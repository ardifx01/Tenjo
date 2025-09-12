# Tenjo - Employee Monitoring System

> **⚠️ PENTING**: Aplikasi ini hanya untuk penggunaan yang sah dan sesuai dengan hukum yang berlaku. Pastikan Anda memiliki izin dari karyawan dan mematuhi regulasi privasi yang berlaku di wilayah Anda.

Tenjo adalah sistem monitoring karyawan yang terdiri dari:
- **Python Client**: Aplikasi stealth untuk monitoring komputer karyawan
- **Laravel Dashboard**: Interface web untuk melihat dan mengelola data monitoring

## ✨ Fitur Utama

### Python Client
- 🔒 **Stealth Operation**: Berjalan tersembunyi dari pengguna
- 📸 **Auto Screenshots**: Tangkap layar setiap 1 menit
- 🌐 **Browser Monitoring**: Pantau aktivitas browser dan URL
- 💻 **Process Monitoring**: Lacak aplikasi yang berjalan
- 📡 **Real-time Streaming**: Streaming layar live dengan FFmpeg + WebRTC
- 🔄 **Cross-platform**: Windows dan macOS support
- 🚀 **Easy Installation**: Install dengan satu perintah

### Laravel Dashboard
- 📊 **Dashboard Overview**: Lihat semua client yang terhubung
- 🎥 **Live Streaming**: Monitoring real-time layar karyawan
- 📱 **Client Details**: Detail lengkap aktivitas setiap client
- 📈 **Statistics**: Analisis penggunaan browser dan aplikasi
- 🕐 **History**: Riwayat aktivitas yang dapat difilter
- 📄 **Export Reports**: Laporan dalam format PDF
- ⏰ **Timezone**: Asia/Jakarta (dapat dikustomisasi)

## 🏗️ Arsitektur Sistem

```
┌─────────────────┐    HTTP/WebSocket    ┌──────────────────┐
│   Python Client │ ←→ ←→ ←→ ←→ ←→ ←→ ←→ │ Laravel Dashboard │
│                 │                      │                  │
│ • Screenshots   │                      │ • Web Interface  │
│ • Browser Track │                      │ • API Endpoints  │
│ • Process Mon   │                      │ • Live Streaming │
│ • Streaming     │                      │ • Reports        │
└─────────────────┘                      └──────────────────┘
```

## 🚀 Quick Start

### 1. Setup Laravel Dashboard

```bash
cd dashboard

# Install dependencies
composer install

# Setup environment
cp .env.example .env
php artisan key:generate

# Setup database
php artisan migrate

# Start server
php artisan serve
```

### 2. Install Python Client

**Otomatis (Recommended):**
```bash
cd client
python3 install.py
```

**Manual:**
```bash
cd client
pip install -r requirements.txt
python main.py
```

### 3. Konfigurasi

Edit `client/src/core/config.py`:
```python
self.server_url = 'http://103.129.149.67'  # URL dashboard Anda
self.api_key = 'your-api-key-here'         # API key untuk autentikasi
```

## 📋 System Requirements

### Client (Python)
- Python 3.7+
- Windows 7+ atau macOS 10.12+
- Koneksi internet
- FFmpeg (opsional, untuk streaming)

### Dashboard (Laravel)
- PHP 8.1+
- Composer
- MySQL/PostgreSQL/SQLite
- Web server (Apache/Nginx)

## 🔧 Instalasi Detail

### Client Dependencies
```bash
# Core packages
pip install requests websocket-client psutil mss Pillow

# Windows specific
pip install pygetwindow pywin32 wmi

# macOS specific  
pip install pyobjc-framework-Quartz pyobjc-framework-AppKit
```

### Laravel Setup
```bash
# Install Laravel dependencies
composer install

# Setup database
php artisan migrate

# Create storage link
php artisan storage:link

# Install API routes (jika belum ada)
php artisan install:api
```

## 📡 API Endpoints

### Client Registration
```http
POST /api/clients/register
Content-Type: application/json

{
  "hostname": "DESKTOP-ABC123",
  "ip_address": "192.168.1.100", 
  "user": "john.doe",
  "os": {
    "system": "Windows",
    "release": "10",
    "version": "10.0.19042"
  },
  "timezone": "Asia/Jakarta"
}
```

### Screenshots
```http
POST /api/screenshots
Content-Type: application/json

{
  "client_id": "uuid-client-id",
  "image_data": "base64-encoded-image",
  "resolution": "1920x1080",
  "monitor": 1,
  "timestamp": "2025-09-04T19:30:00+07:00"
}
```

### Browser Events
```http
POST /api/browser-events
Content-Type: application/json

{
  "client_id": "uuid-client-id",
  "event_type": "browser_started",
  "browser_name": "Chrome",
  "timestamp": "2025-09-04T19:30:00+07:00"
}
```

## 🎛️ Dashboard Interface

### Main Dashboard
- **Overview**: Statistics dan status semua client
- **Client Cards**: Info setiap client dengan tombol Live dan Details
- **Real-time Updates**: Auto-refresh setiap 30 detik

### Client Details
- **Client Info**: Hostname, user, OS, status
- **Activity Summary**: Screenshots, browser sessions, URLs
- **Browser Usage**: Chart penggunaan browser
- **Screenshots Grid**: Thumbnail screenshots hari ini
- **Top URLs**: URL yang paling sering dikunjungi

### Live View
- **Real-time Streaming**: Stream layar live (WebRTC)
- **Quality Control**: Low/Medium/High quality
- **Stream Stats**: FPS, bitrate, latency
- **Quick Actions**: Screenshot, details, refresh

### History Activity
- **Filter Options**: Client, tanggal, jenis aktivitas
- **Export Reports**: Download laporan PDF
- **Activity Timeline**: Kronologi aktivitas lengkap

## 🔒 Keamanan & Privacy

### Data Security
- HTTPS untuk semua komunikasi
- API key authentication
- Data encrypted in transit
- No sensitive data stored locally pada client

### Privacy Compliance
- Pastikan izin dari karyawan
- Beri tahu tentang monitoring
- Patuhi regulasi lokal (GDPR, dll)
- Gunakan data hanya untuk tujuan bisnis yang sah

### Stealth Features
- Hidden installation directory
- Service/daemon integration
- Minimal system footprint
- No visible UI pada client

## 🛠️ Development

### Client Development
```bash
cd client

# Run in development mode
export TENJO_SERVER_URL=http://103.129.149.67
export TENJO_API_KEY=dev-key
python main.py
```

### Dashboard Development
```bash
cd dashboard

# Enable debug mode
APP_DEBUG=true php artisan serve

# Watch for file changes
npm run dev
```

### Building Executable
```bash
# Install PyInstaller
pip install pyinstaller

# Build standalone executable
pyinstaller --onefile --noconsole --name tenjo-client main.py
```

## 📊 Database Schema

### Clients Table
- `id`, `hostname`, `client_id`, `ip_address`
- `username`, `os_info`, `status`, `last_seen`

### Screenshots Table  
- `id`, `client_id`, `filename`, `file_path`
- `resolution`, `monitor`, `file_size`, `captured_at`

### Browser Events Table
- `id`, `client_id`, `event_type`, `browser_name`
- `start_time`, `end_time`, `duration`

### URL Events Table
- `id`, `client_id`, `event_type`, `url`
- `start_time`, `end_time`, `duration`, `page_title`

### Process Events Table
- `id`, `client_id`, `event_type`, `process_name`
- `process_pid`, `start_time`, `end_time`, `duration`

## 🐛 Troubleshooting

### Client tidak connect
- Cek koneksi internet
- Verifikasi server URL dan API key
- Periksa firewall settings
- Lihat log file di `.system_cache/logs/`

### Screenshots tidak upload
- Pastikan folder storage writable
- Cek ukuran file dan bandwidth
- Verifikasi API endpoint tersedia

### Streaming tidak jalan
- Install FFmpeg
- Cek port WebSocket (default 6001)
- Verifikasi codec video support

### Performance issues
- Kurangi frekuensi screenshot
- Turunkan kualitas streaming
- Optimasi database queries

## 📈 Monitoring & Maintenance

### Log Files
- Client logs: `~/.system_cache/logs/`
- Laravel logs: `storage/logs/laravel.log`

### Database Maintenance
```bash
# Clean old screenshots (older than 30 days)
php artisan db:cleanup --days=30

# Optimize database
php artisan db:optimize
```

### Performance Monitoring
- Monitor disk usage untuk screenshots
- Check database size growth
- Monitor network bandwidth usage

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## ⚖️ Legal Notice

**PENTING**: 
- Aplikasi ini hanya untuk penggunaan yang sah
- Dapatkan persetujuan eksplisit dari karyawan
- Patuhi hukum privacy dan monitoring di wilayah Anda
- Gunakan hanya untuk keperluan bisnis yang legitimate
- Implementasikan dengan kebijakan yang jelas

## 📄 License

Aplikasi ini untuk penggunaan internal perusahaan. Pastikan compliance dengan regulasi local sebelum deployment.

## 📞 Support

Untuk bantuan teknis:
- Baca documentation ini dengan lengkap
- Cek troubleshooting section
- Review log files untuk error details
- Contact system administrator

---

**Dibuat dengan ❤️ untuk monitoring karyawan yang aman dan legal**
