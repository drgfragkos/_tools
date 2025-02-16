<#
.SYNOPSIS
  Prepares an external USB drive in Windows so macOS won’t index it.

.DESCRIPTION
  1. Lists all removable drives with a numeric "Dev ID".
  2. Prompts which Dev ID to pick.
  3. Optionally creates a hidden file ".metadata_never_index" in the drive root.
  4. Optionally removes all ".Spotlight-V100" directories/files, continuing even if any fail.
  5. Prints final summary.

.NOTES
  Make sure you have permissions to write to the drive and remove files.  
  
  Important: Run this script in a PowerShell console with appropriate execution policy (Set-ExecutionPolicy RemoteSigned -Scope CurrentUser) or Right-click → Run with PowerShell.
#>

# Step 1: Get all removable drives
Write-Host "Enumerating all removable drives..."
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2"  # DriveType=2 means "Removable"

if (-not $drives) {
    Write-Warning "No removable drives found. Exiting script."
    return
}

Write-Host "Found the following removable drives:`n"

# Display them with a numeric Dev ID
$i = 0
foreach ($d in $drives) {
    # Convert size/free space to GB (for convenience)
    $sizeGB = if ($d.Size) {[math]::Round($d.Size / 1GB, 2)} else {0}
    $freeGB = if ($d.FreeSpace) {[math]::Round($d.FreeSpace / 1GB, 2)} else {0}

    Write-Host "Dev ID: $i"
    Write-Host "  Drive Letter : $($d.DeviceID)"
    Write-Host "  Volume Name  : $($d.VolumeName)"
    Write-Host "  File System  : $($d.FileSystem)"
    Write-Host "  Total Size   : $sizeGB GB"
    Write-Host "  Free Space   : $freeGB GB"
    Write-Host ""

    $i++
}

# Step 2: Prompt which Dev ID to pick
$selectedID = Read-Host "`nEnter the Dev ID of the drive you want to prepare"
if ([int]::TryParse($selectedID, [ref]0) -eq $false -or $selectedID -ge $drives.Count) {
    Write-Warning "Invalid selection. Exiting script."
    return
}

$selectedDrive = $drives[$selectedID]
$driveLetter = $selectedDrive.DeviceID
Write-Host "`nYou selected Drive: $driveLetter (Volume: $($selectedDrive.VolumeName))"

# Variable to track if .metadata_never_index was successfully written
$metadataCreated = $false

# Step 3: Ask to create .metadata_never_index
$createMetaIndexFile = Read-Host "Do you want to create the .metadata_never_index file in the drive root? (y/n)"
if ($createMetaIndexFile -eq 'y') {
    $filePath = Join-Path $driveLetter ".metadata_never_index"
    try {
        # Create or overwrite the file
        New-Item -ItemType File -Path $filePath -Force | Out-Null

        # Set its attributes to Hidden
        (Get-Item $filePath).Attributes = "Hidden"

        $metadataCreated = $true
        Write-Host "Created hidden file: $filePath"
    }
    catch {
        Write-Warning "Failed to create .metadata_never_index in $driveLetter. Error: $_"
    }
}

# Step 5: Ask to remove .Spotlight-V100
$removeSpotlight = Read-Host "`nDo you want to remove all .Spotlight-V100 folders/files recursively on $driveLetter? (y/n)"
$foundCount = 0
$deletedCount = 0
$skippedCount = 0

if ($removeSpotlight -eq 'y') {
    Write-Host "`nSearching for .Spotlight-V100 items..."
    # Recursively find .Spotlight-V100 (files or directories)
    $spotlightItems = Get-ChildItem -Path $driveLetter -Recurse -Force -ErrorAction SilentlyContinue -Filter ".Spotlight-V100"

    if ($spotlightItems) {
        $foundCount = $spotlightItems.Count

        foreach ($item in $spotlightItems) {
            # Display the item path
            Write-Host "Deleting: $($item.FullName)"
            try {
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                $deletedCount++
            }
            catch {
                # If it fails, increment skippedCount and continue
                $skippedCount++
                Write-Warning "Error deleting: $($item.FullName) - $_"
            }
        }
    }
    else {
        Write-Host "No .Spotlight-V100 files/folders found."
    }
}

# Step 7: Print final summary
Write-Host "`n=== FINAL REPORT ==="

if ($metadataCreated) {
    Write-Host "Special File .metadata_never_index successfully written in the root of the disk with Dev ID: $selectedID"
} else {
    Write-Host "Special File .metadata_never_index was NOT created (Dev ID: $selectedID)"
}

if ($removeSpotlight -eq 'y') {
    Write-Host "Total Number of .Spotlight-V100 files/folders found : $foundCount"
    Write-Host "Number of .Spotlight-V100 files/folders deleted     : $deletedCount"
    Write-Host "Number of .Spotlight-V100 files/folders skipped     : $skippedCount"
}

Write-Host "`nScript complete!"


