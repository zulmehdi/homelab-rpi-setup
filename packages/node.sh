#!/bin/bash

# Node.js Installation Script for Raspberry Pi 5
# Installs Node.js using NVM (Node Version Manager)

set -euo pipefail

log_info() {
    echo "[NODE] $1"
}

log_info "Starting Node.js installation..."

# Determine NVM location
if [ -s "/usr/local/nvm/nvm.sh" ]; then
    NVM_DIR="/usr/local/nvm"
elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    NVM_DIR="$HOME/.nvm"
else
    echo "[NODE] ERROR: NVM is required but not installed. Please install NVM first."
    exit 1
fi

# Source NVM
export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Check if Node.js is already installed
if command -v node &> /dev/null && node --version &> /dev/null; then
    log_info "Node.js is already installed. Current version:"
    node --version
    npm --version
    exit 0
fi

# Set Node.js version (LTS version - update as needed)
NODE_VERSION="lts/*"

log_info "Installing Node.js ${NODE_VERSION} using NVM..."

# Install Node.js using NVM
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

# Verify installation
log_info "Verifying Node.js installation..."
if command -v node &> /dev/null && node --version &> /dev/null; then
    echo "[NODE] Node.js installed successfully!"
    node --version
    npm --version
else
    echo "[NODE] ERROR: Node.js installation verification failed"
    exit 1
fi
