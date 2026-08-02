#!/usr/bin/env bash
# codex 0101 阶段1 SoA-canary: 家族隔离 A/B FM 对照 (packed vs SoA)。
# 同一 pCommit partition, 两侧只对 commit-state family(valid/uopNum/stdWritebacked)
# 施加 pin(其余字段两次都不 pin, 完全同等), 隔离测家族 FM match 成本:
#   MODE=packed : impl=packed 核 + 1440 family bit-pins (rob_entries_reg[N][slice])
#   MODE=soa    : impl=SoA 核    + 480 family reg-pins  (rob_valid/uop_num/std_wb _reg[N])
# 记录: pin-apply 数/fail、match 墙钟、family compare-point matched/unmatched。
# Usage: run_soa_canary.sh <packed|soa> [FAM]   (FAM 默认 pCommit)
set -u
MODE="$1"; FAM="${2:-pCommit}"
TOP="Rob_${FAM}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
G="/home/eda/xs-env/G0-canonical/golden-rtl"
RTL="$ROOT/rtl/backend"
EV="${EVROOT:-/tmp/rob-soa-canary-evidence}/canary_${MODE}_${TOP}"
rm -rf "$EV"; mkdir -p "$EV"

DEPS="$G/VTypeBuffer.sv $G/DummyDPICWrapper.sv $G/DummyDPICWrapper_8.sv $G/dt_160x1.sv \
  $G/SnapshotGenerator_1.sv $G/SnapshotGenerator_2.sv $G/DataModule__16entry_12.sv \
  $RTL/Rob_difftest_stubs.sv"
PART="$RTL/${TOP}_part.sv"

export FM_REF_SRCS="$PART $G/Rob.sv $DEPS"
# NOTE: Rob_packed_ref.sv 不进 impl srcs(仅 co-sim 用); impl 用 SoA 版 Rob.sv。
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $RTL/Rob_wrapper.sv $PART $DEPS"
export FM_TOP="$TOP"

BRTL="${BASELINE_RTL:-/tmp/rob-soa-canary-evidence/baseline_rtl}"
if [ "$MODE" = "packed" ]; then
  # baseline: pristine PACKED core (commit 2d486d4) from $BRTL; family-only bit-pins.
  python3 "$ROOT/scripts/gen_rob_fieldmap.py" --top "$TOP" --golden "$G/Rob.sv" \
      --out "$EV/fieldmap" > "$EV/fieldmap_gen.log" 2>&1 || { echo FIELDMAP_FAIL; exit 2; }
  # carve family-only subset (valid/uopNum/stdWritebacked) from full pins:
  awk '/^proc _rob_pin/,/^}/' "$EV/fieldmap/rob_entry_pins.tcl" > "$EV/family_pins.tcl"
  { echo 'set _rob_pin_n 0'; echo 'set _rob_pin_fail 0'; } | cat - "$EV/family_pins.tcl" > "$EV/family_pins.tmp" && mv "$EV/family_pins.tmp" "$EV/family_pins.tcl"
  grep -E '_rob_pin r:.*_(valid|uopNum\\\[[0-9]+\\\]|stdWritebacked) ' \
    "$EV/fieldmap/rob_entry_pins.tcl" >> "$EV/family_pins.tcl"
  echo 'puts "ROB_ENTRY_PINS: applied=$_rob_pin_n fail=$_rob_pin_fail"' >> "$EV/family_pins.tcl"
  # impl = pristine PACKED core + wrapper (base commit):
  export FM_IMPL_SRCS="$BRTL/rob_pkg.sv $BRTL/Rob.sv $BRTL/rob_lsq_deep_outputs.sv $BRTL/Rob_wrapper.sv $PART $DEPS"
  export FM_ENTRY_PINS="$EV/family_pins.tcl"
  DRIVER="$HERE/fm_partition.tcl"
else
  # SoA: family reg-pins only (partition hier: Rob_pCommit/u_rob/u_core)
  python3 "$ROOT/scripts/gen_rob_soa_fieldmap.py" --top "$TOP" --golden "$G/Rob.sv" \
      --impl-prefix "u_rob/u_core" --gold-prefix "u_rob/" \
      --out "$EV/soa_fieldmap" > "$EV/soa_fieldmap_gen.log" 2>&1 || { echo SOA_FIELDMAP_FAIL; exit 2; }
  export FM_SOA_ENTRY_PINS="$EV/soa_fieldmap/rob_soa_entry_pins.tcl"
  # FM_SOA_DFF_MATCH=1 → 用 DFF-cell↔DFF-cell 名映射(避 FM-036/FM-013); 默认走 raw pins。
  export FM_SOA_DFF_MATCH="${FM_SOA_DFF_MATCH:-0}"
  DRIVER="$HERE/fm_partition_soa.tcl"
fi

cd "$EV"
echo "=== SoA-canary MODE=$MODE $TOP ===" | tee phase_timing.log
echo "start $(date -u +%H:%M:%S) epoch=$(date +%s)" | tee -a phase_timing.log
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" \
    -file "$DRIVER" > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC end $(date -u +%H:%M:%S) epoch=$(date +%s)" | tee -a phase_timing.log | tee "$EV/rc.txt"
grep -E "FM_RESULT|SOA_PHASE|ROB_ENTRY_PINS|ROB_SOA_ENTRY_PINS|ROB_PIN_FAIL|ROB_SOA_PIN_FAIL|AUTO_MATCH|Passing|Failing|Unmatched|passing|failing|unmatched|Compare points|compare points" "$EV/fm.log" | tail -40
exit $RC
