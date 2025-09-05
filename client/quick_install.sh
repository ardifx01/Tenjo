#!/bin/bash

# Tenjo Client Quick Install for Development/Testing
# Simple installer for macOS development environment

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "================================"
echo "  Tenjo Client Quick Installer  "
echo "       (Development Mode)       "
echo "================================"
echo -e "${NC}"

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}[INFO]${NC} Installing Tenjo Client from: $CLIENT_DIR"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Python 3 is required but not installed."
    echo "Please install Python 3 first:"
    echo "  brew install python3"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} Python 3 found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "$CLIENT_DIR/.venv" ]; then
    echo -e "${BLUE}[INFO]${NC} Creating virtual environment..."
    cd "$CLIENT_DIR"
    python3 -m venv .venv
    echo -e "${GREEN}[OK]${NC} Virtual environment created"
else
    echo -e "${GREEN}[OK]${NC} Virtual environment already exists"
fi

# Activate virtual environment and install dependencies
echo -e "${BLUE}[INFO]${NC} Installing dependencies..."
cd "$CLIENT_DIR"
source .venv/bin/activate
pip install --upgrade pip --quiet

# Try main requirements first, fallback to minimal
if pip install -r requirements.txt --quiet 2>/dev/null; then
    echo -e "${GREEN}[OK]${NC} All dependencies installed"
else
    echo -e "${YELLOW}[WARNING]${NC} Main requirements failed, trying minimal set..."
    if pip install -r requirements-minimal.txt --quiet 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC} Minimal dependencies installed"
    else
        echo -e "${RED}[ERROR]${NC} Failed to install dependencies"
        echo "Trying individual package installation..."
        
        # Install packages individually
        pip install requests psutil mss Pillow schedule python-dateutil --quiet
        
        # Try macOS packages
        if ! pip install pyobjc-core pyobjc-framework-AppKit pyobjc-framework-Quartz --quiet 2>/dev/null; then
            echo -e "${YELLOW}[WARNING]${NC} macOS integration packages failed"
            echo "Basic monitoring will work, but window tracking may be limited"
        fi
        
        echo -e "${GREEN}[OK]${NC} Core dependencies installed"
    fi
fi

# Update server URL in config
echo -e "${BLUE}[INFO]${NC} Configuring client..."
if [ -f "$CLIENT_DIR/src/core/config.py" ]; then
    # Update server URL to match our running dashboard
    sed -i '' 's|SERVER_URL = ".*"|SERVER_URL = "http://127.0.0.1:8001"|g' "$CLIENT_DIR/src/core/config.py"
    echo -e "${GREEN}[OK]${NC} Configuration updated"
fi

# Create a simple launcher script
cat > "$CLIENT_DIR/start_client.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
python main.py
EOF

chmod +x "$CLIENT_DIR/start_client.sh"

# Test imports and basic functionality
echo -e "${BLUE}[INFO]${NC} Testing client functionality..."
cd "$CLIENT_DIR"
source .venv/bin/activate

# Run import test
if python -c "
import sys
sys.path.append('src')
from modules.screen_capture import ScreenCapture
from modules.browser_monitor import BrowserMonitor
from modules.process_monitor import ProcessMonitor
from utils.api_client import APIClient
print('✓ All imports successful')
" 2>/dev/null; then
    echo -e "${GREEN}[OK]${NC} All modules imported successfully"
else
    echo -e "${RED}[ERROR]${NC} Some imports failed. Check dependencies."
    exit 1
fi

# Test screenshot capability
echo -e "${BLUE}[INFO]${NC} Testing screenshot capability..."
if python -c "
import sys
sys.path.append('src')
from modules.screen_capture import ScreenCapture
sc = ScreenCapture()
try:
    screenshot = sc.capture_screenshot()
    if screenshot:
        print('✓ Screenshot test successful')
    else:
        print('✗ Screenshot test failed')
except Exception as e:
    print(f'✗ Screenshot error: {e}')
" 2>/dev/null; then
    echo -e "${GREEN}[OK]${NC} Screenshot functionality working"
else
    echo -e "${RED}[WARNING]${NC} Screenshot may need permission grants"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}   Installation Complete!      ${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Client installed at: $CLIENT_DIR"
echo ""
echo "To start monitoring:"
echo "  1. Manual start: ./start_client.sh"
echo "  2. Or run: python main.py"
echo ""
echo "Configuration file: src/core/config.py"
echo "Dashboard URL: http://127.0.0.1:8001"
echo ""
echo -e "${BLUE}[INFO]${NC} You may need to grant permissions:"
echo "  • System Preferences > Security & Privacy > Privacy"
echo "  • Add Terminal to Screen Recording permissions"
echo "  • Add Terminal to Accessibility permissions"
echo ""

# Ask if user wants to start client now
read -p "Start client monitoring now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}[INFO]${NC} Starting client..."
    cd "$CLIENT_DIR"
    source .venv/bin/activate
    python main.py
fi
