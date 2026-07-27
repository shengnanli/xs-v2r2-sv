// 自动生成: gen_tb_shardD.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_recv_addr_valid;
  logic [63:0] io_recv_addr_bits_addr;
  logic [4:0] io_recv_addr_bits_pfSource;
  logic io_enable;
  logic g_io_req_valid;
  logic i_io_req_valid;
  logic [32:0] g_io_req_bits_tag;
  logic [32:0] i_io_req_bits_tag;
  logic [8:0] g_io_req_bits_set;
  logic [8:0] i_io_req_bits_set;
  logic [4:0] g_io_req_bits_pfSource;
  logic [4:0] i_io_req_bits_pfSource;

  PrefetchReceiver dut_g (
    .io_recv_addr_valid(io_recv_addr_valid),
    .io_recv_addr_bits_addr(io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(io_recv_addr_bits_pfSource),
    .io_enable(io_enable),
    .io_req_valid(g_io_req_valid),
    .io_req_bits_tag(g_io_req_bits_tag),
    .io_req_bits_set(g_io_req_bits_set),
    .io_req_bits_pfSource(g_io_req_bits_pfSource)
  );

  PrefetchReceiver_xs dut_i (
    .io_recv_addr_valid(io_recv_addr_valid),
    .io_recv_addr_bits_addr(io_recv_addr_bits_addr),
    .io_recv_addr_bits_pfSource(io_recv_addr_bits_pfSource),
    .io_enable(io_enable),
    .io_req_valid(i_io_req_valid),
    .io_req_bits_tag(i_io_req_bits_tag),
    .io_req_bits_set(i_io_req_bits_set),
    .io_req_bits_pfSource(i_io_req_bits_pfSource)
  );

  task automatic drive_random();
    io_recv_addr_valid = $random;
    io_recv_addr_bits_addr = $random;
    io_recv_addr_bits_pfSource = $random;
    io_enable = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_req_valid !== i_io_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_valid: g=%h i=%h", cyc, g_io_req_valid, i_io_req_valid); end
    if (g_io_req_bits_tag !== i_io_req_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_tag: g=%h i=%h", cyc, g_io_req_bits_tag, i_io_req_bits_tag); end
    if (g_io_req_bits_set !== i_io_req_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_set: g=%h i=%h", cyc, g_io_req_bits_set, i_io_req_bits_set); end
    if (g_io_req_bits_pfSource !== i_io_req_bits_pfSource) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_bits_pfSource: g=%h i=%h", cyc, g_io_req_bits_pfSource, i_io_req_bits_pfSource); end
  endtask

  initial begin
    io_recv_addr_valid = '0;
    io_recv_addr_bits_addr = '0;
    io_recv_addr_bits_pfSource = '0;
    io_enable = '0;
    repeat (6) @(posedge clk);
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
