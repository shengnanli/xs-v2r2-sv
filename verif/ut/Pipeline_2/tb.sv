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
  logic io_in_bits_needT;
  logic [6:0] io_in_bits_source;
  logic [43:0] io_in_bits_vaddr;
  logic io_in_bits_hit;
  logic io_in_bits_prefetched;
  logic [2:0] io_in_bits_pfsource;
  logic [4:0] io_in_bits_reqsource;
  logic io_out_ready;
  logic g_io_in_ready;
  logic i_io_in_ready;
  logic g_io_out_valid;
  logic i_io_out_valid;
  logic [32:0] g_io_out_bits_tag;
  logic [32:0] i_io_out_bits_tag;
  logic [8:0] g_io_out_bits_set;
  logic [8:0] i_io_out_bits_set;
  logic g_io_out_bits_needT;
  logic i_io_out_bits_needT;
  logic [6:0] g_io_out_bits_source;
  logic [6:0] i_io_out_bits_source;
  logic [43:0] g_io_out_bits_vaddr;
  logic [43:0] i_io_out_bits_vaddr;
  logic [4:0] g_io_out_bits_reqsource;
  logic [4:0] i_io_out_bits_reqsource;

  Pipeline_2 dut_g (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_set(io_in_bits_set),
    .io_in_bits_needT(io_in_bits_needT),
    .io_in_bits_source(io_in_bits_source),
    .io_in_bits_vaddr(io_in_bits_vaddr),
    .io_in_bits_hit(io_in_bits_hit),
    .io_in_bits_prefetched(io_in_bits_prefetched),
    .io_in_bits_pfsource(io_in_bits_pfsource),
    .io_in_bits_reqsource(io_in_bits_reqsource),
    .io_out_ready(io_out_ready),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_tag(g_io_out_bits_tag),
    .io_out_bits_set(g_io_out_bits_set),
    .io_out_bits_needT(g_io_out_bits_needT),
    .io_out_bits_source(g_io_out_bits_source),
    .io_out_bits_vaddr(g_io_out_bits_vaddr),
    .io_out_bits_reqsource(g_io_out_bits_reqsource)
  );

  Pipeline_2_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_tag(io_in_bits_tag),
    .io_in_bits_set(io_in_bits_set),
    .io_in_bits_needT(io_in_bits_needT),
    .io_in_bits_source(io_in_bits_source),
    .io_in_bits_vaddr(io_in_bits_vaddr),
    .io_in_bits_hit(io_in_bits_hit),
    .io_in_bits_prefetched(io_in_bits_prefetched),
    .io_in_bits_pfsource(io_in_bits_pfsource),
    .io_in_bits_reqsource(io_in_bits_reqsource),
    .io_out_ready(io_out_ready),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_tag(i_io_out_bits_tag),
    .io_out_bits_set(i_io_out_bits_set),
    .io_out_bits_needT(i_io_out_bits_needT),
    .io_out_bits_source(i_io_out_bits_source),
    .io_out_bits_vaddr(i_io_out_bits_vaddr),
    .io_out_bits_reqsource(i_io_out_bits_reqsource)
  );

  task automatic drive_random();
    io_in_valid = $random;
    io_in_bits_tag = $random;
    io_in_bits_set = $random;
    io_in_bits_needT = $random;
    io_in_bits_source = $random;
    io_in_bits_vaddr = $random;
    io_in_bits_hit = $random;
    io_in_bits_prefetched = $random;
    io_in_bits_pfsource = $random;
    io_in_bits_reqsource = $random;
    io_out_ready = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_in_ready: g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_valid: g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits_tag !== i_io_out_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_tag: g=%h i=%h", cyc, g_io_out_bits_tag, i_io_out_bits_tag); end
    if (g_io_out_bits_set !== i_io_out_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_set: g=%h i=%h", cyc, g_io_out_bits_set, i_io_out_bits_set); end
    if (g_io_out_bits_needT !== i_io_out_bits_needT) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_needT: g=%h i=%h", cyc, g_io_out_bits_needT, i_io_out_bits_needT); end
    if (g_io_out_bits_source !== i_io_out_bits_source) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_source: g=%h i=%h", cyc, g_io_out_bits_source, i_io_out_bits_source); end
    if (g_io_out_bits_vaddr !== i_io_out_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_vaddr: g=%h i=%h", cyc, g_io_out_bits_vaddr, i_io_out_bits_vaddr); end
    if (g_io_out_bits_reqsource !== i_io_out_bits_reqsource) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_reqsource: g=%h i=%h", cyc, g_io_out_bits_reqsource, i_io_out_bits_reqsource); end
  endtask

  initial begin
    rst = 1'b1;
    io_in_valid = '0;
    io_in_bits_tag = '0;
    io_in_bits_set = '0;
    io_in_bits_needT = '0;
    io_in_bits_source = '0;
    io_in_bits_vaddr = '0;
    io_in_bits_hit = '0;
    io_in_bits_prefetched = '0;
    io_in_bits_pfsource = '0;
    io_in_bits_reqsource = '0;
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
