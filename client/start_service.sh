#!/bin/bash
launchctl load ~/Library/LaunchAgents/com.tenjo.client.plist
launchctl start com.tenjo.client
echo "Tenjo Client service started"
