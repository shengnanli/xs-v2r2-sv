// =====================================================================
// VSSplitImp.sv —— 向量 store 拆分单元的装配壳（VSplitImp 家族的 store 变体薄文件）
// ---------------------------------------------------------------------
// 胶水核 xs_VSplitImp_core 在 VLSplitImp.sv（结构与机制讲解在那里）。
// 本变体与 load 变体的差别只在子模块与多出来的直通口：
//   · 子模块是 VSSplitPipelineImp / VSSplitBufferImp（skid 缓冲同为 skidBufferConnect）；
//   · 多一路 vstd（元素数据送 store queue）和 vstdMisalign 四根输入（store 非对齐缓冲的状态），
//     都直通拆分缓冲；没有 fromPipeline。
// 规模：335 个端口，本层无寄存器；连线由 scripts/gen_vsplit.py 照 golden 的例化块生成。
// =====================================================================
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分；行号由 scripts/gen_vsplit.py 维护）：
// BEGIN GENERATED(nav) —— scripts/gen_vsplit.py 生成，勿手改
//   L21    VSSplitImp wrapper（生成）
//   L363   子模块输出线声明
//   L639   胶水核例化
//   L654   splitPipeline 例化
//   L901   splitBuffer 例化
//   L1275  VSSplitSkidBuffer 例化
// END GENERATED(nav)
// =====================================================================
// VSSplitImp —— golden 同名 wrapper（store 变体，生成）：子模块例化与连线
// =====================================================================
// BEGIN GENERATED(wrapper_VSSplitImp) —— scripts/gen_vsplit.py 生成，勿手改
module VSSplitImp
(
  input          clock,
  input          reset,
  input          io_redirect_valid,
  input          io_redirect_bits_robIdx_flag,
  input  [7:0]   io_redirect_bits_robIdx_value,
  input          io_redirect_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [49:0]  io_in_bits_uop_pc,
  input          io_in_bits_uop_ftqPtr_flag,
  input  [5:0]   io_in_bits_uop_ftqPtr_value,
  input  [3:0]   io_in_bits_uop_ftqOffset,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
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
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
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
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [4:0]   io_in_bits_uop_numLsElem,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  input  [4:0]   io_in_bits_flowNum,
  input          io_in_bits_isVecPartReplay,
  input  [15:0]  io_in_bits_vecReplayMask,
  input  [3:0]   io_in_bits_vecReplayMbIdx,
  input          io_toMergeBuffer_req_ready,
  output         io_toMergeBuffer_req_valid,
  output [15:0]  io_toMergeBuffer_req_bits_mask,
  output [49:0]  io_toMergeBuffer_req_bits_vaddr,
  output [4:0]   io_toMergeBuffer_req_bits_flowNum,
  output [8:0]   io_toMergeBuffer_req_bits_uop_fuOpType,
  output         io_toMergeBuffer_req_bits_uop_vecWen,
  output         io_toMergeBuffer_req_bits_uop_v0Wen,
  output         io_toMergeBuffer_req_bits_uop_vlWen,
  output         io_toMergeBuffer_req_bits_uop_vpu_vill,
  output         io_toMergeBuffer_req_bits_uop_vpu_vma,
  output         io_toMergeBuffer_req_bits_uop_vpu_vta,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_vsew,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_vlmul,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVill,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVma,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVta,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_specVsew,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_specVlmul,
  output         io_toMergeBuffer_req_bits_uop_vpu_vm,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_frm,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_vxrm,
  output [6:0]   io_toMergeBuffer_req_bits_uop_vpu_vuopIdx,
  output         io_toMergeBuffer_req_bits_uop_vpu_lastUop,
  output [127:0] io_toMergeBuffer_req_bits_uop_vpu_vmask,
  output [7:0]   io_toMergeBuffer_req_bits_uop_vpu_vl,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_nf,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_veew,
  output         io_toMergeBuffer_req_bits_uop_vpu_isReverse,
  output         io_toMergeBuffer_req_bits_uop_vpu_isExt,
  output         io_toMergeBuffer_req_bits_uop_vpu_isNarrow,
  output         io_toMergeBuffer_req_bits_uop_vpu_isDstMask,
  output         io_toMergeBuffer_req_bits_uop_vpu_isOpMask,
  output         io_toMergeBuffer_req_bits_uop_vpu_isMove,
  output         io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd,
  output         io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd,
  output         io_toMergeBuffer_req_bits_uop_vpu_isVleff,
  output [6:0]   io_toMergeBuffer_req_bits_uop_uopIdx,
  output [7:0]   io_toMergeBuffer_req_bits_uop_pdest,
  output         io_toMergeBuffer_req_bits_uop_robIdx_flag,
  output [7:0]   io_toMergeBuffer_req_bits_uop_robIdx_value,
  output         io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_renameTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_selectTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_issueTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx,
  output         io_toMergeBuffer_req_bits_uop_lqIdx_flag,
  output [6:0]   io_toMergeBuffer_req_bits_uop_lqIdx_value,
  output         io_toMergeBuffer_req_bits_uop_sqIdx_flag,
  output [5:0]   io_toMergeBuffer_req_bits_uop_sqIdx_value,
  output [7:0]   io_toMergeBuffer_req_bits_vlmax,
  input          io_toMergeBuffer_resp_valid,
  input  [3:0]   io_toMergeBuffer_resp_bits_mBIndex,
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
  input          io_vstdMisalign_sqDeqIsVec,
  input          io_threshold_valid,
  input          io_threshold_bits_robIdx_flag,
  input  [7:0]   io_threshold_bits_robIdx_value,
  input  [6:0]   io_threshold_bits_uopIdx
);

  // ---- 子模块输出线（<实例名>_<端口名>）----
  logic          splitPipeline_io_out_valid;
  logic [15:0]   splitPipeline_io_out_bits_flowMask;
  logic [127:0]  splitPipeline_io_out_bits_data;
  logic [63:0]   splitPipeline_io_out_bits_baseAddr;
  logic [63:0]   splitPipeline_io_out_bits_uopAddr;
  logic [127:0]  splitPipeline_io_out_bits_stride;
  logic [4:0]    splitPipeline_io_out_bits_flowNum;
  logic [1:0]    splitPipeline_io_out_bits_eew;
  logic [2:0]    splitPipeline_io_out_bits_sew;
  logic [2:0]    splitPipeline_io_out_bits_emul;
  logic [2:0]    splitPipeline_io_out_bits_lmul;
  logic [2:0]    splitPipeline_io_out_bits_instType;
  logic [4:0]    splitPipeline_io_out_bits_indexedSplitOffset;
  logic [49:0]   splitPipeline_io_out_bits_uop_pc;
  logic          splitPipeline_io_out_bits_uop_ftqPtr_flag;
  logic [5:0]    splitPipeline_io_out_bits_uop_ftqPtr_value;
  logic [3:0]    splitPipeline_io_out_bits_uop_ftqOffset;
  logic [34:0]   splitPipeline_io_out_bits_uop_fuType;
  logic [8:0]    splitPipeline_io_out_bits_uop_fuOpType;
  logic          splitPipeline_io_out_bits_uop_vecWen;
  logic          splitPipeline_io_out_bits_uop_v0Wen;
  logic          splitPipeline_io_out_bits_uop_vlWen;
  logic          splitPipeline_io_out_bits_uop_vpu_vill;
  logic          splitPipeline_io_out_bits_uop_vpu_vma;
  logic          splitPipeline_io_out_bits_uop_vpu_vta;
  logic [1:0]    splitPipeline_io_out_bits_uop_vpu_vsew;
  logic [2:0]    splitPipeline_io_out_bits_uop_vpu_vlmul;
  logic          splitPipeline_io_out_bits_uop_vpu_specVill;
  logic          splitPipeline_io_out_bits_uop_vpu_specVma;
  logic          splitPipeline_io_out_bits_uop_vpu_specVta;
  logic [1:0]    splitPipeline_io_out_bits_uop_vpu_specVsew;
  logic [2:0]    splitPipeline_io_out_bits_uop_vpu_specVlmul;
  logic          splitPipeline_io_out_bits_uop_vpu_vm;
  logic [7:0]    splitPipeline_io_out_bits_uop_vpu_vstart;
  logic [2:0]    splitPipeline_io_out_bits_uop_vpu_frm;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isFpToVecInst;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isFP32Instr;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isFP64Instr;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isReduction;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
  logic          splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    splitPipeline_io_out_bits_uop_vpu_vxrm;
  logic [6:0]    splitPipeline_io_out_bits_uop_vpu_vuopIdx;
  logic          splitPipeline_io_out_bits_uop_vpu_lastUop;
  logic [127:0]  splitPipeline_io_out_bits_uop_vpu_vmask;
  logic [7:0]    splitPipeline_io_out_bits_uop_vpu_vl;
  logic [2:0]    splitPipeline_io_out_bits_uop_vpu_nf;
  logic [1:0]    splitPipeline_io_out_bits_uop_vpu_veew;
  logic          splitPipeline_io_out_bits_uop_vpu_isReverse;
  logic          splitPipeline_io_out_bits_uop_vpu_isExt;
  logic          splitPipeline_io_out_bits_uop_vpu_isNarrow;
  logic          splitPipeline_io_out_bits_uop_vpu_isDstMask;
  logic          splitPipeline_io_out_bits_uop_vpu_isOpMask;
  logic          splitPipeline_io_out_bits_uop_vpu_isMove;
  logic          splitPipeline_io_out_bits_uop_vpu_isDependOldVd;
  logic          splitPipeline_io_out_bits_uop_vpu_isWritePartVd;
  logic          splitPipeline_io_out_bits_uop_vpu_isVleff;
  logic [6:0]    splitPipeline_io_out_bits_uop_uopIdx;
  logic          splitPipeline_io_out_bits_uop_lastUop;
  logic [6:0]    splitPipeline_io_out_bits_uop_numUops;
  logic [7:0]    splitPipeline_io_out_bits_uop_pdest;
  logic          splitPipeline_io_out_bits_uop_robIdx_flag;
  logic [7:0]    splitPipeline_io_out_bits_uop_robIdx_value;
  logic          splitPipeline_io_out_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_renameTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_selectTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_issueTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_writebackTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   splitPipeline_io_out_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   splitPipeline_io_out_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    splitPipeline_io_out_bits_uop_debug_seqNum_uopIdx;
  logic          splitPipeline_io_out_bits_uop_lqIdx_flag;
  logic [6:0]    splitPipeline_io_out_bits_uop_lqIdx_value;
  logic          splitPipeline_io_out_bits_uop_sqIdx_flag;
  logic [5:0]    splitPipeline_io_out_bits_uop_sqIdx_value;
  logic [4:0]    splitPipeline_io_out_bits_uop_numLsElem;
  logic          splitPipeline_io_out_bits_preIsSplit;
  logic [3:0]    splitPipeline_io_out_bits_mBIndex;
  logic [2:0]    splitPipeline_io_out_bits_alignedType;
  logic [7:0]    splitPipeline_io_out_bits_indexVlMaxInVd;
  logic [3:0]    splitPipeline_io_out_bits_usLowBitsAddr;
  logic          splitPipeline_io_out_bits_usAligned128;
  logic [31:0]   splitPipeline_io_out_bits_usMask;
  logic          splitPipeline_io_out_bits_isVecPartReplay;
  logic [15:0]   splitPipeline_io_out_bits_vecReplayFlowMask;
  logic          splitBuffer_io_in_ready;
  logic          splitBuffer_io_out_valid;
  logic          VSSplitSkidBuffer_io_in_ready;
  logic          VSSplitSkidBuffer_io_out_valid;
  logic [15:0]   VSSplitSkidBuffer_io_out_bits_flowMask;
  logic [127:0]  VSSplitSkidBuffer_io_out_bits_data;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_baseAddr;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uopAddr;
  logic [127:0]  VSSplitSkidBuffer_io_out_bits_stride;
  logic [4:0]    VSSplitSkidBuffer_io_out_bits_flowNum;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_eew;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_sew;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_emul;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_lmul;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_instType;
  logic [4:0]    VSSplitSkidBuffer_io_out_bits_indexedSplitOffset;
  logic [31:0]   VSSplitSkidBuffer_io_out_bits_uop_instr;
  logic [49:0]   VSSplitSkidBuffer_io_out_bits_uop_pc;
  logic [9:0]    VSSplitSkidBuffer_io_out_bits_uop_foldpc;
  logic          VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_7;
  logic          VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_15;
  logic          VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_19;
  logic          VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_23;
  logic          VSSplitSkidBuffer_io_out_bits_uop_isFetchMalAddr;
  logic          VSSplitSkidBuffer_io_out_bits_uop_hasException;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_trigger;
  logic          VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_valid;
  logic          VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_brType;
  logic          VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isCall;
  logic          VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRet;
  logic          VSSplitSkidBuffer_io_out_bits_uop_pred_taken;
  logic          VSSplitSkidBuffer_io_out_bits_uop_crossPageIPFFix;
  logic          VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_flag;
  logic [5:0]    VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_value;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_ftqOffset;
  logic          VSSplitSkidBuffer_io_out_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_srcType_0;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_srcType_1;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_srcType_2;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_srcType_3;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_srcType_4;
  logic [5:0]    VSSplitSkidBuffer_io_out_bits_uop_ldest;
  logic [34:0]   VSSplitSkidBuffer_io_out_bits_uop_fuType;
  logic [8:0]    VSSplitSkidBuffer_io_out_bits_uop_fuOpType;
  logic          VSSplitSkidBuffer_io_out_bits_uop_rfWen;
  logic          VSSplitSkidBuffer_io_out_bits_uop_fpWen;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vecWen;
  logic          VSSplitSkidBuffer_io_out_bits_uop_v0Wen;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vlWen;
  logic          VSSplitSkidBuffer_io_out_bits_uop_isXSTrap;
  logic          VSSplitSkidBuffer_io_out_bits_uop_waitForward;
  logic          VSSplitSkidBuffer_io_out_bits_uop_blockBackward;
  logic          VSSplitSkidBuffer_io_out_bits_uop_canRobCompress;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_selImm;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_fpu_typeTagOut;
  logic          VSSplitSkidBuffer_io_out_bits_uop_fpu_wflags;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_fpu_typ;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_fpu_fmt;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_fpu_rm;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_vill;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_vma;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_vta;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_vsew;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_vlmul;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_specVill;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_specVma;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_specVta;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_specVsew;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_specVlmul;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_vm;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_vstart;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_frm;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFpToVecInst;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFP32Instr;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFP64Instr;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isReduction;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_vxrm;
  logic [6:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_vuopIdx;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_lastUop;
  logic [127:0]  VSSplitSkidBuffer_io_out_bits_uop_vpu_vmask;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_vl;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_nf;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_vpu_veew;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isReverse;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isExt;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isNarrow;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isDstMask;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isOpMask;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isMove;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isDependOldVd;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isWritePartVd;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vpu_isVleff;
  logic          VSSplitSkidBuffer_io_out_bits_uop_vlsInstr;
  logic          VSSplitSkidBuffer_io_out_bits_uop_wfflags;
  logic          VSSplitSkidBuffer_io_out_bits_uop_isMove;
  logic          VSSplitSkidBuffer_io_out_bits_uop_isDropAmocasSta;
  logic [6:0]    VSSplitSkidBuffer_io_out_bits_uop_uopIdx;
  logic          VSSplitSkidBuffer_io_out_bits_uop_isVset;
  logic          VSSplitSkidBuffer_io_out_bits_uop_firstUop;
  logic          VSSplitSkidBuffer_io_out_bits_uop_lastUop;
  logic [6:0]    VSSplitSkidBuffer_io_out_bits_uop_numUops;
  logic [6:0]    VSSplitSkidBuffer_io_out_bits_uop_numWB;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_commitType;
  logic          VSSplitSkidBuffer_io_out_bits_uop_srcState_0;
  logic          VSSplitSkidBuffer_io_out_bits_uop_srcState_1;
  logic          VSSplitSkidBuffer_io_out_bits_uop_srcState_2;
  logic          VSSplitSkidBuffer_io_out_bits_uop_srcState_3;
  logic          VSSplitSkidBuffer_io_out_bits_uop_srcState_4;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_0;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_1;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_2;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_0;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_1;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_2;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_0;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_1;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_2;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_0;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_1;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_2;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_0;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_1;
  logic [1:0]    VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_2;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_psrc_0;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_psrc_1;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_psrc_2;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_psrc_3;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_psrc_4;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_pdest;
  logic          VSSplitSkidBuffer_io_out_bits_uop_useRegCache_0;
  logic          VSSplitSkidBuffer_io_out_bits_uop_useRegCache_1;
  logic [4:0]    VSSplitSkidBuffer_io_out_bits_uop_regCacheIdx_0;
  logic [4:0]    VSSplitSkidBuffer_io_out_bits_uop_regCacheIdx_1;
  logic          VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_robIdx_value;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_uop_instrSize;
  logic          VSSplitSkidBuffer_io_out_bits_uop_dirtyFs;
  logic          VSSplitSkidBuffer_io_out_bits_uop_dirtyVs;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_itype;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_iretire;
  logic          VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_ilastsize;
  logic          VSSplitSkidBuffer_io_out_bits_uop_eliminatedMove;
  logic          VSSplitSkidBuffer_io_out_bits_uop_snapshot;
  logic          VSSplitSkidBuffer_io_out_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_renameTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_selectTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_issueTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_writebackTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   VSSplitSkidBuffer_io_out_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   VSSplitSkidBuffer_io_out_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_debug_seqNum_uopIdx;
  logic          VSSplitSkidBuffer_io_out_bits_uop_storeSetHit;
  logic          VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_flag;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_value;
  logic          VSSplitSkidBuffer_io_out_bits_uop_loadWaitBit;
  logic          VSSplitSkidBuffer_io_out_bits_uop_loadWaitStrict;
  logic [4:0]    VSSplitSkidBuffer_io_out_bits_uop_ssid;
  logic          VSSplitSkidBuffer_io_out_bits_uop_lqIdx_flag;
  logic [6:0]    VSSplitSkidBuffer_io_out_bits_uop_lqIdx_value;
  logic          VSSplitSkidBuffer_io_out_bits_uop_sqIdx_flag;
  logic [5:0]    VSSplitSkidBuffer_io_out_bits_uop_sqIdx_value;
  logic          VSSplitSkidBuffer_io_out_bits_uop_singleStep;
  logic          VSSplitSkidBuffer_io_out_bits_uop_replayInst;
  logic [34:0]   VSSplitSkidBuffer_io_out_bits_uop_debug_fuType;
  logic          VSSplitSkidBuffer_io_out_bits_uop_debug_sim_trig;
  logic [4:0]    VSSplitSkidBuffer_io_out_bits_uop_numLsElem;
  logic          VSSplitSkidBuffer_io_out_bits_preIsSplit;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_mBIndex;
  logic [2:0]    VSSplitSkidBuffer_io_out_bits_alignedType;
  logic [7:0]    VSSplitSkidBuffer_io_out_bits_indexVlMaxInVd;
  logic [3:0]    VSSplitSkidBuffer_io_out_bits_usLowBitsAddr;
  logic          VSSplitSkidBuffer_io_out_bits_usAligned128;
  logic [31:0]   VSSplitSkidBuffer_io_out_bits_usMask;
  logic          VSSplitSkidBuffer_io_out_bits_isVecPartReplay;
  logic [15:0]   VSSplitSkidBuffer_io_out_bits_vecReplayFlowMask;
  logic          skid_flush;

  // ---- 胶水：skid 缓冲的冲刷条件 ----
  xs_VSplitImp_core u_core (
    .redirect_valid               (io_redirect_valid),
    .redirect_bits_robIdx_flag    (io_redirect_bits_robIdx_flag),
    .redirect_bits_robIdx_value   (io_redirect_bits_robIdx_value),
    .redirect_bits_level          (io_redirect_bits_level),
    .pipeline_out_valid           (splitPipeline_io_out_valid),
    .pipeline_out_robIdx_flag     (splitPipeline_io_out_bits_uop_robIdx_flag),
    .pipeline_out_robIdx_value    (splitPipeline_io_out_bits_uop_robIdx_value),
    .skid_in_ready                (VSSplitSkidBuffer_io_in_ready),
    .skid_out_robIdx_flag         (VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag),
    .skid_out_robIdx_value        (VSSplitSkidBuffer_io_out_bits_uop_robIdx_value),
    .skid_flush                   (skid_flush)
  );

  // ---- 子模块 splitPipeline（VSSplitPipelineImp）----
  VSSplitPipelineImp splitPipeline (
    .clock                                                (clock),
    .reset                                                (reset),
    .io_redirect_valid                                    (io_redirect_valid),
    .io_redirect_bits_robIdx_flag                         (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                        (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                               (io_redirect_bits_level),
    .io_in_ready                                          (io_in_ready),
    .io_in_valid                                          (io_in_valid),
    .io_in_bits_uop_pc                                    (io_in_bits_uop_pc),
    .io_in_bits_uop_ftqPtr_flag                           (io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value                          (io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset                             (io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuType                                (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType                              (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen                                (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen                                 (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen                                 (io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill                              (io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma                               (io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta                               (io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew                              (io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul                             (io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill                          (io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma                           (io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta                           (io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew                          (io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul                         (io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm                                (io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart                            (io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm                               (io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst                 (io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr                   (io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr                   (io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction                   (io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2                   (io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4                   (io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8                   (io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm                              (io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx                           (io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop                           (io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask                             (io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_nf                                (io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew                              (io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse                         (io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt                             (io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow                          (io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask                         (io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask                          (io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove                            (io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd                     (io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd                     (io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff                           (io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_pdest                                 (io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag                           (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value                          (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove              (io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime                  (io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime                (io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime                   (io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime                  (io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime                   (io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime               (io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id      (io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime             (io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime                 (io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum                   (io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx                   (io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag                            (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value                           (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag                            (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value                           (io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_numLsElem                             (io_in_bits_uop_numLsElem),
    .io_in_bits_src_0                                     (io_in_bits_src_0),
    .io_in_bits_src_1                                     (io_in_bits_src_1),
    .io_in_bits_src_2                                     (io_in_bits_src_2),
    .io_in_bits_src_3                                     (io_in_bits_src_3),
    .io_in_bits_src_4                                     (io_in_bits_src_4),
    .io_in_bits_flowNum                                   (io_in_bits_flowNum),
    .io_in_bits_isVecPartReplay                           (io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayMask                             (io_in_bits_vecReplayMask),
    .io_in_bits_vecReplayMbIdx                            (io_in_bits_vecReplayMbIdx),
    .io_toMergeBuffer_req_ready                           (io_toMergeBuffer_req_ready),
    .io_toMergeBuffer_req_valid                           (io_toMergeBuffer_req_valid),
    .io_toMergeBuffer_req_bits_mask                       (io_toMergeBuffer_req_bits_mask),
    .io_toMergeBuffer_req_bits_vaddr                      (io_toMergeBuffer_req_bits_vaddr),
    .io_toMergeBuffer_req_bits_flowNum                    (io_toMergeBuffer_req_bits_flowNum),
    .io_toMergeBuffer_req_bits_uop_fuOpType               (io_toMergeBuffer_req_bits_uop_fuOpType),
    .io_toMergeBuffer_req_bits_uop_vecWen                 (io_toMergeBuffer_req_bits_uop_vecWen),
    .io_toMergeBuffer_req_bits_uop_v0Wen                  (io_toMergeBuffer_req_bits_uop_v0Wen),
    .io_toMergeBuffer_req_bits_uop_vlWen                  (io_toMergeBuffer_req_bits_uop_vlWen),
    .io_toMergeBuffer_req_bits_uop_vpu_vill               (io_toMergeBuffer_req_bits_uop_vpu_vill),
    .io_toMergeBuffer_req_bits_uop_vpu_vma                (io_toMergeBuffer_req_bits_uop_vpu_vma),
    .io_toMergeBuffer_req_bits_uop_vpu_vta                (io_toMergeBuffer_req_bits_uop_vpu_vta),
    .io_toMergeBuffer_req_bits_uop_vpu_vsew               (io_toMergeBuffer_req_bits_uop_vpu_vsew),
    .io_toMergeBuffer_req_bits_uop_vpu_vlmul              (io_toMergeBuffer_req_bits_uop_vpu_vlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_specVill           (io_toMergeBuffer_req_bits_uop_vpu_specVill),
    .io_toMergeBuffer_req_bits_uop_vpu_specVma            (io_toMergeBuffer_req_bits_uop_vpu_specVma),
    .io_toMergeBuffer_req_bits_uop_vpu_specVta            (io_toMergeBuffer_req_bits_uop_vpu_specVta),
    .io_toMergeBuffer_req_bits_uop_vpu_specVsew           (io_toMergeBuffer_req_bits_uop_vpu_specVsew),
    .io_toMergeBuffer_req_bits_uop_vpu_specVlmul          (io_toMergeBuffer_req_bits_uop_vpu_specVlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_vm                 (io_toMergeBuffer_req_bits_uop_vpu_vm),
    .io_toMergeBuffer_req_bits_uop_vpu_frm                (io_toMergeBuffer_req_bits_uop_vpu_frm),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst  (io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr    (io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr    (io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction    (io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2    (io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4    (io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8    (io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_toMergeBuffer_req_bits_uop_vpu_vxrm               (io_toMergeBuffer_req_bits_uop_vpu_vxrm),
    .io_toMergeBuffer_req_bits_uop_vpu_vuopIdx            (io_toMergeBuffer_req_bits_uop_vpu_vuopIdx),
    .io_toMergeBuffer_req_bits_uop_vpu_lastUop            (io_toMergeBuffer_req_bits_uop_vpu_lastUop),
    .io_toMergeBuffer_req_bits_uop_vpu_vmask              (io_toMergeBuffer_req_bits_uop_vpu_vmask),
    .io_toMergeBuffer_req_bits_uop_vpu_vl                 (io_toMergeBuffer_req_bits_uop_vpu_vl),
    .io_toMergeBuffer_req_bits_uop_vpu_nf                 (io_toMergeBuffer_req_bits_uop_vpu_nf),
    .io_toMergeBuffer_req_bits_uop_vpu_veew               (io_toMergeBuffer_req_bits_uop_vpu_veew),
    .io_toMergeBuffer_req_bits_uop_vpu_isReverse          (io_toMergeBuffer_req_bits_uop_vpu_isReverse),
    .io_toMergeBuffer_req_bits_uop_vpu_isExt              (io_toMergeBuffer_req_bits_uop_vpu_isExt),
    .io_toMergeBuffer_req_bits_uop_vpu_isNarrow           (io_toMergeBuffer_req_bits_uop_vpu_isNarrow),
    .io_toMergeBuffer_req_bits_uop_vpu_isDstMask          (io_toMergeBuffer_req_bits_uop_vpu_isDstMask),
    .io_toMergeBuffer_req_bits_uop_vpu_isOpMask           (io_toMergeBuffer_req_bits_uop_vpu_isOpMask),
    .io_toMergeBuffer_req_bits_uop_vpu_isMove             (io_toMergeBuffer_req_bits_uop_vpu_isMove),
    .io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd      (io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd),
    .io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd      (io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd),
    .io_toMergeBuffer_req_bits_uop_vpu_isVleff            (io_toMergeBuffer_req_bits_uop_vpu_isVleff),
    .io_toMergeBuffer_req_bits_uop_uopIdx                 (io_toMergeBuffer_req_bits_uop_uopIdx),
    .io_toMergeBuffer_req_bits_uop_pdest                  (io_toMergeBuffer_req_bits_uop_pdest),
    .io_toMergeBuffer_req_bits_uop_robIdx_flag            (io_toMergeBuffer_req_bits_uop_robIdx_flag),
    .io_toMergeBuffer_req_bits_uop_robIdx_value           (io_toMergeBuffer_req_bits_uop_robIdx_value),
    .io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove (io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove),
    .io_toMergeBuffer_req_bits_uop_debugInfo_renameTime   (io_toMergeBuffer_req_bits_uop_debugInfo_renameTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime (io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime    (io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_selectTime   (io_toMergeBuffer_req_bits_uop_debugInfo_selectTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_issueTime    (io_toMergeBuffer_req_bits_uop_debugInfo_issueTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime (io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id (io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime (io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime  (io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime),
    .io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum    (io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum),
    .io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx    (io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx),
    .io_toMergeBuffer_req_bits_uop_lqIdx_flag             (io_toMergeBuffer_req_bits_uop_lqIdx_flag),
    .io_toMergeBuffer_req_bits_uop_lqIdx_value            (io_toMergeBuffer_req_bits_uop_lqIdx_value),
    .io_toMergeBuffer_req_bits_uop_sqIdx_flag             (io_toMergeBuffer_req_bits_uop_sqIdx_flag),
    .io_toMergeBuffer_req_bits_uop_sqIdx_value            (io_toMergeBuffer_req_bits_uop_sqIdx_value),
    .io_toMergeBuffer_req_bits_vlmax                      (io_toMergeBuffer_req_bits_vlmax),
    .io_toMergeBuffer_resp_valid                          (io_toMergeBuffer_resp_valid),
    .io_toMergeBuffer_resp_bits_mBIndex                   (io_toMergeBuffer_resp_bits_mBIndex),
    .io_out_ready                                         (VSSplitSkidBuffer_io_in_ready),
    .io_out_valid                                         (splitPipeline_io_out_valid),
    .io_out_bits_flowMask                                 (splitPipeline_io_out_bits_flowMask),
    .io_out_bits_data                                     (splitPipeline_io_out_bits_data),
    .io_out_bits_baseAddr                                 (splitPipeline_io_out_bits_baseAddr),
    .io_out_bits_uopAddr                                  (splitPipeline_io_out_bits_uopAddr),
    .io_out_bits_stride                                   (splitPipeline_io_out_bits_stride),
    .io_out_bits_flowNum                                  (splitPipeline_io_out_bits_flowNum),
    .io_out_bits_eew                                      (splitPipeline_io_out_bits_eew),
    .io_out_bits_sew                                      (splitPipeline_io_out_bits_sew),
    .io_out_bits_emul                                     (splitPipeline_io_out_bits_emul),
    .io_out_bits_lmul                                     (splitPipeline_io_out_bits_lmul),
    .io_out_bits_instType                                 (splitPipeline_io_out_bits_instType),
    .io_out_bits_indexedSplitOffset                       (splitPipeline_io_out_bits_indexedSplitOffset),
    .io_out_bits_uop_pc                                   (splitPipeline_io_out_bits_uop_pc),
    .io_out_bits_uop_ftqPtr_flag                          (splitPipeline_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value                         (splitPipeline_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset                            (splitPipeline_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_fuType                               (splitPipeline_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType                             (splitPipeline_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_vecWen                               (splitPipeline_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen                                (splitPipeline_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen                                (splitPipeline_io_out_bits_uop_vlWen),
    .io_out_bits_uop_vpu_vill                             (splitPipeline_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma                              (splitPipeline_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta                              (splitPipeline_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew                             (splitPipeline_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul                            (splitPipeline_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill                         (splitPipeline_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma                          (splitPipeline_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta                          (splitPipeline_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew                         (splitPipeline_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul                        (splitPipeline_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm                               (splitPipeline_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart                           (splitPipeline_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm                              (splitPipeline_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst                (splitPipeline_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr                  (splitPipeline_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr                  (splitPipeline_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction                  (splitPipeline_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2                  (splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4                  (splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8                  (splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm                             (splitPipeline_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx                          (splitPipeline_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop                          (splitPipeline_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask                            (splitPipeline_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl                               (splitPipeline_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf                               (splitPipeline_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew                             (splitPipeline_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse                        (splitPipeline_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt                            (splitPipeline_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow                         (splitPipeline_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask                        (splitPipeline_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask                         (splitPipeline_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove                           (splitPipeline_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd                    (splitPipeline_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd                    (splitPipeline_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff                          (splitPipeline_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_uopIdx                               (splitPipeline_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_lastUop                              (splitPipeline_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops                              (splitPipeline_io_out_bits_uop_numUops),
    .io_out_bits_uop_pdest                                (splitPipeline_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag                          (splitPipeline_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value                         (splitPipeline_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_eliminatedMove             (splitPipeline_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime                 (splitPipeline_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime               (splitPipeline_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime                  (splitPipeline_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime                 (splitPipeline_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime                  (splitPipeline_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime              (splitPipeline_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id     (splitPipeline_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime            (splitPipeline_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime                (splitPipeline_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum                  (splitPipeline_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx                  (splitPipeline_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_lqIdx_flag                           (splitPipeline_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value                          (splitPipeline_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag                           (splitPipeline_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value                          (splitPipeline_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_numLsElem                            (splitPipeline_io_out_bits_uop_numLsElem),
    .io_out_bits_preIsSplit                               (splitPipeline_io_out_bits_preIsSplit),
    .io_out_bits_mBIndex                                  (splitPipeline_io_out_bits_mBIndex),
    .io_out_bits_alignedType                              (splitPipeline_io_out_bits_alignedType),
    .io_out_bits_indexVlMaxInVd                           (splitPipeline_io_out_bits_indexVlMaxInVd),
    .io_out_bits_usLowBitsAddr                            (splitPipeline_io_out_bits_usLowBitsAddr),
    .io_out_bits_usAligned128                             (splitPipeline_io_out_bits_usAligned128),
    .io_out_bits_usMask                                   (splitPipeline_io_out_bits_usMask),
    .io_out_bits_isVecPartReplay                          (splitPipeline_io_out_bits_isVecPartReplay),
    .io_out_bits_vecReplayFlowMask                        (splitPipeline_io_out_bits_vecReplayFlowMask),
    .io_threshold_valid                                   (io_threshold_valid),
    .io_threshold_bits_robIdx_flag                        (io_threshold_bits_robIdx_flag),
    .io_threshold_bits_robIdx_value                       (io_threshold_bits_robIdx_value),
    .io_threshold_bits_uopIdx                             (io_threshold_bits_uopIdx)
  );

  // ---- 子模块 splitBuffer（VSSplitBufferImp）----
  VSSplitBufferImp splitBuffer (
    .clock                                                (clock),
    .reset                                                (reset),
    .io_redirect_valid                                    (io_redirect_valid),
    .io_redirect_bits_robIdx_flag                         (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                        (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                               (io_redirect_bits_level),
    .io_in_ready                                          (splitBuffer_io_in_ready),
    .io_in_valid                                          (VSSplitSkidBuffer_io_out_valid),
    .io_in_bits_flowMask                                  (VSSplitSkidBuffer_io_out_bits_flowMask),
    .io_in_bits_data                                      (VSSplitSkidBuffer_io_out_bits_data),
    .io_in_bits_baseAddr                                  (VSSplitSkidBuffer_io_out_bits_baseAddr),
    .io_in_bits_uopAddr                                   (VSSplitSkidBuffer_io_out_bits_uopAddr),
    .io_in_bits_stride                                    (VSSplitSkidBuffer_io_out_bits_stride),
    .io_in_bits_flowNum                                   (VSSplitSkidBuffer_io_out_bits_flowNum),
    .io_in_bits_eew                                       (VSSplitSkidBuffer_io_out_bits_eew),
    .io_in_bits_sew                                       (VSSplitSkidBuffer_io_out_bits_sew),
    .io_in_bits_emul                                      (VSSplitSkidBuffer_io_out_bits_emul),
    .io_in_bits_lmul                                      (VSSplitSkidBuffer_io_out_bits_lmul),
    .io_in_bits_instType                                  (VSSplitSkidBuffer_io_out_bits_instType),
    .io_in_bits_indexedSplitOffset                        (VSSplitSkidBuffer_io_out_bits_indexedSplitOffset),
    .io_in_bits_uop_instr                                 (VSSplitSkidBuffer_io_out_bits_uop_instr),
    .io_in_bits_uop_pc                                    (VSSplitSkidBuffer_io_out_bits_uop_pc),
    .io_in_bits_uop_foldpc                                (VSSplitSkidBuffer_io_out_bits_uop_foldpc),
    .io_in_bits_uop_exceptionVec_7                        (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_15                       (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19                       (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_23                       (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_23),
    .io_in_bits_uop_isFetchMalAddr                        (VSSplitSkidBuffer_io_out_bits_uop_isFetchMalAddr),
    .io_in_bits_uop_hasException                          (VSSplitSkidBuffer_io_out_bits_uop_hasException),
    .io_in_bits_uop_trigger                               (VSSplitSkidBuffer_io_out_bits_uop_trigger),
    .io_in_bits_uop_preDecodeInfo_valid                   (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_valid),
    .io_in_bits_uop_preDecodeInfo_isRVC                   (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_in_bits_uop_preDecodeInfo_brType                  (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_brType),
    .io_in_bits_uop_preDecodeInfo_isCall                  (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isCall),
    .io_in_bits_uop_preDecodeInfo_isRet                   (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRet),
    .io_in_bits_uop_pred_taken                            (VSSplitSkidBuffer_io_out_bits_uop_pred_taken),
    .io_in_bits_uop_crossPageIPFFix                       (VSSplitSkidBuffer_io_out_bits_uop_crossPageIPFFix),
    .io_in_bits_uop_ftqPtr_flag                           (VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value                          (VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset                             (VSSplitSkidBuffer_io_out_bits_uop_ftqOffset),
    .io_in_bits_uop_satpFlushFirstFetchFault              (VSSplitSkidBuffer_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_in_bits_uop_srcType_0                             (VSSplitSkidBuffer_io_out_bits_uop_srcType_0),
    .io_in_bits_uop_srcType_1                             (VSSplitSkidBuffer_io_out_bits_uop_srcType_1),
    .io_in_bits_uop_srcType_2                             (VSSplitSkidBuffer_io_out_bits_uop_srcType_2),
    .io_in_bits_uop_srcType_3                             (VSSplitSkidBuffer_io_out_bits_uop_srcType_3),
    .io_in_bits_uop_srcType_4                             (VSSplitSkidBuffer_io_out_bits_uop_srcType_4),
    .io_in_bits_uop_ldest                                 (VSSplitSkidBuffer_io_out_bits_uop_ldest),
    .io_in_bits_uop_fuType                                (VSSplitSkidBuffer_io_out_bits_uop_fuType),
    .io_in_bits_uop_fuOpType                              (VSSplitSkidBuffer_io_out_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen                                 (VSSplitSkidBuffer_io_out_bits_uop_rfWen),
    .io_in_bits_uop_fpWen                                 (VSSplitSkidBuffer_io_out_bits_uop_fpWen),
    .io_in_bits_uop_vecWen                                (VSSplitSkidBuffer_io_out_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen                                 (VSSplitSkidBuffer_io_out_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen                                 (VSSplitSkidBuffer_io_out_bits_uop_vlWen),
    .io_in_bits_uop_isXSTrap                              (VSSplitSkidBuffer_io_out_bits_uop_isXSTrap),
    .io_in_bits_uop_waitForward                           (VSSplitSkidBuffer_io_out_bits_uop_waitForward),
    .io_in_bits_uop_blockBackward                         (VSSplitSkidBuffer_io_out_bits_uop_blockBackward),
    .io_in_bits_uop_canRobCompress                        (VSSplitSkidBuffer_io_out_bits_uop_canRobCompress),
    .io_in_bits_uop_selImm                                (VSSplitSkidBuffer_io_out_bits_uop_selImm),
    .io_in_bits_uop_fpu_typeTagOut                        (VSSplitSkidBuffer_io_out_bits_uop_fpu_typeTagOut),
    .io_in_bits_uop_fpu_wflags                            (VSSplitSkidBuffer_io_out_bits_uop_fpu_wflags),
    .io_in_bits_uop_fpu_typ                               (VSSplitSkidBuffer_io_out_bits_uop_fpu_typ),
    .io_in_bits_uop_fpu_fmt                               (VSSplitSkidBuffer_io_out_bits_uop_fpu_fmt),
    .io_in_bits_uop_fpu_rm                                (VSSplitSkidBuffer_io_out_bits_uop_fpu_rm),
    .io_in_bits_uop_vpu_vill                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma                               (VSSplitSkidBuffer_io_out_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta                               (VSSplitSkidBuffer_io_out_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm                                (VSSplitSkidBuffer_io_out_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart                            (VSSplitSkidBuffer_io_out_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm                               (VSSplitSkidBuffer_io_out_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst                 (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr                   (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr                   (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction                   (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2                   (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4                   (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8                   (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl                                (VSSplitSkidBuffer_io_out_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf                                (VSSplitSkidBuffer_io_out_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove                            (VSSplitSkidBuffer_io_out_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd                     (VSSplitSkidBuffer_io_out_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd                     (VSSplitSkidBuffer_io_out_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_isVleff),
    .io_in_bits_uop_vlsInstr                              (VSSplitSkidBuffer_io_out_bits_uop_vlsInstr),
    .io_in_bits_uop_wfflags                               (VSSplitSkidBuffer_io_out_bits_uop_wfflags),
    .io_in_bits_uop_isMove                                (VSSplitSkidBuffer_io_out_bits_uop_isMove),
    .io_in_bits_uop_isDropAmocasSta                       (VSSplitSkidBuffer_io_out_bits_uop_isDropAmocasSta),
    .io_in_bits_uop_uopIdx                                (VSSplitSkidBuffer_io_out_bits_uop_uopIdx),
    .io_in_bits_uop_isVset                                (VSSplitSkidBuffer_io_out_bits_uop_isVset),
    .io_in_bits_uop_firstUop                              (VSSplitSkidBuffer_io_out_bits_uop_firstUop),
    .io_in_bits_uop_lastUop                               (VSSplitSkidBuffer_io_out_bits_uop_lastUop),
    .io_in_bits_uop_numUops                               (VSSplitSkidBuffer_io_out_bits_uop_numUops),
    .io_in_bits_uop_numWB                                 (VSSplitSkidBuffer_io_out_bits_uop_numWB),
    .io_in_bits_uop_commitType                            (VSSplitSkidBuffer_io_out_bits_uop_commitType),
    .io_in_bits_uop_srcState_0                            (VSSplitSkidBuffer_io_out_bits_uop_srcState_0),
    .io_in_bits_uop_srcState_1                            (VSSplitSkidBuffer_io_out_bits_uop_srcState_1),
    .io_in_bits_uop_srcState_2                            (VSSplitSkidBuffer_io_out_bits_uop_srcState_2),
    .io_in_bits_uop_srcState_3                            (VSSplitSkidBuffer_io_out_bits_uop_srcState_3),
    .io_in_bits_uop_srcState_4                            (VSSplitSkidBuffer_io_out_bits_uop_srcState_4),
    .io_in_bits_uop_srcLoadDependency_0_0                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_0),
    .io_in_bits_uop_srcLoadDependency_0_1                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_1),
    .io_in_bits_uop_srcLoadDependency_0_2                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_2),
    .io_in_bits_uop_srcLoadDependency_1_0                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_0),
    .io_in_bits_uop_srcLoadDependency_1_1                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_1),
    .io_in_bits_uop_srcLoadDependency_1_2                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_2),
    .io_in_bits_uop_srcLoadDependency_2_0                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_0),
    .io_in_bits_uop_srcLoadDependency_2_1                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_1),
    .io_in_bits_uop_srcLoadDependency_2_2                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_2),
    .io_in_bits_uop_srcLoadDependency_3_0                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_0),
    .io_in_bits_uop_srcLoadDependency_3_1                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_1),
    .io_in_bits_uop_srcLoadDependency_3_2                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_2),
    .io_in_bits_uop_srcLoadDependency_4_0                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_0),
    .io_in_bits_uop_srcLoadDependency_4_1                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_1),
    .io_in_bits_uop_srcLoadDependency_4_2                 (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_2),
    .io_in_bits_uop_psrc_0                                (VSSplitSkidBuffer_io_out_bits_uop_psrc_0),
    .io_in_bits_uop_psrc_1                                (VSSplitSkidBuffer_io_out_bits_uop_psrc_1),
    .io_in_bits_uop_psrc_2                                (VSSplitSkidBuffer_io_out_bits_uop_psrc_2),
    .io_in_bits_uop_psrc_3                                (VSSplitSkidBuffer_io_out_bits_uop_psrc_3),
    .io_in_bits_uop_psrc_4                                (VSSplitSkidBuffer_io_out_bits_uop_psrc_4),
    .io_in_bits_uop_pdest                                 (VSSplitSkidBuffer_io_out_bits_uop_pdest),
    .io_in_bits_uop_useRegCache_0                         (VSSplitSkidBuffer_io_out_bits_uop_useRegCache_0),
    .io_in_bits_uop_useRegCache_1                         (VSSplitSkidBuffer_io_out_bits_uop_useRegCache_1),
    .io_in_bits_uop_regCacheIdx_0                         (VSSplitSkidBuffer_io_out_bits_uop_regCacheIdx_0),
    .io_in_bits_uop_regCacheIdx_1                         (VSSplitSkidBuffer_io_out_bits_uop_regCacheIdx_1),
    .io_in_bits_uop_robIdx_flag                           (VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value                          (VSSplitSkidBuffer_io_out_bits_uop_robIdx_value),
    .io_in_bits_uop_instrSize                             (VSSplitSkidBuffer_io_out_bits_uop_instrSize),
    .io_in_bits_uop_dirtyFs                               (VSSplitSkidBuffer_io_out_bits_uop_dirtyFs),
    .io_in_bits_uop_dirtyVs                               (VSSplitSkidBuffer_io_out_bits_uop_dirtyVs),
    .io_in_bits_uop_traceBlockInPipe_itype                (VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_itype),
    .io_in_bits_uop_traceBlockInPipe_iretire              (VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_in_bits_uop_traceBlockInPipe_ilastsize            (VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_in_bits_uop_eliminatedMove                        (VSSplitSkidBuffer_io_out_bits_uop_eliminatedMove),
    .io_in_bits_uop_snapshot                              (VSSplitSkidBuffer_io_out_bits_uop_snapshot),
    .io_in_bits_uop_debugInfo_eliminatedMove              (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime                  (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime                (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime                   (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime                  (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime                   (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime               (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id      (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime             (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime                 (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum                   (VSSplitSkidBuffer_io_out_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx                   (VSSplitSkidBuffer_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_storeSetHit                           (VSSplitSkidBuffer_io_out_bits_uop_storeSetHit),
    .io_in_bits_uop_waitForRobIdx_flag                    (VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_flag),
    .io_in_bits_uop_waitForRobIdx_value                   (VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_value),
    .io_in_bits_uop_loadWaitBit                           (VSSplitSkidBuffer_io_out_bits_uop_loadWaitBit),
    .io_in_bits_uop_loadWaitStrict                        (VSSplitSkidBuffer_io_out_bits_uop_loadWaitStrict),
    .io_in_bits_uop_ssid                                  (VSSplitSkidBuffer_io_out_bits_uop_ssid),
    .io_in_bits_uop_lqIdx_flag                            (VSSplitSkidBuffer_io_out_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value                           (VSSplitSkidBuffer_io_out_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag                            (VSSplitSkidBuffer_io_out_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value                           (VSSplitSkidBuffer_io_out_bits_uop_sqIdx_value),
    .io_in_bits_uop_singleStep                            (VSSplitSkidBuffer_io_out_bits_uop_singleStep),
    .io_in_bits_uop_replayInst                            (VSSplitSkidBuffer_io_out_bits_uop_replayInst),
    .io_in_bits_uop_debug_fuType                          (VSSplitSkidBuffer_io_out_bits_uop_debug_fuType),
    .io_in_bits_uop_debug_sim_trig                        (VSSplitSkidBuffer_io_out_bits_uop_debug_sim_trig),
    .io_in_bits_uop_numLsElem                             (VSSplitSkidBuffer_io_out_bits_uop_numLsElem),
    .io_in_bits_preIsSplit                                (VSSplitSkidBuffer_io_out_bits_preIsSplit),
    .io_in_bits_mBIndex                                   (VSSplitSkidBuffer_io_out_bits_mBIndex),
    .io_in_bits_alignedType                               (VSSplitSkidBuffer_io_out_bits_alignedType),
    .io_in_bits_indexVlMaxInVd                            (VSSplitSkidBuffer_io_out_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr                             (VSSplitSkidBuffer_io_out_bits_usLowBitsAddr),
    .io_in_bits_usAligned128                              (VSSplitSkidBuffer_io_out_bits_usAligned128),
    .io_in_bits_usMask                                    (VSSplitSkidBuffer_io_out_bits_usMask),
    .io_in_bits_isVecPartReplay                           (VSSplitSkidBuffer_io_out_bits_isVecPartReplay),
    .io_in_bits_vecReplayFlowMask                         (VSSplitSkidBuffer_io_out_bits_vecReplayFlowMask),
    .io_out_ready                                         (io_out_ready),
    .io_out_valid                                         (splitBuffer_io_out_valid),
    .io_out_bits_vaddr                                    (io_out_bits_vaddr),
    .io_out_bits_basevaddr                                (io_out_bits_basevaddr),
    .io_out_bits_mask                                     (io_out_bits_mask),
    .io_out_bits_reg_offset                               (io_out_bits_reg_offset),
    .io_out_bits_alignedType                              (io_out_bits_alignedType),
    .io_out_bits_vecActive                                (io_out_bits_vecActive),
    .io_out_bits_vecIsFirstActiveElement                  (io_out_bits_vecIsFirstActiveElement),
    .io_out_bits_uop_instr                                (io_out_bits_uop_instr),
    .io_out_bits_uop_pc                                   (io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc                               (io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_6                       (io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7                       (io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_15                      (io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19                      (io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_23                      (io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_isFetchMalAddr                       (io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException                         (io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger                              (io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid                  (io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC                  (io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType                 (io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall                 (io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet                  (io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken                           (io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix                      (io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag                          (io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value                         (io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset                            (io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault             (io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0                            (io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1                            (io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2                            (io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3                            (io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4                            (io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest                                (io_out_bits_uop_ldest),
    .io_out_bits_uop_fuType                               (io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType                             (io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen                                (io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen                                (io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen                               (io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen                                (io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen                                (io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap                             (io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward                          (io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward                        (io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress                       (io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm                               (io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut                       (io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags                           (io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ                              (io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt                              (io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm                               (io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill                             (io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma                              (io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta                              (io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew                             (io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul                            (io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill                         (io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma                          (io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta                          (io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew                         (io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul                        (io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm                               (io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart                           (io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm                              (io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst                (io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr                  (io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr                  (io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction                  (io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2                  (io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4                  (io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8                  (io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm                             (io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx                          (io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop                          (io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask                            (io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl                               (io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf                               (io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew                             (io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse                        (io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt                            (io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow                         (io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask                        (io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask                         (io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove                           (io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd                    (io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd                    (io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff                          (io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr                             (io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags                              (io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove                               (io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta                      (io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx                               (io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset                               (io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop                             (io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop                              (io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops                              (io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB                                (io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType                           (io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0                           (io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1                           (io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2                           (io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3                           (io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4                           (io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0                (io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1                (io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2                (io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0                (io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1                (io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2                (io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0                (io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1                (io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2                (io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0                (io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1                (io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2                (io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0                (io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1                (io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2                (io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0                               (io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1                               (io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2                               (io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3                               (io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4                               (io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest                                (io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0                        (io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1                        (io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0                        (io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1                        (io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag                          (io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value                         (io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize                            (io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs                              (io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs                              (io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype               (io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire             (io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize           (io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove                       (io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot                             (io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove             (io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime                 (io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime               (io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime                  (io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime                 (io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime                  (io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime              (io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id     (io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime            (io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime                (io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum                  (io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx                  (io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit                          (io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag                   (io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value                  (io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit                          (io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict                       (io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid                                 (io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag                           (io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value                          (io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag                           (io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value                          (io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep                           (io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst                           (io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType                         (io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig                       (io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem                            (io_out_bits_uop_numLsElem),
    .io_out_bits_mBIndex                                  (io_out_bits_mBIndex),
    .io_out_bits_elemIdx                                  (io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd                          (io_out_bits_elemIdxInsideVd),
    .io_out_bits_splitIndex                               (io_out_bits_splitIndex),
    .io_vstd_valid                                        (io_vstd_valid),
    .io_vstd_bits_uop_fuOpType                            (io_vstd_bits_uop_fuOpType),
    .io_vstd_bits_uop_sqIdx_flag                          (io_vstd_bits_uop_sqIdx_flag),
    .io_vstd_bits_uop_sqIdx_value                         (io_vstd_bits_uop_sqIdx_value),
    .io_vstd_bits_data                                    (io_vstd_bits_data),
    .io_vstd_bits_vecDebug_offset                         (io_vstd_bits_vecDebug_offset),
    .io_vstdMisalign_storeMisalignBufferEmpty             (io_vstdMisalign_storeMisalignBufferEmpty),
    .io_vstdMisalign_scalaIssueValid                      (io_vstdMisalign_scalaIssueValid),
    .io_vstdMisalign_scalaIssueRobIdx_flag                (io_vstdMisalign_scalaIssueRobIdx_flag),
    .io_vstdMisalign_scalaIssueRobIdx_value               (io_vstdMisalign_scalaIssueRobIdx_value),
    .io_vstdMisalign_sqDeqIsVec                           (io_vstdMisalign_sqDeqIsVec)
  );

  // ---- 子模块 VSSplitSkidBuffer（skidBufferConnect）----
  skidBufferConnect VSSplitSkidBuffer (
    .clock                                                (clock),
    .reset                                                (reset),
    .io_in_ready                                          (VSSplitSkidBuffer_io_in_ready),
    .io_in_valid                                          (splitPipeline_io_out_valid),
    .io_in_bits_flowMask                                  (splitPipeline_io_out_bits_flowMask),
    .io_in_bits_data                                      (splitPipeline_io_out_bits_data),
    .io_in_bits_baseAddr                                  (splitPipeline_io_out_bits_baseAddr),
    .io_in_bits_uopAddr                                   (splitPipeline_io_out_bits_uopAddr),
    .io_in_bits_stride                                    (splitPipeline_io_out_bits_stride),
    .io_in_bits_flowNum                                   (splitPipeline_io_out_bits_flowNum),
    .io_in_bits_eew                                       (splitPipeline_io_out_bits_eew),
    .io_in_bits_sew                                       (splitPipeline_io_out_bits_sew),
    .io_in_bits_emul                                      (splitPipeline_io_out_bits_emul),
    .io_in_bits_lmul                                      (splitPipeline_io_out_bits_lmul),
    .io_in_bits_instType                                  (splitPipeline_io_out_bits_instType),
    .io_in_bits_indexedSplitOffset                        (splitPipeline_io_out_bits_indexedSplitOffset),
    .io_in_bits_uop_pc                                    (splitPipeline_io_out_bits_uop_pc),
    .io_in_bits_uop_ftqPtr_flag                           (splitPipeline_io_out_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value                          (splitPipeline_io_out_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset                             (splitPipeline_io_out_bits_uop_ftqOffset),
    .io_in_bits_uop_fuType                                (splitPipeline_io_out_bits_uop_fuType),
    .io_in_bits_uop_fuOpType                              (splitPipeline_io_out_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen                                (splitPipeline_io_out_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen                                 (splitPipeline_io_out_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen                                 (splitPipeline_io_out_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill                              (splitPipeline_io_out_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma                               (splitPipeline_io_out_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta                               (splitPipeline_io_out_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew                              (splitPipeline_io_out_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul                             (splitPipeline_io_out_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill                          (splitPipeline_io_out_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma                           (splitPipeline_io_out_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta                           (splitPipeline_io_out_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew                          (splitPipeline_io_out_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul                         (splitPipeline_io_out_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm                                (splitPipeline_io_out_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart                            (splitPipeline_io_out_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm                               (splitPipeline_io_out_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst                 (splitPipeline_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr                   (splitPipeline_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr                   (splitPipeline_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction                   (splitPipeline_io_out_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2                   (splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4                   (splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8                   (splitPipeline_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm                              (splitPipeline_io_out_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx                           (splitPipeline_io_out_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop                           (splitPipeline_io_out_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask                             (splitPipeline_io_out_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl                                (splitPipeline_io_out_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf                                (splitPipeline_io_out_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew                              (splitPipeline_io_out_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse                         (splitPipeline_io_out_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt                             (splitPipeline_io_out_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow                          (splitPipeline_io_out_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask                         (splitPipeline_io_out_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask                          (splitPipeline_io_out_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove                            (splitPipeline_io_out_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd                     (splitPipeline_io_out_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd                     (splitPipeline_io_out_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff                           (splitPipeline_io_out_bits_uop_vpu_isVleff),
    .io_in_bits_uop_uopIdx                                (splitPipeline_io_out_bits_uop_uopIdx),
    .io_in_bits_uop_lastUop                               (splitPipeline_io_out_bits_uop_lastUop),
    .io_in_bits_uop_numUops                               (splitPipeline_io_out_bits_uop_numUops),
    .io_in_bits_uop_pdest                                 (splitPipeline_io_out_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag                           (splitPipeline_io_out_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value                          (splitPipeline_io_out_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove              (splitPipeline_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime                  (splitPipeline_io_out_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime                (splitPipeline_io_out_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime                   (splitPipeline_io_out_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime                  (splitPipeline_io_out_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime                   (splitPipeline_io_out_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime               (splitPipeline_io_out_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id      (splitPipeline_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime             (splitPipeline_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime                 (splitPipeline_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum                   (splitPipeline_io_out_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx                   (splitPipeline_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag                            (splitPipeline_io_out_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value                           (splitPipeline_io_out_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag                            (splitPipeline_io_out_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value                           (splitPipeline_io_out_bits_uop_sqIdx_value),
    .io_in_bits_uop_numLsElem                             (splitPipeline_io_out_bits_uop_numLsElem),
    .io_in_bits_preIsSplit                                (splitPipeline_io_out_bits_preIsSplit),
    .io_in_bits_mBIndex                                   (splitPipeline_io_out_bits_mBIndex),
    .io_in_bits_alignedType                               (splitPipeline_io_out_bits_alignedType),
    .io_in_bits_indexVlMaxInVd                            (splitPipeline_io_out_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr                             (splitPipeline_io_out_bits_usLowBitsAddr),
    .io_in_bits_usAligned128                              (splitPipeline_io_out_bits_usAligned128),
    .io_in_bits_usMask                                    (splitPipeline_io_out_bits_usMask),
    .io_in_bits_isVecPartReplay                           (splitPipeline_io_out_bits_isVecPartReplay),
    .io_in_bits_vecReplayFlowMask                         (splitPipeline_io_out_bits_vecReplayFlowMask),
    .io_flush                                             (skid_flush),
    .io_out_ready                                         (splitBuffer_io_in_ready),
    .io_out_valid                                         (VSSplitSkidBuffer_io_out_valid),
    .io_out_bits_flowMask                                 (VSSplitSkidBuffer_io_out_bits_flowMask),
    .io_out_bits_data                                     (VSSplitSkidBuffer_io_out_bits_data),
    .io_out_bits_baseAddr                                 (VSSplitSkidBuffer_io_out_bits_baseAddr),
    .io_out_bits_uopAddr                                  (VSSplitSkidBuffer_io_out_bits_uopAddr),
    .io_out_bits_stride                                   (VSSplitSkidBuffer_io_out_bits_stride),
    .io_out_bits_flowNum                                  (VSSplitSkidBuffer_io_out_bits_flowNum),
    .io_out_bits_eew                                      (VSSplitSkidBuffer_io_out_bits_eew),
    .io_out_bits_sew                                      (VSSplitSkidBuffer_io_out_bits_sew),
    .io_out_bits_emul                                     (VSSplitSkidBuffer_io_out_bits_emul),
    .io_out_bits_lmul                                     (VSSplitSkidBuffer_io_out_bits_lmul),
    .io_out_bits_instType                                 (VSSplitSkidBuffer_io_out_bits_instType),
    .io_out_bits_indexedSplitOffset                       (VSSplitSkidBuffer_io_out_bits_indexedSplitOffset),
    .io_out_bits_uop_instr                                (VSSplitSkidBuffer_io_out_bits_uop_instr),
    .io_out_bits_uop_pc                                   (VSSplitSkidBuffer_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc                               (VSSplitSkidBuffer_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_5                       (),
    .io_out_bits_uop_exceptionVec_7                       (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13                      (),
    .io_out_bits_uop_exceptionVec_15                      (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19                      (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21                      (),
    .io_out_bits_uop_exceptionVec_23                      (VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_isFetchMalAddr                       (VSSplitSkidBuffer_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException                         (VSSplitSkidBuffer_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger                              (VSSplitSkidBuffer_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid                  (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC                  (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType                 (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall                 (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet                  (VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken                           (VSSplitSkidBuffer_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix                      (VSSplitSkidBuffer_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag                          (VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value                         (VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset                            (VSSplitSkidBuffer_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault             (VSSplitSkidBuffer_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0                            (VSSplitSkidBuffer_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1                            (VSSplitSkidBuffer_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2                            (VSSplitSkidBuffer_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3                            (VSSplitSkidBuffer_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4                            (VSSplitSkidBuffer_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest                                (VSSplitSkidBuffer_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuType                               (VSSplitSkidBuffer_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType                             (VSSplitSkidBuffer_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen                                (VSSplitSkidBuffer_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen                                (VSSplitSkidBuffer_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen                               (VSSplitSkidBuffer_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen                                (VSSplitSkidBuffer_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen                                (VSSplitSkidBuffer_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap                             (VSSplitSkidBuffer_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward                          (VSSplitSkidBuffer_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward                        (VSSplitSkidBuffer_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress                       (VSSplitSkidBuffer_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm                               (VSSplitSkidBuffer_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut                       (VSSplitSkidBuffer_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags                           (VSSplitSkidBuffer_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ                              (VSSplitSkidBuffer_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt                              (VSSplitSkidBuffer_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm                               (VSSplitSkidBuffer_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul                            (VSSplitSkidBuffer_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul                        (VSSplitSkidBuffer_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm                               (VSSplitSkidBuffer_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm                              (VSSplitSkidBuffer_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst                (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr                  (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr                  (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction                  (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2                  (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4                  (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8                  (VSSplitSkidBuffer_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask                            (VSSplitSkidBuffer_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl                               (VSSplitSkidBuffer_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf                               (VSSplitSkidBuffer_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew                             (VSSplitSkidBuffer_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse                        (VSSplitSkidBuffer_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt                            (VSSplitSkidBuffer_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask                        (VSSplitSkidBuffer_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask                         (VSSplitSkidBuffer_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove                           (VSSplitSkidBuffer_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd                    (VSSplitSkidBuffer_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd                    (VSSplitSkidBuffer_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff                          (VSSplitSkidBuffer_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr                             (VSSplitSkidBuffer_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags                              (VSSplitSkidBuffer_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove                               (VSSplitSkidBuffer_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta                      (VSSplitSkidBuffer_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx                               (VSSplitSkidBuffer_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset                               (VSSplitSkidBuffer_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop                             (VSSplitSkidBuffer_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop                              (VSSplitSkidBuffer_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops                              (VSSplitSkidBuffer_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB                                (VSSplitSkidBuffer_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType                           (VSSplitSkidBuffer_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0                           (VSSplitSkidBuffer_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1                           (VSSplitSkidBuffer_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2                           (VSSplitSkidBuffer_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3                           (VSSplitSkidBuffer_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4                           (VSSplitSkidBuffer_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2                (VSSplitSkidBuffer_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0                               (VSSplitSkidBuffer_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1                               (VSSplitSkidBuffer_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2                               (VSSplitSkidBuffer_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3                               (VSSplitSkidBuffer_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4                               (VSSplitSkidBuffer_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest                                (VSSplitSkidBuffer_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0                        (VSSplitSkidBuffer_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1                        (VSSplitSkidBuffer_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0                        (VSSplitSkidBuffer_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1                        (VSSplitSkidBuffer_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag                          (VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value                         (VSSplitSkidBuffer_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize                            (VSSplitSkidBuffer_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs                              (VSSplitSkidBuffer_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs                              (VSSplitSkidBuffer_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype               (VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire             (VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize           (VSSplitSkidBuffer_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove                       (VSSplitSkidBuffer_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot                             (VSSplitSkidBuffer_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove             (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime                 (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime               (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime                  (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime                 (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime                  (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime              (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id     (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime            (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime                (VSSplitSkidBuffer_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum                  (VSSplitSkidBuffer_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx                  (VSSplitSkidBuffer_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit                          (VSSplitSkidBuffer_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag                   (VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value                  (VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit                          (VSSplitSkidBuffer_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict                       (VSSplitSkidBuffer_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid                                 (VSSplitSkidBuffer_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag                           (VSSplitSkidBuffer_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value                          (VSSplitSkidBuffer_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag                           (VSSplitSkidBuffer_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value                          (VSSplitSkidBuffer_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep                           (VSSplitSkidBuffer_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst                           (VSSplitSkidBuffer_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType                         (VSSplitSkidBuffer_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig                       (VSSplitSkidBuffer_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem                            (VSSplitSkidBuffer_io_out_bits_uop_numLsElem),
    .io_out_bits_preIsSplit                               (VSSplitSkidBuffer_io_out_bits_preIsSplit),
    .io_out_bits_mBIndex                                  (VSSplitSkidBuffer_io_out_bits_mBIndex),
    .io_out_bits_alignedType                              (VSSplitSkidBuffer_io_out_bits_alignedType),
    .io_out_bits_indexVlMaxInVd                           (VSSplitSkidBuffer_io_out_bits_indexVlMaxInVd),
    .io_out_bits_usLowBitsAddr                            (VSSplitSkidBuffer_io_out_bits_usLowBitsAddr),
    .io_out_bits_usAligned128                             (VSSplitSkidBuffer_io_out_bits_usAligned128),
    .io_out_bits_usMask                                   (VSSplitSkidBuffer_io_out_bits_usMask),
    .io_out_bits_isVecPartReplay                          (VSSplitSkidBuffer_io_out_bits_isVecPartReplay),
    .io_out_bits_vecReplayFlowMask                        (VSSplitSkidBuffer_io_out_bits_vecReplayFlowMask)
  );

  assign io_out_valid = splitBuffer_io_out_valid;

endmodule
// END GENERATED(wrapper_VSSplitImp)
