#!/bin/bash

# Renew Let's Encrypt certificates
# This script should be run via cron job for automatic renewal

set -e

echo "Starting certificate renewal process..."

# Renew certificates
sudo certbot renew

# Check if certificates were renewed
if sudo certbot certificates | grep -q "VALID"; then
    echo "Certificates renewed successfully!"
    
    # Reload nginx to use new certificates
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    
    echo "Certificate renewal completed successfully!"
else
    echo "No certificates were renewed or renewal failed!"
    exit 1
fi 