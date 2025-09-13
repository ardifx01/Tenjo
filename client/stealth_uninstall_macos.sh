#!/bin/bash
# Tenjo Stealth Uninstaller for macOS
# This script completely removes the Tenjo monitoring client

set -e

# Configuration
SERVICE_NAME="com.tenjo.monitor"
INSTALL_DIR="$HOME/.tenjo"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Function to stop and unload launch agent
stop_service() {
    log "Stopping Tenjo monitoring service..."
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl stop "$SERVICE_NAME" 2>/dev/null || warn "Service was not running"
        launchctl unload "$PLIST_FILE" 2>/dev/null || warn "Failed to unload launch agent"
        log "Service stopped and unloaded"
    else
        warn "Service was not loaded"
    fi
}

# Function to remove files
remove_files() {
    log "Removing installation files..."
    
    # Remove launch agent file
    if [ -f "$PLIST_FILE" ]; then
        rm -f "$PLIST_FILE"
        log "Launch agent file removed"
    fi
    
    # Remove installation directory
    if [ -d "$INSTALL_DIR" ]; then
        # Unhide directory first
        chflags nohidden "$INSTALL_DIR" 2>/dev/null || true
        rm -rf "$INSTALL_DIR"
        log "Installation directory removed"
    fi
}

# Function to kill any running processes
kill_processes() {
    log "Terminating any running Tenjo processes..."
    
    # Find and kill Python processes running Tenjo
    pkill -f "tenjo" 2>/dev/null || true
    pkill -f "TenjoClient" 2>/dev/null || true
    
    # Wait a moment for processes to terminate
    sleep 2
    
    # Force kill if still running
    pkill -9 -f "tenjo" 2>/dev/null || true
    pkill -9 -f "TenjoClient" 2>/dev/null || true
}

# Main uninstallation process
main() {
    log "Starting Tenjo monitoring client uninstallation..."
    
    stop_service
    kill_processes
    remove_files
    
    log "✅ Tenjo monitoring client has been completely removed!"
    log "🧹 All traces of the application have been cleaned up"
    
    echo ""
    log "Uninstallation completed successfully."
}

# Confirm uninstallation
echo -e "${YELLOW}This will completely remove the Tenjo monitoring client from your system.${NC}"
echo -e "${YELLOW}Are you sure you want to continue? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    main "$@"
else
    echo "Uninstallation cancelled."
    exit 0
fi
