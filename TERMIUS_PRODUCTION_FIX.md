# TERMIUS QUICK COMMANDS - Video Chunks Troubleshooting

## 🚨 **Current Issue: No Video Chunks Found**

Berdasarkan testing production, issues yang ditemukan:
- ❌ Redis tidak terinstall
- ❌ Tidak ada video chunks di storage  
- ❌ Client mengirim screenshots instead of video
- ✅ Laravel routes working
- ✅ Screenshots upload working

## ⚡ **IMMEDIATE FIX COMMANDS**

### **1. Install Redis (Copy-Paste di Termius)**
```bash
# Install Redis
sudo apt update && sudo apt install -y redis-server redis-tools

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Test Redis
redis-cli ping  # Should return "PONG"
```

### **2. Create Missing Directories**
```bash
# Navigate to Laravel
cd /var/www/Tenjo/dashboard

# Create storage directories
sudo mkdir -p storage/app/{streams,video_chunks,hls}
sudo chown -R www-data:www-data storage/app/
sudo chmod -R 755 storage/app/

# Verify created
ls -la storage/app/
```

### **3. Configure Laravel for Redis**
```bash
# Backup .env
cp .env .env.backup

# Add Redis config to .env
echo "" >> .env
echo "# Redis Configuration" >> .env
echo "CACHE_DRIVER=redis" >> .env
echo "REDIS_HOST=127.0.0.1" >> .env
echo "REDIS_PASSWORD=null" >> .env
echo "REDIS_PORT=6379" >> .env

# Clear Laravel cache
php artisan config:clear && php artisan cache:clear
```

### **4. Test Cache Immediately**
```bash
# Test Laravel cache
php artisan tinker --execute="Cache::put('test', 'working', 60); echo Cache::get('test');"

# Test Redis directly
redis-cli set "test_key" "test_value"
redis-cli get "test_key"

# Check Redis info
redis-cli info server | head -10
```

## 🔍 **DIAGNOSTIC COMMANDS**

### **Quick Status Check**
```bash
CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"

echo "=== REDIS STATUS ==="
redis-cli ping
redis-cli keys "*chunk*" | wc -l

echo "=== STORAGE STATUS ==="
find storage/app -type f -mmin -30 | wc -l
ls -la storage/app/

echo "=== API STATUS ==="
curl -s -o /dev/null -w "Heartbeat: %{http_code}\n" "http://localhost/api/heartbeat"
curl -s "http://localhost/api/stream/latest/$CLIENT_ID" | wc -c
```

### **Real-time Monitoring**
```bash
# Monitor logs for video activity
tail -f storage/logs/laravel.log | grep -E "(video|chunk|stream)" --color=always

# Monitor Redis cache
watch -n 2 'redis-cli keys "*chunk*" | wc -l; echo "Latest chunk size:"; redis-cli strlen "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73" 2>/dev/null || echo "0"'

# Monitor file system
watch -n 5 'echo "Recent files:"; find storage/app -type f -mmin -5 | wc -l; echo "Storage size:"; du -sh storage/app/'
```

## 🎯 **TESTING VIDEO CHUNKS**

### **Test Specific Client**
```bash
CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Test API endpoints
echo "=== TESTING CLIENT $CLIENT_ID ==="
curl -v "http://localhost/api/stream/chunk/$CLIENT_ID"
echo ""
curl -v "http://localhost/api/stream/latest/$CLIENT_ID"

# Check Redis cache for client
redis-cli exists "latest_chunk_$CLIENT_ID"
redis-cli strlen "latest_chunk_$CLIENT_ID"
redis-cli type "latest_chunk_$CLIENT_ID"
```

### **Manual Cache Test**
```bash
# Simulate video chunk upload
redis-cli set "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73" "dummy_video_data_$(date +%s)"

# Test API response
curl -s "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Clean up
redis-cli del "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73"
```

## 🚀 **ONE-LINER AUTOMATED FIX**

### **Complete Auto-Fix (Run in one command)**
```bash
curl -sSL https://raw.githubusercontent.com/Adi-Sumardi/Tenjo/master/production_auto_fix.sh | sudo bash
```

### **Manual Step-by-Step Fix**
```bash
# 1. Install Redis
sudo apt update && sudo apt install -y redis-server redis-tools && sudo systemctl start redis-server

# 2. Setup directories and permissions
cd /var/www/Tenjo/dashboard && sudo mkdir -p storage/app/{streams,video_chunks,hls} && sudo chown -R www-data:www-data storage/

# 3. Configure Laravel
echo -e "\nCACHE_DRIVER=redis\nREDIS_HOST=127.0.0.1" >> .env && php artisan config:clear && php artisan cache:clear

# 4. Test everything
redis-cli ping && php artisan tinker --execute="Cache::put('test', 'ok', 60); echo Cache::get('test');"
```

## 📊 **SUCCESS INDICATORS**

### **After Fix - These Should Work:**
```bash
# Redis working
redis-cli ping  # Returns: PONG

# Directories exist
ls -la storage/app/video_chunks/  # Directory exists

# Cache working
redis-cli keys "*chunk*"  # Should show cache keys when client active

# API returning data
curl -s "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73" | wc -c  # > 100 bytes when active
```

## 🔧 **CLIENT VERIFICATION**

### **Check Client Auto Video Streaming**
```bash
# If you have client access, check environment
echo $TENJO_AUTO_VIDEO  # Should be "true"

# Check client process
ps aux | grep "python.*main.py"

# Force restart client with auto video
export TENJO_AUTO_VIDEO=true && python3 main.py
```

## 📱 **TERMIUS SHORTCUTS**

### **Save These as Termius Snippets:**

**1. `fix-redis`:**
```bash
sudo apt install -y redis-server redis-tools && sudo systemctl start redis-server && redis-cli ping
```

**2. `check-chunks`:**
```bash
redis-cli keys "*chunk*" | wc -l && find storage/app -name "*chunk*" | wc -l && curl -s "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73" | wc -c
```

**3. `monitor-live`:**
```bash
tail -f storage/logs/laravel.log | grep -E "(chunk|stream|video)" --color=always
```

**4. `storage-status`:**
```bash
find storage/app -type f -mmin -10 | wc -l && du -sh storage/app/ && ls -la storage/app/
```

## 🎯 **EXPECTED TIMELINE**

### **Immediate (0-5 minutes):**
- Install Redis ✅
- Create directories ✅  
- Configure Laravel ✅

### **After Client Restart (5-10 minutes):**
- Redis shows chunk keys ✅
- storage/app/video_chunks/ has files ✅
- API returns video data ✅

### **Monitoring (Ongoing):**
- Real-time chunk uploads ✅
- Dashboard shows video instead of screenshots ✅

Gunakan commands ini untuk memperbaiki production server dengan cepat! 🚀
