@echo off
REM Tenjo Client - Uninstall Script for Windows
REM Run this script as Administrator to completely remove Tenjo monitoring client

echo ===============================================
echo     Tenjo Client Uninstallation - Windows
echo ===============================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Running as Administrator - Good!
) else (
    echo [ERROR] This script must be run as Administrator!
    echo [INFO] Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

REM Confirm uninstallation
set /p CONFIRM="Are you sure you want to uninstall Tenjo Client? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo [INFO] Starting uninstallation process...

REM Stop and remove Windows service
echo [INFO] Removing Windows service...
sc stop "system_update_service" >nul 2>&1
schtasks /delete /tn "system_update_service" /f >nul 2>&1
sc delete "SystemUpdateService" >nul 2>&1
echo [INFO] Service removed

REM Remove from registry startup
echo [INFO] Removing startup entries...
reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SystemUpdate" /f >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SystemUpdate" /f >nul 2>&1
echo [INFO] Startup entries removed

REM Kill any running processes
echo [INFO] Stopping any running Tenjo processes...
taskkill /f /im "python.exe" /fi "WINDOWTITLE eq System Update Service" >nul 2>&1
taskkill /f /im "pythonw.exe" /fi "WINDOWTITLE eq System Update Service" >nul 2>&1
wmic process where "name='python.exe' and commandline like '%%tenjo%%'" delete >nul 2>&1
wmic process where "name='pythonw.exe' and commandline like '%%tenjo%%'" delete >nul 2>&1

REM Remove installation directories
echo [INFO] Removing installation files...

set INSTALL_DIR=%APPDATA%\SystemUpdate
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%"
    echo [INFO] Installation directory removed: %INSTALL_DIR%
) else (
    echo [WARNING] Installation directory not found: %INSTALL_DIR%
)

REM Remove alternative directories
set ALT_DIR1=%APPDATA%\.system_cache
set ALT_DIR2=%LOCALAPPDATA%\SystemUpdate
set ALT_DIR3=C:\ProgramData\SystemUpdate

if exist "%ALT_DIR1%" (
    rmdir /s /q "%ALT_DIR1%"
    echo [INFO] Removed: %ALT_DIR1%
)

if exist "%ALT_DIR2%" (
    rmdir /s /q "%ALT_DIR2%"
    echo [INFO] Removed: %ALT_DIR2%
)

if exist "%ALT_DIR3%" (
    rmdir /s /q "%ALT_DIR3%"
    echo [INFO] Removed: %ALT_DIR3%
)

REM Clean up Python packages (optional)
echo.
set /p CLEAN_PACKAGES="Do you want to remove Python packages installed for Tenjo? (y/N): "
if /i "%CLEAN_PACKAGES%"=="y" (
    echo [INFO] Removing Python packages...
    python -m pip uninstall -y mss psutil pywin32 pygetwindow >nul 2>&1
    echo [INFO] Python packages removed
)

echo.
echo ===============================================
echo     Uninstallation Completed Successfully!
echo ===============================================
echo.
echo [INFO] Tenjo Client has been completely removed from your system
echo [INFO] All monitoring processes have been stopped
echo [INFO] Auto-start services have been disabled
echo.
echo [INFO] Thank you for using Tenjo Client!
echo.

pause
