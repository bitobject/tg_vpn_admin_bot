#!/bin/bash

# Initialize Let's Encrypt certificates
# This script should be run once to set up SSL certificates

set -e

# Load environment variables if env_file exists
if [ -f env_file ]; then
    source env_file
fi

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 body-architect.ru"
    exit 1
fi

DOMAIN=$1
EMAIL=${CERTBOT_EMAIL:-"admin@$DOMAIN"}

echo "Initializing Let's Encrypt certificates for domain: $DOMAIN"
echo "Email: $EMAIL"

# Create necessary directories
mkdir -p certbot/conf
mkdir -p certbot/www

# Create a temporary nginx configuration for certificate generation
cat > nginx/conf.d/temp.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 "Certificate generation in progress...";
        add_header Content-Type text/plain;
    }
}
EOF

# Start nginx with temporary configuration
echo "Starting nginx with temporary configuration..."
docker-compose up -d nginx

# Wait for nginx to start
echo "Waiting for nginx to start..."
sleep 10

# Generate certificate
echo "Generating SSL certificate..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN

# Remove temporary configuration
rm nginx/conf.d/temp.conf

# Restart nginx with proper configuration
echo "Restarting nginx with SSL configuration..."
docker-compose restart nginx

echo "SSL certificate generation completed!"
echo "Your site should now be accessible via HTTPS: https://$DOMAIN" 