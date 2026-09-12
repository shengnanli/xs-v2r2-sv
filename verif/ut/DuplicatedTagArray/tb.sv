// 自动生成: scripts/gen_dtagarray.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int WARMUP = 300;   // 跳过上电逐组清零 + 复位窗口
  int errors = 0, checks = 0;
  logic clock = 0, reset;
  always #5 clock = ~clock;
  logic io_read_0_valid;
  logic [7:0] io_read_0_bits_idx;
  logic io_read_1_valid;
  logic [7:0] io_read_1_bits_idx;
  logic io_read_2_valid;
  logic [7:0] io_read_2_bits_idx;
  logic io_read_3_valid;
  logic [7:0] io_read_3_bits_idx;
  logic io_write_valid;
  logic [7:0] io_write_bits_idx;
  logic [3:0] io_write_bits_way_en;
  logic [35:0] io_write_bits_tag;
  logic [5:0] boreChildrenBd_bore_array;
  logic boreChildrenBd_bore_all;
  logic boreChildrenBd_bore_req;
  logic boreChildrenBd_bore_writeen;
  logic [1:0] boreChildrenBd_bore_be;
  logic [8:0] boreChildrenBd_bore_addr;
  logic [85:0] boreChildrenBd_bore_indata;
  logic boreChildrenBd_bore_readen;
  logic [8:0] boreChildrenBd_bore_addr_rd;
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
  wire g_io_read_3_ready;  wire i_io_read_3_ready;
  wire [42:0] g_io_resp_0_0;  wire [42:0] i_io_resp_0_0;
  wire [42:0] g_io_resp_0_1;  wire [42:0] i_io_resp_0_1;
  wire [42:0] g_io_resp_0_2;  wire [42:0] i_io_resp_0_2;
  wire [42:0] g_io_resp_0_3;  wire [42:0] i_io_resp_0_3;
  wire [42:0] g_io_resp_1_0;  wire [42:0] i_io_resp_1_0;
  wire [42:0] g_io_resp_1_1;  wire [42:0] i_io_resp_1_1;
  wire [42:0] g_io_resp_1_2;  wire [42:0] i_io_resp_1_2;
  wire [42:0] g_io_resp_1_3;  wire [42:0] i_io_resp_1_3;
  wire [42:0] g_io_resp_2_0;  wire [42:0] i_io_resp_2_0;
  wire [42:0] g_io_resp_2_1;  wire [42:0] i_io_resp_2_1;
  wire [42:0] g_io_resp_2_2;  wire [42:0] i_io_resp_2_2;
  wire [42:0] g_io_resp_2_3;  wire [42:0] i_io_resp_2_3;
  wire [42:0] g_io_resp_3_0;  wire [42:0] i_io_resp_3_0;
  wire [42:0] g_io_resp_3_1;  wire [42:0] i_io_resp_3_1;
  wire [42:0] g_io_resp_3_2;  wire [42:0] i_io_resp_3_2;
  wire [42:0] g_io_resp_3_3;  wire [42:0] i_io_resp_3_3;
  wire g_boreChildrenBd_bore_ack;  wire i_boreChildrenBd_bore_ack;
  wire [85:0] g_boreChildrenBd_bore_outdata;  wire [85:0] i_boreChildrenBd_bore_outdata;
  DuplicatedTagArray g_u (.clock(clock), .reset(reset), .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx), .io_write_valid(io_write_valid), .io_write_bits_idx(io_write_bits_idx), .io_write_bits_way_en(io_write_bits_way_en), .io_write_bits_tag(io_write_bits_tag), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .io_read_3_ready(g_io_read_3_ready), .io_resp_0_0(g_io_resp_0_0), .io_resp_0_1(g_io_resp_0_1), .io_resp_0_2(g_io_resp_0_2), .io_resp_0_3(g_io_resp_0_3), .io_resp_1_0(g_io_resp_1_0), .io_resp_1_1(g_io_resp_1_1), .io_resp_1_2(g_io_resp_1_2), .io_resp_1_3(g_io_resp_1_3), .io_resp_2_0(g_io_resp_2_0), .io_resp_2_1(g_io_resp_2_1), .io_resp_2_2(g_io_resp_2_2), .io_resp_2_3(g_io_resp_2_3), .io_resp_3_0(g_io_resp_3_0), .io_resp_3_1(g_io_resp_3_1), .io_resp_3_2(g_io_resp_3_2), .io_resp_3_3(g_io_resp_3_3), .boreChildrenBd_bore_ack(g_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(g_boreChildrenBd_bore_outdata));
  DuplicatedTagArray_xs i_u (.clock(clock), .reset(reset), .io_read_0_valid(io_read_0_valid), .io_read_0_bits_idx(io_read_0_bits_idx), .io_read_1_valid(io_read_1_valid), .io_read_1_bits_idx(io_read_1_bits_idx), .io_read_2_valid(io_read_2_valid), .io_read_2_bits_idx(io_read_2_bits_idx), .io_read_3_valid(io_read_3_valid), .io_read_3_bits_idx(io_read_3_bits_idx), .io_write_valid(io_write_valid), .io_write_bits_idx(io_write_bits_idx), .io_write_bits_way_en(io_write_bits_way_en), .io_write_bits_tag(io_write_bits_tag), .boreChildrenBd_bore_array(boreChildrenBd_bore_array), .boreChildrenBd_bore_all(boreChildrenBd_bore_all), .boreChildrenBd_bore_req(boreChildrenBd_bore_req), .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen), .boreChildrenBd_bore_be(boreChildrenBd_bore_be), .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata), .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd), .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold), .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass), .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk), .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold), .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen), .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold), .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass), .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk), .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold), .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen), .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold), .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass), .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk), .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold), .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen), .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold), .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass), .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk), .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold), .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen), .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold), .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass), .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk), .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold), .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen), .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold), .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass), .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk), .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold), .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen), .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold), .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass), .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk), .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold), .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen), .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold), .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass), .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk), .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold), .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen), .io_read_3_ready(i_io_read_3_ready), .io_resp_0_0(i_io_resp_0_0), .io_resp_0_1(i_io_resp_0_1), .io_resp_0_2(i_io_resp_0_2), .io_resp_0_3(i_io_resp_0_3), .io_resp_1_0(i_io_resp_1_0), .io_resp_1_1(i_io_resp_1_1), .io_resp_1_2(i_io_resp_1_2), .io_resp_1_3(i_io_resp_1_3), .io_resp_2_0(i_io_resp_2_0), .io_resp_2_1(i_io_resp_2_1), .io_resp_2_2(i_io_resp_2_2), .io_resp_2_3(i_io_resp_2_3), .io_resp_3_0(i_io_resp_3_0), .io_resp_3_1(i_io_resp_3_1), .io_resp_3_2(i_io_resp_3_2), .io_resp_3_3(i_io_resp_3_3), .boreChildrenBd_bore_ack(i_boreChildrenBd_bore_ack), .boreChildrenBd_bore_outdata(i_boreChildrenBd_bore_outdata));
  task automatic do_check(int t);
    checks++;
    if (!$isunknown(g_io_read_3_ready) && (g_io_read_3_ready !== i_io_read_3_ready)) begin errors++;
      if(errors<=60) $display("vec %0d io_read_3_ready g=%h i=%h",t,g_io_read_3_ready,i_io_read_3_ready); end
    if (!$isunknown(g_io_resp_0_0) && (g_io_resp_0_0 !== i_io_resp_0_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_0 g=%h i=%h",t,g_io_resp_0_0,i_io_resp_0_0); end
    if (!$isunknown(g_io_resp_0_1) && (g_io_resp_0_1 !== i_io_resp_0_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_1 g=%h i=%h",t,g_io_resp_0_1,i_io_resp_0_1); end
    if (!$isunknown(g_io_resp_0_2) && (g_io_resp_0_2 !== i_io_resp_0_2)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_2 g=%h i=%h",t,g_io_resp_0_2,i_io_resp_0_2); end
    if (!$isunknown(g_io_resp_0_3) && (g_io_resp_0_3 !== i_io_resp_0_3)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_0_3 g=%h i=%h",t,g_io_resp_0_3,i_io_resp_0_3); end
    if (!$isunknown(g_io_resp_1_0) && (g_io_resp_1_0 !== i_io_resp_1_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_0 g=%h i=%h",t,g_io_resp_1_0,i_io_resp_1_0); end
    if (!$isunknown(g_io_resp_1_1) && (g_io_resp_1_1 !== i_io_resp_1_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_1 g=%h i=%h",t,g_io_resp_1_1,i_io_resp_1_1); end
    if (!$isunknown(g_io_resp_1_2) && (g_io_resp_1_2 !== i_io_resp_1_2)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_2 g=%h i=%h",t,g_io_resp_1_2,i_io_resp_1_2); end
    if (!$isunknown(g_io_resp_1_3) && (g_io_resp_1_3 !== i_io_resp_1_3)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_1_3 g=%h i=%h",t,g_io_resp_1_3,i_io_resp_1_3); end
    if (!$isunknown(g_io_resp_2_0) && (g_io_resp_2_0 !== i_io_resp_2_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_0 g=%h i=%h",t,g_io_resp_2_0,i_io_resp_2_0); end
    if (!$isunknown(g_io_resp_2_1) && (g_io_resp_2_1 !== i_io_resp_2_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_1 g=%h i=%h",t,g_io_resp_2_1,i_io_resp_2_1); end
    if (!$isunknown(g_io_resp_2_2) && (g_io_resp_2_2 !== i_io_resp_2_2)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_2 g=%h i=%h",t,g_io_resp_2_2,i_io_resp_2_2); end
    if (!$isunknown(g_io_resp_2_3) && (g_io_resp_2_3 !== i_io_resp_2_3)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_2_3 g=%h i=%h",t,g_io_resp_2_3,i_io_resp_2_3); end
    if (!$isunknown(g_io_resp_3_0) && (g_io_resp_3_0 !== i_io_resp_3_0)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_0 g=%h i=%h",t,g_io_resp_3_0,i_io_resp_3_0); end
    if (!$isunknown(g_io_resp_3_1) && (g_io_resp_3_1 !== i_io_resp_3_1)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_1 g=%h i=%h",t,g_io_resp_3_1,i_io_resp_3_1); end
    if (!$isunknown(g_io_resp_3_2) && (g_io_resp_3_2 !== i_io_resp_3_2)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_2 g=%h i=%h",t,g_io_resp_3_2,i_io_resp_3_2); end
    if (!$isunknown(g_io_resp_3_3) && (g_io_resp_3_3 !== i_io_resp_3_3)) begin errors++;
      if(errors<=60) $display("vec %0d io_resp_3_3 g=%h i=%h",t,g_io_resp_3_3,i_io_resp_3_3); end
  endtask

  // MBIST / 旁带信号: 不激活 mbist (req=0), 旁带恒 0 (功能态), 仅验证读写主链
  initial begin
    boreChildrenBd_bore_array=0; boreChildrenBd_bore_all=0; boreChildrenBd_bore_req=0;
    boreChildrenBd_bore_writeen=0; boreChildrenBd_bore_be=0; boreChildrenBd_bore_addr=0;
    boreChildrenBd_bore_indata=0; boreChildrenBd_bore_readen=0; boreChildrenBd_bore_addr_rd=0;
    sigFromSrams_bore_ram_hold=0; sigFromSrams_bore_ram_bypass=0; sigFromSrams_bore_ram_bp_clken=0;
    sigFromSrams_bore_ram_aux_clk=0; sigFromSrams_bore_ram_aux_ckbp=0; sigFromSrams_bore_ram_mcp_hold=0; sigFromSrams_bore_cgen=0;
    sigFromSrams_bore_1_ram_hold=0; sigFromSrams_bore_1_ram_bypass=0; sigFromSrams_bore_1_ram_bp_clken=0;
    sigFromSrams_bore_1_ram_aux_clk=0; sigFromSrams_bore_1_ram_aux_ckbp=0; sigFromSrams_bore_1_ram_mcp_hold=0; sigFromSrams_bore_1_cgen=0;
    sigFromSrams_bore_2_ram_hold=0; sigFromSrams_bore_2_ram_bypass=0; sigFromSrams_bore_2_ram_bp_clken=0;
    sigFromSrams_bore_2_ram_aux_clk=0; sigFromSrams_bore_2_ram_aux_ckbp=0; sigFromSrams_bore_2_ram_mcp_hold=0; sigFromSrams_bore_2_cgen=0;
    sigFromSrams_bore_3_ram_hold=0; sigFromSrams_bore_3_ram_bypass=0; sigFromSrams_bore_3_ram_bp_clken=0;
    sigFromSrams_bore_3_ram_aux_clk=0; sigFromSrams_bore_3_ram_aux_ckbp=0; sigFromSrams_bore_3_ram_mcp_hold=0; sigFromSrams_bore_3_cgen=0;
    sigFromSrams_bore_4_ram_hold=0; sigFromSrams_bore_4_ram_bypass=0; sigFromSrams_bore_4_ram_bp_clken=0;
    sigFromSrams_bore_4_ram_aux_clk=0; sigFromSrams_bore_4_ram_aux_ckbp=0; sigFromSrams_bore_4_ram_mcp_hold=0; sigFromSrams_bore_4_cgen=0;
    sigFromSrams_bore_5_ram_hold=0; sigFromSrams_bore_5_ram_bypass=0; sigFromSrams_bore_5_ram_bp_clken=0;
    sigFromSrams_bore_5_ram_aux_clk=0; sigFromSrams_bore_5_ram_aux_ckbp=0; sigFromSrams_bore_5_ram_mcp_hold=0; sigFromSrams_bore_5_cgen=0;
    sigFromSrams_bore_6_ram_hold=0; sigFromSrams_bore_6_ram_bypass=0; sigFromSrams_bore_6_ram_bp_clken=0;
    sigFromSrams_bore_6_ram_aux_clk=0; sigFromSrams_bore_6_ram_aux_ckbp=0; sigFromSrams_bore_6_ram_mcp_hold=0; sigFromSrams_bore_6_cgen=0;
    sigFromSrams_bore_7_ram_hold=0; sigFromSrams_bore_7_ram_bypass=0; sigFromSrams_bore_7_ram_bp_clken=0;
    sigFromSrams_bore_7_ram_aux_clk=0; sigFromSrams_bore_7_ram_aux_ckbp=0; sigFromSrams_bore_7_ram_mcp_hold=0; sigFromSrams_bore_7_cgen=0;
  end

  // 随机激励: 4 读口 valid/idx + 偶发写 (idx/way_en/tag)
  task automatic drive();
    io_read_0_valid = $urandom; io_read_0_bits_idx = $urandom;
    io_read_1_valid = $urandom; io_read_1_bits_idx = $urandom;
    io_read_2_valid = $urandom; io_read_2_bits_idx = $urandom;
    io_read_3_valid = $urandom; io_read_3_bits_idx = $urandom;
    io_write_valid    = ($urandom % 4 == 0);  // 25% 写
    io_write_bits_idx = $urandom;
    io_write_bits_way_en = $urandom;
    io_write_bits_tag = {$urandom, $urandom};
  endtask

  initial begin
    reset = 1;
    io_read_0_valid=0; io_read_1_valid=0; io_read_2_valid=0; io_read_3_valid=0;
    io_read_0_bits_idx=0; io_read_1_bits_idx=0; io_read_2_bits_idx=0; io_read_3_bits_idx=0;
    io_write_valid=0; io_write_bits_idx=0; io_write_bits_way_en=0; io_write_bits_tag=0;
    repeat (20) @(posedge clock);
    reset = 0;
    for (int t = 0; t < NVEC; t++) begin
      drive();
      @(posedge clock);
      #1;
      if (t >= WARMUP) do_check(t);
    end
    if (errors == 0) $display("TEST PASSED  checks=%0d errors=%0d", checks, errors);
    else             $display("TEST FAILED  checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
