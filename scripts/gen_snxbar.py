#!/usr/bin/env python3
"""生成 SNXbar 的 wrapper / 变体 / UT testbench / Makefile。

SNXbar 是 CHI 4 主 × 1 从 交叉开关 (OpenLLC SNXbar):
  上行 TX: 4 主口 TXREQ / TXDAT 各经一个 FastArbiter (黑盒) 轮转仲裁汇聚到 out;
  下行 RX: out 的 RXRSP / RXDAT 按 txnID[10:9] 解复用回 4 主口 (载荷广播, valid 门控)。
端口全为标量/向量, wrapper/变体直接同名透传例化 xs_SNXbar_core。
子例化仅 FastArbiter_46 (TXDAT) / FastArbiter_47 (TXREQ) 两个黑盒仲裁器。

UT: golden SNXbar vs 可读 SNXbar_xs 双例化, 逐拍比对全部输出。两侧共用 golden 的
    FastArbiter_46/47 (相同仲裁内部状态), 故比对聚焦本核路由/解复用逻辑。
    rx txnID 全随机即可均匀覆盖 [10:9]=0..3 四条回程路由。
FM: ref = golden SNXbar.sv; impl = pkg + 可读核 + wrapper。FastArbiter 两侧均不提供
    ⇒ hdlin_unresolved_modules=black_box 自动黑盒化并按同名配对 (同 IMSIC 做法)。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "SNXbar"

CORE = "xs_SNXbar_core"
TOP = "SNXbar"
VARIANT = "SNXbar_xs"


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
    return ("// 自动生成：scripts/gen_snxbar.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_snxbar.py —— 勿手改\n"
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
        "// 自动生成：scripts/gen_snxbar.py —— 勿手改",
        "// SNXbar 双例化逐拍比对: golden SNXbar vs 可读 SNXbar_xs。",
        "// 激励: 4 主口 TXREQ/TXDAT valid+载荷全随机 (覆盖两个 FastArbiter 的 4 路争用);",
        "//       out 的 RXRSP/RXDAT valid+txnID 全随机 (txnID 全宽随机 ⇒ [10:9] 均匀覆盖",
        "//       0..3 四条回程解复用路由); out 的 tx_*_ready/rx_* 随机背压。",
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
    return """# 自动生成：scripts/gen_snxbar.py —— 勿手改
MODULE = SNXbar

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/snxbar_pkg.sv \\
           $(RTL_DIR)/uncore/SNXbar.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden SNXbar + 两个 FastArbiter 黑盒仲裁器 (两侧共用同一例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/SNXbar.sv \\
              $(GOLDEN_RTL)/FastArbiter_47.sv \\
              $(GOLDEN_RTL)/FastArbiter_46.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/SNXbar_wrapper.sv
FM_VARIANTS = SNXbar
# FM: FastArbiter_46/47 不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box 在
# ref/impl 两侧自动黑盒化并按同名配对; 比对聚焦 SNXbar 自身路由/解复用逻辑。
# (故 FM_REF_DEPS_SNXbar 留空, ref 侧只读 SNXbar.sv)

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
