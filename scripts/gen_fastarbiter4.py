#!/usr/bin/env python3
"""生成 FastArbiter 族 16 输入变体 (_4/_5/_7/_8) 的可读核 / wrapper / 变体 / UT / Makefile。

FastArbiter_4/5/7/8 是 L2 slice MSHRCtl 的 **16 输入** round-robin 仲裁器
(16 个 MSHR 各出一路请求, 与 SNXbar/RNXbar 的 4 输入变体 _27/_44/_46/_47 及
MSHRBuffer 侧的 _1/_2/_28/_29 同族; NUM=16)。golden MSHRCtl 里的例化名/通道:

  FastArbiter_4 : txreq_arb     (CHI TXREQ  请求: addr/opcode/pCrdType/expCompAck...)
  FastArbiter_5 : txrsp_arb     (CHI TXRSP  响应: tgtID/txnID/traceTag; opcode 是无输入
                                 对应的**常量输出** {3'h0,|chosenOH,1'h0} = CompAck)
  FastArbiter_7 : source_b_arb  (SourceB 探测请求: tag/set/param/alias; opcode 常量
                                 (|chosenOH)?3'h6:0 = Probe)
  FastArbiter_8 : mshr_task_arb (MainPipe TaskBundle ~79 字段; mshrTask 常量 |chosenOH)

四变体 16 路输入字段完全对称 (无 _28 那种 input-4 专属字段); 除上述常量输出字段外,
输出 = 胜者 payload one-hot OR 归约。仲裁核 (chosenOH/pendingMask/rrGrantMask/rrSelOH/
io_out_valid) 与族内其余变体逐位一致 (utility.FastArbiter 带挂起记忆 round-robin):

  rrSelOH  = lowest_oh(rrGrantMask & pendingMask)
  chosenOH = (rrSelOH 命中 valid) ? rrSelOH : lowest_oh(valids)
  更新 (io_out_ready & |valids):
    pendingMask <= valids & ~chosenOH
    rrGrantMask <= gt_mask(chosenOH)        // bit[i] = |chosenOH[i-1:0], bit0 恒 0
  io_in_i_ready = chosenOH[i] & io_out_ready ; io_out_valid = |valids

payload 打包成 packed struct 后用胜者 one-hot OR 归约多路选择到 io_out (同 _77/_78/_79
可读核样式)。端口全标量/向量, wrapper/变体直接同名透传例化核。UT: golden vs 可读核双
例化, 全随机激励 (随机 valids + 随机 io_out_ready 自然遍历轮转相位), 逐拍比对全部输出。
FM: ref = golden 叶子 NN.sv; impl = 可读核 + wrapper。无子例化/无黑盒/signoff-strict;
pendingMask_reg[0] 是本族 round-robin 结构死位 (rrGrantMask[0]≡0 掩掉, 两侧同名对称
cone-dead) → FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM 实开比较证等价
(非 waiver), 同已绿 FastArbiter_1/2/28/29。
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "golden" / "chisel-rtl"
RTL = ROOT / "rtl" / "uncore"
UTROOT = ROOT / "verif" / "ut"

NUM = 16
VARIANTS = ["FastArbiter_4", "FastArbiter_5", "FastArbiter_7", "FastArbiter_8"]

# 通道名 (仅用于核头注释)
CHAN = {
    "FastArbiter_4": "MSHRCtl txreq_arb (CHI TXREQ)",
    "FastArbiter_5": "MSHRCtl txrsp_arb (CHI TXRSP)",
    "FastArbiter_7": "MSHRCtl source_b_arb (SourceB probe)",
    "FastArbiter_8": "MSHRCtl mshr_task_arb (MainPipe TaskBundle)",
}

# 无输入对应的常量输出字段 (逐一与 golden assign 核对过, 全是 |chosenOH 的函数):
#   _4 qos   = {4{chosenOH[0]}}|...|{4{chosenOH[15]}} ≡ {4{|chosenOH}}
#   _4 size  = (|chosenOH) ? 3'h6 : 3'h0
#   _4 memAttr_cacheable = |chosenOH ;  _4 snpAttr = |chosenOH
#   _5 opcode = {3'h0, |chosenOH, 1'h0}   (CHI CompAck)
#   _7 opcode = (|chosenOH) ? 3'h6 : 3'h0 (TileLink Probe)
#   _8 mshrTask = |chosenOH
CONST_OUT = {
    "FastArbiter_4": {
        "qos":               "{4{anyChosen}}",
        "size":              "anyChosen ? 3'h6 : 3'h0",
        "memAttr_cacheable": "anyChosen",
        "snpAttr":           "anyChosen",
    },
    "FastArbiter_5": {
        "opcode": "{3'h0, anyChosen, 1'h0}",
    },
    "FastArbiter_7": {
        "opcode": "anyChosen ? 3'h6 : 3'h0",
    },
    "FastArbiter_8": {
        "mshrTask": "anyChosen",
    },
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


def gen_wrapper(top, ports):
    core = f"xs_{top}_core"
    return ("// 自动生成：scripts/gen_fastarbiter4.py —— 勿手改\n"
            + header(top, ports) + inst(core, "u_core", ports) + "\nendmodule\n")


def gen_variant(top, ports):
    core = f"xs_{top}_core"
    return ("// 自动生成：scripts/gen_fastarbiter4.py —— 勿手改\n"
            + header(f"{top}_xs", ports) + inst(core, "u_core", ports) + "\nendmodule\n")


def payload_fields(ports, k):
    """从 io_in_k_bits_* 端口提取 payload (name, width) 有序列表。"""
    pre = f"io_in_{k}_bits_"
    return [(n[len(pre):], w) for d, w, n in ports if d == "input" and n.startswith(pre)]


# SV 保留字不能做 struct 成员名 (_7/_8 的 payload 字段 `alias`); 成员名加 _f 后缀,
# 端口名不受影响 (io_in_k_bits_alias 是完整标识符, 非保留字)。
SV_RESERVED = {"alias"}


def mname(f):
    return f + "_f" if f in SV_RESERVED else f


def out_fields(ports):
    pre = "io_out_bits_"
    return [(n[len(pre):], w) for d, w, n in ports if d == "output" and n.startswith(pre)]


def audit(top, ports):
    """fail-closed 审计: 16 路输入字段对称; 输出字段 = 共有字段 + CONST_OUT 表; 宽度一致。"""
    f0 = payload_fields(ports, 0)
    for k in range(1, NUM):
        if payload_fields(ports, k) != f0:
            raise RuntimeError(f"{top}: input {k} fields differ from input 0")
    fin = dict(f0)
    fout = dict(out_fields(ports))
    const = CONST_OUT[top]
    only_out = {f for f in fout if f not in fin}
    if only_out != set(const):
        raise RuntimeError(f"{top}: const-out mismatch: golden-only={only_out} table={set(const)}")
    for f, w in fin.items():
        if f not in fout or fout[f] != w:
            raise RuntimeError(f"{top}: shared field {f} width mismatch in={w} out={fout.get(f)}")
    return f0


def gen_core(top, ports):
    fields = audit(top, ports)
    const = CONST_OUT[top]
    port_decls = ",\n".join(decl(*p) for p in ports)

    # payload struct (字段序 = golden 端口序)
    struct_lines = ["  typedef struct packed {"]
    for f, w in fields:
        gap = " " if w else ""
        struct_lines.append(f"    logic {w}{gap}{mname(f)};")
    struct_lines.append("  } flit_t;")
    struct = "\n".join(struct_lines)

    # pin[k] 命名 struct 字面量 (每字段一行, _8 有 79 字段)
    pin_lines = []
    for k in range(NUM):
        pin_lines.append(f"  assign pin[{k}] = '{{")
        for i, (f, _) in enumerate(fields):
            c = "," if i + 1 < len(fields) else ""
            pin_lines.append(f"    {mname(f)}:io_in_{k}_bits_{f}{c}")
        pin_lines.append("  };")
    pins = "\n".join(pin_lines)

    valids = ", ".join(f"io_in_{k}_valid" for k in range(NUM - 1, -1, -1))

    readys = "\n".join(f"  assign io_in_{k}_ready = chosenOH[{k}] & io_out_ready;"
                       for k in range(NUM))

    # 输出赋值 (按 golden 端口序: 共有字段取 psel.<f>, 常量字段取 CONST_OUT 表)
    out_lines = []
    for f, _ in out_fields(ports):
        rhs = const[f] if f in const else f"psel.{mname(f)}"
        out_lines.append(f"  assign io_out_bits_{f} = {rhs};")
    outs = "\n".join(out_lines)

    return f"""// =============================================================================
//  {top} —— {CHAN[top]} 16 路 round-robin 仲裁器 (可读核 xs_{top}_core)
// -----------------------------------------------------------------------------
//  L2 slice MSHRCtl 的 16 输入仲裁器: 16 个 MSHR 各出一路请求, 轮转选一路发往下游。
//  与 FastArbiter_1/2/27/28/29/44/46/47 同族 (utility.FastArbiter 带挂起记忆
//  round-robin), NUM=16; 本核用通用循环复刻 golden 的 16 位展平位表达式, 逐位等价:
//    rrSelOH  = lowest_oh(rrGrantMask & pendingMask)
//    chosenOH = (rrSelOH 命中 valid) ? rrSelOH : lowest_oh(valids)
//    pendingMask <= valids & ~chosenOH; rrGrantMask <= gt_mask(chosenOH)  (下游 ready 时)
//  握手: io_in_i_ready = chosenOH[i] & io_out_ready; io_out_valid = |valids。
//  payload 打包成 packed struct 后用胜者 one-hot OR 归约多路选择到 io_out。
//  无输入对应的常量输出字段 (忠实 golden, 全为 |chosenOH 的函数): {", ".join(sorted(const))}。
// =============================================================================
module xs_{top}_core(
{port_decls}
);

  localparam int unsigned NUM = {NUM};

  // ---- payload (打包成 packed struct, 便于 one-hot OR 多路选择; 字段序 = golden 端口序) ----
{struct}

  flit_t          pin [NUM];
  logic [NUM-1:0] valids;

  assign valids = {{{valids}}};
{pins}

  // ---- round-robin 状态 + 组合选胜 (NUM=16) ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  logic [NUM-1:0] cand;
  logic [NUM-1:0] rrSelOH;
  assign cand    = rrGrantMask & pendingMask;
  assign rrSelOH = cand & (~cand + {{{{(NUM-1){{1'b0}}}}, 1'b1}});   // x & -x = 隔离最低置位
  logic [NUM-1:0] baseOH;
  assign baseOH   = valids & (~valids + {{{{(NUM-1){{1'b0}}}}, 1'b1}});
  assign chosenOH = (|(rrSelOH & valids)) ? rrSelOH : baseOH;

  // gt_mask(chosenOH): bit[i] = OR(chosenOH[i-1:0]); bit0 恒 0。
  logic [NUM-1:0] gtMask;
  always_comb begin
    gtMask = '0;
    for (int i = 0; i < NUM; i++)
      gtMask[i] = |(chosenOH & ((NUM'(1) << i) - NUM'(1)));
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;   // 没被选中的 valid 转入欠服务
      rrGrantMask <= gtMask;               // 优先区推进到本次胜者之后
    end
  end

  // ---- 胜者 payload 多路选择 (one-hot OR 归约, chosenOH 至多一位置位) ----
  flit_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  wire anyChosen = |chosenOH;

  // ---- 握手 ----
{readys}

  assign io_out_valid = |valids;

  // ---- 输出 (共有字段来自 psel; 常量字段忠实 golden) ----
{outs}

endmodule
"""


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
    inputs = [p for p in ports if p[0] == "input" and p[2] not in ("clock", "reset")]
    outputs = [p for p in ports if p[0] == "output"]
    L = [
        "// 自动生成：scripts/gen_fastarbiter4.py —— 勿手改",
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
    return "\n".join(L)


def gen_makefile(top):
    return f"""# 自动生成：scripts/gen_fastarbiter4.py —— 勿手改
MODULE = {top}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/{top}.sv

TB_SRCS = variants_xs.sv tb.sv

# 叶子模块, 无子例化; UT 双例化只需 golden 顶层。
GOLDEN_SRCS = $(GOLDEN_RTL)/{top}.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/{top}_wrapper.sv
FM_VARIANTS = {top}
# FM: ref = golden {top}.sv; impl = 自包含可读核 + wrapper (无 pkg 依赖/无黑盒)。
# 加强证明: pendingMask_reg[0] 是本族 round-robin 结构死位 (rrGrantMask[0]≡0 掩掉),
# 两侧同名对称 cone-dead → FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true 让 FM 实际比较
# 证等价 (非 waiver), 得 0 unread clean SUCCEEDED。须 main 把 {top} 加入 fm_eq.tcl 白名单。

FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS ?= true

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""


def main():
    for top in VARIANTS:
        ports = parse_ports(GOLDEN / f"{top}.sv", top)
        (RTL / f"{top}.sv").write_text(gen_core(top, ports))
        (RTL / f"{top}_wrapper.sv").write_text(gen_wrapper(top, ports))
        ut = UTROOT / top
        ut.mkdir(parents=True, exist_ok=True)
        (ut / "variants_xs.sv").write_text(gen_variant(top, ports))
        (ut / "tb.sv").write_text(gen_tb(top, ports))
        (ut / "Makefile").write_text(gen_makefile(top))
        print(f"generated {top}: core / wrapper / variant / tb / Makefile")


if __name__ == "__main__":
    main()
