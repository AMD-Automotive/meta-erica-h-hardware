# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: KC
# Maintainer: KC
# OSPI Memory Map - 1 Gbit (128 MiB) flash - DIRECT BOOT (no image selector)
#
# The Versal ROM boots the application PDI (boot.bin) straight from offset 0x0.
# The image-selector first-boot (~300 ms, and currently failing its A/B bank
# read -> "Read Active bank data failed") is removed entirely.
#
# Trade-off: no PDI-level A/B / recovery / capsule-at-boot. Rootfs A/B via RAUC
# is a separate mechanism and is unaffected. To restore the selector, drop the
# EDF_OSPI_IMAGE_SELECTOR line below (the class default is "1").
#
# App PDI (boot.bin)  : 0x0000_0000  -> up to USER_SCRATCHPAD (~117 MiB avail)
# Boot-audio clip     : 0x0758_0000  (USER_SCRATCHPAD, unchanged offset)
# Total flash size    : 0x0800_0000 = 128 MiB (1 Gbit)

EDF_OSPI_IMAGE_SELECTOR = "0"

# App PDI boots directly from the ROM POR offset.
IMAGE_A_OFFSET                     = "0x0000_0000"

# Boot-audio clip location (must match the offset the PLM reads) and flash size.
USER_SCRATCHPAD_OFFSET             = "0x0758_0000"
SPI_SIZE                           = "0x0800_0000"

# Retained only to satisfy the layout-variable validation in
# erica-edf-spi-image.bbclass; UNUSED when the image selector is disabled
# (nothing is written to these regions).
IMAGE_SELECTOR_OFFSET              = "0x0000_0000"
IMAGE_SELECTOR_BACKUP_OFFSET       = "0x0006_0000"
IMAGE_SELECTOR_SCRATCHPAD_OFFSET   = "0x000C_0000"
IMAGE_RECOVERY_OFFSET              = "0x000E_0000"
IMAGE_RECOVERY_META_OFFSET         = "0x014E_0000"
CAPSULE_METADATA_OFFSET            = "0x0150_0000"
CAPSULE_METADATA_BACKUP_OFFSET     = "0x0152_0000"
UBOOT_ENV_OFFSET                   = "0x0154_0000"
UBOOT_ENV_BACKUP_OFFSET            = "0x0156_0000"
IMAGE_B_OFFSET                     = "0x0458_0000"