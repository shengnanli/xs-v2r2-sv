#!/usr/bin/env python3
"""生成 AXI4Xbar_1 的 wrapper / 变体 / UT testbench / Makefile。

AXI4Xbar_1 是 1 主 × 5 从 AXI4 交叉开关 (装配: 黑盒 Queue2_UInt5/ram_2x5 作为 W 路由队列):
  out_0=UART(0x40600000/16B) out_1=Flash(0x10000000/256MB,地址截29位)
  out_2=SD(0x40002000/4KB)   out_3=IntrGen(0x40070000/64KB)  out_4=Error(DECERR catch-all)
五通道 AW/W/B/AR/R; 端口全为标量/向量, wrapper/变体同名透传例化 xs_AXI4Xbar_1_core。

UT: golden AXI4Xbar_1 vs 可读 AXI4Xbar_1_xs 双例化 (二者共用同一黑盒 Queue2_UInt5):
  · AW/AR 地址按 1/5 概率落到 UART/Flash/SD/IntrGen 区, 1/5 全随机 (→ Error); 覆盖五条路由;
  · id 随机 2 位 (覆盖 4 个 ID 的 FIFO 顺序门); 各通道 valid/ready/响应载荷随机 (覆盖
    AW/W 同步队列 + R/B round-robin 仲裁);
逐拍比对全部输出。FM: ref=golden AXI4Xbar_1 + Queue2_UInt5/ram_2x5; impl=pkg+核+黑盒队列+wrapper。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "AXI4Xbar_1"

CORE = "xs_AXI4Xbar_1_core"
TOP = "AXI4Xbar_1"
VARIANT = "AXI4Xbar_1_xs"


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
    return ("// 自动生成：scripts/gen_axi4xbar1.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_axi4xbar1.py —— 勿手改\n"
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
        "// 自动生成：scripts/gen_axi4xbar1.py —— 勿手改",
        "// AXI4Xbar_1 双例化逐拍比对: golden AXI4Xbar_1 vs 可读 AXI4Xbar_1_xs。",
        "// 激励: AW/AR 地址偏向五个从口区 + 全随机; id 随机; 五通道握手/响应随机。",
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

    L.append("  function automatic logic [30:0] rand_axi_addr();")
    L.append("    int unsigned sel = $urandom_range(0, 4);")
    L.append("    case (sel)")
    L.append("      0: return 31'h40600000 + $urandom_range(0, 15);       // UART")
    L.append("      1: return 31'h10000000 + $urandom_range(0, 16777215); // Flash")
    L.append("      2: return 31'h40002000 + $urandom_range(0, 4095);     // SD")
    L.append("      3: return 31'h40070000 + $urandom_range(0, 65535);    // IntrGen")
    L.append("      default: return 31'($urandom);                        // 全随机 (→ Error)")
    L.append("    endcase")
    L.append("  endfunction")
    L.append("")
    L.append("  task automatic drive_random_inputs();")
    for _, w, n in inputs:
        if n in ("auto_in_aw_bits_addr", "auto_in_ar_bits_addr"):
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
    return """# 自动生成：scripts/gen_axi4xbar1.py —— 勿手改
MODULE = AXI4Xbar_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写: pkg + 可读核; 黑盒 (golden 子模块): W 路由队列 Queue2_UInt5 及其 RAM。
RTL_SRCS = $(RTL_DIR)/uncore/axi4xbar1_pkg.sv \\
           $(RTL_DIR)/uncore/AXI4Xbar_1.sv \\
           $(GOLDEN_RTL)/Queue2_UInt5.sv \\
           $(GOLDEN_RTL)/ram_2x5.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden 顶层 (Queue2_UInt5/ram_2x5 已在 RTL_SRCS 提供, 此处只给顶层避免重定义)。
GOLDEN_SRCS = $(GOLDEN_RTL)/AXI4Xbar_1.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/AXI4Xbar_1_wrapper.sv
FM_VARIANTS = AXI4Xbar_1
# FM: ref = golden AXI4Xbar_1 + 黑盒队列依赖; impl = RTL_SRCS(含队列) + wrapper。两侧队列相同。
FM_REF_DEPS_AXI4Xbar_1 = Queue2_UInt5.sv ram_2x5.sv

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
