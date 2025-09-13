# API Client for communicating with Tenjo dashboard

import requests
import json
import logging
import time
import socket
import subprocess
import platform
from datetime import datetime
import base64

class APIClient:
    def __init__(self, server_url, api_key):
        self.server_url = server_url.rstrip('/')
        self.api_key = api_key
        self.client_id = None
        self.session = requests.Session()

        # Cache for missing endpoints to avoid spam warnings
        self._missing_endpoints = set()

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

    def get_real_ip_address(self):
        """Auto-detect the real IP address of the client with improved reliability."""
        detected_ips = []

        try:
            # Method 1: Try to get IP by connecting to a remote server
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
                s.settimeout(5)  # 5 second timeout
                # Connect to Google DNS (doesn't actually send data)
                s.connect(("8.8.8.8", 80))
                local_ip = s.getsockname()[0]

            # Validate the IP is not localhost or link-local
            if local_ip and local_ip != "127.0.0.1" and not local_ip.startswith("169.254"):
                detected_ips.append(local_ip)
                logging.info(f"Detected local IP via socket method: {local_ip}")

        except Exception as e:
            logging.debug(f"Socket method failed: {e}")

        # If we got a good IP, return it immediately
        if detected_ips:
            logging.info(f"Selected IP: {detected_ips[0]}")
            return detected_ips[0]

        try:
            # Method 2: Quick hostname resolution
            hostname = socket.gethostname()
            ip = socket.gethostbyname(hostname)

            if ip and self._is_valid_private_ip(ip):
                detected_ips.append(ip)
                logging.info(f"Detected IP via hostname resolution: {ip}")

        except Exception as e:
            logging.debug(f"Hostname resolution failed: {e}")

        # Return the detected IP or fallback
        if detected_ips:
            logging.info(f"Selected IP: {detected_ips[0]}")
            return detected_ips[0]

        # Final fallback
        logging.warning("Could not auto-detect IP address, using fallback")
        return "192.168.1.100"  # Generic fallback

    def _is_valid_private_ip(self, ip):
        """Check if IP is a valid private IP address"""
        if not ip or ip == "127.0.0.1" or ip.startswith("169.254"):
            return False

        parts = ip.split('.')
        if len(parts) != 4:
            return False

        try:
            first = int(parts[0])
            second = int(parts[1])

            # Check private ranges
            if first == 192 and second == 168:
                return True
            if first == 10:
                return True
            if first == 172 and 16 <= second <= 31:
                return True

        except ValueError:
            return False

        return False

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
                    # Only log warning once per endpoint
                    if endpoint not in self._missing_endpoints:
                        logging.warning(f"API endpoint not implemented yet: {endpoint}")
                        self._missing_endpoints.add(endpoint)
                    self._store_pending_data(endpoint, data)
                    return {'success': False, 'message': 'Endpoint not implemented yet in local development'}
                else:
                    raise e

        # For production server, check known missing endpoints
        if endpoint in ['/api/browser-events', '/api/process-events', '/api/system-stats', '/api/url-events']:
            # Only log warning once per endpoint
            if endpoint not in self._missing_endpoints:
                logging.warning(f"API endpoint not available on production: {endpoint}")
                self._missing_endpoints.add(endpoint)
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
            # Handle screenshots - pass through to the proper upload method
            # screenshot_data should have image_data and metadata
            if isinstance(data, dict) and 'image_data' in data:
                # This is the new format with separate image_data and metadata
                return self.upload_screenshot(data.get('image_data'), data)
            else:
                # Legacy format - data is the image_data itself
                return self.upload_screenshot(data, {})
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
        """Upload screenshot - Handle both local and production APIs with consistent format"""
        import base64  # Import at function level
        
        # Check if this is production server
        is_production = '103.129.149.67' in self.server_url

        try:
            logging.debug(f"Upload screenshot called with image_data type: {type(image_data)}")
            logging.debug(f"Image data length: {len(image_data) if image_data else 'None'}")
            logging.debug(f"Metadata: {metadata}")
            
            # Ensure image_data is valid base64
            if isinstance(image_data, bytes):
                # Convert bytes to base64
                image_data = base64.b64encode(image_data).decode('utf-8')
                logging.debug("Converted bytes to base64")
            elif not isinstance(image_data, str):
                logging.error(f"Invalid image data format: {type(image_data)}")
                raise ValueError("Invalid image data format")

            # Validate base64 data
            try:
                test_decode = base64.b64decode(image_data)
                logging.debug(f"Base64 decode successful, decoded size: {len(test_decode)}")
                if len(test_decode) < 100:
                    logging.error(f"Image data too small: {len(test_decode)} bytes")
                    raise ValueError("Image data too small")
            except Exception as e:
                logging.error(f"Base64 decode failed: {e}")
                logging.debug(f"Image data preview: {image_data[:100]}...")
                raise ValueError("Invalid base64 image data")

            # Prepare consistent data format
            screenshot_data = {
                'client_id': metadata.get('client_id'),
                'image_data': image_data,  # Clean base64 without data URL prefix
                'resolution': metadata.get('resolution', 'unknown'),
                'monitor': metadata.get('monitor', 1),
                'timestamp': metadata.get('timestamp', datetime.now().isoformat())
            }

            if is_production:
                # Production server - try to upload, fallback to local storage
                try:
                    headers = {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-Requested-With': 'XMLHttpRequest'
                    }

                    result = self._make_request_with_headers('POST', '/api/screenshots', screenshot_data, headers)
                    if result and result.get('success'):
                        logging.info("Screenshot uploaded to production successfully")
                        return result
                    else:
                        # Fallback to local storage
                        self._store_screenshot_locally(image_data, metadata)
                        logging.info("Screenshot stored locally - production upload failed")
                        return {
                            'success': True,
                            'message': 'Screenshot captured and stored locally (production fallback)',
                            'stored_locally': True
                        }
                except Exception as e:
                    # Store locally as fallback
                    self._store_screenshot_locally(image_data, metadata)
                    logging.warning(f"Production upload failed, stored locally: {e}")
                    return {
                        'success': True,
                        'message': 'Screenshot captured and stored locally (production error)',
                        'stored_locally': True,
                        'error': str(e)
                    }
            else:
                # Local development API
                try:
                    result = self._make_request('POST', '/api/screenshots', screenshot_data)
                    if result and result.get('success'):
                        return result
                    else:
                        # Still store locally for development
                        self._store_screenshot_locally(image_data, metadata)
                        return {
                            'success': True,
                            'message': 'Screenshot stored locally (development mode)',
                            'stored_locally': True
                        }
                except Exception as e:
                    # Store locally as fallback
                    self._store_screenshot_locally(image_data, metadata)
                    logging.warning(f"Local upload failed, stored locally: {e}")
                    return {
                        'success': True,
                        'message': 'Screenshot stored locally (upload error)',
                        'stored_locally': True,
                        'error': str(e)
                    }

        except Exception as e:
            logging.error(f"Screenshot upload error: {e}")
            return {'success': False, 'message': f'Screenshot upload failed: {str(e)}'}

    def _store_screenshot_locally(self, image_data, metadata):
        """Store screenshot locally when production upload is not available"""
        import os
        import json
        import base64
        from datetime import datetime

        # Create screenshots directory
        screenshots_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'screenshots')
        os.makedirs(screenshots_dir, exist_ok=True)

        # Create filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]  # Include milliseconds
        filename = f"screenshot_{timestamp}"

        # Save image file
        image_bytes = base64.b64decode(image_data)
        image_path = os.path.join(screenshots_dir, f"{filename}.jpg")
        with open(image_path, 'wb') as f:
            f.write(image_bytes)

        # Save metadata
        metadata_with_file = {
            **metadata,
            'local_file': f"{filename}.jpg",
            'stored_at': datetime.now().isoformat(),
            'size_bytes': len(image_bytes)
        }

        metadata_path = os.path.join(screenshots_dir, f"{filename}_metadata.json")
        with open(metadata_path, 'w') as f:
            json.dump(metadata_with_file, f, indent=2)

        logging.info(f"Screenshot stored locally: {filename}.jpg ({len(image_bytes)} bytes)")

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
        # Auto-detect IP address if not provided or if it's a placeholder
        provided_ip = client_info.get('ip_address', '')
        if not provided_ip or provided_ip in ['192.168.1.100', '127.0.0.1', 'localhost', 'auto-detect']:
            detected_ip = self.get_real_ip_address()
            client_info['ip_address'] = detected_ip
            logging.info(f"Auto-detected IP address: {detected_ip}")
        else:
            logging.info(f"Using provided IP address: {provided_ip}")

        # Check if this is production server
        is_production = '103.129.149.67' in self.server_url

        if is_production:
            # Production API expects specific format
            production_data = {
                'client_id': client_info.get('client_id'),
                'hostname': client_info.get('hostname'),
                'ip_address': client_info.get('ip_address'),
                'username': client_info.get('username', client_info.get('user')),  # Use username field
                'timezone': client_info.get('timezone')
            }

            # Convert os_info to correct format expected by production
            os_info = client_info.get('os_info', client_info.get('os'))
            if isinstance(os_info, dict):
                # Keep as dict but with simple structure
                production_data['os_info'] = {
                    'name': os_info.get('name', ''),
                    'version': os_info.get('version', ''),
                    'architecture': os_info.get('architecture', '')
                }
            elif isinstance(os_info, str):
                # Convert string to dict
                parts = os_info.split(' ', 1)
                production_data['os_info'] = {
                    'name': parts[0] if len(parts) > 0 else 'Unknown',
                    'version': parts[1] if len(parts) > 1 else '',
                    'architecture': ''
                }
            else:
                production_data['os_info'] = {
                    'name': 'Unknown',
                    'version': '',
                    'architecture': ''
                }

            # Use production headers
            headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            }

            try:
                return self._make_request_with_headers('POST', '/api/clients/register', production_data, headers)
            except Exception as e:
                print(f"Production registration failed: {e}")
                raise
        else:
            # Local development server
            try:
                return self._make_request('POST', '/api/clients/register', client_info)
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
