#!/bin/bash

# Tenjo Client MacOS Installer
# This script installs the Tenjo employee monitoring client on macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLIENT_NAME="Tenjo Client"
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.client"
PYTHON_MIN_VERSION="3.7"

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run with sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_status "Please run without sudo for user installation."
        exit 1
    fi
}

# Check macOS version
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This installer is for macOS only!"
        exit 1
    fi
    
    local macos_version=$(sw_vers -productVersion | cut -d. -f1-2)
    print_status "Detected macOS version: $macos_version"
    
    if [[ $(echo "$macos_version >= 10.14" | bc -l) -eq 0 ]]; then
        print_warning "macOS 10.14 (Mojave) or later is recommended"
    fi
}

# Check if Python is installed
check_python() {
    print_status "Checking Python installation..."
    
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version | cut -d' ' -f2)
        print_status "Found Python $python_version"
        
        # Check if version is sufficient
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 7) else 1)"; then
            print_success "Python version is compatible"
            PYTHON_CMD="python3"
        else
            print_error "Python 3.7+ is required, found $python_version"
            install_python
        fi
    else
        print_warning "Python 3 not found"
        install_python
    fi
}

# Install Python using Homebrew
install_python() {
    print_status "Installing Python 3..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_status "Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add brew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install Python
    brew install python3
    PYTHON_CMD="python3"
    print_success "Python 3 installed successfully"
}

# Create installation directory
create_install_dir() {
    print_status "Creating installation directory..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Installation directory already exists"
        read -p "Do you want to overwrite existing installation? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
        else
            print_error "Installation cancelled"
            exit 1
        fi
    fi
    
    mkdir -p "$INSTALL_DIR"
    print_success "Installation directory created: $INSTALL_DIR"
}

# Copy client files
copy_client_files() {
    print_status "Copying client files..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy Python files
    cp "$script_dir/main.py" "$INSTALL_DIR/"
    cp -r "$script_dir/src" "$INSTALL_DIR/"
    cp "$script_dir/requirements.txt" "$INSTALL_DIR/"
    
    # Create config file
    cat > "$INSTALL_DIR/config.py" << EOF
# Tenjo Client Configuration
SERVER_URL = "http://127.0.0.1:8001"
CLIENT_ID = "$(uname -n)-$(date +%s)"
API_KEY = "your-api-key-here"
SCREENSHOT_INTERVAL = 60  # seconds
MONITORING_ENABLED = True
STEALTH_MODE = True
EOF
    
    print_success "Client files copied successfully"
}

# Install Python dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    
    cd "$INSTALL_DIR"
    
    # Create virtual environment
    $PYTHON_CMD -m venv venv
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    pip install -r requirements.txt
    
    print_success "Dependencies installed successfully"
}

# Create launch daemon
create_launch_daemon() {
    print_status "Creating launch daemon..."
    
    local plist_file="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/venv/bin/python</string>
        <string>$INSTALL_DIR/main.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>$INSTALL_DIR/error.log</string>
    <key>StandardOutPath</key>
    <string>$INSTALL_DIR/output.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF
    
    print_success "Launch daemon created: $plist_file"
}

# Request permissions
request_permissions() {
    print_status "Requesting necessary permissions..."
    
    print_warning "Tenjo Client needs the following permissions:"
    echo "  • Screen Recording (for screenshots)"
    echo "  • Accessibility (for window tracking)"
    echo "  • Full Disk Access (for comprehensive monitoring)"
    echo ""
    print_status "Please grant these permissions in System Preferences > Security & Privacy"
    
    # Open System Preferences
    read -p "Open System Preferences now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        open "x-apple.systempreferences:com.apple.preference.security?Privacy"
        print_status "Add Terminal (or your terminal app) to:"
        echo "  • Privacy > Screen Recording"
        echo "  • Privacy > Accessibility"
        echo "  • Privacy > Full Disk Access"
    fi
}

# Start service
start_service() {
    print_status "Starting Tenjo Client service..."
    
    # Load the launch agent
    launchctl load "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
    
    # Start the service
    launchctl start "$SERVICE_NAME"
    
    sleep 2
    
    # Check if service is running
    if launchctl list | grep -q "$SERVICE_NAME"; then
        print_success "Tenjo Client service started successfully"
    else
        print_warning "Service may not have started properly"
        print_status "Check logs at: $INSTALL_DIR/error.log"
    fi
}

# Create uninstall script
create_uninstaller() {
    print_status "Creating uninstaller..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

SERVICE_NAME="com.tenjo.client"
INSTALL_DIR="$HOME/.tenjo"

echo "Uninstalling Tenjo Client..."

# Stop and remove service
launchctl stop "$SERVICE_NAME" 2>/dev/null || true
launchctl unload "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

# Remove installation directory
rm -rf "$INSTALL_DIR"

echo "Tenjo Client uninstalled successfully"
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    print_success "Uninstaller created: $INSTALL_DIR/uninstall.sh"
}

# Show installation summary
show_summary() {
    echo ""
    print_success "=== Tenjo Client Installation Complete ==="
    echo ""
    echo "Installation Details:"
    echo "  • Install Directory: $INSTALL_DIR"
    echo "  • Service Name: $SERVICE_NAME"
    echo "  • Configuration: $INSTALL_DIR/config.py"
    echo "  • Logs: $INSTALL_DIR/output.log, $INSTALL_DIR/error.log"
    echo ""
    echo "Management Commands:"
    echo "  • Start:     launchctl start $SERVICE_NAME"
    echo "  • Stop:      launchctl stop $SERVICE_NAME"
    echo "  • Status:    launchctl list | grep $SERVICE_NAME"
    echo "  • Uninstall: $INSTALL_DIR/uninstall.sh"
    echo ""
    print_status "Next Steps:"
    echo "1. Configure server URL in: $INSTALL_DIR/config.py"
    echo "2. Grant required permissions in System Preferences"
    echo "3. Service will start automatically on system boot"
    echo ""
}

# Main installation function
main() {
    echo ""
    echo "================================"
    echo "  Tenjo Client MacOS Installer  "
    echo "================================"
    echo ""
    
    check_sudo
    check_macos
    check_python
    
    echo ""
    print_status "Starting installation..."
    echo ""
    
    create_install_dir
    copy_client_files
    install_dependencies
    create_launch_daemon
    create_uninstaller
    
    request_permissions
    
    echo ""
    read -p "Start Tenjo Client service now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        start_service
    fi
    
    show_summary
}

# Run main function
main "$@"
