#!/bin/bash

# Build Docker images locally
# This script builds all necessary Docker images for deployment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# УБРАНА ЗАГРУЗКА ПЕРЕМЕННЫХ, ОНИ НЕ НУЖНЫ ДЛЯ СБОРКИ

print_info "Starting Docker image build process..."

# Используем buildx, современный сборщик Docker
export DOCKER_BUILDKIT=1

# Имена и теги образов
APP_IMAGE="telegram-admin-api:latest"
NGINX_IMAGE="telegram-admin-nginx:latest"

print_info "Building application image for linux/amd64: $APP_IMAGE"

# ИЗМЕНЕНО: Используем 'docker buildx build'
# --load: загружает собранный образ в локальный Docker daemon, чтобы 'docker save' мог его найти
# УБРАНЫ: --build-arg с секретами
pushd ../..

# Build app image

docker buildx build \
    --load \
    -t "$APP_IMAGE" \
    -f deploy/prod/Dockerfile \
    .

popd

print_success "Application image built successfully"

print_info "Building Nginx image: $NGINX_IMAGE"

docker build -t "$NGINX_IMAGE" -f nginx/Dockerfile nginx/

print_success "Nginx image built successfully"

print_success "Build process completed successfully!"
print_info "Images ready for deployment:"
echo "  - $APP_IMAGE"
echo "  - $NGINX_IMAGE"
echo "  - $NGINX_IMAGE"