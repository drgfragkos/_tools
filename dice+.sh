#!/usr/bin/env bash

# Clear the screen (similar to "cls" in Windows)
clear

echo "============================================================="
echo "*   Multi-Dice Roller (ADnD style) - (c) @drgfragkos 2024   *"
echo "============================================================="
echo "Syntax: XdY (where X = number of dice, Y = sides per die)"
echo "Example: 2d6 means 'roll two 6-sided dice'"
echo
echo "You can also just type d6 and it will roll 1d6."
echo

# Infinite loop until the user types 'q' or 'quit'
while true; do
  read -p "Enter dice [XdY], q=quit: " diceInput

  # Check for exit
  case "${diceInput,,}" in  # "${diceInput,,}" lowercases the input
    q|quit)
      echo
      echo "Exiting..."
      exit 0
      ;;
    *)
      # Use a regular expression to parse something like "2d6" or "d6"
      # ^([0-9]*)[dD]([0-9]+)$ means:
      #   - An optional series of digits ([0-9]*) before the 'd'
      #   - A required series of digits ([0-9]+) after the 'd'
      if [[ $diceInput =~ ^([0-9]*)[dD]([0-9]+)$ ]]; then
        numDice="${BASH_REMATCH[1]}"
        diceSides="${BASH_REMATCH[2]}"

        # If the user just typed "d6", numDice is empty => assume 1
        if [[ -z $numDice ]]; then
          numDice=1
        fi

        # Validate numeric input
        if ! [[ $numDice =~ ^[0-9]+$ && $diceSides =~ ^[0-9]+$ ]]; then
          echo "[Error] Invalid numeric input. Please try again."
          echo
          continue
        fi

        # Both must be positive
        if (( numDice < 1 )); then
          echo "[Error] Number of dice must be a positive integer."
          echo
          continue
        fi
        if (( diceSides < 1 )); then
          echo "[Error] Sides per die must be a positive integer."
          echo
          continue
        fi

        # Perform the rolls
        echo
        echo "Rolling ${numDice}d${diceSides} ..."
        echo "-----------------------------"

        total=0
        for (( i=1; i<=$numDice; i++ )); do
          # $RANDOM is a built-in Bash variable; modulo to get 0..(diceSides-1)
          # Add 1 to shift to 1..diceSides
          roll=$(( (RANDOM % diceSides) + 1 ))
          echo " Roll #$i: $roll"
          total=$(( total + roll ))
        done

        echo "-----------------------------"
        echo "Total = $total"
        echo
      else
        echo "[Error] Invalid format. Expected something like '2d6' or 'd6'."
        echo
      fi
      ;;
  esac
done
