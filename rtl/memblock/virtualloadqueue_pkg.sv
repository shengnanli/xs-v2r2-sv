// =============================================================================
//  virtualloadqueue_pkg —— VirtualLoadQueue（load 顺序队列主体）可读重写
//                          所用的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/VirtualLoadQueue.scala (class VirtualLoadQueue)
//      src/main/scala/utility/CircularQueuePtr.scala               (环形指针语义)
//      src/main/scala/xiangshan/backend/rob/RobBundles.scala       (RobPtr.needFlush)
//
//  ── VirtualLoadQueue 在 LSU 中的位置与职责 ──
//   它是 load 的「顺序主队列」：按 robIdx/lqIdx 顺序为**每一条 load（含向量 load 的每个
//   flow）**分配一个 entry，并维护该 entry 的生命周期状态。它本身不存地址/数据（那些在
//   LoadQueueReplay / LoadQueueRAR / LoadQueueRAW 等子队列里），只维护「这条 load 走到
//   哪一步了」的少量状态位，并以**入队指针 enqPtr / 出队指针 deqPtr**维护程序顺序。
//
//   其核心作用：
//     1. dispatch 阶段按 lqIdx 顺序分配 entry（allocated=1），向后端反压（canAccept）。
//     2. load 流水 s3 写回（io_ldin）时，对命中 entry 置 committed（标量 load 标记可提交）。
//     3. 向量 load 由 io_vecCommit 单独标记 committed。
//     4. deqPtr 顺序扫描：连续的 allocated&&committed entry 被提交，allocated 清 0、
//        deqPtr 前移，并把提交条数报给 dispatch（lqDeq）。
//     5. redirect 冲刷：按 robIdx 取消被冲刷的 entry（allocated=0），并回退 enqPtr。
//     6. 对外提供 ldWbPtr(=deqPtr)、lqFull/lqEmpty、lqCancelCnt 等状态。
//
//   与其它子队列的关系：deqPtr(ldWbPtr) 告诉 LoadQueueReplay/RAR 哪些 load 已顺序写回。
//
//  ── 本工程当前配置（golden 由 DefaultConfig 固化）──
//     VirtualLoadQueueSize = 72   （entry 数；注意**不是** 2 的幂）
//     LqPtr.value 位宽      = 7    （log2Up(72)=7；指针 = {flag, value[6:0]}，共 8 位）
//     LoadPipelineWidth    = 3    （load 写回端口 ldin_0..2）
//     VecLoadPipelineWidth = 2    （向量 commit 端口 vecCommit_0..1）
//     CommitWidth          = 8    （= DeqPtrMoveStride，每拍最多提交 8 条）
//     io.enq.req.length    = 6    （= RenameWidth，dispatch 入队请求口 req_0..5）
//     io.enq.needAlloc     = 5    （needAlloc_0..4；见下方说明）
//     LSQLdEnqWidth        = 6    （allowEnqueue 余量：Size - 6 = 66）
//     robIdx.value 位宽    = 8
//     uopIdx 位宽          = 7
//     numLsElem 位宽       = 5    （elemIdxBits，向量 load 的 flow 数）
//
//   ⚠️ Size=72 非 2 的幂：环形指针 +/- 必须按 entries=72 取模（见 lq_ptr_add/sub），
//   不能简单丢弃进位。这是本模块与「2 的幂大小队列（如 RAW Size=32）」最大的不同坑。
// =============================================================================
package virtualloadqueue_pkg;

  // ---- 规模 / 位宽参数 -------------------------------------------------------
  localparam int VLQ_SIZE  = 72;              // VirtualLoadQueueSize
  localparam int PTR_VW    = 7;               // log2Up(72)，指针 value 位宽
  localparam int LD_W      = 3;               // LoadPipelineWidth（ldin 口数）
  localparam int VEC_W     = 2;               // VecLoadPipelineWidth（vecCommit 口数）
  localparam int ENQ_W     = 6;               // io.enq.req.length（= RenameWidth）
  localparam int NEED_W    = 5;               // io.enq.needAlloc 口数
  localparam int DEQ_STRIDE = 8;              // DeqPtrMoveStride = CommitWidth
  localparam int LSQ_LD_ENQ_W = 6;            // LSQLdEnqWidth（allowEnqueue 余量）

  localparam int ROB_W     = 8;               // robIdx.value 位宽
  localparam int UOP_W     = 7;               // uopIdx 位宽
  localparam int ELEM_W    = 5;               // numLsElem 位宽（elemIdxBits）
  localparam int PADDR_BITS = 48;             // debug paddr 位宽

  localparam int FUTYPE_W  = 35;              // fuType 位宽（OHEnumeration，one-hot）
  // isVLoad(fuType) = fuType[vldu] | fuType[vsegldu]。OHEnumeration 中 vldu 在第 31 位、
  // vsegldu 在第 33 位（golden 仅保留 fuType[33:31] 三位用于本模块）。
  localparam int FU_VLDU_BIT    = 31;
  localparam int FU_VSEGLDU_BIT = 33;

  // 派生计数位宽
  localparam int CNT_W      = $clog2(VLQ_SIZE + 1);          // validCount/lqCancelCnt: 7 位
  localparam int DEQ_CNT_W  = $clog2(DEQ_STRIDE + 1);        // lqDeq: log2Up(CommitWidth+1)=4

  // ---- 环形指针类型 {flag, value} -------------------------------------------
  //   LqPtr：CircularQueuePtr，entries=72。flag 在最高位，value 在低 PTR_VW 位。
  typedef struct packed {
    logic              flag;            // 环绕标志（区分同 value 的两圈）
    logic [PTR_VW-1:0] value;           // entry 下标 0..71
  } lq_ptr_t;

  // ---- 每条 entry 的状态/标志（per-entry payload）---------------------------
  //   注意：entry「是否被占用」由独立的 allocated[] 数组表示，不放进本 struct，
  //   以便复位时只显式清 allocated（与 Scala 里 allocated 用 RegInit、其余用 Reg 对应）。
  typedef struct packed {
    logic              robFlag;         // robIdx.flag（年龄比较 / redirect 冲刷用）
    logic [ROB_W-1:0]  robIdx;          // robIdx.value
    logic [UOP_W-1:0]  uopIdx;          // uop 在指令内的 flow 下标（向量 commit 匹配用）
    logic              isvec;           // 该 entry 是向量 load flow（commit 路径不同）
    logic              committed;       // 已可提交：标量 load 写回 / 向量 commit 置位
  } lq_entry_t;

  // ===========================================================================
  //  环形指针纯函数（entries = VLQ_SIZE = 72，非 2 的幂，必须显式取模）
  // ===========================================================================
  //  指针 +v：value+v，若 >= 72 则减 72 并翻转 flag。本模块单次增量最大为 enqNumber
  //  （<= 6*flow，但实际 <= Size）或 DEQ_STRIDE 偏移，单步增量远小于 72，故只需判一次回绕。
  function automatic lq_ptr_t lq_ptr_add(input lq_ptr_t p, input int unsigned v);
    lq_ptr_t r;
    logic [PTR_VW:0] sum;               // 多一位防溢出
    sum = {1'b0, p.value} + (PTR_VW+1)'(v);
    if (sum >= (PTR_VW+1)'(VLQ_SIZE)) begin
      r.value = sum - (PTR_VW+1)'(VLQ_SIZE);
      r.flag  = ~p.flag;
    end else begin
      r.value = sum[PTR_VW-1:0];
      r.flag  = p.flag;
    end
    return r;
  endfunction

  //  指针 -v：CircularQueuePtr 实现为 +(entries - v) 再翻 flag。这里直接给出等价结果：
  //  若 value >= v：value-v，flag 不变；否则 value+72-v，flag 翻转。
  function automatic lq_ptr_t lq_ptr_sub(input lq_ptr_t p, input int unsigned v);
    lq_ptr_t r;
    if ({1'b0, p.value} >= (PTR_VW+1)'(v)) begin
      r.value = p.value - PTR_VW'(v);
      r.flag  = p.flag;
    end else begin
      r.value = (PTR_VW)'(({1'b0, p.value} + (PTR_VW+1)'(VLQ_SIZE)) - (PTR_VW+1)'(v));
      r.flag  = ~p.flag;
    end
    return r;
  endfunction

  //  a > b（a 比 b 更年轻 / 更靠后）：(a.flag ^ b.flag) ^ (a.value > b.value)
  function automatic logic lq_ptr_after(input lq_ptr_t a, input lq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  //  distanceBetween(enq, deq)：环形有效条数。
  //   flag 同：enq.value - deq.value；flag 异：72 + enq.value - deq.value。
  function automatic logic [CNT_W-1:0] lq_distance(input lq_ptr_t enq, input lq_ptr_t deq);
    if (enq.flag == deq.flag)
      return CNT_W'({1'b0, enq.value} - {1'b0, deq.value});
    else
      return CNT_W'((CNT_W)'(VLQ_SIZE) + {1'b0, enq.value} - {1'b0, deq.value});
  endfunction

  //  RobPtr.needFlush(redirect)：
  //    flushItself = redirect.level && (this == redirect.robIdx)
  //    needFlush   = redirect.valid && (flushItself || isAfter(this, redirect.robIdx))
  //  即：本条目比 redirect 目标更年轻 → 必被冲刷；或 level=flush(整条含自身)且恰等于目标。
  function automatic logic rob_need_flush(
      input logic             redirect_valid,
      input logic             redirect_level,
      input logic             this_flag,  input logic [ROB_W-1:0] this_val,
      input logic             rdir_flag,  input logic [ROB_W-1:0] rdir_val);
    logic flush_itself, after;
    flush_itself = redirect_level && (this_flag == rdir_flag) && (this_val == rdir_val);
    after        = (this_flag ^ rdir_flag) ^ (this_val > rdir_val);
    return redirect_valid && (flush_itself || after);
  endfunction

endpackage
