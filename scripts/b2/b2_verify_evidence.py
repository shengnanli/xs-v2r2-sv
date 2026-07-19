#!/usr/bin/env python3
"""B2 证据独立验证器(六审)。让证据**自证完整**:任何缺失/篡改/假成功都拒绝。

证据契约(b2_evidence/ 必须同时满足):
 1. COMPLETE 存在, 格式 "B2_ATTEMPT_COMPLETE <epoch> manifest_sha256=<64hex>",
    其 sha 必须等于 evidence.manifest.tsv 的实际 sha256(COMPLETE 绑定 manifest)。
 2. evidence.manifest.tsv 列出精确文件集(path/size/sha256);目录内实际常规文件集
    (除 COMPLETE 与 manifest 自身)必须与之完全一致(缺/多都拒), 逐文件 hash 必须匹配。
 3. b2_regen.log 必须含 "PHASE2-RC: 0" 且含 "PHASE2-DONE" 行(rc 与 marker 同时要求——
    只有 marker 而 rc!=0 是注入攻击, 拒绝)。
 4. b2_1860_result.json 的 result 必须 == "CANONICAL_ARTIFACT_REPRODUCED"。
 5. provenance.txt 必须含 signoff_commit: <40hex>。
用法: b2_verify_evidence.py <evidence-dir>   通过=rc0, 任何违反=rc1。
"""
import sys, os, re, json, hashlib

def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()

def fail(msg):
    print(f"EVIDENCE-REJECT: {msg}")
    sys.exit(1)

def main():
    d = sys.argv[1]
    comp = os.path.join(d, "COMPLETE")
    mf = os.path.join(d, "evidence.manifest.tsv")
    if not os.path.isfile(comp): fail("缺 COMPLETE")
    if not os.path.isfile(mf): fail("缺 evidence.manifest.tsv")
    m = re.match(r"^B2_ATTEMPT_COMPLETE \d+ manifest_sha256=([0-9a-f]{64})\s*$",
                 open(comp).read())
    if not m: fail("COMPLETE 格式不符(须绑定 manifest_sha256)")
    if m.group(1) != sha(mf): fail("COMPLETE 绑定的 manifest sha 不匹配(manifest 被改/证据不完整)")
    rows = [l.rstrip("\n").split("\t") for l in open(mf) if l.strip() and not l.startswith("#")]
    want = {r[0]: (int(r[1]), r[2]) for r in rows}
    have = {f for f in os.listdir(d)
            if os.path.isfile(os.path.join(d, f)) and f not in ("COMPLETE", "evidence.manifest.tsv")}
    if set(want) != have:
        fail(f"文件集不一致: 缺{sorted(set(want)-have)} 多{sorted(have-set(want))}")
    for f, (sz, h) in want.items():
        p = os.path.join(d, f)
        if os.path.getsize(p) != sz or sha(p) != h:
            fail(f"hash/size 不匹配: {f}")
    log = open(os.path.join(d, "b2_regen.log"), errors="ignore").read()
    if not re.search(r"^PHASE2-RC: 0\s*$", log, re.M): fail("log 无 PHASE2-RC: 0(rc 门)")
    if not re.search(r"^PHASE2-DONE\s*$", log, re.M): fail("log 无 PHASE2-DONE(marker 门)")
    res = json.load(open(os.path.join(d, "b2_1860_result.json")))
    if res.get("result") != "CANONICAL_ARTIFACT_REPRODUCED":
        fail(f"1860 result 非 canonical: {res.get('result')}")
    prov = open(os.path.join(d, "provenance.txt")).read()
    if not re.search(r"^signoff_commit: [0-9a-f]{40}\s*$", prov, re.M):
        fail("provenance 无有效 signoff_commit")
    print("EVIDENCE-OK: 契约全项通过")
    sys.exit(0)

if __name__ == "__main__":
    main()
