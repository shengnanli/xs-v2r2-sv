// 生成 FauFTB 的双例化 UT testbench（tb.sv）。
//
// golden FauFTB（+ golden FauFTBWay ×32）vs 重写 FauFTB_xs（+ 重写 FauFTBWay_xs，已签核），scripts/dual_tb_lib.py，
// 端口表读 G1 golden，逐拍比全部输出（4 份 dup 的 S1 预测、entry_out、meta、perf）。
//
// 激励要点：
//   · 预测 PC 与更新 PC 从同一个 48 项小池子取（tag = pc[16:1] 两两不同）——池子比 32 路大，表会被填满、
//     PLRU 替换常发生；同一 tag 反复更新（命中写回、计数器饱和）；更新口的写旁路（本拍写同 tag）自然发生；
//   · 4 份 dup 的 s0_pc / fire 各自独立随机（核只用 dup 0 算预测，其余只做 s1_pc 打拍）；
//   · update 条目字段全随机（tarStat 含非法值 3，覆盖 Mux1H 全不选的那一支），br_taken_mask 随机，
//     meta 低位随机（perf 的 hit/miss 两支）；
//   · ubtb_enable 按阶段开关；复位每 ~30000 拍一次。
// 比较窗口：meta 两级打拍寄存器不复位 —— 等 golden 先后见过 s1_fire_0、s2_fire_0 再开比。
// 覆盖（golden 内部语义信号）：预测命中 / 更新命中写回 / 未命中走 PLRU 替换且表已满 / 计数器饱和停住 /
//   fall-through 非法 / 两次 touch 同拍。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= FauFTB =================
  int unsigned f_mode = 0;
  logic [49:0] f_pool [48];
  initial for (int k = 0; k < 48; k++) f_pool[k] = {$urandom, $urandom} & ~50'h1FFFE | (50'(k * 1237 + 5) << 1 & 50'h1FFFE);
  logic f_reset;
  logic [47:0] f_io_reset_vector;
  logic [49:0] f_io_in_bits_s0_pc_0;
  logic [49:0] f_io_in_bits_s0_pc_1;
  logic [49:0] f_io_in_bits_s0_pc_2;
  logic [49:0] f_io_in_bits_s0_pc_3;
  wire  [49:0] f_g_io_out_s1_pc_0, f_i_io_out_s1_pc_0;
  logic [49:0] f_s0_io_out_s1_pc_0 = '0, f_s1_io_out_s1_pc_0 = '0;
  wire  [49:0] f_g_io_out_s1_pc_1, f_i_io_out_s1_pc_1;
  logic [49:0] f_s0_io_out_s1_pc_1 = '0, f_s1_io_out_s1_pc_1 = '0;
  wire  [49:0] f_g_io_out_s1_pc_2, f_i_io_out_s1_pc_2;
  logic [49:0] f_s0_io_out_s1_pc_2 = '0, f_s1_io_out_s1_pc_2 = '0;
  wire  [49:0] f_g_io_out_s1_pc_3, f_i_io_out_s1_pc_3;
  logic [49:0] f_s0_io_out_s1_pc_3 = '0, f_s1_io_out_s1_pc_3 = '0;
  wire  f_g_io_out_s1_full_pred_0_br_taken_mask_0, f_i_io_out_s1_full_pred_0_br_taken_mask_0;
  logic f_s0_io_out_s1_full_pred_0_br_taken_mask_0 = '0, f_s1_io_out_s1_full_pred_0_br_taken_mask_0 = '0;
  wire  f_g_io_out_s1_full_pred_0_br_taken_mask_1, f_i_io_out_s1_full_pred_0_br_taken_mask_1;
  logic f_s0_io_out_s1_full_pred_0_br_taken_mask_1 = '0, f_s1_io_out_s1_full_pred_0_br_taken_mask_1 = '0;
  wire  f_g_io_out_s1_full_pred_0_slot_valids_0, f_i_io_out_s1_full_pred_0_slot_valids_0;
  logic f_s0_io_out_s1_full_pred_0_slot_valids_0 = '0, f_s1_io_out_s1_full_pred_0_slot_valids_0 = '0;
  wire  f_g_io_out_s1_full_pred_0_slot_valids_1, f_i_io_out_s1_full_pred_0_slot_valids_1;
  logic f_s0_io_out_s1_full_pred_0_slot_valids_1 = '0, f_s1_io_out_s1_full_pred_0_slot_valids_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_0_targets_0, f_i_io_out_s1_full_pred_0_targets_0;
  logic [49:0] f_s0_io_out_s1_full_pred_0_targets_0 = '0, f_s1_io_out_s1_full_pred_0_targets_0 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_0_targets_1, f_i_io_out_s1_full_pred_0_targets_1;
  logic [49:0] f_s0_io_out_s1_full_pred_0_targets_1 = '0, f_s1_io_out_s1_full_pred_0_targets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_0_jalr_target, f_i_io_out_s1_full_pred_0_jalr_target;
  logic [49:0] f_s0_io_out_s1_full_pred_0_jalr_target = '0, f_s1_io_out_s1_full_pred_0_jalr_target = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_0_offsets_0, f_i_io_out_s1_full_pred_0_offsets_0;
  logic [3:0] f_s0_io_out_s1_full_pred_0_offsets_0 = '0, f_s1_io_out_s1_full_pred_0_offsets_0 = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_0_offsets_1, f_i_io_out_s1_full_pred_0_offsets_1;
  logic [3:0] f_s0_io_out_s1_full_pred_0_offsets_1 = '0, f_s1_io_out_s1_full_pred_0_offsets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_0_fallThroughAddr, f_i_io_out_s1_full_pred_0_fallThroughAddr;
  logic [49:0] f_s0_io_out_s1_full_pred_0_fallThroughAddr = '0, f_s1_io_out_s1_full_pred_0_fallThroughAddr = '0;
  wire  f_g_io_out_s1_full_pred_0_fallThroughErr, f_i_io_out_s1_full_pred_0_fallThroughErr;
  logic f_s0_io_out_s1_full_pred_0_fallThroughErr = '0, f_s1_io_out_s1_full_pred_0_fallThroughErr = '0;
  wire  f_g_io_out_s1_full_pred_0_is_jal, f_i_io_out_s1_full_pred_0_is_jal;
  logic f_s0_io_out_s1_full_pred_0_is_jal = '0, f_s1_io_out_s1_full_pred_0_is_jal = '0;
  wire  f_g_io_out_s1_full_pred_0_is_jalr, f_i_io_out_s1_full_pred_0_is_jalr;
  logic f_s0_io_out_s1_full_pred_0_is_jalr = '0, f_s1_io_out_s1_full_pred_0_is_jalr = '0;
  wire  f_g_io_out_s1_full_pred_0_is_call, f_i_io_out_s1_full_pred_0_is_call;
  logic f_s0_io_out_s1_full_pred_0_is_call = '0, f_s1_io_out_s1_full_pred_0_is_call = '0;
  wire  f_g_io_out_s1_full_pred_0_is_ret, f_i_io_out_s1_full_pred_0_is_ret;
  logic f_s0_io_out_s1_full_pred_0_is_ret = '0, f_s1_io_out_s1_full_pred_0_is_ret = '0;
  wire  f_g_io_out_s1_full_pred_0_last_may_be_rvi_call, f_i_io_out_s1_full_pred_0_last_may_be_rvi_call;
  logic f_s0_io_out_s1_full_pred_0_last_may_be_rvi_call = '0, f_s1_io_out_s1_full_pred_0_last_may_be_rvi_call = '0;
  wire  f_g_io_out_s1_full_pred_0_is_br_sharing, f_i_io_out_s1_full_pred_0_is_br_sharing;
  logic f_s0_io_out_s1_full_pred_0_is_br_sharing = '0, f_s1_io_out_s1_full_pred_0_is_br_sharing = '0;
  wire  f_g_io_out_s1_full_pred_0_hit, f_i_io_out_s1_full_pred_0_hit;
  logic f_s0_io_out_s1_full_pred_0_hit = '0, f_s1_io_out_s1_full_pred_0_hit = '0;
  wire  f_g_io_out_s1_full_pred_1_br_taken_mask_0, f_i_io_out_s1_full_pred_1_br_taken_mask_0;
  logic f_s0_io_out_s1_full_pred_1_br_taken_mask_0 = '0, f_s1_io_out_s1_full_pred_1_br_taken_mask_0 = '0;
  wire  f_g_io_out_s1_full_pred_1_br_taken_mask_1, f_i_io_out_s1_full_pred_1_br_taken_mask_1;
  logic f_s0_io_out_s1_full_pred_1_br_taken_mask_1 = '0, f_s1_io_out_s1_full_pred_1_br_taken_mask_1 = '0;
  wire  f_g_io_out_s1_full_pred_1_slot_valids_0, f_i_io_out_s1_full_pred_1_slot_valids_0;
  logic f_s0_io_out_s1_full_pred_1_slot_valids_0 = '0, f_s1_io_out_s1_full_pred_1_slot_valids_0 = '0;
  wire  f_g_io_out_s1_full_pred_1_slot_valids_1, f_i_io_out_s1_full_pred_1_slot_valids_1;
  logic f_s0_io_out_s1_full_pred_1_slot_valids_1 = '0, f_s1_io_out_s1_full_pred_1_slot_valids_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_1_targets_0, f_i_io_out_s1_full_pred_1_targets_0;
  logic [49:0] f_s0_io_out_s1_full_pred_1_targets_0 = '0, f_s1_io_out_s1_full_pred_1_targets_0 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_1_targets_1, f_i_io_out_s1_full_pred_1_targets_1;
  logic [49:0] f_s0_io_out_s1_full_pred_1_targets_1 = '0, f_s1_io_out_s1_full_pred_1_targets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_1_jalr_target, f_i_io_out_s1_full_pred_1_jalr_target;
  logic [49:0] f_s0_io_out_s1_full_pred_1_jalr_target = '0, f_s1_io_out_s1_full_pred_1_jalr_target = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_1_offsets_0, f_i_io_out_s1_full_pred_1_offsets_0;
  logic [3:0] f_s0_io_out_s1_full_pred_1_offsets_0 = '0, f_s1_io_out_s1_full_pred_1_offsets_0 = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_1_offsets_1, f_i_io_out_s1_full_pred_1_offsets_1;
  logic [3:0] f_s0_io_out_s1_full_pred_1_offsets_1 = '0, f_s1_io_out_s1_full_pred_1_offsets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_1_fallThroughAddr, f_i_io_out_s1_full_pred_1_fallThroughAddr;
  logic [49:0] f_s0_io_out_s1_full_pred_1_fallThroughAddr = '0, f_s1_io_out_s1_full_pred_1_fallThroughAddr = '0;
  wire  f_g_io_out_s1_full_pred_1_fallThroughErr, f_i_io_out_s1_full_pred_1_fallThroughErr;
  logic f_s0_io_out_s1_full_pred_1_fallThroughErr = '0, f_s1_io_out_s1_full_pred_1_fallThroughErr = '0;
  wire  f_g_io_out_s1_full_pred_1_is_jal, f_i_io_out_s1_full_pred_1_is_jal;
  logic f_s0_io_out_s1_full_pred_1_is_jal = '0, f_s1_io_out_s1_full_pred_1_is_jal = '0;
  wire  f_g_io_out_s1_full_pred_1_is_jalr, f_i_io_out_s1_full_pred_1_is_jalr;
  logic f_s0_io_out_s1_full_pred_1_is_jalr = '0, f_s1_io_out_s1_full_pred_1_is_jalr = '0;
  wire  f_g_io_out_s1_full_pred_1_is_call, f_i_io_out_s1_full_pred_1_is_call;
  logic f_s0_io_out_s1_full_pred_1_is_call = '0, f_s1_io_out_s1_full_pred_1_is_call = '0;
  wire  f_g_io_out_s1_full_pred_1_is_ret, f_i_io_out_s1_full_pred_1_is_ret;
  logic f_s0_io_out_s1_full_pred_1_is_ret = '0, f_s1_io_out_s1_full_pred_1_is_ret = '0;
  wire  f_g_io_out_s1_full_pred_1_last_may_be_rvi_call, f_i_io_out_s1_full_pred_1_last_may_be_rvi_call;
  logic f_s0_io_out_s1_full_pred_1_last_may_be_rvi_call = '0, f_s1_io_out_s1_full_pred_1_last_may_be_rvi_call = '0;
  wire  f_g_io_out_s1_full_pred_1_is_br_sharing, f_i_io_out_s1_full_pred_1_is_br_sharing;
  logic f_s0_io_out_s1_full_pred_1_is_br_sharing = '0, f_s1_io_out_s1_full_pred_1_is_br_sharing = '0;
  wire  f_g_io_out_s1_full_pred_1_hit, f_i_io_out_s1_full_pred_1_hit;
  logic f_s0_io_out_s1_full_pred_1_hit = '0, f_s1_io_out_s1_full_pred_1_hit = '0;
  wire  f_g_io_out_s1_full_pred_2_br_taken_mask_0, f_i_io_out_s1_full_pred_2_br_taken_mask_0;
  logic f_s0_io_out_s1_full_pred_2_br_taken_mask_0 = '0, f_s1_io_out_s1_full_pred_2_br_taken_mask_0 = '0;
  wire  f_g_io_out_s1_full_pred_2_br_taken_mask_1, f_i_io_out_s1_full_pred_2_br_taken_mask_1;
  logic f_s0_io_out_s1_full_pred_2_br_taken_mask_1 = '0, f_s1_io_out_s1_full_pred_2_br_taken_mask_1 = '0;
  wire  f_g_io_out_s1_full_pred_2_slot_valids_0, f_i_io_out_s1_full_pred_2_slot_valids_0;
  logic f_s0_io_out_s1_full_pred_2_slot_valids_0 = '0, f_s1_io_out_s1_full_pred_2_slot_valids_0 = '0;
  wire  f_g_io_out_s1_full_pred_2_slot_valids_1, f_i_io_out_s1_full_pred_2_slot_valids_1;
  logic f_s0_io_out_s1_full_pred_2_slot_valids_1 = '0, f_s1_io_out_s1_full_pred_2_slot_valids_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_2_targets_0, f_i_io_out_s1_full_pred_2_targets_0;
  logic [49:0] f_s0_io_out_s1_full_pred_2_targets_0 = '0, f_s1_io_out_s1_full_pred_2_targets_0 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_2_targets_1, f_i_io_out_s1_full_pred_2_targets_1;
  logic [49:0] f_s0_io_out_s1_full_pred_2_targets_1 = '0, f_s1_io_out_s1_full_pred_2_targets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_2_jalr_target, f_i_io_out_s1_full_pred_2_jalr_target;
  logic [49:0] f_s0_io_out_s1_full_pred_2_jalr_target = '0, f_s1_io_out_s1_full_pred_2_jalr_target = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_2_offsets_0, f_i_io_out_s1_full_pred_2_offsets_0;
  logic [3:0] f_s0_io_out_s1_full_pred_2_offsets_0 = '0, f_s1_io_out_s1_full_pred_2_offsets_0 = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_2_offsets_1, f_i_io_out_s1_full_pred_2_offsets_1;
  logic [3:0] f_s0_io_out_s1_full_pred_2_offsets_1 = '0, f_s1_io_out_s1_full_pred_2_offsets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_2_fallThroughAddr, f_i_io_out_s1_full_pred_2_fallThroughAddr;
  logic [49:0] f_s0_io_out_s1_full_pred_2_fallThroughAddr = '0, f_s1_io_out_s1_full_pred_2_fallThroughAddr = '0;
  wire  f_g_io_out_s1_full_pred_2_fallThroughErr, f_i_io_out_s1_full_pred_2_fallThroughErr;
  logic f_s0_io_out_s1_full_pred_2_fallThroughErr = '0, f_s1_io_out_s1_full_pred_2_fallThroughErr = '0;
  wire  f_g_io_out_s1_full_pred_2_is_jal, f_i_io_out_s1_full_pred_2_is_jal;
  logic f_s0_io_out_s1_full_pred_2_is_jal = '0, f_s1_io_out_s1_full_pred_2_is_jal = '0;
  wire  f_g_io_out_s1_full_pred_2_is_jalr, f_i_io_out_s1_full_pred_2_is_jalr;
  logic f_s0_io_out_s1_full_pred_2_is_jalr = '0, f_s1_io_out_s1_full_pred_2_is_jalr = '0;
  wire  f_g_io_out_s1_full_pred_2_is_call, f_i_io_out_s1_full_pred_2_is_call;
  logic f_s0_io_out_s1_full_pred_2_is_call = '0, f_s1_io_out_s1_full_pred_2_is_call = '0;
  wire  f_g_io_out_s1_full_pred_2_is_ret, f_i_io_out_s1_full_pred_2_is_ret;
  logic f_s0_io_out_s1_full_pred_2_is_ret = '0, f_s1_io_out_s1_full_pred_2_is_ret = '0;
  wire  f_g_io_out_s1_full_pred_2_last_may_be_rvi_call, f_i_io_out_s1_full_pred_2_last_may_be_rvi_call;
  logic f_s0_io_out_s1_full_pred_2_last_may_be_rvi_call = '0, f_s1_io_out_s1_full_pred_2_last_may_be_rvi_call = '0;
  wire  f_g_io_out_s1_full_pred_2_is_br_sharing, f_i_io_out_s1_full_pred_2_is_br_sharing;
  logic f_s0_io_out_s1_full_pred_2_is_br_sharing = '0, f_s1_io_out_s1_full_pred_2_is_br_sharing = '0;
  wire  f_g_io_out_s1_full_pred_2_hit, f_i_io_out_s1_full_pred_2_hit;
  logic f_s0_io_out_s1_full_pred_2_hit = '0, f_s1_io_out_s1_full_pred_2_hit = '0;
  wire  f_g_io_out_s1_full_pred_3_br_taken_mask_0, f_i_io_out_s1_full_pred_3_br_taken_mask_0;
  logic f_s0_io_out_s1_full_pred_3_br_taken_mask_0 = '0, f_s1_io_out_s1_full_pred_3_br_taken_mask_0 = '0;
  wire  f_g_io_out_s1_full_pred_3_br_taken_mask_1, f_i_io_out_s1_full_pred_3_br_taken_mask_1;
  logic f_s0_io_out_s1_full_pred_3_br_taken_mask_1 = '0, f_s1_io_out_s1_full_pred_3_br_taken_mask_1 = '0;
  wire  f_g_io_out_s1_full_pred_3_slot_valids_0, f_i_io_out_s1_full_pred_3_slot_valids_0;
  logic f_s0_io_out_s1_full_pred_3_slot_valids_0 = '0, f_s1_io_out_s1_full_pred_3_slot_valids_0 = '0;
  wire  f_g_io_out_s1_full_pred_3_slot_valids_1, f_i_io_out_s1_full_pred_3_slot_valids_1;
  logic f_s0_io_out_s1_full_pred_3_slot_valids_1 = '0, f_s1_io_out_s1_full_pred_3_slot_valids_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_3_targets_0, f_i_io_out_s1_full_pred_3_targets_0;
  logic [49:0] f_s0_io_out_s1_full_pred_3_targets_0 = '0, f_s1_io_out_s1_full_pred_3_targets_0 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_3_targets_1, f_i_io_out_s1_full_pred_3_targets_1;
  logic [49:0] f_s0_io_out_s1_full_pred_3_targets_1 = '0, f_s1_io_out_s1_full_pred_3_targets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_3_jalr_target, f_i_io_out_s1_full_pred_3_jalr_target;
  logic [49:0] f_s0_io_out_s1_full_pred_3_jalr_target = '0, f_s1_io_out_s1_full_pred_3_jalr_target = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_3_offsets_0, f_i_io_out_s1_full_pred_3_offsets_0;
  logic [3:0] f_s0_io_out_s1_full_pred_3_offsets_0 = '0, f_s1_io_out_s1_full_pred_3_offsets_0 = '0;
  wire  [3:0] f_g_io_out_s1_full_pred_3_offsets_1, f_i_io_out_s1_full_pred_3_offsets_1;
  logic [3:0] f_s0_io_out_s1_full_pred_3_offsets_1 = '0, f_s1_io_out_s1_full_pred_3_offsets_1 = '0;
  wire  [49:0] f_g_io_out_s1_full_pred_3_fallThroughAddr, f_i_io_out_s1_full_pred_3_fallThroughAddr;
  logic [49:0] f_s0_io_out_s1_full_pred_3_fallThroughAddr = '0, f_s1_io_out_s1_full_pred_3_fallThroughAddr = '0;
  wire  f_g_io_out_s1_full_pred_3_fallThroughErr, f_i_io_out_s1_full_pred_3_fallThroughErr;
  logic f_s0_io_out_s1_full_pred_3_fallThroughErr = '0, f_s1_io_out_s1_full_pred_3_fallThroughErr = '0;
  wire  f_g_io_out_s1_full_pred_3_is_jal, f_i_io_out_s1_full_pred_3_is_jal;
  logic f_s0_io_out_s1_full_pred_3_is_jal = '0, f_s1_io_out_s1_full_pred_3_is_jal = '0;
  wire  f_g_io_out_s1_full_pred_3_is_jalr, f_i_io_out_s1_full_pred_3_is_jalr;
  logic f_s0_io_out_s1_full_pred_3_is_jalr = '0, f_s1_io_out_s1_full_pred_3_is_jalr = '0;
  wire  f_g_io_out_s1_full_pred_3_is_call, f_i_io_out_s1_full_pred_3_is_call;
  logic f_s0_io_out_s1_full_pred_3_is_call = '0, f_s1_io_out_s1_full_pred_3_is_call = '0;
  wire  f_g_io_out_s1_full_pred_3_is_ret, f_i_io_out_s1_full_pred_3_is_ret;
  logic f_s0_io_out_s1_full_pred_3_is_ret = '0, f_s1_io_out_s1_full_pred_3_is_ret = '0;
  wire  f_g_io_out_s1_full_pred_3_last_may_be_rvi_call, f_i_io_out_s1_full_pred_3_last_may_be_rvi_call;
  logic f_s0_io_out_s1_full_pred_3_last_may_be_rvi_call = '0, f_s1_io_out_s1_full_pred_3_last_may_be_rvi_call = '0;
  wire  f_g_io_out_s1_full_pred_3_is_br_sharing, f_i_io_out_s1_full_pred_3_is_br_sharing;
  logic f_s0_io_out_s1_full_pred_3_is_br_sharing = '0, f_s1_io_out_s1_full_pred_3_is_br_sharing = '0;
  wire  f_g_io_out_s1_full_pred_3_hit, f_i_io_out_s1_full_pred_3_hit;
  logic f_s0_io_out_s1_full_pred_3_hit = '0, f_s1_io_out_s1_full_pred_3_hit = '0;
  wire  [515:0] f_g_io_out_last_stage_meta, f_i_io_out_last_stage_meta;
  logic [515:0] f_s0_io_out_last_stage_meta = '0, f_s1_io_out_last_stage_meta = '0;
  wire  f_g_io_fauftb_entry_out_isCall, f_i_io_fauftb_entry_out_isCall;
  logic f_s0_io_fauftb_entry_out_isCall = '0, f_s1_io_fauftb_entry_out_isCall = '0;
  wire  f_g_io_fauftb_entry_out_isRet, f_i_io_fauftb_entry_out_isRet;
  logic f_s0_io_fauftb_entry_out_isRet = '0, f_s1_io_fauftb_entry_out_isRet = '0;
  wire  f_g_io_fauftb_entry_out_isJalr, f_i_io_fauftb_entry_out_isJalr;
  logic f_s0_io_fauftb_entry_out_isJalr = '0, f_s1_io_fauftb_entry_out_isJalr = '0;
  wire  f_g_io_fauftb_entry_out_valid, f_i_io_fauftb_entry_out_valid;
  logic f_s0_io_fauftb_entry_out_valid = '0, f_s1_io_fauftb_entry_out_valid = '0;
  wire  [3:0] f_g_io_fauftb_entry_out_brSlots_0_offset, f_i_io_fauftb_entry_out_brSlots_0_offset;
  logic [3:0] f_s0_io_fauftb_entry_out_brSlots_0_offset = '0, f_s1_io_fauftb_entry_out_brSlots_0_offset = '0;
  wire  f_g_io_fauftb_entry_out_brSlots_0_sharing, f_i_io_fauftb_entry_out_brSlots_0_sharing;
  logic f_s0_io_fauftb_entry_out_brSlots_0_sharing = '0, f_s1_io_fauftb_entry_out_brSlots_0_sharing = '0;
  wire  f_g_io_fauftb_entry_out_brSlots_0_valid, f_i_io_fauftb_entry_out_brSlots_0_valid;
  logic f_s0_io_fauftb_entry_out_brSlots_0_valid = '0, f_s1_io_fauftb_entry_out_brSlots_0_valid = '0;
  wire  [11:0] f_g_io_fauftb_entry_out_brSlots_0_lower, f_i_io_fauftb_entry_out_brSlots_0_lower;
  logic [11:0] f_s0_io_fauftb_entry_out_brSlots_0_lower = '0, f_s1_io_fauftb_entry_out_brSlots_0_lower = '0;
  wire  [1:0] f_g_io_fauftb_entry_out_brSlots_0_tarStat, f_i_io_fauftb_entry_out_brSlots_0_tarStat;
  logic [1:0] f_s0_io_fauftb_entry_out_brSlots_0_tarStat = '0, f_s1_io_fauftb_entry_out_brSlots_0_tarStat = '0;
  wire  [3:0] f_g_io_fauftb_entry_out_tailSlot_offset, f_i_io_fauftb_entry_out_tailSlot_offset;
  logic [3:0] f_s0_io_fauftb_entry_out_tailSlot_offset = '0, f_s1_io_fauftb_entry_out_tailSlot_offset = '0;
  wire  f_g_io_fauftb_entry_out_tailSlot_sharing, f_i_io_fauftb_entry_out_tailSlot_sharing;
  logic f_s0_io_fauftb_entry_out_tailSlot_sharing = '0, f_s1_io_fauftb_entry_out_tailSlot_sharing = '0;
  wire  f_g_io_fauftb_entry_out_tailSlot_valid, f_i_io_fauftb_entry_out_tailSlot_valid;
  logic f_s0_io_fauftb_entry_out_tailSlot_valid = '0, f_s1_io_fauftb_entry_out_tailSlot_valid = '0;
  wire  [19:0] f_g_io_fauftb_entry_out_tailSlot_lower, f_i_io_fauftb_entry_out_tailSlot_lower;
  logic [19:0] f_s0_io_fauftb_entry_out_tailSlot_lower = '0, f_s1_io_fauftb_entry_out_tailSlot_lower = '0;
  wire  [1:0] f_g_io_fauftb_entry_out_tailSlot_tarStat, f_i_io_fauftb_entry_out_tailSlot_tarStat;
  logic [1:0] f_s0_io_fauftb_entry_out_tailSlot_tarStat = '0, f_s1_io_fauftb_entry_out_tailSlot_tarStat = '0;
  wire  [3:0] f_g_io_fauftb_entry_out_pftAddr, f_i_io_fauftb_entry_out_pftAddr;
  logic [3:0] f_s0_io_fauftb_entry_out_pftAddr = '0, f_s1_io_fauftb_entry_out_pftAddr = '0;
  wire  f_g_io_fauftb_entry_out_carry, f_i_io_fauftb_entry_out_carry;
  logic f_s0_io_fauftb_entry_out_carry = '0, f_s1_io_fauftb_entry_out_carry = '0;
  wire  f_g_io_fauftb_entry_out_last_may_be_rvi_call, f_i_io_fauftb_entry_out_last_may_be_rvi_call;
  logic f_s0_io_fauftb_entry_out_last_may_be_rvi_call = '0, f_s1_io_fauftb_entry_out_last_may_be_rvi_call = '0;
  wire  f_g_io_fauftb_entry_out_strong_bias_0, f_i_io_fauftb_entry_out_strong_bias_0;
  logic f_s0_io_fauftb_entry_out_strong_bias_0 = '0, f_s1_io_fauftb_entry_out_strong_bias_0 = '0;
  wire  f_g_io_fauftb_entry_out_strong_bias_1, f_i_io_fauftb_entry_out_strong_bias_1;
  logic f_s0_io_fauftb_entry_out_strong_bias_1 = '0, f_s1_io_fauftb_entry_out_strong_bias_1 = '0;
  wire  f_g_io_fauftb_entry_hit_out, f_i_io_fauftb_entry_hit_out;
  logic f_s0_io_fauftb_entry_hit_out = '0, f_s1_io_fauftb_entry_hit_out = '0;
  logic f_io_ctrl_ubtb_enable;
  logic f_io_s0_fire_0;
  logic f_io_s0_fire_1;
  logic f_io_s0_fire_2;
  logic f_io_s0_fire_3;
  logic f_io_s1_fire_0;
  logic f_io_s1_fire_1;
  logic f_io_s1_fire_2;
  logic f_io_s1_fire_3;
  logic f_io_s2_fire_0;
  logic f_io_s2_fire_1;
  logic f_io_s2_fire_2;
  logic f_io_s2_fire_3;
  logic f_io_update_valid;
  logic [49:0] f_io_update_bits_pc;
  logic f_io_update_bits_ftb_entry_isCall;
  logic f_io_update_bits_ftb_entry_isRet;
  logic f_io_update_bits_ftb_entry_isJalr;
  logic f_io_update_bits_ftb_entry_valid;
  logic [3:0] f_io_update_bits_ftb_entry_brSlots_0_offset;
  logic f_io_update_bits_ftb_entry_brSlots_0_sharing;
  logic f_io_update_bits_ftb_entry_brSlots_0_valid;
  logic [11:0] f_io_update_bits_ftb_entry_brSlots_0_lower;
  logic [1:0] f_io_update_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0] f_io_update_bits_ftb_entry_tailSlot_offset;
  logic f_io_update_bits_ftb_entry_tailSlot_sharing;
  logic f_io_update_bits_ftb_entry_tailSlot_valid;
  logic [19:0] f_io_update_bits_ftb_entry_tailSlot_lower;
  logic [1:0] f_io_update_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0] f_io_update_bits_ftb_entry_pftAddr;
  logic f_io_update_bits_ftb_entry_carry;
  logic f_io_update_bits_ftb_entry_last_may_be_rvi_call;
  logic f_io_update_bits_ftb_entry_strong_bias_0;
  logic f_io_update_bits_ftb_entry_strong_bias_1;
  logic f_io_update_bits_br_taken_mask_0;
  logic f_io_update_bits_br_taken_mask_1;
  logic [515:0] f_io_update_bits_meta;
  wire  [5:0] f_g_io_perf_0_value, f_i_io_perf_0_value;
  logic [5:0] f_s0_io_perf_0_value = '0, f_s1_io_perf_0_value = '0;
  wire  [5:0] f_g_io_perf_1_value, f_i_io_perf_1_value;
  logic [5:0] f_s0_io_perf_1_value = '0, f_s1_io_perf_1_value = '0;
  int f_cov_pred_hit = 0;
  int f_cov_update_hit_writeback = 0;
  int f_cov_replace_when_full = 0;
  int f_cov_ctr_sat_hold = 0;
  int f_cov_fall_through_err = 0;
  int f_cov_double_touch = 0;
  logic [1:0] f_armed = '0;
  int f_armed_at = -1;
  FauFTB f_u_gold (
    .clock(clk),
    .reset(f_reset),
    .io_reset_vector(f_io_reset_vector),
    .io_in_bits_s0_pc_0(f_io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(f_io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(f_io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(f_io_in_bits_s0_pc_3),
    .io_out_s1_pc_0(f_g_io_out_s1_pc_0),
    .io_out_s1_pc_1(f_g_io_out_s1_pc_1),
    .io_out_s1_pc_2(f_g_io_out_s1_pc_2),
    .io_out_s1_pc_3(f_g_io_out_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0(f_g_io_out_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1(f_g_io_out_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0(f_g_io_out_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1(f_g_io_out_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0(f_g_io_out_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1(f_g_io_out_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target(f_g_io_out_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0(f_g_io_out_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1(f_g_io_out_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr(f_g_io_out_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr(f_g_io_out_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal(f_g_io_out_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr(f_g_io_out_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call(f_g_io_out_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret(f_g_io_out_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call(f_g_io_out_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing(f_g_io_out_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit(f_g_io_out_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0(f_g_io_out_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1(f_g_io_out_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0(f_g_io_out_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1(f_g_io_out_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0(f_g_io_out_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1(f_g_io_out_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target(f_g_io_out_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0(f_g_io_out_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1(f_g_io_out_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr(f_g_io_out_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr(f_g_io_out_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal(f_g_io_out_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr(f_g_io_out_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call(f_g_io_out_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret(f_g_io_out_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call(f_g_io_out_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing(f_g_io_out_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit(f_g_io_out_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0(f_g_io_out_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1(f_g_io_out_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0(f_g_io_out_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1(f_g_io_out_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0(f_g_io_out_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1(f_g_io_out_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target(f_g_io_out_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0(f_g_io_out_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1(f_g_io_out_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr(f_g_io_out_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr(f_g_io_out_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal(f_g_io_out_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr(f_g_io_out_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call(f_g_io_out_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret(f_g_io_out_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call(f_g_io_out_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing(f_g_io_out_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit(f_g_io_out_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0(f_g_io_out_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1(f_g_io_out_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0(f_g_io_out_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1(f_g_io_out_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0(f_g_io_out_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1(f_g_io_out_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target(f_g_io_out_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0(f_g_io_out_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1(f_g_io_out_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr(f_g_io_out_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr(f_g_io_out_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal(f_g_io_out_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr(f_g_io_out_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call(f_g_io_out_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret(f_g_io_out_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call(f_g_io_out_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing(f_g_io_out_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit(f_g_io_out_s1_full_pred_3_hit),
    .io_out_last_stage_meta(f_g_io_out_last_stage_meta),
    .io_fauftb_entry_out_isCall(f_g_io_fauftb_entry_out_isCall),
    .io_fauftb_entry_out_isRet(f_g_io_fauftb_entry_out_isRet),
    .io_fauftb_entry_out_isJalr(f_g_io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_out_valid(f_g_io_fauftb_entry_out_valid),
    .io_fauftb_entry_out_brSlots_0_offset(f_g_io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_out_brSlots_0_sharing(f_g_io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_out_brSlots_0_valid(f_g_io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_out_brSlots_0_lower(f_g_io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_out_brSlots_0_tarStat(f_g_io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_out_tailSlot_offset(f_g_io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_out_tailSlot_sharing(f_g_io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_out_tailSlot_valid(f_g_io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_out_tailSlot_lower(f_g_io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_out_tailSlot_tarStat(f_g_io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_out_pftAddr(f_g_io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_out_carry(f_g_io_fauftb_entry_out_carry),
    .io_fauftb_entry_out_last_may_be_rvi_call(f_g_io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_out_strong_bias_0(f_g_io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_out_strong_bias_1(f_g_io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_out(f_g_io_fauftb_entry_hit_out),
    .io_ctrl_ubtb_enable(f_io_ctrl_ubtb_enable),
    .io_s0_fire_0(f_io_s0_fire_0),
    .io_s0_fire_1(f_io_s0_fire_1),
    .io_s0_fire_2(f_io_s0_fire_2),
    .io_s0_fire_3(f_io_s0_fire_3),
    .io_s1_fire_0(f_io_s1_fire_0),
    .io_s1_fire_1(f_io_s1_fire_1),
    .io_s1_fire_2(f_io_s1_fire_2),
    .io_s1_fire_3(f_io_s1_fire_3),
    .io_s2_fire_0(f_io_s2_fire_0),
    .io_s2_fire_1(f_io_s2_fire_1),
    .io_s2_fire_2(f_io_s2_fire_2),
    .io_s2_fire_3(f_io_s2_fire_3),
    .io_update_valid(f_io_update_valid),
    .io_update_bits_pc(f_io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall(f_io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet(f_io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr(f_io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid(f_io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset(f_io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing(f_io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid(f_io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower(f_io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat(f_io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset(f_io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing(f_io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid(f_io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower(f_io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat(f_io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr(f_io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry(f_io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call(f_io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0(f_io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1(f_io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0(f_io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1(f_io_update_bits_br_taken_mask_1),
    .io_update_bits_meta(f_io_update_bits_meta),
    .io_perf_0_value(f_g_io_perf_0_value),
    .io_perf_1_value(f_g_io_perf_1_value)
  );
  FauFTB_xs f_u_impl (
    .clock(clk),
    .reset(f_reset),
    .io_reset_vector(f_io_reset_vector),
    .io_in_bits_s0_pc_0(f_io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(f_io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(f_io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(f_io_in_bits_s0_pc_3),
    .io_out_s1_pc_0(f_i_io_out_s1_pc_0),
    .io_out_s1_pc_1(f_i_io_out_s1_pc_1),
    .io_out_s1_pc_2(f_i_io_out_s1_pc_2),
    .io_out_s1_pc_3(f_i_io_out_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0(f_i_io_out_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1(f_i_io_out_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0(f_i_io_out_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1(f_i_io_out_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0(f_i_io_out_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1(f_i_io_out_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target(f_i_io_out_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0(f_i_io_out_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1(f_i_io_out_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr(f_i_io_out_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr(f_i_io_out_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal(f_i_io_out_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr(f_i_io_out_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call(f_i_io_out_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret(f_i_io_out_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call(f_i_io_out_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing(f_i_io_out_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit(f_i_io_out_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0(f_i_io_out_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1(f_i_io_out_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0(f_i_io_out_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1(f_i_io_out_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0(f_i_io_out_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1(f_i_io_out_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target(f_i_io_out_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0(f_i_io_out_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1(f_i_io_out_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr(f_i_io_out_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr(f_i_io_out_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal(f_i_io_out_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr(f_i_io_out_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call(f_i_io_out_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret(f_i_io_out_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call(f_i_io_out_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing(f_i_io_out_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit(f_i_io_out_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0(f_i_io_out_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1(f_i_io_out_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0(f_i_io_out_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1(f_i_io_out_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0(f_i_io_out_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1(f_i_io_out_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target(f_i_io_out_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0(f_i_io_out_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1(f_i_io_out_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr(f_i_io_out_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr(f_i_io_out_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal(f_i_io_out_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr(f_i_io_out_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call(f_i_io_out_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret(f_i_io_out_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call(f_i_io_out_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing(f_i_io_out_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit(f_i_io_out_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0(f_i_io_out_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1(f_i_io_out_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0(f_i_io_out_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1(f_i_io_out_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0(f_i_io_out_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1(f_i_io_out_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target(f_i_io_out_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0(f_i_io_out_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1(f_i_io_out_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr(f_i_io_out_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr(f_i_io_out_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal(f_i_io_out_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr(f_i_io_out_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call(f_i_io_out_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret(f_i_io_out_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call(f_i_io_out_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing(f_i_io_out_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit(f_i_io_out_s1_full_pred_3_hit),
    .io_out_last_stage_meta(f_i_io_out_last_stage_meta),
    .io_fauftb_entry_out_isCall(f_i_io_fauftb_entry_out_isCall),
    .io_fauftb_entry_out_isRet(f_i_io_fauftb_entry_out_isRet),
    .io_fauftb_entry_out_isJalr(f_i_io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_out_valid(f_i_io_fauftb_entry_out_valid),
    .io_fauftb_entry_out_brSlots_0_offset(f_i_io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_out_brSlots_0_sharing(f_i_io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_out_brSlots_0_valid(f_i_io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_out_brSlots_0_lower(f_i_io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_out_brSlots_0_tarStat(f_i_io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_out_tailSlot_offset(f_i_io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_out_tailSlot_sharing(f_i_io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_out_tailSlot_valid(f_i_io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_out_tailSlot_lower(f_i_io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_out_tailSlot_tarStat(f_i_io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_out_pftAddr(f_i_io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_out_carry(f_i_io_fauftb_entry_out_carry),
    .io_fauftb_entry_out_last_may_be_rvi_call(f_i_io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_out_strong_bias_0(f_i_io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_out_strong_bias_1(f_i_io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_out(f_i_io_fauftb_entry_hit_out),
    .io_ctrl_ubtb_enable(f_io_ctrl_ubtb_enable),
    .io_s0_fire_0(f_io_s0_fire_0),
    .io_s0_fire_1(f_io_s0_fire_1),
    .io_s0_fire_2(f_io_s0_fire_2),
    .io_s0_fire_3(f_io_s0_fire_3),
    .io_s1_fire_0(f_io_s1_fire_0),
    .io_s1_fire_1(f_io_s1_fire_1),
    .io_s1_fire_2(f_io_s1_fire_2),
    .io_s1_fire_3(f_io_s1_fire_3),
    .io_s2_fire_0(f_io_s2_fire_0),
    .io_s2_fire_1(f_io_s2_fire_1),
    .io_s2_fire_2(f_io_s2_fire_2),
    .io_s2_fire_3(f_io_s2_fire_3),
    .io_update_valid(f_io_update_valid),
    .io_update_bits_pc(f_io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall(f_io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet(f_io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr(f_io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid(f_io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset(f_io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing(f_io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid(f_io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower(f_io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat(f_io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset(f_io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing(f_io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid(f_io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower(f_io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat(f_io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr(f_io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry(f_io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call(f_io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0(f_io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1(f_io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0(f_io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1(f_io_update_bits_br_taken_mask_1),
    .io_update_bits_meta(f_io_update_bits_meta),
    .io_perf_0_value(f_i_io_perf_0_value),
    .io_perf_1_value(f_i_io_perf_1_value)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) f_mode = $urandom_range(0, 15);
      f_io_reset_vector = 48'({$urandom, $urandom});
      f_io_in_bits_s0_pc_0 = 50'({$urandom, $urandom});
      f_io_in_bits_s0_pc_1 = 50'({$urandom, $urandom});
      f_io_in_bits_s0_pc_2 = 50'({$urandom, $urandom});
      f_io_in_bits_s0_pc_3 = 50'({$urandom, $urandom});
      f_io_ctrl_ubtb_enable = 1'($urandom);
      f_io_s0_fire_0 = 1'($urandom);
      f_io_s0_fire_1 = 1'($urandom);
      f_io_s0_fire_2 = 1'($urandom);
      f_io_s0_fire_3 = 1'($urandom);
      f_io_s1_fire_0 = 1'($urandom);
      f_io_s1_fire_1 = 1'($urandom);
      f_io_s1_fire_2 = 1'($urandom);
      f_io_s1_fire_3 = 1'($urandom);
      f_io_s2_fire_0 = 1'($urandom);
      f_io_s2_fire_1 = 1'($urandom);
      f_io_s2_fire_2 = 1'($urandom);
      f_io_s2_fire_3 = 1'($urandom);
      f_io_update_valid = 1'($urandom);
      f_io_update_bits_pc = 50'({$urandom, $urandom});
      f_io_update_bits_ftb_entry_isCall = 1'($urandom);
      f_io_update_bits_ftb_entry_isRet = 1'($urandom);
      f_io_update_bits_ftb_entry_isJalr = 1'($urandom);
      f_io_update_bits_ftb_entry_valid = 1'($urandom);
      f_io_update_bits_ftb_entry_brSlots_0_offset = 4'($urandom);
      f_io_update_bits_ftb_entry_brSlots_0_sharing = 1'($urandom);
      f_io_update_bits_ftb_entry_brSlots_0_valid = 1'($urandom);
      f_io_update_bits_ftb_entry_brSlots_0_lower = 12'($urandom);
      f_io_update_bits_ftb_entry_brSlots_0_tarStat = 2'($urandom);
      f_io_update_bits_ftb_entry_tailSlot_offset = 4'($urandom);
      f_io_update_bits_ftb_entry_tailSlot_sharing = 1'($urandom);
      f_io_update_bits_ftb_entry_tailSlot_valid = 1'($urandom);
      f_io_update_bits_ftb_entry_tailSlot_lower = 20'($urandom);
      f_io_update_bits_ftb_entry_tailSlot_tarStat = 2'($urandom);
      f_io_update_bits_ftb_entry_pftAddr = 4'($urandom);
      f_io_update_bits_ftb_entry_carry = 1'($urandom);
      f_io_update_bits_ftb_entry_last_may_be_rvi_call = 1'($urandom);
      f_io_update_bits_ftb_entry_strong_bias_0 = 1'($urandom);
      f_io_update_bits_ftb_entry_strong_bias_1 = 1'($urandom);
      f_io_update_bits_br_taken_mask_0 = 1'($urandom);
      f_io_update_bits_br_taken_mask_1 = 1'($urandom);
      f_io_update_bits_meta = 516'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      f_reset = (cyc < RESET_CYC) || ($urandom_range(0, 29999) == 0);
      begin : stim_f
        f_io_in_bits_s0_pc_0 = f_pool[$urandom_range(0, 47)];
        f_io_in_bits_s0_pc_1 = f_pool[$urandom_range(0, 47)];
        f_io_in_bits_s0_pc_2 = f_pool[$urandom_range(0, 47)];
        f_io_in_bits_s0_pc_3 = f_pool[$urandom_range(0, 47)];
        f_io_update_bits_pc = f_pool[$urandom_range(0, 47)];
        f_io_update_valid = ($urandom_range(0, 3) != 0);
        f_io_ctrl_ubtb_enable = (f_mode != 3);
      end
      #4;
      if (cyc >= RESET_CYC + 0 && f_armed_at >= 0 && cyc >= f_armed_at) begin
        checks++;
        if (f_g_io_out_s1_pc_0 !== f_i_io_out_s1_pc_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_pc_0 g=%h i=%h", cyc, f_g_io_out_s1_pc_0, f_i_io_out_s1_pc_0);
        end
        f_s1_io_out_s1_pc_0 |= f_g_io_out_s1_pc_0;
        f_s0_io_out_s1_pc_0 |= ~f_g_io_out_s1_pc_0;
        checks++;
        if (f_g_io_out_s1_pc_1 !== f_i_io_out_s1_pc_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_pc_1 g=%h i=%h", cyc, f_g_io_out_s1_pc_1, f_i_io_out_s1_pc_1);
        end
        f_s1_io_out_s1_pc_1 |= f_g_io_out_s1_pc_1;
        f_s0_io_out_s1_pc_1 |= ~f_g_io_out_s1_pc_1;
        checks++;
        if (f_g_io_out_s1_pc_2 !== f_i_io_out_s1_pc_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_pc_2 g=%h i=%h", cyc, f_g_io_out_s1_pc_2, f_i_io_out_s1_pc_2);
        end
        f_s1_io_out_s1_pc_2 |= f_g_io_out_s1_pc_2;
        f_s0_io_out_s1_pc_2 |= ~f_g_io_out_s1_pc_2;
        checks++;
        if (f_g_io_out_s1_pc_3 !== f_i_io_out_s1_pc_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_pc_3 g=%h i=%h", cyc, f_g_io_out_s1_pc_3, f_i_io_out_s1_pc_3);
        end
        f_s1_io_out_s1_pc_3 |= f_g_io_out_s1_pc_3;
        f_s0_io_out_s1_pc_3 |= ~f_g_io_out_s1_pc_3;
        checks++;
        if (f_g_io_out_s1_full_pred_0_br_taken_mask_0 !== f_i_io_out_s1_full_pred_0_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_br_taken_mask_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_br_taken_mask_0, f_i_io_out_s1_full_pred_0_br_taken_mask_0);
        end
        f_s1_io_out_s1_full_pred_0_br_taken_mask_0 |= f_g_io_out_s1_full_pred_0_br_taken_mask_0;
        f_s0_io_out_s1_full_pred_0_br_taken_mask_0 |= ~f_g_io_out_s1_full_pred_0_br_taken_mask_0;
        checks++;
        if (f_g_io_out_s1_full_pred_0_br_taken_mask_1 !== f_i_io_out_s1_full_pred_0_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_br_taken_mask_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_br_taken_mask_1, f_i_io_out_s1_full_pred_0_br_taken_mask_1);
        end
        f_s1_io_out_s1_full_pred_0_br_taken_mask_1 |= f_g_io_out_s1_full_pred_0_br_taken_mask_1;
        f_s0_io_out_s1_full_pred_0_br_taken_mask_1 |= ~f_g_io_out_s1_full_pred_0_br_taken_mask_1;
        checks++;
        if (f_g_io_out_s1_full_pred_0_slot_valids_0 !== f_i_io_out_s1_full_pred_0_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_slot_valids_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_slot_valids_0, f_i_io_out_s1_full_pred_0_slot_valids_0);
        end
        f_s1_io_out_s1_full_pred_0_slot_valids_0 |= f_g_io_out_s1_full_pred_0_slot_valids_0;
        f_s0_io_out_s1_full_pred_0_slot_valids_0 |= ~f_g_io_out_s1_full_pred_0_slot_valids_0;
        checks++;
        if (f_g_io_out_s1_full_pred_0_slot_valids_1 !== f_i_io_out_s1_full_pred_0_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_slot_valids_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_slot_valids_1, f_i_io_out_s1_full_pred_0_slot_valids_1);
        end
        f_s1_io_out_s1_full_pred_0_slot_valids_1 |= f_g_io_out_s1_full_pred_0_slot_valids_1;
        f_s0_io_out_s1_full_pred_0_slot_valids_1 |= ~f_g_io_out_s1_full_pred_0_slot_valids_1;
        checks++;
        if (f_g_io_out_s1_full_pred_0_targets_0 !== f_i_io_out_s1_full_pred_0_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_targets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_targets_0, f_i_io_out_s1_full_pred_0_targets_0);
        end
        f_s1_io_out_s1_full_pred_0_targets_0 |= f_g_io_out_s1_full_pred_0_targets_0;
        f_s0_io_out_s1_full_pred_0_targets_0 |= ~f_g_io_out_s1_full_pred_0_targets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_0_targets_1 !== f_i_io_out_s1_full_pred_0_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_targets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_targets_1, f_i_io_out_s1_full_pred_0_targets_1);
        end
        f_s1_io_out_s1_full_pred_0_targets_1 |= f_g_io_out_s1_full_pred_0_targets_1;
        f_s0_io_out_s1_full_pred_0_targets_1 |= ~f_g_io_out_s1_full_pred_0_targets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_0_jalr_target !== f_i_io_out_s1_full_pred_0_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_jalr_target g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_jalr_target, f_i_io_out_s1_full_pred_0_jalr_target);
        end
        f_s1_io_out_s1_full_pred_0_jalr_target |= f_g_io_out_s1_full_pred_0_jalr_target;
        f_s0_io_out_s1_full_pred_0_jalr_target |= ~f_g_io_out_s1_full_pred_0_jalr_target;
        checks++;
        if (f_g_io_out_s1_full_pred_0_offsets_0 !== f_i_io_out_s1_full_pred_0_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_offsets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_offsets_0, f_i_io_out_s1_full_pred_0_offsets_0);
        end
        f_s1_io_out_s1_full_pred_0_offsets_0 |= f_g_io_out_s1_full_pred_0_offsets_0;
        f_s0_io_out_s1_full_pred_0_offsets_0 |= ~f_g_io_out_s1_full_pred_0_offsets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_0_offsets_1 !== f_i_io_out_s1_full_pred_0_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_offsets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_offsets_1, f_i_io_out_s1_full_pred_0_offsets_1);
        end
        f_s1_io_out_s1_full_pred_0_offsets_1 |= f_g_io_out_s1_full_pred_0_offsets_1;
        f_s0_io_out_s1_full_pred_0_offsets_1 |= ~f_g_io_out_s1_full_pred_0_offsets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_0_fallThroughAddr !== f_i_io_out_s1_full_pred_0_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_fallThroughAddr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_fallThroughAddr, f_i_io_out_s1_full_pred_0_fallThroughAddr);
        end
        f_s1_io_out_s1_full_pred_0_fallThroughAddr |= f_g_io_out_s1_full_pred_0_fallThroughAddr;
        f_s0_io_out_s1_full_pred_0_fallThroughAddr |= ~f_g_io_out_s1_full_pred_0_fallThroughAddr;
        checks++;
        if (f_g_io_out_s1_full_pred_0_fallThroughErr !== f_i_io_out_s1_full_pred_0_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_fallThroughErr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_fallThroughErr, f_i_io_out_s1_full_pred_0_fallThroughErr);
        end
        f_s1_io_out_s1_full_pred_0_fallThroughErr |= f_g_io_out_s1_full_pred_0_fallThroughErr;
        f_s0_io_out_s1_full_pred_0_fallThroughErr |= ~f_g_io_out_s1_full_pred_0_fallThroughErr;
        checks++;
        if (f_g_io_out_s1_full_pred_0_is_jal !== f_i_io_out_s1_full_pred_0_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_is_jal g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_is_jal, f_i_io_out_s1_full_pred_0_is_jal);
        end
        f_s1_io_out_s1_full_pred_0_is_jal |= f_g_io_out_s1_full_pred_0_is_jal;
        f_s0_io_out_s1_full_pred_0_is_jal |= ~f_g_io_out_s1_full_pred_0_is_jal;
        checks++;
        if (f_g_io_out_s1_full_pred_0_is_jalr !== f_i_io_out_s1_full_pred_0_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_is_jalr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_is_jalr, f_i_io_out_s1_full_pred_0_is_jalr);
        end
        f_s1_io_out_s1_full_pred_0_is_jalr |= f_g_io_out_s1_full_pred_0_is_jalr;
        f_s0_io_out_s1_full_pred_0_is_jalr |= ~f_g_io_out_s1_full_pred_0_is_jalr;
        checks++;
        if (f_g_io_out_s1_full_pred_0_is_call !== f_i_io_out_s1_full_pred_0_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_is_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_is_call, f_i_io_out_s1_full_pred_0_is_call);
        end
        f_s1_io_out_s1_full_pred_0_is_call |= f_g_io_out_s1_full_pred_0_is_call;
        f_s0_io_out_s1_full_pred_0_is_call |= ~f_g_io_out_s1_full_pred_0_is_call;
        checks++;
        if (f_g_io_out_s1_full_pred_0_is_ret !== f_i_io_out_s1_full_pred_0_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_is_ret g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_is_ret, f_i_io_out_s1_full_pred_0_is_ret);
        end
        f_s1_io_out_s1_full_pred_0_is_ret |= f_g_io_out_s1_full_pred_0_is_ret;
        f_s0_io_out_s1_full_pred_0_is_ret |= ~f_g_io_out_s1_full_pred_0_is_ret;
        checks++;
        if (f_g_io_out_s1_full_pred_0_last_may_be_rvi_call !== f_i_io_out_s1_full_pred_0_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_last_may_be_rvi_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_last_may_be_rvi_call, f_i_io_out_s1_full_pred_0_last_may_be_rvi_call);
        end
        f_s1_io_out_s1_full_pred_0_last_may_be_rvi_call |= f_g_io_out_s1_full_pred_0_last_may_be_rvi_call;
        f_s0_io_out_s1_full_pred_0_last_may_be_rvi_call |= ~f_g_io_out_s1_full_pred_0_last_may_be_rvi_call;
        checks++;
        if (f_g_io_out_s1_full_pred_0_is_br_sharing !== f_i_io_out_s1_full_pred_0_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_is_br_sharing g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_is_br_sharing, f_i_io_out_s1_full_pred_0_is_br_sharing);
        end
        f_s1_io_out_s1_full_pred_0_is_br_sharing |= f_g_io_out_s1_full_pred_0_is_br_sharing;
        f_s0_io_out_s1_full_pred_0_is_br_sharing |= ~f_g_io_out_s1_full_pred_0_is_br_sharing;
        checks++;
        if (f_g_io_out_s1_full_pred_0_hit !== f_i_io_out_s1_full_pred_0_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_0_hit g=%h i=%h", cyc, f_g_io_out_s1_full_pred_0_hit, f_i_io_out_s1_full_pred_0_hit);
        end
        f_s1_io_out_s1_full_pred_0_hit |= f_g_io_out_s1_full_pred_0_hit;
        f_s0_io_out_s1_full_pred_0_hit |= ~f_g_io_out_s1_full_pred_0_hit;
        checks++;
        if (f_g_io_out_s1_full_pred_1_br_taken_mask_0 !== f_i_io_out_s1_full_pred_1_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_br_taken_mask_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_br_taken_mask_0, f_i_io_out_s1_full_pred_1_br_taken_mask_0);
        end
        f_s1_io_out_s1_full_pred_1_br_taken_mask_0 |= f_g_io_out_s1_full_pred_1_br_taken_mask_0;
        f_s0_io_out_s1_full_pred_1_br_taken_mask_0 |= ~f_g_io_out_s1_full_pred_1_br_taken_mask_0;
        checks++;
        if (f_g_io_out_s1_full_pred_1_br_taken_mask_1 !== f_i_io_out_s1_full_pred_1_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_br_taken_mask_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_br_taken_mask_1, f_i_io_out_s1_full_pred_1_br_taken_mask_1);
        end
        f_s1_io_out_s1_full_pred_1_br_taken_mask_1 |= f_g_io_out_s1_full_pred_1_br_taken_mask_1;
        f_s0_io_out_s1_full_pred_1_br_taken_mask_1 |= ~f_g_io_out_s1_full_pred_1_br_taken_mask_1;
        checks++;
        if (f_g_io_out_s1_full_pred_1_slot_valids_0 !== f_i_io_out_s1_full_pred_1_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_slot_valids_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_slot_valids_0, f_i_io_out_s1_full_pred_1_slot_valids_0);
        end
        f_s1_io_out_s1_full_pred_1_slot_valids_0 |= f_g_io_out_s1_full_pred_1_slot_valids_0;
        f_s0_io_out_s1_full_pred_1_slot_valids_0 |= ~f_g_io_out_s1_full_pred_1_slot_valids_0;
        checks++;
        if (f_g_io_out_s1_full_pred_1_slot_valids_1 !== f_i_io_out_s1_full_pred_1_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_slot_valids_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_slot_valids_1, f_i_io_out_s1_full_pred_1_slot_valids_1);
        end
        f_s1_io_out_s1_full_pred_1_slot_valids_1 |= f_g_io_out_s1_full_pred_1_slot_valids_1;
        f_s0_io_out_s1_full_pred_1_slot_valids_1 |= ~f_g_io_out_s1_full_pred_1_slot_valids_1;
        checks++;
        if (f_g_io_out_s1_full_pred_1_targets_0 !== f_i_io_out_s1_full_pred_1_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_targets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_targets_0, f_i_io_out_s1_full_pred_1_targets_0);
        end
        f_s1_io_out_s1_full_pred_1_targets_0 |= f_g_io_out_s1_full_pred_1_targets_0;
        f_s0_io_out_s1_full_pred_1_targets_0 |= ~f_g_io_out_s1_full_pred_1_targets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_1_targets_1 !== f_i_io_out_s1_full_pred_1_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_targets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_targets_1, f_i_io_out_s1_full_pred_1_targets_1);
        end
        f_s1_io_out_s1_full_pred_1_targets_1 |= f_g_io_out_s1_full_pred_1_targets_1;
        f_s0_io_out_s1_full_pred_1_targets_1 |= ~f_g_io_out_s1_full_pred_1_targets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_1_jalr_target !== f_i_io_out_s1_full_pred_1_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_jalr_target g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_jalr_target, f_i_io_out_s1_full_pred_1_jalr_target);
        end
        f_s1_io_out_s1_full_pred_1_jalr_target |= f_g_io_out_s1_full_pred_1_jalr_target;
        f_s0_io_out_s1_full_pred_1_jalr_target |= ~f_g_io_out_s1_full_pred_1_jalr_target;
        checks++;
        if (f_g_io_out_s1_full_pred_1_offsets_0 !== f_i_io_out_s1_full_pred_1_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_offsets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_offsets_0, f_i_io_out_s1_full_pred_1_offsets_0);
        end
        f_s1_io_out_s1_full_pred_1_offsets_0 |= f_g_io_out_s1_full_pred_1_offsets_0;
        f_s0_io_out_s1_full_pred_1_offsets_0 |= ~f_g_io_out_s1_full_pred_1_offsets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_1_offsets_1 !== f_i_io_out_s1_full_pred_1_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_offsets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_offsets_1, f_i_io_out_s1_full_pred_1_offsets_1);
        end
        f_s1_io_out_s1_full_pred_1_offsets_1 |= f_g_io_out_s1_full_pred_1_offsets_1;
        f_s0_io_out_s1_full_pred_1_offsets_1 |= ~f_g_io_out_s1_full_pred_1_offsets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_1_fallThroughAddr !== f_i_io_out_s1_full_pred_1_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_fallThroughAddr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_fallThroughAddr, f_i_io_out_s1_full_pred_1_fallThroughAddr);
        end
        f_s1_io_out_s1_full_pred_1_fallThroughAddr |= f_g_io_out_s1_full_pred_1_fallThroughAddr;
        f_s0_io_out_s1_full_pred_1_fallThroughAddr |= ~f_g_io_out_s1_full_pred_1_fallThroughAddr;
        checks++;
        if (f_g_io_out_s1_full_pred_1_fallThroughErr !== f_i_io_out_s1_full_pred_1_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_fallThroughErr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_fallThroughErr, f_i_io_out_s1_full_pred_1_fallThroughErr);
        end
        f_s1_io_out_s1_full_pred_1_fallThroughErr |= f_g_io_out_s1_full_pred_1_fallThroughErr;
        f_s0_io_out_s1_full_pred_1_fallThroughErr |= ~f_g_io_out_s1_full_pred_1_fallThroughErr;
        checks++;
        if (f_g_io_out_s1_full_pred_1_is_jal !== f_i_io_out_s1_full_pred_1_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_is_jal g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_is_jal, f_i_io_out_s1_full_pred_1_is_jal);
        end
        f_s1_io_out_s1_full_pred_1_is_jal |= f_g_io_out_s1_full_pred_1_is_jal;
        f_s0_io_out_s1_full_pred_1_is_jal |= ~f_g_io_out_s1_full_pred_1_is_jal;
        checks++;
        if (f_g_io_out_s1_full_pred_1_is_jalr !== f_i_io_out_s1_full_pred_1_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_is_jalr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_is_jalr, f_i_io_out_s1_full_pred_1_is_jalr);
        end
        f_s1_io_out_s1_full_pred_1_is_jalr |= f_g_io_out_s1_full_pred_1_is_jalr;
        f_s0_io_out_s1_full_pred_1_is_jalr |= ~f_g_io_out_s1_full_pred_1_is_jalr;
        checks++;
        if (f_g_io_out_s1_full_pred_1_is_call !== f_i_io_out_s1_full_pred_1_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_is_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_is_call, f_i_io_out_s1_full_pred_1_is_call);
        end
        f_s1_io_out_s1_full_pred_1_is_call |= f_g_io_out_s1_full_pred_1_is_call;
        f_s0_io_out_s1_full_pred_1_is_call |= ~f_g_io_out_s1_full_pred_1_is_call;
        checks++;
        if (f_g_io_out_s1_full_pred_1_is_ret !== f_i_io_out_s1_full_pred_1_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_is_ret g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_is_ret, f_i_io_out_s1_full_pred_1_is_ret);
        end
        f_s1_io_out_s1_full_pred_1_is_ret |= f_g_io_out_s1_full_pred_1_is_ret;
        f_s0_io_out_s1_full_pred_1_is_ret |= ~f_g_io_out_s1_full_pred_1_is_ret;
        checks++;
        if (f_g_io_out_s1_full_pred_1_last_may_be_rvi_call !== f_i_io_out_s1_full_pred_1_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_last_may_be_rvi_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_last_may_be_rvi_call, f_i_io_out_s1_full_pred_1_last_may_be_rvi_call);
        end
        f_s1_io_out_s1_full_pred_1_last_may_be_rvi_call |= f_g_io_out_s1_full_pred_1_last_may_be_rvi_call;
        f_s0_io_out_s1_full_pred_1_last_may_be_rvi_call |= ~f_g_io_out_s1_full_pred_1_last_may_be_rvi_call;
        checks++;
        if (f_g_io_out_s1_full_pred_1_is_br_sharing !== f_i_io_out_s1_full_pred_1_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_is_br_sharing g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_is_br_sharing, f_i_io_out_s1_full_pred_1_is_br_sharing);
        end
        f_s1_io_out_s1_full_pred_1_is_br_sharing |= f_g_io_out_s1_full_pred_1_is_br_sharing;
        f_s0_io_out_s1_full_pred_1_is_br_sharing |= ~f_g_io_out_s1_full_pred_1_is_br_sharing;
        checks++;
        if (f_g_io_out_s1_full_pred_1_hit !== f_i_io_out_s1_full_pred_1_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_1_hit g=%h i=%h", cyc, f_g_io_out_s1_full_pred_1_hit, f_i_io_out_s1_full_pred_1_hit);
        end
        f_s1_io_out_s1_full_pred_1_hit |= f_g_io_out_s1_full_pred_1_hit;
        f_s0_io_out_s1_full_pred_1_hit |= ~f_g_io_out_s1_full_pred_1_hit;
        checks++;
        if (f_g_io_out_s1_full_pred_2_br_taken_mask_0 !== f_i_io_out_s1_full_pred_2_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_br_taken_mask_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_br_taken_mask_0, f_i_io_out_s1_full_pred_2_br_taken_mask_0);
        end
        f_s1_io_out_s1_full_pred_2_br_taken_mask_0 |= f_g_io_out_s1_full_pred_2_br_taken_mask_0;
        f_s0_io_out_s1_full_pred_2_br_taken_mask_0 |= ~f_g_io_out_s1_full_pred_2_br_taken_mask_0;
        checks++;
        if (f_g_io_out_s1_full_pred_2_br_taken_mask_1 !== f_i_io_out_s1_full_pred_2_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_br_taken_mask_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_br_taken_mask_1, f_i_io_out_s1_full_pred_2_br_taken_mask_1);
        end
        f_s1_io_out_s1_full_pred_2_br_taken_mask_1 |= f_g_io_out_s1_full_pred_2_br_taken_mask_1;
        f_s0_io_out_s1_full_pred_2_br_taken_mask_1 |= ~f_g_io_out_s1_full_pred_2_br_taken_mask_1;
        checks++;
        if (f_g_io_out_s1_full_pred_2_slot_valids_0 !== f_i_io_out_s1_full_pred_2_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_slot_valids_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_slot_valids_0, f_i_io_out_s1_full_pred_2_slot_valids_0);
        end
        f_s1_io_out_s1_full_pred_2_slot_valids_0 |= f_g_io_out_s1_full_pred_2_slot_valids_0;
        f_s0_io_out_s1_full_pred_2_slot_valids_0 |= ~f_g_io_out_s1_full_pred_2_slot_valids_0;
        checks++;
        if (f_g_io_out_s1_full_pred_2_slot_valids_1 !== f_i_io_out_s1_full_pred_2_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_slot_valids_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_slot_valids_1, f_i_io_out_s1_full_pred_2_slot_valids_1);
        end
        f_s1_io_out_s1_full_pred_2_slot_valids_1 |= f_g_io_out_s1_full_pred_2_slot_valids_1;
        f_s0_io_out_s1_full_pred_2_slot_valids_1 |= ~f_g_io_out_s1_full_pred_2_slot_valids_1;
        checks++;
        if (f_g_io_out_s1_full_pred_2_targets_0 !== f_i_io_out_s1_full_pred_2_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_targets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_targets_0, f_i_io_out_s1_full_pred_2_targets_0);
        end
        f_s1_io_out_s1_full_pred_2_targets_0 |= f_g_io_out_s1_full_pred_2_targets_0;
        f_s0_io_out_s1_full_pred_2_targets_0 |= ~f_g_io_out_s1_full_pred_2_targets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_2_targets_1 !== f_i_io_out_s1_full_pred_2_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_targets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_targets_1, f_i_io_out_s1_full_pred_2_targets_1);
        end
        f_s1_io_out_s1_full_pred_2_targets_1 |= f_g_io_out_s1_full_pred_2_targets_1;
        f_s0_io_out_s1_full_pred_2_targets_1 |= ~f_g_io_out_s1_full_pred_2_targets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_2_jalr_target !== f_i_io_out_s1_full_pred_2_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_jalr_target g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_jalr_target, f_i_io_out_s1_full_pred_2_jalr_target);
        end
        f_s1_io_out_s1_full_pred_2_jalr_target |= f_g_io_out_s1_full_pred_2_jalr_target;
        f_s0_io_out_s1_full_pred_2_jalr_target |= ~f_g_io_out_s1_full_pred_2_jalr_target;
        checks++;
        if (f_g_io_out_s1_full_pred_2_offsets_0 !== f_i_io_out_s1_full_pred_2_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_offsets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_offsets_0, f_i_io_out_s1_full_pred_2_offsets_0);
        end
        f_s1_io_out_s1_full_pred_2_offsets_0 |= f_g_io_out_s1_full_pred_2_offsets_0;
        f_s0_io_out_s1_full_pred_2_offsets_0 |= ~f_g_io_out_s1_full_pred_2_offsets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_2_offsets_1 !== f_i_io_out_s1_full_pred_2_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_offsets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_offsets_1, f_i_io_out_s1_full_pred_2_offsets_1);
        end
        f_s1_io_out_s1_full_pred_2_offsets_1 |= f_g_io_out_s1_full_pred_2_offsets_1;
        f_s0_io_out_s1_full_pred_2_offsets_1 |= ~f_g_io_out_s1_full_pred_2_offsets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_2_fallThroughAddr !== f_i_io_out_s1_full_pred_2_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_fallThroughAddr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_fallThroughAddr, f_i_io_out_s1_full_pred_2_fallThroughAddr);
        end
        f_s1_io_out_s1_full_pred_2_fallThroughAddr |= f_g_io_out_s1_full_pred_2_fallThroughAddr;
        f_s0_io_out_s1_full_pred_2_fallThroughAddr |= ~f_g_io_out_s1_full_pred_2_fallThroughAddr;
        checks++;
        if (f_g_io_out_s1_full_pred_2_fallThroughErr !== f_i_io_out_s1_full_pred_2_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_fallThroughErr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_fallThroughErr, f_i_io_out_s1_full_pred_2_fallThroughErr);
        end
        f_s1_io_out_s1_full_pred_2_fallThroughErr |= f_g_io_out_s1_full_pred_2_fallThroughErr;
        f_s0_io_out_s1_full_pred_2_fallThroughErr |= ~f_g_io_out_s1_full_pred_2_fallThroughErr;
        checks++;
        if (f_g_io_out_s1_full_pred_2_is_jal !== f_i_io_out_s1_full_pred_2_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_is_jal g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_is_jal, f_i_io_out_s1_full_pred_2_is_jal);
        end
        f_s1_io_out_s1_full_pred_2_is_jal |= f_g_io_out_s1_full_pred_2_is_jal;
        f_s0_io_out_s1_full_pred_2_is_jal |= ~f_g_io_out_s1_full_pred_2_is_jal;
        checks++;
        if (f_g_io_out_s1_full_pred_2_is_jalr !== f_i_io_out_s1_full_pred_2_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_is_jalr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_is_jalr, f_i_io_out_s1_full_pred_2_is_jalr);
        end
        f_s1_io_out_s1_full_pred_2_is_jalr |= f_g_io_out_s1_full_pred_2_is_jalr;
        f_s0_io_out_s1_full_pred_2_is_jalr |= ~f_g_io_out_s1_full_pred_2_is_jalr;
        checks++;
        if (f_g_io_out_s1_full_pred_2_is_call !== f_i_io_out_s1_full_pred_2_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_is_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_is_call, f_i_io_out_s1_full_pred_2_is_call);
        end
        f_s1_io_out_s1_full_pred_2_is_call |= f_g_io_out_s1_full_pred_2_is_call;
        f_s0_io_out_s1_full_pred_2_is_call |= ~f_g_io_out_s1_full_pred_2_is_call;
        checks++;
        if (f_g_io_out_s1_full_pred_2_is_ret !== f_i_io_out_s1_full_pred_2_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_is_ret g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_is_ret, f_i_io_out_s1_full_pred_2_is_ret);
        end
        f_s1_io_out_s1_full_pred_2_is_ret |= f_g_io_out_s1_full_pred_2_is_ret;
        f_s0_io_out_s1_full_pred_2_is_ret |= ~f_g_io_out_s1_full_pred_2_is_ret;
        checks++;
        if (f_g_io_out_s1_full_pred_2_last_may_be_rvi_call !== f_i_io_out_s1_full_pred_2_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_last_may_be_rvi_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_last_may_be_rvi_call, f_i_io_out_s1_full_pred_2_last_may_be_rvi_call);
        end
        f_s1_io_out_s1_full_pred_2_last_may_be_rvi_call |= f_g_io_out_s1_full_pred_2_last_may_be_rvi_call;
        f_s0_io_out_s1_full_pred_2_last_may_be_rvi_call |= ~f_g_io_out_s1_full_pred_2_last_may_be_rvi_call;
        checks++;
        if (f_g_io_out_s1_full_pred_2_is_br_sharing !== f_i_io_out_s1_full_pred_2_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_is_br_sharing g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_is_br_sharing, f_i_io_out_s1_full_pred_2_is_br_sharing);
        end
        f_s1_io_out_s1_full_pred_2_is_br_sharing |= f_g_io_out_s1_full_pred_2_is_br_sharing;
        f_s0_io_out_s1_full_pred_2_is_br_sharing |= ~f_g_io_out_s1_full_pred_2_is_br_sharing;
        checks++;
        if (f_g_io_out_s1_full_pred_2_hit !== f_i_io_out_s1_full_pred_2_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_2_hit g=%h i=%h", cyc, f_g_io_out_s1_full_pred_2_hit, f_i_io_out_s1_full_pred_2_hit);
        end
        f_s1_io_out_s1_full_pred_2_hit |= f_g_io_out_s1_full_pred_2_hit;
        f_s0_io_out_s1_full_pred_2_hit |= ~f_g_io_out_s1_full_pred_2_hit;
        checks++;
        if (f_g_io_out_s1_full_pred_3_br_taken_mask_0 !== f_i_io_out_s1_full_pred_3_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_br_taken_mask_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_br_taken_mask_0, f_i_io_out_s1_full_pred_3_br_taken_mask_0);
        end
        f_s1_io_out_s1_full_pred_3_br_taken_mask_0 |= f_g_io_out_s1_full_pred_3_br_taken_mask_0;
        f_s0_io_out_s1_full_pred_3_br_taken_mask_0 |= ~f_g_io_out_s1_full_pred_3_br_taken_mask_0;
        checks++;
        if (f_g_io_out_s1_full_pred_3_br_taken_mask_1 !== f_i_io_out_s1_full_pred_3_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_br_taken_mask_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_br_taken_mask_1, f_i_io_out_s1_full_pred_3_br_taken_mask_1);
        end
        f_s1_io_out_s1_full_pred_3_br_taken_mask_1 |= f_g_io_out_s1_full_pred_3_br_taken_mask_1;
        f_s0_io_out_s1_full_pred_3_br_taken_mask_1 |= ~f_g_io_out_s1_full_pred_3_br_taken_mask_1;
        checks++;
        if (f_g_io_out_s1_full_pred_3_slot_valids_0 !== f_i_io_out_s1_full_pred_3_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_slot_valids_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_slot_valids_0, f_i_io_out_s1_full_pred_3_slot_valids_0);
        end
        f_s1_io_out_s1_full_pred_3_slot_valids_0 |= f_g_io_out_s1_full_pred_3_slot_valids_0;
        f_s0_io_out_s1_full_pred_3_slot_valids_0 |= ~f_g_io_out_s1_full_pred_3_slot_valids_0;
        checks++;
        if (f_g_io_out_s1_full_pred_3_slot_valids_1 !== f_i_io_out_s1_full_pred_3_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_slot_valids_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_slot_valids_1, f_i_io_out_s1_full_pred_3_slot_valids_1);
        end
        f_s1_io_out_s1_full_pred_3_slot_valids_1 |= f_g_io_out_s1_full_pred_3_slot_valids_1;
        f_s0_io_out_s1_full_pred_3_slot_valids_1 |= ~f_g_io_out_s1_full_pred_3_slot_valids_1;
        checks++;
        if (f_g_io_out_s1_full_pred_3_targets_0 !== f_i_io_out_s1_full_pred_3_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_targets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_targets_0, f_i_io_out_s1_full_pred_3_targets_0);
        end
        f_s1_io_out_s1_full_pred_3_targets_0 |= f_g_io_out_s1_full_pred_3_targets_0;
        f_s0_io_out_s1_full_pred_3_targets_0 |= ~f_g_io_out_s1_full_pred_3_targets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_3_targets_1 !== f_i_io_out_s1_full_pred_3_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_targets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_targets_1, f_i_io_out_s1_full_pred_3_targets_1);
        end
        f_s1_io_out_s1_full_pred_3_targets_1 |= f_g_io_out_s1_full_pred_3_targets_1;
        f_s0_io_out_s1_full_pred_3_targets_1 |= ~f_g_io_out_s1_full_pred_3_targets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_3_jalr_target !== f_i_io_out_s1_full_pred_3_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_jalr_target g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_jalr_target, f_i_io_out_s1_full_pred_3_jalr_target);
        end
        f_s1_io_out_s1_full_pred_3_jalr_target |= f_g_io_out_s1_full_pred_3_jalr_target;
        f_s0_io_out_s1_full_pred_3_jalr_target |= ~f_g_io_out_s1_full_pred_3_jalr_target;
        checks++;
        if (f_g_io_out_s1_full_pred_3_offsets_0 !== f_i_io_out_s1_full_pred_3_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_offsets_0 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_offsets_0, f_i_io_out_s1_full_pred_3_offsets_0);
        end
        f_s1_io_out_s1_full_pred_3_offsets_0 |= f_g_io_out_s1_full_pred_3_offsets_0;
        f_s0_io_out_s1_full_pred_3_offsets_0 |= ~f_g_io_out_s1_full_pred_3_offsets_0;
        checks++;
        if (f_g_io_out_s1_full_pred_3_offsets_1 !== f_i_io_out_s1_full_pred_3_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_offsets_1 g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_offsets_1, f_i_io_out_s1_full_pred_3_offsets_1);
        end
        f_s1_io_out_s1_full_pred_3_offsets_1 |= f_g_io_out_s1_full_pred_3_offsets_1;
        f_s0_io_out_s1_full_pred_3_offsets_1 |= ~f_g_io_out_s1_full_pred_3_offsets_1;
        checks++;
        if (f_g_io_out_s1_full_pred_3_fallThroughAddr !== f_i_io_out_s1_full_pred_3_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_fallThroughAddr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_fallThroughAddr, f_i_io_out_s1_full_pred_3_fallThroughAddr);
        end
        f_s1_io_out_s1_full_pred_3_fallThroughAddr |= f_g_io_out_s1_full_pred_3_fallThroughAddr;
        f_s0_io_out_s1_full_pred_3_fallThroughAddr |= ~f_g_io_out_s1_full_pred_3_fallThroughAddr;
        checks++;
        if (f_g_io_out_s1_full_pred_3_fallThroughErr !== f_i_io_out_s1_full_pred_3_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_fallThroughErr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_fallThroughErr, f_i_io_out_s1_full_pred_3_fallThroughErr);
        end
        f_s1_io_out_s1_full_pred_3_fallThroughErr |= f_g_io_out_s1_full_pred_3_fallThroughErr;
        f_s0_io_out_s1_full_pred_3_fallThroughErr |= ~f_g_io_out_s1_full_pred_3_fallThroughErr;
        checks++;
        if (f_g_io_out_s1_full_pred_3_is_jal !== f_i_io_out_s1_full_pred_3_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_is_jal g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_is_jal, f_i_io_out_s1_full_pred_3_is_jal);
        end
        f_s1_io_out_s1_full_pred_3_is_jal |= f_g_io_out_s1_full_pred_3_is_jal;
        f_s0_io_out_s1_full_pred_3_is_jal |= ~f_g_io_out_s1_full_pred_3_is_jal;
        checks++;
        if (f_g_io_out_s1_full_pred_3_is_jalr !== f_i_io_out_s1_full_pred_3_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_is_jalr g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_is_jalr, f_i_io_out_s1_full_pred_3_is_jalr);
        end
        f_s1_io_out_s1_full_pred_3_is_jalr |= f_g_io_out_s1_full_pred_3_is_jalr;
        f_s0_io_out_s1_full_pred_3_is_jalr |= ~f_g_io_out_s1_full_pred_3_is_jalr;
        checks++;
        if (f_g_io_out_s1_full_pred_3_is_call !== f_i_io_out_s1_full_pred_3_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_is_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_is_call, f_i_io_out_s1_full_pred_3_is_call);
        end
        f_s1_io_out_s1_full_pred_3_is_call |= f_g_io_out_s1_full_pred_3_is_call;
        f_s0_io_out_s1_full_pred_3_is_call |= ~f_g_io_out_s1_full_pred_3_is_call;
        checks++;
        if (f_g_io_out_s1_full_pred_3_is_ret !== f_i_io_out_s1_full_pred_3_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_is_ret g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_is_ret, f_i_io_out_s1_full_pred_3_is_ret);
        end
        f_s1_io_out_s1_full_pred_3_is_ret |= f_g_io_out_s1_full_pred_3_is_ret;
        f_s0_io_out_s1_full_pred_3_is_ret |= ~f_g_io_out_s1_full_pred_3_is_ret;
        checks++;
        if (f_g_io_out_s1_full_pred_3_last_may_be_rvi_call !== f_i_io_out_s1_full_pred_3_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_last_may_be_rvi_call g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_last_may_be_rvi_call, f_i_io_out_s1_full_pred_3_last_may_be_rvi_call);
        end
        f_s1_io_out_s1_full_pred_3_last_may_be_rvi_call |= f_g_io_out_s1_full_pred_3_last_may_be_rvi_call;
        f_s0_io_out_s1_full_pred_3_last_may_be_rvi_call |= ~f_g_io_out_s1_full_pred_3_last_may_be_rvi_call;
        checks++;
        if (f_g_io_out_s1_full_pred_3_is_br_sharing !== f_i_io_out_s1_full_pred_3_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_is_br_sharing g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_is_br_sharing, f_i_io_out_s1_full_pred_3_is_br_sharing);
        end
        f_s1_io_out_s1_full_pred_3_is_br_sharing |= f_g_io_out_s1_full_pred_3_is_br_sharing;
        f_s0_io_out_s1_full_pred_3_is_br_sharing |= ~f_g_io_out_s1_full_pred_3_is_br_sharing;
        checks++;
        if (f_g_io_out_s1_full_pred_3_hit !== f_i_io_out_s1_full_pred_3_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_s1_full_pred_3_hit g=%h i=%h", cyc, f_g_io_out_s1_full_pred_3_hit, f_i_io_out_s1_full_pred_3_hit);
        end
        f_s1_io_out_s1_full_pred_3_hit |= f_g_io_out_s1_full_pred_3_hit;
        f_s0_io_out_s1_full_pred_3_hit |= ~f_g_io_out_s1_full_pred_3_hit;
        checks++;
        if (f_g_io_out_last_stage_meta !== f_i_io_out_last_stage_meta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_out_last_stage_meta g=%h i=%h", cyc, f_g_io_out_last_stage_meta, f_i_io_out_last_stage_meta);
        end
        f_s1_io_out_last_stage_meta |= f_g_io_out_last_stage_meta;
        f_s0_io_out_last_stage_meta |= ~f_g_io_out_last_stage_meta;
        checks++;
        if (f_g_io_fauftb_entry_out_isCall !== f_i_io_fauftb_entry_out_isCall) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_isCall g=%h i=%h", cyc, f_g_io_fauftb_entry_out_isCall, f_i_io_fauftb_entry_out_isCall);
        end
        f_s1_io_fauftb_entry_out_isCall |= f_g_io_fauftb_entry_out_isCall;
        f_s0_io_fauftb_entry_out_isCall |= ~f_g_io_fauftb_entry_out_isCall;
        checks++;
        if (f_g_io_fauftb_entry_out_isRet !== f_i_io_fauftb_entry_out_isRet) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_isRet g=%h i=%h", cyc, f_g_io_fauftb_entry_out_isRet, f_i_io_fauftb_entry_out_isRet);
        end
        f_s1_io_fauftb_entry_out_isRet |= f_g_io_fauftb_entry_out_isRet;
        f_s0_io_fauftb_entry_out_isRet |= ~f_g_io_fauftb_entry_out_isRet;
        checks++;
        if (f_g_io_fauftb_entry_out_isJalr !== f_i_io_fauftb_entry_out_isJalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_isJalr g=%h i=%h", cyc, f_g_io_fauftb_entry_out_isJalr, f_i_io_fauftb_entry_out_isJalr);
        end
        f_s1_io_fauftb_entry_out_isJalr |= f_g_io_fauftb_entry_out_isJalr;
        f_s0_io_fauftb_entry_out_isJalr |= ~f_g_io_fauftb_entry_out_isJalr;
        checks++;
        if (f_g_io_fauftb_entry_out_valid !== f_i_io_fauftb_entry_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_valid g=%h i=%h", cyc, f_g_io_fauftb_entry_out_valid, f_i_io_fauftb_entry_out_valid);
        end
        f_s1_io_fauftb_entry_out_valid |= f_g_io_fauftb_entry_out_valid;
        f_s0_io_fauftb_entry_out_valid |= ~f_g_io_fauftb_entry_out_valid;
        checks++;
        if (f_g_io_fauftb_entry_out_brSlots_0_offset !== f_i_io_fauftb_entry_out_brSlots_0_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_brSlots_0_offset g=%h i=%h", cyc, f_g_io_fauftb_entry_out_brSlots_0_offset, f_i_io_fauftb_entry_out_brSlots_0_offset);
        end
        f_s1_io_fauftb_entry_out_brSlots_0_offset |= f_g_io_fauftb_entry_out_brSlots_0_offset;
        f_s0_io_fauftb_entry_out_brSlots_0_offset |= ~f_g_io_fauftb_entry_out_brSlots_0_offset;
        checks++;
        if (f_g_io_fauftb_entry_out_brSlots_0_sharing !== f_i_io_fauftb_entry_out_brSlots_0_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_brSlots_0_sharing g=%h i=%h", cyc, f_g_io_fauftb_entry_out_brSlots_0_sharing, f_i_io_fauftb_entry_out_brSlots_0_sharing);
        end
        f_s1_io_fauftb_entry_out_brSlots_0_sharing |= f_g_io_fauftb_entry_out_brSlots_0_sharing;
        f_s0_io_fauftb_entry_out_brSlots_0_sharing |= ~f_g_io_fauftb_entry_out_brSlots_0_sharing;
        checks++;
        if (f_g_io_fauftb_entry_out_brSlots_0_valid !== f_i_io_fauftb_entry_out_brSlots_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_brSlots_0_valid g=%h i=%h", cyc, f_g_io_fauftb_entry_out_brSlots_0_valid, f_i_io_fauftb_entry_out_brSlots_0_valid);
        end
        f_s1_io_fauftb_entry_out_brSlots_0_valid |= f_g_io_fauftb_entry_out_brSlots_0_valid;
        f_s0_io_fauftb_entry_out_brSlots_0_valid |= ~f_g_io_fauftb_entry_out_brSlots_0_valid;
        checks++;
        if (f_g_io_fauftb_entry_out_brSlots_0_lower !== f_i_io_fauftb_entry_out_brSlots_0_lower) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_brSlots_0_lower g=%h i=%h", cyc, f_g_io_fauftb_entry_out_brSlots_0_lower, f_i_io_fauftb_entry_out_brSlots_0_lower);
        end
        f_s1_io_fauftb_entry_out_brSlots_0_lower |= f_g_io_fauftb_entry_out_brSlots_0_lower;
        f_s0_io_fauftb_entry_out_brSlots_0_lower |= ~f_g_io_fauftb_entry_out_brSlots_0_lower;
        checks++;
        if (f_g_io_fauftb_entry_out_brSlots_0_tarStat !== f_i_io_fauftb_entry_out_brSlots_0_tarStat) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_brSlots_0_tarStat g=%h i=%h", cyc, f_g_io_fauftb_entry_out_brSlots_0_tarStat, f_i_io_fauftb_entry_out_brSlots_0_tarStat);
        end
        f_s1_io_fauftb_entry_out_brSlots_0_tarStat |= f_g_io_fauftb_entry_out_brSlots_0_tarStat;
        f_s0_io_fauftb_entry_out_brSlots_0_tarStat |= ~f_g_io_fauftb_entry_out_brSlots_0_tarStat;
        checks++;
        if (f_g_io_fauftb_entry_out_tailSlot_offset !== f_i_io_fauftb_entry_out_tailSlot_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_tailSlot_offset g=%h i=%h", cyc, f_g_io_fauftb_entry_out_tailSlot_offset, f_i_io_fauftb_entry_out_tailSlot_offset);
        end
        f_s1_io_fauftb_entry_out_tailSlot_offset |= f_g_io_fauftb_entry_out_tailSlot_offset;
        f_s0_io_fauftb_entry_out_tailSlot_offset |= ~f_g_io_fauftb_entry_out_tailSlot_offset;
        checks++;
        if (f_g_io_fauftb_entry_out_tailSlot_sharing !== f_i_io_fauftb_entry_out_tailSlot_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_tailSlot_sharing g=%h i=%h", cyc, f_g_io_fauftb_entry_out_tailSlot_sharing, f_i_io_fauftb_entry_out_tailSlot_sharing);
        end
        f_s1_io_fauftb_entry_out_tailSlot_sharing |= f_g_io_fauftb_entry_out_tailSlot_sharing;
        f_s0_io_fauftb_entry_out_tailSlot_sharing |= ~f_g_io_fauftb_entry_out_tailSlot_sharing;
        checks++;
        if (f_g_io_fauftb_entry_out_tailSlot_valid !== f_i_io_fauftb_entry_out_tailSlot_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_tailSlot_valid g=%h i=%h", cyc, f_g_io_fauftb_entry_out_tailSlot_valid, f_i_io_fauftb_entry_out_tailSlot_valid);
        end
        f_s1_io_fauftb_entry_out_tailSlot_valid |= f_g_io_fauftb_entry_out_tailSlot_valid;
        f_s0_io_fauftb_entry_out_tailSlot_valid |= ~f_g_io_fauftb_entry_out_tailSlot_valid;
        checks++;
        if (f_g_io_fauftb_entry_out_tailSlot_lower !== f_i_io_fauftb_entry_out_tailSlot_lower) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_tailSlot_lower g=%h i=%h", cyc, f_g_io_fauftb_entry_out_tailSlot_lower, f_i_io_fauftb_entry_out_tailSlot_lower);
        end
        f_s1_io_fauftb_entry_out_tailSlot_lower |= f_g_io_fauftb_entry_out_tailSlot_lower;
        f_s0_io_fauftb_entry_out_tailSlot_lower |= ~f_g_io_fauftb_entry_out_tailSlot_lower;
        checks++;
        if (f_g_io_fauftb_entry_out_tailSlot_tarStat !== f_i_io_fauftb_entry_out_tailSlot_tarStat) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_tailSlot_tarStat g=%h i=%h", cyc, f_g_io_fauftb_entry_out_tailSlot_tarStat, f_i_io_fauftb_entry_out_tailSlot_tarStat);
        end
        f_s1_io_fauftb_entry_out_tailSlot_tarStat |= f_g_io_fauftb_entry_out_tailSlot_tarStat;
        f_s0_io_fauftb_entry_out_tailSlot_tarStat |= ~f_g_io_fauftb_entry_out_tailSlot_tarStat;
        checks++;
        if (f_g_io_fauftb_entry_out_pftAddr !== f_i_io_fauftb_entry_out_pftAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_pftAddr g=%h i=%h", cyc, f_g_io_fauftb_entry_out_pftAddr, f_i_io_fauftb_entry_out_pftAddr);
        end
        f_s1_io_fauftb_entry_out_pftAddr |= f_g_io_fauftb_entry_out_pftAddr;
        f_s0_io_fauftb_entry_out_pftAddr |= ~f_g_io_fauftb_entry_out_pftAddr;
        checks++;
        if (f_g_io_fauftb_entry_out_carry !== f_i_io_fauftb_entry_out_carry) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_carry g=%h i=%h", cyc, f_g_io_fauftb_entry_out_carry, f_i_io_fauftb_entry_out_carry);
        end
        f_s1_io_fauftb_entry_out_carry |= f_g_io_fauftb_entry_out_carry;
        f_s0_io_fauftb_entry_out_carry |= ~f_g_io_fauftb_entry_out_carry;
        checks++;
        if (f_g_io_fauftb_entry_out_last_may_be_rvi_call !== f_i_io_fauftb_entry_out_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_last_may_be_rvi_call g=%h i=%h", cyc, f_g_io_fauftb_entry_out_last_may_be_rvi_call, f_i_io_fauftb_entry_out_last_may_be_rvi_call);
        end
        f_s1_io_fauftb_entry_out_last_may_be_rvi_call |= f_g_io_fauftb_entry_out_last_may_be_rvi_call;
        f_s0_io_fauftb_entry_out_last_may_be_rvi_call |= ~f_g_io_fauftb_entry_out_last_may_be_rvi_call;
        checks++;
        if (f_g_io_fauftb_entry_out_strong_bias_0 !== f_i_io_fauftb_entry_out_strong_bias_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_strong_bias_0 g=%h i=%h", cyc, f_g_io_fauftb_entry_out_strong_bias_0, f_i_io_fauftb_entry_out_strong_bias_0);
        end
        f_s1_io_fauftb_entry_out_strong_bias_0 |= f_g_io_fauftb_entry_out_strong_bias_0;
        f_s0_io_fauftb_entry_out_strong_bias_0 |= ~f_g_io_fauftb_entry_out_strong_bias_0;
        checks++;
        if (f_g_io_fauftb_entry_out_strong_bias_1 !== f_i_io_fauftb_entry_out_strong_bias_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_out_strong_bias_1 g=%h i=%h", cyc, f_g_io_fauftb_entry_out_strong_bias_1, f_i_io_fauftb_entry_out_strong_bias_1);
        end
        f_s1_io_fauftb_entry_out_strong_bias_1 |= f_g_io_fauftb_entry_out_strong_bias_1;
        f_s0_io_fauftb_entry_out_strong_bias_1 |= ~f_g_io_fauftb_entry_out_strong_bias_1;
        checks++;
        if (f_g_io_fauftb_entry_hit_out !== f_i_io_fauftb_entry_hit_out) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_fauftb_entry_hit_out g=%h i=%h", cyc, f_g_io_fauftb_entry_hit_out, f_i_io_fauftb_entry_hit_out);
        end
        f_s1_io_fauftb_entry_hit_out |= f_g_io_fauftb_entry_hit_out;
        f_s0_io_fauftb_entry_hit_out |= ~f_g_io_fauftb_entry_hit_out;
        checks++;
        if (f_g_io_perf_0_value !== f_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_perf_0_value g=%h i=%h", cyc, f_g_io_perf_0_value, f_i_io_perf_0_value);
        end
        f_s1_io_perf_0_value |= f_g_io_perf_0_value;
        f_s0_io_perf_0_value |= ~f_g_io_perf_0_value;
        checks++;
        if (f_g_io_perf_1_value !== f_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FauFTB.io_perf_1_value g=%h i=%h", cyc, f_g_io_perf_1_value, f_i_io_perf_1_value);
        end
        f_s1_io_perf_1_value |= f_g_io_perf_1_value;
        f_s0_io_perf_1_value |= ~f_g_io_perf_1_value;
        if (|f_u_gold.s1_hit_oh && f_io_s1_fire_0) f_cov_pred_hit++;
        if (f_u_gold.u_s1_valid && f_u_gold.u_s1_hit) f_cov_update_hit_writeback++;
        if (f_u_gold.u_s1_valid && !f_u_gold.u_s1_hit && (&{f_u_gold.ways_0.valid, f_u_gold.ways_1.valid, f_u_gold.ways_2.valid, f_u_gold.ways_3.valid, f_u_gold.ways_4.valid, f_u_gold.ways_5.valid, f_u_gold.ways_6.valid, f_u_gold.ways_7.valid, f_u_gold.ways_8.valid, f_u_gold.ways_9.valid, f_u_gold.ways_10.valid, f_u_gold.ways_11.valid, f_u_gold.ways_12.valid, f_u_gold.ways_13.valid, f_u_gold.ways_14.valid, f_u_gold.ways_15.valid, f_u_gold.ways_16.valid, f_u_gold.ways_17.valid, f_u_gold.ways_18.valid, f_u_gold.ways_19.valid, f_u_gold.ways_20.valid, f_u_gold.ways_21.valid, f_u_gold.ways_22.valid, f_u_gold.ways_23.valid, f_u_gold.ways_24.valid, f_u_gold.ways_25.valid, f_u_gold.ways_26.valid, f_u_gold.ways_27.valid, f_u_gold.ways_28.valid, f_u_gold.ways_29.valid, f_u_gold.ways_30.valid, f_u_gold.ways_31.valid})) f_cov_replace_when_full++;
        if (|{f_u_gold.u_s1_ways_write_valid_0 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_0_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_1 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_1_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_2 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_2_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_3 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_3_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_4 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_4_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_5 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_5_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_6 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_6_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_7 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_7_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_8 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_8_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_9 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_9_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_10 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_10_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_11 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_11_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_12 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_12_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_13 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_13_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_14 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_14_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_15 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_15_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_16 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_16_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_17 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_17_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_18 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_18_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_19 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_19_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_20 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_20_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_21 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_21_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_22 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_22_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_23 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_23_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_24 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_24_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_25 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_25_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_26 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_26_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_27 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_27_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_28 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_28_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_29 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_29_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_30 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_30_0) && f_u_gold.u_s1_br_takens_0, f_u_gold.u_s1_ways_write_valid_31 && f_u_gold.u_s1_br_update_valids_0 && (&f_u_gold.ctrs_31_0) && f_u_gold.u_s1_br_takens_0}) f_cov_ctr_sat_hold++;
        if (f_g_io_out_s1_full_pred_0_fallThroughErr && f_g_io_out_s1_full_pred_0_hit) f_cov_fall_through_err++;
        if (f_u_gold.replacer_touch_ways_0_valid_REG && f_u_gold.u_s1_valid) f_cov_double_touch++;
      end
      if (f_io_s1_fire_0) f_armed[0] = 1'b1;
      if (f_io_s2_fire_0 && f_armed[0]) f_armed[1] = 1'b1;
      if (f_armed_at < 0 && (&f_armed)) f_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(f_s0_io_out_s1_pc_0[0] && f_s1_io_out_s1_pc_0[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[1] && f_s1_io_out_s1_pc_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[2] && f_s1_io_out_s1_pc_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[3] && f_s1_io_out_s1_pc_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[4] && f_s1_io_out_s1_pc_0[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[5] && f_s1_io_out_s1_pc_0[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[6] && f_s1_io_out_s1_pc_0[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[7] && f_s1_io_out_s1_pc_0[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[8] && f_s1_io_out_s1_pc_0[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[9] && f_s1_io_out_s1_pc_0[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[10] && f_s1_io_out_s1_pc_0[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[11] && f_s1_io_out_s1_pc_0[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[12] && f_s1_io_out_s1_pc_0[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[13] && f_s1_io_out_s1_pc_0[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[14] && f_s1_io_out_s1_pc_0[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[15] && f_s1_io_out_s1_pc_0[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[16] && f_s1_io_out_s1_pc_0[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[17] && f_s1_io_out_s1_pc_0[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[18] && f_s1_io_out_s1_pc_0[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[19] && f_s1_io_out_s1_pc_0[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[20] && f_s1_io_out_s1_pc_0[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[21] && f_s1_io_out_s1_pc_0[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[22] && f_s1_io_out_s1_pc_0[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[23] && f_s1_io_out_s1_pc_0[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[24] && f_s1_io_out_s1_pc_0[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[25] && f_s1_io_out_s1_pc_0[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[26] && f_s1_io_out_s1_pc_0[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[27] && f_s1_io_out_s1_pc_0[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[28] && f_s1_io_out_s1_pc_0[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[29] && f_s1_io_out_s1_pc_0[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[30] && f_s1_io_out_s1_pc_0[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[31] && f_s1_io_out_s1_pc_0[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[32] && f_s1_io_out_s1_pc_0[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[33] && f_s1_io_out_s1_pc_0[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[34] && f_s1_io_out_s1_pc_0[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[35] && f_s1_io_out_s1_pc_0[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[36] && f_s1_io_out_s1_pc_0[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[37] && f_s1_io_out_s1_pc_0[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[38] && f_s1_io_out_s1_pc_0[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[39] && f_s1_io_out_s1_pc_0[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[40] && f_s1_io_out_s1_pc_0[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[41] && f_s1_io_out_s1_pc_0[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[42] && f_s1_io_out_s1_pc_0[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[43] && f_s1_io_out_s1_pc_0[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[44] && f_s1_io_out_s1_pc_0[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[45] && f_s1_io_out_s1_pc_0[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[46] && f_s1_io_out_s1_pc_0[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[47] && f_s1_io_out_s1_pc_0[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[48] && f_s1_io_out_s1_pc_0[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_0[49] && f_s1_io_out_s1_pc_0[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_0[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[0] && f_s1_io_out_s1_pc_1[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[1] && f_s1_io_out_s1_pc_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[2] && f_s1_io_out_s1_pc_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[3] && f_s1_io_out_s1_pc_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[4] && f_s1_io_out_s1_pc_1[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[5] && f_s1_io_out_s1_pc_1[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[6] && f_s1_io_out_s1_pc_1[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[7] && f_s1_io_out_s1_pc_1[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[8] && f_s1_io_out_s1_pc_1[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[9] && f_s1_io_out_s1_pc_1[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[10] && f_s1_io_out_s1_pc_1[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[11] && f_s1_io_out_s1_pc_1[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[12] && f_s1_io_out_s1_pc_1[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[13] && f_s1_io_out_s1_pc_1[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[14] && f_s1_io_out_s1_pc_1[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[15] && f_s1_io_out_s1_pc_1[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[16] && f_s1_io_out_s1_pc_1[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[17] && f_s1_io_out_s1_pc_1[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[18] && f_s1_io_out_s1_pc_1[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[19] && f_s1_io_out_s1_pc_1[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[20] && f_s1_io_out_s1_pc_1[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[21] && f_s1_io_out_s1_pc_1[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[22] && f_s1_io_out_s1_pc_1[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[23] && f_s1_io_out_s1_pc_1[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[24] && f_s1_io_out_s1_pc_1[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[25] && f_s1_io_out_s1_pc_1[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[26] && f_s1_io_out_s1_pc_1[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[27] && f_s1_io_out_s1_pc_1[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[28] && f_s1_io_out_s1_pc_1[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[29] && f_s1_io_out_s1_pc_1[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[30] && f_s1_io_out_s1_pc_1[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[31] && f_s1_io_out_s1_pc_1[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[32] && f_s1_io_out_s1_pc_1[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[33] && f_s1_io_out_s1_pc_1[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[34] && f_s1_io_out_s1_pc_1[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[35] && f_s1_io_out_s1_pc_1[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[36] && f_s1_io_out_s1_pc_1[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[37] && f_s1_io_out_s1_pc_1[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[38] && f_s1_io_out_s1_pc_1[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[39] && f_s1_io_out_s1_pc_1[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[40] && f_s1_io_out_s1_pc_1[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[41] && f_s1_io_out_s1_pc_1[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[42] && f_s1_io_out_s1_pc_1[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[43] && f_s1_io_out_s1_pc_1[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[44] && f_s1_io_out_s1_pc_1[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[45] && f_s1_io_out_s1_pc_1[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[46] && f_s1_io_out_s1_pc_1[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[47] && f_s1_io_out_s1_pc_1[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[48] && f_s1_io_out_s1_pc_1[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_1[49] && f_s1_io_out_s1_pc_1[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_1[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[0] && f_s1_io_out_s1_pc_2[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[1] && f_s1_io_out_s1_pc_2[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[2] && f_s1_io_out_s1_pc_2[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[3] && f_s1_io_out_s1_pc_2[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[4] && f_s1_io_out_s1_pc_2[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[5] && f_s1_io_out_s1_pc_2[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[6] && f_s1_io_out_s1_pc_2[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[7] && f_s1_io_out_s1_pc_2[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[8] && f_s1_io_out_s1_pc_2[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[9] && f_s1_io_out_s1_pc_2[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[10] && f_s1_io_out_s1_pc_2[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[11] && f_s1_io_out_s1_pc_2[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[12] && f_s1_io_out_s1_pc_2[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[13] && f_s1_io_out_s1_pc_2[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[14] && f_s1_io_out_s1_pc_2[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[15] && f_s1_io_out_s1_pc_2[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[16] && f_s1_io_out_s1_pc_2[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[17] && f_s1_io_out_s1_pc_2[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[18] && f_s1_io_out_s1_pc_2[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[19] && f_s1_io_out_s1_pc_2[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[20] && f_s1_io_out_s1_pc_2[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[21] && f_s1_io_out_s1_pc_2[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[22] && f_s1_io_out_s1_pc_2[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[23] && f_s1_io_out_s1_pc_2[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[24] && f_s1_io_out_s1_pc_2[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[25] && f_s1_io_out_s1_pc_2[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[26] && f_s1_io_out_s1_pc_2[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[27] && f_s1_io_out_s1_pc_2[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[28] && f_s1_io_out_s1_pc_2[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[29] && f_s1_io_out_s1_pc_2[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[30] && f_s1_io_out_s1_pc_2[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[31] && f_s1_io_out_s1_pc_2[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[32] && f_s1_io_out_s1_pc_2[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[33] && f_s1_io_out_s1_pc_2[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[34] && f_s1_io_out_s1_pc_2[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[35] && f_s1_io_out_s1_pc_2[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[36] && f_s1_io_out_s1_pc_2[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[37] && f_s1_io_out_s1_pc_2[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[38] && f_s1_io_out_s1_pc_2[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[39] && f_s1_io_out_s1_pc_2[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[40] && f_s1_io_out_s1_pc_2[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[41] && f_s1_io_out_s1_pc_2[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[42] && f_s1_io_out_s1_pc_2[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[43] && f_s1_io_out_s1_pc_2[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[44] && f_s1_io_out_s1_pc_2[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[45] && f_s1_io_out_s1_pc_2[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[46] && f_s1_io_out_s1_pc_2[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[47] && f_s1_io_out_s1_pc_2[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[48] && f_s1_io_out_s1_pc_2[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_2[49] && f_s1_io_out_s1_pc_2[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_2[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[0] && f_s1_io_out_s1_pc_3[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[1] && f_s1_io_out_s1_pc_3[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[2] && f_s1_io_out_s1_pc_3[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[3] && f_s1_io_out_s1_pc_3[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[4] && f_s1_io_out_s1_pc_3[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[5] && f_s1_io_out_s1_pc_3[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[6] && f_s1_io_out_s1_pc_3[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[7] && f_s1_io_out_s1_pc_3[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[8] && f_s1_io_out_s1_pc_3[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[9] && f_s1_io_out_s1_pc_3[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[10] && f_s1_io_out_s1_pc_3[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[11] && f_s1_io_out_s1_pc_3[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[12] && f_s1_io_out_s1_pc_3[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[13] && f_s1_io_out_s1_pc_3[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[14] && f_s1_io_out_s1_pc_3[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[15] && f_s1_io_out_s1_pc_3[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[16] && f_s1_io_out_s1_pc_3[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[17] && f_s1_io_out_s1_pc_3[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[18] && f_s1_io_out_s1_pc_3[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[19] && f_s1_io_out_s1_pc_3[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[20] && f_s1_io_out_s1_pc_3[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[21] && f_s1_io_out_s1_pc_3[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[22] && f_s1_io_out_s1_pc_3[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[23] && f_s1_io_out_s1_pc_3[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[24] && f_s1_io_out_s1_pc_3[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[25] && f_s1_io_out_s1_pc_3[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[26] && f_s1_io_out_s1_pc_3[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[27] && f_s1_io_out_s1_pc_3[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[28] && f_s1_io_out_s1_pc_3[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[29] && f_s1_io_out_s1_pc_3[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[30] && f_s1_io_out_s1_pc_3[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[31] && f_s1_io_out_s1_pc_3[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[32] && f_s1_io_out_s1_pc_3[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[33] && f_s1_io_out_s1_pc_3[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[34] && f_s1_io_out_s1_pc_3[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[35] && f_s1_io_out_s1_pc_3[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[36] && f_s1_io_out_s1_pc_3[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[37] && f_s1_io_out_s1_pc_3[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[38] && f_s1_io_out_s1_pc_3[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[39] && f_s1_io_out_s1_pc_3[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[40] && f_s1_io_out_s1_pc_3[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[41] && f_s1_io_out_s1_pc_3[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[42] && f_s1_io_out_s1_pc_3[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[43] && f_s1_io_out_s1_pc_3[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[44] && f_s1_io_out_s1_pc_3[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[45] && f_s1_io_out_s1_pc_3[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[46] && f_s1_io_out_s1_pc_3[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[47] && f_s1_io_out_s1_pc_3[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[48] && f_s1_io_out_s1_pc_3[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_pc_3[49] && f_s1_io_out_s1_pc_3[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_pc_3[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_br_taken_mask_0 && f_s1_io_out_s1_full_pred_0_br_taken_mask_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_br_taken_mask_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_br_taken_mask_1 && f_s1_io_out_s1_full_pred_0_br_taken_mask_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_br_taken_mask_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_slot_valids_0 && f_s1_io_out_s1_full_pred_0_slot_valids_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_slot_valids_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_slot_valids_1 && f_s1_io_out_s1_full_pred_0_slot_valids_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_slot_valids_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[1] && f_s1_io_out_s1_full_pred_0_targets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[2] && f_s1_io_out_s1_full_pred_0_targets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[3] && f_s1_io_out_s1_full_pred_0_targets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[4] && f_s1_io_out_s1_full_pred_0_targets_0[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[5] && f_s1_io_out_s1_full_pred_0_targets_0[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[6] && f_s1_io_out_s1_full_pred_0_targets_0[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[7] && f_s1_io_out_s1_full_pred_0_targets_0[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[8] && f_s1_io_out_s1_full_pred_0_targets_0[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[9] && f_s1_io_out_s1_full_pred_0_targets_0[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[10] && f_s1_io_out_s1_full_pred_0_targets_0[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[11] && f_s1_io_out_s1_full_pred_0_targets_0[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[12] && f_s1_io_out_s1_full_pred_0_targets_0[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[13] && f_s1_io_out_s1_full_pred_0_targets_0[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[14] && f_s1_io_out_s1_full_pred_0_targets_0[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[15] && f_s1_io_out_s1_full_pred_0_targets_0[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[16] && f_s1_io_out_s1_full_pred_0_targets_0[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[17] && f_s1_io_out_s1_full_pred_0_targets_0[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[18] && f_s1_io_out_s1_full_pred_0_targets_0[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[19] && f_s1_io_out_s1_full_pred_0_targets_0[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[20] && f_s1_io_out_s1_full_pred_0_targets_0[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[21] && f_s1_io_out_s1_full_pred_0_targets_0[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[22] && f_s1_io_out_s1_full_pred_0_targets_0[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[23] && f_s1_io_out_s1_full_pred_0_targets_0[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[24] && f_s1_io_out_s1_full_pred_0_targets_0[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[25] && f_s1_io_out_s1_full_pred_0_targets_0[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[26] && f_s1_io_out_s1_full_pred_0_targets_0[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[27] && f_s1_io_out_s1_full_pred_0_targets_0[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[28] && f_s1_io_out_s1_full_pred_0_targets_0[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[29] && f_s1_io_out_s1_full_pred_0_targets_0[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[30] && f_s1_io_out_s1_full_pred_0_targets_0[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[31] && f_s1_io_out_s1_full_pred_0_targets_0[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[32] && f_s1_io_out_s1_full_pred_0_targets_0[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[33] && f_s1_io_out_s1_full_pred_0_targets_0[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[34] && f_s1_io_out_s1_full_pred_0_targets_0[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[35] && f_s1_io_out_s1_full_pred_0_targets_0[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[36] && f_s1_io_out_s1_full_pred_0_targets_0[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[37] && f_s1_io_out_s1_full_pred_0_targets_0[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[38] && f_s1_io_out_s1_full_pred_0_targets_0[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[39] && f_s1_io_out_s1_full_pred_0_targets_0[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[40] && f_s1_io_out_s1_full_pred_0_targets_0[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[41] && f_s1_io_out_s1_full_pred_0_targets_0[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[42] && f_s1_io_out_s1_full_pred_0_targets_0[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[43] && f_s1_io_out_s1_full_pred_0_targets_0[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[44] && f_s1_io_out_s1_full_pred_0_targets_0[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[45] && f_s1_io_out_s1_full_pred_0_targets_0[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[46] && f_s1_io_out_s1_full_pred_0_targets_0[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[47] && f_s1_io_out_s1_full_pred_0_targets_0[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[48] && f_s1_io_out_s1_full_pred_0_targets_0[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_0[49] && f_s1_io_out_s1_full_pred_0_targets_0[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_0[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[1] && f_s1_io_out_s1_full_pred_0_targets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[2] && f_s1_io_out_s1_full_pred_0_targets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[3] && f_s1_io_out_s1_full_pred_0_targets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[4] && f_s1_io_out_s1_full_pred_0_targets_1[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[5] && f_s1_io_out_s1_full_pred_0_targets_1[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[6] && f_s1_io_out_s1_full_pred_0_targets_1[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[7] && f_s1_io_out_s1_full_pred_0_targets_1[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[8] && f_s1_io_out_s1_full_pred_0_targets_1[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[9] && f_s1_io_out_s1_full_pred_0_targets_1[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[10] && f_s1_io_out_s1_full_pred_0_targets_1[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[11] && f_s1_io_out_s1_full_pred_0_targets_1[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[12] && f_s1_io_out_s1_full_pred_0_targets_1[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[13] && f_s1_io_out_s1_full_pred_0_targets_1[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[14] && f_s1_io_out_s1_full_pred_0_targets_1[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[15] && f_s1_io_out_s1_full_pred_0_targets_1[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[16] && f_s1_io_out_s1_full_pred_0_targets_1[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[17] && f_s1_io_out_s1_full_pred_0_targets_1[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[18] && f_s1_io_out_s1_full_pred_0_targets_1[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[19] && f_s1_io_out_s1_full_pred_0_targets_1[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[20] && f_s1_io_out_s1_full_pred_0_targets_1[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[21] && f_s1_io_out_s1_full_pred_0_targets_1[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[22] && f_s1_io_out_s1_full_pred_0_targets_1[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[23] && f_s1_io_out_s1_full_pred_0_targets_1[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[24] && f_s1_io_out_s1_full_pred_0_targets_1[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[25] && f_s1_io_out_s1_full_pred_0_targets_1[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[26] && f_s1_io_out_s1_full_pred_0_targets_1[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[27] && f_s1_io_out_s1_full_pred_0_targets_1[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[28] && f_s1_io_out_s1_full_pred_0_targets_1[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[29] && f_s1_io_out_s1_full_pred_0_targets_1[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[30] && f_s1_io_out_s1_full_pred_0_targets_1[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[31] && f_s1_io_out_s1_full_pred_0_targets_1[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[32] && f_s1_io_out_s1_full_pred_0_targets_1[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[33] && f_s1_io_out_s1_full_pred_0_targets_1[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[34] && f_s1_io_out_s1_full_pred_0_targets_1[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[35] && f_s1_io_out_s1_full_pred_0_targets_1[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[36] && f_s1_io_out_s1_full_pred_0_targets_1[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[37] && f_s1_io_out_s1_full_pred_0_targets_1[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[38] && f_s1_io_out_s1_full_pred_0_targets_1[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[39] && f_s1_io_out_s1_full_pred_0_targets_1[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[40] && f_s1_io_out_s1_full_pred_0_targets_1[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[41] && f_s1_io_out_s1_full_pred_0_targets_1[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[42] && f_s1_io_out_s1_full_pred_0_targets_1[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[43] && f_s1_io_out_s1_full_pred_0_targets_1[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[44] && f_s1_io_out_s1_full_pred_0_targets_1[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[45] && f_s1_io_out_s1_full_pred_0_targets_1[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[46] && f_s1_io_out_s1_full_pred_0_targets_1[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[47] && f_s1_io_out_s1_full_pred_0_targets_1[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[48] && f_s1_io_out_s1_full_pred_0_targets_1[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_targets_1[49] && f_s1_io_out_s1_full_pred_0_targets_1[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_targets_1[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[1] && f_s1_io_out_s1_full_pred_0_jalr_target[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[2] && f_s1_io_out_s1_full_pred_0_jalr_target[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[3] && f_s1_io_out_s1_full_pred_0_jalr_target[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[4] && f_s1_io_out_s1_full_pred_0_jalr_target[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[5] && f_s1_io_out_s1_full_pred_0_jalr_target[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[6] && f_s1_io_out_s1_full_pred_0_jalr_target[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[7] && f_s1_io_out_s1_full_pred_0_jalr_target[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[8] && f_s1_io_out_s1_full_pred_0_jalr_target[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[9] && f_s1_io_out_s1_full_pred_0_jalr_target[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[10] && f_s1_io_out_s1_full_pred_0_jalr_target[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[11] && f_s1_io_out_s1_full_pred_0_jalr_target[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[12] && f_s1_io_out_s1_full_pred_0_jalr_target[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[13] && f_s1_io_out_s1_full_pred_0_jalr_target[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[14] && f_s1_io_out_s1_full_pred_0_jalr_target[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[15] && f_s1_io_out_s1_full_pred_0_jalr_target[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[16] && f_s1_io_out_s1_full_pred_0_jalr_target[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[17] && f_s1_io_out_s1_full_pred_0_jalr_target[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[18] && f_s1_io_out_s1_full_pred_0_jalr_target[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[19] && f_s1_io_out_s1_full_pred_0_jalr_target[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[20] && f_s1_io_out_s1_full_pred_0_jalr_target[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[21] && f_s1_io_out_s1_full_pred_0_jalr_target[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[22] && f_s1_io_out_s1_full_pred_0_jalr_target[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[23] && f_s1_io_out_s1_full_pred_0_jalr_target[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[24] && f_s1_io_out_s1_full_pred_0_jalr_target[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[25] && f_s1_io_out_s1_full_pred_0_jalr_target[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[26] && f_s1_io_out_s1_full_pred_0_jalr_target[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[27] && f_s1_io_out_s1_full_pred_0_jalr_target[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[28] && f_s1_io_out_s1_full_pred_0_jalr_target[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[29] && f_s1_io_out_s1_full_pred_0_jalr_target[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[30] && f_s1_io_out_s1_full_pred_0_jalr_target[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[31] && f_s1_io_out_s1_full_pred_0_jalr_target[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[32] && f_s1_io_out_s1_full_pred_0_jalr_target[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[33] && f_s1_io_out_s1_full_pred_0_jalr_target[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[34] && f_s1_io_out_s1_full_pred_0_jalr_target[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[35] && f_s1_io_out_s1_full_pred_0_jalr_target[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[36] && f_s1_io_out_s1_full_pred_0_jalr_target[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[37] && f_s1_io_out_s1_full_pred_0_jalr_target[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[38] && f_s1_io_out_s1_full_pred_0_jalr_target[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[39] && f_s1_io_out_s1_full_pred_0_jalr_target[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[40] && f_s1_io_out_s1_full_pred_0_jalr_target[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[41] && f_s1_io_out_s1_full_pred_0_jalr_target[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[42] && f_s1_io_out_s1_full_pred_0_jalr_target[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[43] && f_s1_io_out_s1_full_pred_0_jalr_target[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[44] && f_s1_io_out_s1_full_pred_0_jalr_target[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[45] && f_s1_io_out_s1_full_pred_0_jalr_target[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[46] && f_s1_io_out_s1_full_pred_0_jalr_target[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[47] && f_s1_io_out_s1_full_pred_0_jalr_target[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[48] && f_s1_io_out_s1_full_pred_0_jalr_target[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_jalr_target[49] && f_s1_io_out_s1_full_pred_0_jalr_target[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_jalr_target[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_0[0] && f_s1_io_out_s1_full_pred_0_offsets_0[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_0[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_0[1] && f_s1_io_out_s1_full_pred_0_offsets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_0[2] && f_s1_io_out_s1_full_pred_0_offsets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_0[3] && f_s1_io_out_s1_full_pred_0_offsets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_1[0] && f_s1_io_out_s1_full_pred_0_offsets_1[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_1[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_1[1] && f_s1_io_out_s1_full_pred_0_offsets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_1[2] && f_s1_io_out_s1_full_pred_0_offsets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_offsets_1[3] && f_s1_io_out_s1_full_pred_0_offsets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_offsets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[0] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[1] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[2] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[3] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[4] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[5] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[6] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[7] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[8] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[9] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[10] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[11] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[12] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[13] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[14] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[15] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[16] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[17] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[18] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[19] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[20] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[21] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[22] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[23] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[24] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[25] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[26] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[27] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[28] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[29] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[30] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[31] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[32] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[33] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[34] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[35] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[36] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[37] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[38] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[39] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[40] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[41] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[42] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[43] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[44] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[45] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[46] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[47] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[48] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughAddr[49] && f_s1_io_out_s1_full_pred_0_fallThroughAddr[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_fallThroughErr && f_s1_io_out_s1_full_pred_0_fallThroughErr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_fallThroughErr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_is_jal && f_s1_io_out_s1_full_pred_0_is_jal)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_is_jal 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_is_jalr && f_s1_io_out_s1_full_pred_0_is_jalr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_is_jalr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_is_call && f_s1_io_out_s1_full_pred_0_is_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_is_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_is_ret && f_s1_io_out_s1_full_pred_0_is_ret)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_is_ret 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_last_may_be_rvi_call && f_s1_io_out_s1_full_pred_0_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_is_br_sharing && f_s1_io_out_s1_full_pred_0_is_br_sharing)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_is_br_sharing 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_0_hit && f_s1_io_out_s1_full_pred_0_hit)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_0_hit 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_br_taken_mask_0 && f_s1_io_out_s1_full_pred_1_br_taken_mask_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_br_taken_mask_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_br_taken_mask_1 && f_s1_io_out_s1_full_pred_1_br_taken_mask_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_br_taken_mask_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_slot_valids_0 && f_s1_io_out_s1_full_pred_1_slot_valids_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_slot_valids_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_slot_valids_1 && f_s1_io_out_s1_full_pred_1_slot_valids_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_slot_valids_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[1] && f_s1_io_out_s1_full_pred_1_targets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[2] && f_s1_io_out_s1_full_pred_1_targets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[3] && f_s1_io_out_s1_full_pred_1_targets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[4] && f_s1_io_out_s1_full_pred_1_targets_0[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[5] && f_s1_io_out_s1_full_pred_1_targets_0[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[6] && f_s1_io_out_s1_full_pred_1_targets_0[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[7] && f_s1_io_out_s1_full_pred_1_targets_0[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[8] && f_s1_io_out_s1_full_pred_1_targets_0[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[9] && f_s1_io_out_s1_full_pred_1_targets_0[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[10] && f_s1_io_out_s1_full_pred_1_targets_0[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[11] && f_s1_io_out_s1_full_pred_1_targets_0[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[12] && f_s1_io_out_s1_full_pred_1_targets_0[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[13] && f_s1_io_out_s1_full_pred_1_targets_0[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[14] && f_s1_io_out_s1_full_pred_1_targets_0[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[15] && f_s1_io_out_s1_full_pred_1_targets_0[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[16] && f_s1_io_out_s1_full_pred_1_targets_0[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[17] && f_s1_io_out_s1_full_pred_1_targets_0[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[18] && f_s1_io_out_s1_full_pred_1_targets_0[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[19] && f_s1_io_out_s1_full_pred_1_targets_0[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[20] && f_s1_io_out_s1_full_pred_1_targets_0[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[21] && f_s1_io_out_s1_full_pred_1_targets_0[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[22] && f_s1_io_out_s1_full_pred_1_targets_0[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[23] && f_s1_io_out_s1_full_pred_1_targets_0[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[24] && f_s1_io_out_s1_full_pred_1_targets_0[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[25] && f_s1_io_out_s1_full_pred_1_targets_0[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[26] && f_s1_io_out_s1_full_pred_1_targets_0[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[27] && f_s1_io_out_s1_full_pred_1_targets_0[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[28] && f_s1_io_out_s1_full_pred_1_targets_0[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[29] && f_s1_io_out_s1_full_pred_1_targets_0[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[30] && f_s1_io_out_s1_full_pred_1_targets_0[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[31] && f_s1_io_out_s1_full_pred_1_targets_0[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[32] && f_s1_io_out_s1_full_pred_1_targets_0[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[33] && f_s1_io_out_s1_full_pred_1_targets_0[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[34] && f_s1_io_out_s1_full_pred_1_targets_0[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[35] && f_s1_io_out_s1_full_pred_1_targets_0[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[36] && f_s1_io_out_s1_full_pred_1_targets_0[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[37] && f_s1_io_out_s1_full_pred_1_targets_0[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[38] && f_s1_io_out_s1_full_pred_1_targets_0[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[39] && f_s1_io_out_s1_full_pred_1_targets_0[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[40] && f_s1_io_out_s1_full_pred_1_targets_0[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[41] && f_s1_io_out_s1_full_pred_1_targets_0[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[42] && f_s1_io_out_s1_full_pred_1_targets_0[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[43] && f_s1_io_out_s1_full_pred_1_targets_0[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[44] && f_s1_io_out_s1_full_pred_1_targets_0[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[45] && f_s1_io_out_s1_full_pred_1_targets_0[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[46] && f_s1_io_out_s1_full_pred_1_targets_0[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[47] && f_s1_io_out_s1_full_pred_1_targets_0[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[48] && f_s1_io_out_s1_full_pred_1_targets_0[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_0[49] && f_s1_io_out_s1_full_pred_1_targets_0[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_0[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[1] && f_s1_io_out_s1_full_pred_1_targets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[2] && f_s1_io_out_s1_full_pred_1_targets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[3] && f_s1_io_out_s1_full_pred_1_targets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[4] && f_s1_io_out_s1_full_pred_1_targets_1[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[5] && f_s1_io_out_s1_full_pred_1_targets_1[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[6] && f_s1_io_out_s1_full_pred_1_targets_1[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[7] && f_s1_io_out_s1_full_pred_1_targets_1[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[8] && f_s1_io_out_s1_full_pred_1_targets_1[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[9] && f_s1_io_out_s1_full_pred_1_targets_1[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[10] && f_s1_io_out_s1_full_pred_1_targets_1[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[11] && f_s1_io_out_s1_full_pred_1_targets_1[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[12] && f_s1_io_out_s1_full_pred_1_targets_1[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[13] && f_s1_io_out_s1_full_pred_1_targets_1[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[14] && f_s1_io_out_s1_full_pred_1_targets_1[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[15] && f_s1_io_out_s1_full_pred_1_targets_1[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[16] && f_s1_io_out_s1_full_pred_1_targets_1[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[17] && f_s1_io_out_s1_full_pred_1_targets_1[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[18] && f_s1_io_out_s1_full_pred_1_targets_1[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[19] && f_s1_io_out_s1_full_pred_1_targets_1[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[20] && f_s1_io_out_s1_full_pred_1_targets_1[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[21] && f_s1_io_out_s1_full_pred_1_targets_1[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[22] && f_s1_io_out_s1_full_pred_1_targets_1[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[23] && f_s1_io_out_s1_full_pred_1_targets_1[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[24] && f_s1_io_out_s1_full_pred_1_targets_1[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[25] && f_s1_io_out_s1_full_pred_1_targets_1[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[26] && f_s1_io_out_s1_full_pred_1_targets_1[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[27] && f_s1_io_out_s1_full_pred_1_targets_1[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[28] && f_s1_io_out_s1_full_pred_1_targets_1[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[29] && f_s1_io_out_s1_full_pred_1_targets_1[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[30] && f_s1_io_out_s1_full_pred_1_targets_1[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[31] && f_s1_io_out_s1_full_pred_1_targets_1[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[32] && f_s1_io_out_s1_full_pred_1_targets_1[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[33] && f_s1_io_out_s1_full_pred_1_targets_1[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[34] && f_s1_io_out_s1_full_pred_1_targets_1[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[35] && f_s1_io_out_s1_full_pred_1_targets_1[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[36] && f_s1_io_out_s1_full_pred_1_targets_1[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[37] && f_s1_io_out_s1_full_pred_1_targets_1[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[38] && f_s1_io_out_s1_full_pred_1_targets_1[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[39] && f_s1_io_out_s1_full_pred_1_targets_1[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[40] && f_s1_io_out_s1_full_pred_1_targets_1[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[41] && f_s1_io_out_s1_full_pred_1_targets_1[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[42] && f_s1_io_out_s1_full_pred_1_targets_1[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[43] && f_s1_io_out_s1_full_pred_1_targets_1[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[44] && f_s1_io_out_s1_full_pred_1_targets_1[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[45] && f_s1_io_out_s1_full_pred_1_targets_1[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[46] && f_s1_io_out_s1_full_pred_1_targets_1[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[47] && f_s1_io_out_s1_full_pred_1_targets_1[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[48] && f_s1_io_out_s1_full_pred_1_targets_1[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_targets_1[49] && f_s1_io_out_s1_full_pred_1_targets_1[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_targets_1[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[1] && f_s1_io_out_s1_full_pred_1_jalr_target[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[2] && f_s1_io_out_s1_full_pred_1_jalr_target[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[3] && f_s1_io_out_s1_full_pred_1_jalr_target[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[4] && f_s1_io_out_s1_full_pred_1_jalr_target[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[5] && f_s1_io_out_s1_full_pred_1_jalr_target[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[6] && f_s1_io_out_s1_full_pred_1_jalr_target[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[7] && f_s1_io_out_s1_full_pred_1_jalr_target[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[8] && f_s1_io_out_s1_full_pred_1_jalr_target[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[9] && f_s1_io_out_s1_full_pred_1_jalr_target[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[10] && f_s1_io_out_s1_full_pred_1_jalr_target[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[11] && f_s1_io_out_s1_full_pred_1_jalr_target[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[12] && f_s1_io_out_s1_full_pred_1_jalr_target[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[13] && f_s1_io_out_s1_full_pred_1_jalr_target[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[14] && f_s1_io_out_s1_full_pred_1_jalr_target[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[15] && f_s1_io_out_s1_full_pred_1_jalr_target[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[16] && f_s1_io_out_s1_full_pred_1_jalr_target[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[17] && f_s1_io_out_s1_full_pred_1_jalr_target[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[18] && f_s1_io_out_s1_full_pred_1_jalr_target[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[19] && f_s1_io_out_s1_full_pred_1_jalr_target[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[20] && f_s1_io_out_s1_full_pred_1_jalr_target[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[21] && f_s1_io_out_s1_full_pred_1_jalr_target[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[22] && f_s1_io_out_s1_full_pred_1_jalr_target[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[23] && f_s1_io_out_s1_full_pred_1_jalr_target[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[24] && f_s1_io_out_s1_full_pred_1_jalr_target[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[25] && f_s1_io_out_s1_full_pred_1_jalr_target[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[26] && f_s1_io_out_s1_full_pred_1_jalr_target[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[27] && f_s1_io_out_s1_full_pred_1_jalr_target[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[28] && f_s1_io_out_s1_full_pred_1_jalr_target[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[29] && f_s1_io_out_s1_full_pred_1_jalr_target[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[30] && f_s1_io_out_s1_full_pred_1_jalr_target[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[31] && f_s1_io_out_s1_full_pred_1_jalr_target[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[32] && f_s1_io_out_s1_full_pred_1_jalr_target[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[33] && f_s1_io_out_s1_full_pred_1_jalr_target[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[34] && f_s1_io_out_s1_full_pred_1_jalr_target[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[35] && f_s1_io_out_s1_full_pred_1_jalr_target[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[36] && f_s1_io_out_s1_full_pred_1_jalr_target[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[37] && f_s1_io_out_s1_full_pred_1_jalr_target[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[38] && f_s1_io_out_s1_full_pred_1_jalr_target[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[39] && f_s1_io_out_s1_full_pred_1_jalr_target[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[40] && f_s1_io_out_s1_full_pred_1_jalr_target[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[41] && f_s1_io_out_s1_full_pred_1_jalr_target[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[42] && f_s1_io_out_s1_full_pred_1_jalr_target[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[43] && f_s1_io_out_s1_full_pred_1_jalr_target[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[44] && f_s1_io_out_s1_full_pred_1_jalr_target[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[45] && f_s1_io_out_s1_full_pred_1_jalr_target[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[46] && f_s1_io_out_s1_full_pred_1_jalr_target[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[47] && f_s1_io_out_s1_full_pred_1_jalr_target[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[48] && f_s1_io_out_s1_full_pred_1_jalr_target[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_jalr_target[49] && f_s1_io_out_s1_full_pred_1_jalr_target[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_jalr_target[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_0[0] && f_s1_io_out_s1_full_pred_1_offsets_0[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_0[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_0[1] && f_s1_io_out_s1_full_pred_1_offsets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_0[2] && f_s1_io_out_s1_full_pred_1_offsets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_0[3] && f_s1_io_out_s1_full_pred_1_offsets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_1[0] && f_s1_io_out_s1_full_pred_1_offsets_1[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_1[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_1[1] && f_s1_io_out_s1_full_pred_1_offsets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_1[2] && f_s1_io_out_s1_full_pred_1_offsets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_offsets_1[3] && f_s1_io_out_s1_full_pred_1_offsets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_offsets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[0] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[1] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[2] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[3] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[4] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[5] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[6] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[7] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[8] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[9] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[10] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[11] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[12] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[13] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[14] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[15] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[16] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[17] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[18] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[19] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[20] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[21] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[22] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[23] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[24] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[25] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[26] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[27] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[28] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[29] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[30] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[31] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[32] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[33] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[34] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[35] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[36] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[37] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[38] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[39] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[40] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[41] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[42] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[43] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[44] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[45] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[46] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[47] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[48] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughAddr[49] && f_s1_io_out_s1_full_pred_1_fallThroughAddr[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_fallThroughErr && f_s1_io_out_s1_full_pred_1_fallThroughErr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_fallThroughErr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_is_jal && f_s1_io_out_s1_full_pred_1_is_jal)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_is_jal 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_is_jalr && f_s1_io_out_s1_full_pred_1_is_jalr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_is_jalr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_is_call && f_s1_io_out_s1_full_pred_1_is_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_is_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_is_ret && f_s1_io_out_s1_full_pred_1_is_ret)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_is_ret 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_last_may_be_rvi_call && f_s1_io_out_s1_full_pred_1_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_is_br_sharing && f_s1_io_out_s1_full_pred_1_is_br_sharing)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_is_br_sharing 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_1_hit && f_s1_io_out_s1_full_pred_1_hit)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_1_hit 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_br_taken_mask_0 && f_s1_io_out_s1_full_pred_2_br_taken_mask_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_br_taken_mask_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_br_taken_mask_1 && f_s1_io_out_s1_full_pred_2_br_taken_mask_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_br_taken_mask_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_slot_valids_0 && f_s1_io_out_s1_full_pred_2_slot_valids_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_slot_valids_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_slot_valids_1 && f_s1_io_out_s1_full_pred_2_slot_valids_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_slot_valids_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[1] && f_s1_io_out_s1_full_pred_2_targets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[2] && f_s1_io_out_s1_full_pred_2_targets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[3] && f_s1_io_out_s1_full_pred_2_targets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[4] && f_s1_io_out_s1_full_pred_2_targets_0[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[5] && f_s1_io_out_s1_full_pred_2_targets_0[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[6] && f_s1_io_out_s1_full_pred_2_targets_0[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[7] && f_s1_io_out_s1_full_pred_2_targets_0[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[8] && f_s1_io_out_s1_full_pred_2_targets_0[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[9] && f_s1_io_out_s1_full_pred_2_targets_0[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[10] && f_s1_io_out_s1_full_pred_2_targets_0[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[11] && f_s1_io_out_s1_full_pred_2_targets_0[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[12] && f_s1_io_out_s1_full_pred_2_targets_0[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[13] && f_s1_io_out_s1_full_pred_2_targets_0[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[14] && f_s1_io_out_s1_full_pred_2_targets_0[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[15] && f_s1_io_out_s1_full_pred_2_targets_0[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[16] && f_s1_io_out_s1_full_pred_2_targets_0[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[17] && f_s1_io_out_s1_full_pred_2_targets_0[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[18] && f_s1_io_out_s1_full_pred_2_targets_0[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[19] && f_s1_io_out_s1_full_pred_2_targets_0[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[20] && f_s1_io_out_s1_full_pred_2_targets_0[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[21] && f_s1_io_out_s1_full_pred_2_targets_0[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[22] && f_s1_io_out_s1_full_pred_2_targets_0[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[23] && f_s1_io_out_s1_full_pred_2_targets_0[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[24] && f_s1_io_out_s1_full_pred_2_targets_0[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[25] && f_s1_io_out_s1_full_pred_2_targets_0[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[26] && f_s1_io_out_s1_full_pred_2_targets_0[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[27] && f_s1_io_out_s1_full_pred_2_targets_0[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[28] && f_s1_io_out_s1_full_pred_2_targets_0[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[29] && f_s1_io_out_s1_full_pred_2_targets_0[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[30] && f_s1_io_out_s1_full_pred_2_targets_0[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[31] && f_s1_io_out_s1_full_pred_2_targets_0[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[32] && f_s1_io_out_s1_full_pred_2_targets_0[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[33] && f_s1_io_out_s1_full_pred_2_targets_0[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[34] && f_s1_io_out_s1_full_pred_2_targets_0[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[35] && f_s1_io_out_s1_full_pred_2_targets_0[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[36] && f_s1_io_out_s1_full_pred_2_targets_0[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[37] && f_s1_io_out_s1_full_pred_2_targets_0[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[38] && f_s1_io_out_s1_full_pred_2_targets_0[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[39] && f_s1_io_out_s1_full_pred_2_targets_0[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[40] && f_s1_io_out_s1_full_pred_2_targets_0[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[41] && f_s1_io_out_s1_full_pred_2_targets_0[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[42] && f_s1_io_out_s1_full_pred_2_targets_0[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[43] && f_s1_io_out_s1_full_pred_2_targets_0[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[44] && f_s1_io_out_s1_full_pred_2_targets_0[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[45] && f_s1_io_out_s1_full_pred_2_targets_0[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[46] && f_s1_io_out_s1_full_pred_2_targets_0[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[47] && f_s1_io_out_s1_full_pred_2_targets_0[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[48] && f_s1_io_out_s1_full_pred_2_targets_0[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_0[49] && f_s1_io_out_s1_full_pred_2_targets_0[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_0[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[1] && f_s1_io_out_s1_full_pred_2_targets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[2] && f_s1_io_out_s1_full_pred_2_targets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[3] && f_s1_io_out_s1_full_pred_2_targets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[4] && f_s1_io_out_s1_full_pred_2_targets_1[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[5] && f_s1_io_out_s1_full_pred_2_targets_1[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[6] && f_s1_io_out_s1_full_pred_2_targets_1[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[7] && f_s1_io_out_s1_full_pred_2_targets_1[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[8] && f_s1_io_out_s1_full_pred_2_targets_1[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[9] && f_s1_io_out_s1_full_pred_2_targets_1[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[10] && f_s1_io_out_s1_full_pred_2_targets_1[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[11] && f_s1_io_out_s1_full_pred_2_targets_1[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[12] && f_s1_io_out_s1_full_pred_2_targets_1[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[13] && f_s1_io_out_s1_full_pred_2_targets_1[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[14] && f_s1_io_out_s1_full_pred_2_targets_1[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[15] && f_s1_io_out_s1_full_pred_2_targets_1[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[16] && f_s1_io_out_s1_full_pred_2_targets_1[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[17] && f_s1_io_out_s1_full_pred_2_targets_1[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[18] && f_s1_io_out_s1_full_pred_2_targets_1[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[19] && f_s1_io_out_s1_full_pred_2_targets_1[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[20] && f_s1_io_out_s1_full_pred_2_targets_1[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[21] && f_s1_io_out_s1_full_pred_2_targets_1[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[22] && f_s1_io_out_s1_full_pred_2_targets_1[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[23] && f_s1_io_out_s1_full_pred_2_targets_1[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[24] && f_s1_io_out_s1_full_pred_2_targets_1[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[25] && f_s1_io_out_s1_full_pred_2_targets_1[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[26] && f_s1_io_out_s1_full_pred_2_targets_1[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[27] && f_s1_io_out_s1_full_pred_2_targets_1[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[28] && f_s1_io_out_s1_full_pred_2_targets_1[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[29] && f_s1_io_out_s1_full_pred_2_targets_1[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[30] && f_s1_io_out_s1_full_pred_2_targets_1[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[31] && f_s1_io_out_s1_full_pred_2_targets_1[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[32] && f_s1_io_out_s1_full_pred_2_targets_1[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[33] && f_s1_io_out_s1_full_pred_2_targets_1[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[34] && f_s1_io_out_s1_full_pred_2_targets_1[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[35] && f_s1_io_out_s1_full_pred_2_targets_1[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[36] && f_s1_io_out_s1_full_pred_2_targets_1[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[37] && f_s1_io_out_s1_full_pred_2_targets_1[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[38] && f_s1_io_out_s1_full_pred_2_targets_1[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[39] && f_s1_io_out_s1_full_pred_2_targets_1[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[40] && f_s1_io_out_s1_full_pred_2_targets_1[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[41] && f_s1_io_out_s1_full_pred_2_targets_1[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[42] && f_s1_io_out_s1_full_pred_2_targets_1[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[43] && f_s1_io_out_s1_full_pred_2_targets_1[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[44] && f_s1_io_out_s1_full_pred_2_targets_1[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[45] && f_s1_io_out_s1_full_pred_2_targets_1[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[46] && f_s1_io_out_s1_full_pred_2_targets_1[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[47] && f_s1_io_out_s1_full_pred_2_targets_1[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[48] && f_s1_io_out_s1_full_pred_2_targets_1[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_targets_1[49] && f_s1_io_out_s1_full_pred_2_targets_1[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_targets_1[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[1] && f_s1_io_out_s1_full_pred_2_jalr_target[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[2] && f_s1_io_out_s1_full_pred_2_jalr_target[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[3] && f_s1_io_out_s1_full_pred_2_jalr_target[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[4] && f_s1_io_out_s1_full_pred_2_jalr_target[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[5] && f_s1_io_out_s1_full_pred_2_jalr_target[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[6] && f_s1_io_out_s1_full_pred_2_jalr_target[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[7] && f_s1_io_out_s1_full_pred_2_jalr_target[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[8] && f_s1_io_out_s1_full_pred_2_jalr_target[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[9] && f_s1_io_out_s1_full_pred_2_jalr_target[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[10] && f_s1_io_out_s1_full_pred_2_jalr_target[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[11] && f_s1_io_out_s1_full_pred_2_jalr_target[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[12] && f_s1_io_out_s1_full_pred_2_jalr_target[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[13] && f_s1_io_out_s1_full_pred_2_jalr_target[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[14] && f_s1_io_out_s1_full_pred_2_jalr_target[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[15] && f_s1_io_out_s1_full_pred_2_jalr_target[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[16] && f_s1_io_out_s1_full_pred_2_jalr_target[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[17] && f_s1_io_out_s1_full_pred_2_jalr_target[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[18] && f_s1_io_out_s1_full_pred_2_jalr_target[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[19] && f_s1_io_out_s1_full_pred_2_jalr_target[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[20] && f_s1_io_out_s1_full_pred_2_jalr_target[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[21] && f_s1_io_out_s1_full_pred_2_jalr_target[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[22] && f_s1_io_out_s1_full_pred_2_jalr_target[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[23] && f_s1_io_out_s1_full_pred_2_jalr_target[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[24] && f_s1_io_out_s1_full_pred_2_jalr_target[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[25] && f_s1_io_out_s1_full_pred_2_jalr_target[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[26] && f_s1_io_out_s1_full_pred_2_jalr_target[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[27] && f_s1_io_out_s1_full_pred_2_jalr_target[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[28] && f_s1_io_out_s1_full_pred_2_jalr_target[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[29] && f_s1_io_out_s1_full_pred_2_jalr_target[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[30] && f_s1_io_out_s1_full_pred_2_jalr_target[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[31] && f_s1_io_out_s1_full_pred_2_jalr_target[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[32] && f_s1_io_out_s1_full_pred_2_jalr_target[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[33] && f_s1_io_out_s1_full_pred_2_jalr_target[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[34] && f_s1_io_out_s1_full_pred_2_jalr_target[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[35] && f_s1_io_out_s1_full_pred_2_jalr_target[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[36] && f_s1_io_out_s1_full_pred_2_jalr_target[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[37] && f_s1_io_out_s1_full_pred_2_jalr_target[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[38] && f_s1_io_out_s1_full_pred_2_jalr_target[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[39] && f_s1_io_out_s1_full_pred_2_jalr_target[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[40] && f_s1_io_out_s1_full_pred_2_jalr_target[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[41] && f_s1_io_out_s1_full_pred_2_jalr_target[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[42] && f_s1_io_out_s1_full_pred_2_jalr_target[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[43] && f_s1_io_out_s1_full_pred_2_jalr_target[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[44] && f_s1_io_out_s1_full_pred_2_jalr_target[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[45] && f_s1_io_out_s1_full_pred_2_jalr_target[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[46] && f_s1_io_out_s1_full_pred_2_jalr_target[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[47] && f_s1_io_out_s1_full_pred_2_jalr_target[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[48] && f_s1_io_out_s1_full_pred_2_jalr_target[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_jalr_target[49] && f_s1_io_out_s1_full_pred_2_jalr_target[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_jalr_target[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_0[0] && f_s1_io_out_s1_full_pred_2_offsets_0[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_0[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_0[1] && f_s1_io_out_s1_full_pred_2_offsets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_0[2] && f_s1_io_out_s1_full_pred_2_offsets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_0[3] && f_s1_io_out_s1_full_pred_2_offsets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_1[0] && f_s1_io_out_s1_full_pred_2_offsets_1[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_1[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_1[1] && f_s1_io_out_s1_full_pred_2_offsets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_1[2] && f_s1_io_out_s1_full_pred_2_offsets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_offsets_1[3] && f_s1_io_out_s1_full_pred_2_offsets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_offsets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[0] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[1] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[2] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[3] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[4] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[5] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[6] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[7] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[8] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[9] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[10] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[11] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[12] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[13] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[14] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[15] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[16] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[17] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[18] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[19] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[20] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[21] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[22] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[23] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[24] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[25] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[26] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[27] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[28] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[29] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[30] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[31] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[32] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[33] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[34] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[35] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[36] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[37] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[38] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[39] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[40] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[41] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[42] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[43] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[44] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[45] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[46] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[47] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[48] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughAddr[49] && f_s1_io_out_s1_full_pred_2_fallThroughAddr[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_fallThroughErr && f_s1_io_out_s1_full_pred_2_fallThroughErr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_fallThroughErr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_is_jal && f_s1_io_out_s1_full_pred_2_is_jal)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_is_jal 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_is_jalr && f_s1_io_out_s1_full_pred_2_is_jalr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_is_jalr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_is_call && f_s1_io_out_s1_full_pred_2_is_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_is_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_is_ret && f_s1_io_out_s1_full_pred_2_is_ret)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_is_ret 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_last_may_be_rvi_call && f_s1_io_out_s1_full_pred_2_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_is_br_sharing && f_s1_io_out_s1_full_pred_2_is_br_sharing)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_is_br_sharing 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_2_hit && f_s1_io_out_s1_full_pred_2_hit)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_2_hit 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_br_taken_mask_0 && f_s1_io_out_s1_full_pred_3_br_taken_mask_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_br_taken_mask_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_br_taken_mask_1 && f_s1_io_out_s1_full_pred_3_br_taken_mask_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_br_taken_mask_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_slot_valids_0 && f_s1_io_out_s1_full_pred_3_slot_valids_0)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_slot_valids_0 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_slot_valids_1 && f_s1_io_out_s1_full_pred_3_slot_valids_1)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_slot_valids_1 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[1] && f_s1_io_out_s1_full_pred_3_targets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[2] && f_s1_io_out_s1_full_pred_3_targets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[3] && f_s1_io_out_s1_full_pred_3_targets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[4] && f_s1_io_out_s1_full_pred_3_targets_0[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[5] && f_s1_io_out_s1_full_pred_3_targets_0[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[6] && f_s1_io_out_s1_full_pred_3_targets_0[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[7] && f_s1_io_out_s1_full_pred_3_targets_0[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[8] && f_s1_io_out_s1_full_pred_3_targets_0[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[9] && f_s1_io_out_s1_full_pred_3_targets_0[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[10] && f_s1_io_out_s1_full_pred_3_targets_0[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[11] && f_s1_io_out_s1_full_pred_3_targets_0[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[12] && f_s1_io_out_s1_full_pred_3_targets_0[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[13] && f_s1_io_out_s1_full_pred_3_targets_0[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[14] && f_s1_io_out_s1_full_pred_3_targets_0[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[15] && f_s1_io_out_s1_full_pred_3_targets_0[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[16] && f_s1_io_out_s1_full_pred_3_targets_0[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[17] && f_s1_io_out_s1_full_pred_3_targets_0[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[18] && f_s1_io_out_s1_full_pred_3_targets_0[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[19] && f_s1_io_out_s1_full_pred_3_targets_0[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[20] && f_s1_io_out_s1_full_pred_3_targets_0[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[21] && f_s1_io_out_s1_full_pred_3_targets_0[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[22] && f_s1_io_out_s1_full_pred_3_targets_0[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[23] && f_s1_io_out_s1_full_pred_3_targets_0[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[24] && f_s1_io_out_s1_full_pred_3_targets_0[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[25] && f_s1_io_out_s1_full_pred_3_targets_0[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[26] && f_s1_io_out_s1_full_pred_3_targets_0[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[27] && f_s1_io_out_s1_full_pred_3_targets_0[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[28] && f_s1_io_out_s1_full_pred_3_targets_0[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[29] && f_s1_io_out_s1_full_pred_3_targets_0[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[30] && f_s1_io_out_s1_full_pred_3_targets_0[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[31] && f_s1_io_out_s1_full_pred_3_targets_0[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[32] && f_s1_io_out_s1_full_pred_3_targets_0[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[33] && f_s1_io_out_s1_full_pred_3_targets_0[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[34] && f_s1_io_out_s1_full_pred_3_targets_0[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[35] && f_s1_io_out_s1_full_pred_3_targets_0[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[36] && f_s1_io_out_s1_full_pred_3_targets_0[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[37] && f_s1_io_out_s1_full_pred_3_targets_0[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[38] && f_s1_io_out_s1_full_pred_3_targets_0[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[39] && f_s1_io_out_s1_full_pred_3_targets_0[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[40] && f_s1_io_out_s1_full_pred_3_targets_0[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[41] && f_s1_io_out_s1_full_pred_3_targets_0[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[42] && f_s1_io_out_s1_full_pred_3_targets_0[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[43] && f_s1_io_out_s1_full_pred_3_targets_0[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[44] && f_s1_io_out_s1_full_pred_3_targets_0[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[45] && f_s1_io_out_s1_full_pred_3_targets_0[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[46] && f_s1_io_out_s1_full_pred_3_targets_0[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[47] && f_s1_io_out_s1_full_pred_3_targets_0[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[48] && f_s1_io_out_s1_full_pred_3_targets_0[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_0[49] && f_s1_io_out_s1_full_pred_3_targets_0[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_0[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[1] && f_s1_io_out_s1_full_pred_3_targets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[2] && f_s1_io_out_s1_full_pred_3_targets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[3] && f_s1_io_out_s1_full_pred_3_targets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[4] && f_s1_io_out_s1_full_pred_3_targets_1[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[5] && f_s1_io_out_s1_full_pred_3_targets_1[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[6] && f_s1_io_out_s1_full_pred_3_targets_1[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[7] && f_s1_io_out_s1_full_pred_3_targets_1[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[8] && f_s1_io_out_s1_full_pred_3_targets_1[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[9] && f_s1_io_out_s1_full_pred_3_targets_1[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[10] && f_s1_io_out_s1_full_pred_3_targets_1[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[11] && f_s1_io_out_s1_full_pred_3_targets_1[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[12] && f_s1_io_out_s1_full_pred_3_targets_1[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[13] && f_s1_io_out_s1_full_pred_3_targets_1[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[14] && f_s1_io_out_s1_full_pred_3_targets_1[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[15] && f_s1_io_out_s1_full_pred_3_targets_1[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[16] && f_s1_io_out_s1_full_pred_3_targets_1[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[17] && f_s1_io_out_s1_full_pred_3_targets_1[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[18] && f_s1_io_out_s1_full_pred_3_targets_1[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[19] && f_s1_io_out_s1_full_pred_3_targets_1[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[20] && f_s1_io_out_s1_full_pred_3_targets_1[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[21] && f_s1_io_out_s1_full_pred_3_targets_1[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[22] && f_s1_io_out_s1_full_pred_3_targets_1[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[23] && f_s1_io_out_s1_full_pred_3_targets_1[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[24] && f_s1_io_out_s1_full_pred_3_targets_1[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[25] && f_s1_io_out_s1_full_pred_3_targets_1[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[26] && f_s1_io_out_s1_full_pred_3_targets_1[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[27] && f_s1_io_out_s1_full_pred_3_targets_1[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[28] && f_s1_io_out_s1_full_pred_3_targets_1[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[29] && f_s1_io_out_s1_full_pred_3_targets_1[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[30] && f_s1_io_out_s1_full_pred_3_targets_1[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[31] && f_s1_io_out_s1_full_pred_3_targets_1[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[32] && f_s1_io_out_s1_full_pred_3_targets_1[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[33] && f_s1_io_out_s1_full_pred_3_targets_1[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[34] && f_s1_io_out_s1_full_pred_3_targets_1[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[35] && f_s1_io_out_s1_full_pred_3_targets_1[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[36] && f_s1_io_out_s1_full_pred_3_targets_1[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[37] && f_s1_io_out_s1_full_pred_3_targets_1[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[38] && f_s1_io_out_s1_full_pred_3_targets_1[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[39] && f_s1_io_out_s1_full_pred_3_targets_1[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[40] && f_s1_io_out_s1_full_pred_3_targets_1[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[41] && f_s1_io_out_s1_full_pred_3_targets_1[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[42] && f_s1_io_out_s1_full_pred_3_targets_1[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[43] && f_s1_io_out_s1_full_pred_3_targets_1[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[44] && f_s1_io_out_s1_full_pred_3_targets_1[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[45] && f_s1_io_out_s1_full_pred_3_targets_1[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[46] && f_s1_io_out_s1_full_pred_3_targets_1[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[47] && f_s1_io_out_s1_full_pred_3_targets_1[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[48] && f_s1_io_out_s1_full_pred_3_targets_1[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_targets_1[49] && f_s1_io_out_s1_full_pred_3_targets_1[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_targets_1[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[1] && f_s1_io_out_s1_full_pred_3_jalr_target[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[2] && f_s1_io_out_s1_full_pred_3_jalr_target[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[3] && f_s1_io_out_s1_full_pred_3_jalr_target[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[4] && f_s1_io_out_s1_full_pred_3_jalr_target[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[5] && f_s1_io_out_s1_full_pred_3_jalr_target[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[6] && f_s1_io_out_s1_full_pred_3_jalr_target[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[7] && f_s1_io_out_s1_full_pred_3_jalr_target[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[8] && f_s1_io_out_s1_full_pred_3_jalr_target[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[9] && f_s1_io_out_s1_full_pred_3_jalr_target[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[10] && f_s1_io_out_s1_full_pred_3_jalr_target[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[11] && f_s1_io_out_s1_full_pred_3_jalr_target[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[12] && f_s1_io_out_s1_full_pred_3_jalr_target[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[13] && f_s1_io_out_s1_full_pred_3_jalr_target[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[14] && f_s1_io_out_s1_full_pred_3_jalr_target[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[15] && f_s1_io_out_s1_full_pred_3_jalr_target[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[16] && f_s1_io_out_s1_full_pred_3_jalr_target[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[17] && f_s1_io_out_s1_full_pred_3_jalr_target[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[18] && f_s1_io_out_s1_full_pred_3_jalr_target[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[19] && f_s1_io_out_s1_full_pred_3_jalr_target[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[20] && f_s1_io_out_s1_full_pred_3_jalr_target[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[21] && f_s1_io_out_s1_full_pred_3_jalr_target[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[22] && f_s1_io_out_s1_full_pred_3_jalr_target[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[23] && f_s1_io_out_s1_full_pred_3_jalr_target[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[24] && f_s1_io_out_s1_full_pred_3_jalr_target[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[25] && f_s1_io_out_s1_full_pred_3_jalr_target[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[26] && f_s1_io_out_s1_full_pred_3_jalr_target[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[27] && f_s1_io_out_s1_full_pred_3_jalr_target[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[28] && f_s1_io_out_s1_full_pred_3_jalr_target[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[29] && f_s1_io_out_s1_full_pred_3_jalr_target[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[30] && f_s1_io_out_s1_full_pred_3_jalr_target[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[31] && f_s1_io_out_s1_full_pred_3_jalr_target[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[32] && f_s1_io_out_s1_full_pred_3_jalr_target[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[33] && f_s1_io_out_s1_full_pred_3_jalr_target[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[34] && f_s1_io_out_s1_full_pred_3_jalr_target[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[35] && f_s1_io_out_s1_full_pred_3_jalr_target[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[36] && f_s1_io_out_s1_full_pred_3_jalr_target[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[37] && f_s1_io_out_s1_full_pred_3_jalr_target[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[38] && f_s1_io_out_s1_full_pred_3_jalr_target[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[39] && f_s1_io_out_s1_full_pred_3_jalr_target[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[40] && f_s1_io_out_s1_full_pred_3_jalr_target[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[41] && f_s1_io_out_s1_full_pred_3_jalr_target[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[42] && f_s1_io_out_s1_full_pred_3_jalr_target[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[43] && f_s1_io_out_s1_full_pred_3_jalr_target[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[44] && f_s1_io_out_s1_full_pred_3_jalr_target[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[45] && f_s1_io_out_s1_full_pred_3_jalr_target[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[46] && f_s1_io_out_s1_full_pred_3_jalr_target[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[47] && f_s1_io_out_s1_full_pred_3_jalr_target[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[48] && f_s1_io_out_s1_full_pred_3_jalr_target[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_jalr_target[49] && f_s1_io_out_s1_full_pred_3_jalr_target[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_jalr_target[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_0[0] && f_s1_io_out_s1_full_pred_3_offsets_0[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_0[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_0[1] && f_s1_io_out_s1_full_pred_3_offsets_0[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_0[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_0[2] && f_s1_io_out_s1_full_pred_3_offsets_0[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_0[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_0[3] && f_s1_io_out_s1_full_pred_3_offsets_0[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_0[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_1[0] && f_s1_io_out_s1_full_pred_3_offsets_1[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_1[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_1[1] && f_s1_io_out_s1_full_pred_3_offsets_1[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_1[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_1[2] && f_s1_io_out_s1_full_pred_3_offsets_1[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_1[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_offsets_1[3] && f_s1_io_out_s1_full_pred_3_offsets_1[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_offsets_1[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[0] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[1] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[2] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[3] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[4] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[5] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[6] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[6])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[7] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[7])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[8] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[8])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[9] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[9])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[10] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[10])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[11] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[11])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[12] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[12])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[13] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[13])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[14] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[14])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[15] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[15])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[16] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[16])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[17] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[17])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[18] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[18])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[19] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[19])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[20] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[20])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[21] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[21])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[22] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[22])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[23] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[23])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[24] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[24])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[25] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[25])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[26] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[26])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[27] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[27])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[28] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[28])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[29] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[29])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[30] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[30])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[31] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[31])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[32] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[32])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[33] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[33])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[34] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[34])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[35] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[35])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[36] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[36])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[37] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[37])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[38] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[38])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[39] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[39])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[40] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[40])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[41] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[41])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[42] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[42])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[43] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[43])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[44] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[44])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[45] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[45])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[46] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[46])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[47] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[47])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[48] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[48])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughAddr[49] && f_s1_io_out_s1_full_pred_3_fallThroughAddr[49])) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_fallThroughErr && f_s1_io_out_s1_full_pred_3_fallThroughErr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_fallThroughErr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_is_jal && f_s1_io_out_s1_full_pred_3_is_jal)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_is_jal 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_is_jalr && f_s1_io_out_s1_full_pred_3_is_jalr)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_is_jalr 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_is_call && f_s1_io_out_s1_full_pred_3_is_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_is_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_is_ret && f_s1_io_out_s1_full_pred_3_is_ret)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_is_ret 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_last_may_be_rvi_call && f_s1_io_out_s1_full_pred_3_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_is_br_sharing && f_s1_io_out_s1_full_pred_3_is_br_sharing)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_is_br_sharing 未见过 0 和 1"); end
    if (!(f_s0_io_out_s1_full_pred_3_hit && f_s1_io_out_s1_full_pred_3_hit)) begin cov_fail++; $display("[COV] FauFTB.io_out_s1_full_pred_3_hit 未见过 0 和 1"); end
    if (!(f_s0_io_out_last_stage_meta[0] && f_s1_io_out_last_stage_meta[0])) begin cov_fail++; $display("[COV] FauFTB.io_out_last_stage_meta[0] 未见过 0 和 1"); end
    if (!(f_s0_io_out_last_stage_meta[1] && f_s1_io_out_last_stage_meta[1])) begin cov_fail++; $display("[COV] FauFTB.io_out_last_stage_meta[1] 未见过 0 和 1"); end
    if (!(f_s0_io_out_last_stage_meta[2] && f_s1_io_out_last_stage_meta[2])) begin cov_fail++; $display("[COV] FauFTB.io_out_last_stage_meta[2] 未见过 0 和 1"); end
    if (!(f_s0_io_out_last_stage_meta[3] && f_s1_io_out_last_stage_meta[3])) begin cov_fail++; $display("[COV] FauFTB.io_out_last_stage_meta[3] 未见过 0 和 1"); end
    if (!(f_s0_io_out_last_stage_meta[4] && f_s1_io_out_last_stage_meta[4])) begin cov_fail++; $display("[COV] FauFTB.io_out_last_stage_meta[4] 未见过 0 和 1"); end
    if (!(f_s0_io_out_last_stage_meta[5] && f_s1_io_out_last_stage_meta[5])) begin cov_fail++; $display("[COV] FauFTB.io_out_last_stage_meta[5] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_isCall && f_s1_io_fauftb_entry_out_isCall)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_isCall 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_isRet && f_s1_io_fauftb_entry_out_isRet)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_isRet 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_isJalr && f_s1_io_fauftb_entry_out_isJalr)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_isJalr 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_valid && f_s1_io_fauftb_entry_out_valid)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_valid 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_offset[0] && f_s1_io_fauftb_entry_out_brSlots_0_offset[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_offset[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_offset[1] && f_s1_io_fauftb_entry_out_brSlots_0_offset[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_offset[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_offset[2] && f_s1_io_fauftb_entry_out_brSlots_0_offset[2])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_offset[2] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_offset[3] && f_s1_io_fauftb_entry_out_brSlots_0_offset[3])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_offset[3] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_sharing && f_s1_io_fauftb_entry_out_brSlots_0_sharing)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_sharing 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_valid && f_s1_io_fauftb_entry_out_brSlots_0_valid)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_valid 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[0] && f_s1_io_fauftb_entry_out_brSlots_0_lower[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[1] && f_s1_io_fauftb_entry_out_brSlots_0_lower[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[2] && f_s1_io_fauftb_entry_out_brSlots_0_lower[2])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[2] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[3] && f_s1_io_fauftb_entry_out_brSlots_0_lower[3])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[3] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[4] && f_s1_io_fauftb_entry_out_brSlots_0_lower[4])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[4] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[5] && f_s1_io_fauftb_entry_out_brSlots_0_lower[5])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[5] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[6] && f_s1_io_fauftb_entry_out_brSlots_0_lower[6])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[6] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[7] && f_s1_io_fauftb_entry_out_brSlots_0_lower[7])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[7] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[8] && f_s1_io_fauftb_entry_out_brSlots_0_lower[8])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[8] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[9] && f_s1_io_fauftb_entry_out_brSlots_0_lower[9])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[9] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[10] && f_s1_io_fauftb_entry_out_brSlots_0_lower[10])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[10] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_lower[11] && f_s1_io_fauftb_entry_out_brSlots_0_lower[11])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_lower[11] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_tarStat[0] && f_s1_io_fauftb_entry_out_brSlots_0_tarStat[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_tarStat[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_brSlots_0_tarStat[1] && f_s1_io_fauftb_entry_out_brSlots_0_tarStat[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_brSlots_0_tarStat[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_offset[0] && f_s1_io_fauftb_entry_out_tailSlot_offset[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_offset[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_offset[1] && f_s1_io_fauftb_entry_out_tailSlot_offset[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_offset[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_offset[2] && f_s1_io_fauftb_entry_out_tailSlot_offset[2])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_offset[2] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_offset[3] && f_s1_io_fauftb_entry_out_tailSlot_offset[3])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_offset[3] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_sharing && f_s1_io_fauftb_entry_out_tailSlot_sharing)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_sharing 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_valid && f_s1_io_fauftb_entry_out_tailSlot_valid)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_valid 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[0] && f_s1_io_fauftb_entry_out_tailSlot_lower[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[1] && f_s1_io_fauftb_entry_out_tailSlot_lower[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[2] && f_s1_io_fauftb_entry_out_tailSlot_lower[2])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[2] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[3] && f_s1_io_fauftb_entry_out_tailSlot_lower[3])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[3] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[4] && f_s1_io_fauftb_entry_out_tailSlot_lower[4])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[4] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[5] && f_s1_io_fauftb_entry_out_tailSlot_lower[5])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[5] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[6] && f_s1_io_fauftb_entry_out_tailSlot_lower[6])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[6] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[7] && f_s1_io_fauftb_entry_out_tailSlot_lower[7])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[7] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[8] && f_s1_io_fauftb_entry_out_tailSlot_lower[8])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[8] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[9] && f_s1_io_fauftb_entry_out_tailSlot_lower[9])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[9] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[10] && f_s1_io_fauftb_entry_out_tailSlot_lower[10])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[10] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[11] && f_s1_io_fauftb_entry_out_tailSlot_lower[11])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[11] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[12] && f_s1_io_fauftb_entry_out_tailSlot_lower[12])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[12] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[13] && f_s1_io_fauftb_entry_out_tailSlot_lower[13])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[13] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[14] && f_s1_io_fauftb_entry_out_tailSlot_lower[14])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[14] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[15] && f_s1_io_fauftb_entry_out_tailSlot_lower[15])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[15] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[16] && f_s1_io_fauftb_entry_out_tailSlot_lower[16])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[16] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[17] && f_s1_io_fauftb_entry_out_tailSlot_lower[17])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[17] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[18] && f_s1_io_fauftb_entry_out_tailSlot_lower[18])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[18] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_lower[19] && f_s1_io_fauftb_entry_out_tailSlot_lower[19])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_lower[19] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_tarStat[0] && f_s1_io_fauftb_entry_out_tailSlot_tarStat[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_tarStat[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_tailSlot_tarStat[1] && f_s1_io_fauftb_entry_out_tailSlot_tarStat[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_tailSlot_tarStat[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_pftAddr[0] && f_s1_io_fauftb_entry_out_pftAddr[0])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_pftAddr[0] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_pftAddr[1] && f_s1_io_fauftb_entry_out_pftAddr[1])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_pftAddr[1] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_pftAddr[2] && f_s1_io_fauftb_entry_out_pftAddr[2])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_pftAddr[2] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_pftAddr[3] && f_s1_io_fauftb_entry_out_pftAddr[3])) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_pftAddr[3] 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_carry && f_s1_io_fauftb_entry_out_carry)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_carry 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_last_may_be_rvi_call && f_s1_io_fauftb_entry_out_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_strong_bias_0 && f_s1_io_fauftb_entry_out_strong_bias_0)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_strong_bias_0 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_out_strong_bias_1 && f_s1_io_fauftb_entry_out_strong_bias_1)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_out_strong_bias_1 未见过 0 和 1"); end
    if (!(f_s0_io_fauftb_entry_hit_out && f_s1_io_fauftb_entry_hit_out)) begin cov_fail++; $display("[COV] FauFTB.io_fauftb_entry_hit_out 未见过 0 和 1"); end
    if (!(f_s0_io_perf_0_value[0] && f_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] FauFTB.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(f_s0_io_perf_1_value[0] && f_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] FauFTB.io_perf_1_value[0] 未见过 0 和 1"); end
    $display("[ARM] FauFTB armed_at=%0d", f_armed_at);
    if (f_armed_at < 0) begin cov_fail++; $display("[ARM] FauFTB 从未 arm"); end
    $display("[COV] FauFTB.pred_hit = %0d", f_cov_pred_hit);
    if (f_cov_pred_hit < 50) begin cov_fail++; $display("[COV] FauFTB.pred_hit < 50"); end
    $display("[COV] FauFTB.update_hit_writeback = %0d", f_cov_update_hit_writeback);
    if (f_cov_update_hit_writeback < 50) begin cov_fail++; $display("[COV] FauFTB.update_hit_writeback < 50"); end
    $display("[COV] FauFTB.replace_when_full = %0d", f_cov_replace_when_full);
    if (f_cov_replace_when_full < 50) begin cov_fail++; $display("[COV] FauFTB.replace_when_full < 50"); end
    $display("[COV] FauFTB.ctr_sat_hold = %0d", f_cov_ctr_sat_hold);
    if (f_cov_ctr_sat_hold < 50) begin cov_fail++; $display("[COV] FauFTB.ctr_sat_hold < 50"); end
    $display("[COV] FauFTB.fall_through_err = %0d", f_cov_fall_through_err);
    if (f_cov_fall_through_err < 50) begin cov_fail++; $display("[COV] FauFTB.fall_through_err < 50"); end
    $display("[COV] FauFTB.double_touch = %0d", f_cov_double_touch);
    if (f_cov_double_touch < 50) begin cov_fail++; $display("[COV] FauFTB.double_touch < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
