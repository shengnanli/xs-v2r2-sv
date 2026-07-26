// 自动生成: gen_pipe_ut.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_enq_valid;
  logic [3:0] io_enq_bits_pCrdType;
  logic [10:0] io_enq_bits_srcID;
  logic io_deq_ready;
  logic g_io_enq_ready;
  logic i_io_enq_ready;
  logic g_io_deq_valid;
  logic i_io_deq_valid;
  logic [3:0] g_io_deq_bits_pCrdType;
  logic [3:0] i_io_deq_bits_pCrdType;
  logic [10:0] g_io_deq_bits_srcID;
  logic [10:0] i_io_deq_bits_srcID;

  Queue72_CoupledL2Imp_Anon dut_g (
    .clock(clk),
    .reset(rst),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_pCrdType(io_enq_bits_pCrdType),
    .io_enq_bits_srcID(io_enq_bits_srcID),
    .io_deq_ready(io_deq_ready),
    .io_enq_ready(g_io_enq_ready),
    .io_deq_valid(g_io_deq_valid),
    .io_deq_bits_pCrdType(g_io_deq_bits_pCrdType),
    .io_deq_bits_srcID(g_io_deq_bits_srcID)
  );

  Queue72_CoupledL2Imp_Anon_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_pCrdType(io_enq_bits_pCrdType),
    .io_enq_bits_srcID(io_enq_bits_srcID),
    .io_deq_ready(io_deq_ready),
    .io_enq_ready(i_io_enq_ready),
    .io_deq_valid(i_io_deq_valid),
    .io_deq_bits_pCrdType(i_io_deq_bits_pCrdType),
    .io_deq_bits_srcID(i_io_deq_bits_srcID)
  );

  task automatic drive_random();
    io_enq_valid = $random;
    io_enq_bits_pCrdType = $random;
    io_enq_bits_srcID = $random;
    io_deq_ready = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_enq_ready !== i_io_enq_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_enq_ready: g=%h i=%h", cyc, g_io_enq_ready, i_io_enq_ready); end
    if (g_io_deq_valid !== i_io_deq_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_valid: g=%h i=%h", cyc, g_io_deq_valid, i_io_deq_valid); end
    if (g_io_deq_bits_pCrdType !== i_io_deq_bits_pCrdType) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_pCrdType: g=%h i=%h", cyc, g_io_deq_bits_pCrdType, i_io_deq_bits_pCrdType); end
    if (g_io_deq_bits_srcID !== i_io_deq_bits_srcID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_srcID: g=%h i=%h", cyc, g_io_deq_bits_srcID, i_io_deq_bits_srcID); end
  endtask

  initial begin
    rst = 1'b1;
    io_enq_valid = '0;
    io_enq_bits_pCrdType = '0;
    io_enq_bits_srcID = '0;
    io_deq_ready = '0;
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
