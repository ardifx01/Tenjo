#!/usr/bin/env python3
"""
Simple Local API Test - Direct HTTP calls
"""

import requests
import json

def test_direct_api():
    base_url = 'http://127.0.0.1:8000'
    
    print('=== DIRECT LOCAL API TEST ===')
    print(f'🌐 Testing: {base_url}')
    
    try:
        # Test 1: Health check
        print('\n1️⃣ Testing health endpoint...')
        response = requests.get(f'{base_url}/api/health', timeout=10)
        print(f'   Status: {response.status_code}')
        print(f'   Response: {response.text}')
        
        # Test 2: Registration
        print('\n2️⃣ Testing registration...')
        data = {
            'client_id': 'test-local-direct-001',
            'hostname': 'test-host-direct',
            'ip_address': '192.168.1.100',
            'username': 'test-user',
            'os_info': {
                'name': 'macOS',
                'version': '14.0',
                'architecture': 'arm64'
            },
            'timezone': 'Asia/Jakarta'
        }
        
        response = requests.post(f'{base_url}/api/clients/register', 
                               json=data, 
                               headers={'Content-Type': 'application/json'},
                               timeout=10)
        print(f'   Status: {response.status_code}')
        print(f'   Response: {response.text}')
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                client_id = result.get('client_id', data['client_id'])
                
                # Test 3: Heartbeat
                print('\n3️⃣ Testing heartbeat...')
                heartbeat_data = {
                    'client_id': client_id,
                    'timestamp': '2025-09-13T10:51:00.000Z',
                    'status': 'active'
                }
                
                response = requests.post(f'{base_url}/api/clients/heartbeat',
                                       json=heartbeat_data,
                                       headers={'Content-Type': 'application/json'},
                                       timeout=10)
                print(f'   Status: {response.status_code}')
                print(f'   Response: {response.text}')
        
        print('\n✅ Direct API test completed successfully!')
        return True
        
    except Exception as e:
        print(f'\n❌ Test failed: {e}')
        return False

if __name__ == "__main__":
    test_direct_api()
