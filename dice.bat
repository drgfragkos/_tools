@echo off
rem (c)gfragkos - 04/04/04

:loop
cls
echo ADnD - Roll Dice script - (c)gfragkos 2004                           [q] to exit
echo.
set /p var1= Select dice to roll [4,6,8,10,12,20,100]: 

if "%var1%" == "q" (
goto exit_sub
)

set /a DICE=%var1%
set /a roll=%random% %% %DICE% + 1 > nul
echo  d%DICE%: %roll%
echo.
pause
goto loop

:exit_sub

echo on
