@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:main
cls
echo =============================================================
echo *   Multi-Dice Roller (ADnD style) - (c) @drgfragkos 2024   *
echo =============================================================
echo Syntax: XdY (where X = number of dice, Y = sides per die)
echo Example: 2d6 means "roll two 6-sided dice"
echo.
echo You can also just type d6 and it will roll 1d6.
echo.

:loop
set "numDice="
set "diceSides="

set /p "diceInput=Enter dice [XdY], q=quit: "

:: Check for exit
if /i "%diceInput%"=="q" goto exitScript
if /i "%diceInput%"=="quit" goto exitScript

:: Split the user input at 'd' or 'D'
for /f "tokens=1,2 delims=dD" %%a in ("%diceInput%") do (
    set "numDice=%%a"
    set "diceSides=%%b"
)

:: If no numDice but we have diceSides, assume 1
if not defined numDice if defined diceSides (
    set "numDice=1"
)

:: Validate that both parts are defined
if not defined numDice (
    echo [Error] Invalid format. Expected something like 2d6 or d6.
    echo.
    goto loop
)
if not defined diceSides (
    echo [Error] Invalid format. Expected something like 2d6 or d6.
    echo.
    goto loop
)

:: Validate that numDice and diceSides are numeric
echo !numDice!| findstr /r "^[0-9][0-9]*$" >nul 2>&1
if errorlevel 1 (
    echo [Error] Number of dice must be a positive integer.
    echo.
    goto loop
)

echo !diceSides!| findstr /r "^[0-9][0-9]*$" >nul 2>&1
if errorlevel 1 (
    echo [Error] Sides per die must be a positive integer.
    echo.
    goto loop
)

:: Perform the rolls
set /a total=0
echo.
echo Rolling !numDice!d!diceSides! ...
echo -----------------------------
for /l %%i in (1,1,!numDice!) do (
    set /a roll=%random% %% !diceSides! + 1
    echo  Roll #%%i: !roll!
    set /a total+=roll
)
echo -----------------------------
echo Total = !total!
echo.

goto loop

:exitScript
echo.
echo Exiting...
ENDLOCAL
exit /b
