#!/usr/bin/env bash
# Run ONE Rob partition FM proof WITH the packed rob_entries field-map pins
# (codex 0095 field-map-first). Usage:
#   run_fieldmap_fm.sh <Fam>   Fam in {pCommit pException pPerfTraceCsrDbg pVecExcp pLsqDeep}
# Env: EVROOT (evidence root, default /tmp/rob-fieldmap-evidence)
set -u
FAM="$1"
TOP="Rob_${FAM}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
G="/home/eda/xs-env/G0-canonical/golden-rtl"
RTL="$ROOT/rtl/backend"
EV="${EVROOT:-/tmp/rob-fieldmap-evidence}/$TOP"
rm -rf "$EV"; mkdir -p "$EV"

# 1) generate the field-map + entry pins for THIS partition top.
python3 "$ROOT/scripts/gen_rob_fieldmap.py" --top "$TOP" --golden "$G/Rob.sv" \
    --out "$EV/fieldmap" > "$EV/fieldmap_gen.log" 2>&1
GRC=$?
echo "fieldmap gen rc=$GRC"; tail -6 "$EV/fieldmap_gen.log"
[ "$GRC" -ne 0 ] && { echo "FIELD-MAP BIJECTION FAILED — abort"; exit 2; }

# golden leaf deps (both sides elaborate — white box)
DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
  $G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
  $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
  $G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv \
  $RTL/Rob_difftest_stubs.sv"
PART="$RTL/${TOP}_part.sv"

export FM_REF_SRCS="$PART $G/Rob.sv $DEPS"
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $RTL/Rob_wrapper.sv $PART $DEPS"
export FM_TOP="$TOP"
export FM_ENTRY_PINS="$EV/fieldmap/rob_entry_pins.tcl"

cd "$EV"
echo "=== FM field-map partition $TOP (pins=$FM_ENTRY_PINS) ==="
echo "start $(date -u +%H:%M:%S)"
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" \
    -file "$HERE/fm_partition.tcl" > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC end $(date -u +%H:%M:%S)" | tee "$EV/rc.txt"
grep -E "FM_RESULT|PACKED_MATCH|ROB_ENTRY_PINS|ROB_PIN_FAIL|AUTO_MATCH|Passing|Failing|Unmatched|passing|failing|unmatched" "$EV/fm.log" | tail -30
exit $RC
