#!/bin/bash
# Keepalived notification script - Backup state
# This script is executed when this node transitions to BACKUP state

echo "[$(date)] - Node $(hostname) transitioned to BACKUP state" >> /var/log/keepalived-transitions.log

# Optional: Send notification via email or monitoring system
# mail -s "Keepalived BACKUP on $(hostname)" admin@example.com < /dev/null

exit 0
