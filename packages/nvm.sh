#!/bin/bash

# NVM (Node Version Manager) Installation Script for Raspberry Pi 5
# Installs NVM for managing Node.js versions

set -euo pipefail

log_info() {
    echo "[NVM] $1"
}

# Check if NVM is already installed
if [ -s "$HOME/.nvm/nvm.sh" ] || [ -s "/usr/local/nvm/nvm.sh" ]; then
    log_info "NVM is already installed. Skipping installation."
    exit 0
fi

log_info "Starting NVM installation..."

# Determine installation location
# Install to /usr/local/nvm for system-wide access (requires root)
# Or $HOME/.nvm for user-specific installation
if [ "$EUID" -eq 0 ]; then
    NVM_DIR="/usr/local/nvm"
    PROFILE_FILE="/etc/profile.d/nvm.sh"
    # For root, install to a temp location first, then move
    TEMP_NVM_DIR="$HOME/.nvm"
else
    NVM_DIR="$HOME/.nvm"
    PROFILE_FILE="$HOME/.bashrc"
    TEMP_NVM_DIR="$NVM_DIR"
fi

# Set NVM version (update as needed)
NVM_VERSION="v0.39.7"

log_info "Installing NVM ${NVM_VERSION} to ${NVM_DIR}..."

# Export NVM_DIR so the install script uses it
export NVM_DIR="$TEMP_NVM_DIR"

# Download and install NVM
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# If installing system-wide, move from temp location to /usr/local/nvm
if [ "$EUID" -eq 0 ] && [ "$TEMP_NVM_DIR" != "$NVM_DIR" ] && [ -d "$TEMP_NVM_DIR" ]; then
    log_info "Moving NVM to system-wide location..."
    mkdir -p "$NVM_DIR"
    cp -r "$TEMP_NVM_DIR"/* "$NVM_DIR/" 2>/dev/null || true
    rm -rf "$TEMP_NVM_DIR"
    
    # Create system-wide profile script
    cat > "$PROFILE_FILE" << 'EOF'
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
    chmod +x "$PROFILE_FILE"
else
    # For user installation, update the profile file if needed
    if [ -f "$PROFILE_FILE" ] && ! grep -q "NVM_DIR" "$PROFILE_FILE" 2>/dev/null; then
        log_info "Adding NVM to $PROFILE_FILE..."
        cat >> "$PROFILE_FILE" << EOF

# NVM configuration
export NVM_DIR="$NVM_DIR"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
EOF
    fi
fi

# Source NVM to make it available in current session
if [ -s "$NVM_DIR/nvm.sh" ]; then
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Verify installation
log_info "Verifying NVM installation..."
if command -v nvm &> /dev/null || [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "[NVM] NVM installed successfully!"
    if command -v nvm &> /dev/null; then
        nvm --version
    else
        echo "[NVM] NVM installed at $NVM_DIR"
        echo "[NVM] Please source $PROFILE_FILE or restart your shell to use NVM"
    fi
else
    echo "[NVM] ERROR: NVM installation verification failed"
    exit 1
fi
