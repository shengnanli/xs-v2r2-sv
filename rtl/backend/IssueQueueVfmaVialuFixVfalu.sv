// IssueQueueVfmaVialuFixVfalu.sv —— 发射队列 VfmaVialuFixVfalu（golden 同名 wrapper）
// -----------------------------------------------------------------------------
// 调度逻辑全部在 xs_IssueQueue_core.sv（家族共享参数化核）；本文件只做连线：
//   golden 端口表 + golden 同名子模块例化（已签核件）+ 核的数组接口接线 + deqDelay 负载拼包/拆包。
//
// 本变体规模（全部从 G1 golden 量得）：
//   条目 16 = enq 2 + simp 2 + comp 12，发射口 2，源 5，loadDependency 0 路，exuSources 0
//   口 0：接受 FuType 位 [19, 25]；deqDelay 负载 90 个字段 / 1727 位
//   口 1：接受 FuType 位 [24]；deqDelay 负载 91 个字段 / 1729 位
//   子模块：EntriesVfmaVialuFixVfalu×1，FuBusyTableWrite_80×3，FuBusyTableWrite_73×4，FuBusyTableRead_80×3，FuBusyTableRead_73×4，NewAgeDetector×1，AgeDetector_8×1，AgeDetector_15×1
//
// 自动生成：scripts/gen_iq.py —— 勿手改
// =============================================================================
// 本文件导航（共 2917 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L676   §A 子模块输出线
//   L944   §B 核接口
//   L1017  §C 核输入接线：顶层端口 / 条目阵列 / 忙表 / 年龄选择器 -> 核
//   L1224  §D0 口 0 deqDelay 负载拼包/拆包
//   L1409  §D1 口 1 deqDelay 负载拼包/拆包
//   L1596  §E 子模块例化
//   L2617  §F 唤醒出口胶合输入
//   L2626  §G 调度核例化
//   L2729  §H 顶层输出
//
module IssueQueueVfmaVialuFixVfalu(
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  output         io_enq_0_ready,
  input          io_enq_0_valid,
  input  [31:0]  io_enq_0_bits_instr,
  input  [49:0]  io_enq_0_bits_pc,
  input  [9:0]   io_enq_0_bits_foldpc,
  input          io_enq_0_bits_exceptionVec_0,
  input          io_enq_0_bits_exceptionVec_1,
  input          io_enq_0_bits_exceptionVec_2,
  input          io_enq_0_bits_exceptionVec_3,
  input          io_enq_0_bits_exceptionVec_4,
  input          io_enq_0_bits_exceptionVec_5,
  input          io_enq_0_bits_exceptionVec_6,
  input          io_enq_0_bits_exceptionVec_7,
  input          io_enq_0_bits_exceptionVec_8,
  input          io_enq_0_bits_exceptionVec_9,
  input          io_enq_0_bits_exceptionVec_10,
  input          io_enq_0_bits_exceptionVec_11,
  input          io_enq_0_bits_exceptionVec_12,
  input          io_enq_0_bits_exceptionVec_13,
  input          io_enq_0_bits_exceptionVec_14,
  input          io_enq_0_bits_exceptionVec_15,
  input          io_enq_0_bits_exceptionVec_16,
  input          io_enq_0_bits_exceptionVec_17,
  input          io_enq_0_bits_exceptionVec_18,
  input          io_enq_0_bits_exceptionVec_19,
  input          io_enq_0_bits_exceptionVec_20,
  input          io_enq_0_bits_exceptionVec_21,
  input          io_enq_0_bits_exceptionVec_22,
  input          io_enq_0_bits_exceptionVec_23,
  input          io_enq_0_bits_isFetchMalAddr,
  input          io_enq_0_bits_hasException,
  input  [3:0]   io_enq_0_bits_trigger,
  input          io_enq_0_bits_preDecodeInfo_valid,
  input          io_enq_0_bits_preDecodeInfo_isRVC,
  input  [1:0]   io_enq_0_bits_preDecodeInfo_brType,
  input          io_enq_0_bits_preDecodeInfo_isCall,
  input          io_enq_0_bits_preDecodeInfo_isRet,
  input          io_enq_0_bits_pred_taken,
  input          io_enq_0_bits_crossPageIPFFix,
  input          io_enq_0_bits_ftqPtr_flag,
  input  [5:0]   io_enq_0_bits_ftqPtr_value,
  input  [3:0]   io_enq_0_bits_ftqOffset,
  input          io_enq_0_bits_satpFlushFirstFetchFault,
  input  [3:0]   io_enq_0_bits_srcType_0,
  input  [3:0]   io_enq_0_bits_srcType_1,
  input  [3:0]   io_enq_0_bits_srcType_2,
  input  [3:0]   io_enq_0_bits_srcType_3,
  input  [3:0]   io_enq_0_bits_srcType_4,
  input  [5:0]   io_enq_0_bits_ldest,
  input  [34:0]  io_enq_0_bits_fuType,
  input  [8:0]   io_enq_0_bits_fuOpType,
  input          io_enq_0_bits_rfWen,
  input          io_enq_0_bits_fpWen,
  input          io_enq_0_bits_vecWen,
  input          io_enq_0_bits_v0Wen,
  input          io_enq_0_bits_vlWen,
  input          io_enq_0_bits_isXSTrap,
  input          io_enq_0_bits_waitForward,
  input          io_enq_0_bits_blockBackward,
  input          io_enq_0_bits_flushPipe,
  input          io_enq_0_bits_canRobCompress,
  input  [3:0]   io_enq_0_bits_selImm,
  input  [31:0]  io_enq_0_bits_imm,
  input  [1:0]   io_enq_0_bits_fpu_typeTagOut,
  input          io_enq_0_bits_fpu_wflags,
  input  [1:0]   io_enq_0_bits_fpu_typ,
  input  [1:0]   io_enq_0_bits_fpu_fmt,
  input  [2:0]   io_enq_0_bits_fpu_rm,
  input          io_enq_0_bits_vpu_vill,
  input          io_enq_0_bits_vpu_vma,
  input          io_enq_0_bits_vpu_vta,
  input  [1:0]   io_enq_0_bits_vpu_vsew,
  input  [2:0]   io_enq_0_bits_vpu_vlmul,
  input          io_enq_0_bits_vpu_specVill,
  input          io_enq_0_bits_vpu_specVma,
  input          io_enq_0_bits_vpu_specVta,
  input  [1:0]   io_enq_0_bits_vpu_specVsew,
  input  [2:0]   io_enq_0_bits_vpu_specVlmul,
  input          io_enq_0_bits_vpu_vm,
  input  [7:0]   io_enq_0_bits_vpu_vstart,
  input  [2:0]   io_enq_0_bits_vpu_frm,
  input          io_enq_0_bits_vpu_fpu_isFpToVecInst,
  input          io_enq_0_bits_vpu_fpu_isFP32Instr,
  input          io_enq_0_bits_vpu_fpu_isFP64Instr,
  input          io_enq_0_bits_vpu_fpu_isReduction,
  input          io_enq_0_bits_vpu_fpu_isFoldTo1_2,
  input          io_enq_0_bits_vpu_fpu_isFoldTo1_4,
  input          io_enq_0_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_enq_0_bits_vpu_vxrm,
  input  [6:0]   io_enq_0_bits_vpu_vuopIdx,
  input          io_enq_0_bits_vpu_lastUop,
  input  [127:0] io_enq_0_bits_vpu_vmask,
  input  [7:0]   io_enq_0_bits_vpu_vl,
  input  [2:0]   io_enq_0_bits_vpu_nf,
  input  [1:0]   io_enq_0_bits_vpu_veew,
  input          io_enq_0_bits_vpu_isReverse,
  input          io_enq_0_bits_vpu_isExt,
  input          io_enq_0_bits_vpu_isNarrow,
  input          io_enq_0_bits_vpu_isDstMask,
  input          io_enq_0_bits_vpu_isOpMask,
  input          io_enq_0_bits_vpu_isMove,
  input          io_enq_0_bits_vpu_isDependOldVd,
  input          io_enq_0_bits_vpu_isWritePartVd,
  input          io_enq_0_bits_vpu_isVleff,
  input          io_enq_0_bits_vlsInstr,
  input          io_enq_0_bits_wfflags,
  input          io_enq_0_bits_isMove,
  input          io_enq_0_bits_isDropAmocasSta,
  input  [6:0]   io_enq_0_bits_uopIdx,
  input          io_enq_0_bits_isVset,
  input          io_enq_0_bits_firstUop,
  input          io_enq_0_bits_lastUop,
  input  [6:0]   io_enq_0_bits_numUops,
  input  [6:0]   io_enq_0_bits_numWB,
  input  [2:0]   io_enq_0_bits_commitType,
  input          io_enq_0_bits_srcState_0,
  input          io_enq_0_bits_srcState_1,
  input          io_enq_0_bits_srcState_2,
  input          io_enq_0_bits_srcState_3,
  input          io_enq_0_bits_srcState_4,
  input  [7:0]   io_enq_0_bits_psrc_0,
  input  [7:0]   io_enq_0_bits_psrc_1,
  input  [7:0]   io_enq_0_bits_psrc_2,
  input  [7:0]   io_enq_0_bits_psrc_3,
  input  [7:0]   io_enq_0_bits_psrc_4,
  input  [7:0]   io_enq_0_bits_pdest,
  input          io_enq_0_bits_useRegCache_0,
  input          io_enq_0_bits_useRegCache_1,
  input  [4:0]   io_enq_0_bits_regCacheIdx_0,
  input  [4:0]   io_enq_0_bits_regCacheIdx_1,
  input          io_enq_0_bits_robIdx_flag,
  input  [7:0]   io_enq_0_bits_robIdx_value,
  input  [2:0]   io_enq_0_bits_instrSize,
  input          io_enq_0_bits_dirtyFs,
  input          io_enq_0_bits_dirtyVs,
  input  [3:0]   io_enq_0_bits_traceBlockInPipe_itype,
  input  [3:0]   io_enq_0_bits_traceBlockInPipe_iretire,
  input          io_enq_0_bits_traceBlockInPipe_ilastsize,
  input          io_enq_0_bits_eliminatedMove,
  input          io_enq_0_bits_snapshot,
  input          io_enq_0_bits_debugInfo_eliminatedMove,
  input  [63:0]  io_enq_0_bits_debugInfo_renameTime,
  input  [63:0]  io_enq_0_bits_debugInfo_dispatchTime,
  input  [63:0]  io_enq_0_bits_debugInfo_enqRsTime,
  input  [63:0]  io_enq_0_bits_debugInfo_selectTime,
  input  [63:0]  io_enq_0_bits_debugInfo_issueTime,
  input  [63:0]  io_enq_0_bits_debugInfo_writebackTime,
  input  [63:0]  io_enq_0_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_enq_0_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_enq_0_bits_debugInfo_tlbRespTime,
  input  [55:0]  io_enq_0_bits_debug_seqNum_seqNum,
  input  [7:0]   io_enq_0_bits_debug_seqNum_uopIdx,
  input          io_enq_0_bits_storeSetHit,
  input          io_enq_0_bits_waitForRobIdx_flag,
  input  [7:0]   io_enq_0_bits_waitForRobIdx_value,
  input          io_enq_0_bits_loadWaitBit,
  input          io_enq_0_bits_loadWaitStrict,
  input  [4:0]   io_enq_0_bits_ssid,
  input          io_enq_0_bits_lqIdx_flag,
  input  [6:0]   io_enq_0_bits_lqIdx_value,
  input          io_enq_0_bits_sqIdx_flag,
  input  [5:0]   io_enq_0_bits_sqIdx_value,
  input          io_enq_0_bits_singleStep,
  input          io_enq_0_bits_replayInst,
  input  [34:0]  io_enq_0_bits_debug_fuType,
  input          io_enq_0_bits_debug_sim_trig,
  input  [4:0]   io_enq_0_bits_numLsElem,
  output         io_enq_1_ready,
  input          io_enq_1_valid,
  input  [31:0]  io_enq_1_bits_instr,
  input  [49:0]  io_enq_1_bits_pc,
  input  [9:0]   io_enq_1_bits_foldpc,
  input          io_enq_1_bits_exceptionVec_0,
  input          io_enq_1_bits_exceptionVec_1,
  input          io_enq_1_bits_exceptionVec_2,
  input          io_enq_1_bits_exceptionVec_3,
  input          io_enq_1_bits_exceptionVec_4,
  input          io_enq_1_bits_exceptionVec_5,
  input          io_enq_1_bits_exceptionVec_6,
  input          io_enq_1_bits_exceptionVec_7,
  input          io_enq_1_bits_exceptionVec_8,
  input          io_enq_1_bits_exceptionVec_9,
  input          io_enq_1_bits_exceptionVec_10,
  input          io_enq_1_bits_exceptionVec_11,
  input          io_enq_1_bits_exceptionVec_12,
  input          io_enq_1_bits_exceptionVec_13,
  input          io_enq_1_bits_exceptionVec_14,
  input          io_enq_1_bits_exceptionVec_15,
  input          io_enq_1_bits_exceptionVec_16,
  input          io_enq_1_bits_exceptionVec_17,
  input          io_enq_1_bits_exceptionVec_18,
  input          io_enq_1_bits_exceptionVec_19,
  input          io_enq_1_bits_exceptionVec_20,
  input          io_enq_1_bits_exceptionVec_21,
  input          io_enq_1_bits_exceptionVec_22,
  input          io_enq_1_bits_exceptionVec_23,
  input          io_enq_1_bits_isFetchMalAddr,
  input          io_enq_1_bits_hasException,
  input  [3:0]   io_enq_1_bits_trigger,
  input          io_enq_1_bits_preDecodeInfo_valid,
  input          io_enq_1_bits_preDecodeInfo_isRVC,
  input  [1:0]   io_enq_1_bits_preDecodeInfo_brType,
  input          io_enq_1_bits_preDecodeInfo_isCall,
  input          io_enq_1_bits_preDecodeInfo_isRet,
  input          io_enq_1_bits_pred_taken,
  input          io_enq_1_bits_crossPageIPFFix,
  input          io_enq_1_bits_ftqPtr_flag,
  input  [5:0]   io_enq_1_bits_ftqPtr_value,
  input  [3:0]   io_enq_1_bits_ftqOffset,
  input          io_enq_1_bits_satpFlushFirstFetchFault,
  input  [3:0]   io_enq_1_bits_srcType_0,
  input  [3:0]   io_enq_1_bits_srcType_1,
  input  [3:0]   io_enq_1_bits_srcType_2,
  input  [3:0]   io_enq_1_bits_srcType_3,
  input  [3:0]   io_enq_1_bits_srcType_4,
  input  [5:0]   io_enq_1_bits_ldest,
  input  [34:0]  io_enq_1_bits_fuType,
  input  [8:0]   io_enq_1_bits_fuOpType,
  input          io_enq_1_bits_rfWen,
  input          io_enq_1_bits_fpWen,
  input          io_enq_1_bits_vecWen,
  input          io_enq_1_bits_v0Wen,
  input          io_enq_1_bits_vlWen,
  input          io_enq_1_bits_isXSTrap,
  input          io_enq_1_bits_waitForward,
  input          io_enq_1_bits_blockBackward,
  input          io_enq_1_bits_flushPipe,
  input          io_enq_1_bits_canRobCompress,
  input  [3:0]   io_enq_1_bits_selImm,
  input  [31:0]  io_enq_1_bits_imm,
  input  [1:0]   io_enq_1_bits_fpu_typeTagOut,
  input          io_enq_1_bits_fpu_wflags,
  input  [1:0]   io_enq_1_bits_fpu_typ,
  input  [1:0]   io_enq_1_bits_fpu_fmt,
  input  [2:0]   io_enq_1_bits_fpu_rm,
  input          io_enq_1_bits_vpu_vill,
  input          io_enq_1_bits_vpu_vma,
  input          io_enq_1_bits_vpu_vta,
  input  [1:0]   io_enq_1_bits_vpu_vsew,
  input  [2:0]   io_enq_1_bits_vpu_vlmul,
  input          io_enq_1_bits_vpu_specVill,
  input          io_enq_1_bits_vpu_specVma,
  input          io_enq_1_bits_vpu_specVta,
  input  [1:0]   io_enq_1_bits_vpu_specVsew,
  input  [2:0]   io_enq_1_bits_vpu_specVlmul,
  input          io_enq_1_bits_vpu_vm,
  input  [7:0]   io_enq_1_bits_vpu_vstart,
  input  [2:0]   io_enq_1_bits_vpu_frm,
  input          io_enq_1_bits_vpu_fpu_isFpToVecInst,
  input          io_enq_1_bits_vpu_fpu_isFP32Instr,
  input          io_enq_1_bits_vpu_fpu_isFP64Instr,
  input          io_enq_1_bits_vpu_fpu_isReduction,
  input          io_enq_1_bits_vpu_fpu_isFoldTo1_2,
  input          io_enq_1_bits_vpu_fpu_isFoldTo1_4,
  input          io_enq_1_bits_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_enq_1_bits_vpu_vxrm,
  input  [6:0]   io_enq_1_bits_vpu_vuopIdx,
  input          io_enq_1_bits_vpu_lastUop,
  input  [127:0] io_enq_1_bits_vpu_vmask,
  input  [7:0]   io_enq_1_bits_vpu_vl,
  input  [2:0]   io_enq_1_bits_vpu_nf,
  input  [1:0]   io_enq_1_bits_vpu_veew,
  input          io_enq_1_bits_vpu_isReverse,
  input          io_enq_1_bits_vpu_isExt,
  input          io_enq_1_bits_vpu_isNarrow,
  input          io_enq_1_bits_vpu_isDstMask,
  input          io_enq_1_bits_vpu_isOpMask,
  input          io_enq_1_bits_vpu_isMove,
  input          io_enq_1_bits_vpu_isDependOldVd,
  input          io_enq_1_bits_vpu_isWritePartVd,
  input          io_enq_1_bits_vpu_isVleff,
  input          io_enq_1_bits_vlsInstr,
  input          io_enq_1_bits_wfflags,
  input          io_enq_1_bits_isMove,
  input          io_enq_1_bits_isDropAmocasSta,
  input  [6:0]   io_enq_1_bits_uopIdx,
  input          io_enq_1_bits_isVset,
  input          io_enq_1_bits_firstUop,
  input          io_enq_1_bits_lastUop,
  input  [6:0]   io_enq_1_bits_numUops,
  input  [6:0]   io_enq_1_bits_numWB,
  input  [2:0]   io_enq_1_bits_commitType,
  input          io_enq_1_bits_srcState_0,
  input          io_enq_1_bits_srcState_1,
  input          io_enq_1_bits_srcState_2,
  input          io_enq_1_bits_srcState_3,
  input          io_enq_1_bits_srcState_4,
  input  [7:0]   io_enq_1_bits_psrc_0,
  input  [7:0]   io_enq_1_bits_psrc_1,
  input  [7:0]   io_enq_1_bits_psrc_2,
  input  [7:0]   io_enq_1_bits_psrc_3,
  input  [7:0]   io_enq_1_bits_psrc_4,
  input  [7:0]   io_enq_1_bits_pdest,
  input          io_enq_1_bits_useRegCache_0,
  input          io_enq_1_bits_useRegCache_1,
  input  [4:0]   io_enq_1_bits_regCacheIdx_0,
  input  [4:0]   io_enq_1_bits_regCacheIdx_1,
  input          io_enq_1_bits_robIdx_flag,
  input  [7:0]   io_enq_1_bits_robIdx_value,
  input  [2:0]   io_enq_1_bits_instrSize,
  input          io_enq_1_bits_dirtyFs,
  input          io_enq_1_bits_dirtyVs,
  input  [3:0]   io_enq_1_bits_traceBlockInPipe_itype,
  input  [3:0]   io_enq_1_bits_traceBlockInPipe_iretire,
  input          io_enq_1_bits_traceBlockInPipe_ilastsize,
  input          io_enq_1_bits_eliminatedMove,
  input          io_enq_1_bits_snapshot,
  input          io_enq_1_bits_debugInfo_eliminatedMove,
  input  [63:0]  io_enq_1_bits_debugInfo_renameTime,
  input  [63:0]  io_enq_1_bits_debugInfo_dispatchTime,
  input  [63:0]  io_enq_1_bits_debugInfo_enqRsTime,
  input  [63:0]  io_enq_1_bits_debugInfo_selectTime,
  input  [63:0]  io_enq_1_bits_debugInfo_issueTime,
  input  [63:0]  io_enq_1_bits_debugInfo_writebackTime,
  input  [63:0]  io_enq_1_bits_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_enq_1_bits_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_enq_1_bits_debugInfo_tlbRespTime,
  input  [55:0]  io_enq_1_bits_debug_seqNum_seqNum,
  input  [7:0]   io_enq_1_bits_debug_seqNum_uopIdx,
  input          io_enq_1_bits_storeSetHit,
  input          io_enq_1_bits_waitForRobIdx_flag,
  input  [7:0]   io_enq_1_bits_waitForRobIdx_value,
  input          io_enq_1_bits_loadWaitBit,
  input          io_enq_1_bits_loadWaitStrict,
  input  [4:0]   io_enq_1_bits_ssid,
  input          io_enq_1_bits_lqIdx_flag,
  input  [6:0]   io_enq_1_bits_lqIdx_value,
  input          io_enq_1_bits_sqIdx_flag,
  input  [5:0]   io_enq_1_bits_sqIdx_value,
  input          io_enq_1_bits_singleStep,
  input          io_enq_1_bits_replayInst,
  input  [34:0]  io_enq_1_bits_debug_fuType,
  input          io_enq_1_bits_debug_sim_trig,
  input  [4:0]   io_enq_1_bits_numLsElem,
  input          io_og0Resp_0_valid,
  input  [34:0]  io_og0Resp_0_bits_fuType,
  input          io_og0Resp_1_valid,
  input  [34:0]  io_og0Resp_1_bits_fuType,
  input          io_og1Resp_0_valid,
  input          io_og1Resp_1_valid,
  input          io_og2Resp_0_valid,
  input  [1:0]   io_og2Resp_0_bits_resp,
  input          io_og2Resp_1_valid,
  input  [1:0]   io_og2Resp_1_bits_resp,
  input  [2:0]   io_wbBusyTableRead_1_fpWbBusyTable,
  input  [2:0]   io_wbBusyTableRead_1_vfWbBusyTable,
  input  [2:0]   io_wbBusyTableRead_1_v0WbBusyTable,
  input  [4:0]   io_wbBusyTableRead_0_vfWbBusyTable,
  input  [4:0]   io_wbBusyTableRead_0_v0WbBusyTable,
  output [2:0]   io_wbBusyTableWrite_1_fpWbBusyTable,
  output [2:0]   io_wbBusyTableWrite_1_vfWbBusyTable,
  output [2:0]   io_wbBusyTableWrite_1_v0WbBusyTable,
  output [4:0]   io_wbBusyTableWrite_0_vfWbBusyTable,
  output [4:0]   io_wbBusyTableWrite_0_v0WbBusyTable,
  input          io_wakeupFromWB_15_valid,
  input          io_wakeupFromWB_15_bits_vlWen,
  input  [7:0]   io_wakeupFromWB_15_bits_pdest,
  input          io_wakeupFromWB_14_valid,
  input          io_wakeupFromWB_14_bits_vlWen,
  input  [7:0]   io_wakeupFromWB_14_bits_pdest,
  input          io_wakeupFromWB_13_valid,
  input          io_wakeupFromWB_13_bits_vlWen,
  input  [7:0]   io_wakeupFromWB_13_bits_pdest,
  input          io_wakeupFromWB_12_valid,
  input          io_wakeupFromWB_12_bits_vlWen,
  input  [7:0]   io_wakeupFromWB_12_bits_pdest,
  input          io_wakeupFromWB_11_valid,
  input          io_wakeupFromWB_11_bits_v0Wen,
  input  [7:0]   io_wakeupFromWB_11_bits_pdest,
  input          io_wakeupFromWB_10_valid,
  input          io_wakeupFromWB_10_bits_v0Wen,
  input  [7:0]   io_wakeupFromWB_10_bits_pdest,
  input          io_wakeupFromWB_9_valid,
  input          io_wakeupFromWB_9_bits_v0Wen,
  input  [7:0]   io_wakeupFromWB_9_bits_pdest,
  input          io_wakeupFromWB_8_valid,
  input          io_wakeupFromWB_8_bits_v0Wen,
  input  [7:0]   io_wakeupFromWB_8_bits_pdest,
  input          io_wakeupFromWB_7_valid,
  input          io_wakeupFromWB_7_bits_v0Wen,
  input  [7:0]   io_wakeupFromWB_7_bits_pdest,
  input          io_wakeupFromWB_6_valid,
  input          io_wakeupFromWB_6_bits_v0Wen,
  input  [7:0]   io_wakeupFromWB_6_bits_pdest,
  input          io_wakeupFromWB_5_valid,
  input          io_wakeupFromWB_5_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_5_bits_pdest,
  input          io_wakeupFromWB_4_valid,
  input          io_wakeupFromWB_4_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_4_bits_pdest,
  input          io_wakeupFromWB_3_valid,
  input          io_wakeupFromWB_3_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_3_bits_pdest,
  input          io_wakeupFromWB_2_valid,
  input          io_wakeupFromWB_2_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_2_bits_pdest,
  input          io_wakeupFromWB_1_valid,
  input          io_wakeupFromWB_1_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_1_bits_pdest,
  input          io_wakeupFromWB_0_valid,
  input          io_wakeupFromWB_0_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_0_bits_pdest,
  input          io_wakeupFromWBDelayed_15_valid,
  input          io_wakeupFromWBDelayed_15_bits_vlWen,
  input  [7:0]   io_wakeupFromWBDelayed_15_bits_pdest,
  input          io_wakeupFromWBDelayed_14_valid,
  input          io_wakeupFromWBDelayed_14_bits_vlWen,
  input  [7:0]   io_wakeupFromWBDelayed_14_bits_pdest,
  input          io_wakeupFromWBDelayed_13_valid,
  input          io_wakeupFromWBDelayed_13_bits_vlWen,
  input  [7:0]   io_wakeupFromWBDelayed_13_bits_pdest,
  input          io_wakeupFromWBDelayed_12_valid,
  input          io_wakeupFromWBDelayed_12_bits_vlWen,
  input  [7:0]   io_wakeupFromWBDelayed_12_bits_pdest,
  input          io_wakeupFromWBDelayed_11_valid,
  input          io_wakeupFromWBDelayed_11_bits_v0Wen,
  input  [7:0]   io_wakeupFromWBDelayed_11_bits_pdest,
  input          io_wakeupFromWBDelayed_10_valid,
  input          io_wakeupFromWBDelayed_10_bits_v0Wen,
  input  [7:0]   io_wakeupFromWBDelayed_10_bits_pdest,
  input          io_wakeupFromWBDelayed_9_valid,
  input          io_wakeupFromWBDelayed_9_bits_v0Wen,
  input  [7:0]   io_wakeupFromWBDelayed_9_bits_pdest,
  input          io_wakeupFromWBDelayed_8_valid,
  input          io_wakeupFromWBDelayed_8_bits_v0Wen,
  input  [7:0]   io_wakeupFromWBDelayed_8_bits_pdest,
  input          io_wakeupFromWBDelayed_7_valid,
  input          io_wakeupFromWBDelayed_7_bits_v0Wen,
  input  [7:0]   io_wakeupFromWBDelayed_7_bits_pdest,
  input          io_wakeupFromWBDelayed_6_valid,
  input          io_wakeupFromWBDelayed_6_bits_v0Wen,
  input  [7:0]   io_wakeupFromWBDelayed_6_bits_pdest,
  input          io_wakeupFromWBDelayed_5_valid,
  input          io_wakeupFromWBDelayed_5_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_5_bits_pdest,
  input          io_wakeupFromWBDelayed_4_valid,
  input          io_wakeupFromWBDelayed_4_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_4_bits_pdest,
  input          io_wakeupFromWBDelayed_3_valid,
  input          io_wakeupFromWBDelayed_3_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_3_bits_pdest,
  input          io_wakeupFromWBDelayed_2_valid,
  input          io_wakeupFromWBDelayed_2_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_2_bits_pdest,
  input          io_wakeupFromWBDelayed_1_valid,
  input          io_wakeupFromWBDelayed_1_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_1_bits_pdest,
  input          io_wakeupFromWBDelayed_0_valid,
  input          io_wakeupFromWBDelayed_0_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_0_bits_pdest,
  input          io_vlFromIntIsZero,
  input          io_vlFromIntIsVlmax,
  input          io_vlFromVfIsZero,
  input          io_vlFromVfIsVlmax,
  output [4:0]   io_validCntDeqVec_0,
  output [4:0]   io_validCntDeqVec_1,
  input          io_deqDelay_1_ready,
  output         io_deqDelay_1_valid,
  output [6:0]   io_deqDelay_1_bits_rf_4_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_4_0_srcType,
  output [6:0]   io_deqDelay_1_bits_rf_3_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_3_0_srcType,
  output [6:0]   io_deqDelay_1_bits_rf_2_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_2_0_srcType,
  output [6:0]   io_deqDelay_1_bits_rf_1_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_1_0_srcType,
  output [6:0]   io_deqDelay_1_bits_rf_0_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_0_0_srcType,
  output [3:0]   io_deqDelay_1_bits_srcType_0,
  output [3:0]   io_deqDelay_1_bits_srcType_1,
  output [3:0]   io_deqDelay_1_bits_srcType_2,
  output [3:0]   io_deqDelay_1_bits_srcType_3,
  output [3:0]   io_deqDelay_1_bits_srcType_4,
  output [3:0]   io_deqDelay_1_bits_immType,
  output [34:0]  io_deqDelay_1_bits_common_fuType,
  output [8:0]   io_deqDelay_1_bits_common_fuOpType,
  output [127:0] io_deqDelay_1_bits_common_src_0,
  output [127:0] io_deqDelay_1_bits_common_src_1,
  output [127:0] io_deqDelay_1_bits_common_src_2,
  output [127:0] io_deqDelay_1_bits_common_src_3,
  output [127:0] io_deqDelay_1_bits_common_src_4,
  output [63:0]  io_deqDelay_1_bits_common_imm,
  output         io_deqDelay_1_bits_common_robIdx_flag,
  output [7:0]   io_deqDelay_1_bits_common_robIdx_value,
  output [3:0]   io_deqDelay_1_bits_common_iqIdx,
  output         io_deqDelay_1_bits_common_isFirstIssue,
  output [7:0]   io_deqDelay_1_bits_common_pdest,
  output         io_deqDelay_1_bits_common_fpWen,
  output         io_deqDelay_1_bits_common_vecWen,
  output         io_deqDelay_1_bits_common_v0Wen,
  output [1:0]   io_deqDelay_1_bits_common_fpu_typeTagOut,
  output         io_deqDelay_1_bits_common_fpu_wflags,
  output [1:0]   io_deqDelay_1_bits_common_fpu_typ,
  output [1:0]   io_deqDelay_1_bits_common_fpu_fmt,
  output [2:0]   io_deqDelay_1_bits_common_fpu_rm,
  output         io_deqDelay_1_bits_common_vpu_vill,
  output         io_deqDelay_1_bits_common_vpu_vma,
  output         io_deqDelay_1_bits_common_vpu_vta,
  output [1:0]   io_deqDelay_1_bits_common_vpu_vsew,
  output [2:0]   io_deqDelay_1_bits_common_vpu_vlmul,
  output         io_deqDelay_1_bits_common_vpu_specVill,
  output         io_deqDelay_1_bits_common_vpu_specVma,
  output         io_deqDelay_1_bits_common_vpu_specVta,
  output [1:0]   io_deqDelay_1_bits_common_vpu_specVsew,
  output [2:0]   io_deqDelay_1_bits_common_vpu_specVlmul,
  output         io_deqDelay_1_bits_common_vpu_vm,
  output [7:0]   io_deqDelay_1_bits_common_vpu_vstart,
  output [2:0]   io_deqDelay_1_bits_common_vpu_frm,
  output         io_deqDelay_1_bits_common_vpu_fpu_isFpToVecInst,
  output         io_deqDelay_1_bits_common_vpu_fpu_isFP32Instr,
  output         io_deqDelay_1_bits_common_vpu_fpu_isFP64Instr,
  output         io_deqDelay_1_bits_common_vpu_fpu_isReduction,
  output         io_deqDelay_1_bits_common_vpu_fpu_isFoldTo1_2,
  output         io_deqDelay_1_bits_common_vpu_fpu_isFoldTo1_4,
  output         io_deqDelay_1_bits_common_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_deqDelay_1_bits_common_vpu_vxrm,
  output [6:0]   io_deqDelay_1_bits_common_vpu_vuopIdx,
  output         io_deqDelay_1_bits_common_vpu_lastUop,
  output [127:0] io_deqDelay_1_bits_common_vpu_vmask,
  output [7:0]   io_deqDelay_1_bits_common_vpu_vl,
  output [2:0]   io_deqDelay_1_bits_common_vpu_nf,
  output [1:0]   io_deqDelay_1_bits_common_vpu_veew,
  output         io_deqDelay_1_bits_common_vpu_isReverse,
  output         io_deqDelay_1_bits_common_vpu_isExt,
  output         io_deqDelay_1_bits_common_vpu_isNarrow,
  output         io_deqDelay_1_bits_common_vpu_isDstMask,
  output         io_deqDelay_1_bits_common_vpu_isOpMask,
  output         io_deqDelay_1_bits_common_vpu_isMove,
  output         io_deqDelay_1_bits_common_vpu_isDependOldVd,
  output         io_deqDelay_1_bits_common_vpu_isWritePartVd,
  output         io_deqDelay_1_bits_common_vpu_isVleff,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_0_value,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_1_value,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_2_value,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_3_value,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_4_value,
  output         io_deqDelay_1_bits_common_perfDebugInfo_eliminatedMove,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_renameTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_dispatchTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_enqRsTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_selectTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_issueTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_writebackTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_deqDelay_1_bits_common_perfDebugInfo_tlbRespTime,
  output [55:0]  io_deqDelay_1_bits_common_debug_seqNum_seqNum,
  output [7:0]   io_deqDelay_1_bits_common_debug_seqNum_uopIdx,
  output [15:0]  io_deqDelay_1_bits_addrOH,
  input          io_deqDelay_0_ready,
  output         io_deqDelay_0_valid,
  output [6:0]   io_deqDelay_0_bits_rf_4_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_4_0_srcType,
  output [6:0]   io_deqDelay_0_bits_rf_3_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_3_0_srcType,
  output [6:0]   io_deqDelay_0_bits_rf_2_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_2_0_srcType,
  output [6:0]   io_deqDelay_0_bits_rf_1_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_1_0_srcType,
  output [6:0]   io_deqDelay_0_bits_rf_0_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_0_0_srcType,
  output [3:0]   io_deqDelay_0_bits_srcType_0,
  output [3:0]   io_deqDelay_0_bits_srcType_1,
  output [3:0]   io_deqDelay_0_bits_srcType_2,
  output [3:0]   io_deqDelay_0_bits_srcType_3,
  output [3:0]   io_deqDelay_0_bits_srcType_4,
  output [3:0]   io_deqDelay_0_bits_immType,
  output [34:0]  io_deqDelay_0_bits_common_fuType,
  output [8:0]   io_deqDelay_0_bits_common_fuOpType,
  output [127:0] io_deqDelay_0_bits_common_src_0,
  output [127:0] io_deqDelay_0_bits_common_src_1,
  output [127:0] io_deqDelay_0_bits_common_src_2,
  output [127:0] io_deqDelay_0_bits_common_src_3,
  output [127:0] io_deqDelay_0_bits_common_src_4,
  output [63:0]  io_deqDelay_0_bits_common_imm,
  output         io_deqDelay_0_bits_common_robIdx_flag,
  output [7:0]   io_deqDelay_0_bits_common_robIdx_value,
  output [3:0]   io_deqDelay_0_bits_common_iqIdx,
  output         io_deqDelay_0_bits_common_isFirstIssue,
  output [6:0]   io_deqDelay_0_bits_common_pdest,
  output         io_deqDelay_0_bits_common_vecWen,
  output         io_deqDelay_0_bits_common_v0Wen,
  output [1:0]   io_deqDelay_0_bits_common_fpu_typeTagOut,
  output         io_deqDelay_0_bits_common_fpu_wflags,
  output [1:0]   io_deqDelay_0_bits_common_fpu_typ,
  output [1:0]   io_deqDelay_0_bits_common_fpu_fmt,
  output [2:0]   io_deqDelay_0_bits_common_fpu_rm,
  output         io_deqDelay_0_bits_common_vpu_vill,
  output         io_deqDelay_0_bits_common_vpu_vma,
  output         io_deqDelay_0_bits_common_vpu_vta,
  output [1:0]   io_deqDelay_0_bits_common_vpu_vsew,
  output [2:0]   io_deqDelay_0_bits_common_vpu_vlmul,
  output         io_deqDelay_0_bits_common_vpu_specVill,
  output         io_deqDelay_0_bits_common_vpu_specVma,
  output         io_deqDelay_0_bits_common_vpu_specVta,
  output [1:0]   io_deqDelay_0_bits_common_vpu_specVsew,
  output [2:0]   io_deqDelay_0_bits_common_vpu_specVlmul,
  output         io_deqDelay_0_bits_common_vpu_vm,
  output [7:0]   io_deqDelay_0_bits_common_vpu_vstart,
  output [2:0]   io_deqDelay_0_bits_common_vpu_frm,
  output         io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst,
  output         io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr,
  output         io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr,
  output         io_deqDelay_0_bits_common_vpu_fpu_isReduction,
  output         io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2,
  output         io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4,
  output         io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_deqDelay_0_bits_common_vpu_vxrm,
  output [6:0]   io_deqDelay_0_bits_common_vpu_vuopIdx,
  output         io_deqDelay_0_bits_common_vpu_lastUop,
  output [127:0] io_deqDelay_0_bits_common_vpu_vmask,
  output [7:0]   io_deqDelay_0_bits_common_vpu_vl,
  output [2:0]   io_deqDelay_0_bits_common_vpu_nf,
  output [1:0]   io_deqDelay_0_bits_common_vpu_veew,
  output         io_deqDelay_0_bits_common_vpu_isReverse,
  output         io_deqDelay_0_bits_common_vpu_isExt,
  output         io_deqDelay_0_bits_common_vpu_isNarrow,
  output         io_deqDelay_0_bits_common_vpu_isDstMask,
  output         io_deqDelay_0_bits_common_vpu_isOpMask,
  output         io_deqDelay_0_bits_common_vpu_isMove,
  output         io_deqDelay_0_bits_common_vpu_isDependOldVd,
  output         io_deqDelay_0_bits_common_vpu_isWritePartVd,
  output         io_deqDelay_0_bits_common_vpu_isVleff,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_0_value,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_1_value,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_2_value,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_3_value,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_4_value,
  output         io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_renameTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_selectTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_issueTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_writebackTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime,
  output [63:0]  io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime,
  output [55:0]  io_deqDelay_0_bits_common_debug_seqNum_seqNum,
  output [7:0]   io_deqDelay_0_bits_common_debug_seqNum_uopIdx,
  output [15:0]  io_deqDelay_0_bits_addrOH
);

  // ============================================================================
  // §A 子模块输出线（名字 = <实例>_<端口>）
  logic [15:0] entries_io_valid;
  logic [15:0] entries_io_issued;
  logic [15:0] entries_io_canIssue;
  logic [34:0] entries_io_fuType_0;
  logic [34:0] entries_io_fuType_1;
  logic [34:0] entries_io_fuType_2;
  logic [34:0] entries_io_fuType_3;
  logic [34:0] entries_io_fuType_4;
  logic [34:0] entries_io_fuType_5;
  logic [34:0] entries_io_fuType_6;
  logic [34:0] entries_io_fuType_7;
  logic [34:0] entries_io_fuType_8;
  logic [34:0] entries_io_fuType_9;
  logic [34:0] entries_io_fuType_10;
  logic [34:0] entries_io_fuType_11;
  logic [34:0] entries_io_fuType_12;
  logic [34:0] entries_io_fuType_13;
  logic [34:0] entries_io_fuType_14;
  logic [34:0] entries_io_fuType_15;
  logic [3:0] entries_io_dataSources_0_0_value;
  logic [3:0] entries_io_dataSources_0_1_value;
  logic [3:0] entries_io_dataSources_0_2_value;
  logic [3:0] entries_io_dataSources_0_3_value;
  logic [3:0] entries_io_dataSources_0_4_value;
  logic [3:0] entries_io_dataSources_1_0_value;
  logic [3:0] entries_io_dataSources_1_1_value;
  logic [3:0] entries_io_dataSources_1_2_value;
  logic [3:0] entries_io_dataSources_1_3_value;
  logic [3:0] entries_io_dataSources_1_4_value;
  logic [3:0] entries_io_dataSources_2_0_value;
  logic [3:0] entries_io_dataSources_2_1_value;
  logic [3:0] entries_io_dataSources_2_2_value;
  logic [3:0] entries_io_dataSources_2_3_value;
  logic [3:0] entries_io_dataSources_2_4_value;
  logic [3:0] entries_io_dataSources_3_0_value;
  logic [3:0] entries_io_dataSources_3_1_value;
  logic [3:0] entries_io_dataSources_3_2_value;
  logic [3:0] entries_io_dataSources_3_3_value;
  logic [3:0] entries_io_dataSources_3_4_value;
  logic [3:0] entries_io_dataSources_4_0_value;
  logic [3:0] entries_io_dataSources_4_1_value;
  logic [3:0] entries_io_dataSources_4_2_value;
  logic [3:0] entries_io_dataSources_4_3_value;
  logic [3:0] entries_io_dataSources_4_4_value;
  logic [3:0] entries_io_dataSources_5_0_value;
  logic [3:0] entries_io_dataSources_5_1_value;
  logic [3:0] entries_io_dataSources_5_2_value;
  logic [3:0] entries_io_dataSources_5_3_value;
  logic [3:0] entries_io_dataSources_5_4_value;
  logic [3:0] entries_io_dataSources_6_0_value;
  logic [3:0] entries_io_dataSources_6_1_value;
  logic [3:0] entries_io_dataSources_6_2_value;
  logic [3:0] entries_io_dataSources_6_3_value;
  logic [3:0] entries_io_dataSources_6_4_value;
  logic [3:0] entries_io_dataSources_7_0_value;
  logic [3:0] entries_io_dataSources_7_1_value;
  logic [3:0] entries_io_dataSources_7_2_value;
  logic [3:0] entries_io_dataSources_7_3_value;
  logic [3:0] entries_io_dataSources_7_4_value;
  logic [3:0] entries_io_dataSources_8_0_value;
  logic [3:0] entries_io_dataSources_8_1_value;
  logic [3:0] entries_io_dataSources_8_2_value;
  logic [3:0] entries_io_dataSources_8_3_value;
  logic [3:0] entries_io_dataSources_8_4_value;
  logic [3:0] entries_io_dataSources_9_0_value;
  logic [3:0] entries_io_dataSources_9_1_value;
  logic [3:0] entries_io_dataSources_9_2_value;
  logic [3:0] entries_io_dataSources_9_3_value;
  logic [3:0] entries_io_dataSources_9_4_value;
  logic [3:0] entries_io_dataSources_10_0_value;
  logic [3:0] entries_io_dataSources_10_1_value;
  logic [3:0] entries_io_dataSources_10_2_value;
  logic [3:0] entries_io_dataSources_10_3_value;
  logic [3:0] entries_io_dataSources_10_4_value;
  logic [3:0] entries_io_dataSources_11_0_value;
  logic [3:0] entries_io_dataSources_11_1_value;
  logic [3:0] entries_io_dataSources_11_2_value;
  logic [3:0] entries_io_dataSources_11_3_value;
  logic [3:0] entries_io_dataSources_11_4_value;
  logic [3:0] entries_io_dataSources_12_0_value;
  logic [3:0] entries_io_dataSources_12_1_value;
  logic [3:0] entries_io_dataSources_12_2_value;
  logic [3:0] entries_io_dataSources_12_3_value;
  logic [3:0] entries_io_dataSources_12_4_value;
  logic [3:0] entries_io_dataSources_13_0_value;
  logic [3:0] entries_io_dataSources_13_1_value;
  logic [3:0] entries_io_dataSources_13_2_value;
  logic [3:0] entries_io_dataSources_13_3_value;
  logic [3:0] entries_io_dataSources_13_4_value;
  logic [3:0] entries_io_dataSources_14_0_value;
  logic [3:0] entries_io_dataSources_14_1_value;
  logic [3:0] entries_io_dataSources_14_2_value;
  logic [3:0] entries_io_dataSources_14_3_value;
  logic [3:0] entries_io_dataSources_14_4_value;
  logic [3:0] entries_io_dataSources_15_0_value;
  logic [3:0] entries_io_dataSources_15_1_value;
  logic [3:0] entries_io_dataSources_15_2_value;
  logic [3:0] entries_io_dataSources_15_3_value;
  logic [3:0] entries_io_dataSources_15_4_value;
  logic entries_io_isFirstIssue_0;
  logic entries_io_isFirstIssue_1;
  logic entries_io_deqEntry_0_bits_status_robIdx_flag;
  logic [7:0] entries_io_deqEntry_0_bits_status_robIdx_value;
  logic entries_io_deqEntry_0_bits_status_fuType_19;
  logic entries_io_deqEntry_0_bits_status_fuType_24;
  logic entries_io_deqEntry_0_bits_status_fuType_25;
  logic [6:0] entries_io_deqEntry_0_bits_status_srcStatus_0_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_0_srcType;
  logic [6:0] entries_io_deqEntry_0_bits_status_srcStatus_1_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_1_srcType;
  logic [6:0] entries_io_deqEntry_0_bits_status_srcStatus_2_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_2_srcType;
  logic [6:0] entries_io_deqEntry_0_bits_status_srcStatus_3_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_3_srcType;
  logic [6:0] entries_io_deqEntry_0_bits_status_srcStatus_4_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_4_srcType;
  logic [8:0] entries_io_deqEntry_0_bits_payload_fuOpType;
  logic entries_io_deqEntry_0_bits_payload_vecWen;
  logic entries_io_deqEntry_0_bits_payload_v0Wen;
  logic [3:0] entries_io_deqEntry_0_bits_payload_selImm;
  logic [1:0] entries_io_deqEntry_0_bits_payload_fpu_typeTagOut;
  logic entries_io_deqEntry_0_bits_payload_fpu_wflags;
  logic [1:0] entries_io_deqEntry_0_bits_payload_fpu_typ;
  logic [1:0] entries_io_deqEntry_0_bits_payload_fpu_fmt;
  logic [2:0] entries_io_deqEntry_0_bits_payload_fpu_rm;
  logic entries_io_deqEntry_0_bits_payload_vpu_vill;
  logic entries_io_deqEntry_0_bits_payload_vpu_vma;
  logic entries_io_deqEntry_0_bits_payload_vpu_vta;
  logic [1:0] entries_io_deqEntry_0_bits_payload_vpu_vsew;
  logic [2:0] entries_io_deqEntry_0_bits_payload_vpu_vlmul;
  logic entries_io_deqEntry_0_bits_payload_vpu_specVill;
  logic entries_io_deqEntry_0_bits_payload_vpu_specVma;
  logic entries_io_deqEntry_0_bits_payload_vpu_specVta;
  logic [1:0] entries_io_deqEntry_0_bits_payload_vpu_specVsew;
  logic [2:0] entries_io_deqEntry_0_bits_payload_vpu_specVlmul;
  logic entries_io_deqEntry_0_bits_payload_vpu_vm;
  logic [7:0] entries_io_deqEntry_0_bits_payload_vpu_vstart;
  logic [2:0] entries_io_deqEntry_0_bits_payload_vpu_frm;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isReduction;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4;
  logic entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8;
  logic [1:0] entries_io_deqEntry_0_bits_payload_vpu_vxrm;
  logic [127:0] entries_io_deqEntry_0_bits_payload_vpu_vmask;
  logic [7:0] entries_io_deqEntry_0_bits_payload_vpu_vl;
  logic [2:0] entries_io_deqEntry_0_bits_payload_vpu_nf;
  logic [1:0] entries_io_deqEntry_0_bits_payload_vpu_veew;
  logic entries_io_deqEntry_0_bits_payload_vpu_isReverse;
  logic entries_io_deqEntry_0_bits_payload_vpu_isExt;
  logic entries_io_deqEntry_0_bits_payload_vpu_isNarrow;
  logic entries_io_deqEntry_0_bits_payload_vpu_isDstMask;
  logic entries_io_deqEntry_0_bits_payload_vpu_isOpMask;
  logic entries_io_deqEntry_0_bits_payload_vpu_isMove;
  logic entries_io_deqEntry_0_bits_payload_vpu_isDependOldVd;
  logic entries_io_deqEntry_0_bits_payload_vpu_isWritePartVd;
  logic entries_io_deqEntry_0_bits_payload_vpu_isVleff;
  logic [6:0] entries_io_deqEntry_0_bits_payload_uopIdx;
  logic entries_io_deqEntry_0_bits_payload_lastUop;
  logic [7:0] entries_io_deqEntry_0_bits_payload_pdest;
  logic entries_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_renameTime;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_dispatchTime;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_enqRsTime;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_writebackTime;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime;
  logic [63:0] entries_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime;
  logic [55:0] entries_io_deqEntry_0_bits_payload_debug_seqNum_seqNum;
  logic [7:0] entries_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx;
  logic entries_io_deqEntry_1_bits_status_robIdx_flag;
  logic [7:0] entries_io_deqEntry_1_bits_status_robIdx_value;
  logic entries_io_deqEntry_1_bits_status_fuType_19;
  logic entries_io_deqEntry_1_bits_status_fuType_24;
  logic entries_io_deqEntry_1_bits_status_fuType_25;
  logic [6:0] entries_io_deqEntry_1_bits_status_srcStatus_0_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_0_srcType;
  logic [6:0] entries_io_deqEntry_1_bits_status_srcStatus_1_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_1_srcType;
  logic [6:0] entries_io_deqEntry_1_bits_status_srcStatus_2_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_2_srcType;
  logic [6:0] entries_io_deqEntry_1_bits_status_srcStatus_3_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_3_srcType;
  logic [6:0] entries_io_deqEntry_1_bits_status_srcStatus_4_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_4_srcType;
  logic [8:0] entries_io_deqEntry_1_bits_payload_fuOpType;
  logic entries_io_deqEntry_1_bits_payload_fpWen;
  logic entries_io_deqEntry_1_bits_payload_vecWen;
  logic entries_io_deqEntry_1_bits_payload_v0Wen;
  logic [3:0] entries_io_deqEntry_1_bits_payload_selImm;
  logic [1:0] entries_io_deqEntry_1_bits_payload_fpu_typeTagOut;
  logic entries_io_deqEntry_1_bits_payload_fpu_wflags;
  logic [1:0] entries_io_deqEntry_1_bits_payload_fpu_typ;
  logic [1:0] entries_io_deqEntry_1_bits_payload_fpu_fmt;
  logic [2:0] entries_io_deqEntry_1_bits_payload_fpu_rm;
  logic entries_io_deqEntry_1_bits_payload_vpu_vill;
  logic entries_io_deqEntry_1_bits_payload_vpu_vma;
  logic entries_io_deqEntry_1_bits_payload_vpu_vta;
  logic [1:0] entries_io_deqEntry_1_bits_payload_vpu_vsew;
  logic [2:0] entries_io_deqEntry_1_bits_payload_vpu_vlmul;
  logic entries_io_deqEntry_1_bits_payload_vpu_specVill;
  logic entries_io_deqEntry_1_bits_payload_vpu_specVma;
  logic entries_io_deqEntry_1_bits_payload_vpu_specVta;
  logic [1:0] entries_io_deqEntry_1_bits_payload_vpu_specVsew;
  logic [2:0] entries_io_deqEntry_1_bits_payload_vpu_specVlmul;
  logic entries_io_deqEntry_1_bits_payload_vpu_vm;
  logic [7:0] entries_io_deqEntry_1_bits_payload_vpu_vstart;
  logic [2:0] entries_io_deqEntry_1_bits_payload_vpu_frm;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isFpToVecInst;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isFP32Instr;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isFP64Instr;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isReduction;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_2;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_4;
  logic entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_8;
  logic [1:0] entries_io_deqEntry_1_bits_payload_vpu_vxrm;
  logic [127:0] entries_io_deqEntry_1_bits_payload_vpu_vmask;
  logic [7:0] entries_io_deqEntry_1_bits_payload_vpu_vl;
  logic [2:0] entries_io_deqEntry_1_bits_payload_vpu_nf;
  logic [1:0] entries_io_deqEntry_1_bits_payload_vpu_veew;
  logic entries_io_deqEntry_1_bits_payload_vpu_isReverse;
  logic entries_io_deqEntry_1_bits_payload_vpu_isExt;
  logic entries_io_deqEntry_1_bits_payload_vpu_isNarrow;
  logic entries_io_deqEntry_1_bits_payload_vpu_isDstMask;
  logic entries_io_deqEntry_1_bits_payload_vpu_isOpMask;
  logic entries_io_deqEntry_1_bits_payload_vpu_isMove;
  logic entries_io_deqEntry_1_bits_payload_vpu_isDependOldVd;
  logic entries_io_deqEntry_1_bits_payload_vpu_isWritePartVd;
  logic entries_io_deqEntry_1_bits_payload_vpu_isVleff;
  logic [6:0] entries_io_deqEntry_1_bits_payload_uopIdx;
  logic entries_io_deqEntry_1_bits_payload_lastUop;
  logic [7:0] entries_io_deqEntry_1_bits_payload_pdest;
  logic entries_io_deqEntry_1_bits_payload_debugInfo_eliminatedMove;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_renameTime;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_dispatchTime;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_enqRsTime;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_writebackTime;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime;
  logic [63:0] entries_io_deqEntry_1_bits_payload_debugInfo_tlbRespTime;
  logic [55:0] entries_io_deqEntry_1_bits_payload_debug_seqNum_seqNum;
  logic [7:0] entries_io_deqEntry_1_bits_payload_debug_seqNum_uopIdx;
  logic [1:0] entries_io_simpEntryEnqSelVec_0;
  logic [1:0] entries_io_simpEntryEnqSelVec_1;
  logic [11:0] entries_io_compEntryEnqSelVec_0;
  logic [11:0] entries_io_compEntryEnqSelVec_1;
  logic [4:0] fuBusyTableWrite_0_io_out_fuBusyTable;
  logic [2:0] fuBusyTableWrite_1_io_out_fuBusyTable;
  logic [15:0] fuBusyTableRead_0_io_out_fuBusyTableMask;
  logic [15:0] fuBusyTableRead_1_io_out_fuBusyTableMask;
  logic [15:0] fpWbBusyTableRead_1_io_out_fuBusyTableMask;
  logic [15:0] vfWbBusyTableRead_0_io_out_fuBusyTableMask;
  logic [15:0] vfWbBusyTableRead_1_io_out_fuBusyTableMask;
  logic [15:0] v0WbBusyTableRead_0_io_out_fuBusyTableMask;
  logic [15:0] v0WbBusyTableRead_1_io_out_fuBusyTableMask;
  logic [1:0] age_io_out_0;
  logic [1:0] age_io_out_1;
  logic [1:0] age_1_io_out_0;
  logic [1:0] age_1_io_out_1;
  logic [1:0] age_1_io_out_2;
  logic [1:0] age_1_io_out_3;
  logic [11:0] age_2_io_out_0;
  logic [11:0] age_2_io_out_1;

  // ============================================================================
  // §B 核接口（数组形式，下标含义见 xs_IssueQueue_core.sv 端口注释）
  logic             core_enq_valid     [2];
  logic             core_enq_ready     [2];
  logic             core_enq_do        [2];
  logic [3:0]       core_enq_src_type  [2][5];
  logic [7:0]       core_enq_psrc      [2][5];
  logic             core_enq_src_state [2][5];
  logic [1:0]       core_enq_src_ld    [2][5][1];
  logic             core_st_src_state  [2][5];
  logic [3:0]       core_st_data_src   [2][5];
  logic [1:0]       core_st_src_ld     [2][5][1];
  logic [15:0]      core_ent_valid;
  logic [15:0]      core_ent_issued;
  logic [15:0]      core_ent_can_issue;
  logic [34:0]      core_ent_fu_type   [16];
  logic [3:0]       core_ent_data_src  [16][5];
  logic [0:0]       core_ent_exu_src   [16][1];
  logic [1:0]       core_ent_ld_dep    [16][1];
  logic             core_ent_cancel_deq [2];
  logic [15:0]      core_busy_mask     [2][4];
  logic [1:0]       core_age_enq_req   [2];
  logic [1:0]       core_age_simp_req  [4];
  logic [11:0]      core_age_comp_req  [2];
  logic [1:0]       core_age_enq_out   [2];
  logic [1:0]       core_age_simp_out  [4];
  logic [11:0]      core_age_comp_out  [2];
  logic             core_sel_valid     [2];
  logic [15:0]      core_sel_oh        [2];
  logic             core_simp_oldest_valid [2];
  logic             core_comp_oldest_valid [2];
  logic             core_deq_valid     [2];
  logic [3:0]       core_deq_iq_idx    [2];
  logic [3:0]       core_deq_data_src  [2][5];
  logic [0:0]       core_deq_exu_src   [2][1];
  logic [1:0]       core_deq_ld_dep    [2][1];
  logic [63:0]      core_deq_select_time [2];
  logic [63:0]      core_deq_issue_time  [2];
  logic [1726:0]    core_deq0_payload;
  logic [1728:0]    core_deq1_payload;
  logic             core_dly_valid     [2];
  logic [1726:0]    core_dly0_payload;
  logic [1728:0]    core_dly1_payload;
  logic             core_dly_ready     [2];
  logic [4:0]       core_valid_cnt     [2];
  logic [34:0]      core_wk_enq_fu_type;
  logic [0:0]       core_wk_enq_lat;
  logic             core_wk_og1_valid;
  logic [1:0]       core_wk_og1_resp;
  logic             core_wk_og1_fail;
  logic             core_wk_deq_valid;
  logic [34:0]      core_wk_deq_fu_type;
  logic [4:0]       core_wk_deq_wen;
  logic [4:0]       core_wk_out_wen;
  logic             core_wk_is0lat;
  logic [7:0]       core_enq_lq_idx    [2];
  logic             core_enq_is_vleff  [2];
  logic [7:0]       core_lq_deq_ptr;
  logic             core_st_blocked    [2];
  logic [4:0]       core_deq_wen       [2];
  logic [4:0]       core_deq_wen_valid [2];
  logic             core_ldw_valid;
  logic             core_ldw_rf_wen;
  logic             core_ldw_fp_wen;
  logic [7:0]       core_ldw_pdest;
  logic             core_ldw_q_valid;
  logic             core_ldw_q_rf_wen;
  logic             core_ldw_q_fp_wen;
  logic [7:0]       core_ldw_q_pdest;
  logic             core_ldw_q_rf_wen_copy [6];
  logic             core_ldw_q_fp_wen_copy [6];
  logic [7:0]       core_ldw_q_pdest_copy  [6];

  // ============================================================================
  // §C 核输入接线：顶层端口 / 条目阵列 / 忙表 / 年龄选择器 -> 核
  assign core_enq_valid[0] = io_enq_0_valid;
  assign core_enq_src_type[0][0] = io_enq_0_bits_srcType_0;
  assign core_enq_psrc[0][0] = io_enq_0_bits_psrc_0;
  assign core_enq_src_state[0][0] = io_enq_0_bits_srcState_0;
  assign core_enq_src_ld[0][0][0] = 2'h0;
  assign core_enq_src_type[0][1] = io_enq_0_bits_srcType_1;
  assign core_enq_psrc[0][1] = io_enq_0_bits_psrc_1;
  assign core_enq_src_state[0][1] = io_enq_0_bits_srcState_1;
  assign core_enq_src_ld[0][1][0] = 2'h0;
  assign core_enq_src_type[0][2] = io_enq_0_bits_srcType_2;
  assign core_enq_psrc[0][2] = io_enq_0_bits_psrc_2;
  assign core_enq_src_state[0][2] = io_enq_0_bits_srcState_2;
  assign core_enq_src_ld[0][2][0] = 2'h0;
  assign core_enq_src_type[0][3] = io_enq_0_bits_srcType_3;
  assign core_enq_psrc[0][3] = io_enq_0_bits_psrc_3;
  assign core_enq_src_state[0][3] = io_enq_0_bits_srcState_3;
  assign core_enq_src_ld[0][3][0] = 2'h0;
  assign core_enq_src_type[0][4] = io_enq_0_bits_srcType_4;
  assign core_enq_psrc[0][4] = io_enq_0_bits_psrc_4;
  assign core_enq_src_state[0][4] = io_enq_0_bits_srcState_4;
  assign core_enq_src_ld[0][4][0] = 2'h0;
  assign core_enq_valid[1] = io_enq_1_valid;
  assign core_enq_src_type[1][0] = io_enq_1_bits_srcType_0;
  assign core_enq_psrc[1][0] = io_enq_1_bits_psrc_0;
  assign core_enq_src_state[1][0] = io_enq_1_bits_srcState_0;
  assign core_enq_src_ld[1][0][0] = 2'h0;
  assign core_enq_src_type[1][1] = io_enq_1_bits_srcType_1;
  assign core_enq_psrc[1][1] = io_enq_1_bits_psrc_1;
  assign core_enq_src_state[1][1] = io_enq_1_bits_srcState_1;
  assign core_enq_src_ld[1][1][0] = 2'h0;
  assign core_enq_src_type[1][2] = io_enq_1_bits_srcType_2;
  assign core_enq_psrc[1][2] = io_enq_1_bits_psrc_2;
  assign core_enq_src_state[1][2] = io_enq_1_bits_srcState_2;
  assign core_enq_src_ld[1][2][0] = 2'h0;
  assign core_enq_src_type[1][3] = io_enq_1_bits_srcType_3;
  assign core_enq_psrc[1][3] = io_enq_1_bits_psrc_3;
  assign core_enq_src_state[1][3] = io_enq_1_bits_srcState_3;
  assign core_enq_src_ld[1][3][0] = 2'h0;
  assign core_enq_src_type[1][4] = io_enq_1_bits_srcType_4;
  assign core_enq_psrc[1][4] = io_enq_1_bits_psrc_4;
  assign core_enq_src_state[1][4] = io_enq_1_bits_srcState_4;
  assign core_enq_src_ld[1][4][0] = 2'h0;
  assign core_ent_valid = entries_io_valid;
  assign core_ent_issued = entries_io_issued;
  assign core_ent_can_issue = entries_io_canIssue;
  assign core_ent_fu_type[0] = entries_io_fuType_0;
  assign core_ent_data_src[0][0] = entries_io_dataSources_0_0_value;
  assign core_ent_data_src[0][1] = entries_io_dataSources_0_1_value;
  assign core_ent_data_src[0][2] = entries_io_dataSources_0_2_value;
  assign core_ent_data_src[0][3] = entries_io_dataSources_0_3_value;
  assign core_ent_data_src[0][4] = entries_io_dataSources_0_4_value;
  assign core_ent_exu_src[0][0] = '0;
  assign core_ent_ld_dep[0][0] = 2'h0;
  assign core_ent_fu_type[1] = entries_io_fuType_1;
  assign core_ent_data_src[1][0] = entries_io_dataSources_1_0_value;
  assign core_ent_data_src[1][1] = entries_io_dataSources_1_1_value;
  assign core_ent_data_src[1][2] = entries_io_dataSources_1_2_value;
  assign core_ent_data_src[1][3] = entries_io_dataSources_1_3_value;
  assign core_ent_data_src[1][4] = entries_io_dataSources_1_4_value;
  assign core_ent_exu_src[1][0] = '0;
  assign core_ent_ld_dep[1][0] = 2'h0;
  assign core_ent_fu_type[2] = entries_io_fuType_2;
  assign core_ent_data_src[2][0] = entries_io_dataSources_2_0_value;
  assign core_ent_data_src[2][1] = entries_io_dataSources_2_1_value;
  assign core_ent_data_src[2][2] = entries_io_dataSources_2_2_value;
  assign core_ent_data_src[2][3] = entries_io_dataSources_2_3_value;
  assign core_ent_data_src[2][4] = entries_io_dataSources_2_4_value;
  assign core_ent_exu_src[2][0] = '0;
  assign core_ent_ld_dep[2][0] = 2'h0;
  assign core_ent_fu_type[3] = entries_io_fuType_3;
  assign core_ent_data_src[3][0] = entries_io_dataSources_3_0_value;
  assign core_ent_data_src[3][1] = entries_io_dataSources_3_1_value;
  assign core_ent_data_src[3][2] = entries_io_dataSources_3_2_value;
  assign core_ent_data_src[3][3] = entries_io_dataSources_3_3_value;
  assign core_ent_data_src[3][4] = entries_io_dataSources_3_4_value;
  assign core_ent_exu_src[3][0] = '0;
  assign core_ent_ld_dep[3][0] = 2'h0;
  assign core_ent_fu_type[4] = entries_io_fuType_4;
  assign core_ent_data_src[4][0] = entries_io_dataSources_4_0_value;
  assign core_ent_data_src[4][1] = entries_io_dataSources_4_1_value;
  assign core_ent_data_src[4][2] = entries_io_dataSources_4_2_value;
  assign core_ent_data_src[4][3] = entries_io_dataSources_4_3_value;
  assign core_ent_data_src[4][4] = entries_io_dataSources_4_4_value;
  assign core_ent_exu_src[4][0] = '0;
  assign core_ent_ld_dep[4][0] = 2'h0;
  assign core_ent_fu_type[5] = entries_io_fuType_5;
  assign core_ent_data_src[5][0] = entries_io_dataSources_5_0_value;
  assign core_ent_data_src[5][1] = entries_io_dataSources_5_1_value;
  assign core_ent_data_src[5][2] = entries_io_dataSources_5_2_value;
  assign core_ent_data_src[5][3] = entries_io_dataSources_5_3_value;
  assign core_ent_data_src[5][4] = entries_io_dataSources_5_4_value;
  assign core_ent_exu_src[5][0] = '0;
  assign core_ent_ld_dep[5][0] = 2'h0;
  assign core_ent_fu_type[6] = entries_io_fuType_6;
  assign core_ent_data_src[6][0] = entries_io_dataSources_6_0_value;
  assign core_ent_data_src[6][1] = entries_io_dataSources_6_1_value;
  assign core_ent_data_src[6][2] = entries_io_dataSources_6_2_value;
  assign core_ent_data_src[6][3] = entries_io_dataSources_6_3_value;
  assign core_ent_data_src[6][4] = entries_io_dataSources_6_4_value;
  assign core_ent_exu_src[6][0] = '0;
  assign core_ent_ld_dep[6][0] = 2'h0;
  assign core_ent_fu_type[7] = entries_io_fuType_7;
  assign core_ent_data_src[7][0] = entries_io_dataSources_7_0_value;
  assign core_ent_data_src[7][1] = entries_io_dataSources_7_1_value;
  assign core_ent_data_src[7][2] = entries_io_dataSources_7_2_value;
  assign core_ent_data_src[7][3] = entries_io_dataSources_7_3_value;
  assign core_ent_data_src[7][4] = entries_io_dataSources_7_4_value;
  assign core_ent_exu_src[7][0] = '0;
  assign core_ent_ld_dep[7][0] = 2'h0;
  assign core_ent_fu_type[8] = entries_io_fuType_8;
  assign core_ent_data_src[8][0] = entries_io_dataSources_8_0_value;
  assign core_ent_data_src[8][1] = entries_io_dataSources_8_1_value;
  assign core_ent_data_src[8][2] = entries_io_dataSources_8_2_value;
  assign core_ent_data_src[8][3] = entries_io_dataSources_8_3_value;
  assign core_ent_data_src[8][4] = entries_io_dataSources_8_4_value;
  assign core_ent_exu_src[8][0] = '0;
  assign core_ent_ld_dep[8][0] = 2'h0;
  assign core_ent_fu_type[9] = entries_io_fuType_9;
  assign core_ent_data_src[9][0] = entries_io_dataSources_9_0_value;
  assign core_ent_data_src[9][1] = entries_io_dataSources_9_1_value;
  assign core_ent_data_src[9][2] = entries_io_dataSources_9_2_value;
  assign core_ent_data_src[9][3] = entries_io_dataSources_9_3_value;
  assign core_ent_data_src[9][4] = entries_io_dataSources_9_4_value;
  assign core_ent_exu_src[9][0] = '0;
  assign core_ent_ld_dep[9][0] = 2'h0;
  assign core_ent_fu_type[10] = entries_io_fuType_10;
  assign core_ent_data_src[10][0] = entries_io_dataSources_10_0_value;
  assign core_ent_data_src[10][1] = entries_io_dataSources_10_1_value;
  assign core_ent_data_src[10][2] = entries_io_dataSources_10_2_value;
  assign core_ent_data_src[10][3] = entries_io_dataSources_10_3_value;
  assign core_ent_data_src[10][4] = entries_io_dataSources_10_4_value;
  assign core_ent_exu_src[10][0] = '0;
  assign core_ent_ld_dep[10][0] = 2'h0;
  assign core_ent_fu_type[11] = entries_io_fuType_11;
  assign core_ent_data_src[11][0] = entries_io_dataSources_11_0_value;
  assign core_ent_data_src[11][1] = entries_io_dataSources_11_1_value;
  assign core_ent_data_src[11][2] = entries_io_dataSources_11_2_value;
  assign core_ent_data_src[11][3] = entries_io_dataSources_11_3_value;
  assign core_ent_data_src[11][4] = entries_io_dataSources_11_4_value;
  assign core_ent_exu_src[11][0] = '0;
  assign core_ent_ld_dep[11][0] = 2'h0;
  assign core_ent_fu_type[12] = entries_io_fuType_12;
  assign core_ent_data_src[12][0] = entries_io_dataSources_12_0_value;
  assign core_ent_data_src[12][1] = entries_io_dataSources_12_1_value;
  assign core_ent_data_src[12][2] = entries_io_dataSources_12_2_value;
  assign core_ent_data_src[12][3] = entries_io_dataSources_12_3_value;
  assign core_ent_data_src[12][4] = entries_io_dataSources_12_4_value;
  assign core_ent_exu_src[12][0] = '0;
  assign core_ent_ld_dep[12][0] = 2'h0;
  assign core_ent_fu_type[13] = entries_io_fuType_13;
  assign core_ent_data_src[13][0] = entries_io_dataSources_13_0_value;
  assign core_ent_data_src[13][1] = entries_io_dataSources_13_1_value;
  assign core_ent_data_src[13][2] = entries_io_dataSources_13_2_value;
  assign core_ent_data_src[13][3] = entries_io_dataSources_13_3_value;
  assign core_ent_data_src[13][4] = entries_io_dataSources_13_4_value;
  assign core_ent_exu_src[13][0] = '0;
  assign core_ent_ld_dep[13][0] = 2'h0;
  assign core_ent_fu_type[14] = entries_io_fuType_14;
  assign core_ent_data_src[14][0] = entries_io_dataSources_14_0_value;
  assign core_ent_data_src[14][1] = entries_io_dataSources_14_1_value;
  assign core_ent_data_src[14][2] = entries_io_dataSources_14_2_value;
  assign core_ent_data_src[14][3] = entries_io_dataSources_14_3_value;
  assign core_ent_data_src[14][4] = entries_io_dataSources_14_4_value;
  assign core_ent_exu_src[14][0] = '0;
  assign core_ent_ld_dep[14][0] = 2'h0;
  assign core_ent_fu_type[15] = entries_io_fuType_15;
  assign core_ent_data_src[15][0] = entries_io_dataSources_15_0_value;
  assign core_ent_data_src[15][1] = entries_io_dataSources_15_1_value;
  assign core_ent_data_src[15][2] = entries_io_dataSources_15_2_value;
  assign core_ent_data_src[15][3] = entries_io_dataSources_15_3_value;
  assign core_ent_data_src[15][4] = entries_io_dataSources_15_4_value;
  assign core_ent_exu_src[15][0] = '0;
  assign core_ent_ld_dep[15][0] = 2'h0;
  assign core_ent_cancel_deq[0] = 1'h0;
  assign core_busy_mask[0][0] = fuBusyTableRead_0_io_out_fuBusyTableMask;
  assign core_busy_mask[0][1] = vfWbBusyTableRead_0_io_out_fuBusyTableMask;
  assign core_busy_mask[0][2] = v0WbBusyTableRead_0_io_out_fuBusyTableMask;
  assign core_busy_mask[0][3] = '0;
  assign core_dly_ready[0] = io_deqDelay_0_ready;
  assign core_ent_cancel_deq[1] = 1'h0;
  assign core_busy_mask[1][0] = fuBusyTableRead_1_io_out_fuBusyTableMask;
  assign core_busy_mask[1][1] = fpWbBusyTableRead_1_io_out_fuBusyTableMask;
  assign core_busy_mask[1][2] = vfWbBusyTableRead_1_io_out_fuBusyTableMask;
  assign core_busy_mask[1][3] = v0WbBusyTableRead_1_io_out_fuBusyTableMask;
  assign core_dly_ready[1] = io_deqDelay_1_ready;
  assign core_enq_lq_idx[0] = '0;
  assign core_enq_is_vleff[0] = 1'h0;
  assign core_enq_lq_idx[1] = '0;
  assign core_enq_is_vleff[1] = 1'h0;
  assign core_lq_deq_ptr = '0;
  assign core_deq_wen[0] = {1'h0, entries_io_deqEntry_0_bits_payload_v0Wen, entries_io_deqEntry_0_bits_payload_vecWen, 1'h0, 1'h0};   // {vl, v0, vec, fp, rf}Wen
  assign core_deq_wen[1] = {1'h0, entries_io_deqEntry_1_bits_payload_v0Wen, entries_io_deqEntry_1_bits_payload_vecWen, entries_io_deqEntry_1_bits_payload_fpWen, 1'h0};   // {vl, v0, vec, fp, rf}Wen
  assign core_ldw_valid = 1'h0;
  assign core_ldw_rf_wen = 1'h0;
  assign core_ldw_fp_wen = 1'h0;
  assign core_ldw_pdest = '0;
  assign core_age_enq_out[0] = age_io_out_0;
  assign core_age_comp_out[0] = age_2_io_out_0;
  assign core_age_enq_out[1] = age_io_out_1;
  assign core_age_comp_out[1] = age_2_io_out_1;
  assign core_age_simp_out[0] = age_1_io_out_0;
  assign core_age_simp_out[1] = age_1_io_out_1;
  assign core_age_simp_out[2] = age_1_io_out_2;
  assign core_age_simp_out[3] = age_1_io_out_3;

  // ============================================================================
  // §D0 口 0 deqDelay 负载拼包/拆包（golden 寄存器声明顺序，高位在前）
  assign core_deq0_payload = {
    entries_io_deqEntry_0_bits_status_srcStatus_4_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_4_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_3_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_3_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_2_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_2_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_1_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_1_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_0_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_1_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_2_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_3_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_4_srcType,
    entries_io_deqEntry_0_bits_payload_selImm,
    {9'h0, entries_io_deqEntry_0_bits_status_fuType_25, entries_io_deqEntry_0_bits_status_fuType_24, 4'h0, entries_io_deqEntry_0_bits_status_fuType_19, 19'h0},
    entries_io_deqEntry_0_bits_payload_fuOpType,
    128'h0,
    128'h0,
    128'h0,
    128'h0,
    128'h0,
    64'h0,
    entries_io_deqEntry_0_bits_status_robIdx_flag,
    entries_io_deqEntry_0_bits_status_robIdx_value,
    core_deq_iq_idx[0],
    entries_io_isFirstIssue_0,
    entries_io_deqEntry_0_bits_payload_pdest[6:0],
    entries_io_deqEntry_0_bits_payload_vecWen,
    entries_io_deqEntry_0_bits_payload_v0Wen,
    entries_io_deqEntry_0_bits_payload_fpu_typeTagOut,
    entries_io_deqEntry_0_bits_payload_fpu_wflags,
    entries_io_deqEntry_0_bits_payload_fpu_typ,
    entries_io_deqEntry_0_bits_payload_fpu_fmt,
    entries_io_deqEntry_0_bits_payload_fpu_rm,
    entries_io_deqEntry_0_bits_payload_vpu_vill,
    entries_io_deqEntry_0_bits_payload_vpu_vma,
    entries_io_deqEntry_0_bits_payload_vpu_vta,
    entries_io_deqEntry_0_bits_payload_vpu_vsew,
    entries_io_deqEntry_0_bits_payload_vpu_vlmul,
    entries_io_deqEntry_0_bits_payload_vpu_specVill,
    entries_io_deqEntry_0_bits_payload_vpu_specVma,
    entries_io_deqEntry_0_bits_payload_vpu_specVta,
    entries_io_deqEntry_0_bits_payload_vpu_specVsew,
    entries_io_deqEntry_0_bits_payload_vpu_specVlmul,
    entries_io_deqEntry_0_bits_payload_vpu_vm,
    entries_io_deqEntry_0_bits_payload_vpu_vstart,
    entries_io_deqEntry_0_bits_payload_vpu_frm,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isReduction,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4,
    entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8,
    entries_io_deqEntry_0_bits_payload_vpu_vxrm,
    entries_io_deqEntry_0_bits_payload_uopIdx,
    entries_io_deqEntry_0_bits_payload_lastUop,
    entries_io_deqEntry_0_bits_payload_vpu_vmask,
    entries_io_deqEntry_0_bits_payload_vpu_vl,
    entries_io_deqEntry_0_bits_payload_vpu_nf,
    entries_io_deqEntry_0_bits_payload_vpu_veew,
    entries_io_deqEntry_0_bits_payload_vpu_isReverse,
    entries_io_deqEntry_0_bits_payload_vpu_isExt,
    entries_io_deqEntry_0_bits_payload_vpu_isNarrow,
    entries_io_deqEntry_0_bits_payload_vpu_isDstMask,
    entries_io_deqEntry_0_bits_payload_vpu_isOpMask,
    entries_io_deqEntry_0_bits_payload_vpu_isMove,
    entries_io_deqEntry_0_bits_payload_vpu_isDependOldVd,
    entries_io_deqEntry_0_bits_payload_vpu_isWritePartVd,
    entries_io_deqEntry_0_bits_payload_vpu_isVleff,
    core_deq_data_src[0][0],
    core_deq_data_src[0][1],
    core_deq_data_src[0][2],
    core_deq_data_src[0][3],
    core_deq_data_src[0][4],
    entries_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove,
    entries_io_deqEntry_0_bits_payload_debugInfo_renameTime,
    entries_io_deqEntry_0_bits_payload_debugInfo_dispatchTime,
    entries_io_deqEntry_0_bits_payload_debugInfo_enqRsTime,
    core_deq_select_time[0],
    core_deq_issue_time[0],
    entries_io_deqEntry_0_bits_payload_debugInfo_writebackTime,
    entries_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id,
    entries_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime,
    entries_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime,
    entries_io_deqEntry_0_bits_payload_debug_seqNum_seqNum,
    entries_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx,
    core_sel_oh[0]
  };
  wire [6:0] dly0_bits_rf_4_0_addr = core_dly0_payload[1726:1720];
  wire [2:0] dly0_bits_rf_4_0_srcType = core_dly0_payload[1719:1717];
  wire [6:0] dly0_bits_rf_3_0_addr = core_dly0_payload[1716:1710];
  wire [2:0] dly0_bits_rf_3_0_srcType = core_dly0_payload[1709:1707];
  wire [6:0] dly0_bits_rf_2_0_addr = core_dly0_payload[1706:1700];
  wire [2:0] dly0_bits_rf_2_0_srcType = core_dly0_payload[1699:1697];
  wire [6:0] dly0_bits_rf_1_0_addr = core_dly0_payload[1696:1690];
  wire [2:0] dly0_bits_rf_1_0_srcType = core_dly0_payload[1689:1687];
  wire [6:0] dly0_bits_rf_0_0_addr = core_dly0_payload[1686:1680];
  wire [2:0] dly0_bits_rf_0_0_srcType = core_dly0_payload[1679:1677];
  wire [3:0] dly0_bits_srcType_0 = core_dly0_payload[1676:1673];
  wire [3:0] dly0_bits_srcType_1 = core_dly0_payload[1672:1669];
  wire [3:0] dly0_bits_srcType_2 = core_dly0_payload[1668:1665];
  wire [3:0] dly0_bits_srcType_3 = core_dly0_payload[1664:1661];
  wire [3:0] dly0_bits_srcType_4 = core_dly0_payload[1660:1657];
  wire [3:0] dly0_bits_immType = core_dly0_payload[1656:1653];
  wire [34:0] dly0_bits_common_fuType = core_dly0_payload[1652:1618];
  wire [8:0] dly0_bits_common_fuOpType = core_dly0_payload[1617:1609];
  wire [127:0] dly0_bits_common_src_0 = core_dly0_payload[1608:1481];
  wire [127:0] dly0_bits_common_src_1 = core_dly0_payload[1480:1353];
  wire [127:0] dly0_bits_common_src_2 = core_dly0_payload[1352:1225];
  wire [127:0] dly0_bits_common_src_3 = core_dly0_payload[1224:1097];
  wire [127:0] dly0_bits_common_src_4 = core_dly0_payload[1096:969];
  wire [63:0] dly0_bits_common_imm = core_dly0_payload[968:905];
  wire dly0_bits_common_robIdx_flag = core_dly0_payload[904:904];
  wire [7:0] dly0_bits_common_robIdx_value = core_dly0_payload[903:896];
  wire [3:0] dly0_bits_common_iqIdx = core_dly0_payload[895:892];
  wire dly0_bits_common_isFirstIssue = core_dly0_payload[891:891];
  wire [6:0] dly0_bits_common_pdest = core_dly0_payload[890:884];
  wire dly0_bits_common_vecWen = core_dly0_payload[883:883];
  wire dly0_bits_common_v0Wen = core_dly0_payload[882:882];
  wire [1:0] dly0_bits_common_fpu_typeTagOut = core_dly0_payload[881:880];
  wire dly0_bits_common_fpu_wflags = core_dly0_payload[879:879];
  wire [1:0] dly0_bits_common_fpu_typ = core_dly0_payload[878:877];
  wire [1:0] dly0_bits_common_fpu_fmt = core_dly0_payload[876:875];
  wire [2:0] dly0_bits_common_fpu_rm = core_dly0_payload[874:872];
  wire dly0_bits_common_vpu_vill = core_dly0_payload[871:871];
  wire dly0_bits_common_vpu_vma = core_dly0_payload[870:870];
  wire dly0_bits_common_vpu_vta = core_dly0_payload[869:869];
  wire [1:0] dly0_bits_common_vpu_vsew = core_dly0_payload[868:867];
  wire [2:0] dly0_bits_common_vpu_vlmul = core_dly0_payload[866:864];
  wire dly0_bits_common_vpu_specVill = core_dly0_payload[863:863];
  wire dly0_bits_common_vpu_specVma = core_dly0_payload[862:862];
  wire dly0_bits_common_vpu_specVta = core_dly0_payload[861:861];
  wire [1:0] dly0_bits_common_vpu_specVsew = core_dly0_payload[860:859];
  wire [2:0] dly0_bits_common_vpu_specVlmul = core_dly0_payload[858:856];
  wire dly0_bits_common_vpu_vm = core_dly0_payload[855:855];
  wire [7:0] dly0_bits_common_vpu_vstart = core_dly0_payload[854:847];
  wire [2:0] dly0_bits_common_vpu_frm = core_dly0_payload[846:844];
  wire dly0_bits_common_vpu_fpu_isFpToVecInst = core_dly0_payload[843:843];
  wire dly0_bits_common_vpu_fpu_isFP32Instr = core_dly0_payload[842:842];
  wire dly0_bits_common_vpu_fpu_isFP64Instr = core_dly0_payload[841:841];
  wire dly0_bits_common_vpu_fpu_isReduction = core_dly0_payload[840:840];
  wire dly0_bits_common_vpu_fpu_isFoldTo1_2 = core_dly0_payload[839:839];
  wire dly0_bits_common_vpu_fpu_isFoldTo1_4 = core_dly0_payload[838:838];
  wire dly0_bits_common_vpu_fpu_isFoldTo1_8 = core_dly0_payload[837:837];
  wire [1:0] dly0_bits_common_vpu_vxrm = core_dly0_payload[836:835];
  wire [6:0] dly0_bits_common_vpu_vuopIdx = core_dly0_payload[834:828];
  wire dly0_bits_common_vpu_lastUop = core_dly0_payload[827:827];
  wire [127:0] dly0_bits_common_vpu_vmask = core_dly0_payload[826:699];
  wire [7:0] dly0_bits_common_vpu_vl = core_dly0_payload[698:691];
  wire [2:0] dly0_bits_common_vpu_nf = core_dly0_payload[690:688];
  wire [1:0] dly0_bits_common_vpu_veew = core_dly0_payload[687:686];
  wire dly0_bits_common_vpu_isReverse = core_dly0_payload[685:685];
  wire dly0_bits_common_vpu_isExt = core_dly0_payload[684:684];
  wire dly0_bits_common_vpu_isNarrow = core_dly0_payload[683:683];
  wire dly0_bits_common_vpu_isDstMask = core_dly0_payload[682:682];
  wire dly0_bits_common_vpu_isOpMask = core_dly0_payload[681:681];
  wire dly0_bits_common_vpu_isMove = core_dly0_payload[680:680];
  wire dly0_bits_common_vpu_isDependOldVd = core_dly0_payload[679:679];
  wire dly0_bits_common_vpu_isWritePartVd = core_dly0_payload[678:678];
  wire dly0_bits_common_vpu_isVleff = core_dly0_payload[677:677];
  wire [3:0] dly0_bits_common_dataSources_0_value = core_dly0_payload[676:673];
  wire [3:0] dly0_bits_common_dataSources_1_value = core_dly0_payload[672:669];
  wire [3:0] dly0_bits_common_dataSources_2_value = core_dly0_payload[668:665];
  wire [3:0] dly0_bits_common_dataSources_3_value = core_dly0_payload[664:661];
  wire [3:0] dly0_bits_common_dataSources_4_value = core_dly0_payload[660:657];
  wire dly0_bits_common_perfDebugInfo_eliminatedMove = core_dly0_payload[656:656];
  wire [63:0] dly0_bits_common_perfDebugInfo_renameTime = core_dly0_payload[655:592];
  wire [63:0] dly0_bits_common_perfDebugInfo_dispatchTime = core_dly0_payload[591:528];
  wire [63:0] dly0_bits_common_perfDebugInfo_enqRsTime = core_dly0_payload[527:464];
  wire [63:0] dly0_bits_common_perfDebugInfo_selectTime = core_dly0_payload[463:400];
  wire [63:0] dly0_bits_common_perfDebugInfo_issueTime = core_dly0_payload[399:336];
  wire [63:0] dly0_bits_common_perfDebugInfo_writebackTime = core_dly0_payload[335:272];
  wire [63:0] dly0_bits_common_perfDebugInfo_runahead_checkpoint_id = core_dly0_payload[271:208];
  wire [63:0] dly0_bits_common_perfDebugInfo_tlbFirstReqTime = core_dly0_payload[207:144];
  wire [63:0] dly0_bits_common_perfDebugInfo_tlbRespTime = core_dly0_payload[143:80];
  wire [55:0] dly0_bits_common_debug_seqNum_seqNum = core_dly0_payload[79:24];
  wire [7:0] dly0_bits_common_debug_seqNum_uopIdx = core_dly0_payload[23:16];
  wire [15:0] dly0_bits_addrOH = core_dly0_payload[15:0];

  // ============================================================================
  // §D1 口 1 deqDelay 负载拼包/拆包（golden 寄存器声明顺序，高位在前）
  assign core_deq1_payload = {
    entries_io_deqEntry_1_bits_status_srcStatus_4_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_4_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_3_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_3_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_2_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_2_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_1_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_1_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_0_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_0_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_0_srcType,
    entries_io_deqEntry_1_bits_status_srcStatus_1_srcType,
    entries_io_deqEntry_1_bits_status_srcStatus_2_srcType,
    entries_io_deqEntry_1_bits_status_srcStatus_3_srcType,
    entries_io_deqEntry_1_bits_status_srcStatus_4_srcType,
    entries_io_deqEntry_1_bits_payload_selImm,
    {9'h0, entries_io_deqEntry_1_bits_status_fuType_25, entries_io_deqEntry_1_bits_status_fuType_24, 4'h0, entries_io_deqEntry_1_bits_status_fuType_19, 19'h0},
    entries_io_deqEntry_1_bits_payload_fuOpType,
    128'h0,
    128'h0,
    128'h0,
    128'h0,
    128'h0,
    64'h0,
    entries_io_deqEntry_1_bits_status_robIdx_flag,
    entries_io_deqEntry_1_bits_status_robIdx_value,
    core_deq_iq_idx[1],
    entries_io_isFirstIssue_1,
    entries_io_deqEntry_1_bits_payload_pdest,
    entries_io_deqEntry_1_bits_payload_fpWen,
    entries_io_deqEntry_1_bits_payload_vecWen,
    entries_io_deqEntry_1_bits_payload_v0Wen,
    entries_io_deqEntry_1_bits_payload_fpu_typeTagOut,
    entries_io_deqEntry_1_bits_payload_fpu_wflags,
    entries_io_deqEntry_1_bits_payload_fpu_typ,
    entries_io_deqEntry_1_bits_payload_fpu_fmt,
    entries_io_deqEntry_1_bits_payload_fpu_rm,
    entries_io_deqEntry_1_bits_payload_vpu_vill,
    entries_io_deqEntry_1_bits_payload_vpu_vma,
    entries_io_deqEntry_1_bits_payload_vpu_vta,
    entries_io_deqEntry_1_bits_payload_vpu_vsew,
    entries_io_deqEntry_1_bits_payload_vpu_vlmul,
    entries_io_deqEntry_1_bits_payload_vpu_specVill,
    entries_io_deqEntry_1_bits_payload_vpu_specVma,
    entries_io_deqEntry_1_bits_payload_vpu_specVta,
    entries_io_deqEntry_1_bits_payload_vpu_specVsew,
    entries_io_deqEntry_1_bits_payload_vpu_specVlmul,
    entries_io_deqEntry_1_bits_payload_vpu_vm,
    entries_io_deqEntry_1_bits_payload_vpu_vstart,
    entries_io_deqEntry_1_bits_payload_vpu_frm,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isFpToVecInst,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isFP32Instr,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isFP64Instr,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isReduction,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_2,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_4,
    entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_8,
    entries_io_deqEntry_1_bits_payload_vpu_vxrm,
    entries_io_deqEntry_1_bits_payload_uopIdx,
    entries_io_deqEntry_1_bits_payload_lastUop,
    entries_io_deqEntry_1_bits_payload_vpu_vmask,
    entries_io_deqEntry_1_bits_payload_vpu_vl,
    entries_io_deqEntry_1_bits_payload_vpu_nf,
    entries_io_deqEntry_1_bits_payload_vpu_veew,
    entries_io_deqEntry_1_bits_payload_vpu_isReverse,
    entries_io_deqEntry_1_bits_payload_vpu_isExt,
    entries_io_deqEntry_1_bits_payload_vpu_isNarrow,
    entries_io_deqEntry_1_bits_payload_vpu_isDstMask,
    entries_io_deqEntry_1_bits_payload_vpu_isOpMask,
    entries_io_deqEntry_1_bits_payload_vpu_isMove,
    entries_io_deqEntry_1_bits_payload_vpu_isDependOldVd,
    entries_io_deqEntry_1_bits_payload_vpu_isWritePartVd,
    entries_io_deqEntry_1_bits_payload_vpu_isVleff,
    core_deq_data_src[1][0],
    core_deq_data_src[1][1],
    core_deq_data_src[1][2],
    core_deq_data_src[1][3],
    core_deq_data_src[1][4],
    entries_io_deqEntry_1_bits_payload_debugInfo_eliminatedMove,
    entries_io_deqEntry_1_bits_payload_debugInfo_renameTime,
    entries_io_deqEntry_1_bits_payload_debugInfo_dispatchTime,
    entries_io_deqEntry_1_bits_payload_debugInfo_enqRsTime,
    core_deq_select_time[1],
    core_deq_issue_time[1],
    entries_io_deqEntry_1_bits_payload_debugInfo_writebackTime,
    entries_io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id,
    entries_io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime,
    entries_io_deqEntry_1_bits_payload_debugInfo_tlbRespTime,
    entries_io_deqEntry_1_bits_payload_debug_seqNum_seqNum,
    entries_io_deqEntry_1_bits_payload_debug_seqNum_uopIdx,
    core_sel_oh[1]
  };
  wire [6:0] dly1_bits_rf_4_0_addr = core_dly1_payload[1728:1722];
  wire [2:0] dly1_bits_rf_4_0_srcType = core_dly1_payload[1721:1719];
  wire [6:0] dly1_bits_rf_3_0_addr = core_dly1_payload[1718:1712];
  wire [2:0] dly1_bits_rf_3_0_srcType = core_dly1_payload[1711:1709];
  wire [6:0] dly1_bits_rf_2_0_addr = core_dly1_payload[1708:1702];
  wire [2:0] dly1_bits_rf_2_0_srcType = core_dly1_payload[1701:1699];
  wire [6:0] dly1_bits_rf_1_0_addr = core_dly1_payload[1698:1692];
  wire [2:0] dly1_bits_rf_1_0_srcType = core_dly1_payload[1691:1689];
  wire [6:0] dly1_bits_rf_0_0_addr = core_dly1_payload[1688:1682];
  wire [2:0] dly1_bits_rf_0_0_srcType = core_dly1_payload[1681:1679];
  wire [3:0] dly1_bits_srcType_0 = core_dly1_payload[1678:1675];
  wire [3:0] dly1_bits_srcType_1 = core_dly1_payload[1674:1671];
  wire [3:0] dly1_bits_srcType_2 = core_dly1_payload[1670:1667];
  wire [3:0] dly1_bits_srcType_3 = core_dly1_payload[1666:1663];
  wire [3:0] dly1_bits_srcType_4 = core_dly1_payload[1662:1659];
  wire [3:0] dly1_bits_immType = core_dly1_payload[1658:1655];
  wire [34:0] dly1_bits_common_fuType = core_dly1_payload[1654:1620];
  wire [8:0] dly1_bits_common_fuOpType = core_dly1_payload[1619:1611];
  wire [127:0] dly1_bits_common_src_0 = core_dly1_payload[1610:1483];
  wire [127:0] dly1_bits_common_src_1 = core_dly1_payload[1482:1355];
  wire [127:0] dly1_bits_common_src_2 = core_dly1_payload[1354:1227];
  wire [127:0] dly1_bits_common_src_3 = core_dly1_payload[1226:1099];
  wire [127:0] dly1_bits_common_src_4 = core_dly1_payload[1098:971];
  wire [63:0] dly1_bits_common_imm = core_dly1_payload[970:907];
  wire dly1_bits_common_robIdx_flag = core_dly1_payload[906:906];
  wire [7:0] dly1_bits_common_robIdx_value = core_dly1_payload[905:898];
  wire [3:0] dly1_bits_common_iqIdx = core_dly1_payload[897:894];
  wire dly1_bits_common_isFirstIssue = core_dly1_payload[893:893];
  wire [7:0] dly1_bits_common_pdest = core_dly1_payload[892:885];
  wire dly1_bits_common_fpWen = core_dly1_payload[884:884];
  wire dly1_bits_common_vecWen = core_dly1_payload[883:883];
  wire dly1_bits_common_v0Wen = core_dly1_payload[882:882];
  wire [1:0] dly1_bits_common_fpu_typeTagOut = core_dly1_payload[881:880];
  wire dly1_bits_common_fpu_wflags = core_dly1_payload[879:879];
  wire [1:0] dly1_bits_common_fpu_typ = core_dly1_payload[878:877];
  wire [1:0] dly1_bits_common_fpu_fmt = core_dly1_payload[876:875];
  wire [2:0] dly1_bits_common_fpu_rm = core_dly1_payload[874:872];
  wire dly1_bits_common_vpu_vill = core_dly1_payload[871:871];
  wire dly1_bits_common_vpu_vma = core_dly1_payload[870:870];
  wire dly1_bits_common_vpu_vta = core_dly1_payload[869:869];
  wire [1:0] dly1_bits_common_vpu_vsew = core_dly1_payload[868:867];
  wire [2:0] dly1_bits_common_vpu_vlmul = core_dly1_payload[866:864];
  wire dly1_bits_common_vpu_specVill = core_dly1_payload[863:863];
  wire dly1_bits_common_vpu_specVma = core_dly1_payload[862:862];
  wire dly1_bits_common_vpu_specVta = core_dly1_payload[861:861];
  wire [1:0] dly1_bits_common_vpu_specVsew = core_dly1_payload[860:859];
  wire [2:0] dly1_bits_common_vpu_specVlmul = core_dly1_payload[858:856];
  wire dly1_bits_common_vpu_vm = core_dly1_payload[855:855];
  wire [7:0] dly1_bits_common_vpu_vstart = core_dly1_payload[854:847];
  wire [2:0] dly1_bits_common_vpu_frm = core_dly1_payload[846:844];
  wire dly1_bits_common_vpu_fpu_isFpToVecInst = core_dly1_payload[843:843];
  wire dly1_bits_common_vpu_fpu_isFP32Instr = core_dly1_payload[842:842];
  wire dly1_bits_common_vpu_fpu_isFP64Instr = core_dly1_payload[841:841];
  wire dly1_bits_common_vpu_fpu_isReduction = core_dly1_payload[840:840];
  wire dly1_bits_common_vpu_fpu_isFoldTo1_2 = core_dly1_payload[839:839];
  wire dly1_bits_common_vpu_fpu_isFoldTo1_4 = core_dly1_payload[838:838];
  wire dly1_bits_common_vpu_fpu_isFoldTo1_8 = core_dly1_payload[837:837];
  wire [1:0] dly1_bits_common_vpu_vxrm = core_dly1_payload[836:835];
  wire [6:0] dly1_bits_common_vpu_vuopIdx = core_dly1_payload[834:828];
  wire dly1_bits_common_vpu_lastUop = core_dly1_payload[827:827];
  wire [127:0] dly1_bits_common_vpu_vmask = core_dly1_payload[826:699];
  wire [7:0] dly1_bits_common_vpu_vl = core_dly1_payload[698:691];
  wire [2:0] dly1_bits_common_vpu_nf = core_dly1_payload[690:688];
  wire [1:0] dly1_bits_common_vpu_veew = core_dly1_payload[687:686];
  wire dly1_bits_common_vpu_isReverse = core_dly1_payload[685:685];
  wire dly1_bits_common_vpu_isExt = core_dly1_payload[684:684];
  wire dly1_bits_common_vpu_isNarrow = core_dly1_payload[683:683];
  wire dly1_bits_common_vpu_isDstMask = core_dly1_payload[682:682];
  wire dly1_bits_common_vpu_isOpMask = core_dly1_payload[681:681];
  wire dly1_bits_common_vpu_isMove = core_dly1_payload[680:680];
  wire dly1_bits_common_vpu_isDependOldVd = core_dly1_payload[679:679];
  wire dly1_bits_common_vpu_isWritePartVd = core_dly1_payload[678:678];
  wire dly1_bits_common_vpu_isVleff = core_dly1_payload[677:677];
  wire [3:0] dly1_bits_common_dataSources_0_value = core_dly1_payload[676:673];
  wire [3:0] dly1_bits_common_dataSources_1_value = core_dly1_payload[672:669];
  wire [3:0] dly1_bits_common_dataSources_2_value = core_dly1_payload[668:665];
  wire [3:0] dly1_bits_common_dataSources_3_value = core_dly1_payload[664:661];
  wire [3:0] dly1_bits_common_dataSources_4_value = core_dly1_payload[660:657];
  wire dly1_bits_common_perfDebugInfo_eliminatedMove = core_dly1_payload[656:656];
  wire [63:0] dly1_bits_common_perfDebugInfo_renameTime = core_dly1_payload[655:592];
  wire [63:0] dly1_bits_common_perfDebugInfo_dispatchTime = core_dly1_payload[591:528];
  wire [63:0] dly1_bits_common_perfDebugInfo_enqRsTime = core_dly1_payload[527:464];
  wire [63:0] dly1_bits_common_perfDebugInfo_selectTime = core_dly1_payload[463:400];
  wire [63:0] dly1_bits_common_perfDebugInfo_issueTime = core_dly1_payload[399:336];
  wire [63:0] dly1_bits_common_perfDebugInfo_writebackTime = core_dly1_payload[335:272];
  wire [63:0] dly1_bits_common_perfDebugInfo_runahead_checkpoint_id = core_dly1_payload[271:208];
  wire [63:0] dly1_bits_common_perfDebugInfo_tlbFirstReqTime = core_dly1_payload[207:144];
  wire [63:0] dly1_bits_common_perfDebugInfo_tlbRespTime = core_dly1_payload[143:80];
  wire [55:0] dly1_bits_common_debug_seqNum_seqNum = core_dly1_payload[79:24];
  wire [7:0] dly1_bits_common_debug_seqNum_uopIdx = core_dly1_payload[23:16];
  wire [15:0] dly1_bits_addrOH = core_dly1_payload[15:0];

  // ============================================================================
  // §E 子模块例化（golden 同名实例，均为已签核件）
  EntriesVfmaVialuFixVfalu entries (
    .clock                                                       (clock),
    .reset                                                       (reset),
    .io_flush_valid                                              (io_flush_valid),
    .io_flush_bits_robIdx_flag                                   (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value                                  (io_flush_bits_robIdx_value),
    .io_flush_bits_level                                         (io_flush_bits_level),
    .io_enq_0_valid                                              (core_enq_do[0]),
    .io_enq_0_bits_status_robIdx_flag                            (io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value                           (io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_status_fuType_19                              (io_enq_0_bits_fuType[19]),
    .io_enq_0_bits_status_fuType_24                              (io_enq_0_bits_fuType[24]),
    .io_enq_0_bits_status_fuType_25                              (io_enq_0_bits_fuType[25]),
    .io_enq_0_bits_status_srcStatus_0_psrc                       (io_enq_0_bits_psrc_0[6:0]),
    .io_enq_0_bits_status_srcStatus_0_srcType                    (io_enq_0_bits_srcType_0),
    .io_enq_0_bits_status_srcStatus_0_srcState                   (core_st_src_state[0][0]),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value          (core_st_data_src[0][0]),
    .io_enq_0_bits_status_srcStatus_1_psrc                       (io_enq_0_bits_psrc_1[6:0]),
    .io_enq_0_bits_status_srcStatus_1_srcType                    (io_enq_0_bits_srcType_1),
    .io_enq_0_bits_status_srcStatus_1_srcState                   (core_st_src_state[0][1]),
    .io_enq_0_bits_status_srcStatus_1_dataSources_value          (core_st_data_src[0][1]),
    .io_enq_0_bits_status_srcStatus_2_psrc                       (io_enq_0_bits_psrc_2[6:0]),
    .io_enq_0_bits_status_srcStatus_2_srcType                    (io_enq_0_bits_srcType_2),
    .io_enq_0_bits_status_srcStatus_2_srcState                   (core_st_src_state[0][2]),
    .io_enq_0_bits_status_srcStatus_2_dataSources_value          (core_st_data_src[0][2]),
    .io_enq_0_bits_status_srcStatus_3_psrc                       (io_enq_0_bits_psrc_3[6:0]),
    .io_enq_0_bits_status_srcStatus_3_srcType                    (io_enq_0_bits_srcType_3),
    .io_enq_0_bits_status_srcStatus_3_srcState                   (core_st_src_state[0][3]),
    .io_enq_0_bits_status_srcStatus_3_dataSources_value          (core_st_data_src[0][3]),
    .io_enq_0_bits_status_srcStatus_4_psrc                       (io_enq_0_bits_psrc_4[6:0]),
    .io_enq_0_bits_status_srcStatus_4_srcType                    (io_enq_0_bits_srcType_4),
    .io_enq_0_bits_status_srcStatus_4_srcState                   (core_st_src_state[0][4]),
    .io_enq_0_bits_status_srcStatus_4_dataSources_value          (core_st_data_src[0][4]),
    .io_enq_0_bits_payload_instr                                 (io_enq_0_bits_instr),
    .io_enq_0_bits_payload_pc                                    (io_enq_0_bits_pc),
    .io_enq_0_bits_payload_foldpc                                (io_enq_0_bits_foldpc),
    .io_enq_0_bits_payload_exceptionVec_0                        (io_enq_0_bits_exceptionVec_0),
    .io_enq_0_bits_payload_exceptionVec_1                        (io_enq_0_bits_exceptionVec_1),
    .io_enq_0_bits_payload_exceptionVec_2                        (io_enq_0_bits_exceptionVec_2),
    .io_enq_0_bits_payload_exceptionVec_3                        (io_enq_0_bits_exceptionVec_3),
    .io_enq_0_bits_payload_exceptionVec_4                        (io_enq_0_bits_exceptionVec_4),
    .io_enq_0_bits_payload_exceptionVec_5                        (io_enq_0_bits_exceptionVec_5),
    .io_enq_0_bits_payload_exceptionVec_6                        (io_enq_0_bits_exceptionVec_6),
    .io_enq_0_bits_payload_exceptionVec_7                        (io_enq_0_bits_exceptionVec_7),
    .io_enq_0_bits_payload_exceptionVec_8                        (io_enq_0_bits_exceptionVec_8),
    .io_enq_0_bits_payload_exceptionVec_9                        (io_enq_0_bits_exceptionVec_9),
    .io_enq_0_bits_payload_exceptionVec_10                       (io_enq_0_bits_exceptionVec_10),
    .io_enq_0_bits_payload_exceptionVec_11                       (io_enq_0_bits_exceptionVec_11),
    .io_enq_0_bits_payload_exceptionVec_12                       (io_enq_0_bits_exceptionVec_12),
    .io_enq_0_bits_payload_exceptionVec_13                       (io_enq_0_bits_exceptionVec_13),
    .io_enq_0_bits_payload_exceptionVec_14                       (io_enq_0_bits_exceptionVec_14),
    .io_enq_0_bits_payload_exceptionVec_15                       (io_enq_0_bits_exceptionVec_15),
    .io_enq_0_bits_payload_exceptionVec_16                       (io_enq_0_bits_exceptionVec_16),
    .io_enq_0_bits_payload_exceptionVec_17                       (io_enq_0_bits_exceptionVec_17),
    .io_enq_0_bits_payload_exceptionVec_18                       (io_enq_0_bits_exceptionVec_18),
    .io_enq_0_bits_payload_exceptionVec_19                       (io_enq_0_bits_exceptionVec_19),
    .io_enq_0_bits_payload_exceptionVec_20                       (io_enq_0_bits_exceptionVec_20),
    .io_enq_0_bits_payload_exceptionVec_21                       (io_enq_0_bits_exceptionVec_21),
    .io_enq_0_bits_payload_exceptionVec_22                       (io_enq_0_bits_exceptionVec_22),
    .io_enq_0_bits_payload_exceptionVec_23                       (io_enq_0_bits_exceptionVec_23),
    .io_enq_0_bits_payload_isFetchMalAddr                        (io_enq_0_bits_isFetchMalAddr),
    .io_enq_0_bits_payload_hasException                          (io_enq_0_bits_hasException),
    .io_enq_0_bits_payload_trigger                               (io_enq_0_bits_trigger),
    .io_enq_0_bits_payload_preDecodeInfo_valid                   (io_enq_0_bits_preDecodeInfo_valid),
    .io_enq_0_bits_payload_preDecodeInfo_isRVC                   (io_enq_0_bits_preDecodeInfo_isRVC),
    .io_enq_0_bits_payload_preDecodeInfo_brType                  (io_enq_0_bits_preDecodeInfo_brType),
    .io_enq_0_bits_payload_preDecodeInfo_isCall                  (io_enq_0_bits_preDecodeInfo_isCall),
    .io_enq_0_bits_payload_preDecodeInfo_isRet                   (io_enq_0_bits_preDecodeInfo_isRet),
    .io_enq_0_bits_payload_pred_taken                            (io_enq_0_bits_pred_taken),
    .io_enq_0_bits_payload_crossPageIPFFix                       (io_enq_0_bits_crossPageIPFFix),
    .io_enq_0_bits_payload_ftqPtr_flag                           (io_enq_0_bits_ftqPtr_flag),
    .io_enq_0_bits_payload_ftqPtr_value                          (io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_payload_ftqOffset                             (io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_payload_satpFlushFirstFetchFault              (io_enq_0_bits_satpFlushFirstFetchFault),
    .io_enq_0_bits_payload_srcType_0                             (io_enq_0_bits_srcType_0),
    .io_enq_0_bits_payload_srcType_1                             (io_enq_0_bits_srcType_1),
    .io_enq_0_bits_payload_srcType_2                             (io_enq_0_bits_srcType_2),
    .io_enq_0_bits_payload_srcType_3                             (io_enq_0_bits_srcType_3),
    .io_enq_0_bits_payload_srcType_4                             (io_enq_0_bits_srcType_4),
    .io_enq_0_bits_payload_ldest                                 (io_enq_0_bits_ldest),
    .io_enq_0_bits_payload_fuType                                (io_enq_0_bits_fuType),
    .io_enq_0_bits_payload_fuOpType                              (io_enq_0_bits_fuOpType),
    .io_enq_0_bits_payload_rfWen                                 (io_enq_0_bits_rfWen),
    .io_enq_0_bits_payload_fpWen                                 (io_enq_0_bits_fpWen),
    .io_enq_0_bits_payload_vecWen                                (io_enq_0_bits_vecWen),
    .io_enq_0_bits_payload_v0Wen                                 (io_enq_0_bits_v0Wen),
    .io_enq_0_bits_payload_vlWen                                 (io_enq_0_bits_vlWen),
    .io_enq_0_bits_payload_isXSTrap                              (io_enq_0_bits_isXSTrap),
    .io_enq_0_bits_payload_waitForward                           (io_enq_0_bits_waitForward),
    .io_enq_0_bits_payload_blockBackward                         (io_enq_0_bits_blockBackward),
    .io_enq_0_bits_payload_flushPipe                             (io_enq_0_bits_flushPipe),
    .io_enq_0_bits_payload_canRobCompress                        (io_enq_0_bits_canRobCompress),
    .io_enq_0_bits_payload_selImm                                (io_enq_0_bits_selImm),
    .io_enq_0_bits_payload_imm                                   (io_enq_0_bits_imm),
    .io_enq_0_bits_payload_fpu_typeTagOut                        (io_enq_0_bits_fpu_typeTagOut),
    .io_enq_0_bits_payload_fpu_wflags                            (io_enq_0_bits_fpu_wflags),
    .io_enq_0_bits_payload_fpu_typ                               (io_enq_0_bits_fpu_typ),
    .io_enq_0_bits_payload_fpu_fmt                               (io_enq_0_bits_fpu_fmt),
    .io_enq_0_bits_payload_fpu_rm                                (io_enq_0_bits_fpu_rm),
    .io_enq_0_bits_payload_vpu_vill                              (io_enq_0_bits_vpu_vill),
    .io_enq_0_bits_payload_vpu_vma                               (io_enq_0_bits_vpu_vma),
    .io_enq_0_bits_payload_vpu_vta                               (io_enq_0_bits_vpu_vta),
    .io_enq_0_bits_payload_vpu_vsew                              (io_enq_0_bits_vpu_vsew),
    .io_enq_0_bits_payload_vpu_vlmul                             (io_enq_0_bits_vpu_vlmul),
    .io_enq_0_bits_payload_vpu_specVill                          (io_enq_0_bits_vpu_specVill),
    .io_enq_0_bits_payload_vpu_specVma                           (io_enq_0_bits_vpu_specVma),
    .io_enq_0_bits_payload_vpu_specVta                           (io_enq_0_bits_vpu_specVta),
    .io_enq_0_bits_payload_vpu_specVsew                          (io_enq_0_bits_vpu_specVsew),
    .io_enq_0_bits_payload_vpu_specVlmul                         (io_enq_0_bits_vpu_specVlmul),
    .io_enq_0_bits_payload_vpu_vm                                (io_enq_0_bits_vpu_vm),
    .io_enq_0_bits_payload_vpu_vstart                            (io_enq_0_bits_vpu_vstart),
    .io_enq_0_bits_payload_vpu_frm                               (io_enq_0_bits_vpu_frm),
    .io_enq_0_bits_payload_vpu_fpu_isFpToVecInst                 (io_enq_0_bits_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_payload_vpu_fpu_isFP32Instr                   (io_enq_0_bits_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_payload_vpu_fpu_isFP64Instr                   (io_enq_0_bits_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_payload_vpu_fpu_isReduction                   (io_enq_0_bits_vpu_fpu_isReduction),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2                   (io_enq_0_bits_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4                   (io_enq_0_bits_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8                   (io_enq_0_bits_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_payload_vpu_vxrm                              (io_enq_0_bits_vpu_vxrm),
    .io_enq_0_bits_payload_vpu_vuopIdx                           (io_enq_0_bits_vpu_vuopIdx),
    .io_enq_0_bits_payload_vpu_lastUop                           (io_enq_0_bits_vpu_lastUop),
    .io_enq_0_bits_payload_vpu_vmask                             (io_enq_0_bits_vpu_vmask),
    .io_enq_0_bits_payload_vpu_vl                                (io_enq_0_bits_vpu_vl),
    .io_enq_0_bits_payload_vpu_nf                                (io_enq_0_bits_vpu_nf),
    .io_enq_0_bits_payload_vpu_veew                              (io_enq_0_bits_vpu_veew),
    .io_enq_0_bits_payload_vpu_isReverse                         (io_enq_0_bits_vpu_isReverse),
    .io_enq_0_bits_payload_vpu_isExt                             (io_enq_0_bits_vpu_isExt),
    .io_enq_0_bits_payload_vpu_isNarrow                          (io_enq_0_bits_vpu_isNarrow),
    .io_enq_0_bits_payload_vpu_isDstMask                         (io_enq_0_bits_vpu_isDstMask),
    .io_enq_0_bits_payload_vpu_isOpMask                          (io_enq_0_bits_vpu_isOpMask),
    .io_enq_0_bits_payload_vpu_isMove                            (io_enq_0_bits_vpu_isMove),
    .io_enq_0_bits_payload_vpu_isDependOldVd                     (io_enq_0_bits_vpu_isDependOldVd),
    .io_enq_0_bits_payload_vpu_isWritePartVd                     (io_enq_0_bits_vpu_isWritePartVd),
    .io_enq_0_bits_payload_vpu_isVleff                           (io_enq_0_bits_vpu_isVleff),
    .io_enq_0_bits_payload_vlsInstr                              (io_enq_0_bits_vlsInstr),
    .io_enq_0_bits_payload_wfflags                               (io_enq_0_bits_wfflags),
    .io_enq_0_bits_payload_isMove                                (io_enq_0_bits_isMove),
    .io_enq_0_bits_payload_isDropAmocasSta                       (io_enq_0_bits_isDropAmocasSta),
    .io_enq_0_bits_payload_uopIdx                                (io_enq_0_bits_uopIdx),
    .io_enq_0_bits_payload_isVset                                (io_enq_0_bits_isVset),
    .io_enq_0_bits_payload_firstUop                              (io_enq_0_bits_firstUop),
    .io_enq_0_bits_payload_lastUop                               (io_enq_0_bits_lastUop),
    .io_enq_0_bits_payload_numUops                               (io_enq_0_bits_numUops),
    .io_enq_0_bits_payload_numWB                                 (io_enq_0_bits_numWB),
    .io_enq_0_bits_payload_commitType                            (io_enq_0_bits_commitType),
    .io_enq_0_bits_payload_srcState_0                            (io_enq_0_bits_srcState_0),
    .io_enq_0_bits_payload_srcState_1                            (io_enq_0_bits_srcState_1),
    .io_enq_0_bits_payload_srcState_2                            (io_enq_0_bits_srcState_2),
    .io_enq_0_bits_payload_srcState_3                            (io_enq_0_bits_srcState_3),
    .io_enq_0_bits_payload_srcState_4                            (io_enq_0_bits_srcState_4),
    .io_enq_0_bits_payload_psrc_0                                (io_enq_0_bits_psrc_0),
    .io_enq_0_bits_payload_psrc_1                                (io_enq_0_bits_psrc_1),
    .io_enq_0_bits_payload_psrc_2                                (io_enq_0_bits_psrc_2),
    .io_enq_0_bits_payload_psrc_3                                (io_enq_0_bits_psrc_3),
    .io_enq_0_bits_payload_psrc_4                                (io_enq_0_bits_psrc_4),
    .io_enq_0_bits_payload_pdest                                 (io_enq_0_bits_pdest),
    .io_enq_0_bits_payload_useRegCache_0                         (io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_payload_useRegCache_1                         (io_enq_0_bits_useRegCache_1),
    .io_enq_0_bits_payload_regCacheIdx_0                         (io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_payload_regCacheIdx_1                         (io_enq_0_bits_regCacheIdx_1),
    .io_enq_0_bits_payload_robIdx_flag                           (io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_payload_robIdx_value                          (io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_payload_instrSize                             (io_enq_0_bits_instrSize),
    .io_enq_0_bits_payload_dirtyFs                               (io_enq_0_bits_dirtyFs),
    .io_enq_0_bits_payload_dirtyVs                               (io_enq_0_bits_dirtyVs),
    .io_enq_0_bits_payload_traceBlockInPipe_itype                (io_enq_0_bits_traceBlockInPipe_itype),
    .io_enq_0_bits_payload_traceBlockInPipe_iretire              (io_enq_0_bits_traceBlockInPipe_iretire),
    .io_enq_0_bits_payload_traceBlockInPipe_ilastsize            (io_enq_0_bits_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_payload_eliminatedMove                        (io_enq_0_bits_eliminatedMove),
    .io_enq_0_bits_payload_snapshot                              (io_enq_0_bits_snapshot),
    .io_enq_0_bits_payload_debugInfo_eliminatedMove              (io_enq_0_bits_debugInfo_eliminatedMove),
    .io_enq_0_bits_payload_debugInfo_renameTime                  (io_enq_0_bits_debugInfo_renameTime),
    .io_enq_0_bits_payload_debugInfo_dispatchTime                (io_enq_0_bits_debugInfo_dispatchTime),
    .io_enq_0_bits_payload_debugInfo_enqRsTime                   (io_enq_0_bits_debugInfo_enqRsTime),
    .io_enq_0_bits_payload_debugInfo_selectTime                  (io_enq_0_bits_debugInfo_selectTime),
    .io_enq_0_bits_payload_debugInfo_issueTime                   (io_enq_0_bits_debugInfo_issueTime),
    .io_enq_0_bits_payload_debugInfo_writebackTime               (io_enq_0_bits_debugInfo_writebackTime),
    .io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id      (io_enq_0_bits_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_payload_debugInfo_tlbFirstReqTime             (io_enq_0_bits_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_payload_debugInfo_tlbRespTime                 (io_enq_0_bits_debugInfo_tlbRespTime),
    .io_enq_0_bits_payload_debug_seqNum_seqNum                   (io_enq_0_bits_debug_seqNum_seqNum),
    .io_enq_0_bits_payload_debug_seqNum_uopIdx                   (io_enq_0_bits_debug_seqNum_uopIdx),
    .io_enq_0_bits_payload_storeSetHit                           (io_enq_0_bits_storeSetHit),
    .io_enq_0_bits_payload_waitForRobIdx_flag                    (io_enq_0_bits_waitForRobIdx_flag),
    .io_enq_0_bits_payload_waitForRobIdx_value                   (io_enq_0_bits_waitForRobIdx_value),
    .io_enq_0_bits_payload_loadWaitBit                           (io_enq_0_bits_loadWaitBit),
    .io_enq_0_bits_payload_loadWaitStrict                        (io_enq_0_bits_loadWaitStrict),
    .io_enq_0_bits_payload_ssid                                  (io_enq_0_bits_ssid),
    .io_enq_0_bits_payload_lqIdx_flag                            (io_enq_0_bits_lqIdx_flag),
    .io_enq_0_bits_payload_lqIdx_value                           (io_enq_0_bits_lqIdx_value),
    .io_enq_0_bits_payload_sqIdx_flag                            (io_enq_0_bits_sqIdx_flag),
    .io_enq_0_bits_payload_sqIdx_value                           (io_enq_0_bits_sqIdx_value),
    .io_enq_0_bits_payload_singleStep                            (io_enq_0_bits_singleStep),
    .io_enq_0_bits_payload_replayInst                            (io_enq_0_bits_replayInst),
    .io_enq_0_bits_payload_debug_fuType                          (io_enq_0_bits_debug_fuType),
    .io_enq_0_bits_payload_debug_sim_trig                        (io_enq_0_bits_debug_sim_trig),
    .io_enq_0_bits_payload_numLsElem                             (io_enq_0_bits_numLsElem),
    .io_enq_1_valid                                              (core_enq_do[1]),
    .io_enq_1_bits_status_robIdx_flag                            (io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_status_robIdx_value                           (io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_status_fuType_19                              (io_enq_1_bits_fuType[19]),
    .io_enq_1_bits_status_fuType_24                              (io_enq_1_bits_fuType[24]),
    .io_enq_1_bits_status_fuType_25                              (io_enq_1_bits_fuType[25]),
    .io_enq_1_bits_status_srcStatus_0_psrc                       (io_enq_1_bits_psrc_0[6:0]),
    .io_enq_1_bits_status_srcStatus_0_srcType                    (io_enq_1_bits_srcType_0),
    .io_enq_1_bits_status_srcStatus_0_srcState                   (core_st_src_state[1][0]),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value          (core_st_data_src[1][0]),
    .io_enq_1_bits_status_srcStatus_1_psrc                       (io_enq_1_bits_psrc_1[6:0]),
    .io_enq_1_bits_status_srcStatus_1_srcType                    (io_enq_1_bits_srcType_1),
    .io_enq_1_bits_status_srcStatus_1_srcState                   (core_st_src_state[1][1]),
    .io_enq_1_bits_status_srcStatus_1_dataSources_value          (core_st_data_src[1][1]),
    .io_enq_1_bits_status_srcStatus_2_psrc                       (io_enq_1_bits_psrc_2[6:0]),
    .io_enq_1_bits_status_srcStatus_2_srcType                    (io_enq_1_bits_srcType_2),
    .io_enq_1_bits_status_srcStatus_2_srcState                   (core_st_src_state[1][2]),
    .io_enq_1_bits_status_srcStatus_2_dataSources_value          (core_st_data_src[1][2]),
    .io_enq_1_bits_status_srcStatus_3_psrc                       (io_enq_1_bits_psrc_3[6:0]),
    .io_enq_1_bits_status_srcStatus_3_srcType                    (io_enq_1_bits_srcType_3),
    .io_enq_1_bits_status_srcStatus_3_srcState                   (core_st_src_state[1][3]),
    .io_enq_1_bits_status_srcStatus_3_dataSources_value          (core_st_data_src[1][3]),
    .io_enq_1_bits_status_srcStatus_4_psrc                       (io_enq_1_bits_psrc_4[6:0]),
    .io_enq_1_bits_status_srcStatus_4_srcType                    (io_enq_1_bits_srcType_4),
    .io_enq_1_bits_status_srcStatus_4_srcState                   (core_st_src_state[1][4]),
    .io_enq_1_bits_status_srcStatus_4_dataSources_value          (core_st_data_src[1][4]),
    .io_enq_1_bits_payload_instr                                 (io_enq_1_bits_instr),
    .io_enq_1_bits_payload_pc                                    (io_enq_1_bits_pc),
    .io_enq_1_bits_payload_foldpc                                (io_enq_1_bits_foldpc),
    .io_enq_1_bits_payload_exceptionVec_0                        (io_enq_1_bits_exceptionVec_0),
    .io_enq_1_bits_payload_exceptionVec_1                        (io_enq_1_bits_exceptionVec_1),
    .io_enq_1_bits_payload_exceptionVec_2                        (io_enq_1_bits_exceptionVec_2),
    .io_enq_1_bits_payload_exceptionVec_3                        (io_enq_1_bits_exceptionVec_3),
    .io_enq_1_bits_payload_exceptionVec_4                        (io_enq_1_bits_exceptionVec_4),
    .io_enq_1_bits_payload_exceptionVec_5                        (io_enq_1_bits_exceptionVec_5),
    .io_enq_1_bits_payload_exceptionVec_6                        (io_enq_1_bits_exceptionVec_6),
    .io_enq_1_bits_payload_exceptionVec_7                        (io_enq_1_bits_exceptionVec_7),
    .io_enq_1_bits_payload_exceptionVec_8                        (io_enq_1_bits_exceptionVec_8),
    .io_enq_1_bits_payload_exceptionVec_9                        (io_enq_1_bits_exceptionVec_9),
    .io_enq_1_bits_payload_exceptionVec_10                       (io_enq_1_bits_exceptionVec_10),
    .io_enq_1_bits_payload_exceptionVec_11                       (io_enq_1_bits_exceptionVec_11),
    .io_enq_1_bits_payload_exceptionVec_12                       (io_enq_1_bits_exceptionVec_12),
    .io_enq_1_bits_payload_exceptionVec_13                       (io_enq_1_bits_exceptionVec_13),
    .io_enq_1_bits_payload_exceptionVec_14                       (io_enq_1_bits_exceptionVec_14),
    .io_enq_1_bits_payload_exceptionVec_15                       (io_enq_1_bits_exceptionVec_15),
    .io_enq_1_bits_payload_exceptionVec_16                       (io_enq_1_bits_exceptionVec_16),
    .io_enq_1_bits_payload_exceptionVec_17                       (io_enq_1_bits_exceptionVec_17),
    .io_enq_1_bits_payload_exceptionVec_18                       (io_enq_1_bits_exceptionVec_18),
    .io_enq_1_bits_payload_exceptionVec_19                       (io_enq_1_bits_exceptionVec_19),
    .io_enq_1_bits_payload_exceptionVec_20                       (io_enq_1_bits_exceptionVec_20),
    .io_enq_1_bits_payload_exceptionVec_21                       (io_enq_1_bits_exceptionVec_21),
    .io_enq_1_bits_payload_exceptionVec_22                       (io_enq_1_bits_exceptionVec_22),
    .io_enq_1_bits_payload_exceptionVec_23                       (io_enq_1_bits_exceptionVec_23),
    .io_enq_1_bits_payload_isFetchMalAddr                        (io_enq_1_bits_isFetchMalAddr),
    .io_enq_1_bits_payload_hasException                          (io_enq_1_bits_hasException),
    .io_enq_1_bits_payload_trigger                               (io_enq_1_bits_trigger),
    .io_enq_1_bits_payload_preDecodeInfo_valid                   (io_enq_1_bits_preDecodeInfo_valid),
    .io_enq_1_bits_payload_preDecodeInfo_isRVC                   (io_enq_1_bits_preDecodeInfo_isRVC),
    .io_enq_1_bits_payload_preDecodeInfo_brType                  (io_enq_1_bits_preDecodeInfo_brType),
    .io_enq_1_bits_payload_preDecodeInfo_isCall                  (io_enq_1_bits_preDecodeInfo_isCall),
    .io_enq_1_bits_payload_preDecodeInfo_isRet                   (io_enq_1_bits_preDecodeInfo_isRet),
    .io_enq_1_bits_payload_pred_taken                            (io_enq_1_bits_pred_taken),
    .io_enq_1_bits_payload_crossPageIPFFix                       (io_enq_1_bits_crossPageIPFFix),
    .io_enq_1_bits_payload_ftqPtr_flag                           (io_enq_1_bits_ftqPtr_flag),
    .io_enq_1_bits_payload_ftqPtr_value                          (io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_payload_ftqOffset                             (io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_payload_satpFlushFirstFetchFault              (io_enq_1_bits_satpFlushFirstFetchFault),
    .io_enq_1_bits_payload_srcType_0                             (io_enq_1_bits_srcType_0),
    .io_enq_1_bits_payload_srcType_1                             (io_enq_1_bits_srcType_1),
    .io_enq_1_bits_payload_srcType_2                             (io_enq_1_bits_srcType_2),
    .io_enq_1_bits_payload_srcType_3                             (io_enq_1_bits_srcType_3),
    .io_enq_1_bits_payload_srcType_4                             (io_enq_1_bits_srcType_4),
    .io_enq_1_bits_payload_ldest                                 (io_enq_1_bits_ldest),
    .io_enq_1_bits_payload_fuType                                (io_enq_1_bits_fuType),
    .io_enq_1_bits_payload_fuOpType                              (io_enq_1_bits_fuOpType),
    .io_enq_1_bits_payload_rfWen                                 (io_enq_1_bits_rfWen),
    .io_enq_1_bits_payload_fpWen                                 (io_enq_1_bits_fpWen),
    .io_enq_1_bits_payload_vecWen                                (io_enq_1_bits_vecWen),
    .io_enq_1_bits_payload_v0Wen                                 (io_enq_1_bits_v0Wen),
    .io_enq_1_bits_payload_vlWen                                 (io_enq_1_bits_vlWen),
    .io_enq_1_bits_payload_isXSTrap                              (io_enq_1_bits_isXSTrap),
    .io_enq_1_bits_payload_waitForward                           (io_enq_1_bits_waitForward),
    .io_enq_1_bits_payload_blockBackward                         (io_enq_1_bits_blockBackward),
    .io_enq_1_bits_payload_flushPipe                             (io_enq_1_bits_flushPipe),
    .io_enq_1_bits_payload_canRobCompress                        (io_enq_1_bits_canRobCompress),
    .io_enq_1_bits_payload_selImm                                (io_enq_1_bits_selImm),
    .io_enq_1_bits_payload_imm                                   (io_enq_1_bits_imm),
    .io_enq_1_bits_payload_fpu_typeTagOut                        (io_enq_1_bits_fpu_typeTagOut),
    .io_enq_1_bits_payload_fpu_wflags                            (io_enq_1_bits_fpu_wflags),
    .io_enq_1_bits_payload_fpu_typ                               (io_enq_1_bits_fpu_typ),
    .io_enq_1_bits_payload_fpu_fmt                               (io_enq_1_bits_fpu_fmt),
    .io_enq_1_bits_payload_fpu_rm                                (io_enq_1_bits_fpu_rm),
    .io_enq_1_bits_payload_vpu_vill                              (io_enq_1_bits_vpu_vill),
    .io_enq_1_bits_payload_vpu_vma                               (io_enq_1_bits_vpu_vma),
    .io_enq_1_bits_payload_vpu_vta                               (io_enq_1_bits_vpu_vta),
    .io_enq_1_bits_payload_vpu_vsew                              (io_enq_1_bits_vpu_vsew),
    .io_enq_1_bits_payload_vpu_vlmul                             (io_enq_1_bits_vpu_vlmul),
    .io_enq_1_bits_payload_vpu_specVill                          (io_enq_1_bits_vpu_specVill),
    .io_enq_1_bits_payload_vpu_specVma                           (io_enq_1_bits_vpu_specVma),
    .io_enq_1_bits_payload_vpu_specVta                           (io_enq_1_bits_vpu_specVta),
    .io_enq_1_bits_payload_vpu_specVsew                          (io_enq_1_bits_vpu_specVsew),
    .io_enq_1_bits_payload_vpu_specVlmul                         (io_enq_1_bits_vpu_specVlmul),
    .io_enq_1_bits_payload_vpu_vm                                (io_enq_1_bits_vpu_vm),
    .io_enq_1_bits_payload_vpu_vstart                            (io_enq_1_bits_vpu_vstart),
    .io_enq_1_bits_payload_vpu_frm                               (io_enq_1_bits_vpu_frm),
    .io_enq_1_bits_payload_vpu_fpu_isFpToVecInst                 (io_enq_1_bits_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_payload_vpu_fpu_isFP32Instr                   (io_enq_1_bits_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_payload_vpu_fpu_isFP64Instr                   (io_enq_1_bits_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_payload_vpu_fpu_isReduction                   (io_enq_1_bits_vpu_fpu_isReduction),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2                   (io_enq_1_bits_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4                   (io_enq_1_bits_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8                   (io_enq_1_bits_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_payload_vpu_vxrm                              (io_enq_1_bits_vpu_vxrm),
    .io_enq_1_bits_payload_vpu_vuopIdx                           (io_enq_1_bits_vpu_vuopIdx),
    .io_enq_1_bits_payload_vpu_lastUop                           (io_enq_1_bits_vpu_lastUop),
    .io_enq_1_bits_payload_vpu_vmask                             (io_enq_1_bits_vpu_vmask),
    .io_enq_1_bits_payload_vpu_vl                                (io_enq_1_bits_vpu_vl),
    .io_enq_1_bits_payload_vpu_nf                                (io_enq_1_bits_vpu_nf),
    .io_enq_1_bits_payload_vpu_veew                              (io_enq_1_bits_vpu_veew),
    .io_enq_1_bits_payload_vpu_isReverse                         (io_enq_1_bits_vpu_isReverse),
    .io_enq_1_bits_payload_vpu_isExt                             (io_enq_1_bits_vpu_isExt),
    .io_enq_1_bits_payload_vpu_isNarrow                          (io_enq_1_bits_vpu_isNarrow),
    .io_enq_1_bits_payload_vpu_isDstMask                         (io_enq_1_bits_vpu_isDstMask),
    .io_enq_1_bits_payload_vpu_isOpMask                          (io_enq_1_bits_vpu_isOpMask),
    .io_enq_1_bits_payload_vpu_isMove                            (io_enq_1_bits_vpu_isMove),
    .io_enq_1_bits_payload_vpu_isDependOldVd                     (io_enq_1_bits_vpu_isDependOldVd),
    .io_enq_1_bits_payload_vpu_isWritePartVd                     (io_enq_1_bits_vpu_isWritePartVd),
    .io_enq_1_bits_payload_vpu_isVleff                           (io_enq_1_bits_vpu_isVleff),
    .io_enq_1_bits_payload_vlsInstr                              (io_enq_1_bits_vlsInstr),
    .io_enq_1_bits_payload_wfflags                               (io_enq_1_bits_wfflags),
    .io_enq_1_bits_payload_isMove                                (io_enq_1_bits_isMove),
    .io_enq_1_bits_payload_isDropAmocasSta                       (io_enq_1_bits_isDropAmocasSta),
    .io_enq_1_bits_payload_uopIdx                                (io_enq_1_bits_uopIdx),
    .io_enq_1_bits_payload_isVset                                (io_enq_1_bits_isVset),
    .io_enq_1_bits_payload_firstUop                              (io_enq_1_bits_firstUop),
    .io_enq_1_bits_payload_lastUop                               (io_enq_1_bits_lastUop),
    .io_enq_1_bits_payload_numUops                               (io_enq_1_bits_numUops),
    .io_enq_1_bits_payload_numWB                                 (io_enq_1_bits_numWB),
    .io_enq_1_bits_payload_commitType                            (io_enq_1_bits_commitType),
    .io_enq_1_bits_payload_srcState_0                            (io_enq_1_bits_srcState_0),
    .io_enq_1_bits_payload_srcState_1                            (io_enq_1_bits_srcState_1),
    .io_enq_1_bits_payload_srcState_2                            (io_enq_1_bits_srcState_2),
    .io_enq_1_bits_payload_srcState_3                            (io_enq_1_bits_srcState_3),
    .io_enq_1_bits_payload_srcState_4                            (io_enq_1_bits_srcState_4),
    .io_enq_1_bits_payload_psrc_0                                (io_enq_1_bits_psrc_0),
    .io_enq_1_bits_payload_psrc_1                                (io_enq_1_bits_psrc_1),
    .io_enq_1_bits_payload_psrc_2                                (io_enq_1_bits_psrc_2),
    .io_enq_1_bits_payload_psrc_3                                (io_enq_1_bits_psrc_3),
    .io_enq_1_bits_payload_psrc_4                                (io_enq_1_bits_psrc_4),
    .io_enq_1_bits_payload_pdest                                 (io_enq_1_bits_pdest),
    .io_enq_1_bits_payload_useRegCache_0                         (io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_payload_useRegCache_1                         (io_enq_1_bits_useRegCache_1),
    .io_enq_1_bits_payload_regCacheIdx_0                         (io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_payload_regCacheIdx_1                         (io_enq_1_bits_regCacheIdx_1),
    .io_enq_1_bits_payload_robIdx_flag                           (io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_payload_robIdx_value                          (io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_payload_instrSize                             (io_enq_1_bits_instrSize),
    .io_enq_1_bits_payload_dirtyFs                               (io_enq_1_bits_dirtyFs),
    .io_enq_1_bits_payload_dirtyVs                               (io_enq_1_bits_dirtyVs),
    .io_enq_1_bits_payload_traceBlockInPipe_itype                (io_enq_1_bits_traceBlockInPipe_itype),
    .io_enq_1_bits_payload_traceBlockInPipe_iretire              (io_enq_1_bits_traceBlockInPipe_iretire),
    .io_enq_1_bits_payload_traceBlockInPipe_ilastsize            (io_enq_1_bits_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_payload_eliminatedMove                        (io_enq_1_bits_eliminatedMove),
    .io_enq_1_bits_payload_snapshot                              (io_enq_1_bits_snapshot),
    .io_enq_1_bits_payload_debugInfo_eliminatedMove              (io_enq_1_bits_debugInfo_eliminatedMove),
    .io_enq_1_bits_payload_debugInfo_renameTime                  (io_enq_1_bits_debugInfo_renameTime),
    .io_enq_1_bits_payload_debugInfo_dispatchTime                (io_enq_1_bits_debugInfo_dispatchTime),
    .io_enq_1_bits_payload_debugInfo_enqRsTime                   (io_enq_1_bits_debugInfo_enqRsTime),
    .io_enq_1_bits_payload_debugInfo_selectTime                  (io_enq_1_bits_debugInfo_selectTime),
    .io_enq_1_bits_payload_debugInfo_issueTime                   (io_enq_1_bits_debugInfo_issueTime),
    .io_enq_1_bits_payload_debugInfo_writebackTime               (io_enq_1_bits_debugInfo_writebackTime),
    .io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id      (io_enq_1_bits_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_payload_debugInfo_tlbFirstReqTime             (io_enq_1_bits_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_payload_debugInfo_tlbRespTime                 (io_enq_1_bits_debugInfo_tlbRespTime),
    .io_enq_1_bits_payload_debug_seqNum_seqNum                   (io_enq_1_bits_debug_seqNum_seqNum),
    .io_enq_1_bits_payload_debug_seqNum_uopIdx                   (io_enq_1_bits_debug_seqNum_uopIdx),
    .io_enq_1_bits_payload_storeSetHit                           (io_enq_1_bits_storeSetHit),
    .io_enq_1_bits_payload_waitForRobIdx_flag                    (io_enq_1_bits_waitForRobIdx_flag),
    .io_enq_1_bits_payload_waitForRobIdx_value                   (io_enq_1_bits_waitForRobIdx_value),
    .io_enq_1_bits_payload_loadWaitBit                           (io_enq_1_bits_loadWaitBit),
    .io_enq_1_bits_payload_loadWaitStrict                        (io_enq_1_bits_loadWaitStrict),
    .io_enq_1_bits_payload_ssid                                  (io_enq_1_bits_ssid),
    .io_enq_1_bits_payload_lqIdx_flag                            (io_enq_1_bits_lqIdx_flag),
    .io_enq_1_bits_payload_lqIdx_value                           (io_enq_1_bits_lqIdx_value),
    .io_enq_1_bits_payload_sqIdx_flag                            (io_enq_1_bits_sqIdx_flag),
    .io_enq_1_bits_payload_sqIdx_value                           (io_enq_1_bits_sqIdx_value),
    .io_enq_1_bits_payload_singleStep                            (io_enq_1_bits_singleStep),
    .io_enq_1_bits_payload_replayInst                            (io_enq_1_bits_replayInst),
    .io_enq_1_bits_payload_debug_fuType                          (io_enq_1_bits_debug_fuType),
    .io_enq_1_bits_payload_debug_sim_trig                        (io_enq_1_bits_debug_sim_trig),
    .io_enq_1_bits_payload_numLsElem                             (io_enq_1_bits_numLsElem),
    .io_og0Resp_0_valid                                          (io_og0Resp_0_valid),
    .io_og0Resp_1_valid                                          (io_og0Resp_1_valid),
    .io_og1Resp_0_valid                                          (io_og1Resp_0_valid),
    .io_og1Resp_1_valid                                          (io_og1Resp_1_valid),
    .io_og2Resp_0_valid                                          (io_og2Resp_0_valid),
    .io_og2Resp_0_bits_resp                                      (io_og2Resp_0_bits_resp),
    .io_og2Resp_1_valid                                          (io_og2Resp_1_valid),
    .io_og2Resp_1_bits_resp                                      (io_og2Resp_1_bits_resp),
    .io_deqReady_0                                               (1'h1),
    .io_deqReady_1                                               (1'h1),
    .io_deqSelOH_0_valid                                         (core_deq_valid[0]),
    .io_deqSelOH_0_bits                                          (core_sel_oh[0]),
    .io_deqSelOH_1_valid                                         (core_deq_valid[1]),
    .io_deqSelOH_1_bits                                          (core_sel_oh[1]),
    .io_enqEntryOldestSel_0_bits                                 (age_io_out_0),
    .io_enqEntryOldestSel_1_bits                                 (age_io_out_1),
    .io_simpEntryOldestSel_0_valid                               (core_simp_oldest_valid[0]),
    .io_simpEntryOldestSel_0_bits                                (age_1_io_out_0),
    .io_simpEntryOldestSel_1_valid                               (core_simp_oldest_valid[1]),
    .io_simpEntryOldestSel_1_bits                                (age_1_io_out_1),
    .io_compEntryOldestSel_0_valid                               (core_comp_oldest_valid[0]),
    .io_compEntryOldestSel_0_bits                                (age_2_io_out_0),
    .io_compEntryOldestSel_1_valid                               (core_comp_oldest_valid[1]),
    .io_compEntryOldestSel_1_bits                                (age_2_io_out_1),
    .io_wakeUpFromWB_15_valid                                    (io_wakeupFromWB_15_valid),
    .io_wakeUpFromWB_15_bits_vlWen                               (io_wakeupFromWB_15_bits_vlWen),
    .io_wakeUpFromWB_15_bits_pdest                               (io_wakeupFromWB_15_bits_pdest),
    .io_wakeUpFromWB_14_valid                                    (io_wakeupFromWB_14_valid),
    .io_wakeUpFromWB_14_bits_vlWen                               (io_wakeupFromWB_14_bits_vlWen),
    .io_wakeUpFromWB_14_bits_pdest                               (io_wakeupFromWB_14_bits_pdest),
    .io_wakeUpFromWB_13_valid                                    (io_wakeupFromWB_13_valid),
    .io_wakeUpFromWB_13_bits_vlWen                               (io_wakeupFromWB_13_bits_vlWen),
    .io_wakeUpFromWB_13_bits_pdest                               (io_wakeupFromWB_13_bits_pdest),
    .io_wakeUpFromWB_12_valid                                    (io_wakeupFromWB_12_valid),
    .io_wakeUpFromWB_12_bits_vlWen                               (io_wakeupFromWB_12_bits_vlWen),
    .io_wakeUpFromWB_12_bits_pdest                               (io_wakeupFromWB_12_bits_pdest),
    .io_wakeUpFromWB_11_valid                                    (io_wakeupFromWB_11_valid),
    .io_wakeUpFromWB_11_bits_v0Wen                               (io_wakeupFromWB_11_bits_v0Wen),
    .io_wakeUpFromWB_11_bits_pdest                               (io_wakeupFromWB_11_bits_pdest),
    .io_wakeUpFromWB_10_valid                                    (io_wakeupFromWB_10_valid),
    .io_wakeUpFromWB_10_bits_v0Wen                               (io_wakeupFromWB_10_bits_v0Wen),
    .io_wakeUpFromWB_10_bits_pdest                               (io_wakeupFromWB_10_bits_pdest),
    .io_wakeUpFromWB_9_valid                                     (io_wakeupFromWB_9_valid),
    .io_wakeUpFromWB_9_bits_v0Wen                                (io_wakeupFromWB_9_bits_v0Wen),
    .io_wakeUpFromWB_9_bits_pdest                                (io_wakeupFromWB_9_bits_pdest),
    .io_wakeUpFromWB_8_valid                                     (io_wakeupFromWB_8_valid),
    .io_wakeUpFromWB_8_bits_v0Wen                                (io_wakeupFromWB_8_bits_v0Wen),
    .io_wakeUpFromWB_8_bits_pdest                                (io_wakeupFromWB_8_bits_pdest),
    .io_wakeUpFromWB_7_valid                                     (io_wakeupFromWB_7_valid),
    .io_wakeUpFromWB_7_bits_v0Wen                                (io_wakeupFromWB_7_bits_v0Wen),
    .io_wakeUpFromWB_7_bits_pdest                                (io_wakeupFromWB_7_bits_pdest),
    .io_wakeUpFromWB_6_valid                                     (io_wakeupFromWB_6_valid),
    .io_wakeUpFromWB_6_bits_v0Wen                                (io_wakeupFromWB_6_bits_v0Wen),
    .io_wakeUpFromWB_6_bits_pdest                                (io_wakeupFromWB_6_bits_pdest),
    .io_wakeUpFromWB_5_valid                                     (io_wakeupFromWB_5_valid),
    .io_wakeUpFromWB_5_bits_vecWen                               (io_wakeupFromWB_5_bits_vecWen),
    .io_wakeUpFromWB_5_bits_pdest                                (io_wakeupFromWB_5_bits_pdest),
    .io_wakeUpFromWB_4_valid                                     (io_wakeupFromWB_4_valid),
    .io_wakeUpFromWB_4_bits_vecWen                               (io_wakeupFromWB_4_bits_vecWen),
    .io_wakeUpFromWB_4_bits_pdest                                (io_wakeupFromWB_4_bits_pdest),
    .io_wakeUpFromWB_3_valid                                     (io_wakeupFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_vecWen                               (io_wakeupFromWB_3_bits_vecWen),
    .io_wakeUpFromWB_3_bits_pdest                                (io_wakeupFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid                                     (io_wakeupFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_vecWen                               (io_wakeupFromWB_2_bits_vecWen),
    .io_wakeUpFromWB_2_bits_pdest                                (io_wakeupFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid                                     (io_wakeupFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_vecWen                               (io_wakeupFromWB_1_bits_vecWen),
    .io_wakeUpFromWB_1_bits_pdest                                (io_wakeupFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid                                     (io_wakeupFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_vecWen                               (io_wakeupFromWB_0_bits_vecWen),
    .io_wakeUpFromWB_0_bits_pdest                                (io_wakeupFromWB_0_bits_pdest),
    .io_wakeUpFromWBDelayed_15_valid                             (io_wakeupFromWBDelayed_15_valid),
    .io_wakeUpFromWBDelayed_15_bits_vlWen                        (io_wakeupFromWBDelayed_15_bits_vlWen),
    .io_wakeUpFromWBDelayed_15_bits_pdest                        (io_wakeupFromWBDelayed_15_bits_pdest),
    .io_wakeUpFromWBDelayed_14_valid                             (io_wakeupFromWBDelayed_14_valid),
    .io_wakeUpFromWBDelayed_14_bits_vlWen                        (io_wakeupFromWBDelayed_14_bits_vlWen),
    .io_wakeUpFromWBDelayed_14_bits_pdest                        (io_wakeupFromWBDelayed_14_bits_pdest),
    .io_wakeUpFromWBDelayed_13_valid                             (io_wakeupFromWBDelayed_13_valid),
    .io_wakeUpFromWBDelayed_13_bits_vlWen                        (io_wakeupFromWBDelayed_13_bits_vlWen),
    .io_wakeUpFromWBDelayed_13_bits_pdest                        (io_wakeupFromWBDelayed_13_bits_pdest),
    .io_wakeUpFromWBDelayed_12_valid                             (io_wakeupFromWBDelayed_12_valid),
    .io_wakeUpFromWBDelayed_12_bits_vlWen                        (io_wakeupFromWBDelayed_12_bits_vlWen),
    .io_wakeUpFromWBDelayed_12_bits_pdest                        (io_wakeupFromWBDelayed_12_bits_pdest),
    .io_wakeUpFromWBDelayed_11_valid                             (io_wakeupFromWBDelayed_11_valid),
    .io_wakeUpFromWBDelayed_11_bits_v0Wen                        (io_wakeupFromWBDelayed_11_bits_v0Wen),
    .io_wakeUpFromWBDelayed_11_bits_pdest                        (io_wakeupFromWBDelayed_11_bits_pdest),
    .io_wakeUpFromWBDelayed_10_valid                             (io_wakeupFromWBDelayed_10_valid),
    .io_wakeUpFromWBDelayed_10_bits_v0Wen                        (io_wakeupFromWBDelayed_10_bits_v0Wen),
    .io_wakeUpFromWBDelayed_10_bits_pdest                        (io_wakeupFromWBDelayed_10_bits_pdest),
    .io_wakeUpFromWBDelayed_9_valid                              (io_wakeupFromWBDelayed_9_valid),
    .io_wakeUpFromWBDelayed_9_bits_v0Wen                         (io_wakeupFromWBDelayed_9_bits_v0Wen),
    .io_wakeUpFromWBDelayed_9_bits_pdest                         (io_wakeupFromWBDelayed_9_bits_pdest),
    .io_wakeUpFromWBDelayed_8_valid                              (io_wakeupFromWBDelayed_8_valid),
    .io_wakeUpFromWBDelayed_8_bits_v0Wen                         (io_wakeupFromWBDelayed_8_bits_v0Wen),
    .io_wakeUpFromWBDelayed_8_bits_pdest                         (io_wakeupFromWBDelayed_8_bits_pdest),
    .io_wakeUpFromWBDelayed_7_valid                              (io_wakeupFromWBDelayed_7_valid),
    .io_wakeUpFromWBDelayed_7_bits_v0Wen                         (io_wakeupFromWBDelayed_7_bits_v0Wen),
    .io_wakeUpFromWBDelayed_7_bits_pdest                         (io_wakeupFromWBDelayed_7_bits_pdest),
    .io_wakeUpFromWBDelayed_6_valid                              (io_wakeupFromWBDelayed_6_valid),
    .io_wakeUpFromWBDelayed_6_bits_v0Wen                         (io_wakeupFromWBDelayed_6_bits_v0Wen),
    .io_wakeUpFromWBDelayed_6_bits_pdest                         (io_wakeupFromWBDelayed_6_bits_pdest),
    .io_wakeUpFromWBDelayed_5_valid                              (io_wakeupFromWBDelayed_5_valid),
    .io_wakeUpFromWBDelayed_5_bits_vecWen                        (io_wakeupFromWBDelayed_5_bits_vecWen),
    .io_wakeUpFromWBDelayed_5_bits_pdest                         (io_wakeupFromWBDelayed_5_bits_pdest),
    .io_wakeUpFromWBDelayed_4_valid                              (io_wakeupFromWBDelayed_4_valid),
    .io_wakeUpFromWBDelayed_4_bits_vecWen                        (io_wakeupFromWBDelayed_4_bits_vecWen),
    .io_wakeUpFromWBDelayed_4_bits_pdest                         (io_wakeupFromWBDelayed_4_bits_pdest),
    .io_wakeUpFromWBDelayed_3_valid                              (io_wakeupFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_vecWen                        (io_wakeupFromWBDelayed_3_bits_vecWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest                         (io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid                              (io_wakeupFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_vecWen                        (io_wakeupFromWBDelayed_2_bits_vecWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest                         (io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid                              (io_wakeupFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_vecWen                        (io_wakeupFromWBDelayed_1_bits_vecWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest                         (io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid                              (io_wakeupFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_vecWen                        (io_wakeupFromWBDelayed_0_bits_vecWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest                         (io_wakeupFromWBDelayed_0_bits_pdest),
    .io_vlFromIntIsZero                                          (io_vlFromIntIsZero),
    .io_vlFromIntIsVlmax                                         (io_vlFromIntIsVlmax),
    .io_vlFromVfIsZero                                           (io_vlFromVfIsZero),
    .io_vlFromVfIsVlmax                                          (io_vlFromVfIsVlmax),
    .io_valid                                                    (entries_io_valid),
    .io_issued                                                   (entries_io_issued),
    .io_canIssue                                                 (entries_io_canIssue),
    .io_fuType_0                                                 (entries_io_fuType_0),
    .io_fuType_1                                                 (entries_io_fuType_1),
    .io_fuType_2                                                 (entries_io_fuType_2),
    .io_fuType_3                                                 (entries_io_fuType_3),
    .io_fuType_4                                                 (entries_io_fuType_4),
    .io_fuType_5                                                 (entries_io_fuType_5),
    .io_fuType_6                                                 (entries_io_fuType_6),
    .io_fuType_7                                                 (entries_io_fuType_7),
    .io_fuType_8                                                 (entries_io_fuType_8),
    .io_fuType_9                                                 (entries_io_fuType_9),
    .io_fuType_10                                                (entries_io_fuType_10),
    .io_fuType_11                                                (entries_io_fuType_11),
    .io_fuType_12                                                (entries_io_fuType_12),
    .io_fuType_13                                                (entries_io_fuType_13),
    .io_fuType_14                                                (entries_io_fuType_14),
    .io_fuType_15                                                (entries_io_fuType_15),
    .io_dataSources_0_0_value                                    (entries_io_dataSources_0_0_value),
    .io_dataSources_0_1_value                                    (entries_io_dataSources_0_1_value),
    .io_dataSources_0_2_value                                    (entries_io_dataSources_0_2_value),
    .io_dataSources_0_3_value                                    (entries_io_dataSources_0_3_value),
    .io_dataSources_0_4_value                                    (entries_io_dataSources_0_4_value),
    .io_dataSources_1_0_value                                    (entries_io_dataSources_1_0_value),
    .io_dataSources_1_1_value                                    (entries_io_dataSources_1_1_value),
    .io_dataSources_1_2_value                                    (entries_io_dataSources_1_2_value),
    .io_dataSources_1_3_value                                    (entries_io_dataSources_1_3_value),
    .io_dataSources_1_4_value                                    (entries_io_dataSources_1_4_value),
    .io_dataSources_2_0_value                                    (entries_io_dataSources_2_0_value),
    .io_dataSources_2_1_value                                    (entries_io_dataSources_2_1_value),
    .io_dataSources_2_2_value                                    (entries_io_dataSources_2_2_value),
    .io_dataSources_2_3_value                                    (entries_io_dataSources_2_3_value),
    .io_dataSources_2_4_value                                    (entries_io_dataSources_2_4_value),
    .io_dataSources_3_0_value                                    (entries_io_dataSources_3_0_value),
    .io_dataSources_3_1_value                                    (entries_io_dataSources_3_1_value),
    .io_dataSources_3_2_value                                    (entries_io_dataSources_3_2_value),
    .io_dataSources_3_3_value                                    (entries_io_dataSources_3_3_value),
    .io_dataSources_3_4_value                                    (entries_io_dataSources_3_4_value),
    .io_dataSources_4_0_value                                    (entries_io_dataSources_4_0_value),
    .io_dataSources_4_1_value                                    (entries_io_dataSources_4_1_value),
    .io_dataSources_4_2_value                                    (entries_io_dataSources_4_2_value),
    .io_dataSources_4_3_value                                    (entries_io_dataSources_4_3_value),
    .io_dataSources_4_4_value                                    (entries_io_dataSources_4_4_value),
    .io_dataSources_5_0_value                                    (entries_io_dataSources_5_0_value),
    .io_dataSources_5_1_value                                    (entries_io_dataSources_5_1_value),
    .io_dataSources_5_2_value                                    (entries_io_dataSources_5_2_value),
    .io_dataSources_5_3_value                                    (entries_io_dataSources_5_3_value),
    .io_dataSources_5_4_value                                    (entries_io_dataSources_5_4_value),
    .io_dataSources_6_0_value                                    (entries_io_dataSources_6_0_value),
    .io_dataSources_6_1_value                                    (entries_io_dataSources_6_1_value),
    .io_dataSources_6_2_value                                    (entries_io_dataSources_6_2_value),
    .io_dataSources_6_3_value                                    (entries_io_dataSources_6_3_value),
    .io_dataSources_6_4_value                                    (entries_io_dataSources_6_4_value),
    .io_dataSources_7_0_value                                    (entries_io_dataSources_7_0_value),
    .io_dataSources_7_1_value                                    (entries_io_dataSources_7_1_value),
    .io_dataSources_7_2_value                                    (entries_io_dataSources_7_2_value),
    .io_dataSources_7_3_value                                    (entries_io_dataSources_7_3_value),
    .io_dataSources_7_4_value                                    (entries_io_dataSources_7_4_value),
    .io_dataSources_8_0_value                                    (entries_io_dataSources_8_0_value),
    .io_dataSources_8_1_value                                    (entries_io_dataSources_8_1_value),
    .io_dataSources_8_2_value                                    (entries_io_dataSources_8_2_value),
    .io_dataSources_8_3_value                                    (entries_io_dataSources_8_3_value),
    .io_dataSources_8_4_value                                    (entries_io_dataSources_8_4_value),
    .io_dataSources_9_0_value                                    (entries_io_dataSources_9_0_value),
    .io_dataSources_9_1_value                                    (entries_io_dataSources_9_1_value),
    .io_dataSources_9_2_value                                    (entries_io_dataSources_9_2_value),
    .io_dataSources_9_3_value                                    (entries_io_dataSources_9_3_value),
    .io_dataSources_9_4_value                                    (entries_io_dataSources_9_4_value),
    .io_dataSources_10_0_value                                   (entries_io_dataSources_10_0_value),
    .io_dataSources_10_1_value                                   (entries_io_dataSources_10_1_value),
    .io_dataSources_10_2_value                                   (entries_io_dataSources_10_2_value),
    .io_dataSources_10_3_value                                   (entries_io_dataSources_10_3_value),
    .io_dataSources_10_4_value                                   (entries_io_dataSources_10_4_value),
    .io_dataSources_11_0_value                                   (entries_io_dataSources_11_0_value),
    .io_dataSources_11_1_value                                   (entries_io_dataSources_11_1_value),
    .io_dataSources_11_2_value                                   (entries_io_dataSources_11_2_value),
    .io_dataSources_11_3_value                                   (entries_io_dataSources_11_3_value),
    .io_dataSources_11_4_value                                   (entries_io_dataSources_11_4_value),
    .io_dataSources_12_0_value                                   (entries_io_dataSources_12_0_value),
    .io_dataSources_12_1_value                                   (entries_io_dataSources_12_1_value),
    .io_dataSources_12_2_value                                   (entries_io_dataSources_12_2_value),
    .io_dataSources_12_3_value                                   (entries_io_dataSources_12_3_value),
    .io_dataSources_12_4_value                                   (entries_io_dataSources_12_4_value),
    .io_dataSources_13_0_value                                   (entries_io_dataSources_13_0_value),
    .io_dataSources_13_1_value                                   (entries_io_dataSources_13_1_value),
    .io_dataSources_13_2_value                                   (entries_io_dataSources_13_2_value),
    .io_dataSources_13_3_value                                   (entries_io_dataSources_13_3_value),
    .io_dataSources_13_4_value                                   (entries_io_dataSources_13_4_value),
    .io_dataSources_14_0_value                                   (entries_io_dataSources_14_0_value),
    .io_dataSources_14_1_value                                   (entries_io_dataSources_14_1_value),
    .io_dataSources_14_2_value                                   (entries_io_dataSources_14_2_value),
    .io_dataSources_14_3_value                                   (entries_io_dataSources_14_3_value),
    .io_dataSources_14_4_value                                   (entries_io_dataSources_14_4_value),
    .io_dataSources_15_0_value                                   (entries_io_dataSources_15_0_value),
    .io_dataSources_15_1_value                                   (entries_io_dataSources_15_1_value),
    .io_dataSources_15_2_value                                   (entries_io_dataSources_15_2_value),
    .io_dataSources_15_3_value                                   (entries_io_dataSources_15_3_value),
    .io_dataSources_15_4_value                                   (entries_io_dataSources_15_4_value),
    .io_isFirstIssue_0                                           (entries_io_isFirstIssue_0),
    .io_isFirstIssue_1                                           (entries_io_isFirstIssue_1),
    .io_deqEntry_0_bits_status_robIdx_flag                       (entries_io_deqEntry_0_bits_status_robIdx_flag),
    .io_deqEntry_0_bits_status_robIdx_value                      (entries_io_deqEntry_0_bits_status_robIdx_value),
    .io_deqEntry_0_bits_status_fuType_19                         (entries_io_deqEntry_0_bits_status_fuType_19),
    .io_deqEntry_0_bits_status_fuType_24                         (entries_io_deqEntry_0_bits_status_fuType_24),
    .io_deqEntry_0_bits_status_fuType_25                         (entries_io_deqEntry_0_bits_status_fuType_25),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_0_psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_0_srcType),
    .io_deqEntry_0_bits_status_srcStatus_1_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_1_psrc),
    .io_deqEntry_0_bits_status_srcStatus_1_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_1_srcType),
    .io_deqEntry_0_bits_status_srcStatus_2_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_2_psrc),
    .io_deqEntry_0_bits_status_srcStatus_2_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_2_srcType),
    .io_deqEntry_0_bits_status_srcStatus_3_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_3_psrc),
    .io_deqEntry_0_bits_status_srcStatus_3_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_3_srcType),
    .io_deqEntry_0_bits_status_srcStatus_4_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_4_psrc),
    .io_deqEntry_0_bits_status_srcStatus_4_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_4_srcType),
    .io_deqEntry_0_bits_payload_fuOpType                         (entries_io_deqEntry_0_bits_payload_fuOpType),
    .io_deqEntry_0_bits_payload_vecWen                           (entries_io_deqEntry_0_bits_payload_vecWen),
    .io_deqEntry_0_bits_payload_v0Wen                            (entries_io_deqEntry_0_bits_payload_v0Wen),
    .io_deqEntry_0_bits_payload_selImm                           (entries_io_deqEntry_0_bits_payload_selImm),
    .io_deqEntry_0_bits_payload_fpu_typeTagOut                   (entries_io_deqEntry_0_bits_payload_fpu_typeTagOut),
    .io_deqEntry_0_bits_payload_fpu_wflags                       (entries_io_deqEntry_0_bits_payload_fpu_wflags),
    .io_deqEntry_0_bits_payload_fpu_typ                          (entries_io_deqEntry_0_bits_payload_fpu_typ),
    .io_deqEntry_0_bits_payload_fpu_fmt                          (entries_io_deqEntry_0_bits_payload_fpu_fmt),
    .io_deqEntry_0_bits_payload_fpu_rm                           (entries_io_deqEntry_0_bits_payload_fpu_rm),
    .io_deqEntry_0_bits_payload_vpu_vill                         (entries_io_deqEntry_0_bits_payload_vpu_vill),
    .io_deqEntry_0_bits_payload_vpu_vma                          (entries_io_deqEntry_0_bits_payload_vpu_vma),
    .io_deqEntry_0_bits_payload_vpu_vta                          (entries_io_deqEntry_0_bits_payload_vpu_vta),
    .io_deqEntry_0_bits_payload_vpu_vsew                         (entries_io_deqEntry_0_bits_payload_vpu_vsew),
    .io_deqEntry_0_bits_payload_vpu_vlmul                        (entries_io_deqEntry_0_bits_payload_vpu_vlmul),
    .io_deqEntry_0_bits_payload_vpu_specVill                     (entries_io_deqEntry_0_bits_payload_vpu_specVill),
    .io_deqEntry_0_bits_payload_vpu_specVma                      (entries_io_deqEntry_0_bits_payload_vpu_specVma),
    .io_deqEntry_0_bits_payload_vpu_specVta                      (entries_io_deqEntry_0_bits_payload_vpu_specVta),
    .io_deqEntry_0_bits_payload_vpu_specVsew                     (entries_io_deqEntry_0_bits_payload_vpu_specVsew),
    .io_deqEntry_0_bits_payload_vpu_specVlmul                    (entries_io_deqEntry_0_bits_payload_vpu_specVlmul),
    .io_deqEntry_0_bits_payload_vpu_vm                           (entries_io_deqEntry_0_bits_payload_vpu_vm),
    .io_deqEntry_0_bits_payload_vpu_vstart                       (entries_io_deqEntry_0_bits_payload_vpu_vstart),
    .io_deqEntry_0_bits_payload_vpu_frm                          (entries_io_deqEntry_0_bits_payload_vpu_frm),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst            (entries_io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr              (entries_io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr              (entries_io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr),
    .io_deqEntry_0_bits_payload_vpu_fpu_isReduction              (entries_io_deqEntry_0_bits_payload_vpu_fpu_isReduction),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2              (entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4              (entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8              (entries_io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_deqEntry_0_bits_payload_vpu_vxrm                         (entries_io_deqEntry_0_bits_payload_vpu_vxrm),
    .io_deqEntry_0_bits_payload_vpu_vmask                        (entries_io_deqEntry_0_bits_payload_vpu_vmask),
    .io_deqEntry_0_bits_payload_vpu_vl                           (entries_io_deqEntry_0_bits_payload_vpu_vl),
    .io_deqEntry_0_bits_payload_vpu_nf                           (entries_io_deqEntry_0_bits_payload_vpu_nf),
    .io_deqEntry_0_bits_payload_vpu_veew                         (entries_io_deqEntry_0_bits_payload_vpu_veew),
    .io_deqEntry_0_bits_payload_vpu_isReverse                    (entries_io_deqEntry_0_bits_payload_vpu_isReverse),
    .io_deqEntry_0_bits_payload_vpu_isExt                        (entries_io_deqEntry_0_bits_payload_vpu_isExt),
    .io_deqEntry_0_bits_payload_vpu_isNarrow                     (entries_io_deqEntry_0_bits_payload_vpu_isNarrow),
    .io_deqEntry_0_bits_payload_vpu_isDstMask                    (entries_io_deqEntry_0_bits_payload_vpu_isDstMask),
    .io_deqEntry_0_bits_payload_vpu_isOpMask                     (entries_io_deqEntry_0_bits_payload_vpu_isOpMask),
    .io_deqEntry_0_bits_payload_vpu_isMove                       (entries_io_deqEntry_0_bits_payload_vpu_isMove),
    .io_deqEntry_0_bits_payload_vpu_isDependOldVd                (entries_io_deqEntry_0_bits_payload_vpu_isDependOldVd),
    .io_deqEntry_0_bits_payload_vpu_isWritePartVd                (entries_io_deqEntry_0_bits_payload_vpu_isWritePartVd),
    .io_deqEntry_0_bits_payload_vpu_isVleff                      (entries_io_deqEntry_0_bits_payload_vpu_isVleff),
    .io_deqEntry_0_bits_payload_uopIdx                           (entries_io_deqEntry_0_bits_payload_uopIdx),
    .io_deqEntry_0_bits_payload_lastUop                          (entries_io_deqEntry_0_bits_payload_lastUop),
    .io_deqEntry_0_bits_payload_pdest                            (entries_io_deqEntry_0_bits_payload_pdest),
    .io_deqEntry_0_bits_payload_debugInfo_eliminatedMove         (entries_io_deqEntry_0_bits_payload_debugInfo_eliminatedMove),
    .io_deqEntry_0_bits_payload_debugInfo_renameTime             (entries_io_deqEntry_0_bits_payload_debugInfo_renameTime),
    .io_deqEntry_0_bits_payload_debugInfo_dispatchTime           (entries_io_deqEntry_0_bits_payload_debugInfo_dispatchTime),
    .io_deqEntry_0_bits_payload_debugInfo_enqRsTime              (entries_io_deqEntry_0_bits_payload_debugInfo_enqRsTime),
    .io_deqEntry_0_bits_payload_debugInfo_writebackTime          (entries_io_deqEntry_0_bits_payload_debugInfo_writebackTime),
    .io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id (entries_io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime        (entries_io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime),
    .io_deqEntry_0_bits_payload_debugInfo_tlbRespTime            (entries_io_deqEntry_0_bits_payload_debugInfo_tlbRespTime),
    .io_deqEntry_0_bits_payload_debug_seqNum_seqNum              (entries_io_deqEntry_0_bits_payload_debug_seqNum_seqNum),
    .io_deqEntry_0_bits_payload_debug_seqNum_uopIdx              (entries_io_deqEntry_0_bits_payload_debug_seqNum_uopIdx),
    .io_deqEntry_1_bits_status_robIdx_flag                       (entries_io_deqEntry_1_bits_status_robIdx_flag),
    .io_deqEntry_1_bits_status_robIdx_value                      (entries_io_deqEntry_1_bits_status_robIdx_value),
    .io_deqEntry_1_bits_status_fuType_19                         (entries_io_deqEntry_1_bits_status_fuType_19),
    .io_deqEntry_1_bits_status_fuType_24                         (entries_io_deqEntry_1_bits_status_fuType_24),
    .io_deqEntry_1_bits_status_fuType_25                         (entries_io_deqEntry_1_bits_status_fuType_25),
    .io_deqEntry_1_bits_status_srcStatus_0_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_0_psrc),
    .io_deqEntry_1_bits_status_srcStatus_0_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_0_srcType),
    .io_deqEntry_1_bits_status_srcStatus_1_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_1_psrc),
    .io_deqEntry_1_bits_status_srcStatus_1_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_1_srcType),
    .io_deqEntry_1_bits_status_srcStatus_2_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_2_psrc),
    .io_deqEntry_1_bits_status_srcStatus_2_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_2_srcType),
    .io_deqEntry_1_bits_status_srcStatus_3_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_3_psrc),
    .io_deqEntry_1_bits_status_srcStatus_3_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_3_srcType),
    .io_deqEntry_1_bits_status_srcStatus_4_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_4_psrc),
    .io_deqEntry_1_bits_status_srcStatus_4_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_4_srcType),
    .io_deqEntry_1_bits_payload_fuOpType                         (entries_io_deqEntry_1_bits_payload_fuOpType),
    .io_deqEntry_1_bits_payload_fpWen                            (entries_io_deqEntry_1_bits_payload_fpWen),
    .io_deqEntry_1_bits_payload_vecWen                           (entries_io_deqEntry_1_bits_payload_vecWen),
    .io_deqEntry_1_bits_payload_v0Wen                            (entries_io_deqEntry_1_bits_payload_v0Wen),
    .io_deqEntry_1_bits_payload_selImm                           (entries_io_deqEntry_1_bits_payload_selImm),
    .io_deqEntry_1_bits_payload_fpu_typeTagOut                   (entries_io_deqEntry_1_bits_payload_fpu_typeTagOut),
    .io_deqEntry_1_bits_payload_fpu_wflags                       (entries_io_deqEntry_1_bits_payload_fpu_wflags),
    .io_deqEntry_1_bits_payload_fpu_typ                          (entries_io_deqEntry_1_bits_payload_fpu_typ),
    .io_deqEntry_1_bits_payload_fpu_fmt                          (entries_io_deqEntry_1_bits_payload_fpu_fmt),
    .io_deqEntry_1_bits_payload_fpu_rm                           (entries_io_deqEntry_1_bits_payload_fpu_rm),
    .io_deqEntry_1_bits_payload_vpu_vill                         (entries_io_deqEntry_1_bits_payload_vpu_vill),
    .io_deqEntry_1_bits_payload_vpu_vma                          (entries_io_deqEntry_1_bits_payload_vpu_vma),
    .io_deqEntry_1_bits_payload_vpu_vta                          (entries_io_deqEntry_1_bits_payload_vpu_vta),
    .io_deqEntry_1_bits_payload_vpu_vsew                         (entries_io_deqEntry_1_bits_payload_vpu_vsew),
    .io_deqEntry_1_bits_payload_vpu_vlmul                        (entries_io_deqEntry_1_bits_payload_vpu_vlmul),
    .io_deqEntry_1_bits_payload_vpu_specVill                     (entries_io_deqEntry_1_bits_payload_vpu_specVill),
    .io_deqEntry_1_bits_payload_vpu_specVma                      (entries_io_deqEntry_1_bits_payload_vpu_specVma),
    .io_deqEntry_1_bits_payload_vpu_specVta                      (entries_io_deqEntry_1_bits_payload_vpu_specVta),
    .io_deqEntry_1_bits_payload_vpu_specVsew                     (entries_io_deqEntry_1_bits_payload_vpu_specVsew),
    .io_deqEntry_1_bits_payload_vpu_specVlmul                    (entries_io_deqEntry_1_bits_payload_vpu_specVlmul),
    .io_deqEntry_1_bits_payload_vpu_vm                           (entries_io_deqEntry_1_bits_payload_vpu_vm),
    .io_deqEntry_1_bits_payload_vpu_vstart                       (entries_io_deqEntry_1_bits_payload_vpu_vstart),
    .io_deqEntry_1_bits_payload_vpu_frm                          (entries_io_deqEntry_1_bits_payload_vpu_frm),
    .io_deqEntry_1_bits_payload_vpu_fpu_isFpToVecInst            (entries_io_deqEntry_1_bits_payload_vpu_fpu_isFpToVecInst),
    .io_deqEntry_1_bits_payload_vpu_fpu_isFP32Instr              (entries_io_deqEntry_1_bits_payload_vpu_fpu_isFP32Instr),
    .io_deqEntry_1_bits_payload_vpu_fpu_isFP64Instr              (entries_io_deqEntry_1_bits_payload_vpu_fpu_isFP64Instr),
    .io_deqEntry_1_bits_payload_vpu_fpu_isReduction              (entries_io_deqEntry_1_bits_payload_vpu_fpu_isReduction),
    .io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_2              (entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_2),
    .io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_4              (entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_4),
    .io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_8              (entries_io_deqEntry_1_bits_payload_vpu_fpu_isFoldTo1_8),
    .io_deqEntry_1_bits_payload_vpu_vxrm                         (entries_io_deqEntry_1_bits_payload_vpu_vxrm),
    .io_deqEntry_1_bits_payload_vpu_vmask                        (entries_io_deqEntry_1_bits_payload_vpu_vmask),
    .io_deqEntry_1_bits_payload_vpu_vl                           (entries_io_deqEntry_1_bits_payload_vpu_vl),
    .io_deqEntry_1_bits_payload_vpu_nf                           (entries_io_deqEntry_1_bits_payload_vpu_nf),
    .io_deqEntry_1_bits_payload_vpu_veew                         (entries_io_deqEntry_1_bits_payload_vpu_veew),
    .io_deqEntry_1_bits_payload_vpu_isReverse                    (entries_io_deqEntry_1_bits_payload_vpu_isReverse),
    .io_deqEntry_1_bits_payload_vpu_isExt                        (entries_io_deqEntry_1_bits_payload_vpu_isExt),
    .io_deqEntry_1_bits_payload_vpu_isNarrow                     (entries_io_deqEntry_1_bits_payload_vpu_isNarrow),
    .io_deqEntry_1_bits_payload_vpu_isDstMask                    (entries_io_deqEntry_1_bits_payload_vpu_isDstMask),
    .io_deqEntry_1_bits_payload_vpu_isOpMask                     (entries_io_deqEntry_1_bits_payload_vpu_isOpMask),
    .io_deqEntry_1_bits_payload_vpu_isMove                       (entries_io_deqEntry_1_bits_payload_vpu_isMove),
    .io_deqEntry_1_bits_payload_vpu_isDependOldVd                (entries_io_deqEntry_1_bits_payload_vpu_isDependOldVd),
    .io_deqEntry_1_bits_payload_vpu_isWritePartVd                (entries_io_deqEntry_1_bits_payload_vpu_isWritePartVd),
    .io_deqEntry_1_bits_payload_vpu_isVleff                      (entries_io_deqEntry_1_bits_payload_vpu_isVleff),
    .io_deqEntry_1_bits_payload_uopIdx                           (entries_io_deqEntry_1_bits_payload_uopIdx),
    .io_deqEntry_1_bits_payload_lastUop                          (entries_io_deqEntry_1_bits_payload_lastUop),
    .io_deqEntry_1_bits_payload_pdest                            (entries_io_deqEntry_1_bits_payload_pdest),
    .io_deqEntry_1_bits_payload_debugInfo_eliminatedMove         (entries_io_deqEntry_1_bits_payload_debugInfo_eliminatedMove),
    .io_deqEntry_1_bits_payload_debugInfo_renameTime             (entries_io_deqEntry_1_bits_payload_debugInfo_renameTime),
    .io_deqEntry_1_bits_payload_debugInfo_dispatchTime           (entries_io_deqEntry_1_bits_payload_debugInfo_dispatchTime),
    .io_deqEntry_1_bits_payload_debugInfo_enqRsTime              (entries_io_deqEntry_1_bits_payload_debugInfo_enqRsTime),
    .io_deqEntry_1_bits_payload_debugInfo_writebackTime          (entries_io_deqEntry_1_bits_payload_debugInfo_writebackTime),
    .io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id (entries_io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id),
    .io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime        (entries_io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime),
    .io_deqEntry_1_bits_payload_debugInfo_tlbRespTime            (entries_io_deqEntry_1_bits_payload_debugInfo_tlbRespTime),
    .io_deqEntry_1_bits_payload_debug_seqNum_seqNum              (entries_io_deqEntry_1_bits_payload_debug_seqNum_seqNum),
    .io_deqEntry_1_bits_payload_debug_seqNum_uopIdx              (entries_io_deqEntry_1_bits_payload_debug_seqNum_uopIdx),
    .io_simpEntryDeqSelVec_0                                     (age_1_io_out_2),
    .io_simpEntryDeqSelVec_1                                     (age_1_io_out_3),
    .io_simpEntryEnqSelVec_0                                     (entries_io_simpEntryEnqSelVec_0),
    .io_simpEntryEnqSelVec_1                                     (entries_io_simpEntryEnqSelVec_1),
    .io_compEntryEnqSelVec_0                                     (entries_io_compEntryEnqSelVec_0),
    .io_compEntryEnqSelVec_1                                     (entries_io_compEntryEnqSelVec_1)
  );

  FuBusyTableWrite_80 fuBusyTableWrite_0 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_valid[0]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_0_bits_status_fuType_25, entries_io_deqEntry_0_bits_status_fuType_24, 4'h0, entries_io_deqEntry_0_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_0_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_0_bits_fuType),
    .io_out_fuBusyTable        (fuBusyTableWrite_0_io_out_fuBusyTable)
  );

  FuBusyTableWrite_73 fuBusyTableWrite_1 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_valid[1]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_1_bits_status_fuType_25, entries_io_deqEntry_1_bits_status_fuType_24, 4'h0, entries_io_deqEntry_1_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_1_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_1_bits_fuType),
    .io_out_fuBusyTable        (fuBusyTableWrite_1_io_out_fuBusyTable)
  );

  FuBusyTableRead_80 fuBusyTableRead_0 (
    .io_in_fuBusyTable      (fuBusyTableWrite_0_io_out_fuBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (fuBusyTableRead_0_io_out_fuBusyTableMask)
  );

  FuBusyTableRead_73 fuBusyTableRead_1 (
    .io_in_fuBusyTable      (fuBusyTableWrite_1_io_out_fuBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (fuBusyTableRead_1_io_out_fuBusyTableMask)
  );

  FuBusyTableWrite_73 fpWbBusyTableWrite_1 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_wen_valid[1][1]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_1_bits_status_fuType_25, entries_io_deqEntry_1_bits_status_fuType_24, 4'h0, entries_io_deqEntry_1_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_1_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_1_bits_fuType),
    .io_out_fuBusyTable        (io_wbBusyTableWrite_1_fpWbBusyTable)
  );

  FuBusyTableRead_73 fpWbBusyTableRead_1 (
    .io_in_fuBusyTable      (io_wbBusyTableRead_1_fpWbBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (fpWbBusyTableRead_1_io_out_fuBusyTableMask)
  );

  FuBusyTableWrite_80 vfWbBusyTableWrite_0 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_wen_valid[0][2]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_0_bits_status_fuType_25, entries_io_deqEntry_0_bits_status_fuType_24, 4'h0, entries_io_deqEntry_0_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_0_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_0_bits_fuType),
    .io_out_fuBusyTable        (io_wbBusyTableWrite_0_vfWbBusyTable)
  );

  FuBusyTableWrite_73 vfWbBusyTableWrite_1 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_wen_valid[1][2]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_1_bits_status_fuType_25, entries_io_deqEntry_1_bits_status_fuType_24, 4'h0, entries_io_deqEntry_1_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_1_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_1_bits_fuType),
    .io_out_fuBusyTable        (io_wbBusyTableWrite_1_vfWbBusyTable)
  );

  FuBusyTableRead_80 vfWbBusyTableRead_0 (
    .io_in_fuBusyTable      (io_wbBusyTableRead_0_vfWbBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (vfWbBusyTableRead_0_io_out_fuBusyTableMask)
  );

  FuBusyTableRead_73 vfWbBusyTableRead_1 (
    .io_in_fuBusyTable      (io_wbBusyTableRead_1_vfWbBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (vfWbBusyTableRead_1_io_out_fuBusyTableMask)
  );

  FuBusyTableWrite_80 v0WbBusyTableWrite_0 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_wen_valid[0][3]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_0_bits_status_fuType_25, entries_io_deqEntry_0_bits_status_fuType_24, 4'h0, entries_io_deqEntry_0_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_0_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_0_bits_fuType),
    .io_out_fuBusyTable        (io_wbBusyTableWrite_0_v0WbBusyTable)
  );

  FuBusyTableWrite_73 v0WbBusyTableWrite_1 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_wen_valid[1][3]),
    .io_in_deqResp_bits_fuType ({9'h0, entries_io_deqEntry_1_bits_status_fuType_25, entries_io_deqEntry_1_bits_status_fuType_24, 4'h0, entries_io_deqEntry_1_bits_status_fuType_19, 19'h0}),
    .io_in_og0Resp_valid       (io_og0Resp_1_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_1_bits_fuType),
    .io_out_fuBusyTable        (io_wbBusyTableWrite_1_v0WbBusyTable)
  );

  FuBusyTableRead_80 v0WbBusyTableRead_0 (
    .io_in_fuBusyTable      (io_wbBusyTableRead_0_v0WbBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (v0WbBusyTableRead_0_io_out_fuBusyTableMask)
  );

  FuBusyTableRead_73 v0WbBusyTableRead_1 (
    .io_in_fuBusyTable      (io_wbBusyTableRead_1_v0WbBusyTable),
    .io_in_fuTypeRegVec_0   (entries_io_fuType_0),
    .io_in_fuTypeRegVec_1   (entries_io_fuType_1),
    .io_in_fuTypeRegVec_2   (entries_io_fuType_2),
    .io_in_fuTypeRegVec_3   (entries_io_fuType_3),
    .io_in_fuTypeRegVec_4   (entries_io_fuType_4),
    .io_in_fuTypeRegVec_5   (entries_io_fuType_5),
    .io_in_fuTypeRegVec_6   (entries_io_fuType_6),
    .io_in_fuTypeRegVec_7   (entries_io_fuType_7),
    .io_in_fuTypeRegVec_8   (entries_io_fuType_8),
    .io_in_fuTypeRegVec_9   (entries_io_fuType_9),
    .io_in_fuTypeRegVec_10  (entries_io_fuType_10),
    .io_in_fuTypeRegVec_11  (entries_io_fuType_11),
    .io_in_fuTypeRegVec_12  (entries_io_fuType_12),
    .io_in_fuTypeRegVec_13  (entries_io_fuType_13),
    .io_in_fuTypeRegVec_14  (entries_io_fuType_14),
    .io_in_fuTypeRegVec_15  (entries_io_fuType_15),
    .io_out_fuBusyTableMask (v0WbBusyTableRead_1_io_out_fuBusyTableMask)
  );

  NewAgeDetector age (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (core_enq_do[0]),
    .io_enq_1      (core_enq_do[1]),
    .io_canIssue_0 (core_age_enq_req[0]),
    .io_canIssue_1 (core_age_enq_req[1]),
    .io_out_0      (age_io_out_0),
    .io_out_1      (age_io_out_1)
  );

  AgeDetector_8 age_1 (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (entries_io_simpEntryEnqSelVec_0),
    .io_enq_1      (entries_io_simpEntryEnqSelVec_1),
    .io_canIssue_0 (core_age_simp_req[0]),
    .io_canIssue_1 (core_age_simp_req[1]),
    .io_canIssue_2 (core_age_simp_req[2]),
    .io_canIssue_3 (core_age_simp_req[3]),
    .io_out_0      (age_1_io_out_0),
    .io_out_1      (age_1_io_out_1),
    .io_out_2      (age_1_io_out_2),
    .io_out_3      (age_1_io_out_3)
  );

  AgeDetector_15 age_2 (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (entries_io_compEntryEnqSelVec_0),
    .io_enq_1      (entries_io_compEntryEnqSelVec_1),
    .io_canIssue_0 (core_age_comp_req[0]),
    .io_canIssue_1 (core_age_comp_req[1]),
    .io_out_0      (age_2_io_out_0),
    .io_out_1      (age_2_io_out_1)
  );

  // ============================================================================
  // §F 唤醒出口胶合输入（MultiWakeupQueue 出口 / og1 响应 -> 核）
  assign core_wk_enq_fu_type = '0;
  assign core_wk_deq_valid = 1'h0;
  assign core_wk_deq_fu_type = '0;
  assign core_wk_deq_wen = '0;
  assign core_wk_og1_valid = io_og1Resp_0_valid;
  assign core_wk_og1_resp = 2'h0;

  // ============================================================================
  // §G 调度核例化
  xs_IssueQueue_core #(
    .N_ENTRIES (16),
    .N_ENQ     (2),
    .N_SIMP    (2),
    .N_COMP    (12),
    .N_DEQ     (2),
    .N_SRC     (5),
    .PSRC_W    (8),
    .LD_CNT    (0),
    .N_EXU     (0),
    .EXU_W     (1),
    .N_BUSY    (4),
    .ACCEPT    ('{35'h2080000, 35'h1000000}),
    .IQIDX_W   (4),
    .HAS_VCNT  ('{1'b1, 1'b1}),
    .VCNT_OUT_W(5),
    .W0        (1727),
    .W1        (1729),
    .LDW_ON    (1'b0),
    .VECMEM_BLOCKED(1'b0),
    .LQ_W      (7),
    .N_LAT     (1),
    .LAT_FU    ('{0}),
    .LAT_VAL   ('{0}),
    .LAT_W     (1)
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .flush_valid      (io_flush_valid),
    .enq_valid        (core_enq_valid),
    .enq_ready        (core_enq_ready),
    .enq_do           (core_enq_do),
    .enq_src_type     (core_enq_src_type),
    .enq_psrc         (core_enq_psrc),
    .enq_src_state    (core_enq_src_state),
    .enq_src_ld       (core_enq_src_ld),
    .enq_lq_idx       (core_enq_lq_idx),
    .enq_is_vleff     (core_enq_is_vleff),
    .lq_deq_ptr       (core_lq_deq_ptr),
    .st_blocked       (core_st_blocked),
    .st_src_state     (core_st_src_state),
    .st_data_src      (core_st_data_src),
    .st_src_ld        (core_st_src_ld),
    .ent_valid        (core_ent_valid),
    .ent_issued       (core_ent_issued),
    .ent_can_issue    (core_ent_can_issue),
    .ent_fu_type      (core_ent_fu_type),
    .ent_data_src     (core_ent_data_src),
    .ent_exu_src      (core_ent_exu_src),
    .ent_ld_dep       (core_ent_ld_dep),
    .ent_cancel_deq   (core_ent_cancel_deq),
    .busy_mask        (core_busy_mask),
    .age_enq_req      (core_age_enq_req),
    .age_simp_req     (core_age_simp_req),
    .age_comp_req     (core_age_comp_req),
    .age_enq_out      (core_age_enq_out),
    .age_simp_out     (core_age_simp_out),
    .age_comp_out     (core_age_comp_out),
    .sel_valid        (core_sel_valid),
    .sel_oh           (core_sel_oh),
    .simp_oldest_valid(core_simp_oldest_valid),
    .comp_oldest_valid(core_comp_oldest_valid),
    .deq_valid        (core_deq_valid),
    .deq_iq_idx       (core_deq_iq_idx),
    .deq_data_src     (core_deq_data_src),
    .deq_exu_src      (core_deq_exu_src),
    .deq_ld_dep       (core_deq_ld_dep),
    .deq_select_time  (core_deq_select_time),
    .deq_issue_time   (core_deq_issue_time),
    .deq_wen          (core_deq_wen),
    .deq_wen_valid    (core_deq_wen_valid),
    .deq0_payload     (core_deq0_payload),
    .deq1_payload     (core_deq1_payload),
    .dly_valid        (core_dly_valid),
    .dly0_payload     (core_dly0_payload),
    .dly1_payload     (core_dly1_payload),
    .dly_ready        (core_dly_ready),
    .valid_cnt        (core_valid_cnt),
    .wk_enq_fu_type   (core_wk_enq_fu_type),
    .wk_enq_lat       (core_wk_enq_lat),
    .wk_og1_valid     (core_wk_og1_valid),
    .wk_og1_resp      (core_wk_og1_resp),
    .wk_og1_fail      (core_wk_og1_fail),
    .wk_deq_valid     (core_wk_deq_valid),
    .wk_deq_fu_type   (core_wk_deq_fu_type),
    .wk_deq_wen       (core_wk_deq_wen),
    .wk_out_wen       (core_wk_out_wen),
    .wk_is0lat        (core_wk_is0lat),
    .ldw_valid        (core_ldw_valid),
    .ldw_rf_wen       (core_ldw_rf_wen),
    .ldw_fp_wen       (core_ldw_fp_wen),
    .ldw_pdest        (core_ldw_pdest),
    .ldw_q_valid      (core_ldw_q_valid),
    .ldw_q_rf_wen     (core_ldw_q_rf_wen),
    .ldw_q_fp_wen     (core_ldw_q_fp_wen),
    .ldw_q_pdest      (core_ldw_q_pdest),
    .ldw_q_rf_wen_copy(core_ldw_q_rf_wen_copy),
    .ldw_q_fp_wen_copy(core_ldw_q_fp_wen_copy),
    .ldw_q_pdest_copy (core_ldw_q_pdest_copy)
  );

  // ============================================================================
  // §H 顶层输出
  assign io_enq_0_ready = core_enq_ready[0];
  assign io_enq_1_ready = core_enq_ready[1];
  assign io_validCntDeqVec_0 = core_valid_cnt[0];
  assign io_validCntDeqVec_1 = core_valid_cnt[1];
  assign io_deqDelay_1_valid = core_dly_valid[1];
  assign io_deqDelay_1_bits_rf_4_0_addr = dly1_bits_rf_4_0_addr;
  assign io_deqDelay_1_bits_rf_4_0_srcType = dly1_bits_rf_4_0_srcType;
  assign io_deqDelay_1_bits_rf_3_0_addr = dly1_bits_rf_3_0_addr;
  assign io_deqDelay_1_bits_rf_3_0_srcType = dly1_bits_rf_3_0_srcType;
  assign io_deqDelay_1_bits_rf_2_0_addr = dly1_bits_rf_2_0_addr;
  assign io_deqDelay_1_bits_rf_2_0_srcType = dly1_bits_rf_2_0_srcType;
  assign io_deqDelay_1_bits_rf_1_0_addr = dly1_bits_rf_1_0_addr;
  assign io_deqDelay_1_bits_rf_1_0_srcType = dly1_bits_rf_1_0_srcType;
  assign io_deqDelay_1_bits_rf_0_0_addr = dly1_bits_rf_0_0_addr;
  assign io_deqDelay_1_bits_rf_0_0_srcType = dly1_bits_rf_0_0_srcType;
  assign io_deqDelay_1_bits_srcType_0 = dly1_bits_srcType_0;
  assign io_deqDelay_1_bits_srcType_1 = dly1_bits_srcType_1;
  assign io_deqDelay_1_bits_srcType_2 = dly1_bits_srcType_2;
  assign io_deqDelay_1_bits_srcType_3 = dly1_bits_srcType_3;
  assign io_deqDelay_1_bits_srcType_4 = dly1_bits_srcType_4;
  assign io_deqDelay_1_bits_immType = dly1_bits_immType;
  assign io_deqDelay_1_bits_common_fuType = dly1_bits_common_fuType;
  assign io_deqDelay_1_bits_common_fuOpType = dly1_bits_common_fuOpType;
  assign io_deqDelay_1_bits_common_src_0 = dly1_bits_common_src_0;
  assign io_deqDelay_1_bits_common_src_1 = dly1_bits_common_src_1;
  assign io_deqDelay_1_bits_common_src_2 = dly1_bits_common_src_2;
  assign io_deqDelay_1_bits_common_src_3 = dly1_bits_common_src_3;
  assign io_deqDelay_1_bits_common_src_4 = dly1_bits_common_src_4;
  assign io_deqDelay_1_bits_common_imm = dly1_bits_common_imm;
  assign io_deqDelay_1_bits_common_robIdx_flag = dly1_bits_common_robIdx_flag;
  assign io_deqDelay_1_bits_common_robIdx_value = dly1_bits_common_robIdx_value;
  assign io_deqDelay_1_bits_common_iqIdx = dly1_bits_common_iqIdx;
  assign io_deqDelay_1_bits_common_isFirstIssue = dly1_bits_common_isFirstIssue;
  assign io_deqDelay_1_bits_common_pdest = dly1_bits_common_pdest;
  assign io_deqDelay_1_bits_common_fpWen = dly1_bits_common_fpWen;
  assign io_deqDelay_1_bits_common_vecWen = dly1_bits_common_vecWen;
  assign io_deqDelay_1_bits_common_v0Wen = dly1_bits_common_v0Wen;
  assign io_deqDelay_1_bits_common_fpu_typeTagOut = dly1_bits_common_fpu_typeTagOut;
  assign io_deqDelay_1_bits_common_fpu_wflags = dly1_bits_common_fpu_wflags;
  assign io_deqDelay_1_bits_common_fpu_typ = dly1_bits_common_fpu_typ;
  assign io_deqDelay_1_bits_common_fpu_fmt = dly1_bits_common_fpu_fmt;
  assign io_deqDelay_1_bits_common_fpu_rm = dly1_bits_common_fpu_rm;
  assign io_deqDelay_1_bits_common_vpu_vill = dly1_bits_common_vpu_vill;
  assign io_deqDelay_1_bits_common_vpu_vma = dly1_bits_common_vpu_vma;
  assign io_deqDelay_1_bits_common_vpu_vta = dly1_bits_common_vpu_vta;
  assign io_deqDelay_1_bits_common_vpu_vsew = dly1_bits_common_vpu_vsew;
  assign io_deqDelay_1_bits_common_vpu_vlmul = dly1_bits_common_vpu_vlmul;
  assign io_deqDelay_1_bits_common_vpu_specVill = dly1_bits_common_vpu_specVill;
  assign io_deqDelay_1_bits_common_vpu_specVma = dly1_bits_common_vpu_specVma;
  assign io_deqDelay_1_bits_common_vpu_specVta = dly1_bits_common_vpu_specVta;
  assign io_deqDelay_1_bits_common_vpu_specVsew = dly1_bits_common_vpu_specVsew;
  assign io_deqDelay_1_bits_common_vpu_specVlmul = dly1_bits_common_vpu_specVlmul;
  assign io_deqDelay_1_bits_common_vpu_vm = dly1_bits_common_vpu_vm;
  assign io_deqDelay_1_bits_common_vpu_vstart = dly1_bits_common_vpu_vstart;
  assign io_deqDelay_1_bits_common_vpu_frm = dly1_bits_common_vpu_frm;
  assign io_deqDelay_1_bits_common_vpu_fpu_isFpToVecInst = dly1_bits_common_vpu_fpu_isFpToVecInst;
  assign io_deqDelay_1_bits_common_vpu_fpu_isFP32Instr = dly1_bits_common_vpu_fpu_isFP32Instr;
  assign io_deqDelay_1_bits_common_vpu_fpu_isFP64Instr = dly1_bits_common_vpu_fpu_isFP64Instr;
  assign io_deqDelay_1_bits_common_vpu_fpu_isReduction = dly1_bits_common_vpu_fpu_isReduction;
  assign io_deqDelay_1_bits_common_vpu_fpu_isFoldTo1_2 = dly1_bits_common_vpu_fpu_isFoldTo1_2;
  assign io_deqDelay_1_bits_common_vpu_fpu_isFoldTo1_4 = dly1_bits_common_vpu_fpu_isFoldTo1_4;
  assign io_deqDelay_1_bits_common_vpu_fpu_isFoldTo1_8 = dly1_bits_common_vpu_fpu_isFoldTo1_8;
  assign io_deqDelay_1_bits_common_vpu_vxrm = dly1_bits_common_vpu_vxrm;
  assign io_deqDelay_1_bits_common_vpu_vuopIdx = dly1_bits_common_vpu_vuopIdx;
  assign io_deqDelay_1_bits_common_vpu_lastUop = dly1_bits_common_vpu_lastUop;
  assign io_deqDelay_1_bits_common_vpu_vmask = dly1_bits_common_vpu_vmask;
  assign io_deqDelay_1_bits_common_vpu_vl = dly1_bits_common_vpu_vl;
  assign io_deqDelay_1_bits_common_vpu_nf = dly1_bits_common_vpu_nf;
  assign io_deqDelay_1_bits_common_vpu_veew = dly1_bits_common_vpu_veew;
  assign io_deqDelay_1_bits_common_vpu_isReverse = dly1_bits_common_vpu_isReverse;
  assign io_deqDelay_1_bits_common_vpu_isExt = dly1_bits_common_vpu_isExt;
  assign io_deqDelay_1_bits_common_vpu_isNarrow = dly1_bits_common_vpu_isNarrow;
  assign io_deqDelay_1_bits_common_vpu_isDstMask = dly1_bits_common_vpu_isDstMask;
  assign io_deqDelay_1_bits_common_vpu_isOpMask = dly1_bits_common_vpu_isOpMask;
  assign io_deqDelay_1_bits_common_vpu_isMove = dly1_bits_common_vpu_isMove;
  assign io_deqDelay_1_bits_common_vpu_isDependOldVd = dly1_bits_common_vpu_isDependOldVd;
  assign io_deqDelay_1_bits_common_vpu_isWritePartVd = dly1_bits_common_vpu_isWritePartVd;
  assign io_deqDelay_1_bits_common_vpu_isVleff = dly1_bits_common_vpu_isVleff;
  assign io_deqDelay_1_bits_common_dataSources_0_value = dly1_bits_common_dataSources_0_value;
  assign io_deqDelay_1_bits_common_dataSources_1_value = dly1_bits_common_dataSources_1_value;
  assign io_deqDelay_1_bits_common_dataSources_2_value = dly1_bits_common_dataSources_2_value;
  assign io_deqDelay_1_bits_common_dataSources_3_value = dly1_bits_common_dataSources_3_value;
  assign io_deqDelay_1_bits_common_dataSources_4_value = dly1_bits_common_dataSources_4_value;
  assign io_deqDelay_1_bits_common_perfDebugInfo_eliminatedMove = dly1_bits_common_perfDebugInfo_eliminatedMove;
  assign io_deqDelay_1_bits_common_perfDebugInfo_renameTime = dly1_bits_common_perfDebugInfo_renameTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_dispatchTime = dly1_bits_common_perfDebugInfo_dispatchTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_enqRsTime = dly1_bits_common_perfDebugInfo_enqRsTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_selectTime = dly1_bits_common_perfDebugInfo_selectTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_issueTime = dly1_bits_common_perfDebugInfo_issueTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_writebackTime = dly1_bits_common_perfDebugInfo_writebackTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_runahead_checkpoint_id = dly1_bits_common_perfDebugInfo_runahead_checkpoint_id;
  assign io_deqDelay_1_bits_common_perfDebugInfo_tlbFirstReqTime = dly1_bits_common_perfDebugInfo_tlbFirstReqTime;
  assign io_deqDelay_1_bits_common_perfDebugInfo_tlbRespTime = dly1_bits_common_perfDebugInfo_tlbRespTime;
  assign io_deqDelay_1_bits_common_debug_seqNum_seqNum = dly1_bits_common_debug_seqNum_seqNum;
  assign io_deqDelay_1_bits_common_debug_seqNum_uopIdx = dly1_bits_common_debug_seqNum_uopIdx;
  assign io_deqDelay_1_bits_addrOH = dly1_bits_addrOH;
  assign io_deqDelay_0_valid = core_dly_valid[0];
  assign io_deqDelay_0_bits_rf_4_0_addr = dly0_bits_rf_4_0_addr;
  assign io_deqDelay_0_bits_rf_4_0_srcType = dly0_bits_rf_4_0_srcType;
  assign io_deqDelay_0_bits_rf_3_0_addr = dly0_bits_rf_3_0_addr;
  assign io_deqDelay_0_bits_rf_3_0_srcType = dly0_bits_rf_3_0_srcType;
  assign io_deqDelay_0_bits_rf_2_0_addr = dly0_bits_rf_2_0_addr;
  assign io_deqDelay_0_bits_rf_2_0_srcType = dly0_bits_rf_2_0_srcType;
  assign io_deqDelay_0_bits_rf_1_0_addr = dly0_bits_rf_1_0_addr;
  assign io_deqDelay_0_bits_rf_1_0_srcType = dly0_bits_rf_1_0_srcType;
  assign io_deqDelay_0_bits_rf_0_0_addr = dly0_bits_rf_0_0_addr;
  assign io_deqDelay_0_bits_rf_0_0_srcType = dly0_bits_rf_0_0_srcType;
  assign io_deqDelay_0_bits_srcType_0 = dly0_bits_srcType_0;
  assign io_deqDelay_0_bits_srcType_1 = dly0_bits_srcType_1;
  assign io_deqDelay_0_bits_srcType_2 = dly0_bits_srcType_2;
  assign io_deqDelay_0_bits_srcType_3 = dly0_bits_srcType_3;
  assign io_deqDelay_0_bits_srcType_4 = dly0_bits_srcType_4;
  assign io_deqDelay_0_bits_immType = dly0_bits_immType;
  assign io_deqDelay_0_bits_common_fuType = dly0_bits_common_fuType;
  assign io_deqDelay_0_bits_common_fuOpType = dly0_bits_common_fuOpType;
  assign io_deqDelay_0_bits_common_src_0 = dly0_bits_common_src_0;
  assign io_deqDelay_0_bits_common_src_1 = dly0_bits_common_src_1;
  assign io_deqDelay_0_bits_common_src_2 = dly0_bits_common_src_2;
  assign io_deqDelay_0_bits_common_src_3 = dly0_bits_common_src_3;
  assign io_deqDelay_0_bits_common_src_4 = dly0_bits_common_src_4;
  assign io_deqDelay_0_bits_common_imm = dly0_bits_common_imm;
  assign io_deqDelay_0_bits_common_robIdx_flag = dly0_bits_common_robIdx_flag;
  assign io_deqDelay_0_bits_common_robIdx_value = dly0_bits_common_robIdx_value;
  assign io_deqDelay_0_bits_common_iqIdx = dly0_bits_common_iqIdx;
  assign io_deqDelay_0_bits_common_isFirstIssue = dly0_bits_common_isFirstIssue;
  assign io_deqDelay_0_bits_common_pdest = dly0_bits_common_pdest;
  assign io_deqDelay_0_bits_common_vecWen = dly0_bits_common_vecWen;
  assign io_deqDelay_0_bits_common_v0Wen = dly0_bits_common_v0Wen;
  assign io_deqDelay_0_bits_common_fpu_typeTagOut = dly0_bits_common_fpu_typeTagOut;
  assign io_deqDelay_0_bits_common_fpu_wflags = dly0_bits_common_fpu_wflags;
  assign io_deqDelay_0_bits_common_fpu_typ = dly0_bits_common_fpu_typ;
  assign io_deqDelay_0_bits_common_fpu_fmt = dly0_bits_common_fpu_fmt;
  assign io_deqDelay_0_bits_common_fpu_rm = dly0_bits_common_fpu_rm;
  assign io_deqDelay_0_bits_common_vpu_vill = dly0_bits_common_vpu_vill;
  assign io_deqDelay_0_bits_common_vpu_vma = dly0_bits_common_vpu_vma;
  assign io_deqDelay_0_bits_common_vpu_vta = dly0_bits_common_vpu_vta;
  assign io_deqDelay_0_bits_common_vpu_vsew = dly0_bits_common_vpu_vsew;
  assign io_deqDelay_0_bits_common_vpu_vlmul = dly0_bits_common_vpu_vlmul;
  assign io_deqDelay_0_bits_common_vpu_specVill = dly0_bits_common_vpu_specVill;
  assign io_deqDelay_0_bits_common_vpu_specVma = dly0_bits_common_vpu_specVma;
  assign io_deqDelay_0_bits_common_vpu_specVta = dly0_bits_common_vpu_specVta;
  assign io_deqDelay_0_bits_common_vpu_specVsew = dly0_bits_common_vpu_specVsew;
  assign io_deqDelay_0_bits_common_vpu_specVlmul = dly0_bits_common_vpu_specVlmul;
  assign io_deqDelay_0_bits_common_vpu_vm = dly0_bits_common_vpu_vm;
  assign io_deqDelay_0_bits_common_vpu_vstart = dly0_bits_common_vpu_vstart;
  assign io_deqDelay_0_bits_common_vpu_frm = dly0_bits_common_vpu_frm;
  assign io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst = dly0_bits_common_vpu_fpu_isFpToVecInst;
  assign io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr = dly0_bits_common_vpu_fpu_isFP32Instr;
  assign io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr = dly0_bits_common_vpu_fpu_isFP64Instr;
  assign io_deqDelay_0_bits_common_vpu_fpu_isReduction = dly0_bits_common_vpu_fpu_isReduction;
  assign io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2 = dly0_bits_common_vpu_fpu_isFoldTo1_2;
  assign io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4 = dly0_bits_common_vpu_fpu_isFoldTo1_4;
  assign io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8 = dly0_bits_common_vpu_fpu_isFoldTo1_8;
  assign io_deqDelay_0_bits_common_vpu_vxrm = dly0_bits_common_vpu_vxrm;
  assign io_deqDelay_0_bits_common_vpu_vuopIdx = dly0_bits_common_vpu_vuopIdx;
  assign io_deqDelay_0_bits_common_vpu_lastUop = dly0_bits_common_vpu_lastUop;
  assign io_deqDelay_0_bits_common_vpu_vmask = dly0_bits_common_vpu_vmask;
  assign io_deqDelay_0_bits_common_vpu_vl = dly0_bits_common_vpu_vl;
  assign io_deqDelay_0_bits_common_vpu_nf = dly0_bits_common_vpu_nf;
  assign io_deqDelay_0_bits_common_vpu_veew = dly0_bits_common_vpu_veew;
  assign io_deqDelay_0_bits_common_vpu_isReverse = dly0_bits_common_vpu_isReverse;
  assign io_deqDelay_0_bits_common_vpu_isExt = dly0_bits_common_vpu_isExt;
  assign io_deqDelay_0_bits_common_vpu_isNarrow = dly0_bits_common_vpu_isNarrow;
  assign io_deqDelay_0_bits_common_vpu_isDstMask = dly0_bits_common_vpu_isDstMask;
  assign io_deqDelay_0_bits_common_vpu_isOpMask = dly0_bits_common_vpu_isOpMask;
  assign io_deqDelay_0_bits_common_vpu_isMove = dly0_bits_common_vpu_isMove;
  assign io_deqDelay_0_bits_common_vpu_isDependOldVd = dly0_bits_common_vpu_isDependOldVd;
  assign io_deqDelay_0_bits_common_vpu_isWritePartVd = dly0_bits_common_vpu_isWritePartVd;
  assign io_deqDelay_0_bits_common_vpu_isVleff = dly0_bits_common_vpu_isVleff;
  assign io_deqDelay_0_bits_common_dataSources_0_value = dly0_bits_common_dataSources_0_value;
  assign io_deqDelay_0_bits_common_dataSources_1_value = dly0_bits_common_dataSources_1_value;
  assign io_deqDelay_0_bits_common_dataSources_2_value = dly0_bits_common_dataSources_2_value;
  assign io_deqDelay_0_bits_common_dataSources_3_value = dly0_bits_common_dataSources_3_value;
  assign io_deqDelay_0_bits_common_dataSources_4_value = dly0_bits_common_dataSources_4_value;
  assign io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove = dly0_bits_common_perfDebugInfo_eliminatedMove;
  assign io_deqDelay_0_bits_common_perfDebugInfo_renameTime = dly0_bits_common_perfDebugInfo_renameTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime = dly0_bits_common_perfDebugInfo_dispatchTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime = dly0_bits_common_perfDebugInfo_enqRsTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_selectTime = dly0_bits_common_perfDebugInfo_selectTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_issueTime = dly0_bits_common_perfDebugInfo_issueTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_writebackTime = dly0_bits_common_perfDebugInfo_writebackTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id = dly0_bits_common_perfDebugInfo_runahead_checkpoint_id;
  assign io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime = dly0_bits_common_perfDebugInfo_tlbFirstReqTime;
  assign io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime = dly0_bits_common_perfDebugInfo_tlbRespTime;
  assign io_deqDelay_0_bits_common_debug_seqNum_seqNum = dly0_bits_common_debug_seqNum_seqNum;
  assign io_deqDelay_0_bits_common_debug_seqNum_uopIdx = dly0_bits_common_debug_seqNum_uopIdx;
  assign io_deqDelay_0_bits_addrOH = dly0_bits_addrOH;
endmodule
