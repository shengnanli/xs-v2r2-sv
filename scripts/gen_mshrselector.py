#!/usr/bin/env python3
"""生成 MSHRSelector 的 wrapper / 变体 / UT testbench / Makefile。

MSHRSelector 是 coupledL2 (L2 缓存) MSHRCtl 内的纯组合优先选择器叶子
(无子模块、无 SRAM、无寄存器)：15 个 idle 输入 -> 16 位 one-hot 分配指针。
故无需黑盒 stub：
  - wrapper (golden 同名 MSHRSelector) : FM impl 侧顶层，例化可读核 xs_MSHRSelector_core
  - 变体    (MSHRSelector_xs)           : UT impl 侧顶层，同样例化 xs_MSHRSelector_core
  - tb.sv                               : 双例化 (golden MSHRSelector vs _xs) 逐拍比对
  - Makefile                            : include ut_common.mk
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "MSHRSelector"


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
        "// 自动生成：scripts/gen_mshrselector.py —— 勿手改\n"
        + module_header(top, ports)
        + inst("xs_MSHRSelector_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(ports):
    return (
        "// 自动生成：scripts/gen_mshrselector.py —— 勿手改\n"
        + module_header("MSHRSelector_xs", ports)
        + inst("xs_MSHRSelector_core", "u_core", ports)
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


def signal_decl(kind, width, name):
    gap = " " if width else ""
    return f"  {kind} {width}{gap}{name};"


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input"]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_mshrselector.py —— 勿手改",
        "// MSHRSelector 双例化逐拍比对：golden MSHRSelector vs 可读重写 MSHRSelector_xs。",
        "// 纯组合优先选择器：15 个 idle 输入随机，比对 16 位 one-hot 输出 io_out_bits。",
        "// 激励混合：全随机 idle + 偏向稀疏 (单/双 idle) 以覆盖各优先级分支。",
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
        "  logic [14:0] idle_vec;   // 打包 15 个 idle 输入",
        "",
    ]
    for _, width, name in inputs:
        lines.append(signal_decl("logic", width, name))
    for _, width, name in outputs:
        lines.append(signal_decl("wire", width, f"g_{name}"))
        lines.append(signal_decl("wire", width, f"i_{name}"))
    lines += ["", "  MSHRSelector u_g ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"g_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", "", "  MSHRSelector_xs u_i ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"i_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  // 按概率生成 idle 向量：稀疏 (强调优先级链尾) / 稠密 / 全随机混合",
        "  function automatic logic [14:0] pick_idle();",
        "    logic [14:0] v;",
        "    case ($urandom_range(0, 3))",
        "      0: begin  // 单个 idle (随机下标)",
        "        v = 15'h0;",
        "        v[$urandom_range(0, 14)] = 1'b1;",
        "      end",
        "      1: begin  // 全不空闲 -> 命中兜底槽 (输出应为 16'h8000)",
        "        v = 15'h0;",
        "      end",
        "      2: v = 15'($urandom) & 15'($urandom);  // 稀疏随机",
        "      default: v = 15'($urandom);            // 全随机",
        "    endcase",
        "    return v;",
        "  endfunction",
        "",
        "  task automatic drive_random_inputs();",
        "    idle_vec = pick_idle();",
    ]
    # 逐位驱动 io_idle_N
    for _, _, name in inputs:
        m = re.match(r"io_idle_(\d+)$", name)
        if m:
            idx = int(m.group(1))
            lines.append(f"    {name} = idle_vec[{idx}];")
        else:
            lines.append(f"    {name} = $urandom;")
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
        "    repeat (4) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      #1 check_outputs();",   # 纯组合：同拍 settle 后即可比对
        "      @(posedge clock);",
        "    end",
        "    $display(\"MSHRSelector checks=%0d errors=%0d\", checks, errors);",
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
    ports = parse_ports(GOLDEN / "MSHRSelector.sv", "MSHRSelector")
    (RTL / "MSHRSelector_wrapper.sv").write_text(gen_wrapper("MSHRSelector", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = MSHRSelector

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/mshrselector_pkg.sv \\
           $(RTL_DIR)/uncore/MSHRSelector.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRSelector.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/MSHRSelector_wrapper.sv
FM_VARIANTS = MSHRSelector

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated MSHRSelector wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
