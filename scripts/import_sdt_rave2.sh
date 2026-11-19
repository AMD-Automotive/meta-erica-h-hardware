#!/bin/bash
# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: KC, LT
# Maintainer: KC

# Help function to display usage information
print_help() {
    echo "System Device tree import Util - Kris Chaplin - Jun 2025"
    echo "========================================================"
    echo " "
    echo "Usage: $0 [--seg] <handoff> <machine name>"
    echo "Handoff is the online location of the handoff tarball"
    echo "      eg: http://server/file.tar.gz"
    echo "Machine name is the name of the generated machine"
    echo "      eg: rave2-baseline rave2-ecp"
    echo " "
    echo "Options:"
    echo "  --seg, --sdt   Generate a SEGMENTED-configuration machine (Versal)."
    echo "                 Adds 'gen-machineconf -g full' so the PL is split into"
    echo "                 a pl.dtsi (overlay source) and loaded from Linux at"
    echo "                 runtime instead of by the bootloader, and appends the"
    echo "                 no-PL bootgen deltas (BOOTBIN_NO_PL=1 etc.) so the PL"
    echo "                 is excluded from BOOT.BIN and the boot DTB."
    echo "                 eg: $0 --seg http://server/file.tar.gz rave2-ecp-seg"
    echo "  --amp          Enable the R52_2 (OpenAMP, physical Cluster B core 0,"
    echo "                 TCM 0xEBA80000) and R52_4 (libmetal/CANFD, physical"
    echo "                 Cluster C core 0, TCM 0xEBB00000) baremetal domains"
    echo "                 (CONFIG_YOCTO_BBMC_CORTEXR52_2_BAREMETAL=y,"
    echo "                 CONFIG_YOCTO_BBMC_CORTEXR52_4_BAREMETAL=y). Deliberately"
    echo "                 different physical clusters -- see"
    echo "                 R52_TCM_CLUSTER_ADDRESSING_FINDINGS.md. Both R52 cores are"
    echo "                 already present in the SDT hardware handoff; this flag"
    echo "                 just asks gen-machineconf to split them out as domains."
    echo "                 Always on for rave2-ecp-2026-1."
    echo " "
    exit 1
}

        # Exit immediately if a command exits with a non-zero status.
        set -e

        # Parse options (default behaviour, with no flag, is byte-identical to
        # the original flat import).
        SEG=0
        AMP=0
        POSITIONAL=()
        while [ "$#" -gt 0 ]; do
                case "$1" in
                        --seg|--sdt) SEG=1; shift;;
                        --amp) AMP=1; shift;;
                        -h|--help) print_help;;
                        --) shift; while [ "$#" -gt 0 ]; do POSITIONAL+=("$1"); shift; done;;
                        -*) echo "Unknown option: $1"; print_help;;
                        *) POSITIONAL+=("$1"); shift;;
                esac
        done
        set -- "${POSITIONAL[@]}"

        # Check the number of arguments
        if [ "$#" -ne 2 ]; then
                print_help
        fi
        handoff=$1
	machinename=$2

	# Machines whose images ship the R52 AMP firmware always get the domains,
	# so CI re-imports (sdt_import_jobs.yml, no flags) don't silently drop them.
	case "${machinename}" in
		rave2-ecp-2026-1) AMP=1;;
	esac

        echo "Handoff file = ${handoff}"
	echo "Machine Name = ${machinename}"
	if [ "$SEG" -eq 1 ]; then
		echo "Mode         = SEGMENTED (gen-machineconf -g full; runtime PL)"
	else
		echo "Mode         = flat (PL loaded at boot)"
	fi
	if [ "$AMP" -eq 1 ]; then
		echo "AMP domains  = R52_2 (OpenAMP) + R52_4 (libmetal/CANFD) enabled"
	fi

	rm -rf tmpsdt
	mkdir tmpsdt && cd tmpsdt

	wget ${handoff}
	tar xf `basename ${handoff}`

	# Segmented configuration separates the PL into a pl.dtsi (overlay source)
	# loaded by Linux at runtime; flat keeps the PL in the boot device tree.
	GENMC_EXTRA=()
	if [ "$SEG" -eq 1 ]; then
		GENMC_EXTRA+=(-g full)
	fi
	# R52_2/R52_4 are already present in every Versal Gen2 SDT handoff (verified
	# in sdt_artifacts/system-top.dts: cpus_r52_0..cpus_r52_9); gen-machineconf
	# only splits a cluster into its own baremetal domain when explicitly asked.
	# R52_2 (physical Cluster B core0) = OpenAMP, R52_4 (physical Cluster C
	# core0) = libmetal/CANFD -- deliberately different physical clusters, see
	# R52_TCM_CLUSTER_ADDRESSING_FINDINGS.md (symbolic cortexr52_N labels do
	# not bind the physical cluster; only the sram:/elfload: TCM address in
	# the domain-file does). conf/machineyaml/rave2-amp-domains.yaml declares
	# the CONFIG_YOCTO_BBMC_CORTEXR52_{2,4}_BAREMETAL kconfig + the
	# --domain-file chain together (same --template mechanism as the real EDF/
	# VEK385 flow, see R52_TCM_CLUSTER_ADDRESSING_FINDINGS.md and
	# versal-2ve-2vm-vek385-revb-multidomain.yaml for reference) so Lopper adds
	# the IPI mailbox relation, reserved-memory carveouts, and (for R52_4)
	# CANFD1/CANFD3 ownership on top of the domains those kconfig entries
	# create; the domain names ("cortexr52_2"/"cortexr52_4") match
	# gen-machineconf's own auto-generated ESW_MACHINE identifiers so Lopper
	# merges into the existing domain instead of creating a separate one.
	if [ "$AMP" -eq 1 ]; then
		GENMC_EXTRA+=(--template ../conf/machineyaml/rave2-amp-domains.yaml)
	fi

	MACHINE=amd-cortexa78-mali-common gen-machineconf parse-sdt \
	--hw-description ./sdt_artifacts/ \
	-c ./conf \
	--machine-name ${machinename} \
	--add-config CONFIG_SUBSYSTEM_SERIAL_TF-A_IP_NAME="pl011_1" \
	--add-config CONFIG_SUBSYSTEM_UBOOT_APPEND_BASEADDR=disable \
	"${GENMC_EXTRA[@]}"

    # Drop the stray 'asu' MACHINE_FEATURE (gen-machineconf emits it, but the
    # rave2 boards do not use the ASU feature). Position-independent: in flat
    # mode 'asu' is the trailing token, but in segmented (-g full) mode it is
    # followed by 'fpga-overlay', so match ' asu' before any space or quote.
    sed -i -E '/^[[:space:]]*MACHINE_FEATURES[[:space:]]*\+=/ s/[[:space:]]+asu([[:space:]"])/\1/' conf/machine/${machinename}.conf
    sed -i -E 's/^[[:space:]]*TFA_CONSOLE[[:space:]]*\?=[[:space:]]*"pl011"/TFA_CONSOLE ?= "pl011_1"/' conf/machine/${machinename}.conf

    # Drop 'usbpsu' from the R52_2/R52_4 baremetal/Zephyr domains' MACHINE_FEATURES.
    # gen-machineconf's feature list is generated from the whole hardware design
    # (USB exists on the SoC), but Lopper's per-domain device tree pruning shows
    # these cores cannot reach the USB controller (no usb@ node in their own
    # generated dts) -- unlike VEK385's RPU_1, whose domain dts DOES retain a
    # usb@ node. Without this strip, usbpsu's do_compile fails late with
    # undeclared XPAR_PSU_USB_0_* (the domain's xparameters.h never gets them).
    for amp_features_conf in \
        conf/machine/include/${machinename}/${machinename}-cortexr52-2-zephyr-features.conf \
        conf/machine/include/${machinename}/${machinename}-cortexr52-4-baremetal-features.conf
    do
        [ -f "$amp_features_conf" ] && sed -i -E 's/[[:space:]]+usbpsu([[:space:]"])/\1/' "$amp_features_conf"
    done
	sed -i 's/0x200000/0x20200000/g' conf/machine/${machinename}.conf
	sed -i "s|^SDT_URI =.*|SDT_URI = \"$handoff\"|g" conf/machine/${machinename}.conf

	sed -i 's|^SDT_URI\[S\] =.*|SDT_URI[S] = "${WORKDIR}/sdt_artifacts"|g' conf/machine/${machinename}.conf
	filesha=$(sha256sum "`basename $handoff`" | awk '{ print $1 }')
	sed -i "/^SDT_URI\[S\]/a SDT_URI[sha256sum] = \"${filesha}\"" conf/machine/${machinename}.conf

	# Segmented-configuration deltas. Appended (idempotently: a re-import
	# regenerates the conf then re-appends these) so the PL is kept out of
	# BOOT.BIN and stripped from the boot DTB, then loaded at runtime.
	# The hand-authored ${machinename}.dtsi is NOT generated here; it is picked
	# up automatically via SYSTEM_USER_DTSI ?= "${MACHINE}.dtsi" and survives
	# re-import because gen-machineconf never emits it (see device-tree.bbappend).
	if [ "$SEG" -eq 1 ]; then
                mapfile -t pld_pdis < <(find sdt_artifacts -maxdepth 1 -type f -name '*_pld.pdi' -printf '%f\n')
                if [ "${#pld_pdis[@]}" -ne 1 ]; then
                        echo "Expected exactly one runtime *_pld.pdi, found ${#pld_pdis[@]}" >&2
                        exit 1
                fi
		cat >> conf/machine/${machinename}.conf << 'SEGEOF'

#### Segmented-configuration deltas (added by import_sdt_rave2.sh --seg)
# Exclude the PL from BOOT.BIN and strip /amba_pl from the boot DTB; the PL is
# loaded from Linux at runtime from the pl.dtsi-derived overlay + PDI.
BOOTBIN_NO_PL = "1"
# Distinguish the running board in the u-boot/Linux model banner.
NOPL_MODEL_SUFFIX = " (seg)"
# Marker consumed by the edf-ospi PL overlay + PDI deploy step.
PL_RUNTIME_LOAD = "1"
SEGEOF
                echo "PLD_PDI_FILE = \"${pld_pdis[0]}\"" >> conf/machine/${machinename}.conf
	fi

	cat conf/machine/${machinename}.conf | grep SDT_
        mkdir -p ../conf
        cp -rv conf/* ../conf/
