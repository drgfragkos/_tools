<#
    Duplicate File Flagging Tool
    ============================

    DESCRIPTION
    -----------
    This PowerShell script scans a directory for duplicate files based on:
      - MD5 hash of file contents
      - File size

    Duplicates are identified irrespective of filename. For each set of identical
    files, the *oldest* file (by "Date Created") is treated as the original and
    left unchanged. All other files in that set are:

      - Renamed by appending a suffix (default: "__flagged") before the extension
      - Printed to the console with their full paths
      - Listed in a generated "cleanup.bat" file as MOVE commands to a
        "temp_<timestamp>" directory in the working directory.

    The script is designed to be robust and informative, suitable for large
    collections of files.

    USAGE
    -----
        .\DuplicateFlagger.ps1 [-d <directory>] [-ext "<ext1>,,<ext2>,..."] [-r] [-uniq] [-suffix "<suffix>"]

    PARAMETERS
    ----------
    -d <directory>
        Optional. Directory to scan.
        If omitted, the current working directory is used.

    -ext "<ext1>,,<ext2>,...>"
        Optional. Comma-separated list of file extensions to include (without dots).
        Special handling:
          - A blank entry ("") represents files with NO extension.
          - Example: -ext "pdf,,jpg,txt"
              -> includes: .pdf, no-extension files, .jpg, .txt
          - Example: -ext ""
              -> includes ONLY files with no extension.

        If -ext is NOT specified, ALL files are included.

    -r
        Optional. If present, the script scans recursively (all subdirectories).

    -uniq
        Optional. Only meaningful when used with -r.
        When present, duplicate detection is performed across the ENTIRE directory tree.
        Without -uniq, duplicates are detected per directory.

    -suffix "<suffix>"
        Optional. Suffix to append to flagged duplicate files (before extension).
        Default: "__flagged"

        Examples:
          - File "thisfile.txt" -> "thisfile__flagged.txt"
          - File "noextfile"    -> "noextfile__flagged"

    OUTPUT
    ------
    - Renames duplicate files (except the oldest in each identical group).
    - Prints full paths of all flagged (renamed) files.
    - Creates a "cleanup.bat" file in the working directory that:
        * Creates a "temp_<timestamp>" directory
        * Moves all flagged files into that directory (one MOVE per line)

    EXAMPLES
    --------
    1) Scan current directory, all files, non-recursive:
        .\DuplicateFlagger.ps1

    2) Scan specific directory, all files, non-recursive:
        .\DuplicateFlagger.ps1 -d "D:\Data\Docs"

    3) Scan specific directory recursively, only PDFs and files with no extension:
        .\DuplicateFlagger.ps1 -d "D:\Data" -r -ext "pdf,"

    4) Scan recursively across entire tree, detect duplicates globally:
        .\DuplicateFlagger.ps1 -r -uniq

    5) Scan current directory, only JPG and TXT, custom suffix:
        .\DuplicateFlagger.ps1 -ext "jpg,txt" -suffix "_dup"

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$d,

    [Parameter(Mandatory = $false)]
    [string]$ext,

    [Parameter(Mandatory = $false)]
    [switch]$r,

    [Parameter(Mandatory = $false)]
    [switch]$uniq,

    [Parameter(Mandatory = $false)]
    [string]$suffix = "__flagged"
)

# -----------------------------
# Resolve working directory
# -----------------------------
try {
    if ([string]::IsNullOrWhiteSpace($d)) {
        $WorkingDir = (Get-Location).ProviderPath
    } else {
        $WorkingDir = (Resolve-Path -Path $d).ProviderPath
    }
} catch {
    Write-Host "[x] ERROR: Unable to resolve directory path: $d" -ForegroundColor Red
    exit 1
}

Write-Host "[i] Working directory: $WorkingDir" -ForegroundColor Cyan

# -----------------------------
# Parse extension filter
# -----------------------------
$ExtensionFilter = $null
$IncludeNoExtension = $false
$UseExtensionFilter = $false

if ($PSBoundParameters.ContainsKey("ext")) {
    $UseExtensionFilter = $true
    $parts = $ext.Split(',', [System.StringSplitOptions]::None)

    $ExtensionFilter = @()
    foreach ($p in $parts) {
        $trimmed = $p.Trim()
        if ($trimmed -eq "") {
            $IncludeNoExtension = $true
        } else {
            $ExtensionFilter += $trimmed.ToLower()
        }
    }

    Write-Host "[+] Extension filter enabled." -ForegroundColor Yellow
    Write-Host "  --> Extensions: $($ExtensionFilter -join ', ')" -ForegroundColor Yellow
    Write-Host "  --> Include files with no extension: $IncludeNoExtension" -ForegroundColor Yellow
} else {
    Write-Host "[i] No extension filter specified. All files will be considered." -ForegroundColor Yellow
}

# -----------------------------
# Collect files
# -----------------------------
Write-Host "Collecting files..." -ForegroundColor Cyan

$searchParams = @{
    Path = $WorkingDir
    File = $true
}
if ($r.IsPresent) {
    $searchParams.Recurse = $true
    Write-Host "[i] Recursive search enabled." -ForegroundColor Yellow
} else {
    Write-Host "[i] Non-recursive search (current directory only)." -ForegroundColor Yellow
}

try {
    $allFiles = Get-ChildItem @searchParams
} catch {
    Write-Host "[x] ERROR: Failed to enumerate files in $WorkingDir" -ForegroundColor Red
    exit 1
}

if ($allFiles.Count -eq 0) {
    Write-Host "[!] No files found in the specified directory." -ForegroundColor Yellow
    exit 0
}

# Apply extension filter if needed
$filesToProcess = @()

foreach ($file in $allFiles) {
    if (-not $UseExtensionFilter) {
        $filesToProcess += $file
        continue
    }

    $extNoDot = $file.Extension.TrimStart('.').ToLower()

    if ($extNoDot -eq "" -and $IncludeNoExtension) {
        $filesToProcess += $file
    } elseif ($extNoDot -ne "" -and $ExtensionFilter -contains $extNoDot) {
        $filesToProcess += $file
    }
}

if ($filesToProcess.Count -eq 0) {
    Write-Host "[!] No files matched the specified extension filter." -ForegroundColor Yellow
    exit 0
}

Write-Host "[i] Total files to analyze: $($filesToProcess.Count)" -ForegroundColor Green

# -----------------------------
# Duplicate detection strategy
# -----------------------------
if ($uniq.IsPresent -and $r.IsPresent) {
    Write-Host "[i] Global duplicate detection enabled (-uniq)." -ForegroundColor Yellow
    $filesForDuplicateAnalysis = $filesToProcess
} else {
    Write-Host "[i] Duplicate detection per directory." -ForegroundColor Yellow
    $filesForDuplicateAnalysis = $filesToProcess
}

# -----------------------------
# Group by size
# -----------------------------
Write-Host "Grouping files by size..." -ForegroundColor Cyan

$sizeGroups = $filesForDuplicateAnalysis | Group-Object -Property Length
$potentialDupGroups = $sizeGroups | Where-Object { $_.Count -gt 1 }

if ($potentialDupGroups.Count -eq 0) {
    Write-Host "[i] No potential duplicates found (no matching file sizes)." -ForegroundColor Green
    exit 0
}

Write-Host "[i] Groups with matching sizes: $($potentialDupGroups.Count)" -ForegroundColor Green

# -----------------------------
# Compute hashes
# -----------------------------
Write-Host "[+] Computing MD5 hashes and identifying duplicates..." -ForegroundColor Cyan

$hashGroups = @{}
$processedCount = 0
$totalToHash = ($potentialDupGroups | ForEach-Object { $_.Count }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum

foreach ($group in $potentialDupGroups) {
    foreach ($file in $group.Group) {
        $processedCount++
        $percent = [int](($processedCount / $totalToHash) * 100)

        Write-Progress -Activity "[i] Hashing files" -Status "Processing $processedCount of $totalToHash" -PercentComplete $percent

        try {
            $hash = (Get-FileHash -Path $file.FullName -Algorithm MD5).Hash
        } catch {
            Write-Host "[x] WARNING: Failed to hash file: $($file.FullName)" -ForegroundColor DarkYellow
            continue
        }

        $key = "$($file.Length)-$hash"

        if (-not $hashGroups.ContainsKey($key)) {
            $hashGroups[$key] = New-Object System.Collections.Generic.List[System.IO.FileInfo]
        }
        $hashGroups[$key].Add($file)
    }
}

Write-Progress -Activity "Hashing files" -Completed

# -----------------------------
# Process duplicate groups
# -----------------------------
$flaggedFiles = New-Object System.Collections.Generic.List[string]
$totalDuplicateSets = 0
$totalFlaggedFiles = 0

Write-Host "[+] Analyzing hash groups for duplicates..." -ForegroundColor Cyan

foreach ($entry in $hashGroups.GetEnumerator()) {
    $files = $entry.Value
    if ($files.Count -le 1) {
        continue
    }

    $totalDuplicateSets++

    # Sort by CreationTime ascending: oldest first
    $sorted = $files | Sort-Object CreationTime

    $original = $sorted[0]
    $duplicates = $sorted[1..($sorted.Count - 1)]

    Write-Host ""
    Write-Host "[i] Duplicate set #$totalDuplicateSets" -ForegroundColor Magenta
    Write-Host "[+] Original (kept): $($original.FullName)" -ForegroundColor Green

    foreach ($dup in $duplicates) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($dup.Name)
        $extension = $dup.Extension

        if ([string]::IsNullOrEmpty($extension)) {
            $newNameBase = "$baseName$suffix"
        } else {
            $newNameBase = "$baseName$suffix$extension"
        }

        $newPath = Join-Path $dup.DirectoryName $newNameBase

        # Avoid overwriting
        $counter = 1
        while (Test-Path -LiteralPath $newPath) {
            if ([string]::IsNullOrEmpty($extension)) {
                $candidateName = "$baseName$suffix`_$counter"
            } else {
                $candidateName = "$baseName$suffix`_$counter$extension"
            }
            $newPath = Join-Path $dup.DirectoryName $candidateName
            $counter++
        }

        try {
            Rename-Item -LiteralPath $dup.FullName -NewName (Split-Path -Leaf $newPath)
            Write-Host "[!] Flagged: $($dup.FullName)" -ForegroundColor Yellow
            Write-Host "    -------> $newPath" -ForegroundColor Yellow

            $flaggedFiles.Add($newPath)
            $totalFlaggedFiles++
        } catch {
            Write-Host "[x] ERROR: Failed to rename file: $($dup.FullName)" -ForegroundColor Red
        }
    }
}

if ($totalFlaggedFiles -eq 0) {
    Write-Host ""
    Write-Host "[i] No duplicates required renaming." -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "[i] Total duplicate sets found: $totalDuplicateSets" -ForegroundColor Green
Write-Host "[i] Total files flagged (renamed): $totalFlaggedFiles" -ForegroundColor Green

# -----------------------------
# Generate cleanup.bat
# -----------------------------
Write-Host "[i] Generating cleanup.bat..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempDirName = "temp_$timestamp"
$tempDirPath = Join-Path $WorkingDir $tempDirName

$cleanupBatPath = Join-Path $WorkingDir "cleanup.bat"

try {
    $batLines = @()
    $batLines += "@echo off"
    $batLines += "echo Creating temp directory: ""$tempDirName"""
    $batLines += "if not exist ""$tempDirName"" mkdir ""$tempDirName"""
    $batLines += ""

    foreach ($filePath in $flaggedFiles) {
        $batLines += "move ""$filePath"" ""$tempDirName\"""
    }

    Set-Content -Path $cleanupBatPath -Value $batLines -Encoding ASCII

    Write-Host "[+] cleanup.bat created at: $cleanupBatPath" -ForegroundColor Green
    Write-Host "[i] When run, it will move all flagged files into: $tempDirPath" -ForegroundColor Green
} catch {
    Write-Host "[x] ERROR: Failed to create cleanup.bat" -ForegroundColor Red
}

Write-Host ""
Write-Host "[-] Processing complete." -ForegroundColor Cyan