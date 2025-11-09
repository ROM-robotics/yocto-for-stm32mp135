# How to Flash STM32MP135 with OpenSTLinux

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Monitor Build Progress](#monitor-build-progress)
3. [Build Output Location](#build-output-location)
4. [Flashing Methods](#flashing-methods)
5. [Step-by-Step Flashing Guide](#step-by-step-flashing-guide)
6. [Post-Flash Verification](#post-flash-verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements
- **STM32MP135 Discovery Board** (or custom board with STM32MP135)
- **USB Type-C cable** (for power and USB DFU flashing)
- **USB-UART adapter** (optional, for serial console)
- **SD card** (optional, for SD card boot)
- **Host PC** running Linux (Ubuntu 22.04 recommended)

### Software Requirements
Install the STM32CubeProgrammer tool:

```bash
# Download from ST website
# https://www.st.com/en/development-tools/stm32cubeprog.html

# Or install via command line (after downloading)
cd ~/Downloads
unzip en.stm32cubeprg-lin-*.zip
cd STM32CubeProgrammer*/
sudo ./SetupSTM32CubeProgrammer*.linux

# Add to PATH
export PATH=$PATH:/usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin
```

For SD card flashing, install additional tools:
```bash
sudo apt-get install -y bmap-tools parted dosfstools e2fsprogs gdisk
```

**Important Notes:**
- The `create_sdcard_from_flashlayout.sh` script uses the `DEVICE` environment variable
- Do NOT pass the device as a command-line argument (will cause "bad extension" error)
- The script creates a `.raw` file first, then you use `dd` to write it
- Correct: `sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh <tsv_file>`
- Wrong: `sudo ./scripts/create_sdcard_from_flashlayout.sh <tsv_file> /dev/sda`

---

## Monitor Build Progress

### Check Current Build Status

```bash
# Navigate to build directory
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco

# Watch build progress in real-time
tail -f tmp-glibc/log/cooker/qemux86-64/console-latest.log

# Or check overall progress
bitbake st-image-weston -g -u depexp
```

### Estimate Remaining Time

```bash
# Check how many tasks are remaining
bitbake st-image-weston --dry-run | grep "currently running"

# Monitor CPU and disk usage
htop
```

### Common Build Duration
- **First build**: 2-6 hours (depends on CPU cores and internet speed)
- **Incremental builds**: 10-30 minutes
- **Clean rebuild**: 1-3 hours

---

## Build Output Location

After successful build, images are located at:

```bash
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/
```

### Key Files Generated

#### Bootloader Files
- `arm-trusted-firmware/tf-a-stm32mp135f-dk-serialboot.stm32` - TF-A for serial boot
- `arm-trusted-firmware/tf-a-stm32mp135f-dk-sdcard.stm32` - TF-A for SD boot
- `u-boot-stm32mp13-disco.img` - U-Boot bootloader
- `u-boot-stm32mp13-disco.stm32` - U-Boot for flashing

#### Kernel and Device Tree
- `uImage` - Linux kernel image
- `stm32mp135f-dk.dtb` - Device tree blob for STM32MP135F Discovery Kit

#### Root Filesystem
- `st-image-weston-openstlinux-weston-stm32mp13-disco.ext4` - Root filesystem (ext4 format)
- `st-image-weston-openstlinux-weston-stm32mp13-disco.tar.xz` - Root filesystem archive

#### Flash Layout
- `flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv` - Flash layout for SD card with OP-TEE
- `flashlayout_st-image-weston/extensible/FlashLayout_sdcard_stm32mp135f-dk-extensible.tsv` - Flash layout for extensible SD card

#### Complete Images
- `scripts/create_sdcard_from_flashlayout.sh` - Script to create bootable SD card

---

## Flashing Methods

### Method 1: SD Card Boot (Recommended for Development)
- **Pros**: Easy, non-destructive, hot-swappable
- **Cons**: Slower boot, requires SD card slot
- **Use case**: Development, testing, recovery

### Method 2: eMMC/NAND Flash via USB DFU
- **Pros**: Fast boot, production-ready
- **Cons**: Requires DFU mode, overwrites internal flash
- **Use case**: Production deployment, final product

### Method 3: STM32CubeProgrammer GUI
- **Pros**: User-friendly, detailed feedback
- **Cons**: Requires GUI, slower workflow
- **Use case**: Initial setup, troubleshooting

---

## Step-by-Step Flashing Guide

## Method 1: Flash to SD Card

### Option A: Using FlashLayout Script (Automated)

```bash
# Navigate to deploy directory
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/

# Insert SD card and identify device (e.g., /dev/sdX)
lsblk

# WARNING: Replace /dev/sdX with your actual SD card device!
# This will ERASE all data on the SD card!

# Unmount SD card if auto-mounted
sudo umount /dev/sdX*

# Step 1: Create raw image from FlashLayout (use DEVICE environment variable)
# Note: Replace 'sdX' with your actual device (e.g., sda, sdb)
sudo DEVICE=sdX ./scripts/create_sdcard_from_flashlayout.sh \
    flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv

# Step 2: Write the raw image to SD card
sudo dd if=FlashLayout_sdcard_stm32mp135f-dk-optee.raw \
    of=/dev/sdX bs=8M conv=fdatasync status=progress

# Step 3: Fix GPT table to use full SD card size (if your SD card is larger than 5GB)
sudo sgdisk /dev/sdX -e

# Step 4: Verify partitions
sudo sgdisk /dev/sdX -v

# Wait for completion
sync
```

### Option B: Manual Partitioning (Advanced)

```bash
# Identify SD card device
lsblk
# Example output: /dev/sdb

# Set device name (CHANGE THIS!)
DEVICE=/dev/sdX  # e.g., /dev/sdb

# Unmount all partitions
sudo umount ${DEVICE}*

# Create partition table
sudo parted ${DEVICE} --script mklabel msdos

# Create boot partition (256MB, FAT32)
sudo parted ${DEVICE} --script mkpart primary fat32 1MiB 257MiB
sudo parted ${DEVICE} --script set 1 boot on

# Create rootfs partition (use remaining space)
sudo parted ${DEVICE} --script mkpart primary ext4 257MiB 100%

# Format partitions
sudo mkfs.vfat -F 32 -n BOOT ${DEVICE}1
sudo mkfs.ext4 -L rootfs ${DEVICE}2

# Mount partitions
mkdir -p /tmp/boot /tmp/rootfs
sudo mount ${DEVICE}1 /tmp/boot
sudo mount ${DEVICE}2 /tmp/rootfs

# Copy bootloader and kernel to boot partition
sudo cp arm-trusted-firmware/tf-a-stm32mp135f-dk-sdcard.stm32 /tmp/boot/
sudo cp u-boot-stm32mp13-disco.img /tmp/boot/
sudo cp uImage /tmp/boot/
sudo cp stm32mp135f-dk.dtb /tmp/boot/

# Extract rootfs to rootfs partition
sudo tar -xf st-image-weston-openstlinux-weston-stm32mp13-disco.tar.xz -C /tmp/rootfs/

# Sync and unmount
sync
sudo umount /tmp/boot /tmp/rootfs
```

---

## Method 2: Flash to eMMC/NAND via USB DFU

### Step 1: Set Boot Mode to USB DFU

On STM32MP135 Discovery Board:
1. **Set boot switches** to boot from USB:
   - BOOT0 = 0
   - BOOT1 = 1
   - BOOT2 = 0
   
2. **Connect USB Type-C cable** to ST-LINK USB connector (CN1)
3. **Power on** the board
4. Board should enter **USB DFU mode**

### Step 2: Verify DFU Mode

```bash
# Check if board is detected in DFU mode
lsusb | grep STMicroelectronics

# Expected output:
# Bus 001 Device XXX: ID 0483:df11 STMicroelectronics STM Device in DFU Mode

# Check with dfu-util
sudo dfu-util -l

# Install dfu-util if not present
sudo apt-get install -y dfu-util
```

### Step 3: Flash Using STM32CubeProgrammer CLI

```bash
# Navigate to deploy directory
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/

# Flash using STM32CubeProgrammer CLI (if eMMC available)
# Note: STM32MP13-disco typically uses SD card, not eMMC
STM32_Programmer_CLI -c port=usb1 \
    -w flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv

# Alternative: Flash individual partitions
STM32_Programmer_CLI -c port=usb1 \
    -w arm-trusted-firmware/tf-a-stm32mp135f-dk-serialboot.stm32 0x00000000 \
    -w u-boot-stm32mp13-disco.stm32 0x00040000 \
    -w uImage 0x00280000 \
    -w stm32mp135f-dk.dtb 0x02800000 \
    -w st-image-weston-openstlinux-weston-stm32mp13-disco.ext4 0x03000000
```

### Step 4: Set Boot Mode Back to Normal

After flashing:
1. **Power off** the board
2. **Set boot switches** to boot from eMMC/SD:
   - BOOT0 = 1
   - BOOT1 = 0
   - BOOT2 = 0
3. **Power on** and boot from flashed storage

---

## Method 3: STM32CubeProgrammer GUI

### Step 1: Launch STM32CubeProgrammer

```bash
# Start STM32CubeProgrammer GUI
STM32CubeProgrammer

# Or from installed location
/usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32CubeProgrammer
```

### Step 2: Connect to Board

1. Set board to **DFU mode** (see Method 2, Step 1)
2. In STM32CubeProgrammer:
   - Select **USB** connection type
   - Click **Refresh** to detect device
   - Click **Connect**

### Step 3: Flash Using TSV File

1. Go to **Erasing & Programming** tab
2. Click **Open file** and select:
   ```
   flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv
   ```
   (Note: For eMMC flashing, you would need a different flash layout if available)
3. Click **Browse** for each file path if needed
4. Click **Download** to start flashing
5. Wait for completion (progress bar shows status)

### Step 4: Disconnect and Reboot

1. Click **Disconnect**
2. Close STM32CubeProgrammer
3. Set boot switches back to normal mode
4. Power cycle the board

---

## Post-Flash Verification

### Connect Serial Console

```bash
# Install minicom or screen
sudo apt-get install -y minicom screen

# Identify USB-UART device (usually /dev/ttyUSB0 or /dev/ttyACM0)
ls -l /dev/tty* | grep USB

# Connect with minicom (115200 8N1)
sudo minicom -D /dev/ttyUSB0 -b 115200

# Or with screen
sudo screen /dev/ttyUSB0 115200

# Power on board and watch boot messages
```

### Expected Boot Sequence

```
NOTICE:  CPU: STM32MP135Fxx Rev.Y
NOTICE:  Model: STMicroelectronics STM32MP135F-DK Discovery Board
NOTICE:  Board: MB1635 Var2.0 Rev.C-01
...
U-Boot 2024.01 (Oct 23 2024 - 12:34:56 +0000)
...
Starting kernel ...
[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.6.36
...
OpenSTLinux weston stm32mp13-disco ttySTM0

stm32mp13-disco login: root
```

### Default Login Credentials

- **Username**: `root`
- **Password**: (none - just press Enter)

### Verify System Information

```bash
# After logging in as root

# Check kernel version
uname -a

# Check STM32MP info
cat /proc/cpuinfo

# Check available storage
df -h

# Check memory
free -h

# Test Weston/Wayland (if display connected)
weston-info

# List available packages
opkg list
```

---

## Troubleshooting

### Issue 1: "bad extension of Flashlayout file" Error

**Symptoms**: Script reports "bad extension" or "must have a tsv extension"

**Cause**: Passing device as command-line argument instead of environment variable

**Solution**:
```bash
# WRONG - Don't do this:
sudo ./scripts/create_sdcard_from_flashlayout.sh <tsv_file> /dev/sda

# CORRECT - Use DEVICE environment variable:
sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh <tsv_file>
```

### Issue 2: SD Card Not Bootable

**Symptoms**: Board doesn't boot, blank screen, no serial output

**Solutions**:
```bash
# Verify boot switches are correct
# BOOT0=1, BOOT1=0, BOOT2=0 for SD card boot

# Re-create raw image with verbose output
DEBUG=1 sudo DEVICE=sdX ./scripts/create_sdcard_from_flashlayout.sh \
    flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv

# Then write to SD card
sudo dd if=FlashLayout_sdcard_stm32mp135f-dk-optee.raw \
    of=/dev/sdX bs=8M conv=fdatasync status=progress

# Fix GPT table
sudo sgdisk /dev/sdX -e

# Check SD card partitions
sudo fdisk -l /dev/sdX
sudo sgdisk /dev/sdX -p
```

### Issue 3: "secondary header" Warning After dd

**Symptoms**: `sgdisk -v` reports "secondary header doesn't reside at end of disk"

**Cause**: SD card is larger than the 5GB image size

**Solution**:
```bash
# Fix GPT table to use full SD card
sudo sgdisk /dev/sdX -e

# Verify fix
sudo sgdisk /dev/sdX -v
# Should now show "No problems found"
```

### Issue 4: DFU Mode Not Detected

**Symptoms**: `lsusb` doesn't show STM device, cannot connect

**Solutions**:
```bash
# Check USB cable (must be data-capable, not charge-only)
# Try different USB port on host PC

# Verify boot switches for DFU mode
# BOOT0=0, BOOT1=1, BOOT2=0

# Check dmesg for USB errors
dmesg | tail -20

# Install/update USB rules
sudo cp /usr/local/STMicroelectronics/STM32Cube/STM32CubeProgrammer/Drivers/rules/*.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Issue 5: Kernel Panic on Boot

**Symptoms**: Boot stops at "Starting kernel...", panic messages

**Solutions**:
```bash
# Check device tree compatibility
# Ensure you're using stm32mp135f-dk.dtb for STM32MP135F

# Verify root filesystem is correct
# Check FlashLayout TSV file points to correct rootfs image

# Try booting with console output
# In U-Boot, interrupt boot and add: console=ttySTM0,115200
```

### Issue 6: Build Failed

**Symptoms**: bitbake errors, missing packages

**Solutions**:
```bash
# Clean build cache
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco
bitbake -c cleanall st-image-weston

# Update repo
cd ~/openstlinux-build
repo sync -j4

# Check disk space (need >100GB free)
df -h

# Re-run with verbose output
bitbake st-image-weston -v

# Check logs
cat tmp-glibc/log/cooker/qemux86-64/console-latest.log
```

### Issue 7: Display Not Working

**Symptoms**: No output on HDMI/LCD

**Solutions**:
```bash
# Check Weston status
systemctl status weston

# Restart Weston
systemctl restart weston

# Check display in device tree
ls /sys/class/drm/

# Test with fbtest
fbtest /dev/fb0
```

---

## Additional Resources

### Official Documentation
- [STM32MP13 Wiki](https://wiki.st.com/stm32mpu/wiki/STM32MP13x_lines)
- [OpenSTLinux Distribution](https://wiki.st.com/stm32mpu/wiki/STM32MPU_Distribution_Package)
- [STM32CubeProgrammer User Manual](https://www.st.com/resource/en/user_manual/um2237-stm32cubeprogrammer-software-description-stmicroelectronics.pdf)

### Useful Commands

```bash
# Create backup of SD card
sudo dd if=/dev/sdX of=~/stm32mp135_backup.img bs=4M status=progress

# Restore from backup
sudo dd if=~/stm32mp135_backup.img of=/dev/sdX bs=4M status=progress

# Check partition UUIDs
sudo blkid /dev/sdX*

# List all partitions with details
sudo sgdisk /dev/sdX -p

# Verify GPT integrity
sudo sgdisk /dev/sdX -v

# Check what files are in the raw image before writing
file FlashLayout_sdcard_stm32mp135f-dk-optee.raw

# Monitor boot messages over network
# (if Ethernet configured)
ssh root@<board-ip> dmesg -w

# Customize SD card size (default is 5GB)
SDCARD_SIZE=8192 sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh <tsv_file>
# This creates an 8GB image (8192 MB)
```

### Performance Tips

- Use **eMMC** for faster boot times (vs SD card)
- Enable **U-Boot splash screen** for better user experience
- Configure **systemd** to optimize boot sequence
- Use **read-only rootfs** for production to prevent corruption

---

## Complete Working Example

Here's a complete example that was tested and verified:

```bash
# 1. Navigate to the deploy directory
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/

# 2. Check your SD card device
lsblk
# Look for your SD card (e.g., sda, sdb - NOT sda1, sdb1)

# 3. Unmount any mounted partitions
sudo umount /dev/sda*  # Replace sda with your actual device

# 4. Create the raw image (this generates a .raw file)
# Note: Use DEVICE environment variable, NOT as a command argument
sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh \
    flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv

# This creates: FlashLayout_sdcard_stm32mp135f-dk-optee.raw

# 5. Write the raw image to SD card
sudo dd if=FlashLayout_sdcard_stm32mp135f-dk-optee.raw \
    of=/dev/sda bs=8M conv=fdatasync status=progress

# 6. Fix GPT table if your SD card is larger than 5GB
sudo sgdisk /dev/sda -e

# 7. Verify the partitions
sudo sgdisk /dev/sda -v
lsblk /dev/sda

# 8. Sync and safely eject
sync
sudo eject /dev/sda
```

**Expected Output:**
- Step 4 creates 11 partitions (fsbl1, fsbl2, metadata1/2, fip-a/b, u-boot-env, bootfs, vendorfs, rootfs, userfs)
- Step 5 takes 2-5 minutes depending on SD card speed (~20 MB/s typical)
- Step 6 fixes "secondary header" warning if SD card > 5GB
- Step 7 should show "No problems found"

---

## Quick Reference Card

### Boot Switch Settings (STM32MP135-DK)

| Mode | BOOT0 | BOOT1 | BOOT2 | Description |
|------|-------|-------|-------|-------------|
| USB DFU | 0 | 1 | 0 | Flash programming |
| SD Card | 1 | 0 | 0 | Boot from SD |
| eMMC | 1 | 1 | 0 | Boot from eMMC |
| Developer | 0 | 0 | 1 | Engineering mode |

### Serial Console Settings
- **Baud rate**: 115200
- **Data bits**: 8
- **Parity**: None
- **Stop bits**: 1
- **Flow control**: None

### Default Network Settings
- **DHCP**: Enabled by default
- **Static IP**: Configure via `/etc/network/interfaces`
- **Hostname**: `stm32mp13-disco`

---

## Notes

- Always **sync** after writing to removable media
- Keep **backup copies** of working images
- Test on **SD card first** before flashing to eMMC
- Read the **board's user manual** for specific details
- Check **wiki.st.com** for latest updates and errata

---

**Last Updated**: November 9, 2025  
**OpenSTLinux Version**: v6.1.0 (openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11)  
**Target**: STM32MP135F Discovery Kit
