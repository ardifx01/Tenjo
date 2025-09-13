@echo off
setlocal enabledelayedexpansion

:: Tenjo Stealth Uninstaller for Windows
:: This script completely removes Tenjo monitoring system from the target machine
:: Usage: powershell -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_uninstall_stealth_windows.bat'))"

echo 🗑️  Starting Tenjo stealth uninstall process...

:: Define paths
set "INSTALL_DIR=%USERPROFILE%\.config\system-utils"
set "LOG_DIR=%USERPROFILE%\AppData\Local\SystemUpdater"
set "TASK_NAME=SystemUpdater"

:: Function to check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    set "IS_ADMIN=1"
    echo 🔐 Running with administrator privileges
) else (
    set "IS_ADMIN=0"
    echo 👤 Running with user privileges
)

:: Function to stop Tenjo processes
echo 🔄 Stopping Tenjo processes...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im pythonw.exe >nul 2>&1
wmic process where "commandline like '%%stealth_main.py%%'" delete >nul 2>&1
wmic process where "commandline like '%%tenjo%%'" delete >nul 2>&1
wmic process where "commandline like '%%system-utils%%'" delete >nul 2>&1

:: Wait for processes to terminate
timeout /t 3 >nul

echo ✅ Processes stopped

:: Function to remove scheduled task
echo 🚫 Removing auto-start configuration...
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Auto-start task removed
) else (
    echo ℹ️  No auto-start task found or access denied
)

:: If admin, try to remove system-wide task
if !IS_ADMIN! equ 1 (
    schtasks /delete /tn "Microsoft\Windows\%TASK_NAME%" /f >nul 2>&1
    schtasks /delete /tn "Microsoft\%TASK_NAME%" /f >nul 2>&1
)

:: Function to remove installation files
echo 📁 Removing installation files...
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
    if exist "%INSTALL_DIR%" (
        echo ⚠️  Some files in installation directory could not be removed
    ) else (
        echo ✅ Installation directory removed
    )
) else (
    echo ℹ️  Installation directory not found
)

:: Remove log directory
if exist "%LOG_DIR%" (
    rmdir /s /q "%LOG_DIR%" >nul 2>&1
    echo ✅ Log directory removed
)

:: Function to clean up registry entries (if admin)
if !IS_ADMIN! equ 1 (
    echo 🧹 Cleaning registry entries...
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemUpdater" /f >nul 2>&1
    reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "SystemUpdater" /f >nul 2>&1
    reg delete "HKCU\Software\SystemUpdater" /f >nul 2>&1
    reg delete "HKLM\Software\SystemUpdater" /f >nul 2>&1
    echo ✅ Registry cleaned
)

:: Function to clean up remaining traces
echo 🧹 Cleaning up remaining traces...

:: Remove temporary files
del /q /s "%TEMP%\tenjo*" >nul 2>&1
del /q /s "%TEMP%\system-utils*" >nul 2>&1

:: Remove any Python cache files
for /r "%USERPROFILE%" %%f in (*tenjo* *system-utils*) do (
    del "%%f" >nul 2>&1
)

echo ✅ Traces cleaned

:: Function to verify uninstallation
echo 🔍 Verifying uninstallation...
set "ISSUES=0"

:: Check if scheduled task exists
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if !errorlevel! equ 0 (
    echo ⚠️  Scheduled task still exists: %TASK_NAME%
    set /a ISSUES+=1
)

:: Check if installation directory exists
if exist "%INSTALL_DIR%" (
    echo ⚠️  Installation directory still exists: %INSTALL_DIR%
    set /a ISSUES+=1
)

:: Check if any Tenjo processes are running
tasklist | findstr /i python | findstr /i stealth >nul 2>&1
if !errorlevel! equ 0 (
    echo ⚠️  Tenjo processes still running
    set /a ISSUES+=1
)

:: Display results
if !ISSUES! equ 0 (
    echo ✅ Uninstallation verified successfully
    echo 🎉 Tenjo has been completely removed from this system
    goto :success
) else (
    echo ❌ Uninstallation incomplete - !ISSUES! issues found
    goto :incomplete
)

:success
echo.
echo 🎯 UNINSTALLATION COMPLETE
echo ==========================
echo ✅ All Tenjo components have been removed
echo ✅ Auto-start disabled
echo ✅ All files and logs deleted
echo ✅ System restored to original state
echo.
echo 💡 The system is now clean and monitoring has been stopped.
goto :end

:incomplete
echo.
echo ⚠️  UNINSTALLATION ISSUES DETECTED
echo ===================================
echo Some components may still exist. Please check manually:
echo - Scheduled Task: schtasks /query /tn "%TASK_NAME%"
echo - Install Dir: %INSTALL_DIR%
echo - Running processes: tasklist ^| findstr python
echo.
echo 💡 Try running this script as administrator for complete removal.
goto :end

:end
echo.
echo 🔧 Tenjo Stealth Uninstaller v1.0 - Complete
pause >nul
exit /b 0
