#!/bin/bash

# Network Share Mount Script Example
# This is a template - customize for your specific network share

set -euo pipefail

log_info() {
    echo "[MOUNT-NETWORK] $1"
}

# Configuration - CUSTOMIZE THESE VALUES
SHARE_PATH="//192.168.1.100/share"      # Change to your network share path
MOUNT_POINT="/data/network-share"       # Change to your desired mount point
USERNAME="user"                         # Optional: username for authentication
PASSWORD="password"                     # Optional: password for authentication
FILESYSTEM="nfs"                        # Usually cifs for Windows shares, nfs for NFS

log_info "Setting up network share mount..."

# Install required packages
if [ "$FILESYSTEM" = "cifs" ]; then
    log_info "Installing CIFS utilities..."
    apt-get update -qq
    apt-get install -y cifs-utils
elif [ "$FILESYSTEM" = "nfs" ]; then
    log_info "Installing NFS utilities..."
    apt-get update -qq
    apt-get install -y nfs-common
fi

# Create mount point
log_info "Creating mount point: $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"

# Create credentials file if username/password provided
CREDENTIALS_FILE="/etc/cifs-credentials"
if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    log_info "Creating credentials file..."
    cat > "$CREDENTIALS_FILE" << EOF
username=$USERNAME
password=$PASSWORD
EOF
    chmod 600 "$CREDENTIALS_FILE"
    MOUNT_OPTIONS="credentials=$CREDENTIALS_FILE,uid=$(id -u),gid=$(id -g),iocharset=utf8"
else
    MOUNT_OPTIONS="guest,uid=$(id -u),gid=$(id -g),iocharset=utf8"
fi

# Mount the share
log_info "Mounting $SHARE_PATH to $MOUNT_POINT..."
if mount -t "$FILESYSTEM" -o "$MOUNT_OPTIONS" "$SHARE_PATH" "$MOUNT_POINT"; then
    log_info "Network share mounted successfully!"
    
    # Add to fstab for auto-mounting (optional)
    if [ "$FILESYSTEM" = "cifs" ] && [ -n "$USERNAME" ]; then
        FSTAB_ENTRY="$SHARE_PATH $MOUNT_POINT $FILESYSTEM $MOUNT_OPTIONS 0 0"
    else
        FSTAB_ENTRY="$SHARE_PATH $MOUNT_POINT $FILESYSTEM defaults 0 0"
    fi
    
    if ! grep -q "$MOUNT_POINT" /etc/fstab; then
        log_info "Adding entry to /etc/fstab for auto-mounting..."
        echo "$FSTAB_ENTRY" >> /etc/fstab
    else
        log_info "Mount point already exists in /etc/fstab"
    fi
else
    log_info "ERROR: Failed to mount $SHARE_PATH"
    exit 1
fi

