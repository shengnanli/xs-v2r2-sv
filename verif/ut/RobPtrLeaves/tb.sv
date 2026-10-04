// 自动生成：verif/ut/RobPtrLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// Rob 的三个指针/计数子模块双例化逐拍比对：golden <名> vs 重写 <名>_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= CommitStuckCounter =================
  int unsigned cs_mode = 0;
  always @(negedge clk) if (cyc % 4000 == 1000) begin
    force cs_u_gold.count = 21'h1FFFE0;
    force cs_u_impl.u_core.count = 21'h1FFFE0;
    #1;
    release cs_u_gold.count;
    release cs_u_impl.u_core.count;
  end
  logic cs_reset;
  logic cs_io_stuck;
  wire  cs_g_io_overflow, cs_i_io_overflow;
  logic cs_s0_io_overflow = '0, cs_s1_io_overflow = '0;
  int cs_cov_overflow = 0;
  int cs_cov_stuck_run = 0;
  logic [0:0] cs_armed = '0;
  int cs_armed_at = -1;
  CommitStuckCounter cs_u_gold (
    .clock(clk),
    .reset(cs_reset),
    .io_stuck(cs_io_stuck),
    .io_overflow(cs_g_io_overflow)
  );
  CommitStuckCounter_xs cs_u_impl (
    .clock(clk),
    .reset(cs_reset),
    .io_stuck(cs_io_stuck),
    .io_overflow(cs_i_io_overflow)
  );

  // ================= RobEnqPtrWrapper =================
  int unsigned eq_mode = 0;
  logic eq_reset;
  logic eq_io_redirect_valid;
  logic eq_io_redirect_bits_robIdx_flag;
  logic [7:0] eq_io_redirect_bits_robIdx_value;
  logic eq_io_redirect_bits_level;
  logic eq_io_allowEnqueue;
  logic eq_io_hasBlockBackward;
  logic eq_io_enq_0;
  logic eq_io_enq_1;
  logic eq_io_enq_2;
  logic eq_io_enq_3;
  logic eq_io_enq_4;
  logic eq_io_enq_5;
  wire  eq_g_io_out_0_flag, eq_i_io_out_0_flag;
  logic eq_s0_io_out_0_flag = '0, eq_s1_io_out_0_flag = '0;
  wire  [7:0] eq_g_io_out_0_value, eq_i_io_out_0_value;
  logic [7:0] eq_s0_io_out_0_value = '0, eq_s1_io_out_0_value = '0;
  wire  eq_g_io_out_1_flag, eq_i_io_out_1_flag;
  logic eq_s0_io_out_1_flag = '0, eq_s1_io_out_1_flag = '0;
  wire  [7:0] eq_g_io_out_1_value, eq_i_io_out_1_value;
  logic [7:0] eq_s0_io_out_1_value = '0, eq_s1_io_out_1_value = '0;
  wire  eq_g_io_out_2_flag, eq_i_io_out_2_flag;
  logic eq_s0_io_out_2_flag = '0, eq_s1_io_out_2_flag = '0;
  wire  [7:0] eq_g_io_out_2_value, eq_i_io_out_2_value;
  logic [7:0] eq_s0_io_out_2_value = '0, eq_s1_io_out_2_value = '0;
  wire  eq_g_io_out_3_flag, eq_i_io_out_3_flag;
  logic eq_s0_io_out_3_flag = '0, eq_s1_io_out_3_flag = '0;
  wire  [7:0] eq_g_io_out_3_value, eq_i_io_out_3_value;
  logic [7:0] eq_s0_io_out_3_value = '0, eq_s1_io_out_3_value = '0;
  wire  eq_g_io_out_4_flag, eq_i_io_out_4_flag;
  logic eq_s0_io_out_4_flag = '0, eq_s1_io_out_4_flag = '0;
  wire  [7:0] eq_g_io_out_4_value, eq_i_io_out_4_value;
  logic [7:0] eq_s0_io_out_4_value = '0, eq_s1_io_out_4_value = '0;
  wire  eq_g_io_out_5_flag, eq_i_io_out_5_flag;
  logic eq_s0_io_out_5_flag = '0, eq_s1_io_out_5_flag = '0;
  wire  [7:0] eq_g_io_out_5_value, eq_i_io_out_5_value;
  logic [7:0] eq_s0_io_out_5_value = '0, eq_s1_io_out_5_value = '0;
  int eq_cov_redirect_lvl1 = 0;
  int eq_cov_redirect_lvl0 = 0;
  int eq_cov_redirect_illegal = 0;
  int eq_cov_enq6 = 0;
  int eq_cov_wrap0 = 0;
  int eq_cov_flag5 = 0;
  logic [0:0] eq_armed = '0;
  int eq_armed_at = -1;
  RobEnqPtrWrapper eq_u_gold (
    .clock(clk),
    .reset(eq_reset),
    .io_redirect_valid(eq_io_redirect_valid),
    .io_redirect_bits_robIdx_flag(eq_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(eq_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(eq_io_redirect_bits_level),
    .io_allowEnqueue(eq_io_allowEnqueue),
    .io_hasBlockBackward(eq_io_hasBlockBackward),
    .io_enq_0(eq_io_enq_0),
    .io_enq_1(eq_io_enq_1),
    .io_enq_2(eq_io_enq_2),
    .io_enq_3(eq_io_enq_3),
    .io_enq_4(eq_io_enq_4),
    .io_enq_5(eq_io_enq_5),
    .io_out_0_flag(eq_g_io_out_0_flag),
    .io_out_0_value(eq_g_io_out_0_value),
    .io_out_1_flag(eq_g_io_out_1_flag),
    .io_out_1_value(eq_g_io_out_1_value),
    .io_out_2_flag(eq_g_io_out_2_flag),
    .io_out_2_value(eq_g_io_out_2_value),
    .io_out_3_flag(eq_g_io_out_3_flag),
    .io_out_3_value(eq_g_io_out_3_value),
    .io_out_4_flag(eq_g_io_out_4_flag),
    .io_out_4_value(eq_g_io_out_4_value),
    .io_out_5_flag(eq_g_io_out_5_flag),
    .io_out_5_value(eq_g_io_out_5_value)
  );
  RobEnqPtrWrapper_xs eq_u_impl (
    .clock(clk),
    .reset(eq_reset),
    .io_redirect_valid(eq_io_redirect_valid),
    .io_redirect_bits_robIdx_flag(eq_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(eq_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(eq_io_redirect_bits_level),
    .io_allowEnqueue(eq_io_allowEnqueue),
    .io_hasBlockBackward(eq_io_hasBlockBackward),
    .io_enq_0(eq_io_enq_0),
    .io_enq_1(eq_io_enq_1),
    .io_enq_2(eq_io_enq_2),
    .io_enq_3(eq_io_enq_3),
    .io_enq_4(eq_io_enq_4),
    .io_enq_5(eq_io_enq_5),
    .io_out_0_flag(eq_i_io_out_0_flag),
    .io_out_0_value(eq_i_io_out_0_value),
    .io_out_1_flag(eq_i_io_out_1_flag),
    .io_out_1_value(eq_i_io_out_1_value),
    .io_out_2_flag(eq_i_io_out_2_flag),
    .io_out_2_value(eq_i_io_out_2_value),
    .io_out_3_flag(eq_i_io_out_3_flag),
    .io_out_3_value(eq_i_io_out_3_value),
    .io_out_4_flag(eq_i_io_out_4_flag),
    .io_out_4_value(eq_i_io_out_4_value),
    .io_out_5_flag(eq_i_io_out_5_flag),
    .io_out_5_value(eq_i_io_out_5_value)
  );

  // ================= NewRobDeqPtrWrapper =================
  int unsigned dq_mode = 0;
  logic dq_reset;
  logic [1:0] dq_io_state;
  logic dq_io_deq_v_0;
  logic dq_io_deq_v_1;
  logic dq_io_deq_v_2;
  logic dq_io_deq_v_3;
  logic dq_io_deq_v_4;
  logic dq_io_deq_v_5;
  logic dq_io_deq_v_6;
  logic dq_io_deq_v_7;
  logic dq_io_deq_w_0;
  logic dq_io_deq_w_1;
  logic dq_io_deq_w_2;
  logic dq_io_deq_w_3;
  logic dq_io_deq_w_4;
  logic dq_io_deq_w_5;
  logic dq_io_deq_w_6;
  logic dq_io_deq_w_7;
  logic dq_io_hasCommitted_0;
  logic dq_io_hasCommitted_1;
  logic dq_io_hasCommitted_2;
  logic dq_io_hasCommitted_3;
  logic dq_io_hasCommitted_4;
  logic dq_io_hasCommitted_5;
  logic dq_io_hasCommitted_6;
  logic dq_io_hasCommitted_7;
  logic dq_io_exception_state_valid;
  logic dq_io_exception_state_bits_robIdx_flag;
  logic [7:0] dq_io_exception_state_bits_robIdx_value;
  logic dq_io_exception_state_bits_hasException;
  logic dq_io_exception_state_bits_replayInst;
  logic dq_io_exception_state_bits_singleStep;
  logic [3:0] dq_io_exception_state_bits_trigger;
  logic dq_io_intrBitSetReg;
  logic dq_io_allowOnlyOneCommit;
  logic dq_io_hasNoSpecExec;
  logic dq_io_interrupt_safe;
  logic dq_io_blockCommit;
  wire  dq_g_io_out_0_flag, dq_i_io_out_0_flag;
  logic dq_s0_io_out_0_flag = '0, dq_s1_io_out_0_flag = '0;
  wire  [7:0] dq_g_io_out_0_value, dq_i_io_out_0_value;
  logic [7:0] dq_s0_io_out_0_value = '0, dq_s1_io_out_0_value = '0;
  wire  dq_g_io_out_1_flag, dq_i_io_out_1_flag;
  logic dq_s0_io_out_1_flag = '0, dq_s1_io_out_1_flag = '0;
  wire  [7:0] dq_g_io_out_1_value, dq_i_io_out_1_value;
  logic [7:0] dq_s0_io_out_1_value = '0, dq_s1_io_out_1_value = '0;
  wire  dq_g_io_out_2_flag, dq_i_io_out_2_flag;
  logic dq_s0_io_out_2_flag = '0, dq_s1_io_out_2_flag = '0;
  wire  [7:0] dq_g_io_out_2_value, dq_i_io_out_2_value;
  logic [7:0] dq_s0_io_out_2_value = '0, dq_s1_io_out_2_value = '0;
  wire  dq_g_io_out_3_flag, dq_i_io_out_3_flag;
  logic dq_s0_io_out_3_flag = '0, dq_s1_io_out_3_flag = '0;
  wire  [7:0] dq_g_io_out_3_value, dq_i_io_out_3_value;
  logic [7:0] dq_s0_io_out_3_value = '0, dq_s1_io_out_3_value = '0;
  wire  dq_g_io_out_4_flag, dq_i_io_out_4_flag;
  logic dq_s0_io_out_4_flag = '0, dq_s1_io_out_4_flag = '0;
  wire  [7:0] dq_g_io_out_4_value, dq_i_io_out_4_value;
  logic [7:0] dq_s0_io_out_4_value = '0, dq_s1_io_out_4_value = '0;
  wire  dq_g_io_out_5_flag, dq_i_io_out_5_flag;
  logic dq_s0_io_out_5_flag = '0, dq_s1_io_out_5_flag = '0;
  wire  [7:0] dq_g_io_out_5_value, dq_i_io_out_5_value;
  logic [7:0] dq_s0_io_out_5_value = '0, dq_s1_io_out_5_value = '0;
  wire  dq_g_io_out_6_flag, dq_i_io_out_6_flag;
  logic dq_s0_io_out_6_flag = '0, dq_s1_io_out_6_flag = '0;
  wire  [7:0] dq_g_io_out_6_value, dq_i_io_out_6_value;
  logic [7:0] dq_s0_io_out_6_value = '0, dq_s1_io_out_6_value = '0;
  wire  dq_g_io_out_7_flag, dq_i_io_out_7_flag;
  logic dq_s0_io_out_7_flag = '0, dq_s1_io_out_7_flag = '0;
  wire  [7:0] dq_g_io_out_7_value, dq_i_io_out_7_value;
  logic [7:0] dq_s0_io_out_7_value = '0, dq_s1_io_out_7_value = '0;
  wire  dq_g_io_next_out_0_flag, dq_i_io_next_out_0_flag;
  logic dq_s0_io_next_out_0_flag = '0, dq_s1_io_next_out_0_flag = '0;
  wire  [7:0] dq_g_io_next_out_0_value, dq_i_io_next_out_0_value;
  logic [7:0] dq_s0_io_next_out_0_value = '0, dq_s1_io_next_out_0_value = '0;
  wire  dq_g_io_next_out_1_flag, dq_i_io_next_out_1_flag;
  logic dq_s0_io_next_out_1_flag = '0, dq_s1_io_next_out_1_flag = '0;
  wire  [7:0] dq_g_io_next_out_1_value, dq_i_io_next_out_1_value;
  logic [7:0] dq_s0_io_next_out_1_value = '0, dq_s1_io_next_out_1_value = '0;
  wire  dq_g_io_next_out_2_flag, dq_i_io_next_out_2_flag;
  logic dq_s0_io_next_out_2_flag = '0, dq_s1_io_next_out_2_flag = '0;
  wire  [7:0] dq_g_io_next_out_2_value, dq_i_io_next_out_2_value;
  logic [7:0] dq_s0_io_next_out_2_value = '0, dq_s1_io_next_out_2_value = '0;
  wire  dq_g_io_next_out_3_flag, dq_i_io_next_out_3_flag;
  logic dq_s0_io_next_out_3_flag = '0, dq_s1_io_next_out_3_flag = '0;
  wire  [7:0] dq_g_io_next_out_3_value, dq_i_io_next_out_3_value;
  logic [7:0] dq_s0_io_next_out_3_value = '0, dq_s1_io_next_out_3_value = '0;
  wire  dq_g_io_next_out_4_flag, dq_i_io_next_out_4_flag;
  logic dq_s0_io_next_out_4_flag = '0, dq_s1_io_next_out_4_flag = '0;
  wire  [7:0] dq_g_io_next_out_4_value, dq_i_io_next_out_4_value;
  logic [7:0] dq_s0_io_next_out_4_value = '0, dq_s1_io_next_out_4_value = '0;
  wire  dq_g_io_next_out_5_flag, dq_i_io_next_out_5_flag;
  logic dq_s0_io_next_out_5_flag = '0, dq_s1_io_next_out_5_flag = '0;
  wire  [7:0] dq_g_io_next_out_5_value, dq_i_io_next_out_5_value;
  logic [7:0] dq_s0_io_next_out_5_value = '0, dq_s1_io_next_out_5_value = '0;
  wire  dq_g_io_next_out_6_flag, dq_i_io_next_out_6_flag;
  logic dq_s0_io_next_out_6_flag = '0, dq_s1_io_next_out_6_flag = '0;
  wire  [7:0] dq_g_io_next_out_6_value, dq_i_io_next_out_6_value;
  logic [7:0] dq_s0_io_next_out_6_value = '0, dq_s1_io_next_out_6_value = '0;
  wire  dq_g_io_next_out_7_flag, dq_i_io_next_out_7_flag;
  logic dq_s0_io_next_out_7_flag = '0, dq_s1_io_next_out_7_flag = '0;
  wire  [7:0] dq_g_io_next_out_7_value, dq_i_io_next_out_7_value;
  logic [7:0] dq_s0_io_next_out_7_value = '0, dq_s1_io_next_out_7_value = '0;
  wire  dq_g_io_canCommitPriorityCond_0, dq_i_io_canCommitPriorityCond_0;
  logic dq_s0_io_canCommitPriorityCond_0 = '0, dq_s1_io_canCommitPriorityCond_0 = '0;
  wire  dq_g_io_canCommitPriorityCond_1, dq_i_io_canCommitPriorityCond_1;
  logic dq_s0_io_canCommitPriorityCond_1 = '0, dq_s1_io_canCommitPriorityCond_1 = '0;
  wire  dq_g_io_canCommitPriorityCond_2, dq_i_io_canCommitPriorityCond_2;
  logic dq_s0_io_canCommitPriorityCond_2 = '0, dq_s1_io_canCommitPriorityCond_2 = '0;
  wire  dq_g_io_canCommitPriorityCond_3, dq_i_io_canCommitPriorityCond_3;
  logic dq_s0_io_canCommitPriorityCond_3 = '0, dq_s1_io_canCommitPriorityCond_3 = '0;
  wire  dq_g_io_canCommitPriorityCond_4, dq_i_io_canCommitPriorityCond_4;
  logic dq_s0_io_canCommitPriorityCond_4 = '0, dq_s1_io_canCommitPriorityCond_4 = '0;
  wire  dq_g_io_canCommitPriorityCond_5, dq_i_io_canCommitPriorityCond_5;
  logic dq_s0_io_canCommitPriorityCond_5 = '0, dq_s1_io_canCommitPriorityCond_5 = '0;
  wire  dq_g_io_canCommitPriorityCond_6, dq_i_io_canCommitPriorityCond_6;
  logic dq_s0_io_canCommitPriorityCond_6 = '0, dq_s1_io_canCommitPriorityCond_6 = '0;
  wire  dq_g_io_canCommitPriorityCond_7, dq_i_io_canCommitPriorityCond_7;
  logic dq_s0_io_canCommitPriorityCond_7 = '0, dq_s1_io_canCommitPriorityCond_7 = '0;
  wire  dq_g_io_canCommitPriorityCond_8, dq_i_io_canCommitPriorityCond_8;
  logic dq_s0_io_canCommitPriorityCond_8 = '0, dq_s1_io_canCommitPriorityCond_8 = '0;
  int dq_cov_redirect_out = 0;
  int dq_cov_commit_en = 0;
  int dq_cov_only_one = 0;
  int dq_cov_full_line = 0;
  int dq_cov_wrap = 0;
  int dq_cov_trigger_dbg = 0;
  logic [0:0] dq_armed = '0;
  int dq_armed_at = -1;
  NewRobDeqPtrWrapper dq_u_gold (
    .clock(clk),
    .reset(dq_reset),
    .io_state(dq_io_state),
    .io_deq_v_0(dq_io_deq_v_0),
    .io_deq_v_1(dq_io_deq_v_1),
    .io_deq_v_2(dq_io_deq_v_2),
    .io_deq_v_3(dq_io_deq_v_3),
    .io_deq_v_4(dq_io_deq_v_4),
    .io_deq_v_5(dq_io_deq_v_5),
    .io_deq_v_6(dq_io_deq_v_6),
    .io_deq_v_7(dq_io_deq_v_7),
    .io_deq_w_0(dq_io_deq_w_0),
    .io_deq_w_1(dq_io_deq_w_1),
    .io_deq_w_2(dq_io_deq_w_2),
    .io_deq_w_3(dq_io_deq_w_3),
    .io_deq_w_4(dq_io_deq_w_4),
    .io_deq_w_5(dq_io_deq_w_5),
    .io_deq_w_6(dq_io_deq_w_6),
    .io_deq_w_7(dq_io_deq_w_7),
    .io_hasCommitted_0(dq_io_hasCommitted_0),
    .io_hasCommitted_1(dq_io_hasCommitted_1),
    .io_hasCommitted_2(dq_io_hasCommitted_2),
    .io_hasCommitted_3(dq_io_hasCommitted_3),
    .io_hasCommitted_4(dq_io_hasCommitted_4),
    .io_hasCommitted_5(dq_io_hasCommitted_5),
    .io_hasCommitted_6(dq_io_hasCommitted_6),
    .io_hasCommitted_7(dq_io_hasCommitted_7),
    .io_exception_state_valid(dq_io_exception_state_valid),
    .io_exception_state_bits_robIdx_flag(dq_io_exception_state_bits_robIdx_flag),
    .io_exception_state_bits_robIdx_value(dq_io_exception_state_bits_robIdx_value),
    .io_exception_state_bits_hasException(dq_io_exception_state_bits_hasException),
    .io_exception_state_bits_replayInst(dq_io_exception_state_bits_replayInst),
    .io_exception_state_bits_singleStep(dq_io_exception_state_bits_singleStep),
    .io_exception_state_bits_trigger(dq_io_exception_state_bits_trigger),
    .io_intrBitSetReg(dq_io_intrBitSetReg),
    .io_allowOnlyOneCommit(dq_io_allowOnlyOneCommit),
    .io_hasNoSpecExec(dq_io_hasNoSpecExec),
    .io_interrupt_safe(dq_io_interrupt_safe),
    .io_blockCommit(dq_io_blockCommit),
    .io_out_0_flag(dq_g_io_out_0_flag),
    .io_out_0_value(dq_g_io_out_0_value),
    .io_out_1_flag(dq_g_io_out_1_flag),
    .io_out_1_value(dq_g_io_out_1_value),
    .io_out_2_flag(dq_g_io_out_2_flag),
    .io_out_2_value(dq_g_io_out_2_value),
    .io_out_3_flag(dq_g_io_out_3_flag),
    .io_out_3_value(dq_g_io_out_3_value),
    .io_out_4_flag(dq_g_io_out_4_flag),
    .io_out_4_value(dq_g_io_out_4_value),
    .io_out_5_flag(dq_g_io_out_5_flag),
    .io_out_5_value(dq_g_io_out_5_value),
    .io_out_6_flag(dq_g_io_out_6_flag),
    .io_out_6_value(dq_g_io_out_6_value),
    .io_out_7_flag(dq_g_io_out_7_flag),
    .io_out_7_value(dq_g_io_out_7_value),
    .io_next_out_0_flag(dq_g_io_next_out_0_flag),
    .io_next_out_0_value(dq_g_io_next_out_0_value),
    .io_next_out_1_flag(dq_g_io_next_out_1_flag),
    .io_next_out_1_value(dq_g_io_next_out_1_value),
    .io_next_out_2_flag(dq_g_io_next_out_2_flag),
    .io_next_out_2_value(dq_g_io_next_out_2_value),
    .io_next_out_3_flag(dq_g_io_next_out_3_flag),
    .io_next_out_3_value(dq_g_io_next_out_3_value),
    .io_next_out_4_flag(dq_g_io_next_out_4_flag),
    .io_next_out_4_value(dq_g_io_next_out_4_value),
    .io_next_out_5_flag(dq_g_io_next_out_5_flag),
    .io_next_out_5_value(dq_g_io_next_out_5_value),
    .io_next_out_6_flag(dq_g_io_next_out_6_flag),
    .io_next_out_6_value(dq_g_io_next_out_6_value),
    .io_next_out_7_flag(dq_g_io_next_out_7_flag),
    .io_next_out_7_value(dq_g_io_next_out_7_value),
    .io_canCommitPriorityCond_0(dq_g_io_canCommitPriorityCond_0),
    .io_canCommitPriorityCond_1(dq_g_io_canCommitPriorityCond_1),
    .io_canCommitPriorityCond_2(dq_g_io_canCommitPriorityCond_2),
    .io_canCommitPriorityCond_3(dq_g_io_canCommitPriorityCond_3),
    .io_canCommitPriorityCond_4(dq_g_io_canCommitPriorityCond_4),
    .io_canCommitPriorityCond_5(dq_g_io_canCommitPriorityCond_5),
    .io_canCommitPriorityCond_6(dq_g_io_canCommitPriorityCond_6),
    .io_canCommitPriorityCond_7(dq_g_io_canCommitPriorityCond_7),
    .io_canCommitPriorityCond_8(dq_g_io_canCommitPriorityCond_8)
  );
  NewRobDeqPtrWrapper_xs dq_u_impl (
    .clock(clk),
    .reset(dq_reset),
    .io_state(dq_io_state),
    .io_deq_v_0(dq_io_deq_v_0),
    .io_deq_v_1(dq_io_deq_v_1),
    .io_deq_v_2(dq_io_deq_v_2),
    .io_deq_v_3(dq_io_deq_v_3),
    .io_deq_v_4(dq_io_deq_v_4),
    .io_deq_v_5(dq_io_deq_v_5),
    .io_deq_v_6(dq_io_deq_v_6),
    .io_deq_v_7(dq_io_deq_v_7),
    .io_deq_w_0(dq_io_deq_w_0),
    .io_deq_w_1(dq_io_deq_w_1),
    .io_deq_w_2(dq_io_deq_w_2),
    .io_deq_w_3(dq_io_deq_w_3),
    .io_deq_w_4(dq_io_deq_w_4),
    .io_deq_w_5(dq_io_deq_w_5),
    .io_deq_w_6(dq_io_deq_w_6),
    .io_deq_w_7(dq_io_deq_w_7),
    .io_hasCommitted_0(dq_io_hasCommitted_0),
    .io_hasCommitted_1(dq_io_hasCommitted_1),
    .io_hasCommitted_2(dq_io_hasCommitted_2),
    .io_hasCommitted_3(dq_io_hasCommitted_3),
    .io_hasCommitted_4(dq_io_hasCommitted_4),
    .io_hasCommitted_5(dq_io_hasCommitted_5),
    .io_hasCommitted_6(dq_io_hasCommitted_6),
    .io_hasCommitted_7(dq_io_hasCommitted_7),
    .io_exception_state_valid(dq_io_exception_state_valid),
    .io_exception_state_bits_robIdx_flag(dq_io_exception_state_bits_robIdx_flag),
    .io_exception_state_bits_robIdx_value(dq_io_exception_state_bits_robIdx_value),
    .io_exception_state_bits_hasException(dq_io_exception_state_bits_hasException),
    .io_exception_state_bits_replayInst(dq_io_exception_state_bits_replayInst),
    .io_exception_state_bits_singleStep(dq_io_exception_state_bits_singleStep),
    .io_exception_state_bits_trigger(dq_io_exception_state_bits_trigger),
    .io_intrBitSetReg(dq_io_intrBitSetReg),
    .io_allowOnlyOneCommit(dq_io_allowOnlyOneCommit),
    .io_hasNoSpecExec(dq_io_hasNoSpecExec),
    .io_interrupt_safe(dq_io_interrupt_safe),
    .io_blockCommit(dq_io_blockCommit),
    .io_out_0_flag(dq_i_io_out_0_flag),
    .io_out_0_value(dq_i_io_out_0_value),
    .io_out_1_flag(dq_i_io_out_1_flag),
    .io_out_1_value(dq_i_io_out_1_value),
    .io_out_2_flag(dq_i_io_out_2_flag),
    .io_out_2_value(dq_i_io_out_2_value),
    .io_out_3_flag(dq_i_io_out_3_flag),
    .io_out_3_value(dq_i_io_out_3_value),
    .io_out_4_flag(dq_i_io_out_4_flag),
    .io_out_4_value(dq_i_io_out_4_value),
    .io_out_5_flag(dq_i_io_out_5_flag),
    .io_out_5_value(dq_i_io_out_5_value),
    .io_out_6_flag(dq_i_io_out_6_flag),
    .io_out_6_value(dq_i_io_out_6_value),
    .io_out_7_flag(dq_i_io_out_7_flag),
    .io_out_7_value(dq_i_io_out_7_value),
    .io_next_out_0_flag(dq_i_io_next_out_0_flag),
    .io_next_out_0_value(dq_i_io_next_out_0_value),
    .io_next_out_1_flag(dq_i_io_next_out_1_flag),
    .io_next_out_1_value(dq_i_io_next_out_1_value),
    .io_next_out_2_flag(dq_i_io_next_out_2_flag),
    .io_next_out_2_value(dq_i_io_next_out_2_value),
    .io_next_out_3_flag(dq_i_io_next_out_3_flag),
    .io_next_out_3_value(dq_i_io_next_out_3_value),
    .io_next_out_4_flag(dq_i_io_next_out_4_flag),
    .io_next_out_4_value(dq_i_io_next_out_4_value),
    .io_next_out_5_flag(dq_i_io_next_out_5_flag),
    .io_next_out_5_value(dq_i_io_next_out_5_value),
    .io_next_out_6_flag(dq_i_io_next_out_6_flag),
    .io_next_out_6_value(dq_i_io_next_out_6_value),
    .io_next_out_7_flag(dq_i_io_next_out_7_flag),
    .io_next_out_7_value(dq_i_io_next_out_7_value),
    .io_canCommitPriorityCond_0(dq_i_io_canCommitPriorityCond_0),
    .io_canCommitPriorityCond_1(dq_i_io_canCommitPriorityCond_1),
    .io_canCommitPriorityCond_2(dq_i_io_canCommitPriorityCond_2),
    .io_canCommitPriorityCond_3(dq_i_io_canCommitPriorityCond_3),
    .io_canCommitPriorityCond_4(dq_i_io_canCommitPriorityCond_4),
    .io_canCommitPriorityCond_5(dq_i_io_canCommitPriorityCond_5),
    .io_canCommitPriorityCond_6(dq_i_io_canCommitPriorityCond_6),
    .io_canCommitPriorityCond_7(dq_i_io_canCommitPriorityCond_7),
    .io_canCommitPriorityCond_8(dq_i_io_canCommitPriorityCond_8)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 3000 == 0) cs_mode = $urandom_range(0, 15);
      cs_io_stuck = 1'($urandom);
      cs_reset = (cyc < RESET_CYC) || ($urandom_range(0, 49999) == 0);
      begin : stim_cs
        case (cs_mode % 4)
          0: cs_io_stuck = 1'b1;
          1: cs_io_stuck = ($urandom_range(0, 63) != 0);
          2: cs_io_stuck = ($urandom_range(0, 3) != 0);
          3: ;
        endcase
        if (cyc % 4000 >= 990 && cyc % 4000 < 1100) cs_io_stuck = 1'b1;
      end
      if (cyc % 500 == 0) eq_mode = $urandom_range(0, 15);
      eq_io_redirect_valid = 1'($urandom);
      eq_io_redirect_bits_robIdx_flag = 1'($urandom);
      eq_io_redirect_bits_robIdx_value = 8'($urandom);
      eq_io_redirect_bits_level = 1'($urandom);
      eq_io_allowEnqueue = 1'($urandom);
      eq_io_hasBlockBackward = 1'($urandom);
      eq_io_enq_0 = 1'($urandom);
      eq_io_enq_1 = 1'($urandom);
      eq_io_enq_2 = 1'($urandom);
      eq_io_enq_3 = 1'($urandom);
      eq_io_enq_4 = 1'($urandom);
      eq_io_enq_5 = 1'($urandom);
      eq_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_eq
        eq_io_redirect_valid = ($urandom_range(0, 15) == 0);
        eq_io_redirect_bits_robIdx_value = ($urandom_range(0, 31) == 0) ? 8'($urandom_range(160, 255))
                                                                       : 8'($urandom_range(0, 159));
        eq_io_allowEnqueue = ($urandom_range(0, 7) != 0);
        eq_io_hasBlockBackward = ($urandom_range(0, 15) == 0);
        if (eq_mode % 3 == 0) {eq_io_enq_5, eq_io_enq_4, eq_io_enq_3, eq_io_enq_2, eq_io_enq_1, eq_io_enq_0} = 6'h3F;
      end
      if (cyc % 500 == 0) dq_mode = $urandom_range(0, 15);
      dq_io_state = 2'($urandom);
      dq_io_deq_v_0 = 1'($urandom);
      dq_io_deq_v_1 = 1'($urandom);
      dq_io_deq_v_2 = 1'($urandom);
      dq_io_deq_v_3 = 1'($urandom);
      dq_io_deq_v_4 = 1'($urandom);
      dq_io_deq_v_5 = 1'($urandom);
      dq_io_deq_v_6 = 1'($urandom);
      dq_io_deq_v_7 = 1'($urandom);
      dq_io_deq_w_0 = 1'($urandom);
      dq_io_deq_w_1 = 1'($urandom);
      dq_io_deq_w_2 = 1'($urandom);
      dq_io_deq_w_3 = 1'($urandom);
      dq_io_deq_w_4 = 1'($urandom);
      dq_io_deq_w_5 = 1'($urandom);
      dq_io_deq_w_6 = 1'($urandom);
      dq_io_deq_w_7 = 1'($urandom);
      dq_io_hasCommitted_0 = 1'($urandom);
      dq_io_hasCommitted_1 = 1'($urandom);
      dq_io_hasCommitted_2 = 1'($urandom);
      dq_io_hasCommitted_3 = 1'($urandom);
      dq_io_hasCommitted_4 = 1'($urandom);
      dq_io_hasCommitted_5 = 1'($urandom);
      dq_io_hasCommitted_6 = 1'($urandom);
      dq_io_hasCommitted_7 = 1'($urandom);
      dq_io_exception_state_valid = 1'($urandom);
      dq_io_exception_state_bits_robIdx_flag = 1'($urandom);
      dq_io_exception_state_bits_robIdx_value = 8'($urandom);
      dq_io_exception_state_bits_hasException = 1'($urandom);
      dq_io_exception_state_bits_replayInst = 1'($urandom);
      dq_io_exception_state_bits_singleStep = 1'($urandom);
      dq_io_exception_state_bits_trigger = 4'($urandom);
      dq_io_intrBitSetReg = 1'($urandom);
      dq_io_allowOnlyOneCommit = 1'($urandom);
      dq_io_hasNoSpecExec = 1'($urandom);
      dq_io_interrupt_safe = 1'($urandom);
      dq_io_blockCommit = 1'($urandom);
      dq_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_dq
        dq_io_state = ($urandom_range(0, 7) == 0) ? 2'($urandom) : 2'd0;
        case (dq_mode % 4)
          0: begin  // 整行都能提交
            {dq_io_deq_v_7, dq_io_deq_v_6, dq_io_deq_v_5, dq_io_deq_v_4, dq_io_deq_v_3, dq_io_deq_v_2, dq_io_deq_v_1, dq_io_deq_v_0} = 8'hFF;
            {dq_io_deq_w_7, dq_io_deq_w_6, dq_io_deq_w_5, dq_io_deq_w_4, dq_io_deq_w_3, dq_io_deq_w_2, dq_io_deq_w_1, dq_io_deq_w_0} = 8'hFF;
          end
          1: begin  // 前缀能提交
            automatic int k = $urandom_range(0, 8);
            automatic logic [7:0] m = 8'((16'h1 << k) - 1);
            {dq_io_deq_v_7, dq_io_deq_v_6, dq_io_deq_v_5, dq_io_deq_v_4, dq_io_deq_v_3, dq_io_deq_v_2, dq_io_deq_v_1, dq_io_deq_v_0} = m | 8'($urandom);
            {dq_io_deq_w_7, dq_io_deq_w_6, dq_io_deq_w_5, dq_io_deq_w_4, dq_io_deq_w_3, dq_io_deq_w_2, dq_io_deq_w_1, dq_io_deq_w_0} = m;
            {dq_io_hasCommitted_7, dq_io_hasCommitted_6, dq_io_hasCommitted_5, dq_io_hasCommitted_4, dq_io_hasCommitted_3, dq_io_hasCommitted_2, dq_io_hasCommitted_1, dq_io_hasCommitted_0} = 8'($urandom) & 8'($urandom) & 8'($urandom);
          end
          default: ;
        endcase
        dq_io_blockCommit = ($urandom_range(0, 7) == 0);
        dq_io_allowOnlyOneCommit = ($urandom_range(0, 3) == 0);
        dq_io_intrBitSetReg = ($urandom_range(0, 15) == 0);
        dq_io_exception_state_valid = ($urandom_range(0, 3) == 0);
        if ($urandom_range(0, 1)) begin  // 对准队头，让 exceptionEnable 能成立
          dq_io_exception_state_bits_robIdx_flag = dq_u_gold.deqPtrVec_0_flag;
          dq_io_exception_state_bits_robIdx_value = dq_u_gold.deqPtrVec_0_value;
        end
        dq_io_exception_state_bits_trigger = ($urandom_range(0, 3) == 0) ? 4'd1 : 4'($urandom);
        dq_io_exception_state_bits_hasException = ($urandom_range(0, 3) == 0);
        dq_io_exception_state_bits_replayInst = ($urandom_range(0, 7) == 0);
        dq_io_exception_state_bits_singleStep = ($urandom_range(0, 7) == 0);
      end
      #4;
      cs_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&cs_armed)) begin
        checks++;
        if (cs_g_io_overflow !== cs_i_io_overflow) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d CommitStuckCounter.io_overflow g=%h i=%h", cyc, cs_g_io_overflow, cs_i_io_overflow);
        end
        cs_s1_io_overflow |= cs_g_io_overflow;
        cs_s0_io_overflow |= ~cs_g_io_overflow;
        if (cs_g_io_overflow) cs_cov_overflow++;
        if (cs_u_gold.count > 21'd100) cs_cov_stuck_run++;
      end
      if (cs_armed_at < 0 && (&cs_armed)) cs_armed_at = cyc + 1;
      eq_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&eq_armed)) begin
        checks++;
        if (eq_g_io_out_0_flag !== eq_i_io_out_0_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_0_flag g=%h i=%h", cyc, eq_g_io_out_0_flag, eq_i_io_out_0_flag);
        end
        eq_s1_io_out_0_flag |= eq_g_io_out_0_flag;
        eq_s0_io_out_0_flag |= ~eq_g_io_out_0_flag;
        checks++;
        if (eq_g_io_out_0_value !== eq_i_io_out_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_0_value g=%h i=%h", cyc, eq_g_io_out_0_value, eq_i_io_out_0_value);
        end
        eq_s1_io_out_0_value |= eq_g_io_out_0_value;
        eq_s0_io_out_0_value |= ~eq_g_io_out_0_value;
        checks++;
        if (eq_g_io_out_1_flag !== eq_i_io_out_1_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_1_flag g=%h i=%h", cyc, eq_g_io_out_1_flag, eq_i_io_out_1_flag);
        end
        eq_s1_io_out_1_flag |= eq_g_io_out_1_flag;
        eq_s0_io_out_1_flag |= ~eq_g_io_out_1_flag;
        checks++;
        if (eq_g_io_out_1_value !== eq_i_io_out_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_1_value g=%h i=%h", cyc, eq_g_io_out_1_value, eq_i_io_out_1_value);
        end
        eq_s1_io_out_1_value |= eq_g_io_out_1_value;
        eq_s0_io_out_1_value |= ~eq_g_io_out_1_value;
        checks++;
        if (eq_g_io_out_2_flag !== eq_i_io_out_2_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_2_flag g=%h i=%h", cyc, eq_g_io_out_2_flag, eq_i_io_out_2_flag);
        end
        eq_s1_io_out_2_flag |= eq_g_io_out_2_flag;
        eq_s0_io_out_2_flag |= ~eq_g_io_out_2_flag;
        checks++;
        if (eq_g_io_out_2_value !== eq_i_io_out_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_2_value g=%h i=%h", cyc, eq_g_io_out_2_value, eq_i_io_out_2_value);
        end
        eq_s1_io_out_2_value |= eq_g_io_out_2_value;
        eq_s0_io_out_2_value |= ~eq_g_io_out_2_value;
        checks++;
        if (eq_g_io_out_3_flag !== eq_i_io_out_3_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_3_flag g=%h i=%h", cyc, eq_g_io_out_3_flag, eq_i_io_out_3_flag);
        end
        eq_s1_io_out_3_flag |= eq_g_io_out_3_flag;
        eq_s0_io_out_3_flag |= ~eq_g_io_out_3_flag;
        checks++;
        if (eq_g_io_out_3_value !== eq_i_io_out_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_3_value g=%h i=%h", cyc, eq_g_io_out_3_value, eq_i_io_out_3_value);
        end
        eq_s1_io_out_3_value |= eq_g_io_out_3_value;
        eq_s0_io_out_3_value |= ~eq_g_io_out_3_value;
        checks++;
        if (eq_g_io_out_4_flag !== eq_i_io_out_4_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_4_flag g=%h i=%h", cyc, eq_g_io_out_4_flag, eq_i_io_out_4_flag);
        end
        eq_s1_io_out_4_flag |= eq_g_io_out_4_flag;
        eq_s0_io_out_4_flag |= ~eq_g_io_out_4_flag;
        checks++;
        if (eq_g_io_out_4_value !== eq_i_io_out_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_4_value g=%h i=%h", cyc, eq_g_io_out_4_value, eq_i_io_out_4_value);
        end
        eq_s1_io_out_4_value |= eq_g_io_out_4_value;
        eq_s0_io_out_4_value |= ~eq_g_io_out_4_value;
        checks++;
        if (eq_g_io_out_5_flag !== eq_i_io_out_5_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_5_flag g=%h i=%h", cyc, eq_g_io_out_5_flag, eq_i_io_out_5_flag);
        end
        eq_s1_io_out_5_flag |= eq_g_io_out_5_flag;
        eq_s0_io_out_5_flag |= ~eq_g_io_out_5_flag;
        checks++;
        if (eq_g_io_out_5_value !== eq_i_io_out_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d RobEnqPtrWrapper.io_out_5_value g=%h i=%h", cyc, eq_g_io_out_5_value, eq_i_io_out_5_value);
        end
        eq_s1_io_out_5_value |= eq_g_io_out_5_value;
        eq_s0_io_out_5_value |= ~eq_g_io_out_5_value;
        if (eq_io_redirect_valid && eq_io_redirect_bits_level) eq_cov_redirect_lvl1++;
        if (eq_io_redirect_valid && !eq_io_redirect_bits_level) eq_cov_redirect_lvl0++;
        if (eq_io_redirect_valid && eq_io_redirect_bits_robIdx_value >= 8'd160) eq_cov_redirect_illegal++;
        if (!eq_io_redirect_valid && eq_io_allowEnqueue && !eq_io_hasBlockBackward && ({eq_io_enq_5, eq_io_enq_4, eq_io_enq_3, eq_io_enq_2, eq_io_enq_1, eq_io_enq_0} == 6'h3F)) eq_cov_enq6++;
        if (eq_g_io_out_0_value >= 8'd155) eq_cov_wrap0++;
        if (eq_g_io_out_5_flag) eq_cov_flag5++;
      end
      if (eq_armed_at < 0 && (&eq_armed)) eq_armed_at = cyc + 1;
      dq_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&dq_armed)) begin
        checks++;
        if (dq_g_io_out_0_flag !== dq_i_io_out_0_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_0_flag g=%h i=%h", cyc, dq_g_io_out_0_flag, dq_i_io_out_0_flag);
        end
        dq_s1_io_out_0_flag |= dq_g_io_out_0_flag;
        dq_s0_io_out_0_flag |= ~dq_g_io_out_0_flag;
        checks++;
        if (dq_g_io_out_0_value !== dq_i_io_out_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_0_value g=%h i=%h", cyc, dq_g_io_out_0_value, dq_i_io_out_0_value);
        end
        dq_s1_io_out_0_value |= dq_g_io_out_0_value;
        dq_s0_io_out_0_value |= ~dq_g_io_out_0_value;
        checks++;
        if (dq_g_io_out_1_flag !== dq_i_io_out_1_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_1_flag g=%h i=%h", cyc, dq_g_io_out_1_flag, dq_i_io_out_1_flag);
        end
        dq_s1_io_out_1_flag |= dq_g_io_out_1_flag;
        dq_s0_io_out_1_flag |= ~dq_g_io_out_1_flag;
        checks++;
        if (dq_g_io_out_1_value !== dq_i_io_out_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_1_value g=%h i=%h", cyc, dq_g_io_out_1_value, dq_i_io_out_1_value);
        end
        dq_s1_io_out_1_value |= dq_g_io_out_1_value;
        dq_s0_io_out_1_value |= ~dq_g_io_out_1_value;
        checks++;
        if (dq_g_io_out_2_flag !== dq_i_io_out_2_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_2_flag g=%h i=%h", cyc, dq_g_io_out_2_flag, dq_i_io_out_2_flag);
        end
        dq_s1_io_out_2_flag |= dq_g_io_out_2_flag;
        dq_s0_io_out_2_flag |= ~dq_g_io_out_2_flag;
        checks++;
        if (dq_g_io_out_2_value !== dq_i_io_out_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_2_value g=%h i=%h", cyc, dq_g_io_out_2_value, dq_i_io_out_2_value);
        end
        dq_s1_io_out_2_value |= dq_g_io_out_2_value;
        dq_s0_io_out_2_value |= ~dq_g_io_out_2_value;
        checks++;
        if (dq_g_io_out_3_flag !== dq_i_io_out_3_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_3_flag g=%h i=%h", cyc, dq_g_io_out_3_flag, dq_i_io_out_3_flag);
        end
        dq_s1_io_out_3_flag |= dq_g_io_out_3_flag;
        dq_s0_io_out_3_flag |= ~dq_g_io_out_3_flag;
        checks++;
        if (dq_g_io_out_3_value !== dq_i_io_out_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_3_value g=%h i=%h", cyc, dq_g_io_out_3_value, dq_i_io_out_3_value);
        end
        dq_s1_io_out_3_value |= dq_g_io_out_3_value;
        dq_s0_io_out_3_value |= ~dq_g_io_out_3_value;
        checks++;
        if (dq_g_io_out_4_flag !== dq_i_io_out_4_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_4_flag g=%h i=%h", cyc, dq_g_io_out_4_flag, dq_i_io_out_4_flag);
        end
        dq_s1_io_out_4_flag |= dq_g_io_out_4_flag;
        dq_s0_io_out_4_flag |= ~dq_g_io_out_4_flag;
        checks++;
        if (dq_g_io_out_4_value !== dq_i_io_out_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_4_value g=%h i=%h", cyc, dq_g_io_out_4_value, dq_i_io_out_4_value);
        end
        dq_s1_io_out_4_value |= dq_g_io_out_4_value;
        dq_s0_io_out_4_value |= ~dq_g_io_out_4_value;
        checks++;
        if (dq_g_io_out_5_flag !== dq_i_io_out_5_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_5_flag g=%h i=%h", cyc, dq_g_io_out_5_flag, dq_i_io_out_5_flag);
        end
        dq_s1_io_out_5_flag |= dq_g_io_out_5_flag;
        dq_s0_io_out_5_flag |= ~dq_g_io_out_5_flag;
        checks++;
        if (dq_g_io_out_5_value !== dq_i_io_out_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_5_value g=%h i=%h", cyc, dq_g_io_out_5_value, dq_i_io_out_5_value);
        end
        dq_s1_io_out_5_value |= dq_g_io_out_5_value;
        dq_s0_io_out_5_value |= ~dq_g_io_out_5_value;
        checks++;
        if (dq_g_io_out_6_flag !== dq_i_io_out_6_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_6_flag g=%h i=%h", cyc, dq_g_io_out_6_flag, dq_i_io_out_6_flag);
        end
        dq_s1_io_out_6_flag |= dq_g_io_out_6_flag;
        dq_s0_io_out_6_flag |= ~dq_g_io_out_6_flag;
        checks++;
        if (dq_g_io_out_6_value !== dq_i_io_out_6_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_6_value g=%h i=%h", cyc, dq_g_io_out_6_value, dq_i_io_out_6_value);
        end
        dq_s1_io_out_6_value |= dq_g_io_out_6_value;
        dq_s0_io_out_6_value |= ~dq_g_io_out_6_value;
        checks++;
        if (dq_g_io_out_7_flag !== dq_i_io_out_7_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_7_flag g=%h i=%h", cyc, dq_g_io_out_7_flag, dq_i_io_out_7_flag);
        end
        dq_s1_io_out_7_flag |= dq_g_io_out_7_flag;
        dq_s0_io_out_7_flag |= ~dq_g_io_out_7_flag;
        checks++;
        if (dq_g_io_out_7_value !== dq_i_io_out_7_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_out_7_value g=%h i=%h", cyc, dq_g_io_out_7_value, dq_i_io_out_7_value);
        end
        dq_s1_io_out_7_value |= dq_g_io_out_7_value;
        dq_s0_io_out_7_value |= ~dq_g_io_out_7_value;
        checks++;
        if (dq_g_io_next_out_0_flag !== dq_i_io_next_out_0_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_0_flag g=%h i=%h", cyc, dq_g_io_next_out_0_flag, dq_i_io_next_out_0_flag);
        end
        dq_s1_io_next_out_0_flag |= dq_g_io_next_out_0_flag;
        dq_s0_io_next_out_0_flag |= ~dq_g_io_next_out_0_flag;
        checks++;
        if (dq_g_io_next_out_0_value !== dq_i_io_next_out_0_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_0_value g=%h i=%h", cyc, dq_g_io_next_out_0_value, dq_i_io_next_out_0_value);
        end
        dq_s1_io_next_out_0_value |= dq_g_io_next_out_0_value;
        dq_s0_io_next_out_0_value |= ~dq_g_io_next_out_0_value;
        checks++;
        if (dq_g_io_next_out_1_flag !== dq_i_io_next_out_1_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_1_flag g=%h i=%h", cyc, dq_g_io_next_out_1_flag, dq_i_io_next_out_1_flag);
        end
        dq_s1_io_next_out_1_flag |= dq_g_io_next_out_1_flag;
        dq_s0_io_next_out_1_flag |= ~dq_g_io_next_out_1_flag;
        checks++;
        if (dq_g_io_next_out_1_value !== dq_i_io_next_out_1_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_1_value g=%h i=%h", cyc, dq_g_io_next_out_1_value, dq_i_io_next_out_1_value);
        end
        dq_s1_io_next_out_1_value |= dq_g_io_next_out_1_value;
        dq_s0_io_next_out_1_value |= ~dq_g_io_next_out_1_value;
        checks++;
        if (dq_g_io_next_out_2_flag !== dq_i_io_next_out_2_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_2_flag g=%h i=%h", cyc, dq_g_io_next_out_2_flag, dq_i_io_next_out_2_flag);
        end
        dq_s1_io_next_out_2_flag |= dq_g_io_next_out_2_flag;
        dq_s0_io_next_out_2_flag |= ~dq_g_io_next_out_2_flag;
        checks++;
        if (dq_g_io_next_out_2_value !== dq_i_io_next_out_2_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_2_value g=%h i=%h", cyc, dq_g_io_next_out_2_value, dq_i_io_next_out_2_value);
        end
        dq_s1_io_next_out_2_value |= dq_g_io_next_out_2_value;
        dq_s0_io_next_out_2_value |= ~dq_g_io_next_out_2_value;
        checks++;
        if (dq_g_io_next_out_3_flag !== dq_i_io_next_out_3_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_3_flag g=%h i=%h", cyc, dq_g_io_next_out_3_flag, dq_i_io_next_out_3_flag);
        end
        dq_s1_io_next_out_3_flag |= dq_g_io_next_out_3_flag;
        dq_s0_io_next_out_3_flag |= ~dq_g_io_next_out_3_flag;
        checks++;
        if (dq_g_io_next_out_3_value !== dq_i_io_next_out_3_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_3_value g=%h i=%h", cyc, dq_g_io_next_out_3_value, dq_i_io_next_out_3_value);
        end
        dq_s1_io_next_out_3_value |= dq_g_io_next_out_3_value;
        dq_s0_io_next_out_3_value |= ~dq_g_io_next_out_3_value;
        checks++;
        if (dq_g_io_next_out_4_flag !== dq_i_io_next_out_4_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_4_flag g=%h i=%h", cyc, dq_g_io_next_out_4_flag, dq_i_io_next_out_4_flag);
        end
        dq_s1_io_next_out_4_flag |= dq_g_io_next_out_4_flag;
        dq_s0_io_next_out_4_flag |= ~dq_g_io_next_out_4_flag;
        checks++;
        if (dq_g_io_next_out_4_value !== dq_i_io_next_out_4_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_4_value g=%h i=%h", cyc, dq_g_io_next_out_4_value, dq_i_io_next_out_4_value);
        end
        dq_s1_io_next_out_4_value |= dq_g_io_next_out_4_value;
        dq_s0_io_next_out_4_value |= ~dq_g_io_next_out_4_value;
        checks++;
        if (dq_g_io_next_out_5_flag !== dq_i_io_next_out_5_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_5_flag g=%h i=%h", cyc, dq_g_io_next_out_5_flag, dq_i_io_next_out_5_flag);
        end
        dq_s1_io_next_out_5_flag |= dq_g_io_next_out_5_flag;
        dq_s0_io_next_out_5_flag |= ~dq_g_io_next_out_5_flag;
        checks++;
        if (dq_g_io_next_out_5_value !== dq_i_io_next_out_5_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_5_value g=%h i=%h", cyc, dq_g_io_next_out_5_value, dq_i_io_next_out_5_value);
        end
        dq_s1_io_next_out_5_value |= dq_g_io_next_out_5_value;
        dq_s0_io_next_out_5_value |= ~dq_g_io_next_out_5_value;
        checks++;
        if (dq_g_io_next_out_6_flag !== dq_i_io_next_out_6_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_6_flag g=%h i=%h", cyc, dq_g_io_next_out_6_flag, dq_i_io_next_out_6_flag);
        end
        dq_s1_io_next_out_6_flag |= dq_g_io_next_out_6_flag;
        dq_s0_io_next_out_6_flag |= ~dq_g_io_next_out_6_flag;
        checks++;
        if (dq_g_io_next_out_6_value !== dq_i_io_next_out_6_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_6_value g=%h i=%h", cyc, dq_g_io_next_out_6_value, dq_i_io_next_out_6_value);
        end
        dq_s1_io_next_out_6_value |= dq_g_io_next_out_6_value;
        dq_s0_io_next_out_6_value |= ~dq_g_io_next_out_6_value;
        checks++;
        if (dq_g_io_next_out_7_flag !== dq_i_io_next_out_7_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_7_flag g=%h i=%h", cyc, dq_g_io_next_out_7_flag, dq_i_io_next_out_7_flag);
        end
        dq_s1_io_next_out_7_flag |= dq_g_io_next_out_7_flag;
        dq_s0_io_next_out_7_flag |= ~dq_g_io_next_out_7_flag;
        checks++;
        if (dq_g_io_next_out_7_value !== dq_i_io_next_out_7_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_next_out_7_value g=%h i=%h", cyc, dq_g_io_next_out_7_value, dq_i_io_next_out_7_value);
        end
        dq_s1_io_next_out_7_value |= dq_g_io_next_out_7_value;
        dq_s0_io_next_out_7_value |= ~dq_g_io_next_out_7_value;
        checks++;
        if (dq_g_io_canCommitPriorityCond_0 !== dq_i_io_canCommitPriorityCond_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_0 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_0, dq_i_io_canCommitPriorityCond_0);
        end
        dq_s1_io_canCommitPriorityCond_0 |= dq_g_io_canCommitPriorityCond_0;
        dq_s0_io_canCommitPriorityCond_0 |= ~dq_g_io_canCommitPriorityCond_0;
        checks++;
        if (dq_g_io_canCommitPriorityCond_1 !== dq_i_io_canCommitPriorityCond_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_1 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_1, dq_i_io_canCommitPriorityCond_1);
        end
        dq_s1_io_canCommitPriorityCond_1 |= dq_g_io_canCommitPriorityCond_1;
        dq_s0_io_canCommitPriorityCond_1 |= ~dq_g_io_canCommitPriorityCond_1;
        checks++;
        if (dq_g_io_canCommitPriorityCond_2 !== dq_i_io_canCommitPriorityCond_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_2 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_2, dq_i_io_canCommitPriorityCond_2);
        end
        dq_s1_io_canCommitPriorityCond_2 |= dq_g_io_canCommitPriorityCond_2;
        dq_s0_io_canCommitPriorityCond_2 |= ~dq_g_io_canCommitPriorityCond_2;
        checks++;
        if (dq_g_io_canCommitPriorityCond_3 !== dq_i_io_canCommitPriorityCond_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_3 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_3, dq_i_io_canCommitPriorityCond_3);
        end
        dq_s1_io_canCommitPriorityCond_3 |= dq_g_io_canCommitPriorityCond_3;
        dq_s0_io_canCommitPriorityCond_3 |= ~dq_g_io_canCommitPriorityCond_3;
        checks++;
        if (dq_g_io_canCommitPriorityCond_4 !== dq_i_io_canCommitPriorityCond_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_4 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_4, dq_i_io_canCommitPriorityCond_4);
        end
        dq_s1_io_canCommitPriorityCond_4 |= dq_g_io_canCommitPriorityCond_4;
        dq_s0_io_canCommitPriorityCond_4 |= ~dq_g_io_canCommitPriorityCond_4;
        checks++;
        if (dq_g_io_canCommitPriorityCond_5 !== dq_i_io_canCommitPriorityCond_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_5 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_5, dq_i_io_canCommitPriorityCond_5);
        end
        dq_s1_io_canCommitPriorityCond_5 |= dq_g_io_canCommitPriorityCond_5;
        dq_s0_io_canCommitPriorityCond_5 |= ~dq_g_io_canCommitPriorityCond_5;
        checks++;
        if (dq_g_io_canCommitPriorityCond_6 !== dq_i_io_canCommitPriorityCond_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_6 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_6, dq_i_io_canCommitPriorityCond_6);
        end
        dq_s1_io_canCommitPriorityCond_6 |= dq_g_io_canCommitPriorityCond_6;
        dq_s0_io_canCommitPriorityCond_6 |= ~dq_g_io_canCommitPriorityCond_6;
        checks++;
        if (dq_g_io_canCommitPriorityCond_7 !== dq_i_io_canCommitPriorityCond_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_7 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_7, dq_i_io_canCommitPriorityCond_7);
        end
        dq_s1_io_canCommitPriorityCond_7 |= dq_g_io_canCommitPriorityCond_7;
        dq_s0_io_canCommitPriorityCond_7 |= ~dq_g_io_canCommitPriorityCond_7;
        checks++;
        if (dq_g_io_canCommitPriorityCond_8 !== dq_i_io_canCommitPriorityCond_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d NewRobDeqPtrWrapper.io_canCommitPriorityCond_8 g=%h i=%h", cyc, dq_g_io_canCommitPriorityCond_8, dq_i_io_canCommitPriorityCond_8);
        end
        dq_s1_io_canCommitPriorityCond_8 |= dq_g_io_canCommitPriorityCond_8;
        dq_s0_io_canCommitPriorityCond_8 |= ~dq_g_io_canCommitPriorityCond_8;
        if (dq_u_gold.redirectOutValid) dq_cov_redirect_out++;
        if (dq_u_gold._deqPtrVec_next_T_4) dq_cov_commit_en++;
        if (dq_io_allowOnlyOneCommit && dq_u_gold._deqPtrVec_next_T_4) dq_cov_only_one++;
        if (!dq_io_allowOnlyOneCommit && dq_u_gold._deqPtrVec_next_T_4 && dq_g_io_canCommitPriorityCond_8 && !dq_g_io_canCommitPriorityCond_0 && !dq_g_io_canCommitPriorityCond_7) dq_cov_full_line++;
        if (dq_g_io_next_out_7_flag != dq_g_io_out_7_flag) dq_cov_wrap++;
        if (dq_u_gold.redirectOutValid && dq_io_exception_state_bits_trigger == 4'd1) dq_cov_trigger_dbg++;
      end
      if (dq_armed_at < 0 && (&dq_armed)) dq_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(cs_s0_io_overflow && cs_s1_io_overflow)) begin cov_fail++; $display("[COV] CommitStuckCounter.io_overflow 未见过 0 和 1"); end
    $display("[ARM] CommitStuckCounter armed_at=%0d", cs_armed_at);
    if (cs_armed_at < 0) begin cov_fail++; $display("[ARM] CommitStuckCounter 从未 arm"); end
    $display("[COV] CommitStuckCounter.overflow = %0d", cs_cov_overflow);
    if (cs_cov_overflow < 40) begin cov_fail++; $display("[COV] CommitStuckCounter.overflow < 40"); end
    $display("[COV] CommitStuckCounter.stuck_run = %0d", cs_cov_stuck_run);
    if (cs_cov_stuck_run < 40) begin cov_fail++; $display("[COV] CommitStuckCounter.stuck_run < 40"); end
    if (!(eq_s0_io_out_0_flag && eq_s1_io_out_0_flag)) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_flag 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[0] && eq_s1_io_out_0_value[0])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[0] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[1] && eq_s1_io_out_0_value[1])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[1] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[2] && eq_s1_io_out_0_value[2])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[2] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[3] && eq_s1_io_out_0_value[3])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[3] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[4] && eq_s1_io_out_0_value[4])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[4] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[5] && eq_s1_io_out_0_value[5])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[5] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[6] && eq_s1_io_out_0_value[6])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[6] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_0_value[7] && eq_s1_io_out_0_value[7])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_0_value[7] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_flag && eq_s1_io_out_1_flag)) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_flag 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[0] && eq_s1_io_out_1_value[0])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[0] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[1] && eq_s1_io_out_1_value[1])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[1] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[2] && eq_s1_io_out_1_value[2])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[2] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[3] && eq_s1_io_out_1_value[3])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[3] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[4] && eq_s1_io_out_1_value[4])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[4] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[5] && eq_s1_io_out_1_value[5])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[5] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[6] && eq_s1_io_out_1_value[6])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[6] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_1_value[7] && eq_s1_io_out_1_value[7])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_1_value[7] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_flag && eq_s1_io_out_2_flag)) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_flag 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[0] && eq_s1_io_out_2_value[0])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[0] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[1] && eq_s1_io_out_2_value[1])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[1] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[2] && eq_s1_io_out_2_value[2])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[2] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[3] && eq_s1_io_out_2_value[3])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[3] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[4] && eq_s1_io_out_2_value[4])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[4] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[5] && eq_s1_io_out_2_value[5])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[5] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[6] && eq_s1_io_out_2_value[6])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[6] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_2_value[7] && eq_s1_io_out_2_value[7])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_2_value[7] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_flag && eq_s1_io_out_3_flag)) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_flag 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[0] && eq_s1_io_out_3_value[0])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[0] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[1] && eq_s1_io_out_3_value[1])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[1] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[2] && eq_s1_io_out_3_value[2])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[2] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[3] && eq_s1_io_out_3_value[3])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[3] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[4] && eq_s1_io_out_3_value[4])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[4] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[5] && eq_s1_io_out_3_value[5])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[5] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[6] && eq_s1_io_out_3_value[6])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[6] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_3_value[7] && eq_s1_io_out_3_value[7])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_3_value[7] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_flag && eq_s1_io_out_4_flag)) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_flag 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[0] && eq_s1_io_out_4_value[0])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[0] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[1] && eq_s1_io_out_4_value[1])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[1] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[2] && eq_s1_io_out_4_value[2])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[2] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[3] && eq_s1_io_out_4_value[3])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[3] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[4] && eq_s1_io_out_4_value[4])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[4] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[5] && eq_s1_io_out_4_value[5])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[5] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[6] && eq_s1_io_out_4_value[6])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[6] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_4_value[7] && eq_s1_io_out_4_value[7])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_4_value[7] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_flag && eq_s1_io_out_5_flag)) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_flag 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[0] && eq_s1_io_out_5_value[0])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[0] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[1] && eq_s1_io_out_5_value[1])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[1] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[2] && eq_s1_io_out_5_value[2])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[2] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[3] && eq_s1_io_out_5_value[3])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[3] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[4] && eq_s1_io_out_5_value[4])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[4] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[5] && eq_s1_io_out_5_value[5])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[5] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[6] && eq_s1_io_out_5_value[6])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[6] 未见过 0 和 1"); end
    if (!(eq_s0_io_out_5_value[7] && eq_s1_io_out_5_value[7])) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.io_out_5_value[7] 未见过 0 和 1"); end
    $display("[ARM] RobEnqPtrWrapper armed_at=%0d", eq_armed_at);
    if (eq_armed_at < 0) begin cov_fail++; $display("[ARM] RobEnqPtrWrapper 从未 arm"); end
    $display("[COV] RobEnqPtrWrapper.redirect_lvl1 = %0d", eq_cov_redirect_lvl1);
    if (eq_cov_redirect_lvl1 < 100) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.redirect_lvl1 < 100"); end
    $display("[COV] RobEnqPtrWrapper.redirect_lvl0 = %0d", eq_cov_redirect_lvl0);
    if (eq_cov_redirect_lvl0 < 100) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.redirect_lvl0 < 100"); end
    $display("[COV] RobEnqPtrWrapper.redirect_illegal = %0d", eq_cov_redirect_illegal);
    if (eq_cov_redirect_illegal < 100) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.redirect_illegal < 100"); end
    $display("[COV] RobEnqPtrWrapper.enq6 = %0d", eq_cov_enq6);
    if (eq_cov_enq6 < 100) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.enq6 < 100"); end
    $display("[COV] RobEnqPtrWrapper.wrap0 = %0d", eq_cov_wrap0);
    if (eq_cov_wrap0 < 100) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.wrap0 < 100"); end
    $display("[COV] RobEnqPtrWrapper.flag5 = %0d", eq_cov_flag5);
    if (eq_cov_flag5 < 100) begin cov_fail++; $display("[COV] RobEnqPtrWrapper.flag5 < 100"); end
    if (!(dq_s0_io_out_0_flag && dq_s1_io_out_0_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[0] && dq_s1_io_out_0_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[1] && dq_s1_io_out_0_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[2] && dq_s1_io_out_0_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[3] && dq_s1_io_out_0_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[4] && dq_s1_io_out_0_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[5] && dq_s1_io_out_0_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[6] && dq_s1_io_out_0_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_0_value[7] && dq_s1_io_out_0_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_0_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_flag && dq_s1_io_out_1_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[0] && dq_s1_io_out_1_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[1] && dq_s1_io_out_1_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[2] && dq_s1_io_out_1_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[3] && dq_s1_io_out_1_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[4] && dq_s1_io_out_1_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[5] && dq_s1_io_out_1_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[6] && dq_s1_io_out_1_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_1_value[7] && dq_s1_io_out_1_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_1_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_flag && dq_s1_io_out_2_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[0] && dq_s1_io_out_2_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[1] && dq_s1_io_out_2_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[2] && dq_s1_io_out_2_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[3] && dq_s1_io_out_2_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[4] && dq_s1_io_out_2_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[5] && dq_s1_io_out_2_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[6] && dq_s1_io_out_2_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_2_value[7] && dq_s1_io_out_2_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_2_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_flag && dq_s1_io_out_3_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[0] && dq_s1_io_out_3_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[1] && dq_s1_io_out_3_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[2] && dq_s1_io_out_3_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[3] && dq_s1_io_out_3_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[4] && dq_s1_io_out_3_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[5] && dq_s1_io_out_3_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[6] && dq_s1_io_out_3_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_3_value[7] && dq_s1_io_out_3_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_3_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_flag && dq_s1_io_out_4_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[0] && dq_s1_io_out_4_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[1] && dq_s1_io_out_4_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[2] && dq_s1_io_out_4_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[3] && dq_s1_io_out_4_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[4] && dq_s1_io_out_4_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[5] && dq_s1_io_out_4_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[6] && dq_s1_io_out_4_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_4_value[7] && dq_s1_io_out_4_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_4_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_flag && dq_s1_io_out_5_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[0] && dq_s1_io_out_5_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[1] && dq_s1_io_out_5_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[2] && dq_s1_io_out_5_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[3] && dq_s1_io_out_5_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[4] && dq_s1_io_out_5_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[5] && dq_s1_io_out_5_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[6] && dq_s1_io_out_5_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_5_value[7] && dq_s1_io_out_5_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_5_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_flag && dq_s1_io_out_6_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[0] && dq_s1_io_out_6_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[1] && dq_s1_io_out_6_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[2] && dq_s1_io_out_6_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[3] && dq_s1_io_out_6_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[4] && dq_s1_io_out_6_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[5] && dq_s1_io_out_6_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[6] && dq_s1_io_out_6_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_6_value[7] && dq_s1_io_out_6_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_6_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_flag && dq_s1_io_out_7_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[0] && dq_s1_io_out_7_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[1] && dq_s1_io_out_7_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[2] && dq_s1_io_out_7_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[3] && dq_s1_io_out_7_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[4] && dq_s1_io_out_7_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[5] && dq_s1_io_out_7_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[6] && dq_s1_io_out_7_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_out_7_value[7] && dq_s1_io_out_7_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_out_7_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_flag && dq_s1_io_next_out_0_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[0] && dq_s1_io_next_out_0_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[1] && dq_s1_io_next_out_0_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[2] && dq_s1_io_next_out_0_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[3] && dq_s1_io_next_out_0_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[4] && dq_s1_io_next_out_0_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[5] && dq_s1_io_next_out_0_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[6] && dq_s1_io_next_out_0_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_0_value[7] && dq_s1_io_next_out_0_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_0_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_flag && dq_s1_io_next_out_1_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[0] && dq_s1_io_next_out_1_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[1] && dq_s1_io_next_out_1_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[2] && dq_s1_io_next_out_1_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[3] && dq_s1_io_next_out_1_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[4] && dq_s1_io_next_out_1_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[5] && dq_s1_io_next_out_1_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[6] && dq_s1_io_next_out_1_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_1_value[7] && dq_s1_io_next_out_1_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_1_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_flag && dq_s1_io_next_out_2_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[0] && dq_s1_io_next_out_2_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[1] && dq_s1_io_next_out_2_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[2] && dq_s1_io_next_out_2_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[3] && dq_s1_io_next_out_2_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[4] && dq_s1_io_next_out_2_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[5] && dq_s1_io_next_out_2_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[6] && dq_s1_io_next_out_2_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_2_value[7] && dq_s1_io_next_out_2_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_2_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_flag && dq_s1_io_next_out_3_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[0] && dq_s1_io_next_out_3_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[1] && dq_s1_io_next_out_3_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[2] && dq_s1_io_next_out_3_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[3] && dq_s1_io_next_out_3_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[4] && dq_s1_io_next_out_3_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[5] && dq_s1_io_next_out_3_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[6] && dq_s1_io_next_out_3_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_3_value[7] && dq_s1_io_next_out_3_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_3_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_flag && dq_s1_io_next_out_4_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[0] && dq_s1_io_next_out_4_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[1] && dq_s1_io_next_out_4_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[2] && dq_s1_io_next_out_4_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[3] && dq_s1_io_next_out_4_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[4] && dq_s1_io_next_out_4_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[5] && dq_s1_io_next_out_4_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[6] && dq_s1_io_next_out_4_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_4_value[7] && dq_s1_io_next_out_4_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_4_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_flag && dq_s1_io_next_out_5_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[0] && dq_s1_io_next_out_5_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[1] && dq_s1_io_next_out_5_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[2] && dq_s1_io_next_out_5_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[3] && dq_s1_io_next_out_5_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[4] && dq_s1_io_next_out_5_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[5] && dq_s1_io_next_out_5_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[6] && dq_s1_io_next_out_5_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_5_value[7] && dq_s1_io_next_out_5_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_5_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_flag && dq_s1_io_next_out_6_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[0] && dq_s1_io_next_out_6_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[1] && dq_s1_io_next_out_6_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[2] && dq_s1_io_next_out_6_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[3] && dq_s1_io_next_out_6_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[4] && dq_s1_io_next_out_6_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[5] && dq_s1_io_next_out_6_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[6] && dq_s1_io_next_out_6_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_6_value[7] && dq_s1_io_next_out_6_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_6_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_flag && dq_s1_io_next_out_7_flag)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_flag 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[0] && dq_s1_io_next_out_7_value[0])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[0] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[1] && dq_s1_io_next_out_7_value[1])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[1] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[2] && dq_s1_io_next_out_7_value[2])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[2] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[3] && dq_s1_io_next_out_7_value[3])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[3] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[4] && dq_s1_io_next_out_7_value[4])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[4] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[5] && dq_s1_io_next_out_7_value[5])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[5] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[6] && dq_s1_io_next_out_7_value[6])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[6] 未见过 0 和 1"); end
    if (!(dq_s0_io_next_out_7_value[7] && dq_s1_io_next_out_7_value[7])) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_next_out_7_value[7] 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_0 && dq_s1_io_canCommitPriorityCond_0)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_0 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_1 && dq_s1_io_canCommitPriorityCond_1)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_1 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_2 && dq_s1_io_canCommitPriorityCond_2)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_2 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_3 && dq_s1_io_canCommitPriorityCond_3)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_3 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_4 && dq_s1_io_canCommitPriorityCond_4)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_4 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_5 && dq_s1_io_canCommitPriorityCond_5)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_5 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_6 && dq_s1_io_canCommitPriorityCond_6)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_6 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_7 && dq_s1_io_canCommitPriorityCond_7)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_7 未见过 0 和 1"); end
    if (!(dq_s0_io_canCommitPriorityCond_8 && dq_s1_io_canCommitPriorityCond_8)) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.io_canCommitPriorityCond_8 未见过 0 和 1"); end
    $display("[ARM] NewRobDeqPtrWrapper armed_at=%0d", dq_armed_at);
    if (dq_armed_at < 0) begin cov_fail++; $display("[ARM] NewRobDeqPtrWrapper 从未 arm"); end
    $display("[COV] NewRobDeqPtrWrapper.redirect_out = %0d", dq_cov_redirect_out);
    if (dq_cov_redirect_out < 100) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.redirect_out < 100"); end
    $display("[COV] NewRobDeqPtrWrapper.commit_en = %0d", dq_cov_commit_en);
    if (dq_cov_commit_en < 100) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.commit_en < 100"); end
    $display("[COV] NewRobDeqPtrWrapper.only_one = %0d", dq_cov_only_one);
    if (dq_cov_only_one < 100) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.only_one < 100"); end
    $display("[COV] NewRobDeqPtrWrapper.full_line = %0d", dq_cov_full_line);
    if (dq_cov_full_line < 100) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.full_line < 100"); end
    $display("[COV] NewRobDeqPtrWrapper.wrap = %0d", dq_cov_wrap);
    if (dq_cov_wrap < 100) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.wrap < 100"); end
    $display("[COV] NewRobDeqPtrWrapper.trigger_dbg = %0d", dq_cov_trigger_dbg);
    if (dq_cov_trigger_dbg < 100) begin cov_fail++; $display("[COV] NewRobDeqPtrWrapper.trigger_dbg < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
