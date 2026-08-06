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
    Write-Host "  The script always performs the winget work from Windows PowerShell"
    Write-Host "  5.1 (powershell.exe). If launched from PowerShell 7+ (pwsh.exe), it"
    Write-Host "  re-launches itself in a new elevated 5.1 window, because upgrading"
    Write-Host "  PowerShell 7 while pwsh.exe hosts the installer can make the MSI"
    Write-Host "  try to terminate the very shell running the upgrade."
    Write-Host ""
    Write-Host "  Before upgrading it refreshes the winget source cache, detects"
    Write-Host "  Microsoft Store (MSIX) installs of PowerShell (which the Store"
    Write-Host "  updates itself - the MSI would install side-by-side), and if"
    Write-Host "  'winget upgrade' cannot correlate the installed package"
    Write-Host "  (0x8A150014), it self-heals by falling back to 'winget install',"
    Write-Host "  which upgrades the MSI in place."
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

# ----------------------------------------------------------------------
# Host + elevation gate.
#
# The winget/MSI work must NOT run inside pwsh.exe: upgrading PowerShell 7
# while pwsh hosts the installer makes the MSI try to close pwsh.exe (the
# very shell running the upgrade), which can stall the install or kill it
# mid-flight. So the script guarantees two things before proceeding:
#   1) it is running in Windows PowerShell 5.1 (powershell.exe), and
#   2) it is elevated.
# If either is false, it relaunches itself accordingly and exits.
# ----------------------------------------------------------------------
$needsElevation = -not (Test-IsAdmin)
$isCoreHost     = $PSVersionTable.PSEdition -eq 'Core'

if ($needsElevation -or $isCoreHost) {

    if ($needsElevation -and -not $Silent) {
        Write-Warning "This script must run as Administrator."
        $userConsent = Read-Host "Do you want to re-run this script as Administrator? (y/n)"
        if ($userConsent -ne 'y' -and $userConsent -ne 'Y') {
            Write-Host "User declined elevation. Exiting."
            exit 1
        }
    }

    if ($isCoreHost) {
        Write-Host "[INFO] Detected PowerShell 7+ (pwsh) as the current host."
        Write-Host "[INFO] Re-launching under Windows PowerShell 5.1 so the upgrade cannot terminate its own shell..."
    }

    $scriptPath = $MyInvocation.MyCommand.Definition
    $argsToForward = @()
    if ($Silent) { $argsToForward += "-Silent" }
    $argsString = $argsToForward -join " "

    $startParams = @{
        FilePath     = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        ArgumentList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argsString"
        PassThru     = $true
    }
    if ($needsElevation) { $startParams['Verb'] = 'RunAs' }

    if ($isCoreHost) {
        # Detached on purpose: if the MSI closes this pwsh window during the
        # upgrade, the child 5.1 window carries on unaffected. Exit code is
        # therefore not propagated in this path.
        Write-Host "[INFO] The upgrade continues in the new window. This pwsh window may be closed by the installer."
        $null = Start-Process @startParams
        exit 0
    } else {
        # 5.1 -> elevated 5.1: safe to wait and propagate the exit code so
        # callers/automation can rely on the result.
        $proc = Start-Process @startParams -Wait
        exit $proc.ExitCode
    }
}

Write-Host "[INFO] Running with Administrator privileges (Windows PowerShell $($PSVersionTable.PSVersion.ToString())).`n"

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

# Refresh the winget source cache. A stale index is a known cause of
# transient 0x8A150014 (NO_APPLICATIONS_FOUND) failures where winget can
# see the catalog entry but fails to correlate the installed package.
Write-Host "[INFO] Refreshing winget source cache..."
winget source update *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "winget source update returned exit code $LASTEXITCODE (continuing anyway)."
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

# Function: Detect a Microsoft Store (MSIX) install of PowerShell for the
# current user. The Store copy is updated by the Store itself; installing
# the winget/MSI package alongside it creates a second, side-by-side copy
# rather than upgrading it.
function Test-StorePwshInstalled {
    try {
        $appx = Get-AppxPackage -Name "Microsoft.PowerShell" -ErrorAction SilentlyContinue
        return [bool]$appx
    } catch {
        return $false
    }
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

# Function: Verify the on-disk pwsh version after an install/upgrade and
# report whether it now matches (or exceeds) the expected version.
function Confirm-PwshVersion {
    param ([string]$ExpectedVersion)
    $current = Get-InstalledPwshVersion
    if (-not $current) {
        Write-Warning "Post-install check: pwsh.exe was not found. Open a new terminal and verify with 'pwsh -v'."
        return
    }
    $vCurrent  = ConvertTo-ComparableVersion $current
    $vExpected = ConvertTo-ComparableVersion $ExpectedVersion
    if ($vCurrent -and $vExpected -and $vCurrent -ge $vExpected) {
        Write-Host "[INFO] Verified: PowerShell 7+ is now at version $current."
        Write-Host "[INFO] Note: open a new terminal for the updated 'pwsh' to be picked up."
    } else {
        Write-Warning "Post-install check: pwsh reports version '$current' but '$ExpectedVersion' was expected. A reboot or new terminal may be required, or the install did not complete."
    }
}

# Function: Run the winget upgrade with self-healing fallback.
# Exit codes handled:
#   0            success
#   0x8A15002B  (-1978335189) UPDATE_NOT_APPLICABLE - already latest
#   0x8A150014  (-1978335212) NO_APPLICATIONS_FOUND - winget could not
#                correlate the installed copy; fall back to
#                'winget install', which upgrades the MSI in place.
function Invoke-PwshUpgrade {
    param ([string]$TargetVersion)

    winget upgrade --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
    switch ($LASTEXITCODE) {
        0 {
            Write-Host "[INFO] PowerShell has been updated successfully."
            Confirm-PwshVersion -ExpectedVersion $TargetVersion
        }
        -1978335189 {  # 0x8A15002B
            Write-Host "[INFO] No applicable update found via winget (already latest for this package)."
        }
        -1978335212 {  # 0x8A150014
            Write-Host "[INFO] winget could not match the installed PowerShell to its catalog entry (0x8A150014)."
            Write-Host "[INFO] Falling back to 'winget install' - the PowerShell MSI upgrades in place..."
            winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[INFO] PowerShell has been updated successfully via the install fallback."
                Confirm-PwshVersion -ExpectedVersion $TargetVersion
            } else {
                Write-Warning "Fallback 'winget install' failed with exit code $LASTEXITCODE. Please review the output above."
            }
        }
        default {
            Write-Warning "winget upgrade finished with exit code $LASTEXITCODE. Please review the output above."
        }
    }
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

# Warn early if the installed PowerShell is (also) the Microsoft Store
# (MSIX) build: the Store updates that copy itself, and the winget/MSI
# package would install side-by-side rather than upgrade it.
$storeInstall = Test-StorePwshInstalled
if ($storeInstall) {
    Write-Warning "A Microsoft Store (MSIX) install of PowerShell was detected for this user."
    Write-Warning "The Store copy is updated by the Microsoft Store itself; the winget/MSI package installs side-by-side and will NOT upgrade the Store copy."
    if (-not $Silent) {
        if ((Read-Host "Continue with the winget/MSI install-or-update anyway? (y/n)") -notmatch '^[Yy]$') {
            Write-Host "Skipping install/update. Use the Microsoft Store to update the Store copy of PowerShell."
            exit 0
        }
    } else {
        Write-Host "[INFO] -Silent mode: continuing with the winget/MSI path anyway."
    }
}

if ($installedVersion) {
    Write-Host "[INFO] PowerShell 7 is already installed. Version: $installedVersion"
    Write-Host "[INFO] Latest available stable version (via $latestSource): $latestVersion"

    $vInstalled = ConvertTo-ComparableVersion $installedVersion
    $vLatest = ConvertTo-ComparableVersion $latestVersion

    if ($vInstalled -and $vLatest) {
        if ($vInstalled -lt $vLatest) {
            if ($Silent -or ((Read-Host "A newer version is available. Update to ${latestVersion}? (y/n)") -match '^[Yy]$')) {
                Invoke-PwshUpgrade -TargetVersion $latestVersion
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
