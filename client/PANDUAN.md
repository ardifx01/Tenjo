# Tenjo Client - Panduan Lengkap

## 🚀 Status Instalasi Sukses!

Tenjo Client telah berhasil diinstal di MacBook Anda dengan konfigurasi persistent untuk auto-start.

## 📋 Informasi Sistem

- **Hostname**: Yayasans-MacBook-Air.local
- **Username**: yapi
- **Install Path**: `/Users/yapi/Adi/App-Dev/Tenjo/client`
- **Service Name**: `com.tenjo.client.persistent`
- **Dashboard URL**: http://127.0.0.1:8001

## 🔧 Manajemen Service

### Quick Commands (Menggunakan tenjo.sh)

```bash
# Cek status service
./tenjo.sh status

# Start monitoring
./tenjo.sh start

# Stop monitoring  
./tenjo.sh stop

# Restart service
./tenjo.sh restart

# Lihat logs real-time
./tenjo.sh logs service

# Test functionality
./tenjo.sh test
```

### Manual Commands (Menggunakan launchctl)

```bash
# Start service
launchctl start com.tenjo.client.persistent

# Stop service
launchctl stop com.tenjo.client.persistent

# Check if running
launchctl list | grep tenjo

# Reload service configuration
launchctl unload ~/Library/LaunchAgents/com.tenjo.client.persistent.plist
launchctl load ~/Library/LaunchAgents/com.tenjo.client.persistent.plist
```

## 📊 Fitur Monitoring

### ✅ Aktif
- **Screenshots**: Setiap 60 detik
- **Process Monitoring**: Setiap 45 detik  
- **Browser Activity**: Setiap 30 detik
- **Auto-restart**: Jika aplikasi crash
- **Auto-start**: Saat login

### ⚙️ Konfigurasi
File config: `src/core/config.py`
```python
SCREENSHOT_INTERVAL = 60  # detik
BROWSER_CHECK_INTERVAL = 30  # detik
PROCESS_CHECK_INTERVAL = 45  # detik
STEALTH_MODE = True
```

## 📁 Lokasi File

```
/Users/yapi/Adi/App-Dev/Tenjo/client/
├── main.py                     # Main client application
├── tenjo_startup.py           # Startup wrapper (auto-generated)
├── src/                       # Source modules
│   ├── core/config.py        # Configuration
│   ├── modules/              # Monitoring modules
│   └── utils/                # Utilities
├── logs/                     # Log files
│   ├── service.log          # Service output
│   ├── service_error.log    # Error logs
│   └── startup.log          # Startup logs
├── .venv/                    # Python virtual environment
└── management scripts:
    ├── tenjo.sh             # Service manager
    ├── setup_persistent_service.sh  # Setup auto-start
    ├── uninstall.sh         # Complete uninstaller
    ├── install_macbook.sh   # Original installer
    └── quick_install.sh     # Development installer
```

## 🔄 Auto-Start Behavior

### ✅ Service akan otomatis:
1. **Start saat login** - Mulai monitoring ketika Anda login
2. **Restart jika crash** - Auto-recovery jika aplikasi error
3. **Background running** - Berjalan di background tanpa mengganggu
4. **Survive reboot** - Melanjutkan monitoring setelah restart

### 🛡️ Stealth Mode
- Berjalan tersembunyi di background
- Tidak muncul di Dock atau menu bar
- Minimal CPU dan memory usage
- Log aktivitas untuk debugging

## 📊 Dashboard Monitoring

Buka browser dan akses: **http://127.0.0.1:8001**

### Yang bisa dilihat:
- ✅ Status client (Online/Offline)
- ✅ Screenshots real-time
- ✅ Browser activity
- ✅ Process monitoring
- ✅ URL access history

## 🚨 Troubleshooting

### Service tidak berjalan
```bash
# Cek status
./tenjo.sh status

# Cek error logs
./tenjo.sh logs error

# Restart service
./tenjo.sh restart
```

### Permission issues
```bash
# Grant macOS permissions:
System Preferences → Security & Privacy → Privacy
- Add Terminal to "Screen Recording"
- Add Terminal to "Accessibility"
```

### Reinstall jika ada masalah
```bash
# Uninstall completely
./uninstall.sh

# Reinstall
./install_macbook.sh
```

## 📱 Testing

### Manual test
```bash
# Test all modules
./tenjo.sh test

# Test screenshot only
source .venv/bin/activate
python -c "
import sys; sys.path.append('src')
from modules.screen_capture import ScreenCapture
sc = ScreenCapture()
print('Screenshot:', len(sc.capture_screenshot() or []), 'bytes')
"
```

## 🗑️ Uninstall

### Complete removal
```bash
./uninstall.sh
```

Ini akan menghapus:
- ✗ Service dan auto-start
- ✗ Virtual environment
- ✗ Application files (optional)
- ✗ Logs (dengan backup)

## 🔐 Security & Privacy

### Data yang dikumpulkan:
- Screenshots (setiap 60 detik)
- Active window titles
- Running processes
- Browser URLs and titles
- System information

### Data storage:
- **Local**: Logs dan cache di `/logs/` directory
- **Server**: Data dikirim ke dashboard lokal (127.0.0.1:8001)
- **Network**: Tidak ada data yang keluar dari laptop

### Permissions required:
- **Screen Recording**: Untuk screenshot
- **Accessibility**: Untuk window monitoring
- **Network**: Untuk komunikasi dengan dashboard lokal

## 📞 Support

### Log files untuk debugging:
```bash
# Service logs
tail -f logs/service.log

# Error logs  
tail -f logs/service_error.log

# Startup logs
tail -f logs/startup.log
```

### Manual run untuk debugging:
```bash
cd /Users/yapi/Adi/App-Dev/Tenjo/client
source .venv/bin/activate
python main.py
```

---

## ✅ Quick Start Checklist

- [x] ✅ Client installed and configured
- [x] ✅ Auto-start service setup
- [x] ✅ Persistent monitoring enabled
- [x] ✅ Dashboard accessible at http://127.0.0.1:8001
- [x] ✅ Management scripts available
- [x] ✅ Uninstaller ready

**Status**: 🟢 **ACTIVE & MONITORING**

Your MacBook is now being monitored 24/7 until shutdown! 🚀
