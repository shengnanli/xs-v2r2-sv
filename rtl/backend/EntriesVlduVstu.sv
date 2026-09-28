// EntriesVlduVstu.sv —— 发射队列条目阵列（VlduVstu 变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv（Entries* 家族共享参数化核，本文件不含逻辑分支，
// 只把 golden 的扁平端口打包成核的数组/位向量接口，并给出本变体的参数）。
//
// 本变体规模（全部从 G1 golden EntriesVlduVstu.sv 机械量得）：
//   条目 16 = enq 2 + simp 2 + comp 12，发射口 1，源寄存器 5 个
//   WB 唤醒 16 路（无 IQ 唤醒、无 og0Cancel、无 ldCancel）
//   保留的 FuType one-hot 位：FuType[31], FuType[32]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位（comp 段没有：整条通路是死的）
//   issueResp 4 档（按 issueTimer）：timer0=真 resp, timer1=真 resp, timer2=真 resp, timer3=常量 2'h0
//   needFeedBack：MEM_RESP_MODE=2，访存响应来源 vecLdIn_resp_0 / fromMem_slowResp_0 / vecLdIn_finalIssueResp_0（issueTimer==3 时各路按位或，按 sqIdx 与 lqIdx 同时命中）
//   访存向量状态组：vecMem = {numLsElem 5, lqIdx 8, sqIdx 7} 位，vecReplayMask 16 位 / MbIdx 4 位，blocked 为真逻辑（三种条目都有）
//   负载：发射口可见 60 个字段 / 759 位；转移包另带 120 个字段，共 1330 位
//   golden 层次：EnqEntryVecMem_2 ×2 + OthersEntryVecMem_14 ×2 + OthersEntryVecMem_16 ×12 + EnqPolicy_14 ×2，本文件把它们一并扁平化。
//
// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：
//   src0: WB[0..15]，匹配 srcType[0]&rfWen | srcType[1]&fpWen | srcType[2]&vecWen
//   src1: WB[0..15]，匹配 srcType[0]&rfWen | srcType[1]&fpWen | srcType[2]&vecWen
//   src2: WB[0..15]，匹配 srcType[0]&rfWen | srcType[1]&fpWen | srcType[2]&vecWen
//   src3: WB[0..15]，匹配 srcType[3]&v0Wen
//   src4: WB[0..15]，匹配 srcType[2]&vlWen
//
// 自动生成：verif/ut/EntriesVlduVstu/gen.py（共享库 verif/ut/Entries_common/entries_gen.py）—— 勿手改
// =============================================================================
module EntriesVlduVstu (
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  input          io_enq_0_valid,
  input          io_enq_0_bits_status_robIdx_flag,
  input  [7:0]   io_enq_0_bits_status_robIdx_value,
  input          io_enq_0_bits_status_fuType_31,
  input          io_enq_0_bits_status_fuType_32,
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
  input          io_enq_0_bits_status_blocked,
  input          io_enq_0_bits_status_vecMem_sqIdx_flag,
  input  [5:0]   io_enq_0_bits_status_vecMem_sqIdx_value,
  input          io_enq_0_bits_status_vecMem_lqIdx_flag,
  input  [6:0]   io_enq_0_bits_status_vecMem_lqIdx_value,
  input  [4:0]   io_enq_0_bits_status_vecMem_numLsElem,
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
  input          io_enq_1_bits_status_fuType_31,
  input          io_enq_1_bits_status_fuType_32,
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
  input          io_enq_1_bits_status_blocked,
  input          io_enq_1_bits_status_vecMem_sqIdx_flag,
  input  [5:0]   io_enq_1_bits_status_vecMem_sqIdx_value,
  input          io_enq_1_bits_status_vecMem_lqIdx_flag,
  input  [6:0]   io_enq_1_bits_status_vecMem_lqIdx_value,
  input  [4:0]   io_enq_1_bits_status_vecMem_numLsElem,
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
  input  [1:0]   io_og0Resp_0_bits_resp,
  input          io_og0Resp_0_bits_isVecPartReplay,
  input  [15:0]  io_og0Resp_0_bits_vecReplayMask,
  input  [3:0]   io_og0Resp_0_bits_vecReplayMbIdx,
  input          io_og1Resp_0_valid,
  input  [1:0]   io_og1Resp_0_bits_resp,
  input          io_og1Resp_0_bits_isVecPartReplay,
  input  [15:0]  io_og1Resp_0_bits_vecReplayMask,
  input  [3:0]   io_og1Resp_0_bits_vecReplayMbIdx,
  input          io_og2Resp_0_valid,
  input  [1:0]   io_og2Resp_0_bits_resp,
  input          io_og2Resp_0_bits_isVecPartReplay,
  input  [15:0]  io_og2Resp_0_bits_vecReplayMask,
  input  [3:0]   io_og2Resp_0_bits_vecReplayMbIdx,
  input          io_deqReady_0,
  input          io_deqSelOH_0_valid,
  input  [15:0]  io_deqSelOH_0_bits,
  input  [1:0]   io_enqEntryOldestSel_0_bits,
  input          io_simpEntryOldestSel_0_valid,
  input  [1:0]   io_simpEntryOldestSel_0_bits,
  input          io_compEntryOldestSel_0_valid,
  input  [11:0]  io_compEntryOldestSel_0_bits,
  input          io_wakeUpFromWB_15_valid,
  input          io_wakeUpFromWB_15_bits_rfWen,
  input          io_wakeUpFromWB_15_bits_fpWen,
  input          io_wakeUpFromWB_15_bits_vecWen,
  input          io_wakeUpFromWB_15_bits_v0Wen,
  input          io_wakeUpFromWB_15_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_15_bits_pdest,
  input          io_wakeUpFromWB_14_valid,
  input          io_wakeUpFromWB_14_bits_rfWen,
  input          io_wakeUpFromWB_14_bits_fpWen,
  input          io_wakeUpFromWB_14_bits_vecWen,
  input          io_wakeUpFromWB_14_bits_v0Wen,
  input          io_wakeUpFromWB_14_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_14_bits_pdest,
  input          io_wakeUpFromWB_13_valid,
  input          io_wakeUpFromWB_13_bits_rfWen,
  input          io_wakeUpFromWB_13_bits_fpWen,
  input          io_wakeUpFromWB_13_bits_vecWen,
  input          io_wakeUpFromWB_13_bits_v0Wen,
  input          io_wakeUpFromWB_13_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_13_bits_pdest,
  input          io_wakeUpFromWB_12_valid,
  input          io_wakeUpFromWB_12_bits_rfWen,
  input          io_wakeUpFromWB_12_bits_fpWen,
  input          io_wakeUpFromWB_12_bits_vecWen,
  input          io_wakeUpFromWB_12_bits_v0Wen,
  input          io_wakeUpFromWB_12_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_12_bits_pdest,
  input          io_wakeUpFromWB_11_valid,
  input          io_wakeUpFromWB_11_bits_rfWen,
  input          io_wakeUpFromWB_11_bits_fpWen,
  input          io_wakeUpFromWB_11_bits_vecWen,
  input          io_wakeUpFromWB_11_bits_v0Wen,
  input          io_wakeUpFromWB_11_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_11_bits_pdest,
  input          io_wakeUpFromWB_10_valid,
  input          io_wakeUpFromWB_10_bits_rfWen,
  input          io_wakeUpFromWB_10_bits_fpWen,
  input          io_wakeUpFromWB_10_bits_vecWen,
  input          io_wakeUpFromWB_10_bits_v0Wen,
  input          io_wakeUpFromWB_10_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_10_bits_pdest,
  input          io_wakeUpFromWB_9_valid,
  input          io_wakeUpFromWB_9_bits_rfWen,
  input          io_wakeUpFromWB_9_bits_fpWen,
  input          io_wakeUpFromWB_9_bits_vecWen,
  input          io_wakeUpFromWB_9_bits_v0Wen,
  input          io_wakeUpFromWB_9_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_9_bits_pdest,
  input          io_wakeUpFromWB_8_valid,
  input          io_wakeUpFromWB_8_bits_rfWen,
  input          io_wakeUpFromWB_8_bits_fpWen,
  input          io_wakeUpFromWB_8_bits_vecWen,
  input          io_wakeUpFromWB_8_bits_v0Wen,
  input          io_wakeUpFromWB_8_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_8_bits_pdest,
  input          io_wakeUpFromWB_7_valid,
  input          io_wakeUpFromWB_7_bits_rfWen,
  input          io_wakeUpFromWB_7_bits_fpWen,
  input          io_wakeUpFromWB_7_bits_vecWen,
  input          io_wakeUpFromWB_7_bits_v0Wen,
  input          io_wakeUpFromWB_7_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_7_bits_pdest,
  input          io_wakeUpFromWB_6_valid,
  input          io_wakeUpFromWB_6_bits_rfWen,
  input          io_wakeUpFromWB_6_bits_fpWen,
  input          io_wakeUpFromWB_6_bits_vecWen,
  input          io_wakeUpFromWB_6_bits_v0Wen,
  input          io_wakeUpFromWB_6_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_6_bits_pdest,
  input          io_wakeUpFromWB_5_valid,
  input          io_wakeUpFromWB_5_bits_rfWen,
  input          io_wakeUpFromWB_5_bits_fpWen,
  input          io_wakeUpFromWB_5_bits_vecWen,
  input          io_wakeUpFromWB_5_bits_v0Wen,
  input          io_wakeUpFromWB_5_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_5_bits_pdest,
  input          io_wakeUpFromWB_4_valid,
  input          io_wakeUpFromWB_4_bits_rfWen,
  input          io_wakeUpFromWB_4_bits_fpWen,
  input          io_wakeUpFromWB_4_bits_vecWen,
  input          io_wakeUpFromWB_4_bits_v0Wen,
  input          io_wakeUpFromWB_4_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_4_bits_pdest,
  input          io_wakeUpFromWB_3_valid,
  input          io_wakeUpFromWB_3_bits_rfWen,
  input          io_wakeUpFromWB_3_bits_fpWen,
  input          io_wakeUpFromWB_3_bits_vecWen,
  input          io_wakeUpFromWB_3_bits_v0Wen,
  input          io_wakeUpFromWB_3_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_3_bits_pdest,
  input          io_wakeUpFromWB_2_valid,
  input          io_wakeUpFromWB_2_bits_rfWen,
  input          io_wakeUpFromWB_2_bits_fpWen,
  input          io_wakeUpFromWB_2_bits_vecWen,
  input          io_wakeUpFromWB_2_bits_v0Wen,
  input          io_wakeUpFromWB_2_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_2_bits_pdest,
  input          io_wakeUpFromWB_1_valid,
  input          io_wakeUpFromWB_1_bits_rfWen,
  input          io_wakeUpFromWB_1_bits_fpWen,
  input          io_wakeUpFromWB_1_bits_vecWen,
  input          io_wakeUpFromWB_1_bits_v0Wen,
  input          io_wakeUpFromWB_1_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_1_bits_pdest,
  input          io_wakeUpFromWB_0_valid,
  input          io_wakeUpFromWB_0_bits_rfWen,
  input          io_wakeUpFromWB_0_bits_fpWen,
  input          io_wakeUpFromWB_0_bits_vecWen,
  input          io_wakeUpFromWB_0_bits_v0Wen,
  input          io_wakeUpFromWB_0_bits_vlWen,
  input  [7:0]   io_wakeUpFromWB_0_bits_pdest,
  input          io_wakeUpFromWBDelayed_15_valid,
  input          io_wakeUpFromWBDelayed_15_bits_rfWen,
  input          io_wakeUpFromWBDelayed_15_bits_fpWen,
  input          io_wakeUpFromWBDelayed_15_bits_vecWen,
  input          io_wakeUpFromWBDelayed_15_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_15_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_15_bits_pdest,
  input          io_wakeUpFromWBDelayed_14_valid,
  input          io_wakeUpFromWBDelayed_14_bits_rfWen,
  input          io_wakeUpFromWBDelayed_14_bits_fpWen,
  input          io_wakeUpFromWBDelayed_14_bits_vecWen,
  input          io_wakeUpFromWBDelayed_14_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_14_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_14_bits_pdest,
  input          io_wakeUpFromWBDelayed_13_valid,
  input          io_wakeUpFromWBDelayed_13_bits_rfWen,
  input          io_wakeUpFromWBDelayed_13_bits_fpWen,
  input          io_wakeUpFromWBDelayed_13_bits_vecWen,
  input          io_wakeUpFromWBDelayed_13_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_13_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_13_bits_pdest,
  input          io_wakeUpFromWBDelayed_12_valid,
  input          io_wakeUpFromWBDelayed_12_bits_rfWen,
  input          io_wakeUpFromWBDelayed_12_bits_fpWen,
  input          io_wakeUpFromWBDelayed_12_bits_vecWen,
  input          io_wakeUpFromWBDelayed_12_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_12_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_12_bits_pdest,
  input          io_wakeUpFromWBDelayed_11_valid,
  input          io_wakeUpFromWBDelayed_11_bits_rfWen,
  input          io_wakeUpFromWBDelayed_11_bits_fpWen,
  input          io_wakeUpFromWBDelayed_11_bits_vecWen,
  input          io_wakeUpFromWBDelayed_11_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_11_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_11_bits_pdest,
  input          io_wakeUpFromWBDelayed_10_valid,
  input          io_wakeUpFromWBDelayed_10_bits_rfWen,
  input          io_wakeUpFromWBDelayed_10_bits_fpWen,
  input          io_wakeUpFromWBDelayed_10_bits_vecWen,
  input          io_wakeUpFromWBDelayed_10_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_10_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_10_bits_pdest,
  input          io_wakeUpFromWBDelayed_9_valid,
  input          io_wakeUpFromWBDelayed_9_bits_rfWen,
  input          io_wakeUpFromWBDelayed_9_bits_fpWen,
  input          io_wakeUpFromWBDelayed_9_bits_vecWen,
  input          io_wakeUpFromWBDelayed_9_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_9_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_9_bits_pdest,
  input          io_wakeUpFromWBDelayed_8_valid,
  input          io_wakeUpFromWBDelayed_8_bits_rfWen,
  input          io_wakeUpFromWBDelayed_8_bits_fpWen,
  input          io_wakeUpFromWBDelayed_8_bits_vecWen,
  input          io_wakeUpFromWBDelayed_8_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_8_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_8_bits_pdest,
  input          io_wakeUpFromWBDelayed_7_valid,
  input          io_wakeUpFromWBDelayed_7_bits_rfWen,
  input          io_wakeUpFromWBDelayed_7_bits_fpWen,
  input          io_wakeUpFromWBDelayed_7_bits_vecWen,
  input          io_wakeUpFromWBDelayed_7_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_7_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_7_bits_pdest,
  input          io_wakeUpFromWBDelayed_6_valid,
  input          io_wakeUpFromWBDelayed_6_bits_rfWen,
  input          io_wakeUpFromWBDelayed_6_bits_fpWen,
  input          io_wakeUpFromWBDelayed_6_bits_vecWen,
  input          io_wakeUpFromWBDelayed_6_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_6_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_6_bits_pdest,
  input          io_wakeUpFromWBDelayed_5_valid,
  input          io_wakeUpFromWBDelayed_5_bits_rfWen,
  input          io_wakeUpFromWBDelayed_5_bits_fpWen,
  input          io_wakeUpFromWBDelayed_5_bits_vecWen,
  input          io_wakeUpFromWBDelayed_5_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_5_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_5_bits_pdest,
  input          io_wakeUpFromWBDelayed_4_valid,
  input          io_wakeUpFromWBDelayed_4_bits_rfWen,
  input          io_wakeUpFromWBDelayed_4_bits_fpWen,
  input          io_wakeUpFromWBDelayed_4_bits_vecWen,
  input          io_wakeUpFromWBDelayed_4_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_4_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_4_bits_pdest,
  input          io_wakeUpFromWBDelayed_3_valid,
  input          io_wakeUpFromWBDelayed_3_bits_rfWen,
  input          io_wakeUpFromWBDelayed_3_bits_fpWen,
  input          io_wakeUpFromWBDelayed_3_bits_vecWen,
  input          io_wakeUpFromWBDelayed_3_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_3_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_3_bits_pdest,
  input          io_wakeUpFromWBDelayed_2_valid,
  input          io_wakeUpFromWBDelayed_2_bits_rfWen,
  input          io_wakeUpFromWBDelayed_2_bits_fpWen,
  input          io_wakeUpFromWBDelayed_2_bits_vecWen,
  input          io_wakeUpFromWBDelayed_2_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_2_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_2_bits_pdest,
  input          io_wakeUpFromWBDelayed_1_valid,
  input          io_wakeUpFromWBDelayed_1_bits_rfWen,
  input          io_wakeUpFromWBDelayed_1_bits_fpWen,
  input          io_wakeUpFromWBDelayed_1_bits_vecWen,
  input          io_wakeUpFromWBDelayed_1_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_1_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_1_bits_pdest,
  input          io_wakeUpFromWBDelayed_0_valid,
  input          io_wakeUpFromWBDelayed_0_bits_rfWen,
  input          io_wakeUpFromWBDelayed_0_bits_fpWen,
  input          io_wakeUpFromWBDelayed_0_bits_vecWen,
  input          io_wakeUpFromWBDelayed_0_bits_v0Wen,
  input          io_wakeUpFromWBDelayed_0_bits_vlWen,
  input  [7:0]   io_wakeUpFromWBDelayed_0_bits_pdest,
  input          io_vlFromIntIsZero,
  input          io_vlFromIntIsVlmax,
  input          io_vlFromVfIsZero,
  input          io_vlFromVfIsVlmax,
  output [15:0]  io_valid,
  output [15:0]  io_issued,
  output [15:0]  io_canIssue,
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
  output [34:0]  io_fuType_10,
  output [34:0]  io_fuType_11,
  output [34:0]  io_fuType_12,
  output [34:0]  io_fuType_13,
  output [34:0]  io_fuType_14,
  output [34:0]  io_fuType_15,
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
  output [3:0]   io_dataSources_10_0_value,
  output [3:0]   io_dataSources_10_1_value,
  output [3:0]   io_dataSources_10_2_value,
  output [3:0]   io_dataSources_10_3_value,
  output [3:0]   io_dataSources_10_4_value,
  output [3:0]   io_dataSources_11_0_value,
  output [3:0]   io_dataSources_11_1_value,
  output [3:0]   io_dataSources_11_2_value,
  output [3:0]   io_dataSources_11_3_value,
  output [3:0]   io_dataSources_11_4_value,
  output [3:0]   io_dataSources_12_0_value,
  output [3:0]   io_dataSources_12_1_value,
  output [3:0]   io_dataSources_12_2_value,
  output [3:0]   io_dataSources_12_3_value,
  output [3:0]   io_dataSources_12_4_value,
  output [3:0]   io_dataSources_13_0_value,
  output [3:0]   io_dataSources_13_1_value,
  output [3:0]   io_dataSources_13_2_value,
  output [3:0]   io_dataSources_13_3_value,
  output [3:0]   io_dataSources_13_4_value,
  output [3:0]   io_dataSources_14_0_value,
  output [3:0]   io_dataSources_14_1_value,
  output [3:0]   io_dataSources_14_2_value,
  output [3:0]   io_dataSources_14_3_value,
  output [3:0]   io_dataSources_14_4_value,
  output [3:0]   io_dataSources_15_0_value,
  output [3:0]   io_dataSources_15_1_value,
  output [3:0]   io_dataSources_15_2_value,
  output [3:0]   io_dataSources_15_3_value,
  output [3:0]   io_dataSources_15_4_value,
  output         io_isFirstIssue_0,
  output         io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0]   io_deqEntry_0_bits_status_robIdx_value,
  output         io_deqEntry_0_bits_status_fuType_31,
  output         io_deqEntry_0_bits_status_fuType_32,
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
  output         io_deqEntry_0_bits_status_vecMem_sqIdx_flag,
  output [5:0]   io_deqEntry_0_bits_status_vecMem_sqIdx_value,
  output         io_deqEntry_0_bits_status_vecMem_lqIdx_flag,
  output [6:0]   io_deqEntry_0_bits_status_vecMem_lqIdx_value,
  output [4:0]   io_deqEntry_0_bits_status_vecMem_numLsElem,
  output         io_deqEntry_0_bits_status_isVecPartReplay,
  output [15:0]  io_deqEntry_0_bits_status_vecReplayMask,
  output [3:0]   io_deqEntry_0_bits_status_vecReplayMbIdx,
  output         io_deqEntry_0_bits_payload_ftqPtr_flag,
  output [5:0]   io_deqEntry_0_bits_payload_ftqPtr_value,
  output [3:0]   io_deqEntry_0_bits_payload_ftqOffset,
  output [8:0]   io_deqEntry_0_bits_payload_fuOpType,
  output         io_deqEntry_0_bits_payload_vecWen,
  output         io_deqEntry_0_bits_payload_v0Wen,
  output         io_deqEntry_0_bits_payload_vlWen,
  output         io_deqEntry_0_bits_payload_flushPipe,
  output [3:0]   io_deqEntry_0_bits_payload_selImm,
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
  input          io_fromMem_slowResp_0_valid,
  input  [1:0]   io_fromMem_slowResp_0_bits_resp,
  input          io_fromMem_slowResp_0_bits_sqIdx_flag,
  input  [5:0]   io_fromMem_slowResp_0_bits_sqIdx_value,
  input          io_fromMem_slowResp_0_bits_lqIdx_flag,
  input  [6:0]   io_fromMem_slowResp_0_bits_lqIdx_value,
  input          io_fromMem_slowResp_0_bits_isVecPartReplay,
  input  [15:0]  io_fromMem_slowResp_0_bits_vecReplayMask,
  input  [3:0]   io_fromMem_slowResp_0_bits_vecReplayMbIdx,
  input          io_vecMemIn_lqDeqPtr_flag,
  input  [6:0]   io_vecMemIn_lqDeqPtr_value,
  input          io_vecLdIn_finalIssueResp_0_valid,
  input          io_vecLdIn_finalIssueResp_0_bits_robIdx_flag,
  input  [7:0]   io_vecLdIn_finalIssueResp_0_bits_robIdx_value,
  input  [1:0]   io_vecLdIn_finalIssueResp_0_bits_resp,
  input  [34:0]  io_vecLdIn_finalIssueResp_0_bits_fuType,
  input  [6:0]   io_vecLdIn_finalIssueResp_0_bits_uopIdx,
  input          io_vecLdIn_finalIssueResp_0_bits_sqIdx_flag,
  input  [5:0]   io_vecLdIn_finalIssueResp_0_bits_sqIdx_value,
  input          io_vecLdIn_finalIssueResp_0_bits_lqIdx_flag,
  input  [6:0]   io_vecLdIn_finalIssueResp_0_bits_lqIdx_value,
  input          io_vecLdIn_finalIssueResp_0_bits_isVecPartReplay,
  input  [15:0]  io_vecLdIn_finalIssueResp_0_bits_vecReplayMask,
  input  [3:0]   io_vecLdIn_finalIssueResp_0_bits_vecReplayMbIdx,
  input          io_vecLdIn_resp_0_valid,
  input          io_vecLdIn_resp_0_bits_robIdx_flag,
  input  [7:0]   io_vecLdIn_resp_0_bits_robIdx_value,
  input  [1:0]   io_vecLdIn_resp_0_bits_resp,
  input  [34:0]  io_vecLdIn_resp_0_bits_fuType,
  input  [6:0]   io_vecLdIn_resp_0_bits_uopIdx,
  input          io_vecLdIn_resp_0_bits_sqIdx_flag,
  input  [5:0]   io_vecLdIn_resp_0_bits_sqIdx_value,
  input          io_vecLdIn_resp_0_bits_lqIdx_flag,
  input  [6:0]   io_vecLdIn_resp_0_bits_lqIdx_value,
  input          io_vecLdIn_resp_0_bits_isVecPartReplay,
  input  [15:0]  io_vecLdIn_resp_0_bits_vecReplayMask,
  input  [3:0]   io_vecLdIn_resp_0_bits_vecReplayMbIdx,
  input  [1:0]   io_simpEntryDeqSelVec_0,
  input  [1:0]   io_simpEntryDeqSelVec_1,
  output [1:0]   io_simpEntryEnqSelVec_0,
  output [1:0]   io_simpEntryEnqSelVec_1,
  output [11:0]  io_compEntryEnqSelVec_0,
  output [11:0]  io_compEntryEnqSelVec_1
);

  // BEGIN GENERATED(core-inst)
  logic [1:0][1329:0] enq_payload;
  assign enq_payload[0] = {io_enq_0_bits_payload_numLsElem, io_enq_0_bits_payload_debug_sim_trig, io_enq_0_bits_payload_debug_fuType, io_enq_0_bits_payload_replayInst, io_enq_0_bits_payload_singleStep, io_enq_0_bits_payload_ssid, io_enq_0_bits_payload_loadWaitStrict, io_enq_0_bits_payload_loadWaitBit, io_enq_0_bits_payload_waitForRobIdx_value, io_enq_0_bits_payload_waitForRobIdx_flag, io_enq_0_bits_payload_storeSetHit, io_enq_0_bits_payload_debugInfo_issueTime, io_enq_0_bits_payload_debugInfo_selectTime, io_enq_0_bits_payload_snapshot, io_enq_0_bits_payload_eliminatedMove, io_enq_0_bits_payload_traceBlockInPipe_ilastsize, io_enq_0_bits_payload_traceBlockInPipe_iretire, io_enq_0_bits_payload_traceBlockInPipe_itype, io_enq_0_bits_payload_dirtyVs, io_enq_0_bits_payload_dirtyFs, io_enq_0_bits_payload_instrSize, io_enq_0_bits_payload_robIdx_value, io_enq_0_bits_payload_robIdx_flag, io_enq_0_bits_payload_regCacheIdx_1, io_enq_0_bits_payload_regCacheIdx_0, io_enq_0_bits_payload_useRegCache_1, io_enq_0_bits_payload_useRegCache_0, io_enq_0_bits_payload_psrc_4, io_enq_0_bits_payload_psrc_3, io_enq_0_bits_payload_psrc_2, io_enq_0_bits_payload_psrc_1, io_enq_0_bits_payload_psrc_0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, io_enq_0_bits_payload_srcState_4, io_enq_0_bits_payload_srcState_3, io_enq_0_bits_payload_srcState_2, io_enq_0_bits_payload_srcState_1, io_enq_0_bits_payload_srcState_0, io_enq_0_bits_payload_commitType, io_enq_0_bits_payload_numWB, io_enq_0_bits_payload_numUops, io_enq_0_bits_payload_firstUop, io_enq_0_bits_payload_isVset, io_enq_0_bits_payload_isDropAmocasSta, io_enq_0_bits_payload_isMove, io_enq_0_bits_payload_wfflags, io_enq_0_bits_payload_vlsInstr, io_enq_0_bits_payload_vpu_lastUop, io_enq_0_bits_payload_vpu_vuopIdx, io_enq_0_bits_payload_fpu_rm, io_enq_0_bits_payload_fpu_fmt, io_enq_0_bits_payload_fpu_typ, io_enq_0_bits_payload_fpu_wflags, io_enq_0_bits_payload_fpu_typeTagOut, io_enq_0_bits_payload_imm, io_enq_0_bits_payload_canRobCompress, io_enq_0_bits_payload_blockBackward, io_enq_0_bits_payload_waitForward, io_enq_0_bits_payload_isXSTrap, io_enq_0_bits_payload_fpWen, io_enq_0_bits_payload_rfWen, io_enq_0_bits_payload_fuType, io_enq_0_bits_payload_ldest, io_enq_0_bits_payload_srcType_4, io_enq_0_bits_payload_srcType_3, io_enq_0_bits_payload_srcType_2, io_enq_0_bits_payload_srcType_1, io_enq_0_bits_payload_srcType_0, io_enq_0_bits_payload_satpFlushFirstFetchFault, io_enq_0_bits_payload_crossPageIPFFix, io_enq_0_bits_payload_pred_taken, io_enq_0_bits_payload_preDecodeInfo_isRet, io_enq_0_bits_payload_preDecodeInfo_isCall, io_enq_0_bits_payload_preDecodeInfo_brType, io_enq_0_bits_payload_preDecodeInfo_isRVC, io_enq_0_bits_payload_preDecodeInfo_valid, io_enq_0_bits_payload_trigger, io_enq_0_bits_payload_hasException, io_enq_0_bits_payload_isFetchMalAddr, io_enq_0_bits_payload_exceptionVec_23, io_enq_0_bits_payload_exceptionVec_22, io_enq_0_bits_payload_exceptionVec_21, io_enq_0_bits_payload_exceptionVec_20, io_enq_0_bits_payload_exceptionVec_19, io_enq_0_bits_payload_exceptionVec_18, io_enq_0_bits_payload_exceptionVec_17, io_enq_0_bits_payload_exceptionVec_16, io_enq_0_bits_payload_exceptionVec_15, io_enq_0_bits_payload_exceptionVec_14, io_enq_0_bits_payload_exceptionVec_13, io_enq_0_bits_payload_exceptionVec_12, io_enq_0_bits_payload_exceptionVec_11, io_enq_0_bits_payload_exceptionVec_10, io_enq_0_bits_payload_exceptionVec_9, io_enq_0_bits_payload_exceptionVec_8, io_enq_0_bits_payload_exceptionVec_7, io_enq_0_bits_payload_exceptionVec_6, io_enq_0_bits_payload_exceptionVec_5, io_enq_0_bits_payload_exceptionVec_4, io_enq_0_bits_payload_exceptionVec_3, io_enq_0_bits_payload_exceptionVec_2, io_enq_0_bits_payload_exceptionVec_1, io_enq_0_bits_payload_exceptionVec_0, io_enq_0_bits_payload_foldpc, io_enq_0_bits_payload_pc, io_enq_0_bits_payload_instr, io_enq_0_bits_payload_sqIdx_value, io_enq_0_bits_payload_sqIdx_flag, io_enq_0_bits_payload_lqIdx_value, io_enq_0_bits_payload_lqIdx_flag, io_enq_0_bits_payload_debug_seqNum_uopIdx, io_enq_0_bits_payload_debug_seqNum_seqNum, io_enq_0_bits_payload_debugInfo_tlbRespTime, io_enq_0_bits_payload_debugInfo_tlbFirstReqTime, io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_0_bits_payload_debugInfo_writebackTime, io_enq_0_bits_payload_debugInfo_enqRsTime, io_enq_0_bits_payload_debugInfo_dispatchTime, io_enq_0_bits_payload_debugInfo_renameTime, io_enq_0_bits_payload_debugInfo_eliminatedMove, io_enq_0_bits_payload_pdest, io_enq_0_bits_payload_lastUop, io_enq_0_bits_payload_uopIdx, io_enq_0_bits_payload_vpu_isVleff, io_enq_0_bits_payload_vpu_isWritePartVd, io_enq_0_bits_payload_vpu_isDependOldVd, io_enq_0_bits_payload_vpu_isMove, io_enq_0_bits_payload_vpu_isOpMask, io_enq_0_bits_payload_vpu_isDstMask, io_enq_0_bits_payload_vpu_isNarrow, io_enq_0_bits_payload_vpu_isExt, io_enq_0_bits_payload_vpu_isReverse, io_enq_0_bits_payload_vpu_veew, io_enq_0_bits_payload_vpu_nf, io_enq_0_bits_payload_vpu_vl, io_enq_0_bits_payload_vpu_vmask, io_enq_0_bits_payload_vpu_vxrm, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_0_bits_payload_vpu_fpu_isReduction, io_enq_0_bits_payload_vpu_fpu_isFP64Instr, io_enq_0_bits_payload_vpu_fpu_isFP32Instr, io_enq_0_bits_payload_vpu_fpu_isFpToVecInst, io_enq_0_bits_payload_vpu_frm, io_enq_0_bits_payload_vpu_vstart, io_enq_0_bits_payload_vpu_vm, io_enq_0_bits_payload_vpu_specVlmul, io_enq_0_bits_payload_vpu_specVsew, io_enq_0_bits_payload_vpu_specVta, io_enq_0_bits_payload_vpu_specVma, io_enq_0_bits_payload_vpu_specVill, io_enq_0_bits_payload_vpu_vlmul, io_enq_0_bits_payload_vpu_vsew, io_enq_0_bits_payload_vpu_vta, io_enq_0_bits_payload_vpu_vma, io_enq_0_bits_payload_vpu_vill, io_enq_0_bits_payload_selImm, io_enq_0_bits_payload_flushPipe, io_enq_0_bits_payload_vlWen, io_enq_0_bits_payload_v0Wen, io_enq_0_bits_payload_vecWen, io_enq_0_bits_payload_fuOpType, io_enq_0_bits_payload_ftqOffset, io_enq_0_bits_payload_ftqPtr_value, io_enq_0_bits_payload_ftqPtr_flag};
  assign enq_payload[1] = {io_enq_1_bits_payload_numLsElem, io_enq_1_bits_payload_debug_sim_trig, io_enq_1_bits_payload_debug_fuType, io_enq_1_bits_payload_replayInst, io_enq_1_bits_payload_singleStep, io_enq_1_bits_payload_ssid, io_enq_1_bits_payload_loadWaitStrict, io_enq_1_bits_payload_loadWaitBit, io_enq_1_bits_payload_waitForRobIdx_value, io_enq_1_bits_payload_waitForRobIdx_flag, io_enq_1_bits_payload_storeSetHit, io_enq_1_bits_payload_debugInfo_issueTime, io_enq_1_bits_payload_debugInfo_selectTime, io_enq_1_bits_payload_snapshot, io_enq_1_bits_payload_eliminatedMove, io_enq_1_bits_payload_traceBlockInPipe_ilastsize, io_enq_1_bits_payload_traceBlockInPipe_iretire, io_enq_1_bits_payload_traceBlockInPipe_itype, io_enq_1_bits_payload_dirtyVs, io_enq_1_bits_payload_dirtyFs, io_enq_1_bits_payload_instrSize, io_enq_1_bits_payload_robIdx_value, io_enq_1_bits_payload_robIdx_flag, io_enq_1_bits_payload_regCacheIdx_1, io_enq_1_bits_payload_regCacheIdx_0, io_enq_1_bits_payload_useRegCache_1, io_enq_1_bits_payload_useRegCache_0, io_enq_1_bits_payload_psrc_4, io_enq_1_bits_payload_psrc_3, io_enq_1_bits_payload_psrc_2, io_enq_1_bits_payload_psrc_1, io_enq_1_bits_payload_psrc_0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, io_enq_1_bits_payload_srcState_4, io_enq_1_bits_payload_srcState_3, io_enq_1_bits_payload_srcState_2, io_enq_1_bits_payload_srcState_1, io_enq_1_bits_payload_srcState_0, io_enq_1_bits_payload_commitType, io_enq_1_bits_payload_numWB, io_enq_1_bits_payload_numUops, io_enq_1_bits_payload_firstUop, io_enq_1_bits_payload_isVset, io_enq_1_bits_payload_isDropAmocasSta, io_enq_1_bits_payload_isMove, io_enq_1_bits_payload_wfflags, io_enq_1_bits_payload_vlsInstr, io_enq_1_bits_payload_vpu_lastUop, io_enq_1_bits_payload_vpu_vuopIdx, io_enq_1_bits_payload_fpu_rm, io_enq_1_bits_payload_fpu_fmt, io_enq_1_bits_payload_fpu_typ, io_enq_1_bits_payload_fpu_wflags, io_enq_1_bits_payload_fpu_typeTagOut, io_enq_1_bits_payload_imm, io_enq_1_bits_payload_canRobCompress, io_enq_1_bits_payload_blockBackward, io_enq_1_bits_payload_waitForward, io_enq_1_bits_payload_isXSTrap, io_enq_1_bits_payload_fpWen, io_enq_1_bits_payload_rfWen, io_enq_1_bits_payload_fuType, io_enq_1_bits_payload_ldest, io_enq_1_bits_payload_srcType_4, io_enq_1_bits_payload_srcType_3, io_enq_1_bits_payload_srcType_2, io_enq_1_bits_payload_srcType_1, io_enq_1_bits_payload_srcType_0, io_enq_1_bits_payload_satpFlushFirstFetchFault, io_enq_1_bits_payload_crossPageIPFFix, io_enq_1_bits_payload_pred_taken, io_enq_1_bits_payload_preDecodeInfo_isRet, io_enq_1_bits_payload_preDecodeInfo_isCall, io_enq_1_bits_payload_preDecodeInfo_brType, io_enq_1_bits_payload_preDecodeInfo_isRVC, io_enq_1_bits_payload_preDecodeInfo_valid, io_enq_1_bits_payload_trigger, io_enq_1_bits_payload_hasException, io_enq_1_bits_payload_isFetchMalAddr, io_enq_1_bits_payload_exceptionVec_23, io_enq_1_bits_payload_exceptionVec_22, io_enq_1_bits_payload_exceptionVec_21, io_enq_1_bits_payload_exceptionVec_20, io_enq_1_bits_payload_exceptionVec_19, io_enq_1_bits_payload_exceptionVec_18, io_enq_1_bits_payload_exceptionVec_17, io_enq_1_bits_payload_exceptionVec_16, io_enq_1_bits_payload_exceptionVec_15, io_enq_1_bits_payload_exceptionVec_14, io_enq_1_bits_payload_exceptionVec_13, io_enq_1_bits_payload_exceptionVec_12, io_enq_1_bits_payload_exceptionVec_11, io_enq_1_bits_payload_exceptionVec_10, io_enq_1_bits_payload_exceptionVec_9, io_enq_1_bits_payload_exceptionVec_8, io_enq_1_bits_payload_exceptionVec_7, io_enq_1_bits_payload_exceptionVec_6, io_enq_1_bits_payload_exceptionVec_5, io_enq_1_bits_payload_exceptionVec_4, io_enq_1_bits_payload_exceptionVec_3, io_enq_1_bits_payload_exceptionVec_2, io_enq_1_bits_payload_exceptionVec_1, io_enq_1_bits_payload_exceptionVec_0, io_enq_1_bits_payload_foldpc, io_enq_1_bits_payload_pc, io_enq_1_bits_payload_instr, io_enq_1_bits_payload_sqIdx_value, io_enq_1_bits_payload_sqIdx_flag, io_enq_1_bits_payload_lqIdx_value, io_enq_1_bits_payload_lqIdx_flag, io_enq_1_bits_payload_debug_seqNum_uopIdx, io_enq_1_bits_payload_debug_seqNum_seqNum, io_enq_1_bits_payload_debugInfo_tlbRespTime, io_enq_1_bits_payload_debugInfo_tlbFirstReqTime, io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_1_bits_payload_debugInfo_writebackTime, io_enq_1_bits_payload_debugInfo_enqRsTime, io_enq_1_bits_payload_debugInfo_dispatchTime, io_enq_1_bits_payload_debugInfo_renameTime, io_enq_1_bits_payload_debugInfo_eliminatedMove, io_enq_1_bits_payload_pdest, io_enq_1_bits_payload_lastUop, io_enq_1_bits_payload_uopIdx, io_enq_1_bits_payload_vpu_isVleff, io_enq_1_bits_payload_vpu_isWritePartVd, io_enq_1_bits_payload_vpu_isDependOldVd, io_enq_1_bits_payload_vpu_isMove, io_enq_1_bits_payload_vpu_isOpMask, io_enq_1_bits_payload_vpu_isDstMask, io_enq_1_bits_payload_vpu_isNarrow, io_enq_1_bits_payload_vpu_isExt, io_enq_1_bits_payload_vpu_isReverse, io_enq_1_bits_payload_vpu_veew, io_enq_1_bits_payload_vpu_nf, io_enq_1_bits_payload_vpu_vl, io_enq_1_bits_payload_vpu_vmask, io_enq_1_bits_payload_vpu_vxrm, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_1_bits_payload_vpu_fpu_isReduction, io_enq_1_bits_payload_vpu_fpu_isFP64Instr, io_enq_1_bits_payload_vpu_fpu_isFP32Instr, io_enq_1_bits_payload_vpu_fpu_isFpToVecInst, io_enq_1_bits_payload_vpu_frm, io_enq_1_bits_payload_vpu_vstart, io_enq_1_bits_payload_vpu_vm, io_enq_1_bits_payload_vpu_specVlmul, io_enq_1_bits_payload_vpu_specVsew, io_enq_1_bits_payload_vpu_specVta, io_enq_1_bits_payload_vpu_specVma, io_enq_1_bits_payload_vpu_specVill, io_enq_1_bits_payload_vpu_vlmul, io_enq_1_bits_payload_vpu_vsew, io_enq_1_bits_payload_vpu_vta, io_enq_1_bits_payload_vpu_vma, io_enq_1_bits_payload_vpu_vill, io_enq_1_bits_payload_selImm, io_enq_1_bits_payload_flushPipe, io_enq_1_bits_payload_vlWen, io_enq_1_bits_payload_v0Wen, io_enq_1_bits_payload_vecWen, io_enq_1_bits_payload_fuOpType, io_enq_1_bits_payload_ftqOffset, io_enq_1_bits_payload_ftqPtr_value, io_enq_1_bits_payload_ftqPtr_flag};

  logic [0:0][758:0] deq_payload;
  logic [15:0][1:0] fu_type_narrow;
  logic [0:0][1:0] deq_fu_type;
  logic [0:0][4:0][6:0] deq_psrc;
  logic [0:0][4:0][3:0] deq_src_type;
  logic [0:0] deq_rob_flag;
  logic [0:0][7:0] deq_rob_value;
  logic [15:0][4:0][3:0] data_src;
  // 核的这几个出口：顶层有对应端口的接有名线（后面展开），没有的接悬空线
  logic [15:0][4:0][0:0] unused_exu_src;
  logic [15:0][2:0][1:0] unused_ld_dep;
  logic [0:0][4:0][2:0][1:0] unused_deq_ld_dep;
  logic [0:0][4:0][0:0] unused_deq_rc_idx;
  logic [0:0] unused_cancel_deq;
  logic [0:0][19:0] deq_vm;   // {numLsElem, lqIdx, sqIdx}
  logic [0:0] deq_vpr;
  logic [0:0][15:0] deq_vr_mask;
  logic [0:0][3:0] deq_vr_mbidx;

  xs_iq_entries_core #(
    .NUM_ENQ(2), .NUM_SIMP(2), .NUM_COMP(12), .NUM_DEQ(1),
    .NUM_REGSRC(5), .NUM_WK_WB(16), .NUM_FU_BIT(2),
    .ROB_W(8), .PSRC_W(7), .PDEST_W(8),
    .PL_DEQ_W(759), .PL_TRANS_W(1330),
    .HAS_LD_DEP(1), .COMP_HAS_LD_DEP(0),
    .HAS_LD_CANCEL(0), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(0), .EXU_W(1),
    .SRC_WB_MASK({16'b1111111111111111, 16'b1111111111111111, 16'b1111111111111111, 16'b1111111111111111, 16'b1111111111111111}),
    .SRC_MATCH_KIND({2'd2, 2'd1, 2'd0, 2'd0, 2'd0}),
    .WB_WEN_PRESENT(5'b11111),
    .WBD_WEN_PRESENT(5'b11111),
    .HAS_IGNORE_OLD_VD(1),
    .VD_SRC(2), .VL_SRC(4), .WB_VL_INT(12), .WB_VL_VF(13),
    .PLB_VM(44),
    .PLB_VMA(29),
    .PLB_VTA(30),
    .PLB_IS_DEPEND_OLDVD(212),
    .PLB_IS_WRITE_PARTVD(213),
    .OG_HAS_BITS(4'b0111),
    .OG_CONST_RESP({2'h0, 2'h0, 2'h0, 2'h0}),
    .HAS_VEC_MEM(1), .VM_SQ_W(7), .VM_LQ_W(8), .VM_NLSE_W(5),
    .VR_MASK_W(16), .VR_MBIDX_W(4), .PLB_IS_VLEFF(214),
    .MEM_RESP_MODE(2), .NUM_MEM_SRC(3), .SQ_VAL_W(6), .LQ_VAL_W(7),
    .PLB_SQ_FLAG(752), .PLB_SQ_VALUE(753), .PLB_LQ_FLAG(744), .PLB_LQ_VALUE(745)
  ) u_core (
    .clock(clock), .reset(reset),
    .flush_valid(io_flush_valid), .flush_rob_flag(io_flush_bits_robIdx_flag),
    .flush_rob_value(io_flush_bits_robIdx_value), .flush_level(io_flush_bits_level),
    .enq_valid({io_enq_1_valid, io_enq_0_valid}),
    .enq_rob_flag({io_enq_1_bits_status_robIdx_flag, io_enq_0_bits_status_robIdx_flag}),
    .enq_rob_value({io_enq_1_bits_status_robIdx_value, io_enq_0_bits_status_robIdx_value}),
    .enq_fu_type({io_enq_1_bits_status_fuType_32, io_enq_1_bits_status_fuType_31, io_enq_0_bits_status_fuType_32, io_enq_0_bits_status_fuType_31}),
    .enq_psrc({io_enq_1_bits_status_srcStatus_4_psrc, io_enq_1_bits_status_srcStatus_3_psrc, io_enq_1_bits_status_srcStatus_2_psrc, io_enq_1_bits_status_srcStatus_1_psrc, io_enq_1_bits_status_srcStatus_0_psrc, io_enq_0_bits_status_srcStatus_4_psrc, io_enq_0_bits_status_srcStatus_3_psrc, io_enq_0_bits_status_srcStatus_2_psrc, io_enq_0_bits_status_srcStatus_1_psrc, io_enq_0_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_enq_1_bits_status_srcStatus_4_srcType, io_enq_1_bits_status_srcStatus_3_srcType, io_enq_1_bits_status_srcStatus_2_srcType, io_enq_1_bits_status_srcStatus_1_srcType, io_enq_1_bits_status_srcStatus_0_srcType, io_enq_0_bits_status_srcStatus_4_srcType, io_enq_0_bits_status_srcStatus_3_srcType, io_enq_0_bits_status_srcStatus_2_srcType, io_enq_0_bits_status_srcStatus_1_srcType, io_enq_0_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_enq_1_bits_status_srcStatus_4_srcState, io_enq_1_bits_status_srcStatus_3_srcState, io_enq_1_bits_status_srcStatus_2_srcState, io_enq_1_bits_status_srcStatus_1_srcState, io_enq_1_bits_status_srcStatus_0_srcState, io_enq_0_bits_status_srcStatus_4_srcState, io_enq_0_bits_status_srcStatus_3_srcState, io_enq_0_bits_status_srcStatus_2_srcState, io_enq_0_bits_status_srcStatus_1_srcState, io_enq_0_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_enq_1_bits_status_srcStatus_4_dataSources_value, io_enq_1_bits_status_srcStatus_3_dataSources_value, io_enq_1_bits_status_srcStatus_2_dataSources_value, io_enq_1_bits_status_srcStatus_1_dataSources_value, io_enq_1_bits_status_srcStatus_0_dataSources_value, io_enq_0_bits_status_srcStatus_4_dataSources_value, io_enq_0_bits_status_srcStatus_3_dataSources_value, io_enq_0_bits_status_srcStatus_2_dataSources_value, io_enq_0_bits_status_srcStatus_1_dataSources_value, io_enq_0_bits_status_srcStatus_0_dataSources_value}),
    .enq_payload(enq_payload),
    .enq_ld_dep('0), .enq_pl_ld_dep('0),
    .enq_use_rc('0), .enq_rc_idx('0),
    .enq_blocked({io_enq_1_bits_status_blocked, io_enq_0_bits_status_blocked}),
    .enq_vm({io_enq_1_bits_status_vecMem_numLsElem, io_enq_1_bits_status_vecMem_lqIdx_flag, io_enq_1_bits_status_vecMem_lqIdx_value, io_enq_1_bits_status_vecMem_sqIdx_flag, io_enq_1_bits_status_vecMem_sqIdx_value, io_enq_0_bits_status_vecMem_numLsElem, io_enq_0_bits_status_vecMem_lqIdx_flag, io_enq_0_bits_status_vecMem_lqIdx_value, io_enq_0_bits_status_vecMem_sqIdx_flag, io_enq_0_bits_status_vecMem_sqIdx_value}),
    .lq_deq_ptr({io_vecMemIn_lqDeqPtr_flag, io_vecMemIn_lqDeqPtr_value}),
    .iq_wen('0), .iq_pdest('0), .iq_ld_dep('0), .iq_rc_dest('0),
    .og0_cancel_sel('0), .iq_is0lat('0), .iqd_is0lat('0),
    .iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0),
    .ld1_cancel('0),
    .ld2_cancel('0),
    .wk_valid({io_wakeUpFromWB_15_valid, io_wakeUpFromWB_14_valid, io_wakeUpFromWB_13_valid, io_wakeUpFromWB_12_valid, io_wakeUpFromWB_11_valid, io_wakeUpFromWB_10_valid, io_wakeUpFromWB_9_valid, io_wakeUpFromWB_8_valid, io_wakeUpFromWB_7_valid, io_wakeUpFromWB_6_valid, io_wakeUpFromWB_5_valid, io_wakeUpFromWB_4_valid, io_wakeUpFromWB_3_valid, io_wakeUpFromWB_2_valid, io_wakeUpFromWB_1_valid, io_wakeUpFromWB_0_valid}),
    .wk_wen({{io_wakeUpFromWB_15_bits_vlWen, io_wakeUpFromWB_15_bits_v0Wen, io_wakeUpFromWB_15_bits_vecWen, io_wakeUpFromWB_15_bits_fpWen, io_wakeUpFromWB_15_bits_rfWen}, {io_wakeUpFromWB_14_bits_vlWen, io_wakeUpFromWB_14_bits_v0Wen, io_wakeUpFromWB_14_bits_vecWen, io_wakeUpFromWB_14_bits_fpWen, io_wakeUpFromWB_14_bits_rfWen}, {io_wakeUpFromWB_13_bits_vlWen, io_wakeUpFromWB_13_bits_v0Wen, io_wakeUpFromWB_13_bits_vecWen, io_wakeUpFromWB_13_bits_fpWen, io_wakeUpFromWB_13_bits_rfWen}, {io_wakeUpFromWB_12_bits_vlWen, io_wakeUpFromWB_12_bits_v0Wen, io_wakeUpFromWB_12_bits_vecWen, io_wakeUpFromWB_12_bits_fpWen, io_wakeUpFromWB_12_bits_rfWen}, {io_wakeUpFromWB_11_bits_vlWen, io_wakeUpFromWB_11_bits_v0Wen, io_wakeUpFromWB_11_bits_vecWen, io_wakeUpFromWB_11_bits_fpWen, io_wakeUpFromWB_11_bits_rfWen}, {io_wakeUpFromWB_10_bits_vlWen, io_wakeUpFromWB_10_bits_v0Wen, io_wakeUpFromWB_10_bits_vecWen, io_wakeUpFromWB_10_bits_fpWen, io_wakeUpFromWB_10_bits_rfWen}, {io_wakeUpFromWB_9_bits_vlWen, io_wakeUpFromWB_9_bits_v0Wen, io_wakeUpFromWB_9_bits_vecWen, io_wakeUpFromWB_9_bits_fpWen, io_wakeUpFromWB_9_bits_rfWen}, {io_wakeUpFromWB_8_bits_vlWen, io_wakeUpFromWB_8_bits_v0Wen, io_wakeUpFromWB_8_bits_vecWen, io_wakeUpFromWB_8_bits_fpWen, io_wakeUpFromWB_8_bits_rfWen}, {io_wakeUpFromWB_7_bits_vlWen, io_wakeUpFromWB_7_bits_v0Wen, io_wakeUpFromWB_7_bits_vecWen, io_wakeUpFromWB_7_bits_fpWen, io_wakeUpFromWB_7_bits_rfWen}, {io_wakeUpFromWB_6_bits_vlWen, io_wakeUpFromWB_6_bits_v0Wen, io_wakeUpFromWB_6_bits_vecWen, io_wakeUpFromWB_6_bits_fpWen, io_wakeUpFromWB_6_bits_rfWen}, {io_wakeUpFromWB_5_bits_vlWen, io_wakeUpFromWB_5_bits_v0Wen, io_wakeUpFromWB_5_bits_vecWen, io_wakeUpFromWB_5_bits_fpWen, io_wakeUpFromWB_5_bits_rfWen}, {io_wakeUpFromWB_4_bits_vlWen, io_wakeUpFromWB_4_bits_v0Wen, io_wakeUpFromWB_4_bits_vecWen, io_wakeUpFromWB_4_bits_fpWen, io_wakeUpFromWB_4_bits_rfWen}, {io_wakeUpFromWB_3_bits_vlWen, io_wakeUpFromWB_3_bits_v0Wen, io_wakeUpFromWB_3_bits_vecWen, io_wakeUpFromWB_3_bits_fpWen, io_wakeUpFromWB_3_bits_rfWen}, {io_wakeUpFromWB_2_bits_vlWen, io_wakeUpFromWB_2_bits_v0Wen, io_wakeUpFromWB_2_bits_vecWen, io_wakeUpFromWB_2_bits_fpWen, io_wakeUpFromWB_2_bits_rfWen}, {io_wakeUpFromWB_1_bits_vlWen, io_wakeUpFromWB_1_bits_v0Wen, io_wakeUpFromWB_1_bits_vecWen, io_wakeUpFromWB_1_bits_fpWen, io_wakeUpFromWB_1_bits_rfWen}, {io_wakeUpFromWB_0_bits_vlWen, io_wakeUpFromWB_0_bits_v0Wen, io_wakeUpFromWB_0_bits_vecWen, io_wakeUpFromWB_0_bits_fpWen, io_wakeUpFromWB_0_bits_rfWen}}),
    .wk_pdest({io_wakeUpFromWB_15_bits_pdest, io_wakeUpFromWB_14_bits_pdest, io_wakeUpFromWB_13_bits_pdest, io_wakeUpFromWB_12_bits_pdest, io_wakeUpFromWB_11_bits_pdest, io_wakeUpFromWB_10_bits_pdest, io_wakeUpFromWB_9_bits_pdest, io_wakeUpFromWB_8_bits_pdest, io_wakeUpFromWB_7_bits_pdest, io_wakeUpFromWB_6_bits_pdest, io_wakeUpFromWB_5_bits_pdest, io_wakeUpFromWB_4_bits_pdest, io_wakeUpFromWB_3_bits_pdest, io_wakeUpFromWB_2_bits_pdest, io_wakeUpFromWB_1_bits_pdest, io_wakeUpFromWB_0_bits_pdest}),
    .wkd_valid({io_wakeUpFromWBDelayed_15_valid, io_wakeUpFromWBDelayed_14_valid, io_wakeUpFromWBDelayed_13_valid, io_wakeUpFromWBDelayed_12_valid, io_wakeUpFromWBDelayed_11_valid, io_wakeUpFromWBDelayed_10_valid, io_wakeUpFromWBDelayed_9_valid, io_wakeUpFromWBDelayed_8_valid, io_wakeUpFromWBDelayed_7_valid, io_wakeUpFromWBDelayed_6_valid, io_wakeUpFromWBDelayed_5_valid, io_wakeUpFromWBDelayed_4_valid, io_wakeUpFromWBDelayed_3_valid, io_wakeUpFromWBDelayed_2_valid, io_wakeUpFromWBDelayed_1_valid, io_wakeUpFromWBDelayed_0_valid}),
    .wkd_wen({{io_wakeUpFromWBDelayed_15_bits_vlWen, io_wakeUpFromWBDelayed_15_bits_v0Wen, io_wakeUpFromWBDelayed_15_bits_vecWen, io_wakeUpFromWBDelayed_15_bits_fpWen, io_wakeUpFromWBDelayed_15_bits_rfWen}, {io_wakeUpFromWBDelayed_14_bits_vlWen, io_wakeUpFromWBDelayed_14_bits_v0Wen, io_wakeUpFromWBDelayed_14_bits_vecWen, io_wakeUpFromWBDelayed_14_bits_fpWen, io_wakeUpFromWBDelayed_14_bits_rfWen}, {io_wakeUpFromWBDelayed_13_bits_vlWen, io_wakeUpFromWBDelayed_13_bits_v0Wen, io_wakeUpFromWBDelayed_13_bits_vecWen, io_wakeUpFromWBDelayed_13_bits_fpWen, io_wakeUpFromWBDelayed_13_bits_rfWen}, {io_wakeUpFromWBDelayed_12_bits_vlWen, io_wakeUpFromWBDelayed_12_bits_v0Wen, io_wakeUpFromWBDelayed_12_bits_vecWen, io_wakeUpFromWBDelayed_12_bits_fpWen, io_wakeUpFromWBDelayed_12_bits_rfWen}, {io_wakeUpFromWBDelayed_11_bits_vlWen, io_wakeUpFromWBDelayed_11_bits_v0Wen, io_wakeUpFromWBDelayed_11_bits_vecWen, io_wakeUpFromWBDelayed_11_bits_fpWen, io_wakeUpFromWBDelayed_11_bits_rfWen}, {io_wakeUpFromWBDelayed_10_bits_vlWen, io_wakeUpFromWBDelayed_10_bits_v0Wen, io_wakeUpFromWBDelayed_10_bits_vecWen, io_wakeUpFromWBDelayed_10_bits_fpWen, io_wakeUpFromWBDelayed_10_bits_rfWen}, {io_wakeUpFromWBDelayed_9_bits_vlWen, io_wakeUpFromWBDelayed_9_bits_v0Wen, io_wakeUpFromWBDelayed_9_bits_vecWen, io_wakeUpFromWBDelayed_9_bits_fpWen, io_wakeUpFromWBDelayed_9_bits_rfWen}, {io_wakeUpFromWBDelayed_8_bits_vlWen, io_wakeUpFromWBDelayed_8_bits_v0Wen, io_wakeUpFromWBDelayed_8_bits_vecWen, io_wakeUpFromWBDelayed_8_bits_fpWen, io_wakeUpFromWBDelayed_8_bits_rfWen}, {io_wakeUpFromWBDelayed_7_bits_vlWen, io_wakeUpFromWBDelayed_7_bits_v0Wen, io_wakeUpFromWBDelayed_7_bits_vecWen, io_wakeUpFromWBDelayed_7_bits_fpWen, io_wakeUpFromWBDelayed_7_bits_rfWen}, {io_wakeUpFromWBDelayed_6_bits_vlWen, io_wakeUpFromWBDelayed_6_bits_v0Wen, io_wakeUpFromWBDelayed_6_bits_vecWen, io_wakeUpFromWBDelayed_6_bits_fpWen, io_wakeUpFromWBDelayed_6_bits_rfWen}, {io_wakeUpFromWBDelayed_5_bits_vlWen, io_wakeUpFromWBDelayed_5_bits_v0Wen, io_wakeUpFromWBDelayed_5_bits_vecWen, io_wakeUpFromWBDelayed_5_bits_fpWen, io_wakeUpFromWBDelayed_5_bits_rfWen}, {io_wakeUpFromWBDelayed_4_bits_vlWen, io_wakeUpFromWBDelayed_4_bits_v0Wen, io_wakeUpFromWBDelayed_4_bits_vecWen, io_wakeUpFromWBDelayed_4_bits_fpWen, io_wakeUpFromWBDelayed_4_bits_rfWen}, {io_wakeUpFromWBDelayed_3_bits_vlWen, io_wakeUpFromWBDelayed_3_bits_v0Wen, io_wakeUpFromWBDelayed_3_bits_vecWen, io_wakeUpFromWBDelayed_3_bits_fpWen, io_wakeUpFromWBDelayed_3_bits_rfWen}, {io_wakeUpFromWBDelayed_2_bits_vlWen, io_wakeUpFromWBDelayed_2_bits_v0Wen, io_wakeUpFromWBDelayed_2_bits_vecWen, io_wakeUpFromWBDelayed_2_bits_fpWen, io_wakeUpFromWBDelayed_2_bits_rfWen}, {io_wakeUpFromWBDelayed_1_bits_vlWen, io_wakeUpFromWBDelayed_1_bits_v0Wen, io_wakeUpFromWBDelayed_1_bits_vecWen, io_wakeUpFromWBDelayed_1_bits_fpWen, io_wakeUpFromWBDelayed_1_bits_rfWen}, {io_wakeUpFromWBDelayed_0_bits_vlWen, io_wakeUpFromWBDelayed_0_bits_v0Wen, io_wakeUpFromWBDelayed_0_bits_vecWen, io_wakeUpFromWBDelayed_0_bits_fpWen, io_wakeUpFromWBDelayed_0_bits_rfWen}}),
    .wkd_pdest({io_wakeUpFromWBDelayed_15_bits_pdest, io_wakeUpFromWBDelayed_14_bits_pdest, io_wakeUpFromWBDelayed_13_bits_pdest, io_wakeUpFromWBDelayed_12_bits_pdest, io_wakeUpFromWBDelayed_11_bits_pdest, io_wakeUpFromWBDelayed_10_bits_pdest, io_wakeUpFromWBDelayed_9_bits_pdest, io_wakeUpFromWBDelayed_8_bits_pdest, io_wakeUpFromWBDelayed_7_bits_pdest, io_wakeUpFromWBDelayed_6_bits_pdest, io_wakeUpFromWBDelayed_5_bits_pdest, io_wakeUpFromWBDelayed_4_bits_pdest, io_wakeUpFromWBDelayed_3_bits_pdest, io_wakeUpFromWBDelayed_2_bits_pdest, io_wakeUpFromWBDelayed_1_bits_pdest, io_wakeUpFromWBDelayed_0_bits_pdest}),
    .vl_int_is_zero(io_vlFromIntIsZero), .vl_int_is_vlmax(io_vlFromIntIsVlmax),
    .vl_vf_is_zero(io_vlFromVfIsZero), .vl_vf_is_vlmax(io_vlFromVfIsVlmax),
    .og_valid({{io_og2Resp_0_valid}, {io_og1Resp_0_valid}, {io_og0Resp_0_valid}}),
    .og_resp({{io_og2Resp_0_bits_resp}, {io_og1Resp_0_bits_resp}, {io_og0Resp_0_bits_resp}}),
    .og_vpr({{io_og2Resp_0_bits_isVecPartReplay}, {io_og1Resp_0_bits_isVecPartReplay}, {io_og0Resp_0_bits_isVecPartReplay}}),
    .og_vr_mask({{io_og2Resp_0_bits_vecReplayMask}, {io_og1Resp_0_bits_vecReplayMask}, {io_og0Resp_0_bits_vecReplayMask}}),
    .og_vr_mbidx({{io_og2Resp_0_bits_vecReplayMbIdx}, {io_og1Resp_0_bits_vecReplayMbIdx}, {io_og0Resp_0_bits_vecReplayMbIdx}}),
    .mem_valid({io_vecLdIn_finalIssueResp_0_valid, io_fromMem_slowResp_0_valid, io_vecLdIn_resp_0_valid}),
    .mem_resp({io_vecLdIn_finalIssueResp_0_bits_resp, io_fromMem_slowResp_0_bits_resp, io_vecLdIn_resp_0_bits_resp}),
    .mem_sq_idx({{io_vecLdIn_finalIssueResp_0_bits_sqIdx_flag, io_vecLdIn_finalIssueResp_0_bits_sqIdx_value}, {io_fromMem_slowResp_0_bits_sqIdx_flag, io_fromMem_slowResp_0_bits_sqIdx_value}, {io_vecLdIn_resp_0_bits_sqIdx_flag, io_vecLdIn_resp_0_bits_sqIdx_value}}),
    .mem_lq_idx({{io_vecLdIn_finalIssueResp_0_bits_lqIdx_flag, io_vecLdIn_finalIssueResp_0_bits_lqIdx_value}, {io_fromMem_slowResp_0_bits_lqIdx_flag, io_fromMem_slowResp_0_bits_lqIdx_value}, {io_vecLdIn_resp_0_bits_lqIdx_flag, io_vecLdIn_resp_0_bits_lqIdx_value}}),
    .mem_vpr({io_vecLdIn_finalIssueResp_0_bits_isVecPartReplay, io_fromMem_slowResp_0_bits_isVecPartReplay, io_vecLdIn_resp_0_bits_isVecPartReplay}),
    .mem_vr_mask({io_vecLdIn_finalIssueResp_0_bits_vecReplayMask, io_fromMem_slowResp_0_bits_vecReplayMask, io_vecLdIn_resp_0_bits_vecReplayMask}),
    .mem_vr_mbidx({io_vecLdIn_finalIssueResp_0_bits_vecReplayMbIdx, io_fromMem_slowResp_0_bits_vecReplayMbIdx, io_vecLdIn_resp_0_bits_vecReplayMbIdx}),
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
    .o_deq_vm(deq_vm), .o_deq_vpr(deq_vpr),
    .o_deq_vr_mask(deq_vr_mask), .o_deq_vr_mbidx(deq_vr_mbidx),
    .o_simp_enq_sel_vec({io_simpEntryEnqSelVec_1, io_simpEntryEnqSelVec_0}),
    .o_comp_enq_sel_vec({io_compEntryEnqSelVec_1, io_compEntryEnqSelVec_0})
  );

  // fuType 输出：核只存本变体保留的 2 位，这里放回 35 位 one-hot 的原位置
  assign io_fuType_0 = {2'h0, fu_type_narrow[0][1], fu_type_narrow[0][0], 31'h0};
  assign io_fuType_1 = {2'h0, fu_type_narrow[1][1], fu_type_narrow[1][0], 31'h0};
  assign io_fuType_2 = {2'h0, fu_type_narrow[2][1], fu_type_narrow[2][0], 31'h0};
  assign io_fuType_3 = {2'h0, fu_type_narrow[3][1], fu_type_narrow[3][0], 31'h0};
  assign io_fuType_4 = {2'h0, fu_type_narrow[4][1], fu_type_narrow[4][0], 31'h0};
  assign io_fuType_5 = {2'h0, fu_type_narrow[5][1], fu_type_narrow[5][0], 31'h0};
  assign io_fuType_6 = {2'h0, fu_type_narrow[6][1], fu_type_narrow[6][0], 31'h0};
  assign io_fuType_7 = {2'h0, fu_type_narrow[7][1], fu_type_narrow[7][0], 31'h0};
  assign io_fuType_8 = {2'h0, fu_type_narrow[8][1], fu_type_narrow[8][0], 31'h0};
  assign io_fuType_9 = {2'h0, fu_type_narrow[9][1], fu_type_narrow[9][0], 31'h0};
  assign io_fuType_10 = {2'h0, fu_type_narrow[10][1], fu_type_narrow[10][0], 31'h0};
  assign io_fuType_11 = {2'h0, fu_type_narrow[11][1], fu_type_narrow[11][0], 31'h0};
  assign io_fuType_12 = {2'h0, fu_type_narrow[12][1], fu_type_narrow[12][0], 31'h0};
  assign io_fuType_13 = {2'h0, fu_type_narrow[13][1], fu_type_narrow[13][0], 31'h0};
  assign io_fuType_14 = {2'h0, fu_type_narrow[14][1], fu_type_narrow[14][0], 31'h0};
  assign io_fuType_15 = {2'h0, fu_type_narrow[15][1], fu_type_narrow[15][0], 31'h0};

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
  assign io_dataSources_10_0_value = data_src[10][0];
  assign io_dataSources_10_1_value = data_src[10][1];
  assign io_dataSources_10_2_value = data_src[10][2];
  assign io_dataSources_10_3_value = data_src[10][3];
  assign io_dataSources_10_4_value = data_src[10][4];
  assign io_dataSources_11_0_value = data_src[11][0];
  assign io_dataSources_11_1_value = data_src[11][1];
  assign io_dataSources_11_2_value = data_src[11][2];
  assign io_dataSources_11_3_value = data_src[11][3];
  assign io_dataSources_11_4_value = data_src[11][4];
  assign io_dataSources_12_0_value = data_src[12][0];
  assign io_dataSources_12_1_value = data_src[12][1];
  assign io_dataSources_12_2_value = data_src[12][2];
  assign io_dataSources_12_3_value = data_src[12][3];
  assign io_dataSources_12_4_value = data_src[12][4];
  assign io_dataSources_13_0_value = data_src[13][0];
  assign io_dataSources_13_1_value = data_src[13][1];
  assign io_dataSources_13_2_value = data_src[13][2];
  assign io_dataSources_13_3_value = data_src[13][3];
  assign io_dataSources_13_4_value = data_src[13][4];
  assign io_dataSources_14_0_value = data_src[14][0];
  assign io_dataSources_14_1_value = data_src[14][1];
  assign io_dataSources_14_2_value = data_src[14][2];
  assign io_dataSources_14_3_value = data_src[14][3];
  assign io_dataSources_14_4_value = data_src[14][4];
  assign io_dataSources_15_0_value = data_src[15][0];
  assign io_dataSources_15_1_value = data_src[15][1];
  assign io_dataSources_15_2_value = data_src[15][2];
  assign io_dataSources_15_3_value = data_src[15][3];
  assign io_dataSources_15_4_value = data_src[15][4];

  assign io_deqEntry_0_bits_status_robIdx_flag  = deq_rob_flag[0];
  assign io_deqEntry_0_bits_status_robIdx_value = deq_rob_value[0];
  assign io_deqEntry_0_bits_status_fuType_31 = deq_fu_type[0][0];
  assign io_deqEntry_0_bits_status_fuType_32 = deq_fu_type[0][1];
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
  assign io_deqEntry_0_bits_status_vecMem_sqIdx_value = deq_vm[0][5:0];
  assign io_deqEntry_0_bits_status_vecMem_sqIdx_flag  = deq_vm[0][6];
  assign io_deqEntry_0_bits_status_vecMem_lqIdx_value = deq_vm[0][13:7];
  assign io_deqEntry_0_bits_status_vecMem_lqIdx_flag  = deq_vm[0][14];
  assign io_deqEntry_0_bits_status_vecMem_numLsElem   = deq_vm[0][19:15];
  assign io_deqEntry_0_bits_status_isVecPartReplay    = deq_vpr[0];
  assign io_deqEntry_0_bits_status_vecReplayMask      = deq_vr_mask[0];
  assign io_deqEntry_0_bits_status_vecReplayMbIdx     = deq_vr_mbidx[0];
  assign io_deqEntry_0_bits_payload_ftqPtr_flag = deq_payload[0][0];
  assign io_deqEntry_0_bits_payload_ftqPtr_value = deq_payload[0][6:1];
  assign io_deqEntry_0_bits_payload_ftqOffset = deq_payload[0][10:7];
  assign io_deqEntry_0_bits_payload_fuOpType = deq_payload[0][19:11];
  assign io_deqEntry_0_bits_payload_vecWen = deq_payload[0][20];
  assign io_deqEntry_0_bits_payload_v0Wen = deq_payload[0][21];
  assign io_deqEntry_0_bits_payload_vlWen = deq_payload[0][22];
  assign io_deqEntry_0_bits_payload_flushPipe = deq_payload[0][23];
  assign io_deqEntry_0_bits_payload_selImm = deq_payload[0][27:24];
  assign io_deqEntry_0_bits_payload_vpu_vill = deq_payload[0][28];
  assign io_deqEntry_0_bits_payload_vpu_vma = deq_payload[0][29];
  assign io_deqEntry_0_bits_payload_vpu_vta = deq_payload[0][30];
  assign io_deqEntry_0_bits_payload_vpu_vsew = deq_payload[0][32:31];
  assign io_deqEntry_0_bits_payload_vpu_vlmul = deq_payload[0][35:33];
  assign io_deqEntry_0_bits_payload_vpu_specVill = deq_payload[0][36];
  assign io_deqEntry_0_bits_payload_vpu_specVma = deq_payload[0][37];
  assign io_deqEntry_0_bits_payload_vpu_specVta = deq_payload[0][38];
  assign io_deqEntry_0_bits_payload_vpu_specVsew = deq_payload[0][40:39];
  assign io_deqEntry_0_bits_payload_vpu_specVlmul = deq_payload[0][43:41];
  assign io_deqEntry_0_bits_payload_vpu_vm = deq_payload[0][44];
  assign io_deqEntry_0_bits_payload_vpu_vstart = deq_payload[0][52:45];
  assign io_deqEntry_0_bits_payload_vpu_frm = deq_payload[0][55:53];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFpToVecInst = deq_payload[0][56];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFP32Instr = deq_payload[0][57];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFP64Instr = deq_payload[0][58];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isReduction = deq_payload[0][59];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_2 = deq_payload[0][60];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_4 = deq_payload[0][61];
  assign io_deqEntry_0_bits_payload_vpu_fpu_isFoldTo1_8 = deq_payload[0][62];
  assign io_deqEntry_0_bits_payload_vpu_vxrm = deq_payload[0][64:63];
  assign io_deqEntry_0_bits_payload_vpu_vmask = deq_payload[0][192:65];
  assign io_deqEntry_0_bits_payload_vpu_vl = deq_payload[0][200:193];
  assign io_deqEntry_0_bits_payload_vpu_nf = deq_payload[0][203:201];
  assign io_deqEntry_0_bits_payload_vpu_veew = deq_payload[0][205:204];
  assign io_deqEntry_0_bits_payload_vpu_isReverse = deq_payload[0][206];
  assign io_deqEntry_0_bits_payload_vpu_isExt = deq_payload[0][207];
  assign io_deqEntry_0_bits_payload_vpu_isNarrow = deq_payload[0][208];
  assign io_deqEntry_0_bits_payload_vpu_isDstMask = deq_payload[0][209];
  assign io_deqEntry_0_bits_payload_vpu_isOpMask = deq_payload[0][210];
  assign io_deqEntry_0_bits_payload_vpu_isMove = deq_payload[0][211];
  assign io_deqEntry_0_bits_payload_vpu_isDependOldVd = deq_payload[0][212];
  assign io_deqEntry_0_bits_payload_vpu_isWritePartVd = deq_payload[0][213];
  assign io_deqEntry_0_bits_payload_vpu_isVleff = deq_payload[0][214];
  assign io_deqEntry_0_bits_payload_uopIdx = deq_payload[0][221:215];
  assign io_deqEntry_0_bits_payload_lastUop = deq_payload[0][222];
  assign io_deqEntry_0_bits_payload_pdest = deq_payload[0][230:223];
  assign io_deqEntry_0_bits_payload_debugInfo_eliminatedMove = deq_payload[0][231];
  assign io_deqEntry_0_bits_payload_debugInfo_renameTime = deq_payload[0][295:232];
  assign io_deqEntry_0_bits_payload_debugInfo_dispatchTime = deq_payload[0][359:296];
  assign io_deqEntry_0_bits_payload_debugInfo_enqRsTime = deq_payload[0][423:360];
  assign io_deqEntry_0_bits_payload_debugInfo_writebackTime = deq_payload[0][487:424];
  assign io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id = deq_payload[0][551:488];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime = deq_payload[0][615:552];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbRespTime = deq_payload[0][679:616];
  assign io_deqEntry_0_bits_payload_debug_seqNum_seqNum = deq_payload[0][735:680];
  assign io_deqEntry_0_bits_payload_debug_seqNum_uopIdx = deq_payload[0][743:736];

  // golden 顶层也不读的输入（golden 源里只有端口声明、没有读者）：
  // 显式收拢在这里，表示逐个查过、确实不用，而不是漏接。
  wire unused_golden_dead_inputs = ^{
    io_vecLdIn_finalIssueResp_0_bits_robIdx_flag,
    io_vecLdIn_finalIssueResp_0_bits_robIdx_value,
    io_vecLdIn_finalIssueResp_0_bits_fuType,
    io_vecLdIn_finalIssueResp_0_bits_uopIdx,
    io_vecLdIn_resp_0_bits_robIdx_flag,
    io_vecLdIn_resp_0_bits_robIdx_value,
    io_vecLdIn_resp_0_bits_fuType,
    io_vecLdIn_resp_0_bits_uopIdx
  };
  // END GENERATED(core-inst)

endmodule
