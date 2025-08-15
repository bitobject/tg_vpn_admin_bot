#!/bin/bash

# Initialize Let's Encrypt certificates
# This script should be run once to set up SSL certificates

set -e

# Install certbot if it's not already installed
if ! [ -x "$(command -v certbot)" ]; then
    echo "Certbot not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
fi

# Load environment variables if .env exists
if [ -f .env ]; then
    source .env
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

# Create and enable the Nginx config for the domain
echo "Creating and enabling Nginx config for $DOMAIN..."
sudo cp ancanot.xyz.conf /etc/nginx/sites-available/$DOMAIN.conf
# Update the server_name in the copied config file
sudo sed -i "s/ancanot.xyz www.ancanot.xyz/$DOMAIN www.$DOMAIN/g" /etc/nginx/sites-available/$DOMAIN.conf
# Remove default site if it exists to avoid conflicts
sudo rm -f /etc/nginx/sites-enabled/default
# Enable the new site
sudo ln -sfn /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/$DOMAIN.conf

# Reload Nginx to apply the new site configuration
echo "Reloading Nginx..."
sudo systemctl reload nginx

# Temporarily open firewall ports if ufw is active
UFW_STATUS=$(sudo ufw status | grep -w "Status:" | awk '{print $2}')
if [ "$UFW_STATUS" = "active" ]; then
    echo "Temporarily opening ports 80 and 443 for Certbot..."
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    # Set a trap to close the ports on exit
    trap 'echo "Closing ports 80 and 443..."; sudo ufw delete allow 80/tcp; sudo ufw delete allow 443/tcp' EXIT
fi

# Generate certificate using the Nginx plugin
echo "Generating SSL certificate with Nginx plugin..."
sudo certbot --nginx \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    --redirect

echo "SSL certificate generation completed!"
echo "Your site should now be accessible via HTTPS: https://$DOMAIN" 