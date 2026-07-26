// 自动生成: gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_in_req_valid;
  logic [49:0] io_in_req_bits_full_vaddr;
  logic [43:0] io_in_req_bits_base_vaddr;
  logic io_in_req_bits_needT;
  logic [6:0] io_in_req_bits_source;
  logic io_tlb_req_resp_valid;
  logic [47:0] io_tlb_req_resp_bits_paddr_0;
  logic [1:0] io_tlb_req_resp_bits_pbmt;
  logic io_tlb_req_resp_bits_miss;
  logic io_tlb_req_resp_bits_excp_0_gpf_ld;
  logic io_tlb_req_resp_bits_excp_0_pf_ld;
  logic io_tlb_req_resp_bits_excp_0_af_ld;
  logic io_tlb_req_pmp_resp_ld;
  logic io_tlb_req_pmp_resp_mmio;
  logic io_out_req_ready;
  wire g_io_tlb_req_req_valid;
  wire i_io_tlb_req_req_valid;
  wire [49:0] g_io_tlb_req_req_bits_vaddr;
  wire [49:0] i_io_tlb_req_req_bits_vaddr;
  wire [2:0] g_io_tlb_req_req_bits_cmd;
  wire [2:0] i_io_tlb_req_req_bits_cmd;
  wire g_io_tlb_req_req_bits_kill;
  wire i_io_tlb_req_req_bits_kill;
  wire g_io_tlb_req_req_bits_no_translate;
  wire i_io_tlb_req_req_bits_no_translate;
  wire g_io_out_req_valid;
  wire i_io_out_req_valid;
  wire [32:0] g_io_out_req_bits_tag;
  wire [32:0] i_io_out_req_bits_tag;
  wire [8:0] g_io_out_req_bits_set;
  wire [8:0] i_io_out_req_bits_set;
  wire [43:0] g_io_out_req_bits_vaddr;
  wire [43:0] i_io_out_req_bits_vaddr;
  wire g_io_out_req_bits_needT;
  wire i_io_out_req_bits_needT;
  wire [6:0] g_io_out_req_bits_source;
  wire [6:0] i_io_out_req_bits_source;

  PrefetchReqBuffer dut_g (
    .clock(clk), .reset(rst),
    .io_in_req_valid(io_in_req_valid),
    .io_in_req_bits_full_vaddr(io_in_req_bits_full_vaddr),
    .io_in_req_bits_base_vaddr(io_in_req_bits_base_vaddr),
    .io_in_req_bits_needT(io_in_req_bits_needT),
    .io_in_req_bits_source(io_in_req_bits_source),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(io_tlb_req_pmp_resp_mmio),
    .io_out_req_ready(io_out_req_ready),
    .io_tlb_req_req_valid(g_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(g_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(g_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_kill(g_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(g_io_tlb_req_req_bits_no_translate),
    .io_out_req_valid(g_io_out_req_valid),
    .io_out_req_bits_tag(g_io_out_req_bits_tag),
    .io_out_req_bits_set(g_io_out_req_bits_set),
    .io_out_req_bits_vaddr(g_io_out_req_bits_vaddr),
    .io_out_req_bits_needT(g_io_out_req_bits_needT),
    .io_out_req_bits_source(g_io_out_req_bits_source)
  );

  PrefetchReqBuffer_xs dut_i (
    .clock(clk), .reset(rst),
    .io_in_req_valid(io_in_req_valid),
    .io_in_req_bits_full_vaddr(io_in_req_bits_full_vaddr),
    .io_in_req_bits_base_vaddr(io_in_req_bits_base_vaddr),
    .io_in_req_bits_needT(io_in_req_bits_needT),
    .io_in_req_bits_source(io_in_req_bits_source),
    .io_tlb_req_resp_valid(io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0(io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt(io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss(io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld(io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld(io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld(io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld(io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio(io_tlb_req_pmp_resp_mmio),
    .io_out_req_ready(io_out_req_ready),
    .io_tlb_req_req_valid(i_io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr(i_io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd(i_io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_kill(i_io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate(i_io_tlb_req_req_bits_no_translate),
    .io_out_req_valid(i_io_out_req_valid),
    .io_out_req_bits_tag(i_io_out_req_bits_tag),
    .io_out_req_bits_set(i_io_out_req_bits_set),
    .io_out_req_bits_vaddr(i_io_out_req_bits_vaddr),
    .io_out_req_bits_needT(i_io_out_req_bits_needT),
    .io_out_req_bits_source(i_io_out_req_bits_source)
  );

  // 随机激励: 小地址域 → 频繁去重/合并/填满; tlb resp 覆盖 miss/hit/excp
  task automatic drive_random();
    io_in_req_valid = ($random & 3) != 0; // 3/4 概率有请求
    // 小地址域(低 5 位块号 + 固定高位) → 频繁命中已有条目 / 相邻拍冲突
    io_in_req_bits_full_vaddr = {44'h0, ($random & 5'h1F), 1'b0};
    io_in_req_bits_base_vaddr = {40'h0, ($random & 4'hF)};
    io_in_req_bits_needT      = $random;
    io_in_req_bits_source     = $random & 7'h3;
    // tlb resp: 混合 miss / hit / 各类异常
    io_tlb_req_resp_valid = ($random & 1);
    io_tlb_req_resp_bits_paddr_0 = {$random, $random} & 48'hFFFF;
    io_tlb_req_resp_bits_pbmt = $random & 3;
    io_tlb_req_resp_bits_miss = ($random & 3) == 0; // 1/4 miss
    io_tlb_req_resp_bits_excp_0_gpf_ld = ($random & 15) == 0;
    io_tlb_req_resp_bits_excp_0_pf_ld  = ($random & 15) == 0;
    io_tlb_req_resp_bits_excp_0_af_ld  = ($random & 15) == 0;
    io_tlb_req_pmp_resp_ld   = ($random & 15) == 0;
    io_tlb_req_pmp_resp_mmio = ($random & 15) == 0;
    io_out_req_ready = ($random & 3) != 0; // 出队多为高
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_tlb_req_req_valid !== i_io_tlb_req_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_tlb_req_req_valid: g=%h i=%h", cyc, g_io_tlb_req_req_valid, i_io_tlb_req_req_valid); end
    if (g_io_tlb_req_req_bits_vaddr !== i_io_tlb_req_req_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_tlb_req_req_bits_vaddr: g=%h i=%h", cyc, g_io_tlb_req_req_bits_vaddr, i_io_tlb_req_req_bits_vaddr); end
    if (g_io_tlb_req_req_bits_cmd !== i_io_tlb_req_req_bits_cmd) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_tlb_req_req_bits_cmd: g=%h i=%h", cyc, g_io_tlb_req_req_bits_cmd, i_io_tlb_req_req_bits_cmd); end
    if (g_io_tlb_req_req_bits_kill !== i_io_tlb_req_req_bits_kill) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_tlb_req_req_bits_kill: g=%h i=%h", cyc, g_io_tlb_req_req_bits_kill, i_io_tlb_req_req_bits_kill); end
    if (g_io_tlb_req_req_bits_no_translate !== i_io_tlb_req_req_bits_no_translate) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_tlb_req_req_bits_no_translate: g=%h i=%h", cyc, g_io_tlb_req_req_bits_no_translate, i_io_tlb_req_req_bits_no_translate); end
    if (g_io_out_req_valid !== i_io_out_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_req_valid: g=%h i=%h", cyc, g_io_out_req_valid, i_io_out_req_valid); end
    if (g_io_out_req_bits_tag !== i_io_out_req_bits_tag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_req_bits_tag: g=%h i=%h", cyc, g_io_out_req_bits_tag, i_io_out_req_bits_tag); end
    if (g_io_out_req_bits_set !== i_io_out_req_bits_set) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_req_bits_set: g=%h i=%h", cyc, g_io_out_req_bits_set, i_io_out_req_bits_set); end
    if (g_io_out_req_bits_vaddr !== i_io_out_req_bits_vaddr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_req_bits_vaddr: g=%h i=%h", cyc, g_io_out_req_bits_vaddr, i_io_out_req_bits_vaddr); end
    if (g_io_out_req_bits_needT !== i_io_out_req_bits_needT) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_req_bits_needT: g=%h i=%h", cyc, g_io_out_req_bits_needT, i_io_out_req_bits_needT); end
    if (g_io_out_req_bits_source !== i_io_out_req_bits_source) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_req_bits_source: g=%h i=%h", cyc, g_io_out_req_bits_source, i_io_out_req_bits_source); end
  endtask

  initial begin
    rst = 1'b1;
    io_in_req_valid = '0;
    io_in_req_bits_full_vaddr = '0;
    io_in_req_bits_base_vaddr = '0;
    io_in_req_bits_needT = '0;
    io_in_req_bits_source = '0;
    io_tlb_req_resp_valid = '0;
    io_tlb_req_resp_bits_paddr_0 = '0;
    io_tlb_req_resp_bits_pbmt = '0;
    io_tlb_req_resp_bits_miss = '0;
    io_tlb_req_resp_bits_excp_0_gpf_ld = '0;
    io_tlb_req_resp_bits_excp_0_pf_ld = '0;
    io_tlb_req_resp_bits_excp_0_af_ld = '0;
    io_tlb_req_pmp_resp_ld = '0;
    io_tlb_req_pmp_resp_mmio = '0;
    io_out_req_ready = '0;
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
