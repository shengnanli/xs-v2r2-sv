// tb —— AsyncResetSyncShiftReg_w1_d3_i0：1 位 3 级异步复位同步器（装配壳）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= AsyncResetSynchronizerShiftReg_w1_d3_i0 =================
  int unsigned ar_mode = 0;
  logic ar_reset;
  logic ar_io_d;
  wire  ar_g_io_q, ar_i_io_q;
  logic ar_s0_io_q = '0, ar_s1_io_q = '0;
  int ar_cov_q1 = 0;
  int ar_cov_in_reset = 0;
  int ar_cov_d_rise = 0;
  logic [0:0] ar_armed = '0;
  int ar_armed_at = -1;
  AsyncResetSynchronizerShiftReg_w1_d3_i0 ar_u_gold (
    .clock(clk),
    .reset(ar_reset),
    .io_d(ar_io_d),
    .io_q(ar_g_io_q)
  );
  AsyncResetSynchronizerShiftReg_w1_d3_i0_xs ar_u_impl (
    .clock(clk),
    .reset(ar_reset),
    .io_d(ar_io_d),
    .io_q(ar_i_io_q)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) ar_mode = $urandom_range(0, 15);
      ar_io_d = 1'($urandom);
      ar_reset = (cyc < RESET_CYC) || ($urandom_range(0, 49) == 0);
      #4;
      ar_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&ar_armed)) begin
        checks++;
        if (ar_g_io_q !== ar_i_io_q) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d AsyncResetSynchronizerShiftReg_w1_d3_i0.io_q g=%h i=%h", cyc, ar_g_io_q, ar_i_io_q);
        end
        ar_s1_io_q |= ar_g_io_q;
        ar_s0_io_q |= ~ar_g_io_q;
        if (ar_g_io_q) ar_cov_q1++;
        if (ar_reset) ar_cov_in_reset++;
        if (ar_io_d && !ar_g_io_q) ar_cov_d_rise++;
      end
      if (ar_armed_at < 0 && (&ar_armed)) ar_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(ar_s0_io_q && ar_s1_io_q)) begin cov_fail++; $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.io_q 未见过 0 和 1"); end
    $display("[ARM] AsyncResetSynchronizerShiftReg_w1_d3_i0 armed_at=%0d", ar_armed_at);
    if (ar_armed_at < 0) begin cov_fail++; $display("[ARM] AsyncResetSynchronizerShiftReg_w1_d3_i0 从未 arm"); end
    $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.q1 = %0d", ar_cov_q1);
    if (ar_cov_q1 < 100) begin cov_fail++; $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.q1 < 100"); end
    $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.in_reset = %0d", ar_cov_in_reset);
    if (ar_cov_in_reset < 100) begin cov_fail++; $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.in_reset < 100"); end
    $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.d_rise = %0d", ar_cov_d_rise);
    if (ar_cov_d_rise < 100) begin cov_fail++; $display("[COV] AsyncResetSynchronizerShiftReg_w1_d3_i0.d_rise < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
