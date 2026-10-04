// FTB UT —— 自动生成：verif/ut/FTB/gen.py（勿手改）
// golden FTB vs 重写 FTB_xs（rtl/frontend/FTB.sv 经 derive_ut_impl 改名），逐拍比全部输出。
// 激励说明见 gen.py 文件头。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 1200;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clock = ~clock;

  // ---- 输入（两侧共用）----
  logic [47:0] io_reset_vector;
  logic [49:0] io_in_bits_s0_pc_0;
  logic [49:0] io_in_bits_s0_pc_1;
  logic [49:0] io_in_bits_s0_pc_2;
  logic [49:0] io_in_bits_s0_pc_3;
  logic io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  logic io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;
  logic io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;
  logic io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;
  logic io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;
  logic io_fauftb_entry_in_isCall;
  logic io_fauftb_entry_in_isRet;
  logic io_fauftb_entry_in_isJalr;
  logic io_fauftb_entry_in_valid;
  logic [3:0] io_fauftb_entry_in_brSlots_0_offset;
  logic io_fauftb_entry_in_brSlots_0_sharing;
  logic io_fauftb_entry_in_brSlots_0_valid;
  logic [11:0] io_fauftb_entry_in_brSlots_0_lower;
  logic [1:0] io_fauftb_entry_in_brSlots_0_tarStat;
  logic [3:0] io_fauftb_entry_in_tailSlot_offset;
  logic io_fauftb_entry_in_tailSlot_sharing;
  logic io_fauftb_entry_in_tailSlot_valid;
  logic [19:0] io_fauftb_entry_in_tailSlot_lower;
  logic [1:0] io_fauftb_entry_in_tailSlot_tarStat;
  logic [3:0] io_fauftb_entry_in_pftAddr;
  logic io_fauftb_entry_in_carry;
  logic io_fauftb_entry_in_last_may_be_rvi_call;
  logic io_fauftb_entry_in_strong_bias_0;
  logic io_fauftb_entry_in_strong_bias_1;
  logic io_fauftb_entry_hit_in;
  logic io_ctrl_btb_enable;
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
  logic io_s3_fire_0;
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
  logic io_update_bits_false_hit;
  logic io_update_bits_old_entry;
  logic [515:0] io_update_bits_meta;
  logic io_redirectFromIFU;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [3:0] boreChildrenBd_bore_be;
  logic [9:0] boreChildrenBd_bore_addr;
  logic [39:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [9:0] boreChildrenBd_bore_addr_rd;
  logic sigFromSrams_bore_ram_hold;
  logic sigFromSrams_bore_ram_bypass;
  logic sigFromSrams_bore_ram_bp_clken;
  logic sigFromSrams_bore_ram_aux_clk;
  logic sigFromSrams_bore_ram_aux_ckbp;
  logic sigFromSrams_bore_ram_mcp_hold;
  logic sigFromSrams_bore_cgen;
  logic sigFromSrams_bore_1_ram_hold;
  logic sigFromSrams_bore_1_ram_bypass;
  logic sigFromSrams_bore_1_ram_bp_clken;
  logic sigFromSrams_bore_1_ram_aux_clk;
  logic sigFromSrams_bore_1_ram_aux_ckbp;
  logic sigFromSrams_bore_1_ram_mcp_hold;
  logic sigFromSrams_bore_1_cgen;
  logic sigFromSrams_bore_2_ram_hold;
  logic sigFromSrams_bore_2_ram_bypass;
  logic sigFromSrams_bore_2_ram_bp_clken;
  logic sigFromSrams_bore_2_ram_aux_clk;
  logic sigFromSrams_bore_2_ram_aux_ckbp;
  logic sigFromSrams_bore_2_ram_mcp_hold;
  logic sigFromSrams_bore_2_cgen;
  logic sigFromSrams_bore_3_ram_hold;
  logic sigFromSrams_bore_3_ram_bypass;
  logic sigFromSrams_bore_3_ram_bp_clken;
  logic sigFromSrams_bore_3_ram_aux_clk;
  logic sigFromSrams_bore_3_ram_aux_ckbp;
  logic sigFromSrams_bore_3_ram_mcp_hold;
  logic sigFromSrams_bore_3_cgen;
  logic sigFromSrams_bore_4_ram_hold;
  logic sigFromSrams_bore_4_ram_bypass;
  logic sigFromSrams_bore_4_ram_bp_clken;
  logic sigFromSrams_bore_4_ram_aux_clk;
  logic sigFromSrams_bore_4_ram_aux_ckbp;
  logic sigFromSrams_bore_4_ram_mcp_hold;
  logic sigFromSrams_bore_4_cgen;
  logic sigFromSrams_bore_5_ram_hold;
  logic sigFromSrams_bore_5_ram_bypass;
  logic sigFromSrams_bore_5_ram_bp_clken;
  logic sigFromSrams_bore_5_ram_aux_clk;
  logic sigFromSrams_bore_5_ram_aux_ckbp;
  logic sigFromSrams_bore_5_ram_mcp_hold;
  logic sigFromSrams_bore_5_cgen;
  logic sigFromSrams_bore_6_ram_hold;
  logic sigFromSrams_bore_6_ram_bypass;
  logic sigFromSrams_bore_6_ram_bp_clken;
  logic sigFromSrams_bore_6_ram_aux_clk;
  logic sigFromSrams_bore_6_ram_aux_ckbp;
  logic sigFromSrams_bore_6_ram_mcp_hold;
  logic sigFromSrams_bore_6_cgen;
  logic sigFromSrams_bore_7_ram_hold;
  logic sigFromSrams_bore_7_ram_bypass;
  logic sigFromSrams_bore_7_ram_bp_clken;
  logic sigFromSrams_bore_7_ram_aux_clk;
  logic sigFromSrams_bore_7_ram_aux_ckbp;
  logic sigFromSrams_bore_7_ram_mcp_hold;
  logic sigFromSrams_bore_7_cgen;
  // ---- 输出 ----
  wire g_io_out_s2_full_pred_0_br_taken_mask_0, i_io_out_s2_full_pred_0_br_taken_mask_0;
  wire g_io_out_s2_full_pred_0_br_taken_mask_1, i_io_out_s2_full_pred_0_br_taken_mask_1;
  wire g_io_out_s2_full_pred_0_slot_valids_0, i_io_out_s2_full_pred_0_slot_valids_0;
  wire g_io_out_s2_full_pred_0_slot_valids_1, i_io_out_s2_full_pred_0_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_0_targets_0, i_io_out_s2_full_pred_0_targets_0;
  wire [49:0] g_io_out_s2_full_pred_0_targets_1, i_io_out_s2_full_pred_0_targets_1;
  wire [49:0] g_io_out_s2_full_pred_0_jalr_target, i_io_out_s2_full_pred_0_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_0_offsets_0, i_io_out_s2_full_pred_0_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_0_offsets_1, i_io_out_s2_full_pred_0_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_0_fallThroughAddr, i_io_out_s2_full_pred_0_fallThroughAddr;
  wire g_io_out_s2_full_pred_0_fallThroughErr, i_io_out_s2_full_pred_0_fallThroughErr;
  wire g_io_out_s2_full_pred_0_is_jal, i_io_out_s2_full_pred_0_is_jal;
  wire g_io_out_s2_full_pred_0_is_jalr, i_io_out_s2_full_pred_0_is_jalr;
  wire g_io_out_s2_full_pred_0_is_call, i_io_out_s2_full_pred_0_is_call;
  wire g_io_out_s2_full_pred_0_is_ret, i_io_out_s2_full_pred_0_is_ret;
  wire g_io_out_s2_full_pred_0_last_may_be_rvi_call, i_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_0_is_br_sharing, i_io_out_s2_full_pred_0_is_br_sharing;
  wire g_io_out_s2_full_pred_0_hit, i_io_out_s2_full_pred_0_hit;
  wire g_io_out_s2_full_pred_1_br_taken_mask_0, i_io_out_s2_full_pred_1_br_taken_mask_0;
  wire g_io_out_s2_full_pred_1_br_taken_mask_1, i_io_out_s2_full_pred_1_br_taken_mask_1;
  wire g_io_out_s2_full_pred_1_slot_valids_0, i_io_out_s2_full_pred_1_slot_valids_0;
  wire g_io_out_s2_full_pred_1_slot_valids_1, i_io_out_s2_full_pred_1_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_1_targets_0, i_io_out_s2_full_pred_1_targets_0;
  wire [49:0] g_io_out_s2_full_pred_1_targets_1, i_io_out_s2_full_pred_1_targets_1;
  wire [49:0] g_io_out_s2_full_pred_1_jalr_target, i_io_out_s2_full_pred_1_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_1_offsets_0, i_io_out_s2_full_pred_1_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_1_offsets_1, i_io_out_s2_full_pred_1_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_1_fallThroughAddr, i_io_out_s2_full_pred_1_fallThroughAddr;
  wire g_io_out_s2_full_pred_1_fallThroughErr, i_io_out_s2_full_pred_1_fallThroughErr;
  wire g_io_out_s2_full_pred_1_is_jal, i_io_out_s2_full_pred_1_is_jal;
  wire g_io_out_s2_full_pred_1_is_jalr, i_io_out_s2_full_pred_1_is_jalr;
  wire g_io_out_s2_full_pred_1_is_call, i_io_out_s2_full_pred_1_is_call;
  wire g_io_out_s2_full_pred_1_is_ret, i_io_out_s2_full_pred_1_is_ret;
  wire g_io_out_s2_full_pred_1_last_may_be_rvi_call, i_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_1_is_br_sharing, i_io_out_s2_full_pred_1_is_br_sharing;
  wire g_io_out_s2_full_pred_1_hit, i_io_out_s2_full_pred_1_hit;
  wire g_io_out_s2_full_pred_2_br_taken_mask_0, i_io_out_s2_full_pred_2_br_taken_mask_0;
  wire g_io_out_s2_full_pred_2_br_taken_mask_1, i_io_out_s2_full_pred_2_br_taken_mask_1;
  wire g_io_out_s2_full_pred_2_slot_valids_0, i_io_out_s2_full_pred_2_slot_valids_0;
  wire g_io_out_s2_full_pred_2_slot_valids_1, i_io_out_s2_full_pred_2_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_2_targets_0, i_io_out_s2_full_pred_2_targets_0;
  wire [49:0] g_io_out_s2_full_pred_2_targets_1, i_io_out_s2_full_pred_2_targets_1;
  wire [49:0] g_io_out_s2_full_pred_2_jalr_target, i_io_out_s2_full_pred_2_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_2_offsets_0, i_io_out_s2_full_pred_2_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_2_offsets_1, i_io_out_s2_full_pred_2_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_2_fallThroughAddr, i_io_out_s2_full_pred_2_fallThroughAddr;
  wire g_io_out_s2_full_pred_2_fallThroughErr, i_io_out_s2_full_pred_2_fallThroughErr;
  wire g_io_out_s2_full_pred_2_is_jal, i_io_out_s2_full_pred_2_is_jal;
  wire g_io_out_s2_full_pred_2_is_jalr, i_io_out_s2_full_pred_2_is_jalr;
  wire g_io_out_s2_full_pred_2_is_call, i_io_out_s2_full_pred_2_is_call;
  wire g_io_out_s2_full_pred_2_is_ret, i_io_out_s2_full_pred_2_is_ret;
  wire g_io_out_s2_full_pred_2_last_may_be_rvi_call, i_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_2_is_br_sharing, i_io_out_s2_full_pred_2_is_br_sharing;
  wire g_io_out_s2_full_pred_2_hit, i_io_out_s2_full_pred_2_hit;
  wire g_io_out_s2_full_pred_3_br_taken_mask_0, i_io_out_s2_full_pred_3_br_taken_mask_0;
  wire g_io_out_s2_full_pred_3_br_taken_mask_1, i_io_out_s2_full_pred_3_br_taken_mask_1;
  wire g_io_out_s2_full_pred_3_slot_valids_0, i_io_out_s2_full_pred_3_slot_valids_0;
  wire g_io_out_s2_full_pred_3_slot_valids_1, i_io_out_s2_full_pred_3_slot_valids_1;
  wire [49:0] g_io_out_s2_full_pred_3_targets_0, i_io_out_s2_full_pred_3_targets_0;
  wire [49:0] g_io_out_s2_full_pred_3_targets_1, i_io_out_s2_full_pred_3_targets_1;
  wire [49:0] g_io_out_s2_full_pred_3_jalr_target, i_io_out_s2_full_pred_3_jalr_target;
  wire [3:0] g_io_out_s2_full_pred_3_offsets_0, i_io_out_s2_full_pred_3_offsets_0;
  wire [3:0] g_io_out_s2_full_pred_3_offsets_1, i_io_out_s2_full_pred_3_offsets_1;
  wire [49:0] g_io_out_s2_full_pred_3_fallThroughAddr, i_io_out_s2_full_pred_3_fallThroughAddr;
  wire g_io_out_s2_full_pred_3_fallThroughErr, i_io_out_s2_full_pred_3_fallThroughErr;
  wire g_io_out_s2_full_pred_3_is_jal, i_io_out_s2_full_pred_3_is_jal;
  wire g_io_out_s2_full_pred_3_is_jalr, i_io_out_s2_full_pred_3_is_jalr;
  wire g_io_out_s2_full_pred_3_is_call, i_io_out_s2_full_pred_3_is_call;
  wire g_io_out_s2_full_pred_3_is_ret, i_io_out_s2_full_pred_3_is_ret;
  wire g_io_out_s2_full_pred_3_last_may_be_rvi_call, i_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire g_io_out_s2_full_pred_3_is_br_sharing, i_io_out_s2_full_pred_3_is_br_sharing;
  wire g_io_out_s2_full_pred_3_hit, i_io_out_s2_full_pred_3_hit;
  wire g_io_out_s3_full_pred_0_br_taken_mask_0, i_io_out_s3_full_pred_0_br_taken_mask_0;
  wire g_io_out_s3_full_pred_0_br_taken_mask_1, i_io_out_s3_full_pred_0_br_taken_mask_1;
  wire g_io_out_s3_full_pred_0_slot_valids_0, i_io_out_s3_full_pred_0_slot_valids_0;
  wire g_io_out_s3_full_pred_0_slot_valids_1, i_io_out_s3_full_pred_0_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_0_targets_0, i_io_out_s3_full_pred_0_targets_0;
  wire [49:0] g_io_out_s3_full_pred_0_targets_1, i_io_out_s3_full_pred_0_targets_1;
  wire [3:0] g_io_out_s3_full_pred_0_offsets_0, i_io_out_s3_full_pred_0_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_0_offsets_1, i_io_out_s3_full_pred_0_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_0_fallThroughAddr, i_io_out_s3_full_pred_0_fallThroughAddr;
  wire g_io_out_s3_full_pred_0_fallThroughErr, i_io_out_s3_full_pred_0_fallThroughErr;
  wire g_io_out_s3_full_pred_0_multiHit, i_io_out_s3_full_pred_0_multiHit;
  wire g_io_out_s3_full_pred_0_is_jal, i_io_out_s3_full_pred_0_is_jal;
  wire g_io_out_s3_full_pred_0_is_jalr, i_io_out_s3_full_pred_0_is_jalr;
  wire g_io_out_s3_full_pred_0_is_call, i_io_out_s3_full_pred_0_is_call;
  wire g_io_out_s3_full_pred_0_is_ret, i_io_out_s3_full_pred_0_is_ret;
  wire g_io_out_s3_full_pred_0_last_may_be_rvi_call, i_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_0_is_br_sharing, i_io_out_s3_full_pred_0_is_br_sharing;
  wire g_io_out_s3_full_pred_0_hit, i_io_out_s3_full_pred_0_hit;
  wire g_io_out_s3_full_pred_1_br_taken_mask_0, i_io_out_s3_full_pred_1_br_taken_mask_0;
  wire g_io_out_s3_full_pred_1_br_taken_mask_1, i_io_out_s3_full_pred_1_br_taken_mask_1;
  wire g_io_out_s3_full_pred_1_slot_valids_0, i_io_out_s3_full_pred_1_slot_valids_0;
  wire g_io_out_s3_full_pred_1_slot_valids_1, i_io_out_s3_full_pred_1_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_1_targets_0, i_io_out_s3_full_pred_1_targets_0;
  wire [49:0] g_io_out_s3_full_pred_1_targets_1, i_io_out_s3_full_pred_1_targets_1;
  wire [3:0] g_io_out_s3_full_pred_1_offsets_0, i_io_out_s3_full_pred_1_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_1_offsets_1, i_io_out_s3_full_pred_1_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_1_fallThroughAddr, i_io_out_s3_full_pred_1_fallThroughAddr;
  wire g_io_out_s3_full_pred_1_fallThroughErr, i_io_out_s3_full_pred_1_fallThroughErr;
  wire g_io_out_s3_full_pred_1_multiHit, i_io_out_s3_full_pred_1_multiHit;
  wire g_io_out_s3_full_pred_1_is_jal, i_io_out_s3_full_pred_1_is_jal;
  wire g_io_out_s3_full_pred_1_is_jalr, i_io_out_s3_full_pred_1_is_jalr;
  wire g_io_out_s3_full_pred_1_is_call, i_io_out_s3_full_pred_1_is_call;
  wire g_io_out_s3_full_pred_1_is_ret, i_io_out_s3_full_pred_1_is_ret;
  wire g_io_out_s3_full_pred_1_last_may_be_rvi_call, i_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_1_is_br_sharing, i_io_out_s3_full_pred_1_is_br_sharing;
  wire g_io_out_s3_full_pred_1_hit, i_io_out_s3_full_pred_1_hit;
  wire g_io_out_s3_full_pred_2_br_taken_mask_0, i_io_out_s3_full_pred_2_br_taken_mask_0;
  wire g_io_out_s3_full_pred_2_br_taken_mask_1, i_io_out_s3_full_pred_2_br_taken_mask_1;
  wire g_io_out_s3_full_pred_2_slot_valids_0, i_io_out_s3_full_pred_2_slot_valids_0;
  wire g_io_out_s3_full_pred_2_slot_valids_1, i_io_out_s3_full_pred_2_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_2_targets_0, i_io_out_s3_full_pred_2_targets_0;
  wire [49:0] g_io_out_s3_full_pred_2_targets_1, i_io_out_s3_full_pred_2_targets_1;
  wire [3:0] g_io_out_s3_full_pred_2_offsets_0, i_io_out_s3_full_pred_2_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_2_offsets_1, i_io_out_s3_full_pred_2_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_2_fallThroughAddr, i_io_out_s3_full_pred_2_fallThroughAddr;
  wire g_io_out_s3_full_pred_2_fallThroughErr, i_io_out_s3_full_pred_2_fallThroughErr;
  wire g_io_out_s3_full_pred_2_multiHit, i_io_out_s3_full_pred_2_multiHit;
  wire g_io_out_s3_full_pred_2_is_jal, i_io_out_s3_full_pred_2_is_jal;
  wire g_io_out_s3_full_pred_2_is_jalr, i_io_out_s3_full_pred_2_is_jalr;
  wire g_io_out_s3_full_pred_2_is_call, i_io_out_s3_full_pred_2_is_call;
  wire g_io_out_s3_full_pred_2_is_ret, i_io_out_s3_full_pred_2_is_ret;
  wire g_io_out_s3_full_pred_2_last_may_be_rvi_call, i_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_2_is_br_sharing, i_io_out_s3_full_pred_2_is_br_sharing;
  wire g_io_out_s3_full_pred_2_hit, i_io_out_s3_full_pred_2_hit;
  wire g_io_out_s3_full_pred_3_br_taken_mask_0, i_io_out_s3_full_pred_3_br_taken_mask_0;
  wire g_io_out_s3_full_pred_3_br_taken_mask_1, i_io_out_s3_full_pred_3_br_taken_mask_1;
  wire g_io_out_s3_full_pred_3_slot_valids_0, i_io_out_s3_full_pred_3_slot_valids_0;
  wire g_io_out_s3_full_pred_3_slot_valids_1, i_io_out_s3_full_pred_3_slot_valids_1;
  wire [49:0] g_io_out_s3_full_pred_3_targets_0, i_io_out_s3_full_pred_3_targets_0;
  wire [49:0] g_io_out_s3_full_pred_3_targets_1, i_io_out_s3_full_pred_3_targets_1;
  wire [3:0] g_io_out_s3_full_pred_3_offsets_0, i_io_out_s3_full_pred_3_offsets_0;
  wire [3:0] g_io_out_s3_full_pred_3_offsets_1, i_io_out_s3_full_pred_3_offsets_1;
  wire [49:0] g_io_out_s3_full_pred_3_fallThroughAddr, i_io_out_s3_full_pred_3_fallThroughAddr;
  wire g_io_out_s3_full_pred_3_fallThroughErr, i_io_out_s3_full_pred_3_fallThroughErr;
  wire g_io_out_s3_full_pred_3_multiHit, i_io_out_s3_full_pred_3_multiHit;
  wire g_io_out_s3_full_pred_3_is_jal, i_io_out_s3_full_pred_3_is_jal;
  wire g_io_out_s3_full_pred_3_is_jalr, i_io_out_s3_full_pred_3_is_jalr;
  wire g_io_out_s3_full_pred_3_is_call, i_io_out_s3_full_pred_3_is_call;
  wire g_io_out_s3_full_pred_3_is_ret, i_io_out_s3_full_pred_3_is_ret;
  wire g_io_out_s3_full_pred_3_last_may_be_rvi_call, i_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire g_io_out_s3_full_pred_3_is_br_sharing, i_io_out_s3_full_pred_3_is_br_sharing;
  wire g_io_out_s3_full_pred_3_hit, i_io_out_s3_full_pred_3_hit;
  wire g_io_out_s1_uftbHit, i_io_out_s1_uftbHit;
  wire g_io_out_s1_uftbHasIndirect, i_io_out_s1_uftbHasIndirect;
  wire g_io_out_s1_ftbCloseReq, i_io_out_s1_ftbCloseReq;
  wire [515:0] g_io_out_last_stage_meta, i_io_out_last_stage_meta;
  wire g_io_out_last_stage_spec_info_sc_disagree_0, i_io_out_last_stage_spec_info_sc_disagree_0;
  wire g_io_out_last_stage_spec_info_sc_disagree_1, i_io_out_last_stage_spec_info_sc_disagree_1;
  wire g_io_out_last_stage_ftb_entry_isCall, i_io_out_last_stage_ftb_entry_isCall;
  wire g_io_out_last_stage_ftb_entry_isRet, i_io_out_last_stage_ftb_entry_isRet;
  wire g_io_out_last_stage_ftb_entry_isJalr, i_io_out_last_stage_ftb_entry_isJalr;
  wire g_io_out_last_stage_ftb_entry_valid, i_io_out_last_stage_ftb_entry_valid;
  wire [3:0] g_io_out_last_stage_ftb_entry_brSlots_0_offset, i_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire g_io_out_last_stage_ftb_entry_brSlots_0_sharing, i_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire g_io_out_last_stage_ftb_entry_brSlots_0_valid, i_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0] g_io_out_last_stage_ftb_entry_brSlots_0_lower, i_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0] g_io_out_last_stage_ftb_entry_brSlots_0_tarStat, i_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0] g_io_out_last_stage_ftb_entry_tailSlot_offset, i_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire g_io_out_last_stage_ftb_entry_tailSlot_sharing, i_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire g_io_out_last_stage_ftb_entry_tailSlot_valid, i_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0] g_io_out_last_stage_ftb_entry_tailSlot_lower, i_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0] g_io_out_last_stage_ftb_entry_tailSlot_tarStat, i_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0] g_io_out_last_stage_ftb_entry_pftAddr, i_io_out_last_stage_ftb_entry_pftAddr;
  wire g_io_out_last_stage_ftb_entry_carry, i_io_out_last_stage_ftb_entry_carry;
  wire g_io_out_last_stage_ftb_entry_last_may_be_rvi_call, i_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire g_io_out_last_stage_ftb_entry_strong_bias_0, i_io_out_last_stage_ftb_entry_strong_bias_0;
  wire g_io_out_last_stage_ftb_entry_strong_bias_1, i_io_out_last_stage_ftb_entry_strong_bias_1;
  wire g_io_s1_ready, i_io_s1_ready;
  wire [5:0] g_io_perf_0_value, i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value, i_io_perf_1_value;
  wire g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack;
  wire [39:0] g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata;

  FTB u_g (
    .clock(clock),
    .reset(reset),
    .io_reset_vector(io_reset_vector),
    .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1),
    .io_out_s2_full_pred_0_br_taken_mask_0(g_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1(g_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0(g_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1(g_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0(g_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1(g_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target(g_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0(g_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1(g_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr(g_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr(g_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal(g_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr(g_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call(g_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret(g_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call(g_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing(g_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit(g_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0(g_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1(g_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0(g_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1(g_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0(g_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1(g_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target(g_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0(g_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1(g_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr(g_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr(g_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal(g_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr(g_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call(g_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret(g_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call(g_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing(g_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit(g_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0(g_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1(g_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0(g_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1(g_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0(g_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1(g_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target(g_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0(g_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1(g_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr(g_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr(g_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal(g_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr(g_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call(g_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret(g_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call(g_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing(g_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit(g_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0(g_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1(g_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0(g_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1(g_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0(g_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1(g_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target(g_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0(g_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1(g_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr(g_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr(g_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal(g_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr(g_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call(g_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret(g_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call(g_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing(g_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit(g_io_out_s2_full_pred_3_hit),
    .io_out_s3_full_pred_0_br_taken_mask_0(g_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1(g_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0(g_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1(g_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0(g_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1(g_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_offsets_0(g_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1(g_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr(g_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr(g_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit(g_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal(g_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr(g_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call(g_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret(g_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call(g_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing(g_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit(g_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0(g_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1(g_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0(g_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1(g_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0(g_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1(g_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_offsets_0(g_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1(g_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr(g_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr(g_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit(g_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal(g_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr(g_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call(g_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret(g_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call(g_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing(g_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit(g_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0(g_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1(g_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0(g_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1(g_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0(g_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1(g_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_offsets_0(g_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1(g_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr(g_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr(g_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit(g_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal(g_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr(g_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call(g_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret(g_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call(g_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing(g_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit(g_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0(g_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1(g_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0(g_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1(g_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0(g_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1(g_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_offsets_0(g_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1(g_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr(g_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr(g_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit(g_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal(g_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr(g_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call(g_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret(g_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call(g_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing(g_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit(g_io_out_s3_full_pred_3_hit),
    .io_out_s1_uftbHit(g_io_out_s1_uftbHit),
    .io_out_s1_uftbHasIndirect(g_io_out_s1_uftbHasIndirect),
    .io_out_s1_ftbCloseReq(g_io_out_s1_ftbCloseReq),
    .io_out_last_stage_meta(g_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0(g_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1(g_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall(g_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet(g_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr(g_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid(g_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset(g_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing(g_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid(g_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower(g_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat(g_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset(g_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing(g_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid(g_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower(g_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat(g_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr(g_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry(g_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call(g_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0(g_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1(g_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_fauftb_entry_in_isCall(io_fauftb_entry_in_isCall),
    .io_fauftb_entry_in_isRet(io_fauftb_entry_in_isRet),
    .io_fauftb_entry_in_isJalr(io_fauftb_entry_in_isJalr),
    .io_fauftb_entry_in_valid(io_fauftb_entry_in_valid),
    .io_fauftb_entry_in_brSlots_0_offset(io_fauftb_entry_in_brSlots_0_offset),
    .io_fauftb_entry_in_brSlots_0_sharing(io_fauftb_entry_in_brSlots_0_sharing),
    .io_fauftb_entry_in_brSlots_0_valid(io_fauftb_entry_in_brSlots_0_valid),
    .io_fauftb_entry_in_brSlots_0_lower(io_fauftb_entry_in_brSlots_0_lower),
    .io_fauftb_entry_in_brSlots_0_tarStat(io_fauftb_entry_in_brSlots_0_tarStat),
    .io_fauftb_entry_in_tailSlot_offset(io_fauftb_entry_in_tailSlot_offset),
    .io_fauftb_entry_in_tailSlot_sharing(io_fauftb_entry_in_tailSlot_sharing),
    .io_fauftb_entry_in_tailSlot_valid(io_fauftb_entry_in_tailSlot_valid),
    .io_fauftb_entry_in_tailSlot_lower(io_fauftb_entry_in_tailSlot_lower),
    .io_fauftb_entry_in_tailSlot_tarStat(io_fauftb_entry_in_tailSlot_tarStat),
    .io_fauftb_entry_in_pftAddr(io_fauftb_entry_in_pftAddr),
    .io_fauftb_entry_in_carry(io_fauftb_entry_in_carry),
    .io_fauftb_entry_in_last_may_be_rvi_call(io_fauftb_entry_in_last_may_be_rvi_call),
    .io_fauftb_entry_in_strong_bias_0(io_fauftb_entry_in_strong_bias_0),
    .io_fauftb_entry_in_strong_bias_1(io_fauftb_entry_in_strong_bias_1),
    .io_fauftb_entry_hit_in(io_fauftb_entry_hit_in),
    .io_ctrl_btb_enable(io_ctrl_btb_enable),
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
    .io_s3_fire_0(io_s3_fire_0),
    .io_s1_ready(g_io_s1_ready),
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
    .io_update_bits_false_hit(io_update_bits_false_hit),
    .io_update_bits_old_entry(io_update_bits_old_entry),
    .io_update_bits_meta(io_update_bits_meta),
    .io_redirectFromIFU(io_redirectFromIFU),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen)
  );

  FTB_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_reset_vector(io_reset_vector),
    .io_in_bits_s0_pc_0(io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1(io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2(io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3(io_in_bits_s0_pc_3),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1(io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1(io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1),
    .io_out_s2_full_pred_0_br_taken_mask_0(i_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1(i_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0(i_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1(i_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0(i_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1(i_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target(i_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0(i_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1(i_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr(i_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr(i_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal(i_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr(i_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call(i_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret(i_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call(i_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing(i_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit(i_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0(i_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1(i_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0(i_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1(i_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0(i_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1(i_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target(i_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0(i_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1(i_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr(i_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr(i_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal(i_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr(i_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call(i_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret(i_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call(i_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing(i_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit(i_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0(i_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1(i_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0(i_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1(i_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0(i_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1(i_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target(i_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0(i_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1(i_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr(i_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr(i_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal(i_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr(i_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call(i_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret(i_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call(i_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing(i_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit(i_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0(i_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1(i_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0(i_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1(i_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0(i_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1(i_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target(i_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0(i_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1(i_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr(i_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr(i_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal(i_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr(i_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call(i_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret(i_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call(i_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing(i_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit(i_io_out_s2_full_pred_3_hit),
    .io_out_s3_full_pred_0_br_taken_mask_0(i_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1(i_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0(i_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1(i_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0(i_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1(i_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_offsets_0(i_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1(i_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr(i_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr(i_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit(i_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal(i_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr(i_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call(i_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret(i_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call(i_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing(i_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit(i_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0(i_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1(i_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0(i_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1(i_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0(i_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1(i_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_offsets_0(i_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1(i_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr(i_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr(i_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit(i_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal(i_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr(i_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call(i_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret(i_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call(i_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing(i_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit(i_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0(i_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1(i_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0(i_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1(i_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0(i_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1(i_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_offsets_0(i_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1(i_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr(i_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr(i_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit(i_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal(i_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr(i_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call(i_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret(i_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call(i_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing(i_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit(i_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0(i_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1(i_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0(i_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1(i_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0(i_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1(i_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_offsets_0(i_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1(i_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr(i_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr(i_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit(i_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal(i_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr(i_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call(i_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret(i_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call(i_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing(i_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit(i_io_out_s3_full_pred_3_hit),
    .io_out_s1_uftbHit(i_io_out_s1_uftbHit),
    .io_out_s1_uftbHasIndirect(i_io_out_s1_uftbHasIndirect),
    .io_out_s1_ftbCloseReq(i_io_out_s1_ftbCloseReq),
    .io_out_last_stage_meta(i_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0(i_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1(i_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall(i_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet(i_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr(i_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid(i_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset(i_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing(i_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid(i_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower(i_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat(i_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset(i_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing(i_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid(i_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower(i_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat(i_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr(i_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry(i_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call(i_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0(i_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1(i_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_fauftb_entry_in_isCall(io_fauftb_entry_in_isCall),
    .io_fauftb_entry_in_isRet(io_fauftb_entry_in_isRet),
    .io_fauftb_entry_in_isJalr(io_fauftb_entry_in_isJalr),
    .io_fauftb_entry_in_valid(io_fauftb_entry_in_valid),
    .io_fauftb_entry_in_brSlots_0_offset(io_fauftb_entry_in_brSlots_0_offset),
    .io_fauftb_entry_in_brSlots_0_sharing(io_fauftb_entry_in_brSlots_0_sharing),
    .io_fauftb_entry_in_brSlots_0_valid(io_fauftb_entry_in_brSlots_0_valid),
    .io_fauftb_entry_in_brSlots_0_lower(io_fauftb_entry_in_brSlots_0_lower),
    .io_fauftb_entry_in_brSlots_0_tarStat(io_fauftb_entry_in_brSlots_0_tarStat),
    .io_fauftb_entry_in_tailSlot_offset(io_fauftb_entry_in_tailSlot_offset),
    .io_fauftb_entry_in_tailSlot_sharing(io_fauftb_entry_in_tailSlot_sharing),
    .io_fauftb_entry_in_tailSlot_valid(io_fauftb_entry_in_tailSlot_valid),
    .io_fauftb_entry_in_tailSlot_lower(io_fauftb_entry_in_tailSlot_lower),
    .io_fauftb_entry_in_tailSlot_tarStat(io_fauftb_entry_in_tailSlot_tarStat),
    .io_fauftb_entry_in_pftAddr(io_fauftb_entry_in_pftAddr),
    .io_fauftb_entry_in_carry(io_fauftb_entry_in_carry),
    .io_fauftb_entry_in_last_may_be_rvi_call(io_fauftb_entry_in_last_may_be_rvi_call),
    .io_fauftb_entry_in_strong_bias_0(io_fauftb_entry_in_strong_bias_0),
    .io_fauftb_entry_in_strong_bias_1(io_fauftb_entry_in_strong_bias_1),
    .io_fauftb_entry_hit_in(io_fauftb_entry_hit_in),
    .io_ctrl_btb_enable(io_ctrl_btb_enable),
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
    .io_s3_fire_0(io_s3_fire_0),
    .io_s1_ready(i_io_s1_ready),
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
    .io_update_bits_false_hit(io_update_bits_false_hit),
    .io_update_bits_old_entry(io_update_bits_old_entry),
    .io_update_bits_meta(io_update_bits_meta),
    .io_redirectFromIFU(io_redirectFromIFU),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen)
  );

  // ---- 逐拍比较（下降沿采样：上升沿后组合输出已稳定）----
  task automatic compare();
    checks++;
    if (g_io_out_s2_full_pred_0_br_taken_mask_0 !== i_io_out_s2_full_pred_0_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_br_taken_mask_0, i_io_out_s2_full_pred_0_br_taken_mask_0); end
    checks++;
    if (g_io_out_s2_full_pred_0_br_taken_mask_1 !== i_io_out_s2_full_pred_0_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_br_taken_mask_1, i_io_out_s2_full_pred_0_br_taken_mask_1); end
    checks++;
    if (g_io_out_s2_full_pred_0_slot_valids_0 !== i_io_out_s2_full_pred_0_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_slot_valids_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_slot_valids_0, i_io_out_s2_full_pred_0_slot_valids_0); end
    checks++;
    if (g_io_out_s2_full_pred_0_slot_valids_1 !== i_io_out_s2_full_pred_0_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_slot_valids_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_slot_valids_1, i_io_out_s2_full_pred_0_slot_valids_1); end
    checks++;
    if (g_io_out_s2_full_pred_0_targets_0 !== i_io_out_s2_full_pred_0_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_targets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_targets_0, i_io_out_s2_full_pred_0_targets_0); end
    checks++;
    if (g_io_out_s2_full_pred_0_targets_1 !== i_io_out_s2_full_pred_0_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_targets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_targets_1, i_io_out_s2_full_pred_0_targets_1); end
    checks++;
    if (g_io_out_s2_full_pred_0_jalr_target !== i_io_out_s2_full_pred_0_jalr_target) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_jalr_target g=%h i=%h", cycle, g_io_out_s2_full_pred_0_jalr_target, i_io_out_s2_full_pred_0_jalr_target); end
    checks++;
    if (g_io_out_s2_full_pred_0_offsets_0 !== i_io_out_s2_full_pred_0_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_offsets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_offsets_0, i_io_out_s2_full_pred_0_offsets_0); end
    checks++;
    if (g_io_out_s2_full_pred_0_offsets_1 !== i_io_out_s2_full_pred_0_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_offsets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_0_offsets_1, i_io_out_s2_full_pred_0_offsets_1); end
    checks++;
    if (g_io_out_s2_full_pred_0_fallThroughAddr !== i_io_out_s2_full_pred_0_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_fallThroughAddr g=%h i=%h", cycle, g_io_out_s2_full_pred_0_fallThroughAddr, i_io_out_s2_full_pred_0_fallThroughAddr); end
    checks++;
    if (g_io_out_s2_full_pred_0_fallThroughErr !== i_io_out_s2_full_pred_0_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_fallThroughErr g=%h i=%h", cycle, g_io_out_s2_full_pred_0_fallThroughErr, i_io_out_s2_full_pred_0_fallThroughErr); end
    checks++;
    if (g_io_out_s2_full_pred_0_is_jal !== i_io_out_s2_full_pred_0_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_is_jal g=%h i=%h", cycle, g_io_out_s2_full_pred_0_is_jal, i_io_out_s2_full_pred_0_is_jal); end
    checks++;
    if (g_io_out_s2_full_pred_0_is_jalr !== i_io_out_s2_full_pred_0_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_is_jalr g=%h i=%h", cycle, g_io_out_s2_full_pred_0_is_jalr, i_io_out_s2_full_pred_0_is_jalr); end
    checks++;
    if (g_io_out_s2_full_pred_0_is_call !== i_io_out_s2_full_pred_0_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_is_call g=%h i=%h", cycle, g_io_out_s2_full_pred_0_is_call, i_io_out_s2_full_pred_0_is_call); end
    checks++;
    if (g_io_out_s2_full_pred_0_is_ret !== i_io_out_s2_full_pred_0_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_is_ret g=%h i=%h", cycle, g_io_out_s2_full_pred_0_is_ret, i_io_out_s2_full_pred_0_is_ret); end
    checks++;
    if (g_io_out_s2_full_pred_0_last_may_be_rvi_call !== i_io_out_s2_full_pred_0_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s2_full_pred_0_last_may_be_rvi_call, i_io_out_s2_full_pred_0_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s2_full_pred_0_is_br_sharing !== i_io_out_s2_full_pred_0_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_is_br_sharing g=%h i=%h", cycle, g_io_out_s2_full_pred_0_is_br_sharing, i_io_out_s2_full_pred_0_is_br_sharing); end
    checks++;
    if (g_io_out_s2_full_pred_0_hit !== i_io_out_s2_full_pred_0_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_0_hit g=%h i=%h", cycle, g_io_out_s2_full_pred_0_hit, i_io_out_s2_full_pred_0_hit); end
    checks++;
    if (g_io_out_s2_full_pred_1_br_taken_mask_0 !== i_io_out_s2_full_pred_1_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_br_taken_mask_0, i_io_out_s2_full_pred_1_br_taken_mask_0); end
    checks++;
    if (g_io_out_s2_full_pred_1_br_taken_mask_1 !== i_io_out_s2_full_pred_1_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_br_taken_mask_1, i_io_out_s2_full_pred_1_br_taken_mask_1); end
    checks++;
    if (g_io_out_s2_full_pred_1_slot_valids_0 !== i_io_out_s2_full_pred_1_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_slot_valids_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_slot_valids_0, i_io_out_s2_full_pred_1_slot_valids_0); end
    checks++;
    if (g_io_out_s2_full_pred_1_slot_valids_1 !== i_io_out_s2_full_pred_1_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_slot_valids_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_slot_valids_1, i_io_out_s2_full_pred_1_slot_valids_1); end
    checks++;
    if (g_io_out_s2_full_pred_1_targets_0 !== i_io_out_s2_full_pred_1_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_targets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_targets_0, i_io_out_s2_full_pred_1_targets_0); end
    checks++;
    if (g_io_out_s2_full_pred_1_targets_1 !== i_io_out_s2_full_pred_1_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_targets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_targets_1, i_io_out_s2_full_pred_1_targets_1); end
    checks++;
    if (g_io_out_s2_full_pred_1_jalr_target !== i_io_out_s2_full_pred_1_jalr_target) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_jalr_target g=%h i=%h", cycle, g_io_out_s2_full_pred_1_jalr_target, i_io_out_s2_full_pred_1_jalr_target); end
    checks++;
    if (g_io_out_s2_full_pred_1_offsets_0 !== i_io_out_s2_full_pred_1_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_offsets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_offsets_0, i_io_out_s2_full_pred_1_offsets_0); end
    checks++;
    if (g_io_out_s2_full_pred_1_offsets_1 !== i_io_out_s2_full_pred_1_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_offsets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_1_offsets_1, i_io_out_s2_full_pred_1_offsets_1); end
    checks++;
    if (g_io_out_s2_full_pred_1_fallThroughAddr !== i_io_out_s2_full_pred_1_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_fallThroughAddr g=%h i=%h", cycle, g_io_out_s2_full_pred_1_fallThroughAddr, i_io_out_s2_full_pred_1_fallThroughAddr); end
    checks++;
    if (g_io_out_s2_full_pred_1_fallThroughErr !== i_io_out_s2_full_pred_1_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_fallThroughErr g=%h i=%h", cycle, g_io_out_s2_full_pred_1_fallThroughErr, i_io_out_s2_full_pred_1_fallThroughErr); end
    checks++;
    if (g_io_out_s2_full_pred_1_is_jal !== i_io_out_s2_full_pred_1_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_is_jal g=%h i=%h", cycle, g_io_out_s2_full_pred_1_is_jal, i_io_out_s2_full_pred_1_is_jal); end
    checks++;
    if (g_io_out_s2_full_pred_1_is_jalr !== i_io_out_s2_full_pred_1_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_is_jalr g=%h i=%h", cycle, g_io_out_s2_full_pred_1_is_jalr, i_io_out_s2_full_pred_1_is_jalr); end
    checks++;
    if (g_io_out_s2_full_pred_1_is_call !== i_io_out_s2_full_pred_1_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_is_call g=%h i=%h", cycle, g_io_out_s2_full_pred_1_is_call, i_io_out_s2_full_pred_1_is_call); end
    checks++;
    if (g_io_out_s2_full_pred_1_is_ret !== i_io_out_s2_full_pred_1_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_is_ret g=%h i=%h", cycle, g_io_out_s2_full_pred_1_is_ret, i_io_out_s2_full_pred_1_is_ret); end
    checks++;
    if (g_io_out_s2_full_pred_1_last_may_be_rvi_call !== i_io_out_s2_full_pred_1_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s2_full_pred_1_last_may_be_rvi_call, i_io_out_s2_full_pred_1_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s2_full_pred_1_is_br_sharing !== i_io_out_s2_full_pred_1_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_is_br_sharing g=%h i=%h", cycle, g_io_out_s2_full_pred_1_is_br_sharing, i_io_out_s2_full_pred_1_is_br_sharing); end
    checks++;
    if (g_io_out_s2_full_pred_1_hit !== i_io_out_s2_full_pred_1_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_1_hit g=%h i=%h", cycle, g_io_out_s2_full_pred_1_hit, i_io_out_s2_full_pred_1_hit); end
    checks++;
    if (g_io_out_s2_full_pred_2_br_taken_mask_0 !== i_io_out_s2_full_pred_2_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_br_taken_mask_0, i_io_out_s2_full_pred_2_br_taken_mask_0); end
    checks++;
    if (g_io_out_s2_full_pred_2_br_taken_mask_1 !== i_io_out_s2_full_pred_2_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_br_taken_mask_1, i_io_out_s2_full_pred_2_br_taken_mask_1); end
    checks++;
    if (g_io_out_s2_full_pred_2_slot_valids_0 !== i_io_out_s2_full_pred_2_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_slot_valids_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_slot_valids_0, i_io_out_s2_full_pred_2_slot_valids_0); end
    checks++;
    if (g_io_out_s2_full_pred_2_slot_valids_1 !== i_io_out_s2_full_pred_2_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_slot_valids_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_slot_valids_1, i_io_out_s2_full_pred_2_slot_valids_1); end
    checks++;
    if (g_io_out_s2_full_pred_2_targets_0 !== i_io_out_s2_full_pred_2_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_targets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_targets_0, i_io_out_s2_full_pred_2_targets_0); end
    checks++;
    if (g_io_out_s2_full_pred_2_targets_1 !== i_io_out_s2_full_pred_2_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_targets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_targets_1, i_io_out_s2_full_pred_2_targets_1); end
    checks++;
    if (g_io_out_s2_full_pred_2_jalr_target !== i_io_out_s2_full_pred_2_jalr_target) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_jalr_target g=%h i=%h", cycle, g_io_out_s2_full_pred_2_jalr_target, i_io_out_s2_full_pred_2_jalr_target); end
    checks++;
    if (g_io_out_s2_full_pred_2_offsets_0 !== i_io_out_s2_full_pred_2_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_offsets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_offsets_0, i_io_out_s2_full_pred_2_offsets_0); end
    checks++;
    if (g_io_out_s2_full_pred_2_offsets_1 !== i_io_out_s2_full_pred_2_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_offsets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_2_offsets_1, i_io_out_s2_full_pred_2_offsets_1); end
    checks++;
    if (g_io_out_s2_full_pred_2_fallThroughAddr !== i_io_out_s2_full_pred_2_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_fallThroughAddr g=%h i=%h", cycle, g_io_out_s2_full_pred_2_fallThroughAddr, i_io_out_s2_full_pred_2_fallThroughAddr); end
    checks++;
    if (g_io_out_s2_full_pred_2_fallThroughErr !== i_io_out_s2_full_pred_2_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_fallThroughErr g=%h i=%h", cycle, g_io_out_s2_full_pred_2_fallThroughErr, i_io_out_s2_full_pred_2_fallThroughErr); end
    checks++;
    if (g_io_out_s2_full_pred_2_is_jal !== i_io_out_s2_full_pred_2_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_is_jal g=%h i=%h", cycle, g_io_out_s2_full_pred_2_is_jal, i_io_out_s2_full_pred_2_is_jal); end
    checks++;
    if (g_io_out_s2_full_pred_2_is_jalr !== i_io_out_s2_full_pred_2_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_is_jalr g=%h i=%h", cycle, g_io_out_s2_full_pred_2_is_jalr, i_io_out_s2_full_pred_2_is_jalr); end
    checks++;
    if (g_io_out_s2_full_pred_2_is_call !== i_io_out_s2_full_pred_2_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_is_call g=%h i=%h", cycle, g_io_out_s2_full_pred_2_is_call, i_io_out_s2_full_pred_2_is_call); end
    checks++;
    if (g_io_out_s2_full_pred_2_is_ret !== i_io_out_s2_full_pred_2_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_is_ret g=%h i=%h", cycle, g_io_out_s2_full_pred_2_is_ret, i_io_out_s2_full_pred_2_is_ret); end
    checks++;
    if (g_io_out_s2_full_pred_2_last_may_be_rvi_call !== i_io_out_s2_full_pred_2_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s2_full_pred_2_last_may_be_rvi_call, i_io_out_s2_full_pred_2_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s2_full_pred_2_is_br_sharing !== i_io_out_s2_full_pred_2_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_is_br_sharing g=%h i=%h", cycle, g_io_out_s2_full_pred_2_is_br_sharing, i_io_out_s2_full_pred_2_is_br_sharing); end
    checks++;
    if (g_io_out_s2_full_pred_2_hit !== i_io_out_s2_full_pred_2_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_2_hit g=%h i=%h", cycle, g_io_out_s2_full_pred_2_hit, i_io_out_s2_full_pred_2_hit); end
    checks++;
    if (g_io_out_s2_full_pred_3_br_taken_mask_0 !== i_io_out_s2_full_pred_3_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_br_taken_mask_0, i_io_out_s2_full_pred_3_br_taken_mask_0); end
    checks++;
    if (g_io_out_s2_full_pred_3_br_taken_mask_1 !== i_io_out_s2_full_pred_3_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_br_taken_mask_1, i_io_out_s2_full_pred_3_br_taken_mask_1); end
    checks++;
    if (g_io_out_s2_full_pred_3_slot_valids_0 !== i_io_out_s2_full_pred_3_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_slot_valids_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_slot_valids_0, i_io_out_s2_full_pred_3_slot_valids_0); end
    checks++;
    if (g_io_out_s2_full_pred_3_slot_valids_1 !== i_io_out_s2_full_pred_3_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_slot_valids_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_slot_valids_1, i_io_out_s2_full_pred_3_slot_valids_1); end
    checks++;
    if (g_io_out_s2_full_pred_3_targets_0 !== i_io_out_s2_full_pred_3_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_targets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_targets_0, i_io_out_s2_full_pred_3_targets_0); end
    checks++;
    if (g_io_out_s2_full_pred_3_targets_1 !== i_io_out_s2_full_pred_3_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_targets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_targets_1, i_io_out_s2_full_pred_3_targets_1); end
    checks++;
    if (g_io_out_s2_full_pred_3_jalr_target !== i_io_out_s2_full_pred_3_jalr_target) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_jalr_target g=%h i=%h", cycle, g_io_out_s2_full_pred_3_jalr_target, i_io_out_s2_full_pred_3_jalr_target); end
    checks++;
    if (g_io_out_s2_full_pred_3_offsets_0 !== i_io_out_s2_full_pred_3_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_offsets_0 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_offsets_0, i_io_out_s2_full_pred_3_offsets_0); end
    checks++;
    if (g_io_out_s2_full_pred_3_offsets_1 !== i_io_out_s2_full_pred_3_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_offsets_1 g=%h i=%h", cycle, g_io_out_s2_full_pred_3_offsets_1, i_io_out_s2_full_pred_3_offsets_1); end
    checks++;
    if (g_io_out_s2_full_pred_3_fallThroughAddr !== i_io_out_s2_full_pred_3_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_fallThroughAddr g=%h i=%h", cycle, g_io_out_s2_full_pred_3_fallThroughAddr, i_io_out_s2_full_pred_3_fallThroughAddr); end
    checks++;
    if (g_io_out_s2_full_pred_3_fallThroughErr !== i_io_out_s2_full_pred_3_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_fallThroughErr g=%h i=%h", cycle, g_io_out_s2_full_pred_3_fallThroughErr, i_io_out_s2_full_pred_3_fallThroughErr); end
    checks++;
    if (g_io_out_s2_full_pred_3_is_jal !== i_io_out_s2_full_pred_3_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_is_jal g=%h i=%h", cycle, g_io_out_s2_full_pred_3_is_jal, i_io_out_s2_full_pred_3_is_jal); end
    checks++;
    if (g_io_out_s2_full_pred_3_is_jalr !== i_io_out_s2_full_pred_3_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_is_jalr g=%h i=%h", cycle, g_io_out_s2_full_pred_3_is_jalr, i_io_out_s2_full_pred_3_is_jalr); end
    checks++;
    if (g_io_out_s2_full_pred_3_is_call !== i_io_out_s2_full_pred_3_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_is_call g=%h i=%h", cycle, g_io_out_s2_full_pred_3_is_call, i_io_out_s2_full_pred_3_is_call); end
    checks++;
    if (g_io_out_s2_full_pred_3_is_ret !== i_io_out_s2_full_pred_3_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_is_ret g=%h i=%h", cycle, g_io_out_s2_full_pred_3_is_ret, i_io_out_s2_full_pred_3_is_ret); end
    checks++;
    if (g_io_out_s2_full_pred_3_last_may_be_rvi_call !== i_io_out_s2_full_pred_3_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s2_full_pred_3_last_may_be_rvi_call, i_io_out_s2_full_pred_3_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s2_full_pred_3_is_br_sharing !== i_io_out_s2_full_pred_3_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_is_br_sharing g=%h i=%h", cycle, g_io_out_s2_full_pred_3_is_br_sharing, i_io_out_s2_full_pred_3_is_br_sharing); end
    checks++;
    if (g_io_out_s2_full_pred_3_hit !== i_io_out_s2_full_pred_3_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s2_full_pred_3_hit g=%h i=%h", cycle, g_io_out_s2_full_pred_3_hit, i_io_out_s2_full_pred_3_hit); end
    checks++;
    if (g_io_out_s3_full_pred_0_br_taken_mask_0 !== i_io_out_s3_full_pred_0_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_br_taken_mask_0, i_io_out_s3_full_pred_0_br_taken_mask_0); end
    checks++;
    if (g_io_out_s3_full_pred_0_br_taken_mask_1 !== i_io_out_s3_full_pred_0_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_br_taken_mask_1, i_io_out_s3_full_pred_0_br_taken_mask_1); end
    checks++;
    if (g_io_out_s3_full_pred_0_slot_valids_0 !== i_io_out_s3_full_pred_0_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_slot_valids_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_slot_valids_0, i_io_out_s3_full_pred_0_slot_valids_0); end
    checks++;
    if (g_io_out_s3_full_pred_0_slot_valids_1 !== i_io_out_s3_full_pred_0_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_slot_valids_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_slot_valids_1, i_io_out_s3_full_pred_0_slot_valids_1); end
    checks++;
    if (g_io_out_s3_full_pred_0_targets_0 !== i_io_out_s3_full_pred_0_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_targets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_targets_0, i_io_out_s3_full_pred_0_targets_0); end
    checks++;
    if (g_io_out_s3_full_pred_0_targets_1 !== i_io_out_s3_full_pred_0_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_targets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_targets_1, i_io_out_s3_full_pred_0_targets_1); end
    checks++;
    if (g_io_out_s3_full_pred_0_offsets_0 !== i_io_out_s3_full_pred_0_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_offsets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_offsets_0, i_io_out_s3_full_pred_0_offsets_0); end
    checks++;
    if (g_io_out_s3_full_pred_0_offsets_1 !== i_io_out_s3_full_pred_0_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_offsets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_0_offsets_1, i_io_out_s3_full_pred_0_offsets_1); end
    checks++;
    if (g_io_out_s3_full_pred_0_fallThroughAddr !== i_io_out_s3_full_pred_0_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_fallThroughAddr g=%h i=%h", cycle, g_io_out_s3_full_pred_0_fallThroughAddr, i_io_out_s3_full_pred_0_fallThroughAddr); end
    checks++;
    if (g_io_out_s3_full_pred_0_fallThroughErr !== i_io_out_s3_full_pred_0_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_fallThroughErr g=%h i=%h", cycle, g_io_out_s3_full_pred_0_fallThroughErr, i_io_out_s3_full_pred_0_fallThroughErr); end
    checks++;
    if (g_io_out_s3_full_pred_0_multiHit !== i_io_out_s3_full_pred_0_multiHit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_multiHit g=%h i=%h", cycle, g_io_out_s3_full_pred_0_multiHit, i_io_out_s3_full_pred_0_multiHit); end
    checks++;
    if (g_io_out_s3_full_pred_0_is_jal !== i_io_out_s3_full_pred_0_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_is_jal g=%h i=%h", cycle, g_io_out_s3_full_pred_0_is_jal, i_io_out_s3_full_pred_0_is_jal); end
    checks++;
    if (g_io_out_s3_full_pred_0_is_jalr !== i_io_out_s3_full_pred_0_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_is_jalr g=%h i=%h", cycle, g_io_out_s3_full_pred_0_is_jalr, i_io_out_s3_full_pred_0_is_jalr); end
    checks++;
    if (g_io_out_s3_full_pred_0_is_call !== i_io_out_s3_full_pred_0_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_is_call g=%h i=%h", cycle, g_io_out_s3_full_pred_0_is_call, i_io_out_s3_full_pred_0_is_call); end
    checks++;
    if (g_io_out_s3_full_pred_0_is_ret !== i_io_out_s3_full_pred_0_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_is_ret g=%h i=%h", cycle, g_io_out_s3_full_pred_0_is_ret, i_io_out_s3_full_pred_0_is_ret); end
    checks++;
    if (g_io_out_s3_full_pred_0_last_may_be_rvi_call !== i_io_out_s3_full_pred_0_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s3_full_pred_0_last_may_be_rvi_call, i_io_out_s3_full_pred_0_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s3_full_pred_0_is_br_sharing !== i_io_out_s3_full_pred_0_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_is_br_sharing g=%h i=%h", cycle, g_io_out_s3_full_pred_0_is_br_sharing, i_io_out_s3_full_pred_0_is_br_sharing); end
    checks++;
    if (g_io_out_s3_full_pred_0_hit !== i_io_out_s3_full_pred_0_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_0_hit g=%h i=%h", cycle, g_io_out_s3_full_pred_0_hit, i_io_out_s3_full_pred_0_hit); end
    checks++;
    if (g_io_out_s3_full_pred_1_br_taken_mask_0 !== i_io_out_s3_full_pred_1_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_br_taken_mask_0, i_io_out_s3_full_pred_1_br_taken_mask_0); end
    checks++;
    if (g_io_out_s3_full_pred_1_br_taken_mask_1 !== i_io_out_s3_full_pred_1_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_br_taken_mask_1, i_io_out_s3_full_pred_1_br_taken_mask_1); end
    checks++;
    if (g_io_out_s3_full_pred_1_slot_valids_0 !== i_io_out_s3_full_pred_1_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_slot_valids_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_slot_valids_0, i_io_out_s3_full_pred_1_slot_valids_0); end
    checks++;
    if (g_io_out_s3_full_pred_1_slot_valids_1 !== i_io_out_s3_full_pred_1_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_slot_valids_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_slot_valids_1, i_io_out_s3_full_pred_1_slot_valids_1); end
    checks++;
    if (g_io_out_s3_full_pred_1_targets_0 !== i_io_out_s3_full_pred_1_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_targets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_targets_0, i_io_out_s3_full_pred_1_targets_0); end
    checks++;
    if (g_io_out_s3_full_pred_1_targets_1 !== i_io_out_s3_full_pred_1_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_targets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_targets_1, i_io_out_s3_full_pred_1_targets_1); end
    checks++;
    if (g_io_out_s3_full_pred_1_offsets_0 !== i_io_out_s3_full_pred_1_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_offsets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_offsets_0, i_io_out_s3_full_pred_1_offsets_0); end
    checks++;
    if (g_io_out_s3_full_pred_1_offsets_1 !== i_io_out_s3_full_pred_1_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_offsets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_1_offsets_1, i_io_out_s3_full_pred_1_offsets_1); end
    checks++;
    if (g_io_out_s3_full_pred_1_fallThroughAddr !== i_io_out_s3_full_pred_1_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_fallThroughAddr g=%h i=%h", cycle, g_io_out_s3_full_pred_1_fallThroughAddr, i_io_out_s3_full_pred_1_fallThroughAddr); end
    checks++;
    if (g_io_out_s3_full_pred_1_fallThroughErr !== i_io_out_s3_full_pred_1_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_fallThroughErr g=%h i=%h", cycle, g_io_out_s3_full_pred_1_fallThroughErr, i_io_out_s3_full_pred_1_fallThroughErr); end
    checks++;
    if (g_io_out_s3_full_pred_1_multiHit !== i_io_out_s3_full_pred_1_multiHit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_multiHit g=%h i=%h", cycle, g_io_out_s3_full_pred_1_multiHit, i_io_out_s3_full_pred_1_multiHit); end
    checks++;
    if (g_io_out_s3_full_pred_1_is_jal !== i_io_out_s3_full_pred_1_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_is_jal g=%h i=%h", cycle, g_io_out_s3_full_pred_1_is_jal, i_io_out_s3_full_pred_1_is_jal); end
    checks++;
    if (g_io_out_s3_full_pred_1_is_jalr !== i_io_out_s3_full_pred_1_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_is_jalr g=%h i=%h", cycle, g_io_out_s3_full_pred_1_is_jalr, i_io_out_s3_full_pred_1_is_jalr); end
    checks++;
    if (g_io_out_s3_full_pred_1_is_call !== i_io_out_s3_full_pred_1_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_is_call g=%h i=%h", cycle, g_io_out_s3_full_pred_1_is_call, i_io_out_s3_full_pred_1_is_call); end
    checks++;
    if (g_io_out_s3_full_pred_1_is_ret !== i_io_out_s3_full_pred_1_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_is_ret g=%h i=%h", cycle, g_io_out_s3_full_pred_1_is_ret, i_io_out_s3_full_pred_1_is_ret); end
    checks++;
    if (g_io_out_s3_full_pred_1_last_may_be_rvi_call !== i_io_out_s3_full_pred_1_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s3_full_pred_1_last_may_be_rvi_call, i_io_out_s3_full_pred_1_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s3_full_pred_1_is_br_sharing !== i_io_out_s3_full_pred_1_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_is_br_sharing g=%h i=%h", cycle, g_io_out_s3_full_pred_1_is_br_sharing, i_io_out_s3_full_pred_1_is_br_sharing); end
    checks++;
    if (g_io_out_s3_full_pred_1_hit !== i_io_out_s3_full_pred_1_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_1_hit g=%h i=%h", cycle, g_io_out_s3_full_pred_1_hit, i_io_out_s3_full_pred_1_hit); end
    checks++;
    if (g_io_out_s3_full_pred_2_br_taken_mask_0 !== i_io_out_s3_full_pred_2_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_br_taken_mask_0, i_io_out_s3_full_pred_2_br_taken_mask_0); end
    checks++;
    if (g_io_out_s3_full_pred_2_br_taken_mask_1 !== i_io_out_s3_full_pred_2_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_br_taken_mask_1, i_io_out_s3_full_pred_2_br_taken_mask_1); end
    checks++;
    if (g_io_out_s3_full_pred_2_slot_valids_0 !== i_io_out_s3_full_pred_2_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_slot_valids_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_slot_valids_0, i_io_out_s3_full_pred_2_slot_valids_0); end
    checks++;
    if (g_io_out_s3_full_pred_2_slot_valids_1 !== i_io_out_s3_full_pred_2_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_slot_valids_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_slot_valids_1, i_io_out_s3_full_pred_2_slot_valids_1); end
    checks++;
    if (g_io_out_s3_full_pred_2_targets_0 !== i_io_out_s3_full_pred_2_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_targets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_targets_0, i_io_out_s3_full_pred_2_targets_0); end
    checks++;
    if (g_io_out_s3_full_pred_2_targets_1 !== i_io_out_s3_full_pred_2_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_targets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_targets_1, i_io_out_s3_full_pred_2_targets_1); end
    checks++;
    if (g_io_out_s3_full_pred_2_offsets_0 !== i_io_out_s3_full_pred_2_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_offsets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_offsets_0, i_io_out_s3_full_pred_2_offsets_0); end
    checks++;
    if (g_io_out_s3_full_pred_2_offsets_1 !== i_io_out_s3_full_pred_2_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_offsets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_2_offsets_1, i_io_out_s3_full_pred_2_offsets_1); end
    checks++;
    if (g_io_out_s3_full_pred_2_fallThroughAddr !== i_io_out_s3_full_pred_2_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_fallThroughAddr g=%h i=%h", cycle, g_io_out_s3_full_pred_2_fallThroughAddr, i_io_out_s3_full_pred_2_fallThroughAddr); end
    checks++;
    if (g_io_out_s3_full_pred_2_fallThroughErr !== i_io_out_s3_full_pred_2_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_fallThroughErr g=%h i=%h", cycle, g_io_out_s3_full_pred_2_fallThroughErr, i_io_out_s3_full_pred_2_fallThroughErr); end
    checks++;
    if (g_io_out_s3_full_pred_2_multiHit !== i_io_out_s3_full_pred_2_multiHit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_multiHit g=%h i=%h", cycle, g_io_out_s3_full_pred_2_multiHit, i_io_out_s3_full_pred_2_multiHit); end
    checks++;
    if (g_io_out_s3_full_pred_2_is_jal !== i_io_out_s3_full_pred_2_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_is_jal g=%h i=%h", cycle, g_io_out_s3_full_pred_2_is_jal, i_io_out_s3_full_pred_2_is_jal); end
    checks++;
    if (g_io_out_s3_full_pred_2_is_jalr !== i_io_out_s3_full_pred_2_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_is_jalr g=%h i=%h", cycle, g_io_out_s3_full_pred_2_is_jalr, i_io_out_s3_full_pred_2_is_jalr); end
    checks++;
    if (g_io_out_s3_full_pred_2_is_call !== i_io_out_s3_full_pred_2_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_is_call g=%h i=%h", cycle, g_io_out_s3_full_pred_2_is_call, i_io_out_s3_full_pred_2_is_call); end
    checks++;
    if (g_io_out_s3_full_pred_2_is_ret !== i_io_out_s3_full_pred_2_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_is_ret g=%h i=%h", cycle, g_io_out_s3_full_pred_2_is_ret, i_io_out_s3_full_pred_2_is_ret); end
    checks++;
    if (g_io_out_s3_full_pred_2_last_may_be_rvi_call !== i_io_out_s3_full_pred_2_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s3_full_pred_2_last_may_be_rvi_call, i_io_out_s3_full_pred_2_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s3_full_pred_2_is_br_sharing !== i_io_out_s3_full_pred_2_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_is_br_sharing g=%h i=%h", cycle, g_io_out_s3_full_pred_2_is_br_sharing, i_io_out_s3_full_pred_2_is_br_sharing); end
    checks++;
    if (g_io_out_s3_full_pred_2_hit !== i_io_out_s3_full_pred_2_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_2_hit g=%h i=%h", cycle, g_io_out_s3_full_pred_2_hit, i_io_out_s3_full_pred_2_hit); end
    checks++;
    if (g_io_out_s3_full_pred_3_br_taken_mask_0 !== i_io_out_s3_full_pred_3_br_taken_mask_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_br_taken_mask_0, i_io_out_s3_full_pred_3_br_taken_mask_0); end
    checks++;
    if (g_io_out_s3_full_pred_3_br_taken_mask_1 !== i_io_out_s3_full_pred_3_br_taken_mask_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_br_taken_mask_1, i_io_out_s3_full_pred_3_br_taken_mask_1); end
    checks++;
    if (g_io_out_s3_full_pred_3_slot_valids_0 !== i_io_out_s3_full_pred_3_slot_valids_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_slot_valids_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_slot_valids_0, i_io_out_s3_full_pred_3_slot_valids_0); end
    checks++;
    if (g_io_out_s3_full_pred_3_slot_valids_1 !== i_io_out_s3_full_pred_3_slot_valids_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_slot_valids_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_slot_valids_1, i_io_out_s3_full_pred_3_slot_valids_1); end
    checks++;
    if (g_io_out_s3_full_pred_3_targets_0 !== i_io_out_s3_full_pred_3_targets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_targets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_targets_0, i_io_out_s3_full_pred_3_targets_0); end
    checks++;
    if (g_io_out_s3_full_pred_3_targets_1 !== i_io_out_s3_full_pred_3_targets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_targets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_targets_1, i_io_out_s3_full_pred_3_targets_1); end
    checks++;
    if (g_io_out_s3_full_pred_3_offsets_0 !== i_io_out_s3_full_pred_3_offsets_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_offsets_0 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_offsets_0, i_io_out_s3_full_pred_3_offsets_0); end
    checks++;
    if (g_io_out_s3_full_pred_3_offsets_1 !== i_io_out_s3_full_pred_3_offsets_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_offsets_1 g=%h i=%h", cycle, g_io_out_s3_full_pred_3_offsets_1, i_io_out_s3_full_pred_3_offsets_1); end
    checks++;
    if (g_io_out_s3_full_pred_3_fallThroughAddr !== i_io_out_s3_full_pred_3_fallThroughAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_fallThroughAddr g=%h i=%h", cycle, g_io_out_s3_full_pred_3_fallThroughAddr, i_io_out_s3_full_pred_3_fallThroughAddr); end
    checks++;
    if (g_io_out_s3_full_pred_3_fallThroughErr !== i_io_out_s3_full_pred_3_fallThroughErr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_fallThroughErr g=%h i=%h", cycle, g_io_out_s3_full_pred_3_fallThroughErr, i_io_out_s3_full_pred_3_fallThroughErr); end
    checks++;
    if (g_io_out_s3_full_pred_3_multiHit !== i_io_out_s3_full_pred_3_multiHit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_multiHit g=%h i=%h", cycle, g_io_out_s3_full_pred_3_multiHit, i_io_out_s3_full_pred_3_multiHit); end
    checks++;
    if (g_io_out_s3_full_pred_3_is_jal !== i_io_out_s3_full_pred_3_is_jal) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_is_jal g=%h i=%h", cycle, g_io_out_s3_full_pred_3_is_jal, i_io_out_s3_full_pred_3_is_jal); end
    checks++;
    if (g_io_out_s3_full_pred_3_is_jalr !== i_io_out_s3_full_pred_3_is_jalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_is_jalr g=%h i=%h", cycle, g_io_out_s3_full_pred_3_is_jalr, i_io_out_s3_full_pred_3_is_jalr); end
    checks++;
    if (g_io_out_s3_full_pred_3_is_call !== i_io_out_s3_full_pred_3_is_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_is_call g=%h i=%h", cycle, g_io_out_s3_full_pred_3_is_call, i_io_out_s3_full_pred_3_is_call); end
    checks++;
    if (g_io_out_s3_full_pred_3_is_ret !== i_io_out_s3_full_pred_3_is_ret) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_is_ret g=%h i=%h", cycle, g_io_out_s3_full_pred_3_is_ret, i_io_out_s3_full_pred_3_is_ret); end
    checks++;
    if (g_io_out_s3_full_pred_3_last_may_be_rvi_call !== i_io_out_s3_full_pred_3_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_s3_full_pred_3_last_may_be_rvi_call, i_io_out_s3_full_pred_3_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_s3_full_pred_3_is_br_sharing !== i_io_out_s3_full_pred_3_is_br_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_is_br_sharing g=%h i=%h", cycle, g_io_out_s3_full_pred_3_is_br_sharing, i_io_out_s3_full_pred_3_is_br_sharing); end
    checks++;
    if (g_io_out_s3_full_pred_3_hit !== i_io_out_s3_full_pred_3_hit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s3_full_pred_3_hit g=%h i=%h", cycle, g_io_out_s3_full_pred_3_hit, i_io_out_s3_full_pred_3_hit); end
    checks++;
    if (g_io_out_s1_uftbHit !== i_io_out_s1_uftbHit) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s1_uftbHit g=%h i=%h", cycle, g_io_out_s1_uftbHit, i_io_out_s1_uftbHit); end
    checks++;
    if (g_io_out_s1_uftbHasIndirect !== i_io_out_s1_uftbHasIndirect) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s1_uftbHasIndirect g=%h i=%h", cycle, g_io_out_s1_uftbHasIndirect, i_io_out_s1_uftbHasIndirect); end
    checks++;
    if (g_io_out_s1_ftbCloseReq !== i_io_out_s1_ftbCloseReq) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_s1_ftbCloseReq g=%h i=%h", cycle, g_io_out_s1_ftbCloseReq, i_io_out_s1_ftbCloseReq); end
    checks++;
    if (g_io_out_last_stage_meta !== i_io_out_last_stage_meta) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_meta g=%h i=%h", cycle, g_io_out_last_stage_meta, i_io_out_last_stage_meta); end
    checks++;
    if (g_io_out_last_stage_spec_info_sc_disagree_0 !== i_io_out_last_stage_spec_info_sc_disagree_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_spec_info_sc_disagree_0 g=%h i=%h", cycle, g_io_out_last_stage_spec_info_sc_disagree_0, i_io_out_last_stage_spec_info_sc_disagree_0); end
    checks++;
    if (g_io_out_last_stage_spec_info_sc_disagree_1 !== i_io_out_last_stage_spec_info_sc_disagree_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_spec_info_sc_disagree_1 g=%h i=%h", cycle, g_io_out_last_stage_spec_info_sc_disagree_1, i_io_out_last_stage_spec_info_sc_disagree_1); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_isCall !== i_io_out_last_stage_ftb_entry_isCall) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_isCall g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_isCall, i_io_out_last_stage_ftb_entry_isCall); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_isRet !== i_io_out_last_stage_ftb_entry_isRet) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_isRet g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_isRet, i_io_out_last_stage_ftb_entry_isRet); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_isJalr !== i_io_out_last_stage_ftb_entry_isJalr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_isJalr g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_isJalr, i_io_out_last_stage_ftb_entry_isJalr); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_valid !== i_io_out_last_stage_ftb_entry_valid) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_valid g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_valid, i_io_out_last_stage_ftb_entry_valid); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_brSlots_0_offset !== i_io_out_last_stage_ftb_entry_brSlots_0_offset) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_brSlots_0_offset g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_brSlots_0_offset, i_io_out_last_stage_ftb_entry_brSlots_0_offset); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_brSlots_0_sharing !== i_io_out_last_stage_ftb_entry_brSlots_0_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_brSlots_0_sharing g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_brSlots_0_sharing, i_io_out_last_stage_ftb_entry_brSlots_0_sharing); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_brSlots_0_valid !== i_io_out_last_stage_ftb_entry_brSlots_0_valid) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_brSlots_0_valid g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_brSlots_0_valid, i_io_out_last_stage_ftb_entry_brSlots_0_valid); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_brSlots_0_lower !== i_io_out_last_stage_ftb_entry_brSlots_0_lower) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_brSlots_0_lower g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_brSlots_0_lower, i_io_out_last_stage_ftb_entry_brSlots_0_lower); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_brSlots_0_tarStat !== i_io_out_last_stage_ftb_entry_brSlots_0_tarStat) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_brSlots_0_tarStat g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_brSlots_0_tarStat, i_io_out_last_stage_ftb_entry_brSlots_0_tarStat); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_tailSlot_offset !== i_io_out_last_stage_ftb_entry_tailSlot_offset) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_tailSlot_offset g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_tailSlot_offset, i_io_out_last_stage_ftb_entry_tailSlot_offset); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_tailSlot_sharing !== i_io_out_last_stage_ftb_entry_tailSlot_sharing) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_tailSlot_sharing g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_tailSlot_sharing, i_io_out_last_stage_ftb_entry_tailSlot_sharing); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_tailSlot_valid !== i_io_out_last_stage_ftb_entry_tailSlot_valid) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_tailSlot_valid g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_tailSlot_valid, i_io_out_last_stage_ftb_entry_tailSlot_valid); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_tailSlot_lower !== i_io_out_last_stage_ftb_entry_tailSlot_lower) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_tailSlot_lower g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_tailSlot_lower, i_io_out_last_stage_ftb_entry_tailSlot_lower); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_tailSlot_tarStat !== i_io_out_last_stage_ftb_entry_tailSlot_tarStat) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_tailSlot_tarStat g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_tailSlot_tarStat, i_io_out_last_stage_ftb_entry_tailSlot_tarStat); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_pftAddr !== i_io_out_last_stage_ftb_entry_pftAddr) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_pftAddr g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_pftAddr, i_io_out_last_stage_ftb_entry_pftAddr); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_carry !== i_io_out_last_stage_ftb_entry_carry) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_carry g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_carry, i_io_out_last_stage_ftb_entry_carry); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_last_may_be_rvi_call !== i_io_out_last_stage_ftb_entry_last_may_be_rvi_call) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_last_may_be_rvi_call g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_last_may_be_rvi_call, i_io_out_last_stage_ftb_entry_last_may_be_rvi_call); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_strong_bias_0 !== i_io_out_last_stage_ftb_entry_strong_bias_0) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_strong_bias_0 g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_strong_bias_0, i_io_out_last_stage_ftb_entry_strong_bias_0); end
    checks++;
    if (g_io_out_last_stage_ftb_entry_strong_bias_1 !== i_io_out_last_stage_ftb_entry_strong_bias_1) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_out_last_stage_ftb_entry_strong_bias_1 g=%h i=%h", cycle, g_io_out_last_stage_ftb_entry_strong_bias_1, i_io_out_last_stage_ftb_entry_strong_bias_1); end
    checks++;
    if (g_io_s1_ready !== i_io_s1_ready) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_s1_ready g=%h i=%h", cycle, g_io_s1_ready, i_io_s1_ready); end
    checks++;
    if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_perf_0_value g=%h i=%h", cycle, g_io_perf_0_value, i_io_perf_0_value); end
    checks++;
    if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH io_perf_1_value g=%h i=%h", cycle, g_io_perf_1_value, i_io_perf_1_value); end
    checks++;
    if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH boreChildrenBd_bore_ack g=%h i=%h", cycle, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end
    checks++;
    if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++; if (errors <= 20) $display("[%0d] MISMATCH boreChildrenBd_bore_outdata g=%h i=%h", cycle, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end
  endtask

  // ========================================================================
  // 激励
  // ========================================================================
  logic [49:0] pc_pool [64];
  int unsigned phase_left = 0;
  int unsigned phase      = 0;     // 0 = 一致期（uFTB 条目 = golden bank 读出），1 = 随机期
  // 覆盖计数（读 golden 内部线，只统计不参与判定）
  int unsigned cov_s2_hit, cov_multi, cov_close, cov_reopen, cov_upd_now, cov_upd_read,
               cov_write, cov_fterr, cov_cnt_max, cov_s3_hit, cov_cnt_peak, cov_both_hit;

  function automatic logic [49:0] pick_pc();
    return pc_pool[$urandom_range(63)];
  endfunction

  task automatic drive_entry_rand(output logic isCall, isRet, isJalr, valid,
      output logic [3:0] broff, output logic brsh, brv, output logic [11:0] brlo,
      output logic [1:0] brts, output logic [3:0] tloff, output logic tlsh, tlv,
      output logic [19:0] tllo, output logic [1:0] tlts, output logic [3:0] pft,
      output logic carry, lastrvi, sb0, sb1);
    isCall = $urandom; isRet = $urandom; isJalr = $urandom; valid = ($urandom_range(7) != 0);
    broff = $urandom; brsh = $urandom; brv = $urandom; brlo = $urandom; brts = $urandom;
    tloff = $urandom; tlsh = $urandom; tlv = $urandom; tllo = $urandom; tlts = $urandom;
    pft = $urandom; carry = $urandom; lastrvi = $urandom; sb0 = $urandom; sb1 = $urandom;
  endtask

  task automatic copy_bank_to_fau();
      io_fauftb_entry_in_isCall               = u_g.ftbBank.io_read_resp_isCall;
      io_fauftb_entry_in_isRet                = u_g.ftbBank.io_read_resp_isRet;
      io_fauftb_entry_in_isJalr               = u_g.ftbBank.io_read_resp_isJalr;
      io_fauftb_entry_in_valid                = u_g.ftbBank.io_read_resp_valid;
      io_fauftb_entry_in_brSlots_0_offset     = u_g.ftbBank.io_read_resp_brSlots_0_offset;
      io_fauftb_entry_in_brSlots_0_sharing    = u_g.ftbBank.io_read_resp_brSlots_0_sharing;
      io_fauftb_entry_in_brSlots_0_valid      = u_g.ftbBank.io_read_resp_brSlots_0_valid;
      io_fauftb_entry_in_brSlots_0_lower      = u_g.ftbBank.io_read_resp_brSlots_0_lower;
      io_fauftb_entry_in_brSlots_0_tarStat    = u_g.ftbBank.io_read_resp_brSlots_0_tarStat;
      io_fauftb_entry_in_tailSlot_offset      = u_g.ftbBank.io_read_resp_tailSlot_offset;
      io_fauftb_entry_in_tailSlot_sharing     = u_g.ftbBank.io_read_resp_tailSlot_sharing;
      io_fauftb_entry_in_tailSlot_valid       = u_g.ftbBank.io_read_resp_tailSlot_valid;
      io_fauftb_entry_in_tailSlot_lower       = u_g.ftbBank.io_read_resp_tailSlot_lower;
      io_fauftb_entry_in_tailSlot_tarStat     = u_g.ftbBank.io_read_resp_tailSlot_tarStat;
      io_fauftb_entry_in_pftAddr              = u_g.ftbBank.io_read_resp_pftAddr;
      io_fauftb_entry_in_carry                = u_g.ftbBank.io_read_resp_carry;
      io_fauftb_entry_in_last_may_be_rvi_call = u_g.ftbBank.io_read_resp_last_may_be_rvi_call;
      io_fauftb_entry_in_strong_bias_0        = u_g.ftbBank.io_read_resp_strong_bias_0;
      io_fauftb_entry_in_strong_bias_1        = u_g.ftbBank.io_read_resp_strong_bias_1;
      io_fauftb_entry_hit_in                  = u_g.ftbBank.io_read_hits_valid | ($urandom_range(63) == 0);
      if ($urandom_range(8191) == 0) io_fauftb_entry_in_pftAddr = $urandom;  // 偶发不一致
  endtask

  task automatic drive_inputs();
    logic f;
    // ---- 阶段切换 ----
    if (phase_left == 0) begin
      phase      = ($urandom_range(7) == 0) ? 1 : 0;
      phase_left = $urandom_range(3000, 200);
    end
    phase_left--;
    // ---- PC / fire ----
    io_in_bits_s0_pc_0 = pick_pc();
    io_in_bits_s0_pc_1 = ($urandom_range(15) == 0) ? pick_pc() : io_in_bits_s0_pc_0;
    io_in_bits_s0_pc_2 = ($urandom_range(15) == 0) ? pick_pc() : io_in_bits_s0_pc_0;
    io_in_bits_s0_pc_3 = ($urandom_range(15) == 0) ? pick_pc() : io_in_bits_s0_pc_0;
    f = ($urandom_range(3) != 0) && g_io_s1_ready;
    io_s0_fire_0 = f;
    io_s0_fire_1 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s0_fire_2 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s0_fire_3 = ($urandom_range(15) == 0) ? $urandom : f;
    f = ($urandom_range(3) != 0);
    io_s1_fire_0 = f;
    io_s1_fire_1 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s1_fire_2 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s1_fire_3 = ($urandom_range(15) == 0) ? $urandom : f;
    f = ($urandom_range(3) != 0);
    io_s2_fire_0 = f;
    io_s2_fire_1 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s2_fire_2 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s2_fire_3 = ($urandom_range(15) == 0) ? $urandom : f;
    io_s3_fire_0 = $urandom;
    {io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
     io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
     io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
     io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0, io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
     io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0, io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
     io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
     io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1} = $urandom;
    io_ctrl_btb_enable = (phase == 0) || ($urandom_range(31) != 0);
    // ---- uFTB 条目 ----
    if (phase == 0) begin
      copy_bank_to_fau();   // 先给个值；主循环在其它输入稳定后再抄一遍
    end else begin
      drive_entry_rand(io_fauftb_entry_in_isCall, io_fauftb_entry_in_isRet, io_fauftb_entry_in_isJalr,
        io_fauftb_entry_in_valid, io_fauftb_entry_in_brSlots_0_offset, io_fauftb_entry_in_brSlots_0_sharing,
        io_fauftb_entry_in_brSlots_0_valid, io_fauftb_entry_in_brSlots_0_lower,
        io_fauftb_entry_in_brSlots_0_tarStat, io_fauftb_entry_in_tailSlot_offset,
        io_fauftb_entry_in_tailSlot_sharing, io_fauftb_entry_in_tailSlot_valid,
        io_fauftb_entry_in_tailSlot_lower, io_fauftb_entry_in_tailSlot_tarStat, io_fauftb_entry_in_pftAddr,
        io_fauftb_entry_in_carry, io_fauftb_entry_in_last_may_be_rvi_call, io_fauftb_entry_in_strong_bias_0,
        io_fauftb_entry_in_strong_bias_1);
      io_fauftb_entry_hit_in = $urandom;
    end
    // ---- update ----
    io_update_valid          = ($urandom_range(3) == 0);
    io_update_bits_pc        = pick_pc();
    drive_entry_rand(io_update_bits_ftb_entry_isCall, io_update_bits_ftb_entry_isRet,
      io_update_bits_ftb_entry_isJalr, io_update_bits_ftb_entry_valid,
      io_update_bits_ftb_entry_brSlots_0_offset, io_update_bits_ftb_entry_brSlots_0_sharing,
      io_update_bits_ftb_entry_brSlots_0_valid, io_update_bits_ftb_entry_brSlots_0_lower,
      io_update_bits_ftb_entry_brSlots_0_tarStat, io_update_bits_ftb_entry_tailSlot_offset,
      io_update_bits_ftb_entry_tailSlot_sharing, io_update_bits_ftb_entry_tailSlot_valid,
      io_update_bits_ftb_entry_tailSlot_lower, io_update_bits_ftb_entry_tailSlot_tarStat,
      io_update_bits_ftb_entry_pftAddr, io_update_bits_ftb_entry_carry,
      io_update_bits_ftb_entry_last_may_be_rvi_call, io_update_bits_ftb_entry_strong_bias_0,
      io_update_bits_ftb_entry_strong_bias_1);
    io_update_bits_false_hit = ($urandom_range(63) == 0);
    io_update_bits_old_entry = ($urandom_range(7) == 0);
    for (int k = 0; k < 516; k += 32) io_update_bits_meta[k +: 32] = $urandom;
    io_redirectFromIFU       = ($urandom_range(1023) == 0);
    // ---- MBIST / SRAM 旁带：功能模式下保持静默 ----
    boreChildrenBd_bore_array   = '0;  boreChildrenBd_bore_all     = 1'b0;
    boreChildrenBd_bore_req     = 1'b0; boreChildrenBd_bore_writeen = 1'b0;
    boreChildrenBd_bore_be      = '0;  boreChildrenBd_bore_addr    = '0;
    boreChildrenBd_bore_indata  = '0;  boreChildrenBd_bore_readen  = 1'b0;
    boreChildrenBd_bore_addr_rd = '0;
  endtask

  initial begin
    logic [49:0] base;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    base = {$urandom, $urandom} & 50'h3_ffff_ffff_f000;
    for (int k = 0; k < 64; k++)
      // 64 个 PC：同一 4KB 区内，块内偏移随机（覆盖 fall-through 合法/非法两种）
      pc_pool[k] = base | 50'($urandom_range(4095) & ~1);
    io_reset_vector = {$urandom, $urandom};
    // sigFromSrams_*：功能模式全 0
    {sigFromSrams_bore_ram_hold, sigFromSrams_bore_ram_bypass, sigFromSrams_bore_ram_bp_clken,
     sigFromSrams_bore_ram_aux_clk, sigFromSrams_bore_ram_aux_ckbp, sigFromSrams_bore_ram_mcp_hold,
     sigFromSrams_bore_cgen} = '0;
    {sigFromSrams_bore_1_ram_hold, sigFromSrams_bore_1_ram_bypass, sigFromSrams_bore_1_ram_bp_clken,
     sigFromSrams_bore_1_ram_aux_clk, sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_mcp_hold,
     sigFromSrams_bore_1_cgen} = '0;
    {sigFromSrams_bore_2_ram_hold, sigFromSrams_bore_2_ram_bypass, sigFromSrams_bore_2_ram_bp_clken,
     sigFromSrams_bore_2_ram_aux_clk, sigFromSrams_bore_2_ram_aux_ckbp, sigFromSrams_bore_2_ram_mcp_hold,
     sigFromSrams_bore_2_cgen} = '0;
    {sigFromSrams_bore_3_ram_hold, sigFromSrams_bore_3_ram_bypass, sigFromSrams_bore_3_ram_bp_clken,
     sigFromSrams_bore_3_ram_aux_clk, sigFromSrams_bore_3_ram_aux_ckbp, sigFromSrams_bore_3_ram_mcp_hold,
     sigFromSrams_bore_3_cgen} = '0;
    {sigFromSrams_bore_4_ram_hold, sigFromSrams_bore_4_ram_bypass, sigFromSrams_bore_4_ram_bp_clken,
     sigFromSrams_bore_4_ram_aux_clk, sigFromSrams_bore_4_ram_aux_ckbp, sigFromSrams_bore_4_ram_mcp_hold,
     sigFromSrams_bore_4_cgen} = '0;
    {sigFromSrams_bore_5_ram_hold, sigFromSrams_bore_5_ram_bypass, sigFromSrams_bore_5_ram_bp_clken,
     sigFromSrams_bore_5_ram_aux_clk, sigFromSrams_bore_5_ram_aux_ckbp, sigFromSrams_bore_5_ram_mcp_hold,
     sigFromSrams_bore_5_cgen} = '0;
    {sigFromSrams_bore_6_ram_hold, sigFromSrams_bore_6_ram_bypass, sigFromSrams_bore_6_ram_bp_clken,
     sigFromSrams_bore_6_ram_aux_clk, sigFromSrams_bore_6_ram_aux_ckbp, sigFromSrams_bore_6_ram_mcp_hold,
     sigFromSrams_bore_6_cgen} = '0;
    {sigFromSrams_bore_7_ram_hold, sigFromSrams_bore_7_ram_bypass, sigFromSrams_bore_7_ram_bp_clken,
     sigFromSrams_bore_7_ram_aux_clk, sigFromSrams_bore_7_ram_aux_ckbp, sigFromSrams_bore_7_ram_mcp_hold,
     sigFromSrams_bore_7_cgen} = '0;
    reset = 1'b1;
    drive_inputs();
    io_s0_fire_0 = 0; io_s0_fire_1 = 0; io_s0_fire_2 = 0; io_s0_fire_3 = 0;
    io_update_valid = 0;
    repeat (5) @(negedge clock);
    reset = 1'b0;
    while (cycle < NCYCLES) begin
      @(negedge clock);
      drive_inputs();
      #1;
      // bank 读出可能组合依赖本拍刚给的 fire：等其它输入稳定后再把它抄给 uFTB 输入
      if (phase == 0) copy_bank_to_fau();
      #1;
      if (cycle >= WARMUP) compare();
      // 覆盖
      if (u_g.s2_hit_dup_0 && io_s2_fire_0)          cov_s2_hit++;
      if (u_g.s3_hit_dup_0)                          cov_s3_hit++;
      if (u_g.s2_multi_hit_enable_probe)             cov_multi++;
      if (u_g.s2_close_ftb_req && io_s2_fire_0)      cov_close++;
      if (u_g.needReopen)                            cov_reopen++;
      if (u_g.update_now)                            cov_upd_now++;
      if (u_g.update_need_read)                      cov_upd_read++;
      if (u_g.write_valid)                           cov_write++;
      if (u_g.io_out_s2_full_pred_0_fallThroughErr_0) cov_fterr++;
      if (u_g.fauftb_ftb_entry_consistent_counter > 9'd499) cov_cnt_max++;
      if (u_g.fauftb_ftb_entry_consistent_counter > cov_cnt_peak) cov_cnt_peak = u_g.fauftb_ftb_entry_consistent_counter;
      if (io_s2_fire_0 && u_g.s2_fauftb_ftb_entry_hit_dup_0 && u_g.s2_ftb_hit_dup_0) cov_both_hit++;
      cycle++;
    end
    $display("COVERAGE s2_hit=%0d s3_hit=%0d multi_hit_enable=%0d s2_closed=%0d reopen=%0d update_now=%0d update_need_read=%0d write=%0d s2_ft_err=%0d cnt_over_499=%0d cnt_peak=%0d both_hit_s2fire=%0d",
             cov_s2_hit, cov_s3_hit, cov_multi, cov_close, cov_reopen, cov_upd_now, cov_upd_read,
             cov_write, cov_fterr, cov_cnt_max, cov_cnt_peak, cov_both_hit);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end
endmodule
