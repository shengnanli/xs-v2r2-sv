#!/usr/bin/env python3
"""生成 L1Prefetcher 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden L1Prefetcher（+ golden 子模块）vs L1Prefetcher_xs（+ 本仓重写的 5 个子模块），全部输出逐拍比较。
激励要让两条训练链真的产生预取请求，所以不是全随机：
  * stream 训练（io_ld_in_0..2）：1..8 个"流"，每个流在当前 1KB 区域（16 行）里随机挑行访问，每 40 拍整体
    前移一个区域（区域内 16 行都会被访问到 ⇒ 位向量计数过阈值、相邻区域命中 ⇒ 表项变 active），每 ~3000 拍换到新的随机区域；
    3/4 的 load 标 miss（stream 表靠 miss 分配表项）。
  * stride 训练（stride_train_0..2）：8 个 PC，每个 PC 固定一个步长（±1..±8 行），vaddr 按步长前进。
  * TLB：上一拍 golden 发了 tlb 请求，本拍 95% 回应；paddr 85% 落在 PmemRanges 内（L2 出口门控两边都走到）。
  * io_enable / pf_ctrl_enable 各 15/16 为 1；io_l1_req_ready 3/4。
多级过滤队列（MutiLevelPrefetchFilter）的表项字段不复位：等 golden 侧 L1/L2 两张表 32 项全被分配过
（arm），再开始比 —— 与子模块自己的 UT 同一判据。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [49:0] l_stream_cur [8];
logic [49:0] l_stride_cur [8];
logic [49:0] l_stride_pc [8];
logic signed [9:0] l_stride_step [8];
logic l_tlb_req_q = 1'b0;
int unsigned l_nstream = 2;
always @(posedge clk) l_tlb_req_q <= l_u_gold.io_tlb_req_req_valid;
function automatic logic [49:0] l_rand_region();
  if ($urandom_range(0, 3) == 0) return {12'($urandom), 32'($urandom), 6'h0};   // 偶尔用满 50 位地址
  return {14'h0, 4'($urandom), 26'($urandom), 6'h0};
endfunction
initial begin
  for (int i = 0; i < 8; i++) begin
    l_stream_cur[i] = l_rand_region();
    l_stride_cur[i] = l_rand_region();
    l_stride_pc[i]  = {14'h0, 36'($urandom)} & ~50'h1;
    l_stride_step[i] = (10'($urandom_range(1, 8)) <<< 6) * (($urandom_range(0, 1) != 0) ? 1 : -1);
  end
end
"""

STIM = """
if (cyc % 4000 == 0) l_nstream = $urandom_range(1, 8);
if (cyc % 40 == 0) for (int i = 0; i < 8; i++) l_stream_cur[i] += 50'd1024;   // 流向下一个 1KB 区域
if (cyc % 3000 == 0)
  for (int i = 0; i < 8; i++) begin l_stream_cur[i] = l_rand_region(); l_stride_cur[i] = l_rand_region(); end
@io_enable = ($urandom_range(0, 15) != 0);
@pf_ctrl_enable = ($urandom_range(0, 15) != 0);
@io_l1_req_ready = ($urandom_range(0, 3) != 0);
begin
  int k;
  k = $urandom_range(0, l_nstream - 1); @io_ld_in_0_bits_vaddr = l_stream_cur[k] + 50'($urandom_range(0, 15) * 64);
  k = $urandom_range(0, l_nstream - 1); @io_ld_in_1_bits_vaddr = l_stream_cur[k] + 50'($urandom_range(0, 15) * 64);
  k = $urandom_range(0, l_nstream - 1); @io_ld_in_2_bits_vaddr = l_stream_cur[k] + 50'($urandom_range(0, 15) * 64);
  @io_ld_in_0_valid = ($urandom_range(0, 3) == 0);
  @io_ld_in_1_valid = ($urandom_range(0, 3) == 0);
  @io_ld_in_2_valid = ($urandom_range(0, 3) == 0);
  @io_ld_in_0_bits_miss = ($urandom_range(0, 3) != 0);
  @io_ld_in_1_bits_miss = ($urandom_range(0, 3) != 0);
  @io_ld_in_2_bits_miss = ($urandom_range(0, 3) != 0);
  k = $urandom_range(0, 7); @stride_train_0_bits_uop_pc = l_stride_pc[k]; @stride_train_0_bits_vaddr = l_stride_cur[k]; l_stride_cur[k] += 50'($signed(l_stride_step[k]));
  k = $urandom_range(0, 7); @stride_train_1_bits_uop_pc = l_stride_pc[k]; @stride_train_1_bits_vaddr = l_stride_cur[k]; l_stride_cur[k] += 50'($signed(l_stride_step[k]));
  k = $urandom_range(0, 7); @stride_train_2_bits_uop_pc = l_stride_pc[k]; @stride_train_2_bits_vaddr = l_stride_cur[k]; l_stride_cur[k] += 50'($signed(l_stride_step[k]));
end
@io_tlb_req_resp_valid = l_tlb_req_q ? ($urandom_range(0, 99) < 95) : ($urandom_range(0, 99) < 2);
if ($urandom_range(0, 99) < 85) begin
  @io_tlb_req_resp_bits_paddr_0 = {5'h0, 11'($urandom), 32'($urandom)};
  if (@io_tlb_req_resp_bits_paddr_0 < 48'h8000_0000) @io_tlb_req_resp_bits_paddr_0[31] = 1'b1;
end
@io_tlb_req_resp_bits_miss = ($urandom_range(0, 99) < 15);
@io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 99) < 3);
@io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 99) < 3);
@io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 99) < 3);
@io_pmp_resp_ld = ($urandom_range(0, 99) < 3);
@io_pmp_resp_mmio = ($urandom_range(0, 99) < 3);
"""

COV = [
    ("l1_req", "@io_l1_req_valid && @io_l1_req_ready"),
    ("l2_req", "@io_l2_req_valid"),
    ("tlb_req", "@io_tlb_req_req_valid"),
    ("stream_l1", "l_u_gold.stream_bit_vec_array.io_l1_prefetch_req_valid"),
    ("stride_l1", "l_u_gold.stride_meta_array.io_l1_prefetch_req_valid"),
    ("both_l1", "l_u_gold.stream_bit_vec_array.io_l1_prefetch_req_valid && l_u_gold.stride_meta_array.io_l1_prefetch_req_valid"),
    ("stride_l2l3", "l_u_gold.stride_meta_array.io_l2_l3_prefetch_req_valid && !l_u_gold.stream_bit_vec_array.io_l2_l3_prefetch_req_valid"),
    ("pf_ctrl_off", "!@pf_ctrl_enable && l_u_gold.pf_queue_filter.io_l1_req_valid"),
    ("l2_out_of_pmem", "l_u_gold.pf_queue_filter.io_l2_pf_addr_valid && !@io_l2_req_valid && @io_enable && @pf_ctrl_enable"),
]

ARM = ["l_u_gold.pf_queue_filter.l%d_valids_%d" % (lv, i) for lv in (1, 2) for i in range(16)]

# 结构上翻不动的输出位（不是激励不够）：
#   * TLB 请求里过滤队列恒写常量的字段（fullva/cmd/pmp_addr/debug_*/checkfullva/hyperinst/hlvx/kill/
#     isPrefetch/no_translate/frm_mabuf）—— 寄存器只在上电随机初值时不同，arm 之后两侧都是常量；
#   * TLB 请求 vaddr[9:0]：预取以 1KB 区域为单位发请求，低 10 位恒 0；
#   * L1/L2 出口地址 [5:0]：行对齐；is_store 恒 0；pf_source_value 只有 2/3 两个值（[2] 恒 0、[1] 恒 1）；
#   * l2_req_bits_source[4:3]：L1 预取来源编码在 5 位字段里高 2 位恒 0。
TLB_CONST = ["fullva", "cmd", "pmp_addr", "debug_robIdx_value", "debug_robIdx_flag", "debug_isFirstIssue",
             "checkfullva", "hyperinst", "hlvx", "kill", "isPrefetch", "no_translate", "frm_mabuf"]
EXEMPT = (["io_tlb_req_req_bits_" + f for f in TLB_CONST]
          + ["io_tlb_req_req_bits_vaddr[%d]" % b for b in range(10)]
          + ["io_l1_req_bits_paddr[%d]" % b for b in range(6)]
          + ["io_l2_req_bits_addr[%d]" % b for b in range(6)]
          + ["io_l1_req_bits_is_store", "io_l1_req_bits_pf_source_value[1]",
             "io_l1_req_bits_pf_source_value[2]", "io_l2_req_bits_source[3]", "io_l2_req_bits_source[4]"])

PAIRS = [Pair("L1Prefetcher", "l_", clocked=True, stim=STIM, cov=COV, decls=DECLS,
              reset_period=40000, cov_min=5, arm=ARM, arm_delay=4, exempt=EXEMPT)]

HEADER = """自动生成：verif/ut/L1Prefetcher/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
L1Prefetcher 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
