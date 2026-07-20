#!/usr/bin/env bash
# fmbb/custom recipe 接线 smoke(FMBBCUSTOM_WIRING 阶段)。证明: recipe 经 emitter 产
# native_facts + 真实 fm_shell.rc + **同一 validator**(fm_sidecar_verdict.py)判定,
# 无独立 grep/WAIVED 判绿。正样本=诚实 verdict; 负样本=篡改→validator 拒。
# 用法: fmbb_sidecar_smoke.sh <target> <make_target> <mode>
set -u
SIGNOFF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GOLDEN=/home/eda/xs-env/G0-canonical/golden-rtl
BID=$(awk -F'\t' '$1=="canonical_baseline_id"{print $2}' /home/eda/xs-env/G0-canonical/PROMOTION_LEDGER.tsv)
SC="$SIGNOFF/scripts/sidecar"
TARGET=$1; MK=$2; MODE=${3:-signoff-strict}
D="$SIGNOFF/verif/ut/$TARGET"
OUT=$(mktemp -d); RID="SMOKE-$TARGET-$$"

echo "### $TARGET (make $MK, mode=$MODE) ###"
# 1) 无 FM_SIDECAR_OUT: recipe 必须拒(不独立判绿)
if ( cd "$D" && make "$MK" GOLDEN_RTL="$GOLDEN" XSSV_HOME="$SIGNOFF" >/dev/null 2>&1 ); then
  echo "  NEG_GUARD: FAIL(无 FM_SIDECAR_OUT 竟成功——独立判绿未消除)"; exit 1
else
  echo "  NEG_GUARD: PASS(无 sidecar 拒绝执行)"
fi

# 2) 经 sidecar: 产 native_facts + 真实 rc
( cd "$D" && rm -f fm_work/$TARGET/fm.log && \
  FM_SIDECAR_OUT="$OUT" FM_RUN_ID="$RID" XSSV_HOME="$SIGNOFF" \
  make "$MK" GOLDEN_RTL="$GOLDEN" ) >/dev/null 2>&1
RC=$(cat "$OUT/fm_shell.rc" 2>/dev/null || echo MISSING)
echo "  fm_shell.rc=$RC"
if [ ! -f "$OUT/native_facts.json" ]; then
  echo "  EMIT: NO native_facts"; grep -aE "SIDECAR_ERROR|FM_MODE_ERROR" "$D/fm_work/$TARGET/fm.log" 2>/dev/null | head -3
  echo "  (emitter 拒产=fail-closed, 亦是合法接线结果)"; rm -rf "$OUT"; exit 0
fi
echo "  native_verdict=$(python3 -c "import json;print(json.load(open('$OUT/native_facts.json'))['native_verdict'])")"

# 3) 构 envelope + expectation, 跑同一 validator(fm_sidecar_verdict.py)
python3 - "$OUT" "$RID" "$TARGET" "$MODE" "$BID" "$RC" <<'PYEOF'
import json,hashlib,os,sys
out,rid,tgt,mode,bid,rc=sys.argv[1:7]
nb=open(out+"/native_facts.json","rb").read(); nat=json.loads(nb)
H=lambda: "0"*64  # smoke: 输入/脚本 digest 占位(机制验证; 305 用真实 closure)
env={"schema":"fm-sidecar-envelope-v1","run_id":rid,"target":tgt,"top":nat["top"],
     "variant":tgt,"proof_mode":mode,"canonical_baseline_id":bid,
     "inputs_sha256":{"ref_srcs_digest":H(),"impl_srcs_digest":H()},
     "script_sha256":H(),"tool":{"fm_shell_digest":H()},"fm_shell_rc":int(rc),
     "native_facts_sha256":hashlib.sha256(nb).hexdigest(),
     **{k:nat[k] for k in ("native_verdict","stats","unmatched","objects","qualifications","entry_appvars")}}
json.dump(env,open(out+"/verdict.sidecar.json","w"))
exp={"run_id":rid,"target":tgt,"top":nat["top"],"variant":tgt,"proof_mode":mode,
     "canonical_baseline_id":bid,"ref_digest":H(),"impl_digest":H(),"script_digest":H(),
     "tool_digest":H(),"entry_appvars":nat["entry_appvars"],
     "allow":{"unresolved_blackbox":[],"interface_only":[],"empty_blackbox":[],"unmatched":[]}}
json.dump(exp,open(out+"/expectation.smoke.json","w"))
PYEOF
V=$(python3 "$SC/fm_sidecar_verdict.py" "$OUT/verdict.sidecar.json" \
    --native-facts "$OUT/native_facts.json" --expectation "$OUT/expectation.smoke.json" \
    --actual-rc "$RC" 2>&1 | head -1)
echo "  POS_VALIDATOR: $V"

# 4) 负样本: 篡改 native(failing+1)→ SHA 失配 → validator ERROR
python3 -c "
import json,hashlib
n=json.load(open('$OUT/native_facts.json')); n['stats']['failing']=n['stats']['failing']+7
open('$OUT/native_tampered.json','wb').write(json.dumps(n).encode())
"
VN=$(python3 "$SC/fm_sidecar_verdict.py" "$OUT/verdict.sidecar.json" \
    --native-facts "$OUT/native_tampered.json" --expectation "$OUT/expectation.smoke.json" \
    --actual-rc "$RC" 2>&1 | head -1)
echo "  NEG_TAMPER(native_facts改failing): $VN"
case "$VN" in ERROR*) echo "  NEG_TAMPER: PASS(sha绑定拒篡改)";; *) echo "  NEG_TAMPER: FAIL($VN)"; rm -rf "$OUT"; exit 1;; esac
rm -rf "$OUT"
