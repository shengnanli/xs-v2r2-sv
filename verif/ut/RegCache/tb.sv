// 自动生成：verif/ut/RegCache/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// RegCache 双例化逐拍比对：golden RegCache vs 重写 RegCache_xs（子模块两侧各自 golden / 重写件），全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= RegCache =================
  int unsigned rc_mode = 0;
  logic rc_reset;
  logic rc_io_readPorts_0_ren;
  logic [4:0] rc_io_readPorts_0_addr;
  wire  [63:0] rc_g_io_readPorts_0_data, rc_i_io_readPorts_0_data;
  logic [63:0] rc_s0_io_readPorts_0_data = '0, rc_s1_io_readPorts_0_data = '0;
  logic rc_io_readPorts_1_ren;
  logic [4:0] rc_io_readPorts_1_addr;
  wire  [63:0] rc_g_io_readPorts_1_data, rc_i_io_readPorts_1_data;
  logic [63:0] rc_s0_io_readPorts_1_data = '0, rc_s1_io_readPorts_1_data = '0;
  logic rc_io_readPorts_2_ren;
  logic [4:0] rc_io_readPorts_2_addr;
  wire  [63:0] rc_g_io_readPorts_2_data, rc_i_io_readPorts_2_data;
  logic [63:0] rc_s0_io_readPorts_2_data = '0, rc_s1_io_readPorts_2_data = '0;
  logic rc_io_readPorts_3_ren;
  logic [4:0] rc_io_readPorts_3_addr;
  wire  [63:0] rc_g_io_readPorts_3_data, rc_i_io_readPorts_3_data;
  logic [63:0] rc_s0_io_readPorts_3_data = '0, rc_s1_io_readPorts_3_data = '0;
  logic rc_io_readPorts_4_ren;
  logic [4:0] rc_io_readPorts_4_addr;
  wire  [63:0] rc_g_io_readPorts_4_data, rc_i_io_readPorts_4_data;
  logic [63:0] rc_s0_io_readPorts_4_data = '0, rc_s1_io_readPorts_4_data = '0;
  logic rc_io_readPorts_5_ren;
  logic [4:0] rc_io_readPorts_5_addr;
  wire  [63:0] rc_g_io_readPorts_5_data, rc_i_io_readPorts_5_data;
  logic [63:0] rc_s0_io_readPorts_5_data = '0, rc_s1_io_readPorts_5_data = '0;
  logic rc_io_readPorts_6_ren;
  logic [4:0] rc_io_readPorts_6_addr;
  wire  [63:0] rc_g_io_readPorts_6_data, rc_i_io_readPorts_6_data;
  logic [63:0] rc_s0_io_readPorts_6_data = '0, rc_s1_io_readPorts_6_data = '0;
  logic rc_io_readPorts_7_ren;
  logic [4:0] rc_io_readPorts_7_addr;
  wire  [63:0] rc_g_io_readPorts_7_data, rc_i_io_readPorts_7_data;
  logic [63:0] rc_s0_io_readPorts_7_data = '0, rc_s1_io_readPorts_7_data = '0;
  logic rc_io_readPorts_8_ren;
  logic [4:0] rc_io_readPorts_8_addr;
  wire  [63:0] rc_g_io_readPorts_8_data, rc_i_io_readPorts_8_data;
  logic [63:0] rc_s0_io_readPorts_8_data = '0, rc_s1_io_readPorts_8_data = '0;
  logic rc_io_readPorts_9_ren;
  logic [4:0] rc_io_readPorts_9_addr;
  wire  [63:0] rc_g_io_readPorts_9_data, rc_i_io_readPorts_9_data;
  logic [63:0] rc_s0_io_readPorts_9_data = '0, rc_s1_io_readPorts_9_data = '0;
  logic rc_io_readPorts_10_ren;
  logic [4:0] rc_io_readPorts_10_addr;
  wire  [63:0] rc_g_io_readPorts_10_data, rc_i_io_readPorts_10_data;
  logic [63:0] rc_s0_io_readPorts_10_data = '0, rc_s1_io_readPorts_10_data = '0;
  logic rc_io_readPorts_11_ren;
  logic [4:0] rc_io_readPorts_11_addr;
  wire  [63:0] rc_g_io_readPorts_11_data, rc_i_io_readPorts_11_data;
  logic [63:0] rc_s0_io_readPorts_11_data = '0, rc_s1_io_readPorts_11_data = '0;
  logic rc_io_readPorts_12_ren;
  logic [4:0] rc_io_readPorts_12_addr;
  wire  [63:0] rc_g_io_readPorts_12_data, rc_i_io_readPorts_12_data;
  logic [63:0] rc_s0_io_readPorts_12_data = '0, rc_s1_io_readPorts_12_data = '0;
  logic rc_io_readPorts_13_ren;
  logic [4:0] rc_io_readPorts_13_addr;
  wire  [63:0] rc_g_io_readPorts_13_data, rc_i_io_readPorts_13_data;
  logic [63:0] rc_s0_io_readPorts_13_data = '0, rc_s1_io_readPorts_13_data = '0;
  logic rc_io_readPorts_14_ren;
  logic [4:0] rc_io_readPorts_14_addr;
  wire  [63:0] rc_g_io_readPorts_14_data, rc_i_io_readPorts_14_data;
  logic [63:0] rc_s0_io_readPorts_14_data = '0, rc_s1_io_readPorts_14_data = '0;
  logic rc_io_readPorts_15_ren;
  logic [4:0] rc_io_readPorts_15_addr;
  wire  [63:0] rc_g_io_readPorts_15_data, rc_i_io_readPorts_15_data;
  logic [63:0] rc_s0_io_readPorts_15_data = '0, rc_s1_io_readPorts_15_data = '0;
  logic rc_io_readPorts_16_ren;
  logic [4:0] rc_io_readPorts_16_addr;
  wire  [63:0] rc_g_io_readPorts_16_data, rc_i_io_readPorts_16_data;
  logic [63:0] rc_s0_io_readPorts_16_data = '0, rc_s1_io_readPorts_16_data = '0;
  logic rc_io_readPorts_17_ren;
  logic [4:0] rc_io_readPorts_17_addr;
  wire  [63:0] rc_g_io_readPorts_17_data, rc_i_io_readPorts_17_data;
  logic [63:0] rc_s0_io_readPorts_17_data = '0, rc_s1_io_readPorts_17_data = '0;
  logic rc_io_readPorts_18_ren;
  logic [4:0] rc_io_readPorts_18_addr;
  wire  [63:0] rc_g_io_readPorts_18_data, rc_i_io_readPorts_18_data;
  logic [63:0] rc_s0_io_readPorts_18_data = '0, rc_s1_io_readPorts_18_data = '0;
  logic rc_io_readPorts_19_ren;
  logic [4:0] rc_io_readPorts_19_addr;
  wire  [63:0] rc_g_io_readPorts_19_data, rc_i_io_readPorts_19_data;
  logic [63:0] rc_s0_io_readPorts_19_data = '0, rc_s1_io_readPorts_19_data = '0;
  logic rc_io_readPorts_20_ren;
  logic [4:0] rc_io_readPorts_20_addr;
  wire  [63:0] rc_g_io_readPorts_20_data, rc_i_io_readPorts_20_data;
  logic [63:0] rc_s0_io_readPorts_20_data = '0, rc_s1_io_readPorts_20_data = '0;
  logic rc_io_readPorts_21_ren;
  logic [4:0] rc_io_readPorts_21_addr;
  wire  [63:0] rc_g_io_readPorts_21_data, rc_i_io_readPorts_21_data;
  logic [63:0] rc_s0_io_readPorts_21_data = '0, rc_s1_io_readPorts_21_data = '0;
  logic rc_io_readPorts_22_ren;
  logic [4:0] rc_io_readPorts_22_addr;
  wire  [63:0] rc_g_io_readPorts_22_data, rc_i_io_readPorts_22_data;
  logic [63:0] rc_s0_io_readPorts_22_data = '0, rc_s1_io_readPorts_22_data = '0;
  logic rc_io_writePorts_0_wen;
  logic [63:0] rc_io_writePorts_0_data;
  logic rc_io_writePorts_1_wen;
  logic [63:0] rc_io_writePorts_1_data;
  logic rc_io_writePorts_2_wen;
  logic [63:0] rc_io_writePorts_2_data;
  logic rc_io_writePorts_3_wen;
  logic [63:0] rc_io_writePorts_3_data;
  logic rc_io_writePorts_4_wen;
  logic [63:0] rc_io_writePorts_4_data;
  logic rc_io_writePorts_5_wen;
  logic [63:0] rc_io_writePorts_5_data;
  logic rc_io_writePorts_6_wen;
  logic [63:0] rc_io_writePorts_6_data;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_0, rc_i_io_toWakeupQueueRCIdx_0;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_0 = '0, rc_s1_io_toWakeupQueueRCIdx_0 = '0;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_1, rc_i_io_toWakeupQueueRCIdx_1;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_1 = '0, rc_s1_io_toWakeupQueueRCIdx_1 = '0;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_2, rc_i_io_toWakeupQueueRCIdx_2;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_2 = '0, rc_s1_io_toWakeupQueueRCIdx_2 = '0;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_3, rc_i_io_toWakeupQueueRCIdx_3;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_3 = '0, rc_s1_io_toWakeupQueueRCIdx_3 = '0;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_4, rc_i_io_toWakeupQueueRCIdx_4;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_4 = '0, rc_s1_io_toWakeupQueueRCIdx_4 = '0;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_5, rc_i_io_toWakeupQueueRCIdx_5;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_5 = '0, rc_s1_io_toWakeupQueueRCIdx_5 = '0;
  wire  [4:0] rc_g_io_toWakeupQueueRCIdx_6, rc_i_io_toWakeupQueueRCIdx_6;
  logic [4:0] rc_s0_io_toWakeupQueueRCIdx_6 = '0, rc_s1_io_toWakeupQueueRCIdx_6 = '0;
  int rc_cov_mem_half_read = 0;
  int rc_cov_int_half_read = 0;
  int rc_cov_all_int_wen = 0;
  int rc_cov_all_mem_wen = 0;
  logic [24:0] rc_armed = '0;
  int rc_armed_at = -1;
  RegCache rc_u_gold (
    .clock(clk),
    .reset(rc_reset),
    .io_readPorts_0_ren(rc_io_readPorts_0_ren),
    .io_readPorts_0_addr(rc_io_readPorts_0_addr),
    .io_readPorts_0_data(rc_g_io_readPorts_0_data),
    .io_readPorts_1_ren(rc_io_readPorts_1_ren),
    .io_readPorts_1_addr(rc_io_readPorts_1_addr),
    .io_readPorts_1_data(rc_g_io_readPorts_1_data),
    .io_readPorts_2_ren(rc_io_readPorts_2_ren),
    .io_readPorts_2_addr(rc_io_readPorts_2_addr),
    .io_readPorts_2_data(rc_g_io_readPorts_2_data),
    .io_readPorts_3_ren(rc_io_readPorts_3_ren),
    .io_readPorts_3_addr(rc_io_readPorts_3_addr),
    .io_readPorts_3_data(rc_g_io_readPorts_3_data),
    .io_readPorts_4_ren(rc_io_readPorts_4_ren),
    .io_readPorts_4_addr(rc_io_readPorts_4_addr),
    .io_readPorts_4_data(rc_g_io_readPorts_4_data),
    .io_readPorts_5_ren(rc_io_readPorts_5_ren),
    .io_readPorts_5_addr(rc_io_readPorts_5_addr),
    .io_readPorts_5_data(rc_g_io_readPorts_5_data),
    .io_readPorts_6_ren(rc_io_readPorts_6_ren),
    .io_readPorts_6_addr(rc_io_readPorts_6_addr),
    .io_readPorts_6_data(rc_g_io_readPorts_6_data),
    .io_readPorts_7_ren(rc_io_readPorts_7_ren),
    .io_readPorts_7_addr(rc_io_readPorts_7_addr),
    .io_readPorts_7_data(rc_g_io_readPorts_7_data),
    .io_readPorts_8_ren(rc_io_readPorts_8_ren),
    .io_readPorts_8_addr(rc_io_readPorts_8_addr),
    .io_readPorts_8_data(rc_g_io_readPorts_8_data),
    .io_readPorts_9_ren(rc_io_readPorts_9_ren),
    .io_readPorts_9_addr(rc_io_readPorts_9_addr),
    .io_readPorts_9_data(rc_g_io_readPorts_9_data),
    .io_readPorts_10_ren(rc_io_readPorts_10_ren),
    .io_readPorts_10_addr(rc_io_readPorts_10_addr),
    .io_readPorts_10_data(rc_g_io_readPorts_10_data),
    .io_readPorts_11_ren(rc_io_readPorts_11_ren),
    .io_readPorts_11_addr(rc_io_readPorts_11_addr),
    .io_readPorts_11_data(rc_g_io_readPorts_11_data),
    .io_readPorts_12_ren(rc_io_readPorts_12_ren),
    .io_readPorts_12_addr(rc_io_readPorts_12_addr),
    .io_readPorts_12_data(rc_g_io_readPorts_12_data),
    .io_readPorts_13_ren(rc_io_readPorts_13_ren),
    .io_readPorts_13_addr(rc_io_readPorts_13_addr),
    .io_readPorts_13_data(rc_g_io_readPorts_13_data),
    .io_readPorts_14_ren(rc_io_readPorts_14_ren),
    .io_readPorts_14_addr(rc_io_readPorts_14_addr),
    .io_readPorts_14_data(rc_g_io_readPorts_14_data),
    .io_readPorts_15_ren(rc_io_readPorts_15_ren),
    .io_readPorts_15_addr(rc_io_readPorts_15_addr),
    .io_readPorts_15_data(rc_g_io_readPorts_15_data),
    .io_readPorts_16_ren(rc_io_readPorts_16_ren),
    .io_readPorts_16_addr(rc_io_readPorts_16_addr),
    .io_readPorts_16_data(rc_g_io_readPorts_16_data),
    .io_readPorts_17_ren(rc_io_readPorts_17_ren),
    .io_readPorts_17_addr(rc_io_readPorts_17_addr),
    .io_readPorts_17_data(rc_g_io_readPorts_17_data),
    .io_readPorts_18_ren(rc_io_readPorts_18_ren),
    .io_readPorts_18_addr(rc_io_readPorts_18_addr),
    .io_readPorts_18_data(rc_g_io_readPorts_18_data),
    .io_readPorts_19_ren(rc_io_readPorts_19_ren),
    .io_readPorts_19_addr(rc_io_readPorts_19_addr),
    .io_readPorts_19_data(rc_g_io_readPorts_19_data),
    .io_readPorts_20_ren(rc_io_readPorts_20_ren),
    .io_readPorts_20_addr(rc_io_readPorts_20_addr),
    .io_readPorts_20_data(rc_g_io_readPorts_20_data),
    .io_readPorts_21_ren(rc_io_readPorts_21_ren),
    .io_readPorts_21_addr(rc_io_readPorts_21_addr),
    .io_readPorts_21_data(rc_g_io_readPorts_21_data),
    .io_readPorts_22_ren(rc_io_readPorts_22_ren),
    .io_readPorts_22_addr(rc_io_readPorts_22_addr),
    .io_readPorts_22_data(rc_g_io_readPorts_22_data),
    .io_writePorts_0_wen(rc_io_writePorts_0_wen),
    .io_writePorts_0_data(rc_io_writePorts_0_data),
    .io_writePorts_1_wen(rc_io_writePorts_1_wen),
    .io_writePorts_1_data(rc_io_writePorts_1_data),
    .io_writePorts_2_wen(rc_io_writePorts_2_wen),
    .io_writePorts_2_data(rc_io_writePorts_2_data),
    .io_writePorts_3_wen(rc_io_writePorts_3_wen),
    .io_writePorts_3_data(rc_io_writePorts_3_data),
    .io_writePorts_4_wen(rc_io_writePorts_4_wen),
    .io_writePorts_4_data(rc_io_writePorts_4_data),
    .io_writePorts_5_wen(rc_io_writePorts_5_wen),
    .io_writePorts_5_data(rc_io_writePorts_5_data),
    .io_writePorts_6_wen(rc_io_writePorts_6_wen),
    .io_writePorts_6_data(rc_io_writePorts_6_data),
    .io_toWakeupQueueRCIdx_0(rc_g_io_toWakeupQueueRCIdx_0),
    .io_toWakeupQueueRCIdx_1(rc_g_io_toWakeupQueueRCIdx_1),
    .io_toWakeupQueueRCIdx_2(rc_g_io_toWakeupQueueRCIdx_2),
    .io_toWakeupQueueRCIdx_3(rc_g_io_toWakeupQueueRCIdx_3),
    .io_toWakeupQueueRCIdx_4(rc_g_io_toWakeupQueueRCIdx_4),
    .io_toWakeupQueueRCIdx_5(rc_g_io_toWakeupQueueRCIdx_5),
    .io_toWakeupQueueRCIdx_6(rc_g_io_toWakeupQueueRCIdx_6)
  );
  RegCache_xs rc_u_impl (
    .clock(clk),
    .reset(rc_reset),
    .io_readPorts_0_ren(rc_io_readPorts_0_ren),
    .io_readPorts_0_addr(rc_io_readPorts_0_addr),
    .io_readPorts_0_data(rc_i_io_readPorts_0_data),
    .io_readPorts_1_ren(rc_io_readPorts_1_ren),
    .io_readPorts_1_addr(rc_io_readPorts_1_addr),
    .io_readPorts_1_data(rc_i_io_readPorts_1_data),
    .io_readPorts_2_ren(rc_io_readPorts_2_ren),
    .io_readPorts_2_addr(rc_io_readPorts_2_addr),
    .io_readPorts_2_data(rc_i_io_readPorts_2_data),
    .io_readPorts_3_ren(rc_io_readPorts_3_ren),
    .io_readPorts_3_addr(rc_io_readPorts_3_addr),
    .io_readPorts_3_data(rc_i_io_readPorts_3_data),
    .io_readPorts_4_ren(rc_io_readPorts_4_ren),
    .io_readPorts_4_addr(rc_io_readPorts_4_addr),
    .io_readPorts_4_data(rc_i_io_readPorts_4_data),
    .io_readPorts_5_ren(rc_io_readPorts_5_ren),
    .io_readPorts_5_addr(rc_io_readPorts_5_addr),
    .io_readPorts_5_data(rc_i_io_readPorts_5_data),
    .io_readPorts_6_ren(rc_io_readPorts_6_ren),
    .io_readPorts_6_addr(rc_io_readPorts_6_addr),
    .io_readPorts_6_data(rc_i_io_readPorts_6_data),
    .io_readPorts_7_ren(rc_io_readPorts_7_ren),
    .io_readPorts_7_addr(rc_io_readPorts_7_addr),
    .io_readPorts_7_data(rc_i_io_readPorts_7_data),
    .io_readPorts_8_ren(rc_io_readPorts_8_ren),
    .io_readPorts_8_addr(rc_io_readPorts_8_addr),
    .io_readPorts_8_data(rc_i_io_readPorts_8_data),
    .io_readPorts_9_ren(rc_io_readPorts_9_ren),
    .io_readPorts_9_addr(rc_io_readPorts_9_addr),
    .io_readPorts_9_data(rc_i_io_readPorts_9_data),
    .io_readPorts_10_ren(rc_io_readPorts_10_ren),
    .io_readPorts_10_addr(rc_io_readPorts_10_addr),
    .io_readPorts_10_data(rc_i_io_readPorts_10_data),
    .io_readPorts_11_ren(rc_io_readPorts_11_ren),
    .io_readPorts_11_addr(rc_io_readPorts_11_addr),
    .io_readPorts_11_data(rc_i_io_readPorts_11_data),
    .io_readPorts_12_ren(rc_io_readPorts_12_ren),
    .io_readPorts_12_addr(rc_io_readPorts_12_addr),
    .io_readPorts_12_data(rc_i_io_readPorts_12_data),
    .io_readPorts_13_ren(rc_io_readPorts_13_ren),
    .io_readPorts_13_addr(rc_io_readPorts_13_addr),
    .io_readPorts_13_data(rc_i_io_readPorts_13_data),
    .io_readPorts_14_ren(rc_io_readPorts_14_ren),
    .io_readPorts_14_addr(rc_io_readPorts_14_addr),
    .io_readPorts_14_data(rc_i_io_readPorts_14_data),
    .io_readPorts_15_ren(rc_io_readPorts_15_ren),
    .io_readPorts_15_addr(rc_io_readPorts_15_addr),
    .io_readPorts_15_data(rc_i_io_readPorts_15_data),
    .io_readPorts_16_ren(rc_io_readPorts_16_ren),
    .io_readPorts_16_addr(rc_io_readPorts_16_addr),
    .io_readPorts_16_data(rc_i_io_readPorts_16_data),
    .io_readPorts_17_ren(rc_io_readPorts_17_ren),
    .io_readPorts_17_addr(rc_io_readPorts_17_addr),
    .io_readPorts_17_data(rc_i_io_readPorts_17_data),
    .io_readPorts_18_ren(rc_io_readPorts_18_ren),
    .io_readPorts_18_addr(rc_io_readPorts_18_addr),
    .io_readPorts_18_data(rc_i_io_readPorts_18_data),
    .io_readPorts_19_ren(rc_io_readPorts_19_ren),
    .io_readPorts_19_addr(rc_io_readPorts_19_addr),
    .io_readPorts_19_data(rc_i_io_readPorts_19_data),
    .io_readPorts_20_ren(rc_io_readPorts_20_ren),
    .io_readPorts_20_addr(rc_io_readPorts_20_addr),
    .io_readPorts_20_data(rc_i_io_readPorts_20_data),
    .io_readPorts_21_ren(rc_io_readPorts_21_ren),
    .io_readPorts_21_addr(rc_io_readPorts_21_addr),
    .io_readPorts_21_data(rc_i_io_readPorts_21_data),
    .io_readPorts_22_ren(rc_io_readPorts_22_ren),
    .io_readPorts_22_addr(rc_io_readPorts_22_addr),
    .io_readPorts_22_data(rc_i_io_readPorts_22_data),
    .io_writePorts_0_wen(rc_io_writePorts_0_wen),
    .io_writePorts_0_data(rc_io_writePorts_0_data),
    .io_writePorts_1_wen(rc_io_writePorts_1_wen),
    .io_writePorts_1_data(rc_io_writePorts_1_data),
    .io_writePorts_2_wen(rc_io_writePorts_2_wen),
    .io_writePorts_2_data(rc_io_writePorts_2_data),
    .io_writePorts_3_wen(rc_io_writePorts_3_wen),
    .io_writePorts_3_data(rc_io_writePorts_3_data),
    .io_writePorts_4_wen(rc_io_writePorts_4_wen),
    .io_writePorts_4_data(rc_io_writePorts_4_data),
    .io_writePorts_5_wen(rc_io_writePorts_5_wen),
    .io_writePorts_5_data(rc_io_writePorts_5_data),
    .io_writePorts_6_wen(rc_io_writePorts_6_wen),
    .io_writePorts_6_data(rc_io_writePorts_6_data),
    .io_toWakeupQueueRCIdx_0(rc_i_io_toWakeupQueueRCIdx_0),
    .io_toWakeupQueueRCIdx_1(rc_i_io_toWakeupQueueRCIdx_1),
    .io_toWakeupQueueRCIdx_2(rc_i_io_toWakeupQueueRCIdx_2),
    .io_toWakeupQueueRCIdx_3(rc_i_io_toWakeupQueueRCIdx_3),
    .io_toWakeupQueueRCIdx_4(rc_i_io_toWakeupQueueRCIdx_4),
    .io_toWakeupQueueRCIdx_5(rc_i_io_toWakeupQueueRCIdx_5),
    .io_toWakeupQueueRCIdx_6(rc_i_io_toWakeupQueueRCIdx_6)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) rc_mode = $urandom_range(0, 15);
      rc_io_readPorts_0_ren = 1'($urandom);
      rc_io_readPorts_0_addr = 5'($urandom);
      rc_io_readPorts_1_ren = 1'($urandom);
      rc_io_readPorts_1_addr = 5'($urandom);
      rc_io_readPorts_2_ren = 1'($urandom);
      rc_io_readPorts_2_addr = 5'($urandom);
      rc_io_readPorts_3_ren = 1'($urandom);
      rc_io_readPorts_3_addr = 5'($urandom);
      rc_io_readPorts_4_ren = 1'($urandom);
      rc_io_readPorts_4_addr = 5'($urandom);
      rc_io_readPorts_5_ren = 1'($urandom);
      rc_io_readPorts_5_addr = 5'($urandom);
      rc_io_readPorts_6_ren = 1'($urandom);
      rc_io_readPorts_6_addr = 5'($urandom);
      rc_io_readPorts_7_ren = 1'($urandom);
      rc_io_readPorts_7_addr = 5'($urandom);
      rc_io_readPorts_8_ren = 1'($urandom);
      rc_io_readPorts_8_addr = 5'($urandom);
      rc_io_readPorts_9_ren = 1'($urandom);
      rc_io_readPorts_9_addr = 5'($urandom);
      rc_io_readPorts_10_ren = 1'($urandom);
      rc_io_readPorts_10_addr = 5'($urandom);
      rc_io_readPorts_11_ren = 1'($urandom);
      rc_io_readPorts_11_addr = 5'($urandom);
      rc_io_readPorts_12_ren = 1'($urandom);
      rc_io_readPorts_12_addr = 5'($urandom);
      rc_io_readPorts_13_ren = 1'($urandom);
      rc_io_readPorts_13_addr = 5'($urandom);
      rc_io_readPorts_14_ren = 1'($urandom);
      rc_io_readPorts_14_addr = 5'($urandom);
      rc_io_readPorts_15_ren = 1'($urandom);
      rc_io_readPorts_15_addr = 5'($urandom);
      rc_io_readPorts_16_ren = 1'($urandom);
      rc_io_readPorts_16_addr = 5'($urandom);
      rc_io_readPorts_17_ren = 1'($urandom);
      rc_io_readPorts_17_addr = 5'($urandom);
      rc_io_readPorts_18_ren = 1'($urandom);
      rc_io_readPorts_18_addr = 5'($urandom);
      rc_io_readPorts_19_ren = 1'($urandom);
      rc_io_readPorts_19_addr = 5'($urandom);
      rc_io_readPorts_20_ren = 1'($urandom);
      rc_io_readPorts_20_addr = 5'($urandom);
      rc_io_readPorts_21_ren = 1'($urandom);
      rc_io_readPorts_21_addr = 5'($urandom);
      rc_io_readPorts_22_ren = 1'($urandom);
      rc_io_readPorts_22_addr = 5'($urandom);
      rc_io_writePorts_0_wen = 1'($urandom);
      rc_io_writePorts_0_data = 64'({$urandom, $urandom});
      rc_io_writePorts_1_wen = 1'($urandom);
      rc_io_writePorts_1_data = 64'({$urandom, $urandom});
      rc_io_writePorts_2_wen = 1'($urandom);
      rc_io_writePorts_2_data = 64'({$urandom, $urandom});
      rc_io_writePorts_3_wen = 1'($urandom);
      rc_io_writePorts_3_data = 64'({$urandom, $urandom});
      rc_io_writePorts_4_wen = 1'($urandom);
      rc_io_writePorts_4_data = 64'({$urandom, $urandom});
      rc_io_writePorts_5_wen = 1'($urandom);
      rc_io_writePorts_5_data = 64'({$urandom, $urandom});
      rc_io_writePorts_6_wen = 1'($urandom);
      rc_io_writePorts_6_data = 64'({$urandom, $urandom});
      rc_reset = (cyc < RESET_CYC);
      #4;
      if (cyc >= RESET_CYC + 0 && rc_armed_at >= 0 && cyc >= rc_armed_at) begin
        checks++;
        if (rc_g_io_readPorts_0_data !== rc_i_io_readPorts_0_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_0_data g=%h i=%h", cyc, rc_g_io_readPorts_0_data, rc_i_io_readPorts_0_data);
        end
        rc_s1_io_readPorts_0_data |= rc_g_io_readPorts_0_data;
        rc_s0_io_readPorts_0_data |= ~rc_g_io_readPorts_0_data;
        checks++;
        if (rc_g_io_readPorts_1_data !== rc_i_io_readPorts_1_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_1_data g=%h i=%h", cyc, rc_g_io_readPorts_1_data, rc_i_io_readPorts_1_data);
        end
        rc_s1_io_readPorts_1_data |= rc_g_io_readPorts_1_data;
        rc_s0_io_readPorts_1_data |= ~rc_g_io_readPorts_1_data;
        checks++;
        if (rc_g_io_readPorts_2_data !== rc_i_io_readPorts_2_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_2_data g=%h i=%h", cyc, rc_g_io_readPorts_2_data, rc_i_io_readPorts_2_data);
        end
        rc_s1_io_readPorts_2_data |= rc_g_io_readPorts_2_data;
        rc_s0_io_readPorts_2_data |= ~rc_g_io_readPorts_2_data;
        checks++;
        if (rc_g_io_readPorts_3_data !== rc_i_io_readPorts_3_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_3_data g=%h i=%h", cyc, rc_g_io_readPorts_3_data, rc_i_io_readPorts_3_data);
        end
        rc_s1_io_readPorts_3_data |= rc_g_io_readPorts_3_data;
        rc_s0_io_readPorts_3_data |= ~rc_g_io_readPorts_3_data;
        checks++;
        if (rc_g_io_readPorts_4_data !== rc_i_io_readPorts_4_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_4_data g=%h i=%h", cyc, rc_g_io_readPorts_4_data, rc_i_io_readPorts_4_data);
        end
        rc_s1_io_readPorts_4_data |= rc_g_io_readPorts_4_data;
        rc_s0_io_readPorts_4_data |= ~rc_g_io_readPorts_4_data;
        checks++;
        if (rc_g_io_readPorts_5_data !== rc_i_io_readPorts_5_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_5_data g=%h i=%h", cyc, rc_g_io_readPorts_5_data, rc_i_io_readPorts_5_data);
        end
        rc_s1_io_readPorts_5_data |= rc_g_io_readPorts_5_data;
        rc_s0_io_readPorts_5_data |= ~rc_g_io_readPorts_5_data;
        checks++;
        if (rc_g_io_readPorts_6_data !== rc_i_io_readPorts_6_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_6_data g=%h i=%h", cyc, rc_g_io_readPorts_6_data, rc_i_io_readPorts_6_data);
        end
        rc_s1_io_readPorts_6_data |= rc_g_io_readPorts_6_data;
        rc_s0_io_readPorts_6_data |= ~rc_g_io_readPorts_6_data;
        checks++;
        if (rc_g_io_readPorts_7_data !== rc_i_io_readPorts_7_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_7_data g=%h i=%h", cyc, rc_g_io_readPorts_7_data, rc_i_io_readPorts_7_data);
        end
        rc_s1_io_readPorts_7_data |= rc_g_io_readPorts_7_data;
        rc_s0_io_readPorts_7_data |= ~rc_g_io_readPorts_7_data;
        checks++;
        if (rc_g_io_readPorts_8_data !== rc_i_io_readPorts_8_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_8_data g=%h i=%h", cyc, rc_g_io_readPorts_8_data, rc_i_io_readPorts_8_data);
        end
        rc_s1_io_readPorts_8_data |= rc_g_io_readPorts_8_data;
        rc_s0_io_readPorts_8_data |= ~rc_g_io_readPorts_8_data;
        checks++;
        if (rc_g_io_readPorts_9_data !== rc_i_io_readPorts_9_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_9_data g=%h i=%h", cyc, rc_g_io_readPorts_9_data, rc_i_io_readPorts_9_data);
        end
        rc_s1_io_readPorts_9_data |= rc_g_io_readPorts_9_data;
        rc_s0_io_readPorts_9_data |= ~rc_g_io_readPorts_9_data;
        checks++;
        if (rc_g_io_readPorts_10_data !== rc_i_io_readPorts_10_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_10_data g=%h i=%h", cyc, rc_g_io_readPorts_10_data, rc_i_io_readPorts_10_data);
        end
        rc_s1_io_readPorts_10_data |= rc_g_io_readPorts_10_data;
        rc_s0_io_readPorts_10_data |= ~rc_g_io_readPorts_10_data;
        checks++;
        if (rc_g_io_readPorts_11_data !== rc_i_io_readPorts_11_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_11_data g=%h i=%h", cyc, rc_g_io_readPorts_11_data, rc_i_io_readPorts_11_data);
        end
        rc_s1_io_readPorts_11_data |= rc_g_io_readPorts_11_data;
        rc_s0_io_readPorts_11_data |= ~rc_g_io_readPorts_11_data;
        checks++;
        if (rc_g_io_readPorts_12_data !== rc_i_io_readPorts_12_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_12_data g=%h i=%h", cyc, rc_g_io_readPorts_12_data, rc_i_io_readPorts_12_data);
        end
        rc_s1_io_readPorts_12_data |= rc_g_io_readPorts_12_data;
        rc_s0_io_readPorts_12_data |= ~rc_g_io_readPorts_12_data;
        checks++;
        if (rc_g_io_readPorts_13_data !== rc_i_io_readPorts_13_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_13_data g=%h i=%h", cyc, rc_g_io_readPorts_13_data, rc_i_io_readPorts_13_data);
        end
        rc_s1_io_readPorts_13_data |= rc_g_io_readPorts_13_data;
        rc_s0_io_readPorts_13_data |= ~rc_g_io_readPorts_13_data;
        checks++;
        if (rc_g_io_readPorts_14_data !== rc_i_io_readPorts_14_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_14_data g=%h i=%h", cyc, rc_g_io_readPorts_14_data, rc_i_io_readPorts_14_data);
        end
        rc_s1_io_readPorts_14_data |= rc_g_io_readPorts_14_data;
        rc_s0_io_readPorts_14_data |= ~rc_g_io_readPorts_14_data;
        checks++;
        if (rc_g_io_readPorts_15_data !== rc_i_io_readPorts_15_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_15_data g=%h i=%h", cyc, rc_g_io_readPorts_15_data, rc_i_io_readPorts_15_data);
        end
        rc_s1_io_readPorts_15_data |= rc_g_io_readPorts_15_data;
        rc_s0_io_readPorts_15_data |= ~rc_g_io_readPorts_15_data;
        checks++;
        if (rc_g_io_readPorts_16_data !== rc_i_io_readPorts_16_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_16_data g=%h i=%h", cyc, rc_g_io_readPorts_16_data, rc_i_io_readPorts_16_data);
        end
        rc_s1_io_readPorts_16_data |= rc_g_io_readPorts_16_data;
        rc_s0_io_readPorts_16_data |= ~rc_g_io_readPorts_16_data;
        checks++;
        if (rc_g_io_readPorts_17_data !== rc_i_io_readPorts_17_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_17_data g=%h i=%h", cyc, rc_g_io_readPorts_17_data, rc_i_io_readPorts_17_data);
        end
        rc_s1_io_readPorts_17_data |= rc_g_io_readPorts_17_data;
        rc_s0_io_readPorts_17_data |= ~rc_g_io_readPorts_17_data;
        checks++;
        if (rc_g_io_readPorts_18_data !== rc_i_io_readPorts_18_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_18_data g=%h i=%h", cyc, rc_g_io_readPorts_18_data, rc_i_io_readPorts_18_data);
        end
        rc_s1_io_readPorts_18_data |= rc_g_io_readPorts_18_data;
        rc_s0_io_readPorts_18_data |= ~rc_g_io_readPorts_18_data;
        checks++;
        if (rc_g_io_readPorts_19_data !== rc_i_io_readPorts_19_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_19_data g=%h i=%h", cyc, rc_g_io_readPorts_19_data, rc_i_io_readPorts_19_data);
        end
        rc_s1_io_readPorts_19_data |= rc_g_io_readPorts_19_data;
        rc_s0_io_readPorts_19_data |= ~rc_g_io_readPorts_19_data;
        checks++;
        if (rc_g_io_readPorts_20_data !== rc_i_io_readPorts_20_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_20_data g=%h i=%h", cyc, rc_g_io_readPorts_20_data, rc_i_io_readPorts_20_data);
        end
        rc_s1_io_readPorts_20_data |= rc_g_io_readPorts_20_data;
        rc_s0_io_readPorts_20_data |= ~rc_g_io_readPorts_20_data;
        checks++;
        if (rc_g_io_readPorts_21_data !== rc_i_io_readPorts_21_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_21_data g=%h i=%h", cyc, rc_g_io_readPorts_21_data, rc_i_io_readPorts_21_data);
        end
        rc_s1_io_readPorts_21_data |= rc_g_io_readPorts_21_data;
        rc_s0_io_readPorts_21_data |= ~rc_g_io_readPorts_21_data;
        checks++;
        if (rc_g_io_readPorts_22_data !== rc_i_io_readPorts_22_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_readPorts_22_data g=%h i=%h", cyc, rc_g_io_readPorts_22_data, rc_i_io_readPorts_22_data);
        end
        rc_s1_io_readPorts_22_data |= rc_g_io_readPorts_22_data;
        rc_s0_io_readPorts_22_data |= ~rc_g_io_readPorts_22_data;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_0 !== rc_i_io_toWakeupQueueRCIdx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_0 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_0, rc_i_io_toWakeupQueueRCIdx_0);
        end
        rc_s1_io_toWakeupQueueRCIdx_0 |= rc_g_io_toWakeupQueueRCIdx_0;
        rc_s0_io_toWakeupQueueRCIdx_0 |= ~rc_g_io_toWakeupQueueRCIdx_0;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_1 !== rc_i_io_toWakeupQueueRCIdx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_1 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_1, rc_i_io_toWakeupQueueRCIdx_1);
        end
        rc_s1_io_toWakeupQueueRCIdx_1 |= rc_g_io_toWakeupQueueRCIdx_1;
        rc_s0_io_toWakeupQueueRCIdx_1 |= ~rc_g_io_toWakeupQueueRCIdx_1;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_2 !== rc_i_io_toWakeupQueueRCIdx_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_2 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_2, rc_i_io_toWakeupQueueRCIdx_2);
        end
        rc_s1_io_toWakeupQueueRCIdx_2 |= rc_g_io_toWakeupQueueRCIdx_2;
        rc_s0_io_toWakeupQueueRCIdx_2 |= ~rc_g_io_toWakeupQueueRCIdx_2;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_3 !== rc_i_io_toWakeupQueueRCIdx_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_3 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_3, rc_i_io_toWakeupQueueRCIdx_3);
        end
        rc_s1_io_toWakeupQueueRCIdx_3 |= rc_g_io_toWakeupQueueRCIdx_3;
        rc_s0_io_toWakeupQueueRCIdx_3 |= ~rc_g_io_toWakeupQueueRCIdx_3;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_4 !== rc_i_io_toWakeupQueueRCIdx_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_4 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_4, rc_i_io_toWakeupQueueRCIdx_4);
        end
        rc_s1_io_toWakeupQueueRCIdx_4 |= rc_g_io_toWakeupQueueRCIdx_4;
        rc_s0_io_toWakeupQueueRCIdx_4 |= ~rc_g_io_toWakeupQueueRCIdx_4;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_5 !== rc_i_io_toWakeupQueueRCIdx_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_5 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_5, rc_i_io_toWakeupQueueRCIdx_5);
        end
        rc_s1_io_toWakeupQueueRCIdx_5 |= rc_g_io_toWakeupQueueRCIdx_5;
        rc_s0_io_toWakeupQueueRCIdx_5 |= ~rc_g_io_toWakeupQueueRCIdx_5;
        checks++;
        if (rc_g_io_toWakeupQueueRCIdx_6 !== rc_i_io_toWakeupQueueRCIdx_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RegCache.io_toWakeupQueueRCIdx_6 g=%h i=%h", cyc, rc_g_io_toWakeupQueueRCIdx_6, rc_i_io_toWakeupQueueRCIdx_6);
        end
        rc_s1_io_toWakeupQueueRCIdx_6 |= rc_g_io_toWakeupQueueRCIdx_6;
        rc_s0_io_toWakeupQueueRCIdx_6 |= ~rc_g_io_toWakeupQueueRCIdx_6;
        if (rc_io_readPorts_0_ren && rc_io_readPorts_0_addr[4]) rc_cov_mem_half_read++;
        if (rc_io_readPorts_0_ren && !rc_io_readPorts_0_addr[4]) rc_cov_int_half_read++;
        if (rc_io_writePorts_0_wen && rc_io_writePorts_1_wen && rc_io_writePorts_2_wen && rc_io_writePorts_3_wen) rc_cov_all_int_wen++;
        if (rc_io_writePorts_4_wen && rc_io_writePorts_5_wen && rc_io_writePorts_6_wen) rc_cov_all_mem_wen++;
      end
      if (&{rc_u_gold.IntRegCache.io_validInfo_0, rc_u_gold.IntRegCache.io_validInfo_1, rc_u_gold.IntRegCache.io_validInfo_2, rc_u_gold.IntRegCache.io_validInfo_3, rc_u_gold.IntRegCache.io_validInfo_4, rc_u_gold.IntRegCache.io_validInfo_5, rc_u_gold.IntRegCache.io_validInfo_6, rc_u_gold.IntRegCache.io_validInfo_7, rc_u_gold.IntRegCache.io_validInfo_8, rc_u_gold.IntRegCache.io_validInfo_9, rc_u_gold.IntRegCache.io_validInfo_10, rc_u_gold.IntRegCache.io_validInfo_11, rc_u_gold.IntRegCache.io_validInfo_12, rc_u_gold.IntRegCache.io_validInfo_13, rc_u_gold.IntRegCache.io_validInfo_14, rc_u_gold.IntRegCache.io_validInfo_15}) rc_armed[0] = 1'b1;
      if (&{rc_u_gold.MemRegCache.io_validInfo_0, rc_u_gold.MemRegCache.io_validInfo_1, rc_u_gold.MemRegCache.io_validInfo_2, rc_u_gold.MemRegCache.io_validInfo_3, rc_u_gold.MemRegCache.io_validInfo_4, rc_u_gold.MemRegCache.io_validInfo_5, rc_u_gold.MemRegCache.io_validInfo_6, rc_u_gold.MemRegCache.io_validInfo_7, rc_u_gold.MemRegCache.io_validInfo_8, rc_u_gold.MemRegCache.io_validInfo_9, rc_u_gold.MemRegCache.io_validInfo_10, rc_u_gold.MemRegCache.io_validInfo_11}) rc_armed[1] = 1'b1;
      if (rc_io_readPorts_0_ren) rc_armed[2] = 1'b1;
      if (rc_io_readPorts_1_ren) rc_armed[3] = 1'b1;
      if (rc_io_readPorts_2_ren) rc_armed[4] = 1'b1;
      if (rc_io_readPorts_3_ren) rc_armed[5] = 1'b1;
      if (rc_io_readPorts_4_ren) rc_armed[6] = 1'b1;
      if (rc_io_readPorts_5_ren) rc_armed[7] = 1'b1;
      if (rc_io_readPorts_6_ren) rc_armed[8] = 1'b1;
      if (rc_io_readPorts_7_ren) rc_armed[9] = 1'b1;
      if (rc_io_readPorts_8_ren) rc_armed[10] = 1'b1;
      if (rc_io_readPorts_9_ren) rc_armed[11] = 1'b1;
      if (rc_io_readPorts_10_ren) rc_armed[12] = 1'b1;
      if (rc_io_readPorts_11_ren) rc_armed[13] = 1'b1;
      if (rc_io_readPorts_12_ren) rc_armed[14] = 1'b1;
      if (rc_io_readPorts_13_ren) rc_armed[15] = 1'b1;
      if (rc_io_readPorts_14_ren) rc_armed[16] = 1'b1;
      if (rc_io_readPorts_15_ren) rc_armed[17] = 1'b1;
      if (rc_io_readPorts_16_ren) rc_armed[18] = 1'b1;
      if (rc_io_readPorts_17_ren) rc_armed[19] = 1'b1;
      if (rc_io_readPorts_18_ren) rc_armed[20] = 1'b1;
      if (rc_io_readPorts_19_ren) rc_armed[21] = 1'b1;
      if (rc_io_readPorts_20_ren) rc_armed[22] = 1'b1;
      if (rc_io_readPorts_21_ren) rc_armed[23] = 1'b1;
      if (rc_io_readPorts_22_ren) rc_armed[24] = 1'b1;
      if (rc_armed_at < 0 && (&rc_armed)) rc_armed_at = cyc + 1 + 1;
    end

    // ---- 覆盖闸 ----
    if (!(rc_s0_io_readPorts_0_data[0] && rc_s1_io_readPorts_0_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[1] && rc_s1_io_readPorts_0_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[2] && rc_s1_io_readPorts_0_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[3] && rc_s1_io_readPorts_0_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[4] && rc_s1_io_readPorts_0_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[5] && rc_s1_io_readPorts_0_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[6] && rc_s1_io_readPorts_0_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[7] && rc_s1_io_readPorts_0_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[8] && rc_s1_io_readPorts_0_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[9] && rc_s1_io_readPorts_0_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[10] && rc_s1_io_readPorts_0_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[11] && rc_s1_io_readPorts_0_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[12] && rc_s1_io_readPorts_0_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[13] && rc_s1_io_readPorts_0_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[14] && rc_s1_io_readPorts_0_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[15] && rc_s1_io_readPorts_0_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[16] && rc_s1_io_readPorts_0_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[17] && rc_s1_io_readPorts_0_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[18] && rc_s1_io_readPorts_0_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[19] && rc_s1_io_readPorts_0_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[20] && rc_s1_io_readPorts_0_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[21] && rc_s1_io_readPorts_0_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[22] && rc_s1_io_readPorts_0_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[23] && rc_s1_io_readPorts_0_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[24] && rc_s1_io_readPorts_0_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[25] && rc_s1_io_readPorts_0_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[26] && rc_s1_io_readPorts_0_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[27] && rc_s1_io_readPorts_0_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[28] && rc_s1_io_readPorts_0_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[29] && rc_s1_io_readPorts_0_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[30] && rc_s1_io_readPorts_0_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[31] && rc_s1_io_readPorts_0_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[32] && rc_s1_io_readPorts_0_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[33] && rc_s1_io_readPorts_0_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[34] && rc_s1_io_readPorts_0_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[35] && rc_s1_io_readPorts_0_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[36] && rc_s1_io_readPorts_0_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[37] && rc_s1_io_readPorts_0_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[38] && rc_s1_io_readPorts_0_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[39] && rc_s1_io_readPorts_0_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[40] && rc_s1_io_readPorts_0_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[41] && rc_s1_io_readPorts_0_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[42] && rc_s1_io_readPorts_0_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[43] && rc_s1_io_readPorts_0_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[44] && rc_s1_io_readPorts_0_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[45] && rc_s1_io_readPorts_0_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[46] && rc_s1_io_readPorts_0_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[47] && rc_s1_io_readPorts_0_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[48] && rc_s1_io_readPorts_0_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[49] && rc_s1_io_readPorts_0_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[50] && rc_s1_io_readPorts_0_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[51] && rc_s1_io_readPorts_0_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[52] && rc_s1_io_readPorts_0_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[53] && rc_s1_io_readPorts_0_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[54] && rc_s1_io_readPorts_0_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[55] && rc_s1_io_readPorts_0_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[56] && rc_s1_io_readPorts_0_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[57] && rc_s1_io_readPorts_0_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[58] && rc_s1_io_readPorts_0_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[59] && rc_s1_io_readPorts_0_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[60] && rc_s1_io_readPorts_0_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[61] && rc_s1_io_readPorts_0_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[62] && rc_s1_io_readPorts_0_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_0_data[63] && rc_s1_io_readPorts_0_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_0_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[0] && rc_s1_io_readPorts_1_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[1] && rc_s1_io_readPorts_1_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[2] && rc_s1_io_readPorts_1_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[3] && rc_s1_io_readPorts_1_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[4] && rc_s1_io_readPorts_1_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[5] && rc_s1_io_readPorts_1_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[6] && rc_s1_io_readPorts_1_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[7] && rc_s1_io_readPorts_1_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[8] && rc_s1_io_readPorts_1_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[9] && rc_s1_io_readPorts_1_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[10] && rc_s1_io_readPorts_1_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[11] && rc_s1_io_readPorts_1_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[12] && rc_s1_io_readPorts_1_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[13] && rc_s1_io_readPorts_1_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[14] && rc_s1_io_readPorts_1_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[15] && rc_s1_io_readPorts_1_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[16] && rc_s1_io_readPorts_1_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[17] && rc_s1_io_readPorts_1_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[18] && rc_s1_io_readPorts_1_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[19] && rc_s1_io_readPorts_1_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[20] && rc_s1_io_readPorts_1_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[21] && rc_s1_io_readPorts_1_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[22] && rc_s1_io_readPorts_1_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[23] && rc_s1_io_readPorts_1_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[24] && rc_s1_io_readPorts_1_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[25] && rc_s1_io_readPorts_1_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[26] && rc_s1_io_readPorts_1_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[27] && rc_s1_io_readPorts_1_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[28] && rc_s1_io_readPorts_1_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[29] && rc_s1_io_readPorts_1_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[30] && rc_s1_io_readPorts_1_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[31] && rc_s1_io_readPorts_1_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[32] && rc_s1_io_readPorts_1_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[33] && rc_s1_io_readPorts_1_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[34] && rc_s1_io_readPorts_1_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[35] && rc_s1_io_readPorts_1_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[36] && rc_s1_io_readPorts_1_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[37] && rc_s1_io_readPorts_1_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[38] && rc_s1_io_readPorts_1_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[39] && rc_s1_io_readPorts_1_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[40] && rc_s1_io_readPorts_1_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[41] && rc_s1_io_readPorts_1_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[42] && rc_s1_io_readPorts_1_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[43] && rc_s1_io_readPorts_1_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[44] && rc_s1_io_readPorts_1_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[45] && rc_s1_io_readPorts_1_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[46] && rc_s1_io_readPorts_1_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[47] && rc_s1_io_readPorts_1_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[48] && rc_s1_io_readPorts_1_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[49] && rc_s1_io_readPorts_1_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[50] && rc_s1_io_readPorts_1_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[51] && rc_s1_io_readPorts_1_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[52] && rc_s1_io_readPorts_1_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[53] && rc_s1_io_readPorts_1_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[54] && rc_s1_io_readPorts_1_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[55] && rc_s1_io_readPorts_1_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[56] && rc_s1_io_readPorts_1_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[57] && rc_s1_io_readPorts_1_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[58] && rc_s1_io_readPorts_1_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[59] && rc_s1_io_readPorts_1_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[60] && rc_s1_io_readPorts_1_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[61] && rc_s1_io_readPorts_1_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[62] && rc_s1_io_readPorts_1_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_1_data[63] && rc_s1_io_readPorts_1_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_1_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[0] && rc_s1_io_readPorts_2_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[1] && rc_s1_io_readPorts_2_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[2] && rc_s1_io_readPorts_2_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[3] && rc_s1_io_readPorts_2_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[4] && rc_s1_io_readPorts_2_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[5] && rc_s1_io_readPorts_2_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[6] && rc_s1_io_readPorts_2_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[7] && rc_s1_io_readPorts_2_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[8] && rc_s1_io_readPorts_2_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[9] && rc_s1_io_readPorts_2_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[10] && rc_s1_io_readPorts_2_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[11] && rc_s1_io_readPorts_2_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[12] && rc_s1_io_readPorts_2_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[13] && rc_s1_io_readPorts_2_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[14] && rc_s1_io_readPorts_2_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[15] && rc_s1_io_readPorts_2_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[16] && rc_s1_io_readPorts_2_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[17] && rc_s1_io_readPorts_2_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[18] && rc_s1_io_readPorts_2_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[19] && rc_s1_io_readPorts_2_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[20] && rc_s1_io_readPorts_2_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[21] && rc_s1_io_readPorts_2_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[22] && rc_s1_io_readPorts_2_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[23] && rc_s1_io_readPorts_2_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[24] && rc_s1_io_readPorts_2_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[25] && rc_s1_io_readPorts_2_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[26] && rc_s1_io_readPorts_2_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[27] && rc_s1_io_readPorts_2_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[28] && rc_s1_io_readPorts_2_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[29] && rc_s1_io_readPorts_2_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[30] && rc_s1_io_readPorts_2_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[31] && rc_s1_io_readPorts_2_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[32] && rc_s1_io_readPorts_2_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[33] && rc_s1_io_readPorts_2_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[34] && rc_s1_io_readPorts_2_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[35] && rc_s1_io_readPorts_2_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[36] && rc_s1_io_readPorts_2_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[37] && rc_s1_io_readPorts_2_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[38] && rc_s1_io_readPorts_2_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[39] && rc_s1_io_readPorts_2_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[40] && rc_s1_io_readPorts_2_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[41] && rc_s1_io_readPorts_2_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[42] && rc_s1_io_readPorts_2_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[43] && rc_s1_io_readPorts_2_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[44] && rc_s1_io_readPorts_2_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[45] && rc_s1_io_readPorts_2_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[46] && rc_s1_io_readPorts_2_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[47] && rc_s1_io_readPorts_2_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[48] && rc_s1_io_readPorts_2_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[49] && rc_s1_io_readPorts_2_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[50] && rc_s1_io_readPorts_2_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[51] && rc_s1_io_readPorts_2_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[52] && rc_s1_io_readPorts_2_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[53] && rc_s1_io_readPorts_2_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[54] && rc_s1_io_readPorts_2_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[55] && rc_s1_io_readPorts_2_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[56] && rc_s1_io_readPorts_2_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[57] && rc_s1_io_readPorts_2_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[58] && rc_s1_io_readPorts_2_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[59] && rc_s1_io_readPorts_2_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[60] && rc_s1_io_readPorts_2_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[61] && rc_s1_io_readPorts_2_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[62] && rc_s1_io_readPorts_2_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_2_data[63] && rc_s1_io_readPorts_2_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_2_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[0] && rc_s1_io_readPorts_3_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[1] && rc_s1_io_readPorts_3_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[2] && rc_s1_io_readPorts_3_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[3] && rc_s1_io_readPorts_3_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[4] && rc_s1_io_readPorts_3_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[5] && rc_s1_io_readPorts_3_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[6] && rc_s1_io_readPorts_3_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[7] && rc_s1_io_readPorts_3_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[8] && rc_s1_io_readPorts_3_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[9] && rc_s1_io_readPorts_3_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[10] && rc_s1_io_readPorts_3_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[11] && rc_s1_io_readPorts_3_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[12] && rc_s1_io_readPorts_3_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[13] && rc_s1_io_readPorts_3_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[14] && rc_s1_io_readPorts_3_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[15] && rc_s1_io_readPorts_3_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[16] && rc_s1_io_readPorts_3_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[17] && rc_s1_io_readPorts_3_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[18] && rc_s1_io_readPorts_3_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[19] && rc_s1_io_readPorts_3_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[20] && rc_s1_io_readPorts_3_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[21] && rc_s1_io_readPorts_3_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[22] && rc_s1_io_readPorts_3_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[23] && rc_s1_io_readPorts_3_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[24] && rc_s1_io_readPorts_3_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[25] && rc_s1_io_readPorts_3_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[26] && rc_s1_io_readPorts_3_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[27] && rc_s1_io_readPorts_3_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[28] && rc_s1_io_readPorts_3_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[29] && rc_s1_io_readPorts_3_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[30] && rc_s1_io_readPorts_3_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[31] && rc_s1_io_readPorts_3_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[32] && rc_s1_io_readPorts_3_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[33] && rc_s1_io_readPorts_3_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[34] && rc_s1_io_readPorts_3_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[35] && rc_s1_io_readPorts_3_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[36] && rc_s1_io_readPorts_3_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[37] && rc_s1_io_readPorts_3_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[38] && rc_s1_io_readPorts_3_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[39] && rc_s1_io_readPorts_3_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[40] && rc_s1_io_readPorts_3_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[41] && rc_s1_io_readPorts_3_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[42] && rc_s1_io_readPorts_3_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[43] && rc_s1_io_readPorts_3_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[44] && rc_s1_io_readPorts_3_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[45] && rc_s1_io_readPorts_3_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[46] && rc_s1_io_readPorts_3_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[47] && rc_s1_io_readPorts_3_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[48] && rc_s1_io_readPorts_3_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[49] && rc_s1_io_readPorts_3_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[50] && rc_s1_io_readPorts_3_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[51] && rc_s1_io_readPorts_3_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[52] && rc_s1_io_readPorts_3_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[53] && rc_s1_io_readPorts_3_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[54] && rc_s1_io_readPorts_3_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[55] && rc_s1_io_readPorts_3_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[56] && rc_s1_io_readPorts_3_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[57] && rc_s1_io_readPorts_3_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[58] && rc_s1_io_readPorts_3_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[59] && rc_s1_io_readPorts_3_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[60] && rc_s1_io_readPorts_3_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[61] && rc_s1_io_readPorts_3_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[62] && rc_s1_io_readPorts_3_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_3_data[63] && rc_s1_io_readPorts_3_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_3_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[0] && rc_s1_io_readPorts_4_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[1] && rc_s1_io_readPorts_4_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[2] && rc_s1_io_readPorts_4_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[3] && rc_s1_io_readPorts_4_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[4] && rc_s1_io_readPorts_4_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[5] && rc_s1_io_readPorts_4_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[6] && rc_s1_io_readPorts_4_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[7] && rc_s1_io_readPorts_4_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[8] && rc_s1_io_readPorts_4_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[9] && rc_s1_io_readPorts_4_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[10] && rc_s1_io_readPorts_4_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[11] && rc_s1_io_readPorts_4_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[12] && rc_s1_io_readPorts_4_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[13] && rc_s1_io_readPorts_4_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[14] && rc_s1_io_readPorts_4_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[15] && rc_s1_io_readPorts_4_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[16] && rc_s1_io_readPorts_4_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[17] && rc_s1_io_readPorts_4_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[18] && rc_s1_io_readPorts_4_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[19] && rc_s1_io_readPorts_4_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[20] && rc_s1_io_readPorts_4_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[21] && rc_s1_io_readPorts_4_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[22] && rc_s1_io_readPorts_4_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[23] && rc_s1_io_readPorts_4_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[24] && rc_s1_io_readPorts_4_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[25] && rc_s1_io_readPorts_4_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[26] && rc_s1_io_readPorts_4_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[27] && rc_s1_io_readPorts_4_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[28] && rc_s1_io_readPorts_4_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[29] && rc_s1_io_readPorts_4_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[30] && rc_s1_io_readPorts_4_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[31] && rc_s1_io_readPorts_4_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[32] && rc_s1_io_readPorts_4_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[33] && rc_s1_io_readPorts_4_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[34] && rc_s1_io_readPorts_4_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[35] && rc_s1_io_readPorts_4_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[36] && rc_s1_io_readPorts_4_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[37] && rc_s1_io_readPorts_4_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[38] && rc_s1_io_readPorts_4_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[39] && rc_s1_io_readPorts_4_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[40] && rc_s1_io_readPorts_4_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[41] && rc_s1_io_readPorts_4_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[42] && rc_s1_io_readPorts_4_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[43] && rc_s1_io_readPorts_4_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[44] && rc_s1_io_readPorts_4_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[45] && rc_s1_io_readPorts_4_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[46] && rc_s1_io_readPorts_4_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[47] && rc_s1_io_readPorts_4_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[48] && rc_s1_io_readPorts_4_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[49] && rc_s1_io_readPorts_4_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[50] && rc_s1_io_readPorts_4_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[51] && rc_s1_io_readPorts_4_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[52] && rc_s1_io_readPorts_4_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[53] && rc_s1_io_readPorts_4_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[54] && rc_s1_io_readPorts_4_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[55] && rc_s1_io_readPorts_4_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[56] && rc_s1_io_readPorts_4_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[57] && rc_s1_io_readPorts_4_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[58] && rc_s1_io_readPorts_4_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[59] && rc_s1_io_readPorts_4_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[60] && rc_s1_io_readPorts_4_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[61] && rc_s1_io_readPorts_4_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[62] && rc_s1_io_readPorts_4_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_4_data[63] && rc_s1_io_readPorts_4_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_4_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[0] && rc_s1_io_readPorts_5_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[1] && rc_s1_io_readPorts_5_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[2] && rc_s1_io_readPorts_5_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[3] && rc_s1_io_readPorts_5_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[4] && rc_s1_io_readPorts_5_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[5] && rc_s1_io_readPorts_5_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[6] && rc_s1_io_readPorts_5_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[7] && rc_s1_io_readPorts_5_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[8] && rc_s1_io_readPorts_5_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[9] && rc_s1_io_readPorts_5_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[10] && rc_s1_io_readPorts_5_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[11] && rc_s1_io_readPorts_5_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[12] && rc_s1_io_readPorts_5_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[13] && rc_s1_io_readPorts_5_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[14] && rc_s1_io_readPorts_5_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[15] && rc_s1_io_readPorts_5_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[16] && rc_s1_io_readPorts_5_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[17] && rc_s1_io_readPorts_5_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[18] && rc_s1_io_readPorts_5_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[19] && rc_s1_io_readPorts_5_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[20] && rc_s1_io_readPorts_5_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[21] && rc_s1_io_readPorts_5_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[22] && rc_s1_io_readPorts_5_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[23] && rc_s1_io_readPorts_5_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[24] && rc_s1_io_readPorts_5_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[25] && rc_s1_io_readPorts_5_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[26] && rc_s1_io_readPorts_5_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[27] && rc_s1_io_readPorts_5_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[28] && rc_s1_io_readPorts_5_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[29] && rc_s1_io_readPorts_5_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[30] && rc_s1_io_readPorts_5_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[31] && rc_s1_io_readPorts_5_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[32] && rc_s1_io_readPorts_5_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[33] && rc_s1_io_readPorts_5_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[34] && rc_s1_io_readPorts_5_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[35] && rc_s1_io_readPorts_5_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[36] && rc_s1_io_readPorts_5_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[37] && rc_s1_io_readPorts_5_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[38] && rc_s1_io_readPorts_5_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[39] && rc_s1_io_readPorts_5_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[40] && rc_s1_io_readPorts_5_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[41] && rc_s1_io_readPorts_5_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[42] && rc_s1_io_readPorts_5_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[43] && rc_s1_io_readPorts_5_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[44] && rc_s1_io_readPorts_5_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[45] && rc_s1_io_readPorts_5_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[46] && rc_s1_io_readPorts_5_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[47] && rc_s1_io_readPorts_5_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[48] && rc_s1_io_readPorts_5_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[49] && rc_s1_io_readPorts_5_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[50] && rc_s1_io_readPorts_5_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[51] && rc_s1_io_readPorts_5_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[52] && rc_s1_io_readPorts_5_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[53] && rc_s1_io_readPorts_5_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[54] && rc_s1_io_readPorts_5_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[55] && rc_s1_io_readPorts_5_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[56] && rc_s1_io_readPorts_5_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[57] && rc_s1_io_readPorts_5_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[58] && rc_s1_io_readPorts_5_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[59] && rc_s1_io_readPorts_5_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[60] && rc_s1_io_readPorts_5_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[61] && rc_s1_io_readPorts_5_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[62] && rc_s1_io_readPorts_5_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_5_data[63] && rc_s1_io_readPorts_5_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_5_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[0] && rc_s1_io_readPorts_6_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[1] && rc_s1_io_readPorts_6_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[2] && rc_s1_io_readPorts_6_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[3] && rc_s1_io_readPorts_6_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[4] && rc_s1_io_readPorts_6_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[5] && rc_s1_io_readPorts_6_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[6] && rc_s1_io_readPorts_6_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[7] && rc_s1_io_readPorts_6_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[8] && rc_s1_io_readPorts_6_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[9] && rc_s1_io_readPorts_6_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[10] && rc_s1_io_readPorts_6_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[11] && rc_s1_io_readPorts_6_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[12] && rc_s1_io_readPorts_6_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[13] && rc_s1_io_readPorts_6_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[14] && rc_s1_io_readPorts_6_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[15] && rc_s1_io_readPorts_6_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[16] && rc_s1_io_readPorts_6_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[17] && rc_s1_io_readPorts_6_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[18] && rc_s1_io_readPorts_6_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[19] && rc_s1_io_readPorts_6_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[20] && rc_s1_io_readPorts_6_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[21] && rc_s1_io_readPorts_6_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[22] && rc_s1_io_readPorts_6_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[23] && rc_s1_io_readPorts_6_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[24] && rc_s1_io_readPorts_6_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[25] && rc_s1_io_readPorts_6_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[26] && rc_s1_io_readPorts_6_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[27] && rc_s1_io_readPorts_6_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[28] && rc_s1_io_readPorts_6_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[29] && rc_s1_io_readPorts_6_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[30] && rc_s1_io_readPorts_6_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[31] && rc_s1_io_readPorts_6_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[32] && rc_s1_io_readPorts_6_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[33] && rc_s1_io_readPorts_6_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[34] && rc_s1_io_readPorts_6_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[35] && rc_s1_io_readPorts_6_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[36] && rc_s1_io_readPorts_6_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[37] && rc_s1_io_readPorts_6_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[38] && rc_s1_io_readPorts_6_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[39] && rc_s1_io_readPorts_6_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[40] && rc_s1_io_readPorts_6_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[41] && rc_s1_io_readPorts_6_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[42] && rc_s1_io_readPorts_6_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[43] && rc_s1_io_readPorts_6_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[44] && rc_s1_io_readPorts_6_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[45] && rc_s1_io_readPorts_6_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[46] && rc_s1_io_readPorts_6_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[47] && rc_s1_io_readPorts_6_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[48] && rc_s1_io_readPorts_6_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[49] && rc_s1_io_readPorts_6_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[50] && rc_s1_io_readPorts_6_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[51] && rc_s1_io_readPorts_6_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[52] && rc_s1_io_readPorts_6_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[53] && rc_s1_io_readPorts_6_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[54] && rc_s1_io_readPorts_6_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[55] && rc_s1_io_readPorts_6_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[56] && rc_s1_io_readPorts_6_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[57] && rc_s1_io_readPorts_6_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[58] && rc_s1_io_readPorts_6_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[59] && rc_s1_io_readPorts_6_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[60] && rc_s1_io_readPorts_6_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[61] && rc_s1_io_readPorts_6_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[62] && rc_s1_io_readPorts_6_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_6_data[63] && rc_s1_io_readPorts_6_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_6_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[0] && rc_s1_io_readPorts_7_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[1] && rc_s1_io_readPorts_7_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[2] && rc_s1_io_readPorts_7_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[3] && rc_s1_io_readPorts_7_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[4] && rc_s1_io_readPorts_7_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[5] && rc_s1_io_readPorts_7_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[6] && rc_s1_io_readPorts_7_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[7] && rc_s1_io_readPorts_7_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[8] && rc_s1_io_readPorts_7_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[9] && rc_s1_io_readPorts_7_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[10] && rc_s1_io_readPorts_7_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[11] && rc_s1_io_readPorts_7_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[12] && rc_s1_io_readPorts_7_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[13] && rc_s1_io_readPorts_7_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[14] && rc_s1_io_readPorts_7_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[15] && rc_s1_io_readPorts_7_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[16] && rc_s1_io_readPorts_7_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[17] && rc_s1_io_readPorts_7_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[18] && rc_s1_io_readPorts_7_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[19] && rc_s1_io_readPorts_7_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[20] && rc_s1_io_readPorts_7_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[21] && rc_s1_io_readPorts_7_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[22] && rc_s1_io_readPorts_7_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[23] && rc_s1_io_readPorts_7_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[24] && rc_s1_io_readPorts_7_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[25] && rc_s1_io_readPorts_7_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[26] && rc_s1_io_readPorts_7_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[27] && rc_s1_io_readPorts_7_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[28] && rc_s1_io_readPorts_7_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[29] && rc_s1_io_readPorts_7_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[30] && rc_s1_io_readPorts_7_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[31] && rc_s1_io_readPorts_7_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[32] && rc_s1_io_readPorts_7_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[33] && rc_s1_io_readPorts_7_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[34] && rc_s1_io_readPorts_7_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[35] && rc_s1_io_readPorts_7_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[36] && rc_s1_io_readPorts_7_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[37] && rc_s1_io_readPorts_7_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[38] && rc_s1_io_readPorts_7_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[39] && rc_s1_io_readPorts_7_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[40] && rc_s1_io_readPorts_7_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[41] && rc_s1_io_readPorts_7_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[42] && rc_s1_io_readPorts_7_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[43] && rc_s1_io_readPorts_7_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[44] && rc_s1_io_readPorts_7_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[45] && rc_s1_io_readPorts_7_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[46] && rc_s1_io_readPorts_7_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[47] && rc_s1_io_readPorts_7_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[48] && rc_s1_io_readPorts_7_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[49] && rc_s1_io_readPorts_7_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[50] && rc_s1_io_readPorts_7_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[51] && rc_s1_io_readPorts_7_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[52] && rc_s1_io_readPorts_7_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[53] && rc_s1_io_readPorts_7_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[54] && rc_s1_io_readPorts_7_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[55] && rc_s1_io_readPorts_7_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[56] && rc_s1_io_readPorts_7_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[57] && rc_s1_io_readPorts_7_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[58] && rc_s1_io_readPorts_7_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[59] && rc_s1_io_readPorts_7_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[60] && rc_s1_io_readPorts_7_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[61] && rc_s1_io_readPorts_7_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[62] && rc_s1_io_readPorts_7_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_7_data[63] && rc_s1_io_readPorts_7_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_7_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[0] && rc_s1_io_readPorts_8_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[1] && rc_s1_io_readPorts_8_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[2] && rc_s1_io_readPorts_8_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[3] && rc_s1_io_readPorts_8_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[4] && rc_s1_io_readPorts_8_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[5] && rc_s1_io_readPorts_8_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[6] && rc_s1_io_readPorts_8_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[7] && rc_s1_io_readPorts_8_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[8] && rc_s1_io_readPorts_8_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[9] && rc_s1_io_readPorts_8_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[10] && rc_s1_io_readPorts_8_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[11] && rc_s1_io_readPorts_8_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[12] && rc_s1_io_readPorts_8_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[13] && rc_s1_io_readPorts_8_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[14] && rc_s1_io_readPorts_8_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[15] && rc_s1_io_readPorts_8_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[16] && rc_s1_io_readPorts_8_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[17] && rc_s1_io_readPorts_8_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[18] && rc_s1_io_readPorts_8_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[19] && rc_s1_io_readPorts_8_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[20] && rc_s1_io_readPorts_8_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[21] && rc_s1_io_readPorts_8_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[22] && rc_s1_io_readPorts_8_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[23] && rc_s1_io_readPorts_8_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[24] && rc_s1_io_readPorts_8_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[25] && rc_s1_io_readPorts_8_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[26] && rc_s1_io_readPorts_8_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[27] && rc_s1_io_readPorts_8_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[28] && rc_s1_io_readPorts_8_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[29] && rc_s1_io_readPorts_8_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[30] && rc_s1_io_readPorts_8_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[31] && rc_s1_io_readPorts_8_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[32] && rc_s1_io_readPorts_8_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[33] && rc_s1_io_readPorts_8_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[34] && rc_s1_io_readPorts_8_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[35] && rc_s1_io_readPorts_8_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[36] && rc_s1_io_readPorts_8_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[37] && rc_s1_io_readPorts_8_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[38] && rc_s1_io_readPorts_8_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[39] && rc_s1_io_readPorts_8_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[40] && rc_s1_io_readPorts_8_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[41] && rc_s1_io_readPorts_8_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[42] && rc_s1_io_readPorts_8_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[43] && rc_s1_io_readPorts_8_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[44] && rc_s1_io_readPorts_8_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[45] && rc_s1_io_readPorts_8_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[46] && rc_s1_io_readPorts_8_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[47] && rc_s1_io_readPorts_8_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[48] && rc_s1_io_readPorts_8_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[49] && rc_s1_io_readPorts_8_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[50] && rc_s1_io_readPorts_8_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[51] && rc_s1_io_readPorts_8_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[52] && rc_s1_io_readPorts_8_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[53] && rc_s1_io_readPorts_8_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[54] && rc_s1_io_readPorts_8_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[55] && rc_s1_io_readPorts_8_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[56] && rc_s1_io_readPorts_8_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[57] && rc_s1_io_readPorts_8_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[58] && rc_s1_io_readPorts_8_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[59] && rc_s1_io_readPorts_8_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[60] && rc_s1_io_readPorts_8_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[61] && rc_s1_io_readPorts_8_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[62] && rc_s1_io_readPorts_8_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_8_data[63] && rc_s1_io_readPorts_8_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_8_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[0] && rc_s1_io_readPorts_9_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[1] && rc_s1_io_readPorts_9_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[2] && rc_s1_io_readPorts_9_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[3] && rc_s1_io_readPorts_9_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[4] && rc_s1_io_readPorts_9_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[5] && rc_s1_io_readPorts_9_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[6] && rc_s1_io_readPorts_9_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[7] && rc_s1_io_readPorts_9_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[8] && rc_s1_io_readPorts_9_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[9] && rc_s1_io_readPorts_9_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[10] && rc_s1_io_readPorts_9_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[11] && rc_s1_io_readPorts_9_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[12] && rc_s1_io_readPorts_9_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[13] && rc_s1_io_readPorts_9_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[14] && rc_s1_io_readPorts_9_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[15] && rc_s1_io_readPorts_9_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[16] && rc_s1_io_readPorts_9_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[17] && rc_s1_io_readPorts_9_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[18] && rc_s1_io_readPorts_9_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[19] && rc_s1_io_readPorts_9_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[20] && rc_s1_io_readPorts_9_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[21] && rc_s1_io_readPorts_9_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[22] && rc_s1_io_readPorts_9_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[23] && rc_s1_io_readPorts_9_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[24] && rc_s1_io_readPorts_9_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[25] && rc_s1_io_readPorts_9_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[26] && rc_s1_io_readPorts_9_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[27] && rc_s1_io_readPorts_9_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[28] && rc_s1_io_readPorts_9_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[29] && rc_s1_io_readPorts_9_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[30] && rc_s1_io_readPorts_9_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[31] && rc_s1_io_readPorts_9_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[32] && rc_s1_io_readPorts_9_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[33] && rc_s1_io_readPorts_9_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[34] && rc_s1_io_readPorts_9_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[35] && rc_s1_io_readPorts_9_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[36] && rc_s1_io_readPorts_9_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[37] && rc_s1_io_readPorts_9_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[38] && rc_s1_io_readPorts_9_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[39] && rc_s1_io_readPorts_9_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[40] && rc_s1_io_readPorts_9_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[41] && rc_s1_io_readPorts_9_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[42] && rc_s1_io_readPorts_9_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[43] && rc_s1_io_readPorts_9_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[44] && rc_s1_io_readPorts_9_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[45] && rc_s1_io_readPorts_9_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[46] && rc_s1_io_readPorts_9_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[47] && rc_s1_io_readPorts_9_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[48] && rc_s1_io_readPorts_9_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[49] && rc_s1_io_readPorts_9_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[50] && rc_s1_io_readPorts_9_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[51] && rc_s1_io_readPorts_9_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[52] && rc_s1_io_readPorts_9_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[53] && rc_s1_io_readPorts_9_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[54] && rc_s1_io_readPorts_9_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[55] && rc_s1_io_readPorts_9_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[56] && rc_s1_io_readPorts_9_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[57] && rc_s1_io_readPorts_9_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[58] && rc_s1_io_readPorts_9_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[59] && rc_s1_io_readPorts_9_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[60] && rc_s1_io_readPorts_9_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[61] && rc_s1_io_readPorts_9_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[62] && rc_s1_io_readPorts_9_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_9_data[63] && rc_s1_io_readPorts_9_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_9_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[0] && rc_s1_io_readPorts_10_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[1] && rc_s1_io_readPorts_10_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[2] && rc_s1_io_readPorts_10_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[3] && rc_s1_io_readPorts_10_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[4] && rc_s1_io_readPorts_10_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[5] && rc_s1_io_readPorts_10_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[6] && rc_s1_io_readPorts_10_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[7] && rc_s1_io_readPorts_10_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[8] && rc_s1_io_readPorts_10_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[9] && rc_s1_io_readPorts_10_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[10] && rc_s1_io_readPorts_10_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[11] && rc_s1_io_readPorts_10_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[12] && rc_s1_io_readPorts_10_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[13] && rc_s1_io_readPorts_10_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[14] && rc_s1_io_readPorts_10_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[15] && rc_s1_io_readPorts_10_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[16] && rc_s1_io_readPorts_10_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[17] && rc_s1_io_readPorts_10_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[18] && rc_s1_io_readPorts_10_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[19] && rc_s1_io_readPorts_10_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[20] && rc_s1_io_readPorts_10_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[21] && rc_s1_io_readPorts_10_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[22] && rc_s1_io_readPorts_10_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[23] && rc_s1_io_readPorts_10_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[24] && rc_s1_io_readPorts_10_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[25] && rc_s1_io_readPorts_10_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[26] && rc_s1_io_readPorts_10_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[27] && rc_s1_io_readPorts_10_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[28] && rc_s1_io_readPorts_10_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[29] && rc_s1_io_readPorts_10_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[30] && rc_s1_io_readPorts_10_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[31] && rc_s1_io_readPorts_10_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[32] && rc_s1_io_readPorts_10_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[33] && rc_s1_io_readPorts_10_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[34] && rc_s1_io_readPorts_10_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[35] && rc_s1_io_readPorts_10_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[36] && rc_s1_io_readPorts_10_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[37] && rc_s1_io_readPorts_10_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[38] && rc_s1_io_readPorts_10_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[39] && rc_s1_io_readPorts_10_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[40] && rc_s1_io_readPorts_10_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[41] && rc_s1_io_readPorts_10_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[42] && rc_s1_io_readPorts_10_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[43] && rc_s1_io_readPorts_10_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[44] && rc_s1_io_readPorts_10_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[45] && rc_s1_io_readPorts_10_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[46] && rc_s1_io_readPorts_10_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[47] && rc_s1_io_readPorts_10_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[48] && rc_s1_io_readPorts_10_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[49] && rc_s1_io_readPorts_10_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[50] && rc_s1_io_readPorts_10_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[51] && rc_s1_io_readPorts_10_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[52] && rc_s1_io_readPorts_10_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[53] && rc_s1_io_readPorts_10_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[54] && rc_s1_io_readPorts_10_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[55] && rc_s1_io_readPorts_10_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[56] && rc_s1_io_readPorts_10_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[57] && rc_s1_io_readPorts_10_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[58] && rc_s1_io_readPorts_10_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[59] && rc_s1_io_readPorts_10_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[60] && rc_s1_io_readPorts_10_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[61] && rc_s1_io_readPorts_10_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[62] && rc_s1_io_readPorts_10_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_10_data[63] && rc_s1_io_readPorts_10_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_10_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[0] && rc_s1_io_readPorts_11_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[1] && rc_s1_io_readPorts_11_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[2] && rc_s1_io_readPorts_11_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[3] && rc_s1_io_readPorts_11_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[4] && rc_s1_io_readPorts_11_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[5] && rc_s1_io_readPorts_11_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[6] && rc_s1_io_readPorts_11_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[7] && rc_s1_io_readPorts_11_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[8] && rc_s1_io_readPorts_11_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[9] && rc_s1_io_readPorts_11_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[10] && rc_s1_io_readPorts_11_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[11] && rc_s1_io_readPorts_11_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[12] && rc_s1_io_readPorts_11_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[13] && rc_s1_io_readPorts_11_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[14] && rc_s1_io_readPorts_11_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[15] && rc_s1_io_readPorts_11_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[16] && rc_s1_io_readPorts_11_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[17] && rc_s1_io_readPorts_11_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[18] && rc_s1_io_readPorts_11_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[19] && rc_s1_io_readPorts_11_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[20] && rc_s1_io_readPorts_11_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[21] && rc_s1_io_readPorts_11_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[22] && rc_s1_io_readPorts_11_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[23] && rc_s1_io_readPorts_11_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[24] && rc_s1_io_readPorts_11_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[25] && rc_s1_io_readPorts_11_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[26] && rc_s1_io_readPorts_11_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[27] && rc_s1_io_readPorts_11_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[28] && rc_s1_io_readPorts_11_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[29] && rc_s1_io_readPorts_11_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[30] && rc_s1_io_readPorts_11_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[31] && rc_s1_io_readPorts_11_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[32] && rc_s1_io_readPorts_11_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[33] && rc_s1_io_readPorts_11_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[34] && rc_s1_io_readPorts_11_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[35] && rc_s1_io_readPorts_11_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[36] && rc_s1_io_readPorts_11_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[37] && rc_s1_io_readPorts_11_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[38] && rc_s1_io_readPorts_11_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[39] && rc_s1_io_readPorts_11_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[40] && rc_s1_io_readPorts_11_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[41] && rc_s1_io_readPorts_11_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[42] && rc_s1_io_readPorts_11_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[43] && rc_s1_io_readPorts_11_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[44] && rc_s1_io_readPorts_11_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[45] && rc_s1_io_readPorts_11_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[46] && rc_s1_io_readPorts_11_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[47] && rc_s1_io_readPorts_11_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[48] && rc_s1_io_readPorts_11_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[49] && rc_s1_io_readPorts_11_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[50] && rc_s1_io_readPorts_11_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[51] && rc_s1_io_readPorts_11_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[52] && rc_s1_io_readPorts_11_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[53] && rc_s1_io_readPorts_11_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[54] && rc_s1_io_readPorts_11_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[55] && rc_s1_io_readPorts_11_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[56] && rc_s1_io_readPorts_11_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[57] && rc_s1_io_readPorts_11_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[58] && rc_s1_io_readPorts_11_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[59] && rc_s1_io_readPorts_11_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[60] && rc_s1_io_readPorts_11_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[61] && rc_s1_io_readPorts_11_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[62] && rc_s1_io_readPorts_11_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_11_data[63] && rc_s1_io_readPorts_11_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_11_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[0] && rc_s1_io_readPorts_12_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[1] && rc_s1_io_readPorts_12_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[2] && rc_s1_io_readPorts_12_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[3] && rc_s1_io_readPorts_12_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[4] && rc_s1_io_readPorts_12_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[5] && rc_s1_io_readPorts_12_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[6] && rc_s1_io_readPorts_12_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[7] && rc_s1_io_readPorts_12_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[8] && rc_s1_io_readPorts_12_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[9] && rc_s1_io_readPorts_12_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[10] && rc_s1_io_readPorts_12_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[11] && rc_s1_io_readPorts_12_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[12] && rc_s1_io_readPorts_12_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[13] && rc_s1_io_readPorts_12_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[14] && rc_s1_io_readPorts_12_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[15] && rc_s1_io_readPorts_12_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[16] && rc_s1_io_readPorts_12_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[17] && rc_s1_io_readPorts_12_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[18] && rc_s1_io_readPorts_12_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[19] && rc_s1_io_readPorts_12_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[20] && rc_s1_io_readPorts_12_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[21] && rc_s1_io_readPorts_12_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[22] && rc_s1_io_readPorts_12_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[23] && rc_s1_io_readPorts_12_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[24] && rc_s1_io_readPorts_12_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[25] && rc_s1_io_readPorts_12_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[26] && rc_s1_io_readPorts_12_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[27] && rc_s1_io_readPorts_12_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[28] && rc_s1_io_readPorts_12_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[29] && rc_s1_io_readPorts_12_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[30] && rc_s1_io_readPorts_12_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[31] && rc_s1_io_readPorts_12_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[32] && rc_s1_io_readPorts_12_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[33] && rc_s1_io_readPorts_12_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[34] && rc_s1_io_readPorts_12_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[35] && rc_s1_io_readPorts_12_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[36] && rc_s1_io_readPorts_12_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[37] && rc_s1_io_readPorts_12_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[38] && rc_s1_io_readPorts_12_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[39] && rc_s1_io_readPorts_12_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[40] && rc_s1_io_readPorts_12_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[41] && rc_s1_io_readPorts_12_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[42] && rc_s1_io_readPorts_12_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[43] && rc_s1_io_readPorts_12_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[44] && rc_s1_io_readPorts_12_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[45] && rc_s1_io_readPorts_12_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[46] && rc_s1_io_readPorts_12_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[47] && rc_s1_io_readPorts_12_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[48] && rc_s1_io_readPorts_12_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[49] && rc_s1_io_readPorts_12_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[50] && rc_s1_io_readPorts_12_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[51] && rc_s1_io_readPorts_12_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[52] && rc_s1_io_readPorts_12_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[53] && rc_s1_io_readPorts_12_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[54] && rc_s1_io_readPorts_12_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[55] && rc_s1_io_readPorts_12_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[56] && rc_s1_io_readPorts_12_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[57] && rc_s1_io_readPorts_12_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[58] && rc_s1_io_readPorts_12_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[59] && rc_s1_io_readPorts_12_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[60] && rc_s1_io_readPorts_12_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[61] && rc_s1_io_readPorts_12_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[62] && rc_s1_io_readPorts_12_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_12_data[63] && rc_s1_io_readPorts_12_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_12_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[0] && rc_s1_io_readPorts_13_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[1] && rc_s1_io_readPorts_13_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[2] && rc_s1_io_readPorts_13_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[3] && rc_s1_io_readPorts_13_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[4] && rc_s1_io_readPorts_13_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[5] && rc_s1_io_readPorts_13_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[6] && rc_s1_io_readPorts_13_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[7] && rc_s1_io_readPorts_13_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[8] && rc_s1_io_readPorts_13_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[9] && rc_s1_io_readPorts_13_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[10] && rc_s1_io_readPorts_13_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[11] && rc_s1_io_readPorts_13_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[12] && rc_s1_io_readPorts_13_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[13] && rc_s1_io_readPorts_13_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[14] && rc_s1_io_readPorts_13_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[15] && rc_s1_io_readPorts_13_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[16] && rc_s1_io_readPorts_13_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[17] && rc_s1_io_readPorts_13_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[18] && rc_s1_io_readPorts_13_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[19] && rc_s1_io_readPorts_13_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[20] && rc_s1_io_readPorts_13_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[21] && rc_s1_io_readPorts_13_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[22] && rc_s1_io_readPorts_13_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[23] && rc_s1_io_readPorts_13_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[24] && rc_s1_io_readPorts_13_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[25] && rc_s1_io_readPorts_13_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[26] && rc_s1_io_readPorts_13_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[27] && rc_s1_io_readPorts_13_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[28] && rc_s1_io_readPorts_13_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[29] && rc_s1_io_readPorts_13_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[30] && rc_s1_io_readPorts_13_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[31] && rc_s1_io_readPorts_13_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[32] && rc_s1_io_readPorts_13_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[33] && rc_s1_io_readPorts_13_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[34] && rc_s1_io_readPorts_13_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[35] && rc_s1_io_readPorts_13_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[36] && rc_s1_io_readPorts_13_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[37] && rc_s1_io_readPorts_13_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[38] && rc_s1_io_readPorts_13_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[39] && rc_s1_io_readPorts_13_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[40] && rc_s1_io_readPorts_13_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[41] && rc_s1_io_readPorts_13_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[42] && rc_s1_io_readPorts_13_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[43] && rc_s1_io_readPorts_13_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[44] && rc_s1_io_readPorts_13_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[45] && rc_s1_io_readPorts_13_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[46] && rc_s1_io_readPorts_13_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[47] && rc_s1_io_readPorts_13_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[48] && rc_s1_io_readPorts_13_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[49] && rc_s1_io_readPorts_13_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[50] && rc_s1_io_readPorts_13_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[51] && rc_s1_io_readPorts_13_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[52] && rc_s1_io_readPorts_13_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[53] && rc_s1_io_readPorts_13_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[54] && rc_s1_io_readPorts_13_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[55] && rc_s1_io_readPorts_13_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[56] && rc_s1_io_readPorts_13_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[57] && rc_s1_io_readPorts_13_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[58] && rc_s1_io_readPorts_13_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[59] && rc_s1_io_readPorts_13_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[60] && rc_s1_io_readPorts_13_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[61] && rc_s1_io_readPorts_13_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[62] && rc_s1_io_readPorts_13_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_13_data[63] && rc_s1_io_readPorts_13_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_13_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[0] && rc_s1_io_readPorts_14_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[1] && rc_s1_io_readPorts_14_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[2] && rc_s1_io_readPorts_14_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[3] && rc_s1_io_readPorts_14_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[4] && rc_s1_io_readPorts_14_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[5] && rc_s1_io_readPorts_14_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[6] && rc_s1_io_readPorts_14_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[7] && rc_s1_io_readPorts_14_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[8] && rc_s1_io_readPorts_14_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[9] && rc_s1_io_readPorts_14_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[10] && rc_s1_io_readPorts_14_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[11] && rc_s1_io_readPorts_14_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[12] && rc_s1_io_readPorts_14_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[13] && rc_s1_io_readPorts_14_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[14] && rc_s1_io_readPorts_14_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[15] && rc_s1_io_readPorts_14_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[16] && rc_s1_io_readPorts_14_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[17] && rc_s1_io_readPorts_14_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[18] && rc_s1_io_readPorts_14_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[19] && rc_s1_io_readPorts_14_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[20] && rc_s1_io_readPorts_14_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[21] && rc_s1_io_readPorts_14_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[22] && rc_s1_io_readPorts_14_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[23] && rc_s1_io_readPorts_14_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[24] && rc_s1_io_readPorts_14_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[25] && rc_s1_io_readPorts_14_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[26] && rc_s1_io_readPorts_14_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[27] && rc_s1_io_readPorts_14_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[28] && rc_s1_io_readPorts_14_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[29] && rc_s1_io_readPorts_14_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[30] && rc_s1_io_readPorts_14_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[31] && rc_s1_io_readPorts_14_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[32] && rc_s1_io_readPorts_14_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[33] && rc_s1_io_readPorts_14_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[34] && rc_s1_io_readPorts_14_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[35] && rc_s1_io_readPorts_14_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[36] && rc_s1_io_readPorts_14_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[37] && rc_s1_io_readPorts_14_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[38] && rc_s1_io_readPorts_14_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[39] && rc_s1_io_readPorts_14_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[40] && rc_s1_io_readPorts_14_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[41] && rc_s1_io_readPorts_14_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[42] && rc_s1_io_readPorts_14_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[43] && rc_s1_io_readPorts_14_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[44] && rc_s1_io_readPorts_14_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[45] && rc_s1_io_readPorts_14_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[46] && rc_s1_io_readPorts_14_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[47] && rc_s1_io_readPorts_14_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[48] && rc_s1_io_readPorts_14_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[49] && rc_s1_io_readPorts_14_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[50] && rc_s1_io_readPorts_14_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[51] && rc_s1_io_readPorts_14_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[52] && rc_s1_io_readPorts_14_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[53] && rc_s1_io_readPorts_14_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[54] && rc_s1_io_readPorts_14_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[55] && rc_s1_io_readPorts_14_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[56] && rc_s1_io_readPorts_14_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[57] && rc_s1_io_readPorts_14_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[58] && rc_s1_io_readPorts_14_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[59] && rc_s1_io_readPorts_14_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[60] && rc_s1_io_readPorts_14_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[61] && rc_s1_io_readPorts_14_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[62] && rc_s1_io_readPorts_14_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_14_data[63] && rc_s1_io_readPorts_14_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_14_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[0] && rc_s1_io_readPorts_15_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[1] && rc_s1_io_readPorts_15_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[2] && rc_s1_io_readPorts_15_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[3] && rc_s1_io_readPorts_15_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[4] && rc_s1_io_readPorts_15_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[5] && rc_s1_io_readPorts_15_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[6] && rc_s1_io_readPorts_15_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[7] && rc_s1_io_readPorts_15_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[8] && rc_s1_io_readPorts_15_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[9] && rc_s1_io_readPorts_15_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[10] && rc_s1_io_readPorts_15_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[11] && rc_s1_io_readPorts_15_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[12] && rc_s1_io_readPorts_15_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[13] && rc_s1_io_readPorts_15_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[14] && rc_s1_io_readPorts_15_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[15] && rc_s1_io_readPorts_15_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[16] && rc_s1_io_readPorts_15_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[17] && rc_s1_io_readPorts_15_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[18] && rc_s1_io_readPorts_15_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[19] && rc_s1_io_readPorts_15_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[20] && rc_s1_io_readPorts_15_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[21] && rc_s1_io_readPorts_15_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[22] && rc_s1_io_readPorts_15_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[23] && rc_s1_io_readPorts_15_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[24] && rc_s1_io_readPorts_15_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[25] && rc_s1_io_readPorts_15_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[26] && rc_s1_io_readPorts_15_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[27] && rc_s1_io_readPorts_15_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[28] && rc_s1_io_readPorts_15_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[29] && rc_s1_io_readPorts_15_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[30] && rc_s1_io_readPorts_15_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[31] && rc_s1_io_readPorts_15_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[32] && rc_s1_io_readPorts_15_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[33] && rc_s1_io_readPorts_15_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[34] && rc_s1_io_readPorts_15_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[35] && rc_s1_io_readPorts_15_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[36] && rc_s1_io_readPorts_15_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[37] && rc_s1_io_readPorts_15_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[38] && rc_s1_io_readPorts_15_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[39] && rc_s1_io_readPorts_15_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[40] && rc_s1_io_readPorts_15_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[41] && rc_s1_io_readPorts_15_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[42] && rc_s1_io_readPorts_15_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[43] && rc_s1_io_readPorts_15_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[44] && rc_s1_io_readPorts_15_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[45] && rc_s1_io_readPorts_15_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[46] && rc_s1_io_readPorts_15_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[47] && rc_s1_io_readPorts_15_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[48] && rc_s1_io_readPorts_15_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[49] && rc_s1_io_readPorts_15_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[50] && rc_s1_io_readPorts_15_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[51] && rc_s1_io_readPorts_15_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[52] && rc_s1_io_readPorts_15_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[53] && rc_s1_io_readPorts_15_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[54] && rc_s1_io_readPorts_15_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[55] && rc_s1_io_readPorts_15_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[56] && rc_s1_io_readPorts_15_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[57] && rc_s1_io_readPorts_15_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[58] && rc_s1_io_readPorts_15_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[59] && rc_s1_io_readPorts_15_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[60] && rc_s1_io_readPorts_15_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[61] && rc_s1_io_readPorts_15_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[62] && rc_s1_io_readPorts_15_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_15_data[63] && rc_s1_io_readPorts_15_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_15_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[0] && rc_s1_io_readPorts_16_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[1] && rc_s1_io_readPorts_16_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[2] && rc_s1_io_readPorts_16_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[3] && rc_s1_io_readPorts_16_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[4] && rc_s1_io_readPorts_16_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[5] && rc_s1_io_readPorts_16_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[6] && rc_s1_io_readPorts_16_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[7] && rc_s1_io_readPorts_16_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[8] && rc_s1_io_readPorts_16_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[9] && rc_s1_io_readPorts_16_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[10] && rc_s1_io_readPorts_16_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[11] && rc_s1_io_readPorts_16_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[12] && rc_s1_io_readPorts_16_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[13] && rc_s1_io_readPorts_16_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[14] && rc_s1_io_readPorts_16_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[15] && rc_s1_io_readPorts_16_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[16] && rc_s1_io_readPorts_16_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[17] && rc_s1_io_readPorts_16_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[18] && rc_s1_io_readPorts_16_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[19] && rc_s1_io_readPorts_16_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[20] && rc_s1_io_readPorts_16_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[21] && rc_s1_io_readPorts_16_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[22] && rc_s1_io_readPorts_16_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[23] && rc_s1_io_readPorts_16_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[24] && rc_s1_io_readPorts_16_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[25] && rc_s1_io_readPorts_16_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[26] && rc_s1_io_readPorts_16_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[27] && rc_s1_io_readPorts_16_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[28] && rc_s1_io_readPorts_16_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[29] && rc_s1_io_readPorts_16_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[30] && rc_s1_io_readPorts_16_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[31] && rc_s1_io_readPorts_16_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[32] && rc_s1_io_readPorts_16_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[33] && rc_s1_io_readPorts_16_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[34] && rc_s1_io_readPorts_16_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[35] && rc_s1_io_readPorts_16_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[36] && rc_s1_io_readPorts_16_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[37] && rc_s1_io_readPorts_16_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[38] && rc_s1_io_readPorts_16_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[39] && rc_s1_io_readPorts_16_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[40] && rc_s1_io_readPorts_16_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[41] && rc_s1_io_readPorts_16_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[42] && rc_s1_io_readPorts_16_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[43] && rc_s1_io_readPorts_16_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[44] && rc_s1_io_readPorts_16_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[45] && rc_s1_io_readPorts_16_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[46] && rc_s1_io_readPorts_16_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[47] && rc_s1_io_readPorts_16_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[48] && rc_s1_io_readPorts_16_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[49] && rc_s1_io_readPorts_16_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[50] && rc_s1_io_readPorts_16_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[51] && rc_s1_io_readPorts_16_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[52] && rc_s1_io_readPorts_16_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[53] && rc_s1_io_readPorts_16_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[54] && rc_s1_io_readPorts_16_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[55] && rc_s1_io_readPorts_16_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[56] && rc_s1_io_readPorts_16_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[57] && rc_s1_io_readPorts_16_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[58] && rc_s1_io_readPorts_16_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[59] && rc_s1_io_readPorts_16_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[60] && rc_s1_io_readPorts_16_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[61] && rc_s1_io_readPorts_16_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[62] && rc_s1_io_readPorts_16_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_16_data[63] && rc_s1_io_readPorts_16_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_16_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[0] && rc_s1_io_readPorts_17_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[1] && rc_s1_io_readPorts_17_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[2] && rc_s1_io_readPorts_17_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[3] && rc_s1_io_readPorts_17_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[4] && rc_s1_io_readPorts_17_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[5] && rc_s1_io_readPorts_17_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[6] && rc_s1_io_readPorts_17_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[7] && rc_s1_io_readPorts_17_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[8] && rc_s1_io_readPorts_17_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[9] && rc_s1_io_readPorts_17_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[10] && rc_s1_io_readPorts_17_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[11] && rc_s1_io_readPorts_17_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[12] && rc_s1_io_readPorts_17_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[13] && rc_s1_io_readPorts_17_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[14] && rc_s1_io_readPorts_17_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[15] && rc_s1_io_readPorts_17_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[16] && rc_s1_io_readPorts_17_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[17] && rc_s1_io_readPorts_17_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[18] && rc_s1_io_readPorts_17_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[19] && rc_s1_io_readPorts_17_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[20] && rc_s1_io_readPorts_17_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[21] && rc_s1_io_readPorts_17_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[22] && rc_s1_io_readPorts_17_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[23] && rc_s1_io_readPorts_17_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[24] && rc_s1_io_readPorts_17_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[25] && rc_s1_io_readPorts_17_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[26] && rc_s1_io_readPorts_17_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[27] && rc_s1_io_readPorts_17_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[28] && rc_s1_io_readPorts_17_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[29] && rc_s1_io_readPorts_17_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[30] && rc_s1_io_readPorts_17_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[31] && rc_s1_io_readPorts_17_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[32] && rc_s1_io_readPorts_17_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[33] && rc_s1_io_readPorts_17_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[34] && rc_s1_io_readPorts_17_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[35] && rc_s1_io_readPorts_17_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[36] && rc_s1_io_readPorts_17_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[37] && rc_s1_io_readPorts_17_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[38] && rc_s1_io_readPorts_17_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[39] && rc_s1_io_readPorts_17_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[40] && rc_s1_io_readPorts_17_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[41] && rc_s1_io_readPorts_17_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[42] && rc_s1_io_readPorts_17_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[43] && rc_s1_io_readPorts_17_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[44] && rc_s1_io_readPorts_17_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[45] && rc_s1_io_readPorts_17_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[46] && rc_s1_io_readPorts_17_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[47] && rc_s1_io_readPorts_17_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[48] && rc_s1_io_readPorts_17_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[49] && rc_s1_io_readPorts_17_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[50] && rc_s1_io_readPorts_17_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[51] && rc_s1_io_readPorts_17_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[52] && rc_s1_io_readPorts_17_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[53] && rc_s1_io_readPorts_17_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[54] && rc_s1_io_readPorts_17_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[55] && rc_s1_io_readPorts_17_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[56] && rc_s1_io_readPorts_17_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[57] && rc_s1_io_readPorts_17_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[58] && rc_s1_io_readPorts_17_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[59] && rc_s1_io_readPorts_17_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[60] && rc_s1_io_readPorts_17_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[61] && rc_s1_io_readPorts_17_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[62] && rc_s1_io_readPorts_17_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_17_data[63] && rc_s1_io_readPorts_17_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_17_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[0] && rc_s1_io_readPorts_18_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[1] && rc_s1_io_readPorts_18_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[2] && rc_s1_io_readPorts_18_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[3] && rc_s1_io_readPorts_18_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[4] && rc_s1_io_readPorts_18_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[5] && rc_s1_io_readPorts_18_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[6] && rc_s1_io_readPorts_18_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[7] && rc_s1_io_readPorts_18_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[8] && rc_s1_io_readPorts_18_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[9] && rc_s1_io_readPorts_18_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[10] && rc_s1_io_readPorts_18_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[11] && rc_s1_io_readPorts_18_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[12] && rc_s1_io_readPorts_18_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[13] && rc_s1_io_readPorts_18_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[14] && rc_s1_io_readPorts_18_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[15] && rc_s1_io_readPorts_18_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[16] && rc_s1_io_readPorts_18_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[17] && rc_s1_io_readPorts_18_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[18] && rc_s1_io_readPorts_18_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[19] && rc_s1_io_readPorts_18_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[20] && rc_s1_io_readPorts_18_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[21] && rc_s1_io_readPorts_18_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[22] && rc_s1_io_readPorts_18_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[23] && rc_s1_io_readPorts_18_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[24] && rc_s1_io_readPorts_18_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[25] && rc_s1_io_readPorts_18_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[26] && rc_s1_io_readPorts_18_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[27] && rc_s1_io_readPorts_18_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[28] && rc_s1_io_readPorts_18_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[29] && rc_s1_io_readPorts_18_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[30] && rc_s1_io_readPorts_18_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[31] && rc_s1_io_readPorts_18_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[32] && rc_s1_io_readPorts_18_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[33] && rc_s1_io_readPorts_18_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[34] && rc_s1_io_readPorts_18_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[35] && rc_s1_io_readPorts_18_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[36] && rc_s1_io_readPorts_18_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[37] && rc_s1_io_readPorts_18_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[38] && rc_s1_io_readPorts_18_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[39] && rc_s1_io_readPorts_18_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[40] && rc_s1_io_readPorts_18_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[41] && rc_s1_io_readPorts_18_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[42] && rc_s1_io_readPorts_18_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[43] && rc_s1_io_readPorts_18_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[44] && rc_s1_io_readPorts_18_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[45] && rc_s1_io_readPorts_18_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[46] && rc_s1_io_readPorts_18_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[47] && rc_s1_io_readPorts_18_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[48] && rc_s1_io_readPorts_18_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[49] && rc_s1_io_readPorts_18_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[50] && rc_s1_io_readPorts_18_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[51] && rc_s1_io_readPorts_18_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[52] && rc_s1_io_readPorts_18_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[53] && rc_s1_io_readPorts_18_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[54] && rc_s1_io_readPorts_18_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[55] && rc_s1_io_readPorts_18_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[56] && rc_s1_io_readPorts_18_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[57] && rc_s1_io_readPorts_18_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[58] && rc_s1_io_readPorts_18_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[59] && rc_s1_io_readPorts_18_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[60] && rc_s1_io_readPorts_18_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[61] && rc_s1_io_readPorts_18_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[62] && rc_s1_io_readPorts_18_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_18_data[63] && rc_s1_io_readPorts_18_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_18_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[0] && rc_s1_io_readPorts_19_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[1] && rc_s1_io_readPorts_19_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[2] && rc_s1_io_readPorts_19_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[3] && rc_s1_io_readPorts_19_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[4] && rc_s1_io_readPorts_19_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[5] && rc_s1_io_readPorts_19_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[6] && rc_s1_io_readPorts_19_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[7] && rc_s1_io_readPorts_19_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[8] && rc_s1_io_readPorts_19_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[9] && rc_s1_io_readPorts_19_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[10] && rc_s1_io_readPorts_19_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[11] && rc_s1_io_readPorts_19_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[12] && rc_s1_io_readPorts_19_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[13] && rc_s1_io_readPorts_19_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[14] && rc_s1_io_readPorts_19_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[15] && rc_s1_io_readPorts_19_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[16] && rc_s1_io_readPorts_19_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[17] && rc_s1_io_readPorts_19_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[18] && rc_s1_io_readPorts_19_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[19] && rc_s1_io_readPorts_19_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[20] && rc_s1_io_readPorts_19_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[21] && rc_s1_io_readPorts_19_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[22] && rc_s1_io_readPorts_19_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[23] && rc_s1_io_readPorts_19_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[24] && rc_s1_io_readPorts_19_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[25] && rc_s1_io_readPorts_19_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[26] && rc_s1_io_readPorts_19_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[27] && rc_s1_io_readPorts_19_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[28] && rc_s1_io_readPorts_19_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[29] && rc_s1_io_readPorts_19_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[30] && rc_s1_io_readPorts_19_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[31] && rc_s1_io_readPorts_19_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[32] && rc_s1_io_readPorts_19_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[33] && rc_s1_io_readPorts_19_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[34] && rc_s1_io_readPorts_19_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[35] && rc_s1_io_readPorts_19_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[36] && rc_s1_io_readPorts_19_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[37] && rc_s1_io_readPorts_19_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[38] && rc_s1_io_readPorts_19_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[39] && rc_s1_io_readPorts_19_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[40] && rc_s1_io_readPorts_19_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[41] && rc_s1_io_readPorts_19_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[42] && rc_s1_io_readPorts_19_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[43] && rc_s1_io_readPorts_19_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[44] && rc_s1_io_readPorts_19_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[45] && rc_s1_io_readPorts_19_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[46] && rc_s1_io_readPorts_19_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[47] && rc_s1_io_readPorts_19_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[48] && rc_s1_io_readPorts_19_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[49] && rc_s1_io_readPorts_19_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[50] && rc_s1_io_readPorts_19_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[51] && rc_s1_io_readPorts_19_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[52] && rc_s1_io_readPorts_19_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[53] && rc_s1_io_readPorts_19_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[54] && rc_s1_io_readPorts_19_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[55] && rc_s1_io_readPorts_19_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[56] && rc_s1_io_readPorts_19_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[57] && rc_s1_io_readPorts_19_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[58] && rc_s1_io_readPorts_19_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[59] && rc_s1_io_readPorts_19_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[60] && rc_s1_io_readPorts_19_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[61] && rc_s1_io_readPorts_19_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[62] && rc_s1_io_readPorts_19_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_19_data[63] && rc_s1_io_readPorts_19_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_19_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[0] && rc_s1_io_readPorts_20_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[1] && rc_s1_io_readPorts_20_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[2] && rc_s1_io_readPorts_20_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[3] && rc_s1_io_readPorts_20_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[4] && rc_s1_io_readPorts_20_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[5] && rc_s1_io_readPorts_20_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[6] && rc_s1_io_readPorts_20_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[7] && rc_s1_io_readPorts_20_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[8] && rc_s1_io_readPorts_20_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[9] && rc_s1_io_readPorts_20_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[10] && rc_s1_io_readPorts_20_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[11] && rc_s1_io_readPorts_20_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[12] && rc_s1_io_readPorts_20_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[13] && rc_s1_io_readPorts_20_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[14] && rc_s1_io_readPorts_20_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[15] && rc_s1_io_readPorts_20_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[16] && rc_s1_io_readPorts_20_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[17] && rc_s1_io_readPorts_20_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[18] && rc_s1_io_readPorts_20_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[19] && rc_s1_io_readPorts_20_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[20] && rc_s1_io_readPorts_20_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[21] && rc_s1_io_readPorts_20_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[22] && rc_s1_io_readPorts_20_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[23] && rc_s1_io_readPorts_20_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[24] && rc_s1_io_readPorts_20_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[25] && rc_s1_io_readPorts_20_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[26] && rc_s1_io_readPorts_20_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[27] && rc_s1_io_readPorts_20_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[28] && rc_s1_io_readPorts_20_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[29] && rc_s1_io_readPorts_20_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[30] && rc_s1_io_readPorts_20_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[31] && rc_s1_io_readPorts_20_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[32] && rc_s1_io_readPorts_20_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[33] && rc_s1_io_readPorts_20_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[34] && rc_s1_io_readPorts_20_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[35] && rc_s1_io_readPorts_20_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[36] && rc_s1_io_readPorts_20_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[37] && rc_s1_io_readPorts_20_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[38] && rc_s1_io_readPorts_20_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[39] && rc_s1_io_readPorts_20_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[40] && rc_s1_io_readPorts_20_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[41] && rc_s1_io_readPorts_20_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[42] && rc_s1_io_readPorts_20_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[43] && rc_s1_io_readPorts_20_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[44] && rc_s1_io_readPorts_20_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[45] && rc_s1_io_readPorts_20_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[46] && rc_s1_io_readPorts_20_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[47] && rc_s1_io_readPorts_20_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[48] && rc_s1_io_readPorts_20_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[49] && rc_s1_io_readPorts_20_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[50] && rc_s1_io_readPorts_20_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[51] && rc_s1_io_readPorts_20_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[52] && rc_s1_io_readPorts_20_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[53] && rc_s1_io_readPorts_20_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[54] && rc_s1_io_readPorts_20_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[55] && rc_s1_io_readPorts_20_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[56] && rc_s1_io_readPorts_20_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[57] && rc_s1_io_readPorts_20_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[58] && rc_s1_io_readPorts_20_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[59] && rc_s1_io_readPorts_20_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[60] && rc_s1_io_readPorts_20_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[61] && rc_s1_io_readPorts_20_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[62] && rc_s1_io_readPorts_20_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_20_data[63] && rc_s1_io_readPorts_20_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_20_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[0] && rc_s1_io_readPorts_21_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[1] && rc_s1_io_readPorts_21_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[2] && rc_s1_io_readPorts_21_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[3] && rc_s1_io_readPorts_21_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[4] && rc_s1_io_readPorts_21_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[5] && rc_s1_io_readPorts_21_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[6] && rc_s1_io_readPorts_21_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[7] && rc_s1_io_readPorts_21_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[8] && rc_s1_io_readPorts_21_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[9] && rc_s1_io_readPorts_21_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[10] && rc_s1_io_readPorts_21_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[11] && rc_s1_io_readPorts_21_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[12] && rc_s1_io_readPorts_21_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[13] && rc_s1_io_readPorts_21_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[14] && rc_s1_io_readPorts_21_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[15] && rc_s1_io_readPorts_21_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[16] && rc_s1_io_readPorts_21_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[17] && rc_s1_io_readPorts_21_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[18] && rc_s1_io_readPorts_21_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[19] && rc_s1_io_readPorts_21_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[20] && rc_s1_io_readPorts_21_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[21] && rc_s1_io_readPorts_21_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[22] && rc_s1_io_readPorts_21_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[23] && rc_s1_io_readPorts_21_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[24] && rc_s1_io_readPorts_21_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[25] && rc_s1_io_readPorts_21_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[26] && rc_s1_io_readPorts_21_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[27] && rc_s1_io_readPorts_21_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[28] && rc_s1_io_readPorts_21_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[29] && rc_s1_io_readPorts_21_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[30] && rc_s1_io_readPorts_21_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[31] && rc_s1_io_readPorts_21_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[32] && rc_s1_io_readPorts_21_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[33] && rc_s1_io_readPorts_21_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[34] && rc_s1_io_readPorts_21_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[35] && rc_s1_io_readPorts_21_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[36] && rc_s1_io_readPorts_21_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[37] && rc_s1_io_readPorts_21_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[38] && rc_s1_io_readPorts_21_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[39] && rc_s1_io_readPorts_21_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[40] && rc_s1_io_readPorts_21_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[41] && rc_s1_io_readPorts_21_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[42] && rc_s1_io_readPorts_21_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[43] && rc_s1_io_readPorts_21_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[44] && rc_s1_io_readPorts_21_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[45] && rc_s1_io_readPorts_21_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[46] && rc_s1_io_readPorts_21_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[47] && rc_s1_io_readPorts_21_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[48] && rc_s1_io_readPorts_21_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[49] && rc_s1_io_readPorts_21_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[50] && rc_s1_io_readPorts_21_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[51] && rc_s1_io_readPorts_21_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[52] && rc_s1_io_readPorts_21_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[53] && rc_s1_io_readPorts_21_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[54] && rc_s1_io_readPorts_21_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[55] && rc_s1_io_readPorts_21_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[56] && rc_s1_io_readPorts_21_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[57] && rc_s1_io_readPorts_21_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[58] && rc_s1_io_readPorts_21_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[59] && rc_s1_io_readPorts_21_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[60] && rc_s1_io_readPorts_21_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[61] && rc_s1_io_readPorts_21_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[62] && rc_s1_io_readPorts_21_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_21_data[63] && rc_s1_io_readPorts_21_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_21_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[0] && rc_s1_io_readPorts_22_data[0])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[1] && rc_s1_io_readPorts_22_data[1])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[2] && rc_s1_io_readPorts_22_data[2])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[3] && rc_s1_io_readPorts_22_data[3])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[4] && rc_s1_io_readPorts_22_data[4])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[4] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[5] && rc_s1_io_readPorts_22_data[5])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[5] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[6] && rc_s1_io_readPorts_22_data[6])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[6] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[7] && rc_s1_io_readPorts_22_data[7])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[7] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[8] && rc_s1_io_readPorts_22_data[8])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[8] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[9] && rc_s1_io_readPorts_22_data[9])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[9] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[10] && rc_s1_io_readPorts_22_data[10])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[10] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[11] && rc_s1_io_readPorts_22_data[11])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[11] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[12] && rc_s1_io_readPorts_22_data[12])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[12] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[13] && rc_s1_io_readPorts_22_data[13])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[13] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[14] && rc_s1_io_readPorts_22_data[14])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[14] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[15] && rc_s1_io_readPorts_22_data[15])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[15] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[16] && rc_s1_io_readPorts_22_data[16])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[16] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[17] && rc_s1_io_readPorts_22_data[17])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[17] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[18] && rc_s1_io_readPorts_22_data[18])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[18] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[19] && rc_s1_io_readPorts_22_data[19])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[19] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[20] && rc_s1_io_readPorts_22_data[20])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[20] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[21] && rc_s1_io_readPorts_22_data[21])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[21] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[22] && rc_s1_io_readPorts_22_data[22])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[22] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[23] && rc_s1_io_readPorts_22_data[23])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[23] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[24] && rc_s1_io_readPorts_22_data[24])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[24] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[25] && rc_s1_io_readPorts_22_data[25])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[25] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[26] && rc_s1_io_readPorts_22_data[26])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[26] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[27] && rc_s1_io_readPorts_22_data[27])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[27] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[28] && rc_s1_io_readPorts_22_data[28])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[28] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[29] && rc_s1_io_readPorts_22_data[29])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[29] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[30] && rc_s1_io_readPorts_22_data[30])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[30] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[31] && rc_s1_io_readPorts_22_data[31])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[31] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[32] && rc_s1_io_readPorts_22_data[32])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[32] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[33] && rc_s1_io_readPorts_22_data[33])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[33] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[34] && rc_s1_io_readPorts_22_data[34])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[34] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[35] && rc_s1_io_readPorts_22_data[35])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[35] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[36] && rc_s1_io_readPorts_22_data[36])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[36] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[37] && rc_s1_io_readPorts_22_data[37])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[37] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[38] && rc_s1_io_readPorts_22_data[38])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[38] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[39] && rc_s1_io_readPorts_22_data[39])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[39] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[40] && rc_s1_io_readPorts_22_data[40])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[40] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[41] && rc_s1_io_readPorts_22_data[41])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[41] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[42] && rc_s1_io_readPorts_22_data[42])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[42] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[43] && rc_s1_io_readPorts_22_data[43])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[43] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[44] && rc_s1_io_readPorts_22_data[44])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[44] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[45] && rc_s1_io_readPorts_22_data[45])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[45] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[46] && rc_s1_io_readPorts_22_data[46])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[46] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[47] && rc_s1_io_readPorts_22_data[47])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[47] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[48] && rc_s1_io_readPorts_22_data[48])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[48] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[49] && rc_s1_io_readPorts_22_data[49])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[49] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[50] && rc_s1_io_readPorts_22_data[50])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[50] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[51] && rc_s1_io_readPorts_22_data[51])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[51] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[52] && rc_s1_io_readPorts_22_data[52])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[52] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[53] && rc_s1_io_readPorts_22_data[53])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[53] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[54] && rc_s1_io_readPorts_22_data[54])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[54] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[55] && rc_s1_io_readPorts_22_data[55])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[55] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[56] && rc_s1_io_readPorts_22_data[56])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[56] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[57] && rc_s1_io_readPorts_22_data[57])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[57] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[58] && rc_s1_io_readPorts_22_data[58])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[58] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[59] && rc_s1_io_readPorts_22_data[59])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[59] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[60] && rc_s1_io_readPorts_22_data[60])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[60] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[61] && rc_s1_io_readPorts_22_data[61])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[61] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[62] && rc_s1_io_readPorts_22_data[62])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[62] 未见过 0 和 1"); end
    if (!(rc_s0_io_readPorts_22_data[63] && rc_s1_io_readPorts_22_data[63])) begin cov_fail++; $display("[COV] RegCache.io_readPorts_22_data[63] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_0[0] && rc_s1_io_toWakeupQueueRCIdx_0[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_0[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_0[1] && rc_s1_io_toWakeupQueueRCIdx_0[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_0[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_0[2] && rc_s1_io_toWakeupQueueRCIdx_0[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_0[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_0[3] && rc_s1_io_toWakeupQueueRCIdx_0[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_0[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_1[0] && rc_s1_io_toWakeupQueueRCIdx_1[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_1[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_1[1] && rc_s1_io_toWakeupQueueRCIdx_1[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_1[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_1[2] && rc_s1_io_toWakeupQueueRCIdx_1[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_1[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_1[3] && rc_s1_io_toWakeupQueueRCIdx_1[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_1[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_2[0] && rc_s1_io_toWakeupQueueRCIdx_2[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_2[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_2[1] && rc_s1_io_toWakeupQueueRCIdx_2[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_2[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_2[2] && rc_s1_io_toWakeupQueueRCIdx_2[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_2[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_2[3] && rc_s1_io_toWakeupQueueRCIdx_2[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_2[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_3[0] && rc_s1_io_toWakeupQueueRCIdx_3[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_3[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_3[1] && rc_s1_io_toWakeupQueueRCIdx_3[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_3[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_3[2] && rc_s1_io_toWakeupQueueRCIdx_3[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_3[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_3[3] && rc_s1_io_toWakeupQueueRCIdx_3[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_3[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_4[0] && rc_s1_io_toWakeupQueueRCIdx_4[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_4[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_4[1] && rc_s1_io_toWakeupQueueRCIdx_4[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_4[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_4[2] && rc_s1_io_toWakeupQueueRCIdx_4[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_4[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_4[3] && rc_s1_io_toWakeupQueueRCIdx_4[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_4[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_5[0] && rc_s1_io_toWakeupQueueRCIdx_5[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_5[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_5[1] && rc_s1_io_toWakeupQueueRCIdx_5[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_5[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_5[2] && rc_s1_io_toWakeupQueueRCIdx_5[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_5[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_5[3] && rc_s1_io_toWakeupQueueRCIdx_5[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_5[3] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_6[0] && rc_s1_io_toWakeupQueueRCIdx_6[0])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_6[0] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_6[1] && rc_s1_io_toWakeupQueueRCIdx_6[1])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_6[1] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_6[2] && rc_s1_io_toWakeupQueueRCIdx_6[2])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_6[2] 未见过 0 和 1"); end
    if (!(rc_s0_io_toWakeupQueueRCIdx_6[3] && rc_s1_io_toWakeupQueueRCIdx_6[3])) begin cov_fail++; $display("[COV] RegCache.io_toWakeupQueueRCIdx_6[3] 未见过 0 和 1"); end
    $display("[ARM] RegCache armed_at=%0d", rc_armed_at);
    if (rc_armed_at < 0) begin cov_fail++; $display("[ARM] RegCache 从未 arm"); end
    $display("[COV] RegCache.mem_half_read = %0d", rc_cov_mem_half_read);
    if (rc_cov_mem_half_read < 1000) begin cov_fail++; $display("[COV] RegCache.mem_half_read < 1000"); end
    $display("[COV] RegCache.int_half_read = %0d", rc_cov_int_half_read);
    if (rc_cov_int_half_read < 1000) begin cov_fail++; $display("[COV] RegCache.int_half_read < 1000"); end
    $display("[COV] RegCache.all_int_wen = %0d", rc_cov_all_int_wen);
    if (rc_cov_all_int_wen < 1000) begin cov_fail++; $display("[COV] RegCache.all_int_wen < 1000"); end
    $display("[COV] RegCache.all_mem_wen = %0d", rc_cov_all_mem_wen);
    if (rc_cov_all_mem_wen < 1000) begin cov_fail++; $display("[COV] RegCache.all_mem_wen < 1000"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
