@echo off
title KWave FiveM Server
color 0A

set FIVEM_ROOT=%~dp0
if "%FIVEM_ROOT:~-1%"=="\" set FIVEM_ROOT=%FIVEM_ROOT:~0,-1%

set ARTIFACTS=%FIVEM_ROOT%\artifacts
set SERVER_CFG=%FIVEM_ROOT%\server.cfg

echo.
echo  ██╗  ██╗██╗    ██╗ █████╗ ██╗   ██╗███████╗
echo  ██║ ██╔╝██║    ██║██╔══██╗██║   ██║██╔════╝
echo  █████╔╝ ██║ █╗ ██║███████║██║   ██║█████╗
echo  ██╔═██╗ ██║███╗██║██╔══██║╚██╗ ██╔╝██╔══╝
echo  ██║  ██╗╚███╔███╔╝██║  ██║ ╚████╔╝ ███████╗
echo  ╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝  ╚═══╝  ╚══════╝
echo.
echo  KWave Framework Server - localhost:30120
echo  ─────────────────────────────────────────────
echo.

if not exist "%ARTIFACTS%\FXServer.exe" (
    echo [ERROR] FXServer.exe not found.
    echo         Run: extract_artifacts.bat first
    pause & exit /b 1
)

echo  Root:   %FIVEM_ROOT%
echo  Build:  25770 (Recommended)
echo.

"%ARTIFACTS%\FXServer.exe" +set serverProfile "default"

echo.
echo  Server stopped. Press any key to exit...
pause >nul
