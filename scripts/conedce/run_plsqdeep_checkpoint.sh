#!/usr/bin/env bash
# run_plsqdeep_checkpoint.sh — COMMITTED pLsqDeep (lsq) partition FM checkpoint
# (codex 0108 步6). Same committed-input discipline as run_pcommit_checkpoint.sh:
# every FM input is committed here or hash-gated canonical golden.
#
#   ref  = gen/Rob_golden_lsq.sv (gen_all.sh, hash-gated golden) + golden deps
#   impl = rtl/backend/{rob_pkg,Rob,rob_lsq_deep_outputs}.sv
#          + gen/Rob_impl_lsq.sv (gen_all.sh over committed Rob_wrapper.sv)
#          + same golden deps
#   DPI  = verif/signoff/conedce/DiffExt_dpic_sink_stubs.sv (both sides)
#   pins = scripts/gen_rob_soa_fieldmap.py (lsq-surviving entry fields) +
#          lsq→mmio register bijection + robDeqGroup/deqHitRedirect extra pins.
# No dont_verify / no assumption / no new functional blackbox. Serial heavy FM.
#
# The lsq partition covers the 2064 pLsqDeep outputs. It is the target of the
# codex-0109 LSQ→MMIO set patch: golden REG_3/4/5 + r{,_1,_2}_value drive
# robEntries_N_mmio; impl mirrors them as lsq_mmio_q / lsq_mmio_robidx_q.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
EV="${1:-/tmp/rob-g3g4-evidence/checkpoint_plsqdeep}"
G=/home/eda/xs-env/G0-canonical/golden-rtl
RTL="$ROOT/rtl/backend"
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"

GEN="$EV/gen"
bash "$HERE/gen_all.sh" "$GEN" > "$EV/gen_all.log" 2>&1 || { echo "rc=4" > "$EV/rc.txt"; exit 4; }

DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
$G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
$G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
$G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv"
export FM_REF_SRCS="$GEN/Rob_golden_lsq.sv $DEPS"
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $GEN/Rob_impl_lsq.sv $DEPS"
export FM_TOP="Rob"
export FM_DPI_STUBS="$ROOT/verif/signoff/conedce/DiffExt_dpic_sink_stubs.sv"

# lsq-surviving entry fields (from Rob_golden_lsq.sv reg decls; robEntries_N_<f>)
python3 "$ROOT/scripts/gen_rob_soa_fieldmap.py" \
  --golden "$GEN/Rob_golden_lsq.sv" --out "$EV/pins" \
  --only-fields valid,uopNum,stdWritebacked,needFlush,interrupt_safe,mmio,isVset,realDestSize,commitType,vls \
  > "$EV/fieldmap_gen.log" 2>&1 || { echo "rc=3" > "$EV/rc.txt"; exit 3; }

# ★codex 0108 步6★ extra pins: lsq→mmio 6 registers (golden REG_3/4/5 +
#  r{,_1,_2}_value <-> impl lsq_mmio_q[k] / lsq_mmio_robidx_q[k]) + robDeqGroup
#  isVset/mmio (packed struct member) + deqHitRedirect 打拍链.  All pure
#  set_user_match, fail-closed.
cat >> "$EV/pins/rob_soa_entry_pins.tcl" <<'EOT'
set _extra_pin_start $_rob_soa_pin_fail
# lsq->mmio pulse registers (1-bit REG_3/4/5)
_rob_soa_pin r:/WORK/Rob/REG_3_reg i:/WORK/Rob/u_core/lsq_mmio_q_reg\[0\]
_rob_soa_pin r:/WORK/Rob/REG_4_reg i:/WORK/Rob/u_core/lsq_mmio_q_reg\[1\]
_rob_soa_pin r:/WORK/Rob/REG_5_reg i:/WORK/Rob/u_core/lsq_mmio_q_reg\[2\]
# lsq->mmio latched robIdx (8-bit r_value / r_1_value / r_2_value), per-bit
for {set b 0} {$b < 8} {incr b} {
  _rob_soa_pin r:/WORK/Rob/r_value_reg\[$b\]   i:/WORK/Rob/u_core/lsq_mmio_robidx_q_reg\[0\]\[$b\]
  _rob_soa_pin r:/WORK/Rob/r_1_value_reg\[$b\] i:/WORK/Rob/u_core/lsq_mmio_robidx_q_reg\[1\]\[$b\]
  _rob_soa_pin r:/WORK/Rob/r_2_value_reg\[$b\] i:/WORK/Rob/u_core/lsq_mmio_robidx_q_reg\[2\]\[$b\]
}
# robDeqGroup packed-struct members (isVset / mmio), 8 slots
foreach b {0 1 2 3 4 5 6 7} {
  _rob_soa_pin r:/WORK/Rob/robDeqGroup_${b}_isVset_reg i:/WORK/Rob/u_core/robDeqGroup_reg\[$b\]\[is_vset\]
  _rob_soa_pin r:/WORK/Rob/robDeqGroup_${b}_mmio_reg   i:/WORK/Rob/u_core/robDeqGroup_reg\[$b\]\[mmio\]
}
# deqHitRedirect pipe chain
_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_reg i:/WORK/Rob/u_core/deqHitRedirect_d1_reg
_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_1_reg i:/WORK/Rob/u_core/deqHitRedirect_d1b_reg
_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_2_reg i:/WORK/Rob/u_core/deqHitRedirect_d2_reg
puts "EXTRA_PINS_PLSQDEEP applied_total=$_rob_soa_pin_n fail_total=$_rob_soa_pin_fail (new_fail=[expr {$_rob_soa_pin_fail - $_extra_pin_start}])"
if {$_rob_soa_pin_fail != 0} { puts "EXTRA_PIN_ASSERT_FAIL"; exit 7 }
EOT
export FM_PINS="$EV/pins/rob_soa_entry_pins.tcl"
echo "=== pLsqDeep checkpoint FM launch $(date) ==="
timeout 43200 fm_shell -64 -work_path "$EV/fm_work" -file "$HERE/fm_conedce_partition_pinned.tcl" > "$EV/fm.log" 2> "$EV/time.log"
RC=$?
echo "rc=$RC" > "$EV/rc.txt"
grep -aE 'Verification (SUCCEEDED|FAILED)|FM_DIAG_VERIFY_RET|Passing .compare points|Failing .compare points|Unverified|EXTRA_PINS_PLSQDEEP' "$EV/fm.log" | tail -8
exit $RC
