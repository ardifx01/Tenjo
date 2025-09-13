#!/usr/bin/env python3
"""
Production Test Script for Tenjo Client
Tests client registration and screenshot upload with production server
"""

import sys
import os
import logging
from datetime import datetime

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.config import Config
from utils.api_client import APIClient
from modules.screen_capture import ScreenCapture

def setup_logging():
    """Setup logging for testing"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('production_test.log')
        ]
    )

def test_client_registration():
    """Test client registration with production server"""
    print("🔧 Testing Client Registration...")
    
    try:
        api_client = APIClient(Config.SERVER_URL, Config.CLIENT_ID)
        
        # Prepare client info
        import socket
        import platform
        
        client_info = {
            'client_id': Config.CLIENT_ID,
            'hostname': socket.gethostname(),
            'ip_address': 'auto-detect',
            'username': Config.CLIENT_USER,
            'user': Config.CLIENT_USER,
            'os_info': {
                'name': platform.system(),
                'version': platform.release(),
                'architecture': platform.machine()
            },
            'timezone': 'Asia/Jakarta'
        }
        
        print(f"📡 Registering with server: {Config.SERVER_URL}")
        print(f"🆔 Client ID: {Config.CLIENT_ID[:8]}...")
        print(f"🖥️  Hostname: {client_info['hostname']}")
        
        response = api_client.register_client(client_info)
        
        if response and response.get('success'):
            print("✅ Client registration successful!")
            print(f"📝 Response: {response}")
            return True
        else:
            print("❌ Client registration failed!")
            print(f"📝 Response: {response}")
            return False
            
    except Exception as e:
        print(f"❌ Registration error: {str(e)}")
        logging.error(f"Registration test failed: {str(e)}")
        return False

def test_screenshot_upload():
    """Test screenshot capture and upload"""
    print("\n📸 Testing Screenshot Upload...")
    
    try:
        api_client = APIClient(Config.SERVER_URL, Config.CLIENT_ID)
        screen_capture = ScreenCapture(api_client)
        
        print("📷 Capturing screenshot...")
        result = screen_capture.capture_and_upload()
        
        if result and result.get('success'):
            print("✅ Screenshot upload successful!")
            print(f"📝 Response: {result}")
            return True
        else:
            print("❌ Screenshot upload failed!")
            print(f"📝 Response: {result}")
            return False
            
    except Exception as e:
        print(f"❌ Screenshot error: {str(e)}")
        logging.error(f"Screenshot test failed: {str(e)}")
        return False

def test_api_connectivity():
    """Test basic API connectivity"""
    print("🌐 Testing API Connectivity...")
    
    try:
        api_client = APIClient(Config.SERVER_URL, Config.CLIENT_ID)
        
        # Test health endpoint
        response = api_client.get('/api/health')
        
        if response:
            print("✅ API connectivity successful!")
            print(f"📝 Health check response: {response}")
            return True
        else:
            print("❌ API connectivity failed!")
            return False
            
    except Exception as e:
        print(f"❌ Connectivity error: {str(e)}")
        logging.error(f"Connectivity test failed: {str(e)}")
        return False

def main():
    """Run all production tests"""
    setup_logging()
    
    print("🚀 Tenjo Production Test Suite")
    print("=" * 50)
    print(f"🎯 Target Server: {Config.SERVER_URL}")
    print(f"🆔 Client ID: {Config.CLIENT_ID[:8]}...")
    print(f"⏰ Test Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 50)
    
    tests = [
        ("API Connectivity", test_api_connectivity),
        ("Client Registration", test_client_registration),
        ("Screenshot Upload", test_screenshot_upload)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        print(f"\n🧪 Running: {test_name}")
        print("-" * 30)
        
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"❌ Test '{test_name}' crashed: {str(e)}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 TEST RESULTS SUMMARY")
    print("=" * 50)
    
    passed = 0
    total = len(results)
    
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {test_name}")
        if success:
            passed += 1
    
    print("-" * 50)
    print(f"📈 Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! Production setup is working correctly.")
        return 0
    else:
        print("⚠️  SOME TESTS FAILED! Check the logs and fix issues before deployment.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)