# Makefile for Telegram Admin API deployment

.PHONY: help build build-local build-multiarch deploy clean logs

# Default target
help:
	@echo "Available commands:"
	@echo "  build-local     - Build for local M1 Max (ARM64) - fast"
	@echo "  build-multiarch - Build for both ARM64 and AMD64 - production ready"
	@echo "  build           - Build for AMD64 only - for Ubuntu server"
	@echo "  deploy          - Deploy to remote server"
	@echo "  clean           - Clean up Docker images and containers"
	@echo "  logs            - Show application logs"

# Build for local development (M1 Max - ARM64)
build-local:
	@echo "Building for local M1 Max (ARM64)..."
	./scripts/build-local.sh

# Build for production (multi-architecture)
build-multiarch:
	@echo "Building multi-architecture images..."
	./scripts/build-multiarch.sh

# Build for Ubuntu server (AMD64 only)
build:
	@echo "Building for Ubuntu server (AMD64)..."
	./scripts/build-fast.sh

# Deploy to remote server
deploy:
	@echo "Deploying to remote server..."
	./scripts/deploy.sh

# Clean up
clean:
	@echo "Cleaning up Docker resources..."
	docker system prune -f
	docker image prune -f
	rm -rf images/*.tar.gz

# Show logs
logs:
	@echo "Showing application logs..."
	docker-compose logs -f app

# Show server status
status:
	@echo "Checking server status..."
	@ssh vps "cd /opt/telegram-admin-api && docker compose ps"

# Restart services
restart:
	@echo "Restarting services..."
	@ssh vps "cd /opt/telegram-admin-api && docker compose restart"

# Stop services
stop:
	@echo "Stopping services..."
	@ssh vps "cd /opt/telegram-admin-api && docker compose down"

# Start services
start:
	@echo "Starting services..."
	@ssh vps "cd /opt/telegram-admin-api && docker compose up -d" 