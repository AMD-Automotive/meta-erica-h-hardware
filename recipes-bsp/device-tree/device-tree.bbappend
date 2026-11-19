# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: JC, KC, LT
# Maintainer: JC
COMPATIBLE_MACHINE = "hexcam_20231_1-versal|rave2-xylon-sentry|rave2-imx623-sentry|vek385-imx623-sentry|vek385-xylon-sentry"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:${@bb.utils.which(d.getVar('BBPATH'), 'conf/dts/%s' % d.getVar('MACHINE'))}:"
 
SYSTEM_USER_DTSI ?= "${MACHINE}.dtsi"

# Extra dtsi files referenced from the SYSTEM_USER_DTSI via /include/.
# These are fetched + staged alongside the top-level dtsi so dtc can resolve them.
SYSTEM_USER_DTSI_EXTRA ?= ""
SYSTEM_USER_DTSI_EXTRA:vek385-imx623-sentry = "vek385-imx623-sentry-vid-dma-rd.dtsi"
SYSTEM_USER_DTSI_EXTRA:rave2-imx623-sentry = "rave2-imx623-sentry-vid-dma-rd.dtsi"

SRC_URI:append = " file://${SYSTEM_USER_DTSI}"
SRC_URI:append = "${@' ' + ' '.join(['file://%s' % f for f in (d.getVar('SYSTEM_USER_DTSI_EXTRA') or '').split()])}"

do_configure:aarch64:append() {
        cp ${WORKDIR}/${SYSTEM_USER_DTSI} ${B}/device-tree
        for f in ${SYSTEM_USER_DTSI_EXTRA}; do
                cp ${WORKDIR}/${f} ${B}/device-tree
        done
        echo "#include \"${SYSTEM_USER_DTSI}\"" >> ${DT_FILES_PATH}/${BASE_DTS}.dts
}

