@echo off
for /f "usebackq tokens=2 delims=:" %%f in (`ipconfig ^| findstr /c:"IP"`) do (
    echo%%f
    goto :eof
)
