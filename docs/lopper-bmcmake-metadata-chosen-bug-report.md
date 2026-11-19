<!--
Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
SPDX-License-Identifier: MIT
Contributors: Uwe Gertheinrich
Maintainer: Uwe Gertheinrich
-->

# Bug Report: Lopper picks the wrong domain's "chosen" node when multiple domains share a /domains parent

## Summary

`lopper/assists/bmcmake_metadata_xlnx.py`'s `xlnx_generate_cmake_metadata()` silently selects the `chosen` devicetree block of the **wrong domain** when a system devicetree defines multiple domains under a shared `/domains` parent, each carrying its own `chosen` node (e.g. for per-domain console/stdout configuration). The function has no domain-scoping logic and simply uses "the last `chosen`-named node encountered while recursively traversing the whole tree", independent of which domain/CPU is actually being built.

This causes the generated Xilinx standalone BSP (`bspconfig.h`'s `STDIN_BASEADDRESS`/`STDOUT_BASEADDRESS`) to silently point at the wrong UART for any domain that is not the last one in tree order.

## Affected version

- Repository: `https://github.com/Xilinx/lopper`
- Branch: `xlnx_rel_v2026.1.1`
- Commit: `44a55fd38fa7f9996dd1a8afc743af7ffd877777`
- File: `lopper/assists/bmcmake_metadata_xlnx.py`, function `xlnx_generate_cmake_metadata()` (around line 375)

## Reproduction

1. Define a system devicetree (or domain-yaml input to Lopper) with at least two domains under a shared `/domains` parent node, each carrying its own `chosen` block with a different `stdout-path` (e.g. domain A: `serial1`, domain B: `serial0`).
2. Build either domain's standalone BSP via the standard Yocto/esw.bbclass flow:
   ```
   lopper <system.dtb> -- bmcmake_metadata_xlnx <ESW_MACHINE> <bsp-src-dir> hwcmake_metadata <outdir>
   ```
   (this is exactly how `meta-xilinx-standalone-sdt`'s `esw.bbclass` invokes it via `do_configure:prepend()`, with `tgt_node` always `"/"` — no domain pre-selection).
3. Inspect the generated `StandaloneExample.cmake`'s `STDIN_INSTANCE` value, or the resulting `bspconfig.h`'s `STDIN_BASEADDRESS`/`STDOUT_BASEADDRESS`.

## Observed behavior

Both domains' BSPs resolve to the **same** `chosen` block — specifically, whichever domain is traversed **last** in the devicetree (tree order, not any semantic ordering). Confirmed via runtime instrumentation of `xlnx_generate_cmake_metadata()`: `tgt_node` is always `"/"` for this invocation path, and `root_node.subnodes()` recursively returns every domain's `chosen` node; the function's loop overwrites its `chosen_node` candidate on every match with no further qualification:

```python
for node in root_sub_nodes:
    try:
        if node.name == "chosen":
            chosen_node = node   # <-- overwritten on every match, last one wins
        ...
```

### Concrete reproduction data (RAVE2 / Versal Gen2 board, 4-domain system)

Devicetree had, in tree order: `/chosen` (top-level default), `/domains/RPU_2_Zephyr/chosen` (serial1), `/domains/RPU_4_BM/chosen` (serial1), `/domains/PMC_MB/chosen` (serial0).

Building `RPU_4_BM`'s standalone BSP (ESW_MACHINE matching its own CPU cluster) incorrectly resolved `STDIN_INSTANCE` to the UART instance used by `PMC_MB` (`serial0`, physical base address `0xf1920000`) instead of its own `chosen` block (`serial1`, physical base address `0xf1930000`) — purely because `PMC_MB` happens to be declared last among the sibling domains.

## Expected behavior

The `chosen` node selected should belong to the **same domain** that is actually being built (as identified by `ESW_MACHINE`/the CPU node resolved via `baremetalconfig_xlnx.py::get_cpu_node()`), not whichever domain happens to be last in tree-traversal order.

## Suggested fix

Resolve the CPU node for the domain being built first (`match_cpunode = baremetalconfig_xlnx.get_cpu_node(sdt, options)`), then prefer a `chosen` node whose **parent domain's `cpus` property phandle** matches `match_cpunode`'s enclosing CPU cluster phandle (`match_cpunode.parent.phandle`), instead of unconditionally overwriting on every "chosen"-named match. Fall back to "first chosen encountered" only if no domain match is found, to preserve behavior for single-domain/non-domain system device trees.

A working patch implementing this approach (tested end-to-end on hardware: RAVE2/Versal Gen2, `RPU_4_BM` baremetal domain) is attached as `0001-bmcmake-metadata-xlnx-scope-chosen-node-to-domain.patch`.

## Verification performed

- `STDIN_INSTANCE` in the generated `StandaloneExample.cmake` changed from the incorrect `ps_wizard_0_ps11_0_sbsauart_0` to the correct `ps_wizard_0_ps11_0_sbsauart_1` after the fix.
- `bspconfig.h`'s `STDIN_BASEADDRESS`/`STDOUT_BASEADDRESS` changed from `0xf1920000` to the correct `0xf1930000`.
- Byte-pattern search on the compiled `libmetal-demo-remote` ELF confirmed the linked binary itself only references the correct UART address (0 occurrences of the old address, 5 of the correct one).
- Flashed to real hardware (RAVE2/Versal Gen2): the `libmetal-demo-remote` firmware's console output (TF-A/BL31 boot banner, `RPU4: REMOTE: ...` messages, demo completion) now correctly appears on the intended dedicated UART, separated from the Linux/APU console which shares the formerly-conflicting UART.

## Scope / likely impact on other boards

Any board/system devicetree with more than one domain under a shared `/domains` parent, where more than one of those domains carries its own `chosen` block, is affected — not specific to RAVE2. Boards with only a single domain carrying a `chosen` block (or where the "last domain" coincidentally happens to be the one being built) would not observe the bug, which may explain why it has not previously been reported.
