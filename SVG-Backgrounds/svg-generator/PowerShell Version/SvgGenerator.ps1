# SvgGenerator.ps1 - SVG content generation for the SVG Generator.
# Dot-source this file to get New-SvgContent.

function New-SvgContent {
    <#
    .SYNOPSIS
        Generates an SVG string with a solid background color.
    .PARAMETER R
        Red component (0-255).
    .PARAMETER G
        Green component (0-255).
    .PARAMETER B
        Blue component (0-255).
    .OUTPUTS
        [string] The SVG document content.
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(0, 255)]
        [int]$R = 0,

        [ValidateRange(0, 255)]
        [int]$G = 0,

        [ValidateRange(0, 255)]
        [int]$B = 0
    )

    return @"
<svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="rgb($R,$G,$B)" />
    <!--
        by: @drgfragkos
    -->
</svg>
"@
}
