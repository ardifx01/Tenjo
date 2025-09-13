# Process monitoring module using psutil

import psutil
import time
import threading
import logging
import sys
import os
from datetime import datetime
from collections import defaultdict

# Add src to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from core.config import Config

class ProcessMonitor:
    def __init__(self, api_client):
        self.api_client = api_client
        self.is_running = False
        self.active_processes = {}
        self.check_interval = 10  # seconds
        
        # Applications we want to monitor
        self.monitored_apps = [
            # Browsers
            'chrome.exe', 'firefox.exe', 'msedge.exe', 'opera.exe', 'safari.exe',
            'Chrome', 'Firefox', 'Safari', 'Opera', 'Microsoft Edge',
            
            # Office applications
            'winword.exe', 'excel.exe', 'powerpnt.exe', 'outlook.exe',
            'Microsoft Word', 'Microsoft Excel', 'Microsoft PowerPoint', 'Microsoft Outlook',
            
            # Development tools
            'code.exe', 'devenv.exe', 'notepad++.exe', 'sublime_text.exe',
            'Visual Studio Code', 'Visual Studio', 'Sublime Text', 'PyCharm',
            
            # Media
            'vlc.exe', 'wmplayer.exe', 'spotify.exe',
            'VLC', 'Windows Media Player', 'Spotify',
            
            # Communication
            'discord.exe', 'slack.exe', 'teams.exe', 'zoom.exe',
            'Discord', 'Slack', 'Microsoft Teams', 'Zoom',
            
            # Other
            'notepad.exe', 'calc.exe', 'explorer.exe'
        ]
        
    def start_monitoring(self):
        """Start process monitoring"""
        self.is_running = True
        logging.info("Process monitoring started")
        
        while self.is_running:
            try:
                self.monitor_processes()
                time.sleep(self.check_interval)
            except Exception as e:
                logging.error(f"Process monitoring error: {str(e)}")
                time.sleep(5)
                
    def monitor_processes(self):
        """Monitor running processes"""
        current_time = datetime.now()
        current_processes = self.get_monitored_processes()
        
        # Check for new processes
        for proc_info in current_processes:
            proc_key = f"{proc_info['name']}_{proc_info['pid']}"
            
            if proc_key not in self.active_processes:
                # New process started
                self.active_processes[proc_key] = {
                    'name': proc_info['name'],
                    'pid': proc_info['pid'],
                    'start_time': current_time,
                    'cpu_times': proc_info.get('cpu_times', 0),
                    'memory_info': proc_info.get('memory_info', 0)
                }
                
                self.send_process_event('process_started', proc_info, current_time)
                
        # Check for ended processes
        active_pids = {proc['pid'] for proc in current_processes}
        
        for proc_key in list(self.active_processes.keys()):
            proc_pid = self.active_processes[proc_key]['pid']
            
            if proc_pid not in active_pids:
                # Process ended
                proc_info = self.active_processes[proc_key]
                start_time = proc_info['start_time']
                duration = (current_time - start_time).total_seconds()
                
                self.send_process_event('process_ended', proc_info, current_time, start_time, duration)
                del self.active_processes[proc_key]
                
        # Update process statistics
        self.update_process_stats(current_processes, current_time)
        
    def get_monitored_processes(self):
        """Get all monitored running processes"""
        processes = []
        
        try:
            for proc in psutil.process_iter(['pid', 'name', 'cpu_times', 'memory_info', 'create_time']):
                try:
                    proc_info = proc.info
                    proc_name = proc_info['name']
                    
                    if self.should_monitor_process(proc_name):
                        processes.append({
                            'pid': proc_info['pid'],
                            'name': proc_name,
                            'cpu_times': proc_info.get('cpu_times'),
                            'memory_info': proc_info.get('memory_info'),
                            'create_time': proc_info.get('create_time')
                        })
                        
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
                    
        except Exception as e:
            logging.error(f"Error getting processes: {str(e)}")
            
        return processes
        
    def should_monitor_process(self, proc_name):
        """Check if process should be monitored"""
        return any(app.lower() in proc_name.lower() or proc_name.lower() in app.lower() 
                  for app in self.monitored_apps)
        
    def update_process_stats(self, current_processes, timestamp):
        """Update process statistics"""
        stats_data = []
        
        for proc_info in current_processes:
            proc_key = f"{proc_info['name']}_{proc_info['pid']}"
            
            if proc_key in self.active_processes:
                stats = {
                    'pid': proc_info['pid'],
                    'name': proc_info['name'],
                    'timestamp': timestamp.isoformat(),
                    'cpu_times': proc_info.get('cpu_times'),
                    'memory_info': proc_info.get('memory_info')
                }
                stats_data.append(stats)
                
        if stats_data:
            # Send batch stats update
            self.api_client.post('/api/system-stats', {'stats': stats_data, 'client_id': Config.CLIENT_ID})
            
    def get_system_info(self):
        """Get system information"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            return {
                'cpu_percent': cpu_percent,
                'memory_total': memory.total,
                'memory_used': memory.used,
                'memory_percent': memory.percent,
                'disk_total': disk.total,
                'disk_used': disk.used,
                'disk_percent': (disk.used / disk.total) * 100
            }
        except Exception as e:
            logging.error(f"Error getting system info: {str(e)}")
            return {}
            
    def send_process_event(self, event_type, proc_info, timestamp, start_time=None, duration=None):
        """Send process event to server"""
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
            'process_name': proc_info['name'],
            'process_pid': proc_info['pid'],
            'timestamp': formatted_timestamp,
        }
        
        if start_time:
            if isinstance(start_time, str):
                data['start_time'] = start_time
            elif isinstance(start_time, (int, float)):
                data['start_time'] = datetime.fromtimestamp(start_time).isoformat()
            else:
                data['start_time'] = start_time.isoformat()
            
        if duration:
            data['duration'] = int(duration)  # Ensure integer
            
        # Add system info for process start events
        if event_type == 'process_started':
            data['system_info'] = self.get_system_info()
        else:
            data['system_info'] = {}  # Ensure system_info is always present
            
        try:
            response = self.api_client.post('/api/process-events', data)
            if not response:
                logging.error(f"Failed to send process event: {event_type} for {proc_info['name']}")
            else:
                logging.debug(f"Process event sent successfully: {event_type} for {proc_info['name']}")
        except Exception as e:
            logging.error(f"Error sending process event: {str(e)}")
        
    def stop_monitoring(self):
        """Stop process monitoring"""
        self.is_running = False
        logging.info("Process monitoring stopped")
        
    def get_processes(self):
        """Get current running processes for testing"""
        try:
            return self.get_monitored_processes()
        except Exception as e:
            logging.error(f"Error getting processes: {e}")
            return []
