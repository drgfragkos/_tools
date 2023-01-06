@echo off
echo *******************************************************************************
echo  List all available SIDs in a system and locate the logged account
echo  Author: - GF - I.S.R.G. - 7 June 2005
echo  Scripts Released as a "proof of concept" - Copyrighted under GPL 
echo *******************************************************************************
echo.
cd \
echo SID(s) stored into your system
dir /A /B C:\RECYCLER
echo -----------------------------------------------
echo.
echo.
echo  Your SID for (%username%) is:
dir "%USERPROFILE%\Local Settings\Application Data\Microsoft\Credentials" /A /B
echo. 
echo.
echo.
echo.This script will now exit,
pause


