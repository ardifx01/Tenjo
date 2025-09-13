#!/bin/bash
# Tenjo Remote Stealth Uninstaller for macOS

set -e

# Configuration
INSTALL_DIR="$HOME/.tenjo"
SERVICE_NAME="com.tenjo.monitor"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

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
}

log "Starting Tenjo stealth uninstallation..."

# Stop and remove launch agent
if [ -f "$PLIST_FILE" ]; then
    log "Stopping and removing launch agent..."
    launchctl stop "$SERVICE_NAME" 2>/dev/null || true
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    log "Launch agent removed"
fi

# Kill running client processes
log "Stopping running client processes..."
pkill -f "python.*main.py" 2>/dev/null || true
pkill -f "tenjo" 2>/dev/null || true

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    log "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    log "Installation directory removed"
fi

# Clean up any remaining processes
sleep 2
pkill -f "python.*main.py" 2>/dev/null || true

log "✅ Tenjo client has been completely uninstalled!"
log "All files and services have been removed."
