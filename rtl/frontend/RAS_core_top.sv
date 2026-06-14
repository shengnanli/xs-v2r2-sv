// 自动生成：scripts/gen_ras.py —— 勿手改
// xs_RAS_core: RAS 顶层 (BasePredictor 包装层)，与 golden RAS 同端口。
module xs_RAS_core(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
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
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_jalr_target,
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
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_jalr_target,
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
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_jalr_target,
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
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_jalr_target,
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
  input  io_s3_fire_2,
  input  io_s3_redirect_2,
  input  io_update_valid,
  input  io_update_bits_ftb_entry_isCall,
  input  io_update_bits_ftb_entry_isRet,
  input  [3:0] io_update_bits_ftb_entry_tailSlot_offset,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  io_update_bits_cfi_idx_valid,
  input  [3:0] io_update_bits_cfi_idx_bits,
  input  io_update_bits_jmp_taken,
  input  [515:0] io_update_bits_meta,
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
  input  [4:0] io_redirect_bits_cfiUpdate_NOS_value
);

  // RASStack 输出连线 (提前声明, 供各段引用)
  wire        s2_spec_push, s2_spec_pop;
  wire [49:0] _RASStack_io_spec_pop_addr;
  wire [3:0]  _RASStack_io_ssp;
  wire [2:0]  _RASStack_io_sctr;
  wire        _RASStack_io_TOSR_flag;  wire [4:0] _RASStack_io_TOSR_value;
  wire        _RASStack_io_TOSW_flag;  wire [4:0] _RASStack_io_TOSW_value;
  wire        _RASStack_io_NOS_flag;   wire [4:0] _RASStack_io_NOS_value;
  wire        _RASStack_io_spec_near_overflow;

  // s2->s3 锁存 (提前声明)
  reg  [49:0] s3_top;
  reg  [49:0] s3_spec_new_addr;
  reg         s3_pushed_in_s2, s3_popped_in_s2;
  reg  [3:0]  s3_meta_ssp;
  reg  [2:0]  s3_meta_sctr;
  reg         s3_meta_TOSW_flag;  reg [4:0] s3_meta_TOSW_value;
  reg         s3_meta_TOSR_flag;  reg [4:0] s3_meta_TOSR_value;
  reg         s3_meta_NOS_flag;   reg [4:0] s3_meta_NOS_value;

  // ==========================================================================
  // 1. s2/s3 推测 push/pop 触发条件 (来自 s2/s3 full_pred(2))
  // ==========================================================================
  // hit_taken_on_call/ret 的展开 (Chisel BranchPrediction.hit_taken_on_*)
  wire s2_realtaken_0 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0
                      & io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  wire s2_realtaken_1 = io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing
                      & io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  // taken_on_tail = !(br0 taken) & slot1 valid & (br1taken | !sharing) & hit & !sharing
  wire s2_taken_on_tail =
        ~(s2_realtaken_0 & io_in_bits_resp_in_0_s2_full_pred_2_hit)
      & io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1
      & (s2_realtaken_1 | ~io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing)
      & io_in_bits_resp_in_0_s2_full_pred_2_hit
      & ~io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;
  assign s2_spec_push = io_s2_fire_2 & s2_taken_on_tail
                      & io_in_bits_resp_in_0_s2_full_pred_2_is_call & ~io_s3_redirect_2;
  assign s2_spec_pop  = io_s2_fire_2 & s2_taken_on_tail
                      & io_in_bits_resp_in_0_s2_full_pred_2_is_ret  & ~io_s3_redirect_2;

  // s2 推测新地址 = fallThroughAddr + (last_may_be_rvi_call ? 2 : 0)
  wire [49:0] s2_spec_new_addr =
        io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr
      + {48'h0, io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call, 1'h0};

  // s2 ret 命中时用栈顶覆盖 jalr_target
  wire s2_use_ras = io_in_bits_resp_in_0_s2_full_pred_2_is_ret & io_ctrl_ras_enable;
  wire [49:0] s2_jalr_target_0 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_0_jalr_target;
  wire [49:0] s2_jalr_target_1 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_1_jalr_target;
  wire [49:0] s2_jalr_target_2 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_2_jalr_target;
  wire [49:0] s2_jalr_target_3 = s2_use_ras ? _RASStack_io_spec_pop_addr
                                            : io_in_bits_resp_in_0_s2_full_pred_3_jalr_target;

  // s3 阶段
  wire s3_is_jalr = io_in_bits_resp_in_0_s3_full_pred_2_is_jalr
                  & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  wire s3_use_ras = io_in_bits_resp_in_0_s3_full_pred_2_is_ret
                  & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr & io_ctrl_ras_enable;
  wire [49:0] s3_jalr_target_0 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_0_jalr_target;
  wire [49:0] s3_jalr_target_1 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_1_jalr_target;
  wire [49:0] s3_jalr_target_2 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_2_jalr_target;
  wire [49:0] s3_jalr_target_3 = s3_use_ras ? s3_top : io_in_bits_resp_in_0_s3_full_pred_3_jalr_target;

  wire s3_realtaken_0 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0
                      & io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  wire s3_realtaken_1 = io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing
                      & io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  wire s3_taken_on_tail =
        ~(s3_realtaken_0 & io_in_bits_resp_in_0_s3_full_pred_2_hit)
      & io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1
      & (s3_realtaken_1 | ~io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing)
      & io_in_bits_resp_in_0_s3_full_pred_2_hit
      & ~io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;
  wire s3_push = s3_taken_on_tail & io_in_bits_resp_in_0_s3_full_pred_2_is_call
               & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  wire s3_pop  = s3_taken_on_tail & io_in_bits_resp_in_0_s3_full_pred_2_is_ret
               & ~io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;
  wire s3_cancel = io_s3_fire_2 & ((s3_pushed_in_s2 != s3_push) | (s3_popped_in_s2 != s3_pop));

  // ==========================================================================
  // 2. 流水 pc 复制寄存器 (debug 用，原样复刻 firtool 的分段更新)
  // ==========================================================================
  reg  [49:0] s1_pc_dup_0, s1_pc_dup_1, s1_pc_dup_2, s1_pc_dup_3;
  reg  [25:0] s2_pc_seg0 [0:3];
  reg  [11:0] s2_pc_seg1 [0:3];
  reg  [11:0] s2_pc_seg2 [0:3];
  reg  [25:0] s3_pc_seg0 [0:3];
  reg  [11:0] s3_pc_seg1 [0:3];
  reg  [11:0] s3_pc_seg2 [0:3];
  reg         REG, REG_1;

  wire [49:0] s1_pc [0:3];
  assign s1_pc[0] = s1_pc_dup_0; assign s1_pc[1] = s1_pc_dup_1;
  assign s1_pc[2] = s1_pc_dup_2; assign s1_pc[3] = s1_pc_dup_3;
  wire [49:0] s0_pc [0:3];
  assign s0_pc[0] = io_in_bits_s0_pc_0; assign s0_pc[1] = io_in_bits_s0_pc_1;
  assign s0_pc[2] = io_in_bits_s0_pc_2; assign s0_pc[3] = io_in_bits_s0_pc_3;
  wire [3:0] s0_fire = {io_s0_fire_3, io_s0_fire_2, io_s0_fire_1, io_s0_fire_0};
  wire [3:0] s1_fire = {io_s1_fire_3, io_s1_fire_2, io_s1_fire_1, io_s1_fire_0};
  wire [3:0] s2_fire = {io_s2_fire_3, io_s2_fire_2, io_s2_fire_1, io_s2_fire_0};

  wire [49:0] _rstvec = {2'h0, io_reset_vector};

  // s2_pc 重组地址 (供 io_out_s2_pc_*)
  wire [49:0] s2_pc_addr [0:3];
  wire [49:0] s3_pc_addr [0:3];
  genvar gp;
  generate
    for (gp = 0; gp < 4; gp = gp + 1) begin : g_pc_addr
      assign s2_pc_addr[gp] = {s2_pc_seg0[gp], s2_pc_seg1[gp], s2_pc_seg2[gp]};
      assign s3_pc_addr[gp] = {s3_pc_seg0[gp], s3_pc_seg1[gp], s3_pc_seg2[gp]};
    end
  endgenerate

  always @(posedge clock) begin
    if (REG_1) begin
      s1_pc_dup_0 <= _rstvec; s1_pc_dup_1 <= _rstvec;
      s1_pc_dup_2 <= _rstvec; s1_pc_dup_3 <= _rstvec;
    end else begin
      if (io_s0_fire_0) s1_pc_dup_0 <= io_in_bits_s0_pc_0;
      if (io_s0_fire_1) s1_pc_dup_1 <= io_in_bits_s0_pc_1;
      if (io_s0_fire_2) s1_pc_dup_2 <= io_in_bits_s0_pc_2;
      if (io_s0_fire_3) s1_pc_dup_3 <= io_in_bits_s0_pc_3;
    end
    REG   <= reset;
    REG_1 <= REG & ~reset;
  end

  integer pi;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      for (pi = 0; pi < 4; pi = pi + 1) begin
        s2_pc_seg0[pi] <= 26'h0; s2_pc_seg1[pi] <= 12'h0; s2_pc_seg2[pi] <= 12'h0;
        s3_pc_seg0[pi] <= 26'h0; s3_pc_seg1[pi] <= 12'h0; s3_pc_seg2[pi] <= 12'h0;
      end
    end else begin
      for (pi = 0; pi < 4; pi = pi + 1) begin
        // s2 段: 仅当对应段与 s1_pc 不同且 s1_fire 时更新
        if ((s2_pc_seg0[pi] != s1_pc[pi][49:24]) & s1_fire[pi]) s2_pc_seg0[pi] <= s1_pc[pi][49:24];
        if ((s2_pc_seg1[pi] != s1_pc[pi][23:12]) & s1_fire[pi]) s2_pc_seg1[pi] <= s1_pc[pi][23:12];
        if (s1_fire[pi])                                        s2_pc_seg2[pi] <= s1_pc[pi][11:0];
        // s3 段: 与 s2 段比较
        if ((s3_pc_seg0[pi] != s2_pc_seg0[pi]) & s2_fire[pi]) s3_pc_seg0[pi] <= s2_pc_seg0[pi];
        if ((s3_pc_seg1[pi] != s2_pc_seg1[pi]) & s2_fire[pi]) s3_pc_seg1[pi] <= s2_pc_seg1[pi];
        if (s2_fire[pi])                                      s3_pc_seg2[pi] <= s2_pc_seg2[pi];
      end
    end
  end

  // ==========================================================================
  // 3. s2->s3 meta / 推测信息打拍
  // ==========================================================================
  always @(posedge clock) begin
    if (io_s2_fire_2) begin
      s3_top            <= _RASStack_io_spec_pop_addr;
      s3_spec_new_addr  <= s2_spec_new_addr;
      s3_pushed_in_s2   <= s2_spec_push;
      s3_popped_in_s2   <= s2_spec_pop;
      s3_meta_ssp       <= _RASStack_io_ssp;
      s3_meta_sctr      <= _RASStack_io_sctr;
      s3_meta_TOSW_flag <= _RASStack_io_TOSW_flag;
      s3_meta_TOSW_value<= _RASStack_io_TOSW_value;
      s3_meta_TOSR_flag <= _RASStack_io_TOSR_flag;
      s3_meta_TOSR_value<= _RASStack_io_TOSR_value;
      s3_meta_NOS_flag  <= _RASStack_io_NOS_flag;
      s3_meta_NOS_value <= _RASStack_io_NOS_value;
    end
  end

  // ==========================================================================
  // 4. redirect / update 输入打拍
  // ==========================================================================
  reg         redirect_valid_q;
  reg         redirect_level_q;
  reg  [49:0] redirect_pc_q;
  reg         redirect_pd_valid_q, redirect_pd_isRVC_q, redirect_pd_isCall_q, redirect_pd_isRet_q;
  reg  [3:0]  redirect_ssp_q;
  reg  [2:0]  redirect_sctr_q;
  reg         redirect_TOSW_flag_q;  reg [4:0] redirect_TOSW_value_q;
  reg         redirect_TOSR_flag_q;  reg [4:0] redirect_TOSR_value_q;
  reg         redirect_NOS_flag_q;   reg [4:0] redirect_NOS_value_q;

  reg         updateValid;
  reg         update_isCall_q, update_isRet_q;
  reg  [3:0]  update_tailOff_q;
  reg         update_tailValid_q;
  reg         update_cfiValid_q;
  reg  [3:0]  update_cfiBits_q;
  reg         update_jmpTaken_q;
  reg  [3:0]  updateMeta_ssp;
  reg         updateMeta_TOSW_flag;  reg [4:0] updateMeta_TOSW_value;

  always @(posedge clock) begin
    if (io_redirect_valid) begin
      redirect_level_q     <= io_redirect_bits_level;
      redirect_pc_q        <= io_redirect_bits_cfiUpdate_pc;
      redirect_pd_valid_q  <= io_redirect_bits_cfiUpdate_pd_valid;
      redirect_pd_isRVC_q  <= io_redirect_bits_cfiUpdate_pd_isRVC;
      redirect_pd_isCall_q <= io_redirect_bits_cfiUpdate_pd_isCall;
      redirect_pd_isRet_q  <= io_redirect_bits_cfiUpdate_pd_isRet;
      redirect_ssp_q       <= io_redirect_bits_cfiUpdate_ssp;
      redirect_sctr_q      <= io_redirect_bits_cfiUpdate_sctr;
      redirect_TOSW_flag_q <= io_redirect_bits_cfiUpdate_TOSW_flag;
      redirect_TOSW_value_q<= io_redirect_bits_cfiUpdate_TOSW_value;
      redirect_TOSR_flag_q <= io_redirect_bits_cfiUpdate_TOSR_flag;
      redirect_TOSR_value_q<= io_redirect_bits_cfiUpdate_TOSR_value;
      redirect_NOS_flag_q  <= io_redirect_bits_cfiUpdate_NOS_flag;
      redirect_NOS_value_q <= io_redirect_bits_cfiUpdate_NOS_value;
    end
    if (io_update_valid) begin
      update_isCall_q   <= io_update_bits_ftb_entry_isCall;
      update_isRet_q    <= io_update_bits_ftb_entry_isRet;
      update_tailOff_q  <= io_update_bits_ftb_entry_tailSlot_offset;
      update_tailValid_q<= io_update_bits_ftb_entry_tailSlot_valid;
      update_cfiValid_q <= io_update_bits_cfi_idx_valid;
      update_cfiBits_q  <= io_update_bits_cfi_idx_bits;
      update_jmpTaken_q <= io_update_bits_jmp_taken;
      updateMeta_ssp        <= io_update_bits_meta[9:6];
      updateMeta_TOSW_flag  <= io_update_bits_meta[5];
      updateMeta_TOSW_value <= io_update_bits_meta[4:0];
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      redirect_valid_q <= 1'h0;
      updateValid      <= 1'h0;
    end else begin
      redirect_valid_q <= io_redirect_valid;
      updateValid      <= io_update_valid;
    end
  end

  // ==========================================================================
  // 5. RASStack 输入构造 + 实例化
  // ==========================================================================
  // commit push/pop 限定: updateValid & tailSlot 有效 & isCall/isRet & jmp_taken & cfi 有效 & cfi==tailOff
  wire update_cfi_at_tail = (update_cfiBits_q == update_tailOff_q);
  wire commit_base = updateValid & update_tailValid_q & update_jmpTaken_q
                   & update_cfiValid_q & update_cfi_at_tail;
  wire commit_push = commit_base & update_isCall_q;
  wire commit_pop  = commit_base & update_isRet_q;

  // redirect 恢复条件: isBefore(redirect_TOSW, stack_TOSW) | !near_overflow
  wire redirect_isBefore_TOSW =
        (redirect_TOSW_flag_q ^ _RASStack_io_TOSW_flag)
      ^ (redirect_TOSW_value_q < _RASStack_io_TOSW_value);
  wire stack_redirect_valid = redirect_valid_q
                            & (redirect_isBefore_TOSW | ~_RASStack_io_spec_near_overflow);
  wire stack_redirect_isCall = redirect_valid_q & ~redirect_level_q
                             & redirect_pd_isCall_q & redirect_pd_valid_q;
  wire stack_redirect_isRet  = redirect_valid_q & ~redirect_level_q
                             & redirect_pd_isRet_q  & redirect_pd_valid_q;
  wire [49:0] redirect_callAddr =
        redirect_pc_q + {47'h0, redirect_pd_isRVC_q ? 3'h2 : 3'h4};

  xs_RASStack RASStack (
    .clock(clock), .reset(reset),
    .io_spec_push_valid (s2_spec_push & ~_RASStack_io_spec_near_overflow),
    .io_spec_pop_valid  (s2_spec_pop  & ~_RASStack_io_spec_near_overflow),
    .io_spec_push_addr  (s2_spec_new_addr),
    .io_s2_fire         (io_s2_fire_2),
    .io_s3_fire         (io_s3_fire_2),
    .io_s3_cancel       (s3_cancel & ~_RASStack_io_spec_near_overflow),
    .io_s3_meta_ssp        (s3_meta_ssp),
    .io_s3_meta_sctr       (s3_meta_sctr),
    .io_s3_meta_TOSW_flag  (s3_meta_TOSW_flag),
    .io_s3_meta_TOSW_value (s3_meta_TOSW_value),
    .io_s3_meta_TOSR_flag  (s3_meta_TOSR_flag),
    .io_s3_meta_TOSR_value (s3_meta_TOSR_value),
    .io_s3_meta_NOS_flag   (s3_meta_NOS_flag),
    .io_s3_meta_NOS_value  (s3_meta_NOS_value),
    .io_s3_missed_pop   (s3_pop  & ~s3_popped_in_s2),
    .io_s3_missed_push  (s3_push & ~s3_pushed_in_s2),
    .io_s3_pushAddr     (s3_spec_new_addr),
    .io_spec_pop_addr   (_RASStack_io_spec_pop_addr),
    .io_commit_valid      (updateValid),
    .io_commit_push_valid (commit_push),
    .io_commit_pop_valid  (commit_pop),
    .io_commit_meta_TOSW_flag  (updateMeta_TOSW_flag),
    .io_commit_meta_TOSW_value (updateMeta_TOSW_value),
    .io_commit_meta_ssp        (updateMeta_ssp),
    .io_redirect_valid   (stack_redirect_valid),
    .io_redirect_isCall  (stack_redirect_isCall),
    .io_redirect_isRet   (stack_redirect_isRet),
    .io_redirect_meta_ssp        (redirect_ssp_q),
    .io_redirect_meta_sctr       (redirect_sctr_q),
    .io_redirect_meta_TOSW_flag  (redirect_TOSW_flag_q),
    .io_redirect_meta_TOSW_value (redirect_TOSW_value_q),
    .io_redirect_meta_TOSR_flag  (redirect_TOSR_flag_q),
    .io_redirect_meta_TOSR_value (redirect_TOSR_value_q),
    .io_redirect_meta_NOS_flag   (redirect_NOS_flag_q),
    .io_redirect_meta_NOS_value  (redirect_NOS_value_q),
    .io_redirect_callAddr (redirect_callAddr),
    .io_ssp(_RASStack_io_ssp), .io_sctr(_RASStack_io_sctr),
    .io_TOSR_flag(_RASStack_io_TOSR_flag), .io_TOSR_value(_RASStack_io_TOSR_value),
    .io_TOSW_flag(_RASStack_io_TOSW_flag), .io_TOSW_value(_RASStack_io_TOSW_value),
    .io_NOS_flag(_RASStack_io_NOS_flag),   .io_NOS_value(_RASStack_io_NOS_value),
    .io_spec_near_overflow(_RASStack_io_spec_near_overflow)
  );

  // ==========================================================================
  // 6. 输出
  // ==========================================================================
  assign io_out_s2_pc_0 = s2_pc_addr[0];
  assign io_out_s2_pc_1 = s2_pc_addr[1];
  assign io_out_s2_pc_2 = s2_pc_addr[2];
  assign io_out_s2_pc_3 = s2_pc_addr[3];
  assign io_out_s3_pc_0 = s3_pc_addr[0];
  assign io_out_s3_pc_1 = s3_pc_addr[1];
  assign io_out_s3_pc_2 = s3_pc_addr[2];
  assign io_out_s3_pc_3 = s3_pc_addr[3];

  assign io_out_last_stage_meta =
    {506'h0, s3_meta_ssp, s3_meta_TOSW_flag, s3_meta_TOSW_value};
  assign io_out_last_stage_spec_info_ssp        = s3_meta_ssp;
  assign io_out_last_stage_spec_info_sctr       = s3_meta_sctr;
  assign io_out_last_stage_spec_info_TOSW_flag  = s3_meta_TOSW_flag;
  assign io_out_last_stage_spec_info_TOSW_value = s3_meta_TOSW_value;
  assign io_out_last_stage_spec_info_TOSR_flag  = s3_meta_TOSR_flag;
  assign io_out_last_stage_spec_info_TOSR_value = s3_meta_TOSR_value;
  assign io_out_last_stage_spec_info_NOS_flag   = s3_meta_NOS_flag;
  assign io_out_last_stage_spec_info_NOS_value  = s3_meta_NOS_value;
  assign io_out_last_stage_spec_info_topAddr    = s3_top;

  // s2/s3 各通道的 jalr_target / targets_1 改写
  assign io_out_s2_full_pred_0_jalr_target = s2_jalr_target_0;
  assign io_out_s2_full_pred_0_targets_1 = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr ? s2_jalr_target_0 : io_in_bits_resp_in_0_s2_full_pred_0_targets_1;
  assign io_out_s2_full_pred_1_jalr_target = s2_jalr_target_1;
  assign io_out_s2_full_pred_1_targets_1 = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr ? s2_jalr_target_1 : io_in_bits_resp_in_0_s2_full_pred_1_targets_1;
  assign io_out_s2_full_pred_2_jalr_target = s2_jalr_target_2;
  assign io_out_s2_full_pred_2_targets_1 = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr ? s2_jalr_target_2 : io_in_bits_resp_in_0_s2_full_pred_2_targets_1;
  assign io_out_s2_full_pred_3_jalr_target = s2_jalr_target_3;
  assign io_out_s2_full_pred_3_targets_1 = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr ? s2_jalr_target_3 : io_in_bits_resp_in_0_s2_full_pred_3_targets_1;
  assign io_out_s3_full_pred_0_jalr_target = s3_jalr_target_0;
  assign io_out_s3_full_pred_0_targets_1 = s3_is_jalr ? s3_jalr_target_0 : io_in_bits_resp_in_0_s3_full_pred_0_targets_1;
  assign io_out_s3_full_pred_1_jalr_target = s3_jalr_target_1;
  assign io_out_s3_full_pred_1_targets_1 = s3_is_jalr ? s3_jalr_target_1 : io_in_bits_resp_in_0_s3_full_pred_1_targets_1;
  assign io_out_s3_full_pred_2_jalr_target = s3_jalr_target_2;
  assign io_out_s3_full_pred_2_targets_1 = s3_is_jalr ? s3_jalr_target_2 : io_in_bits_resp_in_0_s3_full_pred_2_targets_1;
  assign io_out_s3_full_pred_3_jalr_target = s3_jalr_target_3;
  assign io_out_s3_full_pred_3_targets_1 = s3_is_jalr ? s3_jalr_target_3 : io_in_bits_resp_in_0_s3_full_pred_3_targets_1;
  // 其余 io_out_* 透传
  assign io_out_s2_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  assign io_out_s2_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  assign io_out_s2_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0;
  assign io_out_s2_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1;
  assign io_out_s2_full_pred_0_targets_0 = io_in_bits_resp_in_0_s2_full_pred_0_targets_0;
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
