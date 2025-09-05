#!/bin/bash

# Tenjo Client Service Manager
# Easy management of Tenjo monitoring service

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE_NAME="com.tenjo.client.persistent"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_status() {
    echo -e "${BLUE}Tenjo Client Service Status${NC}"
    echo "=========================="
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "Status: ${GREEN}✓ RUNNING${NC}"
        
        # Get process info
        local pid=$(launchctl list | grep "$SERVICE_NAME" | awk '{print $1}')
        if [[ "$pid" != "-" ]]; then
            echo "PID: $pid"
            
            # Get memory usage
            local memory=$(ps -p "$pid" -o rss= 2>/dev/null | awk '{print $1/1024}' | cut -d. -f1)
            if [[ -n "$memory" ]]; then
                echo "Memory: ${memory}MB"
            fi
        fi
        
        # Check recent activity
        if [[ -f "$SCRIPT_DIR/logs/service.log" ]]; then
            echo ""
            echo "Recent Activity:"
            tail -3 "$SCRIPT_DIR/logs/service.log" 2>/dev/null | sed 's/^/  /'
        fi
        
    else
        echo -e "Status: ${RED}✗ NOT RUNNING${NC}"
    fi
    
    echo ""
    echo "Auto-start: $(launchctl list | grep -q "$SERVICE_NAME" && echo -e "${GREEN}Enabled${NC}" || echo -e "${RED}Disabled${NC}")"
    echo "Config: $HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
    echo "Logs: $SCRIPT_DIR/logs/"
}

start_service() {
    echo -e "${BLUE}Starting Tenjo Client Service...${NC}"
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "${YELLOW}Service already running${NC}"
        return 0
    fi
    
    # Load and start
    launchctl load "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist" 2>/dev/null || true
    launchctl start "$SERVICE_NAME"
    
    sleep 2
    
    if launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ Service started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start service${NC}"
        echo "Check logs: $SCRIPT_DIR/logs/service_error.log"
        return 1
    fi
}

stop_service() {
    echo -e "${BLUE}Stopping Tenjo Client Service...${NC}"
    
    if ! launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "${YELLOW}Service not running${NC}"
        return 0
    fi
    
    launchctl stop "$SERVICE_NAME"
    launchctl unload "$HOME/Library/LaunchAgents/$SERVICE_NAME.plist" 2>/dev/null || true
    
    sleep 1
    
    if ! launchctl list | grep -q "$SERVICE_NAME"; then
        echo -e "${GREEN}✓ Service stopped successfully${NC}"
    else
        echo -e "${RED}✗ Failed to stop service${NC}"
        return 1
    fi
}

restart_service() {
    echo -e "${BLUE}Restarting Tenjo Client Service...${NC}"
    stop_service
    sleep 1
    start_service
}

show_logs() {
    local log_type="${1:-service}"
    local log_file=""
    
    case "$log_type" in
        "service"|"output")
            log_file="$SCRIPT_DIR/logs/service.log"
            ;;
        "error")
            log_file="$SCRIPT_DIR/logs/service_error.log"
            ;;
        "startup")
            log_file="$SCRIPT_DIR/logs/startup.log"
            ;;
        *)
            echo "Available logs: service, error, startup"
            return 1
            ;;
    esac
    
    if [[ -f "$log_file" ]]; then
        echo -e "${BLUE}Showing $log_type log (Press Ctrl+C to exit):${NC}"
        echo "============================================="
        tail -f "$log_file"
    else
        echo -e "${YELLOW}Log file not found: $log_file${NC}"
        echo "Available log files:"
        ls -la "$SCRIPT_DIR/logs/" 2>/dev/null || echo "No logs directory found"
    fi
}

show_help() {
    echo "Tenjo Client Service Manager"
    echo "============================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status          Show service status and info"
    echo "  start           Start the monitoring service"
    echo "  stop            Stop the monitoring service"  
    echo "  restart         Restart the monitoring service"
    echo "  logs [TYPE]     Show logs (service/error/startup)"
    echo "  test            Test client functionality"
    echo "  setup           Setup persistent auto-start service"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs error"
    echo "  $0 restart"
}

test_client() {
    echo -e "${BLUE}Testing Tenjo Client Functionality...${NC}"
    echo "===================================="
    
    cd "$SCRIPT_DIR"
    
    if [[ ! -d ".venv" ]]; then
        echo -e "${RED}✗ Virtual environment not found${NC}"
        return 1
    fi
    
    source .venv/bin/activate
    
    echo "Testing modules..."
    python -c "
import sys
sys.path.append('src')

try:
    from modules.screen_capture import ScreenCapture
    print('✓ ScreenCapture module OK')
except Exception as e:
    print(f'✗ ScreenCapture error: {e}')

try:
    from modules.process_monitor import ProcessMonitor
    print('✓ ProcessMonitor module OK')
except Exception as e:
    print(f'✗ ProcessMonitor error: {e}')

try:
    from modules.browser_monitor import BrowserMonitor
    print('✓ BrowserMonitor module OK')
except Exception as e:
    print(f'✗ BrowserMonitor error: {e}')

try:
    from utils.api_client import APIClient
    print('✓ APIClient module OK')
except Exception as e:
    print(f'✗ APIClient error: {e}')
"
    
    echo ""
    echo "Testing screenshot capability..."
    python -c "
import sys
sys.path.append('src')
from modules.screen_capture import ScreenCapture

try:
    sc = ScreenCapture()
    screenshot = sc.capture_screenshot()
    if screenshot:
        print(f'✓ Screenshot captured ({len(screenshot)} bytes)')
    else:
        print('✗ Screenshot failed')
except Exception as e:
    print(f'✗ Screenshot error: {e}')
"
    
    echo -e "${GREEN}Test complete${NC}"
}

setup_persistent() {
    if [[ -f "$SCRIPT_DIR/setup_persistent_service.sh" ]]; then
        echo -e "${BLUE}Setting up persistent service...${NC}"
        "$SCRIPT_DIR/setup_persistent_service.sh"
    else
        echo -e "${RED}Setup script not found${NC}"
        return 1
    fi
}

# Main command handling
case "${1:-status}" in
    "status")
        show_status
        ;;
    "start")
        start_service
        ;;
    "stop")
        stop_service
        ;;
    "restart")
        restart_service
        ;;
    "logs")
        show_logs "$2"
        ;;
    "test")
        test_client
        ;;
    "setup")
        setup_persistent
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
