#!/bin/bash

# Kind (Kubernetes in Docker) Installation Script for Raspberry Pi 5
# Installs Kind binary

set -euo pipefail

log_info() {
    echo "[KIND] $1"
}

log_info "Starting Kind installation..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "[KIND] ERROR: Docker is required but not installed. Please install Docker first."
    exit 1
fi

# Determine architecture
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64)
        KIND_ARCH="arm64"
        ;;
    x86_64|amd64)
        KIND_ARCH="amd64"
        ;;
    *)
        echo "[KIND] ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Set version (update as needed)
KIND_VERSION="v0.20.0"
KIND_BINARY="/usr/local/bin/kind"

log_info "Installing Kind ${KIND_VERSION} for ${KIND_ARCH}..."

# Download and install Kind
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${KIND_ARCH}"
chmod +x ./kind
mv ./kind "$KIND_BINARY"

# Verify installation
log_info "Verifying Kind installation..."
if "$KIND_BINARY" version; then
    echo "[KIND] Kind installed successfully!"
    "$KIND_BINARY" version
else
    echo "[KIND] ERROR: Kind installation verification failed"
    exit 1
fi

