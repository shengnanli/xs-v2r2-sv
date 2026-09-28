// 自动生成：verif/ut/BankedDataArray/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// BankedDataArray 双例化逐拍比对：golden vs 重写 _xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= BankedDataArray =================
  int unsigned bda_mode = 0;
  logic bda_reset;
  wire  bda_g_io_read_0_ready, bda_i_io_read_0_ready;
  logic bda_s0_io_read_0_ready = '0, bda_s1_io_read_0_ready = '0;
  logic bda_io_read_0_valid;
  logic [3:0] bda_io_read_0_bits_way_en;
  logic [47:0] bda_io_read_0_bits_addr;
  logic [47:0] bda_io_read_0_bits_addr_dup;
  logic [7:0] bda_io_read_0_bits_bankMask;
  logic bda_io_read_0_bits_lqIdx_flag;
  logic [6:0] bda_io_read_0_bits_lqIdx_value;
  wire  bda_g_io_read_1_ready, bda_i_io_read_1_ready;
  logic bda_s0_io_read_1_ready = '0, bda_s1_io_read_1_ready = '0;
  logic bda_io_read_1_valid;
  logic [3:0] bda_io_read_1_bits_way_en;
  logic [47:0] bda_io_read_1_bits_addr;
  logic [47:0] bda_io_read_1_bits_addr_dup;
  logic [7:0] bda_io_read_1_bits_bankMask;
  logic bda_io_read_1_bits_lqIdx_flag;
  logic [6:0] bda_io_read_1_bits_lqIdx_value;
  wire  bda_g_io_read_2_ready, bda_i_io_read_2_ready;
  logic bda_s0_io_read_2_ready = '0, bda_s1_io_read_2_ready = '0;
  logic bda_io_read_2_valid;
  logic [3:0] bda_io_read_2_bits_way_en;
  logic [47:0] bda_io_read_2_bits_addr;
  logic [47:0] bda_io_read_2_bits_addr_dup;
  logic [7:0] bda_io_read_2_bits_bankMask;
  logic bda_io_read_2_bits_lqIdx_flag;
  logic [6:0] bda_io_read_2_bits_lqIdx_value;
  logic bda_io_is128Req_0;
  logic bda_io_is128Req_1;
  logic bda_io_is128Req_2;
  logic bda_io_readline_intend;
  wire  bda_g_io_readline_ready, bda_i_io_readline_ready;
  logic bda_s0_io_readline_ready = '0, bda_s1_io_readline_ready = '0;
  logic bda_io_readline_valid;
  logic [3:0] bda_io_readline_bits_way_en;
  logic [47:0] bda_io_readline_bits_addr;
  logic [7:0] bda_io_readline_bits_rmask;
  logic bda_io_readline_can_go;
  logic bda_io_readline_stall;
  logic bda_io_readline_can_resp;
  logic bda_io_write_valid;
  logic [7:0] bda_io_write_bits_wmask;
  logic [63:0] bda_io_write_bits_data_0;
  logic [63:0] bda_io_write_bits_data_1;
  logic [63:0] bda_io_write_bits_data_2;
  logic [63:0] bda_io_write_bits_data_3;
  logic [63:0] bda_io_write_bits_data_4;
  logic [63:0] bda_io_write_bits_data_5;
  logic [63:0] bda_io_write_bits_data_6;
  logic [63:0] bda_io_write_bits_data_7;
  logic bda_io_write_dup_0_valid;
  logic [3:0] bda_io_write_dup_0_bits_way_en;
  logic [47:0] bda_io_write_dup_0_bits_addr;
  logic bda_io_write_dup_1_valid;
  logic [3:0] bda_io_write_dup_1_bits_way_en;
  logic [47:0] bda_io_write_dup_1_bits_addr;
  logic bda_io_write_dup_2_valid;
  logic [3:0] bda_io_write_dup_2_bits_way_en;
  logic [47:0] bda_io_write_dup_2_bits_addr;
  logic bda_io_write_dup_3_valid;
  logic [3:0] bda_io_write_dup_3_bits_way_en;
  logic [47:0] bda_io_write_dup_3_bits_addr;
  logic bda_io_write_dup_4_valid;
  logic [3:0] bda_io_write_dup_4_bits_way_en;
  logic [47:0] bda_io_write_dup_4_bits_addr;
  logic bda_io_write_dup_5_valid;
  logic [3:0] bda_io_write_dup_5_bits_way_en;
  logic [47:0] bda_io_write_dup_5_bits_addr;
  logic bda_io_write_dup_6_valid;
  logic [3:0] bda_io_write_dup_6_bits_way_en;
  logic [47:0] bda_io_write_dup_6_bits_addr;
  logic bda_io_write_dup_7_valid;
  logic [3:0] bda_io_write_dup_7_bits_way_en;
  logic [47:0] bda_io_write_dup_7_bits_addr;
  wire  [63:0] bda_g_io_readline_resp_0_raw_data, bda_i_io_readline_resp_0_raw_data;
  logic [63:0] bda_s0_io_readline_resp_0_raw_data = '0, bda_s1_io_readline_resp_0_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_1_raw_data, bda_i_io_readline_resp_1_raw_data;
  logic [63:0] bda_s0_io_readline_resp_1_raw_data = '0, bda_s1_io_readline_resp_1_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_2_raw_data, bda_i_io_readline_resp_2_raw_data;
  logic [63:0] bda_s0_io_readline_resp_2_raw_data = '0, bda_s1_io_readline_resp_2_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_3_raw_data, bda_i_io_readline_resp_3_raw_data;
  logic [63:0] bda_s0_io_readline_resp_3_raw_data = '0, bda_s1_io_readline_resp_3_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_4_raw_data, bda_i_io_readline_resp_4_raw_data;
  logic [63:0] bda_s0_io_readline_resp_4_raw_data = '0, bda_s1_io_readline_resp_4_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_5_raw_data, bda_i_io_readline_resp_5_raw_data;
  logic [63:0] bda_s0_io_readline_resp_5_raw_data = '0, bda_s1_io_readline_resp_5_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_6_raw_data, bda_i_io_readline_resp_6_raw_data;
  logic [63:0] bda_s0_io_readline_resp_6_raw_data = '0, bda_s1_io_readline_resp_6_raw_data = '0;
  wire  [63:0] bda_g_io_readline_resp_7_raw_data, bda_i_io_readline_resp_7_raw_data;
  logic [63:0] bda_s0_io_readline_resp_7_raw_data = '0, bda_s1_io_readline_resp_7_raw_data = '0;
  wire  bda_g_io_readline_error_delayed, bda_i_io_readline_error_delayed;
  logic bda_s0_io_readline_error_delayed = '0, bda_s1_io_readline_error_delayed = '0;
  wire  [63:0] bda_g_io_read_resp_0_0_raw_data, bda_i_io_read_resp_0_0_raw_data;
  logic [63:0] bda_s0_io_read_resp_0_0_raw_data = '0, bda_s1_io_read_resp_0_0_raw_data = '0;
  wire  [63:0] bda_g_io_read_resp_0_1_raw_data, bda_i_io_read_resp_0_1_raw_data;
  logic [63:0] bda_s0_io_read_resp_0_1_raw_data = '0, bda_s1_io_read_resp_0_1_raw_data = '0;
  wire  [63:0] bda_g_io_read_resp_1_0_raw_data, bda_i_io_read_resp_1_0_raw_data;
  logic [63:0] bda_s0_io_read_resp_1_0_raw_data = '0, bda_s1_io_read_resp_1_0_raw_data = '0;
  wire  [63:0] bda_g_io_read_resp_1_1_raw_data, bda_i_io_read_resp_1_1_raw_data;
  logic [63:0] bda_s0_io_read_resp_1_1_raw_data = '0, bda_s1_io_read_resp_1_1_raw_data = '0;
  wire  [63:0] bda_g_io_read_resp_2_0_raw_data, bda_i_io_read_resp_2_0_raw_data;
  logic [63:0] bda_s0_io_read_resp_2_0_raw_data = '0, bda_s1_io_read_resp_2_0_raw_data = '0;
  wire  [63:0] bda_g_io_read_resp_2_1_raw_data, bda_i_io_read_resp_2_1_raw_data;
  logic [63:0] bda_s0_io_read_resp_2_1_raw_data = '0, bda_s1_io_read_resp_2_1_raw_data = '0;
  wire  bda_g_io_read_error_delayed_0_0, bda_i_io_read_error_delayed_0_0;
  logic bda_s0_io_read_error_delayed_0_0 = '0, bda_s1_io_read_error_delayed_0_0 = '0;
  wire  bda_g_io_read_error_delayed_0_1, bda_i_io_read_error_delayed_0_1;
  logic bda_s0_io_read_error_delayed_0_1 = '0, bda_s1_io_read_error_delayed_0_1 = '0;
  wire  bda_g_io_read_error_delayed_1_0, bda_i_io_read_error_delayed_1_0;
  logic bda_s0_io_read_error_delayed_1_0 = '0, bda_s1_io_read_error_delayed_1_0 = '0;
  wire  bda_g_io_read_error_delayed_1_1, bda_i_io_read_error_delayed_1_1;
  logic bda_s0_io_read_error_delayed_1_1 = '0, bda_s1_io_read_error_delayed_1_1 = '0;
  wire  bda_g_io_read_error_delayed_2_0, bda_i_io_read_error_delayed_2_0;
  logic bda_s0_io_read_error_delayed_2_0 = '0, bda_s1_io_read_error_delayed_2_0 = '0;
  wire  bda_g_io_read_error_delayed_2_1, bda_i_io_read_error_delayed_2_1;
  logic bda_s0_io_read_error_delayed_2_1 = '0, bda_s1_io_read_error_delayed_2_1 = '0;
  wire  bda_g_io_bank_conflict_slow_0, bda_i_io_bank_conflict_slow_0;
  logic bda_s0_io_bank_conflict_slow_0 = '0, bda_s1_io_bank_conflict_slow_0 = '0;
  wire  bda_g_io_bank_conflict_slow_1, bda_i_io_bank_conflict_slow_1;
  logic bda_s0_io_bank_conflict_slow_1 = '0, bda_s1_io_bank_conflict_slow_1 = '0;
  wire  bda_g_io_bank_conflict_slow_2, bda_i_io_bank_conflict_slow_2;
  logic bda_s0_io_bank_conflict_slow_2 = '0, bda_s1_io_bank_conflict_slow_2 = '0;
  wire  bda_g_io_disable_ld_fast_wakeup_0, bda_i_io_disable_ld_fast_wakeup_0;
  logic bda_s0_io_disable_ld_fast_wakeup_0 = '0, bda_s1_io_disable_ld_fast_wakeup_0 = '0;
  wire  bda_g_io_disable_ld_fast_wakeup_1, bda_i_io_disable_ld_fast_wakeup_1;
  logic bda_s0_io_disable_ld_fast_wakeup_1 = '0, bda_s1_io_disable_ld_fast_wakeup_1 = '0;
  wire  bda_g_io_disable_ld_fast_wakeup_2, bda_i_io_disable_ld_fast_wakeup_2;
  logic bda_s0_io_disable_ld_fast_wakeup_2 = '0, bda_s1_io_disable_ld_fast_wakeup_2 = '0;
  wire  bda_g_io_pseudo_error_ready, bda_i_io_pseudo_error_ready;
  logic bda_s0_io_pseudo_error_ready = '0, bda_s1_io_pseudo_error_ready = '0;
  logic bda_io_pseudo_error_valid;
  logic bda_io_pseudo_error_bits_0_valid;
  logic [63:0] bda_io_pseudo_error_bits_0_mask;
  logic bda_io_pseudo_error_bits_1_valid;
  logic [63:0] bda_io_pseudo_error_bits_1_mask;
  logic bda_io_pseudo_error_bits_2_valid;
  logic [63:0] bda_io_pseudo_error_bits_2_mask;
  logic bda_io_pseudo_error_bits_3_valid;
  logic [63:0] bda_io_pseudo_error_bits_3_mask;
  logic bda_io_pseudo_error_bits_4_valid;
  logic [63:0] bda_io_pseudo_error_bits_4_mask;
  logic bda_io_pseudo_error_bits_5_valid;
  logic [63:0] bda_io_pseudo_error_bits_5_mask;
  logic bda_io_pseudo_error_bits_6_valid;
  logic [63:0] bda_io_pseudo_error_bits_6_mask;
  logic bda_io_pseudo_error_bits_7_valid;
  logic [63:0] bda_io_pseudo_error_bits_7_mask;
  logic [4:0] bda_boreChildrenBd_bore_array;
  logic bda_boreChildrenBd_bore_all;
  logic bda_boreChildrenBd_bore_req;
  wire  bda_g_boreChildrenBd_bore_ack, bda_i_boreChildrenBd_bore_ack;
  logic bda_s0_boreChildrenBd_bore_ack = '0, bda_s1_boreChildrenBd_bore_ack = '0;
  logic bda_boreChildrenBd_bore_writeen;
  logic bda_boreChildrenBd_bore_be;
  logic [8:0] bda_boreChildrenBd_bore_addr;
  logic [71:0] bda_boreChildrenBd_bore_indata;
  logic bda_boreChildrenBd_bore_readen;
  logic [8:0] bda_boreChildrenBd_bore_addr_rd;
  wire  [71:0] bda_g_boreChildrenBd_bore_outdata, bda_i_boreChildrenBd_bore_outdata;
  logic [71:0] bda_s0_boreChildrenBd_bore_outdata = '0, bda_s1_boreChildrenBd_bore_outdata = '0;
  logic bda_sigFromSrams_bore_ram_hold;
  logic bda_sigFromSrams_bore_ram_bypass;
  logic bda_sigFromSrams_bore_ram_bp_clken;
  logic bda_sigFromSrams_bore_ram_aux_clk;
  logic bda_sigFromSrams_bore_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_ram_mcp_hold;
  logic bda_sigFromSrams_bore_cgen;
  logic bda_sigFromSrams_bore_1_ram_hold;
  logic bda_sigFromSrams_bore_1_ram_bypass;
  logic bda_sigFromSrams_bore_1_ram_bp_clken;
  logic bda_sigFromSrams_bore_1_ram_aux_clk;
  logic bda_sigFromSrams_bore_1_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_1_ram_mcp_hold;
  logic bda_sigFromSrams_bore_1_cgen;
  logic bda_sigFromSrams_bore_2_ram_hold;
  logic bda_sigFromSrams_bore_2_ram_bypass;
  logic bda_sigFromSrams_bore_2_ram_bp_clken;
  logic bda_sigFromSrams_bore_2_ram_aux_clk;
  logic bda_sigFromSrams_bore_2_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_2_ram_mcp_hold;
  logic bda_sigFromSrams_bore_2_cgen;
  logic bda_sigFromSrams_bore_3_ram_hold;
  logic bda_sigFromSrams_bore_3_ram_bypass;
  logic bda_sigFromSrams_bore_3_ram_bp_clken;
  logic bda_sigFromSrams_bore_3_ram_aux_clk;
  logic bda_sigFromSrams_bore_3_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_3_ram_mcp_hold;
  logic bda_sigFromSrams_bore_3_cgen;
  logic bda_sigFromSrams_bore_4_ram_hold;
  logic bda_sigFromSrams_bore_4_ram_bypass;
  logic bda_sigFromSrams_bore_4_ram_bp_clken;
  logic bda_sigFromSrams_bore_4_ram_aux_clk;
  logic bda_sigFromSrams_bore_4_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_4_ram_mcp_hold;
  logic bda_sigFromSrams_bore_4_cgen;
  logic bda_sigFromSrams_bore_5_ram_hold;
  logic bda_sigFromSrams_bore_5_ram_bypass;
  logic bda_sigFromSrams_bore_5_ram_bp_clken;
  logic bda_sigFromSrams_bore_5_ram_aux_clk;
  logic bda_sigFromSrams_bore_5_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_5_ram_mcp_hold;
  logic bda_sigFromSrams_bore_5_cgen;
  logic bda_sigFromSrams_bore_6_ram_hold;
  logic bda_sigFromSrams_bore_6_ram_bypass;
  logic bda_sigFromSrams_bore_6_ram_bp_clken;
  logic bda_sigFromSrams_bore_6_ram_aux_clk;
  logic bda_sigFromSrams_bore_6_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_6_ram_mcp_hold;
  logic bda_sigFromSrams_bore_6_cgen;
  logic bda_sigFromSrams_bore_7_ram_hold;
  logic bda_sigFromSrams_bore_7_ram_bypass;
  logic bda_sigFromSrams_bore_7_ram_bp_clken;
  logic bda_sigFromSrams_bore_7_ram_aux_clk;
  logic bda_sigFromSrams_bore_7_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_7_ram_mcp_hold;
  logic bda_sigFromSrams_bore_7_cgen;
  logic bda_sigFromSrams_bore_8_ram_hold;
  logic bda_sigFromSrams_bore_8_ram_bypass;
  logic bda_sigFromSrams_bore_8_ram_bp_clken;
  logic bda_sigFromSrams_bore_8_ram_aux_clk;
  logic bda_sigFromSrams_bore_8_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_8_ram_mcp_hold;
  logic bda_sigFromSrams_bore_8_cgen;
  logic bda_sigFromSrams_bore_9_ram_hold;
  logic bda_sigFromSrams_bore_9_ram_bypass;
  logic bda_sigFromSrams_bore_9_ram_bp_clken;
  logic bda_sigFromSrams_bore_9_ram_aux_clk;
  logic bda_sigFromSrams_bore_9_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_9_ram_mcp_hold;
  logic bda_sigFromSrams_bore_9_cgen;
  logic bda_sigFromSrams_bore_10_ram_hold;
  logic bda_sigFromSrams_bore_10_ram_bypass;
  logic bda_sigFromSrams_bore_10_ram_bp_clken;
  logic bda_sigFromSrams_bore_10_ram_aux_clk;
  logic bda_sigFromSrams_bore_10_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_10_ram_mcp_hold;
  logic bda_sigFromSrams_bore_10_cgen;
  logic bda_sigFromSrams_bore_11_ram_hold;
  logic bda_sigFromSrams_bore_11_ram_bypass;
  logic bda_sigFromSrams_bore_11_ram_bp_clken;
  logic bda_sigFromSrams_bore_11_ram_aux_clk;
  logic bda_sigFromSrams_bore_11_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_11_ram_mcp_hold;
  logic bda_sigFromSrams_bore_11_cgen;
  logic bda_sigFromSrams_bore_12_ram_hold;
  logic bda_sigFromSrams_bore_12_ram_bypass;
  logic bda_sigFromSrams_bore_12_ram_bp_clken;
  logic bda_sigFromSrams_bore_12_ram_aux_clk;
  logic bda_sigFromSrams_bore_12_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_12_ram_mcp_hold;
  logic bda_sigFromSrams_bore_12_cgen;
  logic bda_sigFromSrams_bore_13_ram_hold;
  logic bda_sigFromSrams_bore_13_ram_bypass;
  logic bda_sigFromSrams_bore_13_ram_bp_clken;
  logic bda_sigFromSrams_bore_13_ram_aux_clk;
  logic bda_sigFromSrams_bore_13_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_13_ram_mcp_hold;
  logic bda_sigFromSrams_bore_13_cgen;
  logic bda_sigFromSrams_bore_14_ram_hold;
  logic bda_sigFromSrams_bore_14_ram_bypass;
  logic bda_sigFromSrams_bore_14_ram_bp_clken;
  logic bda_sigFromSrams_bore_14_ram_aux_clk;
  logic bda_sigFromSrams_bore_14_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_14_ram_mcp_hold;
  logic bda_sigFromSrams_bore_14_cgen;
  logic bda_sigFromSrams_bore_15_ram_hold;
  logic bda_sigFromSrams_bore_15_ram_bypass;
  logic bda_sigFromSrams_bore_15_ram_bp_clken;
  logic bda_sigFromSrams_bore_15_ram_aux_clk;
  logic bda_sigFromSrams_bore_15_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_15_ram_mcp_hold;
  logic bda_sigFromSrams_bore_15_cgen;
  logic bda_sigFromSrams_bore_16_ram_hold;
  logic bda_sigFromSrams_bore_16_ram_bypass;
  logic bda_sigFromSrams_bore_16_ram_bp_clken;
  logic bda_sigFromSrams_bore_16_ram_aux_clk;
  logic bda_sigFromSrams_bore_16_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_16_ram_mcp_hold;
  logic bda_sigFromSrams_bore_16_cgen;
  logic bda_sigFromSrams_bore_17_ram_hold;
  logic bda_sigFromSrams_bore_17_ram_bypass;
  logic bda_sigFromSrams_bore_17_ram_bp_clken;
  logic bda_sigFromSrams_bore_17_ram_aux_clk;
  logic bda_sigFromSrams_bore_17_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_17_ram_mcp_hold;
  logic bda_sigFromSrams_bore_17_cgen;
  logic bda_sigFromSrams_bore_18_ram_hold;
  logic bda_sigFromSrams_bore_18_ram_bypass;
  logic bda_sigFromSrams_bore_18_ram_bp_clken;
  logic bda_sigFromSrams_bore_18_ram_aux_clk;
  logic bda_sigFromSrams_bore_18_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_18_ram_mcp_hold;
  logic bda_sigFromSrams_bore_18_cgen;
  logic bda_sigFromSrams_bore_19_ram_hold;
  logic bda_sigFromSrams_bore_19_ram_bypass;
  logic bda_sigFromSrams_bore_19_ram_bp_clken;
  logic bda_sigFromSrams_bore_19_ram_aux_clk;
  logic bda_sigFromSrams_bore_19_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_19_ram_mcp_hold;
  logic bda_sigFromSrams_bore_19_cgen;
  logic bda_sigFromSrams_bore_20_ram_hold;
  logic bda_sigFromSrams_bore_20_ram_bypass;
  logic bda_sigFromSrams_bore_20_ram_bp_clken;
  logic bda_sigFromSrams_bore_20_ram_aux_clk;
  logic bda_sigFromSrams_bore_20_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_20_ram_mcp_hold;
  logic bda_sigFromSrams_bore_20_cgen;
  logic bda_sigFromSrams_bore_21_ram_hold;
  logic bda_sigFromSrams_bore_21_ram_bypass;
  logic bda_sigFromSrams_bore_21_ram_bp_clken;
  logic bda_sigFromSrams_bore_21_ram_aux_clk;
  logic bda_sigFromSrams_bore_21_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_21_ram_mcp_hold;
  logic bda_sigFromSrams_bore_21_cgen;
  logic bda_sigFromSrams_bore_22_ram_hold;
  logic bda_sigFromSrams_bore_22_ram_bypass;
  logic bda_sigFromSrams_bore_22_ram_bp_clken;
  logic bda_sigFromSrams_bore_22_ram_aux_clk;
  logic bda_sigFromSrams_bore_22_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_22_ram_mcp_hold;
  logic bda_sigFromSrams_bore_22_cgen;
  logic bda_sigFromSrams_bore_23_ram_hold;
  logic bda_sigFromSrams_bore_23_ram_bypass;
  logic bda_sigFromSrams_bore_23_ram_bp_clken;
  logic bda_sigFromSrams_bore_23_ram_aux_clk;
  logic bda_sigFromSrams_bore_23_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_23_ram_mcp_hold;
  logic bda_sigFromSrams_bore_23_cgen;
  logic bda_sigFromSrams_bore_24_ram_hold;
  logic bda_sigFromSrams_bore_24_ram_bypass;
  logic bda_sigFromSrams_bore_24_ram_bp_clken;
  logic bda_sigFromSrams_bore_24_ram_aux_clk;
  logic bda_sigFromSrams_bore_24_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_24_ram_mcp_hold;
  logic bda_sigFromSrams_bore_24_cgen;
  logic bda_sigFromSrams_bore_25_ram_hold;
  logic bda_sigFromSrams_bore_25_ram_bypass;
  logic bda_sigFromSrams_bore_25_ram_bp_clken;
  logic bda_sigFromSrams_bore_25_ram_aux_clk;
  logic bda_sigFromSrams_bore_25_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_25_ram_mcp_hold;
  logic bda_sigFromSrams_bore_25_cgen;
  logic bda_sigFromSrams_bore_26_ram_hold;
  logic bda_sigFromSrams_bore_26_ram_bypass;
  logic bda_sigFromSrams_bore_26_ram_bp_clken;
  logic bda_sigFromSrams_bore_26_ram_aux_clk;
  logic bda_sigFromSrams_bore_26_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_26_ram_mcp_hold;
  logic bda_sigFromSrams_bore_26_cgen;
  logic bda_sigFromSrams_bore_27_ram_hold;
  logic bda_sigFromSrams_bore_27_ram_bypass;
  logic bda_sigFromSrams_bore_27_ram_bp_clken;
  logic bda_sigFromSrams_bore_27_ram_aux_clk;
  logic bda_sigFromSrams_bore_27_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_27_ram_mcp_hold;
  logic bda_sigFromSrams_bore_27_cgen;
  logic bda_sigFromSrams_bore_28_ram_hold;
  logic bda_sigFromSrams_bore_28_ram_bypass;
  logic bda_sigFromSrams_bore_28_ram_bp_clken;
  logic bda_sigFromSrams_bore_28_ram_aux_clk;
  logic bda_sigFromSrams_bore_28_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_28_ram_mcp_hold;
  logic bda_sigFromSrams_bore_28_cgen;
  logic bda_sigFromSrams_bore_29_ram_hold;
  logic bda_sigFromSrams_bore_29_ram_bypass;
  logic bda_sigFromSrams_bore_29_ram_bp_clken;
  logic bda_sigFromSrams_bore_29_ram_aux_clk;
  logic bda_sigFromSrams_bore_29_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_29_ram_mcp_hold;
  logic bda_sigFromSrams_bore_29_cgen;
  logic bda_sigFromSrams_bore_30_ram_hold;
  logic bda_sigFromSrams_bore_30_ram_bypass;
  logic bda_sigFromSrams_bore_30_ram_bp_clken;
  logic bda_sigFromSrams_bore_30_ram_aux_clk;
  logic bda_sigFromSrams_bore_30_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_30_ram_mcp_hold;
  logic bda_sigFromSrams_bore_30_cgen;
  logic bda_sigFromSrams_bore_31_ram_hold;
  logic bda_sigFromSrams_bore_31_ram_bypass;
  logic bda_sigFromSrams_bore_31_ram_bp_clken;
  logic bda_sigFromSrams_bore_31_ram_aux_clk;
  logic bda_sigFromSrams_bore_31_ram_aux_ckbp;
  logic bda_sigFromSrams_bore_31_ram_mcp_hold;
  logic bda_sigFromSrams_bore_31_cgen;
  int bda_cov_rr_conflict = 0;
  int bda_cov_rr_oldest_kill = 0;
  int bda_cov_wr_conflict = 0;
  int bda_cov_rrl_conflict = 0;
  int bda_cov_readline_blocked = 0;
  int bda_cov_read_err = 0;
  int bda_cov_readline_err = 0;
  int bda_cov_pseudo_ready = 0;
  int bda_cov_mbist_ack = 0;
  int bda_cov_is128_read = 0;
  logic [3:0] bda_armed = '0;
  int bda_armed_at = -1;
  BankedDataArray bda_u_gold (
    .clock(clk),
    .reset(bda_reset),
    .io_read_0_ready(bda_g_io_read_0_ready),
    .io_read_0_valid(bda_io_read_0_valid),
    .io_read_0_bits_way_en(bda_io_read_0_bits_way_en),
    .io_read_0_bits_addr(bda_io_read_0_bits_addr),
    .io_read_0_bits_addr_dup(bda_io_read_0_bits_addr_dup),
    .io_read_0_bits_bankMask(bda_io_read_0_bits_bankMask),
    .io_read_0_bits_lqIdx_flag(bda_io_read_0_bits_lqIdx_flag),
    .io_read_0_bits_lqIdx_value(bda_io_read_0_bits_lqIdx_value),
    .io_read_1_ready(bda_g_io_read_1_ready),
    .io_read_1_valid(bda_io_read_1_valid),
    .io_read_1_bits_way_en(bda_io_read_1_bits_way_en),
    .io_read_1_bits_addr(bda_io_read_1_bits_addr),
    .io_read_1_bits_addr_dup(bda_io_read_1_bits_addr_dup),
    .io_read_1_bits_bankMask(bda_io_read_1_bits_bankMask),
    .io_read_1_bits_lqIdx_flag(bda_io_read_1_bits_lqIdx_flag),
    .io_read_1_bits_lqIdx_value(bda_io_read_1_bits_lqIdx_value),
    .io_read_2_ready(bda_g_io_read_2_ready),
    .io_read_2_valid(bda_io_read_2_valid),
    .io_read_2_bits_way_en(bda_io_read_2_bits_way_en),
    .io_read_2_bits_addr(bda_io_read_2_bits_addr),
    .io_read_2_bits_addr_dup(bda_io_read_2_bits_addr_dup),
    .io_read_2_bits_bankMask(bda_io_read_2_bits_bankMask),
    .io_read_2_bits_lqIdx_flag(bda_io_read_2_bits_lqIdx_flag),
    .io_read_2_bits_lqIdx_value(bda_io_read_2_bits_lqIdx_value),
    .io_is128Req_0(bda_io_is128Req_0),
    .io_is128Req_1(bda_io_is128Req_1),
    .io_is128Req_2(bda_io_is128Req_2),
    .io_readline_intend(bda_io_readline_intend),
    .io_readline_ready(bda_g_io_readline_ready),
    .io_readline_valid(bda_io_readline_valid),
    .io_readline_bits_way_en(bda_io_readline_bits_way_en),
    .io_readline_bits_addr(bda_io_readline_bits_addr),
    .io_readline_bits_rmask(bda_io_readline_bits_rmask),
    .io_readline_can_go(bda_io_readline_can_go),
    .io_readline_stall(bda_io_readline_stall),
    .io_readline_can_resp(bda_io_readline_can_resp),
    .io_write_valid(bda_io_write_valid),
    .io_write_bits_wmask(bda_io_write_bits_wmask),
    .io_write_bits_data_0(bda_io_write_bits_data_0),
    .io_write_bits_data_1(bda_io_write_bits_data_1),
    .io_write_bits_data_2(bda_io_write_bits_data_2),
    .io_write_bits_data_3(bda_io_write_bits_data_3),
    .io_write_bits_data_4(bda_io_write_bits_data_4),
    .io_write_bits_data_5(bda_io_write_bits_data_5),
    .io_write_bits_data_6(bda_io_write_bits_data_6),
    .io_write_bits_data_7(bda_io_write_bits_data_7),
    .io_write_dup_0_valid(bda_io_write_dup_0_valid),
    .io_write_dup_0_bits_way_en(bda_io_write_dup_0_bits_way_en),
    .io_write_dup_0_bits_addr(bda_io_write_dup_0_bits_addr),
    .io_write_dup_1_valid(bda_io_write_dup_1_valid),
    .io_write_dup_1_bits_way_en(bda_io_write_dup_1_bits_way_en),
    .io_write_dup_1_bits_addr(bda_io_write_dup_1_bits_addr),
    .io_write_dup_2_valid(bda_io_write_dup_2_valid),
    .io_write_dup_2_bits_way_en(bda_io_write_dup_2_bits_way_en),
    .io_write_dup_2_bits_addr(bda_io_write_dup_2_bits_addr),
    .io_write_dup_3_valid(bda_io_write_dup_3_valid),
    .io_write_dup_3_bits_way_en(bda_io_write_dup_3_bits_way_en),
    .io_write_dup_3_bits_addr(bda_io_write_dup_3_bits_addr),
    .io_write_dup_4_valid(bda_io_write_dup_4_valid),
    .io_write_dup_4_bits_way_en(bda_io_write_dup_4_bits_way_en),
    .io_write_dup_4_bits_addr(bda_io_write_dup_4_bits_addr),
    .io_write_dup_5_valid(bda_io_write_dup_5_valid),
    .io_write_dup_5_bits_way_en(bda_io_write_dup_5_bits_way_en),
    .io_write_dup_5_bits_addr(bda_io_write_dup_5_bits_addr),
    .io_write_dup_6_valid(bda_io_write_dup_6_valid),
    .io_write_dup_6_bits_way_en(bda_io_write_dup_6_bits_way_en),
    .io_write_dup_6_bits_addr(bda_io_write_dup_6_bits_addr),
    .io_write_dup_7_valid(bda_io_write_dup_7_valid),
    .io_write_dup_7_bits_way_en(bda_io_write_dup_7_bits_way_en),
    .io_write_dup_7_bits_addr(bda_io_write_dup_7_bits_addr),
    .io_readline_resp_0_raw_data(bda_g_io_readline_resp_0_raw_data),
    .io_readline_resp_1_raw_data(bda_g_io_readline_resp_1_raw_data),
    .io_readline_resp_2_raw_data(bda_g_io_readline_resp_2_raw_data),
    .io_readline_resp_3_raw_data(bda_g_io_readline_resp_3_raw_data),
    .io_readline_resp_4_raw_data(bda_g_io_readline_resp_4_raw_data),
    .io_readline_resp_5_raw_data(bda_g_io_readline_resp_5_raw_data),
    .io_readline_resp_6_raw_data(bda_g_io_readline_resp_6_raw_data),
    .io_readline_resp_7_raw_data(bda_g_io_readline_resp_7_raw_data),
    .io_readline_error_delayed(bda_g_io_readline_error_delayed),
    .io_read_resp_0_0_raw_data(bda_g_io_read_resp_0_0_raw_data),
    .io_read_resp_0_1_raw_data(bda_g_io_read_resp_0_1_raw_data),
    .io_read_resp_1_0_raw_data(bda_g_io_read_resp_1_0_raw_data),
    .io_read_resp_1_1_raw_data(bda_g_io_read_resp_1_1_raw_data),
    .io_read_resp_2_0_raw_data(bda_g_io_read_resp_2_0_raw_data),
    .io_read_resp_2_1_raw_data(bda_g_io_read_resp_2_1_raw_data),
    .io_read_error_delayed_0_0(bda_g_io_read_error_delayed_0_0),
    .io_read_error_delayed_0_1(bda_g_io_read_error_delayed_0_1),
    .io_read_error_delayed_1_0(bda_g_io_read_error_delayed_1_0),
    .io_read_error_delayed_1_1(bda_g_io_read_error_delayed_1_1),
    .io_read_error_delayed_2_0(bda_g_io_read_error_delayed_2_0),
    .io_read_error_delayed_2_1(bda_g_io_read_error_delayed_2_1),
    .io_bank_conflict_slow_0(bda_g_io_bank_conflict_slow_0),
    .io_bank_conflict_slow_1(bda_g_io_bank_conflict_slow_1),
    .io_bank_conflict_slow_2(bda_g_io_bank_conflict_slow_2),
    .io_disable_ld_fast_wakeup_0(bda_g_io_disable_ld_fast_wakeup_0),
    .io_disable_ld_fast_wakeup_1(bda_g_io_disable_ld_fast_wakeup_1),
    .io_disable_ld_fast_wakeup_2(bda_g_io_disable_ld_fast_wakeup_2),
    .io_pseudo_error_ready(bda_g_io_pseudo_error_ready),
    .io_pseudo_error_valid(bda_io_pseudo_error_valid),
    .io_pseudo_error_bits_0_valid(bda_io_pseudo_error_bits_0_valid),
    .io_pseudo_error_bits_0_mask(bda_io_pseudo_error_bits_0_mask),
    .io_pseudo_error_bits_1_valid(bda_io_pseudo_error_bits_1_valid),
    .io_pseudo_error_bits_1_mask(bda_io_pseudo_error_bits_1_mask),
    .io_pseudo_error_bits_2_valid(bda_io_pseudo_error_bits_2_valid),
    .io_pseudo_error_bits_2_mask(bda_io_pseudo_error_bits_2_mask),
    .io_pseudo_error_bits_3_valid(bda_io_pseudo_error_bits_3_valid),
    .io_pseudo_error_bits_3_mask(bda_io_pseudo_error_bits_3_mask),
    .io_pseudo_error_bits_4_valid(bda_io_pseudo_error_bits_4_valid),
    .io_pseudo_error_bits_4_mask(bda_io_pseudo_error_bits_4_mask),
    .io_pseudo_error_bits_5_valid(bda_io_pseudo_error_bits_5_valid),
    .io_pseudo_error_bits_5_mask(bda_io_pseudo_error_bits_5_mask),
    .io_pseudo_error_bits_6_valid(bda_io_pseudo_error_bits_6_valid),
    .io_pseudo_error_bits_6_mask(bda_io_pseudo_error_bits_6_mask),
    .io_pseudo_error_bits_7_valid(bda_io_pseudo_error_bits_7_valid),
    .io_pseudo_error_bits_7_mask(bda_io_pseudo_error_bits_7_mask),
    .boreChildrenBd_bore_array(bda_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(bda_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(bda_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(bda_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(bda_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(bda_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(bda_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(bda_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(bda_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(bda_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(bda_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(bda_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(bda_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(bda_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(bda_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(bda_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(bda_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(bda_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(bda_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(bda_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(bda_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(bda_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(bda_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(bda_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(bda_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(bda_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(bda_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(bda_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(bda_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(bda_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(bda_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(bda_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(bda_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(bda_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(bda_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(bda_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(bda_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(bda_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(bda_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(bda_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(bda_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(bda_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(bda_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(bda_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(bda_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(bda_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(bda_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(bda_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(bda_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(bda_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(bda_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(bda_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(bda_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(bda_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(bda_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(bda_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(bda_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(bda_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(bda_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(bda_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(bda_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(bda_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(bda_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(bda_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(bda_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(bda_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(bda_sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(bda_sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(bda_sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(bda_sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(bda_sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(bda_sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(bda_sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(bda_sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(bda_sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(bda_sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(bda_sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(bda_sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(bda_sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(bda_sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(bda_sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(bda_sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(bda_sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(bda_sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(bda_sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(bda_sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(bda_sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(bda_sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(bda_sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(bda_sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(bda_sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(bda_sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(bda_sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(bda_sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(bda_sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(bda_sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(bda_sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(bda_sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(bda_sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(bda_sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(bda_sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(bda_sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(bda_sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(bda_sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(bda_sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(bda_sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(bda_sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(bda_sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(bda_sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(bda_sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(bda_sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(bda_sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(bda_sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(bda_sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(bda_sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(bda_sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(bda_sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(bda_sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(bda_sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(bda_sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(bda_sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(bda_sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(bda_sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(bda_sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(bda_sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(bda_sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(bda_sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(bda_sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(bda_sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(bda_sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(bda_sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(bda_sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(bda_sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(bda_sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(bda_sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(bda_sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(bda_sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(bda_sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(bda_sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(bda_sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(bda_sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(bda_sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(bda_sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(bda_sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(bda_sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(bda_sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(bda_sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(bda_sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(bda_sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(bda_sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(bda_sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(bda_sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(bda_sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(bda_sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(bda_sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(bda_sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(bda_sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(bda_sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(bda_sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(bda_sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(bda_sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(bda_sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(bda_sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(bda_sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(bda_sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(bda_sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(bda_sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(bda_sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(bda_sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(bda_sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(bda_sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(bda_sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(bda_sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(bda_sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(bda_sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(bda_sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(bda_sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(bda_sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(bda_sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(bda_sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(bda_sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(bda_sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(bda_sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(bda_sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(bda_sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(bda_sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(bda_sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(bda_sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(bda_sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(bda_sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(bda_sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(bda_sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(bda_sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(bda_sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(bda_sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(bda_sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(bda_sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(bda_sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(bda_sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(bda_sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(bda_sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(bda_sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(bda_sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(bda_sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(bda_sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(bda_sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(bda_sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(bda_sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(bda_sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(bda_sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(bda_sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(bda_sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(bda_sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(bda_sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(bda_sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(bda_sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(bda_sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(bda_sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(bda_sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(bda_sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(bda_sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(bda_sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(bda_sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(bda_sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(bda_sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(bda_sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(bda_sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(bda_sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(bda_sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(bda_sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(bda_sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(bda_sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(bda_sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(bda_sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(bda_sigFromSrams_bore_31_cgen)
  );
  BankedDataArray_xs bda_u_impl (
    .clock(clk),
    .reset(bda_reset),
    .io_read_0_ready(bda_i_io_read_0_ready),
    .io_read_0_valid(bda_io_read_0_valid),
    .io_read_0_bits_way_en(bda_io_read_0_bits_way_en),
    .io_read_0_bits_addr(bda_io_read_0_bits_addr),
    .io_read_0_bits_addr_dup(bda_io_read_0_bits_addr_dup),
    .io_read_0_bits_bankMask(bda_io_read_0_bits_bankMask),
    .io_read_0_bits_lqIdx_flag(bda_io_read_0_bits_lqIdx_flag),
    .io_read_0_bits_lqIdx_value(bda_io_read_0_bits_lqIdx_value),
    .io_read_1_ready(bda_i_io_read_1_ready),
    .io_read_1_valid(bda_io_read_1_valid),
    .io_read_1_bits_way_en(bda_io_read_1_bits_way_en),
    .io_read_1_bits_addr(bda_io_read_1_bits_addr),
    .io_read_1_bits_addr_dup(bda_io_read_1_bits_addr_dup),
    .io_read_1_bits_bankMask(bda_io_read_1_bits_bankMask),
    .io_read_1_bits_lqIdx_flag(bda_io_read_1_bits_lqIdx_flag),
    .io_read_1_bits_lqIdx_value(bda_io_read_1_bits_lqIdx_value),
    .io_read_2_ready(bda_i_io_read_2_ready),
    .io_read_2_valid(bda_io_read_2_valid),
    .io_read_2_bits_way_en(bda_io_read_2_bits_way_en),
    .io_read_2_bits_addr(bda_io_read_2_bits_addr),
    .io_read_2_bits_addr_dup(bda_io_read_2_bits_addr_dup),
    .io_read_2_bits_bankMask(bda_io_read_2_bits_bankMask),
    .io_read_2_bits_lqIdx_flag(bda_io_read_2_bits_lqIdx_flag),
    .io_read_2_bits_lqIdx_value(bda_io_read_2_bits_lqIdx_value),
    .io_is128Req_0(bda_io_is128Req_0),
    .io_is128Req_1(bda_io_is128Req_1),
    .io_is128Req_2(bda_io_is128Req_2),
    .io_readline_intend(bda_io_readline_intend),
    .io_readline_ready(bda_i_io_readline_ready),
    .io_readline_valid(bda_io_readline_valid),
    .io_readline_bits_way_en(bda_io_readline_bits_way_en),
    .io_readline_bits_addr(bda_io_readline_bits_addr),
    .io_readline_bits_rmask(bda_io_readline_bits_rmask),
    .io_readline_can_go(bda_io_readline_can_go),
    .io_readline_stall(bda_io_readline_stall),
    .io_readline_can_resp(bda_io_readline_can_resp),
    .io_write_valid(bda_io_write_valid),
    .io_write_bits_wmask(bda_io_write_bits_wmask),
    .io_write_bits_data_0(bda_io_write_bits_data_0),
    .io_write_bits_data_1(bda_io_write_bits_data_1),
    .io_write_bits_data_2(bda_io_write_bits_data_2),
    .io_write_bits_data_3(bda_io_write_bits_data_3),
    .io_write_bits_data_4(bda_io_write_bits_data_4),
    .io_write_bits_data_5(bda_io_write_bits_data_5),
    .io_write_bits_data_6(bda_io_write_bits_data_6),
    .io_write_bits_data_7(bda_io_write_bits_data_7),
    .io_write_dup_0_valid(bda_io_write_dup_0_valid),
    .io_write_dup_0_bits_way_en(bda_io_write_dup_0_bits_way_en),
    .io_write_dup_0_bits_addr(bda_io_write_dup_0_bits_addr),
    .io_write_dup_1_valid(bda_io_write_dup_1_valid),
    .io_write_dup_1_bits_way_en(bda_io_write_dup_1_bits_way_en),
    .io_write_dup_1_bits_addr(bda_io_write_dup_1_bits_addr),
    .io_write_dup_2_valid(bda_io_write_dup_2_valid),
    .io_write_dup_2_bits_way_en(bda_io_write_dup_2_bits_way_en),
    .io_write_dup_2_bits_addr(bda_io_write_dup_2_bits_addr),
    .io_write_dup_3_valid(bda_io_write_dup_3_valid),
    .io_write_dup_3_bits_way_en(bda_io_write_dup_3_bits_way_en),
    .io_write_dup_3_bits_addr(bda_io_write_dup_3_bits_addr),
    .io_write_dup_4_valid(bda_io_write_dup_4_valid),
    .io_write_dup_4_bits_way_en(bda_io_write_dup_4_bits_way_en),
    .io_write_dup_4_bits_addr(bda_io_write_dup_4_bits_addr),
    .io_write_dup_5_valid(bda_io_write_dup_5_valid),
    .io_write_dup_5_bits_way_en(bda_io_write_dup_5_bits_way_en),
    .io_write_dup_5_bits_addr(bda_io_write_dup_5_bits_addr),
    .io_write_dup_6_valid(bda_io_write_dup_6_valid),
    .io_write_dup_6_bits_way_en(bda_io_write_dup_6_bits_way_en),
    .io_write_dup_6_bits_addr(bda_io_write_dup_6_bits_addr),
    .io_write_dup_7_valid(bda_io_write_dup_7_valid),
    .io_write_dup_7_bits_way_en(bda_io_write_dup_7_bits_way_en),
    .io_write_dup_7_bits_addr(bda_io_write_dup_7_bits_addr),
    .io_readline_resp_0_raw_data(bda_i_io_readline_resp_0_raw_data),
    .io_readline_resp_1_raw_data(bda_i_io_readline_resp_1_raw_data),
    .io_readline_resp_2_raw_data(bda_i_io_readline_resp_2_raw_data),
    .io_readline_resp_3_raw_data(bda_i_io_readline_resp_3_raw_data),
    .io_readline_resp_4_raw_data(bda_i_io_readline_resp_4_raw_data),
    .io_readline_resp_5_raw_data(bda_i_io_readline_resp_5_raw_data),
    .io_readline_resp_6_raw_data(bda_i_io_readline_resp_6_raw_data),
    .io_readline_resp_7_raw_data(bda_i_io_readline_resp_7_raw_data),
    .io_readline_error_delayed(bda_i_io_readline_error_delayed),
    .io_read_resp_0_0_raw_data(bda_i_io_read_resp_0_0_raw_data),
    .io_read_resp_0_1_raw_data(bda_i_io_read_resp_0_1_raw_data),
    .io_read_resp_1_0_raw_data(bda_i_io_read_resp_1_0_raw_data),
    .io_read_resp_1_1_raw_data(bda_i_io_read_resp_1_1_raw_data),
    .io_read_resp_2_0_raw_data(bda_i_io_read_resp_2_0_raw_data),
    .io_read_resp_2_1_raw_data(bda_i_io_read_resp_2_1_raw_data),
    .io_read_error_delayed_0_0(bda_i_io_read_error_delayed_0_0),
    .io_read_error_delayed_0_1(bda_i_io_read_error_delayed_0_1),
    .io_read_error_delayed_1_0(bda_i_io_read_error_delayed_1_0),
    .io_read_error_delayed_1_1(bda_i_io_read_error_delayed_1_1),
    .io_read_error_delayed_2_0(bda_i_io_read_error_delayed_2_0),
    .io_read_error_delayed_2_1(bda_i_io_read_error_delayed_2_1),
    .io_bank_conflict_slow_0(bda_i_io_bank_conflict_slow_0),
    .io_bank_conflict_slow_1(bda_i_io_bank_conflict_slow_1),
    .io_bank_conflict_slow_2(bda_i_io_bank_conflict_slow_2),
    .io_disable_ld_fast_wakeup_0(bda_i_io_disable_ld_fast_wakeup_0),
    .io_disable_ld_fast_wakeup_1(bda_i_io_disable_ld_fast_wakeup_1),
    .io_disable_ld_fast_wakeup_2(bda_i_io_disable_ld_fast_wakeup_2),
    .io_pseudo_error_ready(bda_i_io_pseudo_error_ready),
    .io_pseudo_error_valid(bda_io_pseudo_error_valid),
    .io_pseudo_error_bits_0_valid(bda_io_pseudo_error_bits_0_valid),
    .io_pseudo_error_bits_0_mask(bda_io_pseudo_error_bits_0_mask),
    .io_pseudo_error_bits_1_valid(bda_io_pseudo_error_bits_1_valid),
    .io_pseudo_error_bits_1_mask(bda_io_pseudo_error_bits_1_mask),
    .io_pseudo_error_bits_2_valid(bda_io_pseudo_error_bits_2_valid),
    .io_pseudo_error_bits_2_mask(bda_io_pseudo_error_bits_2_mask),
    .io_pseudo_error_bits_3_valid(bda_io_pseudo_error_bits_3_valid),
    .io_pseudo_error_bits_3_mask(bda_io_pseudo_error_bits_3_mask),
    .io_pseudo_error_bits_4_valid(bda_io_pseudo_error_bits_4_valid),
    .io_pseudo_error_bits_4_mask(bda_io_pseudo_error_bits_4_mask),
    .io_pseudo_error_bits_5_valid(bda_io_pseudo_error_bits_5_valid),
    .io_pseudo_error_bits_5_mask(bda_io_pseudo_error_bits_5_mask),
    .io_pseudo_error_bits_6_valid(bda_io_pseudo_error_bits_6_valid),
    .io_pseudo_error_bits_6_mask(bda_io_pseudo_error_bits_6_mask),
    .io_pseudo_error_bits_7_valid(bda_io_pseudo_error_bits_7_valid),
    .io_pseudo_error_bits_7_mask(bda_io_pseudo_error_bits_7_mask),
    .boreChildrenBd_bore_array(bda_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(bda_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(bda_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(bda_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(bda_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(bda_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(bda_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(bda_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(bda_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(bda_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(bda_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(bda_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(bda_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(bda_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(bda_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(bda_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(bda_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(bda_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(bda_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(bda_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(bda_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(bda_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(bda_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(bda_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(bda_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(bda_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(bda_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(bda_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(bda_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(bda_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(bda_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(bda_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(bda_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(bda_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(bda_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(bda_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(bda_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(bda_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(bda_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(bda_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(bda_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(bda_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(bda_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(bda_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(bda_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(bda_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(bda_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(bda_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(bda_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(bda_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(bda_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(bda_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(bda_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(bda_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(bda_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(bda_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(bda_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(bda_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(bda_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(bda_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(bda_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(bda_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(bda_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(bda_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(bda_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(bda_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(bda_sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold(bda_sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass(bda_sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken(bda_sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk(bda_sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp(bda_sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold(bda_sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen(bda_sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold(bda_sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass(bda_sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken(bda_sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk(bda_sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp(bda_sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold(bda_sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen(bda_sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold(bda_sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass(bda_sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken(bda_sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk(bda_sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp(bda_sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold(bda_sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen(bda_sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold(bda_sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass(bda_sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken(bda_sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk(bda_sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp(bda_sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold(bda_sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen(bda_sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold(bda_sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass(bda_sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken(bda_sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk(bda_sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp(bda_sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold(bda_sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen(bda_sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold(bda_sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass(bda_sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken(bda_sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk(bda_sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp(bda_sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold(bda_sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen(bda_sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold(bda_sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass(bda_sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken(bda_sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk(bda_sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp(bda_sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold(bda_sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen(bda_sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold(bda_sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass(bda_sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken(bda_sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk(bda_sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp(bda_sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold(bda_sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen(bda_sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold(bda_sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass(bda_sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken(bda_sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk(bda_sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp(bda_sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold(bda_sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen(bda_sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold(bda_sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass(bda_sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken(bda_sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk(bda_sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp(bda_sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold(bda_sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen(bda_sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold(bda_sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass(bda_sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken(bda_sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk(bda_sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp(bda_sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold(bda_sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen(bda_sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold(bda_sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass(bda_sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken(bda_sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk(bda_sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp(bda_sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold(bda_sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen(bda_sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold(bda_sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass(bda_sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken(bda_sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk(bda_sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp(bda_sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold(bda_sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen(bda_sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold(bda_sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass(bda_sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken(bda_sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk(bda_sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp(bda_sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold(bda_sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen(bda_sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold(bda_sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass(bda_sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken(bda_sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk(bda_sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp(bda_sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold(bda_sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen(bda_sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold(bda_sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass(bda_sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken(bda_sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk(bda_sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp(bda_sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold(bda_sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen(bda_sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold(bda_sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass(bda_sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken(bda_sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk(bda_sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp(bda_sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold(bda_sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen(bda_sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold(bda_sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass(bda_sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken(bda_sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk(bda_sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp(bda_sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold(bda_sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen(bda_sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold(bda_sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass(bda_sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken(bda_sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk(bda_sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp(bda_sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold(bda_sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen(bda_sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold(bda_sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass(bda_sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken(bda_sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk(bda_sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp(bda_sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold(bda_sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen(bda_sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold(bda_sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass(bda_sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken(bda_sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk(bda_sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp(bda_sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold(bda_sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen(bda_sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold(bda_sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass(bda_sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken(bda_sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk(bda_sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp(bda_sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold(bda_sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen(bda_sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold(bda_sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass(bda_sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken(bda_sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk(bda_sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp(bda_sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold(bda_sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen(bda_sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold(bda_sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass(bda_sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken(bda_sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk(bda_sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp(bda_sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold(bda_sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen(bda_sigFromSrams_bore_31_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) bda_mode = $urandom_range(0, 15);
      bda_io_read_0_valid = 1'($urandom);
      bda_io_read_0_bits_way_en = 4'($urandom);
      bda_io_read_0_bits_addr = 48'({$urandom, $urandom});
      bda_io_read_0_bits_addr_dup = 48'({$urandom, $urandom});
      bda_io_read_0_bits_bankMask = 8'($urandom);
      bda_io_read_0_bits_lqIdx_flag = 1'($urandom);
      bda_io_read_0_bits_lqIdx_value = 7'($urandom);
      bda_io_read_1_valid = 1'($urandom);
      bda_io_read_1_bits_way_en = 4'($urandom);
      bda_io_read_1_bits_addr = 48'({$urandom, $urandom});
      bda_io_read_1_bits_addr_dup = 48'({$urandom, $urandom});
      bda_io_read_1_bits_bankMask = 8'($urandom);
      bda_io_read_1_bits_lqIdx_flag = 1'($urandom);
      bda_io_read_1_bits_lqIdx_value = 7'($urandom);
      bda_io_read_2_valid = 1'($urandom);
      bda_io_read_2_bits_way_en = 4'($urandom);
      bda_io_read_2_bits_addr = 48'({$urandom, $urandom});
      bda_io_read_2_bits_addr_dup = 48'({$urandom, $urandom});
      bda_io_read_2_bits_bankMask = 8'($urandom);
      bda_io_read_2_bits_lqIdx_flag = 1'($urandom);
      bda_io_read_2_bits_lqIdx_value = 7'($urandom);
      bda_io_is128Req_0 = 1'($urandom);
      bda_io_is128Req_1 = 1'($urandom);
      bda_io_is128Req_2 = 1'($urandom);
      bda_io_readline_intend = 1'($urandom);
      bda_io_readline_valid = 1'($urandom);
      bda_io_readline_bits_way_en = 4'($urandom);
      bda_io_readline_bits_addr = 48'({$urandom, $urandom});
      bda_io_readline_bits_rmask = 8'($urandom);
      bda_io_readline_can_go = 1'($urandom);
      bda_io_readline_stall = 1'($urandom);
      bda_io_readline_can_resp = 1'($urandom);
      bda_io_write_valid = 1'($urandom);
      bda_io_write_bits_wmask = 8'($urandom);
      bda_io_write_bits_data_0 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_1 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_2 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_3 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_4 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_5 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_6 = 64'({$urandom, $urandom});
      bda_io_write_bits_data_7 = 64'({$urandom, $urandom});
      bda_io_write_dup_0_valid = 1'($urandom);
      bda_io_write_dup_0_bits_way_en = 4'($urandom);
      bda_io_write_dup_0_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_1_valid = 1'($urandom);
      bda_io_write_dup_1_bits_way_en = 4'($urandom);
      bda_io_write_dup_1_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_2_valid = 1'($urandom);
      bda_io_write_dup_2_bits_way_en = 4'($urandom);
      bda_io_write_dup_2_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_3_valid = 1'($urandom);
      bda_io_write_dup_3_bits_way_en = 4'($urandom);
      bda_io_write_dup_3_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_4_valid = 1'($urandom);
      bda_io_write_dup_4_bits_way_en = 4'($urandom);
      bda_io_write_dup_4_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_5_valid = 1'($urandom);
      bda_io_write_dup_5_bits_way_en = 4'($urandom);
      bda_io_write_dup_5_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_6_valid = 1'($urandom);
      bda_io_write_dup_6_bits_way_en = 4'($urandom);
      bda_io_write_dup_6_bits_addr = 48'({$urandom, $urandom});
      bda_io_write_dup_7_valid = 1'($urandom);
      bda_io_write_dup_7_bits_way_en = 4'($urandom);
      bda_io_write_dup_7_bits_addr = 48'({$urandom, $urandom});
      bda_io_pseudo_error_valid = 1'($urandom);
      bda_io_pseudo_error_bits_0_valid = 1'($urandom);
      bda_io_pseudo_error_bits_0_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_1_valid = 1'($urandom);
      bda_io_pseudo_error_bits_1_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_2_valid = 1'($urandom);
      bda_io_pseudo_error_bits_2_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_3_valid = 1'($urandom);
      bda_io_pseudo_error_bits_3_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_4_valid = 1'($urandom);
      bda_io_pseudo_error_bits_4_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_5_valid = 1'($urandom);
      bda_io_pseudo_error_bits_5_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_6_valid = 1'($urandom);
      bda_io_pseudo_error_bits_6_mask = 64'({$urandom, $urandom});
      bda_io_pseudo_error_bits_7_valid = 1'($urandom);
      bda_io_pseudo_error_bits_7_mask = 64'({$urandom, $urandom});
      bda_boreChildrenBd_bore_array = 5'($urandom);
      bda_boreChildrenBd_bore_all = 1'($urandom);
      bda_boreChildrenBd_bore_req = 1'($urandom);
      bda_boreChildrenBd_bore_writeen = 1'($urandom);
      bda_boreChildrenBd_bore_be = 1'($urandom);
      bda_boreChildrenBd_bore_addr = 9'($urandom);
      bda_boreChildrenBd_bore_indata = 72'({$urandom, $urandom, $urandom});
      bda_boreChildrenBd_bore_readen = 1'($urandom);
      bda_boreChildrenBd_bore_addr_rd = 9'($urandom);
      bda_sigFromSrams_bore_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_cgen = 1'($urandom);
      bda_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_1_cgen = 1'($urandom);
      bda_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_2_cgen = 1'($urandom);
      bda_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_3_cgen = 1'($urandom);
      bda_sigFromSrams_bore_4_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_4_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_4_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_4_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_4_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_4_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_4_cgen = 1'($urandom);
      bda_sigFromSrams_bore_5_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_5_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_5_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_5_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_5_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_5_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_5_cgen = 1'($urandom);
      bda_sigFromSrams_bore_6_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_6_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_6_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_6_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_6_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_6_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_6_cgen = 1'($urandom);
      bda_sigFromSrams_bore_7_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_7_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_7_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_7_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_7_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_7_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_7_cgen = 1'($urandom);
      bda_sigFromSrams_bore_8_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_8_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_8_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_8_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_8_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_8_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_8_cgen = 1'($urandom);
      bda_sigFromSrams_bore_9_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_9_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_9_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_9_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_9_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_9_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_9_cgen = 1'($urandom);
      bda_sigFromSrams_bore_10_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_10_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_10_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_10_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_10_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_10_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_10_cgen = 1'($urandom);
      bda_sigFromSrams_bore_11_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_11_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_11_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_11_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_11_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_11_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_11_cgen = 1'($urandom);
      bda_sigFromSrams_bore_12_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_12_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_12_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_12_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_12_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_12_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_12_cgen = 1'($urandom);
      bda_sigFromSrams_bore_13_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_13_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_13_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_13_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_13_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_13_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_13_cgen = 1'($urandom);
      bda_sigFromSrams_bore_14_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_14_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_14_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_14_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_14_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_14_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_14_cgen = 1'($urandom);
      bda_sigFromSrams_bore_15_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_15_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_15_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_15_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_15_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_15_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_15_cgen = 1'($urandom);
      bda_sigFromSrams_bore_16_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_16_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_16_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_16_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_16_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_16_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_16_cgen = 1'($urandom);
      bda_sigFromSrams_bore_17_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_17_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_17_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_17_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_17_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_17_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_17_cgen = 1'($urandom);
      bda_sigFromSrams_bore_18_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_18_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_18_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_18_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_18_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_18_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_18_cgen = 1'($urandom);
      bda_sigFromSrams_bore_19_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_19_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_19_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_19_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_19_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_19_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_19_cgen = 1'($urandom);
      bda_sigFromSrams_bore_20_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_20_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_20_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_20_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_20_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_20_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_20_cgen = 1'($urandom);
      bda_sigFromSrams_bore_21_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_21_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_21_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_21_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_21_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_21_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_21_cgen = 1'($urandom);
      bda_sigFromSrams_bore_22_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_22_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_22_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_22_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_22_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_22_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_22_cgen = 1'($urandom);
      bda_sigFromSrams_bore_23_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_23_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_23_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_23_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_23_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_23_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_23_cgen = 1'($urandom);
      bda_sigFromSrams_bore_24_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_24_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_24_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_24_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_24_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_24_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_24_cgen = 1'($urandom);
      bda_sigFromSrams_bore_25_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_25_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_25_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_25_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_25_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_25_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_25_cgen = 1'($urandom);
      bda_sigFromSrams_bore_26_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_26_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_26_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_26_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_26_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_26_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_26_cgen = 1'($urandom);
      bda_sigFromSrams_bore_27_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_27_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_27_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_27_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_27_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_27_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_27_cgen = 1'($urandom);
      bda_sigFromSrams_bore_28_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_28_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_28_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_28_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_28_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_28_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_28_cgen = 1'($urandom);
      bda_sigFromSrams_bore_29_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_29_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_29_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_29_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_29_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_29_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_29_cgen = 1'($urandom);
      bda_sigFromSrams_bore_30_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_30_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_30_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_30_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_30_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_30_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_30_cgen = 1'($urandom);
      bda_sigFromSrams_bore_31_ram_hold = 1'($urandom);
      bda_sigFromSrams_bore_31_ram_bypass = 1'($urandom);
      bda_sigFromSrams_bore_31_ram_bp_clken = 1'($urandom);
      bda_sigFromSrams_bore_31_ram_aux_clk = 1'($urandom);
      bda_sigFromSrams_bore_31_ram_aux_ckbp = 1'($urandom);
      bda_sigFromSrams_bore_31_ram_mcp_hold = 1'($urandom);
      bda_sigFromSrams_bore_31_cgen = 1'($urandom);
      bda_reset = (cyc < RESET_CYC) || ($urandom_range(0, 59999) == 0);
      begin : stim_bda
        bda_io_read_0_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_read_0_bits_addr_dup = bda_io_read_0_bits_addr;
        if ($urandom_range(0, 7) == 0) bda_io_read_0_bits_addr_dup[5:3] = 3'($urandom);
        bda_io_read_0_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_read_0_bits_lqIdx_value = 7'($urandom_range(0, 3));
        if ($urandom_range(0, 1)) bda_io_read_0_bits_bankMask = bda_io_is128Req_0 ? (8'b11 << bda_io_read_0_bits_addr[5:3]) : (8'b1 << bda_io_read_0_bits_addr[5:3]);
        bda_io_read_1_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_read_1_bits_addr_dup = bda_io_read_1_bits_addr;
        if ($urandom_range(0, 7) == 0) bda_io_read_1_bits_addr_dup[5:3] = 3'($urandom);
        bda_io_read_1_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_read_1_bits_lqIdx_value = 7'($urandom_range(0, 3));
        if ($urandom_range(0, 1)) bda_io_read_1_bits_bankMask = bda_io_is128Req_1 ? (8'b11 << bda_io_read_1_bits_addr[5:3]) : (8'b1 << bda_io_read_1_bits_addr[5:3]);
        bda_io_read_2_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_read_2_bits_addr_dup = bda_io_read_2_bits_addr;
        if ($urandom_range(0, 7) == 0) bda_io_read_2_bits_addr_dup[5:3] = 3'($urandom);
        bda_io_read_2_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_read_2_bits_lqIdx_value = 7'($urandom_range(0, 3));
        if ($urandom_range(0, 1)) bda_io_read_2_bits_bankMask = bda_io_is128Req_2 ? (8'b11 << bda_io_read_2_bits_addr[5:3]) : (8'b1 << bda_io_read_2_bits_addr[5:3]);
        bda_io_readline_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_readline_bits_way_en = 4'b0001 << $urandom_range(0, 3);
        bda_io_readline_valid = ($urandom_range(0, 3) == 0);
        bda_io_write_valid = ($urandom_range(0, 3) == 0);
        bda_io_write_dup_0_valid = bda_io_write_valid;
        bda_io_write_dup_0_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_0_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_1_valid = bda_io_write_valid;
        bda_io_write_dup_1_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_1_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_2_valid = bda_io_write_valid;
        bda_io_write_dup_2_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_2_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_3_valid = bda_io_write_valid;
        bda_io_write_dup_3_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_3_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_4_valid = bda_io_write_valid;
        bda_io_write_dup_4_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_4_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_5_valid = bda_io_write_valid;
        bda_io_write_dup_5_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_5_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_6_valid = bda_io_write_valid;
        bda_io_write_dup_6_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_6_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_write_dup_7_valid = bda_io_write_valid;
        bda_io_write_dup_7_bits_addr[13:6] = 8'($urandom_range(0, 7));
        bda_io_write_dup_7_bits_way_en = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'b0001 << $urandom_range(0, 3);
        bda_io_pseudo_error_valid = ($urandom_range(0, 7) == 0);
        if (bda_mode < 12 || cyc < 300) begin
          bda_boreChildrenBd_bore_array = '0;
          bda_boreChildrenBd_bore_all = '0;
          bda_boreChildrenBd_bore_req = '0;
          bda_boreChildrenBd_bore_writeen = '0;
          bda_boreChildrenBd_bore_be = '0;
          bda_boreChildrenBd_bore_addr = '0;
          bda_boreChildrenBd_bore_indata = '0;
          bda_boreChildrenBd_bore_readen = '0;
          bda_boreChildrenBd_bore_addr_rd = '0;
        end
        bda_boreChildrenBd_bore_addr = 9'($urandom_range(0, 7));
        bda_boreChildrenBd_bore_addr_rd = 9'($urandom_range(0, 7));
        if (cyc < 300) begin
          bda_io_read_0_valid = 1'b0; bda_io_read_1_valid = 1'b0; bda_io_read_2_valid = 1'b0;
          bda_io_readline_valid = 1'b0; bda_io_readline_intend = 1'b0;
          bda_io_write_valid = 1'b1; bda_io_write_bits_wmask = 8'hFF;
          bda_io_write_dup_0_valid = 1'b1;
          bda_io_write_dup_0_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_0_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_1_valid = 1'b1;
          bda_io_write_dup_1_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_1_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_2_valid = 1'b1;
          bda_io_write_dup_2_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_2_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_3_valid = 1'b1;
          bda_io_write_dup_3_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_3_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_4_valid = 1'b1;
          bda_io_write_dup_4_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_4_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_5_valid = 1'b1;
          bda_io_write_dup_5_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_5_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_6_valid = 1'b1;
          bda_io_write_dup_6_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_6_bits_way_en = 4'b0001 << (cyc % 4);
          bda_io_write_dup_7_valid = 1'b1;
          bda_io_write_dup_7_bits_addr[13:6] = 8'((cyc / 4) % 8);
          bda_io_write_dup_7_bits_way_en = 4'b0001 << (cyc % 4);
        end
        if (cyc >= 300 && cyc < 310) begin
          bda_io_read_0_valid = 1'b0; bda_io_read_1_valid = 1'b0; bda_io_read_2_valid = 1'b0;
          bda_io_write_valid = 1'b0;
          bda_io_write_dup_0_valid = 1'b0;
          bda_io_write_dup_1_valid = 1'b0;
          bda_io_write_dup_2_valid = 1'b0;
          bda_io_write_dup_3_valid = 1'b0;
          bda_io_write_dup_4_valid = 1'b0;
          bda_io_write_dup_5_valid = 1'b0;
          bda_io_write_dup_6_valid = 1'b0;
          bda_io_write_dup_7_valid = 1'b0;
          bda_io_readline_valid = 1'b1; bda_io_readline_bits_addr[13:6] = 8'(cyc % 8);
          bda_io_readline_can_go = 1'b1; bda_io_readline_stall = 1'b1; bda_io_readline_can_resp = 1'b1;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && bda_armed_at >= 0 && cyc >= bda_armed_at) begin
        checks++;
        if (bda_g_io_read_0_ready !== bda_i_io_read_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_0_ready g=%h i=%h", cyc, bda_g_io_read_0_ready, bda_i_io_read_0_ready);
        end
        bda_s1_io_read_0_ready |= bda_g_io_read_0_ready;
        bda_s0_io_read_0_ready |= ~bda_g_io_read_0_ready;
        checks++;
        if (bda_g_io_read_1_ready !== bda_i_io_read_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_1_ready g=%h i=%h", cyc, bda_g_io_read_1_ready, bda_i_io_read_1_ready);
        end
        bda_s1_io_read_1_ready |= bda_g_io_read_1_ready;
        bda_s0_io_read_1_ready |= ~bda_g_io_read_1_ready;
        checks++;
        if (bda_g_io_read_2_ready !== bda_i_io_read_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_2_ready g=%h i=%h", cyc, bda_g_io_read_2_ready, bda_i_io_read_2_ready);
        end
        bda_s1_io_read_2_ready |= bda_g_io_read_2_ready;
        bda_s0_io_read_2_ready |= ~bda_g_io_read_2_ready;
        checks++;
        if (bda_g_io_readline_ready !== bda_i_io_readline_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_ready g=%h i=%h", cyc, bda_g_io_readline_ready, bda_i_io_readline_ready);
        end
        bda_s1_io_readline_ready |= bda_g_io_readline_ready;
        bda_s0_io_readline_ready |= ~bda_g_io_readline_ready;
        checks++;
        if (bda_g_io_readline_resp_0_raw_data !== bda_i_io_readline_resp_0_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_0_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_0_raw_data, bda_i_io_readline_resp_0_raw_data);
        end
        bda_s1_io_readline_resp_0_raw_data |= bda_g_io_readline_resp_0_raw_data;
        bda_s0_io_readline_resp_0_raw_data |= ~bda_g_io_readline_resp_0_raw_data;
        checks++;
        if (bda_g_io_readline_resp_1_raw_data !== bda_i_io_readline_resp_1_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_1_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_1_raw_data, bda_i_io_readline_resp_1_raw_data);
        end
        bda_s1_io_readline_resp_1_raw_data |= bda_g_io_readline_resp_1_raw_data;
        bda_s0_io_readline_resp_1_raw_data |= ~bda_g_io_readline_resp_1_raw_data;
        checks++;
        if (bda_g_io_readline_resp_2_raw_data !== bda_i_io_readline_resp_2_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_2_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_2_raw_data, bda_i_io_readline_resp_2_raw_data);
        end
        bda_s1_io_readline_resp_2_raw_data |= bda_g_io_readline_resp_2_raw_data;
        bda_s0_io_readline_resp_2_raw_data |= ~bda_g_io_readline_resp_2_raw_data;
        checks++;
        if (bda_g_io_readline_resp_3_raw_data !== bda_i_io_readline_resp_3_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_3_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_3_raw_data, bda_i_io_readline_resp_3_raw_data);
        end
        bda_s1_io_readline_resp_3_raw_data |= bda_g_io_readline_resp_3_raw_data;
        bda_s0_io_readline_resp_3_raw_data |= ~bda_g_io_readline_resp_3_raw_data;
        checks++;
        if (bda_g_io_readline_resp_4_raw_data !== bda_i_io_readline_resp_4_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_4_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_4_raw_data, bda_i_io_readline_resp_4_raw_data);
        end
        bda_s1_io_readline_resp_4_raw_data |= bda_g_io_readline_resp_4_raw_data;
        bda_s0_io_readline_resp_4_raw_data |= ~bda_g_io_readline_resp_4_raw_data;
        checks++;
        if (bda_g_io_readline_resp_5_raw_data !== bda_i_io_readline_resp_5_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_5_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_5_raw_data, bda_i_io_readline_resp_5_raw_data);
        end
        bda_s1_io_readline_resp_5_raw_data |= bda_g_io_readline_resp_5_raw_data;
        bda_s0_io_readline_resp_5_raw_data |= ~bda_g_io_readline_resp_5_raw_data;
        checks++;
        if (bda_g_io_readline_resp_6_raw_data !== bda_i_io_readline_resp_6_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_6_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_6_raw_data, bda_i_io_readline_resp_6_raw_data);
        end
        bda_s1_io_readline_resp_6_raw_data |= bda_g_io_readline_resp_6_raw_data;
        bda_s0_io_readline_resp_6_raw_data |= ~bda_g_io_readline_resp_6_raw_data;
        checks++;
        if (bda_g_io_readline_resp_7_raw_data !== bda_i_io_readline_resp_7_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_resp_7_raw_data g=%h i=%h", cyc, bda_g_io_readline_resp_7_raw_data, bda_i_io_readline_resp_7_raw_data);
        end
        bda_s1_io_readline_resp_7_raw_data |= bda_g_io_readline_resp_7_raw_data;
        bda_s0_io_readline_resp_7_raw_data |= ~bda_g_io_readline_resp_7_raw_data;
        checks++;
        if (bda_g_io_readline_error_delayed !== bda_i_io_readline_error_delayed) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_readline_error_delayed g=%h i=%h", cyc, bda_g_io_readline_error_delayed, bda_i_io_readline_error_delayed);
        end
        bda_s1_io_readline_error_delayed |= bda_g_io_readline_error_delayed;
        bda_s0_io_readline_error_delayed |= ~bda_g_io_readline_error_delayed;
        checks++;
        if (bda_g_io_read_resp_0_0_raw_data !== bda_i_io_read_resp_0_0_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_resp_0_0_raw_data g=%h i=%h", cyc, bda_g_io_read_resp_0_0_raw_data, bda_i_io_read_resp_0_0_raw_data);
        end
        bda_s1_io_read_resp_0_0_raw_data |= bda_g_io_read_resp_0_0_raw_data;
        bda_s0_io_read_resp_0_0_raw_data |= ~bda_g_io_read_resp_0_0_raw_data;
        checks++;
        if (bda_g_io_read_resp_0_1_raw_data !== bda_i_io_read_resp_0_1_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_resp_0_1_raw_data g=%h i=%h", cyc, bda_g_io_read_resp_0_1_raw_data, bda_i_io_read_resp_0_1_raw_data);
        end
        bda_s1_io_read_resp_0_1_raw_data |= bda_g_io_read_resp_0_1_raw_data;
        bda_s0_io_read_resp_0_1_raw_data |= ~bda_g_io_read_resp_0_1_raw_data;
        checks++;
        if (bda_g_io_read_resp_1_0_raw_data !== bda_i_io_read_resp_1_0_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_resp_1_0_raw_data g=%h i=%h", cyc, bda_g_io_read_resp_1_0_raw_data, bda_i_io_read_resp_1_0_raw_data);
        end
        bda_s1_io_read_resp_1_0_raw_data |= bda_g_io_read_resp_1_0_raw_data;
        bda_s0_io_read_resp_1_0_raw_data |= ~bda_g_io_read_resp_1_0_raw_data;
        checks++;
        if (bda_g_io_read_resp_1_1_raw_data !== bda_i_io_read_resp_1_1_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_resp_1_1_raw_data g=%h i=%h", cyc, bda_g_io_read_resp_1_1_raw_data, bda_i_io_read_resp_1_1_raw_data);
        end
        bda_s1_io_read_resp_1_1_raw_data |= bda_g_io_read_resp_1_1_raw_data;
        bda_s0_io_read_resp_1_1_raw_data |= ~bda_g_io_read_resp_1_1_raw_data;
        checks++;
        if (bda_g_io_read_resp_2_0_raw_data !== bda_i_io_read_resp_2_0_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_resp_2_0_raw_data g=%h i=%h", cyc, bda_g_io_read_resp_2_0_raw_data, bda_i_io_read_resp_2_0_raw_data);
        end
        bda_s1_io_read_resp_2_0_raw_data |= bda_g_io_read_resp_2_0_raw_data;
        bda_s0_io_read_resp_2_0_raw_data |= ~bda_g_io_read_resp_2_0_raw_data;
        checks++;
        if (bda_g_io_read_resp_2_1_raw_data !== bda_i_io_read_resp_2_1_raw_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_resp_2_1_raw_data g=%h i=%h", cyc, bda_g_io_read_resp_2_1_raw_data, bda_i_io_read_resp_2_1_raw_data);
        end
        bda_s1_io_read_resp_2_1_raw_data |= bda_g_io_read_resp_2_1_raw_data;
        bda_s0_io_read_resp_2_1_raw_data |= ~bda_g_io_read_resp_2_1_raw_data;
        checks++;
        if (bda_g_io_read_error_delayed_0_0 !== bda_i_io_read_error_delayed_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_error_delayed_0_0 g=%h i=%h", cyc, bda_g_io_read_error_delayed_0_0, bda_i_io_read_error_delayed_0_0);
        end
        bda_s1_io_read_error_delayed_0_0 |= bda_g_io_read_error_delayed_0_0;
        bda_s0_io_read_error_delayed_0_0 |= ~bda_g_io_read_error_delayed_0_0;
        checks++;
        if (bda_g_io_read_error_delayed_0_1 !== bda_i_io_read_error_delayed_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_error_delayed_0_1 g=%h i=%h", cyc, bda_g_io_read_error_delayed_0_1, bda_i_io_read_error_delayed_0_1);
        end
        bda_s1_io_read_error_delayed_0_1 |= bda_g_io_read_error_delayed_0_1;
        bda_s0_io_read_error_delayed_0_1 |= ~bda_g_io_read_error_delayed_0_1;
        checks++;
        if (bda_g_io_read_error_delayed_1_0 !== bda_i_io_read_error_delayed_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_error_delayed_1_0 g=%h i=%h", cyc, bda_g_io_read_error_delayed_1_0, bda_i_io_read_error_delayed_1_0);
        end
        bda_s1_io_read_error_delayed_1_0 |= bda_g_io_read_error_delayed_1_0;
        bda_s0_io_read_error_delayed_1_0 |= ~bda_g_io_read_error_delayed_1_0;
        checks++;
        if (bda_g_io_read_error_delayed_1_1 !== bda_i_io_read_error_delayed_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_error_delayed_1_1 g=%h i=%h", cyc, bda_g_io_read_error_delayed_1_1, bda_i_io_read_error_delayed_1_1);
        end
        bda_s1_io_read_error_delayed_1_1 |= bda_g_io_read_error_delayed_1_1;
        bda_s0_io_read_error_delayed_1_1 |= ~bda_g_io_read_error_delayed_1_1;
        checks++;
        if (bda_g_io_read_error_delayed_2_0 !== bda_i_io_read_error_delayed_2_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_error_delayed_2_0 g=%h i=%h", cyc, bda_g_io_read_error_delayed_2_0, bda_i_io_read_error_delayed_2_0);
        end
        bda_s1_io_read_error_delayed_2_0 |= bda_g_io_read_error_delayed_2_0;
        bda_s0_io_read_error_delayed_2_0 |= ~bda_g_io_read_error_delayed_2_0;
        checks++;
        if (bda_g_io_read_error_delayed_2_1 !== bda_i_io_read_error_delayed_2_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_read_error_delayed_2_1 g=%h i=%h", cyc, bda_g_io_read_error_delayed_2_1, bda_i_io_read_error_delayed_2_1);
        end
        bda_s1_io_read_error_delayed_2_1 |= bda_g_io_read_error_delayed_2_1;
        bda_s0_io_read_error_delayed_2_1 |= ~bda_g_io_read_error_delayed_2_1;
        checks++;
        if (bda_g_io_bank_conflict_slow_0 !== bda_i_io_bank_conflict_slow_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_bank_conflict_slow_0 g=%h i=%h", cyc, bda_g_io_bank_conflict_slow_0, bda_i_io_bank_conflict_slow_0);
        end
        bda_s1_io_bank_conflict_slow_0 |= bda_g_io_bank_conflict_slow_0;
        bda_s0_io_bank_conflict_slow_0 |= ~bda_g_io_bank_conflict_slow_0;
        checks++;
        if (bda_g_io_bank_conflict_slow_1 !== bda_i_io_bank_conflict_slow_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_bank_conflict_slow_1 g=%h i=%h", cyc, bda_g_io_bank_conflict_slow_1, bda_i_io_bank_conflict_slow_1);
        end
        bda_s1_io_bank_conflict_slow_1 |= bda_g_io_bank_conflict_slow_1;
        bda_s0_io_bank_conflict_slow_1 |= ~bda_g_io_bank_conflict_slow_1;
        checks++;
        if (bda_g_io_bank_conflict_slow_2 !== bda_i_io_bank_conflict_slow_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_bank_conflict_slow_2 g=%h i=%h", cyc, bda_g_io_bank_conflict_slow_2, bda_i_io_bank_conflict_slow_2);
        end
        bda_s1_io_bank_conflict_slow_2 |= bda_g_io_bank_conflict_slow_2;
        bda_s0_io_bank_conflict_slow_2 |= ~bda_g_io_bank_conflict_slow_2;
        checks++;
        if (bda_g_io_disable_ld_fast_wakeup_0 !== bda_i_io_disable_ld_fast_wakeup_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_disable_ld_fast_wakeup_0 g=%h i=%h", cyc, bda_g_io_disable_ld_fast_wakeup_0, bda_i_io_disable_ld_fast_wakeup_0);
        end
        bda_s1_io_disable_ld_fast_wakeup_0 |= bda_g_io_disable_ld_fast_wakeup_0;
        bda_s0_io_disable_ld_fast_wakeup_0 |= ~bda_g_io_disable_ld_fast_wakeup_0;
        checks++;
        if (bda_g_io_disable_ld_fast_wakeup_1 !== bda_i_io_disable_ld_fast_wakeup_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_disable_ld_fast_wakeup_1 g=%h i=%h", cyc, bda_g_io_disable_ld_fast_wakeup_1, bda_i_io_disable_ld_fast_wakeup_1);
        end
        bda_s1_io_disable_ld_fast_wakeup_1 |= bda_g_io_disable_ld_fast_wakeup_1;
        bda_s0_io_disable_ld_fast_wakeup_1 |= ~bda_g_io_disable_ld_fast_wakeup_1;
        checks++;
        if (bda_g_io_disable_ld_fast_wakeup_2 !== bda_i_io_disable_ld_fast_wakeup_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_disable_ld_fast_wakeup_2 g=%h i=%h", cyc, bda_g_io_disable_ld_fast_wakeup_2, bda_i_io_disable_ld_fast_wakeup_2);
        end
        bda_s1_io_disable_ld_fast_wakeup_2 |= bda_g_io_disable_ld_fast_wakeup_2;
        bda_s0_io_disable_ld_fast_wakeup_2 |= ~bda_g_io_disable_ld_fast_wakeup_2;
        checks++;
        if (bda_g_io_pseudo_error_ready !== bda_i_io_pseudo_error_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.io_pseudo_error_ready g=%h i=%h", cyc, bda_g_io_pseudo_error_ready, bda_i_io_pseudo_error_ready);
        end
        bda_s1_io_pseudo_error_ready |= bda_g_io_pseudo_error_ready;
        bda_s0_io_pseudo_error_ready |= ~bda_g_io_pseudo_error_ready;
        checks++;
        if (bda_g_boreChildrenBd_bore_ack !== bda_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.boreChildrenBd_bore_ack g=%h i=%h", cyc, bda_g_boreChildrenBd_bore_ack, bda_i_boreChildrenBd_bore_ack);
        end
        bda_s1_boreChildrenBd_bore_ack |= bda_g_boreChildrenBd_bore_ack;
        bda_s0_boreChildrenBd_bore_ack |= ~bda_g_boreChildrenBd_bore_ack;
        checks++;
        if (bda_g_boreChildrenBd_bore_outdata !== bda_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d BankedDataArray.boreChildrenBd_bore_outdata g=%h i=%h", cyc, bda_g_boreChildrenBd_bore_outdata, bda_i_boreChildrenBd_bore_outdata);
        end
        bda_s1_boreChildrenBd_bore_outdata |= bda_g_boreChildrenBd_bore_outdata;
        bda_s0_boreChildrenBd_bore_outdata |= ~bda_g_boreChildrenBd_bore_outdata;
        if (bda_u_gold.rr_bank_conflict_0_1_probe || bda_u_gold.rr_bank_conflict_1_2_probe) bda_cov_rr_conflict++;
        if (bda_u_gold.rr_bank_conflict_oldest_0 || bda_u_gold.rr_bank_conflict_oldest_1 || bda_u_gold.rr_bank_conflict_oldest_2) bda_cov_rr_oldest_kill++;
        if (bda_u_gold.wr_bank_conflict_0_probe || bda_u_gold.wr_bank_conflict_2_probe) bda_cov_wr_conflict++;
        if (bda_u_gold.rrl_bank_conflict_1_probe) bda_cov_rrl_conflict++;
        if (bda_io_readline_valid && !bda_g_io_readline_ready) bda_cov_readline_blocked++;
        if (bda_g_io_read_error_delayed_0_0 || bda_g_io_read_error_delayed_1_1 || bda_g_io_read_error_delayed_2_0) bda_cov_read_err++;
        if (bda_g_io_readline_error_delayed) bda_cov_readline_err++;
        if (bda_g_io_pseudo_error_ready) bda_cov_pseudo_ready++;
        if (bda_u_gold._mbistPl_mbist_ack) bda_cov_mbist_ack++;
        if (bda_io_read_0_valid && bda_io_is128Req_0 && bda_g_io_read_0_ready) bda_cov_is128_read++;
      end
      if (cyc >= 310) bda_armed[0] = 1'b1;
      if (bda_io_read_0_valid && bda_g_io_read_0_ready) bda_armed[1] = 1'b1;
      if (bda_io_read_1_valid && bda_g_io_read_1_ready) bda_armed[2] = 1'b1;
      if (bda_io_read_2_valid && bda_g_io_read_2_ready) bda_armed[3] = 1'b1;
      if (bda_armed_at < 0 && (&bda_armed)) bda_armed_at = cyc + 1 + 3;
    end

    // ---- 覆盖闸 ----
    if (!(bda_s0_io_read_0_ready && bda_s1_io_read_0_ready)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_0_ready 未见过 0 和 1"); end
    if (!(bda_s0_io_read_1_ready && bda_s1_io_read_1_ready)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_1_ready 未见过 0 和 1"); end
    if (!(bda_s0_io_read_2_ready && bda_s1_io_read_2_ready)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_2_ready 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_ready && bda_s1_io_readline_ready)) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_ready 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[0] && bda_s1_io_readline_resp_0_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[1] && bda_s1_io_readline_resp_0_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[2] && bda_s1_io_readline_resp_0_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[3] && bda_s1_io_readline_resp_0_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[4] && bda_s1_io_readline_resp_0_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[5] && bda_s1_io_readline_resp_0_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[6] && bda_s1_io_readline_resp_0_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[7] && bda_s1_io_readline_resp_0_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[8] && bda_s1_io_readline_resp_0_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[9] && bda_s1_io_readline_resp_0_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[10] && bda_s1_io_readline_resp_0_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[11] && bda_s1_io_readline_resp_0_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[12] && bda_s1_io_readline_resp_0_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[13] && bda_s1_io_readline_resp_0_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[14] && bda_s1_io_readline_resp_0_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[15] && bda_s1_io_readline_resp_0_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[16] && bda_s1_io_readline_resp_0_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[17] && bda_s1_io_readline_resp_0_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[18] && bda_s1_io_readline_resp_0_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[19] && bda_s1_io_readline_resp_0_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[20] && bda_s1_io_readline_resp_0_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[21] && bda_s1_io_readline_resp_0_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[22] && bda_s1_io_readline_resp_0_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[23] && bda_s1_io_readline_resp_0_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[24] && bda_s1_io_readline_resp_0_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[25] && bda_s1_io_readline_resp_0_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[26] && bda_s1_io_readline_resp_0_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[27] && bda_s1_io_readline_resp_0_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[28] && bda_s1_io_readline_resp_0_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[29] && bda_s1_io_readline_resp_0_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[30] && bda_s1_io_readline_resp_0_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[31] && bda_s1_io_readline_resp_0_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[32] && bda_s1_io_readline_resp_0_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[33] && bda_s1_io_readline_resp_0_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[34] && bda_s1_io_readline_resp_0_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[35] && bda_s1_io_readline_resp_0_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[36] && bda_s1_io_readline_resp_0_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[37] && bda_s1_io_readline_resp_0_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[38] && bda_s1_io_readline_resp_0_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[39] && bda_s1_io_readline_resp_0_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[40] && bda_s1_io_readline_resp_0_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[41] && bda_s1_io_readline_resp_0_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[42] && bda_s1_io_readline_resp_0_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[43] && bda_s1_io_readline_resp_0_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[44] && bda_s1_io_readline_resp_0_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[45] && bda_s1_io_readline_resp_0_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[46] && bda_s1_io_readline_resp_0_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[47] && bda_s1_io_readline_resp_0_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[48] && bda_s1_io_readline_resp_0_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[49] && bda_s1_io_readline_resp_0_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[50] && bda_s1_io_readline_resp_0_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[51] && bda_s1_io_readline_resp_0_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[52] && bda_s1_io_readline_resp_0_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[53] && bda_s1_io_readline_resp_0_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[54] && bda_s1_io_readline_resp_0_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[55] && bda_s1_io_readline_resp_0_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[56] && bda_s1_io_readline_resp_0_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[57] && bda_s1_io_readline_resp_0_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[58] && bda_s1_io_readline_resp_0_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[59] && bda_s1_io_readline_resp_0_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[60] && bda_s1_io_readline_resp_0_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[61] && bda_s1_io_readline_resp_0_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[62] && bda_s1_io_readline_resp_0_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_0_raw_data[63] && bda_s1_io_readline_resp_0_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_0_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[0] && bda_s1_io_readline_resp_1_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[1] && bda_s1_io_readline_resp_1_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[2] && bda_s1_io_readline_resp_1_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[3] && bda_s1_io_readline_resp_1_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[4] && bda_s1_io_readline_resp_1_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[5] && bda_s1_io_readline_resp_1_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[6] && bda_s1_io_readline_resp_1_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[7] && bda_s1_io_readline_resp_1_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[8] && bda_s1_io_readline_resp_1_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[9] && bda_s1_io_readline_resp_1_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[10] && bda_s1_io_readline_resp_1_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[11] && bda_s1_io_readline_resp_1_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[12] && bda_s1_io_readline_resp_1_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[13] && bda_s1_io_readline_resp_1_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[14] && bda_s1_io_readline_resp_1_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[15] && bda_s1_io_readline_resp_1_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[16] && bda_s1_io_readline_resp_1_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[17] && bda_s1_io_readline_resp_1_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[18] && bda_s1_io_readline_resp_1_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[19] && bda_s1_io_readline_resp_1_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[20] && bda_s1_io_readline_resp_1_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[21] && bda_s1_io_readline_resp_1_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[22] && bda_s1_io_readline_resp_1_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[23] && bda_s1_io_readline_resp_1_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[24] && bda_s1_io_readline_resp_1_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[25] && bda_s1_io_readline_resp_1_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[26] && bda_s1_io_readline_resp_1_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[27] && bda_s1_io_readline_resp_1_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[28] && bda_s1_io_readline_resp_1_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[29] && bda_s1_io_readline_resp_1_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[30] && bda_s1_io_readline_resp_1_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[31] && bda_s1_io_readline_resp_1_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[32] && bda_s1_io_readline_resp_1_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[33] && bda_s1_io_readline_resp_1_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[34] && bda_s1_io_readline_resp_1_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[35] && bda_s1_io_readline_resp_1_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[36] && bda_s1_io_readline_resp_1_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[37] && bda_s1_io_readline_resp_1_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[38] && bda_s1_io_readline_resp_1_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[39] && bda_s1_io_readline_resp_1_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[40] && bda_s1_io_readline_resp_1_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[41] && bda_s1_io_readline_resp_1_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[42] && bda_s1_io_readline_resp_1_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[43] && bda_s1_io_readline_resp_1_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[44] && bda_s1_io_readline_resp_1_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[45] && bda_s1_io_readline_resp_1_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[46] && bda_s1_io_readline_resp_1_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[47] && bda_s1_io_readline_resp_1_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[48] && bda_s1_io_readline_resp_1_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[49] && bda_s1_io_readline_resp_1_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[50] && bda_s1_io_readline_resp_1_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[51] && bda_s1_io_readline_resp_1_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[52] && bda_s1_io_readline_resp_1_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[53] && bda_s1_io_readline_resp_1_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[54] && bda_s1_io_readline_resp_1_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[55] && bda_s1_io_readline_resp_1_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[56] && bda_s1_io_readline_resp_1_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[57] && bda_s1_io_readline_resp_1_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[58] && bda_s1_io_readline_resp_1_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[59] && bda_s1_io_readline_resp_1_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[60] && bda_s1_io_readline_resp_1_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[61] && bda_s1_io_readline_resp_1_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[62] && bda_s1_io_readline_resp_1_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_1_raw_data[63] && bda_s1_io_readline_resp_1_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_1_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[0] && bda_s1_io_readline_resp_2_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[1] && bda_s1_io_readline_resp_2_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[2] && bda_s1_io_readline_resp_2_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[3] && bda_s1_io_readline_resp_2_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[4] && bda_s1_io_readline_resp_2_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[5] && bda_s1_io_readline_resp_2_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[6] && bda_s1_io_readline_resp_2_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[7] && bda_s1_io_readline_resp_2_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[8] && bda_s1_io_readline_resp_2_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[9] && bda_s1_io_readline_resp_2_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[10] && bda_s1_io_readline_resp_2_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[11] && bda_s1_io_readline_resp_2_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[12] && bda_s1_io_readline_resp_2_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[13] && bda_s1_io_readline_resp_2_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[14] && bda_s1_io_readline_resp_2_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[15] && bda_s1_io_readline_resp_2_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[16] && bda_s1_io_readline_resp_2_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[17] && bda_s1_io_readline_resp_2_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[18] && bda_s1_io_readline_resp_2_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[19] && bda_s1_io_readline_resp_2_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[20] && bda_s1_io_readline_resp_2_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[21] && bda_s1_io_readline_resp_2_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[22] && bda_s1_io_readline_resp_2_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[23] && bda_s1_io_readline_resp_2_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[24] && bda_s1_io_readline_resp_2_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[25] && bda_s1_io_readline_resp_2_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[26] && bda_s1_io_readline_resp_2_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[27] && bda_s1_io_readline_resp_2_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[28] && bda_s1_io_readline_resp_2_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[29] && bda_s1_io_readline_resp_2_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[30] && bda_s1_io_readline_resp_2_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[31] && bda_s1_io_readline_resp_2_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[32] && bda_s1_io_readline_resp_2_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[33] && bda_s1_io_readline_resp_2_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[34] && bda_s1_io_readline_resp_2_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[35] && bda_s1_io_readline_resp_2_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[36] && bda_s1_io_readline_resp_2_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[37] && bda_s1_io_readline_resp_2_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[38] && bda_s1_io_readline_resp_2_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[39] && bda_s1_io_readline_resp_2_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[40] && bda_s1_io_readline_resp_2_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[41] && bda_s1_io_readline_resp_2_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[42] && bda_s1_io_readline_resp_2_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[43] && bda_s1_io_readline_resp_2_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[44] && bda_s1_io_readline_resp_2_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[45] && bda_s1_io_readline_resp_2_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[46] && bda_s1_io_readline_resp_2_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[47] && bda_s1_io_readline_resp_2_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[48] && bda_s1_io_readline_resp_2_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[49] && bda_s1_io_readline_resp_2_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[50] && bda_s1_io_readline_resp_2_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[51] && bda_s1_io_readline_resp_2_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[52] && bda_s1_io_readline_resp_2_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[53] && bda_s1_io_readline_resp_2_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[54] && bda_s1_io_readline_resp_2_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[55] && bda_s1_io_readline_resp_2_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[56] && bda_s1_io_readline_resp_2_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[57] && bda_s1_io_readline_resp_2_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[58] && bda_s1_io_readline_resp_2_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[59] && bda_s1_io_readline_resp_2_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[60] && bda_s1_io_readline_resp_2_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[61] && bda_s1_io_readline_resp_2_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[62] && bda_s1_io_readline_resp_2_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_2_raw_data[63] && bda_s1_io_readline_resp_2_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_2_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[0] && bda_s1_io_readline_resp_3_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[1] && bda_s1_io_readline_resp_3_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[2] && bda_s1_io_readline_resp_3_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[3] && bda_s1_io_readline_resp_3_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[4] && bda_s1_io_readline_resp_3_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[5] && bda_s1_io_readline_resp_3_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[6] && bda_s1_io_readline_resp_3_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[7] && bda_s1_io_readline_resp_3_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[8] && bda_s1_io_readline_resp_3_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[9] && bda_s1_io_readline_resp_3_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[10] && bda_s1_io_readline_resp_3_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[11] && bda_s1_io_readline_resp_3_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[12] && bda_s1_io_readline_resp_3_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[13] && bda_s1_io_readline_resp_3_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[14] && bda_s1_io_readline_resp_3_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[15] && bda_s1_io_readline_resp_3_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[16] && bda_s1_io_readline_resp_3_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[17] && bda_s1_io_readline_resp_3_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[18] && bda_s1_io_readline_resp_3_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[19] && bda_s1_io_readline_resp_3_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[20] && bda_s1_io_readline_resp_3_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[21] && bda_s1_io_readline_resp_3_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[22] && bda_s1_io_readline_resp_3_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[23] && bda_s1_io_readline_resp_3_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[24] && bda_s1_io_readline_resp_3_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[25] && bda_s1_io_readline_resp_3_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[26] && bda_s1_io_readline_resp_3_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[27] && bda_s1_io_readline_resp_3_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[28] && bda_s1_io_readline_resp_3_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[29] && bda_s1_io_readline_resp_3_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[30] && bda_s1_io_readline_resp_3_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[31] && bda_s1_io_readline_resp_3_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[32] && bda_s1_io_readline_resp_3_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[33] && bda_s1_io_readline_resp_3_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[34] && bda_s1_io_readline_resp_3_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[35] && bda_s1_io_readline_resp_3_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[36] && bda_s1_io_readline_resp_3_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[37] && bda_s1_io_readline_resp_3_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[38] && bda_s1_io_readline_resp_3_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[39] && bda_s1_io_readline_resp_3_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[40] && bda_s1_io_readline_resp_3_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[41] && bda_s1_io_readline_resp_3_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[42] && bda_s1_io_readline_resp_3_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[43] && bda_s1_io_readline_resp_3_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[44] && bda_s1_io_readline_resp_3_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[45] && bda_s1_io_readline_resp_3_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[46] && bda_s1_io_readline_resp_3_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[47] && bda_s1_io_readline_resp_3_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[48] && bda_s1_io_readline_resp_3_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[49] && bda_s1_io_readline_resp_3_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[50] && bda_s1_io_readline_resp_3_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[51] && bda_s1_io_readline_resp_3_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[52] && bda_s1_io_readline_resp_3_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[53] && bda_s1_io_readline_resp_3_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[54] && bda_s1_io_readline_resp_3_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[55] && bda_s1_io_readline_resp_3_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[56] && bda_s1_io_readline_resp_3_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[57] && bda_s1_io_readline_resp_3_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[58] && bda_s1_io_readline_resp_3_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[59] && bda_s1_io_readline_resp_3_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[60] && bda_s1_io_readline_resp_3_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[61] && bda_s1_io_readline_resp_3_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[62] && bda_s1_io_readline_resp_3_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_3_raw_data[63] && bda_s1_io_readline_resp_3_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_3_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[0] && bda_s1_io_readline_resp_4_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[1] && bda_s1_io_readline_resp_4_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[2] && bda_s1_io_readline_resp_4_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[3] && bda_s1_io_readline_resp_4_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[4] && bda_s1_io_readline_resp_4_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[5] && bda_s1_io_readline_resp_4_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[6] && bda_s1_io_readline_resp_4_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[7] && bda_s1_io_readline_resp_4_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[8] && bda_s1_io_readline_resp_4_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[9] && bda_s1_io_readline_resp_4_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[10] && bda_s1_io_readline_resp_4_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[11] && bda_s1_io_readline_resp_4_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[12] && bda_s1_io_readline_resp_4_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[13] && bda_s1_io_readline_resp_4_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[14] && bda_s1_io_readline_resp_4_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[15] && bda_s1_io_readline_resp_4_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[16] && bda_s1_io_readline_resp_4_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[17] && bda_s1_io_readline_resp_4_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[18] && bda_s1_io_readline_resp_4_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[19] && bda_s1_io_readline_resp_4_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[20] && bda_s1_io_readline_resp_4_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[21] && bda_s1_io_readline_resp_4_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[22] && bda_s1_io_readline_resp_4_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[23] && bda_s1_io_readline_resp_4_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[24] && bda_s1_io_readline_resp_4_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[25] && bda_s1_io_readline_resp_4_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[26] && bda_s1_io_readline_resp_4_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[27] && bda_s1_io_readline_resp_4_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[28] && bda_s1_io_readline_resp_4_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[29] && bda_s1_io_readline_resp_4_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[30] && bda_s1_io_readline_resp_4_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[31] && bda_s1_io_readline_resp_4_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[32] && bda_s1_io_readline_resp_4_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[33] && bda_s1_io_readline_resp_4_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[34] && bda_s1_io_readline_resp_4_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[35] && bda_s1_io_readline_resp_4_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[36] && bda_s1_io_readline_resp_4_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[37] && bda_s1_io_readline_resp_4_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[38] && bda_s1_io_readline_resp_4_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[39] && bda_s1_io_readline_resp_4_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[40] && bda_s1_io_readline_resp_4_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[41] && bda_s1_io_readline_resp_4_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[42] && bda_s1_io_readline_resp_4_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[43] && bda_s1_io_readline_resp_4_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[44] && bda_s1_io_readline_resp_4_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[45] && bda_s1_io_readline_resp_4_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[46] && bda_s1_io_readline_resp_4_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[47] && bda_s1_io_readline_resp_4_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[48] && bda_s1_io_readline_resp_4_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[49] && bda_s1_io_readline_resp_4_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[50] && bda_s1_io_readline_resp_4_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[51] && bda_s1_io_readline_resp_4_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[52] && bda_s1_io_readline_resp_4_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[53] && bda_s1_io_readline_resp_4_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[54] && bda_s1_io_readline_resp_4_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[55] && bda_s1_io_readline_resp_4_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[56] && bda_s1_io_readline_resp_4_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[57] && bda_s1_io_readline_resp_4_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[58] && bda_s1_io_readline_resp_4_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[59] && bda_s1_io_readline_resp_4_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[60] && bda_s1_io_readline_resp_4_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[61] && bda_s1_io_readline_resp_4_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[62] && bda_s1_io_readline_resp_4_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_4_raw_data[63] && bda_s1_io_readline_resp_4_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_4_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[0] && bda_s1_io_readline_resp_5_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[1] && bda_s1_io_readline_resp_5_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[2] && bda_s1_io_readline_resp_5_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[3] && bda_s1_io_readline_resp_5_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[4] && bda_s1_io_readline_resp_5_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[5] && bda_s1_io_readline_resp_5_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[6] && bda_s1_io_readline_resp_5_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[7] && bda_s1_io_readline_resp_5_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[8] && bda_s1_io_readline_resp_5_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[9] && bda_s1_io_readline_resp_5_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[10] && bda_s1_io_readline_resp_5_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[11] && bda_s1_io_readline_resp_5_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[12] && bda_s1_io_readline_resp_5_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[13] && bda_s1_io_readline_resp_5_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[14] && bda_s1_io_readline_resp_5_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[15] && bda_s1_io_readline_resp_5_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[16] && bda_s1_io_readline_resp_5_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[17] && bda_s1_io_readline_resp_5_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[18] && bda_s1_io_readline_resp_5_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[19] && bda_s1_io_readline_resp_5_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[20] && bda_s1_io_readline_resp_5_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[21] && bda_s1_io_readline_resp_5_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[22] && bda_s1_io_readline_resp_5_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[23] && bda_s1_io_readline_resp_5_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[24] && bda_s1_io_readline_resp_5_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[25] && bda_s1_io_readline_resp_5_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[26] && bda_s1_io_readline_resp_5_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[27] && bda_s1_io_readline_resp_5_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[28] && bda_s1_io_readline_resp_5_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[29] && bda_s1_io_readline_resp_5_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[30] && bda_s1_io_readline_resp_5_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[31] && bda_s1_io_readline_resp_5_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[32] && bda_s1_io_readline_resp_5_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[33] && bda_s1_io_readline_resp_5_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[34] && bda_s1_io_readline_resp_5_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[35] && bda_s1_io_readline_resp_5_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[36] && bda_s1_io_readline_resp_5_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[37] && bda_s1_io_readline_resp_5_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[38] && bda_s1_io_readline_resp_5_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[39] && bda_s1_io_readline_resp_5_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[40] && bda_s1_io_readline_resp_5_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[41] && bda_s1_io_readline_resp_5_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[42] && bda_s1_io_readline_resp_5_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[43] && bda_s1_io_readline_resp_5_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[44] && bda_s1_io_readline_resp_5_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[45] && bda_s1_io_readline_resp_5_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[46] && bda_s1_io_readline_resp_5_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[47] && bda_s1_io_readline_resp_5_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[48] && bda_s1_io_readline_resp_5_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[49] && bda_s1_io_readline_resp_5_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[50] && bda_s1_io_readline_resp_5_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[51] && bda_s1_io_readline_resp_5_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[52] && bda_s1_io_readline_resp_5_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[53] && bda_s1_io_readline_resp_5_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[54] && bda_s1_io_readline_resp_5_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[55] && bda_s1_io_readline_resp_5_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[56] && bda_s1_io_readline_resp_5_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[57] && bda_s1_io_readline_resp_5_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[58] && bda_s1_io_readline_resp_5_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[59] && bda_s1_io_readline_resp_5_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[60] && bda_s1_io_readline_resp_5_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[61] && bda_s1_io_readline_resp_5_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[62] && bda_s1_io_readline_resp_5_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_5_raw_data[63] && bda_s1_io_readline_resp_5_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_5_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[0] && bda_s1_io_readline_resp_6_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[1] && bda_s1_io_readline_resp_6_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[2] && bda_s1_io_readline_resp_6_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[3] && bda_s1_io_readline_resp_6_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[4] && bda_s1_io_readline_resp_6_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[5] && bda_s1_io_readline_resp_6_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[6] && bda_s1_io_readline_resp_6_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[7] && bda_s1_io_readline_resp_6_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[8] && bda_s1_io_readline_resp_6_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[9] && bda_s1_io_readline_resp_6_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[10] && bda_s1_io_readline_resp_6_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[11] && bda_s1_io_readline_resp_6_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[12] && bda_s1_io_readline_resp_6_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[13] && bda_s1_io_readline_resp_6_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[14] && bda_s1_io_readline_resp_6_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[15] && bda_s1_io_readline_resp_6_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[16] && bda_s1_io_readline_resp_6_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[17] && bda_s1_io_readline_resp_6_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[18] && bda_s1_io_readline_resp_6_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[19] && bda_s1_io_readline_resp_6_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[20] && bda_s1_io_readline_resp_6_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[21] && bda_s1_io_readline_resp_6_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[22] && bda_s1_io_readline_resp_6_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[23] && bda_s1_io_readline_resp_6_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[24] && bda_s1_io_readline_resp_6_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[25] && bda_s1_io_readline_resp_6_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[26] && bda_s1_io_readline_resp_6_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[27] && bda_s1_io_readline_resp_6_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[28] && bda_s1_io_readline_resp_6_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[29] && bda_s1_io_readline_resp_6_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[30] && bda_s1_io_readline_resp_6_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[31] && bda_s1_io_readline_resp_6_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[32] && bda_s1_io_readline_resp_6_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[33] && bda_s1_io_readline_resp_6_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[34] && bda_s1_io_readline_resp_6_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[35] && bda_s1_io_readline_resp_6_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[36] && bda_s1_io_readline_resp_6_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[37] && bda_s1_io_readline_resp_6_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[38] && bda_s1_io_readline_resp_6_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[39] && bda_s1_io_readline_resp_6_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[40] && bda_s1_io_readline_resp_6_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[41] && bda_s1_io_readline_resp_6_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[42] && bda_s1_io_readline_resp_6_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[43] && bda_s1_io_readline_resp_6_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[44] && bda_s1_io_readline_resp_6_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[45] && bda_s1_io_readline_resp_6_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[46] && bda_s1_io_readline_resp_6_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[47] && bda_s1_io_readline_resp_6_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[48] && bda_s1_io_readline_resp_6_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[49] && bda_s1_io_readline_resp_6_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[50] && bda_s1_io_readline_resp_6_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[51] && bda_s1_io_readline_resp_6_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[52] && bda_s1_io_readline_resp_6_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[53] && bda_s1_io_readline_resp_6_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[54] && bda_s1_io_readline_resp_6_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[55] && bda_s1_io_readline_resp_6_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[56] && bda_s1_io_readline_resp_6_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[57] && bda_s1_io_readline_resp_6_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[58] && bda_s1_io_readline_resp_6_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[59] && bda_s1_io_readline_resp_6_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[60] && bda_s1_io_readline_resp_6_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[61] && bda_s1_io_readline_resp_6_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[62] && bda_s1_io_readline_resp_6_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_6_raw_data[63] && bda_s1_io_readline_resp_6_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_6_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[0] && bda_s1_io_readline_resp_7_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[1] && bda_s1_io_readline_resp_7_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[2] && bda_s1_io_readline_resp_7_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[3] && bda_s1_io_readline_resp_7_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[4] && bda_s1_io_readline_resp_7_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[5] && bda_s1_io_readline_resp_7_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[6] && bda_s1_io_readline_resp_7_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[7] && bda_s1_io_readline_resp_7_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[8] && bda_s1_io_readline_resp_7_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[9] && bda_s1_io_readline_resp_7_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[10] && bda_s1_io_readline_resp_7_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[11] && bda_s1_io_readline_resp_7_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[12] && bda_s1_io_readline_resp_7_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[13] && bda_s1_io_readline_resp_7_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[14] && bda_s1_io_readline_resp_7_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[15] && bda_s1_io_readline_resp_7_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[16] && bda_s1_io_readline_resp_7_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[17] && bda_s1_io_readline_resp_7_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[18] && bda_s1_io_readline_resp_7_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[19] && bda_s1_io_readline_resp_7_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[20] && bda_s1_io_readline_resp_7_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[21] && bda_s1_io_readline_resp_7_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[22] && bda_s1_io_readline_resp_7_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[23] && bda_s1_io_readline_resp_7_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[24] && bda_s1_io_readline_resp_7_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[25] && bda_s1_io_readline_resp_7_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[26] && bda_s1_io_readline_resp_7_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[27] && bda_s1_io_readline_resp_7_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[28] && bda_s1_io_readline_resp_7_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[29] && bda_s1_io_readline_resp_7_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[30] && bda_s1_io_readline_resp_7_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[31] && bda_s1_io_readline_resp_7_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[32] && bda_s1_io_readline_resp_7_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[33] && bda_s1_io_readline_resp_7_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[34] && bda_s1_io_readline_resp_7_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[35] && bda_s1_io_readline_resp_7_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[36] && bda_s1_io_readline_resp_7_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[37] && bda_s1_io_readline_resp_7_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[38] && bda_s1_io_readline_resp_7_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[39] && bda_s1_io_readline_resp_7_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[40] && bda_s1_io_readline_resp_7_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[41] && bda_s1_io_readline_resp_7_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[42] && bda_s1_io_readline_resp_7_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[43] && bda_s1_io_readline_resp_7_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[44] && bda_s1_io_readline_resp_7_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[45] && bda_s1_io_readline_resp_7_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[46] && bda_s1_io_readline_resp_7_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[47] && bda_s1_io_readline_resp_7_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[48] && bda_s1_io_readline_resp_7_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[49] && bda_s1_io_readline_resp_7_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[50] && bda_s1_io_readline_resp_7_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[51] && bda_s1_io_readline_resp_7_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[52] && bda_s1_io_readline_resp_7_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[53] && bda_s1_io_readline_resp_7_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[54] && bda_s1_io_readline_resp_7_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[55] && bda_s1_io_readline_resp_7_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[56] && bda_s1_io_readline_resp_7_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[57] && bda_s1_io_readline_resp_7_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[58] && bda_s1_io_readline_resp_7_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[59] && bda_s1_io_readline_resp_7_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[60] && bda_s1_io_readline_resp_7_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[61] && bda_s1_io_readline_resp_7_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[62] && bda_s1_io_readline_resp_7_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_resp_7_raw_data[63] && bda_s1_io_readline_resp_7_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_resp_7_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_readline_error_delayed && bda_s1_io_readline_error_delayed)) begin cov_fail++; $display("[COV] BankedDataArray.io_readline_error_delayed 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[0] && bda_s1_io_read_resp_0_0_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[1] && bda_s1_io_read_resp_0_0_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[2] && bda_s1_io_read_resp_0_0_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[3] && bda_s1_io_read_resp_0_0_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[4] && bda_s1_io_read_resp_0_0_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[5] && bda_s1_io_read_resp_0_0_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[6] && bda_s1_io_read_resp_0_0_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[7] && bda_s1_io_read_resp_0_0_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[8] && bda_s1_io_read_resp_0_0_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[9] && bda_s1_io_read_resp_0_0_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[10] && bda_s1_io_read_resp_0_0_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[11] && bda_s1_io_read_resp_0_0_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[12] && bda_s1_io_read_resp_0_0_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[13] && bda_s1_io_read_resp_0_0_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[14] && bda_s1_io_read_resp_0_0_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[15] && bda_s1_io_read_resp_0_0_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[16] && bda_s1_io_read_resp_0_0_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[17] && bda_s1_io_read_resp_0_0_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[18] && bda_s1_io_read_resp_0_0_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[19] && bda_s1_io_read_resp_0_0_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[20] && bda_s1_io_read_resp_0_0_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[21] && bda_s1_io_read_resp_0_0_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[22] && bda_s1_io_read_resp_0_0_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[23] && bda_s1_io_read_resp_0_0_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[24] && bda_s1_io_read_resp_0_0_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[25] && bda_s1_io_read_resp_0_0_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[26] && bda_s1_io_read_resp_0_0_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[27] && bda_s1_io_read_resp_0_0_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[28] && bda_s1_io_read_resp_0_0_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[29] && bda_s1_io_read_resp_0_0_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[30] && bda_s1_io_read_resp_0_0_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[31] && bda_s1_io_read_resp_0_0_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[32] && bda_s1_io_read_resp_0_0_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[33] && bda_s1_io_read_resp_0_0_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[34] && bda_s1_io_read_resp_0_0_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[35] && bda_s1_io_read_resp_0_0_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[36] && bda_s1_io_read_resp_0_0_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[37] && bda_s1_io_read_resp_0_0_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[38] && bda_s1_io_read_resp_0_0_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[39] && bda_s1_io_read_resp_0_0_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[40] && bda_s1_io_read_resp_0_0_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[41] && bda_s1_io_read_resp_0_0_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[42] && bda_s1_io_read_resp_0_0_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[43] && bda_s1_io_read_resp_0_0_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[44] && bda_s1_io_read_resp_0_0_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[45] && bda_s1_io_read_resp_0_0_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[46] && bda_s1_io_read_resp_0_0_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[47] && bda_s1_io_read_resp_0_0_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[48] && bda_s1_io_read_resp_0_0_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[49] && bda_s1_io_read_resp_0_0_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[50] && bda_s1_io_read_resp_0_0_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[51] && bda_s1_io_read_resp_0_0_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[52] && bda_s1_io_read_resp_0_0_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[53] && bda_s1_io_read_resp_0_0_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[54] && bda_s1_io_read_resp_0_0_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[55] && bda_s1_io_read_resp_0_0_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[56] && bda_s1_io_read_resp_0_0_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[57] && bda_s1_io_read_resp_0_0_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[58] && bda_s1_io_read_resp_0_0_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[59] && bda_s1_io_read_resp_0_0_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[60] && bda_s1_io_read_resp_0_0_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[61] && bda_s1_io_read_resp_0_0_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[62] && bda_s1_io_read_resp_0_0_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_0_raw_data[63] && bda_s1_io_read_resp_0_0_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_0_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[0] && bda_s1_io_read_resp_0_1_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[1] && bda_s1_io_read_resp_0_1_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[2] && bda_s1_io_read_resp_0_1_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[3] && bda_s1_io_read_resp_0_1_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[4] && bda_s1_io_read_resp_0_1_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[5] && bda_s1_io_read_resp_0_1_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[6] && bda_s1_io_read_resp_0_1_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[7] && bda_s1_io_read_resp_0_1_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[8] && bda_s1_io_read_resp_0_1_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[9] && bda_s1_io_read_resp_0_1_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[10] && bda_s1_io_read_resp_0_1_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[11] && bda_s1_io_read_resp_0_1_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[12] && bda_s1_io_read_resp_0_1_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[13] && bda_s1_io_read_resp_0_1_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[14] && bda_s1_io_read_resp_0_1_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[15] && bda_s1_io_read_resp_0_1_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[16] && bda_s1_io_read_resp_0_1_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[17] && bda_s1_io_read_resp_0_1_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[18] && bda_s1_io_read_resp_0_1_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[19] && bda_s1_io_read_resp_0_1_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[20] && bda_s1_io_read_resp_0_1_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[21] && bda_s1_io_read_resp_0_1_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[22] && bda_s1_io_read_resp_0_1_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[23] && bda_s1_io_read_resp_0_1_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[24] && bda_s1_io_read_resp_0_1_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[25] && bda_s1_io_read_resp_0_1_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[26] && bda_s1_io_read_resp_0_1_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[27] && bda_s1_io_read_resp_0_1_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[28] && bda_s1_io_read_resp_0_1_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[29] && bda_s1_io_read_resp_0_1_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[30] && bda_s1_io_read_resp_0_1_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[31] && bda_s1_io_read_resp_0_1_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[32] && bda_s1_io_read_resp_0_1_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[33] && bda_s1_io_read_resp_0_1_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[34] && bda_s1_io_read_resp_0_1_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[35] && bda_s1_io_read_resp_0_1_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[36] && bda_s1_io_read_resp_0_1_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[37] && bda_s1_io_read_resp_0_1_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[38] && bda_s1_io_read_resp_0_1_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[39] && bda_s1_io_read_resp_0_1_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[40] && bda_s1_io_read_resp_0_1_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[41] && bda_s1_io_read_resp_0_1_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[42] && bda_s1_io_read_resp_0_1_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[43] && bda_s1_io_read_resp_0_1_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[44] && bda_s1_io_read_resp_0_1_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[45] && bda_s1_io_read_resp_0_1_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[46] && bda_s1_io_read_resp_0_1_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[47] && bda_s1_io_read_resp_0_1_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[48] && bda_s1_io_read_resp_0_1_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[49] && bda_s1_io_read_resp_0_1_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[50] && bda_s1_io_read_resp_0_1_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[51] && bda_s1_io_read_resp_0_1_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[52] && bda_s1_io_read_resp_0_1_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[53] && bda_s1_io_read_resp_0_1_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[54] && bda_s1_io_read_resp_0_1_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[55] && bda_s1_io_read_resp_0_1_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[56] && bda_s1_io_read_resp_0_1_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[57] && bda_s1_io_read_resp_0_1_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[58] && bda_s1_io_read_resp_0_1_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[59] && bda_s1_io_read_resp_0_1_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[60] && bda_s1_io_read_resp_0_1_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[61] && bda_s1_io_read_resp_0_1_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[62] && bda_s1_io_read_resp_0_1_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_0_1_raw_data[63] && bda_s1_io_read_resp_0_1_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_0_1_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[0] && bda_s1_io_read_resp_1_0_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[1] && bda_s1_io_read_resp_1_0_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[2] && bda_s1_io_read_resp_1_0_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[3] && bda_s1_io_read_resp_1_0_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[4] && bda_s1_io_read_resp_1_0_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[5] && bda_s1_io_read_resp_1_0_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[6] && bda_s1_io_read_resp_1_0_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[7] && bda_s1_io_read_resp_1_0_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[8] && bda_s1_io_read_resp_1_0_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[9] && bda_s1_io_read_resp_1_0_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[10] && bda_s1_io_read_resp_1_0_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[11] && bda_s1_io_read_resp_1_0_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[12] && bda_s1_io_read_resp_1_0_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[13] && bda_s1_io_read_resp_1_0_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[14] && bda_s1_io_read_resp_1_0_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[15] && bda_s1_io_read_resp_1_0_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[16] && bda_s1_io_read_resp_1_0_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[17] && bda_s1_io_read_resp_1_0_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[18] && bda_s1_io_read_resp_1_0_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[19] && bda_s1_io_read_resp_1_0_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[20] && bda_s1_io_read_resp_1_0_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[21] && bda_s1_io_read_resp_1_0_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[22] && bda_s1_io_read_resp_1_0_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[23] && bda_s1_io_read_resp_1_0_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[24] && bda_s1_io_read_resp_1_0_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[25] && bda_s1_io_read_resp_1_0_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[26] && bda_s1_io_read_resp_1_0_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[27] && bda_s1_io_read_resp_1_0_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[28] && bda_s1_io_read_resp_1_0_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[29] && bda_s1_io_read_resp_1_0_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[30] && bda_s1_io_read_resp_1_0_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[31] && bda_s1_io_read_resp_1_0_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[32] && bda_s1_io_read_resp_1_0_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[33] && bda_s1_io_read_resp_1_0_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[34] && bda_s1_io_read_resp_1_0_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[35] && bda_s1_io_read_resp_1_0_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[36] && bda_s1_io_read_resp_1_0_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[37] && bda_s1_io_read_resp_1_0_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[38] && bda_s1_io_read_resp_1_0_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[39] && bda_s1_io_read_resp_1_0_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[40] && bda_s1_io_read_resp_1_0_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[41] && bda_s1_io_read_resp_1_0_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[42] && bda_s1_io_read_resp_1_0_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[43] && bda_s1_io_read_resp_1_0_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[44] && bda_s1_io_read_resp_1_0_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[45] && bda_s1_io_read_resp_1_0_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[46] && bda_s1_io_read_resp_1_0_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[47] && bda_s1_io_read_resp_1_0_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[48] && bda_s1_io_read_resp_1_0_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[49] && bda_s1_io_read_resp_1_0_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[50] && bda_s1_io_read_resp_1_0_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[51] && bda_s1_io_read_resp_1_0_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[52] && bda_s1_io_read_resp_1_0_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[53] && bda_s1_io_read_resp_1_0_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[54] && bda_s1_io_read_resp_1_0_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[55] && bda_s1_io_read_resp_1_0_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[56] && bda_s1_io_read_resp_1_0_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[57] && bda_s1_io_read_resp_1_0_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[58] && bda_s1_io_read_resp_1_0_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[59] && bda_s1_io_read_resp_1_0_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[60] && bda_s1_io_read_resp_1_0_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[61] && bda_s1_io_read_resp_1_0_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[62] && bda_s1_io_read_resp_1_0_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_0_raw_data[63] && bda_s1_io_read_resp_1_0_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_0_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[0] && bda_s1_io_read_resp_1_1_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[1] && bda_s1_io_read_resp_1_1_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[2] && bda_s1_io_read_resp_1_1_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[3] && bda_s1_io_read_resp_1_1_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[4] && bda_s1_io_read_resp_1_1_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[5] && bda_s1_io_read_resp_1_1_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[6] && bda_s1_io_read_resp_1_1_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[7] && bda_s1_io_read_resp_1_1_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[8] && bda_s1_io_read_resp_1_1_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[9] && bda_s1_io_read_resp_1_1_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[10] && bda_s1_io_read_resp_1_1_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[11] && bda_s1_io_read_resp_1_1_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[12] && bda_s1_io_read_resp_1_1_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[13] && bda_s1_io_read_resp_1_1_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[14] && bda_s1_io_read_resp_1_1_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[15] && bda_s1_io_read_resp_1_1_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[16] && bda_s1_io_read_resp_1_1_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[17] && bda_s1_io_read_resp_1_1_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[18] && bda_s1_io_read_resp_1_1_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[19] && bda_s1_io_read_resp_1_1_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[20] && bda_s1_io_read_resp_1_1_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[21] && bda_s1_io_read_resp_1_1_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[22] && bda_s1_io_read_resp_1_1_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[23] && bda_s1_io_read_resp_1_1_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[24] && bda_s1_io_read_resp_1_1_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[25] && bda_s1_io_read_resp_1_1_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[26] && bda_s1_io_read_resp_1_1_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[27] && bda_s1_io_read_resp_1_1_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[28] && bda_s1_io_read_resp_1_1_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[29] && bda_s1_io_read_resp_1_1_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[30] && bda_s1_io_read_resp_1_1_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[31] && bda_s1_io_read_resp_1_1_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[32] && bda_s1_io_read_resp_1_1_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[33] && bda_s1_io_read_resp_1_1_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[34] && bda_s1_io_read_resp_1_1_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[35] && bda_s1_io_read_resp_1_1_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[36] && bda_s1_io_read_resp_1_1_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[37] && bda_s1_io_read_resp_1_1_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[38] && bda_s1_io_read_resp_1_1_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[39] && bda_s1_io_read_resp_1_1_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[40] && bda_s1_io_read_resp_1_1_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[41] && bda_s1_io_read_resp_1_1_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[42] && bda_s1_io_read_resp_1_1_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[43] && bda_s1_io_read_resp_1_1_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[44] && bda_s1_io_read_resp_1_1_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[45] && bda_s1_io_read_resp_1_1_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[46] && bda_s1_io_read_resp_1_1_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[47] && bda_s1_io_read_resp_1_1_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[48] && bda_s1_io_read_resp_1_1_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[49] && bda_s1_io_read_resp_1_1_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[50] && bda_s1_io_read_resp_1_1_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[51] && bda_s1_io_read_resp_1_1_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[52] && bda_s1_io_read_resp_1_1_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[53] && bda_s1_io_read_resp_1_1_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[54] && bda_s1_io_read_resp_1_1_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[55] && bda_s1_io_read_resp_1_1_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[56] && bda_s1_io_read_resp_1_1_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[57] && bda_s1_io_read_resp_1_1_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[58] && bda_s1_io_read_resp_1_1_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[59] && bda_s1_io_read_resp_1_1_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[60] && bda_s1_io_read_resp_1_1_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[61] && bda_s1_io_read_resp_1_1_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[62] && bda_s1_io_read_resp_1_1_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_1_1_raw_data[63] && bda_s1_io_read_resp_1_1_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_1_1_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[0] && bda_s1_io_read_resp_2_0_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[1] && bda_s1_io_read_resp_2_0_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[2] && bda_s1_io_read_resp_2_0_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[3] && bda_s1_io_read_resp_2_0_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[4] && bda_s1_io_read_resp_2_0_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[5] && bda_s1_io_read_resp_2_0_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[6] && bda_s1_io_read_resp_2_0_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[7] && bda_s1_io_read_resp_2_0_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[8] && bda_s1_io_read_resp_2_0_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[9] && bda_s1_io_read_resp_2_0_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[10] && bda_s1_io_read_resp_2_0_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[11] && bda_s1_io_read_resp_2_0_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[12] && bda_s1_io_read_resp_2_0_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[13] && bda_s1_io_read_resp_2_0_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[14] && bda_s1_io_read_resp_2_0_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[15] && bda_s1_io_read_resp_2_0_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[16] && bda_s1_io_read_resp_2_0_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[17] && bda_s1_io_read_resp_2_0_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[18] && bda_s1_io_read_resp_2_0_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[19] && bda_s1_io_read_resp_2_0_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[20] && bda_s1_io_read_resp_2_0_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[21] && bda_s1_io_read_resp_2_0_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[22] && bda_s1_io_read_resp_2_0_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[23] && bda_s1_io_read_resp_2_0_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[24] && bda_s1_io_read_resp_2_0_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[25] && bda_s1_io_read_resp_2_0_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[26] && bda_s1_io_read_resp_2_0_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[27] && bda_s1_io_read_resp_2_0_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[28] && bda_s1_io_read_resp_2_0_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[29] && bda_s1_io_read_resp_2_0_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[30] && bda_s1_io_read_resp_2_0_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[31] && bda_s1_io_read_resp_2_0_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[32] && bda_s1_io_read_resp_2_0_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[33] && bda_s1_io_read_resp_2_0_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[34] && bda_s1_io_read_resp_2_0_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[35] && bda_s1_io_read_resp_2_0_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[36] && bda_s1_io_read_resp_2_0_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[37] && bda_s1_io_read_resp_2_0_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[38] && bda_s1_io_read_resp_2_0_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[39] && bda_s1_io_read_resp_2_0_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[40] && bda_s1_io_read_resp_2_0_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[41] && bda_s1_io_read_resp_2_0_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[42] && bda_s1_io_read_resp_2_0_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[43] && bda_s1_io_read_resp_2_0_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[44] && bda_s1_io_read_resp_2_0_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[45] && bda_s1_io_read_resp_2_0_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[46] && bda_s1_io_read_resp_2_0_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[47] && bda_s1_io_read_resp_2_0_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[48] && bda_s1_io_read_resp_2_0_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[49] && bda_s1_io_read_resp_2_0_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[50] && bda_s1_io_read_resp_2_0_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[51] && bda_s1_io_read_resp_2_0_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[52] && bda_s1_io_read_resp_2_0_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[53] && bda_s1_io_read_resp_2_0_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[54] && bda_s1_io_read_resp_2_0_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[55] && bda_s1_io_read_resp_2_0_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[56] && bda_s1_io_read_resp_2_0_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[57] && bda_s1_io_read_resp_2_0_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[58] && bda_s1_io_read_resp_2_0_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[59] && bda_s1_io_read_resp_2_0_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[60] && bda_s1_io_read_resp_2_0_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[61] && bda_s1_io_read_resp_2_0_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[62] && bda_s1_io_read_resp_2_0_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_0_raw_data[63] && bda_s1_io_read_resp_2_0_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_0_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[0] && bda_s1_io_read_resp_2_1_raw_data[0])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[0] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[1] && bda_s1_io_read_resp_2_1_raw_data[1])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[1] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[2] && bda_s1_io_read_resp_2_1_raw_data[2])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[2] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[3] && bda_s1_io_read_resp_2_1_raw_data[3])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[3] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[4] && bda_s1_io_read_resp_2_1_raw_data[4])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[4] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[5] && bda_s1_io_read_resp_2_1_raw_data[5])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[5] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[6] && bda_s1_io_read_resp_2_1_raw_data[6])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[6] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[7] && bda_s1_io_read_resp_2_1_raw_data[7])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[7] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[8] && bda_s1_io_read_resp_2_1_raw_data[8])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[8] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[9] && bda_s1_io_read_resp_2_1_raw_data[9])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[9] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[10] && bda_s1_io_read_resp_2_1_raw_data[10])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[10] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[11] && bda_s1_io_read_resp_2_1_raw_data[11])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[11] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[12] && bda_s1_io_read_resp_2_1_raw_data[12])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[12] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[13] && bda_s1_io_read_resp_2_1_raw_data[13])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[13] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[14] && bda_s1_io_read_resp_2_1_raw_data[14])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[14] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[15] && bda_s1_io_read_resp_2_1_raw_data[15])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[15] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[16] && bda_s1_io_read_resp_2_1_raw_data[16])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[16] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[17] && bda_s1_io_read_resp_2_1_raw_data[17])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[17] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[18] && bda_s1_io_read_resp_2_1_raw_data[18])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[18] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[19] && bda_s1_io_read_resp_2_1_raw_data[19])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[19] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[20] && bda_s1_io_read_resp_2_1_raw_data[20])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[20] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[21] && bda_s1_io_read_resp_2_1_raw_data[21])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[21] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[22] && bda_s1_io_read_resp_2_1_raw_data[22])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[22] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[23] && bda_s1_io_read_resp_2_1_raw_data[23])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[23] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[24] && bda_s1_io_read_resp_2_1_raw_data[24])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[24] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[25] && bda_s1_io_read_resp_2_1_raw_data[25])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[25] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[26] && bda_s1_io_read_resp_2_1_raw_data[26])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[26] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[27] && bda_s1_io_read_resp_2_1_raw_data[27])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[27] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[28] && bda_s1_io_read_resp_2_1_raw_data[28])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[28] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[29] && bda_s1_io_read_resp_2_1_raw_data[29])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[29] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[30] && bda_s1_io_read_resp_2_1_raw_data[30])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[30] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[31] && bda_s1_io_read_resp_2_1_raw_data[31])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[31] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[32] && bda_s1_io_read_resp_2_1_raw_data[32])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[32] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[33] && bda_s1_io_read_resp_2_1_raw_data[33])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[33] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[34] && bda_s1_io_read_resp_2_1_raw_data[34])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[34] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[35] && bda_s1_io_read_resp_2_1_raw_data[35])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[35] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[36] && bda_s1_io_read_resp_2_1_raw_data[36])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[36] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[37] && bda_s1_io_read_resp_2_1_raw_data[37])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[37] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[38] && bda_s1_io_read_resp_2_1_raw_data[38])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[38] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[39] && bda_s1_io_read_resp_2_1_raw_data[39])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[39] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[40] && bda_s1_io_read_resp_2_1_raw_data[40])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[40] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[41] && bda_s1_io_read_resp_2_1_raw_data[41])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[41] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[42] && bda_s1_io_read_resp_2_1_raw_data[42])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[42] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[43] && bda_s1_io_read_resp_2_1_raw_data[43])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[43] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[44] && bda_s1_io_read_resp_2_1_raw_data[44])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[44] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[45] && bda_s1_io_read_resp_2_1_raw_data[45])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[45] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[46] && bda_s1_io_read_resp_2_1_raw_data[46])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[46] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[47] && bda_s1_io_read_resp_2_1_raw_data[47])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[47] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[48] && bda_s1_io_read_resp_2_1_raw_data[48])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[48] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[49] && bda_s1_io_read_resp_2_1_raw_data[49])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[49] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[50] && bda_s1_io_read_resp_2_1_raw_data[50])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[50] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[51] && bda_s1_io_read_resp_2_1_raw_data[51])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[51] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[52] && bda_s1_io_read_resp_2_1_raw_data[52])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[52] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[53] && bda_s1_io_read_resp_2_1_raw_data[53])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[53] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[54] && bda_s1_io_read_resp_2_1_raw_data[54])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[54] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[55] && bda_s1_io_read_resp_2_1_raw_data[55])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[55] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[56] && bda_s1_io_read_resp_2_1_raw_data[56])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[56] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[57] && bda_s1_io_read_resp_2_1_raw_data[57])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[57] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[58] && bda_s1_io_read_resp_2_1_raw_data[58])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[58] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[59] && bda_s1_io_read_resp_2_1_raw_data[59])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[59] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[60] && bda_s1_io_read_resp_2_1_raw_data[60])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[60] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[61] && bda_s1_io_read_resp_2_1_raw_data[61])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[61] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[62] && bda_s1_io_read_resp_2_1_raw_data[62])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[62] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_resp_2_1_raw_data[63] && bda_s1_io_read_resp_2_1_raw_data[63])) begin cov_fail++; $display("[COV] BankedDataArray.io_read_resp_2_1_raw_data[63] 未见过 0 和 1"); end
    if (!(bda_s0_io_read_error_delayed_0_0 && bda_s1_io_read_error_delayed_0_0)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_error_delayed_0_0 未见过 0 和 1"); end
    if (!(bda_s0_io_read_error_delayed_0_1 && bda_s1_io_read_error_delayed_0_1)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_error_delayed_0_1 未见过 0 和 1"); end
    if (!(bda_s0_io_read_error_delayed_1_0 && bda_s1_io_read_error_delayed_1_0)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_error_delayed_1_0 未见过 0 和 1"); end
    if (!(bda_s0_io_read_error_delayed_1_1 && bda_s1_io_read_error_delayed_1_1)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_error_delayed_1_1 未见过 0 和 1"); end
    if (!(bda_s0_io_read_error_delayed_2_0 && bda_s1_io_read_error_delayed_2_0)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_error_delayed_2_0 未见过 0 和 1"); end
    if (!(bda_s0_io_read_error_delayed_2_1 && bda_s1_io_read_error_delayed_2_1)) begin cov_fail++; $display("[COV] BankedDataArray.io_read_error_delayed_2_1 未见过 0 和 1"); end
    if (!(bda_s0_io_bank_conflict_slow_0 && bda_s1_io_bank_conflict_slow_0)) begin cov_fail++; $display("[COV] BankedDataArray.io_bank_conflict_slow_0 未见过 0 和 1"); end
    if (!(bda_s0_io_bank_conflict_slow_1 && bda_s1_io_bank_conflict_slow_1)) begin cov_fail++; $display("[COV] BankedDataArray.io_bank_conflict_slow_1 未见过 0 和 1"); end
    if (!(bda_s0_io_bank_conflict_slow_2 && bda_s1_io_bank_conflict_slow_2)) begin cov_fail++; $display("[COV] BankedDataArray.io_bank_conflict_slow_2 未见过 0 和 1"); end
    if (!(bda_s0_io_disable_ld_fast_wakeup_0 && bda_s1_io_disable_ld_fast_wakeup_0)) begin cov_fail++; $display("[COV] BankedDataArray.io_disable_ld_fast_wakeup_0 未见过 0 和 1"); end
    if (!(bda_s0_io_disable_ld_fast_wakeup_1 && bda_s1_io_disable_ld_fast_wakeup_1)) begin cov_fail++; $display("[COV] BankedDataArray.io_disable_ld_fast_wakeup_1 未见过 0 和 1"); end
    if (!(bda_s0_io_disable_ld_fast_wakeup_2 && bda_s1_io_disable_ld_fast_wakeup_2)) begin cov_fail++; $display("[COV] BankedDataArray.io_disable_ld_fast_wakeup_2 未见过 0 和 1"); end
    if (!(bda_s0_io_pseudo_error_ready && bda_s1_io_pseudo_error_ready)) begin cov_fail++; $display("[COV] BankedDataArray.io_pseudo_error_ready 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_ack && bda_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[0] && bda_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[1] && bda_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[2] && bda_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[3] && bda_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[4] && bda_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[5] && bda_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[6] && bda_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[7] && bda_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[8] && bda_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[9] && bda_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[10] && bda_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[11] && bda_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[12] && bda_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[13] && bda_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[14] && bda_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[15] && bda_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[16] && bda_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[17] && bda_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[18] && bda_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[19] && bda_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[20] && bda_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[21] && bda_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[22] && bda_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[23] && bda_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[24] && bda_s1_boreChildrenBd_bore_outdata[24])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[24] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[25] && bda_s1_boreChildrenBd_bore_outdata[25])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[25] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[26] && bda_s1_boreChildrenBd_bore_outdata[26])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[26] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[27] && bda_s1_boreChildrenBd_bore_outdata[27])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[27] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[28] && bda_s1_boreChildrenBd_bore_outdata[28])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[28] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[29] && bda_s1_boreChildrenBd_bore_outdata[29])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[29] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[30] && bda_s1_boreChildrenBd_bore_outdata[30])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[30] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[31] && bda_s1_boreChildrenBd_bore_outdata[31])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[31] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[32] && bda_s1_boreChildrenBd_bore_outdata[32])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[32] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[33] && bda_s1_boreChildrenBd_bore_outdata[33])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[33] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[34] && bda_s1_boreChildrenBd_bore_outdata[34])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[34] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[35] && bda_s1_boreChildrenBd_bore_outdata[35])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[35] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[36] && bda_s1_boreChildrenBd_bore_outdata[36])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[36] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[37] && bda_s1_boreChildrenBd_bore_outdata[37])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[37] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[38] && bda_s1_boreChildrenBd_bore_outdata[38])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[38] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[39] && bda_s1_boreChildrenBd_bore_outdata[39])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[39] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[40] && bda_s1_boreChildrenBd_bore_outdata[40])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[40] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[41] && bda_s1_boreChildrenBd_bore_outdata[41])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[41] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[42] && bda_s1_boreChildrenBd_bore_outdata[42])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[42] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[43] && bda_s1_boreChildrenBd_bore_outdata[43])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[43] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[44] && bda_s1_boreChildrenBd_bore_outdata[44])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[44] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[45] && bda_s1_boreChildrenBd_bore_outdata[45])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[45] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[46] && bda_s1_boreChildrenBd_bore_outdata[46])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[46] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[47] && bda_s1_boreChildrenBd_bore_outdata[47])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[47] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[48] && bda_s1_boreChildrenBd_bore_outdata[48])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[48] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[49] && bda_s1_boreChildrenBd_bore_outdata[49])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[49] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[50] && bda_s1_boreChildrenBd_bore_outdata[50])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[50] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[51] && bda_s1_boreChildrenBd_bore_outdata[51])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[51] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[52] && bda_s1_boreChildrenBd_bore_outdata[52])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[52] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[53] && bda_s1_boreChildrenBd_bore_outdata[53])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[53] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[54] && bda_s1_boreChildrenBd_bore_outdata[54])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[54] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[55] && bda_s1_boreChildrenBd_bore_outdata[55])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[55] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[56] && bda_s1_boreChildrenBd_bore_outdata[56])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[56] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[57] && bda_s1_boreChildrenBd_bore_outdata[57])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[57] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[58] && bda_s1_boreChildrenBd_bore_outdata[58])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[58] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[59] && bda_s1_boreChildrenBd_bore_outdata[59])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[59] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[60] && bda_s1_boreChildrenBd_bore_outdata[60])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[60] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[61] && bda_s1_boreChildrenBd_bore_outdata[61])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[61] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[62] && bda_s1_boreChildrenBd_bore_outdata[62])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[62] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[63] && bda_s1_boreChildrenBd_bore_outdata[63])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[63] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[64] && bda_s1_boreChildrenBd_bore_outdata[64])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[64] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[65] && bda_s1_boreChildrenBd_bore_outdata[65])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[65] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[66] && bda_s1_boreChildrenBd_bore_outdata[66])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[66] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[67] && bda_s1_boreChildrenBd_bore_outdata[67])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[67] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[68] && bda_s1_boreChildrenBd_bore_outdata[68])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[68] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[69] && bda_s1_boreChildrenBd_bore_outdata[69])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[69] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[70] && bda_s1_boreChildrenBd_bore_outdata[70])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[70] 未见过 0 和 1"); end
    if (!(bda_s0_boreChildrenBd_bore_outdata[71] && bda_s1_boreChildrenBd_bore_outdata[71])) begin cov_fail++; $display("[COV] BankedDataArray.boreChildrenBd_bore_outdata[71] 未见过 0 和 1"); end
    $display("[ARM] BankedDataArray armed_at=%0d", bda_armed_at);
    if (bda_armed_at < 0) begin cov_fail++; $display("[ARM] BankedDataArray 从未 arm"); end
    $display("[COV] BankedDataArray.rr_conflict = %0d", bda_cov_rr_conflict);
    if (bda_cov_rr_conflict < 100) begin cov_fail++; $display("[COV] BankedDataArray.rr_conflict < 100"); end
    $display("[COV] BankedDataArray.rr_oldest_kill = %0d", bda_cov_rr_oldest_kill);
    if (bda_cov_rr_oldest_kill < 100) begin cov_fail++; $display("[COV] BankedDataArray.rr_oldest_kill < 100"); end
    $display("[COV] BankedDataArray.wr_conflict = %0d", bda_cov_wr_conflict);
    if (bda_cov_wr_conflict < 100) begin cov_fail++; $display("[COV] BankedDataArray.wr_conflict < 100"); end
    $display("[COV] BankedDataArray.rrl_conflict = %0d", bda_cov_rrl_conflict);
    if (bda_cov_rrl_conflict < 100) begin cov_fail++; $display("[COV] BankedDataArray.rrl_conflict < 100"); end
    $display("[COV] BankedDataArray.readline_blocked = %0d", bda_cov_readline_blocked);
    if (bda_cov_readline_blocked < 100) begin cov_fail++; $display("[COV] BankedDataArray.readline_blocked < 100"); end
    $display("[COV] BankedDataArray.read_err = %0d", bda_cov_read_err);
    if (bda_cov_read_err < 100) begin cov_fail++; $display("[COV] BankedDataArray.read_err < 100"); end
    $display("[COV] BankedDataArray.readline_err = %0d", bda_cov_readline_err);
    if (bda_cov_readline_err < 100) begin cov_fail++; $display("[COV] BankedDataArray.readline_err < 100"); end
    $display("[COV] BankedDataArray.pseudo_ready = %0d", bda_cov_pseudo_ready);
    if (bda_cov_pseudo_ready < 100) begin cov_fail++; $display("[COV] BankedDataArray.pseudo_ready < 100"); end
    $display("[COV] BankedDataArray.mbist_ack = %0d", bda_cov_mbist_ack);
    if (bda_cov_mbist_ack < 100) begin cov_fail++; $display("[COV] BankedDataArray.mbist_ack < 100"); end
    $display("[COV] BankedDataArray.is128_read = %0d", bda_cov_is128_read);
    if (bda_cov_is128_read < 100) begin cov_fail++; $display("[COV] BankedDataArray.is128_read < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
