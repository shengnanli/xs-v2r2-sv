// tb —— L2PipelineLeaves4：TL2CHICoupledL2 的 4 个 utility.Pipeline 单态化（Pipeline_2/_3/_10/_11）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Pipeline_2 =================
  int unsigned p2_mode = 0;
  logic p2_reset;
  wire  p2_g_io_in_ready, p2_i_io_in_ready;
  logic p2_s0_io_in_ready = '0, p2_s1_io_in_ready = '0;
  logic p2_io_in_valid;
  logic [32:0] p2_io_in_bits_tag;
  logic [8:0] p2_io_in_bits_set;
  logic p2_io_in_bits_needT;
  logic [6:0] p2_io_in_bits_source;
  logic [43:0] p2_io_in_bits_vaddr;
  logic p2_io_in_bits_hit;
  logic p2_io_in_bits_prefetched;
  logic [2:0] p2_io_in_bits_pfsource;
  logic [4:0] p2_io_in_bits_reqsource;
  logic p2_io_out_ready;
  wire  p2_g_io_out_valid, p2_i_io_out_valid;
  logic p2_s0_io_out_valid = '0, p2_s1_io_out_valid = '0;
  wire  [32:0] p2_g_io_out_bits_tag, p2_i_io_out_bits_tag;
  logic [32:0] p2_s0_io_out_bits_tag = '0, p2_s1_io_out_bits_tag = '0;
  wire  [8:0] p2_g_io_out_bits_set, p2_i_io_out_bits_set;
  logic [8:0] p2_s0_io_out_bits_set = '0, p2_s1_io_out_bits_set = '0;
  wire  p2_g_io_out_bits_needT, p2_i_io_out_bits_needT;
  logic p2_s0_io_out_bits_needT = '0, p2_s1_io_out_bits_needT = '0;
  wire  [6:0] p2_g_io_out_bits_source, p2_i_io_out_bits_source;
  logic [6:0] p2_s0_io_out_bits_source = '0, p2_s1_io_out_bits_source = '0;
  wire  [43:0] p2_g_io_out_bits_vaddr, p2_i_io_out_bits_vaddr;
  logic [43:0] p2_s0_io_out_bits_vaddr = '0, p2_s1_io_out_bits_vaddr = '0;
  wire  [4:0] p2_g_io_out_bits_reqsource, p2_i_io_out_bits_reqsource;
  logic [4:0] p2_s0_io_out_bits_reqsource = '0, p2_s1_io_out_bits_reqsource = '0;
  int p2_cov_enq = 0;
  int p2_cov_deq = 0;
  int p2_cov_backpressure = 0;
  int p2_cov_enq_deq_same = 0;
  logic [0:0] p2_armed = '0;
  int p2_armed_at = -1;
  Pipeline_2 p2_u_gold (
    .clock(clk),
    .reset(p2_reset),
    .io_in_ready(p2_g_io_in_ready),
    .io_in_valid(p2_io_in_valid),
    .io_in_bits_tag(p2_io_in_bits_tag),
    .io_in_bits_set(p2_io_in_bits_set),
    .io_in_bits_needT(p2_io_in_bits_needT),
    .io_in_bits_source(p2_io_in_bits_source),
    .io_in_bits_vaddr(p2_io_in_bits_vaddr),
    .io_in_bits_hit(p2_io_in_bits_hit),
    .io_in_bits_prefetched(p2_io_in_bits_prefetched),
    .io_in_bits_pfsource(p2_io_in_bits_pfsource),
    .io_in_bits_reqsource(p2_io_in_bits_reqsource),
    .io_out_ready(p2_io_out_ready),
    .io_out_valid(p2_g_io_out_valid),
    .io_out_bits_tag(p2_g_io_out_bits_tag),
    .io_out_bits_set(p2_g_io_out_bits_set),
    .io_out_bits_needT(p2_g_io_out_bits_needT),
    .io_out_bits_source(p2_g_io_out_bits_source),
    .io_out_bits_vaddr(p2_g_io_out_bits_vaddr),
    .io_out_bits_reqsource(p2_g_io_out_bits_reqsource)
  );
  Pipeline_2_xs p2_u_impl (
    .clock(clk),
    .reset(p2_reset),
    .io_in_ready(p2_i_io_in_ready),
    .io_in_valid(p2_io_in_valid),
    .io_in_bits_tag(p2_io_in_bits_tag),
    .io_in_bits_set(p2_io_in_bits_set),
    .io_in_bits_needT(p2_io_in_bits_needT),
    .io_in_bits_source(p2_io_in_bits_source),
    .io_in_bits_vaddr(p2_io_in_bits_vaddr),
    .io_in_bits_hit(p2_io_in_bits_hit),
    .io_in_bits_prefetched(p2_io_in_bits_prefetched),
    .io_in_bits_pfsource(p2_io_in_bits_pfsource),
    .io_in_bits_reqsource(p2_io_in_bits_reqsource),
    .io_out_ready(p2_io_out_ready),
    .io_out_valid(p2_i_io_out_valid),
    .io_out_bits_tag(p2_i_io_out_bits_tag),
    .io_out_bits_set(p2_i_io_out_bits_set),
    .io_out_bits_needT(p2_i_io_out_bits_needT),
    .io_out_bits_source(p2_i_io_out_bits_source),
    .io_out_bits_vaddr(p2_i_io_out_bits_vaddr),
    .io_out_bits_reqsource(p2_i_io_out_bits_reqsource)
  );

  // ================= Pipeline_3 =================
  int unsigned p3_mode = 0;
  logic p3_reset;
  wire  p3_g_io_in_ready, p3_i_io_in_ready;
  logic p3_s0_io_in_ready = '0, p3_s1_io_in_ready = '0;
  logic p3_io_in_valid;
  logic [32:0] p3_io_in_bits_tag;
  logic [8:0] p3_io_in_bits_set;
  logic [43:0] p3_io_in_bits_vaddr;
  logic [4:0] p3_io_in_bits_pfSource;
  logic p3_io_out_ready;
  wire  p3_g_io_out_valid, p3_i_io_out_valid;
  logic p3_s0_io_out_valid = '0, p3_s1_io_out_valid = '0;
  wire  [4:0] p3_g_io_out_bits_pfSource, p3_i_io_out_bits_pfSource;
  logic [4:0] p3_s0_io_out_bits_pfSource = '0, p3_s1_io_out_bits_pfSource = '0;
  int p3_cov_enq = 0;
  int p3_cov_deq = 0;
  int p3_cov_backpressure = 0;
  int p3_cov_enq_deq_same = 0;
  logic [0:0] p3_armed = '0;
  int p3_armed_at = -1;
  Pipeline_3 p3_u_gold (
    .clock(clk),
    .reset(p3_reset),
    .io_in_ready(p3_g_io_in_ready),
    .io_in_valid(p3_io_in_valid),
    .io_in_bits_tag(p3_io_in_bits_tag),
    .io_in_bits_set(p3_io_in_bits_set),
    .io_in_bits_vaddr(p3_io_in_bits_vaddr),
    .io_in_bits_pfSource(p3_io_in_bits_pfSource),
    .io_out_ready(p3_io_out_ready),
    .io_out_valid(p3_g_io_out_valid),
    .io_out_bits_pfSource(p3_g_io_out_bits_pfSource)
  );
  Pipeline_3_xs p3_u_impl (
    .clock(clk),
    .reset(p3_reset),
    .io_in_ready(p3_i_io_in_ready),
    .io_in_valid(p3_io_in_valid),
    .io_in_bits_tag(p3_io_in_bits_tag),
    .io_in_bits_set(p3_io_in_bits_set),
    .io_in_bits_vaddr(p3_io_in_bits_vaddr),
    .io_in_bits_pfSource(p3_io_in_bits_pfSource),
    .io_out_ready(p3_io_out_ready),
    .io_out_valid(p3_i_io_out_valid),
    .io_out_bits_pfSource(p3_i_io_out_bits_pfSource)
  );

  // ================= Pipeline_10 =================
  int unsigned p10_mode = 0;
  logic p10_reset;
  logic p10_io_in_valid;
  logic [31:0] p10_io_in_bits;
  wire  p10_g_io_out_valid, p10_i_io_out_valid;
  logic p10_s0_io_out_valid = '0, p10_s1_io_out_valid = '0;
  wire  [31:0] p10_g_io_out_bits, p10_i_io_out_bits;
  logic [31:0] p10_s0_io_out_bits = '0, p10_s1_io_out_bits = '0;
  int p10_cov_enq = 0;
  int p10_cov_out = 0;
  logic [0:0] p10_armed = '0;
  int p10_armed_at = -1;
  Pipeline_10 p10_u_gold (
    .clock(clk),
    .reset(p10_reset),
    .io_in_valid(p10_io_in_valid),
    .io_in_bits(p10_io_in_bits),
    .io_out_valid(p10_g_io_out_valid),
    .io_out_bits(p10_g_io_out_bits)
  );
  Pipeline_10_xs p10_u_impl (
    .clock(clk),
    .reset(p10_reset),
    .io_in_valid(p10_io_in_valid),
    .io_in_bits(p10_io_in_bits),
    .io_out_valid(p10_i_io_out_valid),
    .io_out_bits(p10_i_io_out_bits)
  );

  // ================= Pipeline_11 =================
  int unsigned p11_mode = 0;
  logic p11_reset;
  logic p11_io_in_valid;
  logic [31:0] p11_io_in_bits;
  wire  p11_g_io_out_valid, p11_i_io_out_valid;
  logic p11_s0_io_out_valid = '0, p11_s1_io_out_valid = '0;
  wire  [31:0] p11_g_io_out_bits, p11_i_io_out_bits;
  logic [31:0] p11_s0_io_out_bits = '0, p11_s1_io_out_bits = '0;
  int p11_cov_enq = 0;
  int p11_cov_out = 0;
  logic [0:0] p11_armed = '0;
  int p11_armed_at = -1;
  Pipeline_11 p11_u_gold (
    .clock(clk),
    .reset(p11_reset),
    .io_in_valid(p11_io_in_valid),
    .io_in_bits(p11_io_in_bits),
    .io_out_valid(p11_g_io_out_valid),
    .io_out_bits(p11_g_io_out_bits)
  );
  Pipeline_11_xs p11_u_impl (
    .clock(clk),
    .reset(p11_reset),
    .io_in_valid(p11_io_in_valid),
    .io_in_bits(p11_io_in_bits),
    .io_out_valid(p11_i_io_out_valid),
    .io_out_bits(p11_i_io_out_bits)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) p2_mode = $urandom_range(0, 15);
      p2_io_in_valid = 1'($urandom);
      p2_io_in_bits_tag = 33'({$urandom, $urandom});
      p2_io_in_bits_set = 9'($urandom);
      p2_io_in_bits_needT = 1'($urandom);
      p2_io_in_bits_source = 7'($urandom);
      p2_io_in_bits_vaddr = 44'({$urandom, $urandom});
      p2_io_in_bits_hit = 1'($urandom);
      p2_io_in_bits_prefetched = 1'($urandom);
      p2_io_in_bits_pfsource = 3'($urandom);
      p2_io_in_bits_reqsource = 5'($urandom);
      p2_io_out_ready = 1'($urandom);
      p2_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p2
        case (p2_mode % 3)
          0: p2_io_in_valid = ($urandom_range(0, 3) == 0);
          1: p2_io_in_valid = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
        p2_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      if (cyc % 4000 == 0) p3_mode = $urandom_range(0, 15);
      p3_io_in_valid = 1'($urandom);
      p3_io_in_bits_tag = 33'({$urandom, $urandom});
      p3_io_in_bits_set = 9'($urandom);
      p3_io_in_bits_vaddr = 44'({$urandom, $urandom});
      p3_io_in_bits_pfSource = 5'($urandom);
      p3_io_out_ready = 1'($urandom);
      p3_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p3
        case (p3_mode % 3)
          0: p3_io_in_valid = ($urandom_range(0, 3) == 0);
          1: p3_io_in_valid = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
        p3_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      if (cyc % 4000 == 0) p10_mode = $urandom_range(0, 15);
      p10_io_in_valid = 1'($urandom);
      p10_io_in_bits = 32'($urandom);
      p10_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p10
        case (p10_mode % 3)
          0: p10_io_in_valid = ($urandom_range(0, 3) == 0);
          1: p10_io_in_valid = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
      end
      if (cyc % 4000 == 0) p11_mode = $urandom_range(0, 15);
      p11_io_in_valid = 1'($urandom);
      p11_io_in_bits = 32'($urandom);
      p11_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p11
        case (p11_mode % 3)
          0: p11_io_in_valid = ($urandom_range(0, 3) == 0);
          1: p11_io_in_valid = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&p2_armed)) begin
        checks++;
        if (p2_g_io_in_ready !== p2_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_in_ready g=%h i=%h", cyc, p2_g_io_in_ready, p2_i_io_in_ready);
        end
        p2_s1_io_in_ready |= p2_g_io_in_ready;
        p2_s0_io_in_ready |= ~p2_g_io_in_ready;
        checks++;
        if (p2_g_io_out_valid !== p2_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_valid g=%h i=%h", cyc, p2_g_io_out_valid, p2_i_io_out_valid);
        end
        p2_s1_io_out_valid |= p2_g_io_out_valid;
        p2_s0_io_out_valid |= ~p2_g_io_out_valid;
        checks++;
        if (p2_g_io_out_bits_tag !== p2_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_bits_tag g=%h i=%h", cyc, p2_g_io_out_bits_tag, p2_i_io_out_bits_tag);
        end
        p2_s1_io_out_bits_tag |= p2_g_io_out_bits_tag;
        p2_s0_io_out_bits_tag |= ~p2_g_io_out_bits_tag;
        checks++;
        if (p2_g_io_out_bits_set !== p2_i_io_out_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_bits_set g=%h i=%h", cyc, p2_g_io_out_bits_set, p2_i_io_out_bits_set);
        end
        p2_s1_io_out_bits_set |= p2_g_io_out_bits_set;
        p2_s0_io_out_bits_set |= ~p2_g_io_out_bits_set;
        checks++;
        if (p2_g_io_out_bits_needT !== p2_i_io_out_bits_needT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_bits_needT g=%h i=%h", cyc, p2_g_io_out_bits_needT, p2_i_io_out_bits_needT);
        end
        p2_s1_io_out_bits_needT |= p2_g_io_out_bits_needT;
        p2_s0_io_out_bits_needT |= ~p2_g_io_out_bits_needT;
        checks++;
        if (p2_g_io_out_bits_source !== p2_i_io_out_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_bits_source g=%h i=%h", cyc, p2_g_io_out_bits_source, p2_i_io_out_bits_source);
        end
        p2_s1_io_out_bits_source |= p2_g_io_out_bits_source;
        p2_s0_io_out_bits_source |= ~p2_g_io_out_bits_source;
        checks++;
        if (p2_g_io_out_bits_vaddr !== p2_i_io_out_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_bits_vaddr g=%h i=%h", cyc, p2_g_io_out_bits_vaddr, p2_i_io_out_bits_vaddr);
        end
        p2_s1_io_out_bits_vaddr |= p2_g_io_out_bits_vaddr;
        p2_s0_io_out_bits_vaddr |= ~p2_g_io_out_bits_vaddr;
        checks++;
        if (p2_g_io_out_bits_reqsource !== p2_i_io_out_bits_reqsource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_2.io_out_bits_reqsource g=%h i=%h", cyc, p2_g_io_out_bits_reqsource, p2_i_io_out_bits_reqsource);
        end
        p2_s1_io_out_bits_reqsource |= p2_g_io_out_bits_reqsource;
        p2_s0_io_out_bits_reqsource |= ~p2_g_io_out_bits_reqsource;
        if (p2_io_in_valid && p2_g_io_in_ready) p2_cov_enq++;
        if (p2_g_io_out_valid && p2_io_out_ready) p2_cov_deq++;
        if (p2_g_io_out_valid && !p2_io_out_ready) p2_cov_backpressure++;
        if (p2_io_in_valid && p2_g_io_in_ready && p2_g_io_out_valid && p2_io_out_ready) p2_cov_enq_deq_same++;
      end
      if (p2_io_in_valid && p2_g_io_in_ready && !p2_reset) p2_armed[0] = 1'b1;
      if (p2_armed_at < 0 && (&p2_armed)) p2_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && (&p3_armed)) begin
        checks++;
        if (p3_g_io_in_ready !== p3_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_3.io_in_ready g=%h i=%h", cyc, p3_g_io_in_ready, p3_i_io_in_ready);
        end
        p3_s1_io_in_ready |= p3_g_io_in_ready;
        p3_s0_io_in_ready |= ~p3_g_io_in_ready;
        checks++;
        if (p3_g_io_out_valid !== p3_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_3.io_out_valid g=%h i=%h", cyc, p3_g_io_out_valid, p3_i_io_out_valid);
        end
        p3_s1_io_out_valid |= p3_g_io_out_valid;
        p3_s0_io_out_valid |= ~p3_g_io_out_valid;
        checks++;
        if (p3_g_io_out_bits_pfSource !== p3_i_io_out_bits_pfSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_3.io_out_bits_pfSource g=%h i=%h", cyc, p3_g_io_out_bits_pfSource, p3_i_io_out_bits_pfSource);
        end
        p3_s1_io_out_bits_pfSource |= p3_g_io_out_bits_pfSource;
        p3_s0_io_out_bits_pfSource |= ~p3_g_io_out_bits_pfSource;
        if (p3_io_in_valid && p3_g_io_in_ready) p3_cov_enq++;
        if (p3_g_io_out_valid && p3_io_out_ready) p3_cov_deq++;
        if (p3_g_io_out_valid && !p3_io_out_ready) p3_cov_backpressure++;
        if (p3_io_in_valid && p3_g_io_in_ready && p3_g_io_out_valid && p3_io_out_ready) p3_cov_enq_deq_same++;
      end
      if (p3_io_in_valid && p3_g_io_in_ready && !p3_reset) p3_armed[0] = 1'b1;
      if (p3_armed_at < 0 && (&p3_armed)) p3_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && p10_armed_at >= 0 && cyc >= p10_armed_at) begin
        checks++;
        if (p10_g_io_out_valid !== p10_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_10.io_out_valid g=%h i=%h", cyc, p10_g_io_out_valid, p10_i_io_out_valid);
        end
        p10_s1_io_out_valid |= p10_g_io_out_valid;
        p10_s0_io_out_valid |= ~p10_g_io_out_valid;
        checks++;
        if (p10_g_io_out_bits !== p10_i_io_out_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_10.io_out_bits g=%h i=%h", cyc, p10_g_io_out_bits, p10_i_io_out_bits);
        end
        p10_s1_io_out_bits |= p10_g_io_out_bits;
        p10_s0_io_out_bits |= ~p10_g_io_out_bits;
        if (p10_io_in_valid) p10_cov_enq++;
        if (p10_g_io_out_valid) p10_cov_out++;
      end
      if (p10_io_in_valid && !p10_reset) p10_armed[0] = 1'b1;
      if (p10_armed_at < 0 && (&p10_armed)) p10_armed_at = cyc + 1 + 1;
      if (cyc >= RESET_CYC + 0 && (&p11_armed)) begin
        checks++;
        if (p11_g_io_out_valid !== p11_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_11.io_out_valid g=%h i=%h", cyc, p11_g_io_out_valid, p11_i_io_out_valid);
        end
        p11_s1_io_out_valid |= p11_g_io_out_valid;
        p11_s0_io_out_valid |= ~p11_g_io_out_valid;
        checks++;
        if (p11_g_io_out_bits !== p11_i_io_out_bits) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_11.io_out_bits g=%h i=%h", cyc, p11_g_io_out_bits, p11_i_io_out_bits);
        end
        p11_s1_io_out_bits |= p11_g_io_out_bits;
        p11_s0_io_out_bits |= ~p11_g_io_out_bits;
        if (p11_io_in_valid) p11_cov_enq++;
        if (p11_g_io_out_valid) p11_cov_out++;
      end
      if (p11_io_in_valid && !p11_reset) p11_armed[0] = 1'b1;
      if (p11_armed_at < 0 && (&p11_armed)) p11_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(p2_s0_io_in_ready && p2_s1_io_in_ready)) begin cov_fail++; $display("[COV] Pipeline_2.io_in_ready 未见过 0 和 1"); end
    if (!(p2_s0_io_out_valid && p2_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_2.io_out_valid 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[0] && p2_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[1] && p2_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[2] && p2_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[3] && p2_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[4] && p2_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[5] && p2_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[6] && p2_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[7] && p2_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[8] && p2_s1_io_out_bits_tag[8])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[8] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[9] && p2_s1_io_out_bits_tag[9])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[9] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[10] && p2_s1_io_out_bits_tag[10])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[10] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[11] && p2_s1_io_out_bits_tag[11])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[11] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[12] && p2_s1_io_out_bits_tag[12])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[12] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[13] && p2_s1_io_out_bits_tag[13])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[13] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[14] && p2_s1_io_out_bits_tag[14])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[14] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[15] && p2_s1_io_out_bits_tag[15])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[15] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[16] && p2_s1_io_out_bits_tag[16])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[16] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[17] && p2_s1_io_out_bits_tag[17])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[17] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[18] && p2_s1_io_out_bits_tag[18])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[18] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[19] && p2_s1_io_out_bits_tag[19])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[19] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[20] && p2_s1_io_out_bits_tag[20])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[20] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[21] && p2_s1_io_out_bits_tag[21])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[21] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[22] && p2_s1_io_out_bits_tag[22])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[22] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[23] && p2_s1_io_out_bits_tag[23])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[23] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[24] && p2_s1_io_out_bits_tag[24])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[24] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[25] && p2_s1_io_out_bits_tag[25])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[25] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[26] && p2_s1_io_out_bits_tag[26])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[26] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[27] && p2_s1_io_out_bits_tag[27])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[27] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[28] && p2_s1_io_out_bits_tag[28])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[28] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[29] && p2_s1_io_out_bits_tag[29])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[29] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[30] && p2_s1_io_out_bits_tag[30])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[30] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[31] && p2_s1_io_out_bits_tag[31])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[31] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_tag[32] && p2_s1_io_out_bits_tag[32])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_tag[32] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[0] && p2_s1_io_out_bits_set[0])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[0] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[1] && p2_s1_io_out_bits_set[1])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[1] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[2] && p2_s1_io_out_bits_set[2])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[2] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[3] && p2_s1_io_out_bits_set[3])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[3] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[4] && p2_s1_io_out_bits_set[4])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[4] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[5] && p2_s1_io_out_bits_set[5])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[5] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[6] && p2_s1_io_out_bits_set[6])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[6] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[7] && p2_s1_io_out_bits_set[7])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[7] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_set[8] && p2_s1_io_out_bits_set[8])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_set[8] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_needT && p2_s1_io_out_bits_needT)) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_needT 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[0] && p2_s1_io_out_bits_source[0])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[0] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[1] && p2_s1_io_out_bits_source[1])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[1] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[2] && p2_s1_io_out_bits_source[2])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[2] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[3] && p2_s1_io_out_bits_source[3])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[3] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[4] && p2_s1_io_out_bits_source[4])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[4] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[5] && p2_s1_io_out_bits_source[5])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[5] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_source[6] && p2_s1_io_out_bits_source[6])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_source[6] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[0] && p2_s1_io_out_bits_vaddr[0])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[1] && p2_s1_io_out_bits_vaddr[1])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[2] && p2_s1_io_out_bits_vaddr[2])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[3] && p2_s1_io_out_bits_vaddr[3])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[4] && p2_s1_io_out_bits_vaddr[4])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[5] && p2_s1_io_out_bits_vaddr[5])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[6] && p2_s1_io_out_bits_vaddr[6])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[7] && p2_s1_io_out_bits_vaddr[7])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[8] && p2_s1_io_out_bits_vaddr[8])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[9] && p2_s1_io_out_bits_vaddr[9])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[10] && p2_s1_io_out_bits_vaddr[10])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[11] && p2_s1_io_out_bits_vaddr[11])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[12] && p2_s1_io_out_bits_vaddr[12])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[13] && p2_s1_io_out_bits_vaddr[13])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[14] && p2_s1_io_out_bits_vaddr[14])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[15] && p2_s1_io_out_bits_vaddr[15])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[16] && p2_s1_io_out_bits_vaddr[16])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[17] && p2_s1_io_out_bits_vaddr[17])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[18] && p2_s1_io_out_bits_vaddr[18])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[19] && p2_s1_io_out_bits_vaddr[19])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[20] && p2_s1_io_out_bits_vaddr[20])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[21] && p2_s1_io_out_bits_vaddr[21])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[22] && p2_s1_io_out_bits_vaddr[22])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[23] && p2_s1_io_out_bits_vaddr[23])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[24] && p2_s1_io_out_bits_vaddr[24])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[25] && p2_s1_io_out_bits_vaddr[25])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[26] && p2_s1_io_out_bits_vaddr[26])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[27] && p2_s1_io_out_bits_vaddr[27])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[28] && p2_s1_io_out_bits_vaddr[28])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[29] && p2_s1_io_out_bits_vaddr[29])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[30] && p2_s1_io_out_bits_vaddr[30])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[31] && p2_s1_io_out_bits_vaddr[31])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[32] && p2_s1_io_out_bits_vaddr[32])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[33] && p2_s1_io_out_bits_vaddr[33])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[34] && p2_s1_io_out_bits_vaddr[34])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[35] && p2_s1_io_out_bits_vaddr[35])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[36] && p2_s1_io_out_bits_vaddr[36])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[37] && p2_s1_io_out_bits_vaddr[37])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[38] && p2_s1_io_out_bits_vaddr[38])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[39] && p2_s1_io_out_bits_vaddr[39])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[40] && p2_s1_io_out_bits_vaddr[40])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[41] && p2_s1_io_out_bits_vaddr[41])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[42] && p2_s1_io_out_bits_vaddr[42])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_vaddr[43] && p2_s1_io_out_bits_vaddr[43])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_reqsource[0] && p2_s1_io_out_bits_reqsource[0])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_reqsource[0] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_reqsource[1] && p2_s1_io_out_bits_reqsource[1])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_reqsource[1] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_reqsource[2] && p2_s1_io_out_bits_reqsource[2])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_reqsource[2] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_reqsource[3] && p2_s1_io_out_bits_reqsource[3])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_reqsource[3] 未见过 0 和 1"); end
    if (!(p2_s0_io_out_bits_reqsource[4] && p2_s1_io_out_bits_reqsource[4])) begin cov_fail++; $display("[COV] Pipeline_2.io_out_bits_reqsource[4] 未见过 0 和 1"); end
    $display("[ARM] Pipeline_2 armed_at=%0d", p2_armed_at);
    if (p2_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_2 从未 arm"); end
    $display("[COV] Pipeline_2.enq = %0d", p2_cov_enq);
    if (p2_cov_enq < 100) begin cov_fail++; $display("[COV] Pipeline_2.enq < 100"); end
    $display("[COV] Pipeline_2.deq = %0d", p2_cov_deq);
    if (p2_cov_deq < 100) begin cov_fail++; $display("[COV] Pipeline_2.deq < 100"); end
    $display("[COV] Pipeline_2.backpressure = %0d", p2_cov_backpressure);
    if (p2_cov_backpressure < 100) begin cov_fail++; $display("[COV] Pipeline_2.backpressure < 100"); end
    $display("[COV] Pipeline_2.enq_deq_same = %0d", p2_cov_enq_deq_same);
    if (p2_cov_enq_deq_same < 100) begin cov_fail++; $display("[COV] Pipeline_2.enq_deq_same < 100"); end
    if (!(p3_s0_io_in_ready && p3_s1_io_in_ready)) begin cov_fail++; $display("[COV] Pipeline_3.io_in_ready 未见过 0 和 1"); end
    if (!(p3_s0_io_out_valid && p3_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_3.io_out_valid 未见过 0 和 1"); end
    if (!(p3_s0_io_out_bits_pfSource[0] && p3_s1_io_out_bits_pfSource[0])) begin cov_fail++; $display("[COV] Pipeline_3.io_out_bits_pfSource[0] 未见过 0 和 1"); end
    if (!(p3_s0_io_out_bits_pfSource[1] && p3_s1_io_out_bits_pfSource[1])) begin cov_fail++; $display("[COV] Pipeline_3.io_out_bits_pfSource[1] 未见过 0 和 1"); end
    if (!(p3_s0_io_out_bits_pfSource[2] && p3_s1_io_out_bits_pfSource[2])) begin cov_fail++; $display("[COV] Pipeline_3.io_out_bits_pfSource[2] 未见过 0 和 1"); end
    if (!(p3_s0_io_out_bits_pfSource[3] && p3_s1_io_out_bits_pfSource[3])) begin cov_fail++; $display("[COV] Pipeline_3.io_out_bits_pfSource[3] 未见过 0 和 1"); end
    if (!(p3_s0_io_out_bits_pfSource[4] && p3_s1_io_out_bits_pfSource[4])) begin cov_fail++; $display("[COV] Pipeline_3.io_out_bits_pfSource[4] 未见过 0 和 1"); end
    $display("[ARM] Pipeline_3 armed_at=%0d", p3_armed_at);
    if (p3_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_3 从未 arm"); end
    $display("[COV] Pipeline_3.enq = %0d", p3_cov_enq);
    if (p3_cov_enq < 100) begin cov_fail++; $display("[COV] Pipeline_3.enq < 100"); end
    $display("[COV] Pipeline_3.deq = %0d", p3_cov_deq);
    if (p3_cov_deq < 100) begin cov_fail++; $display("[COV] Pipeline_3.deq < 100"); end
    $display("[COV] Pipeline_3.backpressure = %0d", p3_cov_backpressure);
    if (p3_cov_backpressure < 100) begin cov_fail++; $display("[COV] Pipeline_3.backpressure < 100"); end
    $display("[COV] Pipeline_3.enq_deq_same = %0d", p3_cov_enq_deq_same);
    if (p3_cov_enq_deq_same < 100) begin cov_fail++; $display("[COV] Pipeline_3.enq_deq_same < 100"); end
    if (!(p10_s0_io_out_valid && p10_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_10.io_out_valid 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[0] && p10_s1_io_out_bits[0])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[0] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[1] && p10_s1_io_out_bits[1])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[1] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[2] && p10_s1_io_out_bits[2])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[2] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[3] && p10_s1_io_out_bits[3])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[3] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[4] && p10_s1_io_out_bits[4])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[4] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[5] && p10_s1_io_out_bits[5])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[5] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[6] && p10_s1_io_out_bits[6])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[6] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[7] && p10_s1_io_out_bits[7])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[7] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[8] && p10_s1_io_out_bits[8])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[8] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[9] && p10_s1_io_out_bits[9])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[9] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[10] && p10_s1_io_out_bits[10])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[10] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[11] && p10_s1_io_out_bits[11])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[11] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[12] && p10_s1_io_out_bits[12])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[12] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[13] && p10_s1_io_out_bits[13])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[13] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[14] && p10_s1_io_out_bits[14])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[14] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[15] && p10_s1_io_out_bits[15])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[15] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[16] && p10_s1_io_out_bits[16])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[16] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[17] && p10_s1_io_out_bits[17])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[17] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[18] && p10_s1_io_out_bits[18])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[18] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[19] && p10_s1_io_out_bits[19])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[19] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[20] && p10_s1_io_out_bits[20])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[20] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[21] && p10_s1_io_out_bits[21])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[21] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[22] && p10_s1_io_out_bits[22])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[22] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[23] && p10_s1_io_out_bits[23])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[23] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[24] && p10_s1_io_out_bits[24])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[24] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[25] && p10_s1_io_out_bits[25])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[25] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[26] && p10_s1_io_out_bits[26])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[26] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[27] && p10_s1_io_out_bits[27])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[27] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[28] && p10_s1_io_out_bits[28])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[28] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[29] && p10_s1_io_out_bits[29])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[29] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[30] && p10_s1_io_out_bits[30])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[30] 未见过 0 和 1"); end
    if (!(p10_s0_io_out_bits[31] && p10_s1_io_out_bits[31])) begin cov_fail++; $display("[COV] Pipeline_10.io_out_bits[31] 未见过 0 和 1"); end
    $display("[ARM] Pipeline_10 armed_at=%0d", p10_armed_at);
    if (p10_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_10 从未 arm"); end
    $display("[COV] Pipeline_10.enq = %0d", p10_cov_enq);
    if (p10_cov_enq < 100) begin cov_fail++; $display("[COV] Pipeline_10.enq < 100"); end
    $display("[COV] Pipeline_10.out = %0d", p10_cov_out);
    if (p10_cov_out < 100) begin cov_fail++; $display("[COV] Pipeline_10.out < 100"); end
    if (!(p11_s0_io_out_valid && p11_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_11.io_out_valid 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[0] && p11_s1_io_out_bits[0])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[0] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[1] && p11_s1_io_out_bits[1])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[1] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[2] && p11_s1_io_out_bits[2])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[2] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[3] && p11_s1_io_out_bits[3])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[3] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[4] && p11_s1_io_out_bits[4])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[4] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[5] && p11_s1_io_out_bits[5])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[5] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[6] && p11_s1_io_out_bits[6])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[6] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[7] && p11_s1_io_out_bits[7])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[7] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[8] && p11_s1_io_out_bits[8])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[8] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[9] && p11_s1_io_out_bits[9])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[9] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[10] && p11_s1_io_out_bits[10])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[10] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[11] && p11_s1_io_out_bits[11])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[11] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[12] && p11_s1_io_out_bits[12])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[12] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[13] && p11_s1_io_out_bits[13])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[13] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[14] && p11_s1_io_out_bits[14])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[14] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[15] && p11_s1_io_out_bits[15])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[15] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[16] && p11_s1_io_out_bits[16])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[16] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[17] && p11_s1_io_out_bits[17])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[17] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[18] && p11_s1_io_out_bits[18])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[18] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[19] && p11_s1_io_out_bits[19])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[19] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[20] && p11_s1_io_out_bits[20])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[20] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[21] && p11_s1_io_out_bits[21])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[21] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[22] && p11_s1_io_out_bits[22])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[22] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[23] && p11_s1_io_out_bits[23])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[23] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[24] && p11_s1_io_out_bits[24])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[24] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[25] && p11_s1_io_out_bits[25])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[25] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[26] && p11_s1_io_out_bits[26])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[26] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[27] && p11_s1_io_out_bits[27])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[27] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[28] && p11_s1_io_out_bits[28])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[28] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[29] && p11_s1_io_out_bits[29])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[29] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[30] && p11_s1_io_out_bits[30])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[30] 未见过 0 和 1"); end
    if (!(p11_s0_io_out_bits[31] && p11_s1_io_out_bits[31])) begin cov_fail++; $display("[COV] Pipeline_11.io_out_bits[31] 未见过 0 和 1"); end
    $display("[ARM] Pipeline_11 armed_at=%0d", p11_armed_at);
    if (p11_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_11 从未 arm"); end
    $display("[COV] Pipeline_11.enq = %0d", p11_cov_enq);
    if (p11_cov_enq < 100) begin cov_fail++; $display("[COV] Pipeline_11.enq < 100"); end
    $display("[COV] Pipeline_11.out = %0d", p11_cov_out);
    if (p11_cov_out < 100) begin cov_fail++; $display("[COV] Pipeline_11.out < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
