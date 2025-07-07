#!/bin/bash

# Build Docker images on remote server
# This avoids cross-platform compilation issues on M1 Mac

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

print_info "Starting remote build on server..."

# Set server details
SERVER="vps"
REMOTE_DIR="/opt/telegram-admin-api"

print_info "Copying project files to server..."

# Create remote directory and copy files
ssh "$SERVER" "mkdir -p $REMOTE_DIR"
rsync -avz --exclude='.git' --exclude='_build' --exclude='deps' --exclude='node_modules' \
    ../ "$SERVER:$REMOTE_DIR/"

print_info "Copying environment file to server..."
scp env_file "$SERVER:$REMOTE_DIR/"

print_info "Building Docker images on server..."

# Build on server
ssh "$SERVER" "cd $REMOTE_DIR/deploy && \
    docker build \
        --build-arg SECRET_KEY_BASE='$SECRET_KEY_BASE' \
        --build-arg GUARDIAN_SECRET_KEY='$GUARDIAN_SECRET_KEY' \
        -t telegram-admin-api:latest \
        -f Dockerfile .. && \
    docker build \
        -t telegram-admin-nginx:latest \
        -f nginx/Dockerfile nginx/"

print_success "Images built successfully on server!"

print_info "Saving images to tar files on server..."
ssh "$SERVER" "cd $REMOTE_DIR/deploy && \
    mkdir -p images && \
    docker save telegram-admin-api:latest | gzip > images/app.tar.gz && \
    docker save telegram-admin-nginx:latest | gzip > images/nginx.tar.gz"

print_info "Downloading images from server..."
scp "$SERVER:$REMOTE_DIR/deploy/images/*.tar.gz" images/

print_success "Remote build process completed successfully!"
print_info "Images ready for deployment:"
echo "  - telegram-admin-api:latest (AMD64)"
echo "  - telegram-admin-nginx:latest (AMD64)" 