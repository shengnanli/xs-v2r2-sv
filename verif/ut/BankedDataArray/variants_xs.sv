// 自动生成: scripts/gen_bankeddata.py —— 勿手改
// BankedDataArray wrapper: 扁平 golden 端口 <-> 可读核 + DataSRAMBank/Mbist 黑盒
module BankedDataArray_xs import bankeddata_pkg::*; (
  input clock,
  input reset,
  input io_read_0_valid,
  input [3:0] io_read_0_bits_way_en,
  input [47:0] io_read_0_bits_addr,
  input [47:0] io_read_0_bits_addr_dup,
  input [7:0] io_read_0_bits_bankMask,
  input io_read_0_bits_lqIdx_flag,
  input [6:0] io_read_0_bits_lqIdx_value,
  input io_read_1_valid,
  input [3:0] io_read_1_bits_way_en,
  input [47:0] io_read_1_bits_addr,
  input [47:0] io_read_1_bits_addr_dup,
  input [7:0] io_read_1_bits_bankMask,
  input io_read_1_bits_lqIdx_flag,
  input [6:0] io_read_1_bits_lqIdx_value,
  input io_read_2_valid,
  input [3:0] io_read_2_bits_way_en,
  input [47:0] io_read_2_bits_addr,
  input [47:0] io_read_2_bits_addr_dup,
  input [7:0] io_read_2_bits_bankMask,
  input io_read_2_bits_lqIdx_flag,
  input [6:0] io_read_2_bits_lqIdx_value,
  input io_is128Req_0,
  input io_is128Req_1,
  input io_is128Req_2,
  input io_readline_intend,
  input io_readline_valid,
  input [3:0] io_readline_bits_way_en,
  input [47:0] io_readline_bits_addr,
  input [7:0] io_readline_bits_rmask,
  input io_readline_can_go,
  input io_readline_stall,
  input io_readline_can_resp,
  input io_write_valid,
  input [7:0] io_write_bits_wmask,
  input [63:0] io_write_bits_data_0,
  input [63:0] io_write_bits_data_1,
  input [63:0] io_write_bits_data_2,
  input [63:0] io_write_bits_data_3,
  input [63:0] io_write_bits_data_4,
  input [63:0] io_write_bits_data_5,
  input [63:0] io_write_bits_data_6,
  input [63:0] io_write_bits_data_7,
  input io_write_dup_0_valid,
  input [3:0] io_write_dup_0_bits_way_en,
  input [47:0] io_write_dup_0_bits_addr,
  input io_write_dup_1_valid,
  input [3:0] io_write_dup_1_bits_way_en,
  input [47:0] io_write_dup_1_bits_addr,
  input io_write_dup_2_valid,
  input [3:0] io_write_dup_2_bits_way_en,
  input [47:0] io_write_dup_2_bits_addr,
  input io_write_dup_3_valid,
  input [3:0] io_write_dup_3_bits_way_en,
  input [47:0] io_write_dup_3_bits_addr,
  input io_write_dup_4_valid,
  input [3:0] io_write_dup_4_bits_way_en,
  input [47:0] io_write_dup_4_bits_addr,
  input io_write_dup_5_valid,
  input [3:0] io_write_dup_5_bits_way_en,
  input [47:0] io_write_dup_5_bits_addr,
  input io_write_dup_6_valid,
  input [3:0] io_write_dup_6_bits_way_en,
  input [47:0] io_write_dup_6_bits_addr,
  input io_write_dup_7_valid,
  input [3:0] io_write_dup_7_bits_way_en,
  input [47:0] io_write_dup_7_bits_addr,
  input io_pseudo_error_valid,
  input io_pseudo_error_bits_0_valid,
  input [63:0] io_pseudo_error_bits_0_mask,
  input io_pseudo_error_bits_1_valid,
  input [63:0] io_pseudo_error_bits_1_mask,
  input io_pseudo_error_bits_2_valid,
  input [63:0] io_pseudo_error_bits_2_mask,
  input io_pseudo_error_bits_3_valid,
  input [63:0] io_pseudo_error_bits_3_mask,
  input io_pseudo_error_bits_4_valid,
  input [63:0] io_pseudo_error_bits_4_mask,
  input io_pseudo_error_bits_5_valid,
  input [63:0] io_pseudo_error_bits_5_mask,
  input io_pseudo_error_bits_6_valid,
  input [63:0] io_pseudo_error_bits_6_mask,
  input io_pseudo_error_bits_7_valid,
  input [63:0] io_pseudo_error_bits_7_mask,
  input [4:0] boreChildrenBd_bore_array,
  input boreChildrenBd_bore_all,
  input boreChildrenBd_bore_req,
  input boreChildrenBd_bore_writeen,
  input boreChildrenBd_bore_be,
  input [8:0] boreChildrenBd_bore_addr,
  input [71:0] boreChildrenBd_bore_indata,
  input boreChildrenBd_bore_readen,
  input [8:0] boreChildrenBd_bore_addr_rd,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen,
  input sigFromSrams_bore_2_ram_hold,
  input sigFromSrams_bore_2_ram_bypass,
  input sigFromSrams_bore_2_ram_bp_clken,
  input sigFromSrams_bore_2_ram_aux_clk,
  input sigFromSrams_bore_2_ram_aux_ckbp,
  input sigFromSrams_bore_2_ram_mcp_hold,
  input sigFromSrams_bore_2_cgen,
  input sigFromSrams_bore_3_ram_hold,
  input sigFromSrams_bore_3_ram_bypass,
  input sigFromSrams_bore_3_ram_bp_clken,
  input sigFromSrams_bore_3_ram_aux_clk,
  input sigFromSrams_bore_3_ram_aux_ckbp,
  input sigFromSrams_bore_3_ram_mcp_hold,
  input sigFromSrams_bore_3_cgen,
  input sigFromSrams_bore_4_ram_hold,
  input sigFromSrams_bore_4_ram_bypass,
  input sigFromSrams_bore_4_ram_bp_clken,
  input sigFromSrams_bore_4_ram_aux_clk,
  input sigFromSrams_bore_4_ram_aux_ckbp,
  input sigFromSrams_bore_4_ram_mcp_hold,
  input sigFromSrams_bore_4_cgen,
  input sigFromSrams_bore_5_ram_hold,
  input sigFromSrams_bore_5_ram_bypass,
  input sigFromSrams_bore_5_ram_bp_clken,
  input sigFromSrams_bore_5_ram_aux_clk,
  input sigFromSrams_bore_5_ram_aux_ckbp,
  input sigFromSrams_bore_5_ram_mcp_hold,
  input sigFromSrams_bore_5_cgen,
  input sigFromSrams_bore_6_ram_hold,
  input sigFromSrams_bore_6_ram_bypass,
  input sigFromSrams_bore_6_ram_bp_clken,
  input sigFromSrams_bore_6_ram_aux_clk,
  input sigFromSrams_bore_6_ram_aux_ckbp,
  input sigFromSrams_bore_6_ram_mcp_hold,
  input sigFromSrams_bore_6_cgen,
  input sigFromSrams_bore_7_ram_hold,
  input sigFromSrams_bore_7_ram_bypass,
  input sigFromSrams_bore_7_ram_bp_clken,
  input sigFromSrams_bore_7_ram_aux_clk,
  input sigFromSrams_bore_7_ram_aux_ckbp,
  input sigFromSrams_bore_7_ram_mcp_hold,
  input sigFromSrams_bore_7_cgen,
  input sigFromSrams_bore_8_ram_hold,
  input sigFromSrams_bore_8_ram_bypass,
  input sigFromSrams_bore_8_ram_bp_clken,
  input sigFromSrams_bore_8_ram_aux_clk,
  input sigFromSrams_bore_8_ram_aux_ckbp,
  input sigFromSrams_bore_8_ram_mcp_hold,
  input sigFromSrams_bore_8_cgen,
  input sigFromSrams_bore_9_ram_hold,
  input sigFromSrams_bore_9_ram_bypass,
  input sigFromSrams_bore_9_ram_bp_clken,
  input sigFromSrams_bore_9_ram_aux_clk,
  input sigFromSrams_bore_9_ram_aux_ckbp,
  input sigFromSrams_bore_9_ram_mcp_hold,
  input sigFromSrams_bore_9_cgen,
  input sigFromSrams_bore_10_ram_hold,
  input sigFromSrams_bore_10_ram_bypass,
  input sigFromSrams_bore_10_ram_bp_clken,
  input sigFromSrams_bore_10_ram_aux_clk,
  input sigFromSrams_bore_10_ram_aux_ckbp,
  input sigFromSrams_bore_10_ram_mcp_hold,
  input sigFromSrams_bore_10_cgen,
  input sigFromSrams_bore_11_ram_hold,
  input sigFromSrams_bore_11_ram_bypass,
  input sigFromSrams_bore_11_ram_bp_clken,
  input sigFromSrams_bore_11_ram_aux_clk,
  input sigFromSrams_bore_11_ram_aux_ckbp,
  input sigFromSrams_bore_11_ram_mcp_hold,
  input sigFromSrams_bore_11_cgen,
  input sigFromSrams_bore_12_ram_hold,
  input sigFromSrams_bore_12_ram_bypass,
  input sigFromSrams_bore_12_ram_bp_clken,
  input sigFromSrams_bore_12_ram_aux_clk,
  input sigFromSrams_bore_12_ram_aux_ckbp,
  input sigFromSrams_bore_12_ram_mcp_hold,
  input sigFromSrams_bore_12_cgen,
  input sigFromSrams_bore_13_ram_hold,
  input sigFromSrams_bore_13_ram_bypass,
  input sigFromSrams_bore_13_ram_bp_clken,
  input sigFromSrams_bore_13_ram_aux_clk,
  input sigFromSrams_bore_13_ram_aux_ckbp,
  input sigFromSrams_bore_13_ram_mcp_hold,
  input sigFromSrams_bore_13_cgen,
  input sigFromSrams_bore_14_ram_hold,
  input sigFromSrams_bore_14_ram_bypass,
  input sigFromSrams_bore_14_ram_bp_clken,
  input sigFromSrams_bore_14_ram_aux_clk,
  input sigFromSrams_bore_14_ram_aux_ckbp,
  input sigFromSrams_bore_14_ram_mcp_hold,
  input sigFromSrams_bore_14_cgen,
  input sigFromSrams_bore_15_ram_hold,
  input sigFromSrams_bore_15_ram_bypass,
  input sigFromSrams_bore_15_ram_bp_clken,
  input sigFromSrams_bore_15_ram_aux_clk,
  input sigFromSrams_bore_15_ram_aux_ckbp,
  input sigFromSrams_bore_15_ram_mcp_hold,
  input sigFromSrams_bore_15_cgen,
  input sigFromSrams_bore_16_ram_hold,
  input sigFromSrams_bore_16_ram_bypass,
  input sigFromSrams_bore_16_ram_bp_clken,
  input sigFromSrams_bore_16_ram_aux_clk,
  input sigFromSrams_bore_16_ram_aux_ckbp,
  input sigFromSrams_bore_16_ram_mcp_hold,
  input sigFromSrams_bore_16_cgen,
  input sigFromSrams_bore_17_ram_hold,
  input sigFromSrams_bore_17_ram_bypass,
  input sigFromSrams_bore_17_ram_bp_clken,
  input sigFromSrams_bore_17_ram_aux_clk,
  input sigFromSrams_bore_17_ram_aux_ckbp,
  input sigFromSrams_bore_17_ram_mcp_hold,
  input sigFromSrams_bore_17_cgen,
  input sigFromSrams_bore_18_ram_hold,
  input sigFromSrams_bore_18_ram_bypass,
  input sigFromSrams_bore_18_ram_bp_clken,
  input sigFromSrams_bore_18_ram_aux_clk,
  input sigFromSrams_bore_18_ram_aux_ckbp,
  input sigFromSrams_bore_18_ram_mcp_hold,
  input sigFromSrams_bore_18_cgen,
  input sigFromSrams_bore_19_ram_hold,
  input sigFromSrams_bore_19_ram_bypass,
  input sigFromSrams_bore_19_ram_bp_clken,
  input sigFromSrams_bore_19_ram_aux_clk,
  input sigFromSrams_bore_19_ram_aux_ckbp,
  input sigFromSrams_bore_19_ram_mcp_hold,
  input sigFromSrams_bore_19_cgen,
  input sigFromSrams_bore_20_ram_hold,
  input sigFromSrams_bore_20_ram_bypass,
  input sigFromSrams_bore_20_ram_bp_clken,
  input sigFromSrams_bore_20_ram_aux_clk,
  input sigFromSrams_bore_20_ram_aux_ckbp,
  input sigFromSrams_bore_20_ram_mcp_hold,
  input sigFromSrams_bore_20_cgen,
  input sigFromSrams_bore_21_ram_hold,
  input sigFromSrams_bore_21_ram_bypass,
  input sigFromSrams_bore_21_ram_bp_clken,
  input sigFromSrams_bore_21_ram_aux_clk,
  input sigFromSrams_bore_21_ram_aux_ckbp,
  input sigFromSrams_bore_21_ram_mcp_hold,
  input sigFromSrams_bore_21_cgen,
  input sigFromSrams_bore_22_ram_hold,
  input sigFromSrams_bore_22_ram_bypass,
  input sigFromSrams_bore_22_ram_bp_clken,
  input sigFromSrams_bore_22_ram_aux_clk,
  input sigFromSrams_bore_22_ram_aux_ckbp,
  input sigFromSrams_bore_22_ram_mcp_hold,
  input sigFromSrams_bore_22_cgen,
  input sigFromSrams_bore_23_ram_hold,
  input sigFromSrams_bore_23_ram_bypass,
  input sigFromSrams_bore_23_ram_bp_clken,
  input sigFromSrams_bore_23_ram_aux_clk,
  input sigFromSrams_bore_23_ram_aux_ckbp,
  input sigFromSrams_bore_23_ram_mcp_hold,
  input sigFromSrams_bore_23_cgen,
  input sigFromSrams_bore_24_ram_hold,
  input sigFromSrams_bore_24_ram_bypass,
  input sigFromSrams_bore_24_ram_bp_clken,
  input sigFromSrams_bore_24_ram_aux_clk,
  input sigFromSrams_bore_24_ram_aux_ckbp,
  input sigFromSrams_bore_24_ram_mcp_hold,
  input sigFromSrams_bore_24_cgen,
  input sigFromSrams_bore_25_ram_hold,
  input sigFromSrams_bore_25_ram_bypass,
  input sigFromSrams_bore_25_ram_bp_clken,
  input sigFromSrams_bore_25_ram_aux_clk,
  input sigFromSrams_bore_25_ram_aux_ckbp,
  input sigFromSrams_bore_25_ram_mcp_hold,
  input sigFromSrams_bore_25_cgen,
  input sigFromSrams_bore_26_ram_hold,
  input sigFromSrams_bore_26_ram_bypass,
  input sigFromSrams_bore_26_ram_bp_clken,
  input sigFromSrams_bore_26_ram_aux_clk,
  input sigFromSrams_bore_26_ram_aux_ckbp,
  input sigFromSrams_bore_26_ram_mcp_hold,
  input sigFromSrams_bore_26_cgen,
  input sigFromSrams_bore_27_ram_hold,
  input sigFromSrams_bore_27_ram_bypass,
  input sigFromSrams_bore_27_ram_bp_clken,
  input sigFromSrams_bore_27_ram_aux_clk,
  input sigFromSrams_bore_27_ram_aux_ckbp,
  input sigFromSrams_bore_27_ram_mcp_hold,
  input sigFromSrams_bore_27_cgen,
  input sigFromSrams_bore_28_ram_hold,
  input sigFromSrams_bore_28_ram_bypass,
  input sigFromSrams_bore_28_ram_bp_clken,
  input sigFromSrams_bore_28_ram_aux_clk,
  input sigFromSrams_bore_28_ram_aux_ckbp,
  input sigFromSrams_bore_28_ram_mcp_hold,
  input sigFromSrams_bore_28_cgen,
  input sigFromSrams_bore_29_ram_hold,
  input sigFromSrams_bore_29_ram_bypass,
  input sigFromSrams_bore_29_ram_bp_clken,
  input sigFromSrams_bore_29_ram_aux_clk,
  input sigFromSrams_bore_29_ram_aux_ckbp,
  input sigFromSrams_bore_29_ram_mcp_hold,
  input sigFromSrams_bore_29_cgen,
  input sigFromSrams_bore_30_ram_hold,
  input sigFromSrams_bore_30_ram_bypass,
  input sigFromSrams_bore_30_ram_bp_clken,
  input sigFromSrams_bore_30_ram_aux_clk,
  input sigFromSrams_bore_30_ram_aux_ckbp,
  input sigFromSrams_bore_30_ram_mcp_hold,
  input sigFromSrams_bore_30_cgen,
  input sigFromSrams_bore_31_ram_hold,
  input sigFromSrams_bore_31_ram_bypass,
  input sigFromSrams_bore_31_ram_bp_clken,
  input sigFromSrams_bore_31_ram_aux_clk,
  input sigFromSrams_bore_31_ram_aux_ckbp,
  input sigFromSrams_bore_31_ram_mcp_hold,
  input sigFromSrams_bore_31_cgen,
  output io_read_0_ready,
  output io_read_1_ready,
  output io_read_2_ready,
  output io_readline_ready,
  output [63:0] io_readline_resp_0_raw_data,
  output [63:0] io_readline_resp_1_raw_data,
  output [63:0] io_readline_resp_2_raw_data,
  output [63:0] io_readline_resp_3_raw_data,
  output [63:0] io_readline_resp_4_raw_data,
  output [63:0] io_readline_resp_5_raw_data,
  output [63:0] io_readline_resp_6_raw_data,
  output [63:0] io_readline_resp_7_raw_data,
  output io_readline_error,
  output io_readline_error_delayed,
  output [63:0] io_read_resp_0_0_raw_data,
  output [63:0] io_read_resp_0_1_raw_data,
  output [63:0] io_read_resp_1_0_raw_data,
  output [63:0] io_read_resp_1_1_raw_data,
  output [63:0] io_read_resp_2_0_raw_data,
  output [63:0] io_read_resp_2_1_raw_data,
  output io_read_error_delayed_0_0,
  output io_read_error_delayed_0_1,
  output io_read_error_delayed_1_0,
  output io_read_error_delayed_1_1,
  output io_read_error_delayed_2_0,
  output io_read_error_delayed_2_1,
  output io_bank_conflict_slow_0,
  output io_bank_conflict_slow_1,
  output io_bank_conflict_slow_2,
  output io_disable_ld_fast_wakeup_0,
  output io_disable_ld_fast_wakeup_1,
  output io_disable_ld_fast_wakeup_2,
  output io_pseudo_error_ready,
  output boreChildrenBd_bore_ack,
  output [71:0] boreChildrenBd_bore_outdata
);

  // 可读核接口数组
  logic c_read_valid [0:2];
  logic [3:0] c_read_way_en [0:2];
  logic [47:0] c_read_addr [0:2];
  logic [47:0] c_read_addr_dup [0:2];
  logic [7:0] c_read_bankMask [0:2];
  logic c_read_lqIdx_flag [0:2];
  logic [6:0] c_read_lqIdx_value [0:2];
  logic c_read_ready [0:2];
  logic c_is128 [0:2];
  logic [63:0] c_write_data [0:7];
  logic c_write_dup_valid [0:7];
  logic [3:0] c_write_dup_way_en [0:7];
  logic [47:0] c_write_dup_addr [0:7];
  logic [63:0] c_readline_resp [0:7];
  logic [63:0] c_read_resp [0:2][0:1];
  logic c_read_err_dly [0:2][0:1];
  logic c_bank_conflict_slow [0:2];
  logic c_disable_fast [0:2];
  logic c_pe_bits_valid [0:7];
  logic [63:0] c_pe_bits_mask [0:7];
  logic c_sram_r_en [0:7];
  logic [7:0] c_sram_r_addr [0:7];
  logic [71:0] c_sram_r_data [0:7][0:3];
  logic c_sram_w_en [0:7];
  logic [3:0] c_sram_w_way_en [0:7];
  logic [7:0] c_sram_w_addr [0:7];
  logic [71:0] c_sram_w_data [0:7];
  logic c_mbist_ack; logic [1:0] c_mbist_r_way; logic c_mbist_r_div;

  assign c_read_valid[0]=io_read_0_valid; assign c_read_way_en[0]=io_read_0_bits_way_en;
  assign c_read_addr[0]=io_read_0_bits_addr; assign c_read_addr_dup[0]=io_read_0_bits_addr_dup;
  assign c_read_bankMask[0]=io_read_0_bits_bankMask;
  assign c_read_lqIdx_flag[0]=io_read_0_bits_lqIdx_flag; assign c_read_lqIdx_value[0]=io_read_0_bits_lqIdx_value;
  assign io_read_0_ready=c_read_ready[0]; assign c_is128[0]=io_is128Req_0;
  assign io_read_resp_0_0_raw_data=c_read_resp[0][0]; assign io_read_resp_0_1_raw_data=c_read_resp[0][1];
  assign io_read_error_delayed_0_0=c_read_err_dly[0][0]; assign io_read_error_delayed_0_1=c_read_err_dly[0][1];
  assign io_bank_conflict_slow_0=c_bank_conflict_slow[0]; assign io_disable_ld_fast_wakeup_0=c_disable_fast[0];
  assign c_read_valid[1]=io_read_1_valid; assign c_read_way_en[1]=io_read_1_bits_way_en;
  assign c_read_addr[1]=io_read_1_bits_addr; assign c_read_addr_dup[1]=io_read_1_bits_addr_dup;
  assign c_read_bankMask[1]=io_read_1_bits_bankMask;
  assign c_read_lqIdx_flag[1]=io_read_1_bits_lqIdx_flag; assign c_read_lqIdx_value[1]=io_read_1_bits_lqIdx_value;
  assign io_read_1_ready=c_read_ready[1]; assign c_is128[1]=io_is128Req_1;
  assign io_read_resp_1_0_raw_data=c_read_resp[1][0]; assign io_read_resp_1_1_raw_data=c_read_resp[1][1];
  assign io_read_error_delayed_1_0=c_read_err_dly[1][0]; assign io_read_error_delayed_1_1=c_read_err_dly[1][1];
  assign io_bank_conflict_slow_1=c_bank_conflict_slow[1]; assign io_disable_ld_fast_wakeup_1=c_disable_fast[1];
  assign c_read_valid[2]=io_read_2_valid; assign c_read_way_en[2]=io_read_2_bits_way_en;
  assign c_read_addr[2]=io_read_2_bits_addr; assign c_read_addr_dup[2]=io_read_2_bits_addr_dup;
  assign c_read_bankMask[2]=io_read_2_bits_bankMask;
  assign c_read_lqIdx_flag[2]=io_read_2_bits_lqIdx_flag; assign c_read_lqIdx_value[2]=io_read_2_bits_lqIdx_value;
  assign io_read_2_ready=c_read_ready[2]; assign c_is128[2]=io_is128Req_2;
  assign io_read_resp_2_0_raw_data=c_read_resp[2][0]; assign io_read_resp_2_1_raw_data=c_read_resp[2][1];
  assign io_read_error_delayed_2_0=c_read_err_dly[2][0]; assign io_read_error_delayed_2_1=c_read_err_dly[2][1];
  assign io_bank_conflict_slow_2=c_bank_conflict_slow[2]; assign io_disable_ld_fast_wakeup_2=c_disable_fast[2];
  assign c_write_data[0]=io_write_bits_data_0;
  assign c_write_dup_valid[0]=io_write_dup_0_valid; assign c_write_dup_way_en[0]=io_write_dup_0_bits_way_en; assign c_write_dup_addr[0]=io_write_dup_0_bits_addr;
  assign io_readline_resp_0_raw_data=c_readline_resp[0];
  assign c_pe_bits_valid[0]=io_pseudo_error_bits_0_valid; assign c_pe_bits_mask[0]=io_pseudo_error_bits_0_mask;
  assign c_write_data[1]=io_write_bits_data_1;
  assign c_write_dup_valid[1]=io_write_dup_1_valid; assign c_write_dup_way_en[1]=io_write_dup_1_bits_way_en; assign c_write_dup_addr[1]=io_write_dup_1_bits_addr;
  assign io_readline_resp_1_raw_data=c_readline_resp[1];
  assign c_pe_bits_valid[1]=io_pseudo_error_bits_1_valid; assign c_pe_bits_mask[1]=io_pseudo_error_bits_1_mask;
  assign c_write_data[2]=io_write_bits_data_2;
  assign c_write_dup_valid[2]=io_write_dup_2_valid; assign c_write_dup_way_en[2]=io_write_dup_2_bits_way_en; assign c_write_dup_addr[2]=io_write_dup_2_bits_addr;
  assign io_readline_resp_2_raw_data=c_readline_resp[2];
  assign c_pe_bits_valid[2]=io_pseudo_error_bits_2_valid; assign c_pe_bits_mask[2]=io_pseudo_error_bits_2_mask;
  assign c_write_data[3]=io_write_bits_data_3;
  assign c_write_dup_valid[3]=io_write_dup_3_valid; assign c_write_dup_way_en[3]=io_write_dup_3_bits_way_en; assign c_write_dup_addr[3]=io_write_dup_3_bits_addr;
  assign io_readline_resp_3_raw_data=c_readline_resp[3];
  assign c_pe_bits_valid[3]=io_pseudo_error_bits_3_valid; assign c_pe_bits_mask[3]=io_pseudo_error_bits_3_mask;
  assign c_write_data[4]=io_write_bits_data_4;
  assign c_write_dup_valid[4]=io_write_dup_4_valid; assign c_write_dup_way_en[4]=io_write_dup_4_bits_way_en; assign c_write_dup_addr[4]=io_write_dup_4_bits_addr;
  assign io_readline_resp_4_raw_data=c_readline_resp[4];
  assign c_pe_bits_valid[4]=io_pseudo_error_bits_4_valid; assign c_pe_bits_mask[4]=io_pseudo_error_bits_4_mask;
  assign c_write_data[5]=io_write_bits_data_5;
  assign c_write_dup_valid[5]=io_write_dup_5_valid; assign c_write_dup_way_en[5]=io_write_dup_5_bits_way_en; assign c_write_dup_addr[5]=io_write_dup_5_bits_addr;
  assign io_readline_resp_5_raw_data=c_readline_resp[5];
  assign c_pe_bits_valid[5]=io_pseudo_error_bits_5_valid; assign c_pe_bits_mask[5]=io_pseudo_error_bits_5_mask;
  assign c_write_data[6]=io_write_bits_data_6;
  assign c_write_dup_valid[6]=io_write_dup_6_valid; assign c_write_dup_way_en[6]=io_write_dup_6_bits_way_en; assign c_write_dup_addr[6]=io_write_dup_6_bits_addr;
  assign io_readline_resp_6_raw_data=c_readline_resp[6];
  assign c_pe_bits_valid[6]=io_pseudo_error_bits_6_valid; assign c_pe_bits_mask[6]=io_pseudo_error_bits_6_mask;
  assign c_write_data[7]=io_write_bits_data_7;
  assign c_write_dup_valid[7]=io_write_dup_7_valid; assign c_write_dup_way_en[7]=io_write_dup_7_bits_way_en; assign c_write_dup_addr[7]=io_write_dup_7_bits_addr;
  assign io_readline_resp_7_raw_data=c_readline_resp[7];
  assign c_pe_bits_valid[7]=io_pseudo_error_bits_7_valid; assign c_pe_bits_mask[7]=io_pseudo_error_bits_7_mask;

  xs_BankedDataArray_core u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(c_read_valid), .io_read_way_en(c_read_way_en),
    .io_read_addr(c_read_addr), .io_read_addr_dup(c_read_addr_dup),
    .io_read_bankMask(c_read_bankMask), .io_read_lqIdx_flag(c_read_lqIdx_flag),
    .io_read_lqIdx_value(c_read_lqIdx_value), .io_read_ready(c_read_ready), .io_is128Req(c_is128),
    .io_readline_intend(io_readline_intend), .io_readline_valid(io_readline_valid),
    .io_readline_way_en(io_readline_bits_way_en), .io_readline_addr(io_readline_bits_addr),
    .io_readline_rmask(io_readline_bits_rmask), .io_readline_can_go(io_readline_can_go),
    .io_readline_stall(io_readline_stall), .io_readline_can_resp(io_readline_can_resp),
    .io_readline_ready(io_readline_ready),
    .io_write_valid(io_write_valid), .io_write_wmask(io_write_bits_wmask), .io_write_data(c_write_data),
    .io_write_dup_valid(c_write_dup_valid), .io_write_dup_way_en(c_write_dup_way_en), .io_write_dup_addr(c_write_dup_addr),
    .io_readline_resp(c_readline_resp), .io_readline_error(io_readline_error), .io_readline_error_delayed(io_readline_error_delayed),
    .io_read_resp(c_read_resp), .io_read_error_delayed(c_read_err_dly),
    .io_bank_conflict_slow(c_bank_conflict_slow), .io_disable_ld_fast_wakeup(c_disable_fast),
    .io_pseudo_error_valid(io_pseudo_error_valid), .io_pseudo_error_bits_valid(c_pe_bits_valid),
    .io_pseudo_error_bits_mask(c_pe_bits_mask), .io_pseudo_error_ready(io_pseudo_error_ready),
    .sram_r_en(c_sram_r_en), .sram_r_addr(c_sram_r_addr), .sram_r_data(c_sram_r_data),
    .sram_w_en(c_sram_w_en), .sram_w_way_en(c_sram_w_way_en), .sram_w_addr(c_sram_w_addr), .sram_w_data(c_sram_w_data),
    .mbist_ack(c_mbist_ack), .mbist_r_way(c_mbist_r_way), .mbist_r_div(c_mbist_r_div)
  );

  // MBIST bore: 32 条 childBd (bank b 用 [4b..4b+3]), 32 sig 组
  wire [8:0] cb_addr [32];
  wire [8:0] cb_addr_rd [32];
  wire [71:0] cb_wdata [32];
  wire cb_wmask [32];
  wire cb_re [32];
  wire cb_we [32];
  wire [71:0] cb_rdata [32];
  wire cb_ack [32];
  wire cb_selectedOH [32];
  wire cb_array_0;
  wire cb_array_1;
  wire [1:0] cb_array_2;
  wire [1:0] cb_array_3;
  wire [2:0] cb_array_4;
  wire [2:0] cb_array_5;
  wire [2:0] cb_array_6;
  wire [2:0] cb_array_7;
  wire [3:0] cb_array_8;
  wire [3:0] cb_array_9;
  wire [3:0] cb_array_10;
  wire [3:0] cb_array_11;
  wire [3:0] cb_array_12;
  wire [3:0] cb_array_13;
  wire [3:0] cb_array_14;
  wire [3:0] cb_array_15;
  wire [4:0] cb_array_16;
  wire [4:0] cb_array_17;
  wire [4:0] cb_array_18;
  wire [4:0] cb_array_19;
  wire [4:0] cb_array_20;
  wire [4:0] cb_array_21;
  wire [4:0] cb_array_22;
  wire [4:0] cb_array_23;
  wire [4:0] cb_array_24;
  wire [4:0] cb_array_25;
  wire [4:0] cb_array_26;
  wire [4:0] cb_array_27;
  wire [4:0] cb_array_28;
  wire [4:0] cb_array_29;
  wire [4:0] cb_array_30;
  wire [4:0] cb_array_31;
  wire [6:0] sg [32];
  wire c_mbist_ack_pl;
  assign sg[0] = {sigFromSrams_bore_cgen, sigFromSrams_bore_ram_mcp_hold, sigFromSrams_bore_ram_aux_ckbp, sigFromSrams_bore_ram_aux_clk, sigFromSrams_bore_ram_bp_clken, sigFromSrams_bore_ram_bypass, sigFromSrams_bore_ram_hold};
  assign sg[1] = {sigFromSrams_bore_1_cgen, sigFromSrams_bore_1_ram_mcp_hold, sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_aux_clk, sigFromSrams_bore_1_ram_bp_clken, sigFromSrams_bore_1_ram_bypass, sigFromSrams_bore_1_ram_hold};
  assign sg[2] = {sigFromSrams_bore_2_cgen, sigFromSrams_bore_2_ram_mcp_hold, sigFromSrams_bore_2_ram_aux_ckbp, sigFromSrams_bore_2_ram_aux_clk, sigFromSrams_bore_2_ram_bp_clken, sigFromSrams_bore_2_ram_bypass, sigFromSrams_bore_2_ram_hold};
  assign sg[3] = {sigFromSrams_bore_3_cgen, sigFromSrams_bore_3_ram_mcp_hold, sigFromSrams_bore_3_ram_aux_ckbp, sigFromSrams_bore_3_ram_aux_clk, sigFromSrams_bore_3_ram_bp_clken, sigFromSrams_bore_3_ram_bypass, sigFromSrams_bore_3_ram_hold};
  assign sg[4] = {sigFromSrams_bore_4_cgen, sigFromSrams_bore_4_ram_mcp_hold, sigFromSrams_bore_4_ram_aux_ckbp, sigFromSrams_bore_4_ram_aux_clk, sigFromSrams_bore_4_ram_bp_clken, sigFromSrams_bore_4_ram_bypass, sigFromSrams_bore_4_ram_hold};
  assign sg[5] = {sigFromSrams_bore_5_cgen, sigFromSrams_bore_5_ram_mcp_hold, sigFromSrams_bore_5_ram_aux_ckbp, sigFromSrams_bore_5_ram_aux_clk, sigFromSrams_bore_5_ram_bp_clken, sigFromSrams_bore_5_ram_bypass, sigFromSrams_bore_5_ram_hold};
  assign sg[6] = {sigFromSrams_bore_6_cgen, sigFromSrams_bore_6_ram_mcp_hold, sigFromSrams_bore_6_ram_aux_ckbp, sigFromSrams_bore_6_ram_aux_clk, sigFromSrams_bore_6_ram_bp_clken, sigFromSrams_bore_6_ram_bypass, sigFromSrams_bore_6_ram_hold};
  assign sg[7] = {sigFromSrams_bore_7_cgen, sigFromSrams_bore_7_ram_mcp_hold, sigFromSrams_bore_7_ram_aux_ckbp, sigFromSrams_bore_7_ram_aux_clk, sigFromSrams_bore_7_ram_bp_clken, sigFromSrams_bore_7_ram_bypass, sigFromSrams_bore_7_ram_hold};
  assign sg[8] = {sigFromSrams_bore_8_cgen, sigFromSrams_bore_8_ram_mcp_hold, sigFromSrams_bore_8_ram_aux_ckbp, sigFromSrams_bore_8_ram_aux_clk, sigFromSrams_bore_8_ram_bp_clken, sigFromSrams_bore_8_ram_bypass, sigFromSrams_bore_8_ram_hold};
  assign sg[9] = {sigFromSrams_bore_9_cgen, sigFromSrams_bore_9_ram_mcp_hold, sigFromSrams_bore_9_ram_aux_ckbp, sigFromSrams_bore_9_ram_aux_clk, sigFromSrams_bore_9_ram_bp_clken, sigFromSrams_bore_9_ram_bypass, sigFromSrams_bore_9_ram_hold};
  assign sg[10] = {sigFromSrams_bore_10_cgen, sigFromSrams_bore_10_ram_mcp_hold, sigFromSrams_bore_10_ram_aux_ckbp, sigFromSrams_bore_10_ram_aux_clk, sigFromSrams_bore_10_ram_bp_clken, sigFromSrams_bore_10_ram_bypass, sigFromSrams_bore_10_ram_hold};
  assign sg[11] = {sigFromSrams_bore_11_cgen, sigFromSrams_bore_11_ram_mcp_hold, sigFromSrams_bore_11_ram_aux_ckbp, sigFromSrams_bore_11_ram_aux_clk, sigFromSrams_bore_11_ram_bp_clken, sigFromSrams_bore_11_ram_bypass, sigFromSrams_bore_11_ram_hold};
  assign sg[12] = {sigFromSrams_bore_12_cgen, sigFromSrams_bore_12_ram_mcp_hold, sigFromSrams_bore_12_ram_aux_ckbp, sigFromSrams_bore_12_ram_aux_clk, sigFromSrams_bore_12_ram_bp_clken, sigFromSrams_bore_12_ram_bypass, sigFromSrams_bore_12_ram_hold};
  assign sg[13] = {sigFromSrams_bore_13_cgen, sigFromSrams_bore_13_ram_mcp_hold, sigFromSrams_bore_13_ram_aux_ckbp, sigFromSrams_bore_13_ram_aux_clk, sigFromSrams_bore_13_ram_bp_clken, sigFromSrams_bore_13_ram_bypass, sigFromSrams_bore_13_ram_hold};
  assign sg[14] = {sigFromSrams_bore_14_cgen, sigFromSrams_bore_14_ram_mcp_hold, sigFromSrams_bore_14_ram_aux_ckbp, sigFromSrams_bore_14_ram_aux_clk, sigFromSrams_bore_14_ram_bp_clken, sigFromSrams_bore_14_ram_bypass, sigFromSrams_bore_14_ram_hold};
  assign sg[15] = {sigFromSrams_bore_15_cgen, sigFromSrams_bore_15_ram_mcp_hold, sigFromSrams_bore_15_ram_aux_ckbp, sigFromSrams_bore_15_ram_aux_clk, sigFromSrams_bore_15_ram_bp_clken, sigFromSrams_bore_15_ram_bypass, sigFromSrams_bore_15_ram_hold};
  assign sg[16] = {sigFromSrams_bore_16_cgen, sigFromSrams_bore_16_ram_mcp_hold, sigFromSrams_bore_16_ram_aux_ckbp, sigFromSrams_bore_16_ram_aux_clk, sigFromSrams_bore_16_ram_bp_clken, sigFromSrams_bore_16_ram_bypass, sigFromSrams_bore_16_ram_hold};
  assign sg[17] = {sigFromSrams_bore_17_cgen, sigFromSrams_bore_17_ram_mcp_hold, sigFromSrams_bore_17_ram_aux_ckbp, sigFromSrams_bore_17_ram_aux_clk, sigFromSrams_bore_17_ram_bp_clken, sigFromSrams_bore_17_ram_bypass, sigFromSrams_bore_17_ram_hold};
  assign sg[18] = {sigFromSrams_bore_18_cgen, sigFromSrams_bore_18_ram_mcp_hold, sigFromSrams_bore_18_ram_aux_ckbp, sigFromSrams_bore_18_ram_aux_clk, sigFromSrams_bore_18_ram_bp_clken, sigFromSrams_bore_18_ram_bypass, sigFromSrams_bore_18_ram_hold};
  assign sg[19] = {sigFromSrams_bore_19_cgen, sigFromSrams_bore_19_ram_mcp_hold, sigFromSrams_bore_19_ram_aux_ckbp, sigFromSrams_bore_19_ram_aux_clk, sigFromSrams_bore_19_ram_bp_clken, sigFromSrams_bore_19_ram_bypass, sigFromSrams_bore_19_ram_hold};
  assign sg[20] = {sigFromSrams_bore_20_cgen, sigFromSrams_bore_20_ram_mcp_hold, sigFromSrams_bore_20_ram_aux_ckbp, sigFromSrams_bore_20_ram_aux_clk, sigFromSrams_bore_20_ram_bp_clken, sigFromSrams_bore_20_ram_bypass, sigFromSrams_bore_20_ram_hold};
  assign sg[21] = {sigFromSrams_bore_21_cgen, sigFromSrams_bore_21_ram_mcp_hold, sigFromSrams_bore_21_ram_aux_ckbp, sigFromSrams_bore_21_ram_aux_clk, sigFromSrams_bore_21_ram_bp_clken, sigFromSrams_bore_21_ram_bypass, sigFromSrams_bore_21_ram_hold};
  assign sg[22] = {sigFromSrams_bore_22_cgen, sigFromSrams_bore_22_ram_mcp_hold, sigFromSrams_bore_22_ram_aux_ckbp, sigFromSrams_bore_22_ram_aux_clk, sigFromSrams_bore_22_ram_bp_clken, sigFromSrams_bore_22_ram_bypass, sigFromSrams_bore_22_ram_hold};
  assign sg[23] = {sigFromSrams_bore_23_cgen, sigFromSrams_bore_23_ram_mcp_hold, sigFromSrams_bore_23_ram_aux_ckbp, sigFromSrams_bore_23_ram_aux_clk, sigFromSrams_bore_23_ram_bp_clken, sigFromSrams_bore_23_ram_bypass, sigFromSrams_bore_23_ram_hold};
  assign sg[24] = {sigFromSrams_bore_24_cgen, sigFromSrams_bore_24_ram_mcp_hold, sigFromSrams_bore_24_ram_aux_ckbp, sigFromSrams_bore_24_ram_aux_clk, sigFromSrams_bore_24_ram_bp_clken, sigFromSrams_bore_24_ram_bypass, sigFromSrams_bore_24_ram_hold};
  assign sg[25] = {sigFromSrams_bore_25_cgen, sigFromSrams_bore_25_ram_mcp_hold, sigFromSrams_bore_25_ram_aux_ckbp, sigFromSrams_bore_25_ram_aux_clk, sigFromSrams_bore_25_ram_bp_clken, sigFromSrams_bore_25_ram_bypass, sigFromSrams_bore_25_ram_hold};
  assign sg[26] = {sigFromSrams_bore_26_cgen, sigFromSrams_bore_26_ram_mcp_hold, sigFromSrams_bore_26_ram_aux_ckbp, sigFromSrams_bore_26_ram_aux_clk, sigFromSrams_bore_26_ram_bp_clken, sigFromSrams_bore_26_ram_bypass, sigFromSrams_bore_26_ram_hold};
  assign sg[27] = {sigFromSrams_bore_27_cgen, sigFromSrams_bore_27_ram_mcp_hold, sigFromSrams_bore_27_ram_aux_ckbp, sigFromSrams_bore_27_ram_aux_clk, sigFromSrams_bore_27_ram_bp_clken, sigFromSrams_bore_27_ram_bypass, sigFromSrams_bore_27_ram_hold};
  assign sg[28] = {sigFromSrams_bore_28_cgen, sigFromSrams_bore_28_ram_mcp_hold, sigFromSrams_bore_28_ram_aux_ckbp, sigFromSrams_bore_28_ram_aux_clk, sigFromSrams_bore_28_ram_bp_clken, sigFromSrams_bore_28_ram_bypass, sigFromSrams_bore_28_ram_hold};
  assign sg[29] = {sigFromSrams_bore_29_cgen, sigFromSrams_bore_29_ram_mcp_hold, sigFromSrams_bore_29_ram_aux_ckbp, sigFromSrams_bore_29_ram_aux_clk, sigFromSrams_bore_29_ram_bp_clken, sigFromSrams_bore_29_ram_bypass, sigFromSrams_bore_29_ram_hold};
  assign sg[30] = {sigFromSrams_bore_30_cgen, sigFromSrams_bore_30_ram_mcp_hold, sigFromSrams_bore_30_ram_aux_ckbp, sigFromSrams_bore_30_ram_aux_clk, sigFromSrams_bore_30_ram_bp_clken, sigFromSrams_bore_30_ram_bypass, sigFromSrams_bore_30_ram_hold};
  assign sg[31] = {sigFromSrams_bore_31_cgen, sigFromSrams_bore_31_ram_mcp_hold, sigFromSrams_bore_31_ram_aux_ckbp, sigFromSrams_bore_31_ram_aux_clk, sigFromSrams_bore_31_ram_bp_clken, sigFromSrams_bore_31_ram_bypass, sigFromSrams_bore_31_ram_hold};

  // mbist_r_way: 各 bank 的 {re3,re2,re1} 按位或后 OHToUInt(本配置 mbist 不激活时恒 0)
  wire [2:0] mbist_way_oh = {cb_re[3],cb_re[2],cb_re[1]} | {cb_re[7],cb_re[6],cb_re[5]} | {cb_re[11],cb_re[10],cb_re[9]} | {cb_re[15],cb_re[14],cb_re[13]} | {cb_re[19],cb_re[18],cb_re[17]} | {cb_re[23],cb_re[22],cb_re[21]} | {cb_re[27],cb_re[26],cb_re[25]} | {cb_re[31],cb_re[30],cb_re[29]};
  assign c_mbist_r_way = {mbist_way_oh[2]|mbist_way_oh[1], mbist_way_oh[2]|mbist_way_oh[0]};
  assign c_mbist_r_div = 1'b0;

  DataSRAMBank data_banks_0_0 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[0]), .io_w_addr(c_sram_w_addr[0]), .io_w_way_en(c_sram_w_way_en[0]), .io_w_data(c_sram_w_data[0]),
    .io_r_en(c_sram_r_en[0]), .io_r_addr(c_sram_r_addr[0]),
    .io_r_data_0(c_sram_r_data[0][0]), .io_r_data_1(c_sram_r_data[0][1]), .io_r_data_2(c_sram_r_data[0][2]), .io_r_data_3(c_sram_r_data[0][3]),
    .boreChildrenBd_bore_addr(cb_addr[0]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[0]), .boreChildrenBd_bore_wdata(cb_wdata[0]), .boreChildrenBd_bore_wmask(cb_wmask[0]), .boreChildrenBd_bore_re(cb_re[0]), .boreChildrenBd_bore_we(cb_we[0]), .boreChildrenBd_bore_rdata(cb_rdata[0]), .boreChildrenBd_bore_ack(cb_ack[0]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[0]), .boreChildrenBd_bore_array(cb_array_0),
    .boreChildrenBd_bore_1_addr(cb_addr[1]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[1]), .boreChildrenBd_bore_1_wdata(cb_wdata[1]), .boreChildrenBd_bore_1_wmask(cb_wmask[1]), .boreChildrenBd_bore_1_re(cb_re[1]), .boreChildrenBd_bore_1_we(cb_we[1]), .boreChildrenBd_bore_1_rdata(cb_rdata[1]), .boreChildrenBd_bore_1_ack(cb_ack[1]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[1]), .boreChildrenBd_bore_1_array(cb_array_1),
    .boreChildrenBd_bore_2_addr(cb_addr[2]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[2]), .boreChildrenBd_bore_2_wdata(cb_wdata[2]), .boreChildrenBd_bore_2_wmask(cb_wmask[2]), .boreChildrenBd_bore_2_re(cb_re[2]), .boreChildrenBd_bore_2_we(cb_we[2]), .boreChildrenBd_bore_2_rdata(cb_rdata[2]), .boreChildrenBd_bore_2_ack(cb_ack[2]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[2]), .boreChildrenBd_bore_2_array(cb_array_2),
    .boreChildrenBd_bore_3_addr(cb_addr[3]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[3]), .boreChildrenBd_bore_3_wdata(cb_wdata[3]), .boreChildrenBd_bore_3_wmask(cb_wmask[3]), .boreChildrenBd_bore_3_re(cb_re[3]), .boreChildrenBd_bore_3_we(cb_we[3]), .boreChildrenBd_bore_3_rdata(cb_rdata[3]), .boreChildrenBd_bore_3_ack(cb_ack[3]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[3]), .boreChildrenBd_bore_3_array(cb_array_3),
    .sigFromSrams_bore_ram_hold(sg[0][0]), .sigFromSrams_bore_ram_bypass(sg[0][1]), .sigFromSrams_bore_ram_bp_clken(sg[0][2]), .sigFromSrams_bore_ram_aux_clk(sg[0][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[0][4]), .sigFromSrams_bore_ram_mcp_hold(sg[0][5]), .sigFromSrams_bore_cgen(sg[0][6]),
    .sigFromSrams_bore_1_ram_hold(sg[1][0]), .sigFromSrams_bore_1_ram_bypass(sg[1][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[1][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[1][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[1][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[1][5]), .sigFromSrams_bore_1_cgen(sg[1][6]),
    .sigFromSrams_bore_2_ram_hold(sg[2][0]), .sigFromSrams_bore_2_ram_bypass(sg[2][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[2][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[2][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[2][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[2][5]), .sigFromSrams_bore_2_cgen(sg[2][6]),
    .sigFromSrams_bore_3_ram_hold(sg[3][0]), .sigFromSrams_bore_3_ram_bypass(sg[3][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[3][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[3][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[3][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[3][5]), .sigFromSrams_bore_3_cgen(sg[3][6])
  );
  DataSRAMBank_1 data_banks_0_1 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[1]), .io_w_addr(c_sram_w_addr[1]), .io_w_way_en(c_sram_w_way_en[1]), .io_w_data(c_sram_w_data[1]),
    .io_r_en(c_sram_r_en[1]), .io_r_addr(c_sram_r_addr[1]),
    .io_r_data_0(c_sram_r_data[1][0]), .io_r_data_1(c_sram_r_data[1][1]), .io_r_data_2(c_sram_r_data[1][2]), .io_r_data_3(c_sram_r_data[1][3]),
    .boreChildrenBd_bore_addr(cb_addr[4]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[4]), .boreChildrenBd_bore_wdata(cb_wdata[4]), .boreChildrenBd_bore_wmask(cb_wmask[4]), .boreChildrenBd_bore_re(cb_re[4]), .boreChildrenBd_bore_we(cb_we[4]), .boreChildrenBd_bore_rdata(cb_rdata[4]), .boreChildrenBd_bore_ack(cb_ack[4]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[4]), .boreChildrenBd_bore_array(cb_array_4),
    .boreChildrenBd_bore_1_addr(cb_addr[5]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[5]), .boreChildrenBd_bore_1_wdata(cb_wdata[5]), .boreChildrenBd_bore_1_wmask(cb_wmask[5]), .boreChildrenBd_bore_1_re(cb_re[5]), .boreChildrenBd_bore_1_we(cb_we[5]), .boreChildrenBd_bore_1_rdata(cb_rdata[5]), .boreChildrenBd_bore_1_ack(cb_ack[5]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[5]), .boreChildrenBd_bore_1_array(cb_array_5),
    .boreChildrenBd_bore_2_addr(cb_addr[6]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[6]), .boreChildrenBd_bore_2_wdata(cb_wdata[6]), .boreChildrenBd_bore_2_wmask(cb_wmask[6]), .boreChildrenBd_bore_2_re(cb_re[6]), .boreChildrenBd_bore_2_we(cb_we[6]), .boreChildrenBd_bore_2_rdata(cb_rdata[6]), .boreChildrenBd_bore_2_ack(cb_ack[6]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[6]), .boreChildrenBd_bore_2_array(cb_array_6),
    .boreChildrenBd_bore_3_addr(cb_addr[7]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[7]), .boreChildrenBd_bore_3_wdata(cb_wdata[7]), .boreChildrenBd_bore_3_wmask(cb_wmask[7]), .boreChildrenBd_bore_3_re(cb_re[7]), .boreChildrenBd_bore_3_we(cb_we[7]), .boreChildrenBd_bore_3_rdata(cb_rdata[7]), .boreChildrenBd_bore_3_ack(cb_ack[7]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[7]), .boreChildrenBd_bore_3_array(cb_array_7),
    .sigFromSrams_bore_ram_hold(sg[4][0]), .sigFromSrams_bore_ram_bypass(sg[4][1]), .sigFromSrams_bore_ram_bp_clken(sg[4][2]), .sigFromSrams_bore_ram_aux_clk(sg[4][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[4][4]), .sigFromSrams_bore_ram_mcp_hold(sg[4][5]), .sigFromSrams_bore_cgen(sg[4][6]),
    .sigFromSrams_bore_1_ram_hold(sg[5][0]), .sigFromSrams_bore_1_ram_bypass(sg[5][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[5][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[5][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[5][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[5][5]), .sigFromSrams_bore_1_cgen(sg[5][6]),
    .sigFromSrams_bore_2_ram_hold(sg[6][0]), .sigFromSrams_bore_2_ram_bypass(sg[6][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[6][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[6][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[6][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[6][5]), .sigFromSrams_bore_2_cgen(sg[6][6]),
    .sigFromSrams_bore_3_ram_hold(sg[7][0]), .sigFromSrams_bore_3_ram_bypass(sg[7][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[7][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[7][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[7][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[7][5]), .sigFromSrams_bore_3_cgen(sg[7][6])
  );
  DataSRAMBank_2 data_banks_0_2 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[2]), .io_w_addr(c_sram_w_addr[2]), .io_w_way_en(c_sram_w_way_en[2]), .io_w_data(c_sram_w_data[2]),
    .io_r_en(c_sram_r_en[2]), .io_r_addr(c_sram_r_addr[2]),
    .io_r_data_0(c_sram_r_data[2][0]), .io_r_data_1(c_sram_r_data[2][1]), .io_r_data_2(c_sram_r_data[2][2]), .io_r_data_3(c_sram_r_data[2][3]),
    .boreChildrenBd_bore_addr(cb_addr[8]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[8]), .boreChildrenBd_bore_wdata(cb_wdata[8]), .boreChildrenBd_bore_wmask(cb_wmask[8]), .boreChildrenBd_bore_re(cb_re[8]), .boreChildrenBd_bore_we(cb_we[8]), .boreChildrenBd_bore_rdata(cb_rdata[8]), .boreChildrenBd_bore_ack(cb_ack[8]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[8]), .boreChildrenBd_bore_array(cb_array_8),
    .boreChildrenBd_bore_1_addr(cb_addr[9]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[9]), .boreChildrenBd_bore_1_wdata(cb_wdata[9]), .boreChildrenBd_bore_1_wmask(cb_wmask[9]), .boreChildrenBd_bore_1_re(cb_re[9]), .boreChildrenBd_bore_1_we(cb_we[9]), .boreChildrenBd_bore_1_rdata(cb_rdata[9]), .boreChildrenBd_bore_1_ack(cb_ack[9]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[9]), .boreChildrenBd_bore_1_array(cb_array_9),
    .boreChildrenBd_bore_2_addr(cb_addr[10]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[10]), .boreChildrenBd_bore_2_wdata(cb_wdata[10]), .boreChildrenBd_bore_2_wmask(cb_wmask[10]), .boreChildrenBd_bore_2_re(cb_re[10]), .boreChildrenBd_bore_2_we(cb_we[10]), .boreChildrenBd_bore_2_rdata(cb_rdata[10]), .boreChildrenBd_bore_2_ack(cb_ack[10]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[10]), .boreChildrenBd_bore_2_array(cb_array_10),
    .boreChildrenBd_bore_3_addr(cb_addr[11]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[11]), .boreChildrenBd_bore_3_wdata(cb_wdata[11]), .boreChildrenBd_bore_3_wmask(cb_wmask[11]), .boreChildrenBd_bore_3_re(cb_re[11]), .boreChildrenBd_bore_3_we(cb_we[11]), .boreChildrenBd_bore_3_rdata(cb_rdata[11]), .boreChildrenBd_bore_3_ack(cb_ack[11]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[11]), .boreChildrenBd_bore_3_array(cb_array_11),
    .sigFromSrams_bore_ram_hold(sg[8][0]), .sigFromSrams_bore_ram_bypass(sg[8][1]), .sigFromSrams_bore_ram_bp_clken(sg[8][2]), .sigFromSrams_bore_ram_aux_clk(sg[8][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[8][4]), .sigFromSrams_bore_ram_mcp_hold(sg[8][5]), .sigFromSrams_bore_cgen(sg[8][6]),
    .sigFromSrams_bore_1_ram_hold(sg[9][0]), .sigFromSrams_bore_1_ram_bypass(sg[9][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[9][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[9][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[9][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[9][5]), .sigFromSrams_bore_1_cgen(sg[9][6]),
    .sigFromSrams_bore_2_ram_hold(sg[10][0]), .sigFromSrams_bore_2_ram_bypass(sg[10][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[10][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[10][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[10][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[10][5]), .sigFromSrams_bore_2_cgen(sg[10][6]),
    .sigFromSrams_bore_3_ram_hold(sg[11][0]), .sigFromSrams_bore_3_ram_bypass(sg[11][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[11][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[11][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[11][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[11][5]), .sigFromSrams_bore_3_cgen(sg[11][6])
  );
  DataSRAMBank_2 data_banks_0_3 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[3]), .io_w_addr(c_sram_w_addr[3]), .io_w_way_en(c_sram_w_way_en[3]), .io_w_data(c_sram_w_data[3]),
    .io_r_en(c_sram_r_en[3]), .io_r_addr(c_sram_r_addr[3]),
    .io_r_data_0(c_sram_r_data[3][0]), .io_r_data_1(c_sram_r_data[3][1]), .io_r_data_2(c_sram_r_data[3][2]), .io_r_data_3(c_sram_r_data[3][3]),
    .boreChildrenBd_bore_addr(cb_addr[12]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[12]), .boreChildrenBd_bore_wdata(cb_wdata[12]), .boreChildrenBd_bore_wmask(cb_wmask[12]), .boreChildrenBd_bore_re(cb_re[12]), .boreChildrenBd_bore_we(cb_we[12]), .boreChildrenBd_bore_rdata(cb_rdata[12]), .boreChildrenBd_bore_ack(cb_ack[12]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[12]), .boreChildrenBd_bore_array(cb_array_12),
    .boreChildrenBd_bore_1_addr(cb_addr[13]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[13]), .boreChildrenBd_bore_1_wdata(cb_wdata[13]), .boreChildrenBd_bore_1_wmask(cb_wmask[13]), .boreChildrenBd_bore_1_re(cb_re[13]), .boreChildrenBd_bore_1_we(cb_we[13]), .boreChildrenBd_bore_1_rdata(cb_rdata[13]), .boreChildrenBd_bore_1_ack(cb_ack[13]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[13]), .boreChildrenBd_bore_1_array(cb_array_13),
    .boreChildrenBd_bore_2_addr(cb_addr[14]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[14]), .boreChildrenBd_bore_2_wdata(cb_wdata[14]), .boreChildrenBd_bore_2_wmask(cb_wmask[14]), .boreChildrenBd_bore_2_re(cb_re[14]), .boreChildrenBd_bore_2_we(cb_we[14]), .boreChildrenBd_bore_2_rdata(cb_rdata[14]), .boreChildrenBd_bore_2_ack(cb_ack[14]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[14]), .boreChildrenBd_bore_2_array(cb_array_14),
    .boreChildrenBd_bore_3_addr(cb_addr[15]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[15]), .boreChildrenBd_bore_3_wdata(cb_wdata[15]), .boreChildrenBd_bore_3_wmask(cb_wmask[15]), .boreChildrenBd_bore_3_re(cb_re[15]), .boreChildrenBd_bore_3_we(cb_we[15]), .boreChildrenBd_bore_3_rdata(cb_rdata[15]), .boreChildrenBd_bore_3_ack(cb_ack[15]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[15]), .boreChildrenBd_bore_3_array(cb_array_15),
    .sigFromSrams_bore_ram_hold(sg[12][0]), .sigFromSrams_bore_ram_bypass(sg[12][1]), .sigFromSrams_bore_ram_bp_clken(sg[12][2]), .sigFromSrams_bore_ram_aux_clk(sg[12][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[12][4]), .sigFromSrams_bore_ram_mcp_hold(sg[12][5]), .sigFromSrams_bore_cgen(sg[12][6]),
    .sigFromSrams_bore_1_ram_hold(sg[13][0]), .sigFromSrams_bore_1_ram_bypass(sg[13][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[13][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[13][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[13][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[13][5]), .sigFromSrams_bore_1_cgen(sg[13][6]),
    .sigFromSrams_bore_2_ram_hold(sg[14][0]), .sigFromSrams_bore_2_ram_bypass(sg[14][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[14][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[14][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[14][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[14][5]), .sigFromSrams_bore_2_cgen(sg[14][6]),
    .sigFromSrams_bore_3_ram_hold(sg[15][0]), .sigFromSrams_bore_3_ram_bypass(sg[15][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[15][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[15][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[15][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[15][5]), .sigFromSrams_bore_3_cgen(sg[15][6])
  );
  DataSRAMBank_4 data_banks_0_4 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[4]), .io_w_addr(c_sram_w_addr[4]), .io_w_way_en(c_sram_w_way_en[4]), .io_w_data(c_sram_w_data[4]),
    .io_r_en(c_sram_r_en[4]), .io_r_addr(c_sram_r_addr[4]),
    .io_r_data_0(c_sram_r_data[4][0]), .io_r_data_1(c_sram_r_data[4][1]), .io_r_data_2(c_sram_r_data[4][2]), .io_r_data_3(c_sram_r_data[4][3]),
    .boreChildrenBd_bore_addr(cb_addr[16]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[16]), .boreChildrenBd_bore_wdata(cb_wdata[16]), .boreChildrenBd_bore_wmask(cb_wmask[16]), .boreChildrenBd_bore_re(cb_re[16]), .boreChildrenBd_bore_we(cb_we[16]), .boreChildrenBd_bore_rdata(cb_rdata[16]), .boreChildrenBd_bore_ack(cb_ack[16]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[16]), .boreChildrenBd_bore_array(cb_array_16),
    .boreChildrenBd_bore_1_addr(cb_addr[17]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[17]), .boreChildrenBd_bore_1_wdata(cb_wdata[17]), .boreChildrenBd_bore_1_wmask(cb_wmask[17]), .boreChildrenBd_bore_1_re(cb_re[17]), .boreChildrenBd_bore_1_we(cb_we[17]), .boreChildrenBd_bore_1_rdata(cb_rdata[17]), .boreChildrenBd_bore_1_ack(cb_ack[17]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[17]), .boreChildrenBd_bore_1_array(cb_array_17),
    .boreChildrenBd_bore_2_addr(cb_addr[18]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[18]), .boreChildrenBd_bore_2_wdata(cb_wdata[18]), .boreChildrenBd_bore_2_wmask(cb_wmask[18]), .boreChildrenBd_bore_2_re(cb_re[18]), .boreChildrenBd_bore_2_we(cb_we[18]), .boreChildrenBd_bore_2_rdata(cb_rdata[18]), .boreChildrenBd_bore_2_ack(cb_ack[18]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[18]), .boreChildrenBd_bore_2_array(cb_array_18),
    .boreChildrenBd_bore_3_addr(cb_addr[19]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[19]), .boreChildrenBd_bore_3_wdata(cb_wdata[19]), .boreChildrenBd_bore_3_wmask(cb_wmask[19]), .boreChildrenBd_bore_3_re(cb_re[19]), .boreChildrenBd_bore_3_we(cb_we[19]), .boreChildrenBd_bore_3_rdata(cb_rdata[19]), .boreChildrenBd_bore_3_ack(cb_ack[19]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[19]), .boreChildrenBd_bore_3_array(cb_array_19),
    .sigFromSrams_bore_ram_hold(sg[16][0]), .sigFromSrams_bore_ram_bypass(sg[16][1]), .sigFromSrams_bore_ram_bp_clken(sg[16][2]), .sigFromSrams_bore_ram_aux_clk(sg[16][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[16][4]), .sigFromSrams_bore_ram_mcp_hold(sg[16][5]), .sigFromSrams_bore_cgen(sg[16][6]),
    .sigFromSrams_bore_1_ram_hold(sg[17][0]), .sigFromSrams_bore_1_ram_bypass(sg[17][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[17][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[17][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[17][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[17][5]), .sigFromSrams_bore_1_cgen(sg[17][6]),
    .sigFromSrams_bore_2_ram_hold(sg[18][0]), .sigFromSrams_bore_2_ram_bypass(sg[18][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[18][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[18][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[18][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[18][5]), .sigFromSrams_bore_2_cgen(sg[18][6]),
    .sigFromSrams_bore_3_ram_hold(sg[19][0]), .sigFromSrams_bore_3_ram_bypass(sg[19][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[19][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[19][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[19][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[19][5]), .sigFromSrams_bore_3_cgen(sg[19][6])
  );
  DataSRAMBank_4 data_banks_0_5 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[5]), .io_w_addr(c_sram_w_addr[5]), .io_w_way_en(c_sram_w_way_en[5]), .io_w_data(c_sram_w_data[5]),
    .io_r_en(c_sram_r_en[5]), .io_r_addr(c_sram_r_addr[5]),
    .io_r_data_0(c_sram_r_data[5][0]), .io_r_data_1(c_sram_r_data[5][1]), .io_r_data_2(c_sram_r_data[5][2]), .io_r_data_3(c_sram_r_data[5][3]),
    .boreChildrenBd_bore_addr(cb_addr[20]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[20]), .boreChildrenBd_bore_wdata(cb_wdata[20]), .boreChildrenBd_bore_wmask(cb_wmask[20]), .boreChildrenBd_bore_re(cb_re[20]), .boreChildrenBd_bore_we(cb_we[20]), .boreChildrenBd_bore_rdata(cb_rdata[20]), .boreChildrenBd_bore_ack(cb_ack[20]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[20]), .boreChildrenBd_bore_array(cb_array_20),
    .boreChildrenBd_bore_1_addr(cb_addr[21]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[21]), .boreChildrenBd_bore_1_wdata(cb_wdata[21]), .boreChildrenBd_bore_1_wmask(cb_wmask[21]), .boreChildrenBd_bore_1_re(cb_re[21]), .boreChildrenBd_bore_1_we(cb_we[21]), .boreChildrenBd_bore_1_rdata(cb_rdata[21]), .boreChildrenBd_bore_1_ack(cb_ack[21]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[21]), .boreChildrenBd_bore_1_array(cb_array_21),
    .boreChildrenBd_bore_2_addr(cb_addr[22]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[22]), .boreChildrenBd_bore_2_wdata(cb_wdata[22]), .boreChildrenBd_bore_2_wmask(cb_wmask[22]), .boreChildrenBd_bore_2_re(cb_re[22]), .boreChildrenBd_bore_2_we(cb_we[22]), .boreChildrenBd_bore_2_rdata(cb_rdata[22]), .boreChildrenBd_bore_2_ack(cb_ack[22]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[22]), .boreChildrenBd_bore_2_array(cb_array_22),
    .boreChildrenBd_bore_3_addr(cb_addr[23]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[23]), .boreChildrenBd_bore_3_wdata(cb_wdata[23]), .boreChildrenBd_bore_3_wmask(cb_wmask[23]), .boreChildrenBd_bore_3_re(cb_re[23]), .boreChildrenBd_bore_3_we(cb_we[23]), .boreChildrenBd_bore_3_rdata(cb_rdata[23]), .boreChildrenBd_bore_3_ack(cb_ack[23]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[23]), .boreChildrenBd_bore_3_array(cb_array_23),
    .sigFromSrams_bore_ram_hold(sg[20][0]), .sigFromSrams_bore_ram_bypass(sg[20][1]), .sigFromSrams_bore_ram_bp_clken(sg[20][2]), .sigFromSrams_bore_ram_aux_clk(sg[20][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[20][4]), .sigFromSrams_bore_ram_mcp_hold(sg[20][5]), .sigFromSrams_bore_cgen(sg[20][6]),
    .sigFromSrams_bore_1_ram_hold(sg[21][0]), .sigFromSrams_bore_1_ram_bypass(sg[21][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[21][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[21][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[21][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[21][5]), .sigFromSrams_bore_1_cgen(sg[21][6]),
    .sigFromSrams_bore_2_ram_hold(sg[22][0]), .sigFromSrams_bore_2_ram_bypass(sg[22][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[22][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[22][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[22][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[22][5]), .sigFromSrams_bore_2_cgen(sg[22][6]),
    .sigFromSrams_bore_3_ram_hold(sg[23][0]), .sigFromSrams_bore_3_ram_bypass(sg[23][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[23][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[23][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[23][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[23][5]), .sigFromSrams_bore_3_cgen(sg[23][6])
  );
  DataSRAMBank_4 data_banks_0_6 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[6]), .io_w_addr(c_sram_w_addr[6]), .io_w_way_en(c_sram_w_way_en[6]), .io_w_data(c_sram_w_data[6]),
    .io_r_en(c_sram_r_en[6]), .io_r_addr(c_sram_r_addr[6]),
    .io_r_data_0(c_sram_r_data[6][0]), .io_r_data_1(c_sram_r_data[6][1]), .io_r_data_2(c_sram_r_data[6][2]), .io_r_data_3(c_sram_r_data[6][3]),
    .boreChildrenBd_bore_addr(cb_addr[24]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[24]), .boreChildrenBd_bore_wdata(cb_wdata[24]), .boreChildrenBd_bore_wmask(cb_wmask[24]), .boreChildrenBd_bore_re(cb_re[24]), .boreChildrenBd_bore_we(cb_we[24]), .boreChildrenBd_bore_rdata(cb_rdata[24]), .boreChildrenBd_bore_ack(cb_ack[24]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[24]), .boreChildrenBd_bore_array(cb_array_24),
    .boreChildrenBd_bore_1_addr(cb_addr[25]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[25]), .boreChildrenBd_bore_1_wdata(cb_wdata[25]), .boreChildrenBd_bore_1_wmask(cb_wmask[25]), .boreChildrenBd_bore_1_re(cb_re[25]), .boreChildrenBd_bore_1_we(cb_we[25]), .boreChildrenBd_bore_1_rdata(cb_rdata[25]), .boreChildrenBd_bore_1_ack(cb_ack[25]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[25]), .boreChildrenBd_bore_1_array(cb_array_25),
    .boreChildrenBd_bore_2_addr(cb_addr[26]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[26]), .boreChildrenBd_bore_2_wdata(cb_wdata[26]), .boreChildrenBd_bore_2_wmask(cb_wmask[26]), .boreChildrenBd_bore_2_re(cb_re[26]), .boreChildrenBd_bore_2_we(cb_we[26]), .boreChildrenBd_bore_2_rdata(cb_rdata[26]), .boreChildrenBd_bore_2_ack(cb_ack[26]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[26]), .boreChildrenBd_bore_2_array(cb_array_26),
    .boreChildrenBd_bore_3_addr(cb_addr[27]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[27]), .boreChildrenBd_bore_3_wdata(cb_wdata[27]), .boreChildrenBd_bore_3_wmask(cb_wmask[27]), .boreChildrenBd_bore_3_re(cb_re[27]), .boreChildrenBd_bore_3_we(cb_we[27]), .boreChildrenBd_bore_3_rdata(cb_rdata[27]), .boreChildrenBd_bore_3_ack(cb_ack[27]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[27]), .boreChildrenBd_bore_3_array(cb_array_27),
    .sigFromSrams_bore_ram_hold(sg[24][0]), .sigFromSrams_bore_ram_bypass(sg[24][1]), .sigFromSrams_bore_ram_bp_clken(sg[24][2]), .sigFromSrams_bore_ram_aux_clk(sg[24][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[24][4]), .sigFromSrams_bore_ram_mcp_hold(sg[24][5]), .sigFromSrams_bore_cgen(sg[24][6]),
    .sigFromSrams_bore_1_ram_hold(sg[25][0]), .sigFromSrams_bore_1_ram_bypass(sg[25][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[25][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[25][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[25][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[25][5]), .sigFromSrams_bore_1_cgen(sg[25][6]),
    .sigFromSrams_bore_2_ram_hold(sg[26][0]), .sigFromSrams_bore_2_ram_bypass(sg[26][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[26][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[26][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[26][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[26][5]), .sigFromSrams_bore_2_cgen(sg[26][6]),
    .sigFromSrams_bore_3_ram_hold(sg[27][0]), .sigFromSrams_bore_3_ram_bypass(sg[27][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[27][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[27][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[27][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[27][5]), .sigFromSrams_bore_3_cgen(sg[27][6])
  );
  DataSRAMBank_4 data_banks_0_7 (
    .clock(clock), .reset(reset),
    .io_w_en(c_sram_w_en[7]), .io_w_addr(c_sram_w_addr[7]), .io_w_way_en(c_sram_w_way_en[7]), .io_w_data(c_sram_w_data[7]),
    .io_r_en(c_sram_r_en[7]), .io_r_addr(c_sram_r_addr[7]),
    .io_r_data_0(c_sram_r_data[7][0]), .io_r_data_1(c_sram_r_data[7][1]), .io_r_data_2(c_sram_r_data[7][2]), .io_r_data_3(c_sram_r_data[7][3]),
    .boreChildrenBd_bore_addr(cb_addr[28]), .boreChildrenBd_bore_addr_rd(cb_addr_rd[28]), .boreChildrenBd_bore_wdata(cb_wdata[28]), .boreChildrenBd_bore_wmask(cb_wmask[28]), .boreChildrenBd_bore_re(cb_re[28]), .boreChildrenBd_bore_we(cb_we[28]), .boreChildrenBd_bore_rdata(cb_rdata[28]), .boreChildrenBd_bore_ack(cb_ack[28]), .boreChildrenBd_bore_selectedOH(cb_selectedOH[28]), .boreChildrenBd_bore_array(cb_array_28),
    .boreChildrenBd_bore_1_addr(cb_addr[29]), .boreChildrenBd_bore_1_addr_rd(cb_addr_rd[29]), .boreChildrenBd_bore_1_wdata(cb_wdata[29]), .boreChildrenBd_bore_1_wmask(cb_wmask[29]), .boreChildrenBd_bore_1_re(cb_re[29]), .boreChildrenBd_bore_1_we(cb_we[29]), .boreChildrenBd_bore_1_rdata(cb_rdata[29]), .boreChildrenBd_bore_1_ack(cb_ack[29]), .boreChildrenBd_bore_1_selectedOH(cb_selectedOH[29]), .boreChildrenBd_bore_1_array(cb_array_29),
    .boreChildrenBd_bore_2_addr(cb_addr[30]), .boreChildrenBd_bore_2_addr_rd(cb_addr_rd[30]), .boreChildrenBd_bore_2_wdata(cb_wdata[30]), .boreChildrenBd_bore_2_wmask(cb_wmask[30]), .boreChildrenBd_bore_2_re(cb_re[30]), .boreChildrenBd_bore_2_we(cb_we[30]), .boreChildrenBd_bore_2_rdata(cb_rdata[30]), .boreChildrenBd_bore_2_ack(cb_ack[30]), .boreChildrenBd_bore_2_selectedOH(cb_selectedOH[30]), .boreChildrenBd_bore_2_array(cb_array_30),
    .boreChildrenBd_bore_3_addr(cb_addr[31]), .boreChildrenBd_bore_3_addr_rd(cb_addr_rd[31]), .boreChildrenBd_bore_3_wdata(cb_wdata[31]), .boreChildrenBd_bore_3_wmask(cb_wmask[31]), .boreChildrenBd_bore_3_re(cb_re[31]), .boreChildrenBd_bore_3_we(cb_we[31]), .boreChildrenBd_bore_3_rdata(cb_rdata[31]), .boreChildrenBd_bore_3_ack(cb_ack[31]), .boreChildrenBd_bore_3_selectedOH(cb_selectedOH[31]), .boreChildrenBd_bore_3_array(cb_array_31),
    .sigFromSrams_bore_ram_hold(sg[28][0]), .sigFromSrams_bore_ram_bypass(sg[28][1]), .sigFromSrams_bore_ram_bp_clken(sg[28][2]), .sigFromSrams_bore_ram_aux_clk(sg[28][3]), .sigFromSrams_bore_ram_aux_ckbp(sg[28][4]), .sigFromSrams_bore_ram_mcp_hold(sg[28][5]), .sigFromSrams_bore_cgen(sg[28][6]),
    .sigFromSrams_bore_1_ram_hold(sg[29][0]), .sigFromSrams_bore_1_ram_bypass(sg[29][1]), .sigFromSrams_bore_1_ram_bp_clken(sg[29][2]), .sigFromSrams_bore_1_ram_aux_clk(sg[29][3]), .sigFromSrams_bore_1_ram_aux_ckbp(sg[29][4]), .sigFromSrams_bore_1_ram_mcp_hold(sg[29][5]), .sigFromSrams_bore_1_cgen(sg[29][6]),
    .sigFromSrams_bore_2_ram_hold(sg[30][0]), .sigFromSrams_bore_2_ram_bypass(sg[30][1]), .sigFromSrams_bore_2_ram_bp_clken(sg[30][2]), .sigFromSrams_bore_2_ram_aux_clk(sg[30][3]), .sigFromSrams_bore_2_ram_aux_ckbp(sg[30][4]), .sigFromSrams_bore_2_ram_mcp_hold(sg[30][5]), .sigFromSrams_bore_2_cgen(sg[30][6]),
    .sigFromSrams_bore_3_ram_hold(sg[31][0]), .sigFromSrams_bore_3_ram_bypass(sg[31][1]), .sigFromSrams_bore_3_ram_bp_clken(sg[31][2]), .sigFromSrams_bore_3_ram_aux_clk(sg[31][3]), .sigFromSrams_bore_3_ram_aux_ckbp(sg[31][4]), .sigFromSrams_bore_3_ram_mcp_hold(sg[31][5]), .sigFromSrams_bore_3_cgen(sg[31][6])
  );

  MbistPipeDCacheData mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all), .mbist_req(boreChildrenBd_bore_req), .mbist_ack(c_mbist_ack_pl),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be), .mbist_addr(boreChildrenBd_bore_addr),
    .mbist_indata(boreChildrenBd_bore_indata), .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd), .mbist_outdata(boreChildrenBd_bore_outdata),
    .toSRAM_0_addr(cb_addr[0]), .toSRAM_0_addr_rd(cb_addr_rd[0]), .toSRAM_0_wdata(cb_wdata[0]), .toSRAM_0_wmask(cb_wmask[0]), .toSRAM_0_re(cb_re[0]), .toSRAM_0_we(cb_we[0]), .toSRAM_0_rdata(cb_rdata[0]), .toSRAM_0_ack(cb_ack[0]), .toSRAM_0_selectedOH(cb_selectedOH[0]), .toSRAM_0_array(cb_array_0),
    .toSRAM_1_addr(cb_addr[1]), .toSRAM_1_addr_rd(cb_addr_rd[1]), .toSRAM_1_wdata(cb_wdata[1]), .toSRAM_1_wmask(cb_wmask[1]), .toSRAM_1_re(cb_re[1]), .toSRAM_1_we(cb_we[1]), .toSRAM_1_rdata(cb_rdata[1]), .toSRAM_1_ack(cb_ack[1]), .toSRAM_1_selectedOH(cb_selectedOH[1]), .toSRAM_1_array(cb_array_1),
    .toSRAM_2_addr(cb_addr[2]), .toSRAM_2_addr_rd(cb_addr_rd[2]), .toSRAM_2_wdata(cb_wdata[2]), .toSRAM_2_wmask(cb_wmask[2]), .toSRAM_2_re(cb_re[2]), .toSRAM_2_we(cb_we[2]), .toSRAM_2_rdata(cb_rdata[2]), .toSRAM_2_ack(cb_ack[2]), .toSRAM_2_selectedOH(cb_selectedOH[2]), .toSRAM_2_array(cb_array_2),
    .toSRAM_3_addr(cb_addr[3]), .toSRAM_3_addr_rd(cb_addr_rd[3]), .toSRAM_3_wdata(cb_wdata[3]), .toSRAM_3_wmask(cb_wmask[3]), .toSRAM_3_re(cb_re[3]), .toSRAM_3_we(cb_we[3]), .toSRAM_3_rdata(cb_rdata[3]), .toSRAM_3_ack(cb_ack[3]), .toSRAM_3_selectedOH(cb_selectedOH[3]), .toSRAM_3_array(cb_array_3),
    .toSRAM_4_addr(cb_addr[4]), .toSRAM_4_addr_rd(cb_addr_rd[4]), .toSRAM_4_wdata(cb_wdata[4]), .toSRAM_4_wmask(cb_wmask[4]), .toSRAM_4_re(cb_re[4]), .toSRAM_4_we(cb_we[4]), .toSRAM_4_rdata(cb_rdata[4]), .toSRAM_4_ack(cb_ack[4]), .toSRAM_4_selectedOH(cb_selectedOH[4]), .toSRAM_4_array(cb_array_4),
    .toSRAM_5_addr(cb_addr[5]), .toSRAM_5_addr_rd(cb_addr_rd[5]), .toSRAM_5_wdata(cb_wdata[5]), .toSRAM_5_wmask(cb_wmask[5]), .toSRAM_5_re(cb_re[5]), .toSRAM_5_we(cb_we[5]), .toSRAM_5_rdata(cb_rdata[5]), .toSRAM_5_ack(cb_ack[5]), .toSRAM_5_selectedOH(cb_selectedOH[5]), .toSRAM_5_array(cb_array_5),
    .toSRAM_6_addr(cb_addr[6]), .toSRAM_6_addr_rd(cb_addr_rd[6]), .toSRAM_6_wdata(cb_wdata[6]), .toSRAM_6_wmask(cb_wmask[6]), .toSRAM_6_re(cb_re[6]), .toSRAM_6_we(cb_we[6]), .toSRAM_6_rdata(cb_rdata[6]), .toSRAM_6_ack(cb_ack[6]), .toSRAM_6_selectedOH(cb_selectedOH[6]), .toSRAM_6_array(cb_array_6),
    .toSRAM_7_addr(cb_addr[7]), .toSRAM_7_addr_rd(cb_addr_rd[7]), .toSRAM_7_wdata(cb_wdata[7]), .toSRAM_7_wmask(cb_wmask[7]), .toSRAM_7_re(cb_re[7]), .toSRAM_7_we(cb_we[7]), .toSRAM_7_rdata(cb_rdata[7]), .toSRAM_7_ack(cb_ack[7]), .toSRAM_7_selectedOH(cb_selectedOH[7]), .toSRAM_7_array(cb_array_7),
    .toSRAM_8_addr(cb_addr[8]), .toSRAM_8_addr_rd(cb_addr_rd[8]), .toSRAM_8_wdata(cb_wdata[8]), .toSRAM_8_wmask(cb_wmask[8]), .toSRAM_8_re(cb_re[8]), .toSRAM_8_we(cb_we[8]), .toSRAM_8_rdata(cb_rdata[8]), .toSRAM_8_ack(cb_ack[8]), .toSRAM_8_selectedOH(cb_selectedOH[8]), .toSRAM_8_array(cb_array_8),
    .toSRAM_9_addr(cb_addr[9]), .toSRAM_9_addr_rd(cb_addr_rd[9]), .toSRAM_9_wdata(cb_wdata[9]), .toSRAM_9_wmask(cb_wmask[9]), .toSRAM_9_re(cb_re[9]), .toSRAM_9_we(cb_we[9]), .toSRAM_9_rdata(cb_rdata[9]), .toSRAM_9_ack(cb_ack[9]), .toSRAM_9_selectedOH(cb_selectedOH[9]), .toSRAM_9_array(cb_array_9),
    .toSRAM_10_addr(cb_addr[10]), .toSRAM_10_addr_rd(cb_addr_rd[10]), .toSRAM_10_wdata(cb_wdata[10]), .toSRAM_10_wmask(cb_wmask[10]), .toSRAM_10_re(cb_re[10]), .toSRAM_10_we(cb_we[10]), .toSRAM_10_rdata(cb_rdata[10]), .toSRAM_10_ack(cb_ack[10]), .toSRAM_10_selectedOH(cb_selectedOH[10]), .toSRAM_10_array(cb_array_10),
    .toSRAM_11_addr(cb_addr[11]), .toSRAM_11_addr_rd(cb_addr_rd[11]), .toSRAM_11_wdata(cb_wdata[11]), .toSRAM_11_wmask(cb_wmask[11]), .toSRAM_11_re(cb_re[11]), .toSRAM_11_we(cb_we[11]), .toSRAM_11_rdata(cb_rdata[11]), .toSRAM_11_ack(cb_ack[11]), .toSRAM_11_selectedOH(cb_selectedOH[11]), .toSRAM_11_array(cb_array_11),
    .toSRAM_12_addr(cb_addr[12]), .toSRAM_12_addr_rd(cb_addr_rd[12]), .toSRAM_12_wdata(cb_wdata[12]), .toSRAM_12_wmask(cb_wmask[12]), .toSRAM_12_re(cb_re[12]), .toSRAM_12_we(cb_we[12]), .toSRAM_12_rdata(cb_rdata[12]), .toSRAM_12_ack(cb_ack[12]), .toSRAM_12_selectedOH(cb_selectedOH[12]), .toSRAM_12_array(cb_array_12),
    .toSRAM_13_addr(cb_addr[13]), .toSRAM_13_addr_rd(cb_addr_rd[13]), .toSRAM_13_wdata(cb_wdata[13]), .toSRAM_13_wmask(cb_wmask[13]), .toSRAM_13_re(cb_re[13]), .toSRAM_13_we(cb_we[13]), .toSRAM_13_rdata(cb_rdata[13]), .toSRAM_13_ack(cb_ack[13]), .toSRAM_13_selectedOH(cb_selectedOH[13]), .toSRAM_13_array(cb_array_13),
    .toSRAM_14_addr(cb_addr[14]), .toSRAM_14_addr_rd(cb_addr_rd[14]), .toSRAM_14_wdata(cb_wdata[14]), .toSRAM_14_wmask(cb_wmask[14]), .toSRAM_14_re(cb_re[14]), .toSRAM_14_we(cb_we[14]), .toSRAM_14_rdata(cb_rdata[14]), .toSRAM_14_ack(cb_ack[14]), .toSRAM_14_selectedOH(cb_selectedOH[14]), .toSRAM_14_array(cb_array_14),
    .toSRAM_15_addr(cb_addr[15]), .toSRAM_15_addr_rd(cb_addr_rd[15]), .toSRAM_15_wdata(cb_wdata[15]), .toSRAM_15_wmask(cb_wmask[15]), .toSRAM_15_re(cb_re[15]), .toSRAM_15_we(cb_we[15]), .toSRAM_15_rdata(cb_rdata[15]), .toSRAM_15_ack(cb_ack[15]), .toSRAM_15_selectedOH(cb_selectedOH[15]), .toSRAM_15_array(cb_array_15),
    .toSRAM_16_addr(cb_addr[16]), .toSRAM_16_addr_rd(cb_addr_rd[16]), .toSRAM_16_wdata(cb_wdata[16]), .toSRAM_16_wmask(cb_wmask[16]), .toSRAM_16_re(cb_re[16]), .toSRAM_16_we(cb_we[16]), .toSRAM_16_rdata(cb_rdata[16]), .toSRAM_16_ack(cb_ack[16]), .toSRAM_16_selectedOH(cb_selectedOH[16]), .toSRAM_16_array(cb_array_16),
    .toSRAM_17_addr(cb_addr[17]), .toSRAM_17_addr_rd(cb_addr_rd[17]), .toSRAM_17_wdata(cb_wdata[17]), .toSRAM_17_wmask(cb_wmask[17]), .toSRAM_17_re(cb_re[17]), .toSRAM_17_we(cb_we[17]), .toSRAM_17_rdata(cb_rdata[17]), .toSRAM_17_ack(cb_ack[17]), .toSRAM_17_selectedOH(cb_selectedOH[17]), .toSRAM_17_array(cb_array_17),
    .toSRAM_18_addr(cb_addr[18]), .toSRAM_18_addr_rd(cb_addr_rd[18]), .toSRAM_18_wdata(cb_wdata[18]), .toSRAM_18_wmask(cb_wmask[18]), .toSRAM_18_re(cb_re[18]), .toSRAM_18_we(cb_we[18]), .toSRAM_18_rdata(cb_rdata[18]), .toSRAM_18_ack(cb_ack[18]), .toSRAM_18_selectedOH(cb_selectedOH[18]), .toSRAM_18_array(cb_array_18),
    .toSRAM_19_addr(cb_addr[19]), .toSRAM_19_addr_rd(cb_addr_rd[19]), .toSRAM_19_wdata(cb_wdata[19]), .toSRAM_19_wmask(cb_wmask[19]), .toSRAM_19_re(cb_re[19]), .toSRAM_19_we(cb_we[19]), .toSRAM_19_rdata(cb_rdata[19]), .toSRAM_19_ack(cb_ack[19]), .toSRAM_19_selectedOH(cb_selectedOH[19]), .toSRAM_19_array(cb_array_19),
    .toSRAM_20_addr(cb_addr[20]), .toSRAM_20_addr_rd(cb_addr_rd[20]), .toSRAM_20_wdata(cb_wdata[20]), .toSRAM_20_wmask(cb_wmask[20]), .toSRAM_20_re(cb_re[20]), .toSRAM_20_we(cb_we[20]), .toSRAM_20_rdata(cb_rdata[20]), .toSRAM_20_ack(cb_ack[20]), .toSRAM_20_selectedOH(cb_selectedOH[20]), .toSRAM_20_array(cb_array_20),
    .toSRAM_21_addr(cb_addr[21]), .toSRAM_21_addr_rd(cb_addr_rd[21]), .toSRAM_21_wdata(cb_wdata[21]), .toSRAM_21_wmask(cb_wmask[21]), .toSRAM_21_re(cb_re[21]), .toSRAM_21_we(cb_we[21]), .toSRAM_21_rdata(cb_rdata[21]), .toSRAM_21_ack(cb_ack[21]), .toSRAM_21_selectedOH(cb_selectedOH[21]), .toSRAM_21_array(cb_array_21),
    .toSRAM_22_addr(cb_addr[22]), .toSRAM_22_addr_rd(cb_addr_rd[22]), .toSRAM_22_wdata(cb_wdata[22]), .toSRAM_22_wmask(cb_wmask[22]), .toSRAM_22_re(cb_re[22]), .toSRAM_22_we(cb_we[22]), .toSRAM_22_rdata(cb_rdata[22]), .toSRAM_22_ack(cb_ack[22]), .toSRAM_22_selectedOH(cb_selectedOH[22]), .toSRAM_22_array(cb_array_22),
    .toSRAM_23_addr(cb_addr[23]), .toSRAM_23_addr_rd(cb_addr_rd[23]), .toSRAM_23_wdata(cb_wdata[23]), .toSRAM_23_wmask(cb_wmask[23]), .toSRAM_23_re(cb_re[23]), .toSRAM_23_we(cb_we[23]), .toSRAM_23_rdata(cb_rdata[23]), .toSRAM_23_ack(cb_ack[23]), .toSRAM_23_selectedOH(cb_selectedOH[23]), .toSRAM_23_array(cb_array_23),
    .toSRAM_24_addr(cb_addr[24]), .toSRAM_24_addr_rd(cb_addr_rd[24]), .toSRAM_24_wdata(cb_wdata[24]), .toSRAM_24_wmask(cb_wmask[24]), .toSRAM_24_re(cb_re[24]), .toSRAM_24_we(cb_we[24]), .toSRAM_24_rdata(cb_rdata[24]), .toSRAM_24_ack(cb_ack[24]), .toSRAM_24_selectedOH(cb_selectedOH[24]), .toSRAM_24_array(cb_array_24),
    .toSRAM_25_addr(cb_addr[25]), .toSRAM_25_addr_rd(cb_addr_rd[25]), .toSRAM_25_wdata(cb_wdata[25]), .toSRAM_25_wmask(cb_wmask[25]), .toSRAM_25_re(cb_re[25]), .toSRAM_25_we(cb_we[25]), .toSRAM_25_rdata(cb_rdata[25]), .toSRAM_25_ack(cb_ack[25]), .toSRAM_25_selectedOH(cb_selectedOH[25]), .toSRAM_25_array(cb_array_25),
    .toSRAM_26_addr(cb_addr[26]), .toSRAM_26_addr_rd(cb_addr_rd[26]), .toSRAM_26_wdata(cb_wdata[26]), .toSRAM_26_wmask(cb_wmask[26]), .toSRAM_26_re(cb_re[26]), .toSRAM_26_we(cb_we[26]), .toSRAM_26_rdata(cb_rdata[26]), .toSRAM_26_ack(cb_ack[26]), .toSRAM_26_selectedOH(cb_selectedOH[26]), .toSRAM_26_array(cb_array_26),
    .toSRAM_27_addr(cb_addr[27]), .toSRAM_27_addr_rd(cb_addr_rd[27]), .toSRAM_27_wdata(cb_wdata[27]), .toSRAM_27_wmask(cb_wmask[27]), .toSRAM_27_re(cb_re[27]), .toSRAM_27_we(cb_we[27]), .toSRAM_27_rdata(cb_rdata[27]), .toSRAM_27_ack(cb_ack[27]), .toSRAM_27_selectedOH(cb_selectedOH[27]), .toSRAM_27_array(cb_array_27),
    .toSRAM_28_addr(cb_addr[28]), .toSRAM_28_addr_rd(cb_addr_rd[28]), .toSRAM_28_wdata(cb_wdata[28]), .toSRAM_28_wmask(cb_wmask[28]), .toSRAM_28_re(cb_re[28]), .toSRAM_28_we(cb_we[28]), .toSRAM_28_rdata(cb_rdata[28]), .toSRAM_28_ack(cb_ack[28]), .toSRAM_28_selectedOH(cb_selectedOH[28]), .toSRAM_28_array(cb_array_28),
    .toSRAM_29_addr(cb_addr[29]), .toSRAM_29_addr_rd(cb_addr_rd[29]), .toSRAM_29_wdata(cb_wdata[29]), .toSRAM_29_wmask(cb_wmask[29]), .toSRAM_29_re(cb_re[29]), .toSRAM_29_we(cb_we[29]), .toSRAM_29_rdata(cb_rdata[29]), .toSRAM_29_ack(cb_ack[29]), .toSRAM_29_selectedOH(cb_selectedOH[29]), .toSRAM_29_array(cb_array_29),
    .toSRAM_30_addr(cb_addr[30]), .toSRAM_30_addr_rd(cb_addr_rd[30]), .toSRAM_30_wdata(cb_wdata[30]), .toSRAM_30_wmask(cb_wmask[30]), .toSRAM_30_re(cb_re[30]), .toSRAM_30_we(cb_we[30]), .toSRAM_30_rdata(cb_rdata[30]), .toSRAM_30_ack(cb_ack[30]), .toSRAM_30_selectedOH(cb_selectedOH[30]), .toSRAM_30_array(cb_array_30),
    .toSRAM_31_addr(cb_addr[31]), .toSRAM_31_addr_rd(cb_addr_rd[31]), .toSRAM_31_wdata(cb_wdata[31]), .toSRAM_31_wmask(cb_wmask[31]), .toSRAM_31_re(cb_re[31]), .toSRAM_31_we(cb_we[31]), .toSRAM_31_rdata(cb_rdata[31]), .toSRAM_31_ack(cb_ack[31]), .toSRAM_31_selectedOH(cb_selectedOH[31]), .toSRAM_31_array(cb_array_31)
  );
  assign c_mbist_ack = c_mbist_ack_pl; assign boreChildrenBd_bore_ack = c_mbist_ack_pl;

endmodule