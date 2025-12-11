#!/bin/bash

# GitLab Runner Installation Script for Raspberry Pi 5
# Installs GitLab Runner

set -euo pipefail

log_info() {
    echo "[GITLAB-RUNNER] $1"
}

log_info "Starting GitLab Runner installation..."

# Determine architecture
ARCH=$(uname -m)
case $ARCH in
    aarch64|arm64)
        RUNNER_ARCH="arm64"
        ;;
    x86_64|amd64)
        RUNNER_ARCH="amd64"
        ;;
    *)
        echo "[GITLAB-RUNNER] ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# GitLab Runner download URL
RUNNER_VERSION="latest"
RUNNER_URL="https://gitlab-runner-downloads.s3.amazonaws.com/${RUNNER_VERSION}/deb/gitlab-runner_${RUNNER_ARCH}.deb"
RUNNER_DEB="/tmp/gitlab-runner.deb"

log_info "Downloading GitLab Runner for ${RUNNER_ARCH}..."

# Download GitLab Runner
curl -L "$RUNNER_URL" -o "$RUNNER_DEB"

# Install GitLab Runner
log_info "Installing GitLab Runner..."
dpkg -i "$RUNNER_DEB" || apt-get install -f -y

# Clean up
rm -f "$RUNNER_DEB"

# Verify installation
log_info "Verifying GitLab Runner installation..."
if gitlab-runner --version; then
    echo "[GITLAB-RUNNER] GitLab Runner installed successfully!"
    gitlab-runner --version
    
    log_info "To register GitLab Runner, use:"
    log_info "  sudo gitlab-runner register"
    log_info "You'll need your GitLab URL and registration token from your GitLab instance."
else
    echo "[GITLAB-RUNNER] ERROR: GitLab Runner installation verification failed"
    exit 1
fi

# Note: GitLab Runner registration requires manual configuration
log_info "NOTE: GitLab Runner needs to be registered with your GitLab instance."
log_info "See: https://docs.gitlab.com/runner/register/"

