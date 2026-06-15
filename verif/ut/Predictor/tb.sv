// 自动生成：scripts/gen_predictor.py —— 勿手改
// Predictor UT：golden Predictor vs 手写 Predictor_xs 双例化（共用同名 golden 子模块），
// 随机 s0 起步 / redirect / update / FTQ resp 握手，逐拍比对全部输出。
// 另：探针比对可读核 xs_Predictor_core 的 FSM/topdown 影子 vs golden 内部寄存器。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 64;
  bit clk = 0, rst;
  int errors = 0, checks = 0, core_checks = 0, core_errors = 0;
  int cyc = 0;
  always #5 clk = ~clk;
  logic io_bpu_to_ftq_resp_ready;
  logic io_ftq_to_bpu_redirect_valid;
  logic io_ftq_to_bpu_redirect_bits_level;
  logic [49:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_pc;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp;
  logic [2:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag;
  logic [7:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit;
  logic [49:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_target;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_taken;
  logic [1:0] io_ftq_to_bpu_redirect_bits_cfiUpdate_shift;
  logic io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist;
  logic io_ftq_to_bpu_redirect_bits_debugIsCtrl;
  logic io_ftq_to_bpu_redirect_bits_debugIsMemVio;
  logic io_ftq_to_bpu_redirect_bits_BTBMissBubble;
  logic io_ftq_to_bpu_update_valid;
  logic [49:0] io_ftq_to_bpu_update_bits_pc;
  logic [7:0] io_ftq_to_bpu_update_bits_spec_info_histPtr_value;
  logic io_ftq_to_bpu_update_bits_ftb_entry_isCall;
  logic io_ftq_to_bpu_update_bits_ftb_entry_isRet;
  logic io_ftq_to_bpu_update_bits_ftb_entry_isJalr;
  logic io_ftq_to_bpu_update_bits_ftb_entry_valid;
  logic [3:0] io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset;
  logic io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing;
  logic io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid;
  logic [11:0] io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower;
  logic [1:0] io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0] io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset;
  logic io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing;
  logic io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid;
  logic [19:0] io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower;
  logic [1:0] io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0] io_ftq_to_bpu_update_bits_ftb_entry_pftAddr;
  logic io_ftq_to_bpu_update_bits_ftb_entry_carry;
  logic io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call;
  logic io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0;
  logic io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1;
  logic io_ftq_to_bpu_update_bits_cfi_idx_valid;
  logic [3:0] io_ftq_to_bpu_update_bits_cfi_idx_bits;
  logic io_ftq_to_bpu_update_bits_br_taken_mask_0;
  logic io_ftq_to_bpu_update_bits_br_taken_mask_1;
  logic io_ftq_to_bpu_update_bits_jmp_taken;
  logic io_ftq_to_bpu_update_bits_mispred_mask_0;
  logic io_ftq_to_bpu_update_bits_mispred_mask_1;
  logic io_ftq_to_bpu_update_bits_mispred_mask_2;
  logic io_ftq_to_bpu_update_bits_false_hit;
  logic io_ftq_to_bpu_update_bits_old_entry;
  logic [515:0] io_ftq_to_bpu_update_bits_meta;
  logic [49:0] io_ftq_to_bpu_update_bits_full_target;
  logic io_ftq_to_bpu_enq_ptr_flag;
  logic [5:0] io_ftq_to_bpu_enq_ptr_value;
  logic io_ftq_to_bpu_redirctFromIFU;
  logic io_ctrl_ubtb_enable;
  logic io_ctrl_btb_enable;
  logic io_ctrl_tage_enable;
  logic io_ctrl_sc_enable;
  logic io_ctrl_ras_enable;
  logic [47:0] io_reset_vector;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [3:0] boreChildrenBd_bore_be;
  logic [9:0] boreChildrenBd_bore_addr;
  logic [39:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [9:0] boreChildrenBd_bore_addr_rd;
  logic [6:0] boreChildrenBd_bore_1_array;
  logic boreChildrenBd_bore_1_all;
  logic boreChildrenBd_bore_1_req;
  logic boreChildrenBd_bore_1_writeen;
  logic [15:0] boreChildrenBd_bore_1_be;
  logic [9:0] boreChildrenBd_bore_1_addr;
  logic [23:0] boreChildrenBd_bore_1_indata;
  logic boreChildrenBd_bore_1_readen;
  logic [9:0] boreChildrenBd_bore_1_addr_rd;
  logic [6:0] boreChildrenBd_bore_2_array;
  logic boreChildrenBd_bore_2_all;
  logic boreChildrenBd_bore_2_req;
  logic boreChildrenBd_bore_2_writeen;
  logic [3:0] boreChildrenBd_bore_2_be;
  logic [8:0] boreChildrenBd_bore_2_addr;
  logic [23:0] boreChildrenBd_bore_2_indata;
  logic boreChildrenBd_bore_2_readen;
  logic [8:0] boreChildrenBd_bore_2_addr_rd;
  logic [6:0] boreChildrenBd_bore_3_array;
  logic boreChildrenBd_bore_3_all;
  logic boreChildrenBd_bore_3_req;
  logic boreChildrenBd_bore_3_writeen;
  logic [3:0] boreChildrenBd_bore_3_be;
  logic [8:0] boreChildrenBd_bore_3_addr;
  logic [23:0] boreChildrenBd_bore_3_indata;
  logic boreChildrenBd_bore_3_readen;
  logic [8:0] boreChildrenBd_bore_3_addr_rd;
  logic [6:0] boreChildrenBd_bore_4_array;
  logic boreChildrenBd_bore_4_all;
  logic boreChildrenBd_bore_4_req;
  logic boreChildrenBd_bore_4_writeen;
  logic [3:0] boreChildrenBd_bore_4_be;
  logic [8:0] boreChildrenBd_bore_4_addr;
  logic [23:0] boreChildrenBd_bore_4_indata;
  logic boreChildrenBd_bore_4_readen;
  logic [8:0] boreChildrenBd_bore_4_addr_rd;
  logic [6:0] boreChildrenBd_bore_5_array;
  logic boreChildrenBd_bore_5_all;
  logic boreChildrenBd_bore_5_req;
  logic boreChildrenBd_bore_5_writeen;
  logic [3:0] boreChildrenBd_bore_5_be;
  logic [8:0] boreChildrenBd_bore_5_addr;
  logic [23:0] boreChildrenBd_bore_5_indata;
  logic boreChildrenBd_bore_5_readen;
  logic [8:0] boreChildrenBd_bore_5_addr_rd;
  logic [6:0] boreChildrenBd_bore_6_array;
  logic boreChildrenBd_bore_6_all;
  logic boreChildrenBd_bore_6_req;
  logic boreChildrenBd_bore_6_writeen;
  logic [75:0] boreChildrenBd_bore_6_be;
  logic [7:0] boreChildrenBd_bore_6_addr;
  logic [75:0] boreChildrenBd_bore_6_indata;
  logic boreChildrenBd_bore_6_readen;
  logic [7:0] boreChildrenBd_bore_6_addr_rd;
  logic [6:0] boreChildrenBd_bore_7_array;
  logic boreChildrenBd_bore_7_all;
  logic boreChildrenBd_bore_7_req;
  logic boreChildrenBd_bore_7_writeen;
  logic [75:0] boreChildrenBd_bore_7_be;
  logic [7:0] boreChildrenBd_bore_7_addr;
  logic [75:0] boreChildrenBd_bore_7_indata;
  logic boreChildrenBd_bore_7_readen;
  logic [7:0] boreChildrenBd_bore_7_addr_rd;
  logic [6:0] boreChildrenBd_bore_8_array;
  logic boreChildrenBd_bore_8_all;
  logic boreChildrenBd_bore_8_req;
  logic boreChildrenBd_bore_8_writeen;
  logic [75:0] boreChildrenBd_bore_8_be;
  logic [7:0] boreChildrenBd_bore_8_addr;
  logic [75:0] boreChildrenBd_bore_8_indata;
  logic boreChildrenBd_bore_8_readen;
  logic [7:0] boreChildrenBd_bore_8_addr_rd;
  logic [6:0] boreChildrenBd_bore_9_array;
  logic boreChildrenBd_bore_9_all;
  logic boreChildrenBd_bore_9_req;
  logic boreChildrenBd_bore_9_writeen;
  logic [75:0] boreChildrenBd_bore_9_be;
  logic [7:0] boreChildrenBd_bore_9_addr;
  logic [75:0] boreChildrenBd_bore_9_indata;
  logic boreChildrenBd_bore_9_readen;
  logic [7:0] boreChildrenBd_bore_9_addr_rd;
  logic [6:0] boreChildrenBd_bore_10_array;
  logic boreChildrenBd_bore_10_all;
  logic boreChildrenBd_bore_10_req;
  logic boreChildrenBd_bore_10_writeen;
  logic [75:0] boreChildrenBd_bore_10_be;
  logic [7:0] boreChildrenBd_bore_10_addr;
  logic [75:0] boreChildrenBd_bore_10_indata;
  logic boreChildrenBd_bore_10_readen;
  logic [7:0] boreChildrenBd_bore_10_addr_rd;
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
  logic sigFromSrams_bore_8_ram_hold;
  logic sigFromSrams_bore_8_ram_bypass;
  logic sigFromSrams_bore_8_ram_bp_clken;
  logic sigFromSrams_bore_8_ram_aux_clk;
  logic sigFromSrams_bore_8_ram_aux_ckbp;
  logic sigFromSrams_bore_8_ram_mcp_hold;
  logic sigFromSrams_bore_8_cgen;
  logic sigFromSrams_bore_9_ram_hold;
  logic sigFromSrams_bore_9_ram_bypass;
  logic sigFromSrams_bore_9_ram_bp_clken;
  logic sigFromSrams_bore_9_ram_aux_clk;
  logic sigFromSrams_bore_9_ram_aux_ckbp;
  logic sigFromSrams_bore_9_ram_mcp_hold;
  logic sigFromSrams_bore_9_cgen;
  logic sigFromSrams_bore_10_ram_hold;
  logic sigFromSrams_bore_10_ram_bypass;
  logic sigFromSrams_bore_10_ram_bp_clken;
  logic sigFromSrams_bore_10_ram_aux_clk;
  logic sigFromSrams_bore_10_ram_aux_ckbp;
  logic sigFromSrams_bore_10_ram_mcp_hold;
  logic sigFromSrams_bore_10_cgen;
  logic sigFromSrams_bore_11_ram_hold;
  logic sigFromSrams_bore_11_ram_bypass;
  logic sigFromSrams_bore_11_ram_bp_clken;
  logic sigFromSrams_bore_11_ram_aux_clk;
  logic sigFromSrams_bore_11_ram_aux_ckbp;
  logic sigFromSrams_bore_11_ram_mcp_hold;
  logic sigFromSrams_bore_11_cgen;
  logic sigFromSrams_bore_12_ram_hold;
  logic sigFromSrams_bore_12_ram_bypass;
  logic sigFromSrams_bore_12_ram_bp_clken;
  logic sigFromSrams_bore_12_ram_aux_clk;
  logic sigFromSrams_bore_12_ram_aux_ckbp;
  logic sigFromSrams_bore_12_ram_mcp_hold;
  logic sigFromSrams_bore_12_cgen;
  logic sigFromSrams_bore_13_ram_hold;
  logic sigFromSrams_bore_13_ram_bypass;
  logic sigFromSrams_bore_13_ram_bp_clken;
  logic sigFromSrams_bore_13_ram_aux_clk;
  logic sigFromSrams_bore_13_ram_aux_ckbp;
  logic sigFromSrams_bore_13_ram_mcp_hold;
  logic sigFromSrams_bore_13_cgen;
  logic sigFromSrams_bore_14_ram_hold;
  logic sigFromSrams_bore_14_ram_bypass;
  logic sigFromSrams_bore_14_ram_bp_clken;
  logic sigFromSrams_bore_14_ram_aux_clk;
  logic sigFromSrams_bore_14_ram_aux_ckbp;
  logic sigFromSrams_bore_14_ram_mcp_hold;
  logic sigFromSrams_bore_14_cgen;
  logic sigFromSrams_bore_15_ram_hold;
  logic sigFromSrams_bore_15_ram_bypass;
  logic sigFromSrams_bore_15_ram_bp_clken;
  logic sigFromSrams_bore_15_ram_aux_clk;
  logic sigFromSrams_bore_15_ram_aux_ckbp;
  logic sigFromSrams_bore_15_ram_mcp_hold;
  logic sigFromSrams_bore_15_cgen;
  logic sigFromSrams_bore_16_ram_hold;
  logic sigFromSrams_bore_16_ram_bypass;
  logic sigFromSrams_bore_16_ram_bp_clken;
  logic sigFromSrams_bore_16_ram_aux_clk;
  logic sigFromSrams_bore_16_ram_aux_ckbp;
  logic sigFromSrams_bore_16_ram_mcp_hold;
  logic sigFromSrams_bore_16_cgen;
  logic sigFromSrams_bore_17_ram_hold;
  logic sigFromSrams_bore_17_ram_bypass;
  logic sigFromSrams_bore_17_ram_bp_clken;
  logic sigFromSrams_bore_17_ram_aux_clk;
  logic sigFromSrams_bore_17_ram_aux_ckbp;
  logic sigFromSrams_bore_17_ram_mcp_hold;
  logic sigFromSrams_bore_17_cgen;
  logic sigFromSrams_bore_18_ram_hold;
  logic sigFromSrams_bore_18_ram_bypass;
  logic sigFromSrams_bore_18_ram_bp_clken;
  logic sigFromSrams_bore_18_ram_aux_clk;
  logic sigFromSrams_bore_18_ram_aux_ckbp;
  logic sigFromSrams_bore_18_ram_mcp_hold;
  logic sigFromSrams_bore_18_cgen;
  logic sigFromSrams_bore_19_ram_hold;
  logic sigFromSrams_bore_19_ram_bypass;
  logic sigFromSrams_bore_19_ram_bp_clken;
  logic sigFromSrams_bore_19_ram_aux_clk;
  logic sigFromSrams_bore_19_ram_aux_ckbp;
  logic sigFromSrams_bore_19_ram_mcp_hold;
  logic sigFromSrams_bore_19_cgen;
  logic sigFromSrams_bore_20_ram_hold;
  logic sigFromSrams_bore_20_ram_bypass;
  logic sigFromSrams_bore_20_ram_bp_clken;
  logic sigFromSrams_bore_20_ram_aux_clk;
  logic sigFromSrams_bore_20_ram_aux_ckbp;
  logic sigFromSrams_bore_20_ram_mcp_hold;
  logic sigFromSrams_bore_20_cgen;
  logic sigFromSrams_bore_21_ram_hold;
  logic sigFromSrams_bore_21_ram_bypass;
  logic sigFromSrams_bore_21_ram_bp_clken;
  logic sigFromSrams_bore_21_ram_aux_clk;
  logic sigFromSrams_bore_21_ram_aux_ckbp;
  logic sigFromSrams_bore_21_ram_mcp_hold;
  logic sigFromSrams_bore_21_cgen;
  logic sigFromSrams_bore_22_ram_hold;
  logic sigFromSrams_bore_22_ram_bypass;
  logic sigFromSrams_bore_22_ram_bp_clken;
  logic sigFromSrams_bore_22_ram_aux_clk;
  logic sigFromSrams_bore_22_ram_aux_ckbp;
  logic sigFromSrams_bore_22_ram_mcp_hold;
  logic sigFromSrams_bore_22_cgen;
  logic sigFromSrams_bore_23_ram_hold;
  logic sigFromSrams_bore_23_ram_bypass;
  logic sigFromSrams_bore_23_ram_bp_clken;
  logic sigFromSrams_bore_23_ram_aux_clk;
  logic sigFromSrams_bore_23_ram_aux_ckbp;
  logic sigFromSrams_bore_23_ram_mcp_hold;
  logic sigFromSrams_bore_23_cgen;
  logic sigFromSrams_bore_24_ram_hold;
  logic sigFromSrams_bore_24_ram_bypass;
  logic sigFromSrams_bore_24_ram_bp_clken;
  logic sigFromSrams_bore_24_ram_aux_clk;
  logic sigFromSrams_bore_24_ram_aux_ckbp;
  logic sigFromSrams_bore_24_ram_mcp_hold;
  logic sigFromSrams_bore_24_cgen;
  logic sigFromSrams_bore_25_ram_hold;
  logic sigFromSrams_bore_25_ram_bypass;
  logic sigFromSrams_bore_25_ram_bp_clken;
  logic sigFromSrams_bore_25_ram_aux_clk;
  logic sigFromSrams_bore_25_ram_aux_ckbp;
  logic sigFromSrams_bore_25_ram_mcp_hold;
  logic sigFromSrams_bore_25_cgen;
  logic sigFromSrams_bore_26_ram_hold;
  logic sigFromSrams_bore_26_ram_bypass;
  logic sigFromSrams_bore_26_ram_bp_clken;
  logic sigFromSrams_bore_26_ram_aux_clk;
  logic sigFromSrams_bore_26_ram_aux_ckbp;
  logic sigFromSrams_bore_26_ram_mcp_hold;
  logic sigFromSrams_bore_26_cgen;
  logic sigFromSrams_bore_27_ram_hold;
  logic sigFromSrams_bore_27_ram_bypass;
  logic sigFromSrams_bore_27_ram_bp_clken;
  logic sigFromSrams_bore_27_ram_aux_clk;
  logic sigFromSrams_bore_27_ram_aux_ckbp;
  logic sigFromSrams_bore_27_ram_mcp_hold;
  logic sigFromSrams_bore_27_cgen;
  logic sigFromSrams_bore_28_ram_hold;
  logic sigFromSrams_bore_28_ram_bypass;
  logic sigFromSrams_bore_28_ram_bp_clken;
  logic sigFromSrams_bore_28_ram_aux_clk;
  logic sigFromSrams_bore_28_ram_aux_ckbp;
  logic sigFromSrams_bore_28_ram_mcp_hold;
  logic sigFromSrams_bore_28_cgen;
  logic sigFromSrams_bore_29_ram_hold;
  logic sigFromSrams_bore_29_ram_bypass;
  logic sigFromSrams_bore_29_ram_bp_clken;
  logic sigFromSrams_bore_29_ram_aux_clk;
  logic sigFromSrams_bore_29_ram_aux_ckbp;
  logic sigFromSrams_bore_29_ram_mcp_hold;
  logic sigFromSrams_bore_29_cgen;
  logic sigFromSrams_bore_30_ram_hold;
  logic sigFromSrams_bore_30_ram_bypass;
  logic sigFromSrams_bore_30_ram_bp_clken;
  logic sigFromSrams_bore_30_ram_aux_clk;
  logic sigFromSrams_bore_30_ram_aux_ckbp;
  logic sigFromSrams_bore_30_ram_mcp_hold;
  logic sigFromSrams_bore_30_cgen;
  logic sigFromSrams_bore_31_ram_hold;
  logic sigFromSrams_bore_31_ram_bypass;
  logic sigFromSrams_bore_31_ram_bp_clken;
  logic sigFromSrams_bore_31_ram_aux_clk;
  logic sigFromSrams_bore_31_ram_aux_ckbp;
  logic sigFromSrams_bore_31_ram_mcp_hold;
  logic sigFromSrams_bore_31_cgen;
  logic sigFromSrams_bore_32_ram_hold;
  logic sigFromSrams_bore_32_ram_bypass;
  logic sigFromSrams_bore_32_ram_bp_clken;
  logic sigFromSrams_bore_32_ram_aux_clk;
  logic sigFromSrams_bore_32_ram_aux_ckbp;
  logic sigFromSrams_bore_32_ram_mcp_hold;
  logic sigFromSrams_bore_32_cgen;
  logic sigFromSrams_bore_33_ram_hold;
  logic sigFromSrams_bore_33_ram_bypass;
  logic sigFromSrams_bore_33_ram_bp_clken;
  logic sigFromSrams_bore_33_ram_aux_clk;
  logic sigFromSrams_bore_33_ram_aux_ckbp;
  logic sigFromSrams_bore_33_ram_mcp_hold;
  logic sigFromSrams_bore_33_cgen;
  logic sigFromSrams_bore_34_ram_hold;
  logic sigFromSrams_bore_34_ram_bypass;
  logic sigFromSrams_bore_34_ram_bp_clken;
  logic sigFromSrams_bore_34_ram_aux_clk;
  logic sigFromSrams_bore_34_ram_aux_ckbp;
  logic sigFromSrams_bore_34_ram_mcp_hold;
  logic sigFromSrams_bore_34_cgen;
  logic sigFromSrams_bore_35_ram_hold;
  logic sigFromSrams_bore_35_ram_bypass;
  logic sigFromSrams_bore_35_ram_bp_clken;
  logic sigFromSrams_bore_35_ram_aux_clk;
  logic sigFromSrams_bore_35_ram_aux_ckbp;
  logic sigFromSrams_bore_35_ram_mcp_hold;
  logic sigFromSrams_bore_35_cgen;
  logic sigFromSrams_bore_36_ram_hold;
  logic sigFromSrams_bore_36_ram_bypass;
  logic sigFromSrams_bore_36_ram_bp_clken;
  logic sigFromSrams_bore_36_ram_aux_clk;
  logic sigFromSrams_bore_36_ram_aux_ckbp;
  logic sigFromSrams_bore_36_ram_mcp_hold;
  logic sigFromSrams_bore_36_cgen;
  logic sigFromSrams_bore_37_ram_hold;
  logic sigFromSrams_bore_37_ram_bypass;
  logic sigFromSrams_bore_37_ram_bp_clken;
  logic sigFromSrams_bore_37_ram_aux_clk;
  logic sigFromSrams_bore_37_ram_aux_ckbp;
  logic sigFromSrams_bore_37_ram_mcp_hold;
  logic sigFromSrams_bore_37_cgen;
  logic sigFromSrams_bore_38_ram_hold;
  logic sigFromSrams_bore_38_ram_bypass;
  logic sigFromSrams_bore_38_ram_bp_clken;
  logic sigFromSrams_bore_38_ram_aux_clk;
  logic sigFromSrams_bore_38_ram_aux_ckbp;
  logic sigFromSrams_bore_38_ram_mcp_hold;
  logic sigFromSrams_bore_38_cgen;
  logic sigFromSrams_bore_39_ram_hold;
  logic sigFromSrams_bore_39_ram_bypass;
  logic sigFromSrams_bore_39_ram_bp_clken;
  logic sigFromSrams_bore_39_ram_aux_clk;
  logic sigFromSrams_bore_39_ram_aux_ckbp;
  logic sigFromSrams_bore_39_ram_mcp_hold;
  logic sigFromSrams_bore_39_cgen;
  logic sigFromSrams_bore_40_ram_hold;
  logic sigFromSrams_bore_40_ram_bypass;
  logic sigFromSrams_bore_40_ram_bp_clken;
  logic sigFromSrams_bore_40_ram_aux_clk;
  logic sigFromSrams_bore_40_ram_aux_ckbp;
  logic sigFromSrams_bore_40_ram_mcp_hold;
  logic sigFromSrams_bore_40_cgen;
  logic sigFromSrams_bore_41_ram_hold;
  logic sigFromSrams_bore_41_ram_bypass;
  logic sigFromSrams_bore_41_ram_bp_clken;
  logic sigFromSrams_bore_41_ram_aux_clk;
  logic sigFromSrams_bore_41_ram_aux_ckbp;
  logic sigFromSrams_bore_41_ram_mcp_hold;
  logic sigFromSrams_bore_41_cgen;
  wire g_io_bpu_to_ftq_resp_valid;
  wire i_io_bpu_to_ftq_resp_valid;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s1_pc_3;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s1_pc_3;
  wire [63:0] g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle;
  wire [63:0] i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle;
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0;
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1;
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0;
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1;
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
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr;
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing;
  wire g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit;
  wire i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s2_pc_3;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s2_pc_3;
  wire g_io_bpu_to_ftq_resp_bits_s2_valid_3;
  wire i_io_bpu_to_ftq_resp_bits_s2_valid_3;
  wire g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3;
  wire i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3;
  wire g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag;
  wire i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag;
  wire [5:0] g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value;
  wire [5:0] i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value;
  wire [63:0] g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle;
  wire [63:0] i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle;
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0;
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1;
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0;
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1;
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
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr;
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing;
  wire g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit;
  wire i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_pc_0;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_pc_0;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_s3_pc_3;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_s3_pc_3;
  wire g_io_bpu_to_ftq_resp_bits_s3_valid_0;
  wire i_io_bpu_to_ftq_resp_bits_s3_valid_0;
  wire g_io_bpu_to_ftq_resp_bits_s3_valid_3;
  wire i_io_bpu_to_ftq_resp_bits_s3_valid_3;
  wire g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3;
  wire i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3;
  wire g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag;
  wire i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag;
  wire [5:0] g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value;
  wire [5:0] i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value;
  wire [63:0] g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle;
  wire [63:0] i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle;
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0;
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1;
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0;
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1;
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
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr;
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing;
  wire g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit;
  wire i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit;
  wire [515:0] g_io_bpu_to_ftq_resp_bits_last_stage_meta;
  wire [515:0] i_io_bpu_to_ftq_resp_bits_last_stage_meta;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
  wire [7:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
  wire [7:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp;
  wire [2:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr;
  wire [2:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag;
  wire [4:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value;
  wire [4:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag;
  wire [4:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value;
  wire [4:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag;
  wire [4:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value;
  wire [4:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value;
  wire [49:0] g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr;
  wire [49:0] i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower;
  wire [11:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [1:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower;
  wire [19:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat;
  wire [1:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0] g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr;
  wire [3:0] i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0;
  wire g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1;
  wire i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9;
  wire g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12;
  wire i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12;
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
  wire g_boreChildrenBd_bore_ack;
  wire i_boreChildrenBd_bore_ack;
  wire [39:0] g_boreChildrenBd_bore_outdata;
  wire [39:0] i_boreChildrenBd_bore_outdata;
  wire g_boreChildrenBd_bore_1_ack;
  wire i_boreChildrenBd_bore_1_ack;
  wire [23:0] g_boreChildrenBd_bore_1_outdata;
  wire [23:0] i_boreChildrenBd_bore_1_outdata;
  wire g_boreChildrenBd_bore_2_ack;
  wire i_boreChildrenBd_bore_2_ack;
  wire [23:0] g_boreChildrenBd_bore_2_outdata;
  wire [23:0] i_boreChildrenBd_bore_2_outdata;
  wire g_boreChildrenBd_bore_3_ack;
  wire i_boreChildrenBd_bore_3_ack;
  wire [23:0] g_boreChildrenBd_bore_3_outdata;
  wire [23:0] i_boreChildrenBd_bore_3_outdata;
  wire g_boreChildrenBd_bore_4_ack;
  wire i_boreChildrenBd_bore_4_ack;
  wire [23:0] g_boreChildrenBd_bore_4_outdata;
  wire [23:0] i_boreChildrenBd_bore_4_outdata;
  wire g_boreChildrenBd_bore_5_ack;
  wire i_boreChildrenBd_bore_5_ack;
  wire [23:0] g_boreChildrenBd_bore_5_outdata;
  wire [23:0] i_boreChildrenBd_bore_5_outdata;
  wire g_boreChildrenBd_bore_6_ack;
  wire i_boreChildrenBd_bore_6_ack;
  wire [75:0] g_boreChildrenBd_bore_6_outdata;
  wire [75:0] i_boreChildrenBd_bore_6_outdata;
  wire g_boreChildrenBd_bore_7_ack;
  wire i_boreChildrenBd_bore_7_ack;
  wire [75:0] g_boreChildrenBd_bore_7_outdata;
  wire [75:0] i_boreChildrenBd_bore_7_outdata;
  wire g_boreChildrenBd_bore_8_ack;
  wire i_boreChildrenBd_bore_8_ack;
  wire [75:0] g_boreChildrenBd_bore_8_outdata;
  wire [75:0] i_boreChildrenBd_bore_8_outdata;
  wire g_boreChildrenBd_bore_9_ack;
  wire i_boreChildrenBd_bore_9_ack;
  wire [75:0] g_boreChildrenBd_bore_9_outdata;
  wire [75:0] i_boreChildrenBd_bore_9_outdata;
  wire g_boreChildrenBd_bore_10_ack;
  wire i_boreChildrenBd_bore_10_ack;
  wire [75:0] g_boreChildrenBd_bore_10_outdata;
  wire [75:0] i_boreChildrenBd_bore_10_outdata;
  wire xs_dbg_s1_valid;
  wire xs_dbg_s2_valid;
  wire xs_dbg_s3_valid;
  wire xs_dbg_resp_valid;
  wire xs_dbg_s0_fire_0;
  wire xs_dbg_s0_fire_1;
  wire xs_dbg_s0_fire_2;
  wire xs_dbg_s0_fire_3;
  wire xs_dbg_s1_fire_0;
  wire xs_dbg_s1_fire_1;
  wire xs_dbg_s1_fire_2;
  wire xs_dbg_s1_fire_3;
  wire xs_dbg_topdown2_reason_1;
  wire xs_dbg_topdown2_reason_2;
  wire xs_dbg_topdown2_reason_3;
  wire xs_dbg_topdown2_reason_4;
  wire xs_dbg_topdown2_reason_5;
  wire xs_dbg_topdown2_reason_6;
  wire xs_dbg_topdown2_reason_7;
  wire xs_dbg_topdown2_reason_8;
  wire xs_dbg_topdown2_reason_9;
  wire xs_dbg_topdown2_reason_12;
  Predictor    u_g (.clock(clk), .reset(rst), .io_bpu_to_ftq_resp_ready(io_bpu_to_ftq_resp_ready), .io_ftq_to_bpu_redirect_valid(io_ftq_to_bpu_redirect_valid), .io_ftq_to_bpu_redirect_bits_level(io_ftq_to_bpu_redirect_bits_level), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pc(io_ftq_to_bpu_redirect_bits_cfiUpdate_pc), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet), .io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp(io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp), .io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr(io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit), .io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit), .io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit), .io_ftq_to_bpu_redirect_bits_cfiUpdate_target(io_ftq_to_bpu_redirect_bits_cfiUpdate_target), .io_ftq_to_bpu_redirect_bits_cfiUpdate_taken(io_ftq_to_bpu_redirect_bits_cfiUpdate_taken), .io_ftq_to_bpu_redirect_bits_cfiUpdate_shift(io_ftq_to_bpu_redirect_bits_cfiUpdate_shift), .io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist(io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist), .io_ftq_to_bpu_redirect_bits_debugIsCtrl(io_ftq_to_bpu_redirect_bits_debugIsCtrl), .io_ftq_to_bpu_redirect_bits_debugIsMemVio(io_ftq_to_bpu_redirect_bits_debugIsMemVio), .io_ftq_to_bpu_redirect_bits_BTBMissBubble(io_ftq_to_bpu_redirect_bits_BTBMissBubble), .io_ftq_to_bpu_update_valid(io_ftq_to_bpu_update_valid), .io_ftq_to_bpu_update_bits_pc(io_ftq_to_bpu_update_bits_pc), .io_ftq_to_bpu_update_bits_spec_info_histPtr_value(io_ftq_to_bpu_update_bits_spec_info_histPtr_value), .io_ftq_to_bpu_update_bits_ftb_entry_isCall(io_ftq_to_bpu_update_bits_ftb_entry_isCall), .io_ftq_to_bpu_update_bits_ftb_entry_isRet(io_ftq_to_bpu_update_bits_ftb_entry_isRet), .io_ftq_to_bpu_update_bits_ftb_entry_isJalr(io_ftq_to_bpu_update_bits_ftb_entry_isJalr), .io_ftq_to_bpu_update_bits_ftb_entry_valid(io_ftq_to_bpu_update_bits_ftb_entry_valid), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat), .io_ftq_to_bpu_update_bits_ftb_entry_pftAddr(io_ftq_to_bpu_update_bits_ftb_entry_pftAddr), .io_ftq_to_bpu_update_bits_ftb_entry_carry(io_ftq_to_bpu_update_bits_ftb_entry_carry), .io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call(io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call), .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0), .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1), .io_ftq_to_bpu_update_bits_cfi_idx_valid(io_ftq_to_bpu_update_bits_cfi_idx_valid), .io_ftq_to_bpu_update_bits_cfi_idx_bits(io_ftq_to_bpu_update_bits_cfi_idx_bits), .io_ftq_to_bpu_update_bits_br_taken_mask_0(io_ftq_to_bpu_update_bits_br_taken_mask_0), .io_ftq_to_bpu_update_bits_br_taken_mask_1(io_ftq_to_bpu_update_bits_br_taken_mask_1), .io_ftq_to_bpu_update_bits_jmp_taken(io_ftq_to_bpu_update_bits_jmp_taken), .io_ftq_to_bpu_update_bits_mispred_mask_0(io_ftq_to_bpu_update_bits_mispred_mask_0), .io_ftq_to_bpu_update_bits_mispred_mask_1(io_ftq_to_bpu_update_bits_mispred_mask_1), .io_ftq_to_bpu_update_bits_mispred_mask_2(io_ftq_to_bpu_update_bits_mispred_mask_2), .io_ftq_to_bpu_update_bits_false_hit(io_ftq_to_bpu_update_bits_false_hit), .io_ftq_to_bpu_update_bits_old_entry(io_ftq_to_bpu_update_bits_old_entry), .io_ftq_to_bpu_update_bits_meta(io_ftq_to_bpu_update_bits_meta), .io_ftq_to_bpu_update_bits_full_target(io_ftq_to_bpu_update_bits_full_target), .io_ftq_to_bpu_enq_ptr_flag(io_ftq_to_bpu_enq_ptr_flag), .io_ftq_to_bpu_enq_ptr_value(io_ftq_to_bpu_enq_ptr_value), .io_ftq_to_bpu_redirctFromIFU(io_ftq_to_bpu_redirctFromIFU), .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable), .io_ctrl_btb_enable(io_ctrl_btb_enable), .io_ctrl_tage_enable(io_ctrl_tage_enable), .io_ctrl_sc_enable(io_ctrl_sc_enable), .io_ctrl_ras_enable(io_ctrl_ras_enable), .io_reset_vector(io_reset_vector), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array), .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all), .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req), .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen), .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be), .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata), .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen), .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd), .boreChildrenBd_bore_2_array(boreChildrenBd_bore_2_array), .boreChildrenBd_bore_2_all(boreChildrenBd_bore_2_all), .boreChildrenBd_bore_2_req(boreChildrenBd_bore_2_req), .boreChildrenBd_bore_2_writeen(boreChildrenBd_bore_2_writeen), .boreChildrenBd_bore_2_be(boreChildrenBd_bore_2_be), .boreChildrenBd_bore_2_addr(boreChildrenBd_bore_2_addr), .boreChildrenBd_bore_2_indata(boreChildrenBd_bore_2_indata), .boreChildrenBd_bore_2_readen(boreChildrenBd_bore_2_readen), .boreChildrenBd_bore_2_addr_rd(boreChildrenBd_bore_2_addr_rd), .boreChildrenBd_bore_3_array(boreChildrenBd_bore_3_array), .boreChildrenBd_bore_3_all(boreChildrenBd_bore_3_all), .boreChildrenBd_bore_3_req(boreChildrenBd_bore_3_req), .boreChildrenBd_bore_3_writeen(boreChildrenBd_bore_3_writeen), .boreChildrenBd_bore_3_be(boreChildrenBd_bore_3_be), .boreChildrenBd_bore_3_addr(boreChildrenBd_bore_3_addr), .boreChildrenBd_bore_3_indata(boreChildrenBd_bore_3_indata), .boreChildrenBd_bore_3_readen(boreChildrenBd_bore_3_readen), .boreChildrenBd_bore_3_addr_rd(boreChildrenBd_bore_3_addr_rd), .boreChildrenBd_bore_4_array(boreChildrenBd_bore_4_array), .boreChildrenBd_bore_4_all(boreChildrenBd_bore_4_all), .boreChildrenBd_bore_4_req(boreChildrenBd_bore_4_req), .boreChildrenBd_bore_4_writeen(boreChildrenBd_bore_4_writeen), .boreChildrenBd_bore_4_be(boreChildrenBd_bore_4_be), .boreChildrenBd_bore_4_addr(boreChildrenBd_bore_4_addr), .boreChildrenBd_bore_4_indata(boreChildrenBd_bore_4_indata), .boreChildrenBd_bore_4_readen(boreChildrenBd_bore_4_readen), .boreChildrenBd_bore_4_addr_rd(boreChildrenBd_bore_4_addr_rd), .boreChildrenBd_bore_5_array(boreChildrenBd_bore_5_array), .boreChildrenBd_bore_5_all(boreChildrenBd_bore_5_all), .boreChildrenBd_bore_5_req(boreChildrenBd_bore_5_req), .boreChildrenBd_bore_5_writeen(boreChildrenBd_bore_5_writeen), .boreChildrenBd_bore_5_be(boreChildrenBd_bore_5_be), .boreChildrenBd_bore_5_addr(boreChildrenBd_bore_5_addr), .boreChildrenBd_bore_5_indata(boreChildrenBd_bore_5_indata), .boreChildrenBd_bore_5_readen(boreChildrenBd_bore_5_readen), .boreChildrenBd_bore_5_addr_rd(boreChildrenBd_bore_5_addr_rd), .boreChildrenBd_bore_6_array(boreChildrenBd_bore_6_array), .boreChildrenBd_bore_6_all(boreChildrenBd_bore_6_all), .boreChildrenBd_bore_6_req(boreChildrenBd_bore_6_req), .boreChildrenBd_bore_6_writeen(boreChildrenBd_bore_6_writeen), .boreChildrenBd_bore_6_be(boreChildrenBd_bore_6_be), .boreChildrenBd_bore_6_addr(boreChildrenBd_bore_6_addr), .boreChildrenBd_bore_6_indata(boreChildrenBd_bore_6_indata), .boreChildrenBd_bore_6_readen(boreChildrenBd_bore_6_readen), .boreChildrenBd_bore_6_addr_rd(boreChildrenBd_bore_6_addr_rd), .boreChildrenBd_bore_7_array(boreChildrenBd_bore_7_array), .boreChildrenBd_bore_7_all(boreChildrenBd_bore_7_all), .boreChildrenBd_bore_7_req(boreChildrenBd_bore_7_req), .boreChildrenBd_bore_7_writeen(boreChildrenBd_bore_7_writeen), .boreChildrenBd_bore_7_be(boreChildrenBd_bore_7_be), .boreChildrenBd_bore_7_addr(boreChildrenBd_bore_7_addr), .boreChildrenBd_bore_7_indata(boreChildrenBd_bore_7_indata), .boreChildrenBd_bore_7_readen(boreChildrenBd_bore_7_readen), .boreChildrenBd_bore_7_addr_rd(boreChildrenBd_bore_7_addr_rd), .boreChildrenBd_bore_8_array(boreChildrenBd_bore_8_array), .boreChildrenBd_bore_8_all(boreChildrenBd_bore_8_all), .boreChildrenBd_bore_8_req(boreChildrenBd_bore_8_req), .boreChildrenBd_bore_8_writeen(boreChildrenBd_bore_8_writeen), .boreChildrenBd_bore_8_be(boreChildrenBd_bore_8_be), .boreChildrenBd_bore_8_addr(boreChildrenBd_bore_8_addr), .boreChildrenBd_bore_8_indata(boreChildrenBd_bore_8_indata), .boreChildrenBd_bore_8_readen(boreChildrenBd_bore_8_readen), .boreChildrenBd_bore_8_addr_rd(boreChildrenBd_bore_8_addr_rd), .boreChildrenBd_bore_9_array(boreChildrenBd_bore_9_array), .boreChildrenBd_bore_9_all(boreChildrenBd_bore_9_all), .boreChildrenBd_bore_9_req(boreChildrenBd_bore_9_req), .boreChildrenBd_bore_9_writeen(boreChildrenBd_bore_9_writeen), .boreChildrenBd_bore_9_be(boreChildrenBd_bore_9_be), .boreChildrenBd_bore_9_addr(boreChildrenBd_bore_9_addr), .boreChildrenBd_bore_9_indata(boreChildrenBd_bore_9_indata), .boreChildrenBd_bore_9_readen(boreChildrenBd_bore_9_readen), .boreChildrenBd_bore_9_addr_rd(boreChildrenBd_bore_9_addr_rd), .boreChildrenBd_bore_10_array(boreChildrenBd_bore_10_array), .boreChildrenBd_bore_10_all(boreChildrenBd_bore_10_all), .boreChildrenBd_bore_10_req(boreChildrenBd_bore_10_req), .boreChildrenBd_bore_10_writeen(boreChildrenBd_bore_10_writeen), .boreChildrenBd_bore_10_be(boreChildrenBd_bore_10_be), .boreChildrenBd_bore_10_addr(boreChildrenBd_bore_10_addr), .boreChildrenBd_bore_10_indata(boreChildrenBd_bore_10_indata), .boreChildrenBd_bore_10_readen(boreChildrenBd_bore_10_readen), .boreChildrenBd_bore_10_addr_rd(boreChildrenBd_bore_10_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold), .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass), .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken), .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk), .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp), .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold), .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen), .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold), .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass), .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken), .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk), .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp), .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold), .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen), .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold), .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass), .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken), .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk), .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp), .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold), .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen), .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold), .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass), .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken), .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk), .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp), .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold), .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen), .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold), .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass), .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken), .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk), .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp), .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold), .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen), .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold), .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass), .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken), .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk), .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp), .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold), .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen), .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold), .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass), .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken), .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk), .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp), .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold), .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen), .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold), .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass), .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken), .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk), .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp), .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold), .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen), .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold), .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass), .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken), .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk), .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp), .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold), .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen), .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold), .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass), .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken), .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk), .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp), .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold), .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen), .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold), .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass), .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken), .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk), .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp), .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold), .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen), .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold), .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass), .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken), .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk), .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp), .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold), .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen), .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold), .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass), .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken), .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk), .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp), .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold), .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen), .sigFromSrams_bore_21_ram_hold(sigFromSrams_bore_21_ram_hold), .sigFromSrams_bore_21_ram_bypass(sigFromSrams_bore_21_ram_bypass), .sigFromSrams_bore_21_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken), .sigFromSrams_bore_21_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk), .sigFromSrams_bore_21_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp), .sigFromSrams_bore_21_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold), .sigFromSrams_bore_21_cgen(sigFromSrams_bore_21_cgen), .sigFromSrams_bore_22_ram_hold(sigFromSrams_bore_22_ram_hold), .sigFromSrams_bore_22_ram_bypass(sigFromSrams_bore_22_ram_bypass), .sigFromSrams_bore_22_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken), .sigFromSrams_bore_22_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk), .sigFromSrams_bore_22_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp), .sigFromSrams_bore_22_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold), .sigFromSrams_bore_22_cgen(sigFromSrams_bore_22_cgen), .sigFromSrams_bore_23_ram_hold(sigFromSrams_bore_23_ram_hold), .sigFromSrams_bore_23_ram_bypass(sigFromSrams_bore_23_ram_bypass), .sigFromSrams_bore_23_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken), .sigFromSrams_bore_23_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk), .sigFromSrams_bore_23_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp), .sigFromSrams_bore_23_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold), .sigFromSrams_bore_23_cgen(sigFromSrams_bore_23_cgen), .sigFromSrams_bore_24_ram_hold(sigFromSrams_bore_24_ram_hold), .sigFromSrams_bore_24_ram_bypass(sigFromSrams_bore_24_ram_bypass), .sigFromSrams_bore_24_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken), .sigFromSrams_bore_24_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk), .sigFromSrams_bore_24_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp), .sigFromSrams_bore_24_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold), .sigFromSrams_bore_24_cgen(sigFromSrams_bore_24_cgen), .sigFromSrams_bore_25_ram_hold(sigFromSrams_bore_25_ram_hold), .sigFromSrams_bore_25_ram_bypass(sigFromSrams_bore_25_ram_bypass), .sigFromSrams_bore_25_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken), .sigFromSrams_bore_25_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk), .sigFromSrams_bore_25_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp), .sigFromSrams_bore_25_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold), .sigFromSrams_bore_25_cgen(sigFromSrams_bore_25_cgen), .sigFromSrams_bore_26_ram_hold(sigFromSrams_bore_26_ram_hold), .sigFromSrams_bore_26_ram_bypass(sigFromSrams_bore_26_ram_bypass), .sigFromSrams_bore_26_ram_bp_clken(sigFromSrams_bore_26_ram_bp_clken), .sigFromSrams_bore_26_ram_aux_clk(sigFromSrams_bore_26_ram_aux_clk), .sigFromSrams_bore_26_ram_aux_ckbp(sigFromSrams_bore_26_ram_aux_ckbp), .sigFromSrams_bore_26_ram_mcp_hold(sigFromSrams_bore_26_ram_mcp_hold), .sigFromSrams_bore_26_cgen(sigFromSrams_bore_26_cgen), .sigFromSrams_bore_27_ram_hold(sigFromSrams_bore_27_ram_hold), .sigFromSrams_bore_27_ram_bypass(sigFromSrams_bore_27_ram_bypass), .sigFromSrams_bore_27_ram_bp_clken(sigFromSrams_bore_27_ram_bp_clken), .sigFromSrams_bore_27_ram_aux_clk(sigFromSrams_bore_27_ram_aux_clk), .sigFromSrams_bore_27_ram_aux_ckbp(sigFromSrams_bore_27_ram_aux_ckbp), .sigFromSrams_bore_27_ram_mcp_hold(sigFromSrams_bore_27_ram_mcp_hold), .sigFromSrams_bore_27_cgen(sigFromSrams_bore_27_cgen), .sigFromSrams_bore_28_ram_hold(sigFromSrams_bore_28_ram_hold), .sigFromSrams_bore_28_ram_bypass(sigFromSrams_bore_28_ram_bypass), .sigFromSrams_bore_28_ram_bp_clken(sigFromSrams_bore_28_ram_bp_clken), .sigFromSrams_bore_28_ram_aux_clk(sigFromSrams_bore_28_ram_aux_clk), .sigFromSrams_bore_28_ram_aux_ckbp(sigFromSrams_bore_28_ram_aux_ckbp), .sigFromSrams_bore_28_ram_mcp_hold(sigFromSrams_bore_28_ram_mcp_hold), .sigFromSrams_bore_28_cgen(sigFromSrams_bore_28_cgen), .sigFromSrams_bore_29_ram_hold(sigFromSrams_bore_29_ram_hold), .sigFromSrams_bore_29_ram_bypass(sigFromSrams_bore_29_ram_bypass), .sigFromSrams_bore_29_ram_bp_clken(sigFromSrams_bore_29_ram_bp_clken), .sigFromSrams_bore_29_ram_aux_clk(sigFromSrams_bore_29_ram_aux_clk), .sigFromSrams_bore_29_ram_aux_ckbp(sigFromSrams_bore_29_ram_aux_ckbp), .sigFromSrams_bore_29_ram_mcp_hold(sigFromSrams_bore_29_ram_mcp_hold), .sigFromSrams_bore_29_cgen(sigFromSrams_bore_29_cgen), .sigFromSrams_bore_30_ram_hold(sigFromSrams_bore_30_ram_hold), .sigFromSrams_bore_30_ram_bypass(sigFromSrams_bore_30_ram_bypass), .sigFromSrams_bore_30_ram_bp_clken(sigFromSrams_bore_30_ram_bp_clken), .sigFromSrams_bore_30_ram_aux_clk(sigFromSrams_bore_30_ram_aux_clk), .sigFromSrams_bore_30_ram_aux_ckbp(sigFromSrams_bore_30_ram_aux_ckbp), .sigFromSrams_bore_30_ram_mcp_hold(sigFromSrams_bore_30_ram_mcp_hold), .sigFromSrams_bore_30_cgen(sigFromSrams_bore_30_cgen), .sigFromSrams_bore_31_ram_hold(sigFromSrams_bore_31_ram_hold), .sigFromSrams_bore_31_ram_bypass(sigFromSrams_bore_31_ram_bypass), .sigFromSrams_bore_31_ram_bp_clken(sigFromSrams_bore_31_ram_bp_clken), .sigFromSrams_bore_31_ram_aux_clk(sigFromSrams_bore_31_ram_aux_clk), .sigFromSrams_bore_31_ram_aux_ckbp(sigFromSrams_bore_31_ram_aux_ckbp), .sigFromSrams_bore_31_ram_mcp_hold(sigFromSrams_bore_31_ram_mcp_hold), .sigFromSrams_bore_31_cgen(sigFromSrams_bore_31_cgen), .sigFromSrams_bore_32_ram_hold(sigFromSrams_bore_32_ram_hold), .sigFromSrams_bore_32_ram_bypass(sigFromSrams_bore_32_ram_bypass), .sigFromSrams_bore_32_ram_bp_clken(sigFromSrams_bore_32_ram_bp_clken), .sigFromSrams_bore_32_ram_aux_clk(sigFromSrams_bore_32_ram_aux_clk), .sigFromSrams_bore_32_ram_aux_ckbp(sigFromSrams_bore_32_ram_aux_ckbp), .sigFromSrams_bore_32_ram_mcp_hold(sigFromSrams_bore_32_ram_mcp_hold), .sigFromSrams_bore_32_cgen(sigFromSrams_bore_32_cgen), .sigFromSrams_bore_33_ram_hold(sigFromSrams_bore_33_ram_hold), .sigFromSrams_bore_33_ram_bypass(sigFromSrams_bore_33_ram_bypass), .sigFromSrams_bore_33_ram_bp_clken(sigFromSrams_bore_33_ram_bp_clken), .sigFromSrams_bore_33_ram_aux_clk(sigFromSrams_bore_33_ram_aux_clk), .sigFromSrams_bore_33_ram_aux_ckbp(sigFromSrams_bore_33_ram_aux_ckbp), .sigFromSrams_bore_33_ram_mcp_hold(sigFromSrams_bore_33_ram_mcp_hold), .sigFromSrams_bore_33_cgen(sigFromSrams_bore_33_cgen), .sigFromSrams_bore_34_ram_hold(sigFromSrams_bore_34_ram_hold), .sigFromSrams_bore_34_ram_bypass(sigFromSrams_bore_34_ram_bypass), .sigFromSrams_bore_34_ram_bp_clken(sigFromSrams_bore_34_ram_bp_clken), .sigFromSrams_bore_34_ram_aux_clk(sigFromSrams_bore_34_ram_aux_clk), .sigFromSrams_bore_34_ram_aux_ckbp(sigFromSrams_bore_34_ram_aux_ckbp), .sigFromSrams_bore_34_ram_mcp_hold(sigFromSrams_bore_34_ram_mcp_hold), .sigFromSrams_bore_34_cgen(sigFromSrams_bore_34_cgen), .sigFromSrams_bore_35_ram_hold(sigFromSrams_bore_35_ram_hold), .sigFromSrams_bore_35_ram_bypass(sigFromSrams_bore_35_ram_bypass), .sigFromSrams_bore_35_ram_bp_clken(sigFromSrams_bore_35_ram_bp_clken), .sigFromSrams_bore_35_ram_aux_clk(sigFromSrams_bore_35_ram_aux_clk), .sigFromSrams_bore_35_ram_aux_ckbp(sigFromSrams_bore_35_ram_aux_ckbp), .sigFromSrams_bore_35_ram_mcp_hold(sigFromSrams_bore_35_ram_mcp_hold), .sigFromSrams_bore_35_cgen(sigFromSrams_bore_35_cgen), .sigFromSrams_bore_36_ram_hold(sigFromSrams_bore_36_ram_hold), .sigFromSrams_bore_36_ram_bypass(sigFromSrams_bore_36_ram_bypass), .sigFromSrams_bore_36_ram_bp_clken(sigFromSrams_bore_36_ram_bp_clken), .sigFromSrams_bore_36_ram_aux_clk(sigFromSrams_bore_36_ram_aux_clk), .sigFromSrams_bore_36_ram_aux_ckbp(sigFromSrams_bore_36_ram_aux_ckbp), .sigFromSrams_bore_36_ram_mcp_hold(sigFromSrams_bore_36_ram_mcp_hold), .sigFromSrams_bore_36_cgen(sigFromSrams_bore_36_cgen), .sigFromSrams_bore_37_ram_hold(sigFromSrams_bore_37_ram_hold), .sigFromSrams_bore_37_ram_bypass(sigFromSrams_bore_37_ram_bypass), .sigFromSrams_bore_37_ram_bp_clken(sigFromSrams_bore_37_ram_bp_clken), .sigFromSrams_bore_37_ram_aux_clk(sigFromSrams_bore_37_ram_aux_clk), .sigFromSrams_bore_37_ram_aux_ckbp(sigFromSrams_bore_37_ram_aux_ckbp), .sigFromSrams_bore_37_ram_mcp_hold(sigFromSrams_bore_37_ram_mcp_hold), .sigFromSrams_bore_37_cgen(sigFromSrams_bore_37_cgen), .sigFromSrams_bore_38_ram_hold(sigFromSrams_bore_38_ram_hold), .sigFromSrams_bore_38_ram_bypass(sigFromSrams_bore_38_ram_bypass), .sigFromSrams_bore_38_ram_bp_clken(sigFromSrams_bore_38_ram_bp_clken), .sigFromSrams_bore_38_ram_aux_clk(sigFromSrams_bore_38_ram_aux_clk), .sigFromSrams_bore_38_ram_aux_ckbp(sigFromSrams_bore_38_ram_aux_ckbp), .sigFromSrams_bore_38_ram_mcp_hold(sigFromSrams_bore_38_ram_mcp_hold), .sigFromSrams_bore_38_cgen(sigFromSrams_bore_38_cgen), .sigFromSrams_bore_39_ram_hold(sigFromSrams_bore_39_ram_hold), .sigFromSrams_bore_39_ram_bypass(sigFromSrams_bore_39_ram_bypass), .sigFromSrams_bore_39_ram_bp_clken(sigFromSrams_bore_39_ram_bp_clken), .sigFromSrams_bore_39_ram_aux_clk(sigFromSrams_bore_39_ram_aux_clk), .sigFromSrams_bore_39_ram_aux_ckbp(sigFromSrams_bore_39_ram_aux_ckbp), .sigFromSrams_bore_39_ram_mcp_hold(sigFromSrams_bore_39_ram_mcp_hold), .sigFromSrams_bore_39_cgen(sigFromSrams_bore_39_cgen), .sigFromSrams_bore_40_ram_hold(sigFromSrams_bore_40_ram_hold), .sigFromSrams_bore_40_ram_bypass(sigFromSrams_bore_40_ram_bypass), .sigFromSrams_bore_40_ram_bp_clken(sigFromSrams_bore_40_ram_bp_clken), .sigFromSrams_bore_40_ram_aux_clk(sigFromSrams_bore_40_ram_aux_clk), .sigFromSrams_bore_40_ram_aux_ckbp(sigFromSrams_bore_40_ram_aux_ckbp), .sigFromSrams_bore_40_ram_mcp_hold(sigFromSrams_bore_40_ram_mcp_hold), .sigFromSrams_bore_40_cgen(sigFromSrams_bore_40_cgen), .sigFromSrams_bore_41_ram_hold(sigFromSrams_bore_41_ram_hold), .sigFromSrams_bore_41_ram_bypass(sigFromSrams_bore_41_ram_bypass), .sigFromSrams_bore_41_ram_bp_clken(sigFromSrams_bore_41_ram_bp_clken), .sigFromSrams_bore_41_ram_aux_clk(sigFromSrams_bore_41_ram_aux_clk), .sigFromSrams_bore_41_ram_aux_ckbp(sigFromSrams_bore_41_ram_aux_ckbp), .sigFromSrams_bore_41_ram_mcp_hold(sigFromSrams_bore_41_ram_mcp_hold), .sigFromSrams_bore_41_cgen(sigFromSrams_bore_41_cgen), .io_bpu_to_ftq_resp_valid(g_io_bpu_to_ftq_resp_valid), .io_bpu_to_ftq_resp_bits_s1_pc_3(g_io_bpu_to_ftq_resp_bits_s1_pc_3), .io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle(g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit), .io_bpu_to_ftq_resp_bits_s2_pc_3(g_io_bpu_to_ftq_resp_bits_s2_pc_3), .io_bpu_to_ftq_resp_bits_s2_valid_3(g_io_bpu_to_ftq_resp_bits_s2_valid_3), .io_bpu_to_ftq_resp_bits_s2_hasRedirect_3(g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3), .io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag), .io_bpu_to_ftq_resp_bits_s2_ftq_idx_value(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value), .io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle(g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit), .io_bpu_to_ftq_resp_bits_s3_pc_0(g_io_bpu_to_ftq_resp_bits_s3_pc_0), .io_bpu_to_ftq_resp_bits_s3_pc_3(g_io_bpu_to_ftq_resp_bits_s3_pc_3), .io_bpu_to_ftq_resp_bits_s3_valid_0(g_io_bpu_to_ftq_resp_bits_s3_valid_0), .io_bpu_to_ftq_resp_bits_s3_valid_3(g_io_bpu_to_ftq_resp_bits_s3_valid_3), .io_bpu_to_ftq_resp_bits_s3_hasRedirect_3(g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3), .io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag), .io_bpu_to_ftq_resp_bits_s3_ftq_idx_value(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value), .io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle(g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit), .io_bpu_to_ftq_resp_bits_last_stage_meta(g_io_bpu_to_ftq_resp_bits_last_stage_meta), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_1(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_2(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_3(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_4(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_5(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_6(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_7(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_8(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_9(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_12(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata), .boreChildrenBd_bore_1_ack(g_boreChildrenBd_bore_1_ack), .boreChildrenBd_bore_1_outdata(g_boreChildrenBd_bore_1_outdata), .boreChildrenBd_bore_2_ack(g_boreChildrenBd_bore_2_ack), .boreChildrenBd_bore_2_outdata(g_boreChildrenBd_bore_2_outdata), .boreChildrenBd_bore_3_ack(g_boreChildrenBd_bore_3_ack), .boreChildrenBd_bore_3_outdata(g_boreChildrenBd_bore_3_outdata), .boreChildrenBd_bore_4_ack(g_boreChildrenBd_bore_4_ack), .boreChildrenBd_bore_4_outdata(g_boreChildrenBd_bore_4_outdata), .boreChildrenBd_bore_5_ack(g_boreChildrenBd_bore_5_ack), .boreChildrenBd_bore_5_outdata(g_boreChildrenBd_bore_5_outdata), .boreChildrenBd_bore_6_ack(g_boreChildrenBd_bore_6_ack), .boreChildrenBd_bore_6_outdata(g_boreChildrenBd_bore_6_outdata), .boreChildrenBd_bore_7_ack(g_boreChildrenBd_bore_7_ack), .boreChildrenBd_bore_7_outdata(g_boreChildrenBd_bore_7_outdata), .boreChildrenBd_bore_8_ack(g_boreChildrenBd_bore_8_ack), .boreChildrenBd_bore_8_outdata(g_boreChildrenBd_bore_8_outdata), .boreChildrenBd_bore_9_ack(g_boreChildrenBd_bore_9_ack), .boreChildrenBd_bore_9_outdata(g_boreChildrenBd_bore_9_outdata), .boreChildrenBd_bore_10_ack(g_boreChildrenBd_bore_10_ack), .boreChildrenBd_bore_10_outdata(g_boreChildrenBd_bore_10_outdata));
  Predictor_xs u_i (.clock(clk), .reset(rst), .io_bpu_to_ftq_resp_ready(io_bpu_to_ftq_resp_ready), .io_ftq_to_bpu_redirect_valid(io_ftq_to_bpu_redirect_valid), .io_ftq_to_bpu_redirect_bits_level(io_ftq_to_bpu_redirect_bits_level), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pc(io_ftq_to_bpu_redirect_bits_cfiUpdate_pc), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall), .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet(io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet), .io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp(io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp), .io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr(io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag), .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value(io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value), .io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit), .io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit), .io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit(io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit), .io_ftq_to_bpu_redirect_bits_cfiUpdate_target(io_ftq_to_bpu_redirect_bits_cfiUpdate_target), .io_ftq_to_bpu_redirect_bits_cfiUpdate_taken(io_ftq_to_bpu_redirect_bits_cfiUpdate_taken), .io_ftq_to_bpu_redirect_bits_cfiUpdate_shift(io_ftq_to_bpu_redirect_bits_cfiUpdate_shift), .io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist(io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist), .io_ftq_to_bpu_redirect_bits_debugIsCtrl(io_ftq_to_bpu_redirect_bits_debugIsCtrl), .io_ftq_to_bpu_redirect_bits_debugIsMemVio(io_ftq_to_bpu_redirect_bits_debugIsMemVio), .io_ftq_to_bpu_redirect_bits_BTBMissBubble(io_ftq_to_bpu_redirect_bits_BTBMissBubble), .io_ftq_to_bpu_update_valid(io_ftq_to_bpu_update_valid), .io_ftq_to_bpu_update_bits_pc(io_ftq_to_bpu_update_bits_pc), .io_ftq_to_bpu_update_bits_spec_info_histPtr_value(io_ftq_to_bpu_update_bits_spec_info_histPtr_value), .io_ftq_to_bpu_update_bits_ftb_entry_isCall(io_ftq_to_bpu_update_bits_ftb_entry_isCall), .io_ftq_to_bpu_update_bits_ftb_entry_isRet(io_ftq_to_bpu_update_bits_ftb_entry_isRet), .io_ftq_to_bpu_update_bits_ftb_entry_isJalr(io_ftq_to_bpu_update_bits_ftb_entry_isJalr), .io_ftq_to_bpu_update_bits_ftb_entry_valid(io_ftq_to_bpu_update_bits_ftb_entry_valid), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower), .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower), .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat(io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat), .io_ftq_to_bpu_update_bits_ftb_entry_pftAddr(io_ftq_to_bpu_update_bits_ftb_entry_pftAddr), .io_ftq_to_bpu_update_bits_ftb_entry_carry(io_ftq_to_bpu_update_bits_ftb_entry_carry), .io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call(io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call), .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0), .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1(io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1), .io_ftq_to_bpu_update_bits_cfi_idx_valid(io_ftq_to_bpu_update_bits_cfi_idx_valid), .io_ftq_to_bpu_update_bits_cfi_idx_bits(io_ftq_to_bpu_update_bits_cfi_idx_bits), .io_ftq_to_bpu_update_bits_br_taken_mask_0(io_ftq_to_bpu_update_bits_br_taken_mask_0), .io_ftq_to_bpu_update_bits_br_taken_mask_1(io_ftq_to_bpu_update_bits_br_taken_mask_1), .io_ftq_to_bpu_update_bits_jmp_taken(io_ftq_to_bpu_update_bits_jmp_taken), .io_ftq_to_bpu_update_bits_mispred_mask_0(io_ftq_to_bpu_update_bits_mispred_mask_0), .io_ftq_to_bpu_update_bits_mispred_mask_1(io_ftq_to_bpu_update_bits_mispred_mask_1), .io_ftq_to_bpu_update_bits_mispred_mask_2(io_ftq_to_bpu_update_bits_mispred_mask_2), .io_ftq_to_bpu_update_bits_false_hit(io_ftq_to_bpu_update_bits_false_hit), .io_ftq_to_bpu_update_bits_old_entry(io_ftq_to_bpu_update_bits_old_entry), .io_ftq_to_bpu_update_bits_meta(io_ftq_to_bpu_update_bits_meta), .io_ftq_to_bpu_update_bits_full_target(io_ftq_to_bpu_update_bits_full_target), .io_ftq_to_bpu_enq_ptr_flag(io_ftq_to_bpu_enq_ptr_flag), .io_ftq_to_bpu_enq_ptr_value(io_ftq_to_bpu_enq_ptr_value), .io_ftq_to_bpu_redirctFromIFU(io_ftq_to_bpu_redirctFromIFU), .io_ctrl_ubtb_enable(io_ctrl_ubtb_enable), .io_ctrl_btb_enable(io_ctrl_btb_enable), .io_ctrl_tage_enable(io_ctrl_tage_enable), .io_ctrl_sc_enable(io_ctrl_sc_enable), .io_ctrl_ras_enable(io_ctrl_ras_enable), .io_reset_vector(io_reset_vector), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array), .boreChildrenBd_bore_1_all(boreChildrenBd_bore_1_all), .boreChildrenBd_bore_1_req(boreChildrenBd_bore_1_req), .boreChildrenBd_bore_1_writeen(boreChildrenBd_bore_1_writeen), .boreChildrenBd_bore_1_be(boreChildrenBd_bore_1_be), .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_1_indata(boreChildrenBd_bore_1_indata), .boreChildrenBd_bore_1_readen(boreChildrenBd_bore_1_readen), .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd), .boreChildrenBd_bore_2_array(boreChildrenBd_bore_2_array), .boreChildrenBd_bore_2_all(boreChildrenBd_bore_2_all), .boreChildrenBd_bore_2_req(boreChildrenBd_bore_2_req), .boreChildrenBd_bore_2_writeen(boreChildrenBd_bore_2_writeen), .boreChildrenBd_bore_2_be(boreChildrenBd_bore_2_be), .boreChildrenBd_bore_2_addr(boreChildrenBd_bore_2_addr), .boreChildrenBd_bore_2_indata(boreChildrenBd_bore_2_indata), .boreChildrenBd_bore_2_readen(boreChildrenBd_bore_2_readen), .boreChildrenBd_bore_2_addr_rd(boreChildrenBd_bore_2_addr_rd), .boreChildrenBd_bore_3_array(boreChildrenBd_bore_3_array), .boreChildrenBd_bore_3_all(boreChildrenBd_bore_3_all), .boreChildrenBd_bore_3_req(boreChildrenBd_bore_3_req), .boreChildrenBd_bore_3_writeen(boreChildrenBd_bore_3_writeen), .boreChildrenBd_bore_3_be(boreChildrenBd_bore_3_be), .boreChildrenBd_bore_3_addr(boreChildrenBd_bore_3_addr), .boreChildrenBd_bore_3_indata(boreChildrenBd_bore_3_indata), .boreChildrenBd_bore_3_readen(boreChildrenBd_bore_3_readen), .boreChildrenBd_bore_3_addr_rd(boreChildrenBd_bore_3_addr_rd), .boreChildrenBd_bore_4_array(boreChildrenBd_bore_4_array), .boreChildrenBd_bore_4_all(boreChildrenBd_bore_4_all), .boreChildrenBd_bore_4_req(boreChildrenBd_bore_4_req), .boreChildrenBd_bore_4_writeen(boreChildrenBd_bore_4_writeen), .boreChildrenBd_bore_4_be(boreChildrenBd_bore_4_be), .boreChildrenBd_bore_4_addr(boreChildrenBd_bore_4_addr), .boreChildrenBd_bore_4_indata(boreChildrenBd_bore_4_indata), .boreChildrenBd_bore_4_readen(boreChildrenBd_bore_4_readen), .boreChildrenBd_bore_4_addr_rd(boreChildrenBd_bore_4_addr_rd), .boreChildrenBd_bore_5_array(boreChildrenBd_bore_5_array), .boreChildrenBd_bore_5_all(boreChildrenBd_bore_5_all), .boreChildrenBd_bore_5_req(boreChildrenBd_bore_5_req), .boreChildrenBd_bore_5_writeen(boreChildrenBd_bore_5_writeen), .boreChildrenBd_bore_5_be(boreChildrenBd_bore_5_be), .boreChildrenBd_bore_5_addr(boreChildrenBd_bore_5_addr), .boreChildrenBd_bore_5_indata(boreChildrenBd_bore_5_indata), .boreChildrenBd_bore_5_readen(boreChildrenBd_bore_5_readen), .boreChildrenBd_bore_5_addr_rd(boreChildrenBd_bore_5_addr_rd), .boreChildrenBd_bore_6_array(boreChildrenBd_bore_6_array), .boreChildrenBd_bore_6_all(boreChildrenBd_bore_6_all), .boreChildrenBd_bore_6_req(boreChildrenBd_bore_6_req), .boreChildrenBd_bore_6_writeen(boreChildrenBd_bore_6_writeen), .boreChildrenBd_bore_6_be(boreChildrenBd_bore_6_be), .boreChildrenBd_bore_6_addr(boreChildrenBd_bore_6_addr), .boreChildrenBd_bore_6_indata(boreChildrenBd_bore_6_indata), .boreChildrenBd_bore_6_readen(boreChildrenBd_bore_6_readen), .boreChildrenBd_bore_6_addr_rd(boreChildrenBd_bore_6_addr_rd), .boreChildrenBd_bore_7_array(boreChildrenBd_bore_7_array), .boreChildrenBd_bore_7_all(boreChildrenBd_bore_7_all), .boreChildrenBd_bore_7_req(boreChildrenBd_bore_7_req), .boreChildrenBd_bore_7_writeen(boreChildrenBd_bore_7_writeen), .boreChildrenBd_bore_7_be(boreChildrenBd_bore_7_be), .boreChildrenBd_bore_7_addr(boreChildrenBd_bore_7_addr), .boreChildrenBd_bore_7_indata(boreChildrenBd_bore_7_indata), .boreChildrenBd_bore_7_readen(boreChildrenBd_bore_7_readen), .boreChildrenBd_bore_7_addr_rd(boreChildrenBd_bore_7_addr_rd), .boreChildrenBd_bore_8_array(boreChildrenBd_bore_8_array), .boreChildrenBd_bore_8_all(boreChildrenBd_bore_8_all), .boreChildrenBd_bore_8_req(boreChildrenBd_bore_8_req), .boreChildrenBd_bore_8_writeen(boreChildrenBd_bore_8_writeen), .boreChildrenBd_bore_8_be(boreChildrenBd_bore_8_be), .boreChildrenBd_bore_8_addr(boreChildrenBd_bore_8_addr), .boreChildrenBd_bore_8_indata(boreChildrenBd_bore_8_indata), .boreChildrenBd_bore_8_readen(boreChildrenBd_bore_8_readen), .boreChildrenBd_bore_8_addr_rd(boreChildrenBd_bore_8_addr_rd), .boreChildrenBd_bore_9_array(boreChildrenBd_bore_9_array), .boreChildrenBd_bore_9_all(boreChildrenBd_bore_9_all), .boreChildrenBd_bore_9_req(boreChildrenBd_bore_9_req), .boreChildrenBd_bore_9_writeen(boreChildrenBd_bore_9_writeen), .boreChildrenBd_bore_9_be(boreChildrenBd_bore_9_be), .boreChildrenBd_bore_9_addr(boreChildrenBd_bore_9_addr), .boreChildrenBd_bore_9_indata(boreChildrenBd_bore_9_indata), .boreChildrenBd_bore_9_readen(boreChildrenBd_bore_9_readen), .boreChildrenBd_bore_9_addr_rd(boreChildrenBd_bore_9_addr_rd), .boreChildrenBd_bore_10_array(boreChildrenBd_bore_10_array), .boreChildrenBd_bore_10_all(boreChildrenBd_bore_10_all), .boreChildrenBd_bore_10_req(boreChildrenBd_bore_10_req), .boreChildrenBd_bore_10_writeen(boreChildrenBd_bore_10_writeen), .boreChildrenBd_bore_10_be(boreChildrenBd_bore_10_be), .boreChildrenBd_bore_10_addr(boreChildrenBd_bore_10_addr), .boreChildrenBd_bore_10_indata(boreChildrenBd_bore_10_indata), .boreChildrenBd_bore_10_readen(boreChildrenBd_bore_10_readen), .boreChildrenBd_bore_10_addr_rd(boreChildrenBd_bore_10_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .sigFromSrams_bore_8_ram_hold(sigFromSrams_bore_8_ram_hold), .sigFromSrams_bore_8_ram_bypass(sigFromSrams_bore_8_ram_bypass), .sigFromSrams_bore_8_ram_bp_clken(sigFromSrams_bore_8_ram_bp_clken), .sigFromSrams_bore_8_ram_aux_clk(sigFromSrams_bore_8_ram_aux_clk), .sigFromSrams_bore_8_ram_aux_ckbp(sigFromSrams_bore_8_ram_aux_ckbp), .sigFromSrams_bore_8_ram_mcp_hold(sigFromSrams_bore_8_ram_mcp_hold), .sigFromSrams_bore_8_cgen(sigFromSrams_bore_8_cgen), .sigFromSrams_bore_9_ram_hold(sigFromSrams_bore_9_ram_hold), .sigFromSrams_bore_9_ram_bypass(sigFromSrams_bore_9_ram_bypass), .sigFromSrams_bore_9_ram_bp_clken(sigFromSrams_bore_9_ram_bp_clken), .sigFromSrams_bore_9_ram_aux_clk(sigFromSrams_bore_9_ram_aux_clk), .sigFromSrams_bore_9_ram_aux_ckbp(sigFromSrams_bore_9_ram_aux_ckbp), .sigFromSrams_bore_9_ram_mcp_hold(sigFromSrams_bore_9_ram_mcp_hold), .sigFromSrams_bore_9_cgen(sigFromSrams_bore_9_cgen), .sigFromSrams_bore_10_ram_hold(sigFromSrams_bore_10_ram_hold), .sigFromSrams_bore_10_ram_bypass(sigFromSrams_bore_10_ram_bypass), .sigFromSrams_bore_10_ram_bp_clken(sigFromSrams_bore_10_ram_bp_clken), .sigFromSrams_bore_10_ram_aux_clk(sigFromSrams_bore_10_ram_aux_clk), .sigFromSrams_bore_10_ram_aux_ckbp(sigFromSrams_bore_10_ram_aux_ckbp), .sigFromSrams_bore_10_ram_mcp_hold(sigFromSrams_bore_10_ram_mcp_hold), .sigFromSrams_bore_10_cgen(sigFromSrams_bore_10_cgen), .sigFromSrams_bore_11_ram_hold(sigFromSrams_bore_11_ram_hold), .sigFromSrams_bore_11_ram_bypass(sigFromSrams_bore_11_ram_bypass), .sigFromSrams_bore_11_ram_bp_clken(sigFromSrams_bore_11_ram_bp_clken), .sigFromSrams_bore_11_ram_aux_clk(sigFromSrams_bore_11_ram_aux_clk), .sigFromSrams_bore_11_ram_aux_ckbp(sigFromSrams_bore_11_ram_aux_ckbp), .sigFromSrams_bore_11_ram_mcp_hold(sigFromSrams_bore_11_ram_mcp_hold), .sigFromSrams_bore_11_cgen(sigFromSrams_bore_11_cgen), .sigFromSrams_bore_12_ram_hold(sigFromSrams_bore_12_ram_hold), .sigFromSrams_bore_12_ram_bypass(sigFromSrams_bore_12_ram_bypass), .sigFromSrams_bore_12_ram_bp_clken(sigFromSrams_bore_12_ram_bp_clken), .sigFromSrams_bore_12_ram_aux_clk(sigFromSrams_bore_12_ram_aux_clk), .sigFromSrams_bore_12_ram_aux_ckbp(sigFromSrams_bore_12_ram_aux_ckbp), .sigFromSrams_bore_12_ram_mcp_hold(sigFromSrams_bore_12_ram_mcp_hold), .sigFromSrams_bore_12_cgen(sigFromSrams_bore_12_cgen), .sigFromSrams_bore_13_ram_hold(sigFromSrams_bore_13_ram_hold), .sigFromSrams_bore_13_ram_bypass(sigFromSrams_bore_13_ram_bypass), .sigFromSrams_bore_13_ram_bp_clken(sigFromSrams_bore_13_ram_bp_clken), .sigFromSrams_bore_13_ram_aux_clk(sigFromSrams_bore_13_ram_aux_clk), .sigFromSrams_bore_13_ram_aux_ckbp(sigFromSrams_bore_13_ram_aux_ckbp), .sigFromSrams_bore_13_ram_mcp_hold(sigFromSrams_bore_13_ram_mcp_hold), .sigFromSrams_bore_13_cgen(sigFromSrams_bore_13_cgen), .sigFromSrams_bore_14_ram_hold(sigFromSrams_bore_14_ram_hold), .sigFromSrams_bore_14_ram_bypass(sigFromSrams_bore_14_ram_bypass), .sigFromSrams_bore_14_ram_bp_clken(sigFromSrams_bore_14_ram_bp_clken), .sigFromSrams_bore_14_ram_aux_clk(sigFromSrams_bore_14_ram_aux_clk), .sigFromSrams_bore_14_ram_aux_ckbp(sigFromSrams_bore_14_ram_aux_ckbp), .sigFromSrams_bore_14_ram_mcp_hold(sigFromSrams_bore_14_ram_mcp_hold), .sigFromSrams_bore_14_cgen(sigFromSrams_bore_14_cgen), .sigFromSrams_bore_15_ram_hold(sigFromSrams_bore_15_ram_hold), .sigFromSrams_bore_15_ram_bypass(sigFromSrams_bore_15_ram_bypass), .sigFromSrams_bore_15_ram_bp_clken(sigFromSrams_bore_15_ram_bp_clken), .sigFromSrams_bore_15_ram_aux_clk(sigFromSrams_bore_15_ram_aux_clk), .sigFromSrams_bore_15_ram_aux_ckbp(sigFromSrams_bore_15_ram_aux_ckbp), .sigFromSrams_bore_15_ram_mcp_hold(sigFromSrams_bore_15_ram_mcp_hold), .sigFromSrams_bore_15_cgen(sigFromSrams_bore_15_cgen), .sigFromSrams_bore_16_ram_hold(sigFromSrams_bore_16_ram_hold), .sigFromSrams_bore_16_ram_bypass(sigFromSrams_bore_16_ram_bypass), .sigFromSrams_bore_16_ram_bp_clken(sigFromSrams_bore_16_ram_bp_clken), .sigFromSrams_bore_16_ram_aux_clk(sigFromSrams_bore_16_ram_aux_clk), .sigFromSrams_bore_16_ram_aux_ckbp(sigFromSrams_bore_16_ram_aux_ckbp), .sigFromSrams_bore_16_ram_mcp_hold(sigFromSrams_bore_16_ram_mcp_hold), .sigFromSrams_bore_16_cgen(sigFromSrams_bore_16_cgen), .sigFromSrams_bore_17_ram_hold(sigFromSrams_bore_17_ram_hold), .sigFromSrams_bore_17_ram_bypass(sigFromSrams_bore_17_ram_bypass), .sigFromSrams_bore_17_ram_bp_clken(sigFromSrams_bore_17_ram_bp_clken), .sigFromSrams_bore_17_ram_aux_clk(sigFromSrams_bore_17_ram_aux_clk), .sigFromSrams_bore_17_ram_aux_ckbp(sigFromSrams_bore_17_ram_aux_ckbp), .sigFromSrams_bore_17_ram_mcp_hold(sigFromSrams_bore_17_ram_mcp_hold), .sigFromSrams_bore_17_cgen(sigFromSrams_bore_17_cgen), .sigFromSrams_bore_18_ram_hold(sigFromSrams_bore_18_ram_hold), .sigFromSrams_bore_18_ram_bypass(sigFromSrams_bore_18_ram_bypass), .sigFromSrams_bore_18_ram_bp_clken(sigFromSrams_bore_18_ram_bp_clken), .sigFromSrams_bore_18_ram_aux_clk(sigFromSrams_bore_18_ram_aux_clk), .sigFromSrams_bore_18_ram_aux_ckbp(sigFromSrams_bore_18_ram_aux_ckbp), .sigFromSrams_bore_18_ram_mcp_hold(sigFromSrams_bore_18_ram_mcp_hold), .sigFromSrams_bore_18_cgen(sigFromSrams_bore_18_cgen), .sigFromSrams_bore_19_ram_hold(sigFromSrams_bore_19_ram_hold), .sigFromSrams_bore_19_ram_bypass(sigFromSrams_bore_19_ram_bypass), .sigFromSrams_bore_19_ram_bp_clken(sigFromSrams_bore_19_ram_bp_clken), .sigFromSrams_bore_19_ram_aux_clk(sigFromSrams_bore_19_ram_aux_clk), .sigFromSrams_bore_19_ram_aux_ckbp(sigFromSrams_bore_19_ram_aux_ckbp), .sigFromSrams_bore_19_ram_mcp_hold(sigFromSrams_bore_19_ram_mcp_hold), .sigFromSrams_bore_19_cgen(sigFromSrams_bore_19_cgen), .sigFromSrams_bore_20_ram_hold(sigFromSrams_bore_20_ram_hold), .sigFromSrams_bore_20_ram_bypass(sigFromSrams_bore_20_ram_bypass), .sigFromSrams_bore_20_ram_bp_clken(sigFromSrams_bore_20_ram_bp_clken), .sigFromSrams_bore_20_ram_aux_clk(sigFromSrams_bore_20_ram_aux_clk), .sigFromSrams_bore_20_ram_aux_ckbp(sigFromSrams_bore_20_ram_aux_ckbp), .sigFromSrams_bore_20_ram_mcp_hold(sigFromSrams_bore_20_ram_mcp_hold), .sigFromSrams_bore_20_cgen(sigFromSrams_bore_20_cgen), .sigFromSrams_bore_21_ram_hold(sigFromSrams_bore_21_ram_hold), .sigFromSrams_bore_21_ram_bypass(sigFromSrams_bore_21_ram_bypass), .sigFromSrams_bore_21_ram_bp_clken(sigFromSrams_bore_21_ram_bp_clken), .sigFromSrams_bore_21_ram_aux_clk(sigFromSrams_bore_21_ram_aux_clk), .sigFromSrams_bore_21_ram_aux_ckbp(sigFromSrams_bore_21_ram_aux_ckbp), .sigFromSrams_bore_21_ram_mcp_hold(sigFromSrams_bore_21_ram_mcp_hold), .sigFromSrams_bore_21_cgen(sigFromSrams_bore_21_cgen), .sigFromSrams_bore_22_ram_hold(sigFromSrams_bore_22_ram_hold), .sigFromSrams_bore_22_ram_bypass(sigFromSrams_bore_22_ram_bypass), .sigFromSrams_bore_22_ram_bp_clken(sigFromSrams_bore_22_ram_bp_clken), .sigFromSrams_bore_22_ram_aux_clk(sigFromSrams_bore_22_ram_aux_clk), .sigFromSrams_bore_22_ram_aux_ckbp(sigFromSrams_bore_22_ram_aux_ckbp), .sigFromSrams_bore_22_ram_mcp_hold(sigFromSrams_bore_22_ram_mcp_hold), .sigFromSrams_bore_22_cgen(sigFromSrams_bore_22_cgen), .sigFromSrams_bore_23_ram_hold(sigFromSrams_bore_23_ram_hold), .sigFromSrams_bore_23_ram_bypass(sigFromSrams_bore_23_ram_bypass), .sigFromSrams_bore_23_ram_bp_clken(sigFromSrams_bore_23_ram_bp_clken), .sigFromSrams_bore_23_ram_aux_clk(sigFromSrams_bore_23_ram_aux_clk), .sigFromSrams_bore_23_ram_aux_ckbp(sigFromSrams_bore_23_ram_aux_ckbp), .sigFromSrams_bore_23_ram_mcp_hold(sigFromSrams_bore_23_ram_mcp_hold), .sigFromSrams_bore_23_cgen(sigFromSrams_bore_23_cgen), .sigFromSrams_bore_24_ram_hold(sigFromSrams_bore_24_ram_hold), .sigFromSrams_bore_24_ram_bypass(sigFromSrams_bore_24_ram_bypass), .sigFromSrams_bore_24_ram_bp_clken(sigFromSrams_bore_24_ram_bp_clken), .sigFromSrams_bore_24_ram_aux_clk(sigFromSrams_bore_24_ram_aux_clk), .sigFromSrams_bore_24_ram_aux_ckbp(sigFromSrams_bore_24_ram_aux_ckbp), .sigFromSrams_bore_24_ram_mcp_hold(sigFromSrams_bore_24_ram_mcp_hold), .sigFromSrams_bore_24_cgen(sigFromSrams_bore_24_cgen), .sigFromSrams_bore_25_ram_hold(sigFromSrams_bore_25_ram_hold), .sigFromSrams_bore_25_ram_bypass(sigFromSrams_bore_25_ram_bypass), .sigFromSrams_bore_25_ram_bp_clken(sigFromSrams_bore_25_ram_bp_clken), .sigFromSrams_bore_25_ram_aux_clk(sigFromSrams_bore_25_ram_aux_clk), .sigFromSrams_bore_25_ram_aux_ckbp(sigFromSrams_bore_25_ram_aux_ckbp), .sigFromSrams_bore_25_ram_mcp_hold(sigFromSrams_bore_25_ram_mcp_hold), .sigFromSrams_bore_25_cgen(sigFromSrams_bore_25_cgen), .sigFromSrams_bore_26_ram_hold(sigFromSrams_bore_26_ram_hold), .sigFromSrams_bore_26_ram_bypass(sigFromSrams_bore_26_ram_bypass), .sigFromSrams_bore_26_ram_bp_clken(sigFromSrams_bore_26_ram_bp_clken), .sigFromSrams_bore_26_ram_aux_clk(sigFromSrams_bore_26_ram_aux_clk), .sigFromSrams_bore_26_ram_aux_ckbp(sigFromSrams_bore_26_ram_aux_ckbp), .sigFromSrams_bore_26_ram_mcp_hold(sigFromSrams_bore_26_ram_mcp_hold), .sigFromSrams_bore_26_cgen(sigFromSrams_bore_26_cgen), .sigFromSrams_bore_27_ram_hold(sigFromSrams_bore_27_ram_hold), .sigFromSrams_bore_27_ram_bypass(sigFromSrams_bore_27_ram_bypass), .sigFromSrams_bore_27_ram_bp_clken(sigFromSrams_bore_27_ram_bp_clken), .sigFromSrams_bore_27_ram_aux_clk(sigFromSrams_bore_27_ram_aux_clk), .sigFromSrams_bore_27_ram_aux_ckbp(sigFromSrams_bore_27_ram_aux_ckbp), .sigFromSrams_bore_27_ram_mcp_hold(sigFromSrams_bore_27_ram_mcp_hold), .sigFromSrams_bore_27_cgen(sigFromSrams_bore_27_cgen), .sigFromSrams_bore_28_ram_hold(sigFromSrams_bore_28_ram_hold), .sigFromSrams_bore_28_ram_bypass(sigFromSrams_bore_28_ram_bypass), .sigFromSrams_bore_28_ram_bp_clken(sigFromSrams_bore_28_ram_bp_clken), .sigFromSrams_bore_28_ram_aux_clk(sigFromSrams_bore_28_ram_aux_clk), .sigFromSrams_bore_28_ram_aux_ckbp(sigFromSrams_bore_28_ram_aux_ckbp), .sigFromSrams_bore_28_ram_mcp_hold(sigFromSrams_bore_28_ram_mcp_hold), .sigFromSrams_bore_28_cgen(sigFromSrams_bore_28_cgen), .sigFromSrams_bore_29_ram_hold(sigFromSrams_bore_29_ram_hold), .sigFromSrams_bore_29_ram_bypass(sigFromSrams_bore_29_ram_bypass), .sigFromSrams_bore_29_ram_bp_clken(sigFromSrams_bore_29_ram_bp_clken), .sigFromSrams_bore_29_ram_aux_clk(sigFromSrams_bore_29_ram_aux_clk), .sigFromSrams_bore_29_ram_aux_ckbp(sigFromSrams_bore_29_ram_aux_ckbp), .sigFromSrams_bore_29_ram_mcp_hold(sigFromSrams_bore_29_ram_mcp_hold), .sigFromSrams_bore_29_cgen(sigFromSrams_bore_29_cgen), .sigFromSrams_bore_30_ram_hold(sigFromSrams_bore_30_ram_hold), .sigFromSrams_bore_30_ram_bypass(sigFromSrams_bore_30_ram_bypass), .sigFromSrams_bore_30_ram_bp_clken(sigFromSrams_bore_30_ram_bp_clken), .sigFromSrams_bore_30_ram_aux_clk(sigFromSrams_bore_30_ram_aux_clk), .sigFromSrams_bore_30_ram_aux_ckbp(sigFromSrams_bore_30_ram_aux_ckbp), .sigFromSrams_bore_30_ram_mcp_hold(sigFromSrams_bore_30_ram_mcp_hold), .sigFromSrams_bore_30_cgen(sigFromSrams_bore_30_cgen), .sigFromSrams_bore_31_ram_hold(sigFromSrams_bore_31_ram_hold), .sigFromSrams_bore_31_ram_bypass(sigFromSrams_bore_31_ram_bypass), .sigFromSrams_bore_31_ram_bp_clken(sigFromSrams_bore_31_ram_bp_clken), .sigFromSrams_bore_31_ram_aux_clk(sigFromSrams_bore_31_ram_aux_clk), .sigFromSrams_bore_31_ram_aux_ckbp(sigFromSrams_bore_31_ram_aux_ckbp), .sigFromSrams_bore_31_ram_mcp_hold(sigFromSrams_bore_31_ram_mcp_hold), .sigFromSrams_bore_31_cgen(sigFromSrams_bore_31_cgen), .sigFromSrams_bore_32_ram_hold(sigFromSrams_bore_32_ram_hold), .sigFromSrams_bore_32_ram_bypass(sigFromSrams_bore_32_ram_bypass), .sigFromSrams_bore_32_ram_bp_clken(sigFromSrams_bore_32_ram_bp_clken), .sigFromSrams_bore_32_ram_aux_clk(sigFromSrams_bore_32_ram_aux_clk), .sigFromSrams_bore_32_ram_aux_ckbp(sigFromSrams_bore_32_ram_aux_ckbp), .sigFromSrams_bore_32_ram_mcp_hold(sigFromSrams_bore_32_ram_mcp_hold), .sigFromSrams_bore_32_cgen(sigFromSrams_bore_32_cgen), .sigFromSrams_bore_33_ram_hold(sigFromSrams_bore_33_ram_hold), .sigFromSrams_bore_33_ram_bypass(sigFromSrams_bore_33_ram_bypass), .sigFromSrams_bore_33_ram_bp_clken(sigFromSrams_bore_33_ram_bp_clken), .sigFromSrams_bore_33_ram_aux_clk(sigFromSrams_bore_33_ram_aux_clk), .sigFromSrams_bore_33_ram_aux_ckbp(sigFromSrams_bore_33_ram_aux_ckbp), .sigFromSrams_bore_33_ram_mcp_hold(sigFromSrams_bore_33_ram_mcp_hold), .sigFromSrams_bore_33_cgen(sigFromSrams_bore_33_cgen), .sigFromSrams_bore_34_ram_hold(sigFromSrams_bore_34_ram_hold), .sigFromSrams_bore_34_ram_bypass(sigFromSrams_bore_34_ram_bypass), .sigFromSrams_bore_34_ram_bp_clken(sigFromSrams_bore_34_ram_bp_clken), .sigFromSrams_bore_34_ram_aux_clk(sigFromSrams_bore_34_ram_aux_clk), .sigFromSrams_bore_34_ram_aux_ckbp(sigFromSrams_bore_34_ram_aux_ckbp), .sigFromSrams_bore_34_ram_mcp_hold(sigFromSrams_bore_34_ram_mcp_hold), .sigFromSrams_bore_34_cgen(sigFromSrams_bore_34_cgen), .sigFromSrams_bore_35_ram_hold(sigFromSrams_bore_35_ram_hold), .sigFromSrams_bore_35_ram_bypass(sigFromSrams_bore_35_ram_bypass), .sigFromSrams_bore_35_ram_bp_clken(sigFromSrams_bore_35_ram_bp_clken), .sigFromSrams_bore_35_ram_aux_clk(sigFromSrams_bore_35_ram_aux_clk), .sigFromSrams_bore_35_ram_aux_ckbp(sigFromSrams_bore_35_ram_aux_ckbp), .sigFromSrams_bore_35_ram_mcp_hold(sigFromSrams_bore_35_ram_mcp_hold), .sigFromSrams_bore_35_cgen(sigFromSrams_bore_35_cgen), .sigFromSrams_bore_36_ram_hold(sigFromSrams_bore_36_ram_hold), .sigFromSrams_bore_36_ram_bypass(sigFromSrams_bore_36_ram_bypass), .sigFromSrams_bore_36_ram_bp_clken(sigFromSrams_bore_36_ram_bp_clken), .sigFromSrams_bore_36_ram_aux_clk(sigFromSrams_bore_36_ram_aux_clk), .sigFromSrams_bore_36_ram_aux_ckbp(sigFromSrams_bore_36_ram_aux_ckbp), .sigFromSrams_bore_36_ram_mcp_hold(sigFromSrams_bore_36_ram_mcp_hold), .sigFromSrams_bore_36_cgen(sigFromSrams_bore_36_cgen), .sigFromSrams_bore_37_ram_hold(sigFromSrams_bore_37_ram_hold), .sigFromSrams_bore_37_ram_bypass(sigFromSrams_bore_37_ram_bypass), .sigFromSrams_bore_37_ram_bp_clken(sigFromSrams_bore_37_ram_bp_clken), .sigFromSrams_bore_37_ram_aux_clk(sigFromSrams_bore_37_ram_aux_clk), .sigFromSrams_bore_37_ram_aux_ckbp(sigFromSrams_bore_37_ram_aux_ckbp), .sigFromSrams_bore_37_ram_mcp_hold(sigFromSrams_bore_37_ram_mcp_hold), .sigFromSrams_bore_37_cgen(sigFromSrams_bore_37_cgen), .sigFromSrams_bore_38_ram_hold(sigFromSrams_bore_38_ram_hold), .sigFromSrams_bore_38_ram_bypass(sigFromSrams_bore_38_ram_bypass), .sigFromSrams_bore_38_ram_bp_clken(sigFromSrams_bore_38_ram_bp_clken), .sigFromSrams_bore_38_ram_aux_clk(sigFromSrams_bore_38_ram_aux_clk), .sigFromSrams_bore_38_ram_aux_ckbp(sigFromSrams_bore_38_ram_aux_ckbp), .sigFromSrams_bore_38_ram_mcp_hold(sigFromSrams_bore_38_ram_mcp_hold), .sigFromSrams_bore_38_cgen(sigFromSrams_bore_38_cgen), .sigFromSrams_bore_39_ram_hold(sigFromSrams_bore_39_ram_hold), .sigFromSrams_bore_39_ram_bypass(sigFromSrams_bore_39_ram_bypass), .sigFromSrams_bore_39_ram_bp_clken(sigFromSrams_bore_39_ram_bp_clken), .sigFromSrams_bore_39_ram_aux_clk(sigFromSrams_bore_39_ram_aux_clk), .sigFromSrams_bore_39_ram_aux_ckbp(sigFromSrams_bore_39_ram_aux_ckbp), .sigFromSrams_bore_39_ram_mcp_hold(sigFromSrams_bore_39_ram_mcp_hold), .sigFromSrams_bore_39_cgen(sigFromSrams_bore_39_cgen), .sigFromSrams_bore_40_ram_hold(sigFromSrams_bore_40_ram_hold), .sigFromSrams_bore_40_ram_bypass(sigFromSrams_bore_40_ram_bypass), .sigFromSrams_bore_40_ram_bp_clken(sigFromSrams_bore_40_ram_bp_clken), .sigFromSrams_bore_40_ram_aux_clk(sigFromSrams_bore_40_ram_aux_clk), .sigFromSrams_bore_40_ram_aux_ckbp(sigFromSrams_bore_40_ram_aux_ckbp), .sigFromSrams_bore_40_ram_mcp_hold(sigFromSrams_bore_40_ram_mcp_hold), .sigFromSrams_bore_40_cgen(sigFromSrams_bore_40_cgen), .sigFromSrams_bore_41_ram_hold(sigFromSrams_bore_41_ram_hold), .sigFromSrams_bore_41_ram_bypass(sigFromSrams_bore_41_ram_bypass), .sigFromSrams_bore_41_ram_bp_clken(sigFromSrams_bore_41_ram_bp_clken), .sigFromSrams_bore_41_ram_aux_clk(sigFromSrams_bore_41_ram_aux_clk), .sigFromSrams_bore_41_ram_aux_ckbp(sigFromSrams_bore_41_ram_aux_ckbp), .sigFromSrams_bore_41_ram_mcp_hold(sigFromSrams_bore_41_ram_mcp_hold), .sigFromSrams_bore_41_cgen(sigFromSrams_bore_41_cgen), .io_bpu_to_ftq_resp_valid(i_io_bpu_to_ftq_resp_valid), .io_bpu_to_ftq_resp_bits_s1_pc_3(i_io_bpu_to_ftq_resp_bits_s1_pc_3), .io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle(i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing), .io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit), .io_bpu_to_ftq_resp_bits_s2_pc_3(i_io_bpu_to_ftq_resp_bits_s2_pc_3), .io_bpu_to_ftq_resp_bits_s2_valid_3(i_io_bpu_to_ftq_resp_bits_s2_valid_3), .io_bpu_to_ftq_resp_bits_s2_hasRedirect_3(i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3), .io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag(i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag), .io_bpu_to_ftq_resp_bits_s2_ftq_idx_value(i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value), .io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle(i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing), .io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit), .io_bpu_to_ftq_resp_bits_s3_pc_0(i_io_bpu_to_ftq_resp_bits_s3_pc_0), .io_bpu_to_ftq_resp_bits_s3_pc_3(i_io_bpu_to_ftq_resp_bits_s3_pc_3), .io_bpu_to_ftq_resp_bits_s3_valid_0(i_io_bpu_to_ftq_resp_bits_s3_valid_0), .io_bpu_to_ftq_resp_bits_s3_valid_3(i_io_bpu_to_ftq_resp_bits_s3_valid_3), .io_bpu_to_ftq_resp_bits_s3_hasRedirect_3(i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3), .io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag(i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag), .io_bpu_to_ftq_resp_bits_s3_ftq_idx_value(i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value), .io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle(i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing), .io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit), .io_bpu_to_ftq_resp_bits_last_stage_meta(i_io_bpu_to_ftq_resp_bits_last_stage_meta), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0), .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0), .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_1(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_2(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_3(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_4(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_5(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_6(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_7(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_8(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_9(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9), .io_bpu_to_ftq_resp_bits_topdown_info_reasons_12(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata), .boreChildrenBd_bore_1_ack(i_boreChildrenBd_bore_1_ack), .boreChildrenBd_bore_1_outdata(i_boreChildrenBd_bore_1_outdata), .boreChildrenBd_bore_2_ack(i_boreChildrenBd_bore_2_ack), .boreChildrenBd_bore_2_outdata(i_boreChildrenBd_bore_2_outdata), .boreChildrenBd_bore_3_ack(i_boreChildrenBd_bore_3_ack), .boreChildrenBd_bore_3_outdata(i_boreChildrenBd_bore_3_outdata), .boreChildrenBd_bore_4_ack(i_boreChildrenBd_bore_4_ack), .boreChildrenBd_bore_4_outdata(i_boreChildrenBd_bore_4_outdata), .boreChildrenBd_bore_5_ack(i_boreChildrenBd_bore_5_ack), .boreChildrenBd_bore_5_outdata(i_boreChildrenBd_bore_5_outdata), .boreChildrenBd_bore_6_ack(i_boreChildrenBd_bore_6_ack), .boreChildrenBd_bore_6_outdata(i_boreChildrenBd_bore_6_outdata), .boreChildrenBd_bore_7_ack(i_boreChildrenBd_bore_7_ack), .boreChildrenBd_bore_7_outdata(i_boreChildrenBd_bore_7_outdata), .boreChildrenBd_bore_8_ack(i_boreChildrenBd_bore_8_ack), .boreChildrenBd_bore_8_outdata(i_boreChildrenBd_bore_8_outdata), .boreChildrenBd_bore_9_ack(i_boreChildrenBd_bore_9_ack), .boreChildrenBd_bore_9_outdata(i_boreChildrenBd_bore_9_outdata), .boreChildrenBd_bore_10_ack(i_boreChildrenBd_bore_10_ack), .boreChildrenBd_bore_10_outdata(i_boreChildrenBd_bore_10_outdata), .xs_dbg_s1_valid(xs_dbg_s1_valid), .xs_dbg_s2_valid(xs_dbg_s2_valid), .xs_dbg_s3_valid(xs_dbg_s3_valid), .xs_dbg_resp_valid(xs_dbg_resp_valid), .xs_dbg_s0_fire_0(xs_dbg_s0_fire_0), .xs_dbg_s0_fire_1(xs_dbg_s0_fire_1), .xs_dbg_s0_fire_2(xs_dbg_s0_fire_2), .xs_dbg_s0_fire_3(xs_dbg_s0_fire_3), .xs_dbg_s1_fire_0(xs_dbg_s1_fire_0), .xs_dbg_s1_fire_1(xs_dbg_s1_fire_1), .xs_dbg_s1_fire_2(xs_dbg_s1_fire_2), .xs_dbg_s1_fire_3(xs_dbg_s1_fire_3), .xs_dbg_topdown2_reason_1(xs_dbg_topdown2_reason_1), .xs_dbg_topdown2_reason_2(xs_dbg_topdown2_reason_2), .xs_dbg_topdown2_reason_3(xs_dbg_topdown2_reason_3), .xs_dbg_topdown2_reason_4(xs_dbg_topdown2_reason_4), .xs_dbg_topdown2_reason_5(xs_dbg_topdown2_reason_5), .xs_dbg_topdown2_reason_6(xs_dbg_topdown2_reason_6), .xs_dbg_topdown2_reason_7(xs_dbg_topdown2_reason_7), .xs_dbg_topdown2_reason_8(xs_dbg_topdown2_reason_8), .xs_dbg_topdown2_reason_9(xs_dbg_topdown2_reason_9), .xs_dbg_topdown2_reason_12(xs_dbg_topdown2_reason_12));

  always @(negedge clk) begin
    if (rst) begin
      io_ftq_to_bpu_redirect_valid <= 1'b0;
      io_ftq_to_bpu_update_valid   <= 1'b0;
      io_ftq_to_bpu_redirctFromIFU <= 1'b0;
      io_bpu_to_ftq_resp_ready     <= 1'b1;
    end else begin
      io_bpu_to_ftq_resp_ready <= ($urandom_range(0,3)!=0);
      io_ftq_to_bpu_redirect_valid <= ($urandom_range(0,7)==0);
      io_ftq_to_bpu_redirect_bits_level <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_pc <= {37'($urandom), 12'($urandom_range(0,1023)), 1'b0};
      io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp <= 4'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr <= 3'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value <= 5'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value <= 5'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value <= 5'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value <= 8'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_target <= {37'($urandom), 12'($urandom_range(0,1023)), 1'b0};
      io_ftq_to_bpu_redirect_bits_cfiUpdate_taken <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_shift <= 2'($urandom);
      io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_debugIsCtrl <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_debugIsMemVio <= 1'($urandom);
      io_ftq_to_bpu_redirect_bits_BTBMissBubble <= 1'($urandom);
      io_ftq_to_bpu_update_valid <= ($urandom_range(0,2)==0);
      io_ftq_to_bpu_update_bits_pc <= {37'($urandom), 12'($urandom_range(0,1023)), 1'b0};
      io_ftq_to_bpu_update_bits_spec_info_histPtr_value <= 8'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_isCall <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_isRet <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_isJalr <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_valid <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset <= 4'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower <= 12'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat <= 2'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset <= 4'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower <= 20'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat <= 2'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_pftAddr <= 4'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_carry <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_cfi_idx_valid <= 1'($urandom);
      io_ftq_to_bpu_update_bits_cfi_idx_bits <= 4'($urandom);
      io_ftq_to_bpu_update_bits_br_taken_mask_0 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_br_taken_mask_1 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_jmp_taken <= 1'($urandom);
      io_ftq_to_bpu_update_bits_mispred_mask_0 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_mispred_mask_1 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_mispred_mask_2 <= 1'($urandom);
      io_ftq_to_bpu_update_bits_false_hit <= 1'($urandom);
      io_ftq_to_bpu_update_bits_old_entry <= 1'($urandom);
      io_ftq_to_bpu_update_bits_meta <= 516'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
      io_ftq_to_bpu_update_bits_full_target <= {37'($urandom), 12'($urandom_range(0,1023)), 1'b0};
      io_ftq_to_bpu_enq_ptr_flag <= 1'($urandom);
      io_ftq_to_bpu_enq_ptr_value <= 6'($urandom);
      io_ftq_to_bpu_redirctFromIFU <= ($urandom_range(0,15)==0);
      io_ctrl_ubtb_enable <= 1'($urandom);
      io_ctrl_btb_enable <= 1'($urandom);
      io_ctrl_tage_enable <= 1'($urandom);
      io_ctrl_sc_enable <= 1'($urandom);
      io_ctrl_ras_enable <= 1'($urandom);
      io_reset_vector <= 48'h80000000;
      boreChildrenBd_bore_array <= 6'h0;
      boreChildrenBd_bore_all <= 1'h0;
      boreChildrenBd_bore_req <= 1'h0;
      boreChildrenBd_bore_writeen <= 1'h0;
      boreChildrenBd_bore_be <= 4'h0;
      boreChildrenBd_bore_addr <= 10'h0;
      boreChildrenBd_bore_indata <= 40'h0;
      boreChildrenBd_bore_readen <= 1'h0;
      boreChildrenBd_bore_addr_rd <= 10'h0;
      boreChildrenBd_bore_1_array <= 7'h0;
      boreChildrenBd_bore_1_all <= 1'h0;
      boreChildrenBd_bore_1_req <= 1'h0;
      boreChildrenBd_bore_1_writeen <= 1'h0;
      boreChildrenBd_bore_1_be <= 16'h0;
      boreChildrenBd_bore_1_addr <= 10'h0;
      boreChildrenBd_bore_1_indata <= 24'h0;
      boreChildrenBd_bore_1_readen <= 1'h0;
      boreChildrenBd_bore_1_addr_rd <= 10'h0;
      boreChildrenBd_bore_2_array <= 7'h0;
      boreChildrenBd_bore_2_all <= 1'h0;
      boreChildrenBd_bore_2_req <= 1'h0;
      boreChildrenBd_bore_2_writeen <= 1'h0;
      boreChildrenBd_bore_2_be <= 4'h0;
      boreChildrenBd_bore_2_addr <= 9'h0;
      boreChildrenBd_bore_2_indata <= 24'h0;
      boreChildrenBd_bore_2_readen <= 1'h0;
      boreChildrenBd_bore_2_addr_rd <= 9'h0;
      boreChildrenBd_bore_3_array <= 7'h0;
      boreChildrenBd_bore_3_all <= 1'h0;
      boreChildrenBd_bore_3_req <= 1'h0;
      boreChildrenBd_bore_3_writeen <= 1'h0;
      boreChildrenBd_bore_3_be <= 4'h0;
      boreChildrenBd_bore_3_addr <= 9'h0;
      boreChildrenBd_bore_3_indata <= 24'h0;
      boreChildrenBd_bore_3_readen <= 1'h0;
      boreChildrenBd_bore_3_addr_rd <= 9'h0;
      boreChildrenBd_bore_4_array <= 7'h0;
      boreChildrenBd_bore_4_all <= 1'h0;
      boreChildrenBd_bore_4_req <= 1'h0;
      boreChildrenBd_bore_4_writeen <= 1'h0;
      boreChildrenBd_bore_4_be <= 4'h0;
      boreChildrenBd_bore_4_addr <= 9'h0;
      boreChildrenBd_bore_4_indata <= 24'h0;
      boreChildrenBd_bore_4_readen <= 1'h0;
      boreChildrenBd_bore_4_addr_rd <= 9'h0;
      boreChildrenBd_bore_5_array <= 7'h0;
      boreChildrenBd_bore_5_all <= 1'h0;
      boreChildrenBd_bore_5_req <= 1'h0;
      boreChildrenBd_bore_5_writeen <= 1'h0;
      boreChildrenBd_bore_5_be <= 4'h0;
      boreChildrenBd_bore_5_addr <= 9'h0;
      boreChildrenBd_bore_5_indata <= 24'h0;
      boreChildrenBd_bore_5_readen <= 1'h0;
      boreChildrenBd_bore_5_addr_rd <= 9'h0;
      boreChildrenBd_bore_6_array <= 7'h0;
      boreChildrenBd_bore_6_all <= 1'h0;
      boreChildrenBd_bore_6_req <= 1'h0;
      boreChildrenBd_bore_6_writeen <= 1'h0;
      boreChildrenBd_bore_6_be <= 76'h0;
      boreChildrenBd_bore_6_addr <= 8'h0;
      boreChildrenBd_bore_6_indata <= 76'h0;
      boreChildrenBd_bore_6_readen <= 1'h0;
      boreChildrenBd_bore_6_addr_rd <= 8'h0;
      boreChildrenBd_bore_7_array <= 7'h0;
      boreChildrenBd_bore_7_all <= 1'h0;
      boreChildrenBd_bore_7_req <= 1'h0;
      boreChildrenBd_bore_7_writeen <= 1'h0;
      boreChildrenBd_bore_7_be <= 76'h0;
      boreChildrenBd_bore_7_addr <= 8'h0;
      boreChildrenBd_bore_7_indata <= 76'h0;
      boreChildrenBd_bore_7_readen <= 1'h0;
      boreChildrenBd_bore_7_addr_rd <= 8'h0;
      boreChildrenBd_bore_8_array <= 7'h0;
      boreChildrenBd_bore_8_all <= 1'h0;
      boreChildrenBd_bore_8_req <= 1'h0;
      boreChildrenBd_bore_8_writeen <= 1'h0;
      boreChildrenBd_bore_8_be <= 76'h0;
      boreChildrenBd_bore_8_addr <= 8'h0;
      boreChildrenBd_bore_8_indata <= 76'h0;
      boreChildrenBd_bore_8_readen <= 1'h0;
      boreChildrenBd_bore_8_addr_rd <= 8'h0;
      boreChildrenBd_bore_9_array <= 7'h0;
      boreChildrenBd_bore_9_all <= 1'h0;
      boreChildrenBd_bore_9_req <= 1'h0;
      boreChildrenBd_bore_9_writeen <= 1'h0;
      boreChildrenBd_bore_9_be <= 76'h0;
      boreChildrenBd_bore_9_addr <= 8'h0;
      boreChildrenBd_bore_9_indata <= 76'h0;
      boreChildrenBd_bore_9_readen <= 1'h0;
      boreChildrenBd_bore_9_addr_rd <= 8'h0;
      boreChildrenBd_bore_10_array <= 7'h0;
      boreChildrenBd_bore_10_all <= 1'h0;
      boreChildrenBd_bore_10_req <= 1'h0;
      boreChildrenBd_bore_10_writeen <= 1'h0;
      boreChildrenBd_bore_10_be <= 76'h0;
      boreChildrenBd_bore_10_addr <= 8'h0;
      boreChildrenBd_bore_10_indata <= 76'h0;
      boreChildrenBd_bore_10_readen <= 1'h0;
      boreChildrenBd_bore_10_addr_rd <= 8'h0;
      sigFromSrams_bore_ram_hold <= 1'h0;
      sigFromSrams_bore_ram_bypass <= 1'h0;
      sigFromSrams_bore_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_cgen <= 1'h0;
      sigFromSrams_bore_1_ram_hold <= 1'h0;
      sigFromSrams_bore_1_ram_bypass <= 1'h0;
      sigFromSrams_bore_1_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_1_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_1_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_1_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_1_cgen <= 1'h0;
      sigFromSrams_bore_2_ram_hold <= 1'h0;
      sigFromSrams_bore_2_ram_bypass <= 1'h0;
      sigFromSrams_bore_2_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_2_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_2_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_2_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_2_cgen <= 1'h0;
      sigFromSrams_bore_3_ram_hold <= 1'h0;
      sigFromSrams_bore_3_ram_bypass <= 1'h0;
      sigFromSrams_bore_3_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_3_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_3_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_3_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_3_cgen <= 1'h0;
      sigFromSrams_bore_4_ram_hold <= 1'h0;
      sigFromSrams_bore_4_ram_bypass <= 1'h0;
      sigFromSrams_bore_4_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_4_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_4_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_4_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_4_cgen <= 1'h0;
      sigFromSrams_bore_5_ram_hold <= 1'h0;
      sigFromSrams_bore_5_ram_bypass <= 1'h0;
      sigFromSrams_bore_5_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_5_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_5_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_5_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_5_cgen <= 1'h0;
      sigFromSrams_bore_6_ram_hold <= 1'h0;
      sigFromSrams_bore_6_ram_bypass <= 1'h0;
      sigFromSrams_bore_6_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_6_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_6_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_6_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_6_cgen <= 1'h0;
      sigFromSrams_bore_7_ram_hold <= 1'h0;
      sigFromSrams_bore_7_ram_bypass <= 1'h0;
      sigFromSrams_bore_7_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_7_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_7_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_7_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_7_cgen <= 1'h0;
      sigFromSrams_bore_8_ram_hold <= 1'h0;
      sigFromSrams_bore_8_ram_bypass <= 1'h0;
      sigFromSrams_bore_8_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_8_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_8_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_8_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_8_cgen <= 1'h0;
      sigFromSrams_bore_9_ram_hold <= 1'h0;
      sigFromSrams_bore_9_ram_bypass <= 1'h0;
      sigFromSrams_bore_9_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_9_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_9_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_9_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_9_cgen <= 1'h0;
      sigFromSrams_bore_10_ram_hold <= 1'h0;
      sigFromSrams_bore_10_ram_bypass <= 1'h0;
      sigFromSrams_bore_10_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_10_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_10_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_10_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_10_cgen <= 1'h0;
      sigFromSrams_bore_11_ram_hold <= 1'h0;
      sigFromSrams_bore_11_ram_bypass <= 1'h0;
      sigFromSrams_bore_11_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_11_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_11_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_11_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_11_cgen <= 1'h0;
      sigFromSrams_bore_12_ram_hold <= 1'h0;
      sigFromSrams_bore_12_ram_bypass <= 1'h0;
      sigFromSrams_bore_12_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_12_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_12_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_12_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_12_cgen <= 1'h0;
      sigFromSrams_bore_13_ram_hold <= 1'h0;
      sigFromSrams_bore_13_ram_bypass <= 1'h0;
      sigFromSrams_bore_13_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_13_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_13_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_13_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_13_cgen <= 1'h0;
      sigFromSrams_bore_14_ram_hold <= 1'h0;
      sigFromSrams_bore_14_ram_bypass <= 1'h0;
      sigFromSrams_bore_14_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_14_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_14_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_14_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_14_cgen <= 1'h0;
      sigFromSrams_bore_15_ram_hold <= 1'h0;
      sigFromSrams_bore_15_ram_bypass <= 1'h0;
      sigFromSrams_bore_15_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_15_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_15_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_15_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_15_cgen <= 1'h0;
      sigFromSrams_bore_16_ram_hold <= 1'h0;
      sigFromSrams_bore_16_ram_bypass <= 1'h0;
      sigFromSrams_bore_16_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_16_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_16_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_16_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_16_cgen <= 1'h0;
      sigFromSrams_bore_17_ram_hold <= 1'h0;
      sigFromSrams_bore_17_ram_bypass <= 1'h0;
      sigFromSrams_bore_17_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_17_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_17_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_17_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_17_cgen <= 1'h0;
      sigFromSrams_bore_18_ram_hold <= 1'h0;
      sigFromSrams_bore_18_ram_bypass <= 1'h0;
      sigFromSrams_bore_18_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_18_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_18_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_18_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_18_cgen <= 1'h0;
      sigFromSrams_bore_19_ram_hold <= 1'h0;
      sigFromSrams_bore_19_ram_bypass <= 1'h0;
      sigFromSrams_bore_19_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_19_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_19_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_19_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_19_cgen <= 1'h0;
      sigFromSrams_bore_20_ram_hold <= 1'h0;
      sigFromSrams_bore_20_ram_bypass <= 1'h0;
      sigFromSrams_bore_20_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_20_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_20_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_20_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_20_cgen <= 1'h0;
      sigFromSrams_bore_21_ram_hold <= 1'h0;
      sigFromSrams_bore_21_ram_bypass <= 1'h0;
      sigFromSrams_bore_21_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_21_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_21_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_21_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_21_cgen <= 1'h0;
      sigFromSrams_bore_22_ram_hold <= 1'h0;
      sigFromSrams_bore_22_ram_bypass <= 1'h0;
      sigFromSrams_bore_22_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_22_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_22_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_22_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_22_cgen <= 1'h0;
      sigFromSrams_bore_23_ram_hold <= 1'h0;
      sigFromSrams_bore_23_ram_bypass <= 1'h0;
      sigFromSrams_bore_23_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_23_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_23_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_23_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_23_cgen <= 1'h0;
      sigFromSrams_bore_24_ram_hold <= 1'h0;
      sigFromSrams_bore_24_ram_bypass <= 1'h0;
      sigFromSrams_bore_24_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_24_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_24_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_24_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_24_cgen <= 1'h0;
      sigFromSrams_bore_25_ram_hold <= 1'h0;
      sigFromSrams_bore_25_ram_bypass <= 1'h0;
      sigFromSrams_bore_25_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_25_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_25_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_25_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_25_cgen <= 1'h0;
      sigFromSrams_bore_26_ram_hold <= 1'h0;
      sigFromSrams_bore_26_ram_bypass <= 1'h0;
      sigFromSrams_bore_26_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_26_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_26_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_26_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_26_cgen <= 1'h0;
      sigFromSrams_bore_27_ram_hold <= 1'h0;
      sigFromSrams_bore_27_ram_bypass <= 1'h0;
      sigFromSrams_bore_27_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_27_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_27_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_27_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_27_cgen <= 1'h0;
      sigFromSrams_bore_28_ram_hold <= 1'h0;
      sigFromSrams_bore_28_ram_bypass <= 1'h0;
      sigFromSrams_bore_28_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_28_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_28_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_28_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_28_cgen <= 1'h0;
      sigFromSrams_bore_29_ram_hold <= 1'h0;
      sigFromSrams_bore_29_ram_bypass <= 1'h0;
      sigFromSrams_bore_29_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_29_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_29_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_29_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_29_cgen <= 1'h0;
      sigFromSrams_bore_30_ram_hold <= 1'h0;
      sigFromSrams_bore_30_ram_bypass <= 1'h0;
      sigFromSrams_bore_30_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_30_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_30_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_30_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_30_cgen <= 1'h0;
      sigFromSrams_bore_31_ram_hold <= 1'h0;
      sigFromSrams_bore_31_ram_bypass <= 1'h0;
      sigFromSrams_bore_31_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_31_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_31_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_31_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_31_cgen <= 1'h0;
      sigFromSrams_bore_32_ram_hold <= 1'h0;
      sigFromSrams_bore_32_ram_bypass <= 1'h0;
      sigFromSrams_bore_32_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_32_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_32_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_32_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_32_cgen <= 1'h0;
      sigFromSrams_bore_33_ram_hold <= 1'h0;
      sigFromSrams_bore_33_ram_bypass <= 1'h0;
      sigFromSrams_bore_33_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_33_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_33_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_33_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_33_cgen <= 1'h0;
      sigFromSrams_bore_34_ram_hold <= 1'h0;
      sigFromSrams_bore_34_ram_bypass <= 1'h0;
      sigFromSrams_bore_34_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_34_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_34_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_34_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_34_cgen <= 1'h0;
      sigFromSrams_bore_35_ram_hold <= 1'h0;
      sigFromSrams_bore_35_ram_bypass <= 1'h0;
      sigFromSrams_bore_35_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_35_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_35_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_35_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_35_cgen <= 1'h0;
      sigFromSrams_bore_36_ram_hold <= 1'h0;
      sigFromSrams_bore_36_ram_bypass <= 1'h0;
      sigFromSrams_bore_36_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_36_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_36_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_36_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_36_cgen <= 1'h0;
      sigFromSrams_bore_37_ram_hold <= 1'h0;
      sigFromSrams_bore_37_ram_bypass <= 1'h0;
      sigFromSrams_bore_37_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_37_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_37_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_37_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_37_cgen <= 1'h0;
      sigFromSrams_bore_38_ram_hold <= 1'h0;
      sigFromSrams_bore_38_ram_bypass <= 1'h0;
      sigFromSrams_bore_38_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_38_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_38_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_38_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_38_cgen <= 1'h0;
      sigFromSrams_bore_39_ram_hold <= 1'h0;
      sigFromSrams_bore_39_ram_bypass <= 1'h0;
      sigFromSrams_bore_39_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_39_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_39_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_39_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_39_cgen <= 1'h0;
      sigFromSrams_bore_40_ram_hold <= 1'h0;
      sigFromSrams_bore_40_ram_bypass <= 1'h0;
      sigFromSrams_bore_40_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_40_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_40_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_40_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_40_cgen <= 1'h0;
      sigFromSrams_bore_41_ram_hold <= 1'h0;
      sigFromSrams_bore_41_ram_bypass <= 1'h0;
      sigFromSrams_bore_41_ram_bp_clken <= 1'h0;
      sigFromSrams_bore_41_ram_aux_clk <= 1'h0;
      sigFromSrams_bore_41_ram_aux_ckbp <= 1'h0;
      sigFromSrams_bore_41_ram_mcp_hold <= 1'h0;
      sigFromSrams_bore_41_cgen <= 1'h0;
    end
  end

  // ---- 主比对：跳过 golden 为 X 的位（黑盒内层 SRAM 在 +SYNTHESIS 下初值 X）----
  always @(negedge clk) if (!rst) begin
    cyc++; #4;
    if (cyc > WARMUP) begin
      checks++;
      if (!$isunknown(g_io_bpu_to_ftq_resp_valid) && g_io_bpu_to_ftq_resp_valid !== i_io_bpu_to_ftq_resp_valid) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_valid, i_io_bpu_to_ftq_resp_valid); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_pc_3) && g_io_bpu_to_ftq_resp_bits_s1_pc_3 !== i_io_bpu_to_ftq_resp_bits_s1_pc_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_pc_3, i_io_bpu_to_ftq_resp_bits_s1_pc_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit) && g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_pc_3) && g_io_bpu_to_ftq_resp_bits_s2_pc_3 !== i_io_bpu_to_ftq_resp_bits_s2_pc_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_pc_3, i_io_bpu_to_ftq_resp_bits_s2_pc_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_valid_3) && g_io_bpu_to_ftq_resp_bits_s2_valid_3 !== i_io_bpu_to_ftq_resp_bits_s2_valid_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_valid_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_valid_3, i_io_bpu_to_ftq_resp_bits_s2_valid_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3) && g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 !== i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3, i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag) && g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag !== i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag, i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value) && g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value !== i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_ftq_idx_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value, i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit) && g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_0) && g_io_bpu_to_ftq_resp_bits_s3_pc_0 !== i_io_bpu_to_ftq_resp_bits_s3_pc_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_pc_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_pc_0, i_io_bpu_to_ftq_resp_bits_s3_pc_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_3) && g_io_bpu_to_ftq_resp_bits_s3_pc_3 !== i_io_bpu_to_ftq_resp_bits_s3_pc_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_pc_3, i_io_bpu_to_ftq_resp_bits_s3_pc_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_valid_0) && g_io_bpu_to_ftq_resp_bits_s3_valid_0 !== i_io_bpu_to_ftq_resp_bits_s3_valid_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_valid_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_valid_0, i_io_bpu_to_ftq_resp_bits_s3_valid_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_valid_3) && g_io_bpu_to_ftq_resp_bits_s3_valid_3 !== i_io_bpu_to_ftq_resp_bits_s3_valid_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_valid_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_valid_3, i_io_bpu_to_ftq_resp_bits_s3_valid_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3) && g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 !== i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3, i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag) && g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag !== i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag, i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value) && g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value !== i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_ftq_idx_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value, i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit) && g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_meta) && g_io_bpu_to_ftq_resp_bits_last_stage_meta !== i_io_bpu_to_ftq_resp_bits_last_stage_meta) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_meta g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_meta, i_io_bpu_to_ftq_resp_bits_last_stage_meta); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0 !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1) && g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1 !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0 !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1) && g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_2 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_4 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_5 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_6 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_7 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_8 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_9 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9); end
      if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12) && g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12) begin errors++;
        if (errors<=40) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12); end
      if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
      if (!$isunknown(g_io_perf_1_value) && g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
      if (!$isunknown(g_io_perf_2_value) && g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
      if (!$isunknown(g_io_perf_3_value) && g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
      if (!$isunknown(g_io_perf_4_value) && g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
      if (!$isunknown(g_io_perf_5_value) && g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end
      if (!$isunknown(g_io_perf_6_value) && g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
        if (errors<=40) $display("[%0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end
      if (!$isunknown(g_boreChildrenBd_bore_ack) && g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_ack g=%h i=%h", $time, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_outdata) && g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_1_ack) && g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_1_ack g=%h i=%h", $time, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_1_outdata) && g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_1_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_2_ack) && g_boreChildrenBd_bore_2_ack !== i_boreChildrenBd_bore_2_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_2_ack g=%h i=%h", $time, g_boreChildrenBd_bore_2_ack, i_boreChildrenBd_bore_2_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_2_outdata) && g_boreChildrenBd_bore_2_outdata !== i_boreChildrenBd_bore_2_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_2_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_2_outdata, i_boreChildrenBd_bore_2_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_3_ack) && g_boreChildrenBd_bore_3_ack !== i_boreChildrenBd_bore_3_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_3_ack g=%h i=%h", $time, g_boreChildrenBd_bore_3_ack, i_boreChildrenBd_bore_3_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_3_outdata) && g_boreChildrenBd_bore_3_outdata !== i_boreChildrenBd_bore_3_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_3_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_3_outdata, i_boreChildrenBd_bore_3_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_4_ack) && g_boreChildrenBd_bore_4_ack !== i_boreChildrenBd_bore_4_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_4_ack g=%h i=%h", $time, g_boreChildrenBd_bore_4_ack, i_boreChildrenBd_bore_4_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_4_outdata) && g_boreChildrenBd_bore_4_outdata !== i_boreChildrenBd_bore_4_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_4_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_4_outdata, i_boreChildrenBd_bore_4_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_5_ack) && g_boreChildrenBd_bore_5_ack !== i_boreChildrenBd_bore_5_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_5_ack g=%h i=%h", $time, g_boreChildrenBd_bore_5_ack, i_boreChildrenBd_bore_5_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_5_outdata) && g_boreChildrenBd_bore_5_outdata !== i_boreChildrenBd_bore_5_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_5_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_5_outdata, i_boreChildrenBd_bore_5_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_6_ack) && g_boreChildrenBd_bore_6_ack !== i_boreChildrenBd_bore_6_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_6_ack g=%h i=%h", $time, g_boreChildrenBd_bore_6_ack, i_boreChildrenBd_bore_6_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_6_outdata) && g_boreChildrenBd_bore_6_outdata !== i_boreChildrenBd_bore_6_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_6_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_6_outdata, i_boreChildrenBd_bore_6_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_7_ack) && g_boreChildrenBd_bore_7_ack !== i_boreChildrenBd_bore_7_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_7_ack g=%h i=%h", $time, g_boreChildrenBd_bore_7_ack, i_boreChildrenBd_bore_7_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_7_outdata) && g_boreChildrenBd_bore_7_outdata !== i_boreChildrenBd_bore_7_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_7_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_7_outdata, i_boreChildrenBd_bore_7_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_8_ack) && g_boreChildrenBd_bore_8_ack !== i_boreChildrenBd_bore_8_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_8_ack g=%h i=%h", $time, g_boreChildrenBd_bore_8_ack, i_boreChildrenBd_bore_8_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_8_outdata) && g_boreChildrenBd_bore_8_outdata !== i_boreChildrenBd_bore_8_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_8_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_8_outdata, i_boreChildrenBd_bore_8_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_9_ack) && g_boreChildrenBd_bore_9_ack !== i_boreChildrenBd_bore_9_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_9_ack g=%h i=%h", $time, g_boreChildrenBd_bore_9_ack, i_boreChildrenBd_bore_9_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_9_outdata) && g_boreChildrenBd_bore_9_outdata !== i_boreChildrenBd_bore_9_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_9_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_9_outdata, i_boreChildrenBd_bore_9_outdata); end
      if (!$isunknown(g_boreChildrenBd_bore_10_ack) && g_boreChildrenBd_bore_10_ack !== i_boreChildrenBd_bore_10_ack) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_10_ack g=%h i=%h", $time, g_boreChildrenBd_bore_10_ack, i_boreChildrenBd_bore_10_ack); end
      if (!$isunknown(g_boreChildrenBd_bore_10_outdata) && g_boreChildrenBd_bore_10_outdata !== i_boreChildrenBd_bore_10_outdata) begin errors++;
        if (errors<=40) $display("[%0t] boreChildrenBd_bore_10_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_10_outdata, i_boreChildrenBd_bore_10_outdata); end
    end
  end

  // ---- 可读核探针比对：golden 内部寄存器 vs 可读核影子输出 ----
  always @(negedge clk) if (!rst) begin
    #4;
    if (cyc > WARMUP) begin
      core_checks++;
      if (!$isunknown(u_g.s1_valid_dup_3) && u_g.s1_valid_dup_3 !== xs_dbg_s1_valid) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE s1_valid g=%b core=%b", $time, u_g.s1_valid_dup_3, xs_dbg_s1_valid); end
      core_checks++;
      if (!$isunknown(u_g.s2_valid_dup_3) && u_g.s2_valid_dup_3 !== xs_dbg_s2_valid) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE s2_valid g=%b core=%b", $time, u_g.s2_valid_dup_3, xs_dbg_s2_valid); end
      core_checks++;
      if (!$isunknown(u_g.s3_valid_dup_3) && u_g.s3_valid_dup_3 !== xs_dbg_s3_valid) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE s3_valid g=%b core=%b", $time, u_g.s3_valid_dup_3, xs_dbg_s3_valid); end
      core_checks++;
      if (!$isunknown(u_g.io_bpu_to_ftq_resp_valid_0) && u_g.io_bpu_to_ftq_resp_valid_0 !== xs_dbg_resp_valid) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE resp_valid g=%b core=%b", $time, u_g.io_bpu_to_ftq_resp_valid_0, xs_dbg_resp_valid); end
      core_checks++;
      if (!$isunknown(u_g.s0_fire_dup_0) && u_g.s0_fire_dup_0 !== xs_dbg_s0_fire_0) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE s0_fire_0 g=%b core=%b", $time, u_g.s0_fire_dup_0, xs_dbg_s0_fire_0); end
      core_checks++;
      if (!$isunknown(u_g.s0_fire_dup_3) && u_g.s0_fire_dup_3 !== xs_dbg_s0_fire_3) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE s0_fire_3 g=%b core=%b", $time, u_g.s0_fire_dup_3, xs_dbg_s0_fire_3); end
      core_checks++;
      if (!$isunknown(u_g.s1_fire_dup_0) && u_g.s1_fire_dup_0 !== xs_dbg_s1_fire_0) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE s1_fire_0 g=%b core=%b", $time, u_g.s1_fire_dup_0, xs_dbg_s1_fire_0); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_1) && u_g.topdown_stages_2_reasons_1 !== xs_dbg_topdown2_reason_1) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_1 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_1, xs_dbg_topdown2_reason_1); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_2) && u_g.topdown_stages_2_reasons_2 !== xs_dbg_topdown2_reason_2) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_2 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_2, xs_dbg_topdown2_reason_2); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_3) && u_g.topdown_stages_2_reasons_3 !== xs_dbg_topdown2_reason_3) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_3 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_3, xs_dbg_topdown2_reason_3); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_4) && u_g.topdown_stages_2_reasons_4 !== xs_dbg_topdown2_reason_4) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_4 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_4, xs_dbg_topdown2_reason_4); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_5) && u_g.topdown_stages_2_reasons_5 !== xs_dbg_topdown2_reason_5) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_5 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_5, xs_dbg_topdown2_reason_5); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_6) && u_g.topdown_stages_2_reasons_6 !== xs_dbg_topdown2_reason_6) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_6 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_6, xs_dbg_topdown2_reason_6); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_7) && u_g.topdown_stages_2_reasons_7 !== xs_dbg_topdown2_reason_7) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_7 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_7, xs_dbg_topdown2_reason_7); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_8) && u_g.topdown_stages_2_reasons_8 !== xs_dbg_topdown2_reason_8) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_8 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_8, xs_dbg_topdown2_reason_8); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_9) && u_g.topdown_stages_2_reasons_9 !== xs_dbg_topdown2_reason_9) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_9 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_9, xs_dbg_topdown2_reason_9); end
      core_checks++;
      if (!$isunknown(u_g.topdown_stages_2_reasons_12) && u_g.topdown_stages_2_reasons_12 !== xs_dbg_topdown2_reason_12) begin core_errors++;
        if (core_errors<=40) $display("[%0t] CORE topdown2_reason_12 g=%b core=%b", $time, u_g.topdown_stages_2_reasons_12, xs_dbg_topdown2_reason_12); end
    end
  end

  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d core_checks=%0d core_errors=%0d", checks, errors, core_checks, core_errors);
    if (errors == 0 && core_errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
