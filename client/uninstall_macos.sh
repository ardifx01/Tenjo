#!/bin/bash

# Tenjo Client - Uninstall Script for macOS
# Run this script to completely remove Tenjo monitoring client

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}===============================================${NC}"
echo -e "${RED}    Tenjo Client Uninstallation - macOS${NC}"
echo -e "${RED}===============================================${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm uninstallation
echo -e "${YELLOW}Are you sure you want to uninstall Tenjo Client? (y/N):${NC}"
read -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
print_status "Starting uninstallation process..."

# Stop and remove LaunchAgent
print_status "Removing auto-start service..."
PLIST_FILE="$HOME/Library/LaunchAgents/com.system.update.service.plist"
if [ -f "$PLIST_FILE" ]; then
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    print_status "LaunchAgent removed"
else
    print_warning "LaunchAgent not found"
fi

# Remove installation directory
print_status "Removing installation files..."
INSTALL_DIR="$HOME/.system_update"
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    print_status "Installation directory removed: $INSTALL_DIR"
else
    print_warning "Installation directory not found: $INSTALL_DIR"
fi

# Remove alternative installation directories
ALT_DIRS=(
    "$HOME/.system_cache"
    "$HOME/Library/Application Support/SystemUpdate"
    "/usr/local/tenjo"
)

for dir in "${ALT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        print_status "Removed: $dir"
    fi
done

# Kill any running processes
print_status "Stopping any running Tenjo processes..."
pkill -f "tenjo" 2>/dev/null || true
pkill -f "system.update" 2>/dev/null || true
pkill -f "System Update Service" 2>/dev/null || true

# Remove from crontab if exists
print_status "Checking crontab entries..."
if crontab -l 2>/dev/null | grep -q "tenjo\|system.update"; then
    print_status "Removing crontab entries..."
    crontab -l 2>/dev/null | grep -v "tenjo\|system.update" | crontab -
fi

# Clean up Python packages (optional)
echo ""
echo -e "${YELLOW}Do you want to remove Python packages installed for Tenjo? (y/N):${NC}"
read -r CLEAN_PACKAGES
if [[ "$CLEAN_PACKAGES" =~ ^[Yy]$ ]]; then
    print_status "Removing Python packages..."
    python3 -m pip uninstall -y mss psutil pyobjc-framework-Quartz pyobjc-framework-AppKit 2>/dev/null || true
    print_status "Python packages removed"
fi

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}    Uninstallation Completed Successfully!${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""
print_status "Tenjo Client has been completely removed from your system"
print_status "All monitoring processes have been stopped"
print_status "Auto-start services have been disabled"
echo ""
print_status "Thank you for using Tenjo Client!"
echo ""
