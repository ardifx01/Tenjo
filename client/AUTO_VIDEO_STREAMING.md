# Auto Video Streaming Feature

## Overview
Client sekarang dapat memulai video streaming secara otomatis tanpa menunggu request dari server. Fitur ini sangat berguna untuk deployment production dimana server mungkin tidak mengirim request streaming.

## How It Works

### 1. Configuration
- **Environment Variable**: `TENJO_AUTO_VIDEO=true` (default: true)
- **Config Setting**: `Config.AUTO_START_VIDEO_STREAMING`

### 2. Client Behavior
- **Auto Mode (default)**: Client langsung memulai video streaming saat startup
- **Traditional Mode**: Client menunggu request dari server sebelum memulai streaming

### 3. Implementation
- **main.py**: Menggunakan `start_auto_video_streaming()` jika auto mode enabled
- **stream_handler.py**: Memanggil `start_video_streaming()` langsung
- **Background**: Tetap monitoring server requests untuk kontrol tambahan

## Usage

### For Production (Auto Start)
```bash
export TENJO_AUTO_VIDEO=true
python3 main.py
```

### For Development (Wait for Server)
```bash
export TENJO_AUTO_VIDEO=false
python3 main.py
```

## Benefits
1. **Immediate Streaming**: Video streaming dimulai segera setelah client startup
2. **No Server Dependency**: Tidak perlu menunggu request dari server
3. **Production Ready**: Ideal untuk deployment production
4. **Backward Compatible**: Masih support traditional mode jika diperlukan

## Technical Details
- **Video Capture**: Menggunakan MSS library untuk reliability
- **Streaming Method**: Direct call to `start_video_streaming()`
- **Server Communication**: Background monitoring tetap aktif
- **Fallback**: Jika FFmpeg tidak tersedia, otomatis menggunakan MSS

## Testing
Run test dengan:
```bash
python3 test_auto_video.py
```
