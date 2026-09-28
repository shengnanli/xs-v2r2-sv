// IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv —— 发射队列 AluBrhJmpI2fVsetriwiVsetriwvfI2v（golden 同名 wrapper）
// -----------------------------------------------------------------------------
// 调度逻辑全部在 xs_IssueQueue_core.sv（家族共享参数化核）；本文件只做连线：
//   golden 端口表 + golden 同名子模块例化（已签核件）+ 核的数组接口接线 + deqDelay 负载拼包/拆包。
//
// 本变体规模（全部从 G1 golden 量得）：
//   条目 24 = enq 2 + simp 6 + comp 16，发射口 2，源 2，loadDependency 3 路，exuSources 2
//   口 0：接受 FuType 位 [6]；deqDelay 负载 42 个字段 / 994 位
//   口 1：接受 FuType 位 [0, 1, 2, 3, 28, 29]；deqDelay 负载 63 个字段 / 1131 位
//   子模块：EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v×1，FuBusyTableWrite_22×1，FuBusyTableRead_22×1，FuBusyTableRead_23×1，FuBusyTableWrite_26×1，FuBusyTableRead_26×1，FuBusyTableRead_28×2，MultiWakeupQueue_2×1，NewAgeDetector×1，AgeDetector×1，AgeDetector_1×1
//
// 自动生成：scripts/gen_iq.py —— 勿手改
// =============================================================================
module IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v(
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
  input          io_og0Resp_1_valid,
  input  [34:0]  io_og0Resp_1_bits_fuType,
  input          io_og1Resp_0_valid,
  input  [1:0]   io_og1Resp_0_bits_resp,
  input          io_og1Resp_1_valid,
  input  [1:0]   io_og1Resp_1_bits_resp,
  input  [2:0]   io_wbBusyTableRead_1_fpWbBusyTable,
  input          io_wbBusyTableRead_1_vfWbBusyTable,
  input          io_wbBusyTableRead_1_v0WbBusyTable,
  input          io_wbBusyTableRead_0_intWbBusyTable,
  output [2:0]   io_wbBusyTableWrite_1_fpWbBusyTable,
  input          io_wakeupFromWB_3_valid,
  input          io_wakeupFromWB_3_bits_rfWen,
  input  [7:0]   io_wakeupFromWB_3_bits_pdest,
  input          io_wakeupFromWB_2_valid,
  input          io_wakeupFromWB_2_bits_rfWen,
  input  [7:0]   io_wakeupFromWB_2_bits_pdest,
  input          io_wakeupFromWB_1_valid,
  input          io_wakeupFromWB_1_bits_rfWen,
  input  [7:0]   io_wakeupFromWB_1_bits_pdest,
  input          io_wakeupFromWB_0_valid,
  input          io_wakeupFromWB_0_bits_rfWen,
  input  [7:0]   io_wakeupFromWB_0_bits_pdest,
  input          io_wakeupFromIQ_6_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_6_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_6_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_6_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_6_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQ_6_bits_rcDest,
  input          io_wakeupFromIQ_5_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_5_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_5_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_5_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_5_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQ_5_bits_rcDest,
  input          io_wakeupFromIQ_4_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_4_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_4_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_4_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_4_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQ_4_bits_rcDest,
  input          io_wakeupFromIQ_3_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_3_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_3_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_3_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_3_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQ_3_bits_rcDest,
  input          io_wakeupFromIQ_2_bits_rfWen,
  input  [7:0]   io_wakeupFromIQ_2_bits_pdest,
  input  [1:0]   io_wakeupFromIQ_2_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQ_2_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQ_2_bits_loadDependency_2,
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
  input          io_wakeupFromWBDelayed_3_valid,
  input          io_wakeupFromWBDelayed_3_bits_rfWen,
  input  [7:0]   io_wakeupFromWBDelayed_3_bits_pdest,
  input          io_wakeupFromWBDelayed_2_valid,
  input          io_wakeupFromWBDelayed_2_bits_rfWen,
  input  [7:0]   io_wakeupFromWBDelayed_2_bits_pdest,
  input          io_wakeupFromWBDelayed_1_valid,
  input          io_wakeupFromWBDelayed_1_bits_rfWen,
  input  [7:0]   io_wakeupFromWBDelayed_1_bits_pdest,
  input          io_wakeupFromWBDelayed_0_valid,
  input          io_wakeupFromWBDelayed_0_bits_rfWen,
  input  [7:0]   io_wakeupFromWBDelayed_0_bits_pdest,
  input          io_wakeupFromIQDelayed_6_bits_rfWen,
  input  [7:0]   io_wakeupFromIQDelayed_6_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_6_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_6_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_6_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQDelayed_6_bits_rcDest,
  input          io_wakeupFromIQDelayed_5_bits_rfWen,
  input  [7:0]   io_wakeupFromIQDelayed_5_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_5_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_5_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_5_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQDelayed_5_bits_rcDest,
  input          io_wakeupFromIQDelayed_4_bits_rfWen,
  input  [7:0]   io_wakeupFromIQDelayed_4_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_4_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_4_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_4_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQDelayed_4_bits_rcDest,
  input          io_wakeupFromIQDelayed_3_bits_rfWen,
  input  [7:0]   io_wakeupFromIQDelayed_3_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_3_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_3_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_3_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQDelayed_3_bits_rcDest,
  input          io_wakeupFromIQDelayed_2_bits_rfWen,
  input  [7:0]   io_wakeupFromIQDelayed_2_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_2_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_2_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_2_bits_loadDependency_2,
  input  [4:0]   io_wakeupFromIQDelayed_2_bits_rcDest,
  input          io_wakeupFromIQDelayed_1_bits_rfWen,
  input  [7:0]   io_wakeupFromIQDelayed_1_bits_pdest,
  input  [1:0]   io_wakeupFromIQDelayed_1_bits_loadDependency_0,
  input  [1:0]   io_wakeupFromIQDelayed_1_bits_loadDependency_1,
  input  [1:0]   io_wakeupFromIQDelayed_1_bits_loadDependency_2,
  input          io_wakeupFromIQDelayed_1_bits_is0Lat,
  input  [4:0]   io_wakeupFromIQDelayed_1_bits_rcDest,
  input          io_wakeupFromIQDelayed_0_bits_rfWen,
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
  input          io_ldCancel_0_ld2Cancel,
  input          io_ldCancel_1_ld2Cancel,
  input          io_ldCancel_2_ld2Cancel,
  input  [4:0]   io_replaceRCIdx_0,
  output         io_wakeupToIQ_0_valid,
  output         io_wakeupToIQ_0_bits_rfWen,
  output [7:0]   io_wakeupToIQ_0_bits_pdest,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependency_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependency_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependency_2,
  output [4:0]   io_wakeupToIQ_0_bits_rcDest,
  output [7:0]   io_wakeupToIQ_0_bits_pdestCopy_0,
  output [7:0]   io_wakeupToIQ_0_bits_pdestCopy_1,
  output [7:0]   io_wakeupToIQ_0_bits_pdestCopy_2,
  output [7:0]   io_wakeupToIQ_0_bits_pdestCopy_3,
  output [7:0]   io_wakeupToIQ_0_bits_pdestCopy_4,
  output [7:0]   io_wakeupToIQ_0_bits_pdestCopy_5,
  output         io_wakeupToIQ_0_bits_rfWenCopy_0,
  output         io_wakeupToIQ_0_bits_rfWenCopy_1,
  output         io_wakeupToIQ_0_bits_rfWenCopy_2,
  output         io_wakeupToIQ_0_bits_rfWenCopy_3,
  output         io_wakeupToIQ_0_bits_rfWenCopy_4,
  output         io_wakeupToIQ_0_bits_rfWenCopy_5,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_0_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_0_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_0_2,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_1_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_1_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_1_2,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_2_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_2_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_2_2,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_3_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_3_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_3_2,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_4_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_4_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_4_2,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_5_0,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_5_1,
  output [1:0]   io_wakeupToIQ_0_bits_loadDependencyCopy_5_2,
  output [4:0]   io_validCntDeqVec_0,
  output [4:0]   io_validCntDeqVec_1,
  input          io_deqDelay_1_ready,
  output         io_deqDelay_1_valid,
  output [7:0]   io_deqDelay_1_bits_rf_1_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_1_0_srcType,
  output [7:0]   io_deqDelay_1_bits_rf_0_0_addr,
  output [2:0]   io_deqDelay_1_bits_rf_0_0_srcType,
  output [3:0]   io_deqDelay_1_bits_srcType_0,
  output [3:0]   io_deqDelay_1_bits_srcType_1,
  output [4:0]   io_deqDelay_1_bits_rcIdx_0,
  output [4:0]   io_deqDelay_1_bits_rcIdx_1,
  output [3:0]   io_deqDelay_1_bits_immType,
  output [34:0]  io_deqDelay_1_bits_common_fuType,
  output [8:0]   io_deqDelay_1_bits_common_fuOpType,
  output [63:0]  io_deqDelay_1_bits_common_src_0,
  output [63:0]  io_deqDelay_1_bits_common_src_1,
  output [63:0]  io_deqDelay_1_bits_common_imm,
  output [4:0]   io_deqDelay_1_bits_common_nextPcOffset,
  output         io_deqDelay_1_bits_common_robIdx_flag,
  output [7:0]   io_deqDelay_1_bits_common_robIdx_value,
  output [3:0]   io_deqDelay_1_bits_common_iqIdx,
  output         io_deqDelay_1_bits_common_isFirstIssue,
  output [7:0]   io_deqDelay_1_bits_common_pdest,
  output         io_deqDelay_1_bits_common_rfWen,
  output         io_deqDelay_1_bits_common_fpWen,
  output         io_deqDelay_1_bits_common_vecWen,
  output         io_deqDelay_1_bits_common_v0Wen,
  output         io_deqDelay_1_bits_common_vlWen,
  output [1:0]   io_deqDelay_1_bits_common_fpu_typeTagOut,
  output         io_deqDelay_1_bits_common_fpu_wflags,
  output [1:0]   io_deqDelay_1_bits_common_fpu_typ,
  output [1:0]   io_deqDelay_1_bits_common_fpu_fmt,
  output [2:0]   io_deqDelay_1_bits_common_fpu_rm,
  output [49:0]  io_deqDelay_1_bits_common_pc,
  output         io_deqDelay_1_bits_common_preDecode_valid,
  output         io_deqDelay_1_bits_common_preDecode_isRVC,
  output [1:0]   io_deqDelay_1_bits_common_preDecode_brType,
  output         io_deqDelay_1_bits_common_preDecode_isCall,
  output         io_deqDelay_1_bits_common_preDecode_isRet,
  output         io_deqDelay_1_bits_common_ftqIdx_flag,
  output [5:0]   io_deqDelay_1_bits_common_ftqIdx_value,
  output [3:0]   io_deqDelay_1_bits_common_ftqOffset,
  output [49:0]  io_deqDelay_1_bits_common_predictInfo_target,
  output         io_deqDelay_1_bits_common_predictInfo_taken,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_0_value,
  output [3:0]   io_deqDelay_1_bits_common_dataSources_1_value,
  output [2:0]   io_deqDelay_1_bits_common_exuSources_0_value,
  output [2:0]   io_deqDelay_1_bits_common_exuSources_1_value,
  output [2:0]   io_deqDelay_1_bits_common_srcTimer_0,
  output [2:0]   io_deqDelay_1_bits_common_srcTimer_1,
  output [1:0]   io_deqDelay_1_bits_common_loadDependency_0,
  output [1:0]   io_deqDelay_1_bits_common_loadDependency_1,
  output [1:0]   io_deqDelay_1_bits_common_loadDependency_2,
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
  output [23:0]  io_deqDelay_1_bits_addrOH,
  input          io_deqDelay_0_ready,
  output         io_deqDelay_0_valid,
  output [7:0]   io_deqDelay_0_bits_rf_1_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_1_0_srcType,
  output [7:0]   io_deqDelay_0_bits_rf_0_0_addr,
  output [2:0]   io_deqDelay_0_bits_rf_0_0_srcType,
  output [3:0]   io_deqDelay_0_bits_srcType_0,
  output [3:0]   io_deqDelay_0_bits_srcType_1,
  output [4:0]   io_deqDelay_0_bits_rcIdx_0,
  output [4:0]   io_deqDelay_0_bits_rcIdx_1,
  output [3:0]   io_deqDelay_0_bits_immType,
  output [34:0]  io_deqDelay_0_bits_common_fuType,
  output [8:0]   io_deqDelay_0_bits_common_fuOpType,
  output [63:0]  io_deqDelay_0_bits_common_src_0,
  output [63:0]  io_deqDelay_0_bits_common_src_1,
  output [63:0]  io_deqDelay_0_bits_common_imm,
  output         io_deqDelay_0_bits_common_robIdx_flag,
  output [7:0]   io_deqDelay_0_bits_common_robIdx_value,
  output [3:0]   io_deqDelay_0_bits_common_iqIdx,
  output         io_deqDelay_0_bits_common_isFirstIssue,
  output [7:0]   io_deqDelay_0_bits_common_pdest,
  output         io_deqDelay_0_bits_common_rfWen,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_0_value,
  output [3:0]   io_deqDelay_0_bits_common_dataSources_1_value,
  output [2:0]   io_deqDelay_0_bits_common_exuSources_0_value,
  output [2:0]   io_deqDelay_0_bits_common_exuSources_1_value,
  output [2:0]   io_deqDelay_0_bits_common_srcTimer_0,
  output [2:0]   io_deqDelay_0_bits_common_srcTimer_1,
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
  output [23:0]  io_deqDelay_0_bits_addrOH
);

  // ---- 子模块输出线（名字 = <实例>_<端口>）----
  logic [23:0] entries_io_valid;
  logic [23:0] entries_io_issued;
  logic [23:0] entries_io_canIssue;
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
  logic [34:0] entries_io_fuType_16;
  logic [34:0] entries_io_fuType_17;
  logic [34:0] entries_io_fuType_18;
  logic [34:0] entries_io_fuType_19;
  logic [34:0] entries_io_fuType_20;
  logic [34:0] entries_io_fuType_21;
  logic [34:0] entries_io_fuType_22;
  logic [34:0] entries_io_fuType_23;
  logic [3:0] entries_io_dataSources_0_0_value;
  logic [3:0] entries_io_dataSources_0_1_value;
  logic [3:0] entries_io_dataSources_1_0_value;
  logic [3:0] entries_io_dataSources_1_1_value;
  logic [3:0] entries_io_dataSources_2_0_value;
  logic [3:0] entries_io_dataSources_2_1_value;
  logic [3:0] entries_io_dataSources_3_0_value;
  logic [3:0] entries_io_dataSources_3_1_value;
  logic [3:0] entries_io_dataSources_4_0_value;
  logic [3:0] entries_io_dataSources_4_1_value;
  logic [3:0] entries_io_dataSources_5_0_value;
  logic [3:0] entries_io_dataSources_5_1_value;
  logic [3:0] entries_io_dataSources_6_0_value;
  logic [3:0] entries_io_dataSources_6_1_value;
  logic [3:0] entries_io_dataSources_7_0_value;
  logic [3:0] entries_io_dataSources_7_1_value;
  logic [3:0] entries_io_dataSources_8_0_value;
  logic [3:0] entries_io_dataSources_8_1_value;
  logic [3:0] entries_io_dataSources_9_0_value;
  logic [3:0] entries_io_dataSources_9_1_value;
  logic [3:0] entries_io_dataSources_10_0_value;
  logic [3:0] entries_io_dataSources_10_1_value;
  logic [3:0] entries_io_dataSources_11_0_value;
  logic [3:0] entries_io_dataSources_11_1_value;
  logic [3:0] entries_io_dataSources_12_0_value;
  logic [3:0] entries_io_dataSources_12_1_value;
  logic [3:0] entries_io_dataSources_13_0_value;
  logic [3:0] entries_io_dataSources_13_1_value;
  logic [3:0] entries_io_dataSources_14_0_value;
  logic [3:0] entries_io_dataSources_14_1_value;
  logic [3:0] entries_io_dataSources_15_0_value;
  logic [3:0] entries_io_dataSources_15_1_value;
  logic [3:0] entries_io_dataSources_16_0_value;
  logic [3:0] entries_io_dataSources_16_1_value;
  logic [3:0] entries_io_dataSources_17_0_value;
  logic [3:0] entries_io_dataSources_17_1_value;
  logic [3:0] entries_io_dataSources_18_0_value;
  logic [3:0] entries_io_dataSources_18_1_value;
  logic [3:0] entries_io_dataSources_19_0_value;
  logic [3:0] entries_io_dataSources_19_1_value;
  logic [3:0] entries_io_dataSources_20_0_value;
  logic [3:0] entries_io_dataSources_20_1_value;
  logic [3:0] entries_io_dataSources_21_0_value;
  logic [3:0] entries_io_dataSources_21_1_value;
  logic [3:0] entries_io_dataSources_22_0_value;
  logic [3:0] entries_io_dataSources_22_1_value;
  logic [3:0] entries_io_dataSources_23_0_value;
  logic [3:0] entries_io_dataSources_23_1_value;
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
  logic [1:0] entries_io_loadDependency_16_0;
  logic [1:0] entries_io_loadDependency_16_1;
  logic [1:0] entries_io_loadDependency_16_2;
  logic [1:0] entries_io_loadDependency_17_0;
  logic [1:0] entries_io_loadDependency_17_1;
  logic [1:0] entries_io_loadDependency_17_2;
  logic [1:0] entries_io_loadDependency_18_0;
  logic [1:0] entries_io_loadDependency_18_1;
  logic [1:0] entries_io_loadDependency_18_2;
  logic [1:0] entries_io_loadDependency_19_0;
  logic [1:0] entries_io_loadDependency_19_1;
  logic [1:0] entries_io_loadDependency_19_2;
  logic [1:0] entries_io_loadDependency_20_0;
  logic [1:0] entries_io_loadDependency_20_1;
  logic [1:0] entries_io_loadDependency_20_2;
  logic [1:0] entries_io_loadDependency_21_0;
  logic [1:0] entries_io_loadDependency_21_1;
  logic [1:0] entries_io_loadDependency_21_2;
  logic [1:0] entries_io_loadDependency_22_0;
  logic [1:0] entries_io_loadDependency_22_1;
  logic [1:0] entries_io_loadDependency_22_2;
  logic [1:0] entries_io_loadDependency_23_0;
  logic [1:0] entries_io_loadDependency_23_1;
  logic [1:0] entries_io_loadDependency_23_2;
  logic [2:0] entries_io_exuSources_0_0_value;
  logic [2:0] entries_io_exuSources_0_1_value;
  logic [2:0] entries_io_exuSources_1_0_value;
  logic [2:0] entries_io_exuSources_1_1_value;
  logic [2:0] entries_io_exuSources_2_0_value;
  logic [2:0] entries_io_exuSources_2_1_value;
  logic [2:0] entries_io_exuSources_3_0_value;
  logic [2:0] entries_io_exuSources_3_1_value;
  logic [2:0] entries_io_exuSources_4_0_value;
  logic [2:0] entries_io_exuSources_4_1_value;
  logic [2:0] entries_io_exuSources_5_0_value;
  logic [2:0] entries_io_exuSources_5_1_value;
  logic [2:0] entries_io_exuSources_6_0_value;
  logic [2:0] entries_io_exuSources_6_1_value;
  logic [2:0] entries_io_exuSources_7_0_value;
  logic [2:0] entries_io_exuSources_7_1_value;
  logic [2:0] entries_io_exuSources_8_0_value;
  logic [2:0] entries_io_exuSources_8_1_value;
  logic [2:0] entries_io_exuSources_9_0_value;
  logic [2:0] entries_io_exuSources_9_1_value;
  logic [2:0] entries_io_exuSources_10_0_value;
  logic [2:0] entries_io_exuSources_10_1_value;
  logic [2:0] entries_io_exuSources_11_0_value;
  logic [2:0] entries_io_exuSources_11_1_value;
  logic [2:0] entries_io_exuSources_12_0_value;
  logic [2:0] entries_io_exuSources_12_1_value;
  logic [2:0] entries_io_exuSources_13_0_value;
  logic [2:0] entries_io_exuSources_13_1_value;
  logic [2:0] entries_io_exuSources_14_0_value;
  logic [2:0] entries_io_exuSources_14_1_value;
  logic [2:0] entries_io_exuSources_15_0_value;
  logic [2:0] entries_io_exuSources_15_1_value;
  logic [2:0] entries_io_exuSources_16_0_value;
  logic [2:0] entries_io_exuSources_16_1_value;
  logic [2:0] entries_io_exuSources_17_0_value;
  logic [2:0] entries_io_exuSources_17_1_value;
  logic [2:0] entries_io_exuSources_18_0_value;
  logic [2:0] entries_io_exuSources_18_1_value;
  logic [2:0] entries_io_exuSources_19_0_value;
  logic [2:0] entries_io_exuSources_19_1_value;
  logic [2:0] entries_io_exuSources_20_0_value;
  logic [2:0] entries_io_exuSources_20_1_value;
  logic [2:0] entries_io_exuSources_21_0_value;
  logic [2:0] entries_io_exuSources_21_1_value;
  logic [2:0] entries_io_exuSources_22_0_value;
  logic [2:0] entries_io_exuSources_22_1_value;
  logic [2:0] entries_io_exuSources_23_0_value;
  logic [2:0] entries_io_exuSources_23_1_value;
  logic entries_io_isFirstIssue_0;
  logic entries_io_isFirstIssue_1;
  logic entries_io_deqEntry_0_bits_status_robIdx_flag;
  logic [7:0] entries_io_deqEntry_0_bits_status_robIdx_value;
  logic entries_io_deqEntry_0_bits_status_fuType_0;
  logic entries_io_deqEntry_0_bits_status_fuType_1;
  logic entries_io_deqEntry_0_bits_status_fuType_2;
  logic entries_io_deqEntry_0_bits_status_fuType_3;
  logic entries_io_deqEntry_0_bits_status_fuType_6;
  logic entries_io_deqEntry_0_bits_status_fuType_28;
  logic entries_io_deqEntry_0_bits_status_fuType_29;
  logic [7:0] entries_io_deqEntry_0_bits_status_srcStatus_0_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_0_srcType;
  logic [4:0] entries_io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx;
  logic [7:0] entries_io_deqEntry_0_bits_status_srcStatus_1_psrc;
  logic [3:0] entries_io_deqEntry_0_bits_status_srcStatus_1_srcType;
  logic [4:0] entries_io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx;
  logic [31:0] entries_io_deqEntry_0_bits_imm;
  logic [8:0] entries_io_deqEntry_0_bits_payload_fuOpType;
  logic entries_io_deqEntry_0_bits_payload_rfWen;
  logic [3:0] entries_io_deqEntry_0_bits_payload_selImm;
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
  logic entries_io_deqEntry_1_bits_status_fuType_0;
  logic entries_io_deqEntry_1_bits_status_fuType_1;
  logic entries_io_deqEntry_1_bits_status_fuType_2;
  logic entries_io_deqEntry_1_bits_status_fuType_3;
  logic entries_io_deqEntry_1_bits_status_fuType_6;
  logic entries_io_deqEntry_1_bits_status_fuType_28;
  logic entries_io_deqEntry_1_bits_status_fuType_29;
  logic [7:0] entries_io_deqEntry_1_bits_status_srcStatus_0_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_0_srcType;
  logic [4:0] entries_io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx;
  logic [7:0] entries_io_deqEntry_1_bits_status_srcStatus_1_psrc;
  logic [3:0] entries_io_deqEntry_1_bits_status_srcStatus_1_srcType;
  logic [4:0] entries_io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx;
  logic [31:0] entries_io_deqEntry_1_bits_imm;
  logic entries_io_deqEntry_1_bits_payload_preDecodeInfo_valid;
  logic entries_io_deqEntry_1_bits_payload_preDecodeInfo_isRVC;
  logic [1:0] entries_io_deqEntry_1_bits_payload_preDecodeInfo_brType;
  logic entries_io_deqEntry_1_bits_payload_preDecodeInfo_isCall;
  logic entries_io_deqEntry_1_bits_payload_preDecodeInfo_isRet;
  logic entries_io_deqEntry_1_bits_payload_pred_taken;
  logic entries_io_deqEntry_1_bits_payload_ftqPtr_flag;
  logic [5:0] entries_io_deqEntry_1_bits_payload_ftqPtr_value;
  logic [3:0] entries_io_deqEntry_1_bits_payload_ftqOffset;
  logic [8:0] entries_io_deqEntry_1_bits_payload_fuOpType;
  logic entries_io_deqEntry_1_bits_payload_rfWen;
  logic entries_io_deqEntry_1_bits_payload_fpWen;
  logic entries_io_deqEntry_1_bits_payload_vecWen;
  logic entries_io_deqEntry_1_bits_payload_v0Wen;
  logic entries_io_deqEntry_1_bits_payload_vlWen;
  logic [3:0] entries_io_deqEntry_1_bits_payload_selImm;
  logic [1:0] entries_io_deqEntry_1_bits_payload_fpu_typeTagOut;
  logic entries_io_deqEntry_1_bits_payload_fpu_wflags;
  logic [1:0] entries_io_deqEntry_1_bits_payload_fpu_typ;
  logic [1:0] entries_io_deqEntry_1_bits_payload_fpu_fmt;
  logic [2:0] entries_io_deqEntry_1_bits_payload_fpu_rm;
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
  logic entries_io_cancelDeqVec_0;
  logic entries_io_cancelDeqVec_1;
  logic [5:0] entries_io_simpEntryEnqSelVec_0;
  logic [5:0] entries_io_simpEntryEnqSelVec_1;
  logic [15:0] entries_io_compEntryEnqSelVec_0;
  logic [15:0] entries_io_compEntryEnqSelVec_1;
  logic [2:0] fuBusyTableWrite_1_io_out_fuBusyTable;
  logic [23:0] fuBusyTableRead_1_io_out_fuBusyTableMask;
  logic [23:0] intWbBusyTableRead_0_io_out_fuBusyTableMask;
  logic [23:0] fpWbBusyTableRead_1_io_out_fuBusyTableMask;
  logic [23:0] vfWbBusyTableRead_1_io_out_fuBusyTableMask;
  logic [23:0] v0WbBusyTableRead_1_io_out_fuBusyTableMask;
  logic wakeUpQueues_0_io_deq_valid;
  logic wakeUpQueues_0_io_deq_bits_rfWen;
  logic [1:0] age_io_out_0;
  logic [1:0] age_io_out_1;
  logic [5:0] age_1_io_out_0;
  logic [5:0] age_1_io_out_1;
  logic [5:0] age_1_io_out_2;
  logic [5:0] age_1_io_out_3;
  logic [15:0] age_2_io_out_0;
  logic [15:0] age_2_io_out_1;

  // ---- 核接口 ----
  logic             core_enq_valid     [2];
  logic             core_enq_ready     [2];
  logic             core_enq_do        [2];
  logic [3:0]       core_enq_src_type  [2][2];
  logic [7:0]       core_enq_psrc      [2][2];
  logic             core_enq_src_state [2][2];
  logic [1:0]       core_enq_src_ld    [2][2][3];
  logic             core_st_src_state  [2][2];
  logic [3:0]       core_st_data_src   [2][2];
  logic [1:0]       core_st_src_ld     [2][2][3];
  logic [23:0]      core_ent_valid;
  logic [23:0]      core_ent_issued;
  logic [23:0]      core_ent_can_issue;
  logic [34:0]      core_ent_fu_type   [24];
  logic [3:0]       core_ent_data_src  [24][2];
  logic [2:0]       core_ent_exu_src   [24][2];
  logic [1:0]       core_ent_ld_dep    [24][3];
  logic             core_ent_cancel_deq [2];
  logic [23:0]      core_busy_mask     [2][4];
  logic [1:0]       core_age_enq_req   [2];
  logic [5:0]       core_age_simp_req  [4];
  logic [15:0]      core_age_comp_req  [2];
  logic [1:0]       core_age_enq_out   [2];
  logic [5:0]       core_age_simp_out  [4];
  logic [15:0]      core_age_comp_out  [2];
  logic             core_sel_valid     [2];
  logic [23:0]      core_sel_oh        [2];
  logic             core_simp_oldest_valid [2];
  logic             core_comp_oldest_valid [2];
  logic             core_deq_valid     [2];
  logic [3:0]       core_deq_iq_idx    [2];
  logic [3:0]       core_deq_data_src  [2][2];
  logic [2:0]       core_deq_exu_src   [2][2];
  logic [1:0]       core_deq_ld_dep    [2][3];
  logic [63:0]      core_deq_select_time [2];
  logic [63:0]      core_deq_issue_time  [2];
  logic [993:0]    core_deq0_payload;
  logic [1130:0]    core_deq1_payload;
  logic             core_dly_valid     [2];
  logic [993:0]    core_dly0_payload;
  logic [1130:0]    core_dly1_payload;
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

  // ---- 核输入 ----
  assign core_enq_valid[0] = io_enq_0_valid;
  assign core_enq_src_type[0][0] = io_enq_0_bits_srcType_0;
  assign core_enq_psrc[0][0] = io_enq_0_bits_psrc_0;
  assign core_enq_src_state[0][0] = io_enq_0_bits_srcState_0;
  assign core_enq_src_ld[0][0][0] = io_enq_0_bits_srcLoadDependency_0_0;
  assign core_enq_src_ld[0][0][1] = io_enq_0_bits_srcLoadDependency_0_1;
  assign core_enq_src_ld[0][0][2] = io_enq_0_bits_srcLoadDependency_0_2;
  assign core_enq_src_type[0][1] = io_enq_0_bits_srcType_1;
  assign core_enq_psrc[0][1] = io_enq_0_bits_psrc_1;
  assign core_enq_src_state[0][1] = io_enq_0_bits_srcState_1;
  assign core_enq_src_ld[0][1][0] = io_enq_0_bits_srcLoadDependency_1_0;
  assign core_enq_src_ld[0][1][1] = io_enq_0_bits_srcLoadDependency_1_1;
  assign core_enq_src_ld[0][1][2] = io_enq_0_bits_srcLoadDependency_1_2;
  assign core_enq_valid[1] = io_enq_1_valid;
  assign core_enq_src_type[1][0] = io_enq_1_bits_srcType_0;
  assign core_enq_psrc[1][0] = io_enq_1_bits_psrc_0;
  assign core_enq_src_state[1][0] = io_enq_1_bits_srcState_0;
  assign core_enq_src_ld[1][0][0] = io_enq_1_bits_srcLoadDependency_0_0;
  assign core_enq_src_ld[1][0][1] = io_enq_1_bits_srcLoadDependency_0_1;
  assign core_enq_src_ld[1][0][2] = io_enq_1_bits_srcLoadDependency_0_2;
  assign core_enq_src_type[1][1] = io_enq_1_bits_srcType_1;
  assign core_enq_psrc[1][1] = io_enq_1_bits_psrc_1;
  assign core_enq_src_state[1][1] = io_enq_1_bits_srcState_1;
  assign core_enq_src_ld[1][1][0] = io_enq_1_bits_srcLoadDependency_1_0;
  assign core_enq_src_ld[1][1][1] = io_enq_1_bits_srcLoadDependency_1_1;
  assign core_enq_src_ld[1][1][2] = io_enq_1_bits_srcLoadDependency_1_2;
  assign core_ent_valid = entries_io_valid;
  assign core_ent_issued = entries_io_issued;
  assign core_ent_can_issue = entries_io_canIssue;
  assign core_ent_fu_type[0] = entries_io_fuType_0;
  assign core_ent_data_src[0][0] = entries_io_dataSources_0_0_value;
  assign core_ent_data_src[0][1] = entries_io_dataSources_0_1_value;
  assign core_ent_exu_src[0][0] = entries_io_exuSources_0_0_value;
  assign core_ent_exu_src[0][1] = entries_io_exuSources_0_1_value;
  assign core_ent_ld_dep[0][0] = entries_io_loadDependency_0_0;
  assign core_ent_ld_dep[0][1] = entries_io_loadDependency_0_1;
  assign core_ent_ld_dep[0][2] = entries_io_loadDependency_0_2;
  assign core_ent_fu_type[1] = entries_io_fuType_1;
  assign core_ent_data_src[1][0] = entries_io_dataSources_1_0_value;
  assign core_ent_data_src[1][1] = entries_io_dataSources_1_1_value;
  assign core_ent_exu_src[1][0] = entries_io_exuSources_1_0_value;
  assign core_ent_exu_src[1][1] = entries_io_exuSources_1_1_value;
  assign core_ent_ld_dep[1][0] = entries_io_loadDependency_1_0;
  assign core_ent_ld_dep[1][1] = entries_io_loadDependency_1_1;
  assign core_ent_ld_dep[1][2] = entries_io_loadDependency_1_2;
  assign core_ent_fu_type[2] = entries_io_fuType_2;
  assign core_ent_data_src[2][0] = entries_io_dataSources_2_0_value;
  assign core_ent_data_src[2][1] = entries_io_dataSources_2_1_value;
  assign core_ent_exu_src[2][0] = entries_io_exuSources_2_0_value;
  assign core_ent_exu_src[2][1] = entries_io_exuSources_2_1_value;
  assign core_ent_ld_dep[2][0] = entries_io_loadDependency_2_0;
  assign core_ent_ld_dep[2][1] = entries_io_loadDependency_2_1;
  assign core_ent_ld_dep[2][2] = entries_io_loadDependency_2_2;
  assign core_ent_fu_type[3] = entries_io_fuType_3;
  assign core_ent_data_src[3][0] = entries_io_dataSources_3_0_value;
  assign core_ent_data_src[3][1] = entries_io_dataSources_3_1_value;
  assign core_ent_exu_src[3][0] = entries_io_exuSources_3_0_value;
  assign core_ent_exu_src[3][1] = entries_io_exuSources_3_1_value;
  assign core_ent_ld_dep[3][0] = entries_io_loadDependency_3_0;
  assign core_ent_ld_dep[3][1] = entries_io_loadDependency_3_1;
  assign core_ent_ld_dep[3][2] = entries_io_loadDependency_3_2;
  assign core_ent_fu_type[4] = entries_io_fuType_4;
  assign core_ent_data_src[4][0] = entries_io_dataSources_4_0_value;
  assign core_ent_data_src[4][1] = entries_io_dataSources_4_1_value;
  assign core_ent_exu_src[4][0] = entries_io_exuSources_4_0_value;
  assign core_ent_exu_src[4][1] = entries_io_exuSources_4_1_value;
  assign core_ent_ld_dep[4][0] = entries_io_loadDependency_4_0;
  assign core_ent_ld_dep[4][1] = entries_io_loadDependency_4_1;
  assign core_ent_ld_dep[4][2] = entries_io_loadDependency_4_2;
  assign core_ent_fu_type[5] = entries_io_fuType_5;
  assign core_ent_data_src[5][0] = entries_io_dataSources_5_0_value;
  assign core_ent_data_src[5][1] = entries_io_dataSources_5_1_value;
  assign core_ent_exu_src[5][0] = entries_io_exuSources_5_0_value;
  assign core_ent_exu_src[5][1] = entries_io_exuSources_5_1_value;
  assign core_ent_ld_dep[5][0] = entries_io_loadDependency_5_0;
  assign core_ent_ld_dep[5][1] = entries_io_loadDependency_5_1;
  assign core_ent_ld_dep[5][2] = entries_io_loadDependency_5_2;
  assign core_ent_fu_type[6] = entries_io_fuType_6;
  assign core_ent_data_src[6][0] = entries_io_dataSources_6_0_value;
  assign core_ent_data_src[6][1] = entries_io_dataSources_6_1_value;
  assign core_ent_exu_src[6][0] = entries_io_exuSources_6_0_value;
  assign core_ent_exu_src[6][1] = entries_io_exuSources_6_1_value;
  assign core_ent_ld_dep[6][0] = entries_io_loadDependency_6_0;
  assign core_ent_ld_dep[6][1] = entries_io_loadDependency_6_1;
  assign core_ent_ld_dep[6][2] = entries_io_loadDependency_6_2;
  assign core_ent_fu_type[7] = entries_io_fuType_7;
  assign core_ent_data_src[7][0] = entries_io_dataSources_7_0_value;
  assign core_ent_data_src[7][1] = entries_io_dataSources_7_1_value;
  assign core_ent_exu_src[7][0] = entries_io_exuSources_7_0_value;
  assign core_ent_exu_src[7][1] = entries_io_exuSources_7_1_value;
  assign core_ent_ld_dep[7][0] = entries_io_loadDependency_7_0;
  assign core_ent_ld_dep[7][1] = entries_io_loadDependency_7_1;
  assign core_ent_ld_dep[7][2] = entries_io_loadDependency_7_2;
  assign core_ent_fu_type[8] = entries_io_fuType_8;
  assign core_ent_data_src[8][0] = entries_io_dataSources_8_0_value;
  assign core_ent_data_src[8][1] = entries_io_dataSources_8_1_value;
  assign core_ent_exu_src[8][0] = entries_io_exuSources_8_0_value;
  assign core_ent_exu_src[8][1] = entries_io_exuSources_8_1_value;
  assign core_ent_ld_dep[8][0] = entries_io_loadDependency_8_0;
  assign core_ent_ld_dep[8][1] = entries_io_loadDependency_8_1;
  assign core_ent_ld_dep[8][2] = entries_io_loadDependency_8_2;
  assign core_ent_fu_type[9] = entries_io_fuType_9;
  assign core_ent_data_src[9][0] = entries_io_dataSources_9_0_value;
  assign core_ent_data_src[9][1] = entries_io_dataSources_9_1_value;
  assign core_ent_exu_src[9][0] = entries_io_exuSources_9_0_value;
  assign core_ent_exu_src[9][1] = entries_io_exuSources_9_1_value;
  assign core_ent_ld_dep[9][0] = entries_io_loadDependency_9_0;
  assign core_ent_ld_dep[9][1] = entries_io_loadDependency_9_1;
  assign core_ent_ld_dep[9][2] = entries_io_loadDependency_9_2;
  assign core_ent_fu_type[10] = entries_io_fuType_10;
  assign core_ent_data_src[10][0] = entries_io_dataSources_10_0_value;
  assign core_ent_data_src[10][1] = entries_io_dataSources_10_1_value;
  assign core_ent_exu_src[10][0] = entries_io_exuSources_10_0_value;
  assign core_ent_exu_src[10][1] = entries_io_exuSources_10_1_value;
  assign core_ent_ld_dep[10][0] = entries_io_loadDependency_10_0;
  assign core_ent_ld_dep[10][1] = entries_io_loadDependency_10_1;
  assign core_ent_ld_dep[10][2] = entries_io_loadDependency_10_2;
  assign core_ent_fu_type[11] = entries_io_fuType_11;
  assign core_ent_data_src[11][0] = entries_io_dataSources_11_0_value;
  assign core_ent_data_src[11][1] = entries_io_dataSources_11_1_value;
  assign core_ent_exu_src[11][0] = entries_io_exuSources_11_0_value;
  assign core_ent_exu_src[11][1] = entries_io_exuSources_11_1_value;
  assign core_ent_ld_dep[11][0] = entries_io_loadDependency_11_0;
  assign core_ent_ld_dep[11][1] = entries_io_loadDependency_11_1;
  assign core_ent_ld_dep[11][2] = entries_io_loadDependency_11_2;
  assign core_ent_fu_type[12] = entries_io_fuType_12;
  assign core_ent_data_src[12][0] = entries_io_dataSources_12_0_value;
  assign core_ent_data_src[12][1] = entries_io_dataSources_12_1_value;
  assign core_ent_exu_src[12][0] = entries_io_exuSources_12_0_value;
  assign core_ent_exu_src[12][1] = entries_io_exuSources_12_1_value;
  assign core_ent_ld_dep[12][0] = entries_io_loadDependency_12_0;
  assign core_ent_ld_dep[12][1] = entries_io_loadDependency_12_1;
  assign core_ent_ld_dep[12][2] = entries_io_loadDependency_12_2;
  assign core_ent_fu_type[13] = entries_io_fuType_13;
  assign core_ent_data_src[13][0] = entries_io_dataSources_13_0_value;
  assign core_ent_data_src[13][1] = entries_io_dataSources_13_1_value;
  assign core_ent_exu_src[13][0] = entries_io_exuSources_13_0_value;
  assign core_ent_exu_src[13][1] = entries_io_exuSources_13_1_value;
  assign core_ent_ld_dep[13][0] = entries_io_loadDependency_13_0;
  assign core_ent_ld_dep[13][1] = entries_io_loadDependency_13_1;
  assign core_ent_ld_dep[13][2] = entries_io_loadDependency_13_2;
  assign core_ent_fu_type[14] = entries_io_fuType_14;
  assign core_ent_data_src[14][0] = entries_io_dataSources_14_0_value;
  assign core_ent_data_src[14][1] = entries_io_dataSources_14_1_value;
  assign core_ent_exu_src[14][0] = entries_io_exuSources_14_0_value;
  assign core_ent_exu_src[14][1] = entries_io_exuSources_14_1_value;
  assign core_ent_ld_dep[14][0] = entries_io_loadDependency_14_0;
  assign core_ent_ld_dep[14][1] = entries_io_loadDependency_14_1;
  assign core_ent_ld_dep[14][2] = entries_io_loadDependency_14_2;
  assign core_ent_fu_type[15] = entries_io_fuType_15;
  assign core_ent_data_src[15][0] = entries_io_dataSources_15_0_value;
  assign core_ent_data_src[15][1] = entries_io_dataSources_15_1_value;
  assign core_ent_exu_src[15][0] = entries_io_exuSources_15_0_value;
  assign core_ent_exu_src[15][1] = entries_io_exuSources_15_1_value;
  assign core_ent_ld_dep[15][0] = entries_io_loadDependency_15_0;
  assign core_ent_ld_dep[15][1] = entries_io_loadDependency_15_1;
  assign core_ent_ld_dep[15][2] = entries_io_loadDependency_15_2;
  assign core_ent_fu_type[16] = entries_io_fuType_16;
  assign core_ent_data_src[16][0] = entries_io_dataSources_16_0_value;
  assign core_ent_data_src[16][1] = entries_io_dataSources_16_1_value;
  assign core_ent_exu_src[16][0] = entries_io_exuSources_16_0_value;
  assign core_ent_exu_src[16][1] = entries_io_exuSources_16_1_value;
  assign core_ent_ld_dep[16][0] = entries_io_loadDependency_16_0;
  assign core_ent_ld_dep[16][1] = entries_io_loadDependency_16_1;
  assign core_ent_ld_dep[16][2] = entries_io_loadDependency_16_2;
  assign core_ent_fu_type[17] = entries_io_fuType_17;
  assign core_ent_data_src[17][0] = entries_io_dataSources_17_0_value;
  assign core_ent_data_src[17][1] = entries_io_dataSources_17_1_value;
  assign core_ent_exu_src[17][0] = entries_io_exuSources_17_0_value;
  assign core_ent_exu_src[17][1] = entries_io_exuSources_17_1_value;
  assign core_ent_ld_dep[17][0] = entries_io_loadDependency_17_0;
  assign core_ent_ld_dep[17][1] = entries_io_loadDependency_17_1;
  assign core_ent_ld_dep[17][2] = entries_io_loadDependency_17_2;
  assign core_ent_fu_type[18] = entries_io_fuType_18;
  assign core_ent_data_src[18][0] = entries_io_dataSources_18_0_value;
  assign core_ent_data_src[18][1] = entries_io_dataSources_18_1_value;
  assign core_ent_exu_src[18][0] = entries_io_exuSources_18_0_value;
  assign core_ent_exu_src[18][1] = entries_io_exuSources_18_1_value;
  assign core_ent_ld_dep[18][0] = entries_io_loadDependency_18_0;
  assign core_ent_ld_dep[18][1] = entries_io_loadDependency_18_1;
  assign core_ent_ld_dep[18][2] = entries_io_loadDependency_18_2;
  assign core_ent_fu_type[19] = entries_io_fuType_19;
  assign core_ent_data_src[19][0] = entries_io_dataSources_19_0_value;
  assign core_ent_data_src[19][1] = entries_io_dataSources_19_1_value;
  assign core_ent_exu_src[19][0] = entries_io_exuSources_19_0_value;
  assign core_ent_exu_src[19][1] = entries_io_exuSources_19_1_value;
  assign core_ent_ld_dep[19][0] = entries_io_loadDependency_19_0;
  assign core_ent_ld_dep[19][1] = entries_io_loadDependency_19_1;
  assign core_ent_ld_dep[19][2] = entries_io_loadDependency_19_2;
  assign core_ent_fu_type[20] = entries_io_fuType_20;
  assign core_ent_data_src[20][0] = entries_io_dataSources_20_0_value;
  assign core_ent_data_src[20][1] = entries_io_dataSources_20_1_value;
  assign core_ent_exu_src[20][0] = entries_io_exuSources_20_0_value;
  assign core_ent_exu_src[20][1] = entries_io_exuSources_20_1_value;
  assign core_ent_ld_dep[20][0] = entries_io_loadDependency_20_0;
  assign core_ent_ld_dep[20][1] = entries_io_loadDependency_20_1;
  assign core_ent_ld_dep[20][2] = entries_io_loadDependency_20_2;
  assign core_ent_fu_type[21] = entries_io_fuType_21;
  assign core_ent_data_src[21][0] = entries_io_dataSources_21_0_value;
  assign core_ent_data_src[21][1] = entries_io_dataSources_21_1_value;
  assign core_ent_exu_src[21][0] = entries_io_exuSources_21_0_value;
  assign core_ent_exu_src[21][1] = entries_io_exuSources_21_1_value;
  assign core_ent_ld_dep[21][0] = entries_io_loadDependency_21_0;
  assign core_ent_ld_dep[21][1] = entries_io_loadDependency_21_1;
  assign core_ent_ld_dep[21][2] = entries_io_loadDependency_21_2;
  assign core_ent_fu_type[22] = entries_io_fuType_22;
  assign core_ent_data_src[22][0] = entries_io_dataSources_22_0_value;
  assign core_ent_data_src[22][1] = entries_io_dataSources_22_1_value;
  assign core_ent_exu_src[22][0] = entries_io_exuSources_22_0_value;
  assign core_ent_exu_src[22][1] = entries_io_exuSources_22_1_value;
  assign core_ent_ld_dep[22][0] = entries_io_loadDependency_22_0;
  assign core_ent_ld_dep[22][1] = entries_io_loadDependency_22_1;
  assign core_ent_ld_dep[22][2] = entries_io_loadDependency_22_2;
  assign core_ent_fu_type[23] = entries_io_fuType_23;
  assign core_ent_data_src[23][0] = entries_io_dataSources_23_0_value;
  assign core_ent_data_src[23][1] = entries_io_dataSources_23_1_value;
  assign core_ent_exu_src[23][0] = entries_io_exuSources_23_0_value;
  assign core_ent_exu_src[23][1] = entries_io_exuSources_23_1_value;
  assign core_ent_ld_dep[23][0] = entries_io_loadDependency_23_0;
  assign core_ent_ld_dep[23][1] = entries_io_loadDependency_23_1;
  assign core_ent_ld_dep[23][2] = entries_io_loadDependency_23_2;
  assign core_ent_cancel_deq[0] = entries_io_cancelDeqVec_0;
  assign core_busy_mask[0][0] = intWbBusyTableRead_0_io_out_fuBusyTableMask;
  assign core_busy_mask[0][1] = '0;
  assign core_busy_mask[0][2] = '0;
  assign core_busy_mask[0][3] = '0;
  assign core_dly_ready[0] = io_deqDelay_0_ready;
  assign core_ent_cancel_deq[1] = entries_io_cancelDeqVec_1;
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
  assign core_deq_wen[0] = {1'h0, 1'h0, 1'h0, 1'h0, entries_io_deqEntry_0_bits_payload_rfWen};   // {vl, v0, vec, fp, rf}Wen
  assign core_deq_wen[1] = {entries_io_deqEntry_1_bits_payload_vlWen, entries_io_deqEntry_1_bits_payload_v0Wen, entries_io_deqEntry_1_bits_payload_vecWen, entries_io_deqEntry_1_bits_payload_fpWen, entries_io_deqEntry_1_bits_payload_rfWen};   // {vl, v0, vec, fp, rf}Wen
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

  // ---- 口 0 deqDelay 负载（golden 寄存器声明顺序，高位在前）----
  assign core_deq0_payload = {
    entries_io_deqEntry_0_bits_status_srcStatus_1_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_1_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_0_psrc,
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType[2:0],
    entries_io_deqEntry_0_bits_status_srcStatus_0_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_1_srcType,
    entries_io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx,
    entries_io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx,
    entries_io_deqEntry_0_bits_payload_selImm,
    {5'h0, entries_io_deqEntry_0_bits_status_fuType_29, entries_io_deqEntry_0_bits_status_fuType_28, 21'h0, entries_io_deqEntry_0_bits_status_fuType_6, 2'h0, entries_io_deqEntry_0_bits_status_fuType_3, entries_io_deqEntry_0_bits_status_fuType_2, entries_io_deqEntry_0_bits_status_fuType_1, entries_io_deqEntry_0_bits_status_fuType_0},
    entries_io_deqEntry_0_bits_payload_fuOpType,
    64'h0,
    64'h0,
    {32'h0, entries_io_deqEntry_0_bits_imm},
    entries_io_deqEntry_0_bits_status_robIdx_flag,
    entries_io_deqEntry_0_bits_status_robIdx_value,
    core_deq_iq_idx[0],
    entries_io_isFirstIssue_0,
    entries_io_deqEntry_0_bits_payload_pdest,
    entries_io_deqEntry_0_bits_payload_rfWen,
    core_deq_data_src[0][0],
    core_deq_data_src[0][1],
    core_deq_exu_src[0][0],
    core_deq_exu_src[0][1],
    3'h0,
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
  wire [7:0] dly0_bits_rf_1_0_addr = core_dly0_payload[993:986];
  wire [2:0] dly0_bits_rf_1_0_srcType = core_dly0_payload[985:983];
  wire [7:0] dly0_bits_rf_0_0_addr = core_dly0_payload[982:975];
  wire [2:0] dly0_bits_rf_0_0_srcType = core_dly0_payload[974:972];
  wire [3:0] dly0_bits_srcType_0 = core_dly0_payload[971:968];
  wire [3:0] dly0_bits_srcType_1 = core_dly0_payload[967:964];
  wire [4:0] dly0_bits_rcIdx_0 = core_dly0_payload[963:959];
  wire [4:0] dly0_bits_rcIdx_1 = core_dly0_payload[958:954];
  wire [3:0] dly0_bits_immType = core_dly0_payload[953:950];
  wire [34:0] dly0_bits_common_fuType = core_dly0_payload[949:915];
  wire [8:0] dly0_bits_common_fuOpType = core_dly0_payload[914:906];
  wire [63:0] dly0_bits_common_src_0 = core_dly0_payload[905:842];
  wire [63:0] dly0_bits_common_src_1 = core_dly0_payload[841:778];
  wire [63:0] dly0_bits_common_imm = core_dly0_payload[777:714];
  wire dly0_bits_common_robIdx_flag = core_dly0_payload[713:713];
  wire [7:0] dly0_bits_common_robIdx_value = core_dly0_payload[712:705];
  wire [3:0] dly0_bits_common_iqIdx = core_dly0_payload[704:701];
  wire dly0_bits_common_isFirstIssue = core_dly0_payload[700:700];
  wire [7:0] dly0_bits_common_pdest = core_dly0_payload[699:692];
  wire dly0_bits_common_rfWen = core_dly0_payload[691:691];
  wire [3:0] dly0_bits_common_dataSources_0_value = core_dly0_payload[690:687];
  wire [3:0] dly0_bits_common_dataSources_1_value = core_dly0_payload[686:683];
  wire [2:0] dly0_bits_common_exuSources_0_value = core_dly0_payload[682:680];
  wire [2:0] dly0_bits_common_exuSources_1_value = core_dly0_payload[679:677];
  wire [2:0] dly0_bits_common_srcTimer_0 = core_dly0_payload[676:674];
  wire [2:0] dly0_bits_common_srcTimer_1 = core_dly0_payload[673:671];
  wire [1:0] dly0_bits_common_loadDependency_0 = core_dly0_payload[670:669];
  wire [1:0] dly0_bits_common_loadDependency_1 = core_dly0_payload[668:667];
  wire [1:0] dly0_bits_common_loadDependency_2 = core_dly0_payload[666:665];
  wire dly0_bits_common_perfDebugInfo_eliminatedMove = core_dly0_payload[664:664];
  wire [63:0] dly0_bits_common_perfDebugInfo_renameTime = core_dly0_payload[663:600];
  wire [63:0] dly0_bits_common_perfDebugInfo_dispatchTime = core_dly0_payload[599:536];
  wire [63:0] dly0_bits_common_perfDebugInfo_enqRsTime = core_dly0_payload[535:472];
  wire [63:0] dly0_bits_common_perfDebugInfo_selectTime = core_dly0_payload[471:408];
  wire [63:0] dly0_bits_common_perfDebugInfo_issueTime = core_dly0_payload[407:344];
  wire [63:0] dly0_bits_common_perfDebugInfo_writebackTime = core_dly0_payload[343:280];
  wire [63:0] dly0_bits_common_perfDebugInfo_runahead_checkpoint_id = core_dly0_payload[279:216];
  wire [63:0] dly0_bits_common_perfDebugInfo_tlbFirstReqTime = core_dly0_payload[215:152];
  wire [63:0] dly0_bits_common_perfDebugInfo_tlbRespTime = core_dly0_payload[151:88];
  wire [55:0] dly0_bits_common_debug_seqNum_seqNum = core_dly0_payload[87:32];
  wire [7:0] dly0_bits_common_debug_seqNum_uopIdx = core_dly0_payload[31:24];
  wire [23:0] dly0_bits_addrOH = core_dly0_payload[23:0];

  // ---- 口 1 deqDelay 负载（golden 寄存器声明顺序，高位在前）----
  assign core_deq1_payload = {
    entries_io_deqEntry_1_bits_status_srcStatus_1_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_1_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_0_psrc,
    entries_io_deqEntry_1_bits_status_srcStatus_0_srcType[2:0],
    entries_io_deqEntry_1_bits_status_srcStatus_0_srcType,
    entries_io_deqEntry_1_bits_status_srcStatus_1_srcType,
    entries_io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx,
    entries_io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx,
    entries_io_deqEntry_1_bits_payload_selImm,
    {5'h0, entries_io_deqEntry_1_bits_status_fuType_29, entries_io_deqEntry_1_bits_status_fuType_28, 21'h0, entries_io_deqEntry_1_bits_status_fuType_6, 2'h0, entries_io_deqEntry_1_bits_status_fuType_3, entries_io_deqEntry_1_bits_status_fuType_2, entries_io_deqEntry_1_bits_status_fuType_1, entries_io_deqEntry_1_bits_status_fuType_0},
    entries_io_deqEntry_1_bits_payload_fuOpType,
    64'h0,
    64'h0,
    {32'h0, entries_io_deqEntry_1_bits_imm},
    5'h0,
    entries_io_deqEntry_1_bits_status_robIdx_flag,
    entries_io_deqEntry_1_bits_status_robIdx_value,
    core_deq_iq_idx[1],
    entries_io_isFirstIssue_1,
    entries_io_deqEntry_1_bits_payload_pdest,
    entries_io_deqEntry_1_bits_payload_rfWen,
    entries_io_deqEntry_1_bits_payload_fpWen,
    entries_io_deqEntry_1_bits_payload_vecWen,
    entries_io_deqEntry_1_bits_payload_v0Wen,
    entries_io_deqEntry_1_bits_payload_vlWen,
    entries_io_deqEntry_1_bits_payload_fpu_typeTagOut,
    entries_io_deqEntry_1_bits_payload_fpu_wflags,
    entries_io_deqEntry_1_bits_payload_fpu_typ,
    entries_io_deqEntry_1_bits_payload_fpu_fmt,
    entries_io_deqEntry_1_bits_payload_fpu_rm,
    50'h0,
    entries_io_deqEntry_1_bits_payload_preDecodeInfo_valid,
    entries_io_deqEntry_1_bits_payload_preDecodeInfo_isRVC,
    entries_io_deqEntry_1_bits_payload_preDecodeInfo_brType,
    entries_io_deqEntry_1_bits_payload_preDecodeInfo_isCall,
    entries_io_deqEntry_1_bits_payload_preDecodeInfo_isRet,
    entries_io_deqEntry_1_bits_payload_ftqPtr_flag,
    entries_io_deqEntry_1_bits_payload_ftqPtr_value,
    entries_io_deqEntry_1_bits_payload_ftqOffset,
    50'h0,
    entries_io_deqEntry_1_bits_payload_pred_taken,
    core_deq_data_src[1][0],
    core_deq_data_src[1][1],
    core_deq_exu_src[1][0],
    core_deq_exu_src[1][1],
    3'h0,
    3'h0,
    core_deq_ld_dep[1][0],
    core_deq_ld_dep[1][1],
    core_deq_ld_dep[1][2],
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
  wire [7:0] dly1_bits_rf_1_0_addr = core_dly1_payload[1130:1123];
  wire [2:0] dly1_bits_rf_1_0_srcType = core_dly1_payload[1122:1120];
  wire [7:0] dly1_bits_rf_0_0_addr = core_dly1_payload[1119:1112];
  wire [2:0] dly1_bits_rf_0_0_srcType = core_dly1_payload[1111:1109];
  wire [3:0] dly1_bits_srcType_0 = core_dly1_payload[1108:1105];
  wire [3:0] dly1_bits_srcType_1 = core_dly1_payload[1104:1101];
  wire [4:0] dly1_bits_rcIdx_0 = core_dly1_payload[1100:1096];
  wire [4:0] dly1_bits_rcIdx_1 = core_dly1_payload[1095:1091];
  wire [3:0] dly1_bits_immType = core_dly1_payload[1090:1087];
  wire [34:0] dly1_bits_common_fuType = core_dly1_payload[1086:1052];
  wire [8:0] dly1_bits_common_fuOpType = core_dly1_payload[1051:1043];
  wire [63:0] dly1_bits_common_src_0 = core_dly1_payload[1042:979];
  wire [63:0] dly1_bits_common_src_1 = core_dly1_payload[978:915];
  wire [63:0] dly1_bits_common_imm = core_dly1_payload[914:851];
  wire [4:0] dly1_bits_common_nextPcOffset = core_dly1_payload[850:846];
  wire dly1_bits_common_robIdx_flag = core_dly1_payload[845:845];
  wire [7:0] dly1_bits_common_robIdx_value = core_dly1_payload[844:837];
  wire [3:0] dly1_bits_common_iqIdx = core_dly1_payload[836:833];
  wire dly1_bits_common_isFirstIssue = core_dly1_payload[832:832];
  wire [7:0] dly1_bits_common_pdest = core_dly1_payload[831:824];
  wire dly1_bits_common_rfWen = core_dly1_payload[823:823];
  wire dly1_bits_common_fpWen = core_dly1_payload[822:822];
  wire dly1_bits_common_vecWen = core_dly1_payload[821:821];
  wire dly1_bits_common_v0Wen = core_dly1_payload[820:820];
  wire dly1_bits_common_vlWen = core_dly1_payload[819:819];
  wire [1:0] dly1_bits_common_fpu_typeTagOut = core_dly1_payload[818:817];
  wire dly1_bits_common_fpu_wflags = core_dly1_payload[816:816];
  wire [1:0] dly1_bits_common_fpu_typ = core_dly1_payload[815:814];
  wire [1:0] dly1_bits_common_fpu_fmt = core_dly1_payload[813:812];
  wire [2:0] dly1_bits_common_fpu_rm = core_dly1_payload[811:809];
  wire [49:0] dly1_bits_common_pc = core_dly1_payload[808:759];
  wire dly1_bits_common_preDecode_valid = core_dly1_payload[758:758];
  wire dly1_bits_common_preDecode_isRVC = core_dly1_payload[757:757];
  wire [1:0] dly1_bits_common_preDecode_brType = core_dly1_payload[756:755];
  wire dly1_bits_common_preDecode_isCall = core_dly1_payload[754:754];
  wire dly1_bits_common_preDecode_isRet = core_dly1_payload[753:753];
  wire dly1_bits_common_ftqIdx_flag = core_dly1_payload[752:752];
  wire [5:0] dly1_bits_common_ftqIdx_value = core_dly1_payload[751:746];
  wire [3:0] dly1_bits_common_ftqOffset = core_dly1_payload[745:742];
  wire [49:0] dly1_bits_common_predictInfo_target = core_dly1_payload[741:692];
  wire dly1_bits_common_predictInfo_taken = core_dly1_payload[691:691];
  wire [3:0] dly1_bits_common_dataSources_0_value = core_dly1_payload[690:687];
  wire [3:0] dly1_bits_common_dataSources_1_value = core_dly1_payload[686:683];
  wire [2:0] dly1_bits_common_exuSources_0_value = core_dly1_payload[682:680];
  wire [2:0] dly1_bits_common_exuSources_1_value = core_dly1_payload[679:677];
  wire [2:0] dly1_bits_common_srcTimer_0 = core_dly1_payload[676:674];
  wire [2:0] dly1_bits_common_srcTimer_1 = core_dly1_payload[673:671];
  wire [1:0] dly1_bits_common_loadDependency_0 = core_dly1_payload[670:669];
  wire [1:0] dly1_bits_common_loadDependency_1 = core_dly1_payload[668:667];
  wire [1:0] dly1_bits_common_loadDependency_2 = core_dly1_payload[666:665];
  wire dly1_bits_common_perfDebugInfo_eliminatedMove = core_dly1_payload[664:664];
  wire [63:0] dly1_bits_common_perfDebugInfo_renameTime = core_dly1_payload[663:600];
  wire [63:0] dly1_bits_common_perfDebugInfo_dispatchTime = core_dly1_payload[599:536];
  wire [63:0] dly1_bits_common_perfDebugInfo_enqRsTime = core_dly1_payload[535:472];
  wire [63:0] dly1_bits_common_perfDebugInfo_selectTime = core_dly1_payload[471:408];
  wire [63:0] dly1_bits_common_perfDebugInfo_issueTime = core_dly1_payload[407:344];
  wire [63:0] dly1_bits_common_perfDebugInfo_writebackTime = core_dly1_payload[343:280];
  wire [63:0] dly1_bits_common_perfDebugInfo_runahead_checkpoint_id = core_dly1_payload[279:216];
  wire [63:0] dly1_bits_common_perfDebugInfo_tlbFirstReqTime = core_dly1_payload[215:152];
  wire [63:0] dly1_bits_common_perfDebugInfo_tlbRespTime = core_dly1_payload[151:88];
  wire [55:0] dly1_bits_common_debug_seqNum_seqNum = core_dly1_payload[87:32];
  wire [7:0] dly1_bits_common_debug_seqNum_uopIdx = core_dly1_payload[31:24];
  wire [23:0] dly1_bits_addrOH = core_dly1_payload[23:0];

  EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v entries (
    .clock                                                       (clock),
    .reset                                                       (reset),
    .io_flush_valid                                              (io_flush_valid),
    .io_flush_bits_robIdx_flag                                   (io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value                                  (io_flush_bits_robIdx_value),
    .io_flush_bits_level                                         (io_flush_bits_level),
    .io_enq_0_valid                                              (core_enq_do[0]),
    .io_enq_0_bits_status_robIdx_flag                            (io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_status_robIdx_value                           (io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_status_fuType_0                               (io_enq_0_bits_fuType[0]),
    .io_enq_0_bits_status_fuType_1                               (io_enq_0_bits_fuType[1]),
    .io_enq_0_bits_status_fuType_2                               (io_enq_0_bits_fuType[2]),
    .io_enq_0_bits_status_fuType_3                               (io_enq_0_bits_fuType[3]),
    .io_enq_0_bits_status_fuType_6                               (io_enq_0_bits_fuType[6]),
    .io_enq_0_bits_status_fuType_28                              (io_enq_0_bits_fuType[28]),
    .io_enq_0_bits_status_fuType_29                              (io_enq_0_bits_fuType[29]),
    .io_enq_0_bits_status_srcStatus_0_psrc                       (io_enq_0_bits_psrc_0),
    .io_enq_0_bits_status_srcStatus_0_srcType                    (io_enq_0_bits_srcType_0),
    .io_enq_0_bits_status_srcStatus_0_srcState                   (core_st_src_state[0][0]),
    .io_enq_0_bits_status_srcStatus_0_dataSources_value          (core_st_data_src[0][0]),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0        (core_st_src_ld[0][0][0]),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1        (core_st_src_ld[0][0][1]),
    .io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2        (core_st_src_ld[0][0][2]),
    .io_enq_0_bits_status_srcStatus_0_useRegCache                (io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_status_srcStatus_0_regCacheIdx                (io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_status_srcStatus_1_psrc                       (io_enq_0_bits_psrc_1),
    .io_enq_0_bits_status_srcStatus_1_srcType                    (io_enq_0_bits_srcType_1),
    .io_enq_0_bits_status_srcStatus_1_srcState                   (core_st_src_state[0][1]),
    .io_enq_0_bits_status_srcStatus_1_dataSources_value          (core_st_data_src[0][1]),
    .io_enq_0_bits_status_srcStatus_1_srcLoadDependency_0        (core_st_src_ld[0][1][0]),
    .io_enq_0_bits_status_srcStatus_1_srcLoadDependency_1        (core_st_src_ld[0][1][1]),
    .io_enq_0_bits_status_srcStatus_1_srcLoadDependency_2        (core_st_src_ld[0][1][2]),
    .io_enq_0_bits_status_srcStatus_1_useRegCache                (io_enq_0_bits_useRegCache_1),
    .io_enq_0_bits_status_srcStatus_1_regCacheIdx                (io_enq_0_bits_regCacheIdx_1),
    .io_enq_0_bits_imm                                           (io_enq_0_bits_imm),
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
    .io_enq_1_bits_status_fuType_0                               (io_enq_1_bits_fuType[0]),
    .io_enq_1_bits_status_fuType_1                               (io_enq_1_bits_fuType[1]),
    .io_enq_1_bits_status_fuType_2                               (io_enq_1_bits_fuType[2]),
    .io_enq_1_bits_status_fuType_3                               (io_enq_1_bits_fuType[3]),
    .io_enq_1_bits_status_fuType_6                               (io_enq_1_bits_fuType[6]),
    .io_enq_1_bits_status_fuType_28                              (io_enq_1_bits_fuType[28]),
    .io_enq_1_bits_status_fuType_29                              (io_enq_1_bits_fuType[29]),
    .io_enq_1_bits_status_srcStatus_0_psrc                       (io_enq_1_bits_psrc_0),
    .io_enq_1_bits_status_srcStatus_0_srcType                    (io_enq_1_bits_srcType_0),
    .io_enq_1_bits_status_srcStatus_0_srcState                   (core_st_src_state[1][0]),
    .io_enq_1_bits_status_srcStatus_0_dataSources_value          (core_st_data_src[1][0]),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0        (core_st_src_ld[1][0][0]),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1        (core_st_src_ld[1][0][1]),
    .io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2        (core_st_src_ld[1][0][2]),
    .io_enq_1_bits_status_srcStatus_0_useRegCache                (io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_status_srcStatus_0_regCacheIdx                (io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_status_srcStatus_1_psrc                       (io_enq_1_bits_psrc_1),
    .io_enq_1_bits_status_srcStatus_1_srcType                    (io_enq_1_bits_srcType_1),
    .io_enq_1_bits_status_srcStatus_1_srcState                   (core_st_src_state[1][1]),
    .io_enq_1_bits_status_srcStatus_1_dataSources_value          (core_st_data_src[1][1]),
    .io_enq_1_bits_status_srcStatus_1_srcLoadDependency_0        (core_st_src_ld[1][1][0]),
    .io_enq_1_bits_status_srcStatus_1_srcLoadDependency_1        (core_st_src_ld[1][1][1]),
    .io_enq_1_bits_status_srcStatus_1_srcLoadDependency_2        (core_st_src_ld[1][1][2]),
    .io_enq_1_bits_status_srcStatus_1_useRegCache                (io_enq_1_bits_useRegCache_1),
    .io_enq_1_bits_status_srcStatus_1_regCacheIdx                (io_enq_1_bits_regCacheIdx_1),
    .io_enq_1_bits_imm                                           (io_enq_1_bits_imm),
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
    .io_og0Resp_1_valid                                          (io_og0Resp_1_valid),
    .io_og1Resp_0_valid                                          (io_og1Resp_0_valid),
    .io_og1Resp_0_bits_resp                                      (io_og1Resp_0_bits_resp),
    .io_og1Resp_1_valid                                          (io_og1Resp_1_valid),
    .io_og1Resp_1_bits_resp                                      (io_og1Resp_1_bits_resp),
    .io_deqReady_0                                               (1'h1),
    .io_deqReady_1                                               (1'h1),
    .io_deqSelOH_0_valid                                         (core_sel_valid[0]),
    .io_deqSelOH_0_bits                                          (core_sel_oh[0]),
    .io_deqSelOH_1_valid                                         (core_sel_valid[1]),
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
    .io_wakeUpFromWB_3_valid                                     (io_wakeupFromWB_3_valid),
    .io_wakeUpFromWB_3_bits_rfWen                                (io_wakeupFromWB_3_bits_rfWen),
    .io_wakeUpFromWB_3_bits_pdest                                (io_wakeupFromWB_3_bits_pdest),
    .io_wakeUpFromWB_2_valid                                     (io_wakeupFromWB_2_valid),
    .io_wakeUpFromWB_2_bits_rfWen                                (io_wakeupFromWB_2_bits_rfWen),
    .io_wakeUpFromWB_2_bits_pdest                                (io_wakeupFromWB_2_bits_pdest),
    .io_wakeUpFromWB_1_valid                                     (io_wakeupFromWB_1_valid),
    .io_wakeUpFromWB_1_bits_rfWen                                (io_wakeupFromWB_1_bits_rfWen),
    .io_wakeUpFromWB_1_bits_pdest                                (io_wakeupFromWB_1_bits_pdest),
    .io_wakeUpFromWB_0_valid                                     (io_wakeupFromWB_0_valid),
    .io_wakeUpFromWB_0_bits_rfWen                                (io_wakeupFromWB_0_bits_rfWen),
    .io_wakeUpFromWB_0_bits_pdest                                (io_wakeupFromWB_0_bits_pdest),
    .io_wakeUpFromIQ_6_bits_rfWen                                (io_wakeupFromIQ_6_bits_rfWen),
    .io_wakeUpFromIQ_6_bits_pdest                                (io_wakeupFromIQ_6_bits_pdest),
    .io_wakeUpFromIQ_6_bits_loadDependency_0                     (io_wakeupFromIQ_6_bits_loadDependency_0),
    .io_wakeUpFromIQ_6_bits_loadDependency_1                     (io_wakeupFromIQ_6_bits_loadDependency_1),
    .io_wakeUpFromIQ_6_bits_loadDependency_2                     (io_wakeupFromIQ_6_bits_loadDependency_2),
    .io_wakeUpFromIQ_6_bits_rcDest                               (io_wakeupFromIQ_6_bits_rcDest),
    .io_wakeUpFromIQ_5_bits_rfWen                                (io_wakeupFromIQ_5_bits_rfWen),
    .io_wakeUpFromIQ_5_bits_pdest                                (io_wakeupFromIQ_5_bits_pdest),
    .io_wakeUpFromIQ_5_bits_loadDependency_0                     (io_wakeupFromIQ_5_bits_loadDependency_0),
    .io_wakeUpFromIQ_5_bits_loadDependency_1                     (io_wakeupFromIQ_5_bits_loadDependency_1),
    .io_wakeUpFromIQ_5_bits_loadDependency_2                     (io_wakeupFromIQ_5_bits_loadDependency_2),
    .io_wakeUpFromIQ_5_bits_rcDest                               (io_wakeupFromIQ_5_bits_rcDest),
    .io_wakeUpFromIQ_4_bits_rfWen                                (io_wakeupFromIQ_4_bits_rfWen),
    .io_wakeUpFromIQ_4_bits_pdest                                (io_wakeupFromIQ_4_bits_pdest),
    .io_wakeUpFromIQ_4_bits_loadDependency_0                     (io_wakeupFromIQ_4_bits_loadDependency_0),
    .io_wakeUpFromIQ_4_bits_loadDependency_1                     (io_wakeupFromIQ_4_bits_loadDependency_1),
    .io_wakeUpFromIQ_4_bits_loadDependency_2                     (io_wakeupFromIQ_4_bits_loadDependency_2),
    .io_wakeUpFromIQ_4_bits_rcDest                               (io_wakeupFromIQ_4_bits_rcDest),
    .io_wakeUpFromIQ_3_bits_rfWen                                (io_wakeupFromIQ_3_bits_rfWen),
    .io_wakeUpFromIQ_3_bits_pdest                                (io_wakeupFromIQ_3_bits_pdest),
    .io_wakeUpFromIQ_3_bits_loadDependency_0                     (io_wakeupFromIQ_3_bits_loadDependency_0),
    .io_wakeUpFromIQ_3_bits_loadDependency_1                     (io_wakeupFromIQ_3_bits_loadDependency_1),
    .io_wakeUpFromIQ_3_bits_loadDependency_2                     (io_wakeupFromIQ_3_bits_loadDependency_2),
    .io_wakeUpFromIQ_3_bits_rcDest                               (io_wakeupFromIQ_3_bits_rcDest),
    .io_wakeUpFromIQ_2_bits_rfWen                                (io_wakeupFromIQ_2_bits_rfWen),
    .io_wakeUpFromIQ_2_bits_pdest                                (io_wakeupFromIQ_2_bits_pdest),
    .io_wakeUpFromIQ_2_bits_loadDependency_0                     (io_wakeupFromIQ_2_bits_loadDependency_0),
    .io_wakeUpFromIQ_2_bits_loadDependency_1                     (io_wakeupFromIQ_2_bits_loadDependency_1),
    .io_wakeUpFromIQ_2_bits_loadDependency_2                     (io_wakeupFromIQ_2_bits_loadDependency_2),
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
    .io_wakeUpFromWBDelayed_3_valid                              (io_wakeupFromWBDelayed_3_valid),
    .io_wakeUpFromWBDelayed_3_bits_rfWen                         (io_wakeupFromWBDelayed_3_bits_rfWen),
    .io_wakeUpFromWBDelayed_3_bits_pdest                         (io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeUpFromWBDelayed_2_valid                              (io_wakeupFromWBDelayed_2_valid),
    .io_wakeUpFromWBDelayed_2_bits_rfWen                         (io_wakeupFromWBDelayed_2_bits_rfWen),
    .io_wakeUpFromWBDelayed_2_bits_pdest                         (io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeUpFromWBDelayed_1_valid                              (io_wakeupFromWBDelayed_1_valid),
    .io_wakeUpFromWBDelayed_1_bits_rfWen                         (io_wakeupFromWBDelayed_1_bits_rfWen),
    .io_wakeUpFromWBDelayed_1_bits_pdest                         (io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeUpFromWBDelayed_0_valid                              (io_wakeupFromWBDelayed_0_valid),
    .io_wakeUpFromWBDelayed_0_bits_rfWen                         (io_wakeupFromWBDelayed_0_bits_rfWen),
    .io_wakeUpFromWBDelayed_0_bits_pdest                         (io_wakeupFromWBDelayed_0_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_rfWen                         (io_wakeupFromIQDelayed_6_bits_rfWen),
    .io_wakeUpFromIQDelayed_6_bits_pdest                         (io_wakeupFromIQDelayed_6_bits_pdest),
    .io_wakeUpFromIQDelayed_6_bits_loadDependency_0              (io_wakeupFromIQDelayed_6_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_6_bits_loadDependency_1              (io_wakeupFromIQDelayed_6_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_6_bits_loadDependency_2              (io_wakeupFromIQDelayed_6_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_6_bits_rcDest                        (io_wakeupFromIQDelayed_6_bits_rcDest),
    .io_wakeUpFromIQDelayed_5_bits_rfWen                         (io_wakeupFromIQDelayed_5_bits_rfWen),
    .io_wakeUpFromIQDelayed_5_bits_pdest                         (io_wakeupFromIQDelayed_5_bits_pdest),
    .io_wakeUpFromIQDelayed_5_bits_loadDependency_0              (io_wakeupFromIQDelayed_5_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_5_bits_loadDependency_1              (io_wakeupFromIQDelayed_5_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_5_bits_loadDependency_2              (io_wakeupFromIQDelayed_5_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_5_bits_rcDest                        (io_wakeupFromIQDelayed_5_bits_rcDest),
    .io_wakeUpFromIQDelayed_4_bits_rfWen                         (io_wakeupFromIQDelayed_4_bits_rfWen),
    .io_wakeUpFromIQDelayed_4_bits_pdest                         (io_wakeupFromIQDelayed_4_bits_pdest),
    .io_wakeUpFromIQDelayed_4_bits_loadDependency_0              (io_wakeupFromIQDelayed_4_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_4_bits_loadDependency_1              (io_wakeupFromIQDelayed_4_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_4_bits_loadDependency_2              (io_wakeupFromIQDelayed_4_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_4_bits_rcDest                        (io_wakeupFromIQDelayed_4_bits_rcDest),
    .io_wakeUpFromIQDelayed_3_bits_rfWen                         (io_wakeupFromIQDelayed_3_bits_rfWen),
    .io_wakeUpFromIQDelayed_3_bits_pdest                         (io_wakeupFromIQDelayed_3_bits_pdest),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_0              (io_wakeupFromIQDelayed_3_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_1              (io_wakeupFromIQDelayed_3_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_3_bits_loadDependency_2              (io_wakeupFromIQDelayed_3_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_3_bits_rcDest                        (io_wakeupFromIQDelayed_3_bits_rcDest),
    .io_wakeUpFromIQDelayed_2_bits_rfWen                         (io_wakeupFromIQDelayed_2_bits_rfWen),
    .io_wakeUpFromIQDelayed_2_bits_pdest                         (io_wakeupFromIQDelayed_2_bits_pdest),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_0              (io_wakeupFromIQDelayed_2_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_1              (io_wakeupFromIQDelayed_2_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_2_bits_loadDependency_2              (io_wakeupFromIQDelayed_2_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_2_bits_rcDest                        (io_wakeupFromIQDelayed_2_bits_rcDest),
    .io_wakeUpFromIQDelayed_1_bits_rfWen                         (io_wakeupFromIQDelayed_1_bits_rfWen),
    .io_wakeUpFromIQDelayed_1_bits_pdest                         (io_wakeupFromIQDelayed_1_bits_pdest),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_0              (io_wakeupFromIQDelayed_1_bits_loadDependency_0),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_1              (io_wakeupFromIQDelayed_1_bits_loadDependency_1),
    .io_wakeUpFromIQDelayed_1_bits_loadDependency_2              (io_wakeupFromIQDelayed_1_bits_loadDependency_2),
    .io_wakeUpFromIQDelayed_1_bits_is0Lat                        (io_wakeupFromIQDelayed_1_bits_is0Lat),
    .io_wakeUpFromIQDelayed_1_bits_rcDest                        (io_wakeupFromIQDelayed_1_bits_rcDest),
    .io_wakeUpFromIQDelayed_0_bits_rfWen                         (io_wakeupFromIQDelayed_0_bits_rfWen),
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
    .io_ldCancel_0_ld2Cancel                                     (io_ldCancel_0_ld2Cancel),
    .io_ldCancel_1_ld2Cancel                                     (io_ldCancel_1_ld2Cancel),
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
    .io_fuType_16                                                (entries_io_fuType_16),
    .io_fuType_17                                                (entries_io_fuType_17),
    .io_fuType_18                                                (entries_io_fuType_18),
    .io_fuType_19                                                (entries_io_fuType_19),
    .io_fuType_20                                                (entries_io_fuType_20),
    .io_fuType_21                                                (entries_io_fuType_21),
    .io_fuType_22                                                (entries_io_fuType_22),
    .io_fuType_23                                                (entries_io_fuType_23),
    .io_dataSources_0_0_value                                    (entries_io_dataSources_0_0_value),
    .io_dataSources_0_1_value                                    (entries_io_dataSources_0_1_value),
    .io_dataSources_1_0_value                                    (entries_io_dataSources_1_0_value),
    .io_dataSources_1_1_value                                    (entries_io_dataSources_1_1_value),
    .io_dataSources_2_0_value                                    (entries_io_dataSources_2_0_value),
    .io_dataSources_2_1_value                                    (entries_io_dataSources_2_1_value),
    .io_dataSources_3_0_value                                    (entries_io_dataSources_3_0_value),
    .io_dataSources_3_1_value                                    (entries_io_dataSources_3_1_value),
    .io_dataSources_4_0_value                                    (entries_io_dataSources_4_0_value),
    .io_dataSources_4_1_value                                    (entries_io_dataSources_4_1_value),
    .io_dataSources_5_0_value                                    (entries_io_dataSources_5_0_value),
    .io_dataSources_5_1_value                                    (entries_io_dataSources_5_1_value),
    .io_dataSources_6_0_value                                    (entries_io_dataSources_6_0_value),
    .io_dataSources_6_1_value                                    (entries_io_dataSources_6_1_value),
    .io_dataSources_7_0_value                                    (entries_io_dataSources_7_0_value),
    .io_dataSources_7_1_value                                    (entries_io_dataSources_7_1_value),
    .io_dataSources_8_0_value                                    (entries_io_dataSources_8_0_value),
    .io_dataSources_8_1_value                                    (entries_io_dataSources_8_1_value),
    .io_dataSources_9_0_value                                    (entries_io_dataSources_9_0_value),
    .io_dataSources_9_1_value                                    (entries_io_dataSources_9_1_value),
    .io_dataSources_10_0_value                                   (entries_io_dataSources_10_0_value),
    .io_dataSources_10_1_value                                   (entries_io_dataSources_10_1_value),
    .io_dataSources_11_0_value                                   (entries_io_dataSources_11_0_value),
    .io_dataSources_11_1_value                                   (entries_io_dataSources_11_1_value),
    .io_dataSources_12_0_value                                   (entries_io_dataSources_12_0_value),
    .io_dataSources_12_1_value                                   (entries_io_dataSources_12_1_value),
    .io_dataSources_13_0_value                                   (entries_io_dataSources_13_0_value),
    .io_dataSources_13_1_value                                   (entries_io_dataSources_13_1_value),
    .io_dataSources_14_0_value                                   (entries_io_dataSources_14_0_value),
    .io_dataSources_14_1_value                                   (entries_io_dataSources_14_1_value),
    .io_dataSources_15_0_value                                   (entries_io_dataSources_15_0_value),
    .io_dataSources_15_1_value                                   (entries_io_dataSources_15_1_value),
    .io_dataSources_16_0_value                                   (entries_io_dataSources_16_0_value),
    .io_dataSources_16_1_value                                   (entries_io_dataSources_16_1_value),
    .io_dataSources_17_0_value                                   (entries_io_dataSources_17_0_value),
    .io_dataSources_17_1_value                                   (entries_io_dataSources_17_1_value),
    .io_dataSources_18_0_value                                   (entries_io_dataSources_18_0_value),
    .io_dataSources_18_1_value                                   (entries_io_dataSources_18_1_value),
    .io_dataSources_19_0_value                                   (entries_io_dataSources_19_0_value),
    .io_dataSources_19_1_value                                   (entries_io_dataSources_19_1_value),
    .io_dataSources_20_0_value                                   (entries_io_dataSources_20_0_value),
    .io_dataSources_20_1_value                                   (entries_io_dataSources_20_1_value),
    .io_dataSources_21_0_value                                   (entries_io_dataSources_21_0_value),
    .io_dataSources_21_1_value                                   (entries_io_dataSources_21_1_value),
    .io_dataSources_22_0_value                                   (entries_io_dataSources_22_0_value),
    .io_dataSources_22_1_value                                   (entries_io_dataSources_22_1_value),
    .io_dataSources_23_0_value                                   (entries_io_dataSources_23_0_value),
    .io_dataSources_23_1_value                                   (entries_io_dataSources_23_1_value),
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
    .io_loadDependency_16_0                                      (entries_io_loadDependency_16_0),
    .io_loadDependency_16_1                                      (entries_io_loadDependency_16_1),
    .io_loadDependency_16_2                                      (entries_io_loadDependency_16_2),
    .io_loadDependency_17_0                                      (entries_io_loadDependency_17_0),
    .io_loadDependency_17_1                                      (entries_io_loadDependency_17_1),
    .io_loadDependency_17_2                                      (entries_io_loadDependency_17_2),
    .io_loadDependency_18_0                                      (entries_io_loadDependency_18_0),
    .io_loadDependency_18_1                                      (entries_io_loadDependency_18_1),
    .io_loadDependency_18_2                                      (entries_io_loadDependency_18_2),
    .io_loadDependency_19_0                                      (entries_io_loadDependency_19_0),
    .io_loadDependency_19_1                                      (entries_io_loadDependency_19_1),
    .io_loadDependency_19_2                                      (entries_io_loadDependency_19_2),
    .io_loadDependency_20_0                                      (entries_io_loadDependency_20_0),
    .io_loadDependency_20_1                                      (entries_io_loadDependency_20_1),
    .io_loadDependency_20_2                                      (entries_io_loadDependency_20_2),
    .io_loadDependency_21_0                                      (entries_io_loadDependency_21_0),
    .io_loadDependency_21_1                                      (entries_io_loadDependency_21_1),
    .io_loadDependency_21_2                                      (entries_io_loadDependency_21_2),
    .io_loadDependency_22_0                                      (entries_io_loadDependency_22_0),
    .io_loadDependency_22_1                                      (entries_io_loadDependency_22_1),
    .io_loadDependency_22_2                                      (entries_io_loadDependency_22_2),
    .io_loadDependency_23_0                                      (entries_io_loadDependency_23_0),
    .io_loadDependency_23_1                                      (entries_io_loadDependency_23_1),
    .io_loadDependency_23_2                                      (entries_io_loadDependency_23_2),
    .io_exuSources_0_0_value                                     (entries_io_exuSources_0_0_value),
    .io_exuSources_0_1_value                                     (entries_io_exuSources_0_1_value),
    .io_exuSources_1_0_value                                     (entries_io_exuSources_1_0_value),
    .io_exuSources_1_1_value                                     (entries_io_exuSources_1_1_value),
    .io_exuSources_2_0_value                                     (entries_io_exuSources_2_0_value),
    .io_exuSources_2_1_value                                     (entries_io_exuSources_2_1_value),
    .io_exuSources_3_0_value                                     (entries_io_exuSources_3_0_value),
    .io_exuSources_3_1_value                                     (entries_io_exuSources_3_1_value),
    .io_exuSources_4_0_value                                     (entries_io_exuSources_4_0_value),
    .io_exuSources_4_1_value                                     (entries_io_exuSources_4_1_value),
    .io_exuSources_5_0_value                                     (entries_io_exuSources_5_0_value),
    .io_exuSources_5_1_value                                     (entries_io_exuSources_5_1_value),
    .io_exuSources_6_0_value                                     (entries_io_exuSources_6_0_value),
    .io_exuSources_6_1_value                                     (entries_io_exuSources_6_1_value),
    .io_exuSources_7_0_value                                     (entries_io_exuSources_7_0_value),
    .io_exuSources_7_1_value                                     (entries_io_exuSources_7_1_value),
    .io_exuSources_8_0_value                                     (entries_io_exuSources_8_0_value),
    .io_exuSources_8_1_value                                     (entries_io_exuSources_8_1_value),
    .io_exuSources_9_0_value                                     (entries_io_exuSources_9_0_value),
    .io_exuSources_9_1_value                                     (entries_io_exuSources_9_1_value),
    .io_exuSources_10_0_value                                    (entries_io_exuSources_10_0_value),
    .io_exuSources_10_1_value                                    (entries_io_exuSources_10_1_value),
    .io_exuSources_11_0_value                                    (entries_io_exuSources_11_0_value),
    .io_exuSources_11_1_value                                    (entries_io_exuSources_11_1_value),
    .io_exuSources_12_0_value                                    (entries_io_exuSources_12_0_value),
    .io_exuSources_12_1_value                                    (entries_io_exuSources_12_1_value),
    .io_exuSources_13_0_value                                    (entries_io_exuSources_13_0_value),
    .io_exuSources_13_1_value                                    (entries_io_exuSources_13_1_value),
    .io_exuSources_14_0_value                                    (entries_io_exuSources_14_0_value),
    .io_exuSources_14_1_value                                    (entries_io_exuSources_14_1_value),
    .io_exuSources_15_0_value                                    (entries_io_exuSources_15_0_value),
    .io_exuSources_15_1_value                                    (entries_io_exuSources_15_1_value),
    .io_exuSources_16_0_value                                    (entries_io_exuSources_16_0_value),
    .io_exuSources_16_1_value                                    (entries_io_exuSources_16_1_value),
    .io_exuSources_17_0_value                                    (entries_io_exuSources_17_0_value),
    .io_exuSources_17_1_value                                    (entries_io_exuSources_17_1_value),
    .io_exuSources_18_0_value                                    (entries_io_exuSources_18_0_value),
    .io_exuSources_18_1_value                                    (entries_io_exuSources_18_1_value),
    .io_exuSources_19_0_value                                    (entries_io_exuSources_19_0_value),
    .io_exuSources_19_1_value                                    (entries_io_exuSources_19_1_value),
    .io_exuSources_20_0_value                                    (entries_io_exuSources_20_0_value),
    .io_exuSources_20_1_value                                    (entries_io_exuSources_20_1_value),
    .io_exuSources_21_0_value                                    (entries_io_exuSources_21_0_value),
    .io_exuSources_21_1_value                                    (entries_io_exuSources_21_1_value),
    .io_exuSources_22_0_value                                    (entries_io_exuSources_22_0_value),
    .io_exuSources_22_1_value                                    (entries_io_exuSources_22_1_value),
    .io_exuSources_23_0_value                                    (entries_io_exuSources_23_0_value),
    .io_exuSources_23_1_value                                    (entries_io_exuSources_23_1_value),
    .io_isFirstIssue_0                                           (entries_io_isFirstIssue_0),
    .io_isFirstIssue_1                                           (entries_io_isFirstIssue_1),
    .io_deqEntry_0_bits_status_robIdx_flag                       (entries_io_deqEntry_0_bits_status_robIdx_flag),
    .io_deqEntry_0_bits_status_robIdx_value                      (entries_io_deqEntry_0_bits_status_robIdx_value),
    .io_deqEntry_0_bits_status_fuType_0                          (entries_io_deqEntry_0_bits_status_fuType_0),
    .io_deqEntry_0_bits_status_fuType_1                          (entries_io_deqEntry_0_bits_status_fuType_1),
    .io_deqEntry_0_bits_status_fuType_2                          (entries_io_deqEntry_0_bits_status_fuType_2),
    .io_deqEntry_0_bits_status_fuType_3                          (entries_io_deqEntry_0_bits_status_fuType_3),
    .io_deqEntry_0_bits_status_fuType_6                          (entries_io_deqEntry_0_bits_status_fuType_6),
    .io_deqEntry_0_bits_status_fuType_28                         (entries_io_deqEntry_0_bits_status_fuType_28),
    .io_deqEntry_0_bits_status_fuType_29                         (entries_io_deqEntry_0_bits_status_fuType_29),
    .io_deqEntry_0_bits_status_srcStatus_0_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_0_psrc),
    .io_deqEntry_0_bits_status_srcStatus_0_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_0_srcType),
    .io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx           (entries_io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx),
    .io_deqEntry_0_bits_status_srcStatus_1_psrc                  (entries_io_deqEntry_0_bits_status_srcStatus_1_psrc),
    .io_deqEntry_0_bits_status_srcStatus_1_srcType               (entries_io_deqEntry_0_bits_status_srcStatus_1_srcType),
    .io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx           (entries_io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx),
    .io_deqEntry_0_bits_imm                                      (entries_io_deqEntry_0_bits_imm),
    .io_deqEntry_0_bits_payload_fuOpType                         (entries_io_deqEntry_0_bits_payload_fuOpType),
    .io_deqEntry_0_bits_payload_rfWen                            (entries_io_deqEntry_0_bits_payload_rfWen),
    .io_deqEntry_0_bits_payload_selImm                           (entries_io_deqEntry_0_bits_payload_selImm),
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
    .io_deqEntry_1_bits_status_fuType_0                          (entries_io_deqEntry_1_bits_status_fuType_0),
    .io_deqEntry_1_bits_status_fuType_1                          (entries_io_deqEntry_1_bits_status_fuType_1),
    .io_deqEntry_1_bits_status_fuType_2                          (entries_io_deqEntry_1_bits_status_fuType_2),
    .io_deqEntry_1_bits_status_fuType_3                          (entries_io_deqEntry_1_bits_status_fuType_3),
    .io_deqEntry_1_bits_status_fuType_6                          (entries_io_deqEntry_1_bits_status_fuType_6),
    .io_deqEntry_1_bits_status_fuType_28                         (entries_io_deqEntry_1_bits_status_fuType_28),
    .io_deqEntry_1_bits_status_fuType_29                         (entries_io_deqEntry_1_bits_status_fuType_29),
    .io_deqEntry_1_bits_status_srcStatus_0_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_0_psrc),
    .io_deqEntry_1_bits_status_srcStatus_0_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_0_srcType),
    .io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx           (entries_io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx),
    .io_deqEntry_1_bits_status_srcStatus_1_psrc                  (entries_io_deqEntry_1_bits_status_srcStatus_1_psrc),
    .io_deqEntry_1_bits_status_srcStatus_1_srcType               (entries_io_deqEntry_1_bits_status_srcStatus_1_srcType),
    .io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx           (entries_io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx),
    .io_deqEntry_1_bits_imm                                      (entries_io_deqEntry_1_bits_imm),
    .io_deqEntry_1_bits_payload_preDecodeInfo_valid              (entries_io_deqEntry_1_bits_payload_preDecodeInfo_valid),
    .io_deqEntry_1_bits_payload_preDecodeInfo_isRVC              (entries_io_deqEntry_1_bits_payload_preDecodeInfo_isRVC),
    .io_deqEntry_1_bits_payload_preDecodeInfo_brType             (entries_io_deqEntry_1_bits_payload_preDecodeInfo_brType),
    .io_deqEntry_1_bits_payload_preDecodeInfo_isCall             (entries_io_deqEntry_1_bits_payload_preDecodeInfo_isCall),
    .io_deqEntry_1_bits_payload_preDecodeInfo_isRet              (entries_io_deqEntry_1_bits_payload_preDecodeInfo_isRet),
    .io_deqEntry_1_bits_payload_pred_taken                       (entries_io_deqEntry_1_bits_payload_pred_taken),
    .io_deqEntry_1_bits_payload_ftqPtr_flag                      (entries_io_deqEntry_1_bits_payload_ftqPtr_flag),
    .io_deqEntry_1_bits_payload_ftqPtr_value                     (entries_io_deqEntry_1_bits_payload_ftqPtr_value),
    .io_deqEntry_1_bits_payload_ftqOffset                        (entries_io_deqEntry_1_bits_payload_ftqOffset),
    .io_deqEntry_1_bits_payload_fuOpType                         (entries_io_deqEntry_1_bits_payload_fuOpType),
    .io_deqEntry_1_bits_payload_rfWen                            (entries_io_deqEntry_1_bits_payload_rfWen),
    .io_deqEntry_1_bits_payload_fpWen                            (entries_io_deqEntry_1_bits_payload_fpWen),
    .io_deqEntry_1_bits_payload_vecWen                           (entries_io_deqEntry_1_bits_payload_vecWen),
    .io_deqEntry_1_bits_payload_v0Wen                            (entries_io_deqEntry_1_bits_payload_v0Wen),
    .io_deqEntry_1_bits_payload_vlWen                            (entries_io_deqEntry_1_bits_payload_vlWen),
    .io_deqEntry_1_bits_payload_selImm                           (entries_io_deqEntry_1_bits_payload_selImm),
    .io_deqEntry_1_bits_payload_fpu_typeTagOut                   (entries_io_deqEntry_1_bits_payload_fpu_typeTagOut),
    .io_deqEntry_1_bits_payload_fpu_wflags                       (entries_io_deqEntry_1_bits_payload_fpu_wflags),
    .io_deqEntry_1_bits_payload_fpu_typ                          (entries_io_deqEntry_1_bits_payload_fpu_typ),
    .io_deqEntry_1_bits_payload_fpu_fmt                          (entries_io_deqEntry_1_bits_payload_fpu_fmt),
    .io_deqEntry_1_bits_payload_fpu_rm                           (entries_io_deqEntry_1_bits_payload_fpu_rm),
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
    .io_cancelDeqVec_0                                           (entries_io_cancelDeqVec_0),
    .io_cancelDeqVec_1                                           (entries_io_cancelDeqVec_1),
    .io_simpEntryDeqSelVec_0                                     (age_1_io_out_2),
    .io_simpEntryDeqSelVec_1                                     (age_1_io_out_3),
    .io_simpEntryEnqSelVec_0                                     (entries_io_simpEntryEnqSelVec_0),
    .io_simpEntryEnqSelVec_1                                     (entries_io_simpEntryEnqSelVec_1),
    .io_compEntryEnqSelVec_0                                     (entries_io_compEntryEnqSelVec_0),
    .io_compEntryEnqSelVec_1                                     (entries_io_compEntryEnqSelVec_1)
  );

  FuBusyTableWrite_22 fuBusyTableWrite_1 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_valid[1]),
    .io_in_deqResp_bits_fuType ({5'h0, entries_io_deqEntry_1_bits_status_fuType_29, entries_io_deqEntry_1_bits_status_fuType_28, 21'h0, entries_io_deqEntry_1_bits_status_fuType_6, 2'h0, entries_io_deqEntry_1_bits_status_fuType_3, entries_io_deqEntry_1_bits_status_fuType_2, entries_io_deqEntry_1_bits_status_fuType_1, entries_io_deqEntry_1_bits_status_fuType_0}),
    .io_in_og0Resp_valid       (io_og0Resp_1_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_1_bits_fuType),
    .io_out_fuBusyTable        (fuBusyTableWrite_1_io_out_fuBusyTable)
  );

  FuBusyTableRead_22 fuBusyTableRead_1 (
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
    .io_in_fuTypeRegVec_16  (entries_io_fuType_16),
    .io_in_fuTypeRegVec_17  (entries_io_fuType_17),
    .io_in_fuTypeRegVec_18  (entries_io_fuType_18),
    .io_in_fuTypeRegVec_19  (entries_io_fuType_19),
    .io_in_fuTypeRegVec_20  (entries_io_fuType_20),
    .io_in_fuTypeRegVec_21  (entries_io_fuType_21),
    .io_in_fuTypeRegVec_22  (entries_io_fuType_22),
    .io_in_fuTypeRegVec_23  (entries_io_fuType_23),
    .io_out_fuBusyTableMask (fuBusyTableRead_1_io_out_fuBusyTableMask)
  );

  FuBusyTableRead_23 intWbBusyTableRead_0 (
    .io_in_fuBusyTable      (io_wbBusyTableRead_0_intWbBusyTable),
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
    .io_in_fuTypeRegVec_16  (entries_io_fuType_16),
    .io_in_fuTypeRegVec_17  (entries_io_fuType_17),
    .io_in_fuTypeRegVec_18  (entries_io_fuType_18),
    .io_in_fuTypeRegVec_19  (entries_io_fuType_19),
    .io_in_fuTypeRegVec_20  (entries_io_fuType_20),
    .io_in_fuTypeRegVec_21  (entries_io_fuType_21),
    .io_in_fuTypeRegVec_22  (entries_io_fuType_22),
    .io_in_fuTypeRegVec_23  (entries_io_fuType_23),
    .io_out_fuBusyTableMask (intWbBusyTableRead_0_io_out_fuBusyTableMask)
  );

  FuBusyTableWrite_26 fpWbBusyTableWrite_1 (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_deqResp_valid       (core_deq_wen_valid[1][1]),
    .io_in_deqResp_bits_fuType ({5'h0, entries_io_deqEntry_1_bits_status_fuType_29, entries_io_deqEntry_1_bits_status_fuType_28, 21'h0, entries_io_deqEntry_1_bits_status_fuType_6, 2'h0, entries_io_deqEntry_1_bits_status_fuType_3, entries_io_deqEntry_1_bits_status_fuType_2, entries_io_deqEntry_1_bits_status_fuType_1, entries_io_deqEntry_1_bits_status_fuType_0}),
    .io_in_og0Resp_valid       (io_og0Resp_1_valid),
    .io_in_og0Resp_bits_fuType (io_og0Resp_1_bits_fuType),
    .io_out_fuBusyTable        (io_wbBusyTableWrite_1_fpWbBusyTable)
  );

  FuBusyTableRead_26 fpWbBusyTableRead_1 (
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
    .io_in_fuTypeRegVec_16  (entries_io_fuType_16),
    .io_in_fuTypeRegVec_17  (entries_io_fuType_17),
    .io_in_fuTypeRegVec_18  (entries_io_fuType_18),
    .io_in_fuTypeRegVec_19  (entries_io_fuType_19),
    .io_in_fuTypeRegVec_20  (entries_io_fuType_20),
    .io_in_fuTypeRegVec_21  (entries_io_fuType_21),
    .io_in_fuTypeRegVec_22  (entries_io_fuType_22),
    .io_in_fuTypeRegVec_23  (entries_io_fuType_23),
    .io_out_fuBusyTableMask (fpWbBusyTableRead_1_io_out_fuBusyTableMask)
  );

  FuBusyTableRead_28 vfWbBusyTableRead_1 (
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
    .io_in_fuTypeRegVec_16  (entries_io_fuType_16),
    .io_in_fuTypeRegVec_17  (entries_io_fuType_17),
    .io_in_fuTypeRegVec_18  (entries_io_fuType_18),
    .io_in_fuTypeRegVec_19  (entries_io_fuType_19),
    .io_in_fuTypeRegVec_20  (entries_io_fuType_20),
    .io_in_fuTypeRegVec_21  (entries_io_fuType_21),
    .io_in_fuTypeRegVec_22  (entries_io_fuType_22),
    .io_in_fuTypeRegVec_23  (entries_io_fuType_23),
    .io_out_fuBusyTableMask (vfWbBusyTableRead_1_io_out_fuBusyTableMask)
  );

  FuBusyTableRead_28 v0WbBusyTableRead_1 (
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
    .io_in_fuTypeRegVec_16  (entries_io_fuType_16),
    .io_in_fuTypeRegVec_17  (entries_io_fuType_17),
    .io_in_fuTypeRegVec_18  (entries_io_fuType_18),
    .io_in_fuTypeRegVec_19  (entries_io_fuType_19),
    .io_in_fuTypeRegVec_20  (entries_io_fuType_20),
    .io_in_fuTypeRegVec_21  (entries_io_fuType_21),
    .io_in_fuTypeRegVec_22  (entries_io_fuType_22),
    .io_in_fuTypeRegVec_23  (entries_io_fuType_23),
    .io_out_fuBusyTableMask (v0WbBusyTableRead_1_io_out_fuBusyTableMask)
  );

  MultiWakeupQueue_2 wakeUpQueues_0 (
    .clock                              (clock),
    .io_enq_valid                       (core_deq_valid[0]),
    .io_enq_bits_uop_fuType             ({5'h0, entries_io_deqEntry_0_bits_status_fuType_29, entries_io_deqEntry_0_bits_status_fuType_28, 21'h0, entries_io_deqEntry_0_bits_status_fuType_6, 2'h0, entries_io_deqEntry_0_bits_status_fuType_3, entries_io_deqEntry_0_bits_status_fuType_2, entries_io_deqEntry_0_bits_status_fuType_1, entries_io_deqEntry_0_bits_status_fuType_0}),
    .io_enq_bits_uop_pdest              (entries_io_deqEntry_0_bits_payload_pdest),
    .io_enq_bits_uop_rfWen              (entries_io_deqEntry_0_bits_payload_rfWen),
    .io_enq_bits_uop_loadDependency_0   (core_deq_ld_dep[0][0]),
    .io_enq_bits_uop_loadDependency_1   (core_deq_ld_dep[0][1]),
    .io_enq_bits_uop_loadDependency_2   (core_deq_ld_dep[0][2]),
    .io_deq_valid                       (wakeUpQueues_0_io_deq_valid),
    .io_deq_bits_pdestCopy_0            (io_wakeupToIQ_0_bits_pdestCopy_0),
    .io_deq_bits_pdestCopy_1            (io_wakeupToIQ_0_bits_pdestCopy_1),
    .io_deq_bits_pdestCopy_2            (io_wakeupToIQ_0_bits_pdestCopy_2),
    .io_deq_bits_pdestCopy_3            (io_wakeupToIQ_0_bits_pdestCopy_3),
    .io_deq_bits_pdestCopy_4            (io_wakeupToIQ_0_bits_pdestCopy_4),
    .io_deq_bits_pdestCopy_5            (io_wakeupToIQ_0_bits_pdestCopy_5),
    .io_deq_bits_rfWenCopy_0            (io_wakeupToIQ_0_bits_rfWenCopy_0),
    .io_deq_bits_rfWenCopy_1            (io_wakeupToIQ_0_bits_rfWenCopy_1),
    .io_deq_bits_rfWenCopy_2            (io_wakeupToIQ_0_bits_rfWenCopy_2),
    .io_deq_bits_rfWenCopy_3            (io_wakeupToIQ_0_bits_rfWenCopy_3),
    .io_deq_bits_rfWenCopy_4            (io_wakeupToIQ_0_bits_rfWenCopy_4),
    .io_deq_bits_rfWenCopy_5            (io_wakeupToIQ_0_bits_rfWenCopy_5),
    .io_deq_bits_loadDependencyCopy_0_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_0_0),
    .io_deq_bits_loadDependencyCopy_0_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_0_1),
    .io_deq_bits_loadDependencyCopy_0_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_0_2),
    .io_deq_bits_loadDependencyCopy_1_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_1_0),
    .io_deq_bits_loadDependencyCopy_1_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_1_1),
    .io_deq_bits_loadDependencyCopy_1_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_1_2),
    .io_deq_bits_loadDependencyCopy_2_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_2_0),
    .io_deq_bits_loadDependencyCopy_2_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_2_1),
    .io_deq_bits_loadDependencyCopy_2_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_2_2),
    .io_deq_bits_loadDependencyCopy_3_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_3_0),
    .io_deq_bits_loadDependencyCopy_3_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_3_1),
    .io_deq_bits_loadDependencyCopy_3_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_3_2),
    .io_deq_bits_loadDependencyCopy_4_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_4_0),
    .io_deq_bits_loadDependencyCopy_4_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_4_1),
    .io_deq_bits_loadDependencyCopy_4_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_4_2),
    .io_deq_bits_loadDependencyCopy_5_0 (io_wakeupToIQ_0_bits_loadDependencyCopy_5_0),
    .io_deq_bits_loadDependencyCopy_5_1 (io_wakeupToIQ_0_bits_loadDependencyCopy_5_1),
    .io_deq_bits_loadDependencyCopy_5_2 (io_wakeupToIQ_0_bits_loadDependencyCopy_5_2),
    .io_deq_bits_pdest                  (io_wakeupToIQ_0_bits_pdest),
    .io_deq_bits_rfWen                  (wakeUpQueues_0_io_deq_bits_rfWen),
    .io_deq_bits_loadDependency_0       (io_wakeupToIQ_0_bits_loadDependency_0),
    .io_deq_bits_loadDependency_1       (io_wakeupToIQ_0_bits_loadDependency_1),
    .io_deq_bits_loadDependency_2       (io_wakeupToIQ_0_bits_loadDependency_2)
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

  AgeDetector age_1 (
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

  AgeDetector_1 age_2 (
    .clock         (clock),
    .reset         (reset),
    .io_enq_0      (entries_io_compEntryEnqSelVec_0),
    .io_enq_1      (entries_io_compEntryEnqSelVec_1),
    .io_canIssue_0 (core_age_comp_req[0]),
    .io_canIssue_1 (core_age_comp_req[1]),
    .io_out_0      (age_2_io_out_0),
    .io_out_1      (age_2_io_out_1)
  );

  assign core_wk_enq_fu_type = {5'h0, entries_io_deqEntry_0_bits_status_fuType_29, entries_io_deqEntry_0_bits_status_fuType_28, 21'h0, entries_io_deqEntry_0_bits_status_fuType_6, 2'h0, entries_io_deqEntry_0_bits_status_fuType_3, entries_io_deqEntry_0_bits_status_fuType_2, entries_io_deqEntry_0_bits_status_fuType_1, entries_io_deqEntry_0_bits_status_fuType_0};
  assign core_wk_deq_valid = wakeUpQueues_0_io_deq_valid;
  assign core_wk_deq_fu_type = '0;
  assign core_wk_deq_wen = {1'h0, 1'h0, 1'h0, 1'h0, wakeUpQueues_0_io_deq_bits_rfWen};   // {vl, v0, vec, fp, rf}
  assign core_wk_og1_valid = io_og1Resp_0_valid;
  assign core_wk_og1_resp = io_og1Resp_0_bits_resp;

  xs_IssueQueue_core #(
    .N_ENTRIES (24),
    .N_ENQ     (2),
    .N_SIMP    (6),
    .N_COMP    (16),
    .N_DEQ     (2),
    .N_SRC     (2),
    .PSRC_W    (8),
    .LD_CNT    (3),
    .N_EXU     (2),
    .EXU_W     (3),
    .N_BUSY    (4),
    .ACCEPT    ('{35'h40, 35'h3000000F}),
    .IQIDX_W   (4),
    .HAS_VCNT  ('{1'b1, 1'b1}),
    .VCNT_OUT_W(5),
    .W0        (994),
    .W1        (1131),
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
  assign io_wakeupToIQ_0_valid = wakeUpQueues_0_io_deq_valid;
  assign io_wakeupToIQ_0_bits_rfWen = core_wk_out_wen[0];
  assign io_wakeupToIQ_0_bits_rcDest = io_replaceRCIdx_0;
  assign io_validCntDeqVec_0 = core_valid_cnt[0];
  assign io_validCntDeqVec_1 = core_valid_cnt[1];
  assign io_deqDelay_1_valid = core_dly_valid[1];
  assign io_deqDelay_1_bits_rf_1_0_addr = dly1_bits_rf_1_0_addr;
  assign io_deqDelay_1_bits_rf_1_0_srcType = dly1_bits_rf_1_0_srcType;
  assign io_deqDelay_1_bits_rf_0_0_addr = dly1_bits_rf_0_0_addr;
  assign io_deqDelay_1_bits_rf_0_0_srcType = dly1_bits_rf_0_0_srcType;
  assign io_deqDelay_1_bits_srcType_0 = dly1_bits_srcType_0;
  assign io_deqDelay_1_bits_srcType_1 = dly1_bits_srcType_1;
  assign io_deqDelay_1_bits_rcIdx_0 = dly1_bits_rcIdx_0;
  assign io_deqDelay_1_bits_rcIdx_1 = dly1_bits_rcIdx_1;
  assign io_deqDelay_1_bits_immType = dly1_bits_immType;
  assign io_deqDelay_1_bits_common_fuType = dly1_bits_common_fuType;
  assign io_deqDelay_1_bits_common_fuOpType = dly1_bits_common_fuOpType;
  assign io_deqDelay_1_bits_common_src_0 = dly1_bits_common_src_0;
  assign io_deqDelay_1_bits_common_src_1 = dly1_bits_common_src_1;
  assign io_deqDelay_1_bits_common_imm = dly1_bits_common_imm;
  assign io_deqDelay_1_bits_common_nextPcOffset = dly1_bits_common_nextPcOffset;
  assign io_deqDelay_1_bits_common_robIdx_flag = dly1_bits_common_robIdx_flag;
  assign io_deqDelay_1_bits_common_robIdx_value = dly1_bits_common_robIdx_value;
  assign io_deqDelay_1_bits_common_iqIdx = dly1_bits_common_iqIdx;
  assign io_deqDelay_1_bits_common_isFirstIssue = dly1_bits_common_isFirstIssue;
  assign io_deqDelay_1_bits_common_pdest = dly1_bits_common_pdest;
  assign io_deqDelay_1_bits_common_rfWen = dly1_bits_common_rfWen;
  assign io_deqDelay_1_bits_common_fpWen = dly1_bits_common_fpWen;
  assign io_deqDelay_1_bits_common_vecWen = dly1_bits_common_vecWen;
  assign io_deqDelay_1_bits_common_v0Wen = dly1_bits_common_v0Wen;
  assign io_deqDelay_1_bits_common_vlWen = dly1_bits_common_vlWen;
  assign io_deqDelay_1_bits_common_fpu_typeTagOut = dly1_bits_common_fpu_typeTagOut;
  assign io_deqDelay_1_bits_common_fpu_wflags = dly1_bits_common_fpu_wflags;
  assign io_deqDelay_1_bits_common_fpu_typ = dly1_bits_common_fpu_typ;
  assign io_deqDelay_1_bits_common_fpu_fmt = dly1_bits_common_fpu_fmt;
  assign io_deqDelay_1_bits_common_fpu_rm = dly1_bits_common_fpu_rm;
  assign io_deqDelay_1_bits_common_pc = dly1_bits_common_pc;
  assign io_deqDelay_1_bits_common_preDecode_valid = dly1_bits_common_preDecode_valid;
  assign io_deqDelay_1_bits_common_preDecode_isRVC = dly1_bits_common_preDecode_isRVC;
  assign io_deqDelay_1_bits_common_preDecode_brType = dly1_bits_common_preDecode_brType;
  assign io_deqDelay_1_bits_common_preDecode_isCall = dly1_bits_common_preDecode_isCall;
  assign io_deqDelay_1_bits_common_preDecode_isRet = dly1_bits_common_preDecode_isRet;
  assign io_deqDelay_1_bits_common_ftqIdx_flag = dly1_bits_common_ftqIdx_flag;
  assign io_deqDelay_1_bits_common_ftqIdx_value = dly1_bits_common_ftqIdx_value;
  assign io_deqDelay_1_bits_common_ftqOffset = dly1_bits_common_ftqOffset;
  assign io_deqDelay_1_bits_common_predictInfo_target = dly1_bits_common_predictInfo_target;
  assign io_deqDelay_1_bits_common_predictInfo_taken = dly1_bits_common_predictInfo_taken;
  assign io_deqDelay_1_bits_common_dataSources_0_value = dly1_bits_common_dataSources_0_value;
  assign io_deqDelay_1_bits_common_dataSources_1_value = dly1_bits_common_dataSources_1_value;
  assign io_deqDelay_1_bits_common_exuSources_0_value = dly1_bits_common_exuSources_0_value;
  assign io_deqDelay_1_bits_common_exuSources_1_value = dly1_bits_common_exuSources_1_value;
  assign io_deqDelay_1_bits_common_srcTimer_0 = dly1_bits_common_srcTimer_0;
  assign io_deqDelay_1_bits_common_srcTimer_1 = dly1_bits_common_srcTimer_1;
  assign io_deqDelay_1_bits_common_loadDependency_0 = dly1_bits_common_loadDependency_0;
  assign io_deqDelay_1_bits_common_loadDependency_1 = dly1_bits_common_loadDependency_1;
  assign io_deqDelay_1_bits_common_loadDependency_2 = dly1_bits_common_loadDependency_2;
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
  assign io_deqDelay_0_bits_rf_1_0_addr = dly0_bits_rf_1_0_addr;
  assign io_deqDelay_0_bits_rf_1_0_srcType = dly0_bits_rf_1_0_srcType;
  assign io_deqDelay_0_bits_rf_0_0_addr = dly0_bits_rf_0_0_addr;
  assign io_deqDelay_0_bits_rf_0_0_srcType = dly0_bits_rf_0_0_srcType;
  assign io_deqDelay_0_bits_srcType_0 = dly0_bits_srcType_0;
  assign io_deqDelay_0_bits_srcType_1 = dly0_bits_srcType_1;
  assign io_deqDelay_0_bits_rcIdx_0 = dly0_bits_rcIdx_0;
  assign io_deqDelay_0_bits_rcIdx_1 = dly0_bits_rcIdx_1;
  assign io_deqDelay_0_bits_immType = dly0_bits_immType;
  assign io_deqDelay_0_bits_common_fuType = dly0_bits_common_fuType;
  assign io_deqDelay_0_bits_common_fuOpType = dly0_bits_common_fuOpType;
  assign io_deqDelay_0_bits_common_src_0 = dly0_bits_common_src_0;
  assign io_deqDelay_0_bits_common_src_1 = dly0_bits_common_src_1;
  assign io_deqDelay_0_bits_common_imm = dly0_bits_common_imm;
  assign io_deqDelay_0_bits_common_robIdx_flag = dly0_bits_common_robIdx_flag;
  assign io_deqDelay_0_bits_common_robIdx_value = dly0_bits_common_robIdx_value;
  assign io_deqDelay_0_bits_common_iqIdx = dly0_bits_common_iqIdx;
  assign io_deqDelay_0_bits_common_isFirstIssue = dly0_bits_common_isFirstIssue;
  assign io_deqDelay_0_bits_common_pdest = dly0_bits_common_pdest;
  assign io_deqDelay_0_bits_common_rfWen = dly0_bits_common_rfWen;
  assign io_deqDelay_0_bits_common_dataSources_0_value = dly0_bits_common_dataSources_0_value;
  assign io_deqDelay_0_bits_common_dataSources_1_value = dly0_bits_common_dataSources_1_value;
  assign io_deqDelay_0_bits_common_exuSources_0_value = dly0_bits_common_exuSources_0_value;
  assign io_deqDelay_0_bits_common_exuSources_1_value = dly0_bits_common_exuSources_1_value;
  assign io_deqDelay_0_bits_common_srcTimer_0 = dly0_bits_common_srcTimer_0;
  assign io_deqDelay_0_bits_common_srcTimer_1 = dly0_bits_common_srcTimer_1;
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
