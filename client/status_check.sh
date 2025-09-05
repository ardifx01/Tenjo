#!/bin/bash

# Tenjo Client - Quick Status Check
# Usage: ./status_check.sh

echo "🔍 TENJO CLIENT STATUS CHECK"
echo "=============================="

# Service Status
echo -e "\n📊 SERVICE STATUS:"
if launchctl list | grep -q "com.tenjo.client.persistent"; then
    PID=$(launchctl list | grep "com.tenjo.client.persistent" | awk '{print $1}')
    if [[ "$PID" != "-" ]]; then
        echo "✅ Service RUNNING (PID: $PID)"
    else
        echo "⚠️  Service LOADED but not running"
    fi
else
    echo "❌ Service NOT loaded"
fi

# Process Check
echo -e "\n🖥️  PROCESS STATUS:"
if pgrep -f "main.py" > /dev/null; then
    echo "✅ Main process is running"
    pgrep -f "main.py" | while read pid; do
        echo "   PID: $pid"
    done
else
    echo "❌ Main process not found"
fi

# Files Check
echo -e "\n📁 FILES STATUS:"
CLIENT_DIR="/Users/yapi/Adi/App-Dev/Tenjo/client"
if [[ -d "$CLIENT_DIR" ]]; then
    echo "✅ Client directory exists"
    if [[ -f "$CLIENT_DIR/main.py" ]]; then
        echo "✅ Main application file exists"
    else
        echo "❌ Main application file missing"
    fi
    
    if [[ -d "$CLIENT_DIR/.venv" ]]; then
        echo "✅ Virtual environment exists"
    else
        echo "❌ Virtual environment missing"
    fi
    
    if [[ -f "$HOME/Library/LaunchAgents/com.tenjo.client.persistent.plist" ]]; then
        echo "✅ Launch agent installed"
    else
        echo "❌ Launch agent missing"
    fi
else
    echo "❌ Client directory not found"
fi

# Dashboard Check
echo -e "\n🌐 DASHBOARD STATUS:"
if curl -s http://127.0.0.1:8001 > /dev/null 2>&1; then
    echo "✅ Dashboard accessible at http://127.0.0.1:8001"
else
    echo "❌ Dashboard not accessible"
fi

# Recent Logs
echo -e "\n📋 RECENT ACTIVITY:"
LOG_FILE="$CLIENT_DIR/logs/service.log"
if [[ -f "$LOG_FILE" ]]; then
    echo "Last 3 log entries:"
    tail -n 3 "$LOG_FILE" 2>/dev/null || echo "No recent logs"
else
    echo "No log file found"
fi

# Recommendations
echo -e "\n💡 RECOMMENDATIONS:"
if ! launchctl list | grep -q "com.tenjo.client.persistent"; then
    echo "🔧 Run: cd $CLIENT_DIR && ./setup_persistent_service.sh"
elif ! pgrep -f "main.py" > /dev/null; then
    echo "🔧 Run: cd $CLIENT_DIR && ./tenjo.sh start"
else
    echo "✅ System is running normally"
fi

echo -e "\n=============================="
echo "📖 For detailed help, see: $CLIENT_DIR/PANDUAN.md"
