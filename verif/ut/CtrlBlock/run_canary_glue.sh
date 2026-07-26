#!/usr/bin/env bash
# CtrlBlock glue-partition canary FM run (Worker H, agent/ctrlblock-w).
# See docs/backend/CtrlBlock_partition_plan.md. Partitions CtrlBlock by
# symmetrically black-boxing the 22 submodules (Rob=220K lines etc.) so the FM
# model build is tractable and the real glue equivalence gaps are surfaced.
#
# Usage: bash run_canary_glue.sh [GOLDEN_DIR]
#   GOLDEN_DIR default: /home/eda/xs-env/G0-canonical/golden-rtl
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL="$(cd "$HERE/../../../rtl" && pwd)"
GOLDEN="${1:-/home/eda/xs-env/G0-canonical/golden-rtl}"

rm -rf "$HERE/fm_work"; mkdir -p "$HERE/fm_work/CtrlBlock"

export FM_TOP=CtrlBlock
# ref = ONLY golden CtrlBlock top (submodules unresolved -> black box)
export FM_REF_SRCS="$GOLDEN/CtrlBlock.sv"
# impl = readable core + pkg + wrapper (submodules unresolved -> black box)
export FM_IMPL_SRCS="$RTL/backend/ctrlblock_pkg.sv $RTL/backend/CtrlBlock.sv $RTL/backend/CtrlBlock_wrapper.sv"
# reuse committed glue pin map
export FM_PIN_TCL="$HERE/fm_pins.tcl"

cd "$HERE" || exit 2
fm_shell -64 -work_path fm_work/CtrlBlock -file "$HERE/fm_canary_glue.tcl" \
    > fm_work/CtrlBlock/fm.log 2>&1
rc=$?
echo "CANARY_RC=$rc"
grep -E 'FM_RESULT|Passing compare|Failing compare|Aborted compare|Unverified compare' fm_work/CtrlBlock/fm.log
exit $rc
