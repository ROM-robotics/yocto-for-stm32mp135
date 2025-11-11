# meta-rom-splash Layer - Quick Start Guide

## Your custom layer is ready! ✓

### Layer Location
```
~/openstlinux-build/layers/meta-rom-splash/
```

### Layer Status
✓ Layer created  
✓ Layer added to build configuration  
✓ Helper script created

---

## How to Add Your Custom Splash Image

### Option 1: Using Helper Script (Recommended)

```bash
cd ~/openstlinux-build/layers/meta-rom-splash

# Generate splash for STM32MP135-DK (480x272 only)
./add_splash.sh /path/to/your/logo.png

# Or generate for ALL resolutions
./add_splash.sh /path/to/your/logo.png --all-resolutions
```

### Option 2: Manual Conversion

```bash
# Install ImageMagick (if not already installed)
sudo apt-get install imagemagick

# Convert your image
cd ~/openstlinux-build/layers/meta-rom-splash/recipes-core/psplash/psplash-drm/pictures/

convert /path/to/your/logo.png \
    -resize 480x272 \
    -background black \
    -gravity center \
    -extent 480x272 \
    ST30739_splash-480x272.png
```

### Option 3: Copy Existing PNG

```bash
# If your image is already the correct size and format
cp /path/to/your/splash_480x272.png \
    ~/openstlinux-build/layers/meta-rom-splash/recipes-core/psplash/psplash-drm/pictures/ST30739_splash-480x272.png
```

---

## Rebuild with Custom Splash

```bash
# Navigate to build directory
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Clean psplash cache
bitbake -c cleansstate psplash-drm

# Rebuild image (takes ~5-10 minutes)
bitbake st-image-weston

# Create new SD card
cd tmp-glibc/deploy/images/stm32mp13-disco/
sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh \
    flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv
sudo dd if=FlashLayout_sdcard_stm32mp135f-dk-optee.raw of=/dev/sda bs=8M conv=fdatasync status=progress
sudo sgdisk /dev/sda -e
sync
```

---

## Supported Resolutions

| Resolution | Display Type | Filename |
|------------|--------------|----------|
| 480x272 | STM32MP135-DK (default) | ST30739_splash-480x272.png |
| 800x480 | STM32MP157-DK2 | ST30739_splash-800x480.png |
| 1024x600 | 10-inch display | ST30739_splash-1024x600.png |
| 1280x720 | HDMI 720p | ST30739_splash-1280x720.png |
| 1920x1080 | HDMI 1080p | ST30739_splash-1920x1080.png |

---

## Image Requirements

- **Format:** PNG
- **Color depth:** 24-bit RGB or 32-bit RGBA
- **Background:** Any (transparent supported)
- **Size:** Keep under 500KB for fast boot
- **Aspect ratio:** Should match target resolution

---

## Verify Your Layer

```bash
# Check layer is active
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
bitbake-layers show-layers | grep rom-splash

# Expected output:
# rom-splash  /home/mr_robot/openstlinux-build/layers/meta-rom-splash  10
```

---

## Remove Layer (if needed)

```bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
bitbake-layers remove-layer meta-rom-splash
```

---

## Troubleshooting

### No splash image appears on boot
- Verify file exists: `ls ~/openstlinux-build/layers/meta-rom-splash/recipes-core/psplash/psplash-drm/pictures/`
- Check file permissions: `chmod 644 *.png`
- Rebuild: `bitbake -c cleansstate psplash-drm && bitbake psplash-drm`

### Wrong resolution displayed
- Ensure filename matches pattern: `ST30739_splash-<resolution>.png`
- Check display resolution on target: `cat /sys/class/drm/card0-*/modes`

### Build errors
- Clean everything: `bitbake -c cleansstate psplash-drm`
- Verify PNG format: `file your_image.png` (should show "PNG image data")

---

## Layer Structure

```
meta-rom-splash/
├── conf/
│   └── layer.conf              # Layer configuration
├── recipes-core/
│   └── psplash/
│       ├── psplash-drm_%.bbappend  # Recipe override
│       └── psplash-drm/
│           └── pictures/
│               └── [Your PNG files here]
├── add_splash.sh               # Helper script
└── README.md                   # This file
```

---

## Need Help?

See the complete guide: `custom_boot_splash.md`

---

**Layer:** meta-rom-splash  
**Priority:** 10 (higher than default ST layers)  
**Compatible with:** OpenSTLinux v6.1.0 (Yocto Scarthgap)
