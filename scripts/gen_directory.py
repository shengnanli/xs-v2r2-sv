#!/usr/bin/env python3
"""生成 coupledL2 L2 目录 Directory 的 wrapper / 变体 / UT / Makefile。

Directory 含 4 块 SRAM 黑盒 (tagArray=SplittedSRAM_2, metaArray/replacer/origin
=SRAMTemplate_141/142/143) + 1 个 MBIST 流水 (L2Directory)。可读核 xs_Directory_core
只做三级流水 + DRRIP + ECC 逻辑, SRAM/MBIST 的例化与互联 (childBd/sigFromSrams 等
结构性 glue) 从 golden 原样搬入 wrapper, 把核与 SRAM 读写口对接。

  - wrapper (golden 同名 Directory) : FM impl 顶层; 例化核 + SRAM 黑盒 + mbistPl
  - 变体    (Directory_xs)          : UT impl 顶层; 内容同 wrapper, 仅模块名不同
  - tb.sv   : 双例化 golden Directory vs Directory_xs, MBIST 置闲, 逐拍随机激励比对
  - Makefile: include ut_common.mk; golden 侧带全 SRAM 链, FM 侧 SRAM 当黑盒
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "Directory"

GOLD = (GOLDEN / "Directory.sv").read_text()

# ---- SRAM 读数据接口替换: golden 内部信号名 → wrapper 边界 wire 名 ----
SUBS = [
    ("(_origin_bits_r_T_probe)", "(ren)"),
    ("(tagWrite)", "(tagWdata)"),
    ("(resetFinish ? next_state_s3 : 16'hAAAA)", "(replWdata)"),
    ("(_GEN_11)", "(replWen)"),
    ("(_GEN_13)", "(replWset)"),
    ("(_GEN_12)", "(originWdata)"),
    ("(8'h1 << way_s3)", "(originWaymask)"),
]

INST_MODULES = ["SplittedSRAM_2", "SRAMTemplate_141", "SRAMTemplate_142",
                "SRAMTemplate_143", "L2Directory"]


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
    """从 golden 搬运 SRAM 侧 wire 声明 (childBd / bd / SRAM resp / bd 别名)。"""
    keep = []
    for ln in GOLD.splitlines():
        s = ln.strip()
        if not s.startswith("wire"):
            continue
        if re.search(r"_(tagArray|metaArray|replacer_sram_opt|origin_bit_opt)_io_r_resp_data", s) \
           or "childBd" in s or re.match(r"wire\s+(\[[^\]]+\]\s+)?bd_(outdata|ack);", s) \
           or re.search(r"bd_\w+\s*=\s*boreChildrenBd_bore_", s):
            keep.append("  " + s)
    return "\n".join(keep)


def lift_instances():
    """从 golden 搬运 5 个子模块例化, 并把 SRAM 接口边界信号名替换为核输出 wire。"""
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


META_FIELDS = ["dirty", "state", "clients", "alias", "prefetch", "prefetchSrc",
               "accessed", "tagErr", "dataErr"]


def core_inst(ports):
    """例化可读核: 功能端口按名直连; SRAM 读口接 golden resp wire; 写控接边界 wire。"""
    L = ["  xs_Directory_core u_core ("]
    conns = []
    # 功能端口 (排除 MBIST; msInfo 仅保留核用到的 5 个字段)
    msinfo_keep = ("_valid", "_bits_set", "_bits_way", "_bits_blockRefill", "_bits_dirHit")
    for d, w, n in ports:
        if n.startswith("boreChildrenBd") or n.startswith("sigFromSrams"):
            continue
        if n.startswith("io_msInfo") and not n.endswith(msinfo_keep):
            continue
        conns.append(f".{n}({n})")
    # SRAM 读数据输入
    for k in range(8):
        conns.append(f".i_tagRead_{k}(_tagArray_io_r_resp_data_{k})")
    for k in range(8):
        cat = ", ".join(f"_metaArray_io_r_resp_data_{k}_{f}" for f in META_FIELDS)
        conns.append(f".i_metaRead_{k}({{{cat}}})")
    conns.append(".i_replRead(_replacer_sram_opt_io_r_resp_data_0)")
    for k in range(8):
        conns.append(f".i_originRead_{k}(_origin_bit_opt_io_r_resp_data_{k})")
    # SRAM 控制输出
    conns += [".o_ren(ren)", ".o_tagWdata(tagWdata)", ".o_replWen(replWen)",
              ".o_replWset(replWset)", ".o_replWdata(replWdata)",
              ".o_originWdata(originWdata)", ".o_originWaymask(originWaymask)"]
    for j, c in enumerate(conns):
        L.append(f"    {c}{',' if j + 1 < len(conns) else ''}")
    L.append("  );")
    return "\n".join(L)


BOUNDARY_DECLS = """  // ---- 核与 SRAM 的边界 wire ----
  wire             ren;
  wire [37:0]      tagWdata;
  wire             replWen;
  wire [8:0]       replWset;
  wire [15:0]      replWdata;
  wire             originWdata;
  wire [7:0]       originWaymask;
"""

TAIL = """  assign boreChildrenBd_bore_ack = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;
endmodule
"""


def gen_body(top, ports):
    return ("// 自动生成 scripts/gen_directory.py —— 勿手改\n"
            + module_header(top, ports)
            + "\n" + lift_decls() + "\n\n"
            + BOUNDARY_DECLS + "\n"
            + core_inst(ports) + "\n\n"
            + lift_instances() + "\n"
            + TAIL)


def gen_tb(ports):
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    mbist_in = lambda n: n.startswith("boreChildrenBd") or n.startswith("sigFromSrams")
    L = []
    L.append("// 自动生成 scripts/gen_directory.py —— 勿手改")
    L.append("// Directory 双例化逐拍比对: golden Directory vs 可读重写 Directory_xs。")
    L.append("// MBIST 端口置闲(req/all/sig 全 0), 偏向小 set/tag 域促成命中与 DRRIP 替换。")
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
    for inst, pfx in (("Directory", "g_"), ("Directory_xs", "i_")):
        L.append(f"  {inst} u_{pfx[0]} (")
        for i, (d, _, n) in enumerate(ports):
            c = "," if i + 1 < len(ports) else ""
            sig = n if (n in ("clock", "reset") or d == "input") else f"{pfx}{n}"
            L.append(f"    .{n}({sig}){c}")
        L.append("  );")
    L.append("")
    # 随机激励: 功能输入随机(偏小域), MBIST 输入恒 0
    L.append("  task automatic drive_random();")
    for _, w, n in ins:
        nb = width_bits(w)
        if mbist_in(n):
            L.append(f"    {n} = '0;")
        elif n == "io_read_valid":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_read_bits_set" or n.endswith("WReq_bits_set"):
            L.append(f"    {n} = $urandom_range(0,15);")      # 小 set 域促碰撞
        elif n.startswith("io_msInfo") and n.endswith("_bits_set"):
            L.append(f"    {n} = $urandom_range(0,15);")
        elif n == "io_read_bits_tag" or n == "io_tagWReq_bits_wtag":
            L.append(f"    {n} = $urandom_range(0,7);")       # 小 tag 域促命中
        elif n in ("io_metaWReq_valid", "io_tagWReq_valid"):
            L.append(f"    {n} = ($urandom_range(0,3) == 0);")
        elif n == "io_read_bits_refill":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_read_bits_cmoAll":
            L.append(f"    {n} = ($urandom_range(0,7) == 0);")
        elif n == "io_metaWReq_bits_wmeta_state":
            L.append(f"    {n} = $urandom_range(0,3);")        # 含 INVALID/有效
        elif n == "io_metaWReq_bits_wayOH":
            L.append(f"    {n} = (8'h1 << $urandom_range(0,7));")
        elif n.startswith("io_msInfo") and n.endswith("_valid"):
            L.append(f"    {n} = ($urandom_range(0,2) == 0);")
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
    # 内部 FSM 层次探针 (同名标量寄存器/线网)
    L.append("  int ierr = 0;")
    L.append("  `define IPROBE(PATH) begin \\")
    L.append("    if (!$isunknown(u_g.``PATH)) begin \\")
    L.append("      if (u_g.``PATH !== u_i.u_core.``PATH) begin \\")
    L.append("        ierr++; \\")
    L.append("        if (ierr <= 30) $display(\"[%0t] IPROBE-DIFF %s g=%0h i=%0h\", $time, `\"PATH`\", u_g.``PATH, u_i.u_core.``PATH); \\")
    L.append("      end \\")
    L.append("    end \\")
    L.append("  end")
    iregs = ["resetFinish", "resetIdx", "reqValid_s2", "reqValid_s3",
             "refillReqValid_s2", "refillReqValid_s3", "req_s3_set", "req_s3_tag",
             "repl_state_s3", "PSEL", "freeWayMask_s3", "REG",
             "hit_s3", "way_s3", "finalWay", "chosenWay", "replaceWay", "replacerWen"]
    L.append("  task automatic check_internal();")
    for r in iregs:
        L.append(f"    `IPROBE({r})")
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
    L.append("    $display(\"Directory checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = Directory

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/directory_pkg.sv \\
           $(RTL_DIR)/uncore/Directory.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/Directory_wrapper.sv

# golden 侧 UT 依赖: golden Directory + 全 SRAM 链 + MBIST 流水
GOLDEN_SRCS = $(GOLDEN_RTL)/Directory.sv \\
              $(GOLDEN_RTL)/SplittedSRAM_2.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_137.sv $(GOLDEN_RTL)/SRAMTemplate_139.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_141.sv $(GOLDEN_RTL)/SRAMTemplate_142.sv \\
              $(GOLDEN_RTL)/SRAMTemplate_143.sv \\
              $(GOLDEN_RTL)/sram_array_1p512x76m19s1h0l1b_l2_tag.sv \\
              $(GOLDEN_RTL)/sram_array_1p512x104m13s1h0l1b_l2_meta.sv \\
              $(GOLDEN_RTL)/sram_array_1p512x16m16s1h0l1b_l2_repl.sv \\
              $(GOLDEN_RTL)/sram_array_1p512x8m1s1h0l1b_l2_orgb.sv \\
              $(GOLDEN_RTL)/array_14.sv $(GOLDEN_RTL)/array_14_ext.v \\
              $(GOLDEN_RTL)/array_15.sv $(GOLDEN_RTL)/array_15_ext.v \\
              $(GOLDEN_RTL)/array_16.sv $(GOLDEN_RTL)/array_16_ext.v \\
              $(GOLDEN_RTL)/array_17.sv $(GOLDEN_RTL)/array_17_ext.v \\
              $(GOLDEN_RTL)/L2Directory.sv

TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden Directory 本体, SRAM/mbist 两侧均黑盒
FM_VARIANTS = Directory
FM_REF_DEPS_Directory =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLD, "Directory")
    (RTL / "Directory_wrapper.sv").write_text(gen_body("Directory", ports))
    (UT / "variants_xs.sv").write_text(gen_body("Directory_xs", ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(MAKEFILE)
    print("generated Directory wrapper / variant / tb / Makefile;", len(ports), "ports")


if __name__ == "__main__":
    main()
