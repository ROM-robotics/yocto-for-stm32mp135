# Custom splash screen for ROM project
# This bbappend overrides the default ST splash screen with custom ROM splash

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Override the do_install to use only our custom pictures
do_install:append() {
    # Remove ST default pictures
    rm -f ${D}${datadir}/splashscreen/*
    
    # Install our custom ROM splash pictures
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -m 644 ${WORKDIR}/pictures/* ${D}${datadir}/splashscreen/
    fi
}
