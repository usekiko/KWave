@echo off
title KWave - PostgreSQL Setup
color 0B

:: ─────────────────────────────────────────────────────────────────
::  KWave Framework - PostgreSQL 17 Localhost Setup
::  Downloads and installs PostgreSQL 17, then creates the kwave DB
:: ─────────────────────────────────────────────────────────────────

echo.
echo  KWave Framework - PostgreSQL Setup
echo  ─────────────────────────────────────────────
echo.

:: ─── Require Admin ───────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run this script as Administrator!
    echo         Right-click ^> "Run as administrator"
    pause
    exit /b 1
)

:: ─── Config ───────────────────────────────────────────────────────
set PG_VERSION=17
set PG_MINOR=17.5
set PG_INSTALLER=%TEMP%\postgresql_installer.exe
set PG_INSTALL_DIR=C:\Program Files\PostgreSQL\17
set PG_BIN=%PG_INSTALL_DIR%\bin
set PG_PASSWORD=kwave_password
set DB_NAME=kwave

:: ─── Check if already installed ──────────────────────────────────
if exist "%PG_BIN%\psql.exe" (
    echo [INFO] PostgreSQL %PG_VERSION% is already installed.
    goto :create_db
)

:: ─── Download installer ───────────────────────────────────────────
echo [1/3] Downloading PostgreSQL %PG_MINOR% installer...
echo       This may take a minute depending on your connection.
echo.
powershell -Command "Invoke-WebRequest -Uri 'https://get.enterprisedb.com/postgresql/postgresql-%PG_MINOR%-1-windows-x64.exe' -OutFile '%PG_INSTALLER%' -UseBasicParsing"

if not exist "%PG_INSTALLER%" (
    echo [ERROR] Download failed. Check your internet connection.
    pause
    exit /b 1
)
echo       Download complete!

:: ─── Silent install ───────────────────────────────────────────────
echo.
echo [2/3] Installing PostgreSQL silently...
echo       Password for 'postgres' user: %PG_PASSWORD%
echo.
"%PG_INSTALLER%" ^
  --mode unattended ^
  --unattendedmodeui none ^
  --superpassword "%PG_PASSWORD%" ^
  --serverport 5432 ^
  --prefix "%PG_INSTALL_DIR%" ^
  --datadir "%PG_INSTALL_DIR%\data" ^
  --enable-components server,commandlinetools ^
  --disable-components pgAdmin,stackbuilder

if %errorlevel% neq 0 (
    echo [ERROR] Installation failed. Try running the installer manually.
    start "" "https://www.postgresql.org/download/windows/"
    pause
    exit /b 1
)

echo       Installation complete!
del "%PG_INSTALLER%" >nul 2>&1

:: ─── Add to PATH ──────────────────────────────────────────────────
setx PATH "%PATH%;%PG_BIN%" >nul 2>&1
set PATH=%PATH%;%PG_BIN%

:: ─── Create kwave database ────────────────────────────────────────
:create_db
echo.
echo [3/3] Creating '%DB_NAME%' database...
echo.

set PGPASSWORD=%PG_PASSWORD%
"%PG_BIN%\psql.exe" -U postgres -c "SELECT 1 FROM pg_database WHERE datname = '%DB_NAME%'" 2>nul | findstr "1" >nul

if %errorlevel% equ 0 (
    echo       Database '%DB_NAME%' already exists, skipping creation.
) else (
    "%PG_BIN%\psql.exe" -U postgres -c "CREATE DATABASE %DB_NAME%;"
    if %errorlevel% equ 0 (
        echo       Database '%DB_NAME%' created successfully!
    ) else (
        echo [WARN] Could not create database automatically.
        echo        Do it manually: createdb -U postgres kwave
    )
)

:: ─── Apply KWave SQL schema ───────────────────────────────────────
set SQL_SCHEMA=%~dp0[SQL]\kwave.sql
if exist "%SQL_SCHEMA%" (
    echo.
    echo [BONUS] Applying KWave schema to '%DB_NAME%' database...
    "%PG_BIN%\psql.exe" -U postgres -d %DB_NAME% -f "%SQL_SCHEMA%"
    echo       Schema applied!
) else (
    echo [INFO] No schema found at [SQL]\kwave.sql — run it manually later.
)

:: ─── Done! ────────────────────────────────────────────────────────
echo.
echo  ┌─────────────────────────────────────────────────────┐
echo  │  ✅  PostgreSQL is ready!                           │
echo  │                                                     │
echo  │  Host:     localhost                                │
echo  │  Port:     5432                                     │
echo  │  User:     postgres                                 │
echo  │  Password: %PG_PASSWORD%                   │
echo  │  Database: %DB_NAME%                                │
echo  │                                                     │
echo  │  Connection string for server.cfg:                  │
echo  │  postgresql://postgres:%PG_PASSWORD%@localhost/%DB_NAME%?sslmode=disable
echo  │                                                     │
echo  │  pgAdmin is NOT installed (lighter install).        │
echo  │  Use: psql -U postgres -d kwave                     │
echo  │  Or install DBeaver (free): https://dbeaver.io      │
echo  └─────────────────────────────────────────────────────┘
echo.
pause
