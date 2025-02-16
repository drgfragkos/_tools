Write-Host "============================================================="
Write-Host "*   Multi-Dice Roller (ADnD style) - (c) @drgfragkos 2024   *"
Write-Host "============================================================="
Write-Host "Syntax: XdY (where X = number of dice, Y = sides per die)"
Write-Host "Example: 2d6 means 'roll two 6-sided dice'."
Write-Host "You can also just type d6 and it will roll 1d6."
Write-Host ""

do {
    # Prompt for input
    $diceInput = Read-Host "Enter dice [XdY], q=quit"

    # Check for exit
    if ($diceInput -match '^(?i:q|quit)$') {
        break
    }

    # Attempt to parse input: look for an optional number before 'd' or 'D', and a required number after
    # Example match groups: "2d6" => group 1 is '2', group 2 is '6'
    if ($diceInput -match '^([0-9]*)[dD]([0-9]+)$') {
        $numDice = $Matches[1]
        $diceSides = $Matches[2]

        # If the user wrote just 'd6', $Matches[1] is empty. Assume 1.
        if ([string]::IsNullOrEmpty($numDice)) {
            $numDice = 1
        }
    }
    else {
        Write-Host "`n[Error] Invalid format. Expected something like '2d6' or 'd6'.`n"
        continue
    }

    # Validate numeric ranges
    if (-not [int]::TryParse($numDice, [ref] $null) -or $numDice -lt 1) {
        Write-Host "`n[Error] Number of dice must be a positive integer.`n"
        continue
    }
    if (-not [int]::TryParse($diceSides, [ref] $null) -or $diceSides -lt 1) {
        Write-Host "`n[Error] Sides per die must be a positive integer.`n"
        continue
    }

    # Roll the dice
    $total = 0
    Write-Host "`nRolling $numDice d$diceSides..."
    Write-Host "-----------------------------"
    for ($i = 1; $i -le $numDice; $i++) {
        # Get-Random -Minimum is inclusive, -Maximum is exclusive, so we add 1
        $roll = Get-Random -Minimum 1 -Maximum ($diceSides + 1)
        Write-Host " Roll #$i: $roll"
        $total += $roll
    }
    Write-Host "-----------------------------"
    Write-Host "Total = $total"
    Write-Host ""

} while ($true)

Write-Host "`nExiting..."
