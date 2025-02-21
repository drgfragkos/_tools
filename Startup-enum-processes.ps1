<#
.SYNOPSIS
    Enumerates startup programs on a local or remote machine.

.DESCRIPTION
    This script uses the Win32_StartupCommand WMI class via Get-CimInstance to retrieve
    startup programs. By default, it queries the local machine. Use the -ComputerName
    parameter to check a remote machine and -Credential if needed. Formatted results are 
    output to the console or, if an output file is specified, saved to that file.
    
.PARAMETER ComputerName
    The target machine name. Default is the local computer.

.PARAMETER Credential
    Credentials to use for a remote connection.

.PARAMETER OutputFile
    Path to a file where output will be appended. If not specified, results display on screen.

.EXAMPLE
    .\Startup.ps1
    Retrieves startup programs from the local machine.

.EXAMPLE
    .\Startup.ps1 -ComputerName "SERVER01" -Credential (Get-Credential) -OutputFile "C:\Startup.txt"
    Retrieves startup programs from SERVER01 and saves the formatted output to C:\Startup.txt.

.NOTES
    Running this script locally with administrative privileges is recommended.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile
)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Warn if not running elevated on local machine.
if ($ComputerName -eq $env:COMPUTERNAME -and -not (Test-Admin)) {
    Write-Warning "It is recommended to run this script with administrative privileges for accurate results."
}

Write-Host "Enumerating startup commands on '$ComputerName'..." -ForegroundColor Cyan

try {
    $startupCommands = Get-CimInstance -ClassName Win32_StartupCommand -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
}
catch {
    Write-Error "Error retrieving startup commands: $_"
    exit 1
}

if (-not $startupCommands) {
    Write-Host "No startup commands found on $ComputerName."
    exit 0
}

# Prepare header and formatting.
$header = "{0,-12}{1,-20}{2,-47}" -f "User", "Name", "Command"

$outputLines = @()
$outputLines += "Startup commands on machine '$ComputerName'"
$outputLines += ""
$outputLines += $header

foreach ($startup in $startupCommands) {
    # Ensure null values are replaced with empty strings.
    $user = if ($startup.User) { $startup.User } else { "" }
    $caption = if ($startup.Caption) { $startup.Caption } else { "" }
    $command = if ($startup.Command) { $startup.Command } else { "" }
    
    $line = "{0,-12}{1,-20}{2,-47}" -f $user, $caption, $command
    $outputLines += $line
}

# Output to file if specified; otherwise, display on screen.
if ($OutputFile) {
    try {
        Write-Host "Saving results to file '$OutputFile'..." -ForegroundColor Cyan
        $outputLines | Out-File -FilePath $OutputFile -Encoding UTF8 -Append
        Write-Host "Results successfully written to '$OutputFile'." -ForegroundColor Green
    }
    catch {
        Write-Error "Error writing to file $OutputFile: $_"
        exit 1
    }
}
else {
    Write-Host ""
    $outputLines | ForEach-Object { Write-Host $_ }
}