#!/usr/bin/env bash
# Run ONE Rob Route B partition FM proof (self-contained, strict). Usage:
#   run_partition_fm.sh <Fam>   where Fam in {pCommit pException pPerfTraceCsrDbg pVecExcp pLsqDeep}
set -u
FAM="$1"
TOP="Rob_${FAM}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
G="/home/eda/xs-env/G0-canonical/golden-rtl"
RTL="$ROOT/rtl/backend"
EV="${EVROOT:-/tmp/rob-routeB-evidence}/$TOP"
rm -rf "$EV"; mkdir -p "$EV"

# golden leaf deps (both sides elaborate — white box)
DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
  $G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
  $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
  $G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv \
  $RTL/Rob_difftest_stubs.sv"

PART="$RTL/${TOP}_part.sv"

# REF: partition harness + golden Rob + golden deps  (module Rob -> golden)
export FM_REF_SRCS="$PART $G/Rob.sv $DEPS"
# IMPL: pkg first, then core, lsq_deep outputs, impl Rob_wrapper, partition harness, + same golden deps
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $RTL/Rob_wrapper.sv $PART $DEPS"
export FM_TOP="$TOP"

cd "$EV"
echo "=== FM partition $TOP ==="
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" -file "$HERE/fm_partition.tcl" \
    > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC" | tee "$EV/rc.txt"
grep -E "FM_RESULT|Passing|Failing|Unmatched|Not Compared|passing|failing|unmatched" "$EV/fm.log" | tail -20
exit $RC
