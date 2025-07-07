#!/bin/bash

# Complete setup script for Telegram Admin API deployment
# This script handles the entire setup process from scratch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info "=== Telegram Admin API - Complete Setup ==="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Docker and Docker Compose are available"

# Check if we're in the right directory
if [ ! -f "../mix.exs" ]; then
    print_error "Please run this script from the deploy directory"
    exit 1
fi

# Step 1: Generate secret keys
print_info "Step 1: Generating secret keys..."
./scripts/generate-secrets.sh

# Step 2: Check and create env_file
if [ ! -f "env_file" ]; then
    print_error "env_file not found. Please run generate-secrets.sh first."
    exit 1
fi

# Step 3: Check runtime configuration
print_info "Step 3: Checking runtime configuration..."
./scripts/check-config.sh

print_success "Runtime configuration is valid"

# Step 4: Create necessary directories
print_info "Step 4: Creating necessary directories..."
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p postgres/init
mkdir -p logs

print_success "Directories created"

# Step 5: Make scripts executable
print_info "Step 5: Making scripts executable..."
chmod +x scripts/*.sh

print_success "Scripts are executable"

# Step 6: Build Docker images
print_info "Step 6: Building Docker images..."
docker-compose build --no-cache

print_success "Docker images built"

# Step 7: Initialize SSL certificates
print_info "Step 7: Initializing SSL certificates..."
if [ ! -d "certbot/conf/live/$HOST" ]; then
    ./scripts/init-letsencrypt.sh "$HOST"
else
    print_info "SSL certificates already exist. Checking validity..."
    ./scripts/check-certs.sh
fi

# Step 8: Start services
print_info "Step 8: Starting services..."
docker-compose up -d

print_success "Services started"

# Step 9: Wait for services to be ready
print_info "Step 9: Waiting for services to be ready..."
sleep 30

# Step 10: Check service health
print_info "Step 10: Checking service health..."

# Check nginx
if curl -f -s http://localhost/health > /dev/null 2>&1; then
    print_success "Nginx is healthy"
else
    print_warning "Nginx health check failed (this is normal during initial setup)"
fi

# Check application
if curl -f -s https://$HOST/health > /dev/null 2>&1; then
    print_success "Application is healthy"
else
    print_warning "Application health check failed (this is normal during initial setup)"
fi

# Check database
if docker-compose exec postgres pg_isready -U $DB_USERNAME > /dev/null 2>&1; then
    print_success "Database is healthy"
else
    print_warning "Database health check failed (this is normal during initial setup)"
fi

# Step 11: Setup automatic certificate renewal
print_info "Step 11: Setting up automatic certificate renewal..."
./scripts/setup-cron.sh

# Step 12: Show final status
print_info "Step 12: Final status check..."
docker-compose ps

print_success "=== Setup completed successfully! ==="
print_info "Your application should be available at: https://$HOST"
print_info "API documentation: https://$HOST/api/docs"
print_info ""
print_info "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Check certificates: ./scripts/check-certs.sh"
echo "  - Renew certificates: ./scripts/renew-certs.sh"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo ""
print_info "Next steps:"
echo "  1. Test your application at https://$HOST"
echo "  2. Set up monitoring and alerts"
echo "  3. Configure backups"
echo "  4. Set up CI/CD pipeline" 