@echo off
rem created by Grigorios Fragkos 08/10/02, e-mail me at: gfragkos@glam.ac.uk
rem Takes advantage of the net send command on windows networks to simulater "irc"-like chat behaviour using command prompt windows. 
rem Simple program to show how to prompt the user
rem for an input and manipulate that input with 
rem if statements in order to help you check and chat
rem your friends at the UNI network.
rem This source code is 'open source' but must mention the original author: Grigorios Fragkos
rem Fill free to modify the source code but must be always 'open source'
rem previous lines plus current must always be added to your modifications

:restart
set v=1

rem If you want to change the color of 
rem the startup screen change the parameter
color 1a

:loop

cls
rem +++Replace NameXX with your friends alias
echo * * * chkUNInet v2.0 by:gfragkos * * *                             [Esc] Ctrl+C
echo.
echo 01-Name01    07-Name07      13-Name13
echo 02-Name02    08-Name08      14-Name14
echo 03-Name03    09-Name09      15-Name15
echo 04-Name04    10-Name10      16-Name16
echo 05-Name05    11-Name11      17-Name17
echo 06-Name06    12-Name12      me-YourAlias
echo -------------------------------------------------------------------------------
echo all   msg   chat   syspec   style   cmd   help   restart   exit
echo -------------------------------------------------------------------------------
echo * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
echo.

set /p var1= Please enter Number: 
rem echo You entered %var1%

rem +++Replace 00000000 with your friends EN (E/N for Name01)
if "%var1%" == "1" (
echo.
echo * * checking for Name01...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "2" (
echo.
echo * * checking for Name02...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "3" (
echo.
echo * * checking for Name03...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "4" (
echo.
echo * * checking for Name04...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "5" (
echo.
echo * * checking for Name05...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "6" (
echo.
echo * * checking for Name06...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "7" (
echo.
echo * * checking for Name07...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "8" (
echo.
echo * * checking for Name08...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "9" (
echo.
echo * * checking for Name09...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
)
if "%var1%" == "10" (
echo.
echo * * checking for Name10...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "11" (
echo.
echo * * checking for Name11...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "12" (
echo.
echo * * checking for Name12...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "13" (
echo.
echo * * checking for Name13...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "14" (
echo.
echo * * checking for Name14...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "15" (
echo.
echo * * checking for Name15...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "16" (
echo.
echo * * checking for Name16...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "17" (
echo.
echo * * checking for Name17...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "me" (
echo.
echo * * checking for YourAlias...
net send 00000000 R U IN?
echo * * * * * * * * * * * * * * * * * * * *
PING 1.1.1.1 -n 2 -w 1000 >NUL
goto loop
) 
if "%var1%" == "help" (
echo.
goto helptxt
) 
if "%var1%" == "style" (
goto col
) 
if "%var1%" == "cmd" (
goto cl
) 
if "%var1%" == "msg" (
goto msglabel
) 
if "%var1%" == "restart" (
goto restart
) 
if "%var1%" == "chat" (
echo.
start chat_.bat
goto loop
) 
if "%var1%" == "syspec" (
echo.
ver
echo  Operating System .. %os%
echo  Computer Name ..... %computername%
echo  LogonServer ....... %logonserver%
echo  UserDomain ........ %USERDOMAIN%
echo  UserName .......... %USERNAME%
echo  ProcessorID ....... %PROCESSOR_IDENTIFIER%
echo.
ipconfig
echo.
pause
goto loop
) 
rem +++Replace 00000000 with the EN of your friends
if "%var1%" == "all" (
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
net send 00000000 R U IN?
pause
goto loop
) 
if "%var1%" == "exit" (
echo      ...Goodbye !
PING 1.1.1.1 -n 3 -w 1000 >NUL
goto endf
) else ( 
set /p var2= Wrong Input. Try again...
goto loop 
)

:msglabel
echo.
echo   [insert E/N or Remote Computer Name within [msg] command]
echo.
set /p gf= send to: 
set /p fg= message: 
set sd=net send %gf% %fg%
%sd%
echo.
pause
goto loop

:cl
echo off
set /p cm= Yes Master: 
if "%cm%" == "exit" (
goto loop
) else ( 
%cm%
goto cl
)

:col
if "%v%" == "1" (
color f0
set v=2
goto loop
) else ( 
color 0f
set v=1
goto loop 
)

:helptxt
cls
echo.
echo  - HELP Documentation - - - - - - - - - - - - - - - - - - - - - - - - - -
echo - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo.
echo * * * Check - Chat @ UNInet v2.0 by:$0cr4t3$ * * *
echo.
echo  01-Name01   00000000   11-Name13   00000000
echo  02-Name02   00000000   12-Name14   00000000
echo  03-Name03   00000000   13-Name15   00000000
echo  04-Name04   00000000   14-Name16   00000000
echo  05-Name05   00000000   15-Name17   00000000
echo  06-Name06   00000000   16-Name18   00000000
echo  07-Name07   00000000   17-Name17   00000000
echo  08-Name08   00000000
echo  09-Name09   00000000
echo  10-Name10   00000000
echo.
echo *To add your contact list just use the [Find and Replace all] command
echo   of any text editor e.g. if you replace all myContact14 with a name
echo   of a friend and the number 00000014 with his E/N will work perfect
echo   for u. If there is a syntax problem with spaces open chkUNInet in
echo   a text editor and just add or take out spaces.
echo.
echo  +-----------------------------------------------------------------------
echo  ]
echo  ] all ....... Will message all your friends to check who has loged on
echo  ] msg ....... Will message a new friend (not in the list) asking for
echo  ]              his E/N or the remote computer name that he has loged on
echo  ] chat ...... Will start a new terminal in order to help you chat with
echo  ]              a specific friend from your list
echo  ] syspec .... Will Prompt you the local system configuration
echo  ] style ..... Will change the colors of your lan chat.
echo  ] cmd ....... LanChat will respond as CMD.exe Type exit to return.
echo  ] help ...... Provides the current help screen. 
echo  ]               - Simply press enter to repeat your last command.
echo  ]               - Type cmd and then edit chkUNInet.bat in order to edit
echo  ]                   the source code. At the 16th line from the top you
echo  ]                   can change the parameter of color command in order
echo  ]                   to change the startup color of the program.
echo  ]               - If the program does not respond press CTRL+C
echo  ]                   ..in case nothing happens press again until you 'll
echo  ]                   be prompt [Terminate batch job (Y/N)?] press Y if
echo  ]                   you want to exit LanChat or Press N if you want 
echo  ]                   LanChat to start over.
echo  ]               - Any suggestions, comments, bugs, new versions please
echo  ]                 send them to djgreg_@hotmail.com
echo  ] restart ... will restart the program.
echo  ] exit ...... Will terminate the program by saying you Goodbye !
echo  ]
echo  +-----------------------------------------------------------------------
echo   * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
echo.
echo.
echo                                     Thank you for using chkUNInet
echo                                               $0cr4t3$
echo.
echo.
pause
goto loop


:ena
rem echo printa
goto end

:dio
rem echo printb
goto end

:tria
rem echo printb
goto end

:tessera
rem echo printb
goto end

:pente
rem echo printb
goto end

:eksi
rem echo printb
goto end

:efta
rem echo printb
goto end

:oxto
rem echo printb
goto end

:enia
rem echo printb
goto end

:deka
rem echo not available wet...
goto end


:end

pause

:endf

echo on
