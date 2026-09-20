// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// DelayNWithValid 家族 16 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_DelayNWithValid_core 设不同 WIDTH / STAGES / VALID_CHAIN）。
// 被测语义：valid 打一拍 + n 级"只在使能时更新"的数据寄存器；输入无效时输出保持。
// 家族四种形状都在场（缺一种这个 tb 就证不到那一档）：
//   STAGES=0 直通（无 clock/reset/in_valid）：DelayNWithValid_4 DelayNWithValid_7
//   valid 链长 0（无 reset）：DelayNWithValid_52 DelayNWithValid_55 DelayNWithValid_103 DelayNWithValid_152 DelayNWithValid_155
//   有 out_valid（整条 valid 链被读）：DelayNWithValid_2 DelayNWithValid_3 DelayNWithValid_200 DelayNWithValid_202 DelayNWithValid_203
//   其余为 V=STAGES-1。
// 只有 valid 寄存器带异步复位，数据寄存器无复位，故用 $isunknown(golden 输出)
//   跳过尚未灌满的拍。
// ★热身窗口 WARMUP 不是为了绕过失配，是「无复位数据链」的定义域★
//   golden 的 data/res_bits 与重写侧 u_core.g_chain.data_q[] 是**不同的寄存器**：
//   +vcs+initreg+random 给它们各自独立的随机初值，链灌满之前输出的是这些初值，
//   本来就不该相等（$isunknown 拦不住 —— 随机初值不是 X）。
//   而本家族的数据级是**使能门控**的（第 k 级要等 in_valid 延迟 k 拍才更新），
//   所以光"前几拍不比"还不够 —— 那几拍里使能可能压根没拉高过，链还是空的。
//   做法是**确定性灌注**：热身窗口内把所有变体的 io_in_valid 强制拉 1，
//   连续 STAGES 拍之后每一级都装着 tb 驱动的数据（两侧逐级同源，归纳可证相等），
//   窗口一过立刻开始逐拍比，此后**一拍都不豁免**。
//   WARMUP = 家族最大级数 + 1 = 4 拍（20 万拍里扣 4 拍，覆盖闸不受影响）。
// 激励：io_in_valid 按 50% 随机（既有连续有效也有长时间无效，才测得到"保持"），
//   载荷逐位随机并混入全 0 / 全 1；reset 偶尔异步脉冲一拍。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) in_valid=1 与 in_valid=0
//   各 >= COV_MIN；(3) 输出**保持不变**（相邻拍相等）与**发生变化**各 >= COV_MIN
//   —— 只测流动不测保持的 tb 会在这里被判 FAIL；(4) 每个载荷位都见过 1 和 0；
//   (5) 有 out_valid 的变体，out_valid 的 0 / 1 各 >= COV_MIN。
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

  // ---- DelayNWithValid: 载荷 50 位 / 1 字段 / STAGES=2 / V=1 ----
  logic dv0_in_valid;
  logic [49:0] dv0_in;
  wire  [49:0] g_dv0_out, i_dv0_out;
  logic [49:0] dv0_ones, dv0_zeros, dv0_prev;
  int   dv0_checks, dv0_vld, dv0_idle, dv0_hold, dv0_move;
  DelayNWithValid u_g_dv0 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv0_in_valid),
    .io_in_bits(dv0_in[49:0]),
    .io_out_bits(g_dv0_out[49:0])
  );
  DelayNWithValid_xs u_i_dv0 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv0_in_valid),
    .io_in_bits(dv0_in[49:0]),
    .io_out_bits(i_dv0_out[49:0])
  );

  // ---- DelayNWithValid_1: 载荷 60 位 / 19 字段 / STAGES=2 / V=1 ----
  logic dv1_in_valid;
  logic [59:0] dv1_in;
  wire  [59:0] g_dv1_out, i_dv1_out;
  logic [59:0] dv1_ones, dv1_zeros, dv1_prev;
  int   dv1_checks, dv1_vld, dv1_idle, dv1_hold, dv1_move;
  DelayNWithValid_1 u_g_dv1 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv1_in_valid),
    .io_in_bits_isCall(dv1_in[59]),
    .io_in_bits_isRet(dv1_in[58]),
    .io_in_bits_isJalr(dv1_in[57]),
    .io_in_bits_valid(dv1_in[56]),
    .io_in_bits_brSlots_0_offset(dv1_in[55:52]),
    .io_in_bits_brSlots_0_sharing(dv1_in[51]),
    .io_in_bits_brSlots_0_valid(dv1_in[50]),
    .io_in_bits_brSlots_0_lower(dv1_in[49:38]),
    .io_in_bits_brSlots_0_tarStat(dv1_in[37:36]),
    .io_in_bits_tailSlot_offset(dv1_in[35:32]),
    .io_in_bits_tailSlot_sharing(dv1_in[31]),
    .io_in_bits_tailSlot_valid(dv1_in[30]),
    .io_in_bits_tailSlot_lower(dv1_in[29:10]),
    .io_in_bits_tailSlot_tarStat(dv1_in[9:8]),
    .io_in_bits_pftAddr(dv1_in[7:4]),
    .io_in_bits_carry(dv1_in[3]),
    .io_in_bits_last_may_be_rvi_call(dv1_in[2]),
    .io_in_bits_strong_bias_0(dv1_in[1]),
    .io_in_bits_strong_bias_1(dv1_in[0]),
    .io_out_bits_isCall(g_dv1_out[59]),
    .io_out_bits_isRet(g_dv1_out[58]),
    .io_out_bits_isJalr(g_dv1_out[57]),
    .io_out_bits_valid(g_dv1_out[56]),
    .io_out_bits_brSlots_0_offset(g_dv1_out[55:52]),
    .io_out_bits_brSlots_0_sharing(g_dv1_out[51]),
    .io_out_bits_brSlots_0_valid(g_dv1_out[50]),
    .io_out_bits_brSlots_0_lower(g_dv1_out[49:38]),
    .io_out_bits_brSlots_0_tarStat(g_dv1_out[37:36]),
    .io_out_bits_tailSlot_offset(g_dv1_out[35:32]),
    .io_out_bits_tailSlot_sharing(g_dv1_out[31]),
    .io_out_bits_tailSlot_valid(g_dv1_out[30]),
    .io_out_bits_tailSlot_lower(g_dv1_out[29:10]),
    .io_out_bits_tailSlot_tarStat(g_dv1_out[9:8]),
    .io_out_bits_pftAddr(g_dv1_out[7:4]),
    .io_out_bits_carry(g_dv1_out[3]),
    .io_out_bits_last_may_be_rvi_call(g_dv1_out[2]),
    .io_out_bits_strong_bias_0(g_dv1_out[1]),
    .io_out_bits_strong_bias_1(g_dv1_out[0])
  );
  DelayNWithValid_1_xs u_i_dv1 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv1_in_valid),
    .io_in_bits_isCall(dv1_in[59]),
    .io_in_bits_isRet(dv1_in[58]),
    .io_in_bits_isJalr(dv1_in[57]),
    .io_in_bits_valid(dv1_in[56]),
    .io_in_bits_brSlots_0_offset(dv1_in[55:52]),
    .io_in_bits_brSlots_0_sharing(dv1_in[51]),
    .io_in_bits_brSlots_0_valid(dv1_in[50]),
    .io_in_bits_brSlots_0_lower(dv1_in[49:38]),
    .io_in_bits_brSlots_0_tarStat(dv1_in[37:36]),
    .io_in_bits_tailSlot_offset(dv1_in[35:32]),
    .io_in_bits_tailSlot_sharing(dv1_in[31]),
    .io_in_bits_tailSlot_valid(dv1_in[30]),
    .io_in_bits_tailSlot_lower(dv1_in[29:10]),
    .io_in_bits_tailSlot_tarStat(dv1_in[9:8]),
    .io_in_bits_pftAddr(dv1_in[7:4]),
    .io_in_bits_carry(dv1_in[3]),
    .io_in_bits_last_may_be_rvi_call(dv1_in[2]),
    .io_in_bits_strong_bias_0(dv1_in[1]),
    .io_in_bits_strong_bias_1(dv1_in[0]),
    .io_out_bits_isCall(i_dv1_out[59]),
    .io_out_bits_isRet(i_dv1_out[58]),
    .io_out_bits_isJalr(i_dv1_out[57]),
    .io_out_bits_valid(i_dv1_out[56]),
    .io_out_bits_brSlots_0_offset(i_dv1_out[55:52]),
    .io_out_bits_brSlots_0_sharing(i_dv1_out[51]),
    .io_out_bits_brSlots_0_valid(i_dv1_out[50]),
    .io_out_bits_brSlots_0_lower(i_dv1_out[49:38]),
    .io_out_bits_brSlots_0_tarStat(i_dv1_out[37:36]),
    .io_out_bits_tailSlot_offset(i_dv1_out[35:32]),
    .io_out_bits_tailSlot_sharing(i_dv1_out[31]),
    .io_out_bits_tailSlot_valid(i_dv1_out[30]),
    .io_out_bits_tailSlot_lower(i_dv1_out[29:10]),
    .io_out_bits_tailSlot_tarStat(i_dv1_out[9:8]),
    .io_out_bits_pftAddr(i_dv1_out[7:4]),
    .io_out_bits_carry(i_dv1_out[3]),
    .io_out_bits_last_may_be_rvi_call(i_dv1_out[2]),
    .io_out_bits_strong_bias_0(i_dv1_out[1]),
    .io_out_bits_strong_bias_1(i_dv1_out[0])
  );

  // ---- DelayNWithValid_2: 载荷 49 位 / 2 字段 / STAGES=2 / V=2 / 有 out_valid ----
  logic dv2_in_valid;
  logic [48:0] dv2_in;
  wire  [48:0] g_dv2_out, i_dv2_out;
  wire  g_dv2_ov, i_dv2_ov;
  int   dv2_ov1, dv2_ov0;
  logic [48:0] dv2_ones, dv2_zeros, dv2_prev;
  int   dv2_checks, dv2_vld, dv2_idle, dv2_hold, dv2_move;
  DelayNWithValid_2 u_g_dv2 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv2_in_valid),
    .io_in_bits_paddr(dv2_in[48:1]),
    .io_in_bits_report_to_beu(dv2_in[0]),
    .io_out_bits_paddr(g_dv2_out[48:1]),
    .io_out_bits_report_to_beu(g_dv2_out[0]),
    .io_out_valid(g_dv2_ov)
  );
  DelayNWithValid_2_xs u_i_dv2 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv2_in_valid),
    .io_in_bits_paddr(dv2_in[48:1]),
    .io_in_bits_report_to_beu(dv2_in[0]),
    .io_out_bits_paddr(i_dv2_out[48:1]),
    .io_out_bits_report_to_beu(i_dv2_out[0]),
    .io_out_valid(i_dv2_ov)
  );

  // ---- DelayNWithValid_3: 载荷 48 位 / 1 字段 / STAGES=2 / V=2 / 有 out_valid ----
  logic dv3_in_valid;
  logic [47:0] dv3_in;
  wire  [47:0] g_dv3_out, i_dv3_out;
  wire  g_dv3_ov, i_dv3_ov;
  int   dv3_ov1, dv3_ov0;
  logic [47:0] dv3_ones, dv3_zeros, dv3_prev;
  int   dv3_checks, dv3_vld, dv3_idle, dv3_hold, dv3_move;
  DelayNWithValid_3 u_g_dv3 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv3_in_valid),
    .io_in_bits(dv3_in[47:0]),
    .io_out_bits(g_dv3_out[47:0]),
    .io_out_valid(g_dv3_ov)
  );
  DelayNWithValid_3_xs u_i_dv3 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv3_in_valid),
    .io_in_bits(dv3_in[47:0]),
    .io_out_bits(i_dv3_out[47:0]),
    .io_out_valid(i_dv3_ov)
  );

  // ---- DelayNWithValid_4: 载荷 9 位 / 1 字段 / STAGES=0 / V=0 ----
  logic dv4_in_valid;
  logic [8:0] dv4_in;
  wire  [8:0] g_dv4_out, i_dv4_out;
  logic [8:0] dv4_ones, dv4_zeros, dv4_prev;
  int   dv4_checks, dv4_vld, dv4_idle, dv4_hold, dv4_move;
  DelayNWithValid_4 u_g_dv4 (
    .io_in_bits(dv4_in[8:0]),
    .io_out_bits(g_dv4_out[8:0])
  );
  DelayNWithValid_4_xs u_i_dv4 (
    .io_in_bits(dv4_in[8:0]),
    .io_out_bits(i_dv4_out[8:0])
  );

  // ---- DelayNWithValid_7: 载荷 16 位 / 1 字段 / STAGES=0 / V=0 ----
  logic dv5_in_valid;
  logic [15:0] dv5_in;
  wire  [15:0] g_dv5_out, i_dv5_out;
  logic [15:0] dv5_ones, dv5_zeros, dv5_prev;
  int   dv5_checks, dv5_vld, dv5_idle, dv5_hold, dv5_move;
  DelayNWithValid_7 u_g_dv5 (
    .io_in_bits(dv5_in[15:0]),
    .io_out_bits(g_dv5_out[15:0])
  );
  DelayNWithValid_7_xs u_i_dv5 (
    .io_in_bits(dv5_in[15:0]),
    .io_out_bits(i_dv5_out[15:0])
  );

  // ---- DelayNWithValid_52: 载荷 4 位 / 1 字段 / STAGES=1 / V=0 ----
  logic dv6_in_valid;
  logic [3:0] dv6_in;
  wire  [3:0] g_dv6_out, i_dv6_out;
  logic [3:0] dv6_ones, dv6_zeros, dv6_prev;
  int   dv6_checks, dv6_vld, dv6_idle, dv6_hold, dv6_move;
  DelayNWithValid_52 u_g_dv6 (
    .clock(clock),
    .io_in_valid(dv6_in_valid),
    .io_in_bits(dv6_in[3:0]),
    .io_out_bits(g_dv6_out[3:0])
  );
  DelayNWithValid_52_xs u_i_dv6 (
    .clock(clock),
    .io_in_valid(dv6_in_valid),
    .io_in_bits(dv6_in[3:0]),
    .io_out_bits(i_dv6_out[3:0])
  );

  // ---- DelayNWithValid_55: 载荷 24 位 / 1 字段 / STAGES=1 / V=0 ----
  logic dv7_in_valid;
  logic [23:0] dv7_in;
  wire  [23:0] g_dv7_out, i_dv7_out;
  logic [23:0] dv7_ones, dv7_zeros, dv7_prev;
  int   dv7_checks, dv7_vld, dv7_idle, dv7_hold, dv7_move;
  DelayNWithValid_55 u_g_dv7 (
    .clock(clock),
    .io_in_valid(dv7_in_valid),
    .io_in_bits(dv7_in[23:0]),
    .io_out_bits(g_dv7_out[23:0])
  );
  DelayNWithValid_55_xs u_i_dv7 (
    .clock(clock),
    .io_in_valid(dv7_in_valid),
    .io_in_bits(dv7_in[23:0]),
    .io_out_bits(i_dv7_out[23:0])
  );

  // ---- DelayNWithValid_103: 载荷 16 位 / 1 字段 / STAGES=1 / V=0 ----
  logic dv8_in_valid;
  logic [15:0] dv8_in;
  wire  [15:0] g_dv8_out, i_dv8_out;
  logic [15:0] dv8_ones, dv8_zeros, dv8_prev;
  int   dv8_checks, dv8_vld, dv8_idle, dv8_hold, dv8_move;
  DelayNWithValid_103 u_g_dv8 (
    .clock(clock),
    .io_in_valid(dv8_in_valid),
    .io_in_bits(dv8_in[15:0]),
    .io_out_bits(g_dv8_out[15:0])
  );
  DelayNWithValid_103_xs u_i_dv8 (
    .clock(clock),
    .io_in_valid(dv8_in_valid),
    .io_in_bits(dv8_in[15:0]),
    .io_out_bits(i_dv8_out[15:0])
  );

  // ---- DelayNWithValid_148: 载荷 7 位 / 2 字段 / STAGES=3 / V=2 ----
  logic dv9_in_valid;
  logic [6:0] dv9_in;
  wire  [6:0] g_dv9_out, i_dv9_out;
  logic [6:0] dv9_ones, dv9_zeros, dv9_prev;
  int   dv9_checks, dv9_vld, dv9_idle, dv9_hold, dv9_move;
  DelayNWithValid_148 u_g_dv9 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv9_in_valid),
    .io_in_bits_flag(dv9_in[6]),
    .io_in_bits_value(dv9_in[5:0]),
    .io_out_bits_flag(g_dv9_out[6]),
    .io_out_bits_value(g_dv9_out[5:0])
  );
  DelayNWithValid_148_xs u_i_dv9 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv9_in_valid),
    .io_in_bits_flag(dv9_in[6]),
    .io_in_bits_value(dv9_in[5:0]),
    .io_out_bits_flag(i_dv9_out[6]),
    .io_out_bits_value(i_dv9_out[5:0])
  );

  // ---- DelayNWithValid_149: 载荷 4 位 / 1 字段 / STAGES=3 / V=2 ----
  logic dv10_in_valid;
  logic [3:0] dv10_in;
  wire  [3:0] g_dv10_out, i_dv10_out;
  logic [3:0] dv10_ones, dv10_zeros, dv10_prev;
  int   dv10_checks, dv10_vld, dv10_idle, dv10_hold, dv10_move;
  DelayNWithValid_149 u_g_dv10 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv10_in_valid),
    .io_in_bits(dv10_in[3:0]),
    .io_out_bits(g_dv10_out[3:0])
  );
  DelayNWithValid_149_xs u_i_dv10 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv10_in_valid),
    .io_in_bits(dv10_in[3:0]),
    .io_out_bits(i_dv10_out[3:0])
  );

  // ---- DelayNWithValid_152: 载荷 9 位 / 1 字段 / STAGES=1 / V=0 ----
  logic dv11_in_valid;
  logic [8:0] dv11_in;
  wire  [8:0] g_dv11_out, i_dv11_out;
  logic [8:0] dv11_ones, dv11_zeros, dv11_prev;
  int   dv11_checks, dv11_vld, dv11_idle, dv11_hold, dv11_move;
  DelayNWithValid_152 u_g_dv11 (
    .clock(clock),
    .io_in_valid(dv11_in_valid),
    .io_in_bits(dv11_in[8:0]),
    .io_out_bits(g_dv11_out[8:0])
  );
  DelayNWithValid_152_xs u_i_dv11 (
    .clock(clock),
    .io_in_valid(dv11_in_valid),
    .io_in_bits(dv11_in[8:0]),
    .io_out_bits(i_dv11_out[8:0])
  );

  // ---- DelayNWithValid_155: 载荷 50 位 / 1 字段 / STAGES=1 / V=0 ----
  logic dv12_in_valid;
  logic [49:0] dv12_in;
  wire  [49:0] g_dv12_out, i_dv12_out;
  logic [49:0] dv12_ones, dv12_zeros, dv12_prev;
  int   dv12_checks, dv12_vld, dv12_idle, dv12_hold, dv12_move;
  DelayNWithValid_155 u_g_dv12 (
    .clock(clock),
    .io_in_valid(dv12_in_valid),
    .io_in_bits(dv12_in[49:0]),
    .io_out_bits(g_dv12_out[49:0])
  );
  DelayNWithValid_155_xs u_i_dv12 (
    .clock(clock),
    .io_in_valid(dv12_in_valid),
    .io_in_bits(dv12_in[49:0]),
    .io_out_bits(i_dv12_out[49:0])
  );

  // ---- DelayNWithValid_200: 载荷 53 位 / 2 字段 / STAGES=2 / V=2 / 有 out_valid ----
  logic dv13_in_valid;
  logic [52:0] dv13_in;
  wire  [52:0] g_dv13_out, i_dv13_out;
  wire  g_dv13_ov, i_dv13_ov;
  int   dv13_ov1, dv13_ov0;
  logic [52:0] dv13_ones, dv13_zeros, dv13_prev;
  int   dv13_checks, dv13_vld, dv13_idle, dv13_hold, dv13_move;
  DelayNWithValid_200 u_g_dv13 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv13_in_valid),
    .io_in_bits_addr(dv13_in[52:5]),
    .io_in_bits_source(dv13_in[4:0]),
    .io_out_bits_addr(g_dv13_out[52:5]),
    .io_out_bits_source(g_dv13_out[4:0]),
    .io_out_valid(g_dv13_ov)
  );
  DelayNWithValid_200_xs u_i_dv13 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv13_in_valid),
    .io_in_bits_addr(dv13_in[52:5]),
    .io_in_bits_source(dv13_in[4:0]),
    .io_out_bits_addr(i_dv13_out[52:5]),
    .io_out_bits_source(i_dv13_out[4:0]),
    .io_out_valid(i_dv13_ov)
  );

  // ---- DelayNWithValid_202: 载荷 12 位 / 1 字段 / STAGES=1 / V=1 / 有 out_valid ----
  logic dv14_in_valid;
  logic [11:0] dv14_in;
  wire  [11:0] g_dv14_out, i_dv14_out;
  wire  g_dv14_ov, i_dv14_ov;
  int   dv14_ov1, dv14_ov0;
  logic [11:0] dv14_ones, dv14_zeros, dv14_prev;
  int   dv14_checks, dv14_vld, dv14_idle, dv14_hold, dv14_move;
  DelayNWithValid_202 u_g_dv14 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv14_in_valid),
    .io_in_bits(dv14_in[11:0]),
    .io_out_bits(g_dv14_out[11:0]),
    .io_out_valid(g_dv14_ov)
  );
  DelayNWithValid_202_xs u_i_dv14 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv14_in_valid),
    .io_in_bits(dv14_in[11:0]),
    .io_out_bits(i_dv14_out[11:0]),
    .io_out_valid(i_dv14_ov)
  );

  // ---- DelayNWithValid_203: 载荷 64 位 / 1 字段 / STAGES=1 / V=1 / 有 out_valid ----
  logic dv15_in_valid;
  logic [63:0] dv15_in;
  wire  [63:0] g_dv15_out, i_dv15_out;
  wire  g_dv15_ov, i_dv15_ov;
  int   dv15_ov1, dv15_ov0;
  logic [63:0] dv15_ones, dv15_zeros, dv15_prev;
  int   dv15_checks, dv15_vld, dv15_idle, dv15_hold, dv15_move;
  DelayNWithValid_203 u_g_dv15 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv15_in_valid),
    .io_in_bits(dv15_in[63:0]),
    .io_out_bits(g_dv15_out[63:0]),
    .io_out_valid(g_dv15_ov)
  );
  DelayNWithValid_203_xs u_i_dv15 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv15_in_valid),
    .io_in_bits(dv15_in[63:0]),
    .io_out_bits(i_dv15_out[63:0]),
    .io_out_valid(i_dv15_ov)
  );


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    dv0_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv0_in = '0;
      1:       dv0_in = '1;
      default: for (int b = 0; b < 50; b++) dv0_in[b] = 1'($urandom);
    endcase
    dv1_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv1_in = '0;
      1:       dv1_in = '1;
      default: for (int b = 0; b < 60; b++) dv1_in[b] = 1'($urandom);
    endcase
    dv2_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv2_in = '0;
      1:       dv2_in = '1;
      default: for (int b = 0; b < 49; b++) dv2_in[b] = 1'($urandom);
    endcase
    dv3_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv3_in = '0;
      1:       dv3_in = '1;
      default: for (int b = 0; b < 48; b++) dv3_in[b] = 1'($urandom);
    endcase
    dv4_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv4_in = '0;
      1:       dv4_in = '1;
      default: for (int b = 0; b < 9; b++) dv4_in[b] = 1'($urandom);
    endcase
    dv5_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv5_in = '0;
      1:       dv5_in = '1;
      default: for (int b = 0; b < 16; b++) dv5_in[b] = 1'($urandom);
    endcase
    dv6_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv6_in = '0;
      1:       dv6_in = '1;
      default: for (int b = 0; b < 4; b++) dv6_in[b] = 1'($urandom);
    endcase
    dv7_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv7_in = '0;
      1:       dv7_in = '1;
      default: for (int b = 0; b < 24; b++) dv7_in[b] = 1'($urandom);
    endcase
    dv8_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv8_in = '0;
      1:       dv8_in = '1;
      default: for (int b = 0; b < 16; b++) dv8_in[b] = 1'($urandom);
    endcase
    dv9_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv9_in = '0;
      1:       dv9_in = '1;
      default: for (int b = 0; b < 7; b++) dv9_in[b] = 1'($urandom);
    endcase
    dv10_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv10_in = '0;
      1:       dv10_in = '1;
      default: for (int b = 0; b < 4; b++) dv10_in[b] = 1'($urandom);
    endcase
    dv11_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv11_in = '0;
      1:       dv11_in = '1;
      default: for (int b = 0; b < 9; b++) dv11_in[b] = 1'($urandom);
    endcase
    dv12_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv12_in = '0;
      1:       dv12_in = '1;
      default: for (int b = 0; b < 50; b++) dv12_in[b] = 1'($urandom);
    endcase
    dv13_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv13_in = '0;
      1:       dv13_in = '1;
      default: for (int b = 0; b < 53; b++) dv13_in[b] = 1'($urandom);
    endcase
    dv14_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv14_in = '0;
      1:       dv14_in = '1;
      default: for (int b = 0; b < 12; b++) dv14_in[b] = 1'($urandom);
    endcase
    dv15_in_valid = (cycle < WARMUP) ? 1'b1 : ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv15_in = '0;
      1:       dv15_in = '1;
      default: for (int b = 0; b < 64; b++) dv15_in[b] = 1'($urandom);
    endcase
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_dv0_out)) begin
      checks++; dv0_checks++;
      dv0_ones  |= g_dv0_out;
      dv0_zeros |= ~g_dv0_out;
      if (dv0_in_valid) dv0_vld++; else dv0_idle++;
      if (!$isunknown(dv0_prev)) begin
        if (dv0_prev === g_dv0_out) dv0_hold++; else dv0_move++;
      end
      dv0_prev = g_dv0_out;
      if (g_dv0_out !== i_dv0_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid g=%0h i=%0h", $time, g_dv0_out, i_dv0_out);
      end
    end
    if (!$isunknown(g_dv1_out)) begin
      checks++; dv1_checks++;
      dv1_ones  |= g_dv1_out;
      dv1_zeros |= ~g_dv1_out;
      if (dv1_in_valid) dv1_vld++; else dv1_idle++;
      if (!$isunknown(dv1_prev)) begin
        if (dv1_prev === g_dv1_out) dv1_hold++; else dv1_move++;
      end
      dv1_prev = g_dv1_out;
      if (g_dv1_out !== i_dv1_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_1 g=%0h i=%0h", $time, g_dv1_out, i_dv1_out);
      end
    end
    if (!$isunknown(g_dv2_out)) begin
      checks++; dv2_checks++;
      dv2_ones  |= g_dv2_out;
      dv2_zeros |= ~g_dv2_out;
      if (dv2_in_valid) dv2_vld++; else dv2_idle++;
      if (!$isunknown(dv2_prev)) begin
        if (dv2_prev === g_dv2_out) dv2_hold++; else dv2_move++;
      end
      dv2_prev = g_dv2_out;
      if (g_dv2_out !== i_dv2_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_2 g=%0h i=%0h", $time, g_dv2_out, i_dv2_out);
      end
      if (g_dv2_ov) dv2_ov1++; else dv2_ov0++;
      if (g_dv2_ov !== i_dv2_ov) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_2 io_out_valid g=%b i=%b",
                   $time, g_dv2_ov, i_dv2_ov);
      end
    end
    if (!$isunknown(g_dv3_out)) begin
      checks++; dv3_checks++;
      dv3_ones  |= g_dv3_out;
      dv3_zeros |= ~g_dv3_out;
      if (dv3_in_valid) dv3_vld++; else dv3_idle++;
      if (!$isunknown(dv3_prev)) begin
        if (dv3_prev === g_dv3_out) dv3_hold++; else dv3_move++;
      end
      dv3_prev = g_dv3_out;
      if (g_dv3_out !== i_dv3_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_3 g=%0h i=%0h", $time, g_dv3_out, i_dv3_out);
      end
      if (g_dv3_ov) dv3_ov1++; else dv3_ov0++;
      if (g_dv3_ov !== i_dv3_ov) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_3 io_out_valid g=%b i=%b",
                   $time, g_dv3_ov, i_dv3_ov);
      end
    end
    if (!$isunknown(g_dv4_out)) begin
      checks++; dv4_checks++;
      dv4_ones  |= g_dv4_out;
      dv4_zeros |= ~g_dv4_out;
      if (dv4_in_valid) dv4_vld++; else dv4_idle++;
      if (!$isunknown(dv4_prev)) begin
        if (dv4_prev === g_dv4_out) dv4_hold++; else dv4_move++;
      end
      dv4_prev = g_dv4_out;
      if (g_dv4_out !== i_dv4_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_4 g=%0h i=%0h", $time, g_dv4_out, i_dv4_out);
      end
    end
    if (!$isunknown(g_dv5_out)) begin
      checks++; dv5_checks++;
      dv5_ones  |= g_dv5_out;
      dv5_zeros |= ~g_dv5_out;
      if (dv5_in_valid) dv5_vld++; else dv5_idle++;
      if (!$isunknown(dv5_prev)) begin
        if (dv5_prev === g_dv5_out) dv5_hold++; else dv5_move++;
      end
      dv5_prev = g_dv5_out;
      if (g_dv5_out !== i_dv5_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_7 g=%0h i=%0h", $time, g_dv5_out, i_dv5_out);
      end
    end
    if (!$isunknown(g_dv6_out)) begin
      checks++; dv6_checks++;
      dv6_ones  |= g_dv6_out;
      dv6_zeros |= ~g_dv6_out;
      if (dv6_in_valid) dv6_vld++; else dv6_idle++;
      if (!$isunknown(dv6_prev)) begin
        if (dv6_prev === g_dv6_out) dv6_hold++; else dv6_move++;
      end
      dv6_prev = g_dv6_out;
      if (g_dv6_out !== i_dv6_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_52 g=%0h i=%0h", $time, g_dv6_out, i_dv6_out);
      end
    end
    if (!$isunknown(g_dv7_out)) begin
      checks++; dv7_checks++;
      dv7_ones  |= g_dv7_out;
      dv7_zeros |= ~g_dv7_out;
      if (dv7_in_valid) dv7_vld++; else dv7_idle++;
      if (!$isunknown(dv7_prev)) begin
        if (dv7_prev === g_dv7_out) dv7_hold++; else dv7_move++;
      end
      dv7_prev = g_dv7_out;
      if (g_dv7_out !== i_dv7_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_55 g=%0h i=%0h", $time, g_dv7_out, i_dv7_out);
      end
    end
    if (!$isunknown(g_dv8_out)) begin
      checks++; dv8_checks++;
      dv8_ones  |= g_dv8_out;
      dv8_zeros |= ~g_dv8_out;
      if (dv8_in_valid) dv8_vld++; else dv8_idle++;
      if (!$isunknown(dv8_prev)) begin
        if (dv8_prev === g_dv8_out) dv8_hold++; else dv8_move++;
      end
      dv8_prev = g_dv8_out;
      if (g_dv8_out !== i_dv8_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_103 g=%0h i=%0h", $time, g_dv8_out, i_dv8_out);
      end
    end
    if (!$isunknown(g_dv9_out)) begin
      checks++; dv9_checks++;
      dv9_ones  |= g_dv9_out;
      dv9_zeros |= ~g_dv9_out;
      if (dv9_in_valid) dv9_vld++; else dv9_idle++;
      if (!$isunknown(dv9_prev)) begin
        if (dv9_prev === g_dv9_out) dv9_hold++; else dv9_move++;
      end
      dv9_prev = g_dv9_out;
      if (g_dv9_out !== i_dv9_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_148 g=%0h i=%0h", $time, g_dv9_out, i_dv9_out);
      end
    end
    if (!$isunknown(g_dv10_out)) begin
      checks++; dv10_checks++;
      dv10_ones  |= g_dv10_out;
      dv10_zeros |= ~g_dv10_out;
      if (dv10_in_valid) dv10_vld++; else dv10_idle++;
      if (!$isunknown(dv10_prev)) begin
        if (dv10_prev === g_dv10_out) dv10_hold++; else dv10_move++;
      end
      dv10_prev = g_dv10_out;
      if (g_dv10_out !== i_dv10_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_149 g=%0h i=%0h", $time, g_dv10_out, i_dv10_out);
      end
    end
    if (!$isunknown(g_dv11_out)) begin
      checks++; dv11_checks++;
      dv11_ones  |= g_dv11_out;
      dv11_zeros |= ~g_dv11_out;
      if (dv11_in_valid) dv11_vld++; else dv11_idle++;
      if (!$isunknown(dv11_prev)) begin
        if (dv11_prev === g_dv11_out) dv11_hold++; else dv11_move++;
      end
      dv11_prev = g_dv11_out;
      if (g_dv11_out !== i_dv11_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_152 g=%0h i=%0h", $time, g_dv11_out, i_dv11_out);
      end
    end
    if (!$isunknown(g_dv12_out)) begin
      checks++; dv12_checks++;
      dv12_ones  |= g_dv12_out;
      dv12_zeros |= ~g_dv12_out;
      if (dv12_in_valid) dv12_vld++; else dv12_idle++;
      if (!$isunknown(dv12_prev)) begin
        if (dv12_prev === g_dv12_out) dv12_hold++; else dv12_move++;
      end
      dv12_prev = g_dv12_out;
      if (g_dv12_out !== i_dv12_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_155 g=%0h i=%0h", $time, g_dv12_out, i_dv12_out);
      end
    end
    if (!$isunknown(g_dv13_out)) begin
      checks++; dv13_checks++;
      dv13_ones  |= g_dv13_out;
      dv13_zeros |= ~g_dv13_out;
      if (dv13_in_valid) dv13_vld++; else dv13_idle++;
      if (!$isunknown(dv13_prev)) begin
        if (dv13_prev === g_dv13_out) dv13_hold++; else dv13_move++;
      end
      dv13_prev = g_dv13_out;
      if (g_dv13_out !== i_dv13_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_200 g=%0h i=%0h", $time, g_dv13_out, i_dv13_out);
      end
      if (g_dv13_ov) dv13_ov1++; else dv13_ov0++;
      if (g_dv13_ov !== i_dv13_ov) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_200 io_out_valid g=%b i=%b",
                   $time, g_dv13_ov, i_dv13_ov);
      end
    end
    if (!$isunknown(g_dv14_out)) begin
      checks++; dv14_checks++;
      dv14_ones  |= g_dv14_out;
      dv14_zeros |= ~g_dv14_out;
      if (dv14_in_valid) dv14_vld++; else dv14_idle++;
      if (!$isunknown(dv14_prev)) begin
        if (dv14_prev === g_dv14_out) dv14_hold++; else dv14_move++;
      end
      dv14_prev = g_dv14_out;
      if (g_dv14_out !== i_dv14_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_202 g=%0h i=%0h", $time, g_dv14_out, i_dv14_out);
      end
      if (g_dv14_ov) dv14_ov1++; else dv14_ov0++;
      if (g_dv14_ov !== i_dv14_ov) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_202 io_out_valid g=%b i=%b",
                   $time, g_dv14_ov, i_dv14_ov);
      end
    end
    if (!$isunknown(g_dv15_out)) begin
      checks++; dv15_checks++;
      dv15_ones  |= g_dv15_out;
      dv15_zeros |= ~g_dv15_out;
      if (dv15_in_valid) dv15_vld++; else dv15_idle++;
      if (!$isunknown(dv15_prev)) begin
        if (dv15_prev === g_dv15_out) dv15_hold++; else dv15_move++;
      end
      dv15_prev = g_dv15_out;
      if (g_dv15_out !== i_dv15_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_203 g=%0h i=%0h", $time, g_dv15_out, i_dv15_out);
      end
      if (g_dv15_ov) dv15_ov1++; else dv15_ov0++;
      if (g_dv15_ov !== i_dv15_ov) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_203 io_out_valid g=%b i=%b",
                   $time, g_dv15_ov, i_dv15_ov);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    dv0_in_valid = 0; dv0_in = '0; dv0_ones = '0; dv0_zeros = '0; dv0_prev = 'x;
    dv0_checks = 0; dv0_vld = 0; dv0_idle = 0; dv0_hold = 0; dv0_move = 0;
    dv1_in_valid = 0; dv1_in = '0; dv1_ones = '0; dv1_zeros = '0; dv1_prev = 'x;
    dv1_checks = 0; dv1_vld = 0; dv1_idle = 0; dv1_hold = 0; dv1_move = 0;
    dv2_in_valid = 0; dv2_in = '0; dv2_ones = '0; dv2_zeros = '0; dv2_prev = 'x;
    dv2_checks = 0; dv2_vld = 0; dv2_idle = 0; dv2_hold = 0; dv2_move = 0; dv2_ov1 = 0; dv2_ov0 = 0;
    dv3_in_valid = 0; dv3_in = '0; dv3_ones = '0; dv3_zeros = '0; dv3_prev = 'x;
    dv3_checks = 0; dv3_vld = 0; dv3_idle = 0; dv3_hold = 0; dv3_move = 0; dv3_ov1 = 0; dv3_ov0 = 0;
    dv4_in_valid = 0; dv4_in = '0; dv4_ones = '0; dv4_zeros = '0; dv4_prev = 'x;
    dv4_checks = 0; dv4_vld = 0; dv4_idle = 0; dv4_hold = 0; dv4_move = 0;
    dv5_in_valid = 0; dv5_in = '0; dv5_ones = '0; dv5_zeros = '0; dv5_prev = 'x;
    dv5_checks = 0; dv5_vld = 0; dv5_idle = 0; dv5_hold = 0; dv5_move = 0;
    dv6_in_valid = 0; dv6_in = '0; dv6_ones = '0; dv6_zeros = '0; dv6_prev = 'x;
    dv6_checks = 0; dv6_vld = 0; dv6_idle = 0; dv6_hold = 0; dv6_move = 0;
    dv7_in_valid = 0; dv7_in = '0; dv7_ones = '0; dv7_zeros = '0; dv7_prev = 'x;
    dv7_checks = 0; dv7_vld = 0; dv7_idle = 0; dv7_hold = 0; dv7_move = 0;
    dv8_in_valid = 0; dv8_in = '0; dv8_ones = '0; dv8_zeros = '0; dv8_prev = 'x;
    dv8_checks = 0; dv8_vld = 0; dv8_idle = 0; dv8_hold = 0; dv8_move = 0;
    dv9_in_valid = 0; dv9_in = '0; dv9_ones = '0; dv9_zeros = '0; dv9_prev = 'x;
    dv9_checks = 0; dv9_vld = 0; dv9_idle = 0; dv9_hold = 0; dv9_move = 0;
    dv10_in_valid = 0; dv10_in = '0; dv10_ones = '0; dv10_zeros = '0; dv10_prev = 'x;
    dv10_checks = 0; dv10_vld = 0; dv10_idle = 0; dv10_hold = 0; dv10_move = 0;
    dv11_in_valid = 0; dv11_in = '0; dv11_ones = '0; dv11_zeros = '0; dv11_prev = 'x;
    dv11_checks = 0; dv11_vld = 0; dv11_idle = 0; dv11_hold = 0; dv11_move = 0;
    dv12_in_valid = 0; dv12_in = '0; dv12_ones = '0; dv12_zeros = '0; dv12_prev = 'x;
    dv12_checks = 0; dv12_vld = 0; dv12_idle = 0; dv12_hold = 0; dv12_move = 0;
    dv13_in_valid = 0; dv13_in = '0; dv13_ones = '0; dv13_zeros = '0; dv13_prev = 'x;
    dv13_checks = 0; dv13_vld = 0; dv13_idle = 0; dv13_hold = 0; dv13_move = 0; dv13_ov1 = 0; dv13_ov0 = 0;
    dv14_in_valid = 0; dv14_in = '0; dv14_ones = '0; dv14_zeros = '0; dv14_prev = 'x;
    dv14_checks = 0; dv14_vld = 0; dv14_idle = 0; dv14_hold = 0; dv14_move = 0; dv14_ov1 = 0; dv14_ov0 = 0;
    dv15_in_valid = 0; dv15_in = '0; dv15_ones = '0; dv15_zeros = '0; dv15_prev = 'x;
    dv15_checks = 0; dv15_vld = 0; dv15_idle = 0; dv15_hold = 0; dv15_move = 0; dv15_ov1 = 0; dv15_ov0 = 0;
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      // 热身窗口：两侧无复位数据寄存器各自带着独立随机初值，此时不可比；
      // 窗口内 drive 把 io_in_valid 强制拉 1 做确定性灌注（见文件头）。
      if (cycle >= WARMUP) check_outputs();   // 输出在 posedge 变，negedge 稳定
      drive_random_inputs();
      @(posedge clock);
      cycle++;
      // 复位脉冲只清 valid 链（数据级 golden 就没有复位），热身窗口内不打，
      // 免得把灌注拖慢。
      if (cycle >= WARMUP && $urandom_range(0, 4999) == 0) begin   // 异步复位脉冲
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("DelayNWithValid family checks=%0d errors=%0d", checks, errors);
    $display("  DelayNWithValid: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/50 zeros=%0d/50",
             dv0_checks, dv0_vld, dv0_idle, dv0_hold, dv0_move,
             $countones(dv0_ones), $countones(dv0_zeros));
    cov_fail += cov_short("DelayNWithValid checks", dv0_checks)
              + cov_short("DelayNWithValid valid",  dv0_vld)
              + cov_short("DelayNWithValid idle",   dv0_idle)
              + cov_short("DelayNWithValid hold",   dv0_hold)
              + cov_short("DelayNWithValid move",   dv0_move);
    if (!(&dv0_ones) || !(&dv0_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_1: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/60 zeros=%0d/60",
             dv1_checks, dv1_vld, dv1_idle, dv1_hold, dv1_move,
             $countones(dv1_ones), $countones(dv1_zeros));
    cov_fail += cov_short("DelayNWithValid_1 checks", dv1_checks)
              + cov_short("DelayNWithValid_1 valid",  dv1_vld)
              + cov_short("DelayNWithValid_1 idle",   dv1_idle)
              + cov_short("DelayNWithValid_1 hold",   dv1_hold)
              + cov_short("DelayNWithValid_1 move",   dv1_move);
    if (!(&dv1_ones) || !(&dv1_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_1 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_2: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/49 zeros=%0d/49",
             dv2_checks, dv2_vld, dv2_idle, dv2_hold, dv2_move,
             $countones(dv2_ones), $countones(dv2_zeros));
    cov_fail += cov_short("DelayNWithValid_2 checks", dv2_checks)
              + cov_short("DelayNWithValid_2 valid",  dv2_vld)
              + cov_short("DelayNWithValid_2 idle",   dv2_idle)
              + cov_short("DelayNWithValid_2 hold",   dv2_hold)
              + cov_short("DelayNWithValid_2 move",   dv2_move);
    cov_fail += cov_short("DelayNWithValid_2 out_valid=1", dv2_ov1)
              + cov_short("DelayNWithValid_2 out_valid=0", dv2_ov0);
    if (!(&dv2_ones) || !(&dv2_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_2 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_3: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/48 zeros=%0d/48",
             dv3_checks, dv3_vld, dv3_idle, dv3_hold, dv3_move,
             $countones(dv3_ones), $countones(dv3_zeros));
    cov_fail += cov_short("DelayNWithValid_3 checks", dv3_checks)
              + cov_short("DelayNWithValid_3 valid",  dv3_vld)
              + cov_short("DelayNWithValid_3 idle",   dv3_idle)
              + cov_short("DelayNWithValid_3 hold",   dv3_hold)
              + cov_short("DelayNWithValid_3 move",   dv3_move);
    cov_fail += cov_short("DelayNWithValid_3 out_valid=1", dv3_ov1)
              + cov_short("DelayNWithValid_3 out_valid=0", dv3_ov0);
    if (!(&dv3_ones) || !(&dv3_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_3 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_4: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/9 zeros=%0d/9",
             dv4_checks, dv4_vld, dv4_idle, dv4_hold, dv4_move,
             $countones(dv4_ones), $countones(dv4_zeros));
    cov_fail += cov_short("DelayNWithValid_4 checks", dv4_checks)
              + cov_short("DelayNWithValid_4 valid",  dv4_vld)
              + cov_short("DelayNWithValid_4 idle",   dv4_idle)
              + cov_short("DelayNWithValid_4 hold",   dv4_hold)
              + cov_short("DelayNWithValid_4 move",   dv4_move);
    if (!(&dv4_ones) || !(&dv4_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_4 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_7: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/16 zeros=%0d/16",
             dv5_checks, dv5_vld, dv5_idle, dv5_hold, dv5_move,
             $countones(dv5_ones), $countones(dv5_zeros));
    cov_fail += cov_short("DelayNWithValid_7 checks", dv5_checks)
              + cov_short("DelayNWithValid_7 valid",  dv5_vld)
              + cov_short("DelayNWithValid_7 idle",   dv5_idle)
              + cov_short("DelayNWithValid_7 hold",   dv5_hold)
              + cov_short("DelayNWithValid_7 move",   dv5_move);
    if (!(&dv5_ones) || !(&dv5_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_7 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_52: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/4 zeros=%0d/4",
             dv6_checks, dv6_vld, dv6_idle, dv6_hold, dv6_move,
             $countones(dv6_ones), $countones(dv6_zeros));
    cov_fail += cov_short("DelayNWithValid_52 checks", dv6_checks)
              + cov_short("DelayNWithValid_52 valid",  dv6_vld)
              + cov_short("DelayNWithValid_52 idle",   dv6_idle)
              + cov_short("DelayNWithValid_52 hold",   dv6_hold)
              + cov_short("DelayNWithValid_52 move",   dv6_move);
    if (!(&dv6_ones) || !(&dv6_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_52 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_55: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/24 zeros=%0d/24",
             dv7_checks, dv7_vld, dv7_idle, dv7_hold, dv7_move,
             $countones(dv7_ones), $countones(dv7_zeros));
    cov_fail += cov_short("DelayNWithValid_55 checks", dv7_checks)
              + cov_short("DelayNWithValid_55 valid",  dv7_vld)
              + cov_short("DelayNWithValid_55 idle",   dv7_idle)
              + cov_short("DelayNWithValid_55 hold",   dv7_hold)
              + cov_short("DelayNWithValid_55 move",   dv7_move);
    if (!(&dv7_ones) || !(&dv7_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_55 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_103: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/16 zeros=%0d/16",
             dv8_checks, dv8_vld, dv8_idle, dv8_hold, dv8_move,
             $countones(dv8_ones), $countones(dv8_zeros));
    cov_fail += cov_short("DelayNWithValid_103 checks", dv8_checks)
              + cov_short("DelayNWithValid_103 valid",  dv8_vld)
              + cov_short("DelayNWithValid_103 idle",   dv8_idle)
              + cov_short("DelayNWithValid_103 hold",   dv8_hold)
              + cov_short("DelayNWithValid_103 move",   dv8_move);
    if (!(&dv8_ones) || !(&dv8_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_103 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_148: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/7 zeros=%0d/7",
             dv9_checks, dv9_vld, dv9_idle, dv9_hold, dv9_move,
             $countones(dv9_ones), $countones(dv9_zeros));
    cov_fail += cov_short("DelayNWithValid_148 checks", dv9_checks)
              + cov_short("DelayNWithValid_148 valid",  dv9_vld)
              + cov_short("DelayNWithValid_148 idle",   dv9_idle)
              + cov_short("DelayNWithValid_148 hold",   dv9_hold)
              + cov_short("DelayNWithValid_148 move",   dv9_move);
    if (!(&dv9_ones) || !(&dv9_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_148 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_149: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/4 zeros=%0d/4",
             dv10_checks, dv10_vld, dv10_idle, dv10_hold, dv10_move,
             $countones(dv10_ones), $countones(dv10_zeros));
    cov_fail += cov_short("DelayNWithValid_149 checks", dv10_checks)
              + cov_short("DelayNWithValid_149 valid",  dv10_vld)
              + cov_short("DelayNWithValid_149 idle",   dv10_idle)
              + cov_short("DelayNWithValid_149 hold",   dv10_hold)
              + cov_short("DelayNWithValid_149 move",   dv10_move);
    if (!(&dv10_ones) || !(&dv10_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_149 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_152: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/9 zeros=%0d/9",
             dv11_checks, dv11_vld, dv11_idle, dv11_hold, dv11_move,
             $countones(dv11_ones), $countones(dv11_zeros));
    cov_fail += cov_short("DelayNWithValid_152 checks", dv11_checks)
              + cov_short("DelayNWithValid_152 valid",  dv11_vld)
              + cov_short("DelayNWithValid_152 idle",   dv11_idle)
              + cov_short("DelayNWithValid_152 hold",   dv11_hold)
              + cov_short("DelayNWithValid_152 move",   dv11_move);
    if (!(&dv11_ones) || !(&dv11_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_152 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_155: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/50 zeros=%0d/50",
             dv12_checks, dv12_vld, dv12_idle, dv12_hold, dv12_move,
             $countones(dv12_ones), $countones(dv12_zeros));
    cov_fail += cov_short("DelayNWithValid_155 checks", dv12_checks)
              + cov_short("DelayNWithValid_155 valid",  dv12_vld)
              + cov_short("DelayNWithValid_155 idle",   dv12_idle)
              + cov_short("DelayNWithValid_155 hold",   dv12_hold)
              + cov_short("DelayNWithValid_155 move",   dv12_move);
    if (!(&dv12_ones) || !(&dv12_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_155 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_200: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/53 zeros=%0d/53",
             dv13_checks, dv13_vld, dv13_idle, dv13_hold, dv13_move,
             $countones(dv13_ones), $countones(dv13_zeros));
    cov_fail += cov_short("DelayNWithValid_200 checks", dv13_checks)
              + cov_short("DelayNWithValid_200 valid",  dv13_vld)
              + cov_short("DelayNWithValid_200 idle",   dv13_idle)
              + cov_short("DelayNWithValid_200 hold",   dv13_hold)
              + cov_short("DelayNWithValid_200 move",   dv13_move);
    cov_fail += cov_short("DelayNWithValid_200 out_valid=1", dv13_ov1)
              + cov_short("DelayNWithValid_200 out_valid=0", dv13_ov0);
    if (!(&dv13_ones) || !(&dv13_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_200 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_202: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/12 zeros=%0d/12",
             dv14_checks, dv14_vld, dv14_idle, dv14_hold, dv14_move,
             $countones(dv14_ones), $countones(dv14_zeros));
    cov_fail += cov_short("DelayNWithValid_202 checks", dv14_checks)
              + cov_short("DelayNWithValid_202 valid",  dv14_vld)
              + cov_short("DelayNWithValid_202 idle",   dv14_idle)
              + cov_short("DelayNWithValid_202 hold",   dv14_hold)
              + cov_short("DelayNWithValid_202 move",   dv14_move);
    cov_fail += cov_short("DelayNWithValid_202 out_valid=1", dv14_ov1)
              + cov_short("DelayNWithValid_202 out_valid=0", dv14_ov0);
    if (!(&dv14_ones) || !(&dv14_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_202 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_203: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/64 zeros=%0d/64",
             dv15_checks, dv15_vld, dv15_idle, dv15_hold, dv15_move,
             $countones(dv15_ones), $countones(dv15_zeros));
    cov_fail += cov_short("DelayNWithValid_203 checks", dv15_checks)
              + cov_short("DelayNWithValid_203 valid",  dv15_vld)
              + cov_short("DelayNWithValid_203 idle",   dv15_idle)
              + cov_short("DelayNWithValid_203 hold",   dv15_hold)
              + cov_short("DelayNWithValid_203 move",   dv15_move);
    cov_fail += cov_short("DelayNWithValid_203 out_valid=1", dv15_ov1)
              + cov_short("DelayNWithValid_203 out_valid=0", dv15_ov0);
    if (!(&dv15_ones) || !(&dv15_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_203 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
