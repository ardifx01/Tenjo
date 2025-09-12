@echo off
REM Tenjo Client - One-Line Installer for Windows
REM Download and run: https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/install.bat

echo ===============================================
echo     Tenjo Client - One-Line Installer
echo ===============================================
echo.

REM Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause & exit /b 1
)

REM Get server URL
set /p SERVER_URL="Enter server URL (or press Enter for default): "
if "%SERVER_URL%"=="" set SERVER_URL=http://127.0.0.1:8000

echo [INFO] Server: %SERVER_URL%

REM Download and run installer
set TEMP_SCRIPT=%TEMP%\tenjo_easy_install.bat
echo [INFO] Downloading installer...

powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/easy_install_windows.bat' -OutFile '%TEMP_SCRIPT%' } catch { exit 1 }"

if exist "%TEMP_SCRIPT%" (
    echo %SERVER_URL%| "%TEMP_SCRIPT%"
    del "%TEMP_SCRIPT%"
) else (
    echo [ERROR] Failed to download installer!
    pause & exit /b 1
)

pause
