#!/usr/bin/env python3
"""生成 LinkMonitor 的 wrapper / 变体 / UT testbench / Makefile。

LinkMonitor 是 CHI 链路层监视器 (OpenLLC RN 侧 LinkMonitor):
  · 自身: LINKACTIVE 状态机 (txState/rxState) + L-Credit 回收握手 + 系统一致性
    握手 (syscoreq/syscoack) + txsactive + 性能计数器 + srcID=nodeID 注入;
  · 子例化 6 个黑盒 flit 转换器:
      Decoupled2LCredit / _1 / _2  (txreq/txrsp/txdat: Decoupled→flit);
      LCredit2Decoupled / _1 / _2  (rxsnp/rxrsp/rxdat: flit→Decoupled)。
    其中 LCredit2Decoupled(rxsnp) 内含 Queue4_CHISNP。
端口全为标量/向量, wrapper/变体直接同名透传例化 xs_LinkMonitor_core。

UT: golden LinkMonitor vs 可读 LinkMonitor_xs 双例化, 逐拍比对全部输出。两侧共用
    golden 的 6 个子模块 (相同内部状态), 故比对聚焦本核状态机/握手/计数逻辑。
    输入全随机: io_out_tx_linkactiveack / io_out_rx_linkactivereq 覆盖链路态转换,
    flit/lcrdv/valid 全随机覆盖子模块与 reclaim 路径。
FM: ref = golden LinkMonitor.sv; impl = pkg + 可读核 + wrapper。6 个子模块两侧均不
    提供 ⇒ hdlin_unresolved_modules=black_box 自动黑盒化并按同名配对。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "LinkMonitor"

CORE = "xs_LinkMonitor_core"
TOP = "LinkMonitor"
VARIANT = "LinkMonitor_xs"


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
    return ("// 自动生成：scripts/gen_linkmonitor.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_linkmonitor.py —— 勿手改\n"
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
        "// 自动生成：scripts/gen_linkmonitor.py —— 勿手改",
        "// LinkMonitor 双例化逐拍比对: golden LinkMonitor vs 可读 LinkMonitor_xs。",
        "// 激励: 全输入随机 —— linkactiveack/linkactivereq 覆盖 LINKACTIVE 4 态转换,",
        "//       syscoack 覆盖 txsactive, flit/flitv/lcrdv/valid 覆盖子模块与 L-Credit",
        "//       reclaim (rx 去激活) 路径。两侧共用 golden 子模块, 比对聚焦本核逻辑。",
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
    return """# 自动生成：scripts/gen_linkmonitor.py —— 勿手改
MODULE = LinkMonitor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/linkmonitor_pkg.sv \\
           $(RTL_DIR)/uncore/LinkMonitor.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden LinkMonitor + 6 个黑盒 flit 转换子模块 (两侧共用同一例化);
# LCredit2Decoupled(rxsnp) 内含 Queue4_CHISNP。
GOLDEN_SRCS = $(GOLDEN_RTL)/LinkMonitor.sv \\
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \\
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \\
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \\
              $(GOLDEN_RTL)/LCredit2Decoupled.sv \\
              $(GOLDEN_RTL)/LCredit2Decoupled_1.sv \\
              $(GOLDEN_RTL)/LCredit2Decoupled_2.sv \\
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \\
              $(GOLDEN_RTL)/ram_4x115.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/LinkMonitor_wrapper.sv
FM_VARIANTS = LinkMonitor
# FM: 6 个子模块不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box 在 ref/impl 两侧
# 自动黑盒化并按同名配对; 比对聚焦 LinkMonitor 自身状态机/握手/计数逻辑。
# (故 FM_REF_DEPS_LinkMonitor 留空, ref 侧只读 LinkMonitor.sv)

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
