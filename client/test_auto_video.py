#!/usr/bin/env python3
"""Test script for auto video streaming feature"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.config import Config

def test_auto_video_config():
    """Test auto video streaming configuration"""
    print("Testing Auto Video Streaming Configuration:")
    print(f"AUTO_START_VIDEO_STREAMING: {Config.AUTO_START_VIDEO_STREAMING}")
    print(f"CLIENT_ID: {Config.CLIENT_ID}")
    print(f"SERVER_URL: {Config.SERVER_URL}")
    
    # Test environment variable override
    os.environ['TENJO_AUTO_VIDEO'] = 'false'
    # Need to reload config for env var to take effect
    import importlib
    import core.config
    importlib.reload(core.config)
    from core.config import Config as ReloadedConfig
    
    print(f"\nAfter setting TENJO_AUTO_VIDEO=false:")
    print(f"AUTO_START_VIDEO_STREAMING: {ReloadedConfig.AUTO_START_VIDEO_STREAMING}")
    
    # Reset to true
    os.environ['TENJO_AUTO_VIDEO'] = 'true'
    importlib.reload(core.config)
    from core.config import Config as ResetConfig
    
    print(f"\nAfter setting TENJO_AUTO_VIDEO=true:")
    print(f"AUTO_START_VIDEO_STREAMING: {ResetConfig.AUTO_START_VIDEO_STREAMING}")

if __name__ == "__main__":
    test_auto_video_config()
