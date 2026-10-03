// =====================================================================
// VSSplitBufferImp.sv —— 向量 store 的"拆分缓冲"（VSplitBuffer 家族的 store 变体薄文件）
// ---------------------------------------------------------------------
// 核 xs_VSplitBuffer_core 在 VLSplitBufferImp.sv（机制讲解在那里），类型在 vlsu_pkg.sv。
// 本变体（IS_VSTORE=1）与 load 变体的差别：
//   · 多一路 vstd：把每个元素的 store 数据送 store queue（每个元素只送一次，dataIssued 寄存器）；
//     带一个 difftest 用的 vecDebug.offset；
//   · 元素地址非对齐时要等 store 非对齐缓冲空闲才发（vstdMisalign 四根输入）；
//   · 每个元素占一个 SQ 项：sqIdx + splitIdx（队列大小 56 的环形加法）；
//   · 没有有序 indexed 的 stop-and-wait 状态机，也没有 fromPipeline 输入；
//   · 缓冲项寄存器 uopq_* 的字段集合照 golden 现数（比 load 变体多 data）。
// 规模：370 个端口；寄存器 = 本文件生成段里的 uopq_*（无复位）+ 核里的 allocated / isFirstActive /
//   splitIdx / strideOffsetReg / dataIssued（异步复位）。
// =====================================================================

// BEGIN GENERATED(wrapper_VSSplitBufferImp) —— scripts/gen_vsplit.py 生成，勿手改
module VSSplitBufferImp
  import vlsu_pkg::*;
(
  input          clock,
  input          reset,
  input          io_redirect_valid,
  input          io_redirect_bits_robIdx_flag,
  input  [7:0]   io_redirect_bits_robIdx_value,
  input          io_redirect_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [15:0]  io_in_bits_flowMask,
  input  [127:0] io_in_bits_data,
  input  [63:0]  io_in_bits_baseAddr,
  input  [63:0]  io_in_bits_uopAddr,
  input  [127:0] io_in_bits_stride,
  input  [4:0]   io_in_bits_flowNum,
  input  [1:0]   io_in_bits_eew,
  input  [2:0]   io_in_bits_sew,
  input  [2:0]   io_in_bits_emul,
  input  [2:0]   io_in_bits_lmul,
  input  [2:0]   io_in_bits_instType,
  input  [4:0]   io_in_bits_indexedSplitOffset,
  input  [31:0]  io_in_bits_uop_instr,
  input  [49:0]  io_in_bits_uop_pc,
  input  [9:0]   io_in_bits_uop_foldpc,
  input          io_in_bits_uop_exceptionVec_7,
  input          io_in_bits_uop_exceptionVec_15,
  input          io_in_bits_uop_exceptionVec_19,
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
  input          io_in_bits_uop_canRobCompress,
  input  [3:0]   io_in_bits_uop_selImm,
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
  input          io_in_bits_preIsSplit,
  input  [3:0]   io_in_bits_mBIndex,
  input  [2:0]   io_in_bits_alignedType,
  input  [7:0]   io_in_bits_indexVlMaxInVd,
  input  [3:0]   io_in_bits_usLowBitsAddr,
  input          io_in_bits_usAligned128,
  input  [31:0]  io_in_bits_usMask,
  input          io_in_bits_isVecPartReplay,
  input  [15:0]  io_in_bits_vecReplayFlowMask,
  input          io_out_ready,
  output         io_out_valid,
  output [63:0]  io_out_bits_vaddr,
  output [49:0]  io_out_bits_basevaddr,
  output [15:0]  io_out_bits_mask,
  output [3:0]   io_out_bits_reg_offset,
  output [2:0]   io_out_bits_alignedType,
  output         io_out_bits_vecActive,
  output         io_out_bits_vecIsFirstActiveElement,
  output [31:0]  io_out_bits_uop_instr,
  output [49:0]  io_out_bits_uop_pc,
  output [9:0]   io_out_bits_uop_foldpc,
  output         io_out_bits_uop_exceptionVec_6,
  output         io_out_bits_uop_exceptionVec_7,
  output         io_out_bits_uop_exceptionVec_15,
  output         io_out_bits_uop_exceptionVec_19,
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
  output         io_out_bits_uop_canRobCompress,
  output [3:0]   io_out_bits_uop_selImm,
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
  output [3:0]   io_out_bits_mBIndex,
  output [7:0]   io_out_bits_elemIdx,
  output [7:0]   io_out_bits_elemIdxInsideVd,
  output [4:0]   io_out_bits_splitIndex,
  output         io_vstd_valid,
  output [8:0]   io_vstd_bits_uop_fuOpType,
  output         io_vstd_bits_uop_sqIdx_flag,
  output [5:0]   io_vstd_bits_uop_sqIdx_value,
  output [127:0] io_vstd_bits_data,
  output [5:0]   io_vstd_bits_vecDebug_offset,
  input          io_vstdMisalign_storeMisalignBufferEmpty,
  input          io_vstdMisalign_scalaIssueValid,
  input          io_vstdMisalign_scalaIssueRobIdx_flag,
  input  [7:0]   io_vstdMisalign_scalaIssueRobIdx_value,
  input          io_vstdMisalign_sqDeqIsVec
);

  vls_t          in;
  always_comb begin
    in = '0;
    in.flowMask = io_in_bits_flowMask;
    in.data = io_in_bits_data;
    in.baseAddr = io_in_bits_baseAddr;
    in.uopAddr = io_in_bits_uopAddr;
    in.stride = io_in_bits_stride;
    in.flowNum = io_in_bits_flowNum;
    in.eew = io_in_bits_eew;
    in.sew = io_in_bits_sew;
    in.emul = io_in_bits_emul;
    in.lmul = io_in_bits_lmul;
    in.instType = io_in_bits_instType;
    in.indexedSplitOffset = io_in_bits_indexedSplitOffset;
    in.uop.instr = io_in_bits_uop_instr;
    in.uop.pc = io_in_bits_uop_pc;
    in.uop.foldpc = io_in_bits_uop_foldpc;
    in.uop.exceptionVec[7] = io_in_bits_uop_exceptionVec_7;
    in.uop.exceptionVec[15] = io_in_bits_uop_exceptionVec_15;
    in.uop.exceptionVec[19] = io_in_bits_uop_exceptionVec_19;
    in.uop.exceptionVec[23] = io_in_bits_uop_exceptionVec_23;
    in.uop.isFetchMalAddr = io_in_bits_uop_isFetchMalAddr;
    in.uop.hasException = io_in_bits_uop_hasException;
    in.uop.trigger = io_in_bits_uop_trigger;
    in.uop.preDecodeInfo_valid = io_in_bits_uop_preDecodeInfo_valid;
    in.uop.preDecodeInfo_isRVC = io_in_bits_uop_preDecodeInfo_isRVC;
    in.uop.preDecodeInfo_brType = io_in_bits_uop_preDecodeInfo_brType;
    in.uop.preDecodeInfo_isCall = io_in_bits_uop_preDecodeInfo_isCall;
    in.uop.preDecodeInfo_isRet = io_in_bits_uop_preDecodeInfo_isRet;
    in.uop.pred_taken = io_in_bits_uop_pred_taken;
    in.uop.crossPageIPFFix = io_in_bits_uop_crossPageIPFFix;
    in.uop.ftqPtr_flag = io_in_bits_uop_ftqPtr_flag;
    in.uop.ftqPtr_value = io_in_bits_uop_ftqPtr_value;
    in.uop.ftqOffset = io_in_bits_uop_ftqOffset;
    in.uop.satpFlushFirstFetchFault = io_in_bits_uop_satpFlushFirstFetchFault;
    in.uop.srcType_0 = io_in_bits_uop_srcType_0;
    in.uop.srcType_1 = io_in_bits_uop_srcType_1;
    in.uop.srcType_2 = io_in_bits_uop_srcType_2;
    in.uop.srcType_3 = io_in_bits_uop_srcType_3;
    in.uop.srcType_4 = io_in_bits_uop_srcType_4;
    in.uop.ldest = io_in_bits_uop_ldest;
    in.uop.fuType = io_in_bits_uop_fuType;
    in.uop.fuOpType = io_in_bits_uop_fuOpType;
    in.uop.rfWen = io_in_bits_uop_rfWen;
    in.uop.fpWen = io_in_bits_uop_fpWen;
    in.uop.vecWen = io_in_bits_uop_vecWen;
    in.uop.v0Wen = io_in_bits_uop_v0Wen;
    in.uop.vlWen = io_in_bits_uop_vlWen;
    in.uop.isXSTrap = io_in_bits_uop_isXSTrap;
    in.uop.waitForward = io_in_bits_uop_waitForward;
    in.uop.blockBackward = io_in_bits_uop_blockBackward;
    in.uop.canRobCompress = io_in_bits_uop_canRobCompress;
    in.uop.selImm = io_in_bits_uop_selImm;
    in.uop.fpu_typeTagOut = io_in_bits_uop_fpu_typeTagOut;
    in.uop.fpu_wflags = io_in_bits_uop_fpu_wflags;
    in.uop.fpu_typ = io_in_bits_uop_fpu_typ;
    in.uop.fpu_fmt = io_in_bits_uop_fpu_fmt;
    in.uop.fpu_rm = io_in_bits_uop_fpu_rm;
    in.uop.vpu_vill = io_in_bits_uop_vpu_vill;
    in.uop.vpu_vma = io_in_bits_uop_vpu_vma;
    in.uop.vpu_vta = io_in_bits_uop_vpu_vta;
    in.uop.vpu_vsew = io_in_bits_uop_vpu_vsew;
    in.uop.vpu_vlmul = io_in_bits_uop_vpu_vlmul;
    in.uop.vpu_specVill = io_in_bits_uop_vpu_specVill;
    in.uop.vpu_specVma = io_in_bits_uop_vpu_specVma;
    in.uop.vpu_specVta = io_in_bits_uop_vpu_specVta;
    in.uop.vpu_specVsew = io_in_bits_uop_vpu_specVsew;
    in.uop.vpu_specVlmul = io_in_bits_uop_vpu_specVlmul;
    in.uop.vpu_vm = io_in_bits_uop_vpu_vm;
    in.uop.vpu_vstart = io_in_bits_uop_vpu_vstart;
    in.uop.vpu_frm = io_in_bits_uop_vpu_frm;
    in.uop.vpu_fpu_isFpToVecInst = io_in_bits_uop_vpu_fpu_isFpToVecInst;
    in.uop.vpu_fpu_isFP32Instr = io_in_bits_uop_vpu_fpu_isFP32Instr;
    in.uop.vpu_fpu_isFP64Instr = io_in_bits_uop_vpu_fpu_isFP64Instr;
    in.uop.vpu_fpu_isReduction = io_in_bits_uop_vpu_fpu_isReduction;
    in.uop.vpu_fpu_isFoldTo1_2 = io_in_bits_uop_vpu_fpu_isFoldTo1_2;
    in.uop.vpu_fpu_isFoldTo1_4 = io_in_bits_uop_vpu_fpu_isFoldTo1_4;
    in.uop.vpu_fpu_isFoldTo1_8 = io_in_bits_uop_vpu_fpu_isFoldTo1_8;
    in.uop.vpu_vxrm = io_in_bits_uop_vpu_vxrm;
    in.uop.vpu_vuopIdx = io_in_bits_uop_vpu_vuopIdx;
    in.uop.vpu_lastUop = io_in_bits_uop_vpu_lastUop;
    in.uop.vpu_vmask = io_in_bits_uop_vpu_vmask;
    in.uop.vpu_vl = io_in_bits_uop_vpu_vl;
    in.uop.vpu_nf = io_in_bits_uop_vpu_nf;
    in.uop.vpu_veew = io_in_bits_uop_vpu_veew;
    in.uop.vpu_isReverse = io_in_bits_uop_vpu_isReverse;
    in.uop.vpu_isExt = io_in_bits_uop_vpu_isExt;
    in.uop.vpu_isNarrow = io_in_bits_uop_vpu_isNarrow;
    in.uop.vpu_isDstMask = io_in_bits_uop_vpu_isDstMask;
    in.uop.vpu_isOpMask = io_in_bits_uop_vpu_isOpMask;
    in.uop.vpu_isMove = io_in_bits_uop_vpu_isMove;
    in.uop.vpu_isDependOldVd = io_in_bits_uop_vpu_isDependOldVd;
    in.uop.vpu_isWritePartVd = io_in_bits_uop_vpu_isWritePartVd;
    in.uop.vpu_isVleff = io_in_bits_uop_vpu_isVleff;
    in.uop.vlsInstr = io_in_bits_uop_vlsInstr;
    in.uop.wfflags = io_in_bits_uop_wfflags;
    in.uop.isMove = io_in_bits_uop_isMove;
    in.uop.isDropAmocasSta = io_in_bits_uop_isDropAmocasSta;
    in.uop.uopIdx = io_in_bits_uop_uopIdx;
    in.uop.isVset = io_in_bits_uop_isVset;
    in.uop.firstUop = io_in_bits_uop_firstUop;
    in.uop.lastUop = io_in_bits_uop_lastUop;
    in.uop.numUops = io_in_bits_uop_numUops;
    in.uop.numWB = io_in_bits_uop_numWB;
    in.uop.commitType = io_in_bits_uop_commitType;
    in.uop.srcState_0 = io_in_bits_uop_srcState_0;
    in.uop.srcState_1 = io_in_bits_uop_srcState_1;
    in.uop.srcState_2 = io_in_bits_uop_srcState_2;
    in.uop.srcState_3 = io_in_bits_uop_srcState_3;
    in.uop.srcState_4 = io_in_bits_uop_srcState_4;
    in.uop.srcLoadDependency_0_0 = io_in_bits_uop_srcLoadDependency_0_0;
    in.uop.srcLoadDependency_0_1 = io_in_bits_uop_srcLoadDependency_0_1;
    in.uop.srcLoadDependency_0_2 = io_in_bits_uop_srcLoadDependency_0_2;
    in.uop.srcLoadDependency_1_0 = io_in_bits_uop_srcLoadDependency_1_0;
    in.uop.srcLoadDependency_1_1 = io_in_bits_uop_srcLoadDependency_1_1;
    in.uop.srcLoadDependency_1_2 = io_in_bits_uop_srcLoadDependency_1_2;
    in.uop.srcLoadDependency_2_0 = io_in_bits_uop_srcLoadDependency_2_0;
    in.uop.srcLoadDependency_2_1 = io_in_bits_uop_srcLoadDependency_2_1;
    in.uop.srcLoadDependency_2_2 = io_in_bits_uop_srcLoadDependency_2_2;
    in.uop.srcLoadDependency_3_0 = io_in_bits_uop_srcLoadDependency_3_0;
    in.uop.srcLoadDependency_3_1 = io_in_bits_uop_srcLoadDependency_3_1;
    in.uop.srcLoadDependency_3_2 = io_in_bits_uop_srcLoadDependency_3_2;
    in.uop.srcLoadDependency_4_0 = io_in_bits_uop_srcLoadDependency_4_0;
    in.uop.srcLoadDependency_4_1 = io_in_bits_uop_srcLoadDependency_4_1;
    in.uop.srcLoadDependency_4_2 = io_in_bits_uop_srcLoadDependency_4_2;
    in.uop.psrc_0 = io_in_bits_uop_psrc_0;
    in.uop.psrc_1 = io_in_bits_uop_psrc_1;
    in.uop.psrc_2 = io_in_bits_uop_psrc_2;
    in.uop.psrc_3 = io_in_bits_uop_psrc_3;
    in.uop.psrc_4 = io_in_bits_uop_psrc_4;
    in.uop.pdest = io_in_bits_uop_pdest;
    in.uop.useRegCache_0 = io_in_bits_uop_useRegCache_0;
    in.uop.useRegCache_1 = io_in_bits_uop_useRegCache_1;
    in.uop.regCacheIdx_0 = io_in_bits_uop_regCacheIdx_0;
    in.uop.regCacheIdx_1 = io_in_bits_uop_regCacheIdx_1;
    in.uop.robIdx_flag = io_in_bits_uop_robIdx_flag;
    in.uop.robIdx_value = io_in_bits_uop_robIdx_value;
    in.uop.instrSize = io_in_bits_uop_instrSize;
    in.uop.dirtyFs = io_in_bits_uop_dirtyFs;
    in.uop.dirtyVs = io_in_bits_uop_dirtyVs;
    in.uop.traceBlockInPipe_itype = io_in_bits_uop_traceBlockInPipe_itype;
    in.uop.traceBlockInPipe_iretire = io_in_bits_uop_traceBlockInPipe_iretire;
    in.uop.traceBlockInPipe_ilastsize = io_in_bits_uop_traceBlockInPipe_ilastsize;
    in.uop.eliminatedMove = io_in_bits_uop_eliminatedMove;
    in.uop.snapshot = io_in_bits_uop_snapshot;
    in.uop.debugInfo_eliminatedMove = io_in_bits_uop_debugInfo_eliminatedMove;
    in.uop.debugInfo_renameTime = io_in_bits_uop_debugInfo_renameTime;
    in.uop.debugInfo_dispatchTime = io_in_bits_uop_debugInfo_dispatchTime;
    in.uop.debugInfo_enqRsTime = io_in_bits_uop_debugInfo_enqRsTime;
    in.uop.debugInfo_selectTime = io_in_bits_uop_debugInfo_selectTime;
    in.uop.debugInfo_issueTime = io_in_bits_uop_debugInfo_issueTime;
    in.uop.debugInfo_writebackTime = io_in_bits_uop_debugInfo_writebackTime;
    in.uop.debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in.uop.debugInfo_tlbFirstReqTime = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in.uop.debugInfo_tlbRespTime = io_in_bits_uop_debugInfo_tlbRespTime;
    in.uop.debug_seqNum_seqNum = io_in_bits_uop_debug_seqNum_seqNum;
    in.uop.debug_seqNum_uopIdx = io_in_bits_uop_debug_seqNum_uopIdx;
    in.uop.storeSetHit = io_in_bits_uop_storeSetHit;
    in.uop.waitForRobIdx_flag = io_in_bits_uop_waitForRobIdx_flag;
    in.uop.waitForRobIdx_value = io_in_bits_uop_waitForRobIdx_value;
    in.uop.loadWaitBit = io_in_bits_uop_loadWaitBit;
    in.uop.loadWaitStrict = io_in_bits_uop_loadWaitStrict;
    in.uop.ssid = io_in_bits_uop_ssid;
    in.uop.lqIdx_flag = io_in_bits_uop_lqIdx_flag;
    in.uop.lqIdx_value = io_in_bits_uop_lqIdx_value;
    in.uop.sqIdx_flag = io_in_bits_uop_sqIdx_flag;
    in.uop.sqIdx_value = io_in_bits_uop_sqIdx_value;
    in.uop.singleStep = io_in_bits_uop_singleStep;
    in.uop.replayInst = io_in_bits_uop_replayInst;
    in.uop.debug_fuType = io_in_bits_uop_debug_fuType;
    in.uop.debug_sim_trig = io_in_bits_uop_debug_sim_trig;
    in.uop.numLsElem = io_in_bits_uop_numLsElem;
    in.preIsSplit = io_in_bits_preIsSplit;
    in.mBIndex = io_in_bits_mBIndex;
    in.alignedType = io_in_bits_alignedType;
    in.indexVlMaxInVd = io_in_bits_indexVlMaxInVd;
    in.usLowBitsAddr = io_in_bits_usLowBitsAddr;
    in.usAligned128 = io_in_bits_usAligned128;
    in.usMask = io_in_bits_usMask;
    in.isVecPartReplay = io_in_bits_isVecPartReplay;
    in.vecReplayFlowMask = io_in_bits_vecReplayFlowMask;
  end

  vec_pipe_t     out;
  assign io_out_bits_vaddr = out.vaddr;
  assign io_out_bits_basevaddr = out.basevaddr;
  assign io_out_bits_mask = out.mask;
  assign io_out_bits_reg_offset = out.reg_offset;
  assign io_out_bits_alignedType = out.alignedType;
  assign io_out_bits_vecActive = out.vecActive;
  assign io_out_bits_vecIsFirstActiveElement = out.vecIsFirstActiveElement;
  assign io_out_bits_uop_instr = out.uop.instr;
  assign io_out_bits_uop_pc = out.uop.pc;
  assign io_out_bits_uop_foldpc = out.uop.foldpc;
  assign io_out_bits_uop_exceptionVec_6 = out.uop.exceptionVec[6];
  assign io_out_bits_uop_exceptionVec_7 = out.uop.exceptionVec[7];
  assign io_out_bits_uop_exceptionVec_15 = out.uop.exceptionVec[15];
  assign io_out_bits_uop_exceptionVec_19 = out.uop.exceptionVec[19];
  assign io_out_bits_uop_exceptionVec_23 = out.uop.exceptionVec[23];
  assign io_out_bits_uop_isFetchMalAddr = out.uop.isFetchMalAddr;
  assign io_out_bits_uop_hasException = out.uop.hasException;
  assign io_out_bits_uop_trigger = out.uop.trigger;
  assign io_out_bits_uop_preDecodeInfo_valid = out.uop.preDecodeInfo_valid;
  assign io_out_bits_uop_preDecodeInfo_isRVC = out.uop.preDecodeInfo_isRVC;
  assign io_out_bits_uop_preDecodeInfo_brType = out.uop.preDecodeInfo_brType;
  assign io_out_bits_uop_preDecodeInfo_isCall = out.uop.preDecodeInfo_isCall;
  assign io_out_bits_uop_preDecodeInfo_isRet = out.uop.preDecodeInfo_isRet;
  assign io_out_bits_uop_pred_taken = out.uop.pred_taken;
  assign io_out_bits_uop_crossPageIPFFix = out.uop.crossPageIPFFix;
  assign io_out_bits_uop_ftqPtr_flag = out.uop.ftqPtr_flag;
  assign io_out_bits_uop_ftqPtr_value = out.uop.ftqPtr_value;
  assign io_out_bits_uop_ftqOffset = out.uop.ftqOffset;
  assign io_out_bits_uop_satpFlushFirstFetchFault = out.uop.satpFlushFirstFetchFault;
  assign io_out_bits_uop_srcType_0 = out.uop.srcType_0;
  assign io_out_bits_uop_srcType_1 = out.uop.srcType_1;
  assign io_out_bits_uop_srcType_2 = out.uop.srcType_2;
  assign io_out_bits_uop_srcType_3 = out.uop.srcType_3;
  assign io_out_bits_uop_srcType_4 = out.uop.srcType_4;
  assign io_out_bits_uop_ldest = out.uop.ldest;
  assign io_out_bits_uop_fuType = out.uop.fuType;
  assign io_out_bits_uop_fuOpType = out.uop.fuOpType;
  assign io_out_bits_uop_rfWen = out.uop.rfWen;
  assign io_out_bits_uop_fpWen = out.uop.fpWen;
  assign io_out_bits_uop_vecWen = out.uop.vecWen;
  assign io_out_bits_uop_v0Wen = out.uop.v0Wen;
  assign io_out_bits_uop_vlWen = out.uop.vlWen;
  assign io_out_bits_uop_isXSTrap = out.uop.isXSTrap;
  assign io_out_bits_uop_waitForward = out.uop.waitForward;
  assign io_out_bits_uop_blockBackward = out.uop.blockBackward;
  assign io_out_bits_uop_canRobCompress = out.uop.canRobCompress;
  assign io_out_bits_uop_selImm = out.uop.selImm;
  assign io_out_bits_uop_fpu_typeTagOut = out.uop.fpu_typeTagOut;
  assign io_out_bits_uop_fpu_wflags = out.uop.fpu_wflags;
  assign io_out_bits_uop_fpu_typ = out.uop.fpu_typ;
  assign io_out_bits_uop_fpu_fmt = out.uop.fpu_fmt;
  assign io_out_bits_uop_fpu_rm = out.uop.fpu_rm;
  assign io_out_bits_uop_vpu_vill = out.uop.vpu_vill;
  assign io_out_bits_uop_vpu_vma = out.uop.vpu_vma;
  assign io_out_bits_uop_vpu_vta = out.uop.vpu_vta;
  assign io_out_bits_uop_vpu_vsew = out.uop.vpu_vsew;
  assign io_out_bits_uop_vpu_vlmul = out.uop.vpu_vlmul;
  assign io_out_bits_uop_vpu_specVill = out.uop.vpu_specVill;
  assign io_out_bits_uop_vpu_specVma = out.uop.vpu_specVma;
  assign io_out_bits_uop_vpu_specVta = out.uop.vpu_specVta;
  assign io_out_bits_uop_vpu_specVsew = out.uop.vpu_specVsew;
  assign io_out_bits_uop_vpu_specVlmul = out.uop.vpu_specVlmul;
  assign io_out_bits_uop_vpu_vm = out.uop.vpu_vm;
  assign io_out_bits_uop_vpu_vstart = out.uop.vpu_vstart;
  assign io_out_bits_uop_vpu_frm = out.uop.vpu_frm;
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst = out.uop.vpu_fpu_isFpToVecInst;
  assign io_out_bits_uop_vpu_fpu_isFP32Instr = out.uop.vpu_fpu_isFP32Instr;
  assign io_out_bits_uop_vpu_fpu_isFP64Instr = out.uop.vpu_fpu_isFP64Instr;
  assign io_out_bits_uop_vpu_fpu_isReduction = out.uop.vpu_fpu_isReduction;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2 = out.uop.vpu_fpu_isFoldTo1_2;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4 = out.uop.vpu_fpu_isFoldTo1_4;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8 = out.uop.vpu_fpu_isFoldTo1_8;
  assign io_out_bits_uop_vpu_vxrm = out.uop.vpu_vxrm;
  assign io_out_bits_uop_vpu_vuopIdx = out.uop.vpu_vuopIdx;
  assign io_out_bits_uop_vpu_lastUop = out.uop.vpu_lastUop;
  assign io_out_bits_uop_vpu_vmask = out.uop.vpu_vmask;
  assign io_out_bits_uop_vpu_vl = out.uop.vpu_vl;
  assign io_out_bits_uop_vpu_nf = out.uop.vpu_nf;
  assign io_out_bits_uop_vpu_veew = out.uop.vpu_veew;
  assign io_out_bits_uop_vpu_isReverse = out.uop.vpu_isReverse;
  assign io_out_bits_uop_vpu_isExt = out.uop.vpu_isExt;
  assign io_out_bits_uop_vpu_isNarrow = out.uop.vpu_isNarrow;
  assign io_out_bits_uop_vpu_isDstMask = out.uop.vpu_isDstMask;
  assign io_out_bits_uop_vpu_isOpMask = out.uop.vpu_isOpMask;
  assign io_out_bits_uop_vpu_isMove = out.uop.vpu_isMove;
  assign io_out_bits_uop_vpu_isDependOldVd = out.uop.vpu_isDependOldVd;
  assign io_out_bits_uop_vpu_isWritePartVd = out.uop.vpu_isWritePartVd;
  assign io_out_bits_uop_vpu_isVleff = out.uop.vpu_isVleff;
  assign io_out_bits_uop_vlsInstr = out.uop.vlsInstr;
  assign io_out_bits_uop_wfflags = out.uop.wfflags;
  assign io_out_bits_uop_isMove = out.uop.isMove;
  assign io_out_bits_uop_isDropAmocasSta = out.uop.isDropAmocasSta;
  assign io_out_bits_uop_uopIdx = out.uop.uopIdx;
  assign io_out_bits_uop_isVset = out.uop.isVset;
  assign io_out_bits_uop_firstUop = out.uop.firstUop;
  assign io_out_bits_uop_lastUop = out.uop.lastUop;
  assign io_out_bits_uop_numUops = out.uop.numUops;
  assign io_out_bits_uop_numWB = out.uop.numWB;
  assign io_out_bits_uop_commitType = out.uop.commitType;
  assign io_out_bits_uop_srcState_0 = out.uop.srcState_0;
  assign io_out_bits_uop_srcState_1 = out.uop.srcState_1;
  assign io_out_bits_uop_srcState_2 = out.uop.srcState_2;
  assign io_out_bits_uop_srcState_3 = out.uop.srcState_3;
  assign io_out_bits_uop_srcState_4 = out.uop.srcState_4;
  assign io_out_bits_uop_srcLoadDependency_0_0 = out.uop.srcLoadDependency_0_0;
  assign io_out_bits_uop_srcLoadDependency_0_1 = out.uop.srcLoadDependency_0_1;
  assign io_out_bits_uop_srcLoadDependency_0_2 = out.uop.srcLoadDependency_0_2;
  assign io_out_bits_uop_srcLoadDependency_1_0 = out.uop.srcLoadDependency_1_0;
  assign io_out_bits_uop_srcLoadDependency_1_1 = out.uop.srcLoadDependency_1_1;
  assign io_out_bits_uop_srcLoadDependency_1_2 = out.uop.srcLoadDependency_1_2;
  assign io_out_bits_uop_srcLoadDependency_2_0 = out.uop.srcLoadDependency_2_0;
  assign io_out_bits_uop_srcLoadDependency_2_1 = out.uop.srcLoadDependency_2_1;
  assign io_out_bits_uop_srcLoadDependency_2_2 = out.uop.srcLoadDependency_2_2;
  assign io_out_bits_uop_srcLoadDependency_3_0 = out.uop.srcLoadDependency_3_0;
  assign io_out_bits_uop_srcLoadDependency_3_1 = out.uop.srcLoadDependency_3_1;
  assign io_out_bits_uop_srcLoadDependency_3_2 = out.uop.srcLoadDependency_3_2;
  assign io_out_bits_uop_srcLoadDependency_4_0 = out.uop.srcLoadDependency_4_0;
  assign io_out_bits_uop_srcLoadDependency_4_1 = out.uop.srcLoadDependency_4_1;
  assign io_out_bits_uop_srcLoadDependency_4_2 = out.uop.srcLoadDependency_4_2;
  assign io_out_bits_uop_psrc_0 = out.uop.psrc_0;
  assign io_out_bits_uop_psrc_1 = out.uop.psrc_1;
  assign io_out_bits_uop_psrc_2 = out.uop.psrc_2;
  assign io_out_bits_uop_psrc_3 = out.uop.psrc_3;
  assign io_out_bits_uop_psrc_4 = out.uop.psrc_4;
  assign io_out_bits_uop_pdest = out.uop.pdest;
  assign io_out_bits_uop_useRegCache_0 = out.uop.useRegCache_0;
  assign io_out_bits_uop_useRegCache_1 = out.uop.useRegCache_1;
  assign io_out_bits_uop_regCacheIdx_0 = out.uop.regCacheIdx_0;
  assign io_out_bits_uop_regCacheIdx_1 = out.uop.regCacheIdx_1;
  assign io_out_bits_uop_robIdx_flag = out.uop.robIdx_flag;
  assign io_out_bits_uop_robIdx_value = out.uop.robIdx_value;
  assign io_out_bits_uop_instrSize = out.uop.instrSize;
  assign io_out_bits_uop_dirtyFs = out.uop.dirtyFs;
  assign io_out_bits_uop_dirtyVs = out.uop.dirtyVs;
  assign io_out_bits_uop_traceBlockInPipe_itype = out.uop.traceBlockInPipe_itype;
  assign io_out_bits_uop_traceBlockInPipe_iretire = out.uop.traceBlockInPipe_iretire;
  assign io_out_bits_uop_traceBlockInPipe_ilastsize = out.uop.traceBlockInPipe_ilastsize;
  assign io_out_bits_uop_eliminatedMove = out.uop.eliminatedMove;
  assign io_out_bits_uop_snapshot = out.uop.snapshot;
  assign io_out_bits_uop_debugInfo_eliminatedMove = out.uop.debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime = out.uop.debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime = out.uop.debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime = out.uop.debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime = out.uop.debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime = out.uop.debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime = out.uop.debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out.uop.debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime = out.uop.debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime = out.uop.debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum = out.uop.debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx = out.uop.debug_seqNum_uopIdx;
  assign io_out_bits_uop_storeSetHit = out.uop.storeSetHit;
  assign io_out_bits_uop_waitForRobIdx_flag = out.uop.waitForRobIdx_flag;
  assign io_out_bits_uop_waitForRobIdx_value = out.uop.waitForRobIdx_value;
  assign io_out_bits_uop_loadWaitBit = out.uop.loadWaitBit;
  assign io_out_bits_uop_loadWaitStrict = out.uop.loadWaitStrict;
  assign io_out_bits_uop_ssid = out.uop.ssid;
  assign io_out_bits_uop_lqIdx_flag = out.uop.lqIdx_flag;
  assign io_out_bits_uop_lqIdx_value = out.uop.lqIdx_value;
  assign io_out_bits_uop_sqIdx_flag = out.uop.sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value = out.uop.sqIdx_value;
  assign io_out_bits_uop_singleStep = out.uop.singleStep;
  assign io_out_bits_uop_replayInst = out.uop.replayInst;
  assign io_out_bits_uop_debug_fuType = out.uop.debug_fuType;
  assign io_out_bits_uop_debug_sim_trig = out.uop.debug_sim_trig;
  assign io_out_bits_uop_numLsElem = out.uop.numLsElem;
  assign io_out_bits_mBIndex = out.mBIndex;
  assign io_out_bits_elemIdx = out.elemIdx;
  assign io_out_bits_elemIdxInsideVd = out.elemIdxInsideVd;
  assign io_out_bits_splitIndex = out.splitIndex;

  vstd_t         vstd;
  assign io_vstd_bits_uop_fuOpType = vstd.uop.fuOpType;
  assign io_vstd_bits_uop_sqIdx_flag = vstd.uop.sqIdx_flag;
  assign io_vstd_bits_uop_sqIdx_value = vstd.uop.sqIdx_value;
  assign io_vstd_bits_data = vstd.data;
  assign io_vstd_bits_vecDebug_offset = vstd.vecDebug_offset;

  // ---- 核与寄存器之间的桥 ----
  logic          doEnqueue;
  vls_t          uopq;

  // ---- uopq <= in（doEnqueue 时整包装入，无复位）：golden 留下的 179 个字段 ----
  logic [15:0]   uopq_flowMask;
  logic [127:0]  uopq_data;
  logic [63:0]   uopq_baseAddr;
  logic [63:0]   uopq_uopAddr;
  logic [127:0]  uopq_stride;
  logic [4:0]    uopq_flowNum;
  logic [1:0]    uopq_eew;
  logic [2:0]    uopq_sew;
  logic [2:0]    uopq_emul;
  logic [2:0]    uopq_lmul;
  logic [2:0]    uopq_instType;
  logic [4:0]    uopq_indexedSplitOffset;
  logic [31:0]   uopq_uop_instr;
  logic [49:0]   uopq_uop_pc;
  logic [9:0]    uopq_uop_foldpc;
  logic          uopq_uop_exceptionVec_7;
  logic          uopq_uop_exceptionVec_15;
  logic          uopq_uop_exceptionVec_19;
  logic          uopq_uop_exceptionVec_23;
  logic          uopq_uop_isFetchMalAddr;
  logic          uopq_uop_hasException;
  logic [3:0]    uopq_uop_trigger;
  logic          uopq_uop_preDecodeInfo_valid;
  logic          uopq_uop_preDecodeInfo_isRVC;
  logic [1:0]    uopq_uop_preDecodeInfo_brType;
  logic          uopq_uop_preDecodeInfo_isCall;
  logic          uopq_uop_preDecodeInfo_isRet;
  logic          uopq_uop_pred_taken;
  logic          uopq_uop_crossPageIPFFix;
  logic          uopq_uop_ftqPtr_flag;
  logic [5:0]    uopq_uop_ftqPtr_value;
  logic [3:0]    uopq_uop_ftqOffset;
  logic          uopq_uop_satpFlushFirstFetchFault;
  logic [3:0]    uopq_uop_srcType_0;
  logic [3:0]    uopq_uop_srcType_1;
  logic [3:0]    uopq_uop_srcType_2;
  logic [3:0]    uopq_uop_srcType_3;
  logic [3:0]    uopq_uop_srcType_4;
  logic [5:0]    uopq_uop_ldest;
  logic [34:0]   uopq_uop_fuType;
  logic [8:0]    uopq_uop_fuOpType;
  logic          uopq_uop_rfWen;
  logic          uopq_uop_fpWen;
  logic          uopq_uop_vecWen;
  logic          uopq_uop_v0Wen;
  logic          uopq_uop_vlWen;
  logic          uopq_uop_isXSTrap;
  logic          uopq_uop_waitForward;
  logic          uopq_uop_blockBackward;
  logic          uopq_uop_canRobCompress;
  logic [3:0]    uopq_uop_selImm;
  logic [1:0]    uopq_uop_fpu_typeTagOut;
  logic          uopq_uop_fpu_wflags;
  logic [1:0]    uopq_uop_fpu_typ;
  logic [1:0]    uopq_uop_fpu_fmt;
  logic [2:0]    uopq_uop_fpu_rm;
  logic          uopq_uop_vpu_vill;
  logic          uopq_uop_vpu_vma;
  logic          uopq_uop_vpu_vta;
  logic [1:0]    uopq_uop_vpu_vsew;
  logic [2:0]    uopq_uop_vpu_vlmul;
  logic          uopq_uop_vpu_specVill;
  logic          uopq_uop_vpu_specVma;
  logic          uopq_uop_vpu_specVta;
  logic [1:0]    uopq_uop_vpu_specVsew;
  logic [2:0]    uopq_uop_vpu_specVlmul;
  logic          uopq_uop_vpu_vm;
  logic [7:0]    uopq_uop_vpu_vstart;
  logic [2:0]    uopq_uop_vpu_frm;
  logic          uopq_uop_vpu_fpu_isFpToVecInst;
  logic          uopq_uop_vpu_fpu_isFP32Instr;
  logic          uopq_uop_vpu_fpu_isFP64Instr;
  logic          uopq_uop_vpu_fpu_isReduction;
  logic          uopq_uop_vpu_fpu_isFoldTo1_2;
  logic          uopq_uop_vpu_fpu_isFoldTo1_4;
  logic          uopq_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    uopq_uop_vpu_vxrm;
  logic [6:0]    uopq_uop_vpu_vuopIdx;
  logic          uopq_uop_vpu_lastUop;
  logic [127:0]  uopq_uop_vpu_vmask;
  logic [7:0]    uopq_uop_vpu_vl;
  logic [2:0]    uopq_uop_vpu_nf;
  logic [1:0]    uopq_uop_vpu_veew;
  logic          uopq_uop_vpu_isReverse;
  logic          uopq_uop_vpu_isExt;
  logic          uopq_uop_vpu_isNarrow;
  logic          uopq_uop_vpu_isDstMask;
  logic          uopq_uop_vpu_isOpMask;
  logic          uopq_uop_vpu_isMove;
  logic          uopq_uop_vpu_isDependOldVd;
  logic          uopq_uop_vpu_isWritePartVd;
  logic          uopq_uop_vpu_isVleff;
  logic          uopq_uop_vlsInstr;
  logic          uopq_uop_wfflags;
  logic          uopq_uop_isMove;
  logic          uopq_uop_isDropAmocasSta;
  logic [6:0]    uopq_uop_uopIdx;
  logic          uopq_uop_isVset;
  logic          uopq_uop_firstUop;
  logic          uopq_uop_lastUop;
  logic [6:0]    uopq_uop_numUops;
  logic [6:0]    uopq_uop_numWB;
  logic [2:0]    uopq_uop_commitType;
  logic          uopq_uop_srcState_0;
  logic          uopq_uop_srcState_1;
  logic          uopq_uop_srcState_2;
  logic          uopq_uop_srcState_3;
  logic          uopq_uop_srcState_4;
  logic [1:0]    uopq_uop_srcLoadDependency_0_0;
  logic [1:0]    uopq_uop_srcLoadDependency_0_1;
  logic [1:0]    uopq_uop_srcLoadDependency_0_2;
  logic [1:0]    uopq_uop_srcLoadDependency_1_0;
  logic [1:0]    uopq_uop_srcLoadDependency_1_1;
  logic [1:0]    uopq_uop_srcLoadDependency_1_2;
  logic [1:0]    uopq_uop_srcLoadDependency_2_0;
  logic [1:0]    uopq_uop_srcLoadDependency_2_1;
  logic [1:0]    uopq_uop_srcLoadDependency_2_2;
  logic [1:0]    uopq_uop_srcLoadDependency_3_0;
  logic [1:0]    uopq_uop_srcLoadDependency_3_1;
  logic [1:0]    uopq_uop_srcLoadDependency_3_2;
  logic [1:0]    uopq_uop_srcLoadDependency_4_0;
  logic [1:0]    uopq_uop_srcLoadDependency_4_1;
  logic [1:0]    uopq_uop_srcLoadDependency_4_2;
  logic [7:0]    uopq_uop_psrc_0;
  logic [7:0]    uopq_uop_psrc_1;
  logic [7:0]    uopq_uop_psrc_2;
  logic [7:0]    uopq_uop_psrc_3;
  logic [7:0]    uopq_uop_psrc_4;
  logic [7:0]    uopq_uop_pdest;
  logic          uopq_uop_useRegCache_0;
  logic          uopq_uop_useRegCache_1;
  logic [4:0]    uopq_uop_regCacheIdx_0;
  logic [4:0]    uopq_uop_regCacheIdx_1;
  logic          uopq_uop_robIdx_flag;
  logic [7:0]    uopq_uop_robIdx_value;
  logic [2:0]    uopq_uop_instrSize;
  logic          uopq_uop_dirtyFs;
  logic          uopq_uop_dirtyVs;
  logic [3:0]    uopq_uop_traceBlockInPipe_itype;
  logic [3:0]    uopq_uop_traceBlockInPipe_iretire;
  logic          uopq_uop_traceBlockInPipe_ilastsize;
  logic          uopq_uop_eliminatedMove;
  logic          uopq_uop_snapshot;
  logic          uopq_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_uop_debugInfo_renameTime;
  logic [63:0]   uopq_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_uop_debugInfo_selectTime;
  logic [63:0]   uopq_uop_debugInfo_issueTime;
  logic [63:0]   uopq_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_uop_debug_seqNum_uopIdx;
  logic          uopq_uop_storeSetHit;
  logic          uopq_uop_waitForRobIdx_flag;
  logic [7:0]    uopq_uop_waitForRobIdx_value;
  logic          uopq_uop_loadWaitBit;
  logic          uopq_uop_loadWaitStrict;
  logic [4:0]    uopq_uop_ssid;
  logic          uopq_uop_lqIdx_flag;
  logic [6:0]    uopq_uop_lqIdx_value;
  logic          uopq_uop_sqIdx_flag;
  logic [5:0]    uopq_uop_sqIdx_value;
  logic          uopq_uop_singleStep;
  logic          uopq_uop_replayInst;
  logic [34:0]   uopq_uop_debug_fuType;
  logic          uopq_uop_debug_sim_trig;
  logic [4:0]    uopq_uop_numLsElem;
  logic          uopq_preIsSplit;
  logic [3:0]    uopq_mBIndex;
  logic [2:0]    uopq_alignedType;
  logic [7:0]    uopq_indexVlMaxInVd;
  logic          uopq_usAligned128;
  logic [31:0]   uopq_usMask;
  logic          uopq_isVecPartReplay;
  logic [15:0]   uopq_vecReplayFlowMask;
  logic [3:0]    regOffset;
  always_ff @(posedge clock) begin
    if (doEnqueue) begin
      uopq_flowMask <= in.flowMask;
      uopq_data <= in.data;
      uopq_baseAddr <= in.baseAddr;
      uopq_uopAddr <= in.uopAddr;
      uopq_stride <= in.stride;
      uopq_flowNum <= in.flowNum;
      uopq_eew <= in.eew;
      uopq_sew <= in.sew;
      uopq_emul <= in.emul;
      uopq_lmul <= in.lmul;
      uopq_instType <= in.instType;
      uopq_indexedSplitOffset <= in.indexedSplitOffset;
      uopq_uop_instr <= in.uop.instr;
      uopq_uop_pc <= in.uop.pc;
      uopq_uop_foldpc <= in.uop.foldpc;
      uopq_uop_exceptionVec_7 <= in.uop.exceptionVec[7];
      uopq_uop_exceptionVec_15 <= in.uop.exceptionVec[15];
      uopq_uop_exceptionVec_19 <= in.uop.exceptionVec[19];
      uopq_uop_exceptionVec_23 <= in.uop.exceptionVec[23];
      uopq_uop_isFetchMalAddr <= in.uop.isFetchMalAddr;
      uopq_uop_hasException <= in.uop.hasException;
      uopq_uop_trigger <= in.uop.trigger;
      uopq_uop_preDecodeInfo_valid <= in.uop.preDecodeInfo_valid;
      uopq_uop_preDecodeInfo_isRVC <= in.uop.preDecodeInfo_isRVC;
      uopq_uop_preDecodeInfo_brType <= in.uop.preDecodeInfo_brType;
      uopq_uop_preDecodeInfo_isCall <= in.uop.preDecodeInfo_isCall;
      uopq_uop_preDecodeInfo_isRet <= in.uop.preDecodeInfo_isRet;
      uopq_uop_pred_taken <= in.uop.pred_taken;
      uopq_uop_crossPageIPFFix <= in.uop.crossPageIPFFix;
      uopq_uop_ftqPtr_flag <= in.uop.ftqPtr_flag;
      uopq_uop_ftqPtr_value <= in.uop.ftqPtr_value;
      uopq_uop_ftqOffset <= in.uop.ftqOffset;
      uopq_uop_satpFlushFirstFetchFault <= in.uop.satpFlushFirstFetchFault;
      uopq_uop_srcType_0 <= in.uop.srcType_0;
      uopq_uop_srcType_1 <= in.uop.srcType_1;
      uopq_uop_srcType_2 <= in.uop.srcType_2;
      uopq_uop_srcType_3 <= in.uop.srcType_3;
      uopq_uop_srcType_4 <= in.uop.srcType_4;
      uopq_uop_ldest <= in.uop.ldest;
      uopq_uop_fuType <= in.uop.fuType;
      uopq_uop_fuOpType <= in.uop.fuOpType;
      uopq_uop_rfWen <= in.uop.rfWen;
      uopq_uop_fpWen <= in.uop.fpWen;
      uopq_uop_vecWen <= in.uop.vecWen;
      uopq_uop_v0Wen <= in.uop.v0Wen;
      uopq_uop_vlWen <= in.uop.vlWen;
      uopq_uop_isXSTrap <= in.uop.isXSTrap;
      uopq_uop_waitForward <= in.uop.waitForward;
      uopq_uop_blockBackward <= in.uop.blockBackward;
      uopq_uop_canRobCompress <= in.uop.canRobCompress;
      uopq_uop_selImm <= in.uop.selImm;
      uopq_uop_fpu_typeTagOut <= in.uop.fpu_typeTagOut;
      uopq_uop_fpu_wflags <= in.uop.fpu_wflags;
      uopq_uop_fpu_typ <= in.uop.fpu_typ;
      uopq_uop_fpu_fmt <= in.uop.fpu_fmt;
      uopq_uop_fpu_rm <= in.uop.fpu_rm;
      uopq_uop_vpu_vill <= in.uop.vpu_vill;
      uopq_uop_vpu_vma <= in.uop.vpu_vma;
      uopq_uop_vpu_vta <= in.uop.vpu_vta;
      uopq_uop_vpu_vsew <= in.uop.vpu_vsew;
      uopq_uop_vpu_vlmul <= in.uop.vpu_vlmul;
      uopq_uop_vpu_specVill <= in.uop.vpu_specVill;
      uopq_uop_vpu_specVma <= in.uop.vpu_specVma;
      uopq_uop_vpu_specVta <= in.uop.vpu_specVta;
      uopq_uop_vpu_specVsew <= in.uop.vpu_specVsew;
      uopq_uop_vpu_specVlmul <= in.uop.vpu_specVlmul;
      uopq_uop_vpu_vm <= in.uop.vpu_vm;
      uopq_uop_vpu_vstart <= in.uop.vpu_vstart;
      uopq_uop_vpu_frm <= in.uop.vpu_frm;
      uopq_uop_vpu_fpu_isFpToVecInst <= in.uop.vpu_fpu_isFpToVecInst;
      uopq_uop_vpu_fpu_isFP32Instr <= in.uop.vpu_fpu_isFP32Instr;
      uopq_uop_vpu_fpu_isFP64Instr <= in.uop.vpu_fpu_isFP64Instr;
      uopq_uop_vpu_fpu_isReduction <= in.uop.vpu_fpu_isReduction;
      uopq_uop_vpu_fpu_isFoldTo1_2 <= in.uop.vpu_fpu_isFoldTo1_2;
      uopq_uop_vpu_fpu_isFoldTo1_4 <= in.uop.vpu_fpu_isFoldTo1_4;
      uopq_uop_vpu_fpu_isFoldTo1_8 <= in.uop.vpu_fpu_isFoldTo1_8;
      uopq_uop_vpu_vxrm <= in.uop.vpu_vxrm;
      uopq_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_uop_vpu_lastUop <= in.uop.vpu_lastUop;
      uopq_uop_vpu_vmask <= in.uop.vpu_vmask;
      uopq_uop_vpu_vl <= in.uop.vpu_vl;
      uopq_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_uop_vpu_isReverse <= in.uop.vpu_isReverse;
      uopq_uop_vpu_isExt <= in.uop.vpu_isExt;
      uopq_uop_vpu_isNarrow <= in.uop.vpu_isNarrow;
      uopq_uop_vpu_isDstMask <= in.uop.vpu_isDstMask;
      uopq_uop_vpu_isOpMask <= in.uop.vpu_isOpMask;
      uopq_uop_vpu_isMove <= in.uop.vpu_isMove;
      uopq_uop_vpu_isDependOldVd <= in.uop.vpu_isDependOldVd;
      uopq_uop_vpu_isWritePartVd <= in.uop.vpu_isWritePartVd;
      uopq_uop_vpu_isVleff <= in.uop.vpu_isVleff;
      uopq_uop_vlsInstr <= in.uop.vlsInstr;
      uopq_uop_wfflags <= in.uop.wfflags;
      uopq_uop_isMove <= in.uop.isMove;
      uopq_uop_isDropAmocasSta <= in.uop.isDropAmocasSta;
      uopq_uop_uopIdx <= in.uop.uopIdx;
      uopq_uop_isVset <= in.uop.isVset;
      uopq_uop_firstUop <= in.uop.firstUop;
      uopq_uop_lastUop <= in.uop.lastUop;
      uopq_uop_numUops <= in.uop.numUops;
      uopq_uop_numWB <= in.uop.numWB;
      uopq_uop_commitType <= in.uop.commitType;
      uopq_uop_srcState_0 <= in.uop.srcState_0;
      uopq_uop_srcState_1 <= in.uop.srcState_1;
      uopq_uop_srcState_2 <= in.uop.srcState_2;
      uopq_uop_srcState_3 <= in.uop.srcState_3;
      uopq_uop_srcState_4 <= in.uop.srcState_4;
      uopq_uop_srcLoadDependency_0_0 <= in.uop.srcLoadDependency_0_0;
      uopq_uop_srcLoadDependency_0_1 <= in.uop.srcLoadDependency_0_1;
      uopq_uop_srcLoadDependency_0_2 <= in.uop.srcLoadDependency_0_2;
      uopq_uop_srcLoadDependency_1_0 <= in.uop.srcLoadDependency_1_0;
      uopq_uop_srcLoadDependency_1_1 <= in.uop.srcLoadDependency_1_1;
      uopq_uop_srcLoadDependency_1_2 <= in.uop.srcLoadDependency_1_2;
      uopq_uop_srcLoadDependency_2_0 <= in.uop.srcLoadDependency_2_0;
      uopq_uop_srcLoadDependency_2_1 <= in.uop.srcLoadDependency_2_1;
      uopq_uop_srcLoadDependency_2_2 <= in.uop.srcLoadDependency_2_2;
      uopq_uop_srcLoadDependency_3_0 <= in.uop.srcLoadDependency_3_0;
      uopq_uop_srcLoadDependency_3_1 <= in.uop.srcLoadDependency_3_1;
      uopq_uop_srcLoadDependency_3_2 <= in.uop.srcLoadDependency_3_2;
      uopq_uop_srcLoadDependency_4_0 <= in.uop.srcLoadDependency_4_0;
      uopq_uop_srcLoadDependency_4_1 <= in.uop.srcLoadDependency_4_1;
      uopq_uop_srcLoadDependency_4_2 <= in.uop.srcLoadDependency_4_2;
      uopq_uop_psrc_0 <= in.uop.psrc_0;
      uopq_uop_psrc_1 <= in.uop.psrc_1;
      uopq_uop_psrc_2 <= in.uop.psrc_2;
      uopq_uop_psrc_3 <= in.uop.psrc_3;
      uopq_uop_psrc_4 <= in.uop.psrc_4;
      uopq_uop_pdest <= in.uop.pdest;
      uopq_uop_useRegCache_0 <= in.uop.useRegCache_0;
      uopq_uop_useRegCache_1 <= in.uop.useRegCache_1;
      uopq_uop_regCacheIdx_0 <= in.uop.regCacheIdx_0;
      uopq_uop_regCacheIdx_1 <= in.uop.regCacheIdx_1;
      uopq_uop_robIdx_flag <= in.uop.robIdx_flag;
      uopq_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_uop_instrSize <= in.uop.instrSize;
      uopq_uop_dirtyFs <= in.uop.dirtyFs;
      uopq_uop_dirtyVs <= in.uop.dirtyVs;
      uopq_uop_traceBlockInPipe_itype <= in.uop.traceBlockInPipe_itype;
      uopq_uop_traceBlockInPipe_iretire <= in.uop.traceBlockInPipe_iretire;
      uopq_uop_traceBlockInPipe_ilastsize <= in.uop.traceBlockInPipe_ilastsize;
      uopq_uop_eliminatedMove <= in.uop.eliminatedMove;
      uopq_uop_snapshot <= in.uop.snapshot;
      uopq_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_uop_storeSetHit <= in.uop.storeSetHit;
      uopq_uop_waitForRobIdx_flag <= in.uop.waitForRobIdx_flag;
      uopq_uop_waitForRobIdx_value <= in.uop.waitForRobIdx_value;
      uopq_uop_loadWaitBit <= in.uop.loadWaitBit;
      uopq_uop_loadWaitStrict <= in.uop.loadWaitStrict;
      uopq_uop_ssid <= in.uop.ssid;
      uopq_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_uop_sqIdx_value <= in.uop.sqIdx_value;
      uopq_uop_singleStep <= in.uop.singleStep;
      uopq_uop_replayInst <= in.uop.replayInst;
      uopq_uop_debug_fuType <= in.uop.debug_fuType;
      uopq_uop_debug_sim_trig <= in.uop.debug_sim_trig;
      uopq_uop_numLsElem <= in.uop.numLsElem;
      uopq_preIsSplit <= in.preIsSplit;
      uopq_mBIndex <= in.mBIndex;
      uopq_alignedType <= in.alignedType;
      uopq_indexVlMaxInVd <= in.indexVlMaxInVd;
      uopq_usAligned128 <= in.usAligned128;
      uopq_usMask <= in.usMask;
      uopq_isVecPartReplay <= in.isVecPartReplay;
      uopq_vecReplayFlowMask <= in.vecReplayFlowMask;
      regOffset <= in.usLowBitsAddr;
    end
  end
  always_comb begin
    uopq = '0;
    uopq.flowMask = uopq_flowMask;
    uopq.data = uopq_data;
    uopq.baseAddr = uopq_baseAddr;
    uopq.uopAddr = uopq_uopAddr;
    uopq.stride = uopq_stride;
    uopq.flowNum = uopq_flowNum;
    uopq.eew = uopq_eew;
    uopq.sew = uopq_sew;
    uopq.emul = uopq_emul;
    uopq.lmul = uopq_lmul;
    uopq.instType = uopq_instType;
    uopq.indexedSplitOffset = uopq_indexedSplitOffset;
    uopq.uop.instr = uopq_uop_instr;
    uopq.uop.pc = uopq_uop_pc;
    uopq.uop.foldpc = uopq_uop_foldpc;
    uopq.uop.exceptionVec[7] = uopq_uop_exceptionVec_7;
    uopq.uop.exceptionVec[15] = uopq_uop_exceptionVec_15;
    uopq.uop.exceptionVec[19] = uopq_uop_exceptionVec_19;
    uopq.uop.exceptionVec[23] = uopq_uop_exceptionVec_23;
    uopq.uop.isFetchMalAddr = uopq_uop_isFetchMalAddr;
    uopq.uop.hasException = uopq_uop_hasException;
    uopq.uop.trigger = uopq_uop_trigger;
    uopq.uop.preDecodeInfo_valid = uopq_uop_preDecodeInfo_valid;
    uopq.uop.preDecodeInfo_isRVC = uopq_uop_preDecodeInfo_isRVC;
    uopq.uop.preDecodeInfo_brType = uopq_uop_preDecodeInfo_brType;
    uopq.uop.preDecodeInfo_isCall = uopq_uop_preDecodeInfo_isCall;
    uopq.uop.preDecodeInfo_isRet = uopq_uop_preDecodeInfo_isRet;
    uopq.uop.pred_taken = uopq_uop_pred_taken;
    uopq.uop.crossPageIPFFix = uopq_uop_crossPageIPFFix;
    uopq.uop.ftqPtr_flag = uopq_uop_ftqPtr_flag;
    uopq.uop.ftqPtr_value = uopq_uop_ftqPtr_value;
    uopq.uop.ftqOffset = uopq_uop_ftqOffset;
    uopq.uop.satpFlushFirstFetchFault = uopq_uop_satpFlushFirstFetchFault;
    uopq.uop.srcType_0 = uopq_uop_srcType_0;
    uopq.uop.srcType_1 = uopq_uop_srcType_1;
    uopq.uop.srcType_2 = uopq_uop_srcType_2;
    uopq.uop.srcType_3 = uopq_uop_srcType_3;
    uopq.uop.srcType_4 = uopq_uop_srcType_4;
    uopq.uop.ldest = uopq_uop_ldest;
    uopq.uop.fuType = uopq_uop_fuType;
    uopq.uop.fuOpType = uopq_uop_fuOpType;
    uopq.uop.rfWen = uopq_uop_rfWen;
    uopq.uop.fpWen = uopq_uop_fpWen;
    uopq.uop.vecWen = uopq_uop_vecWen;
    uopq.uop.v0Wen = uopq_uop_v0Wen;
    uopq.uop.vlWen = uopq_uop_vlWen;
    uopq.uop.isXSTrap = uopq_uop_isXSTrap;
    uopq.uop.waitForward = uopq_uop_waitForward;
    uopq.uop.blockBackward = uopq_uop_blockBackward;
    uopq.uop.canRobCompress = uopq_uop_canRobCompress;
    uopq.uop.selImm = uopq_uop_selImm;
    uopq.uop.fpu_typeTagOut = uopq_uop_fpu_typeTagOut;
    uopq.uop.fpu_wflags = uopq_uop_fpu_wflags;
    uopq.uop.fpu_typ = uopq_uop_fpu_typ;
    uopq.uop.fpu_fmt = uopq_uop_fpu_fmt;
    uopq.uop.fpu_rm = uopq_uop_fpu_rm;
    uopq.uop.vpu_vill = uopq_uop_vpu_vill;
    uopq.uop.vpu_vma = uopq_uop_vpu_vma;
    uopq.uop.vpu_vta = uopq_uop_vpu_vta;
    uopq.uop.vpu_vsew = uopq_uop_vpu_vsew;
    uopq.uop.vpu_vlmul = uopq_uop_vpu_vlmul;
    uopq.uop.vpu_specVill = uopq_uop_vpu_specVill;
    uopq.uop.vpu_specVma = uopq_uop_vpu_specVma;
    uopq.uop.vpu_specVta = uopq_uop_vpu_specVta;
    uopq.uop.vpu_specVsew = uopq_uop_vpu_specVsew;
    uopq.uop.vpu_specVlmul = uopq_uop_vpu_specVlmul;
    uopq.uop.vpu_vm = uopq_uop_vpu_vm;
    uopq.uop.vpu_vstart = uopq_uop_vpu_vstart;
    uopq.uop.vpu_frm = uopq_uop_vpu_frm;
    uopq.uop.vpu_fpu_isFpToVecInst = uopq_uop_vpu_fpu_isFpToVecInst;
    uopq.uop.vpu_fpu_isFP32Instr = uopq_uop_vpu_fpu_isFP32Instr;
    uopq.uop.vpu_fpu_isFP64Instr = uopq_uop_vpu_fpu_isFP64Instr;
    uopq.uop.vpu_fpu_isReduction = uopq_uop_vpu_fpu_isReduction;
    uopq.uop.vpu_fpu_isFoldTo1_2 = uopq_uop_vpu_fpu_isFoldTo1_2;
    uopq.uop.vpu_fpu_isFoldTo1_4 = uopq_uop_vpu_fpu_isFoldTo1_4;
    uopq.uop.vpu_fpu_isFoldTo1_8 = uopq_uop_vpu_fpu_isFoldTo1_8;
    uopq.uop.vpu_vxrm = uopq_uop_vpu_vxrm;
    uopq.uop.vpu_vuopIdx = uopq_uop_vpu_vuopIdx;
    uopq.uop.vpu_lastUop = uopq_uop_vpu_lastUop;
    uopq.uop.vpu_vmask = uopq_uop_vpu_vmask;
    uopq.uop.vpu_vl = uopq_uop_vpu_vl;
    uopq.uop.vpu_nf = uopq_uop_vpu_nf;
    uopq.uop.vpu_veew = uopq_uop_vpu_veew;
    uopq.uop.vpu_isReverse = uopq_uop_vpu_isReverse;
    uopq.uop.vpu_isExt = uopq_uop_vpu_isExt;
    uopq.uop.vpu_isNarrow = uopq_uop_vpu_isNarrow;
    uopq.uop.vpu_isDstMask = uopq_uop_vpu_isDstMask;
    uopq.uop.vpu_isOpMask = uopq_uop_vpu_isOpMask;
    uopq.uop.vpu_isMove = uopq_uop_vpu_isMove;
    uopq.uop.vpu_isDependOldVd = uopq_uop_vpu_isDependOldVd;
    uopq.uop.vpu_isWritePartVd = uopq_uop_vpu_isWritePartVd;
    uopq.uop.vpu_isVleff = uopq_uop_vpu_isVleff;
    uopq.uop.vlsInstr = uopq_uop_vlsInstr;
    uopq.uop.wfflags = uopq_uop_wfflags;
    uopq.uop.isMove = uopq_uop_isMove;
    uopq.uop.isDropAmocasSta = uopq_uop_isDropAmocasSta;
    uopq.uop.uopIdx = uopq_uop_uopIdx;
    uopq.uop.isVset = uopq_uop_isVset;
    uopq.uop.firstUop = uopq_uop_firstUop;
    uopq.uop.lastUop = uopq_uop_lastUop;
    uopq.uop.numUops = uopq_uop_numUops;
    uopq.uop.numWB = uopq_uop_numWB;
    uopq.uop.commitType = uopq_uop_commitType;
    uopq.uop.srcState_0 = uopq_uop_srcState_0;
    uopq.uop.srcState_1 = uopq_uop_srcState_1;
    uopq.uop.srcState_2 = uopq_uop_srcState_2;
    uopq.uop.srcState_3 = uopq_uop_srcState_3;
    uopq.uop.srcState_4 = uopq_uop_srcState_4;
    uopq.uop.srcLoadDependency_0_0 = uopq_uop_srcLoadDependency_0_0;
    uopq.uop.srcLoadDependency_0_1 = uopq_uop_srcLoadDependency_0_1;
    uopq.uop.srcLoadDependency_0_2 = uopq_uop_srcLoadDependency_0_2;
    uopq.uop.srcLoadDependency_1_0 = uopq_uop_srcLoadDependency_1_0;
    uopq.uop.srcLoadDependency_1_1 = uopq_uop_srcLoadDependency_1_1;
    uopq.uop.srcLoadDependency_1_2 = uopq_uop_srcLoadDependency_1_2;
    uopq.uop.srcLoadDependency_2_0 = uopq_uop_srcLoadDependency_2_0;
    uopq.uop.srcLoadDependency_2_1 = uopq_uop_srcLoadDependency_2_1;
    uopq.uop.srcLoadDependency_2_2 = uopq_uop_srcLoadDependency_2_2;
    uopq.uop.srcLoadDependency_3_0 = uopq_uop_srcLoadDependency_3_0;
    uopq.uop.srcLoadDependency_3_1 = uopq_uop_srcLoadDependency_3_1;
    uopq.uop.srcLoadDependency_3_2 = uopq_uop_srcLoadDependency_3_2;
    uopq.uop.srcLoadDependency_4_0 = uopq_uop_srcLoadDependency_4_0;
    uopq.uop.srcLoadDependency_4_1 = uopq_uop_srcLoadDependency_4_1;
    uopq.uop.srcLoadDependency_4_2 = uopq_uop_srcLoadDependency_4_2;
    uopq.uop.psrc_0 = uopq_uop_psrc_0;
    uopq.uop.psrc_1 = uopq_uop_psrc_1;
    uopq.uop.psrc_2 = uopq_uop_psrc_2;
    uopq.uop.psrc_3 = uopq_uop_psrc_3;
    uopq.uop.psrc_4 = uopq_uop_psrc_4;
    uopq.uop.pdest = uopq_uop_pdest;
    uopq.uop.useRegCache_0 = uopq_uop_useRegCache_0;
    uopq.uop.useRegCache_1 = uopq_uop_useRegCache_1;
    uopq.uop.regCacheIdx_0 = uopq_uop_regCacheIdx_0;
    uopq.uop.regCacheIdx_1 = uopq_uop_regCacheIdx_1;
    uopq.uop.robIdx_flag = uopq_uop_robIdx_flag;
    uopq.uop.robIdx_value = uopq_uop_robIdx_value;
    uopq.uop.instrSize = uopq_uop_instrSize;
    uopq.uop.dirtyFs = uopq_uop_dirtyFs;
    uopq.uop.dirtyVs = uopq_uop_dirtyVs;
    uopq.uop.traceBlockInPipe_itype = uopq_uop_traceBlockInPipe_itype;
    uopq.uop.traceBlockInPipe_iretire = uopq_uop_traceBlockInPipe_iretire;
    uopq.uop.traceBlockInPipe_ilastsize = uopq_uop_traceBlockInPipe_ilastsize;
    uopq.uop.eliminatedMove = uopq_uop_eliminatedMove;
    uopq.uop.snapshot = uopq_uop_snapshot;
    uopq.uop.debugInfo_eliminatedMove = uopq_uop_debugInfo_eliminatedMove;
    uopq.uop.debugInfo_renameTime = uopq_uop_debugInfo_renameTime;
    uopq.uop.debugInfo_dispatchTime = uopq_uop_debugInfo_dispatchTime;
    uopq.uop.debugInfo_enqRsTime = uopq_uop_debugInfo_enqRsTime;
    uopq.uop.debugInfo_selectTime = uopq_uop_debugInfo_selectTime;
    uopq.uop.debugInfo_issueTime = uopq_uop_debugInfo_issueTime;
    uopq.uop.debugInfo_writebackTime = uopq_uop_debugInfo_writebackTime;
    uopq.uop.debugInfo_runahead_checkpoint_id = uopq_uop_debugInfo_runahead_checkpoint_id;
    uopq.uop.debugInfo_tlbFirstReqTime = uopq_uop_debugInfo_tlbFirstReqTime;
    uopq.uop.debugInfo_tlbRespTime = uopq_uop_debugInfo_tlbRespTime;
    uopq.uop.debug_seqNum_seqNum = uopq_uop_debug_seqNum_seqNum;
    uopq.uop.debug_seqNum_uopIdx = uopq_uop_debug_seqNum_uopIdx;
    uopq.uop.storeSetHit = uopq_uop_storeSetHit;
    uopq.uop.waitForRobIdx_flag = uopq_uop_waitForRobIdx_flag;
    uopq.uop.waitForRobIdx_value = uopq_uop_waitForRobIdx_value;
    uopq.uop.loadWaitBit = uopq_uop_loadWaitBit;
    uopq.uop.loadWaitStrict = uopq_uop_loadWaitStrict;
    uopq.uop.ssid = uopq_uop_ssid;
    uopq.uop.lqIdx_flag = uopq_uop_lqIdx_flag;
    uopq.uop.lqIdx_value = uopq_uop_lqIdx_value;
    uopq.uop.sqIdx_flag = uopq_uop_sqIdx_flag;
    uopq.uop.sqIdx_value = uopq_uop_sqIdx_value;
    uopq.uop.singleStep = uopq_uop_singleStep;
    uopq.uop.replayInst = uopq_uop_replayInst;
    uopq.uop.debug_fuType = uopq_uop_debug_fuType;
    uopq.uop.debug_sim_trig = uopq_uop_debug_sim_trig;
    uopq.uop.numLsElem = uopq_uop_numLsElem;
    uopq.preIsSplit = uopq_preIsSplit;
    uopq.mBIndex = uopq_mBIndex;
    uopq.alignedType = uopq_alignedType;
    uopq.indexVlMaxInVd = uopq_indexVlMaxInVd;
    uopq.usAligned128 = uopq_usAligned128;
    uopq.usMask = uopq_usMask;
    uopq.isVecPartReplay = uopq_isVecPartReplay;
    uopq.vecReplayFlowMask = uopq_vecReplayFlowMask;
    uopq.usLowBitsAddr = regOffset;
  end

  xs_VSplitBuffer_core #(.IS_VSTORE(1'b1)) u_core (
    .clock                                        (clock),
    .reset                                        (reset),
    .redirect_valid                               (io_redirect_valid),
    .redirect_bits_robIdx_flag                    (io_redirect_bits_robIdx_flag),
    .redirect_bits_robIdx_value                   (io_redirect_bits_robIdx_value),
    .redirect_bits_level                          (io_redirect_bits_level),
    .in_ready                                     (io_in_ready),
    .in_valid                                     (io_in_valid),
    .in                                           (in),
    .out_ready                                    (io_out_ready),
    .out_valid                                    (io_out_valid),
    .out                                          (out),
    .fromPipeline_0_valid                         ('0),
    .fromPipeline_0_bits_mBIndex                  ('0),
    .fromPipeline_1_valid                         ('0),
    .fromPipeline_1_bits_mBIndex                  ('0),
    .fromPipeline_2_valid                         ('0),
    .fromPipeline_2_bits_mBIndex                  ('0),
    .vstd_valid                                   (io_vstd_valid),
    .vstd                                         (vstd),
    .vstdMisalign_storeMisalignBufferEmpty        (io_vstdMisalign_storeMisalignBufferEmpty),
    .vstdMisalign_scalaIssueValid                 (io_vstdMisalign_scalaIssueValid),
    .vstdMisalign_scalaIssueRobIdx_flag           (io_vstdMisalign_scalaIssueRobIdx_flag),
    .vstdMisalign_scalaIssueRobIdx_value          (io_vstdMisalign_scalaIssueRobIdx_value),
    .vstdMisalign_sqDeqIsVec                      (io_vstdMisalign_sqDeqIsVec),
    .doEnqueue                                    (doEnqueue),
    .uopq                                         (uopq)
  );

endmodule
// END GENERATED(wrapper_VSSplitBufferImp)
