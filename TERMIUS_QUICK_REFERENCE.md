# Termius Quick Reference - Tenjo Production Testing

## 🚀 **Quick Setup Commands**

### **Connect to Production Server**
```bash
ssh username@103.129.149.67
```

### **Navigate to Application**
```bash
cd /var/www/html  # or your Laravel path
```

## ⚡ **Instant Video Chunk Check**

### **One-liner Status Check**
```bash
curl -s "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73" | head -50 && echo -e "\n=== API Status ===" && curl -s -o /dev/null -w "Status: %{http_code}\n" "http://localhost/api/heartbeat"
```

### **Quick Cache Check (Redis)**
```bash
redis-cli keys "*chunk*" | wc -l && redis-cli exists "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73" && redis-cli strlen "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73"
```

### **Quick Storage Check**
```bash
find storage/app -type f -mmin -10 | wc -l && du -sh storage/app/ && find storage/app -name "*chunk*" -o -name "*.mp4" -o -name "*.ts" | wc -l
```

## 📊 **Real-time Monitoring**

### **Live Log Monitoring**
```bash
tail -f storage/logs/laravel.log | grep --color=always -E "(chunk|stream|video|33ba500a)"
```

### **Live Cache Monitoring (Redis)**
```bash
watch -n 2 'redis-cli keys "*chunk*" | wc -l; redis-cli strlen "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73" 2>/dev/null || echo "0"'
```

### **Live Storage Monitoring**
```bash
watch -n 5 'echo "Recent files:"; find storage/app -type f -mmin -5 | wc -l; echo "Total size:"; du -sh storage/app'
```

## 🔍 **Detailed Investigation**

### **API Endpoint Testing**
```bash
# Test all endpoints
echo "=== Heartbeat ===" && curl -v "http://localhost/api/heartbeat"
echo -e "\n=== Stream Chunk ===" && curl -v "http://localhost/api/stream/chunk/33ba500a-fdea-6619-b1e7-0ede2979bd73"
echo -e "\n=== Latest Chunk ===" && curl -v "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73"
```

### **Cache Deep Dive (Redis)**
```bash
# Show all chunk-related keys
redis-cli keys "*chunk*"

# Show latest chunk keys
redis-cli keys "*latest_chunk*"

# Get specific client data
redis-cli get "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Monitor Redis activity
redis-cli monitor | grep chunk
```

### **Storage Deep Dive**
```bash
# Find all video files
find storage/app -name "*.mp4" -o -name "*.ts" -o -name "*.chunk" -exec ls -la {} \;

# Recent activity
find storage/app -type f -mmin -60 -exec ls -la {} \;

# Storage by directory
for dir in streams video_chunks hls public; do
  if [ -d "storage/app/$dir" ]; then
    echo "=== $dir ==="; 
    du -sh "storage/app/$dir"; 
    find "storage/app/$dir" -type f | wc -l; 
  fi
done
```

### **Log Analysis**
```bash
# Recent chunk activity
grep -E "(chunk|stream|video)" storage/logs/laravel.log | tail -20

# Client specific activity
grep "33ba500a-fdea-6619-b1e7-0ede2979bd73" storage/logs/laravel.log | tail -10

# Upload activity
grep -i "upload\|POST.*stream" storage/logs/laravel.log | tail -10

# Error checking
grep -E "(ERROR|Exception|Error)" storage/logs/laravel.log | tail -5
```

## 🛠️ **Laravel Specific Commands**

### **Artisan Commands**
```bash
# Check app status
php artisan --version
php artisan route:list | grep stream
php artisan config:show cache

# Cache operations
php artisan cache:show
php artisan cache:clear
```

### **Queue & Jobs (if applicable)**
```bash
php artisan queue:work --once
php artisan queue:failed
php artisan queue:retry all
```

## 🎯 **Success Indicators**

### **✅ Video Chunks Working:**
```bash
# Should return video data (large response)
curl -s "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73" | wc -c

# Should show > 0
redis-cli strlen "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Should show recent activity
grep "33ba500a" storage/logs/laravel.log | tail -1
```

### **❌ Common Issues:**
```bash
# No cache data
redis-cli exists "latest_chunk_33ba500a-fdea-6619-b1e7-0ede2979bd73"  # Returns 0

# API returning errors
curl -s -o /dev/null -w "%{http_code}" "http://localhost/api/stream/latest/33ba500a-fdea-6619-b1e7-0ede2979bd73"  # Not 200

# No recent activity
find storage/app -type f -mmin -30 | wc -l  # Returns 0
```

## 🚨 **Emergency Debugging**

### **If No Video Chunks:**
```bash
# Check if client is sending data
grep "POST.*stream.*chunk" storage/logs/laravel.log | tail -5

# Check Laravel routes
php artisan route:list | grep chunk

# Test cache manually
php artisan tinker
> Cache::put('test', 'value', 60);
> Cache::get('test');
```

### **If Permissions Issue:**
```bash
sudo chown -R www-data:www-data storage/
sudo chmod -R 755 storage/
```

### **If Storage Full:**
```bash
df -h
du -sh storage/app/
# Clean old files if needed
find storage/app -type f -mtime +7 -delete
```

## 📱 **Termius-Specific Tips**

### **Save Frequently Used Commands**
Create shortcuts in Termius for:
- `chunk-status`: Quick video chunk check
- `live-monitor`: Real-time monitoring
- `log-watch`: Live log monitoring
- `cache-check`: Redis cache inspection

### **Command Templates**
```bash
# Template for client ID
CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Template for API check
API_CHECK='curl -s "http://localhost/api/stream/latest/$CLIENT_ID" | head -50'

# Template for cache check
CACHE_CHECK='redis-cli get "latest_chunk_$CLIENT_ID"'
```

### **Session Management**
- Keep multiple sessions: Main monitoring, Log watching, Command execution
- Use tmux/screen for persistent sessions
- Set up port forwarding if needed

## 🎬 **Expected Results**

### **Working Video Streaming:**
- API returns 200 with large JSON response (>1000 bytes)
- Redis shows client key with data size >10000 bytes
- Recent log entries show chunk uploads
- Storage shows recent file activity

### **Not Working:**
- API returns 404/500 or small response
- Redis shows no data for client key
- No recent log activity
- No recent storage activity

Save these commands in Termius for quick access to production debugging! 🚀
