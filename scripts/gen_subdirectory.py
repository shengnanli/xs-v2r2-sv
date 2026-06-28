#!/usr/bin/env python3
"""生成 openLLC SubDirectory(clientDir 实例)的 wrapper / 变体 / UT / Makefile。

SubDirectory 含 3 个黑盒子模块:
  SRAMTemplate_197  tagArray  (10 路 tag SRAM)
  SRAMTemplate_198  metaArray (10 路 meta.valid SRAM)
  MaxPeriodFibonacciLFSR_3    随机替换 LFSR
可读核 xs_SubDirectory_core 只做三级流水的控制/选路逻辑; 上述 3 块从 golden 原样
搬入 wrapper, 把核的 SRAM 读口/控制口与之对接 (与 gen_directory.py 同套方法学)。

  - wrapper (golden 同名 SubDirectory) : FM impl 顶层; 例化核 + 2 SRAM + LFSR
  - 变体    (SubDirectory_xs)          : UT impl 顶层; 内容同 wrapper, 仅模块名不同
  - tb.sv   : 双例化 golden SubDirectory vs SubDirectory_xs, 逐拍随机激励比对
  - Makefile: include ut_common.mk; golden 侧带全 SRAM/LFSR 链, FM 侧黑盒
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "SubDirectory"

GOLD = (GOLDEN / "SubDirectory.sv").read_text()

# golden 实例内部驱动信号名 → wrapper 边界 wire (核的 o_* 输出)
SUBS = [
    ("(_req_s2_T)", "(o_ren)"),
    ("(_GEN[9:0])", "(o_tagWaymask)"),
    ("(io_metaWReq_valid | ~resetFinish)", "(o_metaWen)"),
    ("(resetFinish ? io_metaWReq_bits_set : resetIdx)", "(o_metaWset)"),
    ("(_GEN_0)", "(o_metaWdata)"),
    ("(resetFinish ? io_metaWReq_bits_wayOH : 10'h3FF)", "(o_metaWaymask)"),
]

INST_MODULES = ["SRAMTemplate_197", "SRAMTemplate_198", "MaxPeriodFibonacciLFSR_3"]


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
    """从 golden 搬运 SRAM/LFSR 读出口 wire 声明。"""
    keep = []
    for ln in GOLD.splitlines():
        s = ln.strip()
        if not s.startswith("wire"):
            continue
        if "_tagArray_io_r_resp_data" in s or "_metaArray_io_r_resp_data" in s \
           or "_lfsr_prng_io_out" in s:
            keep.append("  " + s)
    return "\n".join(keep)


def lift_instances():
    """从 golden 搬运 3 个子模块例化, 替换 SRAM 接口驱动信号名为核 o_* 输出。"""
    lines = GOLD.splitlines()
    blocks = []
    i = 0
    while i < len(lines):
        m = re.match(r"\s*(" + "|".join(INST_MODULES) + r")\s+\w+\s*\($", lines[i])
        if m:
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
            blocks.append(txt)
        i += 1
    return "\n".join(blocks)


BOUNDARY_DECLS = """  // ---- 核与 SRAM/LFSR 黑盒的边界 wire (核的 o_* 输出) ----
  wire        o_ren;
  wire [9:0]  o_tagWaymask;
  wire        o_metaWen;
  wire [9:0]  o_metaWset;
  wire        o_metaWdata;
  wire [9:0]  o_metaWaymask;
"""


def core_inst(ports):
    L = ["  xs_SubDirectory_core u_core ("]
    conns = []
    for d, w, n in ports:               # 外部 io 功能端口按名直连
        conns.append(f".{n}({n})")
    for k in range(10):                 # SRAM 读数据入核
        conns.append(f".i_tagRead_{k}(_tagArray_io_r_resp_data_{k})")
    for k in range(10):
        conns.append(f".i_metaValid_{k}(_metaArray_io_r_resp_data_{k}_0_valid)")
    for k in range(7):                  # LFSR 低 7 位入核
        conns.append(f".i_lfsr_{k}(_lfsr_prng_io_out_{k})")
    conns += [".o_ren(o_ren)", ".o_tagWaymask(o_tagWaymask)",
              ".o_metaWen(o_metaWen)", ".o_metaWset(o_metaWset)",
              ".o_metaWdata(o_metaWdata)", ".o_metaWaymask(o_metaWaymask)"]
    for j, c in enumerate(conns):
        L.append(f"    {c}{',' if j + 1 < len(conns) else ''}")
    L.append("  );")
    return "\n".join(L)


def gen_body(top, ports):
    return ("// 自动生成 scripts/gen_subdirectory.py —— 勿手改\n"
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
    L.append("// 自动生成 scripts/gen_subdirectory.py —— 勿手改")
    L.append("// SubDirectory 双例化逐拍比对: golden SubDirectory vs 可读 SubDirectory_xs。")
    L.append("// 偏小 set/tag 域促命中与空路/随机替换路全覆盖。")
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
    for inst, pfx in (("SubDirectory", "g_"), ("SubDirectory_xs", "i_")):
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
            L.append(f"    {n} = $urandom_range(0,15);")      # 小 set 域促碰撞
        elif n == "io_read_bits_tag" or n == "io_tagWReq_bits_wtag":
            L.append(f"    {n} = $urandom_range(0,7);")       # 小 tag 域促命中
        elif n in ("io_metaWReq_valid", "io_tagWReq_valid"):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n == "io_metaWReq_bits_wmeta_0_valid":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_metaWReq_bits_wayOH":
            L.append(f"    {n} = (10'h1 << $urandom_range(0,9));")
        elif n == "io_tagWReq_bits_way":
            L.append(f"    {n} = $urandom_range(0,9);")
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
    # 内部探针: golden 标量 metaValidVec_K/tagAll_s3_K  vs  核数组 metaValidVec[K]/tagAll_s3[K]
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
              "reqValid_s3", "req_s3_tag", "req_s3_set"]:
        L.append(f"    `IP({r}, {r})")
    for k in range(10):
        L.append(f"    `IP(metaValidVec_{k}, metaValidVec[{k}])")
        L.append(f"    `IP(tagAll_s3_{k},    tagAll_s3[{k}])")
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
    L.append("    $display(\"SubDirectory checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = SubDirectory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/subdirectory_pkg.sv \\
           $(RTL_DIR)/uncore/SubDirectory.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/SubDirectory_wrapper.sv

# golden 侧 UT 依赖: golden SubDirectory + 2 SRAM + LFSR (含 SRAM 叶子阵列)
#   SRAMTemplate_197 -> array_19 -> array_19_ext (tag)
#   SRAMTemplate_198 -> array_20 -> array_20_ext (meta)
GOLDEN_SRCS = $(GOLDEN_RTL)/SubDirectory.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_197.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_198.sv \\
              $(GOLDEN_RTL)/array_19.sv $(GOLDEN_RTL)/array_19_ext.v \\
              $(GOLDEN_RTL)/array_20.sv $(GOLDEN_RTL)/array_20_ext.v \\
              $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR_3.sv

TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SubDirectory 本体, SRAM/LFSR 两侧均黑盒
FM_VARIANTS = SubDirectory
FM_REF_DEPS_SubDirectory =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLD, "SubDirectory")
    (RTL / "SubDirectory_wrapper.sv").write_text(gen_body("SubDirectory", ports))
    (UT / "variants_xs.sv").write_text(gen_body("SubDirectory_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated SubDirectory wrapper / variant / tb / Makefile;", len(ports), "ports")


if __name__ == "__main__":
    main()
