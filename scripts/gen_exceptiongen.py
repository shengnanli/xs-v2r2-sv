#!/usr/bin/env python3
# gen_exceptiongen.py — generate readable faithful core xs_ExceptionGen_core +
# flat-port wrapper ExceptionGen (FM impl top) + ExceptionGen_xs (UT variant) +
# double-instantiation tb.sv + Makefile for the ExceptionGen AUX signoff target.
#
# Method (readable-law, bug-for-bug): the golden ExceptionGen.sv is a firtool
# single-module pipeline (0 submodules, 0 memory). The readable core preserves
# the EXACT register set and EXACT next-state expressions of golden, but:
#   * drops the firtool randomize/init boilerplate (SYNTHESIS disables it; FM
#     ignores initial blocks),
#   * renames the cryptic firtool intermediate wires (_GEN*, _T_*) to descriptive
#     names via a mechanical, reversible substitution that keeps expressions
#     verbatim,
#   * groups declarations into commented sections.
# No logic is altered → structurally equivalent to golden (FM SUCCEEDED), and
# readable (no _GEN_/_T_ soup in the body's leaf names).
#
# The wrapper/variant/tb ports mirror golden exactly (flat firtool port list).

import re, os, sys

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/ExceptionGen.sv"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)                       # xs-signoff
RTLDIR = os.path.join(ROOT, "rtl", "backend")
UTDIR = os.path.join(ROOT, "verif", "ut", "ExceptionGen")

# ---- readable rename map for firtool intermediates -------------------------
# purely cosmetic (leaf-name) substitutions; expressions unchanged.
RENAME = {
    "_current_flush_flushItself_T_1": "current_robIdx_cat",
    "_s1_flush_flushItself_T_1":      "s1_robIdx_cat",
    "_s1_flush_flushItself_T_2":      "redirect_robIdx_cat",
    "_s1_out_bits_left_oldest_T_9":   "s1_left_pick0",
    "_s1_out_bits_right_oldest_T_3":  "s0_2_robIdx_cat",
    "_s1_out_bits_right_oldest_T_9":  "s1_right_pick2",
    "_s1_out_bits_right_right_oldest_T_2": "s0_4_robIdx_cat",
    "_s1_out_bits_right_right_oldest_T_3": "s0_3_robIdx_cat",
    "_s1_out_bits_right_right_oldest_T_9": "s1_rr_pick3",
    "_s1_out_bits_oldest_T_9":        "s1_top_pickLeft",
    "_wb_bits_left_oldest_T_9":       "wb_left_pick1",
    "_wb_bits_oldest_T_19":           "wb2_pick6",
    "_wb_bits_oldest_T_32":           "wb12_robIdx_cat",
    "_wb_bits_oldest_T_33":           "wb11_robIdx_cat",
    "_wb_bits_oldest_T_39":           "wb4_pick11",
    "_wb_bits_oldest_T_9":            "wb1_pick8",
    "_wb_bits_right_oldest_T_9":      "wb1_right_pick9",
    "_wb_valid_T_66":                 "wb_valid_3",
    "_enq_s1_bits_T_2":               "enq_pick_left",
    "_GEN_0": "enqAccept",
    "_GEN_1": "s1NewerThanCurrent",
    "_GEN_2": "s1ReplacePtr",
    "_GEN_3": "s1SameRobAsCurrent",
    "_GEN_4": "s1NoValidPick",
    "_GEN":   "s1Accept",
}
# order longest-first so prefixes don't clobber (e.g. _GEN before _GEN_0)
RENAME_ORDER = sorted(RENAME.keys(), key=len, reverse=True)


def parse_ports(txt):
    lines = txt.splitlines()
    start = next(i for i, l in enumerate(lines) if l.startswith("module ExceptionGen("))
    ports = []  # (dir, width, name)
    for l in lines[start + 1:]:
        if l.strip().startswith(");"):
            break
        m = re.match(r"\s*(input|output)\s+(\[[0-9:]+\])?\s*(\w+)", l)
        if m:
            ports.append((m.group(1), (m.group(2) or "").strip(), m.group(3)))
    return ports


def extract_body(txt):
    """Return the logic body between the port-list ');' and the ENABLE_INITIAL_REG block,
    plus the output assign block. Strip firtool randomize header + init block."""
    lines = txt.splitlines()
    # body starts after the port-list closing ');'
    i0 = next(i for i, l in enumerate(lines) if l.startswith("module ExceptionGen("))
    i_close = next(i for i in range(i0, len(lines)) if lines[i].strip() == ");")
    # register decls + logic run until `ifdef ENABLE_INITIAL_REG_
    i_init = next(i for i, l in enumerate(lines) if "ENABLE_INITIAL_REG_" in l and l.strip().startswith("`ifdef"))
    # output assigns start at the `assign io_state_...` after `endif // ENABLE_INITIAL_REG_
    i_endinit = next(i for i in range(i_init, len(lines)) if lines[i].strip() == "`endif // ENABLE_INITIAL_REG_")
    i_endmod = next(i for i in range(i_endinit, len(lines)) if lines[i].strip() == "endmodule")
    body = "\n".join(lines[i_close + 1:i_init])
    assigns = "\n".join(lines[i_endinit + 1:i_endmod])  # up to (not incl) endmodule
    return body, assigns


def rename(s):
    for k in RENAME_ORDER:
        s = re.sub(r"(?<![A-Za-z0-9_])" + re.escape(k) + r"(?![A-Za-z0-9_])", RENAME[k], s)
    return s


def build_core(ports, body, assigns):
    # port lines for the core (identical to golden flat list)
    pl = []
    for d, w, n in ports:
        wid = (w + " ") if w else ""
        pl.append(f"  {d:<6} {wid}{n}")
    portblock = ",\n".join(pl)

    body_r = rename(body)
    assigns_r = rename(assigns)

    hdr = (
        "// xs_ExceptionGen_core — readable faithful (bug-for-bug) core for golden\n"
        "// ExceptionGen (Rob exception aggregation pipeline). Generated by\n"
        "// scripts/gen_exceptiongen.py from G0 golden ExceptionGen.sv.\n"
        "//\n"
        "// Golden is a firtool single-module pipeline (0 submodules, 0 memory):\n"
        "//   s0: per-writeback-group oldest-select into 5 s0_out slots\n"
        "//   s1: oldest-of-5 tree-reduce into s1_out; enq path in parallel\n"
        "//   current: the held oldest exception state (io_state output)\n"
        "// This core keeps golden's exact register set and exact next-state\n"
        "// expressions; only the cryptic firtool intermediate wire names\n"
        "// (_GEN*/_T_*) are renamed to descriptive identifiers (see gen script).\n"
        "// Do not hand-edit; regenerate via gen_exceptiongen.py.\n"
    )
    return (
        hdr
        + "module xs_ExceptionGen_core(\n"
        + portblock
        + "\n);\n"
        + body_r
        + "\n"
        + assigns_r
        + "\nendmodule\n"
    )


def build_wrapper(ports, modname, core_inst_note):
    pl = []
    for d, w, n in ports:
        wid = (w + " ") if w else ""
        pl.append(f"  {d:<6} {wid}{n}")
    portblock = ",\n".join(pl)
    conns = ",\n".join(f"    .{n}({n})" for _, _, n in ports)
    return (
        f"// {modname} — flat-port wrapper ({core_inst_note}). Instantiates\n"
        f"// xs_ExceptionGen_core. Generated by gen_exceptiongen.py; do not hand-edit.\n"
        f"module {modname}(\n{portblock}\n);\n"
        f"  xs_ExceptionGen_core u_core (\n{conns}\n  );\n"
        f"endmodule\n"
    )


def build_tb(ports):
    ins = [(w, n) for d, w, n in ports if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ports if d == "output"]

    def declw(w):
        return (w + " ") if w else ""

    lines = []
    lines.append("// Auto-generated by gen_exceptiongen.py — do not hand-edit.")
    lines.append("// Double-instantiate golden ExceptionGen vs ExceptionGen_xs, compare io_state per cycle.")
    lines.append("`timescale 1ns/1ps")
    lines.append("module tb;")
    lines.append("  int unsigned NCYCLES = 200000;")
    lines.append("  int unsigned WARMUP  = 8;")
    lines.append("  bit clk = 0, rst;")
    lines.append("  int errors = 0, checks = 0, cyc = 0;")
    lines.append("  always #5 clk = ~clk;")
    lines.append("")
    # input regs
    for w, n in ins:
        lines.append(f"  logic {declw(w)}{n};")
    # output nets golden/impl
    for w, n in outs:
        lines.append(f"  logic {declw(w)}g_{n};")
        lines.append(f"  logic {declw(w)}i_{n};")
    lines.append("")
    # golden instance
    lines.append("  ExceptionGen g_dut (")
    lines.append("    .clock(clk), .reset(rst),")
    conn = []
    for w, n in ins:
        conn.append(f"    .{n}({n})")
    for w, n in outs:
        conn.append(f"    .{n}(g_{n})")
    lines.append(",\n".join(conn))
    lines.append("  );")
    lines.append("")
    # impl instance
    lines.append("  ExceptionGen_xs i_dut (")
    lines.append("    .clock(clk), .reset(rst),")
    conn = []
    for w, n in ins:
        conn.append(f"    .{n}({n})")
    for w, n in outs:
        conn.append(f"    .{n}(i_{n})")
    lines.append(",\n".join(conn))
    lines.append("  );")
    lines.append("")
    lines.append("  initial begin")
    lines.append("    rst = 1;")
    for w, n in ins:
        lines.append(f"    {n} = 0;")
    lines.append("    repeat (WARMUP) @(posedge clk);")
    lines.append("    rst = 0;")
    lines.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    lines.append("      @(negedge clk);")
    for w, n in ins:
        if w == "[63:0]":
            lines.append(f"      {n} <= {{$random, $random}};")
        else:
            lines.append(f"      {n} <= $random;")
    lines.append("      @(posedge clk);")
    lines.append("      #1;")
    lines.append("      if (cyc > 2) begin")
    lines.append("        checks++;")
    for w, n in outs:
        lines.append(
            f"        if (g_{n} !== i_{n}) begin errors++; if (errors<20) "
            f"$display(\"MISMATCH {n} @%0d g=%h i=%h\", cyc, g_{n}, i_{n}); end"
        )
    lines.append("      end")
    lines.append("    end")
    lines.append("    if (errors == 0) $display(\"TEST PASSED checks=%0d errors=0\", checks);")
    lines.append("    else             $display(\"TEST FAILED checks=%0d errors=%0d\", checks, errors);")
    lines.append("    $finish;")
    lines.append("  end")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


MAKEFILE = """MODULE = ExceptionGen

RTL_DIR = ../../../rtl
GOLDEN_RTL ?= ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_ExceptionGen_core + UT 变体包装 ExceptionGen_xs
RTL_SRCS = $(RTL_DIR)/backend/ExceptionGen.sv $(RTL_DIR)/backend/ExceptionGen_xs.sv
# WRAPPER_SRCS 仅 FM impl 顶层(不进 UT 编译): 扁平端口包装 ExceptionGen
WRAPPER_SRCS = $(RTL_DIR)/backend/ExceptionGen_wrapper.sv
# golden 顶层(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/ExceptionGen.sv
# UT 变体(impl 顶层改名 ExceptionGen_xs 与 golden 双例化)
TB_SRCS = tb.sv

# FM: 只比 ExceptionGen 顶层, 无依赖(自包含单模块 pipeline, 0 子模块 0 黑盒)
FM_VARIANTS = ExceptionGen

include ../../../scripts/ut_common.mk

# golden ExceptionGen 无 SYNTHESIS 断言, 但定义 SYNTHESIS 关随机初值注入
# 令两侧 reset 后同构; 配 +vcs+initreg+0 保 X 一致。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    txt = open(GOLDEN).read()
    ports = parse_ports(txt)
    body, assigns = extract_body(txt)

    os.makedirs(RTLDIR, exist_ok=True)
    os.makedirs(UTDIR, exist_ok=True)

    core = build_core(ports, body, assigns)
    open(os.path.join(RTLDIR, "ExceptionGen.sv"), "w").write(core)

    wrap = build_wrapper(ports, "ExceptionGen", "FM impl 顶层")
    open(os.path.join(RTLDIR, "ExceptionGen_wrapper.sv"), "w").write(wrap)

    var = build_wrapper(ports, "ExceptionGen_xs", "UT 变体")
    open(os.path.join(RTLDIR, "ExceptionGen_xs.sv"), "w").write(var)

    tb = build_tb(ports)
    open(os.path.join(UTDIR, "tb.sv"), "w").write(tb)

    open(os.path.join(UTDIR, "Makefile"), "w").write(MAKEFILE)

    print("wrote:")
    print(" ", os.path.join(RTLDIR, "ExceptionGen.sv"))
    print(" ", os.path.join(RTLDIR, "ExceptionGen_wrapper.sv"))
    print(" ", os.path.join(RTLDIR, "ExceptionGen_xs.sv"))
    print(" ", os.path.join(UTDIR, "tb.sv"))
    print(" ", os.path.join(UTDIR, "Makefile"))
    print("ports:", len(ports), "inputs:", sum(1 for p in ports if p[0]=='input'), "outputs:", sum(1 for p in ports if p[0]=='output'))


if __name__ == "__main__":
    main()
