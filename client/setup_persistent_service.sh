#!/bin/bash

# Tenjo Client Persistent Service Installer
# Creates a macOS Launch Daemon for automatic startup and keep-alive

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="com.tenjo.client.persistent"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

echo -e "${BLUE}Creating Persistent Tenjo Client Service${NC}"
echo "========================================"
echo ""

# Stop existing service if running
echo -e "${BLUE}[1/4]${NC} Stopping existing service..."
launchctl stop com.tenjo.client 2>/dev/null || true
launchctl unload "$HOME/Library/LaunchAgents/com.tenjo.client.plist" 2>/dev/null || true

# Create enhanced plist with better persistence
echo -e "${BLUE}[2/4]${NC} Creating persistent launch agent..."

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/.venv/bin/python</string>
        <string>$SCRIPT_DIR/main.py</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    
    <!-- Auto-start at login -->
    <key>RunAtLoad</key>
    <true/>
    
    <!-- Keep alive - restart if crashes -->
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    
    <!-- Restart with exponential backoff -->
    <key>ThrottleInterval</key>
    <integer>30</integer>
    
    <!-- Environment variables -->
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>PYTHONPATH</key>
        <string>$SCRIPT_DIR/src</string>
        <key>HOME</key>
        <string>$HOME</string>
    </dict>
    
    <!-- Logging -->
    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/logs/service.log</string>
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/logs/service_error.log</string>
    
    <!-- Process limits -->
    <key>SoftResourceLimits</key>
    <dict>
        <key>NumberOfFiles</key>
        <integer>1024</integer>
    </dict>
    
    <!-- Nice value (lower priority) -->
    <key>Nice</key>
    <integer>5</integer>
    
    <!-- Run only when user is logged in -->
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

echo -e "${GREEN}✓${NC} Persistent launch agent created"

# Create startup script that handles dependencies
echo -e "${BLUE}[3/4]${NC} Creating startup wrapper..."

cat > "$SCRIPT_DIR/tenjo_startup.py" << 'EOF'
#!/usr/bin/env python3
"""
Tenjo Client Startup Wrapper
Handles dependencies and ensures robust startup
"""

import sys
import os
import time
import subprocess
import logging
from pathlib import Path

# Setup paths
SCRIPT_DIR = Path(__file__).parent
VENV_PYTHON = SCRIPT_DIR / '.venv' / 'bin' / 'python'
MAIN_SCRIPT = SCRIPT_DIR / 'main.py'
LOG_DIR = SCRIPT_DIR / 'logs'

# Ensure log directory exists
LOG_DIR.mkdir(exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / 'startup.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def wait_for_network():
    """Wait for network connectivity"""
    max_attempts = 30
    for attempt in range(max_attempts):
        try:
            import socket
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            logger.info("Network connectivity confirmed")
            return True
        except (socket.error, OSError):
            if attempt < max_attempts - 1:
                logger.info(f"Waiting for network... ({attempt + 1}/{max_attempts})")
                time.sleep(10)
            else:
                logger.warning("Network not available after waiting")
                return False
    return False

def check_dependencies():
    """Check if virtual environment and dependencies are available"""
    if not VENV_PYTHON.exists():
        logger.error(f"Virtual environment not found: {VENV_PYTHON}")
        return False
    
    if not MAIN_SCRIPT.exists():
        logger.error(f"Main script not found: {MAIN_SCRIPT}")
        return False
    
    # Test import of critical modules
    try:
        result = subprocess.run([
            str(VENV_PYTHON), '-c', 
            'import sys; sys.path.append("src"); from modules.screen_capture import ScreenCapture; print("OK")'
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            logger.info("Dependencies check passed")
            return True
        else:
            logger.error(f"Dependencies check failed: {result.stderr}")
            return False
    except Exception as e:
        logger.error(f"Error checking dependencies: {e}")
        return False

def main():
    logger.info("Tenjo Client starting up...")
    
    # Wait a bit for system to stabilize
    time.sleep(5)
    
    # Wait for network
    if not wait_for_network():
        logger.warning("Starting without network confirmation")
    
    # Check dependencies
    if not check_dependencies():
        logger.error("Dependency check failed, exiting")
        sys.exit(1)
    
    # Start main client
    logger.info("Starting Tenjo Client main process...")
    try:
        # Change to script directory
        os.chdir(SCRIPT_DIR)
        
        # Execute main script
        result = subprocess.run([str(VENV_PYTHON), str(MAIN_SCRIPT)], 
                              env=dict(os.environ, PYTHONPATH=str(SCRIPT_DIR / 'src')))
        
        logger.info(f"Main process exited with code: {result.returncode}")
        sys.exit(result.returncode)
        
    except Exception as e:
        logger.error(f"Error starting main process: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

chmod +x "$SCRIPT_DIR/tenjo_startup.py"

# Update plist to use startup wrapper
sed -i '' "s|<string>$SCRIPT_DIR/main.py</string>|<string>$SCRIPT_DIR/tenjo_startup.py</string>|g" "$PLIST_FILE"

echo -e "${GREEN}✓${NC} Startup wrapper created"

# Load and start the service
echo -e "${BLUE}[4/4]${NC} Loading persistent service..."

# Load the launch agent
launchctl load "$PLIST_FILE"

# Start the service
launchctl start "$SERVICE_NAME"

sleep 3

# Check if service is running
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo -e "${GREEN}✓${NC} Persistent service started successfully"
else
    echo -e "${YELLOW}!${NC} Service may need manual start"
fi

echo ""
echo -e "${GREEN}Persistent Service Configuration Complete!${NC}"
echo ""
echo "Service Details:"
echo "  • Name: $SERVICE_NAME"
echo "  • Auto-start: ✓ On user login"
echo "  • Keep-alive: ✓ Restart if crashes"
echo "  • Logs: $SCRIPT_DIR/logs/"
echo ""
echo "Management Commands:"
echo "  • Start:  launchctl start $SERVICE_NAME"
echo "  • Stop:   launchctl stop $SERVICE_NAME"
echo "  • Status: launchctl list | grep tenjo"
echo "  • Logs:   tail -f $SCRIPT_DIR/logs/service.log"
echo ""
echo -e "${BLUE}The service will now:${NC}"
echo "  ✓ Start automatically when you log in"
echo "  ✓ Restart automatically if it crashes"
echo "  ✓ Run continuously until you shut down"
echo "  ✓ Resume monitoring when you start up again"
