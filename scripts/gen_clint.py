#!/usr/bin/env python3
"""生成 CLINT 的 wrapper / 变体 / UT testbench / Makefile。

CLINT 是叶子模块 (无子模块、无 SRAM)，故无需黑盒 stub：
  - wrapper (golden 同名 CLINT)         : FM impl 侧顶层，例化可读核 xs_CLINT_core
  - 变体    (CLINT_xs)                   : UT impl 侧顶层，同样例化 xs_CLINT_core
  - tb.sv                                : 双例化 (golden CLINT vs CLINT_xs) 逐拍比对
  - Makefile                             : include ut_common.mk，UT + FM 共用
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "CLINT"


def parse_ports(path, module):
    text = path.read_text()
    match = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    if not match:
        raise RuntimeError(f"module {module} not found in {path}")
    ports = []
    for raw in match.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        m = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_][A-Za-z0-9_]*)$", line)
        if not m:
            raise RuntimeError(f"cannot parse port line: {raw}")
        direction, width, name = m.groups()
        ports.append((direction, width or "", name))
    return ports


def decl(direction, width, name):
    gap = " " if width else ""
    return f"  {direction} {width}{gap}{name}"


def module_header(name, ports):
    body = ",\n".join(decl(*p) for p in ports)
    return f"module {name}(\n{body}\n);\n"


def inst(module, name, ports, prefix=""):
    lines = [f"  {module} {name} ("]
    for idx, (_, _, port) in enumerate(ports):
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{port}({prefix}{port}){comma}")
    lines.append("  );")
    return "\n".join(lines)


def gen_wrapper(top, ports):
    return (
        "// 自动生成：scripts/gen_clint.py —— 勿手改\n"
        + module_header(top, ports)
        + inst("xs_CLINT_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(ports):
    return (
        "// 自动生成：scripts/gen_clint.py —— 勿手改\n"
        + module_header("CLINT_xs", ports)
        + inst("xs_CLINT_core", "u_core", ports)
        + "\nendmodule\n"
    )


def bit_width(width):
    if not width:
        return 1
    m = re.match(r"\[(\d+):(\d+)\]", width)
    if not m:
        raise RuntimeError(f"bad width {width}")
    hi, lo = map(int, m.groups())
    return abs(hi - lo) + 1


def rand_expr(width):
    bits = bit_width(width)
    if bits == 1:
        return "$urandom_range(0, 1)"
    words = max(1, (bits + 31) // 32)
    concat = ", ".join(["$urandom"] * words)
    return f"{bits}'({{{concat}}})"


def signal_decl(kind, width, name):
    gap = " " if width else ""
    return f"  {kind} {width}{gap}{name};"


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_clint.py —— 勿手改",
        "// CLINT 双例化逐拍比对：golden CLINT vs 可读重写 CLINT_xs。",
        "// 激励含 TileLink A 随机请求 + io_rtcTick；为提高地址命中率，",
        "// 地址在合法寄存器槽 (msip/mtimecmp/mtime) 与全随机之间混合采样。",
        "`timescale 1ns/1ps",
        "`define CHECK(SIG) begin \\",
        "  if (!$isunknown(g_``SIG)) begin \\",
        "    checks++; \\",
        "    if (g_``SIG !== i_``SIG) begin \\",
        "      errors++; \\",
        "      if (errors <= 20) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\",
        "    end \\",
        "  end \\",
        "end",
        "module tb;",
        "  int unsigned NCYCLES = 200000;",
        "  bit clock = 0;",
        "  bit reset;",
        "  int errors = 0;",
        "  int checks = 0;",
        "  always #5 clock = ~clock;",
        "",
    ]
    for _, width, name in inputs:
        lines.append(signal_decl("logic", width, name))
    for _, width, name in outputs:
        lines.append(signal_decl("wire", width, f"g_{name}"))
        lines.append(signal_decl("wire", width, f"i_{name}"))
    lines += ["", "  CLINT u_g ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"g_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", "", "  CLINT_xs u_i ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"i_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  // 合法寄存器字节偏移 (设备内地址)；偏移在 [15:14]/[13:3] 上有意义",
        "  localparam logic [29:0] OFF_MSIP    = 30'h0000;",
        "  localparam logic [29:0] OFF_TIMECMP = 30'h4000;",
        "  localparam logic [29:0] OFF_TIME    = 30'hbff8;",
        "",
        "  function automatic logic [29:0] pick_addr();",
        "    case ($urandom_range(0, 3))",
        "      0: return OFF_MSIP;",
        "      1: return OFF_TIMECMP;",
        "      2: return OFF_TIME;",
        "      default: return 30'($urandom);  // 全随机：覆盖未命中路径",
        "    endcase",
        "  endfunction",
        "",
        "  task automatic drive_random_inputs();",
    ]
    for _, width, name in inputs:
        if name == "auto_in_a_bits_address":
            lines.append(f"    {name} = pick_addr();")
        elif name == "auto_in_a_bits_opcode":
            # 偏向产生读(4)/写(0,1)合法 opcode，兼顾随机
            lines.append(f"    {name} = ($urandom_range(0,1)) ? 4'h4 : 4'($urandom_range(0,1));")
        elif name == "io_rtcTick":
            # rtcTick 大多数拍拉高以快速推进 mtime，少量拍拉低
            lines.append(f"    {name} = ($urandom_range(0, 3) != 0);")
        else:
            lines.append(f"    {name} = {rand_expr(width)};")
    lines += [
        "  endtask",
        "",
        "  task automatic check_outputs();",
    ]
    for _, _, name in outputs:
        lines.append(f"    `CHECK({name})")
    lines += [
        "  endtask",
        "",
        "  initial begin",
        "    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end",
        "    reset = 1'b1;",
    ]
    for _, _, name in inputs:
        lines.append(f"    {name} = '0;")
    lines += [
        "    repeat (8) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        "    $display(\"CLINT checks=%0d errors=%0d\", checks, errors);",
        "    if (errors == 0) begin",
        "      $display(\"TEST PASSED\");",
        "      $finish;",
        "    end",
        "    $display(\"TEST FAILED\");",
        "    $fatal(1);",
        "  end",
        "endmodule",
        "`undef CHECK",
        "",
    ]
    return "\n".join(lines)


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "CLINT.sv", "CLINT")
    (RTL / "CLINT_wrapper.sv").write_text(gen_wrapper("CLINT", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = CLINT

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/clint_pkg.sv \\
           $(RTL_DIR)/uncore/CLINT.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/CLINT.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/CLINT_wrapper.sv
FM_VARIANTS = CLINT

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated CLINT wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
