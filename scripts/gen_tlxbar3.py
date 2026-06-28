#!/usr/bin/env python3
"""生成 TLXbar_3 的 wrapper / 变体 / UT testbench / Makefile。

TLXbar_3 是 1 主 × 2 从 TileLink-UL 交叉开关 (叶子模块, 无子例化)。端口全为
标量/向量, wrapper/变体直接同名透传例化 xs_TLXbar_3_core。

UT: golden TLXbar_3 vs 可读 TLXbar_3_xs 双例化, 全输入随机 + 地址偏向设备区间,
逐拍比对全部输出。FM: ref=golden 叶子, impl=核+pkg+wrapper, 签名分析证等价。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "TLXbar_3"


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


def gen_wrapper(top, ports):
    return ("// 自动生成：scripts/gen_tlxbar3.py —— 勿手改\n"
            + header(top, ports) + inst("xs_TLXbar_3_core", "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_tlxbar3.py —— 勿手改\n"
            + header("TLXbar_3_xs", ports) + inst("xs_TLXbar_3_core", "u_core", ports) + "\nendmodule\n")


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
        "// 自动生成：scripts/gen_tlxbar3.py —— 勿手改",
        "// TLXbar_3 双例化逐拍比对: golden TLXbar_3 vs 可读 TLXbar_3_xs。",
        "// 激励: A 通道地址偏向设备区间 (0x40-0x57) 以覆盖两条路由; D 通道两从口",
        "// valid/data 随机 (覆盖 round-robin 仲裁两路争用)。",
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
    L += ["", "  TLXbar_3 u_g ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"g_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", "", "  TLXbar_3_xs u_i ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"i_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", ""]

    L.append("  task automatic drive_random_inputs();")
    for _, w, n in inputs:
        if n == "auto_in_a_bits_address":
            # 偏置: 1/2 概率落在设备区间内/附近 (0x40-0x5F), 1/2 全随机
            L.append("    if ($urandom_range(0, 1))")
            L.append("      auto_in_a_bits_address <= 9'(9'h40 + $urandom_range(0, 31));")
            L.append("    else")
            L.append(f"      auto_in_a_bits_address <= {rand_expr(w)};")
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
        "    $display(\"TLXbar_3 checks=%0d errors=%0d\", checks, errors);",
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
    return """# 自动生成：scripts/gen_tlxbar3.py —— 勿手改
MODULE = TLXbar_3

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/tlxbar3_pkg.sv \\
           $(RTL_DIR)/uncore/TLXbar_3.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/TLXbar_3.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/TLXbar_3_wrapper.sv
FM_VARIANTS = TLXbar_3
# FM: ref = golden TLXbar_3.sv; impl = pkg + 可读核 + wrapper。无外部依赖/黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = parse_ports(GOLDEN / "TLXbar_3.sv", "TLXbar_3")
    (RTL / "TLXbar_3_wrapper.sv").write_text(gen_wrapper("TLXbar_3", ports))
    (UT / "variants_xs.sv").write_text(gen_variant(ports))
    (UT / "tb.sv").write_text(gen_tb(ports))
    (UT / "Makefile").write_text(gen_makefile())
    print("generated TLXbar_3 wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
