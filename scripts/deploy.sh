#!/bin/bash

# Deployment script for Telegram Admin API
# This script handles the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if env_file exists
if [ ! -f env_file ]; then
    print_error "env_file not found! Please copy env.example to env_file and configure it."
    exit 1
fi

# Load environment variables
source env_file

# Check required variables
if [ -z "$HOST" ] || [ -z "$CERTBOT_EMAIL" ]; then
    print_error "Required environment variables are missing. Please check your .env file."
    exit 1
fi

print_status "Starting deployment for domain: $HOST"

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p postgres/init
mkdir -p logs

# Check if certificates exist and are valid
print_status "Checking SSL certificates..."
if ./scripts/check-certs.sh "$HOST" > /dev/null 2>&1; then
    print_status "SSL certificates are valid and ready to use."
else
    print_warning "SSL certificates not found or invalid. Running certificate initialization..."
    ./scripts/init-letsencrypt.sh "$HOST"
fi

# Build and start services
print_status "Building and starting services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service health
print_status "Checking service health..."

# Check nginx
if curl -f -s http://localhost/health > /dev/null; then
    print_status "Nginx is healthy"
else
    print_error "Nginx health check failed"
    docker-compose logs nginx
    exit 1
fi

# Check application
if curl -f -s https://$HOST/health > /dev/null; then
    print_status "Application is healthy"
else
    print_error "Application health check failed"
    docker-compose logs app
    exit 1
fi

# Check database
if docker-compose exec postgres pg_isready -U $DB_USERNAME > /dev/null 2>&1; then
    print_status "Database is healthy"
else
    print_error "Database health check failed"
    docker-compose logs postgres
    exit 1
fi

print_status "Deployment completed successfully!"
print_status "Your application is now available at: https://$HOST"
print_status "API documentation: https://$HOST/api/docs"

# Show service status
print_status "Service status:"
docker-compose ps 