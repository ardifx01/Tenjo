# Screen capture module using mss library

import mss
import time
import threading
import base64
import io
from PIL import Image
from datetime import datetime
import logging
import sys
import os

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from core.config import Config

class ScreenCapture:
    def __init__(self, api_client=None):
        self.api_client = api_client
        self.is_running = False
        self.capture_interval = 60  # 1 minute
        
    def start_capture(self):
        """Start screenshot capture loop"""
        self.is_running = True
        logging.info("Screenshot capture started")
        
        while self.is_running:
            try:
                self.capture_screenshot()
                time.sleep(self.capture_interval)
            except Exception as e:
                logging.error(f"Screenshot capture error: {str(e)}")
                time.sleep(5)  # Wait before retry
                
    def capture_screenshot(self):
        """Capture and send screenshot"""
        try:
            with mss.mss() as sct:
                # Capture all monitors
                monitors = sct.monitors[1:]  # Skip the first monitor (all monitors combined)
                
                for i, monitor in enumerate(monitors):
                    # Capture screenshot
                    screenshot = sct.grab(monitor)
                    
                    # Convert to PIL Image
                    img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
                    
                    # Compress and convert to base64
                    screenshot_data = self.compress_image(img)
                    
                    # Prepare metadata for production API
                    metadata = {
                        'client_id': Config.CLIENT_ID,
                        'resolution': f"{screenshot.width}x{screenshot.height}",
                        'timestamp': datetime.now().isoformat()
                    }
                    
                    # Send to server using production API
                    if self.api_client:
                        try:
                            response = self.api_client.upload_screenshot(screenshot_data, metadata)
                            if response and response.get('success'):
                                logging.info(f"Screenshot {i+1} uploaded successfully")
                            else:
                                logging.error(f"Failed to upload screenshot {i+1}")
                        except Exception as upload_error:
                            logging.error(f"Error uploading screenshot {i+1}: {str(upload_error)}")
                    
            logging.info("Screenshot capture cycle completed")
            return True
            
        except Exception as e:
            logging.error(f"Error capturing screenshot: {str(e)}")
            return False
            
    def compress_image(self, img, quality=85, max_size=(1920, 1080)):
        """Compress image to reduce file size"""
        # Resize if too large
        if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Convert to JPEG and compress
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG', quality=quality, optimize=True)
        
        # Convert to base64
        image_data = base64.b64encode(buffer.getvalue()).decode('utf-8')
        return image_data
        
    def stop_capture(self):
        """Stop screenshot capture"""
        self.is_running = False
        logging.info("Screenshot capture stopped")
        
    def capture_and_upload(self):
        """Single screenshot capture and upload for testing"""
        return self.capture_screenshot()
