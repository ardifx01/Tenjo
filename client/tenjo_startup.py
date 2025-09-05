#!/usr/bin/env python3
"""
Tenjo Client Startup Wrapper
Handles dependencies and ensures robust startup
"""

import sys
import os
import time
import subprocess
import logging
from pathlib import Path

# Setup paths
SCRIPT_DIR = Path(__file__).parent
VENV_PYTHON = SCRIPT_DIR / '.venv' / 'bin' / 'python'
MAIN_SCRIPT = SCRIPT_DIR / 'main.py'
LOG_DIR = SCRIPT_DIR / 'logs'

# Ensure log directory exists
LOG_DIR.mkdir(exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_DIR / 'startup.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def wait_for_network():
    """Wait for network connectivity"""
    max_attempts = 30
    for attempt in range(max_attempts):
        try:
            import socket
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            logger.info("Network connectivity confirmed")
            return True
        except (socket.error, OSError):
            if attempt < max_attempts - 1:
                logger.info(f"Waiting for network... ({attempt + 1}/{max_attempts})")
                time.sleep(10)
            else:
                logger.warning("Network not available after waiting")
                return False
    return False

def check_dependencies():
    """Check if virtual environment and dependencies are available"""
    if not VENV_PYTHON.exists():
        logger.error(f"Virtual environment not found: {VENV_PYTHON}")
        return False
    
    if not MAIN_SCRIPT.exists():
        logger.error(f"Main script not found: {MAIN_SCRIPT}")
        return False
    
    # Test import of critical modules
    try:
        result = subprocess.run([
            str(VENV_PYTHON), '-c', 
            'import sys; sys.path.append("src"); from modules.screen_capture import ScreenCapture; print("OK")'
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            logger.info("Dependencies check passed")
            return True
        else:
            logger.error(f"Dependencies check failed: {result.stderr}")
            return False
    except Exception as e:
        logger.error(f"Error checking dependencies: {e}")
        return False

def main():
    logger.info("Tenjo Client starting up...")
    
    # Wait a bit for system to stabilize
    time.sleep(5)
    
    # Wait for network
    if not wait_for_network():
        logger.warning("Starting without network confirmation")
    
    # Check dependencies
    if not check_dependencies():
        logger.error("Dependency check failed, exiting")
        sys.exit(1)
    
    # Start main client
    logger.info("Starting Tenjo Client main process...")
    try:
        # Change to script directory
        os.chdir(SCRIPT_DIR)
        
        # Execute main script
        result = subprocess.run([str(VENV_PYTHON), str(MAIN_SCRIPT)], 
                              env=dict(os.environ, PYTHONPATH=str(SCRIPT_DIR / 'src')))
        
        logger.info(f"Main process exited with code: {result.returncode}")
        sys.exit(result.returncode)
        
    except Exception as e:
        logger.error(f"Error starting main process: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
