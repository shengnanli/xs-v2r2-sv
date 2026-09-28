// =============================================================================
// PipelineRegModule_1 —— LoadQueueUncache -> load 流水线的 MMIO 写回出口（io.mmioOut(2)）
//
// PipelineRegModule 家族的薄 wrapper：逻辑全部在共用核 xs_PipelineRegModule_core
// （rtl/memblock/PipelineRegModule.sv，含机制说明）。本变体 payload = 182 个字段 / 1428 位。
// 本层只做端口展平：golden 的 io_in_bits_* / io_out_bits_* 与核的一根 W 位向量互转。
// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_pipelinereg.py —— 勿手改
// =============================================================================

module PipelineRegModule_1(
  input          clock,
  input          reset,
  output         io_in_ready,
  input          io_in_valid,
  input  [31:0]  io_in_bits_uop_instr,
  input  [49:0]  io_in_bits_uop_pc,
  input  [9:0]   io_in_bits_uop_foldpc,
  input          io_in_bits_uop_exceptionVec_0,
  input          io_in_bits_uop_exceptionVec_1,
  input          io_in_bits_uop_exceptionVec_2,
  input          io_in_bits_uop_exceptionVec_3,
  input          io_in_bits_uop_exceptionVec_4,
  input          io_in_bits_uop_exceptionVec_5,
  input          io_in_bits_uop_exceptionVec_6,
  input          io_in_bits_uop_exceptionVec_7,
  input          io_in_bits_uop_exceptionVec_8,
  input          io_in_bits_uop_exceptionVec_9,
  input          io_in_bits_uop_exceptionVec_10,
  input          io_in_bits_uop_exceptionVec_11,
  input          io_in_bits_uop_exceptionVec_12,
  input          io_in_bits_uop_exceptionVec_13,
  input          io_in_bits_uop_exceptionVec_14,
  input          io_in_bits_uop_exceptionVec_15,
  input          io_in_bits_uop_exceptionVec_16,
  input          io_in_bits_uop_exceptionVec_17,
  input          io_in_bits_uop_exceptionVec_18,
  input          io_in_bits_uop_exceptionVec_19,
  input          io_in_bits_uop_exceptionVec_20,
  input          io_in_bits_uop_exceptionVec_21,
  input          io_in_bits_uop_exceptionVec_22,
  input          io_in_bits_uop_exceptionVec_23,
  input          io_in_bits_uop_isFetchMalAddr,
  input          io_in_bits_uop_hasException,
  input  [3:0]   io_in_bits_uop_trigger,
  input          io_in_bits_uop_preDecodeInfo_valid,
  input          io_in_bits_uop_preDecodeInfo_isRVC,
  input  [1:0]   io_in_bits_uop_preDecodeInfo_brType,
  input          io_in_bits_uop_preDecodeInfo_isCall,
  input          io_in_bits_uop_preDecodeInfo_isRet,
  input          io_in_bits_uop_pred_taken,
  input          io_in_bits_uop_crossPageIPFFix,
  input          io_in_bits_uop_ftqPtr_flag,
  input  [5:0]   io_in_bits_uop_ftqPtr_value,
  input  [3:0]   io_in_bits_uop_ftqOffset,
  input          io_in_bits_uop_satpFlushFirstFetchFault,
  input  [3:0]   io_in_bits_uop_srcType_0,
  input  [3:0]   io_in_bits_uop_srcType_1,
  input  [3:0]   io_in_bits_uop_srcType_2,
  input  [3:0]   io_in_bits_uop_srcType_3,
  input  [3:0]   io_in_bits_uop_srcType_4,
  input  [5:0]   io_in_bits_uop_ldest,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_rfWen,
  input          io_in_bits_uop_fpWen,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
  input          io_in_bits_uop_isXSTrap,
  input          io_in_bits_uop_waitForward,
  input          io_in_bits_uop_blockBackward,
  input          io_in_bits_uop_flushPipe,
  input          io_in_bits_uop_canRobCompress,
  input  [3:0]   io_in_bits_uop_selImm,
  input  [31:0]  io_in_bits_uop_imm,
  input  [1:0]   io_in_bits_uop_fpu_typeTagOut,
  input          io_in_bits_uop_fpu_wflags,
  input  [1:0]   io_in_bits_uop_fpu_typ,
  input  [1:0]   io_in_bits_uop_fpu_fmt,
  input  [2:0]   io_in_bits_uop_fpu_rm,
  input          io_in_bits_uop_vpu_vill,
  input          io_in_bits_uop_vpu_vma,
  input          io_in_bits_uop_vpu_vta,
  input  [1:0]   io_in_bits_uop_vpu_vsew,
  input  [2:0]   io_in_bits_uop_vpu_vlmul,
  input          io_in_bits_uop_vpu_specVill,
  input          io_in_bits_uop_vpu_specVma,
  input          io_in_bits_uop_vpu_specVta,
  input  [1:0]   io_in_bits_uop_vpu_specVsew,
  input  [2:0]   io_in_bits_uop_vpu_specVlmul,
  input          io_in_bits_uop_vpu_vm,
  input  [7:0]   io_in_bits_uop_vpu_vstart,
  input  [2:0]   io_in_bits_uop_vpu_frm,
  input          io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input          io_in_bits_uop_vpu_fpu_isFP32Instr,
  input          io_in_bits_uop_vpu_fpu_isFP64Instr,
  input          io_in_bits_uop_vpu_fpu_isReduction,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_in_bits_uop_vpu_vxrm,
  input  [6:0]   io_in_bits_uop_vpu_vuopIdx,
  input          io_in_bits_uop_vpu_lastUop,
  input  [127:0] io_in_bits_uop_vpu_vmask,
  input  [7:0]   io_in_bits_uop_vpu_vl,
  input  [2:0]   io_in_bits_uop_vpu_nf,
  input  [1:0]   io_in_bits_uop_vpu_veew,
  input          io_in_bits_uop_vpu_isReverse,
  input          io_in_bits_uop_vpu_isExt,
  input          io_in_bits_uop_vpu_isNarrow,
  input          io_in_bits_uop_vpu_isDstMask,
  input          io_in_bits_uop_vpu_isOpMask,
  input          io_in_bits_uop_vpu_isMove,
  input          io_in_bits_uop_vpu_isDependOldVd,
  input          io_in_bits_uop_vpu_isWritePartVd,
  input          io_in_bits_uop_vpu_isVleff,
  input          io_in_bits_uop_vlsInstr,
  input          io_in_bits_uop_wfflags,
  input          io_in_bits_uop_isMove,
  input          io_in_bits_uop_isDropAmocasSta,
  input  [6:0]   io_in_bits_uop_uopIdx,
  input          io_in_bits_uop_isVset,
  input          io_in_bits_uop_firstUop,
  input          io_in_bits_uop_lastUop,
  input  [6:0]   io_in_bits_uop_numUops,
  input  [6:0]   io_in_bits_uop_numWB,
  input  [2:0]   io_in_bits_uop_commitType,
  input          io_in_bits_uop_srcState_0,
  input          io_in_bits_uop_srcState_1,
  input          io_in_bits_uop_srcState_2,
  input          io_in_bits_uop_srcState_3,
  input          io_in_bits_uop_srcState_4,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_0_0,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_0_1,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_0_2,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_1_0,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_1_1,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_1_2,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_2_0,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_2_1,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_2_2,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_3_0,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_3_1,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_3_2,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_4_0,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_4_1,
  input  [1:0]   io_in_bits_uop_srcLoadDependency_4_2,
  input  [7:0]   io_in_bits_uop_psrc_0,
  input  [7:0]   io_in_bits_uop_psrc_1,
  input  [7:0]   io_in_bits_uop_psrc_2,
  input  [7:0]   io_in_bits_uop_psrc_3,
  input  [7:0]   io_in_bits_uop_psrc_4,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_useRegCache_0,
  input          io_in_bits_uop_useRegCache_1,
  input  [4:0]   io_in_bits_uop_regCacheIdx_0,
  input  [4:0]   io_in_bits_uop_regCacheIdx_1,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input  [2:0]   io_in_bits_uop_instrSize,
  input          io_in_bits_uop_dirtyFs,
  input          io_in_bits_uop_dirtyVs,
  input  [3:0]   io_in_bits_uop_traceBlockInPipe_itype,
  input  [3:0]   io_in_bits_uop_traceBlockInPipe_iretire,
  input          io_in_bits_uop_traceBlockInPipe_ilastsize,
  input          io_in_bits_uop_eliminatedMove,
  input          io_in_bits_uop_snapshot,
  input          io_in_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_uop_debugInfo_renameTime,
  input  [63:0]  io_in_bits_uop_debugInfo_dispatchTime,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input  [63:0]  io_in_bits_uop_debugInfo_writebackTime,
  input  [63:0]  io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_uop_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_uop_debug_seqNum_uopIdx,
  input          io_in_bits_uop_storeSetHit,
  input          io_in_bits_uop_waitForRobIdx_flag,
  input  [7:0]   io_in_bits_uop_waitForRobIdx_value,
  input          io_in_bits_uop_loadWaitBit,
  input          io_in_bits_uop_loadWaitStrict,
  input  [4:0]   io_in_bits_uop_ssid,
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input          io_in_bits_uop_singleStep,
  input          io_in_bits_uop_replayInst,
  input  [34:0]  io_in_bits_uop_debug_fuType,
  input          io_in_bits_uop_debug_sim_trig,
  input  [4:0]   io_in_bits_uop_numLsElem,
  input  [47:0]  io_in_bits_debug_paddr,
  input  [49:0]  io_in_bits_debug_vaddr,
  input          io_out_ready,
  output         io_out_valid,
  output [31:0]  io_out_bits_uop_instr,
  output [49:0]  io_out_bits_uop_pc,
  output [9:0]   io_out_bits_uop_foldpc,
  output         io_out_bits_uop_exceptionVec_0,
  output         io_out_bits_uop_exceptionVec_1,
  output         io_out_bits_uop_exceptionVec_2,
  output         io_out_bits_uop_exceptionVec_3,
  output         io_out_bits_uop_exceptionVec_4,
  output         io_out_bits_uop_exceptionVec_5,
  output         io_out_bits_uop_exceptionVec_6,
  output         io_out_bits_uop_exceptionVec_7,
  output         io_out_bits_uop_exceptionVec_8,
  output         io_out_bits_uop_exceptionVec_9,
  output         io_out_bits_uop_exceptionVec_10,
  output         io_out_bits_uop_exceptionVec_11,
  output         io_out_bits_uop_exceptionVec_12,
  output         io_out_bits_uop_exceptionVec_13,
  output         io_out_bits_uop_exceptionVec_14,
  output         io_out_bits_uop_exceptionVec_15,
  output         io_out_bits_uop_exceptionVec_16,
  output         io_out_bits_uop_exceptionVec_17,
  output         io_out_bits_uop_exceptionVec_18,
  output         io_out_bits_uop_exceptionVec_19,
  output         io_out_bits_uop_exceptionVec_20,
  output         io_out_bits_uop_exceptionVec_21,
  output         io_out_bits_uop_exceptionVec_22,
  output         io_out_bits_uop_exceptionVec_23,
  output         io_out_bits_uop_isFetchMalAddr,
  output         io_out_bits_uop_hasException,
  output [3:0]   io_out_bits_uop_trigger,
  output         io_out_bits_uop_preDecodeInfo_valid,
  output         io_out_bits_uop_preDecodeInfo_isRVC,
  output [1:0]   io_out_bits_uop_preDecodeInfo_brType,
  output         io_out_bits_uop_preDecodeInfo_isCall,
  output         io_out_bits_uop_preDecodeInfo_isRet,
  output         io_out_bits_uop_pred_taken,
  output         io_out_bits_uop_crossPageIPFFix,
  output         io_out_bits_uop_ftqPtr_flag,
  output [5:0]   io_out_bits_uop_ftqPtr_value,
  output [3:0]   io_out_bits_uop_ftqOffset,
  output         io_out_bits_uop_satpFlushFirstFetchFault,
  output [3:0]   io_out_bits_uop_srcType_0,
  output [3:0]   io_out_bits_uop_srcType_1,
  output [3:0]   io_out_bits_uop_srcType_2,
  output [3:0]   io_out_bits_uop_srcType_3,
  output [3:0]   io_out_bits_uop_srcType_4,
  output [5:0]   io_out_bits_uop_ldest,
  output [34:0]  io_out_bits_uop_fuType,
  output [8:0]   io_out_bits_uop_fuOpType,
  output         io_out_bits_uop_rfWen,
  output         io_out_bits_uop_fpWen,
  output         io_out_bits_uop_vecWen,
  output         io_out_bits_uop_v0Wen,
  output         io_out_bits_uop_vlWen,
  output         io_out_bits_uop_isXSTrap,
  output         io_out_bits_uop_waitForward,
  output         io_out_bits_uop_blockBackward,
  output         io_out_bits_uop_flushPipe,
  output         io_out_bits_uop_canRobCompress,
  output [3:0]   io_out_bits_uop_selImm,
  output [31:0]  io_out_bits_uop_imm,
  output [1:0]   io_out_bits_uop_fpu_typeTagOut,
  output         io_out_bits_uop_fpu_wflags,
  output [1:0]   io_out_bits_uop_fpu_typ,
  output [1:0]   io_out_bits_uop_fpu_fmt,
  output [2:0]   io_out_bits_uop_fpu_rm,
  output         io_out_bits_uop_vpu_vill,
  output         io_out_bits_uop_vpu_vma,
  output         io_out_bits_uop_vpu_vta,
  output [1:0]   io_out_bits_uop_vpu_vsew,
  output [2:0]   io_out_bits_uop_vpu_vlmul,
  output         io_out_bits_uop_vpu_specVill,
  output         io_out_bits_uop_vpu_specVma,
  output         io_out_bits_uop_vpu_specVta,
  output [1:0]   io_out_bits_uop_vpu_specVsew,
  output [2:0]   io_out_bits_uop_vpu_specVlmul,
  output         io_out_bits_uop_vpu_vm,
  output [7:0]   io_out_bits_uop_vpu_vstart,
  output [2:0]   io_out_bits_uop_vpu_frm,
  output         io_out_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_out_bits_uop_vpu_fpu_isFP32Instr,
  output         io_out_bits_uop_vpu_fpu_isFP64Instr,
  output         io_out_bits_uop_vpu_fpu_isReduction,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_out_bits_uop_vpu_vxrm,
  output [6:0]   io_out_bits_uop_vpu_vuopIdx,
  output         io_out_bits_uop_vpu_lastUop,
  output [127:0] io_out_bits_uop_vpu_vmask,
  output [7:0]   io_out_bits_uop_vpu_vl,
  output [2:0]   io_out_bits_uop_vpu_nf,
  output [1:0]   io_out_bits_uop_vpu_veew,
  output         io_out_bits_uop_vpu_isReverse,
  output         io_out_bits_uop_vpu_isExt,
  output         io_out_bits_uop_vpu_isNarrow,
  output         io_out_bits_uop_vpu_isDstMask,
  output         io_out_bits_uop_vpu_isOpMask,
  output         io_out_bits_uop_vpu_isMove,
  output         io_out_bits_uop_vpu_isDependOldVd,
  output         io_out_bits_uop_vpu_isWritePartVd,
  output         io_out_bits_uop_vpu_isVleff,
  output         io_out_bits_uop_vlsInstr,
  output         io_out_bits_uop_wfflags,
  output         io_out_bits_uop_isMove,
  output         io_out_bits_uop_isDropAmocasSta,
  output [6:0]   io_out_bits_uop_uopIdx,
  output         io_out_bits_uop_isVset,
  output         io_out_bits_uop_firstUop,
  output         io_out_bits_uop_lastUop,
  output [6:0]   io_out_bits_uop_numUops,
  output [6:0]   io_out_bits_uop_numWB,
  output [2:0]   io_out_bits_uop_commitType,
  output         io_out_bits_uop_srcState_0,
  output         io_out_bits_uop_srcState_1,
  output         io_out_bits_uop_srcState_2,
  output         io_out_bits_uop_srcState_3,
  output         io_out_bits_uop_srcState_4,
  output [1:0]   io_out_bits_uop_srcLoadDependency_0_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_0_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_0_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_1_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_1_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_1_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_2_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_2_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_2_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_3_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_3_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_3_2,
  output [1:0]   io_out_bits_uop_srcLoadDependency_4_0,
  output [1:0]   io_out_bits_uop_srcLoadDependency_4_1,
  output [1:0]   io_out_bits_uop_srcLoadDependency_4_2,
  output [7:0]   io_out_bits_uop_psrc_0,
  output [7:0]   io_out_bits_uop_psrc_1,
  output [7:0]   io_out_bits_uop_psrc_2,
  output [7:0]   io_out_bits_uop_psrc_3,
  output [7:0]   io_out_bits_uop_psrc_4,
  output [7:0]   io_out_bits_uop_pdest,
  output         io_out_bits_uop_useRegCache_0,
  output         io_out_bits_uop_useRegCache_1,
  output [4:0]   io_out_bits_uop_regCacheIdx_0,
  output [4:0]   io_out_bits_uop_regCacheIdx_1,
  output         io_out_bits_uop_robIdx_flag,
  output [7:0]   io_out_bits_uop_robIdx_value,
  output [2:0]   io_out_bits_uop_instrSize,
  output         io_out_bits_uop_dirtyFs,
  output         io_out_bits_uop_dirtyVs,
  output [3:0]   io_out_bits_uop_traceBlockInPipe_itype,
  output [3:0]   io_out_bits_uop_traceBlockInPipe_iretire,
  output         io_out_bits_uop_traceBlockInPipe_ilastsize,
  output         io_out_bits_uop_eliminatedMove,
  output         io_out_bits_uop_snapshot,
  output         io_out_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_out_bits_uop_debugInfo_renameTime,
  output [63:0]  io_out_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_uop_debugInfo_selectTime,
  output [63:0]  io_out_bits_uop_debugInfo_issueTime,
  output [63:0]  io_out_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_out_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_uop_debug_seqNum_uopIdx,
  output         io_out_bits_uop_storeSetHit,
  output         io_out_bits_uop_waitForRobIdx_flag,
  output [7:0]   io_out_bits_uop_waitForRobIdx_value,
  output         io_out_bits_uop_loadWaitBit,
  output         io_out_bits_uop_loadWaitStrict,
  output [4:0]   io_out_bits_uop_ssid,
  output         io_out_bits_uop_lqIdx_flag,
  output [6:0]   io_out_bits_uop_lqIdx_value,
  output         io_out_bits_uop_sqIdx_flag,
  output [5:0]   io_out_bits_uop_sqIdx_value,
  output         io_out_bits_uop_singleStep,
  output         io_out_bits_uop_replayInst,
  output [34:0]  io_out_bits_uop_debug_fuType,
  output         io_out_bits_uop_debug_sim_trig,
  output [4:0]   io_out_bits_uop_numLsElem,
  output [47:0]  io_out_bits_debug_paddr,
  output [49:0]  io_out_bits_debug_vaddr
);
  // payload = 182 个字段拼成 1428 位（字段顺序同 golden 端口表，第一个在最高位）
  localparam int W = 1428;
  logic [W-1:0] in_bits;
  logic [W-1:0] out_bits;

  assign in_bits = {
    io_in_bits_uop_instr,
    io_in_bits_uop_pc,
    io_in_bits_uop_foldpc,
    io_in_bits_uop_exceptionVec_0,
    io_in_bits_uop_exceptionVec_1,
    io_in_bits_uop_exceptionVec_2,
    io_in_bits_uop_exceptionVec_3,
    io_in_bits_uop_exceptionVec_4,
    io_in_bits_uop_exceptionVec_5,
    io_in_bits_uop_exceptionVec_6,
    io_in_bits_uop_exceptionVec_7,
    io_in_bits_uop_exceptionVec_8,
    io_in_bits_uop_exceptionVec_9,
    io_in_bits_uop_exceptionVec_10,
    io_in_bits_uop_exceptionVec_11,
    io_in_bits_uop_exceptionVec_12,
    io_in_bits_uop_exceptionVec_13,
    io_in_bits_uop_exceptionVec_14,
    io_in_bits_uop_exceptionVec_15,
    io_in_bits_uop_exceptionVec_16,
    io_in_bits_uop_exceptionVec_17,
    io_in_bits_uop_exceptionVec_18,
    io_in_bits_uop_exceptionVec_19,
    io_in_bits_uop_exceptionVec_20,
    io_in_bits_uop_exceptionVec_21,
    io_in_bits_uop_exceptionVec_22,
    io_in_bits_uop_exceptionVec_23,
    io_in_bits_uop_isFetchMalAddr,
    io_in_bits_uop_hasException,
    io_in_bits_uop_trigger,
    io_in_bits_uop_preDecodeInfo_valid,
    io_in_bits_uop_preDecodeInfo_isRVC,
    io_in_bits_uop_preDecodeInfo_brType,
    io_in_bits_uop_preDecodeInfo_isCall,
    io_in_bits_uop_preDecodeInfo_isRet,
    io_in_bits_uop_pred_taken,
    io_in_bits_uop_crossPageIPFFix,
    io_in_bits_uop_ftqPtr_flag,
    io_in_bits_uop_ftqPtr_value,
    io_in_bits_uop_ftqOffset,
    io_in_bits_uop_satpFlushFirstFetchFault,
    io_in_bits_uop_srcType_0,
    io_in_bits_uop_srcType_1,
    io_in_bits_uop_srcType_2,
    io_in_bits_uop_srcType_3,
    io_in_bits_uop_srcType_4,
    io_in_bits_uop_ldest,
    io_in_bits_uop_fuType,
    io_in_bits_uop_fuOpType,
    io_in_bits_uop_rfWen,
    io_in_bits_uop_fpWen,
    io_in_bits_uop_vecWen,
    io_in_bits_uop_v0Wen,
    io_in_bits_uop_vlWen,
    io_in_bits_uop_isXSTrap,
    io_in_bits_uop_waitForward,
    io_in_bits_uop_blockBackward,
    io_in_bits_uop_flushPipe,
    io_in_bits_uop_canRobCompress,
    io_in_bits_uop_selImm,
    io_in_bits_uop_imm,
    io_in_bits_uop_fpu_typeTagOut,
    io_in_bits_uop_fpu_wflags,
    io_in_bits_uop_fpu_typ,
    io_in_bits_uop_fpu_fmt,
    io_in_bits_uop_fpu_rm,
    io_in_bits_uop_vpu_vill,
    io_in_bits_uop_vpu_vma,
    io_in_bits_uop_vpu_vta,
    io_in_bits_uop_vpu_vsew,
    io_in_bits_uop_vpu_vlmul,
    io_in_bits_uop_vpu_specVill,
    io_in_bits_uop_vpu_specVma,
    io_in_bits_uop_vpu_specVta,
    io_in_bits_uop_vpu_specVsew,
    io_in_bits_uop_vpu_specVlmul,
    io_in_bits_uop_vpu_vm,
    io_in_bits_uop_vpu_vstart,
    io_in_bits_uop_vpu_frm,
    io_in_bits_uop_vpu_fpu_isFpToVecInst,
    io_in_bits_uop_vpu_fpu_isFP32Instr,
    io_in_bits_uop_vpu_fpu_isFP64Instr,
    io_in_bits_uop_vpu_fpu_isReduction,
    io_in_bits_uop_vpu_fpu_isFoldTo1_2,
    io_in_bits_uop_vpu_fpu_isFoldTo1_4,
    io_in_bits_uop_vpu_fpu_isFoldTo1_8,
    io_in_bits_uop_vpu_vxrm,
    io_in_bits_uop_vpu_vuopIdx,
    io_in_bits_uop_vpu_lastUop,
    io_in_bits_uop_vpu_vmask,
    io_in_bits_uop_vpu_vl,
    io_in_bits_uop_vpu_nf,
    io_in_bits_uop_vpu_veew,
    io_in_bits_uop_vpu_isReverse,
    io_in_bits_uop_vpu_isExt,
    io_in_bits_uop_vpu_isNarrow,
    io_in_bits_uop_vpu_isDstMask,
    io_in_bits_uop_vpu_isOpMask,
    io_in_bits_uop_vpu_isMove,
    io_in_bits_uop_vpu_isDependOldVd,
    io_in_bits_uop_vpu_isWritePartVd,
    io_in_bits_uop_vpu_isVleff,
    io_in_bits_uop_vlsInstr,
    io_in_bits_uop_wfflags,
    io_in_bits_uop_isMove,
    io_in_bits_uop_isDropAmocasSta,
    io_in_bits_uop_uopIdx,
    io_in_bits_uop_isVset,
    io_in_bits_uop_firstUop,
    io_in_bits_uop_lastUop,
    io_in_bits_uop_numUops,
    io_in_bits_uop_numWB,
    io_in_bits_uop_commitType,
    io_in_bits_uop_srcState_0,
    io_in_bits_uop_srcState_1,
    io_in_bits_uop_srcState_2,
    io_in_bits_uop_srcState_3,
    io_in_bits_uop_srcState_4,
    io_in_bits_uop_srcLoadDependency_0_0,
    io_in_bits_uop_srcLoadDependency_0_1,
    io_in_bits_uop_srcLoadDependency_0_2,
    io_in_bits_uop_srcLoadDependency_1_0,
    io_in_bits_uop_srcLoadDependency_1_1,
    io_in_bits_uop_srcLoadDependency_1_2,
    io_in_bits_uop_srcLoadDependency_2_0,
    io_in_bits_uop_srcLoadDependency_2_1,
    io_in_bits_uop_srcLoadDependency_2_2,
    io_in_bits_uop_srcLoadDependency_3_0,
    io_in_bits_uop_srcLoadDependency_3_1,
    io_in_bits_uop_srcLoadDependency_3_2,
    io_in_bits_uop_srcLoadDependency_4_0,
    io_in_bits_uop_srcLoadDependency_4_1,
    io_in_bits_uop_srcLoadDependency_4_2,
    io_in_bits_uop_psrc_0,
    io_in_bits_uop_psrc_1,
    io_in_bits_uop_psrc_2,
    io_in_bits_uop_psrc_3,
    io_in_bits_uop_psrc_4,
    io_in_bits_uop_pdest,
    io_in_bits_uop_useRegCache_0,
    io_in_bits_uop_useRegCache_1,
    io_in_bits_uop_regCacheIdx_0,
    io_in_bits_uop_regCacheIdx_1,
    io_in_bits_uop_robIdx_flag,
    io_in_bits_uop_robIdx_value,
    io_in_bits_uop_instrSize,
    io_in_bits_uop_dirtyFs,
    io_in_bits_uop_dirtyVs,
    io_in_bits_uop_traceBlockInPipe_itype,
    io_in_bits_uop_traceBlockInPipe_iretire,
    io_in_bits_uop_traceBlockInPipe_ilastsize,
    io_in_bits_uop_eliminatedMove,
    io_in_bits_uop_snapshot,
    io_in_bits_uop_debugInfo_eliminatedMove,
    io_in_bits_uop_debugInfo_renameTime,
    io_in_bits_uop_debugInfo_dispatchTime,
    io_in_bits_uop_debugInfo_enqRsTime,
    io_in_bits_uop_debugInfo_selectTime,
    io_in_bits_uop_debugInfo_issueTime,
    io_in_bits_uop_debugInfo_writebackTime,
    io_in_bits_uop_debugInfo_runahead_checkpoint_id,
    io_in_bits_uop_debugInfo_tlbFirstReqTime,
    io_in_bits_uop_debugInfo_tlbRespTime,
    io_in_bits_uop_debug_seqNum_seqNum,
    io_in_bits_uop_debug_seqNum_uopIdx,
    io_in_bits_uop_storeSetHit,
    io_in_bits_uop_waitForRobIdx_flag,
    io_in_bits_uop_waitForRobIdx_value,
    io_in_bits_uop_loadWaitBit,
    io_in_bits_uop_loadWaitStrict,
    io_in_bits_uop_ssid,
    io_in_bits_uop_lqIdx_flag,
    io_in_bits_uop_lqIdx_value,
    io_in_bits_uop_sqIdx_flag,
    io_in_bits_uop_sqIdx_value,
    io_in_bits_uop_singleStep,
    io_in_bits_uop_replayInst,
    io_in_bits_uop_debug_fuType,
    io_in_bits_uop_debug_sim_trig,
    io_in_bits_uop_numLsElem,
    io_in_bits_debug_paddr,
    io_in_bits_debug_vaddr
  };

  xs_PipelineRegModule_core #(.W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_ready  (io_in_ready),
    .in_valid  (io_in_valid),
    .in_bits   (in_bits),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_bits)
  );

  assign io_out_bits_uop_instr = out_bits[1427:1396];
  assign io_out_bits_uop_pc = out_bits[1395:1346];
  assign io_out_bits_uop_foldpc = out_bits[1345:1336];
  assign io_out_bits_uop_exceptionVec_0 = out_bits[1335];
  assign io_out_bits_uop_exceptionVec_1 = out_bits[1334];
  assign io_out_bits_uop_exceptionVec_2 = out_bits[1333];
  assign io_out_bits_uop_exceptionVec_3 = out_bits[1332];
  assign io_out_bits_uop_exceptionVec_4 = out_bits[1331];
  assign io_out_bits_uop_exceptionVec_5 = out_bits[1330];
  assign io_out_bits_uop_exceptionVec_6 = out_bits[1329];
  assign io_out_bits_uop_exceptionVec_7 = out_bits[1328];
  assign io_out_bits_uop_exceptionVec_8 = out_bits[1327];
  assign io_out_bits_uop_exceptionVec_9 = out_bits[1326];
  assign io_out_bits_uop_exceptionVec_10 = out_bits[1325];
  assign io_out_bits_uop_exceptionVec_11 = out_bits[1324];
  assign io_out_bits_uop_exceptionVec_12 = out_bits[1323];
  assign io_out_bits_uop_exceptionVec_13 = out_bits[1322];
  assign io_out_bits_uop_exceptionVec_14 = out_bits[1321];
  assign io_out_bits_uop_exceptionVec_15 = out_bits[1320];
  assign io_out_bits_uop_exceptionVec_16 = out_bits[1319];
  assign io_out_bits_uop_exceptionVec_17 = out_bits[1318];
  assign io_out_bits_uop_exceptionVec_18 = out_bits[1317];
  assign io_out_bits_uop_exceptionVec_19 = out_bits[1316];
  assign io_out_bits_uop_exceptionVec_20 = out_bits[1315];
  assign io_out_bits_uop_exceptionVec_21 = out_bits[1314];
  assign io_out_bits_uop_exceptionVec_22 = out_bits[1313];
  assign io_out_bits_uop_exceptionVec_23 = out_bits[1312];
  assign io_out_bits_uop_isFetchMalAddr = out_bits[1311];
  assign io_out_bits_uop_hasException = out_bits[1310];
  assign io_out_bits_uop_trigger = out_bits[1309:1306];
  assign io_out_bits_uop_preDecodeInfo_valid = out_bits[1305];
  assign io_out_bits_uop_preDecodeInfo_isRVC = out_bits[1304];
  assign io_out_bits_uop_preDecodeInfo_brType = out_bits[1303:1302];
  assign io_out_bits_uop_preDecodeInfo_isCall = out_bits[1301];
  assign io_out_bits_uop_preDecodeInfo_isRet = out_bits[1300];
  assign io_out_bits_uop_pred_taken = out_bits[1299];
  assign io_out_bits_uop_crossPageIPFFix = out_bits[1298];
  assign io_out_bits_uop_ftqPtr_flag = out_bits[1297];
  assign io_out_bits_uop_ftqPtr_value = out_bits[1296:1291];
  assign io_out_bits_uop_ftqOffset = out_bits[1290:1287];
  assign io_out_bits_uop_satpFlushFirstFetchFault = out_bits[1286];
  assign io_out_bits_uop_srcType_0 = out_bits[1285:1282];
  assign io_out_bits_uop_srcType_1 = out_bits[1281:1278];
  assign io_out_bits_uop_srcType_2 = out_bits[1277:1274];
  assign io_out_bits_uop_srcType_3 = out_bits[1273:1270];
  assign io_out_bits_uop_srcType_4 = out_bits[1269:1266];
  assign io_out_bits_uop_ldest = out_bits[1265:1260];
  assign io_out_bits_uop_fuType = out_bits[1259:1225];
  assign io_out_bits_uop_fuOpType = out_bits[1224:1216];
  assign io_out_bits_uop_rfWen = out_bits[1215];
  assign io_out_bits_uop_fpWen = out_bits[1214];
  assign io_out_bits_uop_vecWen = out_bits[1213];
  assign io_out_bits_uop_v0Wen = out_bits[1212];
  assign io_out_bits_uop_vlWen = out_bits[1211];
  assign io_out_bits_uop_isXSTrap = out_bits[1210];
  assign io_out_bits_uop_waitForward = out_bits[1209];
  assign io_out_bits_uop_blockBackward = out_bits[1208];
  assign io_out_bits_uop_flushPipe = out_bits[1207];
  assign io_out_bits_uop_canRobCompress = out_bits[1206];
  assign io_out_bits_uop_selImm = out_bits[1205:1202];
  assign io_out_bits_uop_imm = out_bits[1201:1170];
  assign io_out_bits_uop_fpu_typeTagOut = out_bits[1169:1168];
  assign io_out_bits_uop_fpu_wflags = out_bits[1167];
  assign io_out_bits_uop_fpu_typ = out_bits[1166:1165];
  assign io_out_bits_uop_fpu_fmt = out_bits[1164:1163];
  assign io_out_bits_uop_fpu_rm = out_bits[1162:1160];
  assign io_out_bits_uop_vpu_vill = out_bits[1159];
  assign io_out_bits_uop_vpu_vma = out_bits[1158];
  assign io_out_bits_uop_vpu_vta = out_bits[1157];
  assign io_out_bits_uop_vpu_vsew = out_bits[1156:1155];
  assign io_out_bits_uop_vpu_vlmul = out_bits[1154:1152];
  assign io_out_bits_uop_vpu_specVill = out_bits[1151];
  assign io_out_bits_uop_vpu_specVma = out_bits[1150];
  assign io_out_bits_uop_vpu_specVta = out_bits[1149];
  assign io_out_bits_uop_vpu_specVsew = out_bits[1148:1147];
  assign io_out_bits_uop_vpu_specVlmul = out_bits[1146:1144];
  assign io_out_bits_uop_vpu_vm = out_bits[1143];
  assign io_out_bits_uop_vpu_vstart = out_bits[1142:1135];
  assign io_out_bits_uop_vpu_frm = out_bits[1134:1132];
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst = out_bits[1131];
  assign io_out_bits_uop_vpu_fpu_isFP32Instr = out_bits[1130];
  assign io_out_bits_uop_vpu_fpu_isFP64Instr = out_bits[1129];
  assign io_out_bits_uop_vpu_fpu_isReduction = out_bits[1128];
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2 = out_bits[1127];
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4 = out_bits[1126];
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8 = out_bits[1125];
  assign io_out_bits_uop_vpu_vxrm = out_bits[1124:1123];
  assign io_out_bits_uop_vpu_vuopIdx = out_bits[1122:1116];
  assign io_out_bits_uop_vpu_lastUop = out_bits[1115];
  assign io_out_bits_uop_vpu_vmask = out_bits[1114:987];
  assign io_out_bits_uop_vpu_vl = out_bits[986:979];
  assign io_out_bits_uop_vpu_nf = out_bits[978:976];
  assign io_out_bits_uop_vpu_veew = out_bits[975:974];
  assign io_out_bits_uop_vpu_isReverse = out_bits[973];
  assign io_out_bits_uop_vpu_isExt = out_bits[972];
  assign io_out_bits_uop_vpu_isNarrow = out_bits[971];
  assign io_out_bits_uop_vpu_isDstMask = out_bits[970];
  assign io_out_bits_uop_vpu_isOpMask = out_bits[969];
  assign io_out_bits_uop_vpu_isMove = out_bits[968];
  assign io_out_bits_uop_vpu_isDependOldVd = out_bits[967];
  assign io_out_bits_uop_vpu_isWritePartVd = out_bits[966];
  assign io_out_bits_uop_vpu_isVleff = out_bits[965];
  assign io_out_bits_uop_vlsInstr = out_bits[964];
  assign io_out_bits_uop_wfflags = out_bits[963];
  assign io_out_bits_uop_isMove = out_bits[962];
  assign io_out_bits_uop_isDropAmocasSta = out_bits[961];
  assign io_out_bits_uop_uopIdx = out_bits[960:954];
  assign io_out_bits_uop_isVset = out_bits[953];
  assign io_out_bits_uop_firstUop = out_bits[952];
  assign io_out_bits_uop_lastUop = out_bits[951];
  assign io_out_bits_uop_numUops = out_bits[950:944];
  assign io_out_bits_uop_numWB = out_bits[943:937];
  assign io_out_bits_uop_commitType = out_bits[936:934];
  assign io_out_bits_uop_srcState_0 = out_bits[933];
  assign io_out_bits_uop_srcState_1 = out_bits[932];
  assign io_out_bits_uop_srcState_2 = out_bits[931];
  assign io_out_bits_uop_srcState_3 = out_bits[930];
  assign io_out_bits_uop_srcState_4 = out_bits[929];
  assign io_out_bits_uop_srcLoadDependency_0_0 = out_bits[928:927];
  assign io_out_bits_uop_srcLoadDependency_0_1 = out_bits[926:925];
  assign io_out_bits_uop_srcLoadDependency_0_2 = out_bits[924:923];
  assign io_out_bits_uop_srcLoadDependency_1_0 = out_bits[922:921];
  assign io_out_bits_uop_srcLoadDependency_1_1 = out_bits[920:919];
  assign io_out_bits_uop_srcLoadDependency_1_2 = out_bits[918:917];
  assign io_out_bits_uop_srcLoadDependency_2_0 = out_bits[916:915];
  assign io_out_bits_uop_srcLoadDependency_2_1 = out_bits[914:913];
  assign io_out_bits_uop_srcLoadDependency_2_2 = out_bits[912:911];
  assign io_out_bits_uop_srcLoadDependency_3_0 = out_bits[910:909];
  assign io_out_bits_uop_srcLoadDependency_3_1 = out_bits[908:907];
  assign io_out_bits_uop_srcLoadDependency_3_2 = out_bits[906:905];
  assign io_out_bits_uop_srcLoadDependency_4_0 = out_bits[904:903];
  assign io_out_bits_uop_srcLoadDependency_4_1 = out_bits[902:901];
  assign io_out_bits_uop_srcLoadDependency_4_2 = out_bits[900:899];
  assign io_out_bits_uop_psrc_0 = out_bits[898:891];
  assign io_out_bits_uop_psrc_1 = out_bits[890:883];
  assign io_out_bits_uop_psrc_2 = out_bits[882:875];
  assign io_out_bits_uop_psrc_3 = out_bits[874:867];
  assign io_out_bits_uop_psrc_4 = out_bits[866:859];
  assign io_out_bits_uop_pdest = out_bits[858:851];
  assign io_out_bits_uop_useRegCache_0 = out_bits[850];
  assign io_out_bits_uop_useRegCache_1 = out_bits[849];
  assign io_out_bits_uop_regCacheIdx_0 = out_bits[848:844];
  assign io_out_bits_uop_regCacheIdx_1 = out_bits[843:839];
  assign io_out_bits_uop_robIdx_flag = out_bits[838];
  assign io_out_bits_uop_robIdx_value = out_bits[837:830];
  assign io_out_bits_uop_instrSize = out_bits[829:827];
  assign io_out_bits_uop_dirtyFs = out_bits[826];
  assign io_out_bits_uop_dirtyVs = out_bits[825];
  assign io_out_bits_uop_traceBlockInPipe_itype = out_bits[824:821];
  assign io_out_bits_uop_traceBlockInPipe_iretire = out_bits[820:817];
  assign io_out_bits_uop_traceBlockInPipe_ilastsize = out_bits[816];
  assign io_out_bits_uop_eliminatedMove = out_bits[815];
  assign io_out_bits_uop_snapshot = out_bits[814];
  assign io_out_bits_uop_debugInfo_eliminatedMove = out_bits[813];
  assign io_out_bits_uop_debugInfo_renameTime = out_bits[812:749];
  assign io_out_bits_uop_debugInfo_dispatchTime = out_bits[748:685];
  assign io_out_bits_uop_debugInfo_enqRsTime = out_bits[684:621];
  assign io_out_bits_uop_debugInfo_selectTime = out_bits[620:557];
  assign io_out_bits_uop_debugInfo_issueTime = out_bits[556:493];
  assign io_out_bits_uop_debugInfo_writebackTime = out_bits[492:429];
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out_bits[428:365];
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime = out_bits[364:301];
  assign io_out_bits_uop_debugInfo_tlbRespTime = out_bits[300:237];
  assign io_out_bits_uop_debug_seqNum_seqNum = out_bits[236:181];
  assign io_out_bits_uop_debug_seqNum_uopIdx = out_bits[180:173];
  assign io_out_bits_uop_storeSetHit = out_bits[172];
  assign io_out_bits_uop_waitForRobIdx_flag = out_bits[171];
  assign io_out_bits_uop_waitForRobIdx_value = out_bits[170:163];
  assign io_out_bits_uop_loadWaitBit = out_bits[162];
  assign io_out_bits_uop_loadWaitStrict = out_bits[161];
  assign io_out_bits_uop_ssid = out_bits[160:156];
  assign io_out_bits_uop_lqIdx_flag = out_bits[155];
  assign io_out_bits_uop_lqIdx_value = out_bits[154:148];
  assign io_out_bits_uop_sqIdx_flag = out_bits[147];
  assign io_out_bits_uop_sqIdx_value = out_bits[146:141];
  assign io_out_bits_uop_singleStep = out_bits[140];
  assign io_out_bits_uop_replayInst = out_bits[139];
  assign io_out_bits_uop_debug_fuType = out_bits[138:104];
  assign io_out_bits_uop_debug_sim_trig = out_bits[103];
  assign io_out_bits_uop_numLsElem = out_bits[102:98];
  assign io_out_bits_debug_paddr = out_bits[97:50];
  assign io_out_bits_debug_vaddr = out_bits[49:0];
endmodule
