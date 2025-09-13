#!/bin/bash

# Tenjo Stealth Uninstaller for macOS
# This script completely removes the monitoring client

set -e

# Configuration
APP_NAME="SystemUpdate"
INSTALL_DIR="$HOME/.system_update"
SERVICE_NAME="com.system.update.agent"
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Silent mode flag
SILENT=${1:-"false"}

log() {
    if [[ "$SILENT" != "true" ]]; then
        echo -e "$1"
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    INSTALL_DIR="/Library/Application Support/SystemUpdate"
    PLIST_FILE="/Library/LaunchDaemons/$SERVICE_NAME.plist"
fi

log "${BLUE}🗑️ Uninstalling System Update Service...${NC}"

# Stop and unload the service
log "${BLUE}⏹️ Stopping service...${NC}"
launchctl stop "$SERVICE_NAME" 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true

# Remove plist file
if [[ -f "$PLIST_FILE" ]]; then
    rm -f "$PLIST_FILE"
    log "${GREEN}✅ Removed service configuration${NC}"
fi

# Remove installation directory
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
    log "${GREEN}✅ Removed application files${NC}"
fi

# Clean up any remaining processes
pkill -f "stealth_main.py" 2>/dev/null || true
pkill -f "python.*main.py" 2>/dev/null || true

log "${GREEN}✅ System Update Service uninstalled successfully${NC}"

if [[ "$SILENT" != "true" ]]; then
    echo ""
    echo "The monitoring service has been completely removed."
    echo "All files and background processes have been cleaned up."
fi
