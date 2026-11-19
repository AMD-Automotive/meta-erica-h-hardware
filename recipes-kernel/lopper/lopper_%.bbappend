# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: Uwe Gertheinrich
# Maintainer: Uwe Gertheinrich

# The lopper fixes in lopper-rave2-amp-v2026.1.inc patch lopper v2026.1
# sources. Older lopper (e.g. 2025.2) has different code there (do_patch
# would bb.fatal) and needs no fix (no RAVE2 AMP domains), so only include
# them for v2026.1.
include ${@'lopper-rave2-amp-v2026.1.inc' if d.getVar('XILINX_RELEASE_VERSION') == 'v2026.1' else ''}
