// =============================================================================
//  StoreMisalignBuffer —— 非对齐 store 拆分缓冲（可读核 xs_StoreMisalignBuffer_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/StoreMisalignBuffer.scala
//  类型/常量/纯函数见 storemisalignbuffer_pkg.sv。
//
//  ## 它解决什么问题
//  当 StoreUnit 在流水里发现一条 store 跨 16B 边界，无法一次写完，于是送入本缓冲。
//  本缓冲把它拆成 low/high 两次「对齐子 store」，依次经 splitStoreReq 发回 StoreUnit
//  重走流水（写地址进 StoreQueue）；与 load 不同，store 数据不在此搬运（走 StoreQueue
//  通路），故本缓冲只负责「拆地址、控时序、控出队」，不产出写回数据。
//
//  ## 与 LoadMisalignBuffer 的关键区别
//  - 入队：2 个 enq 口「选最老(oldest)」仲裁（按 robIdx→uopIdx），而非固定优先级。
//  - 跨 4KB 页(cross4KB)：跨页 store 要等其到达 ROB 头(robMatch)才拆分，拆分后
//    置 needFlushPipe 并在完成后进 s_block，经 sqControl 阻塞 StoreQueue 出队，
//    直到 doDeq 才释放——保证跨页两半的原子可回滚性。
//  - s_resp 收齐后再延 RAW_DELAY(=1) 拍(经 REG)进 s_wb，对齐 LoadQueueRAW 回滚时序。
//  - s2_needRevoke：入队后第二拍，被选中的源若 revoke，则撤销本次入队。
//
//  ## 本配置端口裁剪
//  io.writeBack.bits.data := DontCare（store 无写回数据）、io.overwriteExpBuf.valid 恒
//  false 等被 firtool DCE，核端口与 golden 一致。
// =============================================================================
module xs_StoreMisalignBuffer_core
  import storemisalignbuffer_pkg::*;
(
  input         clock,
  input         reset,
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  // ---- 2 个 enq 入队口（来自 2 条 store 流水）----
  `define ENQ_PORT(P) \
    output        io_enq_``P``_req_ready, \
    input         io_enq_``P``_req_valid, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_0, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_1, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_2, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_4, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_5, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_8, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_9, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_10, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_11, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_12, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_13, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_14, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_16, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_17, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_18, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_19, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_20, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_21, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_22, \
    input  [3:0]  io_enq_``P``_req_bits_uop_trigger, \
    input  [5:0]  io_enq_``P``_req_bits_uop_ftqPtr_value, \
    input  [3:0]  io_enq_``P``_req_bits_uop_ftqOffset, \
    input  [8:0]  io_enq_``P``_req_bits_uop_fuOpType, \
    input  [7:0]  io_enq_``P``_req_bits_uop_vpu_vstart, \
    input  [1:0]  io_enq_``P``_req_bits_uop_vpu_veew, \
    input  [6:0]  io_enq_``P``_req_bits_uop_uopIdx, \
    input         io_enq_``P``_req_bits_uop_robIdx_flag, \
    input  [7:0]  io_enq_``P``_req_bits_uop_robIdx_value, \
    input  [63:0] io_enq_``P``_req_bits_uop_debugInfo_enqRsTime, \
    input  [63:0] io_enq_``P``_req_bits_uop_debugInfo_selectTime, \
    input  [63:0] io_enq_``P``_req_bits_uop_debugInfo_issueTime, \
    input         io_enq_``P``_req_bits_uop_sqIdx_flag, \
    input  [5:0]  io_enq_``P``_req_bits_uop_sqIdx_value, \
    input  [49:0] io_enq_``P``_req_bits_vaddr, \
    input  [15:0] io_enq_``P``_req_bits_mask, \
    input         io_enq_``P``_req_bits_isvec, \
    input  [7:0]  io_enq_``P``_req_bits_elemIdx, \
    input  [2:0]  io_enq_``P``_req_bits_alignedType, \
    input  [3:0]  io_enq_``P``_req_bits_mbIndex, \
    input         io_enq_``P``_revoke
  `ENQ_PORT(0),
  `ENQ_PORT(1),
  // ---- ROB 头指针（跨页 store 的 robMatch 判定）----
  input         io_rob_pendingst,
  input         io_rob_pendingPtr_flag,
  input  [7:0]  io_rob_pendingPtr_value,
  // ---- 拆分子 store 请求 ----
  input         io_splitStoreReq_ready,
  output        io_splitStoreReq_valid,
  output        io_splitStoreReq_bits_uop_exceptionVec_0,
  output        io_splitStoreReq_bits_uop_exceptionVec_1,
  output        io_splitStoreReq_bits_uop_exceptionVec_2,
  output        io_splitStoreReq_bits_uop_exceptionVec_4,
  output        io_splitStoreReq_bits_uop_exceptionVec_5,
  output        io_splitStoreReq_bits_uop_exceptionVec_8,
  output        io_splitStoreReq_bits_uop_exceptionVec_9,
  output        io_splitStoreReq_bits_uop_exceptionVec_10,
  output        io_splitStoreReq_bits_uop_exceptionVec_11,
  output        io_splitStoreReq_bits_uop_exceptionVec_12,
  output        io_splitStoreReq_bits_uop_exceptionVec_13,
  output        io_splitStoreReq_bits_uop_exceptionVec_14,
  output        io_splitStoreReq_bits_uop_exceptionVec_16,
  output        io_splitStoreReq_bits_uop_exceptionVec_17,
  output        io_splitStoreReq_bits_uop_exceptionVec_18,
  output        io_splitStoreReq_bits_uop_exceptionVec_19,
  output        io_splitStoreReq_bits_uop_exceptionVec_20,
  output        io_splitStoreReq_bits_uop_exceptionVec_21,
  output        io_splitStoreReq_bits_uop_exceptionVec_22,
  output [3:0]  io_splitStoreReq_bits_uop_trigger,
  output [5:0]  io_splitStoreReq_bits_uop_ftqPtr_value,
  output [3:0]  io_splitStoreReq_bits_uop_ftqOffset,
  output [8:0]  io_splitStoreReq_bits_uop_fuOpType,
  output [7:0]  io_splitStoreReq_bits_uop_vpu_vstart,
  output [1:0]  io_splitStoreReq_bits_uop_vpu_veew,
  output [6:0]  io_splitStoreReq_bits_uop_uopIdx,
  output        io_splitStoreReq_bits_uop_robIdx_flag,
  output [7:0]  io_splitStoreReq_bits_uop_robIdx_value,
  output [63:0] io_splitStoreReq_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_splitStoreReq_bits_uop_debugInfo_selectTime,
  output [63:0] io_splitStoreReq_bits_uop_debugInfo_issueTime,
  output        io_splitStoreReq_bits_uop_sqIdx_flag,
  output [5:0]  io_splitStoreReq_bits_uop_sqIdx_value,
  output [49:0] io_splitStoreReq_bits_vaddr,
  output [15:0] io_splitStoreReq_bits_mask,
  output        io_splitStoreReq_bits_isvec,
  output        io_splitStoreReq_bits_is128bit,
  output        io_splitStoreReq_bits_isFinalSplit,
  // ---- 拆分子 store 回应 ----
  input         io_splitStoreResp_valid,
  input         io_splitStoreResp_bits_uop_exceptionVec_3,
  input         io_splitStoreResp_bits_uop_exceptionVec_6,
  input         io_splitStoreResp_bits_uop_exceptionVec_7,
  input         io_splitStoreResp_bits_uop_exceptionVec_15,
  input         io_splitStoreResp_bits_uop_exceptionVec_19,
  input         io_splitStoreResp_bits_uop_exceptionVec_23,
  input  [3:0]  io_splitStoreResp_bits_uop_trigger,
  input  [47:0] io_splitStoreResp_bits_paddr,
  input         io_splitStoreResp_bits_nc,
  input         io_splitStoreResp_bits_mmio,
  input         io_splitStoreResp_bits_memBackTypeMM,
  input         io_splitStoreResp_bits_vecActive,
  input         io_splitStoreResp_bits_need_rep,
  // ---- 标量写回 ROB ----
  input         io_writeBack_ready,
  output        io_writeBack_valid,
  output        io_writeBack_bits_uop_exceptionVec_3,
  output        io_writeBack_bits_uop_exceptionVec_6,
  output        io_writeBack_bits_uop_exceptionVec_7,
  output        io_writeBack_bits_uop_exceptionVec_15,
  output        io_writeBack_bits_uop_exceptionVec_19,
  output        io_writeBack_bits_uop_exceptionVec_23,
  output [3:0]  io_writeBack_bits_uop_trigger,
  output        io_writeBack_bits_uop_flushPipe,
  output        io_writeBack_bits_uop_robIdx_flag,
  output [7:0]  io_writeBack_bits_uop_robIdx_value,
  output [63:0] io_writeBack_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_writeBack_bits_uop_debugInfo_selectTime,
  output [63:0] io_writeBack_bits_uop_debugInfo_issueTime,
  output        io_writeBack_bits_debug_isMMIO,
  output        io_writeBack_bits_debug_isNCIO,
  // ---- 向量写回 VecStoreMergeBuffer（2 口，按 portIndex 选）----
  `define VECWB_PORT(P) \
    output        io_vecWriteBack_``P``_valid, \
    output [3:0]  io_vecWriteBack_``P``_bits_mBIndex, \
    output        io_vecWriteBack_``P``_bits_exceptionVec_3, \
    output        io_vecWriteBack_``P``_bits_exceptionVec_6, \
    output        io_vecWriteBack_``P``_bits_exceptionVec_7, \
    output        io_vecWriteBack_``P``_bits_exceptionVec_15, \
    output        io_vecWriteBack_``P``_bits_exceptionVec_19, \
    output        io_vecWriteBack_``P``_bits_exceptionVec_23, \
    output        io_vecWriteBack_``P``_bits_hasException, \
    output [63:0] io_vecWriteBack_``P``_bits_vaddr, \
    output        io_vecWriteBack_``P``_bits_vaNeedExt, \
    output [63:0] io_vecWriteBack_``P``_bits_gpaddr, \
    output        io_vecWriteBack_``P``_bits_isForVSnonLeafPTE, \
    output [7:0]  io_vecWriteBack_``P``_bits_vstart, \
    output [7:0]  io_vecWriteBack_``P``_bits_elemIdx, \
    output [15:0] io_vecWriteBack_``P``_bits_mask
  `VECWB_PORT(0),
  `VECWB_PORT(1),
  input         io_storeOutValid,
  input         io_storeVecOutValid,
  // ---- StoreQueue 出队控制（跨页 store 阻塞/释放）----
  output        io_sqControl_toStoreQueue_crossPageWithHit,
  output        io_sqControl_toStoreQueue_crossPageCanDeq,
  output [47:0] io_sqControl_toStoreQueue_paddr,
  output        io_sqControl_toStoreQueue_withSameUop,
  input         io_sqControl_toStoreMisalignBuffer_sqPtr_flag,
  input  [5:0]  io_sqControl_toStoreMisalignBuffer_sqPtr_value,
  input         io_sqControl_toStoreMisalignBuffer_doDeq,
  input  [6:0]  io_sqControl_toStoreMisalignBuffer_uop_uopIdx,
  input         io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag,
  input  [7:0]  io_sqControl_toStoreMisalignBuffer_uop_robIdx_value,
  // ---- 给 VecStoreMergeBuffer 的 flush（跨页入队时冲掉旧 vec 条目）----
  output [3:0]  io_toVecStoreMergeBuffer_0_mbIndex,
  output        io_toVecStoreMergeBuffer_0_flush,
  output [3:0]  io_toVecStoreMergeBuffer_1_mbIndex,
  output        io_toVecStoreMergeBuffer_1_flush,
  output        io_full
);

  // ===========================================================================
  //  缓冲条目类型（StoreMisalignBufferEntry = LsPipelineBundle 子集 + portIndex）
  // ===========================================================================
  typedef struct packed {
    logic        exc0, exc1, exc2, exc4, exc5, exc8, exc9, exc10, exc11, exc12;
    logic        exc13, exc14, exc16, exc17, exc18, exc19, exc20, exc21, exc22;
    logic [3:0]  trigger;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
    logic [8:0]  fuOpType;
    logic [7:0]  vpu_vstart;
    logic [1:0]  vpu_veew;
    logic [6:0]  uopIdx;
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic [63:0] dbg_enqRsTime, dbg_selectTime, dbg_issueTime;
    logic        sqIdx_flag;
    logic [5:0]  sqIdx_value;
    logic [49:0] vaddr;
    logic [15:0] mask;
    logic        isvec;
    logic [7:0]  elemIdx;
    logic [2:0]  alignedType;
    logic [3:0]  mbIndex;
    logic        portIndex;  // 来自哪个 enq 口（0/1），决定向量写回走哪个口
  } entry_t;

  // 2 个 enq 口聚成数组。
  localparam int ENQ = 2;
  entry_t enq_bits  [ENQ];
  logic   enq_valid [ENQ];
  logic   enq_revoke[ENQ];

  `define PACK_ENQ(IDX, P) \
    assign enq_valid[IDX]  = io_enq_``P``_req_valid; \
    assign enq_revoke[IDX] = io_enq_``P``_revoke; \
    assign enq_bits[IDX] = '{ \
      exc0: io_enq_``P``_req_bits_uop_exceptionVec_0, exc1: io_enq_``P``_req_bits_uop_exceptionVec_1, \
      exc2: io_enq_``P``_req_bits_uop_exceptionVec_2, exc4: io_enq_``P``_req_bits_uop_exceptionVec_4, \
      exc5: io_enq_``P``_req_bits_uop_exceptionVec_5, exc8: io_enq_``P``_req_bits_uop_exceptionVec_8, \
      exc9: io_enq_``P``_req_bits_uop_exceptionVec_9, exc10: io_enq_``P``_req_bits_uop_exceptionVec_10, \
      exc11: io_enq_``P``_req_bits_uop_exceptionVec_11, exc12: io_enq_``P``_req_bits_uop_exceptionVec_12, \
      exc13: io_enq_``P``_req_bits_uop_exceptionVec_13, exc14: io_enq_``P``_req_bits_uop_exceptionVec_14, \
      exc16: io_enq_``P``_req_bits_uop_exceptionVec_16, exc17: io_enq_``P``_req_bits_uop_exceptionVec_17, \
      exc18: io_enq_``P``_req_bits_uop_exceptionVec_18, exc19: io_enq_``P``_req_bits_uop_exceptionVec_19, \
      exc20: io_enq_``P``_req_bits_uop_exceptionVec_20, exc21: io_enq_``P``_req_bits_uop_exceptionVec_21, \
      exc22: io_enq_``P``_req_bits_uop_exceptionVec_22, \
      trigger: io_enq_``P``_req_bits_uop_trigger, \
      ftqPtr_value: io_enq_``P``_req_bits_uop_ftqPtr_value, ftqOffset: io_enq_``P``_req_bits_uop_ftqOffset, \
      fuOpType: io_enq_``P``_req_bits_uop_fuOpType, vpu_vstart: io_enq_``P``_req_bits_uop_vpu_vstart, \
      vpu_veew: io_enq_``P``_req_bits_uop_vpu_veew, uopIdx: io_enq_``P``_req_bits_uop_uopIdx, \
      robIdx_flag: io_enq_``P``_req_bits_uop_robIdx_flag, robIdx_value: io_enq_``P``_req_bits_uop_robIdx_value, \
      dbg_enqRsTime: io_enq_``P``_req_bits_uop_debugInfo_enqRsTime, \
      dbg_selectTime: io_enq_``P``_req_bits_uop_debugInfo_selectTime, \
      dbg_issueTime: io_enq_``P``_req_bits_uop_debugInfo_issueTime, \
      sqIdx_flag: io_enq_``P``_req_bits_uop_sqIdx_flag, sqIdx_value: io_enq_``P``_req_bits_uop_sqIdx_value, \
      vaddr: io_enq_``P``_req_bits_vaddr, mask: io_enq_``P``_req_bits_mask, \
      isvec: io_enq_``P``_req_bits_isvec, elemIdx: io_enq_``P``_req_bits_elemIdx, \
      alignedType: io_enq_``P``_req_bits_alignedType, mbIndex: io_enq_``P``_req_bits_mbIndex, \
      portIndex: 1'(IDX) }
  `PACK_ENQ(0, 0);
  `PACK_ENQ(1, 1);

  // ===========================================================================
  //  入队仲裁：2 口「选最老」(selectOldest)，缓冲单条目
  // ===========================================================================
  logic   req_valid;
  entry_t req;
  assign io_full = req_valid;

  // selectOldest：两口都 valid 时选 robIdx 更老者（相等则 uopIdx 小者）；否则选 valid 那个。
  //  pickHigh=1 表示「选 enq1」(enq0 比 enq1 更晚/更新 → 取 enq1)。
  logic enq0_after_enq1;   // enq0 是否晚于 enq1（robIdx after，或同 rob 且 uopIdx 更大）
  assign enq0_after_enq1 =
      isAfter(enq_bits[0].robIdx_flag, enq_bits[0].robIdx_value,
              enq_bits[1].robIdx_flag, enq_bits[1].robIdx_value)
    | (isNotBefore(enq_bits[0].robIdx_flag, enq_bits[0].robIdx_value,
                   enq_bits[1].robIdx_flag, enq_bits[1].robIdx_value)
       & (enq_bits[0].uopIdx > enq_bits[1].uopIdx));

  logic   pickHigh;        // 选中 enq1（=1）还是 enq0（=0）
  logic   sel_valid;
  entry_t sel_bits;
  logic   sel_port;        // 被选中的口号（reqSelPort）
  assign pickHigh = (enq_valid[0] & enq_valid[1]) ? enq0_after_enq1
                                                  : ~(enq_valid[0] & ~enq_valid[1]);
  assign sel_valid = (enq_valid[0] & enq_valid[1]) ? (pickHigh ? enq_valid[1] : enq_valid[0])
                   : (enq_valid[0] & ~enq_valid[1]) ? enq_valid[0] : enq_valid[1];
  assign sel_bits  = pickHigh ? enq_bits[1] : enq_bits[0];
  assign sel_port  = pickHigh; // portIndex of selected（0/1）

  // ===========================================================================
  //  跨界判定 + 状态机寄存器
  // ===========================================================================
  fsm_state_e bufferState; // 状态（用 enum 仅作声明，case/比较用具名常量）
  logic       needFlushPipe;   // 跨页拆分需冲流水
  logic       isCrossPage;     // 当前缓冲条目是否跨页
  logic       s2_canEnq_r;     // 入队后第二拍：上拍是否 canEnq（用于 revoke）
  logic       s2_reqSelPort_r; // 入队后第二拍：上拍选中的口号

  // 子 store 请求寄存（fuOpType[1:0]/vaddr/mask 改写；其余 uop 取 s_split 快照）。
  logic [1:0]  splitReq_size  [MAX_SPLIT];
  logic [49:0] splitReq_vaddr [MAX_SPLIT];
  logic [15:0] splitReq_mask  [MAX_SPLIT];
  entry_t      split_uop;                  // s_split 锁存的 uop/元数据快照
  // 合并/掩码只在 store 数据通路用，本缓冲不产数据，仅保留 result 宽度形态以贴近 Scala：
  //   (lowResultWidth/highResultWidth 在 store 侧仅用于 wmask 生成，已 DCE，故省略。)
  logic [2:0]  lowResultWidth, highResultWidth;

  logic [MAX_SPLIT-1:0] unSentStores;
  logic                 curPtr;
  logic [47:0]          splitResp1_paddr;   // 高地址子 store 的 paddr（供 sqControl）
  logic                 raw_delay_reg;      // RAW 延迟级（REG）：s_resp 完成后延 1 拍

  // 全局异常/uncache 标志 + 累积异常向量（store 关心位 3/6/7/15/19/23）。
  logic globalException, globalUncache, globalMMIO, globalNC, globalMemBackTypeMM;
  logic exc3_r, exc6_r, exc7_r, exc15_r, exc19_r, exc23_r;

  // ---- 子 store 回应判定 ----
  logic respHasException, respIsUncache;
  assign respHasException =
      (io_splitStoreResp_bits_vecActive & ~io_splitStoreResp_bits_need_rep &
        (io_splitStoreResp_bits_uop_exceptionVec_3  | io_splitStoreResp_bits_uop_exceptionVec_6 |
         io_splitStoreResp_bits_uop_exceptionVec_7  | io_splitStoreResp_bits_uop_exceptionVec_15 |
         io_splitStoreResp_bits_uop_exceptionVec_19 | io_splitStoreResp_bits_uop_exceptionVec_23))
      | (io_splitStoreResp_bits_uop_trigger == 4'h1);
  assign respIsUncache =
      (io_splitStoreResp_bits_mmio | io_splitStoreResp_bits_nc) & ~io_splitStoreResp_bits_need_rep;
  logic respExcOrUnc;
  assign respExcOrUnc = respHasException | respIsUncache;

  // s_resp：去掉当前 ptr 后仍有未发子 store。
  logic respMoreUnsent;
  assign respMoreUnsent = io_splitStoreResp_bits_need_rep | (|(unSentStores & ~(2'b01 << curPtr)));

  // ---- size + 跨 16B / 跨 4KB 判定 ----
  logic [1:0] alignedType;
  assign alignedType = req.isvec ? req.alignedType[1:0] : req.fuOpType[1:0];
  logic [4:0] sizeLastByte;
  always_comb case (size_e'(alignedType))
    SZ_B: sizeLastByte = 5'd0;
    SZ_H: sizeLastByte = 5'd1;
    SZ_W: sizeLastByte = 5'd3;
    SZ_D: sizeLastByte = 5'd7;
  endcase
  logic [4:0]  highAddr16;   // (vaddr[4:0] + sizeLastByte) —— 跨 16B 看 bit4
  logic [12:0] highAddr4K;   // (vaddr[12:0] + sizeLastByte) —— 跨 4KB 看 bit12
  assign highAddr16 = req.vaddr[4:0]  + sizeLastByte;
  assign highAddr4K = req.vaddr[12:0] + {8'h0, sizeLastByte};
  logic cross16, cross4KB;
  assign cross16  = req_valid & (highAddr16[4]  != req.vaddr[4]);
  assign cross4KB = req_valid & (highAddr4K[12] != req.vaddr[12]);

  // ---- robMatch：跨页 store 是否已到 ROB 头 ----
  logic robMatch;
  assign robMatch = req_valid & io_rob_pendingst &
      (io_rob_pendingPtr_flag == req.robIdx_flag) & (io_rob_pendingPtr_value == req.robIdx_value);

  // ---- 拆分表（与 LoadMisalignBuffer 同构，但 store 无 resultShift）----
  typedef struct packed {
    logic [1:0] lowSz;  logic [49:0] lowVa;  logic [2:0] lowW;
    logic [1:0] highSz; logic [49:0] highVa; logic [2:0] highW;
  } split_plan_t;

  function automatic split_plan_t planSplit(input logic [1:0] sz, input logic [49:0] va);
    split_plan_t p; p = '0;
    case (size_e'(sz))
      SZ_H: begin
        p.lowSz=SZ_B;  p.lowVa=va;        p.lowW=3'd1;
        p.highSz=SZ_B; p.highVa=va+50'd1; p.highW=3'd1;
      end
      SZ_W: case (va[1:0])
        2'b01: begin p.lowSz=SZ_W; p.lowVa=va-50'd1; p.lowW=3'd3; p.highSz=SZ_B; p.highVa=va+50'd3; p.highW=3'd1; end
        2'b10: begin p.lowSz=SZ_H; p.lowVa=va;       p.lowW=3'd2; p.highSz=SZ_H; p.highVa=va+50'd2; p.highW=3'd2; end
        2'b11: begin p.lowSz=SZ_B; p.lowVa=va;       p.lowW=3'd1; p.highSz=SZ_W; p.highVa=va+50'd1; p.highW=3'd3; end
        default: ;
      endcase
      SZ_D: case (va[2:0])
        3'b001: begin p.lowSz=SZ_D; p.lowVa=va-50'd1; p.lowW=3'd7; p.highSz=SZ_B; p.highVa=va+50'd7; p.highW=3'd1; end
        3'b010: begin p.lowSz=SZ_D; p.lowVa=va-50'd2; p.lowW=3'd6; p.highSz=SZ_H; p.highVa=va+50'd6; p.highW=3'd2; end
        3'b011: begin p.lowSz=SZ_D; p.lowVa=va-50'd3; p.lowW=3'd5; p.highSz=SZ_W; p.highVa=va+50'd5; p.highW=3'd3; end
        3'b100: begin p.lowSz=SZ_W; p.lowVa=va;       p.lowW=3'd4; p.highSz=SZ_W; p.highVa=va+50'd4; p.highW=3'd4; end
        3'b101: begin p.lowSz=SZ_D; p.lowVa=va-50'd5; p.lowW=3'd3; p.highSz=SZ_D; p.highVa=va+50'd3; p.highW=3'd5; end
        3'b110: begin p.lowSz=SZ_D; p.lowVa=va-50'd6; p.lowW=3'd2; p.highSz=SZ_D; p.highVa=va+50'd2; p.highW=3'd6; end
        3'b111: begin p.lowSz=SZ_D; p.lowVa=va-50'd7; p.lowW=3'd1; p.highSz=SZ_D; p.highVa=va+50'd1; p.highW=3'd7; end
        default: ;
      endcase
      default: ;
    endcase
    planSplit = p;
  endfunction

  function automatic logic [15:0] genMask(input logic [1:0] sz, input logic [49:0] va);
    genMask = {8'h0, getMask(size_e'(sz))} << va[3:0];
  endfunction

  split_plan_t plan;
  assign plan = planSplit(alignedType, req.vaddr);

  // ---- redirect 冲刷（缓冲条目 & 入队候选）----
  logic flush, reqRedirect;
  assign flush = req_valid & robNeedFlush(req.robIdx_flag, req.robIdx_value,
                                          io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value,
                                          io_redirect_valid, io_redirect_bits_level);
  assign reqRedirect = robNeedFlush(sel_bits.robIdx_flag, sel_bits.robIdx_value,
                                    io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value,
                                    io_redirect_valid, io_redirect_bits_level);

  // ---- s2_needRevoke：入队后第二拍，被选口 revoke 则撤销 ----
  logic s2_needRevoke;
  assign s2_needRevoke = s2_canEnq_r &
      ((enq_revoke[0] & ~s2_reqSelPort_r) | (enq_revoke[1] & s2_reqSelPort_r));

  // ---- 入队条件 ----
  //  普通入队：缓冲空、候选未冲刷、候选 valid。
  //  跨页抢占入队(cross4KBEnq)：当前缓冲条目比候选更新、且处于 idle，则用候选替换并冲流水。
  logic canEnq, cross4KBEnq, candidateNewer;
  assign candidateNewer = sel_valid &
      (isAfter(req.robIdx_flag, req.robIdx_value, sel_bits.robIdx_flag, sel_bits.robIdx_value)
       | (isNotBefore(req.robIdx_flag, req.robIdx_value, sel_bits.robIdx_flag, sel_bits.robIdx_value)
          & (req.uopIdx > sel_bits.uopIdx)))
      & (bufferState == S_IDLE);
  assign cross4KBEnq = cross4KB & ~reqRedirect & candidateNewer;
  assign canEnq = cross4KBEnq | (~req_valid & ~reqRedirect & sel_valid);

  // ---- enq ready：被选口、且(缓冲空 或 跨页抢占) ----
  assign io_enq_0_req_ready = (sel_port == 1'b0) & (~req_valid | (cross4KB & cross4KBEnq));
  assign io_enq_1_req_ready = (sel_port == 1'b1) & (~req_valid | (cross4KB & cross4KBEnq));

  // ===========================================================================
  //  状态机 + 寄存器（用优先级 if-链，保证每条路径定值，避免 FM X 源）
  // ===========================================================================
  `define CLEAR_ENTRY \
    begin \
      bufferState         <= S_IDLE; \
      req_valid           <= 1'b0; \
      curPtr              <= 1'b0; \
      unSentStores        <= '0; \
      globalException     <= 1'b0; \
      globalUncache       <= 1'b0; \
      isCrossPage         <= 1'b0; \
      needFlushPipe       <= 1'b0; \
      globalMMIO          <= 1'b0; \
      globalNC            <= 1'b0; \
      globalMemBackTypeMM <= 1'b0; \
    end

  // writeBack/vecWriteBack fire（用于 s_wb 清条目，定义在输出段，这里前向引用）。
  logic wbFire, vecWbFire, scalarDone;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      // 注：req（缓冲条目数据）与 golden 一致「不复位」（仅入队时写），故不在此清零。
      req_valid <= 1'b0; bufferState <= S_IDLE;
      needFlushPipe <= 1'b0; isCrossPage <= 1'b0;
      s2_canEnq_r <= 1'b0; s2_reqSelPort_r <= 1'b0;
      split_uop <= '0; unSentStores <= '0; curPtr <= 1'b0;
      splitResp1_paddr <= '0;
      lowResultWidth <= '0; highResultWidth <= '0;
      globalException <= 1'b0; globalUncache <= 1'b0;
      globalMMIO <= 1'b0; globalNC <= 1'b0; globalMemBackTypeMM <= 1'b0;
      {exc3_r,exc6_r,exc7_r,exc15_r,exc19_r,exc23_r} <= '0;
      for (int i = 0; i < MAX_SPLIT; i++) begin
        splitReq_size[i] <= '0; splitReq_vaddr[i] <= '0; splitReq_mask[i] <= '0;
      end
    end else begin
      // ---- 入队锁存（普通 或 跨页抢占）----
      //  req 数据字段的更新使能：跨页时取「候选更老」(candidateNewer)，否则取 canEnq。
      //  （与 golden 的 req 更新使能 (cross4KB&~reqRedirect)? candidateNewer : canEnq 一致；
      //   因 cross4KB 蕴含 req_valid，两者在可达空间等价，但写成此形式可让 FM 的
      //   req 次态锥与 golden 同构。）
      if ((cross4KB & ~reqRedirect) ? candidateNewer : canEnq) begin
        req          <= sel_bits;
        req.portIndex<= sel_port;
      end
      if (canEnq) begin
        req_valid    <= 1'b1;
        if (cross4KBEnq) needFlushPipe <= 1'b1;
      end
      // s2 打拍（次拍 revoke 判定用）。
      s2_canEnq_r     <= canEnq;
      s2_reqSelPort_r <= sel_port;

      // ---- s_split：拆分寄存器写入（仅 cross16）----
      if (bufferState == S_SPLIT && cross16) begin
        unSentStores <= 2'b11;
        curPtr       <= 1'b0;
        split_uop    <= req;
        if (|alignedType) begin
          splitReq_size[0] <= plan.lowSz;  splitReq_vaddr[0] <= plan.lowVa;
          splitReq_size[1] <= plan.highSz; splitReq_vaddr[1] <= plan.highVa;
          splitReq_mask[0] <= genMask(plan.lowSz,  plan.lowVa);
          splitReq_mask[1] <= genMask(plan.highSz, plan.highVa);
          lowResultWidth   <= plan.lowW;   highResultWidth   <= plan.highW;
        end
      end

      // ---- 次态转移（优先级链；与 Scala switch 等价）----
      if (bufferState == S_IDLE) begin
        // 跨页：等 robMatch 才拆；非跨页：req_valid 即拆。均需 ~s2_needRevoke。
        if (cross4KB & ~s2_needRevoke) begin
          if (robMatch) begin bufferState <= S_SPLIT; isCrossPage <= 1'b1; end
        end else if (req_valid & ~s2_needRevoke) begin
          bufferState <= S_SPLIT; isCrossPage <= 1'b0;
        end
      end else if (bufferState == S_SPLIT) begin
        bufferState <= S_REQ;
      end else if (bufferState == S_REQ) begin
        if (io_splitStoreReq_ready & io_splitStoreReq_valid) bufferState <= S_RESP;
      end else if (bufferState == S_RESP) begin
        // 优先：RAW 延迟到点 → s_wb。否则收到回应：异常/uncache 直接 s_wb；
        //   还有未发/重放 → s_req；正常完成 → 留在 s_resp 等 raw_delay 下拍触发。
        //   (global*/异常向量的锁存与状态转移解耦，见下方独立的 resp 处理块。)
        if (raw_delay_reg) bufferState <= S_WB;
        else if (io_splitStoreResp_valid) begin
          if (respExcOrUnc)        bufferState <= S_WB;
          else if (respMoreUnsent) bufferState <= S_REQ;
        end
      end else if (bufferState == S_WB) begin
        if (req.isvec) begin
          if (vecWbFire) `CLEAR_ENTRY
        end else begin
          if (scalarDone) `CLEAR_ENTRY      // 非跨页/异常/uncache：写回完成即清
          else if (wbFire & isCrossPage) bufferState <= S_BLOCK; // 跨页：转阻塞等出队
        end
      end else if (bufferState == S_BLOCK) begin
        if (io_sqControl_toStoreMisalignBuffer_doDeq) `CLEAR_ENTRY
      end

      // ---- s_resp 收回应：维护 unSentStores/curPtr/异常向量/paddr/全局标志 ----
      //  （与状态转移解耦，对应 Scala 的 when(io.splitStoreResp.valid) 与 global* 赋值。）
      if (io_splitStoreResp_valid) begin
        if (curPtr) splitResp1_paddr <= io_splitStoreResp_bits_paddr;
        if (respIsUncache) begin
          unSentStores <= '0;
          // 交软件：清异常向量、置 storeAddrMisaligned(bit6)。
          {exc3_r,exc7_r,exc15_r,exc19_r,exc23_r} <= '0;
          exc6_r <= 1'b1;
        end else if (respHasException) begin
          unSentStores <= '0;
          exc3_r  <= exc3_r  | io_splitStoreResp_bits_uop_exceptionVec_3;
          exc6_r  <= exc6_r  | io_splitStoreResp_bits_uop_exceptionVec_6;
          exc7_r  <= exc7_r  | io_splitStoreResp_bits_uop_exceptionVec_7;
          exc15_r <= exc15_r | io_splitStoreResp_bits_uop_exceptionVec_15;
          exc19_r <= exc19_r | io_splitStoreResp_bits_uop_exceptionVec_19;
          exc23_r <= exc23_r | io_splitStoreResp_bits_uop_exceptionVec_23;
        end else if (~io_splitStoreResp_bits_need_rep) begin
          unSentStores <= unSentStores & ~(2'b01 << curPtr);
          curPtr       <= curPtr + 1'b1;
          {exc3_r,exc6_r,exc7_r,exc15_r,exc19_r,exc23_r} <= '0;
        end
        // 全局异常/uncache/调试标志：仅在 s_resp 且本次回应异常/uncache 时锁存。
        if ((bufferState == S_RESP) & respExcOrUnc) begin
          globalException     <= respHasException;
          globalUncache       <= respIsUncache;
          globalMMIO          <= io_splitStoreResp_bits_mmio;
          globalNC            <= io_splitStoreResp_bits_nc;
          globalMemBackTypeMM <= io_splitStoreResp_bits_memBackTypeMM;
        end
      end

      // ---- flush / s2_needRevoke 优先冲刷整条目 ----
      //  跨页抢占入队恰好同拍发生时，保留新入队的 req_valid（与 golden 一致）。
      if (flush | s2_needRevoke) begin
        bufferState         <= S_IDLE;
        req_valid           <= (cross4KBEnq & cross4KB & ~reqRedirect & ~s2_needRevoke) ? req_valid : 1'b0;
        curPtr              <= 1'b0;
        unSentStores        <= '0;
        globalException     <= 1'b0;
        globalUncache       <= 1'b0;
        isCrossPage         <= 1'b0;
        needFlushPipe       <= 1'b0;
        globalMMIO          <= 1'b0;
        globalNC            <= 1'b0;
        globalMemBackTypeMM <= 1'b0;
      end
    end
  end

  // ---- RAW 延迟级(REG)：收到「正常完成」的子 store 回应(无异常/uncache/未完)就拉高
  //   一拍，下一拍在 s_resp 分支触发 s_wb。与 golden 一致：单独的无复位寄存器。
  always_ff @(posedge clock) begin
    raw_delay_reg <= io_splitStoreResp_valid & ~respExcOrUnc & ~respMoreUnsent;
  end

  // ===========================================================================
  //  splitStoreReq 输出
  // ===========================================================================
  assign io_splitStoreReq_valid = req_valid & (bufferState == S_REQ);

  logic [1:0]  cur_size;
  logic [49:0] cur_vaddr;
  logic [15:0] cur_mask;
  assign cur_size  = curPtr ? splitReq_size[1]  : splitReq_size[0];
  assign cur_vaddr = curPtr ? splitReq_vaddr[1] : splitReq_vaddr[0];
  assign cur_mask  = curPtr ? splitReq_mask[1]  : splitReq_mask[0];

  // uop 取 s_split 快照；storeAddrMisaligned(bit6) 拆分时清零。
  assign io_splitStoreReq_bits_uop_exceptionVec_0  = split_uop.exc0;
  assign io_splitStoreReq_bits_uop_exceptionVec_1  = split_uop.exc1;
  assign io_splitStoreReq_bits_uop_exceptionVec_2  = split_uop.exc2;
  assign io_splitStoreReq_bits_uop_exceptionVec_4  = split_uop.exc4;
  assign io_splitStoreReq_bits_uop_exceptionVec_5  = split_uop.exc5;
  assign io_splitStoreReq_bits_uop_exceptionVec_8  = split_uop.exc8;
  assign io_splitStoreReq_bits_uop_exceptionVec_9  = split_uop.exc9;
  assign io_splitStoreReq_bits_uop_exceptionVec_10 = split_uop.exc10;
  assign io_splitStoreReq_bits_uop_exceptionVec_11 = split_uop.exc11;
  assign io_splitStoreReq_bits_uop_exceptionVec_12 = split_uop.exc12;
  assign io_splitStoreReq_bits_uop_exceptionVec_13 = split_uop.exc13;
  assign io_splitStoreReq_bits_uop_exceptionVec_14 = split_uop.exc14;
  assign io_splitStoreReq_bits_uop_exceptionVec_16 = split_uop.exc16;
  assign io_splitStoreReq_bits_uop_exceptionVec_17 = split_uop.exc17;
  assign io_splitStoreReq_bits_uop_exceptionVec_18 = split_uop.exc18;
  assign io_splitStoreReq_bits_uop_exceptionVec_19 = split_uop.exc19;
  assign io_splitStoreReq_bits_uop_exceptionVec_20 = split_uop.exc20;
  assign io_splitStoreReq_bits_uop_exceptionVec_21 = split_uop.exc21;
  assign io_splitStoreReq_bits_uop_exceptionVec_22 = split_uop.exc22;
  assign io_splitStoreReq_bits_uop_trigger      = split_uop.trigger;
  assign io_splitStoreReq_bits_uop_ftqPtr_value = split_uop.ftqPtr_value;
  assign io_splitStoreReq_bits_uop_ftqOffset    = split_uop.ftqOffset;
  // fuOpType 重建：标量 → {4'h0, isHsv, 2'h0, 子store size[1:0]}；向量 → 原 fuOpType。
  //   isHsv = fuOpType[4] & ~fuOpType[5] & (fuOpType[8:7]==0)
  logic reqIsHsv;
  assign reqIsHsv = req.fuOpType[4] & ~req.fuOpType[5] & (req.fuOpType[8:7] == 2'h0);
  assign io_splitStoreReq_bits_uop_fuOpType =
      req.isvec ? req.fuOpType : {4'h0, reqIsHsv, 2'h0, cur_size};
  assign io_splitStoreReq_bits_uop_vpu_vstart   = split_uop.vpu_vstart;
  assign io_splitStoreReq_bits_uop_vpu_veew     = split_uop.vpu_veew;
  assign io_splitStoreReq_bits_uop_uopIdx       = split_uop.uopIdx;
  assign io_splitStoreReq_bits_uop_robIdx_flag  = split_uop.robIdx_flag;
  assign io_splitStoreReq_bits_uop_robIdx_value = split_uop.robIdx_value;
  assign io_splitStoreReq_bits_uop_debugInfo_enqRsTime  = split_uop.dbg_enqRsTime;
  assign io_splitStoreReq_bits_uop_debugInfo_selectTime = split_uop.dbg_selectTime;
  assign io_splitStoreReq_bits_uop_debugInfo_issueTime  = split_uop.dbg_issueTime;
  assign io_splitStoreReq_bits_uop_sqIdx_flag   = split_uop.sqIdx_flag;
  assign io_splitStoreReq_bits_uop_sqIdx_value  = split_uop.sqIdx_value;
  assign io_splitStoreReq_bits_vaddr  = cur_vaddr;
  assign io_splitStoreReq_bits_mask   = cur_mask;
  assign io_splitStoreReq_bits_isvec  = req.isvec;
  assign io_splitStoreReq_bits_is128bit = 1'b0;       // 拆分恒 0（WireInit 默认）
  assign io_splitStoreReq_bits_isFinalSplit = curPtr; // 高地址那次为最后一拆

  // ===========================================================================
  //  标量写回 ROB
  // ===========================================================================
  assign io_writeBack_valid = req_valid & (bufferState == S_WB) & ~io_storeOutValid & ~req.isvec;
  assign wbFire     = io_writeBack_valid & io_writeBack_ready;
  assign scalarDone = wbFire & (~isCrossPage | globalUncache | globalException);

  logic uncacheOrExc;
  assign uncacheOrExc = globalUncache | globalException;
  assign io_writeBack_bits_uop_exceptionVec_3  = uncacheOrExc & exc3_r;
  assign io_writeBack_bits_uop_exceptionVec_6  = uncacheOrExc & exc6_r;
  assign io_writeBack_bits_uop_exceptionVec_7  = uncacheOrExc & exc7_r;
  assign io_writeBack_bits_uop_exceptionVec_15 = uncacheOrExc & exc15_r;
  assign io_writeBack_bits_uop_exceptionVec_19 = uncacheOrExc & exc19_r;
  assign io_writeBack_bits_uop_exceptionVec_23 = uncacheOrExc & exc23_r;
  assign io_writeBack_bits_uop_trigger    = req.trigger;
  assign io_writeBack_bits_uop_flushPipe  = needFlushPipe;
  assign io_writeBack_bits_uop_robIdx_flag  = req.robIdx_flag;
  assign io_writeBack_bits_uop_robIdx_value = req.robIdx_value;
  assign io_writeBack_bits_uop_debugInfo_enqRsTime  = req.dbg_enqRsTime;
  assign io_writeBack_bits_uop_debugInfo_selectTime = req.dbg_selectTime;
  assign io_writeBack_bits_uop_debugInfo_issueTime  = req.dbg_issueTime;
  assign io_writeBack_bits_debug_isMMIO = globalMMIO;
  assign io_writeBack_bits_debug_isNCIO = globalNC & ~globalMemBackTypeMM;

  // ===========================================================================
  //  向量写回 VecStoreMergeBuffer（2 口；只点亮 portIndex 对应口）
  // ===========================================================================
  logic vecwb_base;
  assign vecwb_base = req_valid & (bufferState == S_WB) & req.isvec & ~io_storeVecOutValid;
  logic vecwb0, vecwb1;
  assign vecwb0 = vecwb_base & (req.portIndex == 1'b0);
  assign vecwb1 = vecwb_base & (req.portIndex == 1'b1);
  assign vecWbFire = vecwb0 | vecwb1; // vec 写回口 ready 恒 1

  `define VECWB_BODY(P, V) \
    assign io_vecWriteBack_``P``_valid                  = V; \
    assign io_vecWriteBack_``P``_bits_mBIndex           = req.mbIndex; \
    assign io_vecWriteBack_``P``_bits_exceptionVec_3    = exc3_r; \
    assign io_vecWriteBack_``P``_bits_exceptionVec_6    = exc6_r; \
    assign io_vecWriteBack_``P``_bits_exceptionVec_7    = exc7_r; \
    assign io_vecWriteBack_``P``_bits_exceptionVec_15   = exc15_r; \
    assign io_vecWriteBack_``P``_bits_exceptionVec_19   = exc19_r; \
    assign io_vecWriteBack_``P``_bits_exceptionVec_23   = exc23_r; \
    assign io_vecWriteBack_``P``_bits_hasException      = globalException; \
    assign io_vecWriteBack_``P``_bits_vaddr             = {{(64-VADDR){1'b0}}, req.vaddr}; \
    assign io_vecWriteBack_``P``_bits_vaNeedExt         = 1'b0; \
    assign io_vecWriteBack_``P``_bits_gpaddr            = 64'h0; \
    assign io_vecWriteBack_``P``_bits_isForVSnonLeafPTE = 1'b0; \
    assign io_vecWriteBack_``P``_bits_vstart            = req.vpu_vstart; \
    assign io_vecWriteBack_``P``_bits_elemIdx           = req.elemIdx; \
    assign io_vecWriteBack_``P``_bits_mask              = req.mask
  `VECWB_BODY(0, vecwb0);
  `VECWB_BODY(1, vecwb1);

  // ===========================================================================
  //  StoreQueue 出队控制（跨页 store）
  // ===========================================================================
  //  crossPageWithHit：sqControl 查询的 sqPtr 命中本缓冲条目且跨页 → 该 sq 项需等本缓冲。
  assign io_sqControl_toStoreQueue_crossPageWithHit =
      (io_sqControl_toStoreMisalignBuffer_sqPtr_value == req.sqIdx_value) & isCrossPage;
  //  crossPageCanDeq：非跨页 或 已进 s_block → 可出队。
  assign io_sqControl_toStoreQueue_crossPageCanDeq = ~isCrossPage | (bufferState == S_BLOCK);
  //  高地址子 store 的 8B 对齐 paddr（出队时合并写两半用）。
  assign io_sqControl_toStoreQueue_paddr = {splitResp1_paddr[47:3], 3'h0};
  //  withSameUop：sqControl 回送的 uop 与本条目同 uop 且跨页且已到 ROB 头。
  assign io_sqControl_toStoreQueue_withSameUop =
      (io_sqControl_toStoreMisalignBuffer_uop_robIdx_flag  == req.robIdx_flag) &
      (io_sqControl_toStoreMisalignBuffer_uop_robIdx_value == req.robIdx_value) &
      (io_sqControl_toStoreMisalignBuffer_uop_uopIdx == req.uopIdx) &
      req.isvec & robMatch & isCrossPage;

  // ===========================================================================
  //  给 VecStoreMergeBuffer 的 flush（跨页抢占入队时冲掉旧 vec 条目）
  // ===========================================================================
  logic toVecFlush;
  assign toVecFlush = req_valid & cross4KB & cross4KBEnq;
  assign io_toVecStoreMergeBuffer_0_mbIndex = req.mbIndex;
  assign io_toVecStoreMergeBuffer_0_flush   = toVecFlush & (req.portIndex == 1'b0);
  assign io_toVecStoreMergeBuffer_1_mbIndex = req.mbIndex;
  assign io_toVecStoreMergeBuffer_1_flush   = toVecFlush & (req.portIndex == 1'b1);

endmodule
