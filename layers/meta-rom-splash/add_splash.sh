#!/bin/bash
# add_splash.sh - Helper script to add custom splash screen images to meta-rom-splash layer
# Usage: ./add_splash.sh <your_image.png>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPLASH_DIR="${SCRIPT_DIR}/recipes-core/psplash/psplash-drm/pictures"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <input_image.png> [--all-resolutions]"
    echo ""
    echo "This script converts your custom image to the correct splash screen format."
    echo ""
    echo "Options:"
    echo "  <input_image.png>      Your custom logo/image (PNG, JPG, or any ImageMagick supported format)"
    echo "  --all-resolutions      Generate splash images for all supported resolutions"
    echo "                         Default: Only generates 480x272 (STM32MP135-DK)"
    echo ""
    echo "Examples:"
    echo "  $0 my_logo.png                    # Generate only 480x272"
    echo "  $0 my_logo.png --all-resolutions  # Generate all resolutions"
    exit 1
}

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed${NC}"
    echo "Install it with: sudo apt-get install imagemagick"
    exit 1
fi

# Parse arguments
if [ $# -lt 1 ]; then
    usage
fi

INPUT_IMAGE="$1"
ALL_RESOLUTIONS=false

if [ "$2" == "--all-resolutions" ]; then
    ALL_RESOLUTIONS=true
fi

# Check if input file exists
if [ ! -f "$INPUT_IMAGE" ]; then
    echo -e "${RED}Error: Input file '$INPUT_IMAGE' not found${NC}"
    exit 1
fi

echo -e "${GREEN}=== ROM Splash Screen Generator ===${NC}"
echo "Input image: $INPUT_IMAGE"
echo "Output directory: $SPLASH_DIR"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$SPLASH_DIR"

# Define resolutions
declare -A resolutions
resolutions["480x272"]="STM32MP135-DK (Default)"
resolutions["800x480"]="STM32MP157-DK2"
resolutions["1024x600"]="10-inch displays"
resolutions["1280x720"]="HDMI 720p"
resolutions["1920x1080"]="HDMI 1080p"
resolutions["480x800"]="Portrait mode"
resolutions["720x1280"]="Portrait HD"

# Determine which resolutions to generate
if [ "$ALL_RESOLUTIONS" = true ]; then
    RESOLUTIONS_TO_GENERATE=("480x272" "800x480" "1024x600" "1280x720" "1920x1080" "480x800" "720x1280")
else
    RESOLUTIONS_TO_GENERATE=("480x272")
fi

# Generate splash images
echo "Generating splash images..."
for res in "${RESOLUTIONS_TO_GENERATE[@]}"; do
    output_file="${SPLASH_DIR}/ST30739_splash-${res}.png"
    description="${resolutions[$res]}"
    
    echo -ne "  ${YELLOW}[Processing]${NC} ${res} (${description})..."
    
    convert "$INPUT_IMAGE" \
        -resize "${res}" \
        -background black \
        -gravity center \
        -extent "${res}" \
        -define png:color-type=2 \
        "$output_file"
    
    if [ $? -eq 0 ]; then
        size=$(du -h "$output_file" | cut -f1)
        echo -e "\r  ${GREEN}[✓ Done]${NC} ${res} (${description}) - Size: ${size}"
    else
        echo -e "\r  ${RED}[✗ Failed]${NC} ${res}"
    fi
done

echo ""
echo -e "${GREEN}=== Splash images generated successfully! ===${NC}"
echo ""
echo "Generated files:"
ls -lh "$SPLASH_DIR"/*.png 2>/dev/null || echo "No PNG files found"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the generated images in: $SPLASH_DIR"
echo "2. Rebuild your image:"
echo "   cd ~/openstlinux-build"
echo "   source layers/openembedded-core/oe-init-build-env build-openstlinuxweston-stm32mp13-disco"
echo "   bitbake -c cleansstate psplash-drm"
echo "   bitbake st-image-weston"
echo ""
echo "3. Flash to SD card and test!"
