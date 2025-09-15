#!/bin/bash
# Tenjo Production Server Auto-Fix Script
# Fixes common issues: Redis installation, storage setup, cache configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LARAVEL_PATH="/var/www/Tenjo/dashboard"  # Adjust if different
CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        error "This script needs to be run with sudo for Redis installation"
        echo "Usage: sudo $0"
        exit 1
    fi
}

# Function to check Laravel directory
check_laravel() {
    log "Checking Laravel application..."
    
    if [ ! -d "$LARAVEL_PATH" ]; then
        error "Laravel directory not found: $LARAVEL_PATH"
        echo "Please update LARAVEL_PATH in this script to match your installation"
        exit 1
    fi
    
    cd "$LARAVEL_PATH"
    
    if [ ! -f "artisan" ]; then
        error "Laravel artisan not found in $LARAVEL_PATH"
        exit 1
    fi
    
    log "✅ Laravel application found: $(php artisan --version)"
}

# Function to install and configure Redis
install_redis() {
    log "Installing Redis server..."
    
    # Update package list
    apt update
    
    # Install Redis
    apt install -y redis-server redis-tools
    
    # Start and enable Redis
    systemctl start redis-server
    systemctl enable redis-server
    
    # Test Redis
    sleep 2
    if redis-cli ping | grep -q "PONG"; then
        log "✅ Redis installed and running successfully"
    else
        error "❌ Redis installation failed"
        exit 1
    fi
    
    # Configure Redis for Laravel
    log "Configuring Redis for Laravel..."
    
    # Basic Redis configuration
    redis-cli config set save "900 1 300 10 60 10000"
    redis-cli config set maxmemory-policy allkeys-lru
    
    log "✅ Redis configured"
}

# Function to create storage directories
create_storage_dirs() {
    log "Creating storage directories..."
    
    cd "$LARAVEL_PATH"
    
    # Create required directories
    directories=(
        "storage/app/streams"
        "storage/app/video_chunks"
        "storage/app/hls"
        "storage/app/private"
        "storage/framework/cache/data"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            info "Created directory: $dir"
        fi
    done
    
    # Set proper permissions
    chown -R www-data:www-data storage/
    chmod -R 755 storage/
    
    log "✅ Storage directories created and permissions set"
}

# Function to configure Laravel for Redis
configure_laravel() {
    log "Configuring Laravel for Redis cache..."
    
    cd "$LARAVEL_PATH"
    
    # Backup original .env
    if [ -f ".env" ]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        info "Created .env backup"
    fi
    
    # Update .env file
    if [ -f ".env" ]; then
        # Remove existing cache/redis configs
        sed -i '/^CACHE_DRIVER=/d' .env
        sed -i '/^REDIS_HOST=/d' .env
        sed -i '/^REDIS_PASSWORD=/d' .env
        sed -i '/^REDIS_PORT=/d' .env
        
        # Add Redis configuration
        cat >> .env << EOF

# Redis Configuration (Added by auto-fix)
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
EOF
        
        log "✅ .env file updated with Redis configuration"
    else
        warn ".env file not found, creating basic Redis config"
        cat > .env << EOF
CACHE_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
EOF
    fi
    
    # Clear Laravel cache
    php artisan config:clear
    php artisan cache:clear
    php artisan route:clear
    
    log "✅ Laravel cache cleared"
}

# Function to test cache functionality
test_cache() {
    log "Testing cache functionality..."
    
    cd "$LARAVEL_PATH"
    
    # Test Laravel cache
    php artisan tinker --execute="
        Cache::put('tenjo_test_key', 'test_value_' . time(), 300);
        echo 'Cache test: ' . Cache::get('tenjo_test_key') . PHP_EOL;
    "
    
    # Test Redis directly
    redis-cli set "tenjo_direct_test" "direct_value_$(date +%s)"
    direct_test=$(redis-cli get "tenjo_direct_test")
    
    if [ -n "$direct_test" ]; then
        log "✅ Redis direct access working: $direct_test"
    else
        warn "❌ Redis direct access failed"
    fi
    
    # Clean up test keys
    redis-cli del "tenjo_direct_test"
    
    log "✅ Cache testing completed"
}

# Function to test API endpoints
test_endpoints() {
    log "Testing streaming endpoints..."
    
    # Test basic API
    heartbeat_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/api/heartbeat" 2>/dev/null || echo "000")
    
    if [ "$heartbeat_response" = "200" ]; then
        log "✅ API heartbeat working"
    else
        warn "⚠️ API heartbeat returned: $heartbeat_response"
    fi
    
    # Test stream endpoints
    chunk_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/api/stream/chunk/$CLIENT_ID" 2>/dev/null || echo "000")
    latest_response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/api/stream/latest/$CLIENT_ID" 2>/dev/null || echo "000")
    
    info "Stream chunk endpoint: HTTP $chunk_response"
    info "Latest chunk endpoint: HTTP $latest_response"
    
    log "✅ Endpoint testing completed"
}

# Function to show monitoring commands
show_monitoring() {
    log "Production server fix completed!"
    
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}         POST-FIX MONITORING COMMANDS      ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    echo -e "${YELLOW}📊 Monitor Redis Cache:${NC}"
    echo "redis-cli keys '*chunk*'"
    echo "redis-cli keys '*latest_chunk*'"
    echo "redis-cli info memory"
    echo ""
    
    echo -e "${YELLOW}📁 Monitor Storage:${NC}"
    echo "watch 'find storage/app -type f -mmin -5 | wc -l'"
    echo "ls -la storage/app/video_chunks/"
    echo "ls -la storage/app/streams/"
    echo ""
    
    echo -e "${YELLOW}📄 Monitor Logs:${NC}"
    echo "tail -f storage/logs/laravel.log | grep -E '(chunk|stream|video)'"
    echo "tail -f storage/logs/laravel.log | grep '$CLIENT_ID'"
    echo ""
    
    echo -e "${YELLOW}🌐 Test Endpoints:${NC}"
    echo "curl \"http://localhost/api/heartbeat\""
    echo "curl \"http://localhost/api/stream/latest/$CLIENT_ID\""
    echo ""
    
    echo -e "${YELLOW}🎯 Expected After Client Connects:${NC}"
    echo "- Redis should show chunk keys"
    echo "- storage/app/video_chunks/ should contain files"
    echo "- API endpoints should return video data"
    echo "- Logs should show chunk upload activity"
    echo ""
    
    echo -e "${GREEN}🚀 Ready for client connections with auto video streaming!${NC}"
}

# Function to create monitoring script
create_monitoring_script() {
    log "Creating monitoring script..."
    
    cat > /usr/local/bin/tenjo-monitor << 'EOF'
#!/bin/bash
# Tenjo Production Monitor Script

CLIENT_ID="33ba500a-fdea-6619-b1e7-0ede2979bd73"
LARAVEL_PATH="/var/www/Tenjo/dashboard"

echo "=== Tenjo Production Monitor ==="
echo "Time: $(date)"
echo ""

echo "🔧 Redis Status:"
redis-cli ping 2>/dev/null || echo "Redis not responding"
echo "Cache keys: $(redis-cli keys '*chunk*' 2>/dev/null | wc -l)"
echo ""

echo "📁 Storage Status:"
if [ -d "$LARAVEL_PATH/storage/app" ]; then
    cd "$LARAVEL_PATH"
    echo "Recent files (5min): $(find storage/app -type f -mmin -5 2>/dev/null | wc -l)"
    echo "Video files: $(find storage/app -name '*.chunk' -o -name '*.ts' -o -name '*.mp4' 2>/dev/null | wc -l)"
    echo "Storage size: $(du -sh storage/app 2>/dev/null | cut -f1)"
fi
echo ""

echo "🌐 API Status:"
heartbeat=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost/api/heartbeat" 2>/dev/null || echo "000")
echo "Heartbeat: HTTP $heartbeat"

chunk_size=$(curl -s "http://localhost/api/stream/latest/$CLIENT_ID" 2>/dev/null | wc -c || echo "0")
echo "Latest chunk size: $chunk_size bytes"
echo ""

echo "📄 Recent Activity:"
if [ -f "$LARAVEL_PATH/storage/logs/laravel.log" ]; then
    grep -E "(chunk|stream|video)" "$LARAVEL_PATH/storage/logs/laravel.log" 2>/dev/null | tail -3
fi
EOF

    chmod +x /usr/local/bin/tenjo-monitor
    log "✅ Monitoring script created: /usr/local/bin/tenjo-monitor"
}

# Main execution
main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}       TENJO PRODUCTION AUTO-FIX SCRIPT    ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    log "Starting Tenjo production server auto-fix..."
    log "Laravel path: $LARAVEL_PATH"
    log "Client ID: $CLIENT_ID"
    echo ""
    
    check_permissions
    check_laravel
    
    echo ""
    install_redis
    
    echo ""
    create_storage_dirs
    
    echo ""
    configure_laravel
    
    echo ""
    test_cache
    
    echo ""
    test_endpoints
    
    echo ""
    create_monitoring_script
    
    echo ""
    show_monitoring
}

# Run main function
main "$@"
