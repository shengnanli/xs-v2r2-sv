#!/usr/bin/env bash
# Step 3B runner(验收一审重写, fail-closed)。
# 用法: fm_sidecar_run.sh <session_name> <target> [FM_MODE] [额外make变量...]
# rc 契约: SUCCEEDED→0; PARTIAL/FAILED/ERROR/UNRUN/其他→validator rc(非0);
#          NO_NATIVE_FACTS→5; 基建失败→2/3/4。任何非 SUCCEEDED 不得 shell 成功。
# 证据: staging 目录组装 → TOOLS.tsv(实际执行代码 hash+commit+dirty) → MANIFEST.tsv
#       → COMPLETE(MANIFEST 的 sha256) → 原子 rename(no-force)。
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
BID=$(awk -F'\t' '$1=="canonical_baseline_id"{print $2}' /home/eda/xs-env/G0-canonical/PROMOTION_LEDGER.tsv)
SC="$SIGNOFF/scripts/sidecar"

SESSION=$1; TARGET=$2; MODE=${3:-signoff-strict}; shift 3 || shift 2
EXTRA=("$@")
D="$SIGNOFF/verif/ut/$TARGET"
ED="$SC/step3b-evidence/$SESSION"
STG="$ED.staging"
[ -e "$ED" ] && { echo "REFUSE: $ED 已存在(no-force)"; exit 2; }
[ -e "$STG" ] && { echo "REFUSE: $STG 残留(先清理)"; exit 2; }
mkdir -p "$STG"
RID="R3B-$SESSION-$(date +%s)"

finalize() {  # $1 = 最终 rc
  local rc=$1
  # TOOLS.tsv: 实际执行代码的 hash 绑定(script_closure.list 存在则以其为准)
  {
    echo -e "kind\tpath\tsha256"
    for f in "$SC/fm_sidecar_run.sh" "$SIGNOFF/scripts/ut_common.mk" \
             "$SC/fm_closure_digest.py" "$SC/fm_sidecar_verdict.py"; do
      echo -e "infra\t$f\t$(sha256sum "$f"|cut -d' ' -f1)"
    done
    if [ -f "$STG/script_closure.list" ]; then
      while read -r f; do
        [ -f "$f" ] && echo -e "executed\t$f\t$(sha256sum "$f"|cut -d' ' -f1)"
      done < "$STG/script_closure.list"
    fi
    echo -e "commit\t$(git -C "$SIGNOFF" rev-parse HEAD)\t-"
    echo -e "tracked_dirty_files\t$(git -C "$SIGNOFF" status --porcelain --untracked-files=no | wc -l)\t-"
  } > "$STG/TOOLS.tsv"
  ( cd "$STG" && LC_ALL=C ls | LC_ALL=C sort | grep -v "^MANIFEST.tsv$" | while read -r f; do
      printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
    done ) > "$STG/MANIFEST.tsv"
  sha256sum "$STG/MANIFEST.tsv" | cut -d' ' -f1 > "$STG/COMPLETE"
  mv -T --no-clobber "$STG" "$ED" || { echo "finalize_rename_fail"; exit 2; }
  exit "$rc"
}

# --- 运行(真实 rc 由 ut_common.mk 落 fm_shell.rc) ---
( cd "$D" && rm -f "fm_work/$TARGET/fm.log" && \
  FM_SIDECAR_OUT="$STG" FM_RUN_ID="$RID" \
  make fm FM_MODE="$MODE" GOLDEN_RTL="$GOLDEN" "${EXTRA[@]}" ) > "$STG/make.out" 2>&1
MAKE_RC=$?
cp "$D/fm_work/$TARGET/fm.log" "$STG/fm.log" 2>/dev/null
if [ ! -f "$STG/fm_shell.rc" ]; then
  echo "SESSION_RESULT $SESSION: INFRA_FAIL no_fm_shell_rc(make_rc=$MAKE_RC)" | tee "$STG/RESULT.txt"
  finalize 3
fi
RC=$(cat "$STG/fm_shell.rc")

if [ ! -f "$STG/native_facts.json" ]; then
  {
    echo "SESSION_RESULT $SESSION: NO_NATIVE_FACTS rc=$RC (emitter拒产=fail-closed, runner rc=5)"
    grep -aE "SIDECAR_ERROR|FM_MODE_ERROR" "$STG/fm.log" 2>/dev/null
  } | tee "$STG/RESULT.txt"
  finalize 5
fi

# --- closure digests: script 侧取运行期记账的真实清单 ---
if [ ! -f "$STG/script_closure.list" ]; then
  echo "SESSION_RESULT $SESSION: INFRA_FAIL no_script_closure_list" | tee "$STG/RESULT.txt"
  finalize 3
fi
mapfile -t SRCED < "$STG/script_closure.list"
SCRIPT_DIG=$(python3 "$SC/fm_closure_digest.py" --mode concat "${SRCED[@]}")

CMD=$(cd "$D" && make -n fm FM_MODE="$MODE" GOLDEN_RTL="$GOLDEN" "${EXTRA[@]}" 2>/dev/null \
      | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell -64" | head -1)
extract_var() { echo "$CMD" | grep -o "$1=\"[^\"]*\"" | head -1 | sed -e "s/^$1=\"//" -e 's/"$//'; }
REF_SRCS=$(extract_var FM_REF_SRCS); IMPL_SRCS=$(extract_var FM_IMPL_SRCS)
MERGE=$(echo "$CMD" | grep -o "FM_MERGE_DUP=[^ ]*" | head -1 | cut -d= -f2); MERGE=${MERGE:-true}
FMAP=$(echo "$CMD" | grep -o "FM_FIELD_MAP=[^ ]*" | head -1 | cut -d= -f2)
SEM=(--semantic "DEFINE=SYNTHESIS" --semantic "MERGE_DUP=$MERGE" --semantic "MODE=$MODE")
[ -n "$FMAP" ] && SEM+=(--semantic "FIELD_MAP_SHA=$(sha256sum $FMAP | cut -d' ' -f1)")
SEM+=(--semantic "SCRIPT_CLOSURE_SHA=$SCRIPT_DIG")
REF_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$GOLDEN" "${SEM[@]}" $REF_SRCS)
IMPL_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$SIGNOFF" "${SEM[@]}" $IMPL_SRCS)
TOOL_DIG=$(python3 "$SC/fm_closure_digest.py" --mode tool "$(command -v fm_shell)")

# --- envelope + smoke expectation ---
python3 - "$STG" "$RID" "$TARGET" "$MODE" "$BID" "$REF_DIG" "$IMPL_DIG" "$SCRIPT_DIG" "$TOOL_DIG" "$RC" <<'PYEOF'
import json, hashlib, os, sys
ed, rid, tgt, mode, bid, refd, impld, scrd, toold, rc = sys.argv[1:11]
nat_buf = open(os.path.join(ed, "native_facts.json"), "rb").read()
nat = json.loads(nat_buf)
env = {"schema": "fm-sidecar-envelope-v1", "run_id": rid, "target": tgt, "top": nat["top"],
       "variant": tgt, "proof_mode": mode, "canonical_baseline_id": bid,
       "inputs_sha256": {"ref_srcs_digest": refd, "impl_srcs_digest": impld},
       "script_sha256": scrd, "tool": {"fm_shell_digest": toold},
       "fm_shell_rc": int(rc),
       "native_facts_sha256": hashlib.sha256(nat_buf).hexdigest(),
       **{k: nat[k] for k in ("native_verdict", "stats", "unmatched", "objects",
                              "qualifications", "entry_appvars")}}
tmp = os.path.join(ed, "verdict.sidecar.json.tmp")
fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
with os.fdopen(fd, "w") as f:
    json.dump(env, f); f.flush(); os.fsync(f.fileno())
final = os.path.join(ed, "verdict.sidecar.json")
if os.path.exists(final):
    os.unlink(tmp); raise SystemExit("envelope已存在(no-force)")
os.rename(tmp, final)
# smoke expectation(机制链路验证; 外部独立钉死由 305 manifest 提供——见 STEP3B_SMOKE 限界)
exp = {"run_id": rid, "target": tgt, "top": nat["top"], "variant": tgt, "proof_mode": mode,
       "canonical_baseline_id": bid, "ref_digest": refd, "impl_digest": impld,
       "script_digest": scrd, "tool_digest": toold,
       "entry_appvars": nat["entry_appvars"],
       "allow": {"unresolved_blackbox": [], "interface_only": [],
                 "empty_blackbox": [], "unmatched": []}}
json.dump(exp, open(os.path.join(ed, "expectation.smoke.json"), "w"))
PYEOF
[ $? -ne 0 ] && { echo "SESSION_RESULT $SESSION: INFRA_FAIL envelope" | tee "$STG/RESULT.txt"; finalize 4; }

V=$(python3 "$SC/fm_sidecar_verdict.py" "$STG/verdict.sidecar.json" \
    --native-facts "$STG/native_facts.json" \
    --expectation "$STG/expectation.smoke.json" --actual-rc "$RC" 2>&1)
VRC=$?
V=$(echo "$V" | head -1)
{
  echo "SESSION_RESULT $SESSION: $V (validator_rc=$VRC fm_shell_rc=$RC make_rc=$MAKE_RC runner_rc=$VRC)"
  echo "run_id: $RID"
  echo "signoff_commit: $(git -C "$SIGNOFF" rev-parse HEAD)"
  echo "tracked_dirty: $(git -C "$SIGNOFF" status --porcelain --untracked-files=no | wc -l)"
} | tee "$STG/RESULT.txt"
finalize "$VRC"
