// =============================================================================
// VTypeBuffer —— 向量 vtype 的"重命名缓冲"：记录在途 vset 指令写下的 vtype，提交时更新
//               架构 vtype，冲刷后通过 walk 把译码级的推测 vtype 恢复回来（Rob 的子模块）
//
// 设计源：src/main/scala/xiangshan/backend/rob/VTypeBuffer.scala（size = VTypeBufferSize = 64）。
//
// 为什么需要它：vset{i}vl{i} 在译码级就改写推测 vtype（后续向量指令的译码依赖它），
//   一旦发生冲刷，译码级必须回到"冲刷点之前最后一条 vset 写下的 vtype"。本模块按程序序
//   保存每条 vset（只记它最后一个 uop）的 vtype，像 ROB 一样 enq / commit / walk。
//
// 结构：
//   §1 入队：本拍 6 个 rename 口里 valid && isVset && lastUop 的项按序写入 64 项存储体
//      （SyncDataModuleTemplate__64entry_4，同步读），第 i 个口写 enqPtrVec[已分配数]；
//      enqPtr 前移分配条数。
//   §2 三态状态机 s_idle / s_spcl_walk / s_walk（编码 0 / 1 / 2；3 不可达，保持）：
//        redirect：useSnpt ? s_walk（从快照恢复后再往前 walk） : s_spcl_walk（先把"已提交但
//                  还没出队"的 commitSize 项当作 special walk 出队，再 walk）；
//        s_spcl_walk：spclWalkSize 走完 ⇒ s_walk；
//        s_walk：ROB 宣告 walk 结束（walkEnd，或之前已宣告过）且 walkSize 走完 ⇒ s_idle。
//   §3 计数：ROB 每拍送来 commitSize / walkSize 增量，本模块每拍最多处理 8 项（CommitWidth），
//      剩余量记在 commitSize / walkSize / spclWalkSize 里。★这三个寄存器是 7 位
//      （size.U.getWidth），但"下一值"线宽是 4 位（CommitWidth.U.getWidth），每次写入都是
//      4 位零扩展——高 3 位恒 0，golden 同（照搬，不收窄）。
//   §4 指针：deqPtr 按 commit / special-walk 条数前移；walkPtr 在进入 walk 时从快照（或
//      special walk 后的 deqPtr）起头，walk 中按 walkCount 前移；walk 结束时 enqPtr 回到 walkPtr。
//      deqPtrOH 是 deqPtr 的独热副本（Scala 只用来做 XSError 自检，综合后无读者，照留）；
//      deqPtrVec[1..7] 同样只为 dontTouch 留下，无读者。
//   §5 读口：8 个同步读地址按"下一拍状态"取 deqPtrVecNext（idle / spcl_walk）或 walkPtrVecNext（walk）。
//   §6 输出给译码：commit 时把最新一项（commitValid 最高者）作为架构 vtype；
//      walk 中把最新一项（walkValid 最高者）或快照 vtype 作为恢复值（打一拍）。
//   §7 入队许可：numValidEntries + 本拍分配数 ≤ 58 / ≤ 52（打一拍，复位为 1）。
// 快照：两个 SnapshotGenerator（_1 记 enqPtr，_2 记本拍第一个 valid 口的 specVType），实例名同 golden。
// =============================================================================
module xs_VTypeBuffer_core #(
  parameter int SIZE         = 64,
  parameter int RENAME_WIDTH = 6,
  parameter int COMMIT_WIDTH = 8
) (
  input  logic                    clock,
  input  logic                    reset,
  input  logic                    redirect_valid,
  // rename 口（按口号打包）
  input  logic [RENAME_WIDTH-1:0] req_valid,
  input  logic [RENAME_WIDTH-1:0] req_is_vset,
  input  logic [RENAME_WIDTH-1:0] req_last_uop,
  input  logic [RENAME_WIDTH-1:0] req_is_vsetvl,      // fuOpType[6]
  input  logic [7:0]              req_vtype      [RENAME_WIDTH],   // {vill, vma, vta, vsew[1:0], vlmul[2:0]}
  input  logic [7:0]              req_spec_vtype [RENAME_WIDTH],
  // ROB
  input  logic [5:0]              rob_walk_size,
  input  logic                    rob_walk_end,
  input  logic [5:0]              rob_commit_size,
  // 快照口
  input  logic                    snpt_enq,
  input  logic                    snpt_deq,
  input  logic                    snpt_use,
  input  logic [1:0]              snpt_select,
  input  logic [3:0]              snpt_flush_vec,
  // 输出
  output logic                    can_enq,
  output logic                    can_enq_for_dispatch,
  output logic                    is_resume_vtype,
  output logic                    walk_to_arch_vtype,
  output logic                    walk_vtype_valid,
  output logic [7:0]              walk_vtype,
  output logic                    commit_vtype_valid,
  output logic [7:0]              commit_vtype,
  output logic                    commit_has_vsetvl,
  output logic                    walk_end
);

  localparam logic [1:0] S_IDLE      = 2'd0;
  localparam logic [1:0] S_SPCL_WALK = 2'd1;
  localparam logic [1:0] S_WALK      = 2'd2;

  // ---------------------------------------------------------------------------
  // 状态与寄存器声明
  // ---------------------------------------------------------------------------
  logic [1:0] state;
  logic [1:0] stateNext;
  logic [1:0] stateLastCycle;

  logic       enqPtrVec_flag  [RENAME_WIDTH];
  logic [5:0] enqPtrVec_value [RENAME_WIDTH];
  logic       deqPtrVec_flag  [COMMIT_WIDTH];
  logic [5:0] deqPtrVec_value [COMMIT_WIDTH];
  logic [SIZE-1:0] deqPtrOH;
  logic       walkPtr_flag;
  logic [5:0] walkPtr_value;
  logic       robWalkEndReg;
  logic [6:0] commitSize;
  logic [6:0] walkSize;
  logic [6:0] spclWalkSize;
  logic       useSnapshot;
  logic [7:0] snapshotVType;
  logic       allowEnqueue;
  logic       allowEnqueueForDispatch;
  logic       decodeResumeVType_valid;
  logic [7:0] decodeResumeVType_bits;
  logic       walkToArchVType;

  wire state_idle = (state == S_IDLE);
  wire state_spcl = (state == S_SPCL_WALK);
  wire state_walk = (state == S_WALK);

  // ---------------------------------------------------------------------------
  // §1 入队：哪些口要分配一项、各写到哪
  // ---------------------------------------------------------------------------
  logic [RENAME_WIDTH-1:0] need_alloc;
  logic [2:0]              enq_count;
  logic [5:0]              alloc_addr [RENAME_WIDTH];
  assign need_alloc = req_valid & req_is_vset & req_last_uop;
  assign enq_count  = 3'($countones(need_alloc));

  always_comb begin
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      int unsigned n_before;          // 口 i 之前已分配的条数 = PopCount(needAlloc.take(i))
      n_before = 0;
      for (int j = 0; j < i; j++) n_before += need_alloc[j];
      // 取 enqPtrVec[n_before]；n_before ≤ i，按 k ≤ i 逐项比较选（不用变量下标，免越界歧义）
      alloc_addr[i] = enqPtrVec_value[0];
      for (int k = 1; k <= i; k++)
        if (n_before == k) alloc_addr[i] = enqPtrVec_value[k];
    end
  end

  // ---------------------------------------------------------------------------
  // §3 本拍处理条数与剩余量
  //   commitValid[i] = (idle 且 i < commitSize) 或 (spcl_walk 且 i < spclWalkSize)
  //   walkValid[i]   = (walk 且 i < walkSize)   或 (spcl_walk 且 i < spclWalkSize)
  // ---------------------------------------------------------------------------
  logic [COMMIT_WIDTH-1:0] commit_valid;
  logic [COMMIT_WIDTH-1:0] walk_valid;
  always_comb begin
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      commit_valid[i] = (state_idle & (7'(i) < commitSize)) | (state_spcl & (7'(i) < spclWalkSize));
      walk_valid[i]   = (state_walk & (7'(i) < walkSize))   | (state_spcl & (7'(i) < spclWalkSize));
    end
  end

  logic [3:0] commit_count;
  logic [3:0] walk_count;
  logic [3:0] spcl_walk_count;
  assign commit_count    = state_idle ? 4'($countones(commit_valid)) : 4'd0;
  assign walk_count      = state_walk ? 4'($countones(walk_valid))   : 4'd0;
  assign spcl_walk_count = state_spcl ? 4'($countones(walk_valid))   : 4'd0;

  // 下一值都是 4 位（见文件头 §3 的说明）
  logic [3:0] commit_size_next;
  logic [3:0] walk_size_next;
  logic [3:0] spcl_walk_size_next;
  logic [3:0] new_spcl_walk_size;
  assign commit_size_next    = 4'(commitSize + rob_commit_size - commit_count);
  assign walk_size_next      = 4'(walkSize + rob_walk_size - walk_count);
  assign new_spcl_walk_size  = (redirect_valid & ~snpt_use) ? commit_size_next : 4'd0;
  assign spcl_walk_size_next = 4'(spclWalkSize + new_spcl_walk_size - spcl_walk_count);

  wire walk_end_next      = (walk_size_next == 4'd0);
  wire spcl_walk_end_next = (spcl_walk_size_next == 4'd0);
  wire rob_walk_end_any   = rob_walk_end | robWalkEndReg;

  // ---------------------------------------------------------------------------
  // §2 状态机
  // ---------------------------------------------------------------------------
  always_comb begin
    stateNext = state;                               // 默认保持（含不可达的 3）
    if (redirect_valid)
      stateNext = snpt_use ? S_WALK : S_SPCL_WALK;
    else if (state_idle)
      stateNext = S_IDLE;
    else if (state_spcl && spcl_walk_end_next)
      stateNext = S_WALK;
    else if (state_walk && rob_walk_end_any && walk_end_next)
      stateNext = S_IDLE;
  end

  wire next_idle = (stateNext == S_IDLE);
  wire next_spcl = (stateNext == S_SPCL_WALK);
  wire next_walk = (stateNext == S_WALK);

  // ---------------------------------------------------------------------------
  // §4 指针更新
  // ---------------------------------------------------------------------------
  // 快照里取出的 walk 起点与 vtype
  logic       snpt_ptr_flag  [4];
  logic [5:0] snpt_ptr_value [4];
  logic [7:0] snpt_vtype     [4];

  // deqPtr：idle 时按提交条数、spcl_walk 时按 special walk 条数前移
  logic [3:0] deq_ptr_steps;
  logic [6:0] deq_ptr_next;                          // {flag, value}
  assign deq_ptr_steps = (state_idle ? commit_count : 4'd0) | (state_spcl ? spcl_walk_count : 4'd0);
  assign deq_ptr_next  = {deqPtrVec_flag[0], deqPtrVec_value[0]} + 7'(deq_ptr_steps);

  // walkPtr 下一值（MuxCase，前者优先）
  logic [6:0] walk_ptr_next;                         // {flag, value}
  always_comb begin
    if (state_idle && next_walk)
      walk_ptr_next = {snpt_ptr_flag[snpt_select], snpt_ptr_value[snpt_select]};
    else if (state_spcl && next_walk)
      walk_ptr_next = deq_ptr_next;
    else if (state_walk && snpt_use && redirect_valid)
      walk_ptr_next = {snpt_ptr_flag[snpt_select], snpt_ptr_value[snpt_select]};
    else if (state_walk)
      walk_ptr_next = {walkPtr_flag, walkPtr_value} + 7'(walk_count);
    else
      walk_ptr_next = {walkPtr_flag, walkPtr_value};
  end

  // enqPtr：walk 结束回到 walkPtr，否则按分配条数前移
  logic [6:0] enq_ptr_next;                          // {flag, value}
  assign enq_ptr_next = (state_walk && next_idle) ? walk_ptr_next
                                                  : {enqPtrVec_flag[0], enqPtrVec_value[0]} + 7'(enq_count);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < RENAME_WIDTH; i++) begin
        enqPtrVec_flag[i]  <= 1'b0;
        enqPtrVec_value[i] <= 6'(i);
      end
      for (int i = 0; i < COMMIT_WIDTH; i++) begin
        deqPtrVec_flag[i]  <= 1'b0;
        deqPtrVec_value[i] <= 6'(i);
      end
      deqPtrOH <= SIZE'(1);
    end else begin
      for (int i = 0; i < RENAME_WIDTH; i++)
        {enqPtrVec_flag[i], enqPtrVec_value[i]} <= enq_ptr_next + 7'(i);
      for (int i = 0; i < COMMIT_WIDTH; i++)
        {deqPtrVec_flag[i], deqPtrVec_value[i]} <= deq_ptr_next + 7'(i);
      // 独热副本循环左移 deq_ptr_steps 位（0..8；越界的 9..15 保持，与 golden 的 Vec 越界取第 0 项同）
      if (deq_ptr_steps <= 4'(COMMIT_WIDTH))
        deqPtrOH <= (deqPtrOH << deq_ptr_steps) | (deqPtrOH >> (SIZE - deq_ptr_steps));
    end
  end

  // walkPtr 不复位（Reg），每拍写 walk_ptr_next
  always_ff @(posedge clock)
    {walkPtr_flag, walkPtr_value} <= walk_ptr_next;

  // ---------------------------------------------------------------------------
  // §2/§3 寄存器：状态、剩余量、ROB walkEnd 的粘滞位
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state         <= S_IDLE;
      robWalkEndReg <= 1'b0;
      commitSize    <= 7'd0;
      walkSize      <= 7'd0;
      spclWalkSize  <= 7'd0;
    end else begin
      state         <= stateNext;
      robWalkEndReg <= ~redirect_valid & rob_walk_end_any;
      commitSize    <= {3'd0, (redirect_valid & ~snpt_use) ? 4'd0 : commit_size_next};
      walkSize      <= {3'd0, redirect_valid ? 4'd0 : walk_size_next};
      spclWalkSize  <= {3'd0, spcl_walk_size_next};
    end
  end

  always_ff @(posedge clock)
    stateLastCycle <= state;

  // ---------------------------------------------------------------------------
  // §5 存储体：8 读口地址按下一拍状态选
  // ---------------------------------------------------------------------------
  logic [5:0] read_addr [COMMIT_WIDTH];
  always_comb begin
    for (int i = 0; i < COMMIT_WIDTH; i++) begin
      logic [6:0] deq_i;
      deq_i        = deq_ptr_next + 7'(i);
      read_addr[i] = ((next_idle | next_spcl) ? deq_i[5:0] : 6'd0)
                   | (next_walk ? 6'(walk_ptr_next[5:0] + 6'(i)) : 6'd0);
    end
  end

  logic [7:0]              info_vtype [COMMIT_WIDTH];   // {illegal, vma, vta, vsew, vlmul}
  logic [COMMIT_WIDTH-1:0] info_is_vsetvl;

  SyncDataModuleTemplate__64entry_4 vtypeBuffer (
    .clock                    (clock),
    .reset                    (reset),
    .io_raddr_0               (read_addr[0]),
    .io_raddr_1               (read_addr[1]),
    .io_raddr_2               (read_addr[2]),
    .io_raddr_3               (read_addr[3]),
    .io_raddr_4               (read_addr[4]),
    .io_raddr_5               (read_addr[5]),
    .io_raddr_6               (read_addr[6]),
    .io_raddr_7               (read_addr[7]),
    .io_rdata_0_vtype_illegal (info_vtype[0][7]),
    .io_rdata_0_vtype_vma     (info_vtype[0][6]),
    .io_rdata_0_vtype_vta     (info_vtype[0][5]),
    .io_rdata_0_vtype_vsew    (info_vtype[0][4:3]),
    .io_rdata_0_vtype_vlmul   (info_vtype[0][2:0]),
    .io_rdata_0_isVsetvl      (info_is_vsetvl[0]),
    .io_rdata_1_vtype_illegal (info_vtype[1][7]),
    .io_rdata_1_vtype_vma     (info_vtype[1][6]),
    .io_rdata_1_vtype_vta     (info_vtype[1][5]),
    .io_rdata_1_vtype_vsew    (info_vtype[1][4:3]),
    .io_rdata_1_vtype_vlmul   (info_vtype[1][2:0]),
    .io_rdata_1_isVsetvl      (info_is_vsetvl[1]),
    .io_rdata_2_vtype_illegal (info_vtype[2][7]),
    .io_rdata_2_vtype_vma     (info_vtype[2][6]),
    .io_rdata_2_vtype_vta     (info_vtype[2][5]),
    .io_rdata_2_vtype_vsew    (info_vtype[2][4:3]),
    .io_rdata_2_vtype_vlmul   (info_vtype[2][2:0]),
    .io_rdata_2_isVsetvl      (info_is_vsetvl[2]),
    .io_rdata_3_vtype_illegal (info_vtype[3][7]),
    .io_rdata_3_vtype_vma     (info_vtype[3][6]),
    .io_rdata_3_vtype_vta     (info_vtype[3][5]),
    .io_rdata_3_vtype_vsew    (info_vtype[3][4:3]),
    .io_rdata_3_vtype_vlmul   (info_vtype[3][2:0]),
    .io_rdata_3_isVsetvl      (info_is_vsetvl[3]),
    .io_rdata_4_vtype_illegal (info_vtype[4][7]),
    .io_rdata_4_vtype_vma     (info_vtype[4][6]),
    .io_rdata_4_vtype_vta     (info_vtype[4][5]),
    .io_rdata_4_vtype_vsew    (info_vtype[4][4:3]),
    .io_rdata_4_vtype_vlmul   (info_vtype[4][2:0]),
    .io_rdata_4_isVsetvl      (info_is_vsetvl[4]),
    .io_rdata_5_vtype_illegal (info_vtype[5][7]),
    .io_rdata_5_vtype_vma     (info_vtype[5][6]),
    .io_rdata_5_vtype_vta     (info_vtype[5][5]),
    .io_rdata_5_vtype_vsew    (info_vtype[5][4:3]),
    .io_rdata_5_vtype_vlmul   (info_vtype[5][2:0]),
    .io_rdata_5_isVsetvl      (info_is_vsetvl[5]),
    .io_rdata_6_vtype_illegal (info_vtype[6][7]),
    .io_rdata_6_vtype_vma     (info_vtype[6][6]),
    .io_rdata_6_vtype_vta     (info_vtype[6][5]),
    .io_rdata_6_vtype_vsew    (info_vtype[6][4:3]),
    .io_rdata_6_vtype_vlmul   (info_vtype[6][2:0]),
    .io_rdata_6_isVsetvl      (info_is_vsetvl[6]),
    .io_rdata_7_vtype_illegal (info_vtype[7][7]),
    .io_rdata_7_vtype_vma     (info_vtype[7][6]),
    .io_rdata_7_vtype_vta     (info_vtype[7][5]),
    .io_rdata_7_vtype_vsew    (info_vtype[7][4:3]),
    .io_rdata_7_vtype_vlmul   (info_vtype[7][2:0]),
    .io_rdata_7_isVsetvl      (info_is_vsetvl[7]),
    .io_wen_0                 (need_alloc[0]),
    .io_wen_1                 (need_alloc[1]),
    .io_wen_2                 (need_alloc[2]),
    .io_wen_3                 (need_alloc[3]),
    .io_wen_4                 (need_alloc[4]),
    .io_wen_5                 (need_alloc[5]),
    .io_waddr_0               (alloc_addr[0]),
    .io_waddr_1               (alloc_addr[1]),
    .io_waddr_2               (alloc_addr[2]),
    .io_waddr_3               (alloc_addr[3]),
    .io_waddr_4               (alloc_addr[4]),
    .io_waddr_5               (alloc_addr[5]),
    .io_wdata_0_vtype_illegal (req_vtype[0][7]),
    .io_wdata_0_vtype_vma     (req_vtype[0][6]),
    .io_wdata_0_vtype_vta     (req_vtype[0][5]),
    .io_wdata_0_vtype_vsew    (req_vtype[0][4:3]),
    .io_wdata_0_vtype_vlmul   (req_vtype[0][2:0]),
    .io_wdata_0_isVsetvl      (req_is_vsetvl[0]),
    .io_wdata_1_vtype_illegal (req_vtype[1][7]),
    .io_wdata_1_vtype_vma     (req_vtype[1][6]),
    .io_wdata_1_vtype_vta     (req_vtype[1][5]),
    .io_wdata_1_vtype_vsew    (req_vtype[1][4:3]),
    .io_wdata_1_vtype_vlmul   (req_vtype[1][2:0]),
    .io_wdata_1_isVsetvl      (req_is_vsetvl[1]),
    .io_wdata_2_vtype_illegal (req_vtype[2][7]),
    .io_wdata_2_vtype_vma     (req_vtype[2][6]),
    .io_wdata_2_vtype_vta     (req_vtype[2][5]),
    .io_wdata_2_vtype_vsew    (req_vtype[2][4:3]),
    .io_wdata_2_vtype_vlmul   (req_vtype[2][2:0]),
    .io_wdata_2_isVsetvl      (req_is_vsetvl[2]),
    .io_wdata_3_vtype_illegal (req_vtype[3][7]),
    .io_wdata_3_vtype_vma     (req_vtype[3][6]),
    .io_wdata_3_vtype_vta     (req_vtype[3][5]),
    .io_wdata_3_vtype_vsew    (req_vtype[3][4:3]),
    .io_wdata_3_vtype_vlmul   (req_vtype[3][2:0]),
    .io_wdata_3_isVsetvl      (req_is_vsetvl[3]),
    .io_wdata_4_vtype_illegal (req_vtype[4][7]),
    .io_wdata_4_vtype_vma     (req_vtype[4][6]),
    .io_wdata_4_vtype_vta     (req_vtype[4][5]),
    .io_wdata_4_vtype_vsew    (req_vtype[4][4:3]),
    .io_wdata_4_vtype_vlmul   (req_vtype[4][2:0]),
    .io_wdata_4_isVsetvl      (req_is_vsetvl[4]),
    .io_wdata_5_vtype_illegal (req_vtype[5][7]),
    .io_wdata_5_vtype_vma     (req_vtype[5][6]),
    .io_wdata_5_vtype_vta     (req_vtype[5][5]),
    .io_wdata_5_vtype_vsew    (req_vtype[5][4:3]),
    .io_wdata_5_vtype_vlmul   (req_vtype[5][2:0]),
    .io_wdata_5_isVsetvl      (req_is_vsetvl[5])
  );

  // ---------------------------------------------------------------------------
  // 快照：enqPtr 与本拍第一个 valid 口的推测 vtype
  // ---------------------------------------------------------------------------
  logic [7:0] enq_spec_vtype;                        // PriorityMux：最低号 valid 口，全无取口 5
  always_comb begin
    enq_spec_vtype = req_spec_vtype[RENAME_WIDTH-1];
    for (int i = RENAME_WIDTH - 2; i >= 0; i--)
      if (req_valid[i]) enq_spec_vtype = req_spec_vtype[i];
  end

  SnapshotGenerator_1 walkPtrSnapshots_snapshotGen (
    .clock                (clock),
    .reset                (reset),
    .io_enq               (snpt_enq),
    .io_enqData_flag      (enqPtrVec_flag[0]),
    .io_enqData_value     (enqPtrVec_value[0]),
    .io_deq               (snpt_deq),
    .io_redirect          (redirect_valid),
    .io_flushVec_0        (snpt_flush_vec[0]),
    .io_flushVec_1        (snpt_flush_vec[1]),
    .io_flushVec_2        (snpt_flush_vec[2]),
    .io_flushVec_3        (snpt_flush_vec[3]),
    .io_snapshots_0_flag  (snpt_ptr_flag[0]),
    .io_snapshots_0_value (snpt_ptr_value[0]),
    .io_snapshots_1_flag  (snpt_ptr_flag[1]),
    .io_snapshots_1_value (snpt_ptr_value[1]),
    .io_snapshots_2_flag  (snpt_ptr_flag[2]),
    .io_snapshots_2_value (snpt_ptr_value[2]),
    .io_snapshots_3_flag  (snpt_ptr_flag[3]),
    .io_snapshots_3_value (snpt_ptr_value[3])
  );

  SnapshotGenerator_2 walkVTypeSnapshots_snapshotGen (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq                 (snpt_enq),
    .io_enqData_illegal     (enq_spec_vtype[7]),
    .io_enqData_vma         (enq_spec_vtype[6]),
    .io_enqData_vta         (enq_spec_vtype[5]),
    .io_enqData_vsew        (enq_spec_vtype[4:3]),
    .io_enqData_vlmul       (enq_spec_vtype[2:0]),
    .io_deq                 (snpt_deq),
    .io_redirect            (redirect_valid),
    .io_flushVec_0          (snpt_flush_vec[0]),
    .io_flushVec_1          (snpt_flush_vec[1]),
    .io_flushVec_2          (snpt_flush_vec[2]),
    .io_flushVec_3          (snpt_flush_vec[3]),
    .io_snapshots_0_illegal (snpt_vtype[0][7]),
    .io_snapshots_0_vma     (snpt_vtype[0][6]),
    .io_snapshots_0_vta     (snpt_vtype[0][5]),
    .io_snapshots_0_vsew    (snpt_vtype[0][4:3]),
    .io_snapshots_0_vlmul   (snpt_vtype[0][2:0]),
    .io_snapshots_1_illegal (snpt_vtype[1][7]),
    .io_snapshots_1_vma     (snpt_vtype[1][6]),
    .io_snapshots_1_vta     (snpt_vtype[1][5]),
    .io_snapshots_1_vsew    (snpt_vtype[1][4:3]),
    .io_snapshots_1_vlmul   (snpt_vtype[1][2:0]),
    .io_snapshots_2_illegal (snpt_vtype[2][7]),
    .io_snapshots_2_vma     (snpt_vtype[2][6]),
    .io_snapshots_2_vta     (snpt_vtype[2][5]),
    .io_snapshots_2_vsew    (snpt_vtype[2][4:3]),
    .io_snapshots_2_vlmul   (snpt_vtype[2][2:0]),
    .io_snapshots_3_illegal (snpt_vtype[3][7]),
    .io_snapshots_3_vma     (snpt_vtype[3][6]),
    .io_snapshots_3_vta     (snpt_vtype[3][5]),
    .io_snapshots_3_vsew    (snpt_vtype[3][4:3]),
    .io_snapshots_3_vlmul   (snpt_vtype[3][2:0])
  );

  // 用快照恢复：进入 walk 的那一拍（或 walk 中再次带快照冲刷）锁存选中的快照 vtype
  logic use_snapshot_next;
  assign use_snapshot_next = (state_idle & next_walk) | (state_walk & snpt_use & redirect_valid);

  always_ff @(posedge clock) begin
    useSnapshot <= use_snapshot_next;
    if (use_snapshot_next)
      snapshotVType <= snpt_vtype[snpt_select];
  end

  // ---------------------------------------------------------------------------
  // §6 给译码的 vtype
  //   newest*：有效项里下标最大（最新）的一项；一项都没有时取第 0 项（PriorityMux 缺省）
  // ---------------------------------------------------------------------------
  logic [7:0] newest_arch_vtype;
  logic [7:0] newest_walk_vtype;
  always_comb begin
    newest_arch_vtype = info_vtype[0];
    newest_walk_vtype = info_vtype[0];
    for (int i = 1; i < COMMIT_WIDTH; i++) begin
      if (commit_valid[i]) newest_arch_vtype = info_vtype[i];
      if (walk_valid[i])   newest_walk_vtype = info_vtype[i];
    end
  end

  wire walk_has_items = state_walk & (walk_count != 4'd0);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      decodeResumeVType_valid <= 1'b0;
      decodeResumeVType_bits  <= 8'd0;
      walkToArchVType         <= 1'b0;
    end else begin
      if (state_spcl) begin                    // special walk：用提交侧最新 vtype
        decodeResumeVType_valid <= |commit_valid;
        decodeResumeVType_bits  <= newest_arch_vtype;
      end else if (useSnapshot) begin          // 快照 vtype
        decodeResumeVType_valid <= 1'b1;
        decodeResumeVType_bits  <= snapshotVType;
      end else if (walk_has_items) begin       // walk 中：本拍走过的最新一项
        decodeResumeVType_valid <= 1'b1;
        decodeResumeVType_bits  <= newest_walk_vtype;
      end else begin
        decodeResumeVType_valid <= 1'b0;
      end
      // walk 刚开始且没有任何恢复值：通知译码回到架构 vtype
      walkToArchVType <= ~(state_spcl | useSnapshot | walk_has_items) & state_walk
                       & (stateLastCycle != S_WALK);
    end
  end

  // ---------------------------------------------------------------------------
  // §7 入队许可（打一拍，复位为 1）
  // ---------------------------------------------------------------------------
  logic [6:0] num_valid_entries;
  logic [6:0] entries_after_enq;
  assign num_valid_entries = (enqPtrVec_flag[0] == deqPtrVec_flag[0])
                           ? {1'b0, 6'(enqPtrVec_value[0] - deqPtrVec_value[0])}
                           : 7'(7'(SIZE) + enqPtrVec_value[0] - deqPtrVec_value[0]);
  assign entries_after_enq = num_valid_entries + 7'(enq_count);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      allowEnqueue            <= 1'b1;
      allowEnqueueForDispatch <= 1'b1;
    end else begin
      allowEnqueue            <= entries_after_enq <= 7'(SIZE - RENAME_WIDTH);
      allowEnqueueForDispatch <= entries_after_enq <= 7'(SIZE - 2 * RENAME_WIDTH);
    end
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign can_enq              = allowEnqueue & state_idle;
  assign can_enq_for_dispatch = allowEnqueueForDispatch & state_idle;
  assign is_resume_vtype      = ~state_idle | decodeResumeVType_valid;
  assign walk_to_arch_vtype   = walkToArchVType;
  assign walk_vtype_valid     = decodeResumeVType_valid;
  assign walk_vtype           = decodeResumeVType_valid ? decodeResumeVType_bits : 8'd0;
  assign commit_vtype_valid   = |commit_valid;
  assign commit_vtype         = newest_arch_vtype;
  assign commit_has_vsetvl    = |(commit_valid & info_is_vsetvl);
  assign walk_end             = walk_end_next;

endmodule
// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden VTypeBuffer.sv 逐位一致
// （vtype 五个字段在核里打包成 8 位 {illegal, vma, vta, vsew[1:0], vlmul[2:0]}）
// ---------------------------------------------------------------------------
module VTypeBuffer (
  input        clock,
  input        reset,
  input        io_redirect_valid,
  input        io_req_0_valid,
  input  [8:0] io_req_0_bits_fuOpType,
  input        io_req_0_bits_vpu_vill,
  input        io_req_0_bits_vpu_vma,
  input        io_req_0_bits_vpu_vta,
  input  [1:0] io_req_0_bits_vpu_vsew,
  input  [2:0] io_req_0_bits_vpu_vlmul,
  input        io_req_0_bits_vpu_specVill,
  input        io_req_0_bits_vpu_specVma,
  input        io_req_0_bits_vpu_specVta,
  input  [1:0] io_req_0_bits_vpu_specVsew,
  input  [2:0] io_req_0_bits_vpu_specVlmul,
  input        io_req_0_bits_isVset,
  input        io_req_0_bits_lastUop,
  input        io_req_1_valid,
  input  [8:0] io_req_1_bits_fuOpType,
  input        io_req_1_bits_vpu_vill,
  input        io_req_1_bits_vpu_vma,
  input        io_req_1_bits_vpu_vta,
  input  [1:0] io_req_1_bits_vpu_vsew,
  input  [2:0] io_req_1_bits_vpu_vlmul,
  input        io_req_1_bits_vpu_specVill,
  input        io_req_1_bits_vpu_specVma,
  input        io_req_1_bits_vpu_specVta,
  input  [1:0] io_req_1_bits_vpu_specVsew,
  input  [2:0] io_req_1_bits_vpu_specVlmul,
  input        io_req_1_bits_isVset,
  input        io_req_1_bits_lastUop,
  input        io_req_2_valid,
  input  [8:0] io_req_2_bits_fuOpType,
  input        io_req_2_bits_vpu_vill,
  input        io_req_2_bits_vpu_vma,
  input        io_req_2_bits_vpu_vta,
  input  [1:0] io_req_2_bits_vpu_vsew,
  input  [2:0] io_req_2_bits_vpu_vlmul,
  input        io_req_2_bits_vpu_specVill,
  input        io_req_2_bits_vpu_specVma,
  input        io_req_2_bits_vpu_specVta,
  input  [1:0] io_req_2_bits_vpu_specVsew,
  input  [2:0] io_req_2_bits_vpu_specVlmul,
  input        io_req_2_bits_isVset,
  input        io_req_2_bits_lastUop,
  input        io_req_3_valid,
  input  [8:0] io_req_3_bits_fuOpType,
  input        io_req_3_bits_vpu_vill,
  input        io_req_3_bits_vpu_vma,
  input        io_req_3_bits_vpu_vta,
  input  [1:0] io_req_3_bits_vpu_vsew,
  input  [2:0] io_req_3_bits_vpu_vlmul,
  input        io_req_3_bits_vpu_specVill,
  input        io_req_3_bits_vpu_specVma,
  input        io_req_3_bits_vpu_specVta,
  input  [1:0] io_req_3_bits_vpu_specVsew,
  input  [2:0] io_req_3_bits_vpu_specVlmul,
  input        io_req_3_bits_isVset,
  input        io_req_3_bits_lastUop,
  input        io_req_4_valid,
  input  [8:0] io_req_4_bits_fuOpType,
  input        io_req_4_bits_vpu_vill,
  input        io_req_4_bits_vpu_vma,
  input        io_req_4_bits_vpu_vta,
  input  [1:0] io_req_4_bits_vpu_vsew,
  input  [2:0] io_req_4_bits_vpu_vlmul,
  input        io_req_4_bits_vpu_specVill,
  input        io_req_4_bits_vpu_specVma,
  input        io_req_4_bits_vpu_specVta,
  input  [1:0] io_req_4_bits_vpu_specVsew,
  input  [2:0] io_req_4_bits_vpu_specVlmul,
  input        io_req_4_bits_isVset,
  input        io_req_4_bits_lastUop,
  input        io_req_5_valid,
  input  [8:0] io_req_5_bits_fuOpType,
  input        io_req_5_bits_vpu_vill,
  input        io_req_5_bits_vpu_vma,
  input        io_req_5_bits_vpu_vta,
  input  [1:0] io_req_5_bits_vpu_vsew,
  input  [2:0] io_req_5_bits_vpu_vlmul,
  input        io_req_5_bits_vpu_specVill,
  input        io_req_5_bits_vpu_specVma,
  input        io_req_5_bits_vpu_specVta,
  input  [1:0] io_req_5_bits_vpu_specVsew,
  input  [2:0] io_req_5_bits_vpu_specVlmul,
  input        io_req_5_bits_isVset,
  input        io_req_5_bits_lastUop,
  input  [5:0] io_fromRob_walkSize,
  input        io_fromRob_walkEnd,
  input  [5:0] io_fromRob_commitSize,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output       io_canEnq,
  output       io_canEnqForDispatch,
  output       io_toDecode_isResumeVType,
  output       io_toDecode_walkToArchVType,
  output       io_toDecode_walkVType_valid,
  output       io_toDecode_walkVType_bits_illegal,
  output       io_toDecode_walkVType_bits_vma,
  output       io_toDecode_walkVType_bits_vta,
  output [1:0] io_toDecode_walkVType_bits_vsew,
  output [2:0] io_toDecode_walkVType_bits_vlmul,
  output       io_toDecode_commitVType_vtype_valid,
  output       io_toDecode_commitVType_vtype_bits_illegal,
  output       io_toDecode_commitVType_vtype_bits_vma,
  output       io_toDecode_commitVType_vtype_bits_vta,
  output [1:0] io_toDecode_commitVType_vtype_bits_vsew,
  output [2:0] io_toDecode_commitVType_vtype_bits_vlmul,
  output       io_toDecode_commitVType_hasVsetvl,
  output       io_status_walkEnd
);

  logic [7:0] req_vtype      [6];
  logic [7:0] req_spec_vtype [6];
  logic [7:0] walk_vtype;
  logic [7:0] commit_vtype;

  assign req_vtype[0]      = {io_req_0_bits_vpu_vill, io_req_0_bits_vpu_vma, io_req_0_bits_vpu_vta,
                               io_req_0_bits_vpu_vsew, io_req_0_bits_vpu_vlmul};
  assign req_spec_vtype[0] = {io_req_0_bits_vpu_specVill, io_req_0_bits_vpu_specVma, io_req_0_bits_vpu_specVta,
                               io_req_0_bits_vpu_specVsew, io_req_0_bits_vpu_specVlmul};
  assign req_vtype[1]      = {io_req_1_bits_vpu_vill, io_req_1_bits_vpu_vma, io_req_1_bits_vpu_vta,
                               io_req_1_bits_vpu_vsew, io_req_1_bits_vpu_vlmul};
  assign req_spec_vtype[1] = {io_req_1_bits_vpu_specVill, io_req_1_bits_vpu_specVma, io_req_1_bits_vpu_specVta,
                               io_req_1_bits_vpu_specVsew, io_req_1_bits_vpu_specVlmul};
  assign req_vtype[2]      = {io_req_2_bits_vpu_vill, io_req_2_bits_vpu_vma, io_req_2_bits_vpu_vta,
                               io_req_2_bits_vpu_vsew, io_req_2_bits_vpu_vlmul};
  assign req_spec_vtype[2] = {io_req_2_bits_vpu_specVill, io_req_2_bits_vpu_specVma, io_req_2_bits_vpu_specVta,
                               io_req_2_bits_vpu_specVsew, io_req_2_bits_vpu_specVlmul};
  assign req_vtype[3]      = {io_req_3_bits_vpu_vill, io_req_3_bits_vpu_vma, io_req_3_bits_vpu_vta,
                               io_req_3_bits_vpu_vsew, io_req_3_bits_vpu_vlmul};
  assign req_spec_vtype[3] = {io_req_3_bits_vpu_specVill, io_req_3_bits_vpu_specVma, io_req_3_bits_vpu_specVta,
                               io_req_3_bits_vpu_specVsew, io_req_3_bits_vpu_specVlmul};
  assign req_vtype[4]      = {io_req_4_bits_vpu_vill, io_req_4_bits_vpu_vma, io_req_4_bits_vpu_vta,
                               io_req_4_bits_vpu_vsew, io_req_4_bits_vpu_vlmul};
  assign req_spec_vtype[4] = {io_req_4_bits_vpu_specVill, io_req_4_bits_vpu_specVma, io_req_4_bits_vpu_specVta,
                               io_req_4_bits_vpu_specVsew, io_req_4_bits_vpu_specVlmul};
  assign req_vtype[5]      = {io_req_5_bits_vpu_vill, io_req_5_bits_vpu_vma, io_req_5_bits_vpu_vta,
                               io_req_5_bits_vpu_vsew, io_req_5_bits_vpu_vlmul};
  assign req_spec_vtype[5] = {io_req_5_bits_vpu_specVill, io_req_5_bits_vpu_specVma, io_req_5_bits_vpu_specVta,
                               io_req_5_bits_vpu_specVsew, io_req_5_bits_vpu_specVlmul};

  xs_VTypeBuffer_core #(
    .SIZE         (64),
    .RENAME_WIDTH (6),
    .COMMIT_WIDTH (8)
  ) u_core (
    .clock                (clock),
    .reset                (reset),
    .redirect_valid       (io_redirect_valid),
    .req_valid            ({io_req_5_valid, io_req_4_valid, io_req_3_valid, io_req_2_valid, io_req_1_valid, io_req_0_valid}),
    .req_is_vset          ({io_req_5_bits_isVset, io_req_4_bits_isVset, io_req_3_bits_isVset, io_req_2_bits_isVset, io_req_1_bits_isVset, io_req_0_bits_isVset}),
    .req_last_uop         ({io_req_5_bits_lastUop, io_req_4_bits_lastUop, io_req_3_bits_lastUop, io_req_2_bits_lastUop, io_req_1_bits_lastUop, io_req_0_bits_lastUop}),
    .req_is_vsetvl        ({io_req_5_bits_fuOpType[6], io_req_4_bits_fuOpType[6], io_req_3_bits_fuOpType[6], io_req_2_bits_fuOpType[6], io_req_1_bits_fuOpType[6], io_req_0_bits_fuOpType[6]}),
    .req_vtype            (req_vtype),
    .req_spec_vtype       (req_spec_vtype),
    .rob_walk_size        (io_fromRob_walkSize),
    .rob_walk_end         (io_fromRob_walkEnd),
    .rob_commit_size      (io_fromRob_commitSize),
    .snpt_enq             (io_snpt_snptEnq),
    .snpt_deq             (io_snpt_snptDeq),
    .snpt_use             (io_snpt_useSnpt),
    .snpt_select          (io_snpt_snptSelect),
    .snpt_flush_vec       ({io_snpt_flushVec_3, io_snpt_flushVec_2, io_snpt_flushVec_1, io_snpt_flushVec_0}),
    .can_enq              (io_canEnq),
    .can_enq_for_dispatch (io_canEnqForDispatch),
    .is_resume_vtype      (io_toDecode_isResumeVType),
    .walk_to_arch_vtype   (io_toDecode_walkToArchVType),
    .walk_vtype_valid     (io_toDecode_walkVType_valid),
    .walk_vtype           (walk_vtype),
    .commit_vtype_valid   (io_toDecode_commitVType_vtype_valid),
    .commit_vtype         (commit_vtype),
    .commit_has_vsetvl    (io_toDecode_commitVType_hasVsetvl),
    .walk_end             (io_status_walkEnd)
  );

  assign {io_toDecode_walkVType_bits_illegal, io_toDecode_walkVType_bits_vma, io_toDecode_walkVType_bits_vta,
          io_toDecode_walkVType_bits_vsew, io_toDecode_walkVType_bits_vlmul} = walk_vtype;
  assign {io_toDecode_commitVType_vtype_bits_illegal, io_toDecode_commitVType_vtype_bits_vma,
          io_toDecode_commitVType_vtype_bits_vta, io_toDecode_commitVType_vtype_bits_vsew,
          io_toDecode_commitVType_vtype_bits_vlmul} = commit_vtype;

endmodule
