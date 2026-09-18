#!/usr/bin/env python3
"""
L2TLB 手写区覆盖闸：生成区声明的每一条 glue 输入网，手写区必须**恰好驱动一次**。

漏驱动 = 悬空 X（UT 里可能碰巧不暴露，FM 直接失配）；重复驱动 = 多驱动。
两种都在这里当场拦住，不必等 VCS。

用法: python3 scripts/check_l2tlb_driven.py
"""
import re, sys
from pathlib import Path

SV = Path(__file__).resolve().parent.parent / "rtl/memblock/L2TLB.sv"
text = SV.read_text()


def region(tag):
    m = re.search(re.escape(f"// BEGIN GENERATED({tag})") + r"(.*?)// END GENERATED",
                  text, re.S)
    return m.group(1) if m else ""


declared = set(re.findall(r"^\s*logic\s+(?:\[[^\]]*\]\s*)?(\w+);", region("driven"), re.M))

# 手写区 = 全文去掉所有生成区
hand = text
for t in ("ports", "wires", "driven", "inst", "wrapper", "cache_stage1",
          "merge_in2", "marb_out", "outarb_in", "perf_out"):
    hand = hand.replace(f"// BEGIN GENERATED({t})" + region(t) + "// END GENERATED", "")
# 生成区里 merge_in2 / outarb_in 也驱动 glue 网，算作已驱动
gen_driven = set()
for t in ("merge_in2", "outarb_in"):
    gen_driven |= set(re.findall(r"assign\s+(\w+)\s*=", region(t)))

hand_driven = re.findall(r"^\s*assign\s+(\w+)\s*=", hand, re.M)
# always_comb/always_ff 里的过程赋值目标
hand_driven += re.findall(r"^\s{4,}(\w+)\s*(?:<=|=)\s", hand, re.M)

counts = {}
for n in hand_driven:
    if n in declared:
        counts[n] = counts.get(n, 0) + 1
for n in gen_driven:
    counts[n] = counts.get(n, 0) + 1

missing = sorted(declared - set(counts))
dup = sorted(n for n, c in counts.items() if c > 1)
extra = sorted(n for n in set(re.findall(r"^\s*assign\s+(u_\w+__\w+)\s*=", hand, re.M))
               if n not in declared)

print(f"declared glue nets : {len(declared)}")
print(f"driven exactly once: {len(declared) - len(missing) - len(dup)}")
print(f"MISSING            : {len(missing)}")
print(f"DUPLICATE          : {len(dup)}")
print(f"ASSIGNED-BUT-UNDECLARED (打错名字): {len(extra)}")
for label, lst in (("MISSING", missing), ("DUPLICATE", dup), ("UNDECLARED", extra)):
    if lst:
        print(f"\n--- {label} ---")
        for n in lst[:80]:
            print("  " + n)
        if len(lst) > 80:
            print(f"  ... 共 {len(lst)} 条")
sys.exit(1 if (missing or dup or extra) else 0)
