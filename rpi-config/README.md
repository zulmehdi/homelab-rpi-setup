# Raspberry Pi Configuration Files

This directory contains example configuration files for initial Raspberry Pi setup using cloud-init and firmware configuration.

## Files

### `config.txt.example`
Raspberry Pi firmware configuration file. This file controls hardware settings and boot parameters.

**Key settings in this example:**
- I2C interface enabled (`dtparam=i2c_arm=on`)
- PCIe x1 interface enabled with Gen 3 support
- Audio enabled
- 64-bit mode enabled
- Auto-detection for cameras and displays
- VC4 V3D graphics driver enabled
- Various performance optimizations

**Usage:**
1. Copy `config.txt.example` to `config.txt`
2. Customize settings as needed for your hardware setup
3. Place the file in the `boot` partition of your Raspberry Pi OS SD card (typically mounted at `/boot/firmware/` on Raspberry Pi OS)

**Documentation:**
- Official documentation: https://rptl.io/configtxt
- Overlay documentation: `/boot/firmware/overlays/README` (on Raspberry Pi)

### `user-data.example`
Cloud-init user-data file for automated initial setup of Raspberry Pi OS.

**What this example configures:**
- Hostname and `/etc/hosts` management
- Initial packages (avahi-daemon, git)
- APT configuration (disables date checking)
- Timezone (Europe/Stockholm - customize as needed)
- Keyboard layout (US - customize as needed)
- SSH enabled
- User creation with appropriate groups
- Serial interface enabled
- Automatic setup directory creation and repository cloning

**Usage:**
1. Copy `user-data.example` to `user-data`
2. **Important:** Replace `<USER>` placeholders with your actual username
3. Customize:
   - Hostname
   - Timezone
   - Keyboard layout
   - User name and password
   - Repository URL (if different)
   - Additional packages
4. Place the file in the `system-boot` partition of your Raspberry Pi OS SD card (typically the first partition, FAT32 formatted)

**Cloud-init Requirements:**
- Raspberry Pi OS images with cloud-init support (Raspberry Pi OS Lite or Desktop with cloud-init)
- The `user-data` file must be placed in the `system-boot` partition
- Optionally, you can also create a `meta-data` file (can be empty) in the same location

**Security Note:**
- The example has `lock_passwd: false` and `ssh_pwauth: true` for convenience
- For production use, consider:
  - Setting `lock_passwd: true` and using SSH keys only
  - Setting `ssh_pwauth: false`
  - Using encrypted passwords (see cloud-init documentation)

## Setup Workflow

1. **Flash Raspberry Pi OS** to SD card using Raspberry Pi Imager or similar tool
2. **Configure cloud-init:**
   - Mount the `system-boot` partition
   - Copy and customize `user-data` (and optionally create `meta-data`)
   - Place files in the root of the `system-boot` partition
3. **Configure firmware:**
   - Mount the `boot` partition (or `system-boot` if using newer images)
   - Copy and customize `config.txt`
   - Place in the root of the boot partition
4. **Boot Raspberry Pi:**
   - Insert SD card and power on
   - Cloud-init will run on first boot
   - The setup script will be cloned automatically (if configured in `user-data`)
5. **Run setup script:**
   ```bash
   cd ~/setup
   sudo bash setup.sh
   ```

## Customization Tips

### `config.txt`
- Enable/disable hardware interfaces based on your needs (I2C, SPI, I2S)
- Adjust PCIe settings if using NVMe adapters
- Modify graphics settings for your display setup
- Add custom overlays for specific hardware

### `user-data`
- Change timezone to match your location
- Adjust keyboard layout for your region
- Add additional packages to the `packages:` list
- Modify the repository URL if using a fork
- Add SSH keys for passwordless authentication
- Configure network settings if needed

## Additional Resources

- [Raspberry Pi Configuration Documentation](https://rptl.io/configtxt)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [Raspberry Pi OS Documentation](https://www.raspberrypi.com/documentation/computers/os.html)
