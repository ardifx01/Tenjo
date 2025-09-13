#!/usr/bin/env python3
"""Debug API Client Issues"""

import requests
import json
import sys

def test_simple_request():
    """Test simple request without any headers"""
    try:
        response = requests.get('http://localhost:8003/api/health', timeout=10)
        print(f"✅ Simple request: {response.status_code} - {response.text}")
        return True
    except Exception as e:
        print(f"❌ Simple request failed: {e}")
        return False

def test_with_headers():
    """Test with API client headers"""
    try:
        headers = {
            'Authorization': 'Bearer dummy-key',
            'Content-Type': 'application/json',
            'User-Agent': 'Tenjo-Client/1.0'
        }
        response = requests.get('http://localhost:8003/api/health', headers=headers, timeout=10)
        print(f"✅ With headers: {response.status_code} - {response.text}")
        return True
    except Exception as e:
        print(f"❌ With headers failed: {e}")
        return False

def test_api_client():
    """Test actual API client"""
    try:
        sys.path.append('/Users/yapi/Adi/App-Dev/Tenjo/client')
        from src.utils.api_client import APIClient
        from src.core.config import Config
        
        client = APIClient(Config.SERVER_URL, 'dummy-key')
        result = client.get('/api/health')
        print(f"✅ API Client: {result}")
        return True
    except Exception as e:
        print(f"❌ API Client failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("=== API CLIENT DEBUGGING ===")
    
    print("\n1. Testing simple request...")
    test_simple_request()
    
    print("\n2. Testing with headers...")
    test_with_headers()
    
    print("\n3. Testing API client...")
    test_api_client()
    
    print("\n=== DEBUGGING COMPLETE ===")
