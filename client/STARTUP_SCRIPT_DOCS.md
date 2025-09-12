# Tenjo Startup Script Documentation

## 📁 **File: tenjo_startup.py**

Comprehensive startup script untuk Tenjo client dengan fitur:
- ✅ Service management 
- ✅ Stealth mode
- ✅ Signal handling
- ✅ Logging
- ✅ Configuration management

## 🚀 **Usage Examples:**

### **Basic Usage:**
```bash
# Start dengan default settings
python3 tenjo_startup.py

# Start dengan server URL custom
python3 tenjo_startup.py --server-url http://103.129.149.67

# Start tanpa stealth mode (for debugging)
python3 tenjo_startup.py --no-stealth
```

### **Service Management:**
```bash
# Install sebagai system service
python3 tenjo_startup.py --install-service

# Uninstall system service
python3 tenjo_startup.py --uninstall-service
```

### **Debug Mode:**
```bash
# Enable debug logging
python3 tenjo_startup.py --debug --no-stealth
```

## ⚙️ **Command Line Options:**

| Option | Description |
|--------|-------------|
| `--server-url, -s` | Server URL (default: from config) |
| `--no-stealth` | Disable stealth mode |
| `--install-service` | Install as system service |
| `--uninstall-service` | Uninstall system service |
| `--debug` | Enable debug logging |
| `--help, -h` | Show help message |

## 📋 **Features:**

### **1. Stealth Mode**
- Hide process from task manager
- Silent operation
- Auto-start configuration

### **2. Service Management**
- Cross-platform service installation
- LaunchAgent (macOS) / Service (Windows)
- Auto-restart capabilities

### **3. Signal Handling**
- Graceful shutdown on SIGINT/SIGTERM
- Cleanup resources
- Stop monitoring threads

### **4. Logging**
- Rotating log files
- Configurable log levels
- Silent mode support

### **5. Configuration**
- Command line arguments
- Environment variables
- Config file support

## 📁 **File Locations:**

### **macOS:**
```
~/.tenjo_client/
├── tenjo_startup.py         # Main startup script
├── main.py                  # Core client
├── start_tenjo.sh          # Shell wrapper
└── src/
    ├── logs/               # Log files
    └── ...                 # Other modules
```

### **LaunchAgent:**
```
~/Library/LaunchAgents/com.tenjo.client.plist
```

## 🔧 **Integration dengan Installer:**

Installer otomatis:
1. ✅ Copy `tenjo_startup.py` ke install directory
2. ✅ Create `start_tenjo.sh` wrapper
3. ✅ Setup LaunchAgent dengan startup script
4. ✅ Configure auto-start

## 📊 **Process Flow:**

```
tenjo_startup.py
├── Setup logging
├── Initialize stealth mode
├── Setup signal handlers
├── Create TenjoClient
├── Start monitoring threads
└── Keep alive loop
```

## 🛠️ **Troubleshooting:**

### **Check if running:**
```bash
ps aux | grep tenjo_startup
```

### **View logs:**
```bash
tail -f ~/.tenjo_client/src/logs/tenjo_startup_$(date +%Y%m%d).log
```

### **Manual start for debugging:**
```bash
cd ~/.tenjo_client
python3 tenjo_startup.py --no-stealth --debug
```

### **Service status:**
```bash
launchctl list | grep tenjo
```

## 🎯 **Advantages over main.py:**

1. **Better service management** - Cross-platform service installation
2. **Enhanced logging** - Dedicated startup logs
3. **Signal handling** - Graceful shutdown
4. **Stealth integration** - Built-in stealth mode
5. **Configuration flexibility** - Command line options
6. **Error recovery** - Better error handling

Perfect untuk production deployment! 🚀
