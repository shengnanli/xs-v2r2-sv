// 自动生成：verif/ut/SplittedSRAMBitmap/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// SplittedSRAM（bitmap cache 阵列）双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= SplittedSRAM =================
  int unsigned s_mode = 0;
  logic s_reset;
  logic s_io_r_req_valid;
  logic [4:0] s_io_r_req_bits_setIdx;
  wire  [24:0] s_g_io_r_resp_data_0_tag, s_i_io_r_resp_data_0_tag;
  logic [24:0] s_s0_io_r_resp_data_0_tag = '0, s_s1_io_r_resp_data_0_tag = '0;
  wire  [63:0] s_g_io_r_resp_data_0_data, s_i_io_r_resp_data_0_data;
  logic [63:0] s_s0_io_r_resp_data_0_data = '0, s_s1_io_r_resp_data_0_data = '0;
  wire  [24:0] s_g_io_r_resp_data_1_tag, s_i_io_r_resp_data_1_tag;
  logic [24:0] s_s0_io_r_resp_data_1_tag = '0, s_s1_io_r_resp_data_1_tag = '0;
  wire  [63:0] s_g_io_r_resp_data_1_data, s_i_io_r_resp_data_1_data;
  logic [63:0] s_s0_io_r_resp_data_1_data = '0, s_s1_io_r_resp_data_1_data = '0;
  wire  [24:0] s_g_io_r_resp_data_2_tag, s_i_io_r_resp_data_2_tag;
  logic [24:0] s_s0_io_r_resp_data_2_tag = '0, s_s1_io_r_resp_data_2_tag = '0;
  wire  [63:0] s_g_io_r_resp_data_2_data, s_i_io_r_resp_data_2_data;
  logic [63:0] s_s0_io_r_resp_data_2_data = '0, s_s1_io_r_resp_data_2_data = '0;
  wire  [24:0] s_g_io_r_resp_data_3_tag, s_i_io_r_resp_data_3_tag;
  logic [24:0] s_s0_io_r_resp_data_3_tag = '0, s_s1_io_r_resp_data_3_tag = '0;
  wire  [63:0] s_g_io_r_resp_data_3_data, s_i_io_r_resp_data_3_data;
  logic [63:0] s_s0_io_r_resp_data_3_data = '0, s_s1_io_r_resp_data_3_data = '0;
  logic s_io_w_req_valid;
  logic [4:0] s_io_w_req_bits_setIdx;
  logic [24:0] s_io_w_req_bits_data_0_tag;
  logic [63:0] s_io_w_req_bits_data_0_data;
  logic [24:0] s_io_w_req_bits_data_1_tag;
  logic [63:0] s_io_w_req_bits_data_1_data;
  logic [24:0] s_io_w_req_bits_data_2_tag;
  logic [63:0] s_io_w_req_bits_data_2_data;
  logic [24:0] s_io_w_req_bits_data_3_tag;
  logic [63:0] s_io_w_req_bits_data_3_data;
  logic [3:0] s_io_w_req_bits_waymask;
  logic [5:0] s_boreChildrenBd_bore_addr;
  logic [5:0] s_boreChildrenBd_bore_addr_rd;
  logic [89:0] s_boreChildrenBd_bore_wdata;
  logic [1:0] s_boreChildrenBd_bore_wmask;
  logic s_boreChildrenBd_bore_re;
  logic s_boreChildrenBd_bore_we;
  wire  [89:0] s_g_boreChildrenBd_bore_rdata, s_i_boreChildrenBd_bore_rdata;
  logic [89:0] s_s0_boreChildrenBd_bore_rdata = '0, s_s1_boreChildrenBd_bore_rdata = '0;
  logic s_boreChildrenBd_bore_ack;
  logic s_boreChildrenBd_bore_selectedOH;
  logic [5:0] s_boreChildrenBd_bore_array;
  logic [5:0] s_boreChildrenBd_bore_1_addr;
  logic [5:0] s_boreChildrenBd_bore_1_addr_rd;
  logic [89:0] s_boreChildrenBd_bore_1_wdata;
  logic [1:0] s_boreChildrenBd_bore_1_wmask;
  logic s_boreChildrenBd_bore_1_re;
  logic s_boreChildrenBd_bore_1_we;
  wire  [89:0] s_g_boreChildrenBd_bore_1_rdata, s_i_boreChildrenBd_bore_1_rdata;
  logic [89:0] s_s0_boreChildrenBd_bore_1_rdata = '0, s_s1_boreChildrenBd_bore_1_rdata = '0;
  logic s_boreChildrenBd_bore_1_ack;
  logic s_boreChildrenBd_bore_1_selectedOH;
  logic [5:0] s_boreChildrenBd_bore_1_array;
  logic [5:0] s_boreChildrenBd_bore_2_addr;
  logic [5:0] s_boreChildrenBd_bore_2_addr_rd;
  logic [89:0] s_boreChildrenBd_bore_2_wdata;
  logic [1:0] s_boreChildrenBd_bore_2_wmask;
  logic s_boreChildrenBd_bore_2_re;
  logic s_boreChildrenBd_bore_2_we;
  wire  [89:0] s_g_boreChildrenBd_bore_2_rdata, s_i_boreChildrenBd_bore_2_rdata;
  logic [89:0] s_s0_boreChildrenBd_bore_2_rdata = '0, s_s1_boreChildrenBd_bore_2_rdata = '0;
  logic s_boreChildrenBd_bore_2_ack;
  logic s_boreChildrenBd_bore_2_selectedOH;
  logic [5:0] s_boreChildrenBd_bore_2_array;
  logic [5:0] s_boreChildrenBd_bore_3_addr;
  logic [5:0] s_boreChildrenBd_bore_3_addr_rd;
  logic [89:0] s_boreChildrenBd_bore_3_wdata;
  logic [1:0] s_boreChildrenBd_bore_3_wmask;
  logic s_boreChildrenBd_bore_3_re;
  logic s_boreChildrenBd_bore_3_we;
  wire  [89:0] s_g_boreChildrenBd_bore_3_rdata, s_i_boreChildrenBd_bore_3_rdata;
  logic [89:0] s_s0_boreChildrenBd_bore_3_rdata = '0, s_s1_boreChildrenBd_bore_3_rdata = '0;
  logic s_boreChildrenBd_bore_3_ack;
  logic s_boreChildrenBd_bore_3_selectedOH;
  logic [5:0] s_boreChildrenBd_bore_3_array;
  logic s_sigFromSrams_bore_ram_hold;
  logic s_sigFromSrams_bore_ram_bypass;
  logic s_sigFromSrams_bore_ram_bp_clken;
  logic s_sigFromSrams_bore_ram_aux_clk;
  logic s_sigFromSrams_bore_ram_aux_ckbp;
  logic s_sigFromSrams_bore_ram_mcp_hold;
  logic s_sigFromSrams_bore_cgen;
  logic s_sigFromSrams_bore_1_ram_hold;
  logic s_sigFromSrams_bore_1_ram_bypass;
  logic s_sigFromSrams_bore_1_ram_bp_clken;
  logic s_sigFromSrams_bore_1_ram_aux_clk;
  logic s_sigFromSrams_bore_1_ram_aux_ckbp;
  logic s_sigFromSrams_bore_1_ram_mcp_hold;
  logic s_sigFromSrams_bore_1_cgen;
  logic s_sigFromSrams_bore_2_ram_hold;
  logic s_sigFromSrams_bore_2_ram_bypass;
  logic s_sigFromSrams_bore_2_ram_bp_clken;
  logic s_sigFromSrams_bore_2_ram_aux_clk;
  logic s_sigFromSrams_bore_2_ram_aux_ckbp;
  logic s_sigFromSrams_bore_2_ram_mcp_hold;
  logic s_sigFromSrams_bore_2_cgen;
  logic s_sigFromSrams_bore_3_ram_hold;
  logic s_sigFromSrams_bore_3_ram_bypass;
  logic s_sigFromSrams_bore_3_ram_bp_clken;
  logic s_sigFromSrams_bore_3_ram_aux_clk;
  logic s_sigFromSrams_bore_3_ram_aux_ckbp;
  logic s_sigFromSrams_bore_3_ram_mcp_hold;
  logic s_sigFromSrams_bore_3_cgen;
  int s_cov_read = 0;
  int s_cov_write = 0;
  int s_cov_rw_same_set = 0;
  int s_cov_wmask_cross = 0;
  int s_cov_dft_active = 0;
  logic [0:0] s_armed = '0;
  int s_armed_at = -1;
  SplittedSRAM s_u_gold (
    .clock(clk),
    .reset(s_reset),
    .io_r_req_valid(s_io_r_req_valid),
    .io_r_req_bits_setIdx(s_io_r_req_bits_setIdx),
    .io_r_resp_data_0_tag(s_g_io_r_resp_data_0_tag),
    .io_r_resp_data_0_data(s_g_io_r_resp_data_0_data),
    .io_r_resp_data_1_tag(s_g_io_r_resp_data_1_tag),
    .io_r_resp_data_1_data(s_g_io_r_resp_data_1_data),
    .io_r_resp_data_2_tag(s_g_io_r_resp_data_2_tag),
    .io_r_resp_data_2_data(s_g_io_r_resp_data_2_data),
    .io_r_resp_data_3_tag(s_g_io_r_resp_data_3_tag),
    .io_r_resp_data_3_data(s_g_io_r_resp_data_3_data),
    .io_w_req_valid(s_io_w_req_valid),
    .io_w_req_bits_setIdx(s_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0_tag(s_io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_0_data(s_io_w_req_bits_data_0_data),
    .io_w_req_bits_data_1_tag(s_io_w_req_bits_data_1_tag),
    .io_w_req_bits_data_1_data(s_io_w_req_bits_data_1_data),
    .io_w_req_bits_data_2_tag(s_io_w_req_bits_data_2_tag),
    .io_w_req_bits_data_2_data(s_io_w_req_bits_data_2_data),
    .io_w_req_bits_data_3_tag(s_io_w_req_bits_data_3_tag),
    .io_w_req_bits_data_3_data(s_io_w_req_bits_data_3_data),
    .io_w_req_bits_waymask(s_io_w_req_bits_waymask),
    .boreChildrenBd_bore_addr(s_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(s_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(s_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(s_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(s_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(s_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(s_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(s_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(s_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(s_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(s_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(s_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(s_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(s_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(s_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(s_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(s_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(s_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(s_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(s_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(s_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(s_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(s_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(s_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(s_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(s_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(s_g_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(s_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(s_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(s_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(s_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(s_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(s_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(s_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(s_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(s_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(s_g_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(s_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(s_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(s_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(s_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(s_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(s_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(s_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(s_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(s_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(s_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(s_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(s_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(s_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(s_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(s_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(s_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(s_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(s_sigFromSrams_bore_3_cgen)
  );
  SplittedSRAM_xs s_u_impl (
    .clock(clk),
    .reset(s_reset),
    .io_r_req_valid(s_io_r_req_valid),
    .io_r_req_bits_setIdx(s_io_r_req_bits_setIdx),
    .io_r_resp_data_0_tag(s_i_io_r_resp_data_0_tag),
    .io_r_resp_data_0_data(s_i_io_r_resp_data_0_data),
    .io_r_resp_data_1_tag(s_i_io_r_resp_data_1_tag),
    .io_r_resp_data_1_data(s_i_io_r_resp_data_1_data),
    .io_r_resp_data_2_tag(s_i_io_r_resp_data_2_tag),
    .io_r_resp_data_2_data(s_i_io_r_resp_data_2_data),
    .io_r_resp_data_3_tag(s_i_io_r_resp_data_3_tag),
    .io_r_resp_data_3_data(s_i_io_r_resp_data_3_data),
    .io_w_req_valid(s_io_w_req_valid),
    .io_w_req_bits_setIdx(s_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0_tag(s_io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_0_data(s_io_w_req_bits_data_0_data),
    .io_w_req_bits_data_1_tag(s_io_w_req_bits_data_1_tag),
    .io_w_req_bits_data_1_data(s_io_w_req_bits_data_1_data),
    .io_w_req_bits_data_2_tag(s_io_w_req_bits_data_2_tag),
    .io_w_req_bits_data_2_data(s_io_w_req_bits_data_2_data),
    .io_w_req_bits_data_3_tag(s_io_w_req_bits_data_3_tag),
    .io_w_req_bits_data_3_data(s_io_w_req_bits_data_3_data),
    .io_w_req_bits_waymask(s_io_w_req_bits_waymask),
    .boreChildrenBd_bore_addr(s_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(s_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(s_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(s_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(s_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(s_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(s_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(s_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(s_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(s_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(s_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(s_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(s_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(s_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(s_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(s_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(s_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(s_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(s_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(s_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(s_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(s_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(s_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(s_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(s_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(s_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(s_i_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(s_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(s_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(s_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(s_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(s_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(s_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(s_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(s_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(s_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(s_i_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(s_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(s_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(s_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(s_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(s_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(s_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(s_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(s_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(s_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(s_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(s_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(s_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(s_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(s_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(s_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(s_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(s_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(s_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(s_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(s_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(s_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(s_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(s_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(s_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(s_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(s_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(s_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(s_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(s_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(s_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(s_sigFromSrams_bore_3_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) s_mode = $urandom_range(0, 15);
      s_io_r_req_valid = 1'($urandom);
      s_io_r_req_bits_setIdx = 5'($urandom);
      s_io_w_req_valid = 1'($urandom);
      s_io_w_req_bits_setIdx = 5'($urandom);
      s_io_w_req_bits_data_0_tag = 25'($urandom);
      s_io_w_req_bits_data_0_data = 64'({$urandom, $urandom});
      s_io_w_req_bits_data_1_tag = 25'($urandom);
      s_io_w_req_bits_data_1_data = 64'({$urandom, $urandom});
      s_io_w_req_bits_data_2_tag = 25'($urandom);
      s_io_w_req_bits_data_2_data = 64'({$urandom, $urandom});
      s_io_w_req_bits_data_3_tag = 25'($urandom);
      s_io_w_req_bits_data_3_data = 64'({$urandom, $urandom});
      s_io_w_req_bits_waymask = 4'($urandom);
      s_boreChildrenBd_bore_addr = 6'($urandom);
      s_boreChildrenBd_bore_addr_rd = 6'($urandom);
      s_boreChildrenBd_bore_wdata = 90'({$urandom, $urandom, $urandom});
      s_boreChildrenBd_bore_wmask = 2'($urandom);
      s_boreChildrenBd_bore_re = 1'($urandom);
      s_boreChildrenBd_bore_we = 1'($urandom);
      s_boreChildrenBd_bore_ack = 1'($urandom);
      s_boreChildrenBd_bore_selectedOH = 1'($urandom);
      s_boreChildrenBd_bore_array = 6'($urandom);
      s_boreChildrenBd_bore_1_addr = 6'($urandom);
      s_boreChildrenBd_bore_1_addr_rd = 6'($urandom);
      s_boreChildrenBd_bore_1_wdata = 90'({$urandom, $urandom, $urandom});
      s_boreChildrenBd_bore_1_wmask = 2'($urandom);
      s_boreChildrenBd_bore_1_re = 1'($urandom);
      s_boreChildrenBd_bore_1_we = 1'($urandom);
      s_boreChildrenBd_bore_1_ack = 1'($urandom);
      s_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      s_boreChildrenBd_bore_1_array = 6'($urandom);
      s_boreChildrenBd_bore_2_addr = 6'($urandom);
      s_boreChildrenBd_bore_2_addr_rd = 6'($urandom);
      s_boreChildrenBd_bore_2_wdata = 90'({$urandom, $urandom, $urandom});
      s_boreChildrenBd_bore_2_wmask = 2'($urandom);
      s_boreChildrenBd_bore_2_re = 1'($urandom);
      s_boreChildrenBd_bore_2_we = 1'($urandom);
      s_boreChildrenBd_bore_2_ack = 1'($urandom);
      s_boreChildrenBd_bore_2_selectedOH = 1'($urandom);
      s_boreChildrenBd_bore_2_array = 6'($urandom);
      s_boreChildrenBd_bore_3_addr = 6'($urandom);
      s_boreChildrenBd_bore_3_addr_rd = 6'($urandom);
      s_boreChildrenBd_bore_3_wdata = 90'({$urandom, $urandom, $urandom});
      s_boreChildrenBd_bore_3_wmask = 2'($urandom);
      s_boreChildrenBd_bore_3_re = 1'($urandom);
      s_boreChildrenBd_bore_3_we = 1'($urandom);
      s_boreChildrenBd_bore_3_ack = 1'($urandom);
      s_boreChildrenBd_bore_3_selectedOH = 1'($urandom);
      s_boreChildrenBd_bore_3_array = 6'($urandom);
      s_sigFromSrams_bore_ram_hold = 1'($urandom);
      s_sigFromSrams_bore_ram_bypass = 1'($urandom);
      s_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      s_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      s_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      s_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      s_sigFromSrams_bore_cgen = 1'($urandom);
      s_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      s_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      s_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      s_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      s_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      s_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      s_sigFromSrams_bore_1_cgen = 1'($urandom);
      s_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      s_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      s_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      s_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      s_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      s_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      s_sigFromSrams_bore_2_cgen = 1'($urandom);
      s_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      s_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      s_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      s_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      s_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      s_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      s_sigFromSrams_bore_3_cgen = 1'($urandom);
      s_reset = (cyc < RESET_CYC);
      begin : stim_s
        if (cyc < 72) begin   // 上电填表：每拍写一组、4 路全写
          s_io_w_req_valid = 1'b1;
          s_io_w_req_bits_setIdx = 5'(cyc);
          s_io_w_req_bits_waymask = 4'hF;
          s_io_r_req_valid = 1'b0;
        end
        if (cyc < 72 || s_mode != 0) begin
          s_boreChildrenBd_bore_wmask = '0;
          s_boreChildrenBd_bore_re = '0;
          s_boreChildrenBd_bore_we = '0;
          s_boreChildrenBd_bore_ack = '0;
          s_boreChildrenBd_bore_selectedOH = '0;
          s_boreChildrenBd_bore_array = '0;
          s_boreChildrenBd_bore_1_wmask = '0;
          s_boreChildrenBd_bore_1_re = '0;
          s_boreChildrenBd_bore_1_we = '0;
          s_boreChildrenBd_bore_1_ack = '0;
          s_boreChildrenBd_bore_1_selectedOH = '0;
          s_boreChildrenBd_bore_1_array = '0;
          s_boreChildrenBd_bore_2_wmask = '0;
          s_boreChildrenBd_bore_2_re = '0;
          s_boreChildrenBd_bore_2_we = '0;
          s_boreChildrenBd_bore_2_ack = '0;
          s_boreChildrenBd_bore_2_selectedOH = '0;
          s_boreChildrenBd_bore_2_array = '0;
          s_boreChildrenBd_bore_3_wmask = '0;
          s_boreChildrenBd_bore_3_re = '0;
          s_boreChildrenBd_bore_3_we = '0;
          s_boreChildrenBd_bore_3_ack = '0;
          s_boreChildrenBd_bore_3_selectedOH = '0;
          s_boreChildrenBd_bore_3_array = '0;
          s_sigFromSrams_bore_ram_hold = '0;
          s_sigFromSrams_bore_ram_bypass = '0;
          s_sigFromSrams_bore_ram_bp_clken = '0;
          s_sigFromSrams_bore_ram_aux_clk = '0;
          s_sigFromSrams_bore_ram_aux_ckbp = '0;
          s_sigFromSrams_bore_ram_mcp_hold = '0;
          s_sigFromSrams_bore_cgen = '0;
          s_sigFromSrams_bore_1_ram_hold = '0;
          s_sigFromSrams_bore_1_ram_bypass = '0;
          s_sigFromSrams_bore_1_ram_bp_clken = '0;
          s_sigFromSrams_bore_1_ram_aux_clk = '0;
          s_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          s_sigFromSrams_bore_1_ram_mcp_hold = '0;
          s_sigFromSrams_bore_1_cgen = '0;
          s_sigFromSrams_bore_2_ram_hold = '0;
          s_sigFromSrams_bore_2_ram_bypass = '0;
          s_sigFromSrams_bore_2_ram_bp_clken = '0;
          s_sigFromSrams_bore_2_ram_aux_clk = '0;
          s_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          s_sigFromSrams_bore_2_ram_mcp_hold = '0;
          s_sigFromSrams_bore_2_cgen = '0;
          s_sigFromSrams_bore_3_ram_hold = '0;
          s_sigFromSrams_bore_3_ram_bypass = '0;
          s_sigFromSrams_bore_3_ram_bp_clken = '0;
          s_sigFromSrams_bore_3_ram_aux_clk = '0;
          s_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          s_sigFromSrams_bore_3_ram_mcp_hold = '0;
          s_sigFromSrams_bore_3_cgen = '0;
        end
      end
      #4;
      s_armed = 1'b1;
      if (cyc >= RESET_CYC + 72 && (&s_armed)) begin
        checks++;
        if (s_g_io_r_resp_data_0_tag !== s_i_io_r_resp_data_0_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_0_tag g=%h i=%h", cyc, s_g_io_r_resp_data_0_tag, s_i_io_r_resp_data_0_tag);
        end
        s_s1_io_r_resp_data_0_tag |= s_g_io_r_resp_data_0_tag;
        s_s0_io_r_resp_data_0_tag |= ~s_g_io_r_resp_data_0_tag;
        checks++;
        if (s_g_io_r_resp_data_0_data !== s_i_io_r_resp_data_0_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_0_data g=%h i=%h", cyc, s_g_io_r_resp_data_0_data, s_i_io_r_resp_data_0_data);
        end
        s_s1_io_r_resp_data_0_data |= s_g_io_r_resp_data_0_data;
        s_s0_io_r_resp_data_0_data |= ~s_g_io_r_resp_data_0_data;
        checks++;
        if (s_g_io_r_resp_data_1_tag !== s_i_io_r_resp_data_1_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_1_tag g=%h i=%h", cyc, s_g_io_r_resp_data_1_tag, s_i_io_r_resp_data_1_tag);
        end
        s_s1_io_r_resp_data_1_tag |= s_g_io_r_resp_data_1_tag;
        s_s0_io_r_resp_data_1_tag |= ~s_g_io_r_resp_data_1_tag;
        checks++;
        if (s_g_io_r_resp_data_1_data !== s_i_io_r_resp_data_1_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_1_data g=%h i=%h", cyc, s_g_io_r_resp_data_1_data, s_i_io_r_resp_data_1_data);
        end
        s_s1_io_r_resp_data_1_data |= s_g_io_r_resp_data_1_data;
        s_s0_io_r_resp_data_1_data |= ~s_g_io_r_resp_data_1_data;
        checks++;
        if (s_g_io_r_resp_data_2_tag !== s_i_io_r_resp_data_2_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_2_tag g=%h i=%h", cyc, s_g_io_r_resp_data_2_tag, s_i_io_r_resp_data_2_tag);
        end
        s_s1_io_r_resp_data_2_tag |= s_g_io_r_resp_data_2_tag;
        s_s0_io_r_resp_data_2_tag |= ~s_g_io_r_resp_data_2_tag;
        checks++;
        if (s_g_io_r_resp_data_2_data !== s_i_io_r_resp_data_2_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_2_data g=%h i=%h", cyc, s_g_io_r_resp_data_2_data, s_i_io_r_resp_data_2_data);
        end
        s_s1_io_r_resp_data_2_data |= s_g_io_r_resp_data_2_data;
        s_s0_io_r_resp_data_2_data |= ~s_g_io_r_resp_data_2_data;
        checks++;
        if (s_g_io_r_resp_data_3_tag !== s_i_io_r_resp_data_3_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_3_tag g=%h i=%h", cyc, s_g_io_r_resp_data_3_tag, s_i_io_r_resp_data_3_tag);
        end
        s_s1_io_r_resp_data_3_tag |= s_g_io_r_resp_data_3_tag;
        s_s0_io_r_resp_data_3_tag |= ~s_g_io_r_resp_data_3_tag;
        checks++;
        if (s_g_io_r_resp_data_3_data !== s_i_io_r_resp_data_3_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.io_r_resp_data_3_data g=%h i=%h", cyc, s_g_io_r_resp_data_3_data, s_i_io_r_resp_data_3_data);
        end
        s_s1_io_r_resp_data_3_data |= s_g_io_r_resp_data_3_data;
        s_s0_io_r_resp_data_3_data |= ~s_g_io_r_resp_data_3_data;
        checks++;
        if (s_g_boreChildrenBd_bore_rdata !== s_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.boreChildrenBd_bore_rdata g=%h i=%h", cyc, s_g_boreChildrenBd_bore_rdata, s_i_boreChildrenBd_bore_rdata);
        end
        s_s1_boreChildrenBd_bore_rdata |= s_g_boreChildrenBd_bore_rdata;
        s_s0_boreChildrenBd_bore_rdata |= ~s_g_boreChildrenBd_bore_rdata;
        checks++;
        if (s_g_boreChildrenBd_bore_1_rdata !== s_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, s_g_boreChildrenBd_bore_1_rdata, s_i_boreChildrenBd_bore_1_rdata);
        end
        s_s1_boreChildrenBd_bore_1_rdata |= s_g_boreChildrenBd_bore_1_rdata;
        s_s0_boreChildrenBd_bore_1_rdata |= ~s_g_boreChildrenBd_bore_1_rdata;
        checks++;
        if (s_g_boreChildrenBd_bore_2_rdata !== s_i_boreChildrenBd_bore_2_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.boreChildrenBd_bore_2_rdata g=%h i=%h", cyc, s_g_boreChildrenBd_bore_2_rdata, s_i_boreChildrenBd_bore_2_rdata);
        end
        s_s1_boreChildrenBd_bore_2_rdata |= s_g_boreChildrenBd_bore_2_rdata;
        s_s0_boreChildrenBd_bore_2_rdata |= ~s_g_boreChildrenBd_bore_2_rdata;
        checks++;
        if (s_g_boreChildrenBd_bore_3_rdata !== s_i_boreChildrenBd_bore_3_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SplittedSRAM.boreChildrenBd_bore_3_rdata g=%h i=%h", cyc, s_g_boreChildrenBd_bore_3_rdata, s_i_boreChildrenBd_bore_3_rdata);
        end
        s_s1_boreChildrenBd_bore_3_rdata |= s_g_boreChildrenBd_bore_3_rdata;
        s_s0_boreChildrenBd_bore_3_rdata |= ~s_g_boreChildrenBd_bore_3_rdata;
        if (s_io_r_req_valid) s_cov_read++;
        if (s_io_w_req_valid) s_cov_write++;
        if (s_io_r_req_valid && s_io_w_req_valid && s_io_r_req_bits_setIdx == s_io_w_req_bits_setIdx) s_cov_rw_same_set++;
        if (s_io_w_req_valid && s_io_w_req_bits_waymask == 4'b0110) s_cov_wmask_cross++;
        if (s_mode == 0) s_cov_dft_active++;
      end
      if (s_armed_at < 0 && (&s_armed)) s_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(s_s0_io_r_resp_data_0_tag[0] && s_s1_io_r_resp_data_0_tag[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[1] && s_s1_io_r_resp_data_0_tag[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[2] && s_s1_io_r_resp_data_0_tag[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[3] && s_s1_io_r_resp_data_0_tag[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[4] && s_s1_io_r_resp_data_0_tag[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[5] && s_s1_io_r_resp_data_0_tag[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[6] && s_s1_io_r_resp_data_0_tag[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[7] && s_s1_io_r_resp_data_0_tag[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[8] && s_s1_io_r_resp_data_0_tag[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[9] && s_s1_io_r_resp_data_0_tag[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[10] && s_s1_io_r_resp_data_0_tag[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[11] && s_s1_io_r_resp_data_0_tag[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[12] && s_s1_io_r_resp_data_0_tag[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[13] && s_s1_io_r_resp_data_0_tag[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[14] && s_s1_io_r_resp_data_0_tag[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[15] && s_s1_io_r_resp_data_0_tag[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[16] && s_s1_io_r_resp_data_0_tag[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[17] && s_s1_io_r_resp_data_0_tag[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[18] && s_s1_io_r_resp_data_0_tag[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[19] && s_s1_io_r_resp_data_0_tag[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[20] && s_s1_io_r_resp_data_0_tag[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[21] && s_s1_io_r_resp_data_0_tag[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[22] && s_s1_io_r_resp_data_0_tag[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[23] && s_s1_io_r_resp_data_0_tag[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_tag[24] && s_s1_io_r_resp_data_0_tag[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_tag[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[0] && s_s1_io_r_resp_data_0_data[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[1] && s_s1_io_r_resp_data_0_data[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[2] && s_s1_io_r_resp_data_0_data[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[3] && s_s1_io_r_resp_data_0_data[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[4] && s_s1_io_r_resp_data_0_data[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[5] && s_s1_io_r_resp_data_0_data[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[6] && s_s1_io_r_resp_data_0_data[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[7] && s_s1_io_r_resp_data_0_data[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[8] && s_s1_io_r_resp_data_0_data[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[9] && s_s1_io_r_resp_data_0_data[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[10] && s_s1_io_r_resp_data_0_data[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[11] && s_s1_io_r_resp_data_0_data[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[12] && s_s1_io_r_resp_data_0_data[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[13] && s_s1_io_r_resp_data_0_data[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[14] && s_s1_io_r_resp_data_0_data[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[15] && s_s1_io_r_resp_data_0_data[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[16] && s_s1_io_r_resp_data_0_data[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[17] && s_s1_io_r_resp_data_0_data[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[18] && s_s1_io_r_resp_data_0_data[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[19] && s_s1_io_r_resp_data_0_data[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[20] && s_s1_io_r_resp_data_0_data[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[21] && s_s1_io_r_resp_data_0_data[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[22] && s_s1_io_r_resp_data_0_data[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[23] && s_s1_io_r_resp_data_0_data[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[24] && s_s1_io_r_resp_data_0_data[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[25] && s_s1_io_r_resp_data_0_data[25])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[25] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[26] && s_s1_io_r_resp_data_0_data[26])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[26] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[27] && s_s1_io_r_resp_data_0_data[27])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[27] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[28] && s_s1_io_r_resp_data_0_data[28])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[28] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[29] && s_s1_io_r_resp_data_0_data[29])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[29] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[30] && s_s1_io_r_resp_data_0_data[30])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[30] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[31] && s_s1_io_r_resp_data_0_data[31])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[31] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[32] && s_s1_io_r_resp_data_0_data[32])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[32] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[33] && s_s1_io_r_resp_data_0_data[33])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[33] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[34] && s_s1_io_r_resp_data_0_data[34])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[34] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[35] && s_s1_io_r_resp_data_0_data[35])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[35] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[36] && s_s1_io_r_resp_data_0_data[36])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[36] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[37] && s_s1_io_r_resp_data_0_data[37])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[37] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[38] && s_s1_io_r_resp_data_0_data[38])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[38] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[39] && s_s1_io_r_resp_data_0_data[39])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[39] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[40] && s_s1_io_r_resp_data_0_data[40])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[40] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[41] && s_s1_io_r_resp_data_0_data[41])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[41] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[42] && s_s1_io_r_resp_data_0_data[42])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[42] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[43] && s_s1_io_r_resp_data_0_data[43])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[43] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[44] && s_s1_io_r_resp_data_0_data[44])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[44] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[45] && s_s1_io_r_resp_data_0_data[45])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[45] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[46] && s_s1_io_r_resp_data_0_data[46])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[46] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[47] && s_s1_io_r_resp_data_0_data[47])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[47] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[48] && s_s1_io_r_resp_data_0_data[48])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[48] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[49] && s_s1_io_r_resp_data_0_data[49])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[49] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[50] && s_s1_io_r_resp_data_0_data[50])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[50] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[51] && s_s1_io_r_resp_data_0_data[51])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[51] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[52] && s_s1_io_r_resp_data_0_data[52])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[52] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[53] && s_s1_io_r_resp_data_0_data[53])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[53] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[54] && s_s1_io_r_resp_data_0_data[54])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[54] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[55] && s_s1_io_r_resp_data_0_data[55])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[55] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[56] && s_s1_io_r_resp_data_0_data[56])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[56] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[57] && s_s1_io_r_resp_data_0_data[57])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[57] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[58] && s_s1_io_r_resp_data_0_data[58])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[58] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[59] && s_s1_io_r_resp_data_0_data[59])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[59] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[60] && s_s1_io_r_resp_data_0_data[60])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[60] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[61] && s_s1_io_r_resp_data_0_data[61])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[61] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[62] && s_s1_io_r_resp_data_0_data[62])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[62] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_0_data[63] && s_s1_io_r_resp_data_0_data[63])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_0_data[63] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[0] && s_s1_io_r_resp_data_1_tag[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[1] && s_s1_io_r_resp_data_1_tag[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[2] && s_s1_io_r_resp_data_1_tag[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[3] && s_s1_io_r_resp_data_1_tag[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[4] && s_s1_io_r_resp_data_1_tag[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[5] && s_s1_io_r_resp_data_1_tag[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[6] && s_s1_io_r_resp_data_1_tag[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[7] && s_s1_io_r_resp_data_1_tag[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[8] && s_s1_io_r_resp_data_1_tag[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[9] && s_s1_io_r_resp_data_1_tag[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[10] && s_s1_io_r_resp_data_1_tag[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[11] && s_s1_io_r_resp_data_1_tag[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[12] && s_s1_io_r_resp_data_1_tag[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[13] && s_s1_io_r_resp_data_1_tag[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[14] && s_s1_io_r_resp_data_1_tag[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[15] && s_s1_io_r_resp_data_1_tag[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[16] && s_s1_io_r_resp_data_1_tag[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[17] && s_s1_io_r_resp_data_1_tag[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[18] && s_s1_io_r_resp_data_1_tag[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[19] && s_s1_io_r_resp_data_1_tag[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[20] && s_s1_io_r_resp_data_1_tag[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[21] && s_s1_io_r_resp_data_1_tag[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[22] && s_s1_io_r_resp_data_1_tag[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[23] && s_s1_io_r_resp_data_1_tag[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_tag[24] && s_s1_io_r_resp_data_1_tag[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_tag[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[0] && s_s1_io_r_resp_data_1_data[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[1] && s_s1_io_r_resp_data_1_data[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[2] && s_s1_io_r_resp_data_1_data[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[3] && s_s1_io_r_resp_data_1_data[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[4] && s_s1_io_r_resp_data_1_data[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[5] && s_s1_io_r_resp_data_1_data[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[6] && s_s1_io_r_resp_data_1_data[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[7] && s_s1_io_r_resp_data_1_data[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[8] && s_s1_io_r_resp_data_1_data[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[9] && s_s1_io_r_resp_data_1_data[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[10] && s_s1_io_r_resp_data_1_data[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[11] && s_s1_io_r_resp_data_1_data[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[12] && s_s1_io_r_resp_data_1_data[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[13] && s_s1_io_r_resp_data_1_data[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[14] && s_s1_io_r_resp_data_1_data[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[15] && s_s1_io_r_resp_data_1_data[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[16] && s_s1_io_r_resp_data_1_data[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[17] && s_s1_io_r_resp_data_1_data[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[18] && s_s1_io_r_resp_data_1_data[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[19] && s_s1_io_r_resp_data_1_data[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[20] && s_s1_io_r_resp_data_1_data[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[21] && s_s1_io_r_resp_data_1_data[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[22] && s_s1_io_r_resp_data_1_data[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[23] && s_s1_io_r_resp_data_1_data[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[24] && s_s1_io_r_resp_data_1_data[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[25] && s_s1_io_r_resp_data_1_data[25])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[25] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[26] && s_s1_io_r_resp_data_1_data[26])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[26] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[27] && s_s1_io_r_resp_data_1_data[27])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[27] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[28] && s_s1_io_r_resp_data_1_data[28])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[28] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[29] && s_s1_io_r_resp_data_1_data[29])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[29] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[30] && s_s1_io_r_resp_data_1_data[30])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[30] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[31] && s_s1_io_r_resp_data_1_data[31])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[31] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[32] && s_s1_io_r_resp_data_1_data[32])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[32] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[33] && s_s1_io_r_resp_data_1_data[33])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[33] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[34] && s_s1_io_r_resp_data_1_data[34])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[34] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[35] && s_s1_io_r_resp_data_1_data[35])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[35] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[36] && s_s1_io_r_resp_data_1_data[36])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[36] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[37] && s_s1_io_r_resp_data_1_data[37])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[37] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[38] && s_s1_io_r_resp_data_1_data[38])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[38] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[39] && s_s1_io_r_resp_data_1_data[39])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[39] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[40] && s_s1_io_r_resp_data_1_data[40])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[40] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[41] && s_s1_io_r_resp_data_1_data[41])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[41] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[42] && s_s1_io_r_resp_data_1_data[42])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[42] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[43] && s_s1_io_r_resp_data_1_data[43])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[43] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[44] && s_s1_io_r_resp_data_1_data[44])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[44] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[45] && s_s1_io_r_resp_data_1_data[45])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[45] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[46] && s_s1_io_r_resp_data_1_data[46])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[46] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[47] && s_s1_io_r_resp_data_1_data[47])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[47] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[48] && s_s1_io_r_resp_data_1_data[48])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[48] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[49] && s_s1_io_r_resp_data_1_data[49])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[49] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[50] && s_s1_io_r_resp_data_1_data[50])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[50] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[51] && s_s1_io_r_resp_data_1_data[51])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[51] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[52] && s_s1_io_r_resp_data_1_data[52])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[52] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[53] && s_s1_io_r_resp_data_1_data[53])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[53] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[54] && s_s1_io_r_resp_data_1_data[54])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[54] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[55] && s_s1_io_r_resp_data_1_data[55])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[55] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[56] && s_s1_io_r_resp_data_1_data[56])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[56] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[57] && s_s1_io_r_resp_data_1_data[57])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[57] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[58] && s_s1_io_r_resp_data_1_data[58])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[58] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[59] && s_s1_io_r_resp_data_1_data[59])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[59] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[60] && s_s1_io_r_resp_data_1_data[60])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[60] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[61] && s_s1_io_r_resp_data_1_data[61])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[61] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[62] && s_s1_io_r_resp_data_1_data[62])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[62] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_1_data[63] && s_s1_io_r_resp_data_1_data[63])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_1_data[63] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[0] && s_s1_io_r_resp_data_2_tag[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[1] && s_s1_io_r_resp_data_2_tag[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[2] && s_s1_io_r_resp_data_2_tag[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[3] && s_s1_io_r_resp_data_2_tag[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[4] && s_s1_io_r_resp_data_2_tag[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[5] && s_s1_io_r_resp_data_2_tag[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[6] && s_s1_io_r_resp_data_2_tag[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[7] && s_s1_io_r_resp_data_2_tag[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[8] && s_s1_io_r_resp_data_2_tag[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[9] && s_s1_io_r_resp_data_2_tag[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[10] && s_s1_io_r_resp_data_2_tag[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[11] && s_s1_io_r_resp_data_2_tag[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[12] && s_s1_io_r_resp_data_2_tag[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[13] && s_s1_io_r_resp_data_2_tag[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[14] && s_s1_io_r_resp_data_2_tag[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[15] && s_s1_io_r_resp_data_2_tag[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[16] && s_s1_io_r_resp_data_2_tag[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[17] && s_s1_io_r_resp_data_2_tag[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[18] && s_s1_io_r_resp_data_2_tag[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[19] && s_s1_io_r_resp_data_2_tag[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[20] && s_s1_io_r_resp_data_2_tag[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[21] && s_s1_io_r_resp_data_2_tag[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[22] && s_s1_io_r_resp_data_2_tag[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[23] && s_s1_io_r_resp_data_2_tag[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_tag[24] && s_s1_io_r_resp_data_2_tag[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_tag[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[0] && s_s1_io_r_resp_data_2_data[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[1] && s_s1_io_r_resp_data_2_data[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[2] && s_s1_io_r_resp_data_2_data[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[3] && s_s1_io_r_resp_data_2_data[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[4] && s_s1_io_r_resp_data_2_data[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[5] && s_s1_io_r_resp_data_2_data[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[6] && s_s1_io_r_resp_data_2_data[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[7] && s_s1_io_r_resp_data_2_data[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[8] && s_s1_io_r_resp_data_2_data[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[9] && s_s1_io_r_resp_data_2_data[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[10] && s_s1_io_r_resp_data_2_data[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[11] && s_s1_io_r_resp_data_2_data[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[12] && s_s1_io_r_resp_data_2_data[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[13] && s_s1_io_r_resp_data_2_data[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[14] && s_s1_io_r_resp_data_2_data[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[15] && s_s1_io_r_resp_data_2_data[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[16] && s_s1_io_r_resp_data_2_data[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[17] && s_s1_io_r_resp_data_2_data[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[18] && s_s1_io_r_resp_data_2_data[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[19] && s_s1_io_r_resp_data_2_data[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[20] && s_s1_io_r_resp_data_2_data[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[21] && s_s1_io_r_resp_data_2_data[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[22] && s_s1_io_r_resp_data_2_data[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[23] && s_s1_io_r_resp_data_2_data[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[24] && s_s1_io_r_resp_data_2_data[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[25] && s_s1_io_r_resp_data_2_data[25])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[25] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[26] && s_s1_io_r_resp_data_2_data[26])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[26] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[27] && s_s1_io_r_resp_data_2_data[27])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[27] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[28] && s_s1_io_r_resp_data_2_data[28])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[28] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[29] && s_s1_io_r_resp_data_2_data[29])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[29] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[30] && s_s1_io_r_resp_data_2_data[30])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[30] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[31] && s_s1_io_r_resp_data_2_data[31])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[31] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[32] && s_s1_io_r_resp_data_2_data[32])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[32] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[33] && s_s1_io_r_resp_data_2_data[33])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[33] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[34] && s_s1_io_r_resp_data_2_data[34])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[34] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[35] && s_s1_io_r_resp_data_2_data[35])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[35] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[36] && s_s1_io_r_resp_data_2_data[36])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[36] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[37] && s_s1_io_r_resp_data_2_data[37])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[37] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[38] && s_s1_io_r_resp_data_2_data[38])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[38] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[39] && s_s1_io_r_resp_data_2_data[39])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[39] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[40] && s_s1_io_r_resp_data_2_data[40])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[40] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[41] && s_s1_io_r_resp_data_2_data[41])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[41] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[42] && s_s1_io_r_resp_data_2_data[42])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[42] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[43] && s_s1_io_r_resp_data_2_data[43])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[43] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[44] && s_s1_io_r_resp_data_2_data[44])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[44] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[45] && s_s1_io_r_resp_data_2_data[45])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[45] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[46] && s_s1_io_r_resp_data_2_data[46])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[46] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[47] && s_s1_io_r_resp_data_2_data[47])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[47] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[48] && s_s1_io_r_resp_data_2_data[48])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[48] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[49] && s_s1_io_r_resp_data_2_data[49])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[49] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[50] && s_s1_io_r_resp_data_2_data[50])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[50] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[51] && s_s1_io_r_resp_data_2_data[51])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[51] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[52] && s_s1_io_r_resp_data_2_data[52])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[52] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[53] && s_s1_io_r_resp_data_2_data[53])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[53] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[54] && s_s1_io_r_resp_data_2_data[54])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[54] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[55] && s_s1_io_r_resp_data_2_data[55])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[55] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[56] && s_s1_io_r_resp_data_2_data[56])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[56] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[57] && s_s1_io_r_resp_data_2_data[57])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[57] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[58] && s_s1_io_r_resp_data_2_data[58])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[58] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[59] && s_s1_io_r_resp_data_2_data[59])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[59] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[60] && s_s1_io_r_resp_data_2_data[60])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[60] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[61] && s_s1_io_r_resp_data_2_data[61])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[61] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[62] && s_s1_io_r_resp_data_2_data[62])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[62] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_2_data[63] && s_s1_io_r_resp_data_2_data[63])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_2_data[63] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[0] && s_s1_io_r_resp_data_3_tag[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[1] && s_s1_io_r_resp_data_3_tag[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[2] && s_s1_io_r_resp_data_3_tag[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[3] && s_s1_io_r_resp_data_3_tag[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[4] && s_s1_io_r_resp_data_3_tag[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[5] && s_s1_io_r_resp_data_3_tag[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[6] && s_s1_io_r_resp_data_3_tag[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[7] && s_s1_io_r_resp_data_3_tag[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[8] && s_s1_io_r_resp_data_3_tag[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[9] && s_s1_io_r_resp_data_3_tag[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[10] && s_s1_io_r_resp_data_3_tag[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[11] && s_s1_io_r_resp_data_3_tag[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[12] && s_s1_io_r_resp_data_3_tag[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[13] && s_s1_io_r_resp_data_3_tag[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[14] && s_s1_io_r_resp_data_3_tag[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[15] && s_s1_io_r_resp_data_3_tag[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[16] && s_s1_io_r_resp_data_3_tag[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[17] && s_s1_io_r_resp_data_3_tag[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[18] && s_s1_io_r_resp_data_3_tag[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[19] && s_s1_io_r_resp_data_3_tag[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[20] && s_s1_io_r_resp_data_3_tag[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[21] && s_s1_io_r_resp_data_3_tag[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[22] && s_s1_io_r_resp_data_3_tag[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[23] && s_s1_io_r_resp_data_3_tag[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_tag[24] && s_s1_io_r_resp_data_3_tag[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_tag[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[0] && s_s1_io_r_resp_data_3_data[0])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[0] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[1] && s_s1_io_r_resp_data_3_data[1])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[1] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[2] && s_s1_io_r_resp_data_3_data[2])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[2] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[3] && s_s1_io_r_resp_data_3_data[3])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[3] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[4] && s_s1_io_r_resp_data_3_data[4])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[4] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[5] && s_s1_io_r_resp_data_3_data[5])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[5] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[6] && s_s1_io_r_resp_data_3_data[6])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[6] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[7] && s_s1_io_r_resp_data_3_data[7])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[7] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[8] && s_s1_io_r_resp_data_3_data[8])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[8] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[9] && s_s1_io_r_resp_data_3_data[9])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[9] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[10] && s_s1_io_r_resp_data_3_data[10])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[10] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[11] && s_s1_io_r_resp_data_3_data[11])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[11] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[12] && s_s1_io_r_resp_data_3_data[12])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[12] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[13] && s_s1_io_r_resp_data_3_data[13])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[13] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[14] && s_s1_io_r_resp_data_3_data[14])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[14] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[15] && s_s1_io_r_resp_data_3_data[15])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[15] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[16] && s_s1_io_r_resp_data_3_data[16])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[16] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[17] && s_s1_io_r_resp_data_3_data[17])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[17] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[18] && s_s1_io_r_resp_data_3_data[18])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[18] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[19] && s_s1_io_r_resp_data_3_data[19])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[19] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[20] && s_s1_io_r_resp_data_3_data[20])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[20] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[21] && s_s1_io_r_resp_data_3_data[21])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[21] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[22] && s_s1_io_r_resp_data_3_data[22])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[22] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[23] && s_s1_io_r_resp_data_3_data[23])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[23] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[24] && s_s1_io_r_resp_data_3_data[24])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[24] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[25] && s_s1_io_r_resp_data_3_data[25])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[25] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[26] && s_s1_io_r_resp_data_3_data[26])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[26] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[27] && s_s1_io_r_resp_data_3_data[27])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[27] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[28] && s_s1_io_r_resp_data_3_data[28])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[28] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[29] && s_s1_io_r_resp_data_3_data[29])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[29] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[30] && s_s1_io_r_resp_data_3_data[30])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[30] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[31] && s_s1_io_r_resp_data_3_data[31])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[31] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[32] && s_s1_io_r_resp_data_3_data[32])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[32] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[33] && s_s1_io_r_resp_data_3_data[33])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[33] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[34] && s_s1_io_r_resp_data_3_data[34])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[34] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[35] && s_s1_io_r_resp_data_3_data[35])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[35] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[36] && s_s1_io_r_resp_data_3_data[36])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[36] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[37] && s_s1_io_r_resp_data_3_data[37])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[37] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[38] && s_s1_io_r_resp_data_3_data[38])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[38] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[39] && s_s1_io_r_resp_data_3_data[39])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[39] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[40] && s_s1_io_r_resp_data_3_data[40])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[40] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[41] && s_s1_io_r_resp_data_3_data[41])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[41] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[42] && s_s1_io_r_resp_data_3_data[42])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[42] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[43] && s_s1_io_r_resp_data_3_data[43])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[43] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[44] && s_s1_io_r_resp_data_3_data[44])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[44] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[45] && s_s1_io_r_resp_data_3_data[45])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[45] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[46] && s_s1_io_r_resp_data_3_data[46])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[46] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[47] && s_s1_io_r_resp_data_3_data[47])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[47] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[48] && s_s1_io_r_resp_data_3_data[48])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[48] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[49] && s_s1_io_r_resp_data_3_data[49])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[49] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[50] && s_s1_io_r_resp_data_3_data[50])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[50] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[51] && s_s1_io_r_resp_data_3_data[51])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[51] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[52] && s_s1_io_r_resp_data_3_data[52])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[52] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[53] && s_s1_io_r_resp_data_3_data[53])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[53] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[54] && s_s1_io_r_resp_data_3_data[54])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[54] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[55] && s_s1_io_r_resp_data_3_data[55])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[55] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[56] && s_s1_io_r_resp_data_3_data[56])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[56] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[57] && s_s1_io_r_resp_data_3_data[57])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[57] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[58] && s_s1_io_r_resp_data_3_data[58])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[58] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[59] && s_s1_io_r_resp_data_3_data[59])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[59] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[60] && s_s1_io_r_resp_data_3_data[60])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[60] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[61] && s_s1_io_r_resp_data_3_data[61])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[61] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[62] && s_s1_io_r_resp_data_3_data[62])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[62] 未见过 0 和 1"); end
    if (!(s_s0_io_r_resp_data_3_data[63] && s_s1_io_r_resp_data_3_data[63])) begin cov_fail++; $display("[COV] SplittedSRAM.io_r_resp_data_3_data[63] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[0] && s_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[1] && s_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[2] && s_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[3] && s_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[4] && s_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[5] && s_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[6] && s_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[7] && s_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[8] && s_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[9] && s_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[10] && s_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[11] && s_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[12] && s_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[13] && s_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[14] && s_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[15] && s_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[16] && s_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[17] && s_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[18] && s_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[19] && s_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[20] && s_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[21] && s_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[22] && s_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[23] && s_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[24] && s_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[25] && s_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[26] && s_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[27] && s_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[28] && s_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[29] && s_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[30] && s_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[31] && s_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[32] && s_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[33] && s_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[34] && s_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[35] && s_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[36] && s_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[37] && s_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[38] && s_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[39] && s_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[40] && s_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[41] && s_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[42] && s_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[43] && s_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[44] && s_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[45] && s_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[46] && s_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[47] && s_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[48] && s_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[49] && s_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[50] && s_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[51] && s_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[52] && s_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[53] && s_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[54] && s_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[55] && s_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[56] && s_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[57] && s_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[58] && s_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[59] && s_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[60] && s_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[61] && s_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[62] && s_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[63] && s_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[64] && s_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[65] && s_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[66] && s_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[67] && s_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[68] && s_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[69] && s_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[70] && s_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[71] && s_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[72] && s_s1_boreChildrenBd_bore_rdata[72])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[72] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[73] && s_s1_boreChildrenBd_bore_rdata[73])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[73] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[74] && s_s1_boreChildrenBd_bore_rdata[74])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[74] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[75] && s_s1_boreChildrenBd_bore_rdata[75])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[75] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[76] && s_s1_boreChildrenBd_bore_rdata[76])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[76] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[77] && s_s1_boreChildrenBd_bore_rdata[77])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[77] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[78] && s_s1_boreChildrenBd_bore_rdata[78])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[78] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[79] && s_s1_boreChildrenBd_bore_rdata[79])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[79] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[80] && s_s1_boreChildrenBd_bore_rdata[80])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[80] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[81] && s_s1_boreChildrenBd_bore_rdata[81])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[81] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[82] && s_s1_boreChildrenBd_bore_rdata[82])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[82] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[83] && s_s1_boreChildrenBd_bore_rdata[83])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[83] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[84] && s_s1_boreChildrenBd_bore_rdata[84])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[84] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[85] && s_s1_boreChildrenBd_bore_rdata[85])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[85] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[86] && s_s1_boreChildrenBd_bore_rdata[86])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[86] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[87] && s_s1_boreChildrenBd_bore_rdata[87])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[87] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[88] && s_s1_boreChildrenBd_bore_rdata[88])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[88] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_rdata[89] && s_s1_boreChildrenBd_bore_rdata[89])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_rdata[89] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[0] && s_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[1] && s_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[2] && s_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[3] && s_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[4] && s_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[5] && s_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[6] && s_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[7] && s_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[8] && s_s1_boreChildrenBd_bore_1_rdata[8])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[8] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[9] && s_s1_boreChildrenBd_bore_1_rdata[9])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[9] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[10] && s_s1_boreChildrenBd_bore_1_rdata[10])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[10] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[11] && s_s1_boreChildrenBd_bore_1_rdata[11])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[11] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[12] && s_s1_boreChildrenBd_bore_1_rdata[12])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[12] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[13] && s_s1_boreChildrenBd_bore_1_rdata[13])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[13] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[14] && s_s1_boreChildrenBd_bore_1_rdata[14])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[14] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[15] && s_s1_boreChildrenBd_bore_1_rdata[15])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[15] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[16] && s_s1_boreChildrenBd_bore_1_rdata[16])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[16] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[17] && s_s1_boreChildrenBd_bore_1_rdata[17])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[17] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[18] && s_s1_boreChildrenBd_bore_1_rdata[18])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[18] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[19] && s_s1_boreChildrenBd_bore_1_rdata[19])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[19] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[20] && s_s1_boreChildrenBd_bore_1_rdata[20])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[20] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[21] && s_s1_boreChildrenBd_bore_1_rdata[21])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[21] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[22] && s_s1_boreChildrenBd_bore_1_rdata[22])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[22] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[23] && s_s1_boreChildrenBd_bore_1_rdata[23])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[23] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[24] && s_s1_boreChildrenBd_bore_1_rdata[24])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[24] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[25] && s_s1_boreChildrenBd_bore_1_rdata[25])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[25] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[26] && s_s1_boreChildrenBd_bore_1_rdata[26])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[26] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[27] && s_s1_boreChildrenBd_bore_1_rdata[27])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[27] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[28] && s_s1_boreChildrenBd_bore_1_rdata[28])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[28] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[29] && s_s1_boreChildrenBd_bore_1_rdata[29])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[29] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[30] && s_s1_boreChildrenBd_bore_1_rdata[30])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[30] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[31] && s_s1_boreChildrenBd_bore_1_rdata[31])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[31] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[32] && s_s1_boreChildrenBd_bore_1_rdata[32])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[32] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[33] && s_s1_boreChildrenBd_bore_1_rdata[33])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[33] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[34] && s_s1_boreChildrenBd_bore_1_rdata[34])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[34] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[35] && s_s1_boreChildrenBd_bore_1_rdata[35])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[35] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[36] && s_s1_boreChildrenBd_bore_1_rdata[36])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[36] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[37] && s_s1_boreChildrenBd_bore_1_rdata[37])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[37] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[38] && s_s1_boreChildrenBd_bore_1_rdata[38])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[38] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[39] && s_s1_boreChildrenBd_bore_1_rdata[39])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[39] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[40] && s_s1_boreChildrenBd_bore_1_rdata[40])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[40] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[41] && s_s1_boreChildrenBd_bore_1_rdata[41])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[41] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[42] && s_s1_boreChildrenBd_bore_1_rdata[42])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[42] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[43] && s_s1_boreChildrenBd_bore_1_rdata[43])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[43] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[44] && s_s1_boreChildrenBd_bore_1_rdata[44])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[44] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[45] && s_s1_boreChildrenBd_bore_1_rdata[45])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[45] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[46] && s_s1_boreChildrenBd_bore_1_rdata[46])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[46] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[47] && s_s1_boreChildrenBd_bore_1_rdata[47])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[47] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[48] && s_s1_boreChildrenBd_bore_1_rdata[48])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[48] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[49] && s_s1_boreChildrenBd_bore_1_rdata[49])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[49] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[50] && s_s1_boreChildrenBd_bore_1_rdata[50])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[50] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[51] && s_s1_boreChildrenBd_bore_1_rdata[51])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[51] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[52] && s_s1_boreChildrenBd_bore_1_rdata[52])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[52] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[53] && s_s1_boreChildrenBd_bore_1_rdata[53])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[53] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[54] && s_s1_boreChildrenBd_bore_1_rdata[54])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[54] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[55] && s_s1_boreChildrenBd_bore_1_rdata[55])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[55] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[56] && s_s1_boreChildrenBd_bore_1_rdata[56])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[56] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[57] && s_s1_boreChildrenBd_bore_1_rdata[57])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[57] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[58] && s_s1_boreChildrenBd_bore_1_rdata[58])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[58] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[59] && s_s1_boreChildrenBd_bore_1_rdata[59])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[59] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[60] && s_s1_boreChildrenBd_bore_1_rdata[60])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[60] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[61] && s_s1_boreChildrenBd_bore_1_rdata[61])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[61] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[62] && s_s1_boreChildrenBd_bore_1_rdata[62])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[62] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[63] && s_s1_boreChildrenBd_bore_1_rdata[63])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[63] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[64] && s_s1_boreChildrenBd_bore_1_rdata[64])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[64] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[65] && s_s1_boreChildrenBd_bore_1_rdata[65])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[65] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[66] && s_s1_boreChildrenBd_bore_1_rdata[66])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[66] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[67] && s_s1_boreChildrenBd_bore_1_rdata[67])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[67] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[68] && s_s1_boreChildrenBd_bore_1_rdata[68])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[68] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[69] && s_s1_boreChildrenBd_bore_1_rdata[69])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[69] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[70] && s_s1_boreChildrenBd_bore_1_rdata[70])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[70] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[71] && s_s1_boreChildrenBd_bore_1_rdata[71])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[71] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[72] && s_s1_boreChildrenBd_bore_1_rdata[72])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[72] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[73] && s_s1_boreChildrenBd_bore_1_rdata[73])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[73] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[74] && s_s1_boreChildrenBd_bore_1_rdata[74])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[74] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[75] && s_s1_boreChildrenBd_bore_1_rdata[75])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[75] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[76] && s_s1_boreChildrenBd_bore_1_rdata[76])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[76] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[77] && s_s1_boreChildrenBd_bore_1_rdata[77])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[77] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[78] && s_s1_boreChildrenBd_bore_1_rdata[78])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[78] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[79] && s_s1_boreChildrenBd_bore_1_rdata[79])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[79] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[80] && s_s1_boreChildrenBd_bore_1_rdata[80])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[80] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[81] && s_s1_boreChildrenBd_bore_1_rdata[81])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[81] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[82] && s_s1_boreChildrenBd_bore_1_rdata[82])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[82] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[83] && s_s1_boreChildrenBd_bore_1_rdata[83])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[83] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[84] && s_s1_boreChildrenBd_bore_1_rdata[84])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[84] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[85] && s_s1_boreChildrenBd_bore_1_rdata[85])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[85] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[86] && s_s1_boreChildrenBd_bore_1_rdata[86])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[86] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[87] && s_s1_boreChildrenBd_bore_1_rdata[87])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[87] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[88] && s_s1_boreChildrenBd_bore_1_rdata[88])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[88] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_1_rdata[89] && s_s1_boreChildrenBd_bore_1_rdata[89])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_1_rdata[89] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[0] && s_s1_boreChildrenBd_bore_2_rdata[0])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[0] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[1] && s_s1_boreChildrenBd_bore_2_rdata[1])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[1] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[2] && s_s1_boreChildrenBd_bore_2_rdata[2])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[2] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[3] && s_s1_boreChildrenBd_bore_2_rdata[3])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[3] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[4] && s_s1_boreChildrenBd_bore_2_rdata[4])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[4] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[5] && s_s1_boreChildrenBd_bore_2_rdata[5])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[5] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[6] && s_s1_boreChildrenBd_bore_2_rdata[6])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[6] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[7] && s_s1_boreChildrenBd_bore_2_rdata[7])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[7] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[8] && s_s1_boreChildrenBd_bore_2_rdata[8])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[8] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[9] && s_s1_boreChildrenBd_bore_2_rdata[9])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[9] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[10] && s_s1_boreChildrenBd_bore_2_rdata[10])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[10] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[11] && s_s1_boreChildrenBd_bore_2_rdata[11])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[11] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[12] && s_s1_boreChildrenBd_bore_2_rdata[12])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[12] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[13] && s_s1_boreChildrenBd_bore_2_rdata[13])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[13] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[14] && s_s1_boreChildrenBd_bore_2_rdata[14])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[14] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[15] && s_s1_boreChildrenBd_bore_2_rdata[15])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[15] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[16] && s_s1_boreChildrenBd_bore_2_rdata[16])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[16] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[17] && s_s1_boreChildrenBd_bore_2_rdata[17])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[17] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[18] && s_s1_boreChildrenBd_bore_2_rdata[18])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[18] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[19] && s_s1_boreChildrenBd_bore_2_rdata[19])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[19] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[20] && s_s1_boreChildrenBd_bore_2_rdata[20])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[20] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[21] && s_s1_boreChildrenBd_bore_2_rdata[21])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[21] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[22] && s_s1_boreChildrenBd_bore_2_rdata[22])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[22] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[23] && s_s1_boreChildrenBd_bore_2_rdata[23])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[23] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[24] && s_s1_boreChildrenBd_bore_2_rdata[24])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[24] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[25] && s_s1_boreChildrenBd_bore_2_rdata[25])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[25] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[26] && s_s1_boreChildrenBd_bore_2_rdata[26])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[26] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[27] && s_s1_boreChildrenBd_bore_2_rdata[27])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[27] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[28] && s_s1_boreChildrenBd_bore_2_rdata[28])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[28] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[29] && s_s1_boreChildrenBd_bore_2_rdata[29])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[29] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[30] && s_s1_boreChildrenBd_bore_2_rdata[30])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[30] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[31] && s_s1_boreChildrenBd_bore_2_rdata[31])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[31] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[32] && s_s1_boreChildrenBd_bore_2_rdata[32])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[32] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[33] && s_s1_boreChildrenBd_bore_2_rdata[33])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[33] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[34] && s_s1_boreChildrenBd_bore_2_rdata[34])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[34] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[35] && s_s1_boreChildrenBd_bore_2_rdata[35])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[35] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[36] && s_s1_boreChildrenBd_bore_2_rdata[36])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[36] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[37] && s_s1_boreChildrenBd_bore_2_rdata[37])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[37] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[38] && s_s1_boreChildrenBd_bore_2_rdata[38])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[38] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[39] && s_s1_boreChildrenBd_bore_2_rdata[39])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[39] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[40] && s_s1_boreChildrenBd_bore_2_rdata[40])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[40] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[41] && s_s1_boreChildrenBd_bore_2_rdata[41])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[41] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[42] && s_s1_boreChildrenBd_bore_2_rdata[42])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[42] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[43] && s_s1_boreChildrenBd_bore_2_rdata[43])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[43] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[44] && s_s1_boreChildrenBd_bore_2_rdata[44])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[44] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[45] && s_s1_boreChildrenBd_bore_2_rdata[45])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[45] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[46] && s_s1_boreChildrenBd_bore_2_rdata[46])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[46] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[47] && s_s1_boreChildrenBd_bore_2_rdata[47])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[47] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[48] && s_s1_boreChildrenBd_bore_2_rdata[48])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[48] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[49] && s_s1_boreChildrenBd_bore_2_rdata[49])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[49] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[50] && s_s1_boreChildrenBd_bore_2_rdata[50])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[50] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[51] && s_s1_boreChildrenBd_bore_2_rdata[51])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[51] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[52] && s_s1_boreChildrenBd_bore_2_rdata[52])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[52] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[53] && s_s1_boreChildrenBd_bore_2_rdata[53])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[53] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[54] && s_s1_boreChildrenBd_bore_2_rdata[54])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[54] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[55] && s_s1_boreChildrenBd_bore_2_rdata[55])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[55] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[56] && s_s1_boreChildrenBd_bore_2_rdata[56])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[56] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[57] && s_s1_boreChildrenBd_bore_2_rdata[57])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[57] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[58] && s_s1_boreChildrenBd_bore_2_rdata[58])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[58] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[59] && s_s1_boreChildrenBd_bore_2_rdata[59])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[59] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[60] && s_s1_boreChildrenBd_bore_2_rdata[60])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[60] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[61] && s_s1_boreChildrenBd_bore_2_rdata[61])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[61] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[62] && s_s1_boreChildrenBd_bore_2_rdata[62])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[62] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[63] && s_s1_boreChildrenBd_bore_2_rdata[63])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[63] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[64] && s_s1_boreChildrenBd_bore_2_rdata[64])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[64] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[65] && s_s1_boreChildrenBd_bore_2_rdata[65])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[65] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[66] && s_s1_boreChildrenBd_bore_2_rdata[66])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[66] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[67] && s_s1_boreChildrenBd_bore_2_rdata[67])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[67] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[68] && s_s1_boreChildrenBd_bore_2_rdata[68])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[68] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[69] && s_s1_boreChildrenBd_bore_2_rdata[69])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[69] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[70] && s_s1_boreChildrenBd_bore_2_rdata[70])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[70] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[71] && s_s1_boreChildrenBd_bore_2_rdata[71])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[71] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[72] && s_s1_boreChildrenBd_bore_2_rdata[72])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[72] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[73] && s_s1_boreChildrenBd_bore_2_rdata[73])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[73] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[74] && s_s1_boreChildrenBd_bore_2_rdata[74])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[74] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[75] && s_s1_boreChildrenBd_bore_2_rdata[75])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[75] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[76] && s_s1_boreChildrenBd_bore_2_rdata[76])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[76] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[77] && s_s1_boreChildrenBd_bore_2_rdata[77])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[77] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[78] && s_s1_boreChildrenBd_bore_2_rdata[78])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[78] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[79] && s_s1_boreChildrenBd_bore_2_rdata[79])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[79] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[80] && s_s1_boreChildrenBd_bore_2_rdata[80])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[80] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[81] && s_s1_boreChildrenBd_bore_2_rdata[81])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[81] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[82] && s_s1_boreChildrenBd_bore_2_rdata[82])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[82] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[83] && s_s1_boreChildrenBd_bore_2_rdata[83])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[83] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[84] && s_s1_boreChildrenBd_bore_2_rdata[84])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[84] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[85] && s_s1_boreChildrenBd_bore_2_rdata[85])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[85] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[86] && s_s1_boreChildrenBd_bore_2_rdata[86])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[86] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[87] && s_s1_boreChildrenBd_bore_2_rdata[87])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[87] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[88] && s_s1_boreChildrenBd_bore_2_rdata[88])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[88] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_2_rdata[89] && s_s1_boreChildrenBd_bore_2_rdata[89])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_2_rdata[89] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[0] && s_s1_boreChildrenBd_bore_3_rdata[0])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[0] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[1] && s_s1_boreChildrenBd_bore_3_rdata[1])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[1] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[2] && s_s1_boreChildrenBd_bore_3_rdata[2])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[2] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[3] && s_s1_boreChildrenBd_bore_3_rdata[3])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[3] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[4] && s_s1_boreChildrenBd_bore_3_rdata[4])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[4] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[5] && s_s1_boreChildrenBd_bore_3_rdata[5])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[5] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[6] && s_s1_boreChildrenBd_bore_3_rdata[6])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[6] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[7] && s_s1_boreChildrenBd_bore_3_rdata[7])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[7] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[8] && s_s1_boreChildrenBd_bore_3_rdata[8])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[8] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[9] && s_s1_boreChildrenBd_bore_3_rdata[9])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[9] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[10] && s_s1_boreChildrenBd_bore_3_rdata[10])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[10] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[11] && s_s1_boreChildrenBd_bore_3_rdata[11])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[11] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[12] && s_s1_boreChildrenBd_bore_3_rdata[12])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[12] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[13] && s_s1_boreChildrenBd_bore_3_rdata[13])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[13] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[14] && s_s1_boreChildrenBd_bore_3_rdata[14])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[14] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[15] && s_s1_boreChildrenBd_bore_3_rdata[15])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[15] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[16] && s_s1_boreChildrenBd_bore_3_rdata[16])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[16] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[17] && s_s1_boreChildrenBd_bore_3_rdata[17])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[17] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[18] && s_s1_boreChildrenBd_bore_3_rdata[18])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[18] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[19] && s_s1_boreChildrenBd_bore_3_rdata[19])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[19] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[20] && s_s1_boreChildrenBd_bore_3_rdata[20])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[20] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[21] && s_s1_boreChildrenBd_bore_3_rdata[21])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[21] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[22] && s_s1_boreChildrenBd_bore_3_rdata[22])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[22] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[23] && s_s1_boreChildrenBd_bore_3_rdata[23])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[23] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[24] && s_s1_boreChildrenBd_bore_3_rdata[24])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[24] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[25] && s_s1_boreChildrenBd_bore_3_rdata[25])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[25] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[26] && s_s1_boreChildrenBd_bore_3_rdata[26])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[26] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[27] && s_s1_boreChildrenBd_bore_3_rdata[27])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[27] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[28] && s_s1_boreChildrenBd_bore_3_rdata[28])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[28] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[29] && s_s1_boreChildrenBd_bore_3_rdata[29])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[29] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[30] && s_s1_boreChildrenBd_bore_3_rdata[30])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[30] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[31] && s_s1_boreChildrenBd_bore_3_rdata[31])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[31] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[32] && s_s1_boreChildrenBd_bore_3_rdata[32])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[32] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[33] && s_s1_boreChildrenBd_bore_3_rdata[33])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[33] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[34] && s_s1_boreChildrenBd_bore_3_rdata[34])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[34] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[35] && s_s1_boreChildrenBd_bore_3_rdata[35])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[35] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[36] && s_s1_boreChildrenBd_bore_3_rdata[36])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[36] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[37] && s_s1_boreChildrenBd_bore_3_rdata[37])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[37] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[38] && s_s1_boreChildrenBd_bore_3_rdata[38])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[38] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[39] && s_s1_boreChildrenBd_bore_3_rdata[39])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[39] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[40] && s_s1_boreChildrenBd_bore_3_rdata[40])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[40] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[41] && s_s1_boreChildrenBd_bore_3_rdata[41])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[41] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[42] && s_s1_boreChildrenBd_bore_3_rdata[42])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[42] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[43] && s_s1_boreChildrenBd_bore_3_rdata[43])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[43] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[44] && s_s1_boreChildrenBd_bore_3_rdata[44])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[44] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[45] && s_s1_boreChildrenBd_bore_3_rdata[45])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[45] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[46] && s_s1_boreChildrenBd_bore_3_rdata[46])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[46] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[47] && s_s1_boreChildrenBd_bore_3_rdata[47])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[47] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[48] && s_s1_boreChildrenBd_bore_3_rdata[48])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[48] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[49] && s_s1_boreChildrenBd_bore_3_rdata[49])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[49] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[50] && s_s1_boreChildrenBd_bore_3_rdata[50])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[50] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[51] && s_s1_boreChildrenBd_bore_3_rdata[51])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[51] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[52] && s_s1_boreChildrenBd_bore_3_rdata[52])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[52] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[53] && s_s1_boreChildrenBd_bore_3_rdata[53])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[53] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[54] && s_s1_boreChildrenBd_bore_3_rdata[54])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[54] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[55] && s_s1_boreChildrenBd_bore_3_rdata[55])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[55] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[56] && s_s1_boreChildrenBd_bore_3_rdata[56])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[56] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[57] && s_s1_boreChildrenBd_bore_3_rdata[57])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[57] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[58] && s_s1_boreChildrenBd_bore_3_rdata[58])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[58] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[59] && s_s1_boreChildrenBd_bore_3_rdata[59])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[59] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[60] && s_s1_boreChildrenBd_bore_3_rdata[60])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[60] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[61] && s_s1_boreChildrenBd_bore_3_rdata[61])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[61] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[62] && s_s1_boreChildrenBd_bore_3_rdata[62])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[62] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[63] && s_s1_boreChildrenBd_bore_3_rdata[63])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[63] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[64] && s_s1_boreChildrenBd_bore_3_rdata[64])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[64] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[65] && s_s1_boreChildrenBd_bore_3_rdata[65])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[65] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[66] && s_s1_boreChildrenBd_bore_3_rdata[66])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[66] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[67] && s_s1_boreChildrenBd_bore_3_rdata[67])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[67] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[68] && s_s1_boreChildrenBd_bore_3_rdata[68])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[68] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[69] && s_s1_boreChildrenBd_bore_3_rdata[69])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[69] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[70] && s_s1_boreChildrenBd_bore_3_rdata[70])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[70] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[71] && s_s1_boreChildrenBd_bore_3_rdata[71])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[71] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[72] && s_s1_boreChildrenBd_bore_3_rdata[72])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[72] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[73] && s_s1_boreChildrenBd_bore_3_rdata[73])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[73] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[74] && s_s1_boreChildrenBd_bore_3_rdata[74])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[74] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[75] && s_s1_boreChildrenBd_bore_3_rdata[75])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[75] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[76] && s_s1_boreChildrenBd_bore_3_rdata[76])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[76] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[77] && s_s1_boreChildrenBd_bore_3_rdata[77])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[77] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[78] && s_s1_boreChildrenBd_bore_3_rdata[78])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[78] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[79] && s_s1_boreChildrenBd_bore_3_rdata[79])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[79] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[80] && s_s1_boreChildrenBd_bore_3_rdata[80])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[80] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[81] && s_s1_boreChildrenBd_bore_3_rdata[81])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[81] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[82] && s_s1_boreChildrenBd_bore_3_rdata[82])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[82] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[83] && s_s1_boreChildrenBd_bore_3_rdata[83])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[83] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[84] && s_s1_boreChildrenBd_bore_3_rdata[84])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[84] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[85] && s_s1_boreChildrenBd_bore_3_rdata[85])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[85] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[86] && s_s1_boreChildrenBd_bore_3_rdata[86])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[86] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[87] && s_s1_boreChildrenBd_bore_3_rdata[87])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[87] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[88] && s_s1_boreChildrenBd_bore_3_rdata[88])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[88] 未见过 0 和 1"); end
    if (!(s_s0_boreChildrenBd_bore_3_rdata[89] && s_s1_boreChildrenBd_bore_3_rdata[89])) begin cov_fail++; $display("[COV] SplittedSRAM.boreChildrenBd_bore_3_rdata[89] 未见过 0 和 1"); end
    $display("[ARM] SplittedSRAM armed_at=%0d", s_armed_at);
    if (s_armed_at < 0) begin cov_fail++; $display("[ARM] SplittedSRAM 从未 arm"); end
    $display("[COV] SplittedSRAM.read = %0d", s_cov_read);
    if (s_cov_read < 50) begin cov_fail++; $display("[COV] SplittedSRAM.read < 50"); end
    $display("[COV] SplittedSRAM.write = %0d", s_cov_write);
    if (s_cov_write < 50) begin cov_fail++; $display("[COV] SplittedSRAM.write < 50"); end
    $display("[COV] SplittedSRAM.rw_same_set = %0d", s_cov_rw_same_set);
    if (s_cov_rw_same_set < 50) begin cov_fail++; $display("[COV] SplittedSRAM.rw_same_set < 50"); end
    $display("[COV] SplittedSRAM.wmask_cross = %0d", s_cov_wmask_cross);
    if (s_cov_wmask_cross < 50) begin cov_fail++; $display("[COV] SplittedSRAM.wmask_cross < 50"); end
    $display("[COV] SplittedSRAM.dft_active = %0d", s_cov_dft_active);
    if (s_cov_dft_active < 50) begin cov_fail++; $display("[COV] SplittedSRAM.dft_active < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
