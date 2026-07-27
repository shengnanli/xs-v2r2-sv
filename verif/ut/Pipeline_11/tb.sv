// 自动生成: gen_pipe_ut.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [31:0] io_in_bits;
  logic g_io_out_valid;
  logic i_io_out_valid;
  logic [31:0] g_io_out_bits;
  logic [31:0] i_io_out_bits;

  Pipeline_11 dut_g (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits(io_in_bits),
    .io_out_valid(g_io_out_valid),
    .io_out_bits(g_io_out_bits)
  );

  Pipeline_11_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits(io_in_bits),
    .io_out_valid(i_io_out_valid),
    .io_out_bits(i_io_out_bits)
  );

  task automatic drive_random();
    io_in_valid = $random;
    io_in_bits = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_valid: g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits !== i_io_out_bits) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits: g=%h i=%h", cyc, g_io_out_bits, i_io_out_bits); end
  endtask

  initial begin
    rst = 1'b1;
    io_in_valid = '0;
    io_in_bits = '0;
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
