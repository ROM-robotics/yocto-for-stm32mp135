# meta-rom-splash

Custom Yocto layer for ROM project boot splash screen.

## Description

This layer provides a custom boot splash screen for STM32MP135 OpenSTLinux distribution.

## Dependencies

- meta-st-openstlinux
- openembedded-core

## Layer Structure

```
meta-rom-splash/
├── conf/
│   └── layer.conf
├── recipes-core/
│   └── psplash/
│       ├── psplash-drm_%.bbappend
│       └── psplash-drm/
│           └── pictures/
│               └── [your custom splash PNG files]
└── README.md
```

## Usage

1. Add your custom splash images (PNG format) to:
   `recipes-core/psplash/psplash-drm/pictures/`

2. Supported resolutions:
   - 480x272 (STM32MP135-DK default)
   - 800x480
   - 1024x600
   - 1280x720
   - 1920x1080

3. Name your files following the pattern:
   - `ST30739_splash-480x272.png`
   - `ST30739_splash-800x480.png`
   - etc.

4. Add layer to your build:
   ```bash
   bitbake-layers add-layer ../layers/meta-rom-splash
   ```

5. Rebuild:
   ```bash
   bitbake -c cleansstate psplash-drm
   bitbake st-image-weston
   ```

## Adding Your Custom Image

```bash
# Convert your logo to correct format
convert your_logo.png -resize 480x272 -background black \
    -gravity center -extent 480x272 \
    recipes-core/psplash/psplash-drm/pictures/ST30739_splash-480x272.png

# For multiple resolutions
for res in 480x272 800x480 1024x600 1280x720; do
    convert your_logo.png -resize ${res} -background black \
        -gravity center -extent ${res} \
        recipes-core/psplash/psplash-drm/pictures/ST30739_splash-${res}.png
done
```

## Maintainer

ROM Project Team

## License

MIT (following OpenSTLinux splash screen license)
