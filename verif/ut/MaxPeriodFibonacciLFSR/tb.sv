// 生成 MaxPeriodFibonacciLFSR 的双例化 UT testbench（tb.sv）。
//
// golden MaxPeriodFibonacciLFSR vs 重写 MaxPeriodFibonacciLFSR_xs（scripts/dual_tb_lib.py，端口表读 G1 golden）。
// 被测件只有 clock/reset 两个输入：激励就是复位 —— 上电 8 拍复位，之后每拍 1/5000 概率再打一拍
// 异步复位（复位值 seed=1 与反馈抽头都要被走到）。逐拍比全部 15 位输出；每个输出位都要见过 0 和 1。
// 覆盖：复位后第一拍（seed 态）、状态回到 seed（满周期 32767 拍才会自然发生一次，200k 拍内应有若干次）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= MaxPeriodFibonacciLFSR =================
  int unsigned l_mode = 0;
  logic l_reset;
  wire  l_g_io_out_0, l_i_io_out_0;
  logic l_s0_io_out_0 = '0, l_s1_io_out_0 = '0;
  wire  l_g_io_out_1, l_i_io_out_1;
  logic l_s0_io_out_1 = '0, l_s1_io_out_1 = '0;
  wire  l_g_io_out_2, l_i_io_out_2;
  logic l_s0_io_out_2 = '0, l_s1_io_out_2 = '0;
  wire  l_g_io_out_3, l_i_io_out_3;
  logic l_s0_io_out_3 = '0, l_s1_io_out_3 = '0;
  wire  l_g_io_out_4, l_i_io_out_4;
  logic l_s0_io_out_4 = '0, l_s1_io_out_4 = '0;
  wire  l_g_io_out_5, l_i_io_out_5;
  logic l_s0_io_out_5 = '0, l_s1_io_out_5 = '0;
  wire  l_g_io_out_6, l_i_io_out_6;
  logic l_s0_io_out_6 = '0, l_s1_io_out_6 = '0;
  wire  l_g_io_out_7, l_i_io_out_7;
  logic l_s0_io_out_7 = '0, l_s1_io_out_7 = '0;
  wire  l_g_io_out_8, l_i_io_out_8;
  logic l_s0_io_out_8 = '0, l_s1_io_out_8 = '0;
  wire  l_g_io_out_9, l_i_io_out_9;
  logic l_s0_io_out_9 = '0, l_s1_io_out_9 = '0;
  wire  l_g_io_out_10, l_i_io_out_10;
  logic l_s0_io_out_10 = '0, l_s1_io_out_10 = '0;
  wire  l_g_io_out_11, l_i_io_out_11;
  logic l_s0_io_out_11 = '0, l_s1_io_out_11 = '0;
  wire  l_g_io_out_12, l_i_io_out_12;
  logic l_s0_io_out_12 = '0, l_s1_io_out_12 = '0;
  wire  l_g_io_out_13, l_i_io_out_13;
  logic l_s0_io_out_13 = '0, l_s1_io_out_13 = '0;
  wire  l_g_io_out_14, l_i_io_out_14;
  logic l_s0_io_out_14 = '0, l_s1_io_out_14 = '0;
  int l_cov_reset_cycles = 0;
  int l_cov_at_seed_state = 0;
  logic [0:0] l_armed = '0;
  int l_armed_at = -1;
  MaxPeriodFibonacciLFSR l_u_gold (
    .clock(clk),
    .reset(l_reset),
    .io_out_0(l_g_io_out_0),
    .io_out_1(l_g_io_out_1),
    .io_out_2(l_g_io_out_2),
    .io_out_3(l_g_io_out_3),
    .io_out_4(l_g_io_out_4),
    .io_out_5(l_g_io_out_5),
    .io_out_6(l_g_io_out_6),
    .io_out_7(l_g_io_out_7),
    .io_out_8(l_g_io_out_8),
    .io_out_9(l_g_io_out_9),
    .io_out_10(l_g_io_out_10),
    .io_out_11(l_g_io_out_11),
    .io_out_12(l_g_io_out_12),
    .io_out_13(l_g_io_out_13),
    .io_out_14(l_g_io_out_14)
  );
  MaxPeriodFibonacciLFSR_xs l_u_impl (
    .clock(clk),
    .reset(l_reset),
    .io_out_0(l_i_io_out_0),
    .io_out_1(l_i_io_out_1),
    .io_out_2(l_i_io_out_2),
    .io_out_3(l_i_io_out_3),
    .io_out_4(l_i_io_out_4),
    .io_out_5(l_i_io_out_5),
    .io_out_6(l_i_io_out_6),
    .io_out_7(l_i_io_out_7),
    .io_out_8(l_i_io_out_8),
    .io_out_9(l_i_io_out_9),
    .io_out_10(l_i_io_out_10),
    .io_out_11(l_i_io_out_11),
    .io_out_12(l_i_io_out_12),
    .io_out_13(l_i_io_out_13),
    .io_out_14(l_i_io_out_14)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) l_mode = $urandom_range(0, 15);
      l_reset = (cyc < RESET_CYC) || ($urandom_range(0, 4999) == 0);
      #4;
      l_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&l_armed)) begin
        checks++;
        if (l_g_io_out_0 !== l_i_io_out_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_0 g=%h i=%h", cyc, l_g_io_out_0, l_i_io_out_0);
        end
        l_s1_io_out_0 |= l_g_io_out_0;
        l_s0_io_out_0 |= ~l_g_io_out_0;
        checks++;
        if (l_g_io_out_1 !== l_i_io_out_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_1 g=%h i=%h", cyc, l_g_io_out_1, l_i_io_out_1);
        end
        l_s1_io_out_1 |= l_g_io_out_1;
        l_s0_io_out_1 |= ~l_g_io_out_1;
        checks++;
        if (l_g_io_out_2 !== l_i_io_out_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_2 g=%h i=%h", cyc, l_g_io_out_2, l_i_io_out_2);
        end
        l_s1_io_out_2 |= l_g_io_out_2;
        l_s0_io_out_2 |= ~l_g_io_out_2;
        checks++;
        if (l_g_io_out_3 !== l_i_io_out_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_3 g=%h i=%h", cyc, l_g_io_out_3, l_i_io_out_3);
        end
        l_s1_io_out_3 |= l_g_io_out_3;
        l_s0_io_out_3 |= ~l_g_io_out_3;
        checks++;
        if (l_g_io_out_4 !== l_i_io_out_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_4 g=%h i=%h", cyc, l_g_io_out_4, l_i_io_out_4);
        end
        l_s1_io_out_4 |= l_g_io_out_4;
        l_s0_io_out_4 |= ~l_g_io_out_4;
        checks++;
        if (l_g_io_out_5 !== l_i_io_out_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_5 g=%h i=%h", cyc, l_g_io_out_5, l_i_io_out_5);
        end
        l_s1_io_out_5 |= l_g_io_out_5;
        l_s0_io_out_5 |= ~l_g_io_out_5;
        checks++;
        if (l_g_io_out_6 !== l_i_io_out_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_6 g=%h i=%h", cyc, l_g_io_out_6, l_i_io_out_6);
        end
        l_s1_io_out_6 |= l_g_io_out_6;
        l_s0_io_out_6 |= ~l_g_io_out_6;
        checks++;
        if (l_g_io_out_7 !== l_i_io_out_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_7 g=%h i=%h", cyc, l_g_io_out_7, l_i_io_out_7);
        end
        l_s1_io_out_7 |= l_g_io_out_7;
        l_s0_io_out_7 |= ~l_g_io_out_7;
        checks++;
        if (l_g_io_out_8 !== l_i_io_out_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_8 g=%h i=%h", cyc, l_g_io_out_8, l_i_io_out_8);
        end
        l_s1_io_out_8 |= l_g_io_out_8;
        l_s0_io_out_8 |= ~l_g_io_out_8;
        checks++;
        if (l_g_io_out_9 !== l_i_io_out_9) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_9 g=%h i=%h", cyc, l_g_io_out_9, l_i_io_out_9);
        end
        l_s1_io_out_9 |= l_g_io_out_9;
        l_s0_io_out_9 |= ~l_g_io_out_9;
        checks++;
        if (l_g_io_out_10 !== l_i_io_out_10) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_10 g=%h i=%h", cyc, l_g_io_out_10, l_i_io_out_10);
        end
        l_s1_io_out_10 |= l_g_io_out_10;
        l_s0_io_out_10 |= ~l_g_io_out_10;
        checks++;
        if (l_g_io_out_11 !== l_i_io_out_11) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_11 g=%h i=%h", cyc, l_g_io_out_11, l_i_io_out_11);
        end
        l_s1_io_out_11 |= l_g_io_out_11;
        l_s0_io_out_11 |= ~l_g_io_out_11;
        checks++;
        if (l_g_io_out_12 !== l_i_io_out_12) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_12 g=%h i=%h", cyc, l_g_io_out_12, l_i_io_out_12);
        end
        l_s1_io_out_12 |= l_g_io_out_12;
        l_s0_io_out_12 |= ~l_g_io_out_12;
        checks++;
        if (l_g_io_out_13 !== l_i_io_out_13) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_13 g=%h i=%h", cyc, l_g_io_out_13, l_i_io_out_13);
        end
        l_s1_io_out_13 |= l_g_io_out_13;
        l_s0_io_out_13 |= ~l_g_io_out_13;
        checks++;
        if (l_g_io_out_14 !== l_i_io_out_14) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MaxPeriodFibonacciLFSR.io_out_14 g=%h i=%h", cyc, l_g_io_out_14, l_i_io_out_14);
        end
        l_s1_io_out_14 |= l_g_io_out_14;
        l_s0_io_out_14 |= ~l_g_io_out_14;
        if (l_reset) l_cov_reset_cycles++;
        if (({l_g_io_out_14,l_g_io_out_13,l_g_io_out_12,l_g_io_out_11,l_g_io_out_10,l_g_io_out_9,l_g_io_out_8,l_g_io_out_7,l_g_io_out_6,l_g_io_out_5,l_g_io_out_4,l_g_io_out_3,l_g_io_out_2,l_g_io_out_1,l_g_io_out_0} == 15'd1) && !l_reset) l_cov_at_seed_state++;
      end
      if (l_armed_at < 0 && (&l_armed)) l_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(l_s0_io_out_0 && l_s1_io_out_0)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_0 未见过 0 和 1"); end
    if (!(l_s0_io_out_1 && l_s1_io_out_1)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_1 未见过 0 和 1"); end
    if (!(l_s0_io_out_2 && l_s1_io_out_2)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_2 未见过 0 和 1"); end
    if (!(l_s0_io_out_3 && l_s1_io_out_3)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_3 未见过 0 和 1"); end
    if (!(l_s0_io_out_4 && l_s1_io_out_4)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_4 未见过 0 和 1"); end
    if (!(l_s0_io_out_5 && l_s1_io_out_5)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_5 未见过 0 和 1"); end
    if (!(l_s0_io_out_6 && l_s1_io_out_6)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_6 未见过 0 和 1"); end
    if (!(l_s0_io_out_7 && l_s1_io_out_7)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_7 未见过 0 和 1"); end
    if (!(l_s0_io_out_8 && l_s1_io_out_8)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_8 未见过 0 和 1"); end
    if (!(l_s0_io_out_9 && l_s1_io_out_9)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_9 未见过 0 和 1"); end
    if (!(l_s0_io_out_10 && l_s1_io_out_10)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_10 未见过 0 和 1"); end
    if (!(l_s0_io_out_11 && l_s1_io_out_11)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_11 未见过 0 和 1"); end
    if (!(l_s0_io_out_12 && l_s1_io_out_12)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_12 未见过 0 和 1"); end
    if (!(l_s0_io_out_13 && l_s1_io_out_13)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_13 未见过 0 和 1"); end
    if (!(l_s0_io_out_14 && l_s1_io_out_14)) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.io_out_14 未见过 0 和 1"); end
    $display("[ARM] MaxPeriodFibonacciLFSR armed_at=%0d", l_armed_at);
    if (l_armed_at < 0) begin cov_fail++; $display("[ARM] MaxPeriodFibonacciLFSR 从未 arm"); end
    $display("[COV] MaxPeriodFibonacciLFSR.reset_cycles = %0d", l_cov_reset_cycles);
    if (l_cov_reset_cycles < 3) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.reset_cycles < 3"); end
    $display("[COV] MaxPeriodFibonacciLFSR.at_seed_state = %0d", l_cov_at_seed_state);
    if (l_cov_at_seed_state < 3) begin cov_fail++; $display("[COV] MaxPeriodFibonacciLFSR.at_seed_state < 3"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
