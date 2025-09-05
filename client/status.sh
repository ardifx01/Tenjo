#!/bin/bash
if launchctl list | grep -q com.tenjo.client; then
    echo "✓ Tenjo Client is running"
    echo "Logs: $(dirname "$0")/logs/"
else
    echo "✗ Tenjo Client is not running"
fi
