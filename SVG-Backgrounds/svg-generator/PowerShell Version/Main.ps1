<#
.SYNOPSIS
    Generate an SVG file with a specified background color.

.DESCRIPTION
    Command-line tool that generates SVG files with a customizable background
    color. Specify RGB values directly (-R -G -B), use a predefined preset
    (-Preset / -c), or list all presets (-ListPresets / -l).

.PARAMETER R
    Red component (0-255). Must be used together with -G and -B.

.PARAMETER G
    Green component (0-255). Must be used together with -R and -B.

.PARAMETER B
    Blue component (0-255). Must be used together with -R and -G.

.PARAMETER Preset
    Color preset name (alias: -c). See -ListPresets for available names.

.PARAMETER ListPresets
    List all available color presets (alias: -l).

.PARAMETER OutputFile
    Output filename (alias: -o). Default: output.svg

.EXAMPLE
    ./Main.ps1 -R 255 -G 0 -B 0

.EXAMPLE
    ./Main.ps1 -c PastelTeal -o teal.svg

.EXAMPLE
    ./Main.ps1 -l
#>
[CmdletBinding(DefaultParameterSetName = 'Rgb')]
param(
    [Parameter(ParameterSetName = 'Rgb', Mandatory)]
    [ValidateRange(0, 255)]
    [int]$R,

    [Parameter(ParameterSetName = 'Rgb', Mandatory)]
    [ValidateRange(0, 255)]
    [int]$G,

    [Parameter(ParameterSetName = 'Rgb', Mandatory)]
    [ValidateRange(0, 255)]
    [int]$B,

    [Parameter(ParameterSetName = 'Preset', Mandatory)]
    [Alias('c')]
    [string]$Preset,

    [Parameter(ParameterSetName = 'List', Mandatory)]
    [Alias('l')]
    [switch]$ListPresets,

    [Parameter(ParameterSetName = 'Rgb')]
    [Parameter(ParameterSetName = 'Preset')]
    [Alias('o')]
    [string]$OutputFile = 'output.svg'
)

$ErrorActionPreference = 'Stop'

# Load the preset table and the SVG generator function.
. (Join-Path $PSScriptRoot 'Presets.ps1')
. (Join-Path $PSScriptRoot 'SvgGenerator.ps1')

switch ($PSCmdlet.ParameterSetName) {
    'List' {
        Write-Output 'Available color presets:'
        foreach ($name in Get-PresetList) {
            $rgb = $ColorPresets[$name]
            Write-Output ('{0}: ({1}, {2}, {3})' -f $name, $rgb[0], $rgb[1], $rgb[2])
        }
        exit 0
    }

    'Preset' {
        if (-not $ColorPresets.Contains($Preset)) {
            Write-Error "Unknown preset '$Preset'. Use -ListPresets (-l) to see available presets."
            exit 1
        }
        $rgb = $ColorPresets[$Preset]
        $R, $G, $B = $rgb[0], $rgb[1], $rgb[2]
    }

    'Rgb' {
        # -R, -G, -B are mandatory in this set and range-validated by the
        # param block, so nothing further to check here.
    }
}

try {
    $svgContent = New-SvgContent -R $R -G $G -B $B
    # UTF-8 without BOM keeps the SVG friendly to all browsers/tools.
    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location).Path $OutputFile),
        $svgContent,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Output "SVG file generated: $OutputFile"
    exit 0
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
