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
docker buildx build \
    --platform linux/amd64 \
    --load \
    -t "$APP_IMAGE" \
    -f Dockerfile \
    ..

print_success "Application image built successfully"

print_info "Building Nginx image for linux/amd64: $NGINX_IMAGE"

docker buildx build \
    --platform linux/amd64 \
    --load \
    -t "$NGINX_IMAGE" \
    -f nginx/Dockerfile \
    nginx/

print_success "Nginx image built successfully"

# --- Остальная часть скрипта остается без изменений ---

# Создаем директорию для образов, если ее нет
mkdir -p images

print_info "Saving images to tar files..."

docker save "$APP_IMAGE" | gzip > "images/app.tar.gz"
docker save "$NGINX_IMAGE" | gzip > "images/nginx.tar.gz"

print_success "Images saved to images/ directory"

print_info "Image sizes:"
ls -lh images/*.tar.gz

print_success "Build process completed successfully!"
print_info "Images ready for deployment:"
echo "  - $APP_IMAGE"
echo "  - $NGINX_IMAGE"