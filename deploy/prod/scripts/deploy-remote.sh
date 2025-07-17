#!/bin/bash

# Deploy to remote server via SSH
# This script transfers and deploys the application to a remote server

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

# Default server configuration
DEFAULT_SERVER="vps"
DEFAULT_REMOTE_PATH="/opt/telegram-admin-api"

# Parse command line arguments
SERVER=${1:-$DEFAULT_SERVER}
REMOTE_PATH=${2:-$DEFAULT_REMOTE_PATH}

print_info "Deploying to server: $SERVER"
print_info "Remote path: $REMOTE_PATH"

# Load environment variables
if [ -f .env ]; then
    source .env
    print_info "Loaded environment variables from .env"
else
    print_error ".env not found!"
    exit 1
fi

# Check if images exist
if [ ! -f "images/app.tar.gz" ] || [ ! -f "images/nginx.tar.gz" ]; then
    print_error "Docker images not found. Please run ./scripts/build.sh first."
    exit 1
fi

print_info "Starting deployment process..."

# Create remote directory structure
print_info "Creating remote directory structure..."
ssh "$SERVER" "mkdir -p $REMOTE_PATH/{images,nginx,scripts,certbot,logs}"

# Transfer images
print_info "Transferring Docker images..."
scp images/*.tar.gz "$SERVER:$REMOTE_PATH/images/"

# Transfer configuration files
print_info "Transferring configuration files..."
scp .env "$SERVER:$REMOTE_PATH/"
scp docker-compose.prod.yml "$SERVER:$REMOTE_PATH/docker-compose.yml"
scp -r nginx/ "$SERVER:$REMOTE_PATH/"
scp -r scripts/ "$SERVER:$REMOTE_PATH/"

# Make scripts executable on remote server
print_info "Making scripts executable on remote server..."
ssh "$SERVER" "chmod +x $REMOTE_PATH/scripts/*.sh"

# Load images on remote server
print_info "Loading Docker images on remote server..."
ssh "$SERVER" "cd $REMOTE_PATH && docker load < images/app.tar.gz"
ssh "$SERVER" "cd $REMOTE_PATH && docker load < images/nginx.tar.gz"

# Stop existing containers if running
print_info "Stopping existing containers..."
ssh "$SERVER" "cd $REMOTE_PATH && docker compose --env-file .env down || true"

# Start services
print_info "Starting services..."
ssh "$SERVER" "cd $REMOTE_PATH && docker compose --env-file .env up -d"

# Wait for services to start
print_info "Waiting for services to start..."
sleep 30

# Check service health
print_info "Checking service health..."

# Check if containers are running
ssh "$SERVER" "cd $REMOTE_PATH && docker compose --env-file .env ps"

# Check application health
if ssh "$SERVER" "curl -f -s http://localhost:4000/health > /dev/null 2>&1"; then
    print_success "Application is healthy"
else
    print_warning "Application health check failed (this is normal during initial setup)"
fi

# Check nginx health
if ssh "$SERVER" "curl -f -s http://localhost/health > /dev/null 2>&1"; then
    print_success "Nginx is healthy"
else
    print_warning "Nginx health check failed (this is normal during initial setup)"
fi

print_success "Deployment completed successfully!"
print_info "Your application should be available at: https://$HOST"
print_info "To check logs: ssh $SERVER 'cd $REMOTE_PATH && docker-compose logs -f'"
print_info "To restart services: ssh $SERVER 'cd $REMOTE_PATH && docker-compose restart'" 