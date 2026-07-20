#!/usr/bin/env bash
# Step 3B runner: clean 入口跑 fm(带 sidecar emitter), 取真实 fm_shell rc, 计算 closure
# digests, 原子写 envelope(fm-sidecar-envelope-v1), 生成 smoke expectation, 跑 validator。
# 用法: fm_sidecar_run.sh <session_name> <target> [FM_MODE] [额外make变量...]
# 产物: scripts/sidecar/step3b-evidence/<session>/ (会话名已存在则拒绝, no-force)
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
BID=$(awk -F'\t' '$1=="canonical_baseline_id"{print $2}' /home/eda/xs-env/G0-canonical/PROMOTION_LEDGER.tsv)
SC="$SIGNOFF/scripts/sidecar"

SESSION=$1; TARGET=$2; MODE=${3:-signoff-strict}; shift 3 || shift 2
EXTRA=("$@")
D="$SIGNOFF/verif/ut/$TARGET"
ED="$SC/step3b-evidence/$SESSION"
[ -e "$ED" ] && { echo "REFUSE: $ED 已存在(no-force)"; exit 2; }
mkdir -p "$ED"
RID="R3B-$SESSION-$(date +%s)"

# --- 运行(真实 rc 由 ut_common.mk 落 fm_shell.rc; make rc 是 fm_verdict 的判定) ---
( cd "$D" && rm -f "fm_work/$TARGET/fm.log" && \
  FM_SIDECAR_OUT="$ED" FM_RUN_ID="$RID" \
  make fm FM_MODE="$MODE" GOLDEN_RTL="$GOLDEN" "${EXTRA[@]}" ) > "$ED/make.out" 2>&1
MAKE_RC=$?
cp "$D/fm_work/$TARGET/fm.log" "$ED/fm.log" 2>/dev/null
if [ ! -f "$ED/fm_shell.rc" ]; then
  echo "SESSION_RESULT $SESSION: no_fm_shell_rc(make_rc=$MAKE_RC)" | tee "$ED/RESULT.txt"
  exit 3
fi
RC=$(cat "$ED/fm_shell.rc")

if [ ! -f "$ED/native_facts.json" ]; then
  # emitter 拒产(拦截/非终态/解析失败)——本身就是一个判定结果
  V_OUT=$(python3 "$SC/fm_sidecar_verdict.py" /dev/null --native-facts /dev/null \
          --expectation /dev/null --actual-rc "$RC" 2>&1 | head -1)
  echo "SESSION_RESULT $SESSION: NO_NATIVE_FACTS rc=$RC (emitter拒产=fail-closed)" | tee "$ED/RESULT.txt"
  grep -E "SIDECAR_ERROR|FM_MODE_ERROR" "$ED/fm.log" >> "$ED/RESULT.txt" 2>/dev/null
  exit 0
fi

# --- closure digests(schema v7 算法) ---
CMD=$(cd "$D" && make -n fm FM_MODE="$MODE" GOLDEN_RTL="$GOLDEN" "${EXTRA[@]}" 2>/dev/null \
      | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell -64" | head -1)
extract_var() { echo "$CMD" | grep -o "$1=\"[^\"]*\"" | head -1 | sed -e "s/^$1=\"//" -e 's/"$//'; }
REF_SRCS=$(extract_var FM_REF_SRCS); IMPL_SRCS=$(extract_var FM_IMPL_SRCS)
MERGE=$(echo "$CMD" | grep -o "FM_MERGE_DUP=[^ ]*" | head -1 | cut -d= -f2); MERGE=${MERGE:-true}
IFACE=$(extract_var FM_INTERFACE_ONLY)
PINS=(); for v in FM_PIN_PRE_TCL FM_PIN_TCL; do
  p=$(echo "$CMD" | grep -o "$v=[^ ]*" | head -1 | cut -d= -f2); [ -n "$p" ] && PINS+=("$p")
done
FMAP=$(echo "$CMD" | grep -o "FM_FIELD_MAP=[^ ]*" | head -1 | cut -d= -f2)
SEM=(--semantic "DEFINE=SYNTHESIS" --semantic "MERGE_DUP=$MERGE" --semantic "MODE=$MODE")
[ -n "$FMAP" ] && SEM+=(--semantic "FIELD_MAP_SHA=$(sha256sum $FMAP | cut -d' ' -f1)")
[ ${#PINS[@]} -gt 0 ] && SEM+=(--semantic "PINS_SHA=$(cat "${PINS[@]}" | sha256sum | cut -d' ' -f1)")
REF_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$GOLDEN" "${SEM[@]}" $REF_SRCS)
IMPL_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$SIGNOFF" "${SEM[@]}" $IMPL_SRCS)
SCRIPT_DIG=$(python3 "$SC/fm_closure_digest.py" --mode concat \
  "$SIGNOFF/scripts/fm_eq.tcl" "$SC/fm_native_emit.tcl" ${PINS[@]+"${PINS[@]}"})
TOOL_DIG=$(python3 "$SC/fm_closure_digest.py" --mode tool "$(command -v fm_shell)")

# --- envelope + smoke expectation + validator ---
python3 - "$ED" "$RID" "$TARGET" "$MODE" "$BID" "$REF_DIG" "$IMPL_DIG" "$SCRIPT_DIG" "$TOOL_DIG" "$RC" <<'PYEOF'
import json, hashlib, os, sys
ed, rid, tgt, mode, bid, refd, impld, scrd, toold, rc = sys.argv[1:11]
nat_path = os.path.join(ed, "native_facts.json")
nat_buf = open(nat_path, "rb").read()
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
    json.dump(env, f)
    f.flush(); os.fsync(f.fileno())
final = os.path.join(ed, "verdict.sidecar.json")
if os.path.exists(final):
    os.unlink(tmp); raise SystemExit("envelope 已存在(no-force)")
os.rename(tmp, final)
# smoke expectation(注: 正式流程中 expectation 来自 305 manifest 的外部钉死;
# smoke 中由同批 digests 生成, 只验证机制链路, 不构成外部独立性)
exp = {"run_id": rid, "target": tgt, "top": nat["top"], "variant": tgt, "proof_mode": mode,
       "canonical_baseline_id": bid, "ref_digest": refd, "impl_digest": impld,
       "script_digest": scrd, "tool_digest": toold,
       "entry_appvars": nat["entry_appvars"],
       "allow": {"unresolved_blackbox": [], "interface_only": [],
                 "empty_blackbox": [], "unmatched": []}}
json.dump(exp, open(os.path.join(ed, "expectation.smoke.json"), "w"))
PYEOF
[ $? -ne 0 ] && { echo "SESSION_RESULT $SESSION: envelope_fail" | tee "$ED/RESULT.txt"; exit 4; }

V=$(python3 "$SC/fm_sidecar_verdict.py" "$ED/verdict.sidecar.json" \
    --native-facts "$ED/native_facts.json" \
    --expectation "$ED/expectation.smoke.json" --actual-rc "$RC" 2>&1)
VRC=$?
V=$(echo "$V" | head -1)
{
  echo "SESSION_RESULT $SESSION: $V (validator_rc=$VRC fm_shell_rc=$RC make_rc=$MAKE_RC)"
  echo "run_id: $RID"
  echo "signoff_commit: $(git -C "$SIGNOFF" rev-parse HEAD)"
} | tee "$ED/RESULT.txt"
( cd "$ED" && LC_ALL=C ls | LC_ALL=C sort | while read -r f; do
    printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$f")" "$(sha256sum "$f"|cut -d' ' -f1)"
  done ) > "$ED/../$SESSION.MANIFEST.tsv"
