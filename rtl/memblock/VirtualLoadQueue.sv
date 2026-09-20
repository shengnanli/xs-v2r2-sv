// VirtualLoadQueue.sv — LSU 的"虚拟" load 队列：lqIdx 的唯一所有者
//
// 在流水线里的位置：dispatch ──enq──> VirtualLoadQueue <──ldin── load unit s3
//                                        │
//                                        └─ ldWbPtr / lqDeq / lqCancelCnt ─> LoadQueue 其余子队列
//
// 它**不存数据**，只存每条 load 的"身份与生命周期"：
//   allocated / robIdx / uopIdx / isvec / committed，共 72 个条目。
// LoadQueueReplay / RAR / RAW / Uncache 四个子队列各自存自己的负载，但**共用**
// 这里分配的 lqIdx 索引空间；ldWbPtr（= deqPtr）告诉它们"队头在哪、哪些已经退役"。
//
// 三条主线：
//   1. 入队：dispatch 一拍最多 6 条请求，每条带 numLsElem（向量 load 会占多个 lqIdx）。
//      条目 i 是否被这一拍写入，靠"i 落在某条请求的 [lqIdx, lqIdx+numLsElem) 区间内"判定，
//      而不是靠指针自增 —— 区间可能绕回队尾（enqCrossLoop）。
//   2. 完成：标量 load 在 s3 无需 replay 时直接置 committed；向量 load 等 vecCommit 反馈。
//   3. 退役：队头连续 CommitWidth(=8) 个 allocated&&committed 的条目一次性释放，
//      deqPtr 前进，io_lqDeq 报告这一拍退了几个。
//   redirect（分支预测失败/异常）把 robIdx 在重定向点之后的条目整片作废，
//   并把 enqPtr 回卷 redirectCancelCount 个位置。
//
// ── golden 结构实测（G1-canonical，14257 行 / 122 端口 / 0 子模块）────────────
// Scala 只有 302 行，14257 行全部来自 firtool 把 72 条目 × 6 入队端口的
// 判定网络完全展平。经 firtool DCE 后**实际存在**的寄存器只有下面这些：
//   allocated[72] isvec[72] committed[72] uopIdx[72][7] robIdx[72][1+8]
//   lastNeedCancel[72] enqPtr(8) deqPtr(8) 及 8 个标量 = 1483 个触发器位。
// golden 里 **不存在** 的（Scala 有、被 DCE 掉了，本文件因此也不写）：
//   · debug_mmio / debug_paddr —— 只写不读的调试阵列，firtool 整片删掉
//   · enqPtrExt(1..5) —— 只喂自己，对外不可观测，只剩 enqPtrExt(0)
//   · io.lqFull / io.enq.resp / io.ldin.ready —— 端口都没生成
// 这三处是"照抄 golden"而不是"照抄 Scala"，删了才等价。
//
// ★ELAB-147★：LQ_SIZE=72 不是 2 的幂，下标声明位宽 7 位（可表示 0..127 > 71），
// Formality 对任何"信号下标"直接判越界、set_top 失败。所以条目访问一律
// `for` + 下标比较，本文件里没有一处用信号直接索引数组。
//
// bug-for-bug：与 golden 逐位等价（Formality），包括下面这些"看着像 bug"的地方：
//   · io_lqCancelCnt 是 8 位内部计数器截断到 7 位输出
//   · commitCount 在 8 个候选全部就绪时走 PriorityEncoderOH(0)-1 = 全 1 这条路
//   · enq 的 numLsElem=0 时区间为空，条目不会被写入，但 enqPtr 照样不动

package virtualloadqueue_pkg;

  // ---- KunminghuV2Config 下的配置常量（全部由 golden 端口/常量反推核实）----
  localparam int LQ_SIZE      = 72;  // VirtualLoadQueueSize（非 2 的幂）
  localparam int LQ_PTR_W     = 7;   // log2Up(72)
  localparam int ROB_PTR_W    = 8;   // log2Up(RobSize=256)
  localparam int UOP_IDX_W    = 7;
  localparam int ENQ_W        = 6;   // LSQLdEnqWidth：dispatch 一拍最多 6 条
  localparam int LD_PIPE_W    = 3;   // LoadPipelineWidth
  localparam int VEC_LD_W     = 2;   // VecLoadPipelineWidth
  localparam int COMMIT_W     = 8;   // CommitWidth == DeqPtrMoveStride
  localparam int FU_TYPE_W    = 35;
  localparam int ELEM_IDX_W   = 5;   // numLsElem 端口宽度
  localparam int FLOW_W       = 8;   // elemIdxBits：numLsElem 参与累加时的宽度
  localparam int REP_CAUSE_N  = 11;  // rep_info.cause 的位数
  localparam int LQ_DEQ_W     = 4;   // log2Up(CommitWidth+1)
  localparam int LQ_CNT_W     = 7;   // log2Up(VirtualLoadQueueSize+1)

  // FuType 的向量 load 位：isVLoad = fuType[vldu] | fuType[vsegldu]
  localparam int FU_VLDU      = 31;
  localparam int FU_VSEGLDU   = 33;

  // 队列允许入队的水位：validCount <= LQ_SIZE - ENQ_W
  localparam int ENQ_WATERMARK = LQ_SIZE - ENQ_W;  // 66

  // ---- 环形队列指针（utility.CircularQueuePtr）----------------------------
  // flag 是"绕了奇数圈"标志：{flag,value} 一起才能区分空与满。
  typedef struct packed {
    logic                 flag;
    logic [LQ_PTR_W-1:0]  value;
  } lq_ptr_t;

  typedef struct packed {
    logic                 flag;
    logic [ROB_PTR_W-1:0] value;
  } rob_ptr_t;

  typedef logic [UOP_IDX_W-1:0] uop_idx_t;

  // dispatch 送来的一条入队请求
  typedef struct packed {
    logic                  valid;
    logic [FU_TYPE_W-1:0]  fuType;     // one-hot 功能单元类型，本模块只看两位
    uop_idx_t              uopIdx;     // 向量指令内部的 uop 序号
    rob_ptr_t              robIdx;
    lq_ptr_t               lqIdx;      // dispatch 已经算好的起始 lqIdx
    logic [ELEM_IDX_W-1:0] numLsElem;  // 这条指令占几个 lqIdx（标量=1）
  } lq_enq_req_t;

  // load unit s3 的写回
  typedef struct packed {
    logic                    valid;
    logic [LQ_PTR_W-1:0]     lqIdx_value;
    logic                    isvec;
    logic                    updateAddrValid;
    logic [REP_CAUSE_N-1:0]  rep_cause;  // 非 0 = 需要 replay，这次不算完成
  } ld_wb_t;

  // 向量 load 的提交反馈
  typedef struct packed {
    logic      valid;
    rob_ptr_t  robidx;
    uop_idx_t  uopidx;
  } vec_commit_t;

  // ---- 环形指针算术 ------------------------------------------------------
  // 深度不是 2 的幂，所以 value 不能靠自然溢出回绕：加完先减 LQ_SIZE，
  // 减得动（差 >= 0）就说明绕了一圈 —— 取差值并翻转 flag。
  // v 统一给 8 位：golden 各调用点的 v 宽度是 3/4/5/8 位，但 value+v 在任何
  // 一处都不会溢出各自的中间宽度，用统一的 9 位和 10 位差做完全等价。
  function automatic lq_ptr_t lq_ptr_add(input lq_ptr_t p, input logic [FLOW_W-1:0] v);
    logic [8:0]  sum;
    logic [9:0]  diff;
    logic        wrapped;
    lq_ptr_t     r;
    sum     = {2'b00, p.value} + {1'b0, v};
    diff    = {1'b0, sum} - 10'(LQ_SIZE);
    wrapped = ~diff[9];                       // diff >= 0
    r.value = wrapped ? diff[LQ_PTR_W-1:0] : sum[LQ_PTR_W-1:0];
    r.flag  = wrapped ^ p.flag;
    return r;
  endfunction

  // 减法照 golden 的实现走"先加 (LQ_SIZE - v) 再翻 flag"，不是直接减 ——
  // 两者在 v > LQ_SIZE 时结果不同，这里必须跟 golden 一致。
  function automatic lq_ptr_t lq_ptr_sub(input lq_ptr_t p, input logic [FLOW_W-1:0] v);
    lq_ptr_t flipped;
    lq_ptr_t r;
    flipped = lq_ptr_add(p, FLOW_W'(LQ_SIZE) - v);
    r.flag  = ~flipped.flag;
    r.value = flipped.value;
    return r;
  endfunction

  // left 在 right 之后？（同圈比 value，异圈反过来）
  function automatic logic lq_ptr_after(input lq_ptr_t l, input lq_ptr_t r);
    return (l.flag ^ r.flag) ^ (l.value > r.value);
  endfunction

  // RobPtr 的同名比较，用于 redirect 判定
  function automatic logic rob_ptr_after(input rob_ptr_t l, input rob_ptr_t r);
    return (l.flag ^ r.flag) ^ (l.value > r.value);
  endfunction

  // 这条 rob 表项是否被这次 redirect 冲掉：
  //   level=1（flush，含自身）时，等于重定向点本身也要冲；否则只冲它之后的。
  function automatic logic rob_need_flush(input rob_ptr_t self,
                                          input logic     redirect_valid,
                                          input rob_ptr_t redirect_robIdx,
                                          input logic     redirect_level);
    return redirect_valid &&
           ((redirect_level && self == redirect_robIdx) ||
            rob_ptr_after(self, redirect_robIdx));
  endfunction

endpackage


module xs_VirtualLoadQueue_core
  import virtualloadqueue_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,

  // ---- redirect：分支预测失败 / 异常冲刷 ----
  input  logic                          redirect_valid,
  input  rob_ptr_t                      redirect_robIdx,
  input  logic                          redirect_level,

  // ---- 向量 load 的提交反馈（按 {robIdx, uopIdx} 精确定位条目）----
  input  vec_commit_t [VEC_LD_W-1:0]    vecCommit,

  // ---- dispatch 入队 ----
  output logic                          enq_canAccept,
  input  logic                          enq_sqCanAccept,
  // needAlloc 只有 0..4 五个端口：第 5 个在 golden 里被 DCE 掉了（见文件头），
  // 它唯一的用处是算 validVLoadOffsetRShift，而那个量只喂 XSError 断言。
  input  logic [ENQ_W-2:0]              enq_needAlloc,
  input  lq_enq_req_t [ENQ_W-1:0]       enq_req,

  // ---- load unit s3 写回 ----
  input  ld_wb_t [LD_PIPE_W-1:0]        ldin,

  // ---- 状态输出 ----
  output lq_ptr_t                       ldWbPtr,      // = deqPtr，给 Replay/RAR 用
  output logic                          lqEmpty,
  output logic [LQ_DEQ_W-1:0]           lqDeq,        // 这一拍退了几个
  output logic [LQ_CNT_W-1:0]           lqCancelCnt,  // redirect 作废了几个
  output rob_ptr_t                      lqDeqRobIdx,  // 队头条目的 robIdx
  output uop_idx_t                      lqDeqUopIdx   // 队头条目的 uopIdx
);

  // ======================================================================
  // 条目存储：per-field 数组（SoA），与 golden 的扁平命名一一对应
  // ======================================================================
  logic                  allocated       [LQ_SIZE];  // 该槽已分配给某条 load
  logic                  isvec           [LQ_SIZE];  // 是向量 load 的一个 flow
  logic                  committed       [LQ_SIZE];  // 已完成，可以退役
  uop_idx_t              uopIdx          [LQ_SIZE];
  logic                  robIdx_flag     [LQ_SIZE];
  logic [ROB_PTR_W-1:0]  robIdx_value    [LQ_SIZE];

  // 上一拍的 needCancel 快照，用来数这次 redirect 一共作废了多少条
  logic                  lastNeedCancel  [LQ_SIZE];

  // ======================================================================
  // 指针与控制寄存器
  // ======================================================================
  lq_ptr_t             enqPtr_q;        // golden: enqPtrExt_0
  lq_ptr_t             deqPtr_q;        // golden: deqPtr_r
  logic                lastCycleRedirectValid;
  logic                lastLastCycleRedirectValid;
  logic [FLOW_W-1:0]   lastEnqCancel;      // 上一拍被 redirect 打掉的入队 flow 数
  logic [FLOW_W-1:0]   redirectCancelCount;
  logic [LQ_DEQ_W-1:0] lastCommitCount;    // commitCount 打一拍
  logic [LQ_DEQ_W-1:0] lqDeq_q;            // lastCommitCount 再打一拍
  logic                lqEmpty_q;

  // ======================================================================
  // 组合逻辑
  // ======================================================================
  logic [LQ_CNT_W-1:0]      validCount;
  logic                     allowEnqueue;
  logic                     needCancel      [LQ_SIZE];
  logic [ENQ_W-1:0]         enqCancel;
  logic [FLOW_W-1:0]        enqCancelNumber;
  logic [FLOW_W-1:0]        enqNumber;
  logic [LQ_CNT_W-1:0]      lastCycleCancelCount;
  lq_ptr_t                  enqPtrNextRaw;   // 未夹到 deqPtrNext 之前的下一拍 enqPtr
  lq_ptr_t                  enqPtrNext;
  lq_ptr_t                  deqPtrNext;

  lq_ptr_t                  deqLookupVec       [COMMIT_W];
  logic                     deqEntryAllocated  [COMMIT_W];
  logic                     deqEntryCommitted  [COMMIT_W];
  logic                     deqEntryNeedCancel [COMMIT_W];
  logic [COMMIT_W-1:0]      deqCountMask;
  logic [COMMIT_W-1:0]      deqNotReady;
  logic [COMMIT_W-1:0]      firstNotReadyOH;
  logic [COMMIT_W-1:0]      retireMask;
  logic [LQ_DEQ_W-1:0]      commitCount;

  logic                     entryCanEnq    [LQ_SIZE];
  logic [ENQ_W-1:0]         entryCanEnqSeq [LQ_SIZE];
  lq_enq_req_t              selectBits     [LQ_SIZE];
  logic                     vecLdCommit    [LQ_SIZE];
  logic                     entryRetiring  [LQ_SIZE];  // 这一拍被 commitCount 释放
  logic                     ldinCommit     [LQ_SIZE];  // 这一拍被 s3 写回置 committed

  // ----------------------------------------------------------------------
  // 水位：enqPtr 与 deqPtr 之间的距离就是在队条目数
  // ----------------------------------------------------------------------
  always_comb begin
    if (enqPtr_q.flag == deqPtr_q.flag)
      validCount = enqPtr_q.value - deqPtr_q.value;
    else
      validCount = LQ_CNT_W'(LQ_SIZE) + enqPtr_q.value - deqPtr_q.value;
  end
  assign allowEnqueue  = validCount <= LQ_CNT_W'(ENQ_WATERMARK);
  assign enq_canAccept = allowEnqueue;

  // ----------------------------------------------------------------------
  // redirect：哪些在队条目要被作废
  // ----------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < LQ_SIZE; i++)
      needCancel[i] = rob_need_flush(rob_ptr_t'{flag: robIdx_flag[i], value: robIdx_value[i]},
                                     redirect_valid, redirect_robIdx, redirect_level)
                      && allocated[i];
  end

  // 正要入队、但自己就在被冲刷范围里的请求：不许进队，并且要从 enqPtr 里扣回来
  always_comb begin
    enqCancel       = '0;
    enqCancelNumber = '0;
    for (int j = 0; j < ENQ_W; j++) begin
      enqCancel[j] = enq_req[j].valid &&
                     rob_need_flush(enq_req[j].robIdx, redirect_valid,
                                    redirect_robIdx, redirect_level);
      if (enqCancel[j]) enqCancelNumber += FLOW_W'(enq_req[j].numLsElem);
    end
  end

  always_comb begin
    lastCycleCancelCount = '0;
    for (int i = 0; i < LQ_SIZE; i++)
      lastCycleCancelCount += LQ_CNT_W'(lastNeedCancel[i]);
  end

  // ----------------------------------------------------------------------
  // enqPtr 更新
  //   · redirect 后隔两拍回卷 redirectCancelCount 个位置
  //   · 平时按这一拍实际入队的 flow 总数前进
  //   · 回卷过头（跑到 deqPtrNext 之前）时夹到 deqPtrNext
  // ----------------------------------------------------------------------
  always_comb begin
    enqNumber = '0;
    for (int j = 0; j < ENQ_W; j++)
      if (enq_req[j].valid) enqNumber += FLOW_W'(enq_req[j].numLsElem);
  end

  assign enqPtrNextRaw = lastLastCycleRedirectValid
                       ? lq_ptr_sub(enqPtr_q, redirectCancelCount)
                       : lq_ptr_add(enqPtr_q, enqNumber);
  // golden 这里写的是 deqPtrNext + 0.U（enq 端口 0 的那一项），加 0 是恒等变换，
  // 但为了和 golden 逐位对齐，照样走一次环形加法。
  assign enqPtrNext = lq_ptr_after(enqPtrNextRaw, deqPtrNext)
                    ? enqPtrNextRaw
                    : lq_ptr_add(deqPtrNext, FLOW_W'(0));

  // ----------------------------------------------------------------------
  // deqPtr 更新：从队头看 CommitWidth 个槽，取"连续就绪"的前缀长度
  // ----------------------------------------------------------------------
  always_comb begin
    for (int k = 0; k < COMMIT_W; k++) begin
      deqLookupVec[k]       = lq_ptr_add(deqPtr_q, FLOW_W'(k));
      deqEntryAllocated[k]  = 1'b0;
      deqEntryCommitted[k]  = 1'b0;
      deqEntryNeedCancel[k] = 1'b0;
      // ★下标必须是循环变量★（ELAB-147）：用比较代替 allocated[ptr.value]
      for (int i = 0; i < LQ_SIZE; i++) begin
        if (LQ_PTR_W'(i) == deqLookupVec[k].value) begin
          deqEntryAllocated[k]  = allocated[i];
          deqEntryCommitted[k]  = committed[i];
          deqEntryNeedCancel[k] = needCancel[i];
        end
      end
    end
  end

  always_comb begin
    for (int k = 0; k < COMMIT_W; k++)
      // 追到 enqPtr 就停：那之后的槽还没分配出去
      deqCountMask[k] = deqEntryAllocated[k] && deqEntryCommitted[k]
                        && (deqLookupVec[k] != enqPtr_q)
                        && !deqEntryNeedCancel[k];
  end

  // commitCount = deqCountMask 的连续低位 1 的个数。
  // golden 用 PopCount(PriorityEncoderOH(~mask) - 1) 实现：找到第一个"不就绪"的槽，
  // 它下面的位就是可退役的前缀。全就绪时 PriorityEncoderOH(0)=0，0-1 = 全 1 ⇒ 8。
  assign deqNotReady = ~deqCountMask;
  always_comb begin
    firstNotReadyOH = '0;
    for (int k = COMMIT_W-1; k >= 0; k--)   // 倒着扫，最后写进去的是最低位那个
      if (deqNotReady[k]) firstNotReadyOH = COMMIT_W'(1) << k;
  end
  assign retireMask = firstNotReadyOH - COMMIT_W'(1);
  always_comb begin
    commitCount = '0;
    for (int k = 0; k < COMMIT_W; k++) commitCount += LQ_DEQ_W'(retireMask[k]);
  end

  assign deqPtrNext = lq_ptr_add(deqPtr_q, FLOW_W'(lastCommitCount));

  // 这一拍哪些槽因为退役而被释放（同样只能用循环变量下标）
  always_comb begin
    for (int i = 0; i < LQ_SIZE; i++) entryRetiring[i] = 1'b0;
    for (int k = 0; k < COMMIT_W; k++)
      if (commitCount > LQ_DEQ_W'(k))
        for (int i = 0; i < LQ_SIZE; i++)
          if (LQ_PTR_W'(i) == deqLookupVec[k].value) entryRetiring[i] = 1'b1;
  end

  // ----------------------------------------------------------------------
  // 入队判定：条目 i 落在第 j 条请求的 [lqIdx, lqIdx+numLsElem) 区间里吗？
  // 区间可能绕过队尾（起止 flag 不同），那时判据要取"或"。
  // ----------------------------------------------------------------------
  lq_ptr_t enqLowBound [ENQ_W];
  lq_ptr_t enqUpBound  [ENQ_W];
  logic    enqCrossLoop[ENQ_W];

  always_comb begin
    for (int j = 0; j < ENQ_W; j++) begin
      enqLowBound[j]  = enq_req[j].lqIdx;
      enqUpBound[j]   = lq_ptr_add(enq_req[j].lqIdx, FLOW_W'(enq_req[j].numLsElem));
      enqCrossLoop[j] = enqLowBound[j].flag != enqUpBound[j].flag;
    end
  end

  logic hitBound;
  always_comb begin
    for (int i = 0; i < LQ_SIZE; i++) begin
      entryCanEnq[i]    = 1'b0;
      entryCanEnqSeq[i] = '0;
      selectBits[i]     = enq_req[ENQ_W-1];   // 优先级链兜底项（golden 同）
      for (int j = 0; j < ENQ_W; j++) begin
        hitBound = enqCrossLoop[j]
                 ? (enqLowBound[j].value <= LQ_PTR_W'(i) || LQ_PTR_W'(i) < enqUpBound[j].value)
                 : (enqLowBound[j].value <= LQ_PTR_W'(i) && LQ_PTR_W'(i) < enqUpBound[j].value);
        entryCanEnqSeq[i][j] = enq_req[j].valid && !enqCancel[j] && hitBound;
      end
      // ParallelPriorityMux：端口号小的优先（倒着扫让最小的那个最后写进去）
      for (int j = ENQ_W-1; j >= 0; j--)
        if (entryCanEnqSeq[i][j]) selectBits[i] = enq_req[j];
      entryCanEnq[i] = |entryCanEnqSeq[i];
    end
  end

  // ----------------------------------------------------------------------
  // 完成标记：向量 load 按 {robIdx, uopIdx} 反查条目；标量 load 由 s3 直接点名
  // ----------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < LQ_SIZE; i++) begin
      vecLdCommit[i] = 1'b0;
      for (int j = 0; j < VEC_LD_W; j++)
        if (allocated[i] && vecCommit[j].valid
            && rob_ptr_t'{flag: robIdx_flag[i], value: robIdx_value[i]} == vecCommit[j].robidx
            && uopIdx[i] == vecCommit[j].uopidx)
          vecLdCommit[i] = 1'b1;
    end
  end

  always_comb begin
    for (int i = 0; i < LQ_SIZE; i++) ldinCommit[i] = 1'b0;
    for (int p = 0; p < LD_PIPE_W; p++)
      // 需要 replay 就不算完成；向量 load 走 vecCommit 那条路，这里不管
      if (ldin[p].valid && ldin[p].rep_cause == '0
          && ldin[p].updateAddrValid && !ldin[p].isvec)
        for (int i = 0; i < LQ_SIZE; i++)
          if (LQ_PTR_W'(i) == ldin[p].lqIdx_value) ldinCommit[i] = 1'b1;
  end

  // ======================================================================
  // 时序：两个复位域，与 golden 的两个 always 块逐个寄存器对齐
  //   · 异步复位域：allocated / isvec / lastNeedCancel / 两个指针 / 各计数器
  //   · 无复位域  ：committed / uopIdx / robIdx / 三个打拍寄存器
  // ======================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin                       // ★VLOG-144：复位判断必须是块首第一条★
      for (int i = 0; i < LQ_SIZE; i++) begin
        allocated[i]      <= 1'b0;
        isvec[i]          <= 1'b0;
        lastNeedCancel[i] <= 1'b0;
      end
      enqPtr_q            <= lq_ptr_t'{flag: 1'b0, value: '0};
      deqPtr_q            <= lq_ptr_t'{flag: 1'b0, value: '0};
      lastEnqCancel       <= '0;
      redirectCancelCount <= '0;
      lastCommitCount     <= '0;
      lqDeq_q             <= '0;
    end
    else begin
      for (int i = 0; i < LQ_SIZE; i++) begin
        // 优先级（低 -> 高）：保持 < 入队置位 < 退役清除 < redirect 作废
        allocated[i] <= !needCancel[i] && !entryRetiring[i]
                        && (entryCanEnq[i] || allocated[i]);
        if (entryCanEnq[i])
          isvec[i] <= selectBits[i].fuType[FU_VLDU] | selectBits[i].fuType[FU_VSEGLDU];
        lastNeedCancel[i] <= needCancel[i];
      end
      enqPtr_q <= enqPtrNext;
      lastEnqCancel <= enqCancelNumber;
      // 作废总数 = 上一拍在队被冲掉的 + 上一拍正要入队被挡回去的
      if (lastCycleRedirectValid)
        redirectCancelCount <= FLOW_W'({1'b0, lastCycleCancelCount}) + lastEnqCancel;
      lastCommitCount <= commitCount;
      if (lastCommitCount != '0) deqPtr_q <= deqPtrNext;
      lqDeq_q <= lastCommitCount;
    end
  end

  always_ff @(posedge clock) begin
    for (int i = 0; i < LQ_SIZE; i++) begin
      if (entryCanEnq[i]) begin
        robIdx_flag[i]  <= selectBits[i].robIdx.flag;
        robIdx_value[i] <= selectBits[i].robIdx.value;
        uopIdx[i]       <= selectBits[i].uopIdx;
      end
      // 优先级（低 -> 高）：入队清零 < 向量提交置位 < 标量写回置位
      committed[i] <= ldinCommit[i]
                   || (vecLdCommit[i] && isvec[i])
                   || (!entryCanEnq[i] && committed[i]);
    end
    lastCycleRedirectValid     <= redirect_valid;
    lastLastCycleRedirectValid <= lastCycleRedirectValid;
    lqEmpty_q                  <= (validCount == '0);
  end

  // ======================================================================
  // 输出
  // ======================================================================
  assign ldWbPtr     = deqPtr_q;
  assign lqEmpty     = lqEmpty_q;
  assign lqDeq       = lqDeq_q;
  assign lqCancelCnt = redirectCancelCount[LQ_CNT_W-1:0];  // 8 位计数器截到 7 位

  always_comb begin
    lqDeqRobIdx = '0;
    lqDeqUopIdx = '0;
    for (int i = 0; i < LQ_SIZE; i++)
      if (LQ_PTR_W'(i) == deqPtr_q.value) begin
        lqDeqRobIdx = rob_ptr_t'{flag: robIdx_flag[i], value: robIdx_value[i]};
        lqDeqUopIdx = uopIdx[i];
      end
  end

`ifndef SYNTHESIS
  // ------------------------------------------------------------------
  // 只在非综合视图存在的一致性检查（golden 的 XSError，VirtualLoadQueue.scala:125/198/199）。
  // FM 与 UT 两侧都带 +define SYNTHESIS 读入，所以这一段在两种验收里都被编译掉 ——
  // golden 也是同样处理。它留在这里是为了讲清 enq_needAlloc / enq_sqCanAccept
  // 这两组端口的用途：它们**只**服务于这些断言，综合视图里没有读者。
  //
  // dispatch 侧算出的 lqIdx 必须与本模块按 needAlloc 前缀和推出来的一致。
  logic [FLOW_W-1:0] validVLoadOffset      [ENQ_W-1];  // 只有 0..4（needAlloc_5 被 DCE）
  logic [FLOW_W-1:0] validVLoadOffsetRShift[ENQ_W];
  lq_ptr_t           expectedLqIdx         [ENQ_W];
  logic [FLOW_W-1:0] lqIdxAcc;

  always_comb begin
    for (int j = 0; j < ENQ_W-1; j++)
      validVLoadOffset[j] = enq_needAlloc[j] ? FLOW_W'(enq_req[j].numLsElem) : FLOW_W'(0);
    validVLoadOffsetRShift[0] = FLOW_W'(0);
    for (int j = 1; j < ENQ_W; j++)
      validVLoadOffsetRShift[j] = validVLoadOffset[j-1];
    for (int j = 0; j < ENQ_W; j++) begin
      lqIdxAcc = FLOW_W'(0);
      for (int k = 0; k <= j; k++) lqIdxAcc += validVLoadOffsetRShift[k];
      expectedLqIdx[j] = lq_ptr_add(enqPtr_q, lqIdxAcc);
    end
  end

  always_ff @(posedge clock) begin
    if (!reset) begin
      if (lastCycleRedirectValid && enqNumber != '0)
        $display("[VirtualLoadQueue] redirect 那一拍不应该还有入队 (enqNumber=%0d)", enqNumber);
      for (int j = 0; j < ENQ_W; j++) begin
        if (enq_req[j].valid && !enqCancel[j] && (!allowEnqueue || !enq_sqCanAccept))
          $display("[VirtualLoadQueue] must accept %0d", j);
        if (enq_req[j].valid && !enqCancel[j] && enq_req[j].lqIdx.value != expectedLqIdx[j].value)
          $display("[VirtualLoadQueue] must be the same entry %0d", j);
      end
    end
  end
`endif

endmodule


// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden 逐位同名同序，只做打包/改名
// ---------------------------------------------------------------------------
module VirtualLoadQueue (
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_vecCommit_0_valid,
  input         io_vecCommit_0_bits_robidx_flag,
  input  [7:0]  io_vecCommit_0_bits_robidx_value,
  input  [6:0]  io_vecCommit_0_bits_uopidx,
  input         io_vecCommit_1_valid,
  input         io_vecCommit_1_bits_robidx_flag,
  input  [7:0]  io_vecCommit_1_bits_robidx_value,
  input  [6:0]  io_vecCommit_1_bits_uopidx,
  output        io_enq_canAccept,
  input         io_enq_sqCanAccept,
  input         io_enq_needAlloc_0,
  input         io_enq_needAlloc_1,
  input         io_enq_needAlloc_2,
  input         io_enq_needAlloc_3,
  input         io_enq_needAlloc_4,
  input         io_enq_req_0_valid,
  input  [34:0] io_enq_req_0_bits_fuType,
  input  [6:0]  io_enq_req_0_bits_uopIdx,
  input         io_enq_req_0_bits_robIdx_flag,
  input  [7:0]  io_enq_req_0_bits_robIdx_value,
  input         io_enq_req_0_bits_lqIdx_flag,
  input  [6:0]  io_enq_req_0_bits_lqIdx_value,
  input  [4:0]  io_enq_req_0_bits_numLsElem,
  input         io_enq_req_1_valid,
  input  [34:0] io_enq_req_1_bits_fuType,
  input  [6:0]  io_enq_req_1_bits_uopIdx,
  input         io_enq_req_1_bits_robIdx_flag,
  input  [7:0]  io_enq_req_1_bits_robIdx_value,
  input         io_enq_req_1_bits_lqIdx_flag,
  input  [6:0]  io_enq_req_1_bits_lqIdx_value,
  input  [4:0]  io_enq_req_1_bits_numLsElem,
  input         io_enq_req_2_valid,
  input  [34:0] io_enq_req_2_bits_fuType,
  input  [6:0]  io_enq_req_2_bits_uopIdx,
  input         io_enq_req_2_bits_robIdx_flag,
  input  [7:0]  io_enq_req_2_bits_robIdx_value,
  input         io_enq_req_2_bits_lqIdx_flag,
  input  [6:0]  io_enq_req_2_bits_lqIdx_value,
  input  [4:0]  io_enq_req_2_bits_numLsElem,
  input         io_enq_req_3_valid,
  input  [34:0] io_enq_req_3_bits_fuType,
  input  [6:0]  io_enq_req_3_bits_uopIdx,
  input         io_enq_req_3_bits_robIdx_flag,
  input  [7:0]  io_enq_req_3_bits_robIdx_value,
  input         io_enq_req_3_bits_lqIdx_flag,
  input  [6:0]  io_enq_req_3_bits_lqIdx_value,
  input  [4:0]  io_enq_req_3_bits_numLsElem,
  input         io_enq_req_4_valid,
  input  [34:0] io_enq_req_4_bits_fuType,
  input  [6:0]  io_enq_req_4_bits_uopIdx,
  input         io_enq_req_4_bits_robIdx_flag,
  input  [7:0]  io_enq_req_4_bits_robIdx_value,
  input         io_enq_req_4_bits_lqIdx_flag,
  input  [6:0]  io_enq_req_4_bits_lqIdx_value,
  input  [4:0]  io_enq_req_4_bits_numLsElem,
  input         io_enq_req_5_valid,
  input  [34:0] io_enq_req_5_bits_fuType,
  input  [6:0]  io_enq_req_5_bits_uopIdx,
  input         io_enq_req_5_bits_robIdx_flag,
  input  [7:0]  io_enq_req_5_bits_robIdx_value,
  input         io_enq_req_5_bits_lqIdx_flag,
  input  [6:0]  io_enq_req_5_bits_lqIdx_value,
  input  [4:0]  io_enq_req_5_bits_numLsElem,
  input         io_ldin_0_valid,
  input  [6:0]  io_ldin_0_bits_uop_lqIdx_value,
  input         io_ldin_0_bits_isvec,
  input         io_ldin_0_bits_updateAddrValid,
  input         io_ldin_0_bits_rep_info_cause_0,
  input         io_ldin_0_bits_rep_info_cause_1,
  input         io_ldin_0_bits_rep_info_cause_2,
  input         io_ldin_0_bits_rep_info_cause_3,
  input         io_ldin_0_bits_rep_info_cause_4,
  input         io_ldin_0_bits_rep_info_cause_5,
  input         io_ldin_0_bits_rep_info_cause_6,
  input         io_ldin_0_bits_rep_info_cause_7,
  input         io_ldin_0_bits_rep_info_cause_8,
  input         io_ldin_0_bits_rep_info_cause_9,
  input         io_ldin_0_bits_rep_info_cause_10,
  input         io_ldin_1_valid,
  input  [6:0]  io_ldin_1_bits_uop_lqIdx_value,
  input         io_ldin_1_bits_isvec,
  input         io_ldin_1_bits_updateAddrValid,
  input         io_ldin_1_bits_rep_info_cause_0,
  input         io_ldin_1_bits_rep_info_cause_1,
  input         io_ldin_1_bits_rep_info_cause_2,
  input         io_ldin_1_bits_rep_info_cause_3,
  input         io_ldin_1_bits_rep_info_cause_4,
  input         io_ldin_1_bits_rep_info_cause_5,
  input         io_ldin_1_bits_rep_info_cause_6,
  input         io_ldin_1_bits_rep_info_cause_7,
  input         io_ldin_1_bits_rep_info_cause_8,
  input         io_ldin_1_bits_rep_info_cause_9,
  input         io_ldin_1_bits_rep_info_cause_10,
  input         io_ldin_2_valid,
  input  [6:0]  io_ldin_2_bits_uop_lqIdx_value,
  input         io_ldin_2_bits_isvec,
  input         io_ldin_2_bits_updateAddrValid,
  input         io_ldin_2_bits_rep_info_cause_0,
  input         io_ldin_2_bits_rep_info_cause_1,
  input         io_ldin_2_bits_rep_info_cause_2,
  input         io_ldin_2_bits_rep_info_cause_3,
  input         io_ldin_2_bits_rep_info_cause_4,
  input         io_ldin_2_bits_rep_info_cause_5,
  input         io_ldin_2_bits_rep_info_cause_6,
  input         io_ldin_2_bits_rep_info_cause_7,
  input         io_ldin_2_bits_rep_info_cause_8,
  input         io_ldin_2_bits_rep_info_cause_9,
  input         io_ldin_2_bits_rep_info_cause_10,
  output        io_ldWbPtr_flag,
  output [6:0]  io_ldWbPtr_value,
  output        io_lqEmpty,
  output [3:0]  io_lqDeq,
  output [6:0]  io_lqCancelCnt,
  output        io_lqDeqRobIdx_flag,
  output [7:0]  io_lqDeqRobIdx_value,
  output [6:0]  io_lqDeqUopIdx
);

  import virtualloadqueue_pkg::*;

  // golden 的端口是被 firtool 完全展平的标量；这里按语义重新打包成
  // 结构体/数组交给可读核。打包顺序：拼接式里下标大的在左。
  lq_ptr_t     ldWbPtr_w;
  rob_ptr_t    lqDeqRobIdx_w;

  xs_VirtualLoadQueue_core u_core (
    .clock            (clock),
    .reset            (reset),

    .redirect_valid   (io_redirect_valid),
    .redirect_robIdx  (rob_ptr_t'{flag:  io_redirect_bits_robIdx_flag,
                                 value: io_redirect_bits_robIdx_value}),
    .redirect_level   (io_redirect_bits_level),

    .vecCommit        ({vec_commit_t'{valid:  io_vecCommit_1_valid,
                                      robidx: rob_ptr_t'{flag:  io_vecCommit_1_bits_robidx_flag,
                                                value: io_vecCommit_1_bits_robidx_value},
                                      uopidx: io_vecCommit_1_bits_uopidx},
                        vec_commit_t'{valid:  io_vecCommit_0_valid,
                                      robidx: rob_ptr_t'{flag:  io_vecCommit_0_bits_robidx_flag,
                                                value: io_vecCommit_0_bits_robidx_value},
                                      uopidx: io_vecCommit_0_bits_uopidx}}),

    .enq_canAccept    (io_enq_canAccept),
    .enq_sqCanAccept  (io_enq_sqCanAccept),
    .enq_needAlloc    ({io_enq_needAlloc_4, io_enq_needAlloc_3, io_enq_needAlloc_2,
                        io_enq_needAlloc_1, io_enq_needAlloc_0}),
    .enq_req          ({lq_enq_req_t'{valid:     io_enq_req_5_valid,
                                      fuType:    io_enq_req_5_bits_fuType,
                                      uopIdx:    io_enq_req_5_bits_uopIdx,
                                      robIdx:    rob_ptr_t'{flag:  io_enq_req_5_bits_robIdx_flag,
                                                   value: io_enq_req_5_bits_robIdx_value},
                                      lqIdx:     lq_ptr_t'{flag:  io_enq_req_5_bits_lqIdx_flag,
                                                   value: io_enq_req_5_bits_lqIdx_value},
                                      numLsElem: io_enq_req_5_bits_numLsElem},
                        lq_enq_req_t'{valid:     io_enq_req_4_valid,
                                      fuType:    io_enq_req_4_bits_fuType,
                                      uopIdx:    io_enq_req_4_bits_uopIdx,
                                      robIdx:    rob_ptr_t'{flag:  io_enq_req_4_bits_robIdx_flag,
                                                   value: io_enq_req_4_bits_robIdx_value},
                                      lqIdx:     lq_ptr_t'{flag:  io_enq_req_4_bits_lqIdx_flag,
                                                   value: io_enq_req_4_bits_lqIdx_value},
                                      numLsElem: io_enq_req_4_bits_numLsElem},
                        lq_enq_req_t'{valid:     io_enq_req_3_valid,
                                      fuType:    io_enq_req_3_bits_fuType,
                                      uopIdx:    io_enq_req_3_bits_uopIdx,
                                      robIdx:    rob_ptr_t'{flag:  io_enq_req_3_bits_robIdx_flag,
                                                   value: io_enq_req_3_bits_robIdx_value},
                                      lqIdx:     lq_ptr_t'{flag:  io_enq_req_3_bits_lqIdx_flag,
                                                   value: io_enq_req_3_bits_lqIdx_value},
                                      numLsElem: io_enq_req_3_bits_numLsElem},
                        lq_enq_req_t'{valid:     io_enq_req_2_valid,
                                      fuType:    io_enq_req_2_bits_fuType,
                                      uopIdx:    io_enq_req_2_bits_uopIdx,
                                      robIdx:    rob_ptr_t'{flag:  io_enq_req_2_bits_robIdx_flag,
                                                   value: io_enq_req_2_bits_robIdx_value},
                                      lqIdx:     lq_ptr_t'{flag:  io_enq_req_2_bits_lqIdx_flag,
                                                   value: io_enq_req_2_bits_lqIdx_value},
                                      numLsElem: io_enq_req_2_bits_numLsElem},
                        lq_enq_req_t'{valid:     io_enq_req_1_valid,
                                      fuType:    io_enq_req_1_bits_fuType,
                                      uopIdx:    io_enq_req_1_bits_uopIdx,
                                      robIdx:    rob_ptr_t'{flag:  io_enq_req_1_bits_robIdx_flag,
                                                   value: io_enq_req_1_bits_robIdx_value},
                                      lqIdx:     lq_ptr_t'{flag:  io_enq_req_1_bits_lqIdx_flag,
                                                   value: io_enq_req_1_bits_lqIdx_value},
                                      numLsElem: io_enq_req_1_bits_numLsElem},
                        lq_enq_req_t'{valid:     io_enq_req_0_valid,
                                      fuType:    io_enq_req_0_bits_fuType,
                                      uopIdx:    io_enq_req_0_bits_uopIdx,
                                      robIdx:    rob_ptr_t'{flag:  io_enq_req_0_bits_robIdx_flag,
                                                   value: io_enq_req_0_bits_robIdx_value},
                                      lqIdx:     lq_ptr_t'{flag:  io_enq_req_0_bits_lqIdx_flag,
                                                   value: io_enq_req_0_bits_lqIdx_value},
                                      numLsElem: io_enq_req_0_bits_numLsElem}}),

    .ldin             ({ld_wb_t'{valid:           io_ldin_2_valid,
                                 lqIdx_value:     io_ldin_2_bits_uop_lqIdx_value,
                                 isvec:           io_ldin_2_bits_isvec,
                                 updateAddrValid: io_ldin_2_bits_updateAddrValid,
                                 rep_cause:       {io_ldin_2_bits_rep_info_cause_10,
                                                   io_ldin_2_bits_rep_info_cause_9,
                                                   io_ldin_2_bits_rep_info_cause_8,
                                                   io_ldin_2_bits_rep_info_cause_7,
                                                   io_ldin_2_bits_rep_info_cause_6,
                                                   io_ldin_2_bits_rep_info_cause_5,
                                                   io_ldin_2_bits_rep_info_cause_4,
                                                   io_ldin_2_bits_rep_info_cause_3,
                                                   io_ldin_2_bits_rep_info_cause_2,
                                                   io_ldin_2_bits_rep_info_cause_1,
                                                   io_ldin_2_bits_rep_info_cause_0}},
                        ld_wb_t'{valid:           io_ldin_1_valid,
                                 lqIdx_value:     io_ldin_1_bits_uop_lqIdx_value,
                                 isvec:           io_ldin_1_bits_isvec,
                                 updateAddrValid: io_ldin_1_bits_updateAddrValid,
                                 rep_cause:       {io_ldin_1_bits_rep_info_cause_10,
                                                   io_ldin_1_bits_rep_info_cause_9,
                                                   io_ldin_1_bits_rep_info_cause_8,
                                                   io_ldin_1_bits_rep_info_cause_7,
                                                   io_ldin_1_bits_rep_info_cause_6,
                                                   io_ldin_1_bits_rep_info_cause_5,
                                                   io_ldin_1_bits_rep_info_cause_4,
                                                   io_ldin_1_bits_rep_info_cause_3,
                                                   io_ldin_1_bits_rep_info_cause_2,
                                                   io_ldin_1_bits_rep_info_cause_1,
                                                   io_ldin_1_bits_rep_info_cause_0}},
                        ld_wb_t'{valid:           io_ldin_0_valid,
                                 lqIdx_value:     io_ldin_0_bits_uop_lqIdx_value,
                                 isvec:           io_ldin_0_bits_isvec,
                                 updateAddrValid: io_ldin_0_bits_updateAddrValid,
                                 rep_cause:       {io_ldin_0_bits_rep_info_cause_10,
                                                   io_ldin_0_bits_rep_info_cause_9,
                                                   io_ldin_0_bits_rep_info_cause_8,
                                                   io_ldin_0_bits_rep_info_cause_7,
                                                   io_ldin_0_bits_rep_info_cause_6,
                                                   io_ldin_0_bits_rep_info_cause_5,
                                                   io_ldin_0_bits_rep_info_cause_4,
                                                   io_ldin_0_bits_rep_info_cause_3,
                                                   io_ldin_0_bits_rep_info_cause_2,
                                                   io_ldin_0_bits_rep_info_cause_1,
                                                   io_ldin_0_bits_rep_info_cause_0}}}),

    .ldWbPtr          (ldWbPtr_w),
    .lqEmpty          (io_lqEmpty),
    .lqDeq            (io_lqDeq),
    .lqCancelCnt      (io_lqCancelCnt),
    .lqDeqRobIdx      (lqDeqRobIdx_w),
    .lqDeqUopIdx      (io_lqDeqUopIdx)
  );

  assign io_ldWbPtr_flag      = ldWbPtr_w.flag;
  assign io_ldWbPtr_value     = ldWbPtr_w.value;
  assign io_lqDeqRobIdx_flag  = lqDeqRobIdx_w.flag;
  assign io_lqDeqRobIdx_value = lqDeqRobIdx_w.value;

endmodule
