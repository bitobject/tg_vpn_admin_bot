#!/bin/bash

# Fast Docker build script using BuildKit
# This script builds Docker images with maximum optimization

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Enable BuildKit for faster builds
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Load environment variables
if [ -f env_file ]; then
    source env_file
    print_info "Loaded environment variables from env_file"
else
    print_error "env_file not found!"
    exit 1
fi

print_info "Starting fast Docker build with BuildKit..."

# Set image tags
APP_IMAGE="telegram-admin-api:latest"
NGINX_IMAGE="telegram-admin-nginx:latest"

print_info "Building application image: $APP_IMAGE"

# Build application image with BuildKit optimizations
docker build \
    --platform linux/amd64 \
    --build-arg SECRET_KEY_BASE="$SECRET_KEY_BASE" \
    --build-arg GUARDIAN_SECRET_KEY="$GUARDIAN_SECRET_KEY" \
    --cache-from "$APP_IMAGE" \
    --progress=plain \
    --no-cache=false \
    -t "$APP_IMAGE" \
    -f Dockerfile \
    ..

print_success "Application image built successfully"

print_info "Building Nginx image: $NGINX_IMAGE"

# Build Nginx image with BuildKit optimizations
docker build \
    --platform linux/amd64 \
    --cache-from "$NGINX_IMAGE" \
    --progress=plain \
    --no-cache=false \
    -t "$NGINX_IMAGE" \
    -f nginx/Dockerfile \
    nginx/

print_success "Nginx image built successfully"

# Save images to tar files for transfer
print_info "Saving images to tar files..."

docker save "$APP_IMAGE" | gzip > "images/app.tar.gz"
docker save "$NGINX_IMAGE" | gzip > "images/nginx.tar.gz"

print_success "Images saved to images/ directory"

# Show image sizes
print_info "Image sizes:"
ls -lh images/*.tar.gz

print_success "Fast build process completed successfully!"
print_info "Images ready for deployment:"
echo "  - $APP_IMAGE"
echo "  - $NGINX_IMAGE" 