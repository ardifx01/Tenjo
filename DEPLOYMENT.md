# Tenjo Deployment Guide

This guide covers deployment scenarios for the Tenjo employee monitoring system.

## Prerequisites

- Linux server (Ubuntu 20.04+ recommended)
- Domain name with SSL certificate
- PostgreSQL database
- FFmpeg with hardware encoding support
- Node.js 18+ and npm
- PHP 8.2+ with required extensions
- Composer 2.x
- Redis (optional but recommended)

## Production Deployment

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install PHP 8.2 and extensions
sudo apt install -y php8.2 php8.2-fpm php8.2-mysql php8.2-pgsql php8.2-curl \
    php8.2-json php8.2-mbstring php8.2-xml php8.2-zip php8.2-gd php8.2-redis

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install FFmpeg with hardware acceleration
sudo apt install -y ffmpeg

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Redis
sudo apt install -y redis-server

# Install Nginx
sudo apt install -y nginx
```

### 2. Database Setup

```bash
# Create database and user
sudo -u postgres psql
CREATE DATABASE tenjo;
CREATE USER tenjo_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE tenjo TO tenjo_user;
\q
```

### 3. Application Deployment

```bash
# Clone repository
cd /var/www
sudo git clone https://github.com/yourusername/tenjo.git
sudo chown -R $USER:$USER /var/www/tenjo
cd /var/www/tenjo/dashboard

# Install PHP dependencies
composer install --no-dev --optimize-autoloader

# Install Node.js dependencies
npm install
npm run build

# Setup environment
cp .env.example .env
php artisan key:generate

# Configure database
php artisan migrate --force
php artisan db:seed --force

# Setup storage permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### 4. Environment Configuration

Edit `/var/www/tenjo/dashboard/.env`:

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=tenjo
DB_USERNAME=tenjo_user
DB_PASSWORD=secure_password

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

REDIS_HOST=127.0.0.1
REDIS_PORT=6379

STREAMING_SERVER=wss://yourdomain.com:8443
WEBRTC_TURN_SERVER=turn:yourdomain.com:3478
WEBRTC_TURN_USERNAME=turnuser
WEBRTC_TURN_PASSWORD=turnpassword

LOG_LEVEL=warning
LOG_CHANNEL=daily
```

### 5. Nginx Configuration

Create `/etc/nginx/sites-available/tenjo`:

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    root /var/www/tenjo/dashboard/public;
    index index.php;

    ssl_certificate /path/to/ssl/cert.pem;
    ssl_certificate_key /path/to/ssl/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    client_max_body_size 100M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location /ws {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/tenjo /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6. WebRTC Streaming Server

Install coturn for TURN server:
```bash
sudo apt install -y coturn

# Configure coturn
sudo nano /etc/turnserver.conf
```

Add to turnserver.conf:
```
listening-port=3478
tls-listening-port=5349
relay-device=eth0
min-port=10000
max-port=20000
verbose
fingerprint
lt-cred-mech
use-auth-secret
static-auth-secret=your_secret_key
realm=yourdomain.com
total-quota=100
bps-capacity=0
stale-nonce
cert=/path/to/ssl/cert.pem
pkey=/path/to/ssl/private.key
```

### 7. Process Management

Create systemd service `/etc/systemd/system/tenjo-queue.service`:

```ini
[Unit]
Description=Tenjo Queue Worker
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
Restart=always
RestartSec=5s
WorkingDirectory=/var/www/tenjo/dashboard
ExecStart=/usr/bin/php /var/www/tenjo/dashboard/artisan queue:work --sleep=3 --tries=3 --max-time=3600

[Install]
WantedBy=multi-user.target
```

Enable services:
```bash
sudo systemctl enable tenjo-queue
sudo systemctl start tenjo-queue
sudo systemctl enable coturn
sudo systemctl start coturn
```

### 8. SSL Certificate (Let's Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
sudo systemctl reload nginx
```

### 9. Firewall Configuration

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3478/tcp
sudo ufw allow 5349/tcp
sudo ufw allow 10000:20000/udp
sudo ufw enable
```

## Client Deployment

### Windows

Create installer using PyInstaller:
```bash
cd client/
pip install pyinstaller
pyinstaller --onefile --windowed --icon=icon.ico main.py
```

### macOS

Create app bundle:
```bash
cd client/
pip install py2app
python setup.py py2app
```

### Linux

Create AppImage or DEB package:
```bash
cd client/
pip install pyinstaller
pyinstaller --onefile main.py
```

## Docker Deployment

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  app:
    build:
      context: ./dashboard
      dockerfile: Dockerfile
    ports:
      - "8000:80"
    environment:
      - APP_ENV=production
      - DB_HOST=database
    volumes:
      - ./dashboard/storage:/var/www/html/storage
    depends_on:
      - database
      - redis

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: tenjo
      POSTGRES_USER: tenjo_user
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  coturn:
    image: coturn/coturn
    ports:
      - "3478:3478"
      - "3478:3478/udp"
      - "5349:5349"
    volumes:
      - ./coturn.conf:/etc/turnserver.conf

volumes:
  postgres_data:
  redis_data:
```

Create `dashboard/Dockerfile`:

```dockerfile
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip \
    postgresql-client libpq-dev nodejs npm

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader
RUN npm install && npm run build

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 80
```

## Monitoring and Maintenance

### Log Monitoring

```bash
# Monitor Laravel logs
tail -f /var/www/tenjo/dashboard/storage/logs/laravel.log

# Monitor Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Monitor system resources
htop
```

### Database Maintenance

```bash
# Backup database
pg_dump -h localhost -U tenjo_user tenjo > backup.sql

# Cleanup old data (run daily)
cd /var/www/tenjo/dashboard
php artisan schedule:run
```

### Updates

```bash
# Update application
cd /var/www/tenjo
git pull origin main
cd dashboard
composer install --no-dev --optimize-autoloader
npm install && npm run build
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
sudo systemctl restart tenjo-queue
```

## Scaling Considerations

### Load Balancing

Use multiple application servers behind a load balancer:
- Nginx upstream configuration
- Shared session storage (Redis)
- Shared file storage (NFS/S3)

### Database Optimization

- Read replicas for reporting queries
- Connection pooling (PgBouncer)
- Regular maintenance and optimization

### CDN Integration

- Static asset delivery
- Screenshot storage optimization
- Global content distribution

## Security Hardening

### Application Security

- Regular security updates
- Input validation and sanitization  
- Rate limiting and DDoS protection
- API authentication and authorization
- Encrypted data transmission
- Secure file upload handling

### Server Security

- Fail2ban for intrusion prevention
- Regular security patches
- Firewall configuration
- SSH key authentication
- File permission audits
- Log monitoring and alerting

## Legal Compliance

### Data Protection

- GDPR compliance measures
- Data retention policies
- User consent mechanisms
- Data encryption at rest
- Audit trail maintenance
- Right to erasure implementation

### Monitoring Disclosure

- Employee notification systems
- Legal compliance documentation
- Privacy policy updates
- Monitoring policy enforcement
- Consent management systems

## Support and Troubleshooting

### Common Issues

1. **High CPU usage**: Optimize screenshot frequency and compression
2. **Storage issues**: Implement data retention policies
3. **Network latency**: Use CDN and optimize payload sizes
4. **Database locks**: Optimize queries and indexing

### Performance Monitoring

- Application Performance Monitoring (APM)
- Database query optimization
- Resource usage tracking
- User experience metrics

### Backup Strategy

- Daily database backups
- Configuration file backups
- Log rotation and archival
- Disaster recovery procedures
