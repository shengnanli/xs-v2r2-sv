#!/usr/bin/env python3
"""生成 coupledL2 SinkA (TileLink A 通道接收器) 的 wrapper / 变体 / UT / Makefile。

SinkA 是纯组合叶子(无寄存器、无 SRAM、无子模块):
  - wrapper (golden 同名 SinkA) : FM impl 顶层, 例化 xs_SinkA_core
  - 变体    (SinkA_xs)          : UT impl 顶层, 同样例化 xs_SinkA_core
  - tb.sv   : 双例化 golden SinkA vs SinkA_xs, 每拍随机激励逐拍比对全部输出
  - Makefile: include ut_common.mk
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "SinkA"


def parse_ports(path, module):
    text = path.read_text()
    m = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    ports = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return ports


def width_bits(w):
    if not w:
        return 1
    mm = re.match(r"\[(\d+):(\d+)\]", w)
    hi, lo = map(int, mm.groups())
    return abs(hi - lo) + 1


def module_header(name, ports):
    body = ",\n".join(f"  {d} {w}{' ' if w else ''}{n}" for d, w, n in ports)
    return f"module {name}(\n{body}\n);\n"


def inst(module, name, ports):
    lines = [f"  {module} {name} ("]
    for i, (_, _, p) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{p}({p}){c}")
    lines.append("  );")
    return "\n".join(lines)


def gen_body(top, ports):
    return ("// 自动生成 scripts/gen_sinka.py —— 勿手改\n"
            + module_header(top, ports) + inst("xs_SinkA_core", "u_core", ports) + "\nendmodule\n")


def gen_tb(ports):
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_sinka.py —— 勿手改")
    L.append("// SinkA 双例化逐拍比对: golden SinkA vs 可读重写 SinkA_xs (纯组合)。")
    L.append("`timescale 1ns/1ps")
    L.append("`define CHK(SIG) begin \\")
    L.append("  if (!$isunknown(g_``SIG)) begin \\")
    L.append("    checks++; \\")
    L.append("    if (g_``SIG !== i_``SIG) begin \\")
    L.append("      errors++; \\")
    L.append("      if (errors <= 30) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\")
    L.append("    end \\")
    L.append("  end \\")
    L.append("end")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  bit clock = 0; bit reset; int errors = 0; int checks = 0;")
    L.append("  always #5 clock = ~clock;")
    for _, w, n in ins:
        L.append(f"  logic {w}{' ' if w else ''}{n};")
    for _, w, n in outs:
        L.append(f"  wire {w}{' ' if w else ''}g_{n};")
        L.append(f"  wire {w}{' ' if w else ''}i_{n};")
    L.append("")
    for instname, pfx in (("SinkA", "g_"), ("SinkA_xs", "i_")):
        L.append(f"  {instname} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(ports):
            c = "," if i + 1 < len(ports) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n in ("io_a_valid", "io_prefetchReq_valid"):
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n.endswith("_ready"):
            L.append(f"    {n} = ($urandom_range(0,3) != 0);")
        elif n == "io_a_bits_opcode":
            L.append(f"    {n} = $urandom_range(2,7);")   # 避开 Put(0/1) 的断言
        elif n == "io_prefetchReq_bits_pfSource":
            L.append(f"    {n} = $urandom_range(0,15);")  # 覆盖 fromL2pft 的 8/9
        elif nb <= 32:
            L.append(f"    {n} = $urandom;")
        else:
            words = (nb + 31) // 32
            cat = ", ".join(["$urandom"] * words)
            L.append(f"    {n} = {{{cat}}};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outs:
        L.append(f"    `CHK({n})")
    L.append("  endtask")
    L.append("")
    L.append("  initial begin")
    L.append("    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end")
    L.append("    reset = 1'b1;")
    for _, _, n in ins:
        L.append(f"    {n} = '0;")
    L.append("    repeat (5) @(posedge clock);")
    L.append("    reset = 1'b0;")
    L.append("    repeat (NCYCLES) begin")
    L.append("      @(negedge clock);")
    L.append("      drive_random();")
    L.append("      #1 check_outputs();")
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append("    $display(\"SinkA checks=%0d errors=%0d\", checks, errors);")
    L.append("    if (errors == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = SinkA

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/SinkA.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/SinkA_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SinkA.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SinkA
FM_REF_DEPS_SinkA =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "SinkA.sv", "SinkA")
    (RTL / "SinkA_wrapper.sv").write_text(gen_body("SinkA", ports))
    (UT / "variants_xs.sv").write_text(gen_body("SinkA_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated SinkA wrapper / variant / tb / Makefile;", len(ports), "ports")


if __name__ == "__main__":
    main()
