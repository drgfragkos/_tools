<#
    ---------------------------------------------------------------
    Title: Convert XLSX to CSV (Windows-PowerShell)
    Description:
       A small PowerShell script that uses Excel COM objects 
       (requires Microsoft Excel installed) to convert a 
       single-sheet XLSX to CSV on Windows.

    Usage:
       .\Convert-Xlsx2Csv.ps1 [parameters]

    Examples:
       echo "C:\my.xlsx" | .\Convert-Xlsx2Csv.ps1 -OutputFile "C:\output.csv" -Timestamp          ## (reading filename from PIPE) => my-20250216140000.csv
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\path\to\my.xlsx"
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\path\to\my.xlsx" -OutputFile "C:\some\other.csv"
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\path\to\my.xlsx" -Timestamp                          ## => my-20250216140000.csv
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\my.xlsx" -OutputFile "C:\new file.csv" -Timestamp    ## => new file-20250216140000.csv
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\my.xlsx"
       echo "C:\my.xlsx" | .\Convert-Xlsx2Csv.ps1
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\my.xlsx" -Timestamp
       .\Convert-Xlsx2Csv.ps1 -InputFile "C:\my.xlsx" -OutputFile "C:\new.csv"
       echo "C:\my.xlsx" | .\Convert-Xlsx2Csv.ps1 -OutputFile "C:\custom.csv" -Timestamp

    Author: (c) drgfragkos 2024
    ---------------------------------------------------------------
#>

Param(
    [Parameter(Mandatory=$false)]
    [string]$InputFile,

    [Parameter(Mandatory=$false)]
    [string]$OutputFile,

    [switch]$Timestamp
)

# 1. Attempt to read $InputFile from arguments or pipeline
if (-not $InputFile) {
    # If not provided, attempt from pipeline
    $pipedData = $input | Out-String
    $pipedData = $pipedData.Trim()
    if ($pipedData) {
        $InputFile = $pipedData
    }
}

if (-not $InputFile) {
    Write-Host "Error: No input file provided. Provide via -InputFile or pipeline."
    exit 1
}

if (-not (Test-Path $InputFile)) {
    Write-Host "Error: File not found: $InputFile"
    exit 1
}

# 2. Check if Excel is installed (COM object creation test)
try {
    # Attempt to create an Excel COM Object
    $excel = New-Object -ComObject Excel.Application
} catch {
    Write-Host "Error: Microsoft Excel is not available on this system."
    Write-Host "Please install Microsoft Excel to use this script."
    exit 1
}

# 3. Determine the output CSV path

#   If user provided an OutputFile, use that. Otherwise, default to
#   "basename.csv" or "basename-timestamp.csv" next to the input file.

$InputPath = (Resolve-Path $InputFile).Path

if ($Timestamp) {
    $timestampStr = (Get-Date).ToString("yyyyMMddHHmmss")
} else {
    $timestampStr = ""
}

if ($OutputFile) {
    $OutputFile = $OutputFile.Trim()
    # Split the user-specified output path
    $outDir  = [System.IO.Path]::GetDirectoryName($OutputFile)
    $outFile = [System.IO.Path]::GetFileNameWithoutExtension($OutputFile)
    $outExt  = [System.IO.Path]::GetExtension($OutputFile)

    # If the user didn't specify a directory, it means we place it in the current directory
    # or we keep it as relative to current path
    if (-not $outDir) {
        $outDir = (Get-Location).Path
    }
    # If the user didn't specify an extension, default to .csv
    if (-not $outExt) {
        $outExt = ".csv"
    }

    if ($Timestamp) {
        $FinalOutput = Join-Path $outDir ($outFile + "-" + $timestampStr + $outExt)
    } else {
        $FinalOutput = Join-Path $outDir ($outFile + $outExt)
    }
}
else {
    # User did not specify an OutputFile
    $inBase = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $inDir  = [System.IO.Path]::GetDirectoryName($InputPath)

    if ($Timestamp) {
        $FinalOutput = Join-Path $inDir ($inBase + "-" + $timestampStr + ".csv")
    } else {
        $FinalOutput = Join-Path $inDir ($inBase + ".csv")
    }
}

# 4. Convert using Excel COM
try {
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Open($InputPath)
    $worksheet = $workbook.Sheets.Item(1)

    # 6 = xlCSV
    $workbook.SaveAs($FinalOutput, 6)
    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

    Write-Host "Successfully converted $InputPath -> $FinalOutput"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}
