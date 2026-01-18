#!/bin/bash
# Keepalived notification script - Fault state
# This script is executed when this node detects a fault

echo "[$(date)] - Node $(hostname) detected FAULT state" >> /var/log/keepalived-transitions.log

# Optional: Send notification via email or monitoring system
# mail -s "Keepalived FAULT on $(hostname)" admin@example.com < /dev/null

exit 0
