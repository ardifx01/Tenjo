#!/bin/bash

# Tenjo Client MacBook Personal Install
# Tailored for your current MacBook setup

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                     TENJO CLIENT INSTALLER                  ║
║                   MacBook Personal Edition                  ║
║                                                              ║
║  This will install Tenjo monitoring client on your MacBook  ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get system info
HOSTNAME=$(hostname)
USERNAME=$(whoami)
MACOS_VERSION=$(sw_vers -productVersion)
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}[SYSTEM INFO]${NC}"
echo "  • Hostname: $HOSTNAME"
echo "  • Username: $USERNAME"
echo "  • macOS: $MACOS_VERSION"
echo "  • Client Source: $CURRENT_DIR"
echo ""

# Confirm installation
echo -e "${YELLOW}[CONFIRMATION]${NC} This will:"
echo "  ✓ Install Python dependencies"
echo "  ✓ Configure monitoring client"
echo "  ✓ Set up auto-start service"
echo "  ✓ Request screen recording permissions"
echo "  ✓ Connect to dashboard at http://127.0.0.1:8001"
echo ""

read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}[STEP 1/6]${NC} Checking Python..."

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION found"
    PYTHON_CMD="python3"
else
    echo -e "${RED}✗${NC} Python 3 not found"
    echo "Installing Python via Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew install python3
    PYTHON_CMD="python3"
fi

echo ""
echo -e "${BLUE}[STEP 2/6]${NC} Setting up virtual environment..."

cd "$CURRENT_DIR"

if [ -d ".venv" ]; then
    echo -e "${YELLOW}!${NC} Virtual environment exists, recreating..."
    rm -rf .venv
fi

$PYTHON_CMD -m venv .venv
source .venv/bin/activate
pip install --upgrade pip --quiet

# Install dependencies with fallback strategy
echo "  • Installing Python packages..."
if pip install -r requirements.txt --quiet 2>/dev/null; then
    echo -e "${GREEN}✓${NC} All dependencies installed"
elif pip install -r requirements-minimal.txt --quiet 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Minimal dependencies installed"
else
    echo "  • Trying individual package installation..."
    # Core packages first
    pip install requests psutil mss Pillow schedule python-dateutil --quiet
    
    # macOS packages with error handling
    if pip install pyobjc-core --quiet 2>/dev/null; then
        pip install pyobjc-framework-AppKit pyobjc-framework-Quartz --quiet 2>/dev/null || echo "    Warning: Some macOS packages skipped"
    fi
    
    echo -e "${GREEN}✓${NC} Core dependencies installed"
fi

echo ""
echo -e "${BLUE}[STEP 3/6]${NC} Configuring client..."

# Create personalized config
cat > "src/core/config.py" << EOF
# Tenjo Client Configuration for $HOSTNAME
import os
from datetime import datetime

# Server Configuration
SERVER_URL = "http://127.0.0.1:8001"
API_ENDPOINT = f"{SERVER_URL}/api"

# Client Identification
CLIENT_ID = "${HOSTNAME}-$(date +%s)"
CLIENT_NAME = "$HOSTNAME"
CLIENT_USER = "$USERNAME"

# Monitoring Settings
SCREENSHOT_INTERVAL = 60  # seconds
BROWSER_CHECK_INTERVAL = 30  # seconds
PROCESS_CHECK_INTERVAL = 45  # seconds

# Features
SCREENSHOT_ENABLED = True
BROWSER_MONITORING = True
PROCESS_MONITORING = True
STEALTH_MODE = True

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG_DIR = os.path.join(BASE_DIR, "logs")
DATA_DIR = os.path.join(BASE_DIR, "data")

# Logging
LOG_LEVEL = "INFO"
LOG_FILE = os.path.join(LOG_DIR, f"tenjo_client_{datetime.now().strftime('%Y%m%d')}.log")

# Create directories
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)
EOF

echo -e "${GREEN}✓${NC} Configuration created for $HOSTNAME"

echo ""
echo -e "${BLUE}[STEP 4/6]${NC} Creating service..."

# Create launch agent directory
mkdir -p "$HOME/Library/LaunchAgents"

# Create launch agent plist
PLIST_FILE="$HOME/Library/LaunchAgents/com.tenjo.client.plist"
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tenjo.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>$CURRENT_DIR/.venv/bin/python</string>
        <string>$CURRENT_DIR/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$CURRENT_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$CURRENT_DIR/logs/error.log</string>
    <key>StandardOutPath</key>
    <string>$CURRENT_DIR/logs/output.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
    </dict>
</dict>
</plist>
EOF

echo -e "${GREEN}✓${NC} Launch agent created"

echo ""
echo -e "${BLUE}[STEP 5/6]${NC} Testing client functionality..."

# Test basic functionality
cd "$CURRENT_DIR"
source .venv/bin/activate

echo "  • Testing imports..."
if python -c "
import sys
sys.path.append('src')
try:
    from modules.screen_capture import ScreenCapture
    from modules.browser_monitor import BrowserMonitor  
    from modules.process_monitor import ProcessMonitor
    from utils.api_client import APIClient
    print('✓ All imports successful')
except ImportError as e:
    print(f'✗ Import error: {e}')
    exit(1)
" 2>/dev/null; then
    echo -e "    ${GREEN}✓${NC} All modules loaded successfully"
else
    echo -e "    ${RED}✗${NC} Module loading failed"
    exit 1
fi

echo "  • Testing screenshot capability..."
python -c "
import sys
sys.path.append('src')
from modules.screen_capture import ScreenCapture
try:
    sc = ScreenCapture()
    result = sc.capture_screenshot()
    if result:
        print('✓ Screenshot capability working')
    else:
        print('! Screenshot needs permission')
except Exception as e:
    print(f'! Screenshot issue: {e}')
" 2>/dev/null

echo ""
echo -e "${BLUE}[STEP 6/6]${NC} Requesting permissions..."

echo -e "${YELLOW}[IMPORTANT]${NC} Tenjo needs these macOS permissions:"
echo "  • Screen Recording (for screenshots)"
echo "  • Accessibility (for window monitoring)"
echo ""

read -p "Open System Preferences to grant permissions? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Opening System Preferences..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    echo ""
    echo -e "${BLUE}[INSTRUCTIONS]${NC}"
    echo "1. In System Preferences > Security & Privacy > Privacy"
    echo "2. Click 'Screen Recording' on the left"
    echo "3. Click the lock to make changes"
    echo "4. Add Terminal (or your terminal app)"
    echo "5. Also add to 'Accessibility' if available"
    echo ""
    read -p "Press ENTER when permissions are granted..."
fi

echo ""
echo -e "${BLUE}[FINAL STEP]${NC} Starting Tenjo Client..."

# Create management scripts
cat > "$CURRENT_DIR/start_service.sh" << 'EOF'
#!/bin/bash
launchctl load ~/Library/LaunchAgents/com.tenjo.client.plist
launchctl start com.tenjo.client
echo "Tenjo Client service started"
EOF

cat > "$CURRENT_DIR/stop_service.sh" << 'EOF'
#!/bin/bash
launchctl stop com.tenjo.client
launchctl unload ~/Library/LaunchAgents/com.tenjo.client.plist
echo "Tenjo Client service stopped"
EOF

cat > "$CURRENT_DIR/status.sh" << 'EOF'
#!/bin/bash
if launchctl list | grep -q com.tenjo.client; then
    echo "✓ Tenjo Client is running"
    echo "Logs: $(dirname "$0")/logs/"
else
    echo "✗ Tenjo Client is not running"
fi
EOF

chmod +x "$CURRENT_DIR"/*.sh

# Load and start the service
launchctl load "$PLIST_FILE" 2>/dev/null || true
sleep 1
launchctl start com.tenjo.client 2>/dev/null || true

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   INSTALLATION COMPLETE!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}CLIENT DETAILS:${NC}"
echo "  • Hostname: $HOSTNAME"
echo "  • User: $USERNAME"
echo "  • Install Path: $CURRENT_DIR"
echo "  • Config: $CURRENT_DIR/src/core/config.py"
echo "  • Logs: $CURRENT_DIR/logs/"
echo ""
echo -e "${BLUE}MANAGEMENT COMMANDS:${NC}"
echo "  • Start:  ./start_service.sh"
echo "  • Stop:   ./stop_service.sh"
echo "  • Status: ./status.sh"
echo "  • Manual: python main.py"
echo ""
echo -e "${BLUE}DASHBOARD:${NC}"
echo "  • URL: http://127.0.0.1:8001"
echo "  • Client will appear in dashboard within 30 seconds"
echo ""

# Check if service started
sleep 2
if launchctl list | grep -q com.tenjo.client; then
    echo -e "${GREEN}✓ Tenjo Client is now running and monitoring!${NC}"
else
    echo -e "${YELLOW}! Service may need manual start: ./start_service.sh${NC}"
fi

echo ""
echo -e "${YELLOW}[NEXT STEPS]${NC}"
echo "1. Check dashboard: http://127.0.0.1:8001"
echo "2. Your MacBook should appear as a connected client"
echo "3. Screenshots will be taken every 60 seconds"
echo "4. Browser activity will be monitored"
echo ""
