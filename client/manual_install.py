#!/usr/bin/env python3
"""
Manual Tenjo Client Installation for MacBook
Testing without server connection
"""

import os
import sys
import platform
import getpass
import time
import threading
from datetime import datetime

# Add src to path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, 'src'))

def test_imports():
    """Test all imports first"""
    print("🔍 Testing imports...")
    
    try:
        import requests
        print("  ✅ requests")
    except ImportError as e:
        print(f"  ❌ requests: {e}")
        return False
    
    try:
        import psutil
        print("  ✅ psutil")
    except ImportError as e:
        print(f"  ❌ psutil: {e}")
        return False
    
    try:
        import mss
        print("  ✅ mss")
    except ImportError as e:
        print(f"  ❌ mss: {e}")
        return False
    
    try:
        from PIL import Image
        print("  ✅ Pillow")
    except ImportError as e:
        print(f"  ❌ Pillow: {e}")
        return False
    
    try:
        from AppKit import NSWorkspace
        print("  ✅ AppKit (macOS)")
    except ImportError as e:
        print(f"  ❌ AppKit: {e}")
        return False
    
    return True

def test_system_info():
    """Test system information gathering"""
    print("\n📱 Testing system information...")
    
    try:
        import socket
        hostname = socket.gethostname()
        print(f"  Hostname: {hostname}")
        
        # Get IP address
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        print(f"  IP Address: {ip}")
        
        # Get user info
        user = getpass.getuser()
        print(f"  Username: {user}")
        
        # Get OS info
        os_info = platform.platform()
        print(f"  OS: {os_info}")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def test_screenshot():
    """Test screenshot functionality"""
    print("\n📸 Testing screenshot capture...")
    
    try:
        import mss
        from PIL import Image
        import io
        
        with mss.mss() as sct:
            # Get the first monitor
            monitor = sct.monitors[1]  # monitors[0] is all monitors combined
            
            # Take screenshot
            screenshot = sct.grab(monitor)
            
            # Convert to PIL Image
            img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
            
            # Test compression
            buffer = io.BytesIO()
            img.save(buffer, format='JPEG', quality=50)
            compressed_size = len(buffer.getvalue())
            
            print(f"  ✅ Screenshot captured: {screenshot.size[0]}x{screenshot.size[1]}")
            print(f"  ✅ Compressed size: {compressed_size} bytes")
            
            return True
            
    except Exception as e:
        print(f"  ❌ Screenshot error: {e}")
        return False

def test_browser_monitoring():
    """Test browser monitoring capabilities"""
    print("\n🌐 Testing browser monitoring...")
    
    try:
        from AppKit import NSWorkspace
        
        # Get active application
        workspace = NSWorkspace.sharedWorkspace()
        active_app = workspace.activeApplication()
        
        if active_app:
            app_name = active_app.get('NSApplicationName', 'Unknown')
            bundle_id = active_app.get('NSApplicationBundleIdentifier', 'Unknown')
            
            print(f"  ✅ Active app: {app_name}")
            print(f"  ✅ Bundle ID: {bundle_id}")
            
            # Check if it's a browser
            browser_bundles = [
                'com.google.Chrome',
                'com.apple.Safari',
                'org.mozilla.firefox',
                'com.microsoft.edgemac',
                'com.operasoftware.Opera'
            ]
            
            is_browser = bundle_id in browser_bundles
            print(f"  ✅ Is browser: {is_browser}")
            
        return True
        
    except Exception as e:
        print(f"  ❌ Browser monitoring error: {e}")
        return False

def test_process_monitoring():
    """Test process monitoring"""
    print("\n⚙️ Testing process monitoring...")
    
    try:
        import psutil
        
        # Get system info
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        print(f"  ✅ CPU Usage: {cpu_percent}%")
        print(f"  ✅ Memory Usage: {memory.percent}%")
        print(f"  ✅ Disk Usage: {disk.percent}%")
        
        # Get running processes count
        processes = list(psutil.process_iter(['name']))
        print(f"  ✅ Running processes: {len(processes)}")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Process monitoring error: {e}")
        return False

def install_as_service():
    """Install client as background service"""
    print("\n🔧 Installing as background service...")
    
    try:
        # Create hidden directory
        home_dir = os.path.expanduser('~')
        hidden_dir = os.path.join(home_dir, '.system_cache')
        os.makedirs(hidden_dir, exist_ok=True)
        
        # Copy main files to hidden directory
        import shutil
        
        # Copy main script
        main_file = os.path.join(current_dir, 'main.py')
        if os.path.exists(main_file):
            shutil.copy2(main_file, hidden_dir)
            print("  ✅ Main script copied")
        
        # Copy src directory
        src_dir = os.path.join(current_dir, 'src')
        hidden_src = os.path.join(hidden_dir, 'src')
        if os.path.exists(src_dir):
            if os.path.exists(hidden_src):
                shutil.rmtree(hidden_src)
            shutil.copytree(src_dir, hidden_src)
            print("  ✅ Source files copied")
        
        print(f"  ✅ Client installed to: {hidden_dir}")
        
        # Create launch script
        launch_script = f"""#!/bin/bash
cd {hidden_dir}
python3 main.py > /dev/null 2>&1 &
"""
        
        script_path = os.path.join(hidden_dir, 'start_client.sh')
        with open(script_path, 'w') as f:
            f.write(launch_script)
        os.chmod(script_path, 0o755)
        
        print("  ✅ Launch script created")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Installation error: {e}")
        return False

def run_demo_monitoring():
    """Run a demo monitoring session"""
    print("\n🎭 Running demo monitoring session...")
    
    print("Demo akan berjalan selama 30 detik...")
    print("Silakan buka/tutup aplikasi atau browser untuk melihat monitoring bekerja")
    
    try:
        import psutil
        from AppKit import NSWorkspace
        import mss
        
        start_time = time.time()
        last_app = None
        screenshot_count = 0
        
        while time.time() - start_time < 30:  # Run for 30 seconds
            current_time = datetime.now().strftime("%H:%M:%S")
            
            # Monitor active application
            workspace = NSWorkspace.sharedWorkspace()
            active_app = workspace.activeApplication()
            
            if active_app:
                app_name = active_app.get('NSApplicationName', 'Unknown')
                if app_name != last_app:
                    print(f"  [{current_time}] 🎯 Active app changed: {app_name}")
                    last_app = app_name
            
            # Monitor system resources every 5 seconds
            if int(time.time()) % 5 == 0:
                cpu = psutil.cpu_percent()
                memory = psutil.virtual_memory().percent
                print(f"  [{current_time}] 📊 CPU: {cpu}%, Memory: {memory}%")
            
            # Take screenshot every 10 seconds
            if int(time.time()) % 10 == 0 and screenshot_count < 3:
                try:
                    with mss.mss() as sct:
                        screenshot = sct.grab(sct.monitors[1])
                        print(f"  [{current_time}] 📸 Screenshot captured: {screenshot.size}")
                        screenshot_count += 1
                except:
                    pass
            
            time.sleep(1)
        
        print("  ✅ Demo monitoring completed!")
        
    except KeyboardInterrupt:
        print("\n  ⏹️  Demo stopped by user")
    except Exception as e:
        print(f"  ❌ Demo error: {e}")

def main():
    """Main installation and testing function"""
    print("🍎 Tenjo Client - Manual Installation for macOS")
    print("=" * 60)
    
    # Test 1: Imports
    if not test_imports():
        print("\n❌ Import test failed. Please install dependencies:")
        print("pip install requests psutil mss Pillow pyobjc")
        return False
    
    # Test 2: System info
    if not test_system_info():
        print("\n❌ System info test failed")
        return False
    
    # Test 3: Screenshot
    if not test_screenshot():
        print("\n❌ Screenshot test failed")
        return False
    
    # Test 4: Browser monitoring
    if not test_browser_monitoring():
        print("\n❌ Browser monitoring test failed")
        return False
    
    # Test 5: Process monitoring
    if not test_process_monitoring():
        print("\n❌ Process monitoring test failed")
        return False
    
    print("\n" + "=" * 60)
    print("🎉 All tests passed! Client is ready for installation")
    
    # Ask for installation
    choice = input("\nDo you want to install the client as a background service? (y/n): ")
    if choice.lower() == 'y':
        if install_as_service():
            print("\n✅ Installation completed!")
            print("\nClient has been installed to ~/.system_cache/")
            print("To start manually: ~/.system_cache/start_client.sh")
    
    # Ask for demo
    choice = input("\nDo you want to run a 30-second monitoring demo? (y/n): ")
    if choice.lower() == 'y':
        run_demo_monitoring()
    
    print("\n🏁 Installation and testing completed!")
    return True

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⏹️  Installation stopped by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)
