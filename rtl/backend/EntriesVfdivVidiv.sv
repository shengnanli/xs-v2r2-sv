// EntriesVfdivVidiv.sv —— 发射队列条目阵列（VfdivVidiv 变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv（Entries* 家族共享参数化核，本文件不含逻辑分支，
// 只把 golden 的扁平端口打包成核的数组/位向量接口，并给出本变体的参数）。
//
// 本变体规模（全部从 G1 golden EntriesVfdivVidiv.sv 机械量得）：
//   条目 10 = enq 2 + simp 2 + comp 6，发射口 1，源寄存器 5 个
//   WB 唤醒 16 路（无 IQ 唤醒、无 og0Cancel、无 ldCancel）
//   保留的 FuType one-hot 位：FuType[22], FuType[26]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位（comp 段没有：整条通路是死的）
//   issueResp 4 档（按 issueTimer）：timer0=常量 2'h0, timer1=常量 2'h1, timer2=真 resp, timer3=常量 2'h0
//   负载：发射口可见 56 个字段 / 741 位；转移包另带 124 个字段，共 1330 位
//   golden 层次：EnqEntry_18 ×2 + OthersEntry_164 ×2 + OthersEntry_166 ×6 + EnqPolicy_18 ×2，本文件把它们一并扁平化。
//
// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：
//   src0: WB[0..5]（vecWen），门控 srcType[2]
//   src1: WB[0..5]（vecWen），门控 srcType[2]
//   src2: WB[0..5]（vecWen），门控 srcType[2]
//   src3: WB[6..11]（v0Wen），门控 srcType[3]
//   src4: WB[12..15]（vlWen），门控 srcType[2]
//
// 自动生成：verif/ut/EntriesVfdivVidiv/gen.py（共享库 verif/ut/Entries_common/entries_gen.py）—— 勿手改
// =============================================================================
module EntriesVfdivVidiv (
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  input          io_enq_0_valid,
  input          io_enq_0_bits_status_robIdx_flag,
  input  [7:0]   io_enq_0_bits_status_robIdx_value,
  input          io_enq_0_bits_status_fuType_22,
  input          io_enq_0_bits_status_fuType_26,
  input  [6:0]   io_enq_0_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_0_srcType,
  input          io_enq_0_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_0_dataSources_value,
  input  [6:0]   io_enq_0_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_1_srcType,
  input          io_enq_0_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_1_dataSources_value,
  input  [6:0]   io_enq_0_bits_status_srcStatus_2_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_2_srcType,
  input          io_enq_0_bits_status_srcStatus_2_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_2_dataSources_value,
  input  [6:0]   io_enq_0_bits_status_srcStatus_3_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_3_srcType,
  input          io_enq_0_bits_status_srcStatus_3_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_3_dataSources_value,
  input  [6:0]   io_enq_0_bits_status_srcStatus_4_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_4_srcType,
  input          io_enq_0_bits_status_srcStatus_4_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_4_dataSources_value,
  input  [31:0]  io_enq_0_bits_payload_instr,
  input  [49:0]  io_enq_0_bits_payload_pc,
  input  [9:0]   io_enq_0_bits_payload_foldpc,
  input          io_enq_0_bits_payload_exceptionVec_0,
  input          io_enq_0_bits_payload_exceptionVec_1,
  input          io_enq_0_bits_payload_exceptionVec_2,
  input          io_enq_0_bits_payload_exceptionVec_3,
  input          io_enq_0_bits_payload_exceptionVec_4,
  input          io_enq_0_bits_payload_exceptionVec_5,
  input          io_enq_0_bits_payload_exceptionVec_6,
  input          io_enq_0_bits_payload_exceptionVec_7,
  input          io_enq_0_bits_payload_exceptionVec_8,
  input          io_enq_0_bits_payload_exceptionVec_9,
  input          io_enq_0_bits_payload_exceptionVec_10,
  input          io_enq_0_bits_payload_exceptionVec_11,
  input          io_enq_0_bits_payload_exceptionVec_12,
  input          io_enq_0_bits_payload_exceptionVec_13,
  input          io_enq_0_bits_payload_exceptionVec_14,
  input          io_enq_0_bits_payload_exceptionVec_15,
  input          io_enq_0_bits_payload_exceptionVec_16,
  input          io_enq_0_bits_payload_exceptionVec_17,
  input          io_enq_0_bits_payload_exceptionVec_18,
  input          io_enq_0_bits_payload_exceptionVec_19,
  input          io_enq_0_bits_payload_exceptionVec_20,
  input          io_enq_0_bits_payload_exceptionVec_21,
  input          io_enq_0_bits_payload_exceptionVec_22,
  input          io_enq_0_bits_payload_exceptionVec_23,
  input          io_enq_0_bits_payload_isFetchMalAddr,
  input          io_enq_0_bits_payload_hasException,
  input  [3:0]   io_enq_0_bits_payload_trigger,
  input          io_enq_0_bits_payload_preDecodeInfo_valid,
  input          io_enq_0_bits_payload_preDecodeInfo_isRVC,
  input  [1:0]   io_enq_0_bits_payload_preDecodeInfo_brType,
  input          io_enq_0_bits_payload_preDecodeInfo_isCall,
  input          io_enq_0_bits_payload_preDecodeInfo_isRet,
  input          io_enq_0_bits_payload_pred_taken,
  input          io_enq_0_bits_payload_crossPageIPFFix,
  input          io_enq_0_bits_payload_ftqPtr_flag,
  input  [5:0]   io_enq_0_bits_payload_ftqPtr_value,
  input  [3:0]   io_enq_0_bits_payload_ftqOffset,
  input          io_enq_0_bits_payload_satpFlushFirstFetchFault,
  input  [3:0]   io_enq_0_bits_payload_srcType_0,
  input  [3:0]   io_enq_0_bits_payload_srcType_1,
  input  [3:0]   io_enq_0_bits_payload_srcType_2,
  input  [3:0]   io_enq_0_bits_payload_srcType_3,
  input  [3:0]   io_enq_0_bits_payload_srcType_4,
  input  [5:0]   io_enq_0_bits_payload_ldest,
  input  [34:0]  io_enq_0_bits_payload_fuType,
  input  [8:0]   io_enq_0_bits_payload_fuOpType,
  input          io_enq_0_bits_payload_rfWen,
  input          io_enq_0_bits_payload_fpWen,
  input          io_enq_0_bits_payload_vecWen,
  input          io_enq_0_bits_payload_v0Wen,
  input          io_enq_0_bits_payload_vlWen,
  input          io_enq_0_bits_payload_isXSTrap,
  input          io_enq_0_bits_payload_waitForward,
  input          io_enq_0_bits_payload_blockBackward,
  input          io_enq_0_bits_payload_flushPipe,
  input          io_enq_0_bits_payload_canRobCompress,
  input  [3:0]   io_enq_0_bits_payload_selImm,
  input  [31:0]  io_enq_0_bits_payload_imm,
  input  [1:0]   io_enq_0_bits_payload_fpu_typeTagOut,
  input          io_enq_0_bits_payload_fpu_wflags,
  input  [1:0]   io_enq_0_bits_payload_fpu_typ,
  input  [1:0]   io_enq_0_bits_payload_fpu_fmt,
  input  [2:0]   io_enq_0_bits_payload_fpu_rm,
  input          io_enq_0_bits_payload_vpu_vill,
  input          io_enq_0_bits_payload_vpu_vma,
  input          io_enq_0_bits_payload_vpu_vta,
  input  [1:0]   io_enq_0_bits_payload_vpu_vsew,
  input  [2:0]   io_enq_0_bits_payload_vpu_vlmul,
  input          io_enq_0_bits_payload_vpu_specVill,
  input          io_enq_0_bits_payload_vpu_specVma,
  input          io_enq_0_bits_payload_vpu_specVta,
  input  [1:0]   io_enq_0_bits_payload_vpu_specVsew,
  input  [2:0]   io_enq_0_bits_payload_vpu_specVlmul,
  input          io_enq_0_bits_payload_vpu_vm,
  input  [7:0]   io_enq_0_bits_payload_vpu_vstart,
  input  [2:0]   io_enq_0_bits_payload_vpu_frm,
  input          io_enq_0_bits_payload_vpu_fpu_isFpToVecInst,
  input          io_enq_0_bits_payload_vpu_fpu_isFP32Instr,
  input          io_enq_0_bits_payload_vpu_fpu_isFP64Instr,
  input          io_enq_0_bits_payload_vpu_fpu_isReduction,
  input          io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2,
  input          io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4,
  input          io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_enq_0_bits_payload_vpu_vxrm,
  input  [6:0]   io_enq_0_bits_payload_vpu_vuopIdx,
  input          io_enq_0_bits_payload_vpu_lastUop,
  input  [127:0] io_enq_0_bits_payload_vpu_vmask,
  input  [7:0]   io_enq_0_bits_payload_vpu_vl,
  input  [2:0]   io_enq_0_bits_payload_vpu_nf,
  input  [1:0]   io_enq_0_bits_payload_vpu_veew,
  input          io_enq_0_bits_payload_vpu_isReverse,
  input          io_enq_0_bits_payload_vpu_isExt,
  input          io_enq_0_bits_payload_vpu_isNarrow,
  input          io_enq_0_bits_payload_vpu_isDstMask,
  input          io_enq_0_bits_payload_vpu_isOpMask,
  input          io_enq_0_bits_payload_vpu_isMove,
  input          io_enq_0_bits_payload_vpu_isDependOldVd,
  input          io_enq_0_bits_payload_vpu_isWritePartVd,
  input          io_enq_0_bits_payload_vpu_isVleff,
  input          io_enq_0_bits_payload_vlsInstr,
  input          io_enq_0_bits_payload_wfflags,
  input          io_enq_0_bits_payload_isMove,
  input          io_enq_0_bits_payload_isDropAmocasSta,
  input  [6:0]   io_enq_0_bits_payload_uopIdx,
  input          io_enq_0_bits_payload_isVset,
  input          io_enq_0_bits_payload_firstUop,
  input          io_enq_0_bits_payload_lastUop,
  input  [6:0]   io_enq_0_bits_payload_numUops,
  input  [6:0]   io_enq_0_bits_payload_numWB,
  input  [2:0]   io_enq_0_bits_payload_commitType,
  input          io_enq_0_bits_payload_srcState_0,
  input          io_enq_0_bits_payload_srcState_1,
  input          io_enq_0_bits_payload_srcState_2,
  input          io_enq_0_bits_payload_srcState_3,
  input          io_enq_0_bits_payload_srcState_4,
  input  [7:0]   io_enq_0_bits_payload_psrc_0,
  input  [7:0]   io_enq_0_bits_payload_psrc_1,
  input  [7:0]   io_enq_0_bits_payload_psrc_2,
  input  [7:0]   io_enq_0_bits_payload_psrc_3,
  input  [7:0]   io_enq_0_bits_payload_psrc_4,
  input  [7:0]   io_enq_0_bits_payload_pdest,
  input          io_enq_0_bits_payload_useRegCache_0,
  input          io_enq_0_bits_payload_useRegCache_1,
  input  [4:0]   io_enq_0_bits_payload_regCacheIdx_0,
  input  [4:0]   io_enq_0_bits_payload_regCacheIdx_1,
  input          io_enq_0_bits_payload_robIdx_flag,
  input  [7:0]   io_enq_0_bits_payload_robIdx_value,
  input  [2:0]   io_enq_0_bits_payload_instrSize,
  input          io_enq_0_bits_payload_dirtyFs,
  input          io_enq_0_bits_payload_dirtyVs,
  input  [3:0]   io_enq_0_bits_payload_traceBlockInPipe_itype,
  input  [3:0]   io_enq_0_bits_payload_traceBlockInPipe_iretire,
  input          io_enq_0_bits_payload_traceBlockInPipe_ilastsize,
  input          io_enq_0_bits_payload_eliminatedMove,
  input          io_enq_0_bits_payload_snapshot,
  input          io_enq_0_bits_payload_debugInfo_eliminatedMove,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_renameTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_dispatchTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_enqRsTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_selectTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_issueTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_writebackTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_enq_0_bits_payload_debugInfo_tlbRespTime,
  input  [55:0]  io_enq_0_bits_payload_debug_seqNum_seqNum,
  input  [7:0]   io_enq_0_bits_payload_debug_seqNum_uopIdx,
  input          io_enq_0_bits_payload_storeSetHit,
  input          io_enq_0_bits_payload_waitForRobIdx_flag,
  input  [7:0]   io_enq_0_bits_payload_waitForRobIdx_value,
  input          io_enq_0_bits_payload_loadWaitBit,
  input          io_enq_0_bits_payload_loadWaitStrict,
  input  [4:0]   io_enq_0_bits_payload_ssid,
  input          io_enq_0_bits_payload_lqIdx_flag,
  input  [6:0]   io_enq_0_bits_payload_lqIdx_value,
  input          io_enq_0_bits_payload_sqIdx_flag,
  input  [5:0]   io_enq_0_bits_payload_sqIdx_value,
  input          io_enq_0_bits_payload_singleStep,
  input          io_enq_0_bits_payload_replayInst,
  input  [34:0]  io_enq_0_bits_payload_debug_fuType,
  input          io_enq_0_bits_payload_debug_sim_trig,
  input  [4:0]   io_enq_0_bits_payload_numLsElem,
  input          io_enq_1_valid,
  input          io_enq_1_bits_status_robIdx_flag,
  input  [7:0]   io_enq_1_bits_status_robIdx_value,
  input          io_enq_1_bits_status_fuType_22,
  input          io_enq_1_bits_status_fuType_26,
  input  [6:0]   io_enq_1_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_0_srcType,
  input          io_enq_1_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_0_dataSources_value,
  input  [6:0]   io_enq_1_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_1_srcType,
  input          io_enq_1_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_1_dataSources_value,
  input  [6:0]   io_enq_1_bits_status_srcStatus_2_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_2_srcType,
  input          io_enq_1_bits_status_srcStatus_2_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_2_dataSources_value,
  input  [6:0]   io_enq_1_bits_status_srcStatus_3_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_3_srcType,
  input          io_enq_1_bits_status_srcStatus_3_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_3_dataSources_value,
  input  [6:0]   io_enq_1_bits_status_srcStatus_4_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_4_srcType,
  input          io_enq_1_bits_status_srcStatus_4_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_4_dataSources_value,
  input  [31:0]  io_enq_1_bits_payload_instr,
  input  [49:0]  io_enq_1_bits_payload_pc,
  input  [9:0]   io_enq_1_bits_payload_foldpc,
  input          io_enq_1_bits_payload_exceptionVec_0,
  input          io_enq_1_bits_payload_exceptionVec_1,
  input          io_enq_1_bits_payload_exceptionVec_2,
  input          io_enq_1_bits_payload_exceptionVec_3,
  input          io_enq_1_bits_payload_exceptionVec_4,
  input          io_enq_1_bits_payload_exceptionVec_5,
  input          io_enq_1_bits_payload_exceptionVec_6,
  input          io_enq_1_bits_payload_exceptionVec_7,
  input          io_enq_1_bits_payload_exceptionVec_8,
  input          io_enq_1_bits_payload_exceptionVec_9,
  input          io_enq_1_bits_payload_exceptionVec_10,
  input          io_enq_1_bits_payload_exceptionVec_11,
  input          io_enq_1_bits_payload_exceptionVec_12,
  input          io_enq_1_bits_payload_exceptionVec_13,
  input          io_enq_1_bits_payload_exceptionVec_14,
  input          io_enq_1_bits_payload_exceptionVec_15,
  input          io_enq_1_bits_payload_exceptionVec_16,
  input          io_enq_1_bits_payload_exceptionVec_17,
  input          io_enq_1_bits_payload_exceptionVec_18,
  input          io_enq_1_bits_payload_exceptionVec_19,
  input          io_enq_1_bits_payload_exceptionVec_20,
  input          io_enq_1_bits_payload_exceptionVec_21,
  input          io_enq_1_bits_payload_exceptionVec_22,
  input          io_enq_1_bits_payload_exceptionVec_23,
  input          io_enq_1_bits_payload_isFetchMalAddr,
  input          io_enq_1_bits_payload_hasException,
  input  [3:0]   io_enq_1_bits_payload_trigger,
  input          io_enq_1_bits_payload_preDecodeInfo_valid,
  input          io_enq_1_bits_payload_preDecodeInfo_isRVC,
  input  [1:0]   io_enq_1_bits_payload_preDecodeInfo_brType,
  input          io_enq_1_bits_payload_preDecodeInfo_isCall,
  input          io_enq_1_bits_payload_preDecodeInfo_isRet,
  input          io_enq_1_bits_payload_pred_taken,
  input          io_enq_1_bits_payload_crossPageIPFFix,
  input          io_enq_1_bits_payload_ftqPtr_flag,
  input  [5:0]   io_enq_1_bits_payload_ftqPtr_value,
  input  [3:0]   io_enq_1_bits_payload_ftqOffset,
  input          io_enq_1_bits_payload_satpFlushFirstFetchFault,
  input  [3:0]   io_enq_1_bits_payload_srcType_0,
  input  [3:0]   io_enq_1_bits_payload_srcType_1,
  input  [3:0]   io_enq_1_bits_payload_srcType_2,
  input  [3:0]   io_enq_1_bits_payload_srcType_3,
  input  [3:0]   io_enq_1_bits_payload_srcType_4,
  input  [5:0]   io_enq_1_bits_payload_ldest,
  input  [34:0]  io_enq_1_bits_payload_fuType,
  input  [8:0]   io_enq_1_bits_payload_fuOpType,
  input          io_enq_1_bits_payload_rfWen,
  input          io_enq_1_bits_payload_fpWen,
  input          io_enq_1_bits_payload_vecWen,
  input          io_enq_1_bits_payload_v0Wen,
  input          io_enq_1_bits_payload_vlWen,
  input          io_enq_1_bits_payload_isXSTrap,
  input          io_enq_1_bits_payload_waitForward,
  input          io_enq_1_bits_payload_blockBackward,
  input          io_enq_1_bits_payload_flushPipe,
  input          io_enq_1_bits_payload_canRobCompress,
  input  [3:0]   io_enq_1_bits_payload_selImm,
  input  [31:0]  io_enq_1_bits_payload_imm,
  input  [1:0]   io_enq_1_bits_payload_fpu_typeTagOut,
  input          io_enq_1_bits_payload_fpu_wflags,
  input  [1:0]   io_enq_1_bits_payload_fpu_typ,
  input  [1:0]   io_enq_1_bits_payload_fpu_fmt,
  input  [2:0]   io_enq_1_bits_payload_fpu_rm,
  input          io_enq_1_bits_payload_vpu_vill,
  input          io_enq_1_bits_payload_vpu_vma,
  input          io_enq_1_bits_payload_vpu_vta,
  input  [1:0]   io_enq_1_bits_payload_vpu_vsew,
  input  [2:0]   io_enq_1_bits_payload_vpu_vlmul,
  input          io_enq_1_bits_payload_vpu_specVill,
  input          io_enq_1_bits_payload_vpu_specVma,
  input          io_enq_1_bits_payload_vpu_specVta,
  input  [1:0]   io_enq_1_bits_payload_vpu_specVsew,
  input  [2:0]   io_enq_1_bits_payload_vpu_specVlmul,
  input          io_enq_1_bits_payload_vpu_vm,
  input  [7:0]   io_enq_1_bits_payload_vpu_vstart,
  input  [2:0]   io_enq_1_bits_payload_vpu_frm,
  input          io_enq_1_bits_payload_vpu_fpu_isFpToVecInst,
  input          io_enq_1_bits_payload_vpu_fpu_isFP32Instr,
  input          io_enq_1_bits_payload_vpu_fpu_isFP64Instr,
  input          io_enq_1_bits_payload_vpu_fpu_isReduction,
  input          io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2,
  input          io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4,
  input          io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_enq_1_bits_payload_vpu_vxrm,
  input  [6:0]   io_enq_1_bits_payload_vpu_vuopIdx,
  input          io_enq_1_bits_payload_vpu_lastUop,
  input  [127:0] io_enq_1_bits_payload_vpu_vmask,
  input  [7:0]   io_enq_1_bits_payload_vpu_vl,
  input  [2:0]   io_enq_1_bits_payload_vpu_nf,
  input  [1:0]   io_enq_1_bits_payload_vpu_veew,
  input          io_enq_1_bits_payload_vpu_isReverse,
  input          io_enq_1_bits_payload_vpu_isExt,
  input          io_enq_1_bits_payload_vpu_isNarrow,
  input          io_enq_1_bits_payload_vpu_isDstMask,
  input          io_enq_1_bits_payload_vpu_isOpMask,
  input          io_enq_1_bits_payload_vpu_isMove,
  input          io_enq_1_bits_payload_vpu_isDependOldVd,
  input          io_enq_1_bits_payload_vpu_isWritePartVd,
  input          io_enq_1_bits_payload_vpu_isVleff,
  input          io_enq_1_bits_payload_vlsInstr,
  input          io_enq_1_bits_payload_wfflags,
  input          io_enq_1_bits_payload_isMove,
  input          io_enq_1_bits_payload_isDropAmocasSta,
  input  [6:0]   io_enq_1_bits_payload_uopIdx,
  input          io_enq_1_bits_payload_isVset,
  input          io_enq_1_bits_payload_firstUop,
  input          io_enq_1_bits_payload_lastUop,
  input  [6:0]   io_enq_1_bits_payload_numUops,
  input  [6:0]   io_enq_1_bits_payload_numWB,
  input  [2:0]   io_enq_1_bits_payload_commitType,
  input          io_enq_1_bits_payload_srcState_0,
  input          io_enq_1_bits_payload_srcState_1,
  input          io_enq_1_bits_payload_srcState_2,
  input          io_enq_1_bits_payload_srcState_3,
  input          io_enq_1_bits_payload_srcState_4,
  input  [7:0]   io_enq_1_bits_payload_psrc_0,
  input  [7:0]   io_enq_1_bits_payload_psrc_1,
  input  [7:0]   io_enq_1_bits_payload_psrc_2,
  input  [7:0]   io_enq_1_bits_payload_psrc_3,
  input  [7:0]   io_enq_1_bits_payload_psrc_4,
  input  [7:0]   io_enq_1_bits_payload_pdest,
  input          io_enq_1_bits_payload_useRegCache_0,
  input          io_enq_1_bits_payload_useRegCache_1,
  input  [4:0]   io_enq_1_bits_payload_regCacheIdx_0,
  input  [4:0]   io_enq_1_bits_payload_regCacheIdx_1,
  input          io_enq_1_bits_payload_robIdx_flag,
  input  [7:0]   io_enq_1_bits_payload_robIdx_value,
  input  [2:0]   io_enq_1_bits_payload_instrSize,
  input          io_enq_1_bits_payload_dirtyFs,
  input          io_enq_1_bits_payload_dirtyVs,
  input  [3:0]   io_enq_1_bits_payload_traceBlockInPipe_itype,
  input  [3:0]   io_enq_1_bits_payload_traceBlockInPipe_iretire,
  input          io_enq_1_bits_payload_traceBlockInPipe_ilastsize,
  input          io_enq_1_bits_payload_eliminatedMove,
  input          io_enq_1_bits_payload_snapshot,
  input          io_enq_1_bits_payload_debugInfo_eliminatedMove,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_renameTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_dispatchTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_enqRsTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_selectTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_issueTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_writebackTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_enq_1_bits_payload_debugInfo_tlbRespTime,
  input  [55:0]  io_enq_1_bits_payload_debug_seqNum_seqNum,
  input  [7:0]   io_enq_1_bits_payload_debug_seqNum_uopIdx,
  input          io_enq_1_bits_payload_storeSetHit,
  input          io_enq_1_bits_payload_waitForRobIdx_flag,
  input  [7:0]   io_enq_1_bits_payload_waitForRobIdx_value,
  input          io_enq_1_bits_payload_loadWaitBit,
  input          io_enq_1_bits_payload_loadWaitStrict,
  input  [4:0]   io_enq_1_bits_payload_ssid,
  input          io_enq_1_bits_payload_lqIdx_flag,
  input  [6:0]   io_enq_1_bits_payload_lqIdx_value,
  input          io_enq_1_bits_payload_sqIdx_flag,
  input  [5:0]   io_enq_1_bits_payload_sqIdx_value,
  input          io_enq_1_bits_payload_singleStep,
  input          io_enq_1_bits_payload_replayInst,
  input  [34:0]  io_enq_1_bits_payload_debug_fuType,
  input          io_enq_1_bits_payload_debug_sim_trig,
  input  [4:0]   io_enq_1_bits_payload_numLsElem,
  input          io_og0Resp_0_valid,
  input          io_og1Resp_0_valid,
  input          io_og2Resp_0_valid,
  input  [1:0]   io_og2Resp_0_bits_resp,
  input          io_deqReady_0,
  input          io_deqSelOH_0_valid,
  input  [9:0]   io_deqSelOH_0_bits,
  input  [1:0]   io_enqEntryOldestSel_0_bits,
  input          io_simpEntryOldestSel_0_valid,
  input  [1:0]   io_simpEntryOldestSel_0_bits,
  input          io_compEntryOldestSel_0_valid,
  input  [5:0]   io_compEntryOldestSel_0_bits,
  input          io_wakeUpFromWB_15_valid,
  input          io_wakeUpFromWB_15_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_15_bits_pdest,
  input          io_wakeUpFromWB_14_valid,
  input          io_wakeUpFromWB_14_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_14_bits_pdest,
  input          io_wakeUpFromWB_13_valid,
  input          io_wakeUpFromWB_13_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_13_bits_pdest,
  input          io_wakeUpFromWB_12_valid,
  input          io_wakeUpFromWB_12_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_12_bits_pdest,
  input          io_wakeUpFromWB_11_valid,
  input          io_wakeUpFromWB_11_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWB_11_bits_pdest,
  input          io_wakeUpFromWB_10_valid,
  input          io_wakeUpFromWB_10_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWB_10_bits_pdest,
  input          io_wakeUpFromWB_9_valid,
  input          io_wakeUpFromWB_9_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWB_9_bits_pdest,
  input          io_wakeUpFromWB_8_valid,
  input          io_wakeUpFromWB_8_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWB_8_bits_pdest,
  input          io_wakeUpFromWB_7_valid,
  input          io_wakeUpFromWB_7_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWB_7_bits_pdest,
  input          io_wakeUpFromWB_6_valid,
  input          io_wakeUpFromWB_6_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWB_6_bits_pdest,
  input          io_wakeUpFromWB_5_valid,
  input          io_wakeUpFromWB_5_bits_vecWen,
  input  [7:0]   io_wakeUpFromWB_5_bits_pdest,
  input          io_wakeUpFromWB_4_valid,
  input          io_wakeUpFromWB_4_bits_vecWen,
  input  [7:0]   io_wakeUpFromWB_4_bits_pdest,
  input          io_wakeUpFromWB_3_valid,
  input          io_wakeUpFromWB_3_bits_vecWen,
  input  [7:0]   io_wakeUpFromWB_3_bits_pdest,
  input          io_wakeUpFromWB_2_valid,
  input          io_wakeUpFromWB_2_bits_vecWen,
  input  [7:0]   io_wakeUpFromWB_2_bits_pdest,
  input          io_wakeUpFromWB_1_valid,
  input          io_wakeUpFromWB_1_bits_vecWen,
  input  [7:0]   io_wakeUpFromWB_1_bits_pdest,
  input          io_wakeUpFromWB_0_valid,
  input          io_wakeUpFromWB_0_bits_vecWen,
  input  [7:0]   io_wakeUpFromWB_0_bits_pdest,
  input          io_wakeUpFromWBDelayed_15_valid,
  input          io_wakeUpFromWBDelayed_15_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_15_bits_pdest,
  input          io_wakeUpFromWBDelayed_14_valid,
  input          io_wakeUpFromWBDelayed_14_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_14_bits_pdest,
  input          io_wakeUpFromWBDelayed_13_valid,
  input          io_wakeUpFromWBDelayed_13_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_13_bits_pdest,
  input          io_wakeUpFromWBDelayed_12_valid,
  input          io_wakeUpFromWBDelayed_12_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_12_bits_pdest,
  input          io_wakeUpFromWBDelayed_11_valid,
  input          io_wakeUpFromWBDelayed_11_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWBDelayed_11_bits_pdest,
  input          io_wakeUpFromWBDelayed_10_valid,
  input          io_wakeUpFromWBDelayed_10_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWBDelayed_10_bits_pdest,
  input          io_wakeUpFromWBDelayed_9_valid,
  input          io_wakeUpFromWBDelayed_9_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWBDelayed_9_bits_pdest,
  input          io_wakeUpFromWBDelayed_8_valid,
  input          io_wakeUpFromWBDelayed_8_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWBDelayed_8_bits_pdest,
  input          io_wakeUpFromWBDelayed_7_valid,
  input          io_wakeUpFromWBDelayed_7_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWBDelayed_7_bits_pdest,
  input          io_wakeUpFromWBDelayed_6_valid,
  input          io_wakeUpFromWBDelayed_6_bits_v0Wen,
  input  [7:0]   io_wakeUpFromWBDelayed_6_bits_pdest,
  input          io_wakeUpFromWBDelayed_5_valid,
  input          io_wakeUpFromWBDelayed_5_bits_vecWen,
  input  [7:0]   io_wakeUpFromWBDelayed_5_bits_pdest,
  input          io_wakeUpFromWBDelayed_4_valid,
  input          io_wakeUpFromWBDelayed_4_bits_vecWen,
  input  [7:0]   io_wakeUpFromWBDelayed_4_bits_pdest,
  input          io_wakeUpFromWBDelayed_3_valid,
  input          io_wakeUpFromWBDelayed_3_bits_vecWen,
  input  [7:0]   io_wakeUpFromWBDelayed_3_bits_pdest,
  input          io_wakeUpFromWBDelayed_2_valid,
  input          io_wakeUpFromWBDelayed_2_bits_vecWen,
  input  [7:0]   io_wakeUpFromWBDelayed_2_bits_pdest,
  input          io_wakeUpFromWBDelayed_1_valid,
  input          io_wakeUpFromWBDelayed_1_bits_vecWen,
  input  [7:0]   io_wakeUpFromWBDelayed_1_bits_pdest,
  input          io_wakeUpFromWBDelayed_0_valid,
  input          io_wakeUpFromWBDelayed_0_bits_vecWen,
  input  [7:0]   io_wakeUpFromWBDelayed_0_bits_pdest,
  input          io_vlFromIntIsZero,
  input          io_vlFromIntIsVlmax,
  input          io_vlFromVfIsZero,
  input          io_vlFromVfIsVlmax,
  output [9:0]   io_valid,
  output [9:0]   io_issued,
  output [9:0]   io_canIssue,
  output [34:0]  io_fuType_0,
  output [34:0]  io_fuType_1,
  output [34:0]  io_fuType_2,
  output [34:0]  io_fuType_3,
  output [34:0]  io_fuType_4,
  output [34:0]  io_fuType_5,
  output [34:0]  io_fuType_6,
  output [34:0]  io_fuType_7,
  output [34:0]  io_fuType_8,
  output [34:0]  io_fuType_9,
  output [3:0]   io_dataSources_0_0_value,
  output [3:0]   io_dataSources_0_1_value,
  output [3:0]   io_dataSources_0_2_value,
  output [3:0]   io_dataSources_0_3_value,
  output [3:0]   io_dataSources_0_4_value,
  output [3:0]   io_dataSources_1_0_value,
  output [3:0]   io_dataSources_1_1_value,
  output [3:0]   io_dataSources_1_2_value,
  output [3:0]   io_dataSources_1_3_value,
  output [3:0]   io_dataSources_1_4_value,
  output [3:0]   io_dataSources_2_0_value,
  output [3:0]   io_dataSources_2_1_value,
  output [3:0]   io_dataSources_2_2_value,
  output [3:0]   io_dataSources_2_3_value,
  output [3:0]   io_dataSources_2_4_value,
  output [3:0]   io_dataSources_3_0_value,
  output [3:0]   io_dataSources_3_1_value,
  output [3:0]   io_dataSources_3_2_value,
  output [3:0]   io_dataSources_3_3_value,
  output [3:0]   io_dataSources_3_4_value,
  output [3:0]   io_dataSources_4_0_value,
  output [3:0]   io_dataSources_4_1_value,
  output [3:0]   io_dataSources_4_2_value,
  output [3:0]   io_dataSources_4_3_value,
  output [3:0]   io_dataSources_4_4_value,
  output [3:0]   io_dataSources_5_0_value,
  output [3:0]   io_dataSources_5_1_value,
  output [3:0]   io_dataSources_5_2_value,
  output [3:0]   io_dataSources_5_3_value,
  output [3:0]   io_dataSources_5_4_value,
  output [3:0]   io_dataSources_6_0_value,
  output [3:0]   io_dataSources_6_1_value,
  output [3:0]   io_dataSources_6_2_value,
  output [3:0]   io_dataSources_6_3_value,
  output [3:0]   io_dataSources_6_4_value,
  output [3:0]   io_dataSources_7_0_value,
  output [3:0]   io_dataSources_7_1_value,
  output [3:0]   io_dataSources_7_2_value,
  output [3:0]   io_dataSources_7_3_value,
  output [3:0]   io_dataSources_7_4_value,
  output [3:0]   io_dataSources_8_0_value,
  output [3:0]   io_dataSources_8_1_value,
  output [3:0]   io_dataSources_8_2_value,
  output [3:0]   io_dataSources_8_3_value,
  output [3:0]   io_dataSources_8_4_value,
  output [3:0]   io_dataSources_9_0_value,
  output [3:0]   io_dataSources_9_1_value,
  output [3:0]   io_dataSources_9_2_value,
  output [3:0]   io_dataSources_9_3_value,
  output [3:0]   io_dataSources_9_4_value,
  output         io_isFirstIssue_0,
  output         io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0]   io_deqEntry_0_bits_status_robIdx_value,
  output         io_deqEntry_0_bits_status_fuType_22,
  output         io_deqEntry_0_bits_status_fuType_26,
  output [6:0]   io_deqEntry_0_bits_status_srcStatus_0_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_0_srcType,
  output [6:0]   io_deqEntry_0_bits_status_srcStatus_1_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_1_srcType,
  output [6:0]   io_deqEntry_0_bits_status_srcStatus_2_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_2_srcType,
  output [6:0]   io_deqEntry_0_bits_status_srcStatus_3_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_3_srcType,
  output [6:0]   io_deqEntry_0_bits_status_srcStatus_4_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_4_srcType,
  output [8:0]   io_deqEntry_0_bits_payload_fuOpType,
  output         io_deqEntry_0_bits_payload_vecWen,
  output         io_deqEntry_0_bits_payload_v0Wen,
  output [3:0]   io_deqEntry_0_bits_payload_selImm,
  output [1:0]   io_deqEntry_0_bits_payload_fpu_typeTagOut,
  output         io_deqEntry_0_bits_payload_fpu_wflags,
  output [1:0]   io_deqEntry_0_bits_payload_fpu_typ,
  output [1:0]   io_deqEntry_0_bits_payload_fpu_fmt,
  output [2:0]   io_deqEntry_0_bits_payload_fpu_rm,
  output         io_deqEntry_0_bits_payload_vpu_vill,
  output         io_deqEntry_0_bits_payload_vpu_vma,
  output         io_deqEntry_0_bits_payload_vpu_vta,
  output [1:0]   io_deqEntry_0_bits_payload_vpu_vsew,
  output [2:0]   io_deqEntry_0_bits_payload_vpu_vlmul,
  output         io_deqEntry_0_bits_payload_vpu_specVill,
  output         io_deqEntry_0_bits_payload_vpu_specVma,
  output         io_deqEntry_0_bits_payload_vpu_specVta,
  output [1:0]   io_deqEntry_0_bits_payload_vpu_specVsew,
  output [2:0]   io_deqEntry_0_bits_payload_vpu_specVlmul,
  output         io_deqEntry_0_bits_payload_vpu_vm,
  output [7:0]   io_deqEntry_0_bits_payload_vpu_vstart,
  output [2:0]   io_deqEntry_0_bits_payload_vpu_frm,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isReduction,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4,
  output         io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_deqEntry_0_bits_payload_vpu_vxrm,
  output [127:0] io_deqEntry_0_bits_payload_vpu_vmask,
  output [7:0]   io_deqEntry_0_bits_payload_vpu_vl,
  output [2:0]   io_deqEntry_0_bits_payload_vpu_nf,
  output [1:0]   io_deqEntry_0_bits_payload_vpu_veew,
  output         io_deqEntry_0_bits_payload_vpu_isReverse,
  output         io_deqEntry_0_bits_payload_vpu_isExt,
  output         io_deqEntry_0_bits_payload_vpu_isNarrow,
  output         io_deqEntry_0_bits_payload_vpu_isDstMask,
  output         io_deqEntry_0_bits_payload_vpu_isOpMask,
  output         io_deqEntry_0_bits_payload_vpu_isMove,
  output         io_deqEntry_0_bits_payload_vpu_isDependOldVd,
  output         io_deqEntry_0_bits_payload_vpu_isWritePartVd,
  output         io_deqEntry_0_bits_payload_vpu_isVleff,
  output [6:0]   io_deqEntry_0_bits_payload_uopIdx,
  output         io_deqEntry_0_bits_payload_lastUop,
  output [7:0]   io_deqEntry_0_bits_payload_pdest,
  output         io_deqEntry_0_bits_payload_debugInfo_eliminatedMove,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_renameTime,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_dispatchTime,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_enqRsTime,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_writebackTime,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime,
  output [63:0]  io_deqEntry_0_bits_payload_debugInfo_tlbRespTime,
  output [55:0]  io_deqEntry_0_bits_payload_debug_seqNum_seqNum,
  output [7:0]   io_deqEntry_0_bits_payload_debug_seqNum_uopIdx,
  input  [1:0]   io_simpEntryDeqSelVec_0,
  input  [1:0]   io_simpEntryDeqSelVec_1,
  output [1:0]   io_simpEntryEnqSelVec_0,
  output [1:0]   io_simpEntryEnqSelVec_1,
  output [5:0]   io_compEntryEnqSelVec_0,
  output [5:0]   io_compEntryEnqSelVec_1
);

  // BEGIN GENERATED(core-inst)
  logic [1:0][1329:0] enq_payload;
  assign enq_payload[0] = {io_enq_0_bits_payload_numLsElem, io_enq_0_bits_payload_debug_sim_trig, io_enq_0_bits_payload_debug_fuType, io_enq_0_bits_payload_replayInst, io_enq_0_bits_payload_singleStep, io_enq_0_bits_payload_sqIdx_value, io_enq_0_bits_payload_sqIdx_flag, io_enq_0_bits_payload_lqIdx_value, io_enq_0_bits_payload_lqIdx_flag, io_enq_0_bits_payload_ssid, io_enq_0_bits_payload_loadWaitStrict, io_enq_0_bits_payload_loadWaitBit, io_enq_0_bits_payload_waitForRobIdx_value, io_enq_0_bits_payload_waitForRobIdx_flag, io_enq_0_bits_payload_storeSetHit, io_enq_0_bits_payload_debugInfo_issueTime, io_enq_0_bits_payload_debugInfo_selectTime, io_enq_0_bits_payload_snapshot, io_enq_0_bits_payload_eliminatedMove, io_enq_0_bits_payload_traceBlockInPipe_ilastsize, io_enq_0_bits_payload_traceBlockInPipe_iretire, io_enq_0_bits_payload_traceBlockInPipe_itype, io_enq_0_bits_payload_dirtyVs, io_enq_0_bits_payload_dirtyFs, io_enq_0_bits_payload_instrSize, io_enq_0_bits_payload_robIdx_value, io_enq_0_bits_payload_robIdx_flag, io_enq_0_bits_payload_regCacheIdx_1, io_enq_0_bits_payload_regCacheIdx_0, io_enq_0_bits_payload_useRegCache_1, io_enq_0_bits_payload_useRegCache_0, io_enq_0_bits_payload_psrc_4, io_enq_0_bits_payload_psrc_3, io_enq_0_bits_payload_psrc_2, io_enq_0_bits_payload_psrc_1, io_enq_0_bits_payload_psrc_0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, io_enq_0_bits_payload_srcState_4, io_enq_0_bits_payload_srcState_3, io_enq_0_bits_payload_srcState_2, io_enq_0_bits_payload_srcState_1, io_enq_0_bits_payload_srcState_0, io_enq_0_bits_payload_commitType, io_enq_0_bits_payload_numWB, io_enq_0_bits_payload_numUops, io_enq_0_bits_payload_firstUop, io_enq_0_bits_payload_isVset, io_enq_0_bits_payload_isDropAmocasSta, io_enq_0_bits_payload_isMove, io_enq_0_bits_payload_wfflags, io_enq_0_bits_payload_vlsInstr, io_enq_0_bits_payload_vpu_lastUop, io_enq_0_bits_payload_vpu_vuopIdx, io_enq_0_bits_payload_imm, io_enq_0_bits_payload_canRobCompress, io_enq_0_bits_payload_flushPipe, io_enq_0_bits_payload_blockBackward, io_enq_0_bits_payload_waitForward, io_enq_0_bits_payload_isXSTrap, io_enq_0_bits_payload_vlWen, io_enq_0_bits_payload_fpWen, io_enq_0_bits_payload_rfWen, io_enq_0_bits_payload_fuType, io_enq_0_bits_payload_ldest, io_enq_0_bits_payload_srcType_4, io_enq_0_bits_payload_srcType_3, io_enq_0_bits_payload_srcType_2, io_enq_0_bits_payload_srcType_1, io_enq_0_bits_payload_srcType_0, io_enq_0_bits_payload_satpFlushFirstFetchFault, io_enq_0_bits_payload_ftqOffset, io_enq_0_bits_payload_ftqPtr_value, io_enq_0_bits_payload_ftqPtr_flag, io_enq_0_bits_payload_crossPageIPFFix, io_enq_0_bits_payload_pred_taken, io_enq_0_bits_payload_preDecodeInfo_isRet, io_enq_0_bits_payload_preDecodeInfo_isCall, io_enq_0_bits_payload_preDecodeInfo_brType, io_enq_0_bits_payload_preDecodeInfo_isRVC, io_enq_0_bits_payload_preDecodeInfo_valid, io_enq_0_bits_payload_trigger, io_enq_0_bits_payload_hasException, io_enq_0_bits_payload_isFetchMalAddr, io_enq_0_bits_payload_exceptionVec_23, io_enq_0_bits_payload_exceptionVec_22, io_enq_0_bits_payload_exceptionVec_21, io_enq_0_bits_payload_exceptionVec_20, io_enq_0_bits_payload_exceptionVec_19, io_enq_0_bits_payload_exceptionVec_18, io_enq_0_bits_payload_exceptionVec_17, io_enq_0_bits_payload_exceptionVec_16, io_enq_0_bits_payload_exceptionVec_15, io_enq_0_bits_payload_exceptionVec_14, io_enq_0_bits_payload_exceptionVec_13, io_enq_0_bits_payload_exceptionVec_12, io_enq_0_bits_payload_exceptionVec_11, io_enq_0_bits_payload_exceptionVec_10, io_enq_0_bits_payload_exceptionVec_9, io_enq_0_bits_payload_exceptionVec_8, io_enq_0_bits_payload_exceptionVec_7, io_enq_0_bits_payload_exceptionVec_6, io_enq_0_bits_payload_exceptionVec_5, io_enq_0_bits_payload_exceptionVec_4, io_enq_0_bits_payload_exceptionVec_3, io_enq_0_bits_payload_exceptionVec_2, io_enq_0_bits_payload_exceptionVec_1, io_enq_0_bits_payload_exceptionVec_0, io_enq_0_bits_payload_foldpc, io_enq_0_bits_payload_pc, io_enq_0_bits_payload_instr, io_enq_0_bits_payload_debug_seqNum_uopIdx, io_enq_0_bits_payload_debug_seqNum_seqNum, io_enq_0_bits_payload_debugInfo_tlbRespTime, io_enq_0_bits_payload_debugInfo_tlbFirstReqTime, io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_0_bits_payload_debugInfo_writebackTime, io_enq_0_bits_payload_debugInfo_enqRsTime, io_enq_0_bits_payload_debugInfo_dispatchTime, io_enq_0_bits_payload_debugInfo_renameTime, io_enq_0_bits_payload_debugInfo_eliminatedMove, io_enq_0_bits_payload_pdest, io_enq_0_bits_payload_lastUop, io_enq_0_bits_payload_uopIdx, io_enq_0_bits_payload_vpu_isVleff, io_enq_0_bits_payload_vpu_isWritePartVd, io_enq_0_bits_payload_vpu_isDependOldVd, io_enq_0_bits_payload_vpu_isMove, io_enq_0_bits_payload_vpu_isOpMask, io_enq_0_bits_payload_vpu_isDstMask, io_enq_0_bits_payload_vpu_isNarrow, io_enq_0_bits_payload_vpu_isExt, io_enq_0_bits_payload_vpu_isReverse, io_enq_0_bits_payload_vpu_veew, io_enq_0_bits_payload_vpu_nf, io_enq_0_bits_payload_vpu_vl, io_enq_0_bits_payload_vpu_vmask, io_enq_0_bits_payload_vpu_vxrm, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_0_bits_payload_vpu_fpu_isReduction, io_enq_0_bits_payload_vpu_fpu_isFP64Instr, io_enq_0_bits_payload_vpu_fpu_isFP32Instr, io_enq_0_bits_payload_vpu_fpu_isFpToVecInst, io_enq_0_bits_payload_vpu_frm, io_enq_0_bits_payload_vpu_vstart, io_enq_0_bits_payload_vpu_vm, io_enq_0_bits_payload_vpu_specVlmul, io_enq_0_bits_payload_vpu_specVsew, io_enq_0_bits_payload_vpu_specVta, io_enq_0_bits_payload_vpu_specVma, io_enq_0_bits_payload_vpu_specVill, io_enq_0_bits_payload_vpu_vlmul, io_enq_0_bits_payload_vpu_vsew, io_enq_0_bits_payload_vpu_vta, io_enq_0_bits_payload_vpu_vma, io_enq_0_bits_payload_vpu_vill, io_enq_0_bits_payload_fpu_rm, io_enq_0_bits_payload_fpu_fmt, io_enq_0_bits_payload_fpu_typ, io_enq_0_bits_payload_fpu_wflags, io_enq_0_bits_payload_fpu_typeTagOut, io_enq_0_bits_payload_selImm, io_enq_0_bits_payload_v0Wen, io_enq_0_bits_payload_vecWen, io_enq_0_bits_payload_fuOpType};
  assign enq_payload[1] = {io_enq_1_bits_payload_numLsElem, io_enq_1_bits_payload_debug_sim_trig, io_enq_1_bits_payload_debug_fuType, io_enq_1_bits_payload_replayInst, io_enq_1_bits_payload_singleStep, io_enq_1_bits_payload_sqIdx_value, io_enq_1_bits_payload_sqIdx_flag, io_enq_1_bits_payload_lqIdx_value, io_enq_1_bits_payload_lqIdx_flag, io_enq_1_bits_payload_ssid, io_enq_1_bits_payload_loadWaitStrict, io_enq_1_bits_payload_loadWaitBit, io_enq_1_bits_payload_waitForRobIdx_value, io_enq_1_bits_payload_waitForRobIdx_flag, io_enq_1_bits_payload_storeSetHit, io_enq_1_bits_payload_debugInfo_issueTime, io_enq_1_bits_payload_debugInfo_selectTime, io_enq_1_bits_payload_snapshot, io_enq_1_bits_payload_eliminatedMove, io_enq_1_bits_payload_traceBlockInPipe_ilastsize, io_enq_1_bits_payload_traceBlockInPipe_iretire, io_enq_1_bits_payload_traceBlockInPipe_itype, io_enq_1_bits_payload_dirtyVs, io_enq_1_bits_payload_dirtyFs, io_enq_1_bits_payload_instrSize, io_enq_1_bits_payload_robIdx_value, io_enq_1_bits_payload_robIdx_flag, io_enq_1_bits_payload_regCacheIdx_1, io_enq_1_bits_payload_regCacheIdx_0, io_enq_1_bits_payload_useRegCache_1, io_enq_1_bits_payload_useRegCache_0, io_enq_1_bits_payload_psrc_4, io_enq_1_bits_payload_psrc_3, io_enq_1_bits_payload_psrc_2, io_enq_1_bits_payload_psrc_1, io_enq_1_bits_payload_psrc_0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, io_enq_1_bits_payload_srcState_4, io_enq_1_bits_payload_srcState_3, io_enq_1_bits_payload_srcState_2, io_enq_1_bits_payload_srcState_1, io_enq_1_bits_payload_srcState_0, io_enq_1_bits_payload_commitType, io_enq_1_bits_payload_numWB, io_enq_1_bits_payload_numUops, io_enq_1_bits_payload_firstUop, io_enq_1_bits_payload_isVset, io_enq_1_bits_payload_isDropAmocasSta, io_enq_1_bits_payload_isMove, io_enq_1_bits_payload_wfflags, io_enq_1_bits_payload_vlsInstr, io_enq_1_bits_payload_vpu_lastUop, io_enq_1_bits_payload_vpu_vuopIdx, io_enq_1_bits_payload_imm, io_enq_1_bits_payload_canRobCompress, io_enq_1_bits_payload_flushPipe, io_enq_1_bits_payload_blockBackward, io_enq_1_bits_payload_waitForward, io_enq_1_bits_payload_isXSTrap, io_enq_1_bits_payload_vlWen, io_enq_1_bits_payload_fpWen, io_enq_1_bits_payload_rfWen, io_enq_1_bits_payload_fuType, io_enq_1_bits_payload_ldest, io_enq_1_bits_payload_srcType_4, io_enq_1_bits_payload_srcType_3, io_enq_1_bits_payload_srcType_2, io_enq_1_bits_payload_srcType_1, io_enq_1_bits_payload_srcType_0, io_enq_1_bits_payload_satpFlushFirstFetchFault, io_enq_1_bits_payload_ftqOffset, io_enq_1_bits_payload_ftqPtr_value, io_enq_1_bits_payload_ftqPtr_flag, io_enq_1_bits_payload_crossPageIPFFix, io_enq_1_bits_payload_pred_taken, io_enq_1_bits_payload_preDecodeInfo_isRet, io_enq_1_bits_payload_preDecodeInfo_isCall, io_enq_1_bits_payload_preDecodeInfo_brType, io_enq_1_bits_payload_preDecodeInfo_isRVC, io_enq_1_bits_payload_preDecodeInfo_valid, io_enq_1_bits_payload_trigger, io_enq_1_bits_payload_hasException, io_enq_1_bits_payload_isFetchMalAddr, io_enq_1_bits_payload_exceptionVec_23, io_enq_1_bits_payload_exceptionVec_22, io_enq_1_bits_payload_exceptionVec_21, io_enq_1_bits_payload_exceptionVec_20, io_enq_1_bits_payload_exceptionVec_19, io_enq_1_bits_payload_exceptionVec_18, io_enq_1_bits_payload_exceptionVec_17, io_enq_1_bits_payload_exceptionVec_16, io_enq_1_bits_payload_exceptionVec_15, io_enq_1_bits_payload_exceptionVec_14, io_enq_1_bits_payload_exceptionVec_13, io_enq_1_bits_payload_exceptionVec_12, io_enq_1_bits_payload_exceptionVec_11, io_enq_1_bits_payload_exceptionVec_10, io_enq_1_bits_payload_exceptionVec_9, io_enq_1_bits_payload_exceptionVec_8, io_enq_1_bits_payload_exceptionVec_7, io_enq_1_bits_payload_exceptionVec_6, io_enq_1_bits_payload_exceptionVec_5, io_enq_1_bits_payload_exceptionVec_4, io_enq_1_bits_payload_exceptionVec_3, io_enq_1_bits_payload_exceptionVec_2, io_enq_1_bits_payload_exceptionVec_1, io_enq_1_bits_payload_exceptionVec_0, io_enq_1_bits_payload_foldpc, io_enq_1_bits_payload_pc, io_enq_1_bits_payload_instr, io_enq_1_bits_payload_debug_seqNum_uopIdx, io_enq_1_bits_payload_debug_seqNum_seqNum, io_enq_1_bits_payload_debugInfo_tlbRespTime, io_enq_1_bits_payload_debugInfo_tlbFirstReqTime, io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_1_bits_payload_debugInfo_writebackTime, io_enq_1_bits_payload_debugInfo_enqRsTime, io_enq_1_bits_payload_debugInfo_dispatchTime, io_enq_1_bits_payload_debugInfo_renameTime, io_enq_1_bits_payload_debugInfo_eliminatedMove, io_enq_1_bits_payload_pdest, io_enq_1_bits_payload_lastUop, io_enq_1_bits_payload_uopIdx, io_enq_1_bits_payload_vpu_isVleff, io_enq_1_bits_payload_vpu_isWritePartVd, io_enq_1_bits_payload_vpu_isDependOldVd, io_enq_1_bits_payload_vpu_isMove, io_enq_1_bits_payload_vpu_isOpMask, io_enq_1_bits_payload_vpu_isDstMask, io_enq_1_bits_payload_vpu_isNarrow, io_enq_1_bits_payload_vpu_isExt, io_enq_1_bits_payload_vpu_isReverse, io_enq_1_bits_payload_vpu_veew, io_enq_1_bits_payload_vpu_nf, io_enq_1_bits_payload_vpu_vl, io_enq_1_bits_payload_vpu_vmask, io_enq_1_bits_payload_vpu_vxrm, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_1_bits_payload_vpu_fpu_isReduction, io_enq_1_bits_payload_vpu_fpu_isFP64Instr, io_enq_1_bits_payload_vpu_fpu_isFP32Instr, io_enq_1_bits_payload_vpu_fpu_isFpToVecInst, io_enq_1_bits_payload_vpu_frm, io_enq_1_bits_payload_vpu_vstart, io_enq_1_bits_payload_vpu_vm, io_enq_1_bits_payload_vpu_specVlmul, io_enq_1_bits_payload_vpu_specVsew, io_enq_1_bits_payload_vpu_specVta, io_enq_1_bits_payload_vpu_specVma, io_enq_1_bits_payload_vpu_specVill, io_enq_1_bits_payload_vpu_vlmul, io_enq_1_bits_payload_vpu_vsew, io_enq_1_bits_payload_vpu_vta, io_enq_1_bits_payload_vpu_vma, io_enq_1_bits_payload_vpu_vill, io_enq_1_bits_payload_fpu_rm, io_enq_1_bits_payload_fpu_fmt, io_enq_1_bits_payload_fpu_typ, io_enq_1_bits_payload_fpu_wflags, io_enq_1_bits_payload_fpu_typeTagOut, io_enq_1_bits_payload_selImm, io_enq_1_bits_payload_v0Wen, io_enq_1_bits_payload_vecWen, io_enq_1_bits_payload_fuOpType};

  logic [0:0][740:0] deq_payload;
  logic [9:0][1:0] fu_type_narrow;
  logic [0:0][1:0] deq_fu_type;
  logic [0:0][4:0][6:0] deq_psrc;
  logic [0:0][4:0][3:0] deq_src_type;
  logic [0:0] deq_rob_flag;
  logic [0:0][7:0] deq_rob_value;
  logic [9:0][4:0][3:0] data_src;
  // 核的这几个出口：顶层有对应端口的接有名线（后面展开），没有的接悬空线
  logic [9:0][4:0][0:0] unused_exu_src;
  logic [9:0][2:0][1:0] unused_ld_dep;
  logic [0:0][4:0][2:0][1:0] unused_deq_ld_dep;
  logic [0:0][4:0][0:0] unused_deq_rc_idx;
  logic [0:0] unused_cancel_deq;

  xs_iq_entries_core #(
    .NUM_ENQ(2), .NUM_SIMP(2), .NUM_COMP(6), .NUM_DEQ(1),
    .NUM_REGSRC(5), .NUM_WK_WB(16), .NUM_FU_BIT(2),
    .ROB_W(8), .PSRC_W(7), .PDEST_W(8),
    .PL_DEQ_W(741), .PL_TRANS_W(1330),
    .HAS_LD_DEP(1), .COMP_HAS_LD_DEP(0),
    .HAS_LD_CANCEL(0), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(0), .EXU_W(1),
    .SRC_WB_MASK({16'b1111000000000000, 16'b0000111111000000, 16'b0000000000111111, 16'b0000000000111111, 16'b0000000000111111}),
    .SRC_MATCH_KIND({2'd2, 2'd1, 2'd0, 2'd0, 2'd0}),
    .WB_WEN_PRESENT(5'b11100),
    .WBD_WEN_PRESENT(5'b11100),
    .HAS_IGNORE_OLD_VD(1),
    .VD_SRC(2), .VL_SRC(4), .WB_VL_INT(12), .WB_VL_VF(13),
    .PLB_VM(41),
    .PLB_VMA(26),
    .PLB_VTA(27),
    .PLB_IS_DEPEND_OLDVD(209),
    .PLB_IS_WRITE_PARTVD(210),
    .OG_HAS_BITS(4'b0100),
    .OG_CONST_RESP({2'h0, 2'h0, 2'h1, 2'h0})
  ) u_core (
    .clock(clock), .reset(reset),
    .flush_valid(io_flush_valid), .flush_rob_flag(io_flush_bits_robIdx_flag),
    .flush_rob_value(io_flush_bits_robIdx_value), .flush_level(io_flush_bits_level),
    .enq_valid({io_enq_1_valid, io_enq_0_valid}),
    .enq_rob_flag({io_enq_1_bits_status_robIdx_flag, io_enq_0_bits_status_robIdx_flag}),
    .enq_rob_value({io_enq_1_bits_status_robIdx_value, io_enq_0_bits_status_robIdx_value}),
    .enq_fu_type({io_enq_1_bits_status_fuType_26, io_enq_1_bits_status_fuType_22, io_enq_0_bits_status_fuType_26, io_enq_0_bits_status_fuType_22}),
    .enq_psrc({io_enq_1_bits_status_srcStatus_4_psrc, io_enq_1_bits_status_srcStatus_3_psrc, io_enq_1_bits_status_srcStatus_2_psrc, io_enq_1_bits_status_srcStatus_1_psrc, io_enq_1_bits_status_srcStatus_0_psrc, io_enq_0_bits_status_srcStatus_4_psrc, io_enq_0_bits_status_srcStatus_3_psrc, io_enq_0_bits_status_srcStatus_2_psrc, io_enq_0_bits_status_srcStatus_1_psrc, io_enq_0_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_enq_1_bits_status_srcStatus_4_srcType, io_enq_1_bits_status_srcStatus_3_srcType, io_enq_1_bits_status_srcStatus_2_srcType, io_enq_1_bits_status_srcStatus_1_srcType, io_enq_1_bits_status_srcStatus_0_srcType, io_enq_0_bits_status_srcStatus_4_srcType, io_enq_0_bits_status_srcStatus_3_srcType, io_enq_0_bits_status_srcStatus_2_srcType, io_enq_0_bits_status_srcStatus_1_srcType, io_enq_0_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_enq_1_bits_status_srcStatus_4_srcState, io_enq_1_bits_status_srcStatus_3_srcState, io_enq_1_bits_status_srcStatus_2_srcState, io_enq_1_bits_status_srcStatus_1_srcState, io_enq_1_bits_status_srcStatus_0_srcState, io_enq_0_bits_status_srcStatus_4_srcState, io_enq_0_bits_status_srcStatus_3_srcState, io_enq_0_bits_status_srcStatus_2_srcState, io_enq_0_bits_status_srcStatus_1_srcState, io_enq_0_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_enq_1_bits_status_srcStatus_4_dataSources_value, io_enq_1_bits_status_srcStatus_3_dataSources_value, io_enq_1_bits_status_srcStatus_2_dataSources_value, io_enq_1_bits_status_srcStatus_1_dataSources_value, io_enq_1_bits_status_srcStatus_0_dataSources_value, io_enq_0_bits_status_srcStatus_4_dataSources_value, io_enq_0_bits_status_srcStatus_3_dataSources_value, io_enq_0_bits_status_srcStatus_2_dataSources_value, io_enq_0_bits_status_srcStatus_1_dataSources_value, io_enq_0_bits_status_srcStatus_0_dataSources_value}),
    .enq_payload(enq_payload),
    .enq_ld_dep('0), .enq_pl_ld_dep('0),
    .enq_use_rc('0), .enq_rc_idx('0),
    .iq_wen('0), .iq_pdest('0), .iq_ld_dep('0), .iq_rc_dest('0),
    .og0_cancel_sel('0), .iq_is0lat('0), .iqd_is0lat('0),
    .iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0),
    .ld1_cancel('0),
    .ld2_cancel('0),
    .wk_valid({io_wakeUpFromWB_15_valid, io_wakeUpFromWB_14_valid, io_wakeUpFromWB_13_valid, io_wakeUpFromWB_12_valid, io_wakeUpFromWB_11_valid, io_wakeUpFromWB_10_valid, io_wakeUpFromWB_9_valid, io_wakeUpFromWB_8_valid, io_wakeUpFromWB_7_valid, io_wakeUpFromWB_6_valid, io_wakeUpFromWB_5_valid, io_wakeUpFromWB_4_valid, io_wakeUpFromWB_3_valid, io_wakeUpFromWB_2_valid, io_wakeUpFromWB_1_valid, io_wakeUpFromWB_0_valid}),
    .wk_wen({{io_wakeUpFromWB_15_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {io_wakeUpFromWB_14_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {io_wakeUpFromWB_13_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {io_wakeUpFromWB_12_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWB_11_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWB_10_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWB_9_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWB_8_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWB_7_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWB_6_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWB_5_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWB_4_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWB_3_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWB_2_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWB_1_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWB_0_bits_vecWen, 1'b0, 1'b0}}),
    .wk_pdest({io_wakeUpFromWB_15_bits_pdest, io_wakeUpFromWB_14_bits_pdest, io_wakeUpFromWB_13_bits_pdest, io_wakeUpFromWB_12_bits_pdest, io_wakeUpFromWB_11_bits_pdest, io_wakeUpFromWB_10_bits_pdest, io_wakeUpFromWB_9_bits_pdest, io_wakeUpFromWB_8_bits_pdest, io_wakeUpFromWB_7_bits_pdest, io_wakeUpFromWB_6_bits_pdest, io_wakeUpFromWB_5_bits_pdest, io_wakeUpFromWB_4_bits_pdest, io_wakeUpFromWB_3_bits_pdest, io_wakeUpFromWB_2_bits_pdest, io_wakeUpFromWB_1_bits_pdest, io_wakeUpFromWB_0_bits_pdest}),
    .wkd_valid({io_wakeUpFromWBDelayed_15_valid, io_wakeUpFromWBDelayed_14_valid, io_wakeUpFromWBDelayed_13_valid, io_wakeUpFromWBDelayed_12_valid, io_wakeUpFromWBDelayed_11_valid, io_wakeUpFromWBDelayed_10_valid, io_wakeUpFromWBDelayed_9_valid, io_wakeUpFromWBDelayed_8_valid, io_wakeUpFromWBDelayed_7_valid, io_wakeUpFromWBDelayed_6_valid, io_wakeUpFromWBDelayed_5_valid, io_wakeUpFromWBDelayed_4_valid, io_wakeUpFromWBDelayed_3_valid, io_wakeUpFromWBDelayed_2_valid, io_wakeUpFromWBDelayed_1_valid, io_wakeUpFromWBDelayed_0_valid}),
    .wkd_wen({{io_wakeUpFromWBDelayed_15_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {io_wakeUpFromWBDelayed_14_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {io_wakeUpFromWBDelayed_13_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {io_wakeUpFromWBDelayed_12_bits_vlWen, 1'b0, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWBDelayed_11_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWBDelayed_10_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWBDelayed_9_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWBDelayed_8_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWBDelayed_7_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, io_wakeUpFromWBDelayed_6_bits_v0Wen, 1'b0, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWBDelayed_5_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWBDelayed_4_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWBDelayed_3_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWBDelayed_2_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWBDelayed_1_bits_vecWen, 1'b0, 1'b0}, {1'b0, 1'b0, io_wakeUpFromWBDelayed_0_bits_vecWen, 1'b0, 1'b0}}),
    .wkd_pdest({io_wakeUpFromWBDelayed_15_bits_pdest, io_wakeUpFromWBDelayed_14_bits_pdest, io_wakeUpFromWBDelayed_13_bits_pdest, io_wakeUpFromWBDelayed_12_bits_pdest, io_wakeUpFromWBDelayed_11_bits_pdest, io_wakeUpFromWBDelayed_10_bits_pdest, io_wakeUpFromWBDelayed_9_bits_pdest, io_wakeUpFromWBDelayed_8_bits_pdest, io_wakeUpFromWBDelayed_7_bits_pdest, io_wakeUpFromWBDelayed_6_bits_pdest, io_wakeUpFromWBDelayed_5_bits_pdest, io_wakeUpFromWBDelayed_4_bits_pdest, io_wakeUpFromWBDelayed_3_bits_pdest, io_wakeUpFromWBDelayed_2_bits_pdest, io_wakeUpFromWBDelayed_1_bits_pdest, io_wakeUpFromWBDelayed_0_bits_pdest}),
    .vl_int_is_zero(io_vlFromIntIsZero), .vl_int_is_vlmax(io_vlFromIntIsVlmax),
    .vl_vf_is_zero(io_vlFromVfIsZero), .vl_vf_is_vlmax(io_vlFromVfIsVlmax),
    .og_valid({{io_og2Resp_0_valid}, {io_og1Resp_0_valid}, {io_og0Resp_0_valid}}),
    .og_resp({{io_og2Resp_0_bits_resp}, 2'h0, 2'h0}),
    .deq_ready({io_deqReady_0}),
    .deq_sel_oh_valid({io_deqSelOH_0_valid}),
    .deq_sel_oh({io_deqSelOH_0_bits}),
    .enq_oldest_sel({io_enqEntryOldestSel_0_bits}),
    .simp_oldest_valid({io_simpEntryOldestSel_0_valid}),
    .simp_oldest_sel({io_simpEntryOldestSel_0_bits}),
    .comp_oldest_valid({io_compEntryOldestSel_0_valid}),
    .comp_oldest_sel({io_compEntryOldestSel_0_bits}),
    .simp_deq_sel_vec({io_simpEntryDeqSelVec_1, io_simpEntryDeqSelVec_0}),
    .o_valid(io_valid), .o_issued(io_issued), .o_can_issue(io_canIssue),
    .o_exu_src(unused_exu_src), .o_ld_dep(unused_ld_dep),
    .o_deq_ld_dep(unused_deq_ld_dep), .o_deq_rc_idx(unused_deq_rc_idx),
    .o_cancel_deq(unused_cancel_deq),
    .o_fu_type(fu_type_narrow), .o_data_src(data_src),
    .o_is_first_issue({io_isFirstIssue_0}),
    .o_deq_rob_flag(deq_rob_flag), .o_deq_rob_value(deq_rob_value),
    .o_deq_fu_type(deq_fu_type), .o_deq_psrc(deq_psrc),
    .o_deq_src_type(deq_src_type), .o_deq_payload(deq_payload),
    .o_simp_enq_sel_vec({io_simpEntryEnqSelVec_1, io_simpEntryEnqSelVec_0}),
    .o_comp_enq_sel_vec({io_compEntryEnqSelVec_1, io_compEntryEnqSelVec_0})
  );

  // fuType 输出：核只存本变体保留的 2 位，这里放回 35 位 one-hot 的原位置
  assign io_fuType_0 = {8'h0, fu_type_narrow[0][1], 3'h0, fu_type_narrow[0][0], 22'h0};
  assign io_fuType_1 = {8'h0, fu_type_narrow[1][1], 3'h0, fu_type_narrow[1][0], 22'h0};
  assign io_fuType_2 = {8'h0, fu_type_narrow[2][1], 3'h0, fu_type_narrow[2][0], 22'h0};
  assign io_fuType_3 = {8'h0, fu_type_narrow[3][1], 3'h0, fu_type_narrow[3][0], 22'h0};
  assign io_fuType_4 = {8'h0, fu_type_narrow[4][1], 3'h0, fu_type_narrow[4][0], 22'h0};
  assign io_fuType_5 = {8'h0, fu_type_narrow[5][1], 3'h0, fu_type_narrow[5][0], 22'h0};
  assign io_fuType_6 = {8'h0, fu_type_narrow[6][1], 3'h0, fu_type_narrow[6][0], 22'h0};
  assign io_fuType_7 = {8'h0, fu_type_narrow[7][1], 3'h0, fu_type_narrow[7][0], 22'h0};
  assign io_fuType_8 = {8'h0, fu_type_narrow[8][1], 3'h0, fu_type_narrow[8][0], 22'h0};
  assign io_fuType_9 = {8'h0, fu_type_narrow[9][1], 3'h0, fu_type_narrow[9][0], 22'h0};

  assign io_dataSources_0_0_value = data_src[0][0];
  assign io_dataSources_0_1_value = data_src[0][1];
  assign io_dataSources_0_2_value = data_src[0][2];
  assign io_dataSources_0_3_value = data_src[0][3];
  assign io_dataSources_0_4_value = data_src[0][4];
  assign io_dataSources_1_0_value = data_src[1][0];
  assign io_dataSources_1_1_value = data_src[1][1];
  assign io_dataSources_1_2_value = data_src[1][2];
  assign io_dataSources_1_3_value = data_src[1][3];
  assign io_dataSources_1_4_value = data_src[1][4];
  assign io_dataSources_2_0_value = data_src[2][0];
  assign io_dataSources_2_1_value = data_src[2][1];
  assign io_dataSources_2_2_value = data_src[2][2];
  assign io_dataSources_2_3_value = data_src[2][3];
  assign io_dataSources_2_4_value = data_src[2][4];
  assign io_dataSources_3_0_value = data_src[3][0];
  assign io_dataSources_3_1_value = data_src[3][1];
  assign io_dataSources_3_2_value = data_src[3][2];
  assign io_dataSources_3_3_value = data_src[3][3];
  assign io_dataSources_3_4_value = data_src[3][4];
  assign io_dataSources_4_0_value = data_src[4][0];
  assign io_dataSources_4_1_value = data_src[4][1];
  assign io_dataSources_4_2_value = data_src[4][2];
  assign io_dataSources_4_3_value = data_src[4][3];
  assign io_dataSources_4_4_value = data_src[4][4];
  assign io_dataSources_5_0_value = data_src[5][0];
  assign io_dataSources_5_1_value = data_src[5][1];
  assign io_dataSources_5_2_value = data_src[5][2];
  assign io_dataSources_5_3_value = data_src[5][3];
  assign io_dataSources_5_4_value = data_src[5][4];
  assign io_dataSources_6_0_value = data_src[6][0];
  assign io_dataSources_6_1_value = data_src[6][1];
  assign io_dataSources_6_2_value = data_src[6][2];
  assign io_dataSources_6_3_value = data_src[6][3];
  assign io_dataSources_6_4_value = data_src[6][4];
  assign io_dataSources_7_0_value = data_src[7][0];
  assign io_dataSources_7_1_value = data_src[7][1];
  assign io_dataSources_7_2_value = data_src[7][2];
  assign io_dataSources_7_3_value = data_src[7][3];
  assign io_dataSources_7_4_value = data_src[7][4];
  assign io_dataSources_8_0_value = data_src[8][0];
  assign io_dataSources_8_1_value = data_src[8][1];
  assign io_dataSources_8_2_value = data_src[8][2];
  assign io_dataSources_8_3_value = data_src[8][3];
  assign io_dataSources_8_4_value = data_src[8][4];
  assign io_dataSources_9_0_value = data_src[9][0];
  assign io_dataSources_9_1_value = data_src[9][1];
  assign io_dataSources_9_2_value = data_src[9][2];
  assign io_dataSources_9_3_value = data_src[9][3];
  assign io_dataSources_9_4_value = data_src[9][4];

  assign io_deqEntry_0_bits_status_robIdx_flag  = deq_rob_flag[0];
  assign io_deqEntry_0_bits_status_robIdx_value = deq_rob_value[0];
  assign io_deqEntry_0_bits_status_fuType_22 = deq_fu_type[0][0];
  assign io_deqEntry_0_bits_status_fuType_26 = deq_fu_type[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_0_psrc    = deq_psrc[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_0_srcType = deq_src_type[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_1_psrc    = deq_psrc[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_1_srcType = deq_src_type[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_2_psrc    = deq_psrc[0][2];
  assign io_deqEntry_0_bits_status_srcStatus_2_srcType = deq_src_type[0][2];
  assign io_deqEntry_0_bits_status_srcStatus_3_psrc    = deq_psrc[0][3];
  assign io_deqEntry_0_bits_status_srcStatus_3_srcType = deq_src_type[0][3];
  assign io_deqEntry_0_bits_status_srcStatus_4_psrc    = deq_psrc[0][4];
  assign io_deqEntry_0_bits_status_srcStatus_4_srcType = deq_src_type[0][4];
  assign io_deqEntry_0_bits_payload_fuOpType = deq_payload[0][8:0];
  assign io_deqEntry_0_bits_payload_vecWen = deq_payload[0][9];
  assign io_deqEntry_0_bits_payload_v0Wen = deq_payload[0][10];
  assign io_deqEntry_0_bits_payload_selImm = deq_payload[0][14:11];
  assign io_deqEntry_0_bits_payload_fpu_typeTagOut = deq_payload[0][16:15];
  assign io_deqEntry_0_bits_payload_fpu_wflags = deq_payload[0][17];
  assign io_deqEntry_0_bits_payload_fpu_typ = deq_payload[0][19:18];
  assign io_deqEntry_0_bits_payload_fpu_fmt = deq_payload[0][21:20];
  assign io_deqEntry_0_bits_payload_fpu_rm = deq_payload[0][24:22];
  assign io_deqEntry_0_bits_payload_vpu_vill = deq_payload[0][25];
  assign io_deqEntry_0_bits_payload_vpu_vma = deq_payload[0][26];
  assign io_deqEntry_0_bits_payload_vpu_vta = deq_payload[0][27];
  assign io_deqEntry_0_bits_payload_vpu_vsew = deq_payload[0][29:28];
  assign io_deqEntry_0_bits_payload_vpu_vlmul = deq_payload[0][32:30];
  assign io_deqEntry_0_bits_payload_vpu_specVill = deq_payload[0][33];
  assign io_deqEntry_0_bits_payload_vpu_specVma = deq_payload[0][34];
  assign io_deqEntry_0_bits_payload_vpu_specVta = deq_payload[0][35];
  assign io_deqEntry_0_bits_payload_vpu_specVsew = deq_payload[0][37:36];
  assign io_deqEntry_0_bits_payload_vpu_specVlmul = deq_payload[0][40:38];
  assign io_deqEntry_0_bits_payload_vpu_vm = deq_payload[0][41];
  assign io_deqEntry_0_bits_payload_vpu_vstart = deq_payload[0][49:42];
  assign io_deqEntry_0_bits_payload_vpu_frm = deq_payload[0][52:50];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst = deq_payload[0][53];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr = deq_payload[0][54];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr = deq_payload[0][55];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isReduction = deq_payload[0][56];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2 = deq_payload[0][57];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4 = deq_payload[0][58];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8 = deq_payload[0][59];
  assign io_deqEntry_0_bits_payload_vpu_vxrm = deq_payload[0][61:60];
  assign io_deqEntry_0_bits_payload_vpu_vmask = deq_payload[0][189:62];
  assign io_deqEntry_0_bits_payload_vpu_vl = deq_payload[0][197:190];
  assign io_deqEntry_0_bits_payload_vpu_nf = deq_payload[0][200:198];
  assign io_deqEntry_0_bits_payload_vpu_veew = deq_payload[0][202:201];
  assign io_deqEntry_0_bits_payload_vpu_isReverse = deq_payload[0][203];
  assign io_deqEntry_0_bits_payload_vpu_isExt = deq_payload[0][204];
  assign io_deqEntry_0_bits_payload_vpu_isNarrow = deq_payload[0][205];
  assign io_deqEntry_0_bits_payload_vpu_isDstMask = deq_payload[0][206];
  assign io_deqEntry_0_bits_payload_vpu_isOpMask = deq_payload[0][207];
  assign io_deqEntry_0_bits_payload_vpu_isMove = deq_payload[0][208];
  assign io_deqEntry_0_bits_payload_vpu_isDependOldVd = deq_payload[0][209];
  assign io_deqEntry_0_bits_payload_vpu_isWritePartVd = deq_payload[0][210];
  assign io_deqEntry_0_bits_payload_vpu_isVleff = deq_payload[0][211];
  assign io_deqEntry_0_bits_payload_uopIdx = deq_payload[0][218:212];
  assign io_deqEntry_0_bits_payload_lastUop = deq_payload[0][219];
  assign io_deqEntry_0_bits_payload_pdest = deq_payload[0][227:220];
  assign io_deqEntry_0_bits_payload_debugInfo_eliminatedMove = deq_payload[0][228];
  assign io_deqEntry_0_bits_payload_debugInfo_renameTime = deq_payload[0][292:229];
  assign io_deqEntry_0_bits_payload_debugInfo_dispatchTime = deq_payload[0][356:293];
  assign io_deqEntry_0_bits_payload_debugInfo_enqRsTime = deq_payload[0][420:357];
  assign io_deqEntry_0_bits_payload_debugInfo_writebackTime = deq_payload[0][484:421];
  assign io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id = deq_payload[0][548:485];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime = deq_payload[0][612:549];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbRespTime = deq_payload[0][676:613];
  assign io_deqEntry_0_bits_payload_debug_seqNum_seqNum = deq_payload[0][732:677];
  assign io_deqEntry_0_bits_payload_debug_seqNum_uopIdx = deq_payload[0][740:733];
  // END GENERATED(core-inst)

endmodule
