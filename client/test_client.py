#!/usr/bin/env python3
"""
Tenjo Client Test - Simple testing script
Tests core functionality without full monitoring loop
"""

import sys
import os
import requests
import json
from datetime import datetime
import time

# Add src to path
sys.path.append('src')

# Import modules
import core.config as config
from modules.screen_capture import ScreenCapture
from modules.browser_monitor import BrowserMonitor
from modules.process_monitor import ProcessMonitor
from utils.api_client import APIClient

def test_api_connection():
    """Test API connectivity"""
    print("🔌 Testing API Connection...")
    try:
        response = requests.get(f'{config.SERVER_URL}/api/health', timeout=5)
        if response.status_code == 200:
            print("✅ API Connection: SUCCESS")
            return True
        else:
            print(f"❌ API Connection: FAILED (Status: {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ API Connection: FAILED ({e})")
        return False

def test_client_registration():
    """Test client registration"""
    print("📝 Testing Client Registration...")
    
    client_data = {
        'hostname': config.CLIENT_NAME,
        'os': {'name': 'macOS', 'version': '14.6', 'platform': 'Darwin'},
        'ip_address': '127.0.0.1',
        'user': config.CLIENT_USER,
        'timezone': 'Asia/Jakarta'
    }
    
    try:
        response = requests.post(
            f'{config.SERVER_URL}/api/clients/register',
            json=client_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        if response.status_code in [200, 201]:
            print("✅ Client Registration: SUCCESS")
            data = response.json()
            print(f"   Client ID: {data.get('client_id', 'N/A')}")
            return True
        else:
            print(f"❌ Client Registration: FAILED (Status: {response.status_code})")
            print(f"   Response: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"❌ Client Registration: FAILED ({e})")
        return False

def test_screenshot_capture():
    """Test screenshot capture and upload"""
    print("📸 Testing Screenshot Capture...")
    
    try:
        api_client = APIClient(config.SERVER_URL, "test-key")
        screen_capture = ScreenCapture(api_client)
        
        # Capture screenshot
        result = screen_capture.capture_and_upload()
        
        if result:
            print("✅ Screenshot Capture: SUCCESS")
            return True
        else:
            print("❌ Screenshot Capture: FAILED")
            return False
            
    except Exception as e:
        print(f"❌ Screenshot Capture: FAILED ({e})")
        return False

def test_browser_monitoring():
    """Test browser monitoring"""
    print("🌐 Testing Browser Monitoring...")
    
    try:
        api_client = APIClient(config.SERVER_URL, "test-key")
        browser_monitor = BrowserMonitor(api_client)
        
        # Get browser data
        browser_data = browser_monitor.get_browser_info()
        
        if browser_data:
            print("✅ Browser Monitoring: SUCCESS")
            print(f"   Found {len(browser_data)} browser activities")
            return True
        else:
            print("⚠️  Browser Monitoring: NO DATA (Normal if no browsers open)")
            return True
            
    except Exception as e:
        print(f"❌ Browser Monitoring: FAILED ({e})")
        return False

def test_process_monitoring():
    """Test process monitoring"""
    print("💻 Testing Process Monitoring...")
    
    try:
        api_client = APIClient(config.SERVER_URL, "test-key")
        process_monitor = ProcessMonitor(api_client)
        
        # Get process data
        process_data = process_monitor.get_processes()
        
        if process_data:
            print("✅ Process Monitoring: SUCCESS")
            print(f"   Found {len(process_data)} active processes")
            return True
        else:
            print("❌ Process Monitoring: NO DATA")
            return False
            
    except Exception as e:
        print(f"❌ Process Monitoring: FAILED ({e})")
        return False

def test_heartbeat():
    """Test heartbeat functionality"""
    print("💓 Testing Heartbeat...")
    
    try:
        heartbeat_data = {
            'client_id': '9980bf39-4ba3-4832-8aba-92c7a7cec6ff',  # Known client ID
            'timestamp': datetime.now().isoformat(),
            'status': 'active'
        }
        
        response = requests.post(
            f'{config.SERVER_URL}/api/clients/heartbeat',
            json=heartbeat_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        if response.status_code in [200, 201]:
            print("✅ Heartbeat: SUCCESS")
            return True
        else:
            print(f"❌ Heartbeat: FAILED (Status: {response.status_code})")
            return False
            
    except Exception as e:
        print(f"❌ Heartbeat: FAILED ({e})")
        return False

def main():
    """Run all tests"""
    print("🧪 TENJO CLIENT TEST SUITE")
    print("=" * 50)
    
    tests = [
        test_api_connection,
        test_client_registration,
        test_screenshot_capture,
        test_browser_monitoring,
        test_process_monitoring,
        test_heartbeat
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
            print()  # Empty line between tests
        except Exception as e:
            print(f"❌ Test crashed: {e}")
            print()
    
    print("=" * 50)
    print(f"📊 RESULTS: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! Client is ready for deployment.")
    elif passed >= total * 0.7:
        print("⚠️  MOSTLY WORKING. Some issues need attention.")
    else:
        print("🚨 MAJOR ISSUES. Client needs debugging.")
    
    print("=" * 50)

if __name__ == "__main__":
    main()
