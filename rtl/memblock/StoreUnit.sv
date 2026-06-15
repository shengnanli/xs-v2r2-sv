// =============================================================================
//  StoreUnit —— store 地址流水单元（可读重写核 xs_StoreUnit_core）
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/pipeline/StoreUnit.scala
//  类型/常量/纯函数集中在 storeunit_pkg（见 storeunit_pkg.sv 文件头的整体说明）。
//
//  本核内部用 typedef struct 表达每一级流水的 payload（s1/s2/s3/sx），
//  用 storeunit_pkg 的 enum/纯函数表达来源仲裁、对齐/跨16B/cbo 判定、字节 mask、
//  trigger 三值规范化与 rob 冲刷；端口沿用 golden 扁平名以便 wrapper 直通、UT/FM 对齐。
//
//  ⚠ 端口集合与 golden StoreUnit 完全一致（已按本配置裁剪掉 prefetch/issue 等）。
//    s1/s2/s3 各级 ready 在本配置恒为 1（下游无 back-pressure），故流水推进
//    只由各级 valid/kill 决定；sx 只有一级延迟寄存器（RAW_DELAY_CYCLES=1）。
// =============================================================================
module xs_StoreUnit_core
  import storeunit_pkg::*;
(
  input         clock,
  input         reset,
  // ---- redirect / csr ----
  input         io_redirect_valid,
  input         io_redirect_bits_robIdx_flag,
  input  [7:0]  io_redirect_bits_robIdx_value,
  input         io_redirect_bits_level,
  input         io_csrCtrl_hd_misalign_st_enable,
  // ---- 标量发射 stin ----
  output        io_stin_ready,
  input         io_stin_valid,
  input  [5:0]  io_stin_bits_uop_ftqPtr_value,
  input  [3:0]  io_stin_bits_uop_ftqOffset,
  input  [8:0]  io_stin_bits_uop_fuOpType,
  input  [31:0] io_stin_bits_uop_imm,
  input         io_stin_bits_uop_robIdx_flag,
  input  [7:0]  io_stin_bits_uop_robIdx_value,
  input  [63:0] io_stin_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_stin_bits_uop_debugInfo_selectTime,
  input  [63:0] io_stin_bits_uop_debugInfo_issueTime,
  input         io_stin_bits_uop_sqIdx_flag,
  input  [5:0]  io_stin_bits_uop_sqIdx_value,
  input  [63:0] io_stin_bits_src_0,
  input         io_stin_bits_isFirstIssue,
  // ---- misalignBuffer 重发 misalign_stin ----
  output        io_misalign_stin_ready,
  input         io_misalign_stin_valid,
  input         io_misalign_stin_bits_uop_exceptionVec_0,
  input         io_misalign_stin_bits_uop_exceptionVec_1,
  input         io_misalign_stin_bits_uop_exceptionVec_2,
  input         io_misalign_stin_bits_uop_exceptionVec_4,
  input         io_misalign_stin_bits_uop_exceptionVec_5,
  input         io_misalign_stin_bits_uop_exceptionVec_8,
  input         io_misalign_stin_bits_uop_exceptionVec_9,
  input         io_misalign_stin_bits_uop_exceptionVec_10,
  input         io_misalign_stin_bits_uop_exceptionVec_11,
  input         io_misalign_stin_bits_uop_exceptionVec_12,
  input         io_misalign_stin_bits_uop_exceptionVec_13,
  input         io_misalign_stin_bits_uop_exceptionVec_14,
  input         io_misalign_stin_bits_uop_exceptionVec_16,
  input         io_misalign_stin_bits_uop_exceptionVec_17,
  input         io_misalign_stin_bits_uop_exceptionVec_18,
  input         io_misalign_stin_bits_uop_exceptionVec_19,
  input         io_misalign_stin_bits_uop_exceptionVec_20,
  input         io_misalign_stin_bits_uop_exceptionVec_21,
  input         io_misalign_stin_bits_uop_exceptionVec_22,
  input  [3:0]  io_misalign_stin_bits_uop_trigger,
  input  [5:0]  io_misalign_stin_bits_uop_ftqPtr_value,
  input  [3:0]  io_misalign_stin_bits_uop_ftqOffset,
  input  [8:0]  io_misalign_stin_bits_uop_fuOpType,
  input  [7:0]  io_misalign_stin_bits_uop_vpu_vstart,
  input  [1:0]  io_misalign_stin_bits_uop_vpu_veew,
  input  [6:0]  io_misalign_stin_bits_uop_uopIdx,
  input         io_misalign_stin_bits_uop_robIdx_flag,
  input  [7:0]  io_misalign_stin_bits_uop_robIdx_value,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_selectTime,
  input  [63:0] io_misalign_stin_bits_uop_debugInfo_issueTime,
  input         io_misalign_stin_bits_uop_sqIdx_flag,
  input  [5:0]  io_misalign_stin_bits_uop_sqIdx_value,
  input  [49:0] io_misalign_stin_bits_vaddr,
  input  [15:0] io_misalign_stin_bits_mask,
  input         io_misalign_stin_bits_isvec,
  input         io_misalign_stin_bits_is128bit,
  input         io_misalign_stin_bits_isFinalSplit,
  // ---- misalign 写回 misalign_stout ----
  output        io_misalign_stout_valid,
  output        io_misalign_stout_bits_uop_exceptionVec_3,
  output        io_misalign_stout_bits_uop_exceptionVec_6,
  output        io_misalign_stout_bits_uop_exceptionVec_7,
  output        io_misalign_stout_bits_uop_exceptionVec_15,
  output        io_misalign_stout_bits_uop_exceptionVec_19,
  output        io_misalign_stout_bits_uop_exceptionVec_23,
  output [3:0]  io_misalign_stout_bits_uop_trigger,
  output [47:0] io_misalign_stout_bits_paddr,
  output        io_misalign_stout_bits_nc,
  output        io_misalign_stout_bits_mmio,
  output        io_misalign_stout_bits_memBackTypeMM,
  output        io_misalign_stout_bits_vecActive,
  output        io_misalign_stout_bits_need_rep,
  // ---- DTLB 请求 ----
  output        io_tlb_req_valid,
  output [49:0] io_tlb_req_bits_vaddr,
  output [63:0] io_tlb_req_bits_fullva,
  output        io_tlb_req_bits_checkfullva,
  output [2:0]  io_tlb_req_bits_cmd,
  output        io_tlb_req_bits_hyperinst,
  output        io_tlb_req_bits_debug_robIdx_flag,
  output [7:0]  io_tlb_req_bits_debug_robIdx_value,
  output        io_tlb_req_bits_debug_isFirstIssue,
  // ---- DTLB 响应 ----
  input         io_tlb_resp_valid,
  input  [47:0] io_tlb_resp_bits_paddr_0,
  input  [63:0] io_tlb_resp_bits_gpaddr_0,
  input  [63:0] io_tlb_resp_bits_fullva,
  input  [1:0]  io_tlb_resp_bits_pbmt_0,
  input         io_tlb_resp_bits_miss,
  input         io_tlb_resp_bits_isForVSnonLeafPTE,
  input         io_tlb_resp_bits_excp_0_vaNeedExt,
  input         io_tlb_resp_bits_excp_0_isHyper,
  input         io_tlb_resp_bits_excp_0_gpf_ld,
  input         io_tlb_resp_bits_excp_0_gpf_st,
  input         io_tlb_resp_bits_excp_0_pf_ld,
  input         io_tlb_resp_bits_excp_0_pf_st,
  input         io_tlb_resp_bits_excp_0_af_ld,
  input         io_tlb_resp_bits_excp_0_af_st,
  // ---- DCache（仅探命中的写意图请求，本核只发 req_valid）----
  output        io_dcache_req_valid,
  // ---- PMP 响应 ----
  input         io_pmp_ld,
  input         io_pmp_st,
  input         io_pmp_mmio,
  // ---- 写 StoreQueue 地址 io_lsq ----
  output        io_lsq_valid,
  output        io_lsq_bits_uop_exceptionVec_0,
  output        io_lsq_bits_uop_exceptionVec_1,
  output        io_lsq_bits_uop_exceptionVec_2,
  output        io_lsq_bits_uop_exceptionVec_3,
  output        io_lsq_bits_uop_exceptionVec_4,
  output        io_lsq_bits_uop_exceptionVec_5,
  output        io_lsq_bits_uop_exceptionVec_6,
  output        io_lsq_bits_uop_exceptionVec_7,
  output        io_lsq_bits_uop_exceptionVec_8,
  output        io_lsq_bits_uop_exceptionVec_9,
  output        io_lsq_bits_uop_exceptionVec_10,
  output        io_lsq_bits_uop_exceptionVec_11,
  output        io_lsq_bits_uop_exceptionVec_12,
  output        io_lsq_bits_uop_exceptionVec_13,
  output        io_lsq_bits_uop_exceptionVec_14,
  output        io_lsq_bits_uop_exceptionVec_15,
  output        io_lsq_bits_uop_exceptionVec_16,
  output        io_lsq_bits_uop_exceptionVec_17,
  output        io_lsq_bits_uop_exceptionVec_18,
  output        io_lsq_bits_uop_exceptionVec_19,
  output        io_lsq_bits_uop_exceptionVec_20,
  output        io_lsq_bits_uop_exceptionVec_21,
  output        io_lsq_bits_uop_exceptionVec_22,
  output        io_lsq_bits_uop_exceptionVec_23,
  output [3:0]  io_lsq_bits_uop_trigger,
  output [5:0]  io_lsq_bits_uop_ftqPtr_value,
  output [3:0]  io_lsq_bits_uop_ftqOffset,
  output [8:0]  io_lsq_bits_uop_fuOpType,
  output [6:0]  io_lsq_bits_uop_uopIdx,
  output        io_lsq_bits_uop_robIdx_flag,
  output [7:0]  io_lsq_bits_uop_robIdx_value,
  output [63:0] io_lsq_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_lsq_bits_uop_debugInfo_selectTime,
  output [63:0] io_lsq_bits_uop_debugInfo_issueTime,
  output        io_lsq_bits_uop_sqIdx_flag,
  output [5:0]  io_lsq_bits_uop_sqIdx_value,
  output [49:0] io_lsq_bits_vaddr,
  output [63:0] io_lsq_bits_fullva,
  output        io_lsq_bits_vaNeedExt,
  output [47:0] io_lsq_bits_paddr,
  output [63:0] io_lsq_bits_gpaddr,
  output [15:0] io_lsq_bits_mask,
  output        io_lsq_bits_wlineflag,
  output        io_lsq_bits_miss,
  output        io_lsq_bits_nc,
  output        io_lsq_bits_isHyper,
  output        io_lsq_bits_isForVSnonLeafPTE,
  output        io_lsq_bits_isvec,
  output        io_lsq_bits_isFrmMisAlignBuf,
  output        io_lsq_bits_isMisalign,
  output        io_lsq_bits_misalignWith16Byte,
  output        io_lsq_bits_updateAddrValid,
  // ---- lsq_replenish（s2 补充 mmio/exception/uncache 等）----
  output        io_lsq_replenish_uop_exceptionVec_3,
  output        io_lsq_replenish_uop_exceptionVec_6,
  output        io_lsq_replenish_uop_exceptionVec_15,
  output        io_lsq_replenish_uop_exceptionVec_19,
  output        io_lsq_replenish_uop_exceptionVec_23,
  output [6:0]  io_lsq_replenish_uop_uopIdx,
  output        io_lsq_replenish_uop_robIdx_flag,
  output [7:0]  io_lsq_replenish_uop_robIdx_value,
  output [63:0] io_lsq_replenish_fullva,
  output        io_lsq_replenish_vaNeedExt,
  output [63:0] io_lsq_replenish_gpaddr,
  output        io_lsq_replenish_af,
  output        io_lsq_replenish_mmio,
  output        io_lsq_replenish_memBackTypeMM,
  output        io_lsq_replenish_hasException,
  output        io_lsq_replenish_isHyper,
  output        io_lsq_replenish_isForVSnonLeafPTE,
  output        io_lsq_replenish_isvec,
  output        io_lsq_replenish_updateAddrValid,
  // ---- TLB miss 慢反馈 ----
  output        io_feedback_slow_valid,
  output        io_feedback_slow_bits_hit,
  output        io_feedback_slow_bits_sqIdx_flag,
  output [5:0]  io_feedback_slow_bits_sqIdx_value,
  // ---- 预取请求（本配置仅保留 vaddr 用于 s0 地址选择，valid 已裁剪）----
  input  [49:0] io_prefetch_req_bits_vaddr,
  // ---- st→ld nuke 查询 ----
  output        io_stld_nuke_query_valid,
  output        io_stld_nuke_query_bits_robIdx_flag,
  output [7:0]  io_stld_nuke_query_bits_robIdx_value,
  output [47:0] io_stld_nuke_query_bits_paddr,
  output [15:0] io_stld_nuke_query_bits_mask,
  output [1:0]  io_stld_nuke_query_bits_matchType,
  // ---- 标量写回 ROB io_stout ----
  output        io_stout_valid,
  output        io_stout_bits_uop_exceptionVec_3,
  output        io_stout_bits_uop_exceptionVec_6,
  output        io_stout_bits_uop_exceptionVec_7,
  output        io_stout_bits_uop_exceptionVec_15,
  output        io_stout_bits_uop_exceptionVec_19,
  output        io_stout_bits_uop_exceptionVec_23,
  output [3:0]  io_stout_bits_uop_trigger,
  output        io_stout_bits_uop_robIdx_flag,
  output [7:0]  io_stout_bits_uop_robIdx_value,
  output [63:0] io_stout_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_stout_bits_uop_debugInfo_selectTime,
  output [63:0] io_stout_bits_uop_debugInfo_issueTime,
  output        io_stout_bits_debug_isMMIO,
  output        io_stout_bits_debug_isNCIO,
  // ---- 向量写回 mergeBuffer io_vecstout ----
  output        io_vecstout_valid,
  output [3:0]  io_vecstout_bits_mBIndex,
  output        io_vecstout_bits_hit,
  output [3:0]  io_vecstout_bits_trigger,
  output        io_vecstout_bits_exceptionVec_3,
  output        io_vecstout_bits_exceptionVec_6,
  output        io_vecstout_bits_exceptionVec_7,
  output        io_vecstout_bits_exceptionVec_15,
  output        io_vecstout_bits_exceptionVec_19,
  output        io_vecstout_bits_exceptionVec_23,
  output        io_vecstout_bits_hasException,
  output [63:0] io_vecstout_bits_vaddr,
  output        io_vecstout_bits_vaNeedExt,
  output [63:0] io_vecstout_bits_gpaddr,
  output        io_vecstout_bits_isForVSnonLeafPTE,
  output [7:0]  io_vecstout_bits_vstart,
  output [7:0]  io_vecstout_bits_elemIdx,
  output [15:0] io_vecstout_bits_mask,
  // ---- store mask 早送 sq ----
  output        io_st_mask_out_valid,
  output [5:0]  io_st_mask_out_bits_sqIdx_value,
  output [15:0] io_st_mask_out_bits_mask,
  // ---- 向量发射 vecstin ----
  output        io_vecstin_ready,
  input         io_vecstin_valid,
  input  [63:0] io_vecstin_bits_vaddr,
  input  [49:0] io_vecstin_bits_basevaddr,
  input  [15:0] io_vecstin_bits_mask,
  input  [2:0]  io_vecstin_bits_alignedType,
  input         io_vecstin_bits_vecActive,
  input         io_vecstin_bits_uop_exceptionVec_4,
  input         io_vecstin_bits_uop_exceptionVec_5,
  input         io_vecstin_bits_uop_exceptionVec_6,
  input         io_vecstin_bits_uop_exceptionVec_13,
  input         io_vecstin_bits_uop_exceptionVec_19,
  input         io_vecstin_bits_uop_exceptionVec_21,
  input  [3:0]  io_vecstin_bits_uop_trigger,
  input  [5:0]  io_vecstin_bits_uop_ftqPtr_value,
  input  [3:0]  io_vecstin_bits_uop_ftqOffset,
  input  [8:0]  io_vecstin_bits_uop_fuOpType,
  input  [7:0]  io_vecstin_bits_uop_vpu_vstart,
  input  [1:0]  io_vecstin_bits_uop_vpu_veew,
  input  [6:0]  io_vecstin_bits_uop_uopIdx,
  input         io_vecstin_bits_uop_robIdx_flag,
  input  [7:0]  io_vecstin_bits_uop_robIdx_value,
  input  [63:0] io_vecstin_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_selectTime,
  input  [63:0] io_vecstin_bits_uop_debugInfo_issueTime,
  input         io_vecstin_bits_uop_sqIdx_flag,
  input  [5:0]  io_vecstin_bits_uop_sqIdx_value,
  input  [3:0]  io_vecstin_bits_mBIndex,
  input  [7:0]  io_vecstin_bits_elemIdx,
  // ---- misalignBuffer 入队 misalign_enq ----
  input         io_misalign_enq_req_ready,
  output        io_misalign_enq_req_valid,
  output        io_misalign_enq_req_bits_uop_exceptionVec_0,
  output        io_misalign_enq_req_bits_uop_exceptionVec_1,
  output        io_misalign_enq_req_bits_uop_exceptionVec_2,
  output        io_misalign_enq_req_bits_uop_exceptionVec_4,
  output        io_misalign_enq_req_bits_uop_exceptionVec_5,
  output        io_misalign_enq_req_bits_uop_exceptionVec_8,
  output        io_misalign_enq_req_bits_uop_exceptionVec_9,
  output        io_misalign_enq_req_bits_uop_exceptionVec_10,
  output        io_misalign_enq_req_bits_uop_exceptionVec_11,
  output        io_misalign_enq_req_bits_uop_exceptionVec_12,
  output        io_misalign_enq_req_bits_uop_exceptionVec_13,
  output        io_misalign_enq_req_bits_uop_exceptionVec_14,
  output        io_misalign_enq_req_bits_uop_exceptionVec_16,
  output        io_misalign_enq_req_bits_uop_exceptionVec_17,
  output        io_misalign_enq_req_bits_uop_exceptionVec_18,
  output        io_misalign_enq_req_bits_uop_exceptionVec_19,
  output        io_misalign_enq_req_bits_uop_exceptionVec_20,
  output        io_misalign_enq_req_bits_uop_exceptionVec_21,
  output        io_misalign_enq_req_bits_uop_exceptionVec_22,
  output [3:0]  io_misalign_enq_req_bits_uop_trigger,
  output [5:0]  io_misalign_enq_req_bits_uop_ftqPtr_value,
  output [3:0]  io_misalign_enq_req_bits_uop_ftqOffset,
  output [8:0]  io_misalign_enq_req_bits_uop_fuOpType,
  output [7:0]  io_misalign_enq_req_bits_uop_vpu_vstart,
  output [1:0]  io_misalign_enq_req_bits_uop_vpu_veew,
  output [6:0]  io_misalign_enq_req_bits_uop_uopIdx,
  output        io_misalign_enq_req_bits_uop_robIdx_flag,
  output [7:0]  io_misalign_enq_req_bits_uop_robIdx_value,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_selectTime,
  output [63:0] io_misalign_enq_req_bits_uop_debugInfo_issueTime,
  output        io_misalign_enq_req_bits_uop_sqIdx_flag,
  output [5:0]  io_misalign_enq_req_bits_uop_sqIdx_value,
  output [49:0] io_misalign_enq_req_bits_vaddr,
  output [15:0] io_misalign_enq_req_bits_mask,
  output        io_misalign_enq_req_bits_isvec,
  output [7:0]  io_misalign_enq_req_bits_elemIdx,
  output [2:0]  io_misalign_enq_req_bits_alignedType,
  output [3:0]  io_misalign_enq_req_bits_mbIndex,
  output        io_misalign_enq_revoke,
  // ---- CSR trigger 配置（直通给 MemTrigger 子模块）----
  input  [1:0]  io_fromCsrTrigger_tdataVec_0_matchType,
  input         io_fromCsrTrigger_tdataVec_0_select,
  input         io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_0_action,
  input         io_fromCsrTrigger_tdataVec_0_chain,
  input         io_fromCsrTrigger_tdataVec_0_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]  io_fromCsrTrigger_tdataVec_1_matchType,
  input         io_fromCsrTrigger_tdataVec_1_select,
  input         io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_1_action,
  input         io_fromCsrTrigger_tdataVec_1_chain,
  input         io_fromCsrTrigger_tdataVec_1_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]  io_fromCsrTrigger_tdataVec_2_matchType,
  input         io_fromCsrTrigger_tdataVec_2_select,
  input         io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_2_action,
  input         io_fromCsrTrigger_tdataVec_2_chain,
  input         io_fromCsrTrigger_tdataVec_2_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]  io_fromCsrTrigger_tdataVec_3_matchType,
  input         io_fromCsrTrigger_tdataVec_3_select,
  input         io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]  io_fromCsrTrigger_tdataVec_3_action,
  input         io_fromCsrTrigger_tdataVec_3_chain,
  input         io_fromCsrTrigger_tdataVec_3_store,
  input  [63:0] io_fromCsrTrigger_tdataVec_3_tdata2,
  input         io_fromCsrTrigger_tEnableVec_0,
  input         io_fromCsrTrigger_tEnableVec_1,
  input         io_fromCsrTrigger_tEnableVec_2,
  input         io_fromCsrTrigger_tEnableVec_3,
  input         io_fromCsrTrigger_debugMode,
  input         io_fromCsrTrigger_triggerCanRaiseBpExp,
  output        io_s0_s1_valid
);

  // ===========================================================================
  //  流水级 ready —— 本配置下游恒 ready，故三级 ready 均为常量 1（见文件头）。
  // ===========================================================================
  localparam logic s1_ready = 1'b1;
  localparam logic s2_ready = 1'b1;
  localparam logic s3_ready = 1'b1;

  // redirect 指针打包
  rob_ptr_t redir_robidx;
  assign redir_robidx = '{flag: io_redirect_bits_robIdx_flag,
                          value: io_redirect_bits_robIdx_value};

  // ===========================================================================
  //  stage 0 —— 三源仲裁 + 生成 vaddr/fullva/mask + 对齐/跨16B/cbo + 发 TLB/DCache
  // ===========================================================================
  // 固定优先级 valid 串行屏蔽：misalign > 标量 > 向量（prefetch 本配置失效）。
  logic s0_iss_valid, s0_vec_valid, s0_ma_valid, s0_valid;
  assign s0_iss_valid = io_stin_valid;
  assign s0_vec_valid = io_vecstin_valid;
  assign s0_ma_valid  = io_misalign_stin_valid;
  assign s0_valid     = s0_iss_valid | s0_vec_valid | s0_ma_valid;

  logic s0_use_ma, s0_use_rs, s0_use_vec, s0_use_non_prf;
  assign s0_use_ma      = s0_ma_valid;
  assign s0_use_rs      = s0_iss_valid & ~s0_vec_valid & ~s0_ma_valid;
  assign s0_use_vec     = s0_vec_valid & ~s0_ma_valid;
  assign s0_use_non_prf = s0_use_rs | s0_use_vec | s0_use_ma;

  // —— 选中源的 uop 标量字段（misalign > rs > vec 优先级三选一）——
  // robIdx：用 rob_ptr_t 表达 {flag,value}（替代散标量）。
  rob_ptr_t s0_robidx;
  assign s0_robidx.flag =
      s0_use_ma ? io_misalign_stin_bits_uop_robIdx_flag :
      s0_use_rs ? io_stin_bits_uop_robIdx_flag :
                  (s0_use_vec & io_vecstin_bits_uop_robIdx_flag);
  assign s0_robidx.value =
      s0_use_ma ? io_misalign_stin_bits_uop_robIdx_value :
      s0_use_rs ? io_stin_bits_uop_robIdx_value :
      s0_use_vec ? io_vecstin_bits_uop_robIdx_value : 8'h0;

  logic [5:0] s0_sqidx_value;
  assign s0_sqidx_value =
      s0_use_ma ? io_misalign_stin_bits_uop_sqIdx_value :
      s0_use_rs ? io_stin_bits_uop_sqIdx_value :
      s0_use_vec ? io_vecstin_bits_uop_sqIdx_value : 6'h0;

  logic [8:0] s0_fuOpType;
  assign s0_fuOpType =
      s0_use_ma ? io_misalign_stin_bits_uop_fuOpType :
      s0_use_rs ? io_stin_bits_uop_fuOpType :
      s0_use_vec ? io_vecstin_bits_uop_fuOpType : 9'h0;

  // 标量发射专用字段（仅在 use_rs 时有效，否则 0：用于自算 saddr/mask/cbo）
  logic [6:0] s0_rs_fuOpType7;
  logic [11:0] s0_rs_imm12;
  logic [63:0] s0_rs_src0;
  assign s0_rs_fuOpType7 = s0_use_rs ? io_stin_bits_uop_fuOpType[6:0] : 7'h0;
  assign s0_rs_imm12     = s0_use_rs ? io_stin_bits_uop_imm[11:0]     : 12'h0;
  assign s0_rs_src0      = s0_use_rs ? io_stin_bits_src_0             : 64'h0;

  logic s0_isFirstIssue;
  assign s0_isFirstIssue =
      ~s0_use_ma & ((s0_use_rs & io_stin_bits_isFirstIssue) | s0_use_vec);

  // s0_kill / s0_fire（s0_can_go = s1_ready = 1）
  logic s0_kill, s0_fire;
  assign s0_kill = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                                  s0_robidx, redir_robidx);
  assign s0_fire = s0_valid & ~s0_kill & s1_ready;

  // —— 向量相关 ——
  logic s0_vecActive;
  assign s0_vecActive = ~s0_use_vec | (s0_use_vec & io_vecstin_bits_vecActive);
  logic [2:0] s0_alignedType3; // 向量 alignedType（标量为 0）
  assign s0_alignedType3 = s0_use_vec ? io_vecstin_bits_alignedType : 3'h0;

  // —— cbo 判定（仅标量发射可能是 cbo）——
  logic s0_isCbo, s0_isCbo_nozero;
  assign s0_isCbo        = s0_use_rs & is_cbo_all({2'h0, s0_rs_fuOpType7});
  assign s0_isCbo_nozero = s0_use_rs & is_cbo_nozero({2'h0, s0_rs_fuOpType7});

  // —— 地址 ——
  // 标量 saddr = src0[49:0] + sext(imm12)（向量/misalign 直接给 vaddr）。
  logic [VADDR_BITS-1:0] s0_saddr;
  assign s0_saddr = gen_saddr(s0_rs_src0, s0_rs_imm12);

  // s0_vaddr：misalign > rs(saddr) > vec/prefetch。
  logic [VADDR_BITS-1:0] s0_vaddr;
  assign s0_vaddr =
      s0_use_ma ? io_misalign_stin_bits_vaddr :
      s0_use_rs ? s0_saddr :
      s0_use_vec ? io_vecstin_bits_vaddr[VADDR_BITS-1:0] : io_prefetch_req_bits_vaddr;

  // fullva（64 位完整地址，用于跨页/越界检查）。
  logic [XLEN-1:0] s0_fullva;
  assign s0_fullva =
      s0_use_rs  ? gen_fullva_scalar(s0_rs_src0, s0_rs_imm12) :
      s0_use_vec ? io_vecstin_bits_vaddr :
                   {{(XLEN-VADDR_BITS){1'b0}}, s0_vaddr};

  // —— 对齐 / 跨 16B —— 用 storeunit_pkg 纯函数。
  align_e s0_align;
  assign s0_align = align_e'(s0_use_vec ? s0_alignedType3[1:0] : s0_fuOpType[1:0]);
  logic s0_addr_aligned, s0_cross16, s0_misalignWith16Byte;
  assign s0_addr_aligned       = addr_aligned(s0_align, s0_vaddr) | s0_isCbo;
  assign s0_cross16            = cross16(s0_align, s0_vaddr);
  assign s0_misalignWith16Byte = ~s0_cross16 & ~s0_addr_aligned; // prefetch 本配置失效

  // isMisalign：非预取流且（地址不对齐 或 向量自带 storeAddrMisaligned）
  logic s0_isMisalign;
  assign s0_isMisalign =
      s0_use_non_prf &
      (~s0_addr_aligned |
       (s0_use_vec & io_vecstin_bits_uop_exceptionVec_6 & s0_vecActive));

  // is128bit：misalign 直接给；否则 向量 q-size 或 16B 内错位
  logic s0_is128bit;
  assign s0_is128bit = s0_use_ma ? io_misalign_stin_bits_is128bit
                                 : (s0_alignedType3[2] | s0_misalignWith16Byte);

  // —— 字节 mask ——
  //   跨16B且不对齐 → genBasemask（按 size 长度对齐基 mask，sq 再移位拆分）；
  //   否则 misalign 直给 / 标量 genVWmask128(cbo→全1) / 向量直给 / 其它全1。
  logic [MASK_BITS-1:0] s0_mask;
  always_comb begin
    if (s0_cross16 & ~s0_addr_aligned) begin
      s0_mask = gen_basemask(s0_align);
    end else if (s0_use_ma) begin
      s0_mask = io_misalign_stin_bits_mask;
    end else if (s0_use_rs) begin
      s0_mask = s0_isCbo ? 16'hFFFF : gen_vwmask(s0_saddr, s0_fuOpType[2:0]);
    end else if (s0_use_vec) begin
      s0_mask = io_vecstin_bits_mask;
    end else begin
      s0_mask = 16'hFFFF;
    end
  end

  // —— DTLB 请求 ——
  assign io_tlb_req_valid            = s0_valid;
  assign io_tlb_req_bits_vaddr       = s0_vaddr;
  assign io_tlb_req_bits_fullva      =
      s0_use_rs  ? gen_fullva_scalar(s0_rs_src0, s0_rs_imm12) :
      s0_use_vec ? io_vecstin_bits_vaddr :
                   {{(XLEN-VADDR_BITS){1'b0}},
                    (s0_use_ma ? io_misalign_stin_bits_vaddr : io_prefetch_req_bits_vaddr)};
  assign io_tlb_req_bits_checkfullva = s0_use_rs | s0_use_vec;
  // cbo(非zero) 用读权限，否则写权限。
  assign io_tlb_req_bits_cmd         = s0_isCbo_nozero ? TLB_READ : TLB_WRITE;
  assign io_tlb_req_bits_hyperinst   = is_hsv(s0_fuOpType);
  assign io_tlb_req_bits_debug_robIdx_flag  = s0_use_non_prf & s0_robidx.flag;
  assign io_tlb_req_bits_debug_robIdx_value = s0_use_non_prf ? s0_robidx.value : 8'h0;
  assign io_tlb_req_bits_debug_isFirstIssue = s0_isFirstIssue;

  // —— DCache 探命中写意图（只在真正 fire 时发）——
  assign io_dcache_req_valid = s0_fire;

  // —— store mask 早送 sq —— 标量/向量发射时有效。
  assign io_st_mask_out_valid          = s0_use_rs | s0_use_vec;
  assign io_st_mask_out_bits_sqIdx_value = s0_sqidx_value;
  assign io_st_mask_out_bits_mask        = s0_mask;

  // —— 各源 ready（本配置 s1_ready=1，且各源只在被选中时接受）——
  assign io_stin_ready         = s0_use_rs;
  assign io_vecstin_ready      = s0_use_vec;
  assign io_misalign_stin_ready= s0_use_ma;

  // ===========================================================================
  //  stage 1 —— 收 TLB paddr/异常 + MemTrigger 断点 + 写 lsq + nuke + misalign 入队
  // ===========================================================================
  // s1 流水寄存器 payload（来自 s0 选中流，s0_fire 时锁存）。
  typedef struct packed {
    // uop 标量字段
    logic [3:0]  trigger;       // 来自源（misalign 携带，否则 0/vec）
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
    logic [8:0]  fuOpType;
    logic [7:0]  vpu_vstart;
    logic [1:0]  vpu_veew;
    logic [6:0]  uopIdx;
    rob_ptr_t    robIdx;
    logic [63:0] dbg_enqRsTime, dbg_selectTime, dbg_issueTime;
    sq_ptr_t     sqIdx;
    // 来源携带的异常向量（misalign 全量 / 向量 4/5/13/19/21）
    logic        exc0, exc1, exc2, exc4, exc5, exc8, exc9, exc10, exc11, exc12;
    logic        exc13, exc14, exc16, exc17, exc18, exc19, exc20, exc21, exc22;
    // 地址 / mask / 标志
    logic [VADDR_BITS-1:0] vaddr;
    logic [MASK_BITS-1:0]  mask;
    logic        isvec;
    logic        is128bit;
    logic [7:0]  elemIdx;
    logic [2:0]  alignedType;
    logic [3:0]  mbIndex;
    logic [VADDR_BITS-1:0] vecBaseVaddr;
    logic        vecActive;
    logic        isFirstIssue;
    logic        isFrmMisAlignBuf;
    logic        isMisalign;
    logic        isFinalSplit;
    logic        misalignWith16Byte;
  } s1_payload_t;

  logic        s1_valid;
  s1_payload_t s1;
  // wlineflag 单列为独立寄存器（而非塞进 s1 payload struct）：它是 cbo 的
  // cacheline-flag，下游 sq 据此判定整行操作；独立命名便于 FM 与 golden
  // 同名寄存器 s1_in_wlineflag 逐位配对。
  logic        s1_in_wlineflag;
  // isCbo 同样单列：它既驱动 MemTrigger 黑盒的 io_isCbo 输入，又决定 nuke
  // matchType / s2_isCbo，扇出到多处控制；独立同名（s1_isCbo）便于 FM 配对，
  // 否则塞进 struct 后该位无法按名匹配、且其黑盒下游 trigger 全数失配。
  logic        s1_isCbo;
  // s1 单独打拍的“可控复位初值”寄存器（与 s1 payload 复位签名对齐 golden）
  logic        s1_vecActive_r;   // reset=1
  logic        s1_isvec_r;       // reset=0
  logic        s1_frm_mab_vec;   // reset=0：misalign 源且其本是向量
  logic        s1_mis_align_en_r;        // reset=0：csr hd_misalign_st_enable 打一拍
  logic        s1_toMaBuf_en_r;          // reset=0：同上（golden 拆成两个同源 reg）

  // —— TLB 响应解码 ——
  logic s1_tlb_miss, s1_tlb_hit;
  assign s1_tlb_miss = io_tlb_resp_bits_miss & io_tlb_resp_valid & s1_valid;
  assign s1_tlb_hit  = ~io_tlb_resp_bits_miss & io_tlb_resp_valid & s1_valid;
  logic [1:0] s1_pbmt;
  assign s1_pbmt = s1_tlb_hit ? io_tlb_resp_bits_pbmt_0 : PBMT_NONE;
  logic s1_out_nc, s1_out_mmio;
  assign s1_out_nc   = (s1_pbmt == PBMT_NC);
  assign s1_out_mmio = (s1_pbmt == PBMT_IO);

  // fullva：misalign 源用本地 vaddr 零扩展，否则用 TLB 回的 fullva。
  logic [XLEN-1:0] s1_fullva;
  assign s1_fullva = s1.isFrmMisAlignBuf ? {{(XLEN-VADDR_BITS){1'b0}}, s1.vaddr}
                                         : io_tlb_resp_bits_fullva;

  // s1_kill：被 redirect 冲刷，或（标量/非misalign）TLB miss。
  logic s1_kill, s1_fire;
  assign s1_kill = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                                  s1.robIdx, redir_robidx)
                 | (s1_tlb_miss & ~s1_isvec_r & ~s1.isFrmMisAlignBuf);
  assign s1_fire = s1_valid & ~s1_kill; // s1_can_go = s2_ready = 1

  // —— MemTrigger 子模块（断点匹配，黑盒，与 golden 共用 MemTrigger_3）——
  logic [3:0]  s1_trigger_action;
  logic [VADDR_BITS-1:0] s1_trigger_vaddr;
  MemTrigger_3 storeTrigger (
    .tdataVec_io_fromCsrTrigger_tdataVec_0_matchType (io_fromCsrTrigger_tdataVec_0_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_select    (io_fromCsrTrigger_tdataVec_0_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_timing    (io_fromCsrTrigger_tdataVec_0_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_action    (io_fromCsrTrigger_tdataVec_0_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_chain     (io_fromCsrTrigger_tdataVec_0_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_store     (io_fromCsrTrigger_tdataVec_0_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2    (io_fromCsrTrigger_tdataVec_0_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_matchType (io_fromCsrTrigger_tdataVec_1_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_select    (io_fromCsrTrigger_tdataVec_1_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_timing    (io_fromCsrTrigger_tdataVec_1_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_action    (io_fromCsrTrigger_tdataVec_1_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_chain     (io_fromCsrTrigger_tdataVec_1_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_store     (io_fromCsrTrigger_tdataVec_1_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2    (io_fromCsrTrigger_tdataVec_1_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_matchType (io_fromCsrTrigger_tdataVec_2_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_select    (io_fromCsrTrigger_tdataVec_2_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_timing    (io_fromCsrTrigger_tdataVec_2_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_action    (io_fromCsrTrigger_tdataVec_2_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_chain     (io_fromCsrTrigger_tdataVec_2_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_store     (io_fromCsrTrigger_tdataVec_2_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2    (io_fromCsrTrigger_tdataVec_2_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_matchType (io_fromCsrTrigger_tdataVec_3_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_select    (io_fromCsrTrigger_tdataVec_3_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_timing    (io_fromCsrTrigger_tdataVec_3_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_action    (io_fromCsrTrigger_tdataVec_3_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_chain     (io_fromCsrTrigger_tdataVec_3_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_store     (io_fromCsrTrigger_tdataVec_3_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2    (io_fromCsrTrigger_tdataVec_3_tdata2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_0         (io_fromCsrTrigger_tEnableVec_0),
    .tdataVec_io_fromCsrTrigger_tEnableVec_1         (io_fromCsrTrigger_tEnableVec_1),
    .tdataVec_io_fromCsrTrigger_tEnableVec_2         (io_fromCsrTrigger_tEnableVec_2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_3         (io_fromCsrTrigger_tEnableVec_3),
    .tdataVec_io_fromCsrTrigger_debugMode            (io_fromCsrTrigger_debugMode),
    .tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp (io_fromCsrTrigger_triggerCanRaiseBpExp),
    .tdataVec_io_fromLoadStore_vaddr                 (s1.vaddr),
    .tdataVec_io_fromLoadStore_isVectorUnitStride    (s1.isvec & s1.is128bit),
    .tdataVec_io_fromLoadStore_mask                  (s1.mask),
    .tdataVec_io_toLoadStore_triggerAction           (s1_trigger_action),
    .tdataVec_io_toLoadStore_triggerVaddr            (s1_trigger_vaddr),
    .tdataVec_io_isCbo                               (s1_isCbo)
  );

  // —— trigger 三值规范化（与 TriggerAction 一致）——
  //   action==1 → DebugMode；action 非 0 → breakpoint 异常（exceptionVec[3] = ~(|action)）。
  logic s1_trig_dmode, s1_trig_bp;
  assign s1_trig_dmode = (s1_trigger_action == TRIG_DMODE);
  assign s1_trig_bp    = ~(|s1_trigger_action); // 注：golden 用 ~(|action) 作为 exc3
                                                 // （breakPoint 位）；保持同一布尔驱动。

  // —— s1 异常向量（StaCfg 关心的位，按 Scala 重算）——
  //   storePageFault(15)/storeAccessFault(7)/storeGuestPageFault(23) 取 TLB 异常
  //   （pf/af/gpf 的 st|ld）& s1_vecActive；storeAddrMisaligned(6) = mmio & isMisalign。
  logic s1_exc15, s1_exc7, s1_exc23, s1_exc6;
  assign s1_exc15 = (io_tlb_resp_bits_excp_0_pf_st  | io_tlb_resp_bits_excp_0_pf_ld)  & s1_vecActive_r;
  assign s1_exc7  = (io_tlb_resp_bits_excp_0_af_st  | io_tlb_resp_bits_excp_0_af_ld)  & s1_vecActive_r;
  assign s1_exc23 = (io_tlb_resp_bits_excp_0_gpf_st | io_tlb_resp_bits_excp_0_gpf_ld) & s1_vecActive_r;
  assign s1_exc6  = s1_out_mmio & s1.isMisalign;

  // —— misalign 入队判定 ——
  //   只有标量、非 misalign 来源、非 cbo、确为 16B 内错位、CSR 使能 时入 misalignBuffer。
  logic s1_toMaBufValid;
  assign s1_toMaBufValid =
      s1_valid & ~s1_tlb_miss & ~s1.isFrmMisAlignBuf & ~s1_isCbo &
      s1.isMisalign & ~s1.misalignWith16Byte & s1_toMaBuf_en_r;

  // —— io_lsq（写 StoreQueue 地址）——
  assign io_lsq_valid = s1_valid;
  // 异常向量：被动透传位（misalign 源携带）直接连，主动计算位（断点/页/访问/对齐
  // 错误）单独赋。注：端口为 golden 扁平命名、且关心的位号不连续（跳过 3/6/7/15/23），
  // 不便用单一 generate 循环覆盖，故按位显式罗列；逐字节/多源等可循环逻辑见 pkg 纯函数。
  assign io_lsq_bits_uop_exceptionVec_0  = s1.exc0;
  assign io_lsq_bits_uop_exceptionVec_1  = s1.exc1;
  assign io_lsq_bits_uop_exceptionVec_2  = s1.exc2;
  assign io_lsq_bits_uop_exceptionVec_3  = s1_trig_bp;        // breakPoint
  assign io_lsq_bits_uop_exceptionVec_4  = s1.exc4;
  assign io_lsq_bits_uop_exceptionVec_5  = s1.exc5;
  assign io_lsq_bits_uop_exceptionVec_6  = s1_exc6;           // storeAddrMisaligned
  assign io_lsq_bits_uop_exceptionVec_7  = s1_exc7;           // storeAccessFault
  assign io_lsq_bits_uop_exceptionVec_8  = s1.exc8;
  assign io_lsq_bits_uop_exceptionVec_9  = s1.exc9;
  assign io_lsq_bits_uop_exceptionVec_10 = s1.exc10;
  assign io_lsq_bits_uop_exceptionVec_11 = s1.exc11;
  assign io_lsq_bits_uop_exceptionVec_12 = s1.exc12;
  assign io_lsq_bits_uop_exceptionVec_13 = s1.exc13;
  assign io_lsq_bits_uop_exceptionVec_14 = s1.exc14;
  assign io_lsq_bits_uop_exceptionVec_15 = s1_exc15;          // storePageFault
  assign io_lsq_bits_uop_exceptionVec_16 = s1.exc16;
  assign io_lsq_bits_uop_exceptionVec_17 = s1.exc17;
  assign io_lsq_bits_uop_exceptionVec_18 = s1.exc18;
  assign io_lsq_bits_uop_exceptionVec_19 = s1.exc19;
  assign io_lsq_bits_uop_exceptionVec_20 = s1.exc20;
  assign io_lsq_bits_uop_exceptionVec_21 = s1.exc21;
  assign io_lsq_bits_uop_exceptionVec_22 = s1.exc22;
  assign io_lsq_bits_uop_exceptionVec_23 = s1_exc23;          // storeGuestPageFault
  assign io_lsq_bits_uop_trigger        = s1_trigger_action;
  assign io_lsq_bits_uop_ftqPtr_value   = s1.ftqPtr_value;
  assign io_lsq_bits_uop_ftqOffset      = s1.ftqOffset;
  assign io_lsq_bits_uop_fuOpType       = s1.fuOpType;
  assign io_lsq_bits_uop_uopIdx         = s1.uopIdx;
  assign io_lsq_bits_uop_robIdx_flag    = s1.robIdx.flag;
  assign io_lsq_bits_uop_robIdx_value   = s1.robIdx.value;
  assign io_lsq_bits_uop_debugInfo_enqRsTime  = s1.dbg_enqRsTime;
  assign io_lsq_bits_uop_debugInfo_selectTime = s1.dbg_selectTime;
  assign io_lsq_bits_uop_debugInfo_issueTime  = s1.dbg_issueTime;
  assign io_lsq_bits_uop_sqIdx_flag     = s1.sqIdx.flag;
  assign io_lsq_bits_uop_sqIdx_value    = s1.sqIdx.value;
  assign io_lsq_bits_vaddr   = s1.vaddr;
  assign io_lsq_bits_fullva  = s1_fullva;
  assign io_lsq_bits_vaNeedExt = io_tlb_resp_bits_excp_0_vaNeedExt;
  assign io_lsq_bits_paddr   = io_tlb_resp_bits_paddr_0;
  assign io_lsq_bits_gpaddr  = io_tlb_resp_bits_gpaddr_0;
  assign io_lsq_bits_mask    = s1.mask;
  assign io_lsq_bits_wlineflag = s1_in_wlineflag;
  assign io_lsq_bits_miss    = s1_tlb_miss;
  assign io_lsq_bits_nc      = s1_out_nc;
  assign io_lsq_bits_isHyper = io_tlb_resp_bits_excp_0_isHyper;
  assign io_lsq_bits_isForVSnonLeafPTE = io_tlb_resp_bits_isForVSnonLeafPTE;
  assign io_lsq_bits_isvec   = s1.isvec | s1_frm_mab_vec;
  assign io_lsq_bits_isFrmMisAlignBuf  = s1.isFrmMisAlignBuf;
  assign io_lsq_bits_isMisalign        = s1.isMisalign;
  assign io_lsq_bits_misalignWith16Byte= s1.misalignWith16Byte;
  // updateAddrValid：地址已可信（非错位或16B内错位）且（非misalign来源或最后一拆分）；
  //                  或本拍已产生任一 store 异常（异常也要落地址）。
  assign io_lsq_bits_updateAddrValid =
      ((~s1.isMisalign | s1.misalignWith16Byte) & (~s1.isFrmMisAlignBuf | s1.isFinalSplit))
      | (s1_exc23 | s1.exc19 | s1_exc15 | s1_exc7 | s1_exc6 | s1_trig_bp);

  // —— st→ld nuke 查询 ——
  assign io_stld_nuke_query_valid       = s1_valid & ~s1_tlb_miss;
  assign io_stld_nuke_query_bits_robIdx_flag  = s1.robIdx.flag;
  assign io_stld_nuke_query_bits_robIdx_value = s1.robIdx.value;
  assign io_stld_nuke_query_bits_paddr  = io_tlb_resp_bits_paddr_0;
  assign io_stld_nuke_query_bits_mask   = s1.mask;
  assign io_stld_nuke_query_bits_matchType =
      s1_isCbo ? NUKE_CACHELINE : {1'b0, s1.is128bit};

  // —— misalignBuffer 入队 ——
  assign io_misalign_enq_req_valid = s1_toMaBufValid;
  assign io_misalign_enq_req_bits_uop_exceptionVec_0  = s1.exc0;
  assign io_misalign_enq_req_bits_uop_exceptionVec_1  = s1.exc1;
  assign io_misalign_enq_req_bits_uop_exceptionVec_2  = s1.exc2;
  assign io_misalign_enq_req_bits_uop_exceptionVec_4  = s1.exc4;
  assign io_misalign_enq_req_bits_uop_exceptionVec_5  = s1.exc5;
  assign io_misalign_enq_req_bits_uop_exceptionVec_8  = s1.exc8;
  assign io_misalign_enq_req_bits_uop_exceptionVec_9  = s1.exc9;
  assign io_misalign_enq_req_bits_uop_exceptionVec_10 = s1.exc10;
  assign io_misalign_enq_req_bits_uop_exceptionVec_11 = s1.exc11;
  assign io_misalign_enq_req_bits_uop_exceptionVec_12 = s1.exc12;
  assign io_misalign_enq_req_bits_uop_exceptionVec_13 = s1.exc13;
  assign io_misalign_enq_req_bits_uop_exceptionVec_14 = s1.exc14;
  assign io_misalign_enq_req_bits_uop_exceptionVec_16 = s1.exc16;
  assign io_misalign_enq_req_bits_uop_exceptionVec_17 = s1.exc17;
  assign io_misalign_enq_req_bits_uop_exceptionVec_18 = s1.exc18;
  assign io_misalign_enq_req_bits_uop_exceptionVec_19 = s1.exc19;
  assign io_misalign_enq_req_bits_uop_exceptionVec_20 = s1.exc20;
  assign io_misalign_enq_req_bits_uop_exceptionVec_21 = s1.exc21;
  assign io_misalign_enq_req_bits_uop_exceptionVec_22 = s1.exc22;
  assign io_misalign_enq_req_bits_uop_trigger      = s1.trigger;
  assign io_misalign_enq_req_bits_uop_ftqPtr_value = s1.ftqPtr_value;
  assign io_misalign_enq_req_bits_uop_ftqOffset    = s1.ftqOffset;
  assign io_misalign_enq_req_bits_uop_fuOpType     = s1.fuOpType;
  assign io_misalign_enq_req_bits_uop_vpu_vstart   = s1.vpu_vstart;
  assign io_misalign_enq_req_bits_uop_vpu_veew     = s1.vpu_veew;
  assign io_misalign_enq_req_bits_uop_uopIdx       = s1.uopIdx;
  assign io_misalign_enq_req_bits_uop_robIdx_flag  = s1.robIdx.flag;
  assign io_misalign_enq_req_bits_uop_robIdx_value = s1.robIdx.value;
  assign io_misalign_enq_req_bits_uop_debugInfo_enqRsTime  = s1.dbg_enqRsTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_selectTime = s1.dbg_selectTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_issueTime  = s1.dbg_issueTime;
  assign io_misalign_enq_req_bits_uop_sqIdx_flag   = s1.sqIdx.flag;
  assign io_misalign_enq_req_bits_uop_sqIdx_value  = s1.sqIdx.value;
  assign io_misalign_enq_req_bits_vaddr            = s1.vaddr;
  assign io_misalign_enq_req_bits_mask             = s1.mask;
  assign io_misalign_enq_req_bits_isvec            = s1.isvec;
  assign io_misalign_enq_req_bits_elemIdx          = s1.elemIdx;
  assign io_misalign_enq_req_bits_alignedType      = s1.alignedType;
  assign io_misalign_enq_req_bits_mbIndex          = s1.mbIndex;

  // —— s1→s2 feedback_slow 预算（在 s1 算、s2 发）——
  logic s1_feedback_valid;  // 等价 golden feedback_slow_valid
  assign s1_feedback_valid =
      s1_valid &
      ~rob_need_flush(io_redirect_valid, io_redirect_bits_level, s1.robIdx, redir_robidx) &
      ~s1.isvec & ~s1.isFrmMisAlignBuf;
  // 向量 feedback 用同源寄存器在 s2 合成（见 s2 段）。
  logic s2_vecFeedback_pre; // 等价 golden s2_vecFeedback_REG 的组合输入
  assign s2_vecFeedback_pre =
      ~rob_need_flush(io_redirect_valid, io_redirect_bits_level, s1.robIdx, redir_robidx) &
      ~s1_tlb_miss & s1_valid;

  // s1 mis_align 预算（喂给 s2 的 mis_align 寄存器）。
  logic s1_mis_align_pre;
  assign s1_mis_align_pre =
      s1_valid & ~s1_tlb_miss & ~s1_isCbo & ~s1_out_nc & ~s1_out_mmio &
      s1_mis_align_en_r & s1.isMisalign & ~s1.misalignWith16Byte &
      (|s1_trigger_action) & ~s1_trig_dmode;

  // ===========================================================================
  //  stage 2 —— PMP/PMA + 异常合并 + uncache(mmio/nc) + lsq_replenish + misalign_stout
  // ===========================================================================
  typedef struct packed {
    logic [8:0]  fuOpType;
    logic [1:0]  vpu_veew;
    logic [6:0]  uopIdx;
    rob_ptr_t    robIdx;
    logic [63:0] dbg_enqRsTime, dbg_selectTime, dbg_issueTime;
    logic [XLEN-1:0]       fullva;
    logic        vaNeedExt;
    logic [PADDR_BITS-1:0] paddr;
    logic [63:0] gpaddr;
    logic [MASK_BITS-1:0]  mask;
    logic        nc;
    logic        mmio;
    logic        isHyper;
    logic        isForVSnonLeafPTE;
    logic        isvec;
    logic [7:0]  elemIdx;
    logic [3:0]  mbIndex;
    logic [VADDR_BITS-1:0] vecVaddrOffset;
    logic        vecActive;
    logic        isFrmMisAlignBuf;
    logic        isMisalign;
    logic        isFinalSplit;
    // 入级时已确定的异常向量（被动透传位 + s1 算好的位）
    logic        exc3, exc7, exc15, exc19, exc23;
  } s2_payload_t;

  logic        s2_valid;
  s2_payload_t s2;
  // trigger（断点 action，{0,1,F} 三值）单列为独立寄存器、不进 payload struct：
  // 其高 3 位由 MemTrigger 黑盒同一布尔驱动，独立同名（s2/s3/sx_in_uop_trigger）
  // 才能让 FM 与 golden 逐位配对（打包进 struct 会令高位签名歧义、配对失败）。
  logic [3:0]  s2_in_uop_trigger;
  logic        s2_vecActive_r;  // reset=1
  logic        s2_frm_mab_vec;  // reset=1
  logic [1:0]  s2_pbmt;
  logic        s2_trig_dmode_r; // reset=0
  logic        s2_tlb_hit;
  logic        s2_isCbo;
  // 这 5 个是同一值「上一拍 TLB 命中(~s1_tlb_miss)」的 5 份独立打拍副本，各自只服务
  // 一个 s2 异常/uncache 合并表达式。Scala 里本就是 5 处独立 RegNext(s1_feedback.hit)，
  // 故这里也保 5 份同值寄存器并沿用 golden 同名，使 FM 逐个按名配对（不依赖合并 pass）。
  logic        s2_exception_REG;
  logic        s2_un_misalign_exception_REG;
  logic        s2_mmio_REG;
  logic        s2_actually_uncache_REG;
  logic        s2_out_uop_exceptionVec_7_REG;
  logic        s2_mis_align_r;      // RegEnable(s1_mis_align_pre)
  logic        s2_maBufNack_r;      // RegEnable(s1_toMaBufValid & ~enq.ready)
  logic        s2_need_rep_r;       // RegEnable(s1_tlb_miss)

  // s2 异常合并量之间存在互相引用（s2_exception 依赖 s2_out_af/s2_exc6，
  // 而 s2_exc6 又依赖 s2_out_af）；先声明，再在下方按数据流给出 assign。
  logic        s2_out_af;
  logic        s2_exc6;

  // —— uncache / mmio / 异常合并 ——
  logic s2_isCbo_nozero;
  assign s2_isCbo_nozero = is_cbo_nozero(s2.fuOpType);

  logic s2_pbmt_pma; // pbmt==NONE → 走 PMA，再看 PMP.mmio
  assign s2_pbmt_pma = (s2_pbmt == PBMT_NONE);

  // s2_exception：本拍是否产生（含 trigger debug）任一 StaCfg 异常（& vecActive）。
  logic s2_exception;
  assign s2_exception =
      s2_exception_REG &
      (s2_trig_dmode_r |
       (s2.exc23 | s2.exc19 | s2.exc15 | s2_out_af | s2_exc6 | s2.exc3)) &
      s2_vecActive_r;

  // s2_mmio：pbmt IO 或（PMA 且 PMP.mmio）。
  logic s2_mmio;
  assign s2_mmio = (s2.mmio | (s2_pbmt_pma & io_pmp_mmio)) & s2_mmio_REG;
  logic s2_out_mmio;
  assign s2_out_mmio = s2_mmio & ~s2_exception;

  // s2_actually_uncache：真实物理地址落 uncache 空间（且无访问/页异常时才可信）。
  logic s2_actually_uncache;
  assign s2_actually_uncache =
      s2_tlb_hit &
      ~(s2_vecActive_r & (s2.exc7 | s2.exc15 | s2.exc23)) &
      ((s2_pbmt_pma & io_pmp_mmio) | s2.nc | s2.mmio) &
      s2_actually_uncache_REG;

  // s2_out_af（storeAccessFault 合并）：PMP.st、cbo 读权限、向量/cbo uncache。
  assign s2_out_af =
      (s2.exc7 | io_pmp_st | (io_pmp_ld & s2_isCbo_nozero) |
       ((s2.isvec | s2_isCbo) & s2_actually_uncache & s2_out_uop_exceptionVec_7_REG)) &
      s2_vecActive_r;

  // s2_exc6（storeAddrMisaligned 合并）：uncache 标量错位且无其它非错位异常。
  logic s2_un_misalign_exc; // 等价 golden 用 _GEN（不含 exc6 的异常 OR）
  assign s2_un_misalign_exc =
      s2_un_misalign_exception_REG &
      (s2_trig_dmode_r | (s2.exc23 | s2.exc19 | s2.exc15 | s2_out_af | s2.exc3));
  assign s2_exc6 =
      s2_actually_uncache & ~s2.isvec & (s2.isMisalign | s2.isFrmMisAlignBuf) &
      ~s2_un_misalign_exc;

  // s2_kill / s2_fire
  logic s2_kill, s2_fire;
  assign s2_kill =
      (s2_mmio & ~s2_exception & ~s2.isvec & ~s2.isFrmMisAlignBuf) |
      rob_need_flush(io_redirect_valid, io_redirect_bits_level, s2.robIdx, redir_robidx);
  assign s2_fire = s2_valid & ~s2_kill;

  // s2 mis_align / misalignBuffer nack
  logic s2_mis_align, s2_maBufNack;
  assign s2_mis_align = s2_valid & s2_mis_align_r & ~s2_exception;
  assign s2_maBufNack = ~s2_exception & s2_maBufNack_r;

  // vstart = vecVaddrOffset >> veew
  logic [VADDR_BITS-1:0] s2_vstart_shift;
  assign s2_vstart_shift = s2.vecVaddrOffset >> s2.vpu_veew;

  // —— misalign_stout（misalign 来源在 s2 直接写回 misalignBuffer）——
  assign io_misalign_stout_valid = s2_valid & s2.isFrmMisAlignBuf;
  assign io_misalign_stout_bits_uop_exceptionVec_3  = s2.exc3;
  assign io_misalign_stout_bits_uop_exceptionVec_6  = s2_exc6;
  assign io_misalign_stout_bits_uop_exceptionVec_7  = s2_out_af;
  assign io_misalign_stout_bits_uop_exceptionVec_15 = s2.exc15;
  assign io_misalign_stout_bits_uop_exceptionVec_19 = s2.exc19;
  assign io_misalign_stout_bits_uop_exceptionVec_23 = s2.exc23;
  assign io_misalign_stout_bits_uop_trigger    = s2_in_uop_trigger;
  assign io_misalign_stout_bits_paddr          = s2.paddr;
  assign io_misalign_stout_bits_nc             = s2.nc;
  assign io_misalign_stout_bits_mmio           = s2_out_mmio;
  assign io_misalign_stout_bits_memBackTypeMM  = ~io_pmp_mmio;
  assign io_misalign_stout_bits_vecActive      = s2.vecActive;
  assign io_misalign_stout_bits_need_rep       = s2_need_rep_r;

  // —— lsq_replenish（s2 把 mmio/exception/uncache 等补回 sq）——
  assign io_lsq_replenish_uop_exceptionVec_3  = s2.exc3;
  assign io_lsq_replenish_uop_exceptionVec_6  = s2_exc6;
  assign io_lsq_replenish_uop_exceptionVec_15 = s2.exc15;
  assign io_lsq_replenish_uop_exceptionVec_19 = s2.exc19;
  assign io_lsq_replenish_uop_exceptionVec_23 = s2.exc23;
  assign io_lsq_replenish_uop_uopIdx       = s2.uopIdx;
  assign io_lsq_replenish_uop_robIdx_flag  = s2.robIdx.flag;
  assign io_lsq_replenish_uop_robIdx_value = s2.robIdx.value;
  assign io_lsq_replenish_fullva    = s2.fullva;
  assign io_lsq_replenish_vaNeedExt = s2.vaNeedExt;
  assign io_lsq_replenish_gpaddr    = s2.gpaddr;
  assign io_lsq_replenish_af   = s2_out_af & s2_valid & ~s2_kill;
  assign io_lsq_replenish_mmio = (s2_mmio | s2_isCbo_nozero) & ~s2_exception;
  assign io_lsq_replenish_memBackTypeMM = ~io_pmp_mmio;
  assign io_lsq_replenish_hasException =
      ((s2.exc23 | s2.exc19 | s2.exc15 | s2_out_af | s2_exc6 | s2.exc3) |
       (s2_in_uop_trigger == TRIG_DMODE) | s2_out_af) & s2_valid & ~s2_kill;
  assign io_lsq_replenish_isHyper           = s2.isHyper;
  assign io_lsq_replenish_isForVSnonLeafPTE = s2.isForVSnonLeafPTE;
  assign io_lsq_replenish_isvec   = s2.isvec | s2_frm_mab_vec;
  assign io_lsq_replenish_updateAddrValid =
      (~s2_mis_align & (~s2.isFrmMisAlignBuf | s2.isFinalSplit)) | s2_exception;

  // —— feedback_slow（TLB miss 慢反馈，s1 算/s2 发）——
  logic        fb_valid_r;     // io_feedback_slow_valid_last_REG
  logic        fb_sqIdx_flag_r;
  logic [5:0]  fb_sqIdx_value_r;
  logic        fb_hit_r;
  assign io_feedback_slow_valid          = fb_valid_r;
  assign io_feedback_slow_bits_hit       = fb_hit_r & ~s2_maBufNack;
  assign io_feedback_slow_bits_sqIdx_flag  = fb_sqIdx_flag_r;
  assign io_feedback_slow_bits_sqIdx_value = fb_sqIdx_value_r;

  // misalignBuffer revoke：s2 异常时撤回入队请求。
  assign io_misalign_enq_revoke = s2_exception;

  logic s2_vecFeedback_r; // s2_vecFeedback_REG
  logic s2_vecFeedback;
  assign s2_vecFeedback = s2_vecFeedback_r & ~s2_maBufNack & s2.isvec & ~s2.isFrmMisAlignBuf;

  // ===========================================================================
  //  stage 3 —— 打一拍 + vstart（store 异常/正常进入写回延迟链）
  // ===========================================================================
  typedef struct packed {
    logic [7:0]  vpu_vstart;
    rob_ptr_t    robIdx;
    logic [63:0] dbg_enqRsTime, dbg_selectTime, dbg_issueTime;
    logic [XLEN-1:0] fullva;
    logic        vaNeedExt;
    logic [63:0] gpaddr;
    logic [MASK_BITS-1:0] mask;
    logic        nc, mmio, memBackTypeMM;
    logic        isForVSnonLeafPTE;
    logic        isvec;
    logic [7:0]  elemIdx;
    logic [3:0]  mbIndex;
    logic        vecActive;
    logic        exc3, exc6, exc7, exc15, exc19, exc23;
  } s3_payload_t;

  logic        s3_valid;
  s3_payload_t s3;
  logic [3:0]  s3_in_uop_trigger; // 独立 trigger 寄存器（见 s2 处说明）
  logic        s3_vecFeedback;
  logic        s3_exception;

  logic s3_kill, s3_fire;
  assign s3_kill = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                                  s3.robIdx, redir_robidx);
  assign s3_fire = s3_valid & ~s3_kill; // s3_can_go = s3_ready = 1

  // ===========================================================================
  //  stage x —— 写回延迟链（RAW_DELAY_CYCLES=1：单级寄存器 sx[1]）
  // ===========================================================================
  typedef struct packed {
    logic [7:0]  vpu_vstart;
    rob_ptr_t    robIdx;
    logic [63:0] dbg_enqRsTime, dbg_selectTime, dbg_issueTime;
    logic        debug_isMMIO, debug_isNCIO;
    logic        vecFeedback;
    logic        hasException;
    logic [7:0]  elemIdx;
    logic [3:0]  mbIndex;
    logic [MASK_BITS-1:0]  mask;
    logic [63:0] vaddr;
    logic        vaNeedExt;
    logic [VADDR_BITS-1:0] gpaddr;
    logic        isForVSnonLeafPTE;
    logic        exc3, exc6, exc7, exc15, exc19, exc23;
  } sx_payload_t;

  logic        sx_valid;   // sx_valid_1_r
  sx_payload_t sx;
  logic [3:0]  sx_in_1_r_output_uop_trigger; // 独立 trigger 寄存器（见 s2 处说明）
  logic        sx_is_vec;  // sx_in_vec_1_r

  // sx[1] 的推进：prev_fire（s3 fire 进来）/ cur_kill（被冲刷清空）。
  logic sx_cur_kill, sx_prev_fire;
  assign sx_cur_kill  = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                                       sx.robIdx, redir_robidx);
  assign sx_prev_fire = s3_fire; // = s3_valid & ~s3_kill（s3_ready 链恒通）

  // —— 标量写回 ROB ——
  assign io_stout_valid = sx_valid & ~sx_is_vec;
  assign io_stout_bits_uop_exceptionVec_3  = sx.exc3;
  assign io_stout_bits_uop_exceptionVec_6  = sx.exc6;
  assign io_stout_bits_uop_exceptionVec_7  = sx.exc7;
  assign io_stout_bits_uop_exceptionVec_15 = sx.exc15;
  assign io_stout_bits_uop_exceptionVec_19 = sx.exc19;
  assign io_stout_bits_uop_exceptionVec_23 = sx.exc23;
  assign io_stout_bits_uop_trigger      = sx_in_1_r_output_uop_trigger;
  assign io_stout_bits_uop_robIdx_flag  = sx.robIdx.flag;
  assign io_stout_bits_uop_robIdx_value = sx.robIdx.value;
  assign io_stout_bits_uop_debugInfo_enqRsTime  = sx.dbg_enqRsTime;
  assign io_stout_bits_uop_debugInfo_selectTime = sx.dbg_selectTime;
  assign io_stout_bits_uop_debugInfo_issueTime  = sx.dbg_issueTime;
  assign io_stout_bits_debug_isMMIO = sx.debug_isMMIO;
  assign io_stout_bits_debug_isNCIO = sx.debug_isNCIO;

  // —— 向量写回 mergeBuffer ——
  assign io_vecstout_valid = sx_valid & sx_is_vec;
  assign io_vecstout_bits_mBIndex = sx.mbIndex;
  assign io_vecstout_bits_hit     = sx.vecFeedback;
  assign io_vecstout_bits_trigger = sx_in_1_r_output_uop_trigger;
  assign io_vecstout_bits_exceptionVec_3  = sx.exc3;
  assign io_vecstout_bits_exceptionVec_6  = sx.exc6;
  assign io_vecstout_bits_exceptionVec_7  = sx.exc7;
  assign io_vecstout_bits_exceptionVec_15 = sx.exc15;
  assign io_vecstout_bits_exceptionVec_19 = sx.exc19;
  assign io_vecstout_bits_exceptionVec_23 = sx.exc23;
  assign io_vecstout_bits_hasException = sx.hasException;
  assign io_vecstout_bits_vaddr        = sx.vaddr;
  assign io_vecstout_bits_vaNeedExt    = sx.vaNeedExt;
  assign io_vecstout_bits_gpaddr       = {{(XLEN-VADDR_BITS){1'b0}}, sx.gpaddr};
  assign io_vecstout_bits_isForVSnonLeafPTE = sx.isForVSnonLeafPTE;
  assign io_vecstout_bits_vstart   = sx.vpu_vstart;
  assign io_vecstout_bits_elemIdx  = sx.elemIdx;
  assign io_vecstout_bits_mask     = sx.mask;

  // —— misc ——
  assign io_s0_s1_valid = s0_valid | s1_valid;

  // ===========================================================================
  //  时序：valid 推进 + payload 锁存（valid/异步复位寄存器单独一个 always）
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid          <= 1'b0;
      s1_vecActive_r    <= 1'b1;
      s1_isvec_r        <= 1'b0;
      s1_frm_mab_vec    <= 1'b0;
      s1_mis_align_en_r <= 1'b0;
      s1_toMaBuf_en_r   <= 1'b0;
      s2_valid          <= 1'b0;
      s2_vecActive_r    <= 1'b1;
      s2_frm_mab_vec    <= 1'b1;
      s2_trig_dmode_r   <= 1'b0;
      s2_maBufNack_r    <= 1'b0;
      fb_valid_r        <= 1'b0;
      s3_valid          <= 1'b0;
      sx_valid          <= 1'b0;
    end else begin
      // s1 valid：s0 fire 注入；否则在 fire/kill 时清空。
      s1_valid <= s0_fire | (~(s1_fire | s1_kill) & s1_valid);
      if (s0_fire) begin
        s1_vecActive_r <= s0_vecActive;
        s1_isvec_r     <= s0_use_vec;
        s1_frm_mab_vec <= s0_use_ma & io_misalign_stin_bits_isvec;
      end
      s1_mis_align_en_r <= io_csrCtrl_hd_misalign_st_enable;
      s1_toMaBuf_en_r   <= io_csrCtrl_hd_misalign_st_enable;

      s2_valid <= s1_fire | (~(s2_fire | s2_kill) & s2_valid);
      if (s1_fire) begin
        s2_vecActive_r  <= s1.vecActive;
        s2_frm_mab_vec  <= s1_frm_mab_vec;
        s2_trig_dmode_r <= s1_trig_dmode;
        s2_maBufNack_r  <= s1_toMaBufValid & ~io_misalign_enq_req_ready;
      end
      fb_valid_r <= s1_feedback_valid;

      // s3 valid：仅非 mmio/cbo 或异常、非预取、misalign 放行、非 misalign 来源 进入写回。
      if (s2_fire)
        s3_valid <= (~s2_mmio & ~s2_isCbo | s2_exception) &
                    (~s2_mis_align | (s2.isvec & s2_maBufNack)) &
                    ~s2.isFrmMisAlignBuf;
      else
        s3_valid <= ~(s3_valid & ~s3_kill | s3_kill) & s3_valid;

      // sx[1] valid：s3 fire 进来；cur_kill 清空。
      if (sx_prev_fire | (sx_valid & ~sx_cur_kill) | sx_cur_kill)
        sx_valid <= sx_prev_fire;
    end
  end

  // —— 一组 RegNext(s1_tlb_hit=~tlb_miss) 复制寄存器（每拍更新，无 enable）——
  always_ff @(posedge clock) begin
    s2_exception_REG    <= ~s1_tlb_miss;
    s2_un_misalign_exception_REG   <= ~s1_tlb_miss;
    s2_mmio_REG    <= ~s1_tlb_miss;
    s2_actually_uncache_REG <= ~s1_tlb_miss;
    s2_out_uop_exceptionVec_7_REG      <= ~s1_tlb_miss;
    s2_vecFeedback_r <= s2_vecFeedback_pre;
    if (s1_feedback_valid) begin
      fb_sqIdx_flag_r  <= s1.sqIdx.flag;
      fb_sqIdx_value_r <= s1.sqIdx.value;
      fb_hit_r         <= ~s1_tlb_miss;
    end
  end

  // —— s1 payload 锁存（s0_fire 时从选中流写入）——
  always_ff @(posedge clock) begin
    if (s0_fire) begin
      // 异常向量：misalign 携带全量；向量仅 4/5/13/19/21；标量这些位为 0。
      s1.exc0  <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_0;
      s1.exc1  <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_1;
      s1.exc2  <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_2;
      s1.exc4  <= s0_use_ma ? io_misalign_stin_bits_uop_exceptionVec_4
                            : (s0_use_vec & io_vecstin_bits_uop_exceptionVec_4);
      s1.exc5  <= s0_use_ma ? io_misalign_stin_bits_uop_exceptionVec_5
                            : (s0_use_vec & io_vecstin_bits_uop_exceptionVec_5);
      s1.exc8  <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_8;
      s1.exc9  <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_9;
      s1.exc10 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_10;
      s1.exc11 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_11;
      s1.exc12 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_12;
      s1.exc13 <= s0_use_ma ? io_misalign_stin_bits_uop_exceptionVec_13
                            : (s0_use_vec & io_vecstin_bits_uop_exceptionVec_13);
      s1.exc14 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_14;
      s1.exc16 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_16;
      s1.exc17 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_17;
      s1.exc18 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_18;
      s1.exc19 <= s0_use_ma ? io_misalign_stin_bits_uop_exceptionVec_19
                            : (s0_use_vec & io_vecstin_bits_uop_exceptionVec_19);
      s1.exc20 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_20;
      s1.exc21 <= s0_use_ma ? io_misalign_stin_bits_uop_exceptionVec_21
                            : (s0_use_vec & io_vecstin_bits_uop_exceptionVec_21);
      s1.exc22 <= s0_use_ma & io_misalign_stin_bits_uop_exceptionVec_22;
      // trigger：misalign 携带；标量(或非向量)为 0；否则取向量。
      s1.trigger <= s0_use_ma ? io_misalign_stin_bits_uop_trigger
                  : (s0_use_rs | ~s0_use_vec) ? 4'h0 : io_vecstin_bits_uop_trigger;
      s1.ftqPtr_value <= s0_use_ma ? io_misalign_stin_bits_uop_ftqPtr_value
                       : s0_use_rs ? io_stin_bits_uop_ftqPtr_value
                       : s0_use_vec ? io_vecstin_bits_uop_ftqPtr_value : 6'h0;
      s1.ftqOffset <= s0_use_ma ? io_misalign_stin_bits_uop_ftqOffset
                    : s0_use_rs ? io_stin_bits_uop_ftqOffset
                    : s0_use_vec ? io_vecstin_bits_uop_ftqOffset : 4'h0;
      s1.fuOpType <= s0_fuOpType;
      s1.vpu_vstart <= s0_use_ma ? io_misalign_stin_bits_uop_vpu_vstart
                     : (s0_use_rs | ~s0_use_vec) ? 8'h0 : io_vecstin_bits_uop_vpu_vstart;
      s1.vpu_veew <= s0_use_ma ? io_misalign_stin_bits_uop_vpu_veew
                   : (s0_use_rs | ~s0_use_vec) ? 2'h0 : io_vecstin_bits_uop_vpu_veew;
      s1.uopIdx <= s0_use_ma ? io_misalign_stin_bits_uop_uopIdx
                 : (s0_use_rs | ~s0_use_vec) ? 7'h0 : io_vecstin_bits_uop_uopIdx;
      s1.robIdx <= s0_robidx;
      s1.dbg_enqRsTime <= s0_use_ma ? io_misalign_stin_bits_uop_debugInfo_enqRsTime
                        : s0_use_rs ? io_stin_bits_uop_debugInfo_enqRsTime
                        : s0_use_vec ? io_vecstin_bits_uop_debugInfo_enqRsTime : 64'h0;
      s1.dbg_selectTime <= s0_use_ma ? io_misalign_stin_bits_uop_debugInfo_selectTime
                         : s0_use_rs ? io_stin_bits_uop_debugInfo_selectTime
                         : s0_use_vec ? io_vecstin_bits_uop_debugInfo_selectTime : 64'h0;
      s1.dbg_issueTime <= s0_use_ma ? io_misalign_stin_bits_uop_debugInfo_issueTime
                        : s0_use_rs ? io_stin_bits_uop_debugInfo_issueTime
                        : s0_use_vec ? io_vecstin_bits_uop_debugInfo_issueTime : 64'h0;
      s1.sqIdx.flag <= s0_use_ma ? io_misalign_stin_bits_uop_sqIdx_flag
                     : s0_use_rs ? io_stin_bits_uop_sqIdx_flag
                     : (s0_use_vec & io_vecstin_bits_uop_sqIdx_flag);
      s1.sqIdx.value <= s0_sqidx_value;
      s1.vaddr <= s0_vaddr;
      // mask 落级：跨16B且不对齐时存 base-aligned mask，否则存 s0_mask。
      s1.mask  <= s0_mask;
      s1_in_wlineflag <= s0_use_rs & is_cbo_all({2'h0, s0_rs_fuOpType7});
      s1.isvec <= s0_use_vec;
      s1.is128bit <= s0_use_ma ? io_misalign_stin_bits_is128bit
                               : (s0_alignedType3[2] | s0_misalignWith16Byte);
      s1.elemIdx <= s0_use_vec ? io_vecstin_bits_elemIdx : 8'h0;
      s1.alignedType <= s0_alignedType3;
      s1.mbIndex <= s0_use_vec ? io_vecstin_bits_mBIndex : 4'h0;
      s1.vecBaseVaddr <= s0_use_vec ? io_vecstin_bits_basevaddr : 50'h0;
      s1.vecActive <= s0_vecActive;
      s1.isFirstIssue <= s0_isFirstIssue;
      s1.isFrmMisAlignBuf <= s0_use_ma;
      s1.isMisalign <= s0_isMisalign;
      s1.isFinalSplit <= s0_use_ma & io_misalign_stin_bits_isFinalSplit;
      s1.misalignWith16Byte <= s0_misalignWith16Byte;
      s1_isCbo <= s0_isCbo;
    end
  end

  // —— s2 payload 锁存（s1_fire 时）——
  // vecVaddrOffset：trigger 命中(debug/bp)时用 trigger vaddr - base；否则 va + 首字节偏移 - base。
  logic [VADDR_BITS-1:0] s1_vecVaddrOffset;
  assign s1_vecVaddrOffset =
      (s1_trig_dmode | s1_trig_bp)
        ? VADDR_BITS'(s1_trigger_vaddr - s1.vecBaseVaddr)
        : VADDR_BITS'(VADDR_BITS'(s1.vaddr + {{(VADDR_BITS-4){1'b0}}, first_unmask(s1.mask)})
                      - s1.vecBaseVaddr);

  always_ff @(posedge clock) begin
    if (s1_fire) begin
      s2.exc3  <= s1_trig_bp;        // breakPoint
      s2.exc7  <= s1_exc7;
      s2.exc15 <= s1_exc15;
      s2.exc19 <= s1.exc19;
      s2.exc23 <= s1_exc23;
      s2_in_uop_trigger <= s1_trigger_action;
      s2.fuOpType <= s1.fuOpType;
      s2.vpu_veew <= s1.vpu_veew;
      s2.uopIdx <= s1.uopIdx;
      s2.robIdx <= s1.robIdx;
      s2.dbg_enqRsTime <= s1.dbg_enqRsTime;
      s2.dbg_selectTime <= s1.dbg_selectTime;
      s2.dbg_issueTime <= s1.dbg_issueTime;
      s2.fullva <= s1_fullva;
      s2.vaNeedExt <= io_tlb_resp_bits_excp_0_vaNeedExt;
      s2.paddr <= io_tlb_resp_bits_paddr_0;
      s2.gpaddr <= io_tlb_resp_bits_gpaddr_0;
      s2.mask <= s1.mask;
      s2.nc <= s1_out_nc;
      s2.mmio <= s1_out_mmio;
      s2.isHyper <= io_tlb_resp_bits_excp_0_isHyper;
      s2.isForVSnonLeafPTE <= io_tlb_resp_bits_isForVSnonLeafPTE;
      s2.isvec <= s1.isvec;
      s2.elemIdx <= s1.elemIdx;
      s2.mbIndex <= s1.mbIndex;
      s2.vecVaddrOffset <= s1_vecVaddrOffset;
      s2.vecActive <= s1.vecActive;
      s2.isFrmMisAlignBuf <= s1.isFrmMisAlignBuf;
      s2.isMisalign <= s1.isMisalign;
      s2.isFinalSplit <= s1.isFinalSplit;
      s2_pbmt <= s1_pbmt;
      s2_tlb_hit <= s1_tlb_hit;
      s2_isCbo <= s1_isCbo;
      s2_mis_align_r <= s1_mis_align_pre;
      s2_need_rep_r  <= s1_tlb_miss;
    end
  end

  // —— s3 payload 锁存（s2_fire 时）——
  always_ff @(posedge clock) begin
    if (s2_fire) begin
      s3.exc3  <= s2.exc3;
      s3.exc6  <= s2_exc6;
      s3.exc7  <= s2_out_af;
      s3.exc15 <= s2.exc15;
      s3.exc19 <= s2.exc19;
      s3.exc23 <= s2.exc23;
      s3_in_uop_trigger <= s2_in_uop_trigger;
      s3.vpu_vstart <= s2_vstart_shift[7:0];
      s3.robIdx <= s2.robIdx;
      s3.dbg_enqRsTime <= s2.dbg_enqRsTime;
      s3.dbg_selectTime <= s2.dbg_selectTime;
      s3.dbg_issueTime <= s2.dbg_issueTime;
      s3.fullva <= s2.fullva;
      s3.vaNeedExt <= s2.vaNeedExt;
      s3.gpaddr <= s2.gpaddr;
      s3.mask <= s2.mask;
      s3.nc <= s2.nc;
      s3.mmio <= s2_out_mmio;
      s3.memBackTypeMM <= ~io_pmp_mmio;
      s3.isForVSnonLeafPTE <= s2.isForVSnonLeafPTE;
      s3.isvec <= s2.isvec;
      s3.elemIdx <= s2.elemIdx;
      s3.mbIndex <= s2.mbIndex;
      s3.vecActive <= s2.vecActive;
      s3_vecFeedback <= s2_vecFeedback;
      s3_exception <= s2_exception;
    end
  end

  // —— sx[1] payload 锁存（s3 fire 时）——
  always_ff @(posedge clock) begin
    if (sx_prev_fire) begin
      sx.exc3  <= s3.exc3;
      sx.exc6  <= s3.exc6;
      sx.exc7  <= s3.exc7;
      sx.exc15 <= s3.exc15;
      sx.exc19 <= s3.exc19;
      sx.exc23 <= s3.exc23;
      sx_in_1_r_output_uop_trigger <= s3_in_uop_trigger;
      sx.vpu_vstart <= s3.vpu_vstart;
      sx.robIdx <= s3.robIdx;
      sx.dbg_enqRsTime <= s3.dbg_enqRsTime;
      sx.dbg_selectTime <= s3.dbg_selectTime;
      sx.dbg_issueTime <= s3.dbg_issueTime;
      sx.debug_isMMIO <= s3.mmio;
      sx.debug_isNCIO <= s3.nc & ~s3.memBackTypeMM;
      sx.vecFeedback <= s3_vecFeedback;
      sx.hasException <= s3_exception;
      sx.elemIdx <= s3.elemIdx;
      sx.mbIndex <= s3.mbIndex;
      sx.mask <= s3.mask;
      sx.vaddr <= s3.fullva;
      sx.vaNeedExt <= s3.vaNeedExt;
      sx.gpaddr <= s3.gpaddr[VADDR_BITS-1:0];
      sx.isForVSnonLeafPTE <= s3.isForVSnonLeafPTE;
      sx_is_vec <= s3.isvec;
    end
  end

endmodule
