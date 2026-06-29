#!/usr/bin/env python3
"""生成 coupledL2 SourceB (B 通道 Probe 源) 的 wrapper / 变体 / UT / Makefile。

SourceB 含 1 个 FastArbiter_6 (4 入 1 出轮询仲裁) 黑盒。可读核 xs_SourceB_core 做
4 表项 probe 缓冲 FSM, 仲裁器在 golden 同名 wrapper 内例化并把核与出口 io_sourceB 对接。
  - wrapper (golden 同名 SourceB) : FM impl 顶层; 例化核 + FastArbiter_6
  - 变体    (SourceB_xs)          : UT impl 顶层; 内容同 wrapper, 仅模块名不同
  - tb.sv   : 双例化比对, 每拍随机激励 (偏小 set/tag 促命中 grantStatus 冲突)
  - Makefile: golden 侧带 FastArbiter_6; FM 侧仲裁器当黑盒
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "SourceB"


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


BOUNDARY = """  // ---- 核与 FastArbiter_6 的边界 wire ----
  wire        arb_in_0_ready, arb_in_1_ready, arb_in_2_ready, arb_in_3_ready;
  wire        arb_in_0_valid, arb_in_1_valid, arb_in_2_valid, arb_in_3_valid;
  wire [30:0] arb_in_0_tag, arb_in_1_tag, arb_in_2_tag, arb_in_3_tag;
  wire [8:0]  arb_in_0_set, arb_in_1_set, arb_in_2_set, arb_in_3_set;
  wire [2:0]  arb_in_0_opcode, arb_in_1_opcode, arb_in_2_opcode, arb_in_3_opcode;
  wire [1:0]  arb_in_0_param, arb_in_1_param, arb_in_2_param, arb_in_3_param;
  wire [1:0]  arb_in_0_alias, arb_in_1_alias, arb_in_2_alias, arb_in_3_alias;
  wire [30:0] arb_out_tag;
  wire [8:0]  arb_out_set;
  wire [1:0]  arb_out_alias;
"""


def core_inst(ports):
    L = ["  xs_SourceB_core u_core ("]
    conns = []
    for d, w, n in ports:
        if n.startswith("io_sourceB"):
            continue   # 出口由仲裁器直接驱动, 不进核
        conns.append(f".{n}({n})")
    for k in range(4):
        conns += [f".arb_in_{k}_ready(arb_in_{k}_ready)", f".arb_in_{k}_valid(arb_in_{k}_valid)",
                  f".arb_in_{k}_tag(arb_in_{k}_tag)", f".arb_in_{k}_set(arb_in_{k}_set)",
                  f".arb_in_{k}_opcode(arb_in_{k}_opcode)", f".arb_in_{k}_param(arb_in_{k}_param)",
                  f".arb_in_{k}_alias(arb_in_{k}_alias)"]
    for j, c in enumerate(conns):
        L.append(f"    {c}{',' if j + 1 < len(conns) else ''}")
    L.append("  );")
    return "\n".join(L)


def arb_inst():
    L = ["  FastArbiter_6 issueArb (", "    .clock(clock),", "    .reset(reset),"]
    for k in range(4):
        L += [f"    .io_in_{k}_ready(arb_in_{k}_ready),",
              f"    .io_in_{k}_valid(arb_in_{k}_valid),",
              f"    .io_in_{k}_bits_tag(arb_in_{k}_tag),",
              f"    .io_in_{k}_bits_set(arb_in_{k}_set),",
              f"    .io_in_{k}_bits_opcode(arb_in_{k}_opcode),",
              f"    .io_in_{k}_bits_param(arb_in_{k}_param),",
              f"    .io_in_{k}_bits_alias(arb_in_{k}_alias),"]
    L += ["    .io_out_ready(io_sourceB_ready),",
          "    .io_out_valid(io_sourceB_valid),",
          "    .io_out_bits_tag(arb_out_tag),",
          "    .io_out_bits_set(arb_out_set),",
          "    .io_out_bits_opcode(io_sourceB_bits_opcode),",
          "    .io_out_bits_param(io_sourceB_bits_param),",
          "    .io_out_bits_alias(arb_out_alias)",
          "  );"]
    return "\n".join(L)


TAIL = """  assign io_sourceB_bits_address = {2'h0, arb_out_tag, arb_out_set, 6'h0};
  assign io_sourceB_bits_data = {253'h0, arb_out_alias, 1'h0};
endmodule
"""


def gen_body(top, ports):
    return ("// 自动生成 scripts/gen_sourceb.py —— 勿手改\n"
            + module_header(top, ports) + "\n" + BOUNDARY + "\n"
            + core_inst(ports) + "\n\n" + arb_inst() + "\n"
            + TAIL)


def gen_tb(ports):
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_sourceb.py —— 勿手改")
    L.append("// SourceB 双例化逐拍比对: golden SourceB vs 可读重写 SourceB_xs。")
    L.append("// 偏小 set/tag 域促成 grantStatus 同地址冲突, 覆盖 rdy 阻塞/解除路径。")
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
    for instname, pfx in (("SourceB", "g_"), ("SourceB_xs", "i_")):
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
        if n == "io_task_valid":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_sourceB_ready":
            L.append(f"    {n} = ($urandom_range(0,2) != 0);")
        elif n.endswith("_valid"):   # grantStatus valid
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n.endswith("_set") or n == "io_task_bits_set":
            L.append(f"    {n} = $urandom_range(0,3);")
        elif n.endswith("_tag") or n == "io_task_bits_tag":
            L.append(f"    {n} = $urandom_range(0,3);")
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
    # 内部探针: golden probes_K_* (扁平) vs 可读核 probes_*[K] (数组), 逐表项显式映射
    L.append("  int ierr = 0;")
    L.append("  `define IP(GP, IP) begin \\")
    L.append("    if (!$isunknown(u_g.GP)) begin \\")
    L.append("      if (u_g.GP !== u_i.u_core.IP) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 40) $display(\"[%0t] IPROBE-DIFF g=%0h i=%0h\", $time, u_g.GP, u_i.u_core.IP); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    L.append("  task automatic check_internal();")
    for k in range(4):
        L.append(f"    `IP(probes_{k}_valid,  probes_valid[{k}])")
        L.append(f"    `IP(probes_{k}_rdy,    probes_rdy[{k}])")
        L.append(f"    `IP(probes_{k}_waitG,  probes_waitG[{k}])")
        L.append(f"    `IP(probes_{k}_task_tag,    probes_tag[{k}])")
        L.append(f"    `IP(probes_{k}_task_set,    probes_set[{k}])")
        L.append(f"    `IP(probes_{k}_task_opcode, probes_opcode[{k}])")
        L.append(f"    `IP(probes_{k}_task_param,  probes_param[{k}])")
        L.append(f"    `IP(probes_{k}_task_alias,  probes_alias[{k}])")
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
    L.append("      check_internal();")
    L.append("      @(posedge clock);")
    L.append("    end")
    L.append("    $display(\"SourceB checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = SourceB

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/SourceB.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/SourceB_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SourceB.sv $(GOLDEN_RTL)/FastArbiter_6.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SourceB 本体, FastArbiter_6 两侧均黑盒
FM_VARIANTS = SourceB
FM_REF_DEPS_SourceB =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "SourceB.sv", "SourceB")
    (RTL / "SourceB_wrapper.sv").write_text(gen_body("SourceB", ports))
    (UT / "variants_xs.sv").write_text(gen_body("SourceB_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated SourceB wrapper / variant / tb / Makefile;", len(ports), "ports")


if __name__ == "__main__":
    main()
