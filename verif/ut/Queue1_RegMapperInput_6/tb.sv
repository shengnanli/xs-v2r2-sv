// 自动生成：verif/ut/Queue1_RegMapperInput_6/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Queue1_RegMapperInput_6 双例化逐拍比对，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Queue1_RegMapperInput_6 =================
  int unsigned q_mode = 0;
  logic q_reset;
  wire  q_g_io_enq_ready, q_i_io_enq_ready;
  logic q_s0_io_enq_ready = '0, q_s1_io_enq_ready = '0;
  logic q_io_enq_valid;
  logic q_io_enq_bits_read;
  logic [3:0] q_io_enq_bits_index;
  logic [63:0] q_io_enq_bits_data;
  logic [7:0] q_io_enq_bits_mask;
  logic [3:0] q_io_enq_bits_extra_tlrr_extra_source;
  logic [1:0] q_io_enq_bits_extra_tlrr_extra_size;
  logic q_io_deq_ready;
  wire  q_g_io_deq_valid, q_i_io_deq_valid;
  logic q_s0_io_deq_valid = '0, q_s1_io_deq_valid = '0;
  wire  q_g_io_deq_bits_read, q_i_io_deq_bits_read;
  logic q_s0_io_deq_bits_read = '0, q_s1_io_deq_bits_read = '0;
  wire  [3:0] q_g_io_deq_bits_index, q_i_io_deq_bits_index;
  logic [3:0] q_s0_io_deq_bits_index = '0, q_s1_io_deq_bits_index = '0;
  wire  [63:0] q_g_io_deq_bits_data, q_i_io_deq_bits_data;
  logic [63:0] q_s0_io_deq_bits_data = '0, q_s1_io_deq_bits_data = '0;
  wire  [7:0] q_g_io_deq_bits_mask, q_i_io_deq_bits_mask;
  logic [7:0] q_s0_io_deq_bits_mask = '0, q_s1_io_deq_bits_mask = '0;
  wire  [3:0] q_g_io_deq_bits_extra_tlrr_extra_source, q_i_io_deq_bits_extra_tlrr_extra_source;
  logic [3:0] q_s0_io_deq_bits_extra_tlrr_extra_source = '0, q_s1_io_deq_bits_extra_tlrr_extra_source = '0;
  wire  [1:0] q_g_io_deq_bits_extra_tlrr_extra_size, q_i_io_deq_bits_extra_tlrr_extra_size;
  logic [1:0] q_s0_io_deq_bits_extra_tlrr_extra_size = '0, q_s1_io_deq_bits_extra_tlrr_extra_size = '0;
  int q_cov_enq = 0;
  int q_cov_deq = 0;
  int q_cov_full_stall = 0;
  int q_cov_reset_mid = 0;
  logic [0:0] q_armed = '0;
  int q_armed_at = -1;
  Queue1_RegMapperInput_6 q_u_gold (
    .clock(clk),
    .reset(q_reset),
    .io_enq_ready(q_g_io_enq_ready),
    .io_enq_valid(q_io_enq_valid),
    .io_enq_bits_read(q_io_enq_bits_read),
    .io_enq_bits_index(q_io_enq_bits_index),
    .io_enq_bits_data(q_io_enq_bits_data),
    .io_enq_bits_mask(q_io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source(q_io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size(q_io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready(q_io_deq_ready),
    .io_deq_valid(q_g_io_deq_valid),
    .io_deq_bits_read(q_g_io_deq_bits_read),
    .io_deq_bits_index(q_g_io_deq_bits_index),
    .io_deq_bits_data(q_g_io_deq_bits_data),
    .io_deq_bits_mask(q_g_io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source(q_g_io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size(q_g_io_deq_bits_extra_tlrr_extra_size)
  );
  Queue1_RegMapperInput_6_xs q_u_impl (
    .clock(clk),
    .reset(q_reset),
    .io_enq_ready(q_i_io_enq_ready),
    .io_enq_valid(q_io_enq_valid),
    .io_enq_bits_read(q_io_enq_bits_read),
    .io_enq_bits_index(q_io_enq_bits_index),
    .io_enq_bits_data(q_io_enq_bits_data),
    .io_enq_bits_mask(q_io_enq_bits_mask),
    .io_enq_bits_extra_tlrr_extra_source(q_io_enq_bits_extra_tlrr_extra_source),
    .io_enq_bits_extra_tlrr_extra_size(q_io_enq_bits_extra_tlrr_extra_size),
    .io_deq_ready(q_io_deq_ready),
    .io_deq_valid(q_i_io_deq_valid),
    .io_deq_bits_read(q_i_io_deq_bits_read),
    .io_deq_bits_index(q_i_io_deq_bits_index),
    .io_deq_bits_data(q_i_io_deq_bits_data),
    .io_deq_bits_mask(q_i_io_deq_bits_mask),
    .io_deq_bits_extra_tlrr_extra_source(q_i_io_deq_bits_extra_tlrr_extra_source),
    .io_deq_bits_extra_tlrr_extra_size(q_i_io_deq_bits_extra_tlrr_extra_size)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) q_mode = $urandom_range(0, 15);
      q_io_enq_valid = 1'($urandom);
      q_io_enq_bits_read = 1'($urandom);
      q_io_enq_bits_index = 4'($urandom);
      q_io_enq_bits_data = 64'({$urandom, $urandom});
      q_io_enq_bits_mask = 8'($urandom);
      q_io_enq_bits_extra_tlrr_extra_source = 4'($urandom);
      q_io_enq_bits_extra_tlrr_extra_size = 2'($urandom);
      q_io_deq_ready = 1'($urandom);
      q_reset = (cyc < RESET_CYC) || ($urandom_range(0, 1999) == 0);
      #4;
      if (cyc >= RESET_CYC + 0 && (&q_armed)) begin
        checks++;
        if (q_g_io_enq_ready !== q_i_io_enq_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_enq_ready g=%h i=%h", cyc, q_g_io_enq_ready, q_i_io_enq_ready);
        end
        q_s1_io_enq_ready |= q_g_io_enq_ready;
        q_s0_io_enq_ready |= ~q_g_io_enq_ready;
        checks++;
        if (q_g_io_deq_valid !== q_i_io_deq_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_valid g=%h i=%h", cyc, q_g_io_deq_valid, q_i_io_deq_valid);
        end
        q_s1_io_deq_valid |= q_g_io_deq_valid;
        q_s0_io_deq_valid |= ~q_g_io_deq_valid;
        checks++;
        if (q_g_io_deq_bits_read !== q_i_io_deq_bits_read) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_read g=%h i=%h", cyc, q_g_io_deq_bits_read, q_i_io_deq_bits_read);
        end
        q_s1_io_deq_bits_read |= q_g_io_deq_bits_read;
        q_s0_io_deq_bits_read |= ~q_g_io_deq_bits_read;
        checks++;
        if (q_g_io_deq_bits_index !== q_i_io_deq_bits_index) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_index g=%h i=%h", cyc, q_g_io_deq_bits_index, q_i_io_deq_bits_index);
        end
        q_s1_io_deq_bits_index |= q_g_io_deq_bits_index;
        q_s0_io_deq_bits_index |= ~q_g_io_deq_bits_index;
        checks++;
        if (q_g_io_deq_bits_data !== q_i_io_deq_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_data g=%h i=%h", cyc, q_g_io_deq_bits_data, q_i_io_deq_bits_data);
        end
        q_s1_io_deq_bits_data |= q_g_io_deq_bits_data;
        q_s0_io_deq_bits_data |= ~q_g_io_deq_bits_data;
        checks++;
        if (q_g_io_deq_bits_mask !== q_i_io_deq_bits_mask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_mask g=%h i=%h", cyc, q_g_io_deq_bits_mask, q_i_io_deq_bits_mask);
        end
        q_s1_io_deq_bits_mask |= q_g_io_deq_bits_mask;
        q_s0_io_deq_bits_mask |= ~q_g_io_deq_bits_mask;
        checks++;
        if (q_g_io_deq_bits_extra_tlrr_extra_source !== q_i_io_deq_bits_extra_tlrr_extra_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source g=%h i=%h", cyc, q_g_io_deq_bits_extra_tlrr_extra_source, q_i_io_deq_bits_extra_tlrr_extra_source);
        end
        q_s1_io_deq_bits_extra_tlrr_extra_source |= q_g_io_deq_bits_extra_tlrr_extra_source;
        q_s0_io_deq_bits_extra_tlrr_extra_source |= ~q_g_io_deq_bits_extra_tlrr_extra_source;
        checks++;
        if (q_g_io_deq_bits_extra_tlrr_extra_size !== q_i_io_deq_bits_extra_tlrr_extra_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_size g=%h i=%h", cyc, q_g_io_deq_bits_extra_tlrr_extra_size, q_i_io_deq_bits_extra_tlrr_extra_size);
        end
        q_s1_io_deq_bits_extra_tlrr_extra_size |= q_g_io_deq_bits_extra_tlrr_extra_size;
        q_s0_io_deq_bits_extra_tlrr_extra_size |= ~q_g_io_deq_bits_extra_tlrr_extra_size;
        if (q_io_enq_valid && q_g_io_enq_ready) q_cov_enq++;
        if (q_g_io_deq_valid && q_io_deq_ready) q_cov_deq++;
        if (q_g_io_deq_valid && !q_io_deq_ready && q_io_enq_valid) q_cov_full_stall++;
        if (q_reset && cyc > 100) q_cov_reset_mid++;
      end
      if (q_io_enq_valid && q_g_io_enq_ready) q_armed[0] = 1'b1;
      if (q_armed_at < 0 && (&q_armed)) q_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(q_s0_io_enq_ready && q_s1_io_enq_ready)) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_enq_ready 未见过 0 和 1"); end
    if (!(q_s0_io_deq_valid && q_s1_io_deq_valid)) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_valid 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_read && q_s1_io_deq_bits_read)) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_read 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[0] && q_s1_io_deq_bits_index[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[1] && q_s1_io_deq_bits_index[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[2] && q_s1_io_deq_bits_index[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_index[3] && q_s1_io_deq_bits_index[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_index[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[0] && q_s1_io_deq_bits_data[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[1] && q_s1_io_deq_bits_data[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[2] && q_s1_io_deq_bits_data[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[3] && q_s1_io_deq_bits_data[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[4] && q_s1_io_deq_bits_data[4])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[4] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[5] && q_s1_io_deq_bits_data[5])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[5] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[6] && q_s1_io_deq_bits_data[6])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[6] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[7] && q_s1_io_deq_bits_data[7])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[7] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[8] && q_s1_io_deq_bits_data[8])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[8] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[9] && q_s1_io_deq_bits_data[9])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[9] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[10] && q_s1_io_deq_bits_data[10])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[10] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[11] && q_s1_io_deq_bits_data[11])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[11] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[12] && q_s1_io_deq_bits_data[12])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[12] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[13] && q_s1_io_deq_bits_data[13])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[13] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[14] && q_s1_io_deq_bits_data[14])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[14] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[15] && q_s1_io_deq_bits_data[15])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[15] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[16] && q_s1_io_deq_bits_data[16])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[16] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[17] && q_s1_io_deq_bits_data[17])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[17] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[18] && q_s1_io_deq_bits_data[18])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[18] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[19] && q_s1_io_deq_bits_data[19])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[19] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[20] && q_s1_io_deq_bits_data[20])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[20] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[21] && q_s1_io_deq_bits_data[21])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[21] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[22] && q_s1_io_deq_bits_data[22])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[22] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[23] && q_s1_io_deq_bits_data[23])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[23] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[24] && q_s1_io_deq_bits_data[24])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[24] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[25] && q_s1_io_deq_bits_data[25])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[25] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[26] && q_s1_io_deq_bits_data[26])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[26] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[27] && q_s1_io_deq_bits_data[27])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[27] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[28] && q_s1_io_deq_bits_data[28])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[28] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[29] && q_s1_io_deq_bits_data[29])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[29] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[30] && q_s1_io_deq_bits_data[30])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[30] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[31] && q_s1_io_deq_bits_data[31])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[31] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[32] && q_s1_io_deq_bits_data[32])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[32] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[33] && q_s1_io_deq_bits_data[33])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[33] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[34] && q_s1_io_deq_bits_data[34])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[34] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[35] && q_s1_io_deq_bits_data[35])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[35] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[36] && q_s1_io_deq_bits_data[36])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[36] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[37] && q_s1_io_deq_bits_data[37])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[37] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[38] && q_s1_io_deq_bits_data[38])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[38] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[39] && q_s1_io_deq_bits_data[39])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[39] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[40] && q_s1_io_deq_bits_data[40])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[40] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[41] && q_s1_io_deq_bits_data[41])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[41] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[42] && q_s1_io_deq_bits_data[42])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[42] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[43] && q_s1_io_deq_bits_data[43])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[43] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[44] && q_s1_io_deq_bits_data[44])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[44] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[45] && q_s1_io_deq_bits_data[45])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[45] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[46] && q_s1_io_deq_bits_data[46])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[46] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[47] && q_s1_io_deq_bits_data[47])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[47] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[48] && q_s1_io_deq_bits_data[48])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[48] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[49] && q_s1_io_deq_bits_data[49])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[49] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[50] && q_s1_io_deq_bits_data[50])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[50] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[51] && q_s1_io_deq_bits_data[51])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[51] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[52] && q_s1_io_deq_bits_data[52])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[52] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[53] && q_s1_io_deq_bits_data[53])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[53] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[54] && q_s1_io_deq_bits_data[54])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[54] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[55] && q_s1_io_deq_bits_data[55])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[55] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[56] && q_s1_io_deq_bits_data[56])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[56] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[57] && q_s1_io_deq_bits_data[57])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[57] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[58] && q_s1_io_deq_bits_data[58])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[58] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[59] && q_s1_io_deq_bits_data[59])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[59] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[60] && q_s1_io_deq_bits_data[60])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[60] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[61] && q_s1_io_deq_bits_data[61])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[61] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[62] && q_s1_io_deq_bits_data[62])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[62] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_data[63] && q_s1_io_deq_bits_data[63])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_data[63] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[0] && q_s1_io_deq_bits_mask[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[1] && q_s1_io_deq_bits_mask[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[2] && q_s1_io_deq_bits_mask[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[3] && q_s1_io_deq_bits_mask[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[4] && q_s1_io_deq_bits_mask[4])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[4] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[5] && q_s1_io_deq_bits_mask[5])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[5] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[6] && q_s1_io_deq_bits_mask[6])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[6] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_mask[7] && q_s1_io_deq_bits_mask[7])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_mask[7] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[0] && q_s1_io_deq_bits_extra_tlrr_extra_source[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[1] && q_s1_io_deq_bits_extra_tlrr_extra_source[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[1] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[2] && q_s1_io_deq_bits_extra_tlrr_extra_source[2])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[2] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_source[3] && q_s1_io_deq_bits_extra_tlrr_extra_source[3])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_source[3] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_size[0] && q_s1_io_deq_bits_extra_tlrr_extra_size[0])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_size[0] 未见过 0 和 1"); end
    if (!(q_s0_io_deq_bits_extra_tlrr_extra_size[1] && q_s1_io_deq_bits_extra_tlrr_extra_size[1])) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.io_deq_bits_extra_tlrr_extra_size[1] 未见过 0 和 1"); end
    $display("[ARM] Queue1_RegMapperInput_6 armed_at=%0d", q_armed_at);
    if (q_armed_at < 0) begin cov_fail++; $display("[ARM] Queue1_RegMapperInput_6 从未 arm"); end
    $display("[COV] Queue1_RegMapperInput_6.enq = %0d", q_cov_enq);
    if (q_cov_enq < 20) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.enq < 20"); end
    $display("[COV] Queue1_RegMapperInput_6.deq = %0d", q_cov_deq);
    if (q_cov_deq < 20) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.deq < 20"); end
    $display("[COV] Queue1_RegMapperInput_6.full_stall = %0d", q_cov_full_stall);
    if (q_cov_full_stall < 20) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.full_stall < 20"); end
    $display("[COV] Queue1_RegMapperInput_6.reset_mid = %0d", q_cov_reset_mid);
    if (q_cov_reset_mid < 20) begin cov_fail++; $display("[COV] Queue1_RegMapperInput_6.reset_mid < 20"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
