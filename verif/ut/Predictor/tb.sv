// tb.sv —— Predictor UT：golden `Predictor` 与重写 `Predictor_xs` 双例化，
//          同激励逐拍比全部 125 个输出。本文件由 gen_tb.py 生成，别手改。
//
// 两侧共用同一份 golden Composer（及其 5 个预测器闭包）——本 UT 只验 Predictor
// 这一层的流水控制与全局历史管理，预测器本身另有各自的签核。因此：**只要两侧
// Predictor 逻辑一致，两份 Composer 吃到的输入就逐位一致，输出也必然一致**，
// 任何失配都落在本模块自己身上。
//
// 激励设计与实测依据见 gen_tb.py 头注释（影子 FTQ 回灌 / 取指区间收敛 /
// 固定复位向量；以及被实测否掉的 MBIST 分相假设）。★覆盖闸：golden 侧任何一个覆盖点为 0 即判 TEST FAILED —— 
// 覆盖点全 0 的 UT 报 errors=0 是没有意义的。★
`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// SRAM 行为模型零初始化（理由见 gen_tb.py 头注释「为什么这是加强而不是放宽」）
// ---------------------------------------------------------------------------
// +no_sram_zero 关掉本初始化 —— 只用来复现「不清零时那一档 X 悲观失配数」这条
// 对照证据（见 gen_tb.py 头注释里的 A/B 表），正常跑不要加。
module xs_ram_zero_dn #(parameter int DEPTH = 1, parameter int W = 1)
                      (ref reg [W-1:0] ram [DEPTH-1:0]);
  initial if (!$test$plusargs("no_sram_zero"))
    for (int i = 0; i < DEPTH; i++) ram[i] = '0;
endmodule

module xs_ram_zero_up #(parameter int DEPTH = 1, parameter int W = 1)
                      (ref reg [W-1:0] Memory [0:DEPTH-1]);
  initial if (!$test$plusargs("no_sram_zero"))
    for (int i = 0; i < DEPTH; i++) Memory[i] = '0;
endmodule

bind array_1_ext xs_ram_zero_dn #(.DEPTH(512), .W(40)) u_xs_zero (.ram(ram));
bind array_2_ext xs_ram_zero_dn #(.DEPTH(256), .W(16)) u_xs_zero (.ram(ram));
bind array_3_ext xs_ram_zero_dn #(.DEPTH(512), .W(24)) u_xs_zero (.ram(ram));
bind array_4_ext xs_ram_zero_dn #(.DEPTH(256), .W(8)) u_xs_zero (.ram(ram));
bind array_5_ext xs_ram_zero_dn #(.DEPTH(128), .W(24)) u_xs_zero (.ram(ram));
bind array_6_ext xs_ram_zero_dn #(.DEPTH(128), .W(76)) u_xs_zero (.ram(ram));
bind data_mem_0_4x2 xs_ram_zero_up #(.DEPTH(4), .W(2)) u_xs_zero (.Memory(Memory));
bind data_mem_0_8x3 xs_ram_zero_up #(.DEPTH(8), .W(3)) u_xs_zero (.Memory(Memory));
bind data_mem_16x12 xs_ram_zero_up #(.DEPTH(16), .W(12)) u_xs_zero (.Memory(Memory));
bind data_mem_8x4 xs_ram_zero_up #(.DEPTH(8), .W(4)) u_xs_zero (.Memory(Memory));

module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  longint errors = 0, checks = 0;
  // 失配分两类只为**定位**，判据仍然是 errors 总数：
  //   errors_x   = golden 已定值而 impl 是 X（X 悲观差异）
  //   errors_val = 两侧都是定值但不相等（真逻辑差异）
  longint errors_x = 0, errors_val = 0;
  longint cyc = 0;
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

  // =========================================================================
  // 取指区间：把取指流收敛到 NBLK 个 32 字节块上
  //
  // FTB 的索引/标签只看 pc[29:1]（FTBBank.sv:1962-1963），所以「训练过的 pc」
  // 和「以后会查的 pc」必须逐位相同才可能命中。取指流由 BPU 自环产生，唯一能从
  // 外部把它钉住的两个把手是 ① 复位向量 ② redirect 的 cfiUpdate_target。
  // 二者都钉在 REGION_BASE + j*32 (j<NBLK) 上；合成 FTB 表项的跳转目标也指回
  // 这些块（见 syn_lower），于是稳态下取指流就在这 NBLK 个块里绕。
  //
  // REGION_BASE 取 8 KiB 对齐：FTB 表项里 brSlot 只存 target[12:1]（12 位），
  // tarStat=0(TAR_FIT) 表示高位照抄 pc —— 8 KiB 对齐保证目标不会跨出本页。
  // =========================================================================
  localparam logic [49:0] REGION_BASE = 50'h00_8000_0000;  // 2 GiB，8 KiB 对齐
  localparam int          NBLK        = 16;                 // 训练用取指块数
  localparam int          BLK_BYTES   = 32;                 // 一个取指块 = 16 条 × 2 B

  function automatic logic [49:0] blk_pc(input int j);
    return REGION_BASE + 50'(j % NBLK) * BLK_BYTES;
  endfunction
  // 取指块序号：REGION_BASE 是 8 KiB 对齐，块大小 32 B ⇒ 序号就在 pc[8:5]。
  function automatic int blk_of(input logic [49:0] pc);
    return int'(pc[8:5]);
  endfunction
  // 合成表项的跳转目标块：7 与 16 互质 ⇒ j→(7j+3) 是 16 个块上的一个完整轮换，
  // 取指流因此会走遍全部 NBLK 个块，而不是卡在两三个块上。
  function automatic int tgt_blk(input int j);
    return (j * 7 + 3) % NBLK;
  endfunction

  // =========================================================================
  // 影子 FTQ —— 把 BPU 自己吐出的末级预测包过若干拍当 update 喂回去
  //
  // 真 Ftq 就是这么做的：s3 那拍把 (pc, meta, ftb_entry, spec_info) 存进队列，
  // 等后端把这条取指块执行完再带着「实际怎么跳的」回灌 BPU。本 tb 只保留其中
  // 与 BPU 训练有关的部分，「实际怎么跳的」用一个**按 pc 可复现**的模式生成
  // （bpat/phs），这样 TAGE 才学得会、SC 才可能与之分歧 —— 那正是 S3 覆盖的来源。
  // =========================================================================
  localparam int FQD = 32;   // 队列深度（真 FtqSize=64，这里只要够产生时延）
  localparam int FQ_LAG = 8; // 至少积压这么多条才开始回灌，制造真实的 update 时延

  typedef struct packed {
    logic        isCall, isRet, isJalr, ent_valid;
    logic [3:0]  br0_off;   logic br0_sharing, br0_valid;
    logic [11:0] br0_lower; logic [1:0] br0_tarStat;
    logic [3:0]  tl_off;    logic tl_sharing, tl_valid;
    logic [19:0] tl_lower;  logic [1:0] tl_tarStat;
    logic [3:0]  pftAddr;   logic carry, rvi_call, sb0, sb1;
  } ftbe_t;

  logic [49:0]  fq_pc   [0:FQD-1];
  logic [515:0] fq_meta [0:FQD-1];
  ftbe_t        fq_ent  [0:FQD-1];
  logic [7:0]   fq_hp   [0:FQD-1];
  logic         fq_hpf  [0:FQD-1];
  int           fq_wr = 0, fq_rd = 0, fq_cnt = 0;

  // 每块一个 8 位方向模式 + 一个 3 位相位 ⇒ 每个 pc 上是周期 8 的可学模式。
  // 随机种子决定模式内容，所以三个 seed 走的是三套不同的分支行为。
  logic [7:0] bpat [0:NBLK-1];
  logic [2:0] phs  [0:NBLK-1];

  // 末级历史指针的影子：重定向要带「当时的历史指针」，跟着 BPU 自己吐的走才有意义。
  logic [7:0] hp_shadow;
  logic       hpf_shadow;

  // 五个预测器是否全开 —— 用来把「靠关预测器凑出来的覆盖」和真覆盖分开统计。
  wire all_pred_en = io_ctrl_ubtb_enable & io_ctrl_btb_enable & io_ctrl_tage_enable
                   & io_ctrl_sc_enable  & io_ctrl_ras_enable;

  // ---- 采样：s3 有效那拍把整包压进影子 FTQ ----
  always @(posedge clk) begin
    if (rst) begin
      fq_wr = 0; fq_rd = 0; fq_cnt = 0;
      hp_shadow = 8'h0; hpf_shadow = 1'b0;
    end else begin
      if (g_io_bpu_to_ftq_resp_bits_s3_valid_0 === 1'b1
          && !$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_0)) begin
        hp_shadow  = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
        hpf_shadow = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
        if (fq_cnt < FQD) begin
          fq_pc  [fq_wr] = g_io_bpu_to_ftq_resp_bits_s3_pc_0;
          fq_meta[fq_wr] = g_io_bpu_to_ftq_resp_bits_last_stage_meta;
          fq_hp  [fq_wr] = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
          fq_hpf [fq_wr] = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
          fq_ent [fq_wr] = '{
            isCall     : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall,
            isRet      : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet,
            isJalr     : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr,
            ent_valid  : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid,
            br0_off    : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset,
            br0_sharing: g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing,
            br0_valid  : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid,
            br0_lower  : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower,
            br0_tarStat: g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat,
            tl_off     : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset,
            tl_sharing : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing,
            tl_valid   : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid,
            tl_lower   : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower,
            tl_tarStat : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat,
            pftAddr    : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr,
            carry      : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry,
            rvi_call   : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call,
            sb0        : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0,
            sb1        : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 };
          fq_wr  = (fq_wr + 1) % FQD;
          fq_cnt = fq_cnt + 1;
        end
      end
    end
  end

  // ---- MBIST/DFT 线：每拍随机（与第一版相同，理由见 gen_tb.py 头注释的 A/B）----
  task automatic drive_mbist();
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

  // ---- update 通道：从影子 FTQ 回灌一条 ----
  //
  // 表项内容是 pc 的**确定函数**（syn_* 系列），所以同一个 pc 反复被 update 时
  // 写进 FTB 的是同一条 —— 表项能稳下来，命中才能稳定发生。
  task automatic drive_update();
    int j, t;
    logic [49:0] upc, utgt;
    logic [3:0]  br_off, tl_off;
    logic        shr, brtk0, brtk1, jtk;
    ftbe_t       cap;
    if (fq_cnt > FQ_LAG) begin
      upc  = fq_pc[fq_rd];
      cap  = fq_ent[fq_rd];
      j    = blk_of(upc);
      t    = tgt_blk(j);
      utgt = blk_pc(t);
      // 合成表项：第一条槽放条件分支，尾槽按 j%4 轮流放
      //   0 → 第二条条件分支(sharing) 1 → jalr(练 ITTAGE)
      //   2 → ret (练 RAS 弹栈)      3 → call(练 RAS 压栈)
      shr    = (j % 4 == 0);
      br_off = 4'(j % 12);
      tl_off = 4'(12 + (j % 4));
      brtk0  = bpat[j][phs[j]];
      brtk1  = shr & bpat[j][(phs[j] + 3) % 8];
      jtk    = ~shr & chance(70);
      phs[j] = phs[j] + 3'd1;

      io_ftq_to_bpu_update_valid                          = 1'b1;
      io_ftq_to_bpu_update_bits_pc                        = upc;
      io_ftq_to_bpu_update_bits_meta                      = fq_meta[fq_rd];
      io_ftq_to_bpu_update_bits_spec_info_histPtr_value   = fq_hp[fq_rd];
      io_ftq_to_bpu_update_bits_ftb_entry_valid           = 1'b1;
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid  = 1'b1;
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset = br_off;
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing= 1'b0;
      // brSlot 只存 target[12:1]；目标块 t 的地址是 REGION_BASE + t*32 ⇒ 低位 = t*16
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower  = 12'(t) << 4;
      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat= 2'd0;   // TAR_FIT：高位照抄 pc
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid   = 1'b1;
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset  = tl_off;
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing = shr;
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower   = 20'(t) << 4;
      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat = 2'd0;
      io_ftq_to_bpu_update_bits_ftb_entry_isJalr           = (j % 4 == 1) | (j % 4 == 2);
      io_ftq_to_bpu_update_bits_ftb_entry_isRet            = (j % 4 == 2);
      io_ftq_to_bpu_update_bits_ftb_entry_isCall           = (j % 4 == 3);
      // pftAddr=0 且 carry=1 ⇒ fallThrough 正好是下一个 32 B 块，取指流保持块对齐
      io_ftq_to_bpu_update_bits_ftb_entry_pftAddr          = 4'd0;
      io_ftq_to_bpu_update_bits_ftb_entry_carry            = 1'b1;
      io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call = 1'b0;
      io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0    = 1'b0;
      io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1    = 1'b0;
      io_ftq_to_bpu_update_bits_br_taken_mask_0            = brtk0;
      io_ftq_to_bpu_update_bits_br_taken_mask_1            = brtk1;
      io_ftq_to_bpu_update_bits_jmp_taken                  = jtk;
      io_ftq_to_bpu_update_bits_cfi_idx_valid              = brtk0 | brtk1 | jtk;
      io_ftq_to_bpu_update_bits_cfi_idx_bits               = brtk0 ? br_off : tl_off;
      // mispred 是 TAGE 分配新表项的触发条件，必须真的会置起来
      io_ftq_to_bpu_update_bits_mispred_mask_0             = chance(22);
      io_ftq_to_bpu_update_bits_mispred_mask_1             = chance(15);
      io_ftq_to_bpu_update_bits_mispred_mask_2             = chance(10);
      io_ftq_to_bpu_update_bits_false_hit                  = chance(4);
      // old_entry=1 时 FTB 不写（FTB.sv:1332 u_valid = update_valid & ~old_entry）。
      // 已经有表项的块大多不重写，让 FTB 稳下来；没表项的块一定写。
      io_ftq_to_bpu_update_bits_old_entry                  = cap.ent_valid & chance(65);
      io_ftq_to_bpu_update_bits_full_target                = utgt;
      fq_rd  = (fq_rd + 1) % FQD;
      fq_cnt = fq_cnt - 1;
    end else begin
      io_ftq_to_bpu_update_valid = 1'b0;
    end
  endtask

  // ---- FTQ 真重定向 ----
  task automatic drive_redirect();
    int rb;
    io_ftq_to_bpu_redirect_valid = chance(4);
    rb = $urandom_range(0, NBLK - 1);
    // 重定向目标钉在块对齐地址上：它是把取指流拉回训练区间的唯一外部把手
    io_ftq_to_bpu_redirect_bits_cfiUpdate_target = blk_pc(rb);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pc =
        blk_pc($urandom_range(0, NBLK - 1)) + 50'($urandom_range(0, 15)) * 2;
    io_ftq_to_bpu_redirect_bits_level             = $urandom_range(0, 1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid  = chance(80);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC  = chance(40);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall = chance(15);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet  = chance(15);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp       = 4'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr      = 3'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag = $urandom_range(0, 1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value= 5'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag = $urandom_range(0, 1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value= 5'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag  = $urandom_range(0, 1);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value = 5'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit    = chance(60);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit    = chance(30);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit    = chance(30);
    io_ftq_to_bpu_redirect_bits_BTBMissBubble       = chance(20);
    // 历史指针跟着 BPU 自己吐出来的末级指针走：回滚点落在真实走过的历史上，
    // 折叠历史重算才有比对价值（随机指针会把回滚打到一个从没到过的点上）。
    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value =
        chance(80) ? hp_shadow : 8'($urandom());
    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag  =
        chance(80) ? hpf_shadow : $urandom_range(0, 1);
    // shift 只有 0/1/2 合法(numBr=2)；偶尔打 3 压一下越界行为(golden 也有确定语义)
    io_ftq_to_bpu_redirect_bits_cfiUpdate_shift       =
        chance(95) ? 2'($urandom_range(0, 2)) : 2'd3;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist = chance(70);
    io_ftq_to_bpu_redirect_bits_cfiUpdate_taken       = chance(50);
    io_ftq_to_bpu_redirect_bits_debugIsCtrl           = chance(45);
    io_ftq_to_bpu_redirect_bits_debugIsMemVio         = chance(20);
  endtask

  always @(negedge clk) begin
    drive_mbist();
    drive_redirect();
    drive_update();
    io_bpu_to_ftq_resp_ready = chance(80);
    io_ftq_to_bpu_redirctFromIFU = chance(3);
    io_ftq_to_bpu_enq_ptr_flag  = $urandom_range(0, 1);
    io_ftq_to_bpu_enq_ptr_value = 6'($urandom());
    // 复位向量必须是常量：它只在 modified_reset 那拍装进 s0_pc_reg，
    // 随机值会让取指流第一拍就落在一个随机地址上（第一版的 bug）。
    io_reset_vector = 48'(REGION_BASE);
    // 五个使能绝大多数时间全开；留 2% 关一个，覆盖「预测器被关」这条路。
    io_ctrl_ubtb_enable = chance(97); io_ctrl_btb_enable = chance(97);
    io_ctrl_tage_enable = chance(97); io_ctrl_sc_enable  = chance(97);
    io_ctrl_ras_enable  = chance(97);
  end

  // ---- 覆盖计数（关键事件；任一为 0 即判失败）----
  longint cov_s0_fire = 0;
  longint cov_s2_valid = 0;
  longint cov_s3_valid = 0;
  longint cov_ftq_stall = 0;
  longint cov_s1_hit = 0;
  longint cov_s2_hit = 0;
  longint cov_s3_hit = 0;
  longint cov_s1_taken = 0;
  longint cov_s3_taken = 0;
  longint cov_s2_override = 0;
  longint cov_s3_override = 0;
  longint cov_s2_ovr_allen = 0;
  longint cov_s3_ovr_allen = 0;
  longint cov_ovr_b2b = 0;
  longint cov_ftherr = 0;
  longint cov_redirect = 0;
  longint cov_redir_hist = 0;
  longint cov_shift1 = 0;
  longint cov_shift2 = 0;
  longint cov_ctrl_bubble = 0;
  longint cov_memvio_bubble = 0;
  longint cov_ifu_redir = 0;
  longint cov_topdown_set = 0;
  longint cov_update = 0;
  longint cov_upd_write = 0;
  longint cov_upd_brtaken = 0;
  longint cov_upd_mispred = 0;
  longint cov_upd_jalr = 0;
  longint cov_upd_ret = 0;
  longint cov_upd_call = 0;
  longint cov_redir_vs_resp = 0;
  longint cov_hp_wrap = 0;
  longint cov_pred_dis = 0;
  longint cov_mbist_ack = 0;

  // ---- 逐端口失配直方图：定位用，判据仍是 errors 总数 ----
  localparam int NOUT = 125;
  longint eh   [0:NOUT-1];
  string  onm  [0:NOUT-1];
  initial begin
    for (int k = 0; k < NOUT; k++) eh[k] = 0;
    onm[0] = "io_bpu_to_ftq_resp_valid";
    onm[1] = "io_bpu_to_ftq_resp_bits_s1_pc_3";
    onm[2] = "io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle";
    onm[3] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0";
    onm[4] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1";
    onm[5] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0";
    onm[6] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1";
    onm[7] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0";
    onm[8] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1";
    onm[9] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0";
    onm[10] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1";
    onm[11] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr";
    onm[12] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr";
    onm[13] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing";
    onm[14] = "io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit";
    onm[15] = "io_bpu_to_ftq_resp_bits_s2_pc_3";
    onm[16] = "io_bpu_to_ftq_resp_bits_s2_valid_3";
    onm[17] = "io_bpu_to_ftq_resp_bits_s2_hasRedirect_3";
    onm[18] = "io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag";
    onm[19] = "io_bpu_to_ftq_resp_bits_s2_ftq_idx_value";
    onm[20] = "io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle";
    onm[21] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0";
    onm[22] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1";
    onm[23] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0";
    onm[24] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1";
    onm[25] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0";
    onm[26] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1";
    onm[27] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0";
    onm[28] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1";
    onm[29] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr";
    onm[30] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr";
    onm[31] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing";
    onm[32] = "io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit";
    onm[33] = "io_bpu_to_ftq_resp_bits_s3_pc_0";
    onm[34] = "io_bpu_to_ftq_resp_bits_s3_pc_3";
    onm[35] = "io_bpu_to_ftq_resp_bits_s3_valid_0";
    onm[36] = "io_bpu_to_ftq_resp_bits_s3_valid_3";
    onm[37] = "io_bpu_to_ftq_resp_bits_s3_hasRedirect_3";
    onm[38] = "io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag";
    onm[39] = "io_bpu_to_ftq_resp_bits_s3_ftq_idx_value";
    onm[40] = "io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle";
    onm[41] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0";
    onm[42] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1";
    onm[43] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0";
    onm[44] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1";
    onm[45] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0";
    onm[46] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1";
    onm[47] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0";
    onm[48] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1";
    onm[49] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr";
    onm[50] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr";
    onm[51] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing";
    onm[52] = "io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit";
    onm[53] = "io_bpu_to_ftq_resp_bits_last_stage_meta";
    onm[54] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag";
    onm[55] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value";
    onm[56] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp";
    onm[57] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr";
    onm[58] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag";
    onm[59] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value";
    onm[60] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag";
    onm[61] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value";
    onm[62] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag";
    onm[63] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value";
    onm[64] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr";
    onm[65] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0";
    onm[66] = "io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1";
    onm[67] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall";
    onm[68] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet";
    onm[69] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr";
    onm[70] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid";
    onm[71] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset";
    onm[72] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing";
    onm[73] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid";
    onm[74] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower";
    onm[75] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat";
    onm[76] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset";
    onm[77] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing";
    onm[78] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid";
    onm[79] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower";
    onm[80] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat";
    onm[81] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr";
    onm[82] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry";
    onm[83] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call";
    onm[84] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0";
    onm[85] = "io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1";
    onm[86] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_1";
    onm[87] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_2";
    onm[88] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_3";
    onm[89] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_4";
    onm[90] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_5";
    onm[91] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_6";
    onm[92] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_7";
    onm[93] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_8";
    onm[94] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_9";
    onm[95] = "io_bpu_to_ftq_resp_bits_topdown_info_reasons_12";
    onm[96] = "io_perf_0_value";
    onm[97] = "io_perf_1_value";
    onm[98] = "io_perf_2_value";
    onm[99] = "io_perf_3_value";
    onm[100] = "io_perf_4_value";
    onm[101] = "io_perf_5_value";
    onm[102] = "io_perf_6_value";
    onm[103] = "boreChildrenBd_bore_ack";
    onm[104] = "boreChildrenBd_bore_outdata";
    onm[105] = "boreChildrenBd_bore_1_ack";
    onm[106] = "boreChildrenBd_bore_1_outdata";
    onm[107] = "boreChildrenBd_bore_2_ack";
    onm[108] = "boreChildrenBd_bore_2_outdata";
    onm[109] = "boreChildrenBd_bore_3_ack";
    onm[110] = "boreChildrenBd_bore_3_outdata";
    onm[111] = "boreChildrenBd_bore_4_ack";
    onm[112] = "boreChildrenBd_bore_4_outdata";
    onm[113] = "boreChildrenBd_bore_5_ack";
    onm[114] = "boreChildrenBd_bore_5_outdata";
    onm[115] = "boreChildrenBd_bore_6_ack";
    onm[116] = "boreChildrenBd_bore_6_outdata";
    onm[117] = "boreChildrenBd_bore_7_ack";
    onm[118] = "boreChildrenBd_bore_7_outdata";
    onm[119] = "boreChildrenBd_bore_8_ack";
    onm[120] = "boreChildrenBd_bore_8_outdata";
    onm[121] = "boreChildrenBd_bore_9_ack";
    onm[122] = "boreChildrenBd_bore_9_outdata";
    onm[123] = "boreChildrenBd_bore_10_ack";
    onm[124] = "boreChildrenBd_bore_10_outdata";
  end

  // ---- 逐拍比对全部 125 个输出 ----
  always @(posedge clk) if (!rst) begin
    cyc++;
    if (!$isunknown(g_io_bpu_to_ftq_resp_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_valid !== i_io_bpu_to_ftq_resp_valid) begin
        errors++; eh[0]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_valid)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_valid, i_io_bpu_to_ftq_resp_valid);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_pc_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_pc_3 !== i_io_bpu_to_ftq_resp_bits_s1_pc_3) begin
        errors++; eh[1]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_pc_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_pc_3, i_io_bpu_to_ftq_resp_bits_s1_pc_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle) begin
        errors++; eh[2]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0) begin
        errors++; eh[3]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1) begin
        errors++; eh[4]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0) begin
        errors++; eh[5]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1) begin
        errors++; eh[6]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0) begin
        errors++; eh[7]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1) begin
        errors++; eh[8]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0) begin
        errors++; eh[9]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1) begin
        errors++; eh[10]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr) begin
        errors++; eh[11]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr) begin
        errors++; eh[12]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing) begin
        errors++; eh[13]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit) begin
        errors++; eh[14]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_pc_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_pc_3 !== i_io_bpu_to_ftq_resp_bits_s2_pc_3) begin
        errors++; eh[15]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_pc_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_pc_3, i_io_bpu_to_ftq_resp_bits_s2_pc_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_valid_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_valid_3 !== i_io_bpu_to_ftq_resp_bits_s2_valid_3) begin
        errors++; eh[16]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_valid_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_valid_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_valid_3, i_io_bpu_to_ftq_resp_bits_s2_valid_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 !== i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3) begin
        errors++; eh[17]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3, i_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag !== i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag) begin
        errors++; eh[18]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag, i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value !== i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value) begin
        errors++; eh[19]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_ftq_idx_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value, i_io_bpu_to_ftq_resp_bits_s2_ftq_idx_value);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle) begin
        errors++; eh[20]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0) begin
        errors++; eh[21]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1) begin
        errors++; eh[22]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0) begin
        errors++; eh[23]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1) begin
        errors++; eh[24]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0) begin
        errors++; eh[25]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1) begin
        errors++; eh[26]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0) begin
        errors++; eh[27]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1) begin
        errors++; eh[28]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr) begin
        errors++; eh[29]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr) begin
        errors++; eh[30]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing) begin
        errors++; eh[31]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit) begin
        errors++; eh[32]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_pc_0 !== i_io_bpu_to_ftq_resp_bits_s3_pc_0) begin
        errors++; eh[33]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_pc_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_pc_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_pc_0, i_io_bpu_to_ftq_resp_bits_s3_pc_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_pc_3 !== i_io_bpu_to_ftq_resp_bits_s3_pc_3) begin
        errors++; eh[34]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_pc_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_pc_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_pc_3, i_io_bpu_to_ftq_resp_bits_s3_pc_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_valid_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_valid_0 !== i_io_bpu_to_ftq_resp_bits_s3_valid_0) begin
        errors++; eh[35]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_valid_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_valid_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_valid_0, i_io_bpu_to_ftq_resp_bits_s3_valid_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_valid_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_valid_3 !== i_io_bpu_to_ftq_resp_bits_s3_valid_3) begin
        errors++; eh[36]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_valid_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_valid_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_valid_3, i_io_bpu_to_ftq_resp_bits_s3_valid_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 !== i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3) begin
        errors++; eh[37]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3, i_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag !== i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag) begin
        errors++; eh[38]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag, i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value !== i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value) begin
        errors++; eh[39]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_ftq_idx_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value, i_io_bpu_to_ftq_resp_bits_s3_ftq_idx_value);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle) begin
        errors++; eh[40]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle, i_io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0) begin
        errors++; eh[41]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1) begin
        errors++; eh[42]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0) begin
        errors++; eh[43]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1) begin
        errors++; eh[44]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0) begin
        errors++; eh[45]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1) begin
        errors++; eh[46]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0) begin
        errors++; eh[47]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1 !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1) begin
        errors++; eh[48]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr) begin
        errors++; eh[49]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr) begin
        errors++; eh[50]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing) begin
        errors++; eh[51]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit !== i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit) begin
        errors++; eh[52]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit, i_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_meta)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_meta !== i_io_bpu_to_ftq_resp_bits_last_stage_meta) begin
        errors++; eh[53]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_meta)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_meta g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_meta, i_io_bpu_to_ftq_resp_bits_last_stage_meta);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag) begin
        errors++; eh[54]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value) begin
        errors++; eh[55]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp) begin
        errors++; eh[56]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr) begin
        errors++; eh[57]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag) begin
        errors++; eh[58]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value) begin
        errors++; eh[59]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag) begin
        errors++; eh[60]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value) begin
        errors++; eh[61]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag) begin
        errors++; eh[62]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value) begin
        errors++; eh[63]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr) begin
        errors++; eh[64]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0 !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0) begin
        errors++; eh[65]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1 !== i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1) begin
        errors++; eh[66]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1, i_io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall) begin
        errors++; eh[67]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet) begin
        errors++; eh[68]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr) begin
        errors++; eh[69]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid) begin
        errors++; eh[70]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset) begin
        errors++; eh[71]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing) begin
        errors++; eh[72]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid) begin
        errors++; eh[73]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower) begin
        errors++; eh[74]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat) begin
        errors++; eh[75]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset) begin
        errors++; eh[76]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing) begin
        errors++; eh[77]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid) begin
        errors++; eh[78]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower) begin
        errors++; eh[79]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat) begin
        errors++; eh[80]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr) begin
        errors++; eh[81]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry) begin
        errors++; eh[82]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call) begin
        errors++; eh[83]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0 !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0) begin
        errors++; eh[84]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 !== i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1) begin
        errors++; eh[85]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1, i_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1) begin
        errors++; eh[86]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_1 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2) begin
        errors++; eh[87]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_2 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3) begin
        errors++; eh[88]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_3 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_3);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4) begin
        errors++; eh[89]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_4 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_4);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5) begin
        errors++; eh[90]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_5 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_5);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6) begin
        errors++; eh[91]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_6 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_6);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7) begin
        errors++; eh[92]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_7 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_7);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8) begin
        errors++; eh[93]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_8 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_8);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9) begin
        errors++; eh[94]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_9 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9);
      end end
    if (!$isunknown(g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12)) begin checks++;
      if (g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 !== i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12) begin
        errors++; eh[95]++;
        if ($isunknown(i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 g=%h i=%h", $time, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12, i_io_bpu_to_ftq_resp_bits_topdown_info_reasons_12);
      end end
    if (!$isunknown(g_io_perf_0_value)) begin checks++;
      if (g_io_perf_0_value !== i_io_perf_0_value) begin
        errors++; eh[96]++;
        if ($isunknown(i_io_perf_0_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value);
      end end
    if (!$isunknown(g_io_perf_1_value)) begin checks++;
      if (g_io_perf_1_value !== i_io_perf_1_value) begin
        errors++; eh[97]++;
        if ($isunknown(i_io_perf_1_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value);
      end end
    if (!$isunknown(g_io_perf_2_value)) begin checks++;
      if (g_io_perf_2_value !== i_io_perf_2_value) begin
        errors++; eh[98]++;
        if ($isunknown(i_io_perf_2_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value);
      end end
    if (!$isunknown(g_io_perf_3_value)) begin checks++;
      if (g_io_perf_3_value !== i_io_perf_3_value) begin
        errors++; eh[99]++;
        if ($isunknown(i_io_perf_3_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value);
      end end
    if (!$isunknown(g_io_perf_4_value)) begin checks++;
      if (g_io_perf_4_value !== i_io_perf_4_value) begin
        errors++; eh[100]++;
        if ($isunknown(i_io_perf_4_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value);
      end end
    if (!$isunknown(g_io_perf_5_value)) begin checks++;
      if (g_io_perf_5_value !== i_io_perf_5_value) begin
        errors++; eh[101]++;
        if ($isunknown(i_io_perf_5_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value);
      end end
    if (!$isunknown(g_io_perf_6_value)) begin checks++;
      if (g_io_perf_6_value !== i_io_perf_6_value) begin
        errors++; eh[102]++;
        if ($isunknown(i_io_perf_6_value)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_ack)) begin checks++;
      if (g_boreChildrenBd_bore_ack !== i_boreChildrenBd_bore_ack) begin
        errors++; eh[103]++;
        if ($isunknown(i_boreChildrenBd_bore_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_ack g=%h i=%h", $time, g_boreChildrenBd_bore_ack, i_boreChildrenBd_bore_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_outdata !== i_boreChildrenBd_bore_outdata) begin
        errors++; eh[104]++;
        if ($isunknown(i_boreChildrenBd_bore_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_outdata, i_boreChildrenBd_bore_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_1_ack)) begin checks++;
      if (g_boreChildrenBd_bore_1_ack !== i_boreChildrenBd_bore_1_ack) begin
        errors++; eh[105]++;
        if ($isunknown(i_boreChildrenBd_bore_1_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_1_ack g=%h i=%h", $time, g_boreChildrenBd_bore_1_ack, i_boreChildrenBd_bore_1_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_1_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_1_outdata !== i_boreChildrenBd_bore_1_outdata) begin
        errors++; eh[106]++;
        if ($isunknown(i_boreChildrenBd_bore_1_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_1_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_1_outdata, i_boreChildrenBd_bore_1_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_2_ack)) begin checks++;
      if (g_boreChildrenBd_bore_2_ack !== i_boreChildrenBd_bore_2_ack) begin
        errors++; eh[107]++;
        if ($isunknown(i_boreChildrenBd_bore_2_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_2_ack g=%h i=%h", $time, g_boreChildrenBd_bore_2_ack, i_boreChildrenBd_bore_2_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_2_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_2_outdata !== i_boreChildrenBd_bore_2_outdata) begin
        errors++; eh[108]++;
        if ($isunknown(i_boreChildrenBd_bore_2_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_2_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_2_outdata, i_boreChildrenBd_bore_2_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_3_ack)) begin checks++;
      if (g_boreChildrenBd_bore_3_ack !== i_boreChildrenBd_bore_3_ack) begin
        errors++; eh[109]++;
        if ($isunknown(i_boreChildrenBd_bore_3_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_3_ack g=%h i=%h", $time, g_boreChildrenBd_bore_3_ack, i_boreChildrenBd_bore_3_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_3_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_3_outdata !== i_boreChildrenBd_bore_3_outdata) begin
        errors++; eh[110]++;
        if ($isunknown(i_boreChildrenBd_bore_3_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_3_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_3_outdata, i_boreChildrenBd_bore_3_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_4_ack)) begin checks++;
      if (g_boreChildrenBd_bore_4_ack !== i_boreChildrenBd_bore_4_ack) begin
        errors++; eh[111]++;
        if ($isunknown(i_boreChildrenBd_bore_4_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_4_ack g=%h i=%h", $time, g_boreChildrenBd_bore_4_ack, i_boreChildrenBd_bore_4_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_4_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_4_outdata !== i_boreChildrenBd_bore_4_outdata) begin
        errors++; eh[112]++;
        if ($isunknown(i_boreChildrenBd_bore_4_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_4_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_4_outdata, i_boreChildrenBd_bore_4_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_5_ack)) begin checks++;
      if (g_boreChildrenBd_bore_5_ack !== i_boreChildrenBd_bore_5_ack) begin
        errors++; eh[113]++;
        if ($isunknown(i_boreChildrenBd_bore_5_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_5_ack g=%h i=%h", $time, g_boreChildrenBd_bore_5_ack, i_boreChildrenBd_bore_5_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_5_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_5_outdata !== i_boreChildrenBd_bore_5_outdata) begin
        errors++; eh[114]++;
        if ($isunknown(i_boreChildrenBd_bore_5_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_5_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_5_outdata, i_boreChildrenBd_bore_5_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_6_ack)) begin checks++;
      if (g_boreChildrenBd_bore_6_ack !== i_boreChildrenBd_bore_6_ack) begin
        errors++; eh[115]++;
        if ($isunknown(i_boreChildrenBd_bore_6_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_6_ack g=%h i=%h", $time, g_boreChildrenBd_bore_6_ack, i_boreChildrenBd_bore_6_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_6_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_6_outdata !== i_boreChildrenBd_bore_6_outdata) begin
        errors++; eh[116]++;
        if ($isunknown(i_boreChildrenBd_bore_6_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_6_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_6_outdata, i_boreChildrenBd_bore_6_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_7_ack)) begin checks++;
      if (g_boreChildrenBd_bore_7_ack !== i_boreChildrenBd_bore_7_ack) begin
        errors++; eh[117]++;
        if ($isunknown(i_boreChildrenBd_bore_7_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_7_ack g=%h i=%h", $time, g_boreChildrenBd_bore_7_ack, i_boreChildrenBd_bore_7_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_7_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_7_outdata !== i_boreChildrenBd_bore_7_outdata) begin
        errors++; eh[118]++;
        if ($isunknown(i_boreChildrenBd_bore_7_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_7_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_7_outdata, i_boreChildrenBd_bore_7_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_8_ack)) begin checks++;
      if (g_boreChildrenBd_bore_8_ack !== i_boreChildrenBd_bore_8_ack) begin
        errors++; eh[119]++;
        if ($isunknown(i_boreChildrenBd_bore_8_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_8_ack g=%h i=%h", $time, g_boreChildrenBd_bore_8_ack, i_boreChildrenBd_bore_8_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_8_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_8_outdata !== i_boreChildrenBd_bore_8_outdata) begin
        errors++; eh[120]++;
        if ($isunknown(i_boreChildrenBd_bore_8_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_8_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_8_outdata, i_boreChildrenBd_bore_8_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_9_ack)) begin checks++;
      if (g_boreChildrenBd_bore_9_ack !== i_boreChildrenBd_bore_9_ack) begin
        errors++; eh[121]++;
        if ($isunknown(i_boreChildrenBd_bore_9_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_9_ack g=%h i=%h", $time, g_boreChildrenBd_bore_9_ack, i_boreChildrenBd_bore_9_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_9_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_9_outdata !== i_boreChildrenBd_bore_9_outdata) begin
        errors++; eh[122]++;
        if ($isunknown(i_boreChildrenBd_bore_9_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_9_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_9_outdata, i_boreChildrenBd_bore_9_outdata);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_10_ack)) begin checks++;
      if (g_boreChildrenBd_bore_10_ack !== i_boreChildrenBd_bore_10_ack) begin
        errors++; eh[123]++;
        if ($isunknown(i_boreChildrenBd_bore_10_ack)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_10_ack g=%h i=%h", $time, g_boreChildrenBd_bore_10_ack, i_boreChildrenBd_bore_10_ack);
      end end
    if (!$isunknown(g_boreChildrenBd_bore_10_outdata)) begin checks++;
      if (g_boreChildrenBd_bore_10_outdata !== i_boreChildrenBd_bore_10_outdata) begin
        errors++; eh[124]++;
        if ($isunknown(i_boreChildrenBd_bore_10_outdata)) errors_x++; else errors_val++;
        if (errors<=60) $display("[%0t] boreChildrenBd_bore_10_outdata g=%h i=%h", $time, g_boreChildrenBd_bore_10_outdata, i_boreChildrenBd_bore_10_outdata);
      end end
    if (g_io_bpu_to_ftq_resp_valid === 1'b1) cov_s0_fire++;
    if (g_io_bpu_to_ftq_resp_bits_s2_valid_3 === 1'b1) cov_s2_valid++;
    if (g_io_bpu_to_ftq_resp_bits_s3_valid_3 === 1'b1) cov_s3_valid++;
    if (io_bpu_to_ftq_resp_ready === 1'b0) cov_ftq_stall++;
    if (g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit === 1'b1) cov_s1_hit++;
    if (g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit === 1'b1) cov_s2_hit++;
    if (g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit === 1'b1) cov_s3_hit++;
    if ((g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 | g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1) === 1'b1) cov_s1_taken++;
    if ((g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 | g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1) === 1'b1) cov_s3_taken++;
    if (g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1'b1) cov_s2_override++;
    if (g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1'b1) cov_s3_override++;
    if (g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1'b1 && all_pred_en) cov_s2_ovr_allen++;
    if (g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1'b1 && all_pred_en) cov_s3_ovr_allen++;
    if (g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1'b1 && g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1'b1) cov_ovr_b2b++;
    if ((g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr | g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr) === 1'b1) cov_ftherr++;
    if (io_ftq_to_bpu_redirect_valid === 1'b1) cov_redirect++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist) cov_redir_hist++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2'd1) cov_shift1++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2'd2) cov_shift2++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_debugIsCtrl) cov_ctrl_bubble++;
    if (io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_debugIsMemVio) cov_memvio_bubble++;
    if (io_ftq_to_bpu_redirctFromIFU === 1'b1) cov_ifu_redir++;
    if (|{g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9}) cov_topdown_set++;
    if (io_ftq_to_bpu_update_valid === 1'b1) cov_update++;
    if (io_ftq_to_bpu_update_valid && !io_ftq_to_bpu_update_bits_old_entry) cov_upd_write++;
    if (io_ftq_to_bpu_update_valid && io_ftq_to_bpu_update_bits_br_taken_mask_0) cov_upd_brtaken++;
    if (io_ftq_to_bpu_update_valid && |{io_ftq_to_bpu_update_bits_mispred_mask_0, io_ftq_to_bpu_update_bits_mispred_mask_1}) cov_upd_mispred++;
    if (io_ftq_to_bpu_update_valid && io_ftq_to_bpu_update_bits_ftb_entry_isJalr) cov_upd_jalr++;
    if (io_ftq_to_bpu_update_valid && io_ftq_to_bpu_update_bits_ftb_entry_isRet) cov_upd_ret++;
    if (io_ftq_to_bpu_update_valid && io_ftq_to_bpu_update_bits_ftb_entry_isCall) cov_upd_call++;
    if (io_ftq_to_bpu_redirect_valid && g_io_bpu_to_ftq_resp_valid === 1'b1) cov_redir_vs_resp++;
    if (g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag === 1'b1) cov_hp_wrap++;
    if (!all_pred_en) cov_pred_dis++;
    if (|{g_boreChildrenBd_bore_ack, g_boreChildrenBd_bore_1_ack, g_boreChildrenBd_bore_2_ack, g_boreChildrenBd_bore_3_ack, g_boreChildrenBd_bore_4_ack, g_boreChildrenBd_bore_5_ack, g_boreChildrenBd_bore_6_ack, g_boreChildrenBd_bore_7_ack, g_boreChildrenBd_bore_8_ack, g_boreChildrenBd_bore_9_ack, g_boreChildrenBd_bore_10_ack}) cov_mbist_ack++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    // 复位前先把全部功能输入清零：update 各字段只在 update_valid 那拍被驱动，
    // 不清零的话复位期间它们是 X，会平白把 X 灌进 Composer。
    io_bpu_to_ftq_resp_ready = '0;
    io_ftq_to_bpu_redirect_valid = '0;
    io_ftq_to_bpu_redirect_bits_level = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pc = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_target = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_taken = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_shift = '0;
    io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist = '0;
    io_ftq_to_bpu_redirect_bits_debugIsCtrl = '0;
    io_ftq_to_bpu_redirect_bits_debugIsMemVio = '0;
    io_ftq_to_bpu_redirect_bits_BTBMissBubble = '0;
    io_ftq_to_bpu_update_valid = '0;
    io_ftq_to_bpu_update_bits_pc = '0;
    io_ftq_to_bpu_update_bits_spec_info_histPtr_value = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_isCall = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_isRet = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_isJalr = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_valid = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_pftAddr = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_carry = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0 = '0;
    io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1 = '0;
    io_ftq_to_bpu_update_bits_cfi_idx_valid = '0;
    io_ftq_to_bpu_update_bits_cfi_idx_bits = '0;
    io_ftq_to_bpu_update_bits_br_taken_mask_0 = '0;
    io_ftq_to_bpu_update_bits_br_taken_mask_1 = '0;
    io_ftq_to_bpu_update_bits_jmp_taken = '0;
    io_ftq_to_bpu_update_bits_mispred_mask_0 = '0;
    io_ftq_to_bpu_update_bits_mispred_mask_1 = '0;
    io_ftq_to_bpu_update_bits_mispred_mask_2 = '0;
    io_ftq_to_bpu_update_bits_false_hit = '0;
    io_ftq_to_bpu_update_bits_old_entry = '0;
    io_ftq_to_bpu_update_bits_meta = '0;
    io_ftq_to_bpu_update_bits_full_target = '0;
    io_ftq_to_bpu_enq_ptr_flag = '0;
    io_ftq_to_bpu_enq_ptr_value = '0;
    io_ftq_to_bpu_redirctFromIFU = '0;
    io_ctrl_ubtb_enable = '0;
    io_ctrl_btb_enable = '0;
    io_ctrl_tage_enable = '0;
    io_ctrl_sc_enable = '0;
    io_ctrl_ras_enable = '0;
    io_reset_vector = '0;
    for (int j = 0; j < NBLK; j++) begin bpat[j] = 8'($urandom()); phs[j] = 3'd0; end
    rst = 1; repeat (20) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d (errors_x=%0d errors_val=%0d)",
             checks, errors, errors_x, errors_val);
    $display("--- coverage (golden 侧) ---");
    $display("  cov_s0_fire          = %-10d  预测包送 FTQ", cov_s0_fire);
    $display("  cov_s2_valid         = %-10d  S2 级有效", cov_s2_valid);
    $display("  cov_s3_valid         = %-10d  S3 级有效", cov_s3_valid);
    $display("  cov_ftq_stall        = %-10d  FTQ 反压", cov_ftq_stall);
    $display("  cov_s1_hit           = %-10d  S1(uFTB) 命中", cov_s1_hit);
    $display("  cov_s2_hit           = %-10d  S2(FTB) 命中", cov_s2_hit);
    $display("  cov_s3_hit           = %-10d  S3 命中", cov_s3_hit);
    $display("  cov_s1_taken         = %-10d  S1 预测跳转", cov_s1_taken);
    $display("  cov_s3_taken         = %-10d  S3 预测跳转", cov_s3_taken);
    $display("  cov_s2_override      = %-10d  S2 覆盖 S1", cov_s2_override);
    $display("  cov_s3_override      = %-10d  S3 覆盖 S2", cov_s3_override);
    $display("  cov_s2_ovr_allen     = %-10d  S2 覆盖(五个预测器全开) —— 排除「靠关预测器凑出来的覆盖」", cov_s2_ovr_allen);
    $display("  cov_s3_ovr_allen     = %-10d  S3 覆盖(五个预测器全开)", cov_s3_ovr_allen);
    $display("  cov_ovr_b2b          = %-10d  S2/S3 同拍一起覆盖", cov_ovr_b2b);
    $display("  cov_ftherr           = %-10d  fallThrough 越界(S3 覆盖的一条独立成因)", cov_ftherr);
    $display("  cov_redirect         = %-10d  FTQ 真重定向", cov_redirect);
    $display("  cov_redir_hist       = %-10d  重定向且要改历史(走 GHV 回滚慢路)", cov_redir_hist);
    $display("  cov_shift1           = %-10d  回滚 shift=1", cov_shift1);
    $display("  cov_shift2           = %-10d  回滚 shift=2", cov_shift2);
    $display("  cov_ctrl_bubble      = %-10d  控制流气泡归因", cov_ctrl_bubble);
    $display("  cov_memvio_bubble    = %-10d  访存违例气泡归因", cov_memvio_bubble);
    $display("  cov_ifu_redir        = %-10d  IFU 重定向", cov_ifu_redir);
    $display("  cov_topdown_set      = %-10d  topdown 归因置位", cov_topdown_set);
    $display("  cov_update           = %-10d  update 有效", cov_update);
    $display("  cov_upd_write        = %-10d  update 真写 FTB", cov_upd_write);
    $display("  cov_upd_brtaken      = %-10d  update 报第一条分支跳", cov_upd_brtaken);
    $display("  cov_upd_mispred      = %-10d  update 报预测错(TAGE 分配)", cov_upd_mispred);
    $display("  cov_upd_jalr         = %-10d  update 带间接跳转(ITTAGE)", cov_upd_jalr);
    $display("  cov_upd_ret          = %-10d  update 带返回(RAS pop)", cov_upd_ret);
    $display("  cov_upd_call         = %-10d  update 带调用(RAS push)", cov_upd_call);
    $display("  cov_redir_vs_resp    = %-10d  重定向撞上在飞的预测包（冲刷路径真的被走到）", cov_redir_vs_resp);
    $display("  cov_hp_wrap          = %-10d  历史指针绕过 256 位(flag 翻起来)", cov_hp_wrap);
    $display("  cov_pred_dis         = %-10d  至少一个预测器被关", cov_pred_dis);
    $display("  cov_mbist_ack        = %-10d  MBIST 命令被 SRAM 应答(证明 DFT 链真的通)", cov_mbist_ack);
    if (errors != 0) begin
      $display("--- 失配直方图（按端口） ---");
      for (int k = 0; k < NOUT; k++)
        if (eh[k] != 0) $display("  %-58s %0d", onm[k], eh[k]);
    end
    begin
      int unsigned zero_cov = 0;
      if (cov_s0_fire == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s0_fire 从未发生"); end
      if (cov_s2_valid == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_valid 从未发生"); end
      if (cov_s3_valid == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_valid 从未发生"); end
      if (cov_ftq_stall == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ftq_stall 从未发生"); end
      if (cov_s1_hit == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s1_hit 从未发生"); end
      if (cov_s2_hit == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_hit 从未发生"); end
      if (cov_s3_hit == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_hit 从未发生"); end
      if (cov_s1_taken == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s1_taken 从未发生"); end
      if (cov_s3_taken == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_taken 从未发生"); end
      if (cov_s2_override == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_override 从未发生"); end
      if (cov_s3_override == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_override 从未发生"); end
      if (cov_s2_ovr_allen == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_ovr_allen 从未发生"); end
      if (cov_s3_ovr_allen == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_ovr_allen 从未发生"); end
      if (cov_ovr_b2b == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ovr_b2b 从未发生"); end
      if (cov_ftherr == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ftherr 从未发生"); end
      if (cov_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_redirect 从未发生"); end
      if (cov_redir_hist == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_redir_hist 从未发生"); end
      if (cov_shift1 == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_shift1 从未发生"); end
      if (cov_shift2 == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_shift2 从未发生"); end
      if (cov_ctrl_bubble == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ctrl_bubble 从未发生"); end
      if (cov_memvio_bubble == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_memvio_bubble 从未发生"); end
      if (cov_ifu_redir == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ifu_redir 从未发生"); end
      if (cov_topdown_set == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_topdown_set 从未发生"); end
      if (cov_update == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_update 从未发生"); end
      if (cov_upd_write == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_upd_write 从未发生"); end
      if (cov_upd_brtaken == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_upd_brtaken 从未发生"); end
      if (cov_upd_mispred == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_upd_mispred 从未发生"); end
      if (cov_upd_jalr == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_upd_jalr 从未发生"); end
      if (cov_upd_ret == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_upd_ret 从未发生"); end
      if (cov_upd_call == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_upd_call 从未发生"); end
      if (cov_redir_vs_resp == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_redir_vs_resp 从未发生"); end
      if (cov_hp_wrap == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_hp_wrap 从未发生"); end
      if (cov_pred_dis == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_pred_dis 从未发生"); end
      if (cov_mbist_ack == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_mbist_ack 从未发生"); end
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
