#!/bin/bash
launchctl stop com.tenjo.client
launchctl unload ~/Library/LaunchAgents/com.tenjo.client.plist
echo "Tenjo Client service stopped"
