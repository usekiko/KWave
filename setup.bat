@echo off
title KWave Server - First Time Setup
color 0B

echo.
echo  KWave Framework - First Time Setup
echo  ─────────────────────────────────────────────
echo.

:: ─── Check for admin rights ───
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrator privileges!
    echo         Right-click setup.bat and choose "Run as administrator"
    pause
    exit /b 1
)

set ARTIFACTS=%~dp0artifacts
set FXSERVER=%ARTIFACTS%\FXServer.exe

echo [1/3] Checking artifacts...
if not exist "%FXSERVER%" (
    echo       [FAIL] FXServer.exe not found in artifacts\
    echo              Please re-run the server download.
    pause
    exit /b 1
)
echo       [OK] FXServer.exe found - Build 2289

echo.
echo [2/3] Adding Windows Firewall rules for FiveM (port 30120 TCP+UDP)...
netsh advfirewall firewall delete rule name="KWave FiveM TCP" >nul 2>&1
netsh advfirewall firewall delete rule name="KWave FiveM UDP" >nul 2>&1
netsh advfirewall firewall add rule name="KWave FiveM TCP" dir=in action=allow protocol=TCP localport=30120
netsh advfirewall firewall add rule name="KWave FiveM UDP" dir=in action=allow protocol=UDP localport=30120
echo       [OK] Firewall rules added

echo.
echo [3/3] Setup complete!
echo.
echo  ┌─────────────────────────────────────────────┐
echo  │  HOW TO CONNECT                             │
echo  │                                             │
echo  │  1. Run start.bat to launch the server      │
echo  │  2. Open FiveM client                       │
echo  │  3. Press F8 and type:                      │
echo  │       connect localhost:30120               │
echo  │                                             │
echo  │  BEFORE STARTING:                           │
echo  │  - Set your PostgreSQL connection string    │
echo  │    in server.cfg (pgsql_connection_string)  │
echo  │  - Run kwave.sql on your PostgreSQL server  │
echo  │    found in [SQL]\kwave.sql                 │
echo  └─────────────────────────────────────────────┘
echo.
pause
