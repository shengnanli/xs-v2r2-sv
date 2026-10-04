// =============================================================================
// tb —— VecExcpDataMergeModule UT：golden 与重写件（_xs）双例化，同激励逐拍比全部 32 个输出口。
//
// 暖机（前 WARM 拍不比）：复位 3 拍后走一遍固定的"whole 8 个 vd"异常——把所有不复位寄存器
//   （sWaitRab_* / regMaps 8 项 / 两个批计数 / mergedVd 4 项 / 写 valid 打拍）都写一遍，
//   之后两侧初态完全一致，+vcs+initreg+random 档才有意义。
// 随机激励（每拍，negedge 驱动、下一个 negedge 先比后换）：
//   * 异常：1/8 拍 valid；vstart 偏小值/全随机，vsew/veew/vlmul/nf 全随机，
//     isStride/isIndexed/isWhole/isVlm 各按概率独立取（含非法组合，golden 照样有定义）；
//   * RAB/RAT：70% 拍按"前缀连续有效"（真实提交形态），30% 逐口独立随机；lreg 1/4 取 0（造 isV0）；
//     RAT 每口在 vec / v0 / 两者 / 都不 之间选；
//   * VPRF 读回：50% 跟本拍 golden 读 valid、30% 跟上一拍、20% 随机；数据全随机；
//   * 复位：约 1/20000 拍插一次 1~2 拍异步复位。
// 覆盖（写进 PASS 判据，见末尾 cov_ok）：五个状态驻留、两种 merge 结束分支、
//   异常接受时 stride/nonSegIndexed/seg 重排/whole/vlm、vemul_i_d 四档、e8offset≠0 的合并、
//   isV0 输出、四个写口、复位次数。
// =============================================================================
`timescale 1ns/1ps
`define CMP(n) begin checks++; if ((g_``n) !== (i_``n)) begin errors++; \
  if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, `"n`", g_``n, i_``n); end end
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  localparam int WARM = 40;
  logic clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // ---- 端口声明 / 例化（由 golden 端口表机械展开）----
  logic           i_fromExceptionGen_valid;
  logic [6:0]     i_fromExceptionGen_bits_vstart;
  logic [1:0]     i_fromExceptionGen_bits_vsew;
  logic [1:0]     i_fromExceptionGen_bits_veew;
  logic [2:0]     i_fromExceptionGen_bits_vlmul;
  logic [2:0]     i_fromExceptionGen_bits_nf;
  logic           i_fromExceptionGen_bits_isStride;
  logic           i_fromExceptionGen_bits_isIndexed;
  logic           i_fromExceptionGen_bits_isWhole;
  logic           i_fromExceptionGen_bits_isVlm;
  logic           i_fromRab_logicPhyRegMap_0_valid;
  logic [5:0]     i_fromRab_logicPhyRegMap_0_bits_lreg;
  logic [6:0]     i_fromRab_logicPhyRegMap_0_bits_preg;
  logic           i_fromRab_logicPhyRegMap_1_valid;
  logic [5:0]     i_fromRab_logicPhyRegMap_1_bits_lreg;
  logic [6:0]     i_fromRab_logicPhyRegMap_1_bits_preg;
  logic           i_fromRab_logicPhyRegMap_2_valid;
  logic [5:0]     i_fromRab_logicPhyRegMap_2_bits_lreg;
  logic [6:0]     i_fromRab_logicPhyRegMap_2_bits_preg;
  logic           i_fromRab_logicPhyRegMap_3_valid;
  logic [5:0]     i_fromRab_logicPhyRegMap_3_bits_lreg;
  logic [6:0]     i_fromRab_logicPhyRegMap_3_bits_preg;
  logic           i_fromRab_logicPhyRegMap_4_valid;
  logic [5:0]     i_fromRab_logicPhyRegMap_4_bits_lreg;
  logic [6:0]     i_fromRab_logicPhyRegMap_4_bits_preg;
  logic           i_fromRab_logicPhyRegMap_5_valid;
  logic [5:0]     i_fromRab_logicPhyRegMap_5_bits_lreg;
  logic [6:0]     i_fromRab_logicPhyRegMap_5_bits_preg;
  logic           i_fromRat_vecOldVdPdest_0_valid;
  logic [6:0]     i_fromRat_vecOldVdPdest_0_bits;
  logic           i_fromRat_vecOldVdPdest_1_valid;
  logic [6:0]     i_fromRat_vecOldVdPdest_1_bits;
  logic           i_fromRat_vecOldVdPdest_2_valid;
  logic [6:0]     i_fromRat_vecOldVdPdest_2_bits;
  logic           i_fromRat_vecOldVdPdest_3_valid;
  logic [6:0]     i_fromRat_vecOldVdPdest_3_bits;
  logic           i_fromRat_vecOldVdPdest_4_valid;
  logic [6:0]     i_fromRat_vecOldVdPdest_4_bits;
  logic           i_fromRat_vecOldVdPdest_5_valid;
  logic [6:0]     i_fromRat_vecOldVdPdest_5_bits;
  logic           i_fromRat_v0OldVdPdest_0_valid;
  logic [6:0]     i_fromRat_v0OldVdPdest_0_bits;
  logic           i_fromRat_v0OldVdPdest_1_valid;
  logic [6:0]     i_fromRat_v0OldVdPdest_1_bits;
  logic           i_fromRat_v0OldVdPdest_2_valid;
  logic [6:0]     i_fromRat_v0OldVdPdest_2_bits;
  logic           i_fromRat_v0OldVdPdest_3_valid;
  logic [6:0]     i_fromRat_v0OldVdPdest_3_bits;
  logic           i_fromRat_v0OldVdPdest_4_valid;
  logic [6:0]     i_fromRat_v0OldVdPdest_4_bits;
  logic           i_fromRat_v0OldVdPdest_5_valid;
  logic [6:0]     i_fromRat_v0OldVdPdest_5_bits;
  logic           i_fromVprf_rdata_0_valid;
  logic [127:0]   i_fromVprf_rdata_0_bits;
  logic           i_fromVprf_rdata_1_valid;
  logic [127:0]   i_fromVprf_rdata_1_bits;
  logic           i_fromVprf_rdata_2_valid;
  logic [127:0]   i_fromVprf_rdata_2_bits;
  logic           i_fromVprf_rdata_3_valid;
  logic [127:0]   i_fromVprf_rdata_3_bits;
  logic [127:0]   i_fromVprf_rdata_4_bits;
  logic [127:0]   i_fromVprf_rdata_5_bits;
  logic [127:0]   i_fromVprf_rdata_6_bits;
  logic [127:0]   i_fromVprf_rdata_7_bits;
  logic           g_o_toVPRF_r_0_valid, i_o_toVPRF_r_0_valid;
  logic           g_o_toVPRF_r_0_bits_isV0, i_o_toVPRF_r_0_bits_isV0;
  logic [6:0]     g_o_toVPRF_r_0_bits_addr, i_o_toVPRF_r_0_bits_addr;
  logic           g_o_toVPRF_r_1_valid, i_o_toVPRF_r_1_valid;
  logic [6:0]     g_o_toVPRF_r_1_bits_addr, i_o_toVPRF_r_1_bits_addr;
  logic           g_o_toVPRF_r_2_valid, i_o_toVPRF_r_2_valid;
  logic [6:0]     g_o_toVPRF_r_2_bits_addr, i_o_toVPRF_r_2_bits_addr;
  logic           g_o_toVPRF_r_3_valid, i_o_toVPRF_r_3_valid;
  logic [6:0]     g_o_toVPRF_r_3_bits_addr, i_o_toVPRF_r_3_bits_addr;
  logic           g_o_toVPRF_r_4_valid, i_o_toVPRF_r_4_valid;
  logic           g_o_toVPRF_r_4_bits_isV0, i_o_toVPRF_r_4_bits_isV0;
  logic [6:0]     g_o_toVPRF_r_4_bits_addr, i_o_toVPRF_r_4_bits_addr;
  logic           g_o_toVPRF_r_5_valid, i_o_toVPRF_r_5_valid;
  logic [6:0]     g_o_toVPRF_r_5_bits_addr, i_o_toVPRF_r_5_bits_addr;
  logic           g_o_toVPRF_r_6_valid, i_o_toVPRF_r_6_valid;
  logic [6:0]     g_o_toVPRF_r_6_bits_addr, i_o_toVPRF_r_6_bits_addr;
  logic           g_o_toVPRF_r_7_valid, i_o_toVPRF_r_7_valid;
  logic [6:0]     g_o_toVPRF_r_7_bits_addr, i_o_toVPRF_r_7_bits_addr;
  logic           g_o_toVPRF_w_0_valid, i_o_toVPRF_w_0_valid;
  logic           g_o_toVPRF_w_0_bits_isV0, i_o_toVPRF_w_0_bits_isV0;
  logic [6:0]     g_o_toVPRF_w_0_bits_newVdAddr, i_o_toVPRF_w_0_bits_newVdAddr;
  logic [127:0]   g_o_toVPRF_w_0_bits_newVdData, i_o_toVPRF_w_0_bits_newVdData;
  logic           g_o_toVPRF_w_1_valid, i_o_toVPRF_w_1_valid;
  logic [6:0]     g_o_toVPRF_w_1_bits_newVdAddr, i_o_toVPRF_w_1_bits_newVdAddr;
  logic [127:0]   g_o_toVPRF_w_1_bits_newVdData, i_o_toVPRF_w_1_bits_newVdData;
  logic           g_o_toVPRF_w_2_valid, i_o_toVPRF_w_2_valid;
  logic [6:0]     g_o_toVPRF_w_2_bits_newVdAddr, i_o_toVPRF_w_2_bits_newVdAddr;
  logic [127:0]   g_o_toVPRF_w_2_bits_newVdData, i_o_toVPRF_w_2_bits_newVdData;
  logic           g_o_toVPRF_w_3_valid, i_o_toVPRF_w_3_valid;
  logic [6:0]     g_o_toVPRF_w_3_bits_newVdAddr, i_o_toVPRF_w_3_bits_newVdAddr;
  logic [127:0]   g_o_toVPRF_w_3_bits_newVdData, i_o_toVPRF_w_3_bits_newVdData;
  logic           g_o_status_busy, i_o_status_busy;

  VecExcpDataMergeModule u_g (
    .clock(clock),
    .reset(reset),
    .i_fromExceptionGen_valid(i_fromExceptionGen_valid),
    .i_fromExceptionGen_bits_vstart(i_fromExceptionGen_bits_vstart),
    .i_fromExceptionGen_bits_vsew(i_fromExceptionGen_bits_vsew),
    .i_fromExceptionGen_bits_veew(i_fromExceptionGen_bits_veew),
    .i_fromExceptionGen_bits_vlmul(i_fromExceptionGen_bits_vlmul),
    .i_fromExceptionGen_bits_nf(i_fromExceptionGen_bits_nf),
    .i_fromExceptionGen_bits_isStride(i_fromExceptionGen_bits_isStride),
    .i_fromExceptionGen_bits_isIndexed(i_fromExceptionGen_bits_isIndexed),
    .i_fromExceptionGen_bits_isWhole(i_fromExceptionGen_bits_isWhole),
    .i_fromExceptionGen_bits_isVlm(i_fromExceptionGen_bits_isVlm),
    .i_fromRab_logicPhyRegMap_0_valid(i_fromRab_logicPhyRegMap_0_valid),
    .i_fromRab_logicPhyRegMap_0_bits_lreg(i_fromRab_logicPhyRegMap_0_bits_lreg),
    .i_fromRab_logicPhyRegMap_0_bits_preg(i_fromRab_logicPhyRegMap_0_bits_preg),
    .i_fromRab_logicPhyRegMap_1_valid(i_fromRab_logicPhyRegMap_1_valid),
    .i_fromRab_logicPhyRegMap_1_bits_lreg(i_fromRab_logicPhyRegMap_1_bits_lreg),
    .i_fromRab_logicPhyRegMap_1_bits_preg(i_fromRab_logicPhyRegMap_1_bits_preg),
    .i_fromRab_logicPhyRegMap_2_valid(i_fromRab_logicPhyRegMap_2_valid),
    .i_fromRab_logicPhyRegMap_2_bits_lreg(i_fromRab_logicPhyRegMap_2_bits_lreg),
    .i_fromRab_logicPhyRegMap_2_bits_preg(i_fromRab_logicPhyRegMap_2_bits_preg),
    .i_fromRab_logicPhyRegMap_3_valid(i_fromRab_logicPhyRegMap_3_valid),
    .i_fromRab_logicPhyRegMap_3_bits_lreg(i_fromRab_logicPhyRegMap_3_bits_lreg),
    .i_fromRab_logicPhyRegMap_3_bits_preg(i_fromRab_logicPhyRegMap_3_bits_preg),
    .i_fromRab_logicPhyRegMap_4_valid(i_fromRab_logicPhyRegMap_4_valid),
    .i_fromRab_logicPhyRegMap_4_bits_lreg(i_fromRab_logicPhyRegMap_4_bits_lreg),
    .i_fromRab_logicPhyRegMap_4_bits_preg(i_fromRab_logicPhyRegMap_4_bits_preg),
    .i_fromRab_logicPhyRegMap_5_valid(i_fromRab_logicPhyRegMap_5_valid),
    .i_fromRab_logicPhyRegMap_5_bits_lreg(i_fromRab_logicPhyRegMap_5_bits_lreg),
    .i_fromRab_logicPhyRegMap_5_bits_preg(i_fromRab_logicPhyRegMap_5_bits_preg),
    .i_fromRat_vecOldVdPdest_0_valid(i_fromRat_vecOldVdPdest_0_valid),
    .i_fromRat_vecOldVdPdest_0_bits(i_fromRat_vecOldVdPdest_0_bits),
    .i_fromRat_vecOldVdPdest_1_valid(i_fromRat_vecOldVdPdest_1_valid),
    .i_fromRat_vecOldVdPdest_1_bits(i_fromRat_vecOldVdPdest_1_bits),
    .i_fromRat_vecOldVdPdest_2_valid(i_fromRat_vecOldVdPdest_2_valid),
    .i_fromRat_vecOldVdPdest_2_bits(i_fromRat_vecOldVdPdest_2_bits),
    .i_fromRat_vecOldVdPdest_3_valid(i_fromRat_vecOldVdPdest_3_valid),
    .i_fromRat_vecOldVdPdest_3_bits(i_fromRat_vecOldVdPdest_3_bits),
    .i_fromRat_vecOldVdPdest_4_valid(i_fromRat_vecOldVdPdest_4_valid),
    .i_fromRat_vecOldVdPdest_4_bits(i_fromRat_vecOldVdPdest_4_bits),
    .i_fromRat_vecOldVdPdest_5_valid(i_fromRat_vecOldVdPdest_5_valid),
    .i_fromRat_vecOldVdPdest_5_bits(i_fromRat_vecOldVdPdest_5_bits),
    .i_fromRat_v0OldVdPdest_0_valid(i_fromRat_v0OldVdPdest_0_valid),
    .i_fromRat_v0OldVdPdest_0_bits(i_fromRat_v0OldVdPdest_0_bits),
    .i_fromRat_v0OldVdPdest_1_valid(i_fromRat_v0OldVdPdest_1_valid),
    .i_fromRat_v0OldVdPdest_1_bits(i_fromRat_v0OldVdPdest_1_bits),
    .i_fromRat_v0OldVdPdest_2_valid(i_fromRat_v0OldVdPdest_2_valid),
    .i_fromRat_v0OldVdPdest_2_bits(i_fromRat_v0OldVdPdest_2_bits),
    .i_fromRat_v0OldVdPdest_3_valid(i_fromRat_v0OldVdPdest_3_valid),
    .i_fromRat_v0OldVdPdest_3_bits(i_fromRat_v0OldVdPdest_3_bits),
    .i_fromRat_v0OldVdPdest_4_valid(i_fromRat_v0OldVdPdest_4_valid),
    .i_fromRat_v0OldVdPdest_4_bits(i_fromRat_v0OldVdPdest_4_bits),
    .i_fromRat_v0OldVdPdest_5_valid(i_fromRat_v0OldVdPdest_5_valid),
    .i_fromRat_v0OldVdPdest_5_bits(i_fromRat_v0OldVdPdest_5_bits),
    .i_fromVprf_rdata_0_valid(i_fromVprf_rdata_0_valid),
    .i_fromVprf_rdata_0_bits(i_fromVprf_rdata_0_bits),
    .i_fromVprf_rdata_1_valid(i_fromVprf_rdata_1_valid),
    .i_fromVprf_rdata_1_bits(i_fromVprf_rdata_1_bits),
    .i_fromVprf_rdata_2_valid(i_fromVprf_rdata_2_valid),
    .i_fromVprf_rdata_2_bits(i_fromVprf_rdata_2_bits),
    .i_fromVprf_rdata_3_valid(i_fromVprf_rdata_3_valid),
    .i_fromVprf_rdata_3_bits(i_fromVprf_rdata_3_bits),
    .i_fromVprf_rdata_4_bits(i_fromVprf_rdata_4_bits),
    .i_fromVprf_rdata_5_bits(i_fromVprf_rdata_5_bits),
    .i_fromVprf_rdata_6_bits(i_fromVprf_rdata_6_bits),
    .i_fromVprf_rdata_7_bits(i_fromVprf_rdata_7_bits),
    .o_toVPRF_r_0_valid(g_o_toVPRF_r_0_valid),
    .o_toVPRF_r_0_bits_isV0(g_o_toVPRF_r_0_bits_isV0),
    .o_toVPRF_r_0_bits_addr(g_o_toVPRF_r_0_bits_addr),
    .o_toVPRF_r_1_valid(g_o_toVPRF_r_1_valid),
    .o_toVPRF_r_1_bits_addr(g_o_toVPRF_r_1_bits_addr),
    .o_toVPRF_r_2_valid(g_o_toVPRF_r_2_valid),
    .o_toVPRF_r_2_bits_addr(g_o_toVPRF_r_2_bits_addr),
    .o_toVPRF_r_3_valid(g_o_toVPRF_r_3_valid),
    .o_toVPRF_r_3_bits_addr(g_o_toVPRF_r_3_bits_addr),
    .o_toVPRF_r_4_valid(g_o_toVPRF_r_4_valid),
    .o_toVPRF_r_4_bits_isV0(g_o_toVPRF_r_4_bits_isV0),
    .o_toVPRF_r_4_bits_addr(g_o_toVPRF_r_4_bits_addr),
    .o_toVPRF_r_5_valid(g_o_toVPRF_r_5_valid),
    .o_toVPRF_r_5_bits_addr(g_o_toVPRF_r_5_bits_addr),
    .o_toVPRF_r_6_valid(g_o_toVPRF_r_6_valid),
    .o_toVPRF_r_6_bits_addr(g_o_toVPRF_r_6_bits_addr),
    .o_toVPRF_r_7_valid(g_o_toVPRF_r_7_valid),
    .o_toVPRF_r_7_bits_addr(g_o_toVPRF_r_7_bits_addr),
    .o_toVPRF_w_0_valid(g_o_toVPRF_w_0_valid),
    .o_toVPRF_w_0_bits_isV0(g_o_toVPRF_w_0_bits_isV0),
    .o_toVPRF_w_0_bits_newVdAddr(g_o_toVPRF_w_0_bits_newVdAddr),
    .o_toVPRF_w_0_bits_newVdData(g_o_toVPRF_w_0_bits_newVdData),
    .o_toVPRF_w_1_valid(g_o_toVPRF_w_1_valid),
    .o_toVPRF_w_1_bits_newVdAddr(g_o_toVPRF_w_1_bits_newVdAddr),
    .o_toVPRF_w_1_bits_newVdData(g_o_toVPRF_w_1_bits_newVdData),
    .o_toVPRF_w_2_valid(g_o_toVPRF_w_2_valid),
    .o_toVPRF_w_2_bits_newVdAddr(g_o_toVPRF_w_2_bits_newVdAddr),
    .o_toVPRF_w_2_bits_newVdData(g_o_toVPRF_w_2_bits_newVdData),
    .o_toVPRF_w_3_valid(g_o_toVPRF_w_3_valid),
    .o_toVPRF_w_3_bits_newVdAddr(g_o_toVPRF_w_3_bits_newVdAddr),
    .o_toVPRF_w_3_bits_newVdData(g_o_toVPRF_w_3_bits_newVdData),
    .o_status_busy(g_o_status_busy)
  );

  VecExcpDataMergeModule_xs u_i (
    .clock(clock),
    .reset(reset),
    .i_fromExceptionGen_valid(i_fromExceptionGen_valid),
    .i_fromExceptionGen_bits_vstart(i_fromExceptionGen_bits_vstart),
    .i_fromExceptionGen_bits_vsew(i_fromExceptionGen_bits_vsew),
    .i_fromExceptionGen_bits_veew(i_fromExceptionGen_bits_veew),
    .i_fromExceptionGen_bits_vlmul(i_fromExceptionGen_bits_vlmul),
    .i_fromExceptionGen_bits_nf(i_fromExceptionGen_bits_nf),
    .i_fromExceptionGen_bits_isStride(i_fromExceptionGen_bits_isStride),
    .i_fromExceptionGen_bits_isIndexed(i_fromExceptionGen_bits_isIndexed),
    .i_fromExceptionGen_bits_isWhole(i_fromExceptionGen_bits_isWhole),
    .i_fromExceptionGen_bits_isVlm(i_fromExceptionGen_bits_isVlm),
    .i_fromRab_logicPhyRegMap_0_valid(i_fromRab_logicPhyRegMap_0_valid),
    .i_fromRab_logicPhyRegMap_0_bits_lreg(i_fromRab_logicPhyRegMap_0_bits_lreg),
    .i_fromRab_logicPhyRegMap_0_bits_preg(i_fromRab_logicPhyRegMap_0_bits_preg),
    .i_fromRab_logicPhyRegMap_1_valid(i_fromRab_logicPhyRegMap_1_valid),
    .i_fromRab_logicPhyRegMap_1_bits_lreg(i_fromRab_logicPhyRegMap_1_bits_lreg),
    .i_fromRab_logicPhyRegMap_1_bits_preg(i_fromRab_logicPhyRegMap_1_bits_preg),
    .i_fromRab_logicPhyRegMap_2_valid(i_fromRab_logicPhyRegMap_2_valid),
    .i_fromRab_logicPhyRegMap_2_bits_lreg(i_fromRab_logicPhyRegMap_2_bits_lreg),
    .i_fromRab_logicPhyRegMap_2_bits_preg(i_fromRab_logicPhyRegMap_2_bits_preg),
    .i_fromRab_logicPhyRegMap_3_valid(i_fromRab_logicPhyRegMap_3_valid),
    .i_fromRab_logicPhyRegMap_3_bits_lreg(i_fromRab_logicPhyRegMap_3_bits_lreg),
    .i_fromRab_logicPhyRegMap_3_bits_preg(i_fromRab_logicPhyRegMap_3_bits_preg),
    .i_fromRab_logicPhyRegMap_4_valid(i_fromRab_logicPhyRegMap_4_valid),
    .i_fromRab_logicPhyRegMap_4_bits_lreg(i_fromRab_logicPhyRegMap_4_bits_lreg),
    .i_fromRab_logicPhyRegMap_4_bits_preg(i_fromRab_logicPhyRegMap_4_bits_preg),
    .i_fromRab_logicPhyRegMap_5_valid(i_fromRab_logicPhyRegMap_5_valid),
    .i_fromRab_logicPhyRegMap_5_bits_lreg(i_fromRab_logicPhyRegMap_5_bits_lreg),
    .i_fromRab_logicPhyRegMap_5_bits_preg(i_fromRab_logicPhyRegMap_5_bits_preg),
    .i_fromRat_vecOldVdPdest_0_valid(i_fromRat_vecOldVdPdest_0_valid),
    .i_fromRat_vecOldVdPdest_0_bits(i_fromRat_vecOldVdPdest_0_bits),
    .i_fromRat_vecOldVdPdest_1_valid(i_fromRat_vecOldVdPdest_1_valid),
    .i_fromRat_vecOldVdPdest_1_bits(i_fromRat_vecOldVdPdest_1_bits),
    .i_fromRat_vecOldVdPdest_2_valid(i_fromRat_vecOldVdPdest_2_valid),
    .i_fromRat_vecOldVdPdest_2_bits(i_fromRat_vecOldVdPdest_2_bits),
    .i_fromRat_vecOldVdPdest_3_valid(i_fromRat_vecOldVdPdest_3_valid),
    .i_fromRat_vecOldVdPdest_3_bits(i_fromRat_vecOldVdPdest_3_bits),
    .i_fromRat_vecOldVdPdest_4_valid(i_fromRat_vecOldVdPdest_4_valid),
    .i_fromRat_vecOldVdPdest_4_bits(i_fromRat_vecOldVdPdest_4_bits),
    .i_fromRat_vecOldVdPdest_5_valid(i_fromRat_vecOldVdPdest_5_valid),
    .i_fromRat_vecOldVdPdest_5_bits(i_fromRat_vecOldVdPdest_5_bits),
    .i_fromRat_v0OldVdPdest_0_valid(i_fromRat_v0OldVdPdest_0_valid),
    .i_fromRat_v0OldVdPdest_0_bits(i_fromRat_v0OldVdPdest_0_bits),
    .i_fromRat_v0OldVdPdest_1_valid(i_fromRat_v0OldVdPdest_1_valid),
    .i_fromRat_v0OldVdPdest_1_bits(i_fromRat_v0OldVdPdest_1_bits),
    .i_fromRat_v0OldVdPdest_2_valid(i_fromRat_v0OldVdPdest_2_valid),
    .i_fromRat_v0OldVdPdest_2_bits(i_fromRat_v0OldVdPdest_2_bits),
    .i_fromRat_v0OldVdPdest_3_valid(i_fromRat_v0OldVdPdest_3_valid),
    .i_fromRat_v0OldVdPdest_3_bits(i_fromRat_v0OldVdPdest_3_bits),
    .i_fromRat_v0OldVdPdest_4_valid(i_fromRat_v0OldVdPdest_4_valid),
    .i_fromRat_v0OldVdPdest_4_bits(i_fromRat_v0OldVdPdest_4_bits),
    .i_fromRat_v0OldVdPdest_5_valid(i_fromRat_v0OldVdPdest_5_valid),
    .i_fromRat_v0OldVdPdest_5_bits(i_fromRat_v0OldVdPdest_5_bits),
    .i_fromVprf_rdata_0_valid(i_fromVprf_rdata_0_valid),
    .i_fromVprf_rdata_0_bits(i_fromVprf_rdata_0_bits),
    .i_fromVprf_rdata_1_valid(i_fromVprf_rdata_1_valid),
    .i_fromVprf_rdata_1_bits(i_fromVprf_rdata_1_bits),
    .i_fromVprf_rdata_2_valid(i_fromVprf_rdata_2_valid),
    .i_fromVprf_rdata_2_bits(i_fromVprf_rdata_2_bits),
    .i_fromVprf_rdata_3_valid(i_fromVprf_rdata_3_valid),
    .i_fromVprf_rdata_3_bits(i_fromVprf_rdata_3_bits),
    .i_fromVprf_rdata_4_bits(i_fromVprf_rdata_4_bits),
    .i_fromVprf_rdata_5_bits(i_fromVprf_rdata_5_bits),
    .i_fromVprf_rdata_6_bits(i_fromVprf_rdata_6_bits),
    .i_fromVprf_rdata_7_bits(i_fromVprf_rdata_7_bits),
    .o_toVPRF_r_0_valid(i_o_toVPRF_r_0_valid),
    .o_toVPRF_r_0_bits_isV0(i_o_toVPRF_r_0_bits_isV0),
    .o_toVPRF_r_0_bits_addr(i_o_toVPRF_r_0_bits_addr),
    .o_toVPRF_r_1_valid(i_o_toVPRF_r_1_valid),
    .o_toVPRF_r_1_bits_addr(i_o_toVPRF_r_1_bits_addr),
    .o_toVPRF_r_2_valid(i_o_toVPRF_r_2_valid),
    .o_toVPRF_r_2_bits_addr(i_o_toVPRF_r_2_bits_addr),
    .o_toVPRF_r_3_valid(i_o_toVPRF_r_3_valid),
    .o_toVPRF_r_3_bits_addr(i_o_toVPRF_r_3_bits_addr),
    .o_toVPRF_r_4_valid(i_o_toVPRF_r_4_valid),
    .o_toVPRF_r_4_bits_isV0(i_o_toVPRF_r_4_bits_isV0),
    .o_toVPRF_r_4_bits_addr(i_o_toVPRF_r_4_bits_addr),
    .o_toVPRF_r_5_valid(i_o_toVPRF_r_5_valid),
    .o_toVPRF_r_5_bits_addr(i_o_toVPRF_r_5_bits_addr),
    .o_toVPRF_r_6_valid(i_o_toVPRF_r_6_valid),
    .o_toVPRF_r_6_bits_addr(i_o_toVPRF_r_6_bits_addr),
    .o_toVPRF_r_7_valid(i_o_toVPRF_r_7_valid),
    .o_toVPRF_r_7_bits_addr(i_o_toVPRF_r_7_bits_addr),
    .o_toVPRF_w_0_valid(i_o_toVPRF_w_0_valid),
    .o_toVPRF_w_0_bits_isV0(i_o_toVPRF_w_0_bits_isV0),
    .o_toVPRF_w_0_bits_newVdAddr(i_o_toVPRF_w_0_bits_newVdAddr),
    .o_toVPRF_w_0_bits_newVdData(i_o_toVPRF_w_0_bits_newVdData),
    .o_toVPRF_w_1_valid(i_o_toVPRF_w_1_valid),
    .o_toVPRF_w_1_bits_newVdAddr(i_o_toVPRF_w_1_bits_newVdAddr),
    .o_toVPRF_w_1_bits_newVdData(i_o_toVPRF_w_1_bits_newVdData),
    .o_toVPRF_w_2_valid(i_o_toVPRF_w_2_valid),
    .o_toVPRF_w_2_bits_newVdAddr(i_o_toVPRF_w_2_bits_newVdAddr),
    .o_toVPRF_w_2_bits_newVdData(i_o_toVPRF_w_2_bits_newVdData),
    .o_toVPRF_w_3_valid(i_o_toVPRF_w_3_valid),
    .o_toVPRF_w_3_bits_newVdAddr(i_o_toVPRF_w_3_bits_newVdAddr),
    .o_toVPRF_w_3_bits_newVdData(i_o_toVPRF_w_3_bits_newVdData),
    .o_status_busy(i_o_status_busy)
  );

  // ---- 覆盖计数 ----
  longint cov_state [5];
  longint cov_merge_to_mv = 0, cov_merge_to_fin = 0;
  longint cov_acc = 0, cov_acc_stride = 0, cov_acc_nonseg = 0, cov_acc_seg = 0;
  longint cov_acc_whole = 0, cov_acc_vlm = 0;
  longint cov_vemul [4];
  longint cov_partial_merge = 0, cov_isv0 = 0, cov_reset = 0;
  longint cov_w [4];
  logic [3:0] prev_rvalid;

  // golden 内部状态只用来塑形激励与计覆盖，比较只看端口
  wire [2:0] g_state = u_g.state;

  task automatic rand_bits128(output logic [127:0] d);
    d = {$urandom, $urandom, $urandom, $urandom};
  endtask

  task automatic drive_idle();
    i_fromExceptionGen_valid = 0;
    {i_fromExceptionGen_bits_vstart, i_fromExceptionGen_bits_vsew, i_fromExceptionGen_bits_veew,
     i_fromExceptionGen_bits_vlmul, i_fromExceptionGen_bits_nf, i_fromExceptionGen_bits_isStride,
     i_fromExceptionGen_bits_isIndexed, i_fromExceptionGen_bits_isWhole, i_fromExceptionGen_bits_isVlm} = '0;
    {i_fromRab_logicPhyRegMap_0_valid, i_fromRab_logicPhyRegMap_1_valid, i_fromRab_logicPhyRegMap_2_valid,
     i_fromRab_logicPhyRegMap_3_valid, i_fromRab_logicPhyRegMap_4_valid, i_fromRab_logicPhyRegMap_5_valid} = '0;
    {i_fromRat_vecOldVdPdest_0_valid, i_fromRat_vecOldVdPdest_1_valid, i_fromRat_vecOldVdPdest_2_valid,
     i_fromRat_vecOldVdPdest_3_valid, i_fromRat_vecOldVdPdest_4_valid, i_fromRat_vecOldVdPdest_5_valid} = '0;
    {i_fromRat_v0OldVdPdest_0_valid, i_fromRat_v0OldVdPdest_1_valid, i_fromRat_v0OldVdPdest_2_valid,
     i_fromRat_v0OldVdPdest_3_valid, i_fromRat_v0OldVdPdest_4_valid, i_fromRat_v0OldVdPdest_5_valid} = '0;
    {i_fromVprf_rdata_0_valid, i_fromVprf_rdata_1_valid, i_fromVprf_rdata_2_valid, i_fromVprf_rdata_3_valid} = '0;
  endtask

  // 6 口有效位：70% 前缀连续，30% 独立
  function automatic logic [5:0] rand_valid6();
    if ($urandom_range(0, 9) < 7) begin
      int k = $urandom_range(0, 6);
      return 6'((1 << k) - 1);
    end
    return 6'($urandom);
  endfunction

  function automatic logic [5:0] rand_lreg();
    return ($urandom_range(0, 3) == 0) ? 6'd0 : 6'($urandom);
  endfunction

  task automatic drive_random();
    logic [5:0] rv, rat;
    logic [3:0] vv;
    logic [127:0] d;
    // 异常描述
    i_fromExceptionGen_valid = ($urandom_range(0, 7) == 0);
    case ($urandom_range(0, 3))
      0: i_fromExceptionGen_bits_vstart = 7'd0;
      1: i_fromExceptionGen_bits_vstart = 7'($urandom_range(0, 15));
      default: i_fromExceptionGen_bits_vstart = 7'($urandom);
    endcase
    i_fromExceptionGen_bits_vsew      = 2'($urandom);
    i_fromExceptionGen_bits_veew      = 2'($urandom);
    i_fromExceptionGen_bits_vlmul     = 3'($urandom);
    i_fromExceptionGen_bits_nf        = ($urandom_range(0, 2) == 0) ? 3'd0 : 3'($urandom);
    i_fromExceptionGen_bits_isStride  = ($urandom_range(0, 3) == 0);
    i_fromExceptionGen_bits_isIndexed = ($urandom_range(0, 2) == 0);
    i_fromExceptionGen_bits_isWhole   = ($urandom_range(0, 4) == 0);
    i_fromExceptionGen_bits_isVlm     = ($urandom_range(0, 7) == 0);
    // RAB
    rv = rand_valid6();
    {i_fromRab_logicPhyRegMap_5_valid, i_fromRab_logicPhyRegMap_4_valid, i_fromRab_logicPhyRegMap_3_valid,
     i_fromRab_logicPhyRegMap_2_valid, i_fromRab_logicPhyRegMap_1_valid, i_fromRab_logicPhyRegMap_0_valid} = rv;
    i_fromRab_logicPhyRegMap_0_bits_lreg = rand_lreg(); i_fromRab_logicPhyRegMap_0_bits_preg = 7'($urandom);
    i_fromRab_logicPhyRegMap_1_bits_lreg = rand_lreg(); i_fromRab_logicPhyRegMap_1_bits_preg = 7'($urandom);
    i_fromRab_logicPhyRegMap_2_bits_lreg = rand_lreg(); i_fromRab_logicPhyRegMap_2_bits_preg = 7'($urandom);
    i_fromRab_logicPhyRegMap_3_bits_lreg = rand_lreg(); i_fromRab_logicPhyRegMap_3_bits_preg = 7'($urandom);
    i_fromRab_logicPhyRegMap_4_bits_lreg = rand_lreg(); i_fromRab_logicPhyRegMap_4_bits_preg = 7'($urandom);
    i_fromRab_logicPhyRegMap_5_bits_lreg = rand_lreg(); i_fromRab_logicPhyRegMap_5_bits_preg = 7'($urandom);
    // RAT：每口在 vec / v0 / 两者 / 都不 之间选
    rat = rand_valid6();
    begin
      logic [5:0] vecv, v0v;
      for (int p = 0; p < 6; p++) begin
        int c = $urandom_range(0, 9);
        vecv[p] = rat[p] && (c < 7 || c == 9);
        v0v[p]  = rat[p] && (c == 7 || c == 8 || c == 9 && $urandom_range(0, 1));
      end
      {i_fromRat_vecOldVdPdest_5_valid, i_fromRat_vecOldVdPdest_4_valid, i_fromRat_vecOldVdPdest_3_valid,
       i_fromRat_vecOldVdPdest_2_valid, i_fromRat_vecOldVdPdest_1_valid, i_fromRat_vecOldVdPdest_0_valid} = vecv;
      {i_fromRat_v0OldVdPdest_5_valid, i_fromRat_v0OldVdPdest_4_valid, i_fromRat_v0OldVdPdest_3_valid,
       i_fromRat_v0OldVdPdest_2_valid, i_fromRat_v0OldVdPdest_1_valid, i_fromRat_v0OldVdPdest_0_valid} = v0v;
    end
    i_fromRat_vecOldVdPdest_0_bits = 7'($urandom); i_fromRat_v0OldVdPdest_0_bits = 7'($urandom);
    i_fromRat_vecOldVdPdest_1_bits = 7'($urandom); i_fromRat_v0OldVdPdest_1_bits = 7'($urandom);
    i_fromRat_vecOldVdPdest_2_bits = 7'($urandom); i_fromRat_v0OldVdPdest_2_bits = 7'($urandom);
    i_fromRat_vecOldVdPdest_3_bits = 7'($urandom); i_fromRat_v0OldVdPdest_3_bits = 7'($urandom);
    i_fromRat_vecOldVdPdest_4_bits = 7'($urandom); i_fromRat_v0OldVdPdest_4_bits = 7'($urandom);
    i_fromRat_vecOldVdPdest_5_bits = 7'($urandom); i_fromRat_v0OldVdPdest_5_bits = 7'($urandom);
    // VPRF 读回
    case ($urandom_range(0, 9))
      0, 1, 2, 3, 4: vv = {g_o_toVPRF_r_3_valid, g_o_toVPRF_r_2_valid, g_o_toVPRF_r_1_valid, g_o_toVPRF_r_0_valid};
      5, 6, 7:       vv = prev_rvalid;
      default:       vv = 4'($urandom);
    endcase
    {i_fromVprf_rdata_3_valid, i_fromVprf_rdata_2_valid, i_fromVprf_rdata_1_valid, i_fromVprf_rdata_0_valid} = vv;
    rand_bits128(d); i_fromVprf_rdata_0_bits = d;
    rand_bits128(d); i_fromVprf_rdata_1_bits = d;
    rand_bits128(d); i_fromVprf_rdata_2_bits = d;
    rand_bits128(d); i_fromVprf_rdata_3_bits = d;
    rand_bits128(d); i_fromVprf_rdata_4_bits = d;
    rand_bits128(d); i_fromVprf_rdata_5_bits = d;
    rand_bits128(d); i_fromVprf_rdata_6_bits = d;
    rand_bits128(d); i_fromVprf_rdata_7_bits = d;
  endtask

  // 固定暖机：whole 8 个 vd，两批收齐映射，然后全读全写
  task automatic drive_warm(int c);
    drive_idle();
    reset = (c < 3);
    if (c == 3) begin
      i_fromExceptionGen_valid = 1;
      i_fromExceptionGen_bits_nf = 3'd7;
      i_fromExceptionGen_bits_isWhole = 1;
    end
    if (c == 4 || c == 5) begin
      {i_fromRab_logicPhyRegMap_0_valid, i_fromRab_logicPhyRegMap_1_valid, i_fromRab_logicPhyRegMap_2_valid,
       i_fromRab_logicPhyRegMap_3_valid, i_fromRab_logicPhyRegMap_4_valid, i_fromRab_logicPhyRegMap_5_valid} = '1;
      {i_fromRat_vecOldVdPdest_0_valid, i_fromRat_vecOldVdPdest_1_valid, i_fromRat_vecOldVdPdest_2_valid,
       i_fromRat_vecOldVdPdest_3_valid, i_fromRat_vecOldVdPdest_4_valid, i_fromRat_vecOldVdPdest_5_valid} = '1;
    end
    if (c >= 6 && c < 20)
      {i_fromVprf_rdata_0_valid, i_fromVprf_rdata_1_valid, i_fromVprf_rdata_2_valid, i_fromVprf_rdata_3_valid} = '1;
  endtask

  task automatic do_compare();
      `CMP(o_toVPRF_r_0_valid)
      `CMP(o_toVPRF_r_0_bits_isV0)
      `CMP(o_toVPRF_r_0_bits_addr)
      `CMP(o_toVPRF_r_1_valid)
      `CMP(o_toVPRF_r_1_bits_addr)
      `CMP(o_toVPRF_r_2_valid)
      `CMP(o_toVPRF_r_2_bits_addr)
      `CMP(o_toVPRF_r_3_valid)
      `CMP(o_toVPRF_r_3_bits_addr)
      `CMP(o_toVPRF_r_4_valid)
      `CMP(o_toVPRF_r_4_bits_isV0)
      `CMP(o_toVPRF_r_4_bits_addr)
      `CMP(o_toVPRF_r_5_valid)
      `CMP(o_toVPRF_r_5_bits_addr)
      `CMP(o_toVPRF_r_6_valid)
      `CMP(o_toVPRF_r_6_bits_addr)
      `CMP(o_toVPRF_r_7_valid)
      `CMP(o_toVPRF_r_7_bits_addr)
      `CMP(o_toVPRF_w_0_valid)
      `CMP(o_toVPRF_w_0_bits_isV0)
      `CMP(o_toVPRF_w_0_bits_newVdAddr)
      `CMP(o_toVPRF_w_0_bits_newVdData)
      `CMP(o_toVPRF_w_1_valid)
      `CMP(o_toVPRF_w_1_bits_newVdAddr)
      `CMP(o_toVPRF_w_1_bits_newVdData)
      `CMP(o_toVPRF_w_2_valid)
      `CMP(o_toVPRF_w_2_bits_newVdAddr)
      `CMP(o_toVPRF_w_2_bits_newVdData)
      `CMP(o_toVPRF_w_3_valid)
      `CMP(o_toVPRF_w_3_bits_newVdAddr)
      `CMP(o_toVPRF_w_3_bits_newVdData)
      `CMP(o_status_busy)
  endtask

  task automatic sample_cov();
    logic [2:0] gs = g_state;
    if (gs < 5) cov_state[gs]++;
    if (gs == 3'd2 && u_g.stateNext == 3'd3) cov_merge_to_mv++;
    if (gs == 3'd2 && u_g.stateNext == 3'd4) cov_merge_to_fin++;
    if (gs == 3'd2) for (int n = 0; n < 4; n++) begin
      logic [3:0] vid = {u_g.sWaitRab_vemul_i_d_3, u_g.sWaitRab_vemul_i_d_2, u_g.sWaitRab_vemul_i_d_1, u_g.sWaitRab_vemul_i_d_0};
      if (u_g.sWaitRab_nonSegIndexed && vid[n]) cov_vemul[n]++;
    end
    if (gs == 3'd2 && i_fromVprf_rdata_0_valid && u_g.sWaitRab_e8offset != 0) cov_partial_merge++;
    if (g_o_toVPRF_r_0_bits_isV0 || g_o_toVPRF_r_4_bits_isV0) cov_isv0++;
    if (g_o_toVPRF_w_0_valid) cov_w[0]++;
    if (g_o_toVPRF_w_1_valid) cov_w[1]++;
    if (g_o_toVPRF_w_2_valid) cov_w[2]++;
    if (g_o_toVPRF_w_3_valid) cov_w[3]++;
  endtask

  // 异常接受：在 negedge 驱动之后采（此刻的 state 与输入正是下一个 posedge 要消费的那一对）
  task automatic sample_accept();
    logic [2:0] gs = g_state;
    if (gs == 3'd0 && i_fromExceptionGen_valid && !reset) begin
      cov_acc++;
      if (i_fromExceptionGen_bits_isStride) cov_acc_stride++;
      if (i_fromExceptionGen_bits_isIndexed && i_fromExceptionGen_bits_nf == 0) cov_acc_nonseg++;
      if (!i_fromExceptionGen_bits_isIndexed && !i_fromExceptionGen_bits_isWhole &&
          i_fromExceptionGen_bits_nf inside {[3'd1:3'd3]}) cov_acc_seg++;
      if (i_fromExceptionGen_bits_isWhole) cov_acc_whole++;
      if (i_fromExceptionGen_bits_isVlm) cov_acc_vlm++;
    end
  endtask

  initial begin
    int bad = 0;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    foreach (cov_state[k]) cov_state[k] = 0;
    foreach (cov_vemul[k]) cov_vemul[k] = 0;
    foreach (cov_w[k]) cov_w[k] = 0;
    prev_rvalid = '0;
    reset = 1;
    drive_idle();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      if (cyc >= WARM) begin
        do_compare();
        sample_cov();
      end
      prev_rvalid = {g_o_toVPRF_r_3_valid, g_o_toVPRF_r_2_valid, g_o_toVPRF_r_1_valid, g_o_toVPRF_r_0_valid};
      if (cyc < WARM) drive_warm(cyc);
      else begin
        logic rst_next;
        rst_next = ($urandom_range(0, 19999) == 0) || (reset && $urandom_range(0, 1) && cyc > WARM);
        if (rst_next && !reset) cov_reset++;
        drive_random();
        reset = rst_next;
        sample_accept();
      end
    end
    $display("coverage: state noExcp=%0d waitRab=%0d mergeVd=%0d mvOldVd=%0d finish=%0d",
             cov_state[0], cov_state[1], cov_state[2], cov_state[3], cov_state[4]);
    $display("coverage: merge->mvOld=%0d merge->finish=%0d accepted=%0d stride=%0d nonSegIdx=%0d seg=%0d whole=%0d vlm=%0d",
             cov_merge_to_mv, cov_merge_to_fin, cov_acc, cov_acc_stride, cov_acc_nonseg, cov_acc_seg, cov_acc_whole, cov_acc_vlm);
    $display("coverage: vemul_i_d n0=%0d n1=%0d n2=%0d n3=%0d partial_merge=%0d isV0=%0d w=%0d/%0d/%0d/%0d resets=%0d",
             cov_vemul[0], cov_vemul[1], cov_vemul[2], cov_vemul[3], cov_partial_merge, cov_isv0,
             cov_w[0], cov_w[1], cov_w[2], cov_w[3], cov_reset);
    // 覆盖判据（按 200k 拍定的下限；拍数少于 100k 时不判覆盖）
    if (NCYCLES >= 100000) begin
      foreach (cov_state[k]) if (cov_state[k] < 1000) bad++;
      if (cov_merge_to_mv < 100 || cov_merge_to_fin < 100) bad++;
      if (cov_acc_stride < 100 || cov_acc_nonseg < 100 || cov_acc_seg < 100 || cov_acc_whole < 100 || cov_acc_vlm < 100) bad++;
      foreach (cov_vemul[k]) if (cov_vemul[k] < 20) bad++;
      if (cov_partial_merge < 100 || cov_isv0 < 100 || cov_reset < 2) bad++;
      foreach (cov_w[k]) if (cov_w[k] < 1000) bad++;
    end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
