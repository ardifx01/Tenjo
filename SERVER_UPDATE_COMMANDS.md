# 🚨 **URGENT: API Routes Fix Required**

Client terdeteksi aktif tapi tidak ada screenshot/streaming karena API endpoints tidak ditemukan.

## SSH ke server dan jalankan commands berikut:

```bash
# SSH ke server
ssh root@103.129.149.67

# Update code dari GitHub (PENTING: Sudah ada fix API routes)
cd /var/www/Tenjo
git pull origin master

# Copy updated files to public downloads
cp client/simple_install_macos.sh dashboard/public/downloads/
cp client/easy_install_windows.bat dashboard/public/downloads/
cp client/quick_install_windows.bat dashboard/public/downloads/

# PENTING: Update default server URL di file installer yang sudah ada
sed -i 's/127.0.0.1:8000/103.129.149.67/g' dashboard/public/downloads/easy_install_macos.sh
sed -i 's/127.0.0.1:8000/103.129.149.67/g' dashboard/public/downloads/easy_install_windows.bat

# Make scripts executable
chmod +x dashboard/public/downloads/*.sh

# Set proper permissions
chown -R www-data:www-data dashboard/public/downloads

# CRITICAL: Clear Laravel caches to apply new API routes
cd dashboard
php artisan route:clear
php artisan config:clear  
php artisan cache:clear

# Restart services
systemctl restart nginx
systemctl restart php8.2-fpm
```

## Verify perubahan:

```bash
# Cek apakah IP sudah berubah
grep "103.129.149.67" dashboard/public/downloads/easy_install_macos.sh
grep "103.129.149.67" dashboard/public/downloads/easy_install_windows.bat
```

## Test setelah upload:

```bash
# Test dari komputer lokal
curl -I http://103.129.149.67/downloads/simple_install_macos.sh
curl -I http://103.129.149.67/downloads/quick_install_windows.bat

# Test download file
curl -s http://103.129.149.67/downloads/simple_install_macos.sh | head -5
```

## Commands instalasi yang sudah fixed:

**Windows:**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/easy_install_windows.bat' -OutFile 'tenjo.bat'; .\tenjo.bat"
```

**macOS (Simple - Recommended):**
```bash
curl -sSL http://103.129.149.67/downloads/simple_install_macos.sh | bash
```

**Windows (Quick backup):**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/quick_install_windows.bat' -OutFile 'tenjo_quick.bat'; .\tenjo_quick.bat"
```
