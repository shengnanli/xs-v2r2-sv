// 自动生成：verif/ut/Pipeline_1/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Pipeline_1 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Pipeline_1 =================
  int unsigned p_mode = 0;
  logic p_reset;
  wire  p_g_io_in_ready, p_i_io_in_ready;
  logic p_s0_io_in_ready = '0, p_s1_io_in_ready = '0;
  logic p_io_in_valid;
  logic [32:0] p_io_in_bits_tag;
  logic [8:0] p_io_in_bits_set;
  logic [43:0] p_io_in_bits_vaddr;
  logic p_io_in_bits_needT;
  logic [6:0] p_io_in_bits_source;
  logic [4:0] p_io_in_bits_pfSource;
  logic p_io_out_ready;
  wire  p_g_io_out_valid, p_i_io_out_valid;
  logic p_s0_io_out_valid = '0, p_s1_io_out_valid = '0;
  wire  [32:0] p_g_io_out_bits_tag, p_i_io_out_bits_tag;
  logic [32:0] p_s0_io_out_bits_tag = '0, p_s1_io_out_bits_tag = '0;
  wire  [8:0] p_g_io_out_bits_set, p_i_io_out_bits_set;
  logic [8:0] p_s0_io_out_bits_set = '0, p_s1_io_out_bits_set = '0;
  wire  [43:0] p_g_io_out_bits_vaddr, p_i_io_out_bits_vaddr;
  logic [43:0] p_s0_io_out_bits_vaddr = '0, p_s1_io_out_bits_vaddr = '0;
  wire  p_g_io_out_bits_needT, p_i_io_out_bits_needT;
  logic p_s0_io_out_bits_needT = '0, p_s1_io_out_bits_needT = '0;
  wire  [6:0] p_g_io_out_bits_source, p_i_io_out_bits_source;
  logic [6:0] p_s0_io_out_bits_source = '0, p_s1_io_out_bits_source = '0;
  wire  [4:0] p_g_io_out_bits_pfSource, p_i_io_out_bits_pfSource;
  logic [4:0] p_s0_io_out_bits_pfSource = '0, p_s1_io_out_bits_pfSource = '0;
  int p_cov_enq = 0;
  int p_cov_deq = 0;
  int p_cov_full_stall = 0;
  int p_cov_pipe_through = 0;
  int p_cov_reset_mid = 0;
  logic [0:0] p_armed = '0;
  int p_armed_at = -1;
  Pipeline_1 p_u_gold (
    .clock(clk),
    .reset(p_reset),
    .io_in_ready(p_g_io_in_ready),
    .io_in_valid(p_io_in_valid),
    .io_in_bits_tag(p_io_in_bits_tag),
    .io_in_bits_set(p_io_in_bits_set),
    .io_in_bits_vaddr(p_io_in_bits_vaddr),
    .io_in_bits_needT(p_io_in_bits_needT),
    .io_in_bits_source(p_io_in_bits_source),
    .io_in_bits_pfSource(p_io_in_bits_pfSource),
    .io_out_ready(p_io_out_ready),
    .io_out_valid(p_g_io_out_valid),
    .io_out_bits_tag(p_g_io_out_bits_tag),
    .io_out_bits_set(p_g_io_out_bits_set),
    .io_out_bits_vaddr(p_g_io_out_bits_vaddr),
    .io_out_bits_needT(p_g_io_out_bits_needT),
    .io_out_bits_source(p_g_io_out_bits_source),
    .io_out_bits_pfSource(p_g_io_out_bits_pfSource)
  );
  Pipeline_1_xs p_u_impl (
    .clock(clk),
    .reset(p_reset),
    .io_in_ready(p_i_io_in_ready),
    .io_in_valid(p_io_in_valid),
    .io_in_bits_tag(p_io_in_bits_tag),
    .io_in_bits_set(p_io_in_bits_set),
    .io_in_bits_vaddr(p_io_in_bits_vaddr),
    .io_in_bits_needT(p_io_in_bits_needT),
    .io_in_bits_source(p_io_in_bits_source),
    .io_in_bits_pfSource(p_io_in_bits_pfSource),
    .io_out_ready(p_io_out_ready),
    .io_out_valid(p_i_io_out_valid),
    .io_out_bits_tag(p_i_io_out_bits_tag),
    .io_out_bits_set(p_i_io_out_bits_set),
    .io_out_bits_vaddr(p_i_io_out_bits_vaddr),
    .io_out_bits_needT(p_i_io_out_bits_needT),
    .io_out_bits_source(p_i_io_out_bits_source),
    .io_out_bits_pfSource(p_i_io_out_bits_pfSource)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) p_mode = $urandom_range(0, 15);
      p_io_in_valid = 1'($urandom);
      p_io_in_bits_tag = 33'({$urandom, $urandom});
      p_io_in_bits_set = 9'($urandom);
      p_io_in_bits_vaddr = 44'({$urandom, $urandom});
      p_io_in_bits_needT = 1'($urandom);
      p_io_in_bits_source = 7'($urandom);
      p_io_in_bits_pfSource = 5'($urandom);
      p_io_out_ready = 1'($urandom);
      p_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      #4;
      if (cyc >= RESET_CYC + 0 && (&p_armed)) begin
        checks++;
        if (p_g_io_in_ready !== p_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_in_ready g=%h i=%h", cyc, p_g_io_in_ready, p_i_io_in_ready);
        end
        p_s1_io_in_ready |= p_g_io_in_ready;
        p_s0_io_in_ready |= ~p_g_io_in_ready;
        checks++;
        if (p_g_io_out_valid !== p_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_valid g=%h i=%h", cyc, p_g_io_out_valid, p_i_io_out_valid);
        end
        p_s1_io_out_valid |= p_g_io_out_valid;
        p_s0_io_out_valid |= ~p_g_io_out_valid;
        checks++;
        if (p_g_io_out_bits_tag !== p_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_bits_tag g=%h i=%h", cyc, p_g_io_out_bits_tag, p_i_io_out_bits_tag);
        end
        p_s1_io_out_bits_tag |= p_g_io_out_bits_tag;
        p_s0_io_out_bits_tag |= ~p_g_io_out_bits_tag;
        checks++;
        if (p_g_io_out_bits_set !== p_i_io_out_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_bits_set g=%h i=%h", cyc, p_g_io_out_bits_set, p_i_io_out_bits_set);
        end
        p_s1_io_out_bits_set |= p_g_io_out_bits_set;
        p_s0_io_out_bits_set |= ~p_g_io_out_bits_set;
        checks++;
        if (p_g_io_out_bits_vaddr !== p_i_io_out_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_bits_vaddr g=%h i=%h", cyc, p_g_io_out_bits_vaddr, p_i_io_out_bits_vaddr);
        end
        p_s1_io_out_bits_vaddr |= p_g_io_out_bits_vaddr;
        p_s0_io_out_bits_vaddr |= ~p_g_io_out_bits_vaddr;
        checks++;
        if (p_g_io_out_bits_needT !== p_i_io_out_bits_needT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_bits_needT g=%h i=%h", cyc, p_g_io_out_bits_needT, p_i_io_out_bits_needT);
        end
        p_s1_io_out_bits_needT |= p_g_io_out_bits_needT;
        p_s0_io_out_bits_needT |= ~p_g_io_out_bits_needT;
        checks++;
        if (p_g_io_out_bits_source !== p_i_io_out_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_bits_source g=%h i=%h", cyc, p_g_io_out_bits_source, p_i_io_out_bits_source);
        end
        p_s1_io_out_bits_source |= p_g_io_out_bits_source;
        p_s0_io_out_bits_source |= ~p_g_io_out_bits_source;
        checks++;
        if (p_g_io_out_bits_pfSource !== p_i_io_out_bits_pfSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_1.io_out_bits_pfSource g=%h i=%h", cyc, p_g_io_out_bits_pfSource, p_i_io_out_bits_pfSource);
        end
        p_s1_io_out_bits_pfSource |= p_g_io_out_bits_pfSource;
        p_s0_io_out_bits_pfSource |= ~p_g_io_out_bits_pfSource;
        if (p_io_in_valid && p_g_io_in_ready) p_cov_enq++;
        if (p_g_io_out_valid && p_io_out_ready) p_cov_deq++;
        if (p_g_io_out_valid && !p_io_out_ready && p_io_in_valid) p_cov_full_stall++;
        if (p_g_io_out_valid && p_io_out_ready && p_io_in_valid && p_g_io_in_ready) p_cov_pipe_through++;
        if (p_reset && cyc > 100) p_cov_reset_mid++;
      end
      if (p_io_in_valid && p_g_io_in_ready) p_armed[0] = 1'b1;
      if (p_armed_at < 0 && (&p_armed)) p_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(p_s0_io_in_ready && p_s1_io_in_ready)) begin cov_fail++; $display("[COV] Pipeline_1.io_in_ready 未见过 0 和 1"); end
    if (!(p_s0_io_out_valid && p_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_1.io_out_valid 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[0] && p_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[1] && p_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[2] && p_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[3] && p_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[4] && p_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[5] && p_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[6] && p_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[7] && p_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[8] && p_s1_io_out_bits_tag[8])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[8] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[9] && p_s1_io_out_bits_tag[9])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[9] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[10] && p_s1_io_out_bits_tag[10])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[10] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[11] && p_s1_io_out_bits_tag[11])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[11] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[12] && p_s1_io_out_bits_tag[12])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[12] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[13] && p_s1_io_out_bits_tag[13])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[13] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[14] && p_s1_io_out_bits_tag[14])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[14] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[15] && p_s1_io_out_bits_tag[15])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[15] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[16] && p_s1_io_out_bits_tag[16])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[16] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[17] && p_s1_io_out_bits_tag[17])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[17] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[18] && p_s1_io_out_bits_tag[18])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[18] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[19] && p_s1_io_out_bits_tag[19])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[19] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[20] && p_s1_io_out_bits_tag[20])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[20] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[21] && p_s1_io_out_bits_tag[21])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[21] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[22] && p_s1_io_out_bits_tag[22])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[22] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[23] && p_s1_io_out_bits_tag[23])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[23] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[24] && p_s1_io_out_bits_tag[24])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[24] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[25] && p_s1_io_out_bits_tag[25])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[25] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[26] && p_s1_io_out_bits_tag[26])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[26] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[27] && p_s1_io_out_bits_tag[27])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[27] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[28] && p_s1_io_out_bits_tag[28])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[28] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[29] && p_s1_io_out_bits_tag[29])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[29] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[30] && p_s1_io_out_bits_tag[30])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[30] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[31] && p_s1_io_out_bits_tag[31])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[31] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_tag[32] && p_s1_io_out_bits_tag[32])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_tag[32] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[0] && p_s1_io_out_bits_set[0])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[0] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[1] && p_s1_io_out_bits_set[1])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[1] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[2] && p_s1_io_out_bits_set[2])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[2] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[3] && p_s1_io_out_bits_set[3])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[3] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[4] && p_s1_io_out_bits_set[4])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[4] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[5] && p_s1_io_out_bits_set[5])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[5] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[6] && p_s1_io_out_bits_set[6])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[6] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[7] && p_s1_io_out_bits_set[7])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[7] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_set[8] && p_s1_io_out_bits_set[8])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_set[8] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[0] && p_s1_io_out_bits_vaddr[0])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[1] && p_s1_io_out_bits_vaddr[1])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[2] && p_s1_io_out_bits_vaddr[2])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[3] && p_s1_io_out_bits_vaddr[3])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[4] && p_s1_io_out_bits_vaddr[4])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[5] && p_s1_io_out_bits_vaddr[5])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[6] && p_s1_io_out_bits_vaddr[6])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[7] && p_s1_io_out_bits_vaddr[7])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[8] && p_s1_io_out_bits_vaddr[8])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[9] && p_s1_io_out_bits_vaddr[9])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[10] && p_s1_io_out_bits_vaddr[10])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[11] && p_s1_io_out_bits_vaddr[11])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[12] && p_s1_io_out_bits_vaddr[12])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[13] && p_s1_io_out_bits_vaddr[13])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[14] && p_s1_io_out_bits_vaddr[14])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[15] && p_s1_io_out_bits_vaddr[15])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[16] && p_s1_io_out_bits_vaddr[16])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[17] && p_s1_io_out_bits_vaddr[17])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[18] && p_s1_io_out_bits_vaddr[18])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[19] && p_s1_io_out_bits_vaddr[19])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[20] && p_s1_io_out_bits_vaddr[20])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[21] && p_s1_io_out_bits_vaddr[21])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[22] && p_s1_io_out_bits_vaddr[22])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[23] && p_s1_io_out_bits_vaddr[23])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[24] && p_s1_io_out_bits_vaddr[24])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[25] && p_s1_io_out_bits_vaddr[25])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[26] && p_s1_io_out_bits_vaddr[26])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[27] && p_s1_io_out_bits_vaddr[27])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[28] && p_s1_io_out_bits_vaddr[28])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[29] && p_s1_io_out_bits_vaddr[29])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[30] && p_s1_io_out_bits_vaddr[30])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[31] && p_s1_io_out_bits_vaddr[31])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[32] && p_s1_io_out_bits_vaddr[32])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[33] && p_s1_io_out_bits_vaddr[33])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[34] && p_s1_io_out_bits_vaddr[34])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[35] && p_s1_io_out_bits_vaddr[35])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[36] && p_s1_io_out_bits_vaddr[36])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[37] && p_s1_io_out_bits_vaddr[37])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[38] && p_s1_io_out_bits_vaddr[38])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[39] && p_s1_io_out_bits_vaddr[39])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[40] && p_s1_io_out_bits_vaddr[40])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[41] && p_s1_io_out_bits_vaddr[41])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[42] && p_s1_io_out_bits_vaddr[42])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_vaddr[43] && p_s1_io_out_bits_vaddr[43])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_needT && p_s1_io_out_bits_needT)) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_needT 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[0] && p_s1_io_out_bits_source[0])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[0] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[1] && p_s1_io_out_bits_source[1])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[1] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[2] && p_s1_io_out_bits_source[2])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[2] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[3] && p_s1_io_out_bits_source[3])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[3] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[4] && p_s1_io_out_bits_source[4])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[4] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[5] && p_s1_io_out_bits_source[5])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[5] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_source[6] && p_s1_io_out_bits_source[6])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_source[6] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_pfSource[0] && p_s1_io_out_bits_pfSource[0])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_pfSource[0] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_pfSource[1] && p_s1_io_out_bits_pfSource[1])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_pfSource[1] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_pfSource[2] && p_s1_io_out_bits_pfSource[2])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_pfSource[2] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_pfSource[3] && p_s1_io_out_bits_pfSource[3])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_pfSource[3] 未见过 0 和 1"); end
    if (!(p_s0_io_out_bits_pfSource[4] && p_s1_io_out_bits_pfSource[4])) begin cov_fail++; $display("[COV] Pipeline_1.io_out_bits_pfSource[4] 未见过 0 和 1"); end
    $display("[ARM] Pipeline_1 armed_at=%0d", p_armed_at);
    if (p_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_1 从未 arm"); end
    $display("[COV] Pipeline_1.enq = %0d", p_cov_enq);
    if (p_cov_enq < 50) begin cov_fail++; $display("[COV] Pipeline_1.enq < 50"); end
    $display("[COV] Pipeline_1.deq = %0d", p_cov_deq);
    if (p_cov_deq < 50) begin cov_fail++; $display("[COV] Pipeline_1.deq < 50"); end
    $display("[COV] Pipeline_1.full_stall = %0d", p_cov_full_stall);
    if (p_cov_full_stall < 50) begin cov_fail++; $display("[COV] Pipeline_1.full_stall < 50"); end
    $display("[COV] Pipeline_1.pipe_through = %0d", p_cov_pipe_through);
    if (p_cov_pipe_through < 50) begin cov_fail++; $display("[COV] Pipeline_1.pipe_through < 50"); end
    $display("[COV] Pipeline_1.reset_mid = %0d", p_cov_reset_mid);
    if (p_cov_reset_mid < 50) begin cov_fail++; $display("[COV] Pipeline_1.reset_mid < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
