// 自动生成: gen_vecexcpdatamerge.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic i_fromExceptionGen_valid;
  logic [6:0] i_fromExceptionGen_bits_vstart;
  logic [1:0] i_fromExceptionGen_bits_vsew;
  logic [1:0] i_fromExceptionGen_bits_veew;
  logic [2:0] i_fromExceptionGen_bits_vlmul;
  logic [2:0] i_fromExceptionGen_bits_nf;
  logic i_fromExceptionGen_bits_isStride;
  logic i_fromExceptionGen_bits_isIndexed;
  logic i_fromExceptionGen_bits_isWhole;
  logic i_fromExceptionGen_bits_isVlm;
  logic i_fromRab_logicPhyRegMap_0_valid;
  logic [5:0] i_fromRab_logicPhyRegMap_0_bits_lreg;
  logic [6:0] i_fromRab_logicPhyRegMap_0_bits_preg;
  logic i_fromRab_logicPhyRegMap_1_valid;
  logic [5:0] i_fromRab_logicPhyRegMap_1_bits_lreg;
  logic [6:0] i_fromRab_logicPhyRegMap_1_bits_preg;
  logic i_fromRab_logicPhyRegMap_2_valid;
  logic [5:0] i_fromRab_logicPhyRegMap_2_bits_lreg;
  logic [6:0] i_fromRab_logicPhyRegMap_2_bits_preg;
  logic i_fromRab_logicPhyRegMap_3_valid;
  logic [5:0] i_fromRab_logicPhyRegMap_3_bits_lreg;
  logic [6:0] i_fromRab_logicPhyRegMap_3_bits_preg;
  logic i_fromRab_logicPhyRegMap_4_valid;
  logic [5:0] i_fromRab_logicPhyRegMap_4_bits_lreg;
  logic [6:0] i_fromRab_logicPhyRegMap_4_bits_preg;
  logic i_fromRab_logicPhyRegMap_5_valid;
  logic [5:0] i_fromRab_logicPhyRegMap_5_bits_lreg;
  logic [6:0] i_fromRab_logicPhyRegMap_5_bits_preg;
  logic i_fromRat_vecOldVdPdest_0_valid;
  logic [6:0] i_fromRat_vecOldVdPdest_0_bits;
  logic i_fromRat_vecOldVdPdest_1_valid;
  logic [6:0] i_fromRat_vecOldVdPdest_1_bits;
  logic i_fromRat_vecOldVdPdest_2_valid;
  logic [6:0] i_fromRat_vecOldVdPdest_2_bits;
  logic i_fromRat_vecOldVdPdest_3_valid;
  logic [6:0] i_fromRat_vecOldVdPdest_3_bits;
  logic i_fromRat_vecOldVdPdest_4_valid;
  logic [6:0] i_fromRat_vecOldVdPdest_4_bits;
  logic i_fromRat_vecOldVdPdest_5_valid;
  logic [6:0] i_fromRat_vecOldVdPdest_5_bits;
  logic i_fromRat_v0OldVdPdest_0_valid;
  logic [6:0] i_fromRat_v0OldVdPdest_0_bits;
  logic i_fromRat_v0OldVdPdest_1_valid;
  logic [6:0] i_fromRat_v0OldVdPdest_1_bits;
  logic i_fromRat_v0OldVdPdest_2_valid;
  logic [6:0] i_fromRat_v0OldVdPdest_2_bits;
  logic i_fromRat_v0OldVdPdest_3_valid;
  logic [6:0] i_fromRat_v0OldVdPdest_3_bits;
  logic i_fromRat_v0OldVdPdest_4_valid;
  logic [6:0] i_fromRat_v0OldVdPdest_4_bits;
  logic i_fromRat_v0OldVdPdest_5_valid;
  logic [6:0] i_fromRat_v0OldVdPdest_5_bits;
  logic i_fromVprf_rdata_0_valid;
  logic [127:0] i_fromVprf_rdata_0_bits;
  logic i_fromVprf_rdata_1_valid;
  logic [127:0] i_fromVprf_rdata_1_bits;
  logic i_fromVprf_rdata_2_valid;
  logic [127:0] i_fromVprf_rdata_2_bits;
  logic i_fromVprf_rdata_3_valid;
  logic [127:0] i_fromVprf_rdata_3_bits;
  logic [127:0] i_fromVprf_rdata_4_bits;
  logic [127:0] i_fromVprf_rdata_5_bits;
  logic [127:0] i_fromVprf_rdata_6_bits;
  logic [127:0] i_fromVprf_rdata_7_bits;
  wire g_o_toVPRF_r_0_valid;
  wire i_o_toVPRF_r_0_valid;
  wire g_o_toVPRF_r_0_bits_isV0;
  wire i_o_toVPRF_r_0_bits_isV0;
  wire [6:0] g_o_toVPRF_r_0_bits_addr;
  wire [6:0] i_o_toVPRF_r_0_bits_addr;
  wire g_o_toVPRF_r_1_valid;
  wire i_o_toVPRF_r_1_valid;
  wire [6:0] g_o_toVPRF_r_1_bits_addr;
  wire [6:0] i_o_toVPRF_r_1_bits_addr;
  wire g_o_toVPRF_r_2_valid;
  wire i_o_toVPRF_r_2_valid;
  wire [6:0] g_o_toVPRF_r_2_bits_addr;
  wire [6:0] i_o_toVPRF_r_2_bits_addr;
  wire g_o_toVPRF_r_3_valid;
  wire i_o_toVPRF_r_3_valid;
  wire [6:0] g_o_toVPRF_r_3_bits_addr;
  wire [6:0] i_o_toVPRF_r_3_bits_addr;
  wire g_o_toVPRF_r_4_valid;
  wire i_o_toVPRF_r_4_valid;
  wire g_o_toVPRF_r_4_bits_isV0;
  wire i_o_toVPRF_r_4_bits_isV0;
  wire [6:0] g_o_toVPRF_r_4_bits_addr;
  wire [6:0] i_o_toVPRF_r_4_bits_addr;
  wire g_o_toVPRF_r_5_valid;
  wire i_o_toVPRF_r_5_valid;
  wire [6:0] g_o_toVPRF_r_5_bits_addr;
  wire [6:0] i_o_toVPRF_r_5_bits_addr;
  wire g_o_toVPRF_r_6_valid;
  wire i_o_toVPRF_r_6_valid;
  wire [6:0] g_o_toVPRF_r_6_bits_addr;
  wire [6:0] i_o_toVPRF_r_6_bits_addr;
  wire g_o_toVPRF_r_7_valid;
  wire i_o_toVPRF_r_7_valid;
  wire [6:0] g_o_toVPRF_r_7_bits_addr;
  wire [6:0] i_o_toVPRF_r_7_bits_addr;
  wire g_o_toVPRF_w_0_valid;
  wire i_o_toVPRF_w_0_valid;
  wire g_o_toVPRF_w_0_bits_isV0;
  wire i_o_toVPRF_w_0_bits_isV0;
  wire [6:0] g_o_toVPRF_w_0_bits_newVdAddr;
  wire [6:0] i_o_toVPRF_w_0_bits_newVdAddr;
  wire [127:0] g_o_toVPRF_w_0_bits_newVdData;
  wire [127:0] i_o_toVPRF_w_0_bits_newVdData;
  wire g_o_toVPRF_w_1_valid;
  wire i_o_toVPRF_w_1_valid;
  wire [6:0] g_o_toVPRF_w_1_bits_newVdAddr;
  wire [6:0] i_o_toVPRF_w_1_bits_newVdAddr;
  wire [127:0] g_o_toVPRF_w_1_bits_newVdData;
  wire [127:0] i_o_toVPRF_w_1_bits_newVdData;
  wire g_o_toVPRF_w_2_valid;
  wire i_o_toVPRF_w_2_valid;
  wire [6:0] g_o_toVPRF_w_2_bits_newVdAddr;
  wire [6:0] i_o_toVPRF_w_2_bits_newVdAddr;
  wire [127:0] g_o_toVPRF_w_2_bits_newVdData;
  wire [127:0] i_o_toVPRF_w_2_bits_newVdData;
  wire g_o_toVPRF_w_3_valid;
  wire i_o_toVPRF_w_3_valid;
  wire [6:0] g_o_toVPRF_w_3_bits_newVdAddr;
  wire [6:0] i_o_toVPRF_w_3_bits_newVdAddr;
  wire [127:0] g_o_toVPRF_w_3_bits_newVdData;
  wire [127:0] i_o_toVPRF_w_3_bits_newVdData;
  wire g_o_status_busy;
  wire i_o_status_busy;

  VecExcpDataMergeModule u_g (
    .clock(clk),
    .reset(rst),
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
    .clock(clk),
    .reset(rst),
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

  always @(posedge clk) if (!rst) begin
    i_fromExceptionGen_valid <= $urandom;
    i_fromExceptionGen_bits_vstart <= $urandom;
    i_fromExceptionGen_bits_vsew <= $urandom;
    i_fromExceptionGen_bits_veew <= $urandom;
    i_fromExceptionGen_bits_vlmul <= $urandom;
    i_fromExceptionGen_bits_nf <= $urandom;
    i_fromExceptionGen_bits_isStride <= $urandom;
    i_fromExceptionGen_bits_isIndexed <= $urandom;
    i_fromExceptionGen_bits_isWhole <= $urandom;
    i_fromExceptionGen_bits_isVlm <= $urandom;
    i_fromRab_logicPhyRegMap_0_valid <= $urandom;
    i_fromRab_logicPhyRegMap_0_bits_lreg <= $urandom;
    i_fromRab_logicPhyRegMap_0_bits_preg <= $urandom;
    i_fromRab_logicPhyRegMap_1_valid <= $urandom;
    i_fromRab_logicPhyRegMap_1_bits_lreg <= $urandom;
    i_fromRab_logicPhyRegMap_1_bits_preg <= $urandom;
    i_fromRab_logicPhyRegMap_2_valid <= $urandom;
    i_fromRab_logicPhyRegMap_2_bits_lreg <= $urandom;
    i_fromRab_logicPhyRegMap_2_bits_preg <= $urandom;
    i_fromRab_logicPhyRegMap_3_valid <= $urandom;
    i_fromRab_logicPhyRegMap_3_bits_lreg <= $urandom;
    i_fromRab_logicPhyRegMap_3_bits_preg <= $urandom;
    i_fromRab_logicPhyRegMap_4_valid <= $urandom;
    i_fromRab_logicPhyRegMap_4_bits_lreg <= $urandom;
    i_fromRab_logicPhyRegMap_4_bits_preg <= $urandom;
    i_fromRab_logicPhyRegMap_5_valid <= $urandom;
    i_fromRab_logicPhyRegMap_5_bits_lreg <= $urandom;
    i_fromRab_logicPhyRegMap_5_bits_preg <= $urandom;
    i_fromRat_vecOldVdPdest_0_valid <= $urandom;
    i_fromRat_vecOldVdPdest_0_bits <= $urandom;
    i_fromRat_vecOldVdPdest_1_valid <= $urandom;
    i_fromRat_vecOldVdPdest_1_bits <= $urandom;
    i_fromRat_vecOldVdPdest_2_valid <= $urandom;
    i_fromRat_vecOldVdPdest_2_bits <= $urandom;
    i_fromRat_vecOldVdPdest_3_valid <= $urandom;
    i_fromRat_vecOldVdPdest_3_bits <= $urandom;
    i_fromRat_vecOldVdPdest_4_valid <= $urandom;
    i_fromRat_vecOldVdPdest_4_bits <= $urandom;
    i_fromRat_vecOldVdPdest_5_valid <= $urandom;
    i_fromRat_vecOldVdPdest_5_bits <= $urandom;
    i_fromRat_v0OldVdPdest_0_valid <= $urandom;
    i_fromRat_v0OldVdPdest_0_bits <= $urandom;
    i_fromRat_v0OldVdPdest_1_valid <= $urandom;
    i_fromRat_v0OldVdPdest_1_bits <= $urandom;
    i_fromRat_v0OldVdPdest_2_valid <= $urandom;
    i_fromRat_v0OldVdPdest_2_bits <= $urandom;
    i_fromRat_v0OldVdPdest_3_valid <= $urandom;
    i_fromRat_v0OldVdPdest_3_bits <= $urandom;
    i_fromRat_v0OldVdPdest_4_valid <= $urandom;
    i_fromRat_v0OldVdPdest_4_bits <= $urandom;
    i_fromRat_v0OldVdPdest_5_valid <= $urandom;
    i_fromRat_v0OldVdPdest_5_bits <= $urandom;
    i_fromVprf_rdata_0_valid <= $urandom;
    i_fromVprf_rdata_0_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_1_valid <= $urandom;
    i_fromVprf_rdata_1_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_2_valid <= $urandom;
    i_fromVprf_rdata_2_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_3_valid <= $urandom;
    i_fromVprf_rdata_3_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_4_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_5_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_6_bits <= {$urandom,$urandom,$urandom,$urandom};
    i_fromVprf_rdata_7_bits <= {$urandom,$urandom,$urandom,$urandom};
    // 偏置: 让异常常发生 + nf/vsew 取小以走完 FSM 各状态。
    i_fromExceptionGen_valid <= ($urandom & 3) == 0;
    i_fromExceptionGen_bits_nf   <= $urandom % 3'd4;
    i_fromExceptionGen_bits_vsew <= $urandom % 2'd3;
    i_fromExceptionGen_bits_veew <= $urandom % 2'd3;
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_o_toVPRF_r_0_valid) && g_o_toVPRF_r_0_valid !== i_o_toVPRF_r_0_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_0_valid g=%h i=%h", $time, g_o_toVPRF_r_0_valid, i_o_toVPRF_r_0_valid); end
    if (!$isunknown(g_o_toVPRF_r_0_bits_isV0) && g_o_toVPRF_r_0_bits_isV0 !== i_o_toVPRF_r_0_bits_isV0) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_0_bits_isV0 g=%h i=%h", $time, g_o_toVPRF_r_0_bits_isV0, i_o_toVPRF_r_0_bits_isV0); end
    if (!$isunknown(g_o_toVPRF_r_0_bits_addr) && g_o_toVPRF_r_0_bits_addr !== i_o_toVPRF_r_0_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_0_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_0_bits_addr, i_o_toVPRF_r_0_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_1_valid) && g_o_toVPRF_r_1_valid !== i_o_toVPRF_r_1_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_1_valid g=%h i=%h", $time, g_o_toVPRF_r_1_valid, i_o_toVPRF_r_1_valid); end
    if (!$isunknown(g_o_toVPRF_r_1_bits_addr) && g_o_toVPRF_r_1_bits_addr !== i_o_toVPRF_r_1_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_1_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_1_bits_addr, i_o_toVPRF_r_1_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_2_valid) && g_o_toVPRF_r_2_valid !== i_o_toVPRF_r_2_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_2_valid g=%h i=%h", $time, g_o_toVPRF_r_2_valid, i_o_toVPRF_r_2_valid); end
    if (!$isunknown(g_o_toVPRF_r_2_bits_addr) && g_o_toVPRF_r_2_bits_addr !== i_o_toVPRF_r_2_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_2_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_2_bits_addr, i_o_toVPRF_r_2_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_3_valid) && g_o_toVPRF_r_3_valid !== i_o_toVPRF_r_3_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_3_valid g=%h i=%h", $time, g_o_toVPRF_r_3_valid, i_o_toVPRF_r_3_valid); end
    if (!$isunknown(g_o_toVPRF_r_3_bits_addr) && g_o_toVPRF_r_3_bits_addr !== i_o_toVPRF_r_3_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_3_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_3_bits_addr, i_o_toVPRF_r_3_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_4_valid) && g_o_toVPRF_r_4_valid !== i_o_toVPRF_r_4_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_4_valid g=%h i=%h", $time, g_o_toVPRF_r_4_valid, i_o_toVPRF_r_4_valid); end
    if (!$isunknown(g_o_toVPRF_r_4_bits_isV0) && g_o_toVPRF_r_4_bits_isV0 !== i_o_toVPRF_r_4_bits_isV0) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_4_bits_isV0 g=%h i=%h", $time, g_o_toVPRF_r_4_bits_isV0, i_o_toVPRF_r_4_bits_isV0); end
    if (!$isunknown(g_o_toVPRF_r_4_bits_addr) && g_o_toVPRF_r_4_bits_addr !== i_o_toVPRF_r_4_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_4_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_4_bits_addr, i_o_toVPRF_r_4_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_5_valid) && g_o_toVPRF_r_5_valid !== i_o_toVPRF_r_5_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_5_valid g=%h i=%h", $time, g_o_toVPRF_r_5_valid, i_o_toVPRF_r_5_valid); end
    if (!$isunknown(g_o_toVPRF_r_5_bits_addr) && g_o_toVPRF_r_5_bits_addr !== i_o_toVPRF_r_5_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_5_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_5_bits_addr, i_o_toVPRF_r_5_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_6_valid) && g_o_toVPRF_r_6_valid !== i_o_toVPRF_r_6_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_6_valid g=%h i=%h", $time, g_o_toVPRF_r_6_valid, i_o_toVPRF_r_6_valid); end
    if (!$isunknown(g_o_toVPRF_r_6_bits_addr) && g_o_toVPRF_r_6_bits_addr !== i_o_toVPRF_r_6_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_6_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_6_bits_addr, i_o_toVPRF_r_6_bits_addr); end
    if (!$isunknown(g_o_toVPRF_r_7_valid) && g_o_toVPRF_r_7_valid !== i_o_toVPRF_r_7_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_7_valid g=%h i=%h", $time, g_o_toVPRF_r_7_valid, i_o_toVPRF_r_7_valid); end
    if (!$isunknown(g_o_toVPRF_r_7_bits_addr) && g_o_toVPRF_r_7_bits_addr !== i_o_toVPRF_r_7_bits_addr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_r_7_bits_addr g=%h i=%h", $time, g_o_toVPRF_r_7_bits_addr, i_o_toVPRF_r_7_bits_addr); end
    if (!$isunknown(g_o_toVPRF_w_0_valid) && g_o_toVPRF_w_0_valid !== i_o_toVPRF_w_0_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_0_valid g=%h i=%h", $time, g_o_toVPRF_w_0_valid, i_o_toVPRF_w_0_valid); end
    if (!$isunknown(g_o_toVPRF_w_0_bits_isV0) && g_o_toVPRF_w_0_bits_isV0 !== i_o_toVPRF_w_0_bits_isV0) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_0_bits_isV0 g=%h i=%h", $time, g_o_toVPRF_w_0_bits_isV0, i_o_toVPRF_w_0_bits_isV0); end
    if (!$isunknown(g_o_toVPRF_w_0_bits_newVdAddr) && g_o_toVPRF_w_0_bits_newVdAddr !== i_o_toVPRF_w_0_bits_newVdAddr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_0_bits_newVdAddr g=%h i=%h", $time, g_o_toVPRF_w_0_bits_newVdAddr, i_o_toVPRF_w_0_bits_newVdAddr); end
    if (!$isunknown(g_o_toVPRF_w_0_bits_newVdData) && g_o_toVPRF_w_0_bits_newVdData !== i_o_toVPRF_w_0_bits_newVdData) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_0_bits_newVdData g=%h i=%h", $time, g_o_toVPRF_w_0_bits_newVdData, i_o_toVPRF_w_0_bits_newVdData); end
    if (!$isunknown(g_o_toVPRF_w_1_valid) && g_o_toVPRF_w_1_valid !== i_o_toVPRF_w_1_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_1_valid g=%h i=%h", $time, g_o_toVPRF_w_1_valid, i_o_toVPRF_w_1_valid); end
    if (!$isunknown(g_o_toVPRF_w_1_bits_newVdAddr) && g_o_toVPRF_w_1_bits_newVdAddr !== i_o_toVPRF_w_1_bits_newVdAddr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_1_bits_newVdAddr g=%h i=%h", $time, g_o_toVPRF_w_1_bits_newVdAddr, i_o_toVPRF_w_1_bits_newVdAddr); end
    if (!$isunknown(g_o_toVPRF_w_1_bits_newVdData) && g_o_toVPRF_w_1_bits_newVdData !== i_o_toVPRF_w_1_bits_newVdData) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_1_bits_newVdData g=%h i=%h", $time, g_o_toVPRF_w_1_bits_newVdData, i_o_toVPRF_w_1_bits_newVdData); end
    if (!$isunknown(g_o_toVPRF_w_2_valid) && g_o_toVPRF_w_2_valid !== i_o_toVPRF_w_2_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_2_valid g=%h i=%h", $time, g_o_toVPRF_w_2_valid, i_o_toVPRF_w_2_valid); end
    if (!$isunknown(g_o_toVPRF_w_2_bits_newVdAddr) && g_o_toVPRF_w_2_bits_newVdAddr !== i_o_toVPRF_w_2_bits_newVdAddr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_2_bits_newVdAddr g=%h i=%h", $time, g_o_toVPRF_w_2_bits_newVdAddr, i_o_toVPRF_w_2_bits_newVdAddr); end
    if (!$isunknown(g_o_toVPRF_w_2_bits_newVdData) && g_o_toVPRF_w_2_bits_newVdData !== i_o_toVPRF_w_2_bits_newVdData) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_2_bits_newVdData g=%h i=%h", $time, g_o_toVPRF_w_2_bits_newVdData, i_o_toVPRF_w_2_bits_newVdData); end
    if (!$isunknown(g_o_toVPRF_w_3_valid) && g_o_toVPRF_w_3_valid !== i_o_toVPRF_w_3_valid) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_3_valid g=%h i=%h", $time, g_o_toVPRF_w_3_valid, i_o_toVPRF_w_3_valid); end
    if (!$isunknown(g_o_toVPRF_w_3_bits_newVdAddr) && g_o_toVPRF_w_3_bits_newVdAddr !== i_o_toVPRF_w_3_bits_newVdAddr) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_3_bits_newVdAddr g=%h i=%h", $time, g_o_toVPRF_w_3_bits_newVdAddr, i_o_toVPRF_w_3_bits_newVdAddr); end
    if (!$isunknown(g_o_toVPRF_w_3_bits_newVdData) && g_o_toVPRF_w_3_bits_newVdData !== i_o_toVPRF_w_3_bits_newVdData) begin errors++;
      if(errors<=80) $display("[%0t] o_toVPRF_w_3_bits_newVdData g=%h i=%h", $time, g_o_toVPRF_w_3_bits_newVdData, i_o_toVPRF_w_3_bits_newVdData); end
    if (!$isunknown(g_o_status_busy) && g_o_status_busy !== i_o_status_busy) begin errors++;
      if(errors<=80) $display("[%0t] o_status_busy g=%h i=%h", $time, g_o_status_busy, i_o_status_busy); end
  end

  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
