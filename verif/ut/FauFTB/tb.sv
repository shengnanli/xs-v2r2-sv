// 自动生成：scripts/gen_fauftb.py —— 勿手改
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
  logic io_ctrl_ubtb_enable;
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
  logic io_update_valid;
  logic [49:0] io_update_bits_pc;
  logic io_update_bits_ftb_entry_isCall;
  logic io_update_bits_ftb_entry_isRet;
  logic io_update_bits_ftb_entry_isJalr;
  logic io_update_bits_ftb_entry_valid;
  logic [3:0] io_update_bits_ftb_entry_brSlots_0_offset;
  logic io_update_bits_ftb_entry_brSlots_0_sharing;
  logic io_update_bits_ftb_entry_brSlots_0_valid;
  logic [11:0] io_update_bits_ftb_entry_brSlots_0_lower;
  logic [1:0] io_update_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0] io_update_bits_ftb_entry_tailSlot_offset;
  logic io_update_bits_ftb_entry_tailSlot_sharing;
  logic io_update_bits_ftb_entry_tailSlot_valid;
  logic [19:0] io_update_bits_ftb_entry_tailSlot_lower;
  logic [1:0] io_update_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0] io_update_bits_ftb_entry_pftAddr;
  logic io_update_bits_ftb_entry_carry;
  logic io_update_bits_ftb_entry_last_may_be_rvi_call;
  logic io_update_bits_ftb_entry_strong_bias_0;
  logic io_update_bits_ftb_entry_strong_bias_1;
  logic io_update_bits_br_taken_mask_0;
  logic io_update_bits_br_taken_mask_1;
  logic [515:0] io_update_bits_meta;
  wire [49:0] g_io_out_s1_pc_0;
  wire [49:0] i_io_out_s1_pc_0;
  wire [49:0] g_io_out_s1_pc_1;
  wire [49:0] i_io_out_s1_pc_1;
  wire [49:0] g_io_out_s1_pc_2;
  wire [49:0] i_io_out_s1_pc_2;
  wire [49:0] g_io_out_s1_pc_3;
  wire [49:0] i_io_out_s1_pc_3;
  wire g_io_out_s1_full_pred_0_br_taken_mask_0;
  wire i_io_out_s1_full_pred_0_br_taken_mask_0;
  wire g_io_out_s1_full_pred_0_br_taken_mask_1;
  wire i_io_out_s1_full_pred_0_br_taken_mask_1;
  wire g_io_out_s1_full_pred_0_slot_valids_0;
  wire i_io_out_s1_full_pred_0_slot_valids_0;
  wire g_io_out_s1_full_pred_0_slot_valids_1;
  wire i_io_out_s1_full_pred_0_slot_valids_1;
  wire [49:0] g_io_out_s1_full_pred_0_targets_0;
  wire [49:0] i_io_out_s1_full_pred_0_targets_0;
  wire [49:0] g_io_out_s1_full_pred_0_targets_1;
  wire [49:0] i_io_out_s1_full_pred_0_targets_1;
  wire [49:0] g_io_out_s1_full_pred_0_jalr_target;
  wire [49:0] i_io_out_s1_full_pred_0_jalr_target;
  wire [3:0] g_io_out_s1_full_pred_0_offsets_0;
  wire [3:0] i_io_out_s1_full_pred_0_offsets_0;
  wire [3:0] g_io_out_s1_full_pred_0_offsets_1;
  wire [3:0] i_io_out_s1_full_pred_0_offsets_1;
  wire [49:0] g_io_out_s1_full_pred_0_fallThroughAddr;
  wire [49:0] i_io_out_s1_full_pred_0_fallThroughAddr;
  wire g_io_out_s1_full_pred_0_fallThroughErr;
  wire i_io_out_s1_full_pred_0_fallThroughErr;
  wire g_io_out_s1_full_pred_0_is_jal;
  wire i_io_out_s1_full_pred_0_is_jal;
  wire g_io_out_s1_full_pred_0_is_jalr;
  wire i_io_out_s1_full_pred_0_is_jalr;
  wire g_io_out_s1_full_pred_0_is_call;
  wire i_io_out_s1_full_pred_0_is_call;
  wire g_io_out_s1_full_pred_0_is_ret;
  wire i_io_out_s1_full_pred_0_is_ret;
  wire g_io_out_s1_full_pred_0_last_may_be_rvi_call;
  wire i_io_out_s1_full_pred_0_last_may_be_rvi_call;
  wire g_io_out_s1_full_pred_0_is_br_sharing;
  wire i_io_out_s1_full_pred_0_is_br_sharing;
  wire g_io_out_s1_full_pred_0_hit;
  wire i_io_out_s1_full_pred_0_hit;
  wire g_io_out_s1_full_pred_1_br_taken_mask_0;
  wire i_io_out_s1_full_pred_1_br_taken_mask_0;
  wire g_io_out_s1_full_pred_1_br_taken_mask_1;
  wire i_io_out_s1_full_pred_1_br_taken_mask_1;
  wire g_io_out_s1_full_pred_1_slot_valids_0;
  wire i_io_out_s1_full_pred_1_slot_valids_0;
  wire g_io_out_s1_full_pred_1_slot_valids_1;
  wire i_io_out_s1_full_pred_1_slot_valids_1;
  wire [49:0] g_io_out_s1_full_pred_1_targets_0;
  wire [49:0] i_io_out_s1_full_pred_1_targets_0;
  wire [49:0] g_io_out_s1_full_pred_1_targets_1;
  wire [49:0] i_io_out_s1_full_pred_1_targets_1;
  wire [49:0] g_io_out_s1_full_pred_1_jalr_target;
  wire [49:0] i_io_out_s1_full_pred_1_jalr_target;
  wire [3:0] g_io_out_s1_full_pred_1_offsets_0;
  wire [3:0] i_io_out_s1_full_pred_1_offsets_0;
  wire [3:0] g_io_out_s1_full_pred_1_offsets_1;
  wire [3:0] i_io_out_s1_full_pred_1_offsets_1;
  wire [49:0] g_io_out_s1_full_pred_1_fallThroughAddr;
  wire [49:0] i_io_out_s1_full_pred_1_fallThroughAddr;
  wire g_io_out_s1_full_pred_1_fallThroughErr;
  wire i_io_out_s1_full_pred_1_fallThroughErr;
  wire g_io_out_s1_full_pred_1_is_jal;
  wire i_io_out_s1_full_pred_1_is_jal;
  wire g_io_out_s1_full_pred_1_is_jalr;
  wire i_io_out_s1_full_pred_1_is_jalr;
  wire g_io_out_s1_full_pred_1_is_call;
  wire i_io_out_s1_full_pred_1_is_call;
  wire g_io_out_s1_full_pred_1_is_ret;
  wire i_io_out_s1_full_pred_1_is_ret;
  wire g_io_out_s1_full_pred_1_last_may_be_rvi_call;
  wire i_io_out_s1_full_pred_1_last_may_be_rvi_call;
  wire g_io_out_s1_full_pred_1_is_br_sharing;
  wire i_io_out_s1_full_pred_1_is_br_sharing;
  wire g_io_out_s1_full_pred_1_hit;
  wire i_io_out_s1_full_pred_1_hit;
  wire g_io_out_s1_full_pred_2_br_taken_mask_0;
  wire i_io_out_s1_full_pred_2_br_taken_mask_0;
  wire g_io_out_s1_full_pred_2_br_taken_mask_1;
  wire i_io_out_s1_full_pred_2_br_taken_mask_1;
  wire g_io_out_s1_full_pred_2_slot_valids_0;
  wire i_io_out_s1_full_pred_2_slot_valids_0;
  wire g_io_out_s1_full_pred_2_slot_valids_1;
  wire i_io_out_s1_full_pred_2_slot_valids_1;
  wire [49:0] g_io_out_s1_full_pred_2_targets_0;
  wire [49:0] i_io_out_s1_full_pred_2_targets_0;
  wire [49:0] g_io_out_s1_full_pred_2_targets_1;
  wire [49:0] i_io_out_s1_full_pred_2_targets_1;
  wire [49:0] g_io_out_s1_full_pred_2_jalr_target;
  wire [49:0] i_io_out_s1_full_pred_2_jalr_target;
  wire [3:0] g_io_out_s1_full_pred_2_offsets_0;
  wire [3:0] i_io_out_s1_full_pred_2_offsets_0;
  wire [3:0] g_io_out_s1_full_pred_2_offsets_1;
  wire [3:0] i_io_out_s1_full_pred_2_offsets_1;
  wire [49:0] g_io_out_s1_full_pred_2_fallThroughAddr;
  wire [49:0] i_io_out_s1_full_pred_2_fallThroughAddr;
  wire g_io_out_s1_full_pred_2_fallThroughErr;
  wire i_io_out_s1_full_pred_2_fallThroughErr;
  wire g_io_out_s1_full_pred_2_is_jal;
  wire i_io_out_s1_full_pred_2_is_jal;
  wire g_io_out_s1_full_pred_2_is_jalr;
  wire i_io_out_s1_full_pred_2_is_jalr;
  wire g_io_out_s1_full_pred_2_is_call;
  wire i_io_out_s1_full_pred_2_is_call;
  wire g_io_out_s1_full_pred_2_is_ret;
  wire i_io_out_s1_full_pred_2_is_ret;
  wire g_io_out_s1_full_pred_2_last_may_be_rvi_call;
  wire i_io_out_s1_full_pred_2_last_may_be_rvi_call;
  wire g_io_out_s1_full_pred_2_is_br_sharing;
  wire i_io_out_s1_full_pred_2_is_br_sharing;
  wire g_io_out_s1_full_pred_2_hit;
  wire i_io_out_s1_full_pred_2_hit;
  wire g_io_out_s1_full_pred_3_br_taken_mask_0;
  wire i_io_out_s1_full_pred_3_br_taken_mask_0;
  wire g_io_out_s1_full_pred_3_br_taken_mask_1;
  wire i_io_out_s1_full_pred_3_br_taken_mask_1;
  wire g_io_out_s1_full_pred_3_slot_valids_0;
  wire i_io_out_s1_full_pred_3_slot_valids_0;
  wire g_io_out_s1_full_pred_3_slot_valids_1;
  wire i_io_out_s1_full_pred_3_slot_valids_1;
  wire [49:0] g_io_out_s1_full_pred_3_targets_0;
  wire [49:0] i_io_out_s1_full_pred_3_targets_0;
  wire [49:0] g_io_out_s1_full_pred_3_targets_1;
  wire [49:0] i_io_out_s1_full_pred_3_targets_1;
  wire [49:0] g_io_out_s1_full_pred_3_jalr_target;
  wire [49:0] i_io_out_s1_full_pred_3_jalr_target;
  wire [3:0] g_io_out_s1_full_pred_3_offsets_0;
  wire [3:0] i_io_out_s1_full_pred_3_offsets_0;
  wire [3:0] g_io_out_s1_full_pred_3_offsets_1;
  wire [3:0] i_io_out_s1_full_pred_3_offsets_1;
  wire [49:0] g_io_out_s1_full_pred_3_fallThroughAddr;
  wire [49:0] i_io_out_s1_full_pred_3_fallThroughAddr;
  wire g_io_out_s1_full_pred_3_fallThroughErr;
  wire i_io_out_s1_full_pred_3_fallThroughErr;
  wire g_io_out_s1_full_pred_3_is_jal;
  wire i_io_out_s1_full_pred_3_is_jal;
  wire g_io_out_s1_full_pred_3_is_jalr;
  wire i_io_out_s1_full_pred_3_is_jalr;
  wire g_io_out_s1_full_pred_3_is_call;
  wire i_io_out_s1_full_pred_3_is_call;
  wire g_io_out_s1_full_pred_3_is_ret;
  wire i_io_out_s1_full_pred_3_is_ret;
  wire g_io_out_s1_full_pred_3_last_may_be_rvi_call;
  wire i_io_out_s1_full_pred_3_last_may_be_rvi_call;
  wire g_io_out_s1_full_pred_3_is_br_sharing;
  wire i_io_out_s1_full_pred_3_is_br_sharing;
  wire g_io_out_s1_full_pred_3_hit;
  wire i_io_out_s1_full_pred_3_hit;
  wire [515:0] g_io_out_last_stage_meta;
  wire [515:0] i_io_out_last_stage_meta;
  wire g_io_fauftb_entry_out_isCall;
  wire i_io_fauftb_entry_out_isCall;
  wire g_io_fauftb_entry_out_isRet;
  wire i_io_fauftb_entry_out_isRet;
  wire g_io_fauftb_entry_out_isJalr;
  wire i_io_fauftb_entry_out_isJalr;
  wire g_io_fauftb_entry_out_valid;
  wire i_io_fauftb_entry_out_valid;
  wire [3:0] g_io_fauftb_entry_out_brSlots_0_offset;
  wire [3:0] i_io_fauftb_entry_out_brSlots_0_offset;
  wire g_io_fauftb_entry_out_brSlots_0_sharing;
  wire i_io_fauftb_entry_out_brSlots_0_sharing;
  wire g_io_fauftb_entry_out_brSlots_0_valid;
  wire i_io_fauftb_entry_out_brSlots_0_valid;
  wire [11:0] g_io_fauftb_entry_out_brSlots_0_lower;
  wire [11:0] i_io_fauftb_entry_out_brSlots_0_lower;
  wire [1:0] g_io_fauftb_entry_out_brSlots_0_tarStat;
  wire [1:0] i_io_fauftb_entry_out_brSlots_0_tarStat;
  wire [3:0] g_io_fauftb_entry_out_tailSlot_offset;
  wire [3:0] i_io_fauftb_entry_out_tailSlot_offset;
  wire g_io_fauftb_entry_out_tailSlot_sharing;
  wire i_io_fauftb_entry_out_tailSlot_sharing;
  wire g_io_fauftb_entry_out_tailSlot_valid;
  wire i_io_fauftb_entry_out_tailSlot_valid;
  wire [19:0] g_io_fauftb_entry_out_tailSlot_lower;
  wire [19:0] i_io_fauftb_entry_out_tailSlot_lower;
  wire [1:0] g_io_fauftb_entry_out_tailSlot_tarStat;
  wire [1:0] i_io_fauftb_entry_out_tailSlot_tarStat;
  wire [3:0] g_io_fauftb_entry_out_pftAddr;
  wire [3:0] i_io_fauftb_entry_out_pftAddr;
  wire g_io_fauftb_entry_out_carry;
  wire i_io_fauftb_entry_out_carry;
  wire g_io_fauftb_entry_out_last_may_be_rvi_call;
  wire i_io_fauftb_entry_out_last_may_be_rvi_call;
  wire g_io_fauftb_entry_out_strong_bias_0;
  wire i_io_fauftb_entry_out_strong_bias_0;
  wire g_io_fauftb_entry_out_strong_bias_1;
  wire i_io_fauftb_entry_out_strong_bias_1;
  wire g_io_fauftb_entry_hit_out;
  wire i_io_fauftb_entry_hit_out;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  FauFTB    u_g (.clock(clk), .reset(rst), .io_reset_vector(io_reset_vector), .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0), .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1), .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2), .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3), .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable), .io_s0_fire_0(io_s0_fire_0), .io_s0_fire_1(io_s0_fire_1), .io_s0_fire_2(io_s0_fire_2), .io_s0_fire_3(io_s0_fire_3), .io_s1_fire_0(io_s1_fire_0), .io_s1_fire_1(io_s1_fire_1), .io_s1_fire_2(io_s1_fire_2), .io_s1_fire_3(io_s1_fire_3), .io_s2_fire_0(io_s2_fire_0), .io_s2_fire_1(io_s2_fire_1), .io_s2_fire_2(io_s2_fire_2), .io_s2_fire_3(io_s2_fire_3), .io_update_valid(io_update_valid), .io_update_bits_pc(io_update_bits_pc), .io_update_bits_ftb_entry_isCall(io_update_bits_ftb_entry_isCall), .io_update_bits_ftb_entry_isRet(io_update_bits_ftb_entry_isRet), .io_update_bits_ftb_entry_isJalr(io_update_bits_ftb_entry_isJalr), .io_update_bits_ftb_entry_valid(io_update_bits_ftb_entry_valid), .io_update_bits_ftb_entry_brSlots_0_offset(io_update_bits_ftb_entry_brSlots_0_offset), .io_update_bits_ftb_entry_brSlots_0_sharing(io_update_bits_ftb_entry_brSlots_0_sharing), .io_update_bits_ftb_entry_brSlots_0_valid(io_update_bits_ftb_entry_brSlots_0_valid), .io_update_bits_ftb_entry_brSlots_0_lower(io_update_bits_ftb_entry_brSlots_0_lower), .io_update_bits_ftb_entry_brSlots_0_tarStat(io_update_bits_ftb_entry_brSlots_0_tarStat), .io_update_bits_ftb_entry_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset), .io_update_bits_ftb_entry_tailSlot_sharing(io_update_bits_ftb_entry_tailSlot_sharing), .io_update_bits_ftb_entry_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid), .io_update_bits_ftb_entry_tailSlot_lower(io_update_bits_ftb_entry_tailSlot_lower), .io_update_bits_ftb_entry_tailSlot_tarStat(io_update_bits_ftb_entry_tailSlot_tarStat), .io_update_bits_ftb_entry_pftAddr(io_update_bits_ftb_entry_pftAddr), .io_update_bits_ftb_entry_carry(io_update_bits_ftb_entry_carry), .io_update_bits_ftb_entry_last_may_be_rvi_call(io_update_bits_ftb_entry_last_may_be_rvi_call), .io_update_bits_ftb_entry_strong_bias_0(io_update_bits_ftb_entry_strong_bias_0), .io_update_bits_ftb_entry_strong_bias_1(io_update_bits_ftb_entry_strong_bias_1), .io_update_bits_br_taken_mask_0(io_update_bits_br_taken_mask_0), .io_update_bits_br_taken_mask_1(io_update_bits_br_taken_mask_1), .io_update_bits_meta(io_update_bits_meta), .io_out_s1_pc_0(g_io_out_s1_pc_0), .io_out_s1_pc_1(g_io_out_s1_pc_1), .io_out_s1_pc_2(g_io_out_s1_pc_2), .io_out_s1_pc_3(g_io_out_s1_pc_3), .io_out_s1_full_pred_0_br_taken_mask_0(g_io_out_s1_full_pred_0_br_taken_mask_0), .io_out_s1_full_pred_0_br_taken_mask_1(g_io_out_s1_full_pred_0_br_taken_mask_1), .io_out_s1_full_pred_0_slot_valids_0(g_io_out_s1_full_pred_0_slot_valids_0), .io_out_s1_full_pred_0_slot_valids_1(g_io_out_s1_full_pred_0_slot_valids_1), .io_out_s1_full_pred_0_targets_0(g_io_out_s1_full_pred_0_targets_0), .io_out_s1_full_pred_0_targets_1(g_io_out_s1_full_pred_0_targets_1), .io_out_s1_full_pred_0_jalr_target(g_io_out_s1_full_pred_0_jalr_target), .io_out_s1_full_pred_0_offsets_0(g_io_out_s1_full_pred_0_offsets_0), .io_out_s1_full_pred_0_offsets_1(g_io_out_s1_full_pred_0_offsets_1), .io_out_s1_full_pred_0_fallThroughAddr(g_io_out_s1_full_pred_0_fallThroughAddr), .io_out_s1_full_pred_0_fallThroughErr(g_io_out_s1_full_pred_0_fallThroughErr), .io_out_s1_full_pred_0_is_jal(g_io_out_s1_full_pred_0_is_jal), .io_out_s1_full_pred_0_is_jalr(g_io_out_s1_full_pred_0_is_jalr), .io_out_s1_full_pred_0_is_call(g_io_out_s1_full_pred_0_is_call), .io_out_s1_full_pred_0_is_ret(g_io_out_s1_full_pred_0_is_ret), .io_out_s1_full_pred_0_last_may_be_rvi_call(g_io_out_s1_full_pred_0_last_may_be_rvi_call), .io_out_s1_full_pred_0_is_br_sharing(g_io_out_s1_full_pred_0_is_br_sharing), .io_out_s1_full_pred_0_hit(g_io_out_s1_full_pred_0_hit), .io_out_s1_full_pred_1_br_taken_mask_0(g_io_out_s1_full_pred_1_br_taken_mask_0), .io_out_s1_full_pred_1_br_taken_mask_1(g_io_out_s1_full_pred_1_br_taken_mask_1), .io_out_s1_full_pred_1_slot_valids_0(g_io_out_s1_full_pred_1_slot_valids_0), .io_out_s1_full_pred_1_slot_valids_1(g_io_out_s1_full_pred_1_slot_valids_1), .io_out_s1_full_pred_1_targets_0(g_io_out_s1_full_pred_1_targets_0), .io_out_s1_full_pred_1_targets_1(g_io_out_s1_full_pred_1_targets_1), .io_out_s1_full_pred_1_jalr_target(g_io_out_s1_full_pred_1_jalr_target), .io_out_s1_full_pred_1_offsets_0(g_io_out_s1_full_pred_1_offsets_0), .io_out_s1_full_pred_1_offsets_1(g_io_out_s1_full_pred_1_offsets_1), .io_out_s1_full_pred_1_fallThroughAddr(g_io_out_s1_full_pred_1_fallThroughAddr), .io_out_s1_full_pred_1_fallThroughErr(g_io_out_s1_full_pred_1_fallThroughErr), .io_out_s1_full_pred_1_is_jal(g_io_out_s1_full_pred_1_is_jal), .io_out_s1_full_pred_1_is_jalr(g_io_out_s1_full_pred_1_is_jalr), .io_out_s1_full_pred_1_is_call(g_io_out_s1_full_pred_1_is_call), .io_out_s1_full_pred_1_is_ret(g_io_out_s1_full_pred_1_is_ret), .io_out_s1_full_pred_1_last_may_be_rvi_call(g_io_out_s1_full_pred_1_last_may_be_rvi_call), .io_out_s1_full_pred_1_is_br_sharing(g_io_out_s1_full_pred_1_is_br_sharing), .io_out_s1_full_pred_1_hit(g_io_out_s1_full_pred_1_hit), .io_out_s1_full_pred_2_br_taken_mask_0(g_io_out_s1_full_pred_2_br_taken_mask_0), .io_out_s1_full_pred_2_br_taken_mask_1(g_io_out_s1_full_pred_2_br_taken_mask_1), .io_out_s1_full_pred_2_slot_valids_0(g_io_out_s1_full_pred_2_slot_valids_0), .io_out_s1_full_pred_2_slot_valids_1(g_io_out_s1_full_pred_2_slot_valids_1), .io_out_s1_full_pred_2_targets_0(g_io_out_s1_full_pred_2_targets_0), .io_out_s1_full_pred_2_targets_1(g_io_out_s1_full_pred_2_targets_1), .io_out_s1_full_pred_2_jalr_target(g_io_out_s1_full_pred_2_jalr_target), .io_out_s1_full_pred_2_offsets_0(g_io_out_s1_full_pred_2_offsets_0), .io_out_s1_full_pred_2_offsets_1(g_io_out_s1_full_pred_2_offsets_1), .io_out_s1_full_pred_2_fallThroughAddr(g_io_out_s1_full_pred_2_fallThroughAddr), .io_out_s1_full_pred_2_fallThroughErr(g_io_out_s1_full_pred_2_fallThroughErr), .io_out_s1_full_pred_2_is_jal(g_io_out_s1_full_pred_2_is_jal), .io_out_s1_full_pred_2_is_jalr(g_io_out_s1_full_pred_2_is_jalr), .io_out_s1_full_pred_2_is_call(g_io_out_s1_full_pred_2_is_call), .io_out_s1_full_pred_2_is_ret(g_io_out_s1_full_pred_2_is_ret), .io_out_s1_full_pred_2_last_may_be_rvi_call(g_io_out_s1_full_pred_2_last_may_be_rvi_call), .io_out_s1_full_pred_2_is_br_sharing(g_io_out_s1_full_pred_2_is_br_sharing), .io_out_s1_full_pred_2_hit(g_io_out_s1_full_pred_2_hit), .io_out_s1_full_pred_3_br_taken_mask_0(g_io_out_s1_full_pred_3_br_taken_mask_0), .io_out_s1_full_pred_3_br_taken_mask_1(g_io_out_s1_full_pred_3_br_taken_mask_1), .io_out_s1_full_pred_3_slot_valids_0(g_io_out_s1_full_pred_3_slot_valids_0), .io_out_s1_full_pred_3_slot_valids_1(g_io_out_s1_full_pred_3_slot_valids_1), .io_out_s1_full_pred_3_targets_0(g_io_out_s1_full_pred_3_targets_0), .io_out_s1_full_pred_3_targets_1(g_io_out_s1_full_pred_3_targets_1), .io_out_s1_full_pred_3_jalr_target(g_io_out_s1_full_pred_3_jalr_target), .io_out_s1_full_pred_3_offsets_0(g_io_out_s1_full_pred_3_offsets_0), .io_out_s1_full_pred_3_offsets_1(g_io_out_s1_full_pred_3_offsets_1), .io_out_s1_full_pred_3_fallThroughAddr(g_io_out_s1_full_pred_3_fallThroughAddr), .io_out_s1_full_pred_3_fallThroughErr(g_io_out_s1_full_pred_3_fallThroughErr), .io_out_s1_full_pred_3_is_jal(g_io_out_s1_full_pred_3_is_jal), .io_out_s1_full_pred_3_is_jalr(g_io_out_s1_full_pred_3_is_jalr), .io_out_s1_full_pred_3_is_call(g_io_out_s1_full_pred_3_is_call), .io_out_s1_full_pred_3_is_ret(g_io_out_s1_full_pred_3_is_ret), .io_out_s1_full_pred_3_last_may_be_rvi_call(g_io_out_s1_full_pred_3_last_may_be_rvi_call), .io_out_s1_full_pred_3_is_br_sharing(g_io_out_s1_full_pred_3_is_br_sharing), .io_out_s1_full_pred_3_hit(g_io_out_s1_full_pred_3_hit), .io_out_last_stage_meta(g_io_out_last_stage_meta), .io_fauftb_entry_out_isCall(g_io_fauftb_entry_out_isCall), .io_fauftb_entry_out_isRet(g_io_fauftb_entry_out_isRet), .io_fauftb_entry_out_isJalr(g_io_fauftb_entry_out_isJalr), .io_fauftb_entry_out_valid(g_io_fauftb_entry_out_valid), .io_fauftb_entry_out_brSlots_0_offset(g_io_fauftb_entry_out_brSlots_0_offset), .io_fauftb_entry_out_brSlots_0_sharing(g_io_fauftb_entry_out_brSlots_0_sharing), .io_fauftb_entry_out_brSlots_0_valid(g_io_fauftb_entry_out_brSlots_0_valid), .io_fauftb_entry_out_brSlots_0_lower(g_io_fauftb_entry_out_brSlots_0_lower), .io_fauftb_entry_out_brSlots_0_tarStat(g_io_fauftb_entry_out_brSlots_0_tarStat), .io_fauftb_entry_out_tailSlot_offset(g_io_fauftb_entry_out_tailSlot_offset), .io_fauftb_entry_out_tailSlot_sharing(g_io_fauftb_entry_out_tailSlot_sharing), .io_fauftb_entry_out_tailSlot_valid(g_io_fauftb_entry_out_tailSlot_valid), .io_fauftb_entry_out_tailSlot_lower(g_io_fauftb_entry_out_tailSlot_lower), .io_fauftb_entry_out_tailSlot_tarStat(g_io_fauftb_entry_out_tailSlot_tarStat), .io_fauftb_entry_out_pftAddr(g_io_fauftb_entry_out_pftAddr), .io_fauftb_entry_out_carry(g_io_fauftb_entry_out_carry), .io_fauftb_entry_out_last_may_be_rvi_call(g_io_fauftb_entry_out_last_may_be_rvi_call), .io_fauftb_entry_out_strong_bias_0(g_io_fauftb_entry_out_strong_bias_0), .io_fauftb_entry_out_strong_bias_1(g_io_fauftb_entry_out_strong_bias_1), .io_fauftb_entry_hit_out(g_io_fauftb_entry_hit_out), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value));
  FauFTB_xs u_i (.clock(clk), .reset(rst), .io_reset_vector(io_reset_vector), .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0), .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1), .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2), .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3), .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable), .io_s0_fire_0(io_s0_fire_0), .io_s0_fire_1(io_s0_fire_1), .io_s0_fire_2(io_s0_fire_2), .io_s0_fire_3(io_s0_fire_3), .io_s1_fire_0(io_s1_fire_0), .io_s1_fire_1(io_s1_fire_1), .io_s1_fire_2(io_s1_fire_2), .io_s1_fire_3(io_s1_fire_3), .io_s2_fire_0(io_s2_fire_0), .io_s2_fire_1(io_s2_fire_1), .io_s2_fire_2(io_s2_fire_2), .io_s2_fire_3(io_s2_fire_3), .io_update_valid(io_update_valid), .io_update_bits_pc(io_update_bits_pc), .io_update_bits_ftb_entry_isCall(io_update_bits_ftb_entry_isCall), .io_update_bits_ftb_entry_isRet(io_update_bits_ftb_entry_isRet), .io_update_bits_ftb_entry_isJalr(io_update_bits_ftb_entry_isJalr), .io_update_bits_ftb_entry_valid(io_update_bits_ftb_entry_valid), .io_update_bits_ftb_entry_brSlots_0_offset(io_update_bits_ftb_entry_brSlots_0_offset), .io_update_bits_ftb_entry_brSlots_0_sharing(io_update_bits_ftb_entry_brSlots_0_sharing), .io_update_bits_ftb_entry_brSlots_0_valid(io_update_bits_ftb_entry_brSlots_0_valid), .io_update_bits_ftb_entry_brSlots_0_lower(io_update_bits_ftb_entry_brSlots_0_lower), .io_update_bits_ftb_entry_brSlots_0_tarStat(io_update_bits_ftb_entry_brSlots_0_tarStat), .io_update_bits_ftb_entry_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset), .io_update_bits_ftb_entry_tailSlot_sharing(io_update_bits_ftb_entry_tailSlot_sharing), .io_update_bits_ftb_entry_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid), .io_update_bits_ftb_entry_tailSlot_lower(io_update_bits_ftb_entry_tailSlot_lower), .io_update_bits_ftb_entry_tailSlot_tarStat(io_update_bits_ftb_entry_tailSlot_tarStat), .io_update_bits_ftb_entry_pftAddr(io_update_bits_ftb_entry_pftAddr), .io_update_bits_ftb_entry_carry(io_update_bits_ftb_entry_carry), .io_update_bits_ftb_entry_last_may_be_rvi_call(io_update_bits_ftb_entry_last_may_be_rvi_call), .io_update_bits_ftb_entry_strong_bias_0(io_update_bits_ftb_entry_strong_bias_0), .io_update_bits_ftb_entry_strong_bias_1(io_update_bits_ftb_entry_strong_bias_1), .io_update_bits_br_taken_mask_0(io_update_bits_br_taken_mask_0), .io_update_bits_br_taken_mask_1(io_update_bits_br_taken_mask_1), .io_update_bits_meta(io_update_bits_meta), .io_out_s1_pc_0(i_io_out_s1_pc_0), .io_out_s1_pc_1(i_io_out_s1_pc_1), .io_out_s1_pc_2(i_io_out_s1_pc_2), .io_out_s1_pc_3(i_io_out_s1_pc_3), .io_out_s1_full_pred_0_br_taken_mask_0(i_io_out_s1_full_pred_0_br_taken_mask_0), .io_out_s1_full_pred_0_br_taken_mask_1(i_io_out_s1_full_pred_0_br_taken_mask_1), .io_out_s1_full_pred_0_slot_valids_0(i_io_out_s1_full_pred_0_slot_valids_0), .io_out_s1_full_pred_0_slot_valids_1(i_io_out_s1_full_pred_0_slot_valids_1), .io_out_s1_full_pred_0_targets_0(i_io_out_s1_full_pred_0_targets_0), .io_out_s1_full_pred_0_targets_1(i_io_out_s1_full_pred_0_targets_1), .io_out_s1_full_pred_0_jalr_target(i_io_out_s1_full_pred_0_jalr_target), .io_out_s1_full_pred_0_offsets_0(i_io_out_s1_full_pred_0_offsets_0), .io_out_s1_full_pred_0_offsets_1(i_io_out_s1_full_pred_0_offsets_1), .io_out_s1_full_pred_0_fallThroughAddr(i_io_out_s1_full_pred_0_fallThroughAddr), .io_out_s1_full_pred_0_fallThroughErr(i_io_out_s1_full_pred_0_fallThroughErr), .io_out_s1_full_pred_0_is_jal(i_io_out_s1_full_pred_0_is_jal), .io_out_s1_full_pred_0_is_jalr(i_io_out_s1_full_pred_0_is_jalr), .io_out_s1_full_pred_0_is_call(i_io_out_s1_full_pred_0_is_call), .io_out_s1_full_pred_0_is_ret(i_io_out_s1_full_pred_0_is_ret), .io_out_s1_full_pred_0_last_may_be_rvi_call(i_io_out_s1_full_pred_0_last_may_be_rvi_call), .io_out_s1_full_pred_0_is_br_sharing(i_io_out_s1_full_pred_0_is_br_sharing), .io_out_s1_full_pred_0_hit(i_io_out_s1_full_pred_0_hit), .io_out_s1_full_pred_1_br_taken_mask_0(i_io_out_s1_full_pred_1_br_taken_mask_0), .io_out_s1_full_pred_1_br_taken_mask_1(i_io_out_s1_full_pred_1_br_taken_mask_1), .io_out_s1_full_pred_1_slot_valids_0(i_io_out_s1_full_pred_1_slot_valids_0), .io_out_s1_full_pred_1_slot_valids_1(i_io_out_s1_full_pred_1_slot_valids_1), .io_out_s1_full_pred_1_targets_0(i_io_out_s1_full_pred_1_targets_0), .io_out_s1_full_pred_1_targets_1(i_io_out_s1_full_pred_1_targets_1), .io_out_s1_full_pred_1_jalr_target(i_io_out_s1_full_pred_1_jalr_target), .io_out_s1_full_pred_1_offsets_0(i_io_out_s1_full_pred_1_offsets_0), .io_out_s1_full_pred_1_offsets_1(i_io_out_s1_full_pred_1_offsets_1), .io_out_s1_full_pred_1_fallThroughAddr(i_io_out_s1_full_pred_1_fallThroughAddr), .io_out_s1_full_pred_1_fallThroughErr(i_io_out_s1_full_pred_1_fallThroughErr), .io_out_s1_full_pred_1_is_jal(i_io_out_s1_full_pred_1_is_jal), .io_out_s1_full_pred_1_is_jalr(i_io_out_s1_full_pred_1_is_jalr), .io_out_s1_full_pred_1_is_call(i_io_out_s1_full_pred_1_is_call), .io_out_s1_full_pred_1_is_ret(i_io_out_s1_full_pred_1_is_ret), .io_out_s1_full_pred_1_last_may_be_rvi_call(i_io_out_s1_full_pred_1_last_may_be_rvi_call), .io_out_s1_full_pred_1_is_br_sharing(i_io_out_s1_full_pred_1_is_br_sharing), .io_out_s1_full_pred_1_hit(i_io_out_s1_full_pred_1_hit), .io_out_s1_full_pred_2_br_taken_mask_0(i_io_out_s1_full_pred_2_br_taken_mask_0), .io_out_s1_full_pred_2_br_taken_mask_1(i_io_out_s1_full_pred_2_br_taken_mask_1), .io_out_s1_full_pred_2_slot_valids_0(i_io_out_s1_full_pred_2_slot_valids_0), .io_out_s1_full_pred_2_slot_valids_1(i_io_out_s1_full_pred_2_slot_valids_1), .io_out_s1_full_pred_2_targets_0(i_io_out_s1_full_pred_2_targets_0), .io_out_s1_full_pred_2_targets_1(i_io_out_s1_full_pred_2_targets_1), .io_out_s1_full_pred_2_jalr_target(i_io_out_s1_full_pred_2_jalr_target), .io_out_s1_full_pred_2_offsets_0(i_io_out_s1_full_pred_2_offsets_0), .io_out_s1_full_pred_2_offsets_1(i_io_out_s1_full_pred_2_offsets_1), .io_out_s1_full_pred_2_fallThroughAddr(i_io_out_s1_full_pred_2_fallThroughAddr), .io_out_s1_full_pred_2_fallThroughErr(i_io_out_s1_full_pred_2_fallThroughErr), .io_out_s1_full_pred_2_is_jal(i_io_out_s1_full_pred_2_is_jal), .io_out_s1_full_pred_2_is_jalr(i_io_out_s1_full_pred_2_is_jalr), .io_out_s1_full_pred_2_is_call(i_io_out_s1_full_pred_2_is_call), .io_out_s1_full_pred_2_is_ret(i_io_out_s1_full_pred_2_is_ret), .io_out_s1_full_pred_2_last_may_be_rvi_call(i_io_out_s1_full_pred_2_last_may_be_rvi_call), .io_out_s1_full_pred_2_is_br_sharing(i_io_out_s1_full_pred_2_is_br_sharing), .io_out_s1_full_pred_2_hit(i_io_out_s1_full_pred_2_hit), .io_out_s1_full_pred_3_br_taken_mask_0(i_io_out_s1_full_pred_3_br_taken_mask_0), .io_out_s1_full_pred_3_br_taken_mask_1(i_io_out_s1_full_pred_3_br_taken_mask_1), .io_out_s1_full_pred_3_slot_valids_0(i_io_out_s1_full_pred_3_slot_valids_0), .io_out_s1_full_pred_3_slot_valids_1(i_io_out_s1_full_pred_3_slot_valids_1), .io_out_s1_full_pred_3_targets_0(i_io_out_s1_full_pred_3_targets_0), .io_out_s1_full_pred_3_targets_1(i_io_out_s1_full_pred_3_targets_1), .io_out_s1_full_pred_3_jalr_target(i_io_out_s1_full_pred_3_jalr_target), .io_out_s1_full_pred_3_offsets_0(i_io_out_s1_full_pred_3_offsets_0), .io_out_s1_full_pred_3_offsets_1(i_io_out_s1_full_pred_3_offsets_1), .io_out_s1_full_pred_3_fallThroughAddr(i_io_out_s1_full_pred_3_fallThroughAddr), .io_out_s1_full_pred_3_fallThroughErr(i_io_out_s1_full_pred_3_fallThroughErr), .io_out_s1_full_pred_3_is_jal(i_io_out_s1_full_pred_3_is_jal), .io_out_s1_full_pred_3_is_jalr(i_io_out_s1_full_pred_3_is_jalr), .io_out_s1_full_pred_3_is_call(i_io_out_s1_full_pred_3_is_call), .io_out_s1_full_pred_3_is_ret(i_io_out_s1_full_pred_3_is_ret), .io_out_s1_full_pred_3_last_may_be_rvi_call(i_io_out_s1_full_pred_3_last_may_be_rvi_call), .io_out_s1_full_pred_3_is_br_sharing(i_io_out_s1_full_pred_3_is_br_sharing), .io_out_s1_full_pred_3_hit(i_io_out_s1_full_pred_3_hit), .io_out_last_stage_meta(i_io_out_last_stage_meta), .io_fauftb_entry_out_isCall(i_io_fauftb_entry_out_isCall), .io_fauftb_entry_out_isRet(i_io_fauftb_entry_out_isRet), .io_fauftb_entry_out_isJalr(i_io_fauftb_entry_out_isJalr), .io_fauftb_entry_out_valid(i_io_fauftb_entry_out_valid), .io_fauftb_entry_out_brSlots_0_offset(i_io_fauftb_entry_out_brSlots_0_offset), .io_fauftb_entry_out_brSlots_0_sharing(i_io_fauftb_entry_out_brSlots_0_sharing), .io_fauftb_entry_out_brSlots_0_valid(i_io_fauftb_entry_out_brSlots_0_valid), .io_fauftb_entry_out_brSlots_0_lower(i_io_fauftb_entry_out_brSlots_0_lower), .io_fauftb_entry_out_brSlots_0_tarStat(i_io_fauftb_entry_out_brSlots_0_tarStat), .io_fauftb_entry_out_tailSlot_offset(i_io_fauftb_entry_out_tailSlot_offset), .io_fauftb_entry_out_tailSlot_sharing(i_io_fauftb_entry_out_tailSlot_sharing), .io_fauftb_entry_out_tailSlot_valid(i_io_fauftb_entry_out_tailSlot_valid), .io_fauftb_entry_out_tailSlot_lower(i_io_fauftb_entry_out_tailSlot_lower), .io_fauftb_entry_out_tailSlot_tarStat(i_io_fauftb_entry_out_tailSlot_tarStat), .io_fauftb_entry_out_pftAddr(i_io_fauftb_entry_out_pftAddr), .io_fauftb_entry_out_carry(i_io_fauftb_entry_out_carry), .io_fauftb_entry_out_last_may_be_rvi_call(i_io_fauftb_entry_out_last_may_be_rvi_call), .io_fauftb_entry_out_strong_bias_0(i_io_fauftb_entry_out_strong_bias_0), .io_fauftb_entry_out_strong_bias_1(i_io_fauftb_entry_out_strong_bias_1), .io_fauftb_entry_hit_out(i_io_fauftb_entry_hit_out), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value));
  always @(negedge clk) begin
    if (rst) begin
      io_update_valid <= 1'b0;
      io_s0_fire_0 <= 1'b0; io_s0_fire_1 <= 1'b0;
      io_s0_fire_2 <= 1'b0; io_s0_fire_3 <= 1'b0;
      io_s1_fire_0 <= 1'b0; io_s1_fire_1 <= 1'b0;
      io_s1_fire_2 <= 1'b0; io_s1_fire_3 <= 1'b0;
      io_s2_fire_0 <= 1'b0; io_s2_fire_1 <= 1'b0;
      io_s2_fire_2 <= 1'b0; io_s2_fire_3 <= 1'b0;
    end else begin
      io_reset_vector <= 48'({$urandom(), $urandom()});
      io_in_bits_s0_pc_0 <= {33'($urandom), 16'($urandom_range(0,31)), 1'b0};
      io_in_bits_s0_pc_1 <= {33'($urandom), 16'($urandom_range(0,31)), 1'b0};
      io_in_bits_s0_pc_2 <= {33'($urandom), 16'($urandom_range(0,31)), 1'b0};
      io_in_bits_s0_pc_3 <= {33'($urandom), 16'($urandom_range(0,31)), 1'b0};
      io_ctrl_ubtb_enable <= ($urandom_range(0,1)==0);
      io_s0_fire_0 <= ($urandom_range(0,1)==0);
      io_s0_fire_1 <= ($urandom_range(0,1)==0);
      io_s0_fire_2 <= ($urandom_range(0,1)==0);
      io_s0_fire_3 <= ($urandom_range(0,1)==0);
      io_s1_fire_0 <= ($urandom_range(0,1)==0);
      io_s1_fire_1 <= ($urandom_range(0,1)==0);
      io_s1_fire_2 <= ($urandom_range(0,1)==0);
      io_s1_fire_3 <= ($urandom_range(0,1)==0);
      io_s2_fire_0 <= ($urandom_range(0,1)==0);
      io_s2_fire_1 <= ($urandom_range(0,1)==0);
      io_s2_fire_2 <= ($urandom_range(0,1)==0);
      io_s2_fire_3 <= ($urandom_range(0,1)==0);
      io_update_valid <= ($urandom_range(0,1)==0);
      io_update_bits_pc <= {33'($urandom), 16'($urandom_range(0,31)), 1'b0};
      io_update_bits_ftb_entry_isCall <= 1'($urandom);
      io_update_bits_ftb_entry_isRet <= 1'($urandom);
      io_update_bits_ftb_entry_isJalr <= 1'($urandom);
      io_update_bits_ftb_entry_valid <= 1'($urandom);
      io_update_bits_ftb_entry_brSlots_0_offset <= 4'($urandom);
      io_update_bits_ftb_entry_brSlots_0_sharing <= 1'($urandom);
      io_update_bits_ftb_entry_brSlots_0_valid <= 1'($urandom);
      io_update_bits_ftb_entry_brSlots_0_lower <= 12'($urandom);
      io_update_bits_ftb_entry_brSlots_0_tarStat <= 2'($urandom);
      io_update_bits_ftb_entry_tailSlot_offset <= 4'($urandom);
      io_update_bits_ftb_entry_tailSlot_sharing <= 1'($urandom);
      io_update_bits_ftb_entry_tailSlot_valid <= 1'($urandom);
      io_update_bits_ftb_entry_tailSlot_lower <= 20'($urandom);
      io_update_bits_ftb_entry_tailSlot_tarStat <= 2'($urandom);
      io_update_bits_ftb_entry_pftAddr <= 4'($urandom);
      io_update_bits_ftb_entry_carry <= 1'($urandom);
      io_update_bits_ftb_entry_last_may_be_rvi_call <= 1'($urandom);
      io_update_bits_ftb_entry_strong_bias_0 <= 1'($urandom);
      io_update_bits_ftb_entry_strong_bias_1 <= 1'($urandom);
      io_update_bits_br_taken_mask_0 <= 1'($urandom);
      io_update_bits_br_taken_mask_1 <= 1'($urandom);
      io_update_bits_meta <= 516'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_out_s1_pc_0 !== i_io_out_s1_pc_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_pc_0 g=%h i=%h", $time, g_io_out_s1_pc_0, i_io_out_s1_pc_0); end
    if (g_io_out_s1_pc_1 !== i_io_out_s1_pc_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_pc_1 g=%h i=%h", $time, g_io_out_s1_pc_1, i_io_out_s1_pc_1); end
    if (g_io_out_s1_pc_2 !== i_io_out_s1_pc_2) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_pc_2 g=%h i=%h", $time, g_io_out_s1_pc_2, i_io_out_s1_pc_2); end
    if (g_io_out_s1_pc_3 !== i_io_out_s1_pc_3) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_pc_3 g=%h i=%h", $time, g_io_out_s1_pc_3, i_io_out_s1_pc_3); end
    if (g_io_out_s1_full_pred_0_br_taken_mask_0 !== i_io_out_s1_full_pred_0_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s1_full_pred_0_br_taken_mask_0, i_io_out_s1_full_pred_0_br_taken_mask_0); end
    if (g_io_out_s1_full_pred_0_br_taken_mask_1 !== i_io_out_s1_full_pred_0_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s1_full_pred_0_br_taken_mask_1, i_io_out_s1_full_pred_0_br_taken_mask_1); end
    if (g_io_out_s1_full_pred_0_slot_valids_0 !== i_io_out_s1_full_pred_0_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_slot_valids_0 g=%h i=%h", $time, g_io_out_s1_full_pred_0_slot_valids_0, i_io_out_s1_full_pred_0_slot_valids_0); end
    if (g_io_out_s1_full_pred_0_slot_valids_1 !== i_io_out_s1_full_pred_0_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_slot_valids_1 g=%h i=%h", $time, g_io_out_s1_full_pred_0_slot_valids_1, i_io_out_s1_full_pred_0_slot_valids_1); end
    if (g_io_out_s1_full_pred_0_targets_0 !== i_io_out_s1_full_pred_0_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_targets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_0_targets_0, i_io_out_s1_full_pred_0_targets_0); end
    if (g_io_out_s1_full_pred_0_targets_1 !== i_io_out_s1_full_pred_0_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_targets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_0_targets_1, i_io_out_s1_full_pred_0_targets_1); end
    if (g_io_out_s1_full_pred_0_jalr_target !== i_io_out_s1_full_pred_0_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_jalr_target g=%h i=%h", $time, g_io_out_s1_full_pred_0_jalr_target, i_io_out_s1_full_pred_0_jalr_target); end
    if (g_io_out_s1_full_pred_0_offsets_0 !== i_io_out_s1_full_pred_0_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_offsets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_0_offsets_0, i_io_out_s1_full_pred_0_offsets_0); end
    if (g_io_out_s1_full_pred_0_offsets_1 !== i_io_out_s1_full_pred_0_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_offsets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_0_offsets_1, i_io_out_s1_full_pred_0_offsets_1); end
    if (g_io_out_s1_full_pred_0_fallThroughAddr !== i_io_out_s1_full_pred_0_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_fallThroughAddr g=%h i=%h", $time, g_io_out_s1_full_pred_0_fallThroughAddr, i_io_out_s1_full_pred_0_fallThroughAddr); end
    if (g_io_out_s1_full_pred_0_fallThroughErr !== i_io_out_s1_full_pred_0_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_fallThroughErr g=%h i=%h", $time, g_io_out_s1_full_pred_0_fallThroughErr, i_io_out_s1_full_pred_0_fallThroughErr); end
    if (g_io_out_s1_full_pred_0_is_jal !== i_io_out_s1_full_pred_0_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_is_jal g=%h i=%h", $time, g_io_out_s1_full_pred_0_is_jal, i_io_out_s1_full_pred_0_is_jal); end
    if (g_io_out_s1_full_pred_0_is_jalr !== i_io_out_s1_full_pred_0_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_is_jalr g=%h i=%h", $time, g_io_out_s1_full_pred_0_is_jalr, i_io_out_s1_full_pred_0_is_jalr); end
    if (g_io_out_s1_full_pred_0_is_call !== i_io_out_s1_full_pred_0_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_is_call g=%h i=%h", $time, g_io_out_s1_full_pred_0_is_call, i_io_out_s1_full_pred_0_is_call); end
    if (g_io_out_s1_full_pred_0_is_ret !== i_io_out_s1_full_pred_0_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_is_ret g=%h i=%h", $time, g_io_out_s1_full_pred_0_is_ret, i_io_out_s1_full_pred_0_is_ret); end
    if (g_io_out_s1_full_pred_0_last_may_be_rvi_call !== i_io_out_s1_full_pred_0_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s1_full_pred_0_last_may_be_rvi_call, i_io_out_s1_full_pred_0_last_may_be_rvi_call); end
    if (g_io_out_s1_full_pred_0_is_br_sharing !== i_io_out_s1_full_pred_0_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_is_br_sharing g=%h i=%h", $time, g_io_out_s1_full_pred_0_is_br_sharing, i_io_out_s1_full_pred_0_is_br_sharing); end
    if (g_io_out_s1_full_pred_0_hit !== i_io_out_s1_full_pred_0_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_0_hit g=%h i=%h", $time, g_io_out_s1_full_pred_0_hit, i_io_out_s1_full_pred_0_hit); end
    if (g_io_out_s1_full_pred_1_br_taken_mask_0 !== i_io_out_s1_full_pred_1_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s1_full_pred_1_br_taken_mask_0, i_io_out_s1_full_pred_1_br_taken_mask_0); end
    if (g_io_out_s1_full_pred_1_br_taken_mask_1 !== i_io_out_s1_full_pred_1_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s1_full_pred_1_br_taken_mask_1, i_io_out_s1_full_pred_1_br_taken_mask_1); end
    if (g_io_out_s1_full_pred_1_slot_valids_0 !== i_io_out_s1_full_pred_1_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_slot_valids_0 g=%h i=%h", $time, g_io_out_s1_full_pred_1_slot_valids_0, i_io_out_s1_full_pred_1_slot_valids_0); end
    if (g_io_out_s1_full_pred_1_slot_valids_1 !== i_io_out_s1_full_pred_1_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_slot_valids_1 g=%h i=%h", $time, g_io_out_s1_full_pred_1_slot_valids_1, i_io_out_s1_full_pred_1_slot_valids_1); end
    if (g_io_out_s1_full_pred_1_targets_0 !== i_io_out_s1_full_pred_1_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_targets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_1_targets_0, i_io_out_s1_full_pred_1_targets_0); end
    if (g_io_out_s1_full_pred_1_targets_1 !== i_io_out_s1_full_pred_1_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_targets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_1_targets_1, i_io_out_s1_full_pred_1_targets_1); end
    if (g_io_out_s1_full_pred_1_jalr_target !== i_io_out_s1_full_pred_1_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_jalr_target g=%h i=%h", $time, g_io_out_s1_full_pred_1_jalr_target, i_io_out_s1_full_pred_1_jalr_target); end
    if (g_io_out_s1_full_pred_1_offsets_0 !== i_io_out_s1_full_pred_1_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_offsets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_1_offsets_0, i_io_out_s1_full_pred_1_offsets_0); end
    if (g_io_out_s1_full_pred_1_offsets_1 !== i_io_out_s1_full_pred_1_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_offsets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_1_offsets_1, i_io_out_s1_full_pred_1_offsets_1); end
    if (g_io_out_s1_full_pred_1_fallThroughAddr !== i_io_out_s1_full_pred_1_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_fallThroughAddr g=%h i=%h", $time, g_io_out_s1_full_pred_1_fallThroughAddr, i_io_out_s1_full_pred_1_fallThroughAddr); end
    if (g_io_out_s1_full_pred_1_fallThroughErr !== i_io_out_s1_full_pred_1_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_fallThroughErr g=%h i=%h", $time, g_io_out_s1_full_pred_1_fallThroughErr, i_io_out_s1_full_pred_1_fallThroughErr); end
    if (g_io_out_s1_full_pred_1_is_jal !== i_io_out_s1_full_pred_1_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_is_jal g=%h i=%h", $time, g_io_out_s1_full_pred_1_is_jal, i_io_out_s1_full_pred_1_is_jal); end
    if (g_io_out_s1_full_pred_1_is_jalr !== i_io_out_s1_full_pred_1_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_is_jalr g=%h i=%h", $time, g_io_out_s1_full_pred_1_is_jalr, i_io_out_s1_full_pred_1_is_jalr); end
    if (g_io_out_s1_full_pred_1_is_call !== i_io_out_s1_full_pred_1_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_is_call g=%h i=%h", $time, g_io_out_s1_full_pred_1_is_call, i_io_out_s1_full_pred_1_is_call); end
    if (g_io_out_s1_full_pred_1_is_ret !== i_io_out_s1_full_pred_1_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_is_ret g=%h i=%h", $time, g_io_out_s1_full_pred_1_is_ret, i_io_out_s1_full_pred_1_is_ret); end
    if (g_io_out_s1_full_pred_1_last_may_be_rvi_call !== i_io_out_s1_full_pred_1_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s1_full_pred_1_last_may_be_rvi_call, i_io_out_s1_full_pred_1_last_may_be_rvi_call); end
    if (g_io_out_s1_full_pred_1_is_br_sharing !== i_io_out_s1_full_pred_1_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_is_br_sharing g=%h i=%h", $time, g_io_out_s1_full_pred_1_is_br_sharing, i_io_out_s1_full_pred_1_is_br_sharing); end
    if (g_io_out_s1_full_pred_1_hit !== i_io_out_s1_full_pred_1_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_1_hit g=%h i=%h", $time, g_io_out_s1_full_pred_1_hit, i_io_out_s1_full_pred_1_hit); end
    if (g_io_out_s1_full_pred_2_br_taken_mask_0 !== i_io_out_s1_full_pred_2_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s1_full_pred_2_br_taken_mask_0, i_io_out_s1_full_pred_2_br_taken_mask_0); end
    if (g_io_out_s1_full_pred_2_br_taken_mask_1 !== i_io_out_s1_full_pred_2_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s1_full_pred_2_br_taken_mask_1, i_io_out_s1_full_pred_2_br_taken_mask_1); end
    if (g_io_out_s1_full_pred_2_slot_valids_0 !== i_io_out_s1_full_pred_2_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_slot_valids_0 g=%h i=%h", $time, g_io_out_s1_full_pred_2_slot_valids_0, i_io_out_s1_full_pred_2_slot_valids_0); end
    if (g_io_out_s1_full_pred_2_slot_valids_1 !== i_io_out_s1_full_pred_2_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_slot_valids_1 g=%h i=%h", $time, g_io_out_s1_full_pred_2_slot_valids_1, i_io_out_s1_full_pred_2_slot_valids_1); end
    if (g_io_out_s1_full_pred_2_targets_0 !== i_io_out_s1_full_pred_2_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_targets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_2_targets_0, i_io_out_s1_full_pred_2_targets_0); end
    if (g_io_out_s1_full_pred_2_targets_1 !== i_io_out_s1_full_pred_2_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_targets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_2_targets_1, i_io_out_s1_full_pred_2_targets_1); end
    if (g_io_out_s1_full_pred_2_jalr_target !== i_io_out_s1_full_pred_2_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_jalr_target g=%h i=%h", $time, g_io_out_s1_full_pred_2_jalr_target, i_io_out_s1_full_pred_2_jalr_target); end
    if (g_io_out_s1_full_pred_2_offsets_0 !== i_io_out_s1_full_pred_2_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_offsets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_2_offsets_0, i_io_out_s1_full_pred_2_offsets_0); end
    if (g_io_out_s1_full_pred_2_offsets_1 !== i_io_out_s1_full_pred_2_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_offsets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_2_offsets_1, i_io_out_s1_full_pred_2_offsets_1); end
    if (g_io_out_s1_full_pred_2_fallThroughAddr !== i_io_out_s1_full_pred_2_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_fallThroughAddr g=%h i=%h", $time, g_io_out_s1_full_pred_2_fallThroughAddr, i_io_out_s1_full_pred_2_fallThroughAddr); end
    if (g_io_out_s1_full_pred_2_fallThroughErr !== i_io_out_s1_full_pred_2_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_fallThroughErr g=%h i=%h", $time, g_io_out_s1_full_pred_2_fallThroughErr, i_io_out_s1_full_pred_2_fallThroughErr); end
    if (g_io_out_s1_full_pred_2_is_jal !== i_io_out_s1_full_pred_2_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_is_jal g=%h i=%h", $time, g_io_out_s1_full_pred_2_is_jal, i_io_out_s1_full_pred_2_is_jal); end
    if (g_io_out_s1_full_pred_2_is_jalr !== i_io_out_s1_full_pred_2_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_is_jalr g=%h i=%h", $time, g_io_out_s1_full_pred_2_is_jalr, i_io_out_s1_full_pred_2_is_jalr); end
    if (g_io_out_s1_full_pred_2_is_call !== i_io_out_s1_full_pred_2_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_is_call g=%h i=%h", $time, g_io_out_s1_full_pred_2_is_call, i_io_out_s1_full_pred_2_is_call); end
    if (g_io_out_s1_full_pred_2_is_ret !== i_io_out_s1_full_pred_2_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_is_ret g=%h i=%h", $time, g_io_out_s1_full_pred_2_is_ret, i_io_out_s1_full_pred_2_is_ret); end
    if (g_io_out_s1_full_pred_2_last_may_be_rvi_call !== i_io_out_s1_full_pred_2_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s1_full_pred_2_last_may_be_rvi_call, i_io_out_s1_full_pred_2_last_may_be_rvi_call); end
    if (g_io_out_s1_full_pred_2_is_br_sharing !== i_io_out_s1_full_pred_2_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_is_br_sharing g=%h i=%h", $time, g_io_out_s1_full_pred_2_is_br_sharing, i_io_out_s1_full_pred_2_is_br_sharing); end
    if (g_io_out_s1_full_pred_2_hit !== i_io_out_s1_full_pred_2_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_2_hit g=%h i=%h", $time, g_io_out_s1_full_pred_2_hit, i_io_out_s1_full_pred_2_hit); end
    if (g_io_out_s1_full_pred_3_br_taken_mask_0 !== i_io_out_s1_full_pred_3_br_taken_mask_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_out_s1_full_pred_3_br_taken_mask_0, i_io_out_s1_full_pred_3_br_taken_mask_0); end
    if (g_io_out_s1_full_pred_3_br_taken_mask_1 !== i_io_out_s1_full_pred_3_br_taken_mask_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_out_s1_full_pred_3_br_taken_mask_1, i_io_out_s1_full_pred_3_br_taken_mask_1); end
    if (g_io_out_s1_full_pred_3_slot_valids_0 !== i_io_out_s1_full_pred_3_slot_valids_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_out_s1_full_pred_3_slot_valids_0, i_io_out_s1_full_pred_3_slot_valids_0); end
    if (g_io_out_s1_full_pred_3_slot_valids_1 !== i_io_out_s1_full_pred_3_slot_valids_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_out_s1_full_pred_3_slot_valids_1, i_io_out_s1_full_pred_3_slot_valids_1); end
    if (g_io_out_s1_full_pred_3_targets_0 !== i_io_out_s1_full_pred_3_targets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_targets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_3_targets_0, i_io_out_s1_full_pred_3_targets_0); end
    if (g_io_out_s1_full_pred_3_targets_1 !== i_io_out_s1_full_pred_3_targets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_targets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_3_targets_1, i_io_out_s1_full_pred_3_targets_1); end
    if (g_io_out_s1_full_pred_3_jalr_target !== i_io_out_s1_full_pred_3_jalr_target) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_jalr_target g=%h i=%h", $time, g_io_out_s1_full_pred_3_jalr_target, i_io_out_s1_full_pred_3_jalr_target); end
    if (g_io_out_s1_full_pred_3_offsets_0 !== i_io_out_s1_full_pred_3_offsets_0) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_out_s1_full_pred_3_offsets_0, i_io_out_s1_full_pred_3_offsets_0); end
    if (g_io_out_s1_full_pred_3_offsets_1 !== i_io_out_s1_full_pred_3_offsets_1) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_out_s1_full_pred_3_offsets_1, i_io_out_s1_full_pred_3_offsets_1); end
    if (g_io_out_s1_full_pred_3_fallThroughAddr !== i_io_out_s1_full_pred_3_fallThroughAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_out_s1_full_pred_3_fallThroughAddr, i_io_out_s1_full_pred_3_fallThroughAddr); end
    if (g_io_out_s1_full_pred_3_fallThroughErr !== i_io_out_s1_full_pred_3_fallThroughErr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_out_s1_full_pred_3_fallThroughErr, i_io_out_s1_full_pred_3_fallThroughErr); end
    if (g_io_out_s1_full_pred_3_is_jal !== i_io_out_s1_full_pred_3_is_jal) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_is_jal g=%h i=%h", $time, g_io_out_s1_full_pred_3_is_jal, i_io_out_s1_full_pred_3_is_jal); end
    if (g_io_out_s1_full_pred_3_is_jalr !== i_io_out_s1_full_pred_3_is_jalr) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_is_jalr g=%h i=%h", $time, g_io_out_s1_full_pred_3_is_jalr, i_io_out_s1_full_pred_3_is_jalr); end
    if (g_io_out_s1_full_pred_3_is_call !== i_io_out_s1_full_pred_3_is_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_is_call g=%h i=%h", $time, g_io_out_s1_full_pred_3_is_call, i_io_out_s1_full_pred_3_is_call); end
    if (g_io_out_s1_full_pred_3_is_ret !== i_io_out_s1_full_pred_3_is_ret) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_is_ret g=%h i=%h", $time, g_io_out_s1_full_pred_3_is_ret, i_io_out_s1_full_pred_3_is_ret); end
    if (g_io_out_s1_full_pred_3_last_may_be_rvi_call !== i_io_out_s1_full_pred_3_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_last_may_be_rvi_call g=%h i=%h", $time, g_io_out_s1_full_pred_3_last_may_be_rvi_call, i_io_out_s1_full_pred_3_last_may_be_rvi_call); end
    if (g_io_out_s1_full_pred_3_is_br_sharing !== i_io_out_s1_full_pred_3_is_br_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_out_s1_full_pred_3_is_br_sharing, i_io_out_s1_full_pred_3_is_br_sharing); end
    if (g_io_out_s1_full_pred_3_hit !== i_io_out_s1_full_pred_3_hit) begin errors++;
      if(errors<=30) $display("[%0t] io_out_s1_full_pred_3_hit g=%h i=%h", $time, g_io_out_s1_full_pred_3_hit, i_io_out_s1_full_pred_3_hit); end
    if (g_io_out_last_stage_meta !== i_io_out_last_stage_meta) begin errors++;
      if(errors<=30) $display("[%0t] io_out_last_stage_meta g=%h i=%h", $time, g_io_out_last_stage_meta, i_io_out_last_stage_meta); end
    if (g_io_fauftb_entry_out_isCall !== i_io_fauftb_entry_out_isCall) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_isCall g=%h i=%h", $time, g_io_fauftb_entry_out_isCall, i_io_fauftb_entry_out_isCall); end
    if (g_io_fauftb_entry_out_isRet !== i_io_fauftb_entry_out_isRet) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_isRet g=%h i=%h", $time, g_io_fauftb_entry_out_isRet, i_io_fauftb_entry_out_isRet); end
    if (g_io_fauftb_entry_out_isJalr !== i_io_fauftb_entry_out_isJalr) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_isJalr g=%h i=%h", $time, g_io_fauftb_entry_out_isJalr, i_io_fauftb_entry_out_isJalr); end
    if (g_io_fauftb_entry_out_valid !== i_io_fauftb_entry_out_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_valid g=%h i=%h", $time, g_io_fauftb_entry_out_valid, i_io_fauftb_entry_out_valid); end
    if (g_io_fauftb_entry_out_brSlots_0_offset !== i_io_fauftb_entry_out_brSlots_0_offset) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_brSlots_0_offset g=%h i=%h", $time, g_io_fauftb_entry_out_brSlots_0_offset, i_io_fauftb_entry_out_brSlots_0_offset); end
    if (g_io_fauftb_entry_out_brSlots_0_sharing !== i_io_fauftb_entry_out_brSlots_0_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_brSlots_0_sharing g=%h i=%h", $time, g_io_fauftb_entry_out_brSlots_0_sharing, i_io_fauftb_entry_out_brSlots_0_sharing); end
    if (g_io_fauftb_entry_out_brSlots_0_valid !== i_io_fauftb_entry_out_brSlots_0_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_brSlots_0_valid g=%h i=%h", $time, g_io_fauftb_entry_out_brSlots_0_valid, i_io_fauftb_entry_out_brSlots_0_valid); end
    if (g_io_fauftb_entry_out_brSlots_0_lower !== i_io_fauftb_entry_out_brSlots_0_lower) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_brSlots_0_lower g=%h i=%h", $time, g_io_fauftb_entry_out_brSlots_0_lower, i_io_fauftb_entry_out_brSlots_0_lower); end
    if (g_io_fauftb_entry_out_brSlots_0_tarStat !== i_io_fauftb_entry_out_brSlots_0_tarStat) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_brSlots_0_tarStat g=%h i=%h", $time, g_io_fauftb_entry_out_brSlots_0_tarStat, i_io_fauftb_entry_out_brSlots_0_tarStat); end
    if (g_io_fauftb_entry_out_tailSlot_offset !== i_io_fauftb_entry_out_tailSlot_offset) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_tailSlot_offset g=%h i=%h", $time, g_io_fauftb_entry_out_tailSlot_offset, i_io_fauftb_entry_out_tailSlot_offset); end
    if (g_io_fauftb_entry_out_tailSlot_sharing !== i_io_fauftb_entry_out_tailSlot_sharing) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_tailSlot_sharing g=%h i=%h", $time, g_io_fauftb_entry_out_tailSlot_sharing, i_io_fauftb_entry_out_tailSlot_sharing); end
    if (g_io_fauftb_entry_out_tailSlot_valid !== i_io_fauftb_entry_out_tailSlot_valid) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_tailSlot_valid g=%h i=%h", $time, g_io_fauftb_entry_out_tailSlot_valid, i_io_fauftb_entry_out_tailSlot_valid); end
    if (g_io_fauftb_entry_out_tailSlot_lower !== i_io_fauftb_entry_out_tailSlot_lower) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_tailSlot_lower g=%h i=%h", $time, g_io_fauftb_entry_out_tailSlot_lower, i_io_fauftb_entry_out_tailSlot_lower); end
    if (g_io_fauftb_entry_out_tailSlot_tarStat !== i_io_fauftb_entry_out_tailSlot_tarStat) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_tailSlot_tarStat g=%h i=%h", $time, g_io_fauftb_entry_out_tailSlot_tarStat, i_io_fauftb_entry_out_tailSlot_tarStat); end
    if (g_io_fauftb_entry_out_pftAddr !== i_io_fauftb_entry_out_pftAddr) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_pftAddr g=%h i=%h", $time, g_io_fauftb_entry_out_pftAddr, i_io_fauftb_entry_out_pftAddr); end
    if (g_io_fauftb_entry_out_carry !== i_io_fauftb_entry_out_carry) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_carry g=%h i=%h", $time, g_io_fauftb_entry_out_carry, i_io_fauftb_entry_out_carry); end
    if (g_io_fauftb_entry_out_last_may_be_rvi_call !== i_io_fauftb_entry_out_last_may_be_rvi_call) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_last_may_be_rvi_call g=%h i=%h", $time, g_io_fauftb_entry_out_last_may_be_rvi_call, i_io_fauftb_entry_out_last_may_be_rvi_call); end
    if (g_io_fauftb_entry_out_strong_bias_0 !== i_io_fauftb_entry_out_strong_bias_0) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_strong_bias_0 g=%h i=%h", $time, g_io_fauftb_entry_out_strong_bias_0, i_io_fauftb_entry_out_strong_bias_0); end
    if (g_io_fauftb_entry_out_strong_bias_1 !== i_io_fauftb_entry_out_strong_bias_1) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_out_strong_bias_1 g=%h i=%h", $time, g_io_fauftb_entry_out_strong_bias_1, i_io_fauftb_entry_out_strong_bias_1); end
    if (g_io_fauftb_entry_hit_out !== i_io_fauftb_entry_hit_out) begin errors++;
      if(errors<=30) $display("[%0t] io_fauftb_entry_hit_out g=%h i=%h", $time, g_io_fauftb_entry_hit_out, i_io_fauftb_entry_hit_out); end
    if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=30) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if(errors<=30) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
