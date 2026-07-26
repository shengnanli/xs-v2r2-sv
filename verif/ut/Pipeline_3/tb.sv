// 自动生成: gen_pipe_ut.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [32:0] io_in_bits_tag;
  logic [8:0] io_in_bits_set;
  logic [43:0] io_in_bits_vaddr;
  logic [4:0] io_in_bits_pfSource;
  logic io_out_ready;
  logic g_io_in_ready;
  logic i_io_in_ready;
  logic g_io_out_valid;
  logic i_io_out_valid;
  logic [4:0] g_io_out_bits_pfSource;
  logic [4:0] i_io_out_bits_pfSource;

  Pipeline_3 dut_g (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_set(io_in_bits_set),
    .io_in_bits_vaddr(io_in_bits_vaddr),
    .io_in_bits_pfSource(io_in_bits_pfSource),
    .io_out_ready(io_out_ready),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_pfSource(g_io_out_bits_pfSource)
  );

  Pipeline_3_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_set(io_in_bits_set),
    .io_in_bits_vaddr(io_in_bits_vaddr),
    .io_in_bits_pfSource(io_in_bits_pfSource),
    .io_out_ready(io_out_ready),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_pfSource(i_io_out_bits_pfSource)
  );

  task automatic drive_random();
    io_in_valid = $random;
    io_in_bits_tag = $random;
    io_in_bits_set = $random;
    io_in_bits_vaddr = $random;
    io_in_bits_pfSource = $random;
    io_out_ready = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_in_ready: g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_valid: g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits_pfSource !== i_io_out_bits_pfSource) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_pfSource: g=%h i=%h", cyc, g_io_out_bits_pfSource, i_io_out_bits_pfSource); end
  endtask

  initial begin
    rst = 1'b1;
    io_in_valid = '0;
    io_in_bits_tag = '0;
    io_in_bits_set = '0;
    io_in_bits_vaddr = '0;
    io_in_bits_pfSource = '0;
    io_out_ready = '0;
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
