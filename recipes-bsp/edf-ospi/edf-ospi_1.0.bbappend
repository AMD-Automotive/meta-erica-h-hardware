# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: KC, LT, JC
# Maintainer: KC
COMPATIBLE_MACHINE:vek385-base = "${MACHINE}"
COMPATIBLE_MACHINE:vek385-xylon-sentry = "${MACHINE}"
COMPATIBLE_MACHINE:vek385-imx623-sentry = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-baseline = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-baseline-seg = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-baseline-2026-1 = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-ecp = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-ecp-2026-1 = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-xylon-sentry = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-imx623-sentry = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-ecp-seg = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-recovery = "${MACHINE}"
COMPATIBLE_MACHINE:rave2-display-expansion = "${MACHINE}"

# For any machine that needs an override, create an inc file 
# to change variables, such as SPI_SIZE etc

include edf-ospi-${MACHINE}.inc

# Segmented boot: pull the runtime PL artifacts (pl-design.pdi + pl.dtbo) into
# the same deploy dir as the OSPI image, so `bitbake edf-ospi` yields all three.
# The base OSPI is PL-free; these are scp'd + loaded at runtime (dfx-mgr/fpgautil).
# Hook do_build (the default target of `bitbake edf-ospi`) rather than do_deploy,
# so edf-ospi's own do_deploy task signature is unchanged (avoids a spurious
# do_deploy rerun against a sstate-restored do_compile with no ${B} image).
do_build[depends] += "${@'edf-pl-overlay:do_deploy' if d.getVar('PL_RUNTIME_LOAD') == '1' else ''}"
