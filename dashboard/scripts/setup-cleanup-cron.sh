#!/bin/bash

# Tenjo Stream Cleanup Cron Setup Script
# This script sets up automatic cleanup of stream chunks for production servers

echo "🔧 Setting up Tenjo Stream Cleanup Cron Jobs..."

# Get the current directory (should be the Laravel root)
LARAVEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHP_PATH=$(which php)
ARTISAN_PATH="$LARAVEL_ROOT/artisan"

echo "📁 Laravel Root: $LARAVEL_ROOT"
echo "🐘 PHP Path: $PHP_PATH"

# Check if artisan exists
if [ ! -f "$ARTISAN_PATH" ]; then
    echo "❌ Error: artisan file not found at $ARTISAN_PATH"
    exit 1
fi

# Test the cleanup command
echo "🧪 Testing cleanup command..."
$PHP_PATH $ARTISAN_PATH tenjo:cleanup-streams --dry-run --days=7 >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Error: Cleanup command test failed"
    exit 1
fi

echo "✅ Cleanup command test passed"

# Create temporary crontab file
TEMP_CRON="/tmp/tenjo_cron_$(date +%s)"

# Get existing crontab (if any)
crontab -l 2>/dev/null > "$TEMP_CRON" || touch "$TEMP_CRON"

# Remove any existing Tenjo cleanup entries
sed -i.bak '/# Tenjo Stream Cleanup/d' "$TEMP_CRON"
sed -i.bak '/tenjo:cleanup-streams/d' "$TEMP_CRON"

# Add new cron jobs
cat >> "$TEMP_CRON" << EOF

# Tenjo Stream Cleanup - Weekly cleanup (every Sunday at 2 AM)
0 2 * * 0 $PHP_PATH $ARTISAN_PATH tenjo:cleanup-streams --days=7 >> $LARAVEL_ROOT/storage/logs/cleanup.log 2>&1

# Tenjo Stream Cleanup - Daily cleanup for old files (every day at 3 AM)
0 3 * * * $PHP_PATH $ARTISAN_PATH tenjo:cleanup-streams --days=30 >> $LARAVEL_ROOT/storage/logs/cleanup.log 2>&1

# Tenjo Stream Cleanup - Emergency cleanup (every hour if storage > 10GB)
0 * * * * [ \$(du -s $LARAVEL_ROOT/storage/app/private/stream_chunks 2>/dev/null | cut -f1) -gt 10485760 ] && $PHP_PATH $ARTISAN_PATH tenjo:cleanup-streams --days=1 >> $LARAVEL_ROOT/storage/logs/cleanup.log 2>&1
EOF

# Install the new crontab
crontab "$TEMP_CRON"

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo "✅ Cron jobs installed successfully!"
    echo ""
    echo "📅 Scheduled cleanup jobs:"
    echo "  • Weekly cleanup (7+ days old): Sundays at 2:00 AM"
    echo "  • Daily cleanup (30+ days old): Every day at 3:00 AM" 
    echo "  • Emergency cleanup (1+ days old): Hourly if storage > 10GB"
    echo ""
    echo "📝 Logs will be written to: $LARAVEL_ROOT/storage/logs/cleanup.log"
    echo ""
    echo "🔍 To view current cron jobs: crontab -l"
    echo "🗑️  To remove Tenjo cron jobs, run this script with --remove flag"
else
    echo "❌ Error: Failed to install cron jobs"
    exit 1
fi

# Cleanup temporary file
rm -f "$TEMP_CRON" "$TEMP_CRON.bak"

echo "🎉 Setup completed!"
