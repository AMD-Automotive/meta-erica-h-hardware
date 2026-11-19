# Copyright © Advanced Micro Devices, Inc., or its affiliates. All rights reserved.
# SPDX-License-Identifier: MIT
# Contributors: Uwe Gertheinrich
# Maintainer: Uwe Gertheinrich

FILESEXTRAPATHS:prepend := "${THISDIR}/lopper:"

# Real fix (not diagnostic): xlnx_generate_cmake_metadata() (bmcmake_metadata_xlnx.py)
# picks the "chosen" node of whichever domain happens to be traversed LAST
# under /domains, instead of the domain actually being built -- confirmed via
# direct inspection of the generated StandaloneExample.cmake on RAVE2
# (RPU_4_BM's own "chosen" -- serial1 -- was overridden by PMC_MB's "chosen"
# -- serial0 -- purely due to /domains traversal order). See patch header for
# full root-cause analysis and fix rationale.
SRC_URI += "file://0001-bmcmake-metadata-xlnx-scope-chosen-node-to-domain.patch"

# Hardening (not the root-cause fix above):
# openamp_xlnx.py has the same unsafe "n.parent.parent.propval('cpus')[0]"
# idiom in four places. One had no guard at all. Two others guard only
# against Lopper's "property absent" sentinel (== ['']), not a genuine
# empty list ([]), which can also trigger an uncaught IndexError (confirmed
# via `find /tmp -name openamp_xlnx.py` across every installed copy during
# a failing libmetal-demo-remote do_configure -- see Execution_plan.md for
# the investigation; the actual root cause for that crash turned out to be
# elsewhere, a stale domain-yaml address, but these guards are correct
# hardening regardless). The fourth occurrence is dead code for our
# platform (guarded by an earlier
# `if get_platform(...) in [VERSAL2, VERSAL_NET]: return False`) and is
# left untouched.
python do_patch:append() {
    import os

    path = os.path.join(d.getVar('S'), 'lopper', 'assists', 'openamp_xlnx.py')
    with open(path) as f:
        src = f.read()

    # do_patch can re-run on an already-patched ${S} when only its own signature changed (no do_unpack).
    if '_cpus_phandle = n.parent.parent.propval("cpus")[0]' in src and \
            src.count('n.parent.parent.propval("cpus") in ([\'\'], [])') == 3:
        bb.note("cpus-propval guard hardening already present in %s" % path)
        return

    # Site 1: openamp_nontree_outputs_handler() -- no guard at all before this fix.
    old1 = (
        '        # ensure target domain matches\n'
        '        if os != "linux_dt" and match_cpunode.parent != sdt.tree.pnode(n.parent.parent.propval("cpus")[0]):\n'
        '            continue\n'
    )
    new1 = (
        '        # ensure target domain matches\n'
        '        try:\n'
        '            _cpus_phandle = n.parent.parent.propval("cpus")[0]\n'
        '        except IndexError:\n'
        '            print("openamp_nontree_outputs_handler: skipping node with empty cpus propval:", n, "parent.parent", n.parent.parent)\n'
        '            continue\n'
        '        if os != "linux_dt" and match_cpunode.parent != sdt.tree.pnode(_cpus_phandle):\n'
        '            continue\n'
    )
    if old1 not in src:
        bb.fatal("openamp_xlnx.py: site 1 (handler) source block not found, recipe may have changed upstream")
    src = src.replace(old1, new1)

    # Sites 2+3+4: three other call sites guard against the "absent"
    # sentinel (== ['']) but not a genuine empty list ([]). Broaden all
    # three -- this literal substring occurs exactly 3 times (confirmed via
    # grep; one of them is the guard immediately preceding site 1's
    # already-patched try/except, which we missed on the first pass).
    old2 = 'n.parent.parent.propval("cpus") == [\'\']'
    new2 = 'n.parent.parent.propval("cpus") in ([\'\'], [])'
    count = src.count(old2)
    if count != 3:
        bb.fatal("openamp_xlnx.py: expected exactly 3 occurrences of the cpus-absent guard, found %d; recipe may have changed upstream" % count)
    src = src.replace(old2, new2)

    with open(path, 'w') as f:
        f.write(src)

    bb.note("cpus-propval guard hardening applied to %s" % path)
}
