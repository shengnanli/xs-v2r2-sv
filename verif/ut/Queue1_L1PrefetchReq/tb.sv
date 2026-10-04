// 自动生成：verif/ut/Queue1_L1PrefetchReq/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Queue1_L1PrefetchReq 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Queue1_L1PrefetchReq =================
  int unsigned q_mode = 0;
  logic q_reset;
  wire  q_g_io_enq_ready, q_i_io_enq_ready;
  logic q_s0_io_enq_ready = '0, q_s1_io_enq_ready = '0;
  logic q_io_enq_valid;
  logic [47:0] q_io_enq_bits_paddr;
  logic [1:0] q_io_enq_bits_alias;
  logic q_io_enq_bits_confidence;
  logic q_io_enq_bits_is_store;
  logic [2:0] q_io_enq_bits_pf_source_value;
  logic q_io_deq_ready;
  wire  q_g_io_deq_valid, q_i_io_deq_valid;
  logic q_s0_io_deq_valid = '0, q_s1_io_deq_valid = '0;
  wire  [47:0] q_g_io_deq_bits_paddr, q_i_io_deq_bits_paddr;
  logic [47:0] q_s0_io_deq_bits_paddr = '0, q_s1_io_deq_bits_paddr = '0;
  wire  [1:0] q_g_io_deq_bits_alias, q_i_io_deq_bits_alias;
  logic [1:0] q_s0_io_deq_bits_alias = '0, q_s1_io_deq_bits_alias = '0;
  wire  q_g_io_deq_bits_confidence, q_i_io_deq_bits_confidence;
  logic q_s0_io_deq_bits_confidence = '0, q_s1_io_deq_bits_confidence = '0;
  wire  q_g_io_deq_bits_is_store, q_i_io_deq_bits_is_store;
  logic q_s0_io_deq_bits_is_store = '0, q_s1_io_deq_bits_is_store = '0;
  wire  [2:0] q_g_io_deq_bits_pf_source_value, q_i_io_deq_bits_pf_source_value;
  logic [2:0] q_s0_io_deq_bits_pf_source_value = '0, q_s1_io_deq_bits_pf_source_value = '0;
  int q_cov_enq = 0;
  int q_cov_deq = 0;
  int q_cov_full_stall = 0;
  int q_cov_reset_mid = 0;
  logic [0:0] q_armed = '0;
  int q_armed_at = -1;
  Queue1_L1PrefetchReq q_u_gold (
    .clock(clk),
    .reset(q_reset),
    .io_enq_ready(q_g_io_enq_ready),
    .io_enq_valid(q_io_enq_valid),
    .io_enq_bits_paddr(q_io_enq_bits_paddr),
    .io_enq_bits_alias(q_io_enq_bits_alias),
    .io_enq_bits_confidence(q_io_enq_bits_confidence),
    .io_enq_bits_is_store(q_io_enq_bits_is_store),
    .io_enq_bits_pf_source_value(q_io_enq_bits_pf_source_value),
    .io_deq_ready(q_io_deq_ready),
    .io_deq_valid(q_g_io_deq_valid),
    .io_deq_bits_paddr(q_g_io_deq_bits_paddr),
    .io_deq_bits_alias(q_g_io_deq_bits_alias),
    .io_deq_bits_confidence(q_g_io_deq_bits_confidence),
    .io_deq_bits_is_store(q_g_io_deq_bits_is_store),
    .io_deq_bits_pf_source_value(q_g_io_deq_bits_pf_source_value)
  );
  Queue1_L1PrefetchReq_xs q_u_impl (
    .clock(clk),
    .reset(q_reset),
    .io_enq_ready(q_i_io_enq_ready),
    .io_enq_valid(q_io_enq_valid),
    .io_enq_bits_paddr(q_io_enq_bits_paddr),
    .io_enq_bits_alias(q_io_enq_bits_alias),
    .io_enq_bits_confidence(q_io_enq_bits_confidence),
    .io_enq_bits_is_store(q_io_enq_bits_is_store),
    .io_enq_bits_pf_source_value(q_io_enq_bits_pf_source_value),
    .io_deq_ready(q_io_deq_ready),
    .io_deq_valid(q_i_io_deq_valid),
    .io_deq_bits_paddr(q_i_io_deq_bits_paddr),
    .io_deq_bits_alias(q_i_io_deq_bits_alias),
    .io_deq_bits_confidence(q_i_io_deq_bits_confidence),
    .io_deq_bits_is_store(q_i_io_deq_bits_is_store),
    .io_deq_bits_pf_source_value(q_i_io_deq_bits_pf_source_value)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) q_mode = $urandom_range(0, 15);
      q_io_enq_valid = 1'($urandom);
      q_io_enq_bits_paddr = 48'({$urandom, $urandom});
      q_io_enq_bits_alias = 2'($urandom);
      q_io_enq_bits_confidence = 1'($urandom);
      q_io_enq_bits_is_store = 1'($urandom);
      q_io_enq_bits_pf_source_value = 3'($urandom);
      q_io_deq_ready = 1'($urandom);
      q_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      #4;
      if (cyc >= RESET_CYC + 0 && (&q_armed)) begin
        checks++;
        if (q_g_io_enq_ready !== q_i_io_enq_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_enq_ready g=%h i=%h", cyc, q_g_io_enq_ready, q_i_io_enq_ready);
        end
        q_s1_io_enq_ready |= q_g_io_enq_ready;
        q_s0_io_enq_ready |= ~q_g_io_enq_ready;
        checks++;
        if (q_g_io_deq_valid !== q_i_io_deq_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_deq_valid g=%h i=%h", cyc, q_g_io_deq_valid, q_i_io_deq_valid);
        end
        q_s1_io_deq_valid |= q_g_io_deq_valid;
        q_s0_io_deq_valid |= ~q_g_io_deq_valid;
        checks++;
        if (q_g_io_deq_bits_paddr !== q_i_io_deq_bits_paddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_deq_bits_paddr g=%h i=%h", cyc, q_g_io_deq_bits_paddr, q_i_io_deq_bits_paddr);
        end
        q_s1_io_deq_bits_paddr |= q_g_io_deq_bits_paddr;
        q_s0_io_deq_bits_paddr |= ~q_g_io_deq_bits_paddr;
        checks++;
        if (q_g_io_deq_bits_alias !== q_i_io_deq_bits_alias) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_deq_bits_alias g=%h i=%h", cyc, q_g_io_deq_bits_alias, q_i_io_deq_bits_alias);
        end
        q_s1_io_deq_bits_alias |= q_g_io_deq_bits_alias;
        q_s0_io_deq_bits_alias |= ~q_g_io_deq_bits_alias;
        checks++;
        if (q_g_io_deq_bits_confidence !== q_i_io_deq_bits_confidence) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_deq_bits_confidence g=%h i=%h", cyc, q_g_io_deq_bits_confidence, q_i_io_deq_bits_confidence);
        end
        q_s1_io_deq_bits_confidence |= q_g_io_deq_bits_confidence;
        q_s0_io_deq_bits_confidence |= ~q_g_io_deq_bits_confidence;
        checks++;
        if (q_g_io_deq_bits_is_store !== q_i_io_deq_bits_is_store) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_deq_bits_is_store g=%h i=%h", cyc, q_g_io_deq_bits_is_store, q_i_io_deq_bits_is_store);
        end
        q_s1_io_deq_bits_is_store |= q_g_io_deq_bits_is_store;
        q_s0_io_deq_bits_is_store |= ~q_g_io_deq_bits_is_store;
        checks++;
        if (q_g_io_deq_bits_pf_source_value !== q_i_io_deq_bits_pf_source_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_L1PrefetchReq.io_deq_bits_pf_source_value g=%h i=%h", cyc, q_g_io_deq_bits_pf_source_value, q_i_io_deq_bits_pf_source_value);
        end
        q_s1_io_deq_bits_pf_source_value |= q_g_io_deq_bits_pf_source_value;
        q_s0_io_deq_bits_pf_source_value |= ~q_g_io_deq_bits_pf_source_value;
        if (q_io_enq_valid && q_g_io_enq_ready) q_cov_enq++;
        if (q_g_io_deq_valid && q_io_deq_ready) q_cov_deq++;
        if (q_g_io_deq_valid && !q_io_deq_ready && q_io_enq_valid) q_cov_full_stall++;
        if (q_reset && cyc > 100) q_cov_reset_mid++;
      end
      if (q_io_enq_valid && q_g_io_enq_ready) q_armed[0] = 1'b1;
      if (q_armed_at < 0 && (&q_armed)) q_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(q_s0_io_enq_ready && q_s1_io_enq_ready)) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_enq_ready 未见过 0 和 1"); end
    if (!(q_s0_io_deq_valid && q_s1_io_deq_valid)) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_valid 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[0] && q_s1_io_deq_bits_paddr[0])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[1] && q_s1_io_deq_bits_paddr[1])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[2] && q_s1_io_deq_bits_paddr[2])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[3] && q_s1_io_deq_bits_paddr[3])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[4] && q_s1_io_deq_bits_paddr[4])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[4] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[5] && q_s1_io_deq_bits_paddr[5])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[5] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[6] && q_s1_io_deq_bits_paddr[6])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[6] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[7] && q_s1_io_deq_bits_paddr[7])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[7] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[8] && q_s1_io_deq_bits_paddr[8])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[8] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[9] && q_s1_io_deq_bits_paddr[9])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[9] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[10] && q_s1_io_deq_bits_paddr[10])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[10] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[11] && q_s1_io_deq_bits_paddr[11])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[11] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[12] && q_s1_io_deq_bits_paddr[12])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[12] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[13] && q_s1_io_deq_bits_paddr[13])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[13] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[14] && q_s1_io_deq_bits_paddr[14])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[14] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[15] && q_s1_io_deq_bits_paddr[15])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[15] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[16] && q_s1_io_deq_bits_paddr[16])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[16] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[17] && q_s1_io_deq_bits_paddr[17])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[17] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[18] && q_s1_io_deq_bits_paddr[18])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[18] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[19] && q_s1_io_deq_bits_paddr[19])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[19] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[20] && q_s1_io_deq_bits_paddr[20])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[20] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[21] && q_s1_io_deq_bits_paddr[21])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[21] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[22] && q_s1_io_deq_bits_paddr[22])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[22] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[23] && q_s1_io_deq_bits_paddr[23])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[23] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[24] && q_s1_io_deq_bits_paddr[24])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[24] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[25] && q_s1_io_deq_bits_paddr[25])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[25] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[26] && q_s1_io_deq_bits_paddr[26])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[26] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[27] && q_s1_io_deq_bits_paddr[27])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[27] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[28] && q_s1_io_deq_bits_paddr[28])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[28] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[29] && q_s1_io_deq_bits_paddr[29])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[29] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[30] && q_s1_io_deq_bits_paddr[30])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[30] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[31] && q_s1_io_deq_bits_paddr[31])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[31] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[32] && q_s1_io_deq_bits_paddr[32])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[32] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[33] && q_s1_io_deq_bits_paddr[33])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[33] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[34] && q_s1_io_deq_bits_paddr[34])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[34] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[35] && q_s1_io_deq_bits_paddr[35])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[35] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[36] && q_s1_io_deq_bits_paddr[36])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[36] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[37] && q_s1_io_deq_bits_paddr[37])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[37] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[38] && q_s1_io_deq_bits_paddr[38])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[38] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[39] && q_s1_io_deq_bits_paddr[39])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[39] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[40] && q_s1_io_deq_bits_paddr[40])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[40] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[41] && q_s1_io_deq_bits_paddr[41])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[41] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[42] && q_s1_io_deq_bits_paddr[42])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[42] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[43] && q_s1_io_deq_bits_paddr[43])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[43] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[44] && q_s1_io_deq_bits_paddr[44])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[44] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[45] && q_s1_io_deq_bits_paddr[45])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[45] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[46] && q_s1_io_deq_bits_paddr[46])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[46] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_paddr[47] && q_s1_io_deq_bits_paddr[47])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_paddr[47] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_alias[0] && q_s1_io_deq_bits_alias[0])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_alias[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_alias[1] && q_s1_io_deq_bits_alias[1])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_alias[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_confidence && q_s1_io_deq_bits_confidence)) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_confidence 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_is_store && q_s1_io_deq_bits_is_store)) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_is_store 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_pf_source_value[0] && q_s1_io_deq_bits_pf_source_value[0])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_pf_source_value[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_pf_source_value[1] && q_s1_io_deq_bits_pf_source_value[1])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_pf_source_value[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_pf_source_value[2] && q_s1_io_deq_bits_pf_source_value[2])) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.io_deq_bits_pf_source_value[2] 未见过 0 和 1"); end
    $display("[ARM] Queue1_L1PrefetchReq armed_at=%0d", q_armed_at);
    if (q_armed_at < 0) begin cov_fail++; $display("[ARM] Queue1_L1PrefetchReq 从未 arm"); end
    $display("[COV] Queue1_L1PrefetchReq.enq = %0d", q_cov_enq);
    if (q_cov_enq < 50) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.enq < 50"); end
    $display("[COV] Queue1_L1PrefetchReq.deq = %0d", q_cov_deq);
    if (q_cov_deq < 50) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.deq < 50"); end
    $display("[COV] Queue1_L1PrefetchReq.full_stall = %0d", q_cov_full_stall);
    if (q_cov_full_stall < 50) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.full_stall < 50"); end
    $display("[COV] Queue1_L1PrefetchReq.reset_mid = %0d", q_cov_reset_mid);
    if (q_cov_reset_mid < 50) begin cov_fail++; $display("[COV] Queue1_L1PrefetchReq.reset_mid < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
