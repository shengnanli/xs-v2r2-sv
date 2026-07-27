// MbistIntfL2 双例化逐拍比对: golden MbistIntfL2 vs 可读 MbistIntfL2_xs (随机激励).
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;
  logic toPipeline_0_ack;
  logic [103:0] toPipeline_0_outdata;
  logic [5:0] mbist_array;
  logic mbist_all;
  logic mbist_req;
  logic mbist_writeen;
  logic [7:0] mbist_be;
  logic [12:0] mbist_addr;
  logic [103:0] mbist_indata;
  logic mbist_readen;
  logic [12:0] mbist_addr_rd;
  wire [5:0] g_toPipeline_0_array;
  wire [5:0] i_toPipeline_0_array;
  wire g_toPipeline_0_all;
  wire i_toPipeline_0_all;
  wire g_toPipeline_0_req;
  wire i_toPipeline_0_req;
  wire g_toPipeline_0_writeen;
  wire i_toPipeline_0_writeen;
  wire [7:0] g_toPipeline_0_be;
  wire [7:0] i_toPipeline_0_be;
  wire [12:0] g_toPipeline_0_addr;
  wire [12:0] i_toPipeline_0_addr;
  wire [103:0] g_toPipeline_0_indata;
  wire [103:0] i_toPipeline_0_indata;
  wire g_toPipeline_0_readen;
  wire i_toPipeline_0_readen;
  wire [12:0] g_toPipeline_0_addr_rd;
  wire [12:0] i_toPipeline_0_addr_rd;
  wire g_mbist_ack;
  wire i_mbist_ack;
  wire [103:0] g_mbist_outdata;
  wire [103:0] i_mbist_outdata;
  MbistIntfL2 u_g (
    .toPipeline_0_array(g_toPipeline_0_array),
    .toPipeline_0_all(g_toPipeline_0_all),
    .toPipeline_0_req(g_toPipeline_0_req),
    .toPipeline_0_ack(toPipeline_0_ack),
    .toPipeline_0_writeen(g_toPipeline_0_writeen),
    .toPipeline_0_be(g_toPipeline_0_be),
    .toPipeline_0_addr(g_toPipeline_0_addr),
    .toPipeline_0_indata(g_toPipeline_0_indata),
    .toPipeline_0_readen(g_toPipeline_0_readen),
    .toPipeline_0_addr_rd(g_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(toPipeline_0_outdata),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_ack(g_mbist_ack),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .mbist_outdata(g_mbist_outdata)
  );
  MbistIntfL2_xs u_i (
    .toPipeline_0_array(i_toPipeline_0_array),
    .toPipeline_0_all(i_toPipeline_0_all),
    .toPipeline_0_req(i_toPipeline_0_req),
    .toPipeline_0_ack(toPipeline_0_ack),
    .toPipeline_0_writeen(i_toPipeline_0_writeen),
    .toPipeline_0_be(i_toPipeline_0_be),
    .toPipeline_0_addr(i_toPipeline_0_addr),
    .toPipeline_0_indata(i_toPipeline_0_indata),
    .toPipeline_0_readen(i_toPipeline_0_readen),
    .toPipeline_0_addr_rd(i_toPipeline_0_addr_rd),
    .toPipeline_0_outdata(toPipeline_0_outdata),
    .mbist_array(mbist_array),
    .mbist_all(mbist_all),
    .mbist_req(mbist_req),
    .mbist_ack(i_mbist_ack),
    .mbist_writeen(mbist_writeen),
    .mbist_be(mbist_be),
    .mbist_addr(mbist_addr),
    .mbist_indata(mbist_indata),
    .mbist_readen(mbist_readen),
    .mbist_addr_rd(mbist_addr_rd),
    .mbist_outdata(i_mbist_outdata)
  );
  task automatic drive_random_inputs();
    toPipeline_0_ack = $urandom_range(0, 1);
    toPipeline_0_outdata = 104'($urandom);
    mbist_array = 6'($urandom);
    mbist_all = $urandom_range(0, 1);
    mbist_req = $urandom_range(0, 1);
    mbist_writeen = $urandom_range(0, 1);
    mbist_be = 8'($urandom);
    mbist_addr = 13'($urandom);
    mbist_indata = 104'($urandom);
    mbist_readen = $urandom_range(0, 1);
    mbist_addr_rd = 13'($urandom);
  endtask
  task automatic check_outputs();
    `CHECK(toPipeline_0_array)
    `CHECK(toPipeline_0_all)
    `CHECK(toPipeline_0_req)
    `CHECK(toPipeline_0_writeen)
    `CHECK(toPipeline_0_be)
    `CHECK(toPipeline_0_addr)
    `CHECK(toPipeline_0_indata)
    `CHECK(toPipeline_0_readen)
    `CHECK(toPipeline_0_addr_rd)
    `CHECK(mbist_ack)
    `CHECK(mbist_outdata)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    toPipeline_0_ack = '0;
    toPipeline_0_outdata = '0;
    mbist_array = '0;
    mbist_all = '0;
    mbist_req = '0;
    mbist_writeen = '0;
    mbist_be = '0;
    mbist_addr = '0;
    mbist_indata = '0;
    mbist_readen = '0;
    mbist_addr_rd = '0;
    repeat (2) @(posedge clock);
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
    end
    $display("MbistIntfL2 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED"); $finish;
    end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHECK
