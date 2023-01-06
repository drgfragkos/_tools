@echo off
REM to run this use cmd and give "batparam.bat [filename]"
REM see "Using batch parameters" for more info
echo.
echo %0
echo %~1
echo %~f1
echo %~d1
echo %~p1
echo %~n1
echo %~x1
echo %~s1
echo %~a1
echo %~t1
echo %~z1
echo %~$PATH:1
echo.
pause