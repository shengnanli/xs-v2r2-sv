#!/usr/bin/env python3
"""生成 FastArbiter 族 (CHI round-robin 仲裁器) 的 wrapper / 变体 / UT testbench / Makefile。

FastArbiter 是 OpenLLC/CoupledL2 的 N 输入 round-robin 仲裁器, 香山 V2R2 里 RNXbar/SNXbar
的 CHI TX/RX 通道全部例化它 (叶子模块, 无子例化), 固定 N=4 或单输入退化:

  多输入 (N=4, round-robin + 胜者 payload 多路选择, 见 fastarbiter_pkg):
    FastArbiter_44 : RXSNP (snoop)    FastArbiter_27 : RXRSP (rsp, 带 io_in_ready)
    FastArbiter_46 : RXDAT/TXDAT (dat) FastArbiter_47 : TXREQ (req)
  单输入 (退化纯透传, 无 clock/reset):
    FastArbiter_30 : TXREQ   FastArbiter_31 : TXDAT   FastArbiter_36 : TXRSP

端口全为标量/向量, wrapper/变体直接同名透传例化 xs_FastArbiter_NN_core。
UT: golden FastArbiter_NN vs 可读 FastArbiter_NN_xs 双例化, 全随机激励 (随机 valids +
随机 io_out_ready 自然遍历轮转相位), 逐拍比对全部输出。FM: ref=golden 叶子, impl=pkg+核+wrapper。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UTROOT = ROOT / "verif" / "ut"

# 各变体: 是否依赖 fastarbiter_pkg (多输入轮转才用; 单输入退化纯透传不用)
VARIANTS = {
    "FastArbiter_30": False,
    "FastArbiter_31": False,
    "FastArbiter_36": False,
    "FastArbiter_44": True,
    "FastArbiter_27": True,
    "FastArbiter_46": True,
    "FastArbiter_47": True,
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


def gen_module(top, name, ports):
    core = f"xs_{top}_core"
    return ("// 自动生成：scripts/gen_fastarbiter.py —— 勿手改\n"
            + header(name, ports) + inst(core, "u_core", ports) + "\nendmodule\n")


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


def gen_tb(top, ports):
    variant = f"{top}_xs"
    has_clk = any(n == "clock" for _, _, n in ports)
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_fastarbiter.py —— 勿手改",
        f"// {top} 双例化逐拍比对: golden {top} vs 可读 {variant}。",
        "// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。",
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
    L += ["", f"  {top} u_g ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"g_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", "", f"  {variant} u_i ("]
    for i, (d, _, n) in enumerate(ports):
        sig = "clock" if n == "clock" else "reset" if n == "reset" else (n if d == "input" else f"i_{n}")
        L.append(f"    .{n}({sig}){',' if i + 1 < len(ports) else ''}")
    L += ["  );", ""]

    L.append("  task automatic drive_random_inputs();")
    for _, w, n in inputs:
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
        f"    $display(\"{top} checks=%0d errors=%0d\", checks, errors);",
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
    _ = has_clk
    return "\n".join(L)


def gen_makefile(top, need_pkg):
    pkg_line = "$(RTL_DIR)/uncore/fastarbiter_pkg.sv \\\n           " if need_pkg else ""
    return f"""# 自动生成：scripts/gen_fastarbiter.py —— 勿手改
MODULE = {top}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = {pkg_line}$(RTL_DIR)/uncore/{top}.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/{top}.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/{top}_wrapper.sv
FM_VARIANTS = {top}
# FM: ref = golden {top}.sv; impl = pkg + 可读核 + wrapper。无外部依赖/黑盒。

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    for top, need_pkg in VARIANTS.items():
        ports = parse_ports(GOLDEN / f"{top}.sv", top)
        (RTL / f"{top}_wrapper.sv").write_text(gen_module(top, top, ports))
        ut = UTROOT / top
        ut.mkdir(parents=True, exist_ok=True)
        (ut / "variants_xs.sv").write_text(gen_module(top, f"{top}_xs", ports))
        (ut / "tb.sv").write_text(gen_tb(top, ports))
        (ut / "Makefile").write_text(gen_makefile(top, need_pkg))
        print(f"generated {top}: wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
