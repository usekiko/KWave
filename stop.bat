@echo off
title KWave FiveM Server - STOP
color 0C

echo Stopping KWave FiveM Server...
taskkill /f /im FXServer.exe 2>nul
if %errorlevel% equ 0 (
    echo Server stopped successfully.
) else (
    echo No running server found.
)
pause
