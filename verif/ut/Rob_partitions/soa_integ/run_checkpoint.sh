#!/usr/bin/env bash
# ★2-GROUP CHECKPOINT (codex 0104)★ — pCommit cone-DCE partition FM against the
# CURRENT (committed) SoA impl. Baseline (packed impl, unpinned): match candidate
# total 60714, 13% matched at 54 min, killed. Measure:
#   - total match/compare points (vs 60714)
#   - field-map pins applied/failed (0 FM-036 / FM-013)
#   - model-building time, 30-min matched%
# Usage: run_checkpoint.sh <label>   (FM launched in foreground of this script;
#        caller backgrounds the script. TIMEOUT_S bounds the whole fm_shell.)
set -u
LABEL="${1:-g1g2}"
TIMEOUT_S="${TIMEOUT_S:-7200}"
EV=/tmp/rob-soa-integ2-evidence/checkpoint_${LABEL}
GEN=/tmp/rob-conedce-evidence/gen
G=/home/eda/xs-env/G0-canonical/golden-rtl
RTL=/tmp/rob-soa-integ2/rtl/backend
TCL=/tmp/rob-soa-integ2-evidence/fm_conedce_partition_pinned.tcl
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"

# same golden leaf deps as agent/rob-conedce run_conedce_partition.sh (locked)
DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
$G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
$G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
$G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv"

export FM_REF_SRCS="$GEN/Rob_golden_commit.sv $DEPS"
# impl = CURRENT SoA core (committed worktree) + conedce-trimmed wrapper (u_core .*)
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $GEN/Rob_impl_commit.sv $DEPS"
export FM_TOP="Rob"

# regen field-map: kept-fields-only (12 of 15 SoA fields survive the commit cone;
# mmio/isHls/instrSize are physically deleted from the reduced golden -> no pin)
python3 /tmp/rob-soa-integ2/scripts/gen_rob_soa_fieldmap.py \
  --golden "$GEN/Rob_golden_commit.sv" --out "$EV/pins" \
  --only-fields valid,uopNum,stdWritebacked,needFlush,interrupt_safe,isRVC,isVset,realDestSize,commitType,ftqIdx_flag,ftqIdx_value,ftqOffset \
  > "$EV/fieldmap_gen.log" 2>&1
RCFM=$?
echo "fieldmap_gen rc=$RCFM" ; cat "$EV/fieldmap_gen.log"
[ $RCFM -eq 0 ] || { echo "CHECKPOINT_ABORT fieldmap gen failed"; exit 3; }
export FM_PINS="$EV/pins/rob_soa_entry_pins.tcl"

echo "=== checkpoint FM launch $(date) TIMEOUT_S=$TIMEOUT_S ==="
/usr/bin/time -v timeout "$TIMEOUT_S" fm_shell -64 -work_path "$EV/fm_work" -file "$TCL" \
    > "$EV/fm.log" 2> "$EV/time.log"
RC=$?
echo "rc=$RC" | tee "$EV/rc.txt"
echo "=== pins ==="
grep -E "ROB_SOA_ENTRY_PINS|SOA_FAMILY_DFF_MATCH|SOA_PIN_ASSERT_FAIL|ROB_SOA_PIN_FAIL|FM-036|FM-013" "$EV/fm.log" | head -20
echo "=== matching progress ==="
grep -E "Matched\)" "$EV/fm.log" | head -3
grep -E "Matched\)" "$EV/fm.log" | tail -3
echo "=== result tail ==="
grep -viE '^\s*#' "$EV/fm.log" | grep -iE "SUCCEEDED|FAILED|Passing \(|Failing \(|Unmatched|equivalent|abort|no compare|Status:  (Matching|Building|Verifying)" | tail -20
exit $RC
