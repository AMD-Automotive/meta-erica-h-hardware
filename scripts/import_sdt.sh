#!/bin/bash
# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: KC
# Maintainer: KC

# Help function to display usage information
print_help() {
    echo "System Device tree import Util - Kris Chaplin - Jun 2025"
    echo "========================================================"
    echo " "
    echo "Usage: $0 <handoff> <machine name>"
    echo "Handoff is the online location of the handoff tarball"
    echo "      eg: http://server/file.tar.gz"
    echo "Machine name is the name of the generated machine"
    echo "      eg: vek385-base"
    echo "Note: This script needs to be run from the root directory of this metalayer"
    echo "This script currently only supports Versal 2 devices with the vek385 machine overlay"
    echo " "
    exit 1
}

        # Exit immediately if a command exits with a non-zero status.
        set -e

        # Check the number of arguments
        if [ "$#" -ne 2 ]; then
                print_help
        fi
        handoff=$1
	machinename=$2

        echo "Handoff file = ${handoff}"
	echo "Machine Name = ${machinename}"

	rm -rf tmpsdt
	mkdir tmpsdt && cd tmpsdt

	wget ${handoff}
	tar xf `basename ${handoff}`

	MACHINE=amd-cortexa78-mali-common gen-machineconf parse-sdt \
	--hw-description ./sdt_artifacts/ \
	-c ./conf \
	--machine-name ${machinename} \
	--add-config CONFIG_YOCTO_BBMC_CORTEXR52_1_BAREMETAL=y \
	--add-config CONFIG_SUBSYSTEM_TF-A_SERIAL_SERIAL1_SELECT=y \
	--add-config CONFIG_SUBSYSTEM_SERIAL_TF-A_IP_NAME="pl011_1" \
	--add-config CONFIG_SUBSYSTEM_OP-TEE_SERIAL_SERIAL1_SELECT=y \
	--add-config CONFIG_SUBSYSTEM_SERIAL_OP-TEE_IP_NAME="1" \
	--add-config CONFIG_SUBSYSTEM_UBOOT_APPEND_BASEADDR=disable \
	--add-config CONFIG_YOCTO_BBMC_MICROBLAZE_RISCV_ASU=disable \
	-O versal-2ve-2vm-vek385-sdt-seg

	sed -i 's/0x200000/0x20200000/g' conf/machine/${machinename}.conf
	sed -i "s|^SDT_URI =.*|SDT_URI = \"$handoff\"|g" conf/machine/${machinename}.conf

	sed -i 's|^SDT_URI\[S\] =.*|SDT_URI[S] = "${WORKDIR}/sdt_artifacts"|g' conf/machine/${machinename}.conf
	filesha=$(sha256sum "`basename $handoff`" | awk '{ print $1 }')
	sed -i "/^SDT_URI\[S\]/a SDT_URI[sha256sum] = \"${filesha}\"" conf/machine/${machinename}.conf
	cat conf/machine/${machinename}.conf | grep SDT_
        cp -rv conf/* ../conf/
