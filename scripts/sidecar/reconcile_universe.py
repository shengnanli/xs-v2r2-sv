#!/usr/bin/env python3
"""目标全集对账(审查要求 #1): 冻结清单 verif/freeze/fm_targets.tsv(305)
vs 当前 manifest。机器 diff 逐项; 任何缺失/新增必须有据可查。UNCONFIGURED(Rob)单列。
用法: reconcile_universe.py [manifest.json] [frozen.tsv]  → 打印 diff, 退出码=diff 条数。
"""
import json, sys

manifest = sys.argv[1] if len(sys.argv) > 1 else "scripts/sidecar/manifest_305.json"
frozen_tsv = sys.argv[2] if len(sys.argv) > 2 else "verif/freeze/fm_targets.tsv"

frozen = {}
for ln in open(frozen_tsv):
    p = ln.rstrip("\n").split("\t")
    if len(p) >= 4:
        frozen[(p[0], p[2])] = p[3]  # (module, variant) → kind

m = json.load(open(manifest))
cfg = {(e["ut_dir"], e["target"]) for e in m["entries"] if e["config_status"] == "CONFIGURED"}
unconf = [e["target"] for e in m["entries"] if e["config_status"] == "UNCONFIGURED"]

fk = set(frozen)
missing = sorted(fk - cfg)   # 冻结有、当前 CONFIGURED 无
added = sorted(cfg - fk)     # 当前有、冻结无

print(f"# 目标全集对账: 冻结={len(frozen)} 当前CONFIGURED={len(cfg)} UNCONFIGURED={len(unconf)}{unconf}")
print(f"# 缺失(冻结有当前无)={len(missing)}  新增(当前有冻结无)={len(added)}")
for k in missing:
    print(f"MISSING\t{k[0]}\t{k[1]}\t(冻结 kind={frozen[k]})")
for k in added:
    print(f"ADDED\t{k[0]}\t{k[1]}")
n = len(missing) + len(added)
print(f"RECONCILE_DIFF={n}")
sys.exit(0 if n == 0 else 1)
