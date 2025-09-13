@echo off
REM Tenjo Remote Stealth Uninstaller for Windows

setlocal enabledelayedexpansion

REM Configuration
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "SERVICE_NAME=TenjoMonitor"

echo [%date% %time%] Starting Tenjo stealth uninstallation...

REM Stop and remove scheduled task
echo [%date% %time%] Stopping and removing scheduled task...
schtasks /end /tn "%SERVICE_NAME%" >nul 2>&1
schtasks /delete /tn "%SERVICE_NAME%" /f >nul 2>&1
echo [%date% %time%] Scheduled task removed

REM Kill running client processes
echo [%date% %time%] Stopping running client processes...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im pythonw.exe >nul 2>&1

REM Remove installation directory
if exist "%INSTALL_DIR%" (
    echo [%date% %time%] Removing installation directory...
    rmdir /s /q "%INSTALL_DIR%"
    echo [%date% %time%] Installation directory removed
)

REM Clean up any remaining processes
timeout /t 2 >nul
taskkill /f /im python.exe >nul 2>&1

echo.
echo ================================
echo Tenjo client has been completely uninstalled!
echo All files and services have been removed.
echo ================================

pause
