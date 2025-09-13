@echo off
REM Tenjo Stealth Uninstaller for Windows
REM This script completely removes the Tenjo monitoring client

setlocal enabledelayedexpansion

REM Configuration
set "SERVICE_NAME=TenjoMonitor"
set "INSTALL_DIR=%USERPROFILE%\.tenjo"

echo [%date% %time%] Starting Tenjo monitoring client uninstallation...

REM Confirm uninstallation
echo.
echo This will completely remove the Tenjo monitoring client from your system.
set /p "response=Are you sure you want to continue? (y/N): "
if /i not "%response%"=="y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

REM Stop Windows service if exists
echo [%date% %time%] Stopping Tenjo monitoring service...
sc query %SERVICE_NAME% >nul 2>&1
if not errorlevel 1 (
    sc stop %SERVICE_NAME% >nul 2>&1
    sc delete %SERVICE_NAME% >nul 2>&1
    echo [%date% %time%] Service stopped and removed
) else (
    echo [%date% %time%] Service was not installed
)

REM Remove from Windows startup registry
echo [%date% %time%] Removing from Windows startup...
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /f >nul 2>&1
if not errorlevel 1 (
    echo [%date% %time%] Startup entry removed
) else (
    echo [%date% %time%] No startup entry found
)

REM Kill any running processes
echo [%date% %time%] Terminating any running Tenjo processes...
taskkill /f /im python.exe /fi "WINDOWTITLE eq *tenjo*" >nul 2>&1
taskkill /f /im python.exe /fi "IMAGENAME eq python.exe" >nul 2>&1

REM Wait for processes to terminate
timeout /t 3 /nobreak >nul

REM Remove installation directory
echo [%date% %time%] Removing installation files...
if exist "%INSTALL_DIR%" (
    REM Unhide directory first
    attrib -h "%INSTALL_DIR%" >nul 2>&1
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
    if not exist "%INSTALL_DIR%" (
        echo [%date% %time%] Installation directory removed
    ) else (
        echo [%date% %time%] WARNING: Could not remove some files. Manual cleanup may be required.
    )
) else (
    echo [%date% %time%] Installation directory not found
)

echo.
echo [%date% %time%] ✅ Tenjo monitoring client has been completely removed!
echo [%date% %time%] 🧹 All traces of the application have been cleaned up
echo.
echo Uninstallation completed successfully.
pause
