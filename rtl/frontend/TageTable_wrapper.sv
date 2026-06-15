// 自动生成：scripts/gen_tagetable_wrappers.py —— 例化 xs_TageTable_core
module TageTable(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [255:0] io_req_bits_ghist,
  input [7:0] io_req_bits_folded_hist_hist_14_folded_hist,
  input [6:0] io_req_bits_folded_hist_hist_7_folded_hist,
  output io_resps_0_valid,
  output [2:0] io_resps_0_bits_ctr,
  output io_resps_0_bits_u,
  output io_resps_0_bits_unconf,
  output io_resps_1_valid,
  output [2:0] io_resps_1_bits_ctr,
  output io_resps_1_bits_u,
  output io_resps_1_bits_unconf,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_mask_0,
  input io_update_mask_1,
  input io_update_takens_0,
  input io_update_takens_1,
  input io_update_alloc_0,
  input io_update_alloc_1,
  input [2:0] io_update_oldCtrs_0,
  input [2:0] io_update_oldCtrs_1,
  input io_update_uMask_0,
  input io_update_uMask_1,
  input io_update_us_0,
  input io_update_us_1,
  input io_update_reset_u_0,
  input io_update_reset_u_1,
  input [8:0] boreChildrenBd_bore_addr,
  input [8:0] boreChildrenBd_bore_addr_rd,
  input [15:0] boreChildrenBd_bore_wdata,
  input [15:0] boreChildrenBd_bore_wmask,
  input boreChildrenBd_bore_re,
  input boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_selectedOH,
  input [5:0] boreChildrenBd_bore_array,
  input [9:0] boreChildrenBd_bore_1_addr,
  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input [23:0] boreChildrenBd_bore_1_wdata,
  input [1:0] boreChildrenBd_bore_1_wmask,
  input boreChildrenBd_bore_1_re,
  input boreChildrenBd_bore_1_we,
  output [23:0] boreChildrenBd_bore_1_rdata,
  input boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_selectedOH,
  input [5:0] boreChildrenBd_bore_1_array,
  input [9:0] boreChildrenBd_bore_2_addr,
  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input [23:0] boreChildrenBd_bore_2_wdata,
  input [1:0] boreChildrenBd_bore_2_wmask,
  input boreChildrenBd_bore_2_re,
  input boreChildrenBd_bore_2_we,
  output [23:0] boreChildrenBd_bore_2_rdata,
  input boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_selectedOH,
  input [5:0] boreChildrenBd_bore_2_array,
  input [9:0] boreChildrenBd_bore_3_addr,
  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input [23:0] boreChildrenBd_bore_3_wdata,
  input [1:0] boreChildrenBd_bore_3_wmask,
  input boreChildrenBd_bore_3_re,
  input boreChildrenBd_bore_3_we,
  output [23:0] boreChildrenBd_bore_3_rdata,
  input boreChildrenBd_bore_3_ack,
  input boreChildrenBd_bore_3_selectedOH,
  input [5:0] boreChildrenBd_bore_3_array,
  input [9:0] boreChildrenBd_bore_4_addr,
  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input [23:0] boreChildrenBd_bore_4_wdata,
  input [1:0] boreChildrenBd_bore_4_wmask,
  input boreChildrenBd_bore_4_re,
  input boreChildrenBd_bore_4_we,
  output [23:0] boreChildrenBd_bore_4_rdata,
  input boreChildrenBd_bore_4_ack,
  input boreChildrenBd_bore_4_selectedOH,
  input [5:0] boreChildrenBd_bore_4_array,
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
  input sigFromSrams_bore_4_cgen
);
  // ---- bore_bank/sig_bank 打包（golden bore_1..4 → 数组 [0..3]）----
  wire [9:0]  bb_addr [4], bb_addr_rd [4];
  wire [23:0] bb_wdata [4];
  wire [1:0]  bb_wmask [4];
  wire        bb_re [4], bb_we [4], bb_ack [4], bb_sel [4];
  wire [23:0] bb_rdata [4];
  wire [5:0]  bb_array [4];
  wire [6:0]  sig_bk [4];
  assign bb_addr[0]=boreChildrenBd_bore_1_addr;    assign bb_addr_rd[0]=boreChildrenBd_bore_1_addr_rd;
  assign bb_wdata[0]=boreChildrenBd_bore_1_wdata;  assign bb_wmask[0]=boreChildrenBd_bore_1_wmask;
  assign bb_re[0]=boreChildrenBd_bore_1_re;        assign bb_we[0]=boreChildrenBd_bore_1_we;
  assign bb_ack[0]=boreChildrenBd_bore_1_ack;      assign bb_sel[0]=boreChildrenBd_bore_1_selectedOH;
  assign bb_array[0]=boreChildrenBd_bore_1_array;
  assign boreChildrenBd_bore_1_rdata=bb_rdata[0];
  assign sig_bk[0]={sigFromSrams_bore_1_cgen,sigFromSrams_bore_1_ram_mcp_hold,sigFromSrams_bore_1_ram_aux_ckbp,sigFromSrams_bore_1_ram_aux_clk,sigFromSrams_bore_1_ram_bp_clken,sigFromSrams_bore_1_ram_bypass,sigFromSrams_bore_1_ram_hold};
  assign bb_addr[1]=boreChildrenBd_bore_2_addr;    assign bb_addr_rd[1]=boreChildrenBd_bore_2_addr_rd;
  assign bb_wdata[1]=boreChildrenBd_bore_2_wdata;  assign bb_wmask[1]=boreChildrenBd_bore_2_wmask;
  assign bb_re[1]=boreChildrenBd_bore_2_re;        assign bb_we[1]=boreChildrenBd_bore_2_we;
  assign bb_ack[1]=boreChildrenBd_bore_2_ack;      assign bb_sel[1]=boreChildrenBd_bore_2_selectedOH;
  assign bb_array[1]=boreChildrenBd_bore_2_array;
  assign boreChildrenBd_bore_2_rdata=bb_rdata[1];
  assign sig_bk[1]={sigFromSrams_bore_2_cgen,sigFromSrams_bore_2_ram_mcp_hold,sigFromSrams_bore_2_ram_aux_ckbp,sigFromSrams_bore_2_ram_aux_clk,sigFromSrams_bore_2_ram_bp_clken,sigFromSrams_bore_2_ram_bypass,sigFromSrams_bore_2_ram_hold};
  assign bb_addr[2]=boreChildrenBd_bore_3_addr;    assign bb_addr_rd[2]=boreChildrenBd_bore_3_addr_rd;
  assign bb_wdata[2]=boreChildrenBd_bore_3_wdata;  assign bb_wmask[2]=boreChildrenBd_bore_3_wmask;
  assign bb_re[2]=boreChildrenBd_bore_3_re;        assign bb_we[2]=boreChildrenBd_bore_3_we;
  assign bb_ack[2]=boreChildrenBd_bore_3_ack;      assign bb_sel[2]=boreChildrenBd_bore_3_selectedOH;
  assign bb_array[2]=boreChildrenBd_bore_3_array;
  assign boreChildrenBd_bore_3_rdata=bb_rdata[2];
  assign sig_bk[2]={sigFromSrams_bore_3_cgen,sigFromSrams_bore_3_ram_mcp_hold,sigFromSrams_bore_3_ram_aux_ckbp,sigFromSrams_bore_3_ram_aux_clk,sigFromSrams_bore_3_ram_bp_clken,sigFromSrams_bore_3_ram_bypass,sigFromSrams_bore_3_ram_hold};
  assign bb_addr[3]=boreChildrenBd_bore_4_addr;    assign bb_addr_rd[3]=boreChildrenBd_bore_4_addr_rd;
  assign bb_wdata[3]=boreChildrenBd_bore_4_wdata;  assign bb_wmask[3]=boreChildrenBd_bore_4_wmask;
  assign bb_re[3]=boreChildrenBd_bore_4_re;        assign bb_we[3]=boreChildrenBd_bore_4_we;
  assign bb_ack[3]=boreChildrenBd_bore_4_ack;      assign bb_sel[3]=boreChildrenBd_bore_4_selectedOH;
  assign bb_array[3]=boreChildrenBd_bore_4_array;
  assign boreChildrenBd_bore_4_rdata=bb_rdata[3];
  assign sig_bk[3]={sigFromSrams_bore_4_cgen,sigFromSrams_bore_4_ram_mcp_hold,sigFromSrams_bore_4_ram_aux_ckbp,sigFromSrams_bore_4_ram_aux_clk,sigFromSrams_bore_4_ram_bp_clken,sigFromSrams_bore_4_ram_bypass,sigFromSrams_bore_4_ram_hold};
  xs_TageTable_core #(.HIST_LEN(8)) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc), .io_req_bits_ghist(io_req_bits_ghist),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_14_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_14_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_7_folded_hist),
    .io_resps_0_valid(io_resps_0_valid), .io_resps_0_bits_ctr(io_resps_0_bits_ctr),
    .io_resps_0_bits_u(io_resps_0_bits_u), .io_resps_0_bits_unconf(io_resps_0_bits_unconf),
    .io_resps_1_valid(io_resps_1_valid), .io_resps_1_bits_ctr(io_resps_1_bits_ctr),
    .io_resps_1_bits_u(io_resps_1_bits_u), .io_resps_1_bits_unconf(io_resps_1_bits_unconf),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .io_update_alloc_0(io_update_alloc_0), .io_update_alloc_1(io_update_alloc_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_uMask_0(io_update_uMask_0), .io_update_uMask_1(io_update_uMask_1),
    .io_update_us_0(io_update_us_0), .io_update_us_1(io_update_us_1),
    .io_update_reset_u_0(io_update_reset_u_0), .io_update_reset_u_1(io_update_reset_u_1),
    .bore_us_addr(boreChildrenBd_bore_addr), .bore_us_addr_rd(boreChildrenBd_bore_addr_rd),
    .bore_us_wdata(boreChildrenBd_bore_wdata), .bore_us_wmask(boreChildrenBd_bore_wmask),
    .bore_us_re(boreChildrenBd_bore_re), .bore_us_we(boreChildrenBd_bore_we),
    .bore_us_rdata(boreChildrenBd_bore_rdata), .bore_us_ack(boreChildrenBd_bore_ack),
    .bore_us_selectedOH(boreChildrenBd_bore_selectedOH), .bore_us_array(boreChildrenBd_bore_array),
    .bore_bank_addr(bb_addr), .bore_bank_addr_rd(bb_addr_rd),
    .bore_bank_wdata(bb_wdata), .bore_bank_wmask(bb_wmask),
    .bore_bank_re(bb_re), .bore_bank_we(bb_we), .bore_bank_rdata(bb_rdata),
    .bore_bank_ack(bb_ack), .bore_bank_selectedOH(bb_sel), .bore_bank_array(bb_array),
    .sig_us({sigFromSrams_bore_cgen,sigFromSrams_bore_ram_mcp_hold,sigFromSrams_bore_ram_aux_ckbp,sigFromSrams_bore_ram_aux_clk,sigFromSrams_bore_ram_bp_clken,sigFromSrams_bore_ram_bypass,sigFromSrams_bore_ram_hold}),
    .sig_bank(sig_bk)
  );
endmodule

module TageTable_1(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [255:0] io_req_bits_ghist,
  input [6:0] io_req_bits_folded_hist_hist_15_folded_hist,
  input [7:0] io_req_bits_folded_hist_hist_4_folded_hist,
  input [10:0] io_req_bits_folded_hist_hist_1_folded_hist,
  output io_resps_0_valid,
  output [2:0] io_resps_0_bits_ctr,
  output io_resps_0_bits_u,
  output io_resps_0_bits_unconf,
  output io_resps_1_valid,
  output [2:0] io_resps_1_bits_ctr,
  output io_resps_1_bits_u,
  output io_resps_1_bits_unconf,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_mask_0,
  input io_update_mask_1,
  input io_update_takens_0,
  input io_update_takens_1,
  input io_update_alloc_0,
  input io_update_alloc_1,
  input [2:0] io_update_oldCtrs_0,
  input [2:0] io_update_oldCtrs_1,
  input io_update_uMask_0,
  input io_update_uMask_1,
  input io_update_us_0,
  input io_update_us_1,
  input io_update_reset_u_0,
  input io_update_reset_u_1,
  input [8:0] boreChildrenBd_bore_addr,
  input [8:0] boreChildrenBd_bore_addr_rd,
  input [15:0] boreChildrenBd_bore_wdata,
  input [15:0] boreChildrenBd_bore_wmask,
  input boreChildrenBd_bore_re,
  input boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_selectedOH,
  input [5:0] boreChildrenBd_bore_array,
  input [9:0] boreChildrenBd_bore_1_addr,
  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input [23:0] boreChildrenBd_bore_1_wdata,
  input [1:0] boreChildrenBd_bore_1_wmask,
  input boreChildrenBd_bore_1_re,
  input boreChildrenBd_bore_1_we,
  output [23:0] boreChildrenBd_bore_1_rdata,
  input boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_selectedOH,
  input [5:0] boreChildrenBd_bore_1_array,
  input [9:0] boreChildrenBd_bore_2_addr,
  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input [23:0] boreChildrenBd_bore_2_wdata,
  input [1:0] boreChildrenBd_bore_2_wmask,
  input boreChildrenBd_bore_2_re,
  input boreChildrenBd_bore_2_we,
  output [23:0] boreChildrenBd_bore_2_rdata,
  input boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_selectedOH,
  input [5:0] boreChildrenBd_bore_2_array,
  input [9:0] boreChildrenBd_bore_3_addr,
  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input [23:0] boreChildrenBd_bore_3_wdata,
  input [1:0] boreChildrenBd_bore_3_wmask,
  input boreChildrenBd_bore_3_re,
  input boreChildrenBd_bore_3_we,
  output [23:0] boreChildrenBd_bore_3_rdata,
  input boreChildrenBd_bore_3_ack,
  input boreChildrenBd_bore_3_selectedOH,
  input [5:0] boreChildrenBd_bore_3_array,
  input [9:0] boreChildrenBd_bore_4_addr,
  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input [23:0] boreChildrenBd_bore_4_wdata,
  input [1:0] boreChildrenBd_bore_4_wmask,
  input boreChildrenBd_bore_4_re,
  input boreChildrenBd_bore_4_we,
  output [23:0] boreChildrenBd_bore_4_rdata,
  input boreChildrenBd_bore_4_ack,
  input boreChildrenBd_bore_4_selectedOH,
  input [5:0] boreChildrenBd_bore_4_array,
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
  input sigFromSrams_bore_4_cgen
);
  // ---- bore_bank/sig_bank 打包（golden bore_1..4 → 数组 [0..3]）----
  wire [9:0]  bb_addr [4], bb_addr_rd [4];
  wire [23:0] bb_wdata [4];
  wire [1:0]  bb_wmask [4];
  wire        bb_re [4], bb_we [4], bb_ack [4], bb_sel [4];
  wire [23:0] bb_rdata [4];
  wire [5:0]  bb_array [4];
  wire [6:0]  sig_bk [4];
  assign bb_addr[0]=boreChildrenBd_bore_1_addr;    assign bb_addr_rd[0]=boreChildrenBd_bore_1_addr_rd;
  assign bb_wdata[0]=boreChildrenBd_bore_1_wdata;  assign bb_wmask[0]=boreChildrenBd_bore_1_wmask;
  assign bb_re[0]=boreChildrenBd_bore_1_re;        assign bb_we[0]=boreChildrenBd_bore_1_we;
  assign bb_ack[0]=boreChildrenBd_bore_1_ack;      assign bb_sel[0]=boreChildrenBd_bore_1_selectedOH;
  assign bb_array[0]=boreChildrenBd_bore_1_array;
  assign boreChildrenBd_bore_1_rdata=bb_rdata[0];
  assign sig_bk[0]={sigFromSrams_bore_1_cgen,sigFromSrams_bore_1_ram_mcp_hold,sigFromSrams_bore_1_ram_aux_ckbp,sigFromSrams_bore_1_ram_aux_clk,sigFromSrams_bore_1_ram_bp_clken,sigFromSrams_bore_1_ram_bypass,sigFromSrams_bore_1_ram_hold};
  assign bb_addr[1]=boreChildrenBd_bore_2_addr;    assign bb_addr_rd[1]=boreChildrenBd_bore_2_addr_rd;
  assign bb_wdata[1]=boreChildrenBd_bore_2_wdata;  assign bb_wmask[1]=boreChildrenBd_bore_2_wmask;
  assign bb_re[1]=boreChildrenBd_bore_2_re;        assign bb_we[1]=boreChildrenBd_bore_2_we;
  assign bb_ack[1]=boreChildrenBd_bore_2_ack;      assign bb_sel[1]=boreChildrenBd_bore_2_selectedOH;
  assign bb_array[1]=boreChildrenBd_bore_2_array;
  assign boreChildrenBd_bore_2_rdata=bb_rdata[1];
  assign sig_bk[1]={sigFromSrams_bore_2_cgen,sigFromSrams_bore_2_ram_mcp_hold,sigFromSrams_bore_2_ram_aux_ckbp,sigFromSrams_bore_2_ram_aux_clk,sigFromSrams_bore_2_ram_bp_clken,sigFromSrams_bore_2_ram_bypass,sigFromSrams_bore_2_ram_hold};
  assign bb_addr[2]=boreChildrenBd_bore_3_addr;    assign bb_addr_rd[2]=boreChildrenBd_bore_3_addr_rd;
  assign bb_wdata[2]=boreChildrenBd_bore_3_wdata;  assign bb_wmask[2]=boreChildrenBd_bore_3_wmask;
  assign bb_re[2]=boreChildrenBd_bore_3_re;        assign bb_we[2]=boreChildrenBd_bore_3_we;
  assign bb_ack[2]=boreChildrenBd_bore_3_ack;      assign bb_sel[2]=boreChildrenBd_bore_3_selectedOH;
  assign bb_array[2]=boreChildrenBd_bore_3_array;
  assign boreChildrenBd_bore_3_rdata=bb_rdata[2];
  assign sig_bk[2]={sigFromSrams_bore_3_cgen,sigFromSrams_bore_3_ram_mcp_hold,sigFromSrams_bore_3_ram_aux_ckbp,sigFromSrams_bore_3_ram_aux_clk,sigFromSrams_bore_3_ram_bp_clken,sigFromSrams_bore_3_ram_bypass,sigFromSrams_bore_3_ram_hold};
  assign bb_addr[3]=boreChildrenBd_bore_4_addr;    assign bb_addr_rd[3]=boreChildrenBd_bore_4_addr_rd;
  assign bb_wdata[3]=boreChildrenBd_bore_4_wdata;  assign bb_wmask[3]=boreChildrenBd_bore_4_wmask;
  assign bb_re[3]=boreChildrenBd_bore_4_re;        assign bb_we[3]=boreChildrenBd_bore_4_we;
  assign bb_ack[3]=boreChildrenBd_bore_4_ack;      assign bb_sel[3]=boreChildrenBd_bore_4_selectedOH;
  assign bb_array[3]=boreChildrenBd_bore_4_array;
  assign boreChildrenBd_bore_4_rdata=bb_rdata[3];
  assign sig_bk[3]={sigFromSrams_bore_4_cgen,sigFromSrams_bore_4_ram_mcp_hold,sigFromSrams_bore_4_ram_aux_ckbp,sigFromSrams_bore_4_ram_aux_clk,sigFromSrams_bore_4_ram_bp_clken,sigFromSrams_bore_4_ram_bypass,sigFromSrams_bore_4_ram_hold};
  xs_TageTable_core #(.HIST_LEN(13)) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc), .io_req_bits_ghist(io_req_bits_ghist),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_1_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_4_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_15_folded_hist),
    .io_resps_0_valid(io_resps_0_valid), .io_resps_0_bits_ctr(io_resps_0_bits_ctr),
    .io_resps_0_bits_u(io_resps_0_bits_u), .io_resps_0_bits_unconf(io_resps_0_bits_unconf),
    .io_resps_1_valid(io_resps_1_valid), .io_resps_1_bits_ctr(io_resps_1_bits_ctr),
    .io_resps_1_bits_u(io_resps_1_bits_u), .io_resps_1_bits_unconf(io_resps_1_bits_unconf),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .io_update_alloc_0(io_update_alloc_0), .io_update_alloc_1(io_update_alloc_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_uMask_0(io_update_uMask_0), .io_update_uMask_1(io_update_uMask_1),
    .io_update_us_0(io_update_us_0), .io_update_us_1(io_update_us_1),
    .io_update_reset_u_0(io_update_reset_u_0), .io_update_reset_u_1(io_update_reset_u_1),
    .bore_us_addr(boreChildrenBd_bore_addr), .bore_us_addr_rd(boreChildrenBd_bore_addr_rd),
    .bore_us_wdata(boreChildrenBd_bore_wdata), .bore_us_wmask(boreChildrenBd_bore_wmask),
    .bore_us_re(boreChildrenBd_bore_re), .bore_us_we(boreChildrenBd_bore_we),
    .bore_us_rdata(boreChildrenBd_bore_rdata), .bore_us_ack(boreChildrenBd_bore_ack),
    .bore_us_selectedOH(boreChildrenBd_bore_selectedOH), .bore_us_array(boreChildrenBd_bore_array),
    .bore_bank_addr(bb_addr), .bore_bank_addr_rd(bb_addr_rd),
    .bore_bank_wdata(bb_wdata), .bore_bank_wmask(bb_wmask),
    .bore_bank_re(bb_re), .bore_bank_we(bb_we), .bore_bank_rdata(bb_rdata),
    .bore_bank_ack(bb_ack), .bore_bank_selectedOH(bb_sel), .bore_bank_array(bb_array),
    .sig_us({sigFromSrams_bore_cgen,sigFromSrams_bore_ram_mcp_hold,sigFromSrams_bore_ram_aux_ckbp,sigFromSrams_bore_ram_aux_clk,sigFromSrams_bore_ram_bp_clken,sigFromSrams_bore_ram_bypass,sigFromSrams_bore_ram_hold}),
    .sig_bank(sig_bk)
  );
endmodule

module TageTable_2(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [255:0] io_req_bits_ghist,
  input [10:0] io_req_bits_folded_hist_hist_17_folded_hist,
  input [6:0] io_req_bits_folded_hist_hist_9_folded_hist,
  input [7:0] io_req_bits_folded_hist_hist_3_folded_hist,
  output io_resps_0_valid,
  output [2:0] io_resps_0_bits_ctr,
  output io_resps_0_bits_u,
  output io_resps_0_bits_unconf,
  output io_resps_1_valid,
  output [2:0] io_resps_1_bits_ctr,
  output io_resps_1_bits_u,
  output io_resps_1_bits_unconf,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_mask_0,
  input io_update_mask_1,
  input io_update_takens_0,
  input io_update_takens_1,
  input io_update_alloc_0,
  input io_update_alloc_1,
  input [2:0] io_update_oldCtrs_0,
  input [2:0] io_update_oldCtrs_1,
  input io_update_uMask_0,
  input io_update_uMask_1,
  input io_update_us_0,
  input io_update_us_1,
  input io_update_reset_u_0,
  input io_update_reset_u_1,
  input [8:0] boreChildrenBd_bore_addr,
  input [8:0] boreChildrenBd_bore_addr_rd,
  input [15:0] boreChildrenBd_bore_wdata,
  input [15:0] boreChildrenBd_bore_wmask,
  input boreChildrenBd_bore_re,
  input boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_selectedOH,
  input [5:0] boreChildrenBd_bore_array,
  input [9:0] boreChildrenBd_bore_1_addr,
  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input [23:0] boreChildrenBd_bore_1_wdata,
  input [1:0] boreChildrenBd_bore_1_wmask,
  input boreChildrenBd_bore_1_re,
  input boreChildrenBd_bore_1_we,
  output [23:0] boreChildrenBd_bore_1_rdata,
  input boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_selectedOH,
  input [5:0] boreChildrenBd_bore_1_array,
  input [9:0] boreChildrenBd_bore_2_addr,
  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input [23:0] boreChildrenBd_bore_2_wdata,
  input [1:0] boreChildrenBd_bore_2_wmask,
  input boreChildrenBd_bore_2_re,
  input boreChildrenBd_bore_2_we,
  output [23:0] boreChildrenBd_bore_2_rdata,
  input boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_selectedOH,
  input [5:0] boreChildrenBd_bore_2_array,
  input [9:0] boreChildrenBd_bore_3_addr,
  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input [23:0] boreChildrenBd_bore_3_wdata,
  input [1:0] boreChildrenBd_bore_3_wmask,
  input boreChildrenBd_bore_3_re,
  input boreChildrenBd_bore_3_we,
  output [23:0] boreChildrenBd_bore_3_rdata,
  input boreChildrenBd_bore_3_ack,
  input boreChildrenBd_bore_3_selectedOH,
  input [5:0] boreChildrenBd_bore_3_array,
  input [9:0] boreChildrenBd_bore_4_addr,
  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input [23:0] boreChildrenBd_bore_4_wdata,
  input [1:0] boreChildrenBd_bore_4_wmask,
  input boreChildrenBd_bore_4_re,
  input boreChildrenBd_bore_4_we,
  output [23:0] boreChildrenBd_bore_4_rdata,
  input boreChildrenBd_bore_4_ack,
  input boreChildrenBd_bore_4_selectedOH,
  input [5:0] boreChildrenBd_bore_4_array,
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
  input sigFromSrams_bore_4_cgen
);
  // ---- bore_bank/sig_bank 打包（golden bore_1..4 → 数组 [0..3]）----
  wire [9:0]  bb_addr [4], bb_addr_rd [4];
  wire [23:0] bb_wdata [4];
  wire [1:0]  bb_wmask [4];
  wire        bb_re [4], bb_we [4], bb_ack [4], bb_sel [4];
  wire [23:0] bb_rdata [4];
  wire [5:0]  bb_array [4];
  wire [6:0]  sig_bk [4];
  assign bb_addr[0]=boreChildrenBd_bore_1_addr;    assign bb_addr_rd[0]=boreChildrenBd_bore_1_addr_rd;
  assign bb_wdata[0]=boreChildrenBd_bore_1_wdata;  assign bb_wmask[0]=boreChildrenBd_bore_1_wmask;
  assign bb_re[0]=boreChildrenBd_bore_1_re;        assign bb_we[0]=boreChildrenBd_bore_1_we;
  assign bb_ack[0]=boreChildrenBd_bore_1_ack;      assign bb_sel[0]=boreChildrenBd_bore_1_selectedOH;
  assign bb_array[0]=boreChildrenBd_bore_1_array;
  assign boreChildrenBd_bore_1_rdata=bb_rdata[0];
  assign sig_bk[0]={sigFromSrams_bore_1_cgen,sigFromSrams_bore_1_ram_mcp_hold,sigFromSrams_bore_1_ram_aux_ckbp,sigFromSrams_bore_1_ram_aux_clk,sigFromSrams_bore_1_ram_bp_clken,sigFromSrams_bore_1_ram_bypass,sigFromSrams_bore_1_ram_hold};
  assign bb_addr[1]=boreChildrenBd_bore_2_addr;    assign bb_addr_rd[1]=boreChildrenBd_bore_2_addr_rd;
  assign bb_wdata[1]=boreChildrenBd_bore_2_wdata;  assign bb_wmask[1]=boreChildrenBd_bore_2_wmask;
  assign bb_re[1]=boreChildrenBd_bore_2_re;        assign bb_we[1]=boreChildrenBd_bore_2_we;
  assign bb_ack[1]=boreChildrenBd_bore_2_ack;      assign bb_sel[1]=boreChildrenBd_bore_2_selectedOH;
  assign bb_array[1]=boreChildrenBd_bore_2_array;
  assign boreChildrenBd_bore_2_rdata=bb_rdata[1];
  assign sig_bk[1]={sigFromSrams_bore_2_cgen,sigFromSrams_bore_2_ram_mcp_hold,sigFromSrams_bore_2_ram_aux_ckbp,sigFromSrams_bore_2_ram_aux_clk,sigFromSrams_bore_2_ram_bp_clken,sigFromSrams_bore_2_ram_bypass,sigFromSrams_bore_2_ram_hold};
  assign bb_addr[2]=boreChildrenBd_bore_3_addr;    assign bb_addr_rd[2]=boreChildrenBd_bore_3_addr_rd;
  assign bb_wdata[2]=boreChildrenBd_bore_3_wdata;  assign bb_wmask[2]=boreChildrenBd_bore_3_wmask;
  assign bb_re[2]=boreChildrenBd_bore_3_re;        assign bb_we[2]=boreChildrenBd_bore_3_we;
  assign bb_ack[2]=boreChildrenBd_bore_3_ack;      assign bb_sel[2]=boreChildrenBd_bore_3_selectedOH;
  assign bb_array[2]=boreChildrenBd_bore_3_array;
  assign boreChildrenBd_bore_3_rdata=bb_rdata[2];
  assign sig_bk[2]={sigFromSrams_bore_3_cgen,sigFromSrams_bore_3_ram_mcp_hold,sigFromSrams_bore_3_ram_aux_ckbp,sigFromSrams_bore_3_ram_aux_clk,sigFromSrams_bore_3_ram_bp_clken,sigFromSrams_bore_3_ram_bypass,sigFromSrams_bore_3_ram_hold};
  assign bb_addr[3]=boreChildrenBd_bore_4_addr;    assign bb_addr_rd[3]=boreChildrenBd_bore_4_addr_rd;
  assign bb_wdata[3]=boreChildrenBd_bore_4_wdata;  assign bb_wmask[3]=boreChildrenBd_bore_4_wmask;
  assign bb_re[3]=boreChildrenBd_bore_4_re;        assign bb_we[3]=boreChildrenBd_bore_4_we;
  assign bb_ack[3]=boreChildrenBd_bore_4_ack;      assign bb_sel[3]=boreChildrenBd_bore_4_selectedOH;
  assign bb_array[3]=boreChildrenBd_bore_4_array;
  assign boreChildrenBd_bore_4_rdata=bb_rdata[3];
  assign sig_bk[3]={sigFromSrams_bore_4_cgen,sigFromSrams_bore_4_ram_mcp_hold,sigFromSrams_bore_4_ram_aux_ckbp,sigFromSrams_bore_4_ram_aux_clk,sigFromSrams_bore_4_ram_bp_clken,sigFromSrams_bore_4_ram_bypass,sigFromSrams_bore_4_ram_hold};
  xs_TageTable_core #(.HIST_LEN(32)) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc), .io_req_bits_ghist(io_req_bits_ghist),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_17_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_3_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_9_folded_hist),
    .io_resps_0_valid(io_resps_0_valid), .io_resps_0_bits_ctr(io_resps_0_bits_ctr),
    .io_resps_0_bits_u(io_resps_0_bits_u), .io_resps_0_bits_unconf(io_resps_0_bits_unconf),
    .io_resps_1_valid(io_resps_1_valid), .io_resps_1_bits_ctr(io_resps_1_bits_ctr),
    .io_resps_1_bits_u(io_resps_1_bits_u), .io_resps_1_bits_unconf(io_resps_1_bits_unconf),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .io_update_alloc_0(io_update_alloc_0), .io_update_alloc_1(io_update_alloc_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_uMask_0(io_update_uMask_0), .io_update_uMask_1(io_update_uMask_1),
    .io_update_us_0(io_update_us_0), .io_update_us_1(io_update_us_1),
    .io_update_reset_u_0(io_update_reset_u_0), .io_update_reset_u_1(io_update_reset_u_1),
    .bore_us_addr(boreChildrenBd_bore_addr), .bore_us_addr_rd(boreChildrenBd_bore_addr_rd),
    .bore_us_wdata(boreChildrenBd_bore_wdata), .bore_us_wmask(boreChildrenBd_bore_wmask),
    .bore_us_re(boreChildrenBd_bore_re), .bore_us_we(boreChildrenBd_bore_we),
    .bore_us_rdata(boreChildrenBd_bore_rdata), .bore_us_ack(boreChildrenBd_bore_ack),
    .bore_us_selectedOH(boreChildrenBd_bore_selectedOH), .bore_us_array(boreChildrenBd_bore_array),
    .bore_bank_addr(bb_addr), .bore_bank_addr_rd(bb_addr_rd),
    .bore_bank_wdata(bb_wdata), .bore_bank_wmask(bb_wmask),
    .bore_bank_re(bb_re), .bore_bank_we(bb_we), .bore_bank_rdata(bb_rdata),
    .bore_bank_ack(bb_ack), .bore_bank_selectedOH(bb_sel), .bore_bank_array(bb_array),
    .sig_us({sigFromSrams_bore_cgen,sigFromSrams_bore_ram_mcp_hold,sigFromSrams_bore_ram_aux_ckbp,sigFromSrams_bore_ram_aux_clk,sigFromSrams_bore_ram_bp_clken,sigFromSrams_bore_ram_bypass,sigFromSrams_bore_ram_hold}),
    .sig_bank(sig_bk)
  );
endmodule

module TageTable_3(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [255:0] io_req_bits_ghist,
  input [10:0] io_req_bits_folded_hist_hist_16_folded_hist,
  input [7:0] io_req_bits_folded_hist_hist_8_folded_hist,
  input [6:0] io_req_bits_folded_hist_hist_5_folded_hist,
  output io_resps_0_valid,
  output [2:0] io_resps_0_bits_ctr,
  output io_resps_0_bits_u,
  output io_resps_0_bits_unconf,
  output io_resps_1_valid,
  output [2:0] io_resps_1_bits_ctr,
  output io_resps_1_bits_u,
  output io_resps_1_bits_unconf,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_mask_0,
  input io_update_mask_1,
  input io_update_takens_0,
  input io_update_takens_1,
  input io_update_alloc_0,
  input io_update_alloc_1,
  input [2:0] io_update_oldCtrs_0,
  input [2:0] io_update_oldCtrs_1,
  input io_update_uMask_0,
  input io_update_uMask_1,
  input io_update_us_0,
  input io_update_us_1,
  input io_update_reset_u_0,
  input io_update_reset_u_1,
  input [8:0] boreChildrenBd_bore_addr,
  input [8:0] boreChildrenBd_bore_addr_rd,
  input [15:0] boreChildrenBd_bore_wdata,
  input [15:0] boreChildrenBd_bore_wmask,
  input boreChildrenBd_bore_re,
  input boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_selectedOH,
  input [5:0] boreChildrenBd_bore_array,
  input [9:0] boreChildrenBd_bore_1_addr,
  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input [23:0] boreChildrenBd_bore_1_wdata,
  input [1:0] boreChildrenBd_bore_1_wmask,
  input boreChildrenBd_bore_1_re,
  input boreChildrenBd_bore_1_we,
  output [23:0] boreChildrenBd_bore_1_rdata,
  input boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_selectedOH,
  input [5:0] boreChildrenBd_bore_1_array,
  input [9:0] boreChildrenBd_bore_2_addr,
  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input [23:0] boreChildrenBd_bore_2_wdata,
  input [1:0] boreChildrenBd_bore_2_wmask,
  input boreChildrenBd_bore_2_re,
  input boreChildrenBd_bore_2_we,
  output [23:0] boreChildrenBd_bore_2_rdata,
  input boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_selectedOH,
  input [5:0] boreChildrenBd_bore_2_array,
  input [9:0] boreChildrenBd_bore_3_addr,
  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input [23:0] boreChildrenBd_bore_3_wdata,
  input [1:0] boreChildrenBd_bore_3_wmask,
  input boreChildrenBd_bore_3_re,
  input boreChildrenBd_bore_3_we,
  output [23:0] boreChildrenBd_bore_3_rdata,
  input boreChildrenBd_bore_3_ack,
  input boreChildrenBd_bore_3_selectedOH,
  input [5:0] boreChildrenBd_bore_3_array,
  input [9:0] boreChildrenBd_bore_4_addr,
  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input [23:0] boreChildrenBd_bore_4_wdata,
  input [1:0] boreChildrenBd_bore_4_wmask,
  input boreChildrenBd_bore_4_re,
  input boreChildrenBd_bore_4_we,
  output [23:0] boreChildrenBd_bore_4_rdata,
  input boreChildrenBd_bore_4_ack,
  input boreChildrenBd_bore_4_selectedOH,
  input [5:0] boreChildrenBd_bore_4_array,
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
  input sigFromSrams_bore_4_cgen
);
  // ---- bore_bank/sig_bank 打包（golden bore_1..4 → 数组 [0..3]）----
  wire [9:0]  bb_addr [4], bb_addr_rd [4];
  wire [23:0] bb_wdata [4];
  wire [1:0]  bb_wmask [4];
  wire        bb_re [4], bb_we [4], bb_ack [4], bb_sel [4];
  wire [23:0] bb_rdata [4];
  wire [5:0]  bb_array [4];
  wire [6:0]  sig_bk [4];
  assign bb_addr[0]=boreChildrenBd_bore_1_addr;    assign bb_addr_rd[0]=boreChildrenBd_bore_1_addr_rd;
  assign bb_wdata[0]=boreChildrenBd_bore_1_wdata;  assign bb_wmask[0]=boreChildrenBd_bore_1_wmask;
  assign bb_re[0]=boreChildrenBd_bore_1_re;        assign bb_we[0]=boreChildrenBd_bore_1_we;
  assign bb_ack[0]=boreChildrenBd_bore_1_ack;      assign bb_sel[0]=boreChildrenBd_bore_1_selectedOH;
  assign bb_array[0]=boreChildrenBd_bore_1_array;
  assign boreChildrenBd_bore_1_rdata=bb_rdata[0];
  assign sig_bk[0]={sigFromSrams_bore_1_cgen,sigFromSrams_bore_1_ram_mcp_hold,sigFromSrams_bore_1_ram_aux_ckbp,sigFromSrams_bore_1_ram_aux_clk,sigFromSrams_bore_1_ram_bp_clken,sigFromSrams_bore_1_ram_bypass,sigFromSrams_bore_1_ram_hold};
  assign bb_addr[1]=boreChildrenBd_bore_2_addr;    assign bb_addr_rd[1]=boreChildrenBd_bore_2_addr_rd;
  assign bb_wdata[1]=boreChildrenBd_bore_2_wdata;  assign bb_wmask[1]=boreChildrenBd_bore_2_wmask;
  assign bb_re[1]=boreChildrenBd_bore_2_re;        assign bb_we[1]=boreChildrenBd_bore_2_we;
  assign bb_ack[1]=boreChildrenBd_bore_2_ack;      assign bb_sel[1]=boreChildrenBd_bore_2_selectedOH;
  assign bb_array[1]=boreChildrenBd_bore_2_array;
  assign boreChildrenBd_bore_2_rdata=bb_rdata[1];
  assign sig_bk[1]={sigFromSrams_bore_2_cgen,sigFromSrams_bore_2_ram_mcp_hold,sigFromSrams_bore_2_ram_aux_ckbp,sigFromSrams_bore_2_ram_aux_clk,sigFromSrams_bore_2_ram_bp_clken,sigFromSrams_bore_2_ram_bypass,sigFromSrams_bore_2_ram_hold};
  assign bb_addr[2]=boreChildrenBd_bore_3_addr;    assign bb_addr_rd[2]=boreChildrenBd_bore_3_addr_rd;
  assign bb_wdata[2]=boreChildrenBd_bore_3_wdata;  assign bb_wmask[2]=boreChildrenBd_bore_3_wmask;
  assign bb_re[2]=boreChildrenBd_bore_3_re;        assign bb_we[2]=boreChildrenBd_bore_3_we;
  assign bb_ack[2]=boreChildrenBd_bore_3_ack;      assign bb_sel[2]=boreChildrenBd_bore_3_selectedOH;
  assign bb_array[2]=boreChildrenBd_bore_3_array;
  assign boreChildrenBd_bore_3_rdata=bb_rdata[2];
  assign sig_bk[2]={sigFromSrams_bore_3_cgen,sigFromSrams_bore_3_ram_mcp_hold,sigFromSrams_bore_3_ram_aux_ckbp,sigFromSrams_bore_3_ram_aux_clk,sigFromSrams_bore_3_ram_bp_clken,sigFromSrams_bore_3_ram_bypass,sigFromSrams_bore_3_ram_hold};
  assign bb_addr[3]=boreChildrenBd_bore_4_addr;    assign bb_addr_rd[3]=boreChildrenBd_bore_4_addr_rd;
  assign bb_wdata[3]=boreChildrenBd_bore_4_wdata;  assign bb_wmask[3]=boreChildrenBd_bore_4_wmask;
  assign bb_re[3]=boreChildrenBd_bore_4_re;        assign bb_we[3]=boreChildrenBd_bore_4_we;
  assign bb_ack[3]=boreChildrenBd_bore_4_ack;      assign bb_sel[3]=boreChildrenBd_bore_4_selectedOH;
  assign bb_array[3]=boreChildrenBd_bore_4_array;
  assign boreChildrenBd_bore_4_rdata=bb_rdata[3];
  assign sig_bk[3]={sigFromSrams_bore_4_cgen,sigFromSrams_bore_4_ram_mcp_hold,sigFromSrams_bore_4_ram_aux_ckbp,sigFromSrams_bore_4_ram_aux_clk,sigFromSrams_bore_4_ram_bp_clken,sigFromSrams_bore_4_ram_bypass,sigFromSrams_bore_4_ram_hold};
  xs_TageTable_core #(.HIST_LEN(119)) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc), .io_req_bits_ghist(io_req_bits_ghist),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_16_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_8_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_5_folded_hist),
    .io_resps_0_valid(io_resps_0_valid), .io_resps_0_bits_ctr(io_resps_0_bits_ctr),
    .io_resps_0_bits_u(io_resps_0_bits_u), .io_resps_0_bits_unconf(io_resps_0_bits_unconf),
    .io_resps_1_valid(io_resps_1_valid), .io_resps_1_bits_ctr(io_resps_1_bits_ctr),
    .io_resps_1_bits_u(io_resps_1_bits_u), .io_resps_1_bits_unconf(io_resps_1_bits_unconf),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .io_update_alloc_0(io_update_alloc_0), .io_update_alloc_1(io_update_alloc_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_uMask_0(io_update_uMask_0), .io_update_uMask_1(io_update_uMask_1),
    .io_update_us_0(io_update_us_0), .io_update_us_1(io_update_us_1),
    .io_update_reset_u_0(io_update_reset_u_0), .io_update_reset_u_1(io_update_reset_u_1),
    .bore_us_addr(boreChildrenBd_bore_addr), .bore_us_addr_rd(boreChildrenBd_bore_addr_rd),
    .bore_us_wdata(boreChildrenBd_bore_wdata), .bore_us_wmask(boreChildrenBd_bore_wmask),
    .bore_us_re(boreChildrenBd_bore_re), .bore_us_we(boreChildrenBd_bore_we),
    .bore_us_rdata(boreChildrenBd_bore_rdata), .bore_us_ack(boreChildrenBd_bore_ack),
    .bore_us_selectedOH(boreChildrenBd_bore_selectedOH), .bore_us_array(boreChildrenBd_bore_array),
    .bore_bank_addr(bb_addr), .bore_bank_addr_rd(bb_addr_rd),
    .bore_bank_wdata(bb_wdata), .bore_bank_wmask(bb_wmask),
    .bore_bank_re(bb_re), .bore_bank_we(bb_we), .bore_bank_rdata(bb_rdata),
    .bore_bank_ack(bb_ack), .bore_bank_selectedOH(bb_sel), .bore_bank_array(bb_array),
    .sig_us({sigFromSrams_bore_cgen,sigFromSrams_bore_ram_mcp_hold,sigFromSrams_bore_ram_aux_ckbp,sigFromSrams_bore_ram_aux_clk,sigFromSrams_bore_ram_bp_clken,sigFromSrams_bore_ram_bypass,sigFromSrams_bore_ram_hold}),
    .sig_bank(sig_bk)
  );
endmodule