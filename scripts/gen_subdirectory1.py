#!/usr/bin/env python3
"""生成 openLLC SubDirectory_1(selfDir, plru)的 wrapper / 变体 / UT / Makefile。

SubDirectory_1 含 3 个黑盒子模块:
  SRAMTemplate_199  tagArray
  SRAMTemplate_200  metaArray ({valid,dirty})
  SRAMTemplate_201  replacer_sram_opt (15 位 PLRU 树状态, shouldReset)
可读核 xs_SubDirectory_1_core 做三级流水控制/选路 + PLRU; 3 块 SRAM 从 golden 原样
搬入 wrapper(tagArray 写 waymask 仅依赖外部端口, 留 golden 内联)。方法学同 gen_directory。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "SubDirectory_1"

GOLD = (GOLDEN / "SubDirectory_1.sv").read_text()

# 单行 driver 信号名替换 (golden → 核 o_* 输出)
SUBS = [
    ("(_repl_state_s3_repl_sram_r_T)", "(o_ren)"),
    ("(io_metaWReq_valid | ~resetFinish)", "(o_metaWen)"),
    ("(resetFinish ? io_metaWReq_bits_set : resetIdx)", "(o_metaWset)"),
    ("(_GEN_0)", "(o_metaWdirty)"),
    ("(_GEN)", "(o_metaWvalid)"),
    ("(resetFinish ? io_metaWReq_bits_wayOH : 16'hFFFF)", "(o_metaWaymask)"),
    ("(~resetFinish | replacerWen)", "(o_replWen)"),
    ("(resetFinish ? req_s3_set : resetIdx)", "(o_replWset)"),
]

INST_MODULES = ["SRAMTemplate_199", "SRAMTemplate_200", "SRAMTemplate_201"]


def parse_ports(text, module):
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


def lift_decls():
    keep = []
    for ln in GOLD.splitlines():
        s = ln.strip()
        if not s.startswith("wire"):
            continue
        if "_tagArray_io_r_resp_data" in s or "_metaArray_io_r_resp_data" in s \
           or "_replacer_sram_opt_io_r_resp_data" in s:
            keep.append("  " + s)
    return "\n".join(keep)


def lift_instances():
    lines = GOLD.splitlines()
    blocks = []
    i = 0
    while i < len(lines):
        m = re.match(r"\s*(" + "|".join(INST_MODULES) + r")\s+\w+\s*\($", lines[i])
        if m:
            mod = m.group(1)
            blk = [lines[i]]
            i += 1
            while i < len(lines):
                blk.append(lines[i])
                if lines[i].strip() == ");":
                    break
                i += 1
            txt = "\n".join(blk)
            for a, b in SUBS:
                txt = txt.replace(a, b)
            # 仅 replacer_sram(SRAMTemplate_201) 的写数据是多行 PLRU 更新表达式,
            # 且 data_0 是末尾连接 → 整体折叠成 o_replWdata。tagArray 的 data_0 在
            # 同一行且后面还有 data_1..15/waymask, 切勿用贪婪匹配波及。
            if mod == "SRAMTemplate_201":
                txt = re.sub(r"\.io_w_req_bits_data_0\s*\(.*\)\s*\n(\s*)\);",
                             r".io_w_req_bits_data_0 (o_replWdata)\n\1);", txt, flags=re.S)
            blocks.append(txt)
        i += 1
    return "\n".join(blocks)


BOUNDARY_DECLS = """  // ---- 核与 SRAM 黑盒的边界 wire (核的 o_* 输出) ----
  wire        o_ren;
  wire        o_metaWen;
  wire [11:0] o_metaWset;
  wire        o_metaWvalid;
  wire        o_metaWdirty;
  wire [15:0] o_metaWaymask;
  wire        o_replWen;
  wire [11:0] o_replWset;
  wire [14:0] o_replWdata;
"""


def core_inst(ports):
    L = ["  xs_SubDirectory_1_core u_core ("]
    conns = []
    for d, w, n in ports:
        conns.append(f".{n}({n})")
    for k in range(16):
        conns.append(f".i_tagRead_{k}(_tagArray_io_r_resp_data_{k})")
    for k in range(16):
        conns.append(f".i_metaValid_{k}(_metaArray_io_r_resp_data_{k}_valid)")
    for k in range(16):
        conns.append(f".i_metaDirty_{k}(_metaArray_io_r_resp_data_{k}_dirty)")
    conns.append(".i_replState(_replacer_sram_opt_io_r_resp_data_0)")
    conns += [".o_ren(o_ren)", ".o_metaWen(o_metaWen)", ".o_metaWset(o_metaWset)",
              ".o_metaWvalid(o_metaWvalid)", ".o_metaWdirty(o_metaWdirty)",
              ".o_metaWaymask(o_metaWaymask)", ".o_replWen(o_replWen)",
              ".o_replWset(o_replWset)", ".o_replWdata(o_replWdata)"]
    for j, c in enumerate(conns):
        L.append(f"    {c}{',' if j + 1 < len(conns) else ''}")
    L.append("  );")
    return "\n".join(L)


def gen_body(top, ports):
    return ("// 自动生成 scripts/gen_subdirectory1.py —— 勿手改\n"
            + module_header(top, ports)
            + "\n" + lift_decls() + "\n\n"
            + BOUNDARY_DECLS + "\n"
            + core_inst(ports) + "\n\n"
            + lift_instances() + "\n"
            + "endmodule\n")


def gen_tb(ports):
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_subdirectory1.py —— 勿手改")
    L.append("// SubDirectory_1 双例化逐拍比对: golden vs 可读 SubDirectory_1_xs。")
    L.append("// 偏小 set/tag 域促命中/空路/PLRU 替换全覆盖; opcode 偏向更新触发值。")
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
    for inst, pfx in (("SubDirectory_1", "g_"), ("SubDirectory_1_xs", "i_")):
        L.append(f"  {inst} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(ports):
            c = "," if i + 1 < len(ports) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if n == "io_read_valid":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_read_bits_set" or n.endswith("WReq_bits_set"):
            L.append(f"    {n} = $urandom_range(0,15);")
        elif n == "io_read_bits_tag" or n == "io_tagWReq_bits_wtag":
            L.append(f"    {n} = $urandom_range(0,7);")
        elif n == "io_read_bits_replacerInfo_opcode":
            L.append(f"    {n} = ($urandom_range(0,2)==0) ? (($urandom_range(0,1)==0)?7'h7:7'h26) : $urandom_range(0,127);")
        elif n == "io_read_bits_replacerInfo_refill":
            L.append(f"    {n} = ($urandom_range(0,2) == 0);")
        elif n in ("io_metaWReq_valid", "io_tagWReq_valid"):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n in ("io_metaWReq_bits_wmeta_valid", "io_metaWReq_bits_wmeta_dirty"):
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_metaWReq_bits_wayOH":
            L.append(f"    {n} = (16'h1 << $urandom_range(0,15));")
        elif n == "io_tagWReq_bits_way":
            L.append(f"    {n} = $urandom_range(0,15);")
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
    L.append("  int ierr = 0;")
    L.append("  `define IP(GP, IP) begin \\")
    L.append("    if (!$isunknown(u_g.GP)) begin \\")
    L.append("      if (u_g.GP !== u_i.u_core.IP) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 40) $display(\"[%0t] IPROBE-DIFF %s g=%0h i=%0h\", $time, `\"GP`\", u_g.GP, u_i.u_core.IP); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    L.append("  task automatic check_internal();")
    for r in ["resetFinish", "resetIdx", "reqValid_s2", "req_s2_tag", "req_s2_set",
              "reqValid_s3", "req_s3_tag", "req_s3_set",
              "req_s3_replacerInfo_opcode", "req_s3_replacerInfo_refill",
              "repl_state_s3"]:
        L.append(f"    `IP({r}, {r})")
    for k in range(16):
        L.append(f"    `IP(metaAll_s3_{k}_valid, metaAll_s3[{k}].valid)")
        L.append(f"    `IP(metaAll_s3_{k}_dirty, metaAll_s3[{k}].dirty)")
        L.append(f"    `IP(tagAll_s3_{k},        tagAll_s3[{k}])")
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
    L.append("    $display(\"SubDirectory_1 checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = SubDirectory_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/subdirectory1_pkg.sv \\
           $(RTL_DIR)/uncore/SubDirectory_1.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/SubDirectory_1_wrapper.sv

# golden 侧 UT 依赖: golden SubDirectory_1 + 3 SRAM (含叶子阵列)
#   SRAMTemplate_199 -> array_21 (tag)
#   SRAMTemplate_200 -> array_22 (meta)
#   SRAMTemplate_201 -> array_0_0 (replacer)
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory_1.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_199.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_200.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_201.sv \\
              $(GOLDEN_RTL)/array_21.sv $(GOLDEN_RTL)/array_21_ext.v \\
              $(GOLDEN_RTL)/array_22.sv $(GOLDEN_RTL)/array_22_ext.v \\
              $(GOLDEN_RTL)/array_0_0.sv $(GOLDEN_RTL)/array_0_0_ext.v

TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SubDirectory_1 本体, SRAM 两侧均黑盒
FM_VARIANTS = SubDirectory_1
FM_REF_DEPS_SubDirectory_1 =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLD, "SubDirectory_1")
    (RTL / "SubDirectory_1_wrapper.sv").write_text(gen_body("SubDirectory_1", ports))
    (UT / "variants_xs.sv").write_text(gen_body("SubDirectory_1_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated SubDirectory_1 wrapper / variant / tb / Makefile;", len(ports), "ports")


if __name__ == "__main__":
    main()
