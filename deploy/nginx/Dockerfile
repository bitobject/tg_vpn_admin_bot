# Multi-arch Nginx image optimized for both ARM64 (M1) and AMD64 (Ubuntu)
FROM nginx:alpine

# Install additional packages
RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/

# Create necessary directories
RUN mkdir -p /var/log/nginx && \
    mkdir -p /etc/nginx/ssl

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"] 