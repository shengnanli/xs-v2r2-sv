// 自动生成：verif/ut/DuplicatedTagArray/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// DuplicatedTagArray 双例化逐拍比对：golden vs 重写 _xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= DuplicatedTagArray =================
  int unsigned dta_mode = 0;
  logic dta_reset;
  logic dta_io_read_0_valid;
  logic [7:0] dta_io_read_0_bits_idx;
  logic dta_io_read_1_valid;
  logic [7:0] dta_io_read_1_bits_idx;
  logic dta_io_read_2_valid;
  logic [7:0] dta_io_read_2_bits_idx;
  wire  dta_g_io_read_3_ready, dta_i_io_read_3_ready;
  logic dta_s0_io_read_3_ready = '0, dta_s1_io_read_3_ready = '0;
  logic dta_io_read_3_valid;
  logic [7:0] dta_io_read_3_bits_idx;
  wire  [42:0] dta_g_io_resp_0_0, dta_i_io_resp_0_0;
  logic [42:0] dta_s0_io_resp_0_0 = '0, dta_s1_io_resp_0_0 = '0;
  wire  [42:0] dta_g_io_resp_0_1, dta_i_io_resp_0_1;
  logic [42:0] dta_s0_io_resp_0_1 = '0, dta_s1_io_resp_0_1 = '0;
  wire  [42:0] dta_g_io_resp_0_2, dta_i_io_resp_0_2;
  logic [42:0] dta_s0_io_resp_0_2 = '0, dta_s1_io_resp_0_2 = '0;
  wire  [42:0] dta_g_io_resp_0_3, dta_i_io_resp_0_3;
  logic [42:0] dta_s0_io_resp_0_3 = '0, dta_s1_io_resp_0_3 = '0;
  wire  [42:0] dta_g_io_resp_1_0, dta_i_io_resp_1_0;
  logic [42:0] dta_s0_io_resp_1_0 = '0, dta_s1_io_resp_1_0 = '0;
  wire  [42:0] dta_g_io_resp_1_1, dta_i_io_resp_1_1;
  logic [42:0] dta_s0_io_resp_1_1 = '0, dta_s1_io_resp_1_1 = '0;
  wire  [42:0] dta_g_io_resp_1_2, dta_i_io_resp_1_2;
  logic [42:0] dta_s0_io_resp_1_2 = '0, dta_s1_io_resp_1_2 = '0;
  wire  [42:0] dta_g_io_resp_1_3, dta_i_io_resp_1_3;
  logic [42:0] dta_s0_io_resp_1_3 = '0, dta_s1_io_resp_1_3 = '0;
  wire  [42:0] dta_g_io_resp_2_0, dta_i_io_resp_2_0;
  logic [42:0] dta_s0_io_resp_2_0 = '0, dta_s1_io_resp_2_0 = '0;
  wire  [42:0] dta_g_io_resp_2_1, dta_i_io_resp_2_1;
  logic [42:0] dta_s0_io_resp_2_1 = '0, dta_s1_io_resp_2_1 = '0;
  wire  [42:0] dta_g_io_resp_2_2, dta_i_io_resp_2_2;
  logic [42:0] dta_s0_io_resp_2_2 = '0, dta_s1_io_resp_2_2 = '0;
  wire  [42:0] dta_g_io_resp_2_3, dta_i_io_resp_2_3;
  logic [42:0] dta_s0_io_resp_2_3 = '0, dta_s1_io_resp_2_3 = '0;
  wire  [42:0] dta_g_io_resp_3_0, dta_i_io_resp_3_0;
  logic [42:0] dta_s0_io_resp_3_0 = '0, dta_s1_io_resp_3_0 = '0;
  wire  [42:0] dta_g_io_resp_3_1, dta_i_io_resp_3_1;
  logic [42:0] dta_s0_io_resp_3_1 = '0, dta_s1_io_resp_3_1 = '0;
  wire  [42:0] dta_g_io_resp_3_2, dta_i_io_resp_3_2;
  logic [42:0] dta_s0_io_resp_3_2 = '0, dta_s1_io_resp_3_2 = '0;
  wire  [42:0] dta_g_io_resp_3_3, dta_i_io_resp_3_3;
  logic [42:0] dta_s0_io_resp_3_3 = '0, dta_s1_io_resp_3_3 = '0;
  logic dta_io_write_valid;
  logic [7:0] dta_io_write_bits_idx;
  logic [3:0] dta_io_write_bits_way_en;
  logic [35:0] dta_io_write_bits_tag;
  logic [5:0] dta_boreChildrenBd_bore_array;
  logic dta_boreChildrenBd_bore_all;
  logic dta_boreChildrenBd_bore_req;
  wire  dta_g_boreChildrenBd_bore_ack, dta_i_boreChildrenBd_bore_ack;
  logic dta_s0_boreChildrenBd_bore_ack = '0, dta_s1_boreChildrenBd_bore_ack = '0;
  logic dta_boreChildrenBd_bore_writeen;
  logic [1:0] dta_boreChildrenBd_bore_be;
  logic [8:0] dta_boreChildrenBd_bore_addr;
  logic [85:0] dta_boreChildrenBd_bore_indata;
  logic dta_boreChildrenBd_bore_readen;
  logic [8:0] dta_boreChildrenBd_bore_addr_rd;
  wire  [85:0] dta_g_boreChildrenBd_bore_outdata, dta_i_boreChildrenBd_bore_outdata;
  logic [85:0] dta_s0_boreChildrenBd_bore_outdata = '0, dta_s1_boreChildrenBd_bore_outdata = '0;
  logic dta_sigFromSrams_bore_ram_hold;
  logic dta_sigFromSrams_bore_ram_bypass;
  logic dta_sigFromSrams_bore_ram_bp_clken;
  logic dta_sigFromSrams_bore_ram_aux_clk;
  logic dta_sigFromSrams_bore_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_ram_mcp_hold;
  logic dta_sigFromSrams_bore_cgen;
  logic dta_sigFromSrams_bore_1_ram_hold;
  logic dta_sigFromSrams_bore_1_ram_bypass;
  logic dta_sigFromSrams_bore_1_ram_bp_clken;
  logic dta_sigFromSrams_bore_1_ram_aux_clk;
  logic dta_sigFromSrams_bore_1_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_1_ram_mcp_hold;
  logic dta_sigFromSrams_bore_1_cgen;
  logic dta_sigFromSrams_bore_2_ram_hold;
  logic dta_sigFromSrams_bore_2_ram_bypass;
  logic dta_sigFromSrams_bore_2_ram_bp_clken;
  logic dta_sigFromSrams_bore_2_ram_aux_clk;
  logic dta_sigFromSrams_bore_2_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_2_ram_mcp_hold;
  logic dta_sigFromSrams_bore_2_cgen;
  logic dta_sigFromSrams_bore_3_ram_hold;
  logic dta_sigFromSrams_bore_3_ram_bypass;
  logic dta_sigFromSrams_bore_3_ram_bp_clken;
  logic dta_sigFromSrams_bore_3_ram_aux_clk;
  logic dta_sigFromSrams_bore_3_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_3_ram_mcp_hold;
  logic dta_sigFromSrams_bore_3_cgen;
  logic dta_sigFromSrams_bore_4_ram_hold;
  logic dta_sigFromSrams_bore_4_ram_bypass;
  logic dta_sigFromSrams_bore_4_ram_bp_clken;
  logic dta_sigFromSrams_bore_4_ram_aux_clk;
  logic dta_sigFromSrams_bore_4_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_4_ram_mcp_hold;
  logic dta_sigFromSrams_bore_4_cgen;
  logic dta_sigFromSrams_bore_5_ram_hold;
  logic dta_sigFromSrams_bore_5_ram_bypass;
  logic dta_sigFromSrams_bore_5_ram_bp_clken;
  logic dta_sigFromSrams_bore_5_ram_aux_clk;
  logic dta_sigFromSrams_bore_5_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_5_ram_mcp_hold;
  logic dta_sigFromSrams_bore_5_cgen;
  logic dta_sigFromSrams_bore_6_ram_hold;
  logic dta_sigFromSrams_bore_6_ram_bypass;
  logic dta_sigFromSrams_bore_6_ram_bp_clken;
  logic dta_sigFromSrams_bore_6_ram_aux_clk;
  logic dta_sigFromSrams_bore_6_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_6_ram_mcp_hold;
  logic dta_sigFromSrams_bore_6_cgen;
  logic dta_sigFromSrams_bore_7_ram_hold;
  logic dta_sigFromSrams_bore_7_ram_bypass;
  logic dta_sigFromSrams_bore_7_ram_bp_clken;
  logic dta_sigFromSrams_bore_7_ram_aux_clk;
  logic dta_sigFromSrams_bore_7_ram_aux_ckbp;
  logic dta_sigFromSrams_bore_7_ram_mcp_hold;
  logic dta_sigFromSrams_bore_7_cgen;
  int dta_cov_write = 0;
  int dta_cov_read3_blocked = 0;
  int dta_cov_mbist_req = 0;
  int dta_cov_ecc_nonzero = 0;
  logic [4:0] dta_armed = '0;
  int dta_armed_at = -1;
  DuplicatedTagArray dta_u_gold (
    .clock(clk),
    .reset(dta_reset),
    .io_read_0_valid(dta_io_read_0_valid),
    .io_read_0_bits_idx(dta_io_read_0_bits_idx),
    .io_read_1_valid(dta_io_read_1_valid),
    .io_read_1_bits_idx(dta_io_read_1_bits_idx),
    .io_read_2_valid(dta_io_read_2_valid),
    .io_read_2_bits_idx(dta_io_read_2_bits_idx),
    .io_read_3_ready(dta_g_io_read_3_ready),
    .io_read_3_valid(dta_io_read_3_valid),
    .io_read_3_bits_idx(dta_io_read_3_bits_idx),
    .io_resp_0_0(dta_g_io_resp_0_0),
    .io_resp_0_1(dta_g_io_resp_0_1),
    .io_resp_0_2(dta_g_io_resp_0_2),
    .io_resp_0_3(dta_g_io_resp_0_3),
    .io_resp_1_0(dta_g_io_resp_1_0),
    .io_resp_1_1(dta_g_io_resp_1_1),
    .io_resp_1_2(dta_g_io_resp_1_2),
    .io_resp_1_3(dta_g_io_resp_1_3),
    .io_resp_2_0(dta_g_io_resp_2_0),
    .io_resp_2_1(dta_g_io_resp_2_1),
    .io_resp_2_2(dta_g_io_resp_2_2),
    .io_resp_2_3(dta_g_io_resp_2_3),
    .io_resp_3_0(dta_g_io_resp_3_0),
    .io_resp_3_1(dta_g_io_resp_3_1),
    .io_resp_3_2(dta_g_io_resp_3_2),
    .io_resp_3_3(dta_g_io_resp_3_3),
    .io_write_valid(dta_io_write_valid),
    .io_write_bits_idx(dta_io_write_bits_idx),
    .io_write_bits_way_en(dta_io_write_bits_way_en),
    .io_write_bits_tag(dta_io_write_bits_tag),
    .boreChildrenBd_bore_array(dta_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(dta_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(dta_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(dta_g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(dta_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(dta_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(dta_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(dta_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(dta_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(dta_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(dta_g_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(dta_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(dta_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(dta_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(dta_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(dta_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(dta_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(dta_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(dta_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(dta_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(dta_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(dta_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(dta_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(dta_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(dta_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(dta_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(dta_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(dta_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(dta_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(dta_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(dta_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(dta_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(dta_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(dta_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(dta_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(dta_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(dta_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(dta_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(dta_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(dta_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(dta_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(dta_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(dta_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(dta_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(dta_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(dta_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(dta_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(dta_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(dta_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(dta_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(dta_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(dta_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(dta_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(dta_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(dta_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(dta_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(dta_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(dta_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(dta_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(dta_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(dta_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(dta_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(dta_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(dta_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(dta_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(dta_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(dta_sigFromSrams_bore_7_cgen)
  );
  DuplicatedTagArray_xs dta_u_impl (
    .clock(clk),
    .reset(dta_reset),
    .io_read_0_valid(dta_io_read_0_valid),
    .io_read_0_bits_idx(dta_io_read_0_bits_idx),
    .io_read_1_valid(dta_io_read_1_valid),
    .io_read_1_bits_idx(dta_io_read_1_bits_idx),
    .io_read_2_valid(dta_io_read_2_valid),
    .io_read_2_bits_idx(dta_io_read_2_bits_idx),
    .io_read_3_ready(dta_i_io_read_3_ready),
    .io_read_3_valid(dta_io_read_3_valid),
    .io_read_3_bits_idx(dta_io_read_3_bits_idx),
    .io_resp_0_0(dta_i_io_resp_0_0),
    .io_resp_0_1(dta_i_io_resp_0_1),
    .io_resp_0_2(dta_i_io_resp_0_2),
    .io_resp_0_3(dta_i_io_resp_0_3),
    .io_resp_1_0(dta_i_io_resp_1_0),
    .io_resp_1_1(dta_i_io_resp_1_1),
    .io_resp_1_2(dta_i_io_resp_1_2),
    .io_resp_1_3(dta_i_io_resp_1_3),
    .io_resp_2_0(dta_i_io_resp_2_0),
    .io_resp_2_1(dta_i_io_resp_2_1),
    .io_resp_2_2(dta_i_io_resp_2_2),
    .io_resp_2_3(dta_i_io_resp_2_3),
    .io_resp_3_0(dta_i_io_resp_3_0),
    .io_resp_3_1(dta_i_io_resp_3_1),
    .io_resp_3_2(dta_i_io_resp_3_2),
    .io_resp_3_3(dta_i_io_resp_3_3),
    .io_write_valid(dta_io_write_valid),
    .io_write_bits_idx(dta_io_write_bits_idx),
    .io_write_bits_way_en(dta_io_write_bits_way_en),
    .io_write_bits_tag(dta_io_write_bits_tag),
    .boreChildrenBd_bore_array(dta_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(dta_boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(dta_boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(dta_i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(dta_boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(dta_boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(dta_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(dta_boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(dta_boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(dta_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(dta_i_boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold(dta_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(dta_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(dta_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(dta_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(dta_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(dta_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(dta_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(dta_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(dta_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(dta_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(dta_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(dta_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(dta_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(dta_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(dta_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(dta_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(dta_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(dta_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(dta_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(dta_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(dta_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(dta_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(dta_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(dta_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(dta_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(dta_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(dta_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(dta_sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(dta_sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(dta_sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(dta_sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(dta_sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(dta_sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(dta_sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(dta_sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(dta_sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(dta_sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(dta_sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(dta_sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(dta_sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(dta_sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(dta_sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(dta_sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(dta_sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(dta_sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(dta_sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(dta_sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(dta_sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(dta_sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(dta_sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(dta_sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(dta_sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(dta_sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(dta_sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(dta_sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(dta_sigFromSrams_bore_7_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) dta_mode = $urandom_range(0, 15);
      dta_io_read_0_valid = 1'($urandom);
      dta_io_read_0_bits_idx = 8'($urandom);
      dta_io_read_1_valid = 1'($urandom);
      dta_io_read_1_bits_idx = 8'($urandom);
      dta_io_read_2_valid = 1'($urandom);
      dta_io_read_2_bits_idx = 8'($urandom);
      dta_io_read_3_valid = 1'($urandom);
      dta_io_read_3_bits_idx = 8'($urandom);
      dta_io_write_valid = 1'($urandom);
      dta_io_write_bits_idx = 8'($urandom);
      dta_io_write_bits_way_en = 4'($urandom);
      dta_io_write_bits_tag = 36'({$urandom, $urandom});
      dta_boreChildrenBd_bore_array = 6'($urandom);
      dta_boreChildrenBd_bore_all = 1'($urandom);
      dta_boreChildrenBd_bore_req = 1'($urandom);
      dta_boreChildrenBd_bore_writeen = 1'($urandom);
      dta_boreChildrenBd_bore_be = 2'($urandom);
      dta_boreChildrenBd_bore_addr = 9'($urandom);
      dta_boreChildrenBd_bore_indata = 86'({$urandom, $urandom, $urandom});
      dta_boreChildrenBd_bore_readen = 1'($urandom);
      dta_boreChildrenBd_bore_addr_rd = 9'($urandom);
      dta_sigFromSrams_bore_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_cgen = 1'($urandom);
      dta_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_1_cgen = 1'($urandom);
      dta_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_2_cgen = 1'($urandom);
      dta_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_3_cgen = 1'($urandom);
      dta_sigFromSrams_bore_4_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_4_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_4_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_4_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_4_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_4_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_4_cgen = 1'($urandom);
      dta_sigFromSrams_bore_5_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_5_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_5_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_5_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_5_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_5_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_5_cgen = 1'($urandom);
      dta_sigFromSrams_bore_6_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_6_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_6_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_6_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_6_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_6_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_6_cgen = 1'($urandom);
      dta_sigFromSrams_bore_7_ram_hold = 1'($urandom);
      dta_sigFromSrams_bore_7_ram_bypass = 1'($urandom);
      dta_sigFromSrams_bore_7_ram_bp_clken = 1'($urandom);
      dta_sigFromSrams_bore_7_ram_aux_clk = 1'($urandom);
      dta_sigFromSrams_bore_7_ram_aux_ckbp = 1'($urandom);
      dta_sigFromSrams_bore_7_ram_mcp_hold = 1'($urandom);
      dta_sigFromSrams_bore_7_cgen = 1'($urandom);
      dta_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_dta
        dta_io_read_0_bits_idx = 8'($urandom_range(0, 15));
        dta_io_read_1_bits_idx = 8'($urandom_range(0, 15));
        dta_io_read_2_bits_idx = 8'($urandom_range(0, 15));
        dta_io_read_3_bits_idx = 8'($urandom_range(0, 15));
        dta_io_write_bits_idx = 8'($urandom_range(0, 15));
        dta_io_write_valid = ($urandom_range(0, 2) == 0);
        if (dta_mode < 12) begin
          dta_boreChildrenBd_bore_array = '0;
          dta_boreChildrenBd_bore_all = '0;
          dta_boreChildrenBd_bore_req = '0;
          dta_boreChildrenBd_bore_writeen = '0;
          dta_boreChildrenBd_bore_be = '0;
          dta_boreChildrenBd_bore_addr = '0;
          dta_boreChildrenBd_bore_indata = '0;
          dta_boreChildrenBd_bore_readen = '0;
          dta_boreChildrenBd_bore_addr_rd = '0;
          dta_sigFromSrams_bore_ram_hold = '0;
          dta_sigFromSrams_bore_ram_bypass = '0;
          dta_sigFromSrams_bore_ram_bp_clken = '0;
          dta_sigFromSrams_bore_ram_aux_clk = '0;
          dta_sigFromSrams_bore_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_cgen = '0;
          dta_sigFromSrams_bore_1_ram_hold = '0;
          dta_sigFromSrams_bore_1_ram_bypass = '0;
          dta_sigFromSrams_bore_1_ram_bp_clken = '0;
          dta_sigFromSrams_bore_1_ram_aux_clk = '0;
          dta_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_1_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_1_cgen = '0;
          dta_sigFromSrams_bore_2_ram_hold = '0;
          dta_sigFromSrams_bore_2_ram_bypass = '0;
          dta_sigFromSrams_bore_2_ram_bp_clken = '0;
          dta_sigFromSrams_bore_2_ram_aux_clk = '0;
          dta_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_2_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_2_cgen = '0;
          dta_sigFromSrams_bore_3_ram_hold = '0;
          dta_sigFromSrams_bore_3_ram_bypass = '0;
          dta_sigFromSrams_bore_3_ram_bp_clken = '0;
          dta_sigFromSrams_bore_3_ram_aux_clk = '0;
          dta_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_3_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_3_cgen = '0;
          dta_sigFromSrams_bore_4_ram_hold = '0;
          dta_sigFromSrams_bore_4_ram_bypass = '0;
          dta_sigFromSrams_bore_4_ram_bp_clken = '0;
          dta_sigFromSrams_bore_4_ram_aux_clk = '0;
          dta_sigFromSrams_bore_4_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_4_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_4_cgen = '0;
          dta_sigFromSrams_bore_5_ram_hold = '0;
          dta_sigFromSrams_bore_5_ram_bypass = '0;
          dta_sigFromSrams_bore_5_ram_bp_clken = '0;
          dta_sigFromSrams_bore_5_ram_aux_clk = '0;
          dta_sigFromSrams_bore_5_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_5_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_5_cgen = '0;
          dta_sigFromSrams_bore_6_ram_hold = '0;
          dta_sigFromSrams_bore_6_ram_bypass = '0;
          dta_sigFromSrams_bore_6_ram_bp_clken = '0;
          dta_sigFromSrams_bore_6_ram_aux_clk = '0;
          dta_sigFromSrams_bore_6_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_6_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_6_cgen = '0;
          dta_sigFromSrams_bore_7_ram_hold = '0;
          dta_sigFromSrams_bore_7_ram_bypass = '0;
          dta_sigFromSrams_bore_7_ram_bp_clken = '0;
          dta_sigFromSrams_bore_7_ram_aux_clk = '0;
          dta_sigFromSrams_bore_7_ram_aux_ckbp = '0;
          dta_sigFromSrams_bore_7_ram_mcp_hold = '0;
          dta_sigFromSrams_bore_7_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 0 && dta_armed_at >= 0 && cyc >= dta_armed_at) begin
        checks++;
        if (dta_g_io_read_3_ready !== dta_i_io_read_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_read_3_ready g=%h i=%h", cyc, dta_g_io_read_3_ready, dta_i_io_read_3_ready);
        end
        dta_s1_io_read_3_ready |= dta_g_io_read_3_ready;
        dta_s0_io_read_3_ready |= ~dta_g_io_read_3_ready;
        checks++;
        if (dta_g_io_resp_0_0 !== dta_i_io_resp_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_0_0 g=%h i=%h", cyc, dta_g_io_resp_0_0, dta_i_io_resp_0_0);
        end
        dta_s1_io_resp_0_0 |= dta_g_io_resp_0_0;
        dta_s0_io_resp_0_0 |= ~dta_g_io_resp_0_0;
        checks++;
        if (dta_g_io_resp_0_1 !== dta_i_io_resp_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_0_1 g=%h i=%h", cyc, dta_g_io_resp_0_1, dta_i_io_resp_0_1);
        end
        dta_s1_io_resp_0_1 |= dta_g_io_resp_0_1;
        dta_s0_io_resp_0_1 |= ~dta_g_io_resp_0_1;
        checks++;
        if (dta_g_io_resp_0_2 !== dta_i_io_resp_0_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_0_2 g=%h i=%h", cyc, dta_g_io_resp_0_2, dta_i_io_resp_0_2);
        end
        dta_s1_io_resp_0_2 |= dta_g_io_resp_0_2;
        dta_s0_io_resp_0_2 |= ~dta_g_io_resp_0_2;
        checks++;
        if (dta_g_io_resp_0_3 !== dta_i_io_resp_0_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_0_3 g=%h i=%h", cyc, dta_g_io_resp_0_3, dta_i_io_resp_0_3);
        end
        dta_s1_io_resp_0_3 |= dta_g_io_resp_0_3;
        dta_s0_io_resp_0_3 |= ~dta_g_io_resp_0_3;
        checks++;
        if (dta_g_io_resp_1_0 !== dta_i_io_resp_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_1_0 g=%h i=%h", cyc, dta_g_io_resp_1_0, dta_i_io_resp_1_0);
        end
        dta_s1_io_resp_1_0 |= dta_g_io_resp_1_0;
        dta_s0_io_resp_1_0 |= ~dta_g_io_resp_1_0;
        checks++;
        if (dta_g_io_resp_1_1 !== dta_i_io_resp_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_1_1 g=%h i=%h", cyc, dta_g_io_resp_1_1, dta_i_io_resp_1_1);
        end
        dta_s1_io_resp_1_1 |= dta_g_io_resp_1_1;
        dta_s0_io_resp_1_1 |= ~dta_g_io_resp_1_1;
        checks++;
        if (dta_g_io_resp_1_2 !== dta_i_io_resp_1_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_1_2 g=%h i=%h", cyc, dta_g_io_resp_1_2, dta_i_io_resp_1_2);
        end
        dta_s1_io_resp_1_2 |= dta_g_io_resp_1_2;
        dta_s0_io_resp_1_2 |= ~dta_g_io_resp_1_2;
        checks++;
        if (dta_g_io_resp_1_3 !== dta_i_io_resp_1_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_1_3 g=%h i=%h", cyc, dta_g_io_resp_1_3, dta_i_io_resp_1_3);
        end
        dta_s1_io_resp_1_3 |= dta_g_io_resp_1_3;
        dta_s0_io_resp_1_3 |= ~dta_g_io_resp_1_3;
        checks++;
        if (dta_g_io_resp_2_0 !== dta_i_io_resp_2_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_2_0 g=%h i=%h", cyc, dta_g_io_resp_2_0, dta_i_io_resp_2_0);
        end
        dta_s1_io_resp_2_0 |= dta_g_io_resp_2_0;
        dta_s0_io_resp_2_0 |= ~dta_g_io_resp_2_0;
        checks++;
        if (dta_g_io_resp_2_1 !== dta_i_io_resp_2_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_2_1 g=%h i=%h", cyc, dta_g_io_resp_2_1, dta_i_io_resp_2_1);
        end
        dta_s1_io_resp_2_1 |= dta_g_io_resp_2_1;
        dta_s0_io_resp_2_1 |= ~dta_g_io_resp_2_1;
        checks++;
        if (dta_g_io_resp_2_2 !== dta_i_io_resp_2_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_2_2 g=%h i=%h", cyc, dta_g_io_resp_2_2, dta_i_io_resp_2_2);
        end
        dta_s1_io_resp_2_2 |= dta_g_io_resp_2_2;
        dta_s0_io_resp_2_2 |= ~dta_g_io_resp_2_2;
        checks++;
        if (dta_g_io_resp_2_3 !== dta_i_io_resp_2_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_2_3 g=%h i=%h", cyc, dta_g_io_resp_2_3, dta_i_io_resp_2_3);
        end
        dta_s1_io_resp_2_3 |= dta_g_io_resp_2_3;
        dta_s0_io_resp_2_3 |= ~dta_g_io_resp_2_3;
        checks++;
        if (dta_g_io_resp_3_0 !== dta_i_io_resp_3_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_3_0 g=%h i=%h", cyc, dta_g_io_resp_3_0, dta_i_io_resp_3_0);
        end
        dta_s1_io_resp_3_0 |= dta_g_io_resp_3_0;
        dta_s0_io_resp_3_0 |= ~dta_g_io_resp_3_0;
        checks++;
        if (dta_g_io_resp_3_1 !== dta_i_io_resp_3_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_3_1 g=%h i=%h", cyc, dta_g_io_resp_3_1, dta_i_io_resp_3_1);
        end
        dta_s1_io_resp_3_1 |= dta_g_io_resp_3_1;
        dta_s0_io_resp_3_1 |= ~dta_g_io_resp_3_1;
        checks++;
        if (dta_g_io_resp_3_2 !== dta_i_io_resp_3_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_3_2 g=%h i=%h", cyc, dta_g_io_resp_3_2, dta_i_io_resp_3_2);
        end
        dta_s1_io_resp_3_2 |= dta_g_io_resp_3_2;
        dta_s0_io_resp_3_2 |= ~dta_g_io_resp_3_2;
        checks++;
        if (dta_g_io_resp_3_3 !== dta_i_io_resp_3_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.io_resp_3_3 g=%h i=%h", cyc, dta_g_io_resp_3_3, dta_i_io_resp_3_3);
        end
        dta_s1_io_resp_3_3 |= dta_g_io_resp_3_3;
        dta_s0_io_resp_3_3 |= ~dta_g_io_resp_3_3;
        checks++;
        if (dta_g_boreChildrenBd_bore_ack !== dta_i_boreChildrenBd_bore_ack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.boreChildrenBd_bore_ack g=%h i=%h", cyc, dta_g_boreChildrenBd_bore_ack, dta_i_boreChildrenBd_bore_ack);
        end
        dta_s1_boreChildrenBd_bore_ack |= dta_g_boreChildrenBd_bore_ack;
        dta_s0_boreChildrenBd_bore_ack |= ~dta_g_boreChildrenBd_bore_ack;
        checks++;
        if (dta_g_boreChildrenBd_bore_outdata !== dta_i_boreChildrenBd_bore_outdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DuplicatedTagArray.boreChildrenBd_bore_outdata g=%h i=%h", cyc, dta_g_boreChildrenBd_bore_outdata, dta_i_boreChildrenBd_bore_outdata);
        end
        dta_s1_boreChildrenBd_bore_outdata |= dta_g_boreChildrenBd_bore_outdata;
        dta_s0_boreChildrenBd_bore_outdata |= ~dta_g_boreChildrenBd_bore_outdata;
        if (dta_io_write_valid) dta_cov_write++;
        if (dta_io_read_3_valid && !dta_g_io_read_3_ready) dta_cov_read3_blocked++;
        if (dta_boreChildrenBd_bore_req) dta_cov_mbist_req++;
        if (dta_io_write_valid && (^dta_io_write_bits_tag)) dta_cov_ecc_nonzero++;
      end
      if (dta_u_gold.array_0.tag_arrays_0.rst_cnt[8]) dta_armed[0] = 1'b1;
      if (dta_io_read_0_valid && dta_u_gold.array_0.tag_arrays_1.io_read_ready) dta_armed[1] = 1'b1;
      if (dta_io_read_1_valid && dta_u_gold.array_1.tag_arrays_1.io_read_ready) dta_armed[2] = 1'b1;
      if (dta_io_read_2_valid && dta_u_gold.array_2.tag_arrays_1.io_read_ready) dta_armed[3] = 1'b1;
      if (dta_io_read_3_valid && dta_u_gold.array_3.tag_arrays_1.io_read_ready) dta_armed[4] = 1'b1;
      if (dta_armed_at < 0 && (&dta_armed)) dta_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(dta_s0_io_read_3_ready && dta_s1_io_read_3_ready)) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_read_3_ready 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[0] && dta_s1_io_resp_0_0[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[1] && dta_s1_io_resp_0_0[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[2] && dta_s1_io_resp_0_0[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[3] && dta_s1_io_resp_0_0[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[4] && dta_s1_io_resp_0_0[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[5] && dta_s1_io_resp_0_0[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[6] && dta_s1_io_resp_0_0[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[7] && dta_s1_io_resp_0_0[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[8] && dta_s1_io_resp_0_0[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[9] && dta_s1_io_resp_0_0[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[10] && dta_s1_io_resp_0_0[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[11] && dta_s1_io_resp_0_0[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[12] && dta_s1_io_resp_0_0[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[13] && dta_s1_io_resp_0_0[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[14] && dta_s1_io_resp_0_0[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[15] && dta_s1_io_resp_0_0[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[16] && dta_s1_io_resp_0_0[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[17] && dta_s1_io_resp_0_0[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[18] && dta_s1_io_resp_0_0[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[19] && dta_s1_io_resp_0_0[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[20] && dta_s1_io_resp_0_0[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[21] && dta_s1_io_resp_0_0[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[22] && dta_s1_io_resp_0_0[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[23] && dta_s1_io_resp_0_0[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[24] && dta_s1_io_resp_0_0[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[25] && dta_s1_io_resp_0_0[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[26] && dta_s1_io_resp_0_0[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[27] && dta_s1_io_resp_0_0[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[28] && dta_s1_io_resp_0_0[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[29] && dta_s1_io_resp_0_0[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[30] && dta_s1_io_resp_0_0[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[31] && dta_s1_io_resp_0_0[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[32] && dta_s1_io_resp_0_0[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[33] && dta_s1_io_resp_0_0[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[34] && dta_s1_io_resp_0_0[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[35] && dta_s1_io_resp_0_0[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[36] && dta_s1_io_resp_0_0[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[37] && dta_s1_io_resp_0_0[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[38] && dta_s1_io_resp_0_0[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[39] && dta_s1_io_resp_0_0[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[40] && dta_s1_io_resp_0_0[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[41] && dta_s1_io_resp_0_0[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_0[42] && dta_s1_io_resp_0_0[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_0[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[0] && dta_s1_io_resp_0_1[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[1] && dta_s1_io_resp_0_1[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[2] && dta_s1_io_resp_0_1[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[3] && dta_s1_io_resp_0_1[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[4] && dta_s1_io_resp_0_1[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[5] && dta_s1_io_resp_0_1[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[6] && dta_s1_io_resp_0_1[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[7] && dta_s1_io_resp_0_1[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[8] && dta_s1_io_resp_0_1[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[9] && dta_s1_io_resp_0_1[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[10] && dta_s1_io_resp_0_1[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[11] && dta_s1_io_resp_0_1[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[12] && dta_s1_io_resp_0_1[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[13] && dta_s1_io_resp_0_1[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[14] && dta_s1_io_resp_0_1[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[15] && dta_s1_io_resp_0_1[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[16] && dta_s1_io_resp_0_1[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[17] && dta_s1_io_resp_0_1[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[18] && dta_s1_io_resp_0_1[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[19] && dta_s1_io_resp_0_1[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[20] && dta_s1_io_resp_0_1[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[21] && dta_s1_io_resp_0_1[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[22] && dta_s1_io_resp_0_1[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[23] && dta_s1_io_resp_0_1[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[24] && dta_s1_io_resp_0_1[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[25] && dta_s1_io_resp_0_1[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[26] && dta_s1_io_resp_0_1[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[27] && dta_s1_io_resp_0_1[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[28] && dta_s1_io_resp_0_1[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[29] && dta_s1_io_resp_0_1[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[30] && dta_s1_io_resp_0_1[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[31] && dta_s1_io_resp_0_1[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[32] && dta_s1_io_resp_0_1[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[33] && dta_s1_io_resp_0_1[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[34] && dta_s1_io_resp_0_1[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[35] && dta_s1_io_resp_0_1[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[36] && dta_s1_io_resp_0_1[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[37] && dta_s1_io_resp_0_1[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[38] && dta_s1_io_resp_0_1[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[39] && dta_s1_io_resp_0_1[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[40] && dta_s1_io_resp_0_1[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[41] && dta_s1_io_resp_0_1[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_1[42] && dta_s1_io_resp_0_1[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_1[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[0] && dta_s1_io_resp_0_2[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[1] && dta_s1_io_resp_0_2[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[2] && dta_s1_io_resp_0_2[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[3] && dta_s1_io_resp_0_2[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[4] && dta_s1_io_resp_0_2[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[5] && dta_s1_io_resp_0_2[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[6] && dta_s1_io_resp_0_2[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[7] && dta_s1_io_resp_0_2[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[8] && dta_s1_io_resp_0_2[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[9] && dta_s1_io_resp_0_2[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[10] && dta_s1_io_resp_0_2[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[11] && dta_s1_io_resp_0_2[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[12] && dta_s1_io_resp_0_2[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[13] && dta_s1_io_resp_0_2[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[14] && dta_s1_io_resp_0_2[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[15] && dta_s1_io_resp_0_2[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[16] && dta_s1_io_resp_0_2[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[17] && dta_s1_io_resp_0_2[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[18] && dta_s1_io_resp_0_2[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[19] && dta_s1_io_resp_0_2[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[20] && dta_s1_io_resp_0_2[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[21] && dta_s1_io_resp_0_2[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[22] && dta_s1_io_resp_0_2[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[23] && dta_s1_io_resp_0_2[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[24] && dta_s1_io_resp_0_2[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[25] && dta_s1_io_resp_0_2[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[26] && dta_s1_io_resp_0_2[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[27] && dta_s1_io_resp_0_2[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[28] && dta_s1_io_resp_0_2[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[29] && dta_s1_io_resp_0_2[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[30] && dta_s1_io_resp_0_2[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[31] && dta_s1_io_resp_0_2[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[32] && dta_s1_io_resp_0_2[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[33] && dta_s1_io_resp_0_2[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[34] && dta_s1_io_resp_0_2[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[35] && dta_s1_io_resp_0_2[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[36] && dta_s1_io_resp_0_2[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[37] && dta_s1_io_resp_0_2[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[38] && dta_s1_io_resp_0_2[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[39] && dta_s1_io_resp_0_2[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[40] && dta_s1_io_resp_0_2[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[41] && dta_s1_io_resp_0_2[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_2[42] && dta_s1_io_resp_0_2[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_2[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[0] && dta_s1_io_resp_0_3[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[1] && dta_s1_io_resp_0_3[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[2] && dta_s1_io_resp_0_3[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[3] && dta_s1_io_resp_0_3[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[4] && dta_s1_io_resp_0_3[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[5] && dta_s1_io_resp_0_3[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[6] && dta_s1_io_resp_0_3[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[7] && dta_s1_io_resp_0_3[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[8] && dta_s1_io_resp_0_3[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[9] && dta_s1_io_resp_0_3[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[10] && dta_s1_io_resp_0_3[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[11] && dta_s1_io_resp_0_3[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[12] && dta_s1_io_resp_0_3[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[13] && dta_s1_io_resp_0_3[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[14] && dta_s1_io_resp_0_3[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[15] && dta_s1_io_resp_0_3[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[16] && dta_s1_io_resp_0_3[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[17] && dta_s1_io_resp_0_3[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[18] && dta_s1_io_resp_0_3[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[19] && dta_s1_io_resp_0_3[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[20] && dta_s1_io_resp_0_3[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[21] && dta_s1_io_resp_0_3[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[22] && dta_s1_io_resp_0_3[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[23] && dta_s1_io_resp_0_3[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[24] && dta_s1_io_resp_0_3[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[25] && dta_s1_io_resp_0_3[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[26] && dta_s1_io_resp_0_3[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[27] && dta_s1_io_resp_0_3[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[28] && dta_s1_io_resp_0_3[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[29] && dta_s1_io_resp_0_3[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[30] && dta_s1_io_resp_0_3[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[31] && dta_s1_io_resp_0_3[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[32] && dta_s1_io_resp_0_3[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[33] && dta_s1_io_resp_0_3[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[34] && dta_s1_io_resp_0_3[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[35] && dta_s1_io_resp_0_3[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[36] && dta_s1_io_resp_0_3[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[37] && dta_s1_io_resp_0_3[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[38] && dta_s1_io_resp_0_3[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[39] && dta_s1_io_resp_0_3[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[40] && dta_s1_io_resp_0_3[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[41] && dta_s1_io_resp_0_3[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_0_3[42] && dta_s1_io_resp_0_3[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_0_3[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[0] && dta_s1_io_resp_1_0[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[1] && dta_s1_io_resp_1_0[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[2] && dta_s1_io_resp_1_0[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[3] && dta_s1_io_resp_1_0[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[4] && dta_s1_io_resp_1_0[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[5] && dta_s1_io_resp_1_0[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[6] && dta_s1_io_resp_1_0[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[7] && dta_s1_io_resp_1_0[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[8] && dta_s1_io_resp_1_0[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[9] && dta_s1_io_resp_1_0[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[10] && dta_s1_io_resp_1_0[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[11] && dta_s1_io_resp_1_0[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[12] && dta_s1_io_resp_1_0[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[13] && dta_s1_io_resp_1_0[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[14] && dta_s1_io_resp_1_0[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[15] && dta_s1_io_resp_1_0[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[16] && dta_s1_io_resp_1_0[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[17] && dta_s1_io_resp_1_0[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[18] && dta_s1_io_resp_1_0[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[19] && dta_s1_io_resp_1_0[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[20] && dta_s1_io_resp_1_0[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[21] && dta_s1_io_resp_1_0[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[22] && dta_s1_io_resp_1_0[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[23] && dta_s1_io_resp_1_0[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[24] && dta_s1_io_resp_1_0[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[25] && dta_s1_io_resp_1_0[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[26] && dta_s1_io_resp_1_0[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[27] && dta_s1_io_resp_1_0[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[28] && dta_s1_io_resp_1_0[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[29] && dta_s1_io_resp_1_0[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[30] && dta_s1_io_resp_1_0[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[31] && dta_s1_io_resp_1_0[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[32] && dta_s1_io_resp_1_0[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[33] && dta_s1_io_resp_1_0[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[34] && dta_s1_io_resp_1_0[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[35] && dta_s1_io_resp_1_0[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[36] && dta_s1_io_resp_1_0[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[37] && dta_s1_io_resp_1_0[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[38] && dta_s1_io_resp_1_0[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[39] && dta_s1_io_resp_1_0[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[40] && dta_s1_io_resp_1_0[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[41] && dta_s1_io_resp_1_0[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_0[42] && dta_s1_io_resp_1_0[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_0[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[0] && dta_s1_io_resp_1_1[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[1] && dta_s1_io_resp_1_1[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[2] && dta_s1_io_resp_1_1[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[3] && dta_s1_io_resp_1_1[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[4] && dta_s1_io_resp_1_1[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[5] && dta_s1_io_resp_1_1[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[6] && dta_s1_io_resp_1_1[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[7] && dta_s1_io_resp_1_1[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[8] && dta_s1_io_resp_1_1[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[9] && dta_s1_io_resp_1_1[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[10] && dta_s1_io_resp_1_1[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[11] && dta_s1_io_resp_1_1[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[12] && dta_s1_io_resp_1_1[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[13] && dta_s1_io_resp_1_1[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[14] && dta_s1_io_resp_1_1[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[15] && dta_s1_io_resp_1_1[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[16] && dta_s1_io_resp_1_1[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[17] && dta_s1_io_resp_1_1[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[18] && dta_s1_io_resp_1_1[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[19] && dta_s1_io_resp_1_1[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[20] && dta_s1_io_resp_1_1[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[21] && dta_s1_io_resp_1_1[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[22] && dta_s1_io_resp_1_1[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[23] && dta_s1_io_resp_1_1[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[24] && dta_s1_io_resp_1_1[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[25] && dta_s1_io_resp_1_1[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[26] && dta_s1_io_resp_1_1[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[27] && dta_s1_io_resp_1_1[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[28] && dta_s1_io_resp_1_1[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[29] && dta_s1_io_resp_1_1[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[30] && dta_s1_io_resp_1_1[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[31] && dta_s1_io_resp_1_1[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[32] && dta_s1_io_resp_1_1[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[33] && dta_s1_io_resp_1_1[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[34] && dta_s1_io_resp_1_1[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[35] && dta_s1_io_resp_1_1[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[36] && dta_s1_io_resp_1_1[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[37] && dta_s1_io_resp_1_1[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[38] && dta_s1_io_resp_1_1[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[39] && dta_s1_io_resp_1_1[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[40] && dta_s1_io_resp_1_1[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[41] && dta_s1_io_resp_1_1[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_1[42] && dta_s1_io_resp_1_1[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_1[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[0] && dta_s1_io_resp_1_2[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[1] && dta_s1_io_resp_1_2[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[2] && dta_s1_io_resp_1_2[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[3] && dta_s1_io_resp_1_2[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[4] && dta_s1_io_resp_1_2[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[5] && dta_s1_io_resp_1_2[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[6] && dta_s1_io_resp_1_2[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[7] && dta_s1_io_resp_1_2[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[8] && dta_s1_io_resp_1_2[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[9] && dta_s1_io_resp_1_2[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[10] && dta_s1_io_resp_1_2[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[11] && dta_s1_io_resp_1_2[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[12] && dta_s1_io_resp_1_2[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[13] && dta_s1_io_resp_1_2[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[14] && dta_s1_io_resp_1_2[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[15] && dta_s1_io_resp_1_2[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[16] && dta_s1_io_resp_1_2[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[17] && dta_s1_io_resp_1_2[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[18] && dta_s1_io_resp_1_2[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[19] && dta_s1_io_resp_1_2[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[20] && dta_s1_io_resp_1_2[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[21] && dta_s1_io_resp_1_2[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[22] && dta_s1_io_resp_1_2[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[23] && dta_s1_io_resp_1_2[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[24] && dta_s1_io_resp_1_2[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[25] && dta_s1_io_resp_1_2[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[26] && dta_s1_io_resp_1_2[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[27] && dta_s1_io_resp_1_2[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[28] && dta_s1_io_resp_1_2[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[29] && dta_s1_io_resp_1_2[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[30] && dta_s1_io_resp_1_2[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[31] && dta_s1_io_resp_1_2[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[32] && dta_s1_io_resp_1_2[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[33] && dta_s1_io_resp_1_2[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[34] && dta_s1_io_resp_1_2[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[35] && dta_s1_io_resp_1_2[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[36] && dta_s1_io_resp_1_2[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[37] && dta_s1_io_resp_1_2[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[38] && dta_s1_io_resp_1_2[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[39] && dta_s1_io_resp_1_2[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[40] && dta_s1_io_resp_1_2[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[41] && dta_s1_io_resp_1_2[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_2[42] && dta_s1_io_resp_1_2[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_2[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[0] && dta_s1_io_resp_1_3[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[1] && dta_s1_io_resp_1_3[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[2] && dta_s1_io_resp_1_3[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[3] && dta_s1_io_resp_1_3[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[4] && dta_s1_io_resp_1_3[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[5] && dta_s1_io_resp_1_3[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[6] && dta_s1_io_resp_1_3[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[7] && dta_s1_io_resp_1_3[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[8] && dta_s1_io_resp_1_3[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[9] && dta_s1_io_resp_1_3[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[10] && dta_s1_io_resp_1_3[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[11] && dta_s1_io_resp_1_3[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[12] && dta_s1_io_resp_1_3[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[13] && dta_s1_io_resp_1_3[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[14] && dta_s1_io_resp_1_3[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[15] && dta_s1_io_resp_1_3[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[16] && dta_s1_io_resp_1_3[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[17] && dta_s1_io_resp_1_3[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[18] && dta_s1_io_resp_1_3[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[19] && dta_s1_io_resp_1_3[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[20] && dta_s1_io_resp_1_3[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[21] && dta_s1_io_resp_1_3[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[22] && dta_s1_io_resp_1_3[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[23] && dta_s1_io_resp_1_3[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[24] && dta_s1_io_resp_1_3[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[25] && dta_s1_io_resp_1_3[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[26] && dta_s1_io_resp_1_3[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[27] && dta_s1_io_resp_1_3[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[28] && dta_s1_io_resp_1_3[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[29] && dta_s1_io_resp_1_3[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[30] && dta_s1_io_resp_1_3[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[31] && dta_s1_io_resp_1_3[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[32] && dta_s1_io_resp_1_3[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[33] && dta_s1_io_resp_1_3[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[34] && dta_s1_io_resp_1_3[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[35] && dta_s1_io_resp_1_3[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[36] && dta_s1_io_resp_1_3[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[37] && dta_s1_io_resp_1_3[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[38] && dta_s1_io_resp_1_3[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[39] && dta_s1_io_resp_1_3[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[40] && dta_s1_io_resp_1_3[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[41] && dta_s1_io_resp_1_3[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_1_3[42] && dta_s1_io_resp_1_3[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_1_3[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[0] && dta_s1_io_resp_2_0[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[1] && dta_s1_io_resp_2_0[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[2] && dta_s1_io_resp_2_0[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[3] && dta_s1_io_resp_2_0[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[4] && dta_s1_io_resp_2_0[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[5] && dta_s1_io_resp_2_0[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[6] && dta_s1_io_resp_2_0[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[7] && dta_s1_io_resp_2_0[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[8] && dta_s1_io_resp_2_0[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[9] && dta_s1_io_resp_2_0[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[10] && dta_s1_io_resp_2_0[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[11] && dta_s1_io_resp_2_0[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[12] && dta_s1_io_resp_2_0[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[13] && dta_s1_io_resp_2_0[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[14] && dta_s1_io_resp_2_0[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[15] && dta_s1_io_resp_2_0[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[16] && dta_s1_io_resp_2_0[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[17] && dta_s1_io_resp_2_0[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[18] && dta_s1_io_resp_2_0[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[19] && dta_s1_io_resp_2_0[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[20] && dta_s1_io_resp_2_0[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[21] && dta_s1_io_resp_2_0[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[22] && dta_s1_io_resp_2_0[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[23] && dta_s1_io_resp_2_0[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[24] && dta_s1_io_resp_2_0[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[25] && dta_s1_io_resp_2_0[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[26] && dta_s1_io_resp_2_0[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[27] && dta_s1_io_resp_2_0[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[28] && dta_s1_io_resp_2_0[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[29] && dta_s1_io_resp_2_0[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[30] && dta_s1_io_resp_2_0[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[31] && dta_s1_io_resp_2_0[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[32] && dta_s1_io_resp_2_0[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[33] && dta_s1_io_resp_2_0[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[34] && dta_s1_io_resp_2_0[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[35] && dta_s1_io_resp_2_0[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[36] && dta_s1_io_resp_2_0[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[37] && dta_s1_io_resp_2_0[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[38] && dta_s1_io_resp_2_0[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[39] && dta_s1_io_resp_2_0[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[40] && dta_s1_io_resp_2_0[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[41] && dta_s1_io_resp_2_0[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_0[42] && dta_s1_io_resp_2_0[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_0[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[0] && dta_s1_io_resp_2_1[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[1] && dta_s1_io_resp_2_1[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[2] && dta_s1_io_resp_2_1[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[3] && dta_s1_io_resp_2_1[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[4] && dta_s1_io_resp_2_1[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[5] && dta_s1_io_resp_2_1[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[6] && dta_s1_io_resp_2_1[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[7] && dta_s1_io_resp_2_1[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[8] && dta_s1_io_resp_2_1[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[9] && dta_s1_io_resp_2_1[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[10] && dta_s1_io_resp_2_1[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[11] && dta_s1_io_resp_2_1[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[12] && dta_s1_io_resp_2_1[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[13] && dta_s1_io_resp_2_1[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[14] && dta_s1_io_resp_2_1[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[15] && dta_s1_io_resp_2_1[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[16] && dta_s1_io_resp_2_1[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[17] && dta_s1_io_resp_2_1[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[18] && dta_s1_io_resp_2_1[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[19] && dta_s1_io_resp_2_1[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[20] && dta_s1_io_resp_2_1[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[21] && dta_s1_io_resp_2_1[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[22] && dta_s1_io_resp_2_1[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[23] && dta_s1_io_resp_2_1[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[24] && dta_s1_io_resp_2_1[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[25] && dta_s1_io_resp_2_1[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[26] && dta_s1_io_resp_2_1[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[27] && dta_s1_io_resp_2_1[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[28] && dta_s1_io_resp_2_1[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[29] && dta_s1_io_resp_2_1[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[30] && dta_s1_io_resp_2_1[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[31] && dta_s1_io_resp_2_1[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[32] && dta_s1_io_resp_2_1[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[33] && dta_s1_io_resp_2_1[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[34] && dta_s1_io_resp_2_1[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[35] && dta_s1_io_resp_2_1[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[36] && dta_s1_io_resp_2_1[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[37] && dta_s1_io_resp_2_1[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[38] && dta_s1_io_resp_2_1[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[39] && dta_s1_io_resp_2_1[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[40] && dta_s1_io_resp_2_1[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[41] && dta_s1_io_resp_2_1[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_1[42] && dta_s1_io_resp_2_1[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_1[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[0] && dta_s1_io_resp_2_2[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[1] && dta_s1_io_resp_2_2[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[2] && dta_s1_io_resp_2_2[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[3] && dta_s1_io_resp_2_2[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[4] && dta_s1_io_resp_2_2[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[5] && dta_s1_io_resp_2_2[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[6] && dta_s1_io_resp_2_2[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[7] && dta_s1_io_resp_2_2[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[8] && dta_s1_io_resp_2_2[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[9] && dta_s1_io_resp_2_2[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[10] && dta_s1_io_resp_2_2[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[11] && dta_s1_io_resp_2_2[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[12] && dta_s1_io_resp_2_2[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[13] && dta_s1_io_resp_2_2[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[14] && dta_s1_io_resp_2_2[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[15] && dta_s1_io_resp_2_2[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[16] && dta_s1_io_resp_2_2[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[17] && dta_s1_io_resp_2_2[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[18] && dta_s1_io_resp_2_2[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[19] && dta_s1_io_resp_2_2[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[20] && dta_s1_io_resp_2_2[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[21] && dta_s1_io_resp_2_2[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[22] && dta_s1_io_resp_2_2[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[23] && dta_s1_io_resp_2_2[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[24] && dta_s1_io_resp_2_2[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[25] && dta_s1_io_resp_2_2[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[26] && dta_s1_io_resp_2_2[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[27] && dta_s1_io_resp_2_2[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[28] && dta_s1_io_resp_2_2[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[29] && dta_s1_io_resp_2_2[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[30] && dta_s1_io_resp_2_2[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[31] && dta_s1_io_resp_2_2[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[32] && dta_s1_io_resp_2_2[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[33] && dta_s1_io_resp_2_2[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[34] && dta_s1_io_resp_2_2[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[35] && dta_s1_io_resp_2_2[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[36] && dta_s1_io_resp_2_2[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[37] && dta_s1_io_resp_2_2[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[38] && dta_s1_io_resp_2_2[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[39] && dta_s1_io_resp_2_2[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[40] && dta_s1_io_resp_2_2[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[41] && dta_s1_io_resp_2_2[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_2[42] && dta_s1_io_resp_2_2[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_2[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[0] && dta_s1_io_resp_2_3[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[1] && dta_s1_io_resp_2_3[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[2] && dta_s1_io_resp_2_3[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[3] && dta_s1_io_resp_2_3[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[4] && dta_s1_io_resp_2_3[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[5] && dta_s1_io_resp_2_3[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[6] && dta_s1_io_resp_2_3[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[7] && dta_s1_io_resp_2_3[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[8] && dta_s1_io_resp_2_3[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[9] && dta_s1_io_resp_2_3[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[10] && dta_s1_io_resp_2_3[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[11] && dta_s1_io_resp_2_3[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[12] && dta_s1_io_resp_2_3[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[13] && dta_s1_io_resp_2_3[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[14] && dta_s1_io_resp_2_3[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[15] && dta_s1_io_resp_2_3[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[16] && dta_s1_io_resp_2_3[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[17] && dta_s1_io_resp_2_3[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[18] && dta_s1_io_resp_2_3[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[19] && dta_s1_io_resp_2_3[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[20] && dta_s1_io_resp_2_3[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[21] && dta_s1_io_resp_2_3[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[22] && dta_s1_io_resp_2_3[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[23] && dta_s1_io_resp_2_3[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[24] && dta_s1_io_resp_2_3[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[25] && dta_s1_io_resp_2_3[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[26] && dta_s1_io_resp_2_3[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[27] && dta_s1_io_resp_2_3[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[28] && dta_s1_io_resp_2_3[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[29] && dta_s1_io_resp_2_3[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[30] && dta_s1_io_resp_2_3[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[31] && dta_s1_io_resp_2_3[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[32] && dta_s1_io_resp_2_3[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[33] && dta_s1_io_resp_2_3[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[34] && dta_s1_io_resp_2_3[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[35] && dta_s1_io_resp_2_3[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[36] && dta_s1_io_resp_2_3[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[37] && dta_s1_io_resp_2_3[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[38] && dta_s1_io_resp_2_3[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[39] && dta_s1_io_resp_2_3[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[40] && dta_s1_io_resp_2_3[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[41] && dta_s1_io_resp_2_3[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_2_3[42] && dta_s1_io_resp_2_3[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_2_3[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[0] && dta_s1_io_resp_3_0[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[1] && dta_s1_io_resp_3_0[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[2] && dta_s1_io_resp_3_0[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[3] && dta_s1_io_resp_3_0[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[4] && dta_s1_io_resp_3_0[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[5] && dta_s1_io_resp_3_0[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[6] && dta_s1_io_resp_3_0[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[7] && dta_s1_io_resp_3_0[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[8] && dta_s1_io_resp_3_0[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[9] && dta_s1_io_resp_3_0[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[10] && dta_s1_io_resp_3_0[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[11] && dta_s1_io_resp_3_0[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[12] && dta_s1_io_resp_3_0[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[13] && dta_s1_io_resp_3_0[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[14] && dta_s1_io_resp_3_0[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[15] && dta_s1_io_resp_3_0[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[16] && dta_s1_io_resp_3_0[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[17] && dta_s1_io_resp_3_0[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[18] && dta_s1_io_resp_3_0[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[19] && dta_s1_io_resp_3_0[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[20] && dta_s1_io_resp_3_0[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[21] && dta_s1_io_resp_3_0[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[22] && dta_s1_io_resp_3_0[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[23] && dta_s1_io_resp_3_0[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[24] && dta_s1_io_resp_3_0[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[25] && dta_s1_io_resp_3_0[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[26] && dta_s1_io_resp_3_0[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[27] && dta_s1_io_resp_3_0[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[28] && dta_s1_io_resp_3_0[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[29] && dta_s1_io_resp_3_0[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[30] && dta_s1_io_resp_3_0[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[31] && dta_s1_io_resp_3_0[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[32] && dta_s1_io_resp_3_0[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[33] && dta_s1_io_resp_3_0[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[34] && dta_s1_io_resp_3_0[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[35] && dta_s1_io_resp_3_0[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[36] && dta_s1_io_resp_3_0[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[37] && dta_s1_io_resp_3_0[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[38] && dta_s1_io_resp_3_0[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[39] && dta_s1_io_resp_3_0[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[40] && dta_s1_io_resp_3_0[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[41] && dta_s1_io_resp_3_0[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_0[42] && dta_s1_io_resp_3_0[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_0[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[0] && dta_s1_io_resp_3_1[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[1] && dta_s1_io_resp_3_1[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[2] && dta_s1_io_resp_3_1[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[3] && dta_s1_io_resp_3_1[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[4] && dta_s1_io_resp_3_1[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[5] && dta_s1_io_resp_3_1[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[6] && dta_s1_io_resp_3_1[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[7] && dta_s1_io_resp_3_1[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[8] && dta_s1_io_resp_3_1[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[9] && dta_s1_io_resp_3_1[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[10] && dta_s1_io_resp_3_1[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[11] && dta_s1_io_resp_3_1[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[12] && dta_s1_io_resp_3_1[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[13] && dta_s1_io_resp_3_1[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[14] && dta_s1_io_resp_3_1[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[15] && dta_s1_io_resp_3_1[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[16] && dta_s1_io_resp_3_1[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[17] && dta_s1_io_resp_3_1[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[18] && dta_s1_io_resp_3_1[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[19] && dta_s1_io_resp_3_1[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[20] && dta_s1_io_resp_3_1[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[21] && dta_s1_io_resp_3_1[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[22] && dta_s1_io_resp_3_1[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[23] && dta_s1_io_resp_3_1[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[24] && dta_s1_io_resp_3_1[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[25] && dta_s1_io_resp_3_1[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[26] && dta_s1_io_resp_3_1[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[27] && dta_s1_io_resp_3_1[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[28] && dta_s1_io_resp_3_1[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[29] && dta_s1_io_resp_3_1[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[30] && dta_s1_io_resp_3_1[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[31] && dta_s1_io_resp_3_1[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[32] && dta_s1_io_resp_3_1[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[33] && dta_s1_io_resp_3_1[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[34] && dta_s1_io_resp_3_1[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[35] && dta_s1_io_resp_3_1[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[36] && dta_s1_io_resp_3_1[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[37] && dta_s1_io_resp_3_1[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[38] && dta_s1_io_resp_3_1[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[39] && dta_s1_io_resp_3_1[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[40] && dta_s1_io_resp_3_1[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[41] && dta_s1_io_resp_3_1[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_1[42] && dta_s1_io_resp_3_1[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_1[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[0] && dta_s1_io_resp_3_2[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[1] && dta_s1_io_resp_3_2[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[2] && dta_s1_io_resp_3_2[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[3] && dta_s1_io_resp_3_2[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[4] && dta_s1_io_resp_3_2[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[5] && dta_s1_io_resp_3_2[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[6] && dta_s1_io_resp_3_2[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[7] && dta_s1_io_resp_3_2[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[8] && dta_s1_io_resp_3_2[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[9] && dta_s1_io_resp_3_2[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[10] && dta_s1_io_resp_3_2[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[11] && dta_s1_io_resp_3_2[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[12] && dta_s1_io_resp_3_2[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[13] && dta_s1_io_resp_3_2[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[14] && dta_s1_io_resp_3_2[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[15] && dta_s1_io_resp_3_2[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[16] && dta_s1_io_resp_3_2[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[17] && dta_s1_io_resp_3_2[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[18] && dta_s1_io_resp_3_2[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[19] && dta_s1_io_resp_3_2[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[20] && dta_s1_io_resp_3_2[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[21] && dta_s1_io_resp_3_2[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[22] && dta_s1_io_resp_3_2[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[23] && dta_s1_io_resp_3_2[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[24] && dta_s1_io_resp_3_2[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[25] && dta_s1_io_resp_3_2[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[26] && dta_s1_io_resp_3_2[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[27] && dta_s1_io_resp_3_2[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[28] && dta_s1_io_resp_3_2[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[29] && dta_s1_io_resp_3_2[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[30] && dta_s1_io_resp_3_2[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[31] && dta_s1_io_resp_3_2[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[32] && dta_s1_io_resp_3_2[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[33] && dta_s1_io_resp_3_2[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[34] && dta_s1_io_resp_3_2[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[35] && dta_s1_io_resp_3_2[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[36] && dta_s1_io_resp_3_2[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[37] && dta_s1_io_resp_3_2[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[38] && dta_s1_io_resp_3_2[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[39] && dta_s1_io_resp_3_2[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[40] && dta_s1_io_resp_3_2[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[41] && dta_s1_io_resp_3_2[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_2[42] && dta_s1_io_resp_3_2[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_2[42] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[0] && dta_s1_io_resp_3_3[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[0] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[1] && dta_s1_io_resp_3_3[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[1] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[2] && dta_s1_io_resp_3_3[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[2] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[3] && dta_s1_io_resp_3_3[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[3] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[4] && dta_s1_io_resp_3_3[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[4] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[5] && dta_s1_io_resp_3_3[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[5] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[6] && dta_s1_io_resp_3_3[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[6] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[7] && dta_s1_io_resp_3_3[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[7] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[8] && dta_s1_io_resp_3_3[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[8] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[9] && dta_s1_io_resp_3_3[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[9] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[10] && dta_s1_io_resp_3_3[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[10] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[11] && dta_s1_io_resp_3_3[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[11] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[12] && dta_s1_io_resp_3_3[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[12] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[13] && dta_s1_io_resp_3_3[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[13] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[14] && dta_s1_io_resp_3_3[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[14] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[15] && dta_s1_io_resp_3_3[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[15] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[16] && dta_s1_io_resp_3_3[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[16] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[17] && dta_s1_io_resp_3_3[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[17] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[18] && dta_s1_io_resp_3_3[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[18] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[19] && dta_s1_io_resp_3_3[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[19] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[20] && dta_s1_io_resp_3_3[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[20] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[21] && dta_s1_io_resp_3_3[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[21] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[22] && dta_s1_io_resp_3_3[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[22] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[23] && dta_s1_io_resp_3_3[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[23] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[24] && dta_s1_io_resp_3_3[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[24] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[25] && dta_s1_io_resp_3_3[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[25] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[26] && dta_s1_io_resp_3_3[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[26] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[27] && dta_s1_io_resp_3_3[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[27] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[28] && dta_s1_io_resp_3_3[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[28] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[29] && dta_s1_io_resp_3_3[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[29] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[30] && dta_s1_io_resp_3_3[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[30] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[31] && dta_s1_io_resp_3_3[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[31] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[32] && dta_s1_io_resp_3_3[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[32] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[33] && dta_s1_io_resp_3_3[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[33] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[34] && dta_s1_io_resp_3_3[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[34] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[35] && dta_s1_io_resp_3_3[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[35] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[36] && dta_s1_io_resp_3_3[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[36] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[37] && dta_s1_io_resp_3_3[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[37] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[38] && dta_s1_io_resp_3_3[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[38] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[39] && dta_s1_io_resp_3_3[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[39] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[40] && dta_s1_io_resp_3_3[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[40] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[41] && dta_s1_io_resp_3_3[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[41] 未见过 0 和 1"); end
    if (!(dta_s0_io_resp_3_3[42] && dta_s1_io_resp_3_3[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.io_resp_3_3[42] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_ack && dta_s1_boreChildrenBd_bore_ack)) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_ack 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[0] && dta_s1_boreChildrenBd_bore_outdata[0])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[0] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[1] && dta_s1_boreChildrenBd_bore_outdata[1])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[1] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[2] && dta_s1_boreChildrenBd_bore_outdata[2])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[2] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[3] && dta_s1_boreChildrenBd_bore_outdata[3])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[3] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[4] && dta_s1_boreChildrenBd_bore_outdata[4])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[4] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[5] && dta_s1_boreChildrenBd_bore_outdata[5])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[5] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[6] && dta_s1_boreChildrenBd_bore_outdata[6])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[6] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[7] && dta_s1_boreChildrenBd_bore_outdata[7])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[7] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[8] && dta_s1_boreChildrenBd_bore_outdata[8])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[8] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[9] && dta_s1_boreChildrenBd_bore_outdata[9])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[9] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[10] && dta_s1_boreChildrenBd_bore_outdata[10])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[10] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[11] && dta_s1_boreChildrenBd_bore_outdata[11])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[11] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[12] && dta_s1_boreChildrenBd_bore_outdata[12])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[12] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[13] && dta_s1_boreChildrenBd_bore_outdata[13])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[13] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[14] && dta_s1_boreChildrenBd_bore_outdata[14])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[14] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[15] && dta_s1_boreChildrenBd_bore_outdata[15])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[15] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[16] && dta_s1_boreChildrenBd_bore_outdata[16])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[16] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[17] && dta_s1_boreChildrenBd_bore_outdata[17])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[17] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[18] && dta_s1_boreChildrenBd_bore_outdata[18])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[18] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[19] && dta_s1_boreChildrenBd_bore_outdata[19])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[19] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[20] && dta_s1_boreChildrenBd_bore_outdata[20])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[20] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[21] && dta_s1_boreChildrenBd_bore_outdata[21])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[21] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[22] && dta_s1_boreChildrenBd_bore_outdata[22])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[22] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[23] && dta_s1_boreChildrenBd_bore_outdata[23])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[23] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[24] && dta_s1_boreChildrenBd_bore_outdata[24])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[24] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[25] && dta_s1_boreChildrenBd_bore_outdata[25])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[25] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[26] && dta_s1_boreChildrenBd_bore_outdata[26])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[26] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[27] && dta_s1_boreChildrenBd_bore_outdata[27])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[27] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[28] && dta_s1_boreChildrenBd_bore_outdata[28])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[28] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[29] && dta_s1_boreChildrenBd_bore_outdata[29])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[29] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[30] && dta_s1_boreChildrenBd_bore_outdata[30])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[30] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[31] && dta_s1_boreChildrenBd_bore_outdata[31])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[31] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[32] && dta_s1_boreChildrenBd_bore_outdata[32])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[32] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[33] && dta_s1_boreChildrenBd_bore_outdata[33])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[33] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[34] && dta_s1_boreChildrenBd_bore_outdata[34])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[34] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[35] && dta_s1_boreChildrenBd_bore_outdata[35])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[35] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[36] && dta_s1_boreChildrenBd_bore_outdata[36])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[36] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[37] && dta_s1_boreChildrenBd_bore_outdata[37])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[37] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[38] && dta_s1_boreChildrenBd_bore_outdata[38])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[38] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[39] && dta_s1_boreChildrenBd_bore_outdata[39])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[39] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[40] && dta_s1_boreChildrenBd_bore_outdata[40])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[40] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[41] && dta_s1_boreChildrenBd_bore_outdata[41])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[41] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[42] && dta_s1_boreChildrenBd_bore_outdata[42])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[42] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[43] && dta_s1_boreChildrenBd_bore_outdata[43])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[43] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[44] && dta_s1_boreChildrenBd_bore_outdata[44])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[44] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[45] && dta_s1_boreChildrenBd_bore_outdata[45])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[45] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[46] && dta_s1_boreChildrenBd_bore_outdata[46])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[46] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[47] && dta_s1_boreChildrenBd_bore_outdata[47])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[47] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[48] && dta_s1_boreChildrenBd_bore_outdata[48])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[48] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[49] && dta_s1_boreChildrenBd_bore_outdata[49])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[49] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[50] && dta_s1_boreChildrenBd_bore_outdata[50])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[50] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[51] && dta_s1_boreChildrenBd_bore_outdata[51])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[51] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[52] && dta_s1_boreChildrenBd_bore_outdata[52])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[52] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[53] && dta_s1_boreChildrenBd_bore_outdata[53])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[53] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[54] && dta_s1_boreChildrenBd_bore_outdata[54])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[54] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[55] && dta_s1_boreChildrenBd_bore_outdata[55])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[55] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[56] && dta_s1_boreChildrenBd_bore_outdata[56])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[56] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[57] && dta_s1_boreChildrenBd_bore_outdata[57])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[57] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[58] && dta_s1_boreChildrenBd_bore_outdata[58])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[58] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[59] && dta_s1_boreChildrenBd_bore_outdata[59])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[59] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[60] && dta_s1_boreChildrenBd_bore_outdata[60])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[60] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[61] && dta_s1_boreChildrenBd_bore_outdata[61])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[61] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[62] && dta_s1_boreChildrenBd_bore_outdata[62])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[62] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[63] && dta_s1_boreChildrenBd_bore_outdata[63])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[63] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[64] && dta_s1_boreChildrenBd_bore_outdata[64])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[64] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[65] && dta_s1_boreChildrenBd_bore_outdata[65])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[65] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[66] && dta_s1_boreChildrenBd_bore_outdata[66])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[66] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[67] && dta_s1_boreChildrenBd_bore_outdata[67])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[67] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[68] && dta_s1_boreChildrenBd_bore_outdata[68])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[68] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[69] && dta_s1_boreChildrenBd_bore_outdata[69])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[69] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[70] && dta_s1_boreChildrenBd_bore_outdata[70])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[70] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[71] && dta_s1_boreChildrenBd_bore_outdata[71])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[71] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[72] && dta_s1_boreChildrenBd_bore_outdata[72])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[72] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[73] && dta_s1_boreChildrenBd_bore_outdata[73])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[73] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[74] && dta_s1_boreChildrenBd_bore_outdata[74])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[74] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[75] && dta_s1_boreChildrenBd_bore_outdata[75])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[75] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[76] && dta_s1_boreChildrenBd_bore_outdata[76])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[76] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[77] && dta_s1_boreChildrenBd_bore_outdata[77])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[77] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[78] && dta_s1_boreChildrenBd_bore_outdata[78])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[78] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[79] && dta_s1_boreChildrenBd_bore_outdata[79])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[79] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[80] && dta_s1_boreChildrenBd_bore_outdata[80])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[80] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[81] && dta_s1_boreChildrenBd_bore_outdata[81])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[81] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[82] && dta_s1_boreChildrenBd_bore_outdata[82])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[82] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[83] && dta_s1_boreChildrenBd_bore_outdata[83])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[83] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[84] && dta_s1_boreChildrenBd_bore_outdata[84])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[84] 未见过 0 和 1"); end
    if (!(dta_s0_boreChildrenBd_bore_outdata[85] && dta_s1_boreChildrenBd_bore_outdata[85])) begin cov_fail++; $display("[COV] DuplicatedTagArray.boreChildrenBd_bore_outdata[85] 未见过 0 和 1"); end
    $display("[ARM] DuplicatedTagArray armed_at=%0d", dta_armed_at);
    if (dta_armed_at < 0) begin cov_fail++; $display("[ARM] DuplicatedTagArray 从未 arm"); end
    $display("[COV] DuplicatedTagArray.write = %0d", dta_cov_write);
    if (dta_cov_write < 200) begin cov_fail++; $display("[COV] DuplicatedTagArray.write < 200"); end
    $display("[COV] DuplicatedTagArray.read3_blocked = %0d", dta_cov_read3_blocked);
    if (dta_cov_read3_blocked < 200) begin cov_fail++; $display("[COV] DuplicatedTagArray.read3_blocked < 200"); end
    $display("[COV] DuplicatedTagArray.mbist_req = %0d", dta_cov_mbist_req);
    if (dta_cov_mbist_req < 200) begin cov_fail++; $display("[COV] DuplicatedTagArray.mbist_req < 200"); end
    $display("[COV] DuplicatedTagArray.ecc_nonzero = %0d", dta_cov_ecc_nonzero);
    if (dta_cov_ecc_nonzero < 200) begin cov_fail++; $display("[COV] DuplicatedTagArray.ecc_nonzero < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
