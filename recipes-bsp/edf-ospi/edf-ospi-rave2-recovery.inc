# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: KC
# Maintainer: KC
# OSPI Memory Map - 1 Gbit (128 MiB) flash
# Image selector (primary) : 0x0006_0000 = 384 KiB
# Image selector (backup)  : 0x0006_0000 = 384 KiB
# Selector scratchpad      : 0x0002_0000 = 128 KiB
# Recovery image           : 0x0140_0000 = 20.0 MiB
# Recovery meta / gap      : 0x0002_0000 = 128 KiB
# Capsule metadata (prim)  : 0x0002_0000 = 128 KiB
# Capsule metadata (bkp)   : 0x0002_0000 = 128 KiB
# U-Boot env (primary)     : 0x0002_0000 = 128 KiB
# U-Boot env (backup)      : 0x0002_0000 = 128 KiB
# Image A slot             : 0x0300_0000 = 48.0 MiB
# Image B slot             : 0x0300_0000 = 48.0 MiB
# User scratchpad          : 0x00A8_0000 = 10.5 MiB
# Total flash size         : 0x0800_0000 = 128 MiB (1 Gbit)

IMAGE_SELECTOR_OFFSET              = "0x0000_0000"   
IMAGE_SELECTOR_BACKUP_OFFSET       = "0x0006_0000"   
IMAGE_SELECTOR_SCRATCHPAD_OFFSET   = "0x000C_0000"   
IMAGE_RECOVERY_OFFSET              = "0x000E_0000"   
IMAGE_RECOVERY_META_OFFSET         = "0x014E_0000"   
CAPSULE_METADATA_OFFSET            = "0x0150_0000"   
CAPSULE_METADATA_BACKUP_OFFSET     = "0x0152_0000"   
UBOOT_ENV_OFFSET                   = "0x0154_0000"   
UBOOT_ENV_BACKUP_OFFSET            = "0x0156_0000"   
IMAGE_A_OFFSET                     = "0x0158_0000"   
IMAGE_B_OFFSET                     = "0x0458_0000"   
USER_SCRATCHPAD_OFFSET             = "0x0758_0000"   
SPI_SIZE                           = "0x0800_0000"   