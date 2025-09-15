# Production Server Testing Guide via Termius

## Overview
Panduan ini akan membantu Anda menguji server production (103.129.149.67) menggunakan Termius untuk memverifikasi:
- Video chunks sudah diterima server
- Video chunks tersimpan dengan benar
- Streaming endpoints berfungsi
- Cache dan storage status

## Prerequisites
- **Termius App** installed (iOS/Android/Desktop)
- **SSH Access** ke server production (103.129.149.67)
- **Laravel Application** running di server

## 📱 **Step 1: Connect to Production Server**

### Via Termius
```bash
# Server Details
Host: 103.129.149.67
Username: [your_username]
Password: [your_password]
Port: 22 (default)
```

### SSH Command (Alternative)
```bash
ssh username@103.129.149.67
```

## 🔍 **Step 2: Navigate to Laravel Application**

```bash
# Navigate to Laravel app directory
cd /path/to/laravel/app  # Adjust path sesuai server setup

# Check Laravel app status
php artisan --version
php artisan route:list | grep stream
```

## 📊 **Step 3: Check Video Chunks Storage**

### **3.1 Check Laravel Cache (Redis/File)**
```bash
# If using Redis
redis-cli
> keys "*chunk*"
> keys "*latest_chunk*"
> get "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73"
> exit

# If using File Cache
find storage/framework/cache -name "*chunk*" -type f
find storage/framework/cache -name "*latest*" -type f
```

### **3.2 Check File Storage**
```bash
# Check storage directories
ls -la storage/app/
ls -la storage/app/public/
ls -la storage/app/streams/
ls -la storage/app/video_chunks/

# Check recent files
find storage/app -name "*.mp4" -o -name "*.ts" -o -name "*.chunk" | head -20
find storage/app -type f -mmin -60  # Files modified in last 60 minutes
```

### **3.3 Check Logs for Video Activity**
```bash
# Check Laravel logs
tail -f storage/logs/laravel.log | grep -i "chunk\|stream\|video"

# Check recent log entries
tail -100 storage/logs/laravel.log | grep -E "(chunk|stream|video|upload)"

# Check specific client activity
tail -100 storage/logs/laravel.log | grep "33ba500a-fdea-6619-b1e7-0ede2979bd73"
```

## 🌐 **Step 4: Test API Endpoints**

### **4.1 Test Stream Endpoints**
```bash
# Test heartbeat
curl -X GET "http://localhost/api/heartbeat"

# Test stream chunk endpoint
curl -X GET "http://localhost/api/stream/chunk/33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Test latest chunk endpoint  
curl -X GET "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Test with verbose output
curl -v "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73"
```

### **4.2 Test HLS Endpoints**
```bash
# Test HLS playlist
curl -X GET "http://localhost/api/stream/hls-playlist/33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Test HLS segments
curl -I "http://localhost/api/stream/hls-segment/33ba500a-fdea-6619-b1e7-0ede2979bd73/segment_001.ts"
```

## 🔧 **Step 5: Laravel Artisan Commands**

### **5.1 Check Application Status**
```bash
# Check app configuration
php artisan config:show

# Check cache status
php artisan cache:show

# Check routes
php artisan route:list | grep -E "(stream|chunk|hls)"
```

### **5.2 Debug Commands**
```bash
# Clear caches if needed
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Check queue status (if using queues)
php artisan queue:work --once
php artisan queue:failed
```

## 📈 **Step 6: Real-time Monitoring**

### **6.1 Monitor Live Activity**
```bash
# Monitor all logs in real-time
tail -f storage/logs/laravel.log | grep --color=always -E "(chunk|stream|video|POST|GET)"

# Monitor cache activity (Redis)
redis-cli monitor | grep chunk

# Monitor file system activity
watch "find storage/app -type f -mmin -5 | wc -l"
```

### **6.2 Network Activity**
```bash
# Monitor network connections
netstat -tulpn | grep :80
netstat -tulpn | grep :8000

# Check active processes
ps aux | grep -E "(php|nginx|apache)"
```

## 🧪 **Step 7: Debugging Specific Issues**

### **7.1 If No Video Chunks Found**
```bash
# Check if uploads are reaching server
grep -r "uploadStreamChunk" storage/logs/laravel.log
grep -r "stream/chunk" storage/logs/laravel.log

# Check Laravel error logs
grep -r "ERROR" storage/logs/laravel.log | tail -20

# Check web server logs
tail -f /var/log/nginx/access.log | grep stream
tail -f /var/log/apache2/access.log | grep stream
```

### **7.2 If Video Chunks Not Saving**
```bash
# Check storage permissions
ls -la storage/app/
chmod -R 755 storage/
chown -R www-data:www-data storage/

# Check disk space
df -h
du -sh storage/app/
```

### **7.3 Performance Issues**
```bash
# Check system resources
top
htop
free -h
iostat 1 5
```

## 📋 **Step 8: Useful One-liner Commands**

### **Quick Status Check**
```bash
# All-in-one status check
echo "=== Laravel Status ===" && php artisan --version && \
echo "=== Recent Chunks ===" && find storage/app -name "*chunk*" -mmin -30 | wc -l && \
echo "=== Cache Keys ===" && redis-cli keys "*chunk*" | wc -l && \
echo "=== Recent Logs ===" && tail -5 storage/logs/laravel.log
```

### **Client Specific Check**
```bash
CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"
echo "=== Client $CLIENT_ID Status ===" && \
curl -s "http://localhost/api/stream/latest/$CLIENT_ID" | head -50 && \
echo -e "\n=== Recent Activity ===" && \
grep "$CLIENT_ID" storage/logs/laravel.log | tail -5
```

### **Storage Summary**
```bash
echo "=== Storage Summary ===" && \
echo "Total files: $(find storage/app -type f | wc -l)" && \
echo "Recent files (5min): $(find storage/app -type f -mmin -5 | wc -l)" && \
echo "Video files: $(find storage/app -name "*.mp4" -o -name "*.ts" | wc -l)" && \
echo "Storage size: $(du -sh storage/app/)"
```

## 🎯 **Expected Results**

### **Success Indicators:**
- ✅ **Video chunks found** in cache atau storage
- ✅ **API endpoints return 200** dengan data
- ✅ **Recent log entries** showing chunk uploads
- ✅ **Storage files updated** dalam last few minutes

### **Failure Indicators:**
- ❌ **No chunk data** in cache/storage
- ❌ **API returns 404/500** errors
- ❌ **No recent log activity** untuk client
- ❌ **Storage not updated** for extended time

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: No Video Chunks**
```bash
# Check if client is sending data
grep "POST.*stream.*chunk" storage/logs/laravel.log | tail -10

# Check Laravel routes
php artisan route:list | grep chunk
```

### **Issue 2: Chunks Not Persisting**
```bash
# Check cache driver
grep "CACHE_DRIVER" .env
php artisan config:show cache

# Test cache manually
php artisan tinker
> Cache::put('test', 'value', 60);
> Cache::get('test');
```

### **Issue 3: Permission Issues**
```bash
# Fix storage permissions
sudo chown -R www-data:www-data storage/
sudo chmod -R 755 storage/
```

## 📱 **Termius Tips**

### **Create Saved Commands**
Save frequently used commands in Termius:
- `production-status`: Quick status check
- `check-chunks`: Video chunk verification
- `monitor-logs`: Real-time log monitoring

### **Port Forwarding** (if needed)
```bash
# Forward local port to server
ssh -L 8080:localhost:80 username@103.129.149.67
```

### **File Transfer**
```bash
# Download logs for analysis
scp username@103.129.149.67:/path/to/logs/* ./local-logs/
```

Gunakan panduan ini step-by-step untuk memverifikasi status video chunks di production server! 🚀
