rem chat.bat is part of chkUNInet.bat program.
rem conditions about chUNInet.bat are the same for chat.bat
rem chat.bat by Grigorios Fragkos (c) 2002

@echo off
:start
cls

set /p var3= User:

if "%var3%" == "1" (
set usr=Name01
set en=00000000
goto chat
)
if "%var3%" == "2" (
set usr=Name02
set en=00000000
goto chat
) 
if "%var3%" == "3" (
set usr=Name03
set en=00000000
goto chat
) 
if "%var3%" == "4" (
set usr=Name04...
set en=00000000
goto chat
)
if "%var3%" == "5" (
set usr=Name05...
set en=00000000
goto chat
)
if "%var3%" == "6" (
set usr=Name06...
set en=00000000
goto chat
)
if "%var3%" == "7" (
set usr=Name07...
set en=00000000
goto chat
)
if "%var3%" == "8" (
set usr=Name08...
set en=00000000
goto chat
)
if "%var3%" == "9" (
set usr=Name09...
set en=00000000
goto chat
)
if "%var3%" == "10" (
set usr=Name10...
set en=00000000
goto chat
) 
if "%var3%" == "11" (
set usr=Name11...
set en=00000000
goto chat
) 
if "%var3%" == "12" (
set usr=Name12...
set en=00000000
goto chat
) 
if "%var3%" == "13" (
set usr=Name13...
set en=00000000
goto chat
) 
if "%var3%" == "14" (
set usr=Name14...
set en=00000000
goto chat
) 
if "%var3%" == "15" (
set usr=Name15...
set en=00000000
goto chat
) 
if "%var3%" == "16" (
set usr=Name16...
set en=00000000
goto chat
) 
if "%var3%" == "17" (
set usr=Name17
set en=00000000
goto chat
) else (
echo  Wrong Input ! 
pause
goto start
)


:chat
cls
color f0
echo connected to %usr%
echo -------------------------------------
:begin
time /t & set /p m=: 
net send %en% %m%
goto begin
