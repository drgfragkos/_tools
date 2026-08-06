param (
    [switch]$Silent,
    [switch]$Ver,
    [switch]$h,  # -h (see also --help via $RemainingArgs)
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------
# Execution policy applied when the user consents (or in -Silent mode).
# 'Unrestricted' allows ALL unsigned scripts system-wide. Consider
# 'RemoteSigned' (local scripts run freely; downloaded scripts must be
# signed) as a safer default for most environments.
$PolicyToSet = 'Unrestricted'

# Ensure TLS 1.2 for web requests (PS 5.1 on older Windows builds may
# otherwise fail HTTPS calls to modern endpoints)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Treat --help (and -help) like -h. With a param() block, --help alone
# would otherwise cause a binding error before the script body runs.
if ($RemainingArgs -contains '--help' -or $RemainingArgs -contains '-help') { $h = $true }

# Auto-unblock: remove Zone.Identifier mark if present (suppresses internet-origin security warning)
$scriptPath = $MyInvocation.MyCommand.Definition
$isBlocked = Get-Item -Path $scriptPath -Stream "Zone.Identifier" -ErrorAction SilentlyContinue
if ($isBlocked) {
    try {
        Unblock-File -Path $scriptPath -ErrorAction Stop
        Write-Host "[INFO] Script unblocked successfully. Continuing..."
    } catch {
        Write-Warning "Could not unblock script (continuing anyway): $_"
    }
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
    Write-Host "  winget (with a fallback version check against Microsoft's official"
    Write-Host "  release metadata), and optionally sets the execution policy."
    Write-Host ""
    Write-Host "  Note: Windows PowerShell 5.1 is a Windows component serviced only"
    Write-Host "  via Windows Update; this script reports its version but cannot"
    Write-Host "  update it."
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
    Write-Host "  2025-2026 (c) @drgfragkos"
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

# Function: Check for internet connection
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
    $argsString = $argsToForward -join " "

    # Wait for the elevated instance and propagate its exit code so
    # callers/automation can rely on the result.
    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argsString" `
        -Verb RunAs -PassThru -Wait
    exit $proc.ExitCode
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
    if (-not $pwshPath) {
        # A fresh install in a previous run won't be on this session's PATH;
        # check the default install location too.
        $defaultPwsh = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
        if (Test-Path $defaultPwsh) {
            $pwshPath = [pscustomobject]@{ Source = $defaultPwsh }
        }
    }
    if ($pwshPath) {
        try {
            $version = & $pwshPath.Source -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
            if ($version) { return ([string]$version).Trim() }
        }
        catch {
            return $null
        }
    }
    return $null
}

# Function: Get latest stable PowerShell version via winget
# Note: --accept-source-agreements prevents winget from blocking on a
# first-run agreement prompt (which would look like a silent hang here).
function Get-LatestPwshVersionWinget {
    $wingetOutput = winget show --id Microsoft.PowerShell -e --accept-source-agreements 2>$null
    if ($wingetOutput) {
        # NB: the "Version:" label is localized on non-English systems; the
        # metadata fallback below covers that case.
        $versionLine = $wingetOutput | Select-String -Pattern "Version:\s+(\S+)" | Select-Object -First 1
        if ($versionLine -and $versionLine -match "Version:\s+(\S+)") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

# Function: Fallback — latest stable version from Microsoft's official
# release metadata (locale-independent; same endpoint the official
# install-powershell.ps1 uses). Returns e.g. "7.6.4".
function Get-LatestPwshVersionMetadata {
    try {
        $meta = Invoke-RestMethod -Uri "https://aka.ms/pwsh-buildinfo-stable" -TimeoutSec 15
        if ($meta.ReleaseTag) {
            return ([string]$meta.ReleaseTag).TrimStart('v').Trim()
        }
    } catch {
        return $null
    }
    return $null
}

# Function: Convert a version string to [System.Version] for correct
# segment-by-segment comparison. Strips prerelease/build suffixes
# (e.g. "7.7.0-preview.2" -> 7.7.0). Returns $null if unparseable.
function ConvertTo-ComparableVersion {
    param ([string]$version)
    if (-not $version) { return $null }
    $clean = $version.Trim().TrimStart('v')
    $clean = ($clean -split '[-+]')[0]   # drop -preview.N / +metadata
    try { return [System.Version]$clean } catch { return $null }
}

# Main logic: install or update
$installedVersion = Get-InstalledPwshVersion
$latestVersion = Get-LatestPwshVersionWinget
$latestSource = "winget"

if (-not $latestVersion) {
    $latestVersion = Get-LatestPwshVersionMetadata
    $latestSource = "Microsoft release metadata"
}

if (-not $latestVersion) {
    Write-Error "Failed to determine the latest PowerShell version (winget and metadata fallback both failed)."
    exit 1
}

if ($installedVersion) {
    Write-Host "[INFO] PowerShell 7 is already installed. Version: $installedVersion"
    Write-Host "[INFO] Latest available stable version (via $latestSource): $latestVersion"

    $vInstalled = ConvertTo-ComparableVersion $installedVersion
    $vLatest = ConvertTo-ComparableVersion $latestVersion

    if ($vInstalled -and $vLatest) {
        if ($vInstalled -lt $vLatest) {
            if ($Silent -or ((Read-Host "A newer version is available. Update to $latestVersion? (y/n)") -match '^[Yy]$')) {
                winget upgrade --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
                switch ($LASTEXITCODE) {
                    0           { Write-Host "[INFO] PowerShell has been updated successfully." }
                    -1978335189 { Write-Host "[INFO] No applicable update found via winget (already latest for this package)." }  # 0x8A15002B
                    default     { Write-Warning "winget upgrade finished with exit code $LASTEXITCODE. Please review the output above." }
                }
            } else {
                Write-Host "Update skipped."
            }
        } else {
            Write-Host "[INFO] PowerShell 7 is already up to date."
        }
    } else {
        Write-Warning "Version comparison could not be completed (installed: '$installedVersion', latest: '$latestVersion')."
    }

} else {
    Write-Host "[INFO] PowerShell 7 is not currently installed. Installing latest version..."
    winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Error "winget install failed with exit code $LASTEXITCODE."
        exit 1
    }
    # Verify: a fresh install won't be on this session's PATH yet, so
    # check the default install location directly.
    $newPwsh = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
    if (Test-Path $newPwsh) {
        $newVersion = (& $newPwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()').Trim()
        Write-Host "[INFO] PowerShell 7 has been installed. Version: $newVersion"
        Write-Host "[INFO] Note: open a new terminal for 'pwsh' to be available on PATH."
    } else {
        Write-Warning "Install reported success but pwsh.exe was not found at the default location. Open a new terminal and verify with 'pwsh -v'."
    }
}


# Prompt to set execution policy
if ($Silent -or ((Read-Host "`nAllow system-wide execution of unsigned scripts (Set-ExecutionPolicy $PolicyToSet)? (y/n)") -match '^[Yy]$')) {
    try {
        Set-ExecutionPolicy -ExecutionPolicy $PolicyToSet -Scope LocalMachine -Force
        Write-Host "[INFO] Execution policy set to '$PolicyToSet' at LocalMachine scope."

        # Group Policy (MachinePolicy/UserPolicy scopes) silently overrides
        # LocalMachine — warn if that is the case so the change isn't a no-op.
        $gpPolicy = Get-ExecutionPolicy -Scope MachinePolicy -ErrorAction SilentlyContinue
        if ($gpPolicy -and $gpPolicy -ne 'Undefined') {
            Write-Warning "Group Policy enforces execution policy '$gpPolicy' (MachinePolicy scope), which overrides the LocalMachine setting."
        }
    }
    catch {
        Write-Error "Failed to set execution policy: $_"
        exit 1
    }
} else {
    Write-Host "Execution policy not changed."
}

exit 0
