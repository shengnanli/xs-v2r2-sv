// 自动生成：verif/ut/FrontendTrigger/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// FrontendTrigger 双例化逐拍比对：golden FrontendTrigger vs 重写 FrontendTrigger_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= FrontendTrigger =================
  int unsigned ft_mode = 0;
  logic [49:0] ft_base = '0;
  logic [49:0] ft_pc0;
  int unsigned ft_span;
  logic ft_reset;
  logic ft_io_frontendTrigger_tUpdate_valid;
  logic [1:0] ft_io_frontendTrigger_tUpdate_bits_addr;
  logic [1:0] ft_io_frontendTrigger_tUpdate_bits_tdata_matchType;
  logic ft_io_frontendTrigger_tUpdate_bits_tdata_select;
  logic [3:0] ft_io_frontendTrigger_tUpdate_bits_tdata_action;
  logic ft_io_frontendTrigger_tUpdate_bits_tdata_chain;
  logic [63:0] ft_io_frontendTrigger_tUpdate_bits_tdata_tdata2;
  logic ft_io_frontendTrigger_tEnableVec_0;
  logic ft_io_frontendTrigger_tEnableVec_1;
  logic ft_io_frontendTrigger_tEnableVec_2;
  logic ft_io_frontendTrigger_tEnableVec_3;
  logic ft_io_frontendTrigger_debugMode;
  logic ft_io_frontendTrigger_triggerCanRaiseBpExp;
  wire  [3:0] ft_g_io_triggered_0, ft_i_io_triggered_0;
  logic [3:0] ft_s0_io_triggered_0 = '0, ft_s1_io_triggered_0 = '0;
  wire  [3:0] ft_g_io_triggered_1, ft_i_io_triggered_1;
  logic [3:0] ft_s0_io_triggered_1 = '0, ft_s1_io_triggered_1 = '0;
  wire  [3:0] ft_g_io_triggered_2, ft_i_io_triggered_2;
  logic [3:0] ft_s0_io_triggered_2 = '0, ft_s1_io_triggered_2 = '0;
  wire  [3:0] ft_g_io_triggered_3, ft_i_io_triggered_3;
  logic [3:0] ft_s0_io_triggered_3 = '0, ft_s1_io_triggered_3 = '0;
  wire  [3:0] ft_g_io_triggered_4, ft_i_io_triggered_4;
  logic [3:0] ft_s0_io_triggered_4 = '0, ft_s1_io_triggered_4 = '0;
  wire  [3:0] ft_g_io_triggered_5, ft_i_io_triggered_5;
  logic [3:0] ft_s0_io_triggered_5 = '0, ft_s1_io_triggered_5 = '0;
  wire  [3:0] ft_g_io_triggered_6, ft_i_io_triggered_6;
  logic [3:0] ft_s0_io_triggered_6 = '0, ft_s1_io_triggered_6 = '0;
  wire  [3:0] ft_g_io_triggered_7, ft_i_io_triggered_7;
  logic [3:0] ft_s0_io_triggered_7 = '0, ft_s1_io_triggered_7 = '0;
  wire  [3:0] ft_g_io_triggered_8, ft_i_io_triggered_8;
  logic [3:0] ft_s0_io_triggered_8 = '0, ft_s1_io_triggered_8 = '0;
  wire  [3:0] ft_g_io_triggered_9, ft_i_io_triggered_9;
  logic [3:0] ft_s0_io_triggered_9 = '0, ft_s1_io_triggered_9 = '0;
  wire  [3:0] ft_g_io_triggered_10, ft_i_io_triggered_10;
  logic [3:0] ft_s0_io_triggered_10 = '0, ft_s1_io_triggered_10 = '0;
  wire  [3:0] ft_g_io_triggered_11, ft_i_io_triggered_11;
  logic [3:0] ft_s0_io_triggered_11 = '0, ft_s1_io_triggered_11 = '0;
  wire  [3:0] ft_g_io_triggered_12, ft_i_io_triggered_12;
  logic [3:0] ft_s0_io_triggered_12 = '0, ft_s1_io_triggered_12 = '0;
  wire  [3:0] ft_g_io_triggered_13, ft_i_io_triggered_13;
  logic [3:0] ft_s0_io_triggered_13 = '0, ft_s1_io_triggered_13 = '0;
  wire  [3:0] ft_g_io_triggered_14, ft_i_io_triggered_14;
  logic [3:0] ft_s0_io_triggered_14 = '0, ft_s1_io_triggered_14 = '0;
  wire  [3:0] ft_g_io_triggered_15, ft_i_io_triggered_15;
  logic [3:0] ft_s0_io_triggered_15 = '0, ft_s1_io_triggered_15 = '0;
  logic [49:0] ft_io_pc_0;
  logic [49:0] ft_io_pc_1;
  logic [49:0] ft_io_pc_2;
  logic [49:0] ft_io_pc_3;
  logic [49:0] ft_io_pc_4;
  logic [49:0] ft_io_pc_5;
  logic [49:0] ft_io_pc_6;
  logic [49:0] ft_io_pc_7;
  logic [49:0] ft_io_pc_8;
  logic [49:0] ft_io_pc_9;
  logic [49:0] ft_io_pc_10;
  logic [49:0] ft_io_pc_11;
  logic [49:0] ft_io_pc_12;
  logic [49:0] ft_io_pc_13;
  logic [49:0] ft_io_pc_14;
  logic [49:0] ft_io_pc_15;
  int ft_cov_act_debug = 0;
  int ft_cov_act_bkpt = 0;
  int ft_cov_act_none = 0;
  int ft_cov_bkpt_blocked = 0;
  int ft_cov_hit_eq = 0;
  int ft_cov_hit_ge = 0;
  int ft_cov_hit_lt = 0;
  int ft_cov_napot_nohit = 0;
  int ft_cov_carry_hit = 0;
  int ft_cov_carry_eq = 0;
  int ft_cov_chain_fire = 0;
  int ft_cov_chain_block = 0;
  int ft_cov_chain_mid = 0;
  int ft_cov_select_block = 0;
  int ft_cov_debug_block = 0;
  int ft_cov_update = 0;
  logic [0:0] ft_armed = '0;
  int ft_armed_at = -1;
  FrontendTrigger ft_u_gold (
    .clock(clk),
    .reset(ft_reset),
    .io_frontendTrigger_tUpdate_valid(ft_io_frontendTrigger_tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr(ft_io_frontendTrigger_tUpdate_bits_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType(ft_io_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select(ft_io_frontendTrigger_tUpdate_bits_tdata_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action(ft_io_frontendTrigger_tUpdate_bits_tdata_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain(ft_io_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2(ft_io_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_frontendTrigger_tEnableVec_0(ft_io_frontendTrigger_tEnableVec_0),
    .io_frontendTrigger_tEnableVec_1(ft_io_frontendTrigger_tEnableVec_1),
    .io_frontendTrigger_tEnableVec_2(ft_io_frontendTrigger_tEnableVec_2),
    .io_frontendTrigger_tEnableVec_3(ft_io_frontendTrigger_tEnableVec_3),
    .io_frontendTrigger_debugMode(ft_io_frontendTrigger_debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp(ft_io_frontendTrigger_triggerCanRaiseBpExp),
    .io_triggered_0(ft_g_io_triggered_0),
    .io_triggered_1(ft_g_io_triggered_1),
    .io_triggered_2(ft_g_io_triggered_2),
    .io_triggered_3(ft_g_io_triggered_3),
    .io_triggered_4(ft_g_io_triggered_4),
    .io_triggered_5(ft_g_io_triggered_5),
    .io_triggered_6(ft_g_io_triggered_6),
    .io_triggered_7(ft_g_io_triggered_7),
    .io_triggered_8(ft_g_io_triggered_8),
    .io_triggered_9(ft_g_io_triggered_9),
    .io_triggered_10(ft_g_io_triggered_10),
    .io_triggered_11(ft_g_io_triggered_11),
    .io_triggered_12(ft_g_io_triggered_12),
    .io_triggered_13(ft_g_io_triggered_13),
    .io_triggered_14(ft_g_io_triggered_14),
    .io_triggered_15(ft_g_io_triggered_15),
    .io_pc_0(ft_io_pc_0),
    .io_pc_1(ft_io_pc_1),
    .io_pc_2(ft_io_pc_2),
    .io_pc_3(ft_io_pc_3),
    .io_pc_4(ft_io_pc_4),
    .io_pc_5(ft_io_pc_5),
    .io_pc_6(ft_io_pc_6),
    .io_pc_7(ft_io_pc_7),
    .io_pc_8(ft_io_pc_8),
    .io_pc_9(ft_io_pc_9),
    .io_pc_10(ft_io_pc_10),
    .io_pc_11(ft_io_pc_11),
    .io_pc_12(ft_io_pc_12),
    .io_pc_13(ft_io_pc_13),
    .io_pc_14(ft_io_pc_14),
    .io_pc_15(ft_io_pc_15)
  );
  FrontendTrigger_xs ft_u_impl (
    .clock(clk),
    .reset(ft_reset),
    .io_frontendTrigger_tUpdate_valid(ft_io_frontendTrigger_tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr(ft_io_frontendTrigger_tUpdate_bits_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType(ft_io_frontendTrigger_tUpdate_bits_tdata_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select(ft_io_frontendTrigger_tUpdate_bits_tdata_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action(ft_io_frontendTrigger_tUpdate_bits_tdata_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain(ft_io_frontendTrigger_tUpdate_bits_tdata_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2(ft_io_frontendTrigger_tUpdate_bits_tdata_tdata2),
    .io_frontendTrigger_tEnableVec_0(ft_io_frontendTrigger_tEnableVec_0),
    .io_frontendTrigger_tEnableVec_1(ft_io_frontendTrigger_tEnableVec_1),
    .io_frontendTrigger_tEnableVec_2(ft_io_frontendTrigger_tEnableVec_2),
    .io_frontendTrigger_tEnableVec_3(ft_io_frontendTrigger_tEnableVec_3),
    .io_frontendTrigger_debugMode(ft_io_frontendTrigger_debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp(ft_io_frontendTrigger_triggerCanRaiseBpExp),
    .io_triggered_0(ft_i_io_triggered_0),
    .io_triggered_1(ft_i_io_triggered_1),
    .io_triggered_2(ft_i_io_triggered_2),
    .io_triggered_3(ft_i_io_triggered_3),
    .io_triggered_4(ft_i_io_triggered_4),
    .io_triggered_5(ft_i_io_triggered_5),
    .io_triggered_6(ft_i_io_triggered_6),
    .io_triggered_7(ft_i_io_triggered_7),
    .io_triggered_8(ft_i_io_triggered_8),
    .io_triggered_9(ft_i_io_triggered_9),
    .io_triggered_10(ft_i_io_triggered_10),
    .io_triggered_11(ft_i_io_triggered_11),
    .io_triggered_12(ft_i_io_triggered_12),
    .io_triggered_13(ft_i_io_triggered_13),
    .io_triggered_14(ft_i_io_triggered_14),
    .io_triggered_15(ft_i_io_triggered_15),
    .io_pc_0(ft_io_pc_0),
    .io_pc_1(ft_io_pc_1),
    .io_pc_2(ft_io_pc_2),
    .io_pc_3(ft_io_pc_3),
    .io_pc_4(ft_io_pc_4),
    .io_pc_5(ft_io_pc_5),
    .io_pc_6(ft_io_pc_6),
    .io_pc_7(ft_io_pc_7),
    .io_pc_8(ft_io_pc_8),
    .io_pc_9(ft_io_pc_9),
    .io_pc_10(ft_io_pc_10),
    .io_pc_11(ft_io_pc_11),
    .io_pc_12(ft_io_pc_12),
    .io_pc_13(ft_io_pc_13),
    .io_pc_14(ft_io_pc_14),
    .io_pc_15(ft_io_pc_15)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 500 == 0) ft_mode = $urandom_range(0, 15);
      ft_io_frontendTrigger_tUpdate_valid = 1'($urandom);
      ft_io_frontendTrigger_tUpdate_bits_addr = 2'($urandom);
      ft_io_frontendTrigger_tUpdate_bits_tdata_matchType = 2'($urandom);
      ft_io_frontendTrigger_tUpdate_bits_tdata_select = 1'($urandom);
      ft_io_frontendTrigger_tUpdate_bits_tdata_action = 4'($urandom);
      ft_io_frontendTrigger_tUpdate_bits_tdata_chain = 1'($urandom);
      ft_io_frontendTrigger_tUpdate_bits_tdata_tdata2 = 64'({$urandom, $urandom});
      ft_io_frontendTrigger_tEnableVec_0 = 1'($urandom);
      ft_io_frontendTrigger_tEnableVec_1 = 1'($urandom);
      ft_io_frontendTrigger_tEnableVec_2 = 1'($urandom);
      ft_io_frontendTrigger_tEnableVec_3 = 1'($urandom);
      ft_io_frontendTrigger_debugMode = 1'($urandom);
      ft_io_frontendTrigger_triggerCanRaiseBpExp = 1'($urandom);
      ft_io_pc_0 = 50'({$urandom, $urandom});
      ft_io_pc_1 = 50'({$urandom, $urandom});
      ft_io_pc_2 = 50'({$urandom, $urandom});
      ft_io_pc_3 = 50'({$urandom, $urandom});
      ft_io_pc_4 = 50'({$urandom, $urandom});
      ft_io_pc_5 = 50'({$urandom, $urandom});
      ft_io_pc_6 = 50'({$urandom, $urandom});
      ft_io_pc_7 = 50'({$urandom, $urandom});
      ft_io_pc_8 = 50'({$urandom, $urandom});
      ft_io_pc_9 = 50'({$urandom, $urandom});
      ft_io_pc_10 = 50'({$urandom, $urandom});
      ft_io_pc_11 = 50'({$urandom, $urandom});
      ft_io_pc_12 = 50'({$urandom, $urandom});
      ft_io_pc_13 = 50'({$urandom, $urandom});
      ft_io_pc_14 = 50'({$urandom, $urandom});
      ft_io_pc_15 = 50'({$urandom, $urandom});
      ft_reset = (cyc < RESET_CYC) || ($urandom_range(0, 29999) == 0);
      begin : stim_ft
        if (cyc % 200 == 0) ft_base = 50'({$urandom, $urandom});
        ft_span = (ft_mode % 2) ? 12 : 64;
        ft_pc0 = ft_base + 50'($urandom_range(0, 2 * ft_span)) - 50'(ft_span);
        if ($urandom_range(0, 15) != 0) begin
          ft_io_pc_0 = ft_pc0 + 50'd0;
          ft_io_pc_1 = ft_pc0 + 50'd2;
          ft_io_pc_2 = ft_pc0 + 50'd4;
          ft_io_pc_3 = ft_pc0 + 50'd6;
          ft_io_pc_4 = ft_pc0 + 50'd8;
          ft_io_pc_5 = ft_pc0 + 50'd10;
          ft_io_pc_6 = ft_pc0 + 50'd12;
          ft_io_pc_7 = ft_pc0 + 50'd14;
          ft_io_pc_8 = ft_pc0 + 50'd16;
          ft_io_pc_9 = ft_pc0 + 50'd18;
          ft_io_pc_10 = ft_pc0 + 50'd20;
          ft_io_pc_11 = ft_pc0 + 50'd22;
          ft_io_pc_12 = ft_pc0 + 50'd24;
          ft_io_pc_13 = ft_pc0 + 50'd26;
          ft_io_pc_14 = ft_pc0 + 50'd28;
          ft_io_pc_15 = ft_pc0 + 50'd30;
        end
        ft_io_frontendTrigger_tUpdate_valid = ($urandom_range(0, 7) == 0);
        ft_io_frontendTrigger_tUpdate_bits_tdata_tdata2 = {14'($urandom), ft_base + 50'($urandom_range(0, 2 * ft_span)) - 50'(ft_span)};
        ft_io_frontendTrigger_tUpdate_bits_tdata_chain = ($urandom_range(0, 3) == 0);
        ft_io_frontendTrigger_tUpdate_bits_tdata_select = ($urandom_range(0, 7) == 0);
        ft_io_frontendTrigger_tUpdate_bits_tdata_action = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1));
        if (ft_mode % 4 == 1) ft_io_frontendTrigger_tUpdate_bits_tdata_matchType = 2'd0;
        ft_io_frontendTrigger_debugMode = ($urandom_range(0, 15) == 0);
        if (ft_mode % 4 != 0) begin
          ft_io_frontendTrigger_tEnableVec_0 = 1'b1; ft_io_frontendTrigger_tEnableVec_1 = 1'b1;
          ft_io_frontendTrigger_tEnableVec_2 = 1'b1; ft_io_frontendTrigger_tEnableVec_3 = 1'b1;
        end
      end
      #4;
      ft_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&ft_armed)) begin
        checks++;
        if (ft_g_io_triggered_0 !== ft_i_io_triggered_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_0 g=%h i=%h", cyc, ft_g_io_triggered_0, ft_i_io_triggered_0);
        end
        ft_s1_io_triggered_0 |= ft_g_io_triggered_0;
        ft_s0_io_triggered_0 |= ~ft_g_io_triggered_0;
        checks++;
        if (ft_g_io_triggered_1 !== ft_i_io_triggered_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_1 g=%h i=%h", cyc, ft_g_io_triggered_1, ft_i_io_triggered_1);
        end
        ft_s1_io_triggered_1 |= ft_g_io_triggered_1;
        ft_s0_io_triggered_1 |= ~ft_g_io_triggered_1;
        checks++;
        if (ft_g_io_triggered_2 !== ft_i_io_triggered_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_2 g=%h i=%h", cyc, ft_g_io_triggered_2, ft_i_io_triggered_2);
        end
        ft_s1_io_triggered_2 |= ft_g_io_triggered_2;
        ft_s0_io_triggered_2 |= ~ft_g_io_triggered_2;
        checks++;
        if (ft_g_io_triggered_3 !== ft_i_io_triggered_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_3 g=%h i=%h", cyc, ft_g_io_triggered_3, ft_i_io_triggered_3);
        end
        ft_s1_io_triggered_3 |= ft_g_io_triggered_3;
        ft_s0_io_triggered_3 |= ~ft_g_io_triggered_3;
        checks++;
        if (ft_g_io_triggered_4 !== ft_i_io_triggered_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_4 g=%h i=%h", cyc, ft_g_io_triggered_4, ft_i_io_triggered_4);
        end
        ft_s1_io_triggered_4 |= ft_g_io_triggered_4;
        ft_s0_io_triggered_4 |= ~ft_g_io_triggered_4;
        checks++;
        if (ft_g_io_triggered_5 !== ft_i_io_triggered_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_5 g=%h i=%h", cyc, ft_g_io_triggered_5, ft_i_io_triggered_5);
        end
        ft_s1_io_triggered_5 |= ft_g_io_triggered_5;
        ft_s0_io_triggered_5 |= ~ft_g_io_triggered_5;
        checks++;
        if (ft_g_io_triggered_6 !== ft_i_io_triggered_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_6 g=%h i=%h", cyc, ft_g_io_triggered_6, ft_i_io_triggered_6);
        end
        ft_s1_io_triggered_6 |= ft_g_io_triggered_6;
        ft_s0_io_triggered_6 |= ~ft_g_io_triggered_6;
        checks++;
        if (ft_g_io_triggered_7 !== ft_i_io_triggered_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_7 g=%h i=%h", cyc, ft_g_io_triggered_7, ft_i_io_triggered_7);
        end
        ft_s1_io_triggered_7 |= ft_g_io_triggered_7;
        ft_s0_io_triggered_7 |= ~ft_g_io_triggered_7;
        checks++;
        if (ft_g_io_triggered_8 !== ft_i_io_triggered_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_8 g=%h i=%h", cyc, ft_g_io_triggered_8, ft_i_io_triggered_8);
        end
        ft_s1_io_triggered_8 |= ft_g_io_triggered_8;
        ft_s0_io_triggered_8 |= ~ft_g_io_triggered_8;
        checks++;
        if (ft_g_io_triggered_9 !== ft_i_io_triggered_9) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_9 g=%h i=%h", cyc, ft_g_io_triggered_9, ft_i_io_triggered_9);
        end
        ft_s1_io_triggered_9 |= ft_g_io_triggered_9;
        ft_s0_io_triggered_9 |= ~ft_g_io_triggered_9;
        checks++;
        if (ft_g_io_triggered_10 !== ft_i_io_triggered_10) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_10 g=%h i=%h", cyc, ft_g_io_triggered_10, ft_i_io_triggered_10);
        end
        ft_s1_io_triggered_10 |= ft_g_io_triggered_10;
        ft_s0_io_triggered_10 |= ~ft_g_io_triggered_10;
        checks++;
        if (ft_g_io_triggered_11 !== ft_i_io_triggered_11) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_11 g=%h i=%h", cyc, ft_g_io_triggered_11, ft_i_io_triggered_11);
        end
        ft_s1_io_triggered_11 |= ft_g_io_triggered_11;
        ft_s0_io_triggered_11 |= ~ft_g_io_triggered_11;
        checks++;
        if (ft_g_io_triggered_12 !== ft_i_io_triggered_12) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_12 g=%h i=%h", cyc, ft_g_io_triggered_12, ft_i_io_triggered_12);
        end
        ft_s1_io_triggered_12 |= ft_g_io_triggered_12;
        ft_s0_io_triggered_12 |= ~ft_g_io_triggered_12;
        checks++;
        if (ft_g_io_triggered_13 !== ft_i_io_triggered_13) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_13 g=%h i=%h", cyc, ft_g_io_triggered_13, ft_i_io_triggered_13);
        end
        ft_s1_io_triggered_13 |= ft_g_io_triggered_13;
        ft_s0_io_triggered_13 |= ~ft_g_io_triggered_13;
        checks++;
        if (ft_g_io_triggered_14 !== ft_i_io_triggered_14) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_14 g=%h i=%h", cyc, ft_g_io_triggered_14, ft_i_io_triggered_14);
        end
        ft_s1_io_triggered_14 |= ft_g_io_triggered_14;
        ft_s0_io_triggered_14 |= ~ft_g_io_triggered_14;
        checks++;
        if (ft_g_io_triggered_15 !== ft_i_io_triggered_15) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FrontendTrigger.io_triggered_15 g=%h i=%h", cyc, ft_g_io_triggered_15, ft_i_io_triggered_15);
        end
        ft_s1_io_triggered_15 |= ft_g_io_triggered_15;
        ft_s0_io_triggered_15 |= ~ft_g_io_triggered_15;
        if (ft_g_io_triggered_5 == 4'h1) ft_cov_act_debug++;
        if (ft_g_io_triggered_5 == 4'h0) ft_cov_act_bkpt++;
        if (ft_g_io_triggered_5 == 4'hF) ft_cov_act_none++;
        if ((ft_u_gold.triggerCanFireVec_5_0 && ft_u_gold.tdataVec_0_action == 4'h0) && !ft_io_frontendTrigger_triggerCanRaiseBpExp) ft_cov_bkpt_blocked++;
        if (ft_u_gold.triggerHitVec_9_1 && ft_u_gold.tdataVec_1_matchType == 2'h0) ft_cov_hit_eq++;
        if (ft_u_gold.triggerHitVec_9_1 && ft_u_gold.tdataVec_1_matchType == 2'h2) ft_cov_hit_ge++;
        if (ft_u_gold.triggerHitVec_9_1 && ft_u_gold.tdataVec_1_matchType == 2'h3) ft_cov_hit_lt++;
        if (ft_u_gold.tdataVec_1_matchType == 2'h1 && ft_u_gold.triggerEnableVec_1) ft_cov_napot_nohit++;
        if (ft_u_gold.triggerHitVec_6_2 && (ft_io_pc_6[5] != ft_io_pc_0[5])) ft_cov_carry_hit++;
        if (ft_u_gold.triggerHitVec_6_2 && (ft_io_pc_6[5] != ft_io_pc_0[5]) && ft_u_gold.tdataVec_2_matchType == 2'h0) ft_cov_carry_eq++;
        if (ft_u_gold.triggerCanFireVec_5_2 && ft_u_gold.tdataVec_1_chain) ft_cov_chain_fire++;
        if (ft_u_gold.triggerHitVec_5_2 && ft_u_gold.tdataVec_1_chain && !ft_u_gold.triggerHitVec_5_1 && !ft_u_gold.tdataVec_2_chain) ft_cov_chain_block++;
        if (ft_u_gold.triggerHitVec_5_1 && ft_u_gold.tdataVec_1_chain) ft_cov_chain_mid++;
        if (ft_u_gold.tdataVec_0_select && ft_u_gold.triggerEnableVec_0) ft_cov_select_block++;
        if (ft_io_frontendTrigger_debugMode && ft_u_gold.triggerEnableVec_0) ft_cov_debug_block++;
        if (ft_io_frontendTrigger_tUpdate_valid) ft_cov_update++;
      end
      if (ft_armed_at < 0 && (&ft_armed)) ft_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(ft_s0_io_triggered_0[0] && ft_s1_io_triggered_0[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_0[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_0[1] && ft_s1_io_triggered_0[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_0[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_0[2] && ft_s1_io_triggered_0[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_0[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_0[3] && ft_s1_io_triggered_0[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_0[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_1[0] && ft_s1_io_triggered_1[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_1[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_1[1] && ft_s1_io_triggered_1[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_1[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_1[2] && ft_s1_io_triggered_1[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_1[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_1[3] && ft_s1_io_triggered_1[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_1[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_2[0] && ft_s1_io_triggered_2[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_2[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_2[1] && ft_s1_io_triggered_2[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_2[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_2[2] && ft_s1_io_triggered_2[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_2[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_2[3] && ft_s1_io_triggered_2[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_2[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_3[0] && ft_s1_io_triggered_3[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_3[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_3[1] && ft_s1_io_triggered_3[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_3[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_3[2] && ft_s1_io_triggered_3[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_3[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_3[3] && ft_s1_io_triggered_3[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_3[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_4[0] && ft_s1_io_triggered_4[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_4[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_4[1] && ft_s1_io_triggered_4[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_4[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_4[2] && ft_s1_io_triggered_4[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_4[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_4[3] && ft_s1_io_triggered_4[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_4[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_5[0] && ft_s1_io_triggered_5[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_5[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_5[1] && ft_s1_io_triggered_5[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_5[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_5[2] && ft_s1_io_triggered_5[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_5[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_5[3] && ft_s1_io_triggered_5[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_5[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_6[0] && ft_s1_io_triggered_6[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_6[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_6[1] && ft_s1_io_triggered_6[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_6[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_6[2] && ft_s1_io_triggered_6[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_6[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_6[3] && ft_s1_io_triggered_6[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_6[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_7[0] && ft_s1_io_triggered_7[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_7[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_7[1] && ft_s1_io_triggered_7[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_7[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_7[2] && ft_s1_io_triggered_7[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_7[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_7[3] && ft_s1_io_triggered_7[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_7[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_8[0] && ft_s1_io_triggered_8[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_8[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_8[1] && ft_s1_io_triggered_8[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_8[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_8[2] && ft_s1_io_triggered_8[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_8[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_8[3] && ft_s1_io_triggered_8[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_8[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_9[0] && ft_s1_io_triggered_9[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_9[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_9[1] && ft_s1_io_triggered_9[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_9[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_9[2] && ft_s1_io_triggered_9[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_9[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_9[3] && ft_s1_io_triggered_9[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_9[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_10[0] && ft_s1_io_triggered_10[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_10[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_10[1] && ft_s1_io_triggered_10[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_10[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_10[2] && ft_s1_io_triggered_10[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_10[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_10[3] && ft_s1_io_triggered_10[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_10[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_11[0] && ft_s1_io_triggered_11[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_11[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_11[1] && ft_s1_io_triggered_11[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_11[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_11[2] && ft_s1_io_triggered_11[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_11[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_11[3] && ft_s1_io_triggered_11[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_11[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_12[0] && ft_s1_io_triggered_12[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_12[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_12[1] && ft_s1_io_triggered_12[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_12[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_12[2] && ft_s1_io_triggered_12[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_12[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_12[3] && ft_s1_io_triggered_12[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_12[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_13[0] && ft_s1_io_triggered_13[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_13[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_13[1] && ft_s1_io_triggered_13[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_13[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_13[2] && ft_s1_io_triggered_13[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_13[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_13[3] && ft_s1_io_triggered_13[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_13[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_14[0] && ft_s1_io_triggered_14[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_14[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_14[1] && ft_s1_io_triggered_14[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_14[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_14[2] && ft_s1_io_triggered_14[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_14[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_14[3] && ft_s1_io_triggered_14[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_14[3] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_15[0] && ft_s1_io_triggered_15[0])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_15[0] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_15[1] && ft_s1_io_triggered_15[1])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_15[1] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_15[2] && ft_s1_io_triggered_15[2])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_15[2] 未见过 0 和 1"); end
    if (!(ft_s0_io_triggered_15[3] && ft_s1_io_triggered_15[3])) begin cov_fail++; $display("[COV] FrontendTrigger.io_triggered_15[3] 未见过 0 和 1"); end
    $display("[ARM] FrontendTrigger armed_at=%0d", ft_armed_at);
    if (ft_armed_at < 0) begin cov_fail++; $display("[ARM] FrontendTrigger 从未 arm"); end
    $display("[COV] FrontendTrigger.act_debug = %0d", ft_cov_act_debug);
    if (ft_cov_act_debug < 100) begin cov_fail++; $display("[COV] FrontendTrigger.act_debug < 100"); end
    $display("[COV] FrontendTrigger.act_bkpt = %0d", ft_cov_act_bkpt);
    if (ft_cov_act_bkpt < 100) begin cov_fail++; $display("[COV] FrontendTrigger.act_bkpt < 100"); end
    $display("[COV] FrontendTrigger.act_none = %0d", ft_cov_act_none);
    if (ft_cov_act_none < 100) begin cov_fail++; $display("[COV] FrontendTrigger.act_none < 100"); end
    $display("[COV] FrontendTrigger.bkpt_blocked = %0d", ft_cov_bkpt_blocked);
    if (ft_cov_bkpt_blocked < 100) begin cov_fail++; $display("[COV] FrontendTrigger.bkpt_blocked < 100"); end
    $display("[COV] FrontendTrigger.hit_eq = %0d", ft_cov_hit_eq);
    if (ft_cov_hit_eq < 100) begin cov_fail++; $display("[COV] FrontendTrigger.hit_eq < 100"); end
    $display("[COV] FrontendTrigger.hit_ge = %0d", ft_cov_hit_ge);
    if (ft_cov_hit_ge < 100) begin cov_fail++; $display("[COV] FrontendTrigger.hit_ge < 100"); end
    $display("[COV] FrontendTrigger.hit_lt = %0d", ft_cov_hit_lt);
    if (ft_cov_hit_lt < 100) begin cov_fail++; $display("[COV] FrontendTrigger.hit_lt < 100"); end
    $display("[COV] FrontendTrigger.napot_nohit = %0d", ft_cov_napot_nohit);
    if (ft_cov_napot_nohit < 100) begin cov_fail++; $display("[COV] FrontendTrigger.napot_nohit < 100"); end
    $display("[COV] FrontendTrigger.carry_hit = %0d", ft_cov_carry_hit);
    if (ft_cov_carry_hit < 100) begin cov_fail++; $display("[COV] FrontendTrigger.carry_hit < 100"); end
    $display("[COV] FrontendTrigger.carry_eq = %0d", ft_cov_carry_eq);
    if (ft_cov_carry_eq < 100) begin cov_fail++; $display("[COV] FrontendTrigger.carry_eq < 100"); end
    $display("[COV] FrontendTrigger.chain_fire = %0d", ft_cov_chain_fire);
    if (ft_cov_chain_fire < 100) begin cov_fail++; $display("[COV] FrontendTrigger.chain_fire < 100"); end
    $display("[COV] FrontendTrigger.chain_block = %0d", ft_cov_chain_block);
    if (ft_cov_chain_block < 100) begin cov_fail++; $display("[COV] FrontendTrigger.chain_block < 100"); end
    $display("[COV] FrontendTrigger.chain_mid = %0d", ft_cov_chain_mid);
    if (ft_cov_chain_mid < 100) begin cov_fail++; $display("[COV] FrontendTrigger.chain_mid < 100"); end
    $display("[COV] FrontendTrigger.select_block = %0d", ft_cov_select_block);
    if (ft_cov_select_block < 100) begin cov_fail++; $display("[COV] FrontendTrigger.select_block < 100"); end
    $display("[COV] FrontendTrigger.debug_block = %0d", ft_cov_debug_block);
    if (ft_cov_debug_block < 100) begin cov_fail++; $display("[COV] FrontendTrigger.debug_block < 100"); end
    $display("[COV] FrontendTrigger.update = %0d", ft_cov_update);
    if (ft_cov_update < 100) begin cov_fail++; $display("[COV] FrontendTrigger.update < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
