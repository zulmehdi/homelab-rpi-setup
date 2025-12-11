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

# Check if a package is already installed
is_package_installed() {
    local package_name="$1"
    
    case "$package_name" in
        docker)
            if command -v docker &> /dev/null && docker --version &> /dev/null && docker compose version &> /dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        kind)
            if command -v kind &> /dev/null && kind version &> /dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        kubectl)
            if command -v kubectl &> /dev/null && kubectl version --client &> /dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        gitlab)
            if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^gitlab$"; then
                return 0
            else
                return 1
            fi
            ;;
        gitlab-runner)
            if command -v gitlab-runner &> /dev/null && gitlab-runner --version &> /dev/null; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            # For unknown packages, assume not installed
            return 1
            ;;
    esac
}

# Install a package
install_package() {
    local package_name="$1"
    local package_script="${PACKAGES_DIR}/${package_name}.sh"
    
    if [ ! -f "$package_script" ]; then
        log_error "Package script not found: $package_script"
        return 1
    fi
    
    # Check if package is already installed
    if is_package_installed "$package_name"; then
        log_info "Package $package_name is already installed. Skipping."
        return 0
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
    
    # Clean up Docker repository configurations if Docker is in the package list
    # This prevents GPG key conflicts during apt-get update
    if printf '%s\n' "${PACKAGES_ARRAY[@]}" | grep -q "^docker$"; then
        log_info "Cleaning up existing Docker repository configurations..."
        rm -f /etc/apt/sources.list.d/docker*.list
        rm -f /etc/apt/keyrings/docker*.gpg
        rm -f /etc/apt/keyrings/docker*.asc
        rm -f /usr/share/keyrings/docker*.gpg
        sed -i '/download\.docker\.com/d' /etc/apt/sources.list 2>/dev/null || true
    fi
    
    # Update system packages
    log_info "Updating system packages..."
    set +e
    apt-get update -qq
    UPDATE_EXIT=$?
    set -e
    
    if [ $UPDATE_EXIT -ne 0 ]; then
        log_warning "apt-get update had issues (exit code: $UPDATE_EXIT)"
        log_warning "This may be due to repository conflicts. Continuing anyway..."
    fi
    
    apt-get upgrade -y -qq || log_warning "apt-get upgrade had issues, continuing..."
    
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

