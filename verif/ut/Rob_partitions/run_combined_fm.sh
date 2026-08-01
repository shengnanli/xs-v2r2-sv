#!/usr/bin/env bash
# Rob COMBINED canary (codex 0096 §2): field-map pins + proven-child blackbox.
# Runs ONE Rob partition FM proof with:
#   (a) complete 9440-bit rob_entries field-map pins (gen_rob_fieldmap.py), AND
#   (b) SyncDataModuleTemplate__64entry_3 + DelayReg BLACK-BOXED (symmetric,
#       both FM sides — golden truly instantiates them, depends_on already
#       SIGNOFF_PASS: SyncDataModule delta 792/0 RC0, DelayReg delta 444/0 RC0).
#       RenameBuffer stays WHITE-BOX (RenameBuffer-fix owner still補 AUX).
#
# The two levers together break BOTH Rob convergence walls:
#   - field-map  -> breaks the packed rob_entries[160] signature-match wall.
#   - child-bbox -> breaks the child register-merge wall (SyncDataModule 236
#                   regs + DelayReg 62 regs no longer participate in
#                   verification_merge_duplicated_registers).
#
# Usage: run_combined_fm.sh <Fam> [MAP=1] [BBOX=1]
#   Fam in {pCommit pException pPerfTraceCsrDbg pVecExcp pLsqDeep}
#   MAP=0  -> no field-map pins (baseline for measurement)
#   BBOX=0 -> children white-box (baseline for measurement)
# Env: EVROOT (default /tmp/rob-combined-evidence)
set -u
FAM="$1"
MAP="${2:-1}"
BBOX="${3:-1}"
TOP="Rob_${FAM}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
G="/home/eda/xs-env/G0-canonical/golden-rtl"
RTL="$ROOT/rtl/backend"
TAG="${TOP}_MAP${MAP}_BBOX${BBOX}"
EV="${EVROOT:-/tmp/rob-combined-evidence}/$TAG"
rm -rf "$EV"; mkdir -p "$EV"

# 1) field-map + entry pins for THIS partition top (always generated for audit).
python3 "$ROOT/scripts/gen_rob_fieldmap.py" --top "$TOP" --golden "$G/Rob.sv" \
    --out "$EV/fieldmap" > "$EV/fieldmap_gen.log" 2>&1
GRC=$?
echo "fieldmap gen rc=$GRC"; tail -4 "$EV/fieldmap_gen.log"
[ "$GRC" -ne 0 ] && { echo "FIELD-MAP BIJECTION FAILED — abort"; exit 2; }

# 2) golden leaf deps. Two sets:
#    ALWAYS white-box (both sides elaborate): RenameBuffer, VTypeBuffer,
#    SnapshotGenerator*, ExceptionGen, *PtrWrapper, DummyDPICWrapper*, dt_160x1,
#    DataModule__16entry_12.
#    CHILD-BBOX candidates (dropped from srcs when BBOX=1 -> symmetric unresolved
#    black box via hdlin_unresolved_modules=black_box): SyncDataModule + DelayReg.
DEPS_COMMON="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
  $G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DummyDPICWrapper.sv \
  $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
  $G/SnapshotGenerator_2.sv $G/DataModule__16entry_12.sv $RTL/Rob_difftest_stubs.sv"
DEPS_CHILD="$G/SyncDataModuleTemplate__64entry_3.sv $G/DelayReg.sv"

if [ "$BBOX" = "1" ]; then
  DEPS="$DEPS_COMMON"           # children dropped -> black-boxed both sides
  echo "CHILD-BBOX: SyncDataModuleTemplate__64entry_3 + DelayReg BLACK-BOXED (symmetric)"
else
  DEPS="$DEPS_COMMON $DEPS_CHILD"  # children white-box
  echo "CHILD-BBOX: OFF (children white-box)"
fi

PART="$RTL/${TOP}_part.sv"
export FM_REF_SRCS="$PART $G/Rob.sv $DEPS"
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $RTL/Rob_wrapper.sv $PART $DEPS"
export FM_TOP="$TOP"
if [ "$MAP" = "1" ]; then
  export FM_ENTRY_PINS="$EV/fieldmap/rob_entry_pins.tcl"
else
  unset FM_ENTRY_PINS 2>/dev/null || true
fi

cd "$EV"
echo "=== FM COMBINED $TAG (MAP=$MAP BBOX=$BBOX) ==="
echo "start $(date -u +%H:%M:%S)"
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" \
    -file "$HERE/fm_partition.tcl" > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC end $(date -u +%H:%M:%S)" | tee "$EV/rc.txt"
grep -E "FM_RESULT|ROB_ENTRY_PINS|ROB_PIN_FAIL|AUTO_MATCH|Passing|Failing|Unmatched|passing|failing|unmatched|black|Black" "$EV/fm.log" | tail -40
exit $RC
