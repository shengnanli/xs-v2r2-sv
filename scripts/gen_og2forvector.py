#!/usr/bin/env python3
"""
Og2ForVector (向量操作数收集第 2 级 Og2 流水寄存器组) 可读 SV 生成器。

== 设计意图 (来自人写 Chisel: backend/issue/Scheduler / OgStage2 vector 部分) ==
Og2ForVector 是向量执行前的「操作数收集 stage-2」纯流水寄存器组。它有 7 条通道:
    VfArith: (0_0)(0_1)(1_0)(1_1)(2_0)   —— 5 条向量算术 exu 入口
    VecMem : (0_0)(1_0)                   —— 2 条向量访存 exu 入口
每拍对每条通道做一件事: 若上游 Og1 给出 valid 且**该 uop 未被 flush 命中**, 则把整包
payload (fuType/fuOpType/src0..4/robIdx/pdest/vpu.*/dataSources/perfDebugInfo/imm...) 打一拍
存入 s2_toExuData_<lane>_*, 并把 s2_toExuValid_<lane> 置 1; 否则该通道下拍 valid=0。
输出级把这些寄存器直接连到 io_toVfArithExu / io_toVecMemExu, 并给回 Og2Resp 应答
(valid 但下游 not-ready => 让 IQ 重发, 否则 success)。

== flush 命中判定 (本模块唯一的「逻辑」) ==
flush 有两个来源, 都用「robIdx 不比 flush 更老」判据 (older-than 语义):
  · 当拍 flush   : io_flush_valid & robIdxHit(in.robIdx, io_flush_bits)
  · 上拍 flush   : s2_flush_next_valid_last_REG_k & robIdxHit(in.robIdx, s2_flush_next_bits_r_k)
其中 robIdxHit(a, f) = f.level & a==f.robIdx        // 精确同一条 (flushItself)
                      | (a.flag ^ f.flag ^ a.value > f.value)   // a 不比 f 更老
命中任一 => 该通道被冲刷, valid_next=0。s2_flush_next_* 是把 flush 信息延迟一拍的副本
(Chisel 的 s2_flush := RegNext(io.flush) 展平), 每拍在 io_flush_valid 时更新 bits、
无条件更新 valid_last。

== 反套壳 ==
本核用命名的 flushHit 函数替换 golden 的 _GEN/_T_ 临时量; payload 打拍保留 golden 已
可读的 s2_toExuData_<lane>_<field> 名 (逐字段忠实复刻, 非 svh 套壳)。生成器从 golden
机械解析通道/字段/输出连线, 保证位级一致。厂商/逻辑子模块: 无 (纯逻辑, 0 子模块)。

产物:
  rtl/backend/Og2ForVector.sv          —— golden 同名可读核 (self-contained, 例化即顶层)
  verif/ut/Og2ForVector/{variants_xs.sv,tb.sv,Makefile}
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"

# 7 条通道: (lane_suffix, 输入源前缀)。lane_suffix 用于 s2_toExuValid_/s2_toExuData_ 名。
LANES = [
    ("0_0", "io_fromOg1VfArith_0_0"),
    ("0_1", "io_fromOg1VfArith_0_1"),
    ("1_0", "io_fromOg1VfArith_1_0"),
    ("1_1", "io_fromOg1VfArith_1_1"),
    ("2_0", "io_fromOg1VfArith_2_0"),
    ("3_0", "io_fromOg1VecMem_0_0"),
    ("4_0", "io_fromOg1VecMem_1_0"),
]


def parse_ports(gsv):
    m = re.search(r"^module Og2ForVector\((.*?)\n\);", gsv, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            if pm.group(3) in ("clock", "reset"):
                continue
            ww = int(pm.group(2)) + 1 if pm.group(2) else 1
            res.append((pm.group(1), ww, pm.group(3)))
    return res


def parse_reg_decls(gsv):
    """收集所有 reg 声明 (名字 -> 位宽), 保留 golden 顺序。"""
    regs = []
    for m in re.finditer(r"^\s*reg\s+(?:\[(\d+):0\])?\s*(\w+);", gsv, re.M):
        ww = int(m.group(1)) + 1 if m.group(1) else 1
        regs.append((m.group(2), ww))
    return regs


def parse_latch_blocks(gsv):
    """从主 always 块解析每条通道 if(_GEN) 内的字段打拍 (lane -> [(reg, rhs), ...])。"""
    m = re.search(r"always @\(posedge clock\) begin\n(.*?)\n    if \(io_flush_valid\)",
                  gsv, re.S)
    body = m.group(1)
    lane_by_gen = {}  # _GEN name -> lane suffix
    for lane, src in LANES:
        gm = re.search(rf"s2_toExuValid_{lane} <= (_GEN(?:_\d+)?);", gsv)
        lane_by_gen[gm.group(1)] = lane
    blocks = {}
    for gm in re.finditer(r"if \((_GEN(?:_\d+)?)\) begin\n(.*?)\n    end", body, re.S):
        gen, blk = gm.group(1), gm.group(2)
        lane = lane_by_gen[gen]
        fields = re.findall(r"(s2_toExuData_\w+) <=\s*(io_\w+);", blk)
        blocks[lane] = fields
    return blocks


def parse_output_assigns(gsv):
    """输出 assign: 保留完整 rhs (含 Og2Resp 的三元/取反表达式)。"""
    res = []
    for m in re.finditer(r"^\s*assign\s+(io_\w+)\s*=\s*(.+?);", gsv, re.S | re.M):
        rhs = re.sub(r"\s+", " ", m.group(2).strip())
        res.append((m.group(1), rhs))
    return res


def emit_core(ports, regs, latch, assigns, modname, instless=True):
    L = []
    L.append("// 自动生成: scripts/gen_og2forvector.py —— 勿手改 (逻辑为从设计意图的可读重写)")
    L.append("// Og2ForVector: 向量操作数收集 stage-2 流水寄存器组 (7 通道 payload 打拍 + flush 冲刷)。")
    L.append("// 详见脚本头注释。无子模块; flush 命中用命名 flushHit 函数替换 golden _GEN/_T_ 临时量。")
    L.append(f"module {modname}(")
    L.append("  input  clock,")
    L.append("  input  reset,")
    pdecls = []
    for d, ww, n in ports:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        pdecls.append(f"  {d:6s} {ws}{n}")
    L.append(",\n".join(pdecls))
    L.append(");")
    L.append("")
    # reg 声明 (保留 golden 名与宽度)
    L.append("  // ---- stage-2 payload / valid / flush-pipeline 寄存器 (golden 同名, 忠实复刻) ----")
    for n, ww in regs:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        L.append(f"  reg  {ws}{n};")
    L.append("")
    # flushHit 命名函数
    L.append("  // robIdxHit(a, fFlag, fValue, fLevel) = flush 命中该 uop:")
    L.append("  //   fLevel & a==f (精确同一条 flushItself) | (a.flag ^ f.flag ^ a.value > f.value)")
    L.append("  //   (a 不比 f 更老 => 被更老/同源 flush 冲刷)。")
    L.append("  function automatic logic robIdxHit(")
    L.append("      input logic       aFlag, input logic [7:0] aValue,")
    L.append("      input logic       fFlag, input logic [7:0] fValue, input logic fLevel);")
    L.append("    robIdxHit = fLevel & ({aFlag, aValue} == {fFlag, fValue})")
    L.append("              | (aFlag ^ fFlag ^ (aValue > fValue));")
    L.append("  endfunction")
    L.append("")
    # per-lane flush-hit wires + valid-next
    L.append("  // 每条通道: 未被当拍/上拍 flush 命中 & 上游 valid => 下拍 valid。")
    for lane, src in LANES:
        idx = f"s2_flush_next"
        # prev-flush regs suffix: lane 0_0 -> "", 0_1 -> _1, ... map by LANES order
        pass
    # map lane -> prev-flush reg index (golden: REG, REG_1..REG_6 in LANES order)
    for i, (lane, src) in enumerate(LANES):
        suf = "" if i == 0 else f"_{i}"
        L.append(f"  wire flushHit_{lane} =")
        L.append(f"      (s2_flush_next_valid_last_REG{suf}")
        L.append(f"       & robIdxHit({src}_bits_robIdx_flag, {src}_bits_robIdx_value,")
        L.append(f"                   s2_flush_next_bits_r{suf}_robIdx_flag,")
        L.append(f"                   s2_flush_next_bits_r{suf}_robIdx_value,")
        L.append(f"                   s2_flush_next_bits_r{suf}_level))")
        L.append(f"      | (io_flush_valid")
        L.append(f"         & robIdxHit({src}_bits_robIdx_flag, {src}_bits_robIdx_value,")
        L.append(f"                     io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value,")
        L.append(f"                     io_flush_bits_level));")
        L.append(f"  wire fire_{lane} = {src}_valid & ~flushHit_{lane};")
    L.append("")
    # main always block
    L.append("  always @(posedge clock) begin")
    for lane, src in LANES:
        L.append(f"    s2_toExuValid_{lane} <= fire_{lane};")
    L.append("")
    for lane, src in LANES:
        fields = latch[lane]
        L.append(f"    if (fire_{lane}) begin")
        for reg, rhs in fields:
            L.append(f"      {reg} <= {rhs};")
        L.append(f"    end")
    L.append("")
    L.append("    // flush 信息延迟一拍副本 (s2_flush := RegNext(io.flush) 的 bits 部分)。")
    L.append("    if (io_flush_valid) begin")
    for i, (lane, src) in enumerate(LANES):
        suf = "" if i == 0 else f"_{i}"
        L.append(f"      s2_flush_next_bits_r{suf}_robIdx_flag  <= io_flush_bits_robIdx_flag;")
        L.append(f"      s2_flush_next_bits_r{suf}_robIdx_value <= io_flush_bits_robIdx_value;")
        L.append(f"      s2_flush_next_bits_r{suf}_level        <= io_flush_bits_level;")
    L.append("    end")
    L.append("")
    L.append("    // 立即数随 VfArith(0_1) 一并打拍 (io.fromOg1ImmInfo(1))。")
    L.append("    if (io_fromOg1VfArith_0_1_valid) begin")
    L.append("      r_1_imm     <= io_fromOg1ImmInfo_1_imm;")
    L.append("      r_1_immType <= io_fromOg1ImmInfo_1_immType;")
    L.append("    end")
    L.append("  end")
    L.append("")
    # flush valid-last pipeline (async reset)
    L.append("  // flush valid 延迟一拍 (复位清零)。")
    L.append("  always @(posedge clock or posedge reset) begin")
    L.append("    if (reset) begin")
    for i in range(len(LANES)):
        suf = "" if i == 0 else f"_{i}"
        L.append(f"      s2_flush_next_valid_last_REG{suf} <= 1'h0;")
    L.append("    end")
    L.append("    else begin")
    for i in range(len(LANES)):
        suf = "" if i == 0 else f"_{i}"
        L.append(f"      s2_flush_next_valid_last_REG{suf} <= io_flush_valid;")
    L.append("    end")
    L.append("  end")
    L.append("")
    # outputs
    L.append("  // ---- 输出连线 (寄存器直读 + Og2Resp 应答) ----")
    for lhs, rhs in assigns:
        L.append(f"  assign {lhs} = {rhs};")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def emit_tb(ports, variant_text):
    ins = [(ww, n) for d, ww, n in ports if d == "input"]
    outs = [(ww, n) for d, ww, n in ports if d == "output"]
    L = ["// 自动生成: gen_og2forvector.py —— 勿手改", "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for ww, n in ins:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        L.append(f"  logic {ws}{n};")
    for ww, n in outs:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        L.append(f"  wire {ws}g_{n};")
        L.append(f"  wire {ws}i_{n};")
    L.append("")

    def inst(modname, instname, prefix):
        conns = ["    .clock(clk)", "    .reset(rst)"]
        for d, ww, n in ports:
            conns.append(f"    .{n}({n})" if d == "input" else f"    .{n}({prefix}{n})")
        return f"  {modname} {instname} (\n" + ",\n".join(conns) + "\n  );"
    L.append(inst("Og2ForVector", "u_g", "g_"))
    L.append(inst("Og2ForVector_xs", "u_i", "i_"))
    L.append("")
    L.append("  always @(posedge clk) if (!rst) begin")
    for ww, n in ins:
        if ww <= 32:
            L.append(f"    {n} <= $urandom;")
        else:
            chunks = (ww + 31) // 32
            parts = ",".join("$urandom" for _ in range(chunks))
            L.append(f"    {n} <= {{{parts}}};")
    # bias flush/robIdx to exercise flush-hit paths
    L.append("    // 偏置: 让 robIdx / flush 更常撞上以覆盖 flush 冲刷路径。")
    L.append("    io_flush_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VfArith_0_0_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VfArith_0_1_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VfArith_1_0_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VfArith_1_1_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VfArith_2_0_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VecMem_0_0_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("    io_fromOg1VecMem_1_0_bits_robIdx_value <= $urandom % 8'd16;")
    L.append("  end")
    L.append("")
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for ww, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f'      if(errors<=80) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    L.append("  end")
    L.append("")
    L.append("  initial begin")
    L.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    L.append("    repeat (NCYCLES) @(posedge clk);")
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    L.append("")
    vdir = XSSV / "verif/ut/Og2ForVector"
    vdir.mkdir(parents=True, exist_ok=True)
    (vdir / "tb.sv").write_text("\n".join(L))
    (vdir / "variants_xs.sv").write_text(variant_text)


def emit_makefile():
    L = ["MODULE = Og2ForVector", "",
         "RTL_DIR = ../../../rtl",
         "GOLDEN_RTL = ../../../golden/chisel-rtl", "",
         "# 手写可读核 (golden 同名 self-contained, 纯逻辑无子模块)。",
         "# UT 双例化: golden Og2ForVector (u_g) vs 可读核 _xs 变体 (u_i)。为避免 UT 编译期与",
         "# golden 同名撞名, golden-名可读核 Og2ForVector.sv 只进 FM impl 侧 (WRAPPER_SRCS)。",
         "RTL_SRCS     =",
         "WRAPPER_SRCS = $(RTL_DIR)/backend/Og2ForVector.sv",
         "GOLDEN_SRCS  = $(GOLDEN_RTL)/Og2ForVector.sv",
         "TB_SRCS      = variants_xs.sv tb.sv", "",
         "FM_VARIANTS = Og2ForVector", "",
         "include ../../../scripts/ut_common.mk", "",
         "VCS += +define+SYNTHESIS", ""]
    (XSSV / "verif/ut/Og2ForVector/Makefile").write_text("\n".join(L))


def main():
    gsv = (GOLDEN / "Og2ForVector.sv").read_text()
    ports = parse_ports(gsv)
    regs = parse_reg_decls(gsv)
    latch = parse_latch_blocks(gsv)
    assigns = parse_output_assigns(gsv)

    core = emit_core(ports, regs, latch, assigns, "Og2ForVector")
    (BK / "Og2ForVector.sv").write_text(core)

    # _xs variant: identical body, module renamed.
    xs = core.replace("module Og2ForVector(", "module Og2ForVector_xs(", 1)
    xs = "// Og2ForVector_xs —— UT 双例化变体 (与可读核逐字一致, 仅模块名加 _xs)。\n" + xs
    emit_tb(ports, xs)
    emit_makefile()
    print(f"[Og2ForVector] ports={len(ports)} regs={len(regs)} "
          f"lanes={len(latch)} assigns={len(assigns)}")


if __name__ == "__main__":
    main()
