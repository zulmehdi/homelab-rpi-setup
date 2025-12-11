#!/bin/bash

# GitLab Installation Script for Raspberry Pi 5
# Installs GitLab CE using Docker Compose

set -euo pipefail

log_info() {
    echo "[GITLAB] $1"
}

log_info "Starting GitLab installation..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "[GITLAB] ERROR: Docker is required but not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "[GITLAB] ERROR: Docker Compose is required but not available."
    exit 1
fi

# GitLab configuration directory
GITLAB_DIR="/opt/gitlab"
GITLAB_COMPOSE_FILE="${GITLAB_DIR}/docker-compose.yml"

log_info "Creating GitLab directory structure..."
mkdir -p "$GITLAB_DIR"/{config,logs,data}

# Check if port 22 is in use (SSH)
GITLAB_SSH_PORT=2222
if netstat -tuln 2>/dev/null | grep -q ':22 ' || ss -tuln 2>/dev/null | grep -q ':22 '; then
    log_info "Port 22 is already in use (likely SSH). Using port $GITLAB_SSH_PORT for GitLab SSH instead."
else
    GITLAB_SSH_PORT=22
    log_info "Port 22 is available. Using it for GitLab SSH."
fi

# Create docker-compose.yml for GitLab
log_info "Creating GitLab Docker Compose configuration..."
cat > "$GITLAB_COMPOSE_FILE" << EOF
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    hostname: 'gitlab.local'
    restart: always
    ports:
      - '80:80'
      - '443:443'
      - '${GITLAB_SSH_PORT}:22'
    volumes:
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
    shm_size: '256m'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.local'
        gitlab_rails['gitlab_shell_ssh_port'] = ${GITLAB_SSH_PORT}
EOF

log_info "Starting GitLab container..."
cd "$GITLAB_DIR"
docker compose up -d

log_info "Waiting for GitLab to initialize (this may take a few minutes)..."
log_info "You can check the status with: docker compose -f $GITLAB_COMPOSE_FILE ps"
log_info "View logs with: docker compose -f $GITLAB_COMPOSE_FILE logs -f"

# Wait a bit and check if container is running
sleep 10
if docker ps | grep -q gitlab; then
    log_info "GitLab container is running!"
    log_info "Initial root password will be available in: $GITLAB_DIR/config/initial_root_password"
    log_info "Retrieve it with: sudo cat $GITLAB_DIR/config/initial_root_password"
    log_info "Access GitLab at: http://$(hostname -I | awk '{print $1}')"
    log_info "GitLab SSH port: $GITLAB_SSH_PORT"
    log_info "Note: If using port $GITLAB_SSH_PORT, configure GitLab to use this port for SSH clones"
else
    log_info "WARNING: GitLab container may not have started properly. Check logs for details."
fi

echo "[GITLAB] GitLab installation initiated!"

