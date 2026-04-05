<#
.SYNOPSIS
    Text-to-Morse-Code converter with audio and visual output.

.DESCRIPTION
    Converts text into Morse code with audible tones and visual dot/dash display.
    Works on PowerShell 5.1 (Windows) and PowerShell 7+ (Windows, Linux, macOS).
    Audio uses [Console]::Beep on Windows, 'play' (sox) on Linux/macOS, with
    graceful fallback to visual-only mode when no audio backend is available.

.PARAMETER Text
    Text to convert. If omitted, enters interactive (REPL) mode.

.PARAMETER Frequency
    Tone frequency in Hz (default: 700).

.PARAMETER WPM
    Speed in approximate words-per-minute (default: 15).

.PARAMETER NoAudio
    Suppress audio; show only the visual Morse output.

.EXAMPLE
    ./txt2morse.ps1 -Text "Hello World"

.EXAMPLE
    ./txt2morse.ps1 -WPM 20 -Frequency 880

.NOTES
    Original Python version (c) gfragkos 2005. PowerShell rewrite 2026.
    On Linux/macOS, install SoX for audio:  sudo apt install sox  /  brew install sox

    AUTHOR
    (c) 2005-2026 @drgfragkos
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [string]$Text,

    [ValidateRange(200, 2000)]
    [int]$Frequency = 700,

    [ValidateRange(5, 50)]
    [int]$WPM = 15,

    [switch]$NoAudio
)

# ── Strict mode ──────────────────────────────────────────────────────────────
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── ITU Morse code table ────────────────────────────────────────────────────
# Dot = '.'  Dash = '-'
$MorseTable = @{
    'A' = '.-';      'B' = '-...';    'C' = '-.-.';    'D' = '-..';
    'E' = '.';       'F' = '..-.';    'G' = '--.';     'H' = '....';
    'I' = '..';      'J' = '.---';    'K' = '-.-';     'L' = '.-..';
    'M' = '--';      'N' = '-.';      'O' = '---';     'P' = '.--.';
    'Q' = '--.-';    'R' = '.-.';     'S' = '...';     'T' = '-';
    'U' = '..-';     'V' = '...-';    'W' = '.--';     'X' = '-..-';
    'Y' = '-.--';    'Z' = '--..';
    '0' = '-----';   '1' = '.----';   '2' = '..---';   '3' = '...--';
    '4' = '....-';   '5' = '.....';   '6' = '-....';   '7' = '--...';
    '8' = '---..';   '9' = '----.';
    '.' = '.-.-.-';  ',' = '--..--';  '?' = '..--..';  "'" = '.----.';
    '!' = '-.-.--';  '/' = '-..-.';   '(' = '-.--.';   ')' = '-.--.-';
    '&' = '.-...';   ':' = '---...';  ';' = '-.-.-.';  '=' = '-...-';
    '+' = '.-.-.';   '-' = '-....-';  '_' = '..--.-';  '"' = '.-..-.';
    '$' = '...-..-'; '@' = '.--.-.';
}

# ── Timing (derived from WPM) ───────────────────────────────────────────────
# Standard PARIS timing: 1 WPM ≈ dot length of 1200 ms
$DotMs       = [int](1200 / $WPM)       # length of a dot
$DashMs      = $DotMs * 3               # length of a dash
$IntraGapMs  = $DotMs                   # gap between dots/dashes in a letter
$LetterGapMs = $DotMs * 3               # gap between letters
$WordGapMs   = $DotMs * 7               # gap between words

# ── Audio backend detection ─────────────────────────────────────────────────
$AudioBackend = 'none'

if (-not $NoAudio) {
    if ($IsWindows -or ($PSVersionTable.PSVersion.Major -le 5)) {
        # Windows — [Console]::Beep is always available
        $AudioBackend = 'console_beep'
    }
    else {
        # Linux / macOS — look for sox's 'play' command
        $playPath = Get-Command 'play' -ErrorAction SilentlyContinue
        if ($playPath) {
            $AudioBackend = 'sox_play'
        }
        else {
            Write-Warning ("Audio requires SoX ('play' command). " +
                "Install with:  sudo apt install sox  or  brew install sox")
            Write-Warning "Falling back to visual-only mode."
        }
    }
}

# ── Helper functions ─────────────────────────────────────────────────────────

function Send-Tone {
    <#
    .SYNOPSIS Emit a tone for a given duration (ms) using the detected backend.
    .PARAMETER DurationMs  Length of the tone in milliseconds.
    .PARAMETER Freq        Override frequency in Hz (defaults to the script-level $Frequency).
    #>
    param(
        [int]$DurationMs,
        [int]$Freq = $script:Frequency
    )

    switch ($script:AudioBackend) {
        'console_beep' {
            [Console]::Beep($Freq, $DurationMs)
        }
        'sox_play' {
            $secs = $DurationMs / 1000.0
            # play -q: quiet, -n: null input, synth: synthesizer
            & play -q -n synth $secs sine $Freq 2>$null
        }
        default {
            # No audio — just sleep so the visual pacing still works
            Start-Sleep -Milliseconds $DurationMs
        }
    }
}

function Send-Silence {
    param([int]$DurationMs)
    if ($DurationMs -gt 0) {
        Start-Sleep -Milliseconds $DurationMs
    }
}

function Write-MorseVisual {
    <#
    .SYNOPSIS Print a coloured dot/dash representation for one character.
    #>
    param(
        [string]$Char,
        [string]$Code
    )

    # Build a friendly visual: replace . with · and - with ─ for nicer look
    $pretty = ($Code.ToCharArray() | ForEach-Object {
        if ($_ -eq '.') { '·' } else { '━' }
    }) -join ' '

    # Use colour if the host supports it
    $charLabel = if ($Char -eq ' ') { '␣' } else { $Char.ToUpper() }
    Write-Host -NoNewline "  $charLabel " -ForegroundColor Cyan
    Write-Host $pretty -ForegroundColor Yellow
}

function ConvertTo-Morse {
    <#
    .SYNOPSIS Convert a full string to Morse — audio + visual.
    #>
    param([string]$InputText)

    $chars = $InputText.ToUpper().ToCharArray()

    for ($i = 0; $i -lt $chars.Length; $i++) {
        $ch = [string]$chars[$i]

        if ($ch -eq ' ') {
            Write-MorseVisual ' ' '/'
            Send-Silence $WordGapMs
            continue
        }

        if (-not $MorseTable.ContainsKey($ch)) {
            Write-Host "  $ch " -ForegroundColor DarkGray -NoNewline
            Write-Host "(skipped — no Morse mapping)" -ForegroundColor DarkGray
            continue
        }

        $code = $MorseTable[$ch]
        Write-MorseVisual $ch $code

        $symbols = $code.ToCharArray()
        for ($s = 0; $s -lt $symbols.Length; $s++) {
            if ($symbols[$s] -eq '.') {
                Send-Tone $DotMs
            }
            else {
                Send-Tone $DashMs
            }
            # Intra-character gap (not after last symbol)
            if ($s -lt $symbols.Length - 1) {
                Send-Silence $IntraGapMs
            }
        }

        # Inter-letter gap (not after last character, and not before a space)
        if ($i -lt $chars.Length - 1 -and $chars[$i + 1] -ne ' ') {
            Send-Silence $LetterGapMs
        }
    }
}

function Show-Banner {
    $banner = @"

  +-------------------------------------------------------+
  |                    ·_ txt2morse _·                    |
  |           Text => Morse Code (Audio+Visual)           |
  +-------------------------------------------------------+

"@
    Write-Host $banner -ForegroundColor Green
    Write-Host "  Audio : $AudioBackend  |  Speed : $WPM WPM  |  Freq : $Frequency Hz" -ForegroundColor DarkCyan
    Write-Host ""
}

# ── Big Ben easter egg (preserved from the original) ─────────────────────────
function Invoke-BigBen {
    Write-Host "`n  🔔 No '+' in Morse — playing Big Ben instead!`n" -ForegroundColor Magenta
    $notes = @(
        @(329.63, 400), # E4
        @(261.63, 400), # C4
        @(293.66, 400), # D4
        @(196.00, 600), # G3 (held)
        @(0,      200), # pause
        @(196.00, 400), # G3
        @(293.66, 400), # D4
        @(329.63, 400), # E4
        @(261.63, 600)  # C4 (held)
    )
    foreach ($n in $notes) {
        if ($n[0] -eq 0) {
            Send-Silence $n[1]
        }
        else {
            Send-Tone -DurationMs $n[1] -Freq ([int]$n[0])
        }
    }
}

# ── Cheat-sheet helper ───────────────────────────────────────────────────────
function Show-CheatSheet {
    Write-Host "`n  Morse Code Reference:" -ForegroundColor Green
    Write-Host "  ─────────────────────" -ForegroundColor DarkGray
    $sorted = $MorseTable.GetEnumerator() | Sort-Object Name
    $col = 0
    foreach ($entry in $sorted) {
        $display = "  {0}  {1,-8}" -f $entry.Name, $entry.Value
        Write-Host -NoNewline $display -ForegroundColor Yellow
        $col++
        if ($col % 6 -eq 0) { Write-Host "" }
    }
    Write-Host "`n"
}

# ── Main entry point ────────────────────────────────────────────────────────

# Handle '+' easter egg for the original behaviour
$processedText = $Text
if ($Text -and $Text.Contains('+')) {
    Invoke-BigBen
    $processedText = $Text.Replace('+', '')
}

if ($processedText) {
    # Non-interactive: convert the supplied text and exit
    Show-Banner
    Write-Host "  Converting: $processedText`n" -ForegroundColor White
    ConvertTo-Morse $processedText
    Write-Host ""
}
else {
    # Interactive REPL mode
    Show-Banner
    Write-Host "  Type text and press Enter. Commands:" -ForegroundColor Gray
    Write-Host "    #        Exit" -ForegroundColor Gray
    Write-Host "    ?        Show Morse cheat-sheet" -ForegroundColor Gray
    Write-Host ""

    while ($true) {
        Write-Host -NoNewline "  morse> " -ForegroundColor Green
        $line = Read-Host
        if ($null -eq $line -or $line -eq '#') {
            Write-Host "`n  73! (Best regards in Morse tradition)`n" -ForegroundColor Cyan
            break
        }
        if ($line.Trim() -eq '?') {
            Show-CheatSheet
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line.Contains('+')) {
            Invoke-BigBen
            $line = $line.Replace('+', '')
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
        }
        Write-Host ""
        ConvertTo-Morse $line
        Write-Host ""
    }
}
