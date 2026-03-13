
<#
    Hash Criteria Scanner & Evidence Collector
    =========================================

    DESCRIPTION
    -----------
    This PowerShell tool scans a target folder or drive (e.g. E:\) and compares
    file hashes against a list of known indicators of compromise (IoCs) stored
    in a CSV file (criteria.csv).

    The criteria.csv file should contain rows in the following format:

        hash_type, hash_value, notes

    A header row is optional. If present, it will be detected and skipped
    automatically. Both of these are valid:

        With header:
            hash_type, hash_value, notes
            MD5, 683015117722ac396f23f1b5df1fd984, Fluff Kitten IoC

        Without header (data only):
        MD5, 683015117722ac396f23f1b5df1fd984, Fluff Kitten IoC
        SHA1, b17dcfb1f1e0ba8b8bdfd1cfc15aca6bfb8cb983, HelloKitty IoC
        SHA256, aadf327c8267c09d6fffd87a1a80ad3c798469ff332b7a57b9e8c045d46b2af7, Known Dropper (CatCat Threat Group)

    Supported hash types (as supported by Get-FileHash):
        - MD5
        - SHA1
        - SHA256
        - SHA384
        - SHA512

    For each file in the target, the tool:
        - Computes only the hash types that appear in criteria.csv
        - Compares the computed hash to the known IoCs
        - Emits a single, CSV-friendly line per match to stdout

    The tool can optionally perform actions on matching files:
        - DELETE  : delete matching files
        - RENAME  : rename matching files with a prefix
        - COLLECT : move matching files into a timestamped Evidence Collector folder

    A separate statistics mode (-stats) can be used to profile the target
    folder/drive without performing any IoC checks or actions.

    OUTPUT FORMAT (SCANNING MODE)
    -----------------------------
    Stdout is kept clean and CSV-friendly: one line per event, with a leading
    status marker. All fields are double-quoted for proper CSV compliance:

        "[marker]","hash_type","full_path","hash_value","notes"

    Markers:
        [+]  File matches criteria and is accessible (normal case)
        [i]  File matches criteria and is marked as ReadOnly, Hidden, or System
        [!]  File matches criteria but is locked/in-use or not modifiable
        [x]  Directory cannot be accessed (permissions issue)

    Examples:

        "[+]","MD5","E:\Temp\my data\file.exe","683015117722ac396f23f1b5df1fd984","Fluff Kitten IoC"
        "[i]","SHA1","E:\Temp\backup.dat","b17dcfb1f1e0ba8b8bdfd1cfc15aca6bfb8cb983","HelloKitty IoC"
        "[x]","N/A","E:\Folder\SubDir\"
        "[!]","MD5","E:\Folder\SubDir2\mfile.exe","683015117722ac396f23f1b5df1fd984","Fluff Kitten IoC"

    ACTION MODES (-action)
    ----------------------
    -action is case-sensitive and supports:

        DELETE
        RENAME
        COLLECT

    All destructive actions (DELETE, RENAME, COLLECT) require confirmation
    before proceeding. Use -Confirm:$false to bypass, or -WhatIf to preview.

    DELETE
        - Any file that meets the criteria is deleted immediately.
        - If deletion fails due to lock/permission, marker becomes [!].

    RENAME
        - Matching files are renamed with a prefix:
              __flg<TIMESTAMP>_
        - TIMESTAMP format:
              DDMMYY-HHMMSS-fff
          Example:
              file.exe -> __flg260224-221558-923_file.exe

    COLLECT
        - Matching files are moved into an Evidence Collector folder in the
          script's working directory:
              EC-<TIMESTAMP>
        - Inside that folder, a log file is created:
              _<TIMESTAMP>.log
          containing all stdout lines produced during the run.
        - An HTML evidence tree file is also created:
              _<TIMESTAMP>_evidence_tree.html
          showing the original directory structure, file attributes, and
          hash details for each collected file.
        - TIMESTAMP uses the same DDMMYY-HHMMSS-fff format.

    STATISTICS MODE (-stats)
    ------------------------
    When -stats is used (without -action), the tool:
        - Profiles the target folder/drive
        - Prints statistics such as:
            * Target path
            * Drive letter and filesystem
            * Total capacity, used space, free space
            * Cluster size (if available)
            * Number of files and folders
            * Counts of Hidden, System, ReadOnly files
            * Number of criteria entries and distinct hash types
            * Approximate scan time estimate based on:
                - Stratified file sampling (small / medium / large buckets)
                - Three independent benchmark rounds with median throughput
                - Per-file overhead measurement (seek + open + metadata)
                - Warmup pass to eliminate cold-cache bias
            * System profile: CPU, logical cores, total/free RAM
        - Does NOT perform any IoC checks or actions.

    IMPORTANT:
        - -stats CANNOT be combined with -action.
        - If -stats is present, the tool runs in statistics-only mode.

    EXIT CODES
    ----------
        0  Scan completed, no matches found
        1  Error (bad arguments, missing criteria, inaccessible target, etc.)
        2  Scan completed, one or more matches found

    USAGE
    -----
        # Basic IoC scan (no action, just report matches)
        .\HashScan.ps1 -Target "E:\"

        # IoC scan with DELETE action
        .\HashScan.ps1 -Target "E:\" -Action DELETE

        # IoC scan with RENAME action
        .\HashScan.ps1 -Target "E:\Data" -Action RENAME

        # IoC scan with COLLECT action
        .\HashScan.ps1 -Target "E:\Data" -Action COLLECT

        # Statistics only
        .\HashScan.ps1 -Target "E:\" -Stats

        # Preview DELETE without executing (WhatIf)
        .\HashScan.ps1 -Target "E:\" -Action DELETE -WhatIf

    NOTES
    -----
        - criteria.csv is expected to be in the same directory as this script.
        - The tool is designed to be robust:
            * Handles inaccessible folders
            * Handles locked files
            * Handles Unicode paths and paths with special characters
            * Continues scanning despite errors
        - Progress bars are shown via Write-Progress and do not pollute stdout.
        - Duplicate entries in criteria.csv (same hash_type + hash_value) are
          automatically deduplicated to prevent repeated actions on files.
		- Calculate any Hash from Powershell, and see long SHA512
		  Option A: (Get-FileHash .\file.iso -Algorithm SHA512).hash
		  Option B: Get-FileHash .\file.iso -Algorithm SHA512 | format-list
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [string]$Target = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [ValidateSet("DELETE", "RENAME", "COLLECT")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [switch]$Stats
)

# -----------------------------
# Banner
# -----------------------------
Write-Host ""
Write-Host ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
Write-Host ":::'##::::'##::::'###:::::'######::'##::::'##::'######:::'######:::::'###::::'##::: ##:::" -ForegroundColor Green
Write-Host "::: ##:::: ##:::'## ##:::'##... ##: ##:::: ##:'##... ##:'##... ##:::'## ##::: ###:: ##:::" -ForegroundColor Green
Write-Host "::: ##:::: ##::'##:. ##:: ##:::..:: ##:::: ##: ##:::..:: ##:::..:::'##:. ##:: ####: ##:::" -ForegroundColor Green
Write-Host "::: #########:'##:::. ##:. ######:: #########:. ######:: ##:::::::'##:::. ##: ## ## ##:::" -ForegroundColor Green
Write-Host "::: ##.... ##: #########::..... ##: ##.... ##::..... ##: ##::::::: #########: ##. ####:::" -ForegroundColor Green
Write-Host "::: ##:::: ##: ##.... ##:'##::: ##: ##:::: ##:'##::: ##: ##::: ##: ##.... ##: ##:. ###:::" -ForegroundColor Green
Write-Host "::: ##:::: ##: ##:::: ##:. ######:: ##:::: ##:. ######::. ######:: ##:::: ##: ##::. ##:::" -ForegroundColor Green
Write-Host ":::..:::::..::..:::::..:::......:::..:::::..:::......::::......:::..:::::..::..::::..::::" -ForegroundColor Green
Write-Host ""
Write-Host "[[[ IoC Hash Criteria Scanner & Evidence Collector          ..by (c) 2025 @drgfragkos ]]]" -ForegroundColor Green
Write-Host ""

# -----------------------------
# Helper: Timestamp generator
# -----------------------------
function Get-ScanTimestamp {
    # DDMMYY-HHMMSS-fff
    return (Get-Date -Format "ddMMyy-HHmmss-fff")
}

# -----------------------------
# Helper: CSV-safe field quoting
# -----------------------------
function Format-CsvField {
    param([string]$Value)
    # Double any internal quotes, then wrap in quotes
    $escaped = $Value -replace '"', '""'
    return '"{0}"' -f $escaped
}

function Format-CsvLine {
    param([string[]]$Fields)
    return ($Fields | ForEach-Object { Format-CsvField $_ }) -join ","
}

# -----------------------------
# Helper: Import CSV with normalized headers
# -----------------------------
# criteria.csv may or may not have a header row. This helper:
#   1. Reads the first line to detect whether it's a header or data.
#   2. If no header is found, supplies explicit column names via -Header.
#   3. Strips BOM characters (U+FEFF, U+FFFE), zero-width spaces (U+200B),
#      and leading/trailing whitespace from all property names and values.
#   4. Skips any row that looks like a header row in the middle of data.
function Import-NormalizedCsv {
    param([string]$Path)

    $expectedHeaders = @("hash_type", "hash_value", "notes")
    $bomChars = [char]0xFEFF, [char]0xFFFE, [char]0x200B

    # Read the first line to detect header presence
    $firstLine = (Get-Content -LiteralPath $Path -TotalCount 1).Trim($bomChars).Trim()
    $firstFields = $firstLine -split ',' | ForEach-Object { $_.Trim($bomChars).Trim().ToLower() }

    $hasHeader = ($firstFields.Count -ge 2) -and
                 ($firstFields[0] -eq 'hash_type') -and
                 ($firstFields[1] -eq 'hash_value')

    if ($hasHeader) {
        $raw = Import-Csv -Path $Path
    } else {
        $raw = Import-Csv -Path $Path -Header $expectedHeaders
    }

    foreach ($row in $raw) {
        $clean = [PSCustomObject]@{}
        foreach ($prop in $row.PSObject.Properties) {
            $cleanName = $prop.Name.Trim($bomChars).Trim()
            $cleanValue = if ($null -ne $prop.Value) { $prop.Value.Trim($bomChars).Trim() } else { "" }
            $clean | Add-Member -NotePropertyName $cleanName -NotePropertyValue $cleanValue
        }

        # Skip rows that are themselves a header (e.g. header was present AND
        # we also supplied -Header, or duplicate header lines in the file)
        if ($clean.hash_type -and $clean.hash_type.Trim().ToLower() -eq 'hash_type') {
            continue
        }

        $clean
    }
}

# -----------------------------
# Helper: Format file size for display
# -----------------------------
function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "{0} B" -f $Bytes
}

# -----------------------------
# Resolve script and criteria paths
# -----------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CriteriaPath = Join-Path $ScriptDir "criteria.csv"

# -----------------------------
# Validate mode combinations
# -----------------------------
if ($Stats -and $Action) {
    Write-Error "-stats cannot be used together with -action. Use either statistics mode OR action mode."
    exit 1
}

# -----------------------------
# Ensure target exists
# -----------------------------
try {
    $ResolvedTarget = (Resolve-Path -Path $Target -ErrorAction Stop).ProviderPath
} catch {
    Write-Error "Target path not found or inaccessible: $Target"
    exit 1
}

# -----------------------------
# Cross-drive safety check
# -----------------------------
# Best practice: run the tool from a DIFFERENT drive than the one being
# investigated, to avoid altering evidence on the target volume.
$scriptDriveRoot  = [IO.Path]::GetPathRoot($ScriptDir).TrimEnd('\').ToUpper()
$targetDriveRoot  = [IO.Path]::GetPathRoot($ResolvedTarget).TrimEnd('\').ToUpper()
$isSameDrive      = ($scriptDriveRoot -eq $targetDriveRoot)

# -----------------------------
# Load criteria (if not stats-only)
# -----------------------------
$criteria = $null
$criteriaByAlg = @{}
$distinctAlgorithms = @()

if (-not $Stats) {
    if (-not (Test-Path -LiteralPath $CriteriaPath)) {
        Write-Error "criteria.csv not found at: $CriteriaPath"
        exit 1
    }

    try {
        $criteria = @(Import-NormalizedCsv -Path $CriteriaPath)
    } catch {
        Write-Error "Failed to read criteria.csv: $CriteriaPath"
        exit 1
    }

    # [FIX #11] MACTripleDES removed — not supported on PowerShell 7+ and uses
    #           a non-deterministic default key on 5.1.
    $supportedAlgs = @("MD5", "SHA1", "SHA256", "SHA384", "SHA512")

    # [FIX #10] Track seen (alg+hash) pairs to deduplicate criteria entries
    $seenPairs = @{}

    foreach ($row in $criteria) {
        # Skip malformed rows with missing required fields
        if (-not $row.hash_type -or -not $row.hash_value) { continue }

        $alg = $row.hash_type.Trim().ToUpper()
        $hashValue = $row.hash_value.Trim().ToLower()
        $notes = if ($row.notes) { $row.notes } else { "" }

        # [FIX #1] Corrected operator precedence: was `-not $supportedAlgs -contains $alg`
        #          which evaluated as `(-not $supportedAlgs) -contains $alg` — always false.
        if ($alg -notin $supportedAlgs) {
            continue
        }

        # [FIX #10] Deduplicate: skip if we already have this exact alg+hash pair
        $pairKey = "{0}::{1}" -f $alg, $hashValue
        if ($seenPairs.ContainsKey($pairKey)) {
            continue
        }
        $seenPairs[$pairKey] = $true

        if (-not $criteriaByAlg.ContainsKey($alg)) {
            $criteriaByAlg[$alg] = New-Object System.Collections.Generic.List[object]
        }

        $criteriaByAlg[$alg].Add([PSCustomObject]@{
            HashType  = $alg
            HashValue = $hashValue
            Notes     = $notes
        })
    }

    $distinctAlgorithms = @($criteriaByAlg.Keys)

    if ($criteriaByAlg.Count -eq 0) {
        Write-Error "No supported hash types found in criteria.csv."
        exit 1
    }
}

# -----------------------------
# STATISTICS MODE
# -----------------------------
if ($Stats) {
    # Basic file/folder enumeration
    $fileCount = 0
    $dirCount  = 0
    $hiddenCount = 0
    $systemCount = 0
    $readOnlyCount = 0
    $totalBytes = 0

    try {
        $items = Get-ChildItem -LiteralPath $ResolvedTarget -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Error "Failed to enumerate target for statistics: $ResolvedTarget"
        exit 1
    }

    # [FIX #8] Guarantee array even for single-item results
    $items = @($items)

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            $dirCount++
        } else {
            $fileCount++
            $totalBytes += $item.Length

            $attrs = $item.Attributes
            if ($attrs -band [IO.FileAttributes]::Hidden)   { $hiddenCount++ }
            if ($attrs -band [IO.FileAttributes]::System)   { $systemCount++ }
            if ($attrs -band [IO.FileAttributes]::ReadOnly)  { $readOnlyCount++ }
        }
    }

    # Drive info
    $driveLetter = ([IO.Path]::GetPathRoot($ResolvedTarget)).TrimEnd('\')
    $driveName = $null
    $fsType = $null
    $totalSize = $null
    $freeSpace = $null
    $clusterSize = $null
    $volumeSerial = $null

    # Physical disk identification
    $diskModel     = $null
    $diskSerial    = $null
    $diskMediaType = $null
    $diskBusType   = $null
    $diskSize_GB   = $null
    $diskPartStyle = $null

    try {
        $drive = Get-PSDrive | Where-Object { $_.Root -eq ($driveLetter + "\") }
        if ($drive) {
            $driveName = $drive.Name
            $totalSize = $drive.Used + $drive.Free
            $freeSpace = $drive.Free
        }

        $vol = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$driveLetter'"
        if ($vol) {
            $fsType = $vol.FileSystem
            $clusterSize = $vol.BlockSize
            $volumeSerial = $vol.SerialNumber
        }
    } catch {
        # Ignore drive info errors in stats mode
    }

    # Physical disk details via Storage cmdlets (Windows 10+ / Server 2012+)
    try {
        $partition = Get-Partition -DriveLetter ($driveLetter -replace ':','') -ErrorAction Stop
        if ($partition) {
            $physDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $partition.DiskNumber } | Select-Object -First 1
            if ($physDisk) {
                $diskModel     = $physDisk.FriendlyName
                $diskSerial    = $physDisk.SerialNumber
                $diskMediaType = $physDisk.MediaType       # SSD, HDD, Unspecified
                $diskBusType   = $physDisk.BusType         # SATA, NVMe, USB, etc.
                $diskSize_GB   = [Math]::Round($physDisk.Size / 1GB, 2)
            }
            $diskObj = Get-Disk -Number $partition.DiskNumber -ErrorAction SilentlyContinue
            if ($diskObj) {
                $diskPartStyle = $diskObj.PartitionStyle   # GPT, MBR
            }
        }
    } catch {
        # Storage cmdlets may not be available on all systems
    }

    # Fallback: try WMI if Storage cmdlets didn't populate
    if (-not $diskModel) {
        try {
            # Map logical drive -> partition -> physical disk via WMI
            $logicalToPartition = Get-CimInstance -Query "ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='$driveLetter'} WHERE AssocClass=Win32_LogicalDiskToPartition"
            if ($logicalToPartition) {
                $partToPhys = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($logicalToPartition.DeviceID)'} WHERE AssocClass=Win32_DiskDriveToDiskPartition"
                if ($partToPhys) {
                    if (-not $diskModel)  { $diskModel  = $partToPhys.Model }
                    if (-not $diskSerial) { $diskSerial = $partToPhys.SerialNumber }
                }
            }
        } catch { }
    }

    # Criteria stats (if criteria.csv exists)
    $criteriaCount = 0
    $distinctHashTypesCount = 0
    if (Test-Path -LiteralPath $CriteriaPath) {
        try {
            $crit = @(Import-NormalizedCsv -Path $CriteriaPath)
            $criteriaCount = $crit.Count
            $distinctHashTypesCount = @($crit | Where-Object { $_.hash_type } | ForEach-Object { $_.hash_type.Trim().ToUpper() } | Sort-Object -Unique).Count
        } catch {
            # ignore
        }
    }

    # -----------------------------------------------------------------
    # Robust scan-time estimator
    # -----------------------------------------------------------------
    # The estimate uses:
    #   1. Stratified sampling — files are bucketed by size (small / medium /
    #      large) and sampled proportionally so the benchmark reflects the
    #      actual size distribution on disk.
    #   2. Warmup pass — a handful of files are hashed first and discarded to
    #      eliminate cold-cache / JIT penalties from the measurement.
    #   3. Three independent rounds — each round draws a fresh stratified
    #      sample, producing three throughput measurements.  The median is
    #      used for the final calculation to dampen outliers.
    #   4. Per-file overhead — an additional fixed cost per file (seek + open +
    #      metadata) is measured during sampling and added on top of the pure
    #      throughput estimate.
    #   5. System context — available RAM and logical CPU count are reported
    #      alongside the estimate so the investigator can judge its validity.
    # -----------------------------------------------------------------

    $estimatedSeconds = $null
    $cpuName     = $null
    $cpuCores    = $null
    $totalRAM_GB = $null
    $freeRAM_GB  = $null
    $gpuName     = $null
    $gpuRAM_GB   = $null
    $mbManufacturer = $null
    $mbProduct      = $null
    $mbSerial       = $null
    $osName         = $null
    $osSerial       = $null
    $osBuild        = $null
    $computerName   = $null
    $biosSerial     = $null

    # Gather system info (best-effort)
    try {
        $compSys = Get-CimInstance -ClassName Win32_ComputerSystem
        if ($compSys) {
            $cpuCores     = $compSys.NumberOfLogicalProcessors
            $computerName = $compSys.Name
        }
        $cpuObj = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        if ($cpuObj) { $cpuName = $cpuObj.Name.Trim() }
    } catch { }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        if ($os) {
            $totalRAM_GB = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            $freeRAM_GB  = [Math]::Round($os.FreePhysicalMemory    / 1MB, 2)
            $osName      = $os.Caption
            $osSerial    = $os.SerialNumber
            $osBuild     = $os.BuildNumber
        }
    } catch { }

    # GPU info
    try {
        $gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
        if ($gpu) {
            $gpuName = $gpu.Name
            if ($gpu.AdapterRAM -and $gpu.AdapterRAM -gt 0) {
                $gpuRAM_GB = [Math]::Round($gpu.AdapterRAM / 1GB, 2)
            }
        }
    } catch { }

    # Motherboard info
    try {
        $mb = Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -First 1
        if ($mb) {
            $mbManufacturer = $mb.Manufacturer
            $mbProduct      = $mb.Product
            $mbSerial       = $mb.SerialNumber
        }
    } catch { }

	# BIOS serial (often used as system identifier)
    try {
        $bios = Get-CimInstance -ClassName Win32_BIOS | Select-Object -First 1
        if ($bios) {
            $rawSerial = $bios.SerialNumber
            $biosVersion = $bios.Version
            # Many OEMs leave placeholder strings — treat them as empty
            $placeholders = @("System Serial Number", "To Be Filled By O.E.M.", "Default string",
                              "Not Specified", "None", "N/A", "OEM", "O.E.M.", "123456789", "0")
            if ($rawSerial -and ($rawSerial.Trim() -notin $placeholders)) {
                $biosSerial = $rawSerial.Trim()
            }
        }
    } catch { }

    if ($fileCount -gt 0 -and (Test-Path -LiteralPath $CriteriaPath)) {

        $allStatsFiles = @($items | Where-Object { -not $_.PSIsContainer })

        # --- Stratified bucket builder ---
        # Small < 100 KB | Medium 100 KB – 10 MB | Large > 10 MB
        $bucketSmall  = @($allStatsFiles | Where-Object { $_.Length -lt 100KB })
        $bucketMedium = @($allStatsFiles | Where-Object { $_.Length -ge 100KB -and $_.Length -lt 10MB })
        $bucketLarge  = @($allStatsFiles | Where-Object { $_.Length -ge 10MB })

        # Proportional sample sizes (total ~30 per round to keep it fast)
        $samplesPerRound = 30
        function Get-StratifiedSample {
            param($Small, $Medium, $Large, [int]$Total)
            $n = $Small.Count + $Medium.Count + $Large.Count
            if ($n -eq 0) { return @() }
            # Proportional counts, at least 1 from each non-empty bucket
            $nSmall  = [Math]::Max([int]([Math]::Round($Total * $Small.Count  / $n)), [int]($Small.Count  -gt 0))
            $nMedium = [Math]::Max([int]([Math]::Round($Total * $Medium.Count / $n)), [int]($Medium.Count -gt 0))
            $nLarge  = [Math]::Max([int]([Math]::Round($Total * $Large.Count  / $n)), [int]($Large.Count  -gt 0))
            # Clamp to actual bucket sizes
            $nSmall  = [Math]::Min($nSmall,  $Small.Count)
            $nMedium = [Math]::Min($nMedium, $Medium.Count)
            $nLarge  = [Math]::Min($nLarge,  $Large.Count)
            $result = @()
            if ($nSmall  -gt 0) { $result += @($Small  | Get-Random -Count $nSmall)  }
            if ($nMedium -gt 0) { $result += @($Medium | Get-Random -Count $nMedium) }
            if ($nLarge  -gt 0) { $result += @($Large  | Get-Random -Count $nLarge)  }
            return $result
        }

        # --- Warmup pass (discard timings) ---
        $warmupFiles = @($allStatsFiles | Get-Random -Count ([Math]::Min(5, $allStatsFiles.Count)))
        foreach ($wf in $warmupFiles) {
            try { $null = Get-FileHash -LiteralPath $wf.FullName -Algorithm SHA256 } catch { }
        }

        # --- Three measurement rounds ---
        $roundThroughputs = @()     # bytes/sec from each round
        $roundOverheads   = @()     # seconds-per-file from each round

        for ($round = 1; $round -le 3; $round++) {
            $sample = @(Get-StratifiedSample -Small $bucketSmall -Medium $bucketMedium -Large $bucketLarge -Total $samplesPerRound)
            if ($sample.Count -eq 0) { continue }

            $roundBytes = [long]0
            $roundFiles = 0
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            foreach ($sf in $sample) {
                try {
                    $null = Get-FileHash -LiteralPath $sf.FullName -Algorithm SHA256 -ErrorAction Stop
                    $roundBytes += $sf.Length
                    $roundFiles++
                } catch {
                    # skip failures
                }
            }
            $sw.Stop()

            if ($roundFiles -gt 0 -and $sw.Elapsed.TotalSeconds -gt 0) {
                $roundThroughputs += ($roundBytes / $sw.Elapsed.TotalSeconds)
                $roundOverheads   += ($sw.Elapsed.TotalSeconds / $roundFiles)
            }
        }

        # --- Compute final estimate using median throughput ---
        if ($roundThroughputs.Count -gt 0) {
            # Median helper (works for 1–3 values)
            $sorted = $roundThroughputs | Sort-Object
            if ($sorted.Count % 2 -eq 1) {
                $medianThroughput = $sorted[[Math]::Floor($sorted.Count / 2)]
            } else {
                $mid = $sorted.Count / 2
                $medianThroughput = ($sorted[$mid - 1] + $sorted[$mid]) / 2
            }

            $sortedOH = $roundOverheads | Sort-Object
            if ($sortedOH.Count % 2 -eq 1) {
                $medianOverhead = $sortedOH[[Math]::Floor($sortedOH.Count / 2)]
            } else {
                $mid = $sortedOH.Count / 2
                $medianOverhead = ($sortedOH[$mid - 1] + $sortedOH[$mid]) / 2
            }

            $hashMultiplier = [Math]::Max(1, $distinctHashTypesCount)

            # Time = (data throughput cost) + (per-file overhead cost)
            $throughputTime = ($totalBytes / $medianThroughput) * $hashMultiplier
            $overheadTime   = $fileCount * $medianOverhead * $hashMultiplier
            $estimatedSeconds = $throughputTime + $overheadTime
        }
    }

    Write-Host "=== STATISTICS MODE ====================================================================="
    Write-Host ""

    # [Enhancement #3] Best-practice advisory (always shown in stats)
    Write-Host "+-- Advisory ---------------------------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "|For forensic and data collection integrity, run this tool from a DIFFERENT 'Drive' than|" -ForegroundColor Yellow
    Write-Host "|the target being investigated (e.g. run from a high-performance USB drive). This avoids|" -ForegroundColor Yellow
    Write-Host "|any of the tool's artifacts (logs, EC folders, etc.) to be added to the evidence volume|" -ForegroundColor Yellow
    Write-Host "|and minimises changes to the target filesystem.                                        |" -ForegroundColor Yellow
    if ($isSameDrive) {
        Write-Host "|                                                                                       |" -ForegroundColor Yellow
        Write-Host "|" -ForegroundColor Yellow -NoNewline
		Write-Host "  [WARNING]: Tool is running from the SAME Drive as the Target!                        " -ForegroundColor Red -NoNewline
		Write-Host "|" -ForegroundColor Yellow		
		
        Write-Host "|" -ForegroundColor Yellow -NoNewline
		Write-Host "  [WARNING]: Script Drive: $scriptDriveRoot  |  Target Drive: $targetDriveRoot                                     " -ForegroundColor Red -NoNewline
		Write-Host "|" -ForegroundColor Yellow				
		
    } else {
        Write-Host "|                                                                                       |" -ForegroundColor Yellow
        Write-Host "|" -ForegroundColor Yellow -NoNewline
		Write-Host "  [PASS]: Script Drive [$scriptDriveRoot] differs from Target Drive [$targetDriveRoot]                             " -ForegroundColor Green -NoNewline
		Write-Host "|" -ForegroundColor Yellow
    }
	Write-Host "+---------------------------------------------------------------------------------------+" -ForegroundColor Yellow

    Write-Host ""	
    Write-Host "--- Target ------------------------------------------------------------------------------"
    Write-Host "Target path           : $ResolvedTarget"
    Write-Host "Drive letter          : $driveLetter"
    if ($driveName)     { Write-Host "Drive name            : $driveName" }
    if ($fsType)        { Write-Host "Filesystem            : $fsType" }
    if ($volumeSerial)  { Write-Host ("Volume serial         : {0}" -f $volumeSerial) }
    if ($diskPartStyle) { Write-Host "Partition style       : $diskPartStyle" }
    if ($totalSize -ne $null) {
        Write-Host ("Total capacity        : {0:N2} GB" -f ($totalSize / 1GB))
    }
    if ($freeSpace -ne $null) {
        Write-Host ("Free space            : {0:N2} GB" -f ($freeSpace / 1GB))
        if ($totalSize -ne $null -and $totalSize -gt 0) {
            $used = $totalSize - $freeSpace
            Write-Host ("Used space            : {0:N2} GB ({1:P1})" -f ($used / 1GB), ($used / $totalSize))
        }
    }
    if ($clusterSize -ne $null) {
        Write-Host ("Cluster size          : {0} bytes" -f $clusterSize)
    }

    # Physical disk identification
    if ($diskModel -or $diskSerial -or $diskMediaType -or $diskBusType) {
        Write-Host ""
        Write-Host "--- Physical Disk -----------------------------------------------------------------------"
        if ($diskModel)     { Write-Host "Disk model            : $diskModel" }
        if ($diskSerial)    { Write-Host "Disk serial number    : $($diskSerial.Trim())" }
        if ($diskMediaType) { Write-Host "Media type            : $diskMediaType" }
        if ($diskBusType)   { Write-Host "Bus / interface       : $diskBusType" }
        if ($diskSize_GB)   { Write-Host ("Disk total size       : {0:N2} GB" -f $diskSize_GB) }
    }

    Write-Host ""
    Write-Host "--- File Inventory ----------------------------------------------------------------------"
    Write-Host "Total files           : $fileCount"
    Write-Host "Total folders         : $dirCount"
    Write-Host ("Total data size       : {0:N2} GB" -f ($totalBytes / 1GB))
    Write-Host "Hidden files          : $hiddenCount"
    Write-Host "System files          : $systemCount"
    Write-Host "Read-only files       : $readOnlyCount"

    Write-Host ""
    Write-Host "--- System ------------------------------------------------------------------------------"
    if ($computerName) { Write-Host "Computer Name         : $computerName" }
    if ($osName)       { Write-Host "Operating System      : $osName" }
    if ($osBuild)      { Write-Host "OS build              : $osBuild" }
    if ($osSerial)     { Write-Host "OS Serial / ProductID : $osSerial" }
    
	$biosSerialDisplay = if ($biosSerial) { $biosSerial } else { "N/A" }
    if ($biosVersion) { $biosSerialDisplay = "{0} [{1}]" -f $biosSerialDisplay, $biosVersion.Trim() }
    Write-Host "BIOS serial           : $biosSerialDisplay"
	
    Write-Host ""
    if ($cpuName)      { Write-Host "CPU                   : $cpuName" }
    if ($cpuCores)     { Write-Host "Logical cores         : $cpuCores" }
    if ($totalRAM_GB)  { Write-Host ("Total RAM             : {0:N2} GB" -f $totalRAM_GB) }
    if ($freeRAM_GB)   { Write-Host ("Free RAM              : {0:N2} GB" -f $freeRAM_GB) }
    Write-Host ""
    if ($gpuName)      { Write-Host "GPU                   : $gpuName" }
    if ($gpuRAM_GB)    { Write-Host ("GPU RAM               : {0:N2} GB" -f $gpuRAM_GB) }
    if ($mbManufacturer -or $mbProduct) {
        $mbInfo = @($mbManufacturer, $mbProduct) | Where-Object { $_ } | ForEach-Object { $_.Trim() }
        Write-Host "Motherboard           : $($mbInfo -join ' / ')"
    }
    if ($mbSerial)     { Write-Host "Motherboard serial    : $mbSerial" }

    Write-Host ""
    Write-Host "--- Criteria ----------------------------------------------------------------------------"
    Write-Host "Criteria file         : $CriteriaPath"
    Write-Host "Criteria entries      : $criteriaCount"
    Write-Host "Distinct hash types   : $distinctHashTypesCount"

    if ($estimatedSeconds -ne $null) {
        # Show a time range: estimate ±20% to convey inherent uncertainty
        $lowSec  = $estimatedSeconds * 0.8
        $highSec = $estimatedSeconds * 1.2

        function Format-Duration {
            param([double]$Seconds)
            if ($Seconds -ge 3600) {
                $h = [Math]::Floor($Seconds / 3600)
                $m = [Math]::Floor(($Seconds % 3600) / 60)
                return "{0}h {1}m" -f $h, $m
            }
            $m = [Math]::Floor($Seconds / 60)
            $s = [Math]::Round($Seconds % 60)
            return "{0} min {1} sec" -f $m, $s
        }

        Write-Host ""
        Write-Host "--- Scan Estimate -----------------------------------------------------------------------"
        Write-Host ("Estimated scan time   : ~{0}  (range: {1} - {2})" -f `
            (Format-Duration $estimatedSeconds), `
            (Format-Duration $lowSec), `
            (Format-Duration $highSec))
        if ($medianThroughput) {
            Write-Host ("Measured throughput   : {0:N0} MB/s (median of 3 rounds, SHA-256)" -f ($medianThroughput / 1MB))
        }
        Write-Host   "Estimation method     : Stratified sampling, 3 rounds, median throughput + per-file overhead"
		Write-Host ""
		Write-Host ":::..:::::..::..:::::..:::......:::..:::::..:::......::::......:::..:::::..::..::::..::::"
    }

    exit 0
}

# -----------------------------
# SCANNING MODE
# -----------------------------

# [Enhancement #3] Warn if tool runs from the same drive as the target
if ($isSameDrive) {
    Write-Host ""
    Write-Host "  ** WARNING: Tool is running from the SAME drive as the target ($targetDriveRoot). **" -ForegroundColor Red
    Write-Host "  ** For forensic integrity, run from a different drive (e.g. USB). **" -ForegroundColor Red
    Write-Host ""
}

# [FIX #7] Confirm destructive actions with the user before proceeding
if ($Action) {
    $actionDescriptions = @{
        "DELETE"  = "PERMANENTLY DELETE all matching files"
        "RENAME"  = "RENAME all matching files with a flag prefix"
        "COLLECT" = "MOVE all matching files into an evidence collection folder"
    }
    $desc = $actionDescriptions[$Action]
    if (-not $PSCmdlet.ShouldProcess($ResolvedTarget, $desc)) {
        Write-Host "Operation cancelled by user."
        exit 0
    }
}

# Prepare timestamp for this run
$runTimestamp = Get-ScanTimestamp

# For COLLECT mode: prepare EC folder and log buffer
$collectDir = $null
$collectLogPath = $null
$collectHtmlPath = $null
$logLines = New-Object System.Collections.Generic.List[string]

# [FIX #6] Evidence metadata list for HTML tree generation
$evidenceRecords = New-Object System.Collections.Generic.List[object]

if ($Action -eq "COLLECT") {
    $collectDir = Join-Path $ScriptDir ("EC-{0}" -f $runTimestamp)
    if (-not (Test-Path -LiteralPath $collectDir)) {
        New-Item -ItemType Directory -Path $collectDir | Out-Null
    }
    $collectLogPath = Join-Path $collectDir ("_{0}.log" -f $runTimestamp)
    $collectHtmlPath = Join-Path $collectDir ("_{0}_evidence_tree.html" -f $runTimestamp)
}

# Helper to emit a line and optionally store it for COLLECT
function Emit-Line {
    param(
        [string]$Line
    )
    Write-Output $Line
    if ($Action -eq "COLLECT") {
        $script:logLines.Add($Line) | Out-Null
    }
}

# [FIX #9] Scan-wide counters for summary
$scanStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$matchCount = 0
$errorCount = 0
$accessDeniedCount = 0

# Enumerate files and capture directory access errors
$gciErrors = @()
try {
    # [FIX #4] Use -LiteralPath to handle wildcards in path names
    # [FIX #8] Wrap in @() to guarantee array for single-item results
    $allFiles = @(Get-ChildItem -LiteralPath $ResolvedTarget -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable +gciErrors)
} catch {
    # If even top-level fails, report and exit
    Emit-Line (Format-CsvLine @("[x]", "N/A", $ResolvedTarget))
    exit 1
}

# Report inaccessible directories (permission denied)
foreach ($err in $gciErrors) {
    if ($err.CategoryInfo.Category -eq "PermissionDenied") {
        $targetObj = $err.TargetObject
        $accessDeniedCount++
        if ($targetObj -is [string]) {
            Emit-Line (Format-CsvLine @("[x]", "N/A", $targetObj))
        } elseif ($targetObj -and $targetObj.PSObject.Properties["FullName"]) {
            Emit-Line (Format-CsvLine @("[x]", "N/A", $targetObj.FullName))
        }
    }
}

if ($allFiles.Count -eq 0) {
    # Nothing to scan
    exit 0
}

# -----------------------------
# Main scan loop
# -----------------------------
$totalFiles = $allFiles.Count
$processed = 0

foreach ($file in $allFiles) {
    $processed++
    $percent = [int](($processed / $totalFiles) * 100)
    Write-Progress -Activity "Scanning files" -Status "Processing $processed of $totalFiles" -PercentComplete $percent

    $filePath = $file.FullName

    # [FIX #2] Track whether an action was performed so we stop hashing this file
    $actionPerformed = $false

    # For each algorithm in criteria, compute hash once and compare
    foreach ($alg in $distinctAlgorithms) {

        # [FIX #2] If the file was already acted on (deleted/renamed/moved), skip remaining algorithms
        if ($actionPerformed) { break }

        $hashResult = $null
        try {
            # [FIX #4] Use -LiteralPath to handle brackets, wildcards in file names
            $hashResult = Get-FileHash -LiteralPath $filePath -Algorithm $alg -ErrorAction Stop
        } catch {
            # Could not hash (locked, permission, etc.) – skip this algorithm for this file
            $errorCount++
            continue
        }

        $computedHash = $hashResult.Hash.ToLower()

        # Check against all criteria for this algorithm
        foreach ($entry in $criteriaByAlg[$alg]) {
            if ($computedHash -ne $entry.HashValue) { continue }

            # We have a match
            $matchCount++
            $marker = "[+]"
            $attrs = $file.Attributes

            # [FIX #3] Added Hidden attribute check — was missing from original code
            $isSpecialAttr = (($attrs -band [IO.FileAttributes]::ReadOnly) -ne 0) -or
                             (($attrs -band [IO.FileAttributes]::Hidden)   -ne 0) -or
                             (($attrs -band [IO.FileAttributes]::System)   -ne 0)

            if ($isSpecialAttr) {
                $marker = "[i]"
            }

            $effectivePath = $filePath
            $actionFailedLock = $false

            if ($Action -eq "DELETE") {
                try {
                    Remove-Item -LiteralPath $filePath -Force -ErrorAction Stop
                    $actionPerformed = $true
                } catch [System.UnauthorizedAccessException], [System.IO.IOException] {
                    $actionFailedLock = $true
                } catch {
                    $actionFailedLock = $true
                }

                if ($actionFailedLock) {
                    $marker = "[!]"
                    $errorCount++
                }

            } elseif ($Action -eq "RENAME") {
                $dir = Split-Path -Parent $filePath
                $name = Split-Path -Leaf $filePath
                $newName = "__flg{0}_{1}" -f $runTimestamp, $name
                $newPath = Join-Path $dir $newName

                try {
                    Rename-Item -LiteralPath $filePath -NewName $newName -ErrorAction Stop
                    $effectivePath = $newPath
                    $actionPerformed = $true
                } catch [System.UnauthorizedAccessException], [System.IO.IOException] {
                    $marker = "[!]"
                    $errorCount++
                } catch {
                    $marker = "[!]"
                    $errorCount++
                }

            } elseif ($Action -eq "COLLECT") {
                if ($collectDir) {
                    $destPath = Join-Path $collectDir (Split-Path -Leaf $filePath)
                    # Avoid overwriting inside EC folder
                    $baseName = [IO.Path]::GetFileNameWithoutExtension($destPath)
                    $ext = [IO.Path]::GetExtension($destPath)
                    $candidate = $destPath
                    $counter = 1
                    while (Test-Path -LiteralPath $candidate) {
                        $candidate = Join-Path $collectDir ("{0}_{1}{2}" -f $baseName, $counter, $ext)
                        $counter++
                    }
                    try {
                        Move-Item -LiteralPath $filePath -Destination $candidate -ErrorAction Stop
                        $effectivePath = $candidate
                        $actionPerformed = $true

                        # [FIX #6] Record evidence metadata for HTML tree
                        $script:evidenceRecords.Add([PSCustomObject]@{
                            OriginalPath   = $filePath
                            CollectedAs    = Split-Path -Leaf $candidate
                            HashType       = $entry.HashType
                            HashValue      = $entry.HashValue
                            Notes          = $entry.Notes
                            FileSize       = $file.Length
                            CreationTime   = $file.CreationTime
                            LastWriteTime  = $file.LastWriteTime
                            LastAccessTime = $file.LastAccessTime
                            Attributes     = $file.Attributes.ToString()
                            Marker         = $marker
                        })
                    } catch [System.UnauthorizedAccessException], [System.IO.IOException] {
                        $marker = "[!]"
                        $errorCount++
                    } catch {
                        $marker = "[!]"
                        $errorCount++
                    }
                }
            }

            # [FIX #5] Emit properly quoted CSV line
            $line = Format-CsvLine @($marker, $entry.HashType, $effectivePath, $entry.HashValue, $entry.Notes)
            Emit-Line $line

            # [FIX #2] If action was performed, break out of the criteria inner loop too
            if ($actionPerformed) { break }
        }
    }
}

Write-Progress -Activity "Scanning files" -Completed
$scanStopwatch.Stop()

# Write COLLECT log if needed
if ($Action -eq "COLLECT" -and $collectLogPath -and $logLines.Count -gt 0) {
    try {
        $logLines | Set-Content -LiteralPath $collectLogPath -Encoding UTF8
    } catch {
        # If log writing fails, we silently ignore to avoid polluting stdout
    }
}

# -----------------------------
# [FIX #6] Generate HTML Evidence Tree for COLLECT mode
# -----------------------------
if ($Action -eq "COLLECT" -and $collectHtmlPath -and $evidenceRecords.Count -gt 0) {

    # Build a nested hashtable representing the directory tree
    # Key = folder path segment, Value = hashtable of children or $null for files
    $treeData = @{}

    foreach ($rec in $evidenceRecords) {
        $parts = $rec.OriginalPath -split '[\\/]'
        $current = $treeData
        for ($i = 0; $i -lt $parts.Count - 1; $i++) {
            $segment = $parts[$i]
            if (-not $current.ContainsKey($segment)) {
                $current[$segment] = @{ '__children' = @{} }
            }
            $current = $current[$segment]['__children']
        }
        # Leaf = file name -> metadata
        $fileName = $parts[$parts.Count - 1]
        $current[$fileName] = $rec
    }

    # Recursive function to render tree as HTML
    function Render-TreeHtml {
        param($Node, [int]$Depth = 0)

        $html = ""
        $sortedKeys = $Node.Keys | Sort-Object

        foreach ($key in $sortedKeys) {
            if ($key -eq '__children') { continue }
            $val = $Node[$key]

            if ($val -is [hashtable] -and $val.ContainsKey('__children')) {
                # This is a folder
                $indent = "&nbsp;" * ($Depth * 4)
                $html += "<div class='folder' style='margin-left:{0}px'>" -f ($Depth * 20)
                $html += "<span class='folder-icon'>&#128193;</span> <span class='folder-name'>$([System.Net.WebUtility]::HtmlEncode($key))</span>"
                $html += "</div>`n"
                $html += Render-TreeHtml -Node $val['__children'] -Depth ($Depth + 1)
            } else {
                # This is a file (leaf with evidence record)
                $r = $val
                $sizeStr = Format-FileSize $r.FileSize
                $html += "<div class='file-entry' style='margin-left:{0}px'>" -f ($Depth * 20)
                $html += "<span class='file-icon'>&#128196;</span> "
                $html += "<span class='file-name'>$([System.Net.WebUtility]::HtmlEncode($key))</span>"
                $html += "<span class='marker marker-$(($r.Marker -replace '[\[\]]','').ToLower())'>$([System.Net.WebUtility]::HtmlEncode($r.Marker))</span>"
                $html += "<div class='file-details'>"
                $html += "<table>"
                $html += "<tr><td class='lbl'>Collected As</td><td>$([System.Net.WebUtility]::HtmlEncode($r.CollectedAs))</td></tr>"
                $html += "<tr><td class='lbl'>Hash ($($r.HashType))</td><td class='hash'>$([System.Net.WebUtility]::HtmlEncode($r.HashValue))</td></tr>"
                $html += "<tr><td class='lbl'>Notes</td><td>$([System.Net.WebUtility]::HtmlEncode($r.Notes))</td></tr>"
                $html += "<tr><td class='lbl'>File Size</td><td>$sizeStr ($($r.FileSize) bytes)</td></tr>"
                $html += "<tr><td class='lbl'>Created</td><td>$($r.CreationTime.ToString('yyyy-MM-dd HH:mm:ss.fff'))</td></tr>"
                $html += "<tr><td class='lbl'>Modified</td><td>$($r.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss.fff'))</td></tr>"
                $html += "<tr><td class='lbl'>Accessed</td><td>$($r.LastAccessTime.ToString('yyyy-MM-dd HH:mm:ss.fff'))</td></tr>"
                $html += "<tr><td class='lbl'>Attributes</td><td>$([System.Net.WebUtility]::HtmlEncode($r.Attributes))</td></tr>"
                $html += "</table>"
                $html += "</div></div>`n"
            }
        }
        return $html
    }

    $treeHtml = Render-TreeHtml -Node $treeData

    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Evidence Collection Tree — EC-$runTimestamp</title>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        font-family: 'Segoe UI', Consolas, 'Courier New', monospace;
        background: #0d1117; color: #c9d1d9;
        padding: 24px; line-height: 1.6;
    }
    h1 { color: #58a6ff; font-size: 1.4em; margin-bottom: 4px; }
    .meta { color: #8b949e; font-size: 0.85em; margin-bottom: 20px; border-bottom: 1px solid #21262d; padding-bottom: 12px; }
    .summary-bar {
        display: flex; gap: 24px; background: #161b22; border: 1px solid #30363d;
        border-radius: 6px; padding: 12px 16px; margin-bottom: 20px; font-size: 0.9em;
    }
    .summary-bar .stat { display: flex; flex-direction: column; }
    .summary-bar .stat-val { color: #58a6ff; font-weight: 600; font-size: 1.2em; }
    .summary-bar .stat-lbl { color: #8b949e; font-size: 0.8em; }
    .tree-container { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 16px; }
    .folder { padding: 4px 0; }
    .folder-icon { font-size: 1.1em; }
    .folder-name { color: #58a6ff; font-weight: 600; }
    .file-entry { padding: 6px 0; border-bottom: 1px solid #21262d; }
    .file-entry:last-child { border-bottom: none; }
    .file-icon { font-size: 0.95em; }
    .file-name { color: #f0883e; font-weight: 600; }
    .marker { font-size: 0.8em; padding: 1px 6px; border-radius: 3px; margin-left: 8px; font-weight: 700; }
    .marker-\+ { background: #1a4d2e; color: #3fb950; }
    .marker-i  { background: #2d333b; color: #d29922; }
    .marker-\! { background: #4d1a1a; color: #f85149; }
    .file-details { margin: 6px 0 4px 24px; }
    .file-details table { border-collapse: collapse; font-size: 0.82em; }
    .file-details td { padding: 2px 12px 2px 0; vertical-align: top; }
    .lbl { color: #8b949e; white-space: nowrap; font-weight: 600; }
    .hash { font-family: Consolas, 'Courier New', monospace; color: #bc8cff; word-break: break-all; }
    .footer { margin-top: 20px; color: #484f58; font-size: 0.75em; text-align: center; border-top: 1px solid #21262d; padding-top: 12px; }
</style>
</head>
<body>
<h1>&#128270; Evidence Collection Tree</h1>
<div class="meta">
    Collection ID: EC-$runTimestamp<br>
    Target: $([System.Net.WebUtility]::HtmlEncode($ResolvedTarget))<br>
    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC$(Get-Date -Format 'zzz')
</div>
<div class="summary-bar">
    <div class="stat"><span class="stat-val">$($evidenceRecords.Count)</span><span class="stat-lbl">Files Collected</span></div>
    <div class="stat"><span class="stat-val">$(($evidenceRecords | Select-Object -ExpandProperty HashType -Unique).Count)</span><span class="stat-lbl">Hash Types Matched</span></div>
    <div class="stat"><span class="stat-val">$(Format-FileSize ($evidenceRecords | Measure-Object -Property FileSize -Sum).Sum)</span><span class="stat-lbl">Total Evidence Size</span></div>
</div>
<div class="tree-container">
$treeHtml
</div>
<div class="footer">
    HashScan Evidence Collector &mdash; Generated automatically. Do not modify this file.
</div>
</body>
</html>
"@

    try {
        $htmlContent | Set-Content -LiteralPath $collectHtmlPath -Encoding UTF8
    } catch {
        # If HTML writing fails, continue — the log file is the primary record
        Write-Warning "Failed to write evidence tree HTML: $_"
    }
}

# -----------------------------
# [FIX #9] Scan summary (written to stderr via Write-Host so stdout stays CSV-clean)
# -----------------------------
$elapsed = $scanStopwatch.Elapsed

# [Enhancement #1] Legend reminder before summary
Write-Host ""
Write-Host "--- Legend ------------------------------------------------------------------------------"
Write-Host "  [+] Criteria Matched    [i] ReadOnly/Hidden/System    [!] Locked/In-Use/Unmodifiable    [x] Not Accessible"

Write-Host ""
Write-Host "=== SCAN COMPLETE ==="
Write-Host ("Files scanned         : {0}" -f $totalFiles)
Write-Host ("Matches found         : {0}" -f $matchCount)
Write-Host ("Errors / lock fails   : {0}" -f $errorCount)
Write-Host ("Access denied dirs    : {0}" -f $accessDeniedCount)
Write-Host ("Elapsed time          : {0:D2}:{1:D2}:{2:D2}.{3:D3}" -f $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds, $elapsed.Milliseconds)
if ($Action) {
    Write-Host ("Action performed      : {0}" -f $Action)
}
if ($Action -eq "COLLECT" -and $collectDir) {
    Write-Host ("Evidence folder       : {0}" -f $collectDir)
    if ($collectHtmlPath -and (Test-Path -LiteralPath $collectHtmlPath)) {
        Write-Host ("Evidence tree HTML    : {0}" -f $collectHtmlPath)
    }
}

# [Enhancement #5] Next steps — context-sensitive suggestions with copy-paste commands
$scriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$quotedTarget = '"{0}"' -f $ResolvedTarget

Write-Host ""
Write-Host "--- What's Next -------------------------------------------------------------------------"

if (-not $Action) {
    # User ran a scan-only (no action). Suggest the three action modes.
    Write-Host "  You ran a scan-only pass. To act on matched files, copy & paste one of these:"
    Write-Host ""
    Write-Host "  Collect evidence (move matched files to an evidence folder + HTML report):" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Action COLLECT"
    Write-Host ""
    Write-Host "  Rename matched files (flag with prefix, leave in place):" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Action RENAME"
    Write-Host ""
    Write-Host "  Delete matched files permanently:" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Action DELETE"
    Write-Host ""
    Write-Host "  Preview any action without executing (WhatIf):" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Action COLLECT -WhatIf"

} elseif ($Action -eq "COLLECT") {
    # After COLLECT, suggest reviewing evidence and re-scanning
    Write-Host "  Evidence has been collected. Suggested next steps:"
    Write-Host ""
    Write-Host "  Re-scan the target to verify no matches remain:" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget"
    Write-Host ""
    Write-Host "  View the evidence tree report:" -ForegroundColor Cyan
    if ($collectHtmlPath) {
        Write-Host "    Start-Process `"$collectHtmlPath`""
    }
    Write-Host ""
    Write-Host "  Run statistics to profile the target:" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Stats"

} elseif ($Action -eq "RENAME") {
    # After RENAME, suggest re-scan or collect
    Write-Host "  Matched files have been renamed. Suggested next steps:"
    Write-Host ""
    Write-Host "  Re-scan to verify (renamed files won't match again):" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget"
    Write-Host ""
    Write-Host "  Or collect the renamed evidence files into an EC folder:" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Action COLLECT"

} elseif ($Action -eq "DELETE") {
    # After DELETE, suggest re-scan to confirm
    Write-Host "  Matched files have been deleted. Suggested next steps:"
    Write-Host ""
    Write-Host "  Re-scan the target to confirm all matches were removed:" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget"
    Write-Host ""
    Write-Host "  Run statistics to profile the target post-cleanup:" -ForegroundColor Cyan
    Write-Host "    .\$scriptName -Target $quotedTarget -Stats"
}

Write-Host ""

# [FIX #13] Distinct exit codes: 0 = no matches, 2 = matches found
if ($matchCount -gt 0) {
    exit 2
} else {
    exit 0
}
