#!/usr/bin/env bash
# 305 signoff sweep 编排器(305_SIGNOFF_SWEEP=GO)。冻结锚:
#   implementation_commit=566a851 / canonical G0 / manifest_sha256 固定 / 305 CONFIGURED+Rob。
# 执行纪律: sweep 期间不改 RTL/manifest/proof_mode/allowlist; 每目标独立证据 + 固定 timeout;
# no-clobber 续跑(已有证据跳过); FAILED/timeout/infra 不重试不自动升级。
# 五类终态(总数守恒: 305 configured 各且仅一个终态; Rob 单列不入分母):
#   SIGNOFF_PASS / SHADOW_CHECK / PROOF_GAP(PARTIAL,FAILED) / INFRA_TIMEOUT(TIMEOUT,
#   NO_NATIVE_FACTS,INFRA,ERROR) / UNCONFIGURED
# 用法: run_305_sweep.sh [timeout_sec]   (可反复调用续跑; Ctrl-C 安全, 已完成目标保留)
set -u
SC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIGNOFF="$(cd "$SC/../.." && pwd)"
M="$SC/manifest_305.json"
TMO=${1:-1200}
EXPECT_IMPL=566a8513bd816f3c12f18297b33fdcaf083f651c
LEDGER="$SC/sweep_ledger.tsv"
LOG="$SC/sweep_progress.log"

# 冻结锚硬校验
[ "$(git -C "$SIGNOFF" rev-parse HEAD)" = "$EXPECT_IMPL" ] || { echo "ANCHOR_FAIL: HEAD!=$EXPECT_IMPL"; exit 2; }
[ "$(git -C "$SIGNOFF" status --porcelain --untracked-files=no | wc -l)" = "0" ] || { echo "ANCHOR_FAIL: main dirty"; exit 2; }

classify() {  # gate/verdict → 五类
  case "$1" in
    SIGNOFF_PASS) echo SIGNOFF_PASS ;;
    SHADOW_CHECK) echo SHADOW_CHECK ;;
    PARTIAL|FAILED) echo PROOF_GAP ;;
    TIMEOUT|NO_NATIVE_FACTS|INFRA|ERROR|UNRUN) echo INFRA_TIMEOUT ;;
    UNCONFIGURED) echo UNCONFIGURED ;;
    *) echo INFRA_TIMEOUT ;;
  esac
}

# 目标全集(CONFIGURED + UNCONFIGURED)
mapfile -t TARGETS < <(python3 -c "
import json
for e in json.load(open('$M'))['entries']: print(e['target'],e['config_status'])")

echo "# 305 sweep 启动 $(date -u +%Y-%m-%dT%H:%M:%SZ) impl=$EXPECT_IMPL" >> "$LOG"
done_n=0; total=${#TARGETS[@]}
for line in "${TARGETS[@]}"; do
  set -- $line; TGT=$1; CFG=$2
  done_n=$((done_n+1))
  ED="$SC/signoff-evidence/$TGT"
  # no-clobber 续跑: 已有终态则跳过
  if [ -f "$ED/RESULT.txt" ] && [ -f "$ED/COMPLETE" ]; then
    continue
  fi
  if [ "$CFG" = "UNCONFIGURED" ]; then
    echo -e "$TGT\tUNCONFIGURED\tUNCONFIGURED\t-" >> "$LEDGER.tmp"
    continue
  fi
  rm -rf "$ED" "$ED.staging" 2>/dev/null
  bash "$SC/run_signoff_target.sh" "$M" "$TGT" "$TMO" >/dev/null 2>&1
  # 从证据读终态
  if [ -f "$ED/RESULT.txt" ]; then
    RL=$(grep -m1 "^SIGNOFF_RESULT\|^TARGET" "$ED/RESULT.txt")
    if echo "$RL" | grep -q "gate=PASS"; then
      MV=$(echo "$RL"|grep -o "measured=[A-Z_]*"|cut -d= -f2)
      [ "$MV" = "SHADOW_CHECK" ] && G=SHADOW_CHECK || G=SIGNOFF_PASS
    elif echo "$RL" | grep -q "gate=GAP"; then
      G=$(echo "$RL"|grep -o "measured=[A-Z_]*"|cut -d= -f2)  # PARTIAL/FAILED
    else
      G=$(echo "$RL"|grep -oE "TIMEOUT|NO_NATIVE_FACTS|INFRA[_A-Z]*"|head -1); G=${G:-ERROR}
    fi
  else
    G=ERROR
  fi
  CLS=$(classify "$G")
  echo -e "$TGT\t$G\t$CLS\t$(git -C "$SIGNOFF" rev-parse HEAD)" >> "$LEDGER.tmp"
  echo "[$done_n/$total] $TGT -> $G ($CLS)" >> "$LOG"
done

# 合并已跳过(既有证据)的目标终态 → 最终 ledger(每目标一行, 总数守恒)
python3 - "$M" "$SC/signoff-evidence" "$LEDGER" <<'PYEOF'
import json,os,sys,re
M,evroot,ledger=sys.argv[1:4]
ents=json.load(open(M))['entries']
def read_state(t,cfg):
    if cfg=="UNCONFIGURED": return ("UNCONFIGURED","UNCONFIGURED")
    rp=os.path.join(evroot,t,"RESULT.txt")
    if not os.path.isfile(rp): return ("MISSING","INFRA_TIMEOUT")
    txt=open(rp,encoding="utf-8",errors="replace").read()
    m=re.search(r"measured=(\S+)",txt)
    if "gate=PASS" in txt:
        return (m.group(1), "SHADOW_CHECK" if m.group(1)=="SHADOW_CHECK" else "SIGNOFF_PASS")
    if "gate=GAP" in txt:
        return (m.group(1), "PROOF_GAP")
    mm=re.search(r"(TIMEOUT|NO_NATIVE_FACTS|INFRA\w*)",txt)
    return (mm.group(1) if mm else "ERROR","INFRA_TIMEOUT")
rows=[]
for e in ents:
    v,c=read_state(e['target'],e['config_status'])
    rows.append((e['target'],e['config_status'],v,c))
rows.sort()
with open(ledger,"w") as f:
    f.write("target\tconfig_status\tmeasured\tclass\n")
    for r in rows: f.write("\t".join(r)+"\n")
# 守恒校验
from collections import Counter
cfg=[r for r in rows if r[1]=="CONFIGURED"]
unc=[r for r in rows if r[1]=="UNCONFIGURED"]
cls=Counter(r[3] for r in cfg)
print("=== 305 sweep 台账(总数守恒校验)===")
print(f"CONFIGURED={len(cfg)} (须305)  UNCONFIGURED={len(unc)}{[r[0] for r in unc]}")
s=0
for k in ("SIGNOFF_PASS","SHADOW_CHECK","PROOF_GAP","INFRA_TIMEOUT"):
    print(f"  {k}: {cls.get(k,0)}"); s+=cls.get(k,0)
print(f"  合计 configured 终态 = {s} (须==305: {'OK' if s==len(cfg)==305 else 'FAIL'})")
PYEOF
rm -f "$LEDGER.tmp"
echo "SWEEP_COMPLETE"
