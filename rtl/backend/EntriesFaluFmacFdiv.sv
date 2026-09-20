// EntriesFaluFmacFdiv.sv —— 发射队列条目阵列（FaluFmacFdiv 变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv（Entries* 家族共享参数化核，本文件不含逻辑分支，
// 只把 golden 的扁平端口打包成核的数组/位向量接口，并给出本变体的参数）。
//
// 本变体规模（全部从 G1 golden EntriesFaluFmacFdiv.sv 机械量得）：
//   条目 18 = enq 2 + simp 2 + comp 14，发射口 2，源寄存器 3 个
//   WB 唤醒 6 路 + IQ 即时唤醒 3 路（带 og0Cancel / ldCancel×0 取消网络）
//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：
//     IQ0: og0Cancel[8], is0Lat=real
//     IQ1: 无取消, is0Lat=const0
//     IQ2: 无取消, is0Lat=const0
//   保留的 FuType one-hot 位：FuType[11], FuType[12], FuType[14]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位（comp 段没有：整条通路是死的）
//   issueResp 4 档（按 issueTimer）：timer0=常量 2'h0, timer1=真 resp, timer2=常量 2'h0, timer3=常量 2'h0
//   负载：发射口可见 20 个字段 / 546 位；转移包另带 160 个字段，共 1330 位
//   golden 层次：EnqEntry_10 ×2 + OthersEntry_104 ×2 + OthersEntry_106 ×14 + EnqPolicy_8 ×2，本文件把它们一并扁平化。
//
// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：
//   src0: WB[0..5]，匹配 srcType[1]&fpWen
//   src1: WB[0..5]，匹配 srcType[1]&fpWen
//   src2: WB[0..5]，匹配 srcType[1]&fpWen
//
// 自动生成：verif/ut/EntriesFaluFmacFdiv/gen.py（共享库 verif/ut/Entries_common/entries_gen.py）—— 勿手改
// =============================================================================
module EntriesFaluFmacFdiv (
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  input          io_enq_0_valid,
  input          io_enq_0_bits_status_robIdx_flag,
  input  [7:0]   io_enq_0_bits_status_robIdx_value,
  input          io_enq_0_bits_status_fuType_11,
  input          io_enq_0_bits_status_fuType_12,
  input          io_enq_0_bits_status_fuType_14,
  input  [7:0]   io_enq_0_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_0_srcType,
  input          io_enq_0_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_0_dataSources_value,
  input  [7:0]   io_enq_0_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_1_srcType,
  input          io_enq_0_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_1_dataSources_value,
  input  [7:0]   io_enq_0_bits_status_srcStatus_2_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_2_srcType,
  input          io_enq_0_bits_status_srcStatus_2_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_2_dataSources_value,
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
  input          io_enq_1_bits_status_fuType_11,
  input          io_enq_1_bits_status_fuType_12,
  input          io_enq_1_bits_status_fuType_14,
  input  [7:0]   io_enq_1_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_0_srcType,
  input          io_enq_1_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_0_dataSources_value,
  input  [7:0]   io_enq_1_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_1_srcType,
  input          io_enq_1_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_1_dataSources_value,
  input  [7:0]   io_enq_1_bits_status_srcStatus_2_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_2_srcType,
  input          io_enq_1_bits_status_srcStatus_2_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_2_dataSources_value,
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
  input          io_og0Resp_1_valid,
  input          io_og1Resp_0_valid,
  input  [1:0]   io_og1Resp_0_bits_resp,
  input          io_og1Resp_1_valid,
  input  [1:0]   io_og1Resp_1_bits_resp,
  input          io_deqReady_0,
  input          io_deqReady_1,
  input          io_deqSelOH_0_valid,
  input  [17:0]  io_deqSelOH_0_bits,
  input          io_deqSelOH_1_valid,
  input  [17:0]  io_deqSelOH_1_bits,
  input  [1:0]   io_enqEntryOldestSel_0_bits,
  input  [1:0]   io_enqEntryOldestSel_1_bits,
  input          io_simpEntryOldestSel_0_valid,
  input  [1:0]   io_simpEntryOldestSel_0_bits,
  input          io_simpEntryOldestSel_1_valid,
  input  [1:0]   io_simpEntryOldestSel_1_bits,
  input          io_compEntryOldestSel_0_valid,
  input  [13:0]  io_compEntryOldestSel_0_bits,
  input          io_compEntryOldestSel_1_valid,
  input  [13:0]  io_compEntryOldestSel_1_bits,
  input          io_wakeUpFromWB_5_valid,
  input          io_wakeUpFromWB_5_bits_fpWen,
  input  [7:0]   io_wakeUpFromWB_5_bits_pdest,
  input          io_wakeUpFromWB_4_valid,
  input          io_wakeUpFromWB_4_bits_fpWen,
  input  [7:0]   io_wakeUpFromWB_4_bits_pdest,
  input          io_wakeUpFromWB_3_valid,
  input          io_wakeUpFromWB_3_bits_fpWen,
  input  [7:0]   io_wakeUpFromWB_3_bits_pdest,
  input          io_wakeUpFromWB_2_valid,
  input          io_wakeUpFromWB_2_bits_fpWen,
  input  [7:0]   io_wakeUpFromWB_2_bits_pdest,
  input          io_wakeUpFromWB_1_valid,
  input          io_wakeUpFromWB_1_bits_fpWen,
  input  [7:0]   io_wakeUpFromWB_1_bits_pdest,
  input          io_wakeUpFromWB_0_valid,
  input          io_wakeUpFromWB_0_bits_fpWen,
  input  [7:0]   io_wakeUpFromWB_0_bits_pdest,
  input          io_wakeUpFromIQ_2_bits_fpWen,
  input  [7:0]   io_wakeUpFromIQ_2_bits_pdest,
  input          io_wakeUpFromIQ_1_bits_fpWen,
  input  [7:0]   io_wakeUpFromIQ_1_bits_pdest,
  input          io_wakeUpFromIQ_0_bits_fpWen,
  input  [7:0]   io_wakeUpFromIQ_0_bits_pdest,
  input          io_wakeUpFromIQ_0_bits_is0Lat,
  input          io_wakeUpFromWBDelayed_5_valid,
  input          io_wakeUpFromWBDelayed_5_bits_fpWen,
  input  [7:0]   io_wakeUpFromWBDelayed_5_bits_pdest,
  input          io_wakeUpFromWBDelayed_4_valid,
  input          io_wakeUpFromWBDelayed_4_bits_fpWen,
  input  [7:0]   io_wakeUpFromWBDelayed_4_bits_pdest,
  input          io_wakeUpFromWBDelayed_3_valid,
  input          io_wakeUpFromWBDelayed_3_bits_fpWen,
  input  [7:0]   io_wakeUpFromWBDelayed_3_bits_pdest,
  input          io_wakeUpFromWBDelayed_2_valid,
  input          io_wakeUpFromWBDelayed_2_bits_fpWen,
  input  [7:0]   io_wakeUpFromWBDelayed_2_bits_pdest,
  input          io_wakeUpFromWBDelayed_1_valid,
  input          io_wakeUpFromWBDelayed_1_bits_fpWen,
  input  [7:0]   io_wakeUpFromWBDelayed_1_bits_pdest,
  input          io_wakeUpFromWBDelayed_0_valid,
  input          io_wakeUpFromWBDelayed_0_bits_fpWen,
  input  [7:0]   io_wakeUpFromWBDelayed_0_bits_pdest,
  input          io_wakeUpFromIQDelayed_2_bits_fpWen,
  input  [7:0]   io_wakeUpFromIQDelayed_2_bits_pdest,
  input          io_wakeUpFromIQDelayed_1_bits_fpWen,
  input  [7:0]   io_wakeUpFromIQDelayed_1_bits_pdest,
  input          io_wakeUpFromIQDelayed_0_bits_fpWen,
  input  [7:0]   io_wakeUpFromIQDelayed_0_bits_pdest,
  input          io_wakeUpFromIQDelayed_0_bits_is0Lat,
  input          io_og0Cancel_8,
  output [17:0]  io_valid,
  output [17:0]  io_issued,
  output [17:0]  io_canIssue,
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
  output [34:0]  io_fuType_16,
  output [34:0]  io_fuType_17,
  output [3:0]   io_dataSources_0_0_value,
  output [3:0]   io_dataSources_0_1_value,
  output [3:0]   io_dataSources_0_2_value,
  output [3:0]   io_dataSources_1_0_value,
  output [3:0]   io_dataSources_1_1_value,
  output [3:0]   io_dataSources_1_2_value,
  output [3:0]   io_dataSources_2_0_value,
  output [3:0]   io_dataSources_2_1_value,
  output [3:0]   io_dataSources_2_2_value,
  output [3:0]   io_dataSources_3_0_value,
  output [3:0]   io_dataSources_3_1_value,
  output [3:0]   io_dataSources_3_2_value,
  output [3:0]   io_dataSources_4_0_value,
  output [3:0]   io_dataSources_4_1_value,
  output [3:0]   io_dataSources_4_2_value,
  output [3:0]   io_dataSources_5_0_value,
  output [3:0]   io_dataSources_5_1_value,
  output [3:0]   io_dataSources_5_2_value,
  output [3:0]   io_dataSources_6_0_value,
  output [3:0]   io_dataSources_6_1_value,
  output [3:0]   io_dataSources_6_2_value,
  output [3:0]   io_dataSources_7_0_value,
  output [3:0]   io_dataSources_7_1_value,
  output [3:0]   io_dataSources_7_2_value,
  output [3:0]   io_dataSources_8_0_value,
  output [3:0]   io_dataSources_8_1_value,
  output [3:0]   io_dataSources_8_2_value,
  output [3:0]   io_dataSources_9_0_value,
  output [3:0]   io_dataSources_9_1_value,
  output [3:0]   io_dataSources_9_2_value,
  output [3:0]   io_dataSources_10_0_value,
  output [3:0]   io_dataSources_10_1_value,
  output [3:0]   io_dataSources_10_2_value,
  output [3:0]   io_dataSources_11_0_value,
  output [3:0]   io_dataSources_11_1_value,
  output [3:0]   io_dataSources_11_2_value,
  output [3:0]   io_dataSources_12_0_value,
  output [3:0]   io_dataSources_12_1_value,
  output [3:0]   io_dataSources_12_2_value,
  output [3:0]   io_dataSources_13_0_value,
  output [3:0]   io_dataSources_13_1_value,
  output [3:0]   io_dataSources_13_2_value,
  output [3:0]   io_dataSources_14_0_value,
  output [3:0]   io_dataSources_14_1_value,
  output [3:0]   io_dataSources_14_2_value,
  output [3:0]   io_dataSources_15_0_value,
  output [3:0]   io_dataSources_15_1_value,
  output [3:0]   io_dataSources_15_2_value,
  output [3:0]   io_dataSources_16_0_value,
  output [3:0]   io_dataSources_16_1_value,
  output [3:0]   io_dataSources_16_2_value,
  output [3:0]   io_dataSources_17_0_value,
  output [3:0]   io_dataSources_17_1_value,
  output [3:0]   io_dataSources_17_2_value,
  output [1:0]   io_exuSources_0_0_value,
  output [1:0]   io_exuSources_0_1_value,
  output [1:0]   io_exuSources_0_2_value,
  output [1:0]   io_exuSources_1_0_value,
  output [1:0]   io_exuSources_1_1_value,
  output [1:0]   io_exuSources_1_2_value,
  output [1:0]   io_exuSources_2_0_value,
  output [1:0]   io_exuSources_2_1_value,
  output [1:0]   io_exuSources_2_2_value,
  output [1:0]   io_exuSources_3_0_value,
  output [1:0]   io_exuSources_3_1_value,
  output [1:0]   io_exuSources_3_2_value,
  output [1:0]   io_exuSources_4_0_value,
  output [1:0]   io_exuSources_4_1_value,
  output [1:0]   io_exuSources_4_2_value,
  output [1:0]   io_exuSources_5_0_value,
  output [1:0]   io_exuSources_5_1_value,
  output [1:0]   io_exuSources_5_2_value,
  output [1:0]   io_exuSources_6_0_value,
  output [1:0]   io_exuSources_6_1_value,
  output [1:0]   io_exuSources_6_2_value,
  output [1:0]   io_exuSources_7_0_value,
  output [1:0]   io_exuSources_7_1_value,
  output [1:0]   io_exuSources_7_2_value,
  output [1:0]   io_exuSources_8_0_value,
  output [1:0]   io_exuSources_8_1_value,
  output [1:0]   io_exuSources_8_2_value,
  output [1:0]   io_exuSources_9_0_value,
  output [1:0]   io_exuSources_9_1_value,
  output [1:0]   io_exuSources_9_2_value,
  output [1:0]   io_exuSources_10_0_value,
  output [1:0]   io_exuSources_10_1_value,
  output [1:0]   io_exuSources_10_2_value,
  output [1:0]   io_exuSources_11_0_value,
  output [1:0]   io_exuSources_11_1_value,
  output [1:0]   io_exuSources_11_2_value,
  output [1:0]   io_exuSources_12_0_value,
  output [1:0]   io_exuSources_12_1_value,
  output [1:0]   io_exuSources_12_2_value,
  output [1:0]   io_exuSources_13_0_value,
  output [1:0]   io_exuSources_13_1_value,
  output [1:0]   io_exuSources_13_2_value,
  output [1:0]   io_exuSources_14_0_value,
  output [1:0]   io_exuSources_14_1_value,
  output [1:0]   io_exuSources_14_2_value,
  output [1:0]   io_exuSources_15_0_value,
  output [1:0]   io_exuSources_15_1_value,
  output [1:0]   io_exuSources_15_2_value,
  output [1:0]   io_exuSources_16_0_value,
  output [1:0]   io_exuSources_16_1_value,
  output [1:0]   io_exuSources_16_2_value,
  output [1:0]   io_exuSources_17_0_value,
  output [1:0]   io_exuSources_17_1_value,
  output [1:0]   io_exuSources_17_2_value,
  output         io_isFirstIssue_0,
  output         io_isFirstIssue_1,
  output         io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0]   io_deqEntry_0_bits_status_robIdx_value,
  output         io_deqEntry_0_bits_status_fuType_11,
  output         io_deqEntry_0_bits_status_fuType_12,
  output         io_deqEntry_0_bits_status_fuType_14,
  output [7:0]   io_deqEntry_0_bits_status_srcStatus_0_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_0_srcType,
  output [7:0]   io_deqEntry_0_bits_status_srcStatus_1_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_1_srcType,
  output [7:0]   io_deqEntry_0_bits_status_srcStatus_2_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_2_srcType,
  output [8:0]   io_deqEntry_0_bits_payload_fuOpType,
  output         io_deqEntry_0_bits_payload_rfWen,
  output         io_deqEntry_0_bits_payload_fpWen,
  output [3:0]   io_deqEntry_0_bits_payload_selImm,
  output [1:0]   io_deqEntry_0_bits_payload_fpu_typeTagOut,
  output         io_deqEntry_0_bits_payload_fpu_wflags,
  output [1:0]   io_deqEntry_0_bits_payload_fpu_typ,
  output [1:0]   io_deqEntry_0_bits_payload_fpu_fmt,
  output [2:0]   io_deqEntry_0_bits_payload_fpu_rm,
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
  output         io_deqEntry_1_bits_status_robIdx_flag,
  output [7:0]   io_deqEntry_1_bits_status_robIdx_value,
  output         io_deqEntry_1_bits_status_fuType_11,
  output         io_deqEntry_1_bits_status_fuType_12,
  output         io_deqEntry_1_bits_status_fuType_14,
  output [7:0]   io_deqEntry_1_bits_status_srcStatus_0_psrc,
  output [3:0]   io_deqEntry_1_bits_status_srcStatus_0_srcType,
  output [7:0]   io_deqEntry_1_bits_status_srcStatus_1_psrc,
  output [3:0]   io_deqEntry_1_bits_status_srcStatus_1_srcType,
  output [8:0]   io_deqEntry_1_bits_payload_fuOpType,
  output         io_deqEntry_1_bits_payload_fpWen,
  output [3:0]   io_deqEntry_1_bits_payload_selImm,
  output [1:0]   io_deqEntry_1_bits_payload_fpu_typeTagOut,
  output         io_deqEntry_1_bits_payload_fpu_wflags,
  output [1:0]   io_deqEntry_1_bits_payload_fpu_typ,
  output [1:0]   io_deqEntry_1_bits_payload_fpu_fmt,
  output [2:0]   io_deqEntry_1_bits_payload_fpu_rm,
  output [7:0]   io_deqEntry_1_bits_payload_pdest,
  output         io_deqEntry_1_bits_payload_debugInfo_eliminatedMove,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_renameTime,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_dispatchTime,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_enqRsTime,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_writebackTime,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime,
  output [63:0]  io_deqEntry_1_bits_payload_debugInfo_tlbRespTime,
  output [55:0]  io_deqEntry_1_bits_payload_debug_seqNum_seqNum,
  output [7:0]   io_deqEntry_1_bits_payload_debug_seqNum_uopIdx,
  input  [1:0]   io_simpEntryDeqSelVec_0,
  input  [1:0]   io_simpEntryDeqSelVec_1,
  output [1:0]   io_simpEntryEnqSelVec_0,
  output [1:0]   io_simpEntryEnqSelVec_1,
  output [13:0]  io_compEntryEnqSelVec_0,
  output [13:0]  io_compEntryEnqSelVec_1
);

  // BEGIN GENERATED(core-inst)
  logic [1:0][1329:0] enq_payload;
  assign enq_payload[0] = {io_enq_0_bits_payload_numLsElem, io_enq_0_bits_payload_debug_sim_trig, io_enq_0_bits_payload_debug_fuType, io_enq_0_bits_payload_replayInst, io_enq_0_bits_payload_singleStep, io_enq_0_bits_payload_sqIdx_value, io_enq_0_bits_payload_sqIdx_flag, io_enq_0_bits_payload_lqIdx_value, io_enq_0_bits_payload_lqIdx_flag, io_enq_0_bits_payload_ssid, io_enq_0_bits_payload_loadWaitStrict, io_enq_0_bits_payload_loadWaitBit, io_enq_0_bits_payload_waitForRobIdx_value, io_enq_0_bits_payload_waitForRobIdx_flag, io_enq_0_bits_payload_storeSetHit, io_enq_0_bits_payload_debugInfo_issueTime, io_enq_0_bits_payload_debugInfo_selectTime, io_enq_0_bits_payload_snapshot, io_enq_0_bits_payload_eliminatedMove, io_enq_0_bits_payload_traceBlockInPipe_ilastsize, io_enq_0_bits_payload_traceBlockInPipe_iretire, io_enq_0_bits_payload_traceBlockInPipe_itype, io_enq_0_bits_payload_dirtyVs, io_enq_0_bits_payload_dirtyFs, io_enq_0_bits_payload_instrSize, io_enq_0_bits_payload_robIdx_value, io_enq_0_bits_payload_robIdx_flag, io_enq_0_bits_payload_regCacheIdx_1, io_enq_0_bits_payload_regCacheIdx_0, io_enq_0_bits_payload_useRegCache_1, io_enq_0_bits_payload_useRegCache_0, io_enq_0_bits_payload_psrc_4, io_enq_0_bits_payload_psrc_3, io_enq_0_bits_payload_psrc_2, io_enq_0_bits_payload_psrc_1, io_enq_0_bits_payload_psrc_0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, io_enq_0_bits_payload_srcState_4, io_enq_0_bits_payload_srcState_3, io_enq_0_bits_payload_srcState_2, io_enq_0_bits_payload_srcState_1, io_enq_0_bits_payload_srcState_0, io_enq_0_bits_payload_commitType, io_enq_0_bits_payload_numWB, io_enq_0_bits_payload_numUops, io_enq_0_bits_payload_lastUop, io_enq_0_bits_payload_firstUop, io_enq_0_bits_payload_isVset, io_enq_0_bits_payload_uopIdx, io_enq_0_bits_payload_isDropAmocasSta, io_enq_0_bits_payload_isMove, io_enq_0_bits_payload_wfflags, io_enq_0_bits_payload_vlsInstr, io_enq_0_bits_payload_vpu_isVleff, io_enq_0_bits_payload_vpu_isWritePartVd, io_enq_0_bits_payload_vpu_isDependOldVd, io_enq_0_bits_payload_vpu_isMove, io_enq_0_bits_payload_vpu_isOpMask, io_enq_0_bits_payload_vpu_isDstMask, io_enq_0_bits_payload_vpu_isNarrow, io_enq_0_bits_payload_vpu_isExt, io_enq_0_bits_payload_vpu_isReverse, io_enq_0_bits_payload_vpu_veew, io_enq_0_bits_payload_vpu_nf, io_enq_0_bits_payload_vpu_vl, io_enq_0_bits_payload_vpu_vmask, io_enq_0_bits_payload_vpu_lastUop, io_enq_0_bits_payload_vpu_vuopIdx, io_enq_0_bits_payload_vpu_vxrm, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_0_bits_payload_vpu_fpu_isReduction, io_enq_0_bits_payload_vpu_fpu_isFP64Instr, io_enq_0_bits_payload_vpu_fpu_isFP32Instr, io_enq_0_bits_payload_vpu_fpu_isFpToVecInst, io_enq_0_bits_payload_vpu_frm, io_enq_0_bits_payload_vpu_vstart, io_enq_0_bits_payload_vpu_vm, io_enq_0_bits_payload_vpu_specVlmul, io_enq_0_bits_payload_vpu_specVsew, io_enq_0_bits_payload_vpu_specVta, io_enq_0_bits_payload_vpu_specVma, io_enq_0_bits_payload_vpu_specVill, io_enq_0_bits_payload_vpu_vlmul, io_enq_0_bits_payload_vpu_vsew, io_enq_0_bits_payload_vpu_vta, io_enq_0_bits_payload_vpu_vma, io_enq_0_bits_payload_vpu_vill, io_enq_0_bits_payload_imm, io_enq_0_bits_payload_canRobCompress, io_enq_0_bits_payload_flushPipe, io_enq_0_bits_payload_blockBackward, io_enq_0_bits_payload_waitForward, io_enq_0_bits_payload_isXSTrap, io_enq_0_bits_payload_vlWen, io_enq_0_bits_payload_v0Wen, io_enq_0_bits_payload_vecWen, io_enq_0_bits_payload_fuType, io_enq_0_bits_payload_ldest, io_enq_0_bits_payload_srcType_4, io_enq_0_bits_payload_srcType_3, io_enq_0_bits_payload_srcType_2, io_enq_0_bits_payload_srcType_1, io_enq_0_bits_payload_srcType_0, io_enq_0_bits_payload_satpFlushFirstFetchFault, io_enq_0_bits_payload_ftqOffset, io_enq_0_bits_payload_ftqPtr_value, io_enq_0_bits_payload_ftqPtr_flag, io_enq_0_bits_payload_crossPageIPFFix, io_enq_0_bits_payload_pred_taken, io_enq_0_bits_payload_preDecodeInfo_isRet, io_enq_0_bits_payload_preDecodeInfo_isCall, io_enq_0_bits_payload_preDecodeInfo_brType, io_enq_0_bits_payload_preDecodeInfo_isRVC, io_enq_0_bits_payload_preDecodeInfo_valid, io_enq_0_bits_payload_trigger, io_enq_0_bits_payload_hasException, io_enq_0_bits_payload_isFetchMalAddr, io_enq_0_bits_payload_exceptionVec_23, io_enq_0_bits_payload_exceptionVec_22, io_enq_0_bits_payload_exceptionVec_21, io_enq_0_bits_payload_exceptionVec_20, io_enq_0_bits_payload_exceptionVec_19, io_enq_0_bits_payload_exceptionVec_18, io_enq_0_bits_payload_exceptionVec_17, io_enq_0_bits_payload_exceptionVec_16, io_enq_0_bits_payload_exceptionVec_15, io_enq_0_bits_payload_exceptionVec_14, io_enq_0_bits_payload_exceptionVec_13, io_enq_0_bits_payload_exceptionVec_12, io_enq_0_bits_payload_exceptionVec_11, io_enq_0_bits_payload_exceptionVec_10, io_enq_0_bits_payload_exceptionVec_9, io_enq_0_bits_payload_exceptionVec_8, io_enq_0_bits_payload_exceptionVec_7, io_enq_0_bits_payload_exceptionVec_6, io_enq_0_bits_payload_exceptionVec_5, io_enq_0_bits_payload_exceptionVec_4, io_enq_0_bits_payload_exceptionVec_3, io_enq_0_bits_payload_exceptionVec_2, io_enq_0_bits_payload_exceptionVec_1, io_enq_0_bits_payload_exceptionVec_0, io_enq_0_bits_payload_foldpc, io_enq_0_bits_payload_pc, io_enq_0_bits_payload_instr, io_enq_0_bits_payload_debug_seqNum_uopIdx, io_enq_0_bits_payload_debug_seqNum_seqNum, io_enq_0_bits_payload_debugInfo_tlbRespTime, io_enq_0_bits_payload_debugInfo_tlbFirstReqTime, io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_0_bits_payload_debugInfo_writebackTime, io_enq_0_bits_payload_debugInfo_enqRsTime, io_enq_0_bits_payload_debugInfo_dispatchTime, io_enq_0_bits_payload_debugInfo_renameTime, io_enq_0_bits_payload_debugInfo_eliminatedMove, io_enq_0_bits_payload_pdest, io_enq_0_bits_payload_fpu_rm, io_enq_0_bits_payload_fpu_fmt, io_enq_0_bits_payload_fpu_typ, io_enq_0_bits_payload_fpu_wflags, io_enq_0_bits_payload_fpu_typeTagOut, io_enq_0_bits_payload_selImm, io_enq_0_bits_payload_fpWen, io_enq_0_bits_payload_rfWen, io_enq_0_bits_payload_fuOpType};
  assign enq_payload[1] = {io_enq_1_bits_payload_numLsElem, io_enq_1_bits_payload_debug_sim_trig, io_enq_1_bits_payload_debug_fuType, io_enq_1_bits_payload_replayInst, io_enq_1_bits_payload_singleStep, io_enq_1_bits_payload_sqIdx_value, io_enq_1_bits_payload_sqIdx_flag, io_enq_1_bits_payload_lqIdx_value, io_enq_1_bits_payload_lqIdx_flag, io_enq_1_bits_payload_ssid, io_enq_1_bits_payload_loadWaitStrict, io_enq_1_bits_payload_loadWaitBit, io_enq_1_bits_payload_waitForRobIdx_value, io_enq_1_bits_payload_waitForRobIdx_flag, io_enq_1_bits_payload_storeSetHit, io_enq_1_bits_payload_debugInfo_issueTime, io_enq_1_bits_payload_debugInfo_selectTime, io_enq_1_bits_payload_snapshot, io_enq_1_bits_payload_eliminatedMove, io_enq_1_bits_payload_traceBlockInPipe_ilastsize, io_enq_1_bits_payload_traceBlockInPipe_iretire, io_enq_1_bits_payload_traceBlockInPipe_itype, io_enq_1_bits_payload_dirtyVs, io_enq_1_bits_payload_dirtyFs, io_enq_1_bits_payload_instrSize, io_enq_1_bits_payload_robIdx_value, io_enq_1_bits_payload_robIdx_flag, io_enq_1_bits_payload_regCacheIdx_1, io_enq_1_bits_payload_regCacheIdx_0, io_enq_1_bits_payload_useRegCache_1, io_enq_1_bits_payload_useRegCache_0, io_enq_1_bits_payload_psrc_4, io_enq_1_bits_payload_psrc_3, io_enq_1_bits_payload_psrc_2, io_enq_1_bits_payload_psrc_1, io_enq_1_bits_payload_psrc_0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, io_enq_1_bits_payload_srcState_4, io_enq_1_bits_payload_srcState_3, io_enq_1_bits_payload_srcState_2, io_enq_1_bits_payload_srcState_1, io_enq_1_bits_payload_srcState_0, io_enq_1_bits_payload_commitType, io_enq_1_bits_payload_numWB, io_enq_1_bits_payload_numUops, io_enq_1_bits_payload_lastUop, io_enq_1_bits_payload_firstUop, io_enq_1_bits_payload_isVset, io_enq_1_bits_payload_uopIdx, io_enq_1_bits_payload_isDropAmocasSta, io_enq_1_bits_payload_isMove, io_enq_1_bits_payload_wfflags, io_enq_1_bits_payload_vlsInstr, io_enq_1_bits_payload_vpu_isVleff, io_enq_1_bits_payload_vpu_isWritePartVd, io_enq_1_bits_payload_vpu_isDependOldVd, io_enq_1_bits_payload_vpu_isMove, io_enq_1_bits_payload_vpu_isOpMask, io_enq_1_bits_payload_vpu_isDstMask, io_enq_1_bits_payload_vpu_isNarrow, io_enq_1_bits_payload_vpu_isExt, io_enq_1_bits_payload_vpu_isReverse, io_enq_1_bits_payload_vpu_veew, io_enq_1_bits_payload_vpu_nf, io_enq_1_bits_payload_vpu_vl, io_enq_1_bits_payload_vpu_vmask, io_enq_1_bits_payload_vpu_lastUop, io_enq_1_bits_payload_vpu_vuopIdx, io_enq_1_bits_payload_vpu_vxrm, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_1_bits_payload_vpu_fpu_isReduction, io_enq_1_bits_payload_vpu_fpu_isFP64Instr, io_enq_1_bits_payload_vpu_fpu_isFP32Instr, io_enq_1_bits_payload_vpu_fpu_isFpToVecInst, io_enq_1_bits_payload_vpu_frm, io_enq_1_bits_payload_vpu_vstart, io_enq_1_bits_payload_vpu_vm, io_enq_1_bits_payload_vpu_specVlmul, io_enq_1_bits_payload_vpu_specVsew, io_enq_1_bits_payload_vpu_specVta, io_enq_1_bits_payload_vpu_specVma, io_enq_1_bits_payload_vpu_specVill, io_enq_1_bits_payload_vpu_vlmul, io_enq_1_bits_payload_vpu_vsew, io_enq_1_bits_payload_vpu_vta, io_enq_1_bits_payload_vpu_vma, io_enq_1_bits_payload_vpu_vill, io_enq_1_bits_payload_imm, io_enq_1_bits_payload_canRobCompress, io_enq_1_bits_payload_flushPipe, io_enq_1_bits_payload_blockBackward, io_enq_1_bits_payload_waitForward, io_enq_1_bits_payload_isXSTrap, io_enq_1_bits_payload_vlWen, io_enq_1_bits_payload_v0Wen, io_enq_1_bits_payload_vecWen, io_enq_1_bits_payload_fuType, io_enq_1_bits_payload_ldest, io_enq_1_bits_payload_srcType_4, io_enq_1_bits_payload_srcType_3, io_enq_1_bits_payload_srcType_2, io_enq_1_bits_payload_srcType_1, io_enq_1_bits_payload_srcType_0, io_enq_1_bits_payload_satpFlushFirstFetchFault, io_enq_1_bits_payload_ftqOffset, io_enq_1_bits_payload_ftqPtr_value, io_enq_1_bits_payload_ftqPtr_flag, io_enq_1_bits_payload_crossPageIPFFix, io_enq_1_bits_payload_pred_taken, io_enq_1_bits_payload_preDecodeInfo_isRet, io_enq_1_bits_payload_preDecodeInfo_isCall, io_enq_1_bits_payload_preDecodeInfo_brType, io_enq_1_bits_payload_preDecodeInfo_isRVC, io_enq_1_bits_payload_preDecodeInfo_valid, io_enq_1_bits_payload_trigger, io_enq_1_bits_payload_hasException, io_enq_1_bits_payload_isFetchMalAddr, io_enq_1_bits_payload_exceptionVec_23, io_enq_1_bits_payload_exceptionVec_22, io_enq_1_bits_payload_exceptionVec_21, io_enq_1_bits_payload_exceptionVec_20, io_enq_1_bits_payload_exceptionVec_19, io_enq_1_bits_payload_exceptionVec_18, io_enq_1_bits_payload_exceptionVec_17, io_enq_1_bits_payload_exceptionVec_16, io_enq_1_bits_payload_exceptionVec_15, io_enq_1_bits_payload_exceptionVec_14, io_enq_1_bits_payload_exceptionVec_13, io_enq_1_bits_payload_exceptionVec_12, io_enq_1_bits_payload_exceptionVec_11, io_enq_1_bits_payload_exceptionVec_10, io_enq_1_bits_payload_exceptionVec_9, io_enq_1_bits_payload_exceptionVec_8, io_enq_1_bits_payload_exceptionVec_7, io_enq_1_bits_payload_exceptionVec_6, io_enq_1_bits_payload_exceptionVec_5, io_enq_1_bits_payload_exceptionVec_4, io_enq_1_bits_payload_exceptionVec_3, io_enq_1_bits_payload_exceptionVec_2, io_enq_1_bits_payload_exceptionVec_1, io_enq_1_bits_payload_exceptionVec_0, io_enq_1_bits_payload_foldpc, io_enq_1_bits_payload_pc, io_enq_1_bits_payload_instr, io_enq_1_bits_payload_debug_seqNum_uopIdx, io_enq_1_bits_payload_debug_seqNum_seqNum, io_enq_1_bits_payload_debugInfo_tlbRespTime, io_enq_1_bits_payload_debugInfo_tlbFirstReqTime, io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_1_bits_payload_debugInfo_writebackTime, io_enq_1_bits_payload_debugInfo_enqRsTime, io_enq_1_bits_payload_debugInfo_dispatchTime, io_enq_1_bits_payload_debugInfo_renameTime, io_enq_1_bits_payload_debugInfo_eliminatedMove, io_enq_1_bits_payload_pdest, io_enq_1_bits_payload_fpu_rm, io_enq_1_bits_payload_fpu_fmt, io_enq_1_bits_payload_fpu_typ, io_enq_1_bits_payload_fpu_wflags, io_enq_1_bits_payload_fpu_typeTagOut, io_enq_1_bits_payload_selImm, io_enq_1_bits_payload_fpWen, io_enq_1_bits_payload_rfWen, io_enq_1_bits_payload_fuOpType};

  logic [1:0][545:0] deq_payload;
  logic [17:0][2:0] fu_type_narrow;
  logic [1:0][2:0] deq_fu_type;
  logic [1:0][2:0][7:0] deq_psrc;
  logic [1:0][2:0][3:0] deq_src_type;
  logic [1:0] deq_rob_flag;
  logic [1:0][7:0] deq_rob_value;
  logic [17:0][2:0][3:0] data_src;
  // 核的这几个出口：顶层有对应端口的接有名线（后面展开），没有的接悬空线
  logic [17:0][2:0][1:0] exu_src;
  logic [17:0][2:0][1:0] unused_ld_dep;
  logic [1:0][2:0][2:0][1:0] unused_deq_ld_dep;
  logic [1:0][2:0][0:0] unused_deq_rc_idx;
  logic [1:0] unused_cancel_deq;

  xs_iq_entries_core #(
    .NUM_ENQ(2), .NUM_SIMP(2), .NUM_COMP(14), .NUM_DEQ(2),
    .NUM_REGSRC(3), .NUM_WK_WB(6), .NUM_FU_BIT(3),
    .ROB_W(8), .PSRC_W(8), .PDEST_W(8),
    .PL_DEQ_W(546), .PL_TRANS_W(1330),
    .HAS_LD_DEP(1), .COMP_HAS_LD_DEP(0),
    .HAS_LD_CANCEL(0), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(3), .EXU_W(2),
    .IQ_SRC_MASK({3'b111, 3'b111, 3'b111}),
    .IQ_WEN_PRESENT(5'b00010),
    .IQD_WEN_PRESENT(5'b00010),
    .IQ_IS_LD_PIPE({3'b000, 3'b000, 3'b000}),
    .OG0_HAS_SRC(3'b001),
    .HAS_REG_CACHE(0), .RC_IDX_W(1),
    .IQ_WRITE_RC(3'b000), .RC_TYPE_BIT(0),
    .SRC_WB_MASK({6'b111111, 6'b111111, 6'b111111}),
    .SRC_MATCH_KIND({2'd0, 2'd0, 2'd0}),
    .WB_WEN_PRESENT(5'b00010),
    .WBD_WEN_PRESENT(5'b00010),
    .HAS_IGNORE_OLD_VD(0),
    .VD_SRC(0), .VL_SRC(0), .WB_VL_INT(0), .WB_VL_VF(0),
    .PLB_VM(805),
    .PLB_VMA(790),
    .PLB_VTA(791),
    .PLB_IS_DEPEND_OLDVD(981),
    .PLB_IS_WRITE_PARTVD(982),
    .OG_HAS_BITS(4'b0010),
    .OG_CONST_RESP({2'h0, 2'h0, 2'h0, 2'h0})
  ) u_core (
    .clock(clock), .reset(reset),
    .flush_valid(io_flush_valid), .flush_rob_flag(io_flush_bits_robIdx_flag),
    .flush_rob_value(io_flush_bits_robIdx_value), .flush_level(io_flush_bits_level),
    .enq_valid({io_enq_1_valid, io_enq_0_valid}),
    .enq_rob_flag({io_enq_1_bits_status_robIdx_flag, io_enq_0_bits_status_robIdx_flag}),
    .enq_rob_value({io_enq_1_bits_status_robIdx_value, io_enq_0_bits_status_robIdx_value}),
    .enq_fu_type({io_enq_1_bits_status_fuType_14, io_enq_1_bits_status_fuType_12, io_enq_1_bits_status_fuType_11, io_enq_0_bits_status_fuType_14, io_enq_0_bits_status_fuType_12, io_enq_0_bits_status_fuType_11}),
    .enq_psrc({io_enq_1_bits_status_srcStatus_2_psrc, io_enq_1_bits_status_srcStatus_1_psrc, io_enq_1_bits_status_srcStatus_0_psrc, io_enq_0_bits_status_srcStatus_2_psrc, io_enq_0_bits_status_srcStatus_1_psrc, io_enq_0_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_enq_1_bits_status_srcStatus_2_srcType, io_enq_1_bits_status_srcStatus_1_srcType, io_enq_1_bits_status_srcStatus_0_srcType, io_enq_0_bits_status_srcStatus_2_srcType, io_enq_0_bits_status_srcStatus_1_srcType, io_enq_0_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_enq_1_bits_status_srcStatus_2_srcState, io_enq_1_bits_status_srcStatus_1_srcState, io_enq_1_bits_status_srcStatus_0_srcState, io_enq_0_bits_status_srcStatus_2_srcState, io_enq_0_bits_status_srcStatus_1_srcState, io_enq_0_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_enq_1_bits_status_srcStatus_2_dataSources_value, io_enq_1_bits_status_srcStatus_1_dataSources_value, io_enq_1_bits_status_srcStatus_0_dataSources_value, io_enq_0_bits_status_srcStatus_2_dataSources_value, io_enq_0_bits_status_srcStatus_1_dataSources_value, io_enq_0_bits_status_srcStatus_0_dataSources_value}),
    .enq_payload(enq_payload),
    .enq_ld_dep('0), .enq_pl_ld_dep('0),
    .enq_use_rc('0), .enq_rc_idx('0),
    .iq_wen({{1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_2_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_1_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_0_bits_fpWen, 1'b0}}),
    .iq_pdest({io_wakeUpFromIQ_2_bits_pdest, io_wakeUpFromIQ_1_bits_pdest, io_wakeUpFromIQ_0_bits_pdest}),
    .iq_ld_dep('0),
    .iq_rc_dest('0),
    .iqd_wen({{1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_2_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_1_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_0_bits_fpWen, 1'b0}}),
    .iqd_pdest({io_wakeUpFromIQDelayed_2_bits_pdest, io_wakeUpFromIQDelayed_1_bits_pdest, io_wakeUpFromIQDelayed_0_bits_pdest}),
    .iqd_ld_dep('0),
    .iqd_rc_dest('0),
    .og0_cancel_sel({1'b0, 1'b0, io_og0Cancel_8}),
    .iq_is0lat({1'b0, 1'b0, io_wakeUpFromIQ_0_bits_is0Lat}),
    .iqd_is0lat({1'b0, 1'b0, io_wakeUpFromIQDelayed_0_bits_is0Lat}),
    .ld1_cancel('0),
    .ld2_cancel('0),
    .wk_valid({io_wakeUpFromWB_5_valid, io_wakeUpFromWB_4_valid, io_wakeUpFromWB_3_valid, io_wakeUpFromWB_2_valid, io_wakeUpFromWB_1_valid, io_wakeUpFromWB_0_valid}),
    .wk_wen({{1'b0, 1'b0, 1'b0, io_wakeUpFromWB_5_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWB_4_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWB_3_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWB_2_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWB_1_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWB_0_bits_fpWen, 1'b0}}),
    .wk_pdest({io_wakeUpFromWB_5_bits_pdest, io_wakeUpFromWB_4_bits_pdest, io_wakeUpFromWB_3_bits_pdest, io_wakeUpFromWB_2_bits_pdest, io_wakeUpFromWB_1_bits_pdest, io_wakeUpFromWB_0_bits_pdest}),
    .wkd_valid({io_wakeUpFromWBDelayed_5_valid, io_wakeUpFromWBDelayed_4_valid, io_wakeUpFromWBDelayed_3_valid, io_wakeUpFromWBDelayed_2_valid, io_wakeUpFromWBDelayed_1_valid, io_wakeUpFromWBDelayed_0_valid}),
    .wkd_wen({{1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_5_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_4_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_3_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_2_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_1_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_0_bits_fpWen, 1'b0}}),
    .wkd_pdest({io_wakeUpFromWBDelayed_5_bits_pdest, io_wakeUpFromWBDelayed_4_bits_pdest, io_wakeUpFromWBDelayed_3_bits_pdest, io_wakeUpFromWBDelayed_2_bits_pdest, io_wakeUpFromWBDelayed_1_bits_pdest, io_wakeUpFromWBDelayed_0_bits_pdest}),
    .vl_int_is_zero('0), .vl_int_is_vlmax('0),
    .vl_vf_is_zero('0), .vl_vf_is_vlmax('0),
    .og_valid({2'h0, {io_og1Resp_1_valid, io_og1Resp_0_valid}, {io_og0Resp_1_valid, io_og0Resp_0_valid}}),
    .og_resp({4'h0, {io_og1Resp_1_bits_resp, io_og1Resp_0_bits_resp}, 4'h0}),
    .deq_ready({io_deqReady_1, io_deqReady_0}),
    .deq_sel_oh_valid({io_deqSelOH_1_valid, io_deqSelOH_0_valid}),
    .deq_sel_oh({io_deqSelOH_1_bits, io_deqSelOH_0_bits}),
    .enq_oldest_sel({io_enqEntryOldestSel_1_bits, io_enqEntryOldestSel_0_bits}),
    .simp_oldest_valid({io_simpEntryOldestSel_1_valid, io_simpEntryOldestSel_0_valid}),
    .simp_oldest_sel({io_simpEntryOldestSel_1_bits, io_simpEntryOldestSel_0_bits}),
    .comp_oldest_valid({io_compEntryOldestSel_1_valid, io_compEntryOldestSel_0_valid}),
    .comp_oldest_sel({io_compEntryOldestSel_1_bits, io_compEntryOldestSel_0_bits}),
    .simp_deq_sel_vec({io_simpEntryDeqSelVec_1, io_simpEntryDeqSelVec_0}),
    .o_valid(io_valid), .o_issued(io_issued), .o_can_issue(io_canIssue),
    .o_exu_src(exu_src), .o_ld_dep(unused_ld_dep),
    .o_deq_ld_dep(unused_deq_ld_dep), .o_deq_rc_idx(unused_deq_rc_idx),
    .o_cancel_deq(unused_cancel_deq),
    .o_fu_type(fu_type_narrow), .o_data_src(data_src),
    .o_is_first_issue({io_isFirstIssue_1, io_isFirstIssue_0}),
    .o_deq_rob_flag(deq_rob_flag), .o_deq_rob_value(deq_rob_value),
    .o_deq_fu_type(deq_fu_type), .o_deq_psrc(deq_psrc),
    .o_deq_src_type(deq_src_type), .o_deq_payload(deq_payload),
    .o_simp_enq_sel_vec({io_simpEntryEnqSelVec_1, io_simpEntryEnqSelVec_0}),
    .o_comp_enq_sel_vec({io_compEntryEnqSelVec_1, io_compEntryEnqSelVec_0})
  );

  // fuType 输出：核只存本变体保留的 3 位，这里放回 35 位 one-hot 的原位置
  assign io_fuType_0 = {20'h0, fu_type_narrow[0][2], 1'h0, fu_type_narrow[0][1], fu_type_narrow[0][0], 11'h0};
  assign io_fuType_1 = {20'h0, fu_type_narrow[1][2], 1'h0, fu_type_narrow[1][1], fu_type_narrow[1][0], 11'h0};
  assign io_fuType_2 = {20'h0, fu_type_narrow[2][2], 1'h0, fu_type_narrow[2][1], fu_type_narrow[2][0], 11'h0};
  assign io_fuType_3 = {20'h0, fu_type_narrow[3][2], 1'h0, fu_type_narrow[3][1], fu_type_narrow[3][0], 11'h0};
  assign io_fuType_4 = {20'h0, fu_type_narrow[4][2], 1'h0, fu_type_narrow[4][1], fu_type_narrow[4][0], 11'h0};
  assign io_fuType_5 = {20'h0, fu_type_narrow[5][2], 1'h0, fu_type_narrow[5][1], fu_type_narrow[5][0], 11'h0};
  assign io_fuType_6 = {20'h0, fu_type_narrow[6][2], 1'h0, fu_type_narrow[6][1], fu_type_narrow[6][0], 11'h0};
  assign io_fuType_7 = {20'h0, fu_type_narrow[7][2], 1'h0, fu_type_narrow[7][1], fu_type_narrow[7][0], 11'h0};
  assign io_fuType_8 = {20'h0, fu_type_narrow[8][2], 1'h0, fu_type_narrow[8][1], fu_type_narrow[8][0], 11'h0};
  assign io_fuType_9 = {20'h0, fu_type_narrow[9][2], 1'h0, fu_type_narrow[9][1], fu_type_narrow[9][0], 11'h0};
  assign io_fuType_10 = {20'h0, fu_type_narrow[10][2], 1'h0, fu_type_narrow[10][1], fu_type_narrow[10][0], 11'h0};
  assign io_fuType_11 = {20'h0, fu_type_narrow[11][2], 1'h0, fu_type_narrow[11][1], fu_type_narrow[11][0], 11'h0};
  assign io_fuType_12 = {20'h0, fu_type_narrow[12][2], 1'h0, fu_type_narrow[12][1], fu_type_narrow[12][0], 11'h0};
  assign io_fuType_13 = {20'h0, fu_type_narrow[13][2], 1'h0, fu_type_narrow[13][1], fu_type_narrow[13][0], 11'h0};
  assign io_fuType_14 = {20'h0, fu_type_narrow[14][2], 1'h0, fu_type_narrow[14][1], fu_type_narrow[14][0], 11'h0};
  assign io_fuType_15 = {20'h0, fu_type_narrow[15][2], 1'h0, fu_type_narrow[15][1], fu_type_narrow[15][0], 11'h0};
  assign io_fuType_16 = {20'h0, fu_type_narrow[16][2], 1'h0, fu_type_narrow[16][1], fu_type_narrow[16][0], 11'h0};
  assign io_fuType_17 = {20'h0, fu_type_narrow[17][2], 1'h0, fu_type_narrow[17][1], fu_type_narrow[17][0], 11'h0};

  assign io_dataSources_0_0_value = data_src[0][0];
  assign io_dataSources_0_1_value = data_src[0][1];
  assign io_dataSources_0_2_value = data_src[0][2];
  assign io_dataSources_1_0_value = data_src[1][0];
  assign io_dataSources_1_1_value = data_src[1][1];
  assign io_dataSources_1_2_value = data_src[1][2];
  assign io_dataSources_2_0_value = data_src[2][0];
  assign io_dataSources_2_1_value = data_src[2][1];
  assign io_dataSources_2_2_value = data_src[2][2];
  assign io_dataSources_3_0_value = data_src[3][0];
  assign io_dataSources_3_1_value = data_src[3][1];
  assign io_dataSources_3_2_value = data_src[3][2];
  assign io_dataSources_4_0_value = data_src[4][0];
  assign io_dataSources_4_1_value = data_src[4][1];
  assign io_dataSources_4_2_value = data_src[4][2];
  assign io_dataSources_5_0_value = data_src[5][0];
  assign io_dataSources_5_1_value = data_src[5][1];
  assign io_dataSources_5_2_value = data_src[5][2];
  assign io_dataSources_6_0_value = data_src[6][0];
  assign io_dataSources_6_1_value = data_src[6][1];
  assign io_dataSources_6_2_value = data_src[6][2];
  assign io_dataSources_7_0_value = data_src[7][0];
  assign io_dataSources_7_1_value = data_src[7][1];
  assign io_dataSources_7_2_value = data_src[7][2];
  assign io_dataSources_8_0_value = data_src[8][0];
  assign io_dataSources_8_1_value = data_src[8][1];
  assign io_dataSources_8_2_value = data_src[8][2];
  assign io_dataSources_9_0_value = data_src[9][0];
  assign io_dataSources_9_1_value = data_src[9][1];
  assign io_dataSources_9_2_value = data_src[9][2];
  assign io_dataSources_10_0_value = data_src[10][0];
  assign io_dataSources_10_1_value = data_src[10][1];
  assign io_dataSources_10_2_value = data_src[10][2];
  assign io_dataSources_11_0_value = data_src[11][0];
  assign io_dataSources_11_1_value = data_src[11][1];
  assign io_dataSources_11_2_value = data_src[11][2];
  assign io_dataSources_12_0_value = data_src[12][0];
  assign io_dataSources_12_1_value = data_src[12][1];
  assign io_dataSources_12_2_value = data_src[12][2];
  assign io_dataSources_13_0_value = data_src[13][0];
  assign io_dataSources_13_1_value = data_src[13][1];
  assign io_dataSources_13_2_value = data_src[13][2];
  assign io_dataSources_14_0_value = data_src[14][0];
  assign io_dataSources_14_1_value = data_src[14][1];
  assign io_dataSources_14_2_value = data_src[14][2];
  assign io_dataSources_15_0_value = data_src[15][0];
  assign io_dataSources_15_1_value = data_src[15][1];
  assign io_dataSources_15_2_value = data_src[15][2];
  assign io_dataSources_16_0_value = data_src[16][0];
  assign io_dataSources_16_1_value = data_src[16][1];
  assign io_dataSources_16_2_value = data_src[16][2];
  assign io_dataSources_17_0_value = data_src[17][0];
  assign io_dataSources_17_1_value = data_src[17][1];
  assign io_dataSources_17_2_value = data_src[17][2];

  assign io_exuSources_0_0_value = exu_src[0][0];
  assign io_exuSources_0_1_value = exu_src[0][1];
  assign io_exuSources_0_2_value = exu_src[0][2];
  assign io_exuSources_1_0_value = exu_src[1][0];
  assign io_exuSources_1_1_value = exu_src[1][1];
  assign io_exuSources_1_2_value = exu_src[1][2];
  assign io_exuSources_2_0_value = exu_src[2][0];
  assign io_exuSources_2_1_value = exu_src[2][1];
  assign io_exuSources_2_2_value = exu_src[2][2];
  assign io_exuSources_3_0_value = exu_src[3][0];
  assign io_exuSources_3_1_value = exu_src[3][1];
  assign io_exuSources_3_2_value = exu_src[3][2];
  assign io_exuSources_4_0_value = exu_src[4][0];
  assign io_exuSources_4_1_value = exu_src[4][1];
  assign io_exuSources_4_2_value = exu_src[4][2];
  assign io_exuSources_5_0_value = exu_src[5][0];
  assign io_exuSources_5_1_value = exu_src[5][1];
  assign io_exuSources_5_2_value = exu_src[5][2];
  assign io_exuSources_6_0_value = exu_src[6][0];
  assign io_exuSources_6_1_value = exu_src[6][1];
  assign io_exuSources_6_2_value = exu_src[6][2];
  assign io_exuSources_7_0_value = exu_src[7][0];
  assign io_exuSources_7_1_value = exu_src[7][1];
  assign io_exuSources_7_2_value = exu_src[7][2];
  assign io_exuSources_8_0_value = exu_src[8][0];
  assign io_exuSources_8_1_value = exu_src[8][1];
  assign io_exuSources_8_2_value = exu_src[8][2];
  assign io_exuSources_9_0_value = exu_src[9][0];
  assign io_exuSources_9_1_value = exu_src[9][1];
  assign io_exuSources_9_2_value = exu_src[9][2];
  assign io_exuSources_10_0_value = exu_src[10][0];
  assign io_exuSources_10_1_value = exu_src[10][1];
  assign io_exuSources_10_2_value = exu_src[10][2];
  assign io_exuSources_11_0_value = exu_src[11][0];
  assign io_exuSources_11_1_value = exu_src[11][1];
  assign io_exuSources_11_2_value = exu_src[11][2];
  assign io_exuSources_12_0_value = exu_src[12][0];
  assign io_exuSources_12_1_value = exu_src[12][1];
  assign io_exuSources_12_2_value = exu_src[12][2];
  assign io_exuSources_13_0_value = exu_src[13][0];
  assign io_exuSources_13_1_value = exu_src[13][1];
  assign io_exuSources_13_2_value = exu_src[13][2];
  assign io_exuSources_14_0_value = exu_src[14][0];
  assign io_exuSources_14_1_value = exu_src[14][1];
  assign io_exuSources_14_2_value = exu_src[14][2];
  assign io_exuSources_15_0_value = exu_src[15][0];
  assign io_exuSources_15_1_value = exu_src[15][1];
  assign io_exuSources_15_2_value = exu_src[15][2];
  assign io_exuSources_16_0_value = exu_src[16][0];
  assign io_exuSources_16_1_value = exu_src[16][1];
  assign io_exuSources_16_2_value = exu_src[16][2];
  assign io_exuSources_17_0_value = exu_src[17][0];
  assign io_exuSources_17_1_value = exu_src[17][1];
  assign io_exuSources_17_2_value = exu_src[17][2];

  assign io_deqEntry_0_bits_status_robIdx_flag  = deq_rob_flag[0];
  assign io_deqEntry_0_bits_status_robIdx_value = deq_rob_value[0];
  assign io_deqEntry_0_bits_status_fuType_11 = deq_fu_type[0][0];
  assign io_deqEntry_0_bits_status_fuType_12 = deq_fu_type[0][1];
  assign io_deqEntry_0_bits_status_fuType_14 = deq_fu_type[0][2];
  assign io_deqEntry_0_bits_status_srcStatus_0_psrc    = deq_psrc[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_0_srcType = deq_src_type[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_1_psrc    = deq_psrc[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_1_srcType = deq_src_type[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_2_psrc    = deq_psrc[0][2];
  assign io_deqEntry_0_bits_status_srcStatus_2_srcType = deq_src_type[0][2];
  assign io_deqEntry_0_bits_payload_fuOpType = deq_payload[0][8:0];
  assign io_deqEntry_0_bits_payload_rfWen = deq_payload[0][9];
  assign io_deqEntry_0_bits_payload_fpWen = deq_payload[0][10];
  assign io_deqEntry_0_bits_payload_selImm = deq_payload[0][14:11];
  assign io_deqEntry_0_bits_payload_fpu_typeTagOut = deq_payload[0][16:15];
  assign io_deqEntry_0_bits_payload_fpu_wflags = deq_payload[0][17];
  assign io_deqEntry_0_bits_payload_fpu_typ = deq_payload[0][19:18];
  assign io_deqEntry_0_bits_payload_fpu_fmt = deq_payload[0][21:20];
  assign io_deqEntry_0_bits_payload_fpu_rm = deq_payload[0][24:22];
  assign io_deqEntry_0_bits_payload_pdest = deq_payload[0][32:25];
  assign io_deqEntry_0_bits_payload_debugInfo_eliminatedMove = deq_payload[0][33];
  assign io_deqEntry_0_bits_payload_debugInfo_renameTime = deq_payload[0][97:34];
  assign io_deqEntry_0_bits_payload_debugInfo_dispatchTime = deq_payload[0][161:98];
  assign io_deqEntry_0_bits_payload_debugInfo_enqRsTime = deq_payload[0][225:162];
  assign io_deqEntry_0_bits_payload_debugInfo_writebackTime = deq_payload[0][289:226];
  assign io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id = deq_payload[0][353:290];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime = deq_payload[0][417:354];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbRespTime = deq_payload[0][481:418];
  assign io_deqEntry_0_bits_payload_debug_seqNum_seqNum = deq_payload[0][537:482];
  assign io_deqEntry_0_bits_payload_debug_seqNum_uopIdx = deq_payload[0][545:538];
  assign io_deqEntry_1_bits_status_robIdx_flag  = deq_rob_flag[1];
  assign io_deqEntry_1_bits_status_robIdx_value = deq_rob_value[1];
  assign io_deqEntry_1_bits_status_fuType_11 = deq_fu_type[1][0];
  assign io_deqEntry_1_bits_status_fuType_12 = deq_fu_type[1][1];
  assign io_deqEntry_1_bits_status_fuType_14 = deq_fu_type[1][2];
  assign io_deqEntry_1_bits_status_srcStatus_0_psrc    = deq_psrc[1][0];
  assign io_deqEntry_1_bits_status_srcStatus_0_srcType = deq_src_type[1][0];
  assign io_deqEntry_1_bits_status_srcStatus_1_psrc    = deq_psrc[1][1];
  assign io_deqEntry_1_bits_status_srcStatus_1_srcType = deq_src_type[1][1];
  assign io_deqEntry_1_bits_payload_fuOpType = deq_payload[1][8:0];
  assign io_deqEntry_1_bits_payload_fpWen = deq_payload[1][10];
  assign io_deqEntry_1_bits_payload_selImm = deq_payload[1][14:11];
  assign io_deqEntry_1_bits_payload_fpu_typeTagOut = deq_payload[1][16:15];
  assign io_deqEntry_1_bits_payload_fpu_wflags = deq_payload[1][17];
  assign io_deqEntry_1_bits_payload_fpu_typ = deq_payload[1][19:18];
  assign io_deqEntry_1_bits_payload_fpu_fmt = deq_payload[1][21:20];
  assign io_deqEntry_1_bits_payload_fpu_rm = deq_payload[1][24:22];
  assign io_deqEntry_1_bits_payload_pdest = deq_payload[1][32:25];
  assign io_deqEntry_1_bits_payload_debugInfo_eliminatedMove = deq_payload[1][33];
  assign io_deqEntry_1_bits_payload_debugInfo_renameTime = deq_payload[1][97:34];
  assign io_deqEntry_1_bits_payload_debugInfo_dispatchTime = deq_payload[1][161:98];
  assign io_deqEntry_1_bits_payload_debugInfo_enqRsTime = deq_payload[1][225:162];
  assign io_deqEntry_1_bits_payload_debugInfo_writebackTime = deq_payload[1][289:226];
  assign io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id = deq_payload[1][353:290];
  assign io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime = deq_payload[1][417:354];
  assign io_deqEntry_1_bits_payload_debugInfo_tlbRespTime = deq_payload[1][481:418];
  assign io_deqEntry_1_bits_payload_debug_seqNum_seqNum = deq_payload[1][537:482];
  assign io_deqEntry_1_bits_payload_debug_seqNum_uopIdx = deq_payload[1][545:538];
  // END GENERATED(core-inst)

endmodule
