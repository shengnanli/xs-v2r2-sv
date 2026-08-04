#!/usr/bin/env bash
# run_pcommit_checkpoint.sh — COMMITTED pCommit family-pinned FM checkpoint
# (codex 0108 前置1: absorbs the diag-evidence hand-carried harness; no
# evidence-dir inputs remain — every FM input is either committed here or the
# hash-gated canonical golden).
#
# Reproduces /tmp/rob-soa-diag-evidence/checkpoint_g1g2_fix (SUCCEEDED 13609/0)
# from clean committed sources:
#   ref  = gen/Rob_golden_commit.sv (gen_all.sh, hash-gated golden) + golden deps
#   impl = rtl/backend/{rob_pkg,Rob,rob_lsq_deep_outputs}.sv
#          + gen/Rob_impl_commit.sv (gen_all.sh over committed Rob_wrapper.sv)
#          + same golden deps
#   DPI  = verif/signoff/conedce/DiffExt_dpic_sink_stubs.sv (both sides)
#   pins = scripts/gen_rob_soa_fieldmap.py + round4 extra bijection pins below
# No dont_verify / no assumption / no new functional blackbox. Serial heavy FM.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
EV="${1:-/tmp/rob-g3g4-evidence/checkpoint_pcommit}"
G=/home/eda/xs-env/G0-canonical/golden-rtl
RTL="$ROOT/rtl/backend"
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"

# derivatives from the committed generator (drift-gated against rtl/backend)
GEN="$EV/gen"
bash "$HERE/gen_all.sh" "$GEN" > "$EV/gen_all.log" 2>&1 || { echo "rc=4" > "$EV/rc.txt"; exit 4; }

DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
$G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
$G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
$G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv"
export FM_REF_SRCS="$GEN/Rob_golden_commit.sv $DEPS"
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $GEN/Rob_impl_commit.sv $DEPS"
export FM_TOP="Rob"
export FM_DPI_STUBS="$ROOT/verif/signoff/conedce/DiffExt_dpic_sink_stubs.sv"

python3 "$ROOT/scripts/gen_rob_soa_fieldmap.py" \
  --golden "$GEN/Rob_golden_commit.sv" --out "$EV/pins" \
  --only-fields valid,uopNum,stdWritebacked,needFlush,interrupt_safe,isRVC,isVset,realDestSize,commitType,ftqIdx_flag,ftqIdx_value,ftqOffset,vls,traceBlockInPipe_iretire,traceBlockInPipe_ilastsize \
  > "$EV/fieldmap_gen.log" 2>&1 || { echo "rc=3" > "$EV/rc.txt"; exit 3; }
# ★codex 0108 步3 (G3 SoA)★ vls 从 nf-struct 迁到 SoA array: golden
#  robEntries_N_vls_reg <-> impl u_core/rob_vls_reg[N](整寄存器名配对)。其余 6
#  个 G3 字段(vxsat/dirtyVs/wflags/fflags/rfWen/fpWen)在 pCommit 锥外
#  (cone-DCE, reduced golden 0 refs), 由 perf 分区覆盖, pCommit 不 pin。
# ★codex 0108 步4 (G4 SoA + nf 删)★ 原 round4 的 entry trace iretire/ilastsize
#  pin 指向已删的 rob_entries_nf_reg[n][iretire]/[ilastsize] —— G4 后 iretire/
#  ilastsize 成 SoA array (rob_trace_iretire_reg[n] / rob_trace_ilastsize_reg[n]),
#  且二者在 pCommit 锥内存活(trace-pc -> commit 输出), 故直接移入 --only-fields
#  (whole-reg 名配对 golden robEntries_N_traceBlockInPipe_{iretire,ilastsize}_reg),
#  删去旧 nf per-bit pins。itype 不在 commit 锥(reduced golden 无该 reg)不 pin。
# ★codex 0107 round4 残留 extra pins★ deq-group isVset/ilastsize(robDeqGroup 独立
#  流水寄存器, 非 entry SoA, 未受 G4 影响)+ deqHitRedirect 打拍链(纯 set_user_match)。
cat >> "$EV/pins/rob_soa_entry_pins.tcl" <<'EOT'
set _extra_pin_start $_rob_soa_pin_fail
foreach b {0 1 2 3 4 5 6 7} {
  _rob_soa_pin r:/WORK/Rob/robDeqGroup_${b}_isVset_reg i:/WORK/Rob/u_core/robDeqGroup_reg\[$b\]\[is_vset\]
  _rob_soa_pin r:/WORK/Rob/robDeqGroup_${b}_traceBlockInPipe_ilastsize_reg i:/WORK/Rob/u_core/robDeqGroup_reg\[$b\]\[ilastsize\]\[0\]
}
_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_reg i:/WORK/Rob/u_core/deqHitRedirect_d1_reg
_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_1_reg i:/WORK/Rob/u_core/deqHitRedirect_d1b_reg
_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_2_reg i:/WORK/Rob/u_core/deqHitRedirect_d2_reg
puts "EXTRA_PINS_ROUND4 applied_total=$_rob_soa_pin_n fail_total=$_rob_soa_pin_fail (new_fail=[expr {$_rob_soa_pin_fail - $_extra_pin_start}])"
if {$_rob_soa_pin_fail != 0} { puts "EXTRA_PIN_ASSERT_FAIL"; exit 7 }
EOT
export FM_PINS="$EV/pins/rob_soa_entry_pins.tcl"
echo "=== pCommit checkpoint FM launch $(date) ==="
timeout 43200 fm_shell -64 -work_path "$EV/fm_work" -file "$HERE/fm_conedce_partition_pinned.tcl" > "$EV/fm.log" 2> "$EV/time.log"
RC=$?
echo "rc=$RC" > "$EV/rc.txt"
grep -aE 'Verification (SUCCEEDED|FAILED)|FM_DIAG_VERIFY_RET|Passing .compare points|Failing .compare points|Unverified' "$EV/fm.log" | tail -8
exit $RC
