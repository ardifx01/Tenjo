# 🚀 Tenjo Client - Manual Production Deployment Guide

Masalah saat ini: **Client production tidak menggunakan kode video streaming terbaru**

## Problem Diagnosis
✅ **Local video streaming working** - FFmpeg + MSS fallback  
✅ **Production server working** - dapat menerima video chunks  
✅ **Dashboard requesting stream** - quality: medium  
❌ **Production client not working** - kemungkinan kode lama atau tidak berjalan  

## Solution: Deploy Updated Client

### Step 1: Create Deployment Package
```bash
# Di local machine
cd /Users/yapi/Adi/App-Dev/Tenjo/client

# Create clean deployment package
tar -czf tenjo-client-latest.tar.gz \
    --exclude='logs/*' \
    --exclude='src/data/screenshots/*' \
    --exclude='src/data/hls/*' \
    --exclude='src/data/pending/*' \
    --exclude='**/__pycache__' \
    --exclude='.git*' \
    .

echo "✅ Deployment package created: tenjo-client-latest.tar.gz"
```

### Step 2: Upload to Production Server
```bash
# Upload via SCP (adjust username if needed)
scp tenjo-client-latest.tar.gz root@103.129.149.67:/tmp/

# Or use web upload if SCP not available
# Upload file via web interface/FTP to production server
```

### Step 3: Install on Production Server
SSH to production server and run:

```bash
# SSH to production
ssh root@103.129.149.67

# Stop existing client processes
pkill -f "python.*tenjo.*main.py" || true
pkill -f "python.*main.py.*stealth" || true
sleep 2

# Backup old installation
if [ -d "/opt/tenjo-client" ]; then
    mv /opt/tenjo-client /opt/tenjo-client.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ Old installation backed up"
fi

# Extract new version
cd /tmp
tar -xzf tenjo-client-latest.tar.gz
mv tenjo-client /opt/tenjo-client
cd /opt/tenjo-client

# Install dependencies
python3 -m pip install -r requirements.txt

# Verify config points to production
grep SERVER_URL src/core/config.py
# Should show: SERVER_URL = "http://103.129.149.67"

# Make executable
chmod +x main.py *.sh

echo "✅ Installation completed"
```

### Step 4: Create System Service
```bash
# Create systemd service file
cat > /etc/systemd/system/tenjo-client.service << 'EOF'
[Unit]
Description=Tenjo Client Monitoring Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tenjo-client
ExecStart=/usr/bin/python3 /opt/tenjo-client/main.py --stealth
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=PYTHONPATH=/opt/tenjo-client

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable tenjo-client
systemctl start tenjo-client

echo "✅ Service created and started"
```

### Step 5: Verify Installation
```bash
# Check service status
systemctl status tenjo-client

# Check service logs
journalctl -u tenjo-client -f -n 20

# Check if video streaming is working
# Look for logs like:
# "Starting video stream with quality: medium"
# "FFmpeg process started with PID: XXXX"
# "Video chunk N sent successfully"
```

### Step 6: Test Video Streaming
After 30 seconds, test from local machine:

```bash
# Test from local machine
curl -s "http://103.129.149.67/api/stream/latest/CLIENT_ID" | python3 -m json.tool

# Should show:
# {
#   "type": "video",
#   "data": "base64-video-data...",
#   "sequence": "N"
# }
```

## Troubleshooting

### If service fails to start:
```bash
# Check detailed logs
journalctl -u tenjo-client -n 50

# Check Python dependencies
python3 -c "import mss, PIL, requests; print('Dependencies OK')"

# Test manual run
cd /opt/tenjo-client
python3 main.py --stealth
```

### If still showing screenshots:
1. **Check client logs** for FFmpeg errors
2. **Verify MSS fallback** is working
3. **Restart service** to apply latest code

```bash
systemctl restart tenjo-client
journalctl -u tenjo-client -f
```

### If FFmpeg not available:
```bash
# Install FFmpeg on production
apt update && apt install -y ffmpeg

# Or client will auto-fallback to MSS
```

## Expected Results

After successful deployment:

✅ **Client running as system service**  
✅ **Auto-restart on failure**  
✅ **Video streaming with FFmpeg** (preferred)  
✅ **MSS fallback** if FFmpeg fails  
✅ **Dashboard shows live video** instead of screenshots  

## Service Management

```bash
# Start service
systemctl start tenjo-client

# Stop service  
systemctl stop tenjo-client

# Restart service
systemctl restart tenjo-client

# View logs
journalctl -u tenjo-client -f

# Check status
systemctl status tenjo-client
```

---

**Key Files Updated:**
- `stream_handler.py` - Fixed video_streaming flag initialization
- `main.py` - Uses updated StreamHandler
- `config.py` - Points to production server

**This deployment includes ALL video streaming fixes and should resolve the production issue.**
