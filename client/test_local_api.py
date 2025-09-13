#!/usr/bin/env python3
"""
Local API Test Script
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from src.core.config import Config
from src.utils.api_client import APIClient
import socket
import platform
import requests

def test_local_api():
    print('=== TESTING LOCAL API ===')
    print(f'📡 Server URL: {Config.SERVER_URL}')
    
    # Test health endpoint directly
    try:
        response = requests.get(f'{Config.SERVER_URL}/api/health', timeout=5)
        print(f'🔗 Direct health check: {response.status_code} - {response.text[:100]}')
    except Exception as e:
        print(f'❌ Direct health check failed: {e}')
        return False
    
    api_client = APIClient(Config.SERVER_URL, 'dummy-key')
    
    # Test registration
    client_info = {
        'client_id': Config.CLIENT_ID,
        'hostname': socket.gethostname(),
        'ip_address': '192.168.1.100',
        'username': Config.CLIENT_USER,
        'os_info': {
            'name': platform.system(),
            'version': platform.release(),
            'architecture': platform.machine()
        },
        'timezone': 'Asia/Jakarta'
    }
    
    try:
        print(f'📋 Testing registration with ID: {Config.CLIENT_ID[:8]}...')
        result = api_client.register_client(client_info)
        print(f'✅ Registration result: {result}')
        
        if result and result.get('success'):
            client_id = result.get('client_id', Config.CLIENT_ID)
            print(f'💓 Testing heartbeat with ID: {client_id[:8]}...')
            heartbeat = api_client.send_heartbeat(client_id)
            print(f'✅ Heartbeat result: {heartbeat}')
            
            print(f'\n🎉 LOCAL API TEST SUCCESSFUL!')
            print(f'🌐 Dashboard: http://127.0.0.1:8001/')
            return True
        
    except Exception as e:
        print(f'❌ Error: {e}')
        return False

if __name__ == "__main__":
    test_local_api()
