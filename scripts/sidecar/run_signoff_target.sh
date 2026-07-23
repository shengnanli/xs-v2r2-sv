#!/usr/bin/env bash
# provenance 级 manifest 驱动 signoff runner(PROVENANCE_INTEGRATION)。
# 每目标产自包含证据: 绑定 canonical baseline ID + 完整 manifest SHA + 该 target entry;
# 冻结实际入口(fm_eq.tcl / fm_eq_bb.tcl)、emitter、validator、pin/custom Tcl(经 detached
# clean worktree @ IMPL_COMMIT = 提交态字节, 无需另拷); 记录执行时刻 closure、输入 RTL digest、
# 工具 digest、实现 commit 与 clean 状态; 原子生成; timeout/缺 native/rc 不一致 fail-closed;
# signoff 只认 actual==required==SUCCEEDED(shadow 单独统计 SHADOW_CHECK)。
# assembly allowlist 必须运行前在 declarations 绑定(allow_ref 文件, hash 记入证据)。
# 用法: run_signoff_target.sh <manifest.json> <target> [timeout_sec]
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
SC="$SIGNOFF/scripts/sidecar"
MANIFEST=$1; TARGET=$2; TMO=${3:-1200}
# 证据根可 override(delta 轮次写独立目录, 不覆盖冻结基线 signoff-evidence/)
EROOT="${SIGNOFF_EVIDENCE_ROOT:-$SC/signoff-evidence}"

# --- manifest 条目(tab 分隔) ---
IFS=$'\t' read -r UTDIR MK MT ENTRY PMODE REQV ALLOWREF CFG VERIFY_MU <<<"$(python3 - "$MANIFEST" "$TARGET" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for e in m["entries"]:
    if e["target"]==sys.argv[2]:
        print("\t".join([e["ut_dir"],e["makefile"] or "-",e["make_target"],e["entry"],
            e["proof_mode"],e["required_verdict"],e.get("allow_ref","") or "-",e["config_status"],
            e.get("verify_matched_unread_compare_points", "false")])); break
else: print("NOTFOUND")
PY
)"
[ "$UTDIR" = "NOTFOUND" ] && { echo "MANIFEST_MISS $TARGET"; exit 2; }
[ "$VERIFY_MU" = "true" ] || [ "$VERIFY_MU" = "false" ] || {
  echo "MANIFEST_BAD verify_matched_unread_compare_points=$VERIFY_MU"; exit 2; }
case "$TARGET" in LoadQueueUncache|FastArbiter_46|FastArbiter_47|FastArbiter_27|FastArbiter_44|ICacheCtrlUnit|ICacheDataArray|IPrefetchPipe|DivUnit|FDivSqrt|InstrMMIOEntry|InstrUncache|TXDAT_4|FAlu|FCVT|IssueQueueStdMoud|MulUnit|TXREQ|TlbStorageWrapper|TlbStorageWrapper_1|IssueQueueStaMou|IssueQueueLdu|TXDAT|Scheduler_1|Scheduler|Scheduler_3|MSHR|TageBTable|Directory|SCTable|SCTable_1|SCTable_2|SCTable_3) ;;
  *) [ "$VERIFY_MU" != "true" ] || { echo "MANIFEST_BAD matched-unread strengthening 仅允许精确白名单"; exit 2; } ;;
esac
# manifest 的 makefile 若非默认 Makefile(如 Makefile.iq/.sched), make 须 -f 指定,
# 否则用默认 Makefile 的错误 RTL_SRCS(IssueQueue×6 impl top unknown 根因)。
MKF=$(basename "$MK")
MKARG=""; [ "$MKF" != "Makefile" ] && [ "$MKF" != "-" ] && MKARG="-f $MKF"
if [ "$CFG" = "UNCONFIGURED" ]; then echo "TARGET $TARGET: UNCONFIGURED —— 不运行不计"; exit 4; fi

BID=$(python3 -c "import json;print(json.load(open('$MANIFEST'))['canonical_baseline_id'])")
MANIFEST_SHA=$(sha256sum "$MANIFEST" | cut -d' ' -f1)
IMPL_COMMIT=$(git -C "$SIGNOFF" rev-parse HEAD)
MAIN_DIRTY=$(git -C "$SIGNOFF" status --porcelain --untracked-files=no | wc -l)
# Target-scoped proof semantics must come from committed policy, not a mutable
# command-line manifest or native self-report.  Bind both generated manifest and
# its source declaration bytes to IMPL_COMMIT, then cross-check the target value.
MANIFEST_ABS=$(realpath "$MANIFEST")
case "$MANIFEST_ABS" in
  "$SIGNOFF"/*) MANIFEST_REL=${MANIFEST_ABS#"$SIGNOFF"/} ;;
  *) echo "MANIFEST_NOT_IN_SIGNOFF_TREE $MANIFEST_ABS"; exit 2 ;;
esac
git -C "$SIGNOFF" cat-file -e "$IMPL_COMMIT:$MANIFEST_REL" 2>/dev/null || {
  echo "MANIFEST_NOT_COMMITTED $MANIFEST_REL"; exit 2; }
COMMITTED_MANIFEST_SHA=$(git -C "$SIGNOFF" show "$IMPL_COMMIT:$MANIFEST_REL" | sha256sum | cut -d' ' -f1)
[ "$MANIFEST_SHA" = "$COMMITTED_MANIFEST_SHA" ] || {
  echo "MANIFEST_WORKTREE_COMMIT_MISMATCH"; exit 2; }
DECL_REL=scripts/sidecar/manifest_declarations.tsv
DECL="$SIGNOFF/$DECL_REL"
git -C "$SIGNOFF" cat-file -e "$IMPL_COMMIT:$DECL_REL" 2>/dev/null || {
  echo "DECLARATIONS_NOT_COMMITTED"; exit 2; }
DECL_SHA=$(sha256sum "$DECL" | cut -d' ' -f1)
COMMITTED_DECL_SHA=$(git -C "$SIGNOFF" show "$IMPL_COMMIT:$DECL_REL" | sha256sum | cut -d' ' -f1)
[ "$DECL_SHA" = "$COMMITTED_DECL_SHA" ] || {
  echo "DECLARATIONS_WORKTREE_COMMIT_MISMATCH"; exit 2; }
DECL_VERIFY_MU=$(python3 - "$DECL" "$TARGET" <<'PY'
import sys
path, target = sys.argv[1:]
found = []
for line in open(path, encoding="utf-8"):
    line = line.rstrip("\n")
    if not line or line.startswith("#"):
        continue
    p = line.split("\t")
    if p[0] == target:
        found.append(p[4] if len(p) > 4 and p[4] else "false")
if len(found) > 1:
    raise SystemExit("duplicate declaration")
print(found[0] if found else "false")
PY
)
[ "$VERIFY_MU" = "$DECL_VERIFY_MU" ] || {
  echo "MANIFEST_DECLARATION_APPVAR_MISMATCH manifest=$VERIFY_MU declaration=$DECL_VERIFY_MU"; exit 2; }
ED="$EROOT/$TARGET"; STG="$ED.staging"
[ -e "$ED" ] && { echo "REFUSE: $ED 已存在(no-force)"; exit 2; }
rm -rf "$STG"; mkdir -p "$STG"
RID="SGN-$TARGET-$(date +%s)"

# --- assembly allowlist: 运行前绑定(hash 入证据); allow_ref 须已提交 ---
ALLOW_SHA="-"; ALLOW_JSON="$STG/allow.json"
echo '{"unresolved_blackbox":[],"interface_only":[],"empty_blackbox":[],"unmatched":[]}' > "$ALLOW_JSON"
if [ "$ALLOWREF" != "-" ] && [ -n "$ALLOWREF" ]; then
  if ! git -C "$SIGNOFF" cat-file -e "$IMPL_COMMIT:$ALLOWREF" 2>/dev/null; then
    echo "TARGET $TARGET: ALLOW_REF_NOT_COMMITTED $ALLOWREF"; rm -rf "$STG"; exit 2; fi
  git -C "$SIGNOFF" show "$IMPL_COMMIT:$ALLOWREF" > "$ALLOW_JSON"
  ALLOW_SHA=$(sha256sum "$ALLOW_JSON" | cut -d' ' -f1)
fi

# --- detached clean worktree @ IMPL_COMMIT(提交态字节即冻结入口) ---
WTROOT=$(mktemp -d); WT="$WTROOT/wt"
git -C "$SIGNOFF" worktree add --detach --quiet "$WT" "$IMPL_COMMIT" || { echo "worktree失败"; rm -rf "$STG" "$WTROOT"; exit 2; }
WT_HEAD_PRE=$(git -C "$WT" rev-parse HEAD)
WT_DIRTY_PRE=$(git -C "$WT" status --porcelain --untracked-files=no | wc -l)
D="$WT/verif/ut/$UTDIR"

finalize() {  # rc
  local rc=$1
  local hpo=$(git -C "$WT" rev-parse HEAD 2>/dev/null || echo GONE)
  local dpo=$(git -C "$WT" status --porcelain --untracked-files=no 2>/dev/null | wc -l)
  local unt=$(git -C "$WT" status --porcelain 2>/dev/null | grep -c '^??' || true)
  {
    echo -e "kind\tpath\tsha256"
    for f in "$SC/run_signoff_target.sh" "$SC/fm_closure_digest.py" "$SC/fm_sidecar_verdict.py" \
             "$SC/gen_305_manifest.py"; do
      echo -e "infra\t$f\t$(sha256sum "$f"|cut -d' ' -f1)"
    done
    echo -e "manifest_sha256\t$MANIFEST\t$MANIFEST_SHA"
    echo -e "canonical_baseline_id\t$BID\t-"
    echo -e "target_entry\t$ENTRY\t-"
    echo -e "make_target\t$MT\t-"
    echo -e "proof_mode\t$PMODE\t-"
    echo -e "required_verdict\t$REQV\t-"
    echo -e "allow_ref\t$ALLOWREF\t$ALLOW_SHA"
    echo -e "declarations_ref\t$DECL_REL\t$DECL_SHA"
    echo -e "verify_matched_unread_compare_points\t$VERIFY_MU\t-"
    if [ -f "$STG/script_closure.list" ]; then
      while IFS=$'\t' read -r orig snap lhash; do
        [ -z "$snap" ] && continue
        [ -f "$STG/$snap" ] && echo -e "executed_snapshot\t$snap\t$lhash"
      done < "$STG/script_closure.list"
    fi
    echo -e "impl_commit\t$IMPL_COMMIT\t-"
    echo -e "main_tracked_dirty\t$MAIN_DIRTY\t-"
    echo -e "worktree_head_pre\t$WT_HEAD_PRE\t-"
    echo -e "worktree_head_post\t$hpo\t-"
    echo -e "worktree_tracked_dirty_pre\t$WT_DIRTY_PRE\t-"
    echo -e "worktree_tracked_dirty_post\t$dpo\t-"
    echo -e "worktree_untracked_files\t$unt\t-"
  } > "$STG/TOOLS.tsv"
  if [ "$WT_HEAD_PRE" != "$IMPL_COMMIT" ] || [ "$hpo" != "$IMPL_COMMIT" ] || \
     [ "$WT_DIRTY_PRE" != "0" ] || [ "$dpo" != "0" ] || [ "$MAIN_DIRTY" != "0" ]; then
    echo "CLEAN_GATE_FAIL" >> "$STG/RESULT.txt"; rc=2
  fi
  echo "$rc" > "$STG/RUNNER_RC"
  git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"
  ( cd "$STG" && LC_ALL=C find . -type f ! -name MANIFEST.tsv | LC_ALL=C sort | sed 's|^\./||' | \
    while read -r f; do printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"; done \
  ) > "$STG/MANIFEST.tsv"
  sha256sum "$STG/MANIFEST.tsv" | cut -d' ' -f1 > "$STG/COMPLETE"
  mv -T --no-clobber "$STG" "$ED" || { echo "finalize_rename_fail"; exit 2; }
  exit "$rc"
}

# --- 运行(clean worktree; XSSV_HOME=WT 即提交态脚本; 落真实 fm_shell.rc)---
( cd "$D" && rm -f "fm_work/$TARGET/fm.log" && \
  FM_SIDECAR_OUT="$STG" FM_RUN_ID="$RID" \
  timeout "$TMO" make $MKARG "$MT" GOLDEN_RTL="$GOLDEN" XSSV_HOME="$WT" \
    FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS="$VERIFY_MU" \
    $([ "${MT:0:3}" = "fm-" ] && echo "FM_MODE=$PMODE") ) > "$STG/make.out" 2>&1
MAKE_RC=$?
cp "$D/fm_work/$TARGET/fm.log" "$STG/fm_log.txt" 2>/dev/null
RC=$(cat "$STG/fm_shell.rc" 2>/dev/null || echo NA)

# fail-closed: timeout / 无 native
if [ ! -f "$STG/native_facts.json" ]; then
  if [ "$MAKE_RC" = "124" ]; then CLS=TIMEOUT; else CLS=NO_NATIVE_FACTS; fi
  echo "TARGET $TARGET: $CLS (required=$REQV make_rc=$MAKE_RC fm_shell_rc=$RC) [SIGNOFF FAIL-CLOSED]" | tee "$STG/RESULT.txt"
  grep -aE "SIDECAR_ERROR|FM_MODE_ERROR" "$STG/fm_log.txt" 2>/dev/null | head -2 >> "$STG/RESULT.txt"
  finalize 5
fi
if [ "$RC" = "NA" ]; then echo "TARGET $TARGET: NO_FM_SHELL_RC" | tee "$STG/RESULT.txt"; finalize 3; fi

# --- closure digests(执行时刻快照; ref/impl RTL / script / tool)---
[ -f "$STG/script_closure.list" ] || { echo "no closure" | tee "$STG/RESULT.txt"; finalize 3; }
SNAPS=(); CBAD=0
while IFS=$'\t' read -r o snap h; do
  [ -z "$snap" ] && continue
  a=$(sha256sum "$STG/$snap" 2>/dev/null|cut -d' ' -f1)
  [ "$a" = "$h" ] || { echo "CLOSURE_HASH_MISMATCH $snap" >> "$STG/RESULT.txt"; CBAD=1; }
  SNAPS+=("$STG/$snap")
done < "$STG/script_closure.list"
[ "$CBAD" != 0 ] && { echo "TARGET $TARGET: INFRA_FAIL closure" | tee -a "$STG/RESULT.txt"; finalize 3; }
SCRIPT_DIG=$(python3 "$SC/fm_closure_digest.py" --mode concat "${SNAPS[@]}")
CMD=$(cd "$D" && make -n $MKARG "$MT" GOLDEN_RTL="$GOLDEN" XSSV_HOME="$WT" \
      FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS="$VERIFY_MU" \
      $([ "${MT:0:3}" = "fm-" ] && echo "FM_MODE=$PMODE") 2>/dev/null \
      | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell -64" | head -1)
gv(){ echo "$CMD" | grep -o "$1=\"[^\"]*\"" | head -1 | sed -e "s/^$1=\"//" -e 's/"$//'; }
REF_SRCS=$(gv FM_REF_SRCS); IMPL_SRCS=$(gv FM_IMPL_SRCS)
MERGE=$(echo "$CMD"|grep -o "FM_MERGE_DUP=[^ ]*"|head -1|cut -d= -f2); MERGE=${MERGE:-true}
SEM=(--semantic "DEFINE=SYNTHESIS" --semantic "MERGE_DUP=$MERGE" --semantic "MODE=$PMODE" \
     --semantic "VERIFY_MATCHED_UNREAD_COMPARE_POINTS=$VERIFY_MU" \
     --semantic "DECLARATIONS_SHA=$DECL_SHA" \
     --semantic "SCRIPT_CLOSURE_SHA=$SCRIPT_DIG" --semantic "MANIFEST_SHA=$MANIFEST_SHA" \
     --semantic "ALLOW_SHA=$ALLOW_SHA")
REF_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$GOLDEN" "${SEM[@]}" $REF_SRCS 2>/dev/null)
IMPL_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$WT" "${SEM[@]}" $IMPL_SRCS 2>/dev/null)
TOOL_DIG=$(python3 "$SC/fm_closure_digest.py" --mode tool "$(command -v fm_shell)")

# --- envelope + expectation(required_verdict + allowlist)+ validator ---
python3 - "$STG" "$RID" "$TARGET" "$PMODE" "$BID" "$REF_DIG" "$IMPL_DIG" "$SCRIPT_DIG" "$TOOL_DIG" "$RC" "$ALLOW_JSON" "$VERIFY_MU" <<'PYEOF'
import json,hashlib,os,sys
stg,rid,tgt,mode,bid,refd,impld,scrd,toold,rc,allowp,verify_mu=sys.argv[1:13]
nb=open(stg+"/native_facts.json","rb").read(); nat=json.loads(nb)
env={"schema":"fm-sidecar-envelope-v1","run_id":rid,"target":tgt,"top":nat["top"],
 "variant":tgt,"proof_mode":mode,"canonical_baseline_id":bid,
 "inputs_sha256":{"ref_srcs_digest":refd,"impl_srcs_digest":impld},"script_sha256":scrd,
 "tool":{"fm_shell_digest":toold},"fm_shell_rc":int(rc) if rc.lstrip('-').isdigit() else -1,
 "native_facts_sha256":hashlib.sha256(nb).hexdigest(),
 **{k:nat[k] for k in ("native_verdict","stats","unmatched","objects","qualifications","entry_appvars")}}
json.dump(env,open(stg+"/verdict.sidecar.json","w"))
allow=json.load(open(allowp))
expected_av=dict(nat["entry_appvars"])
expected_av["verification_verify_matched_unread_compare_points"]=verify_mu
exp={"run_id":rid,"target":tgt,"top":nat["top"],"variant":tgt,"proof_mode":mode,
 "canonical_baseline_id":bid,"ref_digest":refd,"impl_digest":impld,"script_digest":scrd,
 "tool_digest":toold,"entry_appvars":expected_av,"allow":allow}
json.dump(exp,open(stg+"/expectation.json","w"))
PYEOF
ACT=$(python3 "$SC/fm_sidecar_verdict.py" "$STG/verdict.sidecar.json" \
    --native-facts "$STG/native_facts.json" --expectation "$STG/expectation.json" \
    --actual-rc "$RC" 2>&1); VRC=$?; ACT=$(echo "$ACT"|head -1|cut -f1)

# signoff 判定: 只认 actual==required==SUCCEEDED(shadow: SHADOW_CHECK 单独统计)
if [ "$ACT" = "$REQV" ]; then GATE=PASS; else GATE=GAP; fi
{
  echo "SIGNOFF_RESULT $TARGET: measured=$ACT required=$REQV gate=$GATE (proof=$PMODE fm_shell_rc=$RC validator_rc=$VRC)"
  echo "run_id: $RID"; echo "impl_commit: $IMPL_COMMIT"; echo "manifest_sha256: $MANIFEST_SHA"
} | tee "$STG/RESULT.txt"
[ "$GATE" = PASS ] && finalize 0 || finalize 1
