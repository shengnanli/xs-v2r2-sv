// 自动生成：scripts/gen_ittage.py —— 勿手改
module ITTage_xs(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_14_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_13_folded_hist,
  input  [3:0] io_in_bits_s1_folded_hist_3_hist_12_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_10_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_6_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_4_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_3_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_2_folded_hist,
  input  io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_0_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_0_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_0_hit,
  input  io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_1_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_1_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_1_hit,
  input  io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_2_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_2_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_2_hit,
  input  io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_3_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_3_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_3_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_0_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_0_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_0_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_0_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_1_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_1_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_1_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_1_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_2_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_2_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_2_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_2_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_3_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_3_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_3_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_3_hit,
  input  io_in_bits_resp_in_0_s1_uftbHit,
  input  io_in_bits_resp_in_0_s1_uftbHasIndirect,
  input  io_in_bits_resp_in_0_s1_ftbCloseReq,
  input  io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
  input  io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_isCall,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_isRet,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_valid,
  input  [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid,
  input  [11:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower,
  input  [1:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat,
  input  [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid,
  input  [19:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower,
  input  [1:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat,
  input  [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_carry,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1,
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
  output io_s1_ready,
  input  io_update_valid,
  input  [49:0] io_update_bits_pc,
  input  io_update_bits_ftb_entry_isRet,
  input  io_update_bits_ftb_entry_isJalr,
  input  [3:0] io_update_bits_ftb_entry_tailSlot_offset,
  input  io_update_bits_ftb_entry_tailSlot_sharing,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  io_update_bits_ftb_entry_strong_bias_1,
  input  io_update_bits_cfi_idx_valid,
  input  [3:0] io_update_bits_cfi_idx_bits,
  input  io_update_bits_jmp_taken,
  input  io_update_bits_mispred_mask_2,
  input  [515:0] io_update_bits_meta,
  input  [49:0] io_update_bits_full_target,
  input  [255:0] io_update_bits_ghist,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [75:0] boreChildrenBd_bore_be,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [75:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input  [6:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [75:0] boreChildrenBd_bore_1_be,
  input  [7:0] boreChildrenBd_bore_1_addr,
  input  [75:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [7:0] boreChildrenBd_bore_1_addr_rd,
  output [75:0] boreChildrenBd_bore_1_outdata,
  input  [6:0] boreChildrenBd_bore_2_array,
  input  boreChildrenBd_bore_2_all,
  input  boreChildrenBd_bore_2_req,
  output boreChildrenBd_bore_2_ack,
  input  boreChildrenBd_bore_2_writeen,
  input  [75:0] boreChildrenBd_bore_2_be,
  input  [7:0] boreChildrenBd_bore_2_addr,
  input  [75:0] boreChildrenBd_bore_2_indata,
  input  boreChildrenBd_bore_2_readen,
  input  [7:0] boreChildrenBd_bore_2_addr_rd,
  output [75:0] boreChildrenBd_bore_2_outdata,
  input  [6:0] boreChildrenBd_bore_3_array,
  input  boreChildrenBd_bore_3_all,
  input  boreChildrenBd_bore_3_req,
  output boreChildrenBd_bore_3_ack,
  input  boreChildrenBd_bore_3_writeen,
  input  [75:0] boreChildrenBd_bore_3_be,
  input  [7:0] boreChildrenBd_bore_3_addr,
  input  [75:0] boreChildrenBd_bore_3_indata,
  input  boreChildrenBd_bore_3_readen,
  input  [7:0] boreChildrenBd_bore_3_addr_rd,
  output [75:0] boreChildrenBd_bore_3_outdata,
  input  [6:0] boreChildrenBd_bore_4_array,
  input  boreChildrenBd_bore_4_all,
  input  boreChildrenBd_bore_4_req,
  output boreChildrenBd_bore_4_ack,
  input  boreChildrenBd_bore_4_writeen,
  input  [75:0] boreChildrenBd_bore_4_be,
  input  [7:0] boreChildrenBd_bore_4_addr,
  input  [75:0] boreChildrenBd_bore_4_indata,
  input  boreChildrenBd_bore_4_readen,
  input  [7:0] boreChildrenBd_bore_4_addr_rd,
  output [75:0] boreChildrenBd_bore_4_outdata,
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
  input  sigFromSrams_bore_7_cgen
);

  // ---- 5 张表 resp / ready 内部线 ----
  wire        t0_req_ready;
  wire        t0_resp_valid;
  wire [1:0]  t0_resp_ctr;
  wire        t0_resp_u;
  wire [19:0] t0_resp_off;
  wire [3:0]  t0_resp_ptr;
  wire        t0_resp_usePCRegion;
  wire        t1_req_ready;
  wire        t1_resp_valid;
  wire [1:0]  t1_resp_ctr;
  wire        t1_resp_u;
  wire [19:0] t1_resp_off;
  wire [3:0]  t1_resp_ptr;
  wire        t1_resp_usePCRegion;
  wire        t2_req_ready;
  wire        t2_resp_valid;
  wire [1:0]  t2_resp_ctr;
  wire        t2_resp_u;
  wire [19:0] t2_resp_off;
  wire [3:0]  t2_resp_ptr;
  wire        t2_resp_usePCRegion;
  wire        t3_req_ready;
  wire        t3_resp_valid;
  wire [1:0]  t3_resp_ctr;
  wire        t3_resp_u;
  wire [19:0] t3_resp_off;
  wire [3:0]  t3_resp_ptr;
  wire        t3_resp_usePCRegion;
  wire        t4_req_ready;
  wire        t4_resp_valid;
  wire [1:0]  t4_resp_ctr;
  wire        t4_resp_u;
  wire [19:0] t4_resp_off;
  wire [3:0]  t4_resp_ptr;
  wire        t4_resp_usePCRegion;
  // ---- 核驱动的各表 update 端口 ----
  wire        t0_upd_valid, t0_upd_correct, t0_upd_alloc;
  wire [1:0]  t0_upd_oldCtr;
  wire        t0_upd_uValid, t0_upd_u, t0_upd_reset_u;
  wire [49:0] t0_upd_pc;
  wire [255:0]t0_upd_ghist;
  wire [19:0] t0_upd_off; wire [3:0] t0_upd_ptr; wire t0_upd_usePCRegion;
  wire [19:0] t0_upd_old_off; wire [3:0] t0_upd_old_ptr; wire t0_upd_old_usePCRegion;
  wire        t1_upd_valid, t1_upd_correct, t1_upd_alloc;
  wire [1:0]  t1_upd_oldCtr;
  wire        t1_upd_uValid, t1_upd_u, t1_upd_reset_u;
  wire [49:0] t1_upd_pc;
  wire [255:0]t1_upd_ghist;
  wire [19:0] t1_upd_off; wire [3:0] t1_upd_ptr; wire t1_upd_usePCRegion;
  wire [19:0] t1_upd_old_off; wire [3:0] t1_upd_old_ptr; wire t1_upd_old_usePCRegion;
  wire        t2_upd_valid, t2_upd_correct, t2_upd_alloc;
  wire [1:0]  t2_upd_oldCtr;
  wire        t2_upd_uValid, t2_upd_u, t2_upd_reset_u;
  wire [49:0] t2_upd_pc;
  wire [255:0]t2_upd_ghist;
  wire [19:0] t2_upd_off; wire [3:0] t2_upd_ptr; wire t2_upd_usePCRegion;
  wire [19:0] t2_upd_old_off; wire [3:0] t2_upd_old_ptr; wire t2_upd_old_usePCRegion;
  wire        t3_upd_valid, t3_upd_correct, t3_upd_alloc;
  wire [1:0]  t3_upd_oldCtr;
  wire        t3_upd_uValid, t3_upd_u, t3_upd_reset_u;
  wire [49:0] t3_upd_pc;
  wire [255:0]t3_upd_ghist;
  wire [19:0] t3_upd_off; wire [3:0] t3_upd_ptr; wire t3_upd_usePCRegion;
  wire [19:0] t3_upd_old_off; wire [3:0] t3_upd_old_ptr; wire t3_upd_old_usePCRegion;
  wire        t4_upd_valid, t4_upd_correct, t4_upd_alloc;
  wire [1:0]  t4_upd_oldCtr;
  wire        t4_upd_uValid, t4_upd_u, t4_upd_reset_u;
  wire [49:0] t4_upd_pc;
  wire [255:0]t4_upd_ghist;
  wire [19:0] t4_upd_off; wire [3:0] t4_upd_ptr; wire t4_upd_usePCRegion;
  wire [19:0] t4_upd_old_off; wire [3:0] t4_upd_old_ptr; wire t4_upd_old_usePCRegion;
  // ---- RegionWays / LFSR 内部线 ----
  wire        rt_resp_hit_0;
  wire [29:0] rt_resp_region_0;
  wire        rt_resp_hit_1;
  wire [29:0] rt_resp_region_1;
  wire        rt_resp_hit_2;
  wire [29:0] rt_resp_region_2;
  wire        rt_resp_hit_3;
  wire [29:0] rt_resp_region_3;
  wire        rt_resp_hit_4;
  wire [29:0] rt_resp_region_4;
  wire        rt_update_hit_0, rt_update_hit_1;
  wire [3:0]  rt_update_ptr_0, rt_update_ptr_1, rt_write_ptr;
  wire [29:0] rt_update_region_0, rt_update_region_1, rt_write_region;
  wire        rt_write_valid;
  wire        lfsr_out_0;
  wire        lfsr_out_1;
  wire        lfsr_out_2;
  wire        lfsr_out_3;
  wire        lfsr_out_4;
  wire        core_s1_ready;
  wire        core_req_valid;
  wire [49:0] core_req_pc;
  wire [49:0] core_s3_jalr_target_0;
  wire [49:0] core_s3_jalr_target_1;
  wire [49:0] core_s3_jalr_target_2;
  wire [49:0] core_s3_jalr_target_3;

  ITTageTable tables_0 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t0_req_ready),
    .io_req_valid(core_req_valid),
    .io_req_bits_pc(core_req_pc),
    .io_req_bits_folded_hist_hist_12_folded_hist(io_in_bits_s1_folded_hist_3_hist_12_folded_hist),
    .io_resp_valid(t0_resp_valid),
    .io_resp_bits_ctr(t0_resp_ctr),
    .io_resp_bits_u(t0_resp_u),
    .io_resp_bits_target_offset_offset(t0_resp_off),
    .io_resp_bits_target_offset_pointer(t0_resp_ptr),
    .io_resp_bits_target_offset_usePCRegion(t0_resp_usePCRegion),
    .io_update_pc(t0_upd_pc),
    .io_update_ghist(t0_upd_ghist),
    .io_update_valid(t0_upd_valid),
    .io_update_correct(t0_upd_correct),
    .io_update_alloc(t0_upd_alloc),
    .io_update_oldCtr(t0_upd_oldCtr),
    .io_update_uValid(t0_upd_uValid),
    .io_update_u(t0_upd_u),
    .io_update_reset_u(t0_upd_reset_u),
    .io_update_target_offset_offset(t0_upd_off),
    .io_update_target_offset_pointer(t0_upd_ptr),
    .io_update_target_offset_usePCRegion(t0_upd_usePCRegion),
    .io_update_old_target_offset_offset(t0_upd_old_off),
    .io_update_old_target_offset_pointer(t0_upd_old_ptr),
    .io_update_old_target_offset_usePCRegion(t0_upd_old_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );
  ITTageTable_1 tables_1 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t1_req_ready),
    .io_req_valid(core_req_valid),
    .io_req_bits_pc(core_req_pc),
    .io_req_bits_folded_hist_hist_14_folded_hist(io_in_bits_s1_folded_hist_3_hist_14_folded_hist),
    .io_resp_valid(t1_resp_valid),
    .io_resp_bits_ctr(t1_resp_ctr),
    .io_resp_bits_u(t1_resp_u),
    .io_resp_bits_target_offset_offset(t1_resp_off),
    .io_resp_bits_target_offset_pointer(t1_resp_ptr),
    .io_resp_bits_target_offset_usePCRegion(t1_resp_usePCRegion),
    .io_update_pc(t1_upd_pc),
    .io_update_ghist(t1_upd_ghist),
    .io_update_valid(t1_upd_valid),
    .io_update_correct(t1_upd_correct),
    .io_update_alloc(t1_upd_alloc),
    .io_update_oldCtr(t1_upd_oldCtr),
    .io_update_uValid(t1_upd_uValid),
    .io_update_u(t1_upd_u),
    .io_update_reset_u(t1_upd_reset_u),
    .io_update_target_offset_offset(t1_upd_off),
    .io_update_target_offset_pointer(t1_upd_ptr),
    .io_update_target_offset_usePCRegion(t1_upd_usePCRegion),
    .io_update_old_target_offset_offset(t1_upd_old_off),
    .io_update_old_target_offset_pointer(t1_upd_old_ptr),
    .io_update_old_target_offset_usePCRegion(t1_upd_old_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata(boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_1_cgen)
  );
  ITTageTable_2 tables_2 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t2_req_ready),
    .io_req_valid(core_req_valid),
    .io_req_bits_pc(core_req_pc),
    .io_req_bits_folded_hist_hist_13_folded_hist(io_in_bits_s1_folded_hist_3_hist_13_folded_hist),
    .io_req_bits_folded_hist_hist_4_folded_hist(io_in_bits_s1_folded_hist_3_hist_4_folded_hist),
    .io_resp_valid(t2_resp_valid),
    .io_resp_bits_ctr(t2_resp_ctr),
    .io_resp_bits_u(t2_resp_u),
    .io_resp_bits_target_offset_offset(t2_resp_off),
    .io_resp_bits_target_offset_pointer(t2_resp_ptr),
    .io_resp_bits_target_offset_usePCRegion(t2_resp_usePCRegion),
    .io_update_pc(t2_upd_pc),
    .io_update_ghist(t2_upd_ghist),
    .io_update_valid(t2_upd_valid),
    .io_update_correct(t2_upd_correct),
    .io_update_alloc(t2_upd_alloc),
    .io_update_oldCtr(t2_upd_oldCtr),
    .io_update_uValid(t2_upd_uValid),
    .io_update_u(t2_upd_u),
    .io_update_reset_u(t2_upd_reset_u),
    .io_update_target_offset_offset(t2_upd_off),
    .io_update_target_offset_pointer(t2_upd_ptr),
    .io_update_target_offset_usePCRegion(t2_upd_usePCRegion),
    .io_update_old_target_offset_offset(t2_upd_old_off),
    .io_update_old_target_offset_pointer(t2_upd_old_ptr),
    .io_update_old_target_offset_usePCRegion(t2_upd_old_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_outdata(boreChildrenBd_bore_2_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_3_cgen)
  );
  ITTageTable_3 tables_3 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t3_req_ready),
    .io_req_valid(core_req_valid),
    .io_req_bits_pc(core_req_pc),
    .io_req_bits_folded_hist_hist_6_folded_hist(io_in_bits_s1_folded_hist_3_hist_6_folded_hist),
    .io_req_bits_folded_hist_hist_2_folded_hist(io_in_bits_s1_folded_hist_3_hist_2_folded_hist),
    .io_resp_valid(t3_resp_valid),
    .io_resp_bits_ctr(t3_resp_ctr),
    .io_resp_bits_u(t3_resp_u),
    .io_resp_bits_target_offset_offset(t3_resp_off),
    .io_resp_bits_target_offset_pointer(t3_resp_ptr),
    .io_resp_bits_target_offset_usePCRegion(t3_resp_usePCRegion),
    .io_update_pc(t3_upd_pc),
    .io_update_ghist(t3_upd_ghist),
    .io_update_valid(t3_upd_valid),
    .io_update_correct(t3_upd_correct),
    .io_update_alloc(t3_upd_alloc),
    .io_update_oldCtr(t3_upd_oldCtr),
    .io_update_uValid(t3_upd_uValid),
    .io_update_u(t3_upd_u),
    .io_update_reset_u(t3_upd_reset_u),
    .io_update_target_offset_offset(t3_upd_off),
    .io_update_target_offset_pointer(t3_upd_ptr),
    .io_update_target_offset_usePCRegion(t3_upd_usePCRegion),
    .io_update_old_target_offset_offset(t3_upd_old_off),
    .io_update_old_target_offset_pointer(t3_upd_old_ptr),
    .io_update_old_target_offset_usePCRegion(t3_upd_old_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_outdata(boreChildrenBd_bore_3_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_5_cgen)
  );
  ITTageTable_4 tables_4 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t4_req_ready),
    .io_req_valid(core_req_valid),
    .io_req_bits_pc(core_req_pc),
    .io_req_bits_folded_hist_hist_10_folded_hist(io_in_bits_s1_folded_hist_3_hist_10_folded_hist),
    .io_req_bits_folded_hist_hist_3_folded_hist(io_in_bits_s1_folded_hist_3_hist_3_folded_hist),
    .io_resp_valid(t4_resp_valid),
    .io_resp_bits_ctr(t4_resp_ctr),
    .io_resp_bits_u(t4_resp_u),
    .io_resp_bits_target_offset_offset(t4_resp_off),
    .io_resp_bits_target_offset_pointer(t4_resp_ptr),
    .io_resp_bits_target_offset_usePCRegion(t4_resp_usePCRegion),
    .io_update_pc(t4_upd_pc),
    .io_update_ghist(t4_upd_ghist),
    .io_update_valid(t4_upd_valid),
    .io_update_correct(t4_upd_correct),
    .io_update_alloc(t4_upd_alloc),
    .io_update_oldCtr(t4_upd_oldCtr),
    .io_update_uValid(t4_upd_uValid),
    .io_update_u(t4_upd_u),
    .io_update_reset_u(t4_upd_reset_u),
    .io_update_target_offset_offset(t4_upd_off),
    .io_update_target_offset_pointer(t4_upd_ptr),
    .io_update_target_offset_usePCRegion(t4_upd_usePCRegion),
    .io_update_old_target_offset_offset(t4_upd_old_off),
    .io_update_old_target_offset_pointer(t4_upd_old_ptr),
    .io_update_old_target_offset_usePCRegion(t4_upd_old_usePCRegion),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_outdata(boreChildrenBd_bore_4_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_7_cgen)
  );

  RegionWays rTable (
    .clock(clock),
    .reset(reset),
    .io_req_pointer_0(t0_resp_ptr),
    .io_req_pointer_1(t1_resp_ptr),
    .io_req_pointer_2(t2_resp_ptr),
    .io_req_pointer_3(t3_resp_ptr),
    .io_req_pointer_4(t4_resp_ptr),
    .io_resp_hit_0(rt_resp_hit_0),
    .io_resp_hit_1(rt_resp_hit_1),
    .io_resp_hit_2(rt_resp_hit_2),
    .io_resp_hit_3(rt_resp_hit_3),
    .io_resp_hit_4(rt_resp_hit_4),
    .io_resp_region_0(rt_resp_region_0),
    .io_resp_region_1(rt_resp_region_1),
    .io_resp_region_2(rt_resp_region_2),
    .io_resp_region_3(rt_resp_region_3),
    .io_resp_region_4(rt_resp_region_4),
    .io_update_region_0(rt_update_region_0),
    .io_update_region_1(rt_update_region_1),
    .io_update_hit_0(rt_update_hit_0),
    .io_update_hit_1(rt_update_hit_1),
    .io_update_pointer_0(rt_update_ptr_0),
    .io_update_pointer_1(rt_update_ptr_1),
    .io_write_valid(rt_write_valid),
    .io_write_region(rt_write_region),
    .io_write_pointer(rt_write_ptr)
  );

  MaxPeriodFibonacciLFSR s2_allocLFSR_prng (
    .clock(clock),
    .reset(reset),
    .io_out_0(lfsr_out_0),
    .io_out_1(lfsr_out_1),
    .io_out_2(lfsr_out_2),
    .io_out_3(lfsr_out_3),
    .io_out_4(lfsr_out_4),
    .io_out_5(),
    .io_out_6(),
    .io_out_7(),
    .io_out_8(),
    .io_out_9(),
    .io_out_10(),
    .io_out_11(),
    .io_out_12(),
    .io_out_13(),
    .io_out_14()
  );

  xs_ITTage_core u_core (
    .clock(clock),
    .reset(reset),
    .io_reset_vector(io_reset_vector),
    .io_in_s0_pc('{io_in_bits_s0_pc_0, io_in_bits_s0_pc_1, io_in_bits_s0_pc_2, io_in_bits_s0_pc_3}),
    .io_s0_fire('{io_s0_fire_0, io_s0_fire_1, io_s0_fire_2, io_s0_fire_3}),
    .io_s1_fire('{io_s1_fire_0, io_s1_fire_1, io_s1_fire_2, io_s1_fire_3}),
    .io_s2_fire('{io_s2_fire_0, io_s2_fire_1, io_s2_fire_2, io_s2_fire_3}),
    .io_s1_uftbHit(io_in_bits_resp_in_0_s1_uftbHit),
    .io_s1_uftbHasIndirect(io_in_bits_resp_in_0_s1_uftbHasIndirect),
    .io_s1_ftbCloseReq(io_in_bits_resp_in_0_s1_ftbCloseReq),
    .io_in_s2_jalr_target_3(io_in_bits_resp_in_0_s2_full_pred_3_jalr_target),
    .io_s1_ready(core_s1_ready),
    .io_out_s3_jalr_target('{core_s3_jalr_target_0, core_s3_jalr_target_1, core_s3_jalr_target_2, core_s3_jalr_target_3}),
    .io_out_last_stage_meta(io_out_last_stage_meta),
    .io_update_valid(io_update_valid),
    .io_update_pc(io_update_bits_pc),
    .io_update_ftb_isRet(io_update_bits_ftb_entry_isRet),
    .io_update_ftb_isJalr(io_update_bits_ftb_entry_isJalr),
    .io_update_ftb_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_ftb_tailSlot_sharing(io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_ftb_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_ftb_strong_bias_1(io_update_bits_ftb_entry_strong_bias_1),
    .io_update_cfi_idx_valid(io_update_bits_cfi_idx_valid),
    .io_update_cfi_idx_bits(io_update_bits_cfi_idx_bits),
    .io_update_jmp_taken(io_update_bits_jmp_taken),
    .io_update_mispred_mask_2(io_update_bits_mispred_mask_2),
    .io_update_meta(io_update_bits_meta),
    .io_update_full_target(io_update_bits_full_target),
    .io_update_ghist(io_update_bits_ghist),
    .tbl_req_valid(core_req_valid),
    .tbl_req_pc(core_req_pc),
    .tbl_req_ready('{t0_req_ready, t1_req_ready, t2_req_ready, t3_req_ready, t4_req_ready}),
    .tbl_resp_valid('{t0_resp_valid, t1_resp_valid, t2_resp_valid, t3_resp_valid, t4_resp_valid}),
    .tbl_resp_ctr('{t0_resp_ctr, t1_resp_ctr, t2_resp_ctr, t3_resp_ctr, t4_resp_ctr}),
    .tbl_resp_u('{t0_resp_u, t1_resp_u, t2_resp_u, t3_resp_u, t4_resp_u}),
    .tbl_resp_off('{t0_resp_off, t1_resp_off, t2_resp_off, t3_resp_off, t4_resp_off}),
    .tbl_resp_ptr('{t0_resp_ptr, t1_resp_ptr, t2_resp_ptr, t3_resp_ptr, t4_resp_ptr}),
    .tbl_resp_usePCRegion('{t0_resp_usePCRegion, t1_resp_usePCRegion, t2_resp_usePCRegion, t3_resp_usePCRegion, t4_resp_usePCRegion}),
    .tbl_upd_valid('{t0_upd_valid, t1_upd_valid, t2_upd_valid, t3_upd_valid, t4_upd_valid}),
    .tbl_upd_correct('{t0_upd_correct, t1_upd_correct, t2_upd_correct, t3_upd_correct, t4_upd_correct}),
    .tbl_upd_alloc('{t0_upd_alloc, t1_upd_alloc, t2_upd_alloc, t3_upd_alloc, t4_upd_alloc}),
    .tbl_upd_oldCtr('{t0_upd_oldCtr, t1_upd_oldCtr, t2_upd_oldCtr, t3_upd_oldCtr, t4_upd_oldCtr}),
    .tbl_upd_uValid('{t0_upd_uValid, t1_upd_uValid, t2_upd_uValid, t3_upd_uValid, t4_upd_uValid}),
    .tbl_upd_u('{t0_upd_u, t1_upd_u, t2_upd_u, t3_upd_u, t4_upd_u}),
    .tbl_upd_reset_u('{t0_upd_reset_u, t1_upd_reset_u, t2_upd_reset_u, t3_upd_reset_u, t4_upd_reset_u}),
    .tbl_upd_pc('{t0_upd_pc, t1_upd_pc, t2_upd_pc, t3_upd_pc, t4_upd_pc}),
    .tbl_upd_ghist('{t0_upd_ghist, t1_upd_ghist, t2_upd_ghist, t3_upd_ghist, t4_upd_ghist}),
    .tbl_upd_off('{t0_upd_off, t1_upd_off, t2_upd_off, t3_upd_off, t4_upd_off}),
    .tbl_upd_ptr('{t0_upd_ptr, t1_upd_ptr, t2_upd_ptr, t3_upd_ptr, t4_upd_ptr}),
    .tbl_upd_usePCRegion('{t0_upd_usePCRegion, t1_upd_usePCRegion, t2_upd_usePCRegion, t3_upd_usePCRegion, t4_upd_usePCRegion}),
    .tbl_upd_old_off('{t0_upd_old_off, t1_upd_old_off, t2_upd_old_off, t3_upd_old_off, t4_upd_old_off}),
    .tbl_upd_old_ptr('{t0_upd_old_ptr, t1_upd_old_ptr, t2_upd_old_ptr, t3_upd_old_ptr, t4_upd_old_ptr}),
    .tbl_upd_old_usePCRegion('{t0_upd_old_usePCRegion, t1_upd_old_usePCRegion, t2_upd_old_usePCRegion, t3_upd_old_usePCRegion, t4_upd_old_usePCRegion}),
    .rt_resp_hit('{rt_resp_hit_0, rt_resp_hit_1, rt_resp_hit_2, rt_resp_hit_3, rt_resp_hit_4}),
    .rt_resp_region('{rt_resp_region_0, rt_resp_region_1, rt_resp_region_2, rt_resp_region_3, rt_resp_region_4}),
    .rt_update_region_0(rt_update_region_0),
    .rt_update_region_1(rt_update_region_1),
    .rt_update_hit_0(rt_update_hit_0),
    .rt_update_hit_1(rt_update_hit_1),
    .rt_update_pointer_0(rt_update_ptr_0),
    .rt_update_pointer_1(rt_update_ptr_1),
    .rt_write_valid(rt_write_valid),
    .rt_write_region(rt_write_region),
    .rt_write_pointer(rt_write_ptr),
    .lfsr_out('{lfsr_out_0, lfsr_out_1, lfsr_out_2, lfsr_out_3, lfsr_out_4})
  );

  assign io_s1_ready = core_s1_ready;
  assign io_out_s3_full_pred_0_jalr_target = core_s3_jalr_target_0;
  assign io_out_s3_full_pred_1_jalr_target = core_s3_jalr_target_1;
  assign io_out_s3_full_pred_2_jalr_target = core_s3_jalr_target_2;
  assign io_out_s3_full_pred_3_jalr_target = core_s3_jalr_target_3;

  // ---- 旁路透传（ITTAGE 只改 s3 jalr_target / last_stage_meta，其余原样透传）----
  assign io_out_s2_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  assign io_out_s2_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  assign io_out_s2_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0;
  assign io_out_s2_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1;
  assign io_out_s2_full_pred_0_targets_0 = io_in_bits_resp_in_0_s2_full_pred_0_targets_0;
  assign io_out_s2_full_pred_0_targets_1 = io_in_bits_resp_in_0_s2_full_pred_0_targets_1;
  assign io_out_s2_full_pred_0_jalr_target = io_in_bits_resp_in_0_s2_full_pred_0_jalr_target;
  assign io_out_s2_full_pred_0_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_0_offsets_0;
  assign io_out_s2_full_pred_0_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_0_offsets_1;
  assign io_out_s2_full_pred_0_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr;
  assign io_out_s2_full_pred_0_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr;
  assign io_out_s2_full_pred_0_is_jal = io_in_bits_resp_in_0_s2_full_pred_0_is_jal;
  assign io_out_s2_full_pred_0_is_jalr = io_in_bits_resp_in_0_s2_full_pred_0_is_jalr;
  assign io_out_s2_full_pred_0_is_call = io_in_bits_resp_in_0_s2_full_pred_0_is_call;
  assign io_out_s2_full_pred_0_is_ret = io_in_bits_resp_in_0_s2_full_pred_0_is_ret;
  assign io_out_s2_full_pred_0_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call;
  assign io_out_s2_full_pred_0_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing;
  assign io_out_s2_full_pred_0_hit = io_in_bits_resp_in_0_s2_full_pred_0_hit;
  assign io_out_s2_full_pred_1_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;
  assign io_out_s2_full_pred_1_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;
  assign io_out_s2_full_pred_1_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0;
  assign io_out_s2_full_pred_1_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1;
  assign io_out_s2_full_pred_1_targets_0 = io_in_bits_resp_in_0_s2_full_pred_1_targets_0;
  assign io_out_s2_full_pred_1_targets_1 = io_in_bits_resp_in_0_s2_full_pred_1_targets_1;
  assign io_out_s2_full_pred_1_jalr_target = io_in_bits_resp_in_0_s2_full_pred_1_jalr_target;
  assign io_out_s2_full_pred_1_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_1_offsets_0;
  assign io_out_s2_full_pred_1_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_1_offsets_1;
  assign io_out_s2_full_pred_1_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr;
  assign io_out_s2_full_pred_1_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr;
  assign io_out_s2_full_pred_1_is_jal = io_in_bits_resp_in_0_s2_full_pred_1_is_jal;
  assign io_out_s2_full_pred_1_is_jalr = io_in_bits_resp_in_0_s2_full_pred_1_is_jalr;
  assign io_out_s2_full_pred_1_is_call = io_in_bits_resp_in_0_s2_full_pred_1_is_call;
  assign io_out_s2_full_pred_1_is_ret = io_in_bits_resp_in_0_s2_full_pred_1_is_ret;
  assign io_out_s2_full_pred_1_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call;
  assign io_out_s2_full_pred_1_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing;
  assign io_out_s2_full_pred_1_hit = io_in_bits_resp_in_0_s2_full_pred_1_hit;
  assign io_out_s2_full_pred_2_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  assign io_out_s2_full_pred_2_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  assign io_out_s2_full_pred_2_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0;
  assign io_out_s2_full_pred_2_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1;
  assign io_out_s2_full_pred_2_targets_0 = io_in_bits_resp_in_0_s2_full_pred_2_targets_0;
  assign io_out_s2_full_pred_2_targets_1 = io_in_bits_resp_in_0_s2_full_pred_2_targets_1;
  assign io_out_s2_full_pred_2_jalr_target = io_in_bits_resp_in_0_s2_full_pred_2_jalr_target;
  assign io_out_s2_full_pred_2_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_2_offsets_0;
  assign io_out_s2_full_pred_2_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_2_offsets_1;
  assign io_out_s2_full_pred_2_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr;
  assign io_out_s2_full_pred_2_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr;
  assign io_out_s2_full_pred_2_is_jal = io_in_bits_resp_in_0_s2_full_pred_2_is_jal;
  assign io_out_s2_full_pred_2_is_jalr = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr;
  assign io_out_s2_full_pred_2_is_call = io_in_bits_resp_in_0_s2_full_pred_2_is_call;
  assign io_out_s2_full_pred_2_is_ret = io_in_bits_resp_in_0_s2_full_pred_2_is_ret;
  assign io_out_s2_full_pred_2_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call;
  assign io_out_s2_full_pred_2_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;
  assign io_out_s2_full_pred_2_hit = io_in_bits_resp_in_0_s2_full_pred_2_hit;
  assign io_out_s2_full_pred_3_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;
  assign io_out_s2_full_pred_3_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;
  assign io_out_s2_full_pred_3_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0;
  assign io_out_s2_full_pred_3_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1;
  assign io_out_s2_full_pred_3_targets_0 = io_in_bits_resp_in_0_s2_full_pred_3_targets_0;
  assign io_out_s2_full_pred_3_targets_1 = io_in_bits_resp_in_0_s2_full_pred_3_targets_1;
  assign io_out_s2_full_pred_3_jalr_target = io_in_bits_resp_in_0_s2_full_pred_3_jalr_target;
  assign io_out_s2_full_pred_3_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_3_offsets_0;
  assign io_out_s2_full_pred_3_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_3_offsets_1;
  assign io_out_s2_full_pred_3_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr;
  assign io_out_s2_full_pred_3_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr;
  assign io_out_s2_full_pred_3_is_jal = io_in_bits_resp_in_0_s2_full_pred_3_is_jal;
  assign io_out_s2_full_pred_3_is_jalr = io_in_bits_resp_in_0_s2_full_pred_3_is_jalr;
  assign io_out_s2_full_pred_3_is_call = io_in_bits_resp_in_0_s2_full_pred_3_is_call;
  assign io_out_s2_full_pred_3_is_ret = io_in_bits_resp_in_0_s2_full_pred_3_is_ret;
  assign io_out_s2_full_pred_3_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call;
  assign io_out_s2_full_pred_3_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing;
  assign io_out_s2_full_pred_3_hit = io_in_bits_resp_in_0_s2_full_pred_3_hit;
  assign io_out_s3_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;
  assign io_out_s3_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;
  assign io_out_s3_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0;
  assign io_out_s3_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1;
  assign io_out_s3_full_pred_0_targets_0 = io_in_bits_resp_in_0_s3_full_pred_0_targets_0;
  assign io_out_s3_full_pred_0_targets_1 = io_in_bits_resp_in_0_s3_full_pred_0_targets_1;
  assign io_out_s3_full_pred_0_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_0_offsets_0;
  assign io_out_s3_full_pred_0_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_0_offsets_1;
  assign io_out_s3_full_pred_0_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr;
  assign io_out_s3_full_pred_0_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr;
  assign io_out_s3_full_pred_0_multiHit = io_in_bits_resp_in_0_s3_full_pred_0_multiHit;
  assign io_out_s3_full_pred_0_is_jal = io_in_bits_resp_in_0_s3_full_pred_0_is_jal;
  assign io_out_s3_full_pred_0_is_jalr = io_in_bits_resp_in_0_s3_full_pred_0_is_jalr;
  assign io_out_s3_full_pred_0_is_call = io_in_bits_resp_in_0_s3_full_pred_0_is_call;
  assign io_out_s3_full_pred_0_is_ret = io_in_bits_resp_in_0_s3_full_pred_0_is_ret;
  assign io_out_s3_full_pred_0_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call;
  assign io_out_s3_full_pred_0_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing;
  assign io_out_s3_full_pred_0_hit = io_in_bits_resp_in_0_s3_full_pred_0_hit;
  assign io_out_s3_full_pred_1_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;
  assign io_out_s3_full_pred_1_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;
  assign io_out_s3_full_pred_1_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0;
  assign io_out_s3_full_pred_1_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1;
  assign io_out_s3_full_pred_1_targets_0 = io_in_bits_resp_in_0_s3_full_pred_1_targets_0;
  assign io_out_s3_full_pred_1_targets_1 = io_in_bits_resp_in_0_s3_full_pred_1_targets_1;
  assign io_out_s3_full_pred_1_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_1_offsets_0;
  assign io_out_s3_full_pred_1_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_1_offsets_1;
  assign io_out_s3_full_pred_1_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr;
  assign io_out_s3_full_pred_1_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr;
  assign io_out_s3_full_pred_1_multiHit = io_in_bits_resp_in_0_s3_full_pred_1_multiHit;
  assign io_out_s3_full_pred_1_is_jal = io_in_bits_resp_in_0_s3_full_pred_1_is_jal;
  assign io_out_s3_full_pred_1_is_jalr = io_in_bits_resp_in_0_s3_full_pred_1_is_jalr;
  assign io_out_s3_full_pred_1_is_call = io_in_bits_resp_in_0_s3_full_pred_1_is_call;
  assign io_out_s3_full_pred_1_is_ret = io_in_bits_resp_in_0_s3_full_pred_1_is_ret;
  assign io_out_s3_full_pred_1_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call;
  assign io_out_s3_full_pred_1_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing;
  assign io_out_s3_full_pred_1_hit = io_in_bits_resp_in_0_s3_full_pred_1_hit;
  assign io_out_s3_full_pred_2_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  assign io_out_s3_full_pred_2_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  assign io_out_s3_full_pred_2_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0;
  assign io_out_s3_full_pred_2_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1;
  assign io_out_s3_full_pred_2_targets_0 = io_in_bits_resp_in_0_s3_full_pred_2_targets_0;
  assign io_out_s3_full_pred_2_targets_1 = io_in_bits_resp_in_0_s3_full_pred_2_targets_1;
  assign io_out_s3_full_pred_2_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_2_offsets_0;
  assign io_out_s3_full_pred_2_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_2_offsets_1;
  assign io_out_s3_full_pred_2_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr;
  assign io_out_s3_full_pred_2_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  assign io_out_s3_full_pred_2_multiHit = io_in_bits_resp_in_0_s3_full_pred_2_multiHit;
  assign io_out_s3_full_pred_2_is_jal = io_in_bits_resp_in_0_s3_full_pred_2_is_jal;
  assign io_out_s3_full_pred_2_is_jalr = io_in_bits_resp_in_0_s3_full_pred_2_is_jalr;
  assign io_out_s3_full_pred_2_is_call = io_in_bits_resp_in_0_s3_full_pred_2_is_call;
  assign io_out_s3_full_pred_2_is_ret = io_in_bits_resp_in_0_s3_full_pred_2_is_ret;
  assign io_out_s3_full_pred_2_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call;
  assign io_out_s3_full_pred_2_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;
  assign io_out_s3_full_pred_2_hit = io_in_bits_resp_in_0_s3_full_pred_2_hit;
  assign io_out_s3_full_pred_3_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;
  assign io_out_s3_full_pred_3_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;
  assign io_out_s3_full_pred_3_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0;
  assign io_out_s3_full_pred_3_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1;
  assign io_out_s3_full_pred_3_targets_0 = io_in_bits_resp_in_0_s3_full_pred_3_targets_0;
  assign io_out_s3_full_pred_3_targets_1 = io_in_bits_resp_in_0_s3_full_pred_3_targets_1;
  assign io_out_s3_full_pred_3_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_3_offsets_0;
  assign io_out_s3_full_pred_3_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_3_offsets_1;
  assign io_out_s3_full_pred_3_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr;
  assign io_out_s3_full_pred_3_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr;
  assign io_out_s3_full_pred_3_multiHit = io_in_bits_resp_in_0_s3_full_pred_3_multiHit;
  assign io_out_s3_full_pred_3_is_jal = io_in_bits_resp_in_0_s3_full_pred_3_is_jal;
  assign io_out_s3_full_pred_3_is_jalr = io_in_bits_resp_in_0_s3_full_pred_3_is_jalr;
  assign io_out_s3_full_pred_3_is_call = io_in_bits_resp_in_0_s3_full_pred_3_is_call;
  assign io_out_s3_full_pred_3_is_ret = io_in_bits_resp_in_0_s3_full_pred_3_is_ret;
  assign io_out_s3_full_pred_3_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call;
  assign io_out_s3_full_pred_3_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing;
  assign io_out_s3_full_pred_3_hit = io_in_bits_resp_in_0_s3_full_pred_3_hit;
  assign io_out_last_stage_spec_info_sc_disagree_0 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;
  assign io_out_last_stage_spec_info_sc_disagree_1 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;
  assign io_out_last_stage_ftb_entry_isCall = io_in_bits_resp_in_0_last_stage_ftb_entry_isCall;
  assign io_out_last_stage_ftb_entry_isRet = io_in_bits_resp_in_0_last_stage_ftb_entry_isRet;
  assign io_out_last_stage_ftb_entry_isJalr = io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr;
  assign io_out_last_stage_ftb_entry_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_offset = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset;
  assign io_out_last_stage_ftb_entry_brSlots_0_sharing = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing;
  assign io_out_last_stage_ftb_entry_brSlots_0_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_lower = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower;
  assign io_out_last_stage_ftb_entry_brSlots_0_tarStat = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat;
  assign io_out_last_stage_ftb_entry_tailSlot_offset = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset;
  assign io_out_last_stage_ftb_entry_tailSlot_sharing = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing;
  assign io_out_last_stage_ftb_entry_tailSlot_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid;
  assign io_out_last_stage_ftb_entry_tailSlot_lower = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower;
  assign io_out_last_stage_ftb_entry_tailSlot_tarStat = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat;
  assign io_out_last_stage_ftb_entry_pftAddr = io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr;
  assign io_out_last_stage_ftb_entry_carry = io_in_bits_resp_in_0_last_stage_ftb_entry_carry;
  assign io_out_last_stage_ftb_entry_last_may_be_rvi_call = io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call;
  assign io_out_last_stage_ftb_entry_strong_bias_0 = io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0;
  assign io_out_last_stage_ftb_entry_strong_bias_1 = io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1;
endmodule
