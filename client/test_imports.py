#!/usr/bin/env python3
"""
Test script to verify all platform-specific imports work correctly
"""

import platform
import sys

def test_imports():
    """Test all platform-specific imports"""
    print(f"Testing imports on {platform.system()} ({platform.platform()})")
    print(f"Python version: {sys.version}")
    print("-" * 50)
    
    # Test core imports
    try:
        import requests
        print("✓ requests")
    except ImportError as e:
        print(f"✗ requests: {e}")
    
    try:
        import psutil
        print("✓ psutil")
    except ImportError as e:
        print(f"✗ psutil: {e}")
    
    try:
        import mss
        print("✓ mss")
    except ImportError as e:
        print(f"✗ mss: {e}")
    
    try:
        from PIL import Image
        print("✓ Pillow (PIL)")
    except ImportError as e:
        print(f"✗ Pillow (PIL): {e}")
    
    # Test platform-specific imports
    if platform.system() == 'Windows':
        print("\n--- Windows-specific imports ---")
        try:
            import pygetwindow as gw
            print("✓ pygetwindow")
        except ImportError as e:
            print(f"✗ pygetwindow: {e}")
        
        try:
            import win32gui
            print("✓ win32gui")
        except ImportError as e:
            print(f"✗ win32gui: {e}")
        
        try:
            import win32process
            print("✓ win32process")
        except ImportError as e:
            print(f"✗ win32process: {e}")
    
    elif platform.system() == 'Darwin':
        print("\n--- macOS-specific imports ---")
        try:
            from AppKit import NSWorkspace
            print("✓ AppKit.NSWorkspace")
        except ImportError as e:
            print(f"✗ AppKit.NSWorkspace: {e}")
        
        try:
            import Quartz
            print("✓ Quartz")
        except ImportError as e:
            print(f"✗ Quartz: {e}")
    
    else:
        print(f"\n--- {platform.system()} platform ---")
        print("No platform-specific imports required")
    
    # Test browser monitor import
    print("\n--- Testing browser monitor ---")
    try:
        sys.path.insert(0, 'src')
        from modules.browser_monitor import BrowserMonitor
        print("✓ BrowserMonitor import successful")
        
        # Test instantiation
        class MockAPIClient:
            def post(self, endpoint, data):
                return {"status": "ok"}
        
        monitor = BrowserMonitor(MockAPIClient())
        print("✓ BrowserMonitor instantiation successful")
        
    except Exception as e:
        print(f"✗ BrowserMonitor: {e}")
    
    print("\n" + "=" * 50)
    print("Import test completed")

if __name__ == '__main__':
    test_imports()
