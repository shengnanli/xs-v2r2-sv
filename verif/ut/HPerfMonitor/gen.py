#!/usr/bin/env python3
"""生成 HPerfMonitor / HPerfMonitor_1 / HPerfMonitor_2 的 UT testbench（tb.sv）：三对双例化 + 独立参考模型。

一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：每个变体 golden（例化 golden HPerfCounter*）vs
   重写 <变体>_xs（例化重写件 HPerfCounter*_xs → xs_HPerfCounter_core），逐拍比全部 io_perf_*_value。
   全部寄存器无复位、无 reset 端口：暖机 8 拍（最长通路 6 拍）后开始比。
二、独立参考模型（纯 SV，按 utility/HardwarePerfMonitor.scala 定义，不读任何实现内部信号）：
   每个计数器 c：4 个事件号 hpm_event[9:0]/[19:10]/[29:20]/[39:30] 取低 B 位（B = clog2(numPCnt)）选事件增量；
   编号不在 golden 端口表里的槽位是父级接的常数（见 HOLE_CONST，除 Backend 第 96 号为 1 外都是 0）；
   编号 >= numPCnt 是 Chisel 越界下标，G1 firtool 取第 0 项；3 个算子 op0=[44:40]、op1=[49:45]、
   op2=[54:50] 按 combineEvents（op[0] 与 / op[1] 异或 / op[2] 加 / 否则 或，优先级自低位）两级归约。
   tb 每个上升沿按当拍输入算出期望值压进 6 级移位链，输出与 6 拍前的期望逐个核对（golden 与重写件同时核）。
   numPCnt 与"哪些槽位在端口表里"是从 golden 端口表读的接口事实（不是内部实现）。
激励偏置：每个事件号字段 1/2 取在表槽位、1/4 取缺槽 / 越界编号、1/4 任意 10 位；每个算子字段 1/2 取 {0,1,2,4}、
   1/2 任意 5 位（多热走优先级、[4:3] 两侧都不看）；事件增量全随机。
覆盖闸：每个变体的 op2 四种归约（与/异或/加/或）各 >= 1000 拍；事件号缺槽 / 越界各 >= 1000 拍；每个输出位见过 0/1。

用法：python3 gen.py [--check]
"""
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

VARIANTS = [("HPerfMonitor", "m0_", 8), ("HPerfMonitor_1", "m1_", 5), ("HPerfMonitor_2", "m2_", 8)]
# 父级把某些事件槽接成常数（firtool 跨实例常量传播后从端口表里删掉）：缺槽的常数值。
# 这是**父级接线**的事实（golden HPerfCounter* 的 _GEN 表里以字面量出现），不是计数器的实现；
# 除此之外的缺槽一律 0。HPerfMonitor_2（Backend）第 96 号事件接常数 1。
HOLE_CONST = {"HPerfMonitor_2": {96: 1}}
DEPTH = 6

pairs = []
for top, x, n in VARIANTS:
    sets = sorted(int(m.group(1)) for _, _, nm in golden_ports(top)
                  for m in [re.match(r"io_events_sets_(\d+)_value$", nm)] if m)
    npc = max(sets) + 1
    b = max(1, math.ceil(math.log2(npc)))
    present = set(sets)
    hole = HOLE_CONST.get(top, {})
    slot = [f"tb.{x}io_events_sets_{k}_value" if k in present else f"6'd{hole.get(k, 0)}" for k in range(npc)]
    # 越界编号（>= numPCnt）：Chisel 动态下标越界，G1 firtool 一律取第 0 项（CONVENTIONS「越界语义」）
    tbl = ",\n  ".join(slot + [slot[0]] * ((1 << b) - npc))
    decls = f"""
// ============================ 独立参考模型（{top}：numPCnt={npc}，事件号取低 {b} 位）============================
logic [5:0] {x}ref_tbl [{1 << b}];
always_comb {x}ref_tbl = '{{
  {tbl}
}};
logic [5:0] {x}ref_pipe [{DEPTH}][{n}];
int {x}ref_fill = 0, {x}ref_checks = 0, {x}ref_errors = 0;
function automatic logic [5:0] {x}combine(input logic [5:0] a, input logic [5:0] b, input logic [4:0] op);
  if (op[0]) return a & b;
  if (op[1]) return a ^ b;
  if (op[2]) return 6'(a + b);
  return a | b;
endfunction
function automatic logic [5:0] {x}ref_one(input logic [63:0] e);
  logic [5:0] v [4];
  for (int k = 0; k < 4; k++) begin
    logic [9:0] idx;
    idx = e[10*k +: 10];
    v[k] = {x}ref_tbl[idx[{b - 1}:0]];
  end
  return {x}combine({x}combine(v[0], v[1], e[44:40]), {x}combine(v[2], v[3], e[49:45]), e[54:50]);
endfunction
always @(posedge clk) begin
  for (int d = {DEPTH - 1}; d > 0; d--) {x}ref_pipe[d] <= {x}ref_pipe[d - 1];
""" + "\n".join(f"  {x}ref_pipe[0][{c}] <= {x}ref_one(tb.{x}io_hpm_event_{c});" for c in range(n)) + f"""
  {x}ref_fill <= {x}ref_fill + 1;
end
always @(negedge clk) begin
  #4;
  if ({x}ref_fill >= {DEPTH}) begin
    {x}ref_checks++;
""" + "\n".join(
        f"    if (tb.{x}g_io_perf_{c}_value !== {x}ref_pipe[{DEPTH - 1}][{c}] || tb.{x}i_io_perf_{c}_value !== {x}ref_pipe[{DEPTH - 1}][{c}]) begin\n"
        f"      {x}ref_errors++; errors++;\n"
        f"      if ({x}ref_errors <= 10) $display(\"[ORACLE] {top} cyc=%0d perf_{c} ref=%h g=%h i=%h\", cyc, {x}ref_pipe[{DEPTH - 1}][{c}], tb.{x}g_io_perf_{c}_value, tb.{x}i_io_perf_{c}_value);\n"
        f"    end" for c in range(n)) + f"""
  end
end
final $display("[ORACLE] {top} checks=%0d errors=%0d", {x}ref_checks, {x}ref_errors);
"""
    present_list = ", ".join(str(k) for k in sets)
    holes = [k for k in range(npc) if k not in present]
    hole_list = ", ".join(str(k) for k in (holes or [npc]))   # 无缺槽的变体退化为越界编号
    stim = "\n".join(f"""for (int k = 0; k < 4; k++)
  case ($urandom_range(0, 3))
    0, 1: begin
      int pick [$] = '{{{present_list}}};
      @io_hpm_event_{c}[10*k +: 10] = 10'(pick[$urandom_range(0, pick.size() - 1)]);
    end
    2: begin
      int hole [$] = '{{{hole_list}}};
      @io_hpm_event_{c}[10*k +: 10] = ($urandom_range(0, 1) == 0) ? 10'({npc} + $urandom_range(0, {(1 << b) - 1 - npc}))
                                                                  : 10'(hole[$urandom_range(0, hole.size() - 1)]);
    end
    default: ;
  endcase
for (int f = 40; f <= 50; f += 5)
  if ($urandom_range(0, 1) == 0) begin
    case ($urandom_range(0, 3))
      0: @io_hpm_event_{c}[f +: 5] = 5'd0;
      1: @io_hpm_event_{c}[f +: 5] = 5'd1;
      2: @io_hpm_event_{c}[f +: 5] = 5'd2;
      default: @io_hpm_event_{c}[f +: 5] = 5'd4;
    endcase
  end""" for c in range(n))
    absent = [k for k in range(npc) if k not in present]
    absent_cond = " || ".join(f"@io_hpm_event_0[9:0] == 10'd{k}" for k in absent) or "1'b0"
    cov = [
        ("op2_and", "@io_hpm_event_0[50]"),
        ("op2_xor", "!@io_hpm_event_0[50] && @io_hpm_event_0[51]"),
        ("op2_add", "@io_hpm_event_0[52:50] == 3'b100"),
        ("op2_or", "@io_hpm_event_0[52:50] == 3'b000"),
        ("idx_oob", f"@io_hpm_event_0[{b - 1}:0] >= {npc}"),
    ]
    if absent:
        cov.append(("idx_hole", absent_cond))
    pairs.append(Pair(top=top, pfx=x, clocked=True, has_reset=False, warmup=8,
                      decls=decls, stim=stim, cov=cov, cov_min=1000))

txt = render(pairs, header=__doc__.strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
