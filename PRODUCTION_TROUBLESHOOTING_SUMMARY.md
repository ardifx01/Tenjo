# PRODUCTION TROUBLESHOOTING SUMMARY

## 🔍 **Issue Analysis**

Berdasarkan testing production server via Termius, ditemukan:

### ❌ **Critical Issues:**
1. **Redis tidak terinstall** - `redis-cli` command not found
2. **Tidak ada video chunks** - storage/app/video_chunks/ directory tidak ada
3. **Client mengirim screenshots** - hanya storage/app/public/screenshots/ yang terisi
4. **Cache kosong** - tidak ada chunk data di cache

### ✅ **Working Components:**
1. **Laravel routes** - semua /api/stream/* endpoints tersedia
2. **Screenshots upload** - client bisa upload screenshots
3. **Web server** - HTTP responses working
4. **Storage permissions** - www-data ownership correct

## 🛠️ **Root Cause**

**Primary Issue:** Client tidak mengirim video chunks karena:
- Environment variable `TENJO_AUTO_VIDEO` tidak di-set di production
- Redis cache tidak tersedia untuk menyimpan video chunks
- Client fallback ke screenshot mode

## 🚀 **Fix Implementation**

### **Server-Side Fix (Immediate - via Termius):**

#### **1. Install Redis:**
```bash
sudo apt update && sudo apt install -y redis-server redis-tools
sudo systemctl start redis-server && sudo systemctl enable redis-server
redis-cli ping  # Should return "PONG"
```

#### **2. Create Storage Directories:**
```bash
cd /var/www/Tenjo/dashboard
sudo mkdir -p storage/app/{streams,video_chunks,hls}
sudo chown -R www-data:www-data storage/app/
sudo chmod -R 755 storage/app/
```

#### **3. Configure Laravel for Redis:**
```bash
# Add to .env
echo -e "\nCACHE_DRIVER=redis\nREDIS_HOST=127.0.0.1\nREDIS_PASSWORD=null\nREDIS_PORT=6379" >> .env

# Clear cache
php artisan config:clear && php artisan cache:clear
```

#### **4. Test Configuration:**
```bash
# Test cache
php artisan tinker --execute="Cache::put('test', 'working', 60); echo Cache::get('test');"

# Test Redis
redis-cli set "test" "value" && redis-cli get "test"
```

### **Client-Side Fix (Remote Installation):**

#### **1. Ensure Auto Video Streaming:**
Client harus menggunakan updated remote installer dengan `TENJO_AUTO_VIDEO=true`:

```bash
# macOS
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_macos.sh | bash

# Windows  
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/client/remote_install_windows.bat' -OutFile '%TEMP%\install.bat' -UseBasicParsing; cmd /c '%TEMP%\install.bat'"
```

#### **2. Manual Client Fix (if accessible):**
```bash
export TENJO_AUTO_VIDEO=true
python3 main.py
```

## 📊 **Verification Commands**

### **Server-Side Verification:**
```bash
# Redis status
redis-cli ping && redis-cli info server | head -5

# Storage check
ls -la storage/app/ && find storage/app -type f -mmin -30 | wc -l

# API test
curl -s "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73" | wc -c

# Real-time monitoring
tail -f storage/logs/laravel.log | grep -E "(chunk|stream|video)"
```

### **Expected Results After Fix:**
```bash
# Redis working
redis-cli keys "*chunk*"  # Shows chunk cache keys

# Storage active  
ls -la storage/app/video_chunks/  # Contains video files

# API returning data
curl -s "http://localhost/api/stream/latest/CLIENT_ID" | wc -c  # > 1000 bytes

# Logs showing activity
grep "uploadStreamChunk\|uploadVideoChunk" storage/logs/laravel.log | tail -5
```

## 🎯 **Timeline Expectations**

### **Phase 1: Server Fix (0-10 minutes)**
- ✅ Install Redis
- ✅ Configure Laravel  
- ✅ Create directories
- ✅ Test cache functionality

### **Phase 2: Client Update (10-20 minutes)**
- 🔄 Install/restart client dengan auto video streaming
- 🔄 Client connects dengan `TENJO_AUTO_VIDEO=true`
- 🔄 Video chunks mulai dikirim ke server

### **Phase 3: Verification (20-30 minutes)**
- ✅ Redis cache shows chunk data
- ✅ Storage contains video files
- ✅ Dashboard shows video instead of screenshots
- ✅ Real-time streaming active

## 🚨 **Emergency Commands**

### **If Still No Video Chunks After Fix:**
```bash
# Check client connection
grep "33ba500a-fdea-6619-b1e7-0ede2979bd73" storage/logs/laravel.log | tail -10

# Check upload attempts
grep -E "(POST.*stream|uploadStreamChunk|uploadVideoChunk)" storage/logs/laravel.log | tail -10

# Manual cache test
redis-cli set "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73" "test_data"
curl "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73"
```

### **Performance Issues:**
```bash
# Check system resources
df -h && free -h && top -n 1

# Redis performance
redis-cli info memory && redis-cli info stats

# Laravel performance
php artisan route:cache && php artisan config:cache
```

## 📱 **Termius Ready Commands**

### **One-Liner Complete Fix:**
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/production_auto_fix.sh | sudo bash
```

### **Quick Status Check:**
```bash
echo "Redis:" && redis-cli ping && echo "Storage:" && find storage/app -type f -mmin -10 | wc -l && echo "API:" && curl -s -o /dev/null -w "%{http_code}" "http://localhost/api/heartbeat"
```

### **Real-time Monitor:**
```bash
watch -n 5 'echo "=== $(date) ==="; redis-cli keys "*chunk*" | wc -l; find storage/app -name "*.chunk" | wc -l; tail -2 storage/logs/laravel.log'
```

## ✅ **Success Criteria**

### **Server Fixed When:**
- ✅ `redis-cli ping` returns "PONG"
- ✅ `redis-cli keys "*chunk*"` shows data (after client connects)
- ✅ `storage/app/video_chunks/` directory exists dan contains files
- ✅ API endpoints return video data instead of empty responses
- ✅ Logs show "uploadStreamChunk" atau "uploadVideoChunk" activity

### **Client Fixed When:**
- ✅ Dashboard shows live video instead of static screenshots
- ✅ Video streaming is smooth dan real-time
- ✅ No fallback to screenshot mode

Production server sekarang siap untuk video streaming dengan fix yang telah disiapkan! 🚀

Jalankan auto-fix script atau gunakan manual commands untuk memperbaiki production server.
