#!/bin/bash

# Tenjo Stealth Uninstaller for macOS - Clean Version
# This script completely removes Tenjo monitoring system from the target machine
# Usage: curl -s https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/quick_uninstall_stealth_macos.sh | bash

echo "🗑️ Starting Tenjo stealth uninstall process..."

# Define paths
INSTALL_DIR="$HOME/.config/system-utils"
LAUNCH_AGENT_FILE="$HOME/Library/LaunchAgents/com.apple.systemupdater.plist"
LOG_DIR="$HOME/Library/Logs/SystemUpdater"

# Function to run commands silently with timeout
run_silent() {
    timeout 10 "$@" >/dev/null 2>&1 || true
}

# Function to show progress
show_progress() {
    echo -n "$1"
    for i in {1..3}; do
        echo -n "."
        sleep 0.5
    done
    echo " Done!"
}

# Function to check if process is running and kill it
stop_tenjo_process() {
    echo "🔄 Stopping Tenjo processes..."
    
    # Kill any running Tenjo processes with progress
    show_progress "   Terminating processes"
    run_silent pkill -f "stealth_main.py"
    run_silent pkill -f "tenjo"
    run_silent pkill -f "system-utils"
    
    # Wait a moment for processes to terminate
    sleep 1
    
    # Force kill if still running
    run_silent pkill -9 -f "stealth_main.py"
    run_silent pkill -9 -f "tenjo"
    run_silent pkill -9 -f "system-utils"
    
    echo "✅ Processes stopped"
}

# Function to unload and remove LaunchAgent
remove_launch_agent() {
    echo "📱 Removing LaunchAgent..."
    
    if [[ -f "$LAUNCH_AGENT_FILE" ]]; then
        show_progress "   Unloading service"
        run_silent launchctl unload "$LAUNCH_AGENT_FILE"
        
        show_progress "   Removing plist file"
        rm -f "$LAUNCH_AGENT_FILE"
        
        echo "✅ LaunchAgent removed"
    else
        echo "ℹ️  LaunchAgent not found (already removed)"
    fi
}

# Function to remove installation files
remove_installation() {
    echo "📁 Removing installation files..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        show_progress "   Removing application files"
        rm -rf "$INSTALL_DIR"
        echo "✅ Installation files removed"
    else
        echo "ℹ️  Installation directory not found (already removed)"
    fi
}

# Function to remove logs
remove_logs() {
    echo "📋 Removing log files..."
    
    if [[ -d "$LOG_DIR" ]]; then
        show_progress "   Cleaning log directory"
        rm -rf "$LOG_DIR"
        echo "✅ Log files removed"
    else
        echo "ℹ️  Log directory not found (already removed)"
    fi
    
    # Also remove any logs in installation directory
    run_silent rm -rf "$HOME/.config/system-utils/logs"
}

# Function to clean cache and temp files
clean_cache() {
    echo "🧹 Cleaning cache and temporary files..."
    
    show_progress "   Removing cache files"
    run_silent rm -rf "$HOME/.cache/tenjo"*
    run_silent rm -rf "/tmp/tenjo"*
    run_silent rm -rf "/tmp/system-utils"*
    
    echo "✅ Cache cleaned"
}

# Function to verify complete removal
verify_removal() {
    echo "🔍 Verifying complete removal..."
    
    local issues_found=0
    
    # Check LaunchAgent
    if [[ -f "$LAUNCH_AGENT_FILE" ]]; then
        echo "⚠️  LaunchAgent still exists: $LAUNCH_AGENT_FILE"
        ((issues_found++))
    fi
    
    # Check installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "⚠️  Installation directory still exists: $INSTALL_DIR"
        ((issues_found++))
    fi
    
    # Check running processes
    local running_processes=$(pgrep -f "tenjo\|stealth\|system-utils" 2>/dev/null | wc -l)
    if [[ $running_processes -gt 0 ]]; then
        echo "⚠️  $running_processes related processes still running"
        ((issues_found++))
    fi
    
    # Check service status
    local service_loaded=$(launchctl list | grep systemupdater 2>/dev/null | wc -l)
    if [[ $service_loaded -gt 0 ]]; then
        echo "⚠️  Service still loaded in launchctl"
        ((issues_found++))
    fi
    
    if [[ $issues_found -eq 0 ]]; then
        echo "✅ Complete removal verified"
        return 0
    else
        echo "⚠️  $issues_found issues found during verification"
        return 1
    fi
}

# Main uninstall process
main() {
    echo ""
    echo "🚀 Starting complete Tenjo removal process..."
    echo "============================================="
    
    # Step 1: Stop all processes
    stop_tenjo_process
    echo ""
    
    # Step 2: Remove LaunchAgent
    remove_launch_agent
    echo ""
    
    # Step 3: Remove installation files
    remove_installation
    echo ""
    
    # Step 4: Remove logs
    remove_logs
    echo ""
    
    # Step 5: Clean cache
    clean_cache
    echo ""
    
    # Step 6: Verify removal
    if verify_removal; then
        echo ""
        echo "🎉 UNINSTALL COMPLETED SUCCESSFULLY!"
        echo "===================================="
        echo "✅ All Tenjo components have been removed"
        echo "✅ System has been restored to clean state"
        echo "✅ No traces of monitoring software remain"
        echo ""
        echo "📊 Removal Summary:"
        echo "   🔄 Processes stopped: All"
        echo "   📱 LaunchAgent removed: Yes"
        echo "   📁 Files removed: All"
        echo "   📋 Logs cleaned: Yes"
        echo "   🧹 Cache cleared: Yes"
        echo ""
        echo "🔒 Your system is now clean and secure."
    else
        echo ""
        echo "⚠️  UNINSTALL COMPLETED WITH WARNINGS"
        echo "===================================="
        echo "Some components may still exist on the system."
        echo "Please check the warnings above and remove manually if needed."
        echo ""
        echo "Manual cleanup commands (if needed):"
        echo "   sudo launchctl unload $LAUNCH_AGENT_FILE"
        echo "   sudo rm -f $LAUNCH_AGENT_FILE"
        echo "   sudo rm -rf $INSTALL_DIR"
        echo "   sudo pkill -f tenjo"
    fi
}

# Run main function
main

# Exit successfully
exit 0
