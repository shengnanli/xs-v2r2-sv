#!/usr/bin/env python3
"""从 G1 golden 机械抽取 DelayN 家族每个变体的事实（端口表 / 级数 / 寄存器总位数）。"""
import re, sys, json, os
G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

def facts(name):
    txt = open(f"{G}/{name}.sv").read()
    i = txt.index(f"\nmodule {name}(")
    body = txt[i+1:]
    head = body[:body.index("\n);")]
    ports = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"{name}: 端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4), text=ln))
    # 寄存器：级数 + 总位数
    regs = re.findall(r'^  reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', body, re.M)
    tot = 0
    stages = set()
    for hi, lo, rn in regs:
        tot += (int(hi) - int(lo) + 1) if hi else 1
        m = re.match(r'REG(_(\d+))?(_.*)?$', rn)
        stages.add(int(m.group(2)) if m and m.group(2) else 0)
    ins = [p for p in ports if p["name"].startswith("io_in")]
    outs = [p for p in ports if p["name"].startswith("io_out")]
    other = [p for p in ports if p not in ins and p not in outs]
    return dict(name=name, ports=ports, ins=ins, outs=outs, other=[p["name"] for p in other],
                stages=len(stages), reg_bits=tot,
                payload=sum(p["w"] for p in ins),
                head_text=head + "\n);")

if __name__ == "__main__":
    for n in sys.argv[1:]:
        f = facts(n)
        ok = f["payload"] * f["stages"] == f["reg_bits"]
        names_ok = [p["name"][len("io_in"):] for p in f["ins"]] == [p["name"][len("io_out"):] for p in f["outs"]]
        widths_ok = [p["w"] for p in f["ins"]] == [p["w"] for p in f["outs"]]
        print(f"{n}: stages={f['stages']} reg_bits={f['reg_bits']} payload={f['payload']} "
              f"ports={len(f['ports'])} other={f['other']} eq={ok} names_match={names_ok} widths_match={widths_ok}")
