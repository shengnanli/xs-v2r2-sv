#!/usr/bin/env python3
"""生成 canonical-bound 305 manifest(MANIFEST_RUNNER_PREP)。

原则(审查三条铁律):
 - manifest 是 proof_mode / 对象 allowlist / required_verdict 的**唯一权威**。
 - **不把当前失败配置成通过**: required_verdict 默认 "UNVERIFIED"(未声明=不算签核范围,
   非绿); 声明值只能来自 declarations 文件(设计边界), 不从本次运行日志反向生成。
 - proof_mode 由 Makefile 结构信号机械判定; 不为掩盖失败而切换。

机械字段(自 Makefile 枚举): target/ut_dir/makefile/make_target/entry/proof_mode。
声明字段(declarations.tsv, 缺省 UNVERIFIED/空 allow): required_verdict/allow_ref。
"""
import argparse, json, os, re, glob, subprocess

BID_LEDGER = "/home/eda/xs-env/G0-canonical/PROMOTION_LEDGER.tsv"

# 结构信号 → proof_mode(interface_only=assembly; fmbb 自带; shadow 人工声明)
ASSEMBLY_DIRS = {"Backend", "Ftq", "L2TLB", "LsqWrapper", "NewIFU", "OpenLLC", "TL2CHICoupledL2"}
FMBB = {"DCache": "fmbb", "DCacheWrapper": "fmbb", "L2TLBWrapper": "fmbb",
        "MemBlock": "fmbb", "NewCSR": "fmbb", "PtwCache": "fm"}
SHADOW_DIRS = {"Predictor", "Frontend"}


def canonical_bid():
    for ln in open(BID_LEDGER):
        p = ln.rstrip("\n").split("\t")
        if len(p) == 2 and p[0] == "canonical_baseline_id":
            return p[1]
    raise SystemExit("no canonical_baseline_id")


def load_declarations(path):
    """target<TAB>proof_mode<TAB>required_verdict<TAB>allow_ref<TAB>rationale"""
    decl = {}
    if not path or not os.path.isfile(path):
        return decl
    for ln in open(path, encoding="utf-8"):
        ln = ln.rstrip("\n")
        if not ln or ln.startswith("#"):
            continue
        p = ln.split("\t")
        if len(p) < 3:
            continue
        decl[p[0]] = {"proof_mode": p[1] or None, "required_verdict": p[2],
                      "allow_ref": p[3] if len(p) > 3 else "",
                      "rationale": p[4] if len(p) > 4 else ""}
    return decl


def variants_of(makefile):
    # 处理反斜杠续行的多行 FM_VARIANTS(SRAM/Pipeline 变体表)
    txt = open(makefile).read()
    txt = re.sub(r"\\\n", " ", txt)  # 折叠续行
    m = re.search(r"^FM_VARIANTS\s*[:+]?=\s*(.+)$", txt, re.M)
    if not m:
        return []
    # 去掉行内注释
    val = m.group(1).split("#")[0]
    return val.split()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ut-root", default="verif/ut")
    ap.add_argument("--declarations", default="scripts/sidecar/manifest_declarations.tsv")
    ap.add_argument("--out", default="scripts/sidecar/manifest_305.json")
    a = ap.parse_args()
    bid = canonical_bid()
    decl = load_declarations(a.declarations)
    entries = []
    seen = set()

    for mk in sorted(glob.glob(os.path.join(a.ut_root, "*", "Makefile")) +
                     glob.glob(os.path.join(a.ut_root, "*", "Makefile.*"))):
        ut_dir = os.path.basename(os.path.dirname(mk))
        # fmbb/custom: 单目标(entry=fm_eq_bb.tcl 或 fm_eq.tcl)
        if ut_dir in FMBB and mk.endswith("Makefile"):
            mt = FMBB[ut_dir]
            entry = ("verif/ut/%s/fm_eq_bb.tcl" % ut_dir) if mt == "fmbb" else "scripts/fm_eq.tcl"
            pm = "assembly" if mt == "fmbb" else "signoff-strict"
            tgt = ut_dir
            key = (ut_dir, tgt, mt)
            if key in seen:
                continue
            seen.add(key)
            d = decl.get(tgt, {})
            entries.append({
                "target": tgt, "ut_dir": ut_dir, "makefile": os.path.relpath(mk),
                "make_target": mt, "entry": entry,
                "proof_mode": d.get("proof_mode") or pm,
                "required_verdict": d.get("required_verdict", "UNVERIFIED"),
                "allow_ref": d.get("allow_ref", ""),
                "rationale": d.get("rationale", ""),
                "canonical_baseline_id": bid})
            continue
        # generic fm-%: 每 variant 一条
        for v in variants_of(mk):
            key = (ut_dir, v, "fm-%s" % v)
            if key in seen:
                continue
            seen.add(key)
            if ut_dir in ASSEMBLY_DIRS:
                pm = "assembly"
            elif ut_dir in SHADOW_DIRS:
                pm = "shadow"
            else:
                pm = "signoff-strict"
            d = decl.get(v, {})
            entries.append({
                "target": v, "ut_dir": ut_dir, "makefile": os.path.relpath(mk),
                "make_target": "fm-%s" % v, "entry": "scripts/fm_eq.tcl",
                "proof_mode": d.get("proof_mode") or pm,
                "required_verdict": d.get("required_verdict", "UNVERIFIED"),
                "allow_ref": d.get("allow_ref", ""),
                "rationale": d.get("rationale", ""),
                "canonical_baseline_id": bid})

    entries.sort(key=lambda e: (e["ut_dir"], e["target"], e["make_target"]))
    manifest = {"schema": "fm-305-manifest-v1", "canonical_baseline_id": bid,
                "count": len(entries), "entries": entries}
    with open(a.out, "w") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    # 摘要
    from collections import Counter
    by_mode = Counter(e["proof_mode"] for e in entries)
    by_verdict = Counter(e["required_verdict"] for e in entries)
    print(f"entries={len(entries)}  by_mode={dict(by_mode)}  by_declared_verdict={dict(by_verdict)}")


if __name__ == "__main__":
    main()
