#!/usr/bin/env python3
"""生成 LevelGateway 的 wrapper / 变体 / UT testbench / Makefile。

LevelGateway 是单寄存器叶子模块 (无子模块、无 SRAM)，端口均为标量，无需打包。
产物：
  - wrapper (golden 同名 LevelGateway) : FM impl 侧顶层，例化 xs_LevelGateway_core
  - 变体    (LevelGateway_xs)           : UT impl 侧顶层，同样例化 xs_LevelGateway_core
  - tb.sv                               : 双例化逐拍比对
  - Makefile                            : include ut_common.mk
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "LevelGateway"


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
        "// 自动生成：scripts/gen_levelgateway.py —— 勿手改\n"
        + module_header(top, ports)
        + inst("xs_LevelGateway_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(ports):
    return (
        "// 自动生成：scripts/gen_levelgateway.py —— 勿手改\n"
        + module_header("LevelGateway_xs", ports)
        + inst("xs_LevelGateway_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_levelgateway.py —— 勿手改",
        "// LevelGateway 双例化逐拍比对：golden LevelGateway vs 可读重写 LevelGateway_xs。",
        "// 激励：随机驱动 interrupt/ready/complete，覆盖 set(interrupt&ready)、",
        "// hold(在途)、clear(complete) 全部 inFlight 转移。",
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
        gap = " " if width else ""
        lines.append(f"  logic {width}{gap}{name};")
    for _, width, name in outputs:
        gap = " " if width else ""
        lines.append(f"  wire {width}{gap}g_{name};")
        lines.append(f"  wire {width}{gap}i_{name};")
    lines += ["", "  LevelGateway u_g ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"g_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", "", "  LevelGateway_xs u_i ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"i_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  task automatic drive_random_inputs();",
        "    // interrupt 多为电平保持 (偶尔翻转)，ready/complete 随机产生握手脉冲",
        "    if ($urandom_range(0, 3) == 0) io_interrupt = ~io_interrupt;",
        "    io_plic_ready    = $urandom_range(0, 1);",
        "    io_plic_complete = ($urandom_range(0, 3) == 0);  // complete 稀疏",
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
        "    $display(\"LevelGateway checks=%0d errors=%0d\", checks, errors);",
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
    ports = parse_ports(GOLDEN / "LevelGateway.sv", "LevelGateway")
    (RTL / "LevelGateway_wrapper.sv").write_text(gen_wrapper("LevelGateway", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = LevelGateway

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/LevelGateway.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/LevelGateway.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/LevelGateway_wrapper.sv
FM_VARIANTS = LevelGateway

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated LevelGateway wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
