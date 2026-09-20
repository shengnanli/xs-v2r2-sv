#!/usr/bin/env python3
"""gen_sbuffer_tb.py —— 生成 verif/ut/Sbuffer/tb.sv 的机械区（端口声明 + 两侧例化 +
逐拍比对表）。激励与覆盖闸是手写模板，放在 scripts/sbuffer_tb_stimulus.svh.in。

为什么 tb 也要生成：Sbuffer 有 196 个 golden 端口，其中 96 个是 forward 的
mask/data 展平项。手抄一次就会漏一项，而漏掉的那一项在 UT 里永远是绿的。

用法: python3 scripts/gen_sbuffer_tb.py [--check]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
OUT = os.path.join(REPO, "verif/ut/Sbuffer/tb.sv")
TPL = os.path.join(HERE, "sbuffer_tb_stimulus.svh.in")


def golden_ports():
    txt = open(os.path.join(GOLDEN, "Sbuffer.sv")).read()
    m = re.search(r"^module Sbuffer\(\n(.*?)^\);", txt, re.S | re.M)
    out = []
    for ln in m.group(1).split("\n"):
        mm = re.match(
            r"\s*(input|output)\s+(?:wire\s+)?(?:\[(\d+):(\d+)\]\s+)?([A-Za-z_]\w*)", ln)
        if mm:
            hi = int(mm.group(2)) if mm.group(2) is not None else 0
            out.append((mm.group(1), hi + 1, mm.group(4)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    ports = golden_ports()
    ins = [(w, n) for d, w, n in ports if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ports if d == "output"]

    L = []
    L.append("// 自动生成：scripts/gen_sbuffer_tb.py —— 请勿手改")
    L.append("// （激励模板在 scripts/sbuffer_tb_stimulus.svh.in，改那里再重跑生成器）")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    L.append("  // ---- 共享输入（两侧同驱）----")
    for w, n in ins:
        L.append("  logic %-10s %s;" % ("[%d:0]" % (w - 1) if w > 1 else "", n))
    L.append("")
    L.append("  // ---- 两侧输出 ----")
    for w, n in outs:
        L.append("  wire  %-10s g_%s, i_%s;" % ("[%d:0]" % (w - 1) if w > 1 else "", n, n))
    L.append("")
    conn = ".clock(clk), .reset(rst)"
    conn += "".join(", .%s(%s)" % (n, n) for _, n in ins)
    L.append("  Sbuffer    u_g (%s%s);"
             % (conn, "".join(", .%s(g_%s)" % (n, n) for _, n in outs)))
    L.append("  Sbuffer_xs u_i (%s%s);"
             % (conn, "".join(", .%s(i_%s)" % (n, n) for _, n in outs)))
    L.append("")
    L.append(open(TPL).read().rstrip("\n"))
    L.append("")
    L.append("  // ---- 逐拍比对：golden 的每一个输出端口都在表里，一个不许少 ----")
    L.append("  task automatic cmp(input string nm,")
    L.append("                     input logic [656:0] g, input logic [656:0] i);")
    L.append("    checks++;")
    L.append("    if (g !== i) begin")
    L.append("      errors++;")
    L.append("      if (errors <= 20)")
    L.append("        $display(\"MISMATCH cyc=%0d %s golden=%h impl=%h\", cyc, nm, g, i);")
    L.append("    end")
    L.append("  endtask")
    L.append("")
    L.append("  always @(posedge clk) if (!rst && compare_open) begin")
    for w, n in outs:
        L.append("    cmp(\"%s\", 657'(g_%s), 657'(i_%s));" % (n, n, n))
    L.append("  end")
    L.append("")
    L.append("endmodule")
    txt = "\n".join(L) + "\n"
    old = open(OUT).read() if os.path.exists(OUT) else None
    if a.check:
        if old != txt:
            print("gen_sbuffer_tb: tb.sv 与生成器不一致", file=sys.stderr)
            return 1
        print("gen_sbuffer_tb: 一致 (%d in / %d out)" % (len(ins), len(outs)))
        return 0
    if old != txt:
        open(OUT, "w").write(txt)
    print("gen_sbuffer_tb: ok (%d in / %d out)" % (len(ins), len(outs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
