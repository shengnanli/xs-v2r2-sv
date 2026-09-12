// 自动生成：scripts/gen_zj_ut.py RegCache —— 勿手改
// RegCache 双例化逐拍比对：golden RegCache vs 重写 RegCache_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 120000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 120000;
  localparam int unsigned MIN_TOGGLED = 30;
  localparam int unsigned MIN_FIRES   = 0;
  localparam int unsigned N_OUT       = 30;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_readPorts_0_ren;
  logic [4:0] io_readPorts_0_addr;
  logic io_readPorts_1_ren;
  logic [4:0] io_readPorts_1_addr;
  logic io_readPorts_2_ren;
  logic [4:0] io_readPorts_2_addr;
  logic io_readPorts_3_ren;
  logic [4:0] io_readPorts_3_addr;
  logic io_readPorts_4_ren;
  logic [4:0] io_readPorts_4_addr;
  logic io_readPorts_5_ren;
  logic [4:0] io_readPorts_5_addr;
  logic io_readPorts_6_ren;
  logic [4:0] io_readPorts_6_addr;
  logic io_readPorts_7_ren;
  logic [4:0] io_readPorts_7_addr;
  logic io_readPorts_8_ren;
  logic [4:0] io_readPorts_8_addr;
  logic io_readPorts_9_ren;
  logic [4:0] io_readPorts_9_addr;
  logic io_readPorts_10_ren;
  logic [4:0] io_readPorts_10_addr;
  logic io_readPorts_11_ren;
  logic [4:0] io_readPorts_11_addr;
  logic io_readPorts_12_ren;
  logic [4:0] io_readPorts_12_addr;
  logic io_readPorts_13_ren;
  logic [4:0] io_readPorts_13_addr;
  logic io_readPorts_14_ren;
  logic [4:0] io_readPorts_14_addr;
  logic io_readPorts_15_ren;
  logic [4:0] io_readPorts_15_addr;
  logic io_readPorts_16_ren;
  logic [4:0] io_readPorts_16_addr;
  logic io_readPorts_17_ren;
  logic [4:0] io_readPorts_17_addr;
  logic io_readPorts_18_ren;
  logic [4:0] io_readPorts_18_addr;
  logic io_readPorts_19_ren;
  logic [4:0] io_readPorts_19_addr;
  logic io_readPorts_20_ren;
  logic [4:0] io_readPorts_20_addr;
  logic io_readPorts_21_ren;
  logic [4:0] io_readPorts_21_addr;
  logic io_readPorts_22_ren;
  logic [4:0] io_readPorts_22_addr;
  logic io_writePorts_0_wen;
  logic [63:0] io_writePorts_0_data;
  logic io_writePorts_1_wen;
  logic [63:0] io_writePorts_1_data;
  logic io_writePorts_2_wen;
  logic [63:0] io_writePorts_2_data;
  logic io_writePorts_3_wen;
  logic [63:0] io_writePorts_3_data;
  logic io_writePorts_4_wen;
  logic [63:0] io_writePorts_4_data;
  logic io_writePorts_5_wen;
  logic [63:0] io_writePorts_5_data;
  logic io_writePorts_6_wen;
  logic [63:0] io_writePorts_6_data;

  wire [63:0] g_io_readPorts_0_data;
  wire [63:0] i_io_readPorts_0_data;
  wire [63:0] g_io_readPorts_1_data;
  wire [63:0] i_io_readPorts_1_data;
  wire [63:0] g_io_readPorts_2_data;
  wire [63:0] i_io_readPorts_2_data;
  wire [63:0] g_io_readPorts_3_data;
  wire [63:0] i_io_readPorts_3_data;
  wire [63:0] g_io_readPorts_4_data;
  wire [63:0] i_io_readPorts_4_data;
  wire [63:0] g_io_readPorts_5_data;
  wire [63:0] i_io_readPorts_5_data;
  wire [63:0] g_io_readPorts_6_data;
  wire [63:0] i_io_readPorts_6_data;
  wire [63:0] g_io_readPorts_7_data;
  wire [63:0] i_io_readPorts_7_data;
  wire [63:0] g_io_readPorts_8_data;
  wire [63:0] i_io_readPorts_8_data;
  wire [63:0] g_io_readPorts_9_data;
  wire [63:0] i_io_readPorts_9_data;
  wire [63:0] g_io_readPorts_10_data;
  wire [63:0] i_io_readPorts_10_data;
  wire [63:0] g_io_readPorts_11_data;
  wire [63:0] i_io_readPorts_11_data;
  wire [63:0] g_io_readPorts_12_data;
  wire [63:0] i_io_readPorts_12_data;
  wire [63:0] g_io_readPorts_13_data;
  wire [63:0] i_io_readPorts_13_data;
  wire [63:0] g_io_readPorts_14_data;
  wire [63:0] i_io_readPorts_14_data;
  wire [63:0] g_io_readPorts_15_data;
  wire [63:0] i_io_readPorts_15_data;
  wire [63:0] g_io_readPorts_16_data;
  wire [63:0] i_io_readPorts_16_data;
  wire [63:0] g_io_readPorts_17_data;
  wire [63:0] i_io_readPorts_17_data;
  wire [63:0] g_io_readPorts_18_data;
  wire [63:0] i_io_readPorts_18_data;
  wire [63:0] g_io_readPorts_19_data;
  wire [63:0] i_io_readPorts_19_data;
  wire [63:0] g_io_readPorts_20_data;
  wire [63:0] i_io_readPorts_20_data;
  wire [63:0] g_io_readPorts_21_data;
  wire [63:0] i_io_readPorts_21_data;
  wire [63:0] g_io_readPorts_22_data;
  wire [63:0] i_io_readPorts_22_data;
  wire [4:0] g_io_toWakeupQueueRCIdx_0;
  wire [4:0] i_io_toWakeupQueueRCIdx_0;
  wire [4:0] g_io_toWakeupQueueRCIdx_1;
  wire [4:0] i_io_toWakeupQueueRCIdx_1;
  wire [4:0] g_io_toWakeupQueueRCIdx_2;
  wire [4:0] i_io_toWakeupQueueRCIdx_2;
  wire [4:0] g_io_toWakeupQueueRCIdx_3;
  wire [4:0] i_io_toWakeupQueueRCIdx_3;
  wire [4:0] g_io_toWakeupQueueRCIdx_4;
  wire [4:0] i_io_toWakeupQueueRCIdx_4;
  wire [4:0] g_io_toWakeupQueueRCIdx_5;
  wire [4:0] i_io_toWakeupQueueRCIdx_5;
  wire [4:0] g_io_toWakeupQueueRCIdx_6;
  wire [4:0] i_io_toWakeupQueueRCIdx_6;

  logic [63:0] p_io_readPorts_0_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_0_data;
  logic [63:0] p_io_readPorts_1_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_1_data;
  logic [63:0] p_io_readPorts_2_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_2_data;
  logic [63:0] p_io_readPorts_3_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_3_data;
  logic [63:0] p_io_readPorts_4_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_4_data;
  logic [63:0] p_io_readPorts_5_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_5_data;
  logic [63:0] p_io_readPorts_6_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_6_data;
  logic [63:0] p_io_readPorts_7_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_7_data;
  logic [63:0] p_io_readPorts_8_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_8_data;
  logic [63:0] p_io_readPorts_9_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_9_data;
  logic [63:0] p_io_readPorts_10_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_10_data;
  logic [63:0] p_io_readPorts_11_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_11_data;
  logic [63:0] p_io_readPorts_12_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_12_data;
  logic [63:0] p_io_readPorts_13_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_13_data;
  logic [63:0] p_io_readPorts_14_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_14_data;
  logic [63:0] p_io_readPorts_15_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_15_data;
  logic [63:0] p_io_readPorts_16_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_16_data;
  logic [63:0] p_io_readPorts_17_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_17_data;
  logic [63:0] p_io_readPorts_18_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_18_data;
  logic [63:0] p_io_readPorts_19_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_19_data;
  logic [63:0] p_io_readPorts_20_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_20_data;
  logic [63:0] p_io_readPorts_21_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_21_data;
  logic [63:0] p_io_readPorts_22_data;   // 上一拍值（toggle 统计）
  bit tog_io_readPorts_22_data;
  logic [4:0] p_io_toWakeupQueueRCIdx_0;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_0;
  logic [4:0] p_io_toWakeupQueueRCIdx_1;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_1;
  logic [4:0] p_io_toWakeupQueueRCIdx_2;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_2;
  logic [4:0] p_io_toWakeupQueueRCIdx_3;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_3;
  logic [4:0] p_io_toWakeupQueueRCIdx_4;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_4;
  logic [4:0] p_io_toWakeupQueueRCIdx_5;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_5;
  logic [4:0] p_io_toWakeupQueueRCIdx_6;   // 上一拍值（toggle 统计）
  bit tog_io_toWakeupQueueRCIdx_6;

  RegCache u_g (
    .clock(clock),
    .reset(reset),
    .io_readPorts_0_ren(io_readPorts_0_ren),
    .io_readPorts_0_addr(io_readPorts_0_addr),
    .io_readPorts_0_data(g_io_readPorts_0_data),
    .io_readPorts_1_ren(io_readPorts_1_ren),
    .io_readPorts_1_addr(io_readPorts_1_addr),
    .io_readPorts_1_data(g_io_readPorts_1_data),
    .io_readPorts_2_ren(io_readPorts_2_ren),
    .io_readPorts_2_addr(io_readPorts_2_addr),
    .io_readPorts_2_data(g_io_readPorts_2_data),
    .io_readPorts_3_ren(io_readPorts_3_ren),
    .io_readPorts_3_addr(io_readPorts_3_addr),
    .io_readPorts_3_data(g_io_readPorts_3_data),
    .io_readPorts_4_ren(io_readPorts_4_ren),
    .io_readPorts_4_addr(io_readPorts_4_addr),
    .io_readPorts_4_data(g_io_readPorts_4_data),
    .io_readPorts_5_ren(io_readPorts_5_ren),
    .io_readPorts_5_addr(io_readPorts_5_addr),
    .io_readPorts_5_data(g_io_readPorts_5_data),
    .io_readPorts_6_ren(io_readPorts_6_ren),
    .io_readPorts_6_addr(io_readPorts_6_addr),
    .io_readPorts_6_data(g_io_readPorts_6_data),
    .io_readPorts_7_ren(io_readPorts_7_ren),
    .io_readPorts_7_addr(io_readPorts_7_addr),
    .io_readPorts_7_data(g_io_readPorts_7_data),
    .io_readPorts_8_ren(io_readPorts_8_ren),
    .io_readPorts_8_addr(io_readPorts_8_addr),
    .io_readPorts_8_data(g_io_readPorts_8_data),
    .io_readPorts_9_ren(io_readPorts_9_ren),
    .io_readPorts_9_addr(io_readPorts_9_addr),
    .io_readPorts_9_data(g_io_readPorts_9_data),
    .io_readPorts_10_ren(io_readPorts_10_ren),
    .io_readPorts_10_addr(io_readPorts_10_addr),
    .io_readPorts_10_data(g_io_readPorts_10_data),
    .io_readPorts_11_ren(io_readPorts_11_ren),
    .io_readPorts_11_addr(io_readPorts_11_addr),
    .io_readPorts_11_data(g_io_readPorts_11_data),
    .io_readPorts_12_ren(io_readPorts_12_ren),
    .io_readPorts_12_addr(io_readPorts_12_addr),
    .io_readPorts_12_data(g_io_readPorts_12_data),
    .io_readPorts_13_ren(io_readPorts_13_ren),
    .io_readPorts_13_addr(io_readPorts_13_addr),
    .io_readPorts_13_data(g_io_readPorts_13_data),
    .io_readPorts_14_ren(io_readPorts_14_ren),
    .io_readPorts_14_addr(io_readPorts_14_addr),
    .io_readPorts_14_data(g_io_readPorts_14_data),
    .io_readPorts_15_ren(io_readPorts_15_ren),
    .io_readPorts_15_addr(io_readPorts_15_addr),
    .io_readPorts_15_data(g_io_readPorts_15_data),
    .io_readPorts_16_ren(io_readPorts_16_ren),
    .io_readPorts_16_addr(io_readPorts_16_addr),
    .io_readPorts_16_data(g_io_readPorts_16_data),
    .io_readPorts_17_ren(io_readPorts_17_ren),
    .io_readPorts_17_addr(io_readPorts_17_addr),
    .io_readPorts_17_data(g_io_readPorts_17_data),
    .io_readPorts_18_ren(io_readPorts_18_ren),
    .io_readPorts_18_addr(io_readPorts_18_addr),
    .io_readPorts_18_data(g_io_readPorts_18_data),
    .io_readPorts_19_ren(io_readPorts_19_ren),
    .io_readPorts_19_addr(io_readPorts_19_addr),
    .io_readPorts_19_data(g_io_readPorts_19_data),
    .io_readPorts_20_ren(io_readPorts_20_ren),
    .io_readPorts_20_addr(io_readPorts_20_addr),
    .io_readPorts_20_data(g_io_readPorts_20_data),
    .io_readPorts_21_ren(io_readPorts_21_ren),
    .io_readPorts_21_addr(io_readPorts_21_addr),
    .io_readPorts_21_data(g_io_readPorts_21_data),
    .io_readPorts_22_ren(io_readPorts_22_ren),
    .io_readPorts_22_addr(io_readPorts_22_addr),
    .io_readPorts_22_data(g_io_readPorts_22_data),
    .io_writePorts_0_wen(io_writePorts_0_wen),
    .io_writePorts_0_data(io_writePorts_0_data),
    .io_writePorts_1_wen(io_writePorts_1_wen),
    .io_writePorts_1_data(io_writePorts_1_data),
    .io_writePorts_2_wen(io_writePorts_2_wen),
    .io_writePorts_2_data(io_writePorts_2_data),
    .io_writePorts_3_wen(io_writePorts_3_wen),
    .io_writePorts_3_data(io_writePorts_3_data),
    .io_writePorts_4_wen(io_writePorts_4_wen),
    .io_writePorts_4_data(io_writePorts_4_data),
    .io_writePorts_5_wen(io_writePorts_5_wen),
    .io_writePorts_5_data(io_writePorts_5_data),
    .io_writePorts_6_wen(io_writePorts_6_wen),
    .io_writePorts_6_data(io_writePorts_6_data),
    .io_toWakeupQueueRCIdx_0(g_io_toWakeupQueueRCIdx_0),
    .io_toWakeupQueueRCIdx_1(g_io_toWakeupQueueRCIdx_1),
    .io_toWakeupQueueRCIdx_2(g_io_toWakeupQueueRCIdx_2),
    .io_toWakeupQueueRCIdx_3(g_io_toWakeupQueueRCIdx_3),
    .io_toWakeupQueueRCIdx_4(g_io_toWakeupQueueRCIdx_4),
    .io_toWakeupQueueRCIdx_5(g_io_toWakeupQueueRCIdx_5),
    .io_toWakeupQueueRCIdx_6(g_io_toWakeupQueueRCIdx_6)
  );
  RegCache_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_readPorts_0_ren(io_readPorts_0_ren),
    .io_readPorts_0_addr(io_readPorts_0_addr),
    .io_readPorts_0_data(i_io_readPorts_0_data),
    .io_readPorts_1_ren(io_readPorts_1_ren),
    .io_readPorts_1_addr(io_readPorts_1_addr),
    .io_readPorts_1_data(i_io_readPorts_1_data),
    .io_readPorts_2_ren(io_readPorts_2_ren),
    .io_readPorts_2_addr(io_readPorts_2_addr),
    .io_readPorts_2_data(i_io_readPorts_2_data),
    .io_readPorts_3_ren(io_readPorts_3_ren),
    .io_readPorts_3_addr(io_readPorts_3_addr),
    .io_readPorts_3_data(i_io_readPorts_3_data),
    .io_readPorts_4_ren(io_readPorts_4_ren),
    .io_readPorts_4_addr(io_readPorts_4_addr),
    .io_readPorts_4_data(i_io_readPorts_4_data),
    .io_readPorts_5_ren(io_readPorts_5_ren),
    .io_readPorts_5_addr(io_readPorts_5_addr),
    .io_readPorts_5_data(i_io_readPorts_5_data),
    .io_readPorts_6_ren(io_readPorts_6_ren),
    .io_readPorts_6_addr(io_readPorts_6_addr),
    .io_readPorts_6_data(i_io_readPorts_6_data),
    .io_readPorts_7_ren(io_readPorts_7_ren),
    .io_readPorts_7_addr(io_readPorts_7_addr),
    .io_readPorts_7_data(i_io_readPorts_7_data),
    .io_readPorts_8_ren(io_readPorts_8_ren),
    .io_readPorts_8_addr(io_readPorts_8_addr),
    .io_readPorts_8_data(i_io_readPorts_8_data),
    .io_readPorts_9_ren(io_readPorts_9_ren),
    .io_readPorts_9_addr(io_readPorts_9_addr),
    .io_readPorts_9_data(i_io_readPorts_9_data),
    .io_readPorts_10_ren(io_readPorts_10_ren),
    .io_readPorts_10_addr(io_readPorts_10_addr),
    .io_readPorts_10_data(i_io_readPorts_10_data),
    .io_readPorts_11_ren(io_readPorts_11_ren),
    .io_readPorts_11_addr(io_readPorts_11_addr),
    .io_readPorts_11_data(i_io_readPorts_11_data),
    .io_readPorts_12_ren(io_readPorts_12_ren),
    .io_readPorts_12_addr(io_readPorts_12_addr),
    .io_readPorts_12_data(i_io_readPorts_12_data),
    .io_readPorts_13_ren(io_readPorts_13_ren),
    .io_readPorts_13_addr(io_readPorts_13_addr),
    .io_readPorts_13_data(i_io_readPorts_13_data),
    .io_readPorts_14_ren(io_readPorts_14_ren),
    .io_readPorts_14_addr(io_readPorts_14_addr),
    .io_readPorts_14_data(i_io_readPorts_14_data),
    .io_readPorts_15_ren(io_readPorts_15_ren),
    .io_readPorts_15_addr(io_readPorts_15_addr),
    .io_readPorts_15_data(i_io_readPorts_15_data),
    .io_readPorts_16_ren(io_readPorts_16_ren),
    .io_readPorts_16_addr(io_readPorts_16_addr),
    .io_readPorts_16_data(i_io_readPorts_16_data),
    .io_readPorts_17_ren(io_readPorts_17_ren),
    .io_readPorts_17_addr(io_readPorts_17_addr),
    .io_readPorts_17_data(i_io_readPorts_17_data),
    .io_readPorts_18_ren(io_readPorts_18_ren),
    .io_readPorts_18_addr(io_readPorts_18_addr),
    .io_readPorts_18_data(i_io_readPorts_18_data),
    .io_readPorts_19_ren(io_readPorts_19_ren),
    .io_readPorts_19_addr(io_readPorts_19_addr),
    .io_readPorts_19_data(i_io_readPorts_19_data),
    .io_readPorts_20_ren(io_readPorts_20_ren),
    .io_readPorts_20_addr(io_readPorts_20_addr),
    .io_readPorts_20_data(i_io_readPorts_20_data),
    .io_readPorts_21_ren(io_readPorts_21_ren),
    .io_readPorts_21_addr(io_readPorts_21_addr),
    .io_readPorts_21_data(i_io_readPorts_21_data),
    .io_readPorts_22_ren(io_readPorts_22_ren),
    .io_readPorts_22_addr(io_readPorts_22_addr),
    .io_readPorts_22_data(i_io_readPorts_22_data),
    .io_writePorts_0_wen(io_writePorts_0_wen),
    .io_writePorts_0_data(io_writePorts_0_data),
    .io_writePorts_1_wen(io_writePorts_1_wen),
    .io_writePorts_1_data(io_writePorts_1_data),
    .io_writePorts_2_wen(io_writePorts_2_wen),
    .io_writePorts_2_data(io_writePorts_2_data),
    .io_writePorts_3_wen(io_writePorts_3_wen),
    .io_writePorts_3_data(io_writePorts_3_data),
    .io_writePorts_4_wen(io_writePorts_4_wen),
    .io_writePorts_4_data(io_writePorts_4_data),
    .io_writePorts_5_wen(io_writePorts_5_wen),
    .io_writePorts_5_data(io_writePorts_5_data),
    .io_writePorts_6_wen(io_writePorts_6_wen),
    .io_writePorts_6_data(io_writePorts_6_data),
    .io_toWakeupQueueRCIdx_0(i_io_toWakeupQueueRCIdx_0),
    .io_toWakeupQueueRCIdx_1(i_io_toWakeupQueueRCIdx_1),
    .io_toWakeupQueueRCIdx_2(i_io_toWakeupQueueRCIdx_2),
    .io_toWakeupQueueRCIdx_3(i_io_toWakeupQueueRCIdx_3),
    .io_toWakeupQueueRCIdx_4(i_io_toWakeupQueueRCIdx_4),
    .io_toWakeupQueueRCIdx_5(i_io_toWakeupQueueRCIdx_5),
    .io_toWakeupQueueRCIdx_6(i_io_toWakeupQueueRCIdx_6)
  );

  task automatic drive_random();
    io_readPorts_0_ren = $urandom % 2;
    io_readPorts_0_addr = rnd(5);
    io_readPorts_1_ren = $urandom % 2;
    io_readPorts_1_addr = rnd(5);
    io_readPorts_2_ren = $urandom % 2;
    io_readPorts_2_addr = rnd(5);
    io_readPorts_3_ren = $urandom % 2;
    io_readPorts_3_addr = rnd(5);
    io_readPorts_4_ren = $urandom % 2;
    io_readPorts_4_addr = rnd(5);
    io_readPorts_5_ren = $urandom % 2;
    io_readPorts_5_addr = rnd(5);
    io_readPorts_6_ren = $urandom % 2;
    io_readPorts_6_addr = rnd(5);
    io_readPorts_7_ren = $urandom % 2;
    io_readPorts_7_addr = rnd(5);
    io_readPorts_8_ren = $urandom % 2;
    io_readPorts_8_addr = rnd(5);
    io_readPorts_9_ren = $urandom % 2;
    io_readPorts_9_addr = rnd(5);
    io_readPorts_10_ren = $urandom % 2;
    io_readPorts_10_addr = rnd(5);
    io_readPorts_11_ren = $urandom % 2;
    io_readPorts_11_addr = rnd(5);
    io_readPorts_12_ren = $urandom % 2;
    io_readPorts_12_addr = rnd(5);
    io_readPorts_13_ren = $urandom % 2;
    io_readPorts_13_addr = rnd(5);
    io_readPorts_14_ren = $urandom % 2;
    io_readPorts_14_addr = rnd(5);
    io_readPorts_15_ren = $urandom % 2;
    io_readPorts_15_addr = rnd(5);
    io_readPorts_16_ren = $urandom % 2;
    io_readPorts_16_addr = rnd(5);
    io_readPorts_17_ren = $urandom % 2;
    io_readPorts_17_addr = rnd(5);
    io_readPorts_18_ren = $urandom % 2;
    io_readPorts_18_addr = rnd(5);
    io_readPorts_19_ren = $urandom % 2;
    io_readPorts_19_addr = rnd(5);
    io_readPorts_20_ren = $urandom % 2;
    io_readPorts_20_addr = rnd(5);
    io_readPorts_21_ren = $urandom % 2;
    io_readPorts_21_addr = rnd(5);
    io_readPorts_22_ren = $urandom % 2;
    io_readPorts_22_addr = rnd(5);
    io_writePorts_0_wen = $urandom % 2;
    io_writePorts_0_data = rnd(64);
    io_writePorts_1_wen = $urandom % 2;
    io_writePorts_1_data = rnd(64);
    io_writePorts_2_wen = $urandom % 2;
    io_writePorts_2_data = rnd(64);
    io_writePorts_3_wen = $urandom % 2;
    io_writePorts_3_data = rnd(64);
    io_writePorts_4_wen = $urandom % 2;
    io_writePorts_4_data = rnd(64);
    io_writePorts_5_wen = $urandom % 2;
    io_writePorts_5_data = rnd(64);
    io_writePorts_6_wen = $urandom % 2;
    io_writePorts_6_data = rnd(64);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_readPorts_0_data)) begin
      checks++;
      if (g_io_readPorts_0_data !== i_io_readPorts_0_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_0_data g=%0h i=%0h", $time, g_io_readPorts_0_data, i_io_readPorts_0_data);
      end
    end
    if (!$isunknown(g_io_readPorts_1_data)) begin
      checks++;
      if (g_io_readPorts_1_data !== i_io_readPorts_1_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_1_data g=%0h i=%0h", $time, g_io_readPorts_1_data, i_io_readPorts_1_data);
      end
    end
    if (!$isunknown(g_io_readPorts_2_data)) begin
      checks++;
      if (g_io_readPorts_2_data !== i_io_readPorts_2_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_2_data g=%0h i=%0h", $time, g_io_readPorts_2_data, i_io_readPorts_2_data);
      end
    end
    if (!$isunknown(g_io_readPorts_3_data)) begin
      checks++;
      if (g_io_readPorts_3_data !== i_io_readPorts_3_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_3_data g=%0h i=%0h", $time, g_io_readPorts_3_data, i_io_readPorts_3_data);
      end
    end
    if (!$isunknown(g_io_readPorts_4_data)) begin
      checks++;
      if (g_io_readPorts_4_data !== i_io_readPorts_4_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_4_data g=%0h i=%0h", $time, g_io_readPorts_4_data, i_io_readPorts_4_data);
      end
    end
    if (!$isunknown(g_io_readPorts_5_data)) begin
      checks++;
      if (g_io_readPorts_5_data !== i_io_readPorts_5_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_5_data g=%0h i=%0h", $time, g_io_readPorts_5_data, i_io_readPorts_5_data);
      end
    end
    if (!$isunknown(g_io_readPorts_6_data)) begin
      checks++;
      if (g_io_readPorts_6_data !== i_io_readPorts_6_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_6_data g=%0h i=%0h", $time, g_io_readPorts_6_data, i_io_readPorts_6_data);
      end
    end
    if (!$isunknown(g_io_readPorts_7_data)) begin
      checks++;
      if (g_io_readPorts_7_data !== i_io_readPorts_7_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_7_data g=%0h i=%0h", $time, g_io_readPorts_7_data, i_io_readPorts_7_data);
      end
    end
    if (!$isunknown(g_io_readPorts_8_data)) begin
      checks++;
      if (g_io_readPorts_8_data !== i_io_readPorts_8_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_8_data g=%0h i=%0h", $time, g_io_readPorts_8_data, i_io_readPorts_8_data);
      end
    end
    if (!$isunknown(g_io_readPorts_9_data)) begin
      checks++;
      if (g_io_readPorts_9_data !== i_io_readPorts_9_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_9_data g=%0h i=%0h", $time, g_io_readPorts_9_data, i_io_readPorts_9_data);
      end
    end
    if (!$isunknown(g_io_readPorts_10_data)) begin
      checks++;
      if (g_io_readPorts_10_data !== i_io_readPorts_10_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_10_data g=%0h i=%0h", $time, g_io_readPorts_10_data, i_io_readPorts_10_data);
      end
    end
    if (!$isunknown(g_io_readPorts_11_data)) begin
      checks++;
      if (g_io_readPorts_11_data !== i_io_readPorts_11_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_11_data g=%0h i=%0h", $time, g_io_readPorts_11_data, i_io_readPorts_11_data);
      end
    end
    if (!$isunknown(g_io_readPorts_12_data)) begin
      checks++;
      if (g_io_readPorts_12_data !== i_io_readPorts_12_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_12_data g=%0h i=%0h", $time, g_io_readPorts_12_data, i_io_readPorts_12_data);
      end
    end
    if (!$isunknown(g_io_readPorts_13_data)) begin
      checks++;
      if (g_io_readPorts_13_data !== i_io_readPorts_13_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_13_data g=%0h i=%0h", $time, g_io_readPorts_13_data, i_io_readPorts_13_data);
      end
    end
    if (!$isunknown(g_io_readPorts_14_data)) begin
      checks++;
      if (g_io_readPorts_14_data !== i_io_readPorts_14_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_14_data g=%0h i=%0h", $time, g_io_readPorts_14_data, i_io_readPorts_14_data);
      end
    end
    if (!$isunknown(g_io_readPorts_15_data)) begin
      checks++;
      if (g_io_readPorts_15_data !== i_io_readPorts_15_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_15_data g=%0h i=%0h", $time, g_io_readPorts_15_data, i_io_readPorts_15_data);
      end
    end
    if (!$isunknown(g_io_readPorts_16_data)) begin
      checks++;
      if (g_io_readPorts_16_data !== i_io_readPorts_16_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_16_data g=%0h i=%0h", $time, g_io_readPorts_16_data, i_io_readPorts_16_data);
      end
    end
    if (!$isunknown(g_io_readPorts_17_data)) begin
      checks++;
      if (g_io_readPorts_17_data !== i_io_readPorts_17_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_17_data g=%0h i=%0h", $time, g_io_readPorts_17_data, i_io_readPorts_17_data);
      end
    end
    if (!$isunknown(g_io_readPorts_18_data)) begin
      checks++;
      if (g_io_readPorts_18_data !== i_io_readPorts_18_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_18_data g=%0h i=%0h", $time, g_io_readPorts_18_data, i_io_readPorts_18_data);
      end
    end
    if (!$isunknown(g_io_readPorts_19_data)) begin
      checks++;
      if (g_io_readPorts_19_data !== i_io_readPorts_19_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_19_data g=%0h i=%0h", $time, g_io_readPorts_19_data, i_io_readPorts_19_data);
      end
    end
    if (!$isunknown(g_io_readPorts_20_data)) begin
      checks++;
      if (g_io_readPorts_20_data !== i_io_readPorts_20_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_20_data g=%0h i=%0h", $time, g_io_readPorts_20_data, i_io_readPorts_20_data);
      end
    end
    if (!$isunknown(g_io_readPorts_21_data)) begin
      checks++;
      if (g_io_readPorts_21_data !== i_io_readPorts_21_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_21_data g=%0h i=%0h", $time, g_io_readPorts_21_data, i_io_readPorts_21_data);
      end
    end
    if (!$isunknown(g_io_readPorts_22_data)) begin
      checks++;
      if (g_io_readPorts_22_data !== i_io_readPorts_22_data) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_readPorts_22_data g=%0h i=%0h", $time, g_io_readPorts_22_data, i_io_readPorts_22_data);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_0)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_0 !== i_io_toWakeupQueueRCIdx_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_0 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_0, i_io_toWakeupQueueRCIdx_0);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_1)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_1 !== i_io_toWakeupQueueRCIdx_1) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_1 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_1, i_io_toWakeupQueueRCIdx_1);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_2)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_2 !== i_io_toWakeupQueueRCIdx_2) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_2 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_2, i_io_toWakeupQueueRCIdx_2);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_3)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_3 !== i_io_toWakeupQueueRCIdx_3) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_3 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_3, i_io_toWakeupQueueRCIdx_3);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_4)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_4 !== i_io_toWakeupQueueRCIdx_4) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_4 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_4, i_io_toWakeupQueueRCIdx_4);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_5)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_5 !== i_io_toWakeupQueueRCIdx_5) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_5 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_5, i_io_toWakeupQueueRCIdx_5);
      end
    end
    if (!$isunknown(g_io_toWakeupQueueRCIdx_6)) begin
      checks++;
      if (g_io_toWakeupQueueRCIdx_6 !== i_io_toWakeupQueueRCIdx_6) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_toWakeupQueueRCIdx_6 g=%0h i=%0h", $time, g_io_toWakeupQueueRCIdx_6, i_io_toWakeupQueueRCIdx_6);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_readPorts_0_data !== p_io_readPorts_0_data) tog_io_readPorts_0_data = 1'b1;
    p_io_readPorts_0_data = g_io_readPorts_0_data;
    if (g_io_readPorts_1_data !== p_io_readPorts_1_data) tog_io_readPorts_1_data = 1'b1;
    p_io_readPorts_1_data = g_io_readPorts_1_data;
    if (g_io_readPorts_2_data !== p_io_readPorts_2_data) tog_io_readPorts_2_data = 1'b1;
    p_io_readPorts_2_data = g_io_readPorts_2_data;
    if (g_io_readPorts_3_data !== p_io_readPorts_3_data) tog_io_readPorts_3_data = 1'b1;
    p_io_readPorts_3_data = g_io_readPorts_3_data;
    if (g_io_readPorts_4_data !== p_io_readPorts_4_data) tog_io_readPorts_4_data = 1'b1;
    p_io_readPorts_4_data = g_io_readPorts_4_data;
    if (g_io_readPorts_5_data !== p_io_readPorts_5_data) tog_io_readPorts_5_data = 1'b1;
    p_io_readPorts_5_data = g_io_readPorts_5_data;
    if (g_io_readPorts_6_data !== p_io_readPorts_6_data) tog_io_readPorts_6_data = 1'b1;
    p_io_readPorts_6_data = g_io_readPorts_6_data;
    if (g_io_readPorts_7_data !== p_io_readPorts_7_data) tog_io_readPorts_7_data = 1'b1;
    p_io_readPorts_7_data = g_io_readPorts_7_data;
    if (g_io_readPorts_8_data !== p_io_readPorts_8_data) tog_io_readPorts_8_data = 1'b1;
    p_io_readPorts_8_data = g_io_readPorts_8_data;
    if (g_io_readPorts_9_data !== p_io_readPorts_9_data) tog_io_readPorts_9_data = 1'b1;
    p_io_readPorts_9_data = g_io_readPorts_9_data;
    if (g_io_readPorts_10_data !== p_io_readPorts_10_data) tog_io_readPorts_10_data = 1'b1;
    p_io_readPorts_10_data = g_io_readPorts_10_data;
    if (g_io_readPorts_11_data !== p_io_readPorts_11_data) tog_io_readPorts_11_data = 1'b1;
    p_io_readPorts_11_data = g_io_readPorts_11_data;
    if (g_io_readPorts_12_data !== p_io_readPorts_12_data) tog_io_readPorts_12_data = 1'b1;
    p_io_readPorts_12_data = g_io_readPorts_12_data;
    if (g_io_readPorts_13_data !== p_io_readPorts_13_data) tog_io_readPorts_13_data = 1'b1;
    p_io_readPorts_13_data = g_io_readPorts_13_data;
    if (g_io_readPorts_14_data !== p_io_readPorts_14_data) tog_io_readPorts_14_data = 1'b1;
    p_io_readPorts_14_data = g_io_readPorts_14_data;
    if (g_io_readPorts_15_data !== p_io_readPorts_15_data) tog_io_readPorts_15_data = 1'b1;
    p_io_readPorts_15_data = g_io_readPorts_15_data;
    if (g_io_readPorts_16_data !== p_io_readPorts_16_data) tog_io_readPorts_16_data = 1'b1;
    p_io_readPorts_16_data = g_io_readPorts_16_data;
    if (g_io_readPorts_17_data !== p_io_readPorts_17_data) tog_io_readPorts_17_data = 1'b1;
    p_io_readPorts_17_data = g_io_readPorts_17_data;
    if (g_io_readPorts_18_data !== p_io_readPorts_18_data) tog_io_readPorts_18_data = 1'b1;
    p_io_readPorts_18_data = g_io_readPorts_18_data;
    if (g_io_readPorts_19_data !== p_io_readPorts_19_data) tog_io_readPorts_19_data = 1'b1;
    p_io_readPorts_19_data = g_io_readPorts_19_data;
    if (g_io_readPorts_20_data !== p_io_readPorts_20_data) tog_io_readPorts_20_data = 1'b1;
    p_io_readPorts_20_data = g_io_readPorts_20_data;
    if (g_io_readPorts_21_data !== p_io_readPorts_21_data) tog_io_readPorts_21_data = 1'b1;
    p_io_readPorts_21_data = g_io_readPorts_21_data;
    if (g_io_readPorts_22_data !== p_io_readPorts_22_data) tog_io_readPorts_22_data = 1'b1;
    p_io_readPorts_22_data = g_io_readPorts_22_data;
    if (g_io_toWakeupQueueRCIdx_0 !== p_io_toWakeupQueueRCIdx_0) tog_io_toWakeupQueueRCIdx_0 = 1'b1;
    p_io_toWakeupQueueRCIdx_0 = g_io_toWakeupQueueRCIdx_0;
    if (g_io_toWakeupQueueRCIdx_1 !== p_io_toWakeupQueueRCIdx_1) tog_io_toWakeupQueueRCIdx_1 = 1'b1;
    p_io_toWakeupQueueRCIdx_1 = g_io_toWakeupQueueRCIdx_1;
    if (g_io_toWakeupQueueRCIdx_2 !== p_io_toWakeupQueueRCIdx_2) tog_io_toWakeupQueueRCIdx_2 = 1'b1;
    p_io_toWakeupQueueRCIdx_2 = g_io_toWakeupQueueRCIdx_2;
    if (g_io_toWakeupQueueRCIdx_3 !== p_io_toWakeupQueueRCIdx_3) tog_io_toWakeupQueueRCIdx_3 = 1'b1;
    p_io_toWakeupQueueRCIdx_3 = g_io_toWakeupQueueRCIdx_3;
    if (g_io_toWakeupQueueRCIdx_4 !== p_io_toWakeupQueueRCIdx_4) tog_io_toWakeupQueueRCIdx_4 = 1'b1;
    p_io_toWakeupQueueRCIdx_4 = g_io_toWakeupQueueRCIdx_4;
    if (g_io_toWakeupQueueRCIdx_5 !== p_io_toWakeupQueueRCIdx_5) tog_io_toWakeupQueueRCIdx_5 = 1'b1;
    p_io_toWakeupQueueRCIdx_5 = g_io_toWakeupQueueRCIdx_5;
    if (g_io_toWakeupQueueRCIdx_6 !== p_io_toWakeupQueueRCIdx_6) tog_io_toWakeupQueueRCIdx_6 = 1'b1;
    p_io_toWakeupQueueRCIdx_6 = g_io_toWakeupQueueRCIdx_6;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_readPorts_0_ren = '0;
    io_readPorts_0_addr = '0;
    io_readPorts_1_ren = '0;
    io_readPorts_1_addr = '0;
    io_readPorts_2_ren = '0;
    io_readPorts_2_addr = '0;
    io_readPorts_3_ren = '0;
    io_readPorts_3_addr = '0;
    io_readPorts_4_ren = '0;
    io_readPorts_4_addr = '0;
    io_readPorts_5_ren = '0;
    io_readPorts_5_addr = '0;
    io_readPorts_6_ren = '0;
    io_readPorts_6_addr = '0;
    io_readPorts_7_ren = '0;
    io_readPorts_7_addr = '0;
    io_readPorts_8_ren = '0;
    io_readPorts_8_addr = '0;
    io_readPorts_9_ren = '0;
    io_readPorts_9_addr = '0;
    io_readPorts_10_ren = '0;
    io_readPorts_10_addr = '0;
    io_readPorts_11_ren = '0;
    io_readPorts_11_addr = '0;
    io_readPorts_12_ren = '0;
    io_readPorts_12_addr = '0;
    io_readPorts_13_ren = '0;
    io_readPorts_13_addr = '0;
    io_readPorts_14_ren = '0;
    io_readPorts_14_addr = '0;
    io_readPorts_15_ren = '0;
    io_readPorts_15_addr = '0;
    io_readPorts_16_ren = '0;
    io_readPorts_16_addr = '0;
    io_readPorts_17_ren = '0;
    io_readPorts_17_addr = '0;
    io_readPorts_18_ren = '0;
    io_readPorts_18_addr = '0;
    io_readPorts_19_ren = '0;
    io_readPorts_19_addr = '0;
    io_readPorts_20_ren = '0;
    io_readPorts_20_addr = '0;
    io_readPorts_21_ren = '0;
    io_readPorts_21_addr = '0;
    io_readPorts_22_ren = '0;
    io_readPorts_22_addr = '0;
    io_writePorts_0_wen = '0;
    io_writePorts_0_data = '0;
    io_writePorts_1_wen = '0;
    io_writePorts_1_data = '0;
    io_writePorts_2_wen = '0;
    io_writePorts_2_data = '0;
    io_writePorts_3_wen = '0;
    io_writePorts_3_data = '0;
    io_writePorts_4_wen = '0;
    io_writePorts_4_data = '0;
    io_writePorts_5_wen = '0;
    io_writePorts_5_data = '0;
    io_writePorts_6_wen = '0;
    io_writePorts_6_data = '0;
    p_io_readPorts_0_data = '0; tog_io_readPorts_0_data = 1'b0;
    p_io_readPorts_1_data = '0; tog_io_readPorts_1_data = 1'b0;
    p_io_readPorts_2_data = '0; tog_io_readPorts_2_data = 1'b0;
    p_io_readPorts_3_data = '0; tog_io_readPorts_3_data = 1'b0;
    p_io_readPorts_4_data = '0; tog_io_readPorts_4_data = 1'b0;
    p_io_readPorts_5_data = '0; tog_io_readPorts_5_data = 1'b0;
    p_io_readPorts_6_data = '0; tog_io_readPorts_6_data = 1'b0;
    p_io_readPorts_7_data = '0; tog_io_readPorts_7_data = 1'b0;
    p_io_readPorts_8_data = '0; tog_io_readPorts_8_data = 1'b0;
    p_io_readPorts_9_data = '0; tog_io_readPorts_9_data = 1'b0;
    p_io_readPorts_10_data = '0; tog_io_readPorts_10_data = 1'b0;
    p_io_readPorts_11_data = '0; tog_io_readPorts_11_data = 1'b0;
    p_io_readPorts_12_data = '0; tog_io_readPorts_12_data = 1'b0;
    p_io_readPorts_13_data = '0; tog_io_readPorts_13_data = 1'b0;
    p_io_readPorts_14_data = '0; tog_io_readPorts_14_data = 1'b0;
    p_io_readPorts_15_data = '0; tog_io_readPorts_15_data = 1'b0;
    p_io_readPorts_16_data = '0; tog_io_readPorts_16_data = 1'b0;
    p_io_readPorts_17_data = '0; tog_io_readPorts_17_data = 1'b0;
    p_io_readPorts_18_data = '0; tog_io_readPorts_18_data = 1'b0;
    p_io_readPorts_19_data = '0; tog_io_readPorts_19_data = 1'b0;
    p_io_readPorts_20_data = '0; tog_io_readPorts_20_data = 1'b0;
    p_io_readPorts_21_data = '0; tog_io_readPorts_21_data = 1'b0;
    p_io_readPorts_22_data = '0; tog_io_readPorts_22_data = 1'b0;
    p_io_toWakeupQueueRCIdx_0 = '0; tog_io_toWakeupQueueRCIdx_0 = 1'b0;
    p_io_toWakeupQueueRCIdx_1 = '0; tog_io_toWakeupQueueRCIdx_1 = 1'b0;
    p_io_toWakeupQueueRCIdx_2 = '0; tog_io_toWakeupQueueRCIdx_2 = 1'b0;
    p_io_toWakeupQueueRCIdx_3 = '0; tog_io_toWakeupQueueRCIdx_3 = 1'b0;
    p_io_toWakeupQueueRCIdx_4 = '0; tog_io_toWakeupQueueRCIdx_4 = 1'b0;
    p_io_toWakeupQueueRCIdx_5 = '0; tog_io_toWakeupQueueRCIdx_5 = 1'b0;
    p_io_toWakeupQueueRCIdx_6 = '0; tog_io_toWakeupQueueRCIdx_6 = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_readPorts_0_data) toggled++; else $display("COV: output io_readPorts_0_data never toggled");
    if (tog_io_readPorts_1_data) toggled++; else $display("COV: output io_readPorts_1_data never toggled");
    if (tog_io_readPorts_2_data) toggled++; else $display("COV: output io_readPorts_2_data never toggled");
    if (tog_io_readPorts_3_data) toggled++; else $display("COV: output io_readPorts_3_data never toggled");
    if (tog_io_readPorts_4_data) toggled++; else $display("COV: output io_readPorts_4_data never toggled");
    if (tog_io_readPorts_5_data) toggled++; else $display("COV: output io_readPorts_5_data never toggled");
    if (tog_io_readPorts_6_data) toggled++; else $display("COV: output io_readPorts_6_data never toggled");
    if (tog_io_readPorts_7_data) toggled++; else $display("COV: output io_readPorts_7_data never toggled");
    if (tog_io_readPorts_8_data) toggled++; else $display("COV: output io_readPorts_8_data never toggled");
    if (tog_io_readPorts_9_data) toggled++; else $display("COV: output io_readPorts_9_data never toggled");
    if (tog_io_readPorts_10_data) toggled++; else $display("COV: output io_readPorts_10_data never toggled");
    if (tog_io_readPorts_11_data) toggled++; else $display("COV: output io_readPorts_11_data never toggled");
    if (tog_io_readPorts_12_data) toggled++; else $display("COV: output io_readPorts_12_data never toggled");
    if (tog_io_readPorts_13_data) toggled++; else $display("COV: output io_readPorts_13_data never toggled");
    if (tog_io_readPorts_14_data) toggled++; else $display("COV: output io_readPorts_14_data never toggled");
    if (tog_io_readPorts_15_data) toggled++; else $display("COV: output io_readPorts_15_data never toggled");
    if (tog_io_readPorts_16_data) toggled++; else $display("COV: output io_readPorts_16_data never toggled");
    if (tog_io_readPorts_17_data) toggled++; else $display("COV: output io_readPorts_17_data never toggled");
    if (tog_io_readPorts_18_data) toggled++; else $display("COV: output io_readPorts_18_data never toggled");
    if (tog_io_readPorts_19_data) toggled++; else $display("COV: output io_readPorts_19_data never toggled");
    if (tog_io_readPorts_20_data) toggled++; else $display("COV: output io_readPorts_20_data never toggled");
    if (tog_io_readPorts_21_data) toggled++; else $display("COV: output io_readPorts_21_data never toggled");
    if (tog_io_readPorts_22_data) toggled++; else $display("COV: output io_readPorts_22_data never toggled");
    if (tog_io_toWakeupQueueRCIdx_0) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_0 never toggled");
    if (tog_io_toWakeupQueueRCIdx_1) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_1 never toggled");
    if (tog_io_toWakeupQueueRCIdx_2) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_2 never toggled");
    if (tog_io_toWakeupQueueRCIdx_3) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_3 never toggled");
    if (tog_io_toWakeupQueueRCIdx_4) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_4 never toggled");
    if (tog_io_toWakeupQueueRCIdx_5) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_5 never toggled");
    if (tog_io_toWakeupQueueRCIdx_6) toggled++; else $display("COV: output io_toWakeupQueueRCIdx_6 never toggled");
    $display("RegCache checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
