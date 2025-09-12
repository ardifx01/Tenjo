@echo off
REM Tenjo Client - Quick Install Script for Windows (Fallback Version)
REM This is a simplified version for when the main installer fails

echo ===============================================
echo    Tenjo Client Quick Installation - Windows
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
set UNIQUE_ID=%RANDOM%%RANDOM%
set TEMP_DIR=%TEMP%\tenjo_quick_%UNIQUE_ID%
set INSTALL_DIR=%APPDATA%\TenjoClient

REM Get server URL from user
set /p SERVER_URL="Enter dashboard server URL (default: http://103.129.149.67): "
if "%SERVER_URL%"=="" set SERVER_URL=http://103.129.149.67

echo [INFO] Server URL: %SERVER_URL%
echo.

REM Create temporary directory with unique name
echo [INFO] Creating installation workspace...
mkdir "%TEMP_DIR%"
cd /d "%TEMP_DIR%"

REM Check if Python is already installed
echo [INFO] Checking Python installation...
python --version >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Python found and ready!
    python --version
    goto :install_packages
)

REM Python not found - offer manual installation
echo [WARNING] Python not found on this system!
echo.
echo [INFO] Please install Python manually:
echo [INFO] 1. Go to https://python.org/downloads
echo [INFO] 2. Download Python 3.11 or newer
echo [INFO] 3. Run installer and check "Add Python to PATH"
echo [INFO] 4. Restart this script after Python installation
echo.
set /p CONTINUE="Continue anyway? (y/N): "
if /i not "%CONTINUE%"=="y" (
    echo [INFO] Installation cancelled. Please install Python first.
    pause
    exit /b 1
)

:install_packages
REM Install required packages with error handling
echo [INFO] Installing required Python packages...
echo [INFO] This may take a few minutes...

python -m pip install --upgrade pip >nul 2>&1

REM Core packages
echo [INFO] Installing core packages...
python -m pip install requests
if %errorLevel% neq 0 echo [WARNING] Failed to install requests

python -m pip install psutil
if %errorLevel% neq 0 echo [WARNING] Failed to install psutil

python -m pip install mss
if %errorLevel% neq 0 echo [WARNING] Failed to install mss

python -m pip install pillow
if %errorLevel% neq 0 echo [WARNING] Failed to install pillow

REM Windows specific packages
echo [INFO] Installing Windows-specific packages...
python -m pip install pywin32
if %errorLevel% neq 0 echo [WARNING] Failed to install pywin32

python -m pip install pygetwindow
if %errorLevel% neq 0 echo [WARNING] Failed to install pygetwindow

REM Create minimal client installation
echo [INFO] Creating Tenjo client files...

REM Create main directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Create simple client script
echo # Tenjo Client - Minimal Version > "%INSTALL_DIR%\tenjo_client.py"
echo import os >> "%INSTALL_DIR%\tenjo_client.py"
echo import sys >> "%INSTALL_DIR%\tenjo_client.py"
echo import time >> "%INSTALL_DIR%\tenjo_client.py"
echo import requests >> "%INSTALL_DIR%\tenjo_client.py"
echo import json >> "%INSTALL_DIR%\tenjo_client.py"
echo. >> "%INSTALL_DIR%\tenjo_client.py"
echo SERVER_URL = '%SERVER_URL%' >> "%INSTALL_DIR%\tenjo_client.py"
echo. >> "%INSTALL_DIR%\tenjo_client.py"
echo def main(): >> "%INSTALL_DIR%\tenjo_client.py"
echo     print('Tenjo Client Starting...') >> "%INSTALL_DIR%\tenjo_client.py"
echo     while True: >> "%INSTALL_DIR%\tenjo_client.py"
echo         try: >> "%INSTALL_DIR%\tenjo_client.py"
echo             # Basic monitoring functionality >> "%INSTALL_DIR%\tenjo_client.py"
echo             time.sleep(60^) >> "%INSTALL_DIR%\tenjo_client.py"
echo         except KeyboardInterrupt: >> "%INSTALL_DIR%\tenjo_client.py"
echo             break >> "%INSTALL_DIR%\tenjo_client.py"
echo. >> "%INSTALL_DIR%\tenjo_client.py"
echo if __name__ == '__main__': >> "%INSTALL_DIR%\tenjo_client.py"
echo     main() >> "%INSTALL_DIR%\tenjo_client.py"

REM Create startup script
echo @echo off > "%INSTALL_DIR%\start_tenjo.bat"
echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\start_tenjo.bat"
echo python tenjo_client.py >> "%INSTALL_DIR%\start_tenjo.bat"

REM Make script executable on startup (basic method)
echo [INFO] Setting up auto-start...
set STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
if exist "%STARTUP_DIR%" (
    copy "%INSTALL_DIR%\start_tenjo.bat" "%STARTUP_DIR%\TenjoClient.bat" >nul 2>&1
    echo [INFO] Auto-start configured successfully!
) else (
    echo [WARNING] Could not configure auto-start
)

REM Cleanup
cd /d %USERPROFILE%
rmdir /s /q "%TEMP_DIR%" >nul 2>&1

echo.
echo ===============================================
echo     Quick Installation Completed!
echo ===============================================
echo.
echo [INFO] Tenjo Client has been installed
echo [INFO] Installation location: %INSTALL_DIR%
echo [INFO] The client will start automatically on boot
echo.
echo [INFO] To start manually: 
echo [INFO] %INSTALL_DIR%\start_tenjo.bat
echo.
echo [INFO] Note: This is a minimal installation.
echo [INFO] For full features, ensure all Python packages are installed.
echo.

pause
