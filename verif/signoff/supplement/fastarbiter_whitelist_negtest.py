#!/usr/bin/env python3
# codex 0136 supplement 负测: vmucp 白名单必须精确匹配, 近似子串/未知目标 fail-closed。
# 可复跑: python3 verif/signoff/supplement/fastarbiter_whitelist_negtest.py ; exit 0=全过
import re, sys, os
R=os.path.join(os.path.dirname(__file__),'../../..')
line=[l for l in open(f'{R}/scripts/sidecar/run_signoff_target.sh') if l.strip().startswith('case "$TARGET" in')][0]
pats=set(re.findall(r'[A-Za-z0-9_]+', line))-{'case','TARGET','in'}
src=open(f'{R}/scripts/sidecar/fm_sidecar_verdict.py').read()
mu=set(x.strip().strip('"') for x in re.search(r'_MU_STRENGTHEN = \{([^}]*)\}', src).group(1).split(','))
NEG=['FastArbiter_45','FastArbiter_40','FastArbiter','FastArbiter_4X','astArbiter_4','FastArbiter_444']
POS=['FastArbiter_4','FastArbiter_5','FastArbiter_7','FastArbiter_8']
ok=all(n not in pats and n not in mu for n in NEG) and all(p in pats and p in mu for p in POS)
print('NEGTEST', 'PASS' if ok else 'FAIL'); sys.exit(0 if ok else 1)
