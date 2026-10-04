// 自动生成：verif/ut/RASTop/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// RAS 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= RAS =================
  int unsigned r_mode = 0;
  logic [25:0] r_hi_pool [4];
  logic [11:0] r_mid_pool [4];
  initial for (int i = 0; i < 4; i++) begin r_hi_pool[i] = 26'($urandom); r_mid_pool[i] = 12'($urandom); end
  logic r_reset;
  logic [47:0] r_io_reset_vector;
  logic [49:0] r_io_in_bits_s0_pc_0;
  logic [49:0] r_io_in_bits_s0_pc_1;
  logic [49:0] r_io_in_bits_s0_pc_2;
  logic [49:0] r_io_in_bits_s0_pc_3;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_0_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_0_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_0_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_is_jal;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_is_jalr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_is_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_is_ret;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s2_full_pred_0_hit;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_1_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_1_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_1_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_is_jal;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_is_jalr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_is_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_is_ret;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s2_full_pred_1_hit;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_2_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_2_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_2_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_is_jal;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_is_jalr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_is_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_is_ret;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s2_full_pred_2_hit;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_3_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_3_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_3_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_is_jal;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_is_jalr;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_is_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_is_ret;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s2_full_pred_3_hit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_0_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_0_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_0_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_multiHit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_is_jal;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_is_jalr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_is_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_is_ret;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s3_full_pred_0_hit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_1_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_1_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_1_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_multiHit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_is_jal;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_is_jalr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_is_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_is_ret;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s3_full_pred_1_hit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_2_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_2_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_2_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_multiHit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_is_jal;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_is_jalr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_is_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_is_ret;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s3_full_pred_2_hit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_3_targets_0;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_3_targets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_3_jalr_target;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_0;
  logic [3:0] r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_1;
  logic [49:0] r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_multiHit;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_is_jal;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_is_jalr;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_is_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_is_ret;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing;
  logic r_io_in_bits_resp_in_0_s3_full_pred_3_hit;
  logic r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;
  logic r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_isCall;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_isRet;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_valid;
  logic [3:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid;
  logic [11:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower;
  logic [1:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat;
  logic [3:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid;
  logic [19:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower;
  logic [1:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat;
  logic [3:0] r_io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_carry;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0;
  logic r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1;
  wire  [49:0] r_g_io_out_s2_pc_0, r_i_io_out_s2_pc_0;
  logic [49:0] r_s0_io_out_s2_pc_0 = '0, r_s1_io_out_s2_pc_0 = '0;
  wire  [49:0] r_g_io_out_s2_pc_1, r_i_io_out_s2_pc_1;
  logic [49:0] r_s0_io_out_s2_pc_1 = '0, r_s1_io_out_s2_pc_1 = '0;
  wire  [49:0] r_g_io_out_s2_pc_2, r_i_io_out_s2_pc_2;
  logic [49:0] r_s0_io_out_s2_pc_2 = '0, r_s1_io_out_s2_pc_2 = '0;
  wire  [49:0] r_g_io_out_s2_pc_3, r_i_io_out_s2_pc_3;
  logic [49:0] r_s0_io_out_s2_pc_3 = '0, r_s1_io_out_s2_pc_3 = '0;
  wire  r_g_io_out_s2_full_pred_0_br_taken_mask_0, r_i_io_out_s2_full_pred_0_br_taken_mask_0;
  logic r_s0_io_out_s2_full_pred_0_br_taken_mask_0 = '0, r_s1_io_out_s2_full_pred_0_br_taken_mask_0 = '0;
  wire  r_g_io_out_s2_full_pred_0_br_taken_mask_1, r_i_io_out_s2_full_pred_0_br_taken_mask_1;
  logic r_s0_io_out_s2_full_pred_0_br_taken_mask_1 = '0, r_s1_io_out_s2_full_pred_0_br_taken_mask_1 = '0;
  wire  r_g_io_out_s2_full_pred_0_slot_valids_0, r_i_io_out_s2_full_pred_0_slot_valids_0;
  logic r_s0_io_out_s2_full_pred_0_slot_valids_0 = '0, r_s1_io_out_s2_full_pred_0_slot_valids_0 = '0;
  wire  r_g_io_out_s2_full_pred_0_slot_valids_1, r_i_io_out_s2_full_pred_0_slot_valids_1;
  logic r_s0_io_out_s2_full_pred_0_slot_valids_1 = '0, r_s1_io_out_s2_full_pred_0_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_0_targets_0, r_i_io_out_s2_full_pred_0_targets_0;
  logic [49:0] r_s0_io_out_s2_full_pred_0_targets_0 = '0, r_s1_io_out_s2_full_pred_0_targets_0 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_0_targets_1, r_i_io_out_s2_full_pred_0_targets_1;
  logic [49:0] r_s0_io_out_s2_full_pred_0_targets_1 = '0, r_s1_io_out_s2_full_pred_0_targets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_0_jalr_target, r_i_io_out_s2_full_pred_0_jalr_target;
  logic [49:0] r_s0_io_out_s2_full_pred_0_jalr_target = '0, r_s1_io_out_s2_full_pred_0_jalr_target = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_0_offsets_0, r_i_io_out_s2_full_pred_0_offsets_0;
  logic [3:0] r_s0_io_out_s2_full_pred_0_offsets_0 = '0, r_s1_io_out_s2_full_pred_0_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_0_offsets_1, r_i_io_out_s2_full_pred_0_offsets_1;
  logic [3:0] r_s0_io_out_s2_full_pred_0_offsets_1 = '0, r_s1_io_out_s2_full_pred_0_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_0_fallThroughAddr, r_i_io_out_s2_full_pred_0_fallThroughAddr;
  logic [49:0] r_s0_io_out_s2_full_pred_0_fallThroughAddr = '0, r_s1_io_out_s2_full_pred_0_fallThroughAddr = '0;
  wire  r_g_io_out_s2_full_pred_0_fallThroughErr, r_i_io_out_s2_full_pred_0_fallThroughErr;
  logic r_s0_io_out_s2_full_pred_0_fallThroughErr = '0, r_s1_io_out_s2_full_pred_0_fallThroughErr = '0;
  wire  r_g_io_out_s2_full_pred_0_is_jal, r_i_io_out_s2_full_pred_0_is_jal;
  logic r_s0_io_out_s2_full_pred_0_is_jal = '0, r_s1_io_out_s2_full_pred_0_is_jal = '0;
  wire  r_g_io_out_s2_full_pred_0_is_jalr, r_i_io_out_s2_full_pred_0_is_jalr;
  logic r_s0_io_out_s2_full_pred_0_is_jalr = '0, r_s1_io_out_s2_full_pred_0_is_jalr = '0;
  wire  r_g_io_out_s2_full_pred_0_is_call, r_i_io_out_s2_full_pred_0_is_call;
  logic r_s0_io_out_s2_full_pred_0_is_call = '0, r_s1_io_out_s2_full_pred_0_is_call = '0;
  wire  r_g_io_out_s2_full_pred_0_is_ret, r_i_io_out_s2_full_pred_0_is_ret;
  logic r_s0_io_out_s2_full_pred_0_is_ret = '0, r_s1_io_out_s2_full_pred_0_is_ret = '0;
  wire  r_g_io_out_s2_full_pred_0_last_may_be_rvi_call, r_i_io_out_s2_full_pred_0_last_may_be_rvi_call;
  logic r_s0_io_out_s2_full_pred_0_last_may_be_rvi_call = '0, r_s1_io_out_s2_full_pred_0_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s2_full_pred_0_is_br_sharing, r_i_io_out_s2_full_pred_0_is_br_sharing;
  logic r_s0_io_out_s2_full_pred_0_is_br_sharing = '0, r_s1_io_out_s2_full_pred_0_is_br_sharing = '0;
  wire  r_g_io_out_s2_full_pred_0_hit, r_i_io_out_s2_full_pred_0_hit;
  logic r_s0_io_out_s2_full_pred_0_hit = '0, r_s1_io_out_s2_full_pred_0_hit = '0;
  wire  r_g_io_out_s2_full_pred_1_br_taken_mask_0, r_i_io_out_s2_full_pred_1_br_taken_mask_0;
  logic r_s0_io_out_s2_full_pred_1_br_taken_mask_0 = '0, r_s1_io_out_s2_full_pred_1_br_taken_mask_0 = '0;
  wire  r_g_io_out_s2_full_pred_1_br_taken_mask_1, r_i_io_out_s2_full_pred_1_br_taken_mask_1;
  logic r_s0_io_out_s2_full_pred_1_br_taken_mask_1 = '0, r_s1_io_out_s2_full_pred_1_br_taken_mask_1 = '0;
  wire  r_g_io_out_s2_full_pred_1_slot_valids_0, r_i_io_out_s2_full_pred_1_slot_valids_0;
  logic r_s0_io_out_s2_full_pred_1_slot_valids_0 = '0, r_s1_io_out_s2_full_pred_1_slot_valids_0 = '0;
  wire  r_g_io_out_s2_full_pred_1_slot_valids_1, r_i_io_out_s2_full_pred_1_slot_valids_1;
  logic r_s0_io_out_s2_full_pred_1_slot_valids_1 = '0, r_s1_io_out_s2_full_pred_1_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_1_targets_0, r_i_io_out_s2_full_pred_1_targets_0;
  logic [49:0] r_s0_io_out_s2_full_pred_1_targets_0 = '0, r_s1_io_out_s2_full_pred_1_targets_0 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_1_targets_1, r_i_io_out_s2_full_pred_1_targets_1;
  logic [49:0] r_s0_io_out_s2_full_pred_1_targets_1 = '0, r_s1_io_out_s2_full_pred_1_targets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_1_jalr_target, r_i_io_out_s2_full_pred_1_jalr_target;
  logic [49:0] r_s0_io_out_s2_full_pred_1_jalr_target = '0, r_s1_io_out_s2_full_pred_1_jalr_target = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_1_offsets_0, r_i_io_out_s2_full_pred_1_offsets_0;
  logic [3:0] r_s0_io_out_s2_full_pred_1_offsets_0 = '0, r_s1_io_out_s2_full_pred_1_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_1_offsets_1, r_i_io_out_s2_full_pred_1_offsets_1;
  logic [3:0] r_s0_io_out_s2_full_pred_1_offsets_1 = '0, r_s1_io_out_s2_full_pred_1_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_1_fallThroughAddr, r_i_io_out_s2_full_pred_1_fallThroughAddr;
  logic [49:0] r_s0_io_out_s2_full_pred_1_fallThroughAddr = '0, r_s1_io_out_s2_full_pred_1_fallThroughAddr = '0;
  wire  r_g_io_out_s2_full_pred_1_fallThroughErr, r_i_io_out_s2_full_pred_1_fallThroughErr;
  logic r_s0_io_out_s2_full_pred_1_fallThroughErr = '0, r_s1_io_out_s2_full_pred_1_fallThroughErr = '0;
  wire  r_g_io_out_s2_full_pred_1_is_jal, r_i_io_out_s2_full_pred_1_is_jal;
  logic r_s0_io_out_s2_full_pred_1_is_jal = '0, r_s1_io_out_s2_full_pred_1_is_jal = '0;
  wire  r_g_io_out_s2_full_pred_1_is_jalr, r_i_io_out_s2_full_pred_1_is_jalr;
  logic r_s0_io_out_s2_full_pred_1_is_jalr = '0, r_s1_io_out_s2_full_pred_1_is_jalr = '0;
  wire  r_g_io_out_s2_full_pred_1_is_call, r_i_io_out_s2_full_pred_1_is_call;
  logic r_s0_io_out_s2_full_pred_1_is_call = '0, r_s1_io_out_s2_full_pred_1_is_call = '0;
  wire  r_g_io_out_s2_full_pred_1_is_ret, r_i_io_out_s2_full_pred_1_is_ret;
  logic r_s0_io_out_s2_full_pred_1_is_ret = '0, r_s1_io_out_s2_full_pred_1_is_ret = '0;
  wire  r_g_io_out_s2_full_pred_1_last_may_be_rvi_call, r_i_io_out_s2_full_pred_1_last_may_be_rvi_call;
  logic r_s0_io_out_s2_full_pred_1_last_may_be_rvi_call = '0, r_s1_io_out_s2_full_pred_1_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s2_full_pred_1_is_br_sharing, r_i_io_out_s2_full_pred_1_is_br_sharing;
  logic r_s0_io_out_s2_full_pred_1_is_br_sharing = '0, r_s1_io_out_s2_full_pred_1_is_br_sharing = '0;
  wire  r_g_io_out_s2_full_pred_1_hit, r_i_io_out_s2_full_pred_1_hit;
  logic r_s0_io_out_s2_full_pred_1_hit = '0, r_s1_io_out_s2_full_pred_1_hit = '0;
  wire  r_g_io_out_s2_full_pred_2_br_taken_mask_0, r_i_io_out_s2_full_pred_2_br_taken_mask_0;
  logic r_s0_io_out_s2_full_pred_2_br_taken_mask_0 = '0, r_s1_io_out_s2_full_pred_2_br_taken_mask_0 = '0;
  wire  r_g_io_out_s2_full_pred_2_br_taken_mask_1, r_i_io_out_s2_full_pred_2_br_taken_mask_1;
  logic r_s0_io_out_s2_full_pred_2_br_taken_mask_1 = '0, r_s1_io_out_s2_full_pred_2_br_taken_mask_1 = '0;
  wire  r_g_io_out_s2_full_pred_2_slot_valids_0, r_i_io_out_s2_full_pred_2_slot_valids_0;
  logic r_s0_io_out_s2_full_pred_2_slot_valids_0 = '0, r_s1_io_out_s2_full_pred_2_slot_valids_0 = '0;
  wire  r_g_io_out_s2_full_pred_2_slot_valids_1, r_i_io_out_s2_full_pred_2_slot_valids_1;
  logic r_s0_io_out_s2_full_pred_2_slot_valids_1 = '0, r_s1_io_out_s2_full_pred_2_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_2_targets_0, r_i_io_out_s2_full_pred_2_targets_0;
  logic [49:0] r_s0_io_out_s2_full_pred_2_targets_0 = '0, r_s1_io_out_s2_full_pred_2_targets_0 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_2_targets_1, r_i_io_out_s2_full_pred_2_targets_1;
  logic [49:0] r_s0_io_out_s2_full_pred_2_targets_1 = '0, r_s1_io_out_s2_full_pred_2_targets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_2_jalr_target, r_i_io_out_s2_full_pred_2_jalr_target;
  logic [49:0] r_s0_io_out_s2_full_pred_2_jalr_target = '0, r_s1_io_out_s2_full_pred_2_jalr_target = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_2_offsets_0, r_i_io_out_s2_full_pred_2_offsets_0;
  logic [3:0] r_s0_io_out_s2_full_pred_2_offsets_0 = '0, r_s1_io_out_s2_full_pred_2_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_2_offsets_1, r_i_io_out_s2_full_pred_2_offsets_1;
  logic [3:0] r_s0_io_out_s2_full_pred_2_offsets_1 = '0, r_s1_io_out_s2_full_pred_2_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_2_fallThroughAddr, r_i_io_out_s2_full_pred_2_fallThroughAddr;
  logic [49:0] r_s0_io_out_s2_full_pred_2_fallThroughAddr = '0, r_s1_io_out_s2_full_pred_2_fallThroughAddr = '0;
  wire  r_g_io_out_s2_full_pred_2_fallThroughErr, r_i_io_out_s2_full_pred_2_fallThroughErr;
  logic r_s0_io_out_s2_full_pred_2_fallThroughErr = '0, r_s1_io_out_s2_full_pred_2_fallThroughErr = '0;
  wire  r_g_io_out_s2_full_pred_2_is_jal, r_i_io_out_s2_full_pred_2_is_jal;
  logic r_s0_io_out_s2_full_pred_2_is_jal = '0, r_s1_io_out_s2_full_pred_2_is_jal = '0;
  wire  r_g_io_out_s2_full_pred_2_is_jalr, r_i_io_out_s2_full_pred_2_is_jalr;
  logic r_s0_io_out_s2_full_pred_2_is_jalr = '0, r_s1_io_out_s2_full_pred_2_is_jalr = '0;
  wire  r_g_io_out_s2_full_pred_2_is_call, r_i_io_out_s2_full_pred_2_is_call;
  logic r_s0_io_out_s2_full_pred_2_is_call = '0, r_s1_io_out_s2_full_pred_2_is_call = '0;
  wire  r_g_io_out_s2_full_pred_2_is_ret, r_i_io_out_s2_full_pred_2_is_ret;
  logic r_s0_io_out_s2_full_pred_2_is_ret = '0, r_s1_io_out_s2_full_pred_2_is_ret = '0;
  wire  r_g_io_out_s2_full_pred_2_last_may_be_rvi_call, r_i_io_out_s2_full_pred_2_last_may_be_rvi_call;
  logic r_s0_io_out_s2_full_pred_2_last_may_be_rvi_call = '0, r_s1_io_out_s2_full_pred_2_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s2_full_pred_2_is_br_sharing, r_i_io_out_s2_full_pred_2_is_br_sharing;
  logic r_s0_io_out_s2_full_pred_2_is_br_sharing = '0, r_s1_io_out_s2_full_pred_2_is_br_sharing = '0;
  wire  r_g_io_out_s2_full_pred_2_hit, r_i_io_out_s2_full_pred_2_hit;
  logic r_s0_io_out_s2_full_pred_2_hit = '0, r_s1_io_out_s2_full_pred_2_hit = '0;
  wire  r_g_io_out_s2_full_pred_3_br_taken_mask_0, r_i_io_out_s2_full_pred_3_br_taken_mask_0;
  logic r_s0_io_out_s2_full_pred_3_br_taken_mask_0 = '0, r_s1_io_out_s2_full_pred_3_br_taken_mask_0 = '0;
  wire  r_g_io_out_s2_full_pred_3_br_taken_mask_1, r_i_io_out_s2_full_pred_3_br_taken_mask_1;
  logic r_s0_io_out_s2_full_pred_3_br_taken_mask_1 = '0, r_s1_io_out_s2_full_pred_3_br_taken_mask_1 = '0;
  wire  r_g_io_out_s2_full_pred_3_slot_valids_0, r_i_io_out_s2_full_pred_3_slot_valids_0;
  logic r_s0_io_out_s2_full_pred_3_slot_valids_0 = '0, r_s1_io_out_s2_full_pred_3_slot_valids_0 = '0;
  wire  r_g_io_out_s2_full_pred_3_slot_valids_1, r_i_io_out_s2_full_pred_3_slot_valids_1;
  logic r_s0_io_out_s2_full_pred_3_slot_valids_1 = '0, r_s1_io_out_s2_full_pred_3_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_3_targets_0, r_i_io_out_s2_full_pred_3_targets_0;
  logic [49:0] r_s0_io_out_s2_full_pred_3_targets_0 = '0, r_s1_io_out_s2_full_pred_3_targets_0 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_3_targets_1, r_i_io_out_s2_full_pred_3_targets_1;
  logic [49:0] r_s0_io_out_s2_full_pred_3_targets_1 = '0, r_s1_io_out_s2_full_pred_3_targets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_3_jalr_target, r_i_io_out_s2_full_pred_3_jalr_target;
  logic [49:0] r_s0_io_out_s2_full_pred_3_jalr_target = '0, r_s1_io_out_s2_full_pred_3_jalr_target = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_3_offsets_0, r_i_io_out_s2_full_pred_3_offsets_0;
  logic [3:0] r_s0_io_out_s2_full_pred_3_offsets_0 = '0, r_s1_io_out_s2_full_pred_3_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s2_full_pred_3_offsets_1, r_i_io_out_s2_full_pred_3_offsets_1;
  logic [3:0] r_s0_io_out_s2_full_pred_3_offsets_1 = '0, r_s1_io_out_s2_full_pred_3_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s2_full_pred_3_fallThroughAddr, r_i_io_out_s2_full_pred_3_fallThroughAddr;
  logic [49:0] r_s0_io_out_s2_full_pred_3_fallThroughAddr = '0, r_s1_io_out_s2_full_pred_3_fallThroughAddr = '0;
  wire  r_g_io_out_s2_full_pred_3_fallThroughErr, r_i_io_out_s2_full_pred_3_fallThroughErr;
  logic r_s0_io_out_s2_full_pred_3_fallThroughErr = '0, r_s1_io_out_s2_full_pred_3_fallThroughErr = '0;
  wire  r_g_io_out_s2_full_pred_3_is_jal, r_i_io_out_s2_full_pred_3_is_jal;
  logic r_s0_io_out_s2_full_pred_3_is_jal = '0, r_s1_io_out_s2_full_pred_3_is_jal = '0;
  wire  r_g_io_out_s2_full_pred_3_is_jalr, r_i_io_out_s2_full_pred_3_is_jalr;
  logic r_s0_io_out_s2_full_pred_3_is_jalr = '0, r_s1_io_out_s2_full_pred_3_is_jalr = '0;
  wire  r_g_io_out_s2_full_pred_3_is_call, r_i_io_out_s2_full_pred_3_is_call;
  logic r_s0_io_out_s2_full_pred_3_is_call = '0, r_s1_io_out_s2_full_pred_3_is_call = '0;
  wire  r_g_io_out_s2_full_pred_3_is_ret, r_i_io_out_s2_full_pred_3_is_ret;
  logic r_s0_io_out_s2_full_pred_3_is_ret = '0, r_s1_io_out_s2_full_pred_3_is_ret = '0;
  wire  r_g_io_out_s2_full_pred_3_last_may_be_rvi_call, r_i_io_out_s2_full_pred_3_last_may_be_rvi_call;
  logic r_s0_io_out_s2_full_pred_3_last_may_be_rvi_call = '0, r_s1_io_out_s2_full_pred_3_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s2_full_pred_3_is_br_sharing, r_i_io_out_s2_full_pred_3_is_br_sharing;
  logic r_s0_io_out_s2_full_pred_3_is_br_sharing = '0, r_s1_io_out_s2_full_pred_3_is_br_sharing = '0;
  wire  r_g_io_out_s2_full_pred_3_hit, r_i_io_out_s2_full_pred_3_hit;
  logic r_s0_io_out_s2_full_pred_3_hit = '0, r_s1_io_out_s2_full_pred_3_hit = '0;
  wire  [49:0] r_g_io_out_s3_pc_0, r_i_io_out_s3_pc_0;
  logic [49:0] r_s0_io_out_s3_pc_0 = '0, r_s1_io_out_s3_pc_0 = '0;
  wire  [49:0] r_g_io_out_s3_pc_1, r_i_io_out_s3_pc_1;
  logic [49:0] r_s0_io_out_s3_pc_1 = '0, r_s1_io_out_s3_pc_1 = '0;
  wire  [49:0] r_g_io_out_s3_pc_2, r_i_io_out_s3_pc_2;
  logic [49:0] r_s0_io_out_s3_pc_2 = '0, r_s1_io_out_s3_pc_2 = '0;
  wire  [49:0] r_g_io_out_s3_pc_3, r_i_io_out_s3_pc_3;
  logic [49:0] r_s0_io_out_s3_pc_3 = '0, r_s1_io_out_s3_pc_3 = '0;
  wire  r_g_io_out_s3_full_pred_0_br_taken_mask_0, r_i_io_out_s3_full_pred_0_br_taken_mask_0;
  logic r_s0_io_out_s3_full_pred_0_br_taken_mask_0 = '0, r_s1_io_out_s3_full_pred_0_br_taken_mask_0 = '0;
  wire  r_g_io_out_s3_full_pred_0_br_taken_mask_1, r_i_io_out_s3_full_pred_0_br_taken_mask_1;
  logic r_s0_io_out_s3_full_pred_0_br_taken_mask_1 = '0, r_s1_io_out_s3_full_pred_0_br_taken_mask_1 = '0;
  wire  r_g_io_out_s3_full_pred_0_slot_valids_0, r_i_io_out_s3_full_pred_0_slot_valids_0;
  logic r_s0_io_out_s3_full_pred_0_slot_valids_0 = '0, r_s1_io_out_s3_full_pred_0_slot_valids_0 = '0;
  wire  r_g_io_out_s3_full_pred_0_slot_valids_1, r_i_io_out_s3_full_pred_0_slot_valids_1;
  logic r_s0_io_out_s3_full_pred_0_slot_valids_1 = '0, r_s1_io_out_s3_full_pred_0_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_0_targets_0, r_i_io_out_s3_full_pred_0_targets_0;
  logic [49:0] r_s0_io_out_s3_full_pred_0_targets_0 = '0, r_s1_io_out_s3_full_pred_0_targets_0 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_0_targets_1, r_i_io_out_s3_full_pred_0_targets_1;
  logic [49:0] r_s0_io_out_s3_full_pred_0_targets_1 = '0, r_s1_io_out_s3_full_pred_0_targets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_0_jalr_target, r_i_io_out_s3_full_pred_0_jalr_target;
  logic [49:0] r_s0_io_out_s3_full_pred_0_jalr_target = '0, r_s1_io_out_s3_full_pred_0_jalr_target = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_0_offsets_0, r_i_io_out_s3_full_pred_0_offsets_0;
  logic [3:0] r_s0_io_out_s3_full_pred_0_offsets_0 = '0, r_s1_io_out_s3_full_pred_0_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_0_offsets_1, r_i_io_out_s3_full_pred_0_offsets_1;
  logic [3:0] r_s0_io_out_s3_full_pred_0_offsets_1 = '0, r_s1_io_out_s3_full_pred_0_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_0_fallThroughAddr, r_i_io_out_s3_full_pred_0_fallThroughAddr;
  logic [49:0] r_s0_io_out_s3_full_pred_0_fallThroughAddr = '0, r_s1_io_out_s3_full_pred_0_fallThroughAddr = '0;
  wire  r_g_io_out_s3_full_pred_0_fallThroughErr, r_i_io_out_s3_full_pred_0_fallThroughErr;
  logic r_s0_io_out_s3_full_pred_0_fallThroughErr = '0, r_s1_io_out_s3_full_pred_0_fallThroughErr = '0;
  wire  r_g_io_out_s3_full_pred_0_multiHit, r_i_io_out_s3_full_pred_0_multiHit;
  logic r_s0_io_out_s3_full_pred_0_multiHit = '0, r_s1_io_out_s3_full_pred_0_multiHit = '0;
  wire  r_g_io_out_s3_full_pred_0_is_jal, r_i_io_out_s3_full_pred_0_is_jal;
  logic r_s0_io_out_s3_full_pred_0_is_jal = '0, r_s1_io_out_s3_full_pred_0_is_jal = '0;
  wire  r_g_io_out_s3_full_pred_0_is_jalr, r_i_io_out_s3_full_pred_0_is_jalr;
  logic r_s0_io_out_s3_full_pred_0_is_jalr = '0, r_s1_io_out_s3_full_pred_0_is_jalr = '0;
  wire  r_g_io_out_s3_full_pred_0_is_call, r_i_io_out_s3_full_pred_0_is_call;
  logic r_s0_io_out_s3_full_pred_0_is_call = '0, r_s1_io_out_s3_full_pred_0_is_call = '0;
  wire  r_g_io_out_s3_full_pred_0_is_ret, r_i_io_out_s3_full_pred_0_is_ret;
  logic r_s0_io_out_s3_full_pred_0_is_ret = '0, r_s1_io_out_s3_full_pred_0_is_ret = '0;
  wire  r_g_io_out_s3_full_pred_0_last_may_be_rvi_call, r_i_io_out_s3_full_pred_0_last_may_be_rvi_call;
  logic r_s0_io_out_s3_full_pred_0_last_may_be_rvi_call = '0, r_s1_io_out_s3_full_pred_0_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s3_full_pred_0_is_br_sharing, r_i_io_out_s3_full_pred_0_is_br_sharing;
  logic r_s0_io_out_s3_full_pred_0_is_br_sharing = '0, r_s1_io_out_s3_full_pred_0_is_br_sharing = '0;
  wire  r_g_io_out_s3_full_pred_0_hit, r_i_io_out_s3_full_pred_0_hit;
  logic r_s0_io_out_s3_full_pred_0_hit = '0, r_s1_io_out_s3_full_pred_0_hit = '0;
  wire  r_g_io_out_s3_full_pred_1_br_taken_mask_0, r_i_io_out_s3_full_pred_1_br_taken_mask_0;
  logic r_s0_io_out_s3_full_pred_1_br_taken_mask_0 = '0, r_s1_io_out_s3_full_pred_1_br_taken_mask_0 = '0;
  wire  r_g_io_out_s3_full_pred_1_br_taken_mask_1, r_i_io_out_s3_full_pred_1_br_taken_mask_1;
  logic r_s0_io_out_s3_full_pred_1_br_taken_mask_1 = '0, r_s1_io_out_s3_full_pred_1_br_taken_mask_1 = '0;
  wire  r_g_io_out_s3_full_pred_1_slot_valids_0, r_i_io_out_s3_full_pred_1_slot_valids_0;
  logic r_s0_io_out_s3_full_pred_1_slot_valids_0 = '0, r_s1_io_out_s3_full_pred_1_slot_valids_0 = '0;
  wire  r_g_io_out_s3_full_pred_1_slot_valids_1, r_i_io_out_s3_full_pred_1_slot_valids_1;
  logic r_s0_io_out_s3_full_pred_1_slot_valids_1 = '0, r_s1_io_out_s3_full_pred_1_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_1_targets_0, r_i_io_out_s3_full_pred_1_targets_0;
  logic [49:0] r_s0_io_out_s3_full_pred_1_targets_0 = '0, r_s1_io_out_s3_full_pred_1_targets_0 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_1_targets_1, r_i_io_out_s3_full_pred_1_targets_1;
  logic [49:0] r_s0_io_out_s3_full_pred_1_targets_1 = '0, r_s1_io_out_s3_full_pred_1_targets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_1_jalr_target, r_i_io_out_s3_full_pred_1_jalr_target;
  logic [49:0] r_s0_io_out_s3_full_pred_1_jalr_target = '0, r_s1_io_out_s3_full_pred_1_jalr_target = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_1_offsets_0, r_i_io_out_s3_full_pred_1_offsets_0;
  logic [3:0] r_s0_io_out_s3_full_pred_1_offsets_0 = '0, r_s1_io_out_s3_full_pred_1_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_1_offsets_1, r_i_io_out_s3_full_pred_1_offsets_1;
  logic [3:0] r_s0_io_out_s3_full_pred_1_offsets_1 = '0, r_s1_io_out_s3_full_pred_1_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_1_fallThroughAddr, r_i_io_out_s3_full_pred_1_fallThroughAddr;
  logic [49:0] r_s0_io_out_s3_full_pred_1_fallThroughAddr = '0, r_s1_io_out_s3_full_pred_1_fallThroughAddr = '0;
  wire  r_g_io_out_s3_full_pred_1_fallThroughErr, r_i_io_out_s3_full_pred_1_fallThroughErr;
  logic r_s0_io_out_s3_full_pred_1_fallThroughErr = '0, r_s1_io_out_s3_full_pred_1_fallThroughErr = '0;
  wire  r_g_io_out_s3_full_pred_1_multiHit, r_i_io_out_s3_full_pred_1_multiHit;
  logic r_s0_io_out_s3_full_pred_1_multiHit = '0, r_s1_io_out_s3_full_pred_1_multiHit = '0;
  wire  r_g_io_out_s3_full_pred_1_is_jal, r_i_io_out_s3_full_pred_1_is_jal;
  logic r_s0_io_out_s3_full_pred_1_is_jal = '0, r_s1_io_out_s3_full_pred_1_is_jal = '0;
  wire  r_g_io_out_s3_full_pred_1_is_jalr, r_i_io_out_s3_full_pred_1_is_jalr;
  logic r_s0_io_out_s3_full_pred_1_is_jalr = '0, r_s1_io_out_s3_full_pred_1_is_jalr = '0;
  wire  r_g_io_out_s3_full_pred_1_is_call, r_i_io_out_s3_full_pred_1_is_call;
  logic r_s0_io_out_s3_full_pred_1_is_call = '0, r_s1_io_out_s3_full_pred_1_is_call = '0;
  wire  r_g_io_out_s3_full_pred_1_is_ret, r_i_io_out_s3_full_pred_1_is_ret;
  logic r_s0_io_out_s3_full_pred_1_is_ret = '0, r_s1_io_out_s3_full_pred_1_is_ret = '0;
  wire  r_g_io_out_s3_full_pred_1_last_may_be_rvi_call, r_i_io_out_s3_full_pred_1_last_may_be_rvi_call;
  logic r_s0_io_out_s3_full_pred_1_last_may_be_rvi_call = '0, r_s1_io_out_s3_full_pred_1_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s3_full_pred_1_is_br_sharing, r_i_io_out_s3_full_pred_1_is_br_sharing;
  logic r_s0_io_out_s3_full_pred_1_is_br_sharing = '0, r_s1_io_out_s3_full_pred_1_is_br_sharing = '0;
  wire  r_g_io_out_s3_full_pred_1_hit, r_i_io_out_s3_full_pred_1_hit;
  logic r_s0_io_out_s3_full_pred_1_hit = '0, r_s1_io_out_s3_full_pred_1_hit = '0;
  wire  r_g_io_out_s3_full_pred_2_br_taken_mask_0, r_i_io_out_s3_full_pred_2_br_taken_mask_0;
  logic r_s0_io_out_s3_full_pred_2_br_taken_mask_0 = '0, r_s1_io_out_s3_full_pred_2_br_taken_mask_0 = '0;
  wire  r_g_io_out_s3_full_pred_2_br_taken_mask_1, r_i_io_out_s3_full_pred_2_br_taken_mask_1;
  logic r_s0_io_out_s3_full_pred_2_br_taken_mask_1 = '0, r_s1_io_out_s3_full_pred_2_br_taken_mask_1 = '0;
  wire  r_g_io_out_s3_full_pred_2_slot_valids_0, r_i_io_out_s3_full_pred_2_slot_valids_0;
  logic r_s0_io_out_s3_full_pred_2_slot_valids_0 = '0, r_s1_io_out_s3_full_pred_2_slot_valids_0 = '0;
  wire  r_g_io_out_s3_full_pred_2_slot_valids_1, r_i_io_out_s3_full_pred_2_slot_valids_1;
  logic r_s0_io_out_s3_full_pred_2_slot_valids_1 = '0, r_s1_io_out_s3_full_pred_2_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_2_targets_0, r_i_io_out_s3_full_pred_2_targets_0;
  logic [49:0] r_s0_io_out_s3_full_pred_2_targets_0 = '0, r_s1_io_out_s3_full_pred_2_targets_0 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_2_targets_1, r_i_io_out_s3_full_pred_2_targets_1;
  logic [49:0] r_s0_io_out_s3_full_pred_2_targets_1 = '0, r_s1_io_out_s3_full_pred_2_targets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_2_jalr_target, r_i_io_out_s3_full_pred_2_jalr_target;
  logic [49:0] r_s0_io_out_s3_full_pred_2_jalr_target = '0, r_s1_io_out_s3_full_pred_2_jalr_target = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_2_offsets_0, r_i_io_out_s3_full_pred_2_offsets_0;
  logic [3:0] r_s0_io_out_s3_full_pred_2_offsets_0 = '0, r_s1_io_out_s3_full_pred_2_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_2_offsets_1, r_i_io_out_s3_full_pred_2_offsets_1;
  logic [3:0] r_s0_io_out_s3_full_pred_2_offsets_1 = '0, r_s1_io_out_s3_full_pred_2_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_2_fallThroughAddr, r_i_io_out_s3_full_pred_2_fallThroughAddr;
  logic [49:0] r_s0_io_out_s3_full_pred_2_fallThroughAddr = '0, r_s1_io_out_s3_full_pred_2_fallThroughAddr = '0;
  wire  r_g_io_out_s3_full_pred_2_fallThroughErr, r_i_io_out_s3_full_pred_2_fallThroughErr;
  logic r_s0_io_out_s3_full_pred_2_fallThroughErr = '0, r_s1_io_out_s3_full_pred_2_fallThroughErr = '0;
  wire  r_g_io_out_s3_full_pred_2_multiHit, r_i_io_out_s3_full_pred_2_multiHit;
  logic r_s0_io_out_s3_full_pred_2_multiHit = '0, r_s1_io_out_s3_full_pred_2_multiHit = '0;
  wire  r_g_io_out_s3_full_pred_2_is_jal, r_i_io_out_s3_full_pred_2_is_jal;
  logic r_s0_io_out_s3_full_pred_2_is_jal = '0, r_s1_io_out_s3_full_pred_2_is_jal = '0;
  wire  r_g_io_out_s3_full_pred_2_is_jalr, r_i_io_out_s3_full_pred_2_is_jalr;
  logic r_s0_io_out_s3_full_pred_2_is_jalr = '0, r_s1_io_out_s3_full_pred_2_is_jalr = '0;
  wire  r_g_io_out_s3_full_pred_2_is_call, r_i_io_out_s3_full_pred_2_is_call;
  logic r_s0_io_out_s3_full_pred_2_is_call = '0, r_s1_io_out_s3_full_pred_2_is_call = '0;
  wire  r_g_io_out_s3_full_pred_2_is_ret, r_i_io_out_s3_full_pred_2_is_ret;
  logic r_s0_io_out_s3_full_pred_2_is_ret = '0, r_s1_io_out_s3_full_pred_2_is_ret = '0;
  wire  r_g_io_out_s3_full_pred_2_last_may_be_rvi_call, r_i_io_out_s3_full_pred_2_last_may_be_rvi_call;
  logic r_s0_io_out_s3_full_pred_2_last_may_be_rvi_call = '0, r_s1_io_out_s3_full_pred_2_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s3_full_pred_2_is_br_sharing, r_i_io_out_s3_full_pred_2_is_br_sharing;
  logic r_s0_io_out_s3_full_pred_2_is_br_sharing = '0, r_s1_io_out_s3_full_pred_2_is_br_sharing = '0;
  wire  r_g_io_out_s3_full_pred_2_hit, r_i_io_out_s3_full_pred_2_hit;
  logic r_s0_io_out_s3_full_pred_2_hit = '0, r_s1_io_out_s3_full_pred_2_hit = '0;
  wire  r_g_io_out_s3_full_pred_3_br_taken_mask_0, r_i_io_out_s3_full_pred_3_br_taken_mask_0;
  logic r_s0_io_out_s3_full_pred_3_br_taken_mask_0 = '0, r_s1_io_out_s3_full_pred_3_br_taken_mask_0 = '0;
  wire  r_g_io_out_s3_full_pred_3_br_taken_mask_1, r_i_io_out_s3_full_pred_3_br_taken_mask_1;
  logic r_s0_io_out_s3_full_pred_3_br_taken_mask_1 = '0, r_s1_io_out_s3_full_pred_3_br_taken_mask_1 = '0;
  wire  r_g_io_out_s3_full_pred_3_slot_valids_0, r_i_io_out_s3_full_pred_3_slot_valids_0;
  logic r_s0_io_out_s3_full_pred_3_slot_valids_0 = '0, r_s1_io_out_s3_full_pred_3_slot_valids_0 = '0;
  wire  r_g_io_out_s3_full_pred_3_slot_valids_1, r_i_io_out_s3_full_pred_3_slot_valids_1;
  logic r_s0_io_out_s3_full_pred_3_slot_valids_1 = '0, r_s1_io_out_s3_full_pred_3_slot_valids_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_3_targets_0, r_i_io_out_s3_full_pred_3_targets_0;
  logic [49:0] r_s0_io_out_s3_full_pred_3_targets_0 = '0, r_s1_io_out_s3_full_pred_3_targets_0 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_3_targets_1, r_i_io_out_s3_full_pred_3_targets_1;
  logic [49:0] r_s0_io_out_s3_full_pred_3_targets_1 = '0, r_s1_io_out_s3_full_pred_3_targets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_3_jalr_target, r_i_io_out_s3_full_pred_3_jalr_target;
  logic [49:0] r_s0_io_out_s3_full_pred_3_jalr_target = '0, r_s1_io_out_s3_full_pred_3_jalr_target = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_3_offsets_0, r_i_io_out_s3_full_pred_3_offsets_0;
  logic [3:0] r_s0_io_out_s3_full_pred_3_offsets_0 = '0, r_s1_io_out_s3_full_pred_3_offsets_0 = '0;
  wire  [3:0] r_g_io_out_s3_full_pred_3_offsets_1, r_i_io_out_s3_full_pred_3_offsets_1;
  logic [3:0] r_s0_io_out_s3_full_pred_3_offsets_1 = '0, r_s1_io_out_s3_full_pred_3_offsets_1 = '0;
  wire  [49:0] r_g_io_out_s3_full_pred_3_fallThroughAddr, r_i_io_out_s3_full_pred_3_fallThroughAddr;
  logic [49:0] r_s0_io_out_s3_full_pred_3_fallThroughAddr = '0, r_s1_io_out_s3_full_pred_3_fallThroughAddr = '0;
  wire  r_g_io_out_s3_full_pred_3_fallThroughErr, r_i_io_out_s3_full_pred_3_fallThroughErr;
  logic r_s0_io_out_s3_full_pred_3_fallThroughErr = '0, r_s1_io_out_s3_full_pred_3_fallThroughErr = '0;
  wire  r_g_io_out_s3_full_pred_3_multiHit, r_i_io_out_s3_full_pred_3_multiHit;
  logic r_s0_io_out_s3_full_pred_3_multiHit = '0, r_s1_io_out_s3_full_pred_3_multiHit = '0;
  wire  r_g_io_out_s3_full_pred_3_is_jal, r_i_io_out_s3_full_pred_3_is_jal;
  logic r_s0_io_out_s3_full_pred_3_is_jal = '0, r_s1_io_out_s3_full_pred_3_is_jal = '0;
  wire  r_g_io_out_s3_full_pred_3_is_jalr, r_i_io_out_s3_full_pred_3_is_jalr;
  logic r_s0_io_out_s3_full_pred_3_is_jalr = '0, r_s1_io_out_s3_full_pred_3_is_jalr = '0;
  wire  r_g_io_out_s3_full_pred_3_is_call, r_i_io_out_s3_full_pred_3_is_call;
  logic r_s0_io_out_s3_full_pred_3_is_call = '0, r_s1_io_out_s3_full_pred_3_is_call = '0;
  wire  r_g_io_out_s3_full_pred_3_is_ret, r_i_io_out_s3_full_pred_3_is_ret;
  logic r_s0_io_out_s3_full_pred_3_is_ret = '0, r_s1_io_out_s3_full_pred_3_is_ret = '0;
  wire  r_g_io_out_s3_full_pred_3_last_may_be_rvi_call, r_i_io_out_s3_full_pred_3_last_may_be_rvi_call;
  logic r_s0_io_out_s3_full_pred_3_last_may_be_rvi_call = '0, r_s1_io_out_s3_full_pred_3_last_may_be_rvi_call = '0;
  wire  r_g_io_out_s3_full_pred_3_is_br_sharing, r_i_io_out_s3_full_pred_3_is_br_sharing;
  logic r_s0_io_out_s3_full_pred_3_is_br_sharing = '0, r_s1_io_out_s3_full_pred_3_is_br_sharing = '0;
  wire  r_g_io_out_s3_full_pred_3_hit, r_i_io_out_s3_full_pred_3_hit;
  logic r_s0_io_out_s3_full_pred_3_hit = '0, r_s1_io_out_s3_full_pred_3_hit = '0;
  wire  [515:0] r_g_io_out_last_stage_meta, r_i_io_out_last_stage_meta;
  logic [515:0] r_s0_io_out_last_stage_meta = '0, r_s1_io_out_last_stage_meta = '0;
  wire  [3:0] r_g_io_out_last_stage_spec_info_ssp, r_i_io_out_last_stage_spec_info_ssp;
  logic [3:0] r_s0_io_out_last_stage_spec_info_ssp = '0, r_s1_io_out_last_stage_spec_info_ssp = '0;
  wire  [2:0] r_g_io_out_last_stage_spec_info_sctr, r_i_io_out_last_stage_spec_info_sctr;
  logic [2:0] r_s0_io_out_last_stage_spec_info_sctr = '0, r_s1_io_out_last_stage_spec_info_sctr = '0;
  wire  r_g_io_out_last_stage_spec_info_TOSW_flag, r_i_io_out_last_stage_spec_info_TOSW_flag;
  logic r_s0_io_out_last_stage_spec_info_TOSW_flag = '0, r_s1_io_out_last_stage_spec_info_TOSW_flag = '0;
  wire  [4:0] r_g_io_out_last_stage_spec_info_TOSW_value, r_i_io_out_last_stage_spec_info_TOSW_value;
  logic [4:0] r_s0_io_out_last_stage_spec_info_TOSW_value = '0, r_s1_io_out_last_stage_spec_info_TOSW_value = '0;
  wire  r_g_io_out_last_stage_spec_info_TOSR_flag, r_i_io_out_last_stage_spec_info_TOSR_flag;
  logic r_s0_io_out_last_stage_spec_info_TOSR_flag = '0, r_s1_io_out_last_stage_spec_info_TOSR_flag = '0;
  wire  [4:0] r_g_io_out_last_stage_spec_info_TOSR_value, r_i_io_out_last_stage_spec_info_TOSR_value;
  logic [4:0] r_s0_io_out_last_stage_spec_info_TOSR_value = '0, r_s1_io_out_last_stage_spec_info_TOSR_value = '0;
  wire  r_g_io_out_last_stage_spec_info_NOS_flag, r_i_io_out_last_stage_spec_info_NOS_flag;
  logic r_s0_io_out_last_stage_spec_info_NOS_flag = '0, r_s1_io_out_last_stage_spec_info_NOS_flag = '0;
  wire  [4:0] r_g_io_out_last_stage_spec_info_NOS_value, r_i_io_out_last_stage_spec_info_NOS_value;
  logic [4:0] r_s0_io_out_last_stage_spec_info_NOS_value = '0, r_s1_io_out_last_stage_spec_info_NOS_value = '0;
  wire  [49:0] r_g_io_out_last_stage_spec_info_topAddr, r_i_io_out_last_stage_spec_info_topAddr;
  logic [49:0] r_s0_io_out_last_stage_spec_info_topAddr = '0, r_s1_io_out_last_stage_spec_info_topAddr = '0;
  wire  r_g_io_out_last_stage_spec_info_sc_disagree_0, r_i_io_out_last_stage_spec_info_sc_disagree_0;
  logic r_s0_io_out_last_stage_spec_info_sc_disagree_0 = '0, r_s1_io_out_last_stage_spec_info_sc_disagree_0 = '0;
  wire  r_g_io_out_last_stage_spec_info_sc_disagree_1, r_i_io_out_last_stage_spec_info_sc_disagree_1;
  logic r_s0_io_out_last_stage_spec_info_sc_disagree_1 = '0, r_s1_io_out_last_stage_spec_info_sc_disagree_1 = '0;
  wire  r_g_io_out_last_stage_ftb_entry_isCall, r_i_io_out_last_stage_ftb_entry_isCall;
  logic r_s0_io_out_last_stage_ftb_entry_isCall = '0, r_s1_io_out_last_stage_ftb_entry_isCall = '0;
  wire  r_g_io_out_last_stage_ftb_entry_isRet, r_i_io_out_last_stage_ftb_entry_isRet;
  logic r_s0_io_out_last_stage_ftb_entry_isRet = '0, r_s1_io_out_last_stage_ftb_entry_isRet = '0;
  wire  r_g_io_out_last_stage_ftb_entry_isJalr, r_i_io_out_last_stage_ftb_entry_isJalr;
  logic r_s0_io_out_last_stage_ftb_entry_isJalr = '0, r_s1_io_out_last_stage_ftb_entry_isJalr = '0;
  wire  r_g_io_out_last_stage_ftb_entry_valid, r_i_io_out_last_stage_ftb_entry_valid;
  logic r_s0_io_out_last_stage_ftb_entry_valid = '0, r_s1_io_out_last_stage_ftb_entry_valid = '0;
  wire  [3:0] r_g_io_out_last_stage_ftb_entry_brSlots_0_offset, r_i_io_out_last_stage_ftb_entry_brSlots_0_offset;
  logic [3:0] r_s0_io_out_last_stage_ftb_entry_brSlots_0_offset = '0, r_s1_io_out_last_stage_ftb_entry_brSlots_0_offset = '0;
  wire  r_g_io_out_last_stage_ftb_entry_brSlots_0_sharing, r_i_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  logic r_s0_io_out_last_stage_ftb_entry_brSlots_0_sharing = '0, r_s1_io_out_last_stage_ftb_entry_brSlots_0_sharing = '0;
  wire  r_g_io_out_last_stage_ftb_entry_brSlots_0_valid, r_i_io_out_last_stage_ftb_entry_brSlots_0_valid;
  logic r_s0_io_out_last_stage_ftb_entry_brSlots_0_valid = '0, r_s1_io_out_last_stage_ftb_entry_brSlots_0_valid = '0;
  wire  [11:0] r_g_io_out_last_stage_ftb_entry_brSlots_0_lower, r_i_io_out_last_stage_ftb_entry_brSlots_0_lower;
  logic [11:0] r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower = '0, r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower = '0;
  wire  [1:0] r_g_io_out_last_stage_ftb_entry_brSlots_0_tarStat, r_i_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  logic [1:0] r_s0_io_out_last_stage_ftb_entry_brSlots_0_tarStat = '0, r_s1_io_out_last_stage_ftb_entry_brSlots_0_tarStat = '0;
  wire  [3:0] r_g_io_out_last_stage_ftb_entry_tailSlot_offset, r_i_io_out_last_stage_ftb_entry_tailSlot_offset;
  logic [3:0] r_s0_io_out_last_stage_ftb_entry_tailSlot_offset = '0, r_s1_io_out_last_stage_ftb_entry_tailSlot_offset = '0;
  wire  r_g_io_out_last_stage_ftb_entry_tailSlot_sharing, r_i_io_out_last_stage_ftb_entry_tailSlot_sharing;
  logic r_s0_io_out_last_stage_ftb_entry_tailSlot_sharing = '0, r_s1_io_out_last_stage_ftb_entry_tailSlot_sharing = '0;
  wire  r_g_io_out_last_stage_ftb_entry_tailSlot_valid, r_i_io_out_last_stage_ftb_entry_tailSlot_valid;
  logic r_s0_io_out_last_stage_ftb_entry_tailSlot_valid = '0, r_s1_io_out_last_stage_ftb_entry_tailSlot_valid = '0;
  wire  [19:0] r_g_io_out_last_stage_ftb_entry_tailSlot_lower, r_i_io_out_last_stage_ftb_entry_tailSlot_lower;
  logic [19:0] r_s0_io_out_last_stage_ftb_entry_tailSlot_lower = '0, r_s1_io_out_last_stage_ftb_entry_tailSlot_lower = '0;
  wire  [1:0] r_g_io_out_last_stage_ftb_entry_tailSlot_tarStat, r_i_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  logic [1:0] r_s0_io_out_last_stage_ftb_entry_tailSlot_tarStat = '0, r_s1_io_out_last_stage_ftb_entry_tailSlot_tarStat = '0;
  wire  [3:0] r_g_io_out_last_stage_ftb_entry_pftAddr, r_i_io_out_last_stage_ftb_entry_pftAddr;
  logic [3:0] r_s0_io_out_last_stage_ftb_entry_pftAddr = '0, r_s1_io_out_last_stage_ftb_entry_pftAddr = '0;
  wire  r_g_io_out_last_stage_ftb_entry_carry, r_i_io_out_last_stage_ftb_entry_carry;
  logic r_s0_io_out_last_stage_ftb_entry_carry = '0, r_s1_io_out_last_stage_ftb_entry_carry = '0;
  wire  r_g_io_out_last_stage_ftb_entry_last_may_be_rvi_call, r_i_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  logic r_s0_io_out_last_stage_ftb_entry_last_may_be_rvi_call = '0, r_s1_io_out_last_stage_ftb_entry_last_may_be_rvi_call = '0;
  wire  r_g_io_out_last_stage_ftb_entry_strong_bias_0, r_i_io_out_last_stage_ftb_entry_strong_bias_0;
  logic r_s0_io_out_last_stage_ftb_entry_strong_bias_0 = '0, r_s1_io_out_last_stage_ftb_entry_strong_bias_0 = '0;
  wire  r_g_io_out_last_stage_ftb_entry_strong_bias_1, r_i_io_out_last_stage_ftb_entry_strong_bias_1;
  logic r_s0_io_out_last_stage_ftb_entry_strong_bias_1 = '0, r_s1_io_out_last_stage_ftb_entry_strong_bias_1 = '0;
  logic r_io_ctrl_ras_enable;
  logic r_io_s0_fire_0;
  logic r_io_s0_fire_1;
  logic r_io_s0_fire_2;
  logic r_io_s0_fire_3;
  logic r_io_s1_fire_0;
  logic r_io_s1_fire_1;
  logic r_io_s1_fire_2;
  logic r_io_s1_fire_3;
  logic r_io_s2_fire_0;
  logic r_io_s2_fire_1;
  logic r_io_s2_fire_2;
  logic r_io_s2_fire_3;
  logic r_io_s3_fire_2;
  logic r_io_s3_redirect_2;
  logic r_io_update_valid;
  logic r_io_update_bits_ftb_entry_isCall;
  logic r_io_update_bits_ftb_entry_isRet;
  logic [3:0] r_io_update_bits_ftb_entry_tailSlot_offset;
  logic r_io_update_bits_ftb_entry_tailSlot_valid;
  logic r_io_update_bits_cfi_idx_valid;
  logic [3:0] r_io_update_bits_cfi_idx_bits;
  logic r_io_update_bits_jmp_taken;
  logic [515:0] r_io_update_bits_meta;
  logic r_io_redirect_valid;
  logic r_io_redirect_bits_level;
  logic [49:0] r_io_redirect_bits_cfiUpdate_pc;
  logic r_io_redirect_bits_cfiUpdate_pd_valid;
  logic r_io_redirect_bits_cfiUpdate_pd_isRVC;
  logic r_io_redirect_bits_cfiUpdate_pd_isCall;
  logic r_io_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0] r_io_redirect_bits_cfiUpdate_ssp;
  logic [2:0] r_io_redirect_bits_cfiUpdate_sctr;
  logic r_io_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0] r_io_redirect_bits_cfiUpdate_TOSW_value;
  logic r_io_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0] r_io_redirect_bits_cfiUpdate_TOSR_value;
  logic r_io_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0] r_io_redirect_bits_cfiUpdate_NOS_value;
  int r_cov_spec_push = 0;
  int r_cov_spec_pop = 0;
  int r_cov_s3_cancel = 0;
  int r_cov_near_overflow = 0;
  int r_cov_redirect_call = 0;
  int r_cov_redirect_ret = 0;
  int r_cov_commit_push = 0;
  int r_cov_commit_pop = 0;
  int r_cov_s2_ret_target = 0;
  int r_cov_s2_seg_hold = 0;
  int r_cov_reset_mid = 0;
  logic [2:0] r_armed = '0;
  int r_armed_at = -1;
  RAS r_u_gold (
    .clock(clk),
    .reset(r_reset),
    .io_reset_vector(r_io_reset_vector),
    .io_in_bits_s0_pc_0(r_io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(r_io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(r_io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(r_io_in_bits_s0_pc_3),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_call(r_io_in_bits_resp_in_0_s2_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_0_hit(r_io_in_bits_resp_in_0_s2_full_pred_0_hit),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_call(r_io_in_bits_resp_in_0_s2_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_1_hit(r_io_in_bits_resp_in_0_s2_full_pred_1_hit),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_call(r_io_in_bits_resp_in_0_s2_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_2_hit(r_io_in_bits_resp_in_0_s2_full_pred_2_hit),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_call(r_io_in_bits_resp_in_0_s2_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_3_hit(r_io_in_bits_resp_in_0_s2_full_pred_3_hit),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_0_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_0_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_call(r_io_in_bits_resp_in_0_s3_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_0_hit(r_io_in_bits_resp_in_0_s3_full_pred_0_hit),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_1_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_1_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_call(r_io_in_bits_resp_in_0_s3_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_1_hit(r_io_in_bits_resp_in_0_s3_full_pred_1_hit),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_2_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_2_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_call(r_io_in_bits_resp_in_0_s3_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_2_hit(r_io_in_bits_resp_in_0_s3_full_pred_2_hit),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_3_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_3_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_call(r_io_in_bits_resp_in_0_s3_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_3_hit(r_io_in_bits_resp_in_0_s3_full_pred_3_hit),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall(r_io_in_bits_resp_in_0_last_stage_ftb_entry_isCall),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet(r_io_in_bits_resp_in_0_last_stage_ftb_entry_isRet),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr(r_io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_valid(r_io_in_bits_resp_in_0_last_stage_ftb_entry_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr(r_io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_carry(r_io_in_bits_resp_in_0_last_stage_ftb_entry_carry),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call(r_io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0(r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1(r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1),
    .io_out_s2_pc_0(r_g_io_out_s2_pc_0),
    .io_out_s2_pc_1(r_g_io_out_s2_pc_1),
    .io_out_s2_pc_2(r_g_io_out_s2_pc_2),
    .io_out_s2_pc_3(r_g_io_out_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0(r_g_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1(r_g_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0(r_g_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1(r_g_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0(r_g_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1(r_g_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target(r_g_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0(r_g_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1(r_g_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr(r_g_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr(r_g_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal(r_g_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr(r_g_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call(r_g_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret(r_g_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call(r_g_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing(r_g_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit(r_g_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0(r_g_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1(r_g_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0(r_g_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1(r_g_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0(r_g_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1(r_g_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target(r_g_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0(r_g_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1(r_g_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr(r_g_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr(r_g_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal(r_g_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr(r_g_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call(r_g_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret(r_g_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call(r_g_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing(r_g_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit(r_g_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0(r_g_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1(r_g_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0(r_g_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1(r_g_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0(r_g_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1(r_g_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target(r_g_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0(r_g_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1(r_g_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr(r_g_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr(r_g_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal(r_g_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr(r_g_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call(r_g_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret(r_g_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call(r_g_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing(r_g_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit(r_g_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0(r_g_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1(r_g_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0(r_g_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1(r_g_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0(r_g_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1(r_g_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target(r_g_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0(r_g_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1(r_g_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr(r_g_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr(r_g_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal(r_g_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr(r_g_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call(r_g_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret(r_g_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call(r_g_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing(r_g_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit(r_g_io_out_s2_full_pred_3_hit),
    .io_out_s3_pc_0(r_g_io_out_s3_pc_0),
    .io_out_s3_pc_1(r_g_io_out_s3_pc_1),
    .io_out_s3_pc_2(r_g_io_out_s3_pc_2),
    .io_out_s3_pc_3(r_g_io_out_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0(r_g_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1(r_g_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0(r_g_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1(r_g_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0(r_g_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1(r_g_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target(r_g_io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0(r_g_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1(r_g_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr(r_g_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr(r_g_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit(r_g_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal(r_g_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr(r_g_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call(r_g_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret(r_g_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call(r_g_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing(r_g_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit(r_g_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0(r_g_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1(r_g_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0(r_g_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1(r_g_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0(r_g_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1(r_g_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target(r_g_io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0(r_g_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1(r_g_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr(r_g_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr(r_g_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit(r_g_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal(r_g_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr(r_g_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call(r_g_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret(r_g_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call(r_g_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing(r_g_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit(r_g_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0(r_g_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1(r_g_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0(r_g_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1(r_g_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0(r_g_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1(r_g_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target(r_g_io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0(r_g_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1(r_g_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr(r_g_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr(r_g_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit(r_g_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal(r_g_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr(r_g_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call(r_g_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret(r_g_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call(r_g_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing(r_g_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit(r_g_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0(r_g_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1(r_g_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0(r_g_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1(r_g_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0(r_g_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1(r_g_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target(r_g_io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0(r_g_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1(r_g_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr(r_g_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr(r_g_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit(r_g_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal(r_g_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr(r_g_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call(r_g_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret(r_g_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call(r_g_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing(r_g_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit(r_g_io_out_s3_full_pred_3_hit),
    .io_out_last_stage_meta(r_g_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_ssp(r_g_io_out_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr(r_g_io_out_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag(r_g_io_out_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value(r_g_io_out_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag(r_g_io_out_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value(r_g_io_out_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag(r_g_io_out_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value(r_g_io_out_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr(r_g_io_out_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0(r_g_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1(r_g_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall(r_g_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet(r_g_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr(r_g_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid(r_g_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset(r_g_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing(r_g_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid(r_g_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower(r_g_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat(r_g_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset(r_g_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing(r_g_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid(r_g_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower(r_g_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat(r_g_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr(r_g_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry(r_g_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call(r_g_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0(r_g_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1(r_g_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_ctrl_ras_enable(r_io_ctrl_ras_enable),
    .io_s0_fire_0(r_io_s0_fire_0),
    .io_s0_fire_1(r_io_s0_fire_1),
    .io_s0_fire_2(r_io_s0_fire_2),
    .io_s0_fire_3(r_io_s0_fire_3),
    .io_s1_fire_0(r_io_s1_fire_0),
    .io_s1_fire_1(r_io_s1_fire_1),
    .io_s1_fire_2(r_io_s1_fire_2),
    .io_s1_fire_3(r_io_s1_fire_3),
    .io_s2_fire_0(r_io_s2_fire_0),
    .io_s2_fire_1(r_io_s2_fire_1),
    .io_s2_fire_2(r_io_s2_fire_2),
    .io_s2_fire_3(r_io_s2_fire_3),
    .io_s3_fire_2(r_io_s3_fire_2),
    .io_s3_redirect_2(r_io_s3_redirect_2),
    .io_update_valid(r_io_update_valid),
    .io_update_bits_ftb_entry_isCall(r_io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet(r_io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_tailSlot_offset(r_io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_valid(r_io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_cfi_idx_valid(r_io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits(r_io_update_bits_cfi_idx_bits),
    .io_update_bits_jmp_taken(r_io_update_bits_jmp_taken),
    .io_update_bits_meta(r_io_update_bits_meta),
    .io_redirect_valid(r_io_redirect_valid),
    .io_redirect_bits_level(r_io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_pc(r_io_redirect_bits_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid(r_io_redirect_bits_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC(r_io_redirect_bits_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall(r_io_redirect_bits_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet(r_io_redirect_bits_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp(r_io_redirect_bits_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr(r_io_redirect_bits_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag(r_io_redirect_bits_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value(r_io_redirect_bits_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag(r_io_redirect_bits_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value(r_io_redirect_bits_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag(r_io_redirect_bits_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value(r_io_redirect_bits_cfiUpdate_NOS_value)
  );
  RAS_xs r_u_impl (
    .clock(clk),
    .reset(r_reset),
    .io_reset_vector(r_io_reset_vector),
    .io_in_bits_s0_pc_0(r_io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(r_io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(r_io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(r_io_in_bits_s0_pc_3),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_call(r_io_in_bits_resp_in_0_s2_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_0_hit(r_io_in_bits_resp_in_0_s2_full_pred_0_hit),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_call(r_io_in_bits_resp_in_0_s2_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_1_hit(r_io_in_bits_resp_in_0_s2_full_pred_1_hit),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_call(r_io_in_bits_resp_in_0_s2_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_2_hit(r_io_in_bits_resp_in_0_s2_full_pred_2_hit),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0(r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1(r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0(r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1(r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_0(r_io_in_bits_resp_in_0_s2_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_1(r_io_in_bits_resp_in_0_s2_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target(r_io_in_bits_resp_in_0_s2_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0(r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1(r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr(r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr(r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jal(r_io_in_bits_resp_in_0_s2_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr(r_io_in_bits_resp_in_0_s2_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_call(r_io_in_bits_resp_in_0_s2_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_ret(r_io_in_bits_resp_in_0_s2_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing(r_io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_3_hit(r_io_in_bits_resp_in_0_s2_full_pred_3_hit),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_0_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_0_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_call(r_io_in_bits_resp_in_0_s3_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_0_hit(r_io_in_bits_resp_in_0_s3_full_pred_0_hit),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_1_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_1_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_call(r_io_in_bits_resp_in_0_s3_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_1_hit(r_io_in_bits_resp_in_0_s3_full_pred_1_hit),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_2_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_2_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_call(r_io_in_bits_resp_in_0_s3_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_2_hit(r_io_in_bits_resp_in_0_s3_full_pred_2_hit),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0(r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1(r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0(r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1(r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_0(r_io_in_bits_resp_in_0_s3_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_1(r_io_in_bits_resp_in_0_s3_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_jalr_target(r_io_in_bits_resp_in_0_s3_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0(r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1(r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr(r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr(r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_3_multiHit(r_io_in_bits_resp_in_0_s3_full_pred_3_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jal(r_io_in_bits_resp_in_0_s3_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr(r_io_in_bits_resp_in_0_s3_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_call(r_io_in_bits_resp_in_0_s3_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_ret(r_io_in_bits_resp_in_0_s3_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call(r_io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing(r_io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_3_hit(r_io_in_bits_resp_in_0_s3_full_pred_3_hit),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall(r_io_in_bits_resp_in_0_last_stage_ftb_entry_isCall),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet(r_io_in_bits_resp_in_0_last_stage_ftb_entry_isRet),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr(r_io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_valid(r_io_in_bits_resp_in_0_last_stage_ftb_entry_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat(r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat(r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr(r_io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_carry(r_io_in_bits_resp_in_0_last_stage_ftb_entry_carry),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call(r_io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0(r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1(r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1),
    .io_out_s2_pc_0(r_i_io_out_s2_pc_0),
    .io_out_s2_pc_1(r_i_io_out_s2_pc_1),
    .io_out_s2_pc_2(r_i_io_out_s2_pc_2),
    .io_out_s2_pc_3(r_i_io_out_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0(r_i_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1(r_i_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0(r_i_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1(r_i_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0(r_i_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1(r_i_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target(r_i_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0(r_i_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1(r_i_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr(r_i_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr(r_i_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal(r_i_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr(r_i_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call(r_i_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret(r_i_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call(r_i_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing(r_i_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit(r_i_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0(r_i_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1(r_i_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0(r_i_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1(r_i_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0(r_i_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1(r_i_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target(r_i_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0(r_i_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1(r_i_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr(r_i_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr(r_i_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal(r_i_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr(r_i_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call(r_i_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret(r_i_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call(r_i_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing(r_i_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit(r_i_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0(r_i_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1(r_i_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0(r_i_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1(r_i_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0(r_i_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1(r_i_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target(r_i_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0(r_i_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1(r_i_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr(r_i_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr(r_i_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal(r_i_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr(r_i_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call(r_i_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret(r_i_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call(r_i_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing(r_i_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit(r_i_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0(r_i_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1(r_i_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0(r_i_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1(r_i_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0(r_i_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1(r_i_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target(r_i_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0(r_i_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1(r_i_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr(r_i_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr(r_i_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal(r_i_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr(r_i_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call(r_i_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret(r_i_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call(r_i_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing(r_i_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit(r_i_io_out_s2_full_pred_3_hit),
    .io_out_s3_pc_0(r_i_io_out_s3_pc_0),
    .io_out_s3_pc_1(r_i_io_out_s3_pc_1),
    .io_out_s3_pc_2(r_i_io_out_s3_pc_2),
    .io_out_s3_pc_3(r_i_io_out_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0(r_i_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1(r_i_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0(r_i_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1(r_i_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0(r_i_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1(r_i_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target(r_i_io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0(r_i_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1(r_i_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr(r_i_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr(r_i_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit(r_i_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal(r_i_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr(r_i_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call(r_i_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret(r_i_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call(r_i_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing(r_i_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit(r_i_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0(r_i_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1(r_i_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0(r_i_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1(r_i_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0(r_i_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1(r_i_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target(r_i_io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0(r_i_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1(r_i_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr(r_i_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr(r_i_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit(r_i_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal(r_i_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr(r_i_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call(r_i_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret(r_i_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call(r_i_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing(r_i_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit(r_i_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0(r_i_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1(r_i_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0(r_i_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1(r_i_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0(r_i_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1(r_i_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target(r_i_io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0(r_i_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1(r_i_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr(r_i_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr(r_i_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit(r_i_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal(r_i_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr(r_i_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call(r_i_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret(r_i_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call(r_i_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing(r_i_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit(r_i_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0(r_i_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1(r_i_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0(r_i_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1(r_i_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0(r_i_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1(r_i_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target(r_i_io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0(r_i_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1(r_i_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr(r_i_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr(r_i_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit(r_i_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal(r_i_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr(r_i_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call(r_i_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret(r_i_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call(r_i_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing(r_i_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit(r_i_io_out_s3_full_pred_3_hit),
    .io_out_last_stage_meta(r_i_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_ssp(r_i_io_out_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr(r_i_io_out_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag(r_i_io_out_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value(r_i_io_out_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag(r_i_io_out_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value(r_i_io_out_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag(r_i_io_out_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value(r_i_io_out_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr(r_i_io_out_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0(r_i_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1(r_i_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall(r_i_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet(r_i_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr(r_i_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid(r_i_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset(r_i_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing(r_i_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid(r_i_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower(r_i_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat(r_i_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset(r_i_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing(r_i_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid(r_i_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower(r_i_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat(r_i_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr(r_i_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry(r_i_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call(r_i_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0(r_i_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1(r_i_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_ctrl_ras_enable(r_io_ctrl_ras_enable),
    .io_s0_fire_0(r_io_s0_fire_0),
    .io_s0_fire_1(r_io_s0_fire_1),
    .io_s0_fire_2(r_io_s0_fire_2),
    .io_s0_fire_3(r_io_s0_fire_3),
    .io_s1_fire_0(r_io_s1_fire_0),
    .io_s1_fire_1(r_io_s1_fire_1),
    .io_s1_fire_2(r_io_s1_fire_2),
    .io_s1_fire_3(r_io_s1_fire_3),
    .io_s2_fire_0(r_io_s2_fire_0),
    .io_s2_fire_1(r_io_s2_fire_1),
    .io_s2_fire_2(r_io_s2_fire_2),
    .io_s2_fire_3(r_io_s2_fire_3),
    .io_s3_fire_2(r_io_s3_fire_2),
    .io_s3_redirect_2(r_io_s3_redirect_2),
    .io_update_valid(r_io_update_valid),
    .io_update_bits_ftb_entry_isCall(r_io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet(r_io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_tailSlot_offset(r_io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_valid(r_io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_cfi_idx_valid(r_io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits(r_io_update_bits_cfi_idx_bits),
    .io_update_bits_jmp_taken(r_io_update_bits_jmp_taken),
    .io_update_bits_meta(r_io_update_bits_meta),
    .io_redirect_valid(r_io_redirect_valid),
    .io_redirect_bits_level(r_io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_pc(r_io_redirect_bits_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid(r_io_redirect_bits_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC(r_io_redirect_bits_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall(r_io_redirect_bits_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet(r_io_redirect_bits_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp(r_io_redirect_bits_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr(r_io_redirect_bits_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag(r_io_redirect_bits_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value(r_io_redirect_bits_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag(r_io_redirect_bits_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value(r_io_redirect_bits_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag(r_io_redirect_bits_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value(r_io_redirect_bits_cfiUpdate_NOS_value)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) r_mode = $urandom_range(0, 15);
      r_io_reset_vector = 48'({$urandom, $urandom});
      r_io_in_bits_s0_pc_0 = 50'({$urandom, $urandom});
      r_io_in_bits_s0_pc_1 = 50'({$urandom, $urandom});
      r_io_in_bits_s0_pc_2 = 50'({$urandom, $urandom});
      r_io_in_bits_s0_pc_3 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_0_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_0_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_0_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_1_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_1_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_1_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_2_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_2_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_2_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_3_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_3_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s2_full_pred_3_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_0_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_0_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_multiHit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_0_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_1_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_1_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_multiHit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_1_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_2_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_2_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_multiHit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_2_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_targets_0 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_3_targets_1 = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_3_jalr_target = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_0 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_offsets_1 = 4'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr = 50'({$urandom, $urandom});
      r_io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_multiHit = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_is_jal = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_is_jalr = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_is_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_is_ret = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_s3_full_pred_3_hit = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1 = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_isCall = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_isRet = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_valid = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset = 4'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower = 12'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat = 2'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset = 4'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower = 20'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat = 2'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr = 4'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_carry = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0 = 1'($urandom);
      r_io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1 = 1'($urandom);
      r_io_ctrl_ras_enable = 1'($urandom);
      r_io_s0_fire_0 = 1'($urandom);
      r_io_s0_fire_1 = 1'($urandom);
      r_io_s0_fire_2 = 1'($urandom);
      r_io_s0_fire_3 = 1'($urandom);
      r_io_s1_fire_0 = 1'($urandom);
      r_io_s1_fire_1 = 1'($urandom);
      r_io_s1_fire_2 = 1'($urandom);
      r_io_s1_fire_3 = 1'($urandom);
      r_io_s2_fire_0 = 1'($urandom);
      r_io_s2_fire_1 = 1'($urandom);
      r_io_s2_fire_2 = 1'($urandom);
      r_io_s2_fire_3 = 1'($urandom);
      r_io_s3_fire_2 = 1'($urandom);
      r_io_s3_redirect_2 = 1'($urandom);
      r_io_update_valid = 1'($urandom);
      r_io_update_bits_ftb_entry_isCall = 1'($urandom);
      r_io_update_bits_ftb_entry_isRet = 1'($urandom);
      r_io_update_bits_ftb_entry_tailSlot_offset = 4'($urandom);
      r_io_update_bits_ftb_entry_tailSlot_valid = 1'($urandom);
      r_io_update_bits_cfi_idx_valid = 1'($urandom);
      r_io_update_bits_cfi_idx_bits = 4'($urandom);
      r_io_update_bits_jmp_taken = 1'($urandom);
      r_io_update_bits_meta = 516'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      r_io_redirect_valid = 1'($urandom);
      r_io_redirect_bits_level = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_pc = 50'({$urandom, $urandom});
      r_io_redirect_bits_cfiUpdate_pd_valid = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_pd_isRVC = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_pd_isCall = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_pd_isRet = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_ssp = 4'($urandom);
      r_io_redirect_bits_cfiUpdate_sctr = 3'($urandom);
      r_io_redirect_bits_cfiUpdate_TOSW_flag = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_TOSW_value = 5'($urandom);
      r_io_redirect_bits_cfiUpdate_TOSR_flag = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_TOSR_value = 5'($urandom);
      r_io_redirect_bits_cfiUpdate_NOS_flag = 1'($urandom);
      r_io_redirect_bits_cfiUpdate_NOS_value = 5'($urandom);
      r_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      begin : stim_r
        if ($urandom_range(0, 3) != 0) begin r_io_in_bits_s0_pc_0[49:24] = r_hi_pool[$urandom_range(0, 3)]; r_io_in_bits_s0_pc_0[23:12] = r_mid_pool[$urandom_range(0, 3)]; end
        if ($urandom_range(0, 3) != 0) begin r_io_in_bits_s0_pc_1[49:24] = r_hi_pool[$urandom_range(0, 3)]; r_io_in_bits_s0_pc_1[23:12] = r_mid_pool[$urandom_range(0, 3)]; end
        if ($urandom_range(0, 3) != 0) begin r_io_in_bits_s0_pc_2[49:24] = r_hi_pool[$urandom_range(0, 3)]; r_io_in_bits_s0_pc_2[23:12] = r_mid_pool[$urandom_range(0, 3)]; end
        if ($urandom_range(0, 3) != 0) begin r_io_in_bits_s0_pc_3[49:24] = r_hi_pool[$urandom_range(0, 3)]; r_io_in_bits_s0_pc_3[23:12] = r_mid_pool[$urandom_range(0, 3)]; end
        if ($urandom_range(0, 3) != 0) begin   // s2：尾槽 taken 跳转的形状
          r_io_in_bits_resp_in_0_s2_full_pred_2_hit = 1'b1;
          r_io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1 = 1'b1;
          r_io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing = 1'b0;
          r_io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0 = ($urandom_range(0, 3) == 0);
        end
        if ($urandom_range(0, 3) != 0) begin   // s3：尾槽 taken 跳转的形状
          r_io_in_bits_resp_in_0_s3_full_pred_2_hit = 1'b1;
          r_io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1 = 1'b1;
          r_io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing = 1'b0;
          r_io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0 = ($urandom_range(0, 3) == 0);
        end
        r_io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr = ($urandom_range(0, 7) == 0);
        r_io_ctrl_ras_enable = ($urandom_range(0, 15) != 0);
        r_io_s3_redirect_2 = ($urandom_range(0, 7) == 0);
        r_io_redirect_valid = ($urandom_range(0, 15) == 0);
        r_io_update_valid = ($urandom_range(0, 3) == 0);
        if ($urandom_range(0, 3) != 0) begin
          r_io_update_bits_ftb_entry_tailSlot_valid = 1'b1;
          r_io_update_bits_jmp_taken = 1'b1;
          r_io_update_bits_cfi_idx_valid = 1'b1;
          if ($urandom_range(0, 1)) r_io_update_bits_cfi_idx_bits = r_io_update_bits_ftb_entry_tailSlot_offset;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && r_armed_at >= 0 && cyc >= r_armed_at) begin
        checks++;
        if (r_g_io_out_s2_pc_0 !== r_i_io_out_s2_pc_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_pc_0 g=%h i=%h", cyc, r_g_io_out_s2_pc_0, r_i_io_out_s2_pc_0);
        end
        r_s1_io_out_s2_pc_0 |= r_g_io_out_s2_pc_0;
        r_s0_io_out_s2_pc_0 |= ~r_g_io_out_s2_pc_0;
        checks++;
        if (r_g_io_out_s2_pc_1 !== r_i_io_out_s2_pc_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_pc_1 g=%h i=%h", cyc, r_g_io_out_s2_pc_1, r_i_io_out_s2_pc_1);
        end
        r_s1_io_out_s2_pc_1 |= r_g_io_out_s2_pc_1;
        r_s0_io_out_s2_pc_1 |= ~r_g_io_out_s2_pc_1;
        checks++;
        if (r_g_io_out_s2_pc_2 !== r_i_io_out_s2_pc_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_pc_2 g=%h i=%h", cyc, r_g_io_out_s2_pc_2, r_i_io_out_s2_pc_2);
        end
        r_s1_io_out_s2_pc_2 |= r_g_io_out_s2_pc_2;
        r_s0_io_out_s2_pc_2 |= ~r_g_io_out_s2_pc_2;
        checks++;
        if (r_g_io_out_s2_pc_3 !== r_i_io_out_s2_pc_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_pc_3 g=%h i=%h", cyc, r_g_io_out_s2_pc_3, r_i_io_out_s2_pc_3);
        end
        r_s1_io_out_s2_pc_3 |= r_g_io_out_s2_pc_3;
        r_s0_io_out_s2_pc_3 |= ~r_g_io_out_s2_pc_3;
        checks++;
        if (r_g_io_out_s2_full_pred_0_br_taken_mask_0 !== r_i_io_out_s2_full_pred_0_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_br_taken_mask_0, r_i_io_out_s2_full_pred_0_br_taken_mask_0);
        end
        r_s1_io_out_s2_full_pred_0_br_taken_mask_0 |= r_g_io_out_s2_full_pred_0_br_taken_mask_0;
        r_s0_io_out_s2_full_pred_0_br_taken_mask_0 |= ~r_g_io_out_s2_full_pred_0_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s2_full_pred_0_br_taken_mask_1 !== r_i_io_out_s2_full_pred_0_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_br_taken_mask_1, r_i_io_out_s2_full_pred_0_br_taken_mask_1);
        end
        r_s1_io_out_s2_full_pred_0_br_taken_mask_1 |= r_g_io_out_s2_full_pred_0_br_taken_mask_1;
        r_s0_io_out_s2_full_pred_0_br_taken_mask_1 |= ~r_g_io_out_s2_full_pred_0_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s2_full_pred_0_slot_valids_0 !== r_i_io_out_s2_full_pred_0_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_slot_valids_0, r_i_io_out_s2_full_pred_0_slot_valids_0);
        end
        r_s1_io_out_s2_full_pred_0_slot_valids_0 |= r_g_io_out_s2_full_pred_0_slot_valids_0;
        r_s0_io_out_s2_full_pred_0_slot_valids_0 |= ~r_g_io_out_s2_full_pred_0_slot_valids_0;
        checks++;
        if (r_g_io_out_s2_full_pred_0_slot_valids_1 !== r_i_io_out_s2_full_pred_0_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_slot_valids_1, r_i_io_out_s2_full_pred_0_slot_valids_1);
        end
        r_s1_io_out_s2_full_pred_0_slot_valids_1 |= r_g_io_out_s2_full_pred_0_slot_valids_1;
        r_s0_io_out_s2_full_pred_0_slot_valids_1 |= ~r_g_io_out_s2_full_pred_0_slot_valids_1;
        checks++;
        if (r_g_io_out_s2_full_pred_0_targets_0 !== r_i_io_out_s2_full_pred_0_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_targets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_targets_0, r_i_io_out_s2_full_pred_0_targets_0);
        end
        r_s1_io_out_s2_full_pred_0_targets_0 |= r_g_io_out_s2_full_pred_0_targets_0;
        r_s0_io_out_s2_full_pred_0_targets_0 |= ~r_g_io_out_s2_full_pred_0_targets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_0_targets_1 !== r_i_io_out_s2_full_pred_0_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_targets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_targets_1, r_i_io_out_s2_full_pred_0_targets_1);
        end
        r_s1_io_out_s2_full_pred_0_targets_1 |= r_g_io_out_s2_full_pred_0_targets_1;
        r_s0_io_out_s2_full_pred_0_targets_1 |= ~r_g_io_out_s2_full_pred_0_targets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_0_jalr_target !== r_i_io_out_s2_full_pred_0_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_jalr_target g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_jalr_target, r_i_io_out_s2_full_pred_0_jalr_target);
        end
        r_s1_io_out_s2_full_pred_0_jalr_target |= r_g_io_out_s2_full_pred_0_jalr_target;
        r_s0_io_out_s2_full_pred_0_jalr_target |= ~r_g_io_out_s2_full_pred_0_jalr_target;
        checks++;
        if (r_g_io_out_s2_full_pred_0_offsets_0 !== r_i_io_out_s2_full_pred_0_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_offsets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_offsets_0, r_i_io_out_s2_full_pred_0_offsets_0);
        end
        r_s1_io_out_s2_full_pred_0_offsets_0 |= r_g_io_out_s2_full_pred_0_offsets_0;
        r_s0_io_out_s2_full_pred_0_offsets_0 |= ~r_g_io_out_s2_full_pred_0_offsets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_0_offsets_1 !== r_i_io_out_s2_full_pred_0_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_offsets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_offsets_1, r_i_io_out_s2_full_pred_0_offsets_1);
        end
        r_s1_io_out_s2_full_pred_0_offsets_1 |= r_g_io_out_s2_full_pred_0_offsets_1;
        r_s0_io_out_s2_full_pred_0_offsets_1 |= ~r_g_io_out_s2_full_pred_0_offsets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_0_fallThroughAddr !== r_i_io_out_s2_full_pred_0_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_fallThroughAddr, r_i_io_out_s2_full_pred_0_fallThroughAddr);
        end
        r_s1_io_out_s2_full_pred_0_fallThroughAddr |= r_g_io_out_s2_full_pred_0_fallThroughAddr;
        r_s0_io_out_s2_full_pred_0_fallThroughAddr |= ~r_g_io_out_s2_full_pred_0_fallThroughAddr;
        checks++;
        if (r_g_io_out_s2_full_pred_0_fallThroughErr !== r_i_io_out_s2_full_pred_0_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_fallThroughErr, r_i_io_out_s2_full_pred_0_fallThroughErr);
        end
        r_s1_io_out_s2_full_pred_0_fallThroughErr |= r_g_io_out_s2_full_pred_0_fallThroughErr;
        r_s0_io_out_s2_full_pred_0_fallThroughErr |= ~r_g_io_out_s2_full_pred_0_fallThroughErr;
        checks++;
        if (r_g_io_out_s2_full_pred_0_is_jal !== r_i_io_out_s2_full_pred_0_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_is_jal g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_is_jal, r_i_io_out_s2_full_pred_0_is_jal);
        end
        r_s1_io_out_s2_full_pred_0_is_jal |= r_g_io_out_s2_full_pred_0_is_jal;
        r_s0_io_out_s2_full_pred_0_is_jal |= ~r_g_io_out_s2_full_pred_0_is_jal;
        checks++;
        if (r_g_io_out_s2_full_pred_0_is_jalr !== r_i_io_out_s2_full_pred_0_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_is_jalr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_is_jalr, r_i_io_out_s2_full_pred_0_is_jalr);
        end
        r_s1_io_out_s2_full_pred_0_is_jalr |= r_g_io_out_s2_full_pred_0_is_jalr;
        r_s0_io_out_s2_full_pred_0_is_jalr |= ~r_g_io_out_s2_full_pred_0_is_jalr;
        checks++;
        if (r_g_io_out_s2_full_pred_0_is_call !== r_i_io_out_s2_full_pred_0_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_is_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_is_call, r_i_io_out_s2_full_pred_0_is_call);
        end
        r_s1_io_out_s2_full_pred_0_is_call |= r_g_io_out_s2_full_pred_0_is_call;
        r_s0_io_out_s2_full_pred_0_is_call |= ~r_g_io_out_s2_full_pred_0_is_call;
        checks++;
        if (r_g_io_out_s2_full_pred_0_is_ret !== r_i_io_out_s2_full_pred_0_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_is_ret g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_is_ret, r_i_io_out_s2_full_pred_0_is_ret);
        end
        r_s1_io_out_s2_full_pred_0_is_ret |= r_g_io_out_s2_full_pred_0_is_ret;
        r_s0_io_out_s2_full_pred_0_is_ret |= ~r_g_io_out_s2_full_pred_0_is_ret;
        checks++;
        if (r_g_io_out_s2_full_pred_0_last_may_be_rvi_call !== r_i_io_out_s2_full_pred_0_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_last_may_be_rvi_call, r_i_io_out_s2_full_pred_0_last_may_be_rvi_call);
        end
        r_s1_io_out_s2_full_pred_0_last_may_be_rvi_call |= r_g_io_out_s2_full_pred_0_last_may_be_rvi_call;
        r_s0_io_out_s2_full_pred_0_last_may_be_rvi_call |= ~r_g_io_out_s2_full_pred_0_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s2_full_pred_0_is_br_sharing !== r_i_io_out_s2_full_pred_0_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_is_br_sharing, r_i_io_out_s2_full_pred_0_is_br_sharing);
        end
        r_s1_io_out_s2_full_pred_0_is_br_sharing |= r_g_io_out_s2_full_pred_0_is_br_sharing;
        r_s0_io_out_s2_full_pred_0_is_br_sharing |= ~r_g_io_out_s2_full_pred_0_is_br_sharing;
        checks++;
        if (r_g_io_out_s2_full_pred_0_hit !== r_i_io_out_s2_full_pred_0_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_0_hit g=%h i=%h", cyc, r_g_io_out_s2_full_pred_0_hit, r_i_io_out_s2_full_pred_0_hit);
        end
        r_s1_io_out_s2_full_pred_0_hit |= r_g_io_out_s2_full_pred_0_hit;
        r_s0_io_out_s2_full_pred_0_hit |= ~r_g_io_out_s2_full_pred_0_hit;
        checks++;
        if (r_g_io_out_s2_full_pred_1_br_taken_mask_0 !== r_i_io_out_s2_full_pred_1_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_br_taken_mask_0, r_i_io_out_s2_full_pred_1_br_taken_mask_0);
        end
        r_s1_io_out_s2_full_pred_1_br_taken_mask_0 |= r_g_io_out_s2_full_pred_1_br_taken_mask_0;
        r_s0_io_out_s2_full_pred_1_br_taken_mask_0 |= ~r_g_io_out_s2_full_pred_1_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s2_full_pred_1_br_taken_mask_1 !== r_i_io_out_s2_full_pred_1_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_br_taken_mask_1, r_i_io_out_s2_full_pred_1_br_taken_mask_1);
        end
        r_s1_io_out_s2_full_pred_1_br_taken_mask_1 |= r_g_io_out_s2_full_pred_1_br_taken_mask_1;
        r_s0_io_out_s2_full_pred_1_br_taken_mask_1 |= ~r_g_io_out_s2_full_pred_1_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s2_full_pred_1_slot_valids_0 !== r_i_io_out_s2_full_pred_1_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_slot_valids_0, r_i_io_out_s2_full_pred_1_slot_valids_0);
        end
        r_s1_io_out_s2_full_pred_1_slot_valids_0 |= r_g_io_out_s2_full_pred_1_slot_valids_0;
        r_s0_io_out_s2_full_pred_1_slot_valids_0 |= ~r_g_io_out_s2_full_pred_1_slot_valids_0;
        checks++;
        if (r_g_io_out_s2_full_pred_1_slot_valids_1 !== r_i_io_out_s2_full_pred_1_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_slot_valids_1, r_i_io_out_s2_full_pred_1_slot_valids_1);
        end
        r_s1_io_out_s2_full_pred_1_slot_valids_1 |= r_g_io_out_s2_full_pred_1_slot_valids_1;
        r_s0_io_out_s2_full_pred_1_slot_valids_1 |= ~r_g_io_out_s2_full_pred_1_slot_valids_1;
        checks++;
        if (r_g_io_out_s2_full_pred_1_targets_0 !== r_i_io_out_s2_full_pred_1_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_targets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_targets_0, r_i_io_out_s2_full_pred_1_targets_0);
        end
        r_s1_io_out_s2_full_pred_1_targets_0 |= r_g_io_out_s2_full_pred_1_targets_0;
        r_s0_io_out_s2_full_pred_1_targets_0 |= ~r_g_io_out_s2_full_pred_1_targets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_1_targets_1 !== r_i_io_out_s2_full_pred_1_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_targets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_targets_1, r_i_io_out_s2_full_pred_1_targets_1);
        end
        r_s1_io_out_s2_full_pred_1_targets_1 |= r_g_io_out_s2_full_pred_1_targets_1;
        r_s0_io_out_s2_full_pred_1_targets_1 |= ~r_g_io_out_s2_full_pred_1_targets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_1_jalr_target !== r_i_io_out_s2_full_pred_1_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_jalr_target g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_jalr_target, r_i_io_out_s2_full_pred_1_jalr_target);
        end
        r_s1_io_out_s2_full_pred_1_jalr_target |= r_g_io_out_s2_full_pred_1_jalr_target;
        r_s0_io_out_s2_full_pred_1_jalr_target |= ~r_g_io_out_s2_full_pred_1_jalr_target;
        checks++;
        if (r_g_io_out_s2_full_pred_1_offsets_0 !== r_i_io_out_s2_full_pred_1_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_offsets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_offsets_0, r_i_io_out_s2_full_pred_1_offsets_0);
        end
        r_s1_io_out_s2_full_pred_1_offsets_0 |= r_g_io_out_s2_full_pred_1_offsets_0;
        r_s0_io_out_s2_full_pred_1_offsets_0 |= ~r_g_io_out_s2_full_pred_1_offsets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_1_offsets_1 !== r_i_io_out_s2_full_pred_1_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_offsets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_offsets_1, r_i_io_out_s2_full_pred_1_offsets_1);
        end
        r_s1_io_out_s2_full_pred_1_offsets_1 |= r_g_io_out_s2_full_pred_1_offsets_1;
        r_s0_io_out_s2_full_pred_1_offsets_1 |= ~r_g_io_out_s2_full_pred_1_offsets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_1_fallThroughAddr !== r_i_io_out_s2_full_pred_1_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_fallThroughAddr, r_i_io_out_s2_full_pred_1_fallThroughAddr);
        end
        r_s1_io_out_s2_full_pred_1_fallThroughAddr |= r_g_io_out_s2_full_pred_1_fallThroughAddr;
        r_s0_io_out_s2_full_pred_1_fallThroughAddr |= ~r_g_io_out_s2_full_pred_1_fallThroughAddr;
        checks++;
        if (r_g_io_out_s2_full_pred_1_fallThroughErr !== r_i_io_out_s2_full_pred_1_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_fallThroughErr, r_i_io_out_s2_full_pred_1_fallThroughErr);
        end
        r_s1_io_out_s2_full_pred_1_fallThroughErr |= r_g_io_out_s2_full_pred_1_fallThroughErr;
        r_s0_io_out_s2_full_pred_1_fallThroughErr |= ~r_g_io_out_s2_full_pred_1_fallThroughErr;
        checks++;
        if (r_g_io_out_s2_full_pred_1_is_jal !== r_i_io_out_s2_full_pred_1_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_is_jal g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_is_jal, r_i_io_out_s2_full_pred_1_is_jal);
        end
        r_s1_io_out_s2_full_pred_1_is_jal |= r_g_io_out_s2_full_pred_1_is_jal;
        r_s0_io_out_s2_full_pred_1_is_jal |= ~r_g_io_out_s2_full_pred_1_is_jal;
        checks++;
        if (r_g_io_out_s2_full_pred_1_is_jalr !== r_i_io_out_s2_full_pred_1_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_is_jalr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_is_jalr, r_i_io_out_s2_full_pred_1_is_jalr);
        end
        r_s1_io_out_s2_full_pred_1_is_jalr |= r_g_io_out_s2_full_pred_1_is_jalr;
        r_s0_io_out_s2_full_pred_1_is_jalr |= ~r_g_io_out_s2_full_pred_1_is_jalr;
        checks++;
        if (r_g_io_out_s2_full_pred_1_is_call !== r_i_io_out_s2_full_pred_1_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_is_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_is_call, r_i_io_out_s2_full_pred_1_is_call);
        end
        r_s1_io_out_s2_full_pred_1_is_call |= r_g_io_out_s2_full_pred_1_is_call;
        r_s0_io_out_s2_full_pred_1_is_call |= ~r_g_io_out_s2_full_pred_1_is_call;
        checks++;
        if (r_g_io_out_s2_full_pred_1_is_ret !== r_i_io_out_s2_full_pred_1_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_is_ret g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_is_ret, r_i_io_out_s2_full_pred_1_is_ret);
        end
        r_s1_io_out_s2_full_pred_1_is_ret |= r_g_io_out_s2_full_pred_1_is_ret;
        r_s0_io_out_s2_full_pred_1_is_ret |= ~r_g_io_out_s2_full_pred_1_is_ret;
        checks++;
        if (r_g_io_out_s2_full_pred_1_last_may_be_rvi_call !== r_i_io_out_s2_full_pred_1_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_last_may_be_rvi_call, r_i_io_out_s2_full_pred_1_last_may_be_rvi_call);
        end
        r_s1_io_out_s2_full_pred_1_last_may_be_rvi_call |= r_g_io_out_s2_full_pred_1_last_may_be_rvi_call;
        r_s0_io_out_s2_full_pred_1_last_may_be_rvi_call |= ~r_g_io_out_s2_full_pred_1_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s2_full_pred_1_is_br_sharing !== r_i_io_out_s2_full_pred_1_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_is_br_sharing, r_i_io_out_s2_full_pred_1_is_br_sharing);
        end
        r_s1_io_out_s2_full_pred_1_is_br_sharing |= r_g_io_out_s2_full_pred_1_is_br_sharing;
        r_s0_io_out_s2_full_pred_1_is_br_sharing |= ~r_g_io_out_s2_full_pred_1_is_br_sharing;
        checks++;
        if (r_g_io_out_s2_full_pred_1_hit !== r_i_io_out_s2_full_pred_1_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_1_hit g=%h i=%h", cyc, r_g_io_out_s2_full_pred_1_hit, r_i_io_out_s2_full_pred_1_hit);
        end
        r_s1_io_out_s2_full_pred_1_hit |= r_g_io_out_s2_full_pred_1_hit;
        r_s0_io_out_s2_full_pred_1_hit |= ~r_g_io_out_s2_full_pred_1_hit;
        checks++;
        if (r_g_io_out_s2_full_pred_2_br_taken_mask_0 !== r_i_io_out_s2_full_pred_2_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_br_taken_mask_0, r_i_io_out_s2_full_pred_2_br_taken_mask_0);
        end
        r_s1_io_out_s2_full_pred_2_br_taken_mask_0 |= r_g_io_out_s2_full_pred_2_br_taken_mask_0;
        r_s0_io_out_s2_full_pred_2_br_taken_mask_0 |= ~r_g_io_out_s2_full_pred_2_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s2_full_pred_2_br_taken_mask_1 !== r_i_io_out_s2_full_pred_2_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_br_taken_mask_1, r_i_io_out_s2_full_pred_2_br_taken_mask_1);
        end
        r_s1_io_out_s2_full_pred_2_br_taken_mask_1 |= r_g_io_out_s2_full_pred_2_br_taken_mask_1;
        r_s0_io_out_s2_full_pred_2_br_taken_mask_1 |= ~r_g_io_out_s2_full_pred_2_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s2_full_pred_2_slot_valids_0 !== r_i_io_out_s2_full_pred_2_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_slot_valids_0, r_i_io_out_s2_full_pred_2_slot_valids_0);
        end
        r_s1_io_out_s2_full_pred_2_slot_valids_0 |= r_g_io_out_s2_full_pred_2_slot_valids_0;
        r_s0_io_out_s2_full_pred_2_slot_valids_0 |= ~r_g_io_out_s2_full_pred_2_slot_valids_0;
        checks++;
        if (r_g_io_out_s2_full_pred_2_slot_valids_1 !== r_i_io_out_s2_full_pred_2_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_slot_valids_1, r_i_io_out_s2_full_pred_2_slot_valids_1);
        end
        r_s1_io_out_s2_full_pred_2_slot_valids_1 |= r_g_io_out_s2_full_pred_2_slot_valids_1;
        r_s0_io_out_s2_full_pred_2_slot_valids_1 |= ~r_g_io_out_s2_full_pred_2_slot_valids_1;
        checks++;
        if (r_g_io_out_s2_full_pred_2_targets_0 !== r_i_io_out_s2_full_pred_2_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_targets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_targets_0, r_i_io_out_s2_full_pred_2_targets_0);
        end
        r_s1_io_out_s2_full_pred_2_targets_0 |= r_g_io_out_s2_full_pred_2_targets_0;
        r_s0_io_out_s2_full_pred_2_targets_0 |= ~r_g_io_out_s2_full_pred_2_targets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_2_targets_1 !== r_i_io_out_s2_full_pred_2_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_targets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_targets_1, r_i_io_out_s2_full_pred_2_targets_1);
        end
        r_s1_io_out_s2_full_pred_2_targets_1 |= r_g_io_out_s2_full_pred_2_targets_1;
        r_s0_io_out_s2_full_pred_2_targets_1 |= ~r_g_io_out_s2_full_pred_2_targets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_2_jalr_target !== r_i_io_out_s2_full_pred_2_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_jalr_target g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_jalr_target, r_i_io_out_s2_full_pred_2_jalr_target);
        end
        r_s1_io_out_s2_full_pred_2_jalr_target |= r_g_io_out_s2_full_pred_2_jalr_target;
        r_s0_io_out_s2_full_pred_2_jalr_target |= ~r_g_io_out_s2_full_pred_2_jalr_target;
        checks++;
        if (r_g_io_out_s2_full_pred_2_offsets_0 !== r_i_io_out_s2_full_pred_2_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_offsets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_offsets_0, r_i_io_out_s2_full_pred_2_offsets_0);
        end
        r_s1_io_out_s2_full_pred_2_offsets_0 |= r_g_io_out_s2_full_pred_2_offsets_0;
        r_s0_io_out_s2_full_pred_2_offsets_0 |= ~r_g_io_out_s2_full_pred_2_offsets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_2_offsets_1 !== r_i_io_out_s2_full_pred_2_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_offsets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_offsets_1, r_i_io_out_s2_full_pred_2_offsets_1);
        end
        r_s1_io_out_s2_full_pred_2_offsets_1 |= r_g_io_out_s2_full_pred_2_offsets_1;
        r_s0_io_out_s2_full_pred_2_offsets_1 |= ~r_g_io_out_s2_full_pred_2_offsets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_2_fallThroughAddr !== r_i_io_out_s2_full_pred_2_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_fallThroughAddr, r_i_io_out_s2_full_pred_2_fallThroughAddr);
        end
        r_s1_io_out_s2_full_pred_2_fallThroughAddr |= r_g_io_out_s2_full_pred_2_fallThroughAddr;
        r_s0_io_out_s2_full_pred_2_fallThroughAddr |= ~r_g_io_out_s2_full_pred_2_fallThroughAddr;
        checks++;
        if (r_g_io_out_s2_full_pred_2_fallThroughErr !== r_i_io_out_s2_full_pred_2_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_fallThroughErr, r_i_io_out_s2_full_pred_2_fallThroughErr);
        end
        r_s1_io_out_s2_full_pred_2_fallThroughErr |= r_g_io_out_s2_full_pred_2_fallThroughErr;
        r_s0_io_out_s2_full_pred_2_fallThroughErr |= ~r_g_io_out_s2_full_pred_2_fallThroughErr;
        checks++;
        if (r_g_io_out_s2_full_pred_2_is_jal !== r_i_io_out_s2_full_pred_2_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_is_jal g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_is_jal, r_i_io_out_s2_full_pred_2_is_jal);
        end
        r_s1_io_out_s2_full_pred_2_is_jal |= r_g_io_out_s2_full_pred_2_is_jal;
        r_s0_io_out_s2_full_pred_2_is_jal |= ~r_g_io_out_s2_full_pred_2_is_jal;
        checks++;
        if (r_g_io_out_s2_full_pred_2_is_jalr !== r_i_io_out_s2_full_pred_2_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_is_jalr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_is_jalr, r_i_io_out_s2_full_pred_2_is_jalr);
        end
        r_s1_io_out_s2_full_pred_2_is_jalr |= r_g_io_out_s2_full_pred_2_is_jalr;
        r_s0_io_out_s2_full_pred_2_is_jalr |= ~r_g_io_out_s2_full_pred_2_is_jalr;
        checks++;
        if (r_g_io_out_s2_full_pred_2_is_call !== r_i_io_out_s2_full_pred_2_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_is_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_is_call, r_i_io_out_s2_full_pred_2_is_call);
        end
        r_s1_io_out_s2_full_pred_2_is_call |= r_g_io_out_s2_full_pred_2_is_call;
        r_s0_io_out_s2_full_pred_2_is_call |= ~r_g_io_out_s2_full_pred_2_is_call;
        checks++;
        if (r_g_io_out_s2_full_pred_2_is_ret !== r_i_io_out_s2_full_pred_2_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_is_ret g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_is_ret, r_i_io_out_s2_full_pred_2_is_ret);
        end
        r_s1_io_out_s2_full_pred_2_is_ret |= r_g_io_out_s2_full_pred_2_is_ret;
        r_s0_io_out_s2_full_pred_2_is_ret |= ~r_g_io_out_s2_full_pred_2_is_ret;
        checks++;
        if (r_g_io_out_s2_full_pred_2_last_may_be_rvi_call !== r_i_io_out_s2_full_pred_2_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_last_may_be_rvi_call, r_i_io_out_s2_full_pred_2_last_may_be_rvi_call);
        end
        r_s1_io_out_s2_full_pred_2_last_may_be_rvi_call |= r_g_io_out_s2_full_pred_2_last_may_be_rvi_call;
        r_s0_io_out_s2_full_pred_2_last_may_be_rvi_call |= ~r_g_io_out_s2_full_pred_2_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s2_full_pred_2_is_br_sharing !== r_i_io_out_s2_full_pred_2_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_is_br_sharing, r_i_io_out_s2_full_pred_2_is_br_sharing);
        end
        r_s1_io_out_s2_full_pred_2_is_br_sharing |= r_g_io_out_s2_full_pred_2_is_br_sharing;
        r_s0_io_out_s2_full_pred_2_is_br_sharing |= ~r_g_io_out_s2_full_pred_2_is_br_sharing;
        checks++;
        if (r_g_io_out_s2_full_pred_2_hit !== r_i_io_out_s2_full_pred_2_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_2_hit g=%h i=%h", cyc, r_g_io_out_s2_full_pred_2_hit, r_i_io_out_s2_full_pred_2_hit);
        end
        r_s1_io_out_s2_full_pred_2_hit |= r_g_io_out_s2_full_pred_2_hit;
        r_s0_io_out_s2_full_pred_2_hit |= ~r_g_io_out_s2_full_pred_2_hit;
        checks++;
        if (r_g_io_out_s2_full_pred_3_br_taken_mask_0 !== r_i_io_out_s2_full_pred_3_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_br_taken_mask_0, r_i_io_out_s2_full_pred_3_br_taken_mask_0);
        end
        r_s1_io_out_s2_full_pred_3_br_taken_mask_0 |= r_g_io_out_s2_full_pred_3_br_taken_mask_0;
        r_s0_io_out_s2_full_pred_3_br_taken_mask_0 |= ~r_g_io_out_s2_full_pred_3_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s2_full_pred_3_br_taken_mask_1 !== r_i_io_out_s2_full_pred_3_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_br_taken_mask_1, r_i_io_out_s2_full_pred_3_br_taken_mask_1);
        end
        r_s1_io_out_s2_full_pred_3_br_taken_mask_1 |= r_g_io_out_s2_full_pred_3_br_taken_mask_1;
        r_s0_io_out_s2_full_pred_3_br_taken_mask_1 |= ~r_g_io_out_s2_full_pred_3_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s2_full_pred_3_slot_valids_0 !== r_i_io_out_s2_full_pred_3_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_slot_valids_0, r_i_io_out_s2_full_pred_3_slot_valids_0);
        end
        r_s1_io_out_s2_full_pred_3_slot_valids_0 |= r_g_io_out_s2_full_pred_3_slot_valids_0;
        r_s0_io_out_s2_full_pred_3_slot_valids_0 |= ~r_g_io_out_s2_full_pred_3_slot_valids_0;
        checks++;
        if (r_g_io_out_s2_full_pred_3_slot_valids_1 !== r_i_io_out_s2_full_pred_3_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_slot_valids_1, r_i_io_out_s2_full_pred_3_slot_valids_1);
        end
        r_s1_io_out_s2_full_pred_3_slot_valids_1 |= r_g_io_out_s2_full_pred_3_slot_valids_1;
        r_s0_io_out_s2_full_pred_3_slot_valids_1 |= ~r_g_io_out_s2_full_pred_3_slot_valids_1;
        checks++;
        if (r_g_io_out_s2_full_pred_3_targets_0 !== r_i_io_out_s2_full_pred_3_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_targets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_targets_0, r_i_io_out_s2_full_pred_3_targets_0);
        end
        r_s1_io_out_s2_full_pred_3_targets_0 |= r_g_io_out_s2_full_pred_3_targets_0;
        r_s0_io_out_s2_full_pred_3_targets_0 |= ~r_g_io_out_s2_full_pred_3_targets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_3_targets_1 !== r_i_io_out_s2_full_pred_3_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_targets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_targets_1, r_i_io_out_s2_full_pred_3_targets_1);
        end
        r_s1_io_out_s2_full_pred_3_targets_1 |= r_g_io_out_s2_full_pred_3_targets_1;
        r_s0_io_out_s2_full_pred_3_targets_1 |= ~r_g_io_out_s2_full_pred_3_targets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_3_jalr_target !== r_i_io_out_s2_full_pred_3_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_jalr_target g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_jalr_target, r_i_io_out_s2_full_pred_3_jalr_target);
        end
        r_s1_io_out_s2_full_pred_3_jalr_target |= r_g_io_out_s2_full_pred_3_jalr_target;
        r_s0_io_out_s2_full_pred_3_jalr_target |= ~r_g_io_out_s2_full_pred_3_jalr_target;
        checks++;
        if (r_g_io_out_s2_full_pred_3_offsets_0 !== r_i_io_out_s2_full_pred_3_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_offsets_0 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_offsets_0, r_i_io_out_s2_full_pred_3_offsets_0);
        end
        r_s1_io_out_s2_full_pred_3_offsets_0 |= r_g_io_out_s2_full_pred_3_offsets_0;
        r_s0_io_out_s2_full_pred_3_offsets_0 |= ~r_g_io_out_s2_full_pred_3_offsets_0;
        checks++;
        if (r_g_io_out_s2_full_pred_3_offsets_1 !== r_i_io_out_s2_full_pred_3_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_offsets_1 g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_offsets_1, r_i_io_out_s2_full_pred_3_offsets_1);
        end
        r_s1_io_out_s2_full_pred_3_offsets_1 |= r_g_io_out_s2_full_pred_3_offsets_1;
        r_s0_io_out_s2_full_pred_3_offsets_1 |= ~r_g_io_out_s2_full_pred_3_offsets_1;
        checks++;
        if (r_g_io_out_s2_full_pred_3_fallThroughAddr !== r_i_io_out_s2_full_pred_3_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_fallThroughAddr, r_i_io_out_s2_full_pred_3_fallThroughAddr);
        end
        r_s1_io_out_s2_full_pred_3_fallThroughAddr |= r_g_io_out_s2_full_pred_3_fallThroughAddr;
        r_s0_io_out_s2_full_pred_3_fallThroughAddr |= ~r_g_io_out_s2_full_pred_3_fallThroughAddr;
        checks++;
        if (r_g_io_out_s2_full_pred_3_fallThroughErr !== r_i_io_out_s2_full_pred_3_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_fallThroughErr, r_i_io_out_s2_full_pred_3_fallThroughErr);
        end
        r_s1_io_out_s2_full_pred_3_fallThroughErr |= r_g_io_out_s2_full_pred_3_fallThroughErr;
        r_s0_io_out_s2_full_pred_3_fallThroughErr |= ~r_g_io_out_s2_full_pred_3_fallThroughErr;
        checks++;
        if (r_g_io_out_s2_full_pred_3_is_jal !== r_i_io_out_s2_full_pred_3_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_is_jal g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_is_jal, r_i_io_out_s2_full_pred_3_is_jal);
        end
        r_s1_io_out_s2_full_pred_3_is_jal |= r_g_io_out_s2_full_pred_3_is_jal;
        r_s0_io_out_s2_full_pred_3_is_jal |= ~r_g_io_out_s2_full_pred_3_is_jal;
        checks++;
        if (r_g_io_out_s2_full_pred_3_is_jalr !== r_i_io_out_s2_full_pred_3_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_is_jalr g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_is_jalr, r_i_io_out_s2_full_pred_3_is_jalr);
        end
        r_s1_io_out_s2_full_pred_3_is_jalr |= r_g_io_out_s2_full_pred_3_is_jalr;
        r_s0_io_out_s2_full_pred_3_is_jalr |= ~r_g_io_out_s2_full_pred_3_is_jalr;
        checks++;
        if (r_g_io_out_s2_full_pred_3_is_call !== r_i_io_out_s2_full_pred_3_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_is_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_is_call, r_i_io_out_s2_full_pred_3_is_call);
        end
        r_s1_io_out_s2_full_pred_3_is_call |= r_g_io_out_s2_full_pred_3_is_call;
        r_s0_io_out_s2_full_pred_3_is_call |= ~r_g_io_out_s2_full_pred_3_is_call;
        checks++;
        if (r_g_io_out_s2_full_pred_3_is_ret !== r_i_io_out_s2_full_pred_3_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_is_ret g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_is_ret, r_i_io_out_s2_full_pred_3_is_ret);
        end
        r_s1_io_out_s2_full_pred_3_is_ret |= r_g_io_out_s2_full_pred_3_is_ret;
        r_s0_io_out_s2_full_pred_3_is_ret |= ~r_g_io_out_s2_full_pred_3_is_ret;
        checks++;
        if (r_g_io_out_s2_full_pred_3_last_may_be_rvi_call !== r_i_io_out_s2_full_pred_3_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_last_may_be_rvi_call, r_i_io_out_s2_full_pred_3_last_may_be_rvi_call);
        end
        r_s1_io_out_s2_full_pred_3_last_may_be_rvi_call |= r_g_io_out_s2_full_pred_3_last_may_be_rvi_call;
        r_s0_io_out_s2_full_pred_3_last_may_be_rvi_call |= ~r_g_io_out_s2_full_pred_3_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s2_full_pred_3_is_br_sharing !== r_i_io_out_s2_full_pred_3_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_is_br_sharing, r_i_io_out_s2_full_pred_3_is_br_sharing);
        end
        r_s1_io_out_s2_full_pred_3_is_br_sharing |= r_g_io_out_s2_full_pred_3_is_br_sharing;
        r_s0_io_out_s2_full_pred_3_is_br_sharing |= ~r_g_io_out_s2_full_pred_3_is_br_sharing;
        checks++;
        if (r_g_io_out_s2_full_pred_3_hit !== r_i_io_out_s2_full_pred_3_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s2_full_pred_3_hit g=%h i=%h", cyc, r_g_io_out_s2_full_pred_3_hit, r_i_io_out_s2_full_pred_3_hit);
        end
        r_s1_io_out_s2_full_pred_3_hit |= r_g_io_out_s2_full_pred_3_hit;
        r_s0_io_out_s2_full_pred_3_hit |= ~r_g_io_out_s2_full_pred_3_hit;
        checks++;
        if (r_g_io_out_s3_pc_0 !== r_i_io_out_s3_pc_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_pc_0 g=%h i=%h", cyc, r_g_io_out_s3_pc_0, r_i_io_out_s3_pc_0);
        end
        r_s1_io_out_s3_pc_0 |= r_g_io_out_s3_pc_0;
        r_s0_io_out_s3_pc_0 |= ~r_g_io_out_s3_pc_0;
        checks++;
        if (r_g_io_out_s3_pc_1 !== r_i_io_out_s3_pc_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_pc_1 g=%h i=%h", cyc, r_g_io_out_s3_pc_1, r_i_io_out_s3_pc_1);
        end
        r_s1_io_out_s3_pc_1 |= r_g_io_out_s3_pc_1;
        r_s0_io_out_s3_pc_1 |= ~r_g_io_out_s3_pc_1;
        checks++;
        if (r_g_io_out_s3_pc_2 !== r_i_io_out_s3_pc_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_pc_2 g=%h i=%h", cyc, r_g_io_out_s3_pc_2, r_i_io_out_s3_pc_2);
        end
        r_s1_io_out_s3_pc_2 |= r_g_io_out_s3_pc_2;
        r_s0_io_out_s3_pc_2 |= ~r_g_io_out_s3_pc_2;
        checks++;
        if (r_g_io_out_s3_pc_3 !== r_i_io_out_s3_pc_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_pc_3 g=%h i=%h", cyc, r_g_io_out_s3_pc_3, r_i_io_out_s3_pc_3);
        end
        r_s1_io_out_s3_pc_3 |= r_g_io_out_s3_pc_3;
        r_s0_io_out_s3_pc_3 |= ~r_g_io_out_s3_pc_3;
        checks++;
        if (r_g_io_out_s3_full_pred_0_br_taken_mask_0 !== r_i_io_out_s3_full_pred_0_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_br_taken_mask_0, r_i_io_out_s3_full_pred_0_br_taken_mask_0);
        end
        r_s1_io_out_s3_full_pred_0_br_taken_mask_0 |= r_g_io_out_s3_full_pred_0_br_taken_mask_0;
        r_s0_io_out_s3_full_pred_0_br_taken_mask_0 |= ~r_g_io_out_s3_full_pred_0_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s3_full_pred_0_br_taken_mask_1 !== r_i_io_out_s3_full_pred_0_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_br_taken_mask_1, r_i_io_out_s3_full_pred_0_br_taken_mask_1);
        end
        r_s1_io_out_s3_full_pred_0_br_taken_mask_1 |= r_g_io_out_s3_full_pred_0_br_taken_mask_1;
        r_s0_io_out_s3_full_pred_0_br_taken_mask_1 |= ~r_g_io_out_s3_full_pred_0_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s3_full_pred_0_slot_valids_0 !== r_i_io_out_s3_full_pred_0_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_slot_valids_0, r_i_io_out_s3_full_pred_0_slot_valids_0);
        end
        r_s1_io_out_s3_full_pred_0_slot_valids_0 |= r_g_io_out_s3_full_pred_0_slot_valids_0;
        r_s0_io_out_s3_full_pred_0_slot_valids_0 |= ~r_g_io_out_s3_full_pred_0_slot_valids_0;
        checks++;
        if (r_g_io_out_s3_full_pred_0_slot_valids_1 !== r_i_io_out_s3_full_pred_0_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_slot_valids_1, r_i_io_out_s3_full_pred_0_slot_valids_1);
        end
        r_s1_io_out_s3_full_pred_0_slot_valids_1 |= r_g_io_out_s3_full_pred_0_slot_valids_1;
        r_s0_io_out_s3_full_pred_0_slot_valids_1 |= ~r_g_io_out_s3_full_pred_0_slot_valids_1;
        checks++;
        if (r_g_io_out_s3_full_pred_0_targets_0 !== r_i_io_out_s3_full_pred_0_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_targets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_targets_0, r_i_io_out_s3_full_pred_0_targets_0);
        end
        r_s1_io_out_s3_full_pred_0_targets_0 |= r_g_io_out_s3_full_pred_0_targets_0;
        r_s0_io_out_s3_full_pred_0_targets_0 |= ~r_g_io_out_s3_full_pred_0_targets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_0_targets_1 !== r_i_io_out_s3_full_pred_0_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_targets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_targets_1, r_i_io_out_s3_full_pred_0_targets_1);
        end
        r_s1_io_out_s3_full_pred_0_targets_1 |= r_g_io_out_s3_full_pred_0_targets_1;
        r_s0_io_out_s3_full_pred_0_targets_1 |= ~r_g_io_out_s3_full_pred_0_targets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_0_jalr_target !== r_i_io_out_s3_full_pred_0_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_jalr_target g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_jalr_target, r_i_io_out_s3_full_pred_0_jalr_target);
        end
        r_s1_io_out_s3_full_pred_0_jalr_target |= r_g_io_out_s3_full_pred_0_jalr_target;
        r_s0_io_out_s3_full_pred_0_jalr_target |= ~r_g_io_out_s3_full_pred_0_jalr_target;
        checks++;
        if (r_g_io_out_s3_full_pred_0_offsets_0 !== r_i_io_out_s3_full_pred_0_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_offsets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_offsets_0, r_i_io_out_s3_full_pred_0_offsets_0);
        end
        r_s1_io_out_s3_full_pred_0_offsets_0 |= r_g_io_out_s3_full_pred_0_offsets_0;
        r_s0_io_out_s3_full_pred_0_offsets_0 |= ~r_g_io_out_s3_full_pred_0_offsets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_0_offsets_1 !== r_i_io_out_s3_full_pred_0_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_offsets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_offsets_1, r_i_io_out_s3_full_pred_0_offsets_1);
        end
        r_s1_io_out_s3_full_pred_0_offsets_1 |= r_g_io_out_s3_full_pred_0_offsets_1;
        r_s0_io_out_s3_full_pred_0_offsets_1 |= ~r_g_io_out_s3_full_pred_0_offsets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_0_fallThroughAddr !== r_i_io_out_s3_full_pred_0_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_fallThroughAddr, r_i_io_out_s3_full_pred_0_fallThroughAddr);
        end
        r_s1_io_out_s3_full_pred_0_fallThroughAddr |= r_g_io_out_s3_full_pred_0_fallThroughAddr;
        r_s0_io_out_s3_full_pred_0_fallThroughAddr |= ~r_g_io_out_s3_full_pred_0_fallThroughAddr;
        checks++;
        if (r_g_io_out_s3_full_pred_0_fallThroughErr !== r_i_io_out_s3_full_pred_0_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_fallThroughErr, r_i_io_out_s3_full_pred_0_fallThroughErr);
        end
        r_s1_io_out_s3_full_pred_0_fallThroughErr |= r_g_io_out_s3_full_pred_0_fallThroughErr;
        r_s0_io_out_s3_full_pred_0_fallThroughErr |= ~r_g_io_out_s3_full_pred_0_fallThroughErr;
        checks++;
        if (r_g_io_out_s3_full_pred_0_multiHit !== r_i_io_out_s3_full_pred_0_multiHit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_multiHit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_multiHit, r_i_io_out_s3_full_pred_0_multiHit);
        end
        r_s1_io_out_s3_full_pred_0_multiHit |= r_g_io_out_s3_full_pred_0_multiHit;
        r_s0_io_out_s3_full_pred_0_multiHit |= ~r_g_io_out_s3_full_pred_0_multiHit;
        checks++;
        if (r_g_io_out_s3_full_pred_0_is_jal !== r_i_io_out_s3_full_pred_0_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_is_jal g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_is_jal, r_i_io_out_s3_full_pred_0_is_jal);
        end
        r_s1_io_out_s3_full_pred_0_is_jal |= r_g_io_out_s3_full_pred_0_is_jal;
        r_s0_io_out_s3_full_pred_0_is_jal |= ~r_g_io_out_s3_full_pred_0_is_jal;
        checks++;
        if (r_g_io_out_s3_full_pred_0_is_jalr !== r_i_io_out_s3_full_pred_0_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_is_jalr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_is_jalr, r_i_io_out_s3_full_pred_0_is_jalr);
        end
        r_s1_io_out_s3_full_pred_0_is_jalr |= r_g_io_out_s3_full_pred_0_is_jalr;
        r_s0_io_out_s3_full_pred_0_is_jalr |= ~r_g_io_out_s3_full_pred_0_is_jalr;
        checks++;
        if (r_g_io_out_s3_full_pred_0_is_call !== r_i_io_out_s3_full_pred_0_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_is_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_is_call, r_i_io_out_s3_full_pred_0_is_call);
        end
        r_s1_io_out_s3_full_pred_0_is_call |= r_g_io_out_s3_full_pred_0_is_call;
        r_s0_io_out_s3_full_pred_0_is_call |= ~r_g_io_out_s3_full_pred_0_is_call;
        checks++;
        if (r_g_io_out_s3_full_pred_0_is_ret !== r_i_io_out_s3_full_pred_0_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_is_ret g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_is_ret, r_i_io_out_s3_full_pred_0_is_ret);
        end
        r_s1_io_out_s3_full_pred_0_is_ret |= r_g_io_out_s3_full_pred_0_is_ret;
        r_s0_io_out_s3_full_pred_0_is_ret |= ~r_g_io_out_s3_full_pred_0_is_ret;
        checks++;
        if (r_g_io_out_s3_full_pred_0_last_may_be_rvi_call !== r_i_io_out_s3_full_pred_0_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_last_may_be_rvi_call, r_i_io_out_s3_full_pred_0_last_may_be_rvi_call);
        end
        r_s1_io_out_s3_full_pred_0_last_may_be_rvi_call |= r_g_io_out_s3_full_pred_0_last_may_be_rvi_call;
        r_s0_io_out_s3_full_pred_0_last_may_be_rvi_call |= ~r_g_io_out_s3_full_pred_0_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s3_full_pred_0_is_br_sharing !== r_i_io_out_s3_full_pred_0_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_is_br_sharing, r_i_io_out_s3_full_pred_0_is_br_sharing);
        end
        r_s1_io_out_s3_full_pred_0_is_br_sharing |= r_g_io_out_s3_full_pred_0_is_br_sharing;
        r_s0_io_out_s3_full_pred_0_is_br_sharing |= ~r_g_io_out_s3_full_pred_0_is_br_sharing;
        checks++;
        if (r_g_io_out_s3_full_pred_0_hit !== r_i_io_out_s3_full_pred_0_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_0_hit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_0_hit, r_i_io_out_s3_full_pred_0_hit);
        end
        r_s1_io_out_s3_full_pred_0_hit |= r_g_io_out_s3_full_pred_0_hit;
        r_s0_io_out_s3_full_pred_0_hit |= ~r_g_io_out_s3_full_pred_0_hit;
        checks++;
        if (r_g_io_out_s3_full_pred_1_br_taken_mask_0 !== r_i_io_out_s3_full_pred_1_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_br_taken_mask_0, r_i_io_out_s3_full_pred_1_br_taken_mask_0);
        end
        r_s1_io_out_s3_full_pred_1_br_taken_mask_0 |= r_g_io_out_s3_full_pred_1_br_taken_mask_0;
        r_s0_io_out_s3_full_pred_1_br_taken_mask_0 |= ~r_g_io_out_s3_full_pred_1_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s3_full_pred_1_br_taken_mask_1 !== r_i_io_out_s3_full_pred_1_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_br_taken_mask_1, r_i_io_out_s3_full_pred_1_br_taken_mask_1);
        end
        r_s1_io_out_s3_full_pred_1_br_taken_mask_1 |= r_g_io_out_s3_full_pred_1_br_taken_mask_1;
        r_s0_io_out_s3_full_pred_1_br_taken_mask_1 |= ~r_g_io_out_s3_full_pred_1_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s3_full_pred_1_slot_valids_0 !== r_i_io_out_s3_full_pred_1_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_slot_valids_0, r_i_io_out_s3_full_pred_1_slot_valids_0);
        end
        r_s1_io_out_s3_full_pred_1_slot_valids_0 |= r_g_io_out_s3_full_pred_1_slot_valids_0;
        r_s0_io_out_s3_full_pred_1_slot_valids_0 |= ~r_g_io_out_s3_full_pred_1_slot_valids_0;
        checks++;
        if (r_g_io_out_s3_full_pred_1_slot_valids_1 !== r_i_io_out_s3_full_pred_1_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_slot_valids_1, r_i_io_out_s3_full_pred_1_slot_valids_1);
        end
        r_s1_io_out_s3_full_pred_1_slot_valids_1 |= r_g_io_out_s3_full_pred_1_slot_valids_1;
        r_s0_io_out_s3_full_pred_1_slot_valids_1 |= ~r_g_io_out_s3_full_pred_1_slot_valids_1;
        checks++;
        if (r_g_io_out_s3_full_pred_1_targets_0 !== r_i_io_out_s3_full_pred_1_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_targets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_targets_0, r_i_io_out_s3_full_pred_1_targets_0);
        end
        r_s1_io_out_s3_full_pred_1_targets_0 |= r_g_io_out_s3_full_pred_1_targets_0;
        r_s0_io_out_s3_full_pred_1_targets_0 |= ~r_g_io_out_s3_full_pred_1_targets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_1_targets_1 !== r_i_io_out_s3_full_pred_1_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_targets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_targets_1, r_i_io_out_s3_full_pred_1_targets_1);
        end
        r_s1_io_out_s3_full_pred_1_targets_1 |= r_g_io_out_s3_full_pred_1_targets_1;
        r_s0_io_out_s3_full_pred_1_targets_1 |= ~r_g_io_out_s3_full_pred_1_targets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_1_jalr_target !== r_i_io_out_s3_full_pred_1_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_jalr_target g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_jalr_target, r_i_io_out_s3_full_pred_1_jalr_target);
        end
        r_s1_io_out_s3_full_pred_1_jalr_target |= r_g_io_out_s3_full_pred_1_jalr_target;
        r_s0_io_out_s3_full_pred_1_jalr_target |= ~r_g_io_out_s3_full_pred_1_jalr_target;
        checks++;
        if (r_g_io_out_s3_full_pred_1_offsets_0 !== r_i_io_out_s3_full_pred_1_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_offsets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_offsets_0, r_i_io_out_s3_full_pred_1_offsets_0);
        end
        r_s1_io_out_s3_full_pred_1_offsets_0 |= r_g_io_out_s3_full_pred_1_offsets_0;
        r_s0_io_out_s3_full_pred_1_offsets_0 |= ~r_g_io_out_s3_full_pred_1_offsets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_1_offsets_1 !== r_i_io_out_s3_full_pred_1_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_offsets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_offsets_1, r_i_io_out_s3_full_pred_1_offsets_1);
        end
        r_s1_io_out_s3_full_pred_1_offsets_1 |= r_g_io_out_s3_full_pred_1_offsets_1;
        r_s0_io_out_s3_full_pred_1_offsets_1 |= ~r_g_io_out_s3_full_pred_1_offsets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_1_fallThroughAddr !== r_i_io_out_s3_full_pred_1_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_fallThroughAddr, r_i_io_out_s3_full_pred_1_fallThroughAddr);
        end
        r_s1_io_out_s3_full_pred_1_fallThroughAddr |= r_g_io_out_s3_full_pred_1_fallThroughAddr;
        r_s0_io_out_s3_full_pred_1_fallThroughAddr |= ~r_g_io_out_s3_full_pred_1_fallThroughAddr;
        checks++;
        if (r_g_io_out_s3_full_pred_1_fallThroughErr !== r_i_io_out_s3_full_pred_1_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_fallThroughErr, r_i_io_out_s3_full_pred_1_fallThroughErr);
        end
        r_s1_io_out_s3_full_pred_1_fallThroughErr |= r_g_io_out_s3_full_pred_1_fallThroughErr;
        r_s0_io_out_s3_full_pred_1_fallThroughErr |= ~r_g_io_out_s3_full_pred_1_fallThroughErr;
        checks++;
        if (r_g_io_out_s3_full_pred_1_multiHit !== r_i_io_out_s3_full_pred_1_multiHit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_multiHit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_multiHit, r_i_io_out_s3_full_pred_1_multiHit);
        end
        r_s1_io_out_s3_full_pred_1_multiHit |= r_g_io_out_s3_full_pred_1_multiHit;
        r_s0_io_out_s3_full_pred_1_multiHit |= ~r_g_io_out_s3_full_pred_1_multiHit;
        checks++;
        if (r_g_io_out_s3_full_pred_1_is_jal !== r_i_io_out_s3_full_pred_1_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_is_jal g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_is_jal, r_i_io_out_s3_full_pred_1_is_jal);
        end
        r_s1_io_out_s3_full_pred_1_is_jal |= r_g_io_out_s3_full_pred_1_is_jal;
        r_s0_io_out_s3_full_pred_1_is_jal |= ~r_g_io_out_s3_full_pred_1_is_jal;
        checks++;
        if (r_g_io_out_s3_full_pred_1_is_jalr !== r_i_io_out_s3_full_pred_1_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_is_jalr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_is_jalr, r_i_io_out_s3_full_pred_1_is_jalr);
        end
        r_s1_io_out_s3_full_pred_1_is_jalr |= r_g_io_out_s3_full_pred_1_is_jalr;
        r_s0_io_out_s3_full_pred_1_is_jalr |= ~r_g_io_out_s3_full_pred_1_is_jalr;
        checks++;
        if (r_g_io_out_s3_full_pred_1_is_call !== r_i_io_out_s3_full_pred_1_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_is_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_is_call, r_i_io_out_s3_full_pred_1_is_call);
        end
        r_s1_io_out_s3_full_pred_1_is_call |= r_g_io_out_s3_full_pred_1_is_call;
        r_s0_io_out_s3_full_pred_1_is_call |= ~r_g_io_out_s3_full_pred_1_is_call;
        checks++;
        if (r_g_io_out_s3_full_pred_1_is_ret !== r_i_io_out_s3_full_pred_1_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_is_ret g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_is_ret, r_i_io_out_s3_full_pred_1_is_ret);
        end
        r_s1_io_out_s3_full_pred_1_is_ret |= r_g_io_out_s3_full_pred_1_is_ret;
        r_s0_io_out_s3_full_pred_1_is_ret |= ~r_g_io_out_s3_full_pred_1_is_ret;
        checks++;
        if (r_g_io_out_s3_full_pred_1_last_may_be_rvi_call !== r_i_io_out_s3_full_pred_1_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_last_may_be_rvi_call, r_i_io_out_s3_full_pred_1_last_may_be_rvi_call);
        end
        r_s1_io_out_s3_full_pred_1_last_may_be_rvi_call |= r_g_io_out_s3_full_pred_1_last_may_be_rvi_call;
        r_s0_io_out_s3_full_pred_1_last_may_be_rvi_call |= ~r_g_io_out_s3_full_pred_1_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s3_full_pred_1_is_br_sharing !== r_i_io_out_s3_full_pred_1_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_is_br_sharing, r_i_io_out_s3_full_pred_1_is_br_sharing);
        end
        r_s1_io_out_s3_full_pred_1_is_br_sharing |= r_g_io_out_s3_full_pred_1_is_br_sharing;
        r_s0_io_out_s3_full_pred_1_is_br_sharing |= ~r_g_io_out_s3_full_pred_1_is_br_sharing;
        checks++;
        if (r_g_io_out_s3_full_pred_1_hit !== r_i_io_out_s3_full_pred_1_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_1_hit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_1_hit, r_i_io_out_s3_full_pred_1_hit);
        end
        r_s1_io_out_s3_full_pred_1_hit |= r_g_io_out_s3_full_pred_1_hit;
        r_s0_io_out_s3_full_pred_1_hit |= ~r_g_io_out_s3_full_pred_1_hit;
        checks++;
        if (r_g_io_out_s3_full_pred_2_br_taken_mask_0 !== r_i_io_out_s3_full_pred_2_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_br_taken_mask_0, r_i_io_out_s3_full_pred_2_br_taken_mask_0);
        end
        r_s1_io_out_s3_full_pred_2_br_taken_mask_0 |= r_g_io_out_s3_full_pred_2_br_taken_mask_0;
        r_s0_io_out_s3_full_pred_2_br_taken_mask_0 |= ~r_g_io_out_s3_full_pred_2_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s3_full_pred_2_br_taken_mask_1 !== r_i_io_out_s3_full_pred_2_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_br_taken_mask_1, r_i_io_out_s3_full_pred_2_br_taken_mask_1);
        end
        r_s1_io_out_s3_full_pred_2_br_taken_mask_1 |= r_g_io_out_s3_full_pred_2_br_taken_mask_1;
        r_s0_io_out_s3_full_pred_2_br_taken_mask_1 |= ~r_g_io_out_s3_full_pred_2_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s3_full_pred_2_slot_valids_0 !== r_i_io_out_s3_full_pred_2_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_slot_valids_0, r_i_io_out_s3_full_pred_2_slot_valids_0);
        end
        r_s1_io_out_s3_full_pred_2_slot_valids_0 |= r_g_io_out_s3_full_pred_2_slot_valids_0;
        r_s0_io_out_s3_full_pred_2_slot_valids_0 |= ~r_g_io_out_s3_full_pred_2_slot_valids_0;
        checks++;
        if (r_g_io_out_s3_full_pred_2_slot_valids_1 !== r_i_io_out_s3_full_pred_2_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_slot_valids_1, r_i_io_out_s3_full_pred_2_slot_valids_1);
        end
        r_s1_io_out_s3_full_pred_2_slot_valids_1 |= r_g_io_out_s3_full_pred_2_slot_valids_1;
        r_s0_io_out_s3_full_pred_2_slot_valids_1 |= ~r_g_io_out_s3_full_pred_2_slot_valids_1;
        checks++;
        if (r_g_io_out_s3_full_pred_2_targets_0 !== r_i_io_out_s3_full_pred_2_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_targets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_targets_0, r_i_io_out_s3_full_pred_2_targets_0);
        end
        r_s1_io_out_s3_full_pred_2_targets_0 |= r_g_io_out_s3_full_pred_2_targets_0;
        r_s0_io_out_s3_full_pred_2_targets_0 |= ~r_g_io_out_s3_full_pred_2_targets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_2_targets_1 !== r_i_io_out_s3_full_pred_2_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_targets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_targets_1, r_i_io_out_s3_full_pred_2_targets_1);
        end
        r_s1_io_out_s3_full_pred_2_targets_1 |= r_g_io_out_s3_full_pred_2_targets_1;
        r_s0_io_out_s3_full_pred_2_targets_1 |= ~r_g_io_out_s3_full_pred_2_targets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_2_jalr_target !== r_i_io_out_s3_full_pred_2_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_jalr_target g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_jalr_target, r_i_io_out_s3_full_pred_2_jalr_target);
        end
        r_s1_io_out_s3_full_pred_2_jalr_target |= r_g_io_out_s3_full_pred_2_jalr_target;
        r_s0_io_out_s3_full_pred_2_jalr_target |= ~r_g_io_out_s3_full_pred_2_jalr_target;
        checks++;
        if (r_g_io_out_s3_full_pred_2_offsets_0 !== r_i_io_out_s3_full_pred_2_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_offsets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_offsets_0, r_i_io_out_s3_full_pred_2_offsets_0);
        end
        r_s1_io_out_s3_full_pred_2_offsets_0 |= r_g_io_out_s3_full_pred_2_offsets_0;
        r_s0_io_out_s3_full_pred_2_offsets_0 |= ~r_g_io_out_s3_full_pred_2_offsets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_2_offsets_1 !== r_i_io_out_s3_full_pred_2_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_offsets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_offsets_1, r_i_io_out_s3_full_pred_2_offsets_1);
        end
        r_s1_io_out_s3_full_pred_2_offsets_1 |= r_g_io_out_s3_full_pred_2_offsets_1;
        r_s0_io_out_s3_full_pred_2_offsets_1 |= ~r_g_io_out_s3_full_pred_2_offsets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_2_fallThroughAddr !== r_i_io_out_s3_full_pred_2_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_fallThroughAddr, r_i_io_out_s3_full_pred_2_fallThroughAddr);
        end
        r_s1_io_out_s3_full_pred_2_fallThroughAddr |= r_g_io_out_s3_full_pred_2_fallThroughAddr;
        r_s0_io_out_s3_full_pred_2_fallThroughAddr |= ~r_g_io_out_s3_full_pred_2_fallThroughAddr;
        checks++;
        if (r_g_io_out_s3_full_pred_2_fallThroughErr !== r_i_io_out_s3_full_pred_2_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_fallThroughErr, r_i_io_out_s3_full_pred_2_fallThroughErr);
        end
        r_s1_io_out_s3_full_pred_2_fallThroughErr |= r_g_io_out_s3_full_pred_2_fallThroughErr;
        r_s0_io_out_s3_full_pred_2_fallThroughErr |= ~r_g_io_out_s3_full_pred_2_fallThroughErr;
        checks++;
        if (r_g_io_out_s3_full_pred_2_multiHit !== r_i_io_out_s3_full_pred_2_multiHit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_multiHit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_multiHit, r_i_io_out_s3_full_pred_2_multiHit);
        end
        r_s1_io_out_s3_full_pred_2_multiHit |= r_g_io_out_s3_full_pred_2_multiHit;
        r_s0_io_out_s3_full_pred_2_multiHit |= ~r_g_io_out_s3_full_pred_2_multiHit;
        checks++;
        if (r_g_io_out_s3_full_pred_2_is_jal !== r_i_io_out_s3_full_pred_2_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_is_jal g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_is_jal, r_i_io_out_s3_full_pred_2_is_jal);
        end
        r_s1_io_out_s3_full_pred_2_is_jal |= r_g_io_out_s3_full_pred_2_is_jal;
        r_s0_io_out_s3_full_pred_2_is_jal |= ~r_g_io_out_s3_full_pred_2_is_jal;
        checks++;
        if (r_g_io_out_s3_full_pred_2_is_jalr !== r_i_io_out_s3_full_pred_2_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_is_jalr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_is_jalr, r_i_io_out_s3_full_pred_2_is_jalr);
        end
        r_s1_io_out_s3_full_pred_2_is_jalr |= r_g_io_out_s3_full_pred_2_is_jalr;
        r_s0_io_out_s3_full_pred_2_is_jalr |= ~r_g_io_out_s3_full_pred_2_is_jalr;
        checks++;
        if (r_g_io_out_s3_full_pred_2_is_call !== r_i_io_out_s3_full_pred_2_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_is_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_is_call, r_i_io_out_s3_full_pred_2_is_call);
        end
        r_s1_io_out_s3_full_pred_2_is_call |= r_g_io_out_s3_full_pred_2_is_call;
        r_s0_io_out_s3_full_pred_2_is_call |= ~r_g_io_out_s3_full_pred_2_is_call;
        checks++;
        if (r_g_io_out_s3_full_pred_2_is_ret !== r_i_io_out_s3_full_pred_2_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_is_ret g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_is_ret, r_i_io_out_s3_full_pred_2_is_ret);
        end
        r_s1_io_out_s3_full_pred_2_is_ret |= r_g_io_out_s3_full_pred_2_is_ret;
        r_s0_io_out_s3_full_pred_2_is_ret |= ~r_g_io_out_s3_full_pred_2_is_ret;
        checks++;
        if (r_g_io_out_s3_full_pred_2_last_may_be_rvi_call !== r_i_io_out_s3_full_pred_2_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_last_may_be_rvi_call, r_i_io_out_s3_full_pred_2_last_may_be_rvi_call);
        end
        r_s1_io_out_s3_full_pred_2_last_may_be_rvi_call |= r_g_io_out_s3_full_pred_2_last_may_be_rvi_call;
        r_s0_io_out_s3_full_pred_2_last_may_be_rvi_call |= ~r_g_io_out_s3_full_pred_2_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s3_full_pred_2_is_br_sharing !== r_i_io_out_s3_full_pred_2_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_is_br_sharing, r_i_io_out_s3_full_pred_2_is_br_sharing);
        end
        r_s1_io_out_s3_full_pred_2_is_br_sharing |= r_g_io_out_s3_full_pred_2_is_br_sharing;
        r_s0_io_out_s3_full_pred_2_is_br_sharing |= ~r_g_io_out_s3_full_pred_2_is_br_sharing;
        checks++;
        if (r_g_io_out_s3_full_pred_2_hit !== r_i_io_out_s3_full_pred_2_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_2_hit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_2_hit, r_i_io_out_s3_full_pred_2_hit);
        end
        r_s1_io_out_s3_full_pred_2_hit |= r_g_io_out_s3_full_pred_2_hit;
        r_s0_io_out_s3_full_pred_2_hit |= ~r_g_io_out_s3_full_pred_2_hit;
        checks++;
        if (r_g_io_out_s3_full_pred_3_br_taken_mask_0 !== r_i_io_out_s3_full_pred_3_br_taken_mask_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_br_taken_mask_0, r_i_io_out_s3_full_pred_3_br_taken_mask_0);
        end
        r_s1_io_out_s3_full_pred_3_br_taken_mask_0 |= r_g_io_out_s3_full_pred_3_br_taken_mask_0;
        r_s0_io_out_s3_full_pred_3_br_taken_mask_0 |= ~r_g_io_out_s3_full_pred_3_br_taken_mask_0;
        checks++;
        if (r_g_io_out_s3_full_pred_3_br_taken_mask_1 !== r_i_io_out_s3_full_pred_3_br_taken_mask_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_br_taken_mask_1, r_i_io_out_s3_full_pred_3_br_taken_mask_1);
        end
        r_s1_io_out_s3_full_pred_3_br_taken_mask_1 |= r_g_io_out_s3_full_pred_3_br_taken_mask_1;
        r_s0_io_out_s3_full_pred_3_br_taken_mask_1 |= ~r_g_io_out_s3_full_pred_3_br_taken_mask_1;
        checks++;
        if (r_g_io_out_s3_full_pred_3_slot_valids_0 !== r_i_io_out_s3_full_pred_3_slot_valids_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_slot_valids_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_slot_valids_0, r_i_io_out_s3_full_pred_3_slot_valids_0);
        end
        r_s1_io_out_s3_full_pred_3_slot_valids_0 |= r_g_io_out_s3_full_pred_3_slot_valids_0;
        r_s0_io_out_s3_full_pred_3_slot_valids_0 |= ~r_g_io_out_s3_full_pred_3_slot_valids_0;
        checks++;
        if (r_g_io_out_s3_full_pred_3_slot_valids_1 !== r_i_io_out_s3_full_pred_3_slot_valids_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_slot_valids_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_slot_valids_1, r_i_io_out_s3_full_pred_3_slot_valids_1);
        end
        r_s1_io_out_s3_full_pred_3_slot_valids_1 |= r_g_io_out_s3_full_pred_3_slot_valids_1;
        r_s0_io_out_s3_full_pred_3_slot_valids_1 |= ~r_g_io_out_s3_full_pred_3_slot_valids_1;
        checks++;
        if (r_g_io_out_s3_full_pred_3_targets_0 !== r_i_io_out_s3_full_pred_3_targets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_targets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_targets_0, r_i_io_out_s3_full_pred_3_targets_0);
        end
        r_s1_io_out_s3_full_pred_3_targets_0 |= r_g_io_out_s3_full_pred_3_targets_0;
        r_s0_io_out_s3_full_pred_3_targets_0 |= ~r_g_io_out_s3_full_pred_3_targets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_3_targets_1 !== r_i_io_out_s3_full_pred_3_targets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_targets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_targets_1, r_i_io_out_s3_full_pred_3_targets_1);
        end
        r_s1_io_out_s3_full_pred_3_targets_1 |= r_g_io_out_s3_full_pred_3_targets_1;
        r_s0_io_out_s3_full_pred_3_targets_1 |= ~r_g_io_out_s3_full_pred_3_targets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_3_jalr_target !== r_i_io_out_s3_full_pred_3_jalr_target) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_jalr_target g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_jalr_target, r_i_io_out_s3_full_pred_3_jalr_target);
        end
        r_s1_io_out_s3_full_pred_3_jalr_target |= r_g_io_out_s3_full_pred_3_jalr_target;
        r_s0_io_out_s3_full_pred_3_jalr_target |= ~r_g_io_out_s3_full_pred_3_jalr_target;
        checks++;
        if (r_g_io_out_s3_full_pred_3_offsets_0 !== r_i_io_out_s3_full_pred_3_offsets_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_offsets_0 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_offsets_0, r_i_io_out_s3_full_pred_3_offsets_0);
        end
        r_s1_io_out_s3_full_pred_3_offsets_0 |= r_g_io_out_s3_full_pred_3_offsets_0;
        r_s0_io_out_s3_full_pred_3_offsets_0 |= ~r_g_io_out_s3_full_pred_3_offsets_0;
        checks++;
        if (r_g_io_out_s3_full_pred_3_offsets_1 !== r_i_io_out_s3_full_pred_3_offsets_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_offsets_1 g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_offsets_1, r_i_io_out_s3_full_pred_3_offsets_1);
        end
        r_s1_io_out_s3_full_pred_3_offsets_1 |= r_g_io_out_s3_full_pred_3_offsets_1;
        r_s0_io_out_s3_full_pred_3_offsets_1 |= ~r_g_io_out_s3_full_pred_3_offsets_1;
        checks++;
        if (r_g_io_out_s3_full_pred_3_fallThroughAddr !== r_i_io_out_s3_full_pred_3_fallThroughAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_fallThroughAddr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_fallThroughAddr, r_i_io_out_s3_full_pred_3_fallThroughAddr);
        end
        r_s1_io_out_s3_full_pred_3_fallThroughAddr |= r_g_io_out_s3_full_pred_3_fallThroughAddr;
        r_s0_io_out_s3_full_pred_3_fallThroughAddr |= ~r_g_io_out_s3_full_pred_3_fallThroughAddr;
        checks++;
        if (r_g_io_out_s3_full_pred_3_fallThroughErr !== r_i_io_out_s3_full_pred_3_fallThroughErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_fallThroughErr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_fallThroughErr, r_i_io_out_s3_full_pred_3_fallThroughErr);
        end
        r_s1_io_out_s3_full_pred_3_fallThroughErr |= r_g_io_out_s3_full_pred_3_fallThroughErr;
        r_s0_io_out_s3_full_pred_3_fallThroughErr |= ~r_g_io_out_s3_full_pred_3_fallThroughErr;
        checks++;
        if (r_g_io_out_s3_full_pred_3_multiHit !== r_i_io_out_s3_full_pred_3_multiHit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_multiHit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_multiHit, r_i_io_out_s3_full_pred_3_multiHit);
        end
        r_s1_io_out_s3_full_pred_3_multiHit |= r_g_io_out_s3_full_pred_3_multiHit;
        r_s0_io_out_s3_full_pred_3_multiHit |= ~r_g_io_out_s3_full_pred_3_multiHit;
        checks++;
        if (r_g_io_out_s3_full_pred_3_is_jal !== r_i_io_out_s3_full_pred_3_is_jal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_is_jal g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_is_jal, r_i_io_out_s3_full_pred_3_is_jal);
        end
        r_s1_io_out_s3_full_pred_3_is_jal |= r_g_io_out_s3_full_pred_3_is_jal;
        r_s0_io_out_s3_full_pred_3_is_jal |= ~r_g_io_out_s3_full_pred_3_is_jal;
        checks++;
        if (r_g_io_out_s3_full_pred_3_is_jalr !== r_i_io_out_s3_full_pred_3_is_jalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_is_jalr g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_is_jalr, r_i_io_out_s3_full_pred_3_is_jalr);
        end
        r_s1_io_out_s3_full_pred_3_is_jalr |= r_g_io_out_s3_full_pred_3_is_jalr;
        r_s0_io_out_s3_full_pred_3_is_jalr |= ~r_g_io_out_s3_full_pred_3_is_jalr;
        checks++;
        if (r_g_io_out_s3_full_pred_3_is_call !== r_i_io_out_s3_full_pred_3_is_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_is_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_is_call, r_i_io_out_s3_full_pred_3_is_call);
        end
        r_s1_io_out_s3_full_pred_3_is_call |= r_g_io_out_s3_full_pred_3_is_call;
        r_s0_io_out_s3_full_pred_3_is_call |= ~r_g_io_out_s3_full_pred_3_is_call;
        checks++;
        if (r_g_io_out_s3_full_pred_3_is_ret !== r_i_io_out_s3_full_pred_3_is_ret) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_is_ret g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_is_ret, r_i_io_out_s3_full_pred_3_is_ret);
        end
        r_s1_io_out_s3_full_pred_3_is_ret |= r_g_io_out_s3_full_pred_3_is_ret;
        r_s0_io_out_s3_full_pred_3_is_ret |= ~r_g_io_out_s3_full_pred_3_is_ret;
        checks++;
        if (r_g_io_out_s3_full_pred_3_last_may_be_rvi_call !== r_i_io_out_s3_full_pred_3_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_last_may_be_rvi_call, r_i_io_out_s3_full_pred_3_last_may_be_rvi_call);
        end
        r_s1_io_out_s3_full_pred_3_last_may_be_rvi_call |= r_g_io_out_s3_full_pred_3_last_may_be_rvi_call;
        r_s0_io_out_s3_full_pred_3_last_may_be_rvi_call |= ~r_g_io_out_s3_full_pred_3_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_s3_full_pred_3_is_br_sharing !== r_i_io_out_s3_full_pred_3_is_br_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_is_br_sharing g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_is_br_sharing, r_i_io_out_s3_full_pred_3_is_br_sharing);
        end
        r_s1_io_out_s3_full_pred_3_is_br_sharing |= r_g_io_out_s3_full_pred_3_is_br_sharing;
        r_s0_io_out_s3_full_pred_3_is_br_sharing |= ~r_g_io_out_s3_full_pred_3_is_br_sharing;
        checks++;
        if (r_g_io_out_s3_full_pred_3_hit !== r_i_io_out_s3_full_pred_3_hit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_s3_full_pred_3_hit g=%h i=%h", cyc, r_g_io_out_s3_full_pred_3_hit, r_i_io_out_s3_full_pred_3_hit);
        end
        r_s1_io_out_s3_full_pred_3_hit |= r_g_io_out_s3_full_pred_3_hit;
        r_s0_io_out_s3_full_pred_3_hit |= ~r_g_io_out_s3_full_pred_3_hit;
        checks++;
        if (r_g_io_out_last_stage_meta !== r_i_io_out_last_stage_meta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_meta g=%h i=%h", cyc, r_g_io_out_last_stage_meta, r_i_io_out_last_stage_meta);
        end
        r_s1_io_out_last_stage_meta |= r_g_io_out_last_stage_meta;
        r_s0_io_out_last_stage_meta |= ~r_g_io_out_last_stage_meta;
        checks++;
        if (r_g_io_out_last_stage_spec_info_ssp !== r_i_io_out_last_stage_spec_info_ssp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_ssp g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_ssp, r_i_io_out_last_stage_spec_info_ssp);
        end
        r_s1_io_out_last_stage_spec_info_ssp |= r_g_io_out_last_stage_spec_info_ssp;
        r_s0_io_out_last_stage_spec_info_ssp |= ~r_g_io_out_last_stage_spec_info_ssp;
        checks++;
        if (r_g_io_out_last_stage_spec_info_sctr !== r_i_io_out_last_stage_spec_info_sctr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_sctr g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_sctr, r_i_io_out_last_stage_spec_info_sctr);
        end
        r_s1_io_out_last_stage_spec_info_sctr |= r_g_io_out_last_stage_spec_info_sctr;
        r_s0_io_out_last_stage_spec_info_sctr |= ~r_g_io_out_last_stage_spec_info_sctr;
        checks++;
        if (r_g_io_out_last_stage_spec_info_TOSW_flag !== r_i_io_out_last_stage_spec_info_TOSW_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_TOSW_flag g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_TOSW_flag, r_i_io_out_last_stage_spec_info_TOSW_flag);
        end
        r_s1_io_out_last_stage_spec_info_TOSW_flag |= r_g_io_out_last_stage_spec_info_TOSW_flag;
        r_s0_io_out_last_stage_spec_info_TOSW_flag |= ~r_g_io_out_last_stage_spec_info_TOSW_flag;
        checks++;
        if (r_g_io_out_last_stage_spec_info_TOSW_value !== r_i_io_out_last_stage_spec_info_TOSW_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_TOSW_value g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_TOSW_value, r_i_io_out_last_stage_spec_info_TOSW_value);
        end
        r_s1_io_out_last_stage_spec_info_TOSW_value |= r_g_io_out_last_stage_spec_info_TOSW_value;
        r_s0_io_out_last_stage_spec_info_TOSW_value |= ~r_g_io_out_last_stage_spec_info_TOSW_value;
        checks++;
        if (r_g_io_out_last_stage_spec_info_TOSR_flag !== r_i_io_out_last_stage_spec_info_TOSR_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_TOSR_flag g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_TOSR_flag, r_i_io_out_last_stage_spec_info_TOSR_flag);
        end
        r_s1_io_out_last_stage_spec_info_TOSR_flag |= r_g_io_out_last_stage_spec_info_TOSR_flag;
        r_s0_io_out_last_stage_spec_info_TOSR_flag |= ~r_g_io_out_last_stage_spec_info_TOSR_flag;
        checks++;
        if (r_g_io_out_last_stage_spec_info_TOSR_value !== r_i_io_out_last_stage_spec_info_TOSR_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_TOSR_value g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_TOSR_value, r_i_io_out_last_stage_spec_info_TOSR_value);
        end
        r_s1_io_out_last_stage_spec_info_TOSR_value |= r_g_io_out_last_stage_spec_info_TOSR_value;
        r_s0_io_out_last_stage_spec_info_TOSR_value |= ~r_g_io_out_last_stage_spec_info_TOSR_value;
        checks++;
        if (r_g_io_out_last_stage_spec_info_NOS_flag !== r_i_io_out_last_stage_spec_info_NOS_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_NOS_flag g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_NOS_flag, r_i_io_out_last_stage_spec_info_NOS_flag);
        end
        r_s1_io_out_last_stage_spec_info_NOS_flag |= r_g_io_out_last_stage_spec_info_NOS_flag;
        r_s0_io_out_last_stage_spec_info_NOS_flag |= ~r_g_io_out_last_stage_spec_info_NOS_flag;
        checks++;
        if (r_g_io_out_last_stage_spec_info_NOS_value !== r_i_io_out_last_stage_spec_info_NOS_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_NOS_value g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_NOS_value, r_i_io_out_last_stage_spec_info_NOS_value);
        end
        r_s1_io_out_last_stage_spec_info_NOS_value |= r_g_io_out_last_stage_spec_info_NOS_value;
        r_s0_io_out_last_stage_spec_info_NOS_value |= ~r_g_io_out_last_stage_spec_info_NOS_value;
        checks++;
        if (r_g_io_out_last_stage_spec_info_topAddr !== r_i_io_out_last_stage_spec_info_topAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_topAddr g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_topAddr, r_i_io_out_last_stage_spec_info_topAddr);
        end
        r_s1_io_out_last_stage_spec_info_topAddr |= r_g_io_out_last_stage_spec_info_topAddr;
        r_s0_io_out_last_stage_spec_info_topAddr |= ~r_g_io_out_last_stage_spec_info_topAddr;
        checks++;
        if (r_g_io_out_last_stage_spec_info_sc_disagree_0 !== r_i_io_out_last_stage_spec_info_sc_disagree_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_sc_disagree_0 g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_sc_disagree_0, r_i_io_out_last_stage_spec_info_sc_disagree_0);
        end
        r_s1_io_out_last_stage_spec_info_sc_disagree_0 |= r_g_io_out_last_stage_spec_info_sc_disagree_0;
        r_s0_io_out_last_stage_spec_info_sc_disagree_0 |= ~r_g_io_out_last_stage_spec_info_sc_disagree_0;
        checks++;
        if (r_g_io_out_last_stage_spec_info_sc_disagree_1 !== r_i_io_out_last_stage_spec_info_sc_disagree_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_spec_info_sc_disagree_1 g=%h i=%h", cyc, r_g_io_out_last_stage_spec_info_sc_disagree_1, r_i_io_out_last_stage_spec_info_sc_disagree_1);
        end
        r_s1_io_out_last_stage_spec_info_sc_disagree_1 |= r_g_io_out_last_stage_spec_info_sc_disagree_1;
        r_s0_io_out_last_stage_spec_info_sc_disagree_1 |= ~r_g_io_out_last_stage_spec_info_sc_disagree_1;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_isCall !== r_i_io_out_last_stage_ftb_entry_isCall) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_isCall g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_isCall, r_i_io_out_last_stage_ftb_entry_isCall);
        end
        r_s1_io_out_last_stage_ftb_entry_isCall |= r_g_io_out_last_stage_ftb_entry_isCall;
        r_s0_io_out_last_stage_ftb_entry_isCall |= ~r_g_io_out_last_stage_ftb_entry_isCall;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_isRet !== r_i_io_out_last_stage_ftb_entry_isRet) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_isRet g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_isRet, r_i_io_out_last_stage_ftb_entry_isRet);
        end
        r_s1_io_out_last_stage_ftb_entry_isRet |= r_g_io_out_last_stage_ftb_entry_isRet;
        r_s0_io_out_last_stage_ftb_entry_isRet |= ~r_g_io_out_last_stage_ftb_entry_isRet;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_isJalr !== r_i_io_out_last_stage_ftb_entry_isJalr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_isJalr g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_isJalr, r_i_io_out_last_stage_ftb_entry_isJalr);
        end
        r_s1_io_out_last_stage_ftb_entry_isJalr |= r_g_io_out_last_stage_ftb_entry_isJalr;
        r_s0_io_out_last_stage_ftb_entry_isJalr |= ~r_g_io_out_last_stage_ftb_entry_isJalr;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_valid !== r_i_io_out_last_stage_ftb_entry_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_valid g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_valid, r_i_io_out_last_stage_ftb_entry_valid);
        end
        r_s1_io_out_last_stage_ftb_entry_valid |= r_g_io_out_last_stage_ftb_entry_valid;
        r_s0_io_out_last_stage_ftb_entry_valid |= ~r_g_io_out_last_stage_ftb_entry_valid;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_brSlots_0_offset !== r_i_io_out_last_stage_ftb_entry_brSlots_0_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_brSlots_0_offset g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_brSlots_0_offset, r_i_io_out_last_stage_ftb_entry_brSlots_0_offset);
        end
        r_s1_io_out_last_stage_ftb_entry_brSlots_0_offset |= r_g_io_out_last_stage_ftb_entry_brSlots_0_offset;
        r_s0_io_out_last_stage_ftb_entry_brSlots_0_offset |= ~r_g_io_out_last_stage_ftb_entry_brSlots_0_offset;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_brSlots_0_sharing !== r_i_io_out_last_stage_ftb_entry_brSlots_0_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_brSlots_0_sharing g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_brSlots_0_sharing, r_i_io_out_last_stage_ftb_entry_brSlots_0_sharing);
        end
        r_s1_io_out_last_stage_ftb_entry_brSlots_0_sharing |= r_g_io_out_last_stage_ftb_entry_brSlots_0_sharing;
        r_s0_io_out_last_stage_ftb_entry_brSlots_0_sharing |= ~r_g_io_out_last_stage_ftb_entry_brSlots_0_sharing;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_brSlots_0_valid !== r_i_io_out_last_stage_ftb_entry_brSlots_0_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_brSlots_0_valid g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_brSlots_0_valid, r_i_io_out_last_stage_ftb_entry_brSlots_0_valid);
        end
        r_s1_io_out_last_stage_ftb_entry_brSlots_0_valid |= r_g_io_out_last_stage_ftb_entry_brSlots_0_valid;
        r_s0_io_out_last_stage_ftb_entry_brSlots_0_valid |= ~r_g_io_out_last_stage_ftb_entry_brSlots_0_valid;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_brSlots_0_lower !== r_i_io_out_last_stage_ftb_entry_brSlots_0_lower) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_brSlots_0_lower g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_brSlots_0_lower, r_i_io_out_last_stage_ftb_entry_brSlots_0_lower);
        end
        r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower |= r_g_io_out_last_stage_ftb_entry_brSlots_0_lower;
        r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower |= ~r_g_io_out_last_stage_ftb_entry_brSlots_0_lower;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_brSlots_0_tarStat !== r_i_io_out_last_stage_ftb_entry_brSlots_0_tarStat) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_brSlots_0_tarStat g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_brSlots_0_tarStat, r_i_io_out_last_stage_ftb_entry_brSlots_0_tarStat);
        end
        r_s1_io_out_last_stage_ftb_entry_brSlots_0_tarStat |= r_g_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
        r_s0_io_out_last_stage_ftb_entry_brSlots_0_tarStat |= ~r_g_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_tailSlot_offset !== r_i_io_out_last_stage_ftb_entry_tailSlot_offset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_tailSlot_offset g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_tailSlot_offset, r_i_io_out_last_stage_ftb_entry_tailSlot_offset);
        end
        r_s1_io_out_last_stage_ftb_entry_tailSlot_offset |= r_g_io_out_last_stage_ftb_entry_tailSlot_offset;
        r_s0_io_out_last_stage_ftb_entry_tailSlot_offset |= ~r_g_io_out_last_stage_ftb_entry_tailSlot_offset;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_tailSlot_sharing !== r_i_io_out_last_stage_ftb_entry_tailSlot_sharing) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_tailSlot_sharing g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_tailSlot_sharing, r_i_io_out_last_stage_ftb_entry_tailSlot_sharing);
        end
        r_s1_io_out_last_stage_ftb_entry_tailSlot_sharing |= r_g_io_out_last_stage_ftb_entry_tailSlot_sharing;
        r_s0_io_out_last_stage_ftb_entry_tailSlot_sharing |= ~r_g_io_out_last_stage_ftb_entry_tailSlot_sharing;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_tailSlot_valid !== r_i_io_out_last_stage_ftb_entry_tailSlot_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_tailSlot_valid g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_tailSlot_valid, r_i_io_out_last_stage_ftb_entry_tailSlot_valid);
        end
        r_s1_io_out_last_stage_ftb_entry_tailSlot_valid |= r_g_io_out_last_stage_ftb_entry_tailSlot_valid;
        r_s0_io_out_last_stage_ftb_entry_tailSlot_valid |= ~r_g_io_out_last_stage_ftb_entry_tailSlot_valid;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_tailSlot_lower !== r_i_io_out_last_stage_ftb_entry_tailSlot_lower) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_tailSlot_lower g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_tailSlot_lower, r_i_io_out_last_stage_ftb_entry_tailSlot_lower);
        end
        r_s1_io_out_last_stage_ftb_entry_tailSlot_lower |= r_g_io_out_last_stage_ftb_entry_tailSlot_lower;
        r_s0_io_out_last_stage_ftb_entry_tailSlot_lower |= ~r_g_io_out_last_stage_ftb_entry_tailSlot_lower;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_tailSlot_tarStat !== r_i_io_out_last_stage_ftb_entry_tailSlot_tarStat) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_tailSlot_tarStat g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_tailSlot_tarStat, r_i_io_out_last_stage_ftb_entry_tailSlot_tarStat);
        end
        r_s1_io_out_last_stage_ftb_entry_tailSlot_tarStat |= r_g_io_out_last_stage_ftb_entry_tailSlot_tarStat;
        r_s0_io_out_last_stage_ftb_entry_tailSlot_tarStat |= ~r_g_io_out_last_stage_ftb_entry_tailSlot_tarStat;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_pftAddr !== r_i_io_out_last_stage_ftb_entry_pftAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_pftAddr g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_pftAddr, r_i_io_out_last_stage_ftb_entry_pftAddr);
        end
        r_s1_io_out_last_stage_ftb_entry_pftAddr |= r_g_io_out_last_stage_ftb_entry_pftAddr;
        r_s0_io_out_last_stage_ftb_entry_pftAddr |= ~r_g_io_out_last_stage_ftb_entry_pftAddr;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_carry !== r_i_io_out_last_stage_ftb_entry_carry) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_carry g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_carry, r_i_io_out_last_stage_ftb_entry_carry);
        end
        r_s1_io_out_last_stage_ftb_entry_carry |= r_g_io_out_last_stage_ftb_entry_carry;
        r_s0_io_out_last_stage_ftb_entry_carry |= ~r_g_io_out_last_stage_ftb_entry_carry;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_last_may_be_rvi_call !== r_i_io_out_last_stage_ftb_entry_last_may_be_rvi_call) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_last_may_be_rvi_call g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_last_may_be_rvi_call, r_i_io_out_last_stage_ftb_entry_last_may_be_rvi_call);
        end
        r_s1_io_out_last_stage_ftb_entry_last_may_be_rvi_call |= r_g_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
        r_s0_io_out_last_stage_ftb_entry_last_may_be_rvi_call |= ~r_g_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_strong_bias_0 !== r_i_io_out_last_stage_ftb_entry_strong_bias_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_strong_bias_0 g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_strong_bias_0, r_i_io_out_last_stage_ftb_entry_strong_bias_0);
        end
        r_s1_io_out_last_stage_ftb_entry_strong_bias_0 |= r_g_io_out_last_stage_ftb_entry_strong_bias_0;
        r_s0_io_out_last_stage_ftb_entry_strong_bias_0 |= ~r_g_io_out_last_stage_ftb_entry_strong_bias_0;
        checks++;
        if (r_g_io_out_last_stage_ftb_entry_strong_bias_1 !== r_i_io_out_last_stage_ftb_entry_strong_bias_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RAS.io_out_last_stage_ftb_entry_strong_bias_1 g=%h i=%h", cyc, r_g_io_out_last_stage_ftb_entry_strong_bias_1, r_i_io_out_last_stage_ftb_entry_strong_bias_1);
        end
        r_s1_io_out_last_stage_ftb_entry_strong_bias_1 |= r_g_io_out_last_stage_ftb_entry_strong_bias_1;
        r_s0_io_out_last_stage_ftb_entry_strong_bias_1 |= ~r_g_io_out_last_stage_ftb_entry_strong_bias_1;
        if (r_u_gold.s2_spec_push) r_cov_spec_push++;
        if (r_u_gold.s2_spec_pop) r_cov_spec_pop++;
        if (r_u_gold.s3_cancel_probe) r_cov_s3_cancel++;
        if (r_u_gold._RASStack_io_spec_near_overflow) r_cov_near_overflow++;
        if (r_u_gold.RASStack.io_redirect_valid && r_u_gold.RASStack.io_redirect_isCall) r_cov_redirect_call++;
        if (r_u_gold.RASStack.io_redirect_valid && r_u_gold.RASStack.io_redirect_isRet) r_cov_redirect_ret++;
        if (r_u_gold.RASStack.io_commit_push_valid) r_cov_commit_push++;
        if (r_u_gold.RASStack.io_commit_pop_valid) r_cov_commit_pop++;
        if (r_io_in_bits_resp_in_0_s2_full_pred_2_is_ret && r_io_ctrl_ras_enable) r_cov_s2_ret_target++;
        if (r_io_s1_fire_0 && r_u_gold.s2_pc_dup_s2_pc_seg_0_value == r_u_gold.s1_pc_dup_0[49:24]) r_cov_s2_seg_hold++;
        if (r_reset && cyc > 100) r_cov_reset_mid++;
      end
      if (r_io_s2_fire_2) r_armed[0] = 1'b1;
      if (r_io_redirect_valid) r_armed[1] = 1'b1;
      if (r_io_update_valid) r_armed[2] = 1'b1;
      if (r_armed_at < 0 && (&r_armed)) r_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(r_s0_io_out_s2_pc_0[0] && r_s1_io_out_s2_pc_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[1] && r_s1_io_out_s2_pc_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[2] && r_s1_io_out_s2_pc_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[3] && r_s1_io_out_s2_pc_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[4] && r_s1_io_out_s2_pc_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[5] && r_s1_io_out_s2_pc_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[6] && r_s1_io_out_s2_pc_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[7] && r_s1_io_out_s2_pc_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[8] && r_s1_io_out_s2_pc_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[9] && r_s1_io_out_s2_pc_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[10] && r_s1_io_out_s2_pc_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[11] && r_s1_io_out_s2_pc_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[12] && r_s1_io_out_s2_pc_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[13] && r_s1_io_out_s2_pc_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[14] && r_s1_io_out_s2_pc_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[15] && r_s1_io_out_s2_pc_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[16] && r_s1_io_out_s2_pc_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[17] && r_s1_io_out_s2_pc_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[18] && r_s1_io_out_s2_pc_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[19] && r_s1_io_out_s2_pc_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[20] && r_s1_io_out_s2_pc_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[21] && r_s1_io_out_s2_pc_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[22] && r_s1_io_out_s2_pc_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[23] && r_s1_io_out_s2_pc_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[24] && r_s1_io_out_s2_pc_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[25] && r_s1_io_out_s2_pc_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[26] && r_s1_io_out_s2_pc_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[27] && r_s1_io_out_s2_pc_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[28] && r_s1_io_out_s2_pc_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[29] && r_s1_io_out_s2_pc_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[30] && r_s1_io_out_s2_pc_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[31] && r_s1_io_out_s2_pc_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[32] && r_s1_io_out_s2_pc_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[33] && r_s1_io_out_s2_pc_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[34] && r_s1_io_out_s2_pc_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[35] && r_s1_io_out_s2_pc_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[36] && r_s1_io_out_s2_pc_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[37] && r_s1_io_out_s2_pc_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[38] && r_s1_io_out_s2_pc_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[39] && r_s1_io_out_s2_pc_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[40] && r_s1_io_out_s2_pc_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[41] && r_s1_io_out_s2_pc_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[42] && r_s1_io_out_s2_pc_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[43] && r_s1_io_out_s2_pc_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[44] && r_s1_io_out_s2_pc_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[45] && r_s1_io_out_s2_pc_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[46] && r_s1_io_out_s2_pc_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[47] && r_s1_io_out_s2_pc_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[48] && r_s1_io_out_s2_pc_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_0[49] && r_s1_io_out_s2_pc_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[0] && r_s1_io_out_s2_pc_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[1] && r_s1_io_out_s2_pc_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[2] && r_s1_io_out_s2_pc_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[3] && r_s1_io_out_s2_pc_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[4] && r_s1_io_out_s2_pc_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[5] && r_s1_io_out_s2_pc_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[6] && r_s1_io_out_s2_pc_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[7] && r_s1_io_out_s2_pc_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[8] && r_s1_io_out_s2_pc_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[9] && r_s1_io_out_s2_pc_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[10] && r_s1_io_out_s2_pc_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[11] && r_s1_io_out_s2_pc_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[12] && r_s1_io_out_s2_pc_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[13] && r_s1_io_out_s2_pc_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[14] && r_s1_io_out_s2_pc_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[15] && r_s1_io_out_s2_pc_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[16] && r_s1_io_out_s2_pc_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[17] && r_s1_io_out_s2_pc_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[18] && r_s1_io_out_s2_pc_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[19] && r_s1_io_out_s2_pc_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[20] && r_s1_io_out_s2_pc_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[21] && r_s1_io_out_s2_pc_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[22] && r_s1_io_out_s2_pc_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[23] && r_s1_io_out_s2_pc_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[24] && r_s1_io_out_s2_pc_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[25] && r_s1_io_out_s2_pc_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[26] && r_s1_io_out_s2_pc_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[27] && r_s1_io_out_s2_pc_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[28] && r_s1_io_out_s2_pc_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[29] && r_s1_io_out_s2_pc_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[30] && r_s1_io_out_s2_pc_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[31] && r_s1_io_out_s2_pc_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[32] && r_s1_io_out_s2_pc_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[33] && r_s1_io_out_s2_pc_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[34] && r_s1_io_out_s2_pc_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[35] && r_s1_io_out_s2_pc_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[36] && r_s1_io_out_s2_pc_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[37] && r_s1_io_out_s2_pc_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[38] && r_s1_io_out_s2_pc_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[39] && r_s1_io_out_s2_pc_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[40] && r_s1_io_out_s2_pc_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[41] && r_s1_io_out_s2_pc_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[42] && r_s1_io_out_s2_pc_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[43] && r_s1_io_out_s2_pc_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[44] && r_s1_io_out_s2_pc_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[45] && r_s1_io_out_s2_pc_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[46] && r_s1_io_out_s2_pc_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[47] && r_s1_io_out_s2_pc_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[48] && r_s1_io_out_s2_pc_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_1[49] && r_s1_io_out_s2_pc_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[0] && r_s1_io_out_s2_pc_2[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[1] && r_s1_io_out_s2_pc_2[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[2] && r_s1_io_out_s2_pc_2[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[3] && r_s1_io_out_s2_pc_2[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[4] && r_s1_io_out_s2_pc_2[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[5] && r_s1_io_out_s2_pc_2[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[6] && r_s1_io_out_s2_pc_2[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[7] && r_s1_io_out_s2_pc_2[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[8] && r_s1_io_out_s2_pc_2[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[9] && r_s1_io_out_s2_pc_2[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[10] && r_s1_io_out_s2_pc_2[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[11] && r_s1_io_out_s2_pc_2[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[12] && r_s1_io_out_s2_pc_2[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[13] && r_s1_io_out_s2_pc_2[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[14] && r_s1_io_out_s2_pc_2[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[15] && r_s1_io_out_s2_pc_2[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[16] && r_s1_io_out_s2_pc_2[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[17] && r_s1_io_out_s2_pc_2[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[18] && r_s1_io_out_s2_pc_2[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[19] && r_s1_io_out_s2_pc_2[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[20] && r_s1_io_out_s2_pc_2[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[21] && r_s1_io_out_s2_pc_2[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[22] && r_s1_io_out_s2_pc_2[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[23] && r_s1_io_out_s2_pc_2[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[24] && r_s1_io_out_s2_pc_2[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[25] && r_s1_io_out_s2_pc_2[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[26] && r_s1_io_out_s2_pc_2[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[27] && r_s1_io_out_s2_pc_2[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[28] && r_s1_io_out_s2_pc_2[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[29] && r_s1_io_out_s2_pc_2[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[30] && r_s1_io_out_s2_pc_2[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[31] && r_s1_io_out_s2_pc_2[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[32] && r_s1_io_out_s2_pc_2[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[33] && r_s1_io_out_s2_pc_2[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[34] && r_s1_io_out_s2_pc_2[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[35] && r_s1_io_out_s2_pc_2[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[36] && r_s1_io_out_s2_pc_2[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[37] && r_s1_io_out_s2_pc_2[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[38] && r_s1_io_out_s2_pc_2[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[39] && r_s1_io_out_s2_pc_2[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[40] && r_s1_io_out_s2_pc_2[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[41] && r_s1_io_out_s2_pc_2[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[42] && r_s1_io_out_s2_pc_2[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[43] && r_s1_io_out_s2_pc_2[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[44] && r_s1_io_out_s2_pc_2[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[45] && r_s1_io_out_s2_pc_2[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[46] && r_s1_io_out_s2_pc_2[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[47] && r_s1_io_out_s2_pc_2[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[48] && r_s1_io_out_s2_pc_2[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_2[49] && r_s1_io_out_s2_pc_2[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_2[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[0] && r_s1_io_out_s2_pc_3[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[1] && r_s1_io_out_s2_pc_3[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[2] && r_s1_io_out_s2_pc_3[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[3] && r_s1_io_out_s2_pc_3[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[4] && r_s1_io_out_s2_pc_3[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[5] && r_s1_io_out_s2_pc_3[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[6] && r_s1_io_out_s2_pc_3[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[7] && r_s1_io_out_s2_pc_3[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[8] && r_s1_io_out_s2_pc_3[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[9] && r_s1_io_out_s2_pc_3[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[10] && r_s1_io_out_s2_pc_3[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[11] && r_s1_io_out_s2_pc_3[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[12] && r_s1_io_out_s2_pc_3[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[13] && r_s1_io_out_s2_pc_3[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[14] && r_s1_io_out_s2_pc_3[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[15] && r_s1_io_out_s2_pc_3[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[16] && r_s1_io_out_s2_pc_3[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[17] && r_s1_io_out_s2_pc_3[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[18] && r_s1_io_out_s2_pc_3[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[19] && r_s1_io_out_s2_pc_3[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[20] && r_s1_io_out_s2_pc_3[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[21] && r_s1_io_out_s2_pc_3[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[22] && r_s1_io_out_s2_pc_3[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[23] && r_s1_io_out_s2_pc_3[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[24] && r_s1_io_out_s2_pc_3[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[25] && r_s1_io_out_s2_pc_3[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[26] && r_s1_io_out_s2_pc_3[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[27] && r_s1_io_out_s2_pc_3[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[28] && r_s1_io_out_s2_pc_3[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[29] && r_s1_io_out_s2_pc_3[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[30] && r_s1_io_out_s2_pc_3[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[31] && r_s1_io_out_s2_pc_3[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[32] && r_s1_io_out_s2_pc_3[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[33] && r_s1_io_out_s2_pc_3[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[34] && r_s1_io_out_s2_pc_3[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[35] && r_s1_io_out_s2_pc_3[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[36] && r_s1_io_out_s2_pc_3[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[37] && r_s1_io_out_s2_pc_3[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[38] && r_s1_io_out_s2_pc_3[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[39] && r_s1_io_out_s2_pc_3[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[40] && r_s1_io_out_s2_pc_3[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[41] && r_s1_io_out_s2_pc_3[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[42] && r_s1_io_out_s2_pc_3[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[43] && r_s1_io_out_s2_pc_3[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[44] && r_s1_io_out_s2_pc_3[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[45] && r_s1_io_out_s2_pc_3[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[46] && r_s1_io_out_s2_pc_3[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[47] && r_s1_io_out_s2_pc_3[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[48] && r_s1_io_out_s2_pc_3[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_pc_3[49] && r_s1_io_out_s2_pc_3[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_pc_3[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_br_taken_mask_0 && r_s1_io_out_s2_full_pred_0_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_br_taken_mask_1 && r_s1_io_out_s2_full_pred_0_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_slot_valids_0 && r_s1_io_out_s2_full_pred_0_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_slot_valids_1 && r_s1_io_out_s2_full_pred_0_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[0] && r_s1_io_out_s2_full_pred_0_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[1] && r_s1_io_out_s2_full_pred_0_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[2] && r_s1_io_out_s2_full_pred_0_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[3] && r_s1_io_out_s2_full_pred_0_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[4] && r_s1_io_out_s2_full_pred_0_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[5] && r_s1_io_out_s2_full_pred_0_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[6] && r_s1_io_out_s2_full_pred_0_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[7] && r_s1_io_out_s2_full_pred_0_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[8] && r_s1_io_out_s2_full_pred_0_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[9] && r_s1_io_out_s2_full_pred_0_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[10] && r_s1_io_out_s2_full_pred_0_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[11] && r_s1_io_out_s2_full_pred_0_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[12] && r_s1_io_out_s2_full_pred_0_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[13] && r_s1_io_out_s2_full_pred_0_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[14] && r_s1_io_out_s2_full_pred_0_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[15] && r_s1_io_out_s2_full_pred_0_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[16] && r_s1_io_out_s2_full_pred_0_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[17] && r_s1_io_out_s2_full_pred_0_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[18] && r_s1_io_out_s2_full_pred_0_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[19] && r_s1_io_out_s2_full_pred_0_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[20] && r_s1_io_out_s2_full_pred_0_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[21] && r_s1_io_out_s2_full_pred_0_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[22] && r_s1_io_out_s2_full_pred_0_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[23] && r_s1_io_out_s2_full_pred_0_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[24] && r_s1_io_out_s2_full_pred_0_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[25] && r_s1_io_out_s2_full_pred_0_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[26] && r_s1_io_out_s2_full_pred_0_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[27] && r_s1_io_out_s2_full_pred_0_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[28] && r_s1_io_out_s2_full_pred_0_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[29] && r_s1_io_out_s2_full_pred_0_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[30] && r_s1_io_out_s2_full_pred_0_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[31] && r_s1_io_out_s2_full_pred_0_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[32] && r_s1_io_out_s2_full_pred_0_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[33] && r_s1_io_out_s2_full_pred_0_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[34] && r_s1_io_out_s2_full_pred_0_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[35] && r_s1_io_out_s2_full_pred_0_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[36] && r_s1_io_out_s2_full_pred_0_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[37] && r_s1_io_out_s2_full_pred_0_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[38] && r_s1_io_out_s2_full_pred_0_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[39] && r_s1_io_out_s2_full_pred_0_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[40] && r_s1_io_out_s2_full_pred_0_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[41] && r_s1_io_out_s2_full_pred_0_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[42] && r_s1_io_out_s2_full_pred_0_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[43] && r_s1_io_out_s2_full_pred_0_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[44] && r_s1_io_out_s2_full_pred_0_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[45] && r_s1_io_out_s2_full_pred_0_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[46] && r_s1_io_out_s2_full_pred_0_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[47] && r_s1_io_out_s2_full_pred_0_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[48] && r_s1_io_out_s2_full_pred_0_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_0[49] && r_s1_io_out_s2_full_pred_0_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[0] && r_s1_io_out_s2_full_pred_0_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[1] && r_s1_io_out_s2_full_pred_0_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[2] && r_s1_io_out_s2_full_pred_0_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[3] && r_s1_io_out_s2_full_pred_0_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[4] && r_s1_io_out_s2_full_pred_0_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[5] && r_s1_io_out_s2_full_pred_0_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[6] && r_s1_io_out_s2_full_pred_0_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[7] && r_s1_io_out_s2_full_pred_0_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[8] && r_s1_io_out_s2_full_pred_0_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[9] && r_s1_io_out_s2_full_pred_0_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[10] && r_s1_io_out_s2_full_pred_0_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[11] && r_s1_io_out_s2_full_pred_0_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[12] && r_s1_io_out_s2_full_pred_0_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[13] && r_s1_io_out_s2_full_pred_0_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[14] && r_s1_io_out_s2_full_pred_0_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[15] && r_s1_io_out_s2_full_pred_0_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[16] && r_s1_io_out_s2_full_pred_0_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[17] && r_s1_io_out_s2_full_pred_0_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[18] && r_s1_io_out_s2_full_pred_0_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[19] && r_s1_io_out_s2_full_pred_0_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[20] && r_s1_io_out_s2_full_pred_0_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[21] && r_s1_io_out_s2_full_pred_0_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[22] && r_s1_io_out_s2_full_pred_0_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[23] && r_s1_io_out_s2_full_pred_0_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[24] && r_s1_io_out_s2_full_pred_0_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[25] && r_s1_io_out_s2_full_pred_0_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[26] && r_s1_io_out_s2_full_pred_0_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[27] && r_s1_io_out_s2_full_pred_0_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[28] && r_s1_io_out_s2_full_pred_0_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[29] && r_s1_io_out_s2_full_pred_0_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[30] && r_s1_io_out_s2_full_pred_0_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[31] && r_s1_io_out_s2_full_pred_0_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[32] && r_s1_io_out_s2_full_pred_0_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[33] && r_s1_io_out_s2_full_pred_0_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[34] && r_s1_io_out_s2_full_pred_0_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[35] && r_s1_io_out_s2_full_pred_0_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[36] && r_s1_io_out_s2_full_pred_0_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[37] && r_s1_io_out_s2_full_pred_0_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[38] && r_s1_io_out_s2_full_pred_0_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[39] && r_s1_io_out_s2_full_pred_0_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[40] && r_s1_io_out_s2_full_pred_0_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[41] && r_s1_io_out_s2_full_pred_0_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[42] && r_s1_io_out_s2_full_pred_0_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[43] && r_s1_io_out_s2_full_pred_0_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[44] && r_s1_io_out_s2_full_pred_0_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[45] && r_s1_io_out_s2_full_pred_0_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[46] && r_s1_io_out_s2_full_pred_0_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[47] && r_s1_io_out_s2_full_pred_0_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[48] && r_s1_io_out_s2_full_pred_0_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_targets_1[49] && r_s1_io_out_s2_full_pred_0_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[0] && r_s1_io_out_s2_full_pred_0_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[1] && r_s1_io_out_s2_full_pred_0_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[2] && r_s1_io_out_s2_full_pred_0_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[3] && r_s1_io_out_s2_full_pred_0_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[4] && r_s1_io_out_s2_full_pred_0_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[5] && r_s1_io_out_s2_full_pred_0_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[6] && r_s1_io_out_s2_full_pred_0_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[7] && r_s1_io_out_s2_full_pred_0_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[8] && r_s1_io_out_s2_full_pred_0_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[9] && r_s1_io_out_s2_full_pred_0_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[10] && r_s1_io_out_s2_full_pred_0_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[11] && r_s1_io_out_s2_full_pred_0_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[12] && r_s1_io_out_s2_full_pred_0_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[13] && r_s1_io_out_s2_full_pred_0_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[14] && r_s1_io_out_s2_full_pred_0_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[15] && r_s1_io_out_s2_full_pred_0_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[16] && r_s1_io_out_s2_full_pred_0_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[17] && r_s1_io_out_s2_full_pred_0_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[18] && r_s1_io_out_s2_full_pred_0_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[19] && r_s1_io_out_s2_full_pred_0_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[20] && r_s1_io_out_s2_full_pred_0_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[21] && r_s1_io_out_s2_full_pred_0_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[22] && r_s1_io_out_s2_full_pred_0_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[23] && r_s1_io_out_s2_full_pred_0_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[24] && r_s1_io_out_s2_full_pred_0_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[25] && r_s1_io_out_s2_full_pred_0_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[26] && r_s1_io_out_s2_full_pred_0_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[27] && r_s1_io_out_s2_full_pred_0_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[28] && r_s1_io_out_s2_full_pred_0_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[29] && r_s1_io_out_s2_full_pred_0_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[30] && r_s1_io_out_s2_full_pred_0_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[31] && r_s1_io_out_s2_full_pred_0_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[32] && r_s1_io_out_s2_full_pred_0_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[33] && r_s1_io_out_s2_full_pred_0_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[34] && r_s1_io_out_s2_full_pred_0_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[35] && r_s1_io_out_s2_full_pred_0_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[36] && r_s1_io_out_s2_full_pred_0_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[37] && r_s1_io_out_s2_full_pred_0_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[38] && r_s1_io_out_s2_full_pred_0_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[39] && r_s1_io_out_s2_full_pred_0_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[40] && r_s1_io_out_s2_full_pred_0_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[41] && r_s1_io_out_s2_full_pred_0_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[42] && r_s1_io_out_s2_full_pred_0_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[43] && r_s1_io_out_s2_full_pred_0_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[44] && r_s1_io_out_s2_full_pred_0_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[45] && r_s1_io_out_s2_full_pred_0_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[46] && r_s1_io_out_s2_full_pred_0_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[47] && r_s1_io_out_s2_full_pred_0_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[48] && r_s1_io_out_s2_full_pred_0_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_jalr_target[49] && r_s1_io_out_s2_full_pred_0_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_0[0] && r_s1_io_out_s2_full_pred_0_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_0[1] && r_s1_io_out_s2_full_pred_0_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_0[2] && r_s1_io_out_s2_full_pred_0_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_0[3] && r_s1_io_out_s2_full_pred_0_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_1[0] && r_s1_io_out_s2_full_pred_0_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_1[1] && r_s1_io_out_s2_full_pred_0_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_1[2] && r_s1_io_out_s2_full_pred_0_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_offsets_1[3] && r_s1_io_out_s2_full_pred_0_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[0] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[1] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[2] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[3] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[4] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[5] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[6] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[7] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[8] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[9] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[10] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[11] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[12] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[13] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[14] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[15] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[16] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[17] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[18] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[19] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[20] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[21] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[22] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[23] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[24] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[25] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[26] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[27] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[28] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[29] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[30] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[31] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[32] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[33] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[34] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[35] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[36] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[37] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[38] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[39] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[40] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[41] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[42] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[43] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[44] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[45] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[46] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[47] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[48] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughAddr[49] && r_s1_io_out_s2_full_pred_0_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_fallThroughErr && r_s1_io_out_s2_full_pred_0_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_is_jal && r_s1_io_out_s2_full_pred_0_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_is_jalr && r_s1_io_out_s2_full_pred_0_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_is_call && r_s1_io_out_s2_full_pred_0_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_is_ret && r_s1_io_out_s2_full_pred_0_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_last_may_be_rvi_call && r_s1_io_out_s2_full_pred_0_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_is_br_sharing && r_s1_io_out_s2_full_pred_0_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_0_hit && r_s1_io_out_s2_full_pred_0_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_0_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_br_taken_mask_0 && r_s1_io_out_s2_full_pred_1_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_br_taken_mask_1 && r_s1_io_out_s2_full_pred_1_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_slot_valids_0 && r_s1_io_out_s2_full_pred_1_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_slot_valids_1 && r_s1_io_out_s2_full_pred_1_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[0] && r_s1_io_out_s2_full_pred_1_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[1] && r_s1_io_out_s2_full_pred_1_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[2] && r_s1_io_out_s2_full_pred_1_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[3] && r_s1_io_out_s2_full_pred_1_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[4] && r_s1_io_out_s2_full_pred_1_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[5] && r_s1_io_out_s2_full_pred_1_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[6] && r_s1_io_out_s2_full_pred_1_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[7] && r_s1_io_out_s2_full_pred_1_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[8] && r_s1_io_out_s2_full_pred_1_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[9] && r_s1_io_out_s2_full_pred_1_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[10] && r_s1_io_out_s2_full_pred_1_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[11] && r_s1_io_out_s2_full_pred_1_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[12] && r_s1_io_out_s2_full_pred_1_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[13] && r_s1_io_out_s2_full_pred_1_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[14] && r_s1_io_out_s2_full_pred_1_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[15] && r_s1_io_out_s2_full_pred_1_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[16] && r_s1_io_out_s2_full_pred_1_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[17] && r_s1_io_out_s2_full_pred_1_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[18] && r_s1_io_out_s2_full_pred_1_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[19] && r_s1_io_out_s2_full_pred_1_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[20] && r_s1_io_out_s2_full_pred_1_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[21] && r_s1_io_out_s2_full_pred_1_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[22] && r_s1_io_out_s2_full_pred_1_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[23] && r_s1_io_out_s2_full_pred_1_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[24] && r_s1_io_out_s2_full_pred_1_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[25] && r_s1_io_out_s2_full_pred_1_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[26] && r_s1_io_out_s2_full_pred_1_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[27] && r_s1_io_out_s2_full_pred_1_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[28] && r_s1_io_out_s2_full_pred_1_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[29] && r_s1_io_out_s2_full_pred_1_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[30] && r_s1_io_out_s2_full_pred_1_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[31] && r_s1_io_out_s2_full_pred_1_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[32] && r_s1_io_out_s2_full_pred_1_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[33] && r_s1_io_out_s2_full_pred_1_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[34] && r_s1_io_out_s2_full_pred_1_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[35] && r_s1_io_out_s2_full_pred_1_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[36] && r_s1_io_out_s2_full_pred_1_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[37] && r_s1_io_out_s2_full_pred_1_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[38] && r_s1_io_out_s2_full_pred_1_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[39] && r_s1_io_out_s2_full_pred_1_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[40] && r_s1_io_out_s2_full_pred_1_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[41] && r_s1_io_out_s2_full_pred_1_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[42] && r_s1_io_out_s2_full_pred_1_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[43] && r_s1_io_out_s2_full_pred_1_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[44] && r_s1_io_out_s2_full_pred_1_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[45] && r_s1_io_out_s2_full_pred_1_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[46] && r_s1_io_out_s2_full_pred_1_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[47] && r_s1_io_out_s2_full_pred_1_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[48] && r_s1_io_out_s2_full_pred_1_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_0[49] && r_s1_io_out_s2_full_pred_1_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[0] && r_s1_io_out_s2_full_pred_1_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[1] && r_s1_io_out_s2_full_pred_1_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[2] && r_s1_io_out_s2_full_pred_1_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[3] && r_s1_io_out_s2_full_pred_1_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[4] && r_s1_io_out_s2_full_pred_1_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[5] && r_s1_io_out_s2_full_pred_1_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[6] && r_s1_io_out_s2_full_pred_1_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[7] && r_s1_io_out_s2_full_pred_1_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[8] && r_s1_io_out_s2_full_pred_1_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[9] && r_s1_io_out_s2_full_pred_1_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[10] && r_s1_io_out_s2_full_pred_1_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[11] && r_s1_io_out_s2_full_pred_1_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[12] && r_s1_io_out_s2_full_pred_1_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[13] && r_s1_io_out_s2_full_pred_1_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[14] && r_s1_io_out_s2_full_pred_1_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[15] && r_s1_io_out_s2_full_pred_1_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[16] && r_s1_io_out_s2_full_pred_1_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[17] && r_s1_io_out_s2_full_pred_1_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[18] && r_s1_io_out_s2_full_pred_1_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[19] && r_s1_io_out_s2_full_pred_1_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[20] && r_s1_io_out_s2_full_pred_1_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[21] && r_s1_io_out_s2_full_pred_1_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[22] && r_s1_io_out_s2_full_pred_1_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[23] && r_s1_io_out_s2_full_pred_1_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[24] && r_s1_io_out_s2_full_pred_1_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[25] && r_s1_io_out_s2_full_pred_1_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[26] && r_s1_io_out_s2_full_pred_1_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[27] && r_s1_io_out_s2_full_pred_1_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[28] && r_s1_io_out_s2_full_pred_1_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[29] && r_s1_io_out_s2_full_pred_1_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[30] && r_s1_io_out_s2_full_pred_1_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[31] && r_s1_io_out_s2_full_pred_1_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[32] && r_s1_io_out_s2_full_pred_1_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[33] && r_s1_io_out_s2_full_pred_1_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[34] && r_s1_io_out_s2_full_pred_1_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[35] && r_s1_io_out_s2_full_pred_1_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[36] && r_s1_io_out_s2_full_pred_1_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[37] && r_s1_io_out_s2_full_pred_1_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[38] && r_s1_io_out_s2_full_pred_1_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[39] && r_s1_io_out_s2_full_pred_1_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[40] && r_s1_io_out_s2_full_pred_1_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[41] && r_s1_io_out_s2_full_pred_1_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[42] && r_s1_io_out_s2_full_pred_1_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[43] && r_s1_io_out_s2_full_pred_1_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[44] && r_s1_io_out_s2_full_pred_1_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[45] && r_s1_io_out_s2_full_pred_1_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[46] && r_s1_io_out_s2_full_pred_1_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[47] && r_s1_io_out_s2_full_pred_1_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[48] && r_s1_io_out_s2_full_pred_1_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_targets_1[49] && r_s1_io_out_s2_full_pred_1_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[0] && r_s1_io_out_s2_full_pred_1_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[1] && r_s1_io_out_s2_full_pred_1_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[2] && r_s1_io_out_s2_full_pred_1_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[3] && r_s1_io_out_s2_full_pred_1_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[4] && r_s1_io_out_s2_full_pred_1_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[5] && r_s1_io_out_s2_full_pred_1_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[6] && r_s1_io_out_s2_full_pred_1_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[7] && r_s1_io_out_s2_full_pred_1_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[8] && r_s1_io_out_s2_full_pred_1_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[9] && r_s1_io_out_s2_full_pred_1_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[10] && r_s1_io_out_s2_full_pred_1_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[11] && r_s1_io_out_s2_full_pred_1_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[12] && r_s1_io_out_s2_full_pred_1_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[13] && r_s1_io_out_s2_full_pred_1_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[14] && r_s1_io_out_s2_full_pred_1_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[15] && r_s1_io_out_s2_full_pred_1_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[16] && r_s1_io_out_s2_full_pred_1_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[17] && r_s1_io_out_s2_full_pred_1_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[18] && r_s1_io_out_s2_full_pred_1_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[19] && r_s1_io_out_s2_full_pred_1_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[20] && r_s1_io_out_s2_full_pred_1_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[21] && r_s1_io_out_s2_full_pred_1_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[22] && r_s1_io_out_s2_full_pred_1_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[23] && r_s1_io_out_s2_full_pred_1_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[24] && r_s1_io_out_s2_full_pred_1_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[25] && r_s1_io_out_s2_full_pred_1_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[26] && r_s1_io_out_s2_full_pred_1_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[27] && r_s1_io_out_s2_full_pred_1_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[28] && r_s1_io_out_s2_full_pred_1_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[29] && r_s1_io_out_s2_full_pred_1_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[30] && r_s1_io_out_s2_full_pred_1_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[31] && r_s1_io_out_s2_full_pred_1_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[32] && r_s1_io_out_s2_full_pred_1_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[33] && r_s1_io_out_s2_full_pred_1_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[34] && r_s1_io_out_s2_full_pred_1_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[35] && r_s1_io_out_s2_full_pred_1_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[36] && r_s1_io_out_s2_full_pred_1_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[37] && r_s1_io_out_s2_full_pred_1_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[38] && r_s1_io_out_s2_full_pred_1_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[39] && r_s1_io_out_s2_full_pred_1_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[40] && r_s1_io_out_s2_full_pred_1_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[41] && r_s1_io_out_s2_full_pred_1_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[42] && r_s1_io_out_s2_full_pred_1_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[43] && r_s1_io_out_s2_full_pred_1_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[44] && r_s1_io_out_s2_full_pred_1_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[45] && r_s1_io_out_s2_full_pred_1_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[46] && r_s1_io_out_s2_full_pred_1_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[47] && r_s1_io_out_s2_full_pred_1_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[48] && r_s1_io_out_s2_full_pred_1_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_jalr_target[49] && r_s1_io_out_s2_full_pred_1_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_0[0] && r_s1_io_out_s2_full_pred_1_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_0[1] && r_s1_io_out_s2_full_pred_1_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_0[2] && r_s1_io_out_s2_full_pred_1_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_0[3] && r_s1_io_out_s2_full_pred_1_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_1[0] && r_s1_io_out_s2_full_pred_1_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_1[1] && r_s1_io_out_s2_full_pred_1_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_1[2] && r_s1_io_out_s2_full_pred_1_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_offsets_1[3] && r_s1_io_out_s2_full_pred_1_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[0] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[1] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[2] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[3] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[4] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[5] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[6] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[7] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[8] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[9] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[10] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[11] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[12] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[13] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[14] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[15] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[16] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[17] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[18] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[19] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[20] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[21] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[22] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[23] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[24] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[25] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[26] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[27] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[28] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[29] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[30] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[31] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[32] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[33] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[34] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[35] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[36] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[37] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[38] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[39] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[40] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[41] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[42] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[43] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[44] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[45] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[46] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[47] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[48] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughAddr[49] && r_s1_io_out_s2_full_pred_1_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_fallThroughErr && r_s1_io_out_s2_full_pred_1_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_is_jal && r_s1_io_out_s2_full_pred_1_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_is_jalr && r_s1_io_out_s2_full_pred_1_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_is_call && r_s1_io_out_s2_full_pred_1_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_is_ret && r_s1_io_out_s2_full_pred_1_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_last_may_be_rvi_call && r_s1_io_out_s2_full_pred_1_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_is_br_sharing && r_s1_io_out_s2_full_pred_1_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_1_hit && r_s1_io_out_s2_full_pred_1_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_1_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_br_taken_mask_0 && r_s1_io_out_s2_full_pred_2_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_br_taken_mask_1 && r_s1_io_out_s2_full_pred_2_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_slot_valids_0 && r_s1_io_out_s2_full_pred_2_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_slot_valids_1 && r_s1_io_out_s2_full_pred_2_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[0] && r_s1_io_out_s2_full_pred_2_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[1] && r_s1_io_out_s2_full_pred_2_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[2] && r_s1_io_out_s2_full_pred_2_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[3] && r_s1_io_out_s2_full_pred_2_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[4] && r_s1_io_out_s2_full_pred_2_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[5] && r_s1_io_out_s2_full_pred_2_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[6] && r_s1_io_out_s2_full_pred_2_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[7] && r_s1_io_out_s2_full_pred_2_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[8] && r_s1_io_out_s2_full_pred_2_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[9] && r_s1_io_out_s2_full_pred_2_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[10] && r_s1_io_out_s2_full_pred_2_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[11] && r_s1_io_out_s2_full_pred_2_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[12] && r_s1_io_out_s2_full_pred_2_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[13] && r_s1_io_out_s2_full_pred_2_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[14] && r_s1_io_out_s2_full_pred_2_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[15] && r_s1_io_out_s2_full_pred_2_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[16] && r_s1_io_out_s2_full_pred_2_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[17] && r_s1_io_out_s2_full_pred_2_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[18] && r_s1_io_out_s2_full_pred_2_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[19] && r_s1_io_out_s2_full_pred_2_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[20] && r_s1_io_out_s2_full_pred_2_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[21] && r_s1_io_out_s2_full_pred_2_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[22] && r_s1_io_out_s2_full_pred_2_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[23] && r_s1_io_out_s2_full_pred_2_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[24] && r_s1_io_out_s2_full_pred_2_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[25] && r_s1_io_out_s2_full_pred_2_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[26] && r_s1_io_out_s2_full_pred_2_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[27] && r_s1_io_out_s2_full_pred_2_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[28] && r_s1_io_out_s2_full_pred_2_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[29] && r_s1_io_out_s2_full_pred_2_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[30] && r_s1_io_out_s2_full_pred_2_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[31] && r_s1_io_out_s2_full_pred_2_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[32] && r_s1_io_out_s2_full_pred_2_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[33] && r_s1_io_out_s2_full_pred_2_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[34] && r_s1_io_out_s2_full_pred_2_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[35] && r_s1_io_out_s2_full_pred_2_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[36] && r_s1_io_out_s2_full_pred_2_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[37] && r_s1_io_out_s2_full_pred_2_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[38] && r_s1_io_out_s2_full_pred_2_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[39] && r_s1_io_out_s2_full_pred_2_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[40] && r_s1_io_out_s2_full_pred_2_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[41] && r_s1_io_out_s2_full_pred_2_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[42] && r_s1_io_out_s2_full_pred_2_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[43] && r_s1_io_out_s2_full_pred_2_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[44] && r_s1_io_out_s2_full_pred_2_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[45] && r_s1_io_out_s2_full_pred_2_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[46] && r_s1_io_out_s2_full_pred_2_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[47] && r_s1_io_out_s2_full_pred_2_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[48] && r_s1_io_out_s2_full_pred_2_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_0[49] && r_s1_io_out_s2_full_pred_2_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[0] && r_s1_io_out_s2_full_pred_2_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[1] && r_s1_io_out_s2_full_pred_2_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[2] && r_s1_io_out_s2_full_pred_2_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[3] && r_s1_io_out_s2_full_pred_2_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[4] && r_s1_io_out_s2_full_pred_2_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[5] && r_s1_io_out_s2_full_pred_2_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[6] && r_s1_io_out_s2_full_pred_2_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[7] && r_s1_io_out_s2_full_pred_2_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[8] && r_s1_io_out_s2_full_pred_2_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[9] && r_s1_io_out_s2_full_pred_2_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[10] && r_s1_io_out_s2_full_pred_2_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[11] && r_s1_io_out_s2_full_pred_2_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[12] && r_s1_io_out_s2_full_pred_2_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[13] && r_s1_io_out_s2_full_pred_2_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[14] && r_s1_io_out_s2_full_pred_2_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[15] && r_s1_io_out_s2_full_pred_2_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[16] && r_s1_io_out_s2_full_pred_2_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[17] && r_s1_io_out_s2_full_pred_2_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[18] && r_s1_io_out_s2_full_pred_2_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[19] && r_s1_io_out_s2_full_pred_2_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[20] && r_s1_io_out_s2_full_pred_2_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[21] && r_s1_io_out_s2_full_pred_2_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[22] && r_s1_io_out_s2_full_pred_2_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[23] && r_s1_io_out_s2_full_pred_2_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[24] && r_s1_io_out_s2_full_pred_2_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[25] && r_s1_io_out_s2_full_pred_2_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[26] && r_s1_io_out_s2_full_pred_2_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[27] && r_s1_io_out_s2_full_pred_2_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[28] && r_s1_io_out_s2_full_pred_2_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[29] && r_s1_io_out_s2_full_pred_2_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[30] && r_s1_io_out_s2_full_pred_2_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[31] && r_s1_io_out_s2_full_pred_2_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[32] && r_s1_io_out_s2_full_pred_2_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[33] && r_s1_io_out_s2_full_pred_2_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[34] && r_s1_io_out_s2_full_pred_2_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[35] && r_s1_io_out_s2_full_pred_2_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[36] && r_s1_io_out_s2_full_pred_2_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[37] && r_s1_io_out_s2_full_pred_2_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[38] && r_s1_io_out_s2_full_pred_2_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[39] && r_s1_io_out_s2_full_pred_2_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[40] && r_s1_io_out_s2_full_pred_2_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[41] && r_s1_io_out_s2_full_pred_2_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[42] && r_s1_io_out_s2_full_pred_2_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[43] && r_s1_io_out_s2_full_pred_2_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[44] && r_s1_io_out_s2_full_pred_2_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[45] && r_s1_io_out_s2_full_pred_2_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[46] && r_s1_io_out_s2_full_pred_2_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[47] && r_s1_io_out_s2_full_pred_2_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[48] && r_s1_io_out_s2_full_pred_2_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_targets_1[49] && r_s1_io_out_s2_full_pred_2_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[0] && r_s1_io_out_s2_full_pred_2_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[1] && r_s1_io_out_s2_full_pred_2_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[2] && r_s1_io_out_s2_full_pred_2_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[3] && r_s1_io_out_s2_full_pred_2_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[4] && r_s1_io_out_s2_full_pred_2_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[5] && r_s1_io_out_s2_full_pred_2_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[6] && r_s1_io_out_s2_full_pred_2_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[7] && r_s1_io_out_s2_full_pred_2_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[8] && r_s1_io_out_s2_full_pred_2_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[9] && r_s1_io_out_s2_full_pred_2_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[10] && r_s1_io_out_s2_full_pred_2_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[11] && r_s1_io_out_s2_full_pred_2_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[12] && r_s1_io_out_s2_full_pred_2_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[13] && r_s1_io_out_s2_full_pred_2_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[14] && r_s1_io_out_s2_full_pred_2_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[15] && r_s1_io_out_s2_full_pred_2_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[16] && r_s1_io_out_s2_full_pred_2_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[17] && r_s1_io_out_s2_full_pred_2_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[18] && r_s1_io_out_s2_full_pred_2_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[19] && r_s1_io_out_s2_full_pred_2_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[20] && r_s1_io_out_s2_full_pred_2_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[21] && r_s1_io_out_s2_full_pred_2_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[22] && r_s1_io_out_s2_full_pred_2_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[23] && r_s1_io_out_s2_full_pred_2_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[24] && r_s1_io_out_s2_full_pred_2_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[25] && r_s1_io_out_s2_full_pred_2_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[26] && r_s1_io_out_s2_full_pred_2_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[27] && r_s1_io_out_s2_full_pred_2_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[28] && r_s1_io_out_s2_full_pred_2_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[29] && r_s1_io_out_s2_full_pred_2_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[30] && r_s1_io_out_s2_full_pred_2_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[31] && r_s1_io_out_s2_full_pred_2_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[32] && r_s1_io_out_s2_full_pred_2_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[33] && r_s1_io_out_s2_full_pred_2_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[34] && r_s1_io_out_s2_full_pred_2_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[35] && r_s1_io_out_s2_full_pred_2_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[36] && r_s1_io_out_s2_full_pred_2_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[37] && r_s1_io_out_s2_full_pred_2_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[38] && r_s1_io_out_s2_full_pred_2_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[39] && r_s1_io_out_s2_full_pred_2_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[40] && r_s1_io_out_s2_full_pred_2_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[41] && r_s1_io_out_s2_full_pred_2_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[42] && r_s1_io_out_s2_full_pred_2_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[43] && r_s1_io_out_s2_full_pred_2_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[44] && r_s1_io_out_s2_full_pred_2_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[45] && r_s1_io_out_s2_full_pred_2_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[46] && r_s1_io_out_s2_full_pred_2_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[47] && r_s1_io_out_s2_full_pred_2_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[48] && r_s1_io_out_s2_full_pred_2_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_jalr_target[49] && r_s1_io_out_s2_full_pred_2_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_0[0] && r_s1_io_out_s2_full_pred_2_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_0[1] && r_s1_io_out_s2_full_pred_2_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_0[2] && r_s1_io_out_s2_full_pred_2_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_0[3] && r_s1_io_out_s2_full_pred_2_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_1[0] && r_s1_io_out_s2_full_pred_2_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_1[1] && r_s1_io_out_s2_full_pred_2_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_1[2] && r_s1_io_out_s2_full_pred_2_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_offsets_1[3] && r_s1_io_out_s2_full_pred_2_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[0] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[1] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[2] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[3] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[4] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[5] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[6] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[7] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[8] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[9] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[10] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[11] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[12] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[13] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[14] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[15] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[16] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[17] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[18] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[19] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[20] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[21] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[22] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[23] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[24] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[25] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[26] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[27] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[28] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[29] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[30] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[31] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[32] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[33] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[34] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[35] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[36] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[37] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[38] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[39] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[40] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[41] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[42] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[43] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[44] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[45] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[46] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[47] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[48] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughAddr[49] && r_s1_io_out_s2_full_pred_2_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_fallThroughErr && r_s1_io_out_s2_full_pred_2_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_is_jal && r_s1_io_out_s2_full_pred_2_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_is_jalr && r_s1_io_out_s2_full_pred_2_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_is_call && r_s1_io_out_s2_full_pred_2_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_is_ret && r_s1_io_out_s2_full_pred_2_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_last_may_be_rvi_call && r_s1_io_out_s2_full_pred_2_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_is_br_sharing && r_s1_io_out_s2_full_pred_2_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_2_hit && r_s1_io_out_s2_full_pred_2_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_2_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_br_taken_mask_0 && r_s1_io_out_s2_full_pred_3_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_br_taken_mask_1 && r_s1_io_out_s2_full_pred_3_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_slot_valids_0 && r_s1_io_out_s2_full_pred_3_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_slot_valids_1 && r_s1_io_out_s2_full_pred_3_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[0] && r_s1_io_out_s2_full_pred_3_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[1] && r_s1_io_out_s2_full_pred_3_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[2] && r_s1_io_out_s2_full_pred_3_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[3] && r_s1_io_out_s2_full_pred_3_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[4] && r_s1_io_out_s2_full_pred_3_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[5] && r_s1_io_out_s2_full_pred_3_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[6] && r_s1_io_out_s2_full_pred_3_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[7] && r_s1_io_out_s2_full_pred_3_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[8] && r_s1_io_out_s2_full_pred_3_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[9] && r_s1_io_out_s2_full_pred_3_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[10] && r_s1_io_out_s2_full_pred_3_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[11] && r_s1_io_out_s2_full_pred_3_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[12] && r_s1_io_out_s2_full_pred_3_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[13] && r_s1_io_out_s2_full_pred_3_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[14] && r_s1_io_out_s2_full_pred_3_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[15] && r_s1_io_out_s2_full_pred_3_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[16] && r_s1_io_out_s2_full_pred_3_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[17] && r_s1_io_out_s2_full_pred_3_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[18] && r_s1_io_out_s2_full_pred_3_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[19] && r_s1_io_out_s2_full_pred_3_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[20] && r_s1_io_out_s2_full_pred_3_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[21] && r_s1_io_out_s2_full_pred_3_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[22] && r_s1_io_out_s2_full_pred_3_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[23] && r_s1_io_out_s2_full_pred_3_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[24] && r_s1_io_out_s2_full_pred_3_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[25] && r_s1_io_out_s2_full_pred_3_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[26] && r_s1_io_out_s2_full_pred_3_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[27] && r_s1_io_out_s2_full_pred_3_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[28] && r_s1_io_out_s2_full_pred_3_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[29] && r_s1_io_out_s2_full_pred_3_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[30] && r_s1_io_out_s2_full_pred_3_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[31] && r_s1_io_out_s2_full_pred_3_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[32] && r_s1_io_out_s2_full_pred_3_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[33] && r_s1_io_out_s2_full_pred_3_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[34] && r_s1_io_out_s2_full_pred_3_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[35] && r_s1_io_out_s2_full_pred_3_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[36] && r_s1_io_out_s2_full_pred_3_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[37] && r_s1_io_out_s2_full_pred_3_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[38] && r_s1_io_out_s2_full_pred_3_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[39] && r_s1_io_out_s2_full_pred_3_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[40] && r_s1_io_out_s2_full_pred_3_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[41] && r_s1_io_out_s2_full_pred_3_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[42] && r_s1_io_out_s2_full_pred_3_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[43] && r_s1_io_out_s2_full_pred_3_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[44] && r_s1_io_out_s2_full_pred_3_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[45] && r_s1_io_out_s2_full_pred_3_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[46] && r_s1_io_out_s2_full_pred_3_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[47] && r_s1_io_out_s2_full_pred_3_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[48] && r_s1_io_out_s2_full_pred_3_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_0[49] && r_s1_io_out_s2_full_pred_3_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[0] && r_s1_io_out_s2_full_pred_3_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[1] && r_s1_io_out_s2_full_pred_3_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[2] && r_s1_io_out_s2_full_pred_3_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[3] && r_s1_io_out_s2_full_pred_3_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[4] && r_s1_io_out_s2_full_pred_3_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[5] && r_s1_io_out_s2_full_pred_3_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[6] && r_s1_io_out_s2_full_pred_3_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[7] && r_s1_io_out_s2_full_pred_3_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[8] && r_s1_io_out_s2_full_pred_3_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[9] && r_s1_io_out_s2_full_pred_3_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[10] && r_s1_io_out_s2_full_pred_3_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[11] && r_s1_io_out_s2_full_pred_3_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[12] && r_s1_io_out_s2_full_pred_3_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[13] && r_s1_io_out_s2_full_pred_3_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[14] && r_s1_io_out_s2_full_pred_3_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[15] && r_s1_io_out_s2_full_pred_3_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[16] && r_s1_io_out_s2_full_pred_3_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[17] && r_s1_io_out_s2_full_pred_3_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[18] && r_s1_io_out_s2_full_pred_3_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[19] && r_s1_io_out_s2_full_pred_3_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[20] && r_s1_io_out_s2_full_pred_3_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[21] && r_s1_io_out_s2_full_pred_3_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[22] && r_s1_io_out_s2_full_pred_3_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[23] && r_s1_io_out_s2_full_pred_3_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[24] && r_s1_io_out_s2_full_pred_3_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[25] && r_s1_io_out_s2_full_pred_3_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[26] && r_s1_io_out_s2_full_pred_3_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[27] && r_s1_io_out_s2_full_pred_3_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[28] && r_s1_io_out_s2_full_pred_3_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[29] && r_s1_io_out_s2_full_pred_3_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[30] && r_s1_io_out_s2_full_pred_3_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[31] && r_s1_io_out_s2_full_pred_3_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[32] && r_s1_io_out_s2_full_pred_3_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[33] && r_s1_io_out_s2_full_pred_3_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[34] && r_s1_io_out_s2_full_pred_3_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[35] && r_s1_io_out_s2_full_pred_3_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[36] && r_s1_io_out_s2_full_pred_3_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[37] && r_s1_io_out_s2_full_pred_3_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[38] && r_s1_io_out_s2_full_pred_3_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[39] && r_s1_io_out_s2_full_pred_3_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[40] && r_s1_io_out_s2_full_pred_3_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[41] && r_s1_io_out_s2_full_pred_3_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[42] && r_s1_io_out_s2_full_pred_3_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[43] && r_s1_io_out_s2_full_pred_3_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[44] && r_s1_io_out_s2_full_pred_3_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[45] && r_s1_io_out_s2_full_pred_3_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[46] && r_s1_io_out_s2_full_pred_3_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[47] && r_s1_io_out_s2_full_pred_3_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[48] && r_s1_io_out_s2_full_pred_3_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_targets_1[49] && r_s1_io_out_s2_full_pred_3_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[0] && r_s1_io_out_s2_full_pred_3_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[1] && r_s1_io_out_s2_full_pred_3_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[2] && r_s1_io_out_s2_full_pred_3_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[3] && r_s1_io_out_s2_full_pred_3_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[4] && r_s1_io_out_s2_full_pred_3_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[5] && r_s1_io_out_s2_full_pred_3_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[6] && r_s1_io_out_s2_full_pred_3_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[7] && r_s1_io_out_s2_full_pred_3_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[8] && r_s1_io_out_s2_full_pred_3_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[9] && r_s1_io_out_s2_full_pred_3_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[10] && r_s1_io_out_s2_full_pred_3_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[11] && r_s1_io_out_s2_full_pred_3_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[12] && r_s1_io_out_s2_full_pred_3_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[13] && r_s1_io_out_s2_full_pred_3_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[14] && r_s1_io_out_s2_full_pred_3_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[15] && r_s1_io_out_s2_full_pred_3_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[16] && r_s1_io_out_s2_full_pred_3_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[17] && r_s1_io_out_s2_full_pred_3_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[18] && r_s1_io_out_s2_full_pred_3_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[19] && r_s1_io_out_s2_full_pred_3_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[20] && r_s1_io_out_s2_full_pred_3_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[21] && r_s1_io_out_s2_full_pred_3_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[22] && r_s1_io_out_s2_full_pred_3_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[23] && r_s1_io_out_s2_full_pred_3_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[24] && r_s1_io_out_s2_full_pred_3_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[25] && r_s1_io_out_s2_full_pred_3_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[26] && r_s1_io_out_s2_full_pred_3_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[27] && r_s1_io_out_s2_full_pred_3_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[28] && r_s1_io_out_s2_full_pred_3_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[29] && r_s1_io_out_s2_full_pred_3_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[30] && r_s1_io_out_s2_full_pred_3_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[31] && r_s1_io_out_s2_full_pred_3_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[32] && r_s1_io_out_s2_full_pred_3_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[33] && r_s1_io_out_s2_full_pred_3_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[34] && r_s1_io_out_s2_full_pred_3_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[35] && r_s1_io_out_s2_full_pred_3_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[36] && r_s1_io_out_s2_full_pred_3_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[37] && r_s1_io_out_s2_full_pred_3_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[38] && r_s1_io_out_s2_full_pred_3_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[39] && r_s1_io_out_s2_full_pred_3_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[40] && r_s1_io_out_s2_full_pred_3_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[41] && r_s1_io_out_s2_full_pred_3_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[42] && r_s1_io_out_s2_full_pred_3_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[43] && r_s1_io_out_s2_full_pred_3_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[44] && r_s1_io_out_s2_full_pred_3_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[45] && r_s1_io_out_s2_full_pred_3_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[46] && r_s1_io_out_s2_full_pred_3_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[47] && r_s1_io_out_s2_full_pred_3_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[48] && r_s1_io_out_s2_full_pred_3_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_jalr_target[49] && r_s1_io_out_s2_full_pred_3_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_0[0] && r_s1_io_out_s2_full_pred_3_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_0[1] && r_s1_io_out_s2_full_pred_3_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_0[2] && r_s1_io_out_s2_full_pred_3_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_0[3] && r_s1_io_out_s2_full_pred_3_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_1[0] && r_s1_io_out_s2_full_pred_3_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_1[1] && r_s1_io_out_s2_full_pred_3_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_1[2] && r_s1_io_out_s2_full_pred_3_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_offsets_1[3] && r_s1_io_out_s2_full_pred_3_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[0] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[1] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[2] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[3] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[4] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[5] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[6] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[7] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[8] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[9] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[10] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[11] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[12] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[13] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[14] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[15] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[16] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[17] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[18] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[19] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[20] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[21] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[22] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[23] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[24] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[25] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[26] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[27] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[28] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[29] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[30] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[31] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[32] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[33] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[34] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[35] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[36] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[37] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[38] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[39] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[40] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[41] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[42] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[43] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[44] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[45] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[46] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[47] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[48] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughAddr[49] && r_s1_io_out_s2_full_pred_3_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_fallThroughErr && r_s1_io_out_s2_full_pred_3_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_is_jal && r_s1_io_out_s2_full_pred_3_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_is_jalr && r_s1_io_out_s2_full_pred_3_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_is_call && r_s1_io_out_s2_full_pred_3_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_is_ret && r_s1_io_out_s2_full_pred_3_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_last_may_be_rvi_call && r_s1_io_out_s2_full_pred_3_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_is_br_sharing && r_s1_io_out_s2_full_pred_3_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s2_full_pred_3_hit && r_s1_io_out_s2_full_pred_3_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s2_full_pred_3_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[0] && r_s1_io_out_s3_pc_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[1] && r_s1_io_out_s3_pc_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[2] && r_s1_io_out_s3_pc_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[3] && r_s1_io_out_s3_pc_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[4] && r_s1_io_out_s3_pc_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[5] && r_s1_io_out_s3_pc_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[6] && r_s1_io_out_s3_pc_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[7] && r_s1_io_out_s3_pc_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[8] && r_s1_io_out_s3_pc_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[9] && r_s1_io_out_s3_pc_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[10] && r_s1_io_out_s3_pc_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[11] && r_s1_io_out_s3_pc_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[12] && r_s1_io_out_s3_pc_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[13] && r_s1_io_out_s3_pc_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[14] && r_s1_io_out_s3_pc_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[15] && r_s1_io_out_s3_pc_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[16] && r_s1_io_out_s3_pc_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[17] && r_s1_io_out_s3_pc_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[18] && r_s1_io_out_s3_pc_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[19] && r_s1_io_out_s3_pc_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[20] && r_s1_io_out_s3_pc_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[21] && r_s1_io_out_s3_pc_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[22] && r_s1_io_out_s3_pc_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[23] && r_s1_io_out_s3_pc_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[24] && r_s1_io_out_s3_pc_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[25] && r_s1_io_out_s3_pc_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[26] && r_s1_io_out_s3_pc_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[27] && r_s1_io_out_s3_pc_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[28] && r_s1_io_out_s3_pc_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[29] && r_s1_io_out_s3_pc_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[30] && r_s1_io_out_s3_pc_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[31] && r_s1_io_out_s3_pc_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[32] && r_s1_io_out_s3_pc_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[33] && r_s1_io_out_s3_pc_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[34] && r_s1_io_out_s3_pc_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[35] && r_s1_io_out_s3_pc_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[36] && r_s1_io_out_s3_pc_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[37] && r_s1_io_out_s3_pc_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[38] && r_s1_io_out_s3_pc_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[39] && r_s1_io_out_s3_pc_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[40] && r_s1_io_out_s3_pc_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[41] && r_s1_io_out_s3_pc_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[42] && r_s1_io_out_s3_pc_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[43] && r_s1_io_out_s3_pc_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[44] && r_s1_io_out_s3_pc_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[45] && r_s1_io_out_s3_pc_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[46] && r_s1_io_out_s3_pc_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[47] && r_s1_io_out_s3_pc_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[48] && r_s1_io_out_s3_pc_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_0[49] && r_s1_io_out_s3_pc_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[0] && r_s1_io_out_s3_pc_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[1] && r_s1_io_out_s3_pc_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[2] && r_s1_io_out_s3_pc_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[3] && r_s1_io_out_s3_pc_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[4] && r_s1_io_out_s3_pc_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[5] && r_s1_io_out_s3_pc_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[6] && r_s1_io_out_s3_pc_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[7] && r_s1_io_out_s3_pc_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[8] && r_s1_io_out_s3_pc_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[9] && r_s1_io_out_s3_pc_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[10] && r_s1_io_out_s3_pc_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[11] && r_s1_io_out_s3_pc_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[12] && r_s1_io_out_s3_pc_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[13] && r_s1_io_out_s3_pc_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[14] && r_s1_io_out_s3_pc_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[15] && r_s1_io_out_s3_pc_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[16] && r_s1_io_out_s3_pc_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[17] && r_s1_io_out_s3_pc_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[18] && r_s1_io_out_s3_pc_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[19] && r_s1_io_out_s3_pc_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[20] && r_s1_io_out_s3_pc_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[21] && r_s1_io_out_s3_pc_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[22] && r_s1_io_out_s3_pc_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[23] && r_s1_io_out_s3_pc_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[24] && r_s1_io_out_s3_pc_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[25] && r_s1_io_out_s3_pc_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[26] && r_s1_io_out_s3_pc_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[27] && r_s1_io_out_s3_pc_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[28] && r_s1_io_out_s3_pc_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[29] && r_s1_io_out_s3_pc_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[30] && r_s1_io_out_s3_pc_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[31] && r_s1_io_out_s3_pc_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[32] && r_s1_io_out_s3_pc_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[33] && r_s1_io_out_s3_pc_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[34] && r_s1_io_out_s3_pc_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[35] && r_s1_io_out_s3_pc_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[36] && r_s1_io_out_s3_pc_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[37] && r_s1_io_out_s3_pc_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[38] && r_s1_io_out_s3_pc_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[39] && r_s1_io_out_s3_pc_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[40] && r_s1_io_out_s3_pc_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[41] && r_s1_io_out_s3_pc_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[42] && r_s1_io_out_s3_pc_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[43] && r_s1_io_out_s3_pc_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[44] && r_s1_io_out_s3_pc_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[45] && r_s1_io_out_s3_pc_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[46] && r_s1_io_out_s3_pc_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[47] && r_s1_io_out_s3_pc_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[48] && r_s1_io_out_s3_pc_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_1[49] && r_s1_io_out_s3_pc_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[0] && r_s1_io_out_s3_pc_2[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[1] && r_s1_io_out_s3_pc_2[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[2] && r_s1_io_out_s3_pc_2[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[3] && r_s1_io_out_s3_pc_2[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[4] && r_s1_io_out_s3_pc_2[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[5] && r_s1_io_out_s3_pc_2[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[6] && r_s1_io_out_s3_pc_2[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[7] && r_s1_io_out_s3_pc_2[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[8] && r_s1_io_out_s3_pc_2[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[9] && r_s1_io_out_s3_pc_2[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[10] && r_s1_io_out_s3_pc_2[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[11] && r_s1_io_out_s3_pc_2[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[12] && r_s1_io_out_s3_pc_2[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[13] && r_s1_io_out_s3_pc_2[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[14] && r_s1_io_out_s3_pc_2[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[15] && r_s1_io_out_s3_pc_2[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[16] && r_s1_io_out_s3_pc_2[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[17] && r_s1_io_out_s3_pc_2[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[18] && r_s1_io_out_s3_pc_2[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[19] && r_s1_io_out_s3_pc_2[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[20] && r_s1_io_out_s3_pc_2[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[21] && r_s1_io_out_s3_pc_2[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[22] && r_s1_io_out_s3_pc_2[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[23] && r_s1_io_out_s3_pc_2[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[24] && r_s1_io_out_s3_pc_2[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[25] && r_s1_io_out_s3_pc_2[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[26] && r_s1_io_out_s3_pc_2[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[27] && r_s1_io_out_s3_pc_2[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[28] && r_s1_io_out_s3_pc_2[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[29] && r_s1_io_out_s3_pc_2[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[30] && r_s1_io_out_s3_pc_2[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[31] && r_s1_io_out_s3_pc_2[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[32] && r_s1_io_out_s3_pc_2[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[33] && r_s1_io_out_s3_pc_2[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[34] && r_s1_io_out_s3_pc_2[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[35] && r_s1_io_out_s3_pc_2[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[36] && r_s1_io_out_s3_pc_2[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[37] && r_s1_io_out_s3_pc_2[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[38] && r_s1_io_out_s3_pc_2[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[39] && r_s1_io_out_s3_pc_2[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[40] && r_s1_io_out_s3_pc_2[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[41] && r_s1_io_out_s3_pc_2[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[42] && r_s1_io_out_s3_pc_2[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[43] && r_s1_io_out_s3_pc_2[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[44] && r_s1_io_out_s3_pc_2[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[45] && r_s1_io_out_s3_pc_2[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[46] && r_s1_io_out_s3_pc_2[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[47] && r_s1_io_out_s3_pc_2[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[48] && r_s1_io_out_s3_pc_2[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_2[49] && r_s1_io_out_s3_pc_2[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_2[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[0] && r_s1_io_out_s3_pc_3[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[1] && r_s1_io_out_s3_pc_3[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[2] && r_s1_io_out_s3_pc_3[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[3] && r_s1_io_out_s3_pc_3[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[4] && r_s1_io_out_s3_pc_3[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[5] && r_s1_io_out_s3_pc_3[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[6] && r_s1_io_out_s3_pc_3[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[7] && r_s1_io_out_s3_pc_3[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[8] && r_s1_io_out_s3_pc_3[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[9] && r_s1_io_out_s3_pc_3[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[10] && r_s1_io_out_s3_pc_3[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[11] && r_s1_io_out_s3_pc_3[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[12] && r_s1_io_out_s3_pc_3[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[13] && r_s1_io_out_s3_pc_3[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[14] && r_s1_io_out_s3_pc_3[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[15] && r_s1_io_out_s3_pc_3[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[16] && r_s1_io_out_s3_pc_3[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[17] && r_s1_io_out_s3_pc_3[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[18] && r_s1_io_out_s3_pc_3[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[19] && r_s1_io_out_s3_pc_3[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[20] && r_s1_io_out_s3_pc_3[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[21] && r_s1_io_out_s3_pc_3[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[22] && r_s1_io_out_s3_pc_3[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[23] && r_s1_io_out_s3_pc_3[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[24] && r_s1_io_out_s3_pc_3[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[25] && r_s1_io_out_s3_pc_3[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[26] && r_s1_io_out_s3_pc_3[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[27] && r_s1_io_out_s3_pc_3[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[28] && r_s1_io_out_s3_pc_3[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[29] && r_s1_io_out_s3_pc_3[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[30] && r_s1_io_out_s3_pc_3[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[31] && r_s1_io_out_s3_pc_3[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[32] && r_s1_io_out_s3_pc_3[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[33] && r_s1_io_out_s3_pc_3[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[34] && r_s1_io_out_s3_pc_3[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[35] && r_s1_io_out_s3_pc_3[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[36] && r_s1_io_out_s3_pc_3[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[37] && r_s1_io_out_s3_pc_3[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[38] && r_s1_io_out_s3_pc_3[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[39] && r_s1_io_out_s3_pc_3[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[40] && r_s1_io_out_s3_pc_3[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[41] && r_s1_io_out_s3_pc_3[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[42] && r_s1_io_out_s3_pc_3[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[43] && r_s1_io_out_s3_pc_3[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[44] && r_s1_io_out_s3_pc_3[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[45] && r_s1_io_out_s3_pc_3[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[46] && r_s1_io_out_s3_pc_3[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[47] && r_s1_io_out_s3_pc_3[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[48] && r_s1_io_out_s3_pc_3[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_pc_3[49] && r_s1_io_out_s3_pc_3[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_pc_3[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_br_taken_mask_0 && r_s1_io_out_s3_full_pred_0_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_br_taken_mask_1 && r_s1_io_out_s3_full_pred_0_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_slot_valids_0 && r_s1_io_out_s3_full_pred_0_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_slot_valids_1 && r_s1_io_out_s3_full_pred_0_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[0] && r_s1_io_out_s3_full_pred_0_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[1] && r_s1_io_out_s3_full_pred_0_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[2] && r_s1_io_out_s3_full_pred_0_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[3] && r_s1_io_out_s3_full_pred_0_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[4] && r_s1_io_out_s3_full_pred_0_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[5] && r_s1_io_out_s3_full_pred_0_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[6] && r_s1_io_out_s3_full_pred_0_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[7] && r_s1_io_out_s3_full_pred_0_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[8] && r_s1_io_out_s3_full_pred_0_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[9] && r_s1_io_out_s3_full_pred_0_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[10] && r_s1_io_out_s3_full_pred_0_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[11] && r_s1_io_out_s3_full_pred_0_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[12] && r_s1_io_out_s3_full_pred_0_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[13] && r_s1_io_out_s3_full_pred_0_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[14] && r_s1_io_out_s3_full_pred_0_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[15] && r_s1_io_out_s3_full_pred_0_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[16] && r_s1_io_out_s3_full_pred_0_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[17] && r_s1_io_out_s3_full_pred_0_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[18] && r_s1_io_out_s3_full_pred_0_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[19] && r_s1_io_out_s3_full_pred_0_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[20] && r_s1_io_out_s3_full_pred_0_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[21] && r_s1_io_out_s3_full_pred_0_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[22] && r_s1_io_out_s3_full_pred_0_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[23] && r_s1_io_out_s3_full_pred_0_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[24] && r_s1_io_out_s3_full_pred_0_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[25] && r_s1_io_out_s3_full_pred_0_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[26] && r_s1_io_out_s3_full_pred_0_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[27] && r_s1_io_out_s3_full_pred_0_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[28] && r_s1_io_out_s3_full_pred_0_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[29] && r_s1_io_out_s3_full_pred_0_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[30] && r_s1_io_out_s3_full_pred_0_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[31] && r_s1_io_out_s3_full_pred_0_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[32] && r_s1_io_out_s3_full_pred_0_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[33] && r_s1_io_out_s3_full_pred_0_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[34] && r_s1_io_out_s3_full_pred_0_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[35] && r_s1_io_out_s3_full_pred_0_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[36] && r_s1_io_out_s3_full_pred_0_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[37] && r_s1_io_out_s3_full_pred_0_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[38] && r_s1_io_out_s3_full_pred_0_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[39] && r_s1_io_out_s3_full_pred_0_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[40] && r_s1_io_out_s3_full_pred_0_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[41] && r_s1_io_out_s3_full_pred_0_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[42] && r_s1_io_out_s3_full_pred_0_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[43] && r_s1_io_out_s3_full_pred_0_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[44] && r_s1_io_out_s3_full_pred_0_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[45] && r_s1_io_out_s3_full_pred_0_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[46] && r_s1_io_out_s3_full_pred_0_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[47] && r_s1_io_out_s3_full_pred_0_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[48] && r_s1_io_out_s3_full_pred_0_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_0[49] && r_s1_io_out_s3_full_pred_0_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[0] && r_s1_io_out_s3_full_pred_0_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[1] && r_s1_io_out_s3_full_pred_0_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[2] && r_s1_io_out_s3_full_pred_0_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[3] && r_s1_io_out_s3_full_pred_0_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[4] && r_s1_io_out_s3_full_pred_0_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[5] && r_s1_io_out_s3_full_pred_0_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[6] && r_s1_io_out_s3_full_pred_0_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[7] && r_s1_io_out_s3_full_pred_0_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[8] && r_s1_io_out_s3_full_pred_0_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[9] && r_s1_io_out_s3_full_pred_0_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[10] && r_s1_io_out_s3_full_pred_0_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[11] && r_s1_io_out_s3_full_pred_0_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[12] && r_s1_io_out_s3_full_pred_0_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[13] && r_s1_io_out_s3_full_pred_0_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[14] && r_s1_io_out_s3_full_pred_0_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[15] && r_s1_io_out_s3_full_pred_0_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[16] && r_s1_io_out_s3_full_pred_0_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[17] && r_s1_io_out_s3_full_pred_0_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[18] && r_s1_io_out_s3_full_pred_0_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[19] && r_s1_io_out_s3_full_pred_0_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[20] && r_s1_io_out_s3_full_pred_0_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[21] && r_s1_io_out_s3_full_pred_0_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[22] && r_s1_io_out_s3_full_pred_0_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[23] && r_s1_io_out_s3_full_pred_0_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[24] && r_s1_io_out_s3_full_pred_0_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[25] && r_s1_io_out_s3_full_pred_0_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[26] && r_s1_io_out_s3_full_pred_0_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[27] && r_s1_io_out_s3_full_pred_0_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[28] && r_s1_io_out_s3_full_pred_0_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[29] && r_s1_io_out_s3_full_pred_0_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[30] && r_s1_io_out_s3_full_pred_0_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[31] && r_s1_io_out_s3_full_pred_0_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[32] && r_s1_io_out_s3_full_pred_0_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[33] && r_s1_io_out_s3_full_pred_0_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[34] && r_s1_io_out_s3_full_pred_0_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[35] && r_s1_io_out_s3_full_pred_0_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[36] && r_s1_io_out_s3_full_pred_0_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[37] && r_s1_io_out_s3_full_pred_0_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[38] && r_s1_io_out_s3_full_pred_0_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[39] && r_s1_io_out_s3_full_pred_0_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[40] && r_s1_io_out_s3_full_pred_0_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[41] && r_s1_io_out_s3_full_pred_0_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[42] && r_s1_io_out_s3_full_pred_0_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[43] && r_s1_io_out_s3_full_pred_0_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[44] && r_s1_io_out_s3_full_pred_0_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[45] && r_s1_io_out_s3_full_pred_0_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[46] && r_s1_io_out_s3_full_pred_0_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[47] && r_s1_io_out_s3_full_pred_0_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[48] && r_s1_io_out_s3_full_pred_0_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_targets_1[49] && r_s1_io_out_s3_full_pred_0_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[0] && r_s1_io_out_s3_full_pred_0_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[1] && r_s1_io_out_s3_full_pred_0_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[2] && r_s1_io_out_s3_full_pred_0_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[3] && r_s1_io_out_s3_full_pred_0_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[4] && r_s1_io_out_s3_full_pred_0_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[5] && r_s1_io_out_s3_full_pred_0_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[6] && r_s1_io_out_s3_full_pred_0_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[7] && r_s1_io_out_s3_full_pred_0_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[8] && r_s1_io_out_s3_full_pred_0_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[9] && r_s1_io_out_s3_full_pred_0_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[10] && r_s1_io_out_s3_full_pred_0_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[11] && r_s1_io_out_s3_full_pred_0_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[12] && r_s1_io_out_s3_full_pred_0_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[13] && r_s1_io_out_s3_full_pred_0_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[14] && r_s1_io_out_s3_full_pred_0_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[15] && r_s1_io_out_s3_full_pred_0_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[16] && r_s1_io_out_s3_full_pred_0_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[17] && r_s1_io_out_s3_full_pred_0_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[18] && r_s1_io_out_s3_full_pred_0_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[19] && r_s1_io_out_s3_full_pred_0_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[20] && r_s1_io_out_s3_full_pred_0_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[21] && r_s1_io_out_s3_full_pred_0_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[22] && r_s1_io_out_s3_full_pred_0_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[23] && r_s1_io_out_s3_full_pred_0_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[24] && r_s1_io_out_s3_full_pred_0_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[25] && r_s1_io_out_s3_full_pred_0_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[26] && r_s1_io_out_s3_full_pred_0_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[27] && r_s1_io_out_s3_full_pred_0_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[28] && r_s1_io_out_s3_full_pred_0_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[29] && r_s1_io_out_s3_full_pred_0_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[30] && r_s1_io_out_s3_full_pred_0_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[31] && r_s1_io_out_s3_full_pred_0_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[32] && r_s1_io_out_s3_full_pred_0_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[33] && r_s1_io_out_s3_full_pred_0_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[34] && r_s1_io_out_s3_full_pred_0_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[35] && r_s1_io_out_s3_full_pred_0_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[36] && r_s1_io_out_s3_full_pred_0_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[37] && r_s1_io_out_s3_full_pred_0_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[38] && r_s1_io_out_s3_full_pred_0_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[39] && r_s1_io_out_s3_full_pred_0_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[40] && r_s1_io_out_s3_full_pred_0_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[41] && r_s1_io_out_s3_full_pred_0_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[42] && r_s1_io_out_s3_full_pred_0_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[43] && r_s1_io_out_s3_full_pred_0_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[44] && r_s1_io_out_s3_full_pred_0_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[45] && r_s1_io_out_s3_full_pred_0_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[46] && r_s1_io_out_s3_full_pred_0_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[47] && r_s1_io_out_s3_full_pred_0_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[48] && r_s1_io_out_s3_full_pred_0_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_jalr_target[49] && r_s1_io_out_s3_full_pred_0_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_0[0] && r_s1_io_out_s3_full_pred_0_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_0[1] && r_s1_io_out_s3_full_pred_0_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_0[2] && r_s1_io_out_s3_full_pred_0_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_0[3] && r_s1_io_out_s3_full_pred_0_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_1[0] && r_s1_io_out_s3_full_pred_0_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_1[1] && r_s1_io_out_s3_full_pred_0_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_1[2] && r_s1_io_out_s3_full_pred_0_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_offsets_1[3] && r_s1_io_out_s3_full_pred_0_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[0] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[1] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[2] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[3] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[4] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[5] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[6] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[7] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[8] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[9] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[10] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[11] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[12] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[13] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[14] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[15] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[16] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[17] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[18] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[19] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[20] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[21] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[22] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[23] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[24] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[25] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[26] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[27] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[28] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[29] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[30] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[31] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[32] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[33] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[34] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[35] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[36] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[37] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[38] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[39] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[40] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[41] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[42] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[43] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[44] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[45] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[46] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[47] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[48] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughAddr[49] && r_s1_io_out_s3_full_pred_0_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_fallThroughErr && r_s1_io_out_s3_full_pred_0_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_multiHit && r_s1_io_out_s3_full_pred_0_multiHit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_multiHit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_is_jal && r_s1_io_out_s3_full_pred_0_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_is_jalr && r_s1_io_out_s3_full_pred_0_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_is_call && r_s1_io_out_s3_full_pred_0_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_is_ret && r_s1_io_out_s3_full_pred_0_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_last_may_be_rvi_call && r_s1_io_out_s3_full_pred_0_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_is_br_sharing && r_s1_io_out_s3_full_pred_0_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_0_hit && r_s1_io_out_s3_full_pred_0_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_0_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_br_taken_mask_0 && r_s1_io_out_s3_full_pred_1_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_br_taken_mask_1 && r_s1_io_out_s3_full_pred_1_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_slot_valids_0 && r_s1_io_out_s3_full_pred_1_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_slot_valids_1 && r_s1_io_out_s3_full_pred_1_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[0] && r_s1_io_out_s3_full_pred_1_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[1] && r_s1_io_out_s3_full_pred_1_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[2] && r_s1_io_out_s3_full_pred_1_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[3] && r_s1_io_out_s3_full_pred_1_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[4] && r_s1_io_out_s3_full_pred_1_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[5] && r_s1_io_out_s3_full_pred_1_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[6] && r_s1_io_out_s3_full_pred_1_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[7] && r_s1_io_out_s3_full_pred_1_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[8] && r_s1_io_out_s3_full_pred_1_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[9] && r_s1_io_out_s3_full_pred_1_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[10] && r_s1_io_out_s3_full_pred_1_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[11] && r_s1_io_out_s3_full_pred_1_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[12] && r_s1_io_out_s3_full_pred_1_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[13] && r_s1_io_out_s3_full_pred_1_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[14] && r_s1_io_out_s3_full_pred_1_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[15] && r_s1_io_out_s3_full_pred_1_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[16] && r_s1_io_out_s3_full_pred_1_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[17] && r_s1_io_out_s3_full_pred_1_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[18] && r_s1_io_out_s3_full_pred_1_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[19] && r_s1_io_out_s3_full_pred_1_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[20] && r_s1_io_out_s3_full_pred_1_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[21] && r_s1_io_out_s3_full_pred_1_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[22] && r_s1_io_out_s3_full_pred_1_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[23] && r_s1_io_out_s3_full_pred_1_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[24] && r_s1_io_out_s3_full_pred_1_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[25] && r_s1_io_out_s3_full_pred_1_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[26] && r_s1_io_out_s3_full_pred_1_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[27] && r_s1_io_out_s3_full_pred_1_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[28] && r_s1_io_out_s3_full_pred_1_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[29] && r_s1_io_out_s3_full_pred_1_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[30] && r_s1_io_out_s3_full_pred_1_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[31] && r_s1_io_out_s3_full_pred_1_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[32] && r_s1_io_out_s3_full_pred_1_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[33] && r_s1_io_out_s3_full_pred_1_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[34] && r_s1_io_out_s3_full_pred_1_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[35] && r_s1_io_out_s3_full_pred_1_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[36] && r_s1_io_out_s3_full_pred_1_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[37] && r_s1_io_out_s3_full_pred_1_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[38] && r_s1_io_out_s3_full_pred_1_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[39] && r_s1_io_out_s3_full_pred_1_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[40] && r_s1_io_out_s3_full_pred_1_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[41] && r_s1_io_out_s3_full_pred_1_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[42] && r_s1_io_out_s3_full_pred_1_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[43] && r_s1_io_out_s3_full_pred_1_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[44] && r_s1_io_out_s3_full_pred_1_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[45] && r_s1_io_out_s3_full_pred_1_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[46] && r_s1_io_out_s3_full_pred_1_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[47] && r_s1_io_out_s3_full_pred_1_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[48] && r_s1_io_out_s3_full_pred_1_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_0[49] && r_s1_io_out_s3_full_pred_1_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[0] && r_s1_io_out_s3_full_pred_1_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[1] && r_s1_io_out_s3_full_pred_1_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[2] && r_s1_io_out_s3_full_pred_1_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[3] && r_s1_io_out_s3_full_pred_1_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[4] && r_s1_io_out_s3_full_pred_1_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[5] && r_s1_io_out_s3_full_pred_1_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[6] && r_s1_io_out_s3_full_pred_1_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[7] && r_s1_io_out_s3_full_pred_1_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[8] && r_s1_io_out_s3_full_pred_1_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[9] && r_s1_io_out_s3_full_pred_1_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[10] && r_s1_io_out_s3_full_pred_1_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[11] && r_s1_io_out_s3_full_pred_1_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[12] && r_s1_io_out_s3_full_pred_1_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[13] && r_s1_io_out_s3_full_pred_1_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[14] && r_s1_io_out_s3_full_pred_1_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[15] && r_s1_io_out_s3_full_pred_1_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[16] && r_s1_io_out_s3_full_pred_1_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[17] && r_s1_io_out_s3_full_pred_1_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[18] && r_s1_io_out_s3_full_pred_1_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[19] && r_s1_io_out_s3_full_pred_1_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[20] && r_s1_io_out_s3_full_pred_1_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[21] && r_s1_io_out_s3_full_pred_1_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[22] && r_s1_io_out_s3_full_pred_1_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[23] && r_s1_io_out_s3_full_pred_1_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[24] && r_s1_io_out_s3_full_pred_1_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[25] && r_s1_io_out_s3_full_pred_1_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[26] && r_s1_io_out_s3_full_pred_1_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[27] && r_s1_io_out_s3_full_pred_1_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[28] && r_s1_io_out_s3_full_pred_1_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[29] && r_s1_io_out_s3_full_pred_1_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[30] && r_s1_io_out_s3_full_pred_1_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[31] && r_s1_io_out_s3_full_pred_1_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[32] && r_s1_io_out_s3_full_pred_1_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[33] && r_s1_io_out_s3_full_pred_1_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[34] && r_s1_io_out_s3_full_pred_1_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[35] && r_s1_io_out_s3_full_pred_1_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[36] && r_s1_io_out_s3_full_pred_1_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[37] && r_s1_io_out_s3_full_pred_1_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[38] && r_s1_io_out_s3_full_pred_1_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[39] && r_s1_io_out_s3_full_pred_1_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[40] && r_s1_io_out_s3_full_pred_1_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[41] && r_s1_io_out_s3_full_pred_1_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[42] && r_s1_io_out_s3_full_pred_1_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[43] && r_s1_io_out_s3_full_pred_1_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[44] && r_s1_io_out_s3_full_pred_1_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[45] && r_s1_io_out_s3_full_pred_1_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[46] && r_s1_io_out_s3_full_pred_1_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[47] && r_s1_io_out_s3_full_pred_1_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[48] && r_s1_io_out_s3_full_pred_1_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_targets_1[49] && r_s1_io_out_s3_full_pred_1_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[0] && r_s1_io_out_s3_full_pred_1_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[1] && r_s1_io_out_s3_full_pred_1_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[2] && r_s1_io_out_s3_full_pred_1_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[3] && r_s1_io_out_s3_full_pred_1_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[4] && r_s1_io_out_s3_full_pred_1_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[5] && r_s1_io_out_s3_full_pred_1_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[6] && r_s1_io_out_s3_full_pred_1_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[7] && r_s1_io_out_s3_full_pred_1_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[8] && r_s1_io_out_s3_full_pred_1_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[9] && r_s1_io_out_s3_full_pred_1_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[10] && r_s1_io_out_s3_full_pred_1_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[11] && r_s1_io_out_s3_full_pred_1_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[12] && r_s1_io_out_s3_full_pred_1_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[13] && r_s1_io_out_s3_full_pred_1_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[14] && r_s1_io_out_s3_full_pred_1_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[15] && r_s1_io_out_s3_full_pred_1_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[16] && r_s1_io_out_s3_full_pred_1_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[17] && r_s1_io_out_s3_full_pred_1_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[18] && r_s1_io_out_s3_full_pred_1_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[19] && r_s1_io_out_s3_full_pred_1_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[20] && r_s1_io_out_s3_full_pred_1_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[21] && r_s1_io_out_s3_full_pred_1_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[22] && r_s1_io_out_s3_full_pred_1_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[23] && r_s1_io_out_s3_full_pred_1_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[24] && r_s1_io_out_s3_full_pred_1_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[25] && r_s1_io_out_s3_full_pred_1_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[26] && r_s1_io_out_s3_full_pred_1_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[27] && r_s1_io_out_s3_full_pred_1_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[28] && r_s1_io_out_s3_full_pred_1_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[29] && r_s1_io_out_s3_full_pred_1_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[30] && r_s1_io_out_s3_full_pred_1_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[31] && r_s1_io_out_s3_full_pred_1_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[32] && r_s1_io_out_s3_full_pred_1_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[33] && r_s1_io_out_s3_full_pred_1_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[34] && r_s1_io_out_s3_full_pred_1_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[35] && r_s1_io_out_s3_full_pred_1_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[36] && r_s1_io_out_s3_full_pred_1_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[37] && r_s1_io_out_s3_full_pred_1_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[38] && r_s1_io_out_s3_full_pred_1_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[39] && r_s1_io_out_s3_full_pred_1_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[40] && r_s1_io_out_s3_full_pred_1_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[41] && r_s1_io_out_s3_full_pred_1_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[42] && r_s1_io_out_s3_full_pred_1_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[43] && r_s1_io_out_s3_full_pred_1_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[44] && r_s1_io_out_s3_full_pred_1_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[45] && r_s1_io_out_s3_full_pred_1_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[46] && r_s1_io_out_s3_full_pred_1_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[47] && r_s1_io_out_s3_full_pred_1_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[48] && r_s1_io_out_s3_full_pred_1_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_jalr_target[49] && r_s1_io_out_s3_full_pred_1_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_0[0] && r_s1_io_out_s3_full_pred_1_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_0[1] && r_s1_io_out_s3_full_pred_1_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_0[2] && r_s1_io_out_s3_full_pred_1_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_0[3] && r_s1_io_out_s3_full_pred_1_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_1[0] && r_s1_io_out_s3_full_pred_1_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_1[1] && r_s1_io_out_s3_full_pred_1_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_1[2] && r_s1_io_out_s3_full_pred_1_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_offsets_1[3] && r_s1_io_out_s3_full_pred_1_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[0] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[1] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[2] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[3] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[4] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[5] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[6] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[7] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[8] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[9] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[10] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[11] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[12] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[13] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[14] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[15] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[16] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[17] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[18] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[19] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[20] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[21] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[22] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[23] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[24] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[25] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[26] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[27] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[28] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[29] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[30] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[31] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[32] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[33] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[34] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[35] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[36] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[37] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[38] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[39] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[40] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[41] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[42] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[43] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[44] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[45] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[46] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[47] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[48] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughAddr[49] && r_s1_io_out_s3_full_pred_1_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_fallThroughErr && r_s1_io_out_s3_full_pred_1_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_multiHit && r_s1_io_out_s3_full_pred_1_multiHit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_multiHit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_is_jal && r_s1_io_out_s3_full_pred_1_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_is_jalr && r_s1_io_out_s3_full_pred_1_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_is_call && r_s1_io_out_s3_full_pred_1_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_is_ret && r_s1_io_out_s3_full_pred_1_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_last_may_be_rvi_call && r_s1_io_out_s3_full_pred_1_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_is_br_sharing && r_s1_io_out_s3_full_pred_1_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_1_hit && r_s1_io_out_s3_full_pred_1_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_1_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_br_taken_mask_0 && r_s1_io_out_s3_full_pred_2_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_br_taken_mask_1 && r_s1_io_out_s3_full_pred_2_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_slot_valids_0 && r_s1_io_out_s3_full_pred_2_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_slot_valids_1 && r_s1_io_out_s3_full_pred_2_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[0] && r_s1_io_out_s3_full_pred_2_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[1] && r_s1_io_out_s3_full_pred_2_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[2] && r_s1_io_out_s3_full_pred_2_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[3] && r_s1_io_out_s3_full_pred_2_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[4] && r_s1_io_out_s3_full_pred_2_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[5] && r_s1_io_out_s3_full_pred_2_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[6] && r_s1_io_out_s3_full_pred_2_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[7] && r_s1_io_out_s3_full_pred_2_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[8] && r_s1_io_out_s3_full_pred_2_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[9] && r_s1_io_out_s3_full_pred_2_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[10] && r_s1_io_out_s3_full_pred_2_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[11] && r_s1_io_out_s3_full_pred_2_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[12] && r_s1_io_out_s3_full_pred_2_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[13] && r_s1_io_out_s3_full_pred_2_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[14] && r_s1_io_out_s3_full_pred_2_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[15] && r_s1_io_out_s3_full_pred_2_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[16] && r_s1_io_out_s3_full_pred_2_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[17] && r_s1_io_out_s3_full_pred_2_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[18] && r_s1_io_out_s3_full_pred_2_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[19] && r_s1_io_out_s3_full_pred_2_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[20] && r_s1_io_out_s3_full_pred_2_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[21] && r_s1_io_out_s3_full_pred_2_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[22] && r_s1_io_out_s3_full_pred_2_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[23] && r_s1_io_out_s3_full_pred_2_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[24] && r_s1_io_out_s3_full_pred_2_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[25] && r_s1_io_out_s3_full_pred_2_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[26] && r_s1_io_out_s3_full_pred_2_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[27] && r_s1_io_out_s3_full_pred_2_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[28] && r_s1_io_out_s3_full_pred_2_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[29] && r_s1_io_out_s3_full_pred_2_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[30] && r_s1_io_out_s3_full_pred_2_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[31] && r_s1_io_out_s3_full_pred_2_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[32] && r_s1_io_out_s3_full_pred_2_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[33] && r_s1_io_out_s3_full_pred_2_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[34] && r_s1_io_out_s3_full_pred_2_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[35] && r_s1_io_out_s3_full_pred_2_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[36] && r_s1_io_out_s3_full_pred_2_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[37] && r_s1_io_out_s3_full_pred_2_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[38] && r_s1_io_out_s3_full_pred_2_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[39] && r_s1_io_out_s3_full_pred_2_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[40] && r_s1_io_out_s3_full_pred_2_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[41] && r_s1_io_out_s3_full_pred_2_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[42] && r_s1_io_out_s3_full_pred_2_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[43] && r_s1_io_out_s3_full_pred_2_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[44] && r_s1_io_out_s3_full_pred_2_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[45] && r_s1_io_out_s3_full_pred_2_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[46] && r_s1_io_out_s3_full_pred_2_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[47] && r_s1_io_out_s3_full_pred_2_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[48] && r_s1_io_out_s3_full_pred_2_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_0[49] && r_s1_io_out_s3_full_pred_2_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[0] && r_s1_io_out_s3_full_pred_2_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[1] && r_s1_io_out_s3_full_pred_2_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[2] && r_s1_io_out_s3_full_pred_2_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[3] && r_s1_io_out_s3_full_pred_2_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[4] && r_s1_io_out_s3_full_pred_2_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[5] && r_s1_io_out_s3_full_pred_2_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[6] && r_s1_io_out_s3_full_pred_2_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[7] && r_s1_io_out_s3_full_pred_2_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[8] && r_s1_io_out_s3_full_pred_2_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[9] && r_s1_io_out_s3_full_pred_2_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[10] && r_s1_io_out_s3_full_pred_2_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[11] && r_s1_io_out_s3_full_pred_2_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[12] && r_s1_io_out_s3_full_pred_2_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[13] && r_s1_io_out_s3_full_pred_2_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[14] && r_s1_io_out_s3_full_pred_2_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[15] && r_s1_io_out_s3_full_pred_2_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[16] && r_s1_io_out_s3_full_pred_2_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[17] && r_s1_io_out_s3_full_pred_2_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[18] && r_s1_io_out_s3_full_pred_2_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[19] && r_s1_io_out_s3_full_pred_2_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[20] && r_s1_io_out_s3_full_pred_2_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[21] && r_s1_io_out_s3_full_pred_2_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[22] && r_s1_io_out_s3_full_pred_2_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[23] && r_s1_io_out_s3_full_pred_2_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[24] && r_s1_io_out_s3_full_pred_2_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[25] && r_s1_io_out_s3_full_pred_2_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[26] && r_s1_io_out_s3_full_pred_2_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[27] && r_s1_io_out_s3_full_pred_2_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[28] && r_s1_io_out_s3_full_pred_2_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[29] && r_s1_io_out_s3_full_pred_2_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[30] && r_s1_io_out_s3_full_pred_2_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[31] && r_s1_io_out_s3_full_pred_2_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[32] && r_s1_io_out_s3_full_pred_2_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[33] && r_s1_io_out_s3_full_pred_2_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[34] && r_s1_io_out_s3_full_pred_2_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[35] && r_s1_io_out_s3_full_pred_2_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[36] && r_s1_io_out_s3_full_pred_2_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[37] && r_s1_io_out_s3_full_pred_2_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[38] && r_s1_io_out_s3_full_pred_2_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[39] && r_s1_io_out_s3_full_pred_2_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[40] && r_s1_io_out_s3_full_pred_2_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[41] && r_s1_io_out_s3_full_pred_2_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[42] && r_s1_io_out_s3_full_pred_2_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[43] && r_s1_io_out_s3_full_pred_2_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[44] && r_s1_io_out_s3_full_pred_2_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[45] && r_s1_io_out_s3_full_pred_2_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[46] && r_s1_io_out_s3_full_pred_2_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[47] && r_s1_io_out_s3_full_pred_2_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[48] && r_s1_io_out_s3_full_pred_2_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_targets_1[49] && r_s1_io_out_s3_full_pred_2_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[0] && r_s1_io_out_s3_full_pred_2_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[1] && r_s1_io_out_s3_full_pred_2_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[2] && r_s1_io_out_s3_full_pred_2_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[3] && r_s1_io_out_s3_full_pred_2_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[4] && r_s1_io_out_s3_full_pred_2_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[5] && r_s1_io_out_s3_full_pred_2_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[6] && r_s1_io_out_s3_full_pred_2_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[7] && r_s1_io_out_s3_full_pred_2_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[8] && r_s1_io_out_s3_full_pred_2_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[9] && r_s1_io_out_s3_full_pred_2_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[10] && r_s1_io_out_s3_full_pred_2_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[11] && r_s1_io_out_s3_full_pred_2_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[12] && r_s1_io_out_s3_full_pred_2_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[13] && r_s1_io_out_s3_full_pred_2_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[14] && r_s1_io_out_s3_full_pred_2_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[15] && r_s1_io_out_s3_full_pred_2_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[16] && r_s1_io_out_s3_full_pred_2_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[17] && r_s1_io_out_s3_full_pred_2_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[18] && r_s1_io_out_s3_full_pred_2_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[19] && r_s1_io_out_s3_full_pred_2_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[20] && r_s1_io_out_s3_full_pred_2_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[21] && r_s1_io_out_s3_full_pred_2_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[22] && r_s1_io_out_s3_full_pred_2_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[23] && r_s1_io_out_s3_full_pred_2_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[24] && r_s1_io_out_s3_full_pred_2_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[25] && r_s1_io_out_s3_full_pred_2_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[26] && r_s1_io_out_s3_full_pred_2_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[27] && r_s1_io_out_s3_full_pred_2_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[28] && r_s1_io_out_s3_full_pred_2_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[29] && r_s1_io_out_s3_full_pred_2_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[30] && r_s1_io_out_s3_full_pred_2_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[31] && r_s1_io_out_s3_full_pred_2_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[32] && r_s1_io_out_s3_full_pred_2_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[33] && r_s1_io_out_s3_full_pred_2_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[34] && r_s1_io_out_s3_full_pred_2_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[35] && r_s1_io_out_s3_full_pred_2_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[36] && r_s1_io_out_s3_full_pred_2_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[37] && r_s1_io_out_s3_full_pred_2_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[38] && r_s1_io_out_s3_full_pred_2_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[39] && r_s1_io_out_s3_full_pred_2_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[40] && r_s1_io_out_s3_full_pred_2_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[41] && r_s1_io_out_s3_full_pred_2_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[42] && r_s1_io_out_s3_full_pred_2_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[43] && r_s1_io_out_s3_full_pred_2_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[44] && r_s1_io_out_s3_full_pred_2_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[45] && r_s1_io_out_s3_full_pred_2_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[46] && r_s1_io_out_s3_full_pred_2_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[47] && r_s1_io_out_s3_full_pred_2_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[48] && r_s1_io_out_s3_full_pred_2_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_jalr_target[49] && r_s1_io_out_s3_full_pred_2_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_0[0] && r_s1_io_out_s3_full_pred_2_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_0[1] && r_s1_io_out_s3_full_pred_2_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_0[2] && r_s1_io_out_s3_full_pred_2_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_0[3] && r_s1_io_out_s3_full_pred_2_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_1[0] && r_s1_io_out_s3_full_pred_2_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_1[1] && r_s1_io_out_s3_full_pred_2_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_1[2] && r_s1_io_out_s3_full_pred_2_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_offsets_1[3] && r_s1_io_out_s3_full_pred_2_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[0] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[1] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[2] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[3] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[4] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[5] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[6] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[7] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[8] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[9] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[10] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[11] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[12] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[13] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[14] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[15] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[16] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[17] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[18] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[19] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[20] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[21] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[22] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[23] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[24] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[25] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[26] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[27] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[28] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[29] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[30] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[31] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[32] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[33] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[34] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[35] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[36] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[37] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[38] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[39] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[40] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[41] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[42] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[43] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[44] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[45] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[46] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[47] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[48] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughAddr[49] && r_s1_io_out_s3_full_pred_2_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_fallThroughErr && r_s1_io_out_s3_full_pred_2_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_multiHit && r_s1_io_out_s3_full_pred_2_multiHit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_multiHit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_is_jal && r_s1_io_out_s3_full_pred_2_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_is_jalr && r_s1_io_out_s3_full_pred_2_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_is_call && r_s1_io_out_s3_full_pred_2_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_is_ret && r_s1_io_out_s3_full_pred_2_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_last_may_be_rvi_call && r_s1_io_out_s3_full_pred_2_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_is_br_sharing && r_s1_io_out_s3_full_pred_2_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_2_hit && r_s1_io_out_s3_full_pred_2_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_2_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_br_taken_mask_0 && r_s1_io_out_s3_full_pred_3_br_taken_mask_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_br_taken_mask_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_br_taken_mask_1 && r_s1_io_out_s3_full_pred_3_br_taken_mask_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_br_taken_mask_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_slot_valids_0 && r_s1_io_out_s3_full_pred_3_slot_valids_0)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_slot_valids_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_slot_valids_1 && r_s1_io_out_s3_full_pred_3_slot_valids_1)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_slot_valids_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[0] && r_s1_io_out_s3_full_pred_3_targets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[1] && r_s1_io_out_s3_full_pred_3_targets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[2] && r_s1_io_out_s3_full_pred_3_targets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[3] && r_s1_io_out_s3_full_pred_3_targets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[4] && r_s1_io_out_s3_full_pred_3_targets_0[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[5] && r_s1_io_out_s3_full_pred_3_targets_0[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[6] && r_s1_io_out_s3_full_pred_3_targets_0[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[7] && r_s1_io_out_s3_full_pred_3_targets_0[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[8] && r_s1_io_out_s3_full_pred_3_targets_0[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[9] && r_s1_io_out_s3_full_pred_3_targets_0[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[10] && r_s1_io_out_s3_full_pred_3_targets_0[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[11] && r_s1_io_out_s3_full_pred_3_targets_0[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[12] && r_s1_io_out_s3_full_pred_3_targets_0[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[13] && r_s1_io_out_s3_full_pred_3_targets_0[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[14] && r_s1_io_out_s3_full_pred_3_targets_0[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[15] && r_s1_io_out_s3_full_pred_3_targets_0[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[16] && r_s1_io_out_s3_full_pred_3_targets_0[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[17] && r_s1_io_out_s3_full_pred_3_targets_0[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[18] && r_s1_io_out_s3_full_pred_3_targets_0[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[19] && r_s1_io_out_s3_full_pred_3_targets_0[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[20] && r_s1_io_out_s3_full_pred_3_targets_0[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[21] && r_s1_io_out_s3_full_pred_3_targets_0[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[22] && r_s1_io_out_s3_full_pred_3_targets_0[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[23] && r_s1_io_out_s3_full_pred_3_targets_0[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[24] && r_s1_io_out_s3_full_pred_3_targets_0[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[25] && r_s1_io_out_s3_full_pred_3_targets_0[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[26] && r_s1_io_out_s3_full_pred_3_targets_0[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[27] && r_s1_io_out_s3_full_pred_3_targets_0[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[28] && r_s1_io_out_s3_full_pred_3_targets_0[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[29] && r_s1_io_out_s3_full_pred_3_targets_0[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[30] && r_s1_io_out_s3_full_pred_3_targets_0[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[31] && r_s1_io_out_s3_full_pred_3_targets_0[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[32] && r_s1_io_out_s3_full_pred_3_targets_0[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[33] && r_s1_io_out_s3_full_pred_3_targets_0[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[34] && r_s1_io_out_s3_full_pred_3_targets_0[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[35] && r_s1_io_out_s3_full_pred_3_targets_0[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[36] && r_s1_io_out_s3_full_pred_3_targets_0[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[37] && r_s1_io_out_s3_full_pred_3_targets_0[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[38] && r_s1_io_out_s3_full_pred_3_targets_0[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[39] && r_s1_io_out_s3_full_pred_3_targets_0[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[40] && r_s1_io_out_s3_full_pred_3_targets_0[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[41] && r_s1_io_out_s3_full_pred_3_targets_0[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[42] && r_s1_io_out_s3_full_pred_3_targets_0[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[43] && r_s1_io_out_s3_full_pred_3_targets_0[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[44] && r_s1_io_out_s3_full_pred_3_targets_0[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[45] && r_s1_io_out_s3_full_pred_3_targets_0[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[46] && r_s1_io_out_s3_full_pred_3_targets_0[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[47] && r_s1_io_out_s3_full_pred_3_targets_0[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[48] && r_s1_io_out_s3_full_pred_3_targets_0[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_0[49] && r_s1_io_out_s3_full_pred_3_targets_0[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_0[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[0] && r_s1_io_out_s3_full_pred_3_targets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[1] && r_s1_io_out_s3_full_pred_3_targets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[2] && r_s1_io_out_s3_full_pred_3_targets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[3] && r_s1_io_out_s3_full_pred_3_targets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[4] && r_s1_io_out_s3_full_pred_3_targets_1[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[5] && r_s1_io_out_s3_full_pred_3_targets_1[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[6] && r_s1_io_out_s3_full_pred_3_targets_1[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[7] && r_s1_io_out_s3_full_pred_3_targets_1[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[8] && r_s1_io_out_s3_full_pred_3_targets_1[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[9] && r_s1_io_out_s3_full_pred_3_targets_1[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[10] && r_s1_io_out_s3_full_pred_3_targets_1[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[11] && r_s1_io_out_s3_full_pred_3_targets_1[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[12] && r_s1_io_out_s3_full_pred_3_targets_1[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[13] && r_s1_io_out_s3_full_pred_3_targets_1[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[14] && r_s1_io_out_s3_full_pred_3_targets_1[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[15] && r_s1_io_out_s3_full_pred_3_targets_1[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[16] && r_s1_io_out_s3_full_pred_3_targets_1[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[17] && r_s1_io_out_s3_full_pred_3_targets_1[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[18] && r_s1_io_out_s3_full_pred_3_targets_1[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[19] && r_s1_io_out_s3_full_pred_3_targets_1[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[20] && r_s1_io_out_s3_full_pred_3_targets_1[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[21] && r_s1_io_out_s3_full_pred_3_targets_1[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[22] && r_s1_io_out_s3_full_pred_3_targets_1[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[23] && r_s1_io_out_s3_full_pred_3_targets_1[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[24] && r_s1_io_out_s3_full_pred_3_targets_1[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[25] && r_s1_io_out_s3_full_pred_3_targets_1[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[26] && r_s1_io_out_s3_full_pred_3_targets_1[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[27] && r_s1_io_out_s3_full_pred_3_targets_1[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[28] && r_s1_io_out_s3_full_pred_3_targets_1[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[29] && r_s1_io_out_s3_full_pred_3_targets_1[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[30] && r_s1_io_out_s3_full_pred_3_targets_1[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[31] && r_s1_io_out_s3_full_pred_3_targets_1[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[32] && r_s1_io_out_s3_full_pred_3_targets_1[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[33] && r_s1_io_out_s3_full_pred_3_targets_1[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[34] && r_s1_io_out_s3_full_pred_3_targets_1[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[35] && r_s1_io_out_s3_full_pred_3_targets_1[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[36] && r_s1_io_out_s3_full_pred_3_targets_1[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[37] && r_s1_io_out_s3_full_pred_3_targets_1[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[38] && r_s1_io_out_s3_full_pred_3_targets_1[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[39] && r_s1_io_out_s3_full_pred_3_targets_1[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[40] && r_s1_io_out_s3_full_pred_3_targets_1[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[41] && r_s1_io_out_s3_full_pred_3_targets_1[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[42] && r_s1_io_out_s3_full_pred_3_targets_1[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[43] && r_s1_io_out_s3_full_pred_3_targets_1[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[44] && r_s1_io_out_s3_full_pred_3_targets_1[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[45] && r_s1_io_out_s3_full_pred_3_targets_1[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[46] && r_s1_io_out_s3_full_pred_3_targets_1[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[47] && r_s1_io_out_s3_full_pred_3_targets_1[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[48] && r_s1_io_out_s3_full_pred_3_targets_1[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_targets_1[49] && r_s1_io_out_s3_full_pred_3_targets_1[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_targets_1[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[0] && r_s1_io_out_s3_full_pred_3_jalr_target[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[1] && r_s1_io_out_s3_full_pred_3_jalr_target[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[2] && r_s1_io_out_s3_full_pred_3_jalr_target[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[3] && r_s1_io_out_s3_full_pred_3_jalr_target[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[4] && r_s1_io_out_s3_full_pred_3_jalr_target[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[5] && r_s1_io_out_s3_full_pred_3_jalr_target[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[6] && r_s1_io_out_s3_full_pred_3_jalr_target[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[7] && r_s1_io_out_s3_full_pred_3_jalr_target[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[8] && r_s1_io_out_s3_full_pred_3_jalr_target[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[9] && r_s1_io_out_s3_full_pred_3_jalr_target[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[10] && r_s1_io_out_s3_full_pred_3_jalr_target[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[11] && r_s1_io_out_s3_full_pred_3_jalr_target[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[12] && r_s1_io_out_s3_full_pred_3_jalr_target[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[13] && r_s1_io_out_s3_full_pred_3_jalr_target[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[14] && r_s1_io_out_s3_full_pred_3_jalr_target[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[15] && r_s1_io_out_s3_full_pred_3_jalr_target[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[16] && r_s1_io_out_s3_full_pred_3_jalr_target[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[17] && r_s1_io_out_s3_full_pred_3_jalr_target[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[18] && r_s1_io_out_s3_full_pred_3_jalr_target[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[19] && r_s1_io_out_s3_full_pred_3_jalr_target[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[20] && r_s1_io_out_s3_full_pred_3_jalr_target[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[21] && r_s1_io_out_s3_full_pred_3_jalr_target[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[22] && r_s1_io_out_s3_full_pred_3_jalr_target[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[23] && r_s1_io_out_s3_full_pred_3_jalr_target[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[24] && r_s1_io_out_s3_full_pred_3_jalr_target[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[25] && r_s1_io_out_s3_full_pred_3_jalr_target[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[26] && r_s1_io_out_s3_full_pred_3_jalr_target[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[27] && r_s1_io_out_s3_full_pred_3_jalr_target[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[28] && r_s1_io_out_s3_full_pred_3_jalr_target[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[29] && r_s1_io_out_s3_full_pred_3_jalr_target[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[30] && r_s1_io_out_s3_full_pred_3_jalr_target[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[31] && r_s1_io_out_s3_full_pred_3_jalr_target[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[32] && r_s1_io_out_s3_full_pred_3_jalr_target[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[33] && r_s1_io_out_s3_full_pred_3_jalr_target[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[34] && r_s1_io_out_s3_full_pred_3_jalr_target[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[35] && r_s1_io_out_s3_full_pred_3_jalr_target[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[36] && r_s1_io_out_s3_full_pred_3_jalr_target[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[37] && r_s1_io_out_s3_full_pred_3_jalr_target[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[38] && r_s1_io_out_s3_full_pred_3_jalr_target[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[39] && r_s1_io_out_s3_full_pred_3_jalr_target[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[40] && r_s1_io_out_s3_full_pred_3_jalr_target[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[41] && r_s1_io_out_s3_full_pred_3_jalr_target[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[42] && r_s1_io_out_s3_full_pred_3_jalr_target[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[43] && r_s1_io_out_s3_full_pred_3_jalr_target[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[44] && r_s1_io_out_s3_full_pred_3_jalr_target[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[45] && r_s1_io_out_s3_full_pred_3_jalr_target[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[46] && r_s1_io_out_s3_full_pred_3_jalr_target[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[47] && r_s1_io_out_s3_full_pred_3_jalr_target[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[48] && r_s1_io_out_s3_full_pred_3_jalr_target[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_jalr_target[49] && r_s1_io_out_s3_full_pred_3_jalr_target[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_jalr_target[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_0[0] && r_s1_io_out_s3_full_pred_3_offsets_0[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_0[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_0[1] && r_s1_io_out_s3_full_pred_3_offsets_0[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_0[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_0[2] && r_s1_io_out_s3_full_pred_3_offsets_0[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_0[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_0[3] && r_s1_io_out_s3_full_pred_3_offsets_0[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_0[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_1[0] && r_s1_io_out_s3_full_pred_3_offsets_1[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_1[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_1[1] && r_s1_io_out_s3_full_pred_3_offsets_1[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_1[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_1[2] && r_s1_io_out_s3_full_pred_3_offsets_1[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_1[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_offsets_1[3] && r_s1_io_out_s3_full_pred_3_offsets_1[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_offsets_1[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[0] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[1] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[2] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[3] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[4] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[5] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[6] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[7] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[8] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[9] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[10] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[11] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[12] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[13] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[14] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[15] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[16] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[17] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[18] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[19] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[20] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[21] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[22] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[23] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[24] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[25] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[26] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[27] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[28] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[29] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[30] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[31] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[32] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[33] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[34] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[35] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[36] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[37] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[38] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[39] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[40] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[41] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[42] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[43] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[44] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[45] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[46] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[47] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[48] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughAddr[49] && r_s1_io_out_s3_full_pred_3_fallThroughAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_fallThroughErr && r_s1_io_out_s3_full_pred_3_fallThroughErr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_fallThroughErr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_multiHit && r_s1_io_out_s3_full_pred_3_multiHit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_multiHit 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_is_jal && r_s1_io_out_s3_full_pred_3_is_jal)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_is_jal 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_is_jalr && r_s1_io_out_s3_full_pred_3_is_jalr)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_is_jalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_is_call && r_s1_io_out_s3_full_pred_3_is_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_is_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_is_ret && r_s1_io_out_s3_full_pred_3_is_ret)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_is_ret 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_last_may_be_rvi_call && r_s1_io_out_s3_full_pred_3_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_is_br_sharing && r_s1_io_out_s3_full_pred_3_is_br_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_is_br_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_s3_full_pred_3_hit && r_s1_io_out_s3_full_pred_3_hit)) begin cov_fail++; $display("[COV] RAS.io_out_s3_full_pred_3_hit 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[0] && r_s1_io_out_last_stage_meta[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[1] && r_s1_io_out_last_stage_meta[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[2] && r_s1_io_out_last_stage_meta[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[3] && r_s1_io_out_last_stage_meta[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[4] && r_s1_io_out_last_stage_meta[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[5] && r_s1_io_out_last_stage_meta[5])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[6] && r_s1_io_out_last_stage_meta[6])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[7] && r_s1_io_out_last_stage_meta[7])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[8] && r_s1_io_out_last_stage_meta[8])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_meta[9] && r_s1_io_out_last_stage_meta[9])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_meta[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_ssp[0] && r_s1_io_out_last_stage_spec_info_ssp[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_ssp[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_ssp[1] && r_s1_io_out_last_stage_spec_info_ssp[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_ssp[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_ssp[2] && r_s1_io_out_last_stage_spec_info_ssp[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_ssp[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_ssp[3] && r_s1_io_out_last_stage_spec_info_ssp[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_ssp[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_sctr[0] && r_s1_io_out_last_stage_spec_info_sctr[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_sctr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_sctr[1] && r_s1_io_out_last_stage_spec_info_sctr[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_sctr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_sctr[2] && r_s1_io_out_last_stage_spec_info_sctr[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_sctr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSW_flag && r_s1_io_out_last_stage_spec_info_TOSW_flag)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSW_flag 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSW_value[0] && r_s1_io_out_last_stage_spec_info_TOSW_value[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSW_value[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSW_value[1] && r_s1_io_out_last_stage_spec_info_TOSW_value[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSW_value[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSW_value[2] && r_s1_io_out_last_stage_spec_info_TOSW_value[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSW_value[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSW_value[3] && r_s1_io_out_last_stage_spec_info_TOSW_value[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSW_value[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSW_value[4] && r_s1_io_out_last_stage_spec_info_TOSW_value[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSW_value[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSR_flag && r_s1_io_out_last_stage_spec_info_TOSR_flag)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSR_flag 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSR_value[0] && r_s1_io_out_last_stage_spec_info_TOSR_value[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSR_value[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSR_value[1] && r_s1_io_out_last_stage_spec_info_TOSR_value[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSR_value[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSR_value[2] && r_s1_io_out_last_stage_spec_info_TOSR_value[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSR_value[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSR_value[3] && r_s1_io_out_last_stage_spec_info_TOSR_value[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSR_value[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_TOSR_value[4] && r_s1_io_out_last_stage_spec_info_TOSR_value[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_TOSR_value[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_NOS_flag && r_s1_io_out_last_stage_spec_info_NOS_flag)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_NOS_flag 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_NOS_value[0] && r_s1_io_out_last_stage_spec_info_NOS_value[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_NOS_value[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_NOS_value[1] && r_s1_io_out_last_stage_spec_info_NOS_value[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_NOS_value[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_NOS_value[2] && r_s1_io_out_last_stage_spec_info_NOS_value[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_NOS_value[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_NOS_value[3] && r_s1_io_out_last_stage_spec_info_NOS_value[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_NOS_value[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_NOS_value[4] && r_s1_io_out_last_stage_spec_info_NOS_value[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_NOS_value[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[0] && r_s1_io_out_last_stage_spec_info_topAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[1] && r_s1_io_out_last_stage_spec_info_topAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[2] && r_s1_io_out_last_stage_spec_info_topAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[3] && r_s1_io_out_last_stage_spec_info_topAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[4] && r_s1_io_out_last_stage_spec_info_topAddr[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[5] && r_s1_io_out_last_stage_spec_info_topAddr[5])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[6] && r_s1_io_out_last_stage_spec_info_topAddr[6])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[7] && r_s1_io_out_last_stage_spec_info_topAddr[7])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[8] && r_s1_io_out_last_stage_spec_info_topAddr[8])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[9] && r_s1_io_out_last_stage_spec_info_topAddr[9])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[10] && r_s1_io_out_last_stage_spec_info_topAddr[10])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[11] && r_s1_io_out_last_stage_spec_info_topAddr[11])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[12] && r_s1_io_out_last_stage_spec_info_topAddr[12])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[13] && r_s1_io_out_last_stage_spec_info_topAddr[13])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[14] && r_s1_io_out_last_stage_spec_info_topAddr[14])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[15] && r_s1_io_out_last_stage_spec_info_topAddr[15])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[16] && r_s1_io_out_last_stage_spec_info_topAddr[16])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[17] && r_s1_io_out_last_stage_spec_info_topAddr[17])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[18] && r_s1_io_out_last_stage_spec_info_topAddr[18])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[19] && r_s1_io_out_last_stage_spec_info_topAddr[19])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[20] && r_s1_io_out_last_stage_spec_info_topAddr[20])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[20] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[21] && r_s1_io_out_last_stage_spec_info_topAddr[21])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[21] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[22] && r_s1_io_out_last_stage_spec_info_topAddr[22])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[22] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[23] && r_s1_io_out_last_stage_spec_info_topAddr[23])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[23] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[24] && r_s1_io_out_last_stage_spec_info_topAddr[24])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[24] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[25] && r_s1_io_out_last_stage_spec_info_topAddr[25])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[25] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[26] && r_s1_io_out_last_stage_spec_info_topAddr[26])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[26] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[27] && r_s1_io_out_last_stage_spec_info_topAddr[27])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[27] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[28] && r_s1_io_out_last_stage_spec_info_topAddr[28])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[28] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[29] && r_s1_io_out_last_stage_spec_info_topAddr[29])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[29] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[30] && r_s1_io_out_last_stage_spec_info_topAddr[30])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[30] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[31] && r_s1_io_out_last_stage_spec_info_topAddr[31])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[31] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[32] && r_s1_io_out_last_stage_spec_info_topAddr[32])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[32] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[33] && r_s1_io_out_last_stage_spec_info_topAddr[33])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[33] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[34] && r_s1_io_out_last_stage_spec_info_topAddr[34])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[34] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[35] && r_s1_io_out_last_stage_spec_info_topAddr[35])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[35] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[36] && r_s1_io_out_last_stage_spec_info_topAddr[36])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[36] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[37] && r_s1_io_out_last_stage_spec_info_topAddr[37])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[37] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[38] && r_s1_io_out_last_stage_spec_info_topAddr[38])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[38] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[39] && r_s1_io_out_last_stage_spec_info_topAddr[39])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[39] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[40] && r_s1_io_out_last_stage_spec_info_topAddr[40])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[40] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[41] && r_s1_io_out_last_stage_spec_info_topAddr[41])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[41] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[42] && r_s1_io_out_last_stage_spec_info_topAddr[42])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[42] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[43] && r_s1_io_out_last_stage_spec_info_topAddr[43])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[43] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[44] && r_s1_io_out_last_stage_spec_info_topAddr[44])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[44] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[45] && r_s1_io_out_last_stage_spec_info_topAddr[45])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[45] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[46] && r_s1_io_out_last_stage_spec_info_topAddr[46])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[46] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[47] && r_s1_io_out_last_stage_spec_info_topAddr[47])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[47] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[48] && r_s1_io_out_last_stage_spec_info_topAddr[48])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[48] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_topAddr[49] && r_s1_io_out_last_stage_spec_info_topAddr[49])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_topAddr[49] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_sc_disagree_0 && r_s1_io_out_last_stage_spec_info_sc_disagree_0)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_sc_disagree_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_spec_info_sc_disagree_1 && r_s1_io_out_last_stage_spec_info_sc_disagree_1)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_spec_info_sc_disagree_1 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_isCall && r_s1_io_out_last_stage_ftb_entry_isCall)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_isCall 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_isRet && r_s1_io_out_last_stage_ftb_entry_isRet)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_isRet 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_isJalr && r_s1_io_out_last_stage_ftb_entry_isJalr)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_isJalr 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_valid && r_s1_io_out_last_stage_ftb_entry_valid)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_valid 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_offset[0] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_offset[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_offset[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_offset[1] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_offset[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_offset[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_offset[2] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_offset[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_offset[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_offset[3] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_offset[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_offset[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_sharing && r_s1_io_out_last_stage_ftb_entry_brSlots_0_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_valid && r_s1_io_out_last_stage_ftb_entry_brSlots_0_valid)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_valid 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[0] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[1] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[2] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[3] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[4] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[5] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[5])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[6] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[6])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[7] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[7])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[8] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[8])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[9] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[9])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[10] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[10])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_lower[11] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_lower[11])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_lower[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_tarStat[0] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_tarStat[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_tarStat[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_brSlots_0_tarStat[1] && r_s1_io_out_last_stage_ftb_entry_brSlots_0_tarStat[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_brSlots_0_tarStat[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_offset[0] && r_s1_io_out_last_stage_ftb_entry_tailSlot_offset[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_offset[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_offset[1] && r_s1_io_out_last_stage_ftb_entry_tailSlot_offset[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_offset[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_offset[2] && r_s1_io_out_last_stage_ftb_entry_tailSlot_offset[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_offset[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_offset[3] && r_s1_io_out_last_stage_ftb_entry_tailSlot_offset[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_offset[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_sharing && r_s1_io_out_last_stage_ftb_entry_tailSlot_sharing)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_sharing 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_valid && r_s1_io_out_last_stage_ftb_entry_tailSlot_valid)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_valid 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[0] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[1] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[2] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[3] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[4] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[4])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[4] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[5] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[5])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[5] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[6] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[6])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[6] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[7] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[7])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[7] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[8] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[8])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[8] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[9] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[9])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[9] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[10] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[10])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[10] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[11] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[11])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[11] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[12] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[12])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[12] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[13] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[13])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[13] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[14] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[14])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[14] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[15] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[15])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[15] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[16] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[16])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[16] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[17] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[17])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[17] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[18] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[18])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[18] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_lower[19] && r_s1_io_out_last_stage_ftb_entry_tailSlot_lower[19])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_lower[19] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_tarStat[0] && r_s1_io_out_last_stage_ftb_entry_tailSlot_tarStat[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_tarStat[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_tailSlot_tarStat[1] && r_s1_io_out_last_stage_ftb_entry_tailSlot_tarStat[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_tailSlot_tarStat[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_pftAddr[0] && r_s1_io_out_last_stage_ftb_entry_pftAddr[0])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_pftAddr[0] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_pftAddr[1] && r_s1_io_out_last_stage_ftb_entry_pftAddr[1])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_pftAddr[1] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_pftAddr[2] && r_s1_io_out_last_stage_ftb_entry_pftAddr[2])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_pftAddr[2] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_pftAddr[3] && r_s1_io_out_last_stage_ftb_entry_pftAddr[3])) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_pftAddr[3] 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_carry && r_s1_io_out_last_stage_ftb_entry_carry)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_carry 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_last_may_be_rvi_call && r_s1_io_out_last_stage_ftb_entry_last_may_be_rvi_call)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_last_may_be_rvi_call 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_strong_bias_0 && r_s1_io_out_last_stage_ftb_entry_strong_bias_0)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_strong_bias_0 未见过 0 和 1"); end
    if (!(r_s0_io_out_last_stage_ftb_entry_strong_bias_1 && r_s1_io_out_last_stage_ftb_entry_strong_bias_1)) begin cov_fail++; $display("[COV] RAS.io_out_last_stage_ftb_entry_strong_bias_1 未见过 0 和 1"); end
    $display("[ARM] RAS armed_at=%0d", r_armed_at);
    if (r_armed_at < 0) begin cov_fail++; $display("[ARM] RAS 从未 arm"); end
    $display("[COV] RAS.spec_push = %0d", r_cov_spec_push);
    if (r_cov_spec_push < 20) begin cov_fail++; $display("[COV] RAS.spec_push < 20"); end
    $display("[COV] RAS.spec_pop = %0d", r_cov_spec_pop);
    if (r_cov_spec_pop < 20) begin cov_fail++; $display("[COV] RAS.spec_pop < 20"); end
    $display("[COV] RAS.s3_cancel = %0d", r_cov_s3_cancel);
    if (r_cov_s3_cancel < 20) begin cov_fail++; $display("[COV] RAS.s3_cancel < 20"); end
    $display("[COV] RAS.near_overflow = %0d", r_cov_near_overflow);
    if (r_cov_near_overflow < 20) begin cov_fail++; $display("[COV] RAS.near_overflow < 20"); end
    $display("[COV] RAS.redirect_call = %0d", r_cov_redirect_call);
    if (r_cov_redirect_call < 20) begin cov_fail++; $display("[COV] RAS.redirect_call < 20"); end
    $display("[COV] RAS.redirect_ret = %0d", r_cov_redirect_ret);
    if (r_cov_redirect_ret < 20) begin cov_fail++; $display("[COV] RAS.redirect_ret < 20"); end
    $display("[COV] RAS.commit_push = %0d", r_cov_commit_push);
    if (r_cov_commit_push < 20) begin cov_fail++; $display("[COV] RAS.commit_push < 20"); end
    $display("[COV] RAS.commit_pop = %0d", r_cov_commit_pop);
    if (r_cov_commit_pop < 20) begin cov_fail++; $display("[COV] RAS.commit_pop < 20"); end
    $display("[COV] RAS.s2_ret_target = %0d", r_cov_s2_ret_target);
    if (r_cov_s2_ret_target < 20) begin cov_fail++; $display("[COV] RAS.s2_ret_target < 20"); end
    $display("[COV] RAS.s2_seg_hold = %0d", r_cov_s2_seg_hold);
    if (r_cov_s2_seg_hold < 20) begin cov_fail++; $display("[COV] RAS.s2_seg_hold < 20"); end
    $display("[COV] RAS.reset_mid = %0d", r_cov_reset_mid);
    if (r_cov_reset_mid < 20) begin cov_fail++; $display("[COV] RAS.reset_mid < 20"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
