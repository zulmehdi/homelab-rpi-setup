#!/bin/bash

# USB Drive Mount Script Example
# This is a template - customize for your specific USB drive

set -euo pipefail

log_info() {
    echo "[MOUNT-USB] $1"
}

# Configuration - CUSTOMIZE THESE VALUES
DEVICE="/dev/sda1"           # Change to your USB device (use lsblk to find)
MOUNT_POINT="/mnt/usb-drive"  # Change to your desired mount point
FILESYSTEM="ext4"             # Change to your filesystem type (ext4, ntfs, vfat, etc.)

log_info "Setting up USB drive mount..."

# Check if device exists
if [ ! -b "$DEVICE" ]; then
    log_info "WARNING: Device $DEVICE not found. Skipping mount."
    log_info "Use 'lsblk' to find your USB device."
    exit 0
fi

# Create mount point
log_info "Creating mount point: $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"

# Mount the device
log_info "Mounting $DEVICE to $MOUNT_POINT..."
if mount -t "$FILESYSTEM" "$DEVICE" "$MOUNT_POINT"; then
    log_info "USB drive mounted successfully!"
    
    # Add to fstab for auto-mounting (optional)
    FSTAB_ENTRY="$DEVICE $MOUNT_POINT $FILESYSTEM defaults,noatime 0 2"
    if ! grep -q "$MOUNT_POINT" /etc/fstab; then
        log_info "Adding entry to /etc/fstab for auto-mounting..."
        echo "$FSTAB_ENTRY" >> /etc/fstab
    else
        log_info "Mount point already exists in /etc/fstab"
    fi
else
    log_info "ERROR: Failed to mount $DEVICE"
    exit 1
fi

