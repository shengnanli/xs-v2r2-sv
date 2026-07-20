#!/usr/bin/env bash
# manifest 驱动的通用 305 runner(MANIFEST_RUNNER_PREP)。
# manifest 条目是 proof_mode/allow/required_verdict 的唯一权威; 本 runner 只**测量** actual
# 并断言 actual==required_verdict, 绝不反向把失败配成通过。
# 泛化点(相对 Step-3B 专用 fm_sidecar_run.sh):
#   - 识别并冻结正确入口: scripts/fm_eq.tcl(generic) 或 verif/ut/<M>/fm_eq_bb.tcl(fmbb)。
#   - 运行正确 make target(fm-<v> / fmbb / fm)。
#   - proof_mode/allow 来自 manifest(FM_MODE 注入 + 未来 allow 文件); required_verdict 断言。
#   - timeout: fm_shell 超时(rc=124/无 native)→ 分类 TIMEOUT。
# 用法: run_manifest_target.sh <manifest.json> <target> [timeout_sec] [--smoke]
#   默认(signoff): 断言 measured == required_verdict(派生 SUCCEEDED/SHADOW_CHECK)。
#   --smoke: 断言 measured == smoke_expected.tsv 的 expected_observation(仅验 runner 机械)。
# UNCONFIGURED 目标: 不运行、不计通过(退出码 4)。
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
SC="$SIGNOFF/scripts/sidecar"
MANIFEST=$1; TARGET=$2; TMO=${3:-1200}; MMODE=${4:-signoff}

# 取 manifest 条目(tab 分隔, 防空字段列错位)
IFS=$'\t' read -r UTDIR MK MT ENTRY PMODE REQV CFG <<<"$(python3 - "$MANIFEST" "$TARGET" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for e in m["entries"]:
    if e["target"]==sys.argv[2]:
        print("\t".join([e["ut_dir"],e["makefile"] or "-",e["make_target"],e["entry"],
                         e["proof_mode"],e["required_verdict"],e["config_status"]])); break
else:
    print("NOTFOUND")
PY
)"
[ "$UTDIR" = "NOTFOUND" ] && { echo "MANIFEST_MISS $TARGET"; exit 2; }
if [ "$CFG" = "UNCONFIGURED" ]; then
  echo "TARGET $TARGET: UNCONFIGURED(有UT无FM配置) —— 不运行、不计通过"; exit 4
fi
# smoke 模式: 取 expected_observation
EXP="$REQV"
if [ "$MMODE" = "--smoke" ]; then
  EXP=$(awk -F'\t' -v t="$TARGET" '!/^#/ && $1==t{print $2}' "$SC/smoke_expected.tsv")
  [ -z "$EXP" ] && { echo "SMOKE_NO_EXPECTED $TARGET"; exit 2; }
fi
BID=$(python3 -c "import json;print(json.load(open('$MANIFEST'))['canonical_baseline_id'])")
D="$SIGNOFF/verif/ut/$UTDIR"
OUT=$(mktemp -d); RID="M305-$TARGET-$$"

# make 变量: generic 传 FM_MODE(assembly/shadow 由 manifest 决定); fmbb/custom 入口已固定 mode
MK_ARGS=(GOLDEN_RTL="$GOLDEN" XSSV_HOME="$SIGNOFF")
case "$MT" in
  fm-*) MK_ARGS+=(FM_MODE="$PMODE") ;;
esac

( cd "$D" && rm -f "fm_work/$TARGET/fm.log" "$OUT/fm_shell.rc" && \
  FM_SIDECAR_OUT="$OUT" FM_RUN_ID="$RID" \
  timeout "$TMO" make "$MT" "${MK_ARGS[@]}" ) >"$OUT/make.out" 2>&1
MAKE_RC=$?
RC=$(cat "$OUT/fm_shell.rc" 2>/dev/null || echo "NA")

if [ ! -f "$OUT/native_facts.json" ]; then
  # 无 native: 超时 / emitter 拒产 / 基建
  if [ "$MAKE_RC" = "124" ] || [ "$RC" = "124" ]; then CLS=TIMEOUT
  else CLS=NO_NATIVE_FACTS; fi
  ACT="$CLS"
  echo "TARGET $TARGET: measured=$ACT expected=$EXP (mode=$MMODE required_verdict=$REQV make_rc=$MAKE_RC fm_shell_rc=$RC)"
  grep -aE "SIDECAR_ERROR|FM_MODE_ERROR" "$D/fm_work/$TARGET/fm.log" 2>/dev/null | head -2
else
  # envelope + expectation(mode/allow 来自 manifest; smoke: 输入/脚本 digest 占位)
  python3 - "$OUT" "$RID" "$TARGET" "$PMODE" "$BID" "$RC" <<'PYEOF'
import json,hashlib,os,sys
out,rid,tgt,mode,bid,rc=sys.argv[1:7]
nb=open(out+"/native_facts.json","rb").read(); nat=json.loads(nb); H=lambda:"0"*64
env={"schema":"fm-sidecar-envelope-v1","run_id":rid,"target":tgt,"top":nat["top"],
 "variant":tgt,"proof_mode":mode,"canonical_baseline_id":bid,
 "inputs_sha256":{"ref_srcs_digest":H(),"impl_srcs_digest":H()},"script_sha256":H(),
 "tool":{"fm_shell_digest":H()},"fm_shell_rc":int(rc) if rc.lstrip('-').isdigit() else 0,
 "native_facts_sha256":hashlib.sha256(nb).hexdigest(),
 **{k:nat[k] for k in ("native_verdict","stats","unmatched","objects","qualifications","entry_appvars")}}
json.dump(env,open(out+"/verdict.sidecar.json","w"))
exp={"run_id":rid,"target":tgt,"top":nat["top"],"variant":tgt,"proof_mode":mode,
 "canonical_baseline_id":bid,"ref_digest":H(),"impl_digest":H(),"script_digest":H(),
 "tool_digest":H(),"entry_appvars":nat["entry_appvars"],
 "allow":{"unresolved_blackbox":[],"interface_only":[],"empty_blackbox":[],"unmatched":[]}}
json.dump(exp,open(out+"/expectation.smoke.json","w"))
PYEOF
  ACT=$(python3 "$SC/fm_sidecar_verdict.py" "$OUT/verdict.sidecar.json" \
      --native-facts "$OUT/native_facts.json" --expectation "$OUT/expectation.smoke.json" \
      --actual-rc "$RC" 2>&1 | head -1 | cut -f1)
  echo "TARGET $TARGET: measured=$ACT expected=$EXP (mode=$MMODE required_verdict=$REQV proof=$PMODE fm_shell_rc=$RC)"
fi

rm -rf "$OUT"
# 断言: measured == expected(signoff: expected=required_verdict; smoke: expected_observation)
if [ "$ACT" = "$EXP" ]; then
  echo "  [MATCH]"; exit 0
else
  # signoff 下 measured!=required 是**签核 gap**(诚实不绿), 非 runner 错
  echo "  [MISMATCH: expected=$EXP measured=$ACT]"; exit 1
fi
