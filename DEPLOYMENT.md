# Tenjo - Deployment Guide untuk BiznetGio Cloud VPS

## Overview
Panduan lengkap untuk deploy aplikasi employee monitoring Tenjo ke server VPS BiznetGio Cloud dengan konfigurasi production yang optimal.

## Prerequisites

### Server Spesifikasi Minimum
- **VPS**: BiznetGio Cloud VPS
- **OS**: Ubuntu 20.04 LTS atau 22.04 LTS
- **RAM**: Minimum 2GB (Recommended 4GB)
- **Storage**: Minimum 20GB SSD
- **CPU**: 2 vCPU
- **Bandwidth**: Unlimited

### Software Requirements
- PHP 8.2+
- Composer 2.x
- Node.js 18+ & npm
- PostgreSQL 13+ atau MySQL 8.0+
- Nginx atau Apache
- SSL Certificate (Let's Encrypt)
- Git

## 🚀 **Step 1: Setup Server BiznetGio**

### 1.1 Create VPS Instance
1. Login ke **BiznetGio Cloud Portal**
2. Go to **Compute** → **Virtual Machine**
3. **Create New Instance**:
   - **Image**: Ubuntu 22.04 LTS
   - **Flavor**: Standard 2GB RAM, 2 vCPU
   - **Storage**: 20GB SSD
   - **Network**: Auto assign public IP
   - **Security Group**: Allow HTTP (80), HTTPS (443), SSH (22)

### 1.2 Initial Server Setup
```bash
# Connect via SSH
ssh root@103.129.149.67

# Update system
apt update && apt upgrade -y

# Install essential packages
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates

# Create deployment user
adduser deploy
usermod -aG sudo deploy
su - deploy
```

## 🔧 **Step 2: Install Software Stack**

### 2.1 Install PHP 8.2
```bash
# Add PHP repository
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install PHP and extensions
sudo apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-common php8.2-mysql php8.2-pgsql \
php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath php8.2-sqlite3

# Verify PHP installation
php --version
```

### 2.2 Install Composer
```bash
# Download and install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Verify Composer
composer --version
```

### 2.3 Install Node.js & npm
```bash
# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### 2.4 Install PostgreSQL
```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql
```

```sql
-- In PostgreSQL console
CREATE DATABASE tenjo_production;
CREATE USER tenjo_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE tenjo_production TO tenjo_user;
\q
```

### 2.5 Install Nginx
```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

## 📂 **Step 3: Deploy Application**

### 3.1 Clone Repository
```bash
# Navigate to web directory
cd /var/www

# Clone Tenjo repository
sudo git clone https://github.com/Adi-Sumardi/Tenjo.git
sudo chown -R deploy:deploy Tenjo
cd Tenjo
```

### 3.2 Setup Laravel Dashboard
```bash
# Navigate to dashboard
cd dashboard

# Install PHP dependencies
composer install --no-dev --optimize-autoloader

# Install Node.js dependencies
npm install
npm run build

# Set permissions
sudo chown -R www-data:www-data /var/www/Tenjo
sudo chmod -R 755 /var/www/Tenjo
sudo chmod -R 775 /var/www/Tenjo/dashboard/storage
sudo chmod -R 775 /var/www/Tenjo/dashboard/bootstrap/cache
```

### 3.3 Configure Environment
```bash
# Copy environment file
cp .env.example .env

# Edit environment configuration
nano .env
```

Configure `.env` file:
```env
APP_NAME="Tenjo Employee Monitoring"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://your-domain.com

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=tenjo_production
DB_USERNAME=tenjo_user
DB_PASSWORD=your_secure_password

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

### 3.4 Generate Application Key
```bash
# Generate application key
php artisan key:generate

# Clear and cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations
php artisan migrate --force

# Create storage symlink
php artisan storage:link
```

## 🌐 **Step 4: Configure Web Server**

### 4.1 Create Nginx Virtual Host
```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/tenjo
```

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    root /var/www/Tenjo/dashboard/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Security headers
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()";

    # Client max body size for file uploads
    client_max_body_size 100M;
}
```

### 4.2 Enable Site
```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/tenjo /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

## 🔒 **Step 5: Setup SSL Certificate**

### 5.1 Install Certbot
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Verify auto-renewal
sudo certbot renew --dry-run
```

## 🔐 **Step 6: Security & Optimization**

### 6.1 Configure Firewall
```bash
# Install and configure UFW firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw status
```

### 6.2 Setup Automated Backups
```bash
# Create backup script
sudo nano /usr/local/bin/tenjo-backup.sh
```

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/backup/tenjo"
DB_NAME="tenjo_production"
DB_USER="tenjo_user"
APP_DIR="/var/www/Tenjo"
DATE=$(date +"%Y%m%d_%H%M%S")

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
PGPASSWORD="your_secure_password" pg_dump -h localhost -U $DB_USER $DB_NAME > $BACKUP_DIR/database_$DATE.sql

# Application files backup
tar -czf $BACKUP_DIR/application_$DATE.tar.gz \
    --exclude='node_modules' \
    --exclude='vendor' \
    --exclude='storage/logs' \
    $APP_DIR

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# Make script executable
sudo chmod +x /usr/local/bin/tenjo-backup.sh

# Add to crontab (daily backup at 2 AM)
echo "0 2 * * * /usr/local/bin/tenjo-backup.sh" | sudo crontab -
```

## 📱 **Step 7: Client Installation Setup**

### 7.1 Serve Client Files
```bash
# Create public download directory
mkdir -p /var/www/Tenjo/dashboard/public/downloads

# Copy client installation files
cp /var/www/Tenjo/client/*.bat /var/www/Tenjo/dashboard/public/downloads/
cp /var/www/Tenjo/client/*.sh /var/www/Tenjo/dashboard/public/downloads/
chmod +x /var/www/Tenjo/dashboard/public/downloads/*.sh
```

### 7.2 Update Client URLs
Update installation URLs to point to your server:

**For Windows clients:**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://your-domain.com/downloads/install.bat' -OutFile 'install.bat'; .\install.bat"
```

**For macOS clients:**
```bash
curl -sSL https://your-domain.com/downloads/install.sh | bash
```

## 🔍 **Step 8: Monitoring & Maintenance**

### 8.1 Setup Log Rotation
```bash
# Configure log rotation
sudo nano /etc/logrotate.d/tenjo
```

```
/var/www/Tenjo/dashboard/storage/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
}
```

### 8.2 Performance Optimization
```bash
# Optimize PHP-FPM
sudo nano /etc/php/8.2/fpm/pool.d/www.conf

# Optimize these settings:
# pm.max_children = 50
# pm.start_servers = 5
# pm.min_spare_servers = 5
# pm.max_spare_servers = 35

# Restart PHP-FPM
sudo systemctl restart php8.2-fpm
```

## 🚀 **Step 9: Go Live**

### 9.1 Final Checklist
- ✅ Domain DNS pointing to server IP
- ✅ SSL certificate installed and working
- ✅ Database migrations completed
- ✅ File permissions set correctly
- ✅ Nginx configuration tested
- ✅ Backup system configured
- ✅ Firewall configured

### 9.2 Test Installation
1. **Web Dashboard**: Visit `https://your-domain.com`
2. **Client Installation**: Test installation scripts
3. **Data Flow**: Verify data from clients to dashboard

## 📞 **Troubleshooting**

### Common Issues

**500 Internal Server Error:**
```bash
# Check Laravel logs
tail -f /var/www/Tenjo/dashboard/storage/logs/laravel.log

# Check Nginx error logs  
sudo tail -f /var/log/nginx/error.log
```

**Database Connection Issues:**
```bash
# Test database connection
sudo -u postgres psql -d tenjo_production -U tenjo_user

# Check PostgreSQL status
sudo systemctl status postgresql
```

**File Permission Issues:**
```bash
# Reset permissions
sudo chown -R www-data:www-data /var/www/Tenjo
sudo chmod -R 755 /var/www/Tenjo
sudo chmod -R 775 /var/www/Tenjo/dashboard/storage
sudo chmod -R 775 /var/www/Tenjo/dashboard/bootstrap/cache
```

## 🔄 **Updates & Maintenance**

### Application Updates
```bash
# Pull latest changes
cd /var/www/Tenjo
git pull origin master

# Update dependencies
cd dashboard
composer install --no-dev --optimize-autoloader
npm install && npm run build

# Run migrations
php artisan migrate --force

# Clear caches
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Restart services
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx
```

## 💰 **Cost Estimation BiznetGio**

**Monthly VPS Costs:**
- **Standard 2GB**: ~Rp 200,000-300,000/bulan
- **Standard 4GB**: ~Rp 400,000-500,000/bulan
- **Domain**: ~Rp 150,000/tahun
- **Total**: ~Rp 200,000-500,000/bulan

**Recommended Plan**: Standard 2GB untuk start, upgrade ke 4GB jika banyak client.

## 🎯 **Post-Deployment**

### Client Distribution Commands

**Windows Installation:**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'https://your-domain.com/downloads/easy_install_windows.bat' -OutFile 'tenjo_install.bat'; .\tenjo_install.bat"
```

**macOS Installation:**
```bash
curl -sSL https://your-domain.com/downloads/easy_install_macos.sh | bash
```

**Uninstall Commands:**
```cmd
# Windows
powershell -Command "Invoke-WebRequest -Uri 'https://your-domain.com/downloads/uninstall_windows.bat' -OutFile 'tenjo_uninstall.bat'; .\tenjo_uninstall.bat"
```

```bash
# macOS
curl -sSL https://your-domain.com/downloads/uninstall_macos.sh | bash
```

Tenjo sekarang **ready for production deployment** di BiznetGio Cloud! 🚀
