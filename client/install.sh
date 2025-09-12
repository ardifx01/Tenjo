#!/bin/bash

# Tenjo Client - One-Line Installer for macOS
# Run: curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/install.sh | bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Tenjo Client - One-Line Installer${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Get server URL
echo -e "${YELLOW}Enter dashboard server URL (or press Enter for default):${NC}"
read -r SERVER_URL
if [ -z "$SERVER_URL" ]; then
    SERVER_URL="http://103.129.149.67"
fi

print_status "Server: $SERVER_URL"

# Download and run installer
TEMP_SCRIPT="/tmp/tenjo_easy_install.sh"
print_status "Downloading installer..."

if curl -f -s -L "https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/easy_install_macos.sh" -o "$TEMP_SCRIPT"; then
    chmod +x "$TEMP_SCRIPT"
    echo "$SERVER_URL" | "$TEMP_SCRIPT"
    rm -f "$TEMP_SCRIPT"
else
    print_error "Failed to download installer!"
    exit 1
fi
