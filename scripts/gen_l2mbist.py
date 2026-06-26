#!/usr/bin/env python3
"""生成 L2 MBIST 流水分发节点 (L2Slice / L2Directory / L2DataStorage) 的
wrapper / 变体 / UT testbench / Makefile。

这三者都是 utility.mbist.MbistPipeline 的单态化实例 (见 mbist_pipe_pkg 说明)，
是纯寄存器+组合的叶子 (无子模块、无 SRAM)，故无需黑盒 stub：
  - wrapper (golden 同名 <M>)  : FM impl 侧顶层，例化可读核 xs_<M>_core
  - 变体    (<M>_xs)            : UT impl 侧顶层，同样例化 xs_<M>_core
  - tb.sv                       : 双例化 (golden <M> vs <M>_xs) 逐拍比对
  - Makefile                    : include ut_common.mk

下游侧的 *_ack / *_rdata / *_outdata 是输入 (子树/SRAM 的回送)，TB 随机驱动；
其余 output 端口逐拍比对。reset 后跑 NCYCLES 拍。
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"

# 各模块共享的核心 RTL 依赖
COMMON_RTL = ["mbist_pipe_pkg.sv", "mbist_pipe_ctrl.sv"]

MODULES = {
    "L2Slice":       "L2Slice.sv",
    "L2Directory":   "L2Directory.sv",
    "L2DataStorage": "L2DataStorage.sv",
}


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


def gen_wrapper(top, core, ports):
    return (
        "// 自动生成：scripts/gen_l2mbist.py —— 勿手改\n"
        + module_header(top, ports)
        + inst(core, "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(top, core, ports):
    return (
        "// 自动生成：scripts/gen_l2mbist.py —— 勿手改\n"
        + module_header(f"{top}_xs", ports)
        + inst(core, "u_core", ports)
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


def array_choices(module):
    """返回该模块合法 mbist_array 编号列表，便于 TB 偏向命中。"""
    if module == "L2Slice":
        return list(range(0x2, 0x10 + 1))
    if module == "L2Directory":
        return list(range(0x2, 0x8 + 1))
    if module == "L2DataStorage":
        return list(range(0x9, 0x10 + 1))
    return []


def gen_tb(module, ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    choices = array_choices(module)
    arr_width = next((bit_width(w) for d, w, n in ports if n == "mbist_array"), 5)
    lines = [
        "// 自动生成：scripts/gen_l2mbist.py —— 勿手改",
        f"// {module} 双例化逐拍比对：golden {module} vs 可读重写 {module}_xs。",
        "// 激励：mbist 请求 (req/all/readen/writeen/array/addr/data/be) 随机，",
        "//       array 偏向落在合法编号上以充分覆盖各 child 的 spread 分支；",
        "//       下游回送 (*_ack/*_rdata/*_outdata) 随机驱动。逐拍比对全部 output。",
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
    lines += ["", f"  {module} u_g ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"g_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", "", f"  {module}_xs u_i ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"i_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", ""]
    # 合法 array 编号选择函数
    case_lines = []
    for i, c in enumerate(choices):
        case_lines.append(f"      {i}: return {arr_width}'h{c:x};")
    lines += [
        f"  function automatic logic [{arr_width-1}:0] pick_array();",
        f"    case ($urandom_range(0, {len(choices)}))",
    ] + case_lines + [
        f"      default: return {arr_width}'($urandom);  // 全随机：覆盖未命中路径",
        "    endcase",
        "  endfunction",
        "",
        "  task automatic drive_random_inputs();",
    ]
    for _, width, name in inputs:
        if name == "mbist_array":
            lines.append(f"    {name} = pick_array();")
        elif name in ("mbist_req", "mbist_all", "mbist_readen", "mbist_writeen"):
            # 偏向拉高以多触发 activated / dataValid
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
        f"    $display(\"{module} checks=%0d errors=%0d\", checks, errors);",
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


def gen_makefile(module, src):
    common = " \\\n           ".join(f"$(RTL_DIR)/uncore/{f}" for f in COMMON_RTL)
    return f"""MODULE = {module}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = {common} \\
           $(RTL_DIR)/uncore/{src}

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/{module}.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/{module}_wrapper.sv
FM_VARIANTS = {module}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    sel = sys.argv[1:] or list(MODULES.keys())
    for module in sel:
        src = MODULES[module]
        core = f"xs_{module}_core"
        ut = ROOT / "verif" / "ut" / module
        ut.mkdir(parents=True, exist_ok=True)
        ports = parse_ports(GOLDEN / f"{module}.sv", module)
        (RTL / f"{module}_wrapper.sv").write_text(gen_wrapper(module, core, ports))
        (ut / "variants_xs.sv").write_text(gen_variant(module, core, ports))
        (ut / "tb.sv").write_text(gen_tb(module, ports))
        (ut / "Makefile").write_text(gen_makefile(module, src))
        print(f"generated {module} wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
