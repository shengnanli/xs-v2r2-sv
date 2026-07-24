#!/usr/bin/env python3
"""FM 全量盘点摘要生成器(冻结基线, 2026-07)。
读 verif/freeze/fm_sweep.tsv(全量 make fm 结果)+ 各模块 Makefile/fm_pins 的 FM setup,
按证明分类法(REPLACEMENT_EQ/ASSEMBLY_EQ/SHADOW_CHECK/PARTIAL_WAIVED/FAILED/UNRUN)
派生每个目标的类别, 产出机器可读 fm_ledger.tsv + 人读汇总。禁把 scoped/shadow 叫等价。
"""
import os, re, glob, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWEEP = os.path.join(ROOT, "verif/freeze/fm_sweep.tsv")
LEDGER = os.path.join(ROOT, "verif/freeze/fm_ledger.tsv")

# 硬编码 SHADOW(可读核不驱动输出, 见 wrapper golden-body 痕迹)
SHADOW = {"Frontend", "Predictor"}

def mk_flags(m):
    """从模块 Makefile / fm_pins 读 FM setup 信号。"""
    mk = os.path.join(ROOT, f"verif/ut/{m}/Makefile")
    f = {"iface": False, "fmbb": False, "dontverify": False, "pins": False}
    if os.path.exists(mk):
        t = open(mk, errors="ignore").read()
        f["iface"] = bool(re.search(r"^FM_INTERFACE_ONLY\s*=\s*\S", t, re.M))
        f["fmbb"]  = bool(re.search(r"^FM_BB_TARGET|^fmbb:", t, re.M))
    for pf in glob.glob(os.path.join(ROOT, f"verif/ut/{m}/fm_pins*.tcl")):
        pt = open(pf, errors="ignore").read()
        f["pins"] = True
        # 只算真实命令行(排除注释)含 dont_verify
        for ln in pt.splitlines():
            s = ln.strip()
            if s and not s.startswith("#") and "set_dont_verify" in s:
                f["dontverify"] = True
    return f

def classify(m, verdict, unver):
    if verdict in ("FAILED", "TIMEOUT", "ERROR"):
        return "FAILED"
    if verdict == "NO_FM_TARGET":
        return "UNRUN"
    if verdict == "WAIVED":
        return "PARTIAL_WAIVED"
    if m in SHADOW:
        return "SHADOW_CHECK"
    if verdict == "SUCCEEDED":
        fl = mk_flags(m)
        if fl["dontverify"]:
            return "PARTIAL_WAIVED"
        if fl["iface"] or fl["fmbb"]:
            return "ASSEMBLY_EQ"
        return "REPLACEMENT_EQ"
    return "UNKNOWN"

def main():
    if not os.path.exists(SWEEP):
        sys.exit(f"缺 {SWEEP}")
    rows = []
    for ln in open(SWEEP):
        p = ln.rstrip("\n").split("\t")
        if len(p) < 5 or p[0] in ("module", "") or p[0].startswith("FM_SWEEP_DONE"):
            continue
        m, verdict, failing, unver, sec = p[:5]
        cls = classify(m, verdict, unver)
        rows.append((m, cls, verdict, failing, unver, sec))
    rows.sort(key=lambda r: (r[1], r[0]))
    with open(LEDGER, "w") as o:
        o.write("module\tclass\tverdict\tfailing\tunverified\tseconds\n")
        for r in rows:
            o.write("\t".join(r) + "\n")
    # 人读汇总
    from collections import Counter
    byc = Counter(r[1] for r in rows)
    print(f"=== FM 全量盘点(冻结基线, {len(rows)} 目标)===")
    order = ["REPLACEMENT_EQ", "ASSEMBLY_EQ", "SHADOW_CHECK", "PARTIAL_WAIVED", "FAILED", "UNRUN", "UNKNOWN"]
    for c in order:
        if byc.get(c):
            print(f"  {c:16s} {byc[c]}")
    print(f"机器可读: {LEDGER}")
    # 非 REPLACEMENT/ASSEMBLY 的逐个列出(需关注)
    print("--- 非纯通过(需关注)---")
    for r in rows:
        if r[1] in ("SHADOW_CHECK", "PARTIAL_WAIVED", "FAILED", "UNRUN", "UNKNOWN"):
            print(f"  {r[0]:24s} {r[1]:16s} {r[2]} f={r[3]} u={r[4]}")

if __name__ == "__main__":
    main()
