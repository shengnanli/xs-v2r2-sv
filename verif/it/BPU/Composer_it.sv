// 自动生成：scripts/gen_composer.py —— 勿手改
// golden 同名 wrapper：例化 5 预测器 + 4 DelayN（逐字照搬 golden 连接）+ 可读核 xs_Composer_core。
module Composer_it(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
  input  [10:0] io_in_bits_folded_hist_1_hist_17_folded_hist,
  input  [10:0] io_in_bits_folded_hist_1_hist_16_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_15_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_14_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_9_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_8_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_7_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_5_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_4_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_3_folded_hist,
  input  [10:0] io_in_bits_folded_hist_1_hist_1_folded_hist,
  input  [3:0] io_in_bits_folded_hist_3_hist_12_folded_hist,
  input  [7:0] io_in_bits_folded_hist_3_hist_11_folded_hist,
  input  [7:0] io_in_bits_folded_hist_3_hist_2_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_14_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_13_folded_hist,
  input  [3:0] io_in_bits_s1_folded_hist_3_hist_12_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_10_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_6_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_4_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_3_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_2_folded_hist,
  input  [255:0] io_in_bits_ghist,
  output [49:0] io_out_s1_pc_0,
  output [49:0] io_out_s1_pc_1,
  output [49:0] io_out_s1_pc_2,
  output [49:0] io_out_s1_pc_3,
  output io_out_s1_full_pred_0_br_taken_mask_0,
  output io_out_s1_full_pred_0_br_taken_mask_1,
  output io_out_s1_full_pred_0_slot_valids_0,
  output io_out_s1_full_pred_0_slot_valids_1,
  output [49:0] io_out_s1_full_pred_0_targets_0,
  output [49:0] io_out_s1_full_pred_0_targets_1,
  output [49:0] io_out_s1_full_pred_0_jalr_target,
  output [3:0] io_out_s1_full_pred_0_offsets_0,
  output [3:0] io_out_s1_full_pred_0_offsets_1,
  output [49:0] io_out_s1_full_pred_0_fallThroughAddr,
  output io_out_s1_full_pred_0_fallThroughErr,
  output io_out_s1_full_pred_0_is_jal,
  output io_out_s1_full_pred_0_is_jalr,
  output io_out_s1_full_pred_0_is_call,
  output io_out_s1_full_pred_0_is_ret,
  output io_out_s1_full_pred_0_last_may_be_rvi_call,
  output io_out_s1_full_pred_0_is_br_sharing,
  output io_out_s1_full_pred_0_hit,
  output io_out_s1_full_pred_1_br_taken_mask_0,
  output io_out_s1_full_pred_1_br_taken_mask_1,
  output io_out_s1_full_pred_1_slot_valids_0,
  output io_out_s1_full_pred_1_slot_valids_1,
  output [49:0] io_out_s1_full_pred_1_targets_0,
  output [49:0] io_out_s1_full_pred_1_targets_1,
  output [49:0] io_out_s1_full_pred_1_jalr_target,
  output [3:0] io_out_s1_full_pred_1_offsets_0,
  output [3:0] io_out_s1_full_pred_1_offsets_1,
  output [49:0] io_out_s1_full_pred_1_fallThroughAddr,
  output io_out_s1_full_pred_1_fallThroughErr,
  output io_out_s1_full_pred_1_is_jal,
  output io_out_s1_full_pred_1_is_jalr,
  output io_out_s1_full_pred_1_is_call,
  output io_out_s1_full_pred_1_is_ret,
  output io_out_s1_full_pred_1_last_may_be_rvi_call,
  output io_out_s1_full_pred_1_is_br_sharing,
  output io_out_s1_full_pred_1_hit,
  output io_out_s1_full_pred_2_br_taken_mask_0,
  output io_out_s1_full_pred_2_br_taken_mask_1,
  output io_out_s1_full_pred_2_slot_valids_0,
  output io_out_s1_full_pred_2_slot_valids_1,
  output [49:0] io_out_s1_full_pred_2_targets_0,
  output [49:0] io_out_s1_full_pred_2_targets_1,
  output [49:0] io_out_s1_full_pred_2_jalr_target,
  output [3:0] io_out_s1_full_pred_2_offsets_0,
  output [3:0] io_out_s1_full_pred_2_offsets_1,
  output [49:0] io_out_s1_full_pred_2_fallThroughAddr,
  output io_out_s1_full_pred_2_fallThroughErr,
  output io_out_s1_full_pred_2_is_jal,
  output io_out_s1_full_pred_2_is_jalr,
  output io_out_s1_full_pred_2_is_call,
  output io_out_s1_full_pred_2_is_ret,
  output io_out_s1_full_pred_2_last_may_be_rvi_call,
  output io_out_s1_full_pred_2_is_br_sharing,
  output io_out_s1_full_pred_2_hit,
  output io_out_s1_full_pred_3_br_taken_mask_0,
  output io_out_s1_full_pred_3_br_taken_mask_1,
  output io_out_s1_full_pred_3_slot_valids_0,
  output io_out_s1_full_pred_3_slot_valids_1,
  output [49:0] io_out_s1_full_pred_3_targets_0,
  output [49:0] io_out_s1_full_pred_3_targets_1,
  output [49:0] io_out_s1_full_pred_3_jalr_target,
  output [3:0] io_out_s1_full_pred_3_offsets_0,
  output [3:0] io_out_s1_full_pred_3_offsets_1,
  output [49:0] io_out_s1_full_pred_3_fallThroughAddr,
  output io_out_s1_full_pred_3_fallThroughErr,
  output io_out_s1_full_pred_3_is_jal,
  output io_out_s1_full_pred_3_is_jalr,
  output io_out_s1_full_pred_3_is_call,
  output io_out_s1_full_pred_3_is_ret,
  output io_out_s1_full_pred_3_last_may_be_rvi_call,
  output io_out_s1_full_pred_3_is_br_sharing,
  output io_out_s1_full_pred_3_hit,
  output [49:0] io_out_s2_pc_0,
  output [49:0] io_out_s2_pc_1,
  output [49:0] io_out_s2_pc_2,
  output [49:0] io_out_s2_pc_3,
  output io_out_s2_full_pred_0_br_taken_mask_0,
  output io_out_s2_full_pred_0_br_taken_mask_1,
  output io_out_s2_full_pred_0_slot_valids_0,
  output io_out_s2_full_pred_0_slot_valids_1,
  output [49:0] io_out_s2_full_pred_0_targets_0,
  output [49:0] io_out_s2_full_pred_0_targets_1,
  output [49:0] io_out_s2_full_pred_0_jalr_target,
  output [3:0] io_out_s2_full_pred_0_offsets_0,
  output [3:0] io_out_s2_full_pred_0_offsets_1,
  output [49:0] io_out_s2_full_pred_0_fallThroughAddr,
  output io_out_s2_full_pred_0_fallThroughErr,
  output io_out_s2_full_pred_0_is_jal,
  output io_out_s2_full_pred_0_is_jalr,
  output io_out_s2_full_pred_0_is_call,
  output io_out_s2_full_pred_0_is_ret,
  output io_out_s2_full_pred_0_last_may_be_rvi_call,
  output io_out_s2_full_pred_0_is_br_sharing,
  output io_out_s2_full_pred_0_hit,
  output io_out_s2_full_pred_1_br_taken_mask_0,
  output io_out_s2_full_pred_1_br_taken_mask_1,
  output io_out_s2_full_pred_1_slot_valids_0,
  output io_out_s2_full_pred_1_slot_valids_1,
  output [49:0] io_out_s2_full_pred_1_targets_0,
  output [49:0] io_out_s2_full_pred_1_targets_1,
  output [49:0] io_out_s2_full_pred_1_jalr_target,
  output [3:0] io_out_s2_full_pred_1_offsets_0,
  output [3:0] io_out_s2_full_pred_1_offsets_1,
  output [49:0] io_out_s2_full_pred_1_fallThroughAddr,
  output io_out_s2_full_pred_1_fallThroughErr,
  output io_out_s2_full_pred_1_is_jal,
  output io_out_s2_full_pred_1_is_jalr,
  output io_out_s2_full_pred_1_is_call,
  output io_out_s2_full_pred_1_is_ret,
  output io_out_s2_full_pred_1_last_may_be_rvi_call,
  output io_out_s2_full_pred_1_is_br_sharing,
  output io_out_s2_full_pred_1_hit,
  output io_out_s2_full_pred_2_br_taken_mask_0,
  output io_out_s2_full_pred_2_br_taken_mask_1,
  output io_out_s2_full_pred_2_slot_valids_0,
  output io_out_s2_full_pred_2_slot_valids_1,
  output [49:0] io_out_s2_full_pred_2_targets_0,
  output [49:0] io_out_s2_full_pred_2_targets_1,
  output [49:0] io_out_s2_full_pred_2_jalr_target,
  output [3:0] io_out_s2_full_pred_2_offsets_0,
  output [3:0] io_out_s2_full_pred_2_offsets_1,
  output [49:0] io_out_s2_full_pred_2_fallThroughAddr,
  output io_out_s2_full_pred_2_fallThroughErr,
  output io_out_s2_full_pred_2_is_jal,
  output io_out_s2_full_pred_2_is_jalr,
  output io_out_s2_full_pred_2_is_call,
  output io_out_s2_full_pred_2_is_ret,
  output io_out_s2_full_pred_2_last_may_be_rvi_call,
  output io_out_s2_full_pred_2_is_br_sharing,
  output io_out_s2_full_pred_2_hit,
  output io_out_s2_full_pred_3_br_taken_mask_0,
  output io_out_s2_full_pred_3_br_taken_mask_1,
  output io_out_s2_full_pred_3_slot_valids_0,
  output io_out_s2_full_pred_3_slot_valids_1,
  output [49:0] io_out_s2_full_pred_3_targets_0,
  output [49:0] io_out_s2_full_pred_3_targets_1,
  output [49:0] io_out_s2_full_pred_3_jalr_target,
  output [3:0] io_out_s2_full_pred_3_offsets_0,
  output [3:0] io_out_s2_full_pred_3_offsets_1,
  output [49:0] io_out_s2_full_pred_3_fallThroughAddr,
  output io_out_s2_full_pred_3_fallThroughErr,
  output io_out_s2_full_pred_3_is_jal,
  output io_out_s2_full_pred_3_is_jalr,
  output io_out_s2_full_pred_3_is_call,
  output io_out_s2_full_pred_3_is_ret,
  output io_out_s2_full_pred_3_last_may_be_rvi_call,
  output io_out_s2_full_pred_3_is_br_sharing,
  output io_out_s2_full_pred_3_hit,
  output [49:0] io_out_s3_pc_0,
  output [49:0] io_out_s3_pc_1,
  output [49:0] io_out_s3_pc_2,
  output [49:0] io_out_s3_pc_3,
  output io_out_s3_full_pred_0_br_taken_mask_0,
  output io_out_s3_full_pred_0_br_taken_mask_1,
  output io_out_s3_full_pred_0_slot_valids_0,
  output io_out_s3_full_pred_0_slot_valids_1,
  output [49:0] io_out_s3_full_pred_0_targets_0,
  output [49:0] io_out_s3_full_pred_0_targets_1,
  output [49:0] io_out_s3_full_pred_0_jalr_target,
  output [3:0] io_out_s3_full_pred_0_offsets_0,
  output [3:0] io_out_s3_full_pred_0_offsets_1,
  output [49:0] io_out_s3_full_pred_0_fallThroughAddr,
  output io_out_s3_full_pred_0_fallThroughErr,
  output io_out_s3_full_pred_0_multiHit,
  output io_out_s3_full_pred_0_is_jal,
  output io_out_s3_full_pred_0_is_jalr,
  output io_out_s3_full_pred_0_is_call,
  output io_out_s3_full_pred_0_is_ret,
  output io_out_s3_full_pred_0_last_may_be_rvi_call,
  output io_out_s3_full_pred_0_is_br_sharing,
  output io_out_s3_full_pred_0_hit,
  output io_out_s3_full_pred_1_br_taken_mask_0,
  output io_out_s3_full_pred_1_br_taken_mask_1,
  output io_out_s3_full_pred_1_slot_valids_0,
  output io_out_s3_full_pred_1_slot_valids_1,
  output [49:0] io_out_s3_full_pred_1_targets_0,
  output [49:0] io_out_s3_full_pred_1_targets_1,
  output [49:0] io_out_s3_full_pred_1_jalr_target,
  output [3:0] io_out_s3_full_pred_1_offsets_0,
  output [3:0] io_out_s3_full_pred_1_offsets_1,
  output [49:0] io_out_s3_full_pred_1_fallThroughAddr,
  output io_out_s3_full_pred_1_fallThroughErr,
  output io_out_s3_full_pred_1_multiHit,
  output io_out_s3_full_pred_1_is_jal,
  output io_out_s3_full_pred_1_is_jalr,
  output io_out_s3_full_pred_1_is_call,
  output io_out_s3_full_pred_1_is_ret,
  output io_out_s3_full_pred_1_last_may_be_rvi_call,
  output io_out_s3_full_pred_1_is_br_sharing,
  output io_out_s3_full_pred_1_hit,
  output io_out_s3_full_pred_2_br_taken_mask_0,
  output io_out_s3_full_pred_2_br_taken_mask_1,
  output io_out_s3_full_pred_2_slot_valids_0,
  output io_out_s3_full_pred_2_slot_valids_1,
  output [49:0] io_out_s3_full_pred_2_targets_0,
  output [49:0] io_out_s3_full_pred_2_targets_1,
  output [49:0] io_out_s3_full_pred_2_jalr_target,
  output [3:0] io_out_s3_full_pred_2_offsets_0,
  output [3:0] io_out_s3_full_pred_2_offsets_1,
  output [49:0] io_out_s3_full_pred_2_fallThroughAddr,
  output io_out_s3_full_pred_2_fallThroughErr,
  output io_out_s3_full_pred_2_multiHit,
  output io_out_s3_full_pred_2_is_jal,
  output io_out_s3_full_pred_2_is_jalr,
  output io_out_s3_full_pred_2_is_call,
  output io_out_s3_full_pred_2_is_ret,
  output io_out_s3_full_pred_2_last_may_be_rvi_call,
  output io_out_s3_full_pred_2_is_br_sharing,
  output io_out_s3_full_pred_2_hit,
  output io_out_s3_full_pred_3_br_taken_mask_0,
  output io_out_s3_full_pred_3_br_taken_mask_1,
  output io_out_s3_full_pred_3_slot_valids_0,
  output io_out_s3_full_pred_3_slot_valids_1,
  output [49:0] io_out_s3_full_pred_3_targets_0,
  output [49:0] io_out_s3_full_pred_3_targets_1,
  output [49:0] io_out_s3_full_pred_3_jalr_target,
  output [3:0] io_out_s3_full_pred_3_offsets_0,
  output [3:0] io_out_s3_full_pred_3_offsets_1,
  output [49:0] io_out_s3_full_pred_3_fallThroughAddr,
  output io_out_s3_full_pred_3_fallThroughErr,
  output io_out_s3_full_pred_3_multiHit,
  output io_out_s3_full_pred_3_is_jal,
  output io_out_s3_full_pred_3_is_jalr,
  output io_out_s3_full_pred_3_is_call,
  output io_out_s3_full_pred_3_is_ret,
  output io_out_s3_full_pred_3_last_may_be_rvi_call,
  output io_out_s3_full_pred_3_is_br_sharing,
  output io_out_s3_full_pred_3_hit,
  output [515:0] io_out_last_stage_meta,
  output [3:0] io_out_last_stage_spec_info_ssp,
  output [2:0] io_out_last_stage_spec_info_sctr,
  output io_out_last_stage_spec_info_TOSW_flag,
  output [4:0] io_out_last_stage_spec_info_TOSW_value,
  output io_out_last_stage_spec_info_TOSR_flag,
  output [4:0] io_out_last_stage_spec_info_TOSR_value,
  output io_out_last_stage_spec_info_NOS_flag,
  output [4:0] io_out_last_stage_spec_info_NOS_value,
  output [49:0] io_out_last_stage_spec_info_topAddr,
  output io_out_last_stage_spec_info_sc_disagree_0,
  output io_out_last_stage_spec_info_sc_disagree_1,
  output io_out_last_stage_ftb_entry_isCall,
  output io_out_last_stage_ftb_entry_isRet,
  output io_out_last_stage_ftb_entry_isJalr,
  output io_out_last_stage_ftb_entry_valid,
  output [3:0] io_out_last_stage_ftb_entry_brSlots_0_offset,
  output io_out_last_stage_ftb_entry_brSlots_0_sharing,
  output io_out_last_stage_ftb_entry_brSlots_0_valid,
  output [11:0] io_out_last_stage_ftb_entry_brSlots_0_lower,
  output [1:0] io_out_last_stage_ftb_entry_brSlots_0_tarStat,
  output [3:0] io_out_last_stage_ftb_entry_tailSlot_offset,
  output io_out_last_stage_ftb_entry_tailSlot_sharing,
  output io_out_last_stage_ftb_entry_tailSlot_valid,
  output [19:0] io_out_last_stage_ftb_entry_tailSlot_lower,
  output [1:0] io_out_last_stage_ftb_entry_tailSlot_tarStat,
  output [3:0] io_out_last_stage_ftb_entry_pftAddr,
  output io_out_last_stage_ftb_entry_carry,
  output io_out_last_stage_ftb_entry_last_may_be_rvi_call,
  output io_out_last_stage_ftb_entry_strong_bias_0,
  output io_out_last_stage_ftb_entry_strong_bias_1,
  input  io_ctrl_ubtb_enable,
  input  io_ctrl_btb_enable,
  input  io_ctrl_tage_enable,
  input  io_ctrl_sc_enable,
  input  io_ctrl_ras_enable,
  input  io_s0_fire_0,
  input  io_s0_fire_1,
  input  io_s0_fire_2,
  input  io_s0_fire_3,
  input  io_s1_fire_0,
  input  io_s1_fire_1,
  input  io_s1_fire_2,
  input  io_s1_fire_3,
  input  io_s2_fire_0,
  input  io_s2_fire_1,
  input  io_s2_fire_2,
  input  io_s2_fire_3,
  input  io_s3_fire_0,
  input  io_s3_fire_2,
  input  io_s3_redirect_2,
  output io_s1_ready,
  input  io_update_valid,
  input  [49:0] io_update_bits_pc,
  input  io_update_bits_ftb_entry_isCall,
  input  io_update_bits_ftb_entry_isRet,
  input  io_update_bits_ftb_entry_isJalr,
  input  io_update_bits_ftb_entry_valid,
  input  [3:0] io_update_bits_ftb_entry_brSlots_0_offset,
  input  io_update_bits_ftb_entry_brSlots_0_sharing,
  input  io_update_bits_ftb_entry_brSlots_0_valid,
  input  [11:0] io_update_bits_ftb_entry_brSlots_0_lower,
  input  [1:0] io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  [3:0] io_update_bits_ftb_entry_tailSlot_offset,
  input  io_update_bits_ftb_entry_tailSlot_sharing,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  [19:0] io_update_bits_ftb_entry_tailSlot_lower,
  input  [1:0] io_update_bits_ftb_entry_tailSlot_tarStat,
  input  [3:0] io_update_bits_ftb_entry_pftAddr,
  input  io_update_bits_ftb_entry_carry,
  input  io_update_bits_ftb_entry_last_may_be_rvi_call,
  input  io_update_bits_ftb_entry_strong_bias_0,
  input  io_update_bits_ftb_entry_strong_bias_1,
  input  io_update_bits_cfi_idx_valid,
  input  [3:0] io_update_bits_cfi_idx_bits,
  input  io_update_bits_br_taken_mask_0,
  input  io_update_bits_br_taken_mask_1,
  input  io_update_bits_jmp_taken,
  input  io_update_bits_mispred_mask_0,
  input  io_update_bits_mispred_mask_1,
  input  io_update_bits_mispred_mask_2,
  input  io_update_bits_false_hit,
  input  io_update_bits_old_entry,
  input  [515:0] io_update_bits_meta,
  input  [49:0] io_update_bits_full_target,
  input  [255:0] io_update_bits_ghist,
  input  io_redirect_valid,
  input  io_redirect_bits_level,
  input  [49:0] io_redirect_bits_cfiUpdate_pc,
  input  io_redirect_bits_cfiUpdate_pd_valid,
  input  io_redirect_bits_cfiUpdate_pd_isRVC,
  input  io_redirect_bits_cfiUpdate_pd_isCall,
  input  io_redirect_bits_cfiUpdate_pd_isRet,
  input  [3:0] io_redirect_bits_cfiUpdate_ssp,
  input  [2:0] io_redirect_bits_cfiUpdate_sctr,
  input  io_redirect_bits_cfiUpdate_TOSW_flag,
  input  [4:0] io_redirect_bits_cfiUpdate_TOSW_value,
  input  io_redirect_bits_cfiUpdate_TOSR_flag,
  input  [4:0] io_redirect_bits_cfiUpdate_TOSR_value,
  input  io_redirect_bits_cfiUpdate_NOS_flag,
  input  [4:0] io_redirect_bits_cfiUpdate_NOS_value,
  input  io_redirectFromIFU,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  input  [5:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [3:0] boreChildrenBd_bore_be,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [39:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  output [39:0] boreChildrenBd_bore_outdata,
  input  [6:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [15:0] boreChildrenBd_bore_1_be,
  input  [9:0] boreChildrenBd_bore_1_addr,
  input  [23:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [9:0] boreChildrenBd_bore_1_addr_rd,
  output [23:0] boreChildrenBd_bore_1_outdata,
  input  [6:0] boreChildrenBd_bore_2_array,
  input  boreChildrenBd_bore_2_all,
  input  boreChildrenBd_bore_2_req,
  output boreChildrenBd_bore_2_ack,
  input  boreChildrenBd_bore_2_writeen,
  input  [3:0] boreChildrenBd_bore_2_be,
  input  [8:0] boreChildrenBd_bore_2_addr,
  input  [23:0] boreChildrenBd_bore_2_indata,
  input  boreChildrenBd_bore_2_readen,
  input  [8:0] boreChildrenBd_bore_2_addr_rd,
  output [23:0] boreChildrenBd_bore_2_outdata,
  input  [6:0] boreChildrenBd_bore_3_array,
  input  boreChildrenBd_bore_3_all,
  input  boreChildrenBd_bore_3_req,
  output boreChildrenBd_bore_3_ack,
  input  boreChildrenBd_bore_3_writeen,
  input  [3:0] boreChildrenBd_bore_3_be,
  input  [8:0] boreChildrenBd_bore_3_addr,
  input  [23:0] boreChildrenBd_bore_3_indata,
  input  boreChildrenBd_bore_3_readen,
  input  [8:0] boreChildrenBd_bore_3_addr_rd,
  output [23:0] boreChildrenBd_bore_3_outdata,
  input  [6:0] boreChildrenBd_bore_4_array,
  input  boreChildrenBd_bore_4_all,
  input  boreChildrenBd_bore_4_req,
  output boreChildrenBd_bore_4_ack,
  input  boreChildrenBd_bore_4_writeen,
  input  [3:0] boreChildrenBd_bore_4_be,
  input  [8:0] boreChildrenBd_bore_4_addr,
  input  [23:0] boreChildrenBd_bore_4_indata,
  input  boreChildrenBd_bore_4_readen,
  input  [8:0] boreChildrenBd_bore_4_addr_rd,
  output [23:0] boreChildrenBd_bore_4_outdata,
  input  [6:0] boreChildrenBd_bore_5_array,
  input  boreChildrenBd_bore_5_all,
  input  boreChildrenBd_bore_5_req,
  output boreChildrenBd_bore_5_ack,
  input  boreChildrenBd_bore_5_writeen,
  input  [3:0] boreChildrenBd_bore_5_be,
  input  [8:0] boreChildrenBd_bore_5_addr,
  input  [23:0] boreChildrenBd_bore_5_indata,
  input  boreChildrenBd_bore_5_readen,
  input  [8:0] boreChildrenBd_bore_5_addr_rd,
  output [23:0] boreChildrenBd_bore_5_outdata,
  input  [6:0] boreChildrenBd_bore_6_array,
  input  boreChildrenBd_bore_6_all,
  input  boreChildrenBd_bore_6_req,
  output boreChildrenBd_bore_6_ack,
  input  boreChildrenBd_bore_6_writeen,
  input  [75:0] boreChildrenBd_bore_6_be,
  input  [7:0] boreChildrenBd_bore_6_addr,
  input  [75:0] boreChildrenBd_bore_6_indata,
  input  boreChildrenBd_bore_6_readen,
  input  [7:0] boreChildrenBd_bore_6_addr_rd,
  output [75:0] boreChildrenBd_bore_6_outdata,
  input  [6:0] boreChildrenBd_bore_7_array,
  input  boreChildrenBd_bore_7_all,
  input  boreChildrenBd_bore_7_req,
  output boreChildrenBd_bore_7_ack,
  input  boreChildrenBd_bore_7_writeen,
  input  [75:0] boreChildrenBd_bore_7_be,
  input  [7:0] boreChildrenBd_bore_7_addr,
  input  [75:0] boreChildrenBd_bore_7_indata,
  input  boreChildrenBd_bore_7_readen,
  input  [7:0] boreChildrenBd_bore_7_addr_rd,
  output [75:0] boreChildrenBd_bore_7_outdata,
  input  [6:0] boreChildrenBd_bore_8_array,
  input  boreChildrenBd_bore_8_all,
  input  boreChildrenBd_bore_8_req,
  output boreChildrenBd_bore_8_ack,
  input  boreChildrenBd_bore_8_writeen,
  input  [75:0] boreChildrenBd_bore_8_be,
  input  [7:0] boreChildrenBd_bore_8_addr,
  input  [75:0] boreChildrenBd_bore_8_indata,
  input  boreChildrenBd_bore_8_readen,
  input  [7:0] boreChildrenBd_bore_8_addr_rd,
  output [75:0] boreChildrenBd_bore_8_outdata,
  input  [6:0] boreChildrenBd_bore_9_array,
  input  boreChildrenBd_bore_9_all,
  input  boreChildrenBd_bore_9_req,
  output boreChildrenBd_bore_9_ack,
  input  boreChildrenBd_bore_9_writeen,
  input  [75:0] boreChildrenBd_bore_9_be,
  input  [7:0] boreChildrenBd_bore_9_addr,
  input  [75:0] boreChildrenBd_bore_9_indata,
  input  boreChildrenBd_bore_9_readen,
  input  [7:0] boreChildrenBd_bore_9_addr_rd,
  output [75:0] boreChildrenBd_bore_9_outdata,
  input  [6:0] boreChildrenBd_bore_10_array,
  input  boreChildrenBd_bore_10_all,
  input  boreChildrenBd_bore_10_req,
  output boreChildrenBd_bore_10_ack,
  input  boreChildrenBd_bore_10_writeen,
  input  [75:0] boreChildrenBd_bore_10_be,
  input  [7:0] boreChildrenBd_bore_10_addr,
  input  [75:0] boreChildrenBd_bore_10_indata,
  input  boreChildrenBd_bore_10_readen,
  input  [7:0] boreChildrenBd_bore_10_addr_rd,
  output [75:0] boreChildrenBd_bore_10_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  sigFromSrams_bore_15_ram_hold,
  input  sigFromSrams_bore_15_ram_bypass,
  input  sigFromSrams_bore_15_ram_bp_clken,
  input  sigFromSrams_bore_15_ram_aux_clk,
  input  sigFromSrams_bore_15_ram_aux_ckbp,
  input  sigFromSrams_bore_15_ram_mcp_hold,
  input  sigFromSrams_bore_15_cgen,
  input  sigFromSrams_bore_16_ram_hold,
  input  sigFromSrams_bore_16_ram_bypass,
  input  sigFromSrams_bore_16_ram_bp_clken,
  input  sigFromSrams_bore_16_ram_aux_clk,
  input  sigFromSrams_bore_16_ram_aux_ckbp,
  input  sigFromSrams_bore_16_ram_mcp_hold,
  input  sigFromSrams_bore_16_cgen,
  input  sigFromSrams_bore_17_ram_hold,
  input  sigFromSrams_bore_17_ram_bypass,
  input  sigFromSrams_bore_17_ram_bp_clken,
  input  sigFromSrams_bore_17_ram_aux_clk,
  input  sigFromSrams_bore_17_ram_aux_ckbp,
  input  sigFromSrams_bore_17_ram_mcp_hold,
  input  sigFromSrams_bore_17_cgen,
  input  sigFromSrams_bore_18_ram_hold,
  input  sigFromSrams_bore_18_ram_bypass,
  input  sigFromSrams_bore_18_ram_bp_clken,
  input  sigFromSrams_bore_18_ram_aux_clk,
  input  sigFromSrams_bore_18_ram_aux_ckbp,
  input  sigFromSrams_bore_18_ram_mcp_hold,
  input  sigFromSrams_bore_18_cgen,
  input  sigFromSrams_bore_19_ram_hold,
  input  sigFromSrams_bore_19_ram_bypass,
  input  sigFromSrams_bore_19_ram_bp_clken,
  input  sigFromSrams_bore_19_ram_aux_clk,
  input  sigFromSrams_bore_19_ram_aux_ckbp,
  input  sigFromSrams_bore_19_ram_mcp_hold,
  input  sigFromSrams_bore_19_cgen,
  input  sigFromSrams_bore_20_ram_hold,
  input  sigFromSrams_bore_20_ram_bypass,
  input  sigFromSrams_bore_20_ram_bp_clken,
  input  sigFromSrams_bore_20_ram_aux_clk,
  input  sigFromSrams_bore_20_ram_aux_ckbp,
  input  sigFromSrams_bore_20_ram_mcp_hold,
  input  sigFromSrams_bore_20_cgen,
  input  sigFromSrams_bore_21_ram_hold,
  input  sigFromSrams_bore_21_ram_bypass,
  input  sigFromSrams_bore_21_ram_bp_clken,
  input  sigFromSrams_bore_21_ram_aux_clk,
  input  sigFromSrams_bore_21_ram_aux_ckbp,
  input  sigFromSrams_bore_21_ram_mcp_hold,
  input  sigFromSrams_bore_21_cgen,
  input  sigFromSrams_bore_22_ram_hold,
  input  sigFromSrams_bore_22_ram_bypass,
  input  sigFromSrams_bore_22_ram_bp_clken,
  input  sigFromSrams_bore_22_ram_aux_clk,
  input  sigFromSrams_bore_22_ram_aux_ckbp,
  input  sigFromSrams_bore_22_ram_mcp_hold,
  input  sigFromSrams_bore_22_cgen,
  input  sigFromSrams_bore_23_ram_hold,
  input  sigFromSrams_bore_23_ram_bypass,
  input  sigFromSrams_bore_23_ram_bp_clken,
  input  sigFromSrams_bore_23_ram_aux_clk,
  input  sigFromSrams_bore_23_ram_aux_ckbp,
  input  sigFromSrams_bore_23_ram_mcp_hold,
  input  sigFromSrams_bore_23_cgen,
  input  sigFromSrams_bore_24_ram_hold,
  input  sigFromSrams_bore_24_ram_bypass,
  input  sigFromSrams_bore_24_ram_bp_clken,
  input  sigFromSrams_bore_24_ram_aux_clk,
  input  sigFromSrams_bore_24_ram_aux_ckbp,
  input  sigFromSrams_bore_24_ram_mcp_hold,
  input  sigFromSrams_bore_24_cgen,
  input  sigFromSrams_bore_25_ram_hold,
  input  sigFromSrams_bore_25_ram_bypass,
  input  sigFromSrams_bore_25_ram_bp_clken,
  input  sigFromSrams_bore_25_ram_aux_clk,
  input  sigFromSrams_bore_25_ram_aux_ckbp,
  input  sigFromSrams_bore_25_ram_mcp_hold,
  input  sigFromSrams_bore_25_cgen,
  input  sigFromSrams_bore_26_ram_hold,
  input  sigFromSrams_bore_26_ram_bypass,
  input  sigFromSrams_bore_26_ram_bp_clken,
  input  sigFromSrams_bore_26_ram_aux_clk,
  input  sigFromSrams_bore_26_ram_aux_ckbp,
  input  sigFromSrams_bore_26_ram_mcp_hold,
  input  sigFromSrams_bore_26_cgen,
  input  sigFromSrams_bore_27_ram_hold,
  input  sigFromSrams_bore_27_ram_bypass,
  input  sigFromSrams_bore_27_ram_bp_clken,
  input  sigFromSrams_bore_27_ram_aux_clk,
  input  sigFromSrams_bore_27_ram_aux_ckbp,
  input  sigFromSrams_bore_27_ram_mcp_hold,
  input  sigFromSrams_bore_27_cgen,
  input  sigFromSrams_bore_28_ram_hold,
  input  sigFromSrams_bore_28_ram_bypass,
  input  sigFromSrams_bore_28_ram_bp_clken,
  input  sigFromSrams_bore_28_ram_aux_clk,
  input  sigFromSrams_bore_28_ram_aux_ckbp,
  input  sigFromSrams_bore_28_ram_mcp_hold,
  input  sigFromSrams_bore_28_cgen,
  input  sigFromSrams_bore_29_ram_hold,
  input  sigFromSrams_bore_29_ram_bypass,
  input  sigFromSrams_bore_29_ram_bp_clken,
  input  sigFromSrams_bore_29_ram_aux_clk,
  input  sigFromSrams_bore_29_ram_aux_ckbp,
  input  sigFromSrams_bore_29_ram_mcp_hold,
  input  sigFromSrams_bore_29_cgen,
  input  sigFromSrams_bore_30_ram_hold,
  input  sigFromSrams_bore_30_ram_bypass,
  input  sigFromSrams_bore_30_ram_bp_clken,
  input  sigFromSrams_bore_30_ram_aux_clk,
  input  sigFromSrams_bore_30_ram_aux_ckbp,
  input  sigFromSrams_bore_30_ram_mcp_hold,
  input  sigFromSrams_bore_30_cgen,
  input  sigFromSrams_bore_31_ram_hold,
  input  sigFromSrams_bore_31_ram_bypass,
  input  sigFromSrams_bore_31_ram_bp_clken,
  input  sigFromSrams_bore_31_ram_aux_clk,
  input  sigFromSrams_bore_31_ram_aux_ckbp,
  input  sigFromSrams_bore_31_ram_mcp_hold,
  input  sigFromSrams_bore_31_cgen,
  input  sigFromSrams_bore_32_ram_hold,
  input  sigFromSrams_bore_32_ram_bypass,
  input  sigFromSrams_bore_32_ram_bp_clken,
  input  sigFromSrams_bore_32_ram_aux_clk,
  input  sigFromSrams_bore_32_ram_aux_ckbp,
  input  sigFromSrams_bore_32_ram_mcp_hold,
  input  sigFromSrams_bore_32_cgen,
  input  sigFromSrams_bore_33_ram_hold,
  input  sigFromSrams_bore_33_ram_bypass,
  input  sigFromSrams_bore_33_ram_bp_clken,
  input  sigFromSrams_bore_33_ram_aux_clk,
  input  sigFromSrams_bore_33_ram_aux_ckbp,
  input  sigFromSrams_bore_33_ram_mcp_hold,
  input  sigFromSrams_bore_33_cgen,
  input  sigFromSrams_bore_34_ram_hold,
  input  sigFromSrams_bore_34_ram_bypass,
  input  sigFromSrams_bore_34_ram_bp_clken,
  input  sigFromSrams_bore_34_ram_aux_clk,
  input  sigFromSrams_bore_34_ram_aux_ckbp,
  input  sigFromSrams_bore_34_ram_mcp_hold,
  input  sigFromSrams_bore_34_cgen,
  input  sigFromSrams_bore_35_ram_hold,
  input  sigFromSrams_bore_35_ram_bypass,
  input  sigFromSrams_bore_35_ram_bp_clken,
  input  sigFromSrams_bore_35_ram_aux_clk,
  input  sigFromSrams_bore_35_ram_aux_ckbp,
  input  sigFromSrams_bore_35_ram_mcp_hold,
  input  sigFromSrams_bore_35_cgen,
  input  sigFromSrams_bore_36_ram_hold,
  input  sigFromSrams_bore_36_ram_bypass,
  input  sigFromSrams_bore_36_ram_bp_clken,
  input  sigFromSrams_bore_36_ram_aux_clk,
  input  sigFromSrams_bore_36_ram_aux_ckbp,
  input  sigFromSrams_bore_36_ram_mcp_hold,
  input  sigFromSrams_bore_36_cgen,
  input  sigFromSrams_bore_37_ram_hold,
  input  sigFromSrams_bore_37_ram_bypass,
  input  sigFromSrams_bore_37_ram_bp_clken,
  input  sigFromSrams_bore_37_ram_aux_clk,
  input  sigFromSrams_bore_37_ram_aux_ckbp,
  input  sigFromSrams_bore_37_ram_mcp_hold,
  input  sigFromSrams_bore_37_cgen,
  input  sigFromSrams_bore_38_ram_hold,
  input  sigFromSrams_bore_38_ram_bypass,
  input  sigFromSrams_bore_38_ram_bp_clken,
  input  sigFromSrams_bore_38_ram_aux_clk,
  input  sigFromSrams_bore_38_ram_aux_ckbp,
  input  sigFromSrams_bore_38_ram_mcp_hold,
  input  sigFromSrams_bore_38_cgen,
  input  sigFromSrams_bore_39_ram_hold,
  input  sigFromSrams_bore_39_ram_bypass,
  input  sigFromSrams_bore_39_ram_bp_clken,
  input  sigFromSrams_bore_39_ram_aux_clk,
  input  sigFromSrams_bore_39_ram_aux_ckbp,
  input  sigFromSrams_bore_39_ram_mcp_hold,
  input  sigFromSrams_bore_39_cgen,
  input  sigFromSrams_bore_40_ram_hold,
  input  sigFromSrams_bore_40_ram_bypass,
  input  sigFromSrams_bore_40_ram_bp_clken,
  input  sigFromSrams_bore_40_ram_aux_clk,
  input  sigFromSrams_bore_40_ram_aux_ckbp,
  input  sigFromSrams_bore_40_ram_mcp_hold,
  input  sigFromSrams_bore_40_cgen,
  input  sigFromSrams_bore_41_ram_hold,
  input  sigFromSrams_bore_41_ram_bypass,
  input  sigFromSrams_bore_41_ram_bp_clken,
  input  sigFromSrams_bore_41_ram_aux_clk,
  input  sigFromSrams_bore_41_ram_aux_ckbp,
  input  sigFromSrams_bore_41_ram_mcp_hold,
  input  sigFromSrams_bore_41_cgen
);

  // ---- 预测器之间 / 预测器→输出 的互连 net（沿用 golden 原名，便于黑盒引脚对齐）----
  wire _ras_io_ctrl_delay_io_out_ras_enable;
  wire _ftb_io_ctrl_delay_io_out_btb_enable;
  wire _tage_io_ctrl_delay_io_out_tage_enable;
  wire _tage_io_ctrl_delay_io_out_sc_enable;
  wire _uftb_io_ctrl_delay_io_out_ubtb_enable;
  wire _ittage_io_out_s2_full_pred_0_br_taken_mask_0;
  wire _ittage_io_out_s2_full_pred_0_br_taken_mask_1;
  wire _ittage_io_out_s2_full_pred_0_slot_valids_0;
  wire _ittage_io_out_s2_full_pred_0_slot_valids_1;
  wire [49:0] _ittage_io_out_s2_full_pred_0_targets_0;
  wire [49:0] _ittage_io_out_s2_full_pred_0_targets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_0_jalr_target;
  wire [3:0] _ittage_io_out_s2_full_pred_0_offsets_0;
  wire [3:0] _ittage_io_out_s2_full_pred_0_offsets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_0_fallThroughAddr;
  wire _ittage_io_out_s2_full_pred_0_fallThroughErr;
  wire _ittage_io_out_s2_full_pred_0_is_jal;
  wire _ittage_io_out_s2_full_pred_0_is_jalr;
  wire _ittage_io_out_s2_full_pred_0_is_call;
  wire _ittage_io_out_s2_full_pred_0_is_ret;
  wire _ittage_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire _ittage_io_out_s2_full_pred_0_is_br_sharing;
  wire _ittage_io_out_s2_full_pred_0_hit;
  wire _ittage_io_out_s2_full_pred_1_br_taken_mask_0;
  wire _ittage_io_out_s2_full_pred_1_br_taken_mask_1;
  wire _ittage_io_out_s2_full_pred_1_slot_valids_0;
  wire _ittage_io_out_s2_full_pred_1_slot_valids_1;
  wire [49:0] _ittage_io_out_s2_full_pred_1_targets_0;
  wire [49:0] _ittage_io_out_s2_full_pred_1_targets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_1_jalr_target;
  wire [3:0] _ittage_io_out_s2_full_pred_1_offsets_0;
  wire [3:0] _ittage_io_out_s2_full_pred_1_offsets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_1_fallThroughAddr;
  wire _ittage_io_out_s2_full_pred_1_fallThroughErr;
  wire _ittage_io_out_s2_full_pred_1_is_jal;
  wire _ittage_io_out_s2_full_pred_1_is_jalr;
  wire _ittage_io_out_s2_full_pred_1_is_call;
  wire _ittage_io_out_s2_full_pred_1_is_ret;
  wire _ittage_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire _ittage_io_out_s2_full_pred_1_is_br_sharing;
  wire _ittage_io_out_s2_full_pred_1_hit;
  wire _ittage_io_out_s2_full_pred_2_br_taken_mask_0;
  wire _ittage_io_out_s2_full_pred_2_br_taken_mask_1;
  wire _ittage_io_out_s2_full_pred_2_slot_valids_0;
  wire _ittage_io_out_s2_full_pred_2_slot_valids_1;
  wire [49:0] _ittage_io_out_s2_full_pred_2_targets_0;
  wire [49:0] _ittage_io_out_s2_full_pred_2_targets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_2_jalr_target;
  wire [3:0] _ittage_io_out_s2_full_pred_2_offsets_0;
  wire [3:0] _ittage_io_out_s2_full_pred_2_offsets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_2_fallThroughAddr;
  wire _ittage_io_out_s2_full_pred_2_fallThroughErr;
  wire _ittage_io_out_s2_full_pred_2_is_jal;
  wire _ittage_io_out_s2_full_pred_2_is_jalr;
  wire _ittage_io_out_s2_full_pred_2_is_call;
  wire _ittage_io_out_s2_full_pred_2_is_ret;
  wire _ittage_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire _ittage_io_out_s2_full_pred_2_is_br_sharing;
  wire _ittage_io_out_s2_full_pred_2_hit;
  wire _ittage_io_out_s2_full_pred_3_br_taken_mask_0;
  wire _ittage_io_out_s2_full_pred_3_br_taken_mask_1;
  wire _ittage_io_out_s2_full_pred_3_slot_valids_0;
  wire _ittage_io_out_s2_full_pred_3_slot_valids_1;
  wire [49:0] _ittage_io_out_s2_full_pred_3_targets_0;
  wire [49:0] _ittage_io_out_s2_full_pred_3_targets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_3_jalr_target;
  wire [3:0] _ittage_io_out_s2_full_pred_3_offsets_0;
  wire [3:0] _ittage_io_out_s2_full_pred_3_offsets_1;
  wire [49:0] _ittage_io_out_s2_full_pred_3_fallThroughAddr;
  wire _ittage_io_out_s2_full_pred_3_fallThroughErr;
  wire _ittage_io_out_s2_full_pred_3_is_jal;
  wire _ittage_io_out_s2_full_pred_3_is_jalr;
  wire _ittage_io_out_s2_full_pred_3_is_call;
  wire _ittage_io_out_s2_full_pred_3_is_ret;
  wire _ittage_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire _ittage_io_out_s2_full_pred_3_is_br_sharing;
  wire _ittage_io_out_s2_full_pred_3_hit;
  wire _ittage_io_out_s3_full_pred_0_br_taken_mask_0;
  wire _ittage_io_out_s3_full_pred_0_br_taken_mask_1;
  wire _ittage_io_out_s3_full_pred_0_slot_valids_0;
  wire _ittage_io_out_s3_full_pred_0_slot_valids_1;
  wire [49:0] _ittage_io_out_s3_full_pred_0_targets_0;
  wire [49:0] _ittage_io_out_s3_full_pred_0_targets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_0_jalr_target;
  wire [3:0] _ittage_io_out_s3_full_pred_0_offsets_0;
  wire [3:0] _ittage_io_out_s3_full_pred_0_offsets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_0_fallThroughAddr;
  wire _ittage_io_out_s3_full_pred_0_fallThroughErr;
  wire _ittage_io_out_s3_full_pred_0_multiHit;
  wire _ittage_io_out_s3_full_pred_0_is_jal;
  wire _ittage_io_out_s3_full_pred_0_is_jalr;
  wire _ittage_io_out_s3_full_pred_0_is_call;
  wire _ittage_io_out_s3_full_pred_0_is_ret;
  wire _ittage_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire _ittage_io_out_s3_full_pred_0_is_br_sharing;
  wire _ittage_io_out_s3_full_pred_0_hit;
  wire _ittage_io_out_s3_full_pred_1_br_taken_mask_0;
  wire _ittage_io_out_s3_full_pred_1_br_taken_mask_1;
  wire _ittage_io_out_s3_full_pred_1_slot_valids_0;
  wire _ittage_io_out_s3_full_pred_1_slot_valids_1;
  wire [49:0] _ittage_io_out_s3_full_pred_1_targets_0;
  wire [49:0] _ittage_io_out_s3_full_pred_1_targets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_1_jalr_target;
  wire [3:0] _ittage_io_out_s3_full_pred_1_offsets_0;
  wire [3:0] _ittage_io_out_s3_full_pred_1_offsets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_1_fallThroughAddr;
  wire _ittage_io_out_s3_full_pred_1_fallThroughErr;
  wire _ittage_io_out_s3_full_pred_1_multiHit;
  wire _ittage_io_out_s3_full_pred_1_is_jal;
  wire _ittage_io_out_s3_full_pred_1_is_jalr;
  wire _ittage_io_out_s3_full_pred_1_is_call;
  wire _ittage_io_out_s3_full_pred_1_is_ret;
  wire _ittage_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire _ittage_io_out_s3_full_pred_1_is_br_sharing;
  wire _ittage_io_out_s3_full_pred_1_hit;
  wire _ittage_io_out_s3_full_pred_2_br_taken_mask_0;
  wire _ittage_io_out_s3_full_pred_2_br_taken_mask_1;
  wire _ittage_io_out_s3_full_pred_2_slot_valids_0;
  wire _ittage_io_out_s3_full_pred_2_slot_valids_1;
  wire [49:0] _ittage_io_out_s3_full_pred_2_targets_0;
  wire [49:0] _ittage_io_out_s3_full_pred_2_targets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_2_jalr_target;
  wire [3:0] _ittage_io_out_s3_full_pred_2_offsets_0;
  wire [3:0] _ittage_io_out_s3_full_pred_2_offsets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_2_fallThroughAddr;
  wire _ittage_io_out_s3_full_pred_2_fallThroughErr;
  wire _ittage_io_out_s3_full_pred_2_multiHit;
  wire _ittage_io_out_s3_full_pred_2_is_jal;
  wire _ittage_io_out_s3_full_pred_2_is_jalr;
  wire _ittage_io_out_s3_full_pred_2_is_call;
  wire _ittage_io_out_s3_full_pred_2_is_ret;
  wire _ittage_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire _ittage_io_out_s3_full_pred_2_is_br_sharing;
  wire _ittage_io_out_s3_full_pred_2_hit;
  wire _ittage_io_out_s3_full_pred_3_br_taken_mask_0;
  wire _ittage_io_out_s3_full_pred_3_br_taken_mask_1;
  wire _ittage_io_out_s3_full_pred_3_slot_valids_0;
  wire _ittage_io_out_s3_full_pred_3_slot_valids_1;
  wire [49:0] _ittage_io_out_s3_full_pred_3_targets_0;
  wire [49:0] _ittage_io_out_s3_full_pred_3_targets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_3_jalr_target;
  wire [3:0] _ittage_io_out_s3_full_pred_3_offsets_0;
  wire [3:0] _ittage_io_out_s3_full_pred_3_offsets_1;
  wire [49:0] _ittage_io_out_s3_full_pred_3_fallThroughAddr;
  wire _ittage_io_out_s3_full_pred_3_fallThroughErr;
  wire _ittage_io_out_s3_full_pred_3_multiHit;
  wire _ittage_io_out_s3_full_pred_3_is_jal;
  wire _ittage_io_out_s3_full_pred_3_is_jalr;
  wire _ittage_io_out_s3_full_pred_3_is_call;
  wire _ittage_io_out_s3_full_pred_3_is_ret;
  wire _ittage_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire _ittage_io_out_s3_full_pred_3_is_br_sharing;
  wire _ittage_io_out_s3_full_pred_3_hit;
  wire [515:0] _ittage_io_out_last_stage_meta;
  wire _ittage_io_out_last_stage_spec_info_sc_disagree_0;
  wire _ittage_io_out_last_stage_spec_info_sc_disagree_1;
  wire _ittage_io_out_last_stage_ftb_entry_isCall;
  wire _ittage_io_out_last_stage_ftb_entry_isRet;
  wire _ittage_io_out_last_stage_ftb_entry_isJalr;
  wire _ittage_io_out_last_stage_ftb_entry_valid;
  wire [3:0] _ittage_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire _ittage_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire _ittage_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0] _ittage_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0] _ittage_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0] _ittage_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire _ittage_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire _ittage_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0] _ittage_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0] _ittage_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0] _ittage_io_out_last_stage_ftb_entry_pftAddr;
  wire _ittage_io_out_last_stage_ftb_entry_carry;
  wire _ittage_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire _ittage_io_out_last_stage_ftb_entry_strong_bias_0;
  wire _ittage_io_out_last_stage_ftb_entry_strong_bias_1;
  wire _ittage_io_s1_ready;
  wire [515:0] _ras_io_out_last_stage_meta;
  wire _tage_io_out_s2_full_pred_0_br_taken_mask_0;
  wire _tage_io_out_s2_full_pred_0_br_taken_mask_1;
  wire _tage_io_out_s2_full_pred_1_br_taken_mask_0;
  wire _tage_io_out_s2_full_pred_1_br_taken_mask_1;
  wire _tage_io_out_s2_full_pred_2_br_taken_mask_0;
  wire _tage_io_out_s2_full_pred_2_br_taken_mask_1;
  wire _tage_io_out_s2_full_pred_3_br_taken_mask_0;
  wire _tage_io_out_s2_full_pred_3_br_taken_mask_1;
  wire _tage_io_out_s3_full_pred_0_br_taken_mask_0;
  wire _tage_io_out_s3_full_pred_0_br_taken_mask_1;
  wire _tage_io_out_s3_full_pred_1_br_taken_mask_0;
  wire _tage_io_out_s3_full_pred_1_br_taken_mask_1;
  wire _tage_io_out_s3_full_pred_2_br_taken_mask_0;
  wire _tage_io_out_s3_full_pred_2_br_taken_mask_1;
  wire _tage_io_out_s3_full_pred_3_br_taken_mask_0;
  wire _tage_io_out_s3_full_pred_3_br_taken_mask_1;
  wire [515:0] _tage_io_out_last_stage_meta;
  wire _tage_io_out_last_stage_spec_info_sc_disagree_0;
  wire _tage_io_out_last_stage_spec_info_sc_disagree_1;
  wire _tage_io_s1_ready;
  wire [5:0] _tage_io_perf_0_value;
  wire [5:0] _tage_io_perf_1_value;
  wire [5:0] _tage_io_perf_2_value;
  wire [515:0] _uftb_io_out_last_stage_meta;
  wire _uftb_io_fauftb_entry_out_isCall;
  wire _uftb_io_fauftb_entry_out_isRet;
  wire _uftb_io_fauftb_entry_out_isJalr;
  wire _uftb_io_fauftb_entry_out_valid;
  wire [3:0] _uftb_io_fauftb_entry_out_brSlots_0_offset;
  wire _uftb_io_fauftb_entry_out_brSlots_0_sharing;
  wire _uftb_io_fauftb_entry_out_brSlots_0_valid;
  wire [11:0] _uftb_io_fauftb_entry_out_brSlots_0_lower;
  wire [1:0] _uftb_io_fauftb_entry_out_brSlots_0_tarStat;
  wire [3:0] _uftb_io_fauftb_entry_out_tailSlot_offset;
  wire _uftb_io_fauftb_entry_out_tailSlot_sharing;
  wire _uftb_io_fauftb_entry_out_tailSlot_valid;
  wire [19:0] _uftb_io_fauftb_entry_out_tailSlot_lower;
  wire [1:0] _uftb_io_fauftb_entry_out_tailSlot_tarStat;
  wire [3:0] _uftb_io_fauftb_entry_out_pftAddr;
  wire _uftb_io_fauftb_entry_out_carry;
  wire _uftb_io_fauftb_entry_out_last_may_be_rvi_call;
  wire _uftb_io_fauftb_entry_out_strong_bias_0;
  wire _uftb_io_fauftb_entry_out_strong_bias_1;
  wire _uftb_io_fauftb_entry_hit_out;
  wire [5:0] _uftb_io_perf_0_value;
  wire [5:0] _uftb_io_perf_1_value;
  wire _ftb_io_out_s2_full_pred_0_br_taken_mask_0;
  wire _ftb_io_out_s2_full_pred_0_br_taken_mask_1;
  wire _ftb_io_out_s2_full_pred_0_slot_valids_0;
  wire _ftb_io_out_s2_full_pred_0_slot_valids_1;
  wire [49:0] _ftb_io_out_s2_full_pred_0_targets_0;
  wire [49:0] _ftb_io_out_s2_full_pred_0_targets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_0_jalr_target;
  wire [3:0] _ftb_io_out_s2_full_pred_0_offsets_0;
  wire [3:0] _ftb_io_out_s2_full_pred_0_offsets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_0_fallThroughAddr;
  wire _ftb_io_out_s2_full_pred_0_fallThroughErr;
  wire _ftb_io_out_s2_full_pred_0_is_jal;
  wire _ftb_io_out_s2_full_pred_0_is_jalr;
  wire _ftb_io_out_s2_full_pred_0_is_call;
  wire _ftb_io_out_s2_full_pred_0_is_ret;
  wire _ftb_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire _ftb_io_out_s2_full_pred_0_is_br_sharing;
  wire _ftb_io_out_s2_full_pred_0_hit;
  wire _ftb_io_out_s2_full_pred_1_br_taken_mask_0;
  wire _ftb_io_out_s2_full_pred_1_br_taken_mask_1;
  wire _ftb_io_out_s2_full_pred_1_slot_valids_0;
  wire _ftb_io_out_s2_full_pred_1_slot_valids_1;
  wire [49:0] _ftb_io_out_s2_full_pred_1_targets_0;
  wire [49:0] _ftb_io_out_s2_full_pred_1_targets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_1_jalr_target;
  wire [3:0] _ftb_io_out_s2_full_pred_1_offsets_0;
  wire [3:0] _ftb_io_out_s2_full_pred_1_offsets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_1_fallThroughAddr;
  wire _ftb_io_out_s2_full_pred_1_fallThroughErr;
  wire _ftb_io_out_s2_full_pred_1_is_jal;
  wire _ftb_io_out_s2_full_pred_1_is_jalr;
  wire _ftb_io_out_s2_full_pred_1_is_call;
  wire _ftb_io_out_s2_full_pred_1_is_ret;
  wire _ftb_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire _ftb_io_out_s2_full_pred_1_is_br_sharing;
  wire _ftb_io_out_s2_full_pred_1_hit;
  wire _ftb_io_out_s2_full_pred_2_br_taken_mask_0;
  wire _ftb_io_out_s2_full_pred_2_br_taken_mask_1;
  wire _ftb_io_out_s2_full_pred_2_slot_valids_0;
  wire _ftb_io_out_s2_full_pred_2_slot_valids_1;
  wire [49:0] _ftb_io_out_s2_full_pred_2_targets_0;
  wire [49:0] _ftb_io_out_s2_full_pred_2_targets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_2_jalr_target;
  wire [3:0] _ftb_io_out_s2_full_pred_2_offsets_0;
  wire [3:0] _ftb_io_out_s2_full_pred_2_offsets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_2_fallThroughAddr;
  wire _ftb_io_out_s2_full_pred_2_fallThroughErr;
  wire _ftb_io_out_s2_full_pred_2_is_jal;
  wire _ftb_io_out_s2_full_pred_2_is_jalr;
  wire _ftb_io_out_s2_full_pred_2_is_call;
  wire _ftb_io_out_s2_full_pred_2_is_ret;
  wire _ftb_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire _ftb_io_out_s2_full_pred_2_is_br_sharing;
  wire _ftb_io_out_s2_full_pred_2_hit;
  wire _ftb_io_out_s2_full_pred_3_br_taken_mask_0;
  wire _ftb_io_out_s2_full_pred_3_br_taken_mask_1;
  wire _ftb_io_out_s2_full_pred_3_slot_valids_0;
  wire _ftb_io_out_s2_full_pred_3_slot_valids_1;
  wire [49:0] _ftb_io_out_s2_full_pred_3_targets_0;
  wire [49:0] _ftb_io_out_s2_full_pred_3_targets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_3_jalr_target;
  wire [3:0] _ftb_io_out_s2_full_pred_3_offsets_0;
  wire [3:0] _ftb_io_out_s2_full_pred_3_offsets_1;
  wire [49:0] _ftb_io_out_s2_full_pred_3_fallThroughAddr;
  wire _ftb_io_out_s2_full_pred_3_fallThroughErr;
  wire _ftb_io_out_s2_full_pred_3_is_jal;
  wire _ftb_io_out_s2_full_pred_3_is_jalr;
  wire _ftb_io_out_s2_full_pred_3_is_call;
  wire _ftb_io_out_s2_full_pred_3_is_ret;
  wire _ftb_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire _ftb_io_out_s2_full_pred_3_is_br_sharing;
  wire _ftb_io_out_s2_full_pred_3_hit;
  wire _ftb_io_out_s3_full_pred_0_br_taken_mask_0;
  wire _ftb_io_out_s3_full_pred_0_br_taken_mask_1;
  wire _ftb_io_out_s3_full_pred_0_slot_valids_0;
  wire _ftb_io_out_s3_full_pred_0_slot_valids_1;
  wire [49:0] _ftb_io_out_s3_full_pred_0_targets_0;
  wire [49:0] _ftb_io_out_s3_full_pred_0_targets_1;
  wire [3:0] _ftb_io_out_s3_full_pred_0_offsets_0;
  wire [3:0] _ftb_io_out_s3_full_pred_0_offsets_1;
  wire [49:0] _ftb_io_out_s3_full_pred_0_fallThroughAddr;
  wire _ftb_io_out_s3_full_pred_0_fallThroughErr;
  wire _ftb_io_out_s3_full_pred_0_multiHit;
  wire _ftb_io_out_s3_full_pred_0_is_jal;
  wire _ftb_io_out_s3_full_pred_0_is_jalr;
  wire _ftb_io_out_s3_full_pred_0_is_call;
  wire _ftb_io_out_s3_full_pred_0_is_ret;
  wire _ftb_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire _ftb_io_out_s3_full_pred_0_is_br_sharing;
  wire _ftb_io_out_s3_full_pred_0_hit;
  wire _ftb_io_out_s3_full_pred_1_br_taken_mask_0;
  wire _ftb_io_out_s3_full_pred_1_br_taken_mask_1;
  wire _ftb_io_out_s3_full_pred_1_slot_valids_0;
  wire _ftb_io_out_s3_full_pred_1_slot_valids_1;
  wire [49:0] _ftb_io_out_s3_full_pred_1_targets_0;
  wire [49:0] _ftb_io_out_s3_full_pred_1_targets_1;
  wire [3:0] _ftb_io_out_s3_full_pred_1_offsets_0;
  wire [3:0] _ftb_io_out_s3_full_pred_1_offsets_1;
  wire [49:0] _ftb_io_out_s3_full_pred_1_fallThroughAddr;
  wire _ftb_io_out_s3_full_pred_1_fallThroughErr;
  wire _ftb_io_out_s3_full_pred_1_multiHit;
  wire _ftb_io_out_s3_full_pred_1_is_jal;
  wire _ftb_io_out_s3_full_pred_1_is_jalr;
  wire _ftb_io_out_s3_full_pred_1_is_call;
  wire _ftb_io_out_s3_full_pred_1_is_ret;
  wire _ftb_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire _ftb_io_out_s3_full_pred_1_is_br_sharing;
  wire _ftb_io_out_s3_full_pred_1_hit;
  wire _ftb_io_out_s3_full_pred_2_br_taken_mask_0;
  wire _ftb_io_out_s3_full_pred_2_br_taken_mask_1;
  wire _ftb_io_out_s3_full_pred_2_slot_valids_0;
  wire _ftb_io_out_s3_full_pred_2_slot_valids_1;
  wire [49:0] _ftb_io_out_s3_full_pred_2_targets_0;
  wire [49:0] _ftb_io_out_s3_full_pred_2_targets_1;
  wire [3:0] _ftb_io_out_s3_full_pred_2_offsets_0;
  wire [3:0] _ftb_io_out_s3_full_pred_2_offsets_1;
  wire [49:0] _ftb_io_out_s3_full_pred_2_fallThroughAddr;
  wire _ftb_io_out_s3_full_pred_2_fallThroughErr;
  wire _ftb_io_out_s3_full_pred_2_multiHit;
  wire _ftb_io_out_s3_full_pred_2_is_jal;
  wire _ftb_io_out_s3_full_pred_2_is_jalr;
  wire _ftb_io_out_s3_full_pred_2_is_call;
  wire _ftb_io_out_s3_full_pred_2_is_ret;
  wire _ftb_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire _ftb_io_out_s3_full_pred_2_is_br_sharing;
  wire _ftb_io_out_s3_full_pred_2_hit;
  wire _ftb_io_out_s3_full_pred_3_br_taken_mask_0;
  wire _ftb_io_out_s3_full_pred_3_br_taken_mask_1;
  wire _ftb_io_out_s3_full_pred_3_slot_valids_0;
  wire _ftb_io_out_s3_full_pred_3_slot_valids_1;
  wire [49:0] _ftb_io_out_s3_full_pred_3_targets_0;
  wire [49:0] _ftb_io_out_s3_full_pred_3_targets_1;
  wire [3:0] _ftb_io_out_s3_full_pred_3_offsets_0;
  wire [3:0] _ftb_io_out_s3_full_pred_3_offsets_1;
  wire [49:0] _ftb_io_out_s3_full_pred_3_fallThroughAddr;
  wire _ftb_io_out_s3_full_pred_3_fallThroughErr;
  wire _ftb_io_out_s3_full_pred_3_multiHit;
  wire _ftb_io_out_s3_full_pred_3_is_jal;
  wire _ftb_io_out_s3_full_pred_3_is_jalr;
  wire _ftb_io_out_s3_full_pred_3_is_call;
  wire _ftb_io_out_s3_full_pred_3_is_ret;
  wire _ftb_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire _ftb_io_out_s3_full_pred_3_is_br_sharing;
  wire _ftb_io_out_s3_full_pred_3_hit;
  wire _ftb_io_out_s1_uftbHit;
  wire _ftb_io_out_s1_uftbHasIndirect;
  wire _ftb_io_out_s1_ftbCloseReq;
  wire [515:0] _ftb_io_out_last_stage_meta;
  wire _ftb_io_out_last_stage_spec_info_sc_disagree_0;
  wire _ftb_io_out_last_stage_spec_info_sc_disagree_1;
  wire _ftb_io_out_last_stage_ftb_entry_isCall;
  wire _ftb_io_out_last_stage_ftb_entry_isRet;
  wire _ftb_io_out_last_stage_ftb_entry_isJalr;
  wire _ftb_io_out_last_stage_ftb_entry_valid;
  wire [3:0] _ftb_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire _ftb_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire _ftb_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0] _ftb_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0] _ftb_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0] _ftb_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire _ftb_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire _ftb_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0] _ftb_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0] _ftb_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0] _ftb_io_out_last_stage_ftb_entry_pftAddr;
  wire _ftb_io_out_last_stage_ftb_entry_carry;
  wire _ftb_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire _ftb_io_out_last_stage_ftb_entry_strong_bias_0;
  wire _ftb_io_out_last_stage_ftb_entry_strong_bias_1;
  wire _ftb_io_s1_ready;
  wire [5:0] _ftb_io_perf_0_value;
  wire [5:0] _ftb_io_perf_1_value;

  FTB_xs ftb (
    .clock                                                   (clock),
    .reset                                                   (reset),
    .io_reset_vector                                         (io_reset_vector),
    .io_in_bits_s0_pc_0                                      (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                      (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                      (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                      (io_in_bits_s0_pc_3),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0
      (_tage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1
      (_tage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0
      (_tage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1
      (_tage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0
      (_tage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1
      (_tage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0
      (_tage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1
      (_tage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0
      (_tage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1
      (_tage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0
      (_tage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1
      (_tage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0
      (_tage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1
      (_tage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0
      (_tage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1
      (_tage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0
      (_tage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1
      (_tage_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_s2_full_pred_0_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0
      (_ftb_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1
      (_ftb_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0
      (_ftb_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1
      (_ftb_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target
      (_ftb_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0
      (_ftb_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1
      (_ftb_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr
      (_ftb_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr
      (_ftb_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal
      (_ftb_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr
      (_ftb_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call
      (_ftb_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret
      (_ftb_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing
      (_ftb_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit
      (_ftb_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0
      (_ftb_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1
      (_ftb_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0
      (_ftb_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1
      (_ftb_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target
      (_ftb_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0
      (_ftb_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1
      (_ftb_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr
      (_ftb_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr
      (_ftb_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal
      (_ftb_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr
      (_ftb_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call
      (_ftb_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret
      (_ftb_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing
      (_ftb_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit
      (_ftb_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0
      (_ftb_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1
      (_ftb_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0
      (_ftb_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1
      (_ftb_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target
      (_ftb_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0
      (_ftb_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1
      (_ftb_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr
      (_ftb_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr
      (_ftb_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal
      (_ftb_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr
      (_ftb_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call
      (_ftb_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret
      (_ftb_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing
      (_ftb_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit
      (_ftb_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0
      (_ftb_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1
      (_ftb_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0
      (_ftb_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1
      (_ftb_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target
      (_ftb_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0
      (_ftb_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1
      (_ftb_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr
      (_ftb_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr
      (_ftb_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal
      (_ftb_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr
      (_ftb_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call
      (_ftb_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret
      (_ftb_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing
      (_ftb_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit
      (_ftb_io_out_s2_full_pred_3_hit),
    .io_out_s3_full_pred_0_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0
      (_ftb_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1
      (_ftb_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0
      (_ftb_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1
      (_ftb_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_offsets_0
      (_ftb_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1
      (_ftb_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr
      (_ftb_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr
      (_ftb_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit
      (_ftb_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal
      (_ftb_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr
      (_ftb_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call
      (_ftb_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret
      (_ftb_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing
      (_ftb_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit
      (_ftb_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0
      (_ftb_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1
      (_ftb_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0
      (_ftb_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1
      (_ftb_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_offsets_0
      (_ftb_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1
      (_ftb_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr
      (_ftb_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr
      (_ftb_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit
      (_ftb_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal
      (_ftb_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr
      (_ftb_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call
      (_ftb_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret
      (_ftb_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing
      (_ftb_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit
      (_ftb_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0
      (_ftb_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1
      (_ftb_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0
      (_ftb_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1
      (_ftb_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_offsets_0
      (_ftb_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1
      (_ftb_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr
      (_ftb_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr
      (_ftb_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit
      (_ftb_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal
      (_ftb_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr
      (_ftb_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call
      (_ftb_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret
      (_ftb_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing
      (_ftb_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit
      (_ftb_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0
      (_ftb_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1
      (_ftb_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0
      (_ftb_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1
      (_ftb_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_offsets_0
      (_ftb_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1
      (_ftb_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr
      (_ftb_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr
      (_ftb_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit
      (_ftb_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal
      (_ftb_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr
      (_ftb_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call
      (_ftb_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret
      (_ftb_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing
      (_ftb_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit
      (_ftb_io_out_s3_full_pred_3_hit),
    .io_out_s1_uftbHit                                       (_ftb_io_out_s1_uftbHit),
    .io_out_s1_uftbHasIndirect
      (_ftb_io_out_s1_uftbHasIndirect),
    .io_out_s1_ftbCloseReq                                   (_ftb_io_out_s1_ftbCloseReq),
    .io_out_last_stage_meta
      (_ftb_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0
      (_ftb_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1
      (_ftb_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall
      (_ftb_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet
      (_ftb_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr
      (_ftb_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid
      (_ftb_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr
      (_ftb_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry
      (_ftb_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call
      (_ftb_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0
      (_ftb_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1
      (_ftb_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_fauftb_entry_in_isCall
      (_uftb_io_fauftb_entry_out_isCall),
    .io_fauftb_entry_in_isRet
      (_uftb_io_fauftb_entry_out_isRet),
    .io_fauftb_entry_in_isJalr
      (_uftb_io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_in_valid
      (_uftb_io_fauftb_entry_out_valid),
    .io_fauftb_entry_in_brSlots_0_offset
      (_uftb_io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_in_brSlots_0_sharing
      (_uftb_io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_in_brSlots_0_valid
      (_uftb_io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_in_brSlots_0_lower
      (_uftb_io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_in_brSlots_0_tarStat
      (_uftb_io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_in_tailSlot_offset
      (_uftb_io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_in_tailSlot_sharing
      (_uftb_io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_in_tailSlot_valid
      (_uftb_io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_in_tailSlot_lower
      (_uftb_io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_in_tailSlot_tarStat
      (_uftb_io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_in_pftAddr
      (_uftb_io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_in_carry
      (_uftb_io_fauftb_entry_out_carry),
    .io_fauftb_entry_in_last_may_be_rvi_call
      (_uftb_io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_in_strong_bias_0
      (_uftb_io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_in_strong_bias_1
      (_uftb_io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_in
      (_uftb_io_fauftb_entry_hit_out),
    .io_ctrl_btb_enable
      (_ftb_io_ctrl_delay_io_out_btb_enable),
    .io_s0_fire_0                                            (io_s0_fire_0),
    .io_s0_fire_1                                            (io_s0_fire_1),
    .io_s0_fire_2                                            (io_s0_fire_2),
    .io_s0_fire_3                                            (io_s0_fire_3),
    .io_s1_fire_0                                            (io_s1_fire_0),
    .io_s1_fire_1                                            (io_s1_fire_1),
    .io_s1_fire_2                                            (io_s1_fire_2),
    .io_s1_fire_3                                            (io_s1_fire_3),
    .io_s2_fire_0                                            (io_s2_fire_0),
    .io_s2_fire_1                                            (io_s2_fire_1),
    .io_s2_fire_2                                            (io_s2_fire_2),
    .io_s2_fire_3                                            (io_s2_fire_3),
    .io_s3_fire_0                                            (io_s3_fire_0),
    .io_s1_ready                                             (_ftb_io_s1_ready),
    .io_update_valid                                         (io_update_valid),
    .io_update_bits_pc                                       (io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall
      (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet
      (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr
      (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid
      (io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset
      (io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing
      (io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid
      (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower
      (io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat
      (io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset
      (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing
      (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid
      (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower
      (io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat
      (io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr
      (io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry
      (io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call
      (io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0
      (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1
      (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_false_hit                                (io_update_bits_false_hit),
    .io_update_bits_old_entry                                (io_update_bits_old_entry),
    .io_update_bits_meta
      ({192'h0, io_update_bits_meta[515:192]}),
    .io_redirectFromIFU                                      (io_redirectFromIFU),
    .io_perf_0_value                                         (_ftb_io_perf_0_value),
    .io_perf_1_value                                         (_ftb_io_perf_1_value),
    .boreChildrenBd_bore_array                               (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                                 (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                                 (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                                 (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen
      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                                  (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                                (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                              (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                              (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd
      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata
      (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold                              (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass
      (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken
      (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk
      (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp
      (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold
      (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                                  (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold
      (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass
      (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken
      (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk
      (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp
      (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold
      (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                                (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold
      (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass
      (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken
      (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk
      (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp
      (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold
      (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                                (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold
      (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass
      (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken
      (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk
      (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp
      (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold
      (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                                (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold
      (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass
      (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken
      (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk
      (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp
      (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold
      (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                                (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold
      (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass
      (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken
      (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk
      (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp
      (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold
      (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                                (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold
      (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass
      (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken
      (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk
      (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp
      (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold
      (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                                (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold
      (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass
      (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken
      (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk
      (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp
      (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold
      (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                                (sigFromSrams_bore_7_cgen)
  );

  FauFTB_xs uftb (
    .clock                                         (clock),
    .reset                                         (reset),
    .io_reset_vector                               (io_reset_vector),
    .io_in_bits_s0_pc_0                            (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                            (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                            (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                            (io_in_bits_s0_pc_3),
    .io_out_s1_pc_0                                (io_out_s1_pc_0),
    .io_out_s1_pc_1                                (io_out_s1_pc_1),
    .io_out_s1_pc_2                                (io_out_s1_pc_2),
    .io_out_s1_pc_3                                (io_out_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0
      (io_out_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1
      (io_out_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0           (io_out_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1           (io_out_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0               (io_out_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1               (io_out_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target             (io_out_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0               (io_out_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1               (io_out_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr
      (io_out_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr          (io_out_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal                  (io_out_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr                 (io_out_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call                 (io_out_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret                  (io_out_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call
      (io_out_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing           (io_out_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit                     (io_out_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0
      (io_out_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1
      (io_out_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0           (io_out_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1           (io_out_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0               (io_out_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1               (io_out_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target             (io_out_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0               (io_out_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1               (io_out_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr
      (io_out_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr          (io_out_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal                  (io_out_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr                 (io_out_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call                 (io_out_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret                  (io_out_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call
      (io_out_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing           (io_out_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit                     (io_out_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0
      (io_out_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1
      (io_out_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0           (io_out_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1           (io_out_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0               (io_out_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1               (io_out_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target             (io_out_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0               (io_out_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1               (io_out_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr
      (io_out_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr          (io_out_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal                  (io_out_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr                 (io_out_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call                 (io_out_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret                  (io_out_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call
      (io_out_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing           (io_out_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit                     (io_out_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0
      (io_out_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1
      (io_out_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0           (io_out_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1           (io_out_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0               (io_out_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1               (io_out_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target             (io_out_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0               (io_out_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1               (io_out_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr
      (io_out_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr          (io_out_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal                  (io_out_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr                 (io_out_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call                 (io_out_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret                  (io_out_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call
      (io_out_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing           (io_out_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit                     (io_out_s1_full_pred_3_hit),
    .io_out_last_stage_meta                        (_uftb_io_out_last_stage_meta),
    .io_fauftb_entry_out_isCall                    (_uftb_io_fauftb_entry_out_isCall),
    .io_fauftb_entry_out_isRet                     (_uftb_io_fauftb_entry_out_isRet),
    .io_fauftb_entry_out_isJalr                    (_uftb_io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_out_valid                     (_uftb_io_fauftb_entry_out_valid),
    .io_fauftb_entry_out_brSlots_0_offset
      (_uftb_io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_out_brSlots_0_sharing
      (_uftb_io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_out_brSlots_0_valid
      (_uftb_io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_out_brSlots_0_lower
      (_uftb_io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_out_brSlots_0_tarStat
      (_uftb_io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_out_tailSlot_offset
      (_uftb_io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_out_tailSlot_sharing
      (_uftb_io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_out_tailSlot_valid
      (_uftb_io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_out_tailSlot_lower
      (_uftb_io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_out_tailSlot_tarStat
      (_uftb_io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_out_pftAddr                   (_uftb_io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_out_carry                     (_uftb_io_fauftb_entry_out_carry),
    .io_fauftb_entry_out_last_may_be_rvi_call
      (_uftb_io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_out_strong_bias_0
      (_uftb_io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_out_strong_bias_1
      (_uftb_io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_out                       (_uftb_io_fauftb_entry_hit_out),
    .io_ctrl_ubtb_enable
      (_uftb_io_ctrl_delay_io_out_ubtb_enable),
    .io_s0_fire_0                                  (io_s0_fire_0),
    .io_s0_fire_1                                  (io_s0_fire_1),
    .io_s0_fire_2                                  (io_s0_fire_2),
    .io_s0_fire_3                                  (io_s0_fire_3),
    .io_s1_fire_0                                  (io_s1_fire_0),
    .io_s1_fire_1                                  (io_s1_fire_1),
    .io_s1_fire_2                                  (io_s1_fire_2),
    .io_s1_fire_3                                  (io_s1_fire_3),
    .io_s2_fire_0                                  (io_s2_fire_0),
    .io_s2_fire_1                                  (io_s2_fire_1),
    .io_s2_fire_2                                  (io_s2_fire_2),
    .io_s2_fire_3                                  (io_s2_fire_3),
    .io_update_valid                               (io_update_valid),
    .io_update_bits_pc                             (io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall               (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet                (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr               (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid                (io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset
      (io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing
      (io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid
      (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower
      (io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat
      (io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset
      (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing
      (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid
      (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower
      (io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat
      (io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr              (io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry                (io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call
      (io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0
      (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1
      (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0                (io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1                (io_update_bits_br_taken_mask_1),
    .io_update_bits_meta
      ({403'h0, io_update_bits_meta[515:403]}),
    .io_perf_0_value                               (_uftb_io_perf_0_value),
    .io_perf_1_value                               (_uftb_io_perf_1_value)
  );

  Tage_SC_xs tage (
    .clock                                        (clock),
    .reset                                        (reset),
    .io_reset_vector                              (io_reset_vector),
    .io_in_bits_s0_pc_0                           (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                           (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                           (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                           (io_in_bits_s0_pc_3),
    .io_in_bits_folded_hist_1_hist_17_folded_hist
      (io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_in_bits_folded_hist_1_hist_16_folded_hist
      (io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_in_bits_folded_hist_1_hist_15_folded_hist
      (io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_in_bits_folded_hist_1_hist_14_folded_hist
      (io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_in_bits_folded_hist_1_hist_9_folded_hist
      (io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_in_bits_folded_hist_1_hist_8_folded_hist
      (io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_in_bits_folded_hist_1_hist_7_folded_hist
      (io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_in_bits_folded_hist_1_hist_5_folded_hist
      (io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_in_bits_folded_hist_1_hist_4_folded_hist
      (io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_in_bits_folded_hist_1_hist_3_folded_hist
      (io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_in_bits_folded_hist_1_hist_1_folded_hist
      (io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_in_bits_folded_hist_3_hist_12_folded_hist
      (io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_folded_hist_3_hist_11_folded_hist
      (io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_in_bits_folded_hist_3_hist_2_folded_hist
      (io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_ghist                             (io_in_bits_ghist),
    .io_out_s2_full_pred_0_br_taken_mask_0
      (_tage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1
      (_tage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_1_br_taken_mask_0
      (_tage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1
      (_tage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_2_br_taken_mask_0
      (_tage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1
      (_tage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_3_br_taken_mask_0
      (_tage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1
      (_tage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_0_br_taken_mask_0
      (_tage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1
      (_tage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_1_br_taken_mask_0
      (_tage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1
      (_tage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_2_br_taken_mask_0
      (_tage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1
      (_tage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_3_br_taken_mask_0
      (_tage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1
      (_tage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_last_stage_meta                       (_tage_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0
      (_tage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1
      (_tage_io_out_last_stage_spec_info_sc_disagree_1),
    .io_ctrl_tage_enable
      (_tage_io_ctrl_delay_io_out_tage_enable),
    .io_ctrl_sc_enable                            (_tage_io_ctrl_delay_io_out_sc_enable),
    .io_s0_fire_0                                 (io_s0_fire_0),
    .io_s0_fire_1                                 (io_s0_fire_1),
    .io_s0_fire_2                                 (io_s0_fire_2),
    .io_s0_fire_3                                 (io_s0_fire_3),
    .io_s1_fire_0                                 (io_s1_fire_0),
    .io_s1_fire_1                                 (io_s1_fire_1),
    .io_s1_fire_2                                 (io_s1_fire_2),
    .io_s1_fire_3                                 (io_s1_fire_3),
    .io_s2_fire_0                                 (io_s2_fire_0),
    .io_s2_fire_1                                 (io_s2_fire_1),
    .io_s2_fire_2                                 (io_s2_fire_2),
    .io_s2_fire_3                                 (io_s2_fire_3),
    .io_s1_ready                                  (_tage_io_s1_ready),
    .io_update_valid                              (io_update_valid),
    .io_update_bits_pc                            (io_update_bits_pc),
    .io_update_bits_ftb_entry_brSlots_0_valid
      (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_tailSlot_sharing
      (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid
      (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_strong_bias_0
      (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1
      (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0               (io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1               (io_update_bits_br_taken_mask_1),
    .io_update_bits_mispred_mask_0                (io_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1                (io_update_bits_mispred_mask_1),
    .io_update_bits_meta
      ({259'h0, io_update_bits_meta[515:259]}),
    .io_update_bits_ghist                         (io_update_bits_ghist),
    .io_perf_0_value                              (_tage_io_perf_0_value),
    .io_perf_1_value                              (_tage_io_perf_1_value),
    .io_perf_2_value                              (_tage_io_perf_2_value),
    .boreChildrenBd_bore_array                    (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all                      (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req                      (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack                      (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen                  (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be                       (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr                     (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata                   (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen                   (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd                  (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata                  (boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_1_array                  (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_1_all                    (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_1_req                    (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_1_ack                    (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_1_writeen                (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_1_be                     (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_1_addr                   (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_1_indata                 (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_1_readen                 (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_1_addr_rd                (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_1_outdata                (boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_2_array                  (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_2_all                    (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_2_req                    (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_2_ack                    (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_2_writeen                (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_2_be                     (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_2_addr                   (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_2_indata                 (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_2_readen                 (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_2_addr_rd                (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_2_outdata                (boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_3_array                  (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_3_all                    (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_3_req                    (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_3_ack                    (boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_3_writeen                (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_3_be                     (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_3_addr                   (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_3_indata                 (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_3_readen                 (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_3_addr_rd                (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_3_outdata                (boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_4_array                  (boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_4_all                    (boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_4_req                    (boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_4_ack                    (boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_4_writeen                (boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_4_be                     (boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_4_addr                   (boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_4_indata                 (boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_4_readen                 (boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_4_addr_rd                (boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_4_outdata                (boreChildrenBd_bore_5_outdata),
    .sigFromSrams_bore_ram_hold                   (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_ram_bypass                 (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken               (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp               (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold               (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_cgen                       (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_1_ram_hold                 (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_1_ram_bypass               (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken             (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk              (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp             (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold             (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                     (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_2_ram_hold                 (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_2_ram_bypass               (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken             (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk              (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp             (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold             (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                     (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_3_ram_hold                 (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_3_ram_bypass               (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken             (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk              (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp             (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold             (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                     (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_4_ram_hold                 (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_4_ram_bypass               (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken             (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk              (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp             (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold             (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                     (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_5_ram_hold                 (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_5_ram_bypass               (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken             (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk              (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp             (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold             (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                     (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_6_ram_hold                 (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_6_ram_bypass               (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken             (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk              (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp             (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold             (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                     (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_7_ram_hold                 (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_7_ram_bypass               (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken             (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk              (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp             (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold             (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                     (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_8_ram_hold                 (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_8_ram_bypass               (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken             (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk              (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp             (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold             (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                     (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_9_ram_hold                 (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_9_ram_bypass               (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken             (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk              (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp             (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold             (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                     (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_10_ram_hold                (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_10_ram_bypass              (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken            (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk             (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp            (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold            (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                    (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_11_ram_hold                (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_11_ram_bypass              (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken            (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk             (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp            (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold            (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                    (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_12_ram_hold                (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_12_ram_bypass              (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken            (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk             (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp            (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold            (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                    (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_13_ram_hold                (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_13_ram_bypass              (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken            (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk             (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp            (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold            (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                    (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_14_ram_hold                (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_14_ram_bypass              (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken            (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk             (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp            (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold            (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                    (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_15_ram_hold                (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_15_ram_bypass              (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken            (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk             (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp            (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold            (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                    (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_16_ram_hold                (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_16_ram_bypass              (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken            (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk             (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp            (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold            (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                    (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_17_ram_hold                (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_17_ram_bypass              (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken            (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk             (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp            (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold            (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen                    (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_18_ram_hold                (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_18_ram_bypass              (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken            (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk             (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp            (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold            (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen                    (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_19_ram_hold                (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_19_ram_bypass              (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken            (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk             (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp            (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold            (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen                    (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_20_ram_hold                (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_20_ram_bypass              (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken            (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk             (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp            (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold            (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen                    (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_21_ram_hold                (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_21_ram_bypass              (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken            (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk             (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp            (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold            (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen                    (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_22_ram_hold                (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_22_ram_bypass              (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken            (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk             (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp            (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold            (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen                    (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_23_ram_hold                (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_23_ram_bypass              (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken            (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk             (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp            (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold            (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen                    (sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_24_ram_hold                (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_24_ram_bypass              (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken            (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk             (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp            (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold            (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen                    (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_25_ram_hold                (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_25_ram_bypass              (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken            (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk             (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp            (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold            (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen                    (sigFromSrams_bore_33_cgen)
  );

  RAS_it ras (
    .clock                                                          (clock),
    .reset                                                          (reset),
    .io_reset_vector                                                (io_reset_vector),
    .io_in_bits_s0_pc_0                                             (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                             (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                             (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                             (io_in_bits_s0_pc_3),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0
      (_ittage_io_out_s2_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1
      (_ittage_io_out_s2_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_0
      (_ittage_io_out_s2_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_1
      (_ittage_io_out_s2_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target
      (_ittage_io_out_s2_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0
      (_ittage_io_out_s2_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1
      (_ittage_io_out_s2_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr
      (_ittage_io_out_s2_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr
      (_ittage_io_out_s2_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jal
      (_ittage_io_out_s2_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr
      (_ittage_io_out_s2_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_call
      (_ittage_io_out_s2_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_ret
      (_ittage_io_out_s2_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing
      (_ittage_io_out_s2_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_0_hit
      (_ittage_io_out_s2_full_pred_0_hit),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0
      (_ittage_io_out_s2_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1
      (_ittage_io_out_s2_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_0
      (_ittage_io_out_s2_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_1
      (_ittage_io_out_s2_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target
      (_ittage_io_out_s2_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0
      (_ittage_io_out_s2_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1
      (_ittage_io_out_s2_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr
      (_ittage_io_out_s2_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr
      (_ittage_io_out_s2_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jal
      (_ittage_io_out_s2_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr
      (_ittage_io_out_s2_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_call
      (_ittage_io_out_s2_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_ret
      (_ittage_io_out_s2_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing
      (_ittage_io_out_s2_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_1_hit
      (_ittage_io_out_s2_full_pred_1_hit),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0
      (_ittage_io_out_s2_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1
      (_ittage_io_out_s2_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_0
      (_ittage_io_out_s2_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_1
      (_ittage_io_out_s2_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target
      (_ittage_io_out_s2_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0
      (_ittage_io_out_s2_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1
      (_ittage_io_out_s2_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr
      (_ittage_io_out_s2_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr
      (_ittage_io_out_s2_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jal
      (_ittage_io_out_s2_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr
      (_ittage_io_out_s2_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_call
      (_ittage_io_out_s2_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_ret
      (_ittage_io_out_s2_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing
      (_ittage_io_out_s2_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_2_hit
      (_ittage_io_out_s2_full_pred_2_hit),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0
      (_ittage_io_out_s2_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1
      (_ittage_io_out_s2_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_0
      (_ittage_io_out_s2_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_1
      (_ittage_io_out_s2_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target
      (_ittage_io_out_s2_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0
      (_ittage_io_out_s2_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1
      (_ittage_io_out_s2_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr
      (_ittage_io_out_s2_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr
      (_ittage_io_out_s2_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jal
      (_ittage_io_out_s2_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr
      (_ittage_io_out_s2_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_call
      (_ittage_io_out_s2_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_ret
      (_ittage_io_out_s2_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing
      (_ittage_io_out_s2_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_3_hit
      (_ittage_io_out_s2_full_pred_3_hit),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0
      (_ittage_io_out_s3_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1
      (_ittage_io_out_s3_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_0
      (_ittage_io_out_s3_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_1
      (_ittage_io_out_s3_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_jalr_target
      (_ittage_io_out_s3_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0
      (_ittage_io_out_s3_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1
      (_ittage_io_out_s3_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr
      (_ittage_io_out_s3_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr
      (_ittage_io_out_s3_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_0_multiHit
      (_ittage_io_out_s3_full_pred_0_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jal
      (_ittage_io_out_s3_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr
      (_ittage_io_out_s3_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_call
      (_ittage_io_out_s3_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_ret
      (_ittage_io_out_s3_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing
      (_ittage_io_out_s3_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_0_hit
      (_ittage_io_out_s3_full_pred_0_hit),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0
      (_ittage_io_out_s3_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1
      (_ittage_io_out_s3_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_0
      (_ittage_io_out_s3_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_1
      (_ittage_io_out_s3_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_jalr_target
      (_ittage_io_out_s3_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0
      (_ittage_io_out_s3_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1
      (_ittage_io_out_s3_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr
      (_ittage_io_out_s3_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr
      (_ittage_io_out_s3_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_1_multiHit
      (_ittage_io_out_s3_full_pred_1_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jal
      (_ittage_io_out_s3_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr
      (_ittage_io_out_s3_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_call
      (_ittage_io_out_s3_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_ret
      (_ittage_io_out_s3_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing
      (_ittage_io_out_s3_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_1_hit
      (_ittage_io_out_s3_full_pred_1_hit),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0
      (_ittage_io_out_s3_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1
      (_ittage_io_out_s3_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_0
      (_ittage_io_out_s3_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_1
      (_ittage_io_out_s3_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_jalr_target
      (_ittage_io_out_s3_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0
      (_ittage_io_out_s3_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1
      (_ittage_io_out_s3_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr
      (_ittage_io_out_s3_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr
      (_ittage_io_out_s3_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_2_multiHit
      (_ittage_io_out_s3_full_pred_2_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jal
      (_ittage_io_out_s3_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr
      (_ittage_io_out_s3_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_call
      (_ittage_io_out_s3_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_ret
      (_ittage_io_out_s3_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing
      (_ittage_io_out_s3_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_2_hit
      (_ittage_io_out_s3_full_pred_2_hit),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0
      (_ittage_io_out_s3_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1
      (_ittage_io_out_s3_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_0
      (_ittage_io_out_s3_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_1
      (_ittage_io_out_s3_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_jalr_target
      (_ittage_io_out_s3_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0
      (_ittage_io_out_s3_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1
      (_ittage_io_out_s3_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr
      (_ittage_io_out_s3_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr
      (_ittage_io_out_s3_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_3_multiHit
      (_ittage_io_out_s3_full_pred_3_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jal
      (_ittage_io_out_s3_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr
      (_ittage_io_out_s3_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_call
      (_ittage_io_out_s3_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_ret
      (_ittage_io_out_s3_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing
      (_ittage_io_out_s3_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_3_hit
      (_ittage_io_out_s3_full_pred_3_hit),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0
      (_ittage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1
      (_ittage_io_out_last_stage_spec_info_sc_disagree_1),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall
      (_ittage_io_out_last_stage_ftb_entry_isCall),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet
      (_ittage_io_out_last_stage_ftb_entry_isRet),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr
      (_ittage_io_out_last_stage_ftb_entry_isJalr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_valid
      (_ittage_io_out_last_stage_ftb_entry_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr
      (_ittage_io_out_last_stage_ftb_entry_pftAddr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_carry
      (_ittage_io_out_last_stage_ftb_entry_carry),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call
      (_ittage_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0
      (_ittage_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1
      (_ittage_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_out_s2_pc_0                                                 (io_out_s2_pc_0),
    .io_out_s2_pc_1                                                 (io_out_s2_pc_1),
    .io_out_s2_pc_2                                                 (io_out_s2_pc_2),
    .io_out_s2_pc_3                                                 (io_out_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0
      (io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1
      (io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0
      (io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1
      (io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0
      (io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1
      (io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target
      (io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0
      (io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1
      (io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr
      (io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr
      (io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal
      (io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr
      (io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call
      (io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret
      (io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call
      (io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing
      (io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit
      (io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0
      (io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1
      (io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0
      (io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1
      (io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0
      (io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1
      (io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target
      (io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0
      (io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1
      (io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr
      (io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr
      (io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal
      (io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr
      (io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call
      (io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret
      (io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call
      (io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing
      (io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit
      (io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0
      (io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1
      (io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0
      (io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1
      (io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0
      (io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1
      (io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target
      (io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0
      (io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1
      (io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr
      (io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr
      (io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal
      (io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr
      (io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call
      (io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret
      (io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call
      (io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing
      (io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit
      (io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0
      (io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1
      (io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0
      (io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1
      (io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0
      (io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1
      (io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target
      (io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0
      (io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1
      (io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr
      (io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr
      (io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal
      (io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr
      (io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call
      (io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret
      (io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call
      (io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing
      (io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit
      (io_out_s2_full_pred_3_hit),
    .io_out_s3_pc_0                                                 (io_out_s3_pc_0),
    .io_out_s3_pc_1                                                 (io_out_s3_pc_1),
    .io_out_s3_pc_2                                                 (io_out_s3_pc_2),
    .io_out_s3_pc_3                                                 (io_out_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0
      (io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1
      (io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0
      (io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1
      (io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0
      (io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1
      (io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target
      (io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0
      (io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1
      (io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr
      (io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr
      (io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit
      (io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal
      (io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr
      (io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call
      (io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret
      (io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call
      (io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing
      (io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit
      (io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0
      (io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1
      (io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0
      (io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1
      (io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0
      (io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1
      (io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target
      (io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0
      (io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1
      (io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr
      (io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr
      (io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit
      (io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal
      (io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr
      (io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call
      (io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret
      (io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call
      (io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing
      (io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit
      (io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0
      (io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1
      (io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0
      (io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1
      (io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0
      (io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1
      (io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target
      (io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0
      (io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1
      (io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr
      (io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr
      (io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit
      (io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal
      (io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr
      (io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call
      (io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret
      (io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call
      (io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing
      (io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit
      (io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0
      (io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1
      (io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0
      (io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1
      (io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0
      (io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1
      (io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target
      (io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0
      (io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1
      (io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr
      (io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr
      (io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit
      (io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal
      (io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr
      (io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call
      (io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret
      (io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call
      (io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing
      (io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit
      (io_out_s3_full_pred_3_hit),
    .io_out_last_stage_meta
      (_ras_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_ssp
      (io_out_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr
      (io_out_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag
      (io_out_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value
      (io_out_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag
      (io_out_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value
      (io_out_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag
      (io_out_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value
      (io_out_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr
      (io_out_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0
      (io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1
      (io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall
      (io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet
      (io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr
      (io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid
      (io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset
      (io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing
      (io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid
      (io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower
      (io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat
      (io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset
      (io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing
      (io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid
      (io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower
      (io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat
      (io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr
      (io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry
      (io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call
      (io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0
      (io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1
      (io_out_last_stage_ftb_entry_strong_bias_1),
    .io_ctrl_ras_enable
      (_ras_io_ctrl_delay_io_out_ras_enable),
    .io_s0_fire_0                                                   (io_s0_fire_0),
    .io_s0_fire_1                                                   (io_s0_fire_1),
    .io_s0_fire_2                                                   (io_s0_fire_2),
    .io_s0_fire_3                                                   (io_s0_fire_3),
    .io_s1_fire_0                                                   (io_s1_fire_0),
    .io_s1_fire_1                                                   (io_s1_fire_1),
    .io_s1_fire_2                                                   (io_s1_fire_2),
    .io_s1_fire_3                                                   (io_s1_fire_3),
    .io_s2_fire_0                                                   (io_s2_fire_0),
    .io_s2_fire_1                                                   (io_s2_fire_1),
    .io_s2_fire_2                                                   (io_s2_fire_2),
    .io_s2_fire_3                                                   (io_s2_fire_3),
    .io_s3_fire_2                                                   (io_s3_fire_2),
    .io_s3_redirect_2                                               (io_s3_redirect_2),
    .io_update_valid                                                (io_update_valid),
    .io_update_bits_ftb_entry_isCall
      (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet
      (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_tailSlot_offset
      (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_valid
      (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_cfi_idx_valid
      (io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits
      (io_update_bits_cfi_idx_bits),
    .io_update_bits_jmp_taken
      (io_update_bits_jmp_taken),
    .io_update_bits_meta                                            (io_update_bits_meta),
    .io_redirect_valid                                              (io_redirect_valid),
    .io_redirect_bits_level
      (io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_pc
      (io_redirect_bits_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid
      (io_redirect_bits_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC
      (io_redirect_bits_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall
      (io_redirect_bits_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet
      (io_redirect_bits_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp
      (io_redirect_bits_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr
      (io_redirect_bits_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag
      (io_redirect_bits_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value
      (io_redirect_bits_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag
      (io_redirect_bits_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value
      (io_redirect_bits_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag
      (io_redirect_bits_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value
      (io_redirect_bits_cfiUpdate_NOS_value)
  );

  ITTage_xs ittage (
    .clock                                                          (clock),
    .reset                                                          (reset),
    .io_reset_vector                                                (io_reset_vector),
    .io_in_bits_s0_pc_0                                             (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                             (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                             (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                             (io_in_bits_s0_pc_3),
    .io_in_bits_s1_folded_hist_3_hist_14_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_14_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_13_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_13_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_12_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_10_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_10_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_6_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_6_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_4_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_4_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_3_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_3_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_2_folded_hist
      (io_in_bits_s1_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0
      (_ftb_io_out_s2_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1
      (_ftb_io_out_s2_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_0
      (_ftb_io_out_s2_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_1
      (_ftb_io_out_s2_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target
      (_ftb_io_out_s2_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0
      (_ftb_io_out_s2_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1
      (_ftb_io_out_s2_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr
      (_ftb_io_out_s2_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr
      (_ftb_io_out_s2_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jal
      (_ftb_io_out_s2_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr
      (_ftb_io_out_s2_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_call
      (_ftb_io_out_s2_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_ret
      (_ftb_io_out_s2_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing
      (_ftb_io_out_s2_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_0_hit
      (_ftb_io_out_s2_full_pred_0_hit),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0
      (_ftb_io_out_s2_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1
      (_ftb_io_out_s2_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_0
      (_ftb_io_out_s2_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_1
      (_ftb_io_out_s2_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target
      (_ftb_io_out_s2_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0
      (_ftb_io_out_s2_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1
      (_ftb_io_out_s2_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr
      (_ftb_io_out_s2_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr
      (_ftb_io_out_s2_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jal
      (_ftb_io_out_s2_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr
      (_ftb_io_out_s2_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_call
      (_ftb_io_out_s2_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_ret
      (_ftb_io_out_s2_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing
      (_ftb_io_out_s2_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_1_hit
      (_ftb_io_out_s2_full_pred_1_hit),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0
      (_ftb_io_out_s2_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1
      (_ftb_io_out_s2_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_0
      (_ftb_io_out_s2_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_1
      (_ftb_io_out_s2_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target
      (_ftb_io_out_s2_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0
      (_ftb_io_out_s2_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1
      (_ftb_io_out_s2_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr
      (_ftb_io_out_s2_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr
      (_ftb_io_out_s2_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jal
      (_ftb_io_out_s2_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr
      (_ftb_io_out_s2_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_call
      (_ftb_io_out_s2_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_ret
      (_ftb_io_out_s2_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing
      (_ftb_io_out_s2_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_2_hit
      (_ftb_io_out_s2_full_pred_2_hit),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0
      (_ftb_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1
      (_ftb_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0
      (_ftb_io_out_s2_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1
      (_ftb_io_out_s2_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_0
      (_ftb_io_out_s2_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_1
      (_ftb_io_out_s2_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target
      (_ftb_io_out_s2_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0
      (_ftb_io_out_s2_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1
      (_ftb_io_out_s2_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr
      (_ftb_io_out_s2_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr
      (_ftb_io_out_s2_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jal
      (_ftb_io_out_s2_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr
      (_ftb_io_out_s2_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_call
      (_ftb_io_out_s2_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_ret
      (_ftb_io_out_s2_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call
      (_ftb_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing
      (_ftb_io_out_s2_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_3_hit
      (_ftb_io_out_s2_full_pred_3_hit),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0
      (_ftb_io_out_s3_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1
      (_ftb_io_out_s3_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_0
      (_ftb_io_out_s3_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_1
      (_ftb_io_out_s3_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0
      (_ftb_io_out_s3_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1
      (_ftb_io_out_s3_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr
      (_ftb_io_out_s3_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr
      (_ftb_io_out_s3_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_0_multiHit
      (_ftb_io_out_s3_full_pred_0_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jal
      (_ftb_io_out_s3_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr
      (_ftb_io_out_s3_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_call
      (_ftb_io_out_s3_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_ret
      (_ftb_io_out_s3_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing
      (_ftb_io_out_s3_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_0_hit
      (_ftb_io_out_s3_full_pred_0_hit),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0
      (_ftb_io_out_s3_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1
      (_ftb_io_out_s3_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_0
      (_ftb_io_out_s3_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_1
      (_ftb_io_out_s3_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0
      (_ftb_io_out_s3_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1
      (_ftb_io_out_s3_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr
      (_ftb_io_out_s3_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr
      (_ftb_io_out_s3_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_1_multiHit
      (_ftb_io_out_s3_full_pred_1_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jal
      (_ftb_io_out_s3_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr
      (_ftb_io_out_s3_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_call
      (_ftb_io_out_s3_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_ret
      (_ftb_io_out_s3_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing
      (_ftb_io_out_s3_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_1_hit
      (_ftb_io_out_s3_full_pred_1_hit),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0
      (_ftb_io_out_s3_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1
      (_ftb_io_out_s3_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_0
      (_ftb_io_out_s3_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_1
      (_ftb_io_out_s3_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0
      (_ftb_io_out_s3_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1
      (_ftb_io_out_s3_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr
      (_ftb_io_out_s3_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr
      (_ftb_io_out_s3_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_2_multiHit
      (_ftb_io_out_s3_full_pred_2_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jal
      (_ftb_io_out_s3_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr
      (_ftb_io_out_s3_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_call
      (_ftb_io_out_s3_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_ret
      (_ftb_io_out_s3_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing
      (_ftb_io_out_s3_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_2_hit
      (_ftb_io_out_s3_full_pred_2_hit),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0
      (_ftb_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1
      (_ftb_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0
      (_ftb_io_out_s3_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1
      (_ftb_io_out_s3_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_0
      (_ftb_io_out_s3_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_1
      (_ftb_io_out_s3_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0
      (_ftb_io_out_s3_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1
      (_ftb_io_out_s3_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr
      (_ftb_io_out_s3_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr
      (_ftb_io_out_s3_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_3_multiHit
      (_ftb_io_out_s3_full_pred_3_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jal
      (_ftb_io_out_s3_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr
      (_ftb_io_out_s3_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_call
      (_ftb_io_out_s3_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_ret
      (_ftb_io_out_s3_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call
      (_ftb_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing
      (_ftb_io_out_s3_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_3_hit
      (_ftb_io_out_s3_full_pred_3_hit),
    .io_in_bits_resp_in_0_s1_uftbHit
      (_ftb_io_out_s1_uftbHit),
    .io_in_bits_resp_in_0_s1_uftbHasIndirect
      (_ftb_io_out_s1_uftbHasIndirect),
    .io_in_bits_resp_in_0_s1_ftbCloseReq
      (_ftb_io_out_s1_ftbCloseReq),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0
      (_ftb_io_out_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1
      (_ftb_io_out_last_stage_spec_info_sc_disagree_1),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall
      (_ftb_io_out_last_stage_ftb_entry_isCall),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet
      (_ftb_io_out_last_stage_ftb_entry_isRet),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr
      (_ftb_io_out_last_stage_ftb_entry_isJalr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_valid
      (_ftb_io_out_last_stage_ftb_entry_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat
      (_ftb_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat
      (_ftb_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr
      (_ftb_io_out_last_stage_ftb_entry_pftAddr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_carry
      (_ftb_io_out_last_stage_ftb_entry_carry),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call
      (_ftb_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0
      (_ftb_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1
      (_ftb_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_out_s2_full_pred_0_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0
      (_ittage_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1
      (_ittage_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0
      (_ittage_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1
      (_ittage_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target
      (_ittage_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0
      (_ittage_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1
      (_ittage_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr
      (_ittage_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr
      (_ittage_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal
      (_ittage_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr
      (_ittage_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call
      (_ittage_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret
      (_ittage_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing
      (_ittage_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit
      (_ittage_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0
      (_ittage_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1
      (_ittage_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0
      (_ittage_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1
      (_ittage_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target
      (_ittage_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0
      (_ittage_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1
      (_ittage_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr
      (_ittage_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr
      (_ittage_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal
      (_ittage_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr
      (_ittage_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call
      (_ittage_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret
      (_ittage_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing
      (_ittage_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit
      (_ittage_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0
      (_ittage_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1
      (_ittage_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0
      (_ittage_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1
      (_ittage_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target
      (_ittage_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0
      (_ittage_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1
      (_ittage_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr
      (_ittage_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr
      (_ittage_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal
      (_ittage_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr
      (_ittage_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call
      (_ittage_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret
      (_ittage_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing
      (_ittage_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit
      (_ittage_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0
      (_ittage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1
      (_ittage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0
      (_ittage_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1
      (_ittage_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0
      (_ittage_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1
      (_ittage_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target
      (_ittage_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0
      (_ittage_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1
      (_ittage_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr
      (_ittage_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr
      (_ittage_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal
      (_ittage_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr
      (_ittage_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call
      (_ittage_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret
      (_ittage_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call
      (_ittage_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing
      (_ittage_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit
      (_ittage_io_out_s2_full_pred_3_hit),
    .io_out_s3_full_pred_0_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0
      (_ittage_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1
      (_ittage_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0
      (_ittage_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1
      (_ittage_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target
      (_ittage_io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0
      (_ittage_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1
      (_ittage_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr
      (_ittage_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr
      (_ittage_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit
      (_ittage_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal
      (_ittage_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr
      (_ittage_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call
      (_ittage_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret
      (_ittage_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing
      (_ittage_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit
      (_ittage_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0
      (_ittage_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1
      (_ittage_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0
      (_ittage_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1
      (_ittage_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target
      (_ittage_io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0
      (_ittage_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1
      (_ittage_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr
      (_ittage_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr
      (_ittage_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit
      (_ittage_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal
      (_ittage_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr
      (_ittage_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call
      (_ittage_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret
      (_ittage_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing
      (_ittage_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit
      (_ittage_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0
      (_ittage_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1
      (_ittage_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0
      (_ittage_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1
      (_ittage_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target
      (_ittage_io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0
      (_ittage_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1
      (_ittage_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr
      (_ittage_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr
      (_ittage_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit
      (_ittage_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal
      (_ittage_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr
      (_ittage_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call
      (_ittage_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret
      (_ittage_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing
      (_ittage_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit
      (_ittage_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0
      (_ittage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1
      (_ittage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0
      (_ittage_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1
      (_ittage_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0
      (_ittage_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1
      (_ittage_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target
      (_ittage_io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0
      (_ittage_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1
      (_ittage_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr
      (_ittage_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr
      (_ittage_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit
      (_ittage_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal
      (_ittage_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr
      (_ittage_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call
      (_ittage_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret
      (_ittage_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call
      (_ittage_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing
      (_ittage_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit
      (_ittage_io_out_s3_full_pred_3_hit),
    .io_out_last_stage_meta
      (_ittage_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0
      (_ittage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1
      (_ittage_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall
      (_ittage_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet
      (_ittage_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr
      (_ittage_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid
      (_ittage_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat
      (_ittage_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat
      (_ittage_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr
      (_ittage_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry
      (_ittage_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call
      (_ittage_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0
      (_ittage_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1
      (_ittage_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_s0_fire_0                                                   (io_s0_fire_0),
    .io_s0_fire_1                                                   (io_s0_fire_1),
    .io_s0_fire_2                                                   (io_s0_fire_2),
    .io_s0_fire_3                                                   (io_s0_fire_3),
    .io_s1_fire_0                                                   (io_s1_fire_0),
    .io_s1_fire_1                                                   (io_s1_fire_1),
    .io_s1_fire_2                                                   (io_s1_fire_2),
    .io_s1_fire_3                                                   (io_s1_fire_3),
    .io_s2_fire_0                                                   (io_s2_fire_0),
    .io_s2_fire_1                                                   (io_s2_fire_1),
    .io_s2_fire_2                                                   (io_s2_fire_2),
    .io_s2_fire_3                                                   (io_s2_fire_3),
    .io_s1_ready                                                    (_ittage_io_s1_ready),
    .io_update_valid                                                (io_update_valid),
    .io_update_bits_pc                                              (io_update_bits_pc),
    .io_update_bits_ftb_entry_isRet
      (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr
      (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_tailSlot_offset
      (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing
      (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid
      (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_strong_bias_1
      (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_cfi_idx_valid
      (io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits
      (io_update_bits_cfi_idx_bits),
    .io_update_bits_jmp_taken
      (io_update_bits_jmp_taken),
    .io_update_bits_mispred_mask_2
      (io_update_bits_mispred_mask_2),
    .io_update_bits_meta
      ({10'h0, io_update_bits_meta[515:10]}),
    .io_update_bits_full_target
      (io_update_bits_full_target),
    .io_update_bits_ghist
      (io_update_bits_ghist),
    .boreChildrenBd_bore_array
      (boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_all
      (boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_req
      (boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_ack
      (boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_writeen
      (boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_be
      (boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_addr
      (boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_indata
      (boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_readen
      (boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_addr_rd
      (boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_outdata
      (boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_1_array
      (boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_1_all
      (boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_1_req
      (boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_1_ack
      (boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_1_writeen
      (boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_1_be
      (boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_1_addr
      (boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_1_indata
      (boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_1_readen
      (boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_1_addr_rd
      (boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_1_outdata
      (boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_2_array
      (boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_2_all
      (boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_2_req
      (boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_2_ack
      (boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_2_writeen
      (boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_2_be
      (boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_2_addr
      (boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_2_indata
      (boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_2_readen
      (boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_2_addr_rd
      (boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_2_outdata
      (boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_3_array
      (boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_3_all
      (boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_3_req
      (boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_3_ack
      (boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_3_writeen
      (boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_3_be
      (boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_3_addr
      (boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_3_indata
      (boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_3_readen
      (boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_3_addr_rd
      (boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_3_outdata
      (boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_4_array
      (boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_4_all
      (boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_4_req
      (boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_4_ack
      (boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_4_writeen
      (boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_4_be
      (boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_4_addr
      (boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_4_indata
      (boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_4_readen
      (boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_4_addr_rd
      (boreChildrenBd_bore_10_addr_rd),
    .boreChildrenBd_bore_4_outdata
      (boreChildrenBd_bore_10_outdata),
    .sigFromSrams_bore_ram_hold
      (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_ram_bypass
      (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken
      (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk
      (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp
      (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold
      (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_cgen
      (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_1_ram_hold
      (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_1_ram_bypass
      (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken
      (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk
      (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp
      (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold
      (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen
      (sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_2_ram_hold
      (sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_2_ram_bypass
      (sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken
      (sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk
      (sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp
      (sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold
      (sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen
      (sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_3_ram_hold
      (sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_3_ram_bypass
      (sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken
      (sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk
      (sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp
      (sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold
      (sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen
      (sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_4_ram_hold
      (sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_4_ram_bypass
      (sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken
      (sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk
      (sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp
      (sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold
      (sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen
      (sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_5_ram_hold
      (sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_5_ram_bypass
      (sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken
      (sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk
      (sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp
      (sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold
      (sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen
      (sigFromSrams_bore_39_cgen),
    .sigFromSrams_bore_6_ram_hold
      (sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_6_ram_bypass
      (sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken
      (sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk
      (sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp
      (sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold
      (sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen
      (sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_7_ram_hold
      (sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_7_ram_bypass
      (sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken
      (sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk
      (sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp
      (sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold
      (sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen
      (sigFromSrams_bore_41_cgen)
  );

  DelayN uftb_io_ctrl_delay (
    .clock              (clock),
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    .io_out_ubtb_enable (_uftb_io_ctrl_delay_io_out_ubtb_enable),
    .io_out_btb_enable  (/* unused */),
    .io_out_tage_enable (/* unused */),
    .io_out_sc_enable   (/* unused */),
    .io_out_ras_enable  (/* unused */)
  );

  DelayN tage_io_ctrl_delay (
    .clock              (clock),
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    .io_out_ubtb_enable (/* unused */),
    .io_out_btb_enable  (/* unused */),
    .io_out_tage_enable (_tage_io_ctrl_delay_io_out_tage_enable),
    .io_out_sc_enable   (_tage_io_ctrl_delay_io_out_sc_enable),
    .io_out_ras_enable  (/* unused */)
  );

  DelayN ftb_io_ctrl_delay (
    .clock              (clock),
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    .io_out_ubtb_enable (/* unused */),
    .io_out_btb_enable  (_ftb_io_ctrl_delay_io_out_btb_enable),
    .io_out_tage_enable (/* unused */),
    .io_out_sc_enable   (/* unused */),
    .io_out_ras_enable  (/* unused */)
  );

  DelayN ras_io_ctrl_delay (
    .clock              (clock),
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    .io_out_ubtb_enable (/* unused */),
    .io_out_btb_enable  (/* unused */),
    .io_out_tage_enable (/* unused */),
    .io_out_sc_enable   (/* unused */),
    .io_out_ras_enable  (_ras_io_ctrl_delay_io_out_ras_enable)
  );

  // ---- 可读核：perf 2 级流水 / meta 拼接 / s1_ready 相与 ----
  xs_Composer_core u_core (
    .clock(clock),
    .reset(reset),
    .perf_in_0(_uftb_io_perf_0_value),
    .perf_in_1(_uftb_io_perf_1_value),
    .perf_in_2(_tage_io_perf_0_value),
    .perf_in_3(_tage_io_perf_1_value),
    .perf_in_4(_tage_io_perf_2_value),
    .perf_in_5(_ftb_io_perf_0_value),
    .perf_in_6(_ftb_io_perf_1_value),
    .meta_in_0(_uftb_io_out_last_stage_meta[5:0]),
    .meta_in_1(_tage_io_out_last_stage_meta[143:0]),
    .meta_in_2(_ftb_io_out_last_stage_meta[66:0]),
    .meta_in_3(_ittage_io_out_last_stage_meta[181:0]),
    .meta_in_4(_ras_io_out_last_stage_meta[9:0]),
    .ready_in_0(_tage_io_s1_ready),
    .ready_in_1(_ftb_io_s1_ready),
    .ready_in_2(_ittage_io_s1_ready),
    .io_perf_0_value(io_perf_0_value),
    .io_perf_1_value(io_perf_1_value),
    .io_perf_2_value(io_perf_2_value),
    .io_perf_3_value(io_perf_3_value),
    .io_perf_4_value(io_perf_4_value),
    .io_perf_5_value(io_perf_5_value),
    .io_perf_6_value(io_perf_6_value),
    .io_out_last_stage_meta(io_out_last_stage_meta),
    .io_s1_ready(io_s1_ready)
  );
endmodule
