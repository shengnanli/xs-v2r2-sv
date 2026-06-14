// 自动生成：scripts/gen_fauftb.py —— 勿手改
module FauFTB_xs(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
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
  output [515:0] io_out_last_stage_meta,
  output io_fauftb_entry_out_isCall,
  output io_fauftb_entry_out_isRet,
  output io_fauftb_entry_out_isJalr,
  output io_fauftb_entry_out_valid,
  output [3:0] io_fauftb_entry_out_brSlots_0_offset,
  output io_fauftb_entry_out_brSlots_0_sharing,
  output io_fauftb_entry_out_brSlots_0_valid,
  output [11:0] io_fauftb_entry_out_brSlots_0_lower,
  output [1:0] io_fauftb_entry_out_brSlots_0_tarStat,
  output [3:0] io_fauftb_entry_out_tailSlot_offset,
  output io_fauftb_entry_out_tailSlot_sharing,
  output io_fauftb_entry_out_tailSlot_valid,
  output [19:0] io_fauftb_entry_out_tailSlot_lower,
  output [1:0] io_fauftb_entry_out_tailSlot_tarStat,
  output [3:0] io_fauftb_entry_out_pftAddr,
  output io_fauftb_entry_out_carry,
  output io_fauftb_entry_out_last_may_be_rvi_call,
  output io_fauftb_entry_out_strong_bias_0,
  output io_fauftb_entry_out_strong_bias_1,
  output io_fauftb_entry_hit_out,
  input  io_ctrl_ubtb_enable,
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
  input  io_update_bits_br_taken_mask_0,
  input  io_update_bits_br_taken_mask_1,
  input  [515:0] io_update_bits_meta,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value
);

  wire fpw_br_taken_mask_0;
  wire fpw_br_taken_mask_1;
  wire fpw_slot_valids_0;
  wire fpw_slot_valids_1;
  wire [49:0] fpw_targets_0;
  wire [49:0] fpw_targets_1;
  wire [49:0] fpw_jalr_target;
  wire [3:0] fpw_offsets_0;
  wire [3:0] fpw_offsets_1;
  wire [49:0] fpw_fallThroughAddr;
  wire fpw_fallThroughErr;
  wire fpw_is_jal;
  wire fpw_is_jalr;
  wire fpw_is_call;
  wire fpw_is_ret;
  wire fpw_last_may_be_rvi_call;
  wire fpw_is_br_sharing;
  wire fpw_hit;

  xs_FauFTB_core #(
    .NUM_WAYS(32), .NUM_BR(2), .TAG_W(16), .PC_W(50), .RV_W(48), .META_W(516)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_reset_vector(io_reset_vector),
    .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3),
    .io_out_s1_pc_0(io_out_s1_pc_0),
    .io_out_s1_pc_1(io_out_s1_pc_1),
    .io_out_s1_pc_2(io_out_s1_pc_2),
    .io_out_s1_pc_3(io_out_s1_pc_3),
    .fp_br_taken_mask_0(fpw_br_taken_mask_0),
    .fp_br_taken_mask_1(fpw_br_taken_mask_1),
    .fp_slot_valids_0(fpw_slot_valids_0),
    .fp_slot_valids_1(fpw_slot_valids_1),
    .fp_targets_0(fpw_targets_0),
    .fp_targets_1(fpw_targets_1),
    .fp_jalr_target(fpw_jalr_target),
    .fp_offsets_0(fpw_offsets_0),
    .fp_offsets_1(fpw_offsets_1),
    .fp_fallThroughAddr(fpw_fallThroughAddr),
    .fp_fallThroughErr(fpw_fallThroughErr),
    .fp_is_jal(fpw_is_jal),
    .fp_is_jalr(fpw_is_jalr),
    .fp_is_call(fpw_is_call),
    .fp_is_ret(fpw_is_ret),
    .fp_last_may_be_rvi_call(fpw_last_may_be_rvi_call),
    .fp_is_br_sharing(fpw_is_br_sharing),
    .fp_hit(fpw_hit),
    .io_out_last_stage_meta(io_out_last_stage_meta),
    .io_fauftb_entry_out_isCall(io_fauftb_entry_out_isCall),
    .io_fauftb_entry_out_isRet(io_fauftb_entry_out_isRet),
    .io_fauftb_entry_out_isJalr(io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_out_valid(io_fauftb_entry_out_valid),
    .io_fauftb_entry_out_brSlots_0_offset(io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_out_brSlots_0_sharing(io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_out_brSlots_0_valid(io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_out_brSlots_0_lower(io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_out_brSlots_0_tarStat(io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_out_tailSlot_offset(io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_out_tailSlot_sharing(io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_out_tailSlot_valid(io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_out_tailSlot_lower(io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_out_tailSlot_tarStat(io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_out_pftAddr(io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_out_carry(io_fauftb_entry_out_carry),
    .io_fauftb_entry_out_last_may_be_rvi_call(io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_out_strong_bias_0(io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_out_strong_bias_1(io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_out(io_fauftb_entry_hit_out),
    .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable),
    .io_s0_fire_0(io_s0_fire_0),
    .io_s0_fire_1(io_s0_fire_1),
    .io_s0_fire_2(io_s0_fire_2),
    .io_s0_fire_3(io_s0_fire_3),
    .io_s1_fire_0(io_s1_fire_0),
    .io_s1_fire_1(io_s1_fire_1),
    .io_s1_fire_2(io_s1_fire_2),
    .io_s1_fire_3(io_s1_fire_3),
    .io_s2_fire_0(io_s2_fire_0),
    .io_s2_fire_1(io_s2_fire_1),
    .io_s2_fire_2(io_s2_fire_2),
    .io_s2_fire_3(io_s2_fire_3),
    .io_update_valid(io_update_valid),
    .io_update_bits_pc(io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall(io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet(io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr(io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid(io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset(io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing(io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid(io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower(io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat(io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing(io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower(io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat(io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr(io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry(io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call(io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0(io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1(io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0(io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1(io_update_bits_br_taken_mask_1),
    .io_update_bits_meta(io_update_bits_meta),
    .io_perf_0_value(io_perf_0_value),
    .io_perf_1_value(io_perf_1_value)
  );

  assign io_out_s1_full_pred_0_br_taken_mask_0 = fpw_br_taken_mask_0;
  assign io_out_s1_full_pred_0_br_taken_mask_1 = fpw_br_taken_mask_1;
  assign io_out_s1_full_pred_0_slot_valids_0 = fpw_slot_valids_0;
  assign io_out_s1_full_pred_0_slot_valids_1 = fpw_slot_valids_1;
  assign io_out_s1_full_pred_0_targets_0 = fpw_targets_0;
  assign io_out_s1_full_pred_0_targets_1 = fpw_targets_1;
  assign io_out_s1_full_pred_0_jalr_target = fpw_jalr_target;
  assign io_out_s1_full_pred_0_offsets_0 = fpw_offsets_0;
  assign io_out_s1_full_pred_0_offsets_1 = fpw_offsets_1;
  assign io_out_s1_full_pred_0_fallThroughAddr = fpw_fallThroughAddr;
  assign io_out_s1_full_pred_0_fallThroughErr = fpw_fallThroughErr;
  assign io_out_s1_full_pred_0_is_jal = fpw_is_jal;
  assign io_out_s1_full_pred_0_is_jalr = fpw_is_jalr;
  assign io_out_s1_full_pred_0_is_call = fpw_is_call;
  assign io_out_s1_full_pred_0_is_ret = fpw_is_ret;
  assign io_out_s1_full_pred_0_last_may_be_rvi_call = fpw_last_may_be_rvi_call;
  assign io_out_s1_full_pred_0_is_br_sharing = fpw_is_br_sharing;
  assign io_out_s1_full_pred_0_hit = fpw_hit;
  assign io_out_s1_full_pred_1_br_taken_mask_0 = fpw_br_taken_mask_0;
  assign io_out_s1_full_pred_1_br_taken_mask_1 = fpw_br_taken_mask_1;
  assign io_out_s1_full_pred_1_slot_valids_0 = fpw_slot_valids_0;
  assign io_out_s1_full_pred_1_slot_valids_1 = fpw_slot_valids_1;
  assign io_out_s1_full_pred_1_targets_0 = fpw_targets_0;
  assign io_out_s1_full_pred_1_targets_1 = fpw_targets_1;
  assign io_out_s1_full_pred_1_jalr_target = fpw_jalr_target;
  assign io_out_s1_full_pred_1_offsets_0 = fpw_offsets_0;
  assign io_out_s1_full_pred_1_offsets_1 = fpw_offsets_1;
  assign io_out_s1_full_pred_1_fallThroughAddr = fpw_fallThroughAddr;
  assign io_out_s1_full_pred_1_fallThroughErr = fpw_fallThroughErr;
  assign io_out_s1_full_pred_1_is_jal = fpw_is_jal;
  assign io_out_s1_full_pred_1_is_jalr = fpw_is_jalr;
  assign io_out_s1_full_pred_1_is_call = fpw_is_call;
  assign io_out_s1_full_pred_1_is_ret = fpw_is_ret;
  assign io_out_s1_full_pred_1_last_may_be_rvi_call = fpw_last_may_be_rvi_call;
  assign io_out_s1_full_pred_1_is_br_sharing = fpw_is_br_sharing;
  assign io_out_s1_full_pred_1_hit = fpw_hit;
  assign io_out_s1_full_pred_2_br_taken_mask_0 = fpw_br_taken_mask_0;
  assign io_out_s1_full_pred_2_br_taken_mask_1 = fpw_br_taken_mask_1;
  assign io_out_s1_full_pred_2_slot_valids_0 = fpw_slot_valids_0;
  assign io_out_s1_full_pred_2_slot_valids_1 = fpw_slot_valids_1;
  assign io_out_s1_full_pred_2_targets_0 = fpw_targets_0;
  assign io_out_s1_full_pred_2_targets_1 = fpw_targets_1;
  assign io_out_s1_full_pred_2_jalr_target = fpw_jalr_target;
  assign io_out_s1_full_pred_2_offsets_0 = fpw_offsets_0;
  assign io_out_s1_full_pred_2_offsets_1 = fpw_offsets_1;
  assign io_out_s1_full_pred_2_fallThroughAddr = fpw_fallThroughAddr;
  assign io_out_s1_full_pred_2_fallThroughErr = fpw_fallThroughErr;
  assign io_out_s1_full_pred_2_is_jal = fpw_is_jal;
  assign io_out_s1_full_pred_2_is_jalr = fpw_is_jalr;
  assign io_out_s1_full_pred_2_is_call = fpw_is_call;
  assign io_out_s1_full_pred_2_is_ret = fpw_is_ret;
  assign io_out_s1_full_pred_2_last_may_be_rvi_call = fpw_last_may_be_rvi_call;
  assign io_out_s1_full_pred_2_is_br_sharing = fpw_is_br_sharing;
  assign io_out_s1_full_pred_2_hit = fpw_hit;
  assign io_out_s1_full_pred_3_br_taken_mask_0 = fpw_br_taken_mask_0;
  assign io_out_s1_full_pred_3_br_taken_mask_1 = fpw_br_taken_mask_1;
  assign io_out_s1_full_pred_3_slot_valids_0 = fpw_slot_valids_0;
  assign io_out_s1_full_pred_3_slot_valids_1 = fpw_slot_valids_1;
  assign io_out_s1_full_pred_3_targets_0 = fpw_targets_0;
  assign io_out_s1_full_pred_3_targets_1 = fpw_targets_1;
  assign io_out_s1_full_pred_3_jalr_target = fpw_jalr_target;
  assign io_out_s1_full_pred_3_offsets_0 = fpw_offsets_0;
  assign io_out_s1_full_pred_3_offsets_1 = fpw_offsets_1;
  assign io_out_s1_full_pred_3_fallThroughAddr = fpw_fallThroughAddr;
  assign io_out_s1_full_pred_3_fallThroughErr = fpw_fallThroughErr;
  assign io_out_s1_full_pred_3_is_jal = fpw_is_jal;
  assign io_out_s1_full_pred_3_is_jalr = fpw_is_jalr;
  assign io_out_s1_full_pred_3_is_call = fpw_is_call;
  assign io_out_s1_full_pred_3_is_ret = fpw_is_ret;
  assign io_out_s1_full_pred_3_last_may_be_rvi_call = fpw_last_may_be_rvi_call;
  assign io_out_s1_full_pred_3_is_br_sharing = fpw_is_br_sharing;
  assign io_out_s1_full_pred_3_hit = fpw_hit;
endmodule
