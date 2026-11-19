# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: LT
# Maintainer: LT
# FPD-patched xilpm-ng grows the image selector past the default 384 KiB slot;
# enlarge the primary + backup image-selector slots to 512 KiB.
IMAGE_SELECTOR_BACKUP_OFFSET       = "0x8_0000"
IMAGE_SELECTOR_SCRATCHPAD_OFFSET   = "0x10_0000"
