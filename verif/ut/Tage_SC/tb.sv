// 生成 Tage_SC 的双例化 UT testbench（tb.sv）。
//
// golden Tage_SC（+ golden 子模块）vs 重写 Tage_SC_xs（+ 已签重写子模块），scripts/dual_tb_lib.py，端口表读 G1 golden，
// 逐拍比全部输出（透传、S2/S3 方向、sc_disagree、meta、s1_ready、perf、MBIST）。
//
// 激励要点：
//   · 预测 PC / 更新 PC 从 16 项小池子取；ghist 与全部折叠历史在大部分阶段同时为 0（两者天然一致，
//     更新写进 TageTable / SCTable 的项在预测时能被同样的 PC 查中），其余阶段全随机；
//   · 更新 75% 让两个槽都是有效条件分支（brSlot 有效、tailSlot 有效且共享、非 strong_bias），
//     taken / mispred 随机；meta 全随机，但 provider/altUsed/allocates/SC 计数器偏向能触发各更新路径的取值；
//   · ★前 3000 拍只做"不更新任何表"的 update（两个槽都无效），但 meta 的 provider.valid 与槽有效位全 1 ——
//     把只在各自使能下锁存的 updateMeta_* 无复位寄存器先灌成确定值★（需要 brSlot/tailSlot 有效才锁存的那几个，
//     在这段里让 strong_bias=1：槽有效但 updateValids=0，不触发表更新）；
//   · tage_enable / sc_enable 按阶段开关；MBIST 口与 SRAM 广播控制位平时钉 0，mode>=14 阶段全随机；
//   · 复位每 ~40000 拍一次（中途复位后各表 SRAM 复位扫描期间 req_ready 拉低，s1_ready 才会翻；复位前两侧状态相同）。
// 比较窗口：S2/S3 寄存器不复位 —— 等 golden 四份 s1_fire / s2_fire 都见过且过了灌值阶段再开比；
//   ★perf 输出用到的 S2 寄存器（s2_provideds 等）同样只在 s1_fire 时写、无复位，比较窗口晚于它们的首次写入★。
// 覆盖（golden 内部语义信号）：provider 命中 / 用 alt / useAltOnNa 计数器更新 / 分配 / tick 涨满 reset_u /
//   SC 推翻 TAGE / SC 更新 / 阈值调整 / 基础表更新。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Tage_SC =================
  int unsigned g_mode = 0;
  logic [49:0] g_pc_pool [16];
  initial for (int k = 0; k < 16; k++) g_pc_pool[k] = {$urandom, $urandom} & ~50'h1;
  logic g_reset;
  logic [47:0] g_io_reset_vector;
  logic [49:0] g_io_in_bits_s0_pc_0;
  logic [49:0] g_io_in_bits_s0_pc_1;
  logic [49:0] g_io_in_bits_s0_pc_2;
  logic [49:0] g_io_in_bits_s0_pc_3;
  logic [10:0] g_io_in_bits_folded_hist_1_hist_17_folded_hist;
  logic [10:0] g_io_in_bits_folded_hist_1_hist_16_folded_hist;
  logic [6:0] g_io_in_bits_folded_hist_1_hist_15_folded_hist;
  logic [7:0] g_io_in_bits_folded_hist_1_hist_14_folded_hist;
  logic [6:0] g_io_in_bits_folded_hist_1_hist_9_folded_hist;
  logic [7:0] g_io_in_bits_folded_hist_1_hist_8_folded_hist;
  logic [6:0] g_io_in_bits_folded_hist_1_hist_7_folded_hist;
  logic [6:0] g_io_in_bits_folded_hist_1_hist_5_folded_hist;
  logic [7:0] g_io_in_bits_folded_hist_1_hist_4_folded_hist;
  logic [7:0] g_io_in_bits_folded_hist_1_hist_3_folded_hist;
  logic [10:0] g_io_in_bits_folded_hist_1_hist_1_folded_hist;
  logic [3:0] g_io_in_bits_folded_hist_3_hist_12_folded_hist;
  logic [7:0] g_io_in_bits_folded_hist_3_hist_11_folded_hist;
  logic [7:0] g_io_in_bits_folded_hist_3_hist_2_folded_hist;
  logic [255:0] g_io_in_bits_ghist;
  logic g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0;
  logic g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1;
  wire  g_g_io_out_s2_full_pred_0_br_taken_mask_0, g_i_io_out_s2_full_pred_0_br_taken_mask_0;
  logic g_s0_io_out_s2_full_pred_0_br_taken_mask_0 = '0, g_s1_io_out_s2_full_pred_0_br_taken_mask_0 = '0;
  wire  g_g_io_out_s2_full_pred_0_br_taken_mask_1, g_i_io_out_s2_full_pred_0_br_taken_mask_1;
  logic g_s0_io_out_s2_full_pred_0_br_taken_mask_1 = '0, g_s1_io_out_s2_full_pred_0_br_taken_mask_1 = '0;
  wire  g_g_io_out_s2_full_pred_1_br_taken_mask_0, g_i_io_out_s2_full_pred_1_br_taken_mask_0;
  logic g_s0_io_out_s2_full_pred_1_br_taken_mask_0 = '0, g_s1_io_out_s2_full_pred_1_br_taken_mask_0 = '0;
  wire  g_g_io_out_s2_full_pred_1_br_taken_mask_1, g_i_io_out_s2_full_pred_1_br_taken_mask_1;
  logic g_s0_io_out_s2_full_pred_1_br_taken_mask_1 = '0, g_s1_io_out_s2_full_pred_1_br_taken_mask_1 = '0;
  wire  g_g_io_out_s2_full_pred_2_br_taken_mask_0, g_i_io_out_s2_full_pred_2_br_taken_mask_0;
  logic g_s0_io_out_s2_full_pred_2_br_taken_mask_0 = '0, g_s1_io_out_s2_full_pred_2_br_taken_mask_0 = '0;
  wire  g_g_io_out_s2_full_pred_2_br_taken_mask_1, g_i_io_out_s2_full_pred_2_br_taken_mask_1;
  logic g_s0_io_out_s2_full_pred_2_br_taken_mask_1 = '0, g_s1_io_out_s2_full_pred_2_br_taken_mask_1 = '0;
  wire  g_g_io_out_s2_full_pred_3_br_taken_mask_0, g_i_io_out_s2_full_pred_3_br_taken_mask_0;
  logic g_s0_io_out_s2_full_pred_3_br_taken_mask_0 = '0, g_s1_io_out_s2_full_pred_3_br_taken_mask_0 = '0;
  wire  g_g_io_out_s2_full_pred_3_br_taken_mask_1, g_i_io_out_s2_full_pred_3_br_taken_mask_1;
  logic g_s0_io_out_s2_full_pred_3_br_taken_mask_1 = '0, g_s1_io_out_s2_full_pred_3_br_taken_mask_1 = '0;
  wire  g_g_io_out_s3_full_pred_0_br_taken_mask_0, g_i_io_out_s3_full_pred_0_br_taken_mask_0;
  logic g_s0_io_out_s3_full_pred_0_br_taken_mask_0 = '0, g_s1_io_out_s3_full_pred_0_br_taken_mask_0 = '0;
  wire  g_g_io_out_s3_full_pred_0_br_taken_mask_1, g_i_io_out_s3_full_pred_0_br_taken_mask_1;
  logic g_s0_io_out_s3_full_pred_0_br_taken_mask_1 = '0, g_s1_io_out_s3_full_pred_0_br_taken_mask_1 = '0;
  wire  g_g_io_out_s3_full_pred_1_br_taken_mask_0, g_i_io_out_s3_full_pred_1_br_taken_mask_0;
  logic g_s0_io_out_s3_full_pred_1_br_taken_mask_0 = '0, g_s1_io_out_s3_full_pred_1_br_taken_mask_0 = '0;
  wire  g_g_io_out_s3_full_pred_1_br_taken_mask_1, g_i_io_out_s3_full_pred_1_br_taken_mask_1;
  logic g_s0_io_out_s3_full_pred_1_br_taken_mask_1 = '0, g_s1_io_out_s3_full_pred_1_br_taken_mask_1 = '0;
  wire  g_g_io_out_s3_full_pred_2_br_taken_mask_0, g_i_io_out_s3_full_pred_2_br_taken_mask_0;
  logic g_s0_io_out_s3_full_pred_2_br_taken_mask_0 = '0, g_s1_io_out_s3_full_pred_2_br_taken_mask_0 = '0;
  wire  g_g_io_out_s3_full_pred_2_br_taken_mask_1, g_i_io_out_s3_full_pred_2_br_taken_mask_1;
  logic g_s0_io_out_s3_full_pred_2_br_taken_mask_1 = '0, g_s1_io_out_s3_full_pred_2_br_taken_mask_1 = '0;
  wire  g_g_io_out_s3_full_pred_3_br_taken_mask_0, g_i_io_out_s3_full_pred_3_br_taken_mask_0;
  logic g_s0_io_out_s3_full_pred_3_br_taken_mask_0 = '0, g_s1_io_out_s3_full_pred_3_br_taken_mask_0 = '0;
  wire  g_g_io_out_s3_full_pred_3_br_taken_mask_1, g_i_io_out_s3_full_pred_3_br_taken_mask_1;
  logic g_s0_io_out_s3_full_pred_3_br_taken_mask_1 = '0, g_s1_io_out_s3_full_pred_3_br_taken_mask_1 = '0;
  wire  [515:0] g_g_io_out_last_stage_meta, g_i_io_out_last_stage_meta;
  logic [515:0] g_s0_io_out_last_stage_meta = '0, g_s1_io_out_last_stage_meta = '0;
  wire  g_g_io_out_last_stage_spec_info_sc_disagree_0, g_i_io_out_last_stage_spec_info_sc_disagree_0;
  logic g_s0_io_out_last_stage_spec_info_sc_disagree_0 = '0, g_s1_io_out_last_stage_spec_info_sc_disagree_0 = '0;
  wire  g_g_io_out_last_stage_spec_info_sc_disagree_1, g_i_io_out_last_stage_spec_info_sc_disagree_1;
  logic g_s0_io_out_last_stage_spec_info_sc_disagree_1 = '0, g_s1_io_out_last_stage_spec_info_sc_disagree_1 = '0;
  logic g_io_ctrl_tage_enable;
  logic g_io_ctrl_sc_enable;
  logic g_io_s0_fire_0;
  logic g_io_s0_fire_1;
  logic g_io_s0_fire_2;
  logic g_io_s0_fire_3;
  logic g_io_s1_fire_0;
  logic g_io_s1_fire_1;
  logic g_io_s1_fire_2;
  logic g_io_s1_fire_3;
  logic g_io_s2_fire_0;
  logic g_io_s2_fire_1;
  logic g_io_s2_fire_2;
  logic g_io_s2_fire_3;
  wire  g_g_io_s1_ready, g_i_io_s1_ready;
  logic g_s0_io_s1_ready = '0, g_s1_io_s1_ready = '0;
  logic g_io_update_valid;
  logic [49:0] g_io_update_bits_pc;
  logic g_io_update_bits_ftb_entry_brSlots_0_valid;
  logic g_io_update_bits_ftb_entry_tailSlot_sharing;
  logic g_io_update_bits_ftb_entry_tailSlot_valid;
  logic g_io_update_bits_ftb_entry_strong_bias_0;
  logic g_io_update_bits_ftb_entry_strong_bias_1;
  logic g_io_update_bits_br_taken_mask_0;
  logic g_io_update_bits_br_taken_mask_1;
  logic g_io_update_bits_mispred_mask_0;
  logic g_io_update_bits_mispred_mask_1;
  logic [515:0] g_io_update_bits_meta;
  logic [255:0] g_io_update_bits_ghist;
  wire  [5:0] g_g_io_perf_0_value, g_i_io_perf_0_value;
  logic [5:0] g_s0_io_perf_0_value = '0, g_s1_io_perf_0_value = '0;
  wire  [5:0] g_g_io_perf_1_value, g_i_io_perf_1_value;
  logic [5:0] g_s0_io_perf_1_value = '0, g_s1_io_perf_1_value = '0;
  wire  [5:0] g_g_io_perf_2_value, g_i_io_perf_2_value;
  logic [5:0] g_s0_io_perf_2_value = '0, g_s1_io_perf_2_value = '0;
  logic [6:0] g_boreChildrenBd_bore_array;
  logic g_boreChildrenBd_bore_all;
  logic g_boreChildrenBd_bore_req;
  wire  g_g_boreChildrenBd_bore_ack, g_i_boreChildrenBd_bore_ack;
  logic g_s0_boreChildrenBd_bore_ack = '0, g_s1_boreChildrenBd_bore_ack = '0;
  logic g_boreChildrenBd_bore_writeen;
  logic [15:0] g_boreChildrenBd_bore_be;
  logic [9:0] g_boreChildrenBd_bore_addr;
  logic [23:0] g_boreChildrenBd_bore_indata;
  logic g_boreChildrenBd_bore_readen;
  logic [9:0] g_boreChildrenBd_bore_addr_rd;
  wire  [23:0] g_g_boreChildrenBd_bore_outdata, g_i_boreChildrenBd_bore_outdata;
  logic [23:0] g_s0_boreChildrenBd_bore_outdata = '0, g_s1_boreChildrenBd_bore_outdata = '0;
  logic [6:0] g_boreChildrenBd_bore_1_array;
  logic g_boreChildrenBd_bore_1_all;
  logic g_boreChildrenBd_bore_1_req;
  wire  g_g_boreChildrenBd_bore_1_ack, g_i_boreChildrenBd_bore_1_ack;
  logic g_s0_boreChildrenBd_bore_1_ack = '0, g_s1_boreChildrenBd_bore_1_ack = '0;
  logic g_boreChildrenBd_bore_1_writeen;
  logic [3:0] g_boreChildrenBd_bore_1_be;
  logic [7:0] g_boreChildrenBd_bore_1_addr;
  logic [23:0] g_boreChildrenBd_bore_1_indata;
  logic g_boreChildrenBd_bore_1_readen;
  logic [7:0] g_boreChildrenBd_bore_1_addr_rd;
  wire  [23:0] g_g_boreChildrenBd_bore_1_outdata, g_i_boreChildrenBd_bore_1_outdata;
  logic [23:0] g_s0_boreChildrenBd_bore_1_outdata = '0, g_s1_boreChildrenBd_bore_1_outdata = '0;
  logic [6:0] g_boreChildrenBd_bore_2_array;
  logic g_boreChildrenBd_bore_2_all;
  logic g_boreChildrenBd_bore_2_req;
  wire  g_g_boreChildrenBd_bore_2_ack, g_i_boreChildrenBd_bore_2_ack;
  logic g_s0_boreChildrenBd_bore_2_ack = '0, g_s1_boreChildrenBd_bore_2_ack = '0;
  logic g_boreChildrenBd_bore_2_writeen;
  logic [3:0] g_boreChildrenBd_bore_2_be;
  logic [7:0] g_boreChildrenBd_bore_2_addr;
  logic [23:0] g_boreChildrenBd_bore_2_indata;
  logic g_boreChildrenBd_bore_2_readen;
  logic [7:0] g_boreChildrenBd_bore_2_addr_rd;
  wire  [23:0] g_g_boreChildrenBd_bore_2_outdata, g_i_boreChildrenBd_bore_2_outdata;
  logic [23:0] g_s0_boreChildrenBd_bore_2_outdata = '0, g_s1_boreChildrenBd_bore_2_outdata = '0;
  logic [6:0] g_boreChildrenBd_bore_3_array;
  logic g_boreChildrenBd_bore_3_all;
  logic g_boreChildrenBd_bore_3_req;
  wire  g_g_boreChildrenBd_bore_3_ack, g_i_boreChildrenBd_bore_3_ack;
  logic g_s0_boreChildrenBd_bore_3_ack = '0, g_s1_boreChildrenBd_bore_3_ack = '0;
  logic g_boreChildrenBd_bore_3_writeen;
  logic [3:0] g_boreChildrenBd_bore_3_be;
  logic [7:0] g_boreChildrenBd_bore_3_addr;
  logic [23:0] g_boreChildrenBd_bore_3_indata;
  logic g_boreChildrenBd_bore_3_readen;
  logic [7:0] g_boreChildrenBd_bore_3_addr_rd;
  wire  [23:0] g_g_boreChildrenBd_bore_3_outdata, g_i_boreChildrenBd_bore_3_outdata;
  logic [23:0] g_s0_boreChildrenBd_bore_3_outdata = '0, g_s1_boreChildrenBd_bore_3_outdata = '0;
  logic [6:0] g_boreChildrenBd_bore_4_array;
  logic g_boreChildrenBd_bore_4_all;
  logic g_boreChildrenBd_bore_4_req;
  wire  g_g_boreChildrenBd_bore_4_ack, g_i_boreChildrenBd_bore_4_ack;
  logic g_s0_boreChildrenBd_bore_4_ack = '0, g_s1_boreChildrenBd_bore_4_ack = '0;
  logic g_boreChildrenBd_bore_4_writeen;
  logic [3:0] g_boreChildrenBd_bore_4_be;
  logic [7:0] g_boreChildrenBd_bore_4_addr;
  logic [23:0] g_boreChildrenBd_bore_4_indata;
  logic g_boreChildrenBd_bore_4_readen;
  logic [7:0] g_boreChildrenBd_bore_4_addr_rd;
  wire  [23:0] g_g_boreChildrenBd_bore_4_outdata, g_i_boreChildrenBd_bore_4_outdata;
  logic [23:0] g_s0_boreChildrenBd_bore_4_outdata = '0, g_s1_boreChildrenBd_bore_4_outdata = '0;
  logic g_sigFromSrams_bore_ram_hold;
  logic g_sigFromSrams_bore_ram_bypass;
  logic g_sigFromSrams_bore_ram_bp_clken;
  logic g_sigFromSrams_bore_ram_aux_clk;
  logic g_sigFromSrams_bore_ram_aux_ckbp;
  logic g_sigFromSrams_bore_ram_mcp_hold;
  logic g_sigFromSrams_bore_cgen;
  logic g_sigFromSrams_bore_1_ram_hold;
  logic g_sigFromSrams_bore_1_ram_bypass;
  logic g_sigFromSrams_bore_1_ram_bp_clken;
  logic g_sigFromSrams_bore_1_ram_aux_clk;
  logic g_sigFromSrams_bore_1_ram_aux_ckbp;
  logic g_sigFromSrams_bore_1_ram_mcp_hold;
  logic g_sigFromSrams_bore_1_cgen;
  logic g_sigFromSrams_bore_2_ram_hold;
  logic g_sigFromSrams_bore_2_ram_bypass;
  logic g_sigFromSrams_bore_2_ram_bp_clken;
  logic g_sigFromSrams_bore_2_ram_aux_clk;
  logic g_sigFromSrams_bore_2_ram_aux_ckbp;
  logic g_sigFromSrams_bore_2_ram_mcp_hold;
  logic g_sigFromSrams_bore_2_cgen;
  logic g_sigFromSrams_bore_3_ram_hold;
  logic g_sigFromSrams_bore_3_ram_bypass;
  logic g_sigFromSrams_bore_3_ram_bp_clken;
  logic g_sigFromSrams_bore_3_ram_aux_clk;
  logic g_sigFromSrams_bore_3_ram_aux_ckbp;
  logic g_sigFromSrams_bore_3_ram_mcp_hold;
  logic g_sigFromSrams_bore_3_cgen;
  logic g_sigFromSrams_bore_4_ram_hold;
  logic g_sigFromSrams_bore_4_ram_bypass;
  logic g_sigFromSrams_bore_4_ram_bp_clken;
  logic g_sigFromSrams_bore_4_ram_aux_clk;
  logic g_sigFromSrams_bore_4_ram_aux_ckbp;
  logic g_sigFromSrams_bore_4_ram_mcp_hold;
  logic g_sigFromSrams_bore_4_cgen;
  logic g_sigFromSrams_bore_5_ram_hold;
  logic g_sigFromSrams_bore_5_ram_bypass;
  logic g_sigFromSrams_bore_5_ram_bp_clken;
  logic g_sigFromSrams_bore_5_ram_aux_clk;
  logic g_sigFromSrams_bore_5_ram_aux_ckbp;
  logic g_sigFromSrams_bore_5_ram_mcp_hold;
  logic g_sigFromSrams_bore_5_cgen;
  logic g_sigFromSrams_bore_6_ram_hold;
  logic g_sigFromSrams_bore_6_ram_bypass;
  logic g_sigFromSrams_bore_6_ram_bp_clken;
  logic g_sigFromSrams_bore_6_ram_aux_clk;
  logic g_sigFromSrams_bore_6_ram_aux_ckbp;
  logic g_sigFromSrams_bore_6_ram_mcp_hold;
  logic g_sigFromSrams_bore_6_cgen;
  logic g_sigFromSrams_bore_7_ram_hold;
  logic g_sigFromSrams_bore_7_ram_bypass;
  logic g_sigFromSrams_bore_7_ram_bp_clken;
  logic g_sigFromSrams_bore_7_ram_aux_clk;
  logic g_sigFromSrams_bore_7_ram_aux_ckbp;
  logic g_sigFromSrams_bore_7_ram_mcp_hold;
  logic g_sigFromSrams_bore_7_cgen;
  logic g_sigFromSrams_bore_8_ram_hold;
  logic g_sigFromSrams_bore_8_ram_bypass;
  logic g_sigFromSrams_bore_8_ram_bp_clken;
  logic g_sigFromSrams_bore_8_ram_aux_clk;
  logic g_sigFromSrams_bore_8_ram_aux_ckbp;
  logic g_sigFromSrams_bore_8_ram_mcp_hold;
  logic g_sigFromSrams_bore_8_cgen;
  logic g_sigFromSrams_bore_9_ram_hold;
  logic g_sigFromSrams_bore_9_ram_bypass;
  logic g_sigFromSrams_bore_9_ram_bp_clken;
  logic g_sigFromSrams_bore_9_ram_aux_clk;
  logic g_sigFromSrams_bore_9_ram_aux_ckbp;
  logic g_sigFromSrams_bore_9_ram_mcp_hold;
  logic g_sigFromSrams_bore_9_cgen;
  logic g_sigFromSrams_bore_10_ram_hold;
  logic g_sigFromSrams_bore_10_ram_bypass;
  logic g_sigFromSrams_bore_10_ram_bp_clken;
  logic g_sigFromSrams_bore_10_ram_aux_clk;
  logic g_sigFromSrams_bore_10_ram_aux_ckbp;
  logic g_sigFromSrams_bore_10_ram_mcp_hold;
  logic g_sigFromSrams_bore_10_cgen;
  logic g_sigFromSrams_bore_11_ram_hold;
  logic g_sigFromSrams_bore_11_ram_bypass;
  logic g_sigFromSrams_bore_11_ram_bp_clken;
  logic g_sigFromSrams_bore_11_ram_aux_clk;
  logic g_sigFromSrams_bore_11_ram_aux_ckbp;
  logic g_sigFromSrams_bore_11_ram_mcp_hold;
  logic g_sigFromSrams_bore_11_cgen;
  logic g_sigFromSrams_bore_12_ram_hold;
  logic g_sigFromSrams_bore_12_ram_bypass;
  logic g_sigFromSrams_bore_12_ram_bp_clken;
  logic g_sigFromSrams_bore_12_ram_aux_clk;
  logic g_sigFromSrams_bore_12_ram_aux_ckbp;
  logic g_sigFromSrams_bore_12_ram_mcp_hold;
  logic g_sigFromSrams_bore_12_cgen;
  logic g_sigFromSrams_bore_13_ram_hold;
  logic g_sigFromSrams_bore_13_ram_bypass;
  logic g_sigFromSrams_bore_13_ram_bp_clken;
  logic g_sigFromSrams_bore_13_ram_aux_clk;
  logic g_sigFromSrams_bore_13_ram_aux_ckbp;
  logic g_sigFromSrams_bore_13_ram_mcp_hold;
  logic g_sigFromSrams_bore_13_cgen;
  logic g_sigFromSrams_bore_14_ram_hold;
  logic g_sigFromSrams_bore_14_ram_bypass;
  logic g_sigFromSrams_bore_14_ram_bp_clken;
  logic g_sigFromSrams_bore_14_ram_aux_clk;
  logic g_sigFromSrams_bore_14_ram_aux_ckbp;
  logic g_sigFromSrams_bore_14_ram_mcp_hold;
  logic g_sigFromSrams_bore_14_cgen;
  logic g_sigFromSrams_bore_15_ram_hold;
  logic g_sigFromSrams_bore_15_ram_bypass;
  logic g_sigFromSrams_bore_15_ram_bp_clken;
  logic g_sigFromSrams_bore_15_ram_aux_clk;
  logic g_sigFromSrams_bore_15_ram_aux_ckbp;
  logic g_sigFromSrams_bore_15_ram_mcp_hold;
  logic g_sigFromSrams_bore_15_cgen;
  logic g_sigFromSrams_bore_16_ram_hold;
  logic g_sigFromSrams_bore_16_ram_bypass;
  logic g_sigFromSrams_bore_16_ram_bp_clken;
  logic g_sigFromSrams_bore_16_ram_aux_clk;
  logic g_sigFromSrams_bore_16_ram_aux_ckbp;
  logic g_sigFromSrams_bore_16_ram_mcp_hold;
  logic g_sigFromSrams_bore_16_cgen;
  logic g_sigFromSrams_bore_17_ram_hold;
  logic g_sigFromSrams_bore_17_ram_bypass;
  logic g_sigFromSrams_bore_17_ram_bp_clken;
  logic g_sigFromSrams_bore_17_ram_aux_clk;
  logic g_sigFromSrams_bore_17_ram_aux_ckbp;
  logic g_sigFromSrams_bore_17_ram_mcp_hold;
  logic g_sigFromSrams_bore_17_cgen;
  logic g_sigFromSrams_bore_18_ram_hold;
  logic g_sigFromSrams_bore_18_ram_bypass;
  logic g_sigFromSrams_bore_18_ram_bp_clken;
  logic g_sigFromSrams_bore_18_ram_aux_clk;
  logic g_sigFromSrams_bore_18_ram_aux_ckbp;
  logic g_sigFromSrams_bore_18_ram_mcp_hold;
  logic g_sigFromSrams_bore_18_cgen;
  logic g_sigFromSrams_bore_19_ram_hold;
  logic g_sigFromSrams_bore_19_ram_bypass;
  logic g_sigFromSrams_bore_19_ram_bp_clken;
  logic g_sigFromSrams_bore_19_ram_aux_clk;
  logic g_sigFromSrams_bore_19_ram_aux_ckbp;
  logic g_sigFromSrams_bore_19_ram_mcp_hold;
  logic g_sigFromSrams_bore_19_cgen;
  logic g_sigFromSrams_bore_20_ram_hold;
  logic g_sigFromSrams_bore_20_ram_bypass;
  logic g_sigFromSrams_bore_20_ram_bp_clken;
  logic g_sigFromSrams_bore_20_ram_aux_clk;
  logic g_sigFromSrams_bore_20_ram_aux_ckbp;
  logic g_sigFromSrams_bore_20_ram_mcp_hold;
  logic g_sigFromSrams_bore_20_cgen;
  logic g_sigFromSrams_bore_21_ram_hold;
  logic g_sigFromSrams_bore_21_ram_bypass;
  logic g_sigFromSrams_bore_21_ram_bp_clken;
  logic g_sigFromSrams_bore_21_ram_aux_clk;
  logic g_sigFromSrams_bore_21_ram_aux_ckbp;
  logic g_sigFromSrams_bore_21_ram_mcp_hold;
  logic g_sigFromSrams_bore_21_cgen;
  logic g_sigFromSrams_bore_22_ram_hold;
  logic g_sigFromSrams_bore_22_ram_bypass;
  logic g_sigFromSrams_bore_22_ram_bp_clken;
  logic g_sigFromSrams_bore_22_ram_aux_clk;
  logic g_sigFromSrams_bore_22_ram_aux_ckbp;
  logic g_sigFromSrams_bore_22_ram_mcp_hold;
  logic g_sigFromSrams_bore_22_cgen;
  logic g_sigFromSrams_bore_23_ram_hold;
  logic g_sigFromSrams_bore_23_ram_bypass;
  logic g_sigFromSrams_bore_23_ram_bp_clken;
  logic g_sigFromSrams_bore_23_ram_aux_clk;
  logic g_sigFromSrams_bore_23_ram_aux_ckbp;
  logic g_sigFromSrams_bore_23_ram_mcp_hold;
  logic g_sigFromSrams_bore_23_cgen;
  logic g_sigFromSrams_bore_24_ram_hold;
  logic g_sigFromSrams_bore_24_ram_bypass;
  logic g_sigFromSrams_bore_24_ram_bp_clken;
  logic g_sigFromSrams_bore_24_ram_aux_clk;
  logic g_sigFromSrams_bore_24_ram_aux_ckbp;
  logic g_sigFromSrams_bore_24_ram_mcp_hold;
  logic g_sigFromSrams_bore_24_cgen;
  logic g_sigFromSrams_bore_25_ram_hold;
  logic g_sigFromSrams_bore_25_ram_bypass;
  logic g_sigFromSrams_bore_25_ram_bp_clken;
  logic g_sigFromSrams_bore_25_ram_aux_clk;
  logic g_sigFromSrams_bore_25_ram_aux_ckbp;
  logic g_sigFromSrams_bore_25_ram_mcp_hold;
  logic g_sigFromSrams_bore_25_cgen;
  logic g_sigFromSrams_bore_26_ram_hold;
  logic g_sigFromSrams_bore_26_ram_bypass;
  logic g_sigFromSrams_bore_26_ram_bp_clken;
  logic g_sigFromSrams_bore_26_ram_aux_clk;
  logic g_sigFromSrams_bore_26_ram_aux_ckbp;
  logic g_sigFromSrams_bore_26_ram_mcp_hold;
  logic g_sigFromSrams_bore_26_cgen;
  logic g_sigFromSrams_bore_27_ram_hold;
  logic g_sigFromSrams_bore_27_ram_bypass;
  logic g_sigFromSrams_bore_27_ram_bp_clken;
  logic g_sigFromSrams_bore_27_ram_aux_clk;
  logic g_sigFromSrams_bore_27_ram_aux_ckbp;
  logic g_sigFromSrams_bore_27_ram_mcp_hold;
  logic g_sigFromSrams_bore_27_cgen;
  logic g_sigFromSrams_bore_28_ram_hold;
  logic g_sigFromSrams_bore_28_ram_bypass;
  logic g_sigFromSrams_bore_28_ram_bp_clken;
  logic g_sigFromSrams_bore_28_ram_aux_clk;
  logic g_sigFromSrams_bore_28_ram_aux_ckbp;
  logic g_sigFromSrams_bore_28_ram_mcp_hold;
  logic g_sigFromSrams_bore_28_cgen;
  logic g_sigFromSrams_bore_29_ram_hold;
  logic g_sigFromSrams_bore_29_ram_bypass;
  logic g_sigFromSrams_bore_29_ram_bp_clken;
  logic g_sigFromSrams_bore_29_ram_aux_clk;
  logic g_sigFromSrams_bore_29_ram_aux_ckbp;
  logic g_sigFromSrams_bore_29_ram_mcp_hold;
  logic g_sigFromSrams_bore_29_cgen;
  logic g_sigFromSrams_bore_30_ram_hold;
  logic g_sigFromSrams_bore_30_ram_bypass;
  logic g_sigFromSrams_bore_30_ram_bp_clken;
  logic g_sigFromSrams_bore_30_ram_aux_clk;
  logic g_sigFromSrams_bore_30_ram_aux_ckbp;
  logic g_sigFromSrams_bore_30_ram_mcp_hold;
  logic g_sigFromSrams_bore_30_cgen;
  logic g_sigFromSrams_bore_31_ram_hold;
  logic g_sigFromSrams_bore_31_ram_bypass;
  logic g_sigFromSrams_bore_31_ram_bp_clken;
  logic g_sigFromSrams_bore_31_ram_aux_clk;
  logic g_sigFromSrams_bore_31_ram_aux_ckbp;
  logic g_sigFromSrams_bore_31_ram_mcp_hold;
  logic g_sigFromSrams_bore_31_cgen;
  int g_cov_provider_hit = 0;
  int g_cov_alt_used_unconf = 0;
  int g_cov_use_alt_ctr_update = 0;
  int g_cov_allocate = 0;
  int g_cov_tick_reset_u = 0;
  int g_cov_sc_override = 0;
  int g_cov_sc_update = 0;
  int g_cov_bt_update = 0;
  logic [8:0] g_armed = '0;
  int g_armed_at = -1;
  Tage_SC g_u_gold (
    .clock(clk),
    .reset(g_reset),
    .io_reset_vector(g_io_reset_vector),
    .io_in_bits_s0_pc_0(g_io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(g_io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(g_io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(g_io_in_bits_s0_pc_3),
    .io_in_bits_folded_hist_1_hist_17_folded_hist(g_io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_in_bits_folded_hist_1_hist_16_folded_hist(g_io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_in_bits_folded_hist_1_hist_15_folded_hist(g_io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_in_bits_folded_hist_1_hist_14_folded_hist(g_io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_in_bits_folded_hist_1_hist_9_folded_hist(g_io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_in_bits_folded_hist_1_hist_8_folded_hist(g_io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_in_bits_folded_hist_1_hist_7_folded_hist(g_io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_in_bits_folded_hist_1_hist_5_folded_hist(g_io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_in_bits_folded_hist_1_hist_4_folded_hist(g_io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_in_bits_folded_hist_1_hist_3_folded_hist(g_io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_in_bits_folded_hist_1_hist_1_folded_hist(g_io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_in_bits_folded_hist_3_hist_12_folded_hist(g_io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_folded_hist_3_hist_11_folded_hist(g_io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_in_bits_folded_hist_3_hist_2_folded_hist(g_io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_ghist(g_io_in_bits_ghist),
    .io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0(g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1(g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_br_taken_mask_0(g_g_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1(g_g_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_1_br_taken_mask_0(g_g_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1(g_g_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_2_br_taken_mask_0(g_g_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1(g_g_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_3_br_taken_mask_0(g_g_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1(g_g_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_0_br_taken_mask_0(g_g_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1(g_g_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_1_br_taken_mask_0(g_g_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1(g_g_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_2_br_taken_mask_0(g_g_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1(g_g_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_3_br_taken_mask_0(g_g_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1(g_g_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_last_stage_meta(g_g_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0(g_g_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1(g_g_io_out_last_stage_spec_info_sc_disagree_1),
    .io_ctrl_tage_enable(g_io_ctrl_tage_enable),
    .io_ctrl_sc_enable(g_io_ctrl_sc_enable),
    .io_s0_fire_0(g_io_s0_fire_0),
    .io_s0_fire_1(g_io_s0_fire_1),
    .io_s0_fire_2(g_io_s0_fire_2),
    .io_s0_fire_3(g_io_s0_fire_3),
    .io_s1_fire_0(g_io_s1_fire_0),
    .io_s1_fire_1(g_io_s1_fire_1),
    .io_s1_fire_2(g_io_s1_fire_2),
    .io_s1_fire_3(g_io_s1_fire_3),
    .io_s2_fire_0(g_io_s2_fire_0),
    .io_s2_fire_1(g_io_s2_fire_1),
    .io_s2_fire_2(g_io_s2_fire_2),
    .io_s2_fire_3(g_io_s2_fire_3),
    .io_s1_ready(g_g_io_s1_ready),
    .io_update_valid(g_io_update_valid),
    .io_update_bits_pc(g_io_update_bits_pc),
    .io_update_bits_ftb_entry_brSlots_0_valid(g_io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_tailSlot_sharing(g_io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid(g_io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_strong_bias_0(g_io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1(g_io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0(g_io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1(g_io_update_bits_br_taken_mask_1),
    .io_update_bits_mispred_mask_0(g_io_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1(g_io_update_bits_mispred_mask_1),
    .io_update_bits_meta(g_io_update_bits_meta),
    .io_update_bits_ghist(g_io_update_bits_ghist),
    .io_perf_0_value(g_g_io_perf_0_value),
    .io_perf_1_value(g_g_io_perf_1_value),
    .io_perf_2_value(g_g_io_perf_2_value),
    .boreChildrenBd_bore_array(g_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(g_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(g_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(g_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(g_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(g_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(g_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(g_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(g_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g_g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array(g_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(g_boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(g_boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack(g_g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen(g_boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(g_boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(g_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(g_boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(g_boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(g_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata(g_g_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array(g_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(g_boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(g_boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack(g_g_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen(g_boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(g_boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(g_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(g_boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(g_boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(g_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata(g_g_boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_array(g_boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all(g_boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req(g_boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_ack(g_g_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_writeen(g_boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be(g_boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr(g_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata(g_boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen(g_boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd(g_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_outdata(g_g_boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_array(g_boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all(g_boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req(g_boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_ack(g_g_boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_writeen(g_boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be(g_boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr(g_boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata(g_boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen(g_boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd(g_boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_4_outdata(g_g_boreChildrenBd_bore_4_outdata),
    .sigFromSrams_bore_ram_hold(g_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(g_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(g_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(g_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(g_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(g_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(g_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(g_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(g_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(g_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(g_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(g_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(g_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(g_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(g_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(g_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(g_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(g_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(g_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(g_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(g_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(g_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(g_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(g_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(g_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(g_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(g_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(g_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(g_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(g_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(g_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(g_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(g_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(g_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(g_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(g_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(g_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(g_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(g_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(g_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(g_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(g_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(g_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(g_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(g_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(g_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(g_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(g_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(g_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(g_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(g_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(g_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(g_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(g_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(g_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(g_sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(g_sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(g_sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(g_sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(g_sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(g_sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(g_sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(g_sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(g_sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(g_sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(g_sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(g_sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(g_sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(g_sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(g_sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(g_sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(g_sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(g_sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(g_sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(g_sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(g_sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(g_sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(g_sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(g_sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(g_sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(g_sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(g_sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(g_sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(g_sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(g_sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(g_sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(g_sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(g_sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(g_sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(g_sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(g_sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(g_sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(g_sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(g_sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(g_sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(g_sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(g_sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(g_sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(g_sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(g_sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(g_sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(g_sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(g_sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(g_sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(g_sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(g_sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(g_sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(g_sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(g_sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(g_sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(g_sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(g_sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(g_sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(g_sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(g_sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(g_sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(g_sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(g_sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(g_sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(g_sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(g_sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(g_sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(g_sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(g_sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(g_sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(g_sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(g_sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(g_sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(g_sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(g_sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(g_sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(g_sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(g_sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(g_sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(g_sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(g_sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(g_sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(g_sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(g_sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(g_sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(g_sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(g_sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(g_sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(g_sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(g_sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(g_sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(g_sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(g_sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(g_sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(g_sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(g_sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(g_sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(g_sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(g_sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(g_sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(g_sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(g_sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(g_sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(g_sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(g_sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(g_sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(g_sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(g_sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(g_sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(g_sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(g_sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(g_sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(g_sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(g_sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(g_sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(g_sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(g_sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(g_sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(g_sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(g_sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(g_sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(g_sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(g_sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(g_sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(g_sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(g_sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(g_sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(g_sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(g_sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(g_sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(g_sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(g_sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(g_sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(g_sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(g_sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(g_sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(g_sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(g_sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(g_sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(g_sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(g_sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(g_sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(g_sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(g_sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(g_sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(g_sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(g_sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(g_sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(g_sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(g_sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(g_sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(g_sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(g_sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(g_sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(g_sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(g_sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(g_sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(g_sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(g_sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(g_sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(g_sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(g_sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(g_sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(g_sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(g_sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(g_sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(g_sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(g_sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(g_sigFromSrams_bore_31_cgen)
  );
  Tage_SC_xs g_u_impl (
    .clock(clk),
    .reset(g_reset),
    .io_reset_vector(g_io_reset_vector),
    .io_in_bits_s0_pc_0(g_io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(g_io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(g_io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(g_io_in_bits_s0_pc_3),
    .io_in_bits_folded_hist_1_hist_17_folded_hist(g_io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_in_bits_folded_hist_1_hist_16_folded_hist(g_io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_in_bits_folded_hist_1_hist_15_folded_hist(g_io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_in_bits_folded_hist_1_hist_14_folded_hist(g_io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_in_bits_folded_hist_1_hist_9_folded_hist(g_io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_in_bits_folded_hist_1_hist_8_folded_hist(g_io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_in_bits_folded_hist_1_hist_7_folded_hist(g_io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_in_bits_folded_hist_1_hist_5_folded_hist(g_io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_in_bits_folded_hist_1_hist_4_folded_hist(g_io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_in_bits_folded_hist_1_hist_3_folded_hist(g_io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_in_bits_folded_hist_1_hist_1_folded_hist(g_io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_in_bits_folded_hist_3_hist_12_folded_hist(g_io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_folded_hist_3_hist_11_folded_hist(g_io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_in_bits_folded_hist_3_hist_2_folded_hist(g_io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_ghist(g_io_in_bits_ghist),
    .io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0(g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1(g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_br_taken_mask_0(g_i_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1(g_i_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_1_br_taken_mask_0(g_i_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1(g_i_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_2_br_taken_mask_0(g_i_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1(g_i_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_3_br_taken_mask_0(g_i_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1(g_i_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_0_br_taken_mask_0(g_i_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1(g_i_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_1_br_taken_mask_0(g_i_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1(g_i_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_2_br_taken_mask_0(g_i_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1(g_i_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_3_br_taken_mask_0(g_i_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1(g_i_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_last_stage_meta(g_i_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0(g_i_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1(g_i_io_out_last_stage_spec_info_sc_disagree_1),
    .io_ctrl_tage_enable(g_io_ctrl_tage_enable),
    .io_ctrl_sc_enable(g_io_ctrl_sc_enable),
    .io_s0_fire_0(g_io_s0_fire_0),
    .io_s0_fire_1(g_io_s0_fire_1),
    .io_s0_fire_2(g_io_s0_fire_2),
    .io_s0_fire_3(g_io_s0_fire_3),
    .io_s1_fire_0(g_io_s1_fire_0),
    .io_s1_fire_1(g_io_s1_fire_1),
    .io_s1_fire_2(g_io_s1_fire_2),
    .io_s1_fire_3(g_io_s1_fire_3),
    .io_s2_fire_0(g_io_s2_fire_0),
    .io_s2_fire_1(g_io_s2_fire_1),
    .io_s2_fire_2(g_io_s2_fire_2),
    .io_s2_fire_3(g_io_s2_fire_3),
    .io_s1_ready(g_i_io_s1_ready),
    .io_update_valid(g_io_update_valid),
    .io_update_bits_pc(g_io_update_bits_pc),
    .io_update_bits_ftb_entry_brSlots_0_valid(g_io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_tailSlot_sharing(g_io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid(g_io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_strong_bias_0(g_io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1(g_io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0(g_io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1(g_io_update_bits_br_taken_mask_1),
    .io_update_bits_mispred_mask_0(g_io_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1(g_io_update_bits_mispred_mask_1),
    .io_update_bits_meta(g_io_update_bits_meta),
    .io_update_bits_ghist(g_io_update_bits_ghist),
    .io_perf_0_value(g_i_io_perf_0_value),
    .io_perf_1_value(g_i_io_perf_1_value),
    .io_perf_2_value(g_i_io_perf_2_value),
    .boreChildrenBd_bore_array(g_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(g_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(g_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(g_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(g_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(g_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(g_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(g_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(g_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g_i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array(g_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(g_boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(g_boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack(g_i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen(g_boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(g_boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(g_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(g_boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(g_boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(g_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata(g_i_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array(g_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(g_boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(g_boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack(g_i_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen(g_boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(g_boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(g_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(g_boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(g_boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(g_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata(g_i_boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_array(g_boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all(g_boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req(g_boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_ack(g_i_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_writeen(g_boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be(g_boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr(g_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata(g_boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen(g_boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd(g_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_outdata(g_i_boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_array(g_boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all(g_boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req(g_boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_ack(g_i_boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_writeen(g_boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be(g_boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr(g_boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata(g_boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen(g_boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd(g_boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_4_outdata(g_i_boreChildrenBd_bore_4_outdata),
    .sigFromSrams_bore_ram_hold(g_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(g_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(g_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(g_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(g_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(g_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(g_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(g_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(g_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(g_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(g_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(g_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(g_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(g_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(g_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(g_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(g_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(g_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(g_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(g_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(g_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(g_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(g_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(g_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(g_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(g_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(g_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(g_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(g_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(g_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(g_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(g_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(g_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(g_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(g_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(g_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(g_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(g_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(g_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(g_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(g_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(g_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(g_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(g_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(g_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(g_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(g_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(g_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(g_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(g_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(g_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(g_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(g_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(g_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(g_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(g_sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(g_sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(g_sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(g_sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(g_sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(g_sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(g_sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(g_sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(g_sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(g_sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(g_sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(g_sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(g_sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(g_sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(g_sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(g_sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(g_sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(g_sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(g_sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(g_sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(g_sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(g_sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(g_sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(g_sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(g_sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(g_sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(g_sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(g_sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(g_sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(g_sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(g_sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(g_sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(g_sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(g_sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(g_sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(g_sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(g_sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(g_sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(g_sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(g_sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(g_sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(g_sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(g_sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(g_sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(g_sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(g_sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(g_sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(g_sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(g_sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(g_sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(g_sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(g_sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(g_sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(g_sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(g_sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(g_sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(g_sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(g_sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(g_sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(g_sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(g_sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(g_sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(g_sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(g_sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(g_sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(g_sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(g_sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(g_sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(g_sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(g_sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(g_sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(g_sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(g_sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(g_sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(g_sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(g_sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(g_sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(g_sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(g_sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(g_sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(g_sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(g_sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(g_sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(g_sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(g_sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(g_sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(g_sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(g_sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(g_sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(g_sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(g_sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(g_sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(g_sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(g_sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(g_sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(g_sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(g_sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(g_sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(g_sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(g_sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(g_sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(g_sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(g_sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(g_sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(g_sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(g_sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(g_sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(g_sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(g_sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(g_sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(g_sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(g_sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(g_sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(g_sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(g_sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(g_sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(g_sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(g_sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(g_sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(g_sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(g_sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(g_sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(g_sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(g_sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(g_sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(g_sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(g_sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(g_sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(g_sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(g_sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(g_sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(g_sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(g_sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(g_sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(g_sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(g_sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(g_sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(g_sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(g_sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(g_sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(g_sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(g_sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(g_sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(g_sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(g_sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(g_sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(g_sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(g_sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(g_sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(g_sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(g_sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(g_sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(g_sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(g_sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(g_sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(g_sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(g_sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(g_sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(g_sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(g_sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(g_sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(g_sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(g_sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(g_sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(g_sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(g_sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(g_sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(g_sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(g_sigFromSrams_bore_31_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) g_mode = $urandom_range(0, 15);
      g_io_reset_vector = 48'({$urandom, $urandom});
      g_io_in_bits_s0_pc_0 = 50'({$urandom, $urandom});
      g_io_in_bits_s0_pc_1 = 50'({$urandom, $urandom});
      g_io_in_bits_s0_pc_2 = 50'({$urandom, $urandom});
      g_io_in_bits_s0_pc_3 = 50'({$urandom, $urandom});
      g_io_in_bits_folded_hist_1_hist_17_folded_hist = 11'($urandom);
      g_io_in_bits_folded_hist_1_hist_16_folded_hist = 11'($urandom);
      g_io_in_bits_folded_hist_1_hist_15_folded_hist = 7'($urandom);
      g_io_in_bits_folded_hist_1_hist_14_folded_hist = 8'($urandom);
      g_io_in_bits_folded_hist_1_hist_9_folded_hist = 7'($urandom);
      g_io_in_bits_folded_hist_1_hist_8_folded_hist = 8'($urandom);
      g_io_in_bits_folded_hist_1_hist_7_folded_hist = 7'($urandom);
      g_io_in_bits_folded_hist_1_hist_5_folded_hist = 7'($urandom);
      g_io_in_bits_folded_hist_1_hist_4_folded_hist = 8'($urandom);
      g_io_in_bits_folded_hist_1_hist_3_folded_hist = 8'($urandom);
      g_io_in_bits_folded_hist_1_hist_1_folded_hist = 11'($urandom);
      g_io_in_bits_folded_hist_3_hist_12_folded_hist = 4'($urandom);
      g_io_in_bits_folded_hist_3_hist_11_folded_hist = 8'($urandom);
      g_io_in_bits_folded_hist_3_hist_2_folded_hist = 8'($urandom);
      g_io_in_bits_ghist = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0 = 1'($urandom);
      g_io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1 = 1'($urandom);
      g_io_ctrl_tage_enable = 1'($urandom);
      g_io_ctrl_sc_enable = 1'($urandom);
      g_io_s0_fire_0 = 1'($urandom);
      g_io_s0_fire_1 = 1'($urandom);
      g_io_s0_fire_2 = 1'($urandom);
      g_io_s0_fire_3 = 1'($urandom);
      g_io_s1_fire_0 = 1'($urandom);
      g_io_s1_fire_1 = 1'($urandom);
      g_io_s1_fire_2 = 1'($urandom);
      g_io_s1_fire_3 = 1'($urandom);
      g_io_s2_fire_0 = 1'($urandom);
      g_io_s2_fire_1 = 1'($urandom);
      g_io_s2_fire_2 = 1'($urandom);
      g_io_s2_fire_3 = 1'($urandom);
      g_io_update_valid = 1'($urandom);
      g_io_update_bits_pc = 50'({$urandom, $urandom});
      g_io_update_bits_ftb_entry_brSlots_0_valid = 1'($urandom);
      g_io_update_bits_ftb_entry_tailSlot_sharing = 1'($urandom);
      g_io_update_bits_ftb_entry_tailSlot_valid = 1'($urandom);
      g_io_update_bits_ftb_entry_strong_bias_0 = 1'($urandom);
      g_io_update_bits_ftb_entry_strong_bias_1 = 1'($urandom);
      g_io_update_bits_br_taken_mask_0 = 1'($urandom);
      g_io_update_bits_br_taken_mask_1 = 1'($urandom);
      g_io_update_bits_mispred_mask_0 = 1'($urandom);
      g_io_update_bits_mispred_mask_1 = 1'($urandom);
      g_io_update_bits_meta = 516'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      g_io_update_bits_ghist = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      g_boreChildrenBd_bore_array = 7'($urandom);
      g_boreChildrenBd_bore_all = 1'($urandom);
      g_boreChildrenBd_bore_req = 1'($urandom);
      g_boreChildrenBd_bore_writeen = 1'($urandom);
      g_boreChildrenBd_bore_be = 16'($urandom);
      g_boreChildrenBd_bore_addr = 10'($urandom);
      g_boreChildrenBd_bore_indata = 24'($urandom);
      g_boreChildrenBd_bore_readen = 1'($urandom);
      g_boreChildrenBd_bore_addr_rd = 10'($urandom);
      g_boreChildrenBd_bore_1_array = 7'($urandom);
      g_boreChildrenBd_bore_1_all = 1'($urandom);
      g_boreChildrenBd_bore_1_req = 1'($urandom);
      g_boreChildrenBd_bore_1_writeen = 1'($urandom);
      g_boreChildrenBd_bore_1_be = 4'($urandom);
      g_boreChildrenBd_bore_1_addr = 8'($urandom);
      g_boreChildrenBd_bore_1_indata = 24'($urandom);
      g_boreChildrenBd_bore_1_readen = 1'($urandom);
      g_boreChildrenBd_bore_1_addr_rd = 8'($urandom);
      g_boreChildrenBd_bore_2_array = 7'($urandom);
      g_boreChildrenBd_bore_2_all = 1'($urandom);
      g_boreChildrenBd_bore_2_req = 1'($urandom);
      g_boreChildrenBd_bore_2_writeen = 1'($urandom);
      g_boreChildrenBd_bore_2_be = 4'($urandom);
      g_boreChildrenBd_bore_2_addr = 8'($urandom);
      g_boreChildrenBd_bore_2_indata = 24'($urandom);
      g_boreChildrenBd_bore_2_readen = 1'($urandom);
      g_boreChildrenBd_bore_2_addr_rd = 8'($urandom);
      g_boreChildrenBd_bore_3_array = 7'($urandom);
      g_boreChildrenBd_bore_3_all = 1'($urandom);
      g_boreChildrenBd_bore_3_req = 1'($urandom);
      g_boreChildrenBd_bore_3_writeen = 1'($urandom);
      g_boreChildrenBd_bore_3_be = 4'($urandom);
      g_boreChildrenBd_bore_3_addr = 8'($urandom);
      g_boreChildrenBd_bore_3_indata = 24'($urandom);
      g_boreChildrenBd_bore_3_readen = 1'($urandom);
      g_boreChildrenBd_bore_3_addr_rd = 8'($urandom);
      g_boreChildrenBd_bore_4_array = 7'($urandom);
      g_boreChildrenBd_bore_4_all = 1'($urandom);
      g_boreChildrenBd_bore_4_req = 1'($urandom);
      g_boreChildrenBd_bore_4_writeen = 1'($urandom);
      g_boreChildrenBd_bore_4_be = 4'($urandom);
      g_boreChildrenBd_bore_4_addr = 8'($urandom);
      g_boreChildrenBd_bore_4_indata = 24'($urandom);
      g_boreChildrenBd_bore_4_readen = 1'($urandom);
      g_boreChildrenBd_bore_4_addr_rd = 8'($urandom);
      g_sigFromSrams_bore_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_cgen = 1'($urandom);
      g_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_1_cgen = 1'($urandom);
      g_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_2_cgen = 1'($urandom);
      g_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_3_cgen = 1'($urandom);
      g_sigFromSrams_bore_4_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_4_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_4_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_4_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_4_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_4_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_4_cgen = 1'($urandom);
      g_sigFromSrams_bore_5_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_5_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_5_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_5_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_5_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_5_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_5_cgen = 1'($urandom);
      g_sigFromSrams_bore_6_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_6_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_6_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_6_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_6_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_6_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_6_cgen = 1'($urandom);
      g_sigFromSrams_bore_7_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_7_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_7_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_7_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_7_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_7_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_7_cgen = 1'($urandom);
      g_sigFromSrams_bore_8_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_8_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_8_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_8_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_8_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_8_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_8_cgen = 1'($urandom);
      g_sigFromSrams_bore_9_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_9_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_9_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_9_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_9_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_9_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_9_cgen = 1'($urandom);
      g_sigFromSrams_bore_10_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_10_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_10_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_10_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_10_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_10_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_10_cgen = 1'($urandom);
      g_sigFromSrams_bore_11_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_11_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_11_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_11_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_11_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_11_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_11_cgen = 1'($urandom);
      g_sigFromSrams_bore_12_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_12_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_12_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_12_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_12_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_12_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_12_cgen = 1'($urandom);
      g_sigFromSrams_bore_13_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_13_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_13_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_13_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_13_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_13_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_13_cgen = 1'($urandom);
      g_sigFromSrams_bore_14_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_14_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_14_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_14_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_14_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_14_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_14_cgen = 1'($urandom);
      g_sigFromSrams_bore_15_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_15_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_15_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_15_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_15_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_15_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_15_cgen = 1'($urandom);
      g_sigFromSrams_bore_16_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_16_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_16_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_16_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_16_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_16_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_16_cgen = 1'($urandom);
      g_sigFromSrams_bore_17_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_17_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_17_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_17_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_17_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_17_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_17_cgen = 1'($urandom);
      g_sigFromSrams_bore_18_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_18_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_18_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_18_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_18_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_18_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_18_cgen = 1'($urandom);
      g_sigFromSrams_bore_19_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_19_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_19_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_19_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_19_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_19_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_19_cgen = 1'($urandom);
      g_sigFromSrams_bore_20_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_20_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_20_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_20_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_20_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_20_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_20_cgen = 1'($urandom);
      g_sigFromSrams_bore_21_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_21_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_21_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_21_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_21_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_21_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_21_cgen = 1'($urandom);
      g_sigFromSrams_bore_22_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_22_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_22_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_22_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_22_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_22_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_22_cgen = 1'($urandom);
      g_sigFromSrams_bore_23_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_23_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_23_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_23_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_23_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_23_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_23_cgen = 1'($urandom);
      g_sigFromSrams_bore_24_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_24_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_24_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_24_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_24_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_24_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_24_cgen = 1'($urandom);
      g_sigFromSrams_bore_25_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_25_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_25_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_25_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_25_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_25_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_25_cgen = 1'($urandom);
      g_sigFromSrams_bore_26_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_26_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_26_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_26_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_26_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_26_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_26_cgen = 1'($urandom);
      g_sigFromSrams_bore_27_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_27_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_27_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_27_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_27_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_27_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_27_cgen = 1'($urandom);
      g_sigFromSrams_bore_28_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_28_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_28_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_28_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_28_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_28_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_28_cgen = 1'($urandom);
      g_sigFromSrams_bore_29_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_29_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_29_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_29_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_29_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_29_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_29_cgen = 1'($urandom);
      g_sigFromSrams_bore_30_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_30_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_30_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_30_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_30_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_30_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_30_cgen = 1'($urandom);
      g_sigFromSrams_bore_31_ram_hold = 1'($urandom);
      g_sigFromSrams_bore_31_ram_bypass = 1'($urandom);
      g_sigFromSrams_bore_31_ram_bp_clken = 1'($urandom);
      g_sigFromSrams_bore_31_ram_aux_clk = 1'($urandom);
      g_sigFromSrams_bore_31_ram_aux_ckbp = 1'($urandom);
      g_sigFromSrams_bore_31_ram_mcp_hold = 1'($urandom);
      g_sigFromSrams_bore_31_cgen = 1'($urandom);
      g_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_g
        g_io_in_bits_s0_pc_0 = g_pc_pool[$urandom_range(0, 15)];
        g_io_in_bits_s0_pc_1 = g_pc_pool[$urandom_range(0, 15)];
        g_io_in_bits_s0_pc_2 = g_pc_pool[$urandom_range(0, 15)];
        g_io_in_bits_s0_pc_3 = g_pc_pool[$urandom_range(0, 15)];
        g_io_update_bits_pc = g_pc_pool[$urandom_range(0, 15)];
        g_io_update_valid = ($urandom_range(0, 1) == 0);
        g_io_ctrl_tage_enable = (g_mode != 5);
        g_io_ctrl_sc_enable = (g_mode != 6);
        if (g_mode < 12) begin
          g_io_in_bits_ghist = '0;
          g_io_update_bits_ghist = '0;
          g_io_in_bits_folded_hist_1_hist_17_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_16_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_15_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_14_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_9_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_8_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_7_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_5_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_4_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_3_folded_hist = '0;
          g_io_in_bits_folded_hist_1_hist_1_folded_hist = '0;
          g_io_in_bits_folded_hist_3_hist_12_folded_hist = '0;
          g_io_in_bits_folded_hist_3_hist_11_folded_hist = '0;
          g_io_in_bits_folded_hist_3_hist_2_folded_hist = '0;
        end
        if ($urandom_range(0, 3) != 0) begin
          g_io_update_bits_ftb_entry_brSlots_0_valid = 1'b1;
          g_io_update_bits_ftb_entry_tailSlot_valid = 1'b1;
          g_io_update_bits_ftb_entry_tailSlot_sharing = 1'b1;
          g_io_update_bits_ftb_entry_strong_bias_0 = 1'b0;
          g_io_update_bits_ftb_entry_strong_bias_1 = 1'b0;
          if ($urandom_range(0, 1)) g_io_update_bits_br_taken_mask_0 = 1'b0;
        end
        // meta 偏置：provider 有效、ctr 落在不自信区 3/4 的概率提高；allocates 有时全 0（分配失败，tick 涨）
        if ($urandom_range(0, 1)) g_io_update_bits_meta[133:131] = 3'($urandom_range(3, 4));
        if ($urandom_range(0, 1)) g_io_update_bits_meta[137:135] = 3'($urandom_range(3, 4));
        if (g_mode >= 9 && g_mode <= 11) g_io_update_bits_meta[123:116] = 8'h0;
        if (cyc < 3000) begin
          g_io_update_valid = 1'b1;
          g_io_update_bits_ftb_entry_brSlots_0_valid = 1'b1;
          g_io_update_bits_ftb_entry_tailSlot_valid = 1'b1;
          g_io_update_bits_ftb_entry_tailSlot_sharing = 1'b1;
          g_io_update_bits_ftb_entry_strong_bias_0 = 1'b1;
          g_io_update_bits_ftb_entry_strong_bias_1 = 1'b1;
          g_io_update_bits_meta[140] = 1'b1; g_io_update_bits_meta[143] = 1'b1;
        end
        if (g_mode < 14) begin
          g_boreChildrenBd_bore_all = '0;
          g_boreChildrenBd_bore_req = '0;
          g_boreChildrenBd_bore_1_all = '0;
          g_boreChildrenBd_bore_1_req = '0;
          g_boreChildrenBd_bore_2_all = '0;
          g_boreChildrenBd_bore_2_req = '0;
          g_boreChildrenBd_bore_3_all = '0;
          g_boreChildrenBd_bore_3_req = '0;
          g_boreChildrenBd_bore_4_all = '0;
          g_boreChildrenBd_bore_4_req = '0;
          g_sigFromSrams_bore_ram_hold = '0;
          g_sigFromSrams_bore_ram_bypass = '0;
          g_sigFromSrams_bore_ram_bp_clken = '0;
          g_sigFromSrams_bore_ram_aux_clk = '0;
          g_sigFromSrams_bore_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_ram_mcp_hold = '0;
          g_sigFromSrams_bore_cgen = '0;
          g_sigFromSrams_bore_1_ram_hold = '0;
          g_sigFromSrams_bore_1_ram_bypass = '0;
          g_sigFromSrams_bore_1_ram_bp_clken = '0;
          g_sigFromSrams_bore_1_ram_aux_clk = '0;
          g_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_1_ram_mcp_hold = '0;
          g_sigFromSrams_bore_1_cgen = '0;
          g_sigFromSrams_bore_2_ram_hold = '0;
          g_sigFromSrams_bore_2_ram_bypass = '0;
          g_sigFromSrams_bore_2_ram_bp_clken = '0;
          g_sigFromSrams_bore_2_ram_aux_clk = '0;
          g_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_2_ram_mcp_hold = '0;
          g_sigFromSrams_bore_2_cgen = '0;
          g_sigFromSrams_bore_3_ram_hold = '0;
          g_sigFromSrams_bore_3_ram_bypass = '0;
          g_sigFromSrams_bore_3_ram_bp_clken = '0;
          g_sigFromSrams_bore_3_ram_aux_clk = '0;
          g_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_3_ram_mcp_hold = '0;
          g_sigFromSrams_bore_3_cgen = '0;
          g_sigFromSrams_bore_4_ram_hold = '0;
          g_sigFromSrams_bore_4_ram_bypass = '0;
          g_sigFromSrams_bore_4_ram_bp_clken = '0;
          g_sigFromSrams_bore_4_ram_aux_clk = '0;
          g_sigFromSrams_bore_4_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_4_ram_mcp_hold = '0;
          g_sigFromSrams_bore_4_cgen = '0;
          g_sigFromSrams_bore_5_ram_hold = '0;
          g_sigFromSrams_bore_5_ram_bypass = '0;
          g_sigFromSrams_bore_5_ram_bp_clken = '0;
          g_sigFromSrams_bore_5_ram_aux_clk = '0;
          g_sigFromSrams_bore_5_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_5_ram_mcp_hold = '0;
          g_sigFromSrams_bore_5_cgen = '0;
          g_sigFromSrams_bore_6_ram_hold = '0;
          g_sigFromSrams_bore_6_ram_bypass = '0;
          g_sigFromSrams_bore_6_ram_bp_clken = '0;
          g_sigFromSrams_bore_6_ram_aux_clk = '0;
          g_sigFromSrams_bore_6_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_6_ram_mcp_hold = '0;
          g_sigFromSrams_bore_6_cgen = '0;
          g_sigFromSrams_bore_7_ram_hold = '0;
          g_sigFromSrams_bore_7_ram_bypass = '0;
          g_sigFromSrams_bore_7_ram_bp_clken = '0;
          g_sigFromSrams_bore_7_ram_aux_clk = '0;
          g_sigFromSrams_bore_7_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_7_ram_mcp_hold = '0;
          g_sigFromSrams_bore_7_cgen = '0;
          g_sigFromSrams_bore_8_ram_hold = '0;
          g_sigFromSrams_bore_8_ram_bypass = '0;
          g_sigFromSrams_bore_8_ram_bp_clken = '0;
          g_sigFromSrams_bore_8_ram_aux_clk = '0;
          g_sigFromSrams_bore_8_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_8_ram_mcp_hold = '0;
          g_sigFromSrams_bore_8_cgen = '0;
          g_sigFromSrams_bore_9_ram_hold = '0;
          g_sigFromSrams_bore_9_ram_bypass = '0;
          g_sigFromSrams_bore_9_ram_bp_clken = '0;
          g_sigFromSrams_bore_9_ram_aux_clk = '0;
          g_sigFromSrams_bore_9_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_9_ram_mcp_hold = '0;
          g_sigFromSrams_bore_9_cgen = '0;
          g_sigFromSrams_bore_10_ram_hold = '0;
          g_sigFromSrams_bore_10_ram_bypass = '0;
          g_sigFromSrams_bore_10_ram_bp_clken = '0;
          g_sigFromSrams_bore_10_ram_aux_clk = '0;
          g_sigFromSrams_bore_10_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_10_ram_mcp_hold = '0;
          g_sigFromSrams_bore_10_cgen = '0;
          g_sigFromSrams_bore_11_ram_hold = '0;
          g_sigFromSrams_bore_11_ram_bypass = '0;
          g_sigFromSrams_bore_11_ram_bp_clken = '0;
          g_sigFromSrams_bore_11_ram_aux_clk = '0;
          g_sigFromSrams_bore_11_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_11_ram_mcp_hold = '0;
          g_sigFromSrams_bore_11_cgen = '0;
          g_sigFromSrams_bore_12_ram_hold = '0;
          g_sigFromSrams_bore_12_ram_bypass = '0;
          g_sigFromSrams_bore_12_ram_bp_clken = '0;
          g_sigFromSrams_bore_12_ram_aux_clk = '0;
          g_sigFromSrams_bore_12_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_12_ram_mcp_hold = '0;
          g_sigFromSrams_bore_12_cgen = '0;
          g_sigFromSrams_bore_13_ram_hold = '0;
          g_sigFromSrams_bore_13_ram_bypass = '0;
          g_sigFromSrams_bore_13_ram_bp_clken = '0;
          g_sigFromSrams_bore_13_ram_aux_clk = '0;
          g_sigFromSrams_bore_13_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_13_ram_mcp_hold = '0;
          g_sigFromSrams_bore_13_cgen = '0;
          g_sigFromSrams_bore_14_ram_hold = '0;
          g_sigFromSrams_bore_14_ram_bypass = '0;
          g_sigFromSrams_bore_14_ram_bp_clken = '0;
          g_sigFromSrams_bore_14_ram_aux_clk = '0;
          g_sigFromSrams_bore_14_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_14_ram_mcp_hold = '0;
          g_sigFromSrams_bore_14_cgen = '0;
          g_sigFromSrams_bore_15_ram_hold = '0;
          g_sigFromSrams_bore_15_ram_bypass = '0;
          g_sigFromSrams_bore_15_ram_bp_clken = '0;
          g_sigFromSrams_bore_15_ram_aux_clk = '0;
          g_sigFromSrams_bore_15_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_15_ram_mcp_hold = '0;
          g_sigFromSrams_bore_15_cgen = '0;
          g_sigFromSrams_bore_16_ram_hold = '0;
          g_sigFromSrams_bore_16_ram_bypass = '0;
          g_sigFromSrams_bore_16_ram_bp_clken = '0;
          g_sigFromSrams_bore_16_ram_aux_clk = '0;
          g_sigFromSrams_bore_16_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_16_ram_mcp_hold = '0;
          g_sigFromSrams_bore_16_cgen = '0;
          g_sigFromSrams_bore_17_ram_hold = '0;
          g_sigFromSrams_bore_17_ram_bypass = '0;
          g_sigFromSrams_bore_17_ram_bp_clken = '0;
          g_sigFromSrams_bore_17_ram_aux_clk = '0;
          g_sigFromSrams_bore_17_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_17_ram_mcp_hold = '0;
          g_sigFromSrams_bore_17_cgen = '0;
          g_sigFromSrams_bore_18_ram_hold = '0;
          g_sigFromSrams_bore_18_ram_bypass = '0;
          g_sigFromSrams_bore_18_ram_bp_clken = '0;
          g_sigFromSrams_bore_18_ram_aux_clk = '0;
          g_sigFromSrams_bore_18_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_18_ram_mcp_hold = '0;
          g_sigFromSrams_bore_18_cgen = '0;
          g_sigFromSrams_bore_19_ram_hold = '0;
          g_sigFromSrams_bore_19_ram_bypass = '0;
          g_sigFromSrams_bore_19_ram_bp_clken = '0;
          g_sigFromSrams_bore_19_ram_aux_clk = '0;
          g_sigFromSrams_bore_19_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_19_ram_mcp_hold = '0;
          g_sigFromSrams_bore_19_cgen = '0;
          g_sigFromSrams_bore_20_ram_hold = '0;
          g_sigFromSrams_bore_20_ram_bypass = '0;
          g_sigFromSrams_bore_20_ram_bp_clken = '0;
          g_sigFromSrams_bore_20_ram_aux_clk = '0;
          g_sigFromSrams_bore_20_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_20_ram_mcp_hold = '0;
          g_sigFromSrams_bore_20_cgen = '0;
          g_sigFromSrams_bore_21_ram_hold = '0;
          g_sigFromSrams_bore_21_ram_bypass = '0;
          g_sigFromSrams_bore_21_ram_bp_clken = '0;
          g_sigFromSrams_bore_21_ram_aux_clk = '0;
          g_sigFromSrams_bore_21_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_21_ram_mcp_hold = '0;
          g_sigFromSrams_bore_21_cgen = '0;
          g_sigFromSrams_bore_22_ram_hold = '0;
          g_sigFromSrams_bore_22_ram_bypass = '0;
          g_sigFromSrams_bore_22_ram_bp_clken = '0;
          g_sigFromSrams_bore_22_ram_aux_clk = '0;
          g_sigFromSrams_bore_22_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_22_ram_mcp_hold = '0;
          g_sigFromSrams_bore_22_cgen = '0;
          g_sigFromSrams_bore_23_ram_hold = '0;
          g_sigFromSrams_bore_23_ram_bypass = '0;
          g_sigFromSrams_bore_23_ram_bp_clken = '0;
          g_sigFromSrams_bore_23_ram_aux_clk = '0;
          g_sigFromSrams_bore_23_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_23_ram_mcp_hold = '0;
          g_sigFromSrams_bore_23_cgen = '0;
          g_sigFromSrams_bore_24_ram_hold = '0;
          g_sigFromSrams_bore_24_ram_bypass = '0;
          g_sigFromSrams_bore_24_ram_bp_clken = '0;
          g_sigFromSrams_bore_24_ram_aux_clk = '0;
          g_sigFromSrams_bore_24_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_24_ram_mcp_hold = '0;
          g_sigFromSrams_bore_24_cgen = '0;
          g_sigFromSrams_bore_25_ram_hold = '0;
          g_sigFromSrams_bore_25_ram_bypass = '0;
          g_sigFromSrams_bore_25_ram_bp_clken = '0;
          g_sigFromSrams_bore_25_ram_aux_clk = '0;
          g_sigFromSrams_bore_25_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_25_ram_mcp_hold = '0;
          g_sigFromSrams_bore_25_cgen = '0;
          g_sigFromSrams_bore_26_ram_hold = '0;
          g_sigFromSrams_bore_26_ram_bypass = '0;
          g_sigFromSrams_bore_26_ram_bp_clken = '0;
          g_sigFromSrams_bore_26_ram_aux_clk = '0;
          g_sigFromSrams_bore_26_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_26_ram_mcp_hold = '0;
          g_sigFromSrams_bore_26_cgen = '0;
          g_sigFromSrams_bore_27_ram_hold = '0;
          g_sigFromSrams_bore_27_ram_bypass = '0;
          g_sigFromSrams_bore_27_ram_bp_clken = '0;
          g_sigFromSrams_bore_27_ram_aux_clk = '0;
          g_sigFromSrams_bore_27_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_27_ram_mcp_hold = '0;
          g_sigFromSrams_bore_27_cgen = '0;
          g_sigFromSrams_bore_28_ram_hold = '0;
          g_sigFromSrams_bore_28_ram_bypass = '0;
          g_sigFromSrams_bore_28_ram_bp_clken = '0;
          g_sigFromSrams_bore_28_ram_aux_clk = '0;
          g_sigFromSrams_bore_28_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_28_ram_mcp_hold = '0;
          g_sigFromSrams_bore_28_cgen = '0;
          g_sigFromSrams_bore_29_ram_hold = '0;
          g_sigFromSrams_bore_29_ram_bypass = '0;
          g_sigFromSrams_bore_29_ram_bp_clken = '0;
          g_sigFromSrams_bore_29_ram_aux_clk = '0;
          g_sigFromSrams_bore_29_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_29_ram_mcp_hold = '0;
          g_sigFromSrams_bore_29_cgen = '0;
          g_sigFromSrams_bore_30_ram_hold = '0;
          g_sigFromSrams_bore_30_ram_bypass = '0;
          g_sigFromSrams_bore_30_ram_bp_clken = '0;
          g_sigFromSrams_bore_30_ram_aux_clk = '0;
          g_sigFromSrams_bore_30_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_30_ram_mcp_hold = '0;
          g_sigFromSrams_bore_30_cgen = '0;
          g_sigFromSrams_bore_31_ram_hold = '0;
          g_sigFromSrams_bore_31_ram_bypass = '0;
          g_sigFromSrams_bore_31_ram_bp_clken = '0;
          g_sigFromSrams_bore_31_ram_aux_clk = '0;
          g_sigFromSrams_bore_31_ram_aux_ckbp = '0;
          g_sigFromSrams_bore_31_ram_mcp_hold = '0;
          g_sigFromSrams_bore_31_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && g_armed_at >= 0 && cyc >= g_armed_at) begin
        checks++;
        if (g_g_io_out_s2_full_pred_0_br_taken_mask_0 !== g_i_io_out_s2_full_pred_0_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_0_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_0_br_taken_mask_0, g_i_io_out_s2_full_pred_0_br_taken_mask_0);
        end
        g_s1_io_out_s2_full_pred_0_br_taken_mask_0 |= g_g_io_out_s2_full_pred_0_br_taken_mask_0;
        g_s0_io_out_s2_full_pred_0_br_taken_mask_0 |= ~g_g_io_out_s2_full_pred_0_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s2_full_pred_0_br_taken_mask_1 !== g_i_io_out_s2_full_pred_0_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_0_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_0_br_taken_mask_1, g_i_io_out_s2_full_pred_0_br_taken_mask_1);
        end
        g_s1_io_out_s2_full_pred_0_br_taken_mask_1 |= g_g_io_out_s2_full_pred_0_br_taken_mask_1;
        g_s0_io_out_s2_full_pred_0_br_taken_mask_1 |= ~g_g_io_out_s2_full_pred_0_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s2_full_pred_1_br_taken_mask_0 !== g_i_io_out_s2_full_pred_1_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_1_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_1_br_taken_mask_0, g_i_io_out_s2_full_pred_1_br_taken_mask_0);
        end
        g_s1_io_out_s2_full_pred_1_br_taken_mask_0 |= g_g_io_out_s2_full_pred_1_br_taken_mask_0;
        g_s0_io_out_s2_full_pred_1_br_taken_mask_0 |= ~g_g_io_out_s2_full_pred_1_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s2_full_pred_1_br_taken_mask_1 !== g_i_io_out_s2_full_pred_1_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_1_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_1_br_taken_mask_1, g_i_io_out_s2_full_pred_1_br_taken_mask_1);
        end
        g_s1_io_out_s2_full_pred_1_br_taken_mask_1 |= g_g_io_out_s2_full_pred_1_br_taken_mask_1;
        g_s0_io_out_s2_full_pred_1_br_taken_mask_1 |= ~g_g_io_out_s2_full_pred_1_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s2_full_pred_2_br_taken_mask_0 !== g_i_io_out_s2_full_pred_2_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_2_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_2_br_taken_mask_0, g_i_io_out_s2_full_pred_2_br_taken_mask_0);
        end
        g_s1_io_out_s2_full_pred_2_br_taken_mask_0 |= g_g_io_out_s2_full_pred_2_br_taken_mask_0;
        g_s0_io_out_s2_full_pred_2_br_taken_mask_0 |= ~g_g_io_out_s2_full_pred_2_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s2_full_pred_2_br_taken_mask_1 !== g_i_io_out_s2_full_pred_2_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_2_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_2_br_taken_mask_1, g_i_io_out_s2_full_pred_2_br_taken_mask_1);
        end
        g_s1_io_out_s2_full_pred_2_br_taken_mask_1 |= g_g_io_out_s2_full_pred_2_br_taken_mask_1;
        g_s0_io_out_s2_full_pred_2_br_taken_mask_1 |= ~g_g_io_out_s2_full_pred_2_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s2_full_pred_3_br_taken_mask_0 !== g_i_io_out_s2_full_pred_3_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_3_br_taken_mask_0, g_i_io_out_s2_full_pred_3_br_taken_mask_0);
        end
        g_s1_io_out_s2_full_pred_3_br_taken_mask_0 |= g_g_io_out_s2_full_pred_3_br_taken_mask_0;
        g_s0_io_out_s2_full_pred_3_br_taken_mask_0 |= ~g_g_io_out_s2_full_pred_3_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s2_full_pred_3_br_taken_mask_1 !== g_i_io_out_s2_full_pred_3_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s2_full_pred_3_br_taken_mask_1, g_i_io_out_s2_full_pred_3_br_taken_mask_1);
        end
        g_s1_io_out_s2_full_pred_3_br_taken_mask_1 |= g_g_io_out_s2_full_pred_3_br_taken_mask_1;
        g_s0_io_out_s2_full_pred_3_br_taken_mask_1 |= ~g_g_io_out_s2_full_pred_3_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s3_full_pred_0_br_taken_mask_0 !== g_i_io_out_s3_full_pred_0_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_0_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_0_br_taken_mask_0, g_i_io_out_s3_full_pred_0_br_taken_mask_0);
        end
        g_s1_io_out_s3_full_pred_0_br_taken_mask_0 |= g_g_io_out_s3_full_pred_0_br_taken_mask_0;
        g_s0_io_out_s3_full_pred_0_br_taken_mask_0 |= ~g_g_io_out_s3_full_pred_0_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s3_full_pred_0_br_taken_mask_1 !== g_i_io_out_s3_full_pred_0_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_0_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_0_br_taken_mask_1, g_i_io_out_s3_full_pred_0_br_taken_mask_1);
        end
        g_s1_io_out_s3_full_pred_0_br_taken_mask_1 |= g_g_io_out_s3_full_pred_0_br_taken_mask_1;
        g_s0_io_out_s3_full_pred_0_br_taken_mask_1 |= ~g_g_io_out_s3_full_pred_0_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s3_full_pred_1_br_taken_mask_0 !== g_i_io_out_s3_full_pred_1_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_1_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_1_br_taken_mask_0, g_i_io_out_s3_full_pred_1_br_taken_mask_0);
        end
        g_s1_io_out_s3_full_pred_1_br_taken_mask_0 |= g_g_io_out_s3_full_pred_1_br_taken_mask_0;
        g_s0_io_out_s3_full_pred_1_br_taken_mask_0 |= ~g_g_io_out_s3_full_pred_1_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s3_full_pred_1_br_taken_mask_1 !== g_i_io_out_s3_full_pred_1_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_1_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_1_br_taken_mask_1, g_i_io_out_s3_full_pred_1_br_taken_mask_1);
        end
        g_s1_io_out_s3_full_pred_1_br_taken_mask_1 |= g_g_io_out_s3_full_pred_1_br_taken_mask_1;
        g_s0_io_out_s3_full_pred_1_br_taken_mask_1 |= ~g_g_io_out_s3_full_pred_1_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s3_full_pred_2_br_taken_mask_0 !== g_i_io_out_s3_full_pred_2_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_2_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_2_br_taken_mask_0, g_i_io_out_s3_full_pred_2_br_taken_mask_0);
        end
        g_s1_io_out_s3_full_pred_2_br_taken_mask_0 |= g_g_io_out_s3_full_pred_2_br_taken_mask_0;
        g_s0_io_out_s3_full_pred_2_br_taken_mask_0 |= ~g_g_io_out_s3_full_pred_2_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s3_full_pred_2_br_taken_mask_1 !== g_i_io_out_s3_full_pred_2_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_2_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_2_br_taken_mask_1, g_i_io_out_s3_full_pred_2_br_taken_mask_1);
        end
        g_s1_io_out_s3_full_pred_2_br_taken_mask_1 |= g_g_io_out_s3_full_pred_2_br_taken_mask_1;
        g_s0_io_out_s3_full_pred_2_br_taken_mask_1 |= ~g_g_io_out_s3_full_pred_2_br_taken_mask_1;
        checks++;
        if (g_g_io_out_s3_full_pred_3_br_taken_mask_0 !== g_i_io_out_s3_full_pred_3_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_3_br_taken_mask_0, g_i_io_out_s3_full_pred_3_br_taken_mask_0);
        end
        g_s1_io_out_s3_full_pred_3_br_taken_mask_0 |= g_g_io_out_s3_full_pred_3_br_taken_mask_0;
        g_s0_io_out_s3_full_pred_3_br_taken_mask_0 |= ~g_g_io_out_s3_full_pred_3_br_taken_mask_0;
        checks++;
        if (g_g_io_out_s3_full_pred_3_br_taken_mask_1 !== g_i_io_out_s3_full_pred_3_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", cyc, g_g_io_out_s3_full_pred_3_br_taken_mask_1, g_i_io_out_s3_full_pred_3_br_taken_mask_1);
        end
        g_s1_io_out_s3_full_pred_3_br_taken_mask_1 |= g_g_io_out_s3_full_pred_3_br_taken_mask_1;
        g_s0_io_out_s3_full_pred_3_br_taken_mask_1 |= ~g_g_io_out_s3_full_pred_3_br_taken_mask_1;
        checks++;
        if (g_g_io_out_last_stage_meta !== g_i_io_out_last_stage_meta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_last_stage_meta g=%h i=%h", cyc, g_g_io_out_last_stage_meta, g_i_io_out_last_stage_meta);
        end
        g_s1_io_out_last_stage_meta |= g_g_io_out_last_stage_meta;
        g_s0_io_out_last_stage_meta |= ~g_g_io_out_last_stage_meta;
        checks++;
        if (g_g_io_out_last_stage_spec_info_sc_disagree_0 !== g_i_io_out_last_stage_spec_info_sc_disagree_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_last_stage_spec_info_sc_disagree_0 g=%h i=%h", cyc, g_g_io_out_last_stage_spec_info_sc_disagree_0, g_i_io_out_last_stage_spec_info_sc_disagree_0);
        end
        g_s1_io_out_last_stage_spec_info_sc_disagree_0 |= g_g_io_out_last_stage_spec_info_sc_disagree_0;
        g_s0_io_out_last_stage_spec_info_sc_disagree_0 |= ~g_g_io_out_last_stage_spec_info_sc_disagree_0;
        checks++;
        if (g_g_io_out_last_stage_spec_info_sc_disagree_1 !== g_i_io_out_last_stage_spec_info_sc_disagree_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_out_last_stage_spec_info_sc_disagree_1 g=%h i=%h", cyc, g_g_io_out_last_stage_spec_info_sc_disagree_1, g_i_io_out_last_stage_spec_info_sc_disagree_1);
        end
        g_s1_io_out_last_stage_spec_info_sc_disagree_1 |= g_g_io_out_last_stage_spec_info_sc_disagree_1;
        g_s0_io_out_last_stage_spec_info_sc_disagree_1 |= ~g_g_io_out_last_stage_spec_info_sc_disagree_1;
        checks++;
        if (g_g_io_s1_ready !== g_i_io_s1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_s1_ready g=%h i=%h", cyc, g_g_io_s1_ready, g_i_io_s1_ready);
        end
        g_s1_io_s1_ready |= g_g_io_s1_ready;
        g_s0_io_s1_ready |= ~g_g_io_s1_ready;
        checks++;
        if (g_g_io_perf_0_value !== g_i_io_perf_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_perf_0_value g=%h i=%h", cyc, g_g_io_perf_0_value, g_i_io_perf_0_value);
        end
        g_s1_io_perf_0_value |= g_g_io_perf_0_value;
        g_s0_io_perf_0_value |= ~g_g_io_perf_0_value;
        checks++;
        if (g_g_io_perf_1_value !== g_i_io_perf_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_perf_1_value g=%h i=%h", cyc, g_g_io_perf_1_value, g_i_io_perf_1_value);
        end
        g_s1_io_perf_1_value |= g_g_io_perf_1_value;
        g_s0_io_perf_1_value |= ~g_g_io_perf_1_value;
        checks++;
        if (g_g_io_perf_2_value !== g_i_io_perf_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.io_perf_2_value g=%h i=%h", cyc, g_g_io_perf_2_value, g_i_io_perf_2_value);
        end
        g_s1_io_perf_2_value |= g_g_io_perf_2_value;
        g_s0_io_perf_2_value |= ~g_g_io_perf_2_value;
        checks++;
        if (g_g_boreChildrenBd_bore_ack !== g_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_ack g=%h i=%h", cyc, g_g_boreChildrenBd_bore_ack, g_i_boreChildrenBd_bore_ack);
        end
        g_s1_boreChildrenBd_bore_ack |= g_g_boreChildrenBd_bore_ack;
        g_s0_boreChildrenBd_bore_ack |= ~g_g_boreChildrenBd_bore_ack;
        checks++;
        if (g_g_boreChildrenBd_bore_outdata !== g_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_outdata g=%h i=%h", cyc, g_g_boreChildrenBd_bore_outdata, g_i_boreChildrenBd_bore_outdata);
        end
        g_s1_boreChildrenBd_bore_outdata |= g_g_boreChildrenBd_bore_outdata;
        g_s0_boreChildrenBd_bore_outdata |= ~g_g_boreChildrenBd_bore_outdata;
        checks++;
        if (g_g_boreChildrenBd_bore_1_ack !== g_i_boreChildrenBd_bore_1_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_1_ack g=%h i=%h", cyc, g_g_boreChildrenBd_bore_1_ack, g_i_boreChildrenBd_bore_1_ack);
        end
        g_s1_boreChildrenBd_bore_1_ack |= g_g_boreChildrenBd_bore_1_ack;
        g_s0_boreChildrenBd_bore_1_ack |= ~g_g_boreChildrenBd_bore_1_ack;
        checks++;
        if (g_g_boreChildrenBd_bore_1_outdata !== g_i_boreChildrenBd_bore_1_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_1_outdata g=%h i=%h", cyc, g_g_boreChildrenBd_bore_1_outdata, g_i_boreChildrenBd_bore_1_outdata);
        end
        g_s1_boreChildrenBd_bore_1_outdata |= g_g_boreChildrenBd_bore_1_outdata;
        g_s0_boreChildrenBd_bore_1_outdata |= ~g_g_boreChildrenBd_bore_1_outdata;
        checks++;
        if (g_g_boreChildrenBd_bore_2_ack !== g_i_boreChildrenBd_bore_2_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_2_ack g=%h i=%h", cyc, g_g_boreChildrenBd_bore_2_ack, g_i_boreChildrenBd_bore_2_ack);
        end
        g_s1_boreChildrenBd_bore_2_ack |= g_g_boreChildrenBd_bore_2_ack;
        g_s0_boreChildrenBd_bore_2_ack |= ~g_g_boreChildrenBd_bore_2_ack;
        checks++;
        if (g_g_boreChildrenBd_bore_2_outdata !== g_i_boreChildrenBd_bore_2_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_2_outdata g=%h i=%h", cyc, g_g_boreChildrenBd_bore_2_outdata, g_i_boreChildrenBd_bore_2_outdata);
        end
        g_s1_boreChildrenBd_bore_2_outdata |= g_g_boreChildrenBd_bore_2_outdata;
        g_s0_boreChildrenBd_bore_2_outdata |= ~g_g_boreChildrenBd_bore_2_outdata;
        checks++;
        if (g_g_boreChildrenBd_bore_3_ack !== g_i_boreChildrenBd_bore_3_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_3_ack g=%h i=%h", cyc, g_g_boreChildrenBd_bore_3_ack, g_i_boreChildrenBd_bore_3_ack);
        end
        g_s1_boreChildrenBd_bore_3_ack |= g_g_boreChildrenBd_bore_3_ack;
        g_s0_boreChildrenBd_bore_3_ack |= ~g_g_boreChildrenBd_bore_3_ack;
        checks++;
        if (g_g_boreChildrenBd_bore_3_outdata !== g_i_boreChildrenBd_bore_3_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_3_outdata g=%h i=%h", cyc, g_g_boreChildrenBd_bore_3_outdata, g_i_boreChildrenBd_bore_3_outdata);
        end
        g_s1_boreChildrenBd_bore_3_outdata |= g_g_boreChildrenBd_bore_3_outdata;
        g_s0_boreChildrenBd_bore_3_outdata |= ~g_g_boreChildrenBd_bore_3_outdata;
        checks++;
        if (g_g_boreChildrenBd_bore_4_ack !== g_i_boreChildrenBd_bore_4_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_4_ack g=%h i=%h", cyc, g_g_boreChildrenBd_bore_4_ack, g_i_boreChildrenBd_bore_4_ack);
        end
        g_s1_boreChildrenBd_bore_4_ack |= g_g_boreChildrenBd_bore_4_ack;
        g_s0_boreChildrenBd_bore_4_ack |= ~g_g_boreChildrenBd_bore_4_ack;
        checks++;
        if (g_g_boreChildrenBd_bore_4_outdata !== g_i_boreChildrenBd_bore_4_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Tage_SC.boreChildrenBd_bore_4_outdata g=%h i=%h", cyc, g_g_boreChildrenBd_bore_4_outdata, g_i_boreChildrenBd_bore_4_outdata);
        end
        g_s1_boreChildrenBd_bore_4_outdata |= g_g_boreChildrenBd_bore_4_outdata;
        g_s0_boreChildrenBd_bore_4_outdata |= ~g_g_boreChildrenBd_bore_4_outdata;
        if (g_io_s1_fire_1 && g_u_gold.provided) g_cov_provider_hit++;
        if (g_io_s1_fire_1 && g_u_gold.provided && g_u_gold.s1_altUsed_0) g_cov_alt_used_unconf++;
        if (g_u_gold.updateValids_0 && g_u_gold.updateMeta_r_providers_0_valid && g_u_gold.updateProviderWeak && g_u_gold.updateAltDiffers) g_cov_use_alt_ctr_update++;
        if (g_u_gold.needToAllocate && (|g_u_gold.updateMeta_allocates_0_r)) g_cov_allocate++;
        if (g_u_gold.updateResetU_0_probe || g_u_gold.updateResetU_1_probe) g_cov_tick_reset_u++;
        if (g_io_s2_fire_3 && g_u_gold.s2_provideds_0 && g_u_gold._GEN_81) g_cov_sc_override++;
        if (g_u_gold.scUpdateMask_0_3 || g_u_gold.scUpdateMask_1_3) g_cov_sc_update++;
        if (g_u_gold._baseupdate_0_T_probe || g_u_gold._baseupdate_1_T_probe) g_cov_bt_update++;
      end
      if (g_io_s1_fire_0) g_armed[0] = 1'b1;
      if (g_io_s1_fire_1) g_armed[1] = 1'b1;
      if (g_io_s1_fire_2) g_armed[2] = 1'b1;
      if (g_io_s1_fire_3) g_armed[3] = 1'b1;
      if (g_io_s2_fire_0) g_armed[4] = 1'b1;
      if (g_io_s2_fire_1) g_armed[5] = 1'b1;
      if (g_io_s2_fire_2) g_armed[6] = 1'b1;
      if (g_io_s2_fire_3) g_armed[7] = 1'b1;
      if (cyc > 3000) g_armed[8] = 1'b1;
      if (g_armed_at < 0 && (&g_armed)) g_armed_at = cyc + 1 + 3;
    end

    // ---- 覆盖闸 ----
    if (!(g_s0_io_out_s2_full_pred_0_br_taken_mask_0 && g_s1_io_out_s2_full_pred_0_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_0_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_0_br_taken_mask_1 && g_s1_io_out_s2_full_pred_0_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_0_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_1_br_taken_mask_0 && g_s1_io_out_s2_full_pred_1_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_1_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_1_br_taken_mask_1 && g_s1_io_out_s2_full_pred_1_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_1_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_2_br_taken_mask_0 && g_s1_io_out_s2_full_pred_2_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_2_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_2_br_taken_mask_1 && g_s1_io_out_s2_full_pred_2_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_2_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_3_br_taken_mask_0 && g_s1_io_out_s2_full_pred_3_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_3_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s2_full_pred_3_br_taken_mask_1 && g_s1_io_out_s2_full_pred_3_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s2_full_pred_3_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_0_br_taken_mask_0 && g_s1_io_out_s3_full_pred_0_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_0_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_0_br_taken_mask_1 && g_s1_io_out_s3_full_pred_0_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_0_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_1_br_taken_mask_0 && g_s1_io_out_s3_full_pred_1_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_1_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_1_br_taken_mask_1 && g_s1_io_out_s3_full_pred_1_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_1_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_2_br_taken_mask_0 && g_s1_io_out_s3_full_pred_2_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_2_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_2_br_taken_mask_1 && g_s1_io_out_s3_full_pred_2_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_2_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_3_br_taken_mask_0 && g_s1_io_out_s3_full_pred_3_br_taken_mask_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_3_br_taken_mask_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_s3_full_pred_3_br_taken_mask_1 && g_s1_io_out_s3_full_pred_3_br_taken_mask_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_s3_full_pred_3_br_taken_mask_1 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[0] && g_s1_io_out_last_stage_meta[0])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[0] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[1] && g_s1_io_out_last_stage_meta[1])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[1] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[2] && g_s1_io_out_last_stage_meta[2])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[2] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[3] && g_s1_io_out_last_stage_meta[3])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[3] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[4] && g_s1_io_out_last_stage_meta[4])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[4] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[5] && g_s1_io_out_last_stage_meta[5])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[5] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[6] && g_s1_io_out_last_stage_meta[6])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[6] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[7] && g_s1_io_out_last_stage_meta[7])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[7] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[8] && g_s1_io_out_last_stage_meta[8])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[8] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[9] && g_s1_io_out_last_stage_meta[9])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[9] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[10] && g_s1_io_out_last_stage_meta[10])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[10] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[11] && g_s1_io_out_last_stage_meta[11])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[11] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[12] && g_s1_io_out_last_stage_meta[12])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[12] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[13] && g_s1_io_out_last_stage_meta[13])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[13] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[14] && g_s1_io_out_last_stage_meta[14])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[14] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[15] && g_s1_io_out_last_stage_meta[15])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[15] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[16] && g_s1_io_out_last_stage_meta[16])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[16] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[17] && g_s1_io_out_last_stage_meta[17])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[17] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[66] && g_s1_io_out_last_stage_meta[66])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[66] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[67] && g_s1_io_out_last_stage_meta[67])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[67] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[68] && g_s1_io_out_last_stage_meta[68])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[68] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[69] && g_s1_io_out_last_stage_meta[69])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[69] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[70] && g_s1_io_out_last_stage_meta[70])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[70] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[71] && g_s1_io_out_last_stage_meta[71])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[71] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[72] && g_s1_io_out_last_stage_meta[72])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[72] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[73] && g_s1_io_out_last_stage_meta[73])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[73] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[74] && g_s1_io_out_last_stage_meta[74])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[74] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[75] && g_s1_io_out_last_stage_meta[75])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[75] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[76] && g_s1_io_out_last_stage_meta[76])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[76] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[77] && g_s1_io_out_last_stage_meta[77])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[77] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[78] && g_s1_io_out_last_stage_meta[78])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[78] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[79] && g_s1_io_out_last_stage_meta[79])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[79] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[80] && g_s1_io_out_last_stage_meta[80])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[80] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[81] && g_s1_io_out_last_stage_meta[81])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[81] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[82] && g_s1_io_out_last_stage_meta[82])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[82] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[83] && g_s1_io_out_last_stage_meta[83])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[83] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[84] && g_s1_io_out_last_stage_meta[84])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[84] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[85] && g_s1_io_out_last_stage_meta[85])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[85] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[86] && g_s1_io_out_last_stage_meta[86])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[86] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[87] && g_s1_io_out_last_stage_meta[87])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[87] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[88] && g_s1_io_out_last_stage_meta[88])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[88] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[89] && g_s1_io_out_last_stage_meta[89])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[89] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[90] && g_s1_io_out_last_stage_meta[90])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[90] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[91] && g_s1_io_out_last_stage_meta[91])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[91] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[92] && g_s1_io_out_last_stage_meta[92])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[92] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[93] && g_s1_io_out_last_stage_meta[93])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[93] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[94] && g_s1_io_out_last_stage_meta[94])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[94] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[95] && g_s1_io_out_last_stage_meta[95])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[95] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[96] && g_s1_io_out_last_stage_meta[96])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[96] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[97] && g_s1_io_out_last_stage_meta[97])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[97] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[98] && g_s1_io_out_last_stage_meta[98])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[98] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[99] && g_s1_io_out_last_stage_meta[99])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[99] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[100] && g_s1_io_out_last_stage_meta[100])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[100] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[101] && g_s1_io_out_last_stage_meta[101])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[101] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[102] && g_s1_io_out_last_stage_meta[102])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[102] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[103] && g_s1_io_out_last_stage_meta[103])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[103] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[104] && g_s1_io_out_last_stage_meta[104])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[104] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[105] && g_s1_io_out_last_stage_meta[105])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[105] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[106] && g_s1_io_out_last_stage_meta[106])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[106] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[107] && g_s1_io_out_last_stage_meta[107])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[107] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[108] && g_s1_io_out_last_stage_meta[108])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[108] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[109] && g_s1_io_out_last_stage_meta[109])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[109] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[110] && g_s1_io_out_last_stage_meta[110])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[110] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[111] && g_s1_io_out_last_stage_meta[111])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[111] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[112] && g_s1_io_out_last_stage_meta[112])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[112] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[113] && g_s1_io_out_last_stage_meta[113])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[113] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[114] && g_s1_io_out_last_stage_meta[114])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[114] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[115] && g_s1_io_out_last_stage_meta[115])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[115] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[116] && g_s1_io_out_last_stage_meta[116])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[116] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[117] && g_s1_io_out_last_stage_meta[117])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[117] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[118] && g_s1_io_out_last_stage_meta[118])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[118] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[119] && g_s1_io_out_last_stage_meta[119])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[119] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[120] && g_s1_io_out_last_stage_meta[120])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[120] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[121] && g_s1_io_out_last_stage_meta[121])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[121] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[122] && g_s1_io_out_last_stage_meta[122])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[122] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[123] && g_s1_io_out_last_stage_meta[123])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[123] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[124] && g_s1_io_out_last_stage_meta[124])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[124] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[125] && g_s1_io_out_last_stage_meta[125])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[125] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[126] && g_s1_io_out_last_stage_meta[126])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[126] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[127] && g_s1_io_out_last_stage_meta[127])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[127] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[128] && g_s1_io_out_last_stage_meta[128])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[128] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[129] && g_s1_io_out_last_stage_meta[129])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[129] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[130] && g_s1_io_out_last_stage_meta[130])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[130] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[131] && g_s1_io_out_last_stage_meta[131])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[131] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[132] && g_s1_io_out_last_stage_meta[132])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[132] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[133] && g_s1_io_out_last_stage_meta[133])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[133] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[134] && g_s1_io_out_last_stage_meta[134])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[134] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[135] && g_s1_io_out_last_stage_meta[135])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[135] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[136] && g_s1_io_out_last_stage_meta[136])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[136] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[137] && g_s1_io_out_last_stage_meta[137])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[137] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[138] && g_s1_io_out_last_stage_meta[138])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[138] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[139] && g_s1_io_out_last_stage_meta[139])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[139] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[140] && g_s1_io_out_last_stage_meta[140])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[140] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[141] && g_s1_io_out_last_stage_meta[141])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[141] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[142] && g_s1_io_out_last_stage_meta[142])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[142] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_meta[143] && g_s1_io_out_last_stage_meta[143])) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_meta[143] 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_spec_info_sc_disagree_0 && g_s1_io_out_last_stage_spec_info_sc_disagree_0)) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_spec_info_sc_disagree_0 未见过 0 和 1"); end
    if (!(g_s0_io_out_last_stage_spec_info_sc_disagree_1 && g_s1_io_out_last_stage_spec_info_sc_disagree_1)) begin cov_fail++; $display("[COV] Tage_SC.io_out_last_stage_spec_info_sc_disagree_1 未见过 0 和 1"); end
    if (!(g_s0_io_s1_ready && g_s1_io_s1_ready)) begin cov_fail++; $display("[COV] Tage_SC.io_s1_ready 未见过 0 和 1"); end
    if (!(g_s0_io_perf_0_value[0] && g_s1_io_perf_0_value[0])) begin cov_fail++; $display("[COV] Tage_SC.io_perf_0_value[0] 未见过 0 和 1"); end
    if (!(g_s0_io_perf_0_value[1] && g_s1_io_perf_0_value[1])) begin cov_fail++; $display("[COV] Tage_SC.io_perf_0_value[1] 未见过 0 和 1"); end
    if (!(g_s0_io_perf_1_value[0] && g_s1_io_perf_1_value[0])) begin cov_fail++; $display("[COV] Tage_SC.io_perf_1_value[0] 未见过 0 和 1"); end
    if (!(g_s0_io_perf_1_value[1] && g_s1_io_perf_1_value[1])) begin cov_fail++; $display("[COV] Tage_SC.io_perf_1_value[1] 未见过 0 和 1"); end
    if (!(g_s0_io_perf_2_value[0] && g_s1_io_perf_2_value[0])) begin cov_fail++; $display("[COV] Tage_SC.io_perf_2_value[0] 未见过 0 和 1"); end
    if (!(g_s0_io_perf_2_value[1] && g_s1_io_perf_2_value[1])) begin cov_fail++; $display("[COV] Tage_SC.io_perf_2_value[1] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_ack && g_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[0] && g_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[1] && g_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[2] && g_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[3] && g_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[4] && g_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[5] && g_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[6] && g_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[7] && g_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[8] && g_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[9] && g_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[10] && g_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[11] && g_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[12] && g_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[13] && g_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[14] && g_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[15] && g_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[16] && g_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[17] && g_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[18] && g_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[19] && g_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[20] && g_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[21] && g_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[22] && g_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_outdata[23] && g_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_ack && g_s1_boreChildrenBd_bore_1_ack)) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_ack 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[0] && g_s1_boreChildrenBd_bore_1_outdata[0])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[0] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[1] && g_s1_boreChildrenBd_bore_1_outdata[1])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[1] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[2] && g_s1_boreChildrenBd_bore_1_outdata[2])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[2] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[3] && g_s1_boreChildrenBd_bore_1_outdata[3])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[3] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[4] && g_s1_boreChildrenBd_bore_1_outdata[4])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[4] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[5] && g_s1_boreChildrenBd_bore_1_outdata[5])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[5] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[6] && g_s1_boreChildrenBd_bore_1_outdata[6])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[6] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[7] && g_s1_boreChildrenBd_bore_1_outdata[7])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[7] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[8] && g_s1_boreChildrenBd_bore_1_outdata[8])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[8] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[9] && g_s1_boreChildrenBd_bore_1_outdata[9])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[9] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[10] && g_s1_boreChildrenBd_bore_1_outdata[10])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[10] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[11] && g_s1_boreChildrenBd_bore_1_outdata[11])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[11] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[12] && g_s1_boreChildrenBd_bore_1_outdata[12])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[12] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[13] && g_s1_boreChildrenBd_bore_1_outdata[13])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[13] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[14] && g_s1_boreChildrenBd_bore_1_outdata[14])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[14] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[15] && g_s1_boreChildrenBd_bore_1_outdata[15])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[15] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[16] && g_s1_boreChildrenBd_bore_1_outdata[16])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[16] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[17] && g_s1_boreChildrenBd_bore_1_outdata[17])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[17] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[18] && g_s1_boreChildrenBd_bore_1_outdata[18])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[18] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[19] && g_s1_boreChildrenBd_bore_1_outdata[19])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[19] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[20] && g_s1_boreChildrenBd_bore_1_outdata[20])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[20] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[21] && g_s1_boreChildrenBd_bore_1_outdata[21])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[21] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[22] && g_s1_boreChildrenBd_bore_1_outdata[22])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[22] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_1_outdata[23] && g_s1_boreChildrenBd_bore_1_outdata[23])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_1_outdata[23] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_ack && g_s1_boreChildrenBd_bore_2_ack)) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_ack 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[0] && g_s1_boreChildrenBd_bore_2_outdata[0])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[0] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[1] && g_s1_boreChildrenBd_bore_2_outdata[1])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[1] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[2] && g_s1_boreChildrenBd_bore_2_outdata[2])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[2] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[3] && g_s1_boreChildrenBd_bore_2_outdata[3])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[3] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[4] && g_s1_boreChildrenBd_bore_2_outdata[4])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[4] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[5] && g_s1_boreChildrenBd_bore_2_outdata[5])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[5] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[6] && g_s1_boreChildrenBd_bore_2_outdata[6])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[6] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[7] && g_s1_boreChildrenBd_bore_2_outdata[7])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[7] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[8] && g_s1_boreChildrenBd_bore_2_outdata[8])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[8] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[9] && g_s1_boreChildrenBd_bore_2_outdata[9])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[9] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[10] && g_s1_boreChildrenBd_bore_2_outdata[10])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[10] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[11] && g_s1_boreChildrenBd_bore_2_outdata[11])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[11] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[12] && g_s1_boreChildrenBd_bore_2_outdata[12])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[12] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[13] && g_s1_boreChildrenBd_bore_2_outdata[13])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[13] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[14] && g_s1_boreChildrenBd_bore_2_outdata[14])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[14] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[15] && g_s1_boreChildrenBd_bore_2_outdata[15])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[15] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[16] && g_s1_boreChildrenBd_bore_2_outdata[16])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[16] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[17] && g_s1_boreChildrenBd_bore_2_outdata[17])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[17] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[18] && g_s1_boreChildrenBd_bore_2_outdata[18])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[18] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[19] && g_s1_boreChildrenBd_bore_2_outdata[19])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[19] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[20] && g_s1_boreChildrenBd_bore_2_outdata[20])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[20] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[21] && g_s1_boreChildrenBd_bore_2_outdata[21])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[21] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[22] && g_s1_boreChildrenBd_bore_2_outdata[22])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[22] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_2_outdata[23] && g_s1_boreChildrenBd_bore_2_outdata[23])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_2_outdata[23] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_ack && g_s1_boreChildrenBd_bore_3_ack)) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_ack 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[0] && g_s1_boreChildrenBd_bore_3_outdata[0])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[0] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[1] && g_s1_boreChildrenBd_bore_3_outdata[1])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[1] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[2] && g_s1_boreChildrenBd_bore_3_outdata[2])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[2] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[3] && g_s1_boreChildrenBd_bore_3_outdata[3])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[3] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[4] && g_s1_boreChildrenBd_bore_3_outdata[4])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[4] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[5] && g_s1_boreChildrenBd_bore_3_outdata[5])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[5] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[6] && g_s1_boreChildrenBd_bore_3_outdata[6])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[6] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[7] && g_s1_boreChildrenBd_bore_3_outdata[7])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[7] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[8] && g_s1_boreChildrenBd_bore_3_outdata[8])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[8] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[9] && g_s1_boreChildrenBd_bore_3_outdata[9])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[9] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[10] && g_s1_boreChildrenBd_bore_3_outdata[10])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[10] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[11] && g_s1_boreChildrenBd_bore_3_outdata[11])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[11] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[12] && g_s1_boreChildrenBd_bore_3_outdata[12])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[12] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[13] && g_s1_boreChildrenBd_bore_3_outdata[13])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[13] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[14] && g_s1_boreChildrenBd_bore_3_outdata[14])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[14] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[15] && g_s1_boreChildrenBd_bore_3_outdata[15])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[15] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[16] && g_s1_boreChildrenBd_bore_3_outdata[16])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[16] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[17] && g_s1_boreChildrenBd_bore_3_outdata[17])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[17] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[18] && g_s1_boreChildrenBd_bore_3_outdata[18])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[18] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[19] && g_s1_boreChildrenBd_bore_3_outdata[19])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[19] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[20] && g_s1_boreChildrenBd_bore_3_outdata[20])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[20] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[21] && g_s1_boreChildrenBd_bore_3_outdata[21])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[21] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[22] && g_s1_boreChildrenBd_bore_3_outdata[22])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[22] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_3_outdata[23] && g_s1_boreChildrenBd_bore_3_outdata[23])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_3_outdata[23] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_ack && g_s1_boreChildrenBd_bore_4_ack)) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_ack 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[0] && g_s1_boreChildrenBd_bore_4_outdata[0])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[0] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[1] && g_s1_boreChildrenBd_bore_4_outdata[1])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[1] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[2] && g_s1_boreChildrenBd_bore_4_outdata[2])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[2] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[3] && g_s1_boreChildrenBd_bore_4_outdata[3])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[3] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[4] && g_s1_boreChildrenBd_bore_4_outdata[4])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[4] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[5] && g_s1_boreChildrenBd_bore_4_outdata[5])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[5] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[6] && g_s1_boreChildrenBd_bore_4_outdata[6])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[6] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[7] && g_s1_boreChildrenBd_bore_4_outdata[7])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[7] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[8] && g_s1_boreChildrenBd_bore_4_outdata[8])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[8] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[9] && g_s1_boreChildrenBd_bore_4_outdata[9])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[9] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[10] && g_s1_boreChildrenBd_bore_4_outdata[10])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[10] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[11] && g_s1_boreChildrenBd_bore_4_outdata[11])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[11] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[12] && g_s1_boreChildrenBd_bore_4_outdata[12])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[12] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[13] && g_s1_boreChildrenBd_bore_4_outdata[13])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[13] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[14] && g_s1_boreChildrenBd_bore_4_outdata[14])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[14] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[15] && g_s1_boreChildrenBd_bore_4_outdata[15])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[15] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[16] && g_s1_boreChildrenBd_bore_4_outdata[16])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[16] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[17] && g_s1_boreChildrenBd_bore_4_outdata[17])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[17] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[18] && g_s1_boreChildrenBd_bore_4_outdata[18])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[18] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[19] && g_s1_boreChildrenBd_bore_4_outdata[19])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[19] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[20] && g_s1_boreChildrenBd_bore_4_outdata[20])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[20] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[21] && g_s1_boreChildrenBd_bore_4_outdata[21])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[21] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[22] && g_s1_boreChildrenBd_bore_4_outdata[22])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[22] 未见过 0 和 1"); end
    if (!(g_s0_boreChildrenBd_bore_4_outdata[23] && g_s1_boreChildrenBd_bore_4_outdata[23])) begin cov_fail++; $display("[COV] Tage_SC.boreChildrenBd_bore_4_outdata[23] 未见过 0 和 1"); end
    $display("[ARM] Tage_SC armed_at=%0d", g_armed_at);
    if (g_armed_at < 0) begin cov_fail++; $display("[ARM] Tage_SC 从未 arm"); end
    $display("[COV] Tage_SC.provider_hit = %0d", g_cov_provider_hit);
    if (g_cov_provider_hit < 10) begin cov_fail++; $display("[COV] Tage_SC.provider_hit < 10"); end
    $display("[COV] Tage_SC.alt_used_unconf = %0d", g_cov_alt_used_unconf);
    if (g_cov_alt_used_unconf < 10) begin cov_fail++; $display("[COV] Tage_SC.alt_used_unconf < 10"); end
    $display("[COV] Tage_SC.use_alt_ctr_update = %0d", g_cov_use_alt_ctr_update);
    if (g_cov_use_alt_ctr_update < 10) begin cov_fail++; $display("[COV] Tage_SC.use_alt_ctr_update < 10"); end
    $display("[COV] Tage_SC.allocate = %0d", g_cov_allocate);
    if (g_cov_allocate < 10) begin cov_fail++; $display("[COV] Tage_SC.allocate < 10"); end
    $display("[COV] Tage_SC.tick_reset_u = %0d", g_cov_tick_reset_u);
    if (g_cov_tick_reset_u < 10) begin cov_fail++; $display("[COV] Tage_SC.tick_reset_u < 10"); end
    $display("[COV] Tage_SC.sc_override = %0d", g_cov_sc_override);
    if (g_cov_sc_override < 10) begin cov_fail++; $display("[COV] Tage_SC.sc_override < 10"); end
    $display("[COV] Tage_SC.sc_update = %0d", g_cov_sc_update);
    if (g_cov_sc_update < 10) begin cov_fail++; $display("[COV] Tage_SC.sc_update < 10"); end
    $display("[COV] Tage_SC.bt_update = %0d", g_cov_bt_update);
    if (g_cov_bt_update < 10) begin cov_fail++; $display("[COV] Tage_SC.bt_update < 10"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
