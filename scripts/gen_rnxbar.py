#!/usr/bin/env python3
"""生成 RNXbar 的 wrapper / 变体 / UT testbench / Makefile。

RNXbar 是 CHI 1 RN × 4 HN 交叉开关 (OpenLLC RNXbar):
  上行 TX: RN (io_in_0) 的 TXREQ/TXRSP/TXDAT 按路由位 (addr[7:6] / txnID[10:9]) 拆分到
           4 个 HN bank, 每 bank 各一个单输入 FastArbiter (黑盒) 透传;
  下行 RX: 4 个 HN bank 的 RXSNP/RXRSP/RXDAT 各经一个 4 输入 FastArbiter (黑盒) 汇聚到
           RN; 其中 RXSNP 先经 snoop 跟踪状态机 (snpReqs/snpMasks 快照寄存器) 缓存一拍。
共 15 个 FastArbiter 黑盒: 30×4 (txreq) / 36×4 (txrsp) / 31×4 (txdat) /
                          44×1 (rxsnp) / 27×1 (rxrsp) / 46×1 (rxdat)。

端口透传, 唯一例外: golden 的 4 个 snoop 掩码输入端口 io_snpMasks_j_0 在可读核里改名为
io_snp_mask_set_j (避免 io_*_N_M 展平命名); wrapper/变体例化时把二者重新对接。

UT: golden RNXbar vs 可读 RNXbar_xs 双例化, 逐拍比对全部输出 (含 snpReqs/snpMasks 经
    rx_snp 输出间接观测)。两侧共用 golden 的 6 种 FastArbiter (相同仲裁内部状态), 故比对
    聚焦本核路由/解复用/snoop 跟踪逻辑。txnID/addr 全随机即均匀覆盖 4 路路由。
FM: ref = golden RNXbar.sv; impl = pkg + 可读核 + wrapper。FastArbiter 两侧均不提供
    ⇒ hdlin_unresolved_modules=black_box 自动黑盒化并按连接配对。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UT = ROOT / "verif" / "ut" / "RNXbar"

CORE = "xs_RNXbar_core"
TOP = "RNXbar"
VARIANT = "RNXbar_xs"

# golden snoop 掩码端口 -> 可读核端口 的改名映射
def core_port(name):
    m = re.match(r"io_snpMasks_(\d)_0$", name)
    return f"io_snp_mask_set_{m.group(1)}" if m else name


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
    # 可读核例化: 端口名同名透传, 仅 snoop 掩码端口按改名映射对接。
    lines = [f"  {module} {name} ("]
    for i, (_, _, p) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{core_port(p)}({p}){c}")
    lines.append("  );")
    return "\n".join(lines)


def gen_wrapper(ports):
    return ("// 自动生成：scripts/gen_rnxbar.py —— 勿手改\n"
            + header(TOP, ports) + inst(CORE, "u_core", ports) + "\nendmodule\n")


def gen_variant(ports):
    return ("// 自动生成：scripts/gen_rnxbar.py —— 勿手改\n"
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
        "// 自动生成：scripts/gen_rnxbar.py —— 勿手改",
        "// RNXbar 双例化逐拍比对: golden RNXbar vs 可读 RNXbar_xs。",
        "// 激励: RN (io_in_0) 的 TXREQ/TXRSP/TXDAT valid+载荷全随机 (addr[7:6]/txnID[10:9]",
        "//       全宽随机 ⇒ 均匀覆盖 4 路 TX 路由拆分); 4 个 HN bank 的 RXSNP/RXRSP/RXDAT",
        "//       valid+载荷全随机 (覆盖 3 个 4 输入仲裁器的争用 + snoop 跟踪状态机的接收/",
        "//       投递时序); io_snp_mask_set 及各侧 ready 随机背压。",
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
        "// 内部探针: snoop 跟踪状态机寄存器 (golden 与可读核同名标量, 逐拍对拍)。",
        "`define PCHECK(GPATH, IPATH) begin \\",
        "  if (!$isunknown(GPATH)) begin \\",
        "    pchecks++; \\",
        "    if (GPATH !== IPATH) begin \\",
        "      errors++; \\",
        "      if (errors <= 30) $display(\"[%0t] PROBE MISMATCH %s g=%0h i=%0h\", $time, `\"GPATH`\", GPATH, IPATH); \\",
        "    end \\",
        "  end \\",
        "end",
        "module tb;",
        "  int unsigned NCYCLES = 200000;",
        "  bit clock = 0;",
        "  bit reset;",
        "  int errors = 0;",
        "  int checks = 0;",
        "  int pchecks = 0;",
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
    # snoop 跟踪状态机内部探针: golden RNXbar 顶层标量 vs 可读核 u_core 内同名标量
    snp_fields = ["valid", "bits_txnID", "bits_fwdNID", "bits_fwdTxnID",
                  "bits_opcode", "bits_addr", "bits_doNotGoToSD", "bits_retToSrc"]
    for j in range(4):
        L.append(f"    `PCHECK(u_g.snpMasks_{j}_0, u_i.u_core.snpMasks_{j}_0)")
        for f in snp_fields:
            L.append(f"    `PCHECK(u_g.snpReqs_{j}_{f}, u_i.u_core.snpReqs_{j}_{f})")
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
        f"    $display(\"{TOP} checks=%0d pchecks=%0d errors=%0d\", checks, pchecks, errors);",
        "    if (errors == 0 && checks > 1000 && pchecks > 1000) begin",
        "      $display(\"TEST PASSED\");",
        "      $finish;",
        "    end",
        "    $display(\"TEST FAILED\");",
        "    $fatal(1);",
        "  end",
        "endmodule",
        "`undef CHECK",
        "`undef PCHECK",
        "",
    ]
    return "\n".join(L)


def gen_makefile():
    return """# 自动生成：scripts/gen_rnxbar.py —— 勿手改
MODULE = RNXbar

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/rnxbar_pkg.sv \\
           $(RTL_DIR)/uncore/RNXbar.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden RNXbar + 15 个 FastArbiter 黑盒 (6 种类型; 两侧共用同一例化)。
GOLDEN_SRCS = $(GOLDEN_RTL)/RNXbar.sv \\
              $(GOLDEN_RTL)/FastArbiter_30.sv \\
              $(GOLDEN_RTL)/FastArbiter_36.sv \\
              $(GOLDEN_RTL)/FastArbiter_31.sv \\
              $(GOLDEN_RTL)/FastArbiter_44.sv \\
              $(GOLDEN_RTL)/FastArbiter_27.sv \\
              $(GOLDEN_RTL)/FastArbiter_46.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/RNXbar_wrapper.sv
FM_VARIANTS = RNXbar
# FM: 6 种 FastArbiter 不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box 在 ref/impl
# 两侧自动黑盒化并按连接配对; 比对聚焦 RNXbar 自身路由/解复用/snoop 跟踪逻辑。
# (故 FM_REF_DEPS_RNXbar 留空, ref 侧只读 RNXbar.sv)

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
    print(f"generated {TOP} wrapper / variant / tb / Makefile ({len(ports)} ports)")


if __name__ == "__main__":
    main()
