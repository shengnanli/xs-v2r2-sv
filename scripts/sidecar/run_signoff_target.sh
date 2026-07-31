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
IFS=$'\t' read -r UTDIR MK MT ENTRY PMODE REQV ALLOWREF CFG VERIFY_MU DEADREF REFKIND DERIVID <<<"$(python3 - "$MANIFEST" "$TARGET" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for e in m["entries"]:
    if e["target"]==sys.argv[2]:
        print("\t".join([e["ut_dir"],e["makefile"] or "-",e["make_target"],e["entry"],
            e["proof_mode"],e["required_verdict"],e.get("allow_ref","") or "-",e["config_status"],
            e.get("verify_matched_unread_compare_points", "false"),
            e.get("dead_ref","") or "-",
            e.get("reference_kind","") or "golden",
            e.get("derivative_id","") or "-"])); break
else: print("NOTFOUND")
PY
)"
[ "$UTDIR" = "NOTFOUND" ] && { echo "MANIFEST_MISS $TARGET"; exit 2; }
# reference_kind security gate: only two committed kinds are legal. A
# canonical_derivative reference substitutes the frozen (possibly DCE-collapsed)
# golden StorePipe.sv with the pre-DCE observable derivative -- but ONLY from a
# committed, hash-pinned ledger resolved by manifest derivative_id. There is NO
# environment-variable path override; the reference bytes come exclusively from
# the committed ledger at IMPL_COMMIT (verified below).
case "$REFKIND" in
  golden|canonical_derivative) ;;
  *) echo "MANIFEST_BAD reference_kind=$REFKIND (only golden|canonical_derivative)"; exit 2 ;;
esac
if [ "$REFKIND" = "canonical_derivative" ] && { [ "$DERIVID" = "-" ] || [ -z "$DERIVID" ]; }; then
  echo "MANIFEST_BAD reference_kind=canonical_derivative requires derivative_id"; exit 2
fi
[ "$VERIFY_MU" = "true" ] || [ "$VERIFY_MU" = "false" ] || {
  echo "MANIFEST_BAD verify_matched_unread_compare_points=$VERIFY_MU"; exit 2; }
case "$TARGET" in LoadQueueUncache|FastArbiter_46|FastArbiter_47|FastArbiter_27|FastArbiter_44|ICacheCtrlUnit|ICacheDataArray|IPrefetchPipe|DivUnit|FDivSqrt|InstrMMIOEntry|InstrUncache|TXDAT_4|FAlu|FCVT|IssueQueueStdMoud|MulUnit|TXREQ|TlbStorageWrapper|TlbStorageWrapper_1|IssueQueueStaMou|IssueQueueLdu|TXDAT|Scheduler_1|Scheduler|Scheduler_3|MSHR|TageBTable|Directory|SCTable|SCTable_1|SCTable_2|SCTable_3|Tage_SC|ITTage|FauFTB|FTBBank|FTB|Composer|EntriesAluCsrFenceDiv|Bku|SourceB|Predictor|EntriesAluMulBkuBrhJmp|DuplicatedTagArray|PtwCache|WritebackQueue|LinkMonitor|Ftq|LoadQueue|LoadPipe|MissQueue|IssueQueueAluMulBkuBrhJmp|L2TLB|Rename|IssueQueueAluCsrFenceDiv|Scheduler_2|DebugModule|WbDataPath|IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v|Slice|LoadQueueReplay|NewCSR|DCache|DataPath|SnoopUnit|MemUnit|RefillUnit|ResponseUnit|OpenLLC|StoreQueue|FastArbiter_1|FastArbiter_2|FastArbiter_28|FastArbiter_29|Slice_1|Slice_2|Slice_3|Directory_1|Directory_2|Directory_3|PrefetchReqBuffer|RXSNP|Prefetcher|Pipeline_2|Pipeline_3|FusionDecoder|TL2CHICoupledL2|L2Top|PrefetchQueue|VBestOffsetPrefetch|MemCtrl|Frontend|CSR|VLSplitImp|VSSplitImp|AtomicsUnit|VSMergeBufferImp|VLMergeBufferImp|PTWNewFilter|L1Prefetcher|SMSPrefetcher|VSegmentUnit|MemBlock|HPerfMonitor_2|FastArbiter_77|FastArbiter_78|FastArbiter_79|TLBNonBlock_1|TLBNonBlock_2|ExuBlock_2|NCB200|NCB200_1|TLBNonBlock|BankedDataArray|StorePipe) ;;
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
# DECL 源可经 SIGNOFF_DECL_FILE override(AUX manifest 用独立 aux declarations, 与 305 分离);
# 默认 305 declarations。override 文件同样须 committed + SHA 冻结(下方检查不变)。
DECL_REL="${SIGNOFF_DECL_FILE:-scripts/sidecar/manifest_declarations.tsv}"
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

# --- 十四审: dead-ref 声明(可选): 运行前绑定, 须已提交, hash 入证据 ---
# 声明存在时验证器以 --dead-ref 收 golden-only 死点(逐点子集校验); 缺省=不吸收。
DEADREF_SHA="-"; DEADREF_JSON=""
if [ "$DEADREF" != "-" ] && [ -n "$DEADREF" ]; then
  if ! git -C "$SIGNOFF" cat-file -e "$IMPL_COMMIT:$DEADREF" 2>/dev/null; then
    echo "TARGET $TARGET: DEAD_REF_NOT_COMMITTED $DEADREF"; rm -rf "$STG"; exit 2; fi
  DEADREF_JSON="$STG/dead_ref.json"
  git -C "$SIGNOFF" show "$IMPL_COMMIT:$DEADREF" > "$DEADREF_JSON"
  DEADREF_SHA=$(sha256sum "$DEADREF_JSON" | cut -d' ' -f1)
fi

# --- detached clean worktree @ IMPL_COMMIT(提交态字节即冻结入口) ---
WTROOT=$(mktemp -d); WT="$WTROOT/wt"
git -C "$SIGNOFF" worktree add --detach --quiet "$WT" "$IMPL_COMMIT" || { echo "worktree失败"; rm -rf "$STG" "$WTROOT"; exit 2; }
WT_HEAD_PRE=$(git -C "$WT" rev-parse HEAD)
WT_DIRTY_PRE=$(git -C "$WT" status --porcelain --untracked-files=no | wc -l)
D="$WT/verif/ut/$UTDIR"

# --- reference_kind=canonical_derivative: committed, hash-pinned overlay ------
# Default reference root = frozen G0 golden. For a canonical_derivative target we
# resolve a per-id ledger under verif/freeze/canonical/derivatives/<derivative_id>,
# read its bytes ONLY from the committed tree (IMPL_COMMIT), verify the derivative
# .sv against the ledger's reference_sv_sha256 AND the whole ledger's root digest,
# then build a symlink-overlay of $GOLDEN with the top's .sv replaced by the
# derivative. GOLDEN is repointed at that overlay for both `make` and the closure
# digest. No env-var path is honored (security boundary).
DERIV_LEDGER_ROOT="-"; DERIV_SV_SHA="-"
DERIV_SURFACE_TOP=""; DERIV_SURFACE_REF_SV=""; DERIV_SURFACE_IMPL_SV=""
DERIV_SURFACE_REF_SHA="-"; DERIV_SURFACE_IMPL_SHA="-"
if [ "$REFKIND" = "canonical_derivative" ]; then
  LREL="verif/freeze/canonical/derivatives/$DERIVID"
  LEDGER_REL="$LREL/LEDGER.tsv"
  git -C "$SIGNOFF" cat-file -e "$IMPL_COMMIT:$LEDGER_REL" 2>/dev/null || {
    echo "TARGET $TARGET: DERIVATIVE_LEDGER_NOT_COMMITTED $LEDGER_REL"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  # Parse ledger fields from committed bytes (not the worktree checkout).
  LEDGER_TXT=$(git -C "$SIGNOFF" show "$IMPL_COMMIT:$LEDGER_REL")
  lval(){ printf '%s\n' "$LEDGER_TXT" | awk -F'\t' -v k="$1" '$1==k{print $2; exit}'; }
  L_KIND=$(lval reference_kind); L_ID=$(lval derivative_id)
  L_TOP=$(lval reference_top);   L_SV=$(lval reference_sv)
  L_SVSHA=$(lval reference_sv_sha256); L_ROOT=$(lval ledger_root_sha256)
  # Target-scoped semantic-surface WRAPPER (codex_0092 §1, option B). OPTIONAL
  # ledger fields: two per-side wrapper .sv (module semantic_surface_top) that
  # re-export ONLY the source-defined outputs and leave the UNSPECIFIED-by-source
  # (invalidate-only) output leaves off the surface.  This is NOT a generic
  # dont_verify / "exclude any point" / "swap any top" runner knob: the wrapper
  # bytes come EXCLUSIVELY from the committed ledger, keyed by this derivative_id,
  # and are hash-checked against the ledger's per-wrapper sha256 (themselves bound
  # into ledger_root_sha256).  No env-var path override.  Absent => full compare.
  L_STOP=$(lval semantic_surface_top)
  L_SREF=$(lval semantic_surface_ref);   L_SREFSHA=$(lval semantic_surface_ref_sha256)
  L_SIMPL=$(lval semantic_surface_impl); L_SIMPLSHA=$(lval semantic_surface_impl_sha256)
  [ "$L_KIND" = "canonical_derivative" ] || { echo "TARGET $TARGET: LEDGER_KIND_BAD $L_KIND"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  [ "$L_ID" = "$DERIVID" ] || { echo "TARGET $TARGET: LEDGER_ID_MISMATCH manifest=$DERIVID ledger=$L_ID"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  [ "$L_TOP" = "$TARGET" ] || { echo "TARGET $TARGET: LEDGER_TOP_MISMATCH ledger reference_top=$L_TOP"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  # Reproduce the ledger root digest over committed artifact bytes; must match.
  CALC_ROOT=$(python3 - "$SIGNOFF" "$IMPL_COMMIT" "$LREL" <<'PY'
import subprocess,sys,hashlib
signoff,commit,lrel=sys.argv[1:4]
ledger=subprocess.check_output(["git","-C",signoff,"show",f"{commit}:{lrel}/LEDGER.tsv"]).decode()
arts=[]
for ln in ledger.splitlines():
    p=ln.split("\t")
    if p[0]=="artifact": arts.append((p[1],int(p[2]),p[3]))
blob=b""
for fn,size,sha in sorted(arts):
    b=subprocess.check_output(["git","-C",signoff,"show",f"{commit}:{lrel}/{fn}"])
    if len(b)!=size or hashlib.sha256(b).hexdigest()!=sha:
        print("ARTIFACT_DRIFT "+fn); sys.exit(0)
    blob+=f"{fn}\t{size}\t{sha}\n".encode()
print(hashlib.sha256(blob).hexdigest())
PY
)
  [ "$CALC_ROOT" = "$L_ROOT" ] || { echo "TARGET $TARGET: LEDGER_ROOT_MISMATCH computed=$CALC_ROOT ledger=$L_ROOT"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  # Materialize the derivative .sv from committed bytes; verify against ledger SHA.
  OVL="$WTROOT/golden-overlay"; mkdir -p "$OVL"
  # symlink-farm the frozen golden so any deps still resolve
  for g in "$GOLDEN"/*; do ln -s "$g" "$OVL/$(basename "$g")"; done
  rm -f "$OVL/$L_SV"
  git -C "$SIGNOFF" show "$IMPL_COMMIT:$LREL/$L_SV" > "$OVL/$L_SV"
  GOT_SVSHA=$(sha256sum "$OVL/$L_SV" | cut -d' ' -f1)
  [ "$GOT_SVSHA" = "$L_SVSHA" ] || { echo "TARGET $TARGET: DERIVATIVE_SV_SHA_MISMATCH got=$GOT_SVSHA ledger=$L_SVSHA"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  GOLDEN="$OVL"; DERIV_LEDGER_ROOT="$L_ROOT"; DERIV_SV_SHA="$L_SVSHA"
  echo "REFERENCE_KIND canonical_derivative id=$DERIVID sv_sha=$L_SVSHA ledger_root=$L_ROOT" > "$STG/reference_kind.txt"
  # ---- semantic-surface wrapper staging (hard-bound; no env override) -------
  # Present only when the committed ledger declares the surface fields.  All or
  # nothing: a partial set (top without a wrapper, wrapper without a sha, etc.)
  # is a corrupt/tampered ledger => fail-closed.
  bail(){ echo "TARGET $TARGET: $1"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2; }
  _surf_any=0
  for v in "$L_STOP" "$L_SREF" "$L_SREFSHA" "$L_SIMPL" "$L_SIMPLSHA"; do
    { [ -n "$v" ] && [ "$v" != "-" ]; } && _surf_any=1
  done
  if [ "$_surf_any" = 1 ]; then
    for kv in "semantic_surface_top:$L_STOP" "semantic_surface_ref:$L_SREF" \
              "semantic_surface_ref_sha256:$L_SREFSHA" \
              "semantic_surface_impl:$L_SIMPL" "semantic_surface_impl_sha256:$L_SIMPLSHA"; do
      val=${kv#*:}
      { [ -n "$val" ] && [ "$val" != "-" ]; } || bail "SEMANTIC_SURFACE_INCOMPLETE missing ${kv%%:*}"
    done
    # stage + hash-verify each wrapper from committed bytes (never worktree).
    stage_surf(){ # <file> <want_sha> <outvar-name>
      local f="$1" want="$2" out="$3" p="$WTROOT/$1" got
      git -C "$SIGNOFF" cat-file -e "$IMPL_COMMIT:$LREL/$f" 2>/dev/null || bail "SEMANTIC_SURFACE_NOT_COMMITTED $LREL/$f"
      git -C "$SIGNOFF" show "$IMPL_COMMIT:$LREL/$f" > "$p"
      got=$(sha256sum "$p" | cut -d' ' -f1)
      [ "$got" = "$want" ] || bail "SEMANTIC_SURFACE_SHA_MISMATCH $f got=$got ledger=$want"
      printf -v "$out" '%s' "$p"
    }
    stage_surf "$L_SREF"  "$L_SREFSHA"  DERIV_SURFACE_REF_SV
    stage_surf "$L_SIMPL" "$L_SIMPLSHA" DERIV_SURFACE_IMPL_SV
    DERIV_SURFACE_TOP="$L_STOP"; DERIV_SURFACE_REF_SHA="$L_SREFSHA"; DERIV_SURFACE_IMPL_SHA="$L_SIMPLSHA"
    cp "$DERIV_SURFACE_REF_SV"  "$STG/$L_SREF"
    cp "$DERIV_SURFACE_IMPL_SV" "$STG/$L_SIMPL"
    echo "SEMANTIC_SURFACE id=$DERIVID top=$L_STOP ref_sha=$L_SREFSHA impl_sha=$L_SIMPLSHA" >> "$STG/reference_kind.txt"
  fi
fi
# Security invariant: a semantic surface is ONLY ever set from the committed,
# hash-verified canonical_derivative ledger above.  A golden-reference target can
# never carry one (no code path sets DERIV_SURFACE_TOP outside the block).
if [ "$REFKIND" = "golden" ] && [ -n "$DERIV_SURFACE_TOP" ]; then
  echo "TARGET $TARGET: SEMANTIC_SURFACE_ON_GOLDEN (illegal)"; rm -rf "$STG"; git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; exit 2
fi

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
    echo -e "dead_ref\t$DEADREF\t$DEADREF_SHA"
    echo -e "declarations_ref\t$DECL_REL\t$DECL_SHA"
    echo -e "reference_kind\t$REFKIND\t-"
    echo -e "derivative_id\t$DERIVID\t-"
    echo -e "derivative_sv_sha256\t-\t$DERIV_SV_SHA"
    echo -e "derivative_ledger_root\t-\t$DERIV_LEDGER_ROOT"
    echo -e "semantic_surface_top\t${DERIV_SURFACE_TOP:--}\t-"
    echo -e "semantic_surface_ref_sha256\t-\t$DERIV_SURFACE_REF_SHA"
    echo -e "semantic_surface_impl_sha256\t-\t$DERIV_SURFACE_IMPL_SHA"
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
# FM_SEMANTIC_SURFACE_* are only ever the hash-verified committed wrappers staged
# above (empty otherwise).  They repoint the FM top to the surface wrapper and
# append each side's wrapper .sv -- a dedicated, target-scoped mechanism, never a
# free-form dont_verify list or arbitrary top-swap.
SURF_MK=""
[ -n "$DERIV_SURFACE_TOP" ] && SURF_MK="FM_SEMANTIC_SURFACE_TOP=$DERIV_SURFACE_TOP FM_SEMANTIC_SURFACE_REF_SV=$DERIV_SURFACE_REF_SV FM_SEMANTIC_SURFACE_IMPL_SV=$DERIV_SURFACE_IMPL_SV"
( cd "$D" && rm -f "fm_work/$TARGET/fm.log" && \
  FM_SIDECAR_OUT="$STG" FM_RUN_ID="$RID" \
  timeout "$TMO" make $MKARG "$MT" GOLDEN_RTL="$GOLDEN" XSSV_HOME="$WT" \
    $SURF_MK \
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
      $SURF_MK \
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
     --semantic "ALLOW_SHA=$ALLOW_SHA" --semantic "DEAD_REF_SHA=$DEADREF_SHA" \
     --semantic "REFERENCE_KIND=$REFKIND" --semantic "DERIVATIVE_ID=$DERIVID" \
     --semantic "DERIVATIVE_LEDGER_ROOT=$DERIV_LEDGER_ROOT" \
     --semantic "SEMANTIC_SURFACE_TOP=${DERIV_SURFACE_TOP:--}" \
     --semantic "SEMANTIC_SURFACE_REF_SHA=$DERIV_SURFACE_REF_SHA" \
     --semantic "SEMANTIC_SURFACE_IMPL_SHA=$DERIV_SURFACE_IMPL_SHA")
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
DEADREF_ARG=(); [ -n "$DEADREF_JSON" ] && DEADREF_ARG=(--dead-ref "$DEADREF_JSON")
ACT=$(python3 "$SC/fm_sidecar_verdict.py" "$STG/verdict.sidecar.json" \
    --native-facts "$STG/native_facts.json" --expectation "$STG/expectation.json" \
    --actual-rc "$RC" "${DEADREF_ARG[@]}" 2>&1); VRC=$?; ACT=$(echo "$ACT"|head -1|cut -f1)

# signoff 判定: 只认 actual==required==SUCCEEDED(shadow: SHADOW_CHECK 单独统计)
if [ "$ACT" = "$REQV" ]; then GATE=PASS; else GATE=GAP; fi
{
  echo "SIGNOFF_RESULT $TARGET: measured=$ACT required=$REQV gate=$GATE (proof=$PMODE fm_shell_rc=$RC validator_rc=$VRC)"
  echo "run_id: $RID"; echo "impl_commit: $IMPL_COMMIT"; echo "manifest_sha256: $MANIFEST_SHA"
} | tee "$STG/RESULT.txt"
[ "$GATE" = PASS ] && finalize 0 || finalize 1
