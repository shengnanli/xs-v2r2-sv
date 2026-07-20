#!/usr/bin/env bash
# 305 sweep 并行驱动(P=6, 8核62G)。冻结锚硬校验; 生成 pending; xargs -P 并发 worker;
# 完成后聚合五类台账(总数守恒)。no-clobber 续跑安全。
set -u
SC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIGNOFF="$(cd "$SC/../.." && pwd)"
M="$SC/manifest_305.json"
P=${1:-6}; TMO=${2:-900}
EXPECT_IMPL=566a8513bd816f3c12f18297b33fdcaf083f651c

[ "$(git -C "$SIGNOFF" rev-parse HEAD)" = "$EXPECT_IMPL" ] || { echo "ANCHOR_FAIL HEAD"; exit 2; }
[ "$(git -C "$SIGNOFF" status --porcelain --untracked-files=no | wc -l)" = "0" ] || { echo "ANCHOR_FAIL dirty"; exit 2; }

python3 -c "
import json,os
ents=json.load(open('$M'))['entries']
for e in ents:
    if e['config_status']=='CONFIGURED' and not os.path.exists('$SC/signoff-evidence/'+e['target']+'/COMPLETE'):
        print(e['target'])
" > "$SC/.pending.txt"
NP=$(wc -l < "$SC/.pending.txt")
echo "# 并行 sweep P=$P TMO=$TMO pending=$NP $(date -u +%H:%M:%SZ)" >> "$SC/sweep_progress.log"
echo "pending=$NP, 并发 P=$P 启动..."

SWEEP_TMO=$TMO xargs -P"$P" -I{} bash "$SC/sweep_worker.sh" {} < "$SC/.pending.txt"

# 聚合五类台账(权威读证据 RESULT.txt; 总数守恒)
python3 - "$M" "$SC/signoff-evidence" "$SC/sweep_ledger.tsv" <<'PYEOF'
import json,os,sys,re
from collections import Counter
M,evroot,ledger=sys.argv[1:4]
ents=json.load(open(M))['entries']
def state(t,cfg):
    if cfg=="UNCONFIGURED": return ("UNCONFIGURED","UNCONFIGURED")
    rp=os.path.join(evroot,t,"RESULT.txt")
    if not os.path.isfile(rp): return ("MISSING","INFRA_TIMEOUT")
    txt=open(rp,encoding="utf-8",errors="replace").read()
    m=re.search(r"measured=(\S+)",txt); mv=m.group(1) if m else "?"
    if "gate=PASS" in txt: return (mv,"SHADOW_CHECK" if mv=="SHADOW_CHECK" else "SIGNOFF_PASS")
    if "gate=GAP" in txt: return (mv,"PROOF_GAP")
    mm=re.search(r"(TIMEOUT|NO_NATIVE_FACTS|INFRA\w*)",txt); return (mm.group(1) if mm else "ERROR","INFRA_TIMEOUT")
rows=sorted((e['target'],e['config_status'],*state(e['target'],e['config_status'])) for e in ents)
open(ledger,"w").write("target\tconfig_status\tmeasured\tclass\n"+"\n".join("\t".join(r) for r in rows)+"\n")
cfg=[r for r in rows if r[1]=="CONFIGURED"]; unc=[r for r in rows if r[1]=="UNCONFIGURED"]
cls=Counter(r[3] for r in cfg)
print("\n=== 305 SWEEP 五类台账(总数守恒)===")
print(f"CONFIGURED={len(cfg)}  UNCONFIGURED={len(unc)}{[r[0] for r in unc]}")
s=0
for k in ("SIGNOFF_PASS","SHADOW_CHECK","PROOF_GAP","INFRA_TIMEOUT"):
    print(f"  {k:16} {cls.get(k,0)}"); s+=cls.get(k,0)
print(f"  {'合计':16} {s}  守恒={'OK' if s==len(cfg)==305 else 'FAIL(%d)'%s}")
# INFRA/GAP 细分(供修复排序)
gapv=Counter(r[2] for r in cfg if r[3]=="PROOF_GAP")
infv=Counter(r[2] for r in cfg if r[3]=="INFRA_TIMEOUT")
print(f"  PROOF_GAP细分: {dict(gapv)}")
print(f"  INFRA_TIMEOUT细分: {dict(infv)}")
PYEOF
echo "SWEEP_COMPLETE"
