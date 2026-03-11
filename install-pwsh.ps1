param (
    [switch]$Silent,
    [switch]$Ver,
    [switch]$h  # -h or --help
)

# Auto-unblock: remove Zone.Identifier mark if present (suppresses internet-origin security warning)
$scriptPath = $MyInvocation.MyCommand.Definition
$isBlocked = Get-Item -Path $scriptPath -Stream "Zone.Identifier" -ErrorAction SilentlyContinue
if ($isBlocked) {
    Unblock-File -Path $scriptPath
    Write-Host "[INFO] Script unblocked successfully. Continuing..."
}

# Show help and exit
if ($h) {
    Write-Host ""
    Write-Host "----------------------------------------------------------------------"
    Write-Host " PowerShell 5.1 Script to Install or Update (as needed) PowerShell 7+"
    Write-Host "----------------------------------------------------------------------"
    Write-Host ""
    Write-Host "DESCRIPTION:"
    Write-Host "  This script checks for PowerShell 7+, installs or updates it using"
    Write-Host "  winget, and optionally can set the execution policy to allow"
    Write-Host "  unsigned scripts (Unrestricted)."
    Write-Host ""
    Write-Host "  Use -ver to inspect what versions of PowerShell are installed on"
    Write-Host "  this system (PowerShell 5 and PowerShell 7+), along with their"
    Write-Host "  full executable paths and the path to Windows PowerShell ISE."
    Write-Host "  The -ver flag is standalone and cannot be combined with other flags."
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  powershell.exe -ExecutionPolicy Bypass -File install-pwsh.ps1 [options]"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "  -ver           Show installed PowerShell 5 and 7+ versions and paths, then exit"
    Write-Host "  -silent        Run silently with no prompts (UAC still appears if elevation needed)"
    Write-Host "  -h, --help     Show this help message and exit"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "  powershell.exe -ExecutionPolicy Bypass -File install-pwsh.ps1"
    Write-Host "      Runs interactively, prompts for elevation and decisions"
    Write-Host ""
    Write-Host "  powershell.exe -ExecutionPolicy Bypass -File install-pwsh.ps1 -silent"
    Write-Host "      Runs silently: installs/updates PowerShell 7+ and sets policy automatically"
    Write-Host ""
    Write-Host "  powershell.exe -ExecutionPolicy Bypass -File install-pwsh.ps1 -ver"
    Write-Host "      Shows PowerShell 5 and 7+ version numbers, executable paths, and ISE path"
    Write-Host ""
    Write-Host "  powershell.exe -ExecutionPolicy Bypass -File install-pwsh.ps1 -ver | Select-String '7+'"
    Write-Host "      Pipe -ver output through grep/Select-String to extract specific lines"
    Write-Host ""
    Write-Host "AUTHOR:"
    Write-Host "  2025 (c) @drgfragkos"
    Write-Host ""
    exit 0
}


# -ver flag: standalone only — show installed PS5 and PS7+ versions and paths, then exit
if ($Ver) {
    # PowerShell 5
    $ps5Path = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $ps5Path) {
        $ps5Version = & $ps5Path -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        Write-Host "PS5  | Version: $($ps5Version.Trim()) | Path: $ps5Path"
    } else {
        Write-Host "PS5  | Version: not found | Path: not found"
    }

    # PowerShell 7+
    $pwsh7 = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
    if ($pwsh7) {
        $ps7Version = & $pwsh7.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        Write-Host "PS7+ | Version: $($ps7Version.Trim()) | Path: $($pwsh7.Source)"
    } else {
        Write-Host "PS7+ | Version: not found | Path: not found"
    }

    # Windows PowerShell ISE
    $isePath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell_ise.exe"
    if (Test-Path $isePath) {
        Write-Host "ISE  | Version: n/a | Path: $isePath"
    } else {
        Write-Host "ISE  | Version: n/a | Path: not found"
    }

    exit 0
}


# Function: Check if running as Administrator
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function: Check for internet connection (ping a reliable server)
function Test-InternetConnection {
    try {
        $null = Invoke-WebRequest -Uri "https://www.microsoft.com" -UseBasicParsing -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
}

# Relaunch script with elevation and bypass if needed
if (-not (Test-IsAdmin)) {
    if (-not $Silent) {
        Write-Warning "This script must run as Administrator."
        $userConsent = Read-Host "Do you want to re-run this script as Administrator? (y/n)"
        if ($userConsent -ne 'y' -and $userConsent -ne 'Y') {
            Write-Host "User declined elevation. Exiting."
            exit 1
        }
    }

    $scriptPath = $MyInvocation.MyCommand.Definition
    $argsToForward = @()
    if ($Silent) { $argsToForward += "-Silent" }
    if ($Ver)    { $argsToForward += "-Ver" }
    $argsString = $argsToForward -join " "

    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argsString" `
        -Verb RunAs
    exit 0
}

Write-Host "[INFO] Running with Administrator privileges.`n"

# Check if winget is available
if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
    Write-Error "Winget is not available. Please install it from the Microsoft Store (App Installer)."
    exit 1
}

# Check internet connectivity
if (-not (Test-InternetConnection)) {
    Write-Error "No internet connection detected. PowerShell 7+ cannot be installed or updated without internet access."
    exit 1
}

# Function: Get installed PowerShell 7+ version (if any)
function Get-InstalledPwshVersion {
    $pwshPath = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
    if ($pwshPath) {
        try {
            $version = & $pwshPath.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
            return $version
        }
        catch {
            return $null
        }
    }
    return $null
}

# Function: Get latest stable PowerShell version via winget
function Get-LatestPwshVersion {
    $wingetOutput = winget show --id Microsoft.PowerShell -e 2>$null
    if ($wingetOutput) {
        $versionLine = $wingetOutput | Select-String -Pattern "Version:\s+(\S+)" | Select-Object -First 1
        if ($versionLine -and $versionLine -match "Version:\s+(\S+)") {
            return $Matches[1]
        }
    }
    return $null
}

function Normalize-Version {
    param (
        [string]$version
    )

    # Split version by dot, remove empty entries
    $segments = $version -split '\.' | Where-Object { $_ -ne '' }

    # Convert each segment to integer (to remove leading zeros), then join as string
    $numericString = ($segments | ForEach-Object { [int]$_ }) -join ''

    # Remove trailing zeros from the final string
    return ($numericString -replace '0+$', '')
}

# Main logic: install or update
$installedVersion = Get-InstalledPwshVersion
$latestVersion = Get-LatestPwshVersion

if (-not $latestVersion) {
    Write-Error "Failed to determine the latest PowerShell version from winget."
    exit 1
}

if ($installedVersion) {
    Write-Host "[INFO] PowerShell 7 is already installed. Version: $installedVersion"
    Write-Host "[INFO] Latest available version via winget: $latestVersion"

    try {
        $vInstalled = Normalize-Version $installedVersion.Trim()
        $vLatest = Normalize-Version $latestVersion.Trim()
    } catch {
        Write-Warning "Failed to normalize version numbers. Skipping version check."
        $vInstalled = $null
        $vLatest = $null
    }

    if ($vInstalled -and $vLatest) {
        # Compare as integers
        if ([int64]$vInstalled -lt [int64]$vLatest) {
            if ($Silent -or ((Read-Host "A newer version is available. Update to $latestVersion? (y/n)") -match '^[Yy]$')) {
                winget upgrade --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
                Write-Host "[INFO] PowerShell has been updated (if not already latest)."
            } else {
                Write-Host "Update skipped."
            }
        } else {
            Write-Host "[INFO] PowerShell 7 is already up to date."
        }
    } else {
        Write-Warning "Version comparison could not be completed."
    }

} else {
    Write-Host "[INFO] PowerShell 7 is not currently installed. Installing latest version..."
    winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
    Write-Host "[INFO] PowerShell 7 has been installed."
}


# Prompt to set execution policy
if ($Silent -or ((Read-Host "`nAllow system-wide execution of unsigned scripts (Set-ExecutionPolicy Unrestricted)? (y/n)") -match '^[Yy]$')) {
    try {
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force
        Write-Host "[INFO] Execution policy set to 'Unrestricted' at LocalMachine scope."
    }
    catch {
        Write-Error "Failed to set execution policy: $_"
        exit 1
    }
} else {
    Write-Host "Execution policy not changed."
}

exit 0
