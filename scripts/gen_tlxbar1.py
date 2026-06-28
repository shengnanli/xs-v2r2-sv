#!/usr/bin/env python3
"""生成 TLXbar_1 的 wrapper / 变体 / UT testbench / Makefile。

TLXbar_1 是 2 主 × 3 从 多主 TileLink 交叉开关 (叶子模块, 无子例化), 支持多拍 burst:
  out_0 = OUT_MEM   req=address[48], 49 位全址;
  out_1 = OUT_MMIO  外设/MMIO (AXI 桥), 31 位地址, 带 AMBA prot;
  out_2 = OUT_DEV   片上设备 (CLINT/PLIC 等), 30 位地址。
端口全为标量/向量, wrapper/变体直接同名透传例化 xs_TLXbar_1_core。

UT: golden TLXbar_1 vs 可读 TLXbar_1_xs 双例化:
  · 两主口 A 地址按 OUT_MEM/OUT_MMIO/OUT_DEV/全随机 四向偏置 (覆盖三条路由 + A 仲裁两路争用);
  · A/D size 偏向 0..6 (覆盖 burst beatsLeft 装入/递减);
  · 三从口 D source 偏向 0..0x3FFF / 0x4000 (覆盖 D→主口 路由 DOI + D 仲裁);
逐拍比对全部输出。FM: ref=golden 叶子, impl=pkg + 可读核 + wrapper。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "TLXbar_1"

CORE = "xs_TLXbar_1_core"
TOP = "TLXbar_1"
VARIANT = "TLXbar_1_xs"

MMIO_BASES = ["49'h0000000000000", "49'h0000020000000", "49'h0000038011000",
              "49'h000003a001000", "49'h0000040000000"]
DEV_BASES = ["49'h0000038000000", "49'h0000038020000",
             "49'h000003a000000", "49'h000003c000000"]


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
        m = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        if not m:
            raise RuntimeError(f"cannot parse port line: {raw}")
        d, w, n = m.groups()
        ports.append((d, w or "", n))
    return ports


def decl(d, w, n):
    gap = " " if w else ""
    return f"  {d} {w}{gap}{n}"


def header(name, ports):
    return f"module {name}(\n" + ",\n".join(decl(*p) for p in ports) + "\n);\n"


def inst(module, name, ports):
    lines = [f"  {module} {name} ("]
    for i, (_, _, p) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{p}({p}){c}")
    lines.append("  );")
    return "\n".join(lines)


def gen_wrapper(ports):
    return ("// 自动生成：scripts/gen_tlxbar1.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_tlxbar1.py —— 勿手改\n"
            + header(VARIANT, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def bit_width(w):
    if not w:
        return 1
    hi, lo = map(int, re.match(r"\[(\d+):(\d+)\]", w).groups())
    return abs(hi - lo) + 1


def rand_expr(w):
    b = bit_width(w)
    if b == 1:
        return "$urandom_range(0, 1)"
    words = max(1, (b + 31) // 32)
    return f"{b}'({{{', '.join(['$urandom'] * words)}}})"


def sdecl(kind, w, n):
    gap = " " if w else ""
    return f"  {kind} {w}{gap}{n};"


def gen_tb(ports):
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_tlxbar1.py —— 勿手改",
        "// TLXbar_1 双例化逐拍比对: golden TLXbar_1 vs 可读 TLXbar_1_xs。",
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
    for _, w, n in inputs:
        L.append(sdecl("logic", w, n))
    for _, w, n in outputs:
        L.append(sdecl("wire", w, f"g_{n}"))
        L.append(sdecl("wire", w, f"i_{n}"))
    L += ["", f"  {TOP} u_g ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"g_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", "", f"  {VARIANT} u_i ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"i_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", ""]

    L.append("  task automatic drive_random_inputs();")
    L.append("    int unsigned sel;")
    for _, w, n in inputs:
        if n.endswith("_a_bits_address"):
            # OUT_MEM(bit48) / OUT_MMIO / OUT_DEV / 全随机 四向偏置
            L.append("    sel = $urandom_range(0, 3);")
            L.append(f"    if (sel == 0) {n} <= 49'h1000000000000 | 49'($urandom);")
            L.append("    else if (sel == 1) begin")
            L.append("      case ($urandom_range(0, 4))")
            for i, b in enumerate(MMIO_BASES):
                L.append(f"        {i}: {n} <= {b} + $urandom_range(0, 4095);")
            L.append("      endcase")
            L.append("    end else if (sel == 2) begin")
            L.append("      case ($urandom_range(0, 3))")
            for i, b in enumerate(DEV_BASES):
                L.append(f"        {i}: {n} <= {b} + $urandom_range(0, 4095);")
            L.append("      endcase")
            L.append(f"    end else {n} <= {rand_expr(w)};")
        elif n.endswith("_a_bits_size") or n.endswith("_d_bits_size"):
            # 偏向 0..6 覆盖 burst 拍数装入/递减
            L.append(f"    {n} <= {bit_width(w)}'($urandom_range(0, 6));")
        elif n.endswith("_d_bits_source"):
            # 偏向 in_0(0..0x3FFF) / in_1(0x4000) / 全随机, 覆盖 D→主口路由 + D 仲裁
            L.append("    sel = $urandom_range(0, 2);")
            L.append(f"    if (sel == 0) {n} <= 15'($urandom_range(0, 16383));")
            L.append(f"    else if (sel == 1) {n} <= 15'h4000;")
            L.append(f"    else {n} <= {rand_expr(w)};")
        else:
            L.append(f"    {n} <= {rand_expr(w)};")
    L.append("  endtask")
    L.append("")
    L.append("  task automatic check_outputs();")
    for _, _, n in outputs:
        L.append(f"    `CHECK({n})")
    L.append("  endtask")
    L += [
        "",
        "  initial begin",
        "    if ($value$plusargs(\"NCYCLES=%d\", NCYCLES)) begin end",
        "    reset = 1'b1;",
    ]
    for _, _, n in inputs:
        L.append(f"    {n} = '0;")
    L += [
        "    repeat (6) @(posedge clock);",
        "    reset = 1'b0;",
        "    repeat (NCYCLES) begin",
        "      @(negedge clock);",
        "      drive_random_inputs();",
        "      @(posedge clock);",
        "      #1 check_outputs();",
        "    end",
        f"    $display(\"{TOP} checks=%0d errors=%0d\", checks, errors);",
        "    if (errors == 0 && checks > 1000) begin",
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
    return "\n".join(L)


def gen_makefile():
    return """# 自动生成：scripts/gen_tlxbar1.py —— 勿手改
MODULE = TLXbar_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/tlxbar1_pkg.sv \\
           $(RTL_DIR)/uncore/TLXbar_1.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_1.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/TLXbar_1_wrapper.sv
FM_VARIANTS = TLXbar_1
# FM: ref = golden TLXbar_1.sv; impl = pkg + 可读核 + wrapper。无外部依赖/黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / f"{TOP}.sv", TOP)
    (RTL / f"{TOP}_wrapper.sv").write_text(gen_wrapper(ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(gen_makefile())
    print(f"generated {TOP} wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
