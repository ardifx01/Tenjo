#!/usr/bin/env python3
"""
Script to discover the actual production API endpoints by testing common patterns.
"""

import requests
import json

def test_endpoint(method, endpoint, data=None):
    """Test an API endpoint and return the response."""
    url = f"http://103.129.149.67{endpoint}"
    headers = {'Content-Type': 'application/json'}
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, timeout=5)
        elif method == 'POST':
            response = requests.post(url, headers=headers, data=json.dumps(data) if data else None, timeout=5)
        
        return {
            'status_code': response.status_code,
            'content_type': response.headers.get('content-type', ''),
            'content': response.text[:200] + '...' if len(response.text) > 200 else response.text
        }
    except Exception as e:
        return {'error': str(e)}

# Test common API patterns
endpoints_to_test = [
    # Registration endpoints
    ('POST', '/api/register'),
    ('POST', '/api/client/register'),
    ('POST', '/api/clients/register'),
    ('POST', '/register'),
    ('POST', '/client/register'),
    
    # Data submission endpoints
    ('POST', '/api/screenshot'),
    ('POST', '/api/screenshots'),
    ('POST', '/api/data'),
    ('POST', '/api/upload'),
    ('POST', '/screenshot'),
    ('POST', '/upload'),
    
    # Heartbeat endpoints
    ('POST', '/api/heartbeat'),
    ('POST', '/api/ping'),
    ('POST', '/heartbeat'),
    ('POST', '/ping'),
    
    # Status endpoints
    ('GET', '/api/status'),
    ('GET', '/api/health'),
    ('GET', '/status'),
    ('GET', '/health'),
]

test_data = {
    'client_id': 'test-discovery',
    'hostname': 'test-host',
    'ip_address': '192.168.1.100',
    'user': 'test-user',
    'os': 'macOS 14.0',
    'timezone': 'Asia/Jakarta'
}

print("🔍 Discovering Production API Endpoints")
print("=" * 50)

for method, endpoint in endpoints_to_test:
    print(f"\n🧪 Testing {method} {endpoint}")
    
    if method == 'POST':
        result = test_endpoint(method, endpoint, test_data)
    else:
        result = test_endpoint(method, endpoint)
    
    if 'error' in result:
        print(f"   ❌ Error: {result['error']}")
    else:
        status = result['status_code']
        content_type = result['content_type']
        
        if status == 200:
            print(f"   ✅ SUCCESS ({status}) - {content_type}")
            print(f"   📄 Response: {result['content']}")
        elif status == 404:
            print(f"   🚫 Not Found ({status})")
        elif status == 405:
            print(f"   ⚠️  Method Not Allowed ({status})")
        elif status == 422:
            print(f"   ⚠️  Validation Error ({status})")
            print(f"   📄 Response: {result['content']}")
        else:
            print(f"   ⚠️  Status {status} - {content_type}")
            print(f"   📄 Response: {result['content']}")

print("\n" + "=" * 50)
print("✅ API Discovery Complete")
