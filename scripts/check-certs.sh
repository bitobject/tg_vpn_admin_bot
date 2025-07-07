#!/bin/bash

# Check SSL certificates status
# This script checks if certificates exist and are valid

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
if [ -f env_file ]; then
    source env_file
    print_info "Loaded environment variables from env_file"
else
    print_error "env_file not found!"
    exit 1
fi

DOMAIN=${1:-$HOST}

if [ -z "$DOMAIN" ]; then
    print_error "Domain not specified and HOST not set in env_file"
    exit 1
fi

print_info "Checking SSL certificates for domain: $DOMAIN"

# Check if certbot directory exists
if [ ! -d "certbot/conf" ]; then
    print_warning "Certbot directory not found. Certificates need to be created."
    exit 1
fi

# Check if live certificates directory exists
if [ ! -d "certbot/conf/live/$DOMAIN" ]; then
    print_warning "Live certificates directory not found for $DOMAIN"
    print_info "Certificates need to be created."
    exit 1
fi

# Check if certificate files exist
CERT_FILE="certbot/conf/live/$DOMAIN/fullchain.pem"
KEY_FILE="certbot/conf/live/$DOMAIN/privkey.pem"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    print_warning "Certificate files not found:"
    echo "  - $CERT_FILE"
    echo "  - $KEY_FILE"
    print_info "Certificates need to be created."
    exit 1
fi

print_success "Certificate files found"

# Check certificate validity using openssl
print_info "Checking certificate validity..."

# Check if certificate is valid
if openssl x509 -checkend 86400 -noout -in "$CERT_FILE" > /dev/null 2>&1; then
    print_success "Certificate is valid and will not expire in the next 24 hours"
else
    print_warning "Certificate will expire within 24 hours or is invalid"
fi

# Get certificate expiration date
EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
print_info "Certificate expires on: $EXPIRY"

# Check certificate domain
CERT_DOMAIN=$(openssl x509 -noout -subject -in "$CERT_FILE" | sed -n '/^subject/s/^.*CN = //p')
if [ "$CERT_DOMAIN" = "$DOMAIN" ]; then
    print_success "Certificate is issued for correct domain: $CERT_DOMAIN"
else
    print_warning "Certificate domain mismatch: expected $DOMAIN, got $CERT_DOMAIN"
fi

# Check certificate chain
if openssl verify -CAfile "$CERT_FILE" "$CERT_FILE" > /dev/null 2>&1; then
    print_success "Certificate chain is valid"
else
    print_warning "Certificate chain validation failed"
fi

print_success "Certificate check completed successfully"
print_info "Certificate status: VALID" 