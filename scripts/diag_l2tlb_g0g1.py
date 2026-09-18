#!/usr/bin/env python3
"""
L2TLB 的 G0→G1 差异分块归类（"该移植还是该重写"的判据）。

可重跑:  python3 scripts/diag_l2tlb_g0g1.py
输入  :  /home/eda/xs-env/G0-canonical/golden-rtl/L2TLB.sv  (G0, 13062 行)
         /home/eda/xs-env/G1-canonical/golden-rtl/L2TLB.sv  (G1, 20101 行)
两份 golden 均只读。本脚本不写任何文件，只打印计量。
"""
import re, hashlib
from pathlib import Path

G0 = Path("/home/eda/xs-env/G0-canonical/golden-rtl/L2TLB.sv")
G1 = Path("/home/eda/xs-env/G1-canonical/golden-rtl/L2TLB.sv")

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

t0, t1 = G0.read_text(), G1.read_text()
print(f"G0 {G0}\n   lines={len(t0.splitlines())} sha256={sha(G0)}")
print(f"G1 {G1}\n   lines={len(t1.splitlines())} sha256={sha(G1)}")

def ports(t, mod="L2TLB"):
    m = re.search(rf"^module {mod}\((.*?)\n\);", t, re.S | re.M)
    out = []
    for l in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", l)
        if pm: out.append(pm.group(3))
    return out

p0, p1 = set(ports(t0)), set(ports(t1))
print(f"\n[端口] G0={len(p0)} G1={len(p1)}  新增={len(p1-p0)} 删除={len(p0-p1)}")
def bucket(n):
    if n.startswith("sigFromSrams_bore") or "bore" in n or "cgen" in n: return "DFT/MBIST 透传"
    if n.startswith("io_csr_tlb"): return "csr_tlb 新字段"
    if n == "io_hartId": return "hartId"
    return "其它"
from collections import Counter
for k, v in Counter(map(bucket, p1 - p0)).most_common(): print(f"    新增 {k:16s} {v}")
for n in sorted(p0 - p1): print(f"    删除 {n}")

def insts(t):
    return re.findall(r"^  ([A-Za-z_]\w*) ([A-Za-z_]\w*) \($", t, re.M)
i0, i1 = insts(t0), insts(t1)
n0, n1 = {n for _, n in i0}, {n for _, n in i1}
print(f"\n[实例] G0={len(i0)} G1={len(i1)}")
print(f"    G1 新增实例: {sorted(n1 - n0)}")
print(f"    G0 独有实例: {sorted(n0 - n1)}")

def ids(t):
    return {w for w in re.findall(r"\b[A-Za-z_]\w*\b", t)
            if not re.fullmatch(r"_(GEN|T)_\d+", w)}
a, b = ids(t0), ids(t1)
print(f"\n[标识符存活率] G0={len(a)} 其中在 G1 仍在={len(a & b)} "
      f"({100 * len(a & b) // len(a)}%)  G0 独有={len(a - b)}  G1 新增={len(b - a)}")

for nm in ("waiting_resp", "flush_latch", "csr_dup", "sfence_dup"):
    f = lambda t: sorted({int(x) for x in re.findall(rf"\b{nm}_(\d+)", t)})
    print(f"\n[{nm}] G0 下标={f(t0)}\n{' ' * (len(nm) + 3)}G1 下标={f(t1)}")
