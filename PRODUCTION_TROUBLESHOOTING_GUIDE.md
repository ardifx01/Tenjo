# PRODUCTION TROUBLESHOOTING - Video Chunks Not Found

## 🔍 **Current Status Analysis**

Berdasarkan hasil testing production server:

### ✅ **Working Components:**
- Laravel routes tersedia (`/api/stream/*`)
- Screenshots upload berfungsi (`storage/app/public/screenshots/`)
- Web server responding
- Laravel application running

### ❌ **Issues Identified:**
- **Redis tidak terinstall** (`redis-cli` command not found)
- **Tidak ada video chunks** di storage
- **Direktori `streams/` dan `video_chunks/` tidak ada**
- **File cache kosong** (tidak ada chunk cache files)
- **Client mengirim screenshots instead of video**

## 🚨 **Root Cause Analysis**

### **Issue 1: Redis Not Installed**
```bash
# Error yang terjadi:
Command 'redis-cli' not found, but can be installed with:
sudo apt install redis-tools

# Impact:
- Cache driver mungkin fallback ke file cache
- Video chunks tidak tersimpan dengan benar
- Streaming performance terganggu
```

### **Issue 2: Client Sending Screenshots Not Video**
```bash
# Evidence:
ls -la storage/app/public/screenshots/  # Folder ada dan berisi data
ls -la storage/app/video_chunks/        # Direktori tidak ada
```

**Kemungkinan Penyebab:**
- Client tidak menggunakan auto video streaming
- Environment variable `TENJO_AUTO_VIDEO` tidak di-set
- Client fallback ke screenshot mode
- Video streaming gagal start

## 🛠️ **Immediate Fix Steps**

### **Step 1: Install Redis**
```bash
# Install Redis server dan tools
sudo apt update
sudo apt install redis-server redis-tools

# Start Redis service
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Test Redis
redis-cli ping  # Should return "PONG"
```

### **Step 2: Configure Laravel for Redis**
```bash
# Check Laravel cache configuration
php artisan config:show cache

# Set cache driver to Redis (edit .env)
nano .env
# Add/update:
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Clear Laravel cache
php artisan config:clear
php artisan cache:clear
```

### **Step 3: Create Missing Directories**
```bash
# Create required storage directories
mkdir -p storage/app/streams
mkdir -p storage/app/video_chunks
mkdir -p storage/app/hls

# Set proper permissions
chown -R www-data:www-data storage/app/
chmod -R 755 storage/app/
```

### **Step 4: Check Client Configuration**
```bash
# Check if client is using auto video streaming
# SSH to client machine or check remote client config

# Expected: Client should have TENJO_AUTO_VIDEO=true
echo $TENJO_AUTO_VIDEO  # Should show "true"

# If not set, configure it:
export TENJO_AUTO_VIDEO=true
```

## 🔧 **Detailed Testing Commands**

### **Test Redis Installation**
```bash
# After installing Redis
redis-cli ping
redis-cli info server
redis-cli config get save
```

### **Test Laravel Cache with Redis**
```bash
# Test cache manually
php artisan tinker
> Cache::put('test_video_chunk', 'dummy_data', 300);
> Cache::get('test_video_chunk');
> exit

# Check in Redis
redis-cli
> keys "*test_video_chunk*"
> get "laravel_database_test_video_chunk"
> exit
```

### **Monitor Video Chunk Uploads**
```bash
# Real-time monitoring for video chunks
tail -f storage/logs/laravel.log | grep -E "(video|chunk|stream)" --color=always

# Check for upload attempts
grep "uploadStreamChunk\|uploadVideoChunk" storage/logs/laravel.log | tail -10

# Monitor file system changes
watch "find storage/app -type f -mmin -5 | wc -l"
```

### **Test API Endpoints for Video Data**
```bash
CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Test video chunk endpoint
curl -v "http://localhost/api/stream/chunk/$CLIENT_ID"

# Test latest chunk endpoint
curl -v "http://localhost/api/stream/latest/$CLIENT_ID"

# Expected: Should return video data, not "no data available"
```

## 🎯 **Expected Results After Fix**

### **Redis Working:**
```bash
redis-cli ping  # Returns: PONG
redis-cli keys "*chunk*"  # Returns: chunk cache keys
```

### **Video Chunks Present:**
```bash
ls -la storage/app/video_chunks/  # Directory exists with files
ls -la storage/app/streams/       # Directory exists
find storage/app -name "*.chunk" -o -name "*.ts" | wc -l  # > 0
```

### **API Returns Video Data:**
```bash
curl -s "http://localhost/api/stream/latest/$CLIENT_ID" | wc -c  # > 1000 bytes
```

### **Redis Cache Active:**
```bash
redis-cli keys "*latest_chunk*"  # Shows client cache keys
redis-cli strlen "latest_chunk_$CLIENT_ID"  # > 0 bytes
```

## 🚀 **Production Fix Script**

```bash
#!/bin/bash
# Quick production fix script

echo "🔧 Fixing Tenjo Production Server..."

# Install Redis
echo "📦 Installing Redis..."
sudo apt update
sudo apt install -y redis-server redis-tools
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Test Redis
if redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis installed and running"
else
    echo "❌ Redis installation failed"
    exit 1
fi

# Create directories
echo "📁 Creating storage directories..."
mkdir -p storage/app/streams storage/app/video_chunks storage/app/hls
chown -R www-data:www-data storage/app/
chmod -R 755 storage/app/
echo "✅ Storage directories created"

# Configure Laravel
echo "⚙️ Configuring Laravel..."
# Update .env for Redis
if ! grep -q "CACHE_DRIVER=redis" .env; then
    echo "CACHE_DRIVER=redis" >> .env
fi
if ! grep -q "REDIS_HOST=127.0.0.1" .env; then
    echo "REDIS_HOST=127.0.0.1" >> .env
fi

# Clear cache
php artisan config:clear
php artisan cache:clear
echo "✅ Laravel configured for Redis"

# Test cache
echo "🧪 Testing cache..."
php artisan tinker --execute="Cache::put('test', 'working', 60); echo Cache::get('test');"

echo "🎉 Production server fix completed!"
echo ""
echo "📋 Next steps:"
echo "1. Restart client with TENJO_AUTO_VIDEO=true"
echo "2. Monitor: tail -f storage/logs/laravel.log | grep chunk"
echo "3. Check: redis-cli keys '*chunk*'"
```

## 🔍 **Client-Side Verification**

### **Check Client Status:**
```bash
# If you have access to client machine
ps aux | grep "python.*main.py"  # Client should be running
echo $TENJO_AUTO_VIDEO           # Should be "true"

# Check client logs
tail -f ~/.tenjo/logs/client.log | grep -E "(video|streaming|chunk)"
```

### **Force Client Video Streaming:**
```bash
# If client accessible, restart with auto video
export TENJO_AUTO_VIDEO=true
python3 main.py
```

## 📊 **Monitoring After Fix**

### **Real-time Dashboard:**
```bash
# Monitor multiple aspects
watch -n 5 '
echo "=== Redis Keys ==="
redis-cli keys "*chunk*" | wc -l
echo "=== Storage Files ==="
find storage/app -type f -mmin -5 | wc -l
echo "=== Recent Logs ==="
tail -3 storage/logs/laravel.log
'
```

Jalankan fix steps ini untuk mengatasi masalah video chunks di production server! 🚀
