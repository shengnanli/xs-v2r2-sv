// tb.sv —— Predictor UT：golden `Predictor` 与重写 `Predictor_xs` 双例化，
//          同激励逐拍比全部 125 个输出。本文件由 gen_tb.py 从 golden 端口表生成。
//
// 两侧共用同一份 golden Composer（及其 5 个预测器闭包）——本 UT 只验 Predictor
// 这一层的流水控制与全局历史管理，预测器本身另有各自的签核。
//
// 激励设计见 gen_tb.py 头注释：shift 约束在 0..2、redirect/update 稀疏、
// histPtr 跟随 DUT 自己吐出的 last_stage_spec_info_histPtr。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  longint errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ---- 输入信号（两侧共用） ----
  logic  io_bpu_to_ftq_resp_ready;
  logic  io_ftq_to_bpu_redirect_valid;
  logic  io_ftq_to_bpu_redirect_bits_level;
  logic [49:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_pc;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp;
  logic [2:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag;
  logic [7:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit;
  logic [49:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_target;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_taken;
  logic [1:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_shift;
  logic  io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist;
  logic  io_ftq_to_bpu_redirect_bits_debugIsCtrl;
  logic  io_ftq_to_bpu_redirect_bits_debugIsMemVio;
  logic  io_ftq_to_bpu_redirect_bits_BTBMissBubble;
  logic  io_ftq_to_bpu_update_valid;
  logic [49:0] io_ftq_to_bpu_update_bits_pc;
  logic [7:0] io_ftq_to_bpu_update_bits_spec_info_histPtr_value;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_isCall;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_isRet;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_isJalr;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_valid;
  logic [3:0] io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid;
  logic [11:0] io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower;
  logic [1:0] io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0] io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid;
  logic [19:0] io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower;
  logic [1:0] io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0] io_ftq_to_bpu_update_bits_ftb_entry_pftAddr;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_carry;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0;
  logic  io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1;
  logic  io_ftq_to_bpu_update_bits_cfi_idx_valid;
  logic [3:0] io_ftq_to_bpu_update_bits_cfi_idx_bits;
  logic  io_ftq_to_bpu_update_bits_br_taken_mask_0;
  logic  io_ftq_to_bpu_update_bits_br_taken_mask_1;
  logic  io_ftq_to_bpu_update_bits_jmp_taken;
  logic  io_ftq_to_bpu_update_bits_mispred_mask_0;
  logic  io_ftq_to_bpu_update_bits_mispred_mask_1;
  logic  io_ftq_to_bpu_update_bits_mispred_mask_2;
  logic  io_ftq_to_bpu_update_bits_false_hit;
  logic  io_ftq_to_bpu_update_bits_old_entry;
  logic [515:0] io_ftq_to_bpu_update_bits_meta;
  logic [49:0] io_ftq_to_bpu_update_bits_full_target;
  logic  io_ftq_to_bpu_enq_ptr_flag;
  logic [5:0] io_ftq_to_bpu_enq_ptr_value;
  logic  io_ftq_to_bpu_redirctFromIFU;
  logic  io_ctrl_ubtb_enable;
  logic  io_ctrl_btb_enable;
  logic  io_ctrl_tage_enable;
  logic  io_ctrl_sc_enable;
  logic  io_ctrl_ras_enable;
  logic [47:0] io_reset_vector;
  logic [5:0] boreChildrenBd_bore_array;
  logic  boreChildrenBd_bore_all;
  logic  boreChildrenBd_bore_req;
  logic  boreChildrenBd_bore_writeen;
  logic [3:0] boreChildrenBd_bore_be;
  logic [9:0] boreChildrenBd_bore_addr;
  logic [39:0] boreChildrenBd_bore_indata;
  logic  boreChildrenBd_bore_readen;
  logic [9:0] boreChildrenBd_bore_addr_rd;
  logic [6:0] boreChildrenBd_bore_1_array;
  logic  boreChildrenBd_bore_1_all;
  logic  boreChildrenBd_bore_1_req;
  logic  boreChildrenBd_bore_1_writeen;
  logic [15:0] boreChildrenBd_bore_1_be;
  logic [9:0] boreChildrenBd_bore_1_addr;
  logic [23:0] boreChildrenBd_bore_1_indata;
  logic  boreChildrenBd_bore_1_readen;
  logic [9:0] boreChildrenBd_bore_1_addr_rd;
  logic [6:0] boreChildrenBd_bore_2_array;
  logic  boreChildrenBd_bore_2_all;
  logic  boreChildrenBd_bore_2_req;
  logic  boreChildrenBd_bore_2_writeen;
  logic [3:0] boreChildrenBd_bore_2_be;
  logic [7:0] boreChildrenBd_bore_2_addr;
  logic [23:0] boreChildrenBd_bore_2_indata;
  logic  boreChildrenBd_bore_2_readen;
  logic [7:0] boreChildrenBd_bore_2_addr_rd;
  logic [6:0] boreChildrenBd_bore_3_array;
  logic  boreChildrenBd_bore_3_all;
  logic  boreChildrenBd_bore_3_req;
  logic  boreChildrenBd_bore_3_writeen;
  logic [3:0] boreChildrenBd_bore_3_be;
  logic [7:0] boreChildrenBd_bore_3_addr;
  logic [23:0] boreChildrenBd_bore_3_indata;
  logic  boreChildrenBd_bore_3_readen;
  logic [7:0] boreChildrenBd_bore_3_addr_rd;
  logic [6:0] boreChildrenBd_bore_4_array;
  logic  boreChildrenBd_bore_4_all;
  logic  boreChildrenBd_bore_4_req;
  logic  boreChildrenBd_bore_4_writeen;
  logic [3:0] boreChildrenBd_bore_4_be;
  logic [7:0] boreChildrenBd_bore_4_addr;
  logic [23:0] boreChildrenBd_bore_4_indata;
  logic  boreChildrenBd_bore_4_readen;
  logic [7:0] boreChildrenBd_bore_4_addr_rd;
  logic [6:0] boreChildrenBd_bore_5_array;
  logic  boreChildrenBd_bore_5_all;
  logic  boreChildrenBd_bore_5_req;
  logic  boreChildrenBd_bore_5_writeen;
  logic [3:0] boreChildrenBd_bore_5_be;
  logic [7:0] boreChildrenBd_bore_5_addr;
  logic [23:0] boreChildrenBd_bore_5_indata;
  logic  boreChildrenBd_bore_5_readen;
  logic [7:0] boreChildrenBd_bore_5_addr_rd;
  logic [6:0] boreChildrenBd_bore_6_array;
  logic  boreChildrenBd_bore_6_all;
  logic  boreChildrenBd_bore_6_req;
  logic  boreChildrenBd_bore_6_writeen;
  logic [75:0] boreChildrenBd_bore_6_be;
  logic [7:0] boreChildrenBd_bore_6_addr;
  logic [75:0] boreChildrenBd_bore_6_indata;
  logic  boreChildrenBd_bore_6_readen;
  logic [7:0] boreChildrenBd_bore_6_addr_rd;
  logic [6:0] boreChildrenBd_bore_7_array;
  logic  boreChildrenBd_bore_7_all;
  logic  boreChildrenBd_bore_7_req;
  logic  boreChildrenBd_bore_7_writeen;
  logic [75:0] boreChildrenBd_bore_7_be;
  logic [7:0] boreChildrenBd_bore_7_addr;
  logic [75:0] boreChildrenBd_bore_7_indata;
  logic  boreChildrenBd_bore_7_readen;
  logic [7:0] boreChildrenBd_bore_7_addr_rd;
  logic [6:0] boreChildrenBd_bore_8_array;
  logic  boreChildrenBd_bore_8_all;
  logic  boreChildrenBd_bore_8_req;
  logic  boreChildrenBd_bore_8_writeen;
  logic [75:0] boreChildrenBd_bore_8_be;
  logic [7:0] boreChildrenBd_bore_8_addr;
  logic [75:0] boreChildrenBd_bore_8_indata;
  logic  boreChildrenBd_bore_8_readen;
  logic [7:0] boreChildrenBd_bore_8_addr_rd;
  logic [6:0] boreChildrenBd_bore_9_array;
  logic  boreChildrenBd_bore_9_all;
  logic  boreChildrenBd_bore_9_req;
  logic  boreChildrenBd_bore_9_writeen;
  logic [75:0] boreChildrenBd_bore_9_be;
  logic [7:0] boreChildrenBd_bore_9_addr;
  logic [75:0] boreChildrenBd_bore_9_indata;
  logic  boreChildrenBd_bore_9_readen;
  logic [7:0] boreChildrenBd_bore_9_addr_rd;
  logic [6:0] boreChildrenBd_bore_10_array;
  logic  boreChildrenBd_bore_10_all;
  logic  boreChildrenBd_bore_10_req;
  logic  boreChildrenBd_bore_10_writeen;
  logic [75:0] boreChildrenBd_bore_10_be;
  logic [7:0] boreChildrenBd_bore_10_addr;
  logic [75:0] boreChildrenBd_bore_10_indata;
  logic  boreChildrenBd_bore_10_readen;
  logic [7:0] boreChildrenBd_bore_10_addr_rd;
  logic  sigFromSrams_bore_ram_hold;
  logic  sigFromSrams_bore_ram_bypass;
  logic  sigFromSrams_bore_ram_bp_clken;
  logic  sigFromSrams_bore_ram_aux_clk;
  logic  sigFromSrams_bore_ram_aux_ckbp;
  logic  sigFromSrams_bore_ram_mcp_hold;
  logic  sigFromSrams_bore_cgen;
  logic  sigFromSrams_bore_1_ram_hold;
  logic  sigFromSrams_bore_1_ram_bypass;
  logic  sigFromSrams_bore_1_ram_bp_clken;
  logic  sigFromSrams_bore_1_ram_aux_clk;
  logic  sigFromSrams_bore_1_ram_aux_ckbp;
  logic  sigFromSrams_bore_1_ram_mcp_hold;
  logic  sigFromSrams_bore_1_cgen;
  logic  sigFromSrams_bore_2_ram_hold;
  logic  sigFromSrams_bore_2_ram_bypass;
  logic  sigFromSrams_bore_2_ram_bp_clken;
  logic  sigFromSrams_bore_2_ram_aux_clk;
  logic  sigFromSrams_bore_2_ram_aux_ckbp;
  logic  sigFromSrams_bore_2_ram_mcp_hold;
  logic  sigFromSrams_bore_2_cgen;
  logic  sigFromSrams_bore_3_ram_hold;
  logic  sigFromSrams_bore_3_ram_bypass;
  logic  sigFromSrams_bore_3_ram_bp_clken;
  logic  sigFromSrams_bore_3_ram_aux_clk;
  logic  sigFromSrams_bore_3_ram_aux_ckbp;
  logic  sigFromSrams_bore_3_ram_mcp_hold;
  logic  sigFromSrams_bore_3_cgen;
  logic  sigFromSrams_bore_4_ram_hold;
  logic  sigFromSrams_bore_4_ram_bypass;
  logic  sigFromSrams_bore_4_ram_bp_clken;
  logic  sigFromSrams_bore_4_ram_aux_clk;
  logic  sigFromSrams_bore_4_ram_aux_ckbp;
  logic  sigFromSrams_bore_4_ram_mcp_hold;
  logic  sigFromSrams_bore_4_cgen;
  logic  sigFromSrams_bore_5_ram_hold;
  logic  sigFromSrams_bore_5_ram_bypass;
  logic  sigFromSrams_bore_5_ram_bp_clken;
  logic  sigFromSrams_bore_5_ram_aux_clk;
  logic  sigFromSrams_bore_5_ram_aux_ckbp;
  logic  sigFromSrams_bore_5_ram_mcp_hold;
  logic  sigFromSrams_bore_5_cgen;
  logic  sigFromSrams_bore_6_ram_hold;
  logic  sigFromSrams_bore_6_ram_bypass;
  logic  sigFromSrams_bore_6_ram_bp_clken;
  logic  sigFromSrams_bore_6_ram_aux_clk;
  logic  sigFromSrams_bore_6_ram_aux_ckbp;
  logic  sigFromSrams_bore_6_ram_mcp_hold;
  logic  sigFromSrams_bore_6_cgen;
  logic  sigFromSrams_bore_7_ram_hold;
  logic  sigFromSrams_bore_7_ram_bypass;
  logic  sigFromSrams_bore_7_ram_bp_clken;
  logic  sigFromSrams_bore_7_ram_aux_clk;
  logic  sigFromSrams_bore_7_ram_aux_ckbp;
  logic  sigFromSrams_bore_7_ram_mcp_hold;
  logic  sigFromSrams_bore_7_cgen;
  logic  sigFromSrams_bore_8_ram_hold;
  logic  sigFromSrams_bore_8_ram_bypass;
  logic  sigFromSrams_bore_8_ram_bp_clken;
  logic  sigFromSrams_bore_8_ram_aux_clk;
  logic  sigFromSrams_bore_8_ram_aux_ckbp;
  logic  sigFromSrams_bore_8_ram_mcp_hold;
  logic  sigFromSrams_bore_8_cgen;
  logic  sigFromSrams_bore_9_ram_hold;
  logic  sigFromSrams_bore_9_ram_bypass;
  logic  sigFromSrams_bore_9_ram_bp_clken;
  logic  sigFromSrams_bore_9_ram_aux_clk;
  logic  sigFromSrams_bore_9_ram_aux_ckbp;
  logic  sigFromSrams_bore_9_ram_mcp_hold;
  logic  sigFromSrams_bore_9_cgen;
  logic  sigFromSrams_bore_10_ram_hold;
  logic  sigFromSrams_bore_10_ram_bypass;
  logic  sigFromSrams_bore_10_ram_bp_clken;
  logic  sigFromSrams_bore_10_ram_aux_clk;
  logic  sigFromSrams_bore_10_ram_aux_ckbp;
  logic  sigFromSrams_bore_10_ram_mcp_hold;
  logic  sigFromSrams_bore_10_cgen;
  logic  sigFromSrams_bore_11_ram_hold;
  logic  sigFromSrams_bore_11_ram_bypass;
  logic  sigFromSrams_bore_11_ram_bp_clken;
  logic  sigFromSrams_bore_11_ram_aux_clk;
  logic  sigFromSrams_bore_11_ram_aux_ckbp;
  logic  sigFromSrams_bore_11_ram_mcp_hold;
  logic  sigFromSrams_bore_11_cgen;
  logic  sigFromSrams_bore_12_ram_hold;
  logic  sigFromSrams_bore_12_ram_bypass;
  logic  sigFromSrams_bore_12_ram_bp_clken;
  logic  sigFromSrams_bore_12_ram_aux_clk;
  logic  sigFromSrams_bore_12_ram_aux_ckbp;
  logic  sigFromSrams_bore_12_ram_mcp_hold;
  logic  sigFromSrams_bore_12_cgen;
  logic  sigFromSrams_bore_13_ram_hold;
  logic  sigFromSrams_bore_13_ram_bypass;
  logic  sigFromSrams_bore_13_ram_bp_clken;
  logic  sigFromSrams_bore_13_ram_aux_clk;
  logic  sigFromSrams_bore_13_ram_aux_ckbp;
  logic  sigFromSrams_bore_13_ram_mcp_hold;
  logic  sigFromSrams_bore_13_cgen;
  logic  sigFromSrams_bore_14_ram_hold;
  logic  sigFromSrams_bore_14_ram_bypass;
  logic  sigFromSrams_bore_14_ram_bp_clken;
  logic  sigFromSrams_bore_14_ram_aux_clk;
  logic  sigFromSrams_bore_14_ram_aux_ckbp;
  logic  sigFromSrams_bore_14_ram_mcp_hold;
  logic  sigFromSrams_bore_14_cgen;
  logic  sigFromSrams_bore_15_ram_hold;
  logic  sigFromSrams_bore_15_ram_bypass;
  logic  sigFromSrams_bore_15_ram_bp_clken;
  logic  sigFromSrams_bore_15_ram_aux_clk;
  logic  sigFromSrams_bore_15_ram_aux_ckbp;
  logic  sigFromSrams_bore_15_ram_mcp_hold;
  logic  sigFromSrams_bore_15_cgen;
  logic  sigFromSrams_bore_16_ram_hold;
  logic  sigFromSrams_bore_16_ram_bypass;
  logic  sigFromSrams_bore_16_ram_bp_clken;
  logic  sigFromSrams_bore_16_ram_aux_clk;
  logic  sigFromSrams_bore_16_ram_aux_ckbp;
  logic  sigFromSrams_bore_16_ram_mcp_hold;
  logic  sigFromSrams_bore_16_cgen;
  logic  sigFromSrams_bore_17_ram_hold;
  logic  sigFromSrams_bore_17_ram_bypass;
  logic  sigFromSrams_bore_17_ram_bp_clken;
  logic  sigFromSrams_bore_17_ram_aux_clk;
  logic  sigFromSrams_bore_17_ram_aux_ckbp;
  logic  sigFromSrams_bore_17_ram_mcp_hold;
  logic  sigFromSrams_bore_17_cgen;
  logic  sigFromSrams_bore_18_ram_hold;
  logic  sigFromSrams_bore_18_ram_bypass;
  logic  sigFromSrams_bore_18_ram_bp_clken;
  logic  sigFromSrams_bore_18_ram_aux_clk;
  logic  sigFromSrams_bore_18_ram_aux_ckbp;
  logic  sigFromSrams_bore_18_ram_mcp_hold;
  logic  sigFromSrams_bore_18_cgen;
  logic  sigFromSrams_bore_19_ram_hold;
  logic  sigFromSrams_bore_19_ram_bypass;
  logic  sigFromSrams_bore_19_ram_bp_clken;
  logic  sigFromSrams_bore_19_ram_aux_clk;
  logic  sigFromSrams_bore_19_ram_aux_ckbp;
  logic  sigFromSrams_bore_19_ram_mcp_hold;
  logic  sigFromSrams_bore_19_cgen;
  logic  sigFromSrams_bore_20_ram_hold;
  logic  sigFromSrams_bore_20_ram_bypass;
  logic  sigFromSrams_bore_20_ram_bp_clken;
  logic  sigFromSrams_bore_20_ram_aux_clk;
  logic  sigFromSrams_bore_20_ram_aux_ckbp;
  logic  sigFromSrams_bore_20_ram_mcp_hold;
  logic  sigFromSrams_bore_20_cgen;
  logic  sigFromSrams_bore_21_ram_hold;
  logic  sigFromSrams_bore_21_ram_bypass;
  logic  sigFromSrams_bore_21_ram_bp_clken;
  logic  sigFromSrams_bore_21_ram_aux_clk;
  logic  sigFromSrams_bore_21_ram_aux_ckbp;
  logic  sigFromSrams_bore_21_ram_mcp_hold;
  logic  sigFromSrams_bore_21_cgen;
  logic  sigFromSrams_bore_22_ram_hold;
  logic  sigFromSrams_bore_22_ram_bypass;
  logic  sigFromSrams_bore_22_ram_bp_clken;
  logic  sigFromSrams_bore_22_ram_aux_clk;
  logic  sigFromSrams_bore_22_ram_aux_ckbp;
  logic  sigFromSrams_bore_22_ram_mcp_hold;
  logic  sigFromSrams_bore_22_cgen;
  logic  sigFromSrams_bore_23_ram_hold;
  logic  sigFromSrams_bore_23_ram_bypass;
  logic  sigFromSrams_bore_23_ram_bp_clken;
  logic  sigFromSrams_bore_23_ram_aux_clk;
  logic  sigFromSrams_bore_23_ram_aux_ckbp;
  logic  sigFromSrams_bore_23_ram_mcp_hold;
  logic  sigFromSrams_bore_23_cgen;
  logic  sigFromSrams_bore_24_ram_hold;
  logic  sigFromSrams_bore_24_ram_bypass;
  logic  sigFromSrams_bore_24_ram_bp_clken;
  logic  sigFromSrams_bore_24_ram_aux_clk;
  logic  sigFromSrams_bore_24_ram_aux_ckbp;
  logic  sigFromSrams_bore_24_ram_mcp_hold;
  logic  sigFromSrams_bore_24_cgen;
  logic  sigFromSrams_bore_25_ram_hold;
  logic  sigFromSrams_bore_25_ram_bypass;
  logic  sigFromSrams_bore_25_ram_bp_clken;
  logic  sigFromSrams_bore_25_ram_aux_clk;
  logic  sigFromSrams_bore_25_ram_aux_ckbp;
  logic  sigFromSrams_bore_25_ram_mcp_hold;
  logic  sigFromSrams_bore_25_cgen;
  logic  sigFromSrams_bore_26_ram_hold;
  logic  sigFromSrams_bore_26_ram_bypass;
  logic  sigFromSrams_bore_26_ram_bp_clken;
  logic  sigFromSrams_bore_26_ram_aux_clk;
  logic  sigFromSrams_bore_26_ram_aux_ckbp;
  logic  sigFromSrams_bore_26_ram_mcp_hold;
  logic  sigFromSrams_bore_26_cgen;
  logic  sigFromSrams_bore_27_ram_hold;
  logic  sigFromSrams_bore_27_ram_bypass;
  logic  sigFromSrams_bore_27_ram_bp_clken;
  logic  sigFromSrams_bore_27_ram_aux_clk;
  logic  sigFromSrams_bore_27_ram_aux_ckbp;
  logic  sigFromSrams_bore_27_ram_mcp_hold;
  logic  sigFromSrams_bore_27_cgen;
  logic  sigFromSrams_bore_28_ram_hold;
  logic  sigFromSrams_bore_28_ram_bypass;
  logic  sigFromSrams_bore_28_ram_bp_clken;
  logic  sigFromSrams_bore_28_ram_aux_clk;
  logic  sigFromSrams_bore_28_ram_aux_ckbp;
  logic  sigFromSrams_bore_28_ram_mcp_hold;
  logic  sigFromSrams_bore_28_cgen;
  logic  sigFromSrams_bore_29_ram_hold;
  logic  sigFromSrams_bore_29_ram_bypass;
  logic  sigFromSrams_bore_29_ram_bp_clken;
  logic  sigFromSrams_bore_29_ram_aux_clk;
  logic  sigFromSrams_bore_29_ram_aux_ckbp;
  logic  sigFromSrams_bore_29_ram_mcp_hold;
  logic  sigFromSrams_bore_29_cgen;
  logic  sigFromSrams_bore_30_ram_hold;
  logic  sigFromSrams_bore_30_ram_bypass;
  logic  sigFromSrams_bore_30_ram_bp_clken;
  logic  sigFromSrams_bore_30_ram_aux_clk;
  logic  sigFromSrams_bore_30_ram_aux_ckbp;
  logic  sigFromSrams_bore_30_ram_mcp_hold;
  logic  sigFromSrams_bore_30_cgen;
  logic  sigFromSrams_bore_31_ram_hold;
  logic  sigFromSrams_bore_31_ram_bypass;
  logic  sigFromSrams_bore_31_ram_bp_clken;
  logic  sigFromSrams_bore_31_ram_aux_clk;
  logic  sigFromSrams_bore_31_ram_aux_ckbp;
  logic  sigFromSrams_bore_31_ram_mcp_hold;
  logic  sigFromSrams_bore_31_cgen;
  logic  sigFromSrams_bore_32_ram_hold;
  logic  sigFromSrams_bore_32_ram_bypass;
  logic  sigFromSrams_bore_32_ram_bp_clken;
  logic  sigFromSrams_bore_32_ram_aux_clk;
  logic  sigFromSrams_bore_32_ram_aux_ckbp;
  logic  sigFromSrams_bore_32_ram_mcp_hold;
  logic  sigFromSrams_bore_32_cgen;
  logic  sigFromSrams_bore_33_ram_hold;
  logic  sigFromSrams_bore_33_ram_bypass;
  logic  sigFromSrams_bore_33_ram_bp_clken;
  logic  sigFromSrams_bore_33_ram_aux_clk;
  logic  sigFromSrams_bore_33_ram_aux_ckbp;
  logic  sigFromSrams_bore_33_ram_mcp_hold;
  logic  sigFromSrams_bore_33_cgen;
  logic  sigFromSrams_bore_34_ram_hold;
  logic  sigFromSrams_bore_34_ram_bypass;
  logic  sigFromSrams_bore_34_ram_bp_clken;
  logic  sigFromSrams_bore_34_ram_aux_clk;
  logic  sigFromSrams_bore_34_ram_aux_ckbp;
  logic  sigFromSrams_bore_34_ram_mcp_hold;
  logic  sigFromSrams_bore_34_cgen;
  logic  sigFromSrams_bore_35_ram_hold;
  logic  sigFromSrams_bore_35_ram_bypass;
  logic  sigFromSrams_bore_35_ram_bp_clken;
  logic  sigFromSrams_bore_35_ram_aux_clk;
  logic  sigFromSrams_bore_35_ram_aux_ckbp;
  logic  sigFromSrams_bore_35_ram_mcp_hold;
  logic  sigFromSrams_bore_35_cgen;
  logic  sigFromSrams_bore_36_ram_hold;
  logic  sigFromSrams_bore_36_ram_bypass;
  logic  sigFromSrams_bore_36_ram_bp_clken;
  logic  sigFromSrams_bore_36_ram_aux_clk;
  logic  sigFromSrams_bore_36_ram_aux_ckbp;
  logic  sigFromSrams_bore_36_ram_mcp_hold;
  logic  sigFromSrams_bore_36_cgen;
  logic  sigFromSrams_bore_37_ram_hold;
  logic  sigFromSrams_bore_37_ram_bypass;
  logic  sigFromSrams_bore_37_ram_bp_clken;
  logic  sigFromSrams_bore_37_ram_aux_clk;
  logic  sigFromSrams_bore_37_ram_aux_ckbp;
  logic  sigFromSrams_bore_37_ram_mcp_hold;
  logic  sigFromSrams_bore_37_cgen;
  logic  sigFromSrams_bore_38_ram_hold;
  logic  sigFromSrams_bore_38_ram_bypass;
  logic  sigFromSrams_bore_38_ram_bp_clken;
  logic  sigFromSrams_bore_38_ram_aux_clk;
  logic  sigFromSrams_bore_38_ram_aux_ckbp;
  logic  sigFromSrams_bore_38_ram_mcp_hold;
  logic  sigFromSrams_bore_38_cgen;
  logic  sigFromSrams_bore_39_ram_hold;
  logic  sigFromSrams_bore_39_ram_bypass;
  logic  sigFromSrams_bore_39_ram_bp_clken;
  logic  sigFromSrams_bore_39_ram_aux_clk;
  logic  sigFromSrams_bore_39_ram_aux_ckbp;
  logic  sigFromSrams_bore_39_ram_mcp_hold;
  logic  sigFromSrams_bore_39_cgen;
  logic  sigFromSrams_bore_40_ram_hold;
  logic  sigFromSrams_bore_40_ram_bypass;
  logic  sigFromSrams_bore_40_ram_bp_clken;
  logic  sigFromSrams_bore_40_ram_aux_clk;
  logic  sigFromSrams_bore_40_ram_aux_ckbp;
  logic  sigFromSrams_bore_40_ram_mcp_hold;
  logic  sigFromSrams_bore_40_cgen;
  logic  sigFromSrams_bore_41_ram_hold;
  logic  sigFromSrams_bore_41_ram_bypass;
  logic  sigFromSrams_bore_41_ram_bp_clken;
  logic  sigFromSrams_bore_41_ram_aux_clk;
  logic  sigFromSrams_bore_41_ram_aux_ckbp;
  logic  sigFromSrams_bore_41_ram_mcp_hold;
  logic  sigFromSrams_bore_41_cgen;
  logic  sigFromSrams_bore_42_ram_hold;
  logic  sigFromSrams_bore_42_ram_bypass;
  logic  sigFromSrams_bore_42_ram_bp_clken;
  logic  sigFromSrams_bore_42_ram_aux_clk;
  logic  sigFromSrams_bore_42_ram_aux_ckbp;
  logic  sigFromSrams_bore_42_ram_mcp_hold;
  logic  sigFromSrams_bore_42_cgen;
  logic  sigFromSrams_bore_43_ram_hold;
  logic  sigFromSrams_bore_43_ram_bypass;
  logic  sigFromSrams_bore_43_ram_bp_clken;
  logic  sigFromSrams_bore_43_ram_aux_clk;
  logic  sigFromSrams_bore_43_ram_aux_ckbp;
  logic  sigFromSrams_bore_43_ram_mcp_hold;
  logic  sigFromSrams_bore_43_cgen;
  logic  sigFromSrams_bore_44_ram_hold;
  logic  sigFromSrams_bore_44_ram_bypass;
  logic  sigFromSrams_bore_44_ram_bp_clken;
  logic  sigFromSrams_bore_44_ram_aux_clk;
  logic  sigFromSrams_bore_44_ram_aux_ckbp;
  logic  sigFromSrams_bore_44_ram_mcp_hold;
  logic  sigFromSrams_bore_44_cgen;
  logic  sigFromSrams_bore_45_ram_hold;
  logic  sigFromSrams_bore_45_ram_bypass;
  logic  sigFromSrams_bore_45_ram_bp_clken;
  logic  sigFromSrams_bore_45_ram_aux_clk;
  logic  sigFromSrams_bore_45_ram_aux_ckbp;
  logic  sigFromSrams_bore_45_ram_mcp_hold;
  logic  sigFromSrams_bore_45_cgen;
  logic  sigFromSrams_bore_46_ram_hold;
  logic  sigFromSrams_bore_46_ram_bypass;
  logic  sigFromSrams_bore_46_ram_bp_clken;
  logic  sigFromSrams_bore_46_ram_aux_clk;
  logic  sigFromSrams_bore_46_ram_aux_ckbp;
  logic  sigFromSrams_bore_46_ram_mcp_hold;
  logic  sigFromSrams_bore_46_cgen;
  logic  sigFromSrams_bore_47_ram_hold;
  logic  sigFromSrams_bore_47_ram_bypass;
  logic  sigFromSrams_bore_47_ram_bp_clken;
  logic  sigFromSrams_bore_47_ram_aux_clk;
  logic  sigFromSrams_bore_47_ram_aux_ckbp;
  logic  sigFromSrams_bore_47_ram_mcp_hold;
  logic  sigFromSrams_bore_47_cgen;

  // ---- 每个输出两根线：g_<port> / i_<port> ----
  wire  g_io_bpu_to_ftq_resp_valid;
  wire  i_io_bpu_to_ftq_resp_valid;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s1_pc_3;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s1_pc_3;
  wire [63:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle;
  wire [63:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing;
  wire  g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit;
  wire  i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s2_pc_3;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s2_pc_3;
  wire  g_io_bpu_to_ftq_resp_bits_s2_valid_3;
  wire  i_io_bpu_to_ftq_resp_bits_s2_valid_3;
  wire  g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3;
  wire  i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3;
  wire  g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag;
  wire  i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag;
  wire [5:0] g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value;
  wire [5:0] i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value;
  wire [63:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle;
  wire [63:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing;
  wire  g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit;
  wire  i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_pc_0;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_pc_0;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_pc_3;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_pc_3;
  wire  g_io_bpu_to_ftq_resp_bits_s3_valid_0;
  wire  i_io_bpu_to_ftq_resp_bits_s3_valid_0;
  wire  g_io_bpu_to_ftq_resp_bits_s3_valid_3;
  wire  i_io_bpu_to_ftq_resp_bits_s3_valid_3;
  wire  g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3;
  wire  i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3;
  wire  g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag;
  wire  i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag;
  wire [5:0] g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value;
  wire [5:0] i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value;
  wire [63:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle;
  wire [63:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing;
  wire  g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit;
  wire  i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit;
  wire [515:0] g_io_bpu_to_ftq_resp_bits_last_stage_meta;
  wire [515:0] i_io_bpu_to_ftq_resp_bits_last_stage_meta;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
  wire [7:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
  wire [7:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp;
  wire [2:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr;
  wire [2:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag;
  wire [4:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value;
  wire [4:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag;
  wire [4:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value;
  wire [4:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag;
  wire [4:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value;
  wire [4:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower;
  wire [11:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [1:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower;
  wire [19:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat;
  wire [1:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0;
  wire  g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1;
  wire  i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9;
  wire  g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12;
  wire  i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  wire  g_boreChildrenBd_bore_ack;
  wire  i_boreChildrenBd_bore_ack;
  wire [39:0] g_boreChildrenBd_bore_outdata;
  wire [39:0] i_boreChildrenBd_bore_outdata;
  wire  g_boreChildrenBd_bore_1_ack;
  wire  i_boreChildrenBd_bore_1_ack;
  wire [23:0] g_boreChildrenBd_bore_1_outdata;
  wire [23:0] i_boreChildrenBd_bore_1_outdata;
  wire  g_boreChildrenBd_bore_2_ack;
  wire  i_boreChildrenBd_bore_2_ack;
  wire [23:0] g_boreChildrenBd_bore_2_outdata;
  wire [23:0] i_boreChildrenBd_bore_2_outdata;
  wire  g_boreChildrenBd_bore_3_ack;
  wire  i_boreChildrenBd_bore_3_ack;
  wire [23:0] g_boreChildrenBd_bore_3_outdata;
  wire [23:0] i_boreChildrenBd_bore_3_outdata;
  wire  g_boreChildrenBd_bore_4_ack;
  wire  i_boreChildrenBd_bore_4_ack;
  wire [23:0] g_boreChildrenBd_bore_4_outdata;
  wire [23:0] i_boreChildrenBd_bore_4_outdata;
  wire  g_boreChildrenBd_bore_5_ack;
  wire  i_boreChildrenBd_bore_5_ack;
  wire [23:0] g_boreChildrenBd_bore_5_outdata;
  wire [23:0] i_boreChildrenBd_bore_5_outdata;
  wire  g_boreChildrenBd_bore_6_ack;
  wire  i_boreChildrenBd_bore_6_ack;
  wire [75:0] g_boreChildrenBd_bore_6_outdata;
  wire [75:0] i_boreChildrenBd_bore_6_outdata;
  wire  g_boreChildrenBd_bore_7_ack;
  wire  i_boreChildrenBd_bore_7_ack;
  wire [75:0] g_boreChildrenBd_bore_7_outdata;
  wire [75:0] i_boreChildrenBd_bore_7_outdata;
  wire  g_boreChildrenBd_bore_8_ack;
  wire  i_boreChildrenBd_bore_8_ack;
  wire [75:0] g_boreChildrenBd_bore_8_outdata;
  wire [75:0] i_boreChildrenBd_bore_8_outdata;
  wire  g_boreChildrenBd_bore_9_ack;
  wire  i_boreChildrenBd_bore_9_ack;
  wire [75:0] g_boreChildrenBd_bore_9_outdata;
  wire [75:0] i_boreChildrenBd_bore_9_outdata;
  wire  g_boreChildrenBd_bore_10_ack;
  wire  i_boreChildrenBd_bore_10_ack;
  wire [75:0] g_boreChildrenBd_bore_10_outdata;
  wire [75:0] i_boreChildrenBd_bore_10_outdata;

  Predictor dut_g (
    .clock(clk), .reset(rst),
    .io_bpu_to_ftq_resp_ready(io_bpu_to_ftq_resp_ready),
    .io_ftq_to_bpu_redirect_valid(io_ftq_to_bpu_redirect_valid),
    .io_ftq_to_bpu_redirect_bits_level(io_ftq_to_bpu_redirect_bits_level),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pc(io_ftq_to_bpu_redirect_bits_cfiUpdate_pc),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp(io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr(io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_target(io_ftq_to_bpu_redirect_bits_cfiUpdate_target),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_taken(io_ftq_to_bpu_redirect_bits_cfiUpdate_taken),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_shift(io_ftq_to_bpu_redirect_bits_cfiUpdate_shift),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist(io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist),
    .io_ftq_to_bpu_redirect_bits_debugIsCtrl(io_ftq_to_bpu_redirect_bits_debugIsCtrl),
    .io_ftq_to_bpu_redirect_bits_debugIsMemVio(io_ftq_to_bpu_redirect_bits_debugIsMemVio),
    .io_ftq_to_bpu_redirect_bits_BTBMissBubble(io_ftq_to_bpu_redirect_bits_BTBMissBubble),
    .io_ftq_to_bpu_update_valid(io_ftq_to_bpu_update_valid),
    .io_ftq_to_bpu_update_bits_pc(io_ftq_to_bpu_update_bits_pc),
    .io_ftq_to_bpu_update_bits_spec_info_histPtr_value(io_ftq_to_bpu_update_bits_spec_info_histPtr_value),
    .io_ftq_to_bpu_update_bits_ftb_entry_isCall(io_ftq_to_bpu_update_bits_ftb_entry_isCall),
    .io_ftq_to_bpu_update_bits_ftb_entry_isRet(io_ftq_to_bpu_update_bits_ftb_entry_isRet),
    .io_ftq_to_bpu_update_bits_ftb_entry_isJalr(io_ftq_to_bpu_update_bits_ftb_entry_isJalr),
    .io_ftq_to_bpu_update_bits_ftb_entry_valid(io_ftq_to_bpu_update_bits_ftb_entry_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_ftq_to_bpu_update_bits_ftb_entry_pftAddr(io_ftq_to_bpu_update_bits_ftb_entry_pftAddr),
    .io_ftq_to_bpu_update_bits_ftb_entry_carry(io_ftq_to_bpu_update_bits_ftb_entry_carry),
    .io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call(io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0),
    .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1),
    .io_ftq_to_bpu_update_bits_cfi_idx_valid(io_ftq_to_bpu_update_bits_cfi_idx_valid),
    .io_ftq_to_bpu_update_bits_cfi_idx_bits(io_ftq_to_bpu_update_bits_cfi_idx_bits),
    .io_ftq_to_bpu_update_bits_br_taken_mask_0(io_ftq_to_bpu_update_bits_br_taken_mask_0),
    .io_ftq_to_bpu_update_bits_br_taken_mask_1(io_ftq_to_bpu_update_bits_br_taken_mask_1),
    .io_ftq_to_bpu_update_bits_jmp_taken(io_ftq_to_bpu_update_bits_jmp_taken),
    .io_ftq_to_bpu_update_bits_mispred_mask_0(io_ftq_to_bpu_update_bits_mispred_mask_0),
    .io_ftq_to_bpu_update_bits_mispred_mask_1(io_ftq_to_bpu_update_bits_mispred_mask_1),
    .io_ftq_to_bpu_update_bits_mispred_mask_2(io_ftq_to_bpu_update_bits_mispred_mask_2),
    .io_ftq_to_bpu_update_bits_false_hit(io_ftq_to_bpu_update_bits_false_hit),
    .io_ftq_to_bpu_update_bits_old_entry(io_ftq_to_bpu_update_bits_old_entry),
    .io_ftq_to_bpu_update_bits_meta(io_ftq_to_bpu_update_bits_meta),
    .io_ftq_to_bpu_update_bits_full_target(io_ftq_to_bpu_update_bits_full_target),
    .io_ftq_to_bpu_enq_ptr_flag(io_ftq_to_bpu_enq_ptr_flag),
    .io_ftq_to_bpu_enq_ptr_value(io_ftq_to_bpu_enq_ptr_value),
    .io_ftq_to_bpu_redirctFromIFU(io_ftq_to_bpu_redirctFromIFU),
    .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable),
    .io_ctrl_btb_enable(io_ctrl_btb_enable),
    .io_ctrl_tage_enable(io_ctrl_tage_enable),
    .io_ctrl_sc_enable(io_ctrl_sc_enable),
    .io_ctrl_ras_enable(io_ctrl_ras_enable),
    .io_reset_vector(io_reset_vector),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_2_array(boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_writeen(boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_3_array(boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all(boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req(boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_writeen(boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be(boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr(boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata(boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen(boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd(boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_4_array(boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all(boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req(boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_writeen(boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be(boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr(boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata(boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen(boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd(boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_5_array(boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_5_all(boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_5_req(boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_5_writeen(boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_5_be(boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_5_addr(boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_5_indata(boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_5_readen(boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_5_addr_rd(boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_6_array(boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_6_all(boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_6_req(boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_6_writeen(boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_6_be(boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_6_addr(boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_6_indata(boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_6_readen(boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_6_addr_rd(boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_7_array(boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_7_all(boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_7_req(boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_7_writeen(boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_7_be(boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_7_addr(boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_7_indata(boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_7_readen(boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_7_addr_rd(boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_8_array(boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_8_all(boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_8_req(boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_8_writeen(boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_8_be(boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_8_addr(boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_8_indata(boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_8_readen(boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_8_addr_rd(boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_9_array(boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_9_all(boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_9_req(boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_9_writeen(boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_9_be(boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_9_addr(boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_9_indata(boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_9_readen(boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_9_addr_rd(boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_10_array(boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_10_all(boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_10_req(boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_10_writeen(boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_10_be(boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_10_addr(boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_10_indata(boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_10_readen(boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_10_addr_rd(boreChildrenBd_bore_10_addr_rd),
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
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold(sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass(sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken(sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk(sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp(sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold(sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen(sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold(sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass(sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken(sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk(sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp(sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold(sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen(sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold(sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass(sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken(sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk(sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp(sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold(sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen(sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold(sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass(sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken(sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk(sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp(sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold(sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen(sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold(sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass(sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken(sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk(sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp(sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold(sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen(sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold(sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass(sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken(sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk(sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp(sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold(sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen(sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold(sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass(sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken(sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk(sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp(sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold(sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen(sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold(sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass(sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken(sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk(sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp(sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold(sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen(sigFromSrams_bore_39_cgen),
    .sigFromSrams_bore_40_ram_hold(sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_40_ram_bypass(sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_40_ram_bp_clken(sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_40_ram_aux_clk(sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_40_ram_aux_ckbp(sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_40_ram_mcp_hold(sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_40_cgen(sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_41_ram_hold(sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_41_ram_bypass(sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_41_ram_bp_clken(sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_41_ram_aux_clk(sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_41_ram_aux_ckbp(sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_41_ram_mcp_hold(sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_41_cgen(sigFromSrams_bore_41_cgen),
    .sigFromSrams_bore_42_ram_hold(sigFromSrams_bore_42_ram_hold),
    .sigFromSrams_bore_42_ram_bypass(sigFromSrams_bore_42_ram_bypass),
    .sigFromSrams_bore_42_ram_bp_clken(sigFromSrams_bore_42_ram_bp_clken),
    .sigFromSrams_bore_42_ram_aux_clk(sigFromSrams_bore_42_ram_aux_clk),
    .sigFromSrams_bore_42_ram_aux_ckbp(sigFromSrams_bore_42_ram_aux_ckbp),
    .sigFromSrams_bore_42_ram_mcp_hold(sigFromSrams_bore_42_ram_mcp_hold),
    .sigFromSrams_bore_42_cgen(sigFromSrams_bore_42_cgen),
    .sigFromSrams_bore_43_ram_hold(sigFromSrams_bore_43_ram_hold),
    .sigFromSrams_bore_43_ram_bypass(sigFromSrams_bore_43_ram_bypass),
    .sigFromSrams_bore_43_ram_bp_clken(sigFromSrams_bore_43_ram_bp_clken),
    .sigFromSrams_bore_43_ram_aux_clk(sigFromSrams_bore_43_ram_aux_clk),
    .sigFromSrams_bore_43_ram_aux_ckbp(sigFromSrams_bore_43_ram_aux_ckbp),
    .sigFromSrams_bore_43_ram_mcp_hold(sigFromSrams_bore_43_ram_mcp_hold),
    .sigFromSrams_bore_43_cgen(sigFromSrams_bore_43_cgen),
    .sigFromSrams_bore_44_ram_hold(sigFromSrams_bore_44_ram_hold),
    .sigFromSrams_bore_44_ram_bypass(sigFromSrams_bore_44_ram_bypass),
    .sigFromSrams_bore_44_ram_bp_clken(sigFromSrams_bore_44_ram_bp_clken),
    .sigFromSrams_bore_44_ram_aux_clk(sigFromSrams_bore_44_ram_aux_clk),
    .sigFromSrams_bore_44_ram_aux_ckbp(sigFromSrams_bore_44_ram_aux_ckbp),
    .sigFromSrams_bore_44_ram_mcp_hold(sigFromSrams_bore_44_ram_mcp_hold),
    .sigFromSrams_bore_44_cgen(sigFromSrams_bore_44_cgen),
    .sigFromSrams_bore_45_ram_hold(sigFromSrams_bore_45_ram_hold),
    .sigFromSrams_bore_45_ram_bypass(sigFromSrams_bore_45_ram_bypass),
    .sigFromSrams_bore_45_ram_bp_clken(sigFromSrams_bore_45_ram_bp_clken),
    .sigFromSrams_bore_45_ram_aux_clk(sigFromSrams_bore_45_ram_aux_clk),
    .sigFromSrams_bore_45_ram_aux_ckbp(sigFromSrams_bore_45_ram_aux_ckbp),
    .sigFromSrams_bore_45_ram_mcp_hold(sigFromSrams_bore_45_ram_mcp_hold),
    .sigFromSrams_bore_45_cgen(sigFromSrams_bore_45_cgen),
    .sigFromSrams_bore_46_ram_hold(sigFromSrams_bore_46_ram_hold),
    .sigFromSrams_bore_46_ram_bypass(sigFromSrams_bore_46_ram_bypass),
    .sigFromSrams_bore_46_ram_bp_clken(sigFromSrams_bore_46_ram_bp_clken),
    .sigFromSrams_bore_46_ram_aux_clk(sigFromSrams_bore_46_ram_aux_clk),
    .sigFromSrams_bore_46_ram_aux_ckbp(sigFromSrams_bore_46_ram_aux_ckbp),
    .sigFromSrams_bore_46_ram_mcp_hold(sigFromSrams_bore_46_ram_mcp_hold),
    .sigFromSrams_bore_46_cgen(sigFromSrams_bore_46_cgen),
    .sigFromSrams_bore_47_ram_hold(sigFromSrams_bore_47_ram_hold),
    .sigFromSrams_bore_47_ram_bypass(sigFromSrams_bore_47_ram_bypass),
    .sigFromSrams_bore_47_ram_bp_clken(sigFromSrams_bore_47_ram_bp_clken),
    .sigFromSrams_bore_47_ram_aux_clk(sigFromSrams_bore_47_ram_aux_clk),
    .sigFromSrams_bore_47_ram_aux_ckbp(sigFromSrams_bore_47_ram_aux_ckbp),
    .sigFromSrams_bore_47_ram_mcp_hold(sigFromSrams_bore_47_ram_mcp_hold),
    .sigFromSrams_bore_47_cgen(sigFromSrams_bore_47_cgen),
    .io_bpu_to_ftq_resp_valid(g_io_bpu_to_ftq_resp_valid),
    .io_bpu_to_ftq_resp_bits_s1_pc_3(g_io_bpu_to_ftq_resp_bits_s1_pc_3),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle(g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_s2_pc_3(g_io_bpu_to_ftq_resp_bits_s2_pc_3),
    .io_bpu_to_ftq_resp_bits_s2_valid_3(g_io_bpu_to_ftq_resp_bits_s2_valid_3),
    .io_bpu_to_ftq_resp_bits_s2_hasRedirect_3(g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3),
    .io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag),
    .io_bpu_to_ftq_resp_bits_s2_ftq_idx_value(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle(g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_s3_pc_0(g_io_bpu_to_ftq_resp_bits_s3_pc_0),
    .io_bpu_to_ftq_resp_bits_s3_pc_3(g_io_bpu_to_ftq_resp_bits_s3_pc_3),
    .io_bpu_to_ftq_resp_bits_s3_valid_0(g_io_bpu_to_ftq_resp_bits_s3_valid_0),
    .io_bpu_to_ftq_resp_bits_s3_valid_3(g_io_bpu_to_ftq_resp_bits_s3_valid_3),
    .io_bpu_to_ftq_resp_bits_s3_hasRedirect_3(g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3),
    .io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag),
    .io_bpu_to_ftq_resp_bits_s3_ftq_idx_value(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle(g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_last_stage_meta(g_io_bpu_to_ftq_resp_bits_last_stage_meta),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_1(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_2(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_3(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_4(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_5(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_6(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_7(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_8(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_9(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_12(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_ack(g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_ack(g_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_outdata(g_boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_ack(g_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_outdata(g_boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_ack(g_boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_outdata(g_boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_5_ack(g_boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_5_outdata(g_boreChildrenBd_bore_5_outdata),
    .boreChildrenBd_bore_6_ack(g_boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_6_outdata(g_boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_7_ack(g_boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_7_outdata(g_boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_8_ack(g_boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_8_outdata(g_boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_9_ack(g_boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_9_outdata(g_boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_10_ack(g_boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_10_outdata(g_boreChildrenBd_bore_10_outdata)
  );

  Predictor_xs dut_i (
    .clock(clk), .reset(rst),
    .io_bpu_to_ftq_resp_ready(io_bpu_to_ftq_resp_ready),
    .io_ftq_to_bpu_redirect_valid(io_ftq_to_bpu_redirect_valid),
    .io_ftq_to_bpu_redirect_bits_level(io_ftq_to_bpu_redirect_bits_level),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pc(io_ftq_to_bpu_redirect_bits_cfiUpdate_pc),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp(io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr(io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_target(io_ftq_to_bpu_redirect_bits_cfiUpdate_target),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_taken(io_ftq_to_bpu_redirect_bits_cfiUpdate_taken),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_shift(io_ftq_to_bpu_redirect_bits_cfiUpdate_shift),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist(io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist),
    .io_ftq_to_bpu_redirect_bits_debugIsCtrl(io_ftq_to_bpu_redirect_bits_debugIsCtrl),
    .io_ftq_to_bpu_redirect_bits_debugIsMemVio(io_ftq_to_bpu_redirect_bits_debugIsMemVio),
    .io_ftq_to_bpu_redirect_bits_BTBMissBubble(io_ftq_to_bpu_redirect_bits_BTBMissBubble),
    .io_ftq_to_bpu_update_valid(io_ftq_to_bpu_update_valid),
    .io_ftq_to_bpu_update_bits_pc(io_ftq_to_bpu_update_bits_pc),
    .io_ftq_to_bpu_update_bits_spec_info_histPtr_value(io_ftq_to_bpu_update_bits_spec_info_histPtr_value),
    .io_ftq_to_bpu_update_bits_ftb_entry_isCall(io_ftq_to_bpu_update_bits_ftb_entry_isCall),
    .io_ftq_to_bpu_update_bits_ftb_entry_isRet(io_ftq_to_bpu_update_bits_ftb_entry_isRet),
    .io_ftq_to_bpu_update_bits_ftb_entry_isJalr(io_ftq_to_bpu_update_bits_ftb_entry_isJalr),
    .io_ftq_to_bpu_update_bits_ftb_entry_valid(io_ftq_to_bpu_update_bits_ftb_entry_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_ftq_to_bpu_update_bits_ftb_entry_pftAddr(io_ftq_to_bpu_update_bits_ftb_entry_pftAddr),
    .io_ftq_to_bpu_update_bits_ftb_entry_carry(io_ftq_to_bpu_update_bits_ftb_entry_carry),
    .io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call(io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0),
    .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1),
    .io_ftq_to_bpu_update_bits_cfi_idx_valid(io_ftq_to_bpu_update_bits_cfi_idx_valid),
    .io_ftq_to_bpu_update_bits_cfi_idx_bits(io_ftq_to_bpu_update_bits_cfi_idx_bits),
    .io_ftq_to_bpu_update_bits_br_taken_mask_0(io_ftq_to_bpu_update_bits_br_taken_mask_0),
    .io_ftq_to_bpu_update_bits_br_taken_mask_1(io_ftq_to_bpu_update_bits_br_taken_mask_1),
    .io_ftq_to_bpu_update_bits_jmp_taken(io_ftq_to_bpu_update_bits_jmp_taken),
    .io_ftq_to_bpu_update_bits_mispred_mask_0(io_ftq_to_bpu_update_bits_mispred_mask_0),
    .io_ftq_to_bpu_update_bits_mispred_mask_1(io_ftq_to_bpu_update_bits_mispred_mask_1),
    .io_ftq_to_bpu_update_bits_mispred_mask_2(io_ftq_to_bpu_update_bits_mispred_mask_2),
    .io_ftq_to_bpu_update_bits_false_hit(io_ftq_to_bpu_update_bits_false_hit),
    .io_ftq_to_bpu_update_bits_old_entry(io_ftq_to_bpu_update_bits_old_entry),
    .io_ftq_to_bpu_update_bits_meta(io_ftq_to_bpu_update_bits_meta),
    .io_ftq_to_bpu_update_bits_full_target(io_ftq_to_bpu_update_bits_full_target),
    .io_ftq_to_bpu_enq_ptr_flag(io_ftq_to_bpu_enq_ptr_flag),
    .io_ftq_to_bpu_enq_ptr_value(io_ftq_to_bpu_enq_ptr_value),
    .io_ftq_to_bpu_redirctFromIFU(io_ftq_to_bpu_redirctFromIFU),
    .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable),
    .io_ctrl_btb_enable(io_ctrl_btb_enable),
    .io_ctrl_tage_enable(io_ctrl_tage_enable),
    .io_ctrl_sc_enable(io_ctrl_sc_enable),
    .io_ctrl_ras_enable(io_ctrl_ras_enable),
    .io_reset_vector(io_reset_vector),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_2_array(boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all(boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req(boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_writeen(boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be(boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr(boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata(boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen(boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd(boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_3_array(boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all(boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req(boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_writeen(boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be(boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr(boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata(boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen(boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd(boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_4_array(boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all(boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req(boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_writeen(boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be(boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr(boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata(boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen(boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd(boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_5_array(boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_5_all(boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_5_req(boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_5_writeen(boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_5_be(boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_5_addr(boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_5_indata(boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_5_readen(boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_5_addr_rd(boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_6_array(boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_6_all(boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_6_req(boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_6_writeen(boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_6_be(boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_6_addr(boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_6_indata(boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_6_readen(boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_6_addr_rd(boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_7_array(boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_7_all(boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_7_req(boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_7_writeen(boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_7_be(boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_7_addr(boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_7_indata(boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_7_readen(boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_7_addr_rd(boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_8_array(boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_8_all(boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_8_req(boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_8_writeen(boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_8_be(boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_8_addr(boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_8_indata(boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_8_readen(boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_8_addr_rd(boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_9_array(boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_9_all(boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_9_req(boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_9_writeen(boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_9_be(boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_9_addr(boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_9_indata(boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_9_readen(boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_9_addr_rd(boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_10_array(boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_10_all(boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_10_req(boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_10_writeen(boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_10_be(boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_10_addr(boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_10_indata(boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_10_readen(boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_10_addr_rd(boreChildrenBd_bore_10_addr_rd),
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
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold(sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass(sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken(sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk(sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp(sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold(sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen(sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold(sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass(sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken(sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk(sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp(sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold(sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen(sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold(sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass(sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken(sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk(sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp(sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold(sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen(sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold(sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass(sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken(sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk(sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp(sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold(sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen(sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold(sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass(sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken(sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk(sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp(sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold(sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen(sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold(sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass(sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken(sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk(sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp(sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold(sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen(sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold(sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass(sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken(sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk(sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp(sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold(sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen(sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold(sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass(sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken(sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk(sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp(sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold(sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen(sigFromSrams_bore_39_cgen),
    .sigFromSrams_bore_40_ram_hold(sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_40_ram_bypass(sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_40_ram_bp_clken(sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_40_ram_aux_clk(sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_40_ram_aux_ckbp(sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_40_ram_mcp_hold(sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_40_cgen(sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_41_ram_hold(sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_41_ram_bypass(sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_41_ram_bp_clken(sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_41_ram_aux_clk(sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_41_ram_aux_ckbp(sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_41_ram_mcp_hold(sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_41_cgen(sigFromSrams_bore_41_cgen),
    .sigFromSrams_bore_42_ram_hold(sigFromSrams_bore_42_ram_hold),
    .sigFromSrams_bore_42_ram_bypass(sigFromSrams_bore_42_ram_bypass),
    .sigFromSrams_bore_42_ram_bp_clken(sigFromSrams_bore_42_ram_bp_clken),
    .sigFromSrams_bore_42_ram_aux_clk(sigFromSrams_bore_42_ram_aux_clk),
    .sigFromSrams_bore_42_ram_aux_ckbp(sigFromSrams_bore_42_ram_aux_ckbp),
    .sigFromSrams_bore_42_ram_mcp_hold(sigFromSrams_bore_42_ram_mcp_hold),
    .sigFromSrams_bore_42_cgen(sigFromSrams_bore_42_cgen),
    .sigFromSrams_bore_43_ram_hold(sigFromSrams_bore_43_ram_hold),
    .sigFromSrams_bore_43_ram_bypass(sigFromSrams_bore_43_ram_bypass),
    .sigFromSrams_bore_43_ram_bp_clken(sigFromSrams_bore_43_ram_bp_clken),
    .sigFromSrams_bore_43_ram_aux_clk(sigFromSrams_bore_43_ram_aux_clk),
    .sigFromSrams_bore_43_ram_aux_ckbp(sigFromSrams_bore_43_ram_aux_ckbp),
    .sigFromSrams_bore_43_ram_mcp_hold(sigFromSrams_bore_43_ram_mcp_hold),
    .sigFromSrams_bore_43_cgen(sigFromSrams_bore_43_cgen),
    .sigFromSrams_bore_44_ram_hold(sigFromSrams_bore_44_ram_hold),
    .sigFromSrams_bore_44_ram_bypass(sigFromSrams_bore_44_ram_bypass),
    .sigFromSrams_bore_44_ram_bp_clken(sigFromSrams_bore_44_ram_bp_clken),
    .sigFromSrams_bore_44_ram_aux_clk(sigFromSrams_bore_44_ram_aux_clk),
    .sigFromSrams_bore_44_ram_aux_ckbp(sigFromSrams_bore_44_ram_aux_ckbp),
    .sigFromSrams_bore_44_ram_mcp_hold(sigFromSrams_bore_44_ram_mcp_hold),
    .sigFromSrams_bore_44_cgen(sigFromSrams_bore_44_cgen),
    .sigFromSrams_bore_45_ram_hold(sigFromSrams_bore_45_ram_hold),
    .sigFromSrams_bore_45_ram_bypass(sigFromSrams_bore_45_ram_bypass),
    .sigFromSrams_bore_45_ram_bp_clken(sigFromSrams_bore_45_ram_bp_clken),
    .sigFromSrams_bore_45_ram_aux_clk(sigFromSrams_bore_45_ram_aux_clk),
    .sigFromSrams_bore_45_ram_aux_ckbp(sigFromSrams_bore_45_ram_aux_ckbp),
    .sigFromSrams_bore_45_ram_mcp_hold(sigFromSrams_bore_45_ram_mcp_hold),
    .sigFromSrams_bore_45_cgen(sigFromSrams_bore_45_cgen),
    .sigFromSrams_bore_46_ram_hold(sigFromSrams_bore_46_ram_hold),
    .sigFromSrams_bore_46_ram_bypass(sigFromSrams_bore_46_ram_bypass),
    .sigFromSrams_bore_46_ram_bp_clken(sigFromSrams_bore_46_ram_bp_clken),
    .sigFromSrams_bore_46_ram_aux_clk(sigFromSrams_bore_46_ram_aux_clk),
    .sigFromSrams_bore_46_ram_aux_ckbp(sigFromSrams_bore_46_ram_aux_ckbp),
    .sigFromSrams_bore_46_ram_mcp_hold(sigFromSrams_bore_46_ram_mcp_hold),
    .sigFromSrams_bore_46_cgen(sigFromSrams_bore_46_cgen),
    .sigFromSrams_bore_47_ram_hold(sigFromSrams_bore_47_ram_hold),
    .sigFromSrams_bore_47_ram_bypass(sigFromSrams_bore_47_ram_bypass),
    .sigFromSrams_bore_47_ram_bp_clken(sigFromSrams_bore_47_ram_bp_clken),
    .sigFromSrams_bore_47_ram_aux_clk(sigFromSrams_bore_47_ram_aux_clk),
    .sigFromSrams_bore_47_ram_aux_ckbp(sigFromSrams_bore_47_ram_aux_ckbp),
    .sigFromSrams_bore_47_ram_mcp_hold(sigFromSrams_bore_47_ram_mcp_hold),
    .sigFromSrams_bore_47_cgen(sigFromSrams_bore_47_cgen),
    .io_bpu_to_ftq_resp_valid(i_io_bpu_to_ftq_resp_valid),
    .io_bpu_to_ftq_resp_bits_s1_pc_3(i_io_bpu_to_ftq_resp_bits_s1_pc_3),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle(i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_s2_pc_3(i_io_bpu_to_ftq_resp_bits_s2_pc_3),
    .io_bpu_to_ftq_resp_bits_s2_valid_3(i_io_bpu_to_ftq_resp_bits_s2_valid_3),
    .io_bpu_to_ftq_resp_bits_s2_hasRedirect_3(i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3),
    .io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag(i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag),
    .io_bpu_to_ftq_resp_bits_s2_ftq_idx_value(i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle(i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_s3_pc_0(i_io_bpu_to_ftq_resp_bits_s3_pc_0),
    .io_bpu_to_ftq_resp_bits_s3_pc_3(i_io_bpu_to_ftq_resp_bits_s3_pc_3),
    .io_bpu_to_ftq_resp_bits_s3_valid_0(i_io_bpu_to_ftq_resp_bits_s3_valid_0),
    .io_bpu_to_ftq_resp_bits_s3_valid_3(i_io_bpu_to_ftq_resp_bits_s3_valid_3),
    .io_bpu_to_ftq_resp_bits_s3_hasRedirect_3(i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3),
    .io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag(i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag),
    .io_bpu_to_ftq_resp_bits_s3_ftq_idx_value(i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle(i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_last_stage_meta(i_io_bpu_to_ftq_resp_bits_last_stage_meta),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_1(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_2(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_3(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_4(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_5(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_6(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_7(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_8(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_9(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_12(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_ack(i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_ack(i_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_outdata(i_boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_ack(i_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_outdata(i_boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_ack(i_boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_outdata(i_boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_5_ack(i_boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_5_outdata(i_boreChildrenBd_bore_5_outdata),
    .boreChildrenBd_bore_6_ack(i_boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_6_outdata(i_boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_7_ack(i_boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_7_outdata(i_boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_8_ack(i_boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_8_outdata(i_boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_9_ack(i_boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_9_outdata(i_boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_10_ack(i_boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_10_outdata(i_boreChildrenBd_bore_10_outdata)
  );

  function automatic bit chance(int unsigned pct);
    return ($urandom_range(0, 99) < pct);
  endfunction

  // ---- 覆盖计数（关键事件；为 0 即判失败）----
  longint cov_s0_fire = 0;
  longint cov_s2_override = 0;
  longint cov_s3_override = 0;
  longint cov_s2_valid = 0;
  longint cov_s3_valid = 0;
  longint cov_redirect = 0;
  longint cov_update = 0;
  longint cov_shift1 = 0;
  longint cov_shift2 = 0;
  longint cov_ctrl_bubble = 0;
  longint cov_memvio_bubble = 0;
  longint cov_topdown_set = 0;
  longint cov_ftq_stall = 0;

  // 重定向的历史指针跟着 BPU 自己吐出来的末级指针走（见头注释）
  logic [7:0] hp_shadow;
  logic       hpf_shadow;
  always @(posedge clk) begin
    if (rst) begin hp_shadow <= 8'h0; hpf_shadow <= 1'b0; end
    else if (chance(70)) begin
      hp_shadow  <= g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
      hpf_shadow <= g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
    end
  end

  task automatic drive();
    io_ftq_to_bpu_redirect_bits_level = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pc = 50'({$urandom(), $urandom()});
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp = 4'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr = 3'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value = 5'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value = 5'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value = 5'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit = $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_target = 50'({$urandom(), $urandom()});
    io_ftq_to_bpu_redirect_bits_BTBMissBubble = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_pc = 50'({$urandom(), $urandom()});
    io_ftq_to_bpu_update_bits_ftb_entry_isCall = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_isRet = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_isJalr = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_valid = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset = 4'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower = 12'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat = 2'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset = 4'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower = 20'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat = 2'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_pftAddr = 4'($urandom());
    io_ftq_to_bpu_update_bits_ftb_entry_carry = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_cfi_idx_valid = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_cfi_idx_bits = 4'($urandom());
    io_ftq_to_bpu_update_bits_br_taken_mask_0 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_br_taken_mask_1 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_jmp_taken = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_mispred_mask_0 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_mispred_mask_1 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_mispred_mask_2 = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_false_hit = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_old_entry = $urandom_range(0,1);
    io_ftq_to_bpu_update_bits_meta = 516'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
    io_ftq_to_bpu_update_bits_full_target = 50'({$urandom(), $urandom()});
    io_reset_vector = 48'({$urandom(), $urandom()});
    boreChildrenBd_bore_array = 6'($urandom());
    boreChildrenBd_bore_all = $urandom_range(0,1);
    boreChildrenBd_bore_req = $urandom_range(0,1);
    boreChildrenBd_bore_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_be = 4'($urandom());
    boreChildrenBd_bore_addr = 10'($urandom());
    boreChildrenBd_bore_indata = 40'({$urandom(), $urandom()});
    boreChildrenBd_bore_readen = $urandom_range(0,1);
    boreChildrenBd_bore_addr_rd = 10'($urandom());
    boreChildrenBd_bore_1_array = 7'($urandom());
    boreChildrenBd_bore_1_all = $urandom_range(0,1);
    boreChildrenBd_bore_1_req = $urandom_range(0,1);
    boreChildrenBd_bore_1_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_1_be = 16'($urandom());
    boreChildrenBd_bore_1_addr = 10'($urandom());
    boreChildrenBd_bore_1_indata = 24'($urandom());
    boreChildrenBd_bore_1_readen = $urandom_range(0,1);
    boreChildrenBd_bore_1_addr_rd = 10'($urandom());
    boreChildrenBd_bore_2_array = 7'($urandom());
    boreChildrenBd_bore_2_all = $urandom_range(0,1);
    boreChildrenBd_bore_2_req = $urandom_range(0,1);
    boreChildrenBd_bore_2_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_2_be = 4'($urandom());
    boreChildrenBd_bore_2_addr = 8'($urandom());
    boreChildrenBd_bore_2_indata = 24'($urandom());
    boreChildrenBd_bore_2_readen = $urandom_range(0,1);
    boreChildrenBd_bore_2_addr_rd = 8'($urandom());
    boreChildrenBd_bore_3_array = 7'($urandom());
    boreChildrenBd_bore_3_all = $urandom_range(0,1);
    boreChildrenBd_bore_3_req = $urandom_range(0,1);
    boreChildrenBd_bore_3_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_3_be = 4'($urandom());
    boreChildrenBd_bore_3_addr = 8'($urandom());
    boreChildrenBd_bore_3_indata = 24'($urandom());
    boreChildrenBd_bore_3_readen = $urandom_range(0,1);
    boreChildrenBd_bore_3_addr_rd = 8'($urandom());
    boreChildrenBd_bore_4_array = 7'($urandom());
    boreChildrenBd_bore_4_all = $urandom_range(0,1);
    boreChildrenBd_bore_4_req = $urandom_range(0,1);
    boreChildrenBd_bore_4_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_4_be = 4'($urandom());
    boreChildrenBd_bore_4_addr = 8'($urandom());
    boreChildrenBd_bore_4_indata = 24'($urandom());
    boreChildrenBd_bore_4_readen = $urandom_range(0,1);
    boreChildrenBd_bore_4_addr_rd = 8'($urandom());
    boreChildrenBd_bore_5_array = 7'($urandom());
    boreChildrenBd_bore_5_all = $urandom_range(0,1);
    boreChildrenBd_bore_5_req = $urandom_range(0,1);
    boreChildrenBd_bore_5_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_5_be = 4'($urandom());
    boreChildrenBd_bore_5_addr = 8'($urandom());
    boreChildrenBd_bore_5_indata = 24'($urandom());
    boreChildrenBd_bore_5_readen = $urandom_range(0,1);
    boreChildrenBd_bore_5_addr_rd = 8'($urandom());
    boreChildrenBd_bore_6_array = 7'($urandom());
    boreChildrenBd_bore_6_all = $urandom_range(0,1);
    boreChildrenBd_bore_6_req = $urandom_range(0,1);
    boreChildrenBd_bore_6_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_6_be = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_6_addr = 8'($urandom());
    boreChildrenBd_bore_6_indata = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_6_readen = $urandom_range(0,1);
    boreChildrenBd_bore_6_addr_rd = 8'($urandom());
    boreChildrenBd_bore_7_array = 7'($urandom());
    boreChildrenBd_bore_7_all = $urandom_range(0,1);
    boreChildrenBd_bore_7_req = $urandom_range(0,1);
    boreChildrenBd_bore_7_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_7_be = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_7_addr = 8'($urandom());
    boreChildrenBd_bore_7_indata = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_7_readen = $urandom_range(0,1);
    boreChildrenBd_bore_7_addr_rd = 8'($urandom());
    boreChildrenBd_bore_8_array = 7'($urandom());
    boreChildrenBd_bore_8_all = $urandom_range(0,1);
    boreChildrenBd_bore_8_req = $urandom_range(0,1);
    boreChildrenBd_bore_8_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_8_be = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_8_addr = 8'($urandom());
    boreChildrenBd_bore_8_indata = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_8_readen = $urandom_range(0,1);
    boreChildrenBd_bore_8_addr_rd = 8'($urandom());
    boreChildrenBd_bore_9_array = 7'($urandom());
    boreChildrenBd_bore_9_all = $urandom_range(0,1);
    boreChildrenBd_bore_9_req = $urandom_range(0,1);
    boreChildrenBd_bore_9_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_9_be = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_9_addr = 8'($urandom());
    boreChildrenBd_bore_9_indata = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_9_readen = $urandom_range(0,1);
    boreChildrenBd_bore_9_addr_rd = 8'($urandom());
    boreChildrenBd_bore_10_array = 7'($urandom());
    boreChildrenBd_bore_10_all = $urandom_range(0,1);
    boreChildrenBd_bore_10_req = $urandom_range(0,1);
    boreChildrenBd_bore_10_writeen = $urandom_range(0,1);
    boreChildrenBd_bore_10_be = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_10_addr = 8'($urandom());
    boreChildrenBd_bore_10_indata = 76'({$urandom(), $urandom(), $urandom()});
    boreChildrenBd_bore_10_readen = $urandom_range(0,1);
    boreChildrenBd_bore_10_addr_rd = 8'($urandom());
    sigFromSrams_bore_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_cgen = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_1_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_1_cgen = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_2_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_2_cgen = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_3_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_3_cgen = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_4_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_4_cgen = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_5_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_5_cgen = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_6_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_6_cgen = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_7_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_7_cgen = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_8_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_8_cgen = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_9_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_9_cgen = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_10_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_10_cgen = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_11_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_11_cgen = $urandom_range(0,1);
    sigFromSrams_bore_12_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_12_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_12_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_12_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_12_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_12_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_12_cgen = $urandom_range(0,1);
    sigFromSrams_bore_13_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_13_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_13_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_13_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_13_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_13_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_13_cgen = $urandom_range(0,1);
    sigFromSrams_bore_14_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_14_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_14_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_14_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_14_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_14_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_14_cgen = $urandom_range(0,1);
    sigFromSrams_bore_15_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_15_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_15_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_15_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_15_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_15_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_15_cgen = $urandom_range(0,1);
    sigFromSrams_bore_16_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_16_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_16_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_16_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_16_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_16_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_16_cgen = $urandom_range(0,1);
    sigFromSrams_bore_17_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_17_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_17_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_17_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_17_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_17_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_17_cgen = $urandom_range(0,1);
    sigFromSrams_bore_18_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_18_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_18_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_18_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_18_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_18_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_18_cgen = $urandom_range(0,1);
    sigFromSrams_bore_19_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_19_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_19_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_19_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_19_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_19_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_19_cgen = $urandom_range(0,1);
    sigFromSrams_bore_20_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_20_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_20_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_20_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_20_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_20_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_20_cgen = $urandom_range(0,1);
    sigFromSrams_bore_21_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_21_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_21_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_21_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_21_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_21_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_21_cgen = $urandom_range(0,1);
    sigFromSrams_bore_22_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_22_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_22_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_22_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_22_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_22_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_22_cgen = $urandom_range(0,1);
    sigFromSrams_bore_23_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_23_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_23_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_23_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_23_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_23_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_23_cgen = $urandom_range(0,1);
    sigFromSrams_bore_24_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_24_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_24_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_24_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_24_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_24_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_24_cgen = $urandom_range(0,1);
    sigFromSrams_bore_25_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_25_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_25_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_25_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_25_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_25_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_25_cgen = $urandom_range(0,1);
    sigFromSrams_bore_26_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_26_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_26_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_26_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_26_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_26_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_26_cgen = $urandom_range(0,1);
    sigFromSrams_bore_27_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_27_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_27_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_27_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_27_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_27_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_27_cgen = $urandom_range(0,1);
    sigFromSrams_bore_28_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_28_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_28_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_28_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_28_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_28_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_28_cgen = $urandom_range(0,1);
    sigFromSrams_bore_29_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_29_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_29_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_29_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_29_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_29_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_29_cgen = $urandom_range(0,1);
    sigFromSrams_bore_30_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_30_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_30_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_30_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_30_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_30_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_30_cgen = $urandom_range(0,1);
    sigFromSrams_bore_31_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_31_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_31_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_31_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_31_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_31_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_31_cgen = $urandom_range(0,1);
    sigFromSrams_bore_32_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_32_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_32_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_32_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_32_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_32_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_32_cgen = $urandom_range(0,1);
    sigFromSrams_bore_33_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_33_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_33_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_33_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_33_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_33_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_33_cgen = $urandom_range(0,1);
    sigFromSrams_bore_34_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_34_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_34_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_34_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_34_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_34_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_34_cgen = $urandom_range(0,1);
    sigFromSrams_bore_35_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_35_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_35_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_35_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_35_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_35_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_35_cgen = $urandom_range(0,1);
    sigFromSrams_bore_36_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_36_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_36_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_36_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_36_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_36_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_36_cgen = $urandom_range(0,1);
    sigFromSrams_bore_37_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_37_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_37_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_37_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_37_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_37_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_37_cgen = $urandom_range(0,1);
    sigFromSrams_bore_38_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_38_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_38_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_38_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_38_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_38_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_38_cgen = $urandom_range(0,1);
    sigFromSrams_bore_39_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_39_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_39_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_39_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_39_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_39_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_39_cgen = $urandom_range(0,1);
    sigFromSrams_bore_40_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_40_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_40_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_40_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_40_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_40_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_40_cgen = $urandom_range(0,1);
    sigFromSrams_bore_41_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_41_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_41_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_41_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_41_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_41_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_41_cgen = $urandom_range(0,1);
    sigFromSrams_bore_42_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_42_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_42_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_42_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_42_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_42_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_42_cgen = $urandom_range(0,1);
    sigFromSrams_bore_43_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_43_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_43_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_43_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_43_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_43_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_43_cgen = $urandom_range(0,1);
    sigFromSrams_bore_44_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_44_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_44_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_44_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_44_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_44_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_44_cgen = $urandom_range(0,1);
    sigFromSrams_bore_45_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_45_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_45_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_45_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_45_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_45_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_45_cgen = $urandom_range(0,1);
    sigFromSrams_bore_46_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_46_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_46_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_46_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_46_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_46_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_46_cgen = $urandom_range(0,1);
    sigFromSrams_bore_47_ram_hold = $urandom_range(0,1);
    sigFromSrams_bore_47_ram_bypass = $urandom_range(0,1);
    sigFromSrams_bore_47_ram_bp_clken = $urandom_range(0,1);
    sigFromSrams_bore_47_ram_aux_clk = $urandom_range(0,1);
    sigFromSrams_bore_47_ram_aux_ckbp = $urandom_range(0,1);
    sigFromSrams_bore_47_ram_mcp_hold = $urandom_range(0,1);
    sigFromSrams_bore_47_cgen = $urandom_range(0,1);
  endtask

  always @(negedge clk) begin
    drive();
    io_bpu_to_ftq_resp_ready                          = chance(80);
    io_ftq_to_bpu_redirect_valid                      = chance(4);
    io_ftq_to_bpu_update_valid                        = chance(25);
    io_ftq_to_bpu_redirctFromIFU                      = chance(3);
    // shift 只有 0/1/2 合法；偶尔打 3 压一下越界行为（golden 也有确定语义）
    io_ftq_to_bpu_redirect_bits_cfiUpdate_shift       = chance(95) ? 2'($urandom_range(0,2)) : 2'd3;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist = chance(70);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_taken       = chance(50);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value = chance(75) ? hp_shadow : 8'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag  = chance(75) ? hpf_shadow : $urandom_range(0,1);
    io_ftq_to_bpu_redirect_bits_debugIsCtrl           = chance(45);
    io_ftq_to_bpu_redirect_bits_debugIsMemVio         = chance(20);
    io_ftq_to_bpu_update_bits_spec_info_histPtr_value = chance(75) ? hp_shadow : 8'($urandom());
    io_ftq_to_bpu_enq_ptr_flag                        = $urandom_range(0,1);
    io_ftq_to_bpu_enq_ptr_value                       = 6'($urandom());
    // ctrl 五个使能绝大多数时间全开（关掉预测器会让预测包恒定，覆盖变差）
    io_ctrl_ubtb_enable = chance(97); io_ctrl_btb_enable  = chance(97);
    io_ctrl_tage_enable = chance(97); io_ctrl_sc_enable   = chance(97);
    io_ctrl_ras_enable  = chance(97);
  end

  // 逐拍比对全部 125 个输出
  always @(posedge clk) if (!rst) begin
    if (!$isunknown(g_io_bpu_to_ftq_resp_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_valid !== i_io_bpu_to_ftq_resp_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_valid, i_io_bpu_to_ftq_resp_valid); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_pc_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_pc_3 !== i_io_bpu_to_ftq_resp_bits_s1_pc_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_pc_3, i_io_bpu_to_ftq_resp_bits_s1_pc_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_pc_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_pc_3 !== i_io_bpu_to_ftq_resp_bits_s2_pc_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_pc_3, i_io_bpu_to_ftq_resp_bits_s2_pc_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_valid_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_valid_3 !== i_io_bpu_to_ftq_resp_bits_s2_valid_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_valid_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_valid_3, i_io_bpu_to_ftq_resp_bits_s2_valid_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 !== i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3, i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag !== i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag, i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value !== i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_ftq_idx_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value, i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_pc_0 !== i_io_bpu_to_ftq_resp_bits_s3_pc_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_pc_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_pc_0, i_io_bpu_to_ftq_resp_bits_s3_pc_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_pc_3 !== i_io_bpu_to_ftq_resp_bits_s3_pc_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_pc_3, i_io_bpu_to_ftq_resp_bits_s3_pc_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_valid_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_valid_0 !== i_io_bpu_to_ftq_resp_bits_s3_valid_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_valid_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_valid_0, i_io_bpu_to_ftq_resp_bits_s3_valid_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_valid_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_valid_3 !== i_io_bpu_to_ftq_resp_bits_s3_valid_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_valid_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_valid_3, i_io_bpu_to_ftq_resp_bits_s3_valid_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 !== i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3, i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag !== i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag, i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value !== i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_ftq_idx_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value, i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_meta)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_meta !== i_io_bpu_to_ftq_resp_bits_last_stage_meta) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_meta g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_meta, i_io_bpu_to_ftq_resp_bits_last_stage_meta); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0 !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1 !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0 !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_2 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_4 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_5 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_6 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_7 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_8 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_9 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9); end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12) begin errors++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12); end end
    if (!$isunknown(g_io_perf_0_value)) begin checks++;
      if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end end
    if (!$isunknown(g_io_perf_1_value)) begin checks++;
      if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end end
    if (!$isunknown(g_io_perf_2_value)) begin checks++;
      if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end end
    if (!$isunknown(g_io_perf_3_value)) begin checks++;
      if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end end
    if (!$isunknown(g_io_perf_4_value)) begin checks++;
      if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end end
    if (!$isunknown(g_io_perf_5_value)) begin checks++;
      if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end end
    if (!$isunknown(g_io_perf_6_value)) begin checks++;
      if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end end
    if (!$isunknown(g_boreChildrenBd_bore_ack)) begin checks++;
      if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_ack g=%h i=%h", $time, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_1_ack)) begin checks++;
      if (g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_1_ack g=%h i=%h", $time, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_1_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_1_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_2_ack)) begin checks++;
      if (g_boreChildrenBd_bore_2_ack !== i_boreChildrenBd_bore_2_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_2_ack g=%h i=%h", $time, g_boreChildrenBd_bore_2_ack, i_boreChildrenBd_bore_2_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_2_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_2_outdata !== i_boreChildrenBd_bore_2_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_2_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_2_outdata, i_boreChildrenBd_bore_2_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_3_ack)) begin checks++;
      if (g_boreChildrenBd_bore_3_ack !== i_boreChildrenBd_bore_3_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_3_ack g=%h i=%h", $time, g_boreChildrenBd_bore_3_ack, i_boreChildrenBd_bore_3_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_3_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_3_outdata !== i_boreChildrenBd_bore_3_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_3_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_3_outdata, i_boreChildrenBd_bore_3_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_4_ack)) begin checks++;
      if (g_boreChildrenBd_bore_4_ack !== i_boreChildrenBd_bore_4_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_4_ack g=%h i=%h", $time, g_boreChildrenBd_bore_4_ack, i_boreChildrenBd_bore_4_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_4_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_4_outdata !== i_boreChildrenBd_bore_4_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_4_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_4_outdata, i_boreChildrenBd_bore_4_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_5_ack)) begin checks++;
      if (g_boreChildrenBd_bore_5_ack !== i_boreChildrenBd_bore_5_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_5_ack g=%h i=%h", $time, g_boreChildrenBd_bore_5_ack, i_boreChildrenBd_bore_5_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_5_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_5_outdata !== i_boreChildrenBd_bore_5_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_5_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_5_outdata, i_boreChildrenBd_bore_5_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_6_ack)) begin checks++;
      if (g_boreChildrenBd_bore_6_ack !== i_boreChildrenBd_bore_6_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_6_ack g=%h i=%h", $time, g_boreChildrenBd_bore_6_ack, i_boreChildrenBd_bore_6_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_6_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_6_outdata !== i_boreChildrenBd_bore_6_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_6_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_6_outdata, i_boreChildrenBd_bore_6_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_7_ack)) begin checks++;
      if (g_boreChildrenBd_bore_7_ack !== i_boreChildrenBd_bore_7_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_7_ack g=%h i=%h", $time, g_boreChildrenBd_bore_7_ack, i_boreChildrenBd_bore_7_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_7_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_7_outdata !== i_boreChildrenBd_bore_7_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_7_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_7_outdata, i_boreChildrenBd_bore_7_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_8_ack)) begin checks++;
      if (g_boreChildrenBd_bore_8_ack !== i_boreChildrenBd_bore_8_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_8_ack g=%h i=%h", $time, g_boreChildrenBd_bore_8_ack, i_boreChildrenBd_bore_8_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_8_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_8_outdata !== i_boreChildrenBd_bore_8_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_8_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_8_outdata, i_boreChildrenBd_bore_8_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_9_ack)) begin checks++;
      if (g_boreChildrenBd_bore_9_ack !== i_boreChildrenBd_bore_9_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_9_ack g=%h i=%h", $time, g_boreChildrenBd_bore_9_ack, i_boreChildrenBd_bore_9_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_9_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_9_outdata !== i_boreChildrenBd_bore_9_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_9_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_9_outdata, i_boreChildrenBd_bore_9_outdata); end end
    if (!$isunknown(g_boreChildrenBd_bore_10_ack)) begin checks++;
      if (g_boreChildrenBd_bore_10_ack !== i_boreChildrenBd_bore_10_ack) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_10_ack g=%h i=%h", $time, g_boreChildrenBd_bore_10_ack, i_boreChildrenBd_bore_10_ack); end end
    if (!$isunknown(g_boreChildrenBd_bore_10_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_10_outdata !== i_boreChildrenBd_bore_10_outdata) begin errors++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_10_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_10_outdata, i_boreChildrenBd_bore_10_outdata); end end
    if (g_io_bpu_to_ftq_resp_valid === 1'b1) cov_s0_fire++;
    if (g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1'b1) cov_s2_override++;
    if (g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1'b1) cov_s3_override++;
    if (g_io_bpu_to_ftq_resp_bits_s2_valid_3 === 1'b1) cov_s2_valid++;
    if (g_io_bpu_to_ftq_resp_bits_s3_valid_3 === 1'b1) cov_s3_valid++;
    if (io_ftq_to_bpu_redirect_valid === 1'b1) cov_redirect++;
    if (io_ftq_to_bpu_update_valid === 1'b1) cov_update++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2'd1) cov_shift1++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2'd2) cov_shift2++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_debugIsCtrl) cov_ctrl_bubble++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_debugIsMemVio) cov_memvio_bubble++;
    if (|{g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9}) cov_topdown_set++;
    if (io_bpu_to_ftq_resp_ready === 1'b0) cov_ftq_stall++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    rst = 1; repeat (20) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("--- coverage ---");
    $display("  cov_s0_fire          = %0d", cov_s0_fire);
    $display("  cov_s2_override      = %0d", cov_s2_override);
    $display("  cov_s3_override      = %0d", cov_s3_override);
    $display("  cov_s2_valid         = %0d", cov_s2_valid);
    $display("  cov_s3_valid         = %0d", cov_s3_valid);
    $display("  cov_redirect         = %0d", cov_redirect);
    $display("  cov_update           = %0d", cov_update);
    $display("  cov_shift1           = %0d", cov_shift1);
    $display("  cov_shift2           = %0d", cov_shift2);
    $display("  cov_ctrl_bubble      = %0d", cov_ctrl_bubble);
    $display("  cov_memvio_bubble    = %0d", cov_memvio_bubble);
    $display("  cov_topdown_set      = %0d", cov_topdown_set);
    $display("  cov_ftq_stall        = %0d", cov_ftq_stall);
    begin
      int unsigned zero_cov = 0;
      if (cov_s0_fire == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s0_fire 从未发生"); end
      if (cov_s2_override == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_override 从未发生"); end
      if (cov_s3_override == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_override 从未发生"); end
      if (cov_s2_valid == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_valid 从未发生"); end
      if (cov_s3_valid == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_valid 从未发生"); end
      if (cov_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_redirect 从未发生"); end
      if (cov_update == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_update 从未发生"); end
      if (cov_shift1 == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_shift1 从未发生"); end
      if (cov_shift2 == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_shift2 从未发生"); end
      if (cov_ctrl_bubble == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ctrl_bubble 从未发生"); end
      if (cov_memvio_bubble == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_memvio_bubble 从未发生"); end
      if (cov_topdown_set == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_topdown_set 从未发生"); end
      if (cov_ftq_stall == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ftq_stall 从未发生"); end
      if (errors == 0 && checks > 1000000 && zero_cov == 0) $display("TEST PASSED");
      else begin
        if (zero_cov != 0) $display("=== 覆盖闸不过：%0d 个关键事件计数为 0 ===", zero_cov);
        if (checks <= 1000000) $display("=== checks=%0d 过少，激励没打进去 ===", checks);
        $display("TEST FAILED");
      end
    end
    $finish;
  end
endmodule
