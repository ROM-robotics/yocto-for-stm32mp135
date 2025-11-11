SUMMARY = "Xprinter thermal printer driver support"
DESCRIPTION = "CUPS driver and utilities for Xprinter thermal printers"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Xprinter uses ESC/POS protocol - compatible with Generic text-only driver
RDEPENDS:${PN} = "cups cups-filters"

# Install printer configuration and PPD files
SRC_URI = "file://xprinter-escpos.ppd \
           file://xprinter-setup.sh"

S = "${WORKDIR}"

do_install() {
    # Install PPD file for CUPS
    install -d ${D}${datadir}/cups/model/xprinter
    install -m 0644 ${WORKDIR}/xprinter-escpos.ppd ${D}${datadir}/cups/model/xprinter/
    
    # Install setup script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/xprinter-setup.sh ${D}${bindir}/xprinter-setup
}

FILES:${PN} = "${datadir}/cups/model/xprinter/* ${bindir}/xprinter-setup"
