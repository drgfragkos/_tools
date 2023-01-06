@echo off
rem Command Alias

echo.
echo [BLOW]
more %systemroot%\system32\blow.bat | find /V "@"
echo.
echo [CLEAR]
more %systemroot%\system32\clear.bat | find /V "@"
echo.
echo [DRIVES]
more %systemroot%\system32\drives.bat | find /V "@"
echo.
echo [LS]
more %systemroot%\system32\ls.bat | find /V "@"
echo.
echo [POWEROFF]
more %systemroot%\system32\poweroff.bat | find /V "@"
echo.
echo [REBOOT]
more %systemroot%\system32\reboot.bat | find /V "@"
