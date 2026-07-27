// 自动生成: gen_tb_shardD.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic mbist_array;
  logic mbist_all;
  logic mbist_req;
  logic mbist_writeen;
  logic mbist_be;
  logic [8:0] mbist_addr;
  logic [12:0] mbist_indata;
  logic mbist_readen;
  logic [8:0] mbist_addr_rd;
  logic [12:0] toSRAM_0_rdata;
  logic [12:0] toSRAM_1_rdata;
  logic g_mbist_ack;
  logic i_mbist_ack;
  logic [12:0] g_mbist_outdata;
  logic [12:0] i_mbist_outdata;
  logic [8:0] g_toSRAM_0_addr;
  logic [8:0] i_toSRAM_0_addr;
  logic [8:0] g_toSRAM_0_addr_rd;
  logic [8:0] i_toSRAM_0_addr_rd;
  logic [12:0] g_toSRAM_0_wdata;
  logic [12:0] i_toSRAM_0_wdata;
  logic g_toSRAM_0_wmask;
  logic i_toSRAM_0_wmask;
  logic g_toSRAM_0_re;
  logic i_toSRAM_0_re;
  logic g_toSRAM_0_we;
  logic i_toSRAM_0_we;
  logic g_toSRAM_0_ack;
  logic i_toSRAM_0_ack;
  logic g_toSRAM_0_selectedOH;
  logic i_toSRAM_0_selectedOH;
  logic g_toSRAM_0_array;
  logic i_toSRAM_0_array;
  logic [8:0] g_toSRAM_1_addr;
  logic [8:0] i_toSRAM_1_addr;
  logic [8:0] g_toSRAM_1_addr_rd;
  logic [8:0] i_toSRAM_1_addr_rd;
  logic [12:0] g_toSRAM_1_wdata;
  logic [12:0] i_toSRAM_1_wdata;
  logic g_toSRAM_1_wmask;
  logic i_toSRAM_1_wmask;
  logic g_toSRAM_1_re;
  logic i_toSRAM_1_re;
  logic g_toSRAM_1_we;
  logic i_toSRAM_1_we;
  logic g_toSRAM_1_ack;
  logic i_toSRAM_1_ack;
  logic g_toSRAM_1_selectedOH;
  logic i_toSRAM_1_selectedOH;
  logic g_toSRAM_1_array;
  logic i_toSRAM_1_array;

  MbistPipeL2Prefetcher dut_g (
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
    .toSRAM_0_rdata(toSRAM_0_rdata),
    .toSRAM_1_rdata(toSRAM_1_rdata),
    .mbist_ack(g_mbist_ack),
    .mbist_outdata(g_mbist_outdata),
    .toSRAM_0_addr(g_toSRAM_0_addr),
    .toSRAM_0_addr_rd(g_toSRAM_0_addr_rd),
    .toSRAM_0_wdata(g_toSRAM_0_wdata),
    .toSRAM_0_wmask(g_toSRAM_0_wmask),
    .toSRAM_0_re(g_toSRAM_0_re),
    .toSRAM_0_we(g_toSRAM_0_we),
    .toSRAM_0_ack(g_toSRAM_0_ack),
    .toSRAM_0_selectedOH(g_toSRAM_0_selectedOH),
    .toSRAM_0_array(g_toSRAM_0_array),
    .toSRAM_1_addr(g_toSRAM_1_addr),
    .toSRAM_1_addr_rd(g_toSRAM_1_addr_rd),
    .toSRAM_1_wdata(g_toSRAM_1_wdata),
    .toSRAM_1_wmask(g_toSRAM_1_wmask),
    .toSRAM_1_re(g_toSRAM_1_re),
    .toSRAM_1_we(g_toSRAM_1_we),
    .toSRAM_1_ack(g_toSRAM_1_ack),
    .toSRAM_1_selectedOH(g_toSRAM_1_selectedOH),
    .toSRAM_1_array(g_toSRAM_1_array)
  );

  MbistPipeL2Prefetcher_xs dut_i (
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
    .toSRAM_0_rdata(toSRAM_0_rdata),
    .toSRAM_1_rdata(toSRAM_1_rdata),
    .mbist_ack(i_mbist_ack),
    .mbist_outdata(i_mbist_outdata),
    .toSRAM_0_addr(i_toSRAM_0_addr),
    .toSRAM_0_addr_rd(i_toSRAM_0_addr_rd),
    .toSRAM_0_wdata(i_toSRAM_0_wdata),
    .toSRAM_0_wmask(i_toSRAM_0_wmask),
    .toSRAM_0_re(i_toSRAM_0_re),
    .toSRAM_0_we(i_toSRAM_0_we),
    .toSRAM_0_ack(i_toSRAM_0_ack),
    .toSRAM_0_selectedOH(i_toSRAM_0_selectedOH),
    .toSRAM_0_array(i_toSRAM_0_array),
    .toSRAM_1_addr(i_toSRAM_1_addr),
    .toSRAM_1_addr_rd(i_toSRAM_1_addr_rd),
    .toSRAM_1_wdata(i_toSRAM_1_wdata),
    .toSRAM_1_wmask(i_toSRAM_1_wmask),
    .toSRAM_1_re(i_toSRAM_1_re),
    .toSRAM_1_we(i_toSRAM_1_we),
    .toSRAM_1_ack(i_toSRAM_1_ack),
    .toSRAM_1_selectedOH(i_toSRAM_1_selectedOH),
    .toSRAM_1_array(i_toSRAM_1_array)
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
    toSRAM_0_rdata = $random;
    toSRAM_1_rdata = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_mbist_ack !== i_mbist_ack) begin errors++; if (errors<=20) $display("[%0d] MISMATCH mbist_ack: g=%h i=%h", cyc, g_mbist_ack, i_mbist_ack); end
    if (g_mbist_outdata !== i_mbist_outdata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH mbist_outdata: g=%h i=%h", cyc, g_mbist_outdata, i_mbist_outdata); end
    if (g_toSRAM_0_addr !== i_toSRAM_0_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_addr: g=%h i=%h", cyc, g_toSRAM_0_addr, i_toSRAM_0_addr); end
    if (g_toSRAM_0_addr_rd !== i_toSRAM_0_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_addr_rd: g=%h i=%h", cyc, g_toSRAM_0_addr_rd, i_toSRAM_0_addr_rd); end
    if (g_toSRAM_0_wdata !== i_toSRAM_0_wdata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_wdata: g=%h i=%h", cyc, g_toSRAM_0_wdata, i_toSRAM_0_wdata); end
    if (g_toSRAM_0_wmask !== i_toSRAM_0_wmask) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_wmask: g=%h i=%h", cyc, g_toSRAM_0_wmask, i_toSRAM_0_wmask); end
    if (g_toSRAM_0_re !== i_toSRAM_0_re) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_re: g=%h i=%h", cyc, g_toSRAM_0_re, i_toSRAM_0_re); end
    if (g_toSRAM_0_we !== i_toSRAM_0_we) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_we: g=%h i=%h", cyc, g_toSRAM_0_we, i_toSRAM_0_we); end
    if (g_toSRAM_0_ack !== i_toSRAM_0_ack) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_ack: g=%h i=%h", cyc, g_toSRAM_0_ack, i_toSRAM_0_ack); end
    if (g_toSRAM_0_selectedOH !== i_toSRAM_0_selectedOH) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_selectedOH: g=%h i=%h", cyc, g_toSRAM_0_selectedOH, i_toSRAM_0_selectedOH); end
    if (g_toSRAM_0_array !== i_toSRAM_0_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_0_array: g=%h i=%h", cyc, g_toSRAM_0_array, i_toSRAM_0_array); end
    if (g_toSRAM_1_addr !== i_toSRAM_1_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_addr: g=%h i=%h", cyc, g_toSRAM_1_addr, i_toSRAM_1_addr); end
    if (g_toSRAM_1_addr_rd !== i_toSRAM_1_addr_rd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_addr_rd: g=%h i=%h", cyc, g_toSRAM_1_addr_rd, i_toSRAM_1_addr_rd); end
    if (g_toSRAM_1_wdata !== i_toSRAM_1_wdata) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_wdata: g=%h i=%h", cyc, g_toSRAM_1_wdata, i_toSRAM_1_wdata); end
    if (g_toSRAM_1_wmask !== i_toSRAM_1_wmask) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_wmask: g=%h i=%h", cyc, g_toSRAM_1_wmask, i_toSRAM_1_wmask); end
    if (g_toSRAM_1_re !== i_toSRAM_1_re) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_re: g=%h i=%h", cyc, g_toSRAM_1_re, i_toSRAM_1_re); end
    if (g_toSRAM_1_we !== i_toSRAM_1_we) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_we: g=%h i=%h", cyc, g_toSRAM_1_we, i_toSRAM_1_we); end
    if (g_toSRAM_1_ack !== i_toSRAM_1_ack) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_ack: g=%h i=%h", cyc, g_toSRAM_1_ack, i_toSRAM_1_ack); end
    if (g_toSRAM_1_selectedOH !== i_toSRAM_1_selectedOH) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_selectedOH: g=%h i=%h", cyc, g_toSRAM_1_selectedOH, i_toSRAM_1_selectedOH); end
    if (g_toSRAM_1_array !== i_toSRAM_1_array) begin errors++; if (errors<=20) $display("[%0d] MISMATCH toSRAM_1_array: g=%h i=%h", cyc, g_toSRAM_1_array, i_toSRAM_1_array); end
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
    toSRAM_0_rdata = '0;
    toSRAM_1_rdata = '0;
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
