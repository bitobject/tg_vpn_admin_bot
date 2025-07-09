#!/bin/bash

# Check runtime configuration
# This script verifies that all required environment variables are set

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

# Load environment variables if env_file exists
if [ -f env_file ]; then
    source env_file
    print_info "Loaded environment variables from env_file"
elif [ -f env_file ]; then
    source env_file
    print_info "Loaded environment variables from env_file"
else
    print_warning "No environment file found, checking system environment variables"
fi

print_info "Checking runtime configuration..."

# Required variables
REQUIRED_VARS=(
    "DB_USERNAME"
    "DB_PASSWORD" 
    "DB_HOST"
    "DB_NAME"
    "HOST"
    "SECRET_KEY_BASE"
    "GUARDIAN_SECRET_KEY"
    "CERTBOT_EMAIL"
)

# Optional variables with defaults
OPTIONAL_VARS=(
    "POOL_SIZE:10"
    "PORT:4000"
)

# Check required variables
MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
        print_error "Missing required variable: $var"
    else
        print_success "✓ $var is set"
    fi
done

# Check optional variables
for var_default in "${OPTIONAL_VARS[@]}"; do
    IFS=':' read -r var default_value <<< "$var_default"
    if [ -z "${!var}" ]; then
        print_warning "Optional variable $var not set, will use default: $default_value"
    else
        print_success "✓ $var is set to: ${!var}"
    fi
done

# Check variable formats
print_info "Checking variable formats..."

# Check SECRET_KEY_BASE format
if [ -n "$SECRET_KEY_BASE" ]; then
    if [[ "$SECRET_KEY_BASE" =~ ^[A-Za-z0-9+/]+=*$ ]]; then
        print_success "✓ SECRET_KEY_BASE format is valid"
    else
        print_error "✗ SECRET_KEY_BASE format is invalid (should be base64)"
    fi
fi

# Check GUARDIAN_SECRET_KEY format
if [ -n "$GUARDIAN_SECRET_KEY" ]; then
    if [[ "$GUARDIAN_SECRET_KEY" =~ ^[A-Za-z0-9+/]+=*$ ]]; then
        print_success "✓ GUARDIAN_SECRET_KEY format is valid"
    else
        print_error "✗ GUARDIAN_SECRET_KEY format is invalid (should be base64)"
    fi
fi

# Check email format
if [ -n "$CERTBOT_EMAIL" ]; then
    if [[ "$CERTBOT_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        print_success "✓ CERTBOT_EMAIL format is valid"
    else
        print_error "✗ CERTBOT_EMAIL format is invalid"
    fi
fi

# Check domain format
if [ -n "$HOST" ]; then
    if [[ "$HOST" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        print_success "✓ HOST format is valid"
    else
        print_error "✗ HOST format is invalid"
    fi
fi

# Summary
echo ""
if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    print_success "All required variables are set!"
    print_info "Configuration is ready for deployment."
else
    print_error "Missing ${#MISSING_VARS[@]} required variable(s):"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    print_info "Please set these variables in your env_file or environment."
    exit 1
fi 