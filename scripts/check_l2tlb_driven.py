#!/usr/bin/env python3
"""
L2TLB 驱动闸，两条判据：

A. 生成区声明的每一条 glue 输入网（598 条），手写区必须**恰好驱动一次**。
B. ★核自己的 152 个输出端口，也必须恰好被驱动一次。★

漏驱动 = 悬空 X（UT 里可能碰巧不暴露，FM 直接失配）；重复驱动 = 多驱动。

★判据 B 是 2026-09-20 补的，补之前这个闸是半张网★
落地那一版 A 报 598/598 全绿、提交信息写着"598 条 glue 全覆盖"，而 152 个核输出里
**103 个根本没人驱动**（整个 io_tlb_{0,1}_resp_bits_* 响应负载 + 3 条 difftest 探针）。
A 只看"子模块的输入有没有被喂到"，顺着这个方向再怎么绿也照不到"核自己的输出"。
UT 一跑，impl 侧整片 `z`，errors=20,600,000。
教训不是"漏写了代码"，是**闸只覆盖了一个方向，而覆盖率报告长得像全覆盖**。

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

# ---------------------------------------------------------------------------
# 判据 B：核输出端口必须恰好驱动一次
# ---------------------------------------------------------------------------
core = text[text.index("module xs_L2TLB_core"):text.index("\nendmodule", text.index("module xs_L2TLB_core"))]
core_ports = re.search(r"// BEGIN GENERATED\(ports\)(.*?)// END GENERATED", core, re.S).group(1)
core_outs = set(re.findall(r"^\s*output\s+(?:\[[^\]]*\]\s*)?(\w+),?\s*$", core_ports, re.M))
core_body = core[core.index("// END GENERATED"):]
out_counts = {}
for n in (re.findall(r"^\s*assign\s+(\w+)\s*=", core_body, re.M)
          + re.findall(r"^\s{4,}(\w+)\s*(?:<=|=)\s", core_body, re.M)
          # 实例区把子模块 output pin 直接接到顶层端口，也算驱动。
          # ★只在 inst 生成区里找★：手写区的具名函数实参也长成 `.名(信号)`，
          # 按全文匹配会把 difftest 探针的 22 个实参误算成第二个驱动（实测踩到）。
          + re.findall(r"^\s*\.\w+\s*\((\w+)\)", region("inst"), re.M)):
    if n in core_outs:
        out_counts[n] = out_counts.get(n, 0) + 1
out_missing = sorted(core_outs - set(out_counts))
out_dup = sorted(n for n, c in out_counts.items() if c > 1)
print(f"core output ports  : {len(core_outs)}")
print(f"driven exactly once: {len(core_outs) - len(out_missing) - len(out_dup)}")
print(f"OUT-MISSING        : {len(out_missing)}")
print(f"OUT-DUPLICATE      : {len(out_dup)}")

missing = sorted(declared - set(counts))
dup = sorted(n for n, c in counts.items() if c > 1)
extra = sorted(n for n in set(re.findall(r"^\s*assign\s+(u_\w+__\w+)\s*=", hand, re.M))
               if n not in declared)

print(f"declared glue nets : {len(declared)}")
print(f"driven exactly once: {len(declared) - len(missing) - len(dup)}")
print(f"MISSING            : {len(missing)}")
print(f"DUPLICATE          : {len(dup)}")
print(f"ASSIGNED-BUT-UNDECLARED (打错名字): {len(extra)}")
for label, lst in (("MISSING", missing), ("DUPLICATE", dup), ("UNDECLARED", extra),
                  ("OUT-MISSING", out_missing), ("OUT-DUPLICATE", out_dup)):
    if lst:
        print(f"\n--- {label} ---")
        for n in lst[:80]:
            print("  " + n)
        if len(lst) > 80:
            print(f"  ... 共 {len(lst)} 条")
sys.exit(1 if (missing or dup or extra or out_missing or out_dup) else 0)
