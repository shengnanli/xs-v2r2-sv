#!/usr/bin/env bash
# codex 0099 pCommit/pLsqDeep canary: ONE Rob partition FM proof with
#   (a) field-map set_user_match pins for packed rob_entries[160]
#   (b) 7-child symmetric blackbox (RenameBuffer/SnapshotGenerator_3/ExceptionGen/
#       NewRobDeqPtrWrapper/RobEnqPtrWrapper/DelayReg/SyncDataModuleTemplate__64entry_3
#       REMOVED from both-side srcs => hdlin_unresolved_modules=black_box)
#   (c) filtered fm_eq (FMR-147/118/091/063 benign message filters)
# VTypeBuffer stays white-box (keep SnapshotGenerator_1/_2 it instantiates);
# DummyDPICWrapper/_8 white-box with 9 DPI dpic sinks blackboxed.
# Usage: run_canary_7child.sh <Fam>   Fam in {pCommit pLsqDeep pException pPerfTraceCsrDbg pVecExcp}
# Env: EVROOT (default /tmp/rob-integ-v2-evidence/canary)
set -u
FAM="$1"
TOP="Rob_${FAM}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
G="/home/eda/xs-env/G0-canonical/golden-rtl"
RTL="$ROOT/rtl/backend"
EV="${EVROOT:-/tmp/rob-integ-v2-evidence/canary}/$TOP"
rm -rf "$EV"; mkdir -p "$EV"

# 1) generate field-map + entry pins for THIS partition top (partition-top prefixes
#    u_rob/u_core: partition wrapper instantiates Rob as u_rob; core is u_core).
python3 "$ROOT/scripts/gen_rob_fieldmap.py" --top "$TOP" --golden "$G/Rob.sv" \
    --out "$EV/fieldmap" > "$EV/fieldmap_gen.log" 2>&1
GRC=$?
echo "fieldmap gen rc=$GRC"; tail -4 "$EV/fieldmap_gen.log"
[ "$GRC" -ne 0 ] && { echo "FIELD-MAP BIJECTION FAILED — abort"; exit 2; }

# golden leaf deps kept WHITE-BOX (both sides elaborate). 7 children NOT here
# (=> symmetric unresolved blackbox). VTypeBuffer white-box keeps SnapshotGenerator_1/_2.
DEPS="$G/VTypeBuffer.sv $G/DummyDPICWrapper.sv $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv \
  $G/SnapshotGenerator_1.sv $G/SnapshotGenerator_2.sv $G/DataModule__16entry_12.sv \
  $RTL/Rob_difftest_stubs.sv"
PART="$RTL/${TOP}_part.sv"

export FM_REF_SRCS="$PART $G/Rob.sv $DEPS"
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $RTL/Rob_wrapper.sv $PART $DEPS"
export FM_TOP="$TOP"
export FM_ENTRY_PINS="$EV/fieldmap/rob_entry_pins.tcl"

cd "$EV"
echo "=== FM 7-child-blackbox field-map canary $TOP ===" | tee phase_timing.log
echo "start $(date -u +%H:%M:%S) epoch=$(date +%s)" | tee -a phase_timing.log
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" \
    -file "$HERE/fm_partition.tcl" > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC end $(date -u +%H:%M:%S) epoch=$(date +%s)" | tee -a phase_timing.log | tee "$EV/rc.txt"
grep -E "FM_RESULT|PACKED_MATCH|ROB_ENTRY_PINS|ROB_PIN_FAIL|AUTO_MATCH|Passing|Failing|Unmatched|passing|failing|unmatched" "$EV/fm.log" | tail -30
exit $RC
