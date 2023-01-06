@echo off
rem myLcmd by Greg Fragkos

:cl
@echo off
set /p lcm= Yes Master: 
if "%lcm%" == "exit" (
goto endf
)
if "%lcm%" == "pwd" (
goto pwd
)
if "%lcm%" == "help" (
goto help
)
if "%lcm%" == "ls --help" (
goto lshelp
)
if "%lcm%" == "ls" (
goto ls
) else ( 
%lcm%
goto cl
)

:pwd
cd
goto cl

:help
help
echo.
echo - - - - -extended commands- - - - - - -
echo LS       List command. Same as dir
echo.
goto cl

:lshelp
help dir
goto cl

:ls
dir
goto cl

:endf
echo      ...Goodbye !
PING 1.1.1.1 -n 2 -w 1000 >NUL
echo on


