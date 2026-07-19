#!/usr/bin/env python3
"""B2 证据独立验证器(七审防伪版)。证据必须自证完整且**不可伪造**。

七审修复:
 - 固定 required pathset(精确等于, 不多不少); os.scandir+lstat 拒 symlink/子目录/特殊文件。
 - --expected-commit 外部传入并精确匹配(40个零的假 provenance 不再通过)。
 - 交叉核对 b2_1860_result.json 实质字段(对 TRUST_ANCHORS):
     manifest_sha256 == 锚 g0_full_manifest; fir_replacements == 6,759,209;
     content_mismatch/missing/extra/mode_bad/special_files 全空;
     normalized_tree_digest == 锚 g0_full_manifest(normalized 复现冻结 manifest)。
   —— 只有真跑过 1860 checker 的结果才有这些自洽值, 手编 JSON 无法凑齐。
 - 供 runner 在 **rename 前**对 tmp 目录验证(失败不产出带 COMPLETE 的正式目录)。
用法: b2_verify_evidence.py <evidence-dir> --expected-commit <40hex>
"""
import sys, os, re, json, hashlib, stat, argparse

HERE = os.path.dirname(os.path.abspath(__file__))
REQUIRED = {"b2_regen.log", "b2_1860_result.json", "normalized.manifest.tsv", "provenance.txt"}
META = {"COMPLETE", "evidence.manifest.tsv"}
EXPECT_FIR = 6_759_209

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
    ap = argparse.ArgumentParser()
    ap.add_argument("evdir")
    ap.add_argument("--expected-commit", required=True)
    A = ap.parse_args()
    d = A.evdir
    if not re.fullmatch(r"[0-9a-f]{40}", A.expected_commit):
        fail("expected-commit 非 40hex")
    anc = dict(l.rstrip("\n").split("\t")[:2] for l in open(os.path.join(HERE, "TRUST_ANCHORS.tsv"))
               if not l.startswith("#") and not l.startswith("key\t"))

    # ① 目录全类型扫描: 只允许 REQUIRED+META 的常规文件, 拒 symlink/子目录/特殊/多余
    entries = {}
    for e in os.scandir(d):
        st = os.lstat(e.path)
        if not stat.S_ISREG(st.st_mode):
            fail(f"非常规条目: {e.name}(symlink/目录/特殊文件)")
        entries[e.name] = st
    if set(entries) != REQUIRED | META:
        fail(f"文件集不精确: 缺{sorted((REQUIRED|META)-set(entries))} 多{sorted(set(entries)-(REQUIRED|META))}")

    # ② COMPLETE 绑定 manifest
    mf = os.path.join(d, "evidence.manifest.tsv")
    m = re.fullmatch(r"B2_ATTEMPT_COMPLETE \d+ manifest_sha256=([0-9a-f]{64})\n?",
                     open(os.path.join(d, "COMPLETE")).read())
    if not m: fail("COMPLETE 格式不符")
    if m.group(1) != sha(mf): fail("COMPLETE 绑定的 manifest sha 不匹配")

    # ③ manifest 精确文件集 + 逐 hash
    rows = [l.rstrip("\n").split("\t") for l in open(mf) if l.strip() and not l.startswith("#")]
    want = {r[0]: (int(r[1]), r[2]) for r in rows}
    if set(want) != REQUIRED:
        fail(f"manifest 文件集 != required: {sorted(set(want) ^ REQUIRED)}")
    for f, (sz, h) in want.items():
        p = os.path.join(d, f)
        if os.path.getsize(p) != sz or sha(p) != h:
            fail(f"hash/size 不匹配: {f}")

    # ④ log: rc 门 + marker 门
    log = open(os.path.join(d, "b2_regen.log"), errors="ignore").read()
    if not re.search(r"^PHASE2-RC: 0\s*$", log, re.M): fail("无 PHASE2-RC: 0")
    if not re.search(r"^PHASE2-DONE\s*$", log, re.M): fail("无 PHASE2-DONE")

    # ⑤ 1860 result 实质交叉核对(手编 JSON 无法凑齐的自洽值)
    res = json.load(open(os.path.join(d, "b2_1860_result.json")))
    if res.get("result") != "CANONICAL_ARTIFACT_REPRODUCED": fail(f"result: {res.get('result')}")
    if res.get("manifest_sha256") != anc["g0_full_manifest"]: fail("result.manifest_sha256 ≠ 锚")
    if res.get("fir_replacements") != EXPECT_FIR: fail(f"fir_replacements ≠ {EXPECT_FIR}")
    for k in ("content_mismatch", "missing", "extra", "mode_bad", "special_files"):
        if res.get(k):
            fail(f"result.{k} 非空")
    if res.get("normalized_tree_digest") != anc["g0_full_manifest"]:
        fail("normalized_tree_digest ≠ 锚(normalized 必须复现冻结 manifest)")

    # ⑥ provenance: 外部期望 commit 精确匹配
    prov = open(os.path.join(d, "provenance.txt")).read()
    mm = re.search(r"^signoff_commit: ([0-9a-f]{40})\s*$", prov, re.M)
    if not mm: fail("provenance 无 signoff_commit")
    if mm.group(1) != A.expected_commit: fail(f"commit 不匹配期望: {mm.group(1)[:12]}")

    print("EVIDENCE-OK: 防伪契约全项通过")
    sys.exit(0)

if __name__ == "__main__":
    main()
