#!/bin/bash

# Python Installation Script for Raspberry Pi 5
# Installs Python 3 and pip

set -euo pipefail

log_info() {
    echo "[PYTHON] $1"
}

# Check if Python 3 is already installed
if command -v python3 &> /dev/null && python3 --version &> /dev/null; then
    log_info "Python 3 is already installed. Current version:"
    python3 --version
    if command -v pip3 &> /dev/null; then
        pip3 --version
    fi
    exit 0
fi

log_info "Starting Python 3 installation..."

# Update package lists
log_info "Updating package lists..."
apt-get update -qq

# Install Python 3 and pip
log_info "Installing Python 3 and pip..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev

# Upgrade pip to latest version
log_info "Upgrading pip to latest version..."
python3 -m pip install --upgrade pip

# Verify installation
log_info "Verifying Python installation..."
if command -v python3 &> /dev/null && python3 --version &> /dev/null; then
    echo "[PYTHON] Python 3 installed successfully!"
    python3 --version
    pip3 --version
else
    echo "[PYTHON] ERROR: Python 3 installation verification failed"
    exit 1
fi
