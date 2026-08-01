// ============================================================================
// xs_NewRobDeqPtr_core —— ROB deq 指针生成器可读核
//
// 忠实复刻 golden NewRobDeqPtrWrapper.sv 语义 (bug-for-bug), 但以可读形式表达:
//   · 维护 8 个环形出队指针 deqPtrVec[0..7] (连续, 复位为 0..7)。
//   · 只有 state==0 (io_state==2'h0, 即正常 commit 态, 非 walk) 且未被 blockCommit
//     且未命中中断/异常拦截时, 本周期才推进指针 (commitEn 门控)。
//   · 每 lane 是否可提交 canCommit_i = (deq_v_i & deq_w_i) | hasCommitted_i。
//   · 由 allowOnlyOneCommit / canCommit 优先级决定本周期提交条数 (0..8),
//     指针整体前移相应条数 (环形绕回 ROB_SIZE=160)。
//
// 候选指针 commitDeqPtr(N) 的构造 (与 golden 逐位一致):
//   groupBase = {deqPtrVec[0].value[7:3], 3'h0}   // 向下对齐到 8 的倍数
//   cand      = groupBase + N                      // N ∈ 0..15
//   wrap      = (cand >= ROB_SIZE)                 // golden: diff=cand-160 >= 0
//   value     = wrap ? (cand - ROB_SIZE) : cand
//   flag      = deqPtrVec[0].flag ^ wrap
// (groupBase ≤ 152, N ≤ 15 ⇒ cand ≤ 167 < 320, 单次减 160 即完成绕回。)
// ============================================================================
module xs_NewRobDeqPtr_core
  import newrobdeqptr_pkg::*;
(
  input  logic                 clock,
  input  logic                 reset,
  input  logic [1:0]           io_state,
  input  logic [COMMIT_W-1:0]  io_deq_v,           // 每 lane valid
  input  logic [COMMIT_W-1:0]  io_deq_w,           // 每 lane writeback done
  input  logic [COMMIT_W-1:0]  io_hasCommitted,    // 每 lane 已提交 (跨周期)
  // 异常状态
  input  logic                 io_exception_state_valid,
  input  rob_ptr_t             io_exception_state_bits_robIdx,
  input  logic                 io_exception_state_bits_hasException,
  input  logic                 io_exception_state_bits_replayInst,
  input  logic                 io_exception_state_bits_singleStep,
  input  logic [3:0]           io_exception_state_bits_trigger,
  // 提交门控
  input  logic                 io_intrBitSetReg,
  input  logic                 io_allowOnlyOneCommit,
  input  logic                 io_hasNoSpecExec,
  input  logic                 io_interrupt_safe,
  input  logic                 io_blockCommit,
  // 输出: 8 个当前 deq 指针 + 下周期 deqPtr[0]
  output rob_ptr_t             io_out       [COMMIT_W],
  output rob_ptr_t             io_next_out_0
);

  // ------------------------------------------------------------------
  // 状态: 8 个出队指针
  // ------------------------------------------------------------------
  rob_ptr_t deqPtrVec [COMMIT_W];

  // ------------------------------------------------------------------
  // commitEn: state==0 (正常提交态)
  // ------------------------------------------------------------------
  wire commitEn = (io_state == 2'h0);

  // 每 lane 是否可提交
  logic [COMMIT_W-1:0] canCommit;
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++)
      canCommit[i] = (io_deq_v[i] & io_deq_w[i]) | io_hasCommitted[i];
  end

  // deqPtr[0] 指向的组内偏移 (0..7) 与 flag
  wire [2:0]           headIdx  = deqPtrVec[0].value[2:0];
  wire                 headFlag = deqPtrVec[0].flag;
  wire [PTR_VAL_W-1:0] headVal  = deqPtrVec[0].value;

  // canCommit 在 deqPtr[0] 头位置的取值 (golden _GEN_2)
  wire canCommitHead = canCommit[headIdx];

  // ------------------------------------------------------------------
  // 候选指针 commitDeqPtr(N), N=0..15
  //   groupBase = value 向下对齐到 8 的倍数
  // ------------------------------------------------------------------
  wire [PTR_VAL_W-1:0] groupBase = {headVal[PTR_VAL_W-1:3], 3'h0};

  // 逐位复刻 golden: new_value = 9'({1'h0,value[7:3],3'h0} + N);
  //                  diff      = 10'({1'h0, new_value} - 10'hA0);
  //                  wrap      = $signed(diff) > -1  (即 diff >= 0, new_value >= 160);
  //                  value     = wrap ? diff[7:0] : new_value[7:0];
  //                  flag      = wrap ^ deqPtrVec_0_flag。
  wire [8:0] gen3 = {1'b0, groupBase};   // 9 位, 与 golden _GEN_3 同
  rob_ptr_t commitDeqPtr [16];
  always_comb begin
    for (int n = 0; n < 16; n++) begin
      logic [8:0] new_value;
      logic [9:0] diff;
      logic       wrap;
      new_value = gen3 + 9'(n);
      diff      = {1'b0, new_value} - 10'(ROB_SIZE);
      wrap      = ($signed(diff) > -10'sh1);
      commitDeqPtr[n].value = wrap ? diff[PTR_VAL_W-1:0] : new_value[PTR_VAL_W-1:0];
      commitDeqPtr[n].flag  = headFlag ^ wrap;
    end
  end

  // ------------------------------------------------------------------
  // 提交条数优先级 (golden canCommitPriorityCond_0..8)
  //   非 allowOnlyOneCommit: cond_k = ~canCommit_k (第一个不能提交的 lane 处停)
  //   allowOnlyOneCommit   : 仅当 head 恰在 lane k 且 head 可提交时才提交 1 条
  //   cond_8 = 全部可提交 (提交满 8 条)
  // ------------------------------------------------------------------
  logic [8:0] priCond;
  always_comb begin
    if (io_allowOnlyOneCommit) begin
      priCond[0] = 1'b0;
      for (int k = 1; k <= 7; k++)
        priCond[k] = (headIdx == 3'(k-1)) & canCommitHead;
      priCond[8] = (&headIdx) & canCommitHead;   // head 在 lane7
    end else begin
      for (int k = 0; k <= 7; k++)
        priCond[k] = ~canCommit[k];
      priCond[8] = 1'b1;
    end
  end

  // numCommit ∈ 0..8 = 第一个置位的 priCond 索引 (优先级从低到高), 决定指针整体
  //   从 groupBase 前移多少 (deqPtrVec[i] <= commitDeqPtr[i+numCommit])。
  // anyCommit = 是否有任一 priCond 置位:
  //   · 非 allowOnlyOne: priCond[8] 恒为 1 ⇒ anyCommit 恒真, 每周期 rebase 到 groupBase。
  //   · allowOnlyOne  : 仅 head 可提交时才有 cond 置位 (rebase 到 groupBase+headIdx+1);
  //     head 不可提交时全 0 ⇒ 不写 (与 golden else 分支 priCond_8=0 只回写不变 flag 等价)。
  // 注意: numCommit=0 (非 allowOnlyOne 且 lane0 不可提交) 仍要写 —— 把指针 rebase 回
  //   groupBase, 而非「不推进」。故写门控用 anyCommit 而非 numCommit!=0。
  logic [3:0] numCommit;
  logic       anyCommit;
  always_comb begin
    numCommit = 4'd0;
    anyCommit = 1'b0;
    for (int k = 8; k >= 0; k--)
      if (priCond[k]) begin
        numCommit = 4'(k);
        anyCommit = 1'b1;
      end
  end

  // ------------------------------------------------------------------
  // 是否真正推进 (golden _deqPtrVec_next_T_4)
  //   commitEn 且 未 blockCommit 且 未命中「头条被中断/异常拦截」。
  //   拦截条件: head lane valid, 且 (中断 pending 且非等待前序且中断安全)
  //             或 (head 已 writeback 且异常有效且异常类型触发提交拦截
  //                 且异常 robIdx == deqPtr[0])。
  // ------------------------------------------------------------------
  wire headDeqV = io_deq_v[headIdx];
  wire headDeqW = io_deq_w[headIdx];

  wire intrBlock = io_intrBitSetReg & ~io_hasNoSpecExec & io_interrupt_safe;

  wire excMatchHead =
      headDeqW & io_exception_state_valid
    & ( io_exception_state_bits_hasException
      | io_exception_state_bits_singleStep
      | io_exception_state_bits_replayInst
      | (io_exception_state_bits_trigger == 4'h1) )
    & ( io_exception_state_bits_robIdx == deqPtrVec[0] );

  wire headBlocked = headDeqV & (intrBlock | excMatchHead);

  wire advance = commitEn & ~headBlocked & ~io_blockCommit;

  // ------------------------------------------------------------------
  // 下一态: 推进 numCommit 条 (numCommit≥1 时 deqPtrVec[i] <= commitDeqPtr[i+numCommit])。
  //   numCommit=0 (仅 allowOnlyOneCommit 且头不可提交) => 保持不变, 与 golden else
  //   分支 priCond_8=0「仅回写不变的 flag」等价 —— 用 doCommit 门控。
  //   (i+numCommit ≤ 7+8 = 15, commitDeqPtr[16] 覆盖。)
  // ------------------------------------------------------------------
  wire doCommit = advance & anyCommit;

  // 索引 = i + numCommit, i∈0..7, numCommit∈0..8 ⇒ ∈0..15, 恰好 4 位, 静态在
  //   commitDeqPtr[16] 边界内 (4 位无符号加法自然截断到 [0,15], 无越界)。
  rob_ptr_t nextVec [COMMIT_W];
  always_comb begin
    for (int i = 0; i < COMMIT_W; i++) begin
      logic [3:0] idx;
      idx = 4'(i) + numCommit;
      nextVec[i] = commitDeqPtr[idx];
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < COMMIT_W; i++) begin
        deqPtrVec[i].flag  <= 1'b0;
        deqPtrVec[i].value <= PTR_VAL_W'(i);
      end
    end else if (doCommit) begin
      for (int i = 0; i < COMMIT_W; i++)
        deqPtrVec[i] <= nextVec[i];
    end
  end

  // ------------------------------------------------------------------
  // 输出。io_next_out_0: 推进时为 nextVec[0], 否则 (含 numCommit=0) 保持 deqPtrVec[0]。
  // ------------------------------------------------------------------
  assign io_out = deqPtrVec;
  assign io_next_out_0 = doCommit ? nextVec[0] : deqPtrVec[0];

endmodule
