# Mounts Directory

This directory contains mount configuration scripts for various drives and filesystems.

## Usage

Each mount should have its own `.sh` script file. The script should:
1. Create mount point directory if it doesn't exist
2. Mount the filesystem
3. Optionally add entry to `/etc/fstab` for persistent mounting

## Example Mount Scripts

- `usb-drive.sh` - Example USB drive mount
- `network-share.sh` - Example network share mount

## Script Requirements

Each mount script should:
- Be executable (`chmod +x`)
- Handle mount point creation
- Handle mounting logic
- Optionally configure `/etc/fstab` for auto-mounting on boot

