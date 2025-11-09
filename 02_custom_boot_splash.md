# How to Add Custom Boot Splash Screen to STM32MP135

## Overview

OpenSTLinux uses **psplash-drm** for boot splash screens. You can easily replace the default ST splash screen with your custom PNG image.

## Methods

There are **3 methods** to customize the boot splash:

1. **Direct Replacement** (Quick & Easy) - Replace existing splash files
2. **Custom Layer** (Recommended) - Create your own Yocto layer
3. **Recipe Override** (Advanced) - Override the psplash recipe

---

## Method 1: Direct Replacement (Quick & Easy)

This is the fastest method - simply replace the existing splash images with your custom ones.

### Step 1: Prepare Your Custom Splash Images

Your splash screen should match your display resolution. The STM32MP135-DK supports multiple resolutions:

**Supported Resolutions:**
- 480x272 (default for STM32MP13-DK display)
- 480x800
- 720x1280
- 800x480
- 1024x600
- 1280x720
- 1920x1080

**Image Requirements:**
- Format: PNG
- Color depth: 24-bit RGB or 32-bit RGBA
- Transparent background supported
- Keep file size reasonable (<500KB)

### Step 2: Convert Your Image (if needed)

```bash
# Install ImageMagick if not present
sudo apt-get install -y imagemagick

# Convert and resize your image to match display resolution
# For STM32MP135-DK (480x272 default)
convert your_logo.png -resize 480x272 -background black -gravity center \
    -extent 480x272 custom_splash-480x272.png

# For other resolutions
convert your_logo.png -resize 800x480 -background black -gravity center \
    -extent 800x480 custom_splash-800x480.png

convert your_logo.png -resize 1024x600 -background black -gravity center \
    -extent 1024x600 custom_splash-1024x600.png
```

### Step 3: Replace the Splash Images

```bash
# Navigate to the splash pictures directory
cd ~/openstlinux-build/layers/meta-st/meta-st-openstlinux/recipes-core/psplash/psplash-drm/pictures/

# Backup original images
mkdir -p ~/original_splash_backup
cp *.png ~/original_splash_backup/

# Copy your custom splash images (replace with your actual filenames)
# You can either:
# A) Replace all resolutions
cp ~/path/to/your/custom_splash-480x272.png ST30739_splash-480x272.png
cp ~/path/to/your/custom_splash-480x800.png ST30739_splash-480x800.png
cp ~/path/to/your/custom_splash-720x1280.png ST30739_splash-720x1280.png
cp ~/path/to/your/custom_splash-800x480.png ST30739_splash-800x480.png
cp ~/path/to/your/custom_splash-1024x600.png ST30739_splash-1024x600.png
cp ~/path/to/your/custom_splash-1280x720.png ST30739_splash-1280x720.png
cp ~/path/to/your/custom_splash-1920x1080.png ST30739_splash-1920x1080.png

# B) Or replace just the resolution you need (e.g., 480x272 for STM32MP13-DK)
cp ~/path/to/your/custom_splash.png ST30739_splash-480x272.png
```

### Step 4: Rebuild psplash Package

```bash
# Navigate to build directory
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Clean and rebuild only psplash (much faster than full rebuild)
bitbake -c cleansstate psplash-drm
bitbake psplash-drm

# Rebuild the image with new splash
bitbake st-image-weston
```

### Step 5: Flash and Test

```bash
# Navigate to deploy directory
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/tmp-glibc/deploy/images/stm32mp13-disco/

# Create new SD card with updated image
sudo DEVICE=sda ./scripts/create_sdcard_from_flashlayout.sh \
    flashlayout_st-image-weston/optee/FlashLayout_sdcard_stm32mp135f-dk-optee.tsv

sudo dd if=FlashLayout_sdcard_stm32mp135f-dk-optee.raw \
    of=/dev/sda bs=8M conv=fdatasync status=progress

sudo sgdisk /dev/sda -e
sync
```

**Build Time:** ~5-10 minutes (only rebuilds psplash and image)

---

## Method 2: Custom Layer (Recommended for Production)

This method creates a custom Yocto layer that won't be affected by future updates.

### Step 1: Create Your Custom Layer

```bash
cd ~/openstlinux-build/layers
mkdir -p meta-custom-splash
cd meta-custom-splash

# Create layer structure
mkdir -p conf
mkdir -p recipes-core/psplash/psplash-drm/pictures
```

### Step 2: Create Layer Configuration

```bash
cat > conf/layer.conf << 'EOF'
# Layer configuration for meta-custom-splash
BBPATH .= ":${LAYERDIR}"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb \
            ${LAYERDIR}/recipes-*/*/*.bbappend"
BBFILE_COLLECTIONS += "custom-splash"
BBFILE_PATTERN_custom-splash = "^${LAYERDIR}/"
BBFILE_PRIORITY_custom-splash = "10"
LAYERSERIES_COMPAT_custom-splash = "scarthgap"
EOF
```

### Step 3: Create Recipe Append

```bash
cat > recipes-core/psplash/psplash-drm_%.bbappend << 'EOF'
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# This will use your custom images instead of the default ones
EOF
```

### Step 4: Add Your Custom Images

```bash
# Copy your custom splash images to the layer
cp ~/path/to/your/custom_splash-480x272.png \
    recipes-core/psplash/psplash-drm/pictures/ST30739_splash-480x272.png

# Copy for other resolutions as needed
cp ~/path/to/your/custom_splash-*.png \
    recipes-core/psplash/psplash-drm/pictures/
```

### Step 5: Add Layer to Build

```bash
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco

# Add your custom layer
bitbake-layers add-layer ../layers/meta-custom-splash

# Verify layer is added
bitbake-layers show-layers
```

### Step 6: Build

```bash
# Clean and rebuild
bitbake -c cleansstate psplash-drm
bitbake st-image-weston
```

---

## Method 3: Runtime Replacement (No Rebuild Required)

If you already have a working SD card and just want to test different splash screens:

### Step 1: Mount the SD Card Partitions

```bash
# Insert SD card and identify partitions
lsblk

# Mount the rootfs partition (usually partition 10)
sudo mount /dev/sda10 /mnt

# The splash images are in /usr/share/splashscreen/
ls -l /mnt/usr/share/splashscreen/
```

### Step 2: Replace Splash Image

```bash
# Backup original
sudo cp /mnt/usr/share/splashscreen/ST30739_splash-480x272.png \
    /mnt/usr/share/splashscreen/ST30739_splash-480x272.png.backup

# Copy your custom splash
sudo cp ~/path/to/your/custom_splash.png \
    /mnt/usr/share/splashscreen/ST30739_splash-480x272.png

# Ensure correct permissions
sudo chmod 644 /mnt/usr/share/splashscreen/*.png

# Unmount
sudo umount /mnt
sync
```

### Step 3: Boot and Test

Insert SD card and power on - your custom splash should appear!

**Pros:** Very fast, no rebuild required  
**Cons:** Changes will be lost if you re-flash the image

---

## Animated Splash Screen (Advanced)

OpenSTLinux also supports animated splash screens using a sequence of PNG frames.

### Animation Location

```bash
cd ~/openstlinux-build/layers/meta-st/meta-st-openstlinux/recipes-core/psplash/psplash-drm/pictures-animated/
```

### Create Animation Frames

```bash
# Your animation should be a sequence of numbered PNG files
# Example: splashscreen-animated_00001.png to splashscreen-animated_00060.png

# Generate frames from video (if you have a video)
ffmpeg -i your_video.mp4 -vf "scale=480:272,fps=15" \
    splashscreen-animated_%05d.png

# Or from GIF
convert animation.gif -resize 480x272 \
    splashscreen-animated_%05d.png
```

### Replace Animation Frames

```bash
cd ~/openstlinux-build/layers/meta-st/meta-st-openstlinux/recipes-core/psplash/psplash-drm/pictures-animated/

# Backup originals
mkdir -p ~/original_animation_backup
cp *.png ~/original_animation_backup/

# Copy your frames
cp ~/path/to/your/frames/splashscreen-animated_*.png ./

# Rebuild
cd ~/openstlinux-build
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco
bitbake -c cleansstate psplash-drm
bitbake st-image-weston
```

---

## Customize Splash Behavior

### Change Splash Display Resolution

Edit your local.conf:

```bash
cd ~/openstlinux-build/build-openstlinuxweston-stm32mp13-disco/conf
vi local.conf

# Add this line to force specific resolution
SPLASH_IMAGES = "file://ST30739_splash-480x272.png;outsuffix=default"
```

### Disable Splash Screen

```bash
# In local.conf, add:
DISTRO_FEATURES:remove = "psplash"

# Then rebuild
bitbake st-image-weston
```

### Change Splash Duration

The splash screen automatically closes when systemd finishes booting. To control timing:

```bash
# On the target (after booting), edit the service
vi /lib/systemd/system/psplash-drm-start.service

# Modify or add:
[Service]
ExecStartPost=/bin/sleep 5
ExecStartPost=/usr/bin/psplash-drm-quit

# Reload systemd
systemctl daemon-reload
```

---

## Testing Your Splash Screen

### Preview Before Building

```bash
# Install preview tool
sudo apt-get install -y feh

# Preview your splash image
feh ~/path/to/your/custom_splash.png

# Check dimensions
file ~/path/to/your/custom_splash.png
identify ~/path/to/your/custom_splash.png
```

### Verify on Target

```bash
# After booting, check which splash was used
systemctl status psplash-drm-start.service

# View available splash images on target
ls -lh /usr/share/splashscreen/

# Manually trigger splash (for testing)
psplash-drm /usr/share/splashscreen/ST30739_splash-480x272.png &

# Close splash
psplash-drm-quit
```

---

## Common Resolutions for STM32MP Boards

| Board/Display | Resolution | Filename Pattern |
|---------------|------------|------------------|
| STM32MP135-DK (default) | 480x272 | ST30739_splash-480x272.png |
| STM32MP157-DK2 | 800x480 | ST30739_splash-800x480.png |
| HDMI 720p | 1280x720 | ST30739_splash-1280x720.png |
| HDMI 1080p | 1920x1080 | ST30739_splash-1920x1080.png |
| Portrait mode | 480x800 | ST30739_splash-480x800.png |

---

## Design Tips for Boot Splash

1. **Keep it simple** - Complex images may slow boot
2. **Use brand colors** - Match your product branding
3. **Center important content** - Avoid edges (screen bezels)
4. **Test on actual hardware** - Colors may differ from PC display
5. **Consider boot time** - Splash shows ~2-5 seconds typically
6. **Use dark backgrounds** - Reduces power consumption on OLED displays
7. **Include version/copyright** - Add text overlay if needed

### Example: Add Text to Image

```bash
# Add company name/logo with ImageMagick
convert your_logo.png \
    -resize 480x272 \
    -background black \
    -gravity center \
    -extent 480x272 \
    -fill white \
    -pointsize 24 \
    -gravity south \
    -annotate +0+20 "Powered by Your Company" \
    custom_splash-480x272.png
```

---

## Troubleshooting

### Splash Not Showing

**Check if psplash service is enabled:**
```bash
systemctl status psplash-drm-start.service
systemctl is-enabled psplash-drm-start.service
```

**Check display driver:**
```bash
ls /dev/dri/
# Should show card0

# Check if DRM is working
modetest -M stm
```

### Wrong Resolution Displayed

**Check what psplash is using:**
```bash
# On target
journalctl -u psplash-drm-start.service
```

**Force specific resolution in recipe:**
```bash
# In psplash-drm.bb or your bbappend
SPLASH_IMAGES = "file://ST30739_splash-480x272.png;outsuffix=default"
```

### Image Appears Corrupted

**Verify PNG format:**
```bash
pngcheck your_custom_splash.png

# Fix if needed
convert your_custom_splash.png -define png:color-type=2 fixed_splash.png
```

### Splash Shows Old Image After Rebuild

**Clean sstate cache:**
```bash
bitbake -c cleansstate psplash-drm
rm -rf tmp-glibc/sstate-control/*psplash*
bitbake psplash-drm
```

---

## Quick Reference Commands

```bash
# One-liner to replace and rebuild (Method 1)
cd ~/openstlinux-build/layers/meta-st/meta-st-openstlinux/recipes-core/psplash/psplash-drm/pictures/ && \
cp ~/your_splash.png ST30739_splash-480x272.png && \
cd ~/openstlinux-build && \
source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco && \
bitbake -c cleansstate psplash-drm && bitbake st-image-weston

# Check splash screen on running system
systemctl status psplash-drm-start.service
ls -lh /usr/share/splashscreen/

# Convert any image to proper format
convert input.png -resize 480x272 -background black \
    -gravity center -extent 480x272 output.png

# Create multiple resolutions at once
for res in 480x272 800x480 1024x600 1280x720 1920x1080; do
    convert your_logo.png -resize ${res} -background black \
        -gravity center -extent ${res} custom_splash-${res}.png
done
```

---

## Additional Resources

- [Yocto Project Documentation](https://docs.yoctoproject.org/)
- [psplash on GitHub](https://github.com/embear/psplash)
- [DRM/KMS Documentation](https://www.kernel.org/doc/html/latest/gpu/drm-kms.html)
- [STM32MP Wiki - Display](https://wiki.st.com/stm32mpu/wiki/Display_overview)

---

**Last Updated:** November 9, 2025  
**Tested On:** OpenSTLinux v6.1.0 (STM32MP135F-DK)  
**Splash System:** psplash-drm with DRM/KMS support
