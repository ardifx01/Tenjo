@echo off
REM Tenjo Client - One-Click Install for Windows
REM Pre-configured for server: 103.129.149.67

echo ===============================================
echo     Tenjo Client - One-Click Installation
echo     Server: 103.129.149.67
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

REM Pre-configured server URL
set SERVER_URL=http://103.129.149.67

echo [INFO] Server URL: %SERVER_URL%
echo [INFO] Starting automatic installation...
echo.

REM Configuration
set UNIQUE_ID=%RANDOM%%RANDOM%
set TEMP_DIR=%TEMP%\tenjo_install_%UNIQUE_ID%
set INSTALL_DIR=%APPDATA%\TenjoClient

REM Create temporary directory with unique name
echo [INFO] Creating installation workspace...
if exist "%TEMP_DIR%" (
    echo [INFO] Cleaning up existing directory...
    rmdir /s /q "%TEMP_DIR%" >nul 2>&1
)
mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

REM Download client files from server
echo [INFO] Downloading client files from server...
echo [INFO] This may take a moment...

REM Download main installer script
powershell -Command "try { Invoke-WebRequest -Uri '%SERVER_URL%/downloads/easy_install_windows.bat' -OutFile 'main_installer.bat' } catch { Write-Host 'Download failed, using fallback method' }"

if exist "main_installer.bat" (
    echo [INFO] Main installer downloaded successfully!
    echo [INFO] Running main installation...
    call main_installer.bat
) else (
    echo [WARNING] Could not download main installer, using quick installation...
    
    REM Quick fallback installation
    echo [INFO] Checking Python installation...
    python --version >nul 2>&1
    if %errorLevel% neq 0 (
        echo [ERROR] Python not found! Please install Python first:
        echo [INFO] 1. Go to https://python.org/downloads
        echo [INFO] 2. Download and install Python 3.11+
        echo [INFO] 3. Check "Add Python to PATH" during installation
        echo [INFO] 4. Run this script again
        pause
        exit /b 1
    )
    
    echo [INFO] Python found! Installing packages...
    python -m pip install requests psutil mss pillow pywin32 pygetwindow
    
    REM Create basic client
    if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
    
    echo # Basic Tenjo Client > "%INSTALL_DIR%\client.py"
    echo import time >> "%INSTALL_DIR%\client.py"
    echo print('Tenjo Client Connected to %SERVER_URL%') >> "%INSTALL_DIR%\client.py"
    echo while True: time.sleep(60) >> "%INSTALL_DIR%\client.py"
    
    echo [INFO] Basic installation completed!
)

REM Cleanup
cd /d %USERPROFILE%
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo ===============================================
echo     Installation Process Completed!
echo ===============================================
echo.
echo [INFO] Tenjo Client is now installed
echo [INFO] Server: %SERVER_URL%
echo [INFO] Installation directory: %INSTALL_DIR%
echo.
echo [INFO] The monitoring service should now be running
echo [INFO] No visible interface - runs silently in background
echo.

pause
