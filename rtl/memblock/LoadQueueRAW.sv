// =============================================================================
// LoadQueueRAW.sv —— load 队列的 RAW（store→load 先读后写）违例检测队列
//
// 对应 Chisel: xiangshan.mem.LoadQueueRAW（src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAW.scala）
//
// 在流水线里的位置：
//     load 流水 s2/s3 ──query.req──> LoadQueueRAW <──storeIn── store 流水 s1（地址已知）
//                                         │
//                                         └──rollback──> 后端 redirect（从违例 load 重取指）
//
// 问题：load 可以越过"地址还没算出来"的更老 store 先执行。等那条 store 的地址到了，
// 如果它写的正是 load 读过的字节，load 就读到了旧数据 —— 这是 RAW 违例，必须冲刷重来。
// 本队列就是为此存档的：
//   1. 入队：load 执行时若队里还有**比它老、地址未就绪**的 store（sqIdx 在 stAddrReadySqPtr
//      之后），就在本队列占一个槽，记下 uop（robIdx/ftq 信息）、部分 paddr、字节掩码。
//      槽位由 FreeList 分配；满了就回 ready=0 让 load 去 replay。
//   2. 出队：它之前的所有 store 地址都就绪了（或被 redirect 冲掉），槽就释放；
//      load 在下一拍被 revoke（自己要 replay）时，上一拍刚分到的槽也立即归还。
//   3. 检测：每条 store 流水来一个 store，就拿它的 paddr/mask 反查（CAM）全部 32 个槽：
//      同地址、字节有交叠、且 load 比 store 年轻（robIdx 在其后）的槽都是违例候选。
//      候选里选**最老**的那条 load 发 rollback（从它重取指），选择分两级流水：
//        s0: CAM + "该槽要不要查"（entryNeedCheck）打一拍
//        s1: 32 选 1 的第一级：每 8 个一组（RollbackGroupSize）组内选最老，打一拍
//        s2: 4 组选最老，打一拍 → 与"store 有效且不 miss"打 3 拍的信号相与 = rollback.valid
//      每级之间都要再核一次"被选中的 load 是否已经被 redirect 冲掉"（当拍 + 上拍的 redirect）。
//
// 子模块（golden 同名例化，都已签核）：
//   LqPAddrModule_1 / LqMaskModule —— 两块 32 项 CAM 阵列（本 lane 重写，共用核 xs_LqRawDataCam_core）
//   FreeList_4                      —— 32 项槽位空闲表（3 分配口，按位 free）
//   DelayN_297 ×2                   —— store 有效位打 3 拍（与选择流水对齐）
//   DelayNWithValid_148/149 ×2      —— store 的 ftqPtr / ftqOffset 打 3 拍（rollback 要带回去）
//
// ★golden 里被 firtool 消掉、因此本文件也不写的东西：query.resp（整组端口不存在）、
//   uop 的其余 170 多个字段（只剩 9 个：isRVC/ftqPtr/ftqOffset/robIdx/runahead_checkpoint_id/sqIdx）、
//   选择树里的 sqIdx（只有出队判定读它）、rollback 的 cfiUpdate.target 等 DontCare 字段、
//   XSError / QueuePerf 的探针。
// ★照抄 golden、看起来冗余的结构（一份都不许少，见 CONVENTIONS「看起来冗余的重复结构」）：
//   · RegNext(io.redirect) 每个选择组各一份（每条 store 流水 4 组 + 第二级 1 份 = 5 份）；
//   · store 的 paddr 以 48 位全宽打拍（只用 [27:4]），与 golden 位宽一致；
//   · lastCanAccept / lastAllocIndex / entryNeedCheck 是 Gated(Valid)RegNext：值变了才打拍，
//     功能上等于 RegNext，但照 golden 写成"不同才更新"。
//
// 复位域（与 golden 两个 always 块逐个对齐）：
//   异步复位：allocated / datavalid / lastCanAccept / lastAllocIndex / entryNeedCheck /
//             第二级 selValid —— 共 32+32+3+15+64+2 位
//   不复位  ：uop 各字段 / store 打拍 / 第一级组寄存器 / 第二级 bits / 各份 redirect 打拍 / perf
//
// 本文件导航：
//   package loadqueueraw_pkg ………… 配置常量、指针与总线类型、环形指针比较函数
//   xs_LoadQueueRAW_core …………… §1 入队  §2 槽状态  §3 出队/撤销  §4 违例检测  §5 输出与 perf
//   LoadQueueRAW（wrapper）………… golden 端口表 <-> 核的结构体端口（scripts/gen_lqraw.py 生成）
// =============================================================================
package loadqueueraw_pkg;

  // ---- KunminghuV2Config 下的配置常量（由 golden 端口/寄存器数量核实）----
  localparam int RAW_SIZE    = 32;                    // LoadQueueRAWSize
  localparam int IDX_W       = 5;                     // log2Up(32)
  localparam int LD_W        = 3;                     // LoadPipelineWidth
  localparam int ST_W        = 2;                     // StorePipelineWidth
  localparam int GROUP_SIZE  = 8;                     // RollbackGroupSize
  localparam int NUM_GROUPS  = RAW_SIZE / GROUP_SIZE; // 4 组
  localparam int PADDR_W     = 48;                    // PAddrBits
  localparam int MASK_W      = 16;                    // VLEN/8
  localparam int PART_PADDR_LO = 4;                   // DCacheVWordOffset：16B 对齐
  localparam int PART_PADDR_W  = 24;                  // PartialPAddrWidth → paddr[27:4]

  // ---- 环形队列指针（utility.CircularQueuePtr）：{flag,value}，flag = 绕圈奇偶 ----
  typedef struct packed { logic flag; logic [7:0] value; } rob_ptr_t;  // RobSize 256
  typedef struct packed { logic flag; logic [5:0] value; } sq_ptr_t;   // StoreQueueSize 56
  typedef struct packed { logic flag; logic [5:0] value; } ftq_ptr_t;  // FtqSize 64

  // redirect：golden 只剩 valid / robIdx / level 三个字段
  typedef struct packed {
    logic     valid;
    rob_ptr_t robIdx;
    logic     level;       // 1 = flush（连 robIdx 自己也冲掉）
  } redirect_t;

  // 选择树里流动、最后变成 rollback 的那部分 uop
  typedef struct packed {
    logic        isRVC;       // preDecodeInfo.isRVC
    ftq_ptr_t    ftqPtr;
    logic [3:0]  ftqOffset;
    rob_ptr_t    robIdx;
    logic [63:0] runaheadId;  // debugInfo.runahead_checkpoint_id
  } sel_uop_t;

  // 选择树的一个候选：valid + bits
  typedef struct packed {
    logic     valid;
    sel_uop_t bits;
  } sel_cand_t;

  // load 流水的入队请求（query.req）
  typedef struct packed {
    logic                 valid;
    sel_uop_t             uop;
    sq_ptr_t              sqIdx;      // uop.sqIdx：这条 load 之前最近的 store 位置
    logic [MASK_W-1:0]    mask;
    logic [PADDR_W-1:0]   paddr;
    logic                 data_valid;
  } query_req_t;

  // store 流水 s1 送来的 store
  typedef struct packed {
    logic                 valid;
    ftq_ptr_t             ftqPtr;
    logic [3:0]           ftqOffset;
    rob_ptr_t             robIdx;
    logic [PADDR_W-1:0]   paddr;
    logic [MASK_W-1:0]    mask;
    logic                 wlineflag;  // 整 cacheline 写（cbo.zero）
    logic                 miss;       // TLB miss：这条 store 这次不算数
  } store_in_t;

  // 发给后端的 rollback（Redirect 里 golden 剩下的字段）
  typedef struct packed {
    logic        valid;
    logic        isRVC;
    rob_ptr_t    robIdx;
    ftq_ptr_t    ftqIdx;
    logic [3:0]  ftqOffset;
    ftq_ptr_t    stFtqIdx;
    logic [3:0]  stFtqOffset;
    logic [63:0] runaheadId;
  } rollback_t;

  // ---- 环形指针比较 ----
  // a 比 b 年轻（在 b 之后）？同圈比 value，异圈反过来。
  function automatic logic rob_is_after(input rob_ptr_t a, input rob_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  // a 比 b 老（在 b 之前）？
  function automatic logic sq_is_before(input sq_ptr_t a, input sq_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value < b.value);
  endfunction

  // RobPtr.needFlush：这条指令会被这次 redirect 冲掉吗？
  //   level=1（flush）时 robIdx 本身也冲；否则只冲它之后的。
  function automatic logic need_flush(input rob_ptr_t self, input redirect_t rd);
    return rd.valid & ((rd.level & (self == rd.robIdx)) | rob_is_after(self, rd.robIdx));
  endfunction

  // selectPartialOldest 的两两比较：返回两个候选里更老的那个。
  //   两个都有效 → 比 robIdx，a 在 b 之后就取 b；
  //   只有 a 有效 → 取 a；其余（只有 b 有效、都无效）→ 取 b。
  //   "都无效取 b"是 golden 的写法（Mux 的默认支），bits 不会被用到但照抄。
  function automatic sel_cand_t select_older(input sel_cand_t a, input sel_cand_t b);
    logic pick_b;
    if (a.valid & b.valid) pick_b = rob_is_after(a.bits.robIdx, b.bits.robIdx);
    else                   pick_b = ~(a.valid & ~b.valid);
    return pick_b ? b : a;
  endfunction

endpackage


// -----------------------------------------------------------------------------
// xs_LoadQueueRAW_core —— 可读核
// -----------------------------------------------------------------------------
module xs_LoadQueueRAW_core
  import loadqueueraw_pkg::*;
(
  input  logic                   clock,
  input  logic                   reset,

  input  redirect_t              io_redirect,

  // load 流水的查询/入队（3 条）
  input  query_req_t [LD_W-1:0]  io_query_req,
  output logic       [LD_W-1:0]  io_query_req_ready,
  input  logic       [LD_W-1:0]  io_query_revoke,      // 上一拍入队的 load 要 replay：退回槽位

  // store 流水（2 条）
  input  store_in_t  [ST_W-1:0]  io_storeIn,
  output rollback_t  [ST_W-1:0]  io_rollback,

  // store queue 的两个指针：地址就绪到哪了 / 发射到哪了
  input  sq_ptr_t                io_stAddrReadySqPtr,
  input  sq_ptr_t                io_stIssuePtr,

  output logic                   io_lqFull,
  output logic [5:0]             io_perf_0_value,      // 本拍入队条数（打两拍）
  output logic [5:0]             io_perf_1_value       // 本拍有无 rollback（打两拍）
);

  // ===========================================================================
  // 槽状态：per-field 数组（SoA），与 golden 的扁平命名一一对应
  // ===========================================================================
  logic                 allocated              [RAW_SIZE];  // 槽被占用（异步复位）
  logic                 datavalid              [RAW_SIZE];  // load 已拿到数据（异步复位）
  logic                 uop_isRVC              [RAW_SIZE];  // 以下 uop 字段不复位
  logic                 uop_ftqPtr_flag        [RAW_SIZE];
  logic [5:0]           uop_ftqPtr_value       [RAW_SIZE];
  logic [3:0]           uop_ftqOffset          [RAW_SIZE];
  logic                 uop_robIdx_flag        [RAW_SIZE];
  logic [7:0]           uop_robIdx_value       [RAW_SIZE];
  logic [63:0]          uop_runaheadId         [RAW_SIZE];
  logic                 uop_sqIdx_flag         [RAW_SIZE];
  logic [5:0]           uop_sqIdx_value        [RAW_SIZE];

  // 读回成结构体，方便下面比较
  rob_ptr_t             uop_robIdx             [RAW_SIZE];
  sq_ptr_t              uop_sqIdx              [RAW_SIZE];
  sel_uop_t             uop_sel                [RAW_SIZE];
  always_comb
    for (int i = 0; i < RAW_SIZE; i++) begin
      uop_robIdx[i] = rob_ptr_t'{flag: uop_robIdx_flag[i], value: uop_robIdx_value[i]};
      uop_sqIdx[i]  = sq_ptr_t'{flag: uop_sqIdx_flag[i], value: uop_sqIdx_value[i]};
      uop_sel[i]    = sel_uop_t'{isRVC:      uop_isRVC[i],
                                 ftqPtr:     ftq_ptr_t'{flag: uop_ftqPtr_flag[i],
                                                        value: uop_ftqPtr_value[i]},
                                 ftqOffset:  uop_ftqOffset[i],
                                 robIdx:     uop_robIdx[i],
                                 runaheadId: uop_runaheadId[i]};
    end

  // 当前在队的每个槽是否被本拍 redirect 冲掉（出队与检测共用）
  logic needCancel [RAW_SIZE];
  always_comb
    for (int i = 0; i < RAW_SIZE; i++)
      needCancel[i] = need_flush(uop_robIdx[i], io_redirect);

  // ===========================================================================
  // §1 入队
  // ---------------------------------------------------------------------------
  // 只有"前面还有地址没就绪的 store"的 load 才需要进队：
  //   allAddrCheck = (stIssuePtr == stAddrReadySqPtr)：已发射的 store 地址全就绪 ⇒ 谁都不用进；
  //   否则看 stAddrReadySqPtr 是否在这条 load 的 sqIdx 之前（有更老的 store 地址未就绪）。
  // 被本拍 redirect 冲掉的 load 不进队。
  // 3 条流水按顺序从 FreeList 取槽：第 w 条用第 offset 个分配口，offset = 它前面
  // 要入队的条数。FreeList 口数也是 3，offset 不会到 3（到了也照 golden 回落到 0 号口）。
  // ===========================================================================
  logic                  allAddrCheck;
  logic [LD_W-1:0]       needEnqueue;
  logic [LD_W-1:0]       acceptedVec;
  logic [1:0]            enqOffset   [LD_W];
  logic                  canAccept   [LD_W];
  logic [IDX_W-1:0]      enqIndexVec [LD_W];

  logic [IDX_W-1:0]      fl_allocateSlot [LD_W];
  logic [LD_W-1:0]       fl_canAllocate;
  logic [5:0]            fl_validCount;
  logic                  fl_empty;

  assign allAddrCheck = (io_stIssuePtr == io_stAddrReadySqPtr);

  always_comb
    for (int w = 0; w < LD_W; w++) begin
      needEnqueue[w] = io_query_req[w].valid
                     & ~allAddrCheck & sq_is_before(io_stAddrReadySqPtr, io_query_req[w].sqIdx)
                     & ~need_flush(io_query_req[w].uop.robIdx, io_redirect);
      enqOffset[w] = '0;
      for (int k = 0; k < w; k++) enqOffset[w] += 2'(needEnqueue[k]);
      canAccept[w]   = fl_canAllocate[0];      // offset 越界（=3）时的回落项
      enqIndexVec[w] = fl_allocateSlot[0];
      for (int k = 0; k < LD_W; k++)
        if (enqOffset[w] == 2'(k)) begin
          canAccept[w]   = fl_canAllocate[k];
          enqIndexVec[w] = fl_allocateSlot[k];
        end
      io_query_req_ready[w] = ~needEnqueue[w] | canAccept[w];
      acceptedVec[w]        = needEnqueue[w] & canAccept[w];
    end

  // ===========================================================================
  // §2 槽状态更新
  // ---------------------------------------------------------------------------
  // Chisel 的 last-connect 语义决定优先级：
  //   allocated: 保持 < 入队置 1 < 出队清 0 < revoke 清 0   ⇒ next = ~free & (set | allocated)
  //   uop / datavalid: 多条流水同拍写同一槽（FreeList 保证不会）时，编号大的流水赢。
  // ===========================================================================
  logic                  enqSet      [RAW_SIZE];
  logic [LD_W-1:0]       enqHit      [RAW_SIZE];
  logic                  freeMask    [RAW_SIZE];   // 本拍释放（出队或 revoke）

  always_comb
    for (int i = 0; i < RAW_SIZE; i++) begin
      for (int w = 0; w < LD_W; w++)
        enqHit[i][w] = acceptedVec[w] & (enqIndexVec[w] == IDX_W'(i));
      enqSet[i] = |enqHit[i];
    end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < RAW_SIZE; i++) begin
        allocated[i] <= 1'b0;
        datavalid[i] <= 1'b0;
      end
    end
    else begin
      for (int i = 0; i < RAW_SIZE; i++) begin
        allocated[i] <= ~freeMask[i] & (enqSet[i] | allocated[i]);
        for (int w = 0; w < LD_W; w++)          // 升序写：编号大的流水最后写、优先
          if (enqHit[i][w]) datavalid[i] <= io_query_req[w].data_valid;
      end
    end
  end

  always_ff @(posedge clock)
    for (int i = 0; i < RAW_SIZE; i++)
      for (int w = 0; w < LD_W; w++)
        if (enqHit[i][w]) begin
          uop_isRVC[i]        <= io_query_req[w].uop.isRVC;
          uop_ftqPtr_flag[i]  <= io_query_req[w].uop.ftqPtr.flag;
          uop_ftqPtr_value[i] <= io_query_req[w].uop.ftqPtr.value;
          uop_ftqOffset[i]    <= io_query_req[w].uop.ftqOffset;
          uop_robIdx_flag[i]  <= io_query_req[w].uop.robIdx.flag;
          uop_robIdx_value[i] <= io_query_req[w].uop.robIdx.value;
          uop_runaheadId[i]   <= io_query_req[w].uop.runaheadId;
          uop_sqIdx_flag[i]   <= io_query_req[w].sqIdx.flag;
          uop_sqIdx_value[i]  <= io_query_req[w].sqIdx.value;
        end

  // ===========================================================================
  // §3 出队与 revoke
  // ---------------------------------------------------------------------------
  // 出队：槽被占用，且（它之前的 store 地址全就绪 或 它被 redirect 冲掉）。
  // revoke：load 入队的下一拍发现自己要 replay，按上一拍记下的槽号退回。
  //   lastCanAccept / lastAllocIndex 是 Gated(Valid)RegNext：值变了才打拍（异步复位 0）。
  //   revoke 只在"那个槽此刻仍被占用"时生效（读的是本拍的 allocated）。
  // ===========================================================================
  logic                  lastCanAccept  [LD_W];
  logic [IDX_W-1:0]      lastAllocIndex [LD_W];
  logic                  lastCanAcceptSame;   // 三位都没变 ⇒ 不打拍（GatedValidRegNext 的 Vec 版）
  logic                  deqNotBlock    [RAW_SIZE];
  logic                  deqFree        [RAW_SIZE];
  logic [LD_W-1:0]       revokeFire;

  always_comb begin
    lastCanAcceptSame = 1'b1;
    for (int w = 0; w < LD_W; w++)
      if (acceptedVec[w] != lastCanAccept[w]) lastCanAcceptSame = 1'b0;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < LD_W; w++) begin
        lastCanAccept[w]  <= 1'b0;
        lastAllocIndex[w] <= '0;
      end
    end
    else begin
      for (int w = 0; w < LD_W; w++) begin
        if (!lastCanAcceptSame) lastCanAccept[w] <= acceptedVec[w];
        if (enqIndexVec[w] != lastAllocIndex[w]) lastAllocIndex[w] <= enqIndexVec[w];   // 逐个门控
      end
    end
  end

  always_comb begin
    for (int i = 0; i < RAW_SIZE; i++) begin
      deqNotBlock[i] = allAddrCheck | ~sq_is_before(io_stAddrReadySqPtr, uop_sqIdx[i]);
      deqFree[i]     = allocated[i] & (deqNotBlock[i] | needCancel[i]);
      freeMask[i]    = deqFree[i];
    end
    for (int w = 0; w < LD_W; w++) begin
      revokeFire[w] = io_query_revoke[w] & lastCanAccept[w] & allocated[lastAllocIndex[w]];
      if (revokeFire[w]) freeMask[lastAllocIndex[w]] = 1'b1;
    end
  end

  logic [RAW_SIZE-1:0] freeMaskBits;
  always_comb
    for (int i = 0; i < RAW_SIZE; i++) freeMaskBits[i] = freeMask[i];

  FreeList_4 freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (fl_allocateSlot[0]),
    .io_allocateSlot_1 (fl_allocateSlot[1]),
    .io_allocateSlot_2 (fl_allocateSlot[2]),
    .io_canAllocate_0  (fl_canAllocate[0]),
    .io_canAllocate_1  (fl_canAllocate[1]),
    .io_canAllocate_2  (fl_canAllocate[2]),
    .io_doAllocate_0   (acceptedVec[0]),
    .io_doAllocate_1   (acceptedVec[1]),
    .io_doAllocate_2   (acceptedVec[2]),
    .io_free           (freeMaskBits),
    .io_validCount     (fl_validCount),
    .io_empty          (fl_empty)
  );

  // ===========================================================================
  // §4 违例检测（每条 store 流水一套）
  // ---------------------------------------------------------------------------
  // 两块 CAM 阵列与入队同步写（写口 = 3 条 load 流水，地址 = 分到的槽号）。
  // 查询侧：store 的 paddr/wlineflag/mask 先 RegEnable(storeIn.valid) 打一拍再送 CAM，
  // 与同样打了一拍的 entryNeedCheck 对齐。
  // ===========================================================================
  logic [PADDR_W-1:0]   st_paddr_q     [ST_W];   // 48 位全宽打拍，CAM 只取 [27:4]
  logic                 st_checkLine_q [ST_W];
  logic [MASK_W-1:0]    st_mask_q      [ST_W];

  always_ff @(posedge clock)
    for (int s = 0; s < ST_W; s++)
      if (io_storeIn[s].valid) begin
        st_paddr_q[s]     <= io_storeIn[s].paddr;
        st_checkLine_q[s] <= io_storeIn[s].wlineflag;
        st_mask_q[s]      <= io_storeIn[s].mask;
      end

  logic [PART_PADDR_W-1:0] cam_wPaddr [LD_W];
  logic [PART_PADDR_W-1:0] cam_qPaddr [ST_W];
  logic [RAW_SIZE-1:0]     paddrMatch [ST_W];
  logic [RAW_SIZE-1:0]     maskMatch  [ST_W];
  always_comb begin
    for (int w = 0; w < LD_W; w++)
      cam_wPaddr[w] = io_query_req[w].paddr[PART_PADDR_LO +: PART_PADDR_W];
    for (int s = 0; s < ST_W; s++)
      cam_qPaddr[s] = st_paddr_q[s][PART_PADDR_LO +: PART_PADDR_W];
  end

  // 两块 CAM 的扁平端口在这里逐位接上（golden 端口名，见 LqPAddrModule_1.sv / LqMaskModule.sv）
  // BEGIN GENERATED(lqraw-cam-inst)
  LqPAddrModule_1 paddrModule (
    .clock                   (clock),
    .reset                   (reset),
    .io_wen_0                (acceptedVec[0]),
    .io_wen_1                (acceptedVec[1]),
    .io_wen_2                (acceptedVec[2]),
    .io_waddr_0              (enqIndexVec[0]),
    .io_waddr_1              (enqIndexVec[1]),
    .io_waddr_2              (enqIndexVec[2]),
    .io_wdata_0              (cam_wPaddr[0]),
    .io_wdata_1              (cam_wPaddr[1]),
    .io_wdata_2              (cam_wPaddr[2]),
    .io_violationMdata_0     (cam_qPaddr[0]),
    .io_violationMdata_1     (cam_qPaddr[1]),
    .io_violationCheckLine_0 (st_checkLine_q[0]),
    .io_violationCheckLine_1 (st_checkLine_q[1]),
    .io_violationMmask_0_0   (paddrMatch[0][0]),
    .io_violationMmask_0_1   (paddrMatch[0][1]),
    .io_violationMmask_0_2   (paddrMatch[0][2]),
    .io_violationMmask_0_3   (paddrMatch[0][3]),
    .io_violationMmask_0_4   (paddrMatch[0][4]),
    .io_violationMmask_0_5   (paddrMatch[0][5]),
    .io_violationMmask_0_6   (paddrMatch[0][6]),
    .io_violationMmask_0_7   (paddrMatch[0][7]),
    .io_violationMmask_0_8   (paddrMatch[0][8]),
    .io_violationMmask_0_9   (paddrMatch[0][9]),
    .io_violationMmask_0_10  (paddrMatch[0][10]),
    .io_violationMmask_0_11  (paddrMatch[0][11]),
    .io_violationMmask_0_12  (paddrMatch[0][12]),
    .io_violationMmask_0_13  (paddrMatch[0][13]),
    .io_violationMmask_0_14  (paddrMatch[0][14]),
    .io_violationMmask_0_15  (paddrMatch[0][15]),
    .io_violationMmask_0_16  (paddrMatch[0][16]),
    .io_violationMmask_0_17  (paddrMatch[0][17]),
    .io_violationMmask_0_18  (paddrMatch[0][18]),
    .io_violationMmask_0_19  (paddrMatch[0][19]),
    .io_violationMmask_0_20  (paddrMatch[0][20]),
    .io_violationMmask_0_21  (paddrMatch[0][21]),
    .io_violationMmask_0_22  (paddrMatch[0][22]),
    .io_violationMmask_0_23  (paddrMatch[0][23]),
    .io_violationMmask_0_24  (paddrMatch[0][24]),
    .io_violationMmask_0_25  (paddrMatch[0][25]),
    .io_violationMmask_0_26  (paddrMatch[0][26]),
    .io_violationMmask_0_27  (paddrMatch[0][27]),
    .io_violationMmask_0_28  (paddrMatch[0][28]),
    .io_violationMmask_0_29  (paddrMatch[0][29]),
    .io_violationMmask_0_30  (paddrMatch[0][30]),
    .io_violationMmask_0_31  (paddrMatch[0][31]),
    .io_violationMmask_1_0   (paddrMatch[1][0]),
    .io_violationMmask_1_1   (paddrMatch[1][1]),
    .io_violationMmask_1_2   (paddrMatch[1][2]),
    .io_violationMmask_1_3   (paddrMatch[1][3]),
    .io_violationMmask_1_4   (paddrMatch[1][4]),
    .io_violationMmask_1_5   (paddrMatch[1][5]),
    .io_violationMmask_1_6   (paddrMatch[1][6]),
    .io_violationMmask_1_7   (paddrMatch[1][7]),
    .io_violationMmask_1_8   (paddrMatch[1][8]),
    .io_violationMmask_1_9   (paddrMatch[1][9]),
    .io_violationMmask_1_10  (paddrMatch[1][10]),
    .io_violationMmask_1_11  (paddrMatch[1][11]),
    .io_violationMmask_1_12  (paddrMatch[1][12]),
    .io_violationMmask_1_13  (paddrMatch[1][13]),
    .io_violationMmask_1_14  (paddrMatch[1][14]),
    .io_violationMmask_1_15  (paddrMatch[1][15]),
    .io_violationMmask_1_16  (paddrMatch[1][16]),
    .io_violationMmask_1_17  (paddrMatch[1][17]),
    .io_violationMmask_1_18  (paddrMatch[1][18]),
    .io_violationMmask_1_19  (paddrMatch[1][19]),
    .io_violationMmask_1_20  (paddrMatch[1][20]),
    .io_violationMmask_1_21  (paddrMatch[1][21]),
    .io_violationMmask_1_22  (paddrMatch[1][22]),
    .io_violationMmask_1_23  (paddrMatch[1][23]),
    .io_violationMmask_1_24  (paddrMatch[1][24]),
    .io_violationMmask_1_25  (paddrMatch[1][25]),
    .io_violationMmask_1_26  (paddrMatch[1][26]),
    .io_violationMmask_1_27  (paddrMatch[1][27]),
    .io_violationMmask_1_28  (paddrMatch[1][28]),
    .io_violationMmask_1_29  (paddrMatch[1][29]),
    .io_violationMmask_1_30  (paddrMatch[1][30]),
    .io_violationMmask_1_31  (paddrMatch[1][31])
  );
  LqMaskModule maskModule (
    .clock                   (clock),
    .reset                   (reset),
    .io_wen_0                (acceptedVec[0]),
    .io_wen_1                (acceptedVec[1]),
    .io_wen_2                (acceptedVec[2]),
    .io_waddr_0              (enqIndexVec[0]),
    .io_waddr_1              (enqIndexVec[1]),
    .io_waddr_2              (enqIndexVec[2]),
    .io_wdata_0              (io_query_req[0].mask),
    .io_wdata_1              (io_query_req[1].mask),
    .io_wdata_2              (io_query_req[2].mask),
    .io_violationMdata_0     (st_mask_q[0]),
    .io_violationMdata_1     (st_mask_q[1]),
    .io_violationMmask_0_0   (maskMatch[0][0]),
    .io_violationMmask_0_1   (maskMatch[0][1]),
    .io_violationMmask_0_2   (maskMatch[0][2]),
    .io_violationMmask_0_3   (maskMatch[0][3]),
    .io_violationMmask_0_4   (maskMatch[0][4]),
    .io_violationMmask_0_5   (maskMatch[0][5]),
    .io_violationMmask_0_6   (maskMatch[0][6]),
    .io_violationMmask_0_7   (maskMatch[0][7]),
    .io_violationMmask_0_8   (maskMatch[0][8]),
    .io_violationMmask_0_9   (maskMatch[0][9]),
    .io_violationMmask_0_10  (maskMatch[0][10]),
    .io_violationMmask_0_11  (maskMatch[0][11]),
    .io_violationMmask_0_12  (maskMatch[0][12]),
    .io_violationMmask_0_13  (maskMatch[0][13]),
    .io_violationMmask_0_14  (maskMatch[0][14]),
    .io_violationMmask_0_15  (maskMatch[0][15]),
    .io_violationMmask_0_16  (maskMatch[0][16]),
    .io_violationMmask_0_17  (maskMatch[0][17]),
    .io_violationMmask_0_18  (maskMatch[0][18]),
    .io_violationMmask_0_19  (maskMatch[0][19]),
    .io_violationMmask_0_20  (maskMatch[0][20]),
    .io_violationMmask_0_21  (maskMatch[0][21]),
    .io_violationMmask_0_22  (maskMatch[0][22]),
    .io_violationMmask_0_23  (maskMatch[0][23]),
    .io_violationMmask_0_24  (maskMatch[0][24]),
    .io_violationMmask_0_25  (maskMatch[0][25]),
    .io_violationMmask_0_26  (maskMatch[0][26]),
    .io_violationMmask_0_27  (maskMatch[0][27]),
    .io_violationMmask_0_28  (maskMatch[0][28]),
    .io_violationMmask_0_29  (maskMatch[0][29]),
    .io_violationMmask_0_30  (maskMatch[0][30]),
    .io_violationMmask_0_31  (maskMatch[0][31]),
    .io_violationMmask_1_0   (maskMatch[1][0]),
    .io_violationMmask_1_1   (maskMatch[1][1]),
    .io_violationMmask_1_2   (maskMatch[1][2]),
    .io_violationMmask_1_3   (maskMatch[1][3]),
    .io_violationMmask_1_4   (maskMatch[1][4]),
    .io_violationMmask_1_5   (maskMatch[1][5]),
    .io_violationMmask_1_6   (maskMatch[1][6]),
    .io_violationMmask_1_7   (maskMatch[1][7]),
    .io_violationMmask_1_8   (maskMatch[1][8]),
    .io_violationMmask_1_9   (maskMatch[1][9]),
    .io_violationMmask_1_10  (maskMatch[1][10]),
    .io_violationMmask_1_11  (maskMatch[1][11]),
    .io_violationMmask_1_12  (maskMatch[1][12]),
    .io_violationMmask_1_13  (maskMatch[1][13]),
    .io_violationMmask_1_14  (maskMatch[1][14]),
    .io_violationMmask_1_15  (maskMatch[1][15]),
    .io_violationMmask_1_16  (maskMatch[1][16]),
    .io_violationMmask_1_17  (maskMatch[1][17]),
    .io_violationMmask_1_18  (maskMatch[1][18]),
    .io_violationMmask_1_19  (maskMatch[1][19]),
    .io_violationMmask_1_20  (maskMatch[1][20]),
    .io_violationMmask_1_21  (maskMatch[1][21]),
    .io_violationMmask_1_22  (maskMatch[1][22]),
    .io_violationMmask_1_23  (maskMatch[1][23]),
    .io_violationMmask_1_24  (maskMatch[1][24]),
    .io_violationMmask_1_25  (maskMatch[1][25]),
    .io_violationMmask_1_26  (maskMatch[1][26]),
    .io_violationMmask_1_27  (maskMatch[1][27]),
    .io_violationMmask_1_28  (maskMatch[1][28]),
    .io_violationMmask_1_29  (maskMatch[1][29]),
    .io_violationMmask_1_30  (maskMatch[1][30]),
    .io_violationMmask_1_31  (maskMatch[1][31])
  );
  // END GENERATED

  // ---- 每条 store 流水的检测与两级选最老 ----
  // ★寄存器一律按字段拆成独立数组（SoA），与 golden 的扁平寄存器一一对应；
  //   结构体（sel_uop_t / sel_cand_t / redirect_t）只用在组合逻辑里读着方便。
  logic entryNeedCheckNext [ST_W][RAW_SIZE];
  logic entryNeedCheck     [ST_W][RAW_SIZE];   // GatedValidRegNext（异步复位）
  logic entryNeedCheckSame [ST_W];             // 整个向量没变 ⇒ 不打拍（门控时钟写法）

  always_comb
    for (int s = 0; s < ST_W; s++) begin
      entryNeedCheckSame[s] = 1'b1;
      for (int j = 0; j < RAW_SIZE; j++) begin
        // 槽占用 & store 有效 & load 比 store 年轻 & load 已有数据 & load 没被冲掉
        entryNeedCheckNext[s][j] = allocated[j] & io_storeIn[s].valid
                                 & rob_is_after(uop_robIdx[j], io_storeIn[s].robIdx)
                                 & datavalid[j] & ~needCancel[j];
        if (entryNeedCheckNext[s][j] != entryNeedCheck[s][j]) entryNeedCheckSame[s] = 1'b0;
      end
    end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < ST_W; s++)
        for (int j = 0; j < RAW_SIZE; j++) entryNeedCheck[s][j] <= 1'b0;
    end
    else begin
      for (int s = 0; s < ST_W; s++)
        if (!entryNeedCheckSame[s])
          for (int j = 0; j < RAW_SIZE; j++) entryNeedCheck[s][j] <= entryNeedCheckNext[s][j];
    end
  end

  // 第一级：每组 8 选 1（组内两两比较的二叉树），结果打一拍
  sel_cand_t grpIn     [ST_W][RAW_SIZE];
  sel_cand_t grpL1     [ST_W][NUM_GROUPS][4];
  sel_cand_t grpL2     [ST_W][NUM_GROUPS][2];
  sel_cand_t grpOldest [ST_W][NUM_GROUPS];

  always_comb
    for (int s = 0; s < ST_W; s++) begin
      for (int j = 0; j < RAW_SIZE; j++)
        grpIn[s][j] = sel_cand_t'{valid: paddrMatch[s][j] & maskMatch[s][j] & entryNeedCheck[s][j],
                                  bits:  uop_sel[j]};
      for (int g = 0; g < NUM_GROUPS; g++) begin
        for (int k = 0; k < 4; k++)
          grpL1[s][g][k] = select_older(grpIn[s][g*GROUP_SIZE + 2*k], grpIn[s][g*GROUP_SIZE + 2*k + 1]);
        for (int k = 0; k < 2; k++)
          grpL2[s][g][k] = select_older(grpL1[s][g][2*k], grpL1[s][g][2*k + 1]);
        grpOldest[s][g] = select_older(grpL2[s][g][0], grpL2[s][g][1]);
      end
    end

  // 第一级组寄存器（全部不复位）：selValidNext = RegNext(valid)，bits = RegEnable(bits, valid)，
  // 以及每组各一份 RegNext(io.redirect)
  logic        grpValid_q               [ST_W][NUM_GROUPS];
  logic        grpUop_isRVC_q           [ST_W][NUM_GROUPS];
  logic        grpUop_ftqPtr_flag_q     [ST_W][NUM_GROUPS];
  logic [5:0]  grpUop_ftqPtr_value_q    [ST_W][NUM_GROUPS];
  logic [3:0]  grpUop_ftqOffset_q       [ST_W][NUM_GROUPS];
  logic        grpUop_robIdx_flag_q     [ST_W][NUM_GROUPS];
  logic [7:0]  grpUop_robIdx_value_q    [ST_W][NUM_GROUPS];
  logic [63:0] grpUop_runaheadId_q      [ST_W][NUM_GROUPS];
  logic        grpRedirect_valid_q      [ST_W][NUM_GROUPS];
  logic        grpRedirect_robIdx_flag_q  [ST_W][NUM_GROUPS];
  logic [7:0]  grpRedirect_robIdx_value_q [ST_W][NUM_GROUPS];
  logic        grpRedirect_level_q      [ST_W][NUM_GROUPS];

  always_ff @(posedge clock)
    for (int s = 0; s < ST_W; s++)
      for (int g = 0; g < NUM_GROUPS; g++) begin
        grpValid_q[s][g] <= grpOldest[s][g].valid;
        if (grpOldest[s][g].valid) begin
          grpUop_isRVC_q[s][g]        <= grpOldest[s][g].bits.isRVC;
          grpUop_ftqPtr_flag_q[s][g]  <= grpOldest[s][g].bits.ftqPtr.flag;
          grpUop_ftqPtr_value_q[s][g] <= grpOldest[s][g].bits.ftqPtr.value;
          grpUop_ftqOffset_q[s][g]    <= grpOldest[s][g].bits.ftqOffset;
          grpUop_robIdx_flag_q[s][g]  <= grpOldest[s][g].bits.robIdx.flag;
          grpUop_robIdx_value_q[s][g] <= grpOldest[s][g].bits.robIdx.value;
          grpUop_runaheadId_q[s][g]   <= grpOldest[s][g].bits.runaheadId;
        end
        grpRedirect_valid_q[s][g]        <= io_redirect.valid;
        grpRedirect_robIdx_flag_q[s][g]  <= io_redirect.robIdx.flag;
        grpRedirect_robIdx_value_q[s][g] <= io_redirect.robIdx.value;
        grpRedirect_level_q[s][g]        <= io_redirect.level;
      end

  // 组结果在第二级被用之前再过滤一次：被本拍或上一拍的 redirect 冲掉的不算
  sel_uop_t  grpBits        [ST_W][NUM_GROUPS];
  redirect_t grpRedirectReg [ST_W][NUM_GROUPS];
  sel_cand_t grpOut         [ST_W][NUM_GROUPS];
  always_comb
    for (int s = 0; s < ST_W; s++)
      for (int g = 0; g < NUM_GROUPS; g++) begin
        grpBits[s][g] = sel_uop_t'{
          isRVC:      grpUop_isRVC_q[s][g],
          ftqPtr:     ftq_ptr_t'{flag: grpUop_ftqPtr_flag_q[s][g], value: grpUop_ftqPtr_value_q[s][g]},
          ftqOffset:  grpUop_ftqOffset_q[s][g],
          robIdx:     rob_ptr_t'{flag: grpUop_robIdx_flag_q[s][g], value: grpUop_robIdx_value_q[s][g]},
          runaheadId: grpUop_runaheadId_q[s][g]};
        grpRedirectReg[s][g] = redirect_t'{
          valid:  grpRedirect_valid_q[s][g],
          robIdx: rob_ptr_t'{flag: grpRedirect_robIdx_flag_q[s][g],
                             value: grpRedirect_robIdx_value_q[s][g]},
          level:  grpRedirect_level_q[s][g]};
        grpOut[s][g] = sel_cand_t'{
          valid: grpValid_q[s][g]
               & ~need_flush(grpBits[s][g].robIdx, io_redirect)
               & ~need_flush(grpBits[s][g].robIdx, grpRedirectReg[s][g]),
          bits:  grpBits[s][g]};
      end

  // 第二级：4 组选 1，打一拍
  sel_cand_t lastL1     [ST_W][2];
  sel_cand_t lastOldest [ST_W];
  always_comb
    for (int s = 0; s < ST_W; s++) begin
      for (int k = 0; k < 2; k++) lastL1[s][k] = select_older(grpOut[s][2*k], grpOut[s][2*k + 1]);
      lastOldest[s] = select_older(lastL1[s][0], lastL1[s][1]);
    end

  logic        lastValid_q               [ST_W];   // GatedValidRegNext（异步复位）
  logic        lastUop_isRVC_q           [ST_W];   // 以下 RegEnable(bits, valid)，不复位
  logic        lastUop_ftqPtr_flag_q     [ST_W];
  logic [5:0]  lastUop_ftqPtr_value_q    [ST_W];
  logic [3:0]  lastUop_ftqOffset_q       [ST_W];
  logic        lastUop_robIdx_flag_q     [ST_W];
  logic [7:0]  lastUop_robIdx_value_q    [ST_W];
  logic [63:0] lastUop_runaheadId_q      [ST_W];
  logic        lastRedirect_valid_q        [ST_W]; // RegNext(io.redirect)，不复位
  logic        lastRedirect_robIdx_flag_q  [ST_W];
  logic [7:0]  lastRedirect_robIdx_value_q [ST_W];
  logic        lastRedirect_level_q        [ST_W];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < ST_W; s++) lastValid_q[s] <= 1'b0;
    end
    else begin
      for (int s = 0; s < ST_W; s++) lastValid_q[s] <= lastOldest[s].valid;
    end
  end

  always_ff @(posedge clock)
    for (int s = 0; s < ST_W; s++) begin
      if (lastOldest[s].valid) begin
        lastUop_isRVC_q[s]        <= lastOldest[s].bits.isRVC;
        lastUop_ftqPtr_flag_q[s]  <= lastOldest[s].bits.ftqPtr.flag;
        lastUop_ftqPtr_value_q[s] <= lastOldest[s].bits.ftqPtr.value;
        lastUop_ftqOffset_q[s]    <= lastOldest[s].bits.ftqOffset;
        lastUop_robIdx_flag_q[s]  <= lastOldest[s].bits.robIdx.flag;
        lastUop_robIdx_value_q[s] <= lastOldest[s].bits.robIdx.value;
        lastUop_runaheadId_q[s]   <= lastOldest[s].bits.runaheadId;
      end
      lastRedirect_valid_q[s]        <= io_redirect.valid;
      lastRedirect_robIdx_flag_q[s]  <= io_redirect.robIdx.flag;
      lastRedirect_robIdx_value_q[s] <= io_redirect.robIdx.value;
      lastRedirect_level_q[s]        <= io_redirect.level;
    end

  rob_ptr_t  lastRobIdx      [ST_W];
  redirect_t lastRedirectReg [ST_W];
  always_comb
    for (int s = 0; s < ST_W; s++) begin
      lastRobIdx[s]      = rob_ptr_t'{flag: lastUop_robIdx_flag_q[s], value: lastUop_robIdx_value_q[s]};
      lastRedirectReg[s] = redirect_t'{
        valid:  lastRedirect_valid_q[s],
        robIdx: rob_ptr_t'{flag: lastRedirect_robIdx_flag_q[s], value: lastRedirect_robIdx_value_q[s]},
        level:  lastRedirect_level_q[s]};
    end

  // store 侧信息打 3 拍（TotalSelectCycles = ceil(log2(32)/log2(8)) + 1 = 3），与选择结果对齐
  logic       stValidDelayed [ST_W];
  ftq_ptr_t   stFtqIdx       [ST_W];
  logic [3:0] stFtqOffset    [ST_W];

  for (genvar s = 0; s < ST_W; s++) begin : g_st
    DelayN_297 rollbackLqWb_valid_delay (
      .clock  (clock),
      .io_in  (io_storeIn[s].valid & ~io_storeIn[s].miss),
      .io_out (stValidDelayed[s])
    );
    DelayNWithValid_148 stFtqIdx_pipMod (
      .clock             (clock),
      .reset             (reset),
      .io_in_bits_flag   (io_storeIn[s].ftqPtr.flag),
      .io_in_bits_value  (io_storeIn[s].ftqPtr.value),
      .io_in_valid       (io_storeIn[s].valid),
      .io_out_bits_flag  (stFtqIdx[s].flag),
      .io_out_bits_value (stFtqIdx[s].value)
    );
    DelayNWithValid_149 stFtqOffset_pipMod (
      .clock       (clock),
      .reset       (reset),
      .io_in_bits  (io_storeIn[s].ftqOffset),
      .io_in_valid (io_storeIn[s].valid),
      .io_out_bits (stFtqOffset[s])
    );
  end

  // ===========================================================================
  // §5 输出与 perf
  // ===========================================================================
  always_comb
    for (int s = 0; s < ST_W; s++)
      io_rollback[s] = rollback_t'{
        valid:       lastValid_q[s] & ~need_flush(lastRobIdx[s], lastRedirectReg[s])
                   & stValidDelayed[s],
        isRVC:       lastUop_isRVC_q[s],
        robIdx:      lastRobIdx[s],
        ftqIdx:      ftq_ptr_t'{flag: lastUop_ftqPtr_flag_q[s], value: lastUop_ftqPtr_value_q[s]},
        ftqOffset:   lastUop_ftqOffset_q[s],
        stFtqIdx:    stFtqIdx[s],
        stFtqOffset: stFtqOffset[s],
        runaheadId:  lastUop_runaheadId_q[s]};

  assign io_lqFull = fl_empty;

  // perf：本拍入队条数（req.fire 计数）/ 本拍是否有 rollback，各打两拍
  logic [1:0] canEnqCount;
  logic       rollbackValid;
  logic [1:0] perfEnq_q [2];
  logic       perfRollback_q [2];
  always_comb begin
    canEnqCount = '0;
    for (int w = 0; w < LD_W; w++)
      canEnqCount += 2'(io_query_req_ready[w] & io_query_req[w].valid);
    rollbackValid = io_rollback[0].valid | io_rollback[1].valid;
  end

  always_ff @(posedge clock) begin
    perfEnq_q[0]      <= canEnqCount;
    perfEnq_q[1]      <= perfEnq_q[0];
    perfRollback_q[0] <= rollbackValid;
    perfRollback_q[1] <= perfRollback_q[0];
  end

  assign io_perf_0_value = {4'h0, perfEnq_q[1]};
  assign io_perf_1_value = {5'h0, perfRollback_q[1]};

endmodule


// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden 逐位同名同序，只做打包/改名
// （scripts/gen_lqraw.py 生成，勿手改）
// -----------------------------------------------------------------------------
// BEGIN GENERATED(lqraw-wrapper)
module LoadQueueRAW
  import loadqueueraw_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  output        io_query_0_req_ready,
  input         io_query_0_req_valid,
  input         io_query_0_req_bits_uop_preDecodeInfo_isRVC,
  input         io_query_0_req_bits_uop_ftqPtr_flag,
  input  [5:0]  io_query_0_req_bits_uop_ftqPtr_value,
  input  [3:0]  io_query_0_req_bits_uop_ftqOffset,
  input         io_query_0_req_bits_uop_robIdx_flag,
  input  [7:0]  io_query_0_req_bits_uop_robIdx_value,
  input  [63:0] io_query_0_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input         io_query_0_req_bits_uop_sqIdx_flag,
  input  [5:0]  io_query_0_req_bits_uop_sqIdx_value,
  input  [15:0] io_query_0_req_bits_mask,
  input  [47:0] io_query_0_req_bits_paddr,
  input         io_query_0_req_bits_data_valid,
  input         io_query_0_revoke,
  output        io_query_1_req_ready,
  input         io_query_1_req_valid,
  input         io_query_1_req_bits_uop_preDecodeInfo_isRVC,
  input         io_query_1_req_bits_uop_ftqPtr_flag,
  input  [5:0]  io_query_1_req_bits_uop_ftqPtr_value,
  input  [3:0]  io_query_1_req_bits_uop_ftqOffset,
  input         io_query_1_req_bits_uop_robIdx_flag,
  input  [7:0]  io_query_1_req_bits_uop_robIdx_value,
  input  [63:0] io_query_1_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input         io_query_1_req_bits_uop_sqIdx_flag,
  input  [5:0]  io_query_1_req_bits_uop_sqIdx_value,
  input  [15:0] io_query_1_req_bits_mask,
  input  [47:0] io_query_1_req_bits_paddr,
  input         io_query_1_req_bits_data_valid,
  input         io_query_1_revoke,
  output        io_query_2_req_ready,
  input         io_query_2_req_valid,
  input         io_query_2_req_bits_uop_preDecodeInfo_isRVC,
  input         io_query_2_req_bits_uop_ftqPtr_flag,
  input  [5:0]  io_query_2_req_bits_uop_ftqPtr_value,
  input  [3:0]  io_query_2_req_bits_uop_ftqOffset,
  input         io_query_2_req_bits_uop_robIdx_flag,
  input  [7:0]  io_query_2_req_bits_uop_robIdx_value,
  input  [63:0] io_query_2_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input         io_query_2_req_bits_uop_sqIdx_flag,
  input  [5:0]  io_query_2_req_bits_uop_sqIdx_value,
  input  [15:0] io_query_2_req_bits_mask,
  input  [47:0] io_query_2_req_bits_paddr,
  input         io_query_2_req_bits_data_valid,
  input         io_query_2_revoke,
  input         io_storeIn_0_valid,
  input         io_storeIn_0_bits_uop_ftqPtr_flag,
  input  [5:0]  io_storeIn_0_bits_uop_ftqPtr_value,
  input  [3:0]  io_storeIn_0_bits_uop_ftqOffset,
  input         io_storeIn_0_bits_uop_robIdx_flag,
  input  [7:0]  io_storeIn_0_bits_uop_robIdx_value,
  input  [47:0] io_storeIn_0_bits_paddr,
  input  [15:0] io_storeIn_0_bits_mask,
  input         io_storeIn_0_bits_wlineflag,
  input         io_storeIn_0_bits_miss,
  input         io_storeIn_1_valid,
  input         io_storeIn_1_bits_uop_ftqPtr_flag,
  input  [5:0]  io_storeIn_1_bits_uop_ftqPtr_value,
  input  [3:0]  io_storeIn_1_bits_uop_ftqOffset,
  input         io_storeIn_1_bits_uop_robIdx_flag,
  input  [7:0]  io_storeIn_1_bits_uop_robIdx_value,
  input  [47:0] io_storeIn_1_bits_paddr,
  input  [15:0] io_storeIn_1_bits_mask,
  input         io_storeIn_1_bits_wlineflag,
  input         io_storeIn_1_bits_miss,
  output        io_rollback_0_valid,
  output        io_rollback_0_bits_isRVC,
  output        io_rollback_0_bits_robIdx_flag,
  output [7:0]  io_rollback_0_bits_robIdx_value,
  output        io_rollback_0_bits_ftqIdx_flag,
  output [5:0]  io_rollback_0_bits_ftqIdx_value,
  output [3:0]  io_rollback_0_bits_ftqOffset,
  output        io_rollback_0_bits_stFtqIdx_flag,
  output [5:0]  io_rollback_0_bits_stFtqIdx_value,
  output [3:0]  io_rollback_0_bits_stFtqOffset,
  output [63:0] io_rollback_0_bits_debug_runahead_checkpoint_id,
  output        io_rollback_1_valid,
  output        io_rollback_1_bits_isRVC,
  output        io_rollback_1_bits_robIdx_flag,
  output [7:0]  io_rollback_1_bits_robIdx_value,
  output        io_rollback_1_bits_ftqIdx_flag,
  output [5:0]  io_rollback_1_bits_ftqIdx_value,
  output [3:0]  io_rollback_1_bits_ftqOffset,
  output        io_rollback_1_bits_stFtqIdx_flag,
  output [5:0]  io_rollback_1_bits_stFtqIdx_value,
  output [3:0]  io_rollback_1_bits_stFtqOffset,
  output [63:0] io_rollback_1_bits_debug_runahead_checkpoint_id,
  input         io_stAddrReadySqPtr_flag,
  input  [5:0]  io_stAddrReadySqPtr_value,
  input         io_stIssuePtr_flag,
  input  [5:0]  io_stIssuePtr_value,
  output        io_lqFull,
  output [5:0]  io_perf_0_value,
  output [5:0]  io_perf_1_value
);
  // golden 的端口是 firtool 完全展平的标量；这里按语义重新装成结构体交给可读核。
  redirect_t              redirect;
  query_req_t [LD_W-1:0]  query_req;
  logic       [LD_W-1:0]  query_ready;
  logic       [LD_W-1:0]  query_revoke;
  store_in_t  [ST_W-1:0]  storeIn;
  rollback_t  [ST_W-1:0]  rollback;
  sq_ptr_t                stAddrReadySqPtr;
  sq_ptr_t                stIssuePtr;

  assign redirect.valid = io_redirect_valid;
  assign redirect.robIdx.flag = io_redirect_bits_robIdx_flag;
  assign redirect.robIdx.value = io_redirect_bits_robIdx_value;
  assign redirect.level = io_redirect_bits_level;
  assign io_query_0_req_ready = query_ready[0];
  assign query_req[0].valid = io_query_0_req_valid;
  assign query_req[0].uop.isRVC = io_query_0_req_bits_uop_preDecodeInfo_isRVC;
  assign query_req[0].uop.ftqPtr.flag = io_query_0_req_bits_uop_ftqPtr_flag;
  assign query_req[0].uop.ftqPtr.value = io_query_0_req_bits_uop_ftqPtr_value;
  assign query_req[0].uop.ftqOffset = io_query_0_req_bits_uop_ftqOffset;
  assign query_req[0].uop.robIdx.flag = io_query_0_req_bits_uop_robIdx_flag;
  assign query_req[0].uop.robIdx.value = io_query_0_req_bits_uop_robIdx_value;
  assign query_req[0].uop.runaheadId = io_query_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
  assign query_req[0].sqIdx.flag = io_query_0_req_bits_uop_sqIdx_flag;
  assign query_req[0].sqIdx.value = io_query_0_req_bits_uop_sqIdx_value;
  assign query_req[0].mask = io_query_0_req_bits_mask;
  assign query_req[0].paddr = io_query_0_req_bits_paddr;
  assign query_req[0].data_valid = io_query_0_req_bits_data_valid;
  assign query_revoke[0] = io_query_0_revoke;
  assign io_query_1_req_ready = query_ready[1];
  assign query_req[1].valid = io_query_1_req_valid;
  assign query_req[1].uop.isRVC = io_query_1_req_bits_uop_preDecodeInfo_isRVC;
  assign query_req[1].uop.ftqPtr.flag = io_query_1_req_bits_uop_ftqPtr_flag;
  assign query_req[1].uop.ftqPtr.value = io_query_1_req_bits_uop_ftqPtr_value;
  assign query_req[1].uop.ftqOffset = io_query_1_req_bits_uop_ftqOffset;
  assign query_req[1].uop.robIdx.flag = io_query_1_req_bits_uop_robIdx_flag;
  assign query_req[1].uop.robIdx.value = io_query_1_req_bits_uop_robIdx_value;
  assign query_req[1].uop.runaheadId = io_query_1_req_bits_uop_debugInfo_runahead_checkpoint_id;
  assign query_req[1].sqIdx.flag = io_query_1_req_bits_uop_sqIdx_flag;
  assign query_req[1].sqIdx.value = io_query_1_req_bits_uop_sqIdx_value;
  assign query_req[1].mask = io_query_1_req_bits_mask;
  assign query_req[1].paddr = io_query_1_req_bits_paddr;
  assign query_req[1].data_valid = io_query_1_req_bits_data_valid;
  assign query_revoke[1] = io_query_1_revoke;
  assign io_query_2_req_ready = query_ready[2];
  assign query_req[2].valid = io_query_2_req_valid;
  assign query_req[2].uop.isRVC = io_query_2_req_bits_uop_preDecodeInfo_isRVC;
  assign query_req[2].uop.ftqPtr.flag = io_query_2_req_bits_uop_ftqPtr_flag;
  assign query_req[2].uop.ftqPtr.value = io_query_2_req_bits_uop_ftqPtr_value;
  assign query_req[2].uop.ftqOffset = io_query_2_req_bits_uop_ftqOffset;
  assign query_req[2].uop.robIdx.flag = io_query_2_req_bits_uop_robIdx_flag;
  assign query_req[2].uop.robIdx.value = io_query_2_req_bits_uop_robIdx_value;
  assign query_req[2].uop.runaheadId = io_query_2_req_bits_uop_debugInfo_runahead_checkpoint_id;
  assign query_req[2].sqIdx.flag = io_query_2_req_bits_uop_sqIdx_flag;
  assign query_req[2].sqIdx.value = io_query_2_req_bits_uop_sqIdx_value;
  assign query_req[2].mask = io_query_2_req_bits_mask;
  assign query_req[2].paddr = io_query_2_req_bits_paddr;
  assign query_req[2].data_valid = io_query_2_req_bits_data_valid;
  assign query_revoke[2] = io_query_2_revoke;
  assign storeIn[0].valid = io_storeIn_0_valid;
  assign storeIn[0].ftqPtr.flag = io_storeIn_0_bits_uop_ftqPtr_flag;
  assign storeIn[0].ftqPtr.value = io_storeIn_0_bits_uop_ftqPtr_value;
  assign storeIn[0].ftqOffset = io_storeIn_0_bits_uop_ftqOffset;
  assign storeIn[0].robIdx.flag = io_storeIn_0_bits_uop_robIdx_flag;
  assign storeIn[0].robIdx.value = io_storeIn_0_bits_uop_robIdx_value;
  assign storeIn[0].paddr = io_storeIn_0_bits_paddr;
  assign storeIn[0].mask = io_storeIn_0_bits_mask;
  assign storeIn[0].wlineflag = io_storeIn_0_bits_wlineflag;
  assign storeIn[0].miss = io_storeIn_0_bits_miss;
  assign storeIn[1].valid = io_storeIn_1_valid;
  assign storeIn[1].ftqPtr.flag = io_storeIn_1_bits_uop_ftqPtr_flag;
  assign storeIn[1].ftqPtr.value = io_storeIn_1_bits_uop_ftqPtr_value;
  assign storeIn[1].ftqOffset = io_storeIn_1_bits_uop_ftqOffset;
  assign storeIn[1].robIdx.flag = io_storeIn_1_bits_uop_robIdx_flag;
  assign storeIn[1].robIdx.value = io_storeIn_1_bits_uop_robIdx_value;
  assign storeIn[1].paddr = io_storeIn_1_bits_paddr;
  assign storeIn[1].mask = io_storeIn_1_bits_mask;
  assign storeIn[1].wlineflag = io_storeIn_1_bits_wlineflag;
  assign storeIn[1].miss = io_storeIn_1_bits_miss;
  assign io_rollback_0_valid = rollback[0].valid;
  assign io_rollback_0_bits_isRVC = rollback[0].isRVC;
  assign io_rollback_0_bits_robIdx_flag = rollback[0].robIdx.flag;
  assign io_rollback_0_bits_robIdx_value = rollback[0].robIdx.value;
  assign io_rollback_0_bits_ftqIdx_flag = rollback[0].ftqIdx.flag;
  assign io_rollback_0_bits_ftqIdx_value = rollback[0].ftqIdx.value;
  assign io_rollback_0_bits_ftqOffset = rollback[0].ftqOffset;
  assign io_rollback_0_bits_stFtqIdx_flag = rollback[0].stFtqIdx.flag;
  assign io_rollback_0_bits_stFtqIdx_value = rollback[0].stFtqIdx.value;
  assign io_rollback_0_bits_stFtqOffset = rollback[0].stFtqOffset;
  assign io_rollback_0_bits_debug_runahead_checkpoint_id = rollback[0].runaheadId;
  assign io_rollback_1_valid = rollback[1].valid;
  assign io_rollback_1_bits_isRVC = rollback[1].isRVC;
  assign io_rollback_1_bits_robIdx_flag = rollback[1].robIdx.flag;
  assign io_rollback_1_bits_robIdx_value = rollback[1].robIdx.value;
  assign io_rollback_1_bits_ftqIdx_flag = rollback[1].ftqIdx.flag;
  assign io_rollback_1_bits_ftqIdx_value = rollback[1].ftqIdx.value;
  assign io_rollback_1_bits_ftqOffset = rollback[1].ftqOffset;
  assign io_rollback_1_bits_stFtqIdx_flag = rollback[1].stFtqIdx.flag;
  assign io_rollback_1_bits_stFtqIdx_value = rollback[1].stFtqIdx.value;
  assign io_rollback_1_bits_stFtqOffset = rollback[1].stFtqOffset;
  assign io_rollback_1_bits_debug_runahead_checkpoint_id = rollback[1].runaheadId;
  assign stAddrReadySqPtr.flag = io_stAddrReadySqPtr_flag;
  assign stAddrReadySqPtr.value = io_stAddrReadySqPtr_value;
  assign stIssuePtr.flag = io_stIssuePtr_flag;
  assign stIssuePtr.value = io_stIssuePtr_value;

  xs_LoadQueueRAW_core u_core (
    .clock                (clock),
    .reset                (reset),
    .io_redirect          (redirect),
    .io_query_req         (query_req),
    .io_query_req_ready   (query_ready),
    .io_query_revoke      (query_revoke),
    .io_storeIn           (storeIn),
    .io_rollback          (rollback),
    .io_stAddrReadySqPtr  (stAddrReadySqPtr),
    .io_stIssuePtr        (stIssuePtr),
    .io_lqFull            (io_lqFull),
    .io_perf_0_value      (io_perf_0_value),
    .io_perf_1_value      (io_perf_1_value)
  );
endmodule
// END GENERATED
