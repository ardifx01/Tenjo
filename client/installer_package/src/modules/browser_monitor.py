# Browser activity monitoring module

import time
import threading
import platform
import logging
import sys
import os
from datetime import datetime
import psutil

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from core.config import Config

# Global flag to track if we've already warned about missing modules
_modules_warning_shown = False

if platform.system() == 'Windows':
    try:
        import pygetwindow as gw
        import win32gui
        import win32process
        WINDOWS_AVAILABLE = True
    except ImportError:
        WINDOWS_AVAILABLE = False
        gw = None
        win32gui = None
        win32process = None
        if not _modules_warning_shown:
            logging.warning("Windows-specific modules not available")
            _modules_warning_shown = True
elif platform.system() == 'Darwin':
    try:
        from AppKit import NSWorkspace
        import Quartz
        MACOS_AVAILABLE = True
    except ImportError:
        MACOS_AVAILABLE = False
        NSWorkspace = None
        Quartz = None
        if not _modules_warning_shown:
            logging.warning("macOS-specific modules not available (install pyobjc for full functionality)")
            _modules_warning_shown = True
else:
    WINDOWS_AVAILABLE = False
    MACOS_AVAILABLE = False
    if not _modules_warning_shown:
        logging.info("Platform-specific window modules not needed")
        _modules_warning_shown = True

class BrowserMonitor:
    def __init__(self, api_client):
        self.api_client = api_client
        self.is_running = False
        self.browser_processes = {}
        self.active_tabs = {}
        self.check_interval = 5  # seconds

        # Browser process names
        self.browser_names = [
            'chrome.exe', 'firefox.exe', 'msedge.exe', 'opera.exe', 'safari.exe',
            'Chrome', 'Firefox', 'Safari', 'Opera', 'Microsoft Edge'
        ]

    def start_monitoring(self):
        """Start browser monitoring"""
        self.is_running = True
        logging.info("Browser monitoring started")

        while self.is_running:
            try:
                self.monitor_browsers()
                time.sleep(self.check_interval)
            except Exception as e:
                logging.error(f"Browser monitoring error: {str(e)}")
                time.sleep(5)

    def monitor_browsers(self):
        """Monitor browser activities"""
        current_time = datetime.now()

        # Get all running processes
        current_browsers = self.get_browser_processes()

        # Check for new browser sessions
        for browser_name, processes in current_browsers.items():
            if browser_name not in self.browser_processes:
                # New browser started
                self.browser_processes[browser_name] = {
                    'start_time': current_time,
                    'processes': processes,
                    'urls': {}
                }

                self.send_browser_event('browser_started', browser_name, current_time)

        # Check for closed browsers
        for browser_name in list(self.browser_processes.keys()):
            if browser_name not in current_browsers:
                # Browser closed
                end_time = current_time
                start_time = self.browser_processes[browser_name]['start_time']

                self.send_browser_event('browser_closed', browser_name, end_time, start_time)
                del self.browser_processes[browser_name]

        # Monitor active windows and URLs (simplified)
        active_window = self.get_active_window()
        if active_window and self.is_browser_window(active_window):
            self.monitor_browser_urls(active_window)

    def get_browser_processes(self):
        """Get all running browser processes"""
        browsers = {}

        try:
            for proc in psutil.process_iter(['pid', 'name']):
                proc_name = proc.info['name']
                if any(browser in proc_name for browser in self.browser_names):
                    browser_key = self.normalize_browser_name(proc_name)
                    if browser_key not in browsers:
                        browsers[browser_key] = []
                    browsers[browser_key].append(proc.info['pid'])
        except Exception as e:
            logging.error(f"Error getting browser processes: {str(e)}")

        return browsers

    def get_active_window(self):
        """Get active window information"""
        try:
            if platform.system() == 'Windows':
                return self.get_active_window_windows()
            elif platform.system() == 'Darwin':
                return self.get_active_window_macos()
        except Exception as e:
            logging.error(f"Error getting active window: {str(e)}")
            return None

    def get_active_window_windows(self):
        """Get active window on Windows"""
        if not WINDOWS_AVAILABLE or not win32gui:
            # Fallback to pygetwindow if win32gui not available
            try:
                if gw:
                    active = gw.getActiveWindow()
                    if active:
                        return {
                            'title': active.title,
                            'handle': None
                        }
            except Exception:
                pass
            return None

        try:
            hwnd = win32gui.GetForegroundWindow()
            window_title = win32gui.GetWindowText(hwnd)
            return {
                'title': window_title,
                'handle': hwnd
            }
        except Exception:
            # Fallback to pygetwindow
            try:
                if gw:
                    active = gw.getActiveWindow()
                    if active:
                        return {
                            'title': active.title,
                            'handle': None
                        }
            except Exception:
                pass
        return None

    def get_active_window_macos(self):
        """Get active window on macOS"""
        if not MACOS_AVAILABLE or not NSWorkspace:
            return None

        try:
            active_app = NSWorkspace.sharedWorkspace().activeApplication()
            return {
                'title': active_app.get('NSApplicationName', ''),
                'bundle_id': active_app.get('NSApplicationBundleIdentifier', '')
            }
        except Exception as e:
            logging.error(f"Error getting macOS active window: {str(e)}")
            return None

    def is_browser_window(self, window_info):
        """Check if window belongs to a browser"""
        if not window_info:
            return False

        title = window_info.get('title', '').lower()
        return any(browser.lower() in title for browser in ['chrome', 'firefox', 'safari', 'edge', 'opera'])

    def monitor_browser_urls(self, window_info):
        """Monitor URLs in browser (simplified approach)"""
        # Note: Actual URL extraction requires more advanced techniques
        # This is a simplified version that tracks window titles

        window_title = window_info.get('title', '')
        current_time = datetime.now()

        # Extract URL from window title (basic approach)
        url = self.extract_url_from_title(window_title)

        if url and url != self.active_tabs.get('current_url'):
            # URL changed
            if 'current_url' in self.active_tabs:
                # Send end time for previous URL
                self.send_url_event('url_closed', self.active_tabs['current_url'],
                                  current_time, self.active_tabs.get('start_time'))

            # Start tracking new URL
            self.active_tabs = {
                'current_url': url,
                'start_time': current_time
            }

            self.send_url_event('url_opened', url, current_time)

    def extract_url_from_title(self, title):
        """Extract URL from browser window title"""
        # Basic URL extraction from window title
        # This is a simplified approach - real implementation would need browser-specific APIs

        if not title:
            return None

        # Look for URL patterns in title
        import re
        url_pattern = r'https?://[^\s]+'
        urls = re.findall(url_pattern, title)

        if urls:
            return urls[0]

        # If no direct URL, use domain extraction
        if ' - ' in title:
            parts = title.split(' - ')
            if len(parts) >= 2:
                return parts[-1]  # Usually browser name is at the end

        return title

    def normalize_browser_name(self, proc_name):
        """Normalize browser process name"""
        name_mapping = {
            'chrome.exe': 'Chrome',
            'Chrome': 'Chrome',
            'firefox.exe': 'Firefox',
            'Firefox': 'Firefox',
            'msedge.exe': 'Microsoft Edge',
            'Microsoft Edge': 'Microsoft Edge',
            'safari.exe': 'Safari',
            'Safari': 'Safari',
            'opera.exe': 'Opera',
            'Opera': 'Opera'
        }

        for key, value in name_mapping.items():
            if key.lower() in proc_name.lower():
                return value

        return proc_name

    def send_browser_event(self, event_type, browser_name, timestamp, start_time=None):
        """Send browser event to server"""
        from datetime import datetime
        
        # Handle timestamp parameter - can be string, datetime, or float
        if isinstance(timestamp, str):
            formatted_timestamp = timestamp
        elif isinstance(timestamp, (int, float)):
            formatted_timestamp = datetime.fromtimestamp(timestamp).isoformat()
        else:
            formatted_timestamp = timestamp.isoformat()
            
        data = {
            'client_id': Config.CLIENT_ID,
            'event_type': event_type,
            'browser_name': browser_name,
            'timestamp': formatted_timestamp,
        }

        if start_time:
            if isinstance(start_time, str):
                data['start_time'] = start_time
            elif isinstance(start_time, (int, float)):
                data['start_time'] = datetime.fromtimestamp(start_time).isoformat()
            else:
                data['start_time'] = start_time.isoformat()
                
            if not isinstance(timestamp, str) and not isinstance(start_time, str):
                try:
                    data['duration'] = int((timestamp - start_time).total_seconds())
                except:
                    data['duration'] = 0
            else:
                data['duration'] = 0

        try:
            response = self.api_client.post('/api/browser-events', data)
            if not response:
                logging.error(f"Failed to send browser event: {event_type} for {browser_name}")
            else:
                logging.debug(f"Browser event sent successfully: {event_type} for {browser_name}")
        except Exception as e:
            logging.error(f"Error sending browser event: {str(e)}")

    def send_url_event(self, event_type, url, timestamp, start_time=None):
        """Send URL event to server"""
        from datetime import datetime
        
        # Handle timestamp parameter - can be string, datetime, or float
        if isinstance(timestamp, str):
            formatted_timestamp = timestamp
        elif isinstance(timestamp, (int, float)):
            formatted_timestamp = datetime.fromtimestamp(timestamp).isoformat()
        else:
            formatted_timestamp = timestamp.isoformat()
            
        data = {
            'client_id': Config.CLIENT_ID,
            'event_type': event_type,
            'url': url,
            'timestamp': formatted_timestamp,
        }

        if start_time:
            if isinstance(start_time, str):
                data['start_time'] = start_time
            elif isinstance(start_time, (int, float)):
                data['start_time'] = datetime.fromtimestamp(start_time).isoformat()
            else:
                data['start_time'] = start_time.isoformat()
                
            if not isinstance(timestamp, str) and not isinstance(start_time, str):
                try:
                    data['duration'] = int((timestamp - start_time).total_seconds())
                except:
                    data['duration'] = 0
            else:
                data['duration'] = 0

        try:
            response = self.api_client.post('/api/url-events', data)
            if not response:
                logging.error(f"Failed to send URL event: {event_type} for {url}")
            else:
                logging.debug(f"URL event sent successfully: {event_type} for {url}")
        except Exception as e:
            logging.error(f"Error sending URL event: {str(e)}")

    def stop_monitoring(self):
        """Stop browser monitoring"""
        self.is_running = False
        logging.info("Browser monitoring stopped")

    def get_browser_info(self):
        """Get current browser information for testing"""
        try:
            browser_data = []
            processes = self.get_browser_processes()

            for process_name, process_info in processes.items():
                browser_data.append({
                    'process_name': process_name,
                    'pid': process_info.get('pid'),
                    'active': True,
                    'timestamp': datetime.now().isoformat()
                })

            return browser_data
        except Exception as e:
            logging.error(f"Error getting browser info: {e}")
            return []
