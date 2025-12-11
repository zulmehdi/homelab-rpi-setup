#!/bin/bash

# Docker Installation Script for Raspberry Pi 5
# Installs Docker Engine and Docker Compose

set -euo pipefail

log_info() {
    echo "[DOCKER] $1"
}

log_info "Starting Docker installation..."

# Remove old versions if they exist
log_info "Removing old Docker versions..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install prerequisites
log_info "Installing prerequisites..."
apt-get update -qq
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
log_info "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Add Docker repository
log_info "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
log_info "Installing Docker Engine..."
apt-get update -qq
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (if not root)
if [ "$EUID" -ne 0 ] && id "$SUDO_USER" &>/dev/null; then
    log_info "Adding $SUDO_USER to docker group..."
    usermod -aG docker "$SUDO_USER"
fi

# Enable and start Docker service
log_info "Enabling Docker service..."
systemctl enable docker
systemctl start docker

# Verify installation
log_info "Verifying Docker installation..."
if docker --version && docker compose version; then
    echo "[DOCKER] Docker installed successfully!"
    docker --version
    docker compose version
else
    echo "[DOCKER] ERROR: Docker installation verification failed"
    exit 1
fi

