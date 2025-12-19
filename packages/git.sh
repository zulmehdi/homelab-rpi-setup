#!/bin/bash

# Git Installation Script for Raspberry Pi 5
# Installs Git version control system

set -euo pipefail

log_info() {
    echo "[GIT] $1"
}

# Check if Git is already installed
if command -v git &> /dev/null && git --version &> /dev/null; then
    log_info "Git is already installed. Current version:"
    git --version
    exit 0
fi

log_info "Starting Git installation..."

# Update package lists
log_info "Updating package lists..."
apt-get update -qq

# Install Git
log_info "Installing Git..."
apt-get install -y git

# Verify installation
log_info "Verifying Git installation..."
if command -v git &> /dev/null && git --version &> /dev/null; then
    echo "[GIT] Git installed successfully!"
    git --version
else
    echo "[GIT] ERROR: Git installation verification failed"
    exit 1
fi
