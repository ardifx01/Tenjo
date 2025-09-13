#!/bin/bash

# Tenjo Stealth Uninstaller for macOS
# This script completely removes Tenjo monitoring system from the target machine
# Usage: curl -s https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_uninstall_stealth_macos.sh | bash

echo "🗑️  Starting Tenjo stealth uninstall process..."

# Define paths
INSTALL_DIR="$HOME/.config/system-utils"
LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/com.apple.systemupdater.plist"
LOG_DIR="$HOME/Library/Logs/SystemUpdater"

# Function to run commands silently
run_silent() {
    "$@" >/dev/null 2>&1
}

# Function to check if process is running and kill it
stop_tenjo_process() {
    echo "🔄 Stopping Tenjo processes..."
    
    # Kill any running Tenjo processes
    run_silent pkill -f "stealth_main.py"
    run_silent pkill -f "tenjo"
    run_silent pkill -f "system-utils"
    
    # Wait a moment for processes to terminate
    sleep 2
    
    # Force kill if still running
    run_silent pkill -9 -f "stealth_main.py"
    run_silent pkill -9 -f "tenjo"
    run_silent pkill -9 -f "system-utils"
}

# Function to unload and remove LaunchAgent
remove_launch_agent() {
    echo "🚫 Removing auto-start configuration..."
    
    if [ -f "$LAUNCH_AGENT_FILE" ]; then
        # Unload the launch agent
        run_silent launchctl unload "$LAUNCH_AGENT_FILE"
        
        # Remove the plist file
        run_silent rm -f "$LAUNCH_AGENT_FILE"
        
        echo "✅ Auto-start configuration removed"
    else
        echo "ℹ️  No auto-start configuration found"
    fi
}

# Function to remove installation directory
remove_files() {
    echo "📁 Removing installation files..."
    
    if [ -d "$INSTALL_DIR" ]; then
        run_silent rm -rf "$INSTALL_DIR"
        echo "✅ Installation directory removed"
    else
        echo "ℹ️  Installation directory not found"
    fi
    
    # Remove log directory
    if [ -d "$LOG_DIR" ]; then
        run_silent rm -rf "$LOG_DIR"
        echo "✅ Log directory removed"
    fi
}

# Function to clean up any remaining traces
cleanup_traces() {
    echo "🧹 Cleaning up remaining traces..."
    
    # Remove any cached Python files that might exist
    run_silent find "$HOME" -name "*tenjo*" -type f -delete 2>/dev/null
    run_silent find "$HOME" -name "*system-utils*" -type f -delete 2>/dev/null
    
    # Clear any temporary files
    run_silent rm -rf /tmp/tenjo* 2>/dev/null
    run_silent rm -rf /tmp/system-utils* 2>/dev/null
    
    echo "✅ Traces cleaned"
}

# Function to verify uninstallation
verify_uninstall() {
    echo "🔍 Verifying uninstallation..."
    
    local issues=0
    
    # Check if LaunchAgent exists
    if [ -f "$LAUNCH_AGENT_FILE" ]; then
        echo "⚠️  LaunchAgent still exists: $LAUNCH_AGENT_FILE"
        issues=$((issues + 1))
    fi
    
    # Check if installation directory exists
    if [ -d "$INSTALL_DIR" ]; then
        echo "⚠️  Installation directory still exists: $INSTALL_DIR"
        issues=$((issues + 1))
    fi
    
    # Check if any Tenjo processes are running
    if pgrep -f "stealth_main.py" >/dev/null 2>&1; then
        echo "⚠️  Tenjo processes still running"
        issues=$((issues + 1))
    fi
    
    if [ $issues -eq 0 ]; then
        echo "✅ Uninstallation verified successfully"
        echo "🎉 Tenjo has been completely removed from this system"
        return 0
    else
        echo "❌ Uninstallation incomplete - $issues issues found"
        return 1
    fi
}

# Main uninstallation process
main() {
    echo "🔧 Tenjo Stealth Uninstaller v1.0"
    echo "=================================="
    
    # Stop all Tenjo processes
    stop_tenjo_process
    
    # Remove LaunchAgent
    remove_launch_agent
    
    # Remove installation files
    remove_files
    
    # Clean up traces
    cleanup_traces
    
    # Verify uninstallation
    if verify_uninstall; then
        echo ""
        echo "🎯 UNINSTALLATION COMPLETE"
        echo "=========================="
        echo "✅ All Tenjo components have been removed"
        echo "✅ Auto-start disabled"
        echo "✅ All files and logs deleted"
        echo "✅ System restored to original state"
        echo ""
        echo "💡 The system is now clean and monitoring has been stopped."
    else
        echo ""
        echo "⚠️  UNINSTALLATION ISSUES DETECTED"
        echo "==================================="
        echo "Some components may still exist. Please check manually:"
        echo "- LaunchAgent: $LAUNCH_AGENT_FILE"
        echo "- Install Dir: $INSTALL_DIR"
        echo "- Running processes: ps aux | grep tenjo"
    fi
}

# Run main function
main

# Exit with success
exit 0
