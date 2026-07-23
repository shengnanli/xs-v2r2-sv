// =============================================================================
//  xs_VirtualLoadQueue_core —— load 顺序主队列（可读重写）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/VirtualLoadQueue.scala
//
//  ── 功能概览 ──（详见 virtualloadqueue_pkg.sv 文件头）
//   按程序顺序为每条 load（含向量 flow）分配 entry，维护其 allocated/committed/isvec
//   等状态与 robIdx/uopIdx，用 enqPtr/deqPtr 维护顺序，提交时顺序前移 deqPtr，
//   redirect 时按 robIdx 取消并回退 enqPtr。
//
//  ── 寄存器结构与 golden 一一对应（FM signoff 要求 bug-for-bug）──
//   golden（firtool）把每条 entry 的字段展平成 72 个独立标量寄存器：
//     allocated_i / robIdx_i_flag / robIdx_i_value / uopIdx_i / isvec_i / committed_i
//   本核对应地用 72 深 SV 数组（robIdx_flag[i] 等），并用 fm_pins.tcl 把 golden 的
//   中缀下标名（robIdx_i_value）双射到本核数组名（robIdx_value[i]）。
//   指针只保留 enqPtrExt_0（golden 只寄存 enqPtrExt(0)，其余 (1..5) 组合派生）。
//   取消统计保留 72 个 lastNeedCancel_r（RegNext(needCancel)），popcount 组合算出，
//   与 golden 完全同构（不合并成计数寄存器）。
//
//  ── 本核分节（与 Scala 一一对应）──
//    A. 端口聚合（扁平 golden 端口 ↔ 数组）
//    B. 队列状态寄存器（allocated / 每字段数组）+ 指针寄存器（仅 enqPtrExt_0/deqPtr）
//    C. redirect 取消统计（needCancel / lastNeedCancel_r / enqCancel / redirectCancelCount）
//    D. enqPtr 更新（正常推进 / redirect 回退）——仅寄存 enqPtrExt_0，其余组合派生
//    E. deqPtr 更新（commitCount：连续 committed 计数；两拍打拍）
//    F. enqueue 写 entry（按 lqIdx 命中区间分配）
//    G. commit 清 allocated（deqPtr..+stride）
//    H. 向量 commit / writeback 置 committed
//    I. redirect 清 allocated
//    J. 全局输出（lqFull/lqEmpty/ldWbPtr/lqDeq/lqCancelCnt/perf）
// =============================================================================
module xs_VirtualLoadQueue_core
  import virtualloadqueue_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ---- 控制：全局 redirect（冲刷）----
  input  logic              io_redirect_valid,
  input  logic              io_redirect_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_redirect_bits_robIdx_value,
  input  logic              io_redirect_bits_level,

  // ---- 向量 commit（VecLoadPipelineWidth=2）----
  input  logic              io_vecCommit_0_valid,
  input  logic              io_vecCommit_0_bits_robidx_flag,
  input  logic [ROB_W-1:0]  io_vecCommit_0_bits_robidx_value,
  input  logic [UOP_W-1:0]  io_vecCommit_0_bits_uopidx,
  input  logic              io_vecCommit_1_valid,
  input  logic              io_vecCommit_1_bits_robidx_flag,
  input  logic [ROB_W-1:0]  io_vecCommit_1_bits_robidx_value,
  input  logic [UOP_W-1:0]  io_vecCommit_1_bits_uopidx,

  // ---- dispatch 入队（io.enq；req 口数=6，needAlloc=5）----
  output logic              io_enq_canAccept,
  input  logic              io_enq_sqCanAccept,
  input  logic              io_enq_needAlloc_0,
  input  logic              io_enq_needAlloc_1,
  input  logic              io_enq_needAlloc_2,
  input  logic              io_enq_needAlloc_3,
  input  logic              io_enq_needAlloc_4,
  input  logic              io_enq_req_0_valid,
  input  logic [FUTYPE_W-1:0] io_enq_req_0_bits_fuType,
  input  logic [UOP_W-1:0]  io_enq_req_0_bits_uopIdx,
  input  logic              io_enq_req_0_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_enq_req_0_bits_robIdx_value,
  input  logic              io_enq_req_0_bits_lqIdx_flag,
  input  logic [PTR_VW-1:0] io_enq_req_0_bits_lqIdx_value,
  input  logic [ELEM_W-1:0] io_enq_req_0_bits_numLsElem,
  input  logic              io_enq_req_1_valid,
  input  logic [FUTYPE_W-1:0] io_enq_req_1_bits_fuType,
  input  logic [UOP_W-1:0]  io_enq_req_1_bits_uopIdx,
  input  logic              io_enq_req_1_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_enq_req_1_bits_robIdx_value,
  input  logic              io_enq_req_1_bits_lqIdx_flag,
  input  logic [PTR_VW-1:0] io_enq_req_1_bits_lqIdx_value,
  input  logic [ELEM_W-1:0] io_enq_req_1_bits_numLsElem,
  input  logic              io_enq_req_2_valid,
  input  logic [FUTYPE_W-1:0] io_enq_req_2_bits_fuType,
  input  logic [UOP_W-1:0]  io_enq_req_2_bits_uopIdx,
  input  logic              io_enq_req_2_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_enq_req_2_bits_robIdx_value,
  input  logic              io_enq_req_2_bits_lqIdx_flag,
  input  logic [PTR_VW-1:0] io_enq_req_2_bits_lqIdx_value,
  input  logic [ELEM_W-1:0] io_enq_req_2_bits_numLsElem,
  input  logic              io_enq_req_3_valid,
  input  logic [FUTYPE_W-1:0] io_enq_req_3_bits_fuType,
  input  logic [UOP_W-1:0]  io_enq_req_3_bits_uopIdx,
  input  logic              io_enq_req_3_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_enq_req_3_bits_robIdx_value,
  input  logic              io_enq_req_3_bits_lqIdx_flag,
  input  logic [PTR_VW-1:0] io_enq_req_3_bits_lqIdx_value,
  input  logic [ELEM_W-1:0] io_enq_req_3_bits_numLsElem,
  input  logic              io_enq_req_4_valid,
  input  logic [FUTYPE_W-1:0] io_enq_req_4_bits_fuType,
  input  logic [UOP_W-1:0]  io_enq_req_4_bits_uopIdx,
  input  logic              io_enq_req_4_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_enq_req_4_bits_robIdx_value,
  input  logic              io_enq_req_4_bits_lqIdx_flag,
  input  logic [PTR_VW-1:0] io_enq_req_4_bits_lqIdx_value,
  input  logic [ELEM_W-1:0] io_enq_req_4_bits_numLsElem,
  input  logic              io_enq_req_5_valid,
  input  logic [FUTYPE_W-1:0] io_enq_req_5_bits_fuType,
  input  logic [UOP_W-1:0]  io_enq_req_5_bits_uopIdx,
  input  logic              io_enq_req_5_bits_robIdx_flag,
  input  logic [ROB_W-1:0]  io_enq_req_5_bits_robIdx_value,
  input  logic              io_enq_req_5_bits_lqIdx_flag,
  input  logic [PTR_VW-1:0] io_enq_req_5_bits_lqIdx_value,
  input  logic [ELEM_W-1:0] io_enq_req_5_bits_numLsElem,

  // ---- load 写回（LoadPipelineWidth=3，来自 ldu s3）----
  input  logic              io_ldin_0_valid,
  input  logic [PTR_VW-1:0] io_ldin_0_bits_uop_lqIdx_value,
  input  logic              io_ldin_0_bits_isvec,
  input  logic              io_ldin_0_bits_updateAddrValid,
  input  logic [10:0]       io_ldin_0_bits_rep_info_cause,
  input  logic              io_ldin_1_valid,
  input  logic [PTR_VW-1:0] io_ldin_1_bits_uop_lqIdx_value,
  input  logic              io_ldin_1_bits_isvec,
  input  logic              io_ldin_1_bits_updateAddrValid,
  input  logic [10:0]       io_ldin_1_bits_rep_info_cause,
  input  logic              io_ldin_2_valid,
  input  logic [PTR_VW-1:0] io_ldin_2_bits_uop_lqIdx_value,
  input  logic              io_ldin_2_bits_isvec,
  input  logic              io_ldin_2_bits_updateAddrValid,
  input  logic [10:0]       io_ldin_2_bits_rep_info_cause,

  // ---- 全局状态输出 ----
  output logic              io_ldWbPtr_flag,
  output logic [PTR_VW-1:0] io_ldWbPtr_value,
  output logic              io_lqEmpty,
  output logic [DEQ_CNT_W-1:0] io_lqDeq,
  output logic [CNT_W-1:0]  io_lqCancelCnt,
  input  logic              io_noUopsIssued,
  output logic [5:0]        io_perf_0_value
);

  // ===========================================================================
  //  A. 端口聚合：扁平 golden 端口 → 数组（便于 for 展开处理多路）
  // ===========================================================================
  // ---- dispatch 入队请求（6 口）----
  logic               enq_req_valid  [ENQ_W];
  logic [FUTYPE_W-1:0] enq_fuType    [ENQ_W];
  logic [UOP_W-1:0]   enq_uopIdx     [ENQ_W];
  logic               enq_robFlag    [ENQ_W];
  logic [ROB_W-1:0]   enq_robIdx     [ENQ_W];
  logic               enq_lqFlag     [ENQ_W];
  logic [PTR_VW-1:0]  enq_lqValue    [ENQ_W];
  logic [ELEM_W-1:0]  enq_numLsElem  [ENQ_W];
  logic               enq_needAlloc  [NEED_W];
  always_comb begin
    enq_req_valid[0]=io_enq_req_0_valid; enq_fuType[0]=io_enq_req_0_bits_fuType;
    enq_uopIdx[0]=io_enq_req_0_bits_uopIdx; enq_robFlag[0]=io_enq_req_0_bits_robIdx_flag;
    enq_robIdx[0]=io_enq_req_0_bits_robIdx_value; enq_lqFlag[0]=io_enq_req_0_bits_lqIdx_flag;
    enq_lqValue[0]=io_enq_req_0_bits_lqIdx_value; enq_numLsElem[0]=io_enq_req_0_bits_numLsElem;
    enq_req_valid[1]=io_enq_req_1_valid; enq_fuType[1]=io_enq_req_1_bits_fuType;
    enq_uopIdx[1]=io_enq_req_1_bits_uopIdx; enq_robFlag[1]=io_enq_req_1_bits_robIdx_flag;
    enq_robIdx[1]=io_enq_req_1_bits_robIdx_value; enq_lqFlag[1]=io_enq_req_1_bits_lqIdx_flag;
    enq_lqValue[1]=io_enq_req_1_bits_lqIdx_value; enq_numLsElem[1]=io_enq_req_1_bits_numLsElem;
    enq_req_valid[2]=io_enq_req_2_valid; enq_fuType[2]=io_enq_req_2_bits_fuType;
    enq_uopIdx[2]=io_enq_req_2_bits_uopIdx; enq_robFlag[2]=io_enq_req_2_bits_robIdx_flag;
    enq_robIdx[2]=io_enq_req_2_bits_robIdx_value; enq_lqFlag[2]=io_enq_req_2_bits_lqIdx_flag;
    enq_lqValue[2]=io_enq_req_2_bits_lqIdx_value; enq_numLsElem[2]=io_enq_req_2_bits_numLsElem;
    enq_req_valid[3]=io_enq_req_3_valid; enq_fuType[3]=io_enq_req_3_bits_fuType;
    enq_uopIdx[3]=io_enq_req_3_bits_uopIdx; enq_robFlag[3]=io_enq_req_3_bits_robIdx_flag;
    enq_robIdx[3]=io_enq_req_3_bits_robIdx_value; enq_lqFlag[3]=io_enq_req_3_bits_lqIdx_flag;
    enq_lqValue[3]=io_enq_req_3_bits_lqIdx_value; enq_numLsElem[3]=io_enq_req_3_bits_numLsElem;
    enq_req_valid[4]=io_enq_req_4_valid; enq_fuType[4]=io_enq_req_4_bits_fuType;
    enq_uopIdx[4]=io_enq_req_4_bits_uopIdx; enq_robFlag[4]=io_enq_req_4_bits_robIdx_flag;
    enq_robIdx[4]=io_enq_req_4_bits_robIdx_value; enq_lqFlag[4]=io_enq_req_4_bits_lqIdx_flag;
    enq_lqValue[4]=io_enq_req_4_bits_lqIdx_value; enq_numLsElem[4]=io_enq_req_4_bits_numLsElem;
    enq_req_valid[5]=io_enq_req_5_valid; enq_fuType[5]=io_enq_req_5_bits_fuType;
    enq_uopIdx[5]=io_enq_req_5_bits_uopIdx; enq_robFlag[5]=io_enq_req_5_bits_robIdx_flag;
    enq_robIdx[5]=io_enq_req_5_bits_robIdx_value; enq_lqFlag[5]=io_enq_req_5_bits_lqIdx_flag;
    enq_lqValue[5]=io_enq_req_5_bits_lqIdx_value; enq_numLsElem[5]=io_enq_req_5_bits_numLsElem;
    enq_needAlloc[0]=io_enq_needAlloc_0; enq_needAlloc[1]=io_enq_needAlloc_1;
    enq_needAlloc[2]=io_enq_needAlloc_2; enq_needAlloc[3]=io_enq_needAlloc_3;
    enq_needAlloc[4]=io_enq_needAlloc_4;
  end

  // ---- load 写回（3 口）----
  logic              ldin_valid    [LD_W];
  logic [PTR_VW-1:0] ldin_lqValue  [LD_W];
  logic              ldin_isvec    [LD_W];
  logic              ldin_updAddrV [LD_W];
  logic [10:0]       ldin_repCause [LD_W];
  always_comb begin
    ldin_valid[0]=io_ldin_0_valid; ldin_lqValue[0]=io_ldin_0_bits_uop_lqIdx_value;
    ldin_isvec[0]=io_ldin_0_bits_isvec; ldin_updAddrV[0]=io_ldin_0_bits_updateAddrValid;
    ldin_repCause[0]=io_ldin_0_bits_rep_info_cause;
    ldin_valid[1]=io_ldin_1_valid; ldin_lqValue[1]=io_ldin_1_bits_uop_lqIdx_value;
    ldin_isvec[1]=io_ldin_1_bits_isvec; ldin_updAddrV[1]=io_ldin_1_bits_updateAddrValid;
    ldin_repCause[1]=io_ldin_1_bits_rep_info_cause;
    ldin_valid[2]=io_ldin_2_valid; ldin_lqValue[2]=io_ldin_2_bits_uop_lqIdx_value;
    ldin_isvec[2]=io_ldin_2_bits_isvec; ldin_updAddrV[2]=io_ldin_2_bits_updateAddrValid;
    ldin_repCause[2]=io_ldin_2_bits_rep_info_cause;
  end

  // ---- 向量 commit（2 口）----
  logic              vec_valid   [VEC_W];
  logic              vec_robFlag [VEC_W];
  logic [ROB_W-1:0]  vec_robIdx  [VEC_W];
  logic [UOP_W-1:0]  vec_uopIdx  [VEC_W];
  always_comb begin
    vec_valid[0]=io_vecCommit_0_valid; vec_robFlag[0]=io_vecCommit_0_bits_robidx_flag;
    vec_robIdx[0]=io_vecCommit_0_bits_robidx_value; vec_uopIdx[0]=io_vecCommit_0_bits_uopidx;
    vec_valid[1]=io_vecCommit_1_valid; vec_robFlag[1]=io_vecCommit_1_bits_robidx_flag;
    vec_robIdx[1]=io_vecCommit_1_bits_robidx_value; vec_uopIdx[1]=io_vecCommit_1_bits_uopidx;
  end

  // ===========================================================================
  //  B. 队列状态寄存器 + 指针寄存器
  //     每字段独立 72 深数组，与 golden 展平寄存器（robIdx_i_value 等）一一对应。
  // ===========================================================================
  //  golden 复位行为（照搬各自）：allocated / isvec 是 RegInit（async reset 清 0）；
  //  robIdx_flag / robIdx_value / uopIdx / committed 是 Reg（无 reset）。
  logic              allocated  [VLQ_SIZE];  // entry 已分配（RegInit 0，async reset 清 0）
  logic              isvec        [VLQ_SIZE]; // 向量 load flow（RegInit 0，async reset 清 0）
  logic              robIdx_flag  [VLQ_SIZE]; // robIdx.flag（无 reset：golden Reg，非 RegInit）
  logic [ROB_W-1:0]  robIdx_value [VLQ_SIZE]; // robIdx.value（无 reset）
  logic [UOP_W-1:0]  uopIdx       [VLQ_SIZE]; // uop flow 下标（无 reset）
  logic              committed    [VLQ_SIZE]; // 已可提交（无 reset）

  // 指针：golden 只寄存 enqPtrExt(0)；enqPtrExt(1..5) 组合派生 = enqPtrExt_0 + j。
  lq_ptr_t enqPtrExt_0;
  lq_ptr_t deqPtr;               // golden deqPtr_r
  // 派生的 6 个入队指针（组合，非寄存器）
  lq_ptr_t enqPtrExt [ENQ_W];
  always_comb
    for (int j = 0; j < ENQ_W; j++) enqPtrExt[j] = lq_ptr_add(enqPtrExt_0, j);

  // redirect 打拍寄存器（lastCycleRedirect / lastLastCycleRedirect）
  logic              lastCycleRedirect_valid;
  logic              lastLastCycleRedirect_valid;

  // ===========================================================================
  //  C. redirect 取消统计
  // ===========================================================================
  //  validCount：当前在队条数 = distanceBetween(enqPtrExt0, deqPtr)
  logic [CNT_W-1:0] validCount;
  assign validCount = lq_distance(enqPtrExt_0, deqPtr);
  //  allowEnqueue：余量 >= LSQLdEnqWidth（validCount <= Size - LSQLdEnqWidth = 66）
  logic allowEnqueue;
  assign allowEnqueue = validCount <= CNT_W'(VLQ_SIZE - LSQ_LD_ENQ_W);

  //  needCancel(i)：该 entry 被 redirect 冲刷（robIdx 更年轻或 flush 自身）且已分配
  logic needCancel [VLQ_SIZE];
  always_comb
    for (int i = 0; i < VLQ_SIZE; i++)
      needCancel[i] = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                          robIdx_flag[i], robIdx_value[i],
                          io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value)
                      && allocated[i];

  //  lastNeedCancel_r：RegNext(needCancel)（golden 保留 72 个独立位，本核对齐）
  logic lastNeedCancel_r [VLQ_SIZE];

  //  入队请求侧的取消：该请求 valid 且其 robIdx 被本拍 redirect 冲刷
  logic               canEnqueue [ENQ_W];
  logic               enqCancel  [ENQ_W];
  logic [ELEM_W-1:0]  vLoadFlow  [ENQ_W];      // 每请求的 flow 数（向量 load 展开条数）
  logic [ELEM_W-1:0]  enqCancelNum [ENQ_W];
  always_comb
    for (int j = 0; j < ENQ_W; j++) begin
      canEnqueue[j]   = enq_req_valid[j];
      vLoadFlow[j]    = enq_numLsElem[j];
      enqCancel[j]    = canEnqueue[j] && rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                            enq_robFlag[j], enq_robIdx[j],
                            io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
      enqCancelNum[j] = enqCancel[j] ? vLoadFlow[j] : '0;
    end

  //  redirect 取消计数：上一拍 PopCount(lastNeedCancel_r) + 上一拍 enqCancelNum 总和（lastEnqCancel），
  //  在 lastCycleRedirect.valid 时锁存（RegEnable），作为 lqCancelCnt 输出。
  //  golden redirectCancelCount 是 8 位。
  logic [7:0]       lastEnqCancel_next_r;    // RegNext(sum(enqCancelNum))
  logic [7:0]       redirectCancelCount;     // RegEnable(...)（8 位）
  //  lastNeedCancel_r 的 popcount（组合）
  logic [7:0]       lastNeedCancelCount_c;
  always_comb begin
    lastNeedCancelCount_c = '0;
    for (int i = 0; i < VLQ_SIZE; i++) lastNeedCancelCount_c += 8'(lastNeedCancel_r[i]);
  end
  //  enqCancelNum 本拍总和（用于下一拍寄存到 lastEnqCancel_next_r）
  logic [7:0]       enqCancelNumSum_c;
  always_comb begin
    enqCancelNumSum_c = '0;
    for (int j = 0; j < ENQ_W; j++) enqCancelNumSum_c += 8'(enqCancelNum[j]);
  end

  // ===========================================================================
  //  D. enqPtr 更新（仅寄存 enqPtrExt_0）
  // ===========================================================================
  //  实际入队 flow 数：仅统计 valid 请求的 flow（与 canEnqueue 对齐）
  logic [ELEM_W-1:0] validVLoadFlow [ENQ_W];
  always_comb
    for (int j = 0; j < ENQ_W; j++)
      validVLoadFlow[j] = canEnqueue[j] ? vLoadFlow[j] : '0;
  //  enqNumber：本拍入队总 flow 数（enqPtr 正常推进量）。golden 为 8 位（_enqNumber_T_8），
  //  6×5bit flow 之和最大 186 > 7 位，须 8 位避免截断（FM 会探索 UT 到不了的大值）。
  logic [7:0] enqNumber;
  always_comb begin
    enqNumber = '0;
    for (int j = 0; j < ENQ_W; j++) enqNumber += 8'(validVLoadFlow[j]);
  end

  //  enqPtrExt_0 的 next：正常 +enqNumber；redirect 恢复 -redirectCancelCount。
  //  若 next(0) 仍在 deqPtrNext 之后则采用之，否则收缩到 deqPtrNext（j=0）。
  lq_ptr_t enqPtrExtNextVec0;
  lq_ptr_t enqPtrExtNext0;
  lq_ptr_t deqPtrNext;                   // 见 E 节
  always_comb begin
    if (lastLastCycleRedirect_valid)
      enqPtrExtNextVec0 = lq_ptr_sub(enqPtrExt_0, redirectCancelCount);
    else
      enqPtrExtNextVec0 = lq_ptr_add(enqPtrExt_0, enqNumber);
    if (lq_ptr_after(enqPtrExtNextVec0, deqPtrNext))
      enqPtrExtNext0 = enqPtrExtNextVec0;
    else
      enqPtrExtNext0 = deqPtrNext;       // = lq_ptr_add(deqPtrNext, 0)
  end

  // ===========================================================================
  //  E. deqPtr 更新（commitCount = 从 deqPtr 起连续可提交条数）
  // ===========================================================================
  //  deqLookupVec(i) = deqPtr + i（i=0..stride-1）
  //  deqLookup(i)    = allocated[ptr] && committed[ptr] && ptr != enqPtrExt(0)
  //  deqInSameRedir(i) = needCancel[ptr]
  //  deqCountMask    = deqLookup & ~deqInSameRedir
  //  commitCount     = 从最低位起连续为 1 的个数
  lq_ptr_t deqLookupVec   [DEQ_STRIDE];
  logic    deqCountMask   [DEQ_STRIDE];
  always_comb
    for (int i = 0; i < DEQ_STRIDE; i++) begin
      lq_ptr_t p;
      logic    lk, same;
      logic    p_alloc, p_commit, p_cancel;
      p  = lq_ptr_add(deqPtr, i);
      // p.value 由 lq_ptr_add 保证 < VLQ_SIZE，但其位宽（7 位）可表达到 127。为避免
      // 变量下标越界（FMR_ELAB-147 在形式工具里被升级为 link 错误），用「按 entry 索引
      // 正向比较」选出 p.value 对应的那条 entry 状态，而非直接变量下标读数组。
      p_alloc  = 1'b0; p_commit = 1'b0; p_cancel = 1'b0;
      for (int e = 0; e < VLQ_SIZE; e++)
        if (p.value == PTR_VW'(e)) begin
          p_alloc  = allocated[e];
          p_commit = committed[e];
          p_cancel = needCancel[e];
        end
      lk = p_alloc && p_commit
           && !((p.flag == enqPtrExt_0.flag) && (p.value == enqPtrExt_0.value));
      same = p_cancel;
      deqLookupVec[i]  = p;
      deqCountMask[i]  = lk && !same;
    end
  //  连续可提交计数：从最低槽起连续 deqCountMask=1 的个数（遇首个 0 停止）。
  logic [DEQ_CNT_W-1:0] commitCount;
  always_comb begin
    commitCount = '0;
    for (int i = 0; i < DEQ_STRIDE; i++)
      if (deqCountMask[i] && commitCount == DEQ_CNT_W'(i)) commitCount = DEQ_CNT_W'(i + 1);
  end

  //  deqPtr 两拍打拍：cycle1 算 commitCount→寄存为 lastCommitCount_next_r；cycle2 推进 deqPtr。
  //  deqPtrNext = deqPtr + lastCommitCount_next_r，照搬 golden 逐位算法（8 位 new_value +
  //  9 位 diff，$signed(diff) >= 0 判回绕），避免通用 lq_ptr_add 的位宽差异被 FM 判不等价。
  logic [DEQ_CNT_W-1:0] lastCommitCount_next_r;   // GatedRegNext(commitCount)
  logic [7:0] deqPtrNext_new_value;
  logic [8:0] deqPtrNext_diff;
  logic       deqPtrNext_reverse;
  always_comb begin
    deqPtrNext_new_value = {1'b0, deqPtr.value} + {4'b0, lastCommitCount_next_r};
    deqPtrNext_diff      = {1'b0, deqPtrNext_new_value} - 9'(VLQ_SIZE);
    deqPtrNext_reverse   = ~deqPtrNext_diff[8];   // $signed(diff) >= 0 ⇔ 符号位 0
    deqPtrNext.value     = deqPtrNext_reverse ? deqPtrNext_diff[PTR_VW-1:0]
                                              : deqPtrNext_new_value[PTR_VW-1:0];
    deqPtrNext.flag      = deqPtrNext_reverse ^ deqPtr.flag;
  end

  // ===========================================================================
  //  F. enqueue 写 entry（按 lqIdx 命中区间分配）
  // ===========================================================================
  //  每个请求 j 占据 lqIdx 区间 [lqIdx, lqIdx+numLsElem)；entry i 若落在某 valid 且
  //  未取消请求的区间内则被该请求写入（优先取最低 j —— ParallelPriorityMux）。
  //  区间可能跨环回绕（low.flag != up.flag），此时命中条件取「>=low 或 <up」。
  logic [PTR_VW-1:0] enqLowBound [ENQ_W];
  logic [PTR_VW-1:0] enqUpBound  [ENQ_W];
  logic              enqUpFlag   [ENQ_W];
  logic              enqCrossLoop[ENQ_W];
  always_comb
    for (int j = 0; j < ENQ_W; j++) begin
      lq_ptr_t up;
      enqLowBound[j] = enq_lqValue[j];
      up = lq_ptr_add('{flag:enq_lqFlag[j], value:enq_lqValue[j]}, enq_numLsElem[j]);
      enqUpBound[j]  = up.value;
      enqUpFlag[j]   = up.flag;
      enqCrossLoop[j]= enq_lqFlag[j] != up.flag;
    end

  //  每个 entry i 的写入决策（组合）：命中哪个请求（最低优先）、是否写。
  logic              entry_enq_hit  [VLQ_SIZE];
  logic [ROB_W-1:0]  entry_enq_robIdx [VLQ_SIZE];
  logic              entry_enq_robFlag[VLQ_SIZE];
  logic [UOP_W-1:0]  entry_enq_uopIdx [VLQ_SIZE];
  logic              entry_enq_isvec  [VLQ_SIZE];
  always_comb
    for (int i = 0; i < VLQ_SIZE; i++) begin
      logic hit;
      logic [ROB_W-1:0] selRob; logic selRobF; logic [UOP_W-1:0] selUop; logic selVec;
      hit = 1'b0; selRob='0; selRobF=1'b0; selUop='0; selVec=1'b0;
      // 反向遍历使最低 j 最后覆盖 → 等价于最低优先
      for (int j = ENQ_W-1; j >= 0; j--) begin
        logic inBound, canHit;
        inBound = enqCrossLoop[j]
                  ? ((enqLowBound[j] <= PTR_VW'(i)) || (PTR_VW'(i) < enqUpBound[j]))
                  : ((enqLowBound[j] <= PTR_VW'(i)) && (PTR_VW'(i) < enqUpBound[j]));
        canHit  = canEnqueue[j] && !enqCancel[j] && inBound;
        if (canHit) begin
          hit    = 1'b1;
          selRob = enq_robIdx[j];
          selRobF= enq_robFlag[j];
          selUop = enq_uopIdx[j];
          // isvec = isVLoad(fuType) = fuType[vldu] | fuType[vsegldu]
          selVec = enq_fuType[j][FU_VLDU_BIT] | enq_fuType[j][FU_VSEGLDU_BIT];
        end
      end
      entry_enq_hit[i]    = hit;
      entry_enq_robIdx[i] = selRob;
      entry_enq_robFlag[i]= selRobF;
      entry_enq_uopIdx[i] = selUop;
      entry_enq_isvec[i]  = selVec;
    end

  // ===========================================================================
  //  G. commit：deqPtr..+commitCount 的 entry 清 allocated（与 deqPtr 推进同拍）
  //     注意 Scala 用本拍 commitCount（非 lastCommitCount）清 allocated。
  // ===========================================================================
  //  按 entry 索引正向比较（避免变量写下标的越界告警）：entry i 被清当且仅当存在
  //  k < commitCount 使 deqLookupVec[k].value == i。
  logic commit_clear [VLQ_SIZE];
  always_comb
    for (int i = 0; i < VLQ_SIZE; i++) begin
      logic c;
      c = 1'b0;
      for (int k = 0; k < DEQ_STRIDE; k++)
        if ((commitCount > DEQ_CNT_W'(k)) && (deqLookupVec[k].value == PTR_VW'(i)))
          c = 1'b1;
      commit_clear[i] = c;
    end

  // ===========================================================================
  //  H. 向量 commit / load 写回 置 committed（组合决策，时序在 always_ff）
  // ===========================================================================
  //  向量 commit：entry 已分配且某向量口的 robIdx/uopIdx 与之匹配 → committed。
  logic vec_set_committed [VLQ_SIZE];
  always_comb
    for (int i = 0; i < VLQ_SIZE; i++) begin
      logic m;
      m = 1'b0;
      for (int v = 0; v < VEC_W; v++)
        m |= allocated[i] && vec_valid[v]
             && (robIdx_flag[i] == vec_robFlag[v]) && (robIdx_value[i] == vec_robIdx[v])
             && (uopIdx[i]      == vec_uopIdx[v]);
      vec_set_committed[i] = m && isvec[i];     // 仅向量 entry 由此路置位
    end

  //  load 写回（标量）：!need_rep && updateAddrValid && !isvec → 该 lqIdx 的 entry committed。
  //  need_rep = |rep_info.cause（任一 replay cause 置位即需重放，不算完成）。
  logic ldwb_fire [LD_W];
  always_comb
    for (int w = 0; w < LD_W; w++)
      ldwb_fire[w] = ldin_valid[w] && !(|ldin_repCause[w]) && ldin_updAddrV[w] && !ldin_isvec[w];

  //  按 entry 索引正向比较（避免变量写下标越界告警）：entry i 被任一“有效完成”且
  //  lqIdx==i 的写回口置 committed。
  logic ldwb_set_committed [VLQ_SIZE];
  always_comb
    for (int i = 0; i < VLQ_SIZE; i++) begin
      logic s;
      s = 1'b0;
      for (int w = 0; w < LD_W; w++)
        if (ldwb_fire[w] && (ldin_lqValue[w] == PTR_VW'(i))) s = 1'b1;
      ldwb_set_committed[i] = s;
    end

  // ===========================================================================
  //  J. 全局输出
  // ===========================================================================
  assign io_enq_canAccept = allowEnqueue;
  assign io_ldWbPtr_flag  = deqPtr.flag;
  assign io_ldWbPtr_value = deqPtr.value;
  assign io_lqCancelCnt   = redirectCancelCount[CNT_W-1:0];

  //  lqEmpty / lqDeq 为打拍输出（见时序）
  logic             lqEmpty_r;             // golden io_lqEmpty_REG
  logic [DEQ_CNT_W-1:0] lqDeq_r;           // golden io_lqDeq_next_r
  assign io_lqEmpty = lqEmpty_r;
  assign io_lqDeq   = lqDeq_r;

  //  perf: mem_stall_anyload = RegNext(noUopsIssued && RegNext(validCount)>=1)，
  //  再经 perf 计数 2 拍寄存（golden io_perf_0_value_REG/REG_1 各 1 位，输出补零到 6 位）。
  logic [CNT_W-1:0] validCountReg;
  logic             memStallAnyLoad;       // RegNext(stallLoad)
  logic             perf0_reg, perf0_reg_1;
  assign io_perf_0_value = {5'h0, perf0_reg_1};

  // ===========================================================================
  //  时序逻辑
  //  ── 块1（async reset）：allocated / lastNeedCancel_r / 指针 / 取消计数 / 打拍位
  //  ── 块2（no reset）    ：entry 数据字段（robIdx/uopIdx/isvec/committed）+ 观测打拍
  //     与 golden 两个 always 块（8129 reset / 10214 no-reset）一一对应。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < VLQ_SIZE; i++) begin
        allocated[i]        <= 1'b0;
        isvec[i]            <= 1'b0;
        lastNeedCancel_r[i] <= 1'b0;
      end
      enqPtrExt_0 <= '{flag:1'b0, value:'0};
      deqPtr <= '{flag:1'b0, value:'0};
      lastEnqCancel_next_r <= '0;
      redirectCancelCount  <= '0;
      lastCommitCount_next_r <= '0;
      lqDeq_r              <= '0;
    end else begin
      // ---- lastNeedCancel_r = RegNext(needCancel)（逐 entry）----
      for (int i = 0; i < VLQ_SIZE; i++) lastNeedCancel_r[i] <= needCancel[i];

      // ---- redirect 取消统计 ----
      lastEnqCancel_next_r <= enqCancelNumSum_c;   // RegNext(sum(enqCancelNum))
      if (lastCycleRedirect_valid)
        redirectCancelCount <= lastNeedCancelCount_c + lastEnqCancel_next_r;

      // ---- 指针更新 ----
      enqPtrExt_0 <= enqPtrExtNext0;
      lastCommitCount_next_r <= commitCount;       // cycle1→cycle2
      // deqPtr：照搬 golden 门控——flag = (|lastCommitCount) & reverse ^ flag；
      // value 仅在 |lastCommitCount 时更新，否则 HOLD（不能用 deqPtr+0 重算，因 FM 会探索
      // value>=72 的不可达状态：+0 会误回绕而 golden 保持原值 → 判不等价）。
      deqPtr.flag <= (deqPtrNext_reverse & (|lastCommitCount_next_r)) ^ deqPtr.flag;
      if (|lastCommitCount_next_r)
        deqPtr.value <= deqPtrNext.value;

      // ---- allocated：入队置 1 / 保留，再被 commit_clear、needCancel 强制清 0 ----
      for (int i = 0; i < VLQ_SIZE; i++)
        allocated[i] <= ~needCancel[i] & ~commit_clear[i]
                        & (entry_enq_hit[i] | allocated[i]);

      // ---- isvec：入队命中时写入（RegInit，与 allocated 同属 reset 块）----
      for (int i = 0; i < VLQ_SIZE; i++)
        if (entry_enq_hit[i]) isvec[i] <= entry_enq_isvec[i];

      // ---- lqDeq 打拍 ----
      lqDeq_r <= lastCommitCount_next_r;            // io.lqDeq = GatedRegNext(lastCommitCount)
    end
  end

  //  块2（no reset）：entry 数据字段 + 观测打拍。golden 这些 Reg 无 reset。
  always_ff @(posedge clock) begin
    // ---- committed：置位（写回/向量）优先于入队清零 ----
    for (int i = 0; i < VLQ_SIZE; i++)
      committed[i] <= ldwb_set_committed[i] | vec_set_committed[i]
                      | (~entry_enq_hit[i] & committed[i]);
    // ---- 入队同拍写入 robIdx/uopIdx（入队命中时覆盖）；isvec 在 reset 块内更新 ----
    for (int i = 0; i < VLQ_SIZE; i++)
      if (entry_enq_hit[i]) begin
        robIdx_flag[i]  <= entry_enq_robFlag[i];
        robIdx_value[i] <= entry_enq_robIdx[i];
        uopIdx[i]       <= entry_enq_uopIdx[i];
      end

    // ---- redirect 打拍（golden 无 reset：Reg，非 RegInit）----
    lastCycleRedirect_valid     <= io_redirect_valid;
    lastLastCycleRedirect_valid <= lastCycleRedirect_valid;

    // ---- 全局输出/观测打拍（golden 无 reset）----
    lqEmpty_r       <= (validCount == '0);
    validCountReg   <= validCount;
    memStallAnyLoad <= io_noUopsIssued && (|validCountReg);
    perf0_reg       <= memStallAnyLoad;
    perf0_reg_1     <= perf0_reg;
  end

endmodule
