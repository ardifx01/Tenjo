# API Client for communicating with Tenjo dashboard

import requests
import json
import logging
import time
from datetime import datetime
import base64

class APIClient:
    def __init__(self, server_url, api_key):
        self.server_url = server_url.rstrip('/')
        self.api_key = api_key
        self.client_id = None
        self.session = requests.Session()
        
        # Set default headers
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'Tenjo-Client/1.0'
        })
        
        # Connection settings
        self.timeout = 30
        self.max_retries = 3
        self.retry_delay = 5
        
    def post(self, endpoint, data):
        """Send POST request to API"""
        return self._make_request('POST', endpoint, data)
        
    def get(self, endpoint, params=None):
        """Send GET request to API"""
        return self._make_request('GET', endpoint, params=params)
        
    def put(self, endpoint, data):
        """Send PUT request to API"""
        return self._make_request('PUT', endpoint, data)
        
    def delete(self, endpoint):
        """Send DELETE request to API"""
        return self._make_request('DELETE', endpoint)
        
    def _make_request(self, method, endpoint, data=None, params=None):
        """Make HTTP request with retry logic"""
        url = f"{self.server_url}{endpoint}"
        
        for attempt in range(self.max_retries):
            try:
                if method == 'GET':
                    response = self.session.get(url, params=params, timeout=self.timeout)
                elif method == 'POST':
                    response = self.session.post(url, json=data, timeout=self.timeout)
                elif method == 'PUT':
                    response = self.session.put(url, json=data, timeout=self.timeout)
                elif method == 'DELETE':
                    response = self.session.delete(url, timeout=self.timeout)
                else:
                    raise ValueError(f"Unsupported HTTP method: {method}")
                
                # Check response status
                if response.status_code == 200 or response.status_code == 201:
                    try:
                        return response.json()
                    except json.JSONDecodeError:
                        return {'success': True}
                elif response.status_code == 401:
                    logging.error("API authentication failed")
                    return None
                elif response.status_code == 404:
                    logging.warning(f"API endpoint not found: {endpoint}")
                    return None
                else:
                    logging.warning(f"API request failed with status {response.status_code}")
                    
            except requests.exceptions.ConnectionError:
                logging.warning(f"Connection error on attempt {attempt + 1}")
            except requests.exceptions.Timeout:
                logging.warning(f"Request timeout on attempt {attempt + 1}")
            except Exception as e:
                logging.error(f"Request error: {str(e)}")
                
            # Wait before retry
            if attempt < self.max_retries - 1:
                time.sleep(self.retry_delay)
                
        logging.error(f"Failed to complete {method} request to {endpoint} after {self.max_retries} attempts")
        return None
        
    def upload_file(self, endpoint, file_data, filename, additional_data=None):
        """Upload file to API"""
        url = f"{self.server_url}{endpoint}"
        
        files = {
            'file': (filename, file_data, 'application/octet-stream')
        }
        
        data = additional_data or {}
        
        # Remove Content-Type header for file uploads
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'User-Agent': 'Tenjo-Client/1.0'
        }
        
        for attempt in range(self.max_retries):
            try:
                response = requests.post(
                    url, 
                    files=files, 
                    data=data, 
                    headers=headers,
                    timeout=self.timeout
                )
                
                if response.status_code == 200 or response.status_code == 201:
                    try:
                        return response.json()
                    except json.JSONDecodeError:
                        return {'success': True}
                else:
                    logging.warning(f"File upload failed with status {response.status_code}")
                    
            except Exception as e:
                logging.error(f"File upload error: {str(e)}")
                
            if attempt < self.max_retries - 1:
                time.sleep(self.retry_delay)
                
        return None
        
    def upload_screenshot(self, image_data, metadata):
        """Upload screenshot with metadata"""
        # Convert base64 image data to bytes
        image_bytes = base64.b64decode(image_data)
        
        # Create filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"screenshot_{timestamp}.jpg"
        
        return self.upload_file('/api/screenshots/upload', image_bytes, filename, metadata)
        
    def get_websocket_url(self):
        """Get WebSocket URL for streaming"""
        try:
            response = self.get('/api/stream/websocket-url')
            if response:
                return response.get('websocket_url')
        except Exception as e:
            logging.error(f"Error getting WebSocket URL: {str(e)}")
        return None
        
    def send_heartbeat(self, client_id):
        """Send heartbeat to keep connection alive"""
        data = {
            'client_id': client_id,
            'timestamp': datetime.now().isoformat(),
            'status': 'active'
        }
        return self.post('/api/clients/heartbeat', data)
        
    def register_client(self, client_info):
        """Register client with server"""
        return self.post('/api/clients/register', client_info)
        
    def send_process_data(self, process_data):
        """Send process monitoring data"""
        return self.post('/api/process-events', process_data)
        
    def send_browser_data(self, browser_data):
        """Send browser monitoring data"""
        return self.post('/api/browser-events', browser_data)
        
    def send_url_data(self, url_data):
        """Send URL access data"""
        return self.post('/api/url-events', url_data)
        
    def get_client_settings(self, client_id):
        """Get client-specific settings"""
        return self.get(f'/api/clients/{client_id}/settings')
        
    def update_client_status(self, client_id, status_data):
        """Update client status"""
        return self.put(f'/api/clients/{client_id}/status', status_data)
        
    def test_connection(self):
        """Test connection to server"""
        try:
            response = self.get('/api/health')
            return response is not None
        except Exception:
            return False
