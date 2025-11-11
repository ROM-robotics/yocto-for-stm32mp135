# ST Image Weston + Qt6
SUMMARY = "OpenSTLinux Weston image with Qt6 support"
LICENSE = "MIT"

# Inherit from st-image-weston (includes Weston compositor + display support)
require recipes-st/images/st-image-weston.bb

# Add essential Qt6 packages only
IMAGE_INSTALL += " \
    qtbase \
    qtbase-plugins \
    qtbase-tools \
    qtdeclarative \
    qtwayland \
    qtsvg \
"

# Add gdbserver for remote debugging
IMAGE_INSTALL += " \
    gdbserver \
"

# Add CUPS and printer support for Xprinter
IMAGE_INSTALL += " \
    cups \
    cups-filters \
    ghostscript \
    libusb1 \
    xprinter-driver \
"

# Replace dropbear with OpenSSH
IMAGE_FEATURES:remove = "ssh-server-dropbear"
IMAGE_FEATURES += "ssh-server-openssh"

# Increase rootfs size limit for Weston + Qt6
IMAGE_ROOTFS_MAXSIZE = "1048576"

# Ensure Qt6 target development files are included in SDK
TOOLCHAIN_TARGET_TASK += " \
    qtbase-dev \
    qtdeclarative-dev \
    qtwayland-dev \
    qtsvg-dev \
"
