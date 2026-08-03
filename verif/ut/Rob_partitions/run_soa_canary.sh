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
# ★codex 0103 修2★ 禁 missing-reference auto-blackbox(旧 canary 未给 7 child 的
#  module 定义 → hdlin_unresolved_modules=black_box 让 FM 自建 FM_BBOX 并推断端口
#  方向, 产 FM-064(7 auto-bbox)+FM-230(8575 unknown-direction pins))。改法: 把 7 个
#  golden child 的【真 module 定义】对称提供给 ref+impl 两侧 → 两侧同 elaborate 成白盒
#  (端口方向/宽度确定, unknown-dir BBPin=0, FM-064=0/FM-230=0), cone 内互相抵消(canary
#  只测 family match, 非 child 逻辑)。RenameBuffer 内含 SnapshotGenerator; SyncDataModule
#  内含 DataModule__16entry_12(已在 DEPS)。canary2 实测: FM-064=0 + FM-230=0(修2 gate 达成)。
#  ★白盒 vs 黑盒 SyncDataModule 的诚实权衡★: SyncDataModule(VTypeBuffer 内 64-entry 大
#  寄存器堆)白盒→修2 gate 达成(0 unknown-dir)但 verification_merge_duplicated_registers
#  在该块 merge 严重放缓(canary2 verify 尾部单块 grind >17min); 反之对称黑盒它→verify
#  快但 read_sverilog 阶段 ref 侧 blackbox 推断产 FM-230=218 unknown-dir(canary3 实测,
#  违修2 gate)。∵修2 gate 明确要 unknown-dir BBPin=0, 故取【白盒】(修2 gate 达成为准);
#  SyncDataModule merge 放缓是 verify-time 性能问题(非修2 缺陷), 见 results doc。
CHILD_DEPS="$G/RenameBuffer.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_3.sv \
  $G/ExceptionGen.sv $G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv \
  $G/DelayReg.sv $G/SyncDataModuleTemplate__64entry_3.sv"
DEPS="$DEPS $CHILD_DEPS"
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
  # ★修1★ 全部 set_user_match 前置于首个 match(fm_partition_soa.tcl 已删除
  #  前置-match 的 FM_SOA_DFF_MATCH 路径), 只走 pre-match name-driven pins。
  # ★修2 refine★ SyncDataModule 声明 interface-only(0 unknown-dir + 免寄存器 merge)。
  export FM_INTERFACE_ONLY="${FM_INTERFACE_ONLY:-SyncDataModuleTemplate__64entry_3}"
  DRIVER="$HERE/fm_partition_soa.tcl"
fi

cd "$EV"
echo "=== SoA-canary MODE=$MODE $TOP ===" | tee phase_timing.log
echo "start $(date -u +%H:%M:%S) epoch=$(date +%s)" | tee -a phase_timing.log
/usr/bin/time -v fm_shell -64 -work_path "$EV/fm_work" \
    -file "$DRIVER" > "$EV/fm.log" 2>"$EV/time.log"
RC=$?
echo "rc=$RC end $(date -u +%H:%M:%S) epoch=$(date +%s)" | tee -a phase_timing.log | tee "$EV/rc.txt"
grep -E "FM_RESULT|SOA_PHASE|SOA_FAMILY_DFF_MATCH|SOA_PREMATCH_COMPLETE|SOA_PIN_ASSERT_FAIL|ROB_SOA_ENTRY_PINS|ROB_SOA_PIN_FAIL|AUTO_MATCH|Passing|Failing|Unmatched|passing|failing|unmatched|Compare points|compare points" "$EV/fm.log" | tail -40

# ================= codex 0103 三修 gate 汇总 (canary 前门禁) =================
echo "=== THREE-FIX GATE ($MODE $TOP) ===" | tee "$EV/gate.txt"
# 修1: pre-match paired 数 + 0 FM-036 (family)
PAIRED=$(grep -oE 'SOA_FAMILY_DFF_MATCH paired=[0-9]+ expected=[0-9]+ fm036=[0-9]+' "$EV/fm.log" | tail -1)
PREMATCH=$(grep -c 'SOA_PREMATCH_COMPLETE' "$EV/fm.log")
echo "FIX1 family pre-match: ${PAIRED:-MISSING}  prematch_before_match=$PREMATCH" | tee -a "$EV/gate.txt"
# 修2: auto-blackbox unknown-direction BBPin=0 (FM-064 / FM-230)
FM064=$(grep -cE 'FM-064' "$EV/fm.log")
FM230=$(grep -oE '[0-9]+ black-box pins of unknown direction' "$EV/fm.log" | grep -oE '^[0-9]+' | tail -1)
UNDRIVEN=$(grep -oE '[0-9]+ (nets?|pins?) (are|is)? *undriven' "$EV/fm.log" | tail -1)
echo "FIX2 auto-bbox: FM-064_count=$FM064  unknown_dir_BBPin=${FM230:-0}  undriven=${UNDRIVEN:-none}" | tee -a "$EV/gate.txt"
# 修3: FMR_VLOG-091=0 at impl set_top (grep whole log; both-side reads)
FMR091=$(grep -cE 'FMR_VLOG-091' "$EV/fm.log")
FMR118=$(grep -cE 'FMR_ELAB-118' "$EV/fm.log")
echo "FIX3 FMR: VLOG-091_count=$FMR091  ELAB-118_count=$FMR118" | tee -a "$EV/gate.txt"
exit $RC
