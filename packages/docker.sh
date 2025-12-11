#!/bin/bash

# Docker Installation Script for Raspberry Pi 5
# Installs Docker Engine and Docker Compose

set -euo pipefail

log_info() {
    echo "[DOCKER] $1"
}

# Check if Docker is already installed
if command -v docker &> /dev/null && docker --version &> /dev/null && docker compose version &> /dev/null; then
    log_info "Docker is already installed. Skipping installation."
    docker --version
    docker compose version
    exit 0
fi

log_info "Starting Docker installation..."

# Clean up any existing Docker repository configurations thoroughly
log_info "Cleaning up existing Docker repository configurations..."
# Remove all Docker-related source files
rm -f /etc/apt/sources.list.d/docker*.list
# Remove all Docker GPG keys
rm -f /etc/apt/keyrings/docker*.gpg
rm -f /etc/apt/keyrings/docker*.asc
rm -f /usr/share/keyrings/docker*.gpg
# Clean up any Docker repository entries from main sources.list
sed -i '/download\.docker\.com/d' /etc/apt/sources.list 2>/dev/null || true

# Remove old versions if they exist
log_info "Removing old Docker versions..."
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install prerequisites
log_info "Installing prerequisites..."
apt-get update -qq || true
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
log_info "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
log_info "Adding Docker repository..."
ARCH=$(dpkg --print-architecture)
CODENAME=$(lsb_release -cs)
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list

# Update package lists (handle GPG conflicts)
log_info "Updating package lists..."
# Temporarily disable exit on error to check for conflicts
set +e
UPDATE_OUTPUT=$(apt-get update -qq 2>&1)
UPDATE_EXIT=$?
set -e

if [ $UPDATE_EXIT -ne 0 ] && echo "$UPDATE_OUTPUT" | grep -q "Conflicting values"; then
    log_info "Detected GPG key conflict, attempting to resolve..."
    # Check for conflicting signed-by references in existing sources
    CONFLICTING_SOURCES=$(grep -r "signed-by.*docker" /etc/apt/sources.list.d/ 2>/dev/null | grep -v "docker.gpg" || true)
    if [ -n "$CONFLICTING_SOURCES" ]; then
        log_info "Found conflicting Docker repository entries, removing them..."
        # Remove all Docker list files
        rm -f /etc/apt/sources.list.d/docker*.list
        # Re-add clean Docker repository
        echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list
        # Try updating again
        set +e
        apt-get update -qq
        UPDATE_EXIT=$?
        set -e
        if [ $UPDATE_EXIT -ne 0 ]; then
            log_info "Warning: apt-get update still has issues, but continuing with installation..."
        fi
    fi
elif [ $UPDATE_EXIT -ne 0 ]; then
    log_info "Warning: apt-get update had issues (exit code: $UPDATE_EXIT), but continuing..."
fi

# Install Docker Engine
log_info "Installing Docker Engine..."
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

