// 自动生成：scripts/gen_l2mbist.py —— 勿手改
// L2Slice 双例化逐拍比对：golden L2Slice vs 可读重写 L2Slice_xs。
// 激励：mbist 请求 (req/all/readen/writeen/array/addr/data/be) 随机，
//       array 偏向落在合法编号上以充分覆盖各 child 的 spread 分支；
//       下游回送 (*_ack/*_rdata/*_outdata) 随机驱动。逐拍比对全部 output。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 20) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic [4:0] mbist_array;
  logic mbist_all;
  logic mbist_req;
  logic mbist_writeen;
  logic [7:0] mbist_be;
  logic [12:0] mbist_addr;
  logic [103:0] mbist_indata;
  logic mbist_readen;
  logic [12:0] mbist_addr_rd;
  logic toNextPipeline_0_ack;
  logic [103:0] toNextPipeline_0_outdata;
  logic toNextPipeline_1_ack;
  logic [68:0] toNextPipeline_1_outdata;
  wire g_mbist_ack;
  wire i_mbist_ack;
  wire [103:0] g_mbist_outdata;
  wire [103:0] i_mbist_outdata;
  wire [3:0] g_toNextPipeline_0_array;
  wire [3:0] i_toNextPipeline_0_array;
  wire g_toNextPipeline_0_all;
  wire i_toNextPipeline_0_all;
  wire g_toNextPipeline_0_req;
  wire i_toNextPipeline_0_req;
  wire g_toNextPipeline_0_writeen;
  wire i_toNextPipeline_0_writeen;
  wire [7:0] g_toNextPipeline_0_be;
  wire [7:0] i_toNextPipeline_0_be;
  wire [9:0] g_toNextPipeline_0_addr;
  wire [9:0] i_toNextPipeline_0_addr;
  wire [103:0] g_toNextPipeline_0_indata;
  wire [103:0] i_toNextPipeline_0_indata;
  wire g_toNextPipeline_0_readen;
  wire i_toNextPipeline_0_readen;
  wire [9:0] g_toNextPipeline_0_addr_rd;
  wire [9:0] i_toNextPipeline_0_addr_rd;
  wire [4:0] g_toNextPipeline_1_array;
  wire [4:0] i_toNextPipeline_1_array;
  wire g_toNextPipeline_1_all;
  wire i_toNextPipeline_1_all;
  wire g_toNextPipeline_1_req;
  wire i_toNextPipeline_1_req;
  wire g_toNextPipeline_1_writeen;
  wire i_toNextPipeline_1_writeen;
  wire g_toNextPipeline_1_be;
  wire i_toNextPipeline_1_be;
  wire [12:0] g_toNextPipeline_1_addr;
  wire [12:0] i_toNextPipeline_1_addr;
  wire [68:0] g_toNextPipeline_1_indata;
  wire [68:0] i_toNextPipeline_1_indata;
  wire g_toNextPipeline_1_readen;
  wire i_toNextPipeline_1_readen;
  wire [12:0] g_toNextPipeline_1_addr_rd;
  wire [12:0] i_toNextPipeline_1_addr_rd;

  L2Slice u_g (
    .clock(clock),
    .reset(reset),
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
    .mbist_outdata(g_mbist_outdata),
    .toNextPipeline_0_array(g_toNextPipeline_0_array),
    .toNextPipeline_0_all(g_toNextPipeline_0_all),
    .toNextPipeline_0_req(g_toNextPipeline_0_req),
    .toNextPipeline_0_ack(toNextPipeline_0_ack),
    .toNextPipeline_0_writeen(g_toNextPipeline_0_writeen),
    .toNextPipeline_0_be(g_toNextPipeline_0_be),
    .toNextPipeline_0_addr(g_toNextPipeline_0_addr),
    .toNextPipeline_0_indata(g_toNextPipeline_0_indata),
    .toNextPipeline_0_readen(g_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd(g_toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata(toNextPipeline_0_outdata),
    .toNextPipeline_1_array(g_toNextPipeline_1_array),
    .toNextPipeline_1_all(g_toNextPipeline_1_all),
    .toNextPipeline_1_req(g_toNextPipeline_1_req),
    .toNextPipeline_1_ack(toNextPipeline_1_ack),
    .toNextPipeline_1_writeen(g_toNextPipeline_1_writeen),
    .toNextPipeline_1_be(g_toNextPipeline_1_be),
    .toNextPipeline_1_addr(g_toNextPipeline_1_addr),
    .toNextPipeline_1_indata(g_toNextPipeline_1_indata),
    .toNextPipeline_1_readen(g_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd(g_toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata(toNextPipeline_1_outdata)
  );

  L2Slice_xs u_i (
    .clock(clock),
    .reset(reset),
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
    .mbist_outdata(i_mbist_outdata),
    .toNextPipeline_0_array(i_toNextPipeline_0_array),
    .toNextPipeline_0_all(i_toNextPipeline_0_all),
    .toNextPipeline_0_req(i_toNextPipeline_0_req),
    .toNextPipeline_0_ack(toNextPipeline_0_ack),
    .toNextPipeline_0_writeen(i_toNextPipeline_0_writeen),
    .toNextPipeline_0_be(i_toNextPipeline_0_be),
    .toNextPipeline_0_addr(i_toNextPipeline_0_addr),
    .toNextPipeline_0_indata(i_toNextPipeline_0_indata),
    .toNextPipeline_0_readen(i_toNextPipeline_0_readen),
    .toNextPipeline_0_addr_rd(i_toNextPipeline_0_addr_rd),
    .toNextPipeline_0_outdata(toNextPipeline_0_outdata),
    .toNextPipeline_1_array(i_toNextPipeline_1_array),
    .toNextPipeline_1_all(i_toNextPipeline_1_all),
    .toNextPipeline_1_req(i_toNextPipeline_1_req),
    .toNextPipeline_1_ack(toNextPipeline_1_ack),
    .toNextPipeline_1_writeen(i_toNextPipeline_1_writeen),
    .toNextPipeline_1_be(i_toNextPipeline_1_be),
    .toNextPipeline_1_addr(i_toNextPipeline_1_addr),
    .toNextPipeline_1_indata(i_toNextPipeline_1_indata),
    .toNextPipeline_1_readen(i_toNextPipeline_1_readen),
    .toNextPipeline_1_addr_rd(i_toNextPipeline_1_addr_rd),
    .toNextPipeline_1_outdata(toNextPipeline_1_outdata)
  );

  function automatic logic [4:0] pick_array();
    case ($urandom_range(0, 15))
      0: return 5'h2;
      1: return 5'h3;
      2: return 5'h4;
      3: return 5'h5;
      4: return 5'h6;
      5: return 5'h7;
      6: return 5'h8;
      7: return 5'h9;
      8: return 5'ha;
      9: return 5'hb;
      10: return 5'hc;
      11: return 5'hd;
      12: return 5'he;
      13: return 5'hf;
      14: return 5'h10;
      default: return 5'($urandom);  // 全随机：覆盖未命中路径
    endcase
  endfunction

  task automatic drive_random_inputs();
    mbist_array = pick_array();
    mbist_all = ($urandom_range(0, 3) != 0);
    mbist_req = ($urandom_range(0, 3) != 0);
    mbist_writeen = ($urandom_range(0, 3) != 0);
    mbist_be = 8'({$urandom});
    mbist_addr = 13'({$urandom});
    mbist_indata = 104'({$urandom, $urandom, $urandom, $urandom});
    mbist_readen = ($urandom_range(0, 3) != 0);
    mbist_addr_rd = 13'({$urandom});
    toNextPipeline_0_ack = $urandom_range(0, 1);
    toNextPipeline_0_outdata = 104'({$urandom, $urandom, $urandom, $urandom});
    toNextPipeline_1_ack = $urandom_range(0, 1);
    toNextPipeline_1_outdata = 69'({$urandom, $urandom, $urandom});
  endtask

  task automatic check_outputs();
    `CHECK(mbist_ack)
    `CHECK(mbist_outdata)
    `CHECK(toNextPipeline_0_array)
    `CHECK(toNextPipeline_0_all)
    `CHECK(toNextPipeline_0_req)
    `CHECK(toNextPipeline_0_writeen)
    `CHECK(toNextPipeline_0_be)
    `CHECK(toNextPipeline_0_addr)
    `CHECK(toNextPipeline_0_indata)
    `CHECK(toNextPipeline_0_readen)
    `CHECK(toNextPipeline_0_addr_rd)
    `CHECK(toNextPipeline_1_array)
    `CHECK(toNextPipeline_1_all)
    `CHECK(toNextPipeline_1_req)
    `CHECK(toNextPipeline_1_writeen)
    `CHECK(toNextPipeline_1_be)
    `CHECK(toNextPipeline_1_addr)
    `CHECK(toNextPipeline_1_indata)
    `CHECK(toNextPipeline_1_readen)
    `CHECK(toNextPipeline_1_addr_rd)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
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
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("L2Slice checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
