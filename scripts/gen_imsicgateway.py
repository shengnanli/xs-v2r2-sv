#!/usr/bin/env python3
"""生成 IMSICGateWay 的 wrapper / 变体 / UT testbench / Makefile。

IMSICGateWay 端口均为标量，无需打包；含一个子例化 (3 级异步复位同步链
AsyncResetSynchronizerShiftReg_w1_d3_i0)：
  - UT  : 把 golden 同步链 (及其子模块) 编入两侧，行为完全一致 ⇒ 可逐拍比对；
  - FM  : 同步链当黑盒 (hdlin_unresolved_modules black_box)，比对 GateWay 自身逻辑。

产物：
  - wrapper (golden 同名 IMSICGateWay) : FM impl 侧顶层，例化 xs_IMSICGateWay_core
  - 变体    (IMSICGateWay_xs)           : UT impl 侧顶层，同样例化 xs_IMSICGateWay_core
  - tb.sv                               : 双例化逐拍比对
  - Makefile                            : include ut_common.mk
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "IMSICGateWay"


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
        "// 自动生成：scripts/gen_imsicgateway.py —— 勿手改\n"
        + module_header(top, ports)
        + inst("xs_IMSICGateWay_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(ports):
    return (
        "// 自动生成：scripts/gen_imsicgateway.py —— 勿手改\n"
        + module_header("IMSICGateWay_xs", ports)
        + inst("xs_IMSICGateWay_core", "u_core", ports)
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
    return f"{bits}'($urandom)"


def signal_decl(kind, width, name):
    gap = " " if width else ""
    return f"  {kind} {width}{gap}{name};"


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    lines = [
        "// 自动生成：scripts/gen_imsicgateway.py —— 勿手改",
        "// IMSICGateWay 双例化逐拍比对：golden IMSICGateWay vs 可读重写 IMSICGateWay_xs。",
        "// 激励：随机驱动 msiio_vld_req / msiio_data；req 在 0/1 间随机翻转以产生",
        "// 上升沿 (锁存) 与非上升沿 (清脉冲) 两类拍。两侧共享真实 3 级同步链。",
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
    lines += ["", "  IMSICGateWay u_g ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"g_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", "", "  IMSICGateWay_xs u_i ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"i_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  task automatic drive_random_inputs();",
        "    // req 大多保持、偶尔翻转，制造稀疏上升沿；data 全随机",
    ]
    for _, width, name in inputs:
        if name == "msiio_vld_req":
            lines.append(f"    if ($urandom_range(0, 2) == 0) {name} = ~{name};")
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
        "    $display(\"IMSICGateWay checks=%0d errors=%0d\", checks, errors);",
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
    ports = parse_ports(GOLDEN / "IMSICGateWay.sv", "IMSICGateWay")
    (RTL / "IMSICGateWay_wrapper.sv").write_text(gen_wrapper("IMSICGateWay", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = IMSICGateWay

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 (进 FM impl 侧)。3 级异步复位同步链不放这里：FM 时 golden 侧把它当黑盒，
# impl 侧也须当黑盒 (二者同名同端口) 才能对齐；故同步链只在 UT 编译里随 GOLDEN_SRCS
# 编入两侧 (行为一致逐拍可比)，FM 不引用 ⇒ 自动黑盒化。
RTL_SRCS = $(RTL_DIR)/uncore/imsic_pkg.sv \\
           $(RTL_DIR)/uncore/IMSICGateWay.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden RTL：golden GateWay + 真实 3 级同步链 (仅 UT，不进 FM)
GOLDEN_SRCS = $(GOLDEN_RTL)/IMSICGateWay.sv \\
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \\
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/IMSICGateWay_wrapper.sv
FM_VARIANTS = IMSICGateWay

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated IMSICGateWay wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
