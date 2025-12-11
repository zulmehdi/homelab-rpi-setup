# Raspberry Pi 5 Setup Scripts

A modular bash script structure for setting up Raspberry Pi 5 running Raspberry Pi OS Lite (64-bit).

## Structure

```
.
├── setup.sh              # Main setup script
├── config.conf           # Configuration file (packages and mounts)
├── packages/             # Individual package installation scripts
│   ├── docker.sh
│   ├── kind.sh
│   ├── kubectl.sh
│   ├── gitlab.sh
│   └── gitlab-runner.sh
└── mounts/              # Mount configuration scripts
    ├── README.md
    ├── usb-drive.sh
    └── network-share.sh
```

## Quick Start

1. **Edit the configuration file** (`config.conf`):
   ```bash
   # Specify which packages to install (one per line)
   PACKAGES=
   docker
   kind
   kubectl
   gitlab
   gitlab-runner
   
   # Specify which mounts to configure (one per line)
   MOUNTS=
   usb-drive
   network-share
   ```

2. **Customize mount scripts** in the `mounts/` directory:
   - Edit `usb-drive.sh` or `network-share.sh` with your specific device paths and mount points
   - Or create new mount scripts following the same pattern

3. **Run the setup script**:
   ```bash
   sudo bash setup.sh
   ```

## Configuration

### Packages

Available packages:
- `docker` - Docker Engine and Docker Compose
- `kind` - Kubernetes in Docker
- `kubectl` - Kubernetes command-line tool
- `gitlab` - GitLab CE (via Docker)
- `gitlab-runner` - GitLab Runner

To add a new package:
1. Create a new script in `packages/` directory (e.g., `packages/my-package.sh`)
2. Make it executable: `chmod +x packages/my-package.sh`
3. Add it to `PACKAGES` in `config.conf`

### Mounts

Mount scripts should be placed in the `mounts/` directory. Each script should:
- Be executable (`chmod +x`)
- Handle mount point creation
- Handle mounting logic
- Optionally configure `/etc/fstab` for persistent mounting

Example mount scripts are provided:
- `usb-drive.sh` - Template for USB drive mounting
- `network-share.sh` - Template for network share mounting (CIFS/NFS)

To add a new mount:
1. Create a new script in `mounts/` directory (e.g., `mounts/my-mount.sh`)
2. Customize the script with your device/share details
3. Make it executable: `chmod +x mounts/my-mount.sh`
4. Add it to `MOUNTS` in `config.conf`

## Package Details

### Docker
- Installs Docker Engine from official Docker repository
- Installs Docker Compose plugin
- Adds current user to docker group
- Enables and starts Docker service

### Kind
- Downloads and installs Kind binary
- Requires Docker to be installed first
- Supports ARM64 architecture

### kubectl
- Downloads latest stable kubectl binary
- Verifies checksum before installation
- Supports ARM64 architecture

### GitLab
- Installs GitLab CE using Docker Compose
- Creates directory structure at `/opt/gitlab`
- Exposes ports 80, 443, and 22
- Initial root password saved to `/opt/gitlab/config/initial_root_password`

### GitLab Runner
- Installs GitLab Runner from official repository
- Supports ARM64 architecture
- Requires manual registration with GitLab instance

## Usage on Multiple Raspberry Pis

This structure is designed to be used across multiple Raspberry Pis:

1. **Clone or copy** this directory to each Raspberry Pi
2. **Customize** `config.conf` for each Pi's specific needs
3. **Customize** mount scripts in `mounts/` directory as needed
4. **Run** `sudo bash setup.sh` on each Pi

## Notes

- The script must be run as root (use `sudo`)
- The script will update system packages before installing
- Package installations are independent - if one fails, others will still be attempted
- Mount scripts should handle cases where devices/shares are not available
- GitLab installation may take several minutes to initialize

## Troubleshooting

- **Package installation fails**: Check the individual package script logs
- **Mount fails**: Verify device/share paths and permissions
- **GitLab not accessible**: Wait a few minutes for initialization, check logs with `docker compose -f /opt/gitlab/docker-compose.yml logs`
- **Permission errors**: Ensure script is run with `sudo`

## License

This is a setup script collection for personal use. Modify as needed for your environment.

