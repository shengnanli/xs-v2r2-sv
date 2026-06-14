// 自动生成：scripts/gen_ras.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
  logic [47:0] io_reset_vector;
  logic [49:0] io_in_bits_s0_pc_0;
  logic [49:0] io_in_bits_s0_pc_1;
  logic [49:0] io_in_bits_s0_pc_2;
  logic [49:0] io_in_bits_s0_pc_3;
  logic io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0;
  logic io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_0_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_0_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_0_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_0_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_0_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr;
  logic io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr;
  logic io_in_bits_resp_in_0_s2_full_pred_0_is_jal;
  logic io_in_bits_resp_in_0_s2_full_pred_0_is_jalr;
  logic io_in_bits_resp_in_0_s2_full_pred_0_is_call;
  logic io_in_bits_resp_in_0_s2_full_pred_0_is_ret;
  logic io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing;
  logic io_in_bits_resp_in_0_s2_full_pred_0_hit;
  logic io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0;
  logic io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_1_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_1_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_1_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_1_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_1_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr;
  logic io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr;
  logic io_in_bits_resp_in_0_s2_full_pred_1_is_jal;
  logic io_in_bits_resp_in_0_s2_full_pred_1_is_jalr;
  logic io_in_bits_resp_in_0_s2_full_pred_1_is_call;
  logic io_in_bits_resp_in_0_s2_full_pred_1_is_ret;
  logic io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing;
  logic io_in_bits_resp_in_0_s2_full_pred_1_hit;
  logic io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0;
  logic io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_2_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_2_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_2_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_2_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_2_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr;
  logic io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr;
  logic io_in_bits_resp_in_0_s2_full_pred_2_is_jal;
  logic io_in_bits_resp_in_0_s2_full_pred_2_is_jalr;
  logic io_in_bits_resp_in_0_s2_full_pred_2_is_call;
  logic io_in_bits_resp_in_0_s2_full_pred_2_is_ret;
  logic io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;
  logic io_in_bits_resp_in_0_s2_full_pred_2_hit;
  logic io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0;
  logic io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_3_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_3_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_3_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_3_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s2_full_pred_3_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr;
  logic io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr;
  logic io_in_bits_resp_in_0_s2_full_pred_3_is_jal;
  logic io_in_bits_resp_in_0_s2_full_pred_3_is_jalr;
  logic io_in_bits_resp_in_0_s2_full_pred_3_is_call;
  logic io_in_bits_resp_in_0_s2_full_pred_3_is_ret;
  logic io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing;
  logic io_in_bits_resp_in_0_s2_full_pred_3_hit;
  logic io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0;
  logic io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_0_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_0_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_0_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_0_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_0_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr;
  logic io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr;
  logic io_in_bits_resp_in_0_s3_full_pred_0_multiHit;
  logic io_in_bits_resp_in_0_s3_full_pred_0_is_jal;
  logic io_in_bits_resp_in_0_s3_full_pred_0_is_jalr;
  logic io_in_bits_resp_in_0_s3_full_pred_0_is_call;
  logic io_in_bits_resp_in_0_s3_full_pred_0_is_ret;
  logic io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing;
  logic io_in_bits_resp_in_0_s3_full_pred_0_hit;
  logic io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0;
  logic io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_1_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_1_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_1_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_1_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_1_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr;
  logic io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr;
  logic io_in_bits_resp_in_0_s3_full_pred_1_multiHit;
  logic io_in_bits_resp_in_0_s3_full_pred_1_is_jal;
  logic io_in_bits_resp_in_0_s3_full_pred_1_is_jalr;
  logic io_in_bits_resp_in_0_s3_full_pred_1_is_call;
  logic io_in_bits_resp_in_0_s3_full_pred_1_is_ret;
  logic io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing;
  logic io_in_bits_resp_in_0_s3_full_pred_1_hit;
  logic io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0;
  logic io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_2_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_2_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_2_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_2_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_2_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr;
  logic io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  logic io_in_bits_resp_in_0_s3_full_pred_2_multiHit;
  logic io_in_bits_resp_in_0_s3_full_pred_2_is_jal;
  logic io_in_bits_resp_in_0_s3_full_pred_2_is_jalr;
  logic io_in_bits_resp_in_0_s3_full_pred_2_is_call;
  logic io_in_bits_resp_in_0_s3_full_pred_2_is_ret;
  logic io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;
  logic io_in_bits_resp_in_0_s3_full_pred_2_hit;
  logic io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0;
  logic io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_3_targets_0;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_3_targets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_3_jalr_target;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_3_offsets_0;
  logic [3:0] io_in_bits_resp_in_0_s3_full_pred_3_offsets_1;
  logic [49:0] io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr;
  logic io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr;
  logic io_in_bits_resp_in_0_s3_full_pred_3_multiHit;
  logic io_in_bits_resp_in_0_s3_full_pred_3_is_jal;
  logic io_in_bits_resp_in_0_s3_full_pred_3_is_jalr;
  logic io_in_bits_resp_in_0_s3_full_pred_3_is_call;
  logic io_in_bits_resp_in_0_s3_full_pred_3_is_ret;
  logic io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing;
  logic io_in_bits_resp_in_0_s3_full_pred_3_hit;
  logic io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;
  logic io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_isCall;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_isRet;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_valid;
  logic [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid;
  logic [11:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower;
  logic [1:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat;
  logic [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid;
  logic [19:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower;
  logic [1:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat;
  logic [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_carry;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0;
  logic io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1;
  logic io_ctrl_ras_enable;
  logic io_s0_fire_0;
  logic io_s0_fire_1;
  logic io_s0_fire_2;
  logic io_s0_fire_3;
  logic io_s1_fire_0;
  logic io_s1_fire_1;
  logic io_s1_fire_2;
  logic io_s1_fire_3;
  logic io_s2_fire_0;
  logic io_s2_fire_1;
  logic io_s2_fire_2;
  logic io_s2_fire_3;
  logic io_s3_fire_2;
  logic io_s3_redirect_2;
  logic io_update_valid;
  logic io_update_bits_ftb_entry_isCall;
  logic io_update_bits_ftb_entry_isRet;
  logic [3:0] io_update_bits_ftb_entry_tailSlot_offset;
  logic io_update_bits_ftb_entry_tailSlot_valid;
  logic io_update_bits_cfi_idx_valid;
  logic [3:0] io_update_bits_cfi_idx_bits;
  logic io_update_bits_jmp_taken;
  logic [515:0] io_update_bits_meta;
  logic io_redirect_valid;
  logic io_redirect_bits_level;
  logic [49:0] io_redirect_bits_cfiUpdate_pc;
  logic io_redirect_bits_cfiUpdate_pd_valid;
  logic io_redirect_bits_cfiUpdate_pd_isRVC;
  logic io_redirect_bits_cfiUpdate_pd_isCall;
  logic io_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0] io_redirect_bits_cfiUpdate_ssp;
  logic [2:0] io_redirect_bits_cfiUpdate_sctr;
  logic io_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0] io_redirect_bits_cfiUpdate_TOSW_value;
  logic io_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0] io_redirect_bits_cfiUpdate_TOSR_value;
  logic io_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0] io_redirect_bits_cfiUpdate_NOS_value;
  wire [49:0] g_io_out_s2_pc_0;
  wire [49:0] i_io_out_s2_pc_0;
  wire [49:0] g_io_out_s2_pc_1;
  wire [49:0] i_io_out_s2_pc_1;
  wire [49:0] g_io_out_s2_pc_2;
  wire [49:0] i_io_out_s2_pc_2;
  wire [49:0] g_io_out_s2_pc_3;
  wire [49:0] i_io_out_s2_pc_3;
  wire g_io_out_s2_full_pred_0_br_taken_mask_0;
  wire i_io_out_s2_full_pred_0_br_taken_mask_0;
  wire g_io_out_s2_full_pred_0_br_taken_mask_1;
  wire i_io_out_s2_full_pred_0_br_taken_mask_1;
  wire g_io_out_s2_full_pred_0_slot_valids_0;
  wire i_io_out_s2_full_pred_0_slot_valids_0;
  wire g_io_out_s2_full_pred_0_slot_valids_1;
  wire i_io_out_s2_full_pred_0_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_0_targets_0;
  wire [49:0] i_io_out_s2_full_pred_0_targets_0;
  wire [49:0] g_io_out_s2_full_pred_0_targets_1;
  wire [49:0] i_io_out_s2_full_pred_0_targets_1;
  wire [49:0] g_io_out_s2_full_pred_0_jalr_target;
  wire [49:0] i_io_out_s2_full_pred_0_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_0_offsets_0;
  wire [3:0] i_io_out_s2_full_pred_0_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_0_offsets_1;
  wire [3:0] i_io_out_s2_full_pred_0_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_0_fallThroughAddr;
  wire [49:0] i_io_out_s2_full_pred_0_fallThroughAddr;
  wire g_io_out_s2_full_pred_0_fallThroughErr;
  wire i_io_out_s2_full_pred_0_fallThroughErr;
  wire g_io_out_s2_full_pred_0_is_jal;
  wire i_io_out_s2_full_pred_0_is_jal;
  wire g_io_out_s2_full_pred_0_is_jalr;
  wire i_io_out_s2_full_pred_0_is_jalr;
  wire g_io_out_s2_full_pred_0_is_call;
  wire i_io_out_s2_full_pred_0_is_call;
  wire g_io_out_s2_full_pred_0_is_ret;
  wire i_io_out_s2_full_pred_0_is_ret;
  wire g_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire i_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_0_is_br_sharing;
  wire i_io_out_s2_full_pred_0_is_br_sharing;
  wire g_io_out_s2_full_pred_0_hit;
  wire i_io_out_s2_full_pred_0_hit;
  wire g_io_out_s2_full_pred_1_br_taken_mask_0;
  wire i_io_out_s2_full_pred_1_br_taken_mask_0;
  wire g_io_out_s2_full_pred_1_br_taken_mask_1;
  wire i_io_out_s2_full_pred_1_br_taken_mask_1;
  wire g_io_out_s2_full_pred_1_slot_valids_0;
  wire i_io_out_s2_full_pred_1_slot_valids_0;
  wire g_io_out_s2_full_pred_1_slot_valids_1;
  wire i_io_out_s2_full_pred_1_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_1_targets_0;
  wire [49:0] i_io_out_s2_full_pred_1_targets_0;
  wire [49:0] g_io_out_s2_full_pred_1_targets_1;
  wire [49:0] i_io_out_s2_full_pred_1_targets_1;
  wire [49:0] g_io_out_s2_full_pred_1_jalr_target;
  wire [49:0] i_io_out_s2_full_pred_1_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_1_offsets_0;
  wire [3:0] i_io_out_s2_full_pred_1_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_1_offsets_1;
  wire [3:0] i_io_out_s2_full_pred_1_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_1_fallThroughAddr;
  wire [49:0] i_io_out_s2_full_pred_1_fallThroughAddr;
  wire g_io_out_s2_full_pred_1_fallThroughErr;
  wire i_io_out_s2_full_pred_1_fallThroughErr;
  wire g_io_out_s2_full_pred_1_is_jal;
  wire i_io_out_s2_full_pred_1_is_jal;
  wire g_io_out_s2_full_pred_1_is_jalr;
  wire i_io_out_s2_full_pred_1_is_jalr;
  wire g_io_out_s2_full_pred_1_is_call;
  wire i_io_out_s2_full_pred_1_is_call;
  wire g_io_out_s2_full_pred_1_is_ret;
  wire i_io_out_s2_full_pred_1_is_ret;
  wire g_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire i_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_1_is_br_sharing;
  wire i_io_out_s2_full_pred_1_is_br_sharing;
  wire g_io_out_s2_full_pred_1_hit;
  wire i_io_out_s2_full_pred_1_hit;
  wire g_io_out_s2_full_pred_2_br_taken_mask_0;
  wire i_io_out_s2_full_pred_2_br_taken_mask_0;
  wire g_io_out_s2_full_pred_2_br_taken_mask_1;
  wire i_io_out_s2_full_pred_2_br_taken_mask_1;
  wire g_io_out_s2_full_pred_2_slot_valids_0;
  wire i_io_out_s2_full_pred_2_slot_valids_0;
  wire g_io_out_s2_full_pred_2_slot_valids_1;
  wire i_io_out_s2_full_pred_2_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_2_targets_0;
  wire [49:0] i_io_out_s2_full_pred_2_targets_0;
  wire [49:0] g_io_out_s2_full_pred_2_targets_1;
  wire [49:0] i_io_out_s2_full_pred_2_targets_1;
  wire [49:0] g_io_out_s2_full_pred_2_jalr_target;
  wire [49:0] i_io_out_s2_full_pred_2_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_2_offsets_0;
  wire [3:0] i_io_out_s2_full_pred_2_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_2_offsets_1;
  wire [3:0] i_io_out_s2_full_pred_2_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_2_fallThroughAddr;
  wire [49:0] i_io_out_s2_full_pred_2_fallThroughAddr;
  wire g_io_out_s2_full_pred_2_fallThroughErr;
  wire i_io_out_s2_full_pred_2_fallThroughErr;
  wire g_io_out_s2_full_pred_2_is_jal;
  wire i_io_out_s2_full_pred_2_is_jal;
  wire g_io_out_s2_full_pred_2_is_jalr;
  wire i_io_out_s2_full_pred_2_is_jalr;
  wire g_io_out_s2_full_pred_2_is_call;
  wire i_io_out_s2_full_pred_2_is_call;
  wire g_io_out_s2_full_pred_2_is_ret;
  wire i_io_out_s2_full_pred_2_is_ret;
  wire g_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire i_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_2_is_br_sharing;
  wire i_io_out_s2_full_pred_2_is_br_sharing;
  wire g_io_out_s2_full_pred_2_hit;
  wire i_io_out_s2_full_pred_2_hit;
  wire g_io_out_s2_full_pred_3_br_taken_mask_0;
  wire i_io_out_s2_full_pred_3_br_taken_mask_0;
  wire g_io_out_s2_full_pred_3_br_taken_mask_1;
  wire i_io_out_s2_full_pred_3_br_taken_mask_1;
  wire g_io_out_s2_full_pred_3_slot_valids_0;
  wire i_io_out_s2_full_pred_3_slot_valids_0;
  wire g_io_out_s2_full_pred_3_slot_valids_1;
  wire i_io_out_s2_full_pred_3_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_3_targets_0;
  wire [49:0] i_io_out_s2_full_pred_3_targets_0;
  wire [49:0] g_io_out_s2_full_pred_3_targets_1;
  wire [49:0] i_io_out_s2_full_pred_3_targets_1;
  wire [49:0] g_io_out_s2_full_pred_3_jalr_target;
  wire [49:0] i_io_out_s2_full_pred_3_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_3_offsets_0;
  wire [3:0] i_io_out_s2_full_pred_3_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_3_offsets_1;
  wire [3:0] i_io_out_s2_full_pred_3_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_3_fallThroughAddr;
  wire [49:0] i_io_out_s2_full_pred_3_fallThroughAddr;
  wire g_io_out_s2_full_pred_3_fallThroughErr;
  wire i_io_out_s2_full_pred_3_fallThroughErr;
  wire g_io_out_s2_full_pred_3_is_jal;
  wire i_io_out_s2_full_pred_3_is_jal;
  wire g_io_out_s2_full_pred_3_is_jalr;
  wire i_io_out_s2_full_pred_3_is_jalr;
  wire g_io_out_s2_full_pred_3_is_call;
  wire i_io_out_s2_full_pred_3_is_call;
  wire g_io_out_s2_full_pred_3_is_ret;
  wire i_io_out_s2_full_pred_3_is_ret;
  wire g_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire i_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_3_is_br_sharing;
  wire i_io_out_s2_full_pred_3_is_br_sharing;
  wire g_io_out_s2_full_pred_3_hit;
  wire i_io_out_s2_full_pred_3_hit;
  wire [49:0] g_io_out_s3_pc_0;
  wire [49:0] i_io_out_s3_pc_0;
  wire [49:0] g_io_out_s3_pc_1;
  wire [49:0] i_io_out_s3_pc_1;
  wire [49:0] g_io_out_s3_pc_2;
  wire [49:0] i_io_out_s3_pc_2;
  wire [49:0] g_io_out_s3_pc_3;
  wire [49:0] i_io_out_s3_pc_3;
  wire g_io_out_s3_full_pred_0_br_taken_mask_0;
  wire i_io_out_s3_full_pred_0_br_taken_mask_0;
  wire g_io_out_s3_full_pred_0_br_taken_mask_1;
  wire i_io_out_s3_full_pred_0_br_taken_mask_1;
  wire g_io_out_s3_full_pred_0_slot_valids_0;
  wire i_io_out_s3_full_pred_0_slot_valids_0;
  wire g_io_out_s3_full_pred_0_slot_valids_1;
  wire i_io_out_s3_full_pred_0_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_0_targets_0;
  wire [49:0] i_io_out_s3_full_pred_0_targets_0;
  wire [49:0] g_io_out_s3_full_pred_0_targets_1;
  wire [49:0] i_io_out_s3_full_pred_0_targets_1;
  wire [49:0] g_io_out_s3_full_pred_0_jalr_target;
  wire [49:0] i_io_out_s3_full_pred_0_jalr_target;
  wire [3:0] g_io_out_s3_full_pred_0_offsets_0;
  wire [3:0] i_io_out_s3_full_pred_0_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_0_offsets_1;
  wire [3:0] i_io_out_s3_full_pred_0_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_0_fallThroughAddr;
  wire [49:0] i_io_out_s3_full_pred_0_fallThroughAddr;
  wire g_io_out_s3_full_pred_0_fallThroughErr;
  wire i_io_out_s3_full_pred_0_fallThroughErr;
  wire g_io_out_s3_full_pred_0_multiHit;
  wire i_io_out_s3_full_pred_0_multiHit;
  wire g_io_out_s3_full_pred_0_is_jal;
  wire i_io_out_s3_full_pred_0_is_jal;
  wire g_io_out_s3_full_pred_0_is_jalr;
  wire i_io_out_s3_full_pred_0_is_jalr;
  wire g_io_out_s3_full_pred_0_is_call;
  wire i_io_out_s3_full_pred_0_is_call;
  wire g_io_out_s3_full_pred_0_is_ret;
  wire i_io_out_s3_full_pred_0_is_ret;
  wire g_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire i_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_0_is_br_sharing;
  wire i_io_out_s3_full_pred_0_is_br_sharing;
  wire g_io_out_s3_full_pred_0_hit;
  wire i_io_out_s3_full_pred_0_hit;
  wire g_io_out_s3_full_pred_1_br_taken_mask_0;
  wire i_io_out_s3_full_pred_1_br_taken_mask_0;
  wire g_io_out_s3_full_pred_1_br_taken_mask_1;
  wire i_io_out_s3_full_pred_1_br_taken_mask_1;
  wire g_io_out_s3_full_pred_1_slot_valids_0;
  wire i_io_out_s3_full_pred_1_slot_valids_0;
  wire g_io_out_s3_full_pred_1_slot_valids_1;
  wire i_io_out_s3_full_pred_1_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_1_targets_0;
  wire [49:0] i_io_out_s3_full_pred_1_targets_0;
  wire [49:0] g_io_out_s3_full_pred_1_targets_1;
  wire [49:0] i_io_out_s3_full_pred_1_targets_1;
  wire [49:0] g_io_out_s3_full_pred_1_jalr_target;
  wire [49:0] i_io_out_s3_full_pred_1_jalr_target;
  wire [3:0] g_io_out_s3_full_pred_1_offsets_0;
  wire [3:0] i_io_out_s3_full_pred_1_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_1_offsets_1;
  wire [3:0] i_io_out_s3_full_pred_1_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_1_fallThroughAddr;
  wire [49:0] i_io_out_s3_full_pred_1_fallThroughAddr;
  wire g_io_out_s3_full_pred_1_fallThroughErr;
  wire i_io_out_s3_full_pred_1_fallThroughErr;
  wire g_io_out_s3_full_pred_1_multiHit;
  wire i_io_out_s3_full_pred_1_multiHit;
  wire g_io_out_s3_full_pred_1_is_jal;
  wire i_io_out_s3_full_pred_1_is_jal;
  wire g_io_out_s3_full_pred_1_is_jalr;
  wire i_io_out_s3_full_pred_1_is_jalr;
  wire g_io_out_s3_full_pred_1_is_call;
  wire i_io_out_s3_full_pred_1_is_call;
  wire g_io_out_s3_full_pred_1_is_ret;
  wire i_io_out_s3_full_pred_1_is_ret;
  wire g_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire i_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_1_is_br_sharing;
  wire i_io_out_s3_full_pred_1_is_br_sharing;
  wire g_io_out_s3_full_pred_1_hit;
  wire i_io_out_s3_full_pred_1_hit;
  wire g_io_out_s3_full_pred_2_br_taken_mask_0;
  wire i_io_out_s3_full_pred_2_br_taken_mask_0;
  wire g_io_out_s3_full_pred_2_br_taken_mask_1;
  wire i_io_out_s3_full_pred_2_br_taken_mask_1;
  wire g_io_out_s3_full_pred_2_slot_valids_0;
  wire i_io_out_s3_full_pred_2_slot_valids_0;
  wire g_io_out_s3_full_pred_2_slot_valids_1;
  wire i_io_out_s3_full_pred_2_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_2_targets_0;
  wire [49:0] i_io_out_s3_full_pred_2_targets_0;
  wire [49:0] g_io_out_s3_full_pred_2_targets_1;
  wire [49:0] i_io_out_s3_full_pred_2_targets_1;
  wire [49:0] g_io_out_s3_full_pred_2_jalr_target;
  wire [49:0] i_io_out_s3_full_pred_2_jalr_target;
  wire [3:0] g_io_out_s3_full_pred_2_offsets_0;
  wire [3:0] i_io_out_s3_full_pred_2_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_2_offsets_1;
  wire [3:0] i_io_out_s3_full_pred_2_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_2_fallThroughAddr;
  wire [49:0] i_io_out_s3_full_pred_2_fallThroughAddr;
  wire g_io_out_s3_full_pred_2_fallThroughErr;
  wire i_io_out_s3_full_pred_2_fallThroughErr;
  wire g_io_out_s3_full_pred_2_multiHit;
  wire i_io_out_s3_full_pred_2_multiHit;
  wire g_io_out_s3_full_pred_2_is_jal;
  wire i_io_out_s3_full_pred_2_is_jal;
  wire g_io_out_s3_full_pred_2_is_jalr;
  wire i_io_out_s3_full_pred_2_is_jalr;
  wire g_io_out_s3_full_pred_2_is_call;
  wire i_io_out_s3_full_pred_2_is_call;
  wire g_io_out_s3_full_pred_2_is_ret;
  wire i_io_out_s3_full_pred_2_is_ret;
  wire g_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire i_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_2_is_br_sharing;
  wire i_io_out_s3_full_pred_2_is_br_sharing;
  wire g_io_out_s3_full_pred_2_hit;
  wire i_io_out_s3_full_pred_2_hit;
  wire g_io_out_s3_full_pred_3_br_taken_mask_0;
  wire i_io_out_s3_full_pred_3_br_taken_mask_0;
  wire g_io_out_s3_full_pred_3_br_taken_mask_1;
  wire i_io_out_s3_full_pred_3_br_taken_mask_1;
  wire g_io_out_s3_full_pred_3_slot_valids_0;
  wire i_io_out_s3_full_pred_3_slot_valids_0;
  wire g_io_out_s3_full_pred_3_slot_valids_1;
  wire i_io_out_s3_full_pred_3_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_3_targets_0;
  wire [49:0] i_io_out_s3_full_pred_3_targets_0;
  wire [49:0] g_io_out_s3_full_pred_3_targets_1;
  wire [49:0] i_io_out_s3_full_pred_3_targets_1;
  wire [49:0] g_io_out_s3_full_pred_3_jalr_target;
  wire [49:0] i_io_out_s3_full_pred_3_jalr_target;
  wire [3:0] g_io_out_s3_full_pred_3_offsets_0;
  wire [3:0] i_io_out_s3_full_pred_3_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_3_offsets_1;
  wire [3:0] i_io_out_s3_full_pred_3_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_3_fallThroughAddr;
  wire [49:0] i_io_out_s3_full_pred_3_fallThroughAddr;
  wire g_io_out_s3_full_pred_3_fallThroughErr;
  wire i_io_out_s3_full_pred_3_fallThroughErr;
  wire g_io_out_s3_full_pred_3_multiHit;
  wire i_io_out_s3_full_pred_3_multiHit;
  wire g_io_out_s3_full_pred_3_is_jal;
  wire i_io_out_s3_full_pred_3_is_jal;
  wire g_io_out_s3_full_pred_3_is_jalr;
  wire i_io_out_s3_full_pred_3_is_jalr;
  wire g_io_out_s3_full_pred_3_is_call;
  wire i_io_out_s3_full_pred_3_is_call;
  wire g_io_out_s3_full_pred_3_is_ret;
  wire i_io_out_s3_full_pred_3_is_ret;
  wire g_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire i_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_3_is_br_sharing;
  wire i_io_out_s3_full_pred_3_is_br_sharing;
  wire g_io_out_s3_full_pred_3_hit;
  wire i_io_out_s3_full_pred_3_hit;
  wire [515:0] g_io_out_last_stage_meta;
  wire [515:0] i_io_out_last_stage_meta;
  wire [3:0] g_io_out_last_stage_spec_info_ssp;
  wire [3:0] i_io_out_last_stage_spec_info_ssp;
  wire [2:0] g_io_out_last_stage_spec_info_sctr;
  wire [2:0] i_io_out_last_stage_spec_info_sctr;
  wire g_io_out_last_stage_spec_info_TOSW_flag;
  wire i_io_out_last_stage_spec_info_TOSW_flag;
  wire [4:0] g_io_out_last_stage_spec_info_TOSW_value;
  wire [4:0] i_io_out_last_stage_spec_info_TOSW_value;
  wire g_io_out_last_stage_spec_info_TOSR_flag;
  wire i_io_out_last_stage_spec_info_TOSR_flag;
  wire [4:0] g_io_out_last_stage_spec_info_TOSR_value;
  wire [4:0] i_io_out_last_stage_spec_info_TOSR_value;
  wire g_io_out_last_stage_spec_info_NOS_flag;
  wire i_io_out_last_stage_spec_info_NOS_flag;
  wire [4:0] g_io_out_last_stage_spec_info_NOS_value;
  wire [4:0] i_io_out_last_stage_spec_info_NOS_value;
  wire [49:0] g_io_out_last_stage_spec_info_topAddr;
  wire [49:0] i_io_out_last_stage_spec_info_topAddr;
  wire g_io_out_last_stage_spec_info_sc_disagree_0;
  wire i_io_out_last_stage_spec_info_sc_disagree_0;
  wire g_io_out_last_stage_spec_info_sc_disagree_1;
  wire i_io_out_last_stage_spec_info_sc_disagree_1;
  wire g_io_out_last_stage_ftb_entry_isCall;
  wire i_io_out_last_stage_ftb_entry_isCall;
  wire g_io_out_last_stage_ftb_entry_isRet;
  wire i_io_out_last_stage_ftb_entry_isRet;
  wire g_io_out_last_stage_ftb_entry_isJalr;
  wire i_io_out_last_stage_ftb_entry_isJalr;
  wire g_io_out_last_stage_ftb_entry_valid;
  wire i_io_out_last_stage_ftb_entry_valid;
  wire [3:0] g_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire [3:0] i_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire g_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire i_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire g_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire i_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0] g_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [11:0] i_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0] g_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [1:0] i_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0] g_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire [3:0] i_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire g_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire i_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire g_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire i_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0] g_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [19:0] i_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0] g_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [1:0] i_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0] g_io_out_last_stage_ftb_entry_pftAddr;
  wire [3:0] i_io_out_last_stage_ftb_entry_pftAddr;
  wire g_io_out_last_stage_ftb_entry_carry;
  wire i_io_out_last_stage_ftb_entry_carry;
  wire g_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire i_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire g_io_out_last_stage_ftb_entry_strong_bias_0;
  wire i_io_out_last_stage_ftb_entry_strong_bias_0;
  wire g_io_out_last_stage_ftb_entry_strong_bias_1;
  wire i_io_out_last_stage_ftb_entry_strong_bias_1;
  RAS    u_g (.clock(clk), .reset(rst), .io_reset_vector(io_reset_vector), .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0), .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1), .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2), .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3), .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_0_targets_0(io_in_bits_resp_in_0_s2_full_pred_0_targets_0), .io_in_bits_resp_in_0_s2_full_pred_0_targets_1(io_in_bits_resp_in_0_s2_full_pred_0_targets_1), .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target(io_in_bits_resp_in_0_s2_full_pred_0_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0(io_in_bits_resp_in_0_s2_full_pred_0_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1(io_in_bits_resp_in_0_s2_full_pred_0_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_0_is_jal(io_in_bits_resp_in_0_s2_full_pred_0_is_jal), .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr(io_in_bits_resp_in_0_s2_full_pred_0_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_0_is_call(io_in_bits_resp_in_0_s2_full_pred_0_is_call), .io_in_bits_resp_in_0_s2_full_pred_0_is_ret(io_in_bits_resp_in_0_s2_full_pred_0_is_ret), .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_0_hit(io_in_bits_resp_in_0_s2_full_pred_0_hit), .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_1_targets_0(io_in_bits_resp_in_0_s2_full_pred_1_targets_0), .io_in_bits_resp_in_0_s2_full_pred_1_targets_1(io_in_bits_resp_in_0_s2_full_pred_1_targets_1), .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target(io_in_bits_resp_in_0_s2_full_pred_1_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0(io_in_bits_resp_in_0_s2_full_pred_1_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1(io_in_bits_resp_in_0_s2_full_pred_1_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_1_is_jal(io_in_bits_resp_in_0_s2_full_pred_1_is_jal), .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr(io_in_bits_resp_in_0_s2_full_pred_1_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_1_is_call(io_in_bits_resp_in_0_s2_full_pred_1_is_call), .io_in_bits_resp_in_0_s2_full_pred_1_is_ret(io_in_bits_resp_in_0_s2_full_pred_1_is_ret), .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_1_hit(io_in_bits_resp_in_0_s2_full_pred_1_hit), .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_2_targets_0(io_in_bits_resp_in_0_s2_full_pred_2_targets_0), .io_in_bits_resp_in_0_s2_full_pred_2_targets_1(io_in_bits_resp_in_0_s2_full_pred_2_targets_1), .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target(io_in_bits_resp_in_0_s2_full_pred_2_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0(io_in_bits_resp_in_0_s2_full_pred_2_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1(io_in_bits_resp_in_0_s2_full_pred_2_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_2_is_jal(io_in_bits_resp_in_0_s2_full_pred_2_is_jal), .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr(io_in_bits_resp_in_0_s2_full_pred_2_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_2_is_call(io_in_bits_resp_in_0_s2_full_pred_2_is_call), .io_in_bits_resp_in_0_s2_full_pred_2_is_ret(io_in_bits_resp_in_0_s2_full_pred_2_is_ret), .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_2_hit(io_in_bits_resp_in_0_s2_full_pred_2_hit), .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_3_targets_0(io_in_bits_resp_in_0_s2_full_pred_3_targets_0), .io_in_bits_resp_in_0_s2_full_pred_3_targets_1(io_in_bits_resp_in_0_s2_full_pred_3_targets_1), .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target(io_in_bits_resp_in_0_s2_full_pred_3_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0(io_in_bits_resp_in_0_s2_full_pred_3_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1(io_in_bits_resp_in_0_s2_full_pred_3_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_3_is_jal(io_in_bits_resp_in_0_s2_full_pred_3_is_jal), .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr(io_in_bits_resp_in_0_s2_full_pred_3_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_3_is_call(io_in_bits_resp_in_0_s2_full_pred_3_is_call), .io_in_bits_resp_in_0_s2_full_pred_3_is_ret(io_in_bits_resp_in_0_s2_full_pred_3_is_ret), .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_3_hit(io_in_bits_resp_in_0_s2_full_pred_3_hit), .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_0_targets_0(io_in_bits_resp_in_0_s3_full_pred_0_targets_0), .io_in_bits_resp_in_0_s3_full_pred_0_targets_1(io_in_bits_resp_in_0_s3_full_pred_0_targets_1), .io_in_bits_resp_in_0_s3_full_pred_0_jalr_target(io_in_bits_resp_in_0_s3_full_pred_0_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0(io_in_bits_resp_in_0_s3_full_pred_0_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1(io_in_bits_resp_in_0_s3_full_pred_0_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_0_multiHit(io_in_bits_resp_in_0_s3_full_pred_0_multiHit), .io_in_bits_resp_in_0_s3_full_pred_0_is_jal(io_in_bits_resp_in_0_s3_full_pred_0_is_jal), .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr(io_in_bits_resp_in_0_s3_full_pred_0_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_0_is_call(io_in_bits_resp_in_0_s3_full_pred_0_is_call), .io_in_bits_resp_in_0_s3_full_pred_0_is_ret(io_in_bits_resp_in_0_s3_full_pred_0_is_ret), .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_0_hit(io_in_bits_resp_in_0_s3_full_pred_0_hit), .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_1_targets_0(io_in_bits_resp_in_0_s3_full_pred_1_targets_0), .io_in_bits_resp_in_0_s3_full_pred_1_targets_1(io_in_bits_resp_in_0_s3_full_pred_1_targets_1), .io_in_bits_resp_in_0_s3_full_pred_1_jalr_target(io_in_bits_resp_in_0_s3_full_pred_1_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0(io_in_bits_resp_in_0_s3_full_pred_1_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1(io_in_bits_resp_in_0_s3_full_pred_1_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_1_multiHit(io_in_bits_resp_in_0_s3_full_pred_1_multiHit), .io_in_bits_resp_in_0_s3_full_pred_1_is_jal(io_in_bits_resp_in_0_s3_full_pred_1_is_jal), .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr(io_in_bits_resp_in_0_s3_full_pred_1_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_1_is_call(io_in_bits_resp_in_0_s3_full_pred_1_is_call), .io_in_bits_resp_in_0_s3_full_pred_1_is_ret(io_in_bits_resp_in_0_s3_full_pred_1_is_ret), .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_1_hit(io_in_bits_resp_in_0_s3_full_pred_1_hit), .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_2_targets_0(io_in_bits_resp_in_0_s3_full_pred_2_targets_0), .io_in_bits_resp_in_0_s3_full_pred_2_targets_1(io_in_bits_resp_in_0_s3_full_pred_2_targets_1), .io_in_bits_resp_in_0_s3_full_pred_2_jalr_target(io_in_bits_resp_in_0_s3_full_pred_2_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0(io_in_bits_resp_in_0_s3_full_pred_2_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1(io_in_bits_resp_in_0_s3_full_pred_2_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_2_multiHit(io_in_bits_resp_in_0_s3_full_pred_2_multiHit), .io_in_bits_resp_in_0_s3_full_pred_2_is_jal(io_in_bits_resp_in_0_s3_full_pred_2_is_jal), .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr(io_in_bits_resp_in_0_s3_full_pred_2_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_2_is_call(io_in_bits_resp_in_0_s3_full_pred_2_is_call), .io_in_bits_resp_in_0_s3_full_pred_2_is_ret(io_in_bits_resp_in_0_s3_full_pred_2_is_ret), .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_2_hit(io_in_bits_resp_in_0_s3_full_pred_2_hit), .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_3_targets_0(io_in_bits_resp_in_0_s3_full_pred_3_targets_0), .io_in_bits_resp_in_0_s3_full_pred_3_targets_1(io_in_bits_resp_in_0_s3_full_pred_3_targets_1), .io_in_bits_resp_in_0_s3_full_pred_3_jalr_target(io_in_bits_resp_in_0_s3_full_pred_3_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0(io_in_bits_resp_in_0_s3_full_pred_3_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1(io_in_bits_resp_in_0_s3_full_pred_3_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_3_multiHit(io_in_bits_resp_in_0_s3_full_pred_3_multiHit), .io_in_bits_resp_in_0_s3_full_pred_3_is_jal(io_in_bits_resp_in_0_s3_full_pred_3_is_jal), .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr(io_in_bits_resp_in_0_s3_full_pred_3_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_3_is_call(io_in_bits_resp_in_0_s3_full_pred_3_is_call), .io_in_bits_resp_in_0_s3_full_pred_3_is_ret(io_in_bits_resp_in_0_s3_full_pred_3_is_ret), .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_3_hit(io_in_bits_resp_in_0_s3_full_pred_3_hit), .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0), .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1), .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall(io_in_bits_resp_in_0_last_stage_ftb_entry_isCall), .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet(io_in_bits_resp_in_0_last_stage_ftb_entry_isRet), .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr(io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr), .io_in_bits_resp_in_0_last_stage_ftb_entry_valid(io_in_bits_resp_in_0_last_stage_ftb_entry_valid), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat), .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr(io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr), .io_in_bits_resp_in_0_last_stage_ftb_entry_carry(io_in_bits_resp_in_0_last_stage_ftb_entry_carry), .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call(io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call), .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0(io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0), .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1(io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1), .io_ctrl_ras_enable(io_ctrl_ras_enable), .io_s0_fire_0(io_s0_fire_0), .io_s0_fire_1(io_s0_fire_1), .io_s0_fire_2(io_s0_fire_2), .io_s0_fire_3(io_s0_fire_3), .io_s1_fire_0(io_s1_fire_0), .io_s1_fire_1(io_s1_fire_1), .io_s1_fire_2(io_s1_fire_2), .io_s1_fire_3(io_s1_fire_3), .io_s2_fire_0(io_s2_fire_0), .io_s2_fire_1(io_s2_fire_1), .io_s2_fire_2(io_s2_fire_2), .io_s2_fire_3(io_s2_fire_3), .io_s3_fire_2(io_s3_fire_2), .io_s3_redirect_2(io_s3_redirect_2), .io_update_valid(io_update_valid), .io_update_bits_ftb_entry_isCall(io_update_bits_ftb_entry_isCall), .io_update_bits_ftb_entry_isRet(io_update_bits_ftb_entry_isRet), .io_update_bits_ftb_entry_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset), .io_update_bits_ftb_entry_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid), .io_update_bits_cfi_idx_valid(io_update_bits_cfi_idx_valid), .io_update_bits_cfi_idx_bits(io_update_bits_cfi_idx_bits), .io_update_bits_jmp_taken(io_update_bits_jmp_taken), .io_update_bits_meta(io_update_bits_meta), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_level(io_redirect_bits_level), .io_redirect_bits_cfiUpdate_pc(io_redirect_bits_cfiUpdate_pc), .io_redirect_bits_cfiUpdate_pd_valid(io_redirect_bits_cfiUpdate_pd_valid), .io_redirect_bits_cfiUpdate_pd_isRVC(io_redirect_bits_cfiUpdate_pd_isRVC), .io_redirect_bits_cfiUpdate_pd_isCall(io_redirect_bits_cfiUpdate_pd_isCall), .io_redirect_bits_cfiUpdate_pd_isRet(io_redirect_bits_cfiUpdate_pd_isRet), .io_redirect_bits_cfiUpdate_ssp(io_redirect_bits_cfiUpdate_ssp), .io_redirect_bits_cfiUpdate_sctr(io_redirect_bits_cfiUpdate_sctr), .io_redirect_bits_cfiUpdate_TOSW_flag(io_redirect_bits_cfiUpdate_TOSW_flag), .io_redirect_bits_cfiUpdate_TOSW_value(io_redirect_bits_cfiUpdate_TOSW_value), .io_redirect_bits_cfiUpdate_TOSR_flag(io_redirect_bits_cfiUpdate_TOSR_flag), .io_redirect_bits_cfiUpdate_TOSR_value(io_redirect_bits_cfiUpdate_TOSR_value), .io_redirect_bits_cfiUpdate_NOS_flag(io_redirect_bits_cfiUpdate_NOS_flag), .io_redirect_bits_cfiUpdate_NOS_value(io_redirect_bits_cfiUpdate_NOS_value), .io_out_s2_pc_0(g_io_out_s2_pc_0), .io_out_s2_pc_1(g_io_out_s2_pc_1), .io_out_s2_pc_2(g_io_out_s2_pc_2), .io_out_s2_pc_3(g_io_out_s2_pc_3), .io_out_s2_full_pred_0_br_taken_mask_0(g_io_out_s2_full_pred_0_br_taken_mask_0), .io_out_s2_full_pred_0_br_taken_mask_1(g_io_out_s2_full_pred_0_br_taken_mask_1), .io_out_s2_full_pred_0_slot_valids_0(g_io_out_s2_full_pred_0_slot_valids_0), .io_out_s2_full_pred_0_slot_valids_1(g_io_out_s2_full_pred_0_slot_valids_1), .io_out_s2_full_pred_0_targets_0(g_io_out_s2_full_pred_0_targets_0), .io_out_s2_full_pred_0_targets_1(g_io_out_s2_full_pred_0_targets_1), .io_out_s2_full_pred_0_jalr_target(g_io_out_s2_full_pred_0_jalr_target), .io_out_s2_full_pred_0_offsets_0(g_io_out_s2_full_pred_0_offsets_0), .io_out_s2_full_pred_0_offsets_1(g_io_out_s2_full_pred_0_offsets_1), .io_out_s2_full_pred_0_fallThroughAddr(g_io_out_s2_full_pred_0_fallThroughAddr), .io_out_s2_full_pred_0_fallThroughErr(g_io_out_s2_full_pred_0_fallThroughErr), .io_out_s2_full_pred_0_is_jal(g_io_out_s2_full_pred_0_is_jal), .io_out_s2_full_pred_0_is_jalr(g_io_out_s2_full_pred_0_is_jalr), .io_out_s2_full_pred_0_is_call(g_io_out_s2_full_pred_0_is_call), .io_out_s2_full_pred_0_is_ret(g_io_out_s2_full_pred_0_is_ret), .io_out_s2_full_pred_0_last_may_be_rvi_call(g_io_out_s2_full_pred_0_last_may_be_rvi_call), .io_out_s2_full_pred_0_is_br_sharing(g_io_out_s2_full_pred_0_is_br_sharing), .io_out_s2_full_pred_0_hit(g_io_out_s2_full_pred_0_hit), .io_out_s2_full_pred_1_br_taken_mask_0(g_io_out_s2_full_pred_1_br_taken_mask_0), .io_out_s2_full_pred_1_br_taken_mask_1(g_io_out_s2_full_pred_1_br_taken_mask_1), .io_out_s2_full_pred_1_slot_valids_0(g_io_out_s2_full_pred_1_slot_valids_0), .io_out_s2_full_pred_1_slot_valids_1(g_io_out_s2_full_pred_1_slot_valids_1), .io_out_s2_full_pred_1_targets_0(g_io_out_s2_full_pred_1_targets_0), .io_out_s2_full_pred_1_targets_1(g_io_out_s2_full_pred_1_targets_1), .io_out_s2_full_pred_1_jalr_target(g_io_out_s2_full_pred_1_jalr_target), .io_out_s2_full_pred_1_offsets_0(g_io_out_s2_full_pred_1_offsets_0), .io_out_s2_full_pred_1_offsets_1(g_io_out_s2_full_pred_1_offsets_1), .io_out_s2_full_pred_1_fallThroughAddr(g_io_out_s2_full_pred_1_fallThroughAddr), .io_out_s2_full_pred_1_fallThroughErr(g_io_out_s2_full_pred_1_fallThroughErr), .io_out_s2_full_pred_1_is_jal(g_io_out_s2_full_pred_1_is_jal), .io_out_s2_full_pred_1_is_jalr(g_io_out_s2_full_pred_1_is_jalr), .io_out_s2_full_pred_1_is_call(g_io_out_s2_full_pred_1_is_call), .io_out_s2_full_pred_1_is_ret(g_io_out_s2_full_pred_1_is_ret), .io_out_s2_full_pred_1_last_may_be_rvi_call(g_io_out_s2_full_pred_1_last_may_be_rvi_call), .io_out_s2_full_pred_1_is_br_sharing(g_io_out_s2_full_pred_1_is_br_sharing), .io_out_s2_full_pred_1_hit(g_io_out_s2_full_pred_1_hit), .io_out_s2_full_pred_2_br_taken_mask_0(g_io_out_s2_full_pred_2_br_taken_mask_0), .io_out_s2_full_pred_2_br_taken_mask_1(g_io_out_s2_full_pred_2_br_taken_mask_1), .io_out_s2_full_pred_2_slot_valids_0(g_io_out_s2_full_pred_2_slot_valids_0), .io_out_s2_full_pred_2_slot_valids_1(g_io_out_s2_full_pred_2_slot_valids_1), .io_out_s2_full_pred_2_targets_0(g_io_out_s2_full_pred_2_targets_0), .io_out_s2_full_pred_2_targets_1(g_io_out_s2_full_pred_2_targets_1), .io_out_s2_full_pred_2_jalr_target(g_io_out_s2_full_pred_2_jalr_target), .io_out_s2_full_pred_2_offsets_0(g_io_out_s2_full_pred_2_offsets_0), .io_out_s2_full_pred_2_offsets_1(g_io_out_s2_full_pred_2_offsets_1), .io_out_s2_full_pred_2_fallThroughAddr(g_io_out_s2_full_pred_2_fallThroughAddr), .io_out_s2_full_pred_2_fallThroughErr(g_io_out_s2_full_pred_2_fallThroughErr), .io_out_s2_full_pred_2_is_jal(g_io_out_s2_full_pred_2_is_jal), .io_out_s2_full_pred_2_is_jalr(g_io_out_s2_full_pred_2_is_jalr), .io_out_s2_full_pred_2_is_call(g_io_out_s2_full_pred_2_is_call), .io_out_s2_full_pred_2_is_ret(g_io_out_s2_full_pred_2_is_ret), .io_out_s2_full_pred_2_last_may_be_rvi_call(g_io_out_s2_full_pred_2_last_may_be_rvi_call), .io_out_s2_full_pred_2_is_br_sharing(g_io_out_s2_full_pred_2_is_br_sharing), .io_out_s2_full_pred_2_hit(g_io_out_s2_full_pred_2_hit), .io_out_s2_full_pred_3_br_taken_mask_0(g_io_out_s2_full_pred_3_br_taken_mask_0), .io_out_s2_full_pred_3_br_taken_mask_1(g_io_out_s2_full_pred_3_br_taken_mask_1), .io_out_s2_full_pred_3_slot_valids_0(g_io_out_s2_full_pred_3_slot_valids_0), .io_out_s2_full_pred_3_slot_valids_1(g_io_out_s2_full_pred_3_slot_valids_1), .io_out_s2_full_pred_3_targets_0(g_io_out_s2_full_pred_3_targets_0), .io_out_s2_full_pred_3_targets_1(g_io_out_s2_full_pred_3_targets_1), .io_out_s2_full_pred_3_jalr_target(g_io_out_s2_full_pred_3_jalr_target), .io_out_s2_full_pred_3_offsets_0(g_io_out_s2_full_pred_3_offsets_0), .io_out_s2_full_pred_3_offsets_1(g_io_out_s2_full_pred_3_offsets_1), .io_out_s2_full_pred_3_fallThroughAddr(g_io_out_s2_full_pred_3_fallThroughAddr), .io_out_s2_full_pred_3_fallThroughErr(g_io_out_s2_full_pred_3_fallThroughErr), .io_out_s2_full_pred_3_is_jal(g_io_out_s2_full_pred_3_is_jal), .io_out_s2_full_pred_3_is_jalr(g_io_out_s2_full_pred_3_is_jalr), .io_out_s2_full_pred_3_is_call(g_io_out_s2_full_pred_3_is_call), .io_out_s2_full_pred_3_is_ret(g_io_out_s2_full_pred_3_is_ret), .io_out_s2_full_pred_3_last_may_be_rvi_call(g_io_out_s2_full_pred_3_last_may_be_rvi_call), .io_out_s2_full_pred_3_is_br_sharing(g_io_out_s2_full_pred_3_is_br_sharing), .io_out_s2_full_pred_3_hit(g_io_out_s2_full_pred_3_hit), .io_out_s3_pc_0(g_io_out_s3_pc_0), .io_out_s3_pc_1(g_io_out_s3_pc_1), .io_out_s3_pc_2(g_io_out_s3_pc_2), .io_out_s3_pc_3(g_io_out_s3_pc_3), .io_out_s3_full_pred_0_br_taken_mask_0(g_io_out_s3_full_pred_0_br_taken_mask_0), .io_out_s3_full_pred_0_br_taken_mask_1(g_io_out_s3_full_pred_0_br_taken_mask_1), .io_out_s3_full_pred_0_slot_valids_0(g_io_out_s3_full_pred_0_slot_valids_0), .io_out_s3_full_pred_0_slot_valids_1(g_io_out_s3_full_pred_0_slot_valids_1), .io_out_s3_full_pred_0_targets_0(g_io_out_s3_full_pred_0_targets_0), .io_out_s3_full_pred_0_targets_1(g_io_out_s3_full_pred_0_targets_1), .io_out_s3_full_pred_0_jalr_target(g_io_out_s3_full_pred_0_jalr_target), .io_out_s3_full_pred_0_offsets_0(g_io_out_s3_full_pred_0_offsets_0), .io_out_s3_full_pred_0_offsets_1(g_io_out_s3_full_pred_0_offsets_1), .io_out_s3_full_pred_0_fallThroughAddr(g_io_out_s3_full_pred_0_fallThroughAddr), .io_out_s3_full_pred_0_fallThroughErr(g_io_out_s3_full_pred_0_fallThroughErr), .io_out_s3_full_pred_0_multiHit(g_io_out_s3_full_pred_0_multiHit), .io_out_s3_full_pred_0_is_jal(g_io_out_s3_full_pred_0_is_jal), .io_out_s3_full_pred_0_is_jalr(g_io_out_s3_full_pred_0_is_jalr), .io_out_s3_full_pred_0_is_call(g_io_out_s3_full_pred_0_is_call), .io_out_s3_full_pred_0_is_ret(g_io_out_s3_full_pred_0_is_ret), .io_out_s3_full_pred_0_last_may_be_rvi_call(g_io_out_s3_full_pred_0_last_may_be_rvi_call), .io_out_s3_full_pred_0_is_br_sharing(g_io_out_s3_full_pred_0_is_br_sharing), .io_out_s3_full_pred_0_hit(g_io_out_s3_full_pred_0_hit), .io_out_s3_full_pred_1_br_taken_mask_0(g_io_out_s3_full_pred_1_br_taken_mask_0), .io_out_s3_full_pred_1_br_taken_mask_1(g_io_out_s3_full_pred_1_br_taken_mask_1), .io_out_s3_full_pred_1_slot_valids_0(g_io_out_s3_full_pred_1_slot_valids_0), .io_out_s3_full_pred_1_slot_valids_1(g_io_out_s3_full_pred_1_slot_valids_1), .io_out_s3_full_pred_1_targets_0(g_io_out_s3_full_pred_1_targets_0), .io_out_s3_full_pred_1_targets_1(g_io_out_s3_full_pred_1_targets_1), .io_out_s3_full_pred_1_jalr_target(g_io_out_s3_full_pred_1_jalr_target), .io_out_s3_full_pred_1_offsets_0(g_io_out_s3_full_pred_1_offsets_0), .io_out_s3_full_pred_1_offsets_1(g_io_out_s3_full_pred_1_offsets_1), .io_out_s3_full_pred_1_fallThroughAddr(g_io_out_s3_full_pred_1_fallThroughAddr), .io_out_s3_full_pred_1_fallThroughErr(g_io_out_s3_full_pred_1_fallThroughErr), .io_out_s3_full_pred_1_multiHit(g_io_out_s3_full_pred_1_multiHit), .io_out_s3_full_pred_1_is_jal(g_io_out_s3_full_pred_1_is_jal), .io_out_s3_full_pred_1_is_jalr(g_io_out_s3_full_pred_1_is_jalr), .io_out_s3_full_pred_1_is_call(g_io_out_s3_full_pred_1_is_call), .io_out_s3_full_pred_1_is_ret(g_io_out_s3_full_pred_1_is_ret), .io_out_s3_full_pred_1_last_may_be_rvi_call(g_io_out_s3_full_pred_1_last_may_be_rvi_call), .io_out_s3_full_pred_1_is_br_sharing(g_io_out_s3_full_pred_1_is_br_sharing), .io_out_s3_full_pred_1_hit(g_io_out_s3_full_pred_1_hit), .io_out_s3_full_pred_2_br_taken_mask_0(g_io_out_s3_full_pred_2_br_taken_mask_0), .io_out_s3_full_pred_2_br_taken_mask_1(g_io_out_s3_full_pred_2_br_taken_mask_1), .io_out_s3_full_pred_2_slot_valids_0(g_io_out_s3_full_pred_2_slot_valids_0), .io_out_s3_full_pred_2_slot_valids_1(g_io_out_s3_full_pred_2_slot_valids_1), .io_out_s3_full_pred_2_targets_0(g_io_out_s3_full_pred_2_targets_0), .io_out_s3_full_pred_2_targets_1(g_io_out_s3_full_pred_2_targets_1), .io_out_s3_full_pred_2_jalr_target(g_io_out_s3_full_pred_2_jalr_target), .io_out_s3_full_pred_2_offsets_0(g_io_out_s3_full_pred_2_offsets_0), .io_out_s3_full_pred_2_offsets_1(g_io_out_s3_full_pred_2_offsets_1), .io_out_s3_full_pred_2_fallThroughAddr(g_io_out_s3_full_pred_2_fallThroughAddr), .io_out_s3_full_pred_2_fallThroughErr(g_io_out_s3_full_pred_2_fallThroughErr), .io_out_s3_full_pred_2_multiHit(g_io_out_s3_full_pred_2_multiHit), .io_out_s3_full_pred_2_is_jal(g_io_out_s3_full_pred_2_is_jal), .io_out_s3_full_pred_2_is_jalr(g_io_out_s3_full_pred_2_is_jalr), .io_out_s3_full_pred_2_is_call(g_io_out_s3_full_pred_2_is_call), .io_out_s3_full_pred_2_is_ret(g_io_out_s3_full_pred_2_is_ret), .io_out_s3_full_pred_2_last_may_be_rvi_call(g_io_out_s3_full_pred_2_last_may_be_rvi_call), .io_out_s3_full_pred_2_is_br_sharing(g_io_out_s3_full_pred_2_is_br_sharing), .io_out_s3_full_pred_2_hit(g_io_out_s3_full_pred_2_hit), .io_out_s3_full_pred_3_br_taken_mask_0(g_io_out_s3_full_pred_3_br_taken_mask_0), .io_out_s3_full_pred_3_br_taken_mask_1(g_io_out_s3_full_pred_3_br_taken_mask_1), .io_out_s3_full_pred_3_slot_valids_0(g_io_out_s3_full_pred_3_slot_valids_0), .io_out_s3_full_pred_3_slot_valids_1(g_io_out_s3_full_pred_3_slot_valids_1), .io_out_s3_full_pred_3_targets_0(g_io_out_s3_full_pred_3_targets_0), .io_out_s3_full_pred_3_targets_1(g_io_out_s3_full_pred_3_targets_1), .io_out_s3_full_pred_3_jalr_target(g_io_out_s3_full_pred_3_jalr_target), .io_out_s3_full_pred_3_offsets_0(g_io_out_s3_full_pred_3_offsets_0), .io_out_s3_full_pred_3_offsets_1(g_io_out_s3_full_pred_3_offsets_1), .io_out_s3_full_pred_3_fallThroughAddr(g_io_out_s3_full_pred_3_fallThroughAddr), .io_out_s3_full_pred_3_fallThroughErr(g_io_out_s3_full_pred_3_fallThroughErr), .io_out_s3_full_pred_3_multiHit(g_io_out_s3_full_pred_3_multiHit), .io_out_s3_full_pred_3_is_jal(g_io_out_s3_full_pred_3_is_jal), .io_out_s3_full_pred_3_is_jalr(g_io_out_s3_full_pred_3_is_jalr), .io_out_s3_full_pred_3_is_call(g_io_out_s3_full_pred_3_is_call), .io_out_s3_full_pred_3_is_ret(g_io_out_s3_full_pred_3_is_ret), .io_out_s3_full_pred_3_last_may_be_rvi_call(g_io_out_s3_full_pred_3_last_may_be_rvi_call), .io_out_s3_full_pred_3_is_br_sharing(g_io_out_s3_full_pred_3_is_br_sharing), .io_out_s3_full_pred_3_hit(g_io_out_s3_full_pred_3_hit), .io_out_last_stage_meta(g_io_out_last_stage_meta), .io_out_last_stage_spec_info_ssp(g_io_out_last_stage_spec_info_ssp), .io_out_last_stage_spec_info_sctr(g_io_out_last_stage_spec_info_sctr), .io_out_last_stage_spec_info_TOSW_flag(g_io_out_last_stage_spec_info_TOSW_flag), .io_out_last_stage_spec_info_TOSW_value(g_io_out_last_stage_spec_info_TOSW_value), .io_out_last_stage_spec_info_TOSR_flag(g_io_out_last_stage_spec_info_TOSR_flag), .io_out_last_stage_spec_info_TOSR_value(g_io_out_last_stage_spec_info_TOSR_value), .io_out_last_stage_spec_info_NOS_flag(g_io_out_last_stage_spec_info_NOS_flag), .io_out_last_stage_spec_info_NOS_value(g_io_out_last_stage_spec_info_NOS_value), .io_out_last_stage_spec_info_topAddr(g_io_out_last_stage_spec_info_topAddr), .io_out_last_stage_spec_info_sc_disagree_0(g_io_out_last_stage_spec_info_sc_disagree_0), .io_out_last_stage_spec_info_sc_disagree_1(g_io_out_last_stage_spec_info_sc_disagree_1), .io_out_last_stage_ftb_entry_isCall(g_io_out_last_stage_ftb_entry_isCall), .io_out_last_stage_ftb_entry_isRet(g_io_out_last_stage_ftb_entry_isRet), .io_out_last_stage_ftb_entry_isJalr(g_io_out_last_stage_ftb_entry_isJalr), .io_out_last_stage_ftb_entry_valid(g_io_out_last_stage_ftb_entry_valid), .io_out_last_stage_ftb_entry_brSlots_0_offset(g_io_out_last_stage_ftb_entry_brSlots_0_offset), .io_out_last_stage_ftb_entry_brSlots_0_sharing(g_io_out_last_stage_ftb_entry_brSlots_0_sharing), .io_out_last_stage_ftb_entry_brSlots_0_valid(g_io_out_last_stage_ftb_entry_brSlots_0_valid), .io_out_last_stage_ftb_entry_brSlots_0_lower(g_io_out_last_stage_ftb_entry_brSlots_0_lower), .io_out_last_stage_ftb_entry_brSlots_0_tarStat(g_io_out_last_stage_ftb_entry_brSlots_0_tarStat), .io_out_last_stage_ftb_entry_tailSlot_offset(g_io_out_last_stage_ftb_entry_tailSlot_offset), .io_out_last_stage_ftb_entry_tailSlot_sharing(g_io_out_last_stage_ftb_entry_tailSlot_sharing), .io_out_last_stage_ftb_entry_tailSlot_valid(g_io_out_last_stage_ftb_entry_tailSlot_valid), .io_out_last_stage_ftb_entry_tailSlot_lower(g_io_out_last_stage_ftb_entry_tailSlot_lower), .io_out_last_stage_ftb_entry_tailSlot_tarStat(g_io_out_last_stage_ftb_entry_tailSlot_tarStat), .io_out_last_stage_ftb_entry_pftAddr(g_io_out_last_stage_ftb_entry_pftAddr), .io_out_last_stage_ftb_entry_carry(g_io_out_last_stage_ftb_entry_carry), .io_out_last_stage_ftb_entry_last_may_be_rvi_call(g_io_out_last_stage_ftb_entry_last_may_be_rvi_call), .io_out_last_stage_ftb_entry_strong_bias_0(g_io_out_last_stage_ftb_entry_strong_bias_0), .io_out_last_stage_ftb_entry_strong_bias_1(g_io_out_last_stage_ftb_entry_strong_bias_1));
  RAS_xs u_i (.clock(clk), .reset(rst), .io_reset_vector(io_reset_vector), .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0), .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1), .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2), .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3), .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_0_targets_0(io_in_bits_resp_in_0_s2_full_pred_0_targets_0), .io_in_bits_resp_in_0_s2_full_pred_0_targets_1(io_in_bits_resp_in_0_s2_full_pred_0_targets_1), .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target(io_in_bits_resp_in_0_s2_full_pred_0_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0(io_in_bits_resp_in_0_s2_full_pred_0_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1(io_in_bits_resp_in_0_s2_full_pred_0_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_0_is_jal(io_in_bits_resp_in_0_s2_full_pred_0_is_jal), .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr(io_in_bits_resp_in_0_s2_full_pred_0_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_0_is_call(io_in_bits_resp_in_0_s2_full_pred_0_is_call), .io_in_bits_resp_in_0_s2_full_pred_0_is_ret(io_in_bits_resp_in_0_s2_full_pred_0_is_ret), .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_0_hit(io_in_bits_resp_in_0_s2_full_pred_0_hit), .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_1_targets_0(io_in_bits_resp_in_0_s2_full_pred_1_targets_0), .io_in_bits_resp_in_0_s2_full_pred_1_targets_1(io_in_bits_resp_in_0_s2_full_pred_1_targets_1), .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target(io_in_bits_resp_in_0_s2_full_pred_1_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0(io_in_bits_resp_in_0_s2_full_pred_1_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1(io_in_bits_resp_in_0_s2_full_pred_1_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_1_is_jal(io_in_bits_resp_in_0_s2_full_pred_1_is_jal), .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr(io_in_bits_resp_in_0_s2_full_pred_1_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_1_is_call(io_in_bits_resp_in_0_s2_full_pred_1_is_call), .io_in_bits_resp_in_0_s2_full_pred_1_is_ret(io_in_bits_resp_in_0_s2_full_pred_1_is_ret), .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_1_hit(io_in_bits_resp_in_0_s2_full_pred_1_hit), .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_2_targets_0(io_in_bits_resp_in_0_s2_full_pred_2_targets_0), .io_in_bits_resp_in_0_s2_full_pred_2_targets_1(io_in_bits_resp_in_0_s2_full_pred_2_targets_1), .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target(io_in_bits_resp_in_0_s2_full_pred_2_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0(io_in_bits_resp_in_0_s2_full_pred_2_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1(io_in_bits_resp_in_0_s2_full_pred_2_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_2_is_jal(io_in_bits_resp_in_0_s2_full_pred_2_is_jal), .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr(io_in_bits_resp_in_0_s2_full_pred_2_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_2_is_call(io_in_bits_resp_in_0_s2_full_pred_2_is_call), .io_in_bits_resp_in_0_s2_full_pred_2_is_ret(io_in_bits_resp_in_0_s2_full_pred_2_is_ret), .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_2_hit(io_in_bits_resp_in_0_s2_full_pred_2_hit), .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0), .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1), .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0(io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0), .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1(io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1), .io_in_bits_resp_in_0_s2_full_pred_3_targets_0(io_in_bits_resp_in_0_s2_full_pred_3_targets_0), .io_in_bits_resp_in_0_s2_full_pred_3_targets_1(io_in_bits_resp_in_0_s2_full_pred_3_targets_1), .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target(io_in_bits_resp_in_0_s2_full_pred_3_jalr_target), .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0(io_in_bits_resp_in_0_s2_full_pred_3_offsets_0), .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1(io_in_bits_resp_in_0_s2_full_pred_3_offsets_1), .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr(io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr), .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr(io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr), .io_in_bits_resp_in_0_s2_full_pred_3_is_jal(io_in_bits_resp_in_0_s2_full_pred_3_is_jal), .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr(io_in_bits_resp_in_0_s2_full_pred_3_is_jalr), .io_in_bits_resp_in_0_s2_full_pred_3_is_call(io_in_bits_resp_in_0_s2_full_pred_3_is_call), .io_in_bits_resp_in_0_s2_full_pred_3_is_ret(io_in_bits_resp_in_0_s2_full_pred_3_is_ret), .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call(io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call), .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing(io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing), .io_in_bits_resp_in_0_s2_full_pred_3_hit(io_in_bits_resp_in_0_s2_full_pred_3_hit), .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_0_targets_0(io_in_bits_resp_in_0_s3_full_pred_0_targets_0), .io_in_bits_resp_in_0_s3_full_pred_0_targets_1(io_in_bits_resp_in_0_s3_full_pred_0_targets_1), .io_in_bits_resp_in_0_s3_full_pred_0_jalr_target(io_in_bits_resp_in_0_s3_full_pred_0_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0(io_in_bits_resp_in_0_s3_full_pred_0_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1(io_in_bits_resp_in_0_s3_full_pred_0_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_0_multiHit(io_in_bits_resp_in_0_s3_full_pred_0_multiHit), .io_in_bits_resp_in_0_s3_full_pred_0_is_jal(io_in_bits_resp_in_0_s3_full_pred_0_is_jal), .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr(io_in_bits_resp_in_0_s3_full_pred_0_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_0_is_call(io_in_bits_resp_in_0_s3_full_pred_0_is_call), .io_in_bits_resp_in_0_s3_full_pred_0_is_ret(io_in_bits_resp_in_0_s3_full_pred_0_is_ret), .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_0_hit(io_in_bits_resp_in_0_s3_full_pred_0_hit), .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_1_targets_0(io_in_bits_resp_in_0_s3_full_pred_1_targets_0), .io_in_bits_resp_in_0_s3_full_pred_1_targets_1(io_in_bits_resp_in_0_s3_full_pred_1_targets_1), .io_in_bits_resp_in_0_s3_full_pred_1_jalr_target(io_in_bits_resp_in_0_s3_full_pred_1_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0(io_in_bits_resp_in_0_s3_full_pred_1_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1(io_in_bits_resp_in_0_s3_full_pred_1_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_1_multiHit(io_in_bits_resp_in_0_s3_full_pred_1_multiHit), .io_in_bits_resp_in_0_s3_full_pred_1_is_jal(io_in_bits_resp_in_0_s3_full_pred_1_is_jal), .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr(io_in_bits_resp_in_0_s3_full_pred_1_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_1_is_call(io_in_bits_resp_in_0_s3_full_pred_1_is_call), .io_in_bits_resp_in_0_s3_full_pred_1_is_ret(io_in_bits_resp_in_0_s3_full_pred_1_is_ret), .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_1_hit(io_in_bits_resp_in_0_s3_full_pred_1_hit), .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_2_targets_0(io_in_bits_resp_in_0_s3_full_pred_2_targets_0), .io_in_bits_resp_in_0_s3_full_pred_2_targets_1(io_in_bits_resp_in_0_s3_full_pred_2_targets_1), .io_in_bits_resp_in_0_s3_full_pred_2_jalr_target(io_in_bits_resp_in_0_s3_full_pred_2_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0(io_in_bits_resp_in_0_s3_full_pred_2_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1(io_in_bits_resp_in_0_s3_full_pred_2_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_2_multiHit(io_in_bits_resp_in_0_s3_full_pred_2_multiHit), .io_in_bits_resp_in_0_s3_full_pred_2_is_jal(io_in_bits_resp_in_0_s3_full_pred_2_is_jal), .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr(io_in_bits_resp_in_0_s3_full_pred_2_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_2_is_call(io_in_bits_resp_in_0_s3_full_pred_2_is_call), .io_in_bits_resp_in_0_s3_full_pred_2_is_ret(io_in_bits_resp_in_0_s3_full_pred_2_is_ret), .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_2_hit(io_in_bits_resp_in_0_s3_full_pred_2_hit), .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0), .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1), .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0(io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0), .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1(io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1), .io_in_bits_resp_in_0_s3_full_pred_3_targets_0(io_in_bits_resp_in_0_s3_full_pred_3_targets_0), .io_in_bits_resp_in_0_s3_full_pred_3_targets_1(io_in_bits_resp_in_0_s3_full_pred_3_targets_1), .io_in_bits_resp_in_0_s3_full_pred_3_jalr_target(io_in_bits_resp_in_0_s3_full_pred_3_jalr_target), .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0(io_in_bits_resp_in_0_s3_full_pred_3_offsets_0), .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1(io_in_bits_resp_in_0_s3_full_pred_3_offsets_1), .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr(io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr), .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr(io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr), .io_in_bits_resp_in_0_s3_full_pred_3_multiHit(io_in_bits_resp_in_0_s3_full_pred_3_multiHit), .io_in_bits_resp_in_0_s3_full_pred_3_is_jal(io_in_bits_resp_in_0_s3_full_pred_3_is_jal), .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr(io_in_bits_resp_in_0_s3_full_pred_3_is_jalr), .io_in_bits_resp_in_0_s3_full_pred_3_is_call(io_in_bits_resp_in_0_s3_full_pred_3_is_call), .io_in_bits_resp_in_0_s3_full_pred_3_is_ret(io_in_bits_resp_in_0_s3_full_pred_3_is_ret), .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call(io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call), .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing(io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing), .io_in_bits_resp_in_0_s3_full_pred_3_hit(io_in_bits_resp_in_0_s3_full_pred_3_hit), .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0), .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1), .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall(io_in_bits_resp_in_0_last_stage_ftb_entry_isCall), .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet(io_in_bits_resp_in_0_last_stage_ftb_entry_isRet), .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr(io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr), .io_in_bits_resp_in_0_last_stage_ftb_entry_valid(io_in_bits_resp_in_0_last_stage_ftb_entry_valid), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower), .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat(io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower), .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat(io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat), .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr(io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr), .io_in_bits_resp_in_0_last_stage_ftb_entry_carry(io_in_bits_resp_in_0_last_stage_ftb_entry_carry), .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call(io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call), .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0(io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0), .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1(io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1), .io_ctrl_ras_enable(io_ctrl_ras_enable), .io_s0_fire_0(io_s0_fire_0), .io_s0_fire_1(io_s0_fire_1), .io_s0_fire_2(io_s0_fire_2), .io_s0_fire_3(io_s0_fire_3), .io_s1_fire_0(io_s1_fire_0), .io_s1_fire_1(io_s1_fire_1), .io_s1_fire_2(io_s1_fire_2), .io_s1_fire_3(io_s1_fire_3), .io_s2_fire_0(io_s2_fire_0), .io_s2_fire_1(io_s2_fire_1), .io_s2_fire_2(io_s2_fire_2), .io_s2_fire_3(io_s2_fire_3), .io_s3_fire_2(io_s3_fire_2), .io_s3_redirect_2(io_s3_redirect_2), .io_update_valid(io_update_valid), .io_update_bits_ftb_entry_isCall(io_update_bits_ftb_entry_isCall), .io_update_bits_ftb_entry_isRet(io_update_bits_ftb_entry_isRet), .io_update_bits_ftb_entry_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset), .io_update_bits_ftb_entry_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid), .io_update_bits_cfi_idx_valid(io_update_bits_cfi_idx_valid), .io_update_bits_cfi_idx_bits(io_update_bits_cfi_idx_bits), .io_update_bits_jmp_taken(io_update_bits_jmp_taken), .io_update_bits_meta(io_update_bits_meta), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_level(io_redirect_bits_level), .io_redirect_bits_cfiUpdate_pc(io_redirect_bits_cfiUpdate_pc), .io_redirect_bits_cfiUpdate_pd_valid(io_redirect_bits_cfiUpdate_pd_valid), .io_redirect_bits_cfiUpdate_pd_isRVC(io_redirect_bits_cfiUpdate_pd_isRVC), .io_redirect_bits_cfiUpdate_pd_isCall(io_redirect_bits_cfiUpdate_pd_isCall), .io_redirect_bits_cfiUpdate_pd_isRet(io_redirect_bits_cfiUpdate_pd_isRet), .io_redirect_bits_cfiUpdate_ssp(io_redirect_bits_cfiUpdate_ssp), .io_redirect_bits_cfiUpdate_sctr(io_redirect_bits_cfiUpdate_sctr), .io_redirect_bits_cfiUpdate_TOSW_flag(io_redirect_bits_cfiUpdate_TOSW_flag), .io_redirect_bits_cfiUpdate_TOSW_value(io_redirect_bits_cfiUpdate_TOSW_value), .io_redirect_bits_cfiUpdate_TOSR_flag(io_redirect_bits_cfiUpdate_TOSR_flag), .io_redirect_bits_cfiUpdate_TOSR_value(io_redirect_bits_cfiUpdate_TOSR_value), .io_redirect_bits_cfiUpdate_NOS_flag(io_redirect_bits_cfiUpdate_NOS_flag), .io_redirect_bits_cfiUpdate_NOS_value(io_redirect_bits_cfiUpdate_NOS_value), .io_out_s2_pc_0(i_io_out_s2_pc_0), .io_out_s2_pc_1(i_io_out_s2_pc_1), .io_out_s2_pc_2(i_io_out_s2_pc_2), .io_out_s2_pc_3(i_io_out_s2_pc_3), .io_out_s2_full_pred_0_br_taken_mask_0(i_io_out_s2_full_pred_0_br_taken_mask_0), .io_out_s2_full_pred_0_br_taken_mask_1(i_io_out_s2_full_pred_0_br_taken_mask_1), .io_out_s2_full_pred_0_slot_valids_0(i_io_out_s2_full_pred_0_slot_valids_0), .io_out_s2_full_pred_0_slot_valids_1(i_io_out_s2_full_pred_0_slot_valids_1), .io_out_s2_full_pred_0_targets_0(i_io_out_s2_full_pred_0_targets_0), .io_out_s2_full_pred_0_targets_1(i_io_out_s2_full_pred_0_targets_1), .io_out_s2_full_pred_0_jalr_target(i_io_out_s2_full_pred_0_jalr_target), .io_out_s2_full_pred_0_offsets_0(i_io_out_s2_full_pred_0_offsets_0), .io_out_s2_full_pred_0_offsets_1(i_io_out_s2_full_pred_0_offsets_1), .io_out_s2_full_pred_0_fallThroughAddr(i_io_out_s2_full_pred_0_fallThroughAddr), .io_out_s2_full_pred_0_fallThroughErr(i_io_out_s2_full_pred_0_fallThroughErr), .io_out_s2_full_pred_0_is_jal(i_io_out_s2_full_pred_0_is_jal), .io_out_s2_full_pred_0_is_jalr(i_io_out_s2_full_pred_0_is_jalr), .io_out_s2_full_pred_0_is_call(i_io_out_s2_full_pred_0_is_call), .io_out_s2_full_pred_0_is_ret(i_io_out_s2_full_pred_0_is_ret), .io_out_s2_full_pred_0_last_may_be_rvi_call(i_io_out_s2_full_pred_0_last_may_be_rvi_call), .io_out_s2_full_pred_0_is_br_sharing(i_io_out_s2_full_pred_0_is_br_sharing), .io_out_s2_full_pred_0_hit(i_io_out_s2_full_pred_0_hit), .io_out_s2_full_pred_1_br_taken_mask_0(i_io_out_s2_full_pred_1_br_taken_mask_0), .io_out_s2_full_pred_1_br_taken_mask_1(i_io_out_s2_full_pred_1_br_taken_mask_1), .io_out_s2_full_pred_1_slot_valids_0(i_io_out_s2_full_pred_1_slot_valids_0), .io_out_s2_full_pred_1_slot_valids_1(i_io_out_s2_full_pred_1_slot_valids_1), .io_out_s2_full_pred_1_targets_0(i_io_out_s2_full_pred_1_targets_0), .io_out_s2_full_pred_1_targets_1(i_io_out_s2_full_pred_1_targets_1), .io_out_s2_full_pred_1_jalr_target(i_io_out_s2_full_pred_1_jalr_target), .io_out_s2_full_pred_1_offsets_0(i_io_out_s2_full_pred_1_offsets_0), .io_out_s2_full_pred_1_offsets_1(i_io_out_s2_full_pred_1_offsets_1), .io_out_s2_full_pred_1_fallThroughAddr(i_io_out_s2_full_pred_1_fallThroughAddr), .io_out_s2_full_pred_1_fallThroughErr(i_io_out_s2_full_pred_1_fallThroughErr), .io_out_s2_full_pred_1_is_jal(i_io_out_s2_full_pred_1_is_jal), .io_out_s2_full_pred_1_is_jalr(i_io_out_s2_full_pred_1_is_jalr), .io_out_s2_full_pred_1_is_call(i_io_out_s2_full_pred_1_is_call), .io_out_s2_full_pred_1_is_ret(i_io_out_s2_full_pred_1_is_ret), .io_out_s2_full_pred_1_last_may_be_rvi_call(i_io_out_s2_full_pred_1_last_may_be_rvi_call), .io_out_s2_full_pred_1_is_br_sharing(i_io_out_s2_full_pred_1_is_br_sharing), .io_out_s2_full_pred_1_hit(i_io_out_s2_full_pred_1_hit), .io_out_s2_full_pred_2_br_taken_mask_0(i_io_out_s2_full_pred_2_br_taken_mask_0), .io_out_s2_full_pred_2_br_taken_mask_1(i_io_out_s2_full_pred_2_br_taken_mask_1), .io_out_s2_full_pred_2_slot_valids_0(i_io_out_s2_full_pred_2_slot_valids_0), .io_out_s2_full_pred_2_slot_valids_1(i_io_out_s2_full_pred_2_slot_valids_1), .io_out_s2_full_pred_2_targets_0(i_io_out_s2_full_pred_2_targets_0), .io_out_s2_full_pred_2_targets_1(i_io_out_s2_full_pred_2_targets_1), .io_out_s2_full_pred_2_jalr_target(i_io_out_s2_full_pred_2_jalr_target), .io_out_s2_full_pred_2_offsets_0(i_io_out_s2_full_pred_2_offsets_0), .io_out_s2_full_pred_2_offsets_1(i_io_out_s2_full_pred_2_offsets_1), .io_out_s2_full_pred_2_fallThroughAddr(i_io_out_s2_full_pred_2_fallThroughAddr), .io_out_s2_full_pred_2_fallThroughErr(i_io_out_s2_full_pred_2_fallThroughErr), .io_out_s2_full_pred_2_is_jal(i_io_out_s2_full_pred_2_is_jal), .io_out_s2_full_pred_2_is_jalr(i_io_out_s2_full_pred_2_is_jalr), .io_out_s2_full_pred_2_is_call(i_io_out_s2_full_pred_2_is_call), .io_out_s2_full_pred_2_is_ret(i_io_out_s2_full_pred_2_is_ret), .io_out_s2_full_pred_2_last_may_be_rvi_call(i_io_out_s2_full_pred_2_last_may_be_rvi_call), .io_out_s2_full_pred_2_is_br_sharing(i_io_out_s2_full_pred_2_is_br_sharing), .io_out_s2_full_pred_2_hit(i_io_out_s2_full_pred_2_hit), .io_out_s2_full_pred_3_br_taken_mask_0(i_io_out_s2_full_pred_3_br_taken_mask_0), .io_out_s2_full_pred_3_br_taken_mask_1(i_io_out_s2_full_pred_3_br_taken_mask_1), .io_out_s2_full_pred_3_slot_valids_0(i_io_out_s2_full_pred_3_slot_valids_0), .io_out_s2_full_pred_3_slot_valids_1(i_io_out_s2_full_pred_3_slot_valids_1), .io_out_s2_full_pred_3_targets_0(i_io_out_s2_full_pred_3_targets_0), .io_out_s2_full_pred_3_targets_1(i_io_out_s2_full_pred_3_targets_1), .io_out_s2_full_pred_3_jalr_target(i_io_out_s2_full_pred_3_jalr_target), .io_out_s2_full_pred_3_offsets_0(i_io_out_s2_full_pred_3_offsets_0), .io_out_s2_full_pred_3_offsets_1(i_io_out_s2_full_pred_3_offsets_1), .io_out_s2_full_pred_3_fallThroughAddr(i_io_out_s2_full_pred_3_fallThroughAddr), .io_out_s2_full_pred_3_fallThroughErr(i_io_out_s2_full_pred_3_fallThroughErr), .io_out_s2_full_pred_3_is_jal(i_io_out_s2_full_pred_3_is_jal), .io_out_s2_full_pred_3_is_jalr(i_io_out_s2_full_pred_3_is_jalr), .io_out_s2_full_pred_3_is_call(i_io_out_s2_full_pred_3_is_call), .io_out_s2_full_pred_3_is_ret(i_io_out_s2_full_pred_3_is_ret), .io_out_s2_full_pred_3_last_may_be_rvi_call(i_io_out_s2_full_pred_3_last_may_be_rvi_call), .io_out_s2_full_pred_3_is_br_sharing(i_io_out_s2_full_pred_3_is_br_sharing), .io_out_s2_full_pred_3_hit(i_io_out_s2_full_pred_3_hit), .io_out_s3_pc_0(i_io_out_s3_pc_0), .io_out_s3_pc_1(i_io_out_s3_pc_1), .io_out_s3_pc_2(i_io_out_s3_pc_2), .io_out_s3_pc_3(i_io_out_s3_pc_3), .io_out_s3_full_pred_0_br_taken_mask_0(i_io_out_s3_full_pred_0_br_taken_mask_0), .io_out_s3_full_pred_0_br_taken_mask_1(i_io_out_s3_full_pred_0_br_taken_mask_1), .io_out_s3_full_pred_0_slot_valids_0(i_io_out_s3_full_pred_0_slot_valids_0), .io_out_s3_full_pred_0_slot_valids_1(i_io_out_s3_full_pred_0_slot_valids_1), .io_out_s3_full_pred_0_targets_0(i_io_out_s3_full_pred_0_targets_0), .io_out_s3_full_pred_0_targets_1(i_io_out_s3_full_pred_0_targets_1), .io_out_s3_full_pred_0_jalr_target(i_io_out_s3_full_pred_0_jalr_target), .io_out_s3_full_pred_0_offsets_0(i_io_out_s3_full_pred_0_offsets_0), .io_out_s3_full_pred_0_offsets_1(i_io_out_s3_full_pred_0_offsets_1), .io_out_s3_full_pred_0_fallThroughAddr(i_io_out_s3_full_pred_0_fallThroughAddr), .io_out_s3_full_pred_0_fallThroughErr(i_io_out_s3_full_pred_0_fallThroughErr), .io_out_s3_full_pred_0_multiHit(i_io_out_s3_full_pred_0_multiHit), .io_out_s3_full_pred_0_is_jal(i_io_out_s3_full_pred_0_is_jal), .io_out_s3_full_pred_0_is_jalr(i_io_out_s3_full_pred_0_is_jalr), .io_out_s3_full_pred_0_is_call(i_io_out_s3_full_pred_0_is_call), .io_out_s3_full_pred_0_is_ret(i_io_out_s3_full_pred_0_is_ret), .io_out_s3_full_pred_0_last_may_be_rvi_call(i_io_out_s3_full_pred_0_last_may_be_rvi_call), .io_out_s3_full_pred_0_is_br_sharing(i_io_out_s3_full_pred_0_is_br_sharing), .io_out_s3_full_pred_0_hit(i_io_out_s3_full_pred_0_hit), .io_out_s3_full_pred_1_br_taken_mask_0(i_io_out_s3_full_pred_1_br_taken_mask_0), .io_out_s3_full_pred_1_br_taken_mask_1(i_io_out_s3_full_pred_1_br_taken_mask_1), .io_out_s3_full_pred_1_slot_valids_0(i_io_out_s3_full_pred_1_slot_valids_0), .io_out_s3_full_pred_1_slot_valids_1(i_io_out_s3_full_pred_1_slot_valids_1), .io_out_s3_full_pred_1_targets_0(i_io_out_s3_full_pred_1_targets_0), .io_out_s3_full_pred_1_targets_1(i_io_out_s3_full_pred_1_targets_1), .io_out_s3_full_pred_1_jalr_target(i_io_out_s3_full_pred_1_jalr_target), .io_out_s3_full_pred_1_offsets_0(i_io_out_s3_full_pred_1_offsets_0), .io_out_s3_full_pred_1_offsets_1(i_io_out_s3_full_pred_1_offsets_1), .io_out_s3_full_pred_1_fallThroughAddr(i_io_out_s3_full_pred_1_fallThroughAddr), .io_out_s3_full_pred_1_fallThroughErr(i_io_out_s3_full_pred_1_fallThroughErr), .io_out_s3_full_pred_1_multiHit(i_io_out_s3_full_pred_1_multiHit), .io_out_s3_full_pred_1_is_jal(i_io_out_s3_full_pred_1_is_jal), .io_out_s3_full_pred_1_is_jalr(i_io_out_s3_full_pred_1_is_jalr), .io_out_s3_full_pred_1_is_call(i_io_out_s3_full_pred_1_is_call), .io_out_s3_full_pred_1_is_ret(i_io_out_s3_full_pred_1_is_ret), .io_out_s3_full_pred_1_last_may_be_rvi_call(i_io_out_s3_full_pred_1_last_may_be_rvi_call), .io_out_s3_full_pred_1_is_br_sharing(i_io_out_s3_full_pred_1_is_br_sharing), .io_out_s3_full_pred_1_hit(i_io_out_s3_full_pred_1_hit), .io_out_s3_full_pred_2_br_taken_mask_0(i_io_out_s3_full_pred_2_br_taken_mask_0), .io_out_s3_full_pred_2_br_taken_mask_1(i_io_out_s3_full_pred_2_br_taken_mask_1), .io_out_s3_full_pred_2_slot_valids_0(i_io_out_s3_full_pred_2_slot_valids_0), .io_out_s3_full_pred_2_slot_valids_1(i_io_out_s3_full_pred_2_slot_valids_1), .io_out_s3_full_pred_2_targets_0(i_io_out_s3_full_pred_2_targets_0), .io_out_s3_full_pred_2_targets_1(i_io_out_s3_full_pred_2_targets_1), .io_out_s3_full_pred_2_jalr_target(i_io_out_s3_full_pred_2_jalr_target), .io_out_s3_full_pred_2_offsets_0(i_io_out_s3_full_pred_2_offsets_0), .io_out_s3_full_pred_2_offsets_1(i_io_out_s3_full_pred_2_offsets_1), .io_out_s3_full_pred_2_fallThroughAddr(i_io_out_s3_full_pred_2_fallThroughAddr), .io_out_s3_full_pred_2_fallThroughErr(i_io_out_s3_full_pred_2_fallThroughErr), .io_out_s3_full_pred_2_multiHit(i_io_out_s3_full_pred_2_multiHit), .io_out_s3_full_pred_2_is_jal(i_io_out_s3_full_pred_2_is_jal), .io_out_s3_full_pred_2_is_jalr(i_io_out_s3_full_pred_2_is_jalr), .io_out_s3_full_pred_2_is_call(i_io_out_s3_full_pred_2_is_call), .io_out_s3_full_pred_2_is_ret(i_io_out_s3_full_pred_2_is_ret), .io_out_s3_full_pred_2_last_may_be_rvi_call(i_io_out_s3_full_pred_2_last_may_be_rvi_call), .io_out_s3_full_pred_2_is_br_sharing(i_io_out_s3_full_pred_2_is_br_sharing), .io_out_s3_full_pred_2_hit(i_io_out_s3_full_pred_2_hit), .io_out_s3_full_pred_3_br_taken_mask_0(i_io_out_s3_full_pred_3_br_taken_mask_0), .io_out_s3_full_pred_3_br_taken_mask_1(i_io_out_s3_full_pred_3_br_taken_mask_1), .io_out_s3_full_pred_3_slot_valids_0(i_io_out_s3_full_pred_3_slot_valids_0), .io_out_s3_full_pred_3_slot_valids_1(i_io_out_s3_full_pred_3_slot_valids_1), .io_out_s3_full_pred_3_targets_0(i_io_out_s3_full_pred_3_targets_0), .io_out_s3_full_pred_3_targets_1(i_io_out_s3_full_pred_3_targets_1), .io_out_s3_full_pred_3_jalr_target(i_io_out_s3_full_pred_3_jalr_target), .io_out_s3_full_pred_3_offsets_0(i_io_out_s3_full_pred_3_offsets_0), .io_out_s3_full_pred_3_offsets_1(i_io_out_s3_full_pred_3_offsets_1), .io_out_s3_full_pred_3_fallThroughAddr(i_io_out_s3_full_pred_3_fallThroughAddr), .io_out_s3_full_pred_3_fallThroughErr(i_io_out_s3_full_pred_3_fallThroughErr), .io_out_s3_full_pred_3_multiHit(i_io_out_s3_full_pred_3_multiHit), .io_out_s3_full_pred_3_is_jal(i_io_out_s3_full_pred_3_is_jal), .io_out_s3_full_pred_3_is_jalr(i_io_out_s3_full_pred_3_is_jalr), .io_out_s3_full_pred_3_is_call(i_io_out_s3_full_pred_3_is_call), .io_out_s3_full_pred_3_is_ret(i_io_out_s3_full_pred_3_is_ret), .io_out_s3_full_pred_3_last_may_be_rvi_call(i_io_out_s3_full_pred_3_last_may_be_rvi_call), .io_out_s3_full_pred_3_is_br_sharing(i_io_out_s3_full_pred_3_is_br_sharing), .io_out_s3_full_pred_3_hit(i_io_out_s3_full_pred_3_hit), .io_out_last_stage_meta(i_io_out_last_stage_meta), .io_out_last_stage_spec_info_ssp(i_io_out_last_stage_spec_info_ssp), .io_out_last_stage_spec_info_sctr(i_io_out_last_stage_spec_info_sctr), .io_out_last_stage_spec_info_TOSW_flag(i_io_out_last_stage_spec_info_TOSW_flag), .io_out_last_stage_spec_info_TOSW_value(i_io_out_last_stage_spec_info_TOSW_value), .io_out_last_stage_spec_info_TOSR_flag(i_io_out_last_stage_spec_info_TOSR_flag), .io_out_last_stage_spec_info_TOSR_value(i_io_out_last_stage_spec_info_TOSR_value), .io_out_last_stage_spec_info_NOS_flag(i_io_out_last_stage_spec_info_NOS_flag), .io_out_last_stage_spec_info_NOS_value(i_io_out_last_stage_spec_info_NOS_value), .io_out_last_stage_spec_info_topAddr(i_io_out_last_stage_spec_info_topAddr), .io_out_last_stage_spec_info_sc_disagree_0(i_io_out_last_stage_spec_info_sc_disagree_0), .io_out_last_stage_spec_info_sc_disagree_1(i_io_out_last_stage_spec_info_sc_disagree_1), .io_out_last_stage_ftb_entry_isCall(i_io_out_last_stage_ftb_entry_isCall), .io_out_last_stage_ftb_entry_isRet(i_io_out_last_stage_ftb_entry_isRet), .io_out_last_stage_ftb_entry_isJalr(i_io_out_last_stage_ftb_entry_isJalr), .io_out_last_stage_ftb_entry_valid(i_io_out_last_stage_ftb_entry_valid), .io_out_last_stage_ftb_entry_brSlots_0_offset(i_io_out_last_stage_ftb_entry_brSlots_0_offset), .io_out_last_stage_ftb_entry_brSlots_0_sharing(i_io_out_last_stage_ftb_entry_brSlots_0_sharing), .io_out_last_stage_ftb_entry_brSlots_0_valid(i_io_out_last_stage_ftb_entry_brSlots_0_valid), .io_out_last_stage_ftb_entry_brSlots_0_lower(i_io_out_last_stage_ftb_entry_brSlots_0_lower), .io_out_last_stage_ftb_entry_brSlots_0_tarStat(i_io_out_last_stage_ftb_entry_brSlots_0_tarStat), .io_out_last_stage_ftb_entry_tailSlot_offset(i_io_out_last_stage_ftb_entry_tailSlot_offset), .io_out_last_stage_ftb_entry_tailSlot_sharing(i_io_out_last_stage_ftb_entry_tailSlot_sharing), .io_out_last_stage_ftb_entry_tailSlot_valid(i_io_out_last_stage_ftb_entry_tailSlot_valid), .io_out_last_stage_ftb_entry_tailSlot_lower(i_io_out_last_stage_ftb_entry_tailSlot_lower), .io_out_last_stage_ftb_entry_tailSlot_tarStat(i_io_out_last_stage_ftb_entry_tailSlot_tarStat), .io_out_last_stage_ftb_entry_pftAddr(i_io_out_last_stage_ftb_entry_pftAddr), .io_out_last_stage_ftb_entry_carry(i_io_out_last_stage_ftb_entry_carry), .io_out_last_stage_ftb_entry_last_may_be_rvi_call(i_io_out_last_stage_ftb_entry_last_may_be_rvi_call), .io_out_last_stage_ftb_entry_strong_bias_0(i_io_out_last_stage_ftb_entry_strong_bias_0), .io_out_last_stage_ftb_entry_strong_bias_1(i_io_out_last_stage_ftb_entry_strong_bias_1));
  task automatic drive();
    io_reset_vector <= 48'({$urandom(), $urandom()});
    io_in_bits_s0_pc_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_s0_pc_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_s0_pc_2 <= 50'({$urandom(), $urandom()});
    io_in_bits_s0_pc_3 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_0_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_0_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_0_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_0_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_1_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_1_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_1_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_1_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_2_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_2_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_2_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_2_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_3_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_3_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_3_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s2_full_pred_3_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_0_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_0_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_0_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_multiHit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_0_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_1_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_1_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_1_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_multiHit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_1_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_2_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_2_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_2_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_multiHit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_2_hit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1 <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_targets_0 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_3_targets_1 <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_3_jalr_target <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_3_offsets_0 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_offsets_1 <= 4'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr <= 50'({$urandom(), $urandom()});
    io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_multiHit <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_is_jal <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_is_jalr <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_is_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_is_ret <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_s3_full_pred_3_hit <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0 <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1 <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_isCall <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_isRet <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_valid <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset <= 4'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower <= 12'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat <= 2'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset <= 4'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower <= 20'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat <= 2'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr <= 4'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_carry <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0 <= 1'($urandom);
    io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1 <= 1'($urandom);
    io_ctrl_ras_enable <= ($urandom_range(0,7)!=0);
    io_s0_fire_0 <= ($urandom_range(0,1));
    io_s0_fire_1 <= ($urandom_range(0,1));
    io_s0_fire_2 <= ($urandom_range(0,1));
    io_s0_fire_3 <= ($urandom_range(0,1));
    io_s1_fire_0 <= ($urandom_range(0,1));
    io_s1_fire_1 <= ($urandom_range(0,1));
    io_s1_fire_2 <= ($urandom_range(0,1));
    io_s1_fire_3 <= ($urandom_range(0,1));
    io_s2_fire_0 <= ($urandom_range(0,1));
    io_s2_fire_1 <= ($urandom_range(0,1));
    io_s2_fire_2 <= ($urandom_range(0,1));
    io_s2_fire_3 <= ($urandom_range(0,1));
    io_s3_fire_2 <= ($urandom_range(0,1));
    io_s3_redirect_2 <= 1'($urandom);
    io_update_valid <= ($urandom_range(0,3)==0);
    io_update_bits_ftb_entry_isCall <= 1'($urandom);
    io_update_bits_ftb_entry_isRet <= 1'($urandom);
    io_update_bits_ftb_entry_tailSlot_offset <= 4'($urandom);
    io_update_bits_ftb_entry_tailSlot_valid <= 1'($urandom);
    io_update_bits_cfi_idx_valid <= 1'($urandom);
    io_update_bits_cfi_idx_bits <= 4'($urandom);
    io_update_bits_jmp_taken <= 1'($urandom);
    io_update_bits_meta <= 516'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
    io_redirect_valid <= ($urandom_range(0,3)==0);
    io_redirect_bits_level <= 1'($urandom);
    io_redirect_bits_cfiUpdate_pc <= 50'({$urandom(), $urandom()});
    io_redirect_bits_cfiUpdate_pd_valid <= 1'($urandom);
    io_redirect_bits_cfiUpdate_pd_isRVC <= 1'($urandom);
    io_redirect_bits_cfiUpdate_pd_isCall <= 1'($urandom);
    io_redirect_bits_cfiUpdate_pd_isRet <= 1'($urandom);
    io_redirect_bits_cfiUpdate_ssp <= 4'($urandom);
    io_redirect_bits_cfiUpdate_sctr <= 3'($urandom);
    io_redirect_bits_cfiUpdate_TOSW_flag <= 1'($urandom);
    io_redirect_bits_cfiUpdate_TOSW_value <= 5'($urandom);
    io_redirect_bits_cfiUpdate_TOSR_flag <= 1'($urandom);
    io_redirect_bits_cfiUpdate_TOSR_value <= 5'($urandom);
    io_redirect_bits_cfiUpdate_NOS_flag <= 1'($urandom);
    io_redirect_bits_cfiUpdate_NOS_value <= 5'($urandom);
  endtask
  always @(negedge clk) begin
    if (rst) begin
      io_s0_fire_0<=0; io_s0_fire_1<=0; io_s0_fire_2<=0; io_s0_fire_3<=0;
      io_s1_fire_0<=0; io_s1_fire_1<=0; io_s1_fire_2<=0; io_s1_fire_3<=0;
      io_s2_fire_0<=0; io_s2_fire_1<=0; io_s2_fire_2<=0; io_s2_fire_3<=0;
      io_s3_fire_2<=0; io_update_valid<=0; io_redirect_valid<=0;
    end else drive();
  end
  int warm = 0;
  always @(negedge clk) if (!rst) warm++;
  always @(negedge clk) if (!rst && warm > 40) begin
    #2; checks++;
    if (g_io_out_s2_pc_0 !== i_io_out_s2_pc_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_pc_0 g=%h i=%h", $time, g_io_out_s2_pc_0, i_io_out_s2_pc_0); end
    if (g_io_out_s2_pc_1 !== i_io_out_s2_pc_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_pc_1 g=%h i=%h", $time, g_io_out_s2_pc_1, i_io_out_s2_pc_1); end
    if (g_io_out_s2_pc_2 !== i_io_out_s2_pc_2) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_pc_2 g=%h i=%h", $time, g_io_out_s2_pc_2, i_io_out_s2_pc_2); end
    if (g_io_out_s2_pc_3 !== i_io_out_s2_pc_3) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_pc_3 g=%h i=%h", $time, g_io_out_s2_pc_3, i_io_out_s2_pc_3); end
    if (g_io_out_s2_full_pred_0_br_taken_mask_0 !== i_io_out_s2_full_pred_0_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s2_full_pred_0_br_taken_mask_0, i_io_out_s2_full_pred_0_br_taken_mask_0); end
    if (g_io_out_s2_full_pred_0_br_taken_mask_1 !== i_io_out_s2_full_pred_0_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s2_full_pred_0_br_taken_mask_1, i_io_out_s2_full_pred_0_br_taken_mask_1); end
    if (g_io_out_s2_full_pred_0_slot_valids_0 !== i_io_out_s2_full_pred_0_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_slot_valids_0 g=%h i=%h", $time, g_io_out_s2_full_pred_0_slot_valids_0, i_io_out_s2_full_pred_0_slot_valids_0); end
    if (g_io_out_s2_full_pred_0_slot_valids_1 !== i_io_out_s2_full_pred_0_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_slot_valids_1 g=%h i=%h", $time, g_io_out_s2_full_pred_0_slot_valids_1, i_io_out_s2_full_pred_0_slot_valids_1); end
    if (g_io_out_s2_full_pred_0_targets_0 !== i_io_out_s2_full_pred_0_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_targets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_0_targets_0, i_io_out_s2_full_pred_0_targets_0); end
    if (g_io_out_s2_full_pred_0_targets_1 !== i_io_out_s2_full_pred_0_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_targets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_0_targets_1, i_io_out_s2_full_pred_0_targets_1); end
    if (g_io_out_s2_full_pred_0_jalr_target !== i_io_out_s2_full_pred_0_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_jalr_target g=%h i=%h", $time, g_io_out_s2_full_pred_0_jalr_target, i_io_out_s2_full_pred_0_jalr_target); end
    if (g_io_out_s2_full_pred_0_offsets_0 !== i_io_out_s2_full_pred_0_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_offsets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_0_offsets_0, i_io_out_s2_full_pred_0_offsets_0); end
    if (g_io_out_s2_full_pred_0_offsets_1 !== i_io_out_s2_full_pred_0_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_offsets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_0_offsets_1, i_io_out_s2_full_pred_0_offsets_1); end
    if (g_io_out_s2_full_pred_0_fallThroughAddr !== i_io_out_s2_full_pred_0_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_fallThroughAddr g=%h i=%h", $time, g_io_out_s2_full_pred_0_fallThroughAddr, i_io_out_s2_full_pred_0_fallThroughAddr); end
    if (g_io_out_s2_full_pred_0_fallThroughErr !== i_io_out_s2_full_pred_0_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_fallThroughErr g=%h i=%h", $time, g_io_out_s2_full_pred_0_fallThroughErr, i_io_out_s2_full_pred_0_fallThroughErr); end
    if (g_io_out_s2_full_pred_0_is_jal !== i_io_out_s2_full_pred_0_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_is_jal g=%h i=%h", $time, g_io_out_s2_full_pred_0_is_jal, i_io_out_s2_full_pred_0_is_jal); end
    if (g_io_out_s2_full_pred_0_is_jalr !== i_io_out_s2_full_pred_0_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_is_jalr g=%h i=%h", $time, g_io_out_s2_full_pred_0_is_jalr, i_io_out_s2_full_pred_0_is_jalr); end
    if (g_io_out_s2_full_pred_0_is_call !== i_io_out_s2_full_pred_0_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_is_call g=%h i=%h", $time, g_io_out_s2_full_pred_0_is_call, i_io_out_s2_full_pred_0_is_call); end
    if (g_io_out_s2_full_pred_0_is_ret !== i_io_out_s2_full_pred_0_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_is_ret g=%h i=%h", $time, g_io_out_s2_full_pred_0_is_ret, i_io_out_s2_full_pred_0_is_ret); end
    if (g_io_out_s2_full_pred_0_last_may_be_rvi_call !== i_io_out_s2_full_pred_0_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s2_full_pred_0_last_may_be_rvi_call, i_io_out_s2_full_pred_0_last_may_be_rvi_call); end
    if (g_io_out_s2_full_pred_0_is_br_sharing !== i_io_out_s2_full_pred_0_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_is_br_sharing g=%h i=%h", $time, g_io_out_s2_full_pred_0_is_br_sharing, i_io_out_s2_full_pred_0_is_br_sharing); end
    if (g_io_out_s2_full_pred_0_hit !== i_io_out_s2_full_pred_0_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_0_hit g=%h i=%h", $time, g_io_out_s2_full_pred_0_hit, i_io_out_s2_full_pred_0_hit); end
    if (g_io_out_s2_full_pred_1_br_taken_mask_0 !== i_io_out_s2_full_pred_1_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s2_full_pred_1_br_taken_mask_0, i_io_out_s2_full_pred_1_br_taken_mask_0); end
    if (g_io_out_s2_full_pred_1_br_taken_mask_1 !== i_io_out_s2_full_pred_1_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s2_full_pred_1_br_taken_mask_1, i_io_out_s2_full_pred_1_br_taken_mask_1); end
    if (g_io_out_s2_full_pred_1_slot_valids_0 !== i_io_out_s2_full_pred_1_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_slot_valids_0 g=%h i=%h", $time, g_io_out_s2_full_pred_1_slot_valids_0, i_io_out_s2_full_pred_1_slot_valids_0); end
    if (g_io_out_s2_full_pred_1_slot_valids_1 !== i_io_out_s2_full_pred_1_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_slot_valids_1 g=%h i=%h", $time, g_io_out_s2_full_pred_1_slot_valids_1, i_io_out_s2_full_pred_1_slot_valids_1); end
    if (g_io_out_s2_full_pred_1_targets_0 !== i_io_out_s2_full_pred_1_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_targets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_1_targets_0, i_io_out_s2_full_pred_1_targets_0); end
    if (g_io_out_s2_full_pred_1_targets_1 !== i_io_out_s2_full_pred_1_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_targets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_1_targets_1, i_io_out_s2_full_pred_1_targets_1); end
    if (g_io_out_s2_full_pred_1_jalr_target !== i_io_out_s2_full_pred_1_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_jalr_target g=%h i=%h", $time, g_io_out_s2_full_pred_1_jalr_target, i_io_out_s2_full_pred_1_jalr_target); end
    if (g_io_out_s2_full_pred_1_offsets_0 !== i_io_out_s2_full_pred_1_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_offsets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_1_offsets_0, i_io_out_s2_full_pred_1_offsets_0); end
    if (g_io_out_s2_full_pred_1_offsets_1 !== i_io_out_s2_full_pred_1_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_offsets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_1_offsets_1, i_io_out_s2_full_pred_1_offsets_1); end
    if (g_io_out_s2_full_pred_1_fallThroughAddr !== i_io_out_s2_full_pred_1_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_fallThroughAddr g=%h i=%h", $time, g_io_out_s2_full_pred_1_fallThroughAddr, i_io_out_s2_full_pred_1_fallThroughAddr); end
    if (g_io_out_s2_full_pred_1_fallThroughErr !== i_io_out_s2_full_pred_1_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_fallThroughErr g=%h i=%h", $time, g_io_out_s2_full_pred_1_fallThroughErr, i_io_out_s2_full_pred_1_fallThroughErr); end
    if (g_io_out_s2_full_pred_1_is_jal !== i_io_out_s2_full_pred_1_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_is_jal g=%h i=%h", $time, g_io_out_s2_full_pred_1_is_jal, i_io_out_s2_full_pred_1_is_jal); end
    if (g_io_out_s2_full_pred_1_is_jalr !== i_io_out_s2_full_pred_1_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_is_jalr g=%h i=%h", $time, g_io_out_s2_full_pred_1_is_jalr, i_io_out_s2_full_pred_1_is_jalr); end
    if (g_io_out_s2_full_pred_1_is_call !== i_io_out_s2_full_pred_1_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_is_call g=%h i=%h", $time, g_io_out_s2_full_pred_1_is_call, i_io_out_s2_full_pred_1_is_call); end
    if (g_io_out_s2_full_pred_1_is_ret !== i_io_out_s2_full_pred_1_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_is_ret g=%h i=%h", $time, g_io_out_s2_full_pred_1_is_ret, i_io_out_s2_full_pred_1_is_ret); end
    if (g_io_out_s2_full_pred_1_last_may_be_rvi_call !== i_io_out_s2_full_pred_1_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s2_full_pred_1_last_may_be_rvi_call, i_io_out_s2_full_pred_1_last_may_be_rvi_call); end
    if (g_io_out_s2_full_pred_1_is_br_sharing !== i_io_out_s2_full_pred_1_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_is_br_sharing g=%h i=%h", $time, g_io_out_s2_full_pred_1_is_br_sharing, i_io_out_s2_full_pred_1_is_br_sharing); end
    if (g_io_out_s2_full_pred_1_hit !== i_io_out_s2_full_pred_1_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_1_hit g=%h i=%h", $time, g_io_out_s2_full_pred_1_hit, i_io_out_s2_full_pred_1_hit); end
    if (g_io_out_s2_full_pred_2_br_taken_mask_0 !== i_io_out_s2_full_pred_2_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s2_full_pred_2_br_taken_mask_0, i_io_out_s2_full_pred_2_br_taken_mask_0); end
    if (g_io_out_s2_full_pred_2_br_taken_mask_1 !== i_io_out_s2_full_pred_2_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s2_full_pred_2_br_taken_mask_1, i_io_out_s2_full_pred_2_br_taken_mask_1); end
    if (g_io_out_s2_full_pred_2_slot_valids_0 !== i_io_out_s2_full_pred_2_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_slot_valids_0 g=%h i=%h", $time, g_io_out_s2_full_pred_2_slot_valids_0, i_io_out_s2_full_pred_2_slot_valids_0); end
    if (g_io_out_s2_full_pred_2_slot_valids_1 !== i_io_out_s2_full_pred_2_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_slot_valids_1 g=%h i=%h", $time, g_io_out_s2_full_pred_2_slot_valids_1, i_io_out_s2_full_pred_2_slot_valids_1); end
    if (g_io_out_s2_full_pred_2_targets_0 !== i_io_out_s2_full_pred_2_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_targets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_2_targets_0, i_io_out_s2_full_pred_2_targets_0); end
    if (g_io_out_s2_full_pred_2_targets_1 !== i_io_out_s2_full_pred_2_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_targets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_2_targets_1, i_io_out_s2_full_pred_2_targets_1); end
    if (g_io_out_s2_full_pred_2_jalr_target !== i_io_out_s2_full_pred_2_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_jalr_target g=%h i=%h", $time, g_io_out_s2_full_pred_2_jalr_target, i_io_out_s2_full_pred_2_jalr_target); end
    if (g_io_out_s2_full_pred_2_offsets_0 !== i_io_out_s2_full_pred_2_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_offsets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_2_offsets_0, i_io_out_s2_full_pred_2_offsets_0); end
    if (g_io_out_s2_full_pred_2_offsets_1 !== i_io_out_s2_full_pred_2_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_offsets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_2_offsets_1, i_io_out_s2_full_pred_2_offsets_1); end
    if (g_io_out_s2_full_pred_2_fallThroughAddr !== i_io_out_s2_full_pred_2_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_fallThroughAddr g=%h i=%h", $time, g_io_out_s2_full_pred_2_fallThroughAddr, i_io_out_s2_full_pred_2_fallThroughAddr); end
    if (g_io_out_s2_full_pred_2_fallThroughErr !== i_io_out_s2_full_pred_2_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_fallThroughErr g=%h i=%h", $time, g_io_out_s2_full_pred_2_fallThroughErr, i_io_out_s2_full_pred_2_fallThroughErr); end
    if (g_io_out_s2_full_pred_2_is_jal !== i_io_out_s2_full_pred_2_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_is_jal g=%h i=%h", $time, g_io_out_s2_full_pred_2_is_jal, i_io_out_s2_full_pred_2_is_jal); end
    if (g_io_out_s2_full_pred_2_is_jalr !== i_io_out_s2_full_pred_2_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_is_jalr g=%h i=%h", $time, g_io_out_s2_full_pred_2_is_jalr, i_io_out_s2_full_pred_2_is_jalr); end
    if (g_io_out_s2_full_pred_2_is_call !== i_io_out_s2_full_pred_2_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_is_call g=%h i=%h", $time, g_io_out_s2_full_pred_2_is_call, i_io_out_s2_full_pred_2_is_call); end
    if (g_io_out_s2_full_pred_2_is_ret !== i_io_out_s2_full_pred_2_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_is_ret g=%h i=%h", $time, g_io_out_s2_full_pred_2_is_ret, i_io_out_s2_full_pred_2_is_ret); end
    if (g_io_out_s2_full_pred_2_last_may_be_rvi_call !== i_io_out_s2_full_pred_2_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s2_full_pred_2_last_may_be_rvi_call, i_io_out_s2_full_pred_2_last_may_be_rvi_call); end
    if (g_io_out_s2_full_pred_2_is_br_sharing !== i_io_out_s2_full_pred_2_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_is_br_sharing g=%h i=%h", $time, g_io_out_s2_full_pred_2_is_br_sharing, i_io_out_s2_full_pred_2_is_br_sharing); end
    if (g_io_out_s2_full_pred_2_hit !== i_io_out_s2_full_pred_2_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_2_hit g=%h i=%h", $time, g_io_out_s2_full_pred_2_hit, i_io_out_s2_full_pred_2_hit); end
    if (g_io_out_s2_full_pred_3_br_taken_mask_0 !== i_io_out_s2_full_pred_3_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s2_full_pred_3_br_taken_mask_0, i_io_out_s2_full_pred_3_br_taken_mask_0); end
    if (g_io_out_s2_full_pred_3_br_taken_mask_1 !== i_io_out_s2_full_pred_3_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s2_full_pred_3_br_taken_mask_1, i_io_out_s2_full_pred_3_br_taken_mask_1); end
    if (g_io_out_s2_full_pred_3_slot_valids_0 !== i_io_out_s2_full_pred_3_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_out_s2_full_pred_3_slot_valids_0, i_io_out_s2_full_pred_3_slot_valids_0); end
    if (g_io_out_s2_full_pred_3_slot_valids_1 !== i_io_out_s2_full_pred_3_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_out_s2_full_pred_3_slot_valids_1, i_io_out_s2_full_pred_3_slot_valids_1); end
    if (g_io_out_s2_full_pred_3_targets_0 !== i_io_out_s2_full_pred_3_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_targets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_3_targets_0, i_io_out_s2_full_pred_3_targets_0); end
    if (g_io_out_s2_full_pred_3_targets_1 !== i_io_out_s2_full_pred_3_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_targets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_3_targets_1, i_io_out_s2_full_pred_3_targets_1); end
    if (g_io_out_s2_full_pred_3_jalr_target !== i_io_out_s2_full_pred_3_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_jalr_target g=%h i=%h", $time, g_io_out_s2_full_pred_3_jalr_target, i_io_out_s2_full_pred_3_jalr_target); end
    if (g_io_out_s2_full_pred_3_offsets_0 !== i_io_out_s2_full_pred_3_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_out_s2_full_pred_3_offsets_0, i_io_out_s2_full_pred_3_offsets_0); end
    if (g_io_out_s2_full_pred_3_offsets_1 !== i_io_out_s2_full_pred_3_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_out_s2_full_pred_3_offsets_1, i_io_out_s2_full_pred_3_offsets_1); end
    if (g_io_out_s2_full_pred_3_fallThroughAddr !== i_io_out_s2_full_pred_3_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_out_s2_full_pred_3_fallThroughAddr, i_io_out_s2_full_pred_3_fallThroughAddr); end
    if (g_io_out_s2_full_pred_3_fallThroughErr !== i_io_out_s2_full_pred_3_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_out_s2_full_pred_3_fallThroughErr, i_io_out_s2_full_pred_3_fallThroughErr); end
    if (g_io_out_s2_full_pred_3_is_jal !== i_io_out_s2_full_pred_3_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_is_jal g=%h i=%h", $time, g_io_out_s2_full_pred_3_is_jal, i_io_out_s2_full_pred_3_is_jal); end
    if (g_io_out_s2_full_pred_3_is_jalr !== i_io_out_s2_full_pred_3_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_is_jalr g=%h i=%h", $time, g_io_out_s2_full_pred_3_is_jalr, i_io_out_s2_full_pred_3_is_jalr); end
    if (g_io_out_s2_full_pred_3_is_call !== i_io_out_s2_full_pred_3_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_is_call g=%h i=%h", $time, g_io_out_s2_full_pred_3_is_call, i_io_out_s2_full_pred_3_is_call); end
    if (g_io_out_s2_full_pred_3_is_ret !== i_io_out_s2_full_pred_3_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_is_ret g=%h i=%h", $time, g_io_out_s2_full_pred_3_is_ret, i_io_out_s2_full_pred_3_is_ret); end
    if (g_io_out_s2_full_pred_3_last_may_be_rvi_call !== i_io_out_s2_full_pred_3_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s2_full_pred_3_last_may_be_rvi_call, i_io_out_s2_full_pred_3_last_may_be_rvi_call); end
    if (g_io_out_s2_full_pred_3_is_br_sharing !== i_io_out_s2_full_pred_3_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_out_s2_full_pred_3_is_br_sharing, i_io_out_s2_full_pred_3_is_br_sharing); end
    if (g_io_out_s2_full_pred_3_hit !== i_io_out_s2_full_pred_3_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s2_full_pred_3_hit g=%h i=%h", $time, g_io_out_s2_full_pred_3_hit, i_io_out_s2_full_pred_3_hit); end
    if (g_io_out_s3_pc_0 !== i_io_out_s3_pc_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_pc_0 g=%h i=%h", $time, g_io_out_s3_pc_0, i_io_out_s3_pc_0); end
    if (g_io_out_s3_pc_1 !== i_io_out_s3_pc_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_pc_1 g=%h i=%h", $time, g_io_out_s3_pc_1, i_io_out_s3_pc_1); end
    if (g_io_out_s3_pc_2 !== i_io_out_s3_pc_2) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_pc_2 g=%h i=%h", $time, g_io_out_s3_pc_2, i_io_out_s3_pc_2); end
    if (g_io_out_s3_pc_3 !== i_io_out_s3_pc_3) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_pc_3 g=%h i=%h", $time, g_io_out_s3_pc_3, i_io_out_s3_pc_3); end
    if (g_io_out_s3_full_pred_0_br_taken_mask_0 !== i_io_out_s3_full_pred_0_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s3_full_pred_0_br_taken_mask_0, i_io_out_s3_full_pred_0_br_taken_mask_0); end
    if (g_io_out_s3_full_pred_0_br_taken_mask_1 !== i_io_out_s3_full_pred_0_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s3_full_pred_0_br_taken_mask_1, i_io_out_s3_full_pred_0_br_taken_mask_1); end
    if (g_io_out_s3_full_pred_0_slot_valids_0 !== i_io_out_s3_full_pred_0_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_slot_valids_0 g=%h i=%h", $time, g_io_out_s3_full_pred_0_slot_valids_0, i_io_out_s3_full_pred_0_slot_valids_0); end
    if (g_io_out_s3_full_pred_0_slot_valids_1 !== i_io_out_s3_full_pred_0_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_slot_valids_1 g=%h i=%h", $time, g_io_out_s3_full_pred_0_slot_valids_1, i_io_out_s3_full_pred_0_slot_valids_1); end
    if (g_io_out_s3_full_pred_0_targets_0 !== i_io_out_s3_full_pred_0_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_targets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_0_targets_0, i_io_out_s3_full_pred_0_targets_0); end
    if (g_io_out_s3_full_pred_0_targets_1 !== i_io_out_s3_full_pred_0_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_targets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_0_targets_1, i_io_out_s3_full_pred_0_targets_1); end
    if (g_io_out_s3_full_pred_0_jalr_target !== i_io_out_s3_full_pred_0_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_jalr_target g=%h i=%h", $time, g_io_out_s3_full_pred_0_jalr_target, i_io_out_s3_full_pred_0_jalr_target); end
    if (g_io_out_s3_full_pred_0_offsets_0 !== i_io_out_s3_full_pred_0_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_offsets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_0_offsets_0, i_io_out_s3_full_pred_0_offsets_0); end
    if (g_io_out_s3_full_pred_0_offsets_1 !== i_io_out_s3_full_pred_0_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_offsets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_0_offsets_1, i_io_out_s3_full_pred_0_offsets_1); end
    if (g_io_out_s3_full_pred_0_fallThroughAddr !== i_io_out_s3_full_pred_0_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_fallThroughAddr g=%h i=%h", $time, g_io_out_s3_full_pred_0_fallThroughAddr, i_io_out_s3_full_pred_0_fallThroughAddr); end
    if (g_io_out_s3_full_pred_0_fallThroughErr !== i_io_out_s3_full_pred_0_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_fallThroughErr g=%h i=%h", $time, g_io_out_s3_full_pred_0_fallThroughErr, i_io_out_s3_full_pred_0_fallThroughErr); end
    if (g_io_out_s3_full_pred_0_multiHit !== i_io_out_s3_full_pred_0_multiHit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_multiHit g=%h i=%h", $time, g_io_out_s3_full_pred_0_multiHit, i_io_out_s3_full_pred_0_multiHit); end
    if (g_io_out_s3_full_pred_0_is_jal !== i_io_out_s3_full_pred_0_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_is_jal g=%h i=%h", $time, g_io_out_s3_full_pred_0_is_jal, i_io_out_s3_full_pred_0_is_jal); end
    if (g_io_out_s3_full_pred_0_is_jalr !== i_io_out_s3_full_pred_0_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_is_jalr g=%h i=%h", $time, g_io_out_s3_full_pred_0_is_jalr, i_io_out_s3_full_pred_0_is_jalr); end
    if (g_io_out_s3_full_pred_0_is_call !== i_io_out_s3_full_pred_0_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_is_call g=%h i=%h", $time, g_io_out_s3_full_pred_0_is_call, i_io_out_s3_full_pred_0_is_call); end
    if (g_io_out_s3_full_pred_0_is_ret !== i_io_out_s3_full_pred_0_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_is_ret g=%h i=%h", $time, g_io_out_s3_full_pred_0_is_ret, i_io_out_s3_full_pred_0_is_ret); end
    if (g_io_out_s3_full_pred_0_last_may_be_rvi_call !== i_io_out_s3_full_pred_0_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s3_full_pred_0_last_may_be_rvi_call, i_io_out_s3_full_pred_0_last_may_be_rvi_call); end
    if (g_io_out_s3_full_pred_0_is_br_sharing !== i_io_out_s3_full_pred_0_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_is_br_sharing g=%h i=%h", $time, g_io_out_s3_full_pred_0_is_br_sharing, i_io_out_s3_full_pred_0_is_br_sharing); end
    if (g_io_out_s3_full_pred_0_hit !== i_io_out_s3_full_pred_0_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_0_hit g=%h i=%h", $time, g_io_out_s3_full_pred_0_hit, i_io_out_s3_full_pred_0_hit); end
    if (g_io_out_s3_full_pred_1_br_taken_mask_0 !== i_io_out_s3_full_pred_1_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s3_full_pred_1_br_taken_mask_0, i_io_out_s3_full_pred_1_br_taken_mask_0); end
    if (g_io_out_s3_full_pred_1_br_taken_mask_1 !== i_io_out_s3_full_pred_1_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s3_full_pred_1_br_taken_mask_1, i_io_out_s3_full_pred_1_br_taken_mask_1); end
    if (g_io_out_s3_full_pred_1_slot_valids_0 !== i_io_out_s3_full_pred_1_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_slot_valids_0 g=%h i=%h", $time, g_io_out_s3_full_pred_1_slot_valids_0, i_io_out_s3_full_pred_1_slot_valids_0); end
    if (g_io_out_s3_full_pred_1_slot_valids_1 !== i_io_out_s3_full_pred_1_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_slot_valids_1 g=%h i=%h", $time, g_io_out_s3_full_pred_1_slot_valids_1, i_io_out_s3_full_pred_1_slot_valids_1); end
    if (g_io_out_s3_full_pred_1_targets_0 !== i_io_out_s3_full_pred_1_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_targets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_1_targets_0, i_io_out_s3_full_pred_1_targets_0); end
    if (g_io_out_s3_full_pred_1_targets_1 !== i_io_out_s3_full_pred_1_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_targets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_1_targets_1, i_io_out_s3_full_pred_1_targets_1); end
    if (g_io_out_s3_full_pred_1_jalr_target !== i_io_out_s3_full_pred_1_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_jalr_target g=%h i=%h", $time, g_io_out_s3_full_pred_1_jalr_target, i_io_out_s3_full_pred_1_jalr_target); end
    if (g_io_out_s3_full_pred_1_offsets_0 !== i_io_out_s3_full_pred_1_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_offsets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_1_offsets_0, i_io_out_s3_full_pred_1_offsets_0); end
    if (g_io_out_s3_full_pred_1_offsets_1 !== i_io_out_s3_full_pred_1_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_offsets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_1_offsets_1, i_io_out_s3_full_pred_1_offsets_1); end
    if (g_io_out_s3_full_pred_1_fallThroughAddr !== i_io_out_s3_full_pred_1_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_fallThroughAddr g=%h i=%h", $time, g_io_out_s3_full_pred_1_fallThroughAddr, i_io_out_s3_full_pred_1_fallThroughAddr); end
    if (g_io_out_s3_full_pred_1_fallThroughErr !== i_io_out_s3_full_pred_1_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_fallThroughErr g=%h i=%h", $time, g_io_out_s3_full_pred_1_fallThroughErr, i_io_out_s3_full_pred_1_fallThroughErr); end
    if (g_io_out_s3_full_pred_1_multiHit !== i_io_out_s3_full_pred_1_multiHit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_multiHit g=%h i=%h", $time, g_io_out_s3_full_pred_1_multiHit, i_io_out_s3_full_pred_1_multiHit); end
    if (g_io_out_s3_full_pred_1_is_jal !== i_io_out_s3_full_pred_1_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_is_jal g=%h i=%h", $time, g_io_out_s3_full_pred_1_is_jal, i_io_out_s3_full_pred_1_is_jal); end
    if (g_io_out_s3_full_pred_1_is_jalr !== i_io_out_s3_full_pred_1_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_is_jalr g=%h i=%h", $time, g_io_out_s3_full_pred_1_is_jalr, i_io_out_s3_full_pred_1_is_jalr); end
    if (g_io_out_s3_full_pred_1_is_call !== i_io_out_s3_full_pred_1_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_is_call g=%h i=%h", $time, g_io_out_s3_full_pred_1_is_call, i_io_out_s3_full_pred_1_is_call); end
    if (g_io_out_s3_full_pred_1_is_ret !== i_io_out_s3_full_pred_1_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_is_ret g=%h i=%h", $time, g_io_out_s3_full_pred_1_is_ret, i_io_out_s3_full_pred_1_is_ret); end
    if (g_io_out_s3_full_pred_1_last_may_be_rvi_call !== i_io_out_s3_full_pred_1_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s3_full_pred_1_last_may_be_rvi_call, i_io_out_s3_full_pred_1_last_may_be_rvi_call); end
    if (g_io_out_s3_full_pred_1_is_br_sharing !== i_io_out_s3_full_pred_1_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_is_br_sharing g=%h i=%h", $time, g_io_out_s3_full_pred_1_is_br_sharing, i_io_out_s3_full_pred_1_is_br_sharing); end
    if (g_io_out_s3_full_pred_1_hit !== i_io_out_s3_full_pred_1_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_1_hit g=%h i=%h", $time, g_io_out_s3_full_pred_1_hit, i_io_out_s3_full_pred_1_hit); end
    if (g_io_out_s3_full_pred_2_br_taken_mask_0 !== i_io_out_s3_full_pred_2_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s3_full_pred_2_br_taken_mask_0, i_io_out_s3_full_pred_2_br_taken_mask_0); end
    if (g_io_out_s3_full_pred_2_br_taken_mask_1 !== i_io_out_s3_full_pred_2_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s3_full_pred_2_br_taken_mask_1, i_io_out_s3_full_pred_2_br_taken_mask_1); end
    if (g_io_out_s3_full_pred_2_slot_valids_0 !== i_io_out_s3_full_pred_2_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_slot_valids_0 g=%h i=%h", $time, g_io_out_s3_full_pred_2_slot_valids_0, i_io_out_s3_full_pred_2_slot_valids_0); end
    if (g_io_out_s3_full_pred_2_slot_valids_1 !== i_io_out_s3_full_pred_2_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_slot_valids_1 g=%h i=%h", $time, g_io_out_s3_full_pred_2_slot_valids_1, i_io_out_s3_full_pred_2_slot_valids_1); end
    if (g_io_out_s3_full_pred_2_targets_0 !== i_io_out_s3_full_pred_2_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_targets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_2_targets_0, i_io_out_s3_full_pred_2_targets_0); end
    if (g_io_out_s3_full_pred_2_targets_1 !== i_io_out_s3_full_pred_2_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_targets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_2_targets_1, i_io_out_s3_full_pred_2_targets_1); end
    if (g_io_out_s3_full_pred_2_jalr_target !== i_io_out_s3_full_pred_2_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_jalr_target g=%h i=%h", $time, g_io_out_s3_full_pred_2_jalr_target, i_io_out_s3_full_pred_2_jalr_target); end
    if (g_io_out_s3_full_pred_2_offsets_0 !== i_io_out_s3_full_pred_2_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_offsets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_2_offsets_0, i_io_out_s3_full_pred_2_offsets_0); end
    if (g_io_out_s3_full_pred_2_offsets_1 !== i_io_out_s3_full_pred_2_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_offsets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_2_offsets_1, i_io_out_s3_full_pred_2_offsets_1); end
    if (g_io_out_s3_full_pred_2_fallThroughAddr !== i_io_out_s3_full_pred_2_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_fallThroughAddr g=%h i=%h", $time, g_io_out_s3_full_pred_2_fallThroughAddr, i_io_out_s3_full_pred_2_fallThroughAddr); end
    if (g_io_out_s3_full_pred_2_fallThroughErr !== i_io_out_s3_full_pred_2_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_fallThroughErr g=%h i=%h", $time, g_io_out_s3_full_pred_2_fallThroughErr, i_io_out_s3_full_pred_2_fallThroughErr); end
    if (g_io_out_s3_full_pred_2_multiHit !== i_io_out_s3_full_pred_2_multiHit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_multiHit g=%h i=%h", $time, g_io_out_s3_full_pred_2_multiHit, i_io_out_s3_full_pred_2_multiHit); end
    if (g_io_out_s3_full_pred_2_is_jal !== i_io_out_s3_full_pred_2_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_is_jal g=%h i=%h", $time, g_io_out_s3_full_pred_2_is_jal, i_io_out_s3_full_pred_2_is_jal); end
    if (g_io_out_s3_full_pred_2_is_jalr !== i_io_out_s3_full_pred_2_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_is_jalr g=%h i=%h", $time, g_io_out_s3_full_pred_2_is_jalr, i_io_out_s3_full_pred_2_is_jalr); end
    if (g_io_out_s3_full_pred_2_is_call !== i_io_out_s3_full_pred_2_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_is_call g=%h i=%h", $time, g_io_out_s3_full_pred_2_is_call, i_io_out_s3_full_pred_2_is_call); end
    if (g_io_out_s3_full_pred_2_is_ret !== i_io_out_s3_full_pred_2_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_is_ret g=%h i=%h", $time, g_io_out_s3_full_pred_2_is_ret, i_io_out_s3_full_pred_2_is_ret); end
    if (g_io_out_s3_full_pred_2_last_may_be_rvi_call !== i_io_out_s3_full_pred_2_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s3_full_pred_2_last_may_be_rvi_call, i_io_out_s3_full_pred_2_last_may_be_rvi_call); end
    if (g_io_out_s3_full_pred_2_is_br_sharing !== i_io_out_s3_full_pred_2_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_is_br_sharing g=%h i=%h", $time, g_io_out_s3_full_pred_2_is_br_sharing, i_io_out_s3_full_pred_2_is_br_sharing); end
    if (g_io_out_s3_full_pred_2_hit !== i_io_out_s3_full_pred_2_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_2_hit g=%h i=%h", $time, g_io_out_s3_full_pred_2_hit, i_io_out_s3_full_pred_2_hit); end
    if (g_io_out_s3_full_pred_3_br_taken_mask_0 !== i_io_out_s3_full_pred_3_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s3_full_pred_3_br_taken_mask_0, i_io_out_s3_full_pred_3_br_taken_mask_0); end
    if (g_io_out_s3_full_pred_3_br_taken_mask_1 !== i_io_out_s3_full_pred_3_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s3_full_pred_3_br_taken_mask_1, i_io_out_s3_full_pred_3_br_taken_mask_1); end
    if (g_io_out_s3_full_pred_3_slot_valids_0 !== i_io_out_s3_full_pred_3_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_out_s3_full_pred_3_slot_valids_0, i_io_out_s3_full_pred_3_slot_valids_0); end
    if (g_io_out_s3_full_pred_3_slot_valids_1 !== i_io_out_s3_full_pred_3_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_out_s3_full_pred_3_slot_valids_1, i_io_out_s3_full_pred_3_slot_valids_1); end
    if (g_io_out_s3_full_pred_3_targets_0 !== i_io_out_s3_full_pred_3_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_targets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_3_targets_0, i_io_out_s3_full_pred_3_targets_0); end
    if (g_io_out_s3_full_pred_3_targets_1 !== i_io_out_s3_full_pred_3_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_targets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_3_targets_1, i_io_out_s3_full_pred_3_targets_1); end
    if (g_io_out_s3_full_pred_3_jalr_target !== i_io_out_s3_full_pred_3_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_jalr_target g=%h i=%h", $time, g_io_out_s3_full_pred_3_jalr_target, i_io_out_s3_full_pred_3_jalr_target); end
    if (g_io_out_s3_full_pred_3_offsets_0 !== i_io_out_s3_full_pred_3_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_out_s3_full_pred_3_offsets_0, i_io_out_s3_full_pred_3_offsets_0); end
    if (g_io_out_s3_full_pred_3_offsets_1 !== i_io_out_s3_full_pred_3_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_out_s3_full_pred_3_offsets_1, i_io_out_s3_full_pred_3_offsets_1); end
    if (g_io_out_s3_full_pred_3_fallThroughAddr !== i_io_out_s3_full_pred_3_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_out_s3_full_pred_3_fallThroughAddr, i_io_out_s3_full_pred_3_fallThroughAddr); end
    if (g_io_out_s3_full_pred_3_fallThroughErr !== i_io_out_s3_full_pred_3_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_out_s3_full_pred_3_fallThroughErr, i_io_out_s3_full_pred_3_fallThroughErr); end
    if (g_io_out_s3_full_pred_3_multiHit !== i_io_out_s3_full_pred_3_multiHit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_multiHit g=%h i=%h", $time, g_io_out_s3_full_pred_3_multiHit, i_io_out_s3_full_pred_3_multiHit); end
    if (g_io_out_s3_full_pred_3_is_jal !== i_io_out_s3_full_pred_3_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_is_jal g=%h i=%h", $time, g_io_out_s3_full_pred_3_is_jal, i_io_out_s3_full_pred_3_is_jal); end
    if (g_io_out_s3_full_pred_3_is_jalr !== i_io_out_s3_full_pred_3_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_is_jalr g=%h i=%h", $time, g_io_out_s3_full_pred_3_is_jalr, i_io_out_s3_full_pred_3_is_jalr); end
    if (g_io_out_s3_full_pred_3_is_call !== i_io_out_s3_full_pred_3_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_is_call g=%h i=%h", $time, g_io_out_s3_full_pred_3_is_call, i_io_out_s3_full_pred_3_is_call); end
    if (g_io_out_s3_full_pred_3_is_ret !== i_io_out_s3_full_pred_3_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_is_ret g=%h i=%h", $time, g_io_out_s3_full_pred_3_is_ret, i_io_out_s3_full_pred_3_is_ret); end
    if (g_io_out_s3_full_pred_3_last_may_be_rvi_call !== i_io_out_s3_full_pred_3_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s3_full_pred_3_last_may_be_rvi_call, i_io_out_s3_full_pred_3_last_may_be_rvi_call); end
    if (g_io_out_s3_full_pred_3_is_br_sharing !== i_io_out_s3_full_pred_3_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_out_s3_full_pred_3_is_br_sharing, i_io_out_s3_full_pred_3_is_br_sharing); end
    if (g_io_out_s3_full_pred_3_hit !== i_io_out_s3_full_pred_3_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s3_full_pred_3_hit g=%h i=%h", $time, g_io_out_s3_full_pred_3_hit, i_io_out_s3_full_pred_3_hit); end
    if (g_io_out_last_stage_meta !== i_io_out_last_stage_meta) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_meta g=%h i=%h", $time, g_io_out_last_stage_meta, i_io_out_last_stage_meta); end
    if (g_io_out_last_stage_spec_info_ssp !== i_io_out_last_stage_spec_info_ssp) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_ssp g=%h i=%h", $time, g_io_out_last_stage_spec_info_ssp, i_io_out_last_stage_spec_info_ssp); end
    if (g_io_out_last_stage_spec_info_sctr !== i_io_out_last_stage_spec_info_sctr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_sctr g=%h i=%h", $time, g_io_out_last_stage_spec_info_sctr, i_io_out_last_stage_spec_info_sctr); end
    if (g_io_out_last_stage_spec_info_TOSW_flag !== i_io_out_last_stage_spec_info_TOSW_flag) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_TOSW_flag g=%h i=%h", $time, g_io_out_last_stage_spec_info_TOSW_flag, i_io_out_last_stage_spec_info_TOSW_flag); end
    if (g_io_out_last_stage_spec_info_TOSW_value !== i_io_out_last_stage_spec_info_TOSW_value) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_TOSW_value g=%h i=%h", $time, g_io_out_last_stage_spec_info_TOSW_value, i_io_out_last_stage_spec_info_TOSW_value); end
    if (g_io_out_last_stage_spec_info_TOSR_flag !== i_io_out_last_stage_spec_info_TOSR_flag) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_TOSR_flag g=%h i=%h", $time, g_io_out_last_stage_spec_info_TOSR_flag, i_io_out_last_stage_spec_info_TOSR_flag); end
    if (g_io_out_last_stage_spec_info_TOSR_value !== i_io_out_last_stage_spec_info_TOSR_value) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_TOSR_value g=%h i=%h", $time, g_io_out_last_stage_spec_info_TOSR_value, i_io_out_last_stage_spec_info_TOSR_value); end
    if (g_io_out_last_stage_spec_info_NOS_flag !== i_io_out_last_stage_spec_info_NOS_flag) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_NOS_flag g=%h i=%h", $time, g_io_out_last_stage_spec_info_NOS_flag, i_io_out_last_stage_spec_info_NOS_flag); end
    if (g_io_out_last_stage_spec_info_NOS_value !== i_io_out_last_stage_spec_info_NOS_value) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_NOS_value g=%h i=%h", $time, g_io_out_last_stage_spec_info_NOS_value, i_io_out_last_stage_spec_info_NOS_value); end
    if (g_io_out_last_stage_spec_info_topAddr !== i_io_out_last_stage_spec_info_topAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_topAddr g=%h i=%h", $time, g_io_out_last_stage_spec_info_topAddr, i_io_out_last_stage_spec_info_topAddr); end
    if (g_io_out_last_stage_spec_info_sc_disagree_0 !== i_io_out_last_stage_spec_info_sc_disagree_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_sc_disagree_0 g=%h i=%h", $time, g_io_out_last_stage_spec_info_sc_disagree_0, i_io_out_last_stage_spec_info_sc_disagree_0); end
    if (g_io_out_last_stage_spec_info_sc_disagree_1 !== i_io_out_last_stage_spec_info_sc_disagree_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_spec_info_sc_disagree_1 g=%h i=%h", $time, g_io_out_last_stage_spec_info_sc_disagree_1, i_io_out_last_stage_spec_info_sc_disagree_1); end
    if (g_io_out_last_stage_ftb_entry_isCall !== i_io_out_last_stage_ftb_entry_isCall) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_isCall g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_isCall, i_io_out_last_stage_ftb_entry_isCall); end
    if (g_io_out_last_stage_ftb_entry_isRet !== i_io_out_last_stage_ftb_entry_isRet) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_isRet g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_isRet, i_io_out_last_stage_ftb_entry_isRet); end
    if (g_io_out_last_stage_ftb_entry_isJalr !== i_io_out_last_stage_ftb_entry_isJalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_isJalr g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_isJalr, i_io_out_last_stage_ftb_entry_isJalr); end
    if (g_io_out_last_stage_ftb_entry_valid !== i_io_out_last_stage_ftb_entry_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_valid g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_valid, i_io_out_last_stage_ftb_entry_valid); end
    if (g_io_out_last_stage_ftb_entry_brSlots_0_offset !== i_io_out_last_stage_ftb_entry_brSlots_0_offset) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_brSlots_0_offset g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_brSlots_0_offset, i_io_out_last_stage_ftb_entry_brSlots_0_offset); end
    if (g_io_out_last_stage_ftb_entry_brSlots_0_sharing !== i_io_out_last_stage_ftb_entry_brSlots_0_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_brSlots_0_sharing g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_brSlots_0_sharing, i_io_out_last_stage_ftb_entry_brSlots_0_sharing); end
    if (g_io_out_last_stage_ftb_entry_brSlots_0_valid !== i_io_out_last_stage_ftb_entry_brSlots_0_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_brSlots_0_valid g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_brSlots_0_valid, i_io_out_last_stage_ftb_entry_brSlots_0_valid); end
    if (g_io_out_last_stage_ftb_entry_brSlots_0_lower !== i_io_out_last_stage_ftb_entry_brSlots_0_lower) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_brSlots_0_lower g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_brSlots_0_lower, i_io_out_last_stage_ftb_entry_brSlots_0_lower); end
    if (g_io_out_last_stage_ftb_entry_brSlots_0_tarStat !== i_io_out_last_stage_ftb_entry_brSlots_0_tarStat) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_brSlots_0_tarStat g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_brSlots_0_tarStat, i_io_out_last_stage_ftb_entry_brSlots_0_tarStat); end
    if (g_io_out_last_stage_ftb_entry_tailSlot_offset !== i_io_out_last_stage_ftb_entry_tailSlot_offset) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_tailSlot_offset g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_tailSlot_offset, i_io_out_last_stage_ftb_entry_tailSlot_offset); end
    if (g_io_out_last_stage_ftb_entry_tailSlot_sharing !== i_io_out_last_stage_ftb_entry_tailSlot_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_tailSlot_sharing g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_tailSlot_sharing, i_io_out_last_stage_ftb_entry_tailSlot_sharing); end
    if (g_io_out_last_stage_ftb_entry_tailSlot_valid !== i_io_out_last_stage_ftb_entry_tailSlot_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_tailSlot_valid g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_tailSlot_valid, i_io_out_last_stage_ftb_entry_tailSlot_valid); end
    if (g_io_out_last_stage_ftb_entry_tailSlot_lower !== i_io_out_last_stage_ftb_entry_tailSlot_lower) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_tailSlot_lower g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_tailSlot_lower, i_io_out_last_stage_ftb_entry_tailSlot_lower); end
    if (g_io_out_last_stage_ftb_entry_tailSlot_tarStat !== i_io_out_last_stage_ftb_entry_tailSlot_tarStat) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_tailSlot_tarStat g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_tailSlot_tarStat, i_io_out_last_stage_ftb_entry_tailSlot_tarStat); end
    if (g_io_out_last_stage_ftb_entry_pftAddr !== i_io_out_last_stage_ftb_entry_pftAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_pftAddr g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_pftAddr, i_io_out_last_stage_ftb_entry_pftAddr); end
    if (g_io_out_last_stage_ftb_entry_carry !== i_io_out_last_stage_ftb_entry_carry) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_carry g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_carry, i_io_out_last_stage_ftb_entry_carry); end
    if (g_io_out_last_stage_ftb_entry_last_may_be_rvi_call !== i_io_out_last_stage_ftb_entry_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_last_may_be_rvi_call, i_io_out_last_stage_ftb_entry_last_may_be_rvi_call); end
    if (g_io_out_last_stage_ftb_entry_strong_bias_0 !== i_io_out_last_stage_ftb_entry_strong_bias_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_strong_bias_0 g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_strong_bias_0, i_io_out_last_stage_ftb_entry_strong_bias_0); end
    if (g_io_out_last_stage_ftb_entry_strong_bias_1 !== i_io_out_last_stage_ftb_entry_strong_bias_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_ftb_entry_strong_bias_1 g=%h i=%h", $time, g_io_out_last_stage_ftb_entry_strong_bias_1, i_io_out_last_stage_ftb_entry_strong_bias_1); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
