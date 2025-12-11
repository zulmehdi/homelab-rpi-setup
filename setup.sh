#!/bin/bash

# Raspberry Pi 5 Setup Script
# This script reads configuration and installs packages/mounts accordingly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"
PACKAGES_DIR="${SCRIPT_DIR}/packages"
MOUNTS_DIR="${SCRIPT_DIR}/mounts"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Raspberry Pi OS
check_raspberry_pi() {
    if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        log_warning "This script is designed for Raspberry Pi. Continuing anyway..."
    fi
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Load configuration file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    log_info "Loading configuration from $CONFIG_FILE"
    
    # Parse packages (vertical list format)
    PACKAGES_ARRAY=()
    IN_PACKAGES_SECTION=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check if we're entering the PACKAGES section
        if [[ "$line" =~ ^[[:space:]]*PACKAGES= ]]; then
            IN_PACKAGES_SECTION=true
            continue
        fi
        
        # Check if we're entering the MOUNTS section (end of PACKAGES)
        if [[ "$line" =~ ^[[:space:]]*MOUNTS= ]]; then
            IN_PACKAGES_SECTION=false
            break
        fi
        
        # Add to packages array if in PACKAGES section
        if [ "$IN_PACKAGES_SECTION" = true ]; then
            # Trim leading and trailing whitespace
            package=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -n "$package" ] && PACKAGES_ARRAY+=("$package")
        fi
    done < "$CONFIG_FILE"
    
    # Parse mounts (vertical list format)
    MOUNTS_ARRAY=()
    IN_MOUNTS_SECTION=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check if we're entering the MOUNTS section
        if [[ "$line" =~ ^[[:space:]]*MOUNTS= ]]; then
            IN_MOUNTS_SECTION=true
            continue
        fi
        
        # Add to mounts array if in MOUNTS section
        if [ "$IN_MOUNTS_SECTION" = true ]; then
            # Trim leading and trailing whitespace
            mount=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -n "$mount" ] && MOUNTS_ARRAY+=("$mount")
        fi
    done < "$CONFIG_FILE"
    
    if [ ${#PACKAGES_ARRAY[@]} -eq 0 ]; then
        log_warning "No packages specified in config file"
    fi
    
    if [ ${#MOUNTS_ARRAY[@]} -eq 0 ]; then
        log_warning "No mounts specified in config file"
    fi
}

# Install a package
install_package() {
    local package_name="$1"
    local package_script="${PACKAGES_DIR}/${package_name}.sh"
    
    if [ ! -f "$package_script" ]; then
        log_error "Package script not found: $package_script"
        return 1
    fi
    
    if [ ! -x "$package_script" ]; then
        log_info "Making $package_script executable"
        chmod +x "$package_script"
    fi
    
    log_info "Installing package: $package_name"
    
    if bash "$package_script"; then
        log_success "Package $package_name installed successfully"
        return 0
    else
        log_error "Failed to install package: $package_name"
        return 1
    fi
}

# Setup a mount
setup_mount() {
    local mount_name="$1"
    local mount_script="${MOUNTS_DIR}/${mount_name}.sh"
    
    if [ ! -f "$mount_script" ]; then
        log_error "Mount script not found: $mount_script"
        return 1
    fi
    
    if [ ! -x "$mount_script" ]; then
        log_info "Making $mount_script executable"
        chmod +x "$mount_script"
    fi
    
    log_info "Setting up mount: $mount_name"
    
    if bash "$mount_script"; then
        log_success "Mount $mount_name configured successfully"
        return 0
    else
        log_error "Failed to setup mount: $mount_name"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting Raspberry Pi 5 Setup"
    log_info "Script directory: $SCRIPT_DIR"
    
    check_raspberry_pi
    check_root
    load_config
    
    # Update system packages
    log_info "Updating system packages..."
    apt-get update -qq
    apt-get upgrade -y -qq
    
    # Install packages
    if [ ${#PACKAGES_ARRAY[@]} -gt 0 ]; then
        log_info "Installing ${#PACKAGES_ARRAY[@]} package(s)..."
        for package in "${PACKAGES_ARRAY[@]}"; do
            if [ -n "$package" ]; then
                install_package "$package" || log_warning "Package $package installation had issues"
            fi
        done
    else
        log_info "No packages to install"
    fi
    
    # Setup mounts
    if [ ${#MOUNTS_ARRAY[@]} -gt 0 ]; then
        log_info "Setting up ${#MOUNTS_ARRAY[@]} mount(s)..."
        for mount in "${MOUNTS_ARRAY[@]}"; do
            if [ -n "$mount" ]; then
                setup_mount "$mount" || log_warning "Mount $mount setup had issues"
            fi
        done
    else
        log_info "No mounts to configure"
    fi
    
    log_success "Setup completed!"
    log_info "Please review the output above for any warnings or errors"
}

# Run main function
main "$@"

