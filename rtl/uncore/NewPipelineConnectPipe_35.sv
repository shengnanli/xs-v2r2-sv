// NewPipelineConnectPipe_35.sv — 向量访存拆分器 → load/store 流水线之间的单拍流水缓冲。
// 例化点（G1 golden，共 4 处）：MemBlock.inner_VsSplitConnectStu / …Stu_1 /
//   inner_VlSplitConnectLdu / …Ldu_1 —— VsSplit/VlSplit 把一条向量访存指令拆成若干
//   逐元素/逐段的访存请求，每个请求带完整 uop 上下文，经本级送进标量 load/store 流水线。
// 本变体参数与规模：payload = 174 字段 / 1446 位，是全族最大的一个
//   （地址束 vaddr/basevaddr/mask/reg_offset/alignedType/vecActive… + 几乎完整的
//   DynInst uop 束 + mBIndex/elemIdx/elemIdxInsideVd/splitIndex 四个拆分索引）；
//   模块端口 356 个（180 输入 / 176 输出），带 io_isFlush；golden 模块体 1197 行。
// 家族关系：与全族共用一个核 xs_PipelineConnect（rtl/common/PipelineConnect.sv），
//   本文件只提供本变体的 payload 字段表与打包/拆包，不复制任何核逻辑。
//   核语义：in_ready = out_ready | ~valid；fire = in_valid & in_ready；
//   valid' = ~isFlush & (fire | ~rightOutFire & valid)（异步复位清 0）；
//   data = RegEnable(in_bits, fire)。
// 时序（逐字段从 G1 golden 机械核实）：**没有任何组合直通字段**，
//   preDecodeInfo_* / debugInfo_* 也一样是打拍透传。唯一的组合输出是 io_in_ready。
// ★名字警告★：本变体在 G0(v2r2) 里叫 NewPipelineConnectPipe_33（96 端口），
//   而 G1 里另有一个 NewPipelineConnectPipe_33（17 端口，VSegmentUnit 用）——
//   同名不同物。G1 的 _35 相对 G0 的 _33 多了 130 个字段（uop 束从 44 字段扩到 174）。
//   判据是例化坑位集合相等，见 scripts/check_name_collisions.py。

module NewPipelineConnectPipe_35 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [63:0] io_in_bits_vaddr,
  input  logic [49:0] io_in_bits_basevaddr,
  input  logic [15:0] io_in_bits_mask,
  input  logic [3:0] io_in_bits_reg_offset,
  input  logic [2:0] io_in_bits_alignedType,
  input  logic io_in_bits_vecActive,
  input  logic io_in_bits_vecIsFirstActiveElement,
  input  logic [31:0] io_in_bits_uop_instr,
  input  logic [49:0] io_in_bits_uop_pc,
  input  logic [9:0] io_in_bits_uop_foldpc,
  input  logic io_in_bits_uop_exceptionVec_4,
  input  logic io_in_bits_uop_exceptionVec_5,
  input  logic io_in_bits_uop_exceptionVec_6,
  input  logic io_in_bits_uop_exceptionVec_7,
  input  logic io_in_bits_uop_exceptionVec_13,
  input  logic io_in_bits_uop_exceptionVec_15,
  input  logic io_in_bits_uop_exceptionVec_19,
  input  logic io_in_bits_uop_exceptionVec_21,
  input  logic io_in_bits_uop_exceptionVec_23,
  input  logic io_in_bits_uop_isFetchMalAddr,
  input  logic io_in_bits_uop_hasException,
  input  logic [3:0] io_in_bits_uop_trigger,
  input  logic io_in_bits_uop_preDecodeInfo_valid,
  input  logic io_in_bits_uop_preDecodeInfo_isRVC,
  input  logic [1:0] io_in_bits_uop_preDecodeInfo_brType,
  input  logic io_in_bits_uop_preDecodeInfo_isCall,
  input  logic io_in_bits_uop_preDecodeInfo_isRet,
  input  logic io_in_bits_uop_pred_taken,
  input  logic io_in_bits_uop_crossPageIPFFix,
  input  logic io_in_bits_uop_ftqPtr_flag,
  input  logic [5:0] io_in_bits_uop_ftqPtr_value,
  input  logic [3:0] io_in_bits_uop_ftqOffset,
  input  logic io_in_bits_uop_satpFlushFirstFetchFault,
  input  logic [3:0] io_in_bits_uop_srcType_0,
  input  logic [3:0] io_in_bits_uop_srcType_1,
  input  logic [3:0] io_in_bits_uop_srcType_2,
  input  logic [3:0] io_in_bits_uop_srcType_3,
  input  logic [3:0] io_in_bits_uop_srcType_4,
  input  logic [5:0] io_in_bits_uop_ldest,
  input  logic [34:0] io_in_bits_uop_fuType,
  input  logic [8:0] io_in_bits_uop_fuOpType,
  input  logic io_in_bits_uop_rfWen,
  input  logic io_in_bits_uop_fpWen,
  input  logic io_in_bits_uop_vecWen,
  input  logic io_in_bits_uop_v0Wen,
  input  logic io_in_bits_uop_vlWen,
  input  logic io_in_bits_uop_isXSTrap,
  input  logic io_in_bits_uop_waitForward,
  input  logic io_in_bits_uop_blockBackward,
  input  logic io_in_bits_uop_canRobCompress,
  input  logic [3:0] io_in_bits_uop_selImm,
  input  logic [1:0] io_in_bits_uop_fpu_typeTagOut,
  input  logic io_in_bits_uop_fpu_wflags,
  input  logic [1:0] io_in_bits_uop_fpu_typ,
  input  logic [1:0] io_in_bits_uop_fpu_fmt,
  input  logic [2:0] io_in_bits_uop_fpu_rm,
  input  logic io_in_bits_uop_vpu_vill,
  input  logic io_in_bits_uop_vpu_vma,
  input  logic io_in_bits_uop_vpu_vta,
  input  logic [1:0] io_in_bits_uop_vpu_vsew,
  input  logic [2:0] io_in_bits_uop_vpu_vlmul,
  input  logic io_in_bits_uop_vpu_specVill,
  input  logic io_in_bits_uop_vpu_specVma,
  input  logic io_in_bits_uop_vpu_specVta,
  input  logic [1:0] io_in_bits_uop_vpu_specVsew,
  input  logic [2:0] io_in_bits_uop_vpu_specVlmul,
  input  logic io_in_bits_uop_vpu_vm,
  input  logic [7:0] io_in_bits_uop_vpu_vstart,
  input  logic [2:0] io_in_bits_uop_vpu_frm,
  input  logic io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic io_in_bits_uop_vpu_fpu_isFP32Instr,
  input  logic io_in_bits_uop_vpu_fpu_isFP64Instr,
  input  logic io_in_bits_uop_vpu_fpu_isReduction,
  input  logic io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0] io_in_bits_uop_vpu_vxrm,
  input  logic [6:0] io_in_bits_uop_vpu_vuopIdx,
  input  logic io_in_bits_uop_vpu_lastUop,
  input  logic [127:0] io_in_bits_uop_vpu_vmask,
  input  logic [7:0] io_in_bits_uop_vpu_vl,
  input  logic [2:0] io_in_bits_uop_vpu_nf,
  input  logic [1:0] io_in_bits_uop_vpu_veew,
  input  logic io_in_bits_uop_vpu_isReverse,
  input  logic io_in_bits_uop_vpu_isExt,
  input  logic io_in_bits_uop_vpu_isNarrow,
  input  logic io_in_bits_uop_vpu_isDstMask,
  input  logic io_in_bits_uop_vpu_isOpMask,
  input  logic io_in_bits_uop_vpu_isMove,
  input  logic io_in_bits_uop_vpu_isDependOldVd,
  input  logic io_in_bits_uop_vpu_isWritePartVd,
  input  logic io_in_bits_uop_vpu_isVleff,
  input  logic io_in_bits_uop_vlsInstr,
  input  logic io_in_bits_uop_wfflags,
  input  logic io_in_bits_uop_isMove,
  input  logic io_in_bits_uop_isDropAmocasSta,
  input  logic [6:0] io_in_bits_uop_uopIdx,
  input  logic io_in_bits_uop_isVset,
  input  logic io_in_bits_uop_firstUop,
  input  logic io_in_bits_uop_lastUop,
  input  logic [6:0] io_in_bits_uop_numUops,
  input  logic [6:0] io_in_bits_uop_numWB,
  input  logic [2:0] io_in_bits_uop_commitType,
  input  logic io_in_bits_uop_srcState_0,
  input  logic io_in_bits_uop_srcState_1,
  input  logic io_in_bits_uop_srcState_2,
  input  logic io_in_bits_uop_srcState_3,
  input  logic io_in_bits_uop_srcState_4,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_0_0,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_0_1,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_0_2,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_1_0,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_1_1,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_1_2,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_2_0,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_2_1,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_2_2,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_3_0,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_3_1,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_3_2,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_4_0,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_4_1,
  input  logic [1:0] io_in_bits_uop_srcLoadDependency_4_2,
  input  logic [7:0] io_in_bits_uop_psrc_0,
  input  logic [7:0] io_in_bits_uop_psrc_1,
  input  logic [7:0] io_in_bits_uop_psrc_2,
  input  logic [7:0] io_in_bits_uop_psrc_3,
  input  logic [7:0] io_in_bits_uop_psrc_4,
  input  logic [7:0] io_in_bits_uop_pdest,
  input  logic io_in_bits_uop_useRegCache_0,
  input  logic io_in_bits_uop_useRegCache_1,
  input  logic [4:0] io_in_bits_uop_regCacheIdx_0,
  input  logic [4:0] io_in_bits_uop_regCacheIdx_1,
  input  logic io_in_bits_uop_robIdx_flag,
  input  logic [7:0] io_in_bits_uop_robIdx_value,
  input  logic [2:0] io_in_bits_uop_instrSize,
  input  logic io_in_bits_uop_dirtyFs,
  input  logic io_in_bits_uop_dirtyVs,
  input  logic [3:0] io_in_bits_uop_traceBlockInPipe_itype,
  input  logic [3:0] io_in_bits_uop_traceBlockInPipe_iretire,
  input  logic io_in_bits_uop_traceBlockInPipe_ilastsize,
  input  logic io_in_bits_uop_eliminatedMove,
  input  logic io_in_bits_uop_snapshot,
  input  logic io_in_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0] io_in_bits_uop_debugInfo_renameTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_writebackTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0] io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0] io_in_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0] io_in_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0] io_in_bits_uop_debug_seqNum_uopIdx,
  input  logic io_in_bits_uop_storeSetHit,
  input  logic io_in_bits_uop_waitForRobIdx_flag,
  input  logic [7:0] io_in_bits_uop_waitForRobIdx_value,
  input  logic io_in_bits_uop_loadWaitBit,
  input  logic io_in_bits_uop_loadWaitStrict,
  input  logic [4:0] io_in_bits_uop_ssid,
  input  logic io_in_bits_uop_lqIdx_flag,
  input  logic [6:0] io_in_bits_uop_lqIdx_value,
  input  logic io_in_bits_uop_sqIdx_flag,
  input  logic [5:0] io_in_bits_uop_sqIdx_value,
  input  logic io_in_bits_uop_singleStep,
  input  logic io_in_bits_uop_replayInst,
  input  logic [34:0] io_in_bits_uop_debug_fuType,
  input  logic io_in_bits_uop_debug_sim_trig,
  input  logic [4:0] io_in_bits_uop_numLsElem,
  input  logic [3:0] io_in_bits_mBIndex,
  input  logic [7:0] io_in_bits_elemIdx,
  input  logic [7:0] io_in_bits_elemIdxInsideVd,
  input  logic [4:0] io_in_bits_splitIndex,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [63:0] io_out_bits_vaddr,
  output logic [49:0] io_out_bits_basevaddr,
  output logic [15:0] io_out_bits_mask,
  output logic [3:0] io_out_bits_reg_offset,
  output logic [2:0] io_out_bits_alignedType,
  output logic io_out_bits_vecActive,
  output logic io_out_bits_vecIsFirstActiveElement,
  output logic [31:0] io_out_bits_uop_instr,
  output logic [49:0] io_out_bits_uop_pc,
  output logic [9:0] io_out_bits_uop_foldpc,
  output logic io_out_bits_uop_exceptionVec_4,
  output logic io_out_bits_uop_exceptionVec_5,
  output logic io_out_bits_uop_exceptionVec_6,
  output logic io_out_bits_uop_exceptionVec_7,
  output logic io_out_bits_uop_exceptionVec_13,
  output logic io_out_bits_uop_exceptionVec_15,
  output logic io_out_bits_uop_exceptionVec_19,
  output logic io_out_bits_uop_exceptionVec_21,
  output logic io_out_bits_uop_exceptionVec_23,
  output logic io_out_bits_uop_isFetchMalAddr,
  output logic io_out_bits_uop_hasException,
  output logic [3:0] io_out_bits_uop_trigger,
  output logic io_out_bits_uop_preDecodeInfo_valid,
  output logic io_out_bits_uop_preDecodeInfo_isRVC,
  output logic [1:0] io_out_bits_uop_preDecodeInfo_brType,
  output logic io_out_bits_uop_preDecodeInfo_isCall,
  output logic io_out_bits_uop_preDecodeInfo_isRet,
  output logic io_out_bits_uop_pred_taken,
  output logic io_out_bits_uop_crossPageIPFFix,
  output logic io_out_bits_uop_ftqPtr_flag,
  output logic [5:0] io_out_bits_uop_ftqPtr_value,
  output logic [3:0] io_out_bits_uop_ftqOffset,
  output logic io_out_bits_uop_satpFlushFirstFetchFault,
  output logic [3:0] io_out_bits_uop_srcType_0,
  output logic [3:0] io_out_bits_uop_srcType_1,
  output logic [3:0] io_out_bits_uop_srcType_2,
  output logic [3:0] io_out_bits_uop_srcType_3,
  output logic [3:0] io_out_bits_uop_srcType_4,
  output logic [5:0] io_out_bits_uop_ldest,
  output logic [34:0] io_out_bits_uop_fuType,
  output logic [8:0] io_out_bits_uop_fuOpType,
  output logic io_out_bits_uop_rfWen,
  output logic io_out_bits_uop_fpWen,
  output logic io_out_bits_uop_vecWen,
  output logic io_out_bits_uop_v0Wen,
  output logic io_out_bits_uop_vlWen,
  output logic io_out_bits_uop_isXSTrap,
  output logic io_out_bits_uop_waitForward,
  output logic io_out_bits_uop_blockBackward,
  output logic io_out_bits_uop_canRobCompress,
  output logic [3:0] io_out_bits_uop_selImm,
  output logic [1:0] io_out_bits_uop_fpu_typeTagOut,
  output logic io_out_bits_uop_fpu_wflags,
  output logic [1:0] io_out_bits_uop_fpu_typ,
  output logic [1:0] io_out_bits_uop_fpu_fmt,
  output logic [2:0] io_out_bits_uop_fpu_rm,
  output logic io_out_bits_uop_vpu_vill,
  output logic io_out_bits_uop_vpu_vma,
  output logic io_out_bits_uop_vpu_vta,
  output logic [1:0] io_out_bits_uop_vpu_vsew,
  output logic [2:0] io_out_bits_uop_vpu_vlmul,
  output logic io_out_bits_uop_vpu_specVill,
  output logic io_out_bits_uop_vpu_specVma,
  output logic io_out_bits_uop_vpu_specVta,
  output logic [1:0] io_out_bits_uop_vpu_specVsew,
  output logic [2:0] io_out_bits_uop_vpu_specVlmul,
  output logic io_out_bits_uop_vpu_vm,
  output logic [7:0] io_out_bits_uop_vpu_vstart,
  output logic [2:0] io_out_bits_uop_vpu_frm,
  output logic io_out_bits_uop_vpu_fpu_isFpToVecInst,
  output logic io_out_bits_uop_vpu_fpu_isFP32Instr,
  output logic io_out_bits_uop_vpu_fpu_isFP64Instr,
  output logic io_out_bits_uop_vpu_fpu_isReduction,
  output logic io_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output logic io_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output logic io_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output logic [1:0] io_out_bits_uop_vpu_vxrm,
  output logic [6:0] io_out_bits_uop_vpu_vuopIdx,
  output logic io_out_bits_uop_vpu_lastUop,
  output logic [127:0] io_out_bits_uop_vpu_vmask,
  output logic [7:0] io_out_bits_uop_vpu_vl,
  output logic [2:0] io_out_bits_uop_vpu_nf,
  output logic [1:0] io_out_bits_uop_vpu_veew,
  output logic io_out_bits_uop_vpu_isReverse,
  output logic io_out_bits_uop_vpu_isExt,
  output logic io_out_bits_uop_vpu_isNarrow,
  output logic io_out_bits_uop_vpu_isDstMask,
  output logic io_out_bits_uop_vpu_isOpMask,
  output logic io_out_bits_uop_vpu_isMove,
  output logic io_out_bits_uop_vpu_isDependOldVd,
  output logic io_out_bits_uop_vpu_isWritePartVd,
  output logic io_out_bits_uop_vpu_isVleff,
  output logic io_out_bits_uop_vlsInstr,
  output logic io_out_bits_uop_wfflags,
  output logic io_out_bits_uop_isMove,
  output logic io_out_bits_uop_isDropAmocasSta,
  output logic [6:0] io_out_bits_uop_uopIdx,
  output logic io_out_bits_uop_isVset,
  output logic io_out_bits_uop_firstUop,
  output logic io_out_bits_uop_lastUop,
  output logic [6:0] io_out_bits_uop_numUops,
  output logic [6:0] io_out_bits_uop_numWB,
  output logic [2:0] io_out_bits_uop_commitType,
  output logic io_out_bits_uop_srcState_0,
  output logic io_out_bits_uop_srcState_1,
  output logic io_out_bits_uop_srcState_2,
  output logic io_out_bits_uop_srcState_3,
  output logic io_out_bits_uop_srcState_4,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_0_0,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_0_1,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_0_2,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_1_0,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_1_1,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_1_2,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_2_0,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_2_1,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_2_2,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_3_0,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_3_1,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_3_2,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_4_0,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_4_1,
  output logic [1:0] io_out_bits_uop_srcLoadDependency_4_2,
  output logic [7:0] io_out_bits_uop_psrc_0,
  output logic [7:0] io_out_bits_uop_psrc_1,
  output logic [7:0] io_out_bits_uop_psrc_2,
  output logic [7:0] io_out_bits_uop_psrc_3,
  output logic [7:0] io_out_bits_uop_psrc_4,
  output logic [7:0] io_out_bits_uop_pdest,
  output logic io_out_bits_uop_useRegCache_0,
  output logic io_out_bits_uop_useRegCache_1,
  output logic [4:0] io_out_bits_uop_regCacheIdx_0,
  output logic [4:0] io_out_bits_uop_regCacheIdx_1,
  output logic io_out_bits_uop_robIdx_flag,
  output logic [7:0] io_out_bits_uop_robIdx_value,
  output logic [2:0] io_out_bits_uop_instrSize,
  output logic io_out_bits_uop_dirtyFs,
  output logic io_out_bits_uop_dirtyVs,
  output logic [3:0] io_out_bits_uop_traceBlockInPipe_itype,
  output logic [3:0] io_out_bits_uop_traceBlockInPipe_iretire,
  output logic io_out_bits_uop_traceBlockInPipe_ilastsize,
  output logic io_out_bits_uop_eliminatedMove,
  output logic io_out_bits_uop_snapshot,
  output logic io_out_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0] io_out_bits_uop_debugInfo_renameTime,
  output logic [63:0] io_out_bits_uop_debugInfo_dispatchTime,
  output logic [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output logic [63:0] io_out_bits_uop_debugInfo_selectTime,
  output logic [63:0] io_out_bits_uop_debugInfo_issueTime,
  output logic [63:0] io_out_bits_uop_debugInfo_writebackTime,
  output logic [63:0] io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0] io_out_bits_uop_debug_seqNum_seqNum,
  output logic [7:0] io_out_bits_uop_debug_seqNum_uopIdx,
  output logic io_out_bits_uop_storeSetHit,
  output logic io_out_bits_uop_waitForRobIdx_flag,
  output logic [7:0] io_out_bits_uop_waitForRobIdx_value,
  output logic io_out_bits_uop_loadWaitBit,
  output logic io_out_bits_uop_loadWaitStrict,
  output logic [4:0] io_out_bits_uop_ssid,
  output logic io_out_bits_uop_lqIdx_flag,
  output logic [6:0] io_out_bits_uop_lqIdx_value,
  output logic io_out_bits_uop_sqIdx_flag,
  output logic [5:0] io_out_bits_uop_sqIdx_value,
  output logic io_out_bits_uop_singleStep,
  output logic io_out_bits_uop_replayInst,
  output logic [34:0] io_out_bits_uop_debug_fuType,
  output logic io_out_bits_uop_debug_sim_trig,
  output logic [4:0] io_out_bits_uop_numLsElem,
  output logic [3:0] io_out_bits_mBIndex,
  output logic [7:0] io_out_bits_elemIdx,
  output logic [7:0] io_out_bits_elemIdxInsideVd,
  output logic [4:0] io_out_bits_splitIndex,
  input  logic io_rightOutFire,
  input  logic io_isFlush
);

  // ---------------------------------------------------------------------------
  // 本变体的 payload 布局。用 packed struct 而不是手工位切片：入口打包与出口拆包
  // 都按同一组成员名访问，"字段错位"在结构上就不可能发生（这一族历史上正是
  // 手工切片 + 照抄错基线的端口表而集体配错）。成员顺序照 G1 golden 端口表，
  // 顺序本身不影响功能——核只把 payload 当一坨位搬运。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    // 本级自己的数据字段（不属于 uop 束）
    logic [63:0]    vaddr;
    logic [49:0]    basevaddr;
    logic [15:0]    mask;
    logic [3:0]     reg_offset;
    logic [2:0]     alignedType;
    logic           vecActive;
    logic           vecIsFirstActiveElement;
    // uop：微操作本身的控制位
    logic [31:0]    uop_instr;
    logic [49:0]    uop_pc;
    logic [9:0]     uop_foldpc;
    // uop.exceptionVec：异常向量，本变体只导出用得到的 9 号位 —— 4/5/6/7/13/15/19/21/23（编号不连续）
    logic           uop_exceptionVec_4;
    logic           uop_exceptionVec_5;
    logic           uop_exceptionVec_6;
    logic           uop_exceptionVec_7;
    logic           uop_exceptionVec_13;
    logic           uop_exceptionVec_15;
    logic           uop_exceptionVec_19;
    logic           uop_exceptionVec_21;
    logic           uop_exceptionVec_23;
    // uop（续）
    logic           uop_isFetchMalAddr;
    logic           uop_hasException;
    logic [3:0]     uop_trigger;
    // uop.preDecodeInfo：前端预译码信息（打拍透传，非组合直通）
    logic           uop_preDecodeInfo_valid;
    logic           uop_preDecodeInfo_isRVC;
    logic [1:0]     uop_preDecodeInfo_brType;
    logic           uop_preDecodeInfo_isCall;
    logic           uop_preDecodeInfo_isRet;
    // uop（续）
    logic           uop_pred_taken;
    logic           uop_crossPageIPFFix;
    // uop.ftq*：取指队列指针与块内偏移
    logic           uop_ftqPtr_flag;
    logic [5:0]     uop_ftqPtr_value;
    logic [3:0]     uop_ftqOffset;
    // uop（续）
    logic           uop_satpFlushFirstFetchFault;
    // uop.srcType：5 个源的类型编码
    logic [3:0]     uop_srcType_0;
    logic [3:0]     uop_srcType_1;
    logic [3:0]     uop_srcType_2;
    logic [3:0]     uop_srcType_3;
    logic [3:0]     uop_srcType_4;
    // uop（续）
    logic [5:0]     uop_ldest;
    logic [34:0]    uop_fuType;
    logic [8:0]     uop_fuOpType;
    logic           uop_rfWen;
    logic           uop_fpWen;
    logic           uop_vecWen;
    logic           uop_v0Wen;
    logic           uop_vlWen;
    logic           uop_isXSTrap;
    logic           uop_waitForward;
    logic           uop_blockBackward;
    logic           uop_canRobCompress;
    logic [3:0]     uop_selImm;
    // uop.fpu：标量浮点控制（fmt/rm/typ/wflags）
    logic [1:0]     uop_fpu_typeTagOut;
    logic           uop_fpu_wflags;
    logic [1:0]     uop_fpu_typ;
    logic [1:0]     uop_fpu_fmt;
    logic [2:0]     uop_fpu_rm;
    // uop.vpu：向量控制束（vtype 现态与推测态、vl/vstart/vmask、各类形态标志）
    logic           uop_vpu_vill;
    logic           uop_vpu_vma;
    logic           uop_vpu_vta;
    logic [1:0]     uop_vpu_vsew;
    logic [2:0]     uop_vpu_vlmul;
    logic           uop_vpu_specVill;
    logic           uop_vpu_specVma;
    logic           uop_vpu_specVta;
    logic [1:0]     uop_vpu_specVsew;
    logic [2:0]     uop_vpu_specVlmul;
    logic           uop_vpu_vm;
    logic [7:0]     uop_vpu_vstart;
    logic [2:0]     uop_vpu_frm;
    // uop.vpu.fpu：向量指令里的浮点子束（folding / reduction / 精度标志）
    logic           uop_vpu_fpu_isFpToVecInst;
    logic           uop_vpu_fpu_isFP32Instr;
    logic           uop_vpu_fpu_isFP64Instr;
    logic           uop_vpu_fpu_isReduction;
    logic           uop_vpu_fpu_isFoldTo1_2;
    logic           uop_vpu_fpu_isFoldTo1_4;
    logic           uop_vpu_fpu_isFoldTo1_8;
    // uop.vpu（续）
    logic [1:0]     uop_vpu_vxrm;
    logic [6:0]     uop_vpu_vuopIdx;
    logic           uop_vpu_lastUop;
    logic [127:0]   uop_vpu_vmask;
    logic [7:0]     uop_vpu_vl;
    logic [2:0]     uop_vpu_nf;
    logic [1:0]     uop_vpu_veew;
    logic           uop_vpu_isReverse;
    logic           uop_vpu_isExt;
    logic           uop_vpu_isNarrow;
    logic           uop_vpu_isDstMask;
    logic           uop_vpu_isOpMask;
    logic           uop_vpu_isMove;
    logic           uop_vpu_isDependOldVd;
    logic           uop_vpu_isWritePartVd;
    logic           uop_vpu_isVleff;
    // uop（续）
    logic           uop_vlsInstr;
    logic           uop_wfflags;
    logic           uop_isMove;
    logic           uop_isDropAmocasSta;
    logic [6:0]     uop_uopIdx;
    logic           uop_isVset;
    logic           uop_firstUop;
    logic           uop_lastUop;
    logic [6:0]     uop_numUops;
    logic [6:0]     uop_numWB;
    logic [2:0]     uop_commitType;
    // uop.srcState：5 个源的就绪位
    logic           uop_srcState_0;
    logic           uop_srcState_1;
    logic           uop_srcState_2;
    logic           uop_srcState_3;
    logic           uop_srcState_4;
    // uop.srcLoadDependency：5 个源 × 3 级的 load 依赖倒计时
    logic [1:0]     uop_srcLoadDependency_0_0;
    logic [1:0]     uop_srcLoadDependency_0_1;
    logic [1:0]     uop_srcLoadDependency_0_2;
    logic [1:0]     uop_srcLoadDependency_1_0;
    logic [1:0]     uop_srcLoadDependency_1_1;
    logic [1:0]     uop_srcLoadDependency_1_2;
    logic [1:0]     uop_srcLoadDependency_2_0;
    logic [1:0]     uop_srcLoadDependency_2_1;
    logic [1:0]     uop_srcLoadDependency_2_2;
    logic [1:0]     uop_srcLoadDependency_3_0;
    logic [1:0]     uop_srcLoadDependency_3_1;
    logic [1:0]     uop_srcLoadDependency_3_2;
    logic [1:0]     uop_srcLoadDependency_4_0;
    logic [1:0]     uop_srcLoadDependency_4_1;
    logic [1:0]     uop_srcLoadDependency_4_2;
    // uop.psrc：物理源寄存器号
    logic [7:0]     uop_psrc_0;
    logic [7:0]     uop_psrc_1;
    logic [7:0]     uop_psrc_2;
    logic [7:0]     uop_psrc_3;
    logic [7:0]     uop_psrc_4;
    // uop（续）
    logic [7:0]     uop_pdest;
    // uop.useRegCache / uop.regCacheIdx：寄存器缓存旁路
    logic           uop_useRegCache_0;
    logic           uop_useRegCache_1;
    logic [4:0]     uop_regCacheIdx_0;
    logic [4:0]     uop_regCacheIdx_1;
    // uop.robIdx：ROB 表项指针（flag = 回绕位）
    logic           uop_robIdx_flag;
    logic [7:0]     uop_robIdx_value;
    // uop（续）
    logic [2:0]     uop_instrSize;
    logic           uop_dirtyFs;
    logic           uop_dirtyVs;
    // uop.traceBlockInPipe：指令轨迹（RISC-V trace）字段
    logic [3:0]     uop_traceBlockInPipe_itype;
    logic [3:0]     uop_traceBlockInPipe_iretire;
    logic           uop_traceBlockInPipe_ilastsize;
    // uop（续）
    logic           uop_eliminatedMove;
    logic           uop_snapshot;
    // uop.debugInfo：性能剖析时间戳。**随流水打拍透传，不是组合直通**
    logic           uop_debugInfo_eliminatedMove;
    logic [63:0]    uop_debugInfo_renameTime;
    logic [63:0]    uop_debugInfo_dispatchTime;
    logic [63:0]    uop_debugInfo_enqRsTime;
    logic [63:0]    uop_debugInfo_selectTime;
    logic [63:0]    uop_debugInfo_issueTime;
    logic [63:0]    uop_debugInfo_writebackTime;
    logic [63:0]    uop_debugInfo_runahead_checkpoint_id;
    logic [63:0]    uop_debugInfo_tlbFirstReqTime;
    logic [63:0]    uop_debugInfo_tlbRespTime;
    // uop.debug.seqNum：调试用指令序号
    logic [55:0]    uop_debug_seqNum_seqNum;
    logic [7:0]     uop_debug_seqNum_uopIdx;
    // uop（续）
    logic           uop_storeSetHit;
    // uop.waitForRobIdx：store set 依赖的 ROB 指针
    logic           uop_waitForRobIdx_flag;
    logic [7:0]     uop_waitForRobIdx_value;
    // uop（续）
    logic           uop_loadWaitBit;
    logic           uop_loadWaitStrict;
    logic [4:0]     uop_ssid;
    // uop.lqIdx：load queue 指针（flag = 回绕位）
    logic           uop_lqIdx_flag;
    logic [6:0]     uop_lqIdx_value;
    // uop.sqIdx：store queue 指针（flag = 回绕位）
    logic           uop_sqIdx_flag;
    logic [5:0]     uop_sqIdx_value;
    // uop（续）
    logic           uop_singleStep;
    logic           uop_replayInst;
    // uop.debug_*：调试用透传字段
    logic [34:0]    uop_debug_fuType;
    logic           uop_debug_sim_trig;
    // uop（续）
    logic [4:0]     uop_numLsElem;
    // 本级自己的数据字段（不属于 uop 束）（续）
    logic [3:0]     mBIndex;
    logic [7:0]     elemIdx;
    logic [7:0]     elemIdxInsideVd;
    logic [4:0]     splitIndex;
  } payload_t;

  // G1 golden 该变体所有 io_in_bits_* 的位宽之和。传给共享核做防呆：
  // 核里的 initial 会校验 DATA_WIDTH（= $bits(payload_t)）与它相等。
  // ★这个参数必须显式传★——核给了默认值 PAYLOAD_W_G1 = DATA_WIDTH，省略即等于不校验。
  localparam int unsigned PAYLOAD_W_G1 = 1446;

  payload_t in_payload, out_payload;

  // 入口打包：端口 -> struct 成员（同名逐项）
  always_comb begin
    in_payload.vaddr                                = io_in_bits_vaddr;
    in_payload.basevaddr                            = io_in_bits_basevaddr;
    in_payload.mask                                 = io_in_bits_mask;
    in_payload.reg_offset                           = io_in_bits_reg_offset;
    in_payload.alignedType                          = io_in_bits_alignedType;
    in_payload.vecActive                            = io_in_bits_vecActive;
    in_payload.vecIsFirstActiveElement              = io_in_bits_vecIsFirstActiveElement;
    in_payload.uop_instr                            = io_in_bits_uop_instr;
    in_payload.uop_pc                               = io_in_bits_uop_pc;
    in_payload.uop_foldpc                           = io_in_bits_uop_foldpc;
    in_payload.uop_exceptionVec_4                   = io_in_bits_uop_exceptionVec_4;
    in_payload.uop_exceptionVec_5                   = io_in_bits_uop_exceptionVec_5;
    in_payload.uop_exceptionVec_6                   = io_in_bits_uop_exceptionVec_6;
    in_payload.uop_exceptionVec_7                   = io_in_bits_uop_exceptionVec_7;
    in_payload.uop_exceptionVec_13                  = io_in_bits_uop_exceptionVec_13;
    in_payload.uop_exceptionVec_15                  = io_in_bits_uop_exceptionVec_15;
    in_payload.uop_exceptionVec_19                  = io_in_bits_uop_exceptionVec_19;
    in_payload.uop_exceptionVec_21                  = io_in_bits_uop_exceptionVec_21;
    in_payload.uop_exceptionVec_23                  = io_in_bits_uop_exceptionVec_23;
    in_payload.uop_isFetchMalAddr                   = io_in_bits_uop_isFetchMalAddr;
    in_payload.uop_hasException                     = io_in_bits_uop_hasException;
    in_payload.uop_trigger                          = io_in_bits_uop_trigger;
    in_payload.uop_preDecodeInfo_valid              = io_in_bits_uop_preDecodeInfo_valid;
    in_payload.uop_preDecodeInfo_isRVC              = io_in_bits_uop_preDecodeInfo_isRVC;
    in_payload.uop_preDecodeInfo_brType             = io_in_bits_uop_preDecodeInfo_brType;
    in_payload.uop_preDecodeInfo_isCall             = io_in_bits_uop_preDecodeInfo_isCall;
    in_payload.uop_preDecodeInfo_isRet              = io_in_bits_uop_preDecodeInfo_isRet;
    in_payload.uop_pred_taken                       = io_in_bits_uop_pred_taken;
    in_payload.uop_crossPageIPFFix                  = io_in_bits_uop_crossPageIPFFix;
    in_payload.uop_ftqPtr_flag                      = io_in_bits_uop_ftqPtr_flag;
    in_payload.uop_ftqPtr_value                     = io_in_bits_uop_ftqPtr_value;
    in_payload.uop_ftqOffset                        = io_in_bits_uop_ftqOffset;
    in_payload.uop_satpFlushFirstFetchFault         = io_in_bits_uop_satpFlushFirstFetchFault;
    in_payload.uop_srcType_0                        = io_in_bits_uop_srcType_0;
    in_payload.uop_srcType_1                        = io_in_bits_uop_srcType_1;
    in_payload.uop_srcType_2                        = io_in_bits_uop_srcType_2;
    in_payload.uop_srcType_3                        = io_in_bits_uop_srcType_3;
    in_payload.uop_srcType_4                        = io_in_bits_uop_srcType_4;
    in_payload.uop_ldest                            = io_in_bits_uop_ldest;
    in_payload.uop_fuType                           = io_in_bits_uop_fuType;
    in_payload.uop_fuOpType                         = io_in_bits_uop_fuOpType;
    in_payload.uop_rfWen                            = io_in_bits_uop_rfWen;
    in_payload.uop_fpWen                            = io_in_bits_uop_fpWen;
    in_payload.uop_vecWen                           = io_in_bits_uop_vecWen;
    in_payload.uop_v0Wen                            = io_in_bits_uop_v0Wen;
    in_payload.uop_vlWen                            = io_in_bits_uop_vlWen;
    in_payload.uop_isXSTrap                         = io_in_bits_uop_isXSTrap;
    in_payload.uop_waitForward                      = io_in_bits_uop_waitForward;
    in_payload.uop_blockBackward                    = io_in_bits_uop_blockBackward;
    in_payload.uop_canRobCompress                   = io_in_bits_uop_canRobCompress;
    in_payload.uop_selImm                           = io_in_bits_uop_selImm;
    in_payload.uop_fpu_typeTagOut                   = io_in_bits_uop_fpu_typeTagOut;
    in_payload.uop_fpu_wflags                       = io_in_bits_uop_fpu_wflags;
    in_payload.uop_fpu_typ                          = io_in_bits_uop_fpu_typ;
    in_payload.uop_fpu_fmt                          = io_in_bits_uop_fpu_fmt;
    in_payload.uop_fpu_rm                           = io_in_bits_uop_fpu_rm;
    in_payload.uop_vpu_vill                         = io_in_bits_uop_vpu_vill;
    in_payload.uop_vpu_vma                          = io_in_bits_uop_vpu_vma;
    in_payload.uop_vpu_vta                          = io_in_bits_uop_vpu_vta;
    in_payload.uop_vpu_vsew                         = io_in_bits_uop_vpu_vsew;
    in_payload.uop_vpu_vlmul                        = io_in_bits_uop_vpu_vlmul;
    in_payload.uop_vpu_specVill                     = io_in_bits_uop_vpu_specVill;
    in_payload.uop_vpu_specVma                      = io_in_bits_uop_vpu_specVma;
    in_payload.uop_vpu_specVta                      = io_in_bits_uop_vpu_specVta;
    in_payload.uop_vpu_specVsew                     = io_in_bits_uop_vpu_specVsew;
    in_payload.uop_vpu_specVlmul                    = io_in_bits_uop_vpu_specVlmul;
    in_payload.uop_vpu_vm                           = io_in_bits_uop_vpu_vm;
    in_payload.uop_vpu_vstart                       = io_in_bits_uop_vpu_vstart;
    in_payload.uop_vpu_frm                          = io_in_bits_uop_vpu_frm;
    in_payload.uop_vpu_fpu_isFpToVecInst            = io_in_bits_uop_vpu_fpu_isFpToVecInst;
    in_payload.uop_vpu_fpu_isFP32Instr              = io_in_bits_uop_vpu_fpu_isFP32Instr;
    in_payload.uop_vpu_fpu_isFP64Instr              = io_in_bits_uop_vpu_fpu_isFP64Instr;
    in_payload.uop_vpu_fpu_isReduction              = io_in_bits_uop_vpu_fpu_isReduction;
    in_payload.uop_vpu_fpu_isFoldTo1_2              = io_in_bits_uop_vpu_fpu_isFoldTo1_2;
    in_payload.uop_vpu_fpu_isFoldTo1_4              = io_in_bits_uop_vpu_fpu_isFoldTo1_4;
    in_payload.uop_vpu_fpu_isFoldTo1_8              = io_in_bits_uop_vpu_fpu_isFoldTo1_8;
    in_payload.uop_vpu_vxrm                         = io_in_bits_uop_vpu_vxrm;
    in_payload.uop_vpu_vuopIdx                      = io_in_bits_uop_vpu_vuopIdx;
    in_payload.uop_vpu_lastUop                      = io_in_bits_uop_vpu_lastUop;
    in_payload.uop_vpu_vmask                        = io_in_bits_uop_vpu_vmask;
    in_payload.uop_vpu_vl                           = io_in_bits_uop_vpu_vl;
    in_payload.uop_vpu_nf                           = io_in_bits_uop_vpu_nf;
    in_payload.uop_vpu_veew                         = io_in_bits_uop_vpu_veew;
    in_payload.uop_vpu_isReverse                    = io_in_bits_uop_vpu_isReverse;
    in_payload.uop_vpu_isExt                        = io_in_bits_uop_vpu_isExt;
    in_payload.uop_vpu_isNarrow                     = io_in_bits_uop_vpu_isNarrow;
    in_payload.uop_vpu_isDstMask                    = io_in_bits_uop_vpu_isDstMask;
    in_payload.uop_vpu_isOpMask                     = io_in_bits_uop_vpu_isOpMask;
    in_payload.uop_vpu_isMove                       = io_in_bits_uop_vpu_isMove;
    in_payload.uop_vpu_isDependOldVd                = io_in_bits_uop_vpu_isDependOldVd;
    in_payload.uop_vpu_isWritePartVd                = io_in_bits_uop_vpu_isWritePartVd;
    in_payload.uop_vpu_isVleff                      = io_in_bits_uop_vpu_isVleff;
    in_payload.uop_vlsInstr                         = io_in_bits_uop_vlsInstr;
    in_payload.uop_wfflags                          = io_in_bits_uop_wfflags;
    in_payload.uop_isMove                           = io_in_bits_uop_isMove;
    in_payload.uop_isDropAmocasSta                  = io_in_bits_uop_isDropAmocasSta;
    in_payload.uop_uopIdx                           = io_in_bits_uop_uopIdx;
    in_payload.uop_isVset                           = io_in_bits_uop_isVset;
    in_payload.uop_firstUop                         = io_in_bits_uop_firstUop;
    in_payload.uop_lastUop                          = io_in_bits_uop_lastUop;
    in_payload.uop_numUops                          = io_in_bits_uop_numUops;
    in_payload.uop_numWB                            = io_in_bits_uop_numWB;
    in_payload.uop_commitType                       = io_in_bits_uop_commitType;
    in_payload.uop_srcState_0                       = io_in_bits_uop_srcState_0;
    in_payload.uop_srcState_1                       = io_in_bits_uop_srcState_1;
    in_payload.uop_srcState_2                       = io_in_bits_uop_srcState_2;
    in_payload.uop_srcState_3                       = io_in_bits_uop_srcState_3;
    in_payload.uop_srcState_4                       = io_in_bits_uop_srcState_4;
    in_payload.uop_srcLoadDependency_0_0            = io_in_bits_uop_srcLoadDependency_0_0;
    in_payload.uop_srcLoadDependency_0_1            = io_in_bits_uop_srcLoadDependency_0_1;
    in_payload.uop_srcLoadDependency_0_2            = io_in_bits_uop_srcLoadDependency_0_2;
    in_payload.uop_srcLoadDependency_1_0            = io_in_bits_uop_srcLoadDependency_1_0;
    in_payload.uop_srcLoadDependency_1_1            = io_in_bits_uop_srcLoadDependency_1_1;
    in_payload.uop_srcLoadDependency_1_2            = io_in_bits_uop_srcLoadDependency_1_2;
    in_payload.uop_srcLoadDependency_2_0            = io_in_bits_uop_srcLoadDependency_2_0;
    in_payload.uop_srcLoadDependency_2_1            = io_in_bits_uop_srcLoadDependency_2_1;
    in_payload.uop_srcLoadDependency_2_2            = io_in_bits_uop_srcLoadDependency_2_2;
    in_payload.uop_srcLoadDependency_3_0            = io_in_bits_uop_srcLoadDependency_3_0;
    in_payload.uop_srcLoadDependency_3_1            = io_in_bits_uop_srcLoadDependency_3_1;
    in_payload.uop_srcLoadDependency_3_2            = io_in_bits_uop_srcLoadDependency_3_2;
    in_payload.uop_srcLoadDependency_4_0            = io_in_bits_uop_srcLoadDependency_4_0;
    in_payload.uop_srcLoadDependency_4_1            = io_in_bits_uop_srcLoadDependency_4_1;
    in_payload.uop_srcLoadDependency_4_2            = io_in_bits_uop_srcLoadDependency_4_2;
    in_payload.uop_psrc_0                           = io_in_bits_uop_psrc_0;
    in_payload.uop_psrc_1                           = io_in_bits_uop_psrc_1;
    in_payload.uop_psrc_2                           = io_in_bits_uop_psrc_2;
    in_payload.uop_psrc_3                           = io_in_bits_uop_psrc_3;
    in_payload.uop_psrc_4                           = io_in_bits_uop_psrc_4;
    in_payload.uop_pdest                            = io_in_bits_uop_pdest;
    in_payload.uop_useRegCache_0                    = io_in_bits_uop_useRegCache_0;
    in_payload.uop_useRegCache_1                    = io_in_bits_uop_useRegCache_1;
    in_payload.uop_regCacheIdx_0                    = io_in_bits_uop_regCacheIdx_0;
    in_payload.uop_regCacheIdx_1                    = io_in_bits_uop_regCacheIdx_1;
    in_payload.uop_robIdx_flag                      = io_in_bits_uop_robIdx_flag;
    in_payload.uop_robIdx_value                     = io_in_bits_uop_robIdx_value;
    in_payload.uop_instrSize                        = io_in_bits_uop_instrSize;
    in_payload.uop_dirtyFs                          = io_in_bits_uop_dirtyFs;
    in_payload.uop_dirtyVs                          = io_in_bits_uop_dirtyVs;
    in_payload.uop_traceBlockInPipe_itype           = io_in_bits_uop_traceBlockInPipe_itype;
    in_payload.uop_traceBlockInPipe_iretire         = io_in_bits_uop_traceBlockInPipe_iretire;
    in_payload.uop_traceBlockInPipe_ilastsize       = io_in_bits_uop_traceBlockInPipe_ilastsize;
    in_payload.uop_eliminatedMove                   = io_in_bits_uop_eliminatedMove;
    in_payload.uop_snapshot                         = io_in_bits_uop_snapshot;
    in_payload.uop_debugInfo_eliminatedMove         = io_in_bits_uop_debugInfo_eliminatedMove;
    in_payload.uop_debugInfo_renameTime             = io_in_bits_uop_debugInfo_renameTime;
    in_payload.uop_debugInfo_dispatchTime           = io_in_bits_uop_debugInfo_dispatchTime;
    in_payload.uop_debugInfo_enqRsTime              = io_in_bits_uop_debugInfo_enqRsTime;
    in_payload.uop_debugInfo_selectTime             = io_in_bits_uop_debugInfo_selectTime;
    in_payload.uop_debugInfo_issueTime              = io_in_bits_uop_debugInfo_issueTime;
    in_payload.uop_debugInfo_writebackTime          = io_in_bits_uop_debugInfo_writebackTime;
    in_payload.uop_debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in_payload.uop_debugInfo_tlbFirstReqTime        = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in_payload.uop_debugInfo_tlbRespTime            = io_in_bits_uop_debugInfo_tlbRespTime;
    in_payload.uop_debug_seqNum_seqNum              = io_in_bits_uop_debug_seqNum_seqNum;
    in_payload.uop_debug_seqNum_uopIdx              = io_in_bits_uop_debug_seqNum_uopIdx;
    in_payload.uop_storeSetHit                      = io_in_bits_uop_storeSetHit;
    in_payload.uop_waitForRobIdx_flag               = io_in_bits_uop_waitForRobIdx_flag;
    in_payload.uop_waitForRobIdx_value              = io_in_bits_uop_waitForRobIdx_value;
    in_payload.uop_loadWaitBit                      = io_in_bits_uop_loadWaitBit;
    in_payload.uop_loadWaitStrict                   = io_in_bits_uop_loadWaitStrict;
    in_payload.uop_ssid                             = io_in_bits_uop_ssid;
    in_payload.uop_lqIdx_flag                       = io_in_bits_uop_lqIdx_flag;
    in_payload.uop_lqIdx_value                      = io_in_bits_uop_lqIdx_value;
    in_payload.uop_sqIdx_flag                       = io_in_bits_uop_sqIdx_flag;
    in_payload.uop_sqIdx_value                      = io_in_bits_uop_sqIdx_value;
    in_payload.uop_singleStep                       = io_in_bits_uop_singleStep;
    in_payload.uop_replayInst                       = io_in_bits_uop_replayInst;
    in_payload.uop_debug_fuType                     = io_in_bits_uop_debug_fuType;
    in_payload.uop_debug_sim_trig                   = io_in_bits_uop_debug_sim_trig;
    in_payload.uop_numLsElem                        = io_in_bits_uop_numLsElem;
    in_payload.mBIndex                              = io_in_bits_mBIndex;
    in_payload.elemIdx                              = io_in_bits_elemIdx;
    in_payload.elemIdxInsideVd                      = io_in_bits_elemIdxInsideVd;
    in_payload.splitIndex                           = io_in_bits_splitIndex;
  end

  // 出口拆包：struct 成员 -> 端口（同名逐项）
  assign io_out_bits_vaddr                                = out_payload.vaddr;
  assign io_out_bits_basevaddr                            = out_payload.basevaddr;
  assign io_out_bits_mask                                 = out_payload.mask;
  assign io_out_bits_reg_offset                           = out_payload.reg_offset;
  assign io_out_bits_alignedType                          = out_payload.alignedType;
  assign io_out_bits_vecActive                            = out_payload.vecActive;
  assign io_out_bits_vecIsFirstActiveElement              = out_payload.vecIsFirstActiveElement;
  assign io_out_bits_uop_instr                            = out_payload.uop_instr;
  assign io_out_bits_uop_pc                               = out_payload.uop_pc;
  assign io_out_bits_uop_foldpc                           = out_payload.uop_foldpc;
  assign io_out_bits_uop_exceptionVec_4                   = out_payload.uop_exceptionVec_4;
  assign io_out_bits_uop_exceptionVec_5                   = out_payload.uop_exceptionVec_5;
  assign io_out_bits_uop_exceptionVec_6                   = out_payload.uop_exceptionVec_6;
  assign io_out_bits_uop_exceptionVec_7                   = out_payload.uop_exceptionVec_7;
  assign io_out_bits_uop_exceptionVec_13                  = out_payload.uop_exceptionVec_13;
  assign io_out_bits_uop_exceptionVec_15                  = out_payload.uop_exceptionVec_15;
  assign io_out_bits_uop_exceptionVec_19                  = out_payload.uop_exceptionVec_19;
  assign io_out_bits_uop_exceptionVec_21                  = out_payload.uop_exceptionVec_21;
  assign io_out_bits_uop_exceptionVec_23                  = out_payload.uop_exceptionVec_23;
  assign io_out_bits_uop_isFetchMalAddr                   = out_payload.uop_isFetchMalAddr;
  assign io_out_bits_uop_hasException                     = out_payload.uop_hasException;
  assign io_out_bits_uop_trigger                          = out_payload.uop_trigger;
  assign io_out_bits_uop_preDecodeInfo_valid              = out_payload.uop_preDecodeInfo_valid;
  assign io_out_bits_uop_preDecodeInfo_isRVC              = out_payload.uop_preDecodeInfo_isRVC;
  assign io_out_bits_uop_preDecodeInfo_brType             = out_payload.uop_preDecodeInfo_brType;
  assign io_out_bits_uop_preDecodeInfo_isCall             = out_payload.uop_preDecodeInfo_isCall;
  assign io_out_bits_uop_preDecodeInfo_isRet              = out_payload.uop_preDecodeInfo_isRet;
  assign io_out_bits_uop_pred_taken                       = out_payload.uop_pred_taken;
  assign io_out_bits_uop_crossPageIPFFix                  = out_payload.uop_crossPageIPFFix;
  assign io_out_bits_uop_ftqPtr_flag                      = out_payload.uop_ftqPtr_flag;
  assign io_out_bits_uop_ftqPtr_value                     = out_payload.uop_ftqPtr_value;
  assign io_out_bits_uop_ftqOffset                        = out_payload.uop_ftqOffset;
  assign io_out_bits_uop_satpFlushFirstFetchFault         = out_payload.uop_satpFlushFirstFetchFault;
  assign io_out_bits_uop_srcType_0                        = out_payload.uop_srcType_0;
  assign io_out_bits_uop_srcType_1                        = out_payload.uop_srcType_1;
  assign io_out_bits_uop_srcType_2                        = out_payload.uop_srcType_2;
  assign io_out_bits_uop_srcType_3                        = out_payload.uop_srcType_3;
  assign io_out_bits_uop_srcType_4                        = out_payload.uop_srcType_4;
  assign io_out_bits_uop_ldest                            = out_payload.uop_ldest;
  assign io_out_bits_uop_fuType                           = out_payload.uop_fuType;
  assign io_out_bits_uop_fuOpType                         = out_payload.uop_fuOpType;
  assign io_out_bits_uop_rfWen                            = out_payload.uop_rfWen;
  assign io_out_bits_uop_fpWen                            = out_payload.uop_fpWen;
  assign io_out_bits_uop_vecWen                           = out_payload.uop_vecWen;
  assign io_out_bits_uop_v0Wen                            = out_payload.uop_v0Wen;
  assign io_out_bits_uop_vlWen                            = out_payload.uop_vlWen;
  assign io_out_bits_uop_isXSTrap                         = out_payload.uop_isXSTrap;
  assign io_out_bits_uop_waitForward                      = out_payload.uop_waitForward;
  assign io_out_bits_uop_blockBackward                    = out_payload.uop_blockBackward;
  assign io_out_bits_uop_canRobCompress                   = out_payload.uop_canRobCompress;
  assign io_out_bits_uop_selImm                           = out_payload.uop_selImm;
  assign io_out_bits_uop_fpu_typeTagOut                   = out_payload.uop_fpu_typeTagOut;
  assign io_out_bits_uop_fpu_wflags                       = out_payload.uop_fpu_wflags;
  assign io_out_bits_uop_fpu_typ                          = out_payload.uop_fpu_typ;
  assign io_out_bits_uop_fpu_fmt                          = out_payload.uop_fpu_fmt;
  assign io_out_bits_uop_fpu_rm                           = out_payload.uop_fpu_rm;
  assign io_out_bits_uop_vpu_vill                         = out_payload.uop_vpu_vill;
  assign io_out_bits_uop_vpu_vma                          = out_payload.uop_vpu_vma;
  assign io_out_bits_uop_vpu_vta                          = out_payload.uop_vpu_vta;
  assign io_out_bits_uop_vpu_vsew                         = out_payload.uop_vpu_vsew;
  assign io_out_bits_uop_vpu_vlmul                        = out_payload.uop_vpu_vlmul;
  assign io_out_bits_uop_vpu_specVill                     = out_payload.uop_vpu_specVill;
  assign io_out_bits_uop_vpu_specVma                      = out_payload.uop_vpu_specVma;
  assign io_out_bits_uop_vpu_specVta                      = out_payload.uop_vpu_specVta;
  assign io_out_bits_uop_vpu_specVsew                     = out_payload.uop_vpu_specVsew;
  assign io_out_bits_uop_vpu_specVlmul                    = out_payload.uop_vpu_specVlmul;
  assign io_out_bits_uop_vpu_vm                           = out_payload.uop_vpu_vm;
  assign io_out_bits_uop_vpu_vstart                       = out_payload.uop_vpu_vstart;
  assign io_out_bits_uop_vpu_frm                          = out_payload.uop_vpu_frm;
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst            = out_payload.uop_vpu_fpu_isFpToVecInst;
  assign io_out_bits_uop_vpu_fpu_isFP32Instr              = out_payload.uop_vpu_fpu_isFP32Instr;
  assign io_out_bits_uop_vpu_fpu_isFP64Instr              = out_payload.uop_vpu_fpu_isFP64Instr;
  assign io_out_bits_uop_vpu_fpu_isReduction              = out_payload.uop_vpu_fpu_isReduction;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2              = out_payload.uop_vpu_fpu_isFoldTo1_2;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4              = out_payload.uop_vpu_fpu_isFoldTo1_4;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8              = out_payload.uop_vpu_fpu_isFoldTo1_8;
  assign io_out_bits_uop_vpu_vxrm                         = out_payload.uop_vpu_vxrm;
  assign io_out_bits_uop_vpu_vuopIdx                      = out_payload.uop_vpu_vuopIdx;
  assign io_out_bits_uop_vpu_lastUop                      = out_payload.uop_vpu_lastUop;
  assign io_out_bits_uop_vpu_vmask                        = out_payload.uop_vpu_vmask;
  assign io_out_bits_uop_vpu_vl                           = out_payload.uop_vpu_vl;
  assign io_out_bits_uop_vpu_nf                           = out_payload.uop_vpu_nf;
  assign io_out_bits_uop_vpu_veew                         = out_payload.uop_vpu_veew;
  assign io_out_bits_uop_vpu_isReverse                    = out_payload.uop_vpu_isReverse;
  assign io_out_bits_uop_vpu_isExt                        = out_payload.uop_vpu_isExt;
  assign io_out_bits_uop_vpu_isNarrow                     = out_payload.uop_vpu_isNarrow;
  assign io_out_bits_uop_vpu_isDstMask                    = out_payload.uop_vpu_isDstMask;
  assign io_out_bits_uop_vpu_isOpMask                     = out_payload.uop_vpu_isOpMask;
  assign io_out_bits_uop_vpu_isMove                       = out_payload.uop_vpu_isMove;
  assign io_out_bits_uop_vpu_isDependOldVd                = out_payload.uop_vpu_isDependOldVd;
  assign io_out_bits_uop_vpu_isWritePartVd                = out_payload.uop_vpu_isWritePartVd;
  assign io_out_bits_uop_vpu_isVleff                      = out_payload.uop_vpu_isVleff;
  assign io_out_bits_uop_vlsInstr                         = out_payload.uop_vlsInstr;
  assign io_out_bits_uop_wfflags                          = out_payload.uop_wfflags;
  assign io_out_bits_uop_isMove                           = out_payload.uop_isMove;
  assign io_out_bits_uop_isDropAmocasSta                  = out_payload.uop_isDropAmocasSta;
  assign io_out_bits_uop_uopIdx                           = out_payload.uop_uopIdx;
  assign io_out_bits_uop_isVset                           = out_payload.uop_isVset;
  assign io_out_bits_uop_firstUop                         = out_payload.uop_firstUop;
  assign io_out_bits_uop_lastUop                          = out_payload.uop_lastUop;
  assign io_out_bits_uop_numUops                          = out_payload.uop_numUops;
  assign io_out_bits_uop_numWB                            = out_payload.uop_numWB;
  assign io_out_bits_uop_commitType                       = out_payload.uop_commitType;
  assign io_out_bits_uop_srcState_0                       = out_payload.uop_srcState_0;
  assign io_out_bits_uop_srcState_1                       = out_payload.uop_srcState_1;
  assign io_out_bits_uop_srcState_2                       = out_payload.uop_srcState_2;
  assign io_out_bits_uop_srcState_3                       = out_payload.uop_srcState_3;
  assign io_out_bits_uop_srcState_4                       = out_payload.uop_srcState_4;
  assign io_out_bits_uop_srcLoadDependency_0_0            = out_payload.uop_srcLoadDependency_0_0;
  assign io_out_bits_uop_srcLoadDependency_0_1            = out_payload.uop_srcLoadDependency_0_1;
  assign io_out_bits_uop_srcLoadDependency_0_2            = out_payload.uop_srcLoadDependency_0_2;
  assign io_out_bits_uop_srcLoadDependency_1_0            = out_payload.uop_srcLoadDependency_1_0;
  assign io_out_bits_uop_srcLoadDependency_1_1            = out_payload.uop_srcLoadDependency_1_1;
  assign io_out_bits_uop_srcLoadDependency_1_2            = out_payload.uop_srcLoadDependency_1_2;
  assign io_out_bits_uop_srcLoadDependency_2_0            = out_payload.uop_srcLoadDependency_2_0;
  assign io_out_bits_uop_srcLoadDependency_2_1            = out_payload.uop_srcLoadDependency_2_1;
  assign io_out_bits_uop_srcLoadDependency_2_2            = out_payload.uop_srcLoadDependency_2_2;
  assign io_out_bits_uop_srcLoadDependency_3_0            = out_payload.uop_srcLoadDependency_3_0;
  assign io_out_bits_uop_srcLoadDependency_3_1            = out_payload.uop_srcLoadDependency_3_1;
  assign io_out_bits_uop_srcLoadDependency_3_2            = out_payload.uop_srcLoadDependency_3_2;
  assign io_out_bits_uop_srcLoadDependency_4_0            = out_payload.uop_srcLoadDependency_4_0;
  assign io_out_bits_uop_srcLoadDependency_4_1            = out_payload.uop_srcLoadDependency_4_1;
  assign io_out_bits_uop_srcLoadDependency_4_2            = out_payload.uop_srcLoadDependency_4_2;
  assign io_out_bits_uop_psrc_0                           = out_payload.uop_psrc_0;
  assign io_out_bits_uop_psrc_1                           = out_payload.uop_psrc_1;
  assign io_out_bits_uop_psrc_2                           = out_payload.uop_psrc_2;
  assign io_out_bits_uop_psrc_3                           = out_payload.uop_psrc_3;
  assign io_out_bits_uop_psrc_4                           = out_payload.uop_psrc_4;
  assign io_out_bits_uop_pdest                            = out_payload.uop_pdest;
  assign io_out_bits_uop_useRegCache_0                    = out_payload.uop_useRegCache_0;
  assign io_out_bits_uop_useRegCache_1                    = out_payload.uop_useRegCache_1;
  assign io_out_bits_uop_regCacheIdx_0                    = out_payload.uop_regCacheIdx_0;
  assign io_out_bits_uop_regCacheIdx_1                    = out_payload.uop_regCacheIdx_1;
  assign io_out_bits_uop_robIdx_flag                      = out_payload.uop_robIdx_flag;
  assign io_out_bits_uop_robIdx_value                     = out_payload.uop_robIdx_value;
  assign io_out_bits_uop_instrSize                        = out_payload.uop_instrSize;
  assign io_out_bits_uop_dirtyFs                          = out_payload.uop_dirtyFs;
  assign io_out_bits_uop_dirtyVs                          = out_payload.uop_dirtyVs;
  assign io_out_bits_uop_traceBlockInPipe_itype           = out_payload.uop_traceBlockInPipe_itype;
  assign io_out_bits_uop_traceBlockInPipe_iretire         = out_payload.uop_traceBlockInPipe_iretire;
  assign io_out_bits_uop_traceBlockInPipe_ilastsize       = out_payload.uop_traceBlockInPipe_ilastsize;
  assign io_out_bits_uop_eliminatedMove                   = out_payload.uop_eliminatedMove;
  assign io_out_bits_uop_snapshot                         = out_payload.uop_snapshot;
  assign io_out_bits_uop_debugInfo_eliminatedMove         = out_payload.uop_debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime             = out_payload.uop_debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime           = out_payload.uop_debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime              = out_payload.uop_debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime             = out_payload.uop_debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime              = out_payload.uop_debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime          = out_payload.uop_debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out_payload.uop_debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime        = out_payload.uop_debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime            = out_payload.uop_debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum              = out_payload.uop_debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx              = out_payload.uop_debug_seqNum_uopIdx;
  assign io_out_bits_uop_storeSetHit                      = out_payload.uop_storeSetHit;
  assign io_out_bits_uop_waitForRobIdx_flag               = out_payload.uop_waitForRobIdx_flag;
  assign io_out_bits_uop_waitForRobIdx_value              = out_payload.uop_waitForRobIdx_value;
  assign io_out_bits_uop_loadWaitBit                      = out_payload.uop_loadWaitBit;
  assign io_out_bits_uop_loadWaitStrict                   = out_payload.uop_loadWaitStrict;
  assign io_out_bits_uop_ssid                             = out_payload.uop_ssid;
  assign io_out_bits_uop_lqIdx_flag                       = out_payload.uop_lqIdx_flag;
  assign io_out_bits_uop_lqIdx_value                      = out_payload.uop_lqIdx_value;
  assign io_out_bits_uop_sqIdx_flag                       = out_payload.uop_sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value                      = out_payload.uop_sqIdx_value;
  assign io_out_bits_uop_singleStep                       = out_payload.uop_singleStep;
  assign io_out_bits_uop_replayInst                       = out_payload.uop_replayInst;
  assign io_out_bits_uop_debug_fuType                     = out_payload.uop_debug_fuType;
  assign io_out_bits_uop_debug_sim_trig                   = out_payload.uop_debug_sim_trig;
  assign io_out_bits_uop_numLsElem                        = out_payload.uop_numLsElem;
  assign io_out_bits_mBIndex                              = out_payload.mBIndex;
  assign io_out_bits_elemIdx                              = out_payload.elemIdx;
  assign io_out_bits_elemIdxInsideVd                      = out_payload.elemIdxInsideVd;
  assign io_out_bits_splitIndex                           = out_payload.splitIndex;

  // ---------------------------------------------------------------------------
  // elaborate 期位宽不变式。
  //
  // 本轮反复出事的形态是「逻辑全对、只有某个字段位宽停在旧基线」：随机激励未必
  // 打到高位，UT 照样 errors=0，要等 FM 才炸。这里把它提前到 time 0。
  // 判据：入口端口位宽之和 == 出口端口位宽之和 == PAYLOAD_W_G1 == $bits(payload_t)。
  // 任何一个端口或 struct 成员的位宽被改动，这四个数就不再相等（后两项由共享核
  // 里的 initial 负责）。「两处互相抵消的改动」逃得过位宽和，但逃不过
  // scripts/port_contract_lint.py（逐端口比 G1 golden）与 UT 的逐拍输出比对。
  // ---------------------------------------------------------------------------
  localparam int unsigned IN_PORT_BITS =
   $bits(io_in_bits_vaddr) + $bits(io_in_bits_basevaddr) + $bits(io_in_bits_mask) + $bits(io_in_bits_reg_offset) +
   $bits(io_in_bits_alignedType) + $bits(io_in_bits_vecActive) + $bits(io_in_bits_vecIsFirstActiveElement) + $bits(io_in_bits_uop_instr) +
   $bits(io_in_bits_uop_pc) + $bits(io_in_bits_uop_foldpc) + $bits(io_in_bits_uop_exceptionVec_4) + $bits(io_in_bits_uop_exceptionVec_5) +
   $bits(io_in_bits_uop_exceptionVec_6) + $bits(io_in_bits_uop_exceptionVec_7) + $bits(io_in_bits_uop_exceptionVec_13) + $bits(io_in_bits_uop_exceptionVec_15) +
   $bits(io_in_bits_uop_exceptionVec_19) + $bits(io_in_bits_uop_exceptionVec_21) + $bits(io_in_bits_uop_exceptionVec_23) + $bits(io_in_bits_uop_isFetchMalAddr) +
   $bits(io_in_bits_uop_hasException) + $bits(io_in_bits_uop_trigger) + $bits(io_in_bits_uop_preDecodeInfo_valid) + $bits(io_in_bits_uop_preDecodeInfo_isRVC) +
   $bits(io_in_bits_uop_preDecodeInfo_brType) + $bits(io_in_bits_uop_preDecodeInfo_isCall) + $bits(io_in_bits_uop_preDecodeInfo_isRet) + $bits(io_in_bits_uop_pred_taken) +
   $bits(io_in_bits_uop_crossPageIPFFix) + $bits(io_in_bits_uop_ftqPtr_flag) + $bits(io_in_bits_uop_ftqPtr_value) + $bits(io_in_bits_uop_ftqOffset) +
   $bits(io_in_bits_uop_satpFlushFirstFetchFault) + $bits(io_in_bits_uop_srcType_0) + $bits(io_in_bits_uop_srcType_1) + $bits(io_in_bits_uop_srcType_2) +
   $bits(io_in_bits_uop_srcType_3) + $bits(io_in_bits_uop_srcType_4) + $bits(io_in_bits_uop_ldest) + $bits(io_in_bits_uop_fuType) +
   $bits(io_in_bits_uop_fuOpType) + $bits(io_in_bits_uop_rfWen) + $bits(io_in_bits_uop_fpWen) + $bits(io_in_bits_uop_vecWen) +
   $bits(io_in_bits_uop_v0Wen) + $bits(io_in_bits_uop_vlWen) + $bits(io_in_bits_uop_isXSTrap) + $bits(io_in_bits_uop_waitForward) +
   $bits(io_in_bits_uop_blockBackward) + $bits(io_in_bits_uop_canRobCompress) + $bits(io_in_bits_uop_selImm) + $bits(io_in_bits_uop_fpu_typeTagOut) +
   $bits(io_in_bits_uop_fpu_wflags) + $bits(io_in_bits_uop_fpu_typ) + $bits(io_in_bits_uop_fpu_fmt) + $bits(io_in_bits_uop_fpu_rm) +
   $bits(io_in_bits_uop_vpu_vill) + $bits(io_in_bits_uop_vpu_vma) + $bits(io_in_bits_uop_vpu_vta) + $bits(io_in_bits_uop_vpu_vsew) +
   $bits(io_in_bits_uop_vpu_vlmul) + $bits(io_in_bits_uop_vpu_specVill) + $bits(io_in_bits_uop_vpu_specVma) + $bits(io_in_bits_uop_vpu_specVta) +
   $bits(io_in_bits_uop_vpu_specVsew) + $bits(io_in_bits_uop_vpu_specVlmul) + $bits(io_in_bits_uop_vpu_vm) + $bits(io_in_bits_uop_vpu_vstart) +
   $bits(io_in_bits_uop_vpu_frm) + $bits(io_in_bits_uop_vpu_fpu_isFpToVecInst) + $bits(io_in_bits_uop_vpu_fpu_isFP32Instr) + $bits(io_in_bits_uop_vpu_fpu_isFP64Instr) +
   $bits(io_in_bits_uop_vpu_fpu_isReduction) + $bits(io_in_bits_uop_vpu_fpu_isFoldTo1_2) + $bits(io_in_bits_uop_vpu_fpu_isFoldTo1_4) + $bits(io_in_bits_uop_vpu_fpu_isFoldTo1_8) +
   $bits(io_in_bits_uop_vpu_vxrm) + $bits(io_in_bits_uop_vpu_vuopIdx) + $bits(io_in_bits_uop_vpu_lastUop) + $bits(io_in_bits_uop_vpu_vmask) +
   $bits(io_in_bits_uop_vpu_vl) + $bits(io_in_bits_uop_vpu_nf) + $bits(io_in_bits_uop_vpu_veew) + $bits(io_in_bits_uop_vpu_isReverse) +
   $bits(io_in_bits_uop_vpu_isExt) + $bits(io_in_bits_uop_vpu_isNarrow) + $bits(io_in_bits_uop_vpu_isDstMask) + $bits(io_in_bits_uop_vpu_isOpMask) +
   $bits(io_in_bits_uop_vpu_isMove) + $bits(io_in_bits_uop_vpu_isDependOldVd) + $bits(io_in_bits_uop_vpu_isWritePartVd) + $bits(io_in_bits_uop_vpu_isVleff) +
   $bits(io_in_bits_uop_vlsInstr) + $bits(io_in_bits_uop_wfflags) + $bits(io_in_bits_uop_isMove) + $bits(io_in_bits_uop_isDropAmocasSta) +
   $bits(io_in_bits_uop_uopIdx) + $bits(io_in_bits_uop_isVset) + $bits(io_in_bits_uop_firstUop) + $bits(io_in_bits_uop_lastUop) +
   $bits(io_in_bits_uop_numUops) + $bits(io_in_bits_uop_numWB) + $bits(io_in_bits_uop_commitType) + $bits(io_in_bits_uop_srcState_0) +
   $bits(io_in_bits_uop_srcState_1) + $bits(io_in_bits_uop_srcState_2) + $bits(io_in_bits_uop_srcState_3) + $bits(io_in_bits_uop_srcState_4) +
   $bits(io_in_bits_uop_srcLoadDependency_0_0) + $bits(io_in_bits_uop_srcLoadDependency_0_1) + $bits(io_in_bits_uop_srcLoadDependency_0_2) + $bits(io_in_bits_uop_srcLoadDependency_1_0) +
   $bits(io_in_bits_uop_srcLoadDependency_1_1) + $bits(io_in_bits_uop_srcLoadDependency_1_2) + $bits(io_in_bits_uop_srcLoadDependency_2_0) + $bits(io_in_bits_uop_srcLoadDependency_2_1) +
   $bits(io_in_bits_uop_srcLoadDependency_2_2) + $bits(io_in_bits_uop_srcLoadDependency_3_0) + $bits(io_in_bits_uop_srcLoadDependency_3_1) + $bits(io_in_bits_uop_srcLoadDependency_3_2) +
   $bits(io_in_bits_uop_srcLoadDependency_4_0) + $bits(io_in_bits_uop_srcLoadDependency_4_1) + $bits(io_in_bits_uop_srcLoadDependency_4_2) + $bits(io_in_bits_uop_psrc_0) +
   $bits(io_in_bits_uop_psrc_1) + $bits(io_in_bits_uop_psrc_2) + $bits(io_in_bits_uop_psrc_3) + $bits(io_in_bits_uop_psrc_4) +
   $bits(io_in_bits_uop_pdest) + $bits(io_in_bits_uop_useRegCache_0) + $bits(io_in_bits_uop_useRegCache_1) + $bits(io_in_bits_uop_regCacheIdx_0) +
   $bits(io_in_bits_uop_regCacheIdx_1) + $bits(io_in_bits_uop_robIdx_flag) + $bits(io_in_bits_uop_robIdx_value) + $bits(io_in_bits_uop_instrSize) +
   $bits(io_in_bits_uop_dirtyFs) + $bits(io_in_bits_uop_dirtyVs) + $bits(io_in_bits_uop_traceBlockInPipe_itype) + $bits(io_in_bits_uop_traceBlockInPipe_iretire) +
   $bits(io_in_bits_uop_traceBlockInPipe_ilastsize) + $bits(io_in_bits_uop_eliminatedMove) + $bits(io_in_bits_uop_snapshot) + $bits(io_in_bits_uop_debugInfo_eliminatedMove) +
   $bits(io_in_bits_uop_debugInfo_renameTime) + $bits(io_in_bits_uop_debugInfo_dispatchTime) + $bits(io_in_bits_uop_debugInfo_enqRsTime) + $bits(io_in_bits_uop_debugInfo_selectTime) +
   $bits(io_in_bits_uop_debugInfo_issueTime) + $bits(io_in_bits_uop_debugInfo_writebackTime) + $bits(io_in_bits_uop_debugInfo_runahead_checkpoint_id) + $bits(io_in_bits_uop_debugInfo_tlbFirstReqTime) +
   $bits(io_in_bits_uop_debugInfo_tlbRespTime) + $bits(io_in_bits_uop_debug_seqNum_seqNum) + $bits(io_in_bits_uop_debug_seqNum_uopIdx) + $bits(io_in_bits_uop_storeSetHit) +
   $bits(io_in_bits_uop_waitForRobIdx_flag) + $bits(io_in_bits_uop_waitForRobIdx_value) + $bits(io_in_bits_uop_loadWaitBit) + $bits(io_in_bits_uop_loadWaitStrict) +
   $bits(io_in_bits_uop_ssid) + $bits(io_in_bits_uop_lqIdx_flag) + $bits(io_in_bits_uop_lqIdx_value) + $bits(io_in_bits_uop_sqIdx_flag) +
   $bits(io_in_bits_uop_sqIdx_value) + $bits(io_in_bits_uop_singleStep) + $bits(io_in_bits_uop_replayInst) + $bits(io_in_bits_uop_debug_fuType) +
   $bits(io_in_bits_uop_debug_sim_trig) + $bits(io_in_bits_uop_numLsElem) + $bits(io_in_bits_mBIndex) + $bits(io_in_bits_elemIdx) +
   $bits(io_in_bits_elemIdxInsideVd) + $bits(io_in_bits_splitIndex);
  localparam int unsigned OUT_PORT_BITS =
   $bits(io_out_bits_vaddr) + $bits(io_out_bits_basevaddr) + $bits(io_out_bits_mask) + $bits(io_out_bits_reg_offset) +
   $bits(io_out_bits_alignedType) + $bits(io_out_bits_vecActive) + $bits(io_out_bits_vecIsFirstActiveElement) + $bits(io_out_bits_uop_instr) +
   $bits(io_out_bits_uop_pc) + $bits(io_out_bits_uop_foldpc) + $bits(io_out_bits_uop_exceptionVec_4) + $bits(io_out_bits_uop_exceptionVec_5) +
   $bits(io_out_bits_uop_exceptionVec_6) + $bits(io_out_bits_uop_exceptionVec_7) + $bits(io_out_bits_uop_exceptionVec_13) + $bits(io_out_bits_uop_exceptionVec_15) +
   $bits(io_out_bits_uop_exceptionVec_19) + $bits(io_out_bits_uop_exceptionVec_21) + $bits(io_out_bits_uop_exceptionVec_23) + $bits(io_out_bits_uop_isFetchMalAddr) +
   $bits(io_out_bits_uop_hasException) + $bits(io_out_bits_uop_trigger) + $bits(io_out_bits_uop_preDecodeInfo_valid) + $bits(io_out_bits_uop_preDecodeInfo_isRVC) +
   $bits(io_out_bits_uop_preDecodeInfo_brType) + $bits(io_out_bits_uop_preDecodeInfo_isCall) + $bits(io_out_bits_uop_preDecodeInfo_isRet) + $bits(io_out_bits_uop_pred_taken) +
   $bits(io_out_bits_uop_crossPageIPFFix) + $bits(io_out_bits_uop_ftqPtr_flag) + $bits(io_out_bits_uop_ftqPtr_value) + $bits(io_out_bits_uop_ftqOffset) +
   $bits(io_out_bits_uop_satpFlushFirstFetchFault) + $bits(io_out_bits_uop_srcType_0) + $bits(io_out_bits_uop_srcType_1) + $bits(io_out_bits_uop_srcType_2) +
   $bits(io_out_bits_uop_srcType_3) + $bits(io_out_bits_uop_srcType_4) + $bits(io_out_bits_uop_ldest) + $bits(io_out_bits_uop_fuType) +
   $bits(io_out_bits_uop_fuOpType) + $bits(io_out_bits_uop_rfWen) + $bits(io_out_bits_uop_fpWen) + $bits(io_out_bits_uop_vecWen) +
   $bits(io_out_bits_uop_v0Wen) + $bits(io_out_bits_uop_vlWen) + $bits(io_out_bits_uop_isXSTrap) + $bits(io_out_bits_uop_waitForward) +
   $bits(io_out_bits_uop_blockBackward) + $bits(io_out_bits_uop_canRobCompress) + $bits(io_out_bits_uop_selImm) + $bits(io_out_bits_uop_fpu_typeTagOut) +
   $bits(io_out_bits_uop_fpu_wflags) + $bits(io_out_bits_uop_fpu_typ) + $bits(io_out_bits_uop_fpu_fmt) + $bits(io_out_bits_uop_fpu_rm) +
   $bits(io_out_bits_uop_vpu_vill) + $bits(io_out_bits_uop_vpu_vma) + $bits(io_out_bits_uop_vpu_vta) + $bits(io_out_bits_uop_vpu_vsew) +
   $bits(io_out_bits_uop_vpu_vlmul) + $bits(io_out_bits_uop_vpu_specVill) + $bits(io_out_bits_uop_vpu_specVma) + $bits(io_out_bits_uop_vpu_specVta) +
   $bits(io_out_bits_uop_vpu_specVsew) + $bits(io_out_bits_uop_vpu_specVlmul) + $bits(io_out_bits_uop_vpu_vm) + $bits(io_out_bits_uop_vpu_vstart) +
   $bits(io_out_bits_uop_vpu_frm) + $bits(io_out_bits_uop_vpu_fpu_isFpToVecInst) + $bits(io_out_bits_uop_vpu_fpu_isFP32Instr) + $bits(io_out_bits_uop_vpu_fpu_isFP64Instr) +
   $bits(io_out_bits_uop_vpu_fpu_isReduction) + $bits(io_out_bits_uop_vpu_fpu_isFoldTo1_2) + $bits(io_out_bits_uop_vpu_fpu_isFoldTo1_4) + $bits(io_out_bits_uop_vpu_fpu_isFoldTo1_8) +
   $bits(io_out_bits_uop_vpu_vxrm) + $bits(io_out_bits_uop_vpu_vuopIdx) + $bits(io_out_bits_uop_vpu_lastUop) + $bits(io_out_bits_uop_vpu_vmask) +
   $bits(io_out_bits_uop_vpu_vl) + $bits(io_out_bits_uop_vpu_nf) + $bits(io_out_bits_uop_vpu_veew) + $bits(io_out_bits_uop_vpu_isReverse) +
   $bits(io_out_bits_uop_vpu_isExt) + $bits(io_out_bits_uop_vpu_isNarrow) + $bits(io_out_bits_uop_vpu_isDstMask) + $bits(io_out_bits_uop_vpu_isOpMask) +
   $bits(io_out_bits_uop_vpu_isMove) + $bits(io_out_bits_uop_vpu_isDependOldVd) + $bits(io_out_bits_uop_vpu_isWritePartVd) + $bits(io_out_bits_uop_vpu_isVleff) +
   $bits(io_out_bits_uop_vlsInstr) + $bits(io_out_bits_uop_wfflags) + $bits(io_out_bits_uop_isMove) + $bits(io_out_bits_uop_isDropAmocasSta) +
   $bits(io_out_bits_uop_uopIdx) + $bits(io_out_bits_uop_isVset) + $bits(io_out_bits_uop_firstUop) + $bits(io_out_bits_uop_lastUop) +
   $bits(io_out_bits_uop_numUops) + $bits(io_out_bits_uop_numWB) + $bits(io_out_bits_uop_commitType) + $bits(io_out_bits_uop_srcState_0) +
   $bits(io_out_bits_uop_srcState_1) + $bits(io_out_bits_uop_srcState_2) + $bits(io_out_bits_uop_srcState_3) + $bits(io_out_bits_uop_srcState_4) +
   $bits(io_out_bits_uop_srcLoadDependency_0_0) + $bits(io_out_bits_uop_srcLoadDependency_0_1) + $bits(io_out_bits_uop_srcLoadDependency_0_2) + $bits(io_out_bits_uop_srcLoadDependency_1_0) +
   $bits(io_out_bits_uop_srcLoadDependency_1_1) + $bits(io_out_bits_uop_srcLoadDependency_1_2) + $bits(io_out_bits_uop_srcLoadDependency_2_0) + $bits(io_out_bits_uop_srcLoadDependency_2_1) +
   $bits(io_out_bits_uop_srcLoadDependency_2_2) + $bits(io_out_bits_uop_srcLoadDependency_3_0) + $bits(io_out_bits_uop_srcLoadDependency_3_1) + $bits(io_out_bits_uop_srcLoadDependency_3_2) +
   $bits(io_out_bits_uop_srcLoadDependency_4_0) + $bits(io_out_bits_uop_srcLoadDependency_4_1) + $bits(io_out_bits_uop_srcLoadDependency_4_2) + $bits(io_out_bits_uop_psrc_0) +
   $bits(io_out_bits_uop_psrc_1) + $bits(io_out_bits_uop_psrc_2) + $bits(io_out_bits_uop_psrc_3) + $bits(io_out_bits_uop_psrc_4) +
   $bits(io_out_bits_uop_pdest) + $bits(io_out_bits_uop_useRegCache_0) + $bits(io_out_bits_uop_useRegCache_1) + $bits(io_out_bits_uop_regCacheIdx_0) +
   $bits(io_out_bits_uop_regCacheIdx_1) + $bits(io_out_bits_uop_robIdx_flag) + $bits(io_out_bits_uop_robIdx_value) + $bits(io_out_bits_uop_instrSize) +
   $bits(io_out_bits_uop_dirtyFs) + $bits(io_out_bits_uop_dirtyVs) + $bits(io_out_bits_uop_traceBlockInPipe_itype) + $bits(io_out_bits_uop_traceBlockInPipe_iretire) +
   $bits(io_out_bits_uop_traceBlockInPipe_ilastsize) + $bits(io_out_bits_uop_eliminatedMove) + $bits(io_out_bits_uop_snapshot) + $bits(io_out_bits_uop_debugInfo_eliminatedMove) +
   $bits(io_out_bits_uop_debugInfo_renameTime) + $bits(io_out_bits_uop_debugInfo_dispatchTime) + $bits(io_out_bits_uop_debugInfo_enqRsTime) + $bits(io_out_bits_uop_debugInfo_selectTime) +
   $bits(io_out_bits_uop_debugInfo_issueTime) + $bits(io_out_bits_uop_debugInfo_writebackTime) + $bits(io_out_bits_uop_debugInfo_runahead_checkpoint_id) + $bits(io_out_bits_uop_debugInfo_tlbFirstReqTime) +
   $bits(io_out_bits_uop_debugInfo_tlbRespTime) + $bits(io_out_bits_uop_debug_seqNum_seqNum) + $bits(io_out_bits_uop_debug_seqNum_uopIdx) + $bits(io_out_bits_uop_storeSetHit) +
   $bits(io_out_bits_uop_waitForRobIdx_flag) + $bits(io_out_bits_uop_waitForRobIdx_value) + $bits(io_out_bits_uop_loadWaitBit) + $bits(io_out_bits_uop_loadWaitStrict) +
   $bits(io_out_bits_uop_ssid) + $bits(io_out_bits_uop_lqIdx_flag) + $bits(io_out_bits_uop_lqIdx_value) + $bits(io_out_bits_uop_sqIdx_flag) +
   $bits(io_out_bits_uop_sqIdx_value) + $bits(io_out_bits_uop_singleStep) + $bits(io_out_bits_uop_replayInst) + $bits(io_out_bits_uop_debug_fuType) +
   $bits(io_out_bits_uop_debug_sim_trig) + $bits(io_out_bits_uop_numLsElem) + $bits(io_out_bits_mBIndex) + $bits(io_out_bits_elemIdx) +
   $bits(io_out_bits_elemIdxInsideVd) + $bits(io_out_bits_splitIndex);

  initial begin
    if (IN_PORT_BITS != PAYLOAD_W_G1)
      $fatal(1, "NewPipelineConnectPipe_35: 入口端口位宽之和 %0d != G1 golden 的 %0d 位",
             IN_PORT_BITS, PAYLOAD_W_G1);
    if (OUT_PORT_BITS != PAYLOAD_W_G1)
      $fatal(1, "NewPipelineConnectPipe_35: 出口端口位宽之和 %0d != G1 golden 的 %0d 位",
             OUT_PORT_BITS, PAYLOAD_W_G1);
  end

  // 共享核：本文件不含任何流水/握手逻辑，全部在 xs_PipelineConnect 里。
  xs_PipelineConnect #(
    .DATA_WIDTH   ($bits(payload_t)),
    .PAYLOAD_W_G1 (PAYLOAD_W_G1)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .io_in_ready     (io_in_ready),
    .io_in_valid     (io_in_valid),
    .io_in_bits      (in_payload),
    .io_out_ready    (io_out_ready),
    .io_out_valid    (io_out_valid),
    .io_out_bits     (out_payload),
    .io_rightOutFire (io_rightOutFire),
    .io_isFlush      (io_isFlush)
  );

endmodule
