// 自动生成：verif/ut/PipeWithFlush/gen.py（读 G1 golden）—— 勿手改
// PipeWithFlush 家族 8 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_PipeWithFlush_core 设不同 STAGES / 载荷 / 冲刷特性）。
// 被测语义：N 级 valid + bits 流水；第 2 级起可被 redirect / ldCancel / ogFail 冲掉；
//   loadDependency 每前移一级左移一位（老化）。
// 家族四种形状都在场（缺一种这个 tb 就证不到那一档）：
//   STAGES=0 直通（无 clock/reset/flush）：PipeWithFlush PipeWithFlush_8
//   STAGES=1 无冲刷：PipeWithFlush_6 PipeWithFlush_10
//   STAGES>=2 有冲刷：PipeWithFlush_1 PipeWithFlush_7 PipeWithFlush_9 PipeWithFlush_11
//   带 loadDependency 老化 + ldCancel：PipeWithFlush_1
//
// ★热身窗口 WARMUP 不是为了绕过失配，是「无复位数据链」的定义域★
//   golden 的 bits_k_* 与重写侧 u_core.g_pipe.bits_q[] 是**不同的寄存器**：
//   +vcs+initreg+random 给它们各自独立的随机初值，链灌满之前输出的是这些初值，
//   本来就不该相等（$isunknown 拦不住 —— 随机初值不是 X）。
//   而数据级是**使能门控**的（第 k 级要等 valids[k-1] 拉高才更新），光"前几拍不比"
//   还不够。做法是**确定性灌注**：窗口内把 io_enq_valid 强制拉 1、所有 flush 输入
//   强制拉 0，连续 STAGES 拍后每级都装着 tb 驱动的数据（两侧逐级同源，归纳可证
//   相等），窗口一过立刻开始逐拍比，此后**一拍都不豁免**。
//   WARMUP = 家族最大级数 + 1 = 4 拍。
//
// 激励：io_enq_valid 50%；载荷逐位随机并混入全 0 / 全 1；
//   robIdx 一半落在窄区间（0..7）好让重定向比较真的命中，一半全随机；
//   redirect_valid 1/8、level 1/2、ogFail 1/16、ldCancel 1/8；
//   reset 偶尔异步脉冲一拍。
// 覆盖闸：每个变体都要 (1) 比对次数 >= COV_MIN；(2) deq_valid 的 0 / 1 各 >= COV_MIN；
//   (3) 载荷每一位都见过 1 和 0 —— **但 loadDependency 老化会把每路最低位恒填 0**，
//       所以这些位单列成第 (3b) 条：它们必须**从未**出现过 1。把"测不到 1"从
//       豁免改写成断言：老化少移一位、或者第 1 级误加了老化，这条立刻红。
//   有冲刷的变体另外要 (4) redirect_valid=1 >= COV_MIN；(5) 每根 ogFail=1 >= COV_MIN；
//   (6) **被冲掉的条目数 >= COV_MIN** —— 入队 valid 数减出队 valid 数，
//       这是"冲刷真的发生过"的见证，不是"按构造应该会冲"；
//   带 ldCancel 的变体再要 (7) 每路 ldCancel=1 >= COV_MIN。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  localparam int WARMUP  = 4;   // 确定性灌注窗口，见文件头
  int cycle = 0;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  // ---- 冲刷激励（所有带冲刷的变体共用同一组，便于对照）----
  logic fl_red_valid, fl_red_flag, fl_red_level;
  logic [7:0] fl_red_value;
  logic fl_ldc [3];
  logic fl_og [2];

  // ---- PipeWithFlush: STAGES=0 载荷 50 位 / 6 字段 ----
  logic p0_enq_valid;
  logic [49:0] p0_enq;
  wire  [49:0] g_p0_deq, i_p0_deq;
  wire  g_p0_dv, i_p0_dv;
  logic [49:0] p0_ones, p0_zeros;
  int   p0_checks, p0_dv1, p0_dv0, p0_enq1;
  PipeWithFlush u_g_p0 (
    .io_enq_valid(p0_enq_valid),
    .io_enq_bits_fuType(p0_enq[49:15]),
    .io_enq_bits_pdest(p0_enq[14:7]),
    .io_enq_bits_rfWen(p0_enq[6]),
    .io_enq_bits_loadDependency_0(p0_enq[5:4]),
    .io_enq_bits_loadDependency_1(p0_enq[3:2]),
    .io_enq_bits_loadDependency_2(p0_enq[1:0]),
    .io_deq_valid(g_p0_dv),
    .io_deq_bits_fuType(g_p0_deq[49:15]),
    .io_deq_bits_pdest(g_p0_deq[14:7]),
    .io_deq_bits_rfWen(g_p0_deq[6]),
    .io_deq_bits_loadDependency_0(g_p0_deq[5:4]),
    .io_deq_bits_loadDependency_1(g_p0_deq[3:2]),
    .io_deq_bits_loadDependency_2(g_p0_deq[1:0])
  );
  PipeWithFlush_xs u_i_p0 (
    .io_enq_valid(p0_enq_valid),
    .io_enq_bits_fuType(p0_enq[49:15]),
    .io_enq_bits_pdest(p0_enq[14:7]),
    .io_enq_bits_rfWen(p0_enq[6]),
    .io_enq_bits_loadDependency_0(p0_enq[5:4]),
    .io_enq_bits_loadDependency_1(p0_enq[3:2]),
    .io_enq_bits_loadDependency_2(p0_enq[1:0]),
    .io_deq_valid(i_p0_dv),
    .io_deq_bits_fuType(i_p0_deq[49:15]),
    .io_deq_bits_pdest(i_p0_deq[14:7]),
    .io_deq_bits_rfWen(i_p0_deq[6]),
    .io_deq_bits_loadDependency_0(i_p0_deq[5:4]),
    .io_deq_bits_loadDependency_1(i_p0_deq[3:2]),
    .io_deq_bits_loadDependency_2(i_p0_deq[1:0])
  );

  // ---- PipeWithFlush_1: STAGES=2 载荷 59 位 / 8 字段 / ldCancel 3 路 ----
  logic p1_enq_valid;
  logic [58:0] p1_enq;
  wire  [58:0] g_p1_deq, i_p1_deq;
  wire  g_p1_dv, i_p1_dv;
  logic [58:0] p1_ones, p1_zeros;
  int   p1_checks, p1_dv1, p1_dv0, p1_enq1;
  int   p1_red;
  int   p1_og [1];
  int   p1_ldc [3];
  PipeWithFlush_1 u_g_p1 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_ldCancel_0_ld2Cancel(fl_ldc[0]),
    .io_flush_ldCancel_1_ld2Cancel(fl_ldc[1]),
    .io_flush_ldCancel_2_ld2Cancel(fl_ldc[2]),
    .io_flush_og0Fail(fl_og[0]),
    .io_enq_valid(p1_enq_valid),
    .io_enq_bits_fuType(p1_enq[58:24]),
    .io_enq_bits_pdest(p1_enq[23:16]),
    .io_enq_bits_rfWen(p1_enq[15]),
    .io_enq_bits_robIdx_flag(p1_enq[14]),
    .io_enq_bits_robIdx_value(p1_enq[13:6]),
    .io_enq_bits_loadDependency_2(p1_enq[5:4]),
    .io_enq_bits_loadDependency_1(p1_enq[3:2]),
    .io_enq_bits_loadDependency_0(p1_enq[1:0]),
    .io_deq_valid(g_p1_dv),
    .io_deq_bits_fuType(g_p1_deq[58:24]),
    .io_deq_bits_pdest(g_p1_deq[23:16]),
    .io_deq_bits_rfWen(g_p1_deq[15]),
    .io_deq_bits_robIdx_flag(g_p1_deq[14]),
    .io_deq_bits_robIdx_value(g_p1_deq[13:6]),
    .io_deq_bits_loadDependency_2(g_p1_deq[5:4]),
    .io_deq_bits_loadDependency_1(g_p1_deq[3:2]),
    .io_deq_bits_loadDependency_0(g_p1_deq[1:0])
  );
  PipeWithFlush_1_xs u_i_p1 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_ldCancel_0_ld2Cancel(fl_ldc[0]),
    .io_flush_ldCancel_1_ld2Cancel(fl_ldc[1]),
    .io_flush_ldCancel_2_ld2Cancel(fl_ldc[2]),
    .io_flush_og0Fail(fl_og[0]),
    .io_enq_valid(p1_enq_valid),
    .io_enq_bits_fuType(p1_enq[58:24]),
    .io_enq_bits_pdest(p1_enq[23:16]),
    .io_enq_bits_rfWen(p1_enq[15]),
    .io_enq_bits_robIdx_flag(p1_enq[14]),
    .io_enq_bits_robIdx_value(p1_enq[13:6]),
    .io_enq_bits_loadDependency_2(p1_enq[5:4]),
    .io_enq_bits_loadDependency_1(p1_enq[3:2]),
    .io_enq_bits_loadDependency_0(p1_enq[1:0]),
    .io_deq_valid(i_p1_dv),
    .io_deq_bits_fuType(i_p1_deq[58:24]),
    .io_deq_bits_pdest(i_p1_deq[23:16]),
    .io_deq_bits_rfWen(i_p1_deq[15]),
    .io_deq_bits_robIdx_flag(i_p1_deq[14]),
    .io_deq_bits_robIdx_value(i_p1_deq[13:6]),
    .io_deq_bits_loadDependency_2(i_p1_deq[5:4]),
    .io_deq_bits_loadDependency_1(i_p1_deq[3:2]),
    .io_deq_bits_loadDependency_0(i_p1_deq[1:0])
  );

  // ---- PipeWithFlush_6: STAGES=1 载荷 55 位 / 7 字段 ----
  logic p2_enq_valid;
  logic [54:0] p2_enq;
  wire  [54:0] g_p2_deq, i_p2_deq;
  wire  g_p2_dv, i_p2_dv;
  logic [54:0] p2_ones, p2_zeros;
  int   p2_checks, p2_dv1, p2_dv0, p2_enq1;
  PipeWithFlush_6 u_g_p2 (
    .clock(clock),
    .reset(reset),
    .io_enq_valid(p2_enq_valid),
    .io_enq_bits_fuType(p2_enq[54:20]),
    .io_enq_bits_pdest(p2_enq[19:12]),
    .io_enq_bits_fpWen(p2_enq[11]),
    .io_enq_bits_vecWen(p2_enq[10]),
    .io_enq_bits_v0Wen(p2_enq[9]),
    .io_enq_bits_robIdx_flag(p2_enq[8]),
    .io_enq_bits_robIdx_value(p2_enq[7:0]),
    .io_deq_valid(g_p2_dv),
    .io_deq_bits_fuType(g_p2_deq[54:20]),
    .io_deq_bits_pdest(g_p2_deq[19:12]),
    .io_deq_bits_fpWen(g_p2_deq[11]),
    .io_deq_bits_vecWen(g_p2_deq[10]),
    .io_deq_bits_v0Wen(g_p2_deq[9]),
    .io_deq_bits_robIdx_flag(g_p2_deq[8]),
    .io_deq_bits_robIdx_value(g_p2_deq[7:0])
  );
  PipeWithFlush_6_xs u_i_p2 (
    .clock(clock),
    .reset(reset),
    .io_enq_valid(p2_enq_valid),
    .io_enq_bits_fuType(p2_enq[54:20]),
    .io_enq_bits_pdest(p2_enq[19:12]),
    .io_enq_bits_fpWen(p2_enq[11]),
    .io_enq_bits_vecWen(p2_enq[10]),
    .io_enq_bits_v0Wen(p2_enq[9]),
    .io_enq_bits_robIdx_flag(p2_enq[8]),
    .io_enq_bits_robIdx_value(p2_enq[7:0]),
    .io_deq_valid(i_p2_dv),
    .io_deq_bits_fuType(i_p2_deq[54:20]),
    .io_deq_bits_pdest(i_p2_deq[19:12]),
    .io_deq_bits_fpWen(i_p2_deq[11]),
    .io_deq_bits_vecWen(i_p2_deq[10]),
    .io_deq_bits_v0Wen(i_p2_deq[9]),
    .io_deq_bits_robIdx_flag(i_p2_deq[8]),
    .io_deq_bits_robIdx_value(i_p2_deq[7:0])
  );

  // ---- PipeWithFlush_7: STAGES=2 载荷 55 位 / 7 字段 ----
  logic p3_enq_valid;
  logic [54:0] p3_enq;
  wire  [54:0] g_p3_deq, i_p3_deq;
  wire  g_p3_dv, i_p3_dv;
  logic [54:0] p3_ones, p3_zeros;
  int   p3_checks, p3_dv1, p3_dv0, p3_enq1;
  int   p3_red;
  int   p3_og [1];
  PipeWithFlush_7 u_g_p3 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_og0Fail(fl_og[0]),
    .io_enq_valid(p3_enq_valid),
    .io_enq_bits_fuType(p3_enq[54:20]),
    .io_enq_bits_pdest(p3_enq[19:12]),
    .io_enq_bits_fpWen(p3_enq[11]),
    .io_enq_bits_vecWen(p3_enq[10]),
    .io_enq_bits_v0Wen(p3_enq[9]),
    .io_enq_bits_robIdx_flag(p3_enq[8]),
    .io_enq_bits_robIdx_value(p3_enq[7:0]),
    .io_deq_valid(g_p3_dv),
    .io_deq_bits_fuType(g_p3_deq[54:20]),
    .io_deq_bits_pdest(g_p3_deq[19:12]),
    .io_deq_bits_fpWen(g_p3_deq[11]),
    .io_deq_bits_vecWen(g_p3_deq[10]),
    .io_deq_bits_v0Wen(g_p3_deq[9]),
    .io_deq_bits_robIdx_flag(g_p3_deq[8]),
    .io_deq_bits_robIdx_value(g_p3_deq[7:0])
  );
  PipeWithFlush_7_xs u_i_p3 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_og0Fail(fl_og[0]),
    .io_enq_valid(p3_enq_valid),
    .io_enq_bits_fuType(p3_enq[54:20]),
    .io_enq_bits_pdest(p3_enq[19:12]),
    .io_enq_bits_fpWen(p3_enq[11]),
    .io_enq_bits_vecWen(p3_enq[10]),
    .io_enq_bits_v0Wen(p3_enq[9]),
    .io_enq_bits_robIdx_flag(p3_enq[8]),
    .io_enq_bits_robIdx_value(p3_enq[7:0]),
    .io_deq_valid(i_p3_dv),
    .io_deq_bits_fuType(i_p3_deq[54:20]),
    .io_deq_bits_pdest(i_p3_deq[19:12]),
    .io_deq_bits_fpWen(i_p3_deq[11]),
    .io_deq_bits_vecWen(i_p3_deq[10]),
    .io_deq_bits_v0Wen(i_p3_deq[9]),
    .io_deq_bits_robIdx_flag(i_p3_deq[8]),
    .io_deq_bits_robIdx_value(i_p3_deq[7:0])
  );

  // ---- PipeWithFlush_8: STAGES=0 载荷 46 位 / 5 字段 ----
  logic p4_enq_valid;
  logic [45:0] p4_enq;
  wire  [45:0] g_p4_deq, i_p4_deq;
  wire  g_p4_dv, i_p4_dv;
  logic [45:0] p4_ones, p4_zeros;
  int   p4_checks, p4_dv1, p4_dv0, p4_enq1;
  PipeWithFlush_8 u_g_p4 (
    .io_enq_valid(p4_enq_valid),
    .io_enq_bits_fuType(p4_enq[45:11]),
    .io_enq_bits_pdest(p4_enq[10:3]),
    .io_enq_bits_fpWen(p4_enq[2]),
    .io_enq_bits_vecWen(p4_enq[1]),
    .io_enq_bits_v0Wen(p4_enq[0]),
    .io_deq_valid(g_p4_dv),
    .io_deq_bits_fuType(g_p4_deq[45:11]),
    .io_deq_bits_pdest(g_p4_deq[10:3]),
    .io_deq_bits_fpWen(g_p4_deq[2]),
    .io_deq_bits_vecWen(g_p4_deq[1]),
    .io_deq_bits_v0Wen(g_p4_deq[0])
  );
  PipeWithFlush_8_xs u_i_p4 (
    .io_enq_valid(p4_enq_valid),
    .io_enq_bits_fuType(p4_enq[45:11]),
    .io_enq_bits_pdest(p4_enq[10:3]),
    .io_enq_bits_fpWen(p4_enq[2]),
    .io_enq_bits_vecWen(p4_enq[1]),
    .io_enq_bits_v0Wen(p4_enq[0]),
    .io_deq_valid(i_p4_dv),
    .io_deq_bits_fuType(i_p4_deq[45:11]),
    .io_deq_bits_pdest(i_p4_deq[10:3]),
    .io_deq_bits_fpWen(i_p4_deq[2]),
    .io_deq_bits_vecWen(i_p4_deq[1]),
    .io_deq_bits_v0Wen(i_p4_deq[0])
  );

  // ---- PipeWithFlush_9: STAGES=3 载荷 55 位 / 7 字段 ----
  logic p5_enq_valid;
  logic [54:0] p5_enq;
  wire  [54:0] g_p5_deq, i_p5_deq;
  wire  g_p5_dv, i_p5_dv;
  logic [54:0] p5_ones, p5_zeros;
  int   p5_checks, p5_dv1, p5_dv0, p5_enq1;
  int   p5_red;
  int   p5_og [2];
  PipeWithFlush_9 u_g_p5 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_og0Fail(fl_og[0]),
    .io_flush_og1Fail(fl_og[1]),
    .io_enq_valid(p5_enq_valid),
    .io_enq_bits_fuType(p5_enq[54:20]),
    .io_enq_bits_pdest(p5_enq[19:12]),
    .io_enq_bits_fpWen(p5_enq[11]),
    .io_enq_bits_vecWen(p5_enq[10]),
    .io_enq_bits_v0Wen(p5_enq[9]),
    .io_enq_bits_robIdx_flag(p5_enq[8]),
    .io_enq_bits_robIdx_value(p5_enq[7:0]),
    .io_deq_valid(g_p5_dv),
    .io_deq_bits_fuType(g_p5_deq[54:20]),
    .io_deq_bits_pdest(g_p5_deq[19:12]),
    .io_deq_bits_fpWen(g_p5_deq[11]),
    .io_deq_bits_vecWen(g_p5_deq[10]),
    .io_deq_bits_v0Wen(g_p5_deq[9]),
    .io_deq_bits_robIdx_flag(g_p5_deq[8]),
    .io_deq_bits_robIdx_value(g_p5_deq[7:0])
  );
  PipeWithFlush_9_xs u_i_p5 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_og0Fail(fl_og[0]),
    .io_flush_og1Fail(fl_og[1]),
    .io_enq_valid(p5_enq_valid),
    .io_enq_bits_fuType(p5_enq[54:20]),
    .io_enq_bits_pdest(p5_enq[19:12]),
    .io_enq_bits_fpWen(p5_enq[11]),
    .io_enq_bits_vecWen(p5_enq[10]),
    .io_enq_bits_v0Wen(p5_enq[9]),
    .io_enq_bits_robIdx_flag(p5_enq[8]),
    .io_enq_bits_robIdx_value(p5_enq[7:0]),
    .io_deq_valid(i_p5_dv),
    .io_deq_bits_fuType(i_p5_deq[54:20]),
    .io_deq_bits_pdest(i_p5_deq[19:12]),
    .io_deq_bits_fpWen(i_p5_deq[11]),
    .io_deq_bits_vecWen(i_p5_deq[10]),
    .io_deq_bits_v0Wen(i_p5_deq[9]),
    .io_deq_bits_robIdx_flag(i_p5_deq[8]),
    .io_deq_bits_robIdx_value(i_p5_deq[7:0])
  );

  // ---- PipeWithFlush_10: STAGES=1 载荷 18 位 / 4 字段 ----
  logic p6_enq_valid;
  logic [17:0] p6_enq;
  wire  [17:0] g_p6_deq, i_p6_deq;
  wire  g_p6_dv, i_p6_dv;
  logic [17:0] p6_ones, p6_zeros;
  int   p6_checks, p6_dv1, p6_dv0, p6_enq1;
  PipeWithFlush_10 u_g_p6 (
    .clock(clock),
    .reset(reset),
    .io_enq_valid(p6_enq_valid),
    .io_enq_bits_pdest(p6_enq[17:10]),
    .io_enq_bits_fpWen(p6_enq[9]),
    .io_enq_bits_robIdx_flag(p6_enq[8]),
    .io_enq_bits_robIdx_value(p6_enq[7:0]),
    .io_deq_valid(g_p6_dv),
    .io_deq_bits_pdest(g_p6_deq[17:10]),
    .io_deq_bits_fpWen(g_p6_deq[9]),
    .io_deq_bits_robIdx_flag(g_p6_deq[8]),
    .io_deq_bits_robIdx_value(g_p6_deq[7:0])
  );
  PipeWithFlush_10_xs u_i_p6 (
    .clock(clock),
    .reset(reset),
    .io_enq_valid(p6_enq_valid),
    .io_enq_bits_pdest(p6_enq[17:10]),
    .io_enq_bits_fpWen(p6_enq[9]),
    .io_enq_bits_robIdx_flag(p6_enq[8]),
    .io_enq_bits_robIdx_value(p6_enq[7:0]),
    .io_deq_valid(i_p6_dv),
    .io_deq_bits_pdest(i_p6_deq[17:10]),
    .io_deq_bits_fpWen(i_p6_deq[9]),
    .io_deq_bits_robIdx_flag(i_p6_deq[8]),
    .io_deq_bits_robIdx_value(i_p6_deq[7:0])
  );

  // ---- PipeWithFlush_11: STAGES=3 载荷 18 位 / 4 字段 ----
  logic p7_enq_valid;
  logic [17:0] p7_enq;
  wire  [17:0] g_p7_deq, i_p7_deq;
  wire  g_p7_dv, i_p7_dv;
  logic [17:0] p7_ones, p7_zeros;
  int   p7_checks, p7_dv1, p7_dv0, p7_enq1;
  int   p7_red;
  int   p7_og [2];
  PipeWithFlush_11 u_g_p7 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_og0Fail(fl_og[0]),
    .io_flush_og1Fail(fl_og[1]),
    .io_enq_valid(p7_enq_valid),
    .io_enq_bits_pdest(p7_enq[17:10]),
    .io_enq_bits_fpWen(p7_enq[9]),
    .io_enq_bits_robIdx_flag(p7_enq[8]),
    .io_enq_bits_robIdx_value(p7_enq[7:0]),
    .io_deq_valid(g_p7_dv),
    .io_deq_bits_pdest(g_p7_deq[17:10]),
    .io_deq_bits_fpWen(g_p7_deq[9]),
    .io_deq_bits_robIdx_flag(g_p7_deq[8]),
    .io_deq_bits_robIdx_value(g_p7_deq[7:0])
  );
  PipeWithFlush_11_xs u_i_p7 (
    .clock(clock),
    .reset(reset),
    .io_flush_redirect_valid(fl_red_valid),
    .io_flush_redirect_bits_robIdx_flag(fl_red_flag),
    .io_flush_redirect_bits_robIdx_value(fl_red_value),
    .io_flush_redirect_bits_level(fl_red_level),
    .io_flush_og0Fail(fl_og[0]),
    .io_flush_og1Fail(fl_og[1]),
    .io_enq_valid(p7_enq_valid),
    .io_enq_bits_pdest(p7_enq[17:10]),
    .io_enq_bits_fpWen(p7_enq[9]),
    .io_enq_bits_robIdx_flag(p7_enq[8]),
    .io_enq_bits_robIdx_value(p7_enq[7:0]),
    .io_deq_valid(i_p7_dv),
    .io_deq_bits_pdest(i_p7_deq[17:10]),
    .io_deq_bits_fpWen(i_p7_deq[9]),
    .io_deq_bits_robIdx_flag(i_p7_deq[8]),
    .io_deq_bits_robIdx_value(i_p7_deq[7:0])
  );


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    // 热身窗口内不冲刷：冲刷会打断 valid 链，数据级就灌不满（见文件头）
    if (cycle < WARMUP) begin
      fl_red_valid = 1'b0; fl_red_level = 1'b0;
      fl_red_flag  = 1'b0; fl_red_value = '0;
      for (int j = 0; j < 3; j++) fl_ldc[j] = 1'b0;
      for (int k = 0; k < 2; k++) fl_og[k]  = 1'b0;
    end else begin
      fl_red_valid = ($urandom_range(0, 7) == 0);            // 1/8
      fl_red_level = ($urandom_range(0, 1) == 1);
      fl_red_flag  = 1'($urandom);
      // 一半落在窄区间：robIdx 比较要真的命中，靠全随机 8 位撞不上
      fl_red_value = ($urandom_range(0, 1) == 1) ? 8'($urandom_range(0, 7))
                                                 : 8'($urandom);
      for (int j = 0; j < 3; j++) fl_ldc[j] = ($urandom_range(0, 7) == 0);
      for (int k = 0; k < 2; k++) fl_og[k]  = ($urandom_range(0, 15) == 0);
    end
    p0_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p0_enq = '0;
      1:       p0_enq = '1;
      default: for (int b = 0; b < 50; b++) p0_enq[b] = 1'($urandom);
    endcase
    p1_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p1_enq = '0;
      1:       p1_enq = '1;
      default: for (int b = 0; b < 59; b++) p1_enq[b] = 1'($urandom);
    endcase
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      p1_enq[6 +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};
    p2_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p2_enq = '0;
      1:       p2_enq = '1;
      default: for (int b = 0; b < 55; b++) p2_enq[b] = 1'($urandom);
    endcase
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      p2_enq[0 +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};
    p3_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p3_enq = '0;
      1:       p3_enq = '1;
      default: for (int b = 0; b < 55; b++) p3_enq[b] = 1'($urandom);
    endcase
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      p3_enq[0 +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};
    p4_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p4_enq = '0;
      1:       p4_enq = '1;
      default: for (int b = 0; b < 46; b++) p4_enq[b] = 1'($urandom);
    endcase
    p5_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p5_enq = '0;
      1:       p5_enq = '1;
      default: for (int b = 0; b < 55; b++) p5_enq[b] = 1'($urandom);
    endcase
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      p5_enq[0 +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};
    p6_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p6_enq = '0;
      1:       p6_enq = '1;
      default: for (int b = 0; b < 18; b++) p6_enq[b] = 1'($urandom);
    endcase
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      p6_enq[0 +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};
    p7_enq_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       p7_enq = '0;
      1:       p7_enq = '1;
      default: for (int b = 0; b < 18; b++) p7_enq[b] = 1'($urandom);
    endcase
    // robIdx 一半落在窄区间，好让重定向比较真的命中
    if ($urandom_range(0, 1) == 1)
      p7_enq[0 +: 9] = {1'($urandom), 8'($urandom_range(0, 7))};
  endtask

  task automatic check_outputs();
    if (!$isunknown({g_p0_dv, g_p0_deq})) begin
      checks++; p0_checks++;
      p0_ones  |= g_p0_deq;
      p0_zeros |= ~g_p0_deq;
      if (g_p0_dv) p0_dv1++; else p0_dv0++;
      if (p0_enq_valid) p0_enq1++;
      if ({g_p0_dv, g_p0_deq} !== {i_p0_dv, i_p0_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush g=%b/%0h i=%b/%0h",
                   $time, g_p0_dv, g_p0_deq, i_p0_dv, i_p0_deq);
      end
    end
    if (!$isunknown({g_p1_dv, g_p1_deq})) begin
      checks++; p1_checks++;
      p1_ones  |= g_p1_deq;
      p1_zeros |= ~g_p1_deq;
      if (g_p1_dv) p1_dv1++; else p1_dv0++;
      if (p1_enq_valid) p1_enq1++;
      if (fl_red_valid) p1_red++;
      for (int k = 0; k < 1; k++) if (fl_og[k]) p1_og[k]++;
      for (int j = 0; j < 3; j++) if (fl_ldc[j]) p1_ldc[j]++;
      if ({g_p1_dv, g_p1_deq} !== {i_p1_dv, i_p1_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_1 g=%b/%0h i=%b/%0h",
                   $time, g_p1_dv, g_p1_deq, i_p1_dv, i_p1_deq);
      end
    end
    if (!$isunknown({g_p2_dv, g_p2_deq})) begin
      checks++; p2_checks++;
      p2_ones  |= g_p2_deq;
      p2_zeros |= ~g_p2_deq;
      if (g_p2_dv) p2_dv1++; else p2_dv0++;
      if (p2_enq_valid) p2_enq1++;
      if ({g_p2_dv, g_p2_deq} !== {i_p2_dv, i_p2_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_6 g=%b/%0h i=%b/%0h",
                   $time, g_p2_dv, g_p2_deq, i_p2_dv, i_p2_deq);
      end
    end
    if (!$isunknown({g_p3_dv, g_p3_deq})) begin
      checks++; p3_checks++;
      p3_ones  |= g_p3_deq;
      p3_zeros |= ~g_p3_deq;
      if (g_p3_dv) p3_dv1++; else p3_dv0++;
      if (p3_enq_valid) p3_enq1++;
      if (fl_red_valid) p3_red++;
      for (int k = 0; k < 1; k++) if (fl_og[k]) p3_og[k]++;
      if ({g_p3_dv, g_p3_deq} !== {i_p3_dv, i_p3_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_7 g=%b/%0h i=%b/%0h",
                   $time, g_p3_dv, g_p3_deq, i_p3_dv, i_p3_deq);
      end
    end
    if (!$isunknown({g_p4_dv, g_p4_deq})) begin
      checks++; p4_checks++;
      p4_ones  |= g_p4_deq;
      p4_zeros |= ~g_p4_deq;
      if (g_p4_dv) p4_dv1++; else p4_dv0++;
      if (p4_enq_valid) p4_enq1++;
      if ({g_p4_dv, g_p4_deq} !== {i_p4_dv, i_p4_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_8 g=%b/%0h i=%b/%0h",
                   $time, g_p4_dv, g_p4_deq, i_p4_dv, i_p4_deq);
      end
    end
    if (!$isunknown({g_p5_dv, g_p5_deq})) begin
      checks++; p5_checks++;
      p5_ones  |= g_p5_deq;
      p5_zeros |= ~g_p5_deq;
      if (g_p5_dv) p5_dv1++; else p5_dv0++;
      if (p5_enq_valid) p5_enq1++;
      if (fl_red_valid) p5_red++;
      for (int k = 0; k < 2; k++) if (fl_og[k]) p5_og[k]++;
      if ({g_p5_dv, g_p5_deq} !== {i_p5_dv, i_p5_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_9 g=%b/%0h i=%b/%0h",
                   $time, g_p5_dv, g_p5_deq, i_p5_dv, i_p5_deq);
      end
    end
    if (!$isunknown({g_p6_dv, g_p6_deq})) begin
      checks++; p6_checks++;
      p6_ones  |= g_p6_deq;
      p6_zeros |= ~g_p6_deq;
      if (g_p6_dv) p6_dv1++; else p6_dv0++;
      if (p6_enq_valid) p6_enq1++;
      if ({g_p6_dv, g_p6_deq} !== {i_p6_dv, i_p6_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_10 g=%b/%0h i=%b/%0h",
                   $time, g_p6_dv, g_p6_deq, i_p6_dv, i_p6_deq);
      end
    end
    if (!$isunknown({g_p7_dv, g_p7_deq})) begin
      checks++; p7_checks++;
      p7_ones  |= g_p7_deq;
      p7_zeros |= ~g_p7_deq;
      if (g_p7_dv) p7_dv1++; else p7_dv0++;
      if (p7_enq_valid) p7_enq1++;
      if (fl_red_valid) p7_red++;
      for (int k = 0; k < 2; k++) if (fl_og[k]) p7_og[k]++;
      if ({g_p7_dv, g_p7_deq} !== {i_p7_dv, i_p7_deq}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH PipeWithFlush_11 g=%b/%0h i=%b/%0h",
                   $time, g_p7_dv, g_p7_deq, i_p7_dv, i_p7_deq);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    fl_red_valid = 0; fl_red_level = 0; fl_red_flag = 0; fl_red_value = '0;
    for (int j = 0; j < 3; j++) fl_ldc[j] = 0;
    for (int k = 0; k < 2; k++) fl_og[k] = 0;
    p0_enq_valid = 0; p0_enq = '0; p0_ones = '0; p0_zeros = '0;
    p0_checks = 0; p0_dv1 = 0; p0_dv0 = 0; p0_enq1 = 0;
    p1_enq_valid = 0; p1_enq = '0; p1_ones = '0; p1_zeros = '0;
    p1_checks = 0; p1_dv1 = 0; p1_dv0 = 0; p1_enq1 = 0;
    p1_red = 0; for (int k = 0; k < 1; k++) p1_og[k] = 0;
    for (int j = 0; j < 3; j++) p1_ldc[j] = 0;
    p2_enq_valid = 0; p2_enq = '0; p2_ones = '0; p2_zeros = '0;
    p2_checks = 0; p2_dv1 = 0; p2_dv0 = 0; p2_enq1 = 0;
    p3_enq_valid = 0; p3_enq = '0; p3_ones = '0; p3_zeros = '0;
    p3_checks = 0; p3_dv1 = 0; p3_dv0 = 0; p3_enq1 = 0;
    p3_red = 0; for (int k = 0; k < 1; k++) p3_og[k] = 0;
    p4_enq_valid = 0; p4_enq = '0; p4_ones = '0; p4_zeros = '0;
    p4_checks = 0; p4_dv1 = 0; p4_dv0 = 0; p4_enq1 = 0;
    p5_enq_valid = 0; p5_enq = '0; p5_ones = '0; p5_zeros = '0;
    p5_checks = 0; p5_dv1 = 0; p5_dv0 = 0; p5_enq1 = 0;
    p5_red = 0; for (int k = 0; k < 2; k++) p5_og[k] = 0;
    p6_enq_valid = 0; p6_enq = '0; p6_ones = '0; p6_zeros = '0;
    p6_checks = 0; p6_dv1 = 0; p6_dv0 = 0; p6_enq1 = 0;
    p7_enq_valid = 0; p7_enq = '0; p7_ones = '0; p7_zeros = '0;
    p7_checks = 0; p7_dv1 = 0; p7_dv0 = 0; p7_enq1 = 0;
    p7_red = 0; for (int k = 0; k < 2; k++) p7_og[k] = 0;
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      // 热身窗口内两侧无复位数据寄存器各自带着独立随机初值，不可比（见文件头）
      if (cycle >= WARMUP) check_outputs();   // 输出在 posedge 变，negedge 稳定
      drive_random_inputs();
      @(posedge clock);
      cycle++;
      // 复位脉冲只清 valid 链（数据级 golden 就没有复位），热身窗口内不打
      if (cycle >= WARMUP && $urandom_range(0, 4999) == 0) begin
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("PipeWithFlush family checks=%0d errors=%0d", checks, errors);
    $display("  PipeWithFlush: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/50 zeros=%0d/50",
             p0_checks, p0_dv1, p0_dv0, p0_enq1, p0_enq1 - p0_dv1,
             $countones(p0_ones), $countones(p0_zeros));
    cov_fail += cov_short("PipeWithFlush checks", p0_checks)
              + cov_short("PipeWithFlush deq_valid=1", p0_dv1)
              + cov_short("PipeWithFlush deq_valid=0", p0_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p0_ones | 50'h0) !== '1) || (p0_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p0_ones, p0_zeros); cov_fail++;
    end
    $display("  PipeWithFlush_1: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/59 zeros=%0d/59",
             p1_checks, p1_dv1, p1_dv0, p1_enq1, p1_enq1 - p1_dv1,
             $countones(p1_ones), $countones(p1_zeros));
    cov_fail += cov_short("PipeWithFlush_1 checks", p1_checks)
              + cov_short("PipeWithFlush_1 deq_valid=1", p1_dv1)
              + cov_short("PipeWithFlush_1 deq_valid=0", p1_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p1_ones | 59'h15) !== '1) || (p1_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_1 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p1_ones, p1_zeros); cov_fail++;
    end
    // ★正向断言，不是豁免★：loadDependency 每路最低位是老化左移填进来的 0，
    // 在输出上必须**从未**出现过 1。老化少移一位、或第 1 级误加了老化，这里立刻红。
    if ((p1_ones & 59'h15) != '0) begin
      $display("STRUCTURAL FAIL: PipeWithFlush_1 loadDependency 老化位竟然出现过 1 (ones=%0h & mask=59'h15)",
               p1_ones); cov_fail++;
    end else
      $display("  PipeWithFlush_1: loadDependency 老化恒零位 59'h15 全程未出现 1（老化左移坐实）");
    cov_fail += cov_short("PipeWithFlush_1 redirect_valid=1", p1_red)
              + cov_short("PipeWithFlush_1 被冲掉的条目(enq1-deq1)", p1_enq1 - p1_dv1);
    for (int k = 0; k < 1; k++)
      cov_fail += cov_short($sformatf("PipeWithFlush_1 og%0dFail=1", k), p1_og[k]);
    for (int j = 0; j < 3; j++)
      cov_fail += cov_short($sformatf("PipeWithFlush_1 ldCancel_%0d=1", j), p1_ldc[j]);
    $display("  PipeWithFlush_6: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/55 zeros=%0d/55",
             p2_checks, p2_dv1, p2_dv0, p2_enq1, p2_enq1 - p2_dv1,
             $countones(p2_ones), $countones(p2_zeros));
    cov_fail += cov_short("PipeWithFlush_6 checks", p2_checks)
              + cov_short("PipeWithFlush_6 deq_valid=1", p2_dv1)
              + cov_short("PipeWithFlush_6 deq_valid=0", p2_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p2_ones | 55'h0) !== '1) || (p2_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_6 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p2_ones, p2_zeros); cov_fail++;
    end
    $display("  PipeWithFlush_7: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/55 zeros=%0d/55",
             p3_checks, p3_dv1, p3_dv0, p3_enq1, p3_enq1 - p3_dv1,
             $countones(p3_ones), $countones(p3_zeros));
    cov_fail += cov_short("PipeWithFlush_7 checks", p3_checks)
              + cov_short("PipeWithFlush_7 deq_valid=1", p3_dv1)
              + cov_short("PipeWithFlush_7 deq_valid=0", p3_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p3_ones | 55'h0) !== '1) || (p3_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_7 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p3_ones, p3_zeros); cov_fail++;
    end
    cov_fail += cov_short("PipeWithFlush_7 redirect_valid=1", p3_red)
              + cov_short("PipeWithFlush_7 被冲掉的条目(enq1-deq1)", p3_enq1 - p3_dv1);
    for (int k = 0; k < 1; k++)
      cov_fail += cov_short($sformatf("PipeWithFlush_7 og%0dFail=1", k), p3_og[k]);
    $display("  PipeWithFlush_8: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/46 zeros=%0d/46",
             p4_checks, p4_dv1, p4_dv0, p4_enq1, p4_enq1 - p4_dv1,
             $countones(p4_ones), $countones(p4_zeros));
    cov_fail += cov_short("PipeWithFlush_8 checks", p4_checks)
              + cov_short("PipeWithFlush_8 deq_valid=1", p4_dv1)
              + cov_short("PipeWithFlush_8 deq_valid=0", p4_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p4_ones | 46'h0) !== '1) || (p4_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_8 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p4_ones, p4_zeros); cov_fail++;
    end
    $display("  PipeWithFlush_9: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/55 zeros=%0d/55",
             p5_checks, p5_dv1, p5_dv0, p5_enq1, p5_enq1 - p5_dv1,
             $countones(p5_ones), $countones(p5_zeros));
    cov_fail += cov_short("PipeWithFlush_9 checks", p5_checks)
              + cov_short("PipeWithFlush_9 deq_valid=1", p5_dv1)
              + cov_short("PipeWithFlush_9 deq_valid=0", p5_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p5_ones | 55'h0) !== '1) || (p5_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_9 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p5_ones, p5_zeros); cov_fail++;
    end
    cov_fail += cov_short("PipeWithFlush_9 redirect_valid=1", p5_red)
              + cov_short("PipeWithFlush_9 被冲掉的条目(enq1-deq1)", p5_enq1 - p5_dv1);
    for (int k = 0; k < 2; k++)
      cov_fail += cov_short($sformatf("PipeWithFlush_9 og%0dFail=1", k), p5_og[k]);
    $display("  PipeWithFlush_10: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/18 zeros=%0d/18",
             p6_checks, p6_dv1, p6_dv0, p6_enq1, p6_enq1 - p6_dv1,
             $countones(p6_ones), $countones(p6_zeros));
    cov_fail += cov_short("PipeWithFlush_10 checks", p6_checks)
              + cov_short("PipeWithFlush_10 deq_valid=1", p6_dv1)
              + cov_short("PipeWithFlush_10 deq_valid=0", p6_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p6_ones | 18'h0) !== '1) || (p6_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_10 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p6_ones, p6_zeros); cov_fail++;
    end
    $display("  PipeWithFlush_11: checks=%0d deq1=%0d deq0=%0d enq1=%0d dropped=%0d ones=%0d/18 zeros=%0d/18",
             p7_checks, p7_dv1, p7_dv0, p7_enq1, p7_enq1 - p7_dv1,
             $countones(p7_ones), $countones(p7_zeros));
    cov_fail += cov_short("PipeWithFlush_11 checks", p7_checks)
              + cov_short("PipeWithFlush_11 deq_valid=1", p7_dv1)
              + cov_short("PipeWithFlush_11 deq_valid=0", p7_dv0);
    // 恒零位（loadDependency 老化填进来的 0）单独处理，见下
    if (((p7_ones | 18'h0) !== '1) || (p7_zeros !== '1)) begin
      $display("COVERAGE FAIL: PipeWithFlush_11 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               p7_ones, p7_zeros); cov_fail++;
    end
    cov_fail += cov_short("PipeWithFlush_11 redirect_valid=1", p7_red)
              + cov_short("PipeWithFlush_11 被冲掉的条目(enq1-deq1)", p7_enq1 - p7_dv1);
    for (int k = 0; k < 2; k++)
      cov_fail += cov_short($sformatf("PipeWithFlush_11 og%0dFail=1", k), p7_og[k]);
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
