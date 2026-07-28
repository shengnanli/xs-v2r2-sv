#!/usr/bin/env python3
"""生成 Receiver/TransmitterLinkMonitor 的可读核 / wrapper / UT / Makefile。

ReceiverLinkMonitor / TransmitterLinkMonitor 是 XSTop 里 OpenNCB(CHI↔AXI 桥)侧的
CHI 链路层监视器, 与已绿 LinkMonitor(OpenLLC RN 侧)同族但方向/子模块 dedup id 不同:

  TransmitterLinkMonitor : TX=Decoupled2LCredit(txreq/txrsp/txdat, 出), RX=
      LCredit2Decoupled_11/3/4(rxsnp/rxrsp/rxdat, 入). 本端 tx 恒请求(req=~reset),
      rx.ack = RegNext(rx.req) | ~(三 RX 子模块 reclaim 全 1)。txsactive/syscoreq=1。
  ReceiverLinkMonitor    : RX=LCredit2Decoupled_8/9/10(rxreq/rxrsp/rxdat, 入)由
      txState 驱动, TX=Decoupled2LCredit_5/1/2(txsnp/txrsp/txdat, 出)由 rxState 驱动。
      tx.ack = RegNext(tx.req) | ~(三 RX 子模块 reclaim 全 1); rx.req=~reset; rxsactive
      =1; syscoack=RegNext(syscoreq)。

核心逻辑 = LINKACTIVE 4 态机 (txState/rxState): golden 用 _GEN LUT
  _GEN[{req,ack}] = {STOP, ACTIVATE, ..} 展开式, 与 linkmonitor_pkg::link_state(req,ack)
  逐态一致 (00=STOP/10=ACTIVATE/11=RUN/01=DEACTIVATE)。可读核把 LUT 改写成 link_state()
  调用, 其余握手寄存器 / 6 个 flit 转换子模块实例 **逐字保留** golden(结构 glue)。

flit 转换子模块两侧 elaborate 白盒 (同已绿 LinkMonitor): Queue4/15_CHI* + ram_Nx*
  纯 firtool 寄存器阵列(非 vendor 宏, 无 _ext 未解析叶子)。UT/FM 两侧共用全链 golden RTL。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UTROOT = ROOT / "verif" / "ut"

# 每变体: (tx_req信号名, tx_ack信号名, rx_req信号名, rx_ack信号名) 供 link_state 调用,
# 与 golden _txState_T/_rxState_T 的 {高位=req, 低位=ack} 一致。
VARIANTS = {
    "ReceiverLinkMonitor": {
        # _txState_T = {io_in_tx_linkactivereq, hetVecWire_0_linkactiveack}
        # _rxState_T = {~reset, io_in_rx_linkactiveack}
        "tx_req": "io_in_tx_linkactivereq",
        "tx_ack": "hetVecWire_0_linkactiveack",
        "rx_req": "~reset",
        "rx_ack": "io_in_rx_linkactiveack",
    },
    "TransmitterLinkMonitor": {
        # _txState_T = {~reset, io_out_tx_linkactiveack}
        # _rxState_T = {io_out_rx_linkactivereq, hetVecWire_1_linkactiveack}
        "tx_req": "~reset",
        "tx_ack": "io_out_tx_linkactiveack",
        "rx_req": "io_out_rx_linkactivereq",
        "rx_ack": "hetVecWire_1_linkactiveack",
    },
}


def parse_port_block(text, module):
    """返回 (port_decl_str, ports[list of (dir,width,name)])."""
    m = re.search(rf"module\s+{module}\s*\((.*?)\n\);", text, re.S)
    if not m:
        raise RuntimeError(f"module {module} not found")
    block = m.group(1)
    ports = []
    for raw in block.splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        if not mm:
            raise RuntimeError(f"cannot parse port: {raw}")
        d, w, n = mm.groups()
        ports.append((d, w or "", n))
    return block, ports


def rebuild_header(ports, decls_indent="  "):
    lines = []
    for d, w, n in ports:
        gap = " " if w else ""
        lines.append(f"{decls_indent}{d} {w}{gap}{n}")
    return ",\n".join(lines)


def extract_body(text, module):
    """返回 module port 块之后到 endmodule 之前的 body 文本。"""
    m = re.search(rf"module\s+{module}\s*\(.*?\n\);\n(.*)\nendmodule", text, re.S)
    if not m:
        raise RuntimeError(f"cannot extract body of {module}")
    return m.group(1)


# 匹配 golden 的 FSM LUT 段 (从第一处 _txState_T 声明 到 ENABLE_INITIAL_REG_ 块结束),
# 整段替换成可读版。用锚点切片而非逐行正则, 保证不误伤。
def rewrite_fsm(body, v):
    # 锚点 1: '  wire [1:0]      _txState_T =' 起
    a = body.index("  wire [1:0]      _txState_T =")
    # 锚点 2: ENABLE_INITIAL_REG_ 段结束 '`endif // ENABLE_INITIAL_REG_' 后
    end_tok = "`endif // ENABLE_INITIAL_REG_"
    b = body.index(end_tok) + len(end_tok)
    head = body[:a]
    tail = body[b:]

    readable = f"""  // ---- LINKACTIVE 4 态机 (txState/rxState): 由对端 {{req, ack}} 译码 ----
  //   golden _GEN LUT (00=STOP/10=ACTIVATE/11=RUN/01=DEACTIVATE) 与
  //   linkmonitor_pkg::link_state(req, ack) 逐态一致, 此处改写成可读调用。
  //   txState 送 flit 转换子模块 io_state_state (RX 收方向); rxState 送 TX 发方向。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      txState <= STOP;
      rxState <= STOP;
    end
    else begin
      txState <= link_state({v['tx_req']}, {v['tx_ack']});
      rxState <= link_state({v['rx_req']}, {v['rx_ack']});
    end
  end
"""
    # 保留 golden 的另一段 always @(posedge clock) 打拍寄存器(REG 更新)——它在 head 之后、
    # 但原文里紧跟在 FSM always 之后。extract 时它落在被切走的区间? 不: 它在 _GEN always 之后、
    # ENABLE_INITIAL_REG_ 之前, 属于被切区间。需从原 body 里单独救回。
    reg_always = _extract_reg_always(body)
    return head + readable + reg_always + tail


def _extract_reg_always(body):
    """救回 FSM always 之后、initial 块之前的 'always @(posedge clock) begin ... end' 打拍段。"""
    # 该段形如: always @(posedge clock) begin\n    <REG <= ...>;\n  end // always @(posedge)
    m = re.search(r"(  always @\(posedge clock\) begin\n(?:.*?\n)*?  end // always @\(posedge\)\n)", body)
    if not m:
        # 可能是单行 body 版本
        m = re.search(r"(  always @\(posedge clock\)\n    [^\n]+\n)", body)
    if not m:
        raise RuntimeError("cannot find REG always block")
    seg = m.group(1)
    # 改成 always_ff 更可读, 语义等价
    seg = seg.replace("always @(posedge clock)", "always_ff @(posedge clock)")
    seg = seg.replace(" // always @(posedge)", "")
    return "  // ---- 握手打拍寄存器 (RegNext, 无复位, 与 golden 一致) ----\n" + seg


def gen_core(top, v):
    text = (GOLDEN / f"{top}.sv").read_text()
    _, ports = parse_port_block(text, top)
    body = extract_body(text, top)
    body = rewrite_fsm(body, v)
    hdr = rebuild_header(ports)
    banner = f"""// =============================================================================
//  {top} —— CHI 链路层监视器 (可读核 xs_{top}_core)
// -----------------------------------------------------------------------------
//  XSTop OpenNCB(CHI↔AXI 桥)侧 CHI 链路层监视器, 与已绿 LinkMonitor 同族。
//  自身逻辑 = LINKACTIVE 4 态机 (txState/rxState, 由对端 {{req,ack}} 译码) +
//  链路握手打拍寄存器。flit↔Decoupled+L-Credit 互转由 6 个子模块完成(结构 glue,
//  逐字保留 golden 例化), 各子模块回报 reclaimLCredit 供去激活握手。
//  golden 的 _GEN LUT 状态转移改写成 linkmonitor_pkg::link_state() 可读调用
//  (00=STOP/10=ACTIVATE/11=RUN/01=DEACTIVATE, 与 golden 逐态一致)。
//
//  验证: golden 同名模块例化本核; 6 个 flit 转换子模块(Queue4/15_CHI*+ram)两侧
//  elaborate 白盒(同 LinkMonitor); UT 双例化逐拍对拍; FM signoff-strict 签名分析。
// =============================================================================
module xs_{top}_core
  import linkmonitor_pkg::*;
(
{hdr}
);
"""
    return banner + body + "\nendmodule\n"


def gen_wrapper(top):
    text = (GOLDEN / f"{top}.sv").read_text()
    _, ports = parse_port_block(text, top)
    hdr = rebuild_header(ports)
    lines = [f"// 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改",
             f"module {top}(", hdr, ");", "",
             f"  xs_{top}_core u_core ("]
    for i, (_, _, n) in enumerate(ports):
        c = "," if i + 1 < len(ports) else ""
        lines.append(f"    .{n}({n}){c}")
    lines += ["  );", "endmodule", ""]
    return "\n".join(lines)


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


def gen_tb(top):
    text = (GOLDEN / f"{top}.sv").read_text()
    _, ports = parse_port_block(text, top)
    variant = f"{top}_xs"
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改",
        f"// {top} 双例化逐拍比对: golden {top} vs 可读 {variant}(经 wrapper)。",
        "// 6 个 flit 转换子模块两侧共用同一份 golden RTL(白盒)。全随机激励。",
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
    return "\n".join(L)


# 每变体的 6 个 flit 转换子模块 + 其嵌套 queue/ram golden 依赖文件。
FLIT_DEPS = {
    "ReceiverLinkMonitor": [
        "LCredit2Decoupled_8.sv", "LCredit2Decoupled_9.sv", "LCredit2Decoupled_10.sv",
        "Decoupled2LCredit_5.sv", "Decoupled2LCredit_1.sv", "Decoupled2LCredit_2.sv",
        "Queue4_CHIREQ.sv", "Queue4_CHIRSP.sv", "Queue4_CHIDAT.sv",
        "ram_4x151.sv", "ram_4x73.sv", "ram_4x422.sv",
    ],
    "TransmitterLinkMonitor": [
        "Decoupled2LCredit.sv", "Decoupled2LCredit_1.sv", "Decoupled2LCredit_2.sv",
        "LCredit2Decoupled_11.sv", "LCredit2Decoupled_3.sv", "LCredit2Decoupled_4.sv",
        "Queue15_CHISNP.sv", "Queue15_CHIRSP.sv", "Queue15_CHIDAT.sv",
        "ram_15x115.sv", "ram_15x73.sv", "ram_15x422.sv",
    ],
}


def gen_makefile(top):
    deps = FLIT_DEPS[top]
    golden_flit = " \\\n              ".join(f"$(GOLDEN_RTL)/{d}" for d in deps)
    ref_deps = " ".join(deps)
    return f"""# 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改
MODULE = {top}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/linkmonitor_pkg.sv \\
           $(RTL_DIR)/uncore/{top}.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden {top} + 6 个 flit 转换子模块(两侧共用同一例化, 白盒)。
GOLDEN_SRCS = $(GOLDEN_RTL)/{top}.sv \\
              {golden_flit}

# impl 侧(WRAPPER_SRCS)加同套 golden flit 文件 ⇒ 两侧都 elaborate 出这 6 个子模块
# = 全白盒等价比对(非黑盒), signoff-strict 下无 unresolved/blackbox 对象。
FLIT_GOLDEN = {golden_flit}

WRAPPER_SRCS = $(RTL_DIR)/uncore/{top}_wrapper.sv $(FLIT_GOLDEN)
FM_VARIANTS = {top}
# ref 侧(FM_REF_DEPS)加同套 golden flit 文件 ⇒ ref {top} 例化解析为真 RTL。
FM_REF_DEPS_{top} = {ref_deps}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    for top, v in VARIANTS.items():
        (RTL / f"{top}.sv").write_text(gen_core(top, v))
        (RTL / f"{top}_wrapper.sv").write_text(gen_wrapper(top))
        ut = UTROOT / top
        ut.mkdir(parents=True, exist_ok=True)
        (ut / "variants_xs.sv").write_text(
            "// 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改\n" +
            gen_wrapper(top).split("\n", 1)[1].replace(f"module {top}(", f"module {top}_xs(", 1)
        )
        (ut / "tb.sv").write_text(gen_tb(top))
        (ut / "Makefile").write_text(gen_makefile(top))
        print(f"generated {top}: core / wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
