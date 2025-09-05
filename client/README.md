# Tenjo Client - Employee Monitoring Application

Cross-platform stealth employee monitoring client written in Python.

## Features

- **Stealth Operation**: Runs hidden from normal user view
- **Real-time Screen Streaming**: FFmpeg + WebRTC for live monitoring
- **Automated Screenshots**: Captures screen every 1 minute
- **Browser Activity Tracking**: Monitors browser usage and URLs
- **Process Monitoring**: Tracks application usage with psutil
- **Cross-platform**: Windows and macOS support

## Installation

### Automatic Installation (Recommended)

1. Download and run the installer:
```bash
# Download the installer
curl -O https://your-server.com/install.py

# Run installer
python3 install.py
```

2. Follow the setup prompts:
   - Enter your dashboard server URL
   - Enter your API key
   - Installer will handle the rest automatically

### Manual Installation

1. Clone or download the client files
2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure the client by editing `src/core/config.py`:
```python
self.server_url = 'https://your-dashboard-url.com'
self.api_key = 'your-api-key-here'
```

4. Run the client:
```bash
python main.py
```

## System Requirements

- Python 3.7 or higher
- Internet connection
- FFmpeg (optional, for streaming)

### Platform-specific Requirements

**Windows:**
- Windows 7 or higher
- Python packages: `pygetwindow`, `pywin32`, `wmi`

**macOS:**
- macOS 10.12 or higher
- Python packages: `pyobjc-framework-Quartz`, `pyobjc-framework-AppKit`

## Dependencies

- `requests` - HTTP API communication
- `websocket-client` - WebSocket for streaming
- `psutil` - Process monitoring
- `mss` - Screenshot capture
- `Pillow` - Image processing
- `opencv-python` - Video processing
- `schedule` - Task scheduling
- `cryptography` - Security features

## Configuration

The client configuration is stored in `src/core/config.py`:

```python
class Config:
    def __init__(self):
        self.server_url = 'https://your-dashboard.com'
        self.api_key = 'your-api-key'
        self.screenshot_interval = 60  # seconds
        self.upload_batch_size = 10
        self.max_retries = 3
```

## Features Details

### Screenshot Capture
- Captures full screen every 1 minute
- Compresses images to reduce bandwidth
- Uploads to dashboard automatically

### Browser Monitoring
- Tracks browser start/stop times
- Monitors URL access and duration
- Supports Chrome, Firefox, Safari, Edge, Opera

### Process Monitoring
- Monitors application usage
- Tracks CPU and memory usage
- Records application start/stop times

### Real-time Streaming
- Uses FFmpeg for screen capture
- WebRTC for low-latency streaming
- Configurable quality settings (low/medium/high)

### Stealth Features
- Runs as system service
- Hidden installation directory
- Minimal system footprint
- Auto-start on boot

## API Endpoints

The client communicates with these dashboard endpoints:

- `POST /api/clients/register` - Register client
- `POST /api/clients/heartbeat` - Send heartbeat
- `POST /api/screenshots` - Upload screenshots
- `POST /api/browser-events` - Send browser activity
- `POST /api/process-events` - Send process data
- `POST /api/url-events` - Send URL access data
- `GET /api/stream/requests` - Check for stream requests
- `GET /api/stream/websocket-url` - Get WebSocket URL

## Security

- All communications use HTTPS
- API key authentication
- Data encryption in transit
- No sensitive data stored locally

## Uninstallation

To remove the client:

1. Stop the service:
   - Windows: Remove from startup registry
   - macOS: Unload Launch Agent
   - Linux: Stop systemd service

2. Remove installation directory:
   - Windows: `%APPDATA%\.system_cache`
   - macOS/Linux: `~/.system_cache`

## Troubleshooting

### Client won't start
- Check Python installation
- Verify all dependencies are installed
- Check API key and server URL
- Review log files in the logs directory

### Screenshots not uploading
- Check internet connection
- Verify API key is correct
- Check server endpoint availability

### Streaming not working
- Ensure FFmpeg is installed
- Check firewall settings
- Verify WebSocket connection

### High CPU usage
- Reduce screenshot frequency
- Lower streaming quality
- Check for conflicting software

## Logs

Log files are stored in:
- Windows: `%APPDATA%\.system_cache\logs\`
- macOS/Linux: `~/.system_cache/logs/`

## Development

### Running in Development Mode

1. Set environment variables:
```bash
export TENJO_SERVER_URL=http://localhost:8000
export TENJO_API_KEY=dev-api-key
```

2. Run the client:
```bash
python main.py
```

### Building Executable

To create standalone executable:

```bash
# Install PyInstaller
pip install pyinstaller

# Build executable
pyinstaller --onefile --noconsole --hidden-import=PIL --hidden-import=mss main.py
```

## License

This software is for authorized use only. Ensure compliance with local laws and regulations regarding employee monitoring.

## Support

For technical support, contact your system administrator or refer to the dashboard documentation.
