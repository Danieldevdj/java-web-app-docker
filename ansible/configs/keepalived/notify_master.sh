#!/bin/bash
# Keepalived notification script - Master state
# This script is executed when this node becomes MASTER

echo "[$(date)] - Node $(hostname) transitioned to MASTER state" >> /var/log/keepalived-transitions.log

# Optional: Send notification via email or monitoring system
# mail -s "Keepalived MASTER on $(hostname)" admin@example.com < /dev/null

exit 0
