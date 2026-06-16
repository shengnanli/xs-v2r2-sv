// =============================================================================
//  LoadMisalignBuffer —— 非对齐 load 拆分/合并缓冲（可读核 xs_LoadMisalignBuffer_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LoadMisalignBuffer.scala
//  类型/常量/纯函数见 loadmisalignbuffer_pkg.sv。
//
//  ## 它解决什么问题
//  RISC-V 允许非对齐访存，但 DCache 一次只能服务「不跨 16B 对齐窗口」的访问。
//  当 LoadUnit 在流水里发现一条 load 跨 16B 边界（如 vaddr 末位=0xF 的 ld），
//  无法一次读完，于是把它送入本缓冲。本缓冲：
//    1) 把该非对齐 load 拆成 low/high 两次「对齐子 load」（s_split）；
//    2) 依次经 splitLoadReq 口发回 LoadUnit 重新走流水读 DCache（s_req/s_resp）；
//    3) 两次都拿到数据后，按各自的「右移/截取字节数」抠出有效段、逐字节拼接成
//       原始 64b 数据，做符号/零扩展（s_comb_wakeup_rep）；
//    4) 写回 ROB（标量，并对 LoadUnit 再发一次 wakeup）或 VecMergeBuffer（向量）。
//
//  ## 关键微架构点
//  - 同一时刻只缓冲一条非对齐 load（req_valid 单条目）：3 个 enq 口固定优先级仲裁。
//  - 拆分恒为 2 次（maxSplitNum=2）；low 取「含 vaddr 的对齐字」，high 取「含末字节
//    的对齐字」。每次子 load 用尽量大的对齐 size（见 split 表）以减少访问次数。
//  - 字节合并语义：catResult[i] = (i < lowWidth) ? lowSeg[i] : highSeg[i-lowWidth]，
//    即低 lowWidth 字节来自 low 子 load，其余来自 high 子 load。务必精确，否则数据错位。
//  - 异常/uncache 短路：任一子 load 命中异常或落到 uncache 空间，立即收尾交软件处理。
//
//  ## 本配置端口裁剪
//  Scala 里的 io.overwriteExpBuf / io.flushLdExpBuff（valid 恒 false）与 io.rob 输出
//  在本顶层全被 firtool DCE，故核端口里没有它们（与 golden 端口集一致）。
// =============================================================================
module xs_LoadMisalignBuffer_core
  import loadmisalignbuffer_pkg::*;
(
  input         clock,
  input         reset,
  // ---- redirect ----
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  // ---- 3 个 enq 入队口（来自 3 条 load 流水）：扁平 uop + 访存元数据 ----
  //  本核把每个 enq 口的全部 uop/元数据字段聚成 enq_payload_t（见下）。端口仍用
  //  golden 扁平名以便 wrapper 直通。
  `define ENQ_PORT(P) \
    output        io_enq_``P``_req_ready, \
    input         io_enq_``P``_req_valid, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_0, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_1, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_2, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_3, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_5, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_6, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_7, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_8, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_9, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_10, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_11, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_12, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_13, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_14, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_15, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_16, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_17, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_18, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_19, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_20, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_21, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_22, \
    input         io_enq_``P``_req_bits_uop_exceptionVec_23, \
    input  [3:0]  io_enq_``P``_req_bits_uop_trigger, \
    input         io_enq_``P``_req_bits_uop_preDecodeInfo_isRVC, \
    input         io_enq_``P``_req_bits_uop_ftqPtr_flag, \
    input  [5:0]  io_enq_``P``_req_bits_uop_ftqPtr_value, \
    input  [3:0]  io_enq_``P``_req_bits_uop_ftqOffset, \
    input  [8:0]  io_enq_``P``_req_bits_uop_fuOpType, \
    input         io_enq_``P``_req_bits_uop_rfWen, \
    input         io_enq_``P``_req_bits_uop_fpWen, \
    input  [7:0]  io_enq_``P``_req_bits_uop_vpu_vstart, \
    input  [1:0]  io_enq_``P``_req_bits_uop_vpu_veew, \
    input  [6:0]  io_enq_``P``_req_bits_uop_uopIdx, \
    input  [7:0]  io_enq_``P``_req_bits_uop_pdest, \
    input         io_enq_``P``_req_bits_uop_robIdx_flag, \
    input  [7:0]  io_enq_``P``_req_bits_uop_robIdx_value, \
    input  [63:0] io_enq_``P``_req_bits_uop_debugInfo_enqRsTime, \
    input  [63:0] io_enq_``P``_req_bits_uop_debugInfo_selectTime, \
    input  [63:0] io_enq_``P``_req_bits_uop_debugInfo_issueTime, \
    input         io_enq_``P``_req_bits_uop_storeSetHit, \
    input         io_enq_``P``_req_bits_uop_waitForRobIdx_flag, \
    input  [7:0]  io_enq_``P``_req_bits_uop_waitForRobIdx_value, \
    input         io_enq_``P``_req_bits_uop_loadWaitBit, \
    input         io_enq_``P``_req_bits_uop_loadWaitStrict, \
    input         io_enq_``P``_req_bits_uop_lqIdx_flag, \
    input  [6:0]  io_enq_``P``_req_bits_uop_lqIdx_value, \
    input         io_enq_``P``_req_bits_uop_sqIdx_flag, \
    input  [5:0]  io_enq_``P``_req_bits_uop_sqIdx_value, \
    input  [49:0] io_enq_``P``_req_bits_vaddr, \
    input  [63:0] io_enq_``P``_req_bits_fullva, \
    input         io_enq_``P``_req_bits_vaNeedExt, \
    input  [63:0] io_enq_``P``_req_bits_gpaddr, \
    input  [15:0] io_enq_``P``_req_bits_mask, \
    input         io_enq_``P``_req_bits_isvec, \
    input  [7:0]  io_enq_``P``_req_bits_elemIdx, \
    input  [2:0]  io_enq_``P``_req_bits_alignedType, \
    input  [3:0]  io_enq_``P``_req_bits_mbIndex, \
    input  [7:0]  io_enq_``P``_req_bits_elemIdxInsideVd, \
    input  [15:0] io_enq_``P``_req_bits_vecTriggerMask
  `ENQ_PORT(0),
  `ENQ_PORT(1),
  `ENQ_PORT(2),
  // ---- 拆分子 load 请求 splitLoadReq（发回 LoadUnit 重走流水）----
  input         io_splitLoadReq_ready,
  output        io_splitLoadReq_valid,
  output        io_splitLoadReq_bits_uop_exceptionVec_0,
  output        io_splitLoadReq_bits_uop_exceptionVec_1,
  output        io_splitLoadReq_bits_uop_exceptionVec_2,
  output        io_splitLoadReq_bits_uop_exceptionVec_3,
  output        io_splitLoadReq_bits_uop_exceptionVec_4,
  output        io_splitLoadReq_bits_uop_exceptionVec_5,
  output        io_splitLoadReq_bits_uop_exceptionVec_6,
  output        io_splitLoadReq_bits_uop_exceptionVec_7,
  output        io_splitLoadReq_bits_uop_exceptionVec_8,
  output        io_splitLoadReq_bits_uop_exceptionVec_9,
  output        io_splitLoadReq_bits_uop_exceptionVec_10,
  output        io_splitLoadReq_bits_uop_exceptionVec_11,
  output        io_splitLoadReq_bits_uop_exceptionVec_12,
  output        io_splitLoadReq_bits_uop_exceptionVec_13,
  output        io_splitLoadReq_bits_uop_exceptionVec_14,
  output        io_splitLoadReq_bits_uop_exceptionVec_15,
  output        io_splitLoadReq_bits_uop_exceptionVec_16,
  output        io_splitLoadReq_bits_uop_exceptionVec_17,
  output        io_splitLoadReq_bits_uop_exceptionVec_18,
  output        io_splitLoadReq_bits_uop_exceptionVec_19,
  output        io_splitLoadReq_bits_uop_exceptionVec_20,
  output        io_splitLoadReq_bits_uop_exceptionVec_21,
  output        io_splitLoadReq_bits_uop_exceptionVec_22,
  output        io_splitLoadReq_bits_uop_exceptionVec_23,
  output [3:0]  io_splitLoadReq_bits_uop_trigger,
  output        io_splitLoadReq_bits_uop_preDecodeInfo_isRVC,
  output        io_splitLoadReq_bits_uop_ftqPtr_flag,
  output [5:0]  io_splitLoadReq_bits_uop_ftqPtr_value,
  output [3:0]  io_splitLoadReq_bits_uop_ftqOffset,
  output [8:0]  io_splitLoadReq_bits_uop_fuOpType,
  output        io_splitLoadReq_bits_uop_rfWen,
  output        io_splitLoadReq_bits_uop_fpWen,
  output [7:0]  io_splitLoadReq_bits_uop_vpu_vstart,
  output [1:0]  io_splitLoadReq_bits_uop_vpu_veew,
  output [6:0]  io_splitLoadReq_bits_uop_uopIdx,
  output [7:0]  io_splitLoadReq_bits_uop_pdest,
  output        io_splitLoadReq_bits_uop_robIdx_flag,
  output [7:0]  io_splitLoadReq_bits_uop_robIdx_value,
  output [63:0] io_splitLoadReq_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_splitLoadReq_bits_uop_debugInfo_selectTime,
  output [63:0] io_splitLoadReq_bits_uop_debugInfo_issueTime,
  output        io_splitLoadReq_bits_uop_storeSetHit,
  output        io_splitLoadReq_bits_uop_waitForRobIdx_flag,
  output [7:0]  io_splitLoadReq_bits_uop_waitForRobIdx_value,
  output        io_splitLoadReq_bits_uop_loadWaitBit,
  output        io_splitLoadReq_bits_uop_loadWaitStrict,
  output        io_splitLoadReq_bits_uop_lqIdx_flag,
  output [6:0]  io_splitLoadReq_bits_uop_lqIdx_value,
  output        io_splitLoadReq_bits_uop_sqIdx_flag,
  output [5:0]  io_splitLoadReq_bits_uop_sqIdx_value,
  output [49:0] io_splitLoadReq_bits_vaddr,
  output [63:0] io_splitLoadReq_bits_fullva,
  output [15:0] io_splitLoadReq_bits_mask,
  output        io_splitLoadReq_bits_nc,
  output        io_splitLoadReq_bits_mmio,
  output        io_splitLoadReq_bits_memBackTypeMM,
  output        io_splitLoadReq_bits_isvec,
  output        io_splitLoadReq_bits_is128bit,
  output        io_splitLoadReq_bits_vecActive,
  output [3:0]  io_splitLoadReq_bits_mshrid,
  output [6:0]  io_splitLoadReq_bits_schedIndex,
  output        io_splitLoadReq_bits_isFinalSplit,
  output        io_splitLoadReq_bits_misalignNeedWakeUp,
  // ---- 拆分子 load 回应 splitLoadResp ----
  input         io_splitLoadResp_valid,
  input         io_splitLoadResp_bits_uop_exceptionVec_3,
  input         io_splitLoadResp_bits_uop_exceptionVec_4,
  input         io_splitLoadResp_bits_uop_exceptionVec_5,
  input         io_splitLoadResp_bits_uop_exceptionVec_13,
  input         io_splitLoadResp_bits_uop_exceptionVec_19,
  input         io_splitLoadResp_bits_uop_exceptionVec_21,
  input  [3:0]  io_splitLoadResp_bits_uop_trigger,
  input  [128:0] io_splitLoadResp_bits_data,
  input         io_splitLoadResp_bits_nc,
  input         io_splitLoadResp_bits_mmio,
  input         io_splitLoadResp_bits_memBackTypeMM,
  input         io_splitLoadResp_bits_vecActive,
  input         io_splitLoadResp_bits_misalignNeedWakeUp,
  input         io_splitLoadResp_bits_rep_info_cause_0,
  input         io_splitLoadResp_bits_rep_info_cause_1,
  input         io_splitLoadResp_bits_rep_info_cause_2,
  input         io_splitLoadResp_bits_rep_info_cause_3,
  input         io_splitLoadResp_bits_rep_info_cause_4,
  input         io_splitLoadResp_bits_rep_info_cause_5,
  input         io_splitLoadResp_bits_rep_info_cause_6,
  input         io_splitLoadResp_bits_rep_info_cause_7,
  input         io_splitLoadResp_bits_rep_info_cause_8,
  input         io_splitLoadResp_bits_rep_info_cause_9,
  input         io_splitLoadResp_bits_rep_info_cause_10,
  // ---- 标量写回 ROB io_writeBack ----
  input         io_writeBack_ready,
  output        io_writeBack_valid,
  output        io_writeBack_bits_uop_exceptionVec_3,
  output        io_writeBack_bits_uop_exceptionVec_4,
  output        io_writeBack_bits_uop_exceptionVec_5,
  output        io_writeBack_bits_uop_exceptionVec_13,
  output        io_writeBack_bits_uop_exceptionVec_19,
  output        io_writeBack_bits_uop_exceptionVec_21,
  output [3:0]  io_writeBack_bits_uop_trigger,
  output        io_writeBack_bits_uop_rfWen,
  output        io_writeBack_bits_uop_fpWen,
  output [7:0]  io_writeBack_bits_uop_pdest,
  output        io_writeBack_bits_uop_robIdx_flag,
  output [7:0]  io_writeBack_bits_uop_robIdx_value,
  output [63:0] io_writeBack_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_writeBack_bits_uop_debugInfo_selectTime,
  output [63:0] io_writeBack_bits_uop_debugInfo_issueTime,
  output [63:0] io_writeBack_bits_data,
  output        io_writeBack_bits_debug_isMMIO,
  output        io_writeBack_bits_debug_isNCIO,
  // ---- 向量写回 VecMergeBuffer io_vecWriteBack ----
  output        io_vecWriteBack_valid,
  output [3:0]  io_vecWriteBack_bits_mBIndex,
  output        io_vecWriteBack_bits_exceptionVec_3,
  output        io_vecWriteBack_bits_exceptionVec_4,
  output        io_vecWriteBack_bits_exceptionVec_5,
  output        io_vecWriteBack_bits_exceptionVec_13,
  output        io_vecWriteBack_bits_exceptionVec_19,
  output        io_vecWriteBack_bits_exceptionVec_21,
  output        io_vecWriteBack_bits_hasException,
  output [63:0] io_vecWriteBack_bits_vaddr,
  output        io_vecWriteBack_bits_vaNeedExt,
  output [63:0] io_vecWriteBack_bits_gpaddr,
  output [7:0]  io_vecWriteBack_bits_vstart,
  output [15:0] io_vecWriteBack_bits_vecTriggerMask,
  output [7:0]  io_vecWriteBack_bits_elemIdx,
  output [15:0] io_vecWriteBack_bits_mask,
  output [2:0]  io_vecWriteBack_bits_alignedType,
  output [7:0]  io_vecWriteBack_bits_elemIdxInsideVd,
  output [127:0] io_vecWriteBack_bits_vecdata,
  input         io_loadOutValid,
  input         io_loadVecOutValid,
  output        io_loadMisalignFull
);

  // ===========================================================================
  //  缓冲条目类型：把一条 load 的全部 uop/元数据聚成 struct（替代几十个散标量 reg）
  // ===========================================================================
  typedef struct packed {
    // 异常向量（load 关心位；bit4=loadAddrMisaligned 不入 enq，由拆分清零）
    logic        exc0, exc1, exc2, exc3, exc5, exc6, exc7, exc8, exc9, exc10;
    logic        exc11, exc12, exc13, exc14, exc15, exc16, exc17, exc18;
    logic        exc19, exc20, exc21, exc22, exc23;
    logic [3:0]  trigger;
    logic        preDecodeInfo_isRVC;
    logic        ftqPtr_flag;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
    logic [8:0]  fuOpType;
    logic        rfWen, fpWen;
    logic [7:0]  vpu_vstart;
    logic [1:0]  vpu_veew;
    logic [6:0]  uopIdx;
    logic [7:0]  pdest;
    logic        robIdx_flag;
    logic [7:0]  robIdx_value;
    logic [63:0] dbg_enqRsTime, dbg_selectTime, dbg_issueTime;
    logic        storeSetHit;
    logic        waitForRobIdx_flag;
    logic [7:0]  waitForRobIdx_value;
    logic        loadWaitBit, loadWaitStrict;
    logic        lqIdx_flag;
    logic [6:0]  lqIdx_value;
    logic        sqIdx_flag;
    logic [5:0]  sqIdx_value;
    logic [49:0] vaddr;
    logic [63:0] fullva;
    logic        vaNeedExt;
    logic [63:0] gpaddr;
    logic [15:0] mask;
    logic        isvec;
    logic [7:0]  elemIdx;
    logic [2:0]  alignedType;
    logic [3:0]  mbIndex;
    logic [7:0]  elemIdxInsideVd;
    logic [15:0] vecTriggerMask;
  } enq_payload_t;

  // 3 个 enq 口聚成数组，便于 for/优先级仲裁。
  localparam int ENQ = 3;
  enq_payload_t enq_bits  [ENQ];
  logic         enq_valid [ENQ];

  `define PACK_ENQ(IDX, P) \
    assign enq_valid[IDX] = io_enq_``P``_req_valid; \
    assign enq_bits[IDX] = '{ \
      exc0: io_enq_``P``_req_bits_uop_exceptionVec_0, exc1: io_enq_``P``_req_bits_uop_exceptionVec_1, \
      exc2: io_enq_``P``_req_bits_uop_exceptionVec_2, exc3: io_enq_``P``_req_bits_uop_exceptionVec_3, \
      exc5: io_enq_``P``_req_bits_uop_exceptionVec_5, exc6: io_enq_``P``_req_bits_uop_exceptionVec_6, \
      exc7: io_enq_``P``_req_bits_uop_exceptionVec_7, exc8: io_enq_``P``_req_bits_uop_exceptionVec_8, \
      exc9: io_enq_``P``_req_bits_uop_exceptionVec_9, exc10: io_enq_``P``_req_bits_uop_exceptionVec_10, \
      exc11: io_enq_``P``_req_bits_uop_exceptionVec_11, exc12: io_enq_``P``_req_bits_uop_exceptionVec_12, \
      exc13: io_enq_``P``_req_bits_uop_exceptionVec_13, exc14: io_enq_``P``_req_bits_uop_exceptionVec_14, \
      exc15: io_enq_``P``_req_bits_uop_exceptionVec_15, exc16: io_enq_``P``_req_bits_uop_exceptionVec_16, \
      exc17: io_enq_``P``_req_bits_uop_exceptionVec_17, exc18: io_enq_``P``_req_bits_uop_exceptionVec_18, \
      exc19: io_enq_``P``_req_bits_uop_exceptionVec_19, exc20: io_enq_``P``_req_bits_uop_exceptionVec_20, \
      exc21: io_enq_``P``_req_bits_uop_exceptionVec_21, exc22: io_enq_``P``_req_bits_uop_exceptionVec_22, \
      exc23: io_enq_``P``_req_bits_uop_exceptionVec_23, \
      trigger: io_enq_``P``_req_bits_uop_trigger, \
      preDecodeInfo_isRVC: io_enq_``P``_req_bits_uop_preDecodeInfo_isRVC, \
      ftqPtr_flag: io_enq_``P``_req_bits_uop_ftqPtr_flag, ftqPtr_value: io_enq_``P``_req_bits_uop_ftqPtr_value, \
      ftqOffset: io_enq_``P``_req_bits_uop_ftqOffset, fuOpType: io_enq_``P``_req_bits_uop_fuOpType, \
      rfWen: io_enq_``P``_req_bits_uop_rfWen, fpWen: io_enq_``P``_req_bits_uop_fpWen, \
      vpu_vstart: io_enq_``P``_req_bits_uop_vpu_vstart, vpu_veew: io_enq_``P``_req_bits_uop_vpu_veew, \
      uopIdx: io_enq_``P``_req_bits_uop_uopIdx, pdest: io_enq_``P``_req_bits_uop_pdest, \
      robIdx_flag: io_enq_``P``_req_bits_uop_robIdx_flag, robIdx_value: io_enq_``P``_req_bits_uop_robIdx_value, \
      dbg_enqRsTime: io_enq_``P``_req_bits_uop_debugInfo_enqRsTime, \
      dbg_selectTime: io_enq_``P``_req_bits_uop_debugInfo_selectTime, \
      dbg_issueTime: io_enq_``P``_req_bits_uop_debugInfo_issueTime, \
      storeSetHit: io_enq_``P``_req_bits_uop_storeSetHit, \
      waitForRobIdx_flag: io_enq_``P``_req_bits_uop_waitForRobIdx_flag, \
      waitForRobIdx_value: io_enq_``P``_req_bits_uop_waitForRobIdx_value, \
      loadWaitBit: io_enq_``P``_req_bits_uop_loadWaitBit, loadWaitStrict: io_enq_``P``_req_bits_uop_loadWaitStrict, \
      lqIdx_flag: io_enq_``P``_req_bits_uop_lqIdx_flag, lqIdx_value: io_enq_``P``_req_bits_uop_lqIdx_value, \
      sqIdx_flag: io_enq_``P``_req_bits_uop_sqIdx_flag, sqIdx_value: io_enq_``P``_req_bits_uop_sqIdx_value, \
      vaddr: io_enq_``P``_req_bits_vaddr, fullva: io_enq_``P``_req_bits_fullva, \
      vaNeedExt: io_enq_``P``_req_bits_vaNeedExt, gpaddr: io_enq_``P``_req_bits_gpaddr, \
      mask: io_enq_``P``_req_bits_mask, isvec: io_enq_``P``_req_bits_isvec, \
      elemIdx: io_enq_``P``_req_bits_elemIdx, alignedType: io_enq_``P``_req_bits_alignedType, \
      mbIndex: io_enq_``P``_req_bits_mbIndex, elemIdxInsideVd: io_enq_``P``_req_bits_elemIdxInsideVd, \
      vecTriggerMask: io_enq_``P``_req_bits_vecTriggerMask }
  `PACK_ENQ(0, 0);
  `PACK_ENQ(1, 1);
  `PACK_ENQ(2, 2);

  // ===========================================================================
  //  入队仲裁：单条目缓冲，3 口固定优先级（0>1>2）选最先 valid 者
  // ===========================================================================
  logic         req_valid;
  enq_payload_t req;

  assign io_loadMisalignFull = req_valid;

  // 优先级选择（ParallelPriorityMux）：选第一个 valid 的 enq。
  logic         sel_valid;
  enq_payload_t sel_bits;
  always_comb begin
    sel_valid = 1'b0;
    sel_bits  = enq_bits[0];
    for (int i = ENQ-1; i >= 0; i--) begin
      if (enq_valid[i]) begin
        sel_valid = 1'b1;
        sel_bits  = enq_bits[i];
      end
    end
  end

  // enq ready：缓冲空且本口被选中（固定优先级屏蔽）。
  assign io_enq_0_req_ready = ~req_valid & enq_valid[0];
  assign io_enq_1_req_ready = ~enq_valid[0] & ~req_valid & enq_valid[1];
  assign io_enq_2_req_ready = ~(enq_valid[0] | enq_valid[1]) & ~req_valid & enq_valid[2];

  // 选中者未被冲刷且缓冲空 → 本拍入队。
  logic sel_flush, canEnqValid;
  assign sel_flush = robNeedFlush(sel_bits.robIdx_flag, sel_bits.robIdx_value,
                                  io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value,
                                  io_redirect_valid, io_redirect_bits_level);
  assign canEnqValid = ~req_valid & ~sel_flush & sel_valid;

  // ===========================================================================
  //  拆分状态机
  // ===========================================================================
  // 用 3 位向量而非 enum 类型存状态：enum 变量在 case 里会让 Formality 把非法编码
  //   (6/7) 当 don't-care 建成 X 源；用 logic[2:0] + 具名常量(S_*)比较则保持纯组合。
  logic [2:0]  bufferState;

  // 子 load 请求寄存：仅 fuOpType[1:0]/vaddr/mask 在 split 时按 size 改写；
  // 其余 uop/元数据是「s_split 当拍对 req 的快照」(split_uop)。golden 给 low/high
  // 各存一份全量 uop，但两份除 fuOpType/vaddr/mask 外完全相同，故这里共享一份快照。
  logic [1:0]   splitReq_size  [MAX_SPLIT]; // 该次子 load 的对齐 size 编码
  logic [49:0]  splitReq_vaddr [MAX_SPLIT];
  logic [15:0]  splitReq_mask  [MAX_SPLIT];
  enq_payload_t split_uop;                  // s_split 锁存的 uop/元数据快照
  // 合并所需：各侧「右移字节数 / 截取字节数」。
  // 注：拆分表里 high 子 load 的「右移字节数」恒为 0（高地址段总是从其对齐字的
  //   字节 0 开始取），故不设 highResultShift 寄存器、合并时直接用常量 0；这与
  //   golden 把 high data 高字节判为 unread 而 DCE 的结构一致。
  logic [2:0]  lowResultShift, lowResultWidth, highResultWidth;

  // 两次子 load 的回应数据（只需 data；其余 resp 字段本配置未被使用，已 DCE）。
  logic [128:0] splitResp_data [MAX_SPLIT];

  logic [MAX_SPLIT-1:0] unSentLoads;  // 尚未发出的子 load（one-hot per ptr）
  logic                 curPtr;       // 当前处理的子 load 序号（0/1）
  logic [63:0]          combinedData; // 合并后的 64b 数据（扩展前）
  logic [63:0]          merged_data;  // s_comb 组合合并结果（锁存到 combinedData）
  logic [8:0]           data_select;  // genRdataOH：写回时的符号/零扩展 one-hot
  logic                 needWakeUpWB; // 写回时标记「来自 LoadUnit 唤醒」

  // 全局异常/uncache 标志（任一子 load 命中即置位，收尾走软件）。
  logic globalException, globalUncache, globalMMIO, globalNC, globalMemBackTypeMM;
  // 合并写回用的异常向量（load 关心位）。
  logic exc3_r, exc4_r, exc5_r, exc13_r, exc19_r, exc21_r;

  // ---- 子 load 回应的异常/uncache 判定 ----
  //  hasException：向量有效且任一 load 异常位置位，或 trigger 进入 debug-mode。
  logic respHasException, respIsUncache;
  assign respHasException =
      (io_splitLoadResp_bits_vecActive &
        (io_splitLoadResp_bits_uop_exceptionVec_3  | io_splitLoadResp_bits_uop_exceptionVec_4 |
         io_splitLoadResp_bits_uop_exceptionVec_5  | io_splitLoadResp_bits_uop_exceptionVec_13 |
         io_splitLoadResp_bits_uop_exceptionVec_19 | io_splitLoadResp_bits_uop_exceptionVec_21))
      | (io_splitLoadResp_bits_uop_trigger == 4'h1);
  assign respIsUncache = io_splitLoadResp_bits_mmio | io_splitLoadResp_bits_nc;

  // need_rep：子 load 需重放（rep_info.cause 任一置位）。
  logic respNeedRep;
  assign respNeedRep =
      io_splitLoadResp_bits_rep_info_cause_0  | io_splitLoadResp_bits_rep_info_cause_1 |
      io_splitLoadResp_bits_rep_info_cause_2  | io_splitLoadResp_bits_rep_info_cause_3 |
      io_splitLoadResp_bits_rep_info_cause_4  | io_splitLoadResp_bits_rep_info_cause_5 |
      io_splitLoadResp_bits_rep_info_cause_6  | io_splitLoadResp_bits_rep_info_cause_7 |
      io_splitLoadResp_bits_rep_info_cause_8  | io_splitLoadResp_bits_rep_info_cause_9 |
      io_splitLoadResp_bits_rep_info_cause_10;

  // ---- 跨 16B 判定 + size ----
  logic [1:0]  alignedType;             // 本次访问的 size（向量取 alignedType，标量取 fuOpType）
  logic [4:0]  highAddrOff;             // (vaddr 低 5 位 + (size 末字节偏移))
  logic        cross16;                 // 末字节与首字节是否跨 16B
  assign alignedType = req.isvec ? req.alignedType[1:0] : req.fuOpType[1:0];
  // size 末字节相对偏移：LB→0, LH→1, LW→3, LD→7
  logic [4:0]  sizeLastByte;
  always_comb case (size_e'(alignedType))
    SZ_B: sizeLastByte = 5'd0;
    SZ_H: sizeLastByte = 5'd1;
    SZ_W: sizeLastByte = 5'd3;
    SZ_D: sizeLastByte = 5'd7;
  endcase
  assign highAddrOff = sizeLastByte + req.vaddr[4:0];
  assign cross16 = req_valid & (highAddrOff[4] != req.vaddr[4]);

  // ---- 拆分表：依 (size, vaddr 低位) 给出 low/high 子 load 的
  //      {size, vaddr, mask 对齐基, resultShift, resultWidth}。
  //  完全对照 Scala switch(alignedType)/switch(vaddr 低位)。返回打包结构。
  typedef struct packed {
    logic [1:0] lowSz;   logic [49:0] lowVa;   logic [2:0] lowShift; logic [2:0] lowWidth;
    logic [1:0] highSz;  logic [49:0] highVa;  logic [2:0] highShift;logic [2:0] highWidth;
  } split_plan_t;

  function automatic split_plan_t planSplit(input logic [1:0] sz, input logic [49:0] va);
    split_plan_t p;
    // 默认全 0（仅作兜底，正常拆分必落入下列分支之一）。
    p = '0;
    case (size_e'(sz))
      SZ_H: begin
        p.lowSz=SZ_B;  p.lowVa=va;        p.lowShift=3'd0; p.lowWidth=3'd1;
        p.highSz=SZ_B; p.highVa=va+50'd1; p.highShift=3'd0;p.highWidth=3'd1;
      end
      SZ_W: case (va[1:0])
        2'b01: begin
          p.lowSz=SZ_W;  p.lowVa=va-50'd1; p.lowShift=3'd1; p.lowWidth=3'd3;
          p.highSz=SZ_B; p.highVa=va+50'd3;p.highShift=3'd0;p.highWidth=3'd1;
        end
        2'b10: begin
          p.lowSz=SZ_H;  p.lowVa=va;       p.lowShift=3'd0; p.lowWidth=3'd2;
          p.highSz=SZ_H; p.highVa=va+50'd2;p.highShift=3'd0;p.highWidth=3'd2;
        end
        2'b11: begin
          p.lowSz=SZ_B;  p.lowVa=va;       p.lowShift=3'd0; p.lowWidth=3'd1;
          p.highSz=SZ_W; p.highVa=va+50'd1;p.highShift=3'd0;p.highWidth=3'd3;
        end
        default: ;
      endcase
      SZ_D: case (va[2:0])
        3'b001: begin
          p.lowSz=SZ_D;  p.lowVa=va-50'd1; p.lowShift=3'd1; p.lowWidth=3'd7;
          p.highSz=SZ_B; p.highVa=va+50'd7;p.highShift=3'd0;p.highWidth=3'd1;
        end
        3'b010: begin
          p.lowSz=SZ_D;  p.lowVa=va-50'd2; p.lowShift=3'd2; p.lowWidth=3'd6;
          p.highSz=SZ_H; p.highVa=va+50'd6;p.highShift=3'd0;p.highWidth=3'd2;
        end
        3'b011: begin
          p.lowSz=SZ_D;  p.lowVa=va-50'd3; p.lowShift=3'd3; p.lowWidth=3'd5;
          p.highSz=SZ_W; p.highVa=va+50'd5;p.highShift=3'd0;p.highWidth=3'd3;
        end
        3'b100: begin
          p.lowSz=SZ_W;  p.lowVa=va;       p.lowShift=3'd0; p.lowWidth=3'd4;
          p.highSz=SZ_W; p.highVa=va+50'd4;p.highShift=3'd0;p.highWidth=3'd4;
        end
        3'b101: begin
          p.lowSz=SZ_W;  p.lowVa=va-50'd1; p.lowShift=3'd1; p.lowWidth=3'd3;
          p.highSz=SZ_D; p.highVa=va+50'd3;p.highShift=3'd0;p.highWidth=3'd5;
        end
        3'b110: begin
          p.lowSz=SZ_H;  p.lowVa=va;       p.lowShift=3'd0; p.lowWidth=3'd2;
          p.highSz=SZ_D; p.highVa=va+50'd2;p.highShift=3'd0;p.highWidth=3'd6;
        end
        3'b111: begin
          p.lowSz=SZ_B;  p.lowVa=va;       p.lowShift=3'd0; p.lowWidth=3'd1;
          p.highSz=SZ_D; p.highVa=va+50'd1;p.highShift=3'd0;p.highWidth=3'd7;
        end
        default: ;
      endcase
      default: ; // SZ_B 不会触发非对齐拆分
    endcase
    planSplit = p;
  endfunction

  // mask = getMask(size) << vaddr[3:0]（落在 16B 窗口内的字节使能）。
  function automatic logic [15:0] genMask(input logic [1:0] sz, input logic [49:0] va);
    genMask = {8'h0, getMask(size_e'(sz))} << va[3:0];
  endfunction

  split_plan_t plan;
  assign plan = planSplit(alignedType, req.vaddr);

  // ---- needWakeUpReqsWire：在 s_comb 且标量时，需再发一次 wakeup load ----
  logic needWakeUpReqsWire;
  assign needWakeUpReqsWire = (bufferState == S_COMB_WAKEUP_REP) & ~req.isvec;

  // ---- flush（缓冲中的 req 被 redirect 冲刷）----
  logic flush;
  assign flush = req_valid & robNeedFlush(req.robIdx_flag, req.robIdx_value,
                                          io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value,
                                          io_redirect_valid, io_redirect_bits_level);

  // genRdataOH：依 fuOpType/fpWen 生成「写回扩展方式」one-hot（9 位）。
  //  对照 LoadQueue.genRdataOH 的 Cat 顺序（bit0=lbu ... bit8=lw&fp）。
  function automatic logic [8:0] genRdataOH(input logic [8:0] op, input logic fpWen);
    logic isLw, isLh;
    isLw = (op == 9'h2);
    isLh = (op == 9'h1);
    genRdataOH = {
      isLw & fpWen,                                            // [8] lw & fp  → box S
      isLh & fpWen,                                            // [7] lh & fp  → box H
      (isLw & ~fpWen) | (op == 9'h12),                         // [6] lw/hlvw  → sext32
      (isLh & ~fpWen) | (op == 9'h11),                         // [5] lh/hlvh  → sext16
      (op == 9'h0)  | (op == 9'h10),                           // [4] lb/hlvb  → sext8
      (op == 9'h3)  | (op == 9'h13),                           // [3] ld/hlvd  → 64b
      (op == 9'h6)  | (op == 9'h16) | (op == 9'h1E),           // [2] lwu/...  → zext32
      (op == 9'h5)  | (op == 9'h15) | (op == 9'h1D),           // [1] lhu/...  → zext16
      (op == 9'h4)  | (op == 9'h14)                            // [0] lbu/hlvbu→ zext8
    };
  endfunction

  // ===========================================================================
  //  状态机 + 寄存器更新（时序）
  // ===========================================================================
  // s_resp 当拍是否「未发完还有子 load」：unSentLoads 去掉当前 ptr 后仍非空。
  logic respMoreUnsent;
  assign respMoreUnsent = |(unSentLoads & ~(2'b01 << curPtr));

  // 条目清空（写回完成 / 冲刷）：与 Scala 各 reset 字段一一对应。用宏内联以保证
  // Formality 把这些 NBA 视作本 always_ff 的赋值（纯函数不能写非局部信号）。
  `define CLEAR_ENTRY \
    begin \
      bufferState         <= S_IDLE; \
      req_valid           <= 1'b0; \
      curPtr              <= 1'b0; \
      unSentLoads         <= '0; \
      globalException     <= 1'b0; \
      globalUncache       <= 1'b0; \
      needWakeUpWB        <= 1'b0; \
      globalMMIO          <= 1'b0; \
      globalNC            <= 1'b0; \
      globalMemBackTypeMM <= 1'b0; \
    end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      req_valid           <= 1'b0;
      // 注：req（缓冲条目数据）与 golden 一致「不复位」（仅入队时写）。
      bufferState         <= S_IDLE;
      unSentLoads         <= '0;
      curPtr              <= 1'b0;
      combinedData        <= '0;
      data_select         <= '0;
      needWakeUpWB        <= 1'b0;
      globalException     <= 1'b0;
      globalUncache       <= 1'b0;
      globalMMIO          <= 1'b0;
      globalNC            <= 1'b0;
      globalMemBackTypeMM <= 1'b0;
      lowResultShift      <= '0;
      lowResultWidth      <= '0;
      highResultWidth     <= '0;
      split_uop           <= '0;
      {exc3_r,exc4_r,exc5_r,exc13_r,exc19_r,exc21_r} <= '0;
      for (int i = 0; i < MAX_SPLIT; i++) begin
        splitReq_size[i]  <= '0;
        splitReq_vaddr[i] <= '0;
        splitReq_mask[i]  <= '0;
        splitResp_data[i] <= '0;
      end
    end else begin
      // ---- 入队：锁存选中 req + genRdataOH ----
      if (canEnqValid) begin
        req         <= sel_bits;
        req_valid   <= 1'b1;
        data_select <= genRdataOH(sel_bits.fuOpType, sel_bits.fpWen);
      end

      // ---- 状态转移（用优先级 if-else 链表达，等价于 golden 的嵌套 if）----
      //  写成「先判当前状态、逐级跳转」的链：每个未跳转分支天然保持(reg 不赋值即保持)，
      //  没有 case 默认分支被建成 X 的风险。
      // S_SPLIT 的拆分寄存器写入（仅 cross16，且 size 非 LB 时写地址/掩码/宽度）。
      if (bufferState == S_SPLIT) begin
        if (cross16) begin
          unSentLoads <= 2'b11;
          curPtr      <= 1'b0;
          split_uop   <= req;   // 快照 uop（loadAddrMisaligned 在输出端清零）
          if (|alignedType) begin
            splitReq_size[0]  <= plan.lowSz;   splitReq_vaddr[0] <= plan.lowVa;
            splitReq_size[1]  <= plan.highSz;  splitReq_vaddr[1] <= plan.highVa;
            splitReq_mask[0]  <= genMask(plan.lowSz,  plan.lowVa);
            splitReq_mask[1]  <= genMask(plan.highSz, plan.highVa);
            lowResultShift    <= plan.lowShift;  lowResultWidth  <= plan.lowWidth;
            highResultWidth   <= plan.highWidth; // plan.highShift 恒 0，省略
          end
        end
        {exc3_r,exc4_r,exc5_r,exc13_r,exc19_r,exc21_r} <= '0;
      end

      // 次态转移（优先级链；S_RESP 的全局异常/uncache 标志一并锁存）。
      if (bufferState == S_IDLE) begin
        if (req_valid) bufferState <= S_SPLIT;
      end else if (bufferState == S_SPLIT) begin
        bufferState <= S_REQ;
      end else if (bufferState == S_REQ) begin
        if (io_splitLoadReq_ready & io_splitLoadReq_valid) bufferState <= S_RESP;
      end else if (bufferState == S_RESP) begin
        if (io_splitLoadResp_valid) begin
          if (respHasException | respIsUncache) begin
            bufferState         <= S_WB;
            globalException     <= respHasException;
            globalUncache       <= respIsUncache;
            globalMMIO          <= io_splitLoadResp_bits_mmio;
            globalNC            <= io_splitLoadResp_bits_nc;
            globalMemBackTypeMM <= io_splitLoadResp_bits_memBackTypeMM;
          end else if (respNeedRep | respMoreUnsent) begin
            bufferState <= S_REQ; // 重放或还有未发子 load
          end else begin
            bufferState  <= S_COMB_WAKEUP_REP;
            needWakeUpWB <= ~req.isvec;
          end
        end
      end else if (bufferState == S_COMB_WAKEUP_REP) begin
        // 标量：发完 wakeup load(fire)进 s_wb；向量：直接进 s_wb。
        if (~req.isvec) begin
          if (io_splitLoadReq_ready & io_splitLoadReq_valid) bufferState <= S_WB;
        end else begin
          bufferState <= S_WB;
        end
      end else if (bufferState == S_WB) begin
        if (req.isvec) begin
          if (io_vecWriteBack_valid /* vec 写回口 ready 恒 1 */) `CLEAR_ENTRY
        end else begin
          if (io_writeBack_valid & io_writeBack_ready) `CLEAR_ENTRY
        end
      end

      // ---- s_resp 收下回应数据 + 维护 unSentLoads/curPtr/异常向量 ----
      if (io_splitLoadResp_valid) begin
        splitResp_data[curPtr] <= io_splitLoadResp_bits_data;
        if (respIsUncache) begin
          unSentLoads <= '0;
          // 交软件处理：清异常向量、置 loadAddrMisaligned(bit4)。
          {exc3_r,exc5_r,exc13_r,exc19_r,exc21_r} <= '0;
          exc4_r <= 1'b1;
        end else if (respHasException) begin
          unSentLoads <= '0;
          // 累积本次回应的 load 异常位。
          exc3_r  <= exc3_r  | io_splitLoadResp_bits_uop_exceptionVec_3;
          exc4_r  <= exc4_r  | io_splitLoadResp_bits_uop_exceptionVec_4;
          exc5_r  <= exc5_r  | io_splitLoadResp_bits_uop_exceptionVec_5;
          exc13_r <= exc13_r | io_splitLoadResp_bits_uop_exceptionVec_13;
          exc19_r <= exc19_r | io_splitLoadResp_bits_uop_exceptionVec_19;
          exc21_r <= exc21_r | io_splitLoadResp_bits_uop_exceptionVec_21;
        end else if (~respNeedRep) begin
          unSentLoads <= unSentLoads & ~(2'b01 << curPtr);
          curPtr      <= curPtr + 1'b1;
          {exc3_r,exc4_r,exc5_r,exc13_r,exc19_r,exc21_r} <= '0;
        end
      end

      // ---- s_comb：合并两次数据 + 扩展 ----
      if (bufferState == S_COMB_WAKEUP_REP) begin
        combinedData <= merged_data;
      end

      // ---- flush 优先级最高，整体复位条目 ----
      if (flush) `CLEAR_ENTRY
    end
  end

  // ---- 逐字节合并 + 符号/零扩展（组合逻辑，s_comb 时锁存到 combinedData）----
  //  lowSeg / highSeg：把两次回应数据各自右移/截取出有效段；
  //  catResult[i] = (i < lowWidth) ? lowSeg[i] : highSeg[i-lowWidth]。
  //  merged_data 在向量与标量下扩展方式不同（向量按 alignedType 零扩展，标量 rdataHelper）。
  always_comb begin
    logic [63:0] lowSeg, highSeg;
    logic [7:0]  lowByte [8], highByte [8], cat [8];
    logic [63:0] catv;
    logic [2:0]  j;
    lowSeg  = shiftAndTruncate(lowResultShift,  lowResultWidth,  splitResp_data[0][63:0]);
    highSeg = shiftAndTruncate(3'd0, highResultWidth, splitResp_data[1][63:0]);
    // 拆成字节数组，索引一律用 3 位量（与 golden 的 3'(i-lowWidth) 同构，避免
    //   part-select 越界被工具判 X）。highByte[7] 恒 0（high 段最多 7 字节）。
    for (int b = 0; b < 8; b++) begin
      lowByte[b]  = lowSeg[b*8 +: 8];
      highByte[b] = (b == 7) ? 8'h0 : highSeg[b*8 +: 8];
    end
    for (int i = 0; i < 8; i++) begin
      j = 3'(i) - lowResultWidth;           // 3 位回绕减法
      cat[i] = (3'(i) < lowResultWidth) ? lowByte[i] : highByte[j];
    end
    catv = {cat[7],cat[6],cat[5],cat[4],cat[3],cat[2],cat[1],cat[0]};
    // 扩展用「互斥 OR-mux」表达（而非 case），与 golden combinedData 结构一致，
    //   避免 Formality 把 case 默认分支建成 X 源。每个分支由其条件选通，互斥求或。
    if (req.isvec) begin
      // 向量：按全 3 位 alignedType 精确零扩展；alignedType>=4 时无分支命中 → 0。
      merged_data =
          ((req.alignedType == 3'd0) ? {56'h0, catv[7:0]}  : 64'h0)
        | ((req.alignedType == 3'd1) ? {48'h0, catv[15:0]} : 64'h0)
        | ((req.alignedType == 3'd2) ? {32'h0, catv[31:0]} : 64'h0)
        | ((req.alignedType == 3'd3) ? catv                : 64'h0);
    end else begin
      // 标量：按 fuOpType 做符号/零扩展（含浮点 NaN-box）。无匹配 fuOpType → 0。
      merged_data =
          ((req.fuOpType == 9'h0)  ? {{56{catv[7]}},  catv[7:0]}  : 64'h0) // lb
        | ((req.fuOpType == 9'h1)  ? {{48{catv[15]}}, catv[15:0]} : 64'h0) // lh
        | ((req.fuOpType == 9'h2)  ? {req.fpWen ? 32'hFFFFFFFF : {32{catv[31]}}, catv[31:0]} : 64'h0) // lw(/box S)
        | ((req.fuOpType == 9'h3)  ? catv                        : 64'h0) // ld
        | ((req.fuOpType == 9'h4)  ? {56'h0, catv[7:0]}          : 64'h0) // lbu
        | ((req.fuOpType == 9'h5)  ? {48'h0, catv[15:0]}         : 64'h0) // lhu
        | ((req.fuOpType == 9'h6)  ? {32'h0, catv[31:0]}         : 64'h0) // lwu
        | ((req.fuOpType == 9'h10) ? {{56{catv[7]}},  catv[7:0]} : 64'h0) // hlvb
        | ((req.fuOpType == 9'h11) ? {{48{catv[15]}}, catv[15:0]}: 64'h0) // hlvh
        | ((req.fuOpType == 9'h12) ? {{32{catv[31]}}, catv[31:0]}: 64'h0) // hlvw
        | ((req.fuOpType == 9'h13) ? catv                        : 64'h0) // hlvd
        | ((req.fuOpType == 9'h14) ? {56'h0, catv[7:0]}          : 64'h0) // hlvbu
        | ((req.fuOpType == 9'h15) ? {48'h0, catv[15:0]}         : 64'h0) // hlvhu
        | ((req.fuOpType == 9'h16) ? {32'h0, catv[31:0]}         : 64'h0) // hlvwu
        | ((req.fuOpType == 9'h1D) ? {48'h0, catv[15:0]}         : 64'h0) // hlvxhu
        | ((req.fuOpType == 9'h1E) ? {32'h0, catv[31:0]}         : 64'h0);// hlvxwu
    end
  end

  // ===========================================================================
  //  splitLoadReq 输出：当前 curPtr 子 load。uop 多数透传 req，少数按拆分改写。
  // ===========================================================================
  // splitLoadReq.valid：s_req 状态，或 s_comb 标量需发 wakeup。
  assign io_splitLoadReq_valid = req_valid &
      ((bufferState == S_REQ) |
       ((bufferState == S_COMB_WAKEUP_REP) & needWakeUpReqsWire & ~req.isvec));

  // 当前子 load 的 size/vaddr/mask（curPtr 选 low/high）。
  logic [1:0]  cur_size;
  logic [49:0] cur_vaddr;
  logic [15:0] cur_mask;
  assign cur_size  = curPtr ? splitReq_size[1]  : splitReq_size[0];
  assign cur_vaddr = curPtr ? splitReq_vaddr[1] : splitReq_vaddr[0];
  assign cur_mask  = curPtr ? splitReq_mask[1]  : splitReq_mask[0];

  // uop 字段全部取自 s_split 快照 split_uop（与 golden splitLoadReqs_N 一致）；
  //   loadAddrMisaligned(bit4) 被拆分清零（恒 0），其余位透传快照。
  assign io_splitLoadReq_bits_uop_exceptionVec_0  = split_uop.exc0;
  assign io_splitLoadReq_bits_uop_exceptionVec_1  = split_uop.exc1;
  assign io_splitLoadReq_bits_uop_exceptionVec_2  = split_uop.exc2;
  assign io_splitLoadReq_bits_uop_exceptionVec_3  = split_uop.exc3;
  assign io_splitLoadReq_bits_uop_exceptionVec_4  = 1'b0; // loadAddrMisaligned 清零
  assign io_splitLoadReq_bits_uop_exceptionVec_5  = split_uop.exc5;
  assign io_splitLoadReq_bits_uop_exceptionVec_6  = split_uop.exc6;
  assign io_splitLoadReq_bits_uop_exceptionVec_7  = split_uop.exc7;
  assign io_splitLoadReq_bits_uop_exceptionVec_8  = split_uop.exc8;
  assign io_splitLoadReq_bits_uop_exceptionVec_9  = split_uop.exc9;
  assign io_splitLoadReq_bits_uop_exceptionVec_10 = split_uop.exc10;
  assign io_splitLoadReq_bits_uop_exceptionVec_11 = split_uop.exc11;
  assign io_splitLoadReq_bits_uop_exceptionVec_12 = split_uop.exc12;
  assign io_splitLoadReq_bits_uop_exceptionVec_13 = split_uop.exc13;
  assign io_splitLoadReq_bits_uop_exceptionVec_14 = split_uop.exc14;
  assign io_splitLoadReq_bits_uop_exceptionVec_15 = split_uop.exc15;
  assign io_splitLoadReq_bits_uop_exceptionVec_16 = split_uop.exc16;
  assign io_splitLoadReq_bits_uop_exceptionVec_17 = split_uop.exc17;
  assign io_splitLoadReq_bits_uop_exceptionVec_18 = split_uop.exc18;
  assign io_splitLoadReq_bits_uop_exceptionVec_19 = split_uop.exc19;
  assign io_splitLoadReq_bits_uop_exceptionVec_20 = split_uop.exc20;
  assign io_splitLoadReq_bits_uop_exceptionVec_21 = split_uop.exc21;
  assign io_splitLoadReq_bits_uop_exceptionVec_22 = split_uop.exc22;
  assign io_splitLoadReq_bits_uop_exceptionVec_23 = split_uop.exc23;
  assign io_splitLoadReq_bits_uop_trigger         = split_uop.trigger;
  assign io_splitLoadReq_bits_uop_preDecodeInfo_isRVC = split_uop.preDecodeInfo_isRVC;
  assign io_splitLoadReq_bits_uop_ftqPtr_flag     = split_uop.ftqPtr_flag;
  assign io_splitLoadReq_bits_uop_ftqPtr_value    = split_uop.ftqPtr_value;
  assign io_splitLoadReq_bits_uop_ftqOffset       = split_uop.ftqOffset;
  // fuOpType 重建：标量 → {0000, isHlv, isHlvx, 0, 子load size[1:0]}；向量 → 原 fuOpType。
  //   注：isHlv/isHlvx 与 isvec 取自当前 req（与 Scala 一致，用 req.uop 计算）。
  logic reqIsHlv, reqIsHlvx;
  assign reqIsHlv  = req.fuOpType[4] & ~req.fuOpType[5] & ~(|req.fuOpType[8:7]);
  assign reqIsHlvx = req.fuOpType[4] & req.fuOpType[3] & ~req.fuOpType[5] & ~(|req.fuOpType[8:7]);
  assign io_splitLoadReq_bits_uop_fuOpType =
      req.isvec ? req.fuOpType
                : {4'h0, reqIsHlv, reqIsHlvx, 1'b0, cur_size};
  assign io_splitLoadReq_bits_uop_rfWen           = split_uop.rfWen;
  assign io_splitLoadReq_bits_uop_fpWen           = split_uop.fpWen;
  assign io_splitLoadReq_bits_uop_vpu_vstart      = split_uop.vpu_vstart;
  assign io_splitLoadReq_bits_uop_vpu_veew        = split_uop.vpu_veew;
  assign io_splitLoadReq_bits_uop_uopIdx          = split_uop.uopIdx;
  assign io_splitLoadReq_bits_uop_pdest           = split_uop.pdest;
  assign io_splitLoadReq_bits_uop_robIdx_flag     = split_uop.robIdx_flag;
  assign io_splitLoadReq_bits_uop_robIdx_value    = split_uop.robIdx_value;
  assign io_splitLoadReq_bits_uop_debugInfo_enqRsTime  = split_uop.dbg_enqRsTime;
  assign io_splitLoadReq_bits_uop_debugInfo_selectTime = split_uop.dbg_selectTime;
  assign io_splitLoadReq_bits_uop_debugInfo_issueTime  = split_uop.dbg_issueTime;
  assign io_splitLoadReq_bits_uop_storeSetHit     = split_uop.storeSetHit;
  assign io_splitLoadReq_bits_uop_waitForRobIdx_flag  = split_uop.waitForRobIdx_flag;
  assign io_splitLoadReq_bits_uop_waitForRobIdx_value = split_uop.waitForRobIdx_value;
  assign io_splitLoadReq_bits_uop_loadWaitBit     = split_uop.loadWaitBit;
  assign io_splitLoadReq_bits_uop_loadWaitStrict  = split_uop.loadWaitStrict;
  assign io_splitLoadReq_bits_uop_lqIdx_flag      = split_uop.lqIdx_flag;
  assign io_splitLoadReq_bits_uop_lqIdx_value     = split_uop.lqIdx_value;
  assign io_splitLoadReq_bits_uop_sqIdx_flag      = split_uop.sqIdx_flag;
  assign io_splitLoadReq_bits_uop_sqIdx_value     = split_uop.sqIdx_value;
  assign io_splitLoadReq_bits_vaddr  = cur_vaddr;
  assign io_splitLoadReq_bits_fullva = split_uop.fullva;
  assign io_splitLoadReq_bits_mask   = cur_mask;
  // 这些 LsPipelineBundle 字段在拆分时恒为 0（WireInit(0) 默认且从不被赋值）。
  assign io_splitLoadReq_bits_nc            = 1'b0;
  assign io_splitLoadReq_bits_mmio          = 1'b0;
  assign io_splitLoadReq_bits_memBackTypeMM = 1'b0;
  assign io_splitLoadReq_bits_isvec         = req.isvec;
  assign io_splitLoadReq_bits_is128bit      = 1'b0;
  assign io_splitLoadReq_bits_vecActive     = 1'b0;
  assign io_splitLoadReq_bits_mshrid        = 4'h0;
  assign io_splitLoadReq_bits_schedIndex    = 7'h0;
  // isFinalSplit：最后一次子 load（curPtr=1）且非 wakeup 时置位。
  assign io_splitLoadReq_bits_isFinalSplit       = curPtr & ~needWakeUpReqsWire;
  assign io_splitLoadReq_bits_misalignNeedWakeUp = needWakeUpReqsWire;

  // ===========================================================================
  //  标量写回 ROB
  // ===========================================================================
  logic uncacheOrExc;
  assign uncacheOrExc = globalUncache | globalException;

  assign io_writeBack_valid = req_valid & (bufferState == S_WB)
      & ((io_splitLoadResp_valid & io_splitLoadResp_bits_misalignNeedWakeUp) | uncacheOrExc)
      & ~io_loadOutValid & ~req.isvec;
  // 异常向量：仅在 uncache/异常时透出累积位。
  assign io_writeBack_bits_uop_exceptionVec_3  = uncacheOrExc & exc3_r;
  assign io_writeBack_bits_uop_exceptionVec_4  = uncacheOrExc & exc4_r;
  assign io_writeBack_bits_uop_exceptionVec_5  = uncacheOrExc & exc5_r;
  assign io_writeBack_bits_uop_exceptionVec_13 = uncacheOrExc & exc13_r;
  assign io_writeBack_bits_uop_exceptionVec_19 = uncacheOrExc & exc19_r;
  assign io_writeBack_bits_uop_exceptionVec_21 = uncacheOrExc & exc21_r;
  assign io_writeBack_bits_uop_trigger = req.trigger;
  assign io_writeBack_bits_uop_rfWen   = ~globalException & ~globalUncache & req.rfWen;
  assign io_writeBack_bits_uop_fpWen   = req.fpWen;
  assign io_writeBack_bits_uop_pdest   = req.pdest;
  assign io_writeBack_bits_uop_robIdx_flag  = req.robIdx_flag;
  assign io_writeBack_bits_uop_robIdx_value = req.robIdx_value;
  assign io_writeBack_bits_uop_debugInfo_enqRsTime  = req.dbg_enqRsTime;
  assign io_writeBack_bits_uop_debugInfo_selectTime = req.dbg_selectTime;
  assign io_writeBack_bits_uop_debugInfo_issueTime  = req.dbg_issueTime;
  // 写回数据：newRdataHelper(data_select, combinedData)。data_select 必为 one-hot，
  //   各档对应不同扩展（zext8/16/32、原 64b、sext8/16/32、box H/S）。
  logic [63:0] wb_data;
  always_comb begin
    wb_data = 64'h0;
    if (data_select[0]) wb_data = {56'h0, combinedData[7:0]};   // zext8
    if (data_select[1]) wb_data = {48'h0, combinedData[15:0]};  // zext16
    if (data_select[2]) wb_data = {32'h0, combinedData[31:0]};  // zext32
    if (data_select[3]) wb_data = combinedData;                 // 64b
    if (data_select[4]) wb_data = {{56{combinedData[7]}},  combinedData[7:0]};  // sext8
    if (data_select[5]) wb_data = {{48{combinedData[15]}}, combinedData[15:0]}; // sext16
    if (data_select[6]) wb_data = {{32{combinedData[31]}}, combinedData[31:0]}; // sext32
    if (data_select[7]) wb_data = {48'hFFFFFFFFFFFF, combinedData[15:0]};       // box H
    if (data_select[8]) wb_data = {32'hFFFFFFFF, combinedData[31:0]};           // box S
  end
  assign io_writeBack_bits_data = wb_data;
  assign io_writeBack_bits_debug_isMMIO = globalMMIO;
  assign io_writeBack_bits_debug_isNCIO = globalNC & ~globalMemBackTypeMM;

  // ===========================================================================
  //  向量写回 VecMergeBuffer
  // ===========================================================================
  assign io_vecWriteBack_valid = req_valid & (bufferState == S_WB) & ~io_loadVecOutValid & req.isvec;
  assign io_vecWriteBack_bits_mBIndex          = req.mbIndex;
  assign io_vecWriteBack_bits_exceptionVec_3   = exc3_r;
  assign io_vecWriteBack_bits_exceptionVec_4   = exc4_r;
  assign io_vecWriteBack_bits_exceptionVec_5   = exc5_r;
  assign io_vecWriteBack_bits_exceptionVec_13  = exc13_r;
  assign io_vecWriteBack_bits_exceptionVec_19  = exc19_r;
  assign io_vecWriteBack_bits_exceptionVec_21  = exc21_r;
  assign io_vecWriteBack_bits_hasException     = globalException;
  assign io_vecWriteBack_bits_vaddr            = req.fullva;
  assign io_vecWriteBack_bits_vaNeedExt        = req.vaNeedExt;
  assign io_vecWriteBack_bits_gpaddr           = req.gpaddr;
  assign io_vecWriteBack_bits_vstart           = req.vpu_vstart;
  assign io_vecWriteBack_bits_vecTriggerMask   = req.vecTriggerMask;
  assign io_vecWriteBack_bits_elemIdx          = req.elemIdx;
  assign io_vecWriteBack_bits_mask             = req.mask;
  assign io_vecWriteBack_bits_alignedType      = req.alignedType;
  assign io_vecWriteBack_bits_elemIdxInsideVd  = req.elemIdxInsideVd;
  assign io_vecWriteBack_bits_vecdata          = {64'h0, combinedData};

endmodule
