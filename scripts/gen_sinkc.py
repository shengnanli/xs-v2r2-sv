#!/usr/bin/env python3
"""生成 coupledL2 SinkC (TileLink C 通道接收器) 的 wrapper / 变体 / UT / Makefile。

可读核 xs_SinkC_core 内含全部 SinkC 逻辑 + RRArbiterInit_14 (4 入 1 出轮询仲裁) 黑盒例化;
4 个 taskBuf 表项逐字段保留为寄存器 (与 golden 同名) 喂给仲裁器, 出口 io_task_bits_* 由
仲裁器直接驱动。因此 wrapper / 变体均为「与 golden 同端口的薄壳」, 仅例化核:
  - wrapper (golden 同名 SinkC) : FM impl 顶层
  - 变体    (SinkC_xs)          : UT impl 顶层 (内容同 wrapper, 仅模块名不同)
  - tb.sv   : 双例化逐拍比对 + 内部状态探针
  - Makefile: golden 侧带 RRArbiterInit_14; FM 侧仲裁器两边均黑盒
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "SinkC"

# taskBuf 中 SinkC 真正会写非零/变化值的字段 (内部探针重点); 其余字段 toTaskBundle 恒置 0
MEANINGFUL = ["channel", "set", "tag", "off", "opcode", "param", "size",
              "sourceId", "bufIdx", "denied", "corrupt", "wayMask"]


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


def gen_wrapper(top, ports):
    """薄壳: 与 golden 同端口, 仅例化核 (核内含仲裁器)。"""
    L = ["// 自动生成 scripts/gen_sinkc.py —— 勿手改", module_header(top, ports), ""]
    L.append("  xs_SinkC_core u_core (")
    conns = []
    for d, w, n in ports:
        conns.append(f".{n}({n})")
    for j, c in enumerate(conns):
        L.append(f"    {c}{',' if j + 1 < len(conns) else ''}")
    L.append("  );")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


# golden 内部信号名 -> 可读核层次名 (内部探针)
def probe_pairs():
    pairs = []
    for k in range(4):
        for b in range(2):
            pairs.append((f"dataBuf_{k}_{b}", f"dataBuf[{k}][{b}]"))
            pairs.append((f"beatValids_{k}_{b}", f"beatValids[{k}][{b}]"))
    for k in range(4):
        for f in MEANINGFUL:
            pairs.append((f"taskBuf_{k}_{f}", f"taskBuf_{k}_{f}"))
        pairs.append((f"taskValids_{k}", f"taskValids[{k}]"))
    pairs += [
        ("r_counter", "r_counter"),
        ("nextPtrReg", "nextPtrReg"),
        ("probeAckDataBuf", "probeAckDataBuf"),
        ("r_0", "r_0"), ("r_1", "r_1"),
        ("REG_0", "REG_0"), ("REG_1", "REG_1"),
        ("REG_1_0", "REG_1_0"), ("REG_2", "REG_2"),
        ("io_refillBufWrite_valid_REG", "io_refillBufWrite_valid_REG"),
        ("io_refillBufWrite_bits_id_REG", "io_refillBufWrite_bits_id_REG"),
        ("io_refillBufWrite_bits_data_data_REG", "io_refillBufWrite_bits_data_data_REG"),
    ]
    return pairs


def gen_tb(ports):
    ins = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in ports if p[0] == "output"]
    L = []
    L.append("// 自动生成 scripts/gen_sinkc.py —— 勿手改")
    L.append("// SinkC 双例化逐拍比对: golden SinkC vs 可读重写 SinkC_xs。")
    L.append("// 偏 Release/ProbeAck 与偏小 set/tag 促成缓冲分配与 msInfo 命中。")
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
    for instname, pfx in (("SinkC", "g_"), ("SinkC_xs", "i_")):
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
        if n == "io_c_valid":
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_task_ready":
            L.append(f"    {n} = ($urandom_range(0,2) != 0);")
        elif n == "io_c_bits_opcode":
            # 偏向 C 通道合法 opcode (ProbeAck=4 / ProbeAckData=5 / Release=6 / ReleaseData=7)
            L.append(f"    {n} = 3'h4 | $urandom_range(0,3);")
        elif n == "io_c_bits_size":
            # 偏 size=6 (满块, 两拍) 与小 size (单拍) 混合
            L.append(f"    {n} = ($urandom_range(0,1) == 0) ? 3'h6 : $urandom_range(0,6);")
        elif n.endswith("_valid"):  # msInfo valid
            L.append(f"    {n} = ($urandom_range(0,1) == 0);")
        elif n == "io_c_bits_address":
            # 偏小 tag/set 促 msInfo 命中 (set=addr[16:8], tag=addr[47:17])
            L.append(f"    {n} = {{31'h0, $urandom_range(0,3), 8'h0, $urandom_range(0,63)}};")
        elif n.endswith("_bits_set"):
            L.append(f"    {n} = $urandom_range(0,3);")
        elif n.endswith("_bits_reqTag"):
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
    for gp, ip in probe_pairs():
        L.append(f"    `IP({gp}, {ip})")
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
    L.append("    $display(\"SinkC checks=%0d errors=%0d ierr=%0d\", checks, errors, ierr);")
    L.append("    if (errors == 0 && ierr == 0) begin $display(\"TEST PASSED\"); $finish; end")
    L.append("    $display(\"TEST FAILED\"); $fatal(1);")
    L.append("  end")
    L.append("endmodule")
    L.append("`undef CHK")
    L.append("`undef IP")
    L.append("")
    return "\n".join(L)


MAKEFILE = """MODULE = SinkC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/sinkc_pkg.sv $(RTL_DIR)/uncore/SinkC.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/SinkC_wrapper.sv

# 核内例化 RRArbiterInit_14: UT/变体编译与 golden 比对都需要它
GOLDEN_SRCS = $(GOLDEN_RTL)/SinkC.sv $(GOLDEN_RTL)/RRArbiterInit_14.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SinkC 本体, RRArbiterInit_14 两侧均黑盒
FM_VARIANTS = SinkC
FM_REF_DEPS_SinkC =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    top_ports = parse_ports(GOLDEN / "SinkC.sv", "SinkC")
    (RTL / "SinkC_wrapper.sv").write_text(gen_wrapper("SinkC", top_ports))
    (UT / "variants_xs.sv").write_text(gen_wrapper("SinkC_xs", top_ports))
    (UT / "tb.sv").write_text(gen_tb(top_ports))
    (UT / "Makefile").write_text(MAKEFILE)
    print(f"generated SinkC wrapper / variant / tb / Makefile; {len(top_ports)} top ports")


if __name__ == "__main__":
    main()
