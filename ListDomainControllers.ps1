<# 
.SYNOPSIS
    Lists all Domain Controllers for the current domain.

.DESCRIPTION
    This PowerShell script automatically retrieves the domain information for the local machine
    (assuming it is domain-joined) and lists all Domain Controllers in that domain using the 
    ActiveDirectory module. The user is kept informed with progress messages during the execution.
    Optionally, the results can be saved to a CSV file.

.PARAMETER OutputFile
    If provided (full path), the list of Domain Controllers will be written as a CSV file.
    Otherwise, the results are displayed in a formatted table.

.EXAMPLE
    .\ListDomainControllers.ps1
    .\ListDomainControllers.ps1 -OutputFile "C:\DCs.csv"

.NOTES
    This script requires the ActiveDirectory module. Please run the script with administrative 
    privileges for best results.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "It is recommended to run this script with administrative privileges."
    }
}

# Check if running as admin, warn if not.
Check-Admin

# Import the ActiveDirectory module.
try {
    Write-Host "Importing ActiveDirectory module..." -ForegroundColor Cyan
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    Write-Error "ActiveDirectory module not available. Please install RSAT or run on a system with the AD module."
    exit 1
}

# Retrieve domain information automatically.
try {
    Write-Host "Retrieving domain information..." -ForegroundColor Cyan
    $ADDomain = Get-ADDomain -ErrorAction Stop
    $DomainName = $ADDomain.DNSRoot
    Write-Host "Domain detected: $DomainName" -ForegroundColor Green
}
catch {
    Write-Error "Unable to determine domain information. Are you domain-joined?"
    exit 1
}

# Query Domain Controllers.
try {
    Write-Host "Querying domain controllers for domain '$DomainName'..." -ForegroundColor Cyan
    $DCs = Get-ADDomainController -Filter * -Server $DomainName -ErrorAction Stop
    Write-Host "Found $($DCs.Count) domain controller(s)." -ForegroundColor Green
}
catch {
    Write-Error "Error retrieving domain controllers: $_"
    exit 1
}

# Output the results.
if ($OutputFile) {
    try {
        Write-Host "Saving results to CSV file: $OutputFile" -ForegroundColor Cyan
        $DCs | Select-Object Name, IPv4Address, Site, Domain, Forest | Export-Csv -NoTypeInformation -Path $OutputFile -Force
        Write-Host "Results successfully written to $OutputFile" -ForegroundColor Green
    }
    catch {
        Write-Error "Error writing to file $OutputFile: $_"
        exit 1
    }
}
else {
    Write-Host "Displaying domain controllers:" -ForegroundColor Cyan
    $DCs | Format-Table Name, IPv4Address, Site, Domain, Forest
}