// =============================================================================
// MultiWakeupQueue 家族 UT（4 个变体）：golden <M> 与重写 <M>_xs 同激励双例化，
// 逐拍比对**全部**输出口（每变体把输出口拼成一根向量整体比）。子模块两侧各用各的：
// golden 侧 golden PipeWithFlush*，重写侧 rtl/common 的已签核重写件。
//
// 激励按事件造：
//   * lat 85% 取 0..3（覆盖各变体的每条流水），15% 取 0..7（非法 lat：哪条都不进）
//   * robIdx 围着一个缓慢前进的游标取值，redirect 的 robIdx 也围着它取 ——
//     这样 isAfter / 相等（level=flushItself）两种冲刷判据都真的会成立/不成立，
//     且 flag 回绕（游标跨 256）也会发生
//   * ld2Cancel / og0Fail / og1Fail 各自独立随机点亮
//   * 0.5% 的拍中途拉复位（流水 valid 有异步复位，lastConnect 不复位）
// lastConnect_* 全不复位且每拍无条件写：复位释放后跳过 2 拍再比。
// 覆盖计数（golden 内部探针）任一为 0 判 TEST FAILED。
// =============================================================================
`timescale 1ns/1ps
module tb;
  logic clk = 0;
  logic rst = 1;
  always #5 clk = ~clk;

  int NCYCLES = 200000;

  logic [0:0] io_flush_redirect_valid;
  logic [0:0] io_flush_redirect_bits_robIdx_flag;
  logic [7:0] io_flush_redirect_bits_robIdx_value;
  logic [0:0] io_flush_redirect_bits_level;
  logic [0:0] io_flush_ldCancel_0_ld2Cancel;
  logic [0:0] io_flush_ldCancel_1_ld2Cancel;
  logic [0:0] io_flush_ldCancel_2_ld2Cancel;
  logic [0:0] io_flush_og0Fail;
  logic [0:0] io_flush_og1Fail;
  logic [0:0] io_enq_valid;
  logic [34:0] io_enq_bits_uop_fuType;
  logic [0:0] io_enq_bits_uop_robIdx_flag;
  logic [7:0] io_enq_bits_uop_robIdx_value;
  logic [7:0] io_enq_bits_uop_pdest;
  logic [0:0] io_enq_bits_uop_rfWen;
  logic [1:0] io_enq_bits_uop_loadDependency_0;
  logic [1:0] io_enq_bits_uop_loadDependency_1;
  logic [1:0] io_enq_bits_uop_loadDependency_2;
  logic [2:0] io_enq_bits_lat;
  logic [0:0] io_enq_bits_uop_fpWen;
  logic [0:0] io_enq_bits_uop_vecWen;
  logic [0:0] io_enq_bits_uop_v0Wen;

  wire [140:0] g_out0, i_out0;  // MultiWakeupQueue: 37 个输出口 / 141 位
  MultiWakeupQueue g_0 (
    .clock(clk),
    .reset(rst),
    .io_flush_redirect_valid(io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag(io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value(io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level(io_flush_redirect_bits_level),
    .io_flush_ldCancel_0_ld2Cancel(io_flush_ldCancel_0_ld2Cancel),
    .io_flush_ldCancel_1_ld2Cancel(io_flush_ldCancel_1_ld2Cancel),
    .io_flush_ldCancel_2_ld2Cancel(io_flush_ldCancel_2_ld2Cancel),
    .io_flush_og0Fail(io_flush_og0Fail),
    .io_flush_og1Fail(io_flush_og1Fail),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_fuType(io_enq_bits_uop_fuType),
    .io_enq_bits_uop_robIdx_flag(io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_uop_robIdx_value(io_enq_bits_uop_robIdx_value),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_rfWen(io_enq_bits_uop_rfWen),
    .io_enq_bits_uop_loadDependency_0(io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_uop_loadDependency_1(io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_uop_loadDependency_2(io_enq_bits_uop_loadDependency_2),
    .io_enq_bits_lat(io_enq_bits_lat[1:0]),
    .io_deq_bits_loadDependency_2(g_out0[1:0]),
    .io_deq_bits_loadDependency_1(g_out0[3:2]),
    .io_deq_bits_loadDependency_0(g_out0[5:4]),
    .io_deq_bits_rfWen(g_out0[6:6]),
    .io_deq_bits_pdest(g_out0[14:7]),
    .io_deq_bits_loadDependencyCopy_5_2(g_out0[16:15]),
    .io_deq_bits_loadDependencyCopy_5_1(g_out0[18:17]),
    .io_deq_bits_loadDependencyCopy_5_0(g_out0[20:19]),
    .io_deq_bits_loadDependencyCopy_4_2(g_out0[22:21]),
    .io_deq_bits_loadDependencyCopy_4_1(g_out0[24:23]),
    .io_deq_bits_loadDependencyCopy_4_0(g_out0[26:25]),
    .io_deq_bits_loadDependencyCopy_3_2(g_out0[28:27]),
    .io_deq_bits_loadDependencyCopy_3_1(g_out0[30:29]),
    .io_deq_bits_loadDependencyCopy_3_0(g_out0[32:31]),
    .io_deq_bits_loadDependencyCopy_2_2(g_out0[34:33]),
    .io_deq_bits_loadDependencyCopy_2_1(g_out0[36:35]),
    .io_deq_bits_loadDependencyCopy_2_0(g_out0[38:37]),
    .io_deq_bits_loadDependencyCopy_1_2(g_out0[40:39]),
    .io_deq_bits_loadDependencyCopy_1_1(g_out0[42:41]),
    .io_deq_bits_loadDependencyCopy_1_0(g_out0[44:43]),
    .io_deq_bits_loadDependencyCopy_0_2(g_out0[46:45]),
    .io_deq_bits_loadDependencyCopy_0_1(g_out0[48:47]),
    .io_deq_bits_loadDependencyCopy_0_0(g_out0[50:49]),
    .io_deq_bits_rfWenCopy_5(g_out0[51:51]),
    .io_deq_bits_rfWenCopy_4(g_out0[52:52]),
    .io_deq_bits_rfWenCopy_3(g_out0[53:53]),
    .io_deq_bits_rfWenCopy_2(g_out0[54:54]),
    .io_deq_bits_rfWenCopy_1(g_out0[55:55]),
    .io_deq_bits_rfWenCopy_0(g_out0[56:56]),
    .io_deq_bits_pdestCopy_5(g_out0[64:57]),
    .io_deq_bits_pdestCopy_4(g_out0[72:65]),
    .io_deq_bits_pdestCopy_3(g_out0[80:73]),
    .io_deq_bits_pdestCopy_2(g_out0[88:81]),
    .io_deq_bits_pdestCopy_1(g_out0[96:89]),
    .io_deq_bits_pdestCopy_0(g_out0[104:97]),
    .io_deq_bits_fuType(g_out0[139:105]),
    .io_deq_valid(g_out0[140:140])
  );
  MultiWakeupQueue_xs i_0 (
    .clock(clk),
    .reset(rst),
    .io_flush_redirect_valid(io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag(io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value(io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level(io_flush_redirect_bits_level),
    .io_flush_ldCancel_0_ld2Cancel(io_flush_ldCancel_0_ld2Cancel),
    .io_flush_ldCancel_1_ld2Cancel(io_flush_ldCancel_1_ld2Cancel),
    .io_flush_ldCancel_2_ld2Cancel(io_flush_ldCancel_2_ld2Cancel),
    .io_flush_og0Fail(io_flush_og0Fail),
    .io_flush_og1Fail(io_flush_og1Fail),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_fuType(io_enq_bits_uop_fuType),
    .io_enq_bits_uop_robIdx_flag(io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_uop_robIdx_value(io_enq_bits_uop_robIdx_value),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_rfWen(io_enq_bits_uop_rfWen),
    .io_enq_bits_uop_loadDependency_0(io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_uop_loadDependency_1(io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_uop_loadDependency_2(io_enq_bits_uop_loadDependency_2),
    .io_enq_bits_lat(io_enq_bits_lat[1:0]),
    .io_deq_bits_loadDependency_2(i_out0[1:0]),
    .io_deq_bits_loadDependency_1(i_out0[3:2]),
    .io_deq_bits_loadDependency_0(i_out0[5:4]),
    .io_deq_bits_rfWen(i_out0[6:6]),
    .io_deq_bits_pdest(i_out0[14:7]),
    .io_deq_bits_loadDependencyCopy_5_2(i_out0[16:15]),
    .io_deq_bits_loadDependencyCopy_5_1(i_out0[18:17]),
    .io_deq_bits_loadDependencyCopy_5_0(i_out0[20:19]),
    .io_deq_bits_loadDependencyCopy_4_2(i_out0[22:21]),
    .io_deq_bits_loadDependencyCopy_4_1(i_out0[24:23]),
    .io_deq_bits_loadDependencyCopy_4_0(i_out0[26:25]),
    .io_deq_bits_loadDependencyCopy_3_2(i_out0[28:27]),
    .io_deq_bits_loadDependencyCopy_3_1(i_out0[30:29]),
    .io_deq_bits_loadDependencyCopy_3_0(i_out0[32:31]),
    .io_deq_bits_loadDependencyCopy_2_2(i_out0[34:33]),
    .io_deq_bits_loadDependencyCopy_2_1(i_out0[36:35]),
    .io_deq_bits_loadDependencyCopy_2_0(i_out0[38:37]),
    .io_deq_bits_loadDependencyCopy_1_2(i_out0[40:39]),
    .io_deq_bits_loadDependencyCopy_1_1(i_out0[42:41]),
    .io_deq_bits_loadDependencyCopy_1_0(i_out0[44:43]),
    .io_deq_bits_loadDependencyCopy_0_2(i_out0[46:45]),
    .io_deq_bits_loadDependencyCopy_0_1(i_out0[48:47]),
    .io_deq_bits_loadDependencyCopy_0_0(i_out0[50:49]),
    .io_deq_bits_rfWenCopy_5(i_out0[51:51]),
    .io_deq_bits_rfWenCopy_4(i_out0[52:52]),
    .io_deq_bits_rfWenCopy_3(i_out0[53:53]),
    .io_deq_bits_rfWenCopy_2(i_out0[54:54]),
    .io_deq_bits_rfWenCopy_1(i_out0[55:55]),
    .io_deq_bits_rfWenCopy_0(i_out0[56:56]),
    .io_deq_bits_pdestCopy_5(i_out0[64:57]),
    .io_deq_bits_pdestCopy_4(i_out0[72:65]),
    .io_deq_bits_pdestCopy_3(i_out0[80:73]),
    .io_deq_bits_pdestCopy_2(i_out0[88:81]),
    .io_deq_bits_pdestCopy_1(i_out0[96:89]),
    .io_deq_bits_pdestCopy_0(i_out0[104:97]),
    .io_deq_bits_fuType(i_out0[139:105]),
    .io_deq_valid(i_out0[140:140])
  );
  wire [105:0] g_out1, i_out1;  // MultiWakeupQueue_2: 36 个输出口 / 106 位
  MultiWakeupQueue_2 g_1 (
    .clock(clk),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_fuType(io_enq_bits_uop_fuType),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_rfWen(io_enq_bits_uop_rfWen),
    .io_enq_bits_uop_loadDependency_0(io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_uop_loadDependency_1(io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_uop_loadDependency_2(io_enq_bits_uop_loadDependency_2),
    .io_deq_bits_loadDependency_2(g_out1[1:0]),
    .io_deq_bits_loadDependency_1(g_out1[3:2]),
    .io_deq_bits_loadDependency_0(g_out1[5:4]),
    .io_deq_bits_rfWen(g_out1[6:6]),
    .io_deq_bits_pdest(g_out1[14:7]),
    .io_deq_bits_loadDependencyCopy_5_2(g_out1[16:15]),
    .io_deq_bits_loadDependencyCopy_5_1(g_out1[18:17]),
    .io_deq_bits_loadDependencyCopy_5_0(g_out1[20:19]),
    .io_deq_bits_loadDependencyCopy_4_2(g_out1[22:21]),
    .io_deq_bits_loadDependencyCopy_4_1(g_out1[24:23]),
    .io_deq_bits_loadDependencyCopy_4_0(g_out1[26:25]),
    .io_deq_bits_loadDependencyCopy_3_2(g_out1[28:27]),
    .io_deq_bits_loadDependencyCopy_3_1(g_out1[30:29]),
    .io_deq_bits_loadDependencyCopy_3_0(g_out1[32:31]),
    .io_deq_bits_loadDependencyCopy_2_2(g_out1[34:33]),
    .io_deq_bits_loadDependencyCopy_2_1(g_out1[36:35]),
    .io_deq_bits_loadDependencyCopy_2_0(g_out1[38:37]),
    .io_deq_bits_loadDependencyCopy_1_2(g_out1[40:39]),
    .io_deq_bits_loadDependencyCopy_1_1(g_out1[42:41]),
    .io_deq_bits_loadDependencyCopy_1_0(g_out1[44:43]),
    .io_deq_bits_loadDependencyCopy_0_2(g_out1[46:45]),
    .io_deq_bits_loadDependencyCopy_0_1(g_out1[48:47]),
    .io_deq_bits_loadDependencyCopy_0_0(g_out1[50:49]),
    .io_deq_bits_rfWenCopy_5(g_out1[51:51]),
    .io_deq_bits_rfWenCopy_4(g_out1[52:52]),
    .io_deq_bits_rfWenCopy_3(g_out1[53:53]),
    .io_deq_bits_rfWenCopy_2(g_out1[54:54]),
    .io_deq_bits_rfWenCopy_1(g_out1[55:55]),
    .io_deq_bits_rfWenCopy_0(g_out1[56:56]),
    .io_deq_bits_pdestCopy_5(g_out1[64:57]),
    .io_deq_bits_pdestCopy_4(g_out1[72:65]),
    .io_deq_bits_pdestCopy_3(g_out1[80:73]),
    .io_deq_bits_pdestCopy_2(g_out1[88:81]),
    .io_deq_bits_pdestCopy_1(g_out1[96:89]),
    .io_deq_bits_pdestCopy_0(g_out1[104:97]),
    .io_deq_valid(g_out1[105:105])
  );
  MultiWakeupQueue_2_xs i_1 (
    .clock(clk),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_fuType(io_enq_bits_uop_fuType),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_rfWen(io_enq_bits_uop_rfWen),
    .io_enq_bits_uop_loadDependency_0(io_enq_bits_uop_loadDependency_0),
    .io_enq_bits_uop_loadDependency_1(io_enq_bits_uop_loadDependency_1),
    .io_enq_bits_uop_loadDependency_2(io_enq_bits_uop_loadDependency_2),
    .io_deq_bits_loadDependency_2(i_out1[1:0]),
    .io_deq_bits_loadDependency_1(i_out1[3:2]),
    .io_deq_bits_loadDependency_0(i_out1[5:4]),
    .io_deq_bits_rfWen(i_out1[6:6]),
    .io_deq_bits_pdest(i_out1[14:7]),
    .io_deq_bits_loadDependencyCopy_5_2(i_out1[16:15]),
    .io_deq_bits_loadDependencyCopy_5_1(i_out1[18:17]),
    .io_deq_bits_loadDependencyCopy_5_0(i_out1[20:19]),
    .io_deq_bits_loadDependencyCopy_4_2(i_out1[22:21]),
    .io_deq_bits_loadDependencyCopy_4_1(i_out1[24:23]),
    .io_deq_bits_loadDependencyCopy_4_0(i_out1[26:25]),
    .io_deq_bits_loadDependencyCopy_3_2(i_out1[28:27]),
    .io_deq_bits_loadDependencyCopy_3_1(i_out1[30:29]),
    .io_deq_bits_loadDependencyCopy_3_0(i_out1[32:31]),
    .io_deq_bits_loadDependencyCopy_2_2(i_out1[34:33]),
    .io_deq_bits_loadDependencyCopy_2_1(i_out1[36:35]),
    .io_deq_bits_loadDependencyCopy_2_0(i_out1[38:37]),
    .io_deq_bits_loadDependencyCopy_1_2(i_out1[40:39]),
    .io_deq_bits_loadDependencyCopy_1_1(i_out1[42:41]),
    .io_deq_bits_loadDependencyCopy_1_0(i_out1[44:43]),
    .io_deq_bits_loadDependencyCopy_0_2(i_out1[46:45]),
    .io_deq_bits_loadDependencyCopy_0_1(i_out1[48:47]),
    .io_deq_bits_loadDependencyCopy_0_0(i_out1[50:49]),
    .io_deq_bits_rfWenCopy_5(i_out1[51:51]),
    .io_deq_bits_rfWenCopy_4(i_out1[52:52]),
    .io_deq_bits_rfWenCopy_3(i_out1[53:53]),
    .io_deq_bits_rfWenCopy_2(i_out1[54:54]),
    .io_deq_bits_rfWenCopy_1(i_out1[55:55]),
    .io_deq_bits_rfWenCopy_0(i_out1[56:56]),
    .io_deq_bits_pdestCopy_5(i_out1[64:57]),
    .io_deq_bits_pdestCopy_4(i_out1[72:65]),
    .io_deq_bits_pdestCopy_3(i_out1[80:73]),
    .io_deq_bits_pdestCopy_2(i_out1[88:81]),
    .io_deq_bits_pdestCopy_1(i_out1[96:89]),
    .io_deq_bits_pdestCopy_0(i_out1[104:97]),
    .io_deq_valid(i_out1[105:105])
  );
  wire [46:0] g_out2, i_out2;  // MultiWakeupQueue_4: 6 个输出口 / 47 位
  MultiWakeupQueue_4 g_2 (
    .clock(clk),
    .reset(rst),
    .io_flush_redirect_valid(io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag(io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value(io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level(io_flush_redirect_bits_level),
    .io_flush_og0Fail(io_flush_og0Fail),
    .io_flush_og1Fail(io_flush_og1Fail),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_fuType(io_enq_bits_uop_fuType),
    .io_enq_bits_uop_robIdx_flag(io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_uop_robIdx_value(io_enq_bits_uop_robIdx_value),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_fpWen(io_enq_bits_uop_fpWen),
    .io_enq_bits_uop_vecWen(io_enq_bits_uop_vecWen),
    .io_enq_bits_uop_v0Wen(io_enq_bits_uop_v0Wen),
    .io_enq_bits_lat(io_enq_bits_lat),
    .io_deq_bits_v0Wen(g_out2[0:0]),
    .io_deq_bits_vecWen(g_out2[1:1]),
    .io_deq_bits_fpWen(g_out2[2:2]),
    .io_deq_bits_pdest(g_out2[10:3]),
    .io_deq_bits_fuType(g_out2[45:11]),
    .io_deq_valid(g_out2[46:46])
  );
  MultiWakeupQueue_4_xs i_2 (
    .clock(clk),
    .reset(rst),
    .io_flush_redirect_valid(io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag(io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value(io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level(io_flush_redirect_bits_level),
    .io_flush_og0Fail(io_flush_og0Fail),
    .io_flush_og1Fail(io_flush_og1Fail),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_fuType(io_enq_bits_uop_fuType),
    .io_enq_bits_uop_robIdx_flag(io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_uop_robIdx_value(io_enq_bits_uop_robIdx_value),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_fpWen(io_enq_bits_uop_fpWen),
    .io_enq_bits_uop_vecWen(io_enq_bits_uop_vecWen),
    .io_enq_bits_uop_v0Wen(io_enq_bits_uop_v0Wen),
    .io_enq_bits_lat(io_enq_bits_lat),
    .io_deq_bits_v0Wen(i_out2[0:0]),
    .io_deq_bits_vecWen(i_out2[1:1]),
    .io_deq_bits_fpWen(i_out2[2:2]),
    .io_deq_bits_pdest(i_out2[10:3]),
    .io_deq_bits_fuType(i_out2[45:11]),
    .io_deq_valid(i_out2[46:46])
  );
  wire [9:0] g_out3, i_out3;  // MultiWakeupQueue_5: 3 个输出口 / 10 位
  MultiWakeupQueue_5 g_3 (
    .clock(clk),
    .reset(rst),
    .io_flush_redirect_valid(io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag(io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value(io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level(io_flush_redirect_bits_level),
    .io_flush_og0Fail(io_flush_og0Fail),
    .io_flush_og1Fail(io_flush_og1Fail),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_robIdx_flag(io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_uop_robIdx_value(io_enq_bits_uop_robIdx_value),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_fpWen(io_enq_bits_uop_fpWen),
    .io_enq_bits_lat(io_enq_bits_lat),
    .io_deq_bits_fpWen(g_out3[0:0]),
    .io_deq_bits_pdest(g_out3[8:1]),
    .io_deq_valid(g_out3[9:9])
  );
  MultiWakeupQueue_5_xs i_3 (
    .clock(clk),
    .reset(rst),
    .io_flush_redirect_valid(io_flush_redirect_valid),
    .io_flush_redirect_bits_robIdx_flag(io_flush_redirect_bits_robIdx_flag),
    .io_flush_redirect_bits_robIdx_value(io_flush_redirect_bits_robIdx_value),
    .io_flush_redirect_bits_level(io_flush_redirect_bits_level),
    .io_flush_og0Fail(io_flush_og0Fail),
    .io_flush_og1Fail(io_flush_og1Fail),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_uop_robIdx_flag(io_enq_bits_uop_robIdx_flag),
    .io_enq_bits_uop_robIdx_value(io_enq_bits_uop_robIdx_value),
    .io_enq_bits_uop_pdest(io_enq_bits_uop_pdest),
    .io_enq_bits_uop_fpWen(io_enq_bits_uop_fpWen),
    .io_enq_bits_lat(io_enq_bits_lat),
    .io_deq_bits_fpWen(i_out3[0:0]),
    .io_deq_bits_pdest(i_out3[8:1]),
    .io_deq_valid(i_out3[9:9])
  );

  // ---------------------------------------------------------------------------
  // 激励
  // ---------------------------------------------------------------------------
  logic [8:0] rob_cursor = 9'h0;

  function automatic logic [8:0] near_cursor();
    return rob_cursor + 9'($urandom_range(0, 12)) - 9'd4;
  endfunction

  always @(negedge clk) begin
    logic [8:0] r;
    if ($urandom_range(0, 3) == 0) rob_cursor = rob_cursor + 9'd1;
    io_enq_valid = ($urandom_range(0, 99) < 70);
    io_enq_bits_lat = ($urandom_range(0, 99) < 85) ? 3'($urandom_range(0, 3)) : 3'($urandom);
    io_enq_bits_uop_fuType = {3'($urandom), $urandom};
    r = near_cursor();
    {io_enq_bits_uop_robIdx_flag, io_enq_bits_uop_robIdx_value} = r;
    io_enq_bits_uop_pdest = 8'($urandom);
    io_enq_bits_uop_rfWen = $urandom;
    io_enq_bits_uop_fpWen = $urandom;
    io_enq_bits_uop_vecWen = $urandom;
    io_enq_bits_uop_v0Wen = $urandom;
    io_enq_bits_uop_loadDependency_0 = 2'($urandom);
    io_enq_bits_uop_loadDependency_1 = 2'($urandom);
    io_enq_bits_uop_loadDependency_2 = 2'($urandom);
    io_flush_redirect_valid = ($urandom_range(0, 99) < 20);
    io_flush_redirect_bits_level = $urandom;
    r = near_cursor();
    {io_flush_redirect_bits_robIdx_flag, io_flush_redirect_bits_robIdx_value} = r;
    io_flush_ldCancel_0_ld2Cancel = ($urandom_range(0, 99) < 15);
    io_flush_ldCancel_1_ld2Cancel = ($urandom_range(0, 99) < 15);
    io_flush_ldCancel_2_ld2Cancel = ($urandom_range(0, 99) < 15);
    io_flush_og0Fail = ($urandom_range(0, 99) < 20);
    io_flush_og1Fail = ($urandom_range(0, 99) < 20);
  end

  // ---------------------------------------------------------------------------
  // 比对 + 覆盖
  // ---------------------------------------------------------------------------
  longint checks = 0;
  longint errors [4] = '{0, 0, 0, 0};
  int     settle = 0;
  longint cov_deq      [4] = '{0, 0, 0, 0};   // io_deq_valid=1
  longint cov_kill     [4] = '{0, 0, 0, 0};   // 某条 lat>0 流水出口有效但被出口冲刷杀掉
  longint cov_collide  [4] = '{0, 0, 0, 0};   // 两条以上流水同拍出口有效（按位或汇合）
  longint cov_ldkill   = 0;                   // MWQ：lat=2 出口只因 load 取消被杀
  longint cov_midreset = 0;

  always @(posedge clk) begin
    #4;
    if (rst) settle = 0;
    else if (settle < 2) settle++;
    else begin
      checks++;
      if (g_out0 !== i_out0) begin errors[0]++; if (errors[0] <= 5) $display("[%0t] MWQ   g=%h i=%h", $time, g_out0, i_out0); end
      if (g_out1 !== i_out1) begin errors[1]++; if (errors[1] <= 5) $display("[%0t] MWQ_2 g=%h i=%h", $time, g_out1, i_out1); end
      if (g_out2 !== i_out2) begin errors[2]++; if (errors[2] <= 5) $display("[%0t] MWQ_4 g=%h i=%h", $time, g_out2, i_out2); end
      if (g_out3 !== i_out3) begin errors[3]++; if (errors[3] <= 5) $display("[%0t] MWQ_5 g=%h i=%h", $time, g_out3, i_out3); end
      if (g_0.io_deq_valid) cov_deq[0]++;
      if (g_1.io_deq_valid) cov_deq[1]++;
      if (g_2.io_deq_valid) cov_deq[2]++;
      if (g_3.io_deq_valid) cov_deq[3]++;
      if (g_0._pipes_1_io_deq_valid & ~g_0.pipesValidVec_1) cov_kill[0]++;
      cov_kill[1] = -1;   // MWQ_2 只有 lat=0 一条流水，没有出口冲刷
      if (g_2._pipes_0_io_deq_valid & ~g_2.pipesValidVec_0 | g_2._pipes_1_io_deq_valid & ~g_2.pipesValidVec_1
          | g_2._pipes_3_io_deq_valid & ~g_2.pipesValidVec_3) cov_kill[2]++;
      if (g_3._pipes_0_io_deq_valid & ~g_3.pipesValidVec_0 | g_3._pipes_1_io_deq_valid & ~g_3.pipesValidVec_1) cov_kill[3]++;
      if (g_0._pipes_0_io_deq_valid & g_0.pipesValidVec_1) cov_collide[0]++;
      cov_collide[1] = -1;
      if ($countones({g_2.pipesValidVec_0, g_2.pipesValidVec_1, g_2._pipes_2_io_deq_valid, g_2.pipesValidVec_3}) >= 2) cov_collide[2]++;
      if (g_3.pipesValidVec_0 & g_3.pipesValidVec_1) cov_collide[3]++;
      // lat=2 出口被 ld2Cancel & loadDependency[k][1] 单独杀掉（redirect/og1Fail 都没成立）
      if (g_0._pipes_1_io_deq_valid && !io_flush_redirect_valid && !io_flush_og1Fail &&
          (io_flush_ldCancel_0_ld2Cancel & g_0._pipes_1_io_deq_bits_loadDependency_0[1] |
           io_flush_ldCancel_1_ld2Cancel & g_0._pipes_1_io_deq_bits_loadDependency_1[1] |
           io_flush_ldCancel_2_ld2Cancel & g_0._pipes_1_io_deq_bits_loadDependency_2[1])) cov_ldkill++;
    end
  end

  initial begin
    int bad;
    longint tot_err;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (4) @(posedge clk); @(negedge clk); rst = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      @(negedge clk);
      #1;
      if ($urandom_range(0, 199) == 0) begin rst = 1; cov_midreset++; end
      else rst = 0;
    end
    bad = 0;
    tot_err = 0;
    for (int v = 0; v < 4; v++) begin
      tot_err += errors[v];
      if (errors[v] != 0 || cov_deq[v] == 0 || cov_kill[v] == 0 || cov_collide[v] == 0) bad = 1;
      $display("VARIANT %0d errors=%0d cov_deq=%0d cov_kill=%0d cov_collide=%0d", v, errors[v], cov_deq[v],
               cov_kill[v], cov_collide[v]);
    end
    if (cov_ldkill == 0 || cov_midreset == 0) bad = 1;
    $display("COVER ldkill=%0d midreset=%0d (cov=-1 表示该变体结构上没有这类事件)", cov_ldkill, cov_midreset);
    $display("checks=%0d errors=%0d", checks, tot_err);
    if (!bad) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
