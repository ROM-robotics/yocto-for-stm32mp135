#!/bin/bash
# create_test_splash.sh - Creates a simple test splash screen
# This generates a basic splash with text to verify the system works

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/recipes-core/psplash/psplash-drm/pictures"

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed"
    echo "Install it with: sudo apt-get install imagemagick"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Creating test splash screen (480x272)..."

# Create a simple test splash with ROM branding
convert -size 480x272 xc:black \
    -fill white \
    -pointsize 48 \
    -gravity center \
    -annotate +0-50 "ROM" \
    -pointsize 24 \
    -annotate +0+0 "Custom Boot Splash" \
    -pointsize 16 \
    -gravity south \
    -annotate +0+20 "Powered by OpenSTLinux" \
    -fill gray60 \
    -pointsize 12 \
    -annotate +0+5 "STM32MP135" \
    "$OUTPUT_DIR/ST30739_splash-480x272.png"

echo "✓ Test splash created: $OUTPUT_DIR/ST30739_splash-480x272.png"
echo ""
echo "Preview the image:"
echo "  display $OUTPUT_DIR/ST30739_splash-480x272.png"
echo ""
echo "To use it, rebuild:"
echo "  cd ~/openstlinux-build"
echo "  source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco"
echo "  bitbake -c cleansstate psplash-drm"
echo "  bitbake st-image-weston"
