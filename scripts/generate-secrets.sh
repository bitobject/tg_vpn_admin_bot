#!/bin/bash

# Generate secret keys for the application
# This script generates SECRET_KEY_BASE and GUARDIAN_SECRET_KEY

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

print_info "Generating secret keys for the application..."

# Check if we're in the right directory
if [ ! -f "../mix.exs" ]; then
    print_info "Please run this script from the deploy directory"
    exit 1
fi

# Generate SECRET_KEY_BASE
print_info "Generating SECRET_KEY_BASE..."
SECRET_KEY_BASE=$(cd .. && mix phx.gen.secret)
print_success "SECRET_KEY_BASE generated"

# Generate GUARDIAN_SECRET_KEY
print_info "Generating GUARDIAN_SECRET_KEY..."
GUARDIAN_SECRET_KEY=$(cd .. && mix phx.gen.secret)
print_success "GUARDIAN_SECRET_KEY generated"

# Create env_file if it doesn't exist
if [ ! -f "env_file" ]; then
    print_info "Creating env_file from template..."
    cp env.example env_file
fi

# Update env_file with generated keys
print_info "Updating env_file with generated keys..."

# Update SECRET_KEY_BASE
sed -i.bak "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET_KEY_BASE/" env_file

# Update GUARDIAN_SECRET_KEY
sed -i.bak "s/GUARDIAN_SECRET_KEY=.*/GUARDIAN_SECRET_KEY=$GUARDIAN_SECRET_KEY/" env_file

# Remove backup file
rm env_file.bak

print_success "Secret keys generated and saved to env_file"
print_info "Please review and update other variables in env_file before deployment"
print_info "Required variables to set:"
echo "  - DB_PASSWORD"
echo "  - CERTBOT_EMAIL"
echo "  - HOST (if different from body-architect.ru)" 