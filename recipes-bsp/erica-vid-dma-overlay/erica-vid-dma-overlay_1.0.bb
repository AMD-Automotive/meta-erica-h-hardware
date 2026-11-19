# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: JC, LT
# Maintainer: JC
SUMMARY = "Runtime DT overlay enabling the erica-vid-dma platform devices"
DESCRIPTION = "Builds erica-vid-dma.dtbo from erica-vid-dma.dtso and installs \
it to /lib/firmware/.  Loaded by run_display_sentry.sh at app start \
(via /sys/kernel/config/device-tree/overlays/) to flip the 12 axi4s_vid_dma \
instances from status=disabled (set in vek385-imx623-sentry.dtsi) to status=okay \
so the erica-vid-dma kernel driver binds.  Unloaded on app exit, allowing \
clean re-launch and avoiding ISP probe-ordering races at boot."
LICENSE = "BSD-3-Clause | GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/BSD-3-Clause;md5=550794465ba0ec5312d6919e203a55f9"

# NOTE: The deployed appdev rootfs (erica-appdev-image) is built with
# MACHINE=amd-cortexa78-mali-common (a multi-board generic A78 rootfs)
# per .github/workflows/hexcam_builder_vek280.yml::Build-appdev-image-2025-2,
# NOT MACHINE=vek385-imx623-sentry.  If we restrict COMPATIBLE_MACHINE to
# "vek385-imx623-sentry" the recipe is silently skipped at parse time for the
# generic rootfs build and the .dtbo never makes it into the wic.  The
# resulting .dtbo is noarch and ~few KB, so allow it on the generic rootfs
# (it is only loaded by run_display_sentry.sh on the vek385 board).
COMPATIBLE_MACHINE = "amd-cortexa78-mali-common|vek385-imx623-sentry"

SRC_URI = "file://erica-vid-dma.dtso"
S = "${WORKDIR}"

inherit allarch

DEPENDS = "dtc-native"

do_compile() {
    # -@ : keep symbols so the overlay can resolve labels against the base DTB
    dtc -@ -I dts -O dtb -o ${B}/erica-vid-dma.dtbo ${S}/erica-vid-dma.dtso
}

# Install under a board-namespaced subdir so the .dtbo cannot be mistaken
# for a generic firmware blob on the shared appdev rootfs (which is also
# flashed on rave2-xylon-sentry / vek385-xylon-sentry where this overlay must NOT
# be applied -- the kernel would reject it via __fixups__ mismatch anyway,
# but namespacing makes the intent explicit).  The loader
# (run_display_sentry.sh) reads from this exact path.
do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware/vek385-imx623-sentry
    install -m 0644 ${B}/erica-vid-dma.dtbo \
        ${D}${nonarch_base_libdir}/firmware/vek385-imx623-sentry/erica-vid-dma.dtbo

    install -d ${D}${nonarch_base_libdir}/firmware/rave2-imx623-sentry
    install -m 0644 ${B}/erica-vid-dma.dtbo \
        ${D}${nonarch_base_libdir}/firmware/rave2-imx623-sentry/erica-vid-dma.dtbo

    # Backward compatibility for deployed sentry-npu scripts still probing
    # /lib/firmware/vek385-isp-sentry/erica-vid-dma.dtbo.
    install -d ${D}${nonarch_base_libdir}/firmware/vek385-isp-sentry
    install -m 0644 ${B}/erica-vid-dma.dtbo \
        ${D}${nonarch_base_libdir}/firmware/vek385-isp-sentry/erica-vid-dma.dtbo
}

FILES:${PN} = " \
    ${nonarch_base_libdir}/firmware/vek385-imx623-sentry/erica-vid-dma.dtbo \
    ${nonarch_base_libdir}/firmware/rave2-imx623-sentry/erica-vid-dma.dtbo \
    ${nonarch_base_libdir}/firmware/vek385-isp-sentry/erica-vid-dma.dtbo \
"
