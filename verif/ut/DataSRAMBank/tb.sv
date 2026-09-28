// 自动生成：verif/ut/DataSRAMBank/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// DataSRAMBank 家族 4 对双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= DataSRAMBank =================
  int unsigned db0_mode = 0;
  logic db0_reset;
  logic db0_io_w_en;
  logic [7:0] db0_io_w_addr;
  logic [3:0] db0_io_w_way_en;
  logic [71:0] db0_io_w_data;
  logic db0_io_r_en;
  logic [7:0] db0_io_r_addr;
  wire  [71:0] db0_g_io_r_data_0, db0_i_io_r_data_0;
  logic [71:0] db0_s0_io_r_data_0 = '0, db0_s1_io_r_data_0 = '0;
  wire  [71:0] db0_g_io_r_data_1, db0_i_io_r_data_1;
  logic [71:0] db0_s0_io_r_data_1 = '0, db0_s1_io_r_data_1 = '0;
  wire  [71:0] db0_g_io_r_data_2, db0_i_io_r_data_2;
  logic [71:0] db0_s0_io_r_data_2 = '0, db0_s1_io_r_data_2 = '0;
  wire  [71:0] db0_g_io_r_data_3, db0_i_io_r_data_3;
  logic [71:0] db0_s0_io_r_data_3 = '0, db0_s1_io_r_data_3 = '0;
  logic [8:0] db0_boreChildrenBd_bore_addr;
  logic [8:0] db0_boreChildrenBd_bore_addr_rd;
  logic [71:0] db0_boreChildrenBd_bore_wdata;
  logic db0_boreChildrenBd_bore_wmask;
  logic db0_boreChildrenBd_bore_re;
  logic db0_boreChildrenBd_bore_we;
  wire  [71:0] db0_g_boreChildrenBd_bore_rdata, db0_i_boreChildrenBd_bore_rdata;
  logic [71:0] db0_s0_boreChildrenBd_bore_rdata = '0, db0_s1_boreChildrenBd_bore_rdata = '0;
  logic db0_boreChildrenBd_bore_ack;
  logic db0_boreChildrenBd_bore_selectedOH;
  logic db0_boreChildrenBd_bore_array;
  logic [8:0] db0_boreChildrenBd_bore_1_addr;
  logic [8:0] db0_boreChildrenBd_bore_1_addr_rd;
  logic [71:0] db0_boreChildrenBd_bore_1_wdata;
  logic db0_boreChildrenBd_bore_1_wmask;
  logic db0_boreChildrenBd_bore_1_re;
  logic db0_boreChildrenBd_bore_1_we;
  wire  [71:0] db0_g_boreChildrenBd_bore_1_rdata, db0_i_boreChildrenBd_bore_1_rdata;
  logic [71:0] db0_s0_boreChildrenBd_bore_1_rdata = '0, db0_s1_boreChildrenBd_bore_1_rdata = '0;
  logic db0_boreChildrenBd_bore_1_ack;
  logic db0_boreChildrenBd_bore_1_selectedOH;
  logic db0_boreChildrenBd_bore_1_array;
  logic [8:0] db0_boreChildrenBd_bore_2_addr;
  logic [8:0] db0_boreChildrenBd_bore_2_addr_rd;
  logic [71:0] db0_boreChildrenBd_bore_2_wdata;
  logic db0_boreChildrenBd_bore_2_wmask;
  logic db0_boreChildrenBd_bore_2_re;
  logic db0_boreChildrenBd_bore_2_we;
  wire  [71:0] db0_g_boreChildrenBd_bore_2_rdata, db0_i_boreChildrenBd_bore_2_rdata;
  logic [71:0] db0_s0_boreChildrenBd_bore_2_rdata = '0, db0_s1_boreChildrenBd_bore_2_rdata = '0;
  logic db0_boreChildrenBd_bore_2_ack;
  logic db0_boreChildrenBd_bore_2_selectedOH;
  logic [1:0] db0_boreChildrenBd_bore_2_array;
  logic [8:0] db0_boreChildrenBd_bore_3_addr;
  logic [8:0] db0_boreChildrenBd_bore_3_addr_rd;
  logic [71:0] db0_boreChildrenBd_bore_3_wdata;
  logic db0_boreChildrenBd_bore_3_wmask;
  logic db0_boreChildrenBd_bore_3_re;
  logic db0_boreChildrenBd_bore_3_we;
  wire  [71:0] db0_g_boreChildrenBd_bore_3_rdata, db0_i_boreChildrenBd_bore_3_rdata;
  logic [71:0] db0_s0_boreChildrenBd_bore_3_rdata = '0, db0_s1_boreChildrenBd_bore_3_rdata = '0;
  logic db0_boreChildrenBd_bore_3_ack;
  logic db0_boreChildrenBd_bore_3_selectedOH;
  logic [1:0] db0_boreChildrenBd_bore_3_array;
  logic db0_sigFromSrams_bore_ram_hold;
  logic db0_sigFromSrams_bore_ram_bypass;
  logic db0_sigFromSrams_bore_ram_bp_clken;
  logic db0_sigFromSrams_bore_ram_aux_clk;
  logic db0_sigFromSrams_bore_ram_aux_ckbp;
  logic db0_sigFromSrams_bore_ram_mcp_hold;
  logic db0_sigFromSrams_bore_cgen;
  logic db0_sigFromSrams_bore_1_ram_hold;
  logic db0_sigFromSrams_bore_1_ram_bypass;
  logic db0_sigFromSrams_bore_1_ram_bp_clken;
  logic db0_sigFromSrams_bore_1_ram_aux_clk;
  logic db0_sigFromSrams_bore_1_ram_aux_ckbp;
  logic db0_sigFromSrams_bore_1_ram_mcp_hold;
  logic db0_sigFromSrams_bore_1_cgen;
  logic db0_sigFromSrams_bore_2_ram_hold;
  logic db0_sigFromSrams_bore_2_ram_bypass;
  logic db0_sigFromSrams_bore_2_ram_bp_clken;
  logic db0_sigFromSrams_bore_2_ram_aux_clk;
  logic db0_sigFromSrams_bore_2_ram_aux_ckbp;
  logic db0_sigFromSrams_bore_2_ram_mcp_hold;
  logic db0_sigFromSrams_bore_2_cgen;
  logic db0_sigFromSrams_bore_3_ram_hold;
  logic db0_sigFromSrams_bore_3_ram_bypass;
  logic db0_sigFromSrams_bore_3_ram_bp_clken;
  logic db0_sigFromSrams_bore_3_ram_aux_clk;
  logic db0_sigFromSrams_bore_3_ram_aux_ckbp;
  logic db0_sigFromSrams_bore_3_ram_mcp_hold;
  logic db0_sigFromSrams_bore_3_cgen;
  int db0_cov_multi_way_write = 0;
  int db0_cov_read = 0;
  int db0_cov_mbist_we = 0;
  logic [1:0] db0_armed = '0;
  int db0_armed_at = -1;
  DataSRAMBank db0_u_gold (
    .clock(clk),
    .reset(db0_reset),
    .io_w_en(db0_io_w_en),
    .io_w_addr(db0_io_w_addr),
    .io_w_way_en(db0_io_w_way_en),
    .io_w_data(db0_io_w_data),
    .io_r_en(db0_io_r_en),
    .io_r_addr(db0_io_r_addr),
    .io_r_data_0(db0_g_io_r_data_0),
    .io_r_data_1(db0_g_io_r_data_1),
    .io_r_data_2(db0_g_io_r_data_2),
    .io_r_data_3(db0_g_io_r_data_3),
    .boreChildrenBd_bore_addr(db0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db0_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db0_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db0_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db0_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db0_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db0_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db0_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db0_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db0_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db0_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db0_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db0_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db0_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db0_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db0_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db0_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db0_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db0_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db0_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db0_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db0_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db0_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db0_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db0_g_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db0_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db0_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db0_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db0_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db0_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db0_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db0_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db0_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db0_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db0_g_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db0_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db0_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db0_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db0_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db0_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db0_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db0_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db0_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db0_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db0_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db0_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db0_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db0_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db0_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db0_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db0_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db0_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db0_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db0_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db0_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db0_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db0_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db0_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db0_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db0_sigFromSrams_bore_3_cgen)
  );
  DataSRAMBank_xs db0_u_impl (
    .clock(clk),
    .reset(db0_reset),
    .io_w_en(db0_io_w_en),
    .io_w_addr(db0_io_w_addr),
    .io_w_way_en(db0_io_w_way_en),
    .io_w_data(db0_io_w_data),
    .io_r_en(db0_io_r_en),
    .io_r_addr(db0_io_r_addr),
    .io_r_data_0(db0_i_io_r_data_0),
    .io_r_data_1(db0_i_io_r_data_1),
    .io_r_data_2(db0_i_io_r_data_2),
    .io_r_data_3(db0_i_io_r_data_3),
    .boreChildrenBd_bore_addr(db0_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db0_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db0_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db0_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db0_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db0_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db0_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db0_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db0_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db0_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db0_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db0_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db0_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db0_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db0_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db0_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db0_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db0_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db0_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db0_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db0_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db0_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db0_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db0_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db0_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db0_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db0_i_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db0_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db0_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db0_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db0_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db0_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db0_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db0_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db0_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db0_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db0_i_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db0_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db0_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db0_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db0_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db0_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db0_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db0_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db0_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db0_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db0_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db0_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db0_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db0_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db0_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db0_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db0_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db0_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db0_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db0_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db0_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db0_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db0_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db0_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db0_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db0_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db0_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db0_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db0_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db0_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db0_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db0_sigFromSrams_bore_3_cgen)
  );

  // ================= DataSRAMBank_1 =================
  int unsigned db1_mode = 0;
  logic db1_reset;
  logic db1_io_w_en;
  logic [7:0] db1_io_w_addr;
  logic [3:0] db1_io_w_way_en;
  logic [71:0] db1_io_w_data;
  logic db1_io_r_en;
  logic [7:0] db1_io_r_addr;
  wire  [71:0] db1_g_io_r_data_0, db1_i_io_r_data_0;
  logic [71:0] db1_s0_io_r_data_0 = '0, db1_s1_io_r_data_0 = '0;
  wire  [71:0] db1_g_io_r_data_1, db1_i_io_r_data_1;
  logic [71:0] db1_s0_io_r_data_1 = '0, db1_s1_io_r_data_1 = '0;
  wire  [71:0] db1_g_io_r_data_2, db1_i_io_r_data_2;
  logic [71:0] db1_s0_io_r_data_2 = '0, db1_s1_io_r_data_2 = '0;
  wire  [71:0] db1_g_io_r_data_3, db1_i_io_r_data_3;
  logic [71:0] db1_s0_io_r_data_3 = '0, db1_s1_io_r_data_3 = '0;
  logic [8:0] db1_boreChildrenBd_bore_addr;
  logic [8:0] db1_boreChildrenBd_bore_addr_rd;
  logic [71:0] db1_boreChildrenBd_bore_wdata;
  logic db1_boreChildrenBd_bore_wmask;
  logic db1_boreChildrenBd_bore_re;
  logic db1_boreChildrenBd_bore_we;
  wire  [71:0] db1_g_boreChildrenBd_bore_rdata, db1_i_boreChildrenBd_bore_rdata;
  logic [71:0] db1_s0_boreChildrenBd_bore_rdata = '0, db1_s1_boreChildrenBd_bore_rdata = '0;
  logic db1_boreChildrenBd_bore_ack;
  logic db1_boreChildrenBd_bore_selectedOH;
  logic [2:0] db1_boreChildrenBd_bore_array;
  logic [8:0] db1_boreChildrenBd_bore_1_addr;
  logic [8:0] db1_boreChildrenBd_bore_1_addr_rd;
  logic [71:0] db1_boreChildrenBd_bore_1_wdata;
  logic db1_boreChildrenBd_bore_1_wmask;
  logic db1_boreChildrenBd_bore_1_re;
  logic db1_boreChildrenBd_bore_1_we;
  wire  [71:0] db1_g_boreChildrenBd_bore_1_rdata, db1_i_boreChildrenBd_bore_1_rdata;
  logic [71:0] db1_s0_boreChildrenBd_bore_1_rdata = '0, db1_s1_boreChildrenBd_bore_1_rdata = '0;
  logic db1_boreChildrenBd_bore_1_ack;
  logic db1_boreChildrenBd_bore_1_selectedOH;
  logic [2:0] db1_boreChildrenBd_bore_1_array;
  logic [8:0] db1_boreChildrenBd_bore_2_addr;
  logic [8:0] db1_boreChildrenBd_bore_2_addr_rd;
  logic [71:0] db1_boreChildrenBd_bore_2_wdata;
  logic db1_boreChildrenBd_bore_2_wmask;
  logic db1_boreChildrenBd_bore_2_re;
  logic db1_boreChildrenBd_bore_2_we;
  wire  [71:0] db1_g_boreChildrenBd_bore_2_rdata, db1_i_boreChildrenBd_bore_2_rdata;
  logic [71:0] db1_s0_boreChildrenBd_bore_2_rdata = '0, db1_s1_boreChildrenBd_bore_2_rdata = '0;
  logic db1_boreChildrenBd_bore_2_ack;
  logic db1_boreChildrenBd_bore_2_selectedOH;
  logic [2:0] db1_boreChildrenBd_bore_2_array;
  logic [8:0] db1_boreChildrenBd_bore_3_addr;
  logic [8:0] db1_boreChildrenBd_bore_3_addr_rd;
  logic [71:0] db1_boreChildrenBd_bore_3_wdata;
  logic db1_boreChildrenBd_bore_3_wmask;
  logic db1_boreChildrenBd_bore_3_re;
  logic db1_boreChildrenBd_bore_3_we;
  wire  [71:0] db1_g_boreChildrenBd_bore_3_rdata, db1_i_boreChildrenBd_bore_3_rdata;
  logic [71:0] db1_s0_boreChildrenBd_bore_3_rdata = '0, db1_s1_boreChildrenBd_bore_3_rdata = '0;
  logic db1_boreChildrenBd_bore_3_ack;
  logic db1_boreChildrenBd_bore_3_selectedOH;
  logic [2:0] db1_boreChildrenBd_bore_3_array;
  logic db1_sigFromSrams_bore_ram_hold;
  logic db1_sigFromSrams_bore_ram_bypass;
  logic db1_sigFromSrams_bore_ram_bp_clken;
  logic db1_sigFromSrams_bore_ram_aux_clk;
  logic db1_sigFromSrams_bore_ram_aux_ckbp;
  logic db1_sigFromSrams_bore_ram_mcp_hold;
  logic db1_sigFromSrams_bore_cgen;
  logic db1_sigFromSrams_bore_1_ram_hold;
  logic db1_sigFromSrams_bore_1_ram_bypass;
  logic db1_sigFromSrams_bore_1_ram_bp_clken;
  logic db1_sigFromSrams_bore_1_ram_aux_clk;
  logic db1_sigFromSrams_bore_1_ram_aux_ckbp;
  logic db1_sigFromSrams_bore_1_ram_mcp_hold;
  logic db1_sigFromSrams_bore_1_cgen;
  logic db1_sigFromSrams_bore_2_ram_hold;
  logic db1_sigFromSrams_bore_2_ram_bypass;
  logic db1_sigFromSrams_bore_2_ram_bp_clken;
  logic db1_sigFromSrams_bore_2_ram_aux_clk;
  logic db1_sigFromSrams_bore_2_ram_aux_ckbp;
  logic db1_sigFromSrams_bore_2_ram_mcp_hold;
  logic db1_sigFromSrams_bore_2_cgen;
  logic db1_sigFromSrams_bore_3_ram_hold;
  logic db1_sigFromSrams_bore_3_ram_bypass;
  logic db1_sigFromSrams_bore_3_ram_bp_clken;
  logic db1_sigFromSrams_bore_3_ram_aux_clk;
  logic db1_sigFromSrams_bore_3_ram_aux_ckbp;
  logic db1_sigFromSrams_bore_3_ram_mcp_hold;
  logic db1_sigFromSrams_bore_3_cgen;
  int db1_cov_multi_way_write = 0;
  int db1_cov_read = 0;
  int db1_cov_mbist_we = 0;
  logic [1:0] db1_armed = '0;
  int db1_armed_at = -1;
  DataSRAMBank_1 db1_u_gold (
    .clock(clk),
    .reset(db1_reset),
    .io_w_en(db1_io_w_en),
    .io_w_addr(db1_io_w_addr),
    .io_w_way_en(db1_io_w_way_en),
    .io_w_data(db1_io_w_data),
    .io_r_en(db1_io_r_en),
    .io_r_addr(db1_io_r_addr),
    .io_r_data_0(db1_g_io_r_data_0),
    .io_r_data_1(db1_g_io_r_data_1),
    .io_r_data_2(db1_g_io_r_data_2),
    .io_r_data_3(db1_g_io_r_data_3),
    .boreChildrenBd_bore_addr(db1_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db1_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db1_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db1_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db1_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db1_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db1_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db1_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db1_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db1_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db1_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db1_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db1_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db1_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db1_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db1_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db1_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db1_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db1_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db1_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db1_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db1_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db1_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db1_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db1_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db1_g_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db1_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db1_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db1_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db1_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db1_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db1_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db1_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db1_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db1_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db1_g_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db1_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db1_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db1_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db1_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db1_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db1_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db1_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db1_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db1_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db1_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db1_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db1_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db1_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db1_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db1_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db1_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db1_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db1_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db1_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db1_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db1_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db1_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db1_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db1_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db1_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db1_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db1_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db1_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db1_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db1_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db1_sigFromSrams_bore_3_cgen)
  );
  DataSRAMBank_1_xs db1_u_impl (
    .clock(clk),
    .reset(db1_reset),
    .io_w_en(db1_io_w_en),
    .io_w_addr(db1_io_w_addr),
    .io_w_way_en(db1_io_w_way_en),
    .io_w_data(db1_io_w_data),
    .io_r_en(db1_io_r_en),
    .io_r_addr(db1_io_r_addr),
    .io_r_data_0(db1_i_io_r_data_0),
    .io_r_data_1(db1_i_io_r_data_1),
    .io_r_data_2(db1_i_io_r_data_2),
    .io_r_data_3(db1_i_io_r_data_3),
    .boreChildrenBd_bore_addr(db1_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db1_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db1_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db1_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db1_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db1_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db1_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db1_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db1_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db1_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db1_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db1_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db1_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db1_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db1_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db1_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db1_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db1_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db1_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db1_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db1_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db1_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db1_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db1_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db1_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db1_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db1_i_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db1_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db1_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db1_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db1_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db1_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db1_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db1_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db1_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db1_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db1_i_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db1_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db1_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db1_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db1_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db1_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db1_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db1_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db1_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db1_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db1_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db1_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db1_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db1_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db1_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db1_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db1_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db1_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db1_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db1_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db1_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db1_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db1_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db1_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db1_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db1_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db1_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db1_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db1_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db1_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db1_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db1_sigFromSrams_bore_3_cgen)
  );

  // ================= DataSRAMBank_2 =================
  int unsigned db2_mode = 0;
  logic db2_reset;
  logic db2_io_w_en;
  logic [7:0] db2_io_w_addr;
  logic [3:0] db2_io_w_way_en;
  logic [71:0] db2_io_w_data;
  logic db2_io_r_en;
  logic [7:0] db2_io_r_addr;
  wire  [71:0] db2_g_io_r_data_0, db2_i_io_r_data_0;
  logic [71:0] db2_s0_io_r_data_0 = '0, db2_s1_io_r_data_0 = '0;
  wire  [71:0] db2_g_io_r_data_1, db2_i_io_r_data_1;
  logic [71:0] db2_s0_io_r_data_1 = '0, db2_s1_io_r_data_1 = '0;
  wire  [71:0] db2_g_io_r_data_2, db2_i_io_r_data_2;
  logic [71:0] db2_s0_io_r_data_2 = '0, db2_s1_io_r_data_2 = '0;
  wire  [71:0] db2_g_io_r_data_3, db2_i_io_r_data_3;
  logic [71:0] db2_s0_io_r_data_3 = '0, db2_s1_io_r_data_3 = '0;
  logic [8:0] db2_boreChildrenBd_bore_addr;
  logic [8:0] db2_boreChildrenBd_bore_addr_rd;
  logic [71:0] db2_boreChildrenBd_bore_wdata;
  logic db2_boreChildrenBd_bore_wmask;
  logic db2_boreChildrenBd_bore_re;
  logic db2_boreChildrenBd_bore_we;
  wire  [71:0] db2_g_boreChildrenBd_bore_rdata, db2_i_boreChildrenBd_bore_rdata;
  logic [71:0] db2_s0_boreChildrenBd_bore_rdata = '0, db2_s1_boreChildrenBd_bore_rdata = '0;
  logic db2_boreChildrenBd_bore_ack;
  logic db2_boreChildrenBd_bore_selectedOH;
  logic [3:0] db2_boreChildrenBd_bore_array;
  logic [8:0] db2_boreChildrenBd_bore_1_addr;
  logic [8:0] db2_boreChildrenBd_bore_1_addr_rd;
  logic [71:0] db2_boreChildrenBd_bore_1_wdata;
  logic db2_boreChildrenBd_bore_1_wmask;
  logic db2_boreChildrenBd_bore_1_re;
  logic db2_boreChildrenBd_bore_1_we;
  wire  [71:0] db2_g_boreChildrenBd_bore_1_rdata, db2_i_boreChildrenBd_bore_1_rdata;
  logic [71:0] db2_s0_boreChildrenBd_bore_1_rdata = '0, db2_s1_boreChildrenBd_bore_1_rdata = '0;
  logic db2_boreChildrenBd_bore_1_ack;
  logic db2_boreChildrenBd_bore_1_selectedOH;
  logic [3:0] db2_boreChildrenBd_bore_1_array;
  logic [8:0] db2_boreChildrenBd_bore_2_addr;
  logic [8:0] db2_boreChildrenBd_bore_2_addr_rd;
  logic [71:0] db2_boreChildrenBd_bore_2_wdata;
  logic db2_boreChildrenBd_bore_2_wmask;
  logic db2_boreChildrenBd_bore_2_re;
  logic db2_boreChildrenBd_bore_2_we;
  wire  [71:0] db2_g_boreChildrenBd_bore_2_rdata, db2_i_boreChildrenBd_bore_2_rdata;
  logic [71:0] db2_s0_boreChildrenBd_bore_2_rdata = '0, db2_s1_boreChildrenBd_bore_2_rdata = '0;
  logic db2_boreChildrenBd_bore_2_ack;
  logic db2_boreChildrenBd_bore_2_selectedOH;
  logic [3:0] db2_boreChildrenBd_bore_2_array;
  logic [8:0] db2_boreChildrenBd_bore_3_addr;
  logic [8:0] db2_boreChildrenBd_bore_3_addr_rd;
  logic [71:0] db2_boreChildrenBd_bore_3_wdata;
  logic db2_boreChildrenBd_bore_3_wmask;
  logic db2_boreChildrenBd_bore_3_re;
  logic db2_boreChildrenBd_bore_3_we;
  wire  [71:0] db2_g_boreChildrenBd_bore_3_rdata, db2_i_boreChildrenBd_bore_3_rdata;
  logic [71:0] db2_s0_boreChildrenBd_bore_3_rdata = '0, db2_s1_boreChildrenBd_bore_3_rdata = '0;
  logic db2_boreChildrenBd_bore_3_ack;
  logic db2_boreChildrenBd_bore_3_selectedOH;
  logic [3:0] db2_boreChildrenBd_bore_3_array;
  logic db2_sigFromSrams_bore_ram_hold;
  logic db2_sigFromSrams_bore_ram_bypass;
  logic db2_sigFromSrams_bore_ram_bp_clken;
  logic db2_sigFromSrams_bore_ram_aux_clk;
  logic db2_sigFromSrams_bore_ram_aux_ckbp;
  logic db2_sigFromSrams_bore_ram_mcp_hold;
  logic db2_sigFromSrams_bore_cgen;
  logic db2_sigFromSrams_bore_1_ram_hold;
  logic db2_sigFromSrams_bore_1_ram_bypass;
  logic db2_sigFromSrams_bore_1_ram_bp_clken;
  logic db2_sigFromSrams_bore_1_ram_aux_clk;
  logic db2_sigFromSrams_bore_1_ram_aux_ckbp;
  logic db2_sigFromSrams_bore_1_ram_mcp_hold;
  logic db2_sigFromSrams_bore_1_cgen;
  logic db2_sigFromSrams_bore_2_ram_hold;
  logic db2_sigFromSrams_bore_2_ram_bypass;
  logic db2_sigFromSrams_bore_2_ram_bp_clken;
  logic db2_sigFromSrams_bore_2_ram_aux_clk;
  logic db2_sigFromSrams_bore_2_ram_aux_ckbp;
  logic db2_sigFromSrams_bore_2_ram_mcp_hold;
  logic db2_sigFromSrams_bore_2_cgen;
  logic db2_sigFromSrams_bore_3_ram_hold;
  logic db2_sigFromSrams_bore_3_ram_bypass;
  logic db2_sigFromSrams_bore_3_ram_bp_clken;
  logic db2_sigFromSrams_bore_3_ram_aux_clk;
  logic db2_sigFromSrams_bore_3_ram_aux_ckbp;
  logic db2_sigFromSrams_bore_3_ram_mcp_hold;
  logic db2_sigFromSrams_bore_3_cgen;
  int db2_cov_multi_way_write = 0;
  int db2_cov_read = 0;
  int db2_cov_mbist_we = 0;
  logic [1:0] db2_armed = '0;
  int db2_armed_at = -1;
  DataSRAMBank_2 db2_u_gold (
    .clock(clk),
    .reset(db2_reset),
    .io_w_en(db2_io_w_en),
    .io_w_addr(db2_io_w_addr),
    .io_w_way_en(db2_io_w_way_en),
    .io_w_data(db2_io_w_data),
    .io_r_en(db2_io_r_en),
    .io_r_addr(db2_io_r_addr),
    .io_r_data_0(db2_g_io_r_data_0),
    .io_r_data_1(db2_g_io_r_data_1),
    .io_r_data_2(db2_g_io_r_data_2),
    .io_r_data_3(db2_g_io_r_data_3),
    .boreChildrenBd_bore_addr(db2_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db2_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db2_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db2_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db2_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db2_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db2_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db2_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db2_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db2_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db2_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db2_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db2_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db2_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db2_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db2_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db2_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db2_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db2_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db2_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db2_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db2_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db2_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db2_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db2_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db2_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db2_g_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db2_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db2_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db2_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db2_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db2_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db2_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db2_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db2_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db2_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db2_g_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db2_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db2_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db2_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db2_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db2_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db2_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db2_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db2_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db2_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db2_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db2_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db2_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db2_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db2_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db2_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db2_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db2_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db2_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db2_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db2_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db2_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db2_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db2_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db2_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db2_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db2_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db2_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db2_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db2_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db2_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db2_sigFromSrams_bore_3_cgen)
  );
  DataSRAMBank_2_xs db2_u_impl (
    .clock(clk),
    .reset(db2_reset),
    .io_w_en(db2_io_w_en),
    .io_w_addr(db2_io_w_addr),
    .io_w_way_en(db2_io_w_way_en),
    .io_w_data(db2_io_w_data),
    .io_r_en(db2_io_r_en),
    .io_r_addr(db2_io_r_addr),
    .io_r_data_0(db2_i_io_r_data_0),
    .io_r_data_1(db2_i_io_r_data_1),
    .io_r_data_2(db2_i_io_r_data_2),
    .io_r_data_3(db2_i_io_r_data_3),
    .boreChildrenBd_bore_addr(db2_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db2_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db2_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db2_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db2_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db2_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db2_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db2_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db2_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db2_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db2_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db2_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db2_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db2_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db2_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db2_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db2_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db2_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db2_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db2_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db2_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db2_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db2_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db2_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db2_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db2_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db2_i_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db2_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db2_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db2_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db2_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db2_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db2_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db2_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db2_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db2_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db2_i_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db2_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db2_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db2_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db2_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db2_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db2_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db2_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db2_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db2_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db2_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db2_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db2_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db2_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db2_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db2_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db2_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db2_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db2_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db2_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db2_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db2_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db2_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db2_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db2_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db2_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db2_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db2_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db2_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db2_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db2_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db2_sigFromSrams_bore_3_cgen)
  );

  // ================= DataSRAMBank_4 =================
  int unsigned db4_mode = 0;
  logic db4_reset;
  logic db4_io_w_en;
  logic [7:0] db4_io_w_addr;
  logic [3:0] db4_io_w_way_en;
  logic [71:0] db4_io_w_data;
  logic db4_io_r_en;
  logic [7:0] db4_io_r_addr;
  wire  [71:0] db4_g_io_r_data_0, db4_i_io_r_data_0;
  logic [71:0] db4_s0_io_r_data_0 = '0, db4_s1_io_r_data_0 = '0;
  wire  [71:0] db4_g_io_r_data_1, db4_i_io_r_data_1;
  logic [71:0] db4_s0_io_r_data_1 = '0, db4_s1_io_r_data_1 = '0;
  wire  [71:0] db4_g_io_r_data_2, db4_i_io_r_data_2;
  logic [71:0] db4_s0_io_r_data_2 = '0, db4_s1_io_r_data_2 = '0;
  wire  [71:0] db4_g_io_r_data_3, db4_i_io_r_data_3;
  logic [71:0] db4_s0_io_r_data_3 = '0, db4_s1_io_r_data_3 = '0;
  logic [8:0] db4_boreChildrenBd_bore_addr;
  logic [8:0] db4_boreChildrenBd_bore_addr_rd;
  logic [71:0] db4_boreChildrenBd_bore_wdata;
  logic db4_boreChildrenBd_bore_wmask;
  logic db4_boreChildrenBd_bore_re;
  logic db4_boreChildrenBd_bore_we;
  wire  [71:0] db4_g_boreChildrenBd_bore_rdata, db4_i_boreChildrenBd_bore_rdata;
  logic [71:0] db4_s0_boreChildrenBd_bore_rdata = '0, db4_s1_boreChildrenBd_bore_rdata = '0;
  logic db4_boreChildrenBd_bore_ack;
  logic db4_boreChildrenBd_bore_selectedOH;
  logic [4:0] db4_boreChildrenBd_bore_array;
  logic [8:0] db4_boreChildrenBd_bore_1_addr;
  logic [8:0] db4_boreChildrenBd_bore_1_addr_rd;
  logic [71:0] db4_boreChildrenBd_bore_1_wdata;
  logic db4_boreChildrenBd_bore_1_wmask;
  logic db4_boreChildrenBd_bore_1_re;
  logic db4_boreChildrenBd_bore_1_we;
  wire  [71:0] db4_g_boreChildrenBd_bore_1_rdata, db4_i_boreChildrenBd_bore_1_rdata;
  logic [71:0] db4_s0_boreChildrenBd_bore_1_rdata = '0, db4_s1_boreChildrenBd_bore_1_rdata = '0;
  logic db4_boreChildrenBd_bore_1_ack;
  logic db4_boreChildrenBd_bore_1_selectedOH;
  logic [4:0] db4_boreChildrenBd_bore_1_array;
  logic [8:0] db4_boreChildrenBd_bore_2_addr;
  logic [8:0] db4_boreChildrenBd_bore_2_addr_rd;
  logic [71:0] db4_boreChildrenBd_bore_2_wdata;
  logic db4_boreChildrenBd_bore_2_wmask;
  logic db4_boreChildrenBd_bore_2_re;
  logic db4_boreChildrenBd_bore_2_we;
  wire  [71:0] db4_g_boreChildrenBd_bore_2_rdata, db4_i_boreChildrenBd_bore_2_rdata;
  logic [71:0] db4_s0_boreChildrenBd_bore_2_rdata = '0, db4_s1_boreChildrenBd_bore_2_rdata = '0;
  logic db4_boreChildrenBd_bore_2_ack;
  logic db4_boreChildrenBd_bore_2_selectedOH;
  logic [4:0] db4_boreChildrenBd_bore_2_array;
  logic [8:0] db4_boreChildrenBd_bore_3_addr;
  logic [8:0] db4_boreChildrenBd_bore_3_addr_rd;
  logic [71:0] db4_boreChildrenBd_bore_3_wdata;
  logic db4_boreChildrenBd_bore_3_wmask;
  logic db4_boreChildrenBd_bore_3_re;
  logic db4_boreChildrenBd_bore_3_we;
  wire  [71:0] db4_g_boreChildrenBd_bore_3_rdata, db4_i_boreChildrenBd_bore_3_rdata;
  logic [71:0] db4_s0_boreChildrenBd_bore_3_rdata = '0, db4_s1_boreChildrenBd_bore_3_rdata = '0;
  logic db4_boreChildrenBd_bore_3_ack;
  logic db4_boreChildrenBd_bore_3_selectedOH;
  logic [4:0] db4_boreChildrenBd_bore_3_array;
  logic db4_sigFromSrams_bore_ram_hold;
  logic db4_sigFromSrams_bore_ram_bypass;
  logic db4_sigFromSrams_bore_ram_bp_clken;
  logic db4_sigFromSrams_bore_ram_aux_clk;
  logic db4_sigFromSrams_bore_ram_aux_ckbp;
  logic db4_sigFromSrams_bore_ram_mcp_hold;
  logic db4_sigFromSrams_bore_cgen;
  logic db4_sigFromSrams_bore_1_ram_hold;
  logic db4_sigFromSrams_bore_1_ram_bypass;
  logic db4_sigFromSrams_bore_1_ram_bp_clken;
  logic db4_sigFromSrams_bore_1_ram_aux_clk;
  logic db4_sigFromSrams_bore_1_ram_aux_ckbp;
  logic db4_sigFromSrams_bore_1_ram_mcp_hold;
  logic db4_sigFromSrams_bore_1_cgen;
  logic db4_sigFromSrams_bore_2_ram_hold;
  logic db4_sigFromSrams_bore_2_ram_bypass;
  logic db4_sigFromSrams_bore_2_ram_bp_clken;
  logic db4_sigFromSrams_bore_2_ram_aux_clk;
  logic db4_sigFromSrams_bore_2_ram_aux_ckbp;
  logic db4_sigFromSrams_bore_2_ram_mcp_hold;
  logic db4_sigFromSrams_bore_2_cgen;
  logic db4_sigFromSrams_bore_3_ram_hold;
  logic db4_sigFromSrams_bore_3_ram_bypass;
  logic db4_sigFromSrams_bore_3_ram_bp_clken;
  logic db4_sigFromSrams_bore_3_ram_aux_clk;
  logic db4_sigFromSrams_bore_3_ram_aux_ckbp;
  logic db4_sigFromSrams_bore_3_ram_mcp_hold;
  logic db4_sigFromSrams_bore_3_cgen;
  int db4_cov_multi_way_write = 0;
  int db4_cov_read = 0;
  int db4_cov_mbist_we = 0;
  logic [1:0] db4_armed = '0;
  int db4_armed_at = -1;
  DataSRAMBank_4 db4_u_gold (
    .clock(clk),
    .reset(db4_reset),
    .io_w_en(db4_io_w_en),
    .io_w_addr(db4_io_w_addr),
    .io_w_way_en(db4_io_w_way_en),
    .io_w_data(db4_io_w_data),
    .io_r_en(db4_io_r_en),
    .io_r_addr(db4_io_r_addr),
    .io_r_data_0(db4_g_io_r_data_0),
    .io_r_data_1(db4_g_io_r_data_1),
    .io_r_data_2(db4_g_io_r_data_2),
    .io_r_data_3(db4_g_io_r_data_3),
    .boreChildrenBd_bore_addr(db4_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db4_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db4_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db4_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db4_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db4_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db4_g_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db4_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db4_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db4_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db4_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db4_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db4_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db4_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db4_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db4_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db4_g_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db4_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db4_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db4_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db4_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db4_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db4_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db4_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db4_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db4_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db4_g_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db4_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db4_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db4_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db4_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db4_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db4_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db4_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db4_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db4_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db4_g_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db4_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db4_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db4_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db4_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db4_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db4_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db4_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db4_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db4_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db4_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db4_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db4_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db4_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db4_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db4_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db4_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db4_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db4_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db4_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db4_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db4_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db4_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db4_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db4_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db4_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db4_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db4_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db4_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db4_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db4_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db4_sigFromSrams_bore_3_cgen)
  );
  DataSRAMBank_4_xs db4_u_impl (
    .clock(clk),
    .reset(db4_reset),
    .io_w_en(db4_io_w_en),
    .io_w_addr(db4_io_w_addr),
    .io_w_way_en(db4_io_w_way_en),
    .io_w_data(db4_io_w_data),
    .io_r_en(db4_io_r_en),
    .io_r_addr(db4_io_r_addr),
    .io_r_data_0(db4_i_io_r_data_0),
    .io_r_data_1(db4_i_io_r_data_1),
    .io_r_data_2(db4_i_io_r_data_2),
    .io_r_data_3(db4_i_io_r_data_3),
    .boreChildrenBd_bore_addr(db4_boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(db4_boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(db4_boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(db4_boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(db4_boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(db4_boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(db4_i_boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(db4_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(db4_boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(db4_boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(db4_boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(db4_boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(db4_boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(db4_boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(db4_boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(db4_boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(db4_i_boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(db4_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(db4_boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(db4_boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_2_addr(db4_boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_addr_rd(db4_boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_wdata(db4_boreChildrenBd_bore_2_wdata),
    .boreChildrenBd_bore_2_wmask(db4_boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_2_re(db4_boreChildrenBd_bore_2_re),
    .boreChildrenBd_bore_2_we(db4_boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_2_rdata(db4_i_boreChildrenBd_bore_2_rdata),
    .boreChildrenBd_bore_2_ack(db4_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_selectedOH(db4_boreChildrenBd_bore_2_selectedOH),
    .boreChildrenBd_bore_2_array(db4_boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_3_addr(db4_boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_addr_rd(db4_boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_wdata(db4_boreChildrenBd_bore_3_wdata),
    .boreChildrenBd_bore_3_wmask(db4_boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_3_re(db4_boreChildrenBd_bore_3_re),
    .boreChildrenBd_bore_3_we(db4_boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_3_rdata(db4_i_boreChildrenBd_bore_3_rdata),
    .boreChildrenBd_bore_3_ack(db4_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_selectedOH(db4_boreChildrenBd_bore_3_selectedOH),
    .boreChildrenBd_bore_3_array(db4_boreChildrenBd_bore_3_array),
    .sigFromSrams_bore_ram_hold(db4_sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(db4_sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(db4_sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(db4_sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(db4_sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(db4_sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(db4_sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(db4_sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(db4_sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(db4_sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(db4_sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(db4_sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(db4_sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(db4_sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(db4_sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(db4_sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(db4_sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(db4_sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(db4_sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(db4_sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(db4_sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(db4_sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(db4_sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(db4_sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(db4_sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(db4_sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(db4_sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(db4_sigFromSrams_bore_3_cgen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) db0_mode = $urandom_range(0, 15);
      db0_io_w_en = 1'($urandom);
      db0_io_w_addr = 8'($urandom);
      db0_io_w_way_en = 4'($urandom);
      db0_io_w_data = 72'({$urandom, $urandom, $urandom});
      db0_io_r_en = 1'($urandom);
      db0_io_r_addr = 8'($urandom);
      db0_boreChildrenBd_bore_addr = 9'($urandom);
      db0_boreChildrenBd_bore_addr_rd = 9'($urandom);
      db0_boreChildrenBd_bore_wdata = 72'({$urandom, $urandom, $urandom});
      db0_boreChildrenBd_bore_wmask = 1'($urandom);
      db0_boreChildrenBd_bore_re = 1'($urandom);
      db0_boreChildrenBd_bore_we = 1'($urandom);
      db0_boreChildrenBd_bore_ack = 1'($urandom);
      db0_boreChildrenBd_bore_selectedOH = 1'($urandom);
      db0_boreChildrenBd_bore_array = 1'($urandom);
      db0_boreChildrenBd_bore_1_addr = 9'($urandom);
      db0_boreChildrenBd_bore_1_addr_rd = 9'($urandom);
      db0_boreChildrenBd_bore_1_wdata = 72'({$urandom, $urandom, $urandom});
      db0_boreChildrenBd_bore_1_wmask = 1'($urandom);
      db0_boreChildrenBd_bore_1_re = 1'($urandom);
      db0_boreChildrenBd_bore_1_we = 1'($urandom);
      db0_boreChildrenBd_bore_1_ack = 1'($urandom);
      db0_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      db0_boreChildrenBd_bore_1_array = 1'($urandom);
      db0_boreChildrenBd_bore_2_addr = 9'($urandom);
      db0_boreChildrenBd_bore_2_addr_rd = 9'($urandom);
      db0_boreChildrenBd_bore_2_wdata = 72'({$urandom, $urandom, $urandom});
      db0_boreChildrenBd_bore_2_wmask = 1'($urandom);
      db0_boreChildrenBd_bore_2_re = 1'($urandom);
      db0_boreChildrenBd_bore_2_we = 1'($urandom);
      db0_boreChildrenBd_bore_2_ack = 1'($urandom);
      db0_boreChildrenBd_bore_2_selectedOH = 1'($urandom);
      db0_boreChildrenBd_bore_2_array = 2'($urandom);
      db0_boreChildrenBd_bore_3_addr = 9'($urandom);
      db0_boreChildrenBd_bore_3_addr_rd = 9'($urandom);
      db0_boreChildrenBd_bore_3_wdata = 72'({$urandom, $urandom, $urandom});
      db0_boreChildrenBd_bore_3_wmask = 1'($urandom);
      db0_boreChildrenBd_bore_3_re = 1'($urandom);
      db0_boreChildrenBd_bore_3_we = 1'($urandom);
      db0_boreChildrenBd_bore_3_ack = 1'($urandom);
      db0_boreChildrenBd_bore_3_selectedOH = 1'($urandom);
      db0_boreChildrenBd_bore_3_array = 2'($urandom);
      db0_sigFromSrams_bore_ram_hold = 1'($urandom);
      db0_sigFromSrams_bore_ram_bypass = 1'($urandom);
      db0_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      db0_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      db0_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      db0_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      db0_sigFromSrams_bore_cgen = 1'($urandom);
      db0_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      db0_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      db0_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      db0_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      db0_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      db0_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      db0_sigFromSrams_bore_1_cgen = 1'($urandom);
      db0_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      db0_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      db0_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      db0_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      db0_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      db0_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      db0_sigFromSrams_bore_2_cgen = 1'($urandom);
      db0_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      db0_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      db0_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      db0_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      db0_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      db0_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      db0_sigFromSrams_bore_3_cgen = 1'($urandom);
      db0_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_db0
        db0_io_r_addr = 8'($urandom_range(0, 7));
        db0_io_w_addr = 8'($urandom_range(0, 7));
        if ($urandom_range(0, 3) != 0) db0_io_w_way_en = 4'b0001 << $urandom_range(0, 3);
        if (cyc < 400) begin db0_io_w_en = 1'b1; db0_io_w_way_en = 4'b0001 << (cyc % 4); db0_io_w_addr = 8'((cyc / 4) % 8); end
        if (db0_mode < 12 || cyc < 400) begin
          db0_boreChildrenBd_bore_addr = '0;
          db0_boreChildrenBd_bore_addr_rd = '0;
          db0_boreChildrenBd_bore_wdata = '0;
          db0_boreChildrenBd_bore_wmask = '0;
          db0_boreChildrenBd_bore_re = '0;
          db0_boreChildrenBd_bore_we = '0;
          db0_boreChildrenBd_bore_ack = '0;
          db0_boreChildrenBd_bore_selectedOH = '0;
          db0_boreChildrenBd_bore_array = '0;
          db0_boreChildrenBd_bore_1_addr = '0;
          db0_boreChildrenBd_bore_1_addr_rd = '0;
          db0_boreChildrenBd_bore_1_wdata = '0;
          db0_boreChildrenBd_bore_1_wmask = '0;
          db0_boreChildrenBd_bore_1_re = '0;
          db0_boreChildrenBd_bore_1_we = '0;
          db0_boreChildrenBd_bore_1_ack = '0;
          db0_boreChildrenBd_bore_1_selectedOH = '0;
          db0_boreChildrenBd_bore_1_array = '0;
          db0_boreChildrenBd_bore_2_addr = '0;
          db0_boreChildrenBd_bore_2_addr_rd = '0;
          db0_boreChildrenBd_bore_2_wdata = '0;
          db0_boreChildrenBd_bore_2_wmask = '0;
          db0_boreChildrenBd_bore_2_re = '0;
          db0_boreChildrenBd_bore_2_we = '0;
          db0_boreChildrenBd_bore_2_ack = '0;
          db0_boreChildrenBd_bore_2_selectedOH = '0;
          db0_boreChildrenBd_bore_2_array = '0;
          db0_boreChildrenBd_bore_3_addr = '0;
          db0_boreChildrenBd_bore_3_addr_rd = '0;
          db0_boreChildrenBd_bore_3_wdata = '0;
          db0_boreChildrenBd_bore_3_wmask = '0;
          db0_boreChildrenBd_bore_3_re = '0;
          db0_boreChildrenBd_bore_3_we = '0;
          db0_boreChildrenBd_bore_3_ack = '0;
          db0_boreChildrenBd_bore_3_selectedOH = '0;
          db0_boreChildrenBd_bore_3_array = '0;
          db0_sigFromSrams_bore_ram_hold = '0;
          db0_sigFromSrams_bore_ram_bypass = '0;
          db0_sigFromSrams_bore_ram_bp_clken = '0;
          db0_sigFromSrams_bore_ram_aux_clk = '0;
          db0_sigFromSrams_bore_ram_aux_ckbp = '0;
          db0_sigFromSrams_bore_ram_mcp_hold = '0;
          db0_sigFromSrams_bore_cgen = '0;
          db0_sigFromSrams_bore_1_ram_hold = '0;
          db0_sigFromSrams_bore_1_ram_bypass = '0;
          db0_sigFromSrams_bore_1_ram_bp_clken = '0;
          db0_sigFromSrams_bore_1_ram_aux_clk = '0;
          db0_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          db0_sigFromSrams_bore_1_ram_mcp_hold = '0;
          db0_sigFromSrams_bore_1_cgen = '0;
          db0_sigFromSrams_bore_2_ram_hold = '0;
          db0_sigFromSrams_bore_2_ram_bypass = '0;
          db0_sigFromSrams_bore_2_ram_bp_clken = '0;
          db0_sigFromSrams_bore_2_ram_aux_clk = '0;
          db0_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          db0_sigFromSrams_bore_2_ram_mcp_hold = '0;
          db0_sigFromSrams_bore_2_cgen = '0;
          db0_sigFromSrams_bore_3_ram_hold = '0;
          db0_sigFromSrams_bore_3_ram_bypass = '0;
          db0_sigFromSrams_bore_3_ram_bp_clken = '0;
          db0_sigFromSrams_bore_3_ram_aux_clk = '0;
          db0_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          db0_sigFromSrams_bore_3_ram_mcp_hold = '0;
          db0_sigFromSrams_bore_3_cgen = '0;
        end
        db0_boreChildrenBd_bore_addr = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_addr_rd = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_1_addr = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_1_addr_rd = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_2_addr = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_2_addr_rd = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_3_addr = 9'($urandom_range(0, 7));
        db0_boreChildrenBd_bore_3_addr_rd = 9'($urandom_range(0, 7));
      end
      if (cyc % 3000 == 0) db1_mode = $urandom_range(0, 15);
      db1_io_w_en = 1'($urandom);
      db1_io_w_addr = 8'($urandom);
      db1_io_w_way_en = 4'($urandom);
      db1_io_w_data = 72'({$urandom, $urandom, $urandom});
      db1_io_r_en = 1'($urandom);
      db1_io_r_addr = 8'($urandom);
      db1_boreChildrenBd_bore_addr = 9'($urandom);
      db1_boreChildrenBd_bore_addr_rd = 9'($urandom);
      db1_boreChildrenBd_bore_wdata = 72'({$urandom, $urandom, $urandom});
      db1_boreChildrenBd_bore_wmask = 1'($urandom);
      db1_boreChildrenBd_bore_re = 1'($urandom);
      db1_boreChildrenBd_bore_we = 1'($urandom);
      db1_boreChildrenBd_bore_ack = 1'($urandom);
      db1_boreChildrenBd_bore_selectedOH = 1'($urandom);
      db1_boreChildrenBd_bore_array = 3'($urandom);
      db1_boreChildrenBd_bore_1_addr = 9'($urandom);
      db1_boreChildrenBd_bore_1_addr_rd = 9'($urandom);
      db1_boreChildrenBd_bore_1_wdata = 72'({$urandom, $urandom, $urandom});
      db1_boreChildrenBd_bore_1_wmask = 1'($urandom);
      db1_boreChildrenBd_bore_1_re = 1'($urandom);
      db1_boreChildrenBd_bore_1_we = 1'($urandom);
      db1_boreChildrenBd_bore_1_ack = 1'($urandom);
      db1_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      db1_boreChildrenBd_bore_1_array = 3'($urandom);
      db1_boreChildrenBd_bore_2_addr = 9'($urandom);
      db1_boreChildrenBd_bore_2_addr_rd = 9'($urandom);
      db1_boreChildrenBd_bore_2_wdata = 72'({$urandom, $urandom, $urandom});
      db1_boreChildrenBd_bore_2_wmask = 1'($urandom);
      db1_boreChildrenBd_bore_2_re = 1'($urandom);
      db1_boreChildrenBd_bore_2_we = 1'($urandom);
      db1_boreChildrenBd_bore_2_ack = 1'($urandom);
      db1_boreChildrenBd_bore_2_selectedOH = 1'($urandom);
      db1_boreChildrenBd_bore_2_array = 3'($urandom);
      db1_boreChildrenBd_bore_3_addr = 9'($urandom);
      db1_boreChildrenBd_bore_3_addr_rd = 9'($urandom);
      db1_boreChildrenBd_bore_3_wdata = 72'({$urandom, $urandom, $urandom});
      db1_boreChildrenBd_bore_3_wmask = 1'($urandom);
      db1_boreChildrenBd_bore_3_re = 1'($urandom);
      db1_boreChildrenBd_bore_3_we = 1'($urandom);
      db1_boreChildrenBd_bore_3_ack = 1'($urandom);
      db1_boreChildrenBd_bore_3_selectedOH = 1'($urandom);
      db1_boreChildrenBd_bore_3_array = 3'($urandom);
      db1_sigFromSrams_bore_ram_hold = 1'($urandom);
      db1_sigFromSrams_bore_ram_bypass = 1'($urandom);
      db1_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      db1_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      db1_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      db1_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      db1_sigFromSrams_bore_cgen = 1'($urandom);
      db1_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      db1_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      db1_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      db1_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      db1_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      db1_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      db1_sigFromSrams_bore_1_cgen = 1'($urandom);
      db1_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      db1_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      db1_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      db1_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      db1_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      db1_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      db1_sigFromSrams_bore_2_cgen = 1'($urandom);
      db1_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      db1_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      db1_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      db1_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      db1_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      db1_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      db1_sigFromSrams_bore_3_cgen = 1'($urandom);
      db1_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_db1
        db1_io_r_addr = 8'($urandom_range(0, 7));
        db1_io_w_addr = 8'($urandom_range(0, 7));
        if ($urandom_range(0, 3) != 0) db1_io_w_way_en = 4'b0001 << $urandom_range(0, 3);
        if (cyc < 400) begin db1_io_w_en = 1'b1; db1_io_w_way_en = 4'b0001 << (cyc % 4); db1_io_w_addr = 8'((cyc / 4) % 8); end
        if (db1_mode < 12 || cyc < 400) begin
          db1_boreChildrenBd_bore_addr = '0;
          db1_boreChildrenBd_bore_addr_rd = '0;
          db1_boreChildrenBd_bore_wdata = '0;
          db1_boreChildrenBd_bore_wmask = '0;
          db1_boreChildrenBd_bore_re = '0;
          db1_boreChildrenBd_bore_we = '0;
          db1_boreChildrenBd_bore_ack = '0;
          db1_boreChildrenBd_bore_selectedOH = '0;
          db1_boreChildrenBd_bore_array = '0;
          db1_boreChildrenBd_bore_1_addr = '0;
          db1_boreChildrenBd_bore_1_addr_rd = '0;
          db1_boreChildrenBd_bore_1_wdata = '0;
          db1_boreChildrenBd_bore_1_wmask = '0;
          db1_boreChildrenBd_bore_1_re = '0;
          db1_boreChildrenBd_bore_1_we = '0;
          db1_boreChildrenBd_bore_1_ack = '0;
          db1_boreChildrenBd_bore_1_selectedOH = '0;
          db1_boreChildrenBd_bore_1_array = '0;
          db1_boreChildrenBd_bore_2_addr = '0;
          db1_boreChildrenBd_bore_2_addr_rd = '0;
          db1_boreChildrenBd_bore_2_wdata = '0;
          db1_boreChildrenBd_bore_2_wmask = '0;
          db1_boreChildrenBd_bore_2_re = '0;
          db1_boreChildrenBd_bore_2_we = '0;
          db1_boreChildrenBd_bore_2_ack = '0;
          db1_boreChildrenBd_bore_2_selectedOH = '0;
          db1_boreChildrenBd_bore_2_array = '0;
          db1_boreChildrenBd_bore_3_addr = '0;
          db1_boreChildrenBd_bore_3_addr_rd = '0;
          db1_boreChildrenBd_bore_3_wdata = '0;
          db1_boreChildrenBd_bore_3_wmask = '0;
          db1_boreChildrenBd_bore_3_re = '0;
          db1_boreChildrenBd_bore_3_we = '0;
          db1_boreChildrenBd_bore_3_ack = '0;
          db1_boreChildrenBd_bore_3_selectedOH = '0;
          db1_boreChildrenBd_bore_3_array = '0;
          db1_sigFromSrams_bore_ram_hold = '0;
          db1_sigFromSrams_bore_ram_bypass = '0;
          db1_sigFromSrams_bore_ram_bp_clken = '0;
          db1_sigFromSrams_bore_ram_aux_clk = '0;
          db1_sigFromSrams_bore_ram_aux_ckbp = '0;
          db1_sigFromSrams_bore_ram_mcp_hold = '0;
          db1_sigFromSrams_bore_cgen = '0;
          db1_sigFromSrams_bore_1_ram_hold = '0;
          db1_sigFromSrams_bore_1_ram_bypass = '0;
          db1_sigFromSrams_bore_1_ram_bp_clken = '0;
          db1_sigFromSrams_bore_1_ram_aux_clk = '0;
          db1_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          db1_sigFromSrams_bore_1_ram_mcp_hold = '0;
          db1_sigFromSrams_bore_1_cgen = '0;
          db1_sigFromSrams_bore_2_ram_hold = '0;
          db1_sigFromSrams_bore_2_ram_bypass = '0;
          db1_sigFromSrams_bore_2_ram_bp_clken = '0;
          db1_sigFromSrams_bore_2_ram_aux_clk = '0;
          db1_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          db1_sigFromSrams_bore_2_ram_mcp_hold = '0;
          db1_sigFromSrams_bore_2_cgen = '0;
          db1_sigFromSrams_bore_3_ram_hold = '0;
          db1_sigFromSrams_bore_3_ram_bypass = '0;
          db1_sigFromSrams_bore_3_ram_bp_clken = '0;
          db1_sigFromSrams_bore_3_ram_aux_clk = '0;
          db1_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          db1_sigFromSrams_bore_3_ram_mcp_hold = '0;
          db1_sigFromSrams_bore_3_cgen = '0;
        end
        db1_boreChildrenBd_bore_addr = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_addr_rd = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_1_addr = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_1_addr_rd = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_2_addr = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_2_addr_rd = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_3_addr = 9'($urandom_range(0, 7));
        db1_boreChildrenBd_bore_3_addr_rd = 9'($urandom_range(0, 7));
      end
      if (cyc % 3000 == 0) db2_mode = $urandom_range(0, 15);
      db2_io_w_en = 1'($urandom);
      db2_io_w_addr = 8'($urandom);
      db2_io_w_way_en = 4'($urandom);
      db2_io_w_data = 72'({$urandom, $urandom, $urandom});
      db2_io_r_en = 1'($urandom);
      db2_io_r_addr = 8'($urandom);
      db2_boreChildrenBd_bore_addr = 9'($urandom);
      db2_boreChildrenBd_bore_addr_rd = 9'($urandom);
      db2_boreChildrenBd_bore_wdata = 72'({$urandom, $urandom, $urandom});
      db2_boreChildrenBd_bore_wmask = 1'($urandom);
      db2_boreChildrenBd_bore_re = 1'($urandom);
      db2_boreChildrenBd_bore_we = 1'($urandom);
      db2_boreChildrenBd_bore_ack = 1'($urandom);
      db2_boreChildrenBd_bore_selectedOH = 1'($urandom);
      db2_boreChildrenBd_bore_array = 4'($urandom);
      db2_boreChildrenBd_bore_1_addr = 9'($urandom);
      db2_boreChildrenBd_bore_1_addr_rd = 9'($urandom);
      db2_boreChildrenBd_bore_1_wdata = 72'({$urandom, $urandom, $urandom});
      db2_boreChildrenBd_bore_1_wmask = 1'($urandom);
      db2_boreChildrenBd_bore_1_re = 1'($urandom);
      db2_boreChildrenBd_bore_1_we = 1'($urandom);
      db2_boreChildrenBd_bore_1_ack = 1'($urandom);
      db2_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      db2_boreChildrenBd_bore_1_array = 4'($urandom);
      db2_boreChildrenBd_bore_2_addr = 9'($urandom);
      db2_boreChildrenBd_bore_2_addr_rd = 9'($urandom);
      db2_boreChildrenBd_bore_2_wdata = 72'({$urandom, $urandom, $urandom});
      db2_boreChildrenBd_bore_2_wmask = 1'($urandom);
      db2_boreChildrenBd_bore_2_re = 1'($urandom);
      db2_boreChildrenBd_bore_2_we = 1'($urandom);
      db2_boreChildrenBd_bore_2_ack = 1'($urandom);
      db2_boreChildrenBd_bore_2_selectedOH = 1'($urandom);
      db2_boreChildrenBd_bore_2_array = 4'($urandom);
      db2_boreChildrenBd_bore_3_addr = 9'($urandom);
      db2_boreChildrenBd_bore_3_addr_rd = 9'($urandom);
      db2_boreChildrenBd_bore_3_wdata = 72'({$urandom, $urandom, $urandom});
      db2_boreChildrenBd_bore_3_wmask = 1'($urandom);
      db2_boreChildrenBd_bore_3_re = 1'($urandom);
      db2_boreChildrenBd_bore_3_we = 1'($urandom);
      db2_boreChildrenBd_bore_3_ack = 1'($urandom);
      db2_boreChildrenBd_bore_3_selectedOH = 1'($urandom);
      db2_boreChildrenBd_bore_3_array = 4'($urandom);
      db2_sigFromSrams_bore_ram_hold = 1'($urandom);
      db2_sigFromSrams_bore_ram_bypass = 1'($urandom);
      db2_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      db2_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      db2_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      db2_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      db2_sigFromSrams_bore_cgen = 1'($urandom);
      db2_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      db2_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      db2_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      db2_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      db2_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      db2_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      db2_sigFromSrams_bore_1_cgen = 1'($urandom);
      db2_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      db2_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      db2_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      db2_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      db2_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      db2_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      db2_sigFromSrams_bore_2_cgen = 1'($urandom);
      db2_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      db2_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      db2_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      db2_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      db2_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      db2_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      db2_sigFromSrams_bore_3_cgen = 1'($urandom);
      db2_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_db2
        db2_io_r_addr = 8'($urandom_range(0, 7));
        db2_io_w_addr = 8'($urandom_range(0, 7));
        if ($urandom_range(0, 3) != 0) db2_io_w_way_en = 4'b0001 << $urandom_range(0, 3);
        if (cyc < 400) begin db2_io_w_en = 1'b1; db2_io_w_way_en = 4'b0001 << (cyc % 4); db2_io_w_addr = 8'((cyc / 4) % 8); end
        if (db2_mode < 12 || cyc < 400) begin
          db2_boreChildrenBd_bore_addr = '0;
          db2_boreChildrenBd_bore_addr_rd = '0;
          db2_boreChildrenBd_bore_wdata = '0;
          db2_boreChildrenBd_bore_wmask = '0;
          db2_boreChildrenBd_bore_re = '0;
          db2_boreChildrenBd_bore_we = '0;
          db2_boreChildrenBd_bore_ack = '0;
          db2_boreChildrenBd_bore_selectedOH = '0;
          db2_boreChildrenBd_bore_array = '0;
          db2_boreChildrenBd_bore_1_addr = '0;
          db2_boreChildrenBd_bore_1_addr_rd = '0;
          db2_boreChildrenBd_bore_1_wdata = '0;
          db2_boreChildrenBd_bore_1_wmask = '0;
          db2_boreChildrenBd_bore_1_re = '0;
          db2_boreChildrenBd_bore_1_we = '0;
          db2_boreChildrenBd_bore_1_ack = '0;
          db2_boreChildrenBd_bore_1_selectedOH = '0;
          db2_boreChildrenBd_bore_1_array = '0;
          db2_boreChildrenBd_bore_2_addr = '0;
          db2_boreChildrenBd_bore_2_addr_rd = '0;
          db2_boreChildrenBd_bore_2_wdata = '0;
          db2_boreChildrenBd_bore_2_wmask = '0;
          db2_boreChildrenBd_bore_2_re = '0;
          db2_boreChildrenBd_bore_2_we = '0;
          db2_boreChildrenBd_bore_2_ack = '0;
          db2_boreChildrenBd_bore_2_selectedOH = '0;
          db2_boreChildrenBd_bore_2_array = '0;
          db2_boreChildrenBd_bore_3_addr = '0;
          db2_boreChildrenBd_bore_3_addr_rd = '0;
          db2_boreChildrenBd_bore_3_wdata = '0;
          db2_boreChildrenBd_bore_3_wmask = '0;
          db2_boreChildrenBd_bore_3_re = '0;
          db2_boreChildrenBd_bore_3_we = '0;
          db2_boreChildrenBd_bore_3_ack = '0;
          db2_boreChildrenBd_bore_3_selectedOH = '0;
          db2_boreChildrenBd_bore_3_array = '0;
          db2_sigFromSrams_bore_ram_hold = '0;
          db2_sigFromSrams_bore_ram_bypass = '0;
          db2_sigFromSrams_bore_ram_bp_clken = '0;
          db2_sigFromSrams_bore_ram_aux_clk = '0;
          db2_sigFromSrams_bore_ram_aux_ckbp = '0;
          db2_sigFromSrams_bore_ram_mcp_hold = '0;
          db2_sigFromSrams_bore_cgen = '0;
          db2_sigFromSrams_bore_1_ram_hold = '0;
          db2_sigFromSrams_bore_1_ram_bypass = '0;
          db2_sigFromSrams_bore_1_ram_bp_clken = '0;
          db2_sigFromSrams_bore_1_ram_aux_clk = '0;
          db2_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          db2_sigFromSrams_bore_1_ram_mcp_hold = '0;
          db2_sigFromSrams_bore_1_cgen = '0;
          db2_sigFromSrams_bore_2_ram_hold = '0;
          db2_sigFromSrams_bore_2_ram_bypass = '0;
          db2_sigFromSrams_bore_2_ram_bp_clken = '0;
          db2_sigFromSrams_bore_2_ram_aux_clk = '0;
          db2_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          db2_sigFromSrams_bore_2_ram_mcp_hold = '0;
          db2_sigFromSrams_bore_2_cgen = '0;
          db2_sigFromSrams_bore_3_ram_hold = '0;
          db2_sigFromSrams_bore_3_ram_bypass = '0;
          db2_sigFromSrams_bore_3_ram_bp_clken = '0;
          db2_sigFromSrams_bore_3_ram_aux_clk = '0;
          db2_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          db2_sigFromSrams_bore_3_ram_mcp_hold = '0;
          db2_sigFromSrams_bore_3_cgen = '0;
        end
        db2_boreChildrenBd_bore_addr = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_addr_rd = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_1_addr = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_1_addr_rd = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_2_addr = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_2_addr_rd = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_3_addr = 9'($urandom_range(0, 7));
        db2_boreChildrenBd_bore_3_addr_rd = 9'($urandom_range(0, 7));
      end
      if (cyc % 3000 == 0) db4_mode = $urandom_range(0, 15);
      db4_io_w_en = 1'($urandom);
      db4_io_w_addr = 8'($urandom);
      db4_io_w_way_en = 4'($urandom);
      db4_io_w_data = 72'({$urandom, $urandom, $urandom});
      db4_io_r_en = 1'($urandom);
      db4_io_r_addr = 8'($urandom);
      db4_boreChildrenBd_bore_addr = 9'($urandom);
      db4_boreChildrenBd_bore_addr_rd = 9'($urandom);
      db4_boreChildrenBd_bore_wdata = 72'({$urandom, $urandom, $urandom});
      db4_boreChildrenBd_bore_wmask = 1'($urandom);
      db4_boreChildrenBd_bore_re = 1'($urandom);
      db4_boreChildrenBd_bore_we = 1'($urandom);
      db4_boreChildrenBd_bore_ack = 1'($urandom);
      db4_boreChildrenBd_bore_selectedOH = 1'($urandom);
      db4_boreChildrenBd_bore_array = 5'($urandom);
      db4_boreChildrenBd_bore_1_addr = 9'($urandom);
      db4_boreChildrenBd_bore_1_addr_rd = 9'($urandom);
      db4_boreChildrenBd_bore_1_wdata = 72'({$urandom, $urandom, $urandom});
      db4_boreChildrenBd_bore_1_wmask = 1'($urandom);
      db4_boreChildrenBd_bore_1_re = 1'($urandom);
      db4_boreChildrenBd_bore_1_we = 1'($urandom);
      db4_boreChildrenBd_bore_1_ack = 1'($urandom);
      db4_boreChildrenBd_bore_1_selectedOH = 1'($urandom);
      db4_boreChildrenBd_bore_1_array = 5'($urandom);
      db4_boreChildrenBd_bore_2_addr = 9'($urandom);
      db4_boreChildrenBd_bore_2_addr_rd = 9'($urandom);
      db4_boreChildrenBd_bore_2_wdata = 72'({$urandom, $urandom, $urandom});
      db4_boreChildrenBd_bore_2_wmask = 1'($urandom);
      db4_boreChildrenBd_bore_2_re = 1'($urandom);
      db4_boreChildrenBd_bore_2_we = 1'($urandom);
      db4_boreChildrenBd_bore_2_ack = 1'($urandom);
      db4_boreChildrenBd_bore_2_selectedOH = 1'($urandom);
      db4_boreChildrenBd_bore_2_array = 5'($urandom);
      db4_boreChildrenBd_bore_3_addr = 9'($urandom);
      db4_boreChildrenBd_bore_3_addr_rd = 9'($urandom);
      db4_boreChildrenBd_bore_3_wdata = 72'({$urandom, $urandom, $urandom});
      db4_boreChildrenBd_bore_3_wmask = 1'($urandom);
      db4_boreChildrenBd_bore_3_re = 1'($urandom);
      db4_boreChildrenBd_bore_3_we = 1'($urandom);
      db4_boreChildrenBd_bore_3_ack = 1'($urandom);
      db4_boreChildrenBd_bore_3_selectedOH = 1'($urandom);
      db4_boreChildrenBd_bore_3_array = 5'($urandom);
      db4_sigFromSrams_bore_ram_hold = 1'($urandom);
      db4_sigFromSrams_bore_ram_bypass = 1'($urandom);
      db4_sigFromSrams_bore_ram_bp_clken = 1'($urandom);
      db4_sigFromSrams_bore_ram_aux_clk = 1'($urandom);
      db4_sigFromSrams_bore_ram_aux_ckbp = 1'($urandom);
      db4_sigFromSrams_bore_ram_mcp_hold = 1'($urandom);
      db4_sigFromSrams_bore_cgen = 1'($urandom);
      db4_sigFromSrams_bore_1_ram_hold = 1'($urandom);
      db4_sigFromSrams_bore_1_ram_bypass = 1'($urandom);
      db4_sigFromSrams_bore_1_ram_bp_clken = 1'($urandom);
      db4_sigFromSrams_bore_1_ram_aux_clk = 1'($urandom);
      db4_sigFromSrams_bore_1_ram_aux_ckbp = 1'($urandom);
      db4_sigFromSrams_bore_1_ram_mcp_hold = 1'($urandom);
      db4_sigFromSrams_bore_1_cgen = 1'($urandom);
      db4_sigFromSrams_bore_2_ram_hold = 1'($urandom);
      db4_sigFromSrams_bore_2_ram_bypass = 1'($urandom);
      db4_sigFromSrams_bore_2_ram_bp_clken = 1'($urandom);
      db4_sigFromSrams_bore_2_ram_aux_clk = 1'($urandom);
      db4_sigFromSrams_bore_2_ram_aux_ckbp = 1'($urandom);
      db4_sigFromSrams_bore_2_ram_mcp_hold = 1'($urandom);
      db4_sigFromSrams_bore_2_cgen = 1'($urandom);
      db4_sigFromSrams_bore_3_ram_hold = 1'($urandom);
      db4_sigFromSrams_bore_3_ram_bypass = 1'($urandom);
      db4_sigFromSrams_bore_3_ram_bp_clken = 1'($urandom);
      db4_sigFromSrams_bore_3_ram_aux_clk = 1'($urandom);
      db4_sigFromSrams_bore_3_ram_aux_ckbp = 1'($urandom);
      db4_sigFromSrams_bore_3_ram_mcp_hold = 1'($urandom);
      db4_sigFromSrams_bore_3_cgen = 1'($urandom);
      db4_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_db4
        db4_io_r_addr = 8'($urandom_range(0, 7));
        db4_io_w_addr = 8'($urandom_range(0, 7));
        if ($urandom_range(0, 3) != 0) db4_io_w_way_en = 4'b0001 << $urandom_range(0, 3);
        if (cyc < 400) begin db4_io_w_en = 1'b1; db4_io_w_way_en = 4'b0001 << (cyc % 4); db4_io_w_addr = 8'((cyc / 4) % 8); end
        if (db4_mode < 12 || cyc < 400) begin
          db4_boreChildrenBd_bore_addr = '0;
          db4_boreChildrenBd_bore_addr_rd = '0;
          db4_boreChildrenBd_bore_wdata = '0;
          db4_boreChildrenBd_bore_wmask = '0;
          db4_boreChildrenBd_bore_re = '0;
          db4_boreChildrenBd_bore_we = '0;
          db4_boreChildrenBd_bore_ack = '0;
          db4_boreChildrenBd_bore_selectedOH = '0;
          db4_boreChildrenBd_bore_array = '0;
          db4_boreChildrenBd_bore_1_addr = '0;
          db4_boreChildrenBd_bore_1_addr_rd = '0;
          db4_boreChildrenBd_bore_1_wdata = '0;
          db4_boreChildrenBd_bore_1_wmask = '0;
          db4_boreChildrenBd_bore_1_re = '0;
          db4_boreChildrenBd_bore_1_we = '0;
          db4_boreChildrenBd_bore_1_ack = '0;
          db4_boreChildrenBd_bore_1_selectedOH = '0;
          db4_boreChildrenBd_bore_1_array = '0;
          db4_boreChildrenBd_bore_2_addr = '0;
          db4_boreChildrenBd_bore_2_addr_rd = '0;
          db4_boreChildrenBd_bore_2_wdata = '0;
          db4_boreChildrenBd_bore_2_wmask = '0;
          db4_boreChildrenBd_bore_2_re = '0;
          db4_boreChildrenBd_bore_2_we = '0;
          db4_boreChildrenBd_bore_2_ack = '0;
          db4_boreChildrenBd_bore_2_selectedOH = '0;
          db4_boreChildrenBd_bore_2_array = '0;
          db4_boreChildrenBd_bore_3_addr = '0;
          db4_boreChildrenBd_bore_3_addr_rd = '0;
          db4_boreChildrenBd_bore_3_wdata = '0;
          db4_boreChildrenBd_bore_3_wmask = '0;
          db4_boreChildrenBd_bore_3_re = '0;
          db4_boreChildrenBd_bore_3_we = '0;
          db4_boreChildrenBd_bore_3_ack = '0;
          db4_boreChildrenBd_bore_3_selectedOH = '0;
          db4_boreChildrenBd_bore_3_array = '0;
          db4_sigFromSrams_bore_ram_hold = '0;
          db4_sigFromSrams_bore_ram_bypass = '0;
          db4_sigFromSrams_bore_ram_bp_clken = '0;
          db4_sigFromSrams_bore_ram_aux_clk = '0;
          db4_sigFromSrams_bore_ram_aux_ckbp = '0;
          db4_sigFromSrams_bore_ram_mcp_hold = '0;
          db4_sigFromSrams_bore_cgen = '0;
          db4_sigFromSrams_bore_1_ram_hold = '0;
          db4_sigFromSrams_bore_1_ram_bypass = '0;
          db4_sigFromSrams_bore_1_ram_bp_clken = '0;
          db4_sigFromSrams_bore_1_ram_aux_clk = '0;
          db4_sigFromSrams_bore_1_ram_aux_ckbp = '0;
          db4_sigFromSrams_bore_1_ram_mcp_hold = '0;
          db4_sigFromSrams_bore_1_cgen = '0;
          db4_sigFromSrams_bore_2_ram_hold = '0;
          db4_sigFromSrams_bore_2_ram_bypass = '0;
          db4_sigFromSrams_bore_2_ram_bp_clken = '0;
          db4_sigFromSrams_bore_2_ram_aux_clk = '0;
          db4_sigFromSrams_bore_2_ram_aux_ckbp = '0;
          db4_sigFromSrams_bore_2_ram_mcp_hold = '0;
          db4_sigFromSrams_bore_2_cgen = '0;
          db4_sigFromSrams_bore_3_ram_hold = '0;
          db4_sigFromSrams_bore_3_ram_bypass = '0;
          db4_sigFromSrams_bore_3_ram_bp_clken = '0;
          db4_sigFromSrams_bore_3_ram_aux_clk = '0;
          db4_sigFromSrams_bore_3_ram_aux_ckbp = '0;
          db4_sigFromSrams_bore_3_ram_mcp_hold = '0;
          db4_sigFromSrams_bore_3_cgen = '0;
        end
        db4_boreChildrenBd_bore_addr = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_addr_rd = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_1_addr = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_1_addr_rd = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_2_addr = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_2_addr_rd = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_3_addr = 9'($urandom_range(0, 7));
        db4_boreChildrenBd_bore_3_addr_rd = 9'($urandom_range(0, 7));
      end
      #4;
      if (cyc >= RESET_CYC + 0 && db0_armed_at >= 0 && cyc >= db0_armed_at) begin
        checks++;
        if (db0_g_io_r_data_0 !== db0_i_io_r_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.io_r_data_0 g=%h i=%h", cyc, db0_g_io_r_data_0, db0_i_io_r_data_0);
        end
        db0_s1_io_r_data_0 |= db0_g_io_r_data_0;
        db0_s0_io_r_data_0 |= ~db0_g_io_r_data_0;
        checks++;
        if (db0_g_io_r_data_1 !== db0_i_io_r_data_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.io_r_data_1 g=%h i=%h", cyc, db0_g_io_r_data_1, db0_i_io_r_data_1);
        end
        db0_s1_io_r_data_1 |= db0_g_io_r_data_1;
        db0_s0_io_r_data_1 |= ~db0_g_io_r_data_1;
        checks++;
        if (db0_g_io_r_data_2 !== db0_i_io_r_data_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.io_r_data_2 g=%h i=%h", cyc, db0_g_io_r_data_2, db0_i_io_r_data_2);
        end
        db0_s1_io_r_data_2 |= db0_g_io_r_data_2;
        db0_s0_io_r_data_2 |= ~db0_g_io_r_data_2;
        checks++;
        if (db0_g_io_r_data_3 !== db0_i_io_r_data_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.io_r_data_3 g=%h i=%h", cyc, db0_g_io_r_data_3, db0_i_io_r_data_3);
        end
        db0_s1_io_r_data_3 |= db0_g_io_r_data_3;
        db0_s0_io_r_data_3 |= ~db0_g_io_r_data_3;
        checks++;
        if (db0_g_boreChildrenBd_bore_rdata !== db0_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.boreChildrenBd_bore_rdata g=%h i=%h", cyc, db0_g_boreChildrenBd_bore_rdata, db0_i_boreChildrenBd_bore_rdata);
        end
        db0_s1_boreChildrenBd_bore_rdata |= db0_g_boreChildrenBd_bore_rdata;
        db0_s0_boreChildrenBd_bore_rdata |= ~db0_g_boreChildrenBd_bore_rdata;
        checks++;
        if (db0_g_boreChildrenBd_bore_1_rdata !== db0_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, db0_g_boreChildrenBd_bore_1_rdata, db0_i_boreChildrenBd_bore_1_rdata);
        end
        db0_s1_boreChildrenBd_bore_1_rdata |= db0_g_boreChildrenBd_bore_1_rdata;
        db0_s0_boreChildrenBd_bore_1_rdata |= ~db0_g_boreChildrenBd_bore_1_rdata;
        checks++;
        if (db0_g_boreChildrenBd_bore_2_rdata !== db0_i_boreChildrenBd_bore_2_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.boreChildrenBd_bore_2_rdata g=%h i=%h", cyc, db0_g_boreChildrenBd_bore_2_rdata, db0_i_boreChildrenBd_bore_2_rdata);
        end
        db0_s1_boreChildrenBd_bore_2_rdata |= db0_g_boreChildrenBd_bore_2_rdata;
        db0_s0_boreChildrenBd_bore_2_rdata |= ~db0_g_boreChildrenBd_bore_2_rdata;
        checks++;
        if (db0_g_boreChildrenBd_bore_3_rdata !== db0_i_boreChildrenBd_bore_3_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank.boreChildrenBd_bore_3_rdata g=%h i=%h", cyc, db0_g_boreChildrenBd_bore_3_rdata, db0_i_boreChildrenBd_bore_3_rdata);
        end
        db0_s1_boreChildrenBd_bore_3_rdata |= db0_g_boreChildrenBd_bore_3_rdata;
        db0_s0_boreChildrenBd_bore_3_rdata |= ~db0_g_boreChildrenBd_bore_3_rdata;
        if (db0_io_w_en && !$onehot0(db0_io_w_way_en)) db0_cov_multi_way_write++;
        if (db0_io_r_en) db0_cov_read++;
        if (db0_boreChildrenBd_bore_we) db0_cov_mbist_we++;
      end
      if (cyc >= 400) db0_armed[0] = 1'b1;
      if (db0_io_r_en) db0_armed[1] = 1'b1;
      if (db0_armed_at < 0 && (&db0_armed)) db0_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && db1_armed_at >= 0 && cyc >= db1_armed_at) begin
        checks++;
        if (db1_g_io_r_data_0 !== db1_i_io_r_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.io_r_data_0 g=%h i=%h", cyc, db1_g_io_r_data_0, db1_i_io_r_data_0);
        end
        db1_s1_io_r_data_0 |= db1_g_io_r_data_0;
        db1_s0_io_r_data_0 |= ~db1_g_io_r_data_0;
        checks++;
        if (db1_g_io_r_data_1 !== db1_i_io_r_data_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.io_r_data_1 g=%h i=%h", cyc, db1_g_io_r_data_1, db1_i_io_r_data_1);
        end
        db1_s1_io_r_data_1 |= db1_g_io_r_data_1;
        db1_s0_io_r_data_1 |= ~db1_g_io_r_data_1;
        checks++;
        if (db1_g_io_r_data_2 !== db1_i_io_r_data_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.io_r_data_2 g=%h i=%h", cyc, db1_g_io_r_data_2, db1_i_io_r_data_2);
        end
        db1_s1_io_r_data_2 |= db1_g_io_r_data_2;
        db1_s0_io_r_data_2 |= ~db1_g_io_r_data_2;
        checks++;
        if (db1_g_io_r_data_3 !== db1_i_io_r_data_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.io_r_data_3 g=%h i=%h", cyc, db1_g_io_r_data_3, db1_i_io_r_data_3);
        end
        db1_s1_io_r_data_3 |= db1_g_io_r_data_3;
        db1_s0_io_r_data_3 |= ~db1_g_io_r_data_3;
        checks++;
        if (db1_g_boreChildrenBd_bore_rdata !== db1_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.boreChildrenBd_bore_rdata g=%h i=%h", cyc, db1_g_boreChildrenBd_bore_rdata, db1_i_boreChildrenBd_bore_rdata);
        end
        db1_s1_boreChildrenBd_bore_rdata |= db1_g_boreChildrenBd_bore_rdata;
        db1_s0_boreChildrenBd_bore_rdata |= ~db1_g_boreChildrenBd_bore_rdata;
        checks++;
        if (db1_g_boreChildrenBd_bore_1_rdata !== db1_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, db1_g_boreChildrenBd_bore_1_rdata, db1_i_boreChildrenBd_bore_1_rdata);
        end
        db1_s1_boreChildrenBd_bore_1_rdata |= db1_g_boreChildrenBd_bore_1_rdata;
        db1_s0_boreChildrenBd_bore_1_rdata |= ~db1_g_boreChildrenBd_bore_1_rdata;
        checks++;
        if (db1_g_boreChildrenBd_bore_2_rdata !== db1_i_boreChildrenBd_bore_2_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.boreChildrenBd_bore_2_rdata g=%h i=%h", cyc, db1_g_boreChildrenBd_bore_2_rdata, db1_i_boreChildrenBd_bore_2_rdata);
        end
        db1_s1_boreChildrenBd_bore_2_rdata |= db1_g_boreChildrenBd_bore_2_rdata;
        db1_s0_boreChildrenBd_bore_2_rdata |= ~db1_g_boreChildrenBd_bore_2_rdata;
        checks++;
        if (db1_g_boreChildrenBd_bore_3_rdata !== db1_i_boreChildrenBd_bore_3_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_1.boreChildrenBd_bore_3_rdata g=%h i=%h", cyc, db1_g_boreChildrenBd_bore_3_rdata, db1_i_boreChildrenBd_bore_3_rdata);
        end
        db1_s1_boreChildrenBd_bore_3_rdata |= db1_g_boreChildrenBd_bore_3_rdata;
        db1_s0_boreChildrenBd_bore_3_rdata |= ~db1_g_boreChildrenBd_bore_3_rdata;
        if (db1_io_w_en && !$onehot0(db1_io_w_way_en)) db1_cov_multi_way_write++;
        if (db1_io_r_en) db1_cov_read++;
        if (db1_boreChildrenBd_bore_we) db1_cov_mbist_we++;
      end
      if (cyc >= 400) db1_armed[0] = 1'b1;
      if (db1_io_r_en) db1_armed[1] = 1'b1;
      if (db1_armed_at < 0 && (&db1_armed)) db1_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && db2_armed_at >= 0 && cyc >= db2_armed_at) begin
        checks++;
        if (db2_g_io_r_data_0 !== db2_i_io_r_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.io_r_data_0 g=%h i=%h", cyc, db2_g_io_r_data_0, db2_i_io_r_data_0);
        end
        db2_s1_io_r_data_0 |= db2_g_io_r_data_0;
        db2_s0_io_r_data_0 |= ~db2_g_io_r_data_0;
        checks++;
        if (db2_g_io_r_data_1 !== db2_i_io_r_data_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.io_r_data_1 g=%h i=%h", cyc, db2_g_io_r_data_1, db2_i_io_r_data_1);
        end
        db2_s1_io_r_data_1 |= db2_g_io_r_data_1;
        db2_s0_io_r_data_1 |= ~db2_g_io_r_data_1;
        checks++;
        if (db2_g_io_r_data_2 !== db2_i_io_r_data_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.io_r_data_2 g=%h i=%h", cyc, db2_g_io_r_data_2, db2_i_io_r_data_2);
        end
        db2_s1_io_r_data_2 |= db2_g_io_r_data_2;
        db2_s0_io_r_data_2 |= ~db2_g_io_r_data_2;
        checks++;
        if (db2_g_io_r_data_3 !== db2_i_io_r_data_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.io_r_data_3 g=%h i=%h", cyc, db2_g_io_r_data_3, db2_i_io_r_data_3);
        end
        db2_s1_io_r_data_3 |= db2_g_io_r_data_3;
        db2_s0_io_r_data_3 |= ~db2_g_io_r_data_3;
        checks++;
        if (db2_g_boreChildrenBd_bore_rdata !== db2_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.boreChildrenBd_bore_rdata g=%h i=%h", cyc, db2_g_boreChildrenBd_bore_rdata, db2_i_boreChildrenBd_bore_rdata);
        end
        db2_s1_boreChildrenBd_bore_rdata |= db2_g_boreChildrenBd_bore_rdata;
        db2_s0_boreChildrenBd_bore_rdata |= ~db2_g_boreChildrenBd_bore_rdata;
        checks++;
        if (db2_g_boreChildrenBd_bore_1_rdata !== db2_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, db2_g_boreChildrenBd_bore_1_rdata, db2_i_boreChildrenBd_bore_1_rdata);
        end
        db2_s1_boreChildrenBd_bore_1_rdata |= db2_g_boreChildrenBd_bore_1_rdata;
        db2_s0_boreChildrenBd_bore_1_rdata |= ~db2_g_boreChildrenBd_bore_1_rdata;
        checks++;
        if (db2_g_boreChildrenBd_bore_2_rdata !== db2_i_boreChildrenBd_bore_2_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.boreChildrenBd_bore_2_rdata g=%h i=%h", cyc, db2_g_boreChildrenBd_bore_2_rdata, db2_i_boreChildrenBd_bore_2_rdata);
        end
        db2_s1_boreChildrenBd_bore_2_rdata |= db2_g_boreChildrenBd_bore_2_rdata;
        db2_s0_boreChildrenBd_bore_2_rdata |= ~db2_g_boreChildrenBd_bore_2_rdata;
        checks++;
        if (db2_g_boreChildrenBd_bore_3_rdata !== db2_i_boreChildrenBd_bore_3_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_2.boreChildrenBd_bore_3_rdata g=%h i=%h", cyc, db2_g_boreChildrenBd_bore_3_rdata, db2_i_boreChildrenBd_bore_3_rdata);
        end
        db2_s1_boreChildrenBd_bore_3_rdata |= db2_g_boreChildrenBd_bore_3_rdata;
        db2_s0_boreChildrenBd_bore_3_rdata |= ~db2_g_boreChildrenBd_bore_3_rdata;
        if (db2_io_w_en && !$onehot0(db2_io_w_way_en)) db2_cov_multi_way_write++;
        if (db2_io_r_en) db2_cov_read++;
        if (db2_boreChildrenBd_bore_we) db2_cov_mbist_we++;
      end
      if (cyc >= 400) db2_armed[0] = 1'b1;
      if (db2_io_r_en) db2_armed[1] = 1'b1;
      if (db2_armed_at < 0 && (&db2_armed)) db2_armed_at = cyc + 1 + 2;
      if (cyc >= RESET_CYC + 0 && db4_armed_at >= 0 && cyc >= db4_armed_at) begin
        checks++;
        if (db4_g_io_r_data_0 !== db4_i_io_r_data_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.io_r_data_0 g=%h i=%h", cyc, db4_g_io_r_data_0, db4_i_io_r_data_0);
        end
        db4_s1_io_r_data_0 |= db4_g_io_r_data_0;
        db4_s0_io_r_data_0 |= ~db4_g_io_r_data_0;
        checks++;
        if (db4_g_io_r_data_1 !== db4_i_io_r_data_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.io_r_data_1 g=%h i=%h", cyc, db4_g_io_r_data_1, db4_i_io_r_data_1);
        end
        db4_s1_io_r_data_1 |= db4_g_io_r_data_1;
        db4_s0_io_r_data_1 |= ~db4_g_io_r_data_1;
        checks++;
        if (db4_g_io_r_data_2 !== db4_i_io_r_data_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.io_r_data_2 g=%h i=%h", cyc, db4_g_io_r_data_2, db4_i_io_r_data_2);
        end
        db4_s1_io_r_data_2 |= db4_g_io_r_data_2;
        db4_s0_io_r_data_2 |= ~db4_g_io_r_data_2;
        checks++;
        if (db4_g_io_r_data_3 !== db4_i_io_r_data_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.io_r_data_3 g=%h i=%h", cyc, db4_g_io_r_data_3, db4_i_io_r_data_3);
        end
        db4_s1_io_r_data_3 |= db4_g_io_r_data_3;
        db4_s0_io_r_data_3 |= ~db4_g_io_r_data_3;
        checks++;
        if (db4_g_boreChildrenBd_bore_rdata !== db4_i_boreChildrenBd_bore_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.boreChildrenBd_bore_rdata g=%h i=%h", cyc, db4_g_boreChildrenBd_bore_rdata, db4_i_boreChildrenBd_bore_rdata);
        end
        db4_s1_boreChildrenBd_bore_rdata |= db4_g_boreChildrenBd_bore_rdata;
        db4_s0_boreChildrenBd_bore_rdata |= ~db4_g_boreChildrenBd_bore_rdata;
        checks++;
        if (db4_g_boreChildrenBd_bore_1_rdata !== db4_i_boreChildrenBd_bore_1_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.boreChildrenBd_bore_1_rdata g=%h i=%h", cyc, db4_g_boreChildrenBd_bore_1_rdata, db4_i_boreChildrenBd_bore_1_rdata);
        end
        db4_s1_boreChildrenBd_bore_1_rdata |= db4_g_boreChildrenBd_bore_1_rdata;
        db4_s0_boreChildrenBd_bore_1_rdata |= ~db4_g_boreChildrenBd_bore_1_rdata;
        checks++;
        if (db4_g_boreChildrenBd_bore_2_rdata !== db4_i_boreChildrenBd_bore_2_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.boreChildrenBd_bore_2_rdata g=%h i=%h", cyc, db4_g_boreChildrenBd_bore_2_rdata, db4_i_boreChildrenBd_bore_2_rdata);
        end
        db4_s1_boreChildrenBd_bore_2_rdata |= db4_g_boreChildrenBd_bore_2_rdata;
        db4_s0_boreChildrenBd_bore_2_rdata |= ~db4_g_boreChildrenBd_bore_2_rdata;
        checks++;
        if (db4_g_boreChildrenBd_bore_3_rdata !== db4_i_boreChildrenBd_bore_3_rdata) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d DataSRAMBank_4.boreChildrenBd_bore_3_rdata g=%h i=%h", cyc, db4_g_boreChildrenBd_bore_3_rdata, db4_i_boreChildrenBd_bore_3_rdata);
        end
        db4_s1_boreChildrenBd_bore_3_rdata |= db4_g_boreChildrenBd_bore_3_rdata;
        db4_s0_boreChildrenBd_bore_3_rdata |= ~db4_g_boreChildrenBd_bore_3_rdata;
        if (db4_io_w_en && !$onehot0(db4_io_w_way_en)) db4_cov_multi_way_write++;
        if (db4_io_r_en) db4_cov_read++;
        if (db4_boreChildrenBd_bore_we) db4_cov_mbist_we++;
      end
      if (cyc >= 400) db4_armed[0] = 1'b1;
      if (db4_io_r_en) db4_armed[1] = 1'b1;
      if (db4_armed_at < 0 && (&db4_armed)) db4_armed_at = cyc + 1 + 2;
    end

    // ---- 覆盖闸 ----
    if (!(db0_s0_io_r_data_0[0] && db0_s1_io_r_data_0[0])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[0] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[1] && db0_s1_io_r_data_0[1])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[1] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[2] && db0_s1_io_r_data_0[2])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[2] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[3] && db0_s1_io_r_data_0[3])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[3] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[4] && db0_s1_io_r_data_0[4])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[4] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[5] && db0_s1_io_r_data_0[5])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[5] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[6] && db0_s1_io_r_data_0[6])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[6] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[7] && db0_s1_io_r_data_0[7])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[7] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[8] && db0_s1_io_r_data_0[8])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[8] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[9] && db0_s1_io_r_data_0[9])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[9] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[10] && db0_s1_io_r_data_0[10])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[10] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[11] && db0_s1_io_r_data_0[11])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[11] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[12] && db0_s1_io_r_data_0[12])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[12] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[13] && db0_s1_io_r_data_0[13])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[13] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[14] && db0_s1_io_r_data_0[14])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[14] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[15] && db0_s1_io_r_data_0[15])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[15] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[16] && db0_s1_io_r_data_0[16])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[16] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[17] && db0_s1_io_r_data_0[17])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[17] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[18] && db0_s1_io_r_data_0[18])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[18] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[19] && db0_s1_io_r_data_0[19])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[19] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[20] && db0_s1_io_r_data_0[20])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[20] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[21] && db0_s1_io_r_data_0[21])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[21] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[22] && db0_s1_io_r_data_0[22])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[22] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[23] && db0_s1_io_r_data_0[23])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[23] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[24] && db0_s1_io_r_data_0[24])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[24] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[25] && db0_s1_io_r_data_0[25])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[25] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[26] && db0_s1_io_r_data_0[26])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[26] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[27] && db0_s1_io_r_data_0[27])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[27] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[28] && db0_s1_io_r_data_0[28])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[28] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[29] && db0_s1_io_r_data_0[29])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[29] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[30] && db0_s1_io_r_data_0[30])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[30] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[31] && db0_s1_io_r_data_0[31])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[31] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[32] && db0_s1_io_r_data_0[32])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[32] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[33] && db0_s1_io_r_data_0[33])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[33] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[34] && db0_s1_io_r_data_0[34])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[34] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[35] && db0_s1_io_r_data_0[35])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[35] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[36] && db0_s1_io_r_data_0[36])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[36] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[37] && db0_s1_io_r_data_0[37])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[37] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[38] && db0_s1_io_r_data_0[38])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[38] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[39] && db0_s1_io_r_data_0[39])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[39] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[40] && db0_s1_io_r_data_0[40])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[40] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[41] && db0_s1_io_r_data_0[41])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[41] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[42] && db0_s1_io_r_data_0[42])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[42] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[43] && db0_s1_io_r_data_0[43])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[43] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[44] && db0_s1_io_r_data_0[44])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[44] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[45] && db0_s1_io_r_data_0[45])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[45] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[46] && db0_s1_io_r_data_0[46])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[46] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[47] && db0_s1_io_r_data_0[47])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[47] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[48] && db0_s1_io_r_data_0[48])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[48] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[49] && db0_s1_io_r_data_0[49])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[49] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[50] && db0_s1_io_r_data_0[50])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[50] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[51] && db0_s1_io_r_data_0[51])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[51] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[52] && db0_s1_io_r_data_0[52])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[52] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[53] && db0_s1_io_r_data_0[53])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[53] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[54] && db0_s1_io_r_data_0[54])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[54] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[55] && db0_s1_io_r_data_0[55])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[55] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[56] && db0_s1_io_r_data_0[56])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[56] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[57] && db0_s1_io_r_data_0[57])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[57] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[58] && db0_s1_io_r_data_0[58])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[58] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[59] && db0_s1_io_r_data_0[59])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[59] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[60] && db0_s1_io_r_data_0[60])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[60] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[61] && db0_s1_io_r_data_0[61])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[61] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[62] && db0_s1_io_r_data_0[62])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[62] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[63] && db0_s1_io_r_data_0[63])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[63] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[64] && db0_s1_io_r_data_0[64])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[64] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[65] && db0_s1_io_r_data_0[65])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[65] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[66] && db0_s1_io_r_data_0[66])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[66] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[67] && db0_s1_io_r_data_0[67])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[67] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[68] && db0_s1_io_r_data_0[68])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[68] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[69] && db0_s1_io_r_data_0[69])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[69] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[70] && db0_s1_io_r_data_0[70])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[70] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_0[71] && db0_s1_io_r_data_0[71])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_0[71] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[0] && db0_s1_io_r_data_1[0])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[0] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[1] && db0_s1_io_r_data_1[1])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[1] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[2] && db0_s1_io_r_data_1[2])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[2] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[3] && db0_s1_io_r_data_1[3])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[3] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[4] && db0_s1_io_r_data_1[4])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[4] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[5] && db0_s1_io_r_data_1[5])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[5] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[6] && db0_s1_io_r_data_1[6])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[6] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[7] && db0_s1_io_r_data_1[7])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[7] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[8] && db0_s1_io_r_data_1[8])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[8] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[9] && db0_s1_io_r_data_1[9])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[9] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[10] && db0_s1_io_r_data_1[10])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[10] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[11] && db0_s1_io_r_data_1[11])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[11] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[12] && db0_s1_io_r_data_1[12])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[12] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[13] && db0_s1_io_r_data_1[13])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[13] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[14] && db0_s1_io_r_data_1[14])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[14] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[15] && db0_s1_io_r_data_1[15])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[15] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[16] && db0_s1_io_r_data_1[16])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[16] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[17] && db0_s1_io_r_data_1[17])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[17] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[18] && db0_s1_io_r_data_1[18])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[18] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[19] && db0_s1_io_r_data_1[19])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[19] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[20] && db0_s1_io_r_data_1[20])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[20] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[21] && db0_s1_io_r_data_1[21])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[21] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[22] && db0_s1_io_r_data_1[22])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[22] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[23] && db0_s1_io_r_data_1[23])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[23] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[24] && db0_s1_io_r_data_1[24])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[24] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[25] && db0_s1_io_r_data_1[25])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[25] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[26] && db0_s1_io_r_data_1[26])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[26] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[27] && db0_s1_io_r_data_1[27])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[27] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[28] && db0_s1_io_r_data_1[28])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[28] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[29] && db0_s1_io_r_data_1[29])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[29] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[30] && db0_s1_io_r_data_1[30])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[30] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[31] && db0_s1_io_r_data_1[31])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[31] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[32] && db0_s1_io_r_data_1[32])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[32] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[33] && db0_s1_io_r_data_1[33])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[33] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[34] && db0_s1_io_r_data_1[34])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[34] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[35] && db0_s1_io_r_data_1[35])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[35] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[36] && db0_s1_io_r_data_1[36])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[36] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[37] && db0_s1_io_r_data_1[37])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[37] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[38] && db0_s1_io_r_data_1[38])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[38] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[39] && db0_s1_io_r_data_1[39])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[39] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[40] && db0_s1_io_r_data_1[40])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[40] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[41] && db0_s1_io_r_data_1[41])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[41] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[42] && db0_s1_io_r_data_1[42])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[42] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[43] && db0_s1_io_r_data_1[43])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[43] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[44] && db0_s1_io_r_data_1[44])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[44] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[45] && db0_s1_io_r_data_1[45])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[45] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[46] && db0_s1_io_r_data_1[46])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[46] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[47] && db0_s1_io_r_data_1[47])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[47] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[48] && db0_s1_io_r_data_1[48])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[48] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[49] && db0_s1_io_r_data_1[49])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[49] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[50] && db0_s1_io_r_data_1[50])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[50] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[51] && db0_s1_io_r_data_1[51])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[51] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[52] && db0_s1_io_r_data_1[52])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[52] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[53] && db0_s1_io_r_data_1[53])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[53] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[54] && db0_s1_io_r_data_1[54])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[54] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[55] && db0_s1_io_r_data_1[55])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[55] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[56] && db0_s1_io_r_data_1[56])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[56] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[57] && db0_s1_io_r_data_1[57])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[57] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[58] && db0_s1_io_r_data_1[58])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[58] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[59] && db0_s1_io_r_data_1[59])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[59] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[60] && db0_s1_io_r_data_1[60])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[60] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[61] && db0_s1_io_r_data_1[61])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[61] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[62] && db0_s1_io_r_data_1[62])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[62] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[63] && db0_s1_io_r_data_1[63])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[63] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[64] && db0_s1_io_r_data_1[64])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[64] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[65] && db0_s1_io_r_data_1[65])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[65] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[66] && db0_s1_io_r_data_1[66])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[66] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[67] && db0_s1_io_r_data_1[67])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[67] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[68] && db0_s1_io_r_data_1[68])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[68] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[69] && db0_s1_io_r_data_1[69])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[69] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[70] && db0_s1_io_r_data_1[70])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[70] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_1[71] && db0_s1_io_r_data_1[71])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_1[71] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[0] && db0_s1_io_r_data_2[0])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[0] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[1] && db0_s1_io_r_data_2[1])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[1] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[2] && db0_s1_io_r_data_2[2])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[2] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[3] && db0_s1_io_r_data_2[3])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[3] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[4] && db0_s1_io_r_data_2[4])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[4] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[5] && db0_s1_io_r_data_2[5])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[5] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[6] && db0_s1_io_r_data_2[6])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[6] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[7] && db0_s1_io_r_data_2[7])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[7] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[8] && db0_s1_io_r_data_2[8])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[8] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[9] && db0_s1_io_r_data_2[9])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[9] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[10] && db0_s1_io_r_data_2[10])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[10] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[11] && db0_s1_io_r_data_2[11])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[11] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[12] && db0_s1_io_r_data_2[12])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[12] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[13] && db0_s1_io_r_data_2[13])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[13] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[14] && db0_s1_io_r_data_2[14])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[14] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[15] && db0_s1_io_r_data_2[15])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[15] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[16] && db0_s1_io_r_data_2[16])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[16] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[17] && db0_s1_io_r_data_2[17])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[17] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[18] && db0_s1_io_r_data_2[18])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[18] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[19] && db0_s1_io_r_data_2[19])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[19] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[20] && db0_s1_io_r_data_2[20])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[20] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[21] && db0_s1_io_r_data_2[21])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[21] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[22] && db0_s1_io_r_data_2[22])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[22] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[23] && db0_s1_io_r_data_2[23])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[23] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[24] && db0_s1_io_r_data_2[24])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[24] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[25] && db0_s1_io_r_data_2[25])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[25] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[26] && db0_s1_io_r_data_2[26])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[26] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[27] && db0_s1_io_r_data_2[27])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[27] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[28] && db0_s1_io_r_data_2[28])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[28] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[29] && db0_s1_io_r_data_2[29])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[29] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[30] && db0_s1_io_r_data_2[30])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[30] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[31] && db0_s1_io_r_data_2[31])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[31] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[32] && db0_s1_io_r_data_2[32])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[32] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[33] && db0_s1_io_r_data_2[33])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[33] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[34] && db0_s1_io_r_data_2[34])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[34] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[35] && db0_s1_io_r_data_2[35])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[35] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[36] && db0_s1_io_r_data_2[36])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[36] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[37] && db0_s1_io_r_data_2[37])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[37] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[38] && db0_s1_io_r_data_2[38])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[38] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[39] && db0_s1_io_r_data_2[39])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[39] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[40] && db0_s1_io_r_data_2[40])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[40] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[41] && db0_s1_io_r_data_2[41])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[41] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[42] && db0_s1_io_r_data_2[42])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[42] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[43] && db0_s1_io_r_data_2[43])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[43] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[44] && db0_s1_io_r_data_2[44])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[44] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[45] && db0_s1_io_r_data_2[45])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[45] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[46] && db0_s1_io_r_data_2[46])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[46] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[47] && db0_s1_io_r_data_2[47])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[47] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[48] && db0_s1_io_r_data_2[48])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[48] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[49] && db0_s1_io_r_data_2[49])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[49] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[50] && db0_s1_io_r_data_2[50])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[50] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[51] && db0_s1_io_r_data_2[51])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[51] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[52] && db0_s1_io_r_data_2[52])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[52] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[53] && db0_s1_io_r_data_2[53])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[53] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[54] && db0_s1_io_r_data_2[54])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[54] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[55] && db0_s1_io_r_data_2[55])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[55] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[56] && db0_s1_io_r_data_2[56])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[56] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[57] && db0_s1_io_r_data_2[57])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[57] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[58] && db0_s1_io_r_data_2[58])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[58] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[59] && db0_s1_io_r_data_2[59])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[59] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[60] && db0_s1_io_r_data_2[60])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[60] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[61] && db0_s1_io_r_data_2[61])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[61] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[62] && db0_s1_io_r_data_2[62])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[62] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[63] && db0_s1_io_r_data_2[63])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[63] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[64] && db0_s1_io_r_data_2[64])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[64] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[65] && db0_s1_io_r_data_2[65])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[65] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[66] && db0_s1_io_r_data_2[66])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[66] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[67] && db0_s1_io_r_data_2[67])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[67] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[68] && db0_s1_io_r_data_2[68])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[68] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[69] && db0_s1_io_r_data_2[69])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[69] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[70] && db0_s1_io_r_data_2[70])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[70] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_2[71] && db0_s1_io_r_data_2[71])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_2[71] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[0] && db0_s1_io_r_data_3[0])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[0] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[1] && db0_s1_io_r_data_3[1])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[1] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[2] && db0_s1_io_r_data_3[2])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[2] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[3] && db0_s1_io_r_data_3[3])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[3] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[4] && db0_s1_io_r_data_3[4])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[4] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[5] && db0_s1_io_r_data_3[5])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[5] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[6] && db0_s1_io_r_data_3[6])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[6] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[7] && db0_s1_io_r_data_3[7])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[7] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[8] && db0_s1_io_r_data_3[8])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[8] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[9] && db0_s1_io_r_data_3[9])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[9] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[10] && db0_s1_io_r_data_3[10])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[10] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[11] && db0_s1_io_r_data_3[11])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[11] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[12] && db0_s1_io_r_data_3[12])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[12] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[13] && db0_s1_io_r_data_3[13])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[13] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[14] && db0_s1_io_r_data_3[14])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[14] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[15] && db0_s1_io_r_data_3[15])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[15] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[16] && db0_s1_io_r_data_3[16])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[16] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[17] && db0_s1_io_r_data_3[17])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[17] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[18] && db0_s1_io_r_data_3[18])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[18] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[19] && db0_s1_io_r_data_3[19])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[19] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[20] && db0_s1_io_r_data_3[20])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[20] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[21] && db0_s1_io_r_data_3[21])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[21] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[22] && db0_s1_io_r_data_3[22])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[22] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[23] && db0_s1_io_r_data_3[23])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[23] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[24] && db0_s1_io_r_data_3[24])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[24] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[25] && db0_s1_io_r_data_3[25])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[25] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[26] && db0_s1_io_r_data_3[26])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[26] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[27] && db0_s1_io_r_data_3[27])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[27] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[28] && db0_s1_io_r_data_3[28])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[28] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[29] && db0_s1_io_r_data_3[29])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[29] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[30] && db0_s1_io_r_data_3[30])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[30] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[31] && db0_s1_io_r_data_3[31])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[31] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[32] && db0_s1_io_r_data_3[32])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[32] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[33] && db0_s1_io_r_data_3[33])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[33] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[34] && db0_s1_io_r_data_3[34])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[34] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[35] && db0_s1_io_r_data_3[35])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[35] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[36] && db0_s1_io_r_data_3[36])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[36] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[37] && db0_s1_io_r_data_3[37])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[37] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[38] && db0_s1_io_r_data_3[38])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[38] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[39] && db0_s1_io_r_data_3[39])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[39] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[40] && db0_s1_io_r_data_3[40])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[40] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[41] && db0_s1_io_r_data_3[41])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[41] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[42] && db0_s1_io_r_data_3[42])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[42] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[43] && db0_s1_io_r_data_3[43])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[43] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[44] && db0_s1_io_r_data_3[44])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[44] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[45] && db0_s1_io_r_data_3[45])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[45] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[46] && db0_s1_io_r_data_3[46])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[46] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[47] && db0_s1_io_r_data_3[47])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[47] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[48] && db0_s1_io_r_data_3[48])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[48] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[49] && db0_s1_io_r_data_3[49])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[49] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[50] && db0_s1_io_r_data_3[50])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[50] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[51] && db0_s1_io_r_data_3[51])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[51] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[52] && db0_s1_io_r_data_3[52])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[52] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[53] && db0_s1_io_r_data_3[53])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[53] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[54] && db0_s1_io_r_data_3[54])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[54] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[55] && db0_s1_io_r_data_3[55])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[55] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[56] && db0_s1_io_r_data_3[56])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[56] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[57] && db0_s1_io_r_data_3[57])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[57] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[58] && db0_s1_io_r_data_3[58])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[58] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[59] && db0_s1_io_r_data_3[59])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[59] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[60] && db0_s1_io_r_data_3[60])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[60] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[61] && db0_s1_io_r_data_3[61])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[61] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[62] && db0_s1_io_r_data_3[62])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[62] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[63] && db0_s1_io_r_data_3[63])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[63] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[64] && db0_s1_io_r_data_3[64])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[64] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[65] && db0_s1_io_r_data_3[65])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[65] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[66] && db0_s1_io_r_data_3[66])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[66] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[67] && db0_s1_io_r_data_3[67])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[67] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[68] && db0_s1_io_r_data_3[68])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[68] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[69] && db0_s1_io_r_data_3[69])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[69] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[70] && db0_s1_io_r_data_3[70])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[70] 未见过 0 和 1"); end
    if (!(db0_s0_io_r_data_3[71] && db0_s1_io_r_data_3[71])) begin cov_fail++; $display("[COV] DataSRAMBank.io_r_data_3[71] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[0] && db0_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[1] && db0_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[2] && db0_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[3] && db0_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[4] && db0_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[5] && db0_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[6] && db0_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[7] && db0_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[8] && db0_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[9] && db0_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[10] && db0_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[11] && db0_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[12] && db0_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[13] && db0_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[14] && db0_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[15] && db0_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[16] && db0_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[17] && db0_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[18] && db0_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[19] && db0_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[20] && db0_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[21] && db0_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[22] && db0_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[23] && db0_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[24] && db0_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[25] && db0_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[26] && db0_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[27] && db0_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[28] && db0_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[29] && db0_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[30] && db0_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[31] && db0_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[32] && db0_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[33] && db0_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[34] && db0_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[35] && db0_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[36] && db0_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[37] && db0_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[38] && db0_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[39] && db0_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[40] && db0_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[41] && db0_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[42] && db0_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[43] && db0_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[44] && db0_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[45] && db0_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[46] && db0_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[47] && db0_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[48] && db0_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[49] && db0_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[50] && db0_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[51] && db0_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[52] && db0_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[53] && db0_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[54] && db0_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[55] && db0_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[56] && db0_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[57] && db0_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[58] && db0_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[59] && db0_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[60] && db0_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[61] && db0_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[62] && db0_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[63] && db0_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[64] && db0_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[65] && db0_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[66] && db0_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[67] && db0_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[68] && db0_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[69] && db0_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[70] && db0_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_rdata[71] && db0_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[0] && db0_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[1] && db0_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[2] && db0_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[3] && db0_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[4] && db0_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[5] && db0_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[6] && db0_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[7] && db0_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[8] && db0_s1_boreChildrenBd_bore_1_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[8] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[9] && db0_s1_boreChildrenBd_bore_1_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[9] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[10] && db0_s1_boreChildrenBd_bore_1_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[10] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[11] && db0_s1_boreChildrenBd_bore_1_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[11] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[12] && db0_s1_boreChildrenBd_bore_1_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[12] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[13] && db0_s1_boreChildrenBd_bore_1_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[13] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[14] && db0_s1_boreChildrenBd_bore_1_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[14] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[15] && db0_s1_boreChildrenBd_bore_1_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[15] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[16] && db0_s1_boreChildrenBd_bore_1_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[16] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[17] && db0_s1_boreChildrenBd_bore_1_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[17] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[18] && db0_s1_boreChildrenBd_bore_1_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[18] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[19] && db0_s1_boreChildrenBd_bore_1_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[19] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[20] && db0_s1_boreChildrenBd_bore_1_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[20] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[21] && db0_s1_boreChildrenBd_bore_1_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[21] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[22] && db0_s1_boreChildrenBd_bore_1_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[22] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[23] && db0_s1_boreChildrenBd_bore_1_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[23] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[24] && db0_s1_boreChildrenBd_bore_1_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[24] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[25] && db0_s1_boreChildrenBd_bore_1_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[25] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[26] && db0_s1_boreChildrenBd_bore_1_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[26] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[27] && db0_s1_boreChildrenBd_bore_1_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[27] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[28] && db0_s1_boreChildrenBd_bore_1_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[28] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[29] && db0_s1_boreChildrenBd_bore_1_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[29] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[30] && db0_s1_boreChildrenBd_bore_1_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[30] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[31] && db0_s1_boreChildrenBd_bore_1_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[31] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[32] && db0_s1_boreChildrenBd_bore_1_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[32] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[33] && db0_s1_boreChildrenBd_bore_1_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[33] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[34] && db0_s1_boreChildrenBd_bore_1_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[34] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[35] && db0_s1_boreChildrenBd_bore_1_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[35] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[36] && db0_s1_boreChildrenBd_bore_1_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[36] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[37] && db0_s1_boreChildrenBd_bore_1_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[37] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[38] && db0_s1_boreChildrenBd_bore_1_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[38] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[39] && db0_s1_boreChildrenBd_bore_1_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[39] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[40] && db0_s1_boreChildrenBd_bore_1_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[40] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[41] && db0_s1_boreChildrenBd_bore_1_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[41] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[42] && db0_s1_boreChildrenBd_bore_1_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[42] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[43] && db0_s1_boreChildrenBd_bore_1_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[43] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[44] && db0_s1_boreChildrenBd_bore_1_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[44] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[45] && db0_s1_boreChildrenBd_bore_1_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[45] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[46] && db0_s1_boreChildrenBd_bore_1_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[46] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[47] && db0_s1_boreChildrenBd_bore_1_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[47] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[48] && db0_s1_boreChildrenBd_bore_1_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[48] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[49] && db0_s1_boreChildrenBd_bore_1_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[49] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[50] && db0_s1_boreChildrenBd_bore_1_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[50] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[51] && db0_s1_boreChildrenBd_bore_1_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[51] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[52] && db0_s1_boreChildrenBd_bore_1_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[52] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[53] && db0_s1_boreChildrenBd_bore_1_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[53] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[54] && db0_s1_boreChildrenBd_bore_1_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[54] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[55] && db0_s1_boreChildrenBd_bore_1_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[55] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[56] && db0_s1_boreChildrenBd_bore_1_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[56] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[57] && db0_s1_boreChildrenBd_bore_1_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[57] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[58] && db0_s1_boreChildrenBd_bore_1_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[58] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[59] && db0_s1_boreChildrenBd_bore_1_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[59] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[60] && db0_s1_boreChildrenBd_bore_1_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[60] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[61] && db0_s1_boreChildrenBd_bore_1_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[61] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[62] && db0_s1_boreChildrenBd_bore_1_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[62] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[63] && db0_s1_boreChildrenBd_bore_1_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[63] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[64] && db0_s1_boreChildrenBd_bore_1_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[64] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[65] && db0_s1_boreChildrenBd_bore_1_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[65] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[66] && db0_s1_boreChildrenBd_bore_1_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[66] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[67] && db0_s1_boreChildrenBd_bore_1_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[67] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[68] && db0_s1_boreChildrenBd_bore_1_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[68] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[69] && db0_s1_boreChildrenBd_bore_1_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[69] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[70] && db0_s1_boreChildrenBd_bore_1_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[70] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_1_rdata[71] && db0_s1_boreChildrenBd_bore_1_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_1_rdata[71] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[0] && db0_s1_boreChildrenBd_bore_2_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[0] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[1] && db0_s1_boreChildrenBd_bore_2_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[1] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[2] && db0_s1_boreChildrenBd_bore_2_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[2] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[3] && db0_s1_boreChildrenBd_bore_2_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[3] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[4] && db0_s1_boreChildrenBd_bore_2_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[4] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[5] && db0_s1_boreChildrenBd_bore_2_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[5] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[6] && db0_s1_boreChildrenBd_bore_2_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[6] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[7] && db0_s1_boreChildrenBd_bore_2_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[7] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[8] && db0_s1_boreChildrenBd_bore_2_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[8] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[9] && db0_s1_boreChildrenBd_bore_2_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[9] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[10] && db0_s1_boreChildrenBd_bore_2_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[10] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[11] && db0_s1_boreChildrenBd_bore_2_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[11] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[12] && db0_s1_boreChildrenBd_bore_2_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[12] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[13] && db0_s1_boreChildrenBd_bore_2_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[13] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[14] && db0_s1_boreChildrenBd_bore_2_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[14] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[15] && db0_s1_boreChildrenBd_bore_2_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[15] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[16] && db0_s1_boreChildrenBd_bore_2_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[16] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[17] && db0_s1_boreChildrenBd_bore_2_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[17] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[18] && db0_s1_boreChildrenBd_bore_2_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[18] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[19] && db0_s1_boreChildrenBd_bore_2_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[19] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[20] && db0_s1_boreChildrenBd_bore_2_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[20] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[21] && db0_s1_boreChildrenBd_bore_2_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[21] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[22] && db0_s1_boreChildrenBd_bore_2_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[22] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[23] && db0_s1_boreChildrenBd_bore_2_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[23] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[24] && db0_s1_boreChildrenBd_bore_2_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[24] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[25] && db0_s1_boreChildrenBd_bore_2_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[25] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[26] && db0_s1_boreChildrenBd_bore_2_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[26] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[27] && db0_s1_boreChildrenBd_bore_2_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[27] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[28] && db0_s1_boreChildrenBd_bore_2_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[28] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[29] && db0_s1_boreChildrenBd_bore_2_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[29] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[30] && db0_s1_boreChildrenBd_bore_2_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[30] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[31] && db0_s1_boreChildrenBd_bore_2_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[31] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[32] && db0_s1_boreChildrenBd_bore_2_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[32] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[33] && db0_s1_boreChildrenBd_bore_2_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[33] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[34] && db0_s1_boreChildrenBd_bore_2_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[34] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[35] && db0_s1_boreChildrenBd_bore_2_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[35] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[36] && db0_s1_boreChildrenBd_bore_2_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[36] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[37] && db0_s1_boreChildrenBd_bore_2_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[37] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[38] && db0_s1_boreChildrenBd_bore_2_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[38] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[39] && db0_s1_boreChildrenBd_bore_2_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[39] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[40] && db0_s1_boreChildrenBd_bore_2_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[40] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[41] && db0_s1_boreChildrenBd_bore_2_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[41] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[42] && db0_s1_boreChildrenBd_bore_2_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[42] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[43] && db0_s1_boreChildrenBd_bore_2_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[43] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[44] && db0_s1_boreChildrenBd_bore_2_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[44] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[45] && db0_s1_boreChildrenBd_bore_2_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[45] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[46] && db0_s1_boreChildrenBd_bore_2_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[46] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[47] && db0_s1_boreChildrenBd_bore_2_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[47] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[48] && db0_s1_boreChildrenBd_bore_2_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[48] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[49] && db0_s1_boreChildrenBd_bore_2_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[49] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[50] && db0_s1_boreChildrenBd_bore_2_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[50] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[51] && db0_s1_boreChildrenBd_bore_2_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[51] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[52] && db0_s1_boreChildrenBd_bore_2_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[52] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[53] && db0_s1_boreChildrenBd_bore_2_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[53] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[54] && db0_s1_boreChildrenBd_bore_2_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[54] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[55] && db0_s1_boreChildrenBd_bore_2_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[55] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[56] && db0_s1_boreChildrenBd_bore_2_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[56] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[57] && db0_s1_boreChildrenBd_bore_2_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[57] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[58] && db0_s1_boreChildrenBd_bore_2_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[58] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[59] && db0_s1_boreChildrenBd_bore_2_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[59] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[60] && db0_s1_boreChildrenBd_bore_2_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[60] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[61] && db0_s1_boreChildrenBd_bore_2_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[61] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[62] && db0_s1_boreChildrenBd_bore_2_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[62] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[63] && db0_s1_boreChildrenBd_bore_2_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[63] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[64] && db0_s1_boreChildrenBd_bore_2_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[64] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[65] && db0_s1_boreChildrenBd_bore_2_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[65] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[66] && db0_s1_boreChildrenBd_bore_2_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[66] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[67] && db0_s1_boreChildrenBd_bore_2_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[67] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[68] && db0_s1_boreChildrenBd_bore_2_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[68] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[69] && db0_s1_boreChildrenBd_bore_2_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[69] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[70] && db0_s1_boreChildrenBd_bore_2_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[70] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_2_rdata[71] && db0_s1_boreChildrenBd_bore_2_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_2_rdata[71] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[0] && db0_s1_boreChildrenBd_bore_3_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[0] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[1] && db0_s1_boreChildrenBd_bore_3_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[1] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[2] && db0_s1_boreChildrenBd_bore_3_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[2] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[3] && db0_s1_boreChildrenBd_bore_3_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[3] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[4] && db0_s1_boreChildrenBd_bore_3_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[4] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[5] && db0_s1_boreChildrenBd_bore_3_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[5] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[6] && db0_s1_boreChildrenBd_bore_3_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[6] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[7] && db0_s1_boreChildrenBd_bore_3_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[7] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[8] && db0_s1_boreChildrenBd_bore_3_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[8] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[9] && db0_s1_boreChildrenBd_bore_3_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[9] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[10] && db0_s1_boreChildrenBd_bore_3_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[10] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[11] && db0_s1_boreChildrenBd_bore_3_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[11] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[12] && db0_s1_boreChildrenBd_bore_3_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[12] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[13] && db0_s1_boreChildrenBd_bore_3_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[13] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[14] && db0_s1_boreChildrenBd_bore_3_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[14] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[15] && db0_s1_boreChildrenBd_bore_3_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[15] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[16] && db0_s1_boreChildrenBd_bore_3_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[16] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[17] && db0_s1_boreChildrenBd_bore_3_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[17] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[18] && db0_s1_boreChildrenBd_bore_3_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[18] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[19] && db0_s1_boreChildrenBd_bore_3_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[19] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[20] && db0_s1_boreChildrenBd_bore_3_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[20] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[21] && db0_s1_boreChildrenBd_bore_3_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[21] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[22] && db0_s1_boreChildrenBd_bore_3_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[22] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[23] && db0_s1_boreChildrenBd_bore_3_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[23] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[24] && db0_s1_boreChildrenBd_bore_3_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[24] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[25] && db0_s1_boreChildrenBd_bore_3_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[25] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[26] && db0_s1_boreChildrenBd_bore_3_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[26] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[27] && db0_s1_boreChildrenBd_bore_3_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[27] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[28] && db0_s1_boreChildrenBd_bore_3_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[28] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[29] && db0_s1_boreChildrenBd_bore_3_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[29] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[30] && db0_s1_boreChildrenBd_bore_3_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[30] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[31] && db0_s1_boreChildrenBd_bore_3_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[31] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[32] && db0_s1_boreChildrenBd_bore_3_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[32] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[33] && db0_s1_boreChildrenBd_bore_3_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[33] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[34] && db0_s1_boreChildrenBd_bore_3_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[34] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[35] && db0_s1_boreChildrenBd_bore_3_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[35] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[36] && db0_s1_boreChildrenBd_bore_3_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[36] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[37] && db0_s1_boreChildrenBd_bore_3_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[37] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[38] && db0_s1_boreChildrenBd_bore_3_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[38] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[39] && db0_s1_boreChildrenBd_bore_3_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[39] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[40] && db0_s1_boreChildrenBd_bore_3_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[40] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[41] && db0_s1_boreChildrenBd_bore_3_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[41] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[42] && db0_s1_boreChildrenBd_bore_3_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[42] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[43] && db0_s1_boreChildrenBd_bore_3_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[43] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[44] && db0_s1_boreChildrenBd_bore_3_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[44] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[45] && db0_s1_boreChildrenBd_bore_3_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[45] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[46] && db0_s1_boreChildrenBd_bore_3_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[46] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[47] && db0_s1_boreChildrenBd_bore_3_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[47] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[48] && db0_s1_boreChildrenBd_bore_3_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[48] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[49] && db0_s1_boreChildrenBd_bore_3_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[49] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[50] && db0_s1_boreChildrenBd_bore_3_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[50] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[51] && db0_s1_boreChildrenBd_bore_3_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[51] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[52] && db0_s1_boreChildrenBd_bore_3_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[52] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[53] && db0_s1_boreChildrenBd_bore_3_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[53] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[54] && db0_s1_boreChildrenBd_bore_3_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[54] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[55] && db0_s1_boreChildrenBd_bore_3_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[55] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[56] && db0_s1_boreChildrenBd_bore_3_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[56] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[57] && db0_s1_boreChildrenBd_bore_3_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[57] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[58] && db0_s1_boreChildrenBd_bore_3_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[58] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[59] && db0_s1_boreChildrenBd_bore_3_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[59] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[60] && db0_s1_boreChildrenBd_bore_3_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[60] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[61] && db0_s1_boreChildrenBd_bore_3_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[61] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[62] && db0_s1_boreChildrenBd_bore_3_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[62] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[63] && db0_s1_boreChildrenBd_bore_3_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[63] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[64] && db0_s1_boreChildrenBd_bore_3_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[64] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[65] && db0_s1_boreChildrenBd_bore_3_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[65] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[66] && db0_s1_boreChildrenBd_bore_3_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[66] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[67] && db0_s1_boreChildrenBd_bore_3_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[67] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[68] && db0_s1_boreChildrenBd_bore_3_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[68] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[69] && db0_s1_boreChildrenBd_bore_3_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[69] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[70] && db0_s1_boreChildrenBd_bore_3_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[70] 未见过 0 和 1"); end
    if (!(db0_s0_boreChildrenBd_bore_3_rdata[71] && db0_s1_boreChildrenBd_bore_3_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank.boreChildrenBd_bore_3_rdata[71] 未见过 0 和 1"); end
    $display("[ARM] DataSRAMBank armed_at=%0d", db0_armed_at);
    if (db0_armed_at < 0) begin cov_fail++; $display("[ARM] DataSRAMBank 从未 arm"); end
    $display("[COV] DataSRAMBank.multi_way_write = %0d", db0_cov_multi_way_write);
    if (db0_cov_multi_way_write < 200) begin cov_fail++; $display("[COV] DataSRAMBank.multi_way_write < 200"); end
    $display("[COV] DataSRAMBank.read = %0d", db0_cov_read);
    if (db0_cov_read < 200) begin cov_fail++; $display("[COV] DataSRAMBank.read < 200"); end
    $display("[COV] DataSRAMBank.mbist_we = %0d", db0_cov_mbist_we);
    if (db0_cov_mbist_we < 200) begin cov_fail++; $display("[COV] DataSRAMBank.mbist_we < 200"); end
    if (!(db1_s0_io_r_data_0[0] && db1_s1_io_r_data_0[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[0] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[1] && db1_s1_io_r_data_0[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[1] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[2] && db1_s1_io_r_data_0[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[2] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[3] && db1_s1_io_r_data_0[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[3] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[4] && db1_s1_io_r_data_0[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[4] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[5] && db1_s1_io_r_data_0[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[5] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[6] && db1_s1_io_r_data_0[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[6] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[7] && db1_s1_io_r_data_0[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[7] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[8] && db1_s1_io_r_data_0[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[8] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[9] && db1_s1_io_r_data_0[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[9] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[10] && db1_s1_io_r_data_0[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[10] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[11] && db1_s1_io_r_data_0[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[11] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[12] && db1_s1_io_r_data_0[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[12] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[13] && db1_s1_io_r_data_0[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[13] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[14] && db1_s1_io_r_data_0[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[14] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[15] && db1_s1_io_r_data_0[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[15] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[16] && db1_s1_io_r_data_0[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[16] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[17] && db1_s1_io_r_data_0[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[17] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[18] && db1_s1_io_r_data_0[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[18] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[19] && db1_s1_io_r_data_0[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[19] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[20] && db1_s1_io_r_data_0[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[20] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[21] && db1_s1_io_r_data_0[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[21] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[22] && db1_s1_io_r_data_0[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[22] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[23] && db1_s1_io_r_data_0[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[23] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[24] && db1_s1_io_r_data_0[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[24] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[25] && db1_s1_io_r_data_0[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[25] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[26] && db1_s1_io_r_data_0[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[26] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[27] && db1_s1_io_r_data_0[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[27] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[28] && db1_s1_io_r_data_0[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[28] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[29] && db1_s1_io_r_data_0[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[29] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[30] && db1_s1_io_r_data_0[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[30] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[31] && db1_s1_io_r_data_0[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[31] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[32] && db1_s1_io_r_data_0[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[32] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[33] && db1_s1_io_r_data_0[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[33] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[34] && db1_s1_io_r_data_0[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[34] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[35] && db1_s1_io_r_data_0[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[35] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[36] && db1_s1_io_r_data_0[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[36] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[37] && db1_s1_io_r_data_0[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[37] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[38] && db1_s1_io_r_data_0[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[38] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[39] && db1_s1_io_r_data_0[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[39] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[40] && db1_s1_io_r_data_0[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[40] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[41] && db1_s1_io_r_data_0[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[41] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[42] && db1_s1_io_r_data_0[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[42] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[43] && db1_s1_io_r_data_0[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[43] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[44] && db1_s1_io_r_data_0[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[44] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[45] && db1_s1_io_r_data_0[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[45] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[46] && db1_s1_io_r_data_0[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[46] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[47] && db1_s1_io_r_data_0[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[47] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[48] && db1_s1_io_r_data_0[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[48] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[49] && db1_s1_io_r_data_0[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[49] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[50] && db1_s1_io_r_data_0[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[50] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[51] && db1_s1_io_r_data_0[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[51] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[52] && db1_s1_io_r_data_0[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[52] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[53] && db1_s1_io_r_data_0[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[53] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[54] && db1_s1_io_r_data_0[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[54] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[55] && db1_s1_io_r_data_0[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[55] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[56] && db1_s1_io_r_data_0[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[56] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[57] && db1_s1_io_r_data_0[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[57] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[58] && db1_s1_io_r_data_0[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[58] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[59] && db1_s1_io_r_data_0[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[59] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[60] && db1_s1_io_r_data_0[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[60] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[61] && db1_s1_io_r_data_0[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[61] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[62] && db1_s1_io_r_data_0[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[62] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[63] && db1_s1_io_r_data_0[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[63] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[64] && db1_s1_io_r_data_0[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[64] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[65] && db1_s1_io_r_data_0[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[65] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[66] && db1_s1_io_r_data_0[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[66] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[67] && db1_s1_io_r_data_0[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[67] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[68] && db1_s1_io_r_data_0[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[68] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[69] && db1_s1_io_r_data_0[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[69] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[70] && db1_s1_io_r_data_0[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[70] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_0[71] && db1_s1_io_r_data_0[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_0[71] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[0] && db1_s1_io_r_data_1[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[0] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[1] && db1_s1_io_r_data_1[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[1] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[2] && db1_s1_io_r_data_1[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[2] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[3] && db1_s1_io_r_data_1[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[3] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[4] && db1_s1_io_r_data_1[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[4] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[5] && db1_s1_io_r_data_1[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[5] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[6] && db1_s1_io_r_data_1[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[6] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[7] && db1_s1_io_r_data_1[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[7] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[8] && db1_s1_io_r_data_1[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[8] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[9] && db1_s1_io_r_data_1[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[9] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[10] && db1_s1_io_r_data_1[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[10] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[11] && db1_s1_io_r_data_1[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[11] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[12] && db1_s1_io_r_data_1[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[12] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[13] && db1_s1_io_r_data_1[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[13] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[14] && db1_s1_io_r_data_1[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[14] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[15] && db1_s1_io_r_data_1[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[15] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[16] && db1_s1_io_r_data_1[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[16] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[17] && db1_s1_io_r_data_1[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[17] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[18] && db1_s1_io_r_data_1[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[18] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[19] && db1_s1_io_r_data_1[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[19] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[20] && db1_s1_io_r_data_1[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[20] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[21] && db1_s1_io_r_data_1[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[21] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[22] && db1_s1_io_r_data_1[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[22] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[23] && db1_s1_io_r_data_1[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[23] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[24] && db1_s1_io_r_data_1[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[24] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[25] && db1_s1_io_r_data_1[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[25] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[26] && db1_s1_io_r_data_1[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[26] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[27] && db1_s1_io_r_data_1[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[27] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[28] && db1_s1_io_r_data_1[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[28] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[29] && db1_s1_io_r_data_1[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[29] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[30] && db1_s1_io_r_data_1[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[30] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[31] && db1_s1_io_r_data_1[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[31] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[32] && db1_s1_io_r_data_1[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[32] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[33] && db1_s1_io_r_data_1[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[33] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[34] && db1_s1_io_r_data_1[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[34] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[35] && db1_s1_io_r_data_1[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[35] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[36] && db1_s1_io_r_data_1[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[36] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[37] && db1_s1_io_r_data_1[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[37] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[38] && db1_s1_io_r_data_1[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[38] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[39] && db1_s1_io_r_data_1[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[39] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[40] && db1_s1_io_r_data_1[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[40] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[41] && db1_s1_io_r_data_1[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[41] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[42] && db1_s1_io_r_data_1[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[42] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[43] && db1_s1_io_r_data_1[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[43] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[44] && db1_s1_io_r_data_1[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[44] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[45] && db1_s1_io_r_data_1[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[45] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[46] && db1_s1_io_r_data_1[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[46] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[47] && db1_s1_io_r_data_1[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[47] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[48] && db1_s1_io_r_data_1[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[48] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[49] && db1_s1_io_r_data_1[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[49] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[50] && db1_s1_io_r_data_1[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[50] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[51] && db1_s1_io_r_data_1[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[51] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[52] && db1_s1_io_r_data_1[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[52] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[53] && db1_s1_io_r_data_1[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[53] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[54] && db1_s1_io_r_data_1[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[54] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[55] && db1_s1_io_r_data_1[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[55] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[56] && db1_s1_io_r_data_1[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[56] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[57] && db1_s1_io_r_data_1[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[57] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[58] && db1_s1_io_r_data_1[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[58] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[59] && db1_s1_io_r_data_1[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[59] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[60] && db1_s1_io_r_data_1[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[60] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[61] && db1_s1_io_r_data_1[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[61] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[62] && db1_s1_io_r_data_1[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[62] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[63] && db1_s1_io_r_data_1[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[63] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[64] && db1_s1_io_r_data_1[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[64] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[65] && db1_s1_io_r_data_1[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[65] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[66] && db1_s1_io_r_data_1[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[66] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[67] && db1_s1_io_r_data_1[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[67] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[68] && db1_s1_io_r_data_1[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[68] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[69] && db1_s1_io_r_data_1[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[69] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[70] && db1_s1_io_r_data_1[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[70] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_1[71] && db1_s1_io_r_data_1[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_1[71] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[0] && db1_s1_io_r_data_2[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[0] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[1] && db1_s1_io_r_data_2[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[1] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[2] && db1_s1_io_r_data_2[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[2] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[3] && db1_s1_io_r_data_2[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[3] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[4] && db1_s1_io_r_data_2[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[4] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[5] && db1_s1_io_r_data_2[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[5] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[6] && db1_s1_io_r_data_2[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[6] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[7] && db1_s1_io_r_data_2[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[7] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[8] && db1_s1_io_r_data_2[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[8] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[9] && db1_s1_io_r_data_2[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[9] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[10] && db1_s1_io_r_data_2[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[10] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[11] && db1_s1_io_r_data_2[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[11] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[12] && db1_s1_io_r_data_2[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[12] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[13] && db1_s1_io_r_data_2[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[13] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[14] && db1_s1_io_r_data_2[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[14] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[15] && db1_s1_io_r_data_2[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[15] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[16] && db1_s1_io_r_data_2[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[16] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[17] && db1_s1_io_r_data_2[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[17] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[18] && db1_s1_io_r_data_2[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[18] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[19] && db1_s1_io_r_data_2[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[19] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[20] && db1_s1_io_r_data_2[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[20] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[21] && db1_s1_io_r_data_2[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[21] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[22] && db1_s1_io_r_data_2[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[22] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[23] && db1_s1_io_r_data_2[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[23] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[24] && db1_s1_io_r_data_2[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[24] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[25] && db1_s1_io_r_data_2[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[25] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[26] && db1_s1_io_r_data_2[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[26] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[27] && db1_s1_io_r_data_2[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[27] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[28] && db1_s1_io_r_data_2[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[28] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[29] && db1_s1_io_r_data_2[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[29] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[30] && db1_s1_io_r_data_2[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[30] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[31] && db1_s1_io_r_data_2[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[31] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[32] && db1_s1_io_r_data_2[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[32] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[33] && db1_s1_io_r_data_2[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[33] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[34] && db1_s1_io_r_data_2[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[34] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[35] && db1_s1_io_r_data_2[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[35] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[36] && db1_s1_io_r_data_2[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[36] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[37] && db1_s1_io_r_data_2[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[37] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[38] && db1_s1_io_r_data_2[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[38] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[39] && db1_s1_io_r_data_2[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[39] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[40] && db1_s1_io_r_data_2[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[40] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[41] && db1_s1_io_r_data_2[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[41] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[42] && db1_s1_io_r_data_2[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[42] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[43] && db1_s1_io_r_data_2[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[43] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[44] && db1_s1_io_r_data_2[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[44] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[45] && db1_s1_io_r_data_2[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[45] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[46] && db1_s1_io_r_data_2[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[46] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[47] && db1_s1_io_r_data_2[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[47] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[48] && db1_s1_io_r_data_2[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[48] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[49] && db1_s1_io_r_data_2[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[49] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[50] && db1_s1_io_r_data_2[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[50] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[51] && db1_s1_io_r_data_2[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[51] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[52] && db1_s1_io_r_data_2[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[52] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[53] && db1_s1_io_r_data_2[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[53] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[54] && db1_s1_io_r_data_2[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[54] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[55] && db1_s1_io_r_data_2[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[55] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[56] && db1_s1_io_r_data_2[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[56] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[57] && db1_s1_io_r_data_2[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[57] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[58] && db1_s1_io_r_data_2[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[58] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[59] && db1_s1_io_r_data_2[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[59] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[60] && db1_s1_io_r_data_2[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[60] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[61] && db1_s1_io_r_data_2[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[61] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[62] && db1_s1_io_r_data_2[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[62] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[63] && db1_s1_io_r_data_2[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[63] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[64] && db1_s1_io_r_data_2[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[64] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[65] && db1_s1_io_r_data_2[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[65] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[66] && db1_s1_io_r_data_2[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[66] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[67] && db1_s1_io_r_data_2[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[67] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[68] && db1_s1_io_r_data_2[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[68] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[69] && db1_s1_io_r_data_2[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[69] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[70] && db1_s1_io_r_data_2[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[70] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_2[71] && db1_s1_io_r_data_2[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_2[71] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[0] && db1_s1_io_r_data_3[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[0] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[1] && db1_s1_io_r_data_3[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[1] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[2] && db1_s1_io_r_data_3[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[2] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[3] && db1_s1_io_r_data_3[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[3] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[4] && db1_s1_io_r_data_3[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[4] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[5] && db1_s1_io_r_data_3[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[5] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[6] && db1_s1_io_r_data_3[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[6] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[7] && db1_s1_io_r_data_3[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[7] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[8] && db1_s1_io_r_data_3[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[8] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[9] && db1_s1_io_r_data_3[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[9] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[10] && db1_s1_io_r_data_3[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[10] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[11] && db1_s1_io_r_data_3[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[11] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[12] && db1_s1_io_r_data_3[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[12] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[13] && db1_s1_io_r_data_3[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[13] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[14] && db1_s1_io_r_data_3[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[14] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[15] && db1_s1_io_r_data_3[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[15] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[16] && db1_s1_io_r_data_3[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[16] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[17] && db1_s1_io_r_data_3[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[17] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[18] && db1_s1_io_r_data_3[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[18] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[19] && db1_s1_io_r_data_3[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[19] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[20] && db1_s1_io_r_data_3[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[20] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[21] && db1_s1_io_r_data_3[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[21] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[22] && db1_s1_io_r_data_3[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[22] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[23] && db1_s1_io_r_data_3[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[23] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[24] && db1_s1_io_r_data_3[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[24] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[25] && db1_s1_io_r_data_3[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[25] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[26] && db1_s1_io_r_data_3[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[26] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[27] && db1_s1_io_r_data_3[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[27] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[28] && db1_s1_io_r_data_3[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[28] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[29] && db1_s1_io_r_data_3[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[29] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[30] && db1_s1_io_r_data_3[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[30] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[31] && db1_s1_io_r_data_3[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[31] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[32] && db1_s1_io_r_data_3[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[32] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[33] && db1_s1_io_r_data_3[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[33] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[34] && db1_s1_io_r_data_3[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[34] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[35] && db1_s1_io_r_data_3[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[35] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[36] && db1_s1_io_r_data_3[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[36] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[37] && db1_s1_io_r_data_3[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[37] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[38] && db1_s1_io_r_data_3[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[38] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[39] && db1_s1_io_r_data_3[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[39] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[40] && db1_s1_io_r_data_3[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[40] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[41] && db1_s1_io_r_data_3[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[41] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[42] && db1_s1_io_r_data_3[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[42] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[43] && db1_s1_io_r_data_3[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[43] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[44] && db1_s1_io_r_data_3[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[44] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[45] && db1_s1_io_r_data_3[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[45] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[46] && db1_s1_io_r_data_3[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[46] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[47] && db1_s1_io_r_data_3[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[47] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[48] && db1_s1_io_r_data_3[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[48] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[49] && db1_s1_io_r_data_3[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[49] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[50] && db1_s1_io_r_data_3[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[50] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[51] && db1_s1_io_r_data_3[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[51] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[52] && db1_s1_io_r_data_3[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[52] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[53] && db1_s1_io_r_data_3[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[53] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[54] && db1_s1_io_r_data_3[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[54] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[55] && db1_s1_io_r_data_3[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[55] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[56] && db1_s1_io_r_data_3[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[56] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[57] && db1_s1_io_r_data_3[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[57] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[58] && db1_s1_io_r_data_3[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[58] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[59] && db1_s1_io_r_data_3[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[59] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[60] && db1_s1_io_r_data_3[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[60] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[61] && db1_s1_io_r_data_3[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[61] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[62] && db1_s1_io_r_data_3[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[62] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[63] && db1_s1_io_r_data_3[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[63] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[64] && db1_s1_io_r_data_3[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[64] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[65] && db1_s1_io_r_data_3[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[65] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[66] && db1_s1_io_r_data_3[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[66] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[67] && db1_s1_io_r_data_3[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[67] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[68] && db1_s1_io_r_data_3[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[68] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[69] && db1_s1_io_r_data_3[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[69] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[70] && db1_s1_io_r_data_3[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[70] 未见过 0 和 1"); end
    if (!(db1_s0_io_r_data_3[71] && db1_s1_io_r_data_3[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.io_r_data_3[71] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[0] && db1_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[1] && db1_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[2] && db1_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[3] && db1_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[4] && db1_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[5] && db1_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[6] && db1_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[7] && db1_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[8] && db1_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[9] && db1_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[10] && db1_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[11] && db1_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[12] && db1_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[13] && db1_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[14] && db1_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[15] && db1_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[16] && db1_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[17] && db1_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[18] && db1_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[19] && db1_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[20] && db1_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[21] && db1_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[22] && db1_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[23] && db1_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[24] && db1_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[25] && db1_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[26] && db1_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[27] && db1_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[28] && db1_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[29] && db1_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[30] && db1_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[31] && db1_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[32] && db1_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[33] && db1_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[34] && db1_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[35] && db1_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[36] && db1_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[37] && db1_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[38] && db1_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[39] && db1_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[40] && db1_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[41] && db1_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[42] && db1_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[43] && db1_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[44] && db1_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[45] && db1_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[46] && db1_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[47] && db1_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[48] && db1_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[49] && db1_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[50] && db1_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[51] && db1_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[52] && db1_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[53] && db1_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[54] && db1_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[55] && db1_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[56] && db1_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[57] && db1_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[58] && db1_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[59] && db1_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[60] && db1_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[61] && db1_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[62] && db1_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[63] && db1_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[64] && db1_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[65] && db1_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[66] && db1_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[67] && db1_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[68] && db1_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[69] && db1_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[70] && db1_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_rdata[71] && db1_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[0] && db1_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[1] && db1_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[2] && db1_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[3] && db1_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[4] && db1_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[5] && db1_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[6] && db1_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[7] && db1_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[8] && db1_s1_boreChildrenBd_bore_1_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[8] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[9] && db1_s1_boreChildrenBd_bore_1_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[9] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[10] && db1_s1_boreChildrenBd_bore_1_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[10] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[11] && db1_s1_boreChildrenBd_bore_1_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[11] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[12] && db1_s1_boreChildrenBd_bore_1_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[12] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[13] && db1_s1_boreChildrenBd_bore_1_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[13] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[14] && db1_s1_boreChildrenBd_bore_1_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[14] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[15] && db1_s1_boreChildrenBd_bore_1_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[15] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[16] && db1_s1_boreChildrenBd_bore_1_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[16] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[17] && db1_s1_boreChildrenBd_bore_1_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[17] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[18] && db1_s1_boreChildrenBd_bore_1_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[18] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[19] && db1_s1_boreChildrenBd_bore_1_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[19] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[20] && db1_s1_boreChildrenBd_bore_1_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[20] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[21] && db1_s1_boreChildrenBd_bore_1_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[21] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[22] && db1_s1_boreChildrenBd_bore_1_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[22] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[23] && db1_s1_boreChildrenBd_bore_1_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[23] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[24] && db1_s1_boreChildrenBd_bore_1_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[24] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[25] && db1_s1_boreChildrenBd_bore_1_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[25] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[26] && db1_s1_boreChildrenBd_bore_1_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[26] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[27] && db1_s1_boreChildrenBd_bore_1_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[27] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[28] && db1_s1_boreChildrenBd_bore_1_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[28] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[29] && db1_s1_boreChildrenBd_bore_1_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[29] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[30] && db1_s1_boreChildrenBd_bore_1_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[30] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[31] && db1_s1_boreChildrenBd_bore_1_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[31] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[32] && db1_s1_boreChildrenBd_bore_1_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[32] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[33] && db1_s1_boreChildrenBd_bore_1_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[33] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[34] && db1_s1_boreChildrenBd_bore_1_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[34] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[35] && db1_s1_boreChildrenBd_bore_1_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[35] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[36] && db1_s1_boreChildrenBd_bore_1_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[36] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[37] && db1_s1_boreChildrenBd_bore_1_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[37] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[38] && db1_s1_boreChildrenBd_bore_1_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[38] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[39] && db1_s1_boreChildrenBd_bore_1_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[39] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[40] && db1_s1_boreChildrenBd_bore_1_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[40] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[41] && db1_s1_boreChildrenBd_bore_1_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[41] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[42] && db1_s1_boreChildrenBd_bore_1_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[42] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[43] && db1_s1_boreChildrenBd_bore_1_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[43] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[44] && db1_s1_boreChildrenBd_bore_1_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[44] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[45] && db1_s1_boreChildrenBd_bore_1_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[45] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[46] && db1_s1_boreChildrenBd_bore_1_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[46] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[47] && db1_s1_boreChildrenBd_bore_1_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[47] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[48] && db1_s1_boreChildrenBd_bore_1_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[48] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[49] && db1_s1_boreChildrenBd_bore_1_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[49] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[50] && db1_s1_boreChildrenBd_bore_1_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[50] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[51] && db1_s1_boreChildrenBd_bore_1_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[51] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[52] && db1_s1_boreChildrenBd_bore_1_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[52] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[53] && db1_s1_boreChildrenBd_bore_1_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[53] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[54] && db1_s1_boreChildrenBd_bore_1_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[54] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[55] && db1_s1_boreChildrenBd_bore_1_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[55] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[56] && db1_s1_boreChildrenBd_bore_1_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[56] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[57] && db1_s1_boreChildrenBd_bore_1_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[57] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[58] && db1_s1_boreChildrenBd_bore_1_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[58] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[59] && db1_s1_boreChildrenBd_bore_1_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[59] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[60] && db1_s1_boreChildrenBd_bore_1_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[60] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[61] && db1_s1_boreChildrenBd_bore_1_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[61] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[62] && db1_s1_boreChildrenBd_bore_1_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[62] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[63] && db1_s1_boreChildrenBd_bore_1_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[63] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[64] && db1_s1_boreChildrenBd_bore_1_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[64] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[65] && db1_s1_boreChildrenBd_bore_1_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[65] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[66] && db1_s1_boreChildrenBd_bore_1_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[66] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[67] && db1_s1_boreChildrenBd_bore_1_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[67] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[68] && db1_s1_boreChildrenBd_bore_1_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[68] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[69] && db1_s1_boreChildrenBd_bore_1_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[69] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[70] && db1_s1_boreChildrenBd_bore_1_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[70] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_1_rdata[71] && db1_s1_boreChildrenBd_bore_1_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_1_rdata[71] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[0] && db1_s1_boreChildrenBd_bore_2_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[0] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[1] && db1_s1_boreChildrenBd_bore_2_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[1] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[2] && db1_s1_boreChildrenBd_bore_2_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[2] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[3] && db1_s1_boreChildrenBd_bore_2_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[3] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[4] && db1_s1_boreChildrenBd_bore_2_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[4] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[5] && db1_s1_boreChildrenBd_bore_2_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[5] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[6] && db1_s1_boreChildrenBd_bore_2_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[6] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[7] && db1_s1_boreChildrenBd_bore_2_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[7] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[8] && db1_s1_boreChildrenBd_bore_2_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[8] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[9] && db1_s1_boreChildrenBd_bore_2_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[9] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[10] && db1_s1_boreChildrenBd_bore_2_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[10] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[11] && db1_s1_boreChildrenBd_bore_2_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[11] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[12] && db1_s1_boreChildrenBd_bore_2_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[12] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[13] && db1_s1_boreChildrenBd_bore_2_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[13] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[14] && db1_s1_boreChildrenBd_bore_2_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[14] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[15] && db1_s1_boreChildrenBd_bore_2_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[15] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[16] && db1_s1_boreChildrenBd_bore_2_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[16] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[17] && db1_s1_boreChildrenBd_bore_2_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[17] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[18] && db1_s1_boreChildrenBd_bore_2_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[18] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[19] && db1_s1_boreChildrenBd_bore_2_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[19] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[20] && db1_s1_boreChildrenBd_bore_2_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[20] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[21] && db1_s1_boreChildrenBd_bore_2_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[21] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[22] && db1_s1_boreChildrenBd_bore_2_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[22] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[23] && db1_s1_boreChildrenBd_bore_2_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[23] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[24] && db1_s1_boreChildrenBd_bore_2_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[24] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[25] && db1_s1_boreChildrenBd_bore_2_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[25] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[26] && db1_s1_boreChildrenBd_bore_2_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[26] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[27] && db1_s1_boreChildrenBd_bore_2_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[27] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[28] && db1_s1_boreChildrenBd_bore_2_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[28] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[29] && db1_s1_boreChildrenBd_bore_2_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[29] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[30] && db1_s1_boreChildrenBd_bore_2_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[30] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[31] && db1_s1_boreChildrenBd_bore_2_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[31] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[32] && db1_s1_boreChildrenBd_bore_2_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[32] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[33] && db1_s1_boreChildrenBd_bore_2_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[33] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[34] && db1_s1_boreChildrenBd_bore_2_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[34] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[35] && db1_s1_boreChildrenBd_bore_2_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[35] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[36] && db1_s1_boreChildrenBd_bore_2_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[36] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[37] && db1_s1_boreChildrenBd_bore_2_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[37] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[38] && db1_s1_boreChildrenBd_bore_2_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[38] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[39] && db1_s1_boreChildrenBd_bore_2_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[39] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[40] && db1_s1_boreChildrenBd_bore_2_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[40] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[41] && db1_s1_boreChildrenBd_bore_2_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[41] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[42] && db1_s1_boreChildrenBd_bore_2_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[42] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[43] && db1_s1_boreChildrenBd_bore_2_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[43] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[44] && db1_s1_boreChildrenBd_bore_2_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[44] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[45] && db1_s1_boreChildrenBd_bore_2_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[45] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[46] && db1_s1_boreChildrenBd_bore_2_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[46] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[47] && db1_s1_boreChildrenBd_bore_2_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[47] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[48] && db1_s1_boreChildrenBd_bore_2_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[48] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[49] && db1_s1_boreChildrenBd_bore_2_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[49] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[50] && db1_s1_boreChildrenBd_bore_2_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[50] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[51] && db1_s1_boreChildrenBd_bore_2_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[51] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[52] && db1_s1_boreChildrenBd_bore_2_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[52] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[53] && db1_s1_boreChildrenBd_bore_2_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[53] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[54] && db1_s1_boreChildrenBd_bore_2_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[54] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[55] && db1_s1_boreChildrenBd_bore_2_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[55] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[56] && db1_s1_boreChildrenBd_bore_2_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[56] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[57] && db1_s1_boreChildrenBd_bore_2_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[57] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[58] && db1_s1_boreChildrenBd_bore_2_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[58] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[59] && db1_s1_boreChildrenBd_bore_2_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[59] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[60] && db1_s1_boreChildrenBd_bore_2_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[60] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[61] && db1_s1_boreChildrenBd_bore_2_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[61] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[62] && db1_s1_boreChildrenBd_bore_2_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[62] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[63] && db1_s1_boreChildrenBd_bore_2_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[63] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[64] && db1_s1_boreChildrenBd_bore_2_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[64] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[65] && db1_s1_boreChildrenBd_bore_2_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[65] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[66] && db1_s1_boreChildrenBd_bore_2_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[66] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[67] && db1_s1_boreChildrenBd_bore_2_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[67] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[68] && db1_s1_boreChildrenBd_bore_2_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[68] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[69] && db1_s1_boreChildrenBd_bore_2_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[69] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[70] && db1_s1_boreChildrenBd_bore_2_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[70] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_2_rdata[71] && db1_s1_boreChildrenBd_bore_2_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_2_rdata[71] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[0] && db1_s1_boreChildrenBd_bore_3_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[0] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[1] && db1_s1_boreChildrenBd_bore_3_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[1] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[2] && db1_s1_boreChildrenBd_bore_3_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[2] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[3] && db1_s1_boreChildrenBd_bore_3_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[3] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[4] && db1_s1_boreChildrenBd_bore_3_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[4] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[5] && db1_s1_boreChildrenBd_bore_3_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[5] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[6] && db1_s1_boreChildrenBd_bore_3_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[6] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[7] && db1_s1_boreChildrenBd_bore_3_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[7] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[8] && db1_s1_boreChildrenBd_bore_3_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[8] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[9] && db1_s1_boreChildrenBd_bore_3_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[9] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[10] && db1_s1_boreChildrenBd_bore_3_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[10] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[11] && db1_s1_boreChildrenBd_bore_3_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[11] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[12] && db1_s1_boreChildrenBd_bore_3_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[12] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[13] && db1_s1_boreChildrenBd_bore_3_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[13] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[14] && db1_s1_boreChildrenBd_bore_3_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[14] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[15] && db1_s1_boreChildrenBd_bore_3_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[15] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[16] && db1_s1_boreChildrenBd_bore_3_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[16] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[17] && db1_s1_boreChildrenBd_bore_3_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[17] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[18] && db1_s1_boreChildrenBd_bore_3_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[18] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[19] && db1_s1_boreChildrenBd_bore_3_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[19] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[20] && db1_s1_boreChildrenBd_bore_3_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[20] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[21] && db1_s1_boreChildrenBd_bore_3_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[21] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[22] && db1_s1_boreChildrenBd_bore_3_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[22] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[23] && db1_s1_boreChildrenBd_bore_3_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[23] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[24] && db1_s1_boreChildrenBd_bore_3_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[24] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[25] && db1_s1_boreChildrenBd_bore_3_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[25] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[26] && db1_s1_boreChildrenBd_bore_3_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[26] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[27] && db1_s1_boreChildrenBd_bore_3_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[27] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[28] && db1_s1_boreChildrenBd_bore_3_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[28] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[29] && db1_s1_boreChildrenBd_bore_3_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[29] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[30] && db1_s1_boreChildrenBd_bore_3_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[30] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[31] && db1_s1_boreChildrenBd_bore_3_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[31] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[32] && db1_s1_boreChildrenBd_bore_3_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[32] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[33] && db1_s1_boreChildrenBd_bore_3_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[33] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[34] && db1_s1_boreChildrenBd_bore_3_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[34] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[35] && db1_s1_boreChildrenBd_bore_3_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[35] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[36] && db1_s1_boreChildrenBd_bore_3_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[36] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[37] && db1_s1_boreChildrenBd_bore_3_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[37] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[38] && db1_s1_boreChildrenBd_bore_3_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[38] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[39] && db1_s1_boreChildrenBd_bore_3_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[39] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[40] && db1_s1_boreChildrenBd_bore_3_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[40] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[41] && db1_s1_boreChildrenBd_bore_3_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[41] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[42] && db1_s1_boreChildrenBd_bore_3_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[42] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[43] && db1_s1_boreChildrenBd_bore_3_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[43] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[44] && db1_s1_boreChildrenBd_bore_3_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[44] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[45] && db1_s1_boreChildrenBd_bore_3_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[45] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[46] && db1_s1_boreChildrenBd_bore_3_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[46] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[47] && db1_s1_boreChildrenBd_bore_3_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[47] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[48] && db1_s1_boreChildrenBd_bore_3_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[48] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[49] && db1_s1_boreChildrenBd_bore_3_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[49] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[50] && db1_s1_boreChildrenBd_bore_3_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[50] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[51] && db1_s1_boreChildrenBd_bore_3_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[51] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[52] && db1_s1_boreChildrenBd_bore_3_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[52] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[53] && db1_s1_boreChildrenBd_bore_3_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[53] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[54] && db1_s1_boreChildrenBd_bore_3_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[54] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[55] && db1_s1_boreChildrenBd_bore_3_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[55] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[56] && db1_s1_boreChildrenBd_bore_3_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[56] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[57] && db1_s1_boreChildrenBd_bore_3_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[57] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[58] && db1_s1_boreChildrenBd_bore_3_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[58] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[59] && db1_s1_boreChildrenBd_bore_3_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[59] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[60] && db1_s1_boreChildrenBd_bore_3_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[60] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[61] && db1_s1_boreChildrenBd_bore_3_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[61] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[62] && db1_s1_boreChildrenBd_bore_3_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[62] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[63] && db1_s1_boreChildrenBd_bore_3_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[63] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[64] && db1_s1_boreChildrenBd_bore_3_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[64] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[65] && db1_s1_boreChildrenBd_bore_3_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[65] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[66] && db1_s1_boreChildrenBd_bore_3_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[66] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[67] && db1_s1_boreChildrenBd_bore_3_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[67] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[68] && db1_s1_boreChildrenBd_bore_3_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[68] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[69] && db1_s1_boreChildrenBd_bore_3_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[69] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[70] && db1_s1_boreChildrenBd_bore_3_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[70] 未见过 0 和 1"); end
    if (!(db1_s0_boreChildrenBd_bore_3_rdata[71] && db1_s1_boreChildrenBd_bore_3_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_1.boreChildrenBd_bore_3_rdata[71] 未见过 0 和 1"); end
    $display("[ARM] DataSRAMBank_1 armed_at=%0d", db1_armed_at);
    if (db1_armed_at < 0) begin cov_fail++; $display("[ARM] DataSRAMBank_1 从未 arm"); end
    $display("[COV] DataSRAMBank_1.multi_way_write = %0d", db1_cov_multi_way_write);
    if (db1_cov_multi_way_write < 200) begin cov_fail++; $display("[COV] DataSRAMBank_1.multi_way_write < 200"); end
    $display("[COV] DataSRAMBank_1.read = %0d", db1_cov_read);
    if (db1_cov_read < 200) begin cov_fail++; $display("[COV] DataSRAMBank_1.read < 200"); end
    $display("[COV] DataSRAMBank_1.mbist_we = %0d", db1_cov_mbist_we);
    if (db1_cov_mbist_we < 200) begin cov_fail++; $display("[COV] DataSRAMBank_1.mbist_we < 200"); end
    if (!(db2_s0_io_r_data_0[0] && db2_s1_io_r_data_0[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[0] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[1] && db2_s1_io_r_data_0[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[1] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[2] && db2_s1_io_r_data_0[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[2] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[3] && db2_s1_io_r_data_0[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[3] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[4] && db2_s1_io_r_data_0[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[4] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[5] && db2_s1_io_r_data_0[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[5] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[6] && db2_s1_io_r_data_0[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[6] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[7] && db2_s1_io_r_data_0[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[7] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[8] && db2_s1_io_r_data_0[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[8] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[9] && db2_s1_io_r_data_0[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[9] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[10] && db2_s1_io_r_data_0[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[10] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[11] && db2_s1_io_r_data_0[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[11] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[12] && db2_s1_io_r_data_0[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[12] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[13] && db2_s1_io_r_data_0[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[13] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[14] && db2_s1_io_r_data_0[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[14] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[15] && db2_s1_io_r_data_0[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[15] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[16] && db2_s1_io_r_data_0[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[16] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[17] && db2_s1_io_r_data_0[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[17] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[18] && db2_s1_io_r_data_0[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[18] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[19] && db2_s1_io_r_data_0[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[19] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[20] && db2_s1_io_r_data_0[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[20] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[21] && db2_s1_io_r_data_0[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[21] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[22] && db2_s1_io_r_data_0[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[22] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[23] && db2_s1_io_r_data_0[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[23] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[24] && db2_s1_io_r_data_0[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[24] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[25] && db2_s1_io_r_data_0[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[25] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[26] && db2_s1_io_r_data_0[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[26] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[27] && db2_s1_io_r_data_0[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[27] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[28] && db2_s1_io_r_data_0[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[28] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[29] && db2_s1_io_r_data_0[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[29] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[30] && db2_s1_io_r_data_0[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[30] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[31] && db2_s1_io_r_data_0[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[31] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[32] && db2_s1_io_r_data_0[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[32] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[33] && db2_s1_io_r_data_0[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[33] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[34] && db2_s1_io_r_data_0[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[34] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[35] && db2_s1_io_r_data_0[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[35] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[36] && db2_s1_io_r_data_0[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[36] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[37] && db2_s1_io_r_data_0[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[37] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[38] && db2_s1_io_r_data_0[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[38] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[39] && db2_s1_io_r_data_0[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[39] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[40] && db2_s1_io_r_data_0[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[40] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[41] && db2_s1_io_r_data_0[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[41] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[42] && db2_s1_io_r_data_0[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[42] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[43] && db2_s1_io_r_data_0[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[43] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[44] && db2_s1_io_r_data_0[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[44] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[45] && db2_s1_io_r_data_0[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[45] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[46] && db2_s1_io_r_data_0[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[46] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[47] && db2_s1_io_r_data_0[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[47] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[48] && db2_s1_io_r_data_0[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[48] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[49] && db2_s1_io_r_data_0[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[49] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[50] && db2_s1_io_r_data_0[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[50] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[51] && db2_s1_io_r_data_0[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[51] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[52] && db2_s1_io_r_data_0[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[52] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[53] && db2_s1_io_r_data_0[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[53] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[54] && db2_s1_io_r_data_0[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[54] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[55] && db2_s1_io_r_data_0[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[55] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[56] && db2_s1_io_r_data_0[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[56] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[57] && db2_s1_io_r_data_0[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[57] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[58] && db2_s1_io_r_data_0[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[58] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[59] && db2_s1_io_r_data_0[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[59] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[60] && db2_s1_io_r_data_0[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[60] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[61] && db2_s1_io_r_data_0[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[61] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[62] && db2_s1_io_r_data_0[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[62] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[63] && db2_s1_io_r_data_0[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[63] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[64] && db2_s1_io_r_data_0[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[64] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[65] && db2_s1_io_r_data_0[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[65] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[66] && db2_s1_io_r_data_0[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[66] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[67] && db2_s1_io_r_data_0[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[67] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[68] && db2_s1_io_r_data_0[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[68] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[69] && db2_s1_io_r_data_0[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[69] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[70] && db2_s1_io_r_data_0[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[70] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_0[71] && db2_s1_io_r_data_0[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_0[71] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[0] && db2_s1_io_r_data_1[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[0] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[1] && db2_s1_io_r_data_1[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[1] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[2] && db2_s1_io_r_data_1[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[2] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[3] && db2_s1_io_r_data_1[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[3] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[4] && db2_s1_io_r_data_1[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[4] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[5] && db2_s1_io_r_data_1[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[5] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[6] && db2_s1_io_r_data_1[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[6] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[7] && db2_s1_io_r_data_1[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[7] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[8] && db2_s1_io_r_data_1[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[8] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[9] && db2_s1_io_r_data_1[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[9] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[10] && db2_s1_io_r_data_1[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[10] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[11] && db2_s1_io_r_data_1[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[11] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[12] && db2_s1_io_r_data_1[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[12] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[13] && db2_s1_io_r_data_1[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[13] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[14] && db2_s1_io_r_data_1[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[14] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[15] && db2_s1_io_r_data_1[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[15] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[16] && db2_s1_io_r_data_1[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[16] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[17] && db2_s1_io_r_data_1[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[17] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[18] && db2_s1_io_r_data_1[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[18] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[19] && db2_s1_io_r_data_1[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[19] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[20] && db2_s1_io_r_data_1[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[20] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[21] && db2_s1_io_r_data_1[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[21] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[22] && db2_s1_io_r_data_1[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[22] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[23] && db2_s1_io_r_data_1[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[23] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[24] && db2_s1_io_r_data_1[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[24] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[25] && db2_s1_io_r_data_1[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[25] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[26] && db2_s1_io_r_data_1[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[26] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[27] && db2_s1_io_r_data_1[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[27] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[28] && db2_s1_io_r_data_1[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[28] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[29] && db2_s1_io_r_data_1[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[29] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[30] && db2_s1_io_r_data_1[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[30] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[31] && db2_s1_io_r_data_1[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[31] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[32] && db2_s1_io_r_data_1[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[32] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[33] && db2_s1_io_r_data_1[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[33] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[34] && db2_s1_io_r_data_1[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[34] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[35] && db2_s1_io_r_data_1[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[35] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[36] && db2_s1_io_r_data_1[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[36] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[37] && db2_s1_io_r_data_1[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[37] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[38] && db2_s1_io_r_data_1[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[38] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[39] && db2_s1_io_r_data_1[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[39] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[40] && db2_s1_io_r_data_1[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[40] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[41] && db2_s1_io_r_data_1[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[41] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[42] && db2_s1_io_r_data_1[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[42] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[43] && db2_s1_io_r_data_1[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[43] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[44] && db2_s1_io_r_data_1[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[44] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[45] && db2_s1_io_r_data_1[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[45] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[46] && db2_s1_io_r_data_1[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[46] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[47] && db2_s1_io_r_data_1[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[47] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[48] && db2_s1_io_r_data_1[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[48] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[49] && db2_s1_io_r_data_1[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[49] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[50] && db2_s1_io_r_data_1[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[50] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[51] && db2_s1_io_r_data_1[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[51] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[52] && db2_s1_io_r_data_1[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[52] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[53] && db2_s1_io_r_data_1[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[53] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[54] && db2_s1_io_r_data_1[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[54] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[55] && db2_s1_io_r_data_1[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[55] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[56] && db2_s1_io_r_data_1[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[56] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[57] && db2_s1_io_r_data_1[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[57] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[58] && db2_s1_io_r_data_1[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[58] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[59] && db2_s1_io_r_data_1[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[59] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[60] && db2_s1_io_r_data_1[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[60] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[61] && db2_s1_io_r_data_1[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[61] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[62] && db2_s1_io_r_data_1[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[62] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[63] && db2_s1_io_r_data_1[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[63] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[64] && db2_s1_io_r_data_1[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[64] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[65] && db2_s1_io_r_data_1[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[65] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[66] && db2_s1_io_r_data_1[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[66] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[67] && db2_s1_io_r_data_1[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[67] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[68] && db2_s1_io_r_data_1[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[68] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[69] && db2_s1_io_r_data_1[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[69] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[70] && db2_s1_io_r_data_1[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[70] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_1[71] && db2_s1_io_r_data_1[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_1[71] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[0] && db2_s1_io_r_data_2[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[0] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[1] && db2_s1_io_r_data_2[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[1] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[2] && db2_s1_io_r_data_2[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[2] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[3] && db2_s1_io_r_data_2[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[3] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[4] && db2_s1_io_r_data_2[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[4] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[5] && db2_s1_io_r_data_2[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[5] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[6] && db2_s1_io_r_data_2[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[6] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[7] && db2_s1_io_r_data_2[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[7] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[8] && db2_s1_io_r_data_2[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[8] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[9] && db2_s1_io_r_data_2[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[9] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[10] && db2_s1_io_r_data_2[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[10] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[11] && db2_s1_io_r_data_2[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[11] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[12] && db2_s1_io_r_data_2[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[12] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[13] && db2_s1_io_r_data_2[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[13] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[14] && db2_s1_io_r_data_2[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[14] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[15] && db2_s1_io_r_data_2[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[15] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[16] && db2_s1_io_r_data_2[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[16] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[17] && db2_s1_io_r_data_2[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[17] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[18] && db2_s1_io_r_data_2[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[18] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[19] && db2_s1_io_r_data_2[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[19] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[20] && db2_s1_io_r_data_2[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[20] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[21] && db2_s1_io_r_data_2[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[21] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[22] && db2_s1_io_r_data_2[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[22] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[23] && db2_s1_io_r_data_2[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[23] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[24] && db2_s1_io_r_data_2[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[24] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[25] && db2_s1_io_r_data_2[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[25] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[26] && db2_s1_io_r_data_2[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[26] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[27] && db2_s1_io_r_data_2[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[27] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[28] && db2_s1_io_r_data_2[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[28] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[29] && db2_s1_io_r_data_2[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[29] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[30] && db2_s1_io_r_data_2[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[30] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[31] && db2_s1_io_r_data_2[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[31] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[32] && db2_s1_io_r_data_2[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[32] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[33] && db2_s1_io_r_data_2[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[33] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[34] && db2_s1_io_r_data_2[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[34] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[35] && db2_s1_io_r_data_2[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[35] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[36] && db2_s1_io_r_data_2[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[36] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[37] && db2_s1_io_r_data_2[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[37] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[38] && db2_s1_io_r_data_2[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[38] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[39] && db2_s1_io_r_data_2[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[39] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[40] && db2_s1_io_r_data_2[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[40] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[41] && db2_s1_io_r_data_2[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[41] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[42] && db2_s1_io_r_data_2[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[42] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[43] && db2_s1_io_r_data_2[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[43] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[44] && db2_s1_io_r_data_2[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[44] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[45] && db2_s1_io_r_data_2[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[45] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[46] && db2_s1_io_r_data_2[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[46] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[47] && db2_s1_io_r_data_2[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[47] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[48] && db2_s1_io_r_data_2[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[48] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[49] && db2_s1_io_r_data_2[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[49] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[50] && db2_s1_io_r_data_2[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[50] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[51] && db2_s1_io_r_data_2[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[51] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[52] && db2_s1_io_r_data_2[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[52] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[53] && db2_s1_io_r_data_2[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[53] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[54] && db2_s1_io_r_data_2[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[54] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[55] && db2_s1_io_r_data_2[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[55] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[56] && db2_s1_io_r_data_2[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[56] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[57] && db2_s1_io_r_data_2[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[57] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[58] && db2_s1_io_r_data_2[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[58] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[59] && db2_s1_io_r_data_2[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[59] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[60] && db2_s1_io_r_data_2[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[60] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[61] && db2_s1_io_r_data_2[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[61] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[62] && db2_s1_io_r_data_2[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[62] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[63] && db2_s1_io_r_data_2[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[63] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[64] && db2_s1_io_r_data_2[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[64] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[65] && db2_s1_io_r_data_2[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[65] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[66] && db2_s1_io_r_data_2[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[66] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[67] && db2_s1_io_r_data_2[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[67] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[68] && db2_s1_io_r_data_2[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[68] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[69] && db2_s1_io_r_data_2[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[69] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[70] && db2_s1_io_r_data_2[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[70] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_2[71] && db2_s1_io_r_data_2[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_2[71] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[0] && db2_s1_io_r_data_3[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[0] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[1] && db2_s1_io_r_data_3[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[1] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[2] && db2_s1_io_r_data_3[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[2] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[3] && db2_s1_io_r_data_3[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[3] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[4] && db2_s1_io_r_data_3[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[4] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[5] && db2_s1_io_r_data_3[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[5] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[6] && db2_s1_io_r_data_3[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[6] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[7] && db2_s1_io_r_data_3[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[7] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[8] && db2_s1_io_r_data_3[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[8] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[9] && db2_s1_io_r_data_3[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[9] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[10] && db2_s1_io_r_data_3[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[10] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[11] && db2_s1_io_r_data_3[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[11] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[12] && db2_s1_io_r_data_3[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[12] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[13] && db2_s1_io_r_data_3[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[13] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[14] && db2_s1_io_r_data_3[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[14] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[15] && db2_s1_io_r_data_3[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[15] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[16] && db2_s1_io_r_data_3[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[16] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[17] && db2_s1_io_r_data_3[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[17] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[18] && db2_s1_io_r_data_3[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[18] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[19] && db2_s1_io_r_data_3[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[19] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[20] && db2_s1_io_r_data_3[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[20] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[21] && db2_s1_io_r_data_3[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[21] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[22] && db2_s1_io_r_data_3[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[22] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[23] && db2_s1_io_r_data_3[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[23] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[24] && db2_s1_io_r_data_3[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[24] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[25] && db2_s1_io_r_data_3[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[25] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[26] && db2_s1_io_r_data_3[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[26] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[27] && db2_s1_io_r_data_3[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[27] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[28] && db2_s1_io_r_data_3[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[28] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[29] && db2_s1_io_r_data_3[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[29] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[30] && db2_s1_io_r_data_3[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[30] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[31] && db2_s1_io_r_data_3[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[31] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[32] && db2_s1_io_r_data_3[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[32] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[33] && db2_s1_io_r_data_3[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[33] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[34] && db2_s1_io_r_data_3[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[34] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[35] && db2_s1_io_r_data_3[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[35] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[36] && db2_s1_io_r_data_3[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[36] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[37] && db2_s1_io_r_data_3[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[37] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[38] && db2_s1_io_r_data_3[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[38] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[39] && db2_s1_io_r_data_3[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[39] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[40] && db2_s1_io_r_data_3[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[40] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[41] && db2_s1_io_r_data_3[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[41] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[42] && db2_s1_io_r_data_3[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[42] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[43] && db2_s1_io_r_data_3[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[43] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[44] && db2_s1_io_r_data_3[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[44] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[45] && db2_s1_io_r_data_3[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[45] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[46] && db2_s1_io_r_data_3[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[46] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[47] && db2_s1_io_r_data_3[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[47] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[48] && db2_s1_io_r_data_3[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[48] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[49] && db2_s1_io_r_data_3[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[49] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[50] && db2_s1_io_r_data_3[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[50] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[51] && db2_s1_io_r_data_3[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[51] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[52] && db2_s1_io_r_data_3[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[52] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[53] && db2_s1_io_r_data_3[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[53] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[54] && db2_s1_io_r_data_3[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[54] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[55] && db2_s1_io_r_data_3[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[55] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[56] && db2_s1_io_r_data_3[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[56] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[57] && db2_s1_io_r_data_3[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[57] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[58] && db2_s1_io_r_data_3[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[58] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[59] && db2_s1_io_r_data_3[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[59] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[60] && db2_s1_io_r_data_3[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[60] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[61] && db2_s1_io_r_data_3[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[61] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[62] && db2_s1_io_r_data_3[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[62] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[63] && db2_s1_io_r_data_3[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[63] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[64] && db2_s1_io_r_data_3[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[64] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[65] && db2_s1_io_r_data_3[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[65] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[66] && db2_s1_io_r_data_3[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[66] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[67] && db2_s1_io_r_data_3[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[67] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[68] && db2_s1_io_r_data_3[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[68] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[69] && db2_s1_io_r_data_3[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[69] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[70] && db2_s1_io_r_data_3[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[70] 未见过 0 和 1"); end
    if (!(db2_s0_io_r_data_3[71] && db2_s1_io_r_data_3[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.io_r_data_3[71] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[0] && db2_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[1] && db2_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[2] && db2_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[3] && db2_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[4] && db2_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[5] && db2_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[6] && db2_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[7] && db2_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[8] && db2_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[9] && db2_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[10] && db2_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[11] && db2_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[12] && db2_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[13] && db2_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[14] && db2_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[15] && db2_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[16] && db2_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[17] && db2_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[18] && db2_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[19] && db2_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[20] && db2_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[21] && db2_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[22] && db2_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[23] && db2_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[24] && db2_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[25] && db2_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[26] && db2_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[27] && db2_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[28] && db2_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[29] && db2_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[30] && db2_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[31] && db2_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[32] && db2_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[33] && db2_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[34] && db2_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[35] && db2_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[36] && db2_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[37] && db2_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[38] && db2_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[39] && db2_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[40] && db2_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[41] && db2_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[42] && db2_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[43] && db2_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[44] && db2_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[45] && db2_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[46] && db2_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[47] && db2_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[48] && db2_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[49] && db2_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[50] && db2_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[51] && db2_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[52] && db2_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[53] && db2_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[54] && db2_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[55] && db2_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[56] && db2_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[57] && db2_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[58] && db2_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[59] && db2_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[60] && db2_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[61] && db2_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[62] && db2_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[63] && db2_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[64] && db2_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[65] && db2_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[66] && db2_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[67] && db2_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[68] && db2_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[69] && db2_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[70] && db2_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_rdata[71] && db2_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[0] && db2_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[1] && db2_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[2] && db2_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[3] && db2_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[4] && db2_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[5] && db2_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[6] && db2_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[7] && db2_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[8] && db2_s1_boreChildrenBd_bore_1_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[8] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[9] && db2_s1_boreChildrenBd_bore_1_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[9] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[10] && db2_s1_boreChildrenBd_bore_1_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[10] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[11] && db2_s1_boreChildrenBd_bore_1_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[11] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[12] && db2_s1_boreChildrenBd_bore_1_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[12] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[13] && db2_s1_boreChildrenBd_bore_1_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[13] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[14] && db2_s1_boreChildrenBd_bore_1_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[14] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[15] && db2_s1_boreChildrenBd_bore_1_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[15] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[16] && db2_s1_boreChildrenBd_bore_1_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[16] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[17] && db2_s1_boreChildrenBd_bore_1_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[17] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[18] && db2_s1_boreChildrenBd_bore_1_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[18] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[19] && db2_s1_boreChildrenBd_bore_1_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[19] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[20] && db2_s1_boreChildrenBd_bore_1_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[20] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[21] && db2_s1_boreChildrenBd_bore_1_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[21] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[22] && db2_s1_boreChildrenBd_bore_1_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[22] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[23] && db2_s1_boreChildrenBd_bore_1_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[23] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[24] && db2_s1_boreChildrenBd_bore_1_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[24] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[25] && db2_s1_boreChildrenBd_bore_1_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[25] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[26] && db2_s1_boreChildrenBd_bore_1_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[26] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[27] && db2_s1_boreChildrenBd_bore_1_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[27] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[28] && db2_s1_boreChildrenBd_bore_1_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[28] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[29] && db2_s1_boreChildrenBd_bore_1_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[29] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[30] && db2_s1_boreChildrenBd_bore_1_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[30] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[31] && db2_s1_boreChildrenBd_bore_1_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[31] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[32] && db2_s1_boreChildrenBd_bore_1_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[32] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[33] && db2_s1_boreChildrenBd_bore_1_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[33] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[34] && db2_s1_boreChildrenBd_bore_1_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[34] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[35] && db2_s1_boreChildrenBd_bore_1_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[35] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[36] && db2_s1_boreChildrenBd_bore_1_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[36] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[37] && db2_s1_boreChildrenBd_bore_1_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[37] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[38] && db2_s1_boreChildrenBd_bore_1_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[38] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[39] && db2_s1_boreChildrenBd_bore_1_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[39] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[40] && db2_s1_boreChildrenBd_bore_1_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[40] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[41] && db2_s1_boreChildrenBd_bore_1_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[41] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[42] && db2_s1_boreChildrenBd_bore_1_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[42] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[43] && db2_s1_boreChildrenBd_bore_1_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[43] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[44] && db2_s1_boreChildrenBd_bore_1_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[44] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[45] && db2_s1_boreChildrenBd_bore_1_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[45] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[46] && db2_s1_boreChildrenBd_bore_1_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[46] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[47] && db2_s1_boreChildrenBd_bore_1_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[47] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[48] && db2_s1_boreChildrenBd_bore_1_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[48] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[49] && db2_s1_boreChildrenBd_bore_1_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[49] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[50] && db2_s1_boreChildrenBd_bore_1_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[50] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[51] && db2_s1_boreChildrenBd_bore_1_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[51] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[52] && db2_s1_boreChildrenBd_bore_1_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[52] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[53] && db2_s1_boreChildrenBd_bore_1_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[53] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[54] && db2_s1_boreChildrenBd_bore_1_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[54] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[55] && db2_s1_boreChildrenBd_bore_1_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[55] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[56] && db2_s1_boreChildrenBd_bore_1_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[56] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[57] && db2_s1_boreChildrenBd_bore_1_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[57] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[58] && db2_s1_boreChildrenBd_bore_1_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[58] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[59] && db2_s1_boreChildrenBd_bore_1_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[59] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[60] && db2_s1_boreChildrenBd_bore_1_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[60] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[61] && db2_s1_boreChildrenBd_bore_1_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[61] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[62] && db2_s1_boreChildrenBd_bore_1_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[62] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[63] && db2_s1_boreChildrenBd_bore_1_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[63] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[64] && db2_s1_boreChildrenBd_bore_1_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[64] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[65] && db2_s1_boreChildrenBd_bore_1_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[65] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[66] && db2_s1_boreChildrenBd_bore_1_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[66] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[67] && db2_s1_boreChildrenBd_bore_1_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[67] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[68] && db2_s1_boreChildrenBd_bore_1_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[68] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[69] && db2_s1_boreChildrenBd_bore_1_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[69] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[70] && db2_s1_boreChildrenBd_bore_1_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[70] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_1_rdata[71] && db2_s1_boreChildrenBd_bore_1_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_1_rdata[71] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[0] && db2_s1_boreChildrenBd_bore_2_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[0] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[1] && db2_s1_boreChildrenBd_bore_2_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[1] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[2] && db2_s1_boreChildrenBd_bore_2_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[2] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[3] && db2_s1_boreChildrenBd_bore_2_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[3] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[4] && db2_s1_boreChildrenBd_bore_2_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[4] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[5] && db2_s1_boreChildrenBd_bore_2_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[5] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[6] && db2_s1_boreChildrenBd_bore_2_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[6] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[7] && db2_s1_boreChildrenBd_bore_2_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[7] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[8] && db2_s1_boreChildrenBd_bore_2_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[8] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[9] && db2_s1_boreChildrenBd_bore_2_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[9] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[10] && db2_s1_boreChildrenBd_bore_2_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[10] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[11] && db2_s1_boreChildrenBd_bore_2_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[11] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[12] && db2_s1_boreChildrenBd_bore_2_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[12] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[13] && db2_s1_boreChildrenBd_bore_2_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[13] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[14] && db2_s1_boreChildrenBd_bore_2_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[14] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[15] && db2_s1_boreChildrenBd_bore_2_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[15] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[16] && db2_s1_boreChildrenBd_bore_2_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[16] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[17] && db2_s1_boreChildrenBd_bore_2_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[17] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[18] && db2_s1_boreChildrenBd_bore_2_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[18] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[19] && db2_s1_boreChildrenBd_bore_2_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[19] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[20] && db2_s1_boreChildrenBd_bore_2_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[20] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[21] && db2_s1_boreChildrenBd_bore_2_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[21] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[22] && db2_s1_boreChildrenBd_bore_2_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[22] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[23] && db2_s1_boreChildrenBd_bore_2_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[23] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[24] && db2_s1_boreChildrenBd_bore_2_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[24] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[25] && db2_s1_boreChildrenBd_bore_2_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[25] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[26] && db2_s1_boreChildrenBd_bore_2_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[26] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[27] && db2_s1_boreChildrenBd_bore_2_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[27] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[28] && db2_s1_boreChildrenBd_bore_2_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[28] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[29] && db2_s1_boreChildrenBd_bore_2_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[29] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[30] && db2_s1_boreChildrenBd_bore_2_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[30] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[31] && db2_s1_boreChildrenBd_bore_2_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[31] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[32] && db2_s1_boreChildrenBd_bore_2_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[32] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[33] && db2_s1_boreChildrenBd_bore_2_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[33] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[34] && db2_s1_boreChildrenBd_bore_2_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[34] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[35] && db2_s1_boreChildrenBd_bore_2_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[35] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[36] && db2_s1_boreChildrenBd_bore_2_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[36] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[37] && db2_s1_boreChildrenBd_bore_2_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[37] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[38] && db2_s1_boreChildrenBd_bore_2_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[38] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[39] && db2_s1_boreChildrenBd_bore_2_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[39] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[40] && db2_s1_boreChildrenBd_bore_2_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[40] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[41] && db2_s1_boreChildrenBd_bore_2_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[41] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[42] && db2_s1_boreChildrenBd_bore_2_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[42] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[43] && db2_s1_boreChildrenBd_bore_2_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[43] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[44] && db2_s1_boreChildrenBd_bore_2_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[44] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[45] && db2_s1_boreChildrenBd_bore_2_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[45] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[46] && db2_s1_boreChildrenBd_bore_2_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[46] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[47] && db2_s1_boreChildrenBd_bore_2_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[47] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[48] && db2_s1_boreChildrenBd_bore_2_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[48] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[49] && db2_s1_boreChildrenBd_bore_2_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[49] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[50] && db2_s1_boreChildrenBd_bore_2_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[50] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[51] && db2_s1_boreChildrenBd_bore_2_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[51] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[52] && db2_s1_boreChildrenBd_bore_2_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[52] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[53] && db2_s1_boreChildrenBd_bore_2_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[53] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[54] && db2_s1_boreChildrenBd_bore_2_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[54] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[55] && db2_s1_boreChildrenBd_bore_2_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[55] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[56] && db2_s1_boreChildrenBd_bore_2_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[56] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[57] && db2_s1_boreChildrenBd_bore_2_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[57] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[58] && db2_s1_boreChildrenBd_bore_2_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[58] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[59] && db2_s1_boreChildrenBd_bore_2_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[59] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[60] && db2_s1_boreChildrenBd_bore_2_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[60] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[61] && db2_s1_boreChildrenBd_bore_2_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[61] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[62] && db2_s1_boreChildrenBd_bore_2_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[62] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[63] && db2_s1_boreChildrenBd_bore_2_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[63] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[64] && db2_s1_boreChildrenBd_bore_2_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[64] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[65] && db2_s1_boreChildrenBd_bore_2_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[65] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[66] && db2_s1_boreChildrenBd_bore_2_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[66] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[67] && db2_s1_boreChildrenBd_bore_2_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[67] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[68] && db2_s1_boreChildrenBd_bore_2_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[68] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[69] && db2_s1_boreChildrenBd_bore_2_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[69] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[70] && db2_s1_boreChildrenBd_bore_2_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[70] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_2_rdata[71] && db2_s1_boreChildrenBd_bore_2_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_2_rdata[71] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[0] && db2_s1_boreChildrenBd_bore_3_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[0] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[1] && db2_s1_boreChildrenBd_bore_3_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[1] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[2] && db2_s1_boreChildrenBd_bore_3_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[2] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[3] && db2_s1_boreChildrenBd_bore_3_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[3] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[4] && db2_s1_boreChildrenBd_bore_3_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[4] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[5] && db2_s1_boreChildrenBd_bore_3_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[5] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[6] && db2_s1_boreChildrenBd_bore_3_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[6] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[7] && db2_s1_boreChildrenBd_bore_3_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[7] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[8] && db2_s1_boreChildrenBd_bore_3_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[8] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[9] && db2_s1_boreChildrenBd_bore_3_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[9] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[10] && db2_s1_boreChildrenBd_bore_3_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[10] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[11] && db2_s1_boreChildrenBd_bore_3_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[11] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[12] && db2_s1_boreChildrenBd_bore_3_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[12] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[13] && db2_s1_boreChildrenBd_bore_3_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[13] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[14] && db2_s1_boreChildrenBd_bore_3_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[14] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[15] && db2_s1_boreChildrenBd_bore_3_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[15] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[16] && db2_s1_boreChildrenBd_bore_3_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[16] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[17] && db2_s1_boreChildrenBd_bore_3_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[17] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[18] && db2_s1_boreChildrenBd_bore_3_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[18] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[19] && db2_s1_boreChildrenBd_bore_3_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[19] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[20] && db2_s1_boreChildrenBd_bore_3_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[20] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[21] && db2_s1_boreChildrenBd_bore_3_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[21] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[22] && db2_s1_boreChildrenBd_bore_3_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[22] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[23] && db2_s1_boreChildrenBd_bore_3_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[23] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[24] && db2_s1_boreChildrenBd_bore_3_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[24] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[25] && db2_s1_boreChildrenBd_bore_3_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[25] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[26] && db2_s1_boreChildrenBd_bore_3_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[26] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[27] && db2_s1_boreChildrenBd_bore_3_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[27] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[28] && db2_s1_boreChildrenBd_bore_3_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[28] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[29] && db2_s1_boreChildrenBd_bore_3_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[29] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[30] && db2_s1_boreChildrenBd_bore_3_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[30] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[31] && db2_s1_boreChildrenBd_bore_3_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[31] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[32] && db2_s1_boreChildrenBd_bore_3_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[32] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[33] && db2_s1_boreChildrenBd_bore_3_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[33] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[34] && db2_s1_boreChildrenBd_bore_3_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[34] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[35] && db2_s1_boreChildrenBd_bore_3_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[35] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[36] && db2_s1_boreChildrenBd_bore_3_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[36] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[37] && db2_s1_boreChildrenBd_bore_3_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[37] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[38] && db2_s1_boreChildrenBd_bore_3_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[38] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[39] && db2_s1_boreChildrenBd_bore_3_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[39] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[40] && db2_s1_boreChildrenBd_bore_3_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[40] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[41] && db2_s1_boreChildrenBd_bore_3_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[41] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[42] && db2_s1_boreChildrenBd_bore_3_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[42] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[43] && db2_s1_boreChildrenBd_bore_3_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[43] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[44] && db2_s1_boreChildrenBd_bore_3_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[44] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[45] && db2_s1_boreChildrenBd_bore_3_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[45] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[46] && db2_s1_boreChildrenBd_bore_3_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[46] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[47] && db2_s1_boreChildrenBd_bore_3_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[47] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[48] && db2_s1_boreChildrenBd_bore_3_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[48] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[49] && db2_s1_boreChildrenBd_bore_3_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[49] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[50] && db2_s1_boreChildrenBd_bore_3_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[50] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[51] && db2_s1_boreChildrenBd_bore_3_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[51] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[52] && db2_s1_boreChildrenBd_bore_3_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[52] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[53] && db2_s1_boreChildrenBd_bore_3_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[53] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[54] && db2_s1_boreChildrenBd_bore_3_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[54] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[55] && db2_s1_boreChildrenBd_bore_3_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[55] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[56] && db2_s1_boreChildrenBd_bore_3_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[56] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[57] && db2_s1_boreChildrenBd_bore_3_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[57] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[58] && db2_s1_boreChildrenBd_bore_3_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[58] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[59] && db2_s1_boreChildrenBd_bore_3_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[59] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[60] && db2_s1_boreChildrenBd_bore_3_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[60] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[61] && db2_s1_boreChildrenBd_bore_3_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[61] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[62] && db2_s1_boreChildrenBd_bore_3_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[62] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[63] && db2_s1_boreChildrenBd_bore_3_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[63] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[64] && db2_s1_boreChildrenBd_bore_3_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[64] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[65] && db2_s1_boreChildrenBd_bore_3_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[65] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[66] && db2_s1_boreChildrenBd_bore_3_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[66] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[67] && db2_s1_boreChildrenBd_bore_3_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[67] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[68] && db2_s1_boreChildrenBd_bore_3_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[68] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[69] && db2_s1_boreChildrenBd_bore_3_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[69] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[70] && db2_s1_boreChildrenBd_bore_3_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[70] 未见过 0 和 1"); end
    if (!(db2_s0_boreChildrenBd_bore_3_rdata[71] && db2_s1_boreChildrenBd_bore_3_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_2.boreChildrenBd_bore_3_rdata[71] 未见过 0 和 1"); end
    $display("[ARM] DataSRAMBank_2 armed_at=%0d", db2_armed_at);
    if (db2_armed_at < 0) begin cov_fail++; $display("[ARM] DataSRAMBank_2 从未 arm"); end
    $display("[COV] DataSRAMBank_2.multi_way_write = %0d", db2_cov_multi_way_write);
    if (db2_cov_multi_way_write < 200) begin cov_fail++; $display("[COV] DataSRAMBank_2.multi_way_write < 200"); end
    $display("[COV] DataSRAMBank_2.read = %0d", db2_cov_read);
    if (db2_cov_read < 200) begin cov_fail++; $display("[COV] DataSRAMBank_2.read < 200"); end
    $display("[COV] DataSRAMBank_2.mbist_we = %0d", db2_cov_mbist_we);
    if (db2_cov_mbist_we < 200) begin cov_fail++; $display("[COV] DataSRAMBank_2.mbist_we < 200"); end
    if (!(db4_s0_io_r_data_0[0] && db4_s1_io_r_data_0[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[0] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[1] && db4_s1_io_r_data_0[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[1] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[2] && db4_s1_io_r_data_0[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[2] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[3] && db4_s1_io_r_data_0[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[3] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[4] && db4_s1_io_r_data_0[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[4] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[5] && db4_s1_io_r_data_0[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[5] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[6] && db4_s1_io_r_data_0[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[6] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[7] && db4_s1_io_r_data_0[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[7] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[8] && db4_s1_io_r_data_0[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[8] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[9] && db4_s1_io_r_data_0[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[9] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[10] && db4_s1_io_r_data_0[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[10] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[11] && db4_s1_io_r_data_0[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[11] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[12] && db4_s1_io_r_data_0[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[12] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[13] && db4_s1_io_r_data_0[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[13] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[14] && db4_s1_io_r_data_0[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[14] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[15] && db4_s1_io_r_data_0[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[15] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[16] && db4_s1_io_r_data_0[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[16] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[17] && db4_s1_io_r_data_0[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[17] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[18] && db4_s1_io_r_data_0[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[18] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[19] && db4_s1_io_r_data_0[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[19] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[20] && db4_s1_io_r_data_0[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[20] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[21] && db4_s1_io_r_data_0[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[21] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[22] && db4_s1_io_r_data_0[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[22] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[23] && db4_s1_io_r_data_0[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[23] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[24] && db4_s1_io_r_data_0[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[24] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[25] && db4_s1_io_r_data_0[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[25] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[26] && db4_s1_io_r_data_0[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[26] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[27] && db4_s1_io_r_data_0[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[27] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[28] && db4_s1_io_r_data_0[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[28] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[29] && db4_s1_io_r_data_0[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[29] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[30] && db4_s1_io_r_data_0[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[30] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[31] && db4_s1_io_r_data_0[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[31] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[32] && db4_s1_io_r_data_0[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[32] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[33] && db4_s1_io_r_data_0[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[33] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[34] && db4_s1_io_r_data_0[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[34] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[35] && db4_s1_io_r_data_0[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[35] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[36] && db4_s1_io_r_data_0[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[36] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[37] && db4_s1_io_r_data_0[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[37] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[38] && db4_s1_io_r_data_0[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[38] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[39] && db4_s1_io_r_data_0[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[39] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[40] && db4_s1_io_r_data_0[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[40] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[41] && db4_s1_io_r_data_0[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[41] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[42] && db4_s1_io_r_data_0[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[42] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[43] && db4_s1_io_r_data_0[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[43] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[44] && db4_s1_io_r_data_0[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[44] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[45] && db4_s1_io_r_data_0[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[45] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[46] && db4_s1_io_r_data_0[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[46] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[47] && db4_s1_io_r_data_0[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[47] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[48] && db4_s1_io_r_data_0[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[48] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[49] && db4_s1_io_r_data_0[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[49] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[50] && db4_s1_io_r_data_0[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[50] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[51] && db4_s1_io_r_data_0[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[51] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[52] && db4_s1_io_r_data_0[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[52] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[53] && db4_s1_io_r_data_0[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[53] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[54] && db4_s1_io_r_data_0[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[54] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[55] && db4_s1_io_r_data_0[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[55] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[56] && db4_s1_io_r_data_0[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[56] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[57] && db4_s1_io_r_data_0[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[57] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[58] && db4_s1_io_r_data_0[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[58] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[59] && db4_s1_io_r_data_0[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[59] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[60] && db4_s1_io_r_data_0[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[60] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[61] && db4_s1_io_r_data_0[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[61] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[62] && db4_s1_io_r_data_0[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[62] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[63] && db4_s1_io_r_data_0[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[63] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[64] && db4_s1_io_r_data_0[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[64] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[65] && db4_s1_io_r_data_0[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[65] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[66] && db4_s1_io_r_data_0[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[66] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[67] && db4_s1_io_r_data_0[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[67] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[68] && db4_s1_io_r_data_0[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[68] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[69] && db4_s1_io_r_data_0[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[69] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[70] && db4_s1_io_r_data_0[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[70] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_0[71] && db4_s1_io_r_data_0[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_0[71] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[0] && db4_s1_io_r_data_1[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[0] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[1] && db4_s1_io_r_data_1[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[1] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[2] && db4_s1_io_r_data_1[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[2] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[3] && db4_s1_io_r_data_1[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[3] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[4] && db4_s1_io_r_data_1[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[4] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[5] && db4_s1_io_r_data_1[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[5] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[6] && db4_s1_io_r_data_1[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[6] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[7] && db4_s1_io_r_data_1[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[7] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[8] && db4_s1_io_r_data_1[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[8] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[9] && db4_s1_io_r_data_1[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[9] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[10] && db4_s1_io_r_data_1[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[10] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[11] && db4_s1_io_r_data_1[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[11] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[12] && db4_s1_io_r_data_1[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[12] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[13] && db4_s1_io_r_data_1[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[13] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[14] && db4_s1_io_r_data_1[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[14] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[15] && db4_s1_io_r_data_1[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[15] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[16] && db4_s1_io_r_data_1[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[16] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[17] && db4_s1_io_r_data_1[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[17] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[18] && db4_s1_io_r_data_1[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[18] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[19] && db4_s1_io_r_data_1[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[19] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[20] && db4_s1_io_r_data_1[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[20] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[21] && db4_s1_io_r_data_1[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[21] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[22] && db4_s1_io_r_data_1[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[22] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[23] && db4_s1_io_r_data_1[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[23] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[24] && db4_s1_io_r_data_1[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[24] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[25] && db4_s1_io_r_data_1[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[25] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[26] && db4_s1_io_r_data_1[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[26] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[27] && db4_s1_io_r_data_1[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[27] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[28] && db4_s1_io_r_data_1[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[28] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[29] && db4_s1_io_r_data_1[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[29] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[30] && db4_s1_io_r_data_1[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[30] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[31] && db4_s1_io_r_data_1[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[31] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[32] && db4_s1_io_r_data_1[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[32] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[33] && db4_s1_io_r_data_1[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[33] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[34] && db4_s1_io_r_data_1[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[34] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[35] && db4_s1_io_r_data_1[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[35] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[36] && db4_s1_io_r_data_1[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[36] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[37] && db4_s1_io_r_data_1[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[37] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[38] && db4_s1_io_r_data_1[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[38] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[39] && db4_s1_io_r_data_1[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[39] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[40] && db4_s1_io_r_data_1[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[40] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[41] && db4_s1_io_r_data_1[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[41] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[42] && db4_s1_io_r_data_1[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[42] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[43] && db4_s1_io_r_data_1[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[43] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[44] && db4_s1_io_r_data_1[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[44] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[45] && db4_s1_io_r_data_1[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[45] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[46] && db4_s1_io_r_data_1[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[46] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[47] && db4_s1_io_r_data_1[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[47] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[48] && db4_s1_io_r_data_1[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[48] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[49] && db4_s1_io_r_data_1[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[49] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[50] && db4_s1_io_r_data_1[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[50] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[51] && db4_s1_io_r_data_1[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[51] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[52] && db4_s1_io_r_data_1[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[52] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[53] && db4_s1_io_r_data_1[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[53] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[54] && db4_s1_io_r_data_1[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[54] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[55] && db4_s1_io_r_data_1[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[55] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[56] && db4_s1_io_r_data_1[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[56] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[57] && db4_s1_io_r_data_1[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[57] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[58] && db4_s1_io_r_data_1[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[58] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[59] && db4_s1_io_r_data_1[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[59] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[60] && db4_s1_io_r_data_1[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[60] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[61] && db4_s1_io_r_data_1[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[61] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[62] && db4_s1_io_r_data_1[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[62] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[63] && db4_s1_io_r_data_1[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[63] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[64] && db4_s1_io_r_data_1[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[64] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[65] && db4_s1_io_r_data_1[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[65] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[66] && db4_s1_io_r_data_1[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[66] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[67] && db4_s1_io_r_data_1[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[67] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[68] && db4_s1_io_r_data_1[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[68] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[69] && db4_s1_io_r_data_1[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[69] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[70] && db4_s1_io_r_data_1[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[70] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_1[71] && db4_s1_io_r_data_1[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_1[71] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[0] && db4_s1_io_r_data_2[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[0] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[1] && db4_s1_io_r_data_2[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[1] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[2] && db4_s1_io_r_data_2[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[2] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[3] && db4_s1_io_r_data_2[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[3] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[4] && db4_s1_io_r_data_2[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[4] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[5] && db4_s1_io_r_data_2[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[5] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[6] && db4_s1_io_r_data_2[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[6] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[7] && db4_s1_io_r_data_2[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[7] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[8] && db4_s1_io_r_data_2[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[8] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[9] && db4_s1_io_r_data_2[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[9] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[10] && db4_s1_io_r_data_2[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[10] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[11] && db4_s1_io_r_data_2[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[11] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[12] && db4_s1_io_r_data_2[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[12] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[13] && db4_s1_io_r_data_2[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[13] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[14] && db4_s1_io_r_data_2[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[14] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[15] && db4_s1_io_r_data_2[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[15] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[16] && db4_s1_io_r_data_2[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[16] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[17] && db4_s1_io_r_data_2[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[17] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[18] && db4_s1_io_r_data_2[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[18] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[19] && db4_s1_io_r_data_2[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[19] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[20] && db4_s1_io_r_data_2[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[20] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[21] && db4_s1_io_r_data_2[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[21] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[22] && db4_s1_io_r_data_2[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[22] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[23] && db4_s1_io_r_data_2[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[23] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[24] && db4_s1_io_r_data_2[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[24] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[25] && db4_s1_io_r_data_2[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[25] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[26] && db4_s1_io_r_data_2[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[26] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[27] && db4_s1_io_r_data_2[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[27] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[28] && db4_s1_io_r_data_2[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[28] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[29] && db4_s1_io_r_data_2[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[29] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[30] && db4_s1_io_r_data_2[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[30] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[31] && db4_s1_io_r_data_2[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[31] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[32] && db4_s1_io_r_data_2[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[32] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[33] && db4_s1_io_r_data_2[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[33] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[34] && db4_s1_io_r_data_2[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[34] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[35] && db4_s1_io_r_data_2[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[35] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[36] && db4_s1_io_r_data_2[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[36] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[37] && db4_s1_io_r_data_2[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[37] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[38] && db4_s1_io_r_data_2[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[38] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[39] && db4_s1_io_r_data_2[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[39] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[40] && db4_s1_io_r_data_2[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[40] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[41] && db4_s1_io_r_data_2[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[41] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[42] && db4_s1_io_r_data_2[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[42] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[43] && db4_s1_io_r_data_2[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[43] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[44] && db4_s1_io_r_data_2[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[44] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[45] && db4_s1_io_r_data_2[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[45] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[46] && db4_s1_io_r_data_2[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[46] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[47] && db4_s1_io_r_data_2[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[47] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[48] && db4_s1_io_r_data_2[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[48] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[49] && db4_s1_io_r_data_2[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[49] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[50] && db4_s1_io_r_data_2[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[50] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[51] && db4_s1_io_r_data_2[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[51] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[52] && db4_s1_io_r_data_2[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[52] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[53] && db4_s1_io_r_data_2[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[53] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[54] && db4_s1_io_r_data_2[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[54] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[55] && db4_s1_io_r_data_2[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[55] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[56] && db4_s1_io_r_data_2[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[56] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[57] && db4_s1_io_r_data_2[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[57] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[58] && db4_s1_io_r_data_2[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[58] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[59] && db4_s1_io_r_data_2[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[59] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[60] && db4_s1_io_r_data_2[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[60] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[61] && db4_s1_io_r_data_2[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[61] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[62] && db4_s1_io_r_data_2[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[62] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[63] && db4_s1_io_r_data_2[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[63] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[64] && db4_s1_io_r_data_2[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[64] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[65] && db4_s1_io_r_data_2[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[65] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[66] && db4_s1_io_r_data_2[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[66] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[67] && db4_s1_io_r_data_2[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[67] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[68] && db4_s1_io_r_data_2[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[68] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[69] && db4_s1_io_r_data_2[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[69] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[70] && db4_s1_io_r_data_2[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[70] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_2[71] && db4_s1_io_r_data_2[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_2[71] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[0] && db4_s1_io_r_data_3[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[0] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[1] && db4_s1_io_r_data_3[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[1] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[2] && db4_s1_io_r_data_3[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[2] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[3] && db4_s1_io_r_data_3[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[3] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[4] && db4_s1_io_r_data_3[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[4] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[5] && db4_s1_io_r_data_3[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[5] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[6] && db4_s1_io_r_data_3[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[6] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[7] && db4_s1_io_r_data_3[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[7] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[8] && db4_s1_io_r_data_3[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[8] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[9] && db4_s1_io_r_data_3[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[9] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[10] && db4_s1_io_r_data_3[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[10] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[11] && db4_s1_io_r_data_3[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[11] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[12] && db4_s1_io_r_data_3[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[12] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[13] && db4_s1_io_r_data_3[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[13] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[14] && db4_s1_io_r_data_3[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[14] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[15] && db4_s1_io_r_data_3[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[15] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[16] && db4_s1_io_r_data_3[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[16] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[17] && db4_s1_io_r_data_3[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[17] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[18] && db4_s1_io_r_data_3[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[18] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[19] && db4_s1_io_r_data_3[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[19] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[20] && db4_s1_io_r_data_3[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[20] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[21] && db4_s1_io_r_data_3[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[21] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[22] && db4_s1_io_r_data_3[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[22] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[23] && db4_s1_io_r_data_3[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[23] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[24] && db4_s1_io_r_data_3[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[24] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[25] && db4_s1_io_r_data_3[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[25] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[26] && db4_s1_io_r_data_3[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[26] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[27] && db4_s1_io_r_data_3[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[27] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[28] && db4_s1_io_r_data_3[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[28] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[29] && db4_s1_io_r_data_3[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[29] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[30] && db4_s1_io_r_data_3[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[30] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[31] && db4_s1_io_r_data_3[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[31] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[32] && db4_s1_io_r_data_3[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[32] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[33] && db4_s1_io_r_data_3[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[33] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[34] && db4_s1_io_r_data_3[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[34] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[35] && db4_s1_io_r_data_3[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[35] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[36] && db4_s1_io_r_data_3[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[36] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[37] && db4_s1_io_r_data_3[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[37] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[38] && db4_s1_io_r_data_3[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[38] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[39] && db4_s1_io_r_data_3[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[39] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[40] && db4_s1_io_r_data_3[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[40] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[41] && db4_s1_io_r_data_3[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[41] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[42] && db4_s1_io_r_data_3[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[42] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[43] && db4_s1_io_r_data_3[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[43] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[44] && db4_s1_io_r_data_3[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[44] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[45] && db4_s1_io_r_data_3[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[45] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[46] && db4_s1_io_r_data_3[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[46] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[47] && db4_s1_io_r_data_3[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[47] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[48] && db4_s1_io_r_data_3[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[48] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[49] && db4_s1_io_r_data_3[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[49] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[50] && db4_s1_io_r_data_3[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[50] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[51] && db4_s1_io_r_data_3[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[51] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[52] && db4_s1_io_r_data_3[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[52] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[53] && db4_s1_io_r_data_3[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[53] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[54] && db4_s1_io_r_data_3[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[54] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[55] && db4_s1_io_r_data_3[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[55] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[56] && db4_s1_io_r_data_3[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[56] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[57] && db4_s1_io_r_data_3[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[57] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[58] && db4_s1_io_r_data_3[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[58] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[59] && db4_s1_io_r_data_3[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[59] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[60] && db4_s1_io_r_data_3[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[60] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[61] && db4_s1_io_r_data_3[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[61] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[62] && db4_s1_io_r_data_3[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[62] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[63] && db4_s1_io_r_data_3[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[63] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[64] && db4_s1_io_r_data_3[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[64] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[65] && db4_s1_io_r_data_3[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[65] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[66] && db4_s1_io_r_data_3[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[66] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[67] && db4_s1_io_r_data_3[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[67] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[68] && db4_s1_io_r_data_3[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[68] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[69] && db4_s1_io_r_data_3[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[69] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[70] && db4_s1_io_r_data_3[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[70] 未见过 0 和 1"); end
    if (!(db4_s0_io_r_data_3[71] && db4_s1_io_r_data_3[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.io_r_data_3[71] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[0] && db4_s1_boreChildrenBd_bore_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[0] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[1] && db4_s1_boreChildrenBd_bore_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[1] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[2] && db4_s1_boreChildrenBd_bore_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[2] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[3] && db4_s1_boreChildrenBd_bore_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[3] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[4] && db4_s1_boreChildrenBd_bore_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[4] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[5] && db4_s1_boreChildrenBd_bore_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[5] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[6] && db4_s1_boreChildrenBd_bore_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[6] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[7] && db4_s1_boreChildrenBd_bore_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[7] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[8] && db4_s1_boreChildrenBd_bore_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[8] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[9] && db4_s1_boreChildrenBd_bore_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[9] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[10] && db4_s1_boreChildrenBd_bore_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[10] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[11] && db4_s1_boreChildrenBd_bore_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[11] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[12] && db4_s1_boreChildrenBd_bore_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[12] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[13] && db4_s1_boreChildrenBd_bore_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[13] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[14] && db4_s1_boreChildrenBd_bore_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[14] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[15] && db4_s1_boreChildrenBd_bore_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[15] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[16] && db4_s1_boreChildrenBd_bore_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[16] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[17] && db4_s1_boreChildrenBd_bore_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[17] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[18] && db4_s1_boreChildrenBd_bore_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[18] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[19] && db4_s1_boreChildrenBd_bore_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[19] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[20] && db4_s1_boreChildrenBd_bore_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[20] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[21] && db4_s1_boreChildrenBd_bore_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[21] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[22] && db4_s1_boreChildrenBd_bore_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[22] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[23] && db4_s1_boreChildrenBd_bore_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[23] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[24] && db4_s1_boreChildrenBd_bore_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[24] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[25] && db4_s1_boreChildrenBd_bore_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[25] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[26] && db4_s1_boreChildrenBd_bore_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[26] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[27] && db4_s1_boreChildrenBd_bore_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[27] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[28] && db4_s1_boreChildrenBd_bore_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[28] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[29] && db4_s1_boreChildrenBd_bore_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[29] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[30] && db4_s1_boreChildrenBd_bore_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[30] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[31] && db4_s1_boreChildrenBd_bore_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[31] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[32] && db4_s1_boreChildrenBd_bore_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[32] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[33] && db4_s1_boreChildrenBd_bore_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[33] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[34] && db4_s1_boreChildrenBd_bore_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[34] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[35] && db4_s1_boreChildrenBd_bore_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[35] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[36] && db4_s1_boreChildrenBd_bore_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[36] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[37] && db4_s1_boreChildrenBd_bore_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[37] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[38] && db4_s1_boreChildrenBd_bore_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[38] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[39] && db4_s1_boreChildrenBd_bore_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[39] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[40] && db4_s1_boreChildrenBd_bore_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[40] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[41] && db4_s1_boreChildrenBd_bore_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[41] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[42] && db4_s1_boreChildrenBd_bore_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[42] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[43] && db4_s1_boreChildrenBd_bore_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[43] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[44] && db4_s1_boreChildrenBd_bore_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[44] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[45] && db4_s1_boreChildrenBd_bore_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[45] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[46] && db4_s1_boreChildrenBd_bore_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[46] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[47] && db4_s1_boreChildrenBd_bore_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[47] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[48] && db4_s1_boreChildrenBd_bore_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[48] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[49] && db4_s1_boreChildrenBd_bore_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[49] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[50] && db4_s1_boreChildrenBd_bore_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[50] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[51] && db4_s1_boreChildrenBd_bore_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[51] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[52] && db4_s1_boreChildrenBd_bore_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[52] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[53] && db4_s1_boreChildrenBd_bore_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[53] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[54] && db4_s1_boreChildrenBd_bore_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[54] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[55] && db4_s1_boreChildrenBd_bore_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[55] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[56] && db4_s1_boreChildrenBd_bore_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[56] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[57] && db4_s1_boreChildrenBd_bore_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[57] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[58] && db4_s1_boreChildrenBd_bore_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[58] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[59] && db4_s1_boreChildrenBd_bore_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[59] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[60] && db4_s1_boreChildrenBd_bore_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[60] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[61] && db4_s1_boreChildrenBd_bore_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[61] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[62] && db4_s1_boreChildrenBd_bore_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[62] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[63] && db4_s1_boreChildrenBd_bore_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[63] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[64] && db4_s1_boreChildrenBd_bore_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[64] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[65] && db4_s1_boreChildrenBd_bore_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[65] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[66] && db4_s1_boreChildrenBd_bore_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[66] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[67] && db4_s1_boreChildrenBd_bore_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[67] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[68] && db4_s1_boreChildrenBd_bore_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[68] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[69] && db4_s1_boreChildrenBd_bore_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[69] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[70] && db4_s1_boreChildrenBd_bore_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[70] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_rdata[71] && db4_s1_boreChildrenBd_bore_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_rdata[71] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[0] && db4_s1_boreChildrenBd_bore_1_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[0] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[1] && db4_s1_boreChildrenBd_bore_1_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[1] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[2] && db4_s1_boreChildrenBd_bore_1_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[2] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[3] && db4_s1_boreChildrenBd_bore_1_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[3] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[4] && db4_s1_boreChildrenBd_bore_1_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[4] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[5] && db4_s1_boreChildrenBd_bore_1_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[5] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[6] && db4_s1_boreChildrenBd_bore_1_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[6] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[7] && db4_s1_boreChildrenBd_bore_1_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[7] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[8] && db4_s1_boreChildrenBd_bore_1_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[8] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[9] && db4_s1_boreChildrenBd_bore_1_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[9] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[10] && db4_s1_boreChildrenBd_bore_1_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[10] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[11] && db4_s1_boreChildrenBd_bore_1_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[11] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[12] && db4_s1_boreChildrenBd_bore_1_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[12] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[13] && db4_s1_boreChildrenBd_bore_1_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[13] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[14] && db4_s1_boreChildrenBd_bore_1_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[14] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[15] && db4_s1_boreChildrenBd_bore_1_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[15] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[16] && db4_s1_boreChildrenBd_bore_1_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[16] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[17] && db4_s1_boreChildrenBd_bore_1_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[17] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[18] && db4_s1_boreChildrenBd_bore_1_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[18] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[19] && db4_s1_boreChildrenBd_bore_1_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[19] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[20] && db4_s1_boreChildrenBd_bore_1_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[20] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[21] && db4_s1_boreChildrenBd_bore_1_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[21] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[22] && db4_s1_boreChildrenBd_bore_1_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[22] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[23] && db4_s1_boreChildrenBd_bore_1_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[23] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[24] && db4_s1_boreChildrenBd_bore_1_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[24] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[25] && db4_s1_boreChildrenBd_bore_1_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[25] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[26] && db4_s1_boreChildrenBd_bore_1_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[26] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[27] && db4_s1_boreChildrenBd_bore_1_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[27] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[28] && db4_s1_boreChildrenBd_bore_1_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[28] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[29] && db4_s1_boreChildrenBd_bore_1_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[29] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[30] && db4_s1_boreChildrenBd_bore_1_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[30] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[31] && db4_s1_boreChildrenBd_bore_1_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[31] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[32] && db4_s1_boreChildrenBd_bore_1_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[32] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[33] && db4_s1_boreChildrenBd_bore_1_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[33] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[34] && db4_s1_boreChildrenBd_bore_1_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[34] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[35] && db4_s1_boreChildrenBd_bore_1_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[35] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[36] && db4_s1_boreChildrenBd_bore_1_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[36] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[37] && db4_s1_boreChildrenBd_bore_1_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[37] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[38] && db4_s1_boreChildrenBd_bore_1_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[38] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[39] && db4_s1_boreChildrenBd_bore_1_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[39] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[40] && db4_s1_boreChildrenBd_bore_1_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[40] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[41] && db4_s1_boreChildrenBd_bore_1_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[41] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[42] && db4_s1_boreChildrenBd_bore_1_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[42] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[43] && db4_s1_boreChildrenBd_bore_1_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[43] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[44] && db4_s1_boreChildrenBd_bore_1_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[44] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[45] && db4_s1_boreChildrenBd_bore_1_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[45] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[46] && db4_s1_boreChildrenBd_bore_1_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[46] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[47] && db4_s1_boreChildrenBd_bore_1_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[47] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[48] && db4_s1_boreChildrenBd_bore_1_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[48] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[49] && db4_s1_boreChildrenBd_bore_1_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[49] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[50] && db4_s1_boreChildrenBd_bore_1_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[50] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[51] && db4_s1_boreChildrenBd_bore_1_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[51] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[52] && db4_s1_boreChildrenBd_bore_1_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[52] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[53] && db4_s1_boreChildrenBd_bore_1_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[53] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[54] && db4_s1_boreChildrenBd_bore_1_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[54] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[55] && db4_s1_boreChildrenBd_bore_1_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[55] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[56] && db4_s1_boreChildrenBd_bore_1_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[56] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[57] && db4_s1_boreChildrenBd_bore_1_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[57] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[58] && db4_s1_boreChildrenBd_bore_1_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[58] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[59] && db4_s1_boreChildrenBd_bore_1_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[59] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[60] && db4_s1_boreChildrenBd_bore_1_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[60] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[61] && db4_s1_boreChildrenBd_bore_1_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[61] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[62] && db4_s1_boreChildrenBd_bore_1_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[62] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[63] && db4_s1_boreChildrenBd_bore_1_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[63] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[64] && db4_s1_boreChildrenBd_bore_1_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[64] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[65] && db4_s1_boreChildrenBd_bore_1_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[65] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[66] && db4_s1_boreChildrenBd_bore_1_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[66] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[67] && db4_s1_boreChildrenBd_bore_1_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[67] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[68] && db4_s1_boreChildrenBd_bore_1_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[68] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[69] && db4_s1_boreChildrenBd_bore_1_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[69] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[70] && db4_s1_boreChildrenBd_bore_1_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[70] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_1_rdata[71] && db4_s1_boreChildrenBd_bore_1_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_1_rdata[71] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[0] && db4_s1_boreChildrenBd_bore_2_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[0] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[1] && db4_s1_boreChildrenBd_bore_2_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[1] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[2] && db4_s1_boreChildrenBd_bore_2_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[2] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[3] && db4_s1_boreChildrenBd_bore_2_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[3] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[4] && db4_s1_boreChildrenBd_bore_2_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[4] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[5] && db4_s1_boreChildrenBd_bore_2_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[5] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[6] && db4_s1_boreChildrenBd_bore_2_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[6] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[7] && db4_s1_boreChildrenBd_bore_2_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[7] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[8] && db4_s1_boreChildrenBd_bore_2_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[8] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[9] && db4_s1_boreChildrenBd_bore_2_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[9] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[10] && db4_s1_boreChildrenBd_bore_2_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[10] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[11] && db4_s1_boreChildrenBd_bore_2_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[11] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[12] && db4_s1_boreChildrenBd_bore_2_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[12] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[13] && db4_s1_boreChildrenBd_bore_2_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[13] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[14] && db4_s1_boreChildrenBd_bore_2_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[14] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[15] && db4_s1_boreChildrenBd_bore_2_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[15] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[16] && db4_s1_boreChildrenBd_bore_2_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[16] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[17] && db4_s1_boreChildrenBd_bore_2_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[17] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[18] && db4_s1_boreChildrenBd_bore_2_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[18] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[19] && db4_s1_boreChildrenBd_bore_2_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[19] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[20] && db4_s1_boreChildrenBd_bore_2_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[20] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[21] && db4_s1_boreChildrenBd_bore_2_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[21] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[22] && db4_s1_boreChildrenBd_bore_2_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[22] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[23] && db4_s1_boreChildrenBd_bore_2_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[23] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[24] && db4_s1_boreChildrenBd_bore_2_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[24] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[25] && db4_s1_boreChildrenBd_bore_2_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[25] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[26] && db4_s1_boreChildrenBd_bore_2_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[26] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[27] && db4_s1_boreChildrenBd_bore_2_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[27] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[28] && db4_s1_boreChildrenBd_bore_2_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[28] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[29] && db4_s1_boreChildrenBd_bore_2_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[29] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[30] && db4_s1_boreChildrenBd_bore_2_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[30] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[31] && db4_s1_boreChildrenBd_bore_2_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[31] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[32] && db4_s1_boreChildrenBd_bore_2_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[32] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[33] && db4_s1_boreChildrenBd_bore_2_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[33] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[34] && db4_s1_boreChildrenBd_bore_2_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[34] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[35] && db4_s1_boreChildrenBd_bore_2_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[35] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[36] && db4_s1_boreChildrenBd_bore_2_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[36] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[37] && db4_s1_boreChildrenBd_bore_2_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[37] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[38] && db4_s1_boreChildrenBd_bore_2_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[38] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[39] && db4_s1_boreChildrenBd_bore_2_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[39] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[40] && db4_s1_boreChildrenBd_bore_2_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[40] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[41] && db4_s1_boreChildrenBd_bore_2_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[41] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[42] && db4_s1_boreChildrenBd_bore_2_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[42] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[43] && db4_s1_boreChildrenBd_bore_2_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[43] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[44] && db4_s1_boreChildrenBd_bore_2_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[44] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[45] && db4_s1_boreChildrenBd_bore_2_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[45] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[46] && db4_s1_boreChildrenBd_bore_2_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[46] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[47] && db4_s1_boreChildrenBd_bore_2_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[47] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[48] && db4_s1_boreChildrenBd_bore_2_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[48] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[49] && db4_s1_boreChildrenBd_bore_2_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[49] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[50] && db4_s1_boreChildrenBd_bore_2_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[50] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[51] && db4_s1_boreChildrenBd_bore_2_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[51] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[52] && db4_s1_boreChildrenBd_bore_2_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[52] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[53] && db4_s1_boreChildrenBd_bore_2_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[53] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[54] && db4_s1_boreChildrenBd_bore_2_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[54] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[55] && db4_s1_boreChildrenBd_bore_2_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[55] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[56] && db4_s1_boreChildrenBd_bore_2_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[56] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[57] && db4_s1_boreChildrenBd_bore_2_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[57] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[58] && db4_s1_boreChildrenBd_bore_2_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[58] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[59] && db4_s1_boreChildrenBd_bore_2_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[59] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[60] && db4_s1_boreChildrenBd_bore_2_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[60] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[61] && db4_s1_boreChildrenBd_bore_2_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[61] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[62] && db4_s1_boreChildrenBd_bore_2_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[62] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[63] && db4_s1_boreChildrenBd_bore_2_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[63] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[64] && db4_s1_boreChildrenBd_bore_2_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[64] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[65] && db4_s1_boreChildrenBd_bore_2_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[65] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[66] && db4_s1_boreChildrenBd_bore_2_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[66] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[67] && db4_s1_boreChildrenBd_bore_2_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[67] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[68] && db4_s1_boreChildrenBd_bore_2_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[68] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[69] && db4_s1_boreChildrenBd_bore_2_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[69] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[70] && db4_s1_boreChildrenBd_bore_2_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[70] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_2_rdata[71] && db4_s1_boreChildrenBd_bore_2_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_2_rdata[71] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[0] && db4_s1_boreChildrenBd_bore_3_rdata[0])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[0] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[1] && db4_s1_boreChildrenBd_bore_3_rdata[1])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[1] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[2] && db4_s1_boreChildrenBd_bore_3_rdata[2])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[2] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[3] && db4_s1_boreChildrenBd_bore_3_rdata[3])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[3] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[4] && db4_s1_boreChildrenBd_bore_3_rdata[4])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[4] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[5] && db4_s1_boreChildrenBd_bore_3_rdata[5])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[5] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[6] && db4_s1_boreChildrenBd_bore_3_rdata[6])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[6] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[7] && db4_s1_boreChildrenBd_bore_3_rdata[7])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[7] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[8] && db4_s1_boreChildrenBd_bore_3_rdata[8])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[8] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[9] && db4_s1_boreChildrenBd_bore_3_rdata[9])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[9] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[10] && db4_s1_boreChildrenBd_bore_3_rdata[10])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[10] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[11] && db4_s1_boreChildrenBd_bore_3_rdata[11])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[11] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[12] && db4_s1_boreChildrenBd_bore_3_rdata[12])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[12] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[13] && db4_s1_boreChildrenBd_bore_3_rdata[13])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[13] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[14] && db4_s1_boreChildrenBd_bore_3_rdata[14])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[14] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[15] && db4_s1_boreChildrenBd_bore_3_rdata[15])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[15] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[16] && db4_s1_boreChildrenBd_bore_3_rdata[16])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[16] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[17] && db4_s1_boreChildrenBd_bore_3_rdata[17])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[17] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[18] && db4_s1_boreChildrenBd_bore_3_rdata[18])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[18] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[19] && db4_s1_boreChildrenBd_bore_3_rdata[19])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[19] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[20] && db4_s1_boreChildrenBd_bore_3_rdata[20])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[20] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[21] && db4_s1_boreChildrenBd_bore_3_rdata[21])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[21] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[22] && db4_s1_boreChildrenBd_bore_3_rdata[22])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[22] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[23] && db4_s1_boreChildrenBd_bore_3_rdata[23])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[23] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[24] && db4_s1_boreChildrenBd_bore_3_rdata[24])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[24] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[25] && db4_s1_boreChildrenBd_bore_3_rdata[25])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[25] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[26] && db4_s1_boreChildrenBd_bore_3_rdata[26])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[26] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[27] && db4_s1_boreChildrenBd_bore_3_rdata[27])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[27] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[28] && db4_s1_boreChildrenBd_bore_3_rdata[28])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[28] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[29] && db4_s1_boreChildrenBd_bore_3_rdata[29])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[29] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[30] && db4_s1_boreChildrenBd_bore_3_rdata[30])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[30] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[31] && db4_s1_boreChildrenBd_bore_3_rdata[31])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[31] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[32] && db4_s1_boreChildrenBd_bore_3_rdata[32])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[32] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[33] && db4_s1_boreChildrenBd_bore_3_rdata[33])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[33] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[34] && db4_s1_boreChildrenBd_bore_3_rdata[34])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[34] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[35] && db4_s1_boreChildrenBd_bore_3_rdata[35])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[35] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[36] && db4_s1_boreChildrenBd_bore_3_rdata[36])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[36] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[37] && db4_s1_boreChildrenBd_bore_3_rdata[37])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[37] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[38] && db4_s1_boreChildrenBd_bore_3_rdata[38])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[38] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[39] && db4_s1_boreChildrenBd_bore_3_rdata[39])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[39] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[40] && db4_s1_boreChildrenBd_bore_3_rdata[40])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[40] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[41] && db4_s1_boreChildrenBd_bore_3_rdata[41])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[41] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[42] && db4_s1_boreChildrenBd_bore_3_rdata[42])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[42] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[43] && db4_s1_boreChildrenBd_bore_3_rdata[43])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[43] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[44] && db4_s1_boreChildrenBd_bore_3_rdata[44])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[44] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[45] && db4_s1_boreChildrenBd_bore_3_rdata[45])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[45] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[46] && db4_s1_boreChildrenBd_bore_3_rdata[46])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[46] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[47] && db4_s1_boreChildrenBd_bore_3_rdata[47])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[47] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[48] && db4_s1_boreChildrenBd_bore_3_rdata[48])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[48] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[49] && db4_s1_boreChildrenBd_bore_3_rdata[49])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[49] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[50] && db4_s1_boreChildrenBd_bore_3_rdata[50])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[50] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[51] && db4_s1_boreChildrenBd_bore_3_rdata[51])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[51] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[52] && db4_s1_boreChildrenBd_bore_3_rdata[52])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[52] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[53] && db4_s1_boreChildrenBd_bore_3_rdata[53])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[53] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[54] && db4_s1_boreChildrenBd_bore_3_rdata[54])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[54] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[55] && db4_s1_boreChildrenBd_bore_3_rdata[55])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[55] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[56] && db4_s1_boreChildrenBd_bore_3_rdata[56])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[56] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[57] && db4_s1_boreChildrenBd_bore_3_rdata[57])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[57] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[58] && db4_s1_boreChildrenBd_bore_3_rdata[58])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[58] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[59] && db4_s1_boreChildrenBd_bore_3_rdata[59])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[59] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[60] && db4_s1_boreChildrenBd_bore_3_rdata[60])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[60] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[61] && db4_s1_boreChildrenBd_bore_3_rdata[61])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[61] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[62] && db4_s1_boreChildrenBd_bore_3_rdata[62])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[62] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[63] && db4_s1_boreChildrenBd_bore_3_rdata[63])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[63] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[64] && db4_s1_boreChildrenBd_bore_3_rdata[64])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[64] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[65] && db4_s1_boreChildrenBd_bore_3_rdata[65])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[65] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[66] && db4_s1_boreChildrenBd_bore_3_rdata[66])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[66] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[67] && db4_s1_boreChildrenBd_bore_3_rdata[67])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[67] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[68] && db4_s1_boreChildrenBd_bore_3_rdata[68])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[68] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[69] && db4_s1_boreChildrenBd_bore_3_rdata[69])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[69] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[70] && db4_s1_boreChildrenBd_bore_3_rdata[70])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[70] 未见过 0 和 1"); end
    if (!(db4_s0_boreChildrenBd_bore_3_rdata[71] && db4_s1_boreChildrenBd_bore_3_rdata[71])) begin cov_fail++; $display("[COV] DataSRAMBank_4.boreChildrenBd_bore_3_rdata[71] 未见过 0 和 1"); end
    $display("[ARM] DataSRAMBank_4 armed_at=%0d", db4_armed_at);
    if (db4_armed_at < 0) begin cov_fail++; $display("[ARM] DataSRAMBank_4 从未 arm"); end
    $display("[COV] DataSRAMBank_4.multi_way_write = %0d", db4_cov_multi_way_write);
    if (db4_cov_multi_way_write < 200) begin cov_fail++; $display("[COV] DataSRAMBank_4.multi_way_write < 200"); end
    $display("[COV] DataSRAMBank_4.read = %0d", db4_cov_read);
    if (db4_cov_read < 200) begin cov_fail++; $display("[COV] DataSRAMBank_4.read < 200"); end
    $display("[COV] DataSRAMBank_4.mbist_we = %0d", db4_cov_mbist_we);
    if (db4_cov_mbist_we < 200) begin cov_fail++; $display("[COV] DataSRAMBank_4.mbist_we < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
