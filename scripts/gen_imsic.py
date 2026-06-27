#!/usr/bin/env python3
"""生成 IMSIC 的 wrapper / 变体 / UT testbench / Makefile。

IMSIC 端口均为标量 (与 golden 一致)，故 wrapper/变体直接同名透传例化 xs_IMSIC_core。
子例化:
  - IMSICGateWay (MSI 入口握手) : 已重写核, UT 编入真实块, FM 当黑盒;
  - IntFile ×7 (中断文件)        : golden 黑盒, UT 编入真实块, FM 当黑盒。
FM 时 IntFile / IMSICGateWay 只出现在 golden 侧 (GOLDEN_SRCS), 不进 RTL_SRCS/
WRAPPER_SRCS ⇒ impl 侧自动黑盒, ref 侧同名黑盒, 比对聚焦 IMSIC 自身路由/聚合逻辑。

产物:
  - wrapper (golden 同名 IMSIC) : FM impl 侧顶层，例化 xs_IMSIC_core
  - 变体    (IMSIC_xs)          : UT impl 侧顶层，同样例化 xs_IMSIC_core
  - tb.sv                       : 双例化逐拍比对
  - Makefile                    : include ut_common.mk
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "IMSIC"


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
        "// 自动生成：scripts/gen_imsic.py —— 勿手改\n"
        + module_header(top, ports)
        + inst("xs_IMSIC_core", "u_core", ports)
        + "\nendmodule\n"
    )


def gen_variant(ports):
    return (
        "// 自动生成：scripts/gen_imsic.py —— 勿手改\n"
        + module_header("IMSIC_xs", ports)
        + inst("xs_IMSIC_core", "u_core", ports)
        + "\nendmodule\n"
    )


def bit_width(width):
    if not width:
        return 1
    m = re.match(r"\[(\d+):(\d+)\]", width)
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
        "// 自动生成：scripts/gen_imsic.py —— 勿手改",
        "// IMSIC 双例化逐拍比对: golden IMSIC vs 可读重写 IMSIC_xs。",
        "// 激励: fromCSR 访问 (privilege/virt/vgein 偏向合法组合: M/S/VS), 读/写/claim;",
        "// msiio MSI 投递 (vld_req 稀疏翻转产生上升沿, data 含目标文件号+源号)。",
        "// 两侧共享真实 IntFile×7 + IMSICGateWay (+3 级同步链)。",
        "`timescale 1ns/1ps",
        "`define CHECK(SIG) begin \\",
        "  if (!$isunknown(g_``SIG)) begin \\",
        "    checks++; \\",
        "    if (g_``SIG !== i_``SIG) begin \\",
        "      errors++; \\",
        "      if (errors <= 30) $display(\"[%0t] MISMATCH %s g=%0h i=%0h\", $time, `\"SIG`\", g_``SIG, i_``SIG); \\",
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
    lines += ["", "  IMSIC u_g ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"g_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += ["  );", "", "  IMSIC_xs u_i ("]
    for idx, (direction, _, name) in enumerate(ports):
        sig = name if direction == "input" else f"i_{name}"
        comma = "," if idx + 1 < len(ports) else ""
        lines.append(f"    .{name}({sig}){comma}")
    lines += [
        "  );",
        "",
        "  // 选一组合法的 {priv, virt, vgein} 以提高文件命中率",
        "  task automatic pick_priv();",
        "    case ($urandom_range(0, 3))",
        "      0: begin fromCSR_addr_bits_priv = 2'h3; fromCSR_addr_bits_virt = 1'b0; end // M",
        "      1: begin fromCSR_addr_bits_priv = 2'h1; fromCSR_addr_bits_virt = 1'b0; end // S",
        "      2: begin // VS: priv=S, virt=1, vgein∈[1,5]",
        "        fromCSR_addr_bits_priv = 2'h1; fromCSR_addr_bits_virt = 1'b1;",
        "        fromCSR_vgein = 6'($urandom_range(1, 5));",
        "      end",
        "      default: begin // 随机 (覆盖非法路径)",
        "        fromCSR_addr_bits_priv = 2'($urandom);",
        "        fromCSR_addr_bits_virt = $urandom_range(0,1);",
        "        fromCSR_vgein = 6'($urandom_range(0, 7));",
        "      end",
        "    endcase",
        "  endtask",
        "",
        "  task automatic drive_random_inputs();",
        "    pick_priv();",
        "    fromCSR_addr_valid      = $urandom_range(0, 1);",
        "    fromCSR_addr_bits_addr  = 12'($urandom);",
        "    fromCSR_wdata_valid     = $urandom_range(0, 1);",
        "    fromCSR_wdata_bits_op   = 2'($urandom);",
        "    fromCSR_wdata_bits_data = {$urandom, $urandom};",
        "    fromCSR_claims_0        = $urandom_range(0, 1);",
        "    fromCSR_claims_1        = $urandom_range(0, 1);",
        "    fromCSR_claims_2        = $urandom_range(0, 1);",
        "    // MSI: vld_req 稀疏翻转 (产生上升沿), data = {文件号[10:8], 源号[7:0]}",
        "    if ($urandom_range(0, 2) == 0) msiio_vld_req = ~msiio_vld_req;",
        "    msiio_data = {3'($urandom_range(0, 6)), 8'($urandom)};",
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
        "    $display(\"IMSIC checks=%0d errors=%0d\", checks, errors);",
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
    ports = parse_ports(GOLDEN / "IMSIC.sv", "IMSIC")
    (RTL / "IMSIC_wrapper.sv").write_text(gen_wrapper("IMSIC", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(
        """MODULE = IMSIC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + 依赖的已重写 IMSICGateWay 核 + pkg。
# IntFile / IMSICGateWay 子块: FM 时由 golden 侧黑盒, impl 侧也黑盒 (不引用其体);
#   IMSICGateWay 的可读核仅 UT 需要 (golden IMSICGateWay 真块编入两侧)。
RTL_SRCS = $(RTL_DIR)/uncore/imsic_pkg.sv \\
           $(RTL_DIR)/uncore/IMSIC.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden RTL: IMSIC + IntFile×7 + IMSICGateWay + 3 级同步链
GOLDEN_SRCS = $(GOLDEN_RTL)/IMSIC.sv \\
              $(GOLDEN_RTL)/IntFile.sv \\
              $(GOLDEN_RTL)/IMSICGateWay.sv \\
              $(GOLDEN_RTL)/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \\
              $(GOLDEN_RTL)/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/IMSIC_wrapper.sv
FM_VARIANTS = IMSIC
# FM: IntFile / IMSICGateWay 不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box
# 自动在 ref/impl 两侧黑盒化, 比对聚焦 IMSIC 自身选择/路由/聚合逻辑。
# (故 FM_REF_DEPS_IMSIC 留空, ref 侧只读 IMSIC.sv)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    )
    print("generated IMSIC wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
