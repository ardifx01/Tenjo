#!/bin/bash

# Emergency Tenjo Client Install - Minimal Setup
# Use this if other installers fail due to dependency issues

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Emergency Tenjo Client Installer${NC}"
echo "=================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}[1/4]${NC} Setting up minimal Python environment..."

# Clean start
rm -rf .venv 2>/dev/null || true

# Create venv
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip --quiet

echo -e "${BLUE}[2/4]${NC} Installing core packages only..."

# Install absolutely essential packages
pip install requests psutil mss Pillow --quiet

# Try macOS packages individually
echo "  • Installing macOS integration..."
pip install pyobjc-core --quiet 2>/dev/null || echo "    Skipped pyobjc-core"
pip install pyobjc-framework-AppKit --quiet 2>/dev/null || echo "    Skipped AppKit"
pip install pyobjc-framework-Quartz --quiet 2>/dev/null || echo "    Skipped Quartz"

echo -e "${GREEN}✓${NC} Core packages installed"

echo -e "${BLUE}[3/4]${NC} Creating basic config..."

# Minimal config
cat > "src/core/config.py" << 'EOF'
# Minimal Tenjo Config
import os

# Server
SERVER_URL = "http://127.0.0.1:8001"
API_ENDPOINT = f"{SERVER_URL}/api"

# Client
CLIENT_ID = "emergency-client"
CLIENT_NAME = "MacBook-Emergency"

# Settings
SCREENSHOT_INTERVAL = 60
SCREENSHOT_ENABLED = True
BROWSER_MONITORING = False  # Disabled for emergency mode
PROCESS_MONITORING = True
STEALTH_MODE = False

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG_DIR = os.path.join(BASE_DIR, "logs")
os.makedirs(LOG_DIR, exist_ok=True)

LOG_LEVEL = "INFO"
EOF

echo -e "${GREEN}✓${NC} Basic configuration created"

echo -e "${BLUE}[4/4]${NC} Testing basic functionality..."

# Test screenshot only
python -c "
import sys
sys.path.append('src')
try:
    from modules.screen_capture import ScreenCapture
    sc = ScreenCapture()
    print('✓ Screenshot module loaded')
except Exception as e:
    print(f'! Screenshot issue: {e}')

try:
    from modules.process_monitor import ProcessMonitor
    pm = ProcessMonitor()
    print('✓ Process monitor loaded')
except Exception as e:
    print(f'! Process monitor issue: {e}')
" 2>/dev/null

echo ""
echo -e "${GREEN}Emergency installation complete!${NC}"
echo ""
echo "To start monitoring:"
echo "  cd $SCRIPT_DIR"
echo "  source .venv/bin/activate"
echo "  python main.py"
echo ""
echo -e "${YELLOW}Note: This is a minimal setup${NC}"
echo "• Browser monitoring disabled"
echo "• Some advanced features may not work"
echo "• Screenshot and process monitoring should work"
