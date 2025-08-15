#!/bin/bash
# This script installs Docker Engine and Docker Compose on Ubuntu.
# It follows the official Docker installation guide.

set -e

echo "🚀 Starting Docker installation..."

# 1. Set up the repository
echo "Updating apt package index and installing dependencies..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Set up the repository
echo "Setting up the Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Install Docker Engine
echo "Installing Docker Engine, CLI, and Compose plugin..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Add the current user to the 'docker' group
echo "Adding current user to the 'docker' group to run Docker without sudo..."
sudo usermod -aG docker $USER

echo "✅ Docker installation completed successfully!"
echo "You need to log out and log back in for the group changes to take effect."
echo "After that, you can test your installation by running: docker run hello-world"
