// 自动生成: gen_l2cache_ut.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic [5:0] mbist_array;
  logic mbist_all;
  logic mbist_req;
  logic mbist_writeen;
  logic [7:0] mbist_be;
  logic [12:0] mbist_addr;
  logic [103:0] mbist_indata;
  logic mbist_readen;
  logic [12:0] mbist_addr_rd;
  logic toNextPipeline_0_ack;
  logic [12:0] toNextPipeline_0_outdata;
  logic toNextPipeline_1_ack;
  logic [103:0] toNextPipeline_1_outdata;
  logic toNextPipeline_2_ack;
  logic [103:0] toNextPipeline_2_outdata;
  logic toNextPipeline_3_ack;
  logic [103:0] toNextPipeline_3_outdata;
  logic toNextPipeline_4_ack;
  logic [103:0] toNextPipeline_4_outdata;
  logic g_mbist_ack;
  logic i_mbist_ack;
  logic [103:0] g_mbist_outdata;
  logic [103:0] i_mbist_outdata;
  logic g_toNextPipeline_0_array;
  logic i_toNextPipeline_0_array;
  logic g_toNextPipeline_0_all;
  logic i_toNextPipeline_0_all;
  logic g_toNextPipeline_0_req;
  logic i_toNextPipeline_0_req;
  logic g_toNextPipeline_0_writeen;
  logic i_toNextPipeline_0_writeen;
  logic g_toNextPipeline_0_be;
  logic i_toNextPipeline_0_be;
  logic [8:0] g_toNextPipeline_0_addr;
  logic [8:0] i_toNextPipeline_0_addr;
  logic [12:0] g_toNextPipeline_0_indata;
  logic [12:0] i_toNextPipeline_0_indata;
  logic g_toNextPipeline_0_readen;
  logic i_toNextPipeline_0_readen;
  logic [8:0] g_toNextPipeline_0_addr_rd;
  logic [8:0] i_toNextPipeline_0_addr_rd;
  logic [4:0] g_toNextPipeline_1_array;
  logic [4:0] i_toNextPipeline_1_array;
  logic g_toNextPipeline_1_all;
  logic i_toNextPipeline_1_all;
  logic g_toNextPipeline_1_req;
  logic i_toNextPipeline_1_req;
  logic g_toNextPipeline_1_writeen;
  logic i_toNextPipeline_1_writeen;
  logic [7:0] g_toNextPipeline_1_be;
  logic [7:0] i_toNextPipeline_1_be;
  logic [12:0] g_toNextPipeline_1_addr;
  logic [12:0] i_toNextPipeline_1_addr;
  logic [103:0] g_toNextPipeline_1_indata;
  logic [103:0] i_toNextPipeline_1_indata;
  logic g_toNextPipeline_1_readen;
  logic i_toNextPipeline_1_readen;
  logic [12:0] g_toNextPipeline_1_addr_rd;
  logic [12:0] i_toNextPipeline_1_addr_rd;
  logic [4:0] g_toNextPipeline_2_array;
  logic [4:0] i_toNextPipeline_2_array;
  logic g_toNextPipeline_2_all;
  logic i_toNextPipeline_2_all;
  logic g_toNextPipeline_2_req;
  logic i_toNextPipeline_2_req;
  logic g_toNextPipeline_2_writeen;
  logic i_toNextPipeline_2_writeen;
  logic [7:0] g_toNextPipeline_2_be;
  logic [7:0] i_toNextPipeline_2_be;
  logic [12:0] g_toNextPipeline_2_addr;
  logic [12:0] i_toNextPipeline_2_addr;
  logic [103:0] g_toNextPipeline_2_indata;
  logic [103:0] i_toNextPipeline_2_indata;
  logic g_toNextPipeline_2_readen;
  logic i_toNextPipeline_2_readen;
  logic [12:0] g_toNextPipeline_2_addr_rd;
  logic [12:0] i_toNextPipeline_2_addr_rd;
  logic [5:0] g_toNextPipeline_3_array;
  logic [5:0] i_toNextPipeline_3_array;
  logic g_toNextPipeline_3_all;
  logic i_toNextPipeline_3_all;
  logic g_toNextPipeline_3_req;
  logic i_toNextPipeline_3_req;
  logic g_toNextPipeline_3_writeen;
  logic i_toNextPipeline_3_writeen;
  logic [7:0] g_toNextPipeline_3_be;
  logic [7:0] i_toNextPipeline_3_be;
  logic [12:0] g_toNextPipeline_3_addr;
  logic [12:0] i_toNextPipeline_3_addr;
  logic [103:0] g_toNextPipeline_3_indata;
  logic [103:0] i_toNextPipeline_3_indata;
  logic g_toNextPipeline_3_readen;
  logic i_toNextPipeline_3_readen;
  logic [12:0] g_toNextPipeline_3_addr_rd;
  logic [12:0] i_toNextPipeline_3_addr_rd;
  logic [5:0] g_toNextPipeline_4_array;
  logic [5:0] i_toNextPipeline_4_array;
  logic g_toNextPipeline_4_all;
  logic i_toNextPipeline_4_all;
  logic g_toNextPipeline_4_req;
  logic i_toNextPipeline_4_req;
  logic g_toNextPipeline_4_writeen;
  logic i_toNextPipeline_4_writeen;
  logic [7:0] g_toNextPipeline_4_be;
  logic [7:0] i_toNextPipeline_4_be;
  logic [12:0] g_toNextPipeline_4_addr;
  logic [12:0] i_toNextPipeline_4_addr;
  logic [103:0] g_toNextPipeline_4_indata;
  logic [103:0] i_toNextPipeline_4_indata;
  logic g_toNextPipeline_4_readen;
  logic i_toNextPipeline_4_readen;
  logic [12:0] g_toNextPipeline_4_addr_rd;
  logic [12:0] i_toNextPipeline_4_addr_rd;

  L2Cache dut_g (
    .clock(clk),
    .reset(rst),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .toNextPipeline_0_ack(toNextPipeline_0_ack),
    .toNextPipeline_0_outdata(toNextPipeline_0_outdata),
    .toNextPipeline_1_ack(toNextPipeline_1_ack),
    .toNextPipeline_1_outdata(toNextPipeline_1_outdata),
    .toNextPipeline_2_ack(toNextPipeline_2_ack),
    .toNextPipeline_2_outdata(toNextPipeline_2_outdata),
    .toNextPipeline_3_ack(toNextPipeline_3_ack),
    .toNextPipeline_3_outdata(toNextPipeline_3_outdata),
    .toNextPipeline_4_ack(toNextPipeline_4_ack),
    .toNextPipeline_4_outdata(toNextPipeline_4_outdata),
    .mbist_ack(g_mbist_ack),
    .mbist_outdata(g_mbist_outdata),
    .toNextPipeline_0_array(g_toNextPipeline_0_array),
    .toNextPipeline_0_all(g_toNextPipeline_0_all),
    .toNextPipeline_0_req(g_toNextPipeline_0_req),
    .toNextPipeline_0_writeen(g_toNextPipeline_0_writeen),
    .toNextPipeline_0_be(g_toNextPipeline_0_be),
    .toNextPipeline_0_addr(g_toNextPipeline_0_addr),
    .toNextPipeline_0_indata(g_toNextPipeline_0_indata),
    .toNextPipeline_0_readen(g_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd(g_toNextPipeline_0_addr_rd),
    .toNextPipeline_1_array(g_toNextPipeline_1_array),
    .toNextPipeline_1_all(g_toNextPipeline_1_all),
    .toNextPipeline_1_req(g_toNextPipeline_1_req),
    .toNextPipeline_1_writeen(g_toNextPipeline_1_writeen),
    .toNextPipeline_1_be(g_toNextPipeline_1_be),
    .toNextPipeline_1_addr(g_toNextPipeline_1_addr),
    .toNextPipeline_1_indata(g_toNextPipeline_1_indata),
    .toNextPipeline_1_readen(g_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd(g_toNextPipeline_1_addr_rd),
    .toNextPipeline_2_array(g_toNextPipeline_2_array),
    .toNextPipeline_2_all(g_toNextPipeline_2_all),
    .toNextPipeline_2_req(g_toNextPipeline_2_req),
    .toNextPipeline_2_writeen(g_toNextPipeline_2_writeen),
    .toNextPipeline_2_be(g_toNextPipeline_2_be),
    .toNextPipeline_2_addr(g_toNextPipeline_2_addr),
    .toNextPipeline_2_indata(g_toNextPipeline_2_indata),
    .toNextPipeline_2_readen(g_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd(g_toNextPipeline_2_addr_rd),
    .toNextPipeline_3_array(g_toNextPipeline_3_array),
    .toNextPipeline_3_all(g_toNextPipeline_3_all),
    .toNextPipeline_3_req(g_toNextPipeline_3_req),
    .toNextPipeline_3_writeen(g_toNextPipeline_3_writeen),
    .toNextPipeline_3_be(g_toNextPipeline_3_be),
    .toNextPipeline_3_addr(g_toNextPipeline_3_addr),
    .toNextPipeline_3_indata(g_toNextPipeline_3_indata),
    .toNextPipeline_3_readen(g_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd(g_toNextPipeline_3_addr_rd),
    .toNextPipeline_4_array(g_toNextPipeline_4_array),
    .toNextPipeline_4_all(g_toNextPipeline_4_all),
    .toNextPipeline_4_req(g_toNextPipeline_4_req),
    .toNextPipeline_4_writeen(g_toNextPipeline_4_writeen),
    .toNextPipeline_4_be(g_toNextPipeline_4_be),
    .toNextPipeline_4_addr(g_toNextPipeline_4_addr),
    .toNextPipeline_4_indata(g_toNextPipeline_4_indata),
    .toNextPipeline_4_readen(g_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd(g_toNextPipeline_4_addr_rd)
  );

  L2Cache_xs dut_i (
    .clock(clk),
    .reset(rst),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .toNextPipeline_0_ack(toNextPipeline_0_ack),
    .toNextPipeline_0_outdata(toNextPipeline_0_outdata),
    .toNextPipeline_1_ack(toNextPipeline_1_ack),
    .toNextPipeline_1_outdata(toNextPipeline_1_outdata),
    .toNextPipeline_2_ack(toNextPipeline_2_ack),
    .toNextPipeline_2_outdata(toNextPipeline_2_outdata),
    .toNextPipeline_3_ack(toNextPipeline_3_ack),
    .toNextPipeline_3_outdata(toNextPipeline_3_outdata),
    .toNextPipeline_4_ack(toNextPipeline_4_ack),
    .toNextPipeline_4_outdata(toNextPipeline_4_outdata),
    .mbist_ack(i_mbist_ack),
    .mbist_outdata(i_mbist_outdata),
    .toNextPipeline_0_array(i_toNextPipeline_0_array),
    .toNextPipeline_0_all(i_toNextPipeline_0_all),
    .toNextPipeline_0_req(i_toNextPipeline_0_req),
    .toNextPipeline_0_writeen(i_toNextPipeline_0_writeen),
    .toNextPipeline_0_be(i_toNextPipeline_0_be),
    .toNextPipeline_0_addr(i_toNextPipeline_0_addr),
    .toNextPipeline_0_indata(i_toNextPipeline_0_indata),
    .toNextPipeline_0_readen(i_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd(i_toNextPipeline_0_addr_rd),
    .toNextPipeline_1_array(i_toNextPipeline_1_array),
    .toNextPipeline_1_all(i_toNextPipeline_1_all),
    .toNextPipeline_1_req(i_toNextPipeline_1_req),
    .toNextPipeline_1_writeen(i_toNextPipeline_1_writeen),
    .toNextPipeline_1_be(i_toNextPipeline_1_be),
    .toNextPipeline_1_addr(i_toNextPipeline_1_addr),
    .toNextPipeline_1_indata(i_toNextPipeline_1_indata),
    .toNextPipeline_1_readen(i_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd(i_toNextPipeline_1_addr_rd),
    .toNextPipeline_2_array(i_toNextPipeline_2_array),
    .toNextPipeline_2_all(i_toNextPipeline_2_all),
    .toNextPipeline_2_req(i_toNextPipeline_2_req),
    .toNextPipeline_2_writeen(i_toNextPipeline_2_writeen),
    .toNextPipeline_2_be(i_toNextPipeline_2_be),
    .toNextPipeline_2_addr(i_toNextPipeline_2_addr),
    .toNextPipeline_2_indata(i_toNextPipeline_2_indata),
    .toNextPipeline_2_readen(i_toNextPipeline_2_readen),
    .toNextPipeline_2_addr_rd(i_toNextPipeline_2_addr_rd),
    .toNextPipeline_3_array(i_toNextPipeline_3_array),
    .toNextPipeline_3_all(i_toNextPipeline_3_all),
    .toNextPipeline_3_req(i_toNextPipeline_3_req),
    .toNextPipeline_3_writeen(i_toNextPipeline_3_writeen),
    .toNextPipeline_3_be(i_toNextPipeline_3_be),
    .toNextPipeline_3_addr(i_toNextPipeline_3_addr),
    .toNextPipeline_3_indata(i_toNextPipeline_3_indata),
    .toNextPipeline_3_readen(i_toNextPipeline_3_readen),
    .toNextPipeline_3_addr_rd(i_toNextPipeline_3_addr_rd),
    .toNextPipeline_4_array(i_toNextPipeline_4_array),
    .toNextPipeline_4_all(i_toNextPipeline_4_all),
    .toNextPipeline_4_req(i_toNextPipeline_4_req),
    .toNextPipeline_4_writeen(i_toNextPipeline_4_writeen),
    .toNextPipeline_4_be(i_toNextPipeline_4_be),
    .toNextPipeline_4_addr(i_toNextPipeline_4_addr),
    .toNextPipeline_4_indata(i_toNextPipeline_4_indata),
    .toNextPipeline_4_readen(i_toNextPipeline_4_readen),
    .toNextPipeline_4_addr_rd(i_toNextPipeline_4_addr_rd)
  );

  task automatic drive_random();
    mbist_array = $random;
    mbist_all = $random;
    mbist_req = $random;
    mbist_writeen = $random;
    mbist_be = $random;
    mbist_addr = $random;
    mbist_indata = $random;
    mbist_readen = $random;
    mbist_addr_rd = $random;
    toNextPipeline_0_ack = $random;
    toNextPipeline_0_outdata = $random;
    toNextPipeline_1_ack = $random;
    toNextPipeline_1_outdata = $random;
    toNextPipeline_2_ack = $random;
    toNextPipeline_2_outdata = $random;
    toNextPipeline_3_ack = $random;
    toNextPipeline_3_outdata = $random;
    toNextPipeline_4_ack = $random;
    toNextPipeline_4_outdata = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_mbist_ack !== i_mbist_ack) begin errors++; if (errors<=20) $display("[%0d] MISMATCH mbist_ack: g=%h i=%h", cyc, g_mbist_ack, i_mbist_ack); end
    if (g_mbist_outdata !== i_mbist_outdata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH mbist_outdata: g=%h i=%h", cyc, g_mbist_outdata, i_mbist_outdata); end
    if (g_toNextPipeline_0_array !== i_toNextPipeline_0_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_array: g=%h i=%h", cyc, g_toNextPipeline_0_array, i_toNextPipeline_0_array); end
    if (g_toNextPipeline_0_all !== i_toNextPipeline_0_all) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_all: g=%h i=%h", cyc, g_toNextPipeline_0_all, i_toNextPipeline_0_all); end
    if (g_toNextPipeline_0_req !== i_toNextPipeline_0_req) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_req: g=%h i=%h", cyc, g_toNextPipeline_0_req, i_toNextPipeline_0_req); end
    if (g_toNextPipeline_0_writeen !== i_toNextPipeline_0_writeen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_writeen: g=%h i=%h", cyc, g_toNextPipeline_0_writeen, i_toNextPipeline_0_writeen); end
    if (g_toNextPipeline_0_be !== i_toNextPipeline_0_be) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_be: g=%h i=%h", cyc, g_toNextPipeline_0_be, i_toNextPipeline_0_be); end
    if (g_toNextPipeline_0_addr !== i_toNextPipeline_0_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_addr: g=%h i=%h", cyc, g_toNextPipeline_0_addr, i_toNextPipeline_0_addr); end
    if (g_toNextPipeline_0_indata !== i_toNextPipeline_0_indata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_indata: g=%h i=%h", cyc, g_toNextPipeline_0_indata, i_toNextPipeline_0_indata); end
    if (g_toNextPipeline_0_readen !== i_toNextPipeline_0_readen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_readen: g=%h i=%h", cyc, g_toNextPipeline_0_readen, i_toNextPipeline_0_readen); end
    if (g_toNextPipeline_0_addr_rd !== i_toNextPipeline_0_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_0_addr_rd: g=%h i=%h", cyc, g_toNextPipeline_0_addr_rd, i_toNextPipeline_0_addr_rd); end
    if (g_toNextPipeline_1_array !== i_toNextPipeline_1_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_array: g=%h i=%h", cyc, g_toNextPipeline_1_array, i_toNextPipeline_1_array); end
    if (g_toNextPipeline_1_all !== i_toNextPipeline_1_all) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_all: g=%h i=%h", cyc, g_toNextPipeline_1_all, i_toNextPipeline_1_all); end
    if (g_toNextPipeline_1_req !== i_toNextPipeline_1_req) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_req: g=%h i=%h", cyc, g_toNextPipeline_1_req, i_toNextPipeline_1_req); end
    if (g_toNextPipeline_1_writeen !== i_toNextPipeline_1_writeen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_writeen: g=%h i=%h", cyc, g_toNextPipeline_1_writeen, i_toNextPipeline_1_writeen); end
    if (g_toNextPipeline_1_be !== i_toNextPipeline_1_be) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_be: g=%h i=%h", cyc, g_toNextPipeline_1_be, i_toNextPipeline_1_be); end
    if (g_toNextPipeline_1_addr !== i_toNextPipeline_1_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_addr: g=%h i=%h", cyc, g_toNextPipeline_1_addr, i_toNextPipeline_1_addr); end
    if (g_toNextPipeline_1_indata !== i_toNextPipeline_1_indata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_indata: g=%h i=%h", cyc, g_toNextPipeline_1_indata, i_toNextPipeline_1_indata); end
    if (g_toNextPipeline_1_readen !== i_toNextPipeline_1_readen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_readen: g=%h i=%h", cyc, g_toNextPipeline_1_readen, i_toNextPipeline_1_readen); end
    if (g_toNextPipeline_1_addr_rd !== i_toNextPipeline_1_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_1_addr_rd: g=%h i=%h", cyc, g_toNextPipeline_1_addr_rd, i_toNextPipeline_1_addr_rd); end
    if (g_toNextPipeline_2_array !== i_toNextPipeline_2_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_array: g=%h i=%h", cyc, g_toNextPipeline_2_array, i_toNextPipeline_2_array); end
    if (g_toNextPipeline_2_all !== i_toNextPipeline_2_all) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_all: g=%h i=%h", cyc, g_toNextPipeline_2_all, i_toNextPipeline_2_all); end
    if (g_toNextPipeline_2_req !== i_toNextPipeline_2_req) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_req: g=%h i=%h", cyc, g_toNextPipeline_2_req, i_toNextPipeline_2_req); end
    if (g_toNextPipeline_2_writeen !== i_toNextPipeline_2_writeen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_writeen: g=%h i=%h", cyc, g_toNextPipeline_2_writeen, i_toNextPipeline_2_writeen); end
    if (g_toNextPipeline_2_be !== i_toNextPipeline_2_be) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_be: g=%h i=%h", cyc, g_toNextPipeline_2_be, i_toNextPipeline_2_be); end
    if (g_toNextPipeline_2_addr !== i_toNextPipeline_2_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_addr: g=%h i=%h", cyc, g_toNextPipeline_2_addr, i_toNextPipeline_2_addr); end
    if (g_toNextPipeline_2_indata !== i_toNextPipeline_2_indata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_indata: g=%h i=%h", cyc, g_toNextPipeline_2_indata, i_toNextPipeline_2_indata); end
    if (g_toNextPipeline_2_readen !== i_toNextPipeline_2_readen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_readen: g=%h i=%h", cyc, g_toNextPipeline_2_readen, i_toNextPipeline_2_readen); end
    if (g_toNextPipeline_2_addr_rd !== i_toNextPipeline_2_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_2_addr_rd: g=%h i=%h", cyc, g_toNextPipeline_2_addr_rd, i_toNextPipeline_2_addr_rd); end
    if (g_toNextPipeline_3_array !== i_toNextPipeline_3_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_array: g=%h i=%h", cyc, g_toNextPipeline_3_array, i_toNextPipeline_3_array); end
    if (g_toNextPipeline_3_all !== i_toNextPipeline_3_all) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_all: g=%h i=%h", cyc, g_toNextPipeline_3_all, i_toNextPipeline_3_all); end
    if (g_toNextPipeline_3_req !== i_toNextPipeline_3_req) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_req: g=%h i=%h", cyc, g_toNextPipeline_3_req, i_toNextPipeline_3_req); end
    if (g_toNextPipeline_3_writeen !== i_toNextPipeline_3_writeen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_writeen: g=%h i=%h", cyc, g_toNextPipeline_3_writeen, i_toNextPipeline_3_writeen); end
    if (g_toNextPipeline_3_be !== i_toNextPipeline_3_be) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_be: g=%h i=%h", cyc, g_toNextPipeline_3_be, i_toNextPipeline_3_be); end
    if (g_toNextPipeline_3_addr !== i_toNextPipeline_3_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_addr: g=%h i=%h", cyc, g_toNextPipeline_3_addr, i_toNextPipeline_3_addr); end
    if (g_toNextPipeline_3_indata !== i_toNextPipeline_3_indata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_indata: g=%h i=%h", cyc, g_toNextPipeline_3_indata, i_toNextPipeline_3_indata); end
    if (g_toNextPipeline_3_readen !== i_toNextPipeline_3_readen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_readen: g=%h i=%h", cyc, g_toNextPipeline_3_readen, i_toNextPipeline_3_readen); end
    if (g_toNextPipeline_3_addr_rd !== i_toNextPipeline_3_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_3_addr_rd: g=%h i=%h", cyc, g_toNextPipeline_3_addr_rd, i_toNextPipeline_3_addr_rd); end
    if (g_toNextPipeline_4_array !== i_toNextPipeline_4_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_array: g=%h i=%h", cyc, g_toNextPipeline_4_array, i_toNextPipeline_4_array); end
    if (g_toNextPipeline_4_all !== i_toNextPipeline_4_all) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_all: g=%h i=%h", cyc, g_toNextPipeline_4_all, i_toNextPipeline_4_all); end
    if (g_toNextPipeline_4_req !== i_toNextPipeline_4_req) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_req: g=%h i=%h", cyc, g_toNextPipeline_4_req, i_toNextPipeline_4_req); end
    if (g_toNextPipeline_4_writeen !== i_toNextPipeline_4_writeen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_writeen: g=%h i=%h", cyc, g_toNextPipeline_4_writeen, i_toNextPipeline_4_writeen); end
    if (g_toNextPipeline_4_be !== i_toNextPipeline_4_be) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_be: g=%h i=%h", cyc, g_toNextPipeline_4_be, i_toNextPipeline_4_be); end
    if (g_toNextPipeline_4_addr !== i_toNextPipeline_4_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_addr: g=%h i=%h", cyc, g_toNextPipeline_4_addr, i_toNextPipeline_4_addr); end
    if (g_toNextPipeline_4_indata !== i_toNextPipeline_4_indata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_indata: g=%h i=%h", cyc, g_toNextPipeline_4_indata, i_toNextPipeline_4_indata); end
    if (g_toNextPipeline_4_readen !== i_toNextPipeline_4_readen) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_readen: g=%h i=%h", cyc, g_toNextPipeline_4_readen, i_toNextPipeline_4_readen); end
    if (g_toNextPipeline_4_addr_rd !== i_toNextPipeline_4_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toNextPipeline_4_addr_rd: g=%h i=%h", cyc, g_toNextPipeline_4_addr_rd, i_toNextPipeline_4_addr_rd); end
  endtask

  initial begin
    rst = 1'b1;
    mbist_array = '0;
    mbist_all = '0;
    mbist_req = '0;
    mbist_writeen = '0;
    mbist_be = '0;
    mbist_addr = '0;
    mbist_indata = '0;
    mbist_readen = '0;
    mbist_addr_rd = '0;
    toNextPipeline_0_ack = '0;
    toNextPipeline_0_outdata = '0;
    toNextPipeline_1_ack = '0;
    toNextPipeline_1_outdata = '0;
    toNextPipeline_2_ack = '0;
    toNextPipeline_2_outdata = '0;
    toNextPipeline_3_ack = '0;
    toNextPipeline_3_outdata = '0;
    toNextPipeline_4_ack = '0;
    toNextPipeline_4_outdata = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
