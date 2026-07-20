#!/usr/bin/env bash
# Step 3B runner(验收三审重写)。
# 三审要点: ①FM 在 **detached clean worktree**(HEAD=当前实现提交)中执行, 运行前后
# 强制 HEAD 不变+tracked clean, 记入 TOOLS; ②入口/emitter/verdict 冻结进 staging
# (frozen/), FM 经 XSSV_HOOME=frozen 只执行 staging 字节(探针改动=PROBE_SED 作用于
# frozen 副本→字节随证据入 commit); ③script closure=执行时刻字节快照(emitter 落
# sourced_NNN_*), runner 只对快照做 digest; ④证据根 step3b-evidence-r3(全新, 避免
# 与历史 tracked 证据同名冲突导致 dirty)。
# rc 契约: SUCCEEDED→0; 其他 verdict→validator rc(非0); NO_NATIVE_FACTS→5; 基建→2-4。
# 可选 env: PROBE_SED(sed 表达式, 作用于 frozen fm_eq.tcl); STIM_PRE(文件, 拷为
# worktree 的 fm_pins_pre.tcl 刺激)。
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
BID=$(awk -F'\t' '$1=="canonical_baseline_id"{print $2}' /home/eda/xs-env/G0-canonical/PROMOTION_LEDGER.tsv)
SC="$SIGNOFF/scripts/sidecar"
EROOT="$SC/step3b-evidence-r3"

SESSION=$1; TARGET=$2; MODE=${3:-signoff-strict}; shift 3 || shift 2
EXTRA=("$@")
ED="$EROOT/$SESSION"
STG="$ED.staging"
[ -e "$ED" ] && { echo "REFUSE: $ED 已存在(no-force)"; exit 2; }
[ -e "$STG" ] && { echo "REFUSE: $STG 残留(先清理)"; exit 2; }
mkdir -p "$STG"
RID="R3B-$SESSION-$(date +%s)"
IMPL_COMMIT=$(git -C "$SIGNOFF" rev-parse HEAD)

# --- frozen 脚本树(FM 只执行 staging 字节) ---
mkdir -p "$STG/frozen/scripts/sidecar"
cp "$SIGNOFF/scripts/fm_eq.tcl" "$STG/frozen/scripts/fm_eq.tcl"
cp "$SIGNOFF/scripts/fm_verdict.py" "$STG/frozen/scripts/fm_verdict.py"
cp "$SC/fm_native_emit.tcl" "$STG/frozen/scripts/sidecar/fm_native_emit.tcl"
if [ -n "${PROBE_SED:-}" ]; then
  sed -i "$PROBE_SED" "$STG/frozen/scripts/fm_eq.tcl"
fi

# --- detached clean worktree ---
WTROOT=$(mktemp -d); WT="$WTROOT/wt"
git -C "$SIGNOFF" worktree add --detach --quiet "$WT" "$IMPL_COMMIT" || { echo "worktree失败"; exit 2; }
cleanup_wt() { git -C "$SIGNOFF" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$WTROOT"; }
WT_HEAD_PRE=$(git -C "$WT" rev-parse HEAD)
WT_DIRTY_PRE=$(git -C "$WT" status --porcelain --untracked-files=no | wc -l)
D="$WT/verif/ut/$TARGET"
[ -n "${STIM_PRE:-}" ] && cp "$STIM_PRE" "$D/fm_pins_pre.tcl"
# STIM_INNER: 嵌套 source 的内层文件, 预置进 UT 目录(外层刺激经受控 source alias 引用)
[ -n "${STIM_INNER:-}" ] && cp "$STIM_INNER" "$D/fm_pins_inner.tcl"

finalize() {  # $1 = 最终 rc
  local rc=$1
  local WT_HEAD_POST=$(git -C "$WT" rev-parse HEAD 2>/dev/null || echo GONE)
  local WT_DIRTY_POST=$(git -C "$WT" status --porcelain --untracked-files=no 2>/dev/null | wc -l)
  local WT_UNTRACKED=$(git -C "$WT" status --porcelain 2>/dev/null | grep -c '^??' || true)
  {
    echo -e "kind\tpath\tsha256"
    for f in "$SC/fm_sidecar_run.sh" "$SIGNOFF/scripts/ut_common.mk" \
             "$SC/fm_closure_digest.py" "$SC/fm_sidecar_verdict.py" \
             "$SC/step3b_archive_check.sh"; do
      echo -e "infra\t$f\t$(sha256sum "$f"|cut -d' ' -f1)"
    done
    if [ -f "$STG/script_closure.list" ]; then
      while IFS=$'\t' read -r orig snap; do
        [ -f "$STG/$snap" ] && echo -e "executed_snapshot\t$orig -> $snap\t$(sha256sum "$STG/$snap"|cut -d' ' -f1)"
      done < "$STG/script_closure.list"
    fi
    echo -e "impl_commit\t$IMPL_COMMIT\t-"
    echo -e "main_tracked_dirty\t$(git -C "$SIGNOFF" status --porcelain --untracked-files=no | wc -l)\t-"
    echo -e "worktree_head_pre\t$WT_HEAD_PRE\t-"
    echo -e "worktree_head_post\t$WT_HEAD_POST\t-"
    echo -e "worktree_tracked_dirty_pre\t$WT_DIRTY_PRE\t-"
    echo -e "worktree_tracked_dirty_post\t$WT_DIRTY_POST\t-"
    echo -e "worktree_untracked_files\t$WT_UNTRACKED\t-"
  } > "$STG/TOOLS.tsv"
  # 三审: HEAD 前后不变 + tracked clean 是硬闸
  if [ "$WT_HEAD_PRE" != "$IMPL_COMMIT" ] || [ "$WT_HEAD_POST" != "$IMPL_COMMIT" ] || \
     [ "$WT_DIRTY_PRE" != "0" ] || [ "$WT_DIRTY_POST" != "0" ]; then
    echo "CLEAN_GATE_FAIL head=$WT_HEAD_PRE/$WT_HEAD_POST dirty=$WT_DIRTY_PRE/$WT_DIRTY_POST" >> "$STG/RESULT.txt"
    rc=2
  fi
  # 四审: 结构化 runner 回执(archive checker 语义校验的锚)
  echo "$rc" > "$STG/RUNNER_RC"
  cleanup_wt
  ( cd "$STG" && LC_ALL=C find . -mindepth 1 \( -type f -o -type d \) | LC_ALL=C sort | sed 's|^\./||' | \
    while read -r f; do
      if [ -f "$STG/$f" ] && [ "$f" != "MANIFEST.tsv" ]; then
        printf '%s\t%s\t%s\n' "$f" "$(stat -c%s "$STG/$f")" "$(sha256sum "$STG/$f"|cut -d' ' -f1)"
      fi
    done ) > "$STG/MANIFEST.tsv"
  sha256sum "$STG/MANIFEST.tsv" | cut -d' ' -f1 > "$STG/COMPLETE"
  mv -T --no-clobber "$STG" "$ED" || { echo "finalize_rename_fail"; exit 2; }
  exit "$rc"
}

# --- 预跑提取命令与刺激绑定 ---
CMD=$(cd "$D" && make -n fm FM_MODE="$MODE" GOLDEN_RTL="$GOLDEN" XSSV_HOME="$STG/frozen" "${EXTRA[@]}" 2>/dev/null \
      | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell -64" | head -1)
extract_var() { echo "$CMD" | grep -o "$1=\"[^\"]*\"" | head -1 | sed -e "s/^$1=\"//" -e 's/"$//'; }
for v in FM_PIN_PRE_TCL FM_PIN_TCL; do
  p=$(echo "$CMD" | grep -o "$v=[^ ]*" | head -1 | cut -d= -f2)
  [ -n "$p" ] && [ -f "$p" ] && cp "$p" "$STG/stimulus_$(basename "$p")"
done
[ -n "${STIM_INNER:-}" ] && [ -f "$D/fm_pins_inner.tcl" ] && cp "$D/fm_pins_inner.tcl" "$STG/stimulus_fm_pins_inner.tcl"

# --- 运行 ---
( cd "$D" && FM_SIDECAR_OUT="$STG" FM_RUN_ID="$RID" \
  make fm FM_MODE="$MODE" GOLDEN_RTL="$GOLDEN" XSSV_HOME="$STG/frozen" "${EXTRA[@]}" ) > "$STG/make.out" 2>&1
MAKE_RC=$?
cp "$D/fm_work/$TARGET/fm.log" "$STG/fm_log.txt" 2>/dev/null
if [ ! -f "$STG/fm_shell.rc" ]; then
  echo "SESSION_RESULT $SESSION: INFRA_FAIL no_fm_shell_rc(make_rc=$MAKE_RC)" | tee "$STG/RESULT.txt"
  finalize 3
fi
RC=$(cat "$STG/fm_shell.rc")

if [ ! -f "$STG/native_facts.json" ]; then
  {
    echo "SESSION_RESULT $SESSION: NO_NATIVE_FACTS rc=$RC (emitter拒产=fail-closed, runner rc=5)"
    grep -aE "SIDECAR_ERROR|FM_MODE_ERROR" "$STG/fm_log.txt" 2>/dev/null
  } | tee "$STG/RESULT.txt"
  finalize 5
fi

# --- closure digests(script 侧 = 执行时刻字节快照) ---
if [ ! -f "$STG/script_closure.list" ]; then
  echo "SESSION_RESULT $SESSION: INFRA_FAIL no_script_closure_list" | tee "$STG/RESULT.txt"
  finalize 3
fi
SNAPS=(); CLOSURE_BAD=0
while IFS=$'\t' read -r orig snap hash; do
  [ -z "$snap" ] && continue
  # 五审: runner 复算快照实际字节 sha256, 必须 == emitter 台账记录的 hash(执行时刻)
  actual=$(sha256sum "$STG/$snap" 2>/dev/null | cut -d' ' -f1)
  [ "$actual" = "$hash" ] || { echo "  CLOSURE_HASH_MISMATCH $snap: $actual != $hash"; CLOSURE_BAD=1; }
  SNAPS+=("$STG/$snap")
done < "$STG/script_closure.list"
if [ "$CLOSURE_BAD" != "0" ]; then
  echo "SESSION_RESULT $SESSION: INFRA_FAIL closure_hash_mismatch" | tee -a "$STG/RESULT.txt"
  finalize 3
fi
SCRIPT_DIG=$(python3 "$SC/fm_closure_digest.py" --mode concat "${SNAPS[@]}")
PIN_SNAPS=("${SNAPS[@]:2}")
if [ ${#PIN_SNAPS[@]} -gt 0 ]; then
  PINS_SHA=$(python3 "$SC/fm_closure_digest.py" --mode concat "${PIN_SNAPS[@]}")
else
  PINS_SHA=""
fi
REF_SRCS=$(extract_var FM_REF_SRCS); IMPL_SRCS=$(extract_var FM_IMPL_SRCS)
MERGE=$(echo "$CMD" | grep -o "FM_MERGE_DUP=[^ ]*" | head -1 | cut -d= -f2); MERGE=${MERGE:-true}
FMAP=$(echo "$CMD" | grep -o "FM_FIELD_MAP=[^ ]*" | head -1 | cut -d= -f2)
FMAP_SHA=""; [ -n "$FMAP" ] && FMAP_SHA=$(sha256sum "$FMAP" | cut -d' ' -f1)
SEM=(--semantic "DEFINE=SYNTHESIS" --semantic "INCDIR=" --semantic "MERGE_DUP=$MERGE" \
     --semantic "FIELD_MAP_SHA=$FMAP_SHA" --semantic "PINS_SHA=$PINS_SHA" --semantic "MODE=$MODE")
REF_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$GOLDEN" "${SEM[@]}" $REF_SRCS)
IMPL_DIG=$(cd "$D" && python3 "$SC/fm_closure_digest.py" --mode files --root "$WT" "${SEM[@]}" $IMPL_SRCS)
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
  echo "impl_commit: $IMPL_COMMIT"
} | tee "$STG/RESULT.txt"
finalize "$VRC"
