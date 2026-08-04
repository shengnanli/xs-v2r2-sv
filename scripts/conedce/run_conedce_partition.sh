#!/usr/bin/env bash
# Run ONE cone-DCE Rob partition FM proof (reduced golden ref vs reduced impl).
# Usage: run_conedce_partition.sh <fam>  fam in {commit exception perf vecexcp lsq}
set -u
FAM="$1"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="/home/eda/xs-env/G0-canonical/golden-rtl"
GEN="${GEN_DIR:-/tmp/rob-conedce-evidence/gen}"
RTL="/tmp/rob-conedce/verif/signoff/conedce/impl_freeze"   # freeze-commit impl A+B artifacts
EV="${EVROOT:-/tmp/rob-conedce-evidence}/part_${FAM}"
rm -rf "$EV"; mkdir -p "$EV"

# golden leaf deps (both sides elaborate — white box; the 7 official-PASS children)
DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
  $G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
  $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
  $G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv"

REF="$GEN/Rob_golden_${FAM}.sv"
IMPL="$GEN/Rob_impl_${FAM}.sv"

# ref: reduced golden Rob + golden deps
export FM_REF_SRCS="$REF $DEPS"
# impl: pkg + core + lsq_deep outputs + reduced impl Rob wrapper + golden deps
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $IMPL $DEPS"
export FM_TOP="Rob"

cd "$EV"
echo "=== cone-DCE partition FM: $FAM  (ref=$REF impl=$IMPL) ==="
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" -file "$HERE/fm_conedce_partition.tcl" \
    > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC" | tee "$EV/rc.txt"
grep -viE '^\s*#' "$EV/fm.log" | grep -iE "SUCCEEDED|FAILED|Passing|Failing|Unmatched|equivalent|abort|no compare" | tail -15
exit $RC
