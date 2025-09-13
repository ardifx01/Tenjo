# Remote Installer Production Update

## Overview
Remote installer scripts telah diupdate untuk mendukung **Auto Video Streaming** di production. Client akan langsung memulai video streaming saat startup tanpa menunggu request dari server.

## Changes Made

### 🍎 macOS (`remote_install_macos.sh`)

#### 1. **Configuration Updates**
- **Environment Variables**: Automatically set `TENJO_AUTO_VIDEO=true`
- **Profile Updates**: Added to `.bash_profile` and `.zshrc` untuk persistent environment
- **Production Ready**: Default configuration untuk immediate video streaming

#### 2. **Launch Agent (plist) Updates**
- **Environment Variables**: Added `TENJO_AUTO_VIDEO=true` ke LaunchAgent
- **Server Configuration**: Added `TENJO_SERVER_URL` dan `TENJO_API_KEY`
- **Automatic Startup**: Client akan start dengan auto video streaming enabled

#### 3. **Startup Process**
- **Immediate Video**: Export environment variables sebelum start client
- **Background Process**: Menggunakan nohup dengan auto video streaming
- **Configuration Test**: Display auto video streaming status

### 🪟 Windows (`remote_install_windows.bat`)

#### 1. **Environment Variables**
- **System Level**: `setx TENJO_AUTO_VIDEO "true"` untuk persistent setting
- **Session Level**: `set "TENJO_AUTO_VIDEO=true"` untuk immediate use
- **Production Config**: Automatic setup untuk production deployment

#### 2. **Scheduled Task Updates**
- **Wrapper Script**: Created `start_tenjo.bat` dengan environment variables
- **Auto Video**: Task scheduler menggunakan wrapper dengan auto video enabled
- **Service Mode**: Client runs as service dengan auto video streaming

#### 3. **Immediate Startup**
- **Environment Setup**: Set variables sebelum start client
- **Background Process**: Client starts dengan auto video streaming
- **Status Display**: Show auto video streaming configuration

## Key Features

### ✅ **Auto Video Streaming**
- **Immediate Start**: Client langsung mulai video streaming saat startup
- **No Server Dependency**: Tidak perlu menunggu request dari server
- **Production Ready**: Optimized untuk deployment production

### ✅ **Environment Configuration**
- **macOS**: Environment variables in shell profiles dan LaunchAgent
- **Windows**: System environment variables dan scheduled task
- **Persistent**: Settings survive system reboot

### ✅ **Service Integration**
- **macOS**: LaunchAgent dengan environment variables
- **Windows**: Scheduled Task dengan wrapper script
- **Auto Start**: Starts on system boot dengan auto video streaming

## Installation Commands

### macOS Production Install
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_macos.sh | bash
```

### Windows Production Install
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_windows.bat' -OutFile '%TEMP%\install.bat' -UseBasicParsing; cmd /c '%TEMP%\install.bat'; del '%TEMP%\install.bat'"
```

## Expected Behavior

### 🎯 **Production Deployment**
1. **Download**: Script downloads latest client dari GitHub
2. **Environment**: Set `TENJO_AUTO_VIDEO=true` automatically
3. **Installation**: Client installed dengan auto video streaming
4. **Service**: Auto-start service created dengan environment variables
5. **Video Streaming**: Client immediately starts video streaming
6. **Dashboard**: Video akan muncul di dashboard (bukan screenshots)

### 🔧 **Configuration Verification**
- **Auto Video**: `Config.AUTO_START_VIDEO_STREAMING = True`
- **Server URL**: `Config.SERVER_URL = "http://103.129.149.67"`
- **Client ID**: Unique hardware-based identifier
- **Streaming**: Video chunks sent to production server

## Benefits
- **Immediate Video**: No delay untuk video streaming
- **Production Ready**: Optimized untuk real deployment
- **Zero Config**: Client works out-of-the-box dengan video streaming
- **Reliable**: Uses existing tested video streaming infrastructure
- **Cross Platform**: Consistent behavior across macOS dan Windows

## Testing
After installation, verify:
```bash
# Check environment
echo $TENJO_AUTO_VIDEO  # Should show: true

# Check client process
ps aux | grep "python.*main.py"

# Check dashboard
# Should show video, not screenshots
```
