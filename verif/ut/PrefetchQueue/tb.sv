`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic         io_enq_valid;
  logic [32:0]  io_enq_bits_tag;
  logic [8:0]   io_enq_bits_set;
  logic [43:0]  io_enq_bits_vaddr;
  logic         io_enq_bits_needT;
  logic [6:0]   io_enq_bits_source;
  logic [4:0]   io_enq_bits_pfSource;
  logic         io_deq_ready;

  logic         g_io_deq_valid,       i_io_deq_valid;
  logic [32:0]  g_io_deq_bits_tag,    i_io_deq_bits_tag;
  logic [8:0]   g_io_deq_bits_set,    i_io_deq_bits_set;
  logic [43:0]  g_io_deq_bits_vaddr,  i_io_deq_bits_vaddr;
  logic         g_io_deq_bits_needT,  i_io_deq_bits_needT;
  logic [6:0]   g_io_deq_bits_source, i_io_deq_bits_source;
  logic [4:0]   g_io_deq_bits_pfSource, i_io_deq_bits_pfSource;

  PrefetchQueue dut_g (
    .clock(clk), .reset(rst),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_tag(io_enq_bits_tag),
    .io_enq_bits_set(io_enq_bits_set),
    .io_enq_bits_vaddr(io_enq_bits_vaddr),
    .io_enq_bits_needT(io_enq_bits_needT),
    .io_enq_bits_source(io_enq_bits_source),
    .io_enq_bits_pfSource(io_enq_bits_pfSource),
    .io_deq_ready(io_deq_ready),
    .io_deq_valid(g_io_deq_valid),
    .io_deq_bits_tag(g_io_deq_bits_tag),
    .io_deq_bits_set(g_io_deq_bits_set),
    .io_deq_bits_vaddr(g_io_deq_bits_vaddr),
    .io_deq_bits_needT(g_io_deq_bits_needT),
    .io_deq_bits_source(g_io_deq_bits_source),
    .io_deq_bits_pfSource(g_io_deq_bits_pfSource)
  );

  PrefetchQueue_xs dut_i (
    .clock(clk), .reset(rst),
    .io_enq_valid(io_enq_valid),
    .io_enq_bits_tag(io_enq_bits_tag),
    .io_enq_bits_set(io_enq_bits_set),
    .io_enq_bits_vaddr(io_enq_bits_vaddr),
    .io_enq_bits_needT(io_enq_bits_needT),
    .io_enq_bits_source(io_enq_bits_source),
    .io_enq_bits_pfSource(io_enq_bits_pfSource),
    .io_deq_ready(io_deq_ready),
    .io_deq_valid(i_io_deq_valid),
    .io_deq_bits_tag(i_io_deq_bits_tag),
    .io_deq_bits_set(i_io_deq_bits_set),
    .io_deq_bits_vaddr(i_io_deq_bits_vaddr),
    .io_deq_bits_needT(i_io_deq_bits_needT),
    .io_deq_bits_source(i_io_deq_bits_source),
    .io_deq_bits_pfSource(i_io_deq_bits_pfSource)
  );

  task automatic drive_random();
    // 50% enq/deq 概率, 使队列在空/满/环绕之间频繁切换。
    io_enq_valid         = $random;
    io_enq_bits_tag      = $random;
    io_enq_bits_set      = $random;
    io_enq_bits_vaddr    = {$random, $random};
    io_enq_bits_needT    = $random;
    io_enq_bits_source   = $random;
    io_enq_bits_pfSource = $random;
    io_deq_ready         = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_deq_valid !== i_io_deq_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_valid: g=%h i=%h", cyc, g_io_deq_valid, i_io_deq_valid); end
    if (g_io_deq_bits_tag !== i_io_deq_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_tag: g=%h i=%h", cyc, g_io_deq_bits_tag, i_io_deq_bits_tag); end
    if (g_io_deq_bits_set !== i_io_deq_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_set: g=%h i=%h", cyc, g_io_deq_bits_set, i_io_deq_bits_set); end
    if (g_io_deq_bits_vaddr !== i_io_deq_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_vaddr: g=%h i=%h", cyc, g_io_deq_bits_vaddr, i_io_deq_bits_vaddr); end
    if (g_io_deq_bits_needT !== i_io_deq_bits_needT) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_needT: g=%h i=%h", cyc, g_io_deq_bits_needT, i_io_deq_bits_needT); end
    if (g_io_deq_bits_source !== i_io_deq_bits_source) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_source: g=%h i=%h", cyc, g_io_deq_bits_source, i_io_deq_bits_source); end
    if (g_io_deq_bits_pfSource !== i_io_deq_bits_pfSource) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_deq_bits_pfSource: g=%h i=%h", cyc, g_io_deq_bits_pfSource, i_io_deq_bits_pfSource); end
  endtask

  initial begin
    rst = 1'b1;
    io_enq_valid = '0; io_enq_bits_tag = '0; io_enq_bits_set = '0;
    io_enq_bits_vaddr = '0; io_enq_bits_needT = '0; io_enq_bits_source = '0;
    io_enq_bits_pfSource = '0; io_deq_ready = '0;
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
