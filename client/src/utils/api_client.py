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
        # Check if this is local development server
        is_local = '127.0.0.1' in self.server_url or 'localhost' in self.server_url
        
        # For local server, try the endpoint first
        if is_local:
            try:
                return self._make_request('POST', endpoint, data)
            except Exception as e:
                # If endpoint doesn't exist on local, that's normal for development
                if endpoint in ['/api/browser-events', '/api/process-events', '/api/system-stats', '/api/url-events']:
                    logging.warning(f"API endpoint not found: {endpoint}")
                    self._store_pending_data(endpoint, data)
                    return {'success': False, 'message': 'Endpoint not implemented yet in local development'}
                else:
                    raise e
        
        # For production server, check known missing endpoints
        if endpoint in ['/api/browser-events', '/api/process-events', '/api/system-stats', '/api/url-events']:
            logging.warning(f"API endpoint not found: {endpoint}")
            # Store data locally for future use when endpoint is available
            self._store_pending_data(endpoint, data)
            return {'success': False, 'message': 'Endpoint not available on production server'}
        
        # Add production headers for JSON endpoints
        if endpoint in ['/api/clients/register', '/api/clients/heartbeat']:
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }
            return self._make_request_with_headers('POST', endpoint, data, headers)
        elif endpoint == '/api/screenshots':
            # Handle screenshots differently - they need form data
            return self.upload_screenshot(data)
        else:
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
        # Raise exception instead of returning None for better error handling
        raise Exception(f"API request failed: {method} {endpoint} after {self.max_retries} attempts")
    
    def _make_request_with_headers(self, method, endpoint, data=None, custom_headers=None):
        """Make HTTP request with custom headers for production API compatibility"""
        url = f"{self.server_url}{endpoint}"
        
        # Create a temporary session with custom headers
        temp_session = requests.Session()
        if custom_headers:
            temp_session.headers.update(custom_headers)
        
        for attempt in range(self.max_retries):
            try:
                if method == 'POST':
                    response = temp_session.post(url, json=data, timeout=self.timeout)
                else:
                    raise ValueError(f"Unsupported HTTP method: {method}")
                
                if response.status_code in [200, 201]:
                    try:
                        return response.json()
                    except ValueError:
                        return {'success': True, 'message': 'Request successful'}
                else:
                    logging.warning(f"HTTP {response.status_code} on attempt {attempt + 1}: {response.text}")
                    
            except requests.exceptions.Timeout:
                logging.warning(f"Request timeout on attempt {attempt + 1}")
            except Exception as e:
                logging.error(f"Request error: {str(e)}")
                
            # Wait before retry
            if attempt < self.max_retries - 1:
                time.sleep(self.retry_delay)
                
        logging.error(f"Failed to complete {method} request to {endpoint} after {self.max_retries} attempts")
        raise Exception(f"API request failed: {method} {endpoint} after {self.max_retries} attempts")
        
    def upload_screenshot(self, screenshot_data):
        """Upload screenshot to production API with proper format"""
        # Production API expects specific format
        headers = {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }
        
        # Use form data for screenshot upload (not JSON)
        url = f"{self.server_url}/api/screenshots"
        
        try:
            response = requests.post(
                url,
                data=screenshot_data,  # Send as form data
                headers=headers,
                timeout=self.timeout
            )
            
            if response.status_code in [200, 201]:
                try:
                    return response.json()
                except ValueError:
                    return {'success': True, 'message': 'Screenshot uploaded'}
            else:
                logging.warning(f"Screenshot upload failed: HTTP {response.status_code}")
                return None
                
        except Exception as e:
            logging.error(f"Screenshot upload error: {str(e)}")
            return None
    
    def _store_pending_data(self, endpoint, data):
        """Store data locally when endpoint is not available"""
        import json
        import os
        
        # Create pending data directory
        pending_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'pending')
        os.makedirs(pending_dir, exist_ok=True)
        
        # Create filename based on endpoint
        filename = endpoint.replace('/', '_').replace('-', '_') + '_pending.jsonl'
        filepath = os.path.join(pending_dir, filename)
        
        # Append data to file (JSONL format)
        try:
            with open(filepath, 'a') as f:
                f.write(json.dumps(data) + '\n')
            logging.debug(f"Stored pending data for {endpoint}")
        except Exception as e:
            logging.error(f"Failed to store pending data: {e}")
    
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
        """Upload screenshot - Local API format"""
        # For local API, use the upload_file method with proper endpoint
        try:
            # Convert base64 to bytes
            import base64
            image_bytes = base64.b64decode(image_data)
            
            # Create filename
            from datetime import datetime
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"screenshot_{timestamp}.jpg"
            
            # Use local endpoint
            return self.upload_file('/api/screenshots', image_bytes, filename, metadata)
        except Exception as e:
            print(f"Screenshot upload failed: {e}")
            return {'success': False, 'message': str(e)}
        
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
        """Register client with the server."""
        # Use local API format (not production)
        try:
            response = self.post('/api/clients/register', client_info)
            return response
        except Exception as e:
            print(f"Registration failed: {e}")
            raise
        
    def send_process_data(self, process_data):
        """Send process monitoring data"""
        return self.post('/api/process-events', process_data)
        
    def send_browser_data(self, browser_data):
        """Send browser monitoring data"""
        return self.post('/api/browser-events', browser_data)
        
    def send_url_data(self, url_data):
        """Send URL access data"""
        return self.post('/api/url-events', url_data)
        
    # Helper methods for easy testing
    def send_test_browser_event(self, client_id, event_type='page_visit', browser_name='Chrome', url='https://test.com', title='Test Page'):
        """Send test browser event with required fields"""
        from datetime import datetime
        data = {
            'client_id': client_id,
            'event_type': event_type,
            'browser_name': browser_name,
            'url': url,
            'title': title,
            'timestamp': datetime.now().isoformat()
        }
        return self.send_browser_data(data)
        
    def send_test_process_event(self, client_id, event_type='process_started', process_name='python3', process_pid=12345):
        """Send test process event with required fields"""
        from datetime import datetime
        data = {
            'client_id': client_id,
            'event_type': event_type,
            'process_name': process_name,
            'process_pid': process_pid,
            'timestamp': datetime.now().isoformat()
        }
        return self.send_process_data(data)
        
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
