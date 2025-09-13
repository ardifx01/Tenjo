# Stream Chunks Auto Cleanup System

## Overview

Tenjo includes an automatic cleanup system to prevent stream chunks from consuming excessive server storage. The system provides multiple layers of cleanup with different retention periods.

## Cleanup Strategies

### 1. **Weekly Cleanup (Recommended)**
- **Schedule**: Every Sunday at 2:00 AM
- **Retention**: Deletes files older than 7 days
- **Purpose**: Regular maintenance to keep storage usage reasonable

### 2. **Daily Cleanup (Backup)**
- **Schedule**: Every day at 3:00 AM
- **Retention**: Deletes files older than 30 days
- **Condition**: Only runs when total storage > 5GB
- **Purpose**: Additional cleanup for high-usage environments

### 3. **Emergency Cleanup**
- **Schedule**: Every hour
- **Retention**: Deletes files older than 1 day
- **Condition**: Only runs when total storage > 10GB
- **Purpose**: Prevents server storage from filling up completely

## Manual Commands

### Basic Cleanup Command
```bash
# Cleanup files older than 7 days
php artisan tenjo:cleanup-streams --days=7

# Cleanup files older than 1 day (emergency)
php artisan tenjo:cleanup-streams --days=1

# Dry run to see what would be deleted (recommended first)
php artisan tenjo:cleanup-streams --days=7 --dry-run
```

### Command Options
- `--days=N`: Keep files newer than N days (default: 7)
- `--dry-run`: Show what would be deleted without actually deleting
- `--help`: Show detailed help information

### Example Usage
```bash
# Test what would be deleted in the last week
php artisan tenjo:cleanup-streams --days=7 --dry-run

# Actually perform the cleanup
php artisan tenjo:cleanup-streams --days=7

# Emergency cleanup (keep only files from today)
php artisan tenjo:cleanup-streams --days=0
```

## Setup on Production Server

### Automatic Setup (Recommended)
```bash
# Make the script executable
chmod +x scripts/setup-cleanup-cron.sh

# Run the setup script
./scripts/setup-cleanup-cron.sh
```

### Manual Cron Setup
Add these lines to your crontab (`crontab -e`):

```bash
# Weekly cleanup (every Sunday at 2 AM)
0 2 * * 0 /usr/bin/php /path/to/tenjo/artisan tenjo:cleanup-streams --days=7 >> /path/to/tenjo/storage/logs/cleanup.log 2>&1

# Daily cleanup for old files (every day at 3 AM)
0 3 * * * /usr/bin/php /path/to/tenjo/artisan tenjo:cleanup-streams --days=30 >> /path/to/tenjo/storage/logs/cleanup.log 2>&1

# Emergency cleanup (hourly if storage > 10GB)
0 * * * * [ $(du -s /path/to/tenjo/storage/app/private/stream_chunks 2>/dev/null | cut -f1) -gt 10485760 ] && /usr/bin/php /path/to/tenjo/artisan tenjo:cleanup-streams --days=1 >> /path/to/tenjo/storage/logs/cleanup.log 2>&1
```

## Monitoring & Logs

### Check Cleanup Logs
```bash
# View recent cleanup activity
tail -f storage/logs/cleanup.log

# View Laravel logs for any errors
tail -f storage/logs/laravel.log
```

### Monitor Storage Usage
```bash
# Check total storage used by stream chunks
du -sh storage/app/private/stream_chunks/

# Check storage per client
du -sh storage/app/private/stream_chunks/*/

# Count total files
find storage/app/private/stream_chunks/ -name "*.chunk" | wc -l
```

### Current Cron Jobs
```bash
# View installed cron jobs
crontab -l

# Remove all cron jobs (if needed)
crontab -r
```

## Storage Estimates

### Typical Usage Patterns
- **Low Activity**: ~100MB per week per client
- **Medium Activity**: ~500MB per week per client
- **High Activity**: ~2GB per week per client

### Retention Impact
- **7 days retention**: ~2-14GB total storage
- **3 days retention**: ~1-6GB total storage
- **1 day retention**: ~200MB-2GB total storage

## Troubleshooting

### Common Issues

1. **Storage Still Growing**
   ```bash
   # Check if cron jobs are running
   grep "tenjo:cleanup" /var/log/cron

   # Run manual cleanup with debug
   php artisan tenjo:cleanup-streams --days=1 -v
   ```

2. **Permission Errors**
   ```bash
   # Fix storage permissions
   chown -R www-data:www-data storage/
   chmod -R 755 storage/
   ```

3. **Cron Not Running**
   ```bash
   # Check cron service status
   systemctl status cron

   # Restart cron service
   sudo systemctl restart cron
   ```

### Emergency Manual Cleanup
If storage is critically full:

```bash
# Keep only files from last 6 hours
php artisan tenjo:cleanup-streams --days=0

# Or manually delete oldest directories
rm -rf storage/app/private/stream_chunks/$(ls storage/app/private/stream_chunks/ | head -n 3)
```

## Configuration

### Customize Retention Periods
Edit `routes/console.php` to adjust cleanup schedules:

```php
// Change weekly cleanup to 3 days
Schedule::command('tenjo:cleanup-streams', ['--days=3'])
    ->weekly()
    ->sundays()
    ->at('02:00');
```

### Email Notifications
Configure email notifications for cleanup failures by setting:

```bash
# In .env file
MAIL_ADMIN_EMAIL=admin@yourcompany.com
```

## Best Practices

1. **Monitor Regularly**: Check storage usage weekly
2. **Test First**: Always run `--dry-run` before manual cleanup
3. **Backup Critical Streams**: If you need long-term retention for specific clients
4. **Adjust Retention**: Based on your business requirements and storage capacity
5. **Log Rotation**: Ensure cleanup logs don't grow too large

## Security Considerations

- Cleanup runs as the web user (www-data/nginx)
- Only affects files in `storage/app/private/stream_chunks/`
- Cannot delete files outside the designated directory
- Preserves directory structure and permissions
