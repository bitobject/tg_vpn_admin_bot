#!/bin/bash

# Multi-architecture Docker build script using Docker Buildx
# Optimized for M1 Max (ARM64) and Ubuntu (AMD64)

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

# Enable BuildKit
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

print_info "Setting up multi-architecture build environment..."

# Create and use buildx builder if it doesn't exist
if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
    print_info "Creating multi-architecture builder..."
    docker buildx create --name multiarch-builder --use
fi

# Use the multi-arch builder
docker buildx use multiarch-builder

print_info "Starting multi-architecture Docker build..."

# Set image tags
APP_IMAGE="telegram-admin-api:latest"
NGINX_IMAGE="telegram-admin-nginx:latest"

print_info "Building application image: $APP_IMAGE"

# Build application image for multiple architectures
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg SECRET_KEY_BASE="$SECRET_KEY_BASE" \
    --build-arg GUARDIAN_SECRET_KEY="$GUARDIAN_SECRET_KEY" \
    --cache-from type=local,src=/tmp/.buildx-cache \
    --cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
    --progress=plain \
    --tag "$APP_IMAGE" \
    --file Dockerfile \
    --load \
    ..

print_success "Application image built successfully"

print_info "Building Nginx image: $NGINX_IMAGE"

# Build Nginx image for multiple architectures
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --cache-from type=local,src=/tmp/.buildx-cache \
    --cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
    --progress=plain \
    --tag "$NGINX_IMAGE" \
    --file nginx/Dockerfile \
    --load \
    nginx/

print_success "Nginx image built successfully"

# Save images to tar files for transfer
print_info "Saving images to tar files..."

# Create images directory if it doesn't exist
mkdir -p images

docker save "$APP_IMAGE" | gzip > "images/app.tar.gz"
docker save "$NGINX_IMAGE" | gzip > "images/nginx.tar.gz"

print_success "Images saved to images/ directory"

# Show image sizes
print_info "Image sizes:"
ls -lh images/*.tar.gz

print_success "Multi-architecture build process completed successfully!"
print_info "Images ready for deployment:"
echo "  - $APP_IMAGE (supports AMD64 and ARM64)"
echo "  - $NGINX_IMAGE (supports AMD64 and ARM64)" 