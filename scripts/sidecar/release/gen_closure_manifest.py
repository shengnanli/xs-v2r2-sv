#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# gen_closure_manifest.py — RC3→supplement 机器可复算 closure manifest (codex 0137 §3)
# 逐文件列 path/rc3_blob_sha/supplement_blob_sha/disposition, 并断言:
#   (1) changed 集精确 == 已批准 4 tool/test 文件;
#   (2) 设计输入 closure 零变化: rtl/ golden 引用(verif/ut/*/Makefile) verif/signoff/{allow,dead_ref}/
#       fm_pins* scripts/sidecar/manifest_*.{json,tsv} scripts/fm_eq.tcl combined_ledger 等全 unchanged。
# 用法: gen_closure_manifest.py <repo> <rc3_sha> <sup_sha> <out.tsv>; exit 0=全部断言过
import subprocess, sys, hashlib
repo, rc3, sup, out = sys.argv[1:5]
APPROVED = {
    "scripts/sidecar/run_signoff_target.sh",
    "scripts/sidecar/fm_sidecar_verdict.py",
    "scripts/sidecar/gen_305_manifest.py",
    "verif/signoff/supplement/fastarbiter_whitelist_negtest.py",
}
DESIGN_CLOSURE_PREFIX = ("rtl/", "verif/ut/", "verif/signoff/allow/", "verif/signoff/dead_ref/",
                         "verif/freeze/", "golden/")
DESIGN_CLOSURE_EXACT = ("scripts/fm_eq.tcl", "scripts/sidecar/manifest_305.json",
                        "scripts/sidecar/manifest_306_v2.json", "scripts/sidecar/manifest_aux.json",
                        "scripts/sidecar/manifest_declarations.tsv",
                        "scripts/sidecar/manifest_declarations_aux.tsv",
                        "scripts/sidecar/combined_ledger.tsv")
def run(*a):
    p = subprocess.run(a, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise SystemExit("git failed: %s: %s" % (a, p.stderr.decode()[:200]))
    return p.stdout.decode()
def tree(commit):
    # path -> sha256(blob bytes) — 与 verify_release_archive.git_blob_sha256 同约定
    d = {}
    paths = [l.split("\t", 1)[1] for l in run("git", "-C", repo, "ls-tree", "-r", commit).splitlines()]
    for path in paths:
        b = subprocess.run(["git", "-C", repo, "show", "%s:%s" % (commit, path)],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if b.returncode == 0:
            d[path] = hashlib.sha256(b.stdout).hexdigest()
    return d
t3, ts = tree(rc3), tree(sup)
changed = sorted(set(p for p in set(t3) | set(ts) if t3.get(p) != ts.get(p)))
assert set(changed) == APPROVED, "changed set != approved: %s" % changed
viol = [p for p in set(t3) | set(ts)
        if (p.startswith(DESIGN_CLOSURE_PREFIX) or p in DESIGN_CLOSURE_EXACT)
        and t3.get(p) != ts.get(p)]
assert not viol, "design closure violated: %s" % viol
rows = ["# closure-manifest-v1(sha256-of-blob-bytes)\trc3=%s\tsupplement=%s" % (rc3, sup),
        "# changed set asserted == approved 4 tool/test files; design-input closure asserted zero-change",
        "# path\trc3_sha256\tsupplement_sha256\tdisposition"]
for p in changed:
    rows.append("%s\t%s\t%s\t%s" % (p, t3.get(p, "-"), ts.get(p, "-"),
                                    "added" if p not in t3 else "modified"))
# 抽样记录 20 个 unchanged 设计输入文件供独立复算锚点(排序取前 20 深路径)
sample = sorted(p for p in t3 if (p.startswith(DESIGN_CLOSURE_PREFIX) or p in DESIGN_CLOSURE_EXACT)
                and t3.get(p) == ts.get(p))[:20]
for p in sample:
    rows.append("%s\t%s\t%s\tunchanged-sample" % (p, t3[p], ts[p]))
open(out, "w").write("\n".join(rows) + "\n")
print("CLOSURE_MANIFEST_OK changed=%d sample=%d -> %s" % (len(changed), len(sample), out))
