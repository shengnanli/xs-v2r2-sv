// 自动生成：scripts/gen_tagesc.py —— 勿手改
module Tage_SC(
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
  input  [255:0] io_in_bits_ghist,
  output io_out_s2_full_pred_0_br_taken_mask_0,
  output io_out_s2_full_pred_0_br_taken_mask_1,
  output io_out_s2_full_pred_1_br_taken_mask_0,
  output io_out_s2_full_pred_1_br_taken_mask_1,
  output io_out_s2_full_pred_2_br_taken_mask_0,
  output io_out_s2_full_pred_2_br_taken_mask_1,
  output io_out_s2_full_pred_3_br_taken_mask_0,
  output io_out_s2_full_pred_3_br_taken_mask_1,
  output io_out_s3_full_pred_0_br_taken_mask_0,
  output io_out_s3_full_pred_0_br_taken_mask_1,
  output io_out_s3_full_pred_1_br_taken_mask_0,
  output io_out_s3_full_pred_1_br_taken_mask_1,
  output io_out_s3_full_pred_2_br_taken_mask_0,
  output io_out_s3_full_pred_2_br_taken_mask_1,
  output io_out_s3_full_pred_3_br_taken_mask_0,
  output io_out_s3_full_pred_3_br_taken_mask_1,
  output [515:0] io_out_last_stage_meta,
  output io_out_last_stage_spec_info_sc_disagree_0,
  output io_out_last_stage_spec_info_sc_disagree_1,
  input  io_ctrl_tage_enable,
  input  io_ctrl_sc_enable,
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
  input  io_update_bits_ftb_entry_brSlots_0_valid,
  input  io_update_bits_ftb_entry_tailSlot_sharing,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  io_update_bits_ftb_entry_strong_bias_0,
  input  io_update_bits_ftb_entry_strong_bias_1,
  input  io_update_bits_br_taken_mask_0,
  input  io_update_bits_br_taken_mask_1,
  input  io_update_bits_mispred_mask_0,
  input  io_update_bits_mispred_mask_1,
  input  [515:0] io_update_bits_meta,
  input  [255:0] io_update_bits_ghist,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [15:0] boreChildrenBd_bore_be,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [23:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  output [23:0] boreChildrenBd_bore_outdata,
  input  [6:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [3:0] boreChildrenBd_bore_1_be,
  input  [8:0] boreChildrenBd_bore_1_addr,
  input  [23:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [8:0] boreChildrenBd_bore_1_addr_rd,
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
  input  sigFromSrams_bore_25_cgen
);

  // ===== 核 ↔ 子模块功能 wire =====
  wire core_tbl_req_valid; wire [49:0] core_tbl_req_pc;
  wire core_bt_req_valid;  wire [49:0] core_bt_req_pc;
  wire core_sc_req_valid;  wire [49:0] core_sc_req_pc;
  wire t0_req_ready;
  wire t0_resp_valid_0; wire [2:0] t0_resp_ctr_0; wire t0_resp_u_0; wire t0_resp_unconf_0;
  wire t0_resp_valid_1; wire [2:0] t0_resp_ctr_1; wire t0_resp_u_1; wire t0_resp_unconf_1;
  wire [49:0] t0_upd_pc; wire [255:0] t0_upd_ghist;
  wire t0_upd_mask_0, t0_upd_takens_0, t0_upd_alloc_0, t0_upd_uMask_0, t0_upd_us_0, t0_upd_reset_u_0; wire [2:0] t0_upd_oldCtrs_0;
  wire t0_upd_mask_1, t0_upd_takens_1, t0_upd_alloc_1, t0_upd_uMask_1, t0_upd_us_1, t0_upd_reset_u_1; wire [2:0] t0_upd_oldCtrs_1;
  wire t1_req_ready;
  wire t1_resp_valid_0; wire [2:0] t1_resp_ctr_0; wire t1_resp_u_0; wire t1_resp_unconf_0;
  wire t1_resp_valid_1; wire [2:0] t1_resp_ctr_1; wire t1_resp_u_1; wire t1_resp_unconf_1;
  wire [49:0] t1_upd_pc; wire [255:0] t1_upd_ghist;
  wire t1_upd_mask_0, t1_upd_takens_0, t1_upd_alloc_0, t1_upd_uMask_0, t1_upd_us_0, t1_upd_reset_u_0; wire [2:0] t1_upd_oldCtrs_0;
  wire t1_upd_mask_1, t1_upd_takens_1, t1_upd_alloc_1, t1_upd_uMask_1, t1_upd_us_1, t1_upd_reset_u_1; wire [2:0] t1_upd_oldCtrs_1;
  wire t2_req_ready;
  wire t2_resp_valid_0; wire [2:0] t2_resp_ctr_0; wire t2_resp_u_0; wire t2_resp_unconf_0;
  wire t2_resp_valid_1; wire [2:0] t2_resp_ctr_1; wire t2_resp_u_1; wire t2_resp_unconf_1;
  wire [49:0] t2_upd_pc; wire [255:0] t2_upd_ghist;
  wire t2_upd_mask_0, t2_upd_takens_0, t2_upd_alloc_0, t2_upd_uMask_0, t2_upd_us_0, t2_upd_reset_u_0; wire [2:0] t2_upd_oldCtrs_0;
  wire t2_upd_mask_1, t2_upd_takens_1, t2_upd_alloc_1, t2_upd_uMask_1, t2_upd_us_1, t2_upd_reset_u_1; wire [2:0] t2_upd_oldCtrs_1;
  wire t3_req_ready;
  wire t3_resp_valid_0; wire [2:0] t3_resp_ctr_0; wire t3_resp_u_0; wire t3_resp_unconf_0;
  wire t3_resp_valid_1; wire [2:0] t3_resp_ctr_1; wire t3_resp_u_1; wire t3_resp_unconf_1;
  wire [49:0] t3_upd_pc; wire [255:0] t3_upd_ghist;
  wire t3_upd_mask_0, t3_upd_takens_0, t3_upd_alloc_0, t3_upd_uMask_0, t3_upd_us_0, t3_upd_reset_u_0; wire [2:0] t3_upd_oldCtrs_0;
  wire t3_upd_mask_1, t3_upd_takens_1, t3_upd_alloc_1, t3_upd_uMask_1, t3_upd_us_1, t3_upd_reset_u_1; wire [2:0] t3_upd_oldCtrs_1;
  wire bt_req_ready;
  wire [1:0] bt_s1_cnt_0; wire bt_upd_mask_0, bt_upd_takens_0; wire [1:0] bt_upd_cnt_0;
  wire [1:0] bt_s1_cnt_1; wire bt_upd_mask_1, bt_upd_takens_1; wire [1:0] bt_upd_cnt_1;
  wire [49:0] bt_upd_pc;
  wire [5:0] sc0_resp_00;
  wire [5:0] sc0_resp_01;
  wire [5:0] sc0_resp_10;
  wire [5:0] sc0_resp_11;
  wire [49:0] sc0_upd_pc; wire [255:0] sc0_upd_ghist;
  wire sc0_upd_mask_0, sc0_upd_tagePreds_0, sc0_upd_takens_0; wire [5:0] sc0_upd_oldCtrs_0;
  wire sc0_upd_mask_1, sc0_upd_tagePreds_1, sc0_upd_takens_1; wire [5:0] sc0_upd_oldCtrs_1;
  wire [5:0] sc1_resp_00;
  wire [5:0] sc1_resp_01;
  wire [5:0] sc1_resp_10;
  wire [5:0] sc1_resp_11;
  wire [49:0] sc1_upd_pc; wire [255:0] sc1_upd_ghist;
  wire sc1_upd_mask_0, sc1_upd_tagePreds_0, sc1_upd_takens_0; wire [5:0] sc1_upd_oldCtrs_0;
  wire sc1_upd_mask_1, sc1_upd_tagePreds_1, sc1_upd_takens_1; wire [5:0] sc1_upd_oldCtrs_1;
  wire [5:0] sc2_resp_00;
  wire [5:0] sc2_resp_01;
  wire [5:0] sc2_resp_10;
  wire [5:0] sc2_resp_11;
  wire [49:0] sc2_upd_pc; wire [255:0] sc2_upd_ghist;
  wire sc2_upd_mask_0, sc2_upd_tagePreds_0, sc2_upd_takens_0; wire [5:0] sc2_upd_oldCtrs_0;
  wire sc2_upd_mask_1, sc2_upd_tagePreds_1, sc2_upd_takens_1; wire [5:0] sc2_upd_oldCtrs_1;
  wire [5:0] sc3_resp_00;
  wire [5:0] sc3_resp_01;
  wire [5:0] sc3_resp_10;
  wire [5:0] sc3_resp_11;
  wire [49:0] sc3_upd_pc; wire [255:0] sc3_upd_ghist;
  wire sc3_upd_mask_0, sc3_upd_tagePreds_0, sc3_upd_takens_0; wire [5:0] sc3_upd_oldCtrs_0;
  wire sc3_upd_mask_1, sc3_upd_tagePreds_1, sc3_upd_takens_1; wire [5:0] sc3_upd_oldCtrs_1;
  wire lfsr0_out_0;
  wire lfsr0_out_1;
  wire lfsr0_out_2;
  wire lfsr0_out_3;
  wire lfsr1_out_0;
  wire lfsr1_out_1;
  wire lfsr1_out_2;
  wire lfsr1_out_3;
  wire core_s2_taken_0_0, core_s3_taken_0_0;
  wire core_s2_taken_0_1, core_s3_taken_0_1;
  wire core_s2_taken_1_0, core_s3_taken_1_0;
  wire core_s2_taken_1_1, core_s3_taken_1_1;
  wire core_s2_taken_2_0, core_s3_taken_2_0;
  wire core_s2_taken_2_1, core_s3_taken_2_1;
  wire core_s2_taken_3_0, core_s3_taken_3_0;
  wire core_s2_taken_3_1, core_s3_taken_3_1;
  wire core_s1_ready; wire [515:0] core_meta;
  wire core_sc_disagree_0, core_sc_disagree_1;

  // ===== DFT/MBIST 基础设施（逐字抽取自 golden Tage_SC，机械适配）=====
  wire [23:0]  bd_outdata;
  wire         bd_ack;
  wire [15:0]  childBd_21_rdata;
  wire [15:0]  childBd_20_rdata;
  wire [23:0]  childBd_19_rdata;
  wire [23:0]  childBd_18_rdata;
  wire [23:0]  childBd_17_rdata;
  wire [23:0]  childBd_16_rdata;
  wire [15:0]  childBd_15_rdata;
  wire [23:0]  childBd_14_rdata;
  wire [23:0]  childBd_13_rdata;
  wire [23:0]  childBd_12_rdata;
  wire [23:0]  childBd_11_rdata;
  wire [15:0]  childBd_10_rdata;
  wire [23:0]  childBd_9_rdata;
  wire [23:0]  childBd_8_rdata;
  wire [23:0]  childBd_7_rdata;
  wire [23:0]  childBd_6_rdata;
  wire [15:0]  childBd_5_rdata;
  wire [23:0]  childBd_4_rdata;
  wire [23:0]  childBd_3_rdata;
  wire [23:0]  childBd_2_rdata;
  wire [23:0]  childBd_1_rdata;
  wire [15:0]  childBd_rdata;
  wire [6:0]   bd_array = boreChildrenBd_bore_array;
  wire         bd_all = boreChildrenBd_bore_all;
  wire         bd_req = boreChildrenBd_bore_req;
  wire         bd_writeen = boreChildrenBd_bore_writeen;
  wire [15:0]  bd_be = boreChildrenBd_bore_be;
  wire [9:0]   bd_addr = boreChildrenBd_bore_addr;
  wire [23:0]  bd_indata = boreChildrenBd_bore_indata;
  wire         bd_readen = boreChildrenBd_bore_readen;
  wire [9:0]   bd_addr_rd = boreChildrenBd_bore_addr_rd;
  wire [8:0]   childBd_addr;
  wire [8:0]   childBd_addr_rd;
  wire [15:0]  childBd_wdata;
  wire [15:0]  childBd_wmask;
  wire         childBd_re;
  wire         childBd_we;
  wire         childBd_ack;
  wire         childBd_selectedOH;
  wire [5:0]   childBd_array;
  wire [9:0]   childBd_1_addr;
  wire [9:0]   childBd_1_addr_rd;
  wire [23:0]  childBd_1_wdata;
  wire [1:0]   childBd_1_wmask;
  wire         childBd_1_re;
  wire         childBd_1_we;
  wire         childBd_1_ack;
  wire         childBd_1_selectedOH;
  wire [5:0]   childBd_1_array;
  wire [9:0]   childBd_2_addr;
  wire [9:0]   childBd_2_addr_rd;
  wire [23:0]  childBd_2_wdata;
  wire [1:0]   childBd_2_wmask;
  wire         childBd_2_re;
  wire         childBd_2_we;
  wire         childBd_2_ack;
  wire         childBd_2_selectedOH;
  wire [5:0]   childBd_2_array;
  wire [9:0]   childBd_3_addr;
  wire [9:0]   childBd_3_addr_rd;
  wire [23:0]  childBd_3_wdata;
  wire [1:0]   childBd_3_wmask;
  wire         childBd_3_re;
  wire         childBd_3_we;
  wire         childBd_3_ack;
  wire         childBd_3_selectedOH;
  wire [5:0]   childBd_3_array;
  wire [9:0]   childBd_4_addr;
  wire [9:0]   childBd_4_addr_rd;
  wire [23:0]  childBd_4_wdata;
  wire [1:0]   childBd_4_wmask;
  wire         childBd_4_re;
  wire         childBd_4_we;
  wire         childBd_4_ack;
  wire         childBd_4_selectedOH;
  wire [5:0]   childBd_4_array;
  wire [8:0]   childBd_5_addr;
  wire [8:0]   childBd_5_addr_rd;
  wire [15:0]  childBd_5_wdata;
  wire [15:0]  childBd_5_wmask;
  wire         childBd_5_re;
  wire         childBd_5_we;
  wire         childBd_5_ack;
  wire         childBd_5_selectedOH;
  wire [5:0]   childBd_5_array;
  wire [9:0]   childBd_6_addr;
  wire [9:0]   childBd_6_addr_rd;
  wire [23:0]  childBd_6_wdata;
  wire [1:0]   childBd_6_wmask;
  wire         childBd_6_re;
  wire         childBd_6_we;
  wire         childBd_6_ack;
  wire         childBd_6_selectedOH;
  wire [5:0]   childBd_6_array;
  wire [9:0]   childBd_7_addr;
  wire [9:0]   childBd_7_addr_rd;
  wire [23:0]  childBd_7_wdata;
  wire [1:0]   childBd_7_wmask;
  wire         childBd_7_re;
  wire         childBd_7_we;
  wire         childBd_7_ack;
  wire         childBd_7_selectedOH;
  wire [5:0]   childBd_7_array;
  wire [9:0]   childBd_8_addr;
  wire [9:0]   childBd_8_addr_rd;
  wire [23:0]  childBd_8_wdata;
  wire [1:0]   childBd_8_wmask;
  wire         childBd_8_re;
  wire         childBd_8_we;
  wire         childBd_8_ack;
  wire         childBd_8_selectedOH;
  wire [5:0]   childBd_8_array;
  wire [9:0]   childBd_9_addr;
  wire [9:0]   childBd_9_addr_rd;
  wire [23:0]  childBd_9_wdata;
  wire [1:0]   childBd_9_wmask;
  wire         childBd_9_re;
  wire         childBd_9_we;
  wire         childBd_9_ack;
  wire         childBd_9_selectedOH;
  wire [5:0]   childBd_9_array;
  wire [8:0]   childBd_10_addr;
  wire [8:0]   childBd_10_addr_rd;
  wire [15:0]  childBd_10_wdata;
  wire [15:0]  childBd_10_wmask;
  wire         childBd_10_re;
  wire         childBd_10_we;
  wire         childBd_10_ack;
  wire         childBd_10_selectedOH;
  wire [5:0]   childBd_10_array;
  wire [9:0]   childBd_11_addr;
  wire [9:0]   childBd_11_addr_rd;
  wire [23:0]  childBd_11_wdata;
  wire [1:0]   childBd_11_wmask;
  wire         childBd_11_re;
  wire         childBd_11_we;
  wire         childBd_11_ack;
  wire         childBd_11_selectedOH;
  wire [5:0]   childBd_11_array;
  wire [9:0]   childBd_12_addr;
  wire [9:0]   childBd_12_addr_rd;
  wire [23:0]  childBd_12_wdata;
  wire [1:0]   childBd_12_wmask;
  wire         childBd_12_re;
  wire         childBd_12_we;
  wire         childBd_12_ack;
  wire         childBd_12_selectedOH;
  wire [5:0]   childBd_12_array;
  wire [9:0]   childBd_13_addr;
  wire [9:0]   childBd_13_addr_rd;
  wire [23:0]  childBd_13_wdata;
  wire [1:0]   childBd_13_wmask;
  wire         childBd_13_re;
  wire         childBd_13_we;
  wire         childBd_13_ack;
  wire         childBd_13_selectedOH;
  wire [5:0]   childBd_13_array;
  wire [9:0]   childBd_14_addr;
  wire [9:0]   childBd_14_addr_rd;
  wire [23:0]  childBd_14_wdata;
  wire [1:0]   childBd_14_wmask;
  wire         childBd_14_re;
  wire         childBd_14_we;
  wire         childBd_14_ack;
  wire         childBd_14_selectedOH;
  wire [5:0]   childBd_14_array;
  wire [8:0]   childBd_15_addr;
  wire [8:0]   childBd_15_addr_rd;
  wire [15:0]  childBd_15_wdata;
  wire [15:0]  childBd_15_wmask;
  wire         childBd_15_re;
  wire         childBd_15_we;
  wire         childBd_15_ack;
  wire         childBd_15_selectedOH;
  wire [5:0]   childBd_15_array;
  wire [9:0]   childBd_16_addr;
  wire [9:0]   childBd_16_addr_rd;
  wire [23:0]  childBd_16_wdata;
  wire [1:0]   childBd_16_wmask;
  wire         childBd_16_re;
  wire         childBd_16_we;
  wire         childBd_16_ack;
  wire         childBd_16_selectedOH;
  wire [5:0]   childBd_16_array;
  wire [9:0]   childBd_17_addr;
  wire [9:0]   childBd_17_addr_rd;
  wire [23:0]  childBd_17_wdata;
  wire [1:0]   childBd_17_wmask;
  wire         childBd_17_re;
  wire         childBd_17_we;
  wire         childBd_17_ack;
  wire         childBd_17_selectedOH;
  wire [5:0]   childBd_17_array;
  wire [9:0]   childBd_18_addr;
  wire [9:0]   childBd_18_addr_rd;
  wire [23:0]  childBd_18_wdata;
  wire [1:0]   childBd_18_wmask;
  wire         childBd_18_re;
  wire         childBd_18_we;
  wire         childBd_18_ack;
  wire         childBd_18_selectedOH;
  wire [5:0]   childBd_18_array;
  wire [9:0]   childBd_19_addr;
  wire [9:0]   childBd_19_addr_rd;
  wire [23:0]  childBd_19_wdata;
  wire [1:0]   childBd_19_wmask;
  wire         childBd_19_re;
  wire         childBd_19_we;
  wire         childBd_19_ack;
  wire         childBd_19_selectedOH;
  wire [5:0]   childBd_19_array;
  wire [8:0]   childBd_20_addr;
  wire [8:0]   childBd_20_addr_rd;
  wire [15:0]  childBd_20_wdata;
  wire [7:0]   childBd_20_wmask;
  wire         childBd_20_re;
  wire         childBd_20_we;
  wire         childBd_20_ack;
  wire         childBd_20_selectedOH;
  wire [6:0]   childBd_20_array;
  wire [8:0]   childBd_21_addr;
  wire [8:0]   childBd_21_addr_rd;
  wire [15:0]  childBd_21_wdata;
  wire [7:0]   childBd_21_wmask;
  wire         childBd_21_re;
  wire         childBd_21_we;
  wire         childBd_21_ack;
  wire         childBd_21_selectedOH;
  wire [6:0]   childBd_21_array;

  MbistPipeTage mbistPl (
    .clock                (clock),
    .reset                (reset),
    .mbist_array          (bd_array),
    .mbist_all            (bd_all),
    .mbist_req            (bd_req),
    .mbist_ack            (bd_ack),
    .mbist_writeen        (bd_writeen),
    .mbist_be             (bd_be),
    .mbist_addr           (bd_addr),
    .mbist_indata         (bd_indata),
    .mbist_readen         (bd_readen),
    .mbist_addr_rd        (bd_addr_rd),
    .mbist_outdata        (bd_outdata),
    .toSRAM_0_addr        (childBd_addr),
    .toSRAM_0_addr_rd     (childBd_addr_rd),
    .toSRAM_0_wdata       (childBd_wdata),
    .toSRAM_0_wmask       (childBd_wmask),
    .toSRAM_0_re          (childBd_re),
    .toSRAM_0_we          (childBd_we),
    .toSRAM_0_rdata       (childBd_rdata),
    .toSRAM_0_ack         (childBd_ack),
    .toSRAM_0_selectedOH  (childBd_selectedOH),
    .toSRAM_0_array       (childBd_array),
    .toSRAM_1_addr        (childBd_1_addr),
    .toSRAM_1_addr_rd     (childBd_1_addr_rd),
    .toSRAM_1_wdata       (childBd_1_wdata),
    .toSRAM_1_wmask       (childBd_1_wmask),
    .toSRAM_1_re          (childBd_1_re),
    .toSRAM_1_we          (childBd_1_we),
    .toSRAM_1_rdata       (childBd_1_rdata),
    .toSRAM_1_ack         (childBd_1_ack),
    .toSRAM_1_selectedOH  (childBd_1_selectedOH),
    .toSRAM_1_array       (childBd_1_array),
    .toSRAM_2_addr        (childBd_2_addr),
    .toSRAM_2_addr_rd     (childBd_2_addr_rd),
    .toSRAM_2_wdata       (childBd_2_wdata),
    .toSRAM_2_wmask       (childBd_2_wmask),
    .toSRAM_2_re          (childBd_2_re),
    .toSRAM_2_we          (childBd_2_we),
    .toSRAM_2_rdata       (childBd_2_rdata),
    .toSRAM_2_ack         (childBd_2_ack),
    .toSRAM_2_selectedOH  (childBd_2_selectedOH),
    .toSRAM_2_array       (childBd_2_array),
    .toSRAM_3_addr        (childBd_3_addr),
    .toSRAM_3_addr_rd     (childBd_3_addr_rd),
    .toSRAM_3_wdata       (childBd_3_wdata),
    .toSRAM_3_wmask       (childBd_3_wmask),
    .toSRAM_3_re          (childBd_3_re),
    .toSRAM_3_we          (childBd_3_we),
    .toSRAM_3_rdata       (childBd_3_rdata),
    .toSRAM_3_ack         (childBd_3_ack),
    .toSRAM_3_selectedOH  (childBd_3_selectedOH),
    .toSRAM_3_array       (childBd_3_array),
    .toSRAM_4_addr        (childBd_4_addr),
    .toSRAM_4_addr_rd     (childBd_4_addr_rd),
    .toSRAM_4_wdata       (childBd_4_wdata),
    .toSRAM_4_wmask       (childBd_4_wmask),
    .toSRAM_4_re          (childBd_4_re),
    .toSRAM_4_we          (childBd_4_we),
    .toSRAM_4_rdata       (childBd_4_rdata),
    .toSRAM_4_ack         (childBd_4_ack),
    .toSRAM_4_selectedOH  (childBd_4_selectedOH),
    .toSRAM_4_array       (childBd_4_array),
    .toSRAM_5_addr        (childBd_5_addr),
    .toSRAM_5_addr_rd     (childBd_5_addr_rd),
    .toSRAM_5_wdata       (childBd_5_wdata),
    .toSRAM_5_wmask       (childBd_5_wmask),
    .toSRAM_5_re          (childBd_5_re),
    .toSRAM_5_we          (childBd_5_we),
    .toSRAM_5_rdata       (childBd_5_rdata),
    .toSRAM_5_ack         (childBd_5_ack),
    .toSRAM_5_selectedOH  (childBd_5_selectedOH),
    .toSRAM_5_array       (childBd_5_array),
    .toSRAM_6_addr        (childBd_6_addr),
    .toSRAM_6_addr_rd     (childBd_6_addr_rd),
    .toSRAM_6_wdata       (childBd_6_wdata),
    .toSRAM_6_wmask       (childBd_6_wmask),
    .toSRAM_6_re          (childBd_6_re),
    .toSRAM_6_we          (childBd_6_we),
    .toSRAM_6_rdata       (childBd_6_rdata),
    .toSRAM_6_ack         (childBd_6_ack),
    .toSRAM_6_selectedOH  (childBd_6_selectedOH),
    .toSRAM_6_array       (childBd_6_array),
    .toSRAM_7_addr        (childBd_7_addr),
    .toSRAM_7_addr_rd     (childBd_7_addr_rd),
    .toSRAM_7_wdata       (childBd_7_wdata),
    .toSRAM_7_wmask       (childBd_7_wmask),
    .toSRAM_7_re          (childBd_7_re),
    .toSRAM_7_we          (childBd_7_we),
    .toSRAM_7_rdata       (childBd_7_rdata),
    .toSRAM_7_ack         (childBd_7_ack),
    .toSRAM_7_selectedOH  (childBd_7_selectedOH),
    .toSRAM_7_array       (childBd_7_array),
    .toSRAM_8_addr        (childBd_8_addr),
    .toSRAM_8_addr_rd     (childBd_8_addr_rd),
    .toSRAM_8_wdata       (childBd_8_wdata),
    .toSRAM_8_wmask       (childBd_8_wmask),
    .toSRAM_8_re          (childBd_8_re),
    .toSRAM_8_we          (childBd_8_we),
    .toSRAM_8_rdata       (childBd_8_rdata),
    .toSRAM_8_ack         (childBd_8_ack),
    .toSRAM_8_selectedOH  (childBd_8_selectedOH),
    .toSRAM_8_array       (childBd_8_array),
    .toSRAM_9_addr        (childBd_9_addr),
    .toSRAM_9_addr_rd     (childBd_9_addr_rd),
    .toSRAM_9_wdata       (childBd_9_wdata),
    .toSRAM_9_wmask       (childBd_9_wmask),
    .toSRAM_9_re          (childBd_9_re),
    .toSRAM_9_we          (childBd_9_we),
    .toSRAM_9_rdata       (childBd_9_rdata),
    .toSRAM_9_ack         (childBd_9_ack),
    .toSRAM_9_selectedOH  (childBd_9_selectedOH),
    .toSRAM_9_array       (childBd_9_array),
    .toSRAM_10_addr       (childBd_10_addr),
    .toSRAM_10_addr_rd    (childBd_10_addr_rd),
    .toSRAM_10_wdata      (childBd_10_wdata),
    .toSRAM_10_wmask      (childBd_10_wmask),
    .toSRAM_10_re         (childBd_10_re),
    .toSRAM_10_we         (childBd_10_we),
    .toSRAM_10_rdata      (childBd_10_rdata),
    .toSRAM_10_ack        (childBd_10_ack),
    .toSRAM_10_selectedOH (childBd_10_selectedOH),
    .toSRAM_10_array      (childBd_10_array),
    .toSRAM_11_addr       (childBd_11_addr),
    .toSRAM_11_addr_rd    (childBd_11_addr_rd),
    .toSRAM_11_wdata      (childBd_11_wdata),
    .toSRAM_11_wmask      (childBd_11_wmask),
    .toSRAM_11_re         (childBd_11_re),
    .toSRAM_11_we         (childBd_11_we),
    .toSRAM_11_rdata      (childBd_11_rdata),
    .toSRAM_11_ack        (childBd_11_ack),
    .toSRAM_11_selectedOH (childBd_11_selectedOH),
    .toSRAM_11_array      (childBd_11_array),
    .toSRAM_12_addr       (childBd_12_addr),
    .toSRAM_12_addr_rd    (childBd_12_addr_rd),
    .toSRAM_12_wdata      (childBd_12_wdata),
    .toSRAM_12_wmask      (childBd_12_wmask),
    .toSRAM_12_re         (childBd_12_re),
    .toSRAM_12_we         (childBd_12_we),
    .toSRAM_12_rdata      (childBd_12_rdata),
    .toSRAM_12_ack        (childBd_12_ack),
    .toSRAM_12_selectedOH (childBd_12_selectedOH),
    .toSRAM_12_array      (childBd_12_array),
    .toSRAM_13_addr       (childBd_13_addr),
    .toSRAM_13_addr_rd    (childBd_13_addr_rd),
    .toSRAM_13_wdata      (childBd_13_wdata),
    .toSRAM_13_wmask      (childBd_13_wmask),
    .toSRAM_13_re         (childBd_13_re),
    .toSRAM_13_we         (childBd_13_we),
    .toSRAM_13_rdata      (childBd_13_rdata),
    .toSRAM_13_ack        (childBd_13_ack),
    .toSRAM_13_selectedOH (childBd_13_selectedOH),
    .toSRAM_13_array      (childBd_13_array),
    .toSRAM_14_addr       (childBd_14_addr),
    .toSRAM_14_addr_rd    (childBd_14_addr_rd),
    .toSRAM_14_wdata      (childBd_14_wdata),
    .toSRAM_14_wmask      (childBd_14_wmask),
    .toSRAM_14_re         (childBd_14_re),
    .toSRAM_14_we         (childBd_14_we),
    .toSRAM_14_rdata      (childBd_14_rdata),
    .toSRAM_14_ack        (childBd_14_ack),
    .toSRAM_14_selectedOH (childBd_14_selectedOH),
    .toSRAM_14_array      (childBd_14_array),
    .toSRAM_15_addr       (childBd_15_addr),
    .toSRAM_15_addr_rd    (childBd_15_addr_rd),
    .toSRAM_15_wdata      (childBd_15_wdata),
    .toSRAM_15_wmask      (childBd_15_wmask),
    .toSRAM_15_re         (childBd_15_re),
    .toSRAM_15_we         (childBd_15_we),
    .toSRAM_15_rdata      (childBd_15_rdata),
    .toSRAM_15_ack        (childBd_15_ack),
    .toSRAM_15_selectedOH (childBd_15_selectedOH),
    .toSRAM_15_array      (childBd_15_array),
    .toSRAM_16_addr       (childBd_16_addr),
    .toSRAM_16_addr_rd    (childBd_16_addr_rd),
    .toSRAM_16_wdata      (childBd_16_wdata),
    .toSRAM_16_wmask      (childBd_16_wmask),
    .toSRAM_16_re         (childBd_16_re),
    .toSRAM_16_we         (childBd_16_we),
    .toSRAM_16_rdata      (childBd_16_rdata),
    .toSRAM_16_ack        (childBd_16_ack),
    .toSRAM_16_selectedOH (childBd_16_selectedOH),
    .toSRAM_16_array      (childBd_16_array),
    .toSRAM_17_addr       (childBd_17_addr),
    .toSRAM_17_addr_rd    (childBd_17_addr_rd),
    .toSRAM_17_wdata      (childBd_17_wdata),
    .toSRAM_17_wmask      (childBd_17_wmask),
    .toSRAM_17_re         (childBd_17_re),
    .toSRAM_17_we         (childBd_17_we),
    .toSRAM_17_rdata      (childBd_17_rdata),
    .toSRAM_17_ack        (childBd_17_ack),
    .toSRAM_17_selectedOH (childBd_17_selectedOH),
    .toSRAM_17_array      (childBd_17_array),
    .toSRAM_18_addr       (childBd_18_addr),
    .toSRAM_18_addr_rd    (childBd_18_addr_rd),
    .toSRAM_18_wdata      (childBd_18_wdata),
    .toSRAM_18_wmask      (childBd_18_wmask),
    .toSRAM_18_re         (childBd_18_re),
    .toSRAM_18_we         (childBd_18_we),
    .toSRAM_18_rdata      (childBd_18_rdata),
    .toSRAM_18_ack        (childBd_18_ack),
    .toSRAM_18_selectedOH (childBd_18_selectedOH),
    .toSRAM_18_array      (childBd_18_array),
    .toSRAM_19_addr       (childBd_19_addr),
    .toSRAM_19_addr_rd    (childBd_19_addr_rd),
    .toSRAM_19_wdata      (childBd_19_wdata),
    .toSRAM_19_wmask      (childBd_19_wmask),
    .toSRAM_19_re         (childBd_19_re),
    .toSRAM_19_we         (childBd_19_we),
    .toSRAM_19_rdata      (childBd_19_rdata),
    .toSRAM_19_ack        (childBd_19_ack),
    .toSRAM_19_selectedOH (childBd_19_selectedOH),
    .toSRAM_19_array      (childBd_19_array),
    .toSRAM_20_addr       (childBd_20_addr),
    .toSRAM_20_addr_rd    (childBd_20_addr_rd),
    .toSRAM_20_wdata      (childBd_20_wdata),
    .toSRAM_20_wmask      (childBd_20_wmask),
    .toSRAM_20_re         (childBd_20_re),
    .toSRAM_20_we         (childBd_20_we),
    .toSRAM_20_rdata      (childBd_20_rdata),
    .toSRAM_20_ack        (childBd_20_ack),
    .toSRAM_20_selectedOH (childBd_20_selectedOH),
    .toSRAM_20_array      (childBd_20_array),
    .toSRAM_21_addr       (childBd_21_addr),
    .toSRAM_21_addr_rd    (childBd_21_addr_rd),
    .toSRAM_21_wdata      (childBd_21_wdata),
    .toSRAM_21_wmask      (childBd_21_wmask),
    .toSRAM_21_re         (childBd_21_re),
    .toSRAM_21_we         (childBd_21_we),
    .toSRAM_21_rdata      (childBd_21_rdata),
    .toSRAM_21_ack        (childBd_21_ack),
    .toSRAM_21_selectedOH (childBd_21_selectedOH),
    .toSRAM_21_array      (childBd_21_array)
  );

  // ===== 子模块实例 =====
  TageTable tables_0 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t0_req_ready),
    .io_req_valid(core_tbl_req_valid),
    .io_req_bits_pc(core_tbl_req_pc),
    .io_req_bits_ghist(io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_14_folded_hist(io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_req_bits_folded_hist_hist_7_folded_hist(io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_resps_0_valid(t0_resp_valid_0),
    .io_resps_0_bits_ctr(t0_resp_ctr_0),
    .io_resps_0_bits_u(t0_resp_u_0),
    .io_resps_0_bits_unconf(t0_resp_unconf_0),
    .io_resps_1_valid(t0_resp_valid_1),
    .io_resps_1_bits_ctr(t0_resp_ctr_1),
    .io_resps_1_bits_u(t0_resp_u_1),
    .io_resps_1_bits_unconf(t0_resp_unconf_1),
    .io_update_pc(t0_upd_pc),
    .io_update_ghist(t0_upd_ghist),
    .io_update_mask_0(t0_upd_mask_0),
    .io_update_mask_1(t0_upd_mask_1),
    .io_update_takens_0(t0_upd_takens_0),
    .io_update_takens_1(t0_upd_takens_1),
    .io_update_alloc_0(t0_upd_alloc_0),
    .io_update_alloc_1(t0_upd_alloc_1),
    .io_update_oldCtrs_0(t0_upd_oldCtrs_0),
    .io_update_oldCtrs_1(t0_upd_oldCtrs_1),
    .io_update_uMask_0(t0_upd_uMask_0),
    .io_update_uMask_1(t0_upd_uMask_1),
    .io_update_us_0(t0_upd_us_0),
    .io_update_us_1(t0_upd_us_1),
    .io_update_reset_u_0(t0_upd_reset_u_0),
    .io_update_reset_u_1(t0_upd_reset_u_1),
    .boreChildrenBd_bore_addr(childBd_addr),
    .boreChildrenBd_bore_addr_rd(childBd_addr_rd),
    .boreChildrenBd_bore_wdata(childBd_wdata),
    .boreChildrenBd_bore_wmask(childBd_wmask),
    .boreChildrenBd_bore_re(childBd_re),
    .boreChildrenBd_bore_we(childBd_we),
    .boreChildrenBd_bore_rdata(childBd_rdata),
    .boreChildrenBd_bore_ack(childBd_ack),
    .boreChildrenBd_bore_selectedOH(childBd_selectedOH),
    .boreChildrenBd_bore_array(childBd_array),
    .boreChildrenBd_bore_1_addr(childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask(childBd_1_wmask),
    .boreChildrenBd_bore_1_re(childBd_1_re),
    .boreChildrenBd_bore_1_we(childBd_1_we),
    .boreChildrenBd_bore_1_rdata(childBd_1_rdata),
    .boreChildrenBd_bore_1_ack(childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array(childBd_1_array),
    .boreChildrenBd_bore_2_addr(childBd_2_addr),
    .boreChildrenBd_bore_2_addr_rd(childBd_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(childBd_2_wdata),
    .boreChildrenBd_bore_2_wmask(childBd_2_wmask),
    .boreChildrenBd_bore_2_re(childBd_2_re),
    .boreChildrenBd_bore_2_we(childBd_2_we),
    .boreChildrenBd_bore_2_rdata(childBd_2_rdata),
    .boreChildrenBd_bore_2_ack(childBd_2_ack),
    .boreChildrenBd_bore_2_selectedOH(childBd_2_selectedOH),
    .boreChildrenBd_bore_2_array(childBd_2_array),
    .boreChildrenBd_bore_3_addr(childBd_3_addr),
    .boreChildrenBd_bore_3_addr_rd(childBd_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(childBd_3_wdata),
    .boreChildrenBd_bore_3_wmask(childBd_3_wmask),
    .boreChildrenBd_bore_3_re(childBd_3_re),
    .boreChildrenBd_bore_3_we(childBd_3_we),
    .boreChildrenBd_bore_3_rdata(childBd_3_rdata),
    .boreChildrenBd_bore_3_ack(childBd_3_ack),
    .boreChildrenBd_bore_3_selectedOH(childBd_3_selectedOH),
    .boreChildrenBd_bore_3_array(childBd_3_array),
    .boreChildrenBd_bore_4_addr(childBd_4_addr),
    .boreChildrenBd_bore_4_addr_rd(childBd_4_addr_rd),
    .boreChildrenBd_bore_4_wdata(childBd_4_wdata),
    .boreChildrenBd_bore_4_wmask(childBd_4_wmask),
    .boreChildrenBd_bore_4_re(childBd_4_re),
    .boreChildrenBd_bore_4_we(childBd_4_we),
    .boreChildrenBd_bore_4_rdata(childBd_4_rdata),
    .boreChildrenBd_bore_4_ack(childBd_4_ack),
    .boreChildrenBd_bore_4_selectedOH(childBd_4_selectedOH),
    .boreChildrenBd_bore_4_array(childBd_4_array),
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
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen)
  );
  TageTable_1 tables_1 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t1_req_ready),
    .io_req_valid(core_tbl_req_valid),
    .io_req_bits_pc(core_tbl_req_pc),
    .io_req_bits_ghist(io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_15_folded_hist(io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_req_bits_folded_hist_hist_4_folded_hist(io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_req_bits_folded_hist_hist_1_folded_hist(io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_resps_0_valid(t1_resp_valid_0),
    .io_resps_0_bits_ctr(t1_resp_ctr_0),
    .io_resps_0_bits_u(t1_resp_u_0),
    .io_resps_0_bits_unconf(t1_resp_unconf_0),
    .io_resps_1_valid(t1_resp_valid_1),
    .io_resps_1_bits_ctr(t1_resp_ctr_1),
    .io_resps_1_bits_u(t1_resp_u_1),
    .io_resps_1_bits_unconf(t1_resp_unconf_1),
    .io_update_pc(t1_upd_pc),
    .io_update_ghist(t1_upd_ghist),
    .io_update_mask_0(t1_upd_mask_0),
    .io_update_mask_1(t1_upd_mask_1),
    .io_update_takens_0(t1_upd_takens_0),
    .io_update_takens_1(t1_upd_takens_1),
    .io_update_alloc_0(t1_upd_alloc_0),
    .io_update_alloc_1(t1_upd_alloc_1),
    .io_update_oldCtrs_0(t1_upd_oldCtrs_0),
    .io_update_oldCtrs_1(t1_upd_oldCtrs_1),
    .io_update_uMask_0(t1_upd_uMask_0),
    .io_update_uMask_1(t1_upd_uMask_1),
    .io_update_us_0(t1_upd_us_0),
    .io_update_us_1(t1_upd_us_1),
    .io_update_reset_u_0(t1_upd_reset_u_0),
    .io_update_reset_u_1(t1_upd_reset_u_1),
    .boreChildrenBd_bore_addr(childBd_5_addr),
    .boreChildrenBd_bore_addr_rd(childBd_5_addr_rd),
    .boreChildrenBd_bore_wdata(childBd_5_wdata),
    .boreChildrenBd_bore_wmask(childBd_5_wmask),
    .boreChildrenBd_bore_re(childBd_5_re),
    .boreChildrenBd_bore_we(childBd_5_we),
    .boreChildrenBd_bore_rdata(childBd_5_rdata),
    .boreChildrenBd_bore_ack(childBd_5_ack),
    .boreChildrenBd_bore_selectedOH(childBd_5_selectedOH),
    .boreChildrenBd_bore_array(childBd_5_array),
    .boreChildrenBd_bore_1_addr(childBd_6_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd_6_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd_6_wdata),
    .boreChildrenBd_bore_1_wmask(childBd_6_wmask),
    .boreChildrenBd_bore_1_re(childBd_6_re),
    .boreChildrenBd_bore_1_we(childBd_6_we),
    .boreChildrenBd_bore_1_rdata(childBd_6_rdata),
    .boreChildrenBd_bore_1_ack(childBd_6_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd_6_selectedOH),
    .boreChildrenBd_bore_1_array(childBd_6_array),
    .boreChildrenBd_bore_2_addr(childBd_7_addr),
    .boreChildrenBd_bore_2_addr_rd(childBd_7_addr_rd),
    .boreChildrenBd_bore_2_wdata(childBd_7_wdata),
    .boreChildrenBd_bore_2_wmask(childBd_7_wmask),
    .boreChildrenBd_bore_2_re(childBd_7_re),
    .boreChildrenBd_bore_2_we(childBd_7_we),
    .boreChildrenBd_bore_2_rdata(childBd_7_rdata),
    .boreChildrenBd_bore_2_ack(childBd_7_ack),
    .boreChildrenBd_bore_2_selectedOH(childBd_7_selectedOH),
    .boreChildrenBd_bore_2_array(childBd_7_array),
    .boreChildrenBd_bore_3_addr(childBd_8_addr),
    .boreChildrenBd_bore_3_addr_rd(childBd_8_addr_rd),
    .boreChildrenBd_bore_3_wdata(childBd_8_wdata),
    .boreChildrenBd_bore_3_wmask(childBd_8_wmask),
    .boreChildrenBd_bore_3_re(childBd_8_re),
    .boreChildrenBd_bore_3_we(childBd_8_we),
    .boreChildrenBd_bore_3_rdata(childBd_8_rdata),
    .boreChildrenBd_bore_3_ack(childBd_8_ack),
    .boreChildrenBd_bore_3_selectedOH(childBd_8_selectedOH),
    .boreChildrenBd_bore_3_array(childBd_8_array),
    .boreChildrenBd_bore_4_addr(childBd_9_addr),
    .boreChildrenBd_bore_4_addr_rd(childBd_9_addr_rd),
    .boreChildrenBd_bore_4_wdata(childBd_9_wdata),
    .boreChildrenBd_bore_4_wmask(childBd_9_wmask),
    .boreChildrenBd_bore_4_re(childBd_9_re),
    .boreChildrenBd_bore_4_we(childBd_9_we),
    .boreChildrenBd_bore_4_rdata(childBd_9_rdata),
    .boreChildrenBd_bore_4_ack(childBd_9_ack),
    .boreChildrenBd_bore_4_selectedOH(childBd_9_selectedOH),
    .boreChildrenBd_bore_4_array(childBd_9_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_9_cgen)
  );
  TageTable_2 tables_2 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t2_req_ready),
    .io_req_valid(core_tbl_req_valid),
    .io_req_bits_pc(core_tbl_req_pc),
    .io_req_bits_ghist(io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_17_folded_hist(io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_req_bits_folded_hist_hist_9_folded_hist(io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_req_bits_folded_hist_hist_3_folded_hist(io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_resps_0_valid(t2_resp_valid_0),
    .io_resps_0_bits_ctr(t2_resp_ctr_0),
    .io_resps_0_bits_u(t2_resp_u_0),
    .io_resps_0_bits_unconf(t2_resp_unconf_0),
    .io_resps_1_valid(t2_resp_valid_1),
    .io_resps_1_bits_ctr(t2_resp_ctr_1),
    .io_resps_1_bits_u(t2_resp_u_1),
    .io_resps_1_bits_unconf(t2_resp_unconf_1),
    .io_update_pc(t2_upd_pc),
    .io_update_ghist(t2_upd_ghist),
    .io_update_mask_0(t2_upd_mask_0),
    .io_update_mask_1(t2_upd_mask_1),
    .io_update_takens_0(t2_upd_takens_0),
    .io_update_takens_1(t2_upd_takens_1),
    .io_update_alloc_0(t2_upd_alloc_0),
    .io_update_alloc_1(t2_upd_alloc_1),
    .io_update_oldCtrs_0(t2_upd_oldCtrs_0),
    .io_update_oldCtrs_1(t2_upd_oldCtrs_1),
    .io_update_uMask_0(t2_upd_uMask_0),
    .io_update_uMask_1(t2_upd_uMask_1),
    .io_update_us_0(t2_upd_us_0),
    .io_update_us_1(t2_upd_us_1),
    .io_update_reset_u_0(t2_upd_reset_u_0),
    .io_update_reset_u_1(t2_upd_reset_u_1),
    .boreChildrenBd_bore_addr(childBd_10_addr),
    .boreChildrenBd_bore_addr_rd(childBd_10_addr_rd),
    .boreChildrenBd_bore_wdata(childBd_10_wdata),
    .boreChildrenBd_bore_wmask(childBd_10_wmask),
    .boreChildrenBd_bore_re(childBd_10_re),
    .boreChildrenBd_bore_we(childBd_10_we),
    .boreChildrenBd_bore_rdata(childBd_10_rdata),
    .boreChildrenBd_bore_ack(childBd_10_ack),
    .boreChildrenBd_bore_selectedOH(childBd_10_selectedOH),
    .boreChildrenBd_bore_array(childBd_10_array),
    .boreChildrenBd_bore_1_addr(childBd_11_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd_11_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd_11_wdata),
    .boreChildrenBd_bore_1_wmask(childBd_11_wmask),
    .boreChildrenBd_bore_1_re(childBd_11_re),
    .boreChildrenBd_bore_1_we(childBd_11_we),
    .boreChildrenBd_bore_1_rdata(childBd_11_rdata),
    .boreChildrenBd_bore_1_ack(childBd_11_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd_11_selectedOH),
    .boreChildrenBd_bore_1_array(childBd_11_array),
    .boreChildrenBd_bore_2_addr(childBd_12_addr),
    .boreChildrenBd_bore_2_addr_rd(childBd_12_addr_rd),
    .boreChildrenBd_bore_2_wdata(childBd_12_wdata),
    .boreChildrenBd_bore_2_wmask(childBd_12_wmask),
    .boreChildrenBd_bore_2_re(childBd_12_re),
    .boreChildrenBd_bore_2_we(childBd_12_we),
    .boreChildrenBd_bore_2_rdata(childBd_12_rdata),
    .boreChildrenBd_bore_2_ack(childBd_12_ack),
    .boreChildrenBd_bore_2_selectedOH(childBd_12_selectedOH),
    .boreChildrenBd_bore_2_array(childBd_12_array),
    .boreChildrenBd_bore_3_addr(childBd_13_addr),
    .boreChildrenBd_bore_3_addr_rd(childBd_13_addr_rd),
    .boreChildrenBd_bore_3_wdata(childBd_13_wdata),
    .boreChildrenBd_bore_3_wmask(childBd_13_wmask),
    .boreChildrenBd_bore_3_re(childBd_13_re),
    .boreChildrenBd_bore_3_we(childBd_13_we),
    .boreChildrenBd_bore_3_rdata(childBd_13_rdata),
    .boreChildrenBd_bore_3_ack(childBd_13_ack),
    .boreChildrenBd_bore_3_selectedOH(childBd_13_selectedOH),
    .boreChildrenBd_bore_3_array(childBd_13_array),
    .boreChildrenBd_bore_4_addr(childBd_14_addr),
    .boreChildrenBd_bore_4_addr_rd(childBd_14_addr_rd),
    .boreChildrenBd_bore_4_wdata(childBd_14_wdata),
    .boreChildrenBd_bore_4_wmask(childBd_14_wmask),
    .boreChildrenBd_bore_4_re(childBd_14_re),
    .boreChildrenBd_bore_4_we(childBd_14_we),
    .boreChildrenBd_bore_4_rdata(childBd_14_rdata),
    .boreChildrenBd_bore_4_ack(childBd_14_ack),
    .boreChildrenBd_bore_4_selectedOH(childBd_14_selectedOH),
    .boreChildrenBd_bore_4_array(childBd_14_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_14_cgen)
  );
  TageTable_3 tables_3 (
    .clock(clock),
    .reset(reset),
    .io_req_ready(t3_req_ready),
    .io_req_valid(core_tbl_req_valid),
    .io_req_bits_pc(core_tbl_req_pc),
    .io_req_bits_ghist(io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_16_folded_hist(io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_req_bits_folded_hist_hist_8_folded_hist(io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_req_bits_folded_hist_hist_5_folded_hist(io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_resps_0_valid(t3_resp_valid_0),
    .io_resps_0_bits_ctr(t3_resp_ctr_0),
    .io_resps_0_bits_u(t3_resp_u_0),
    .io_resps_0_bits_unconf(t3_resp_unconf_0),
    .io_resps_1_valid(t3_resp_valid_1),
    .io_resps_1_bits_ctr(t3_resp_ctr_1),
    .io_resps_1_bits_u(t3_resp_u_1),
    .io_resps_1_bits_unconf(t3_resp_unconf_1),
    .io_update_pc(t3_upd_pc),
    .io_update_ghist(t3_upd_ghist),
    .io_update_mask_0(t3_upd_mask_0),
    .io_update_mask_1(t3_upd_mask_1),
    .io_update_takens_0(t3_upd_takens_0),
    .io_update_takens_1(t3_upd_takens_1),
    .io_update_alloc_0(t3_upd_alloc_0),
    .io_update_alloc_1(t3_upd_alloc_1),
    .io_update_oldCtrs_0(t3_upd_oldCtrs_0),
    .io_update_oldCtrs_1(t3_upd_oldCtrs_1),
    .io_update_uMask_0(t3_upd_uMask_0),
    .io_update_uMask_1(t3_upd_uMask_1),
    .io_update_us_0(t3_upd_us_0),
    .io_update_us_1(t3_upd_us_1),
    .io_update_reset_u_0(t3_upd_reset_u_0),
    .io_update_reset_u_1(t3_upd_reset_u_1),
    .boreChildrenBd_bore_addr(childBd_15_addr),
    .boreChildrenBd_bore_addr_rd(childBd_15_addr_rd),
    .boreChildrenBd_bore_wdata(childBd_15_wdata),
    .boreChildrenBd_bore_wmask(childBd_15_wmask),
    .boreChildrenBd_bore_re(childBd_15_re),
    .boreChildrenBd_bore_we(childBd_15_we),
    .boreChildrenBd_bore_rdata(childBd_15_rdata),
    .boreChildrenBd_bore_ack(childBd_15_ack),
    .boreChildrenBd_bore_selectedOH(childBd_15_selectedOH),
    .boreChildrenBd_bore_array(childBd_15_array),
    .boreChildrenBd_bore_1_addr(childBd_16_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd_16_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd_16_wdata),
    .boreChildrenBd_bore_1_wmask(childBd_16_wmask),
    .boreChildrenBd_bore_1_re(childBd_16_re),
    .boreChildrenBd_bore_1_we(childBd_16_we),
    .boreChildrenBd_bore_1_rdata(childBd_16_rdata),
    .boreChildrenBd_bore_1_ack(childBd_16_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd_16_selectedOH),
    .boreChildrenBd_bore_1_array(childBd_16_array),
    .boreChildrenBd_bore_2_addr(childBd_17_addr),
    .boreChildrenBd_bore_2_addr_rd(childBd_17_addr_rd),
    .boreChildrenBd_bore_2_wdata(childBd_17_wdata),
    .boreChildrenBd_bore_2_wmask(childBd_17_wmask),
    .boreChildrenBd_bore_2_re(childBd_17_re),
    .boreChildrenBd_bore_2_we(childBd_17_we),
    .boreChildrenBd_bore_2_rdata(childBd_17_rdata),
    .boreChildrenBd_bore_2_ack(childBd_17_ack),
    .boreChildrenBd_bore_2_selectedOH(childBd_17_selectedOH),
    .boreChildrenBd_bore_2_array(childBd_17_array),
    .boreChildrenBd_bore_3_addr(childBd_18_addr),
    .boreChildrenBd_bore_3_addr_rd(childBd_18_addr_rd),
    .boreChildrenBd_bore_3_wdata(childBd_18_wdata),
    .boreChildrenBd_bore_3_wmask(childBd_18_wmask),
    .boreChildrenBd_bore_3_re(childBd_18_re),
    .boreChildrenBd_bore_3_we(childBd_18_we),
    .boreChildrenBd_bore_3_rdata(childBd_18_rdata),
    .boreChildrenBd_bore_3_ack(childBd_18_ack),
    .boreChildrenBd_bore_3_selectedOH(childBd_18_selectedOH),
    .boreChildrenBd_bore_3_array(childBd_18_array),
    .boreChildrenBd_bore_4_addr(childBd_19_addr),
    .boreChildrenBd_bore_4_addr_rd(childBd_19_addr_rd),
    .boreChildrenBd_bore_4_wdata(childBd_19_wdata),
    .boreChildrenBd_bore_4_wmask(childBd_19_wmask),
    .boreChildrenBd_bore_4_re(childBd_19_re),
    .boreChildrenBd_bore_4_we(childBd_19_we),
    .boreChildrenBd_bore_4_rdata(childBd_19_rdata),
    .boreChildrenBd_bore_4_ack(childBd_19_ack),
    .boreChildrenBd_bore_4_selectedOH(childBd_19_selectedOH),
    .boreChildrenBd_bore_4_array(childBd_19_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_19_cgen)
  );
  TageBTable bt (
    .clock(clock),
    .reset(reset),
    .io_req_ready(bt_req_ready),
    .io_req_valid(core_bt_req_valid),
    .io_req_bits(core_bt_req_pc),
    .io_s1_cnt_0(bt_s1_cnt_0),
    .io_s1_cnt_1(bt_s1_cnt_1),
    .io_update_mask_0(bt_upd_mask_0),
    .io_update_mask_1(bt_upd_mask_1),
    .io_update_pc(bt_upd_pc),
    .io_update_cnt_0(bt_upd_cnt_0),
    .io_update_cnt_1(bt_upd_cnt_1),
    .io_update_takens_0(bt_upd_takens_0),
    .io_update_takens_1(bt_upd_takens_1),
    .boreChildrenBd_bore_addr(childBd_20_addr),
    .boreChildrenBd_bore_addr_rd(childBd_20_addr_rd),
    .boreChildrenBd_bore_wdata(childBd_20_wdata),
    .boreChildrenBd_bore_wmask(childBd_20_wmask),
    .boreChildrenBd_bore_re(childBd_20_re),
    .boreChildrenBd_bore_we(childBd_20_we),
    .boreChildrenBd_bore_rdata(childBd_20_rdata),
    .boreChildrenBd_bore_ack(childBd_20_ack),
    .boreChildrenBd_bore_selectedOH(childBd_20_selectedOH),
    .boreChildrenBd_bore_array(childBd_20_array),
    .boreChildrenBd_bore_1_addr(childBd_21_addr),
    .boreChildrenBd_bore_1_addr_rd(childBd_21_addr_rd),
    .boreChildrenBd_bore_1_wdata(childBd_21_wdata),
    .boreChildrenBd_bore_1_wmask(childBd_21_wmask),
    .boreChildrenBd_bore_1_re(childBd_21_re),
    .boreChildrenBd_bore_1_we(childBd_21_we),
    .boreChildrenBd_bore_1_rdata(childBd_21_rdata),
    .boreChildrenBd_bore_1_ack(childBd_21_ack),
    .boreChildrenBd_bore_1_selectedOH(childBd_21_selectedOH),
    .boreChildrenBd_bore_1_array(childBd_21_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_21_cgen)
  );
  SCTable scTables_0 (
    .clock(clock),
    .reset(reset),
    .io_req_valid(core_sc_req_valid),
    .io_req_bits_pc(core_sc_req_pc),
    .io_resp_ctrs_0_0(sc0_resp_00),
    .io_resp_ctrs_0_1(sc0_resp_01),
    .io_resp_ctrs_1_0(sc0_resp_10),
    .io_resp_ctrs_1_1(sc0_resp_11),
    .io_update_pc(sc0_upd_pc),
    .io_update_mask_0(sc0_upd_mask_0),
    .io_update_mask_1(sc0_upd_mask_1),
    .io_update_oldCtrs_0(sc0_upd_oldCtrs_0),
    .io_update_oldCtrs_1(sc0_upd_oldCtrs_1),
    .io_update_tagePreds_0(sc0_upd_tagePreds_0),
    .io_update_tagePreds_1(sc0_upd_tagePreds_1),
    .io_update_takens_0(sc0_upd_takens_0),
    .io_update_takens_1(sc0_upd_takens_1),
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
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_22_cgen)
  );
  SCTable_1 scTables_1 (
    .clock(clock),
    .reset(reset),
    .io_req_valid(core_sc_req_valid),
    .io_req_bits_pc(core_sc_req_pc),
    .io_req_bits_folded_hist_hist_12_folded_hist(io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_resp_ctrs_0_0(sc1_resp_00),
    .io_resp_ctrs_0_1(sc1_resp_01),
    .io_resp_ctrs_1_0(sc1_resp_10),
    .io_resp_ctrs_1_1(sc1_resp_11),
    .io_update_pc(sc1_upd_pc),
    .io_update_ghist(sc1_upd_ghist),
    .io_update_mask_0(sc1_upd_mask_0),
    .io_update_mask_1(sc1_upd_mask_1),
    .io_update_oldCtrs_0(sc1_upd_oldCtrs_0),
    .io_update_oldCtrs_1(sc1_upd_oldCtrs_1),
    .io_update_tagePreds_0(sc1_upd_tagePreds_0),
    .io_update_tagePreds_1(sc1_upd_tagePreds_1),
    .io_update_takens_0(sc1_upd_takens_0),
    .io_update_takens_1(sc1_upd_takens_1),
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
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_23_cgen)
  );
  SCTable_2 scTables_2 (
    .clock(clock),
    .reset(reset),
    .io_req_valid(core_sc_req_valid),
    .io_req_bits_pc(core_sc_req_pc),
    .io_req_bits_folded_hist_hist_11_folded_hist(io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_resp_ctrs_0_0(sc2_resp_00),
    .io_resp_ctrs_0_1(sc2_resp_01),
    .io_resp_ctrs_1_0(sc2_resp_10),
    .io_resp_ctrs_1_1(sc2_resp_11),
    .io_update_pc(sc2_upd_pc),
    .io_update_ghist(sc2_upd_ghist),
    .io_update_mask_0(sc2_upd_mask_0),
    .io_update_mask_1(sc2_upd_mask_1),
    .io_update_oldCtrs_0(sc2_upd_oldCtrs_0),
    .io_update_oldCtrs_1(sc2_upd_oldCtrs_1),
    .io_update_tagePreds_0(sc2_upd_tagePreds_0),
    .io_update_tagePreds_1(sc2_upd_tagePreds_1),
    .io_update_takens_0(sc2_upd_takens_0),
    .io_update_takens_1(sc2_upd_takens_1),
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
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_24_cgen)
  );
  SCTable_3 scTables_3 (
    .clock(clock),
    .reset(reset),
    .io_req_valid(core_sc_req_valid),
    .io_req_bits_pc(core_sc_req_pc),
    .io_req_bits_folded_hist_hist_2_folded_hist(io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_resp_ctrs_0_0(sc3_resp_00),
    .io_resp_ctrs_0_1(sc3_resp_01),
    .io_resp_ctrs_1_0(sc3_resp_10),
    .io_resp_ctrs_1_1(sc3_resp_11),
    .io_update_pc(sc3_upd_pc),
    .io_update_ghist(sc3_upd_ghist),
    .io_update_mask_0(sc3_upd_mask_0),
    .io_update_mask_1(sc3_upd_mask_1),
    .io_update_oldCtrs_0(sc3_upd_oldCtrs_0),
    .io_update_oldCtrs_1(sc3_upd_oldCtrs_1),
    .io_update_tagePreds_0(sc3_upd_tagePreds_0),
    .io_update_tagePreds_1(sc3_upd_tagePreds_1),
    .io_update_takens_0(sc3_upd_takens_0),
    .io_update_takens_1(sc3_upd_takens_1),
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
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_25_cgen)
  );
  MaxPeriodFibonacciLFSR allocLFSR_prng (
    .clock(clock),
    .reset(reset),
    .io_out_0(lfsr0_out_0),
    .io_out_1(lfsr0_out_1),
    .io_out_2(lfsr0_out_2)
  );
  MaxPeriodFibonacciLFSR allocLFSR_prng_1 (
    .clock(clock),
    .reset(reset),
    .io_out_0(lfsr1_out_0),
    .io_out_1(lfsr1_out_1),
    .io_out_2(lfsr1_out_2)
  );

  // ===== 可读核 =====
  xs_Tage_SC_core u_core (
    .clock(clock),
    .reset(reset),
    .io_reset_vector(io_reset_vector),
    .io_in_s0_pc('{io_in_bits_s0_pc_0, io_in_bits_s0_pc_1, io_in_bits_s0_pc_2, io_in_bits_s0_pc_3}),
    .io_s0_fire('{io_s0_fire_0, io_s0_fire_1, io_s0_fire_2, io_s0_fire_3}),
    .io_s1_fire('{io_s1_fire_0, io_s1_fire_1, io_s1_fire_2, io_s1_fire_3}),
    .io_s2_fire('{io_s2_fire_0, io_s2_fire_1, io_s2_fire_2, io_s2_fire_3}),
    .io_ctrl_tage_enable(io_ctrl_tage_enable),
    .io_ctrl_sc_enable(io_ctrl_sc_enable),
    .io_out_s2_taken('{'{core_s2_taken_0_0, core_s2_taken_0_1}, '{core_s2_taken_1_0, core_s2_taken_1_1}, '{core_s2_taken_2_0, core_s2_taken_2_1}, '{core_s2_taken_3_0, core_s2_taken_3_1}}),
    .io_out_s3_taken('{'{core_s3_taken_0_0, core_s3_taken_0_1}, '{core_s3_taken_1_0, core_s3_taken_1_1}, '{core_s3_taken_2_0, core_s3_taken_2_1}, '{core_s3_taken_3_0, core_s3_taken_3_1}}),
    .io_out_last_stage_meta(core_meta),
    .io_out_sc_disagree('{core_sc_disagree_0, core_sc_disagree_1}),
    .io_s1_ready(core_s1_ready),
    .io_update_valid(io_update_valid),
    .io_update_pc(io_update_bits_pc),
    .io_update_br_valid('{io_update_bits_ftb_entry_brSlots_0_valid, (io_update_bits_ftb_entry_tailSlot_valid & io_update_bits_ftb_entry_tailSlot_sharing)}),
    .io_update_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_tailSlot_sharing(io_update_bits_ftb_entry_tailSlot_sharing),
    .io_perf_0_value(io_perf_0_value),
    .io_perf_1_value(io_perf_1_value),
    .io_perf_2_value(io_perf_2_value),
    .io_update_strong_bias('{io_update_bits_ftb_entry_strong_bias_0, io_update_bits_ftb_entry_strong_bias_1}),
    .io_update_br_taken('{io_update_bits_br_taken_mask_0, io_update_bits_br_taken_mask_1}),
    .io_update_mispred('{io_update_bits_mispred_mask_0, io_update_bits_mispred_mask_1}),
    .io_update_meta(io_update_bits_meta),
    .io_update_ghist(io_update_bits_ghist),
    .tbl_req_valid(core_tbl_req_valid),
    .tbl_req_pc(core_tbl_req_pc),
    .tbl_req_ready('{t0_req_ready, t1_req_ready, t2_req_ready, t3_req_ready}),
    .tbl_resp_valid('{'{t0_resp_valid_0, t0_resp_valid_1}, '{t1_resp_valid_0, t1_resp_valid_1}, '{t2_resp_valid_0, t2_resp_valid_1}, '{t3_resp_valid_0, t3_resp_valid_1}}),
    .tbl_resp_ctr('{'{t0_resp_ctr_0, t0_resp_ctr_1}, '{t1_resp_ctr_0, t1_resp_ctr_1}, '{t2_resp_ctr_0, t2_resp_ctr_1}, '{t3_resp_ctr_0, t3_resp_ctr_1}}),
    .tbl_resp_u('{'{t0_resp_u_0, t0_resp_u_1}, '{t1_resp_u_0, t1_resp_u_1}, '{t2_resp_u_0, t2_resp_u_1}, '{t3_resp_u_0, t3_resp_u_1}}),
    .tbl_resp_unconf('{'{t0_resp_unconf_0, t0_resp_unconf_1}, '{t1_resp_unconf_0, t1_resp_unconf_1}, '{t2_resp_unconf_0, t2_resp_unconf_1}, '{t3_resp_unconf_0, t3_resp_unconf_1}}),
    .tbl_upd_pc('{t0_upd_pc, t1_upd_pc, t2_upd_pc, t3_upd_pc}),
    .tbl_upd_ghist('{t0_upd_ghist, t1_upd_ghist, t2_upd_ghist, t3_upd_ghist}),
    .tbl_upd_mask('{'{t0_upd_mask_0, t0_upd_mask_1}, '{t1_upd_mask_0, t1_upd_mask_1}, '{t2_upd_mask_0, t2_upd_mask_1}, '{t3_upd_mask_0, t3_upd_mask_1}}),
    .tbl_upd_takens('{'{t0_upd_takens_0, t0_upd_takens_1}, '{t1_upd_takens_0, t1_upd_takens_1}, '{t2_upd_takens_0, t2_upd_takens_1}, '{t3_upd_takens_0, t3_upd_takens_1}}),
    .tbl_upd_alloc('{'{t0_upd_alloc_0, t0_upd_alloc_1}, '{t1_upd_alloc_0, t1_upd_alloc_1}, '{t2_upd_alloc_0, t2_upd_alloc_1}, '{t3_upd_alloc_0, t3_upd_alloc_1}}),
    .tbl_upd_oldCtrs('{'{t0_upd_oldCtrs_0, t0_upd_oldCtrs_1}, '{t1_upd_oldCtrs_0, t1_upd_oldCtrs_1}, '{t2_upd_oldCtrs_0, t2_upd_oldCtrs_1}, '{t3_upd_oldCtrs_0, t3_upd_oldCtrs_1}}),
    .tbl_upd_uMask('{'{t0_upd_uMask_0, t0_upd_uMask_1}, '{t1_upd_uMask_0, t1_upd_uMask_1}, '{t2_upd_uMask_0, t2_upd_uMask_1}, '{t3_upd_uMask_0, t3_upd_uMask_1}}),
    .tbl_upd_us('{'{t0_upd_us_0, t0_upd_us_1}, '{t1_upd_us_0, t1_upd_us_1}, '{t2_upd_us_0, t2_upd_us_1}, '{t3_upd_us_0, t3_upd_us_1}}),
    .tbl_upd_reset_u('{'{t0_upd_reset_u_0, t0_upd_reset_u_1}, '{t1_upd_reset_u_0, t1_upd_reset_u_1}, '{t2_upd_reset_u_0, t2_upd_reset_u_1}, '{t3_upd_reset_u_0, t3_upd_reset_u_1}}),
    .bt_req_valid(core_bt_req_valid),
    .bt_req_pc(core_bt_req_pc),
    .bt_req_ready(bt_req_ready),
    .bt_s1_cnt('{bt_s1_cnt_0, bt_s1_cnt_1}),
    .bt_upd_mask('{bt_upd_mask_0, bt_upd_mask_1}),
    .bt_upd_pc(bt_upd_pc),
    .bt_upd_cnt('{bt_upd_cnt_0, bt_upd_cnt_1}),
    .bt_upd_takens('{bt_upd_takens_0, bt_upd_takens_1}),
    .sc_req_valid(core_sc_req_valid),
    .sc_req_pc(core_sc_req_pc),
    .sc_resp_ctrs('{'{'{sc0_resp_00, sc0_resp_01}, '{sc0_resp_10, sc0_resp_11}}, '{'{sc1_resp_00, sc1_resp_01}, '{sc1_resp_10, sc1_resp_11}}, '{'{sc2_resp_00, sc2_resp_01}, '{sc2_resp_10, sc2_resp_11}}, '{'{sc3_resp_00, sc3_resp_01}, '{sc3_resp_10, sc3_resp_11}}}),
    .sc_upd_pc('{sc0_upd_pc, sc1_upd_pc, sc2_upd_pc, sc3_upd_pc}),
    .sc_upd_ghist('{sc0_upd_ghist, sc1_upd_ghist, sc2_upd_ghist, sc3_upd_ghist}),
    .sc_upd_mask('{'{sc0_upd_mask_0, sc0_upd_mask_1}, '{sc1_upd_mask_0, sc1_upd_mask_1}, '{sc2_upd_mask_0, sc2_upd_mask_1}, '{sc3_upd_mask_0, sc3_upd_mask_1}}),
    .sc_upd_oldCtrs('{'{sc0_upd_oldCtrs_0, sc0_upd_oldCtrs_1}, '{sc1_upd_oldCtrs_0, sc1_upd_oldCtrs_1}, '{sc2_upd_oldCtrs_0, sc2_upd_oldCtrs_1}, '{sc3_upd_oldCtrs_0, sc3_upd_oldCtrs_1}}),
    .sc_upd_tagePreds('{'{sc0_upd_tagePreds_0, sc0_upd_tagePreds_1}, '{sc1_upd_tagePreds_0, sc1_upd_tagePreds_1}, '{sc2_upd_tagePreds_0, sc2_upd_tagePreds_1}, '{sc3_upd_tagePreds_0, sc3_upd_tagePreds_1}}),
    .sc_upd_takens('{'{sc0_upd_takens_0, sc0_upd_takens_1}, '{sc1_upd_takens_0, sc1_upd_takens_1}, '{sc2_upd_takens_0, sc2_upd_takens_1}, '{sc3_upd_takens_0, sc3_upd_takens_1}}),
    .alloc_lfsr('{{1'b0, lfsr0_out_2, lfsr0_out_1, lfsr0_out_0}, {1'b0, lfsr1_out_2, lfsr1_out_1, lfsr1_out_0}})
  );

  // ===== 输出连接 =====
  assign io_out_s2_full_pred_0_br_taken_mask_0 = core_s2_taken_0_0;
  assign io_out_s3_full_pred_0_br_taken_mask_0 = core_s3_taken_0_0;
  assign io_out_s2_full_pred_0_br_taken_mask_1 = core_s2_taken_0_1;
  assign io_out_s3_full_pred_0_br_taken_mask_1 = core_s3_taken_0_1;
  assign io_out_s2_full_pred_1_br_taken_mask_0 = core_s2_taken_1_0;
  assign io_out_s3_full_pred_1_br_taken_mask_0 = core_s3_taken_1_0;
  assign io_out_s2_full_pred_1_br_taken_mask_1 = core_s2_taken_1_1;
  assign io_out_s3_full_pred_1_br_taken_mask_1 = core_s3_taken_1_1;
  assign io_out_s2_full_pred_2_br_taken_mask_0 = core_s2_taken_2_0;
  assign io_out_s3_full_pred_2_br_taken_mask_0 = core_s3_taken_2_0;
  assign io_out_s2_full_pred_2_br_taken_mask_1 = core_s2_taken_2_1;
  assign io_out_s3_full_pred_2_br_taken_mask_1 = core_s3_taken_2_1;
  assign io_out_s2_full_pred_3_br_taken_mask_0 = core_s2_taken_3_0;
  assign io_out_s3_full_pred_3_br_taken_mask_0 = core_s3_taken_3_0;
  assign io_out_s2_full_pred_3_br_taken_mask_1 = core_s2_taken_3_1;
  assign io_out_s3_full_pred_3_br_taken_mask_1 = core_s3_taken_3_1;
  assign io_out_last_stage_meta = core_meta;
  assign io_out_last_stage_spec_info_sc_disagree_0 = core_sc_disagree_0;
  assign io_out_last_stage_spec_info_sc_disagree_1 = core_sc_disagree_1;
  assign io_s1_ready = core_s1_ready;
  // mbist bore 上行输出（golden 7605-7606 行；漏接会使输出口悬空 X → FM 失配）
  assign boreChildrenBd_bore_ack = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;
endmodule