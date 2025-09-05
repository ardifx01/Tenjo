#!/bin/bash
# Start Laravel server script

echo "Starting Laravel server..."
cd /Users/yapi/Adi/App-Dev/Tenjo/dashboard

# Check if artisan exists
if [ ! -f "artisan" ]; then
    echo "Error: artisan file not found"
    exit 1
fi

# Start server
echo "Starting server on http://127.0.0.1:8000"
php artisan serve --host=127.0.0.1 --port=8000
