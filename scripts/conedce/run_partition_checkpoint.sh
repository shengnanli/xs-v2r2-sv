#!/usr/bin/env bash
# run_partition_checkpoint.sh — COMMITTED generic cone-DCE partition FM checkpoint
# (codex 0108 步6). Parameterized over fam in {exception perf vecexcp}. Same
# committed-input discipline + pinned tcl as run_pcommit_checkpoint.sh /
# run_plsqdeep_checkpoint.sh. commit/lsq have dedicated runners (extra pins).
#
# Usage: run_partition_checkpoint.sh <fam> [evidence_dir]
# The per-fam surviving entry fields (robEntries_N_<f> that remain in the
# cone-reduced golden) are passed as --only-fields; a superset of guarded extra
# set_user_match pins (lsq→mmio 6 regs + robDeqGroup packed-struct members that
# do not auto-match + deqHitRedirect chain) is appended, each fail-closed.
set -u
FAM="${1:?usage: run_partition_checkpoint.sh <exception|perf|vecexcp|robdeqgroup> [evdir]}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
EV="${2:-/tmp/rob-g3g4-evidence/checkpoint_${FAM}}"
G=/home/eda/xs-env/G0-canonical/golden-rtl
RTL="$ROOT/rtl/backend"
rm -rf "$EV"; mkdir -p "$EV"; cd "$EV"

# per-fam surviving robEntries_N_<f> fields (parsed from cone-reduced golden below)
case "$FAM" in
  exception) ONLY="valid,uopNum,stdWritebacked,needFlush,interrupt_safe,isVset,isHls,realDestSize,commitType,vls" ;;
  perf)      ONLY="valid,uopNum,stdWritebacked,needFlush,interrupt_safe,isVset,realDestSize,instrSize,commitType,ftqIdx_value,ftqOffset,vls,vxsat,dirtyVs,wflags,fflags,fpWen,traceBlockInPipe_itype,traceBlockInPipe_iretire,traceBlockInPipe_ilastsize" ;;
  vecexcp)   ONLY="valid,uopNum,stdWritebacked,needFlush,interrupt_safe,isVset,realDestSize,vls" ;;
  # ★pRobDeqGroup (codex 0117)★ dedicated partition whose retained outputs are
  #  io_commits_commitValid_0..7 / io_headNotReady / io_flushOut_* / io_robDeqPtr_*.
  #  These outputs read robDeqGroup_N_{commit_v,commit_w,needFlush} DIRECTLY via
  #  commitValidThisLine_N / commit_block_N / allowOnlyOneCommit (golden L21956-
  #  22044; impl Rob.sv L1119/1129/1144). So the head-of-queue commit state chain
  #  becomes a set of *read* compare points that FM VERIFIES (not skips) — this is
  #  the sole purpose of this fam. --only-fields = the robEntries_N_<f> storage
  #  regs that survive the cone (parsed above; feed robDeqGroup line-read merge).
  robdeqgroup) ONLY="valid,uopNum,stdWritebacked,needFlush,interrupt_safe,isRVC,isVset,realDestSize,ftqIdx_flag,ftqIdx_value,ftqOffset,vls" ;;
  *) echo "unsupported fam $FAM (commit/lsq have dedicated runners)"; echo "rc=5" > "$EV/rc.txt"; exit 5 ;;
esac

GEN="$EV/gen"
bash "$HERE/gen_all.sh" "$GEN" > "$EV/gen_all.log" 2>&1 || { echo "rc=4" > "$EV/rc.txt"; exit 4; }

DEPS="$G/RenameBuffer.sv $G/VTypeBuffer.sv $G/SnapshotGenerator_3.sv $G/ExceptionGen.sv \
$G/NewRobDeqPtrWrapper.sv $G/RobEnqPtrWrapper.sv $G/DelayReg.sv $G/DummyDPICWrapper.sv \
$G/DummyDPICWrapper_8.sv $G/dt_160x1.sv $G/SnapshotGenerator.sv $G/SnapshotGenerator_1.sv \
$G/SnapshotGenerator_2.sv $G/SyncDataModuleTemplate__64entry_3.sv $G/DataModule__16entry_12.sv"
export FM_REF_SRCS="$GEN/Rob_golden_${FAM}.sv $DEPS"
export FM_IMPL_SRCS="$RTL/rob_pkg.sv $RTL/Rob.sv $RTL/rob_lsq_deep_outputs.sv $GEN/Rob_impl_${FAM}.sv $DEPS"
export FM_TOP="Rob"
export FM_DPI_STUBS="$ROOT/verif/signoff/conedce/DiffExt_dpic_sink_stubs.sv"

python3 "$ROOT/scripts/gen_rob_soa_fieldmap.py" \
  --golden "$GEN/Rob_golden_${FAM}.sv" --out "$EV/pins" \
  --only-fields "$ONLY" \
  > "$EV/fieldmap_gen.log" 2>&1 || { echo "rc=3" > "$EV/rc.txt"; exit 3; }

# ★pRobDeqGroup (codex 0117)★ locked head-state bijection manifest + hash. Fails
#  closed (rc=6) if any robDeqGroup_N_{commit_v,commit_w,needFlush} reg is absent
#  from the reduced golden (would mean the cone did not retain the head-state
#  chain → the partition is not actually verifying it). The emitted-pin fragment
#  it writes must match the inline commit_v/commit_w pins in the extra-pins block.
if [ "$FAM" = robdeqgroup ]; then
  python3 "$HERE/gen_robdeqgroup_pins.py" \
    --reduced-golden "$GEN/Rob_golden_${FAM}.sv" --out "$EV/pins" \
    --emit "commit_v,commit_w" \
    > "$EV/robdeqgroup_pins_gen.log" 2>&1 || { echo "rc=6" > "$EV/rc.txt"; exit 6; }
fi

# extra pins (all fail-closed). Only-present golden reg targets are guarded with
# find_dc / regexp on the reduced golden so absent partitions skip cleanly.
REDG="$GEN/Rob_golden_${FAM}.sv"
have() { grep -qE "reg .*$1\b" "$REDG"; }
{
  echo 'set _extra_pin_start $_rob_soa_pin_fail'
  # lsq->mmio pulse + latched robidx (present in all partitions that read deq mmio)
  if have 'REG_3'; then
    echo '_rob_soa_pin r:/WORK/Rob/REG_3_reg i:/WORK/Rob/u_core/lsq_mmio_q_reg\[0\]'
    echo '_rob_soa_pin r:/WORK/Rob/REG_4_reg i:/WORK/Rob/u_core/lsq_mmio_q_reg\[1\]'
    echo '_rob_soa_pin r:/WORK/Rob/REG_5_reg i:/WORK/Rob/u_core/lsq_mmio_q_reg\[2\]'
    echo 'for {set b 0} {$b < 8} {incr b} {'
    echo '  _rob_soa_pin r:/WORK/Rob/r_value_reg\[$b\]   i:/WORK/Rob/u_core/lsq_mmio_robidx_q_reg\[0\]\[$b\]'
    echo '  _rob_soa_pin r:/WORK/Rob/r_1_value_reg\[$b\] i:/WORK/Rob/u_core/lsq_mmio_robidx_q_reg\[1\]\[$b\]'
    echo '  _rob_soa_pin r:/WORK/Rob/r_2_value_reg\[$b\] i:/WORK/Rob/u_core/lsq_mmio_robidx_q_reg\[2\]\[$b\]'
    echo '}'
  fi
  # robDeqGroup packed-struct members that do not auto-match.
  # ★perf5 (codex 0108 步5 收尾)★ In the perf partition the enlarged entry-storage
  #  field set (fflags/vxsat/dirtyVs/wflags/fpWen/trace…) changes robDeqGroup's
  #  driver-cone signature, so FM auto-match drops MANY packed-struct members
  #  (not just isVset/mmio/ilastsize). Left unmatched, each member becomes a free
  #  cone input → cascading failures (rab walkSize/commitSize, deqHasFlushed,
  #  hasCommitted, dirty_fs/dirty_vs, and — via deqHasFlushed → exceptionGen
  #  s0_out — the shared ExceptionGen submodule regs). All these members are the
  #  SAME golden DFF as impl (merge eq `allCommitted ? next : this` bit-exact),
  #  and they are ALL proven equivalent in the pException partition (they pass
  #  there). So we pin the COMPLETE robDeqGroup member set the impl struct shares
  #  with golden — pure set_user_match, NO dont_verify, fail-closed on any FM-036.
  #  (golden_suffix impl_member width) — only pinned when present in reduced golden
  echo 'foreach b {0 1 2 3 4 5 6 7} {'
  # 1-bit members
  for gm in "isVset:is_vset" "mmio:mmio" "needFlush:need_flush" "dirtyFs:dirty_fs" \
            "dirtyVs:dirty_vs" "isVls:is_vls" "isRVC:is_rvc" "isHls:is_hls" \
            "interrupt_safe:interrupt_safe" "rfWen:rf_wen" "wflags:wflags" \
            "ftqIdx_flag:ftq_idx_flag" "traceBlockInPipe_ilastsize:ilastsize"; do
    g="${gm%%:*}"; m="${gm##*:}"
    if [ "$g" = "traceBlockInPipe_ilastsize" ]; then
      have "robDeqGroup_0_${g}" && echo "  _rob_soa_pin r:/WORK/Rob/robDeqGroup_\${b}_${g}_reg i:/WORK/Rob/u_core/robDeqGroup_reg\\[\$b\\]\\[${m}\\]\\[0\\]"
    else
      have "robDeqGroup_0_${g}" && echo "  _rob_soa_pin r:/WORK/Rob/robDeqGroup_\${b}_${g}_reg i:/WORK/Rob/u_core/robDeqGroup_reg\\[\$b\\]\\[${m}\\]"
    fi
  done
  # multi-bit members (per-bit pins: golden reg[k] <-> impl member[k])
  for gm in "realDestSize:real_dest_size:7" "commitType:commit_type:3" \
            "instrSize:instr_size:3" "ftqIdx_value:ftq_idx_value:6" \
            "ftqOffset:ftq_offset:4" "traceBlockInPipe_iretire:iretire:4" \
            "traceBlockInPipe_itype:itype:4"; do
    g="${gm%%:*}"; rest="${gm#*:}"; m="${rest%%:*}"; w="${rest##*:}"
    if have "robDeqGroup_0_${g}"; then
      echo "  for {set k 0} {\$k < ${w}} {incr k} {"
      echo "    _rob_soa_pin r:/WORK/Rob/robDeqGroup_\${b}_${g}_reg\\[\$k\\] i:/WORK/Rob/u_core/robDeqGroup_reg\\[\$b\\]\\[${m}\\]\\[\$k\\]"
      echo "  }"
    fi
  done
  echo '}'
  # ★pRobDeqGroup (codex 0117) — the head-of-queue commit-state chain★
  #  robDeqGroup_N_commit_v / commit_w are the golden merge-output registers that
  #  DO NOT live in robEntries (they are robDeqGroup-only: golden reg
  #  robDeqGroup_N_commit_v/_commit_w, Rob.sv L11680-11681; next-state written in
  #  the allCommitted-branched always block L126255/126256). The impl stores them
  #  as members of the robDeqGroup unpacked-array struct
  #  (i:/WORK/Rob/u_core/robDeqGroup_reg[b][commit_v|commit_w], rtl/backend/Rob.sv
  #  L1570 `robDeqGroup[b] <= robDeqGroup_next[b]`). Because golden's FLAT name
  #  (robDeqGroup_N_commit_v) and impl's ARRAY-member name differ, FM's auto-match
  #  NEVER pairs them → they are not compare points anywhere (grep commit_w
  #  compare-point in pCommit = 0). In THIS fam the retained outputs
  #  (io_commits_commitValid_0..7 / io_headNotReady) READ robDeqGroup_N_commit_v/
  #  _w directly (commitValidThisLine_N = commit_v & commit_w & …, commit_block_N =
  #  ~commit_w & …), so pinning golden↔impl 1:1 makes commit_v/commit_w *read*
  #  compare points that FM VERIFIES (next-state equivalence), NOT matched-unread
  #  (verification_verify_matched_unread_compare_points=false only skips UNREAD
  #  matched regs; these are read). needFlush is already pinned by the shared
  #  foreach-b loop above (do NOT re-pin here → would double-match). Pure
  #  set_user_match, NO dont_verify, fail-closed on any FM-036 (the driver's
  #  EXTRA_PIN_ASSERT_FAIL exits 7 if any pin fails to resolve). ★This block is the
  #  entire reason pRobDeqGroup exists: independently DECIDE whether the impl
  #  8-bank line-read merge of commit_w/commit_v equals golden — it does NOT pin
  #  deqVlsCanCommit / exceptionGen / blockCommit / s0_out (those are the DOWNSTREAM
  #  measured targets; pinning them would mask the very failure under test).★
  if [ "$FAM" = robdeqgroup ]; then
    echo 'foreach b {0 1 2 3 4 5 6 7} {'
    for gm in "commit_v:commit_v" "commit_w:commit_w"; do
      g="${gm%%:*}"; m="${gm##*:}"
      have "robDeqGroup_0_${g}" && echo "  _rob_soa_pin r:/WORK/Rob/robDeqGroup_\${b}_${g}_reg i:/WORK/Rob/u_core/robDeqGroup_reg\\[\$b\\]\\[${m}\\]"
    done
    echo '}'
  fi
  # ★perf5★ standalone regs feeding perf-family + exceptionGen cones that share a
  #  golden↔impl name-diff (all proven equivalent in pException/pVecExcp). Pure
  #  set_user_match.
  #  exceptionValidReg (golden io_exception_valid_REG): trace block0 valid.
  have 'io_exception_valid_REG' && echo '_rob_soa_pin r:/WORK/Rob/io_exception_valid_REG_reg i:/WORK/Rob/u_core/exceptionValidReg_reg'
  # deqHitRedirect pipe chain (present in all)
  if have 'deqHitRedirectReg_REG'; then
    echo '_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_reg i:/WORK/Rob/u_core/deqHitRedirect_d1_reg'
    echo '_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_1_reg i:/WORK/Rob/u_core/deqHitRedirect_d1b_reg'
    echo '_rob_soa_pin r:/WORK/Rob/deqHitRedirectReg_REG_2_reg i:/WORK/Rob/u_core/deqHitRedirect_d2_reg'
  fi
  # ★codex 0117 分支2★ deqVlsCanCommit completion pin(第三级异步复位 reg):
  #  链 deqVlsCanCommit_REG(=deqIsVlsException & deqPtrEntry.commit_w)→REG_1→deqVlsCanCommit
  #  (& rab.commitEnd)。golden flat `deqVlsCanCommit` ↔ impl u_core 同名标量, FM 跨 u_core 边界
  #  漏配 → 成 io_flush/lastCycleFlush 的 free cone input → perf 20 个 exceptionGen s0_out 失配。
  #  其输入 robDeqGroup commit_w/commit_v/needFlush 已由 pRobDeqGroup 专用分区(commit e4e6991f,
  #  robdeqgroup_run1 SUCCEEDED, 24/24 head-state reg 实证等价)FM 证等价 → 此 completion pin 有
  #  形式背书, 非掩盖。★不钉 s0_out/exceptionGen/blockCommit(被测下游目标)★。纯 set_user_match, FM-036 fail-closed。
  have 'deqVlsCanCommit' && echo '_rob_soa_pin r:/WORK/Rob/deqVlsCanCommit_reg i:/WORK/Rob/u_core/deqVlsCanCommit_reg'
  # ★rob-perf-cone (codex 0113 选项A)★ debug_microOp fuType per-entry SoA family.
  #  golden emits a FLAT per-entry reg `debug_microOp_debugReg_<N>_fuType` [34:0]
  #  (no-reset always@(posedge clock) block, L84370). The impl core stores the same
  #  head-tracking debug fuType in a packed unpacked-array `debug_fuType[<N>]`
  #  [34:0] (also no-reset — perf6 already aligned the reset topology). Because the
  #  golden flat name (debug_microOp_debugReg_N_fuType) and the impl array name
  #  (debug_fuType[N]) differ, FM's auto-matcher leaves ALL 160×35 entry bits
  #  UNMATCHED → they become free cone inputs to io_debugRobHead_fuType
  #  (= _GEN_187[deqPtr.value], golden L15883; impl dbgFuTypeVec[deqHeadIdx]).
  #  FM proves bits [0:9]/[24:34] independently (constant/derivable in this config)
  #  but leaves bits [10:23] unprovable → the 14 io_debugRobHead_fuType[10..23]
  #  failing points. Pinning the COMPLETE entry array (golden flat reg ↔ impl
  #  array member, per-bit) restores the read-multiplexer fanin symmetry so all 35
  #  output bits are provable. Pure set_user_match bijection, NO dont_verify, NO
  #  ref constraint; fail-closed on any FM-036. Same golden DFF ↔ impl DFF (both
  #  are RegEnable(io_enq_req_<port>_bits_fuType, enq-hit) — proven bit-exact by
  #  co-sim seed 1/7/42 checks=199997 errors=0). Only pinned when present in the
  #  reduced golden (perf partition is the sole family that reads debugRobHead).
  if have 'debug_microOp_debugReg_0_fuType'; then
    echo 'for {set n 0} {$n < 160} {incr n} {'
    echo '  for {set k 0} {$k < 35} {incr k} {'
    echo '    _rob_soa_pin r:/WORK/Rob/debug_microOp_debugReg_${n}_fuType_reg\[$k\] i:/WORK/Rob/u_core/debug_fuType_reg\[$n\]\[$k\]'
    echo '  }'
    echo '}'
  fi
  # NOTE: entry trace iretire/ilastsize (perf) are already pinned via --only-fields
  #  (SOA_FAMILY whole-reg/per-bit) — do NOT re-pin here (would double-match).
  echo 'puts "EXTRA_PINS_'"$FAM"' applied_total=$_rob_soa_pin_n fail_total=$_rob_soa_pin_fail (new_fail=[expr {$_rob_soa_pin_fail - $_extra_pin_start}])"'
  echo 'if {$_rob_soa_pin_fail != 0} { puts "EXTRA_PIN_ASSERT_FAIL"; exit 7 }'
} >> "$EV/pins/rob_soa_entry_pins.tcl"
export FM_PINS="$EV/pins/rob_soa_entry_pins.tcl"
echo "=== $FAM checkpoint FM launch $(date) ==="
timeout 43200 fm_shell -64 -work_path "$EV/fm_work" -file "$HERE/fm_conedce_partition_pinned.tcl" > "$EV/fm.log" 2> "$EV/time.log"
RC=$?
echo "rc=$RC" > "$EV/rc.txt"
grep -aE 'Verification (SUCCEEDED|FAILED)|FM_DIAG_VERIFY_RET|Passing .compare points|Failing .compare points|Unverified|EXTRA_PINS_' "$EV/fm.log" | tail -8
exit $RC
