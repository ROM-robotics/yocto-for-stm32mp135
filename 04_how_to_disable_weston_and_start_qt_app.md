# How to Disable Weston Launcher and Run Qt6 App Only

Complete guide for running Qt6 applications without Weston launcher in kiosk mode on STM32MP135F Discovery Kit.

## Table of Contents
1. [Overview](#overview)
2. [Method Comparison](#method-comparison)
3. [Method 1: EGLFS Kiosk Mode (Recommended)](#method-1-eglfs-kiosk-mode-recommended)
4. [Method 2: Framebuffer Direct Access](#method-2-framebuffer-direct-access)
5. [Method 3: Wayland Fullscreen (Keep Weston)](#method-3-wayland-fullscreen-keep-weston)
6. [Method 4: Manual Command Line](#method-4-manual-command-line)
7. [Production Kiosk Mode Setup](#production-kiosk-mode-setup)
8. [Yocto Integration](#yocto-integration)
9. [Troubleshooting](#troubleshooting)

---

## Overview

### What is Weston Launcher?

**Weston** is a Wayland compositor that provides:
- Desktop environment with application launcher
- Multi-window support
- Touch screen input handling
- Hardware-accelerated rendering

**Weston Launcher** shows icons for:
- Settings
- Video player
- Python GTK demos
- Qt6 examples
- Graphics demos
- Multimedia applications

### Why Disable Weston Launcher?

For **kiosk mode** or **single-purpose devices**:
- ✅ Faster boot time
- ✅ Lower memory usage
- ✅ No user access to other apps
- ✅ Direct fullscreen application
- ✅ Better performance
- ✅ Simpler user experience

---

## Method Comparison

| Method | Display Server | GPU Acceleration | Boot Time | Memory | Best For |
|--------|---------------|------------------|-----------|---------|----------|
| **EGLFS** | None | ✅ Full | ⚡ Fastest | 💚 Lowest | Production kiosk |
| **Framebuffer** | None | ⚠️ Limited | ⚡ Fast | 💚 Low | Simple graphics |
| **Wayland Fullscreen** | Weston | ✅ Full | 🐢 Slower | 💛 Medium | Multi-window capable |
| **Wayland Desktop** | Weston + Launcher | ✅ Full | 🐢 Slowest | 🧡 High | Development/testing |

**Recommendation**: Use **EGLFS** for production, **Wayland** for development.

---

## Method 1: EGLFS Kiosk Mode (Recommended)

EGLFS (EGL Full Screen) provides direct OpenGL ES access with best performance.

### Step 1: Create EGLFS Configuration

```bash
# On STM32MP135 target (via SSH or serial console)

# Create Qt6 EGLFS configuration file
cat > /etc/qt6-kiosk.json << 'EOF'
{
  "device": "/dev/dri/card0",
  "hwcursor": false,
  "pbuffers": true,
  "outputs": [
    {
      "name": "HDMI-A-1",
      "mode": "480x272",
      "format": "argb8888",
      "physicalWidth": 105,
      "physicalHeight": 67
    }
  ]
}
EOF

# Verify file created
cat /etc/qt6-kiosk.json
```

**Configuration Options:**
- `device`: DRM/KMS device (usually `/dev/dri/card0`)
- `hwcursor`: Hardware cursor (false for STM32MP135)
- `mode`: Display resolution (480x272 for STM32MP135F-DK)
- `format`: Pixel format (argb8888 recommended)

### Step 2: Create Systemd Service

```bash
# Create systemd service for Qt6 application
cat > /etc/systemd/system/qt-kiosk.service << 'EOF'
[Unit]
Description=Qt6 Kiosk Application
After=systemd-user-sessions.service
After=plymouth-quit.service
After=systemd-logind.service

[Service]
Type=simple
User=root
WorkingDirectory=/root

# Qt6 EGLFS environment
Environment="QT_QPA_PLATFORM=eglfs"
Environment="QT_QPA_EGLFS_INTEGRATION=eglfs_kms"
Environment="QT_QPA_EGLFS_KMS_CONFIG=/etc/qt6-kiosk.json"
Environment="QT_QPA_EGLFS_ALWAYS_SET_MODE=1"
Environment="QT_QPA_EGLFS_FORCE888=1"

# Display and input
Environment="QT_QPA_FB_DRM=1"
Environment="QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/event0"

# Font configuration
Environment="QT_QPA_FONTDIR=/usr/share/fonts"

# Logging (optional, for debugging)
Environment="QT_LOGGING_RULES=qt.qpa.*=false"

# Application to run
ExecStart=/usr/bin/hello_stm32

# Restart on crash
Restart=always
RestartSec=3

# TTY configuration
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Verify service file
cat /etc/systemd/system/qt-kiosk.service
```

### Step 3: Disable Weston and Enable Qt Kiosk

```bash
# Stop Weston launcher
systemctl stop weston

# Disable Weston from auto-starting
systemctl disable weston

# Reload systemd configuration
systemctl daemon-reload

# Enable Qt kiosk service
systemctl enable qt-kiosk.service

# Start Qt kiosk service
systemctl start qt-kiosk.service

# Check status
systemctl status qt-kiosk.service
```

### Step 4: Verify and Reboot

```bash
# Check if service is enabled
systemctl is-enabled qt-kiosk.service
# Should output: enabled

# Check if Weston is disabled
systemctl is-enabled weston.service
# Should output: disabled

# Reboot to test auto-start
reboot
```

**Expected Result**: After reboot, your Qt6 application starts immediately in fullscreen without Weston launcher.

---

## Method 2: Framebuffer Direct Access

For simple applications without GPU acceleration requirements.

### Step 1: Create Framebuffer Service

```bash
# Create systemd service for framebuffer mode
cat > /etc/systemd/system/qt-framebuffer.service << 'EOF'
[Unit]
Description=Qt6 Framebuffer Application
After=systemd-user-sessions.service

[Service]
Type=simple
User=root

# Framebuffer platform
Environment="QT_QPA_PLATFORM=linuxfb"
Environment="QT_QPA_FB_DRM=1"
Environment="QT_QPA_FONTDIR=/usr/share/fonts"

# Touch input
Environment="QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/event0"

# Application
ExecStart=/usr/bin/hello_stm32

Restart=always
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF
```

### Step 2: Enable Service

```bash
systemctl stop weston
systemctl disable weston
systemctl daemon-reload
systemctl enable qt-framebuffer.service
systemctl start qt-framebuffer.service
```

**Pros:**
- Simple configuration
- Lower resource usage
- Fast startup

**Cons:**
- No GPU acceleration
- Limited graphics performance
- No hardware cursor

---

## Method 3: Wayland Fullscreen (Keep Weston)

Run Qt app in fullscreen on Weston, but hide the launcher.

### Step 1: Modify Weston Configuration

```bash
# Edit Weston configuration
cat > /etc/xdg/weston/weston.ini << 'EOF'
[core]
idle-time=0
require-input=false
modules=systemd-notify.so

[shell]
# Hide panel/launcher
panel-position=none
background-color=0xff000000
locking=false

[keyboard]
keymap_layout=us

[output]
name=HDMI-A-1
mode=480x272
transform=normal
EOF
```

### Step 2: Create Auto-start Service

```bash
# Create service to auto-start Qt app on Weston
cat > /etc/systemd/system/qt-wayland-fullscreen.service << 'EOF'
[Unit]
Description=Qt6 Wayland Fullscreen Application
After=weston.service
Requires=weston.service
PartOf=weston.service

[Service]
Type=simple
User=root

# Wayland environment
Environment="XDG_RUNTIME_DIR=/run/user/0"
Environment="QT_QPA_PLATFORM=wayland"
Environment="WAYLAND_DISPLAY=wayland-0"

# Fullscreen and no decoration
Environment="QT_WAYLAND_DISABLE_WINDOWDECORATION=1"

# Application with fullscreen flag
ExecStart=/usr/bin/hello_stm32

Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
```

### Step 3: Enable Services

```bash
systemctl daemon-reload
systemctl enable weston.service
systemctl enable qt-wayland-fullscreen.service
systemctl start weston.service
systemctl start qt-wayland-fullscreen.service
```

**Pros:**
- Keep Weston's features
- Easy to add more windows if needed
- Good for development

**Cons:**
- Higher memory usage
- Slower boot time
- Weston running in background

---

## Method 4: Manual Command Line

For testing or one-time execution.

### EGLFS Mode

```bash
# Stop Weston first
systemctl stop weston

# Run Qt app in EGLFS mode
QT_QPA_PLATFORM=eglfs \
QT_QPA_EGLFS_INTEGRATION=eglfs_kms \
QT_QPA_EGLFS_KMS_CONFIG=/etc/qt6-kiosk.json \
QT_QPA_EGLFS_ALWAYS_SET_MODE=1 \
/usr/bin/hello_stm32
```

### Framebuffer Mode

```bash
# Stop Weston
systemctl stop weston

# Run Qt app on framebuffer
QT_QPA_PLATFORM=linuxfb \
QT_QPA_FB_DRM=1 \
/usr/bin/hello_stm32
```

### Wayland Mode (Keep Weston)

```bash
# Ensure Weston is running
systemctl start weston

# Run Qt app on Wayland
export XDG_RUNTIME_DIR=/run/user/0
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY=wayland-0
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

/usr/bin/hello_stm32 &
```

---

## Production Kiosk Mode Setup

Complete automated setup script for production kiosk mode.

### All-in-One Setup Script

```bash
# Create setup script
cat > /tmp/setup_production_kiosk.sh << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Qt6 Production Kiosk Mode Setup"
echo "STM32MP135F Discovery Kit"
echo "=========================================="
echo ""

# Configuration
QT_APP="/usr/bin/hello_stm32"
SERVICE_NAME="qt-kiosk"

# Check if application exists
if [ ! -f "$QT_APP" ]; then
    echo "Error: Qt application not found at $QT_APP"
    exit 1
fi

echo "[1/6] Creating EGLFS configuration..."
cat > /etc/qt6-kiosk.json << 'EOFCONFIG'
{
  "device": "/dev/dri/card0",
  "hwcursor": false,
  "pbuffers": true,
  "outputs": [
    {
      "name": "HDMI-A-1",
      "mode": "480x272",
      "format": "argb8888",
      "physicalWidth": 105,
      "physicalHeight": 67
    }
  ]
}
EOFCONFIG
echo "   ✓ Created /etc/qt6-kiosk.json"

echo "[2/6] Creating systemd service..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << 'EOFSERVICE'
[Unit]
Description=Qt6 Production Kiosk Application
After=systemd-user-sessions.service plymouth-quit.service
DefaultDependencies=no

[Service]
Type=simple
User=root
WorkingDirectory=/root
Environment="QT_QPA_PLATFORM=eglfs"
Environment="QT_QPA_EGLFS_INTEGRATION=eglfs_kms"
Environment="QT_QPA_EGLFS_KMS_CONFIG=/etc/qt6-kiosk.json"
Environment="QT_QPA_EGLFS_ALWAYS_SET_MODE=1"
Environment="QT_QPA_EGLFS_FORCE888=1"
Environment="QT_QPA_FB_DRM=1"
Environment="QT_QPA_FONTDIR=/usr/share/fonts"
Environment="QT_LOGGING_RULES=qt.qpa.*=false"
ExecStart=/usr/bin/hello_stm32
Restart=always
RestartSec=3
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE
echo "   ✓ Created /etc/systemd/system/${SERVICE_NAME}.service"

echo "[3/6] Disabling Weston..."
systemctl stop weston 2>/dev/null || true
systemctl disable weston 2>/dev/null || true
echo "   ✓ Weston disabled"

echo "[4/6] Reloading systemd configuration..."
systemctl daemon-reload
echo "   ✓ Systemd reloaded"

echo "[5/6] Enabling Qt kiosk service..."
systemctl enable ${SERVICE_NAME}.service
echo "   ✓ Service enabled"

echo "[6/6] Starting Qt kiosk service..."
systemctl start ${SERVICE_NAME}.service
sleep 2
echo "   ✓ Service started"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Service Status:"
systemctl status ${SERVICE_NAME}.service --no-pager -l || true
echo ""
echo "Commands:"
echo "  Check status:  systemctl status ${SERVICE_NAME}"
echo "  View logs:     journalctl -u ${SERVICE_NAME} -f"
echo "  Restart:       systemctl restart ${SERVICE_NAME}"
echo "  Stop:          systemctl stop ${SERVICE_NAME}"
echo ""
echo "Reboot recommended for clean startup test."
echo ""
EOF

chmod +x /tmp/setup_production_kiosk.sh

# Run setup script
/tmp/setup_production_kiosk.sh
```

### Verify Installation

```bash
# Check service status
systemctl status qt-kiosk

# View logs
journalctl -u qt-kiosk -f

# Check if Weston is disabled
systemctl is-enabled weston
# Should show: disabled

# Check if Qt kiosk is enabled
systemctl is-enabled qt-kiosk
# Should show: enabled

# Test reboot
reboot
```

---

## Yocto Integration

Add kiosk mode configuration to your Yocto build.

### Method 1: Recipe-based Setup

#### Create Qt Kiosk Setup Recipe

```bash
# On host PC
cd ~/openstlinux-build/layers/meta-rom-custom

# Create recipe directory
mkdir -p recipes-apps/qt-kiosk-setup/qt-kiosk-setup

# Create recipe
cat > recipes-apps/qt-kiosk-setup/qt-kiosk-setup_1.0.bb << 'EOF'
SUMMARY = "Qt6 Kiosk Mode Configuration"
DESCRIPTION = "Configures STM32MP135 to run Qt6 application in kiosk mode without Weston launcher"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit allarch systemd

# Ensure Qt app is installed
RDEPENDS:${PN} = "hello-stm32"

SRC_URI = "file://qt-kiosk.service \
           file://qt6-kiosk.json"

S = "${WORKDIR}"

# Enable systemd service
SYSTEMD_SERVICE:${PN} = "qt-kiosk.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/qt-kiosk.service ${D}${systemd_system_unitdir}/
    
    # Install Qt EGLFS configuration
    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/qt6-kiosk.json ${D}${sysconfdir}/
    
    # Disable Weston service
    install -d ${D}${sysconfdir}/systemd/system
    ln -sf /dev/null ${D}${sysconfdir}/systemd/system/weston.service
}

FILES:${PN} = "${systemd_system_unitdir}/qt-kiosk.service \
               ${sysconfdir}/qt6-kiosk.json \
               ${sysconfdir}/systemd/system/weston.service"
EOF
```

#### Create Service Files

```bash
# Create systemd service file
cat > recipes-apps/qt-kiosk-setup/qt-kiosk-setup/qt-kiosk.service << 'EOF'
[Unit]
Description=Qt6 Kiosk Application
After=systemd-user-sessions.service plymouth-quit.service
DefaultDependencies=no

[Service]
Type=simple
User=root
WorkingDirectory=/root
Environment="QT_QPA_PLATFORM=eglfs"
Environment="QT_QPA_EGLFS_INTEGRATION=eglfs_kms"
Environment="QT_QPA_EGLFS_KMS_CONFIG=/etc/qt6-kiosk.json"
Environment="QT_QPA_EGLFS_ALWAYS_SET_MODE=1"
Environment="QT_QPA_EGLFS_FORCE888=1"
Environment="QT_QPA_FB_DRM=1"
Environment="QT_QPA_FONTDIR=/usr/share/fonts"
Environment="QT_LOGGING_RULES=qt.qpa.*=false"
ExecStart=/usr/bin/hello_stm32
Restart=always
RestartSec=3
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create EGLFS config
cat > recipes-apps/qt-kiosk-setup/qt-kiosk-setup/qt6-kiosk.json << 'EOF'
{
  "device": "/dev/dri/card0",
  "hwcursor": false,
  "pbuffers": true,
  "outputs": [
    {
      "name": "HDMI-A-1",
      "mode": "480x272",
      "format": "argb8888",
      "physicalWidth": 105,
      "physicalHeight": 67
    }
  ]
}
EOF
```

#### Add to Image

```bash
# Edit st-image-qt6.bb
cat >> ~/openstlinux-build/layers/meta-rom-custom/recipes-st/images/st-image-qt6.bb << 'EOF'

# Qt6 Kiosk Mode
IMAGE_INSTALL += "qt-kiosk-setup"
EOF
```

#### Build and Flash

```bash
# Build image with kiosk mode
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

bitbake st-image-qt6

# Flash to SD card
cd tmp-glibc/deploy/images/stm32mp13-disco/
sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh \
    flashlayout_st-image-qt6/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv

sudo dd if=FlashLayout_sdcard_stm32mp135f-dk-optee.raw \
    of=/dev/sda bs=8M conv=fdatasync status=progress

sudo sgdisk /dev/sda -e
```

### Method 2: Image Feature Configuration

```bash
# Add to local.conf or image recipe
cat >> ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/conf/local.conf << 'EOF'

# Disable Weston launcher, enable Qt kiosk
SYSTEMD_AUTO_ENABLE:pn-weston = "disable"
PACKAGECONFIG:remove:pn-weston = "launcher-desktop"

# Add Qt kiosk package
IMAGE_INSTALL:append = " qt-kiosk-setup"
EOF
```

---

## Troubleshooting

### Issue 1: Black Screen After Boot

**Symptoms**: Screen stays black, no Qt application visible

**Diagnosis**:
```bash
# Check service status
systemctl status qt-kiosk

# Check logs
journalctl -u qt-kiosk -n 50

# Check if application exists
ls -l /usr/bin/hello_stm32

# Test manually
systemctl stop qt-kiosk
QT_QPA_PLATFORM=eglfs QT_LOGGING_RULES="*=true" /usr/bin/hello_stm32
```

**Solutions**:
```bash
# 1. Check DRM device
ls -l /dev/dri/card0

# 2. Verify EGLFS config
cat /etc/qt6-kiosk.json

# 3. Check display connection
cat /sys/class/drm/card0-HDMI-A-1/status
# Should show: connected

# 4. Try framebuffer mode instead
sed -i 's/QT_QPA_PLATFORM=eglfs/QT_QPA_PLATFORM=linuxfb/' /etc/systemd/system/qt-kiosk.service
systemctl daemon-reload
systemctl restart qt-kiosk
```

### Issue 2: "Could not queue DRM page flip"

**Cause**: Multiple applications trying to access DRM device

**Solutions**:
```bash
# Ensure Weston is stopped
systemctl stop weston
systemctl disable weston

# Check for other processes using DRM
fuser -v /dev/dri/card0

# Kill conflicting processes
killall weston 2>/dev/null || true

# Restart Qt kiosk
systemctl restart qt-kiosk
```

### Issue 3: Touch Input Not Working

**Symptoms**: Display works but touch doesn't respond

**Solutions**:
```bash
# 1. Find touch device
ls -l /dev/input/by-path/*touch*
ls -l /dev/input/event*

# 2. Test touch device
evtest /dev/input/event0

# 3. Update service environment
cat >> /etc/systemd/system/qt-kiosk.service << 'EOF'
Environment="QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/event0"
Environment="QT_QPA_GENERIC_PLUGINS=evdevtouch:/dev/input/event0"
EOF

systemctl daemon-reload
systemctl restart qt-kiosk
```

### Issue 4: Application Crashes on Startup

**Diagnosis**:
```bash
# Check crash logs
journalctl -u qt-kiosk -n 100 | grep -i error

# Run with debug output
systemctl stop qt-kiosk
QT_DEBUG_PLUGINS=1 QT_LOGGING_RULES="*=true" /usr/bin/hello_stm32

# Check dependencies
ldd /usr/bin/hello_stm32

# Verify Qt libraries
ls -l /usr/lib/libQt6*.so*
```

**Solutions**:
```bash
# Install missing Qt6 packages
opkg update
opkg install qtbase qtdeclarative qtwayland

# Verify application permissions
chmod +x /usr/bin/hello_stm32

# Check for missing resources
strace /usr/bin/hello_stm32 2>&1 | grep "No such file"
```

### Issue 5: Slow Performance

**Symptoms**: Application runs but laggy or slow

**Solutions**:
```bash
# 1. Ensure using EGLFS (not framebuffer)
grep QT_QPA_PLATFORM /etc/systemd/system/qt-kiosk.service
# Should show: eglfs

# 2. Check GPU is being used
cat /sys/kernel/debug/dri/0/clients

# 3. Enable performance governor
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# 4. Optimize EGLFS config
cat > /etc/qt6-kiosk.json << 'EOF'
{
  "device": "/dev/dri/card0",
  "hwcursor": false,
  "pbuffers": true,
  "separateScreens": false,
  "outputs": [
    {
      "name": "HDMI-A-1",
      "mode": "480x272",
      "format": "argb8888"
    }
  ]
}
EOF

systemctl restart qt-kiosk
```

### Issue 6: Application Not Auto-starting After Reboot

**Diagnosis**:
```bash
# Check if service is enabled
systemctl is-enabled qt-kiosk
# Should show: enabled

# Check service dependencies
systemctl list-dependencies qt-kiosk

# Check boot logs
journalctl -b | grep qt-kiosk
```

**Solutions**:
```bash
# Re-enable service
systemctl daemon-reload
systemctl enable qt-kiosk.service

# Check for failed dependencies
systemctl --failed

# Add delay if needed
cat >> /etc/systemd/system/qt-kiosk.service << 'EOF'
[Service]
ExecStartPre=/bin/sleep 3
EOF

systemctl daemon-reload
reboot
```

---

## Performance Optimization

### Reduce Boot Time

```bash
# 1. Disable unnecessary services
systemctl disable bluetooth
systemctl disable avahi-daemon
systemctl disable networkd-dispatcher

# 2. Optimize systemd timeout
mkdir -p /etc/systemd/system.conf.d/
cat > /etc/systemd/system.conf.d/timeout.conf << 'EOF'
[Manager]
DefaultTimeoutStartSec=10s
DefaultTimeoutStopSec=10s
EOF

# 3. Use static hostname
hostnamectl set-hostname stm32mp135 --static

# 4. Disable Plymouth (boot splash)
systemctl disable plymouth-start.service
```

### Optimize Memory Usage

```bash
# Set in /etc/systemd/system/qt-kiosk.service
[Service]
Environment="QT_QPA_EGLFS_NO_LIBINPUT=1"
Environment="QT_FONT_DPI=96"
MemoryLimit=256M
```

### Enable Watchdog

```bash
# Auto-restart if application hangs
cat >> /etc/systemd/system/qt-kiosk.service << 'EOF'
[Service]
WatchdogSec=30s
EOF

# In your Qt application (C++):
# QCoreApplication::instance()->installNativeEventFilter(watchdog);
```

---

## Useful Commands

### Service Management

```bash
# Start/stop/restart service
systemctl start qt-kiosk
systemctl stop qt-kiosk
systemctl restart qt-kiosk

# Enable/disable auto-start
systemctl enable qt-kiosk
systemctl disable qt-kiosk

# Check status
systemctl status qt-kiosk

# View logs (real-time)
journalctl -u qt-kiosk -f

# View logs (last 100 lines)
journalctl -u qt-kiosk -n 100

# Clear old logs
journalctl --vacuum-time=1d
```

### Testing Modes

```bash
# Test EGLFS mode
QT_QPA_PLATFORM=eglfs \
QT_QPA_EGLFS_INTEGRATION=eglfs_kms \
/usr/bin/hello_stm32

# Test Framebuffer mode
QT_QPA_PLATFORM=linuxfb \
/usr/bin/hello_stm32

# Test Wayland mode (Weston must be running)
export XDG_RUNTIME_DIR=/run/user/0
QT_QPA_PLATFORM=wayland \
/usr/bin/hello_stm32
```

### Debug Output

```bash
# Enable Qt debug output
QT_LOGGING_RULES="qt.qpa.*=true" /usr/bin/hello_stm32

# Full debug
QT_DEBUG_PLUGINS=1 \
QT_LOGGING_RULES="*=true" \
/usr/bin/hello_stm32 2>&1 | less

# Check OpenGL info
QT_QPA_PLATFORM=eglfs \
/usr/bin/hello_stm32 2>&1 | grep -i "opengl\|egl\|gpu"
```

---

## Quick Reference

### Kiosk Mode Setup (One Command)

```bash
# Quick setup for EGLFS kiosk mode
bash <(cat << 'EOFSETUP'
systemctl stop weston; systemctl disable weston
cat > /etc/qt6-kiosk.json << 'EOF'
{"device":"/dev/dri/card0","hwcursor":false,"outputs":[{"name":"HDMI-A-1","mode":"480x272"}]}
EOF
cat > /etc/systemd/system/qt-kiosk.service << 'EOF'
[Unit]
Description=Qt6 Kiosk
After=systemd-user-sessions.service
[Service]
Environment="QT_QPA_PLATFORM=eglfs"
Environment="QT_QPA_EGLFS_INTEGRATION=eglfs_kms"
Environment="QT_QPA_EGLFS_KMS_CONFIG=/etc/qt6-kiosk.json"
ExecStart=/usr/bin/hello_stm32
Restart=always
TTYPath=/dev/tty1
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable qt-kiosk.service
systemctl start qt-kiosk.service
EOFSETUP
)
```

### Switch Between Modes

```bash
# Switch to Weston launcher
systemctl stop qt-kiosk
systemctl disable qt-kiosk
systemctl enable weston
systemctl start weston

# Switch to Qt kiosk
systemctl stop weston
systemctl disable weston
systemctl enable qt-kiosk
systemctl start qt-kiosk
```

---

## Summary

**For Production Kiosk Mode:**
- ✅ Use **EGLFS** mode
- ✅ Disable Weston
- ✅ Create systemd service
- ✅ Enable auto-start
- ✅ Test thoroughly

**For Development:**
- Use Wayland with Weston
- Easy debugging
- Multi-window support

**Key Files:**
- Service: `/etc/systemd/system/qt-kiosk.service`
- Config: `/etc/qt6-kiosk.json`
- Application: `/usr/bin/hello_stm32`

**Commands:**
```bash
systemctl status qt-kiosk      # Check status
journalctl -u qt-kiosk -f      # View logs
systemctl restart qt-kiosk     # Restart app
```

---

**Last Updated**: November 10, 2025  
**Qt Version**: 6.8.4  
**OpenSTLinux**: v6.1.0 (openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11)  
**Target**: STM32MP135F Discovery Kit
