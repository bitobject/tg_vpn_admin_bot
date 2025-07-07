#!/bin/bash

# Setup cron job for automatic certificate renewal
# This script adds a cron job to renew Let's Encrypt certificates daily

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Get the absolute path to the deploy directory
DEPLOY_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RENEW_SCRIPT="$DEPLOY_DIR/scripts/renew-certs.sh"
LOG_FILE="$DEPLOY_DIR/logs/cert-renewal.log"

print_status "Setting up automatic certificate renewal..."

# Create logs directory if it doesn't exist
mkdir -p "$DEPLOY_DIR/logs"

# Create the cron job entry
CRON_JOB="0 12 * * * cd $DEPLOY_DIR && $RENEW_SCRIPT >> $LOG_FILE 2>&1"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "$RENEW_SCRIPT"; then
    print_status "Cron job already exists. Updating..."
    # Remove existing cron job
    crontab -l 2>/dev/null | grep -v "$RENEW_SCRIPT" | crontab -
fi

# Add new cron job
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

print_status "Cron job added successfully!"
print_status "Certificate renewal will run daily at 12:00 PM"
print_status "Logs will be saved to: $LOG_FILE"

# Show current cron jobs
print_status "Current cron jobs:"
crontab -l 