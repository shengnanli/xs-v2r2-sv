// IssueQueueStdMoud.sv —— 发射队列 StdMoud（golden 同名 wrapper）
// -----------------------------------------------------------------------------
// 调度逻辑全部在 xs_IssueQueue_core.sv（家族共享参数化核）；本文件只做连线：
//   golden 端口表 + golden 同名子模块例化（已签核件）+ 核的数组接口接线 + deqDelay 负载拼包/拆包。
//
// 本变体规模（全部从 G1 golden 量得）：
//   条目 16 = enq 2 + simp 2 + comp 12，发射口 1，源 1，loadDependency 3 路，exuSources 1
//   口 0：接受 FuType 位 [16, 17]；deqDelay 负载 36 个字段 / 901 位
//   子模块：EntriesStdMoud×1，NewAgeDetector_6×1，AgeDetector_12×1，AgeDetector_21×1
//
// 自动生成：scripts/gen_iq.py —— 勿手改
// =============================================================================
module IssueQueueStdMoud(
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
  input  [1:0]   io_enq_0_bits_srcLoadDependency_0_0,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_0_1,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_0_2,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_1_0,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_1_1,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_1_2,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_2_0,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_2_1,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_2_2,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_3_0,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_3_1,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_3_2,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_4_0,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_4_1,
  input  [1:0]   io_enq_0_bits_srcLoadDependency_4_2,
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
  input  [1:0]   io_enq_1_bits_srcLoadDependency_0_0,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_0_1,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_0_2,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_1_0,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_1_1,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_1_2,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_2_0,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_2_1,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_2_2,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_3_0,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_3_1,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_3_2,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_4_0,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_4_1,
  input  [1:0]   io_enq_1_bits_srcLoadDependency_4_2,
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
  input  [1:0]   io_og0Resp_0_bits_resp,
  input          io_og1Resp_0_valid,
  input  [1:0]   io_og1Resp_0_bits_resp,
  input          io_wakeupFromWB_9_valid,
  input          io_wakeupFromWB_9_bits_rfWen,
  input          io_wakeupFromWB_9_bits_fpWen,
  input          io_wakeupFromWB_9_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_9_bits_pdest,
  input          io_wakeupFromWB_8_valid,
  input          io_wakeupFromWB_8_bits_rfWen,
  input          io_wakeupFromWB_8_bits_fpWen,
  input          io_wakeupFromWB_8_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_8_bits_pdest,
  input          io_wakeupFromWB_7_valid,
  input          io_wakeupFromWB_7_bits_rfWen,
  input          io_wakeupFromWB_7_bits_fpWen,
  input          io_wakeupFromWB_7_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_7_bits_pdest,
  input          io_wakeupFromWB_6_valid,
  input          io_wakeupFromWB_6_bits_rfWen,
  input          io_wakeupFromWB_6_bits_fpWen,
  input          io_wakeupFromWB_6_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_6_bits_pdest,
  input          io_wakeupFromWB_5_valid,
  input          io_wakeupFromWB_5_bits_rfWen,
  input          io_wakeupFromWB_5_bits_fpWen,
  input          io_wakeupFromWB_5_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_5_bits_pdest,
  input          io_wakeupFromWB_4_valid,
  input          io_wakeupFromWB_4_bits_rfWen,
  input          io_wakeupFromWB_4_bits_fpWen,
  input          io_wakeupFromWB_4_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_4_bits_pdest,
  input          io_wakeupFromWB_3_valid,
  input          io_wakeupFromWB_3_bits_rfWen,
  input          io_wakeupFromWB_3_bits_fpWen,
  input          io_wakeupFromWB_3_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_3_bits_pdest,
  input          io_wakeupFromWB_2_valid,
  input          io_wakeupFromWB_2_bits_rfWen,
  input          io_wakeupFromWB_2_bits_fpWen,
  input          io_wakeupFromWB_2_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_2_bits_pdest,
  input          io_wakeupFromWB_1_valid,
  input          io_wakeupFromWB_1_bits_rfWen,
  input          io_wakeupFromWB_1_bits_fpWen,
  input          io_wakeupFromWB_1_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_1_bits_pdest,
  input          io_wakeupFromWB_0_valid,
  input          io_wakeupFromWB_0_bits_rfWen,
  input          io_wakeupFromWB_0_bits_fpWen,
  input          io_wakeupFromWB_0_bits_vecWen,
  input  [7:0]   io_wakeupFromWB_0_bits_pdest,
  input          io_wakeupFromIQ_6_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_6_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_6_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_6_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_6_bits_loadDependency_2,
  input          io_wakeupFromIQ_6_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_6_bits_rcDest,
  input          io_wakeupFromIQ_5_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_5_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_5_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_5_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_5_bits_loadDependency_2,
  input          io_wakeupFromIQ_5_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_5_bits_rcDest,
  input          io_wakeupFromIQ_4_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_4_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_4_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_4_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_4_bits_loadDependency_2,
  input          io_wakeupFromIQ_4_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_4_bits_rcDest,
  input          io_wakeupFromIQ_3_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_3_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_3_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_3_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_3_bits_loadDependency_2,
  input          io_wakeupFromIQ_3_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_3_bits_rcDest,
  input          io_wakeupFromIQ_2_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_2_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_2_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_2_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_2_bits_loadDependency_2,
  input          io_wakeupFromIQ_2_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_2_bits_rcDest,
  input          io_wakeupFromIQ_1_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_1_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_1_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_1_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_1_bits_loadDependency_2,
  input          io_wakeupFromIQ_1_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_1_bits_rcDest,
  input          io_wakeupFromIQ_0_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_0_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_0_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_0_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_0_bits_loadDependency_2,
  input          io_wakeupFromIQ_0_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQ_0_bits_rcDest,
  input          io_wakeupFromWBDelayed_9_valid,
  input          io_wakeupFromWBDelayed_9_bits_rfWen,
  input          io_wakeupFromWBDelayed_9_bits_fpWen,
  input          io_wakeupFromWBDelayed_9_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_9_bits_pdest,
  input          io_wakeupFromWBDelayed_8_valid,
  input          io_wakeupFromWBDelayed_8_bits_rfWen,
  input          io_wakeupFromWBDelayed_8_bits_fpWen,
  input          io_wakeupFromWBDelayed_8_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_8_bits_pdest,
  input          io_wakeupFromWBDelayed_7_valid,
  input          io_wakeupFromWBDelayed_7_bits_rfWen,
  input          io_wakeupFromWBDelayed_7_bits_fpWen,
  input          io_wakeupFromWBDelayed_7_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_7_bits_pdest,
  input          io_wakeupFromWBDelayed_6_valid,
  input          io_wakeupFromWBDelayed_6_bits_rfWen,
  input          io_wakeupFromWBDelayed_6_bits_fpWen,
  input          io_wakeupFromWBDelayed_6_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_6_bits_pdest,
  input          io_wakeupFromWBDelayed_5_valid,
  input          io_wakeupFromWBDelayed_5_bits_rfWen,
  input          io_wakeupFromWBDelayed_5_bits_fpWen,
  input          io_wakeupFromWBDelayed_5_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_5_bits_pdest,
  input          io_wakeupFromWBDelayed_4_valid,
  input          io_wakeupFromWBDelayed_4_bits_rfWen,
  input          io_wakeupFromWBDelayed_4_bits_fpWen,
  input          io_wakeupFromWBDelayed_4_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_4_bits_pdest,
  input          io_wakeupFromWBDelayed_3_valid,
  input          io_wakeupFromWBDelayed_3_bits_rfWen,
  input          io_wakeupFromWBDelayed_3_bits_fpWen,
  input          io_wakeupFromWBDelayed_3_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_3_bits_pdest,
  input          io_wakeupFromWBDelayed_2_valid,
  input          io_wakeupFromWBDelayed_2_bits_rfWen,
  input          io_wakeupFromWBDelayed_2_bits_fpWen,
  input          io_wakeupFromWBDelayed_2_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_2_bits_pdest,
  input          io_wakeupFromWBDelayed_1_valid,
  input          io_wakeupFromWBDelayed_1_bits_rfWen,
  input          io_wakeupFromWBDelayed_1_bits_fpWen,
  input          io_wakeupFromWBDelayed_1_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_1_bits_pdest,
  input          io_wakeupFromWBDelayed_0_valid,
  input          io_wakeupFromWBDelayed_0_bits_rfWen,
  input          io_wakeupFromWBDelayed_0_bits_fpWen,
  input          io_wakeupFromWBDelayed_0_bits_vecWen,
  input  [7:0]   io_wakeupFromWBDelayed_0_bits_pdest,
  input          io_wakeupFromIQDelayed_6_bits_rfWen,
  input          io_wakeupFromIQDelayed_6_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_6_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_6_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_6_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_6_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_6_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_6_bits_rcDest,
  input          io_wakeupFromIQDelayed_5_bits_rfWen,
  input          io_wakeupFromIQDelayed_5_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_5_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_5_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_5_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_5_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_5_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_5_bits_rcDest,
  input          io_wakeupFromIQDelayed_4_bits_rfWen,
  input          io_wakeupFromIQDelayed_4_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_4_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_4_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_4_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_4_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_4_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_4_bits_rcDest,
  input          io_wakeupFromIQDelayed_3_bits_rfWen,
  input          io_wakeupFromIQDelayed_3_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_3_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_3_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_3_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_3_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_3_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_3_bits_rcDest,
  input          io_wakeupFromIQDelayed_2_bits_rfWen,
  input          io_wakeupFromIQDelayed_2_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_2_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_2_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_2_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_2_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_2_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_2_bits_rcDest,
  input          io_wakeupFromIQDelayed_1_bits_rfWen,
  input          io_wakeupFromIQDelayed_1_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_1_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_1_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_1_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_1_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_1_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_1_bits_rcDest,
  input          io_wakeupFromIQDelayed_0_bits_rfWen,
  input          io_wakeupFromIQDelayed_0_bits_fpWen,
  input  [7:0]   io_wakeupFromIQDelayed_0_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_0_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_0_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_0_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_0_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_0_bits_rcDest,
  input          io_og0Cancel_0,
  input          io_og0Cancel_2,
  input          io_og0Cancel_4,
  input          io_og0Cancel_6,
  input          io_og0Cancel_20,
  input          io_og0Cancel_21,
  input          io_og0Cancel_22,
  input          io_ldCancel_0_ld1Cancel,
  input          io_ldCancel_0_ld2Cancel,
  input          io_ldCancel_1_ld1Cancel,
  input          io_ldCancel_1_ld2Cancel,
  input          io_ldCancel_2_ld1Cancel,
  input          io_ldCancel_2_ld2Cancel,
  input          io_deqDelay_0_ready,
  output         io_deqDelay_0_valid,
  output [7:0]   io_deqDelay_0_bits_rf_0_1_addr,
  output [2:0]   io_deqDelay_0_bits_rf_0_1_srcType,
  output [7:0]   io_deqDelay_0_bits_rf_0_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_0_0_srcType,
  output [3:0]   io_deqDelay_0_bits_srcType_0,
  output [4:0]   io_deqDelay_0_bits_rcIdx_0,
  output [3:0]   io_deqDelay_0_bits_immType,
  output [34:0]  io_deqDelay_0_bits_common_fuType,
  output [8:0]   io_deqDelay_0_bits_common_fuOpType,
  output [63:0]  io_deqDelay_0_bits_common_src_0,
  output [63:0]  io_deqDelay_0_bits_common_imm,
  output         io_deqDelay_0_bits_common_robIdx_flag,
  output [7:0]   io_deqDelay_0_bits_common_robIdx_value,
  output [3:0]   io_deqDelay_0_bits_common_iqIdx,
  output         io_deqDelay_0_bits_common_isFirstIssue,
  output         io_deqDelay_0_bits_common_sqIdx_flag,
  output [5:0]   io_deqDelay_0_bits_common_sqIdx_value,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_0_value,
  output [2:0]   io_deqDelay_0_bits_common_exuSources_0_value,
  output [2:0]   io_deqDelay_0_bits_common_srcTimer_0,
  output [1:0]   io_deqDelay_0_bits_common_loadDependency_0,
  output [1:0]   io_deqDelay_0_bits_common_loadDependency_1,
  output [1:0]   io_deqDelay_0_bits_common_loadDependency_2,
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

  // ---- 子模块输出线（名字 = <实例>_<端口>）----
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
  logic [3:0] entries_io_dataSources_1_0_value;
  logic [3:0] entries_io_dataSources_2_0_value;
  logic [3:0] entries_io_dataSources_3_0_value;
  logic [3:0] entries_io_dataSources_4_0_value;
  logic [3:0] entries_io_dataSources_5_0_value;
  logic [3:0] entries_io_dataSources_6_0_value;
  logic [3:0] entries_io_dataSources_7_0_value;
  logic [3:0] entries_io_dataSources_8_0_value;
  logic [3:0] entries_io_dataSources_9_0_value;
  logic [3:0] entries_io_dataSources_10_0_value;
  logic [3:0] entries_io_dataSources_11_0_value;
  logic [3:0] entries_io_dataSources_12_0_value;
  logic [3:0] entries_io_dataSources_13_0_value;
  logic [3:0] entries_io_dataSources_14_0_value;
  logic [3:0] entries_io_dataSources_15_0_value;
  logic [1:0] entries_io_loadDependency_0_0;
  logic [1:0] entries_io_loadDependency_0_1;
  logic [1:0] entries_io_loadDependency_0_2;
  logic [1:0] entries_io_loadDependency_1_0;
  logic [1:0] entries_io_loadDependency_1_1;
  logic [1:0] entries_io_loadDependency_1_2;
  logic [1:0] entries_io_loadDependency_2_0;
  logic [1:0] entries_io_loadDependency_2_1;
  logic [1:0] entries_io_loadDependency_2_2;
  logic [1:0] entries_io_loadDependency_3_0;
  logic [1:0] entries_io_loadDependency_3_1;
  logic [1:0] entries_io_loadDependency_3_2;
  logic [1:0] entries_io_loadDependency_4_0;
  logic [1:0] entries_io_loadDependency_4_1;
  logic [1:0] entries_io_loadDependency_4_2;
  logic [1:0] entries_io_loadDependency_5_0;
  logic [1:0] entries_io_loadDependency_5_1;
  logic [1:0] entries_io_loadDependency_5_2;
  logic [1:0] entries_io_loadDependency_6_0;
  logic [1:0] entries_io_loadDependency_6_1;
  logic [1:0] entries_io_loadDependency_6_2;
  logic [1:0] entries_io_loadDependency_7_0;
  logic [1:0] entries_io_loadDependency_7_1;
  logic [1:0] entries_io_loadDependency_7_2;
  logic [1:0] entries_io_loadDependency_8_0;
  logic [1:0] entries_io_loadDependency_8_1;
  logic [1:0] entries_io_loadDependency_8_2;
  logic [1:0] entries_io_loadDependency_9_0;
  logic [1:0] entries_io_loadDependency_9_1;
  logic [1:0] entries_io_loadDependency_9_2;
  logic [1:0] entries_io_loadDependency_10_0;
  logic [1:0] entries_io_loadDependency_10_1;
  logic [1:0] entries_io_loadDependency_10_2;
  logic [1:0] entries_io_loadDependency_11_0;
  logic [1:0] entries_io_loadDependency_11_1;
  logic [1:0] entries_io_loadDependency_11_2;
  logic [1:0] entries_io_loadDependency_12_0;
  logic [1:0] entries_io_loadDependency_12_1;
  logic [1:0] entries_io_loadDependency_12_2;
  logic [1:0] entries_io_loadDependency_13_0;
  logic [1:0] entries_io_loadDependency_13_1;
  logic [1:0] entries_io_loadDependency_13_2;
  logic [1:0] entries_io_loadDependency_14_0;
  logic [1:0] entries_io_loadDependency_14_1;
  logic [1:0] entries_io_loadDependency_14_2;
  logic [1:0] entries_io_loadDependency_15_0;
  logic [1:0] entries_io_loadDependency_15_1;
  logic [1:0] entries_io_loadDependency_15_2;
  logic [2:0] entries_io_exuSources_0_0_value;
  logic [2:0] entries_io_exuSources_1_0_value;
  logic [2:0] entries_io_exuSources_2_0_value;
  logic [2:0] entries_io_exuSources_3_0_value;
  logic [2:0] entries_io_exuSources_4_0_value;
  logic [2:0] entries_io_exuSources_5_0_value;
  logic [2:0] entries_io_exuSources_6_0_value;
  logic [2:0] entries_io_exuSources_7_0_value;
  logic [2:0] entries_io_exuSources_8_0_value;
  logic [2:0] entries_io_exuSources_9_0_value;
  logic [2:0] entries_io_exuSources_10_0_value;
  logic [2:0] entries_io_exuSources_11_0_value;
  logic [2:0] entries_io_exuSources_12_0_value;
  logic [2:0] entries_io_exuSources_13_0_value;
  logic [2:0] entries_io_exuSources_14_0_value;
  logic [2:0] entries_io_exuSources_15_0_value;
  logic entries_io_isFirstIssue_0;
  logic entries_io_deqEntry_0_bits_status_robIdx_flag;
  logic [7:0] entries_io_deqEntry_0_bits_status_robIdx_value;
  logic entries_io_deqEntry_0_bits_status_fuType_16;
  logic entries_io_deqEntry_0_bits_status_fuType_17;
  logic [7:0] entries_io_deqEntry_0_bits_status_srcStatus_0_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_0_srcType;
  logic [4:0] entries_io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx;
  logic [8:0] entries_io_deqEntry_0_bits_payload_fuOpType;
  logic [3:0] entries_io_deqEntry_0_bits_payload_selImm;
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
  logic entries_io_deqEntry_0_bits_payload_sqIdx_flag;
  logic [5:0] entries_io_deqEntry_0_bits_payload_sqIdx_value;
  logic entries_io_cancelDeqVec_0;
  logic [1:0] entries_io_simpEntryEnqSelVec_0;
  logic [1:0] entries_io_simpEntryEnqSelVec_1;
  logic [11:0] entries_io_compEntryEnqSelVec_0;
  logic [11:0] entries_io_compEntryEnqSelVec_1;
  logic [1:0] age_io_out_0;
  logic [1:0] age_1_io_out_0;
  logic [1:0] age_1_io_out_1;
  logic [1:0] age_1_io_out_2;
  logic [11:0] age_2_io_out_0;

  // ---- 核接口 ----
  logic             core_enq_valid     [2];
  logic             core_enq_ready     [2];
  logic             core_enq_do        [2];
  logic [3:0]       core_enq_src_type  [2][1];
  logic [7:0]       core_enq_psrc      [2][1];
  logic             core_enq_src_state [2][1];
  logic [1:0]       core_enq_src_ld    [2][1][3];
  logic             core_st_src_state  [2][1];
  logic [3:0]       core_st_data_src   [2][1];
  logic [1:0]       core_st_src_ld     [2][1][3];
  logic [15:0]      core_ent_valid;
  logic [15:0]      core_ent_issued;
  logic [15:0]      core_ent_can_issue;
  logic [34:0]      core_ent_fu_type   [16];
  logic [3:0]       core_ent_data_src  [16][1];
  logic [2:0]       core_ent_exu_src   [16][1];
  logic [1:0]       core_ent_ld_dep    [16][3];
  logic             core_ent_cancel_deq [1];
  logic [15:0]      core_busy_mask     [1][1];
  logic [1:0]       core_age_enq_req   [1];
  logic [1:0]       core_age_simp_req  [3];
  logic [11:0]      core_age_comp_req  [1];
  logic [1:0]       core_age_enq_out   [1];
  logic [1:0]       core_age_simp_out  [3];
  logic [11:0]      core_age_comp_out  [1];
  logic             core_sel_valid     [1];
  logic [15:0]      core_sel_oh        [1];
  logic             core_simp_oldest_valid [1];
  logic             core_comp_oldest_valid [1];
  logic             core_deq_valid     [1];
  logic [3:0]       core_deq_iq_idx    [1];
  logic [3:0]       core_deq_data_src  [1][1];
  logic [2:0]       core_deq_exu_src   [1][1];
  logic [1:0]       core_deq_ld_dep    [1][3];
  logic [63:0]      core_deq_select_time [1];
  logic [63:0]      core_deq_issue_time  [1];
  logic [900:0]    core_deq0_payload;
  logic [0:0]    core_deq1_payload;
  logic             core_dly_valid     [1];
  logic [900:0]    core_dly0_payload;
  logic [0:0]    core_dly1_payload;
  logic             core_dly_ready     [1];
  logic [0:0]       core_valid_cnt     [1];
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
  logic [4:0]       core_deq_wen       [1];
  logic [4:0]       core_deq_wen_valid [1];
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

  // ---- 核输入 ----
  assign core_enq_valid[0] = io_enq_0_valid;
  assign core_enq_src_type[0][0] = io_enq_0_bits_srcType_0;
  assign core_enq_psrc[0][0] = io_enq_0_bits_psrc_0;
  assign core_enq_src_state[0][0] = io_enq_0_bits_srcState_0;
  assign core_enq_src_ld[0][0][0] = io_enq_0_bits_srcLoadDependency_0_0;
  assign core_enq_src_ld[0][0][1] = io_enq_0_bits_srcLoadDependency_0_1;
  assign core_enq_src_ld[0][0][2] = io_enq_0_bits_srcLoadDependency_0_2;
  assign core_enq_valid[1] = io_enq_1_valid;
  assign core_enq_src_type[1][0] = io_enq_1_bits_srcType_0;
  assign core_enq_psrc[1][0] = io_enq_1_bits_psrc_0;
  assign core_enq_src_state[1][0] = io_enq_1_bits_srcState_0;
  assign core_enq_src_ld[1][0][0] = io_enq_1_bits_srcLoadDependency_0_0;
  assign core_enq_src_ld[1][0][1] = io_enq_1_bits_srcLoadDependency_0_1;
  assign core_enq_src_ld[1][0][2] = io_enq_1_bits_srcLoadDependency_0_2;
  assign core_ent_valid = entries_io_valid;
  assign core_ent_issued = entries_io_issued;
  assign core_ent_can_issue = entries_io_canIssue;
  assign core_ent_fu_type[0] = entries_io_fuType_0;
  assign core_ent_data_src[0][0] = entries_io_dataSources_0_0_value;
  assign core_ent_exu_src[0][0] = entries_io_exuSources_0_0_value;
  assign core_ent_ld_dep[0][0] = entries_io_loadDependency_0_0;
  assign core_ent_ld_dep[0][1] = entries_io_loadDependency_0_1;
  assign core_ent_ld_dep[0][2] = entries_io_loadDependency_0_2;
  assign core_ent_fu_type[1] = entries_io_fuType_1;
  assign core_ent_data_src[1][0] = entries_io_dataSources_1_0_value;
  assign core_ent_exu_src[1][0] = entries_io_exuSources_1_0_value;
  assign core_ent_ld_dep[1][0] = entries_io_loadDependency_1_0;
  assign core_ent_ld_dep[1][1] = entries_io_loadDependency_1_1;
  assign core_ent_ld_dep[1][2] = entries_io_loadDependency_1_2;
  assign core_ent_fu_type[2] = entries_io_fuType_2;
  assign core_ent_data_src[2][0] = entries_io_dataSources_2_0_value;
  assign core_ent_exu_src[2][0] = entries_io_exuSources_2_0_value;
  assign core_ent_ld_dep[2][0] = entries_io_loadDependency_2_0;
  assign core_ent_ld_dep[2][1] = entries_io_loadDependency_2_1;
  assign core_ent_ld_dep[2][2] = entries_io_loadDependency_2_2;
  assign core_ent_fu_type[3] = entries_io_fuType_3;
  assign core_ent_data_src[3][0] = entries_io_dataSources_3_0_value;
  assign core_ent_exu_src[3][0] = entries_io_exuSources_3_0_value;
  assign core_ent_ld_dep[3][0] = entries_io_loadDependency_3_0;
  assign core_ent_ld_dep[3][1] = entries_io_loadDependency_3_1;
  assign core_ent_ld_dep[3][2] = entries_io_loadDependency_3_2;
  assign core_ent_fu_type[4] = entries_io_fuType_4;
  assign core_ent_data_src[4][0] = entries_io_dataSources_4_0_value;
  assign core_ent_exu_src[4][0] = entries_io_exuSources_4_0_value;
  assign core_ent_ld_dep[4][0] = entries_io_loadDependency_4_0;
  assign core_ent_ld_dep[4][1] = entries_io_loadDependency_4_1;
  assign core_ent_ld_dep[4][2] = entries_io_loadDependency_4_2;
  assign core_ent_fu_type[5] = entries_io_fuType_5;
  assign core_ent_data_src[5][0] = entries_io_dataSources_5_0_value;
  assign core_ent_exu_src[5][0] = entries_io_exuSources_5_0_value;
  assign core_ent_ld_dep[5][0] = entries_io_loadDependency_5_0;
  assign core_ent_ld_dep[5][1] = entries_io_loadDependency_5_1;
  assign core_ent_ld_dep[5][2] = entries_io_loadDependency_5_2;
  assign core_ent_fu_type[6] = entries_io_fuType_6;
  assign core_ent_data_src[6][0] = entries_io_dataSources_6_0_value;
  assign core_ent_exu_src[6][0] = entries_io_exuSources_6_0_value;
  assign core_ent_ld_dep[6][0] = entries_io_loadDependency_6_0;
  assign core_ent_ld_dep[6][1] = entries_io_loadDependency_6_1;
  assign core_ent_ld_dep[6][2] = entries_io_loadDependency_6_2;
  assign core_ent_fu_type[7] = entries_io_fuType_7;
  assign core_ent_data_src[7][0] = entries_io_dataSources_7_0_value;
  assign core_ent_exu_src[7][0] = entries_io_exuSources_7_0_value;
  assign core_ent_ld_dep[7][0] = entries_io_loadDependency_7_0;
  assign core_ent_ld_dep[7][1] = entries_io_loadDependency_7_1;
  assign core_ent_ld_dep[7][2] = entries_io_loadDependency_7_2;
  assign core_ent_fu_type[8] = entries_io_fuType_8;
  assign core_ent_data_src[8][0] = entries_io_dataSources_8_0_value;
  assign core_ent_exu_src[8][0] = entries_io_exuSources_8_0_value;
  assign core_ent_ld_dep[8][0] = entries_io_loadDependency_8_0;
  assign core_ent_ld_dep[8][1] = entries_io_loadDependency_8_1;
  assign core_ent_ld_dep[8][2] = entries_io_loadDependency_8_2;
  assign core_ent_fu_type[9] = entries_io_fuType_9;
  assign core_ent_data_src[9][0] = entries_io_dataSources_9_0_value;
  assign core_ent_exu_src[9][0] = entries_io_exuSources_9_0_value;
  assign core_ent_ld_dep[9][0] = entries_io_loadDependency_9_0;
  assign core_ent_ld_dep[9][1] = entries_io_loadDependency_9_1;
  assign core_ent_ld_dep[9][2] = entries_io_loadDependency_9_2;
  assign core_ent_fu_type[10] = entries_io_fuType_10;
  assign core_ent_data_src[10][0] = entries_io_dataSources_10_0_value;
  assign core_ent_exu_src[10][0] = entries_io_exuSources_10_0_value;
  assign core_ent_ld_dep[10][0] = entries_io_loadDependency_10_0;
  assign core_ent_ld_dep[10][1] = entries_io_loadDependency_10_1;
  assign core_ent_ld_dep[10][2] = entries_io_loadDependency_10_2;
  assign core_ent_fu_type[11] = entries_io_fuType_11;
  assign core_ent_data_src[11][0] = entries_io_dataSources_11_0_value;
  assign core_ent_exu_src[11][0] = entries_io_exuSources_11_0_value;
  assign core_ent_ld_dep[11][0] = entries_io_loadDependency_11_0;
  assign core_ent_ld_dep[11][1] = entries_io_loadDependency_11_1;
  assign core_ent_ld_dep[11][2] = entries_io_loadDependency_11_2;
  assign core_ent_fu_type[12] = entries_io_fuType_12;
  assign core_ent_data_src[12][0] = entries_io_dataSources_12_0_value;
  assign core_ent_exu_src[12][0] = entries_io_exuSources_12_0_value;
  assign core_ent_ld_dep[12][0] = entries_io_loadDependency_12_0;
  assign core_ent_ld_dep[12][1] = entries_io_loadDependency_12_1;
  assign core_ent_ld_dep[12][2] = entries_io_loadDependency_12_2;
  assign core_ent_fu_type[13] = entries_io_fuType_13;
  assign core_ent_data_src[13][0] = entries_io_dataSources_13_0_value;
  assign core_ent_exu_src[13][0] = entries_io_exuSources_13_0_value;
  assign core_ent_ld_dep[13][0] = entries_io_loadDependency_13_0;
  assign core_ent_ld_dep[13][1] = entries_io_loadDependency_13_1;
  assign core_ent_ld_dep[13][2] = entries_io_loadDependency_13_2;
  assign core_ent_fu_type[14] = entries_io_fuType_14;
  assign core_ent_data_src[14][0] = entries_io_dataSources_14_0_value;
  assign core_ent_exu_src[14][0] = entries_io_exuSources_14_0_value;
  assign core_ent_ld_dep[14][0] = entries_io_loadDependency_14_0;
  assign core_ent_ld_dep[14][1] = entries_io_loadDependency_14_1;
  assign core_ent_ld_dep[14][2] = entries_io_loadDependency_14_2;
  assign core_ent_fu_type[15] = entries_io_fuType_15;
  assign core_ent_data_src[15][0] = entries_io_dataSources_15_0_value;
  assign core_ent_exu_src[15][0] = entries_io_exuSources_15_0_value;
  assign core_ent_ld_dep[15][0] = entries_io_loadDependency_15_0;
  assign core_ent_ld_dep[15][1] = entries_io_loadDependency_15_1;
  assign core_ent_ld_dep[15][2] = entries_io_loadDependency_15_2;
  assign core_ent_cancel_deq[0] = entries_io_cancelDeqVec_0;
  assign core_busy_mask[0][0] = '0;
  assign core_dly_ready[0] = io_deqDelay_0_ready;
  assign core_enq_lq_idx[0] = '0;
  assign core_enq_is_vleff[0] = 1'h0;
  assign core_enq_lq_idx[1] = '0;
  assign core_enq_is_vleff[1] = 1'h0;
  assign core_lq_deq_ptr = '0;
  assign core_deq_wen[0] = {1'h0, 1'h0, 1'h0, 1'h0, 1'h0};   // {vl, v0, vec, fp, rf}Wen
  assign core_ldw_valid = 1'h0;
  assign core_ldw_rf_wen = 1'h0;
  assign core_ldw_fp_wen = 1'h0;
  assign core_ldw_pdest = '0;
  assign core_age_enq_out[0] = age_io_out_0;
  assign core_age_comp_out[0] = age_2_io_out_0;
  assign core_age_simp_out[0] = age_1_io_out_0;
  assign core_age_simp_out[1] = age_1_io_out_1;
  assign core_age_simp_out[2] = age_1_io_out_2;

  // ---- 口 0 deqDelay 负载（golden 寄存器声明顺序，高位在前）----
  assign core_deq0_payload = {
    entries_io_deqEntry_0_bits_status_srcStatus_0_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_0_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx,
    entries_io_deqEntry_0_bits_payload_selImm,
    {17'h0, entries_io_deqEntry_0_bits_status_fuType_17, entries_io_deqEntry_0_bits_status_fuType_16, 16'h0},
    entries_io_deqEntry_0_bits_payload_fuOpType,
    64'h0,
    64'h0,
    entries_io_deqEntry_0_bits_status_robIdx_flag,
    entries_io_deqEntry_0_bits_status_robIdx_value,
    core_deq_iq_idx[0],
    entries_io_isFirstIssue_0,
    entries_io_deqEntry_0_bits_payload_sqIdx_flag,
    entries_io_deqEntry_0_bits_payload_sqIdx_value,
    core_deq_data_src[0][0],
    core_deq_exu_src[0][0],
    3'h0,
    core_deq_ld_dep[0][0],
    core_deq_ld_dep[0][1],
    core_deq_ld_dep[0][2],
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
  wire [7:0] dly0_bits_rf_0_1_addr = core_dly0_payload[900:893];
  wire [2:0] dly0_bits_rf_0_1_srcType = core_dly0_payload[892:890];
  wire [7:0] dly0_bits_rf_0_0_addr = core_dly0_payload[889:882];
  wire [2:0] dly0_bits_rf_0_0_srcType = core_dly0_payload[881:879];
  wire [3:0] dly0_bits_srcType_0 = core_dly0_payload[878:875];
  wire [4:0] dly0_bits_rcIdx_0 = core_dly0_payload[874:870];
  wire [3:0] dly0_bits_immType = core_dly0_payload[869:866];
  wire [34:0] dly0_bits_common_fuType = core_dly0_payload[865:831];
  wire [8:0] dly0_bits_common_fuOpType = core_dly0_payload[830:822];
  wire [63:0] dly0_bits_common_src_0 = core_dly0_payload[821:758];
  wire [63:0] dly0_bits_common_imm = core_dly0_payload[757:694];
  wire dly0_bits_common_robIdx_flag = core_dly0_payload[693:693];
  wire [7:0] dly0_bits_common_robIdx_value = core_dly0_payload[692:685];
  wire [3:0] dly0_bits_common_iqIdx = core_dly0_payload[684:681];
  wire dly0_bits_common_isFirstIssue = core_dly0_payload[680:680];
  wire dly0_bits_common_sqIdx_flag = core_dly0_payload[679:679];
  wire [5:0] dly0_bits_common_sqIdx_value = core_dly0_payload[678:673];
  wire [3:0] dly0_bits_common_dataSources_0_value = core_dly0_payload[672:669];
  wire [2:0] dly0_bits_common_exuSources_0_value = core_dly0_payload[668:666];
  wire [2:0] dly0_bits_common_srcTimer_0 = core_dly0_payload[665:663];
  wire [1:0] dly0_bits_common_loadDependency_0 = core_dly0_payload[662:661];
  wire [1:0] dly0_bits_common_loadDependency_1 = core_dly0_payload[660:659];
  wire [1:0] dly0_bits_common_loadDependency_2 = core_dly0_payload[658:657];
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

  assign core_deq1_payload = 1'h0;
  EntriesStdMoud entries (
    .clock                                                       (clock),
    .reset                                                       (reset),
    .io_flush_valid                                              (io_flush_valid),
    .io_flush_bits_robIdx_flag                                   (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value                                  (io_flush_bits_robIdx_value),
    .io_flush_bits_level                                         (io_flush_bits_level),
    .io_enq_0_valid                                              (core_enq_do[0]),
    .io_enq_0_bits_status_robIdx_flag                            (io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value                           (io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_status_fuType_16                              (io_enq_0_bits_fuType[16]),
    .io_enq_0_bits_status_fuType_17                              (io_enq_0_bits_fuType[17]),
    .io_enq_0_bits_status_srcStatus_0_psrc                       (io_enq_0_bits_psrc_0),
    .io_enq_0_bits_status_srcStatus_0_srcType                    (io_enq_0_bits_srcType_0),
    .io_enq_0_bits_status_srcStatus_0_srcState                   (core_st_src_state[0][0]),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value          (core_st_data_src[0][0]),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0        (core_st_src_ld[0][0][0]),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1        (core_st_src_ld[0][0][1]),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2        (core_st_src_ld[0][0][2]),
    .io_enq_0_bits_status_srcStatus_0_useRegCache                (io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_status_srcStatus_0_regCacheIdx                (io_enq_0_bits_regCacheIdx_0),
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
    .io_enq_0_bits_payload_srcLoadDependency_0_0                 (io_enq_0_bits_srcLoadDependency_0_0),
    .io_enq_0_bits_payload_srcLoadDependency_0_1                 (io_enq_0_bits_srcLoadDependency_0_1),
    .io_enq_0_bits_payload_srcLoadDependency_0_2                 (io_enq_0_bits_srcLoadDependency_0_2),
    .io_enq_0_bits_payload_srcLoadDependency_1_0                 (io_enq_0_bits_srcLoadDependency_1_0),
    .io_enq_0_bits_payload_srcLoadDependency_1_1                 (io_enq_0_bits_srcLoadDependency_1_1),
    .io_enq_0_bits_payload_srcLoadDependency_1_2                 (io_enq_0_bits_srcLoadDependency_1_2),
    .io_enq_0_bits_payload_srcLoadDependency_2_0                 (io_enq_0_bits_srcLoadDependency_2_0),
    .io_enq_0_bits_payload_srcLoadDependency_2_1                 (io_enq_0_bits_srcLoadDependency_2_1),
    .io_enq_0_bits_payload_srcLoadDependency_2_2                 (io_enq_0_bits_srcLoadDependency_2_2),
    .io_enq_0_bits_payload_srcLoadDependency_3_0                 (io_enq_0_bits_srcLoadDependency_3_0),
    .io_enq_0_bits_payload_srcLoadDependency_3_1                 (io_enq_0_bits_srcLoadDependency_3_1),
    .io_enq_0_bits_payload_srcLoadDependency_3_2                 (io_enq_0_bits_srcLoadDependency_3_2),
    .io_enq_0_bits_payload_srcLoadDependency_4_0                 (io_enq_0_bits_srcLoadDependency_4_0),
    .io_enq_0_bits_payload_srcLoadDependency_4_1                 (io_enq_0_bits_srcLoadDependency_4_1),
    .io_enq_0_bits_payload_srcLoadDependency_4_2                 (io_enq_0_bits_srcLoadDependency_4_2),
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
    .io_enq_1_bits_status_fuType_16                              (io_enq_1_bits_fuType[16]),
    .io_enq_1_bits_status_fuType_17                              (io_enq_1_bits_fuType[17]),
    .io_enq_1_bits_status_srcStatus_0_psrc                       (io_enq_1_bits_psrc_0),
    .io_enq_1_bits_status_srcStatus_0_srcType                    (io_enq_1_bits_srcType_0),
    .io_enq_1_bits_status_srcStatus_0_srcState                   (core_st_src_state[1][0]),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value          (core_st_data_src[1][0]),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0        (core_st_src_ld[1][0][0]),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1        (core_st_src_ld[1][0][1]),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2        (core_st_src_ld[1][0][2]),
    .io_enq_1_bits_status_srcStatus_0_useRegCache                (io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_status_srcStatus_0_regCacheIdx                (io_enq_1_bits_regCacheIdx_0),
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
    .io_enq_1_bits_payload_srcLoadDependency_0_0                 (io_enq_1_bits_srcLoadDependency_0_0),
    .io_enq_1_bits_payload_srcLoadDependency_0_1                 (io_enq_1_bits_srcLoadDependency_0_1),
    .io_enq_1_bits_payload_srcLoadDependency_0_2                 (io_enq_1_bits_srcLoadDependency_0_2),
    .io_enq_1_bits_payload_srcLoadDependency_1_0                 (io_enq_1_bits_srcLoadDependency_1_0),
    .io_enq_1_bits_payload_srcLoadDependency_1_1                 (io_enq_1_bits_srcLoadDependency_1_1),
    .io_enq_1_bits_payload_srcLoadDependency_1_2                 (io_enq_1_bits_srcLoadDependency_1_2),
    .io_enq_1_bits_payload_srcLoadDependency_2_0                 (io_enq_1_bits_srcLoadDependency_2_0),
    .io_enq_1_bits_payload_srcLoadDependency_2_1                 (io_enq_1_bits_srcLoadDependency_2_1),
    .io_enq_1_bits_payload_srcLoadDependency_2_2                 (io_enq_1_bits_srcLoadDependency_2_2),
    .io_enq_1_bits_payload_srcLoadDependency_3_0                 (io_enq_1_bits_srcLoadDependency_3_0),
    .io_enq_1_bits_payload_srcLoadDependency_3_1                 (io_enq_1_bits_srcLoadDependency_3_1),
    .io_enq_1_bits_payload_srcLoadDependency_3_2                 (io_enq_1_bits_srcLoadDependency_3_2),
    .io_enq_1_bits_payload_srcLoadDependency_4_0                 (io_enq_1_bits_srcLoadDependency_4_0),
    .io_enq_1_bits_payload_srcLoadDependency_4_1                 (io_enq_1_bits_srcLoadDependency_4_1),
    .io_enq_1_bits_payload_srcLoadDependency_4_2                 (io_enq_1_bits_srcLoadDependency_4_2),
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
    .io_og0Resp_0_bits_resp                                      (io_og0Resp_0_bits_resp),
    .io_og1Resp_0_valid                                          (io_og1Resp_0_valid),
    .io_og1Resp_0_bits_resp                                      (io_og1Resp_0_bits_resp),
    .io_deqReady_0                                               (1'h1),
    .io_deqSelOH_0_valid                                         (core_sel_valid[0]),
    .io_deqSelOH_0_bits                                          (core_sel_oh[0]),
    .io_enqEntryOldestSel_0_bits                                 (age_io_out_0),
    .io_simpEntryOldestSel_0_valid                               (core_simp_oldest_valid[0]),
    .io_simpEntryOldestSel_0_bits                                (age_1_io_out_0),
    .io_compEntryOldestSel_0_valid                               (core_comp_oldest_valid[0]),
    .io_compEntryOldestSel_0_bits                                (age_2_io_out_0),
    .io_wakeUpFromWB_9_valid                                     (io_wakeupFromWB_9_valid),
    .io_wakeUpFromWB_9_bits_rfWen                                (io_wakeupFromWB_9_bits_rfWen),
    .io_wakeUpFromWB_9_bits_fpWen                                (io_wakeupFromWB_9_bits_fpWen),
    .io_wakeUpFromWB_9_bits_vecWen                               (io_wakeupFromWB_9_bits_vecWen),
    .io_wakeUpFromWB_9_bits_pdest                                (io_wakeupFromWB_9_bits_pdest),
    .io_wakeUpFromWB_8_valid                                     (io_wakeupFromWB_8_valid),
    .io_wakeUpFromWB_8_bits_rfWen                                (io_wakeupFromWB_8_bits_rfWen),
    .io_wakeUpFromWB_8_bits_fpWen                                (io_wakeupFromWB_8_bits_fpWen),
    .io_wakeUpFromWB_8_bits_vecWen                               (io_wakeupFromWB_8_bits_vecWen),
    .io_wakeUpFromWB_8_bits_pdest                                (io_wakeupFromWB_8_bits_pdest),
    .io_wakeUpFromWB_7_valid                                     (io_wakeupFromWB_7_valid),
    .io_wakeUpFromWB_7_bits_rfWen                                (io_wakeupFromWB_7_bits_rfWen),
    .io_wakeUpFromWB_7_bits_fpWen                                (io_wakeupFromWB_7_bits_fpWen),
    .io_wakeUpFromWB_7_bits_vecWen                               (io_wakeupFromWB_7_bits_vecWen),
    .io_wakeUpFromWB_7_bits_pdest                                (io_wakeupFromWB_7_bits_pdest),
    .io_wakeUpFromWB_6_valid                                     (io_wakeupFromWB_6_valid),
    .io_wakeUpFromWB_6_bits_rfWen                                (io_wakeupFromWB_6_bits_rfWen),
    .io_wakeUpFromWB_6_bits_fpWen                                (io_wakeupFromWB_6_bits_fpWen),
    .io_wakeUpFromWB_6_bits_vecWen                               (io_wakeupFromWB_6_bits_vecWen),
    .io_wakeUpFromWB_6_bits_pdest                                (io_wakeupFromWB_6_bits_pdest),
    .io_wakeUpFromWB_5_valid                                     (io_wakeupFromWB_5_valid),
    .io_wakeUpFromWB_5_bits_rfWen                                (io_wakeupFromWB_5_bits_rfWen),
    .io_wakeUpFromWB_5_bits_fpWen                                (io_wakeupFromWB_5_bits_fpWen),
    .io_wakeUpFromWB_5_bits_vecWen                               (io_wakeupFromWB_5_bits_vecWen),
    .io_wakeUpFromWB_5_bits_pdest                                (io_wakeupFromWB_5_bits_pdest),
    .io_wakeUpFromWB_4_valid                                     (io_wakeupFromWB_4_valid),
    .io_wakeUpFromWB_4_bits_rfWen                                (io_wakeupFromWB_4_bits_rfWen),
    .io_wakeUpFromWB_4_bits_fpWen                                (io_wakeupFromWB_4_bits_fpWen),
    .io_wakeUpFromWB_4_bits_vecWen                               (io_wakeupFromWB_4_bits_vecWen),
    .io_wakeUpFromWB_4_bits_pdest                                (io_wakeupFromWB_4_bits_pdest),
    .io_wakeUpFromWB_3_valid                                     (io_wakeupFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_rfWen                                (io_wakeupFromWB_3_bits_rfWen),
    .io_wakeUpFromWB_3_bits_fpWen                                (io_wakeupFromWB_3_bits_fpWen),
    .io_wakeUpFromWB_3_bits_vecWen                               (io_wakeupFromWB_3_bits_vecWen),
    .io_wakeUpFromWB_3_bits_pdest                                (io_wakeupFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid                                     (io_wakeupFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_rfWen                                (io_wakeupFromWB_2_bits_rfWen),
    .io_wakeUpFromWB_2_bits_fpWen                                (io_wakeupFromWB_2_bits_fpWen),
    .io_wakeUpFromWB_2_bits_vecWen                               (io_wakeupFromWB_2_bits_vecWen),
    .io_wakeUpFromWB_2_bits_pdest                                (io_wakeupFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid                                     (io_wakeupFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_rfWen                                (io_wakeupFromWB_1_bits_rfWen),
    .io_wakeUpFromWB_1_bits_fpWen                                (io_wakeupFromWB_1_bits_fpWen),
    .io_wakeUpFromWB_1_bits_vecWen                               (io_wakeupFromWB_1_bits_vecWen),
    .io_wakeUpFromWB_1_bits_pdest                                (io_wakeupFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid                                     (io_wakeupFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_rfWen                                (io_wakeupFromWB_0_bits_rfWen),
    .io_wakeUpFromWB_0_bits_fpWen                                (io_wakeupFromWB_0_bits_fpWen),
    .io_wakeUpFromWB_0_bits_vecWen                               (io_wakeupFromWB_0_bits_vecWen),
    .io_wakeUpFromWB_0_bits_pdest                                (io_wakeupFromWB_0_bits_pdest),
    .io_wakeUpFromIQ_6_bits_rfWen                                (io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeUpFromIQ_6_bits_pdest                                (io_wakeupFromIQ_6_bits_pdest),
    .io_wakeUpFromIQ_6_bits_loadDependency_0                     (io_wakeupFromIQ_6_bits_loadDependency_0),
    .io_wakeUpFromIQ_6_bits_loadDependency_1                     (io_wakeupFromIQ_6_bits_loadDependency_1),
    .io_wakeUpFromIQ_6_bits_loadDependency_2                     (io_wakeupFromIQ_6_bits_loadDependency_2),
    .io_wakeUpFromIQ_6_bits_is0Lat                               (io_wakeupFromIQ_6_bits_is0Lat),
    .io_wakeUpFromIQ_6_bits_rcDest                               (io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeUpFromIQ_5_bits_rfWen                                (io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeUpFromIQ_5_bits_pdest                                (io_wakeupFromIQ_5_bits_pdest),
    .io_wakeUpFromIQ_5_bits_loadDependency_0                     (io_wakeupFromIQ_5_bits_loadDependency_0),
    .io_wakeUpFromIQ_5_bits_loadDependency_1                     (io_wakeupFromIQ_5_bits_loadDependency_1),
    .io_wakeUpFromIQ_5_bits_loadDependency_2                     (io_wakeupFromIQ_5_bits_loadDependency_2),
    .io_wakeUpFromIQ_5_bits_is0Lat                               (io_wakeupFromIQ_5_bits_is0Lat),
    .io_wakeUpFromIQ_5_bits_rcDest                               (io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeUpFromIQ_4_bits_rfWen                                (io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeUpFromIQ_4_bits_pdest                                (io_wakeupFromIQ_4_bits_pdest),
    .io_wakeUpFromIQ_4_bits_loadDependency_0                     (io_wakeupFromIQ_4_bits_loadDependency_0),
    .io_wakeUpFromIQ_4_bits_loadDependency_1                     (io_wakeupFromIQ_4_bits_loadDependency_1),
    .io_wakeUpFromIQ_4_bits_loadDependency_2                     (io_wakeupFromIQ_4_bits_loadDependency_2),
    .io_wakeUpFromIQ_4_bits_is0Lat                               (io_wakeupFromIQ_4_bits_is0Lat),
    .io_wakeUpFromIQ_4_bits_rcDest                               (io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeUpFromIQ_3_bits_rfWen                                (io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeUpFromIQ_3_bits_pdest                                (io_wakeupFromIQ_3_bits_pdest),
    .io_wakeUpFromIQ_3_bits_loadDependency_0                     (io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeUpFromIQ_3_bits_loadDependency_1                     (io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeUpFromIQ_3_bits_loadDependency_2                     (io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeUpFromIQ_3_bits_is0Lat                               (io_wakeupFromIQ_3_bits_is0Lat),
    .io_wakeUpFromIQ_3_bits_rcDest                               (io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeUpFromIQ_2_bits_rfWen                                (io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeUpFromIQ_2_bits_pdest                                (io_wakeupFromIQ_2_bits_pdest),
    .io_wakeUpFromIQ_2_bits_loadDependency_0                     (io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeUpFromIQ_2_bits_loadDependency_1                     (io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeUpFromIQ_2_bits_loadDependency_2                     (io_wakeupFromIQ_2_bits_loadDependency_2),
    .io_wakeUpFromIQ_2_bits_is0Lat                               (io_wakeupFromIQ_2_bits_is0Lat),
    .io_wakeUpFromIQ_2_bits_rcDest                               (io_wakeupFromIQ_2_bits_rcDest),
    .io_wakeUpFromIQ_1_bits_rfWen                                (io_wakeupFromIQ_1_bits_rfWen),
    .io_wakeUpFromIQ_1_bits_pdest                                (io_wakeupFromIQ_1_bits_pdest),
    .io_wakeUpFromIQ_1_bits_loadDependency_0                     (io_wakeupFromIQ_1_bits_loadDependency_0),
    .io_wakeUpFromIQ_1_bits_loadDependency_1                     (io_wakeupFromIQ_1_bits_loadDependency_1),
    .io_wakeUpFromIQ_1_bits_loadDependency_2                     (io_wakeupFromIQ_1_bits_loadDependency_2),
    .io_wakeUpFromIQ_1_bits_is0Lat                               (io_wakeupFromIQ_1_bits_is0Lat),
    .io_wakeUpFromIQ_1_bits_rcDest                               (io_wakeupFromIQ_1_bits_rcDest),
    .io_wakeUpFromIQ_0_bits_rfWen                                (io_wakeupFromIQ_0_bits_rfWen),
    .io_wakeUpFromIQ_0_bits_pdest                                (io_wakeupFromIQ_0_bits_pdest),
    .io_wakeUpFromIQ_0_bits_loadDependency_0                     (io_wakeupFromIQ_0_bits_loadDependency_0),
    .io_wakeUpFromIQ_0_bits_loadDependency_1                     (io_wakeupFromIQ_0_bits_loadDependency_1),
    .io_wakeUpFromIQ_0_bits_loadDependency_2                     (io_wakeupFromIQ_0_bits_loadDependency_2),
    .io_wakeUpFromIQ_0_bits_is0Lat                               (io_wakeupFromIQ_0_bits_is0Lat),
    .io_wakeUpFromIQ_0_bits_rcDest                               (io_wakeupFromIQ_0_bits_rcDest),
    .io_wakeUpFromWBDelayed_9_valid                              (io_wakeupFromWBDelayed_9_valid),
    .io_wakeUpFromWBDelayed_9_bits_rfWen                         (io_wakeupFromWBDelayed_9_bits_rfWen),
    .io_wakeUpFromWBDelayed_9_bits_fpWen                         (io_wakeupFromWBDelayed_9_bits_fpWen),
    .io_wakeUpFromWBDelayed_9_bits_vecWen                        (io_wakeupFromWBDelayed_9_bits_vecWen),
    .io_wakeUpFromWBDelayed_9_bits_pdest                         (io_wakeupFromWBDelayed_9_bits_pdest),
    .io_wakeUpFromWBDelayed_8_valid                              (io_wakeupFromWBDelayed_8_valid),
    .io_wakeUpFromWBDelayed_8_bits_rfWen                         (io_wakeupFromWBDelayed_8_bits_rfWen),
    .io_wakeUpFromWBDelayed_8_bits_fpWen                         (io_wakeupFromWBDelayed_8_bits_fpWen),
    .io_wakeUpFromWBDelayed_8_bits_vecWen                        (io_wakeupFromWBDelayed_8_bits_vecWen),
    .io_wakeUpFromWBDelayed_8_bits_pdest                         (io_wakeupFromWBDelayed_8_bits_pdest),
    .io_wakeUpFromWBDelayed_7_valid                              (io_wakeupFromWBDelayed_7_valid),
    .io_wakeUpFromWBDelayed_7_bits_rfWen                         (io_wakeupFromWBDelayed_7_bits_rfWen),
    .io_wakeUpFromWBDelayed_7_bits_fpWen                         (io_wakeupFromWBDelayed_7_bits_fpWen),
    .io_wakeUpFromWBDelayed_7_bits_vecWen                        (io_wakeupFromWBDelayed_7_bits_vecWen),
    .io_wakeUpFromWBDelayed_7_bits_pdest                         (io_wakeupFromWBDelayed_7_bits_pdest),
    .io_wakeUpFromWBDelayed_6_valid                              (io_wakeupFromWBDelayed_6_valid),
    .io_wakeUpFromWBDelayed_6_bits_rfWen                         (io_wakeupFromWBDelayed_6_bits_rfWen),
    .io_wakeUpFromWBDelayed_6_bits_fpWen                         (io_wakeupFromWBDelayed_6_bits_fpWen),
    .io_wakeUpFromWBDelayed_6_bits_vecWen                        (io_wakeupFromWBDelayed_6_bits_vecWen),
    .io_wakeUpFromWBDelayed_6_bits_pdest                         (io_wakeupFromWBDelayed_6_bits_pdest),
    .io_wakeUpFromWBDelayed_5_valid                              (io_wakeupFromWBDelayed_5_valid),
    .io_wakeUpFromWBDelayed_5_bits_rfWen                         (io_wakeupFromWBDelayed_5_bits_rfWen),
    .io_wakeUpFromWBDelayed_5_bits_fpWen                         (io_wakeupFromWBDelayed_5_bits_fpWen),
    .io_wakeUpFromWBDelayed_5_bits_vecWen                        (io_wakeupFromWBDelayed_5_bits_vecWen),
    .io_wakeUpFromWBDelayed_5_bits_pdest                         (io_wakeupFromWBDelayed_5_bits_pdest),
    .io_wakeUpFromWBDelayed_4_valid                              (io_wakeupFromWBDelayed_4_valid),
    .io_wakeUpFromWBDelayed_4_bits_rfWen                         (io_wakeupFromWBDelayed_4_bits_rfWen),
    .io_wakeUpFromWBDelayed_4_bits_fpWen                         (io_wakeupFromWBDelayed_4_bits_fpWen),
    .io_wakeUpFromWBDelayed_4_bits_vecWen                        (io_wakeupFromWBDelayed_4_bits_vecWen),
    .io_wakeUpFromWBDelayed_4_bits_pdest                         (io_wakeupFromWBDelayed_4_bits_pdest),
    .io_wakeUpFromWBDelayed_3_valid                              (io_wakeupFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_rfWen                         (io_wakeupFromWBDelayed_3_bits_rfWen),
    .io_wakeUpFromWBDelayed_3_bits_fpWen                         (io_wakeupFromWBDelayed_3_bits_fpWen),
    .io_wakeUpFromWBDelayed_3_bits_vecWen                        (io_wakeupFromWBDelayed_3_bits_vecWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest                         (io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid                              (io_wakeupFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_rfWen                         (io_wakeupFromWBDelayed_2_bits_rfWen),
    .io_wakeUpFromWBDelayed_2_bits_fpWen                         (io_wakeupFromWBDelayed_2_bits_fpWen),
    .io_wakeUpFromWBDelayed_2_bits_vecWen                        (io_wakeupFromWBDelayed_2_bits_vecWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest                         (io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid                              (io_wakeupFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_rfWen                         (io_wakeupFromWBDelayed_1_bits_rfWen),
    .io_wakeUpFromWBDelayed_1_bits_fpWen                         (io_wakeupFromWBDelayed_1_bits_fpWen),
    .io_wakeUpFromWBDelayed_1_bits_vecWen                        (io_wakeupFromWBDelayed_1_bits_vecWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest                         (io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid                              (io_wakeupFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_rfWen                         (io_wakeupFromWBDelayed_0_bits_rfWen),
    .io_wakeUpFromWBDelayed_0_bits_fpWen                         (io_wakeupFromWBDelayed_0_bits_fpWen),
    .io_wakeUpFromWBDelayed_0_bits_vecWen                        (io_wakeupFromWBDelayed_0_bits_vecWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest                         (io_wakeupFromWBDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_rfWen                         (io_wakeupFromIQDelayed_6_bits_rfWen),
    .io_wakeUpFromIQDelayed_6_bits_fpWen                         (io_wakeupFromIQDelayed_6_bits_fpWen),
    .io_wakeUpFromIQDelayed_6_bits_pdest                         (io_wakeupFromIQDelayed_6_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_loadDependency_0              (io_wakeupFromIQDelayed_6_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_6_bits_loadDependency_1              (io_wakeupFromIQDelayed_6_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_6_bits_loadDependency_2              (io_wakeupFromIQDelayed_6_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_6_bits_is0Lat                        (io_wakeupFromIQDelayed_6_bits_is0Lat),
    .io_wakeUpFromIQDelayed_6_bits_rcDest                        (io_wakeupFromIQDelayed_6_bits_rcDest),
    .io_wakeUpFromIQDelayed_5_bits_rfWen                         (io_wakeupFromIQDelayed_5_bits_rfWen),
    .io_wakeUpFromIQDelayed_5_bits_fpWen                         (io_wakeupFromIQDelayed_5_bits_fpWen),
    .io_wakeUpFromIQDelayed_5_bits_pdest                         (io_wakeupFromIQDelayed_5_bits_pdest),
    .io_wakeUpFromIQDelayed_5_bits_loadDependency_0              (io_wakeupFromIQDelayed_5_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_5_bits_loadDependency_1              (io_wakeupFromIQDelayed_5_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_5_bits_loadDependency_2              (io_wakeupFromIQDelayed_5_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_5_bits_is0Lat                        (io_wakeupFromIQDelayed_5_bits_is0Lat),
    .io_wakeUpFromIQDelayed_5_bits_rcDest                        (io_wakeupFromIQDelayed_5_bits_rcDest),
    .io_wakeUpFromIQDelayed_4_bits_rfWen                         (io_wakeupFromIQDelayed_4_bits_rfWen),
    .io_wakeUpFromIQDelayed_4_bits_fpWen                         (io_wakeupFromIQDelayed_4_bits_fpWen),
    .io_wakeUpFromIQDelayed_4_bits_pdest                         (io_wakeupFromIQDelayed_4_bits_pdest),
    .io_wakeUpFromIQDelayed_4_bits_loadDependency_0              (io_wakeupFromIQDelayed_4_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_4_bits_loadDependency_1              (io_wakeupFromIQDelayed_4_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_4_bits_loadDependency_2              (io_wakeupFromIQDelayed_4_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_4_bits_is0Lat                        (io_wakeupFromIQDelayed_4_bits_is0Lat),
    .io_wakeUpFromIQDelayed_4_bits_rcDest                        (io_wakeupFromIQDelayed_4_bits_rcDest),
    .io_wakeUpFromIQDelayed_3_bits_rfWen                         (io_wakeupFromIQDelayed_3_bits_rfWen),
    .io_wakeUpFromIQDelayed_3_bits_fpWen                         (io_wakeupFromIQDelayed_3_bits_fpWen),
    .io_wakeUpFromIQDelayed_3_bits_pdest                         (io_wakeupFromIQDelayed_3_bits_pdest),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_0              (io_wakeupFromIQDelayed_3_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_1              (io_wakeupFromIQDelayed_3_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_2              (io_wakeupFromIQDelayed_3_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_3_bits_is0Lat                        (io_wakeupFromIQDelayed_3_bits_is0Lat),
    .io_wakeUpFromIQDelayed_3_bits_rcDest                        (io_wakeupFromIQDelayed_3_bits_rcDest),
    .io_wakeUpFromIQDelayed_2_bits_rfWen                         (io_wakeupFromIQDelayed_2_bits_rfWen),
    .io_wakeUpFromIQDelayed_2_bits_fpWen                         (io_wakeupFromIQDelayed_2_bits_fpWen),
    .io_wakeUpFromIQDelayed_2_bits_pdest                         (io_wakeupFromIQDelayed_2_bits_pdest),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_0              (io_wakeupFromIQDelayed_2_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_1              (io_wakeupFromIQDelayed_2_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_2              (io_wakeupFromIQDelayed_2_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_2_bits_is0Lat                        (io_wakeupFromIQDelayed_2_bits_is0Lat),
    .io_wakeUpFromIQDelayed_2_bits_rcDest                        (io_wakeupFromIQDelayed_2_bits_rcDest),
    .io_wakeUpFromIQDelayed_1_bits_rfWen                         (io_wakeupFromIQDelayed_1_bits_rfWen),
    .io_wakeUpFromIQDelayed_1_bits_fpWen                         (io_wakeupFromIQDelayed_1_bits_fpWen),
    .io_wakeUpFromIQDelayed_1_bits_pdest                         (io_wakeupFromIQDelayed_1_bits_pdest),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_0              (io_wakeupFromIQDelayed_1_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_1              (io_wakeupFromIQDelayed_1_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_2              (io_wakeupFromIQDelayed_1_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_1_bits_is0Lat                        (io_wakeupFromIQDelayed_1_bits_is0Lat),
    .io_wakeUpFromIQDelayed_1_bits_rcDest                        (io_wakeupFromIQDelayed_1_bits_rcDest),
    .io_wakeUpFromIQDelayed_0_bits_rfWen                         (io_wakeupFromIQDelayed_0_bits_rfWen),
    .io_wakeUpFromIQDelayed_0_bits_fpWen                         (io_wakeupFromIQDelayed_0_bits_fpWen),
    .io_wakeUpFromIQDelayed_0_bits_pdest                         (io_wakeupFromIQDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_0              (io_wakeupFromIQDelayed_0_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_1              (io_wakeupFromIQDelayed_0_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_0_bits_loadDependency_2              (io_wakeupFromIQDelayed_0_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_0_bits_is0Lat                        (io_wakeupFromIQDelayed_0_bits_is0Lat),
    .io_wakeUpFromIQDelayed_0_bits_rcDest                        (io_wakeupFromIQDelayed_0_bits_rcDest),
    .io_og0Cancel_0                                              (io_og0Cancel_0),
    .io_og0Cancel_2                                              (io_og0Cancel_2),
    .io_og0Cancel_4                                              (io_og0Cancel_4),
    .io_og0Cancel_6                                              (io_og0Cancel_6),
    .io_og0Cancel_20                                             (io_og0Cancel_20),
    .io_og0Cancel_21                                             (io_og0Cancel_21),
    .io_og0Cancel_22                                             (io_og0Cancel_22),
    .io_ldCancel_0_ld1Cancel                                     (io_ldCancel_0_ld1Cancel),
    .io_ldCancel_0_ld2Cancel                                     (io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld1Cancel                                     (io_ldCancel_1_ld1Cancel),
    .io_ldCancel_1_ld2Cancel                                     (io_ldCancel_1_ld2Cancel),
    .io_ldCancel_2_ld1Cancel                                     (io_ldCancel_2_ld1Cancel),
    .io_ldCancel_2_ld2Cancel                                     (io_ldCancel_2_ld2Cancel),
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
    .io_dataSources_1_0_value                                    (entries_io_dataSources_1_0_value),
    .io_dataSources_2_0_value                                    (entries_io_dataSources_2_0_value),
    .io_dataSources_3_0_value                                    (entries_io_dataSources_3_0_value),
    .io_dataSources_4_0_value                                    (entries_io_dataSources_4_0_value),
    .io_dataSources_5_0_value                                    (entries_io_dataSources_5_0_value),
    .io_dataSources_6_0_value                                    (entries_io_dataSources_6_0_value),
    .io_dataSources_7_0_value                                    (entries_io_dataSources_7_0_value),
    .io_dataSources_8_0_value                                    (entries_io_dataSources_8_0_value),
    .io_dataSources_9_0_value                                    (entries_io_dataSources_9_0_value),
    .io_dataSources_10_0_value                                   (entries_io_dataSources_10_0_value),
    .io_dataSources_11_0_value                                   (entries_io_dataSources_11_0_value),
    .io_dataSources_12_0_value                                   (entries_io_dataSources_12_0_value),
    .io_dataSources_13_0_value                                   (entries_io_dataSources_13_0_value),
    .io_dataSources_14_0_value                                   (entries_io_dataSources_14_0_value),
    .io_dataSources_15_0_value                                   (entries_io_dataSources_15_0_value),
    .io_loadDependency_0_0                                       (entries_io_loadDependency_0_0),
    .io_loadDependency_0_1                                       (entries_io_loadDependency_0_1),
    .io_loadDependency_0_2                                       (entries_io_loadDependency_0_2),
    .io_loadDependency_1_0                                       (entries_io_loadDependency_1_0),
    .io_loadDependency_1_1                                       (entries_io_loadDependency_1_1),
    .io_loadDependency_1_2                                       (entries_io_loadDependency_1_2),
    .io_loadDependency_2_0                                       (entries_io_loadDependency_2_0),
    .io_loadDependency_2_1                                       (entries_io_loadDependency_2_1),
    .io_loadDependency_2_2                                       (entries_io_loadDependency_2_2),
    .io_loadDependency_3_0                                       (entries_io_loadDependency_3_0),
    .io_loadDependency_3_1                                       (entries_io_loadDependency_3_1),
    .io_loadDependency_3_2                                       (entries_io_loadDependency_3_2),
    .io_loadDependency_4_0                                       (entries_io_loadDependency_4_0),
    .io_loadDependency_4_1                                       (entries_io_loadDependency_4_1),
    .io_loadDependency_4_2                                       (entries_io_loadDependency_4_2),
    .io_loadDependency_5_0                                       (entries_io_loadDependency_5_0),
    .io_loadDependency_5_1                                       (entries_io_loadDependency_5_1),
    .io_loadDependency_5_2                                       (entries_io_loadDependency_5_2),
    .io_loadDependency_6_0                                       (entries_io_loadDependency_6_0),
    .io_loadDependency_6_1                                       (entries_io_loadDependency_6_1),
    .io_loadDependency_6_2                                       (entries_io_loadDependency_6_2),
    .io_loadDependency_7_0                                       (entries_io_loadDependency_7_0),
    .io_loadDependency_7_1                                       (entries_io_loadDependency_7_1),
    .io_loadDependency_7_2                                       (entries_io_loadDependency_7_2),
    .io_loadDependency_8_0                                       (entries_io_loadDependency_8_0),
    .io_loadDependency_8_1                                       (entries_io_loadDependency_8_1),
    .io_loadDependency_8_2                                       (entries_io_loadDependency_8_2),
    .io_loadDependency_9_0                                       (entries_io_loadDependency_9_0),
    .io_loadDependency_9_1                                       (entries_io_loadDependency_9_1),
    .io_loadDependency_9_2                                       (entries_io_loadDependency_9_2),
    .io_loadDependency_10_0                                      (entries_io_loadDependency_10_0),
    .io_loadDependency_10_1                                      (entries_io_loadDependency_10_1),
    .io_loadDependency_10_2                                      (entries_io_loadDependency_10_2),
    .io_loadDependency_11_0                                      (entries_io_loadDependency_11_0),
    .io_loadDependency_11_1                                      (entries_io_loadDependency_11_1),
    .io_loadDependency_11_2                                      (entries_io_loadDependency_11_2),
    .io_loadDependency_12_0                                      (entries_io_loadDependency_12_0),
    .io_loadDependency_12_1                                      (entries_io_loadDependency_12_1),
    .io_loadDependency_12_2                                      (entries_io_loadDependency_12_2),
    .io_loadDependency_13_0                                      (entries_io_loadDependency_13_0),
    .io_loadDependency_13_1                                      (entries_io_loadDependency_13_1),
    .io_loadDependency_13_2                                      (entries_io_loadDependency_13_2),
    .io_loadDependency_14_0                                      (entries_io_loadDependency_14_0),
    .io_loadDependency_14_1                                      (entries_io_loadDependency_14_1),
    .io_loadDependency_14_2                                      (entries_io_loadDependency_14_2),
    .io_loadDependency_15_0                                      (entries_io_loadDependency_15_0),
    .io_loadDependency_15_1                                      (entries_io_loadDependency_15_1),
    .io_loadDependency_15_2                                      (entries_io_loadDependency_15_2),
    .io_exuSources_0_0_value                                     (entries_io_exuSources_0_0_value),
    .io_exuSources_1_0_value                                     (entries_io_exuSources_1_0_value),
    .io_exuSources_2_0_value                                     (entries_io_exuSources_2_0_value),
    .io_exuSources_3_0_value                                     (entries_io_exuSources_3_0_value),
    .io_exuSources_4_0_value                                     (entries_io_exuSources_4_0_value),
    .io_exuSources_5_0_value                                     (entries_io_exuSources_5_0_value),
    .io_exuSources_6_0_value                                     (entries_io_exuSources_6_0_value),
    .io_exuSources_7_0_value                                     (entries_io_exuSources_7_0_value),
    .io_exuSources_8_0_value                                     (entries_io_exuSources_8_0_value),
    .io_exuSources_9_0_value                                     (entries_io_exuSources_9_0_value),
    .io_exuSources_10_0_value                                    (entries_io_exuSources_10_0_value),
    .io_exuSources_11_0_value                                    (entries_io_exuSources_11_0_value),
    .io_exuSources_12_0_value                                    (entries_io_exuSources_12_0_value),
    .io_exuSources_13_0_value                                    (entries_io_exuSources_13_0_value),
    .io_exuSources_14_0_value                                    (entries_io_exuSources_14_0_value),
    .io_exuSources_15_0_value                                    (entries_io_exuSources_15_0_value),
    .io_isFirstIssue_0                                           (entries_io_isFirstIssue_0),
    .io_deqEntry_0_bits_status_robIdx_flag                       (entries_io_deqEntry_0_bits_status_robIdx_flag),
    .io_deqEntry_0_bits_status_robIdx_value                      (entries_io_deqEntry_0_bits_status_robIdx_value),
    .io_deqEntry_0_bits_status_fuType_16                         (entries_io_deqEntry_0_bits_status_fuType_16),
    .io_deqEntry_0_bits_status_fuType_17                         (entries_io_deqEntry_0_bits_status_fuType_17),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_0_psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_0_srcType),
    .io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx           (entries_io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx),
    .io_deqEntry_0_bits_payload_fuOpType                         (entries_io_deqEntry_0_bits_payload_fuOpType),
    .io_deqEntry_0_bits_payload_selImm                           (entries_io_deqEntry_0_bits_payload_selImm),
    .io_deqEntry_0_bits_payload_pdest                            (/* unused */),
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
    .io_deqEntry_0_bits_payload_sqIdx_flag                       (entries_io_deqEntry_0_bits_payload_sqIdx_flag),
    .io_deqEntry_0_bits_payload_sqIdx_value                      (entries_io_deqEntry_0_bits_payload_sqIdx_value),
    .io_cancelDeqVec_0                                           (entries_io_cancelDeqVec_0),
    .io_simpEntryDeqSelVec_0                                     (age_1_io_out_1),
    .io_simpEntryDeqSelVec_1                                     (age_1_io_out_2),
    .io_simpEntryEnqSelVec_0                                     (entries_io_simpEntryEnqSelVec_0),
    .io_simpEntryEnqSelVec_1                                     (entries_io_simpEntryEnqSelVec_1),
    .io_compEntryEnqSelVec_0                                     (entries_io_compEntryEnqSelVec_0),
    .io_compEntryEnqSelVec_1                                     (entries_io_compEntryEnqSelVec_1)
  );

  NewAgeDetector_6 age (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (core_enq_do[0]),
    .io_enq_1      (core_enq_do[1]),
    .io_canIssue_0 (core_age_enq_req[0]),
    .io_out_0      (age_io_out_0)
  );

  AgeDetector_12 age_1 (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (entries_io_simpEntryEnqSelVec_0),
    .io_enq_1      (entries_io_simpEntryEnqSelVec_1),
    .io_canIssue_0 (core_age_simp_req[0]),
    .io_canIssue_1 (core_age_simp_req[1]),
    .io_canIssue_2 (core_age_simp_req[2]),
    .io_out_0      (age_1_io_out_0),
    .io_out_1      (age_1_io_out_1),
    .io_out_2      (age_1_io_out_2)
  );

  AgeDetector_21 age_2 (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (entries_io_compEntryEnqSelVec_0),
    .io_enq_1      (entries_io_compEntryEnqSelVec_1),
    .io_canIssue_0 (core_age_comp_req[0]),
    .io_out_0      (age_2_io_out_0)
  );

  assign core_wk_enq_fu_type = '0;
  assign core_wk_deq_valid = 1'h0;
  assign core_wk_deq_fu_type = '0;
  assign core_wk_deq_wen = '0;
  assign core_wk_og1_valid = io_og1Resp_0_valid;
  assign core_wk_og1_resp = io_og1Resp_0_bits_resp;

  xs_IssueQueue_core #(
    .N_ENTRIES (16),
    .N_ENQ     (2),
    .N_SIMP    (2),
    .N_COMP    (12),
    .N_DEQ     (1),
    .N_SRC     (1),
    .PSRC_W    (8),
    .LD_CNT    (3),
    .N_EXU     (1),
    .EXU_W     (3),
    .N_BUSY    (1),
    .ACCEPT    ('{35'h30000}),
    .IQIDX_W   (4),
    .HAS_VCNT  ('{1'b0}),
    .VCNT_OUT_W(1),
    .W0        (901),
    .W1        (1),
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

  // ---- 顶层输出 ----
  assign io_enq_0_ready = core_enq_ready[0];
  assign io_enq_1_ready = core_enq_ready[1];
  assign io_deqDelay_0_valid = core_dly_valid[0];
  assign io_deqDelay_0_bits_rf_0_1_addr = dly0_bits_rf_0_1_addr;
  assign io_deqDelay_0_bits_rf_0_1_srcType = dly0_bits_rf_0_1_srcType;
  assign io_deqDelay_0_bits_rf_0_0_addr = dly0_bits_rf_0_0_addr;
  assign io_deqDelay_0_bits_rf_0_0_srcType = dly0_bits_rf_0_0_srcType;
  assign io_deqDelay_0_bits_srcType_0 = dly0_bits_srcType_0;
  assign io_deqDelay_0_bits_rcIdx_0 = dly0_bits_rcIdx_0;
  assign io_deqDelay_0_bits_immType = dly0_bits_immType;
  assign io_deqDelay_0_bits_common_fuType = dly0_bits_common_fuType;
  assign io_deqDelay_0_bits_common_fuOpType = dly0_bits_common_fuOpType;
  assign io_deqDelay_0_bits_common_src_0 = dly0_bits_common_src_0;
  assign io_deqDelay_0_bits_common_imm = dly0_bits_common_imm;
  assign io_deqDelay_0_bits_common_robIdx_flag = dly0_bits_common_robIdx_flag;
  assign io_deqDelay_0_bits_common_robIdx_value = dly0_bits_common_robIdx_value;
  assign io_deqDelay_0_bits_common_iqIdx = dly0_bits_common_iqIdx;
  assign io_deqDelay_0_bits_common_isFirstIssue = dly0_bits_common_isFirstIssue;
  assign io_deqDelay_0_bits_common_sqIdx_flag = dly0_bits_common_sqIdx_flag;
  assign io_deqDelay_0_bits_common_sqIdx_value = dly0_bits_common_sqIdx_value;
  assign io_deqDelay_0_bits_common_dataSources_0_value = dly0_bits_common_dataSources_0_value;
  assign io_deqDelay_0_bits_common_exuSources_0_value = dly0_bits_common_exuSources_0_value;
  assign io_deqDelay_0_bits_common_srcTimer_0 = dly0_bits_common_srcTimer_0;
  assign io_deqDelay_0_bits_common_loadDependency_0 = dly0_bits_common_loadDependency_0;
  assign io_deqDelay_0_bits_common_loadDependency_1 = dly0_bits_common_loadDependency_1;
  assign io_deqDelay_0_bits_common_loadDependency_2 = dly0_bits_common_loadDependency_2;
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
