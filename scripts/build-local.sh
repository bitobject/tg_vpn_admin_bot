#!/bin/bash

# Local Docker build script for M1 Max (ARM64)
# Fast build for local development and testing

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

print_info "Starting local Docker build for M1 Max (ARM64)..."

# Set image tags
APP_IMAGE="telegram-admin-api:local"
NGINX_IMAGE="telegram-admin-nginx:local"

print_info "Building application image: $APP_IMAGE"

# Build application image with native ARM64 architecture
docker build \
    --platform linux/arm64 \
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

# Build Nginx image with native ARM64 architecture
docker build \
    --platform linux/arm64 \
    --cache-from "$NGINX_IMAGE" \
    --progress=plain \
    --no-cache=false \
    -t "$NGINX_IMAGE" \
    -f nginx/Dockerfile \
    nginx/

print_success "Nginx image built successfully"

print_success "Local build process completed successfully!"
print_info "Images ready for local testing:"
echo "  - $APP_IMAGE (ARM64)"
echo "  - $NGINX_IMAGE (ARM64)"
print_warning "Note: These images are built for ARM64 and cannot be deployed to AMD64 servers" 