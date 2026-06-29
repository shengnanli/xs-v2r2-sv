#!/usr/bin/env python3
"""生成 AXI4Xbar (大 2 主 × 2 从 AXI4 交叉开关) 的 wrapper / 变体 / UT testbench / Makefile。

AXI4Xbar 是香山 SoC 顶层 2 主 (in_0 id6 / in_1 id5) × 2 从 (out_0=MEM / out_1=MMIO) 的
多主交叉开关 (装配 4 个黑盒 Queue2_UInt2 作为 AW/W 同步队列, 内部 RAM ram_2x2):
  · ID indexer/yanker: 上行前缀主口号 (in_0={1'b0,id6}/in_1={2'b10,id5}); 下行据 id 高位还原+裁宽。
  · 8 把 2 路 round-robin (每从口 AW/AR + 每主口 R/B)。
  · per-ID 顺序保持 (in_0 64 ID + in_1 32 ID 各 count/last)。
端口全为标量/向量, wrapper/变体同名透传例化 xs_AXI4Xbar_core。

UT: golden AXI4Xbar vs 可读 AXI4Xbar_xs 双例化 (二者共用同一黑盒 Queue2_UInt2/ram_2x2):
  · 两主口 AW/AR 地址全 49 位随机 (≈各 50% 落 MEM/MMIO, 覆盖两条路由 + 同从口并发);
  · 主口 id 随机 (覆盖各 ID 的 FIFO 顺序门); 从口响应 r/b id 随机 7 位 (覆盖 id 归属还原);
  · 各通道 valid/ready/载荷随机 (覆盖 AW/W 同步队列 + R/B/AW/AR round-robin 仲裁)。
逐拍比对全部输出。FM: ref=golden AXI4Xbar + Queue2_UInt2/ram_2x2; impl=pkg+核+黑盒队列+wrapper。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "AXI4Xbar"

CORE = "xs_AXI4Xbar_core"
TOP = "AXI4Xbar"
VARIANT = "AXI4Xbar_xs"

ADDR_PORTS = (
    "auto_in_0_aw_bits_addr", "auto_in_0_ar_bits_addr",
    "auto_in_1_aw_bits_addr", "auto_in_1_ar_bits_addr",
)


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
    return ("// 自动生成：scripts/gen_axi4xbar.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_axi4xbar.py —— 勿手改\n"
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
        "// 自动生成：scripts/gen_axi4xbar.py —— 勿手改",
        "// AXI4Xbar 双例化逐拍比对: golden AXI4Xbar vs 可读 AXI4Xbar_xs。",
        "// 激励: 两主口 AW/AR 49 位随机地址 (≈50% MEM/MMIO); id 随机; 从口响应/握手随机。",
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

    # 49 位地址生成器: 全随机 (~50% 落 MEM[2^31,2^48) / ~50% 落 MMIO[0,2^31)∪addr[48]),
    # 另偏置一部分强制落各区, 保证同从口并发与跨从口交错都被覆盖。
    L.append("  function automatic logic [48:0] rand_axi_addr();")
    L.append("    case ($urandom_range(0, 3))")
    L.append("      0: return {18'h0, 31'($urandom)};                 // MMIO 低区 [0, 2^31)")
    L.append("      1: return {1'b0, 16'($urandom), 32'($urandom)} | 49'h0_0000_8000_0000; // MEM [2^31, 2^48)")
    L.append("      2: return {1'b1, 48'($urandom)};                  // MMIO 高位别名 (addr[48]=1)")
    L.append("      default: return 49'({$urandom, $urandom});        // 全随机")
    L.append("    endcase")
    L.append("  endfunction")
    L.append("")
    L.append("  task automatic drive_random_inputs();")
    for _, w, n in inputs:
        if n in ADDR_PORTS:
            L.append(f"    {n} <= rand_axi_addr();")
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
    return """# 自动生成：scripts/gen_axi4xbar.py —— 勿手改
MODULE = AXI4Xbar

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写: pkg + 可读核; 黑盒 (golden 子模块): AW/W 同步队列 Queue2_UInt2 及其 RAM ram_2x2。
RTL_SRCS = $(RTL_DIR)/uncore/axi4xbar_pkg.sv \\
           $(RTL_DIR)/uncore/AXI4Xbar.sv \\
           $(GOLDEN_RTL)/Queue2_UInt2.sv \\
           $(GOLDEN_RTL)/ram_2x2.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶层 (Queue2_UInt2/ram_2x2 已在 RTL_SRCS 提供, 此处只给顶层避免重定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Xbar.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4Xbar_wrapper.sv
FM_VARIANTS = AXI4Xbar
# FM: ref = golden AXI4Xbar + 黑盒队列依赖; impl = RTL_SRCS(含队列) + wrapper。两侧队列相同。
FM_REF_DEPS_AXI4Xbar = Queue2_UInt2.sv ram_2x2.sv

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
