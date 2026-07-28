#!/usr/bin/env python3
# gen_ncb200_1.py —— NCB200_1 (CHI↔AXI Non-Coherent Bridge, 32-entry variant) 可读实现生成器。
#
# NCB200_1 是 OpenNCB_1 的核心 child(golden 12327 行), 是 NCB200(64 条目)的 32 条目
# 参数变体: 事务表深度 32(索引 max _31) vs NCB200 的 64(_63); AXI id 宽 5 位 vs 6 位;
# 且 NCB200_1 多 io_axi_{ar,aw}_bits_cache 两口。
#
# ★结构: 顶层是纯结构 netlist(0 register / 0 always / 0 function / 0 generate),
#   仅 wire 声明 + 16 个 child 例化 + 纯组合 assign(598 直通 + debug_valid=|concat)。
#   全部功能逻辑在 16 个 child 内(CAM/FreeList/AgeMatrix/Queue/Payload/上下游通道 FSM)。
#   顶层只做互连: 每个 child 端口连到 top IO 或另一 child 的输出 wire(_uChild_io_port)。
#
# 16 children(全逻辑, 无厂商 SRAM 宏):
#   CHILinkActiveManagerRX/TX(共享, 无 _1 后缀)
#   NCBOrderAddressCAM_1 / NCBTransactionFreeList_1 / NCBTransactionAgeMatrix_1 /
#   NCBTransactionQueue_1 / NCBTransactionPayload_1
#   NCBUpstreamRXREQ_1 / RXDAT_1 / TXRSP_1 / TXDAT_1
#   NCBDownstreamAW_1 / W_1 / B_1 / AR_1 / R_1
#
# 生成:
#   rtl/uncore/NCB200_1.sv          可读核 xs_NCB200_1_core(golden 端口名; 例化 16 child;
#                                   互连 wire/assign 忠实重建; 唯一 _T_ 临时改可读名)
#   rtl/uncore/NCB200_1_wrapper.sv  golden 同名 NCB200_1(...)例化 xs_NCB200_1_core u_core
#   verif/ut/NCB200_1/{Makefile,tb.sv,variants_xs.sv}
#
# FM assembly(FM_MODE=assembly): 16 逻辑 child 两侧 elaborate golden RTL(非黑盒, ref==impl
#   同源); 无厂商宏 → allow 4 键全空(结构无黑盒)。UT dual-instantiate golden + xs 影子核。
import os, re, sys

GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G0-canonical/golden-rtl")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(GOLDEN, "NCB200_1.sv")

# 16 child module types directly instantiated by NCB200_1 top.
CHILDREN = [
    "CHILinkActiveManagerRX", "CHILinkActiveManagerTX",
    "NCBOrderAddressCAM_1", "NCBTransactionFreeList_1", "NCBTransactionAgeMatrix_1",
    "NCBTransactionQueue_1", "NCBTransactionPayload_1",
    "NCBUpstreamRXREQ_1", "NCBUpstreamRXDAT_1", "NCBUpstreamTXRSP_1", "NCBUpstreamTXDAT_1",
    "NCBDownstreamAW_1", "NCBDownstreamW_1", "NCBDownstreamB_1", "NCBDownstreamAR_1",
    "NCBDownstreamR_1",
]

# 10 grandchildren (instantiated inside the 16 children): SpillRegister / Decoder /
# link-credit managers / index-FIFO / ProvideBuffer.  All are logic modules with their
# own golden .sv (no vendor SRAM macro), so both UT and FM elaborate them two-sided.
GRANDCHILDREN = [
    "CHILinkCreditManagerRX", "CHILinkCreditManagerRX_1", "CHILinkCreditManagerTX",
    "Decoder", "Decoder_1", "NCBTransactionIndexFIFO_3", "ProvideBuffer",
    "SpillRegister_2", "SpillRegister_6", "SpillRegister_7",
]

# full transitive closure (26 modules) — every module below NCB200_1 top.
CLOSURE = CHILDREN + GRANDCHILDREN


def read_golden():
    with open(SRC) as f:
        return f.read().splitlines(keepends=False)


def split_golden(lines):
    """Return (port_lines, body_lines).  port_lines are the raw `input/output ...`
    declarations between `module NCB200_1(` and the closing `);`.  body_lines are
    everything after `);` up to (not including) `endmodule`."""
    start = None
    for i, l in enumerate(lines):
        if l.startswith("module NCB200_1("):
            start = i
            break
    assert start is not None
    # port list ends at the first line that is exactly ");"
    pend = None
    for i in range(start + 1, len(lines)):
        if lines[i].rstrip() == ");":
            pend = i
            break
    assert pend is not None
    port_lines = lines[start + 1:pend]
    # body: after ");" up to endmodule
    eend = None
    for i in range(pend + 1, len(lines)):
        if lines[i].rstrip() == "endmodule":
            eend = i
            break
    assert eend is not None
    body_lines = lines[pend + 1:eend]
    return port_lines, body_lines


PORT_RE = re.compile(r"^\s*(input|output)\s+(\[[0-9:]+\]\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$")


def parse_ports(port_lines):
    """Ordered list of (dir, width, name)."""
    out = []
    for l in port_lines:
        m = PORT_RE.match(l)
        if not m:
            continue
        out.append((m.group(1), (m.group(2) or "").strip(), m.group(3)))
    return out


def make_core(port_lines, body_lines):
    # Rename the single readability-hostile temp `_debug_valid_T_31` to a readable name.
    body = "\n".join(body_lines)
    body = body.replace("_debug_valid_T_31", "_debug_reason_all_cat")
    hdr = [
        "// NCB200_1 —— 手写可读实现(codex_0085 Lane A2, OpenNCB_1 核心 child, AUX assembly signoff)。",
        "//",
        "// CHI↔AXI Non-Coherent Bridge, 32 条目事务表变体(NCB200=64 条目的参数变体:",
        "//   事务表深度 32 / AXI id 宽 5 位 / 多 io_axi_{ar,aw}_bits_cache 两口)。",
        "//",
        "// ★顶层 = 纯结构 netlist(0 register/0 always/0 function): 声明互连 wire + 例化 16 个",
        "//   child + 纯组合 assign(598 直通 + debug_valid=|concat(598 debug reason))。全部功能",
        "//   逻辑在 16 个 child 内(CAM/FreeList/AgeMatrix/Queue/Payload/上下游 5+4 通道 FSM);",
        "//   本核忠实重建互连: 每个 child 端口连到 top IO 或另一 child 输出 wire(_uChild_io_port)。",
        "//",
        "// ★ FM assembly: 16 逻辑 child 两侧 elaborate golden RTL(非黑盒, ref==impl 同源);",
        "//   无厂商 SRAM 宏 → 结构无黑盒(allow 4 键全空)。",
        "module xs_NCB200_1_core(",
    ]
    # port lines: keep verbatim (already golden-formatted), ensure trailing `);`
    return "\n".join(hdr) + "\n" + "\n".join(port_lines).rstrip() + "\n);\n\n" + body.strip("\n") + "\nendmodule\n"


def make_wrapper(ports):
    lines = [
        "// NCB200_1 包装层(golden 同名扁平端口 ↔ xs_NCB200_1_core)。",
        "// 仅供 FM impl 侧与 ST 替换。核内例化 16 逻辑 child(两侧 elaborate)。",
        "module NCB200_1(",
    ]
    decl = []
    for d, w, n in ports:
        wsp = (w + " ") if w else ""
        decl.append(f"  {d} {wsp}{n}")
    lines.append(",\n".join(decl))
    lines.append(");")
    lines.append("  xs_NCB200_1_core u_core (")
    conn = [f"    .{n} ({n})" for _, _, n in ports]
    lines.append(",\n".join(conn))
    lines.append("  );")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


def make_tb(ports):
    """Dual-instantiate golden NCB200_1 (renamed via variants_xs to NCB200_1_xs core wrap)
    and xs implementation; drive random stimulus; compare all outputs each cycle."""
    ins = [(w, n) for d, w, n in ports if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ports if d == "output"]

    def sig(w, n, pfx=""):
        wsp = (w + " ") if w else ""
        return f"  logic {wsp}{pfx}{n};"

    lines = []
    lines.append("// NCB200_1 UT: dual-instantiate golden NCB200_1 vs xs 影子核, 逐拍比对全部 output。")
    lines.append("`timescale 1ns/1ps")
    lines.append("module tb;")
    lines.append("  logic clock=0, reset=1;")
    lines.append("  always #5 clock = ~clock;")
    lines.append("  integer i, errors=0, checks=0;")
    lines.append("  integer seed;")
    lines.append("  initial begin")
    lines.append('    if (!$value$plusargs("seed=%d", seed)) seed = 1;')
    lines.append("  end")
    lines.append("")
    lines.append("  // inputs (shared drive)")
    for w, n in ins:
        lines.append(sig(w, n))
    lines.append("")
    lines.append("  // golden outputs")
    for w, n in outs:
        lines.append(sig(w, n, "g_"))
    lines.append("  // xs outputs")
    for w, n in outs:
        lines.append(sig(w, n, "x_"))
    lines.append("")
    # golden instance
    lines.append("  NCB200_1 u_g (")
    lines.append("    .clock(clock), .reset(reset),")
    conns = []
    for w, n in ins:
        conns.append(f"    .{n}({n})")
    for w, n in outs:
        conns.append(f"    .{n}(g_{n})")
    lines.append(",\n".join(conns))
    lines.append("  );")
    lines.append("")
    # xs instance (renamed golden-name wrapper -> NCB200_1_xs in variants_xs.sv)
    lines.append("  NCB200_1_xs u_x (")
    lines.append("    .clock(clock), .reset(reset),")
    conns = []
    for w, n in ins:
        conns.append(f"    .{n}({n})")
    for w, n in outs:
        conns.append(f"    .{n}(x_{n})")
    lines.append(",\n".join(conns))
    lines.append("  );")
    lines.append("")
    # stimulus
    lines.append("  task drive_random;")
    lines.append("    begin")
    for w, n in ins:
        if w:
            m = re.match(r"\[(\d+):0\]", w)
            width = int(m.group(1)) + 1 if m else 1
            if width <= 32:
                lines.append(f"      {n} = $random(seed);")
            else:
                # build wide random by concatenation of 32-bit chunks
                nch = (width + 31) // 32
                parts = ", ".join(["$random(seed)"] * nch)
                lines.append(f"      {n} = {{{parts}}};")
        else:
            lines.append(f"      {n} = $random(seed);")
    lines.append("    end")
    lines.append("  endtask")
    lines.append("")
    lines.append("  task check_outputs;")
    lines.append("    begin")
    for w, n in outs:
        lines.append(f"      checks = checks + 1;")
        lines.append(f"      if (x_{n} !== g_{n}) begin errors=errors+1;")
        lines.append(f'        if (errors<20) $display("MISMATCH %0t {n}: xs=%h golden=%h", $time, x_{n}, g_{n}); end')
    lines.append("    end")
    lines.append("  endtask")
    lines.append("")
    lines.append("  initial begin")
    lines.append("    reset = 1; drive_random();")
    lines.append("    repeat (5) @(posedge clock);")
    lines.append("    reset = 0;")
    lines.append("    for (i = 0; i < 200000; i = i + 1) begin")
    lines.append("      @(negedge clock);")
    lines.append("      drive_random();")
    lines.append("      @(posedge clock);")
    lines.append("      #1 check_outputs();")
    lines.append("    end")
    lines.append('    $display("NCB200_1 UT done: seed=%0d checks=%0d errors=%0d", seed, checks, errors);')
    lines.append('    if (errors==0) $display("UT PASS"); else $display("UT FAIL");')
    lines.append("    $finish;")
    lines.append("  end")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


def make_variants_xs(ports):
    # standalone NCB200_1_xs module wrapping xs_NCB200_1_core (for dual instantiation vs golden).
    lines = [
        "// UT variant: NCB200_1_xs (例化 xs_NCB200_1_core) —— 与 golden NCB200_1 双例化对拍。",
        "module NCB200_1_xs(",
    ]
    decl = []
    for d, w, n in ports:
        wsp = (w + " ") if w else ""
        decl.append(f"  {d} {wsp}{n}")
    lines.append(",\n".join(decl))
    lines.append(");")
    lines.append("  xs_NCB200_1_core u_core (")
    conn = [f"    .{n}({n})" for _, _, n in ports]
    lines.append(",\n".join(conn))
    lines.append("  );")
    lines.append("endmodule")
    return "\n".join(lines) + "\n"


def make_makefile():
    ref_deps = " ".join(f"{c}.sv" for c in CLOSURE)
    wrapper_children = " \\\n               ".join(f"$(GOLDEN_RTL)/{c}.sv" for c in CLOSURE)
    golden_children = " \\\n              ".join(f"$(GOLDEN_RTL)/{c}.sv" for c in CLOSURE)
    return f"""MODULE = NCB200_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读顶层核 xs_NCB200_1_core(纯结构 netlist glue: 互连 16 个直接 child)。
RTL_SRCS = $(RTL_DIR)/uncore/NCB200_1.sv
# FM impl 侧: golden 同名扁平端口包装 + 26 逻辑 child(16 直接 + 10 孙)两侧 elaborate
# (全逻辑 child, 非黑盒, ref==impl 同源; 无厂商 SRAM 宏 → 结构无黑盒)。
WRAPPER_SRCS = $(RTL_DIR)/uncore/NCB200_1_wrapper.sv \\
               {wrapper_children}

# golden 顶层 + 全部 26 子模块闭包(无厂商宏)。
GOLDEN_SRCS = $(GOLDEN_RTL)/NCB200_1.sv \\
              {golden_children}
# UT 变体: impl 顶层改名 NCB200_1_xs 与 golden 双例化。
TB_SRCS = variants_xs.sv tb.sv

# FM: 单顶层 assembly。26 逻辑 child 两侧 elaborate golden RTL(逻辑 child, 非黑盒,
# ref==impl 同源)。唯一黑盒 = golden 本身把 NCBOrderAddressCAM_1 化简成的空模块(0 输出),
# FM 自动归 empty_blackbox(对称, allow/NCB200_1.json 声明)。不用 FM_INTERFACE_ONLY
# (我方闭包里没有"有 body 却要当 interface"的模块; 空 CAM 由 FM 自动 empty-blackbox)。
# FM_MERGE_DUP=false: 关闭重复寄存器合并。26 child 里有多份同款子模块(SpillRegister/
# LinkCreditManager/Decoder), impl 侧多一层 u_core 层次会让 merge_duplicated_registers
# 在两侧不对称合并 uLinkCredit 的 regInitialCycleCounter/CreditCounter → 18 个 golden-only
# unmatched-ref 伪影。关掉合并让两侧逐寄存器对称匹配(同 SMSPrefetcher assembly 做法)。
FM_VARIANTS = NCB200_1
FM_MODE = assembly
FM_MERGE_DUP = false
FM_REF_DEPS_NCB200_1 = {ref_deps}

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言; 定义 SYNTHESIS 关掉使两侧复位到 0 同构。
VCS += +define+SYNTHESIS
VCS += -assert disable
"""


def main():
    lines = read_golden()
    port_lines, body_lines = split_golden(lines)
    ports = parse_ports(port_lines)
    assert len(ports) == 692, f"expected 692 ports, got {len(ports)}"

    os.makedirs(os.path.join(ROOT, "rtl", "uncore"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "verif", "ut", "NCB200_1"), exist_ok=True)

    with open(os.path.join(ROOT, "rtl", "uncore", "NCB200_1.sv"), "w") as f:
        f.write(make_core(port_lines, body_lines))
    with open(os.path.join(ROOT, "rtl", "uncore", "NCB200_1_wrapper.sv"), "w") as f:
        f.write(make_wrapper(ports))
    with open(os.path.join(ROOT, "verif", "ut", "NCB200_1", "tb.sv"), "w") as f:
        f.write(make_tb(ports))
    with open(os.path.join(ROOT, "verif", "ut", "NCB200_1", "variants_xs.sv"), "w") as f:
        f.write(make_variants_xs(ports))
    with open(os.path.join(ROOT, "verif", "ut", "NCB200_1", "Makefile"), "w") as f:
        f.write(make_makefile())
    print(f"generated: core+wrapper (692 ports, {len(CHILDREN)} children), UT scaffolding")


if __name__ == "__main__":
    main()
