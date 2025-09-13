@echo off
:: Test script for Windows installer
:: This can be copied to Windows machine for testing

echo === TESTING WINDOWS INSTALLER DOWNLOAD ===
echo.
echo 1. Downloading Windows installer...

:: Download the installer
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_install_stealth_windows.bat' -OutFile 'tenjo_installer.bat'"

if exist tenjo_installer.bat (
    echo ✅ Installer downloaded successfully
    echo.
    echo 2. File size check:
    dir tenjo_installer.bat
    echo.
    echo 3. Quick content verification:
    findstr /i "Auto IP" tenjo_installer.bat
    findstr /i "progress" tenjo_installer.bat
    echo.
    echo === READY FOR INSTALLATION ===
    echo To install: tenjo_installer.bat
    echo.
    echo Features included:
    echo ✅ Auto IP detection
    echo ✅ 8-step progress indicators  
    echo ✅ Auto client registration
    echo ✅ Stealth mode operation
    echo ✅ Error handling and recovery
) else (
    echo ❌ Download failed
    echo Check internet connection and try again
)

pause
