#!/bin/bash

# Tenjo Client Complete Uninstaller
# Removes all traces of Tenjo Client from macOS

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${RED}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                   TENJO CLIENT UNINSTALLER                  ║
║                                                              ║
║     This will completely remove Tenjo Client from macOS     ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}[SYSTEM CHECK]${NC}"
echo "  • Install Directory: $CLIENT_DIR"
echo "  • User: $(whoami)"
echo "  • Hostname: $(hostname)"
echo ""

# Show what will be removed
echo -e "${YELLOW}[WARNING]${NC} This will remove:"
echo "  ✗ Tenjo Client application files"
echo "  ✗ Virtual environment and dependencies"
echo "  ✗ Launch agents (auto-start services)"
echo "  ✗ Configuration files"
echo "  ✗ Log files and data"
echo "  ✗ All monitoring data"
echo ""

# Confirmation
read -p "Are you sure you want to completely uninstall Tenjo Client? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
echo -e "${RED}[UNINSTALLING]${NC} Removing Tenjo Client..."
echo ""

# Step 1: Stop and remove services
echo -e "${BLUE}[1/6]${NC} Stopping services..."

SERVICES=(
    "com.tenjo.client"
    "com.tenjo.client.persistent"
)

for service in "${SERVICES[@]}"; do
    if launchctl list | grep -q "$service" 2>/dev/null; then
        echo "  • Stopping $service..."
        launchctl stop "$service" 2>/dev/null || true
        launchctl unload "$HOME/Library/LaunchAgents/$service.plist" 2>/dev/null || true
        echo -e "    ${GREEN}✓${NC} Stopped"
    else
        echo "  • $service not running"
    fi
done

# Step 2: Remove launch agents
echo -e "${BLUE}[2/6]${NC} Removing launch agents..."

PLIST_FILES=(
    "$HOME/Library/LaunchAgents/com.tenjo.client.plist"
    "$HOME/Library/LaunchAgents/com.tenjo.client.persistent.plist"
)

for plist in "${PLIST_FILES[@]}"; do
    if [[ -f "$plist" ]]; then
        echo "  • Removing $(basename "$plist")..."
        rm -f "$plist"
        echo -e "    ${GREEN}✓${NC} Removed"
    else
        echo "  • $(basename "$plist") not found"
    fi
done

# Step 3: Stop any running Python processes
echo -e "${BLUE}[3/6]${NC} Stopping Tenjo processes..."

TENJO_PIDS=$(ps aux | grep -i tenjo | grep -v grep | awk '{print $2}' || true)
if [[ -n "$TENJO_PIDS" ]]; then
    echo "  • Found running Tenjo processes: $TENJO_PIDS"
    for pid in $TENJO_PIDS; do
        echo "  • Killing process $pid..."
        kill -TERM "$pid" 2>/dev/null || true
        sleep 1
        kill -KILL "$pid" 2>/dev/null || true
    done
    echo -e "    ${GREEN}✓${NC} Processes stopped"
else
    echo "  • No running Tenjo processes found"
fi

# Step 4: Remove virtual environment
echo -e "${BLUE}[4/6]${NC} Removing virtual environment..."

if [[ -d "$CLIENT_DIR/.venv" ]]; then
    echo "  • Removing Python virtual environment..."
    rm -rf "$CLIENT_DIR/.venv"
    echo -e "    ${GREEN}✓${NC} Virtual environment removed"
else
    echo "  • Virtual environment not found"
fi

# Step 5: Remove application files (optional)
echo -e "${BLUE}[5/6]${NC} Removing application files..."

read -p "Remove all Tenjo application files? This cannot be undone! (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup important files first
    if [[ -d "$CLIENT_DIR/logs" ]] && [[ -n "$(ls -A "$CLIENT_DIR/logs" 2>/dev/null)" ]]; then
        echo "  • Creating backup of logs..."
        BACKUP_DIR="$HOME/Desktop/tenjo_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp -r "$CLIENT_DIR/logs" "$BACKUP_DIR/" 2>/dev/null || true
        echo -e "    ${GREEN}✓${NC} Logs backed up to: $BACKUP_DIR"
    fi
    
    # Remove files but keep the directory structure for safety
    FILES_TO_REMOVE=(
        "main.py"
        "requirements.txt"
        "requirements-minimal.txt"
        "tenjo_startup.py"
        "src/"
        "logs/"
        "data/"
        "*.sh"
        "*.log"
        "*.pyc"
        "__pycache__/"
    )
    
    for item in "${FILES_TO_REMOVE[@]}"; do
        if [[ -e "$CLIENT_DIR/$item" ]]; then
            echo "  • Removing $item..."
            rm -rf "$CLIENT_DIR/$item" 2>/dev/null || true
        fi
    done
    
    echo -e "    ${GREEN}✓${NC} Application files removed"
else
    echo "  • Application files kept"
fi

# Step 6: Clean up system
echo -e "${BLUE}[6/6]${NC} Final cleanup..."

# Reload launch services
echo "  • Reloading launch services..."
launchctl load -w /System/Library/LaunchDaemons/com.apple.launchservicesd.plist 2>/dev/null || true

# Clear any cached Python bytecode
find "$CLIENT_DIR" -name "*.pyc" -delete 2>/dev/null || true
find "$CLIENT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

echo -e "    ${GREEN}✓${NC} System cleanup complete"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  UNINSTALLATION COMPLETE                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}SUMMARY:${NC}"
echo "  ✓ Services stopped and removed"
echo "  ✓ Launch agents removed"
echo "  ✓ Processes terminated"
echo "  ✓ Virtual environment removed"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  ✓ Application files removed"
    if [[ -d "$HOME/Desktop/tenjo_backup_"* ]]; then
        echo "  ✓ Logs backed up to Desktop"
    fi
else
    echo "  • Application files kept"
fi
echo ""

echo -e "${BLUE}VERIFICATION:${NC}"
if launchctl list 2>/dev/null | grep -q tenjo; then
    echo -e "  ${YELLOW}!${NC} Some services may still be loaded"
    echo "    Run: launchctl list | grep tenjo"
else
    echo -e "  ${GREEN}✓${NC} No Tenjo services running"
fi

if pgrep -f tenjo >/dev/null 2>&1; then
    echo -e "  ${YELLOW}!${NC} Some processes may still be running"
    echo "    Run: ps aux | grep tenjo"
else
    echo -e "  ${GREEN}✓${NC} No Tenjo processes running"
fi

echo ""
echo -e "${BLUE}TO REINSTALL:${NC}"
echo "  Run: ./install_macbook.sh"
echo ""
echo -e "${GREEN}Tenjo Client has been successfully uninstalled!${NC}"
