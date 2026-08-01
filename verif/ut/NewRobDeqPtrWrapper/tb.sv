// NewRobDeqPtrWrapper 双例化逐拍比对:
//   golden NewRobDeqPtrWrapper vs 可读 NewRobDeqPtrWrapper_xs (随机激励)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 40) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset = 1;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  // ---- 输入 ----
  logic [1:0] io_state;
  logic       io_deq_v_0, io_deq_v_1, io_deq_v_2, io_deq_v_3,
              io_deq_v_4, io_deq_v_5, io_deq_v_6, io_deq_v_7;
  logic       io_deq_w_0, io_deq_w_1, io_deq_w_2, io_deq_w_3,
              io_deq_w_4, io_deq_w_5, io_deq_w_6, io_deq_w_7;
  logic       io_hasCommitted_0, io_hasCommitted_1, io_hasCommitted_2, io_hasCommitted_3,
              io_hasCommitted_4, io_hasCommitted_5, io_hasCommitted_6, io_hasCommitted_7;
  logic       io_exception_state_valid;
  logic       io_exception_state_bits_robIdx_flag;
  logic [7:0] io_exception_state_bits_robIdx_value;
  logic       io_exception_state_bits_hasException;
  logic       io_exception_state_bits_replayInst;
  logic       io_exception_state_bits_singleStep;
  logic [3:0] io_exception_state_bits_trigger;
  logic       io_intrBitSetReg;
  logic       io_allowOnlyOneCommit;
  logic       io_hasNoSpecExec;
  logic       io_interrupt_safe;
  logic       io_blockCommit;

  // ---- 输出 (golden / impl) ----
  wire       g_io_out_0_flag, i_io_out_0_flag;
  wire [7:0] g_io_out_0_value, i_io_out_0_value;
  wire       g_io_out_1_flag, i_io_out_1_flag;
  wire [7:0] g_io_out_1_value, i_io_out_1_value;
  wire       g_io_out_2_flag, i_io_out_2_flag;
  wire [7:0] g_io_out_2_value, i_io_out_2_value;
  wire       g_io_out_3_flag, i_io_out_3_flag;
  wire [7:0] g_io_out_3_value, i_io_out_3_value;
  wire       g_io_out_4_flag, i_io_out_4_flag;
  wire [7:0] g_io_out_4_value, i_io_out_4_value;
  wire       g_io_out_5_flag, i_io_out_5_flag;
  wire [7:0] g_io_out_5_value, i_io_out_5_value;
  wire       g_io_out_6_flag, i_io_out_6_flag;
  wire [7:0] g_io_out_6_value, i_io_out_6_value;
  wire       g_io_out_7_flag, i_io_out_7_flag;
  wire [7:0] g_io_out_7_value, i_io_out_7_value;
  wire       g_io_next_out_0_flag, i_io_next_out_0_flag;
  wire [7:0] g_io_next_out_0_value, i_io_next_out_0_value;

  NewRobDeqPtrWrapper u_g (
    .clock(clock), .reset(reset), .io_state(io_state),
    .io_deq_v_0(io_deq_v_0), .io_deq_v_1(io_deq_v_1), .io_deq_v_2(io_deq_v_2), .io_deq_v_3(io_deq_v_3),
    .io_deq_v_4(io_deq_v_4), .io_deq_v_5(io_deq_v_5), .io_deq_v_6(io_deq_v_6), .io_deq_v_7(io_deq_v_7),
    .io_deq_w_0(io_deq_w_0), .io_deq_w_1(io_deq_w_1), .io_deq_w_2(io_deq_w_2), .io_deq_w_3(io_deq_w_3),
    .io_deq_w_4(io_deq_w_4), .io_deq_w_5(io_deq_w_5), .io_deq_w_6(io_deq_w_6), .io_deq_w_7(io_deq_w_7),
    .io_hasCommitted_0(io_hasCommitted_0), .io_hasCommitted_1(io_hasCommitted_1),
    .io_hasCommitted_2(io_hasCommitted_2), .io_hasCommitted_3(io_hasCommitted_3),
    .io_hasCommitted_4(io_hasCommitted_4), .io_hasCommitted_5(io_hasCommitted_5),
    .io_hasCommitted_6(io_hasCommitted_6), .io_hasCommitted_7(io_hasCommitted_7),
    .io_exception_state_valid(io_exception_state_valid),
    .io_exception_state_bits_robIdx_flag(io_exception_state_bits_robIdx_flag),
    .io_exception_state_bits_robIdx_value(io_exception_state_bits_robIdx_value),
    .io_exception_state_bits_hasException(io_exception_state_bits_hasException),
    .io_exception_state_bits_replayInst(io_exception_state_bits_replayInst),
    .io_exception_state_bits_singleStep(io_exception_state_bits_singleStep),
    .io_exception_state_bits_trigger(io_exception_state_bits_trigger),
    .io_intrBitSetReg(io_intrBitSetReg), .io_allowOnlyOneCommit(io_allowOnlyOneCommit),
    .io_hasNoSpecExec(io_hasNoSpecExec), .io_interrupt_safe(io_interrupt_safe),
    .io_blockCommit(io_blockCommit),
    .io_out_0_flag(g_io_out_0_flag), .io_out_0_value(g_io_out_0_value),
    .io_out_1_flag(g_io_out_1_flag), .io_out_1_value(g_io_out_1_value),
    .io_out_2_flag(g_io_out_2_flag), .io_out_2_value(g_io_out_2_value),
    .io_out_3_flag(g_io_out_3_flag), .io_out_3_value(g_io_out_3_value),
    .io_out_4_flag(g_io_out_4_flag), .io_out_4_value(g_io_out_4_value),
    .io_out_5_flag(g_io_out_5_flag), .io_out_5_value(g_io_out_5_value),
    .io_out_6_flag(g_io_out_6_flag), .io_out_6_value(g_io_out_6_value),
    .io_out_7_flag(g_io_out_7_flag), .io_out_7_value(g_io_out_7_value),
    .io_next_out_0_flag(g_io_next_out_0_flag), .io_next_out_0_value(g_io_next_out_0_value)
  );

  NewRobDeqPtrWrapper_xs u_i (
    .clock(clock), .reset(reset), .io_state(io_state),
    .io_deq_v_0(io_deq_v_0), .io_deq_v_1(io_deq_v_1), .io_deq_v_2(io_deq_v_2), .io_deq_v_3(io_deq_v_3),
    .io_deq_v_4(io_deq_v_4), .io_deq_v_5(io_deq_v_5), .io_deq_v_6(io_deq_v_6), .io_deq_v_7(io_deq_v_7),
    .io_deq_w_0(io_deq_w_0), .io_deq_w_1(io_deq_w_1), .io_deq_w_2(io_deq_w_2), .io_deq_w_3(io_deq_w_3),
    .io_deq_w_4(io_deq_w_4), .io_deq_w_5(io_deq_w_5), .io_deq_w_6(io_deq_w_6), .io_deq_w_7(io_deq_w_7),
    .io_hasCommitted_0(io_hasCommitted_0), .io_hasCommitted_1(io_hasCommitted_1),
    .io_hasCommitted_2(io_hasCommitted_2), .io_hasCommitted_3(io_hasCommitted_3),
    .io_hasCommitted_4(io_hasCommitted_4), .io_hasCommitted_5(io_hasCommitted_5),
    .io_hasCommitted_6(io_hasCommitted_6), .io_hasCommitted_7(io_hasCommitted_7),
    .io_exception_state_valid(io_exception_state_valid),
    .io_exception_state_bits_robIdx_flag(io_exception_state_bits_robIdx_flag),
    .io_exception_state_bits_robIdx_value(io_exception_state_bits_robIdx_value),
    .io_exception_state_bits_hasException(io_exception_state_bits_hasException),
    .io_exception_state_bits_replayInst(io_exception_state_bits_replayInst),
    .io_exception_state_bits_singleStep(io_exception_state_bits_singleStep),
    .io_exception_state_bits_trigger(io_exception_state_bits_trigger),
    .io_intrBitSetReg(io_intrBitSetReg), .io_allowOnlyOneCommit(io_allowOnlyOneCommit),
    .io_hasNoSpecExec(io_hasNoSpecExec), .io_interrupt_safe(io_interrupt_safe),
    .io_blockCommit(io_blockCommit),
    .io_out_0_flag(i_io_out_0_flag), .io_out_0_value(i_io_out_0_value),
    .io_out_1_flag(i_io_out_1_flag), .io_out_1_value(i_io_out_1_value),
    .io_out_2_flag(i_io_out_2_flag), .io_out_2_value(i_io_out_2_value),
    .io_out_3_flag(i_io_out_3_flag), .io_out_3_value(i_io_out_3_value),
    .io_out_4_flag(i_io_out_4_flag), .io_out_4_value(i_io_out_4_value),
    .io_out_5_flag(i_io_out_5_flag), .io_out_5_value(i_io_out_5_value),
    .io_out_6_flag(i_io_out_6_flag), .io_out_6_value(i_io_out_6_value),
    .io_out_7_flag(i_io_out_7_flag), .io_out_7_value(i_io_out_7_value),
    .io_next_out_0_flag(i_io_next_out_0_flag), .io_next_out_0_value(i_io_next_out_0_value)
  );

  // 各 lane 用一个 bias 概率使 canCommit 常为真, 让指针真正推进覆盖绕回。
  function automatic bit rb(input int pct);
    return ($urandom_range(0,99) < pct);
  endfunction

  task automatic drive_random_inputs();
    // 大多数周期 state=0 (commit 态), 偶尔 walk (非 0) 冻结指针。
    io_state = rb(85) ? 2'h0 : 2'(rb(50) ? 1 : 2);
    io_deq_v_0 = rb(80); io_deq_v_1 = rb(80); io_deq_v_2 = rb(80); io_deq_v_3 = rb(80);
    io_deq_v_4 = rb(80); io_deq_v_5 = rb(80); io_deq_v_6 = rb(80); io_deq_v_7 = rb(80);
    io_deq_w_0 = rb(80); io_deq_w_1 = rb(80); io_deq_w_2 = rb(80); io_deq_w_3 = rb(80);
    io_deq_w_4 = rb(80); io_deq_w_5 = rb(80); io_deq_w_6 = rb(80); io_deq_w_7 = rb(80);
    io_hasCommitted_0 = rb(20); io_hasCommitted_1 = rb(20);
    io_hasCommitted_2 = rb(20); io_hasCommitted_3 = rb(20);
    io_hasCommitted_4 = rb(20); io_hasCommitted_5 = rb(20);
    io_hasCommitted_6 = rb(20); io_hasCommitted_7 = rb(20);
    io_exception_state_valid            = rb(15);
    io_exception_state_bits_robIdx_flag = rb(50);
    io_exception_state_bits_robIdx_value= 8'($urandom);
    io_exception_state_bits_hasException= rb(50);
    io_exception_state_bits_replayInst  = rb(30);
    io_exception_state_bits_singleStep  = rb(30);
    io_exception_state_bits_trigger     = 4'($urandom);
    io_intrBitSetReg      = rb(15);
    io_allowOnlyOneCommit = rb(30);
    io_hasNoSpecExec      = rb(40);
    io_interrupt_safe     = rb(60);
    io_blockCommit        = rb(15);
  endtask

  task automatic check_outputs();
    `CHECK(io_out_0_flag)  `CHECK(io_out_0_value)
    `CHECK(io_out_1_flag)  `CHECK(io_out_1_value)
    `CHECK(io_out_2_flag)  `CHECK(io_out_2_value)
    `CHECK(io_out_3_flag)  `CHECK(io_out_3_value)
    `CHECK(io_out_4_flag)  `CHECK(io_out_4_value)
    `CHECK(io_out_5_flag)  `CHECK(io_out_5_value)
    `CHECK(io_out_6_flag)  `CHECK(io_out_6_value)
    `CHECK(io_out_7_flag)  `CHECK(io_out_7_value)
    `CHECK(io_next_out_0_flag) `CHECK(io_next_out_0_value)
  endtask

  initial begin
    // 复位若干拍
    drive_random_inputs();
    reset = 1;
    repeat (4) @(posedge clock);
    reset = 0;
    for (int c = 0; c < NCYCLES; c++) begin
      drive_random_inputs();
      @(negedge clock);       // 输入在 negedge 稳定
      check_outputs();        // 比对组合输出 (io_out = 当前寄存器, io_next_out_0 = 组合)
    end
    if (errors == 0) $display("=== TEST PASSED === checks=%0d errors=%0d", checks, errors);
    else             $display("=== TEST FAILED === checks=%0d errors=%0d", checks, errors);
    $finish;
  end

  // 看门狗
  initial begin
    #(NCYCLES*20 + 100000);
    $display("=== TEST FAILED (timeout) === checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
