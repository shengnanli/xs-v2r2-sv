// 自动生成：verif/ut/SRAMTemplateWithFixedWidth/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// SRAMTemplateWithFixedWidth 家族 4 变体双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= SRAMTemplateWithFixedWidth =================
  int unsigned f0_mode = 0;
  logic f0_reset;
  logic f0_io_r_req_valid;
  logic [7:0] f0_io_r_req_bits_setIdx;
  wire  [64:0] f0_g_io_r_resp_data_0, f0_i_io_r_resp_data_0;
  logic [64:0] f0_s0_io_r_resp_data_0 = '0, f0_s1_io_r_resp_data_0 = '0;
  logic f0_io_w_req_valid;
  logic [7:0] f0_io_w_req_bits_setIdx;
  logic [64:0] f0_io_w_req_bits_data_0;
  logic [8:0] f0_boreChildrenBd_bore_addr;
  logic [8:0] f0_boreChildrenBd_bore_addr_rd;
  logic [65:0] f0_boreChildrenBd_bore_wdata;
  logic f0_boreChildrenBd_bore_wmask;
  logic f0_boreChildrenBd_bore_re;
  logic f0_boreChildrenBd_bore_we;
  wire  [65:0] f0_g_boreChildrenBd_bore_rdata, f0_i_boreChildrenBd_bore_rdata;
  logic [65:0] f0_s0_boreChildrenBd_bore_rdata = '0, f0_s1_boreChildrenBd_bore_rdata = '0;
  logic f0_boreChildrenBd_bore_ack;
  logic f0_boreChildrenBd_bore_selectedOH;
  logic [2:0] f0_boreChildrenBd_bore_array;
  logic f0_sigFromSrams_bore_ram_hold;
  logic f0_sigFromSrams_bore_ram_bypass;
  logic f0_sigFromSrams_bore_ram_bp_clken;
  logic f0_sigFromSrams_bore_ram_aux_clk;
  logic f0_sigFromSrams_bore_ram_aux_ckbp;
  logic f0_sigFromSrams_bore_ram_mcp_hold;
  logic f0_sigFromSrams_bore_cgen;
  int f0_cov_read = 0;
  int f0_cov_write = 0;
  int f0_cov_rw_same = 0;
  int f0_cov_reset_mid = 0;
  logic [0:0] f0_armed = '0;
  int f0_armed_at = -1;
  SRAMTemplateWithFixedWidth f0_u_gold (
    .clock(clk),
    .reset(f0_reset),
    .io_r_req_valid(f0_io_r_req_valid),
    .io_r_req_bits_setIdx(f0_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f0_g_io_r_resp_data_0),
    .io_w_req_valid(f0_io_w_req_valid),
    .io_w_req_bits_setIdx(f0_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f0_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f0_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f0_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f0_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f0_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f0_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f0_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f0_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f0_sigFromSrams_bore_cgen)
  );
  SRAMTemplateWithFixedWidth_xs f0_u_impl (
    .clock(clk),
    .reset(f0_reset),
    .io_r_req_valid(f0_io_r_req_valid),
    .io_r_req_bits_setIdx(f0_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f0_i_io_r_resp_data_0),
    .io_w_req_valid(f0_io_w_req_valid),
    .io_w_req_bits_setIdx(f0_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f0_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f0_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f0_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f0_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f0_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f0_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f0_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f0_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f0_sigFromSrams_bore_cgen)
  );

  // ================= SRAMTemplateWithFixedWidth_4 =================
  int unsigned f4_mode = 0;
  logic f4_reset;
  logic f4_io_r_req_valid;
  logic [7:0] f4_io_r_req_bits_setIdx;
  wire  [64:0] f4_g_io_r_resp_data_0, f4_i_io_r_resp_data_0;
  logic [64:0] f4_s0_io_r_resp_data_0 = '0, f4_s1_io_r_resp_data_0 = '0;
  logic f4_io_w_req_valid;
  logic [7:0] f4_io_w_req_bits_setIdx;
  logic [64:0] f4_io_w_req_bits_data_0;
  logic [8:0] f4_boreChildrenBd_bore_addr;
  logic [8:0] f4_boreChildrenBd_bore_addr_rd;
  logic [65:0] f4_boreChildrenBd_bore_wdata;
  logic f4_boreChildrenBd_bore_wmask;
  logic f4_boreChildrenBd_bore_re;
  logic f4_boreChildrenBd_bore_we;
  wire  [65:0] f4_g_boreChildrenBd_bore_rdata, f4_i_boreChildrenBd_bore_rdata;
  logic [65:0] f4_s0_boreChildrenBd_bore_rdata = '0, f4_s1_boreChildrenBd_bore_rdata = '0;
  logic f4_boreChildrenBd_bore_ack;
  logic f4_boreChildrenBd_bore_selectedOH;
  logic [3:0] f4_boreChildrenBd_bore_array;
  logic f4_sigFromSrams_bore_ram_hold;
  logic f4_sigFromSrams_bore_ram_bypass;
  logic f4_sigFromSrams_bore_ram_bp_clken;
  logic f4_sigFromSrams_bore_ram_aux_clk;
  logic f4_sigFromSrams_bore_ram_aux_ckbp;
  logic f4_sigFromSrams_bore_ram_mcp_hold;
  logic f4_sigFromSrams_bore_cgen;
  int f4_cov_read = 0;
  int f4_cov_write = 0;
  int f4_cov_rw_same = 0;
  int f4_cov_reset_mid = 0;
  logic [0:0] f4_armed = '0;
  int f4_armed_at = -1;
  SRAMTemplateWithFixedWidth_4 f4_u_gold (
    .clock(clk),
    .reset(f4_reset),
    .io_r_req_valid(f4_io_r_req_valid),
    .io_r_req_bits_setIdx(f4_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f4_g_io_r_resp_data_0),
    .io_w_req_valid(f4_io_w_req_valid),
    .io_w_req_bits_setIdx(f4_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f4_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f4_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f4_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f4_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f4_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f4_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f4_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f4_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f4_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f4_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f4_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f4_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f4_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f4_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f4_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f4_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f4_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f4_sigFromSrams_bore_cgen)
  );
  SRAMTemplateWithFixedWidth_4_xs f4_u_impl (
    .clock(clk),
    .reset(f4_reset),
    .io_r_req_valid(f4_io_r_req_valid),
    .io_r_req_bits_setIdx(f4_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f4_i_io_r_resp_data_0),
    .io_w_req_valid(f4_io_w_req_valid),
    .io_w_req_bits_setIdx(f4_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f4_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f4_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f4_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f4_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f4_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f4_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f4_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f4_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f4_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f4_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f4_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f4_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f4_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f4_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f4_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f4_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f4_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f4_sigFromSrams_bore_cgen)
  );

  // ================= SRAMTemplateWithFixedWidth_12 =================
  int unsigned f12_mode = 0;
  logic f12_reset;
  logic f12_io_r_req_valid;
  logic [7:0] f12_io_r_req_bits_setIdx;
  wire  [64:0] f12_g_io_r_resp_data_0, f12_i_io_r_resp_data_0;
  logic [64:0] f12_s0_io_r_resp_data_0 = '0, f12_s1_io_r_resp_data_0 = '0;
  logic f12_io_w_req_valid;
  logic [7:0] f12_io_w_req_bits_setIdx;
  logic [64:0] f12_io_w_req_bits_data_0;
  logic [8:0] f12_boreChildrenBd_bore_addr;
  logic [8:0] f12_boreChildrenBd_bore_addr_rd;
  logic [65:0] f12_boreChildrenBd_bore_wdata;
  logic f12_boreChildrenBd_bore_wmask;
  logic f12_boreChildrenBd_bore_re;
  logic f12_boreChildrenBd_bore_we;
  wire  [65:0] f12_g_boreChildrenBd_bore_rdata, f12_i_boreChildrenBd_bore_rdata;
  logic [65:0] f12_s0_boreChildrenBd_bore_rdata = '0, f12_s1_boreChildrenBd_bore_rdata = '0;
  logic f12_boreChildrenBd_bore_ack;
  logic f12_boreChildrenBd_bore_selectedOH;
  logic [4:0] f12_boreChildrenBd_bore_array;
  logic f12_sigFromSrams_bore_ram_hold;
  logic f12_sigFromSrams_bore_ram_bypass;
  logic f12_sigFromSrams_bore_ram_bp_clken;
  logic f12_sigFromSrams_bore_ram_aux_clk;
  logic f12_sigFromSrams_bore_ram_aux_ckbp;
  logic f12_sigFromSrams_bore_ram_mcp_hold;
  logic f12_sigFromSrams_bore_cgen;
  int f12_cov_read = 0;
  int f12_cov_write = 0;
  int f12_cov_rw_same = 0;
  int f12_cov_reset_mid = 0;
  logic [0:0] f12_armed = '0;
  int f12_armed_at = -1;
  SRAMTemplateWithFixedWidth_12 f12_u_gold (
    .clock(clk),
    .reset(f12_reset),
    .io_r_req_valid(f12_io_r_req_valid),
    .io_r_req_bits_setIdx(f12_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f12_g_io_r_resp_data_0),
    .io_w_req_valid(f12_io_w_req_valid),
    .io_w_req_bits_setIdx(f12_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f12_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f12_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f12_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f12_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f12_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f12_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f12_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f12_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f12_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f12_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f12_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f12_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f12_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f12_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f12_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f12_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f12_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f12_sigFromSrams_bore_cgen)
  );
  SRAMTemplateWithFixedWidth_12_xs f12_u_impl (
    .clock(clk),
    .reset(f12_reset),
    .io_r_req_valid(f12_io_r_req_valid),
    .io_r_req_bits_setIdx(f12_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f12_i_io_r_resp_data_0),
    .io_w_req_valid(f12_io_w_req_valid),
    .io_w_req_bits_setIdx(f12_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f12_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f12_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f12_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f12_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f12_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f12_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f12_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f12_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f12_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f12_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f12_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f12_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f12_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f12_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f12_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f12_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f12_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f12_sigFromSrams_bore_cgen)
  );

  // ================= SRAMTemplateWithFixedWidth_28 =================
  int unsigned f28_mode = 0;
  logic f28_reset;
  logic f28_io_r_req_valid;
  logic [7:0] f28_io_r_req_bits_setIdx;
  wire  [64:0] f28_g_io_r_resp_data_0, f28_i_io_r_resp_data_0;
  logic [64:0] f28_s0_io_r_resp_data_0 = '0, f28_s1_io_r_resp_data_0 = '0;
  logic f28_io_w_req_valid;
  logic [7:0] f28_io_w_req_bits_setIdx;
  logic [64:0] f28_io_w_req_bits_data_0;
  logic [8:0] f28_boreChildrenBd_bore_addr;
  logic [8:0] f28_boreChildrenBd_bore_addr_rd;
  logic [65:0] f28_boreChildrenBd_bore_wdata;
  logic f28_boreChildrenBd_bore_wmask;
  logic f28_boreChildrenBd_bore_re;
  logic f28_boreChildrenBd_bore_we;
  wire  [65:0] f28_g_boreChildrenBd_bore_rdata, f28_i_boreChildrenBd_bore_rdata;
  logic [65:0] f28_s0_boreChildrenBd_bore_rdata = '0, f28_s1_boreChildrenBd_bore_rdata = '0;
  logic f28_boreChildrenBd_bore_ack;
  logic f28_boreChildrenBd_bore_selectedOH;
  logic [5:0] f28_boreChildrenBd_bore_array;
  logic f28_sigFromSrams_bore_ram_hold;
  logic f28_sigFromSrams_bore_ram_bypass;
  logic f28_sigFromSrams_bore_ram_bp_clken;
  logic f28_sigFromSrams_bore_ram_aux_clk;
  logic f28_sigFromSrams_bore_ram_aux_ckbp;
  logic f28_sigFromSrams_bore_ram_mcp_hold;
  logic f28_sigFromSrams_bore_cgen;
  int f28_cov_read = 0;
  int f28_cov_write = 0;
  int f28_cov_rw_same = 0;
  int f28_cov_reset_mid = 0;
  logic [0:0] f28_armed = '0;
  int f28_armed_at = -1;
  SRAMTemplateWithFixedWidth_28 f28_u_gold (
    .clock(clk),
    .reset(f28_reset),
    .io_r_req_valid(f28_io_r_req_valid),
    .io_r_req_bits_setIdx(f28_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f28_g_io_r_resp_data_0),
    .io_w_req_valid(f28_io_w_req_valid),
    .io_w_req_bits_setIdx(f28_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f28_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f28_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f28_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f28_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f28_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f28_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f28_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f28_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f28_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f28_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f28_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f28_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f28_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f28_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f28_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f28_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f28_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f28_sigFromSrams_bore_cgen)
  );
  SRAMTemplateWithFixedWidth_28_xs f28_u_impl (
    .clock(clk),
    .reset(f28_reset),
    .io_r_req_valid(f28_io_r_req_valid),
    .io_r_req_bits_setIdx(f28_io_r_req_bits_setIdx),
    .io_r_resp_data_0(f28_i_io_r_resp_data_0),
    .io_w_req_valid(f28_io_w_req_valid),
    .io_w_req_bits_setIdx(f28_io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(f28_io_w_req_bits_data_0),
    .boreChildrenBd_bore_addr(f28_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(f28_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(f28_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(f28_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(f28_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(f28_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(f28_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(f28_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(f28_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(f28_boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(f28_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(f28_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(f28_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(f28_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(f28_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(f28_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(f28_sigFromSrams_bore_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 2000 == 0) f0_mode = $urandom_range(0, 15);
      f0_io_r_req_valid = 1'($urandom);
      f0_io_r_req_bits_setIdx = 8'($urandom);
      f0_io_w_req_valid = 1'($urandom);
      f0_io_w_req_bits_setIdx = 8'($urandom);
      f0_io_w_req_bits_data_0 = 65'({$urandom, $urandom, $urandom});
      f0_boreChildrenBd_bore_addr = 9'($urandom);
      f0_boreChildrenBd_bore_addr_rd = 9'($urandom);
      f0_boreChildrenBd_bore_wdata = 66'({$urandom, $urandom, $urandom});
      f0_boreChildrenBd_bore_wmask = 1'($urandom);
      f0_boreChildrenBd_bore_re = 1'($urandom);
      f0_boreChildrenBd_bore_we = 1'($urandom);
      f0_boreChildrenBd_bore_ack = 1'($urandom);
      f0_boreChildrenBd_bore_selectedOH = 1'($urandom);
      f0_boreChildrenBd_bore_array = 3'($urandom);
      f0_sigFromSrams_bore_ram_hold = 1'($urandom);
      f0_sigFromSrams_bore_ram_bypass = 1'($urandom);
      f0_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      f0_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      f0_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      f0_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      f0_sigFromSrams_bore_cgen = 1'($urandom);
      f0_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_f0
        if (f0_mode < 12) begin
          f0_io_r_req_bits_setIdx = 8'($urandom_range(0, 15));
          f0_io_w_req_bits_setIdx = 8'($urandom_range(0, 15));
        end
        if (f0_mode != 0) begin
          f0_boreChildrenBd_bore_wmask = '0;
          f0_boreChildrenBd_bore_re = '0;
          f0_boreChildrenBd_bore_we = '0;
          f0_boreChildrenBd_bore_ack = '0;
          f0_boreChildrenBd_bore_selectedOH = '0;
          f0_boreChildrenBd_bore_array = '0;
          f0_sigFromSrams_bore_ram_hold = '0;
          f0_sigFromSrams_bore_ram_bypass = '0;
          f0_sigFromSrams_bore_ram_bp_clken = '0;
          f0_sigFromSrams_bore_ram_aux_clk = '0;
          f0_sigFromSrams_bore_ram_aux_ckbp = '0;
          f0_sigFromSrams_bore_ram_mcp_hold = '0;
          f0_sigFromSrams_bore_cgen = '0;
        end
      end
      if (cyc % 2000 == 0) f4_mode = $urandom_range(0, 15);
      f4_io_r_req_valid = 1'($urandom);
      f4_io_r_req_bits_setIdx = 8'($urandom);
      f4_io_w_req_valid = 1'($urandom);
      f4_io_w_req_bits_setIdx = 8'($urandom);
      f4_io_w_req_bits_data_0 = 65'({$urandom, $urandom, $urandom});
      f4_boreChildrenBd_bore_addr = 9'($urandom);
      f4_boreChildrenBd_bore_addr_rd = 9'($urandom);
      f4_boreChildrenBd_bore_wdata = 66'({$urandom, $urandom, $urandom});
      f4_boreChildrenBd_bore_wmask = 1'($urandom);
      f4_boreChildrenBd_bore_re = 1'($urandom);
      f4_boreChildrenBd_bore_we = 1'($urandom);
      f4_boreChildrenBd_bore_ack = 1'($urandom);
      f4_boreChildrenBd_bore_selectedOH = 1'($urandom);
      f4_boreChildrenBd_bore_array = 4'($urandom);
      f4_sigFromSrams_bore_ram_hold = 1'($urandom);
      f4_sigFromSrams_bore_ram_bypass = 1'($urandom);
      f4_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      f4_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      f4_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      f4_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      f4_sigFromSrams_bore_cgen = 1'($urandom);
      f4_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_f4
        if (f4_mode < 12) begin
          f4_io_r_req_bits_setIdx = 8'($urandom_range(0, 15));
          f4_io_w_req_bits_setIdx = 8'($urandom_range(0, 15));
        end
        if (f4_mode != 0) begin
          f4_boreChildrenBd_bore_wmask = '0;
          f4_boreChildrenBd_bore_re = '0;
          f4_boreChildrenBd_bore_we = '0;
          f4_boreChildrenBd_bore_ack = '0;
          f4_boreChildrenBd_bore_selectedOH = '0;
          f4_boreChildrenBd_bore_array = '0;
          f4_sigFromSrams_bore_ram_hold = '0;
          f4_sigFromSrams_bore_ram_bypass = '0;
          f4_sigFromSrams_bore_ram_bp_clken = '0;
          f4_sigFromSrams_bore_ram_aux_clk = '0;
          f4_sigFromSrams_bore_ram_aux_ckbp = '0;
          f4_sigFromSrams_bore_ram_mcp_hold = '0;
          f4_sigFromSrams_bore_cgen = '0;
        end
      end
      if (cyc % 2000 == 0) f12_mode = $urandom_range(0, 15);
      f12_io_r_req_valid = 1'($urandom);
      f12_io_r_req_bits_setIdx = 8'($urandom);
      f12_io_w_req_valid = 1'($urandom);
      f12_io_w_req_bits_setIdx = 8'($urandom);
      f12_io_w_req_bits_data_0 = 65'({$urandom, $urandom, $urandom});
      f12_boreChildrenBd_bore_addr = 9'($urandom);
      f12_boreChildrenBd_bore_addr_rd = 9'($urandom);
      f12_boreChildrenBd_bore_wdata = 66'({$urandom, $urandom, $urandom});
      f12_boreChildrenBd_bore_wmask = 1'($urandom);
      f12_boreChildrenBd_bore_re = 1'($urandom);
      f12_boreChildrenBd_bore_we = 1'($urandom);
      f12_boreChildrenBd_bore_ack = 1'($urandom);
      f12_boreChildrenBd_bore_selectedOH = 1'($urandom);
      f12_boreChildrenBd_bore_array = 5'($urandom);
      f12_sigFromSrams_bore_ram_hold = 1'($urandom);
      f12_sigFromSrams_bore_ram_bypass = 1'($urandom);
      f12_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      f12_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      f12_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      f12_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      f12_sigFromSrams_bore_cgen = 1'($urandom);
      f12_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_f12
        if (f12_mode < 12) begin
          f12_io_r_req_bits_setIdx = 8'($urandom_range(0, 15));
          f12_io_w_req_bits_setIdx = 8'($urandom_range(0, 15));
        end
        if (f12_mode != 0) begin
          f12_boreChildrenBd_bore_wmask = '0;
          f12_boreChildrenBd_bore_re = '0;
          f12_boreChildrenBd_bore_we = '0;
          f12_boreChildrenBd_bore_ack = '0;
          f12_boreChildrenBd_bore_selectedOH = '0;
          f12_boreChildrenBd_bore_array = '0;
          f12_sigFromSrams_bore_ram_hold = '0;
          f12_sigFromSrams_bore_ram_bypass = '0;
          f12_sigFromSrams_bore_ram_bp_clken = '0;
          f12_sigFromSrams_bore_ram_aux_clk = '0;
          f12_sigFromSrams_bore_ram_aux_ckbp = '0;
          f12_sigFromSrams_bore_ram_mcp_hold = '0;
          f12_sigFromSrams_bore_cgen = '0;
        end
      end
      if (cyc % 2000 == 0) f28_mode = $urandom_range(0, 15);
      f28_io_r_req_valid = 1'($urandom);
      f28_io_r_req_bits_setIdx = 8'($urandom);
      f28_io_w_req_valid = 1'($urandom);
      f28_io_w_req_bits_setIdx = 8'($urandom);
      f28_io_w_req_bits_data_0 = 65'({$urandom, $urandom, $urandom});
      f28_boreChildrenBd_bore_addr = 9'($urandom);
      f28_boreChildrenBd_bore_addr_rd = 9'($urandom);
      f28_boreChildrenBd_bore_wdata = 66'({$urandom, $urandom, $urandom});
      f28_boreChildrenBd_bore_wmask = 1'($urandom);
      f28_boreChildrenBd_bore_re = 1'($urandom);
      f28_boreChildrenBd_bore_we = 1'($urandom);
      f28_boreChildrenBd_bore_ack = 1'($urandom);
      f28_boreChildrenBd_bore_selectedOH = 1'($urandom);
      f28_boreChildrenBd_bore_array = 6'($urandom);
      f28_sigFromSrams_bore_ram_hold = 1'($urandom);
      f28_sigFromSrams_bore_ram_bypass = 1'($urandom);
      f28_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      f28_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      f28_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      f28_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      f28_sigFromSrams_bore_cgen = 1'($urandom);
      f28_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_f28
        if (f28_mode < 12) begin
          f28_io_r_req_bits_setIdx = 8'($urandom_range(0, 15));
          f28_io_w_req_bits_setIdx = 8'($urandom_range(0, 15));
        end
        if (f28_mode != 0) begin
          f28_boreChildrenBd_bore_wmask = '0;
          f28_boreChildrenBd_bore_re = '0;
          f28_boreChildrenBd_bore_we = '0;
          f28_boreChildrenBd_bore_ack = '0;
          f28_boreChildrenBd_bore_selectedOH = '0;
          f28_boreChildrenBd_bore_array = '0;
          f28_sigFromSrams_bore_ram_hold = '0;
          f28_sigFromSrams_bore_ram_bypass = '0;
          f28_sigFromSrams_bore_ram_bp_clken = '0;
          f28_sigFromSrams_bore_ram_aux_clk = '0;
          f28_sigFromSrams_bore_ram_aux_ckbp = '0;
          f28_sigFromSrams_bore_ram_mcp_hold = '0;
          f28_sigFromSrams_bore_cgen = '0;
        end
      end
      #4;
      if (cyc >= RESET_CYC + 300 && f0_armed_at >= 0 && cyc >= f0_armed_at) begin
        checks++;
        if (f0_g_io_r_resp_data_0 !== f0_i_io_r_resp_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth.io_r_resp_data_0 g=%h i=%h", cyc, f0_g_io_r_resp_data_0, f0_i_io_r_resp_data_0);
        end
        f0_s1_io_r_resp_data_0 |= f0_g_io_r_resp_data_0;
        f0_s0_io_r_resp_data_0 |= ~f0_g_io_r_resp_data_0;
        checks++;
        if (f0_g_boreChildrenBd_bore_rdata !== f0_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata g=%h i=%h", cyc, f0_g_boreChildrenBd_bore_rdata, f0_i_boreChildrenBd_bore_rdata);
        end
        f0_s1_boreChildrenBd_bore_rdata |= f0_g_boreChildrenBd_bore_rdata;
        f0_s0_boreChildrenBd_bore_rdata |= ~f0_g_boreChildrenBd_bore_rdata;
        if (f0_io_r_req_valid) f0_cov_read++;
        if (f0_io_w_req_valid) f0_cov_write++;
        if (f0_io_r_req_valid && f0_io_w_req_valid) f0_cov_rw_same++;
        if (f0_reset && cyc > 1000) f0_cov_reset_mid++;
      end
      if (cyc > 300 && !f0_reset && f0_io_r_req_valid) f0_armed[0] = 1'b1;
      if (f0_armed_at < 0 && (&f0_armed)) f0_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 300 && f4_armed_at >= 0 && cyc >= f4_armed_at) begin
        checks++;
        if (f4_g_io_r_resp_data_0 !== f4_i_io_r_resp_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth_4.io_r_resp_data_0 g=%h i=%h", cyc, f4_g_io_r_resp_data_0, f4_i_io_r_resp_data_0);
        end
        f4_s1_io_r_resp_data_0 |= f4_g_io_r_resp_data_0;
        f4_s0_io_r_resp_data_0 |= ~f4_g_io_r_resp_data_0;
        checks++;
        if (f4_g_boreChildrenBd_bore_rdata !== f4_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata g=%h i=%h", cyc, f4_g_boreChildrenBd_bore_rdata, f4_i_boreChildrenBd_bore_rdata);
        end
        f4_s1_boreChildrenBd_bore_rdata |= f4_g_boreChildrenBd_bore_rdata;
        f4_s0_boreChildrenBd_bore_rdata |= ~f4_g_boreChildrenBd_bore_rdata;
        if (f4_io_r_req_valid) f4_cov_read++;
        if (f4_io_w_req_valid) f4_cov_write++;
        if (f4_io_r_req_valid && f4_io_w_req_valid) f4_cov_rw_same++;
        if (f4_reset && cyc > 1000) f4_cov_reset_mid++;
      end
      if (cyc > 300 && !f4_reset && f4_io_r_req_valid) f4_armed[0] = 1'b1;
      if (f4_armed_at < 0 && (&f4_armed)) f4_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 300 && f12_armed_at >= 0 && cyc >= f12_armed_at) begin
        checks++;
        if (f12_g_io_r_resp_data_0 !== f12_i_io_r_resp_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth_12.io_r_resp_data_0 g=%h i=%h", cyc, f12_g_io_r_resp_data_0, f12_i_io_r_resp_data_0);
        end
        f12_s1_io_r_resp_data_0 |= f12_g_io_r_resp_data_0;
        f12_s0_io_r_resp_data_0 |= ~f12_g_io_r_resp_data_0;
        checks++;
        if (f12_g_boreChildrenBd_bore_rdata !== f12_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata g=%h i=%h", cyc, f12_g_boreChildrenBd_bore_rdata, f12_i_boreChildrenBd_bore_rdata);
        end
        f12_s1_boreChildrenBd_bore_rdata |= f12_g_boreChildrenBd_bore_rdata;
        f12_s0_boreChildrenBd_bore_rdata |= ~f12_g_boreChildrenBd_bore_rdata;
        if (f12_io_r_req_valid) f12_cov_read++;
        if (f12_io_w_req_valid) f12_cov_write++;
        if (f12_io_r_req_valid && f12_io_w_req_valid) f12_cov_rw_same++;
        if (f12_reset && cyc > 1000) f12_cov_reset_mid++;
      end
      if (cyc > 300 && !f12_reset && f12_io_r_req_valid) f12_armed[0] = 1'b1;
      if (f12_armed_at < 0 && (&f12_armed)) f12_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 300 && f28_armed_at >= 0 && cyc >= f28_armed_at) begin
        checks++;
        if (f28_g_io_r_resp_data_0 !== f28_i_io_r_resp_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth_28.io_r_resp_data_0 g=%h i=%h", cyc, f28_g_io_r_resp_data_0, f28_i_io_r_resp_data_0);
        end
        f28_s1_io_r_resp_data_0 |= f28_g_io_r_resp_data_0;
        f28_s0_io_r_resp_data_0 |= ~f28_g_io_r_resp_data_0;
        checks++;
        if (f28_g_boreChildrenBd_bore_rdata !== f28_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata g=%h i=%h", cyc, f28_g_boreChildrenBd_bore_rdata, f28_i_boreChildrenBd_bore_rdata);
        end
        f28_s1_boreChildrenBd_bore_rdata |= f28_g_boreChildrenBd_bore_rdata;
        f28_s0_boreChildrenBd_bore_rdata |= ~f28_g_boreChildrenBd_bore_rdata;
        if (f28_io_r_req_valid) f28_cov_read++;
        if (f28_io_w_req_valid) f28_cov_write++;
        if (f28_io_r_req_valid && f28_io_w_req_valid) f28_cov_rw_same++;
        if (f28_reset && cyc > 1000) f28_cov_reset_mid++;
      end
      if (cyc > 300 && !f28_reset && f28_io_r_req_valid) f28_armed[0] = 1'b1;
      if (f28_armed_at < 0 && (&f28_armed)) f28_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(f0_s0_io_r_resp_data_0[0] && f0_s1_io_r_resp_data_0[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[0] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[1] && f0_s1_io_r_resp_data_0[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[1] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[2] && f0_s1_io_r_resp_data_0[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[2] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[3] && f0_s1_io_r_resp_data_0[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[3] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[4] && f0_s1_io_r_resp_data_0[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[4] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[5] && f0_s1_io_r_resp_data_0[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[5] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[6] && f0_s1_io_r_resp_data_0[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[6] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[7] && f0_s1_io_r_resp_data_0[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[7] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[8] && f0_s1_io_r_resp_data_0[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[8] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[9] && f0_s1_io_r_resp_data_0[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[9] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[10] && f0_s1_io_r_resp_data_0[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[10] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[11] && f0_s1_io_r_resp_data_0[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[11] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[12] && f0_s1_io_r_resp_data_0[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[12] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[13] && f0_s1_io_r_resp_data_0[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[13] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[14] && f0_s1_io_r_resp_data_0[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[14] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[15] && f0_s1_io_r_resp_data_0[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[15] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[16] && f0_s1_io_r_resp_data_0[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[16] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[17] && f0_s1_io_r_resp_data_0[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[17] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[18] && f0_s1_io_r_resp_data_0[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[18] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[19] && f0_s1_io_r_resp_data_0[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[19] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[20] && f0_s1_io_r_resp_data_0[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[20] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[21] && f0_s1_io_r_resp_data_0[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[21] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[22] && f0_s1_io_r_resp_data_0[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[22] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[23] && f0_s1_io_r_resp_data_0[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[23] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[24] && f0_s1_io_r_resp_data_0[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[24] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[25] && f0_s1_io_r_resp_data_0[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[25] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[26] && f0_s1_io_r_resp_data_0[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[26] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[27] && f0_s1_io_r_resp_data_0[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[27] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[28] && f0_s1_io_r_resp_data_0[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[28] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[29] && f0_s1_io_r_resp_data_0[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[29] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[30] && f0_s1_io_r_resp_data_0[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[30] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[31] && f0_s1_io_r_resp_data_0[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[31] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[32] && f0_s1_io_r_resp_data_0[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[32] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[33] && f0_s1_io_r_resp_data_0[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[33] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[34] && f0_s1_io_r_resp_data_0[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[34] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[35] && f0_s1_io_r_resp_data_0[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[35] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[36] && f0_s1_io_r_resp_data_0[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[36] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[37] && f0_s1_io_r_resp_data_0[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[37] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[38] && f0_s1_io_r_resp_data_0[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[38] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[39] && f0_s1_io_r_resp_data_0[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[39] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[40] && f0_s1_io_r_resp_data_0[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[40] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[41] && f0_s1_io_r_resp_data_0[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[41] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[42] && f0_s1_io_r_resp_data_0[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[42] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[43] && f0_s1_io_r_resp_data_0[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[43] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[44] && f0_s1_io_r_resp_data_0[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[44] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[45] && f0_s1_io_r_resp_data_0[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[45] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[46] && f0_s1_io_r_resp_data_0[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[46] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[47] && f0_s1_io_r_resp_data_0[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[47] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[48] && f0_s1_io_r_resp_data_0[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[48] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[49] && f0_s1_io_r_resp_data_0[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[49] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[50] && f0_s1_io_r_resp_data_0[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[50] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[51] && f0_s1_io_r_resp_data_0[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[51] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[52] && f0_s1_io_r_resp_data_0[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[52] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[53] && f0_s1_io_r_resp_data_0[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[53] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[54] && f0_s1_io_r_resp_data_0[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[54] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[55] && f0_s1_io_r_resp_data_0[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[55] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[56] && f0_s1_io_r_resp_data_0[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[56] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[57] && f0_s1_io_r_resp_data_0[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[57] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[58] && f0_s1_io_r_resp_data_0[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[58] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[59] && f0_s1_io_r_resp_data_0[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[59] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[60] && f0_s1_io_r_resp_data_0[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[60] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[61] && f0_s1_io_r_resp_data_0[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[61] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[62] && f0_s1_io_r_resp_data_0[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[62] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[63] && f0_s1_io_r_resp_data_0[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[63] 未见过 0 和 1"); end
    if (!(f0_s0_io_r_resp_data_0[64] && f0_s1_io_r_resp_data_0[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.io_r_resp_data_0[64] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[0] && f0_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[1] && f0_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[2] && f0_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[3] && f0_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[4] && f0_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[5] && f0_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[6] && f0_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[7] && f0_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[8] && f0_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[9] && f0_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[10] && f0_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[11] && f0_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[12] && f0_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[13] && f0_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[14] && f0_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[15] && f0_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[16] && f0_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[17] && f0_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[18] && f0_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[19] && f0_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[20] && f0_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[21] && f0_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[22] && f0_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[23] && f0_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[24] && f0_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[25] && f0_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[26] && f0_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[27] && f0_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[28] && f0_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[29] && f0_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[30] && f0_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[31] && f0_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[32] && f0_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[33] && f0_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[34] && f0_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[35] && f0_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[36] && f0_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[37] && f0_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[38] && f0_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[39] && f0_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[40] && f0_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[41] && f0_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[42] && f0_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[43] && f0_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[44] && f0_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[45] && f0_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[46] && f0_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[47] && f0_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[48] && f0_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[49] && f0_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[50] && f0_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[51] && f0_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[52] && f0_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[53] && f0_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[54] && f0_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[55] && f0_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[56] && f0_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[57] && f0_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[58] && f0_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[59] && f0_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[60] && f0_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[61] && f0_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[62] && f0_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[63] && f0_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[64] && f0_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(f0_s0_boreChildrenBd_bore_rdata[65] && f0_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    $display("[ARM] SRAMTemplateWithFixedWidth armed_at=%0d", f0_armed_at);
    if (f0_armed_at < 0) begin cov_fail++; $display("[ARM] SRAMTemplateWithFixedWidth 从未 arm"); end
    $display("[COV] SRAMTemplateWithFixedWidth.read = %0d", f0_cov_read);
    if (f0_cov_read < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.read < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth.write = %0d", f0_cov_write);
    if (f0_cov_write < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.write < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth.rw_same = %0d", f0_cov_rw_same);
    if (f0_cov_rw_same < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.rw_same < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth.reset_mid = %0d", f0_cov_reset_mid);
    if (f0_cov_reset_mid < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth.reset_mid < 5"); end
    if (!(f4_s0_io_r_resp_data_0[0] && f4_s1_io_r_resp_data_0[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[0] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[1] && f4_s1_io_r_resp_data_0[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[1] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[2] && f4_s1_io_r_resp_data_0[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[2] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[3] && f4_s1_io_r_resp_data_0[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[3] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[4] && f4_s1_io_r_resp_data_0[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[4] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[5] && f4_s1_io_r_resp_data_0[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[5] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[6] && f4_s1_io_r_resp_data_0[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[6] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[7] && f4_s1_io_r_resp_data_0[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[7] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[8] && f4_s1_io_r_resp_data_0[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[8] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[9] && f4_s1_io_r_resp_data_0[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[9] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[10] && f4_s1_io_r_resp_data_0[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[10] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[11] && f4_s1_io_r_resp_data_0[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[11] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[12] && f4_s1_io_r_resp_data_0[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[12] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[13] && f4_s1_io_r_resp_data_0[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[13] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[14] && f4_s1_io_r_resp_data_0[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[14] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[15] && f4_s1_io_r_resp_data_0[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[15] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[16] && f4_s1_io_r_resp_data_0[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[16] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[17] && f4_s1_io_r_resp_data_0[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[17] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[18] && f4_s1_io_r_resp_data_0[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[18] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[19] && f4_s1_io_r_resp_data_0[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[19] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[20] && f4_s1_io_r_resp_data_0[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[20] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[21] && f4_s1_io_r_resp_data_0[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[21] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[22] && f4_s1_io_r_resp_data_0[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[22] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[23] && f4_s1_io_r_resp_data_0[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[23] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[24] && f4_s1_io_r_resp_data_0[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[24] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[25] && f4_s1_io_r_resp_data_0[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[25] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[26] && f4_s1_io_r_resp_data_0[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[26] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[27] && f4_s1_io_r_resp_data_0[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[27] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[28] && f4_s1_io_r_resp_data_0[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[28] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[29] && f4_s1_io_r_resp_data_0[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[29] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[30] && f4_s1_io_r_resp_data_0[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[30] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[31] && f4_s1_io_r_resp_data_0[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[31] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[32] && f4_s1_io_r_resp_data_0[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[32] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[33] && f4_s1_io_r_resp_data_0[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[33] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[34] && f4_s1_io_r_resp_data_0[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[34] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[35] && f4_s1_io_r_resp_data_0[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[35] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[36] && f4_s1_io_r_resp_data_0[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[36] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[37] && f4_s1_io_r_resp_data_0[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[37] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[38] && f4_s1_io_r_resp_data_0[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[38] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[39] && f4_s1_io_r_resp_data_0[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[39] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[40] && f4_s1_io_r_resp_data_0[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[40] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[41] && f4_s1_io_r_resp_data_0[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[41] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[42] && f4_s1_io_r_resp_data_0[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[42] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[43] && f4_s1_io_r_resp_data_0[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[43] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[44] && f4_s1_io_r_resp_data_0[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[44] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[45] && f4_s1_io_r_resp_data_0[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[45] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[46] && f4_s1_io_r_resp_data_0[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[46] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[47] && f4_s1_io_r_resp_data_0[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[47] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[48] && f4_s1_io_r_resp_data_0[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[48] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[49] && f4_s1_io_r_resp_data_0[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[49] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[50] && f4_s1_io_r_resp_data_0[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[50] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[51] && f4_s1_io_r_resp_data_0[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[51] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[52] && f4_s1_io_r_resp_data_0[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[52] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[53] && f4_s1_io_r_resp_data_0[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[53] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[54] && f4_s1_io_r_resp_data_0[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[54] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[55] && f4_s1_io_r_resp_data_0[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[55] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[56] && f4_s1_io_r_resp_data_0[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[56] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[57] && f4_s1_io_r_resp_data_0[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[57] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[58] && f4_s1_io_r_resp_data_0[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[58] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[59] && f4_s1_io_r_resp_data_0[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[59] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[60] && f4_s1_io_r_resp_data_0[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[60] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[61] && f4_s1_io_r_resp_data_0[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[61] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[62] && f4_s1_io_r_resp_data_0[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[62] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[63] && f4_s1_io_r_resp_data_0[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[63] 未见过 0 和 1"); end
    if (!(f4_s0_io_r_resp_data_0[64] && f4_s1_io_r_resp_data_0[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.io_r_resp_data_0[64] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[0] && f4_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[1] && f4_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[2] && f4_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[3] && f4_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[4] && f4_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[5] && f4_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[6] && f4_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[7] && f4_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[8] && f4_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[9] && f4_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[10] && f4_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[11] && f4_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[12] && f4_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[13] && f4_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[14] && f4_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[15] && f4_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[16] && f4_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[17] && f4_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[18] && f4_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[19] && f4_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[20] && f4_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[21] && f4_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[22] && f4_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[23] && f4_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[24] && f4_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[25] && f4_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[26] && f4_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[27] && f4_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[28] && f4_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[29] && f4_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[30] && f4_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[31] && f4_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[32] && f4_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[33] && f4_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[34] && f4_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[35] && f4_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[36] && f4_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[37] && f4_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[38] && f4_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[39] && f4_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[40] && f4_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[41] && f4_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[42] && f4_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[43] && f4_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[44] && f4_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[45] && f4_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[46] && f4_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[47] && f4_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[48] && f4_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[49] && f4_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[50] && f4_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[51] && f4_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[52] && f4_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[53] && f4_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[54] && f4_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[55] && f4_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[56] && f4_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[57] && f4_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[58] && f4_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[59] && f4_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[60] && f4_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[61] && f4_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[62] && f4_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[63] && f4_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[64] && f4_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(f4_s0_boreChildrenBd_bore_rdata[65] && f4_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    $display("[ARM] SRAMTemplateWithFixedWidth_4 armed_at=%0d", f4_armed_at);
    if (f4_armed_at < 0) begin cov_fail++; $display("[ARM] SRAMTemplateWithFixedWidth_4 从未 arm"); end
    $display("[COV] SRAMTemplateWithFixedWidth_4.read = %0d", f4_cov_read);
    if (f4_cov_read < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.read < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_4.write = %0d", f4_cov_write);
    if (f4_cov_write < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.write < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_4.rw_same = %0d", f4_cov_rw_same);
    if (f4_cov_rw_same < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.rw_same < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_4.reset_mid = %0d", f4_cov_reset_mid);
    if (f4_cov_reset_mid < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_4.reset_mid < 5"); end
    if (!(f12_s0_io_r_resp_data_0[0] && f12_s1_io_r_resp_data_0[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[0] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[1] && f12_s1_io_r_resp_data_0[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[1] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[2] && f12_s1_io_r_resp_data_0[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[2] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[3] && f12_s1_io_r_resp_data_0[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[3] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[4] && f12_s1_io_r_resp_data_0[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[4] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[5] && f12_s1_io_r_resp_data_0[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[5] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[6] && f12_s1_io_r_resp_data_0[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[6] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[7] && f12_s1_io_r_resp_data_0[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[7] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[8] && f12_s1_io_r_resp_data_0[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[8] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[9] && f12_s1_io_r_resp_data_0[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[9] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[10] && f12_s1_io_r_resp_data_0[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[10] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[11] && f12_s1_io_r_resp_data_0[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[11] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[12] && f12_s1_io_r_resp_data_0[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[12] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[13] && f12_s1_io_r_resp_data_0[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[13] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[14] && f12_s1_io_r_resp_data_0[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[14] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[15] && f12_s1_io_r_resp_data_0[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[15] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[16] && f12_s1_io_r_resp_data_0[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[16] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[17] && f12_s1_io_r_resp_data_0[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[17] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[18] && f12_s1_io_r_resp_data_0[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[18] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[19] && f12_s1_io_r_resp_data_0[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[19] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[20] && f12_s1_io_r_resp_data_0[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[20] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[21] && f12_s1_io_r_resp_data_0[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[21] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[22] && f12_s1_io_r_resp_data_0[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[22] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[23] && f12_s1_io_r_resp_data_0[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[23] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[24] && f12_s1_io_r_resp_data_0[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[24] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[25] && f12_s1_io_r_resp_data_0[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[25] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[26] && f12_s1_io_r_resp_data_0[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[26] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[27] && f12_s1_io_r_resp_data_0[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[27] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[28] && f12_s1_io_r_resp_data_0[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[28] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[29] && f12_s1_io_r_resp_data_0[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[29] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[30] && f12_s1_io_r_resp_data_0[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[30] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[31] && f12_s1_io_r_resp_data_0[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[31] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[32] && f12_s1_io_r_resp_data_0[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[32] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[33] && f12_s1_io_r_resp_data_0[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[33] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[34] && f12_s1_io_r_resp_data_0[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[34] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[35] && f12_s1_io_r_resp_data_0[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[35] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[36] && f12_s1_io_r_resp_data_0[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[36] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[37] && f12_s1_io_r_resp_data_0[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[37] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[38] && f12_s1_io_r_resp_data_0[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[38] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[39] && f12_s1_io_r_resp_data_0[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[39] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[40] && f12_s1_io_r_resp_data_0[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[40] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[41] && f12_s1_io_r_resp_data_0[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[41] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[42] && f12_s1_io_r_resp_data_0[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[42] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[43] && f12_s1_io_r_resp_data_0[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[43] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[44] && f12_s1_io_r_resp_data_0[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[44] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[45] && f12_s1_io_r_resp_data_0[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[45] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[46] && f12_s1_io_r_resp_data_0[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[46] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[47] && f12_s1_io_r_resp_data_0[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[47] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[48] && f12_s1_io_r_resp_data_0[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[48] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[49] && f12_s1_io_r_resp_data_0[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[49] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[50] && f12_s1_io_r_resp_data_0[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[50] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[51] && f12_s1_io_r_resp_data_0[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[51] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[52] && f12_s1_io_r_resp_data_0[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[52] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[53] && f12_s1_io_r_resp_data_0[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[53] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[54] && f12_s1_io_r_resp_data_0[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[54] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[55] && f12_s1_io_r_resp_data_0[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[55] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[56] && f12_s1_io_r_resp_data_0[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[56] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[57] && f12_s1_io_r_resp_data_0[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[57] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[58] && f12_s1_io_r_resp_data_0[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[58] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[59] && f12_s1_io_r_resp_data_0[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[59] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[60] && f12_s1_io_r_resp_data_0[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[60] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[61] && f12_s1_io_r_resp_data_0[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[61] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[62] && f12_s1_io_r_resp_data_0[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[62] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[63] && f12_s1_io_r_resp_data_0[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[63] 未见过 0 和 1"); end
    if (!(f12_s0_io_r_resp_data_0[64] && f12_s1_io_r_resp_data_0[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.io_r_resp_data_0[64] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[0] && f12_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[1] && f12_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[2] && f12_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[3] && f12_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[4] && f12_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[5] && f12_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[6] && f12_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[7] && f12_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[8] && f12_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[9] && f12_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[10] && f12_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[11] && f12_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[12] && f12_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[13] && f12_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[14] && f12_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[15] && f12_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[16] && f12_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[17] && f12_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[18] && f12_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[19] && f12_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[20] && f12_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[21] && f12_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[22] && f12_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[23] && f12_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[24] && f12_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[25] && f12_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[26] && f12_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[27] && f12_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[28] && f12_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[29] && f12_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[30] && f12_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[31] && f12_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[32] && f12_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[33] && f12_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[34] && f12_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[35] && f12_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[36] && f12_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[37] && f12_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[38] && f12_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[39] && f12_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[40] && f12_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[41] && f12_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[42] && f12_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[43] && f12_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[44] && f12_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[45] && f12_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[46] && f12_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[47] && f12_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[48] && f12_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[49] && f12_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[50] && f12_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[51] && f12_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[52] && f12_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[53] && f12_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[54] && f12_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[55] && f12_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[56] && f12_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[57] && f12_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[58] && f12_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[59] && f12_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[60] && f12_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[61] && f12_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[62] && f12_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[63] && f12_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[64] && f12_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(f12_s0_boreChildrenBd_bore_rdata[65] && f12_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    $display("[ARM] SRAMTemplateWithFixedWidth_12 armed_at=%0d", f12_armed_at);
    if (f12_armed_at < 0) begin cov_fail++; $display("[ARM] SRAMTemplateWithFixedWidth_12 从未 arm"); end
    $display("[COV] SRAMTemplateWithFixedWidth_12.read = %0d", f12_cov_read);
    if (f12_cov_read < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.read < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_12.write = %0d", f12_cov_write);
    if (f12_cov_write < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.write < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_12.rw_same = %0d", f12_cov_rw_same);
    if (f12_cov_rw_same < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.rw_same < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_12.reset_mid = %0d", f12_cov_reset_mid);
    if (f12_cov_reset_mid < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_12.reset_mid < 5"); end
    if (!(f28_s0_io_r_resp_data_0[0] && f28_s1_io_r_resp_data_0[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[0] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[1] && f28_s1_io_r_resp_data_0[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[1] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[2] && f28_s1_io_r_resp_data_0[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[2] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[3] && f28_s1_io_r_resp_data_0[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[3] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[4] && f28_s1_io_r_resp_data_0[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[4] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[5] && f28_s1_io_r_resp_data_0[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[5] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[6] && f28_s1_io_r_resp_data_0[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[6] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[7] && f28_s1_io_r_resp_data_0[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[7] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[8] && f28_s1_io_r_resp_data_0[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[8] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[9] && f28_s1_io_r_resp_data_0[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[9] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[10] && f28_s1_io_r_resp_data_0[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[10] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[11] && f28_s1_io_r_resp_data_0[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[11] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[12] && f28_s1_io_r_resp_data_0[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[12] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[13] && f28_s1_io_r_resp_data_0[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[13] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[14] && f28_s1_io_r_resp_data_0[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[14] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[15] && f28_s1_io_r_resp_data_0[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[15] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[16] && f28_s1_io_r_resp_data_0[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[16] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[17] && f28_s1_io_r_resp_data_0[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[17] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[18] && f28_s1_io_r_resp_data_0[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[18] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[19] && f28_s1_io_r_resp_data_0[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[19] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[20] && f28_s1_io_r_resp_data_0[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[20] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[21] && f28_s1_io_r_resp_data_0[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[21] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[22] && f28_s1_io_r_resp_data_0[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[22] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[23] && f28_s1_io_r_resp_data_0[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[23] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[24] && f28_s1_io_r_resp_data_0[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[24] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[25] && f28_s1_io_r_resp_data_0[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[25] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[26] && f28_s1_io_r_resp_data_0[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[26] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[27] && f28_s1_io_r_resp_data_0[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[27] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[28] && f28_s1_io_r_resp_data_0[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[28] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[29] && f28_s1_io_r_resp_data_0[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[29] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[30] && f28_s1_io_r_resp_data_0[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[30] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[31] && f28_s1_io_r_resp_data_0[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[31] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[32] && f28_s1_io_r_resp_data_0[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[32] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[33] && f28_s1_io_r_resp_data_0[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[33] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[34] && f28_s1_io_r_resp_data_0[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[34] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[35] && f28_s1_io_r_resp_data_0[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[35] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[36] && f28_s1_io_r_resp_data_0[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[36] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[37] && f28_s1_io_r_resp_data_0[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[37] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[38] && f28_s1_io_r_resp_data_0[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[38] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[39] && f28_s1_io_r_resp_data_0[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[39] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[40] && f28_s1_io_r_resp_data_0[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[40] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[41] && f28_s1_io_r_resp_data_0[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[41] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[42] && f28_s1_io_r_resp_data_0[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[42] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[43] && f28_s1_io_r_resp_data_0[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[43] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[44] && f28_s1_io_r_resp_data_0[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[44] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[45] && f28_s1_io_r_resp_data_0[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[45] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[46] && f28_s1_io_r_resp_data_0[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[46] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[47] && f28_s1_io_r_resp_data_0[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[47] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[48] && f28_s1_io_r_resp_data_0[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[48] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[49] && f28_s1_io_r_resp_data_0[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[49] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[50] && f28_s1_io_r_resp_data_0[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[50] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[51] && f28_s1_io_r_resp_data_0[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[51] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[52] && f28_s1_io_r_resp_data_0[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[52] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[53] && f28_s1_io_r_resp_data_0[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[53] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[54] && f28_s1_io_r_resp_data_0[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[54] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[55] && f28_s1_io_r_resp_data_0[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[55] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[56] && f28_s1_io_r_resp_data_0[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[56] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[57] && f28_s1_io_r_resp_data_0[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[57] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[58] && f28_s1_io_r_resp_data_0[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[58] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[59] && f28_s1_io_r_resp_data_0[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[59] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[60] && f28_s1_io_r_resp_data_0[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[60] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[61] && f28_s1_io_r_resp_data_0[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[61] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[62] && f28_s1_io_r_resp_data_0[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[62] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[63] && f28_s1_io_r_resp_data_0[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[63] 未见过 0 和 1"); end
    if (!(f28_s0_io_r_resp_data_0[64] && f28_s1_io_r_resp_data_0[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.io_r_resp_data_0[64] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[0] && f28_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[1] && f28_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[2] && f28_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[3] && f28_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[4] && f28_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[5] && f28_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[6] && f28_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[7] && f28_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[8] && f28_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[9] && f28_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[10] && f28_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[11] && f28_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[12] && f28_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[13] && f28_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[14] && f28_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[15] && f28_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[16] && f28_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[17] && f28_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[18] && f28_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[19] && f28_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[20] && f28_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[21] && f28_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[22] && f28_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[23] && f28_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[24] && f28_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[25] && f28_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[26] && f28_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[27] && f28_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[28] && f28_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[29] && f28_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[30] && f28_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[31] && f28_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[32] && f28_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[33] && f28_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[34] && f28_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[35] && f28_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[36] && f28_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[37] && f28_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[38] && f28_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[39] && f28_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[40] && f28_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[41] && f28_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[42] && f28_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[43] && f28_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[44] && f28_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[45] && f28_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[46] && f28_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[47] && f28_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[48] && f28_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[49] && f28_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[50] && f28_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[51] && f28_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[52] && f28_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[53] && f28_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[54] && f28_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[55] && f28_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[56] && f28_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[57] && f28_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[58] && f28_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[59] && f28_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[60] && f28_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[61] && f28_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[62] && f28_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[63] && f28_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[64] && f28_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(f28_s0_boreChildrenBd_bore_rdata[65] && f28_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    $display("[ARM] SRAMTemplateWithFixedWidth_28 armed_at=%0d", f28_armed_at);
    if (f28_armed_at < 0) begin cov_fail++; $display("[ARM] SRAMTemplateWithFixedWidth_28 从未 arm"); end
    $display("[COV] SRAMTemplateWithFixedWidth_28.read = %0d", f28_cov_read);
    if (f28_cov_read < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.read < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_28.write = %0d", f28_cov_write);
    if (f28_cov_write < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.write < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_28.rw_same = %0d", f28_cov_rw_same);
    if (f28_cov_rw_same < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.rw_same < 5"); end
    $display("[COV] SRAMTemplateWithFixedWidth_28.reset_mid = %0d", f28_cov_reset_mid);
    if (f28_cov_reset_mid < 5) begin cov_fail++; $display("[COV] SRAMTemplateWithFixedWidth_28.reset_mid < 5"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
