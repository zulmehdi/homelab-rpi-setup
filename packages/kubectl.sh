#!/bin/bash

# kubectl Installation Script for Raspberry Pi 5
# Installs kubectl Kubernetes command-line tool

set -euo pipefail

log_info() {
    echo "[KUBECTL] $1"
}

log_info "Starting kubectl installation..."

# Determine architecture
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64)
        KUBECTL_ARCH="arm64"
        ;;
    x86_64|amd64)
        KUBECTL_ARCH="amd64"
        ;;
    *)
        echo "[KUBECTL] ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Set version (update as needed - using latest stable)
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
KUBECTL_BINARY="/usr/local/bin/kubectl"

log_info "Installing kubectl ${KUBECTL_VERSION} for ${KUBECTL_ARCH}..."

# Download kubectl
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

# Download checksum
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl.sha256"

# Verify checksum
log_info "Verifying checksum..."
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install kubectl
chmod +x kubectl
mv kubectl "$KUBECTL_BINARY"
rm kubectl.sha256

# Verify installation
log_info "Verifying kubectl installation..."
if "$KUBECTL_BINARY" version --client; then
    echo "[KUBECTL] kubectl installed successfully!"
    "$KUBECTL_BINARY" version --client
else
    echo "[KUBECTL] ERROR: kubectl installation verification failed"
    exit 1
fi

