// =============================================================================
// NewRobDeqPtrWrapper —— ROB 出队（提交）指针组（Rob 的子模块）
//
// 设计源：src/main/scala/xiangshan/backend/rob/RobDeqPtrWrapper.scala（class NewRobDeqPtrWrapper）。
//
// 机制：ROB 160 项环形队列按 8 项一行（CommitWidth=8，bank）组织，本模块保存 8 个提交指针
//   deqPtrVec[i]（复位为 i）。每拍：
//   §1 冲刷判定 redirectOutValid：state==idle 且队头 deqPtrVec[0] 所在列 deq_v 有效，并且
//      （中断可接收：intrBitSetReg && !hasNoSpecExec && interrupt_safe）
//      或（队头已写回 deq_w、exception_state 有效、它就是队头那条、且属于"不提交"异常：
//        hasException / singleStep / replayInst / trigger==1(进 debug 模式)）。
//   §2 能提交向量 canCommit[i] = (deq_v[i] && deq_w[i]) || hasCommitted[i]
//      （注意按"列号 i"索引，不是按"距队头第 i 条"——ROB 提交以整行为单位）。
//   §3 优先条件 canCommitPriorityCond[0..8]（也直接输出给 Rob）：
//        allowOnlyOneCommit=0：cond[i] = !canCommit[i]（i<8），cond[8] = 1
//            ⇒ 第一个"不能提交"的列号 k 决定本行提交到第 k 列；
//        allowOnlyOneCommit=1：cond[0] = 0，cond[i] = (deqPosition==i-1) && canCommit[deqPosition]
//            ⇒ 只放行队头那一条（若它能提交）。
//   §4 候选新指针：lineHead = {flag, value[7:3], 3'b000}（队头所在行首），
//        commitDeqPtrAll[j] = lineHead + j（j = 0..15）；
//        新 deqPtrVec[i] = 第一个为真的 cond[k] 对应的 commitDeqPtrAll[i+k]，全不真则保持。
//   §5 commitEn = state==idle && !redirectOutValid && !blockCommit 时更新为新指针，
//      next_out 输出这一拍末的值（组合），out 输出寄存器当前值。
// 复位：deqPtrVec[i] 异步复位为 {flag=0, value=i}。
//
// golden 常量折叠：commitCnt / commitEn 输出与 allCommitted 输入在 G1 配置下无读者，已裁掉。
// 怪癖：非 2 的幂环形加法对 value ≥ 160 的非法值也照 golden 同式计算（不假设合法）。
// =============================================================================
module xs_NewRobDeqPtrWrapper_core #(
  parameter int COMMIT_WIDTH = 8,
  parameter int ROB_SIZE     = 160
) (
  input  logic                    clock,
  input  logic                    reset,
  input  logic [1:0]              state,
  input  logic [COMMIT_WIDTH-1:0] deq_v,
  input  logic [COMMIT_WIDTH-1:0] deq_w,
  input  logic [COMMIT_WIDTH-1:0] has_committed,
  input  logic                    exc_valid,
  input  logic                    exc_flag,
  input  logic [7:0]              exc_value,
  input  logic                    exc_has_exception,
  input  logic                    exc_replay_inst,
  input  logic                    exc_single_step,
  input  logic [3:0]              exc_trigger,
  input  logic                    intr_bit_set,
  input  logic                    allow_only_one_commit,
  input  logic                    has_no_spec_exec,
  input  logic                    interrupt_safe,
  input  logic                    block_commit,
  output logic [COMMIT_WIDTH-1:0] out_flag,
  output logic [7:0]              out_value [COMMIT_WIDTH],
  output logic [COMMIT_WIDTH-1:0] next_flag,
  output logic [7:0]              next_value [COMMIT_WIDTH],
  output logic [COMMIT_WIDTH:0]   priority_cond
);

  // 环形指针加法（CircularQueuePtr.+，非 2 的幂分支），见 RobEnqPtrWrapper 同名函数。
  function automatic logic [8:0] rob_ptr_add(input logic       flag,
                                             input logic [7:0] value,
                                             input logic [8:0] inc);
    logic [8:0] sum;
    logic       wrap;
    sum  = {1'b0, value} + inc;
    wrap = (sum >= 9'(ROB_SIZE));
    return wrap ? {~flag, 8'(sum - 9'(ROB_SIZE))} : {flag, sum[7:0]};
  endfunction

  logic       deqPtrVec_flag  [COMMIT_WIDTH];
  logic [7:0] deqPtrVec_value [COMMIT_WIDTH];

  // 队头在本行内的列号（bank 号）
  logic [2:0] deq_position;
  assign deq_position = deqPtrVec_value[0][2:0];

  // ---------------------------------------------------------------------------
  // §1 冲刷判定：队头那一条要么接中断、要么带"不提交"异常 ⇒ 本拍不前移指针
  // ---------------------------------------------------------------------------
  logic state_idle;
  logic intr_enable;
  logic exc_not_commit;
  logic exception_enable;
  logic redirect_out_valid;
  assign state_idle       = (state == 2'd0);
  assign intr_enable      = intr_bit_set & ~has_no_spec_exec & interrupt_safe;
  assign exc_not_commit   = exc_has_exception | exc_single_step | exc_replay_inst
                          | (exc_trigger == 4'd1);
  assign exception_enable = deq_w[deq_position] & exc_valid & exc_not_commit
                          & ({exc_flag, exc_value} == {deqPtrVec_flag[0], deqPtrVec_value[0]});
  assign redirect_out_valid = state_idle & deq_v[deq_position]
                            & (intr_enable | exception_enable);

  // ---------------------------------------------------------------------------
  // §2 / §3 能提交向量与优先条件
  // ---------------------------------------------------------------------------
  logic [COMMIT_WIDTH-1:0] can_commit;
  logic [COMMIT_WIDTH:0]   only_one_cond;
  assign can_commit = (deq_v & deq_w) | has_committed;

  always_comb begin
    only_one_cond[0] = 1'b0;
    for (int i = 1; i <= COMMIT_WIDTH; i++)
      only_one_cond[i] = (deq_position == 3'(i - 1)) & can_commit[deq_position];
  end

  assign priority_cond = allow_only_one_commit ? only_one_cond : {1'b1, ~can_commit};

  // ---------------------------------------------------------------------------
  // §4 候选新指针：行首 + j（j = 0 .. 2*COMMIT_WIDTH-1），按优先条件取
  // ---------------------------------------------------------------------------
  logic [8:0] commit_ptr_all [2*COMMIT_WIDTH];   // {flag, value}
  for (genvar j = 0; j < 2*COMMIT_WIDTH; j++) begin : g_all
    assign commit_ptr_all[j] = rob_ptr_add(deqPtrVec_flag[0],
                                           {deqPtrVec_value[0][7:3], 3'b000}, 9'(j));
  end

  logic [8:0] commit_ptr [COMMIT_WIDTH];         // {flag, value}
  always_comb begin
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      commit_ptr[i] = {deqPtrVec_flag[i], deqPtrVec_value[i]};   // 全不真：保持
      for (int k = COMMIT_WIDTH; k >= 0; k--)                    // 从低到高的优先：k 小者胜
        if (priority_cond[k]) commit_ptr[i] = commit_ptr_all[i + k];
    end
  end

  // ---------------------------------------------------------------------------
  // §5 提交使能与指针寄存器
  // ---------------------------------------------------------------------------
  logic commit_en;
  assign commit_en = state_idle & ~redirect_out_valid & ~block_commit;

  for (genvar i = 0; i < COMMIT_WIDTH; i++) begin : g_ptr
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        deqPtrVec_flag[i]  <= 1'b0;
        deqPtrVec_value[i] <= 8'(i);
      end else if (commit_en) begin
        {deqPtrVec_flag[i], deqPtrVec_value[i]} <= commit_ptr[i];
      end
    end

    assign out_flag[i]   = deqPtrVec_flag[i];
    assign out_value[i]  = deqPtrVec_value[i];
    assign next_flag[i]  = commit_en ? commit_ptr[i][8]   : deqPtrVec_flag[i];
    assign next_value[i] = commit_en ? commit_ptr[i][7:0] : deqPtrVec_value[i];
  end

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden NewRobDeqPtrWrapper.sv 逐位一致
// ---------------------------------------------------------------------------
module NewRobDeqPtrWrapper (
  input        clock,
  input        reset,
  input  [1:0] io_state,
  input        io_deq_v_0,
  input        io_deq_v_1,
  input        io_deq_v_2,
  input        io_deq_v_3,
  input        io_deq_v_4,
  input        io_deq_v_5,
  input        io_deq_v_6,
  input        io_deq_v_7,
  input        io_deq_w_0,
  input        io_deq_w_1,
  input        io_deq_w_2,
  input        io_deq_w_3,
  input        io_deq_w_4,
  input        io_deq_w_5,
  input        io_deq_w_6,
  input        io_deq_w_7,
  input        io_hasCommitted_0,
  input        io_hasCommitted_1,
  input        io_hasCommitted_2,
  input        io_hasCommitted_3,
  input        io_hasCommitted_4,
  input        io_hasCommitted_5,
  input        io_hasCommitted_6,
  input        io_hasCommitted_7,
  input        io_exception_state_valid,
  input        io_exception_state_bits_robIdx_flag,
  input  [7:0] io_exception_state_bits_robIdx_value,
  input        io_exception_state_bits_hasException,
  input        io_exception_state_bits_replayInst,
  input        io_exception_state_bits_singleStep,
  input  [3:0] io_exception_state_bits_trigger,
  input        io_intrBitSetReg,
  input        io_allowOnlyOneCommit,
  input        io_hasNoSpecExec,
  input        io_interrupt_safe,
  input        io_blockCommit,
  output       io_out_0_flag,
  output [7:0] io_out_0_value,
  output       io_out_1_flag,
  output [7:0] io_out_1_value,
  output       io_out_2_flag,
  output [7:0] io_out_2_value,
  output       io_out_3_flag,
  output [7:0] io_out_3_value,
  output       io_out_4_flag,
  output [7:0] io_out_4_value,
  output       io_out_5_flag,
  output [7:0] io_out_5_value,
  output       io_out_6_flag,
  output [7:0] io_out_6_value,
  output       io_out_7_flag,
  output [7:0] io_out_7_value,
  output       io_next_out_0_flag,
  output [7:0] io_next_out_0_value,
  output       io_next_out_1_flag,
  output [7:0] io_next_out_1_value,
  output       io_next_out_2_flag,
  output [7:0] io_next_out_2_value,
  output       io_next_out_3_flag,
  output [7:0] io_next_out_3_value,
  output       io_next_out_4_flag,
  output [7:0] io_next_out_4_value,
  output       io_next_out_5_flag,
  output [7:0] io_next_out_5_value,
  output       io_next_out_6_flag,
  output [7:0] io_next_out_6_value,
  output       io_next_out_7_flag,
  output [7:0] io_next_out_7_value,
  output       io_canCommitPriorityCond_0,
  output       io_canCommitPriorityCond_1,
  output       io_canCommitPriorityCond_2,
  output       io_canCommitPriorityCond_3,
  output       io_canCommitPriorityCond_4,
  output       io_canCommitPriorityCond_5,
  output       io_canCommitPriorityCond_6,
  output       io_canCommitPriorityCond_7,
  output       io_canCommitPriorityCond_8
);

  logic [7:0] out_flag;
  logic [7:0] out_value [8];
  logic [7:0] next_flag;
  logic [7:0] next_value [8];
  logic [8:0] priority_cond;

  xs_NewRobDeqPtrWrapper_core #(
    .COMMIT_WIDTH (8),
    .ROB_SIZE     (160)
  ) u_core (
    .clock                 (clock),
    .reset                 (reset),
    .state                 (io_state),
    .deq_v                 ({io_deq_v_7, io_deq_v_6, io_deq_v_5, io_deq_v_4,
                             io_deq_v_3, io_deq_v_2, io_deq_v_1, io_deq_v_0}),
    .deq_w                 ({io_deq_w_7, io_deq_w_6, io_deq_w_5, io_deq_w_4,
                             io_deq_w_3, io_deq_w_2, io_deq_w_1, io_deq_w_0}),
    .has_committed         ({io_hasCommitted_7, io_hasCommitted_6, io_hasCommitted_5, io_hasCommitted_4,
                             io_hasCommitted_3, io_hasCommitted_2, io_hasCommitted_1, io_hasCommitted_0}),
    .exc_valid             (io_exception_state_valid),
    .exc_flag              (io_exception_state_bits_robIdx_flag),
    .exc_value             (io_exception_state_bits_robIdx_value),
    .exc_has_exception     (io_exception_state_bits_hasException),
    .exc_replay_inst       (io_exception_state_bits_replayInst),
    .exc_single_step       (io_exception_state_bits_singleStep),
    .exc_trigger           (io_exception_state_bits_trigger),
    .intr_bit_set          (io_intrBitSetReg),
    .allow_only_one_commit (io_allowOnlyOneCommit),
    .has_no_spec_exec      (io_hasNoSpecExec),
    .interrupt_safe        (io_interrupt_safe),
    .block_commit          (io_blockCommit),
    .out_flag              (out_flag),
    .out_value             (out_value),
    .next_flag             (next_flag),
    .next_value            (next_value),
    .priority_cond         (priority_cond)
  );

  assign io_out_0_flag       = out_flag[0];
  assign io_out_0_value      = out_value[0];
  assign io_out_1_flag       = out_flag[1];
  assign io_out_1_value      = out_value[1];
  assign io_out_2_flag       = out_flag[2];
  assign io_out_2_value      = out_value[2];
  assign io_out_3_flag       = out_flag[3];
  assign io_out_3_value      = out_value[3];
  assign io_out_4_flag       = out_flag[4];
  assign io_out_4_value      = out_value[4];
  assign io_out_5_flag       = out_flag[5];
  assign io_out_5_value      = out_value[5];
  assign io_out_6_flag       = out_flag[6];
  assign io_out_6_value      = out_value[6];
  assign io_out_7_flag       = out_flag[7];
  assign io_out_7_value      = out_value[7];
  assign io_next_out_0_flag  = next_flag[0];
  assign io_next_out_0_value = next_value[0];
  assign io_next_out_1_flag  = next_flag[1];
  assign io_next_out_1_value = next_value[1];
  assign io_next_out_2_flag  = next_flag[2];
  assign io_next_out_2_value = next_value[2];
  assign io_next_out_3_flag  = next_flag[3];
  assign io_next_out_3_value = next_value[3];
  assign io_next_out_4_flag  = next_flag[4];
  assign io_next_out_4_value = next_value[4];
  assign io_next_out_5_flag  = next_flag[5];
  assign io_next_out_5_value = next_value[5];
  assign io_next_out_6_flag  = next_flag[6];
  assign io_next_out_6_value = next_value[6];
  assign io_next_out_7_flag  = next_flag[7];
  assign io_next_out_7_value = next_value[7];
  assign io_canCommitPriorityCond_0 = priority_cond[0];
  assign io_canCommitPriorityCond_1 = priority_cond[1];
  assign io_canCommitPriorityCond_2 = priority_cond[2];
  assign io_canCommitPriorityCond_3 = priority_cond[3];
  assign io_canCommitPriorityCond_4 = priority_cond[4];
  assign io_canCommitPriorityCond_5 = priority_cond[5];
  assign io_canCommitPriorityCond_6 = priority_cond[6];
  assign io_canCommitPriorityCond_7 = priority_cond[7];
  assign io_canCommitPriorityCond_8 = priority_cond[8];

endmodule
