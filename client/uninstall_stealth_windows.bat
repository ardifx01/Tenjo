@echo off
setlocal enabledelayedexpansion

:: Tenjo Stealth Uninstaller for Windows
:: This script completely removes the monitoring client

:: Configuration
set APP_NAME=SystemUpdate
set INSTALL_DIR=%APPDATA%\SystemUpdate
set SERVICE_NAME=SystemUpdateService

:: Silent mode check
set SILENT=%1
if "%SILENT%"=="" set SILENT=false

:: Admin check
net session >nul 2>&1
if %errorLevel% == 0 (
    set INSTALL_DIR=%PROGRAMDATA%\SystemUpdate
)

if not "%SILENT%"=="true" (
    echo [INFO] Uninstalling System Update Service...
)

:: Stop all related processes
if not "%SILENT%"=="true" echo [INFO] Stopping service...
taskkill /F /IM "stealth_main.exe" >nul 2>&1
taskkill /F /IM "python.exe" /FI "WINDOWTITLE eq SystemUpdate*" >nul 2>&1
taskkill /F /IM "pythonw.exe" /FI "WINDOWTITLE eq SystemUpdate*" >nul 2>&1

:: Stop and remove scheduled task
schtasks /End /TN "%SERVICE_NAME%" >nul 2>&1
schtasks /Delete /TN "%SERVICE_NAME%" /F >nul 2>&1

:: Kill any remaining Python processes related to our app
for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV ^| findstr /i "stealth_main\|main.py"') do (
    taskkill /F /PID %%i >nul 2>&1
)

:: Remove installation directory
if exist "%INSTALL_DIR%" (
    rmdir /S /Q "%INSTALL_DIR%" >nul 2>&1
    if not "%SILENT%"=="true" echo [SUCCESS] Removed application files
)

:: Clean up any remaining registry entries (if any were created)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%SERVICE_NAME%" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "%SERVICE_NAME%" /f >nul 2>&1

if not "%SILENT%"=="true" (
    echo [SUCCESS] System Update Service uninstalled successfully
    echo.
    echo The monitoring service has been completely removed.
    echo All files and background processes have been cleaned up.
    pause
)

endlocal
