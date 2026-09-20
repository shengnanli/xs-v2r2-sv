// OthersEntry_150.sv —— 发射队列单条目（VfmaVialuFixVfalu 变体的 simp）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*
// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。
//
// 在流水线里的位置：一条等待发射的 uop 占一个条目。条目每拍监听写回(WB)与
// IQ 即时唤醒总线，把命中的源置就绪；「全源就绪 && 未发射 && 未阻塞 && 未冲刷」
// 即 canIssue，上层 Entries 在 canIssue 的条目里按年龄选最老的发射。
// 本条目角色：简单条目 simp（可被提级，产出 transEntry）
//   golden 里由 EntriesVfmaVialuFixVfalu 例化 2 份（实例名 othersEntriesSimp_*）。
//
// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的
//   Variant("EntriesVfmaVialuFixVfalu")，那份代码已断言 enq/simp/comp 三个 golden 模块
//   共用同一套唤醒路由与 og0 取消映射；逐模块才会不同的几样在本文件里另量）：
//   源寄存器 5 个，发射口 2 个（deqPortIdxRead 有）
//   WB 唤醒 16 路（无 IQ 唤醒、无 og0Cancel）
//   保留的 FuType one-hot 位：FuType[19], FuType[24], FuType[25]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位
//   负载：发射口可见 57 个字段 / 742 位；转移包另带 123 个字段，共 1330 位
//
// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出
//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool
//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。
//
// 自动生成：verif/ut/OthersEntry_150/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
// =============================================================================
module OthersEntry_150 (
  input          clock,
  input          reset,
  input          io_commonIn_flush_valid,
  input          io_commonIn_flush_bits_robIdx_flag,
  input  [7:0]   io_commonIn_flush_bits_robIdx_value,
  input          io_commonIn_flush_bits_level,
  input          io_commonIn_enq_valid,
  input          io_commonIn_enq_bits_status_robIdx_flag,
  input  [7:0]   io_commonIn_enq_bits_status_robIdx_value,
  input          io_commonIn_enq_bits_status_fuType_19,
  input          io_commonIn_enq_bits_status_fuType_24,
  input          io_commonIn_enq_bits_status_fuType_25,
  input  [6:0]   io_commonIn_enq_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2,
  input  [6:0]   io_commonIn_enq_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_1_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_1_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2,
  input  [6:0]   io_commonIn_enq_bits_status_srcStatus_2_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_2_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_2_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_2_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_2,
  input  [6:0]   io_commonIn_enq_bits_status_srcStatus_3_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_3_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_3_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_3_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_3_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_3_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_3_srcLoadDependency_2,
  input  [6:0]   io_commonIn_enq_bits_status_srcStatus_4_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_4_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_4_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_4_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_4_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_4_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_4_srcLoadDependency_2,
  input          io_commonIn_enq_bits_status_blocked,
  input          io_commonIn_enq_bits_status_issued,
  input          io_commonIn_enq_bits_status_firstIssue,
  input  [1:0]   io_commonIn_enq_bits_status_issueTimer,
  input          io_commonIn_enq_bits_status_deqPortIdx,
  input  [31:0]  io_commonIn_enq_bits_payload_instr,
  input  [49:0]  io_commonIn_enq_bits_payload_pc,
  input  [9:0]   io_commonIn_enq_bits_payload_foldpc,
  input          io_commonIn_enq_bits_payload_exceptionVec_0,
  input          io_commonIn_enq_bits_payload_exceptionVec_1,
  input          io_commonIn_enq_bits_payload_exceptionVec_2,
  input          io_commonIn_enq_bits_payload_exceptionVec_3,
  input          io_commonIn_enq_bits_payload_exceptionVec_4,
  input          io_commonIn_enq_bits_payload_exceptionVec_5,
  input          io_commonIn_enq_bits_payload_exceptionVec_6,
  input          io_commonIn_enq_bits_payload_exceptionVec_7,
  input          io_commonIn_enq_bits_payload_exceptionVec_8,
  input          io_commonIn_enq_bits_payload_exceptionVec_9,
  input          io_commonIn_enq_bits_payload_exceptionVec_10,
  input          io_commonIn_enq_bits_payload_exceptionVec_11,
  input          io_commonIn_enq_bits_payload_exceptionVec_12,
  input          io_commonIn_enq_bits_payload_exceptionVec_13,
  input          io_commonIn_enq_bits_payload_exceptionVec_14,
  input          io_commonIn_enq_bits_payload_exceptionVec_15,
  input          io_commonIn_enq_bits_payload_exceptionVec_16,
  input          io_commonIn_enq_bits_payload_exceptionVec_17,
  input          io_commonIn_enq_bits_payload_exceptionVec_18,
  input          io_commonIn_enq_bits_payload_exceptionVec_19,
  input          io_commonIn_enq_bits_payload_exceptionVec_20,
  input          io_commonIn_enq_bits_payload_exceptionVec_21,
  input          io_commonIn_enq_bits_payload_exceptionVec_22,
  input          io_commonIn_enq_bits_payload_exceptionVec_23,
  input          io_commonIn_enq_bits_payload_isFetchMalAddr,
  input          io_commonIn_enq_bits_payload_hasException,
  input  [3:0]   io_commonIn_enq_bits_payload_trigger,
  input          io_commonIn_enq_bits_payload_preDecodeInfo_valid,
  input          io_commonIn_enq_bits_payload_preDecodeInfo_isRVC,
  input  [1:0]   io_commonIn_enq_bits_payload_preDecodeInfo_brType,
  input          io_commonIn_enq_bits_payload_preDecodeInfo_isCall,
  input          io_commonIn_enq_bits_payload_preDecodeInfo_isRet,
  input          io_commonIn_enq_bits_payload_pred_taken,
  input          io_commonIn_enq_bits_payload_crossPageIPFFix,
  input          io_commonIn_enq_bits_payload_ftqPtr_flag,
  input  [5:0]   io_commonIn_enq_bits_payload_ftqPtr_value,
  input  [3:0]   io_commonIn_enq_bits_payload_ftqOffset,
  input          io_commonIn_enq_bits_payload_satpFlushFirstFetchFault,
  input  [3:0]   io_commonIn_enq_bits_payload_srcType_0,
  input  [3:0]   io_commonIn_enq_bits_payload_srcType_1,
  input  [3:0]   io_commonIn_enq_bits_payload_srcType_2,
  input  [3:0]   io_commonIn_enq_bits_payload_srcType_3,
  input  [3:0]   io_commonIn_enq_bits_payload_srcType_4,
  input  [5:0]   io_commonIn_enq_bits_payload_ldest,
  input  [34:0]  io_commonIn_enq_bits_payload_fuType,
  input  [8:0]   io_commonIn_enq_bits_payload_fuOpType,
  input          io_commonIn_enq_bits_payload_rfWen,
  input          io_commonIn_enq_bits_payload_fpWen,
  input          io_commonIn_enq_bits_payload_vecWen,
  input          io_commonIn_enq_bits_payload_v0Wen,
  input          io_commonIn_enq_bits_payload_vlWen,
  input          io_commonIn_enq_bits_payload_isXSTrap,
  input          io_commonIn_enq_bits_payload_waitForward,
  input          io_commonIn_enq_bits_payload_blockBackward,
  input          io_commonIn_enq_bits_payload_flushPipe,
  input          io_commonIn_enq_bits_payload_canRobCompress,
  input  [3:0]   io_commonIn_enq_bits_payload_selImm,
  input  [31:0]  io_commonIn_enq_bits_payload_imm,
  input  [1:0]   io_commonIn_enq_bits_payload_fpu_typeTagOut,
  input          io_commonIn_enq_bits_payload_fpu_wflags,
  input  [1:0]   io_commonIn_enq_bits_payload_fpu_typ,
  input  [1:0]   io_commonIn_enq_bits_payload_fpu_fmt,
  input  [2:0]   io_commonIn_enq_bits_payload_fpu_rm,
  input          io_commonIn_enq_bits_payload_vpu_vill,
  input          io_commonIn_enq_bits_payload_vpu_vma,
  input          io_commonIn_enq_bits_payload_vpu_vta,
  input  [1:0]   io_commonIn_enq_bits_payload_vpu_vsew,
  input  [2:0]   io_commonIn_enq_bits_payload_vpu_vlmul,
  input          io_commonIn_enq_bits_payload_vpu_specVill,
  input          io_commonIn_enq_bits_payload_vpu_specVma,
  input          io_commonIn_enq_bits_payload_vpu_specVta,
  input  [1:0]   io_commonIn_enq_bits_payload_vpu_specVsew,
  input  [2:0]   io_commonIn_enq_bits_payload_vpu_specVlmul,
  input          io_commonIn_enq_bits_payload_vpu_vm,
  input  [7:0]   io_commonIn_enq_bits_payload_vpu_vstart,
  input  [2:0]   io_commonIn_enq_bits_payload_vpu_frm,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isReduction,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4,
  input          io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_commonIn_enq_bits_payload_vpu_vxrm,
  input  [6:0]   io_commonIn_enq_bits_payload_vpu_vuopIdx,
  input          io_commonIn_enq_bits_payload_vpu_lastUop,
  input  [127:0] io_commonIn_enq_bits_payload_vpu_vmask,
  input  [7:0]   io_commonIn_enq_bits_payload_vpu_vl,
  input  [2:0]   io_commonIn_enq_bits_payload_vpu_nf,
  input  [1:0]   io_commonIn_enq_bits_payload_vpu_veew,
  input          io_commonIn_enq_bits_payload_vpu_isReverse,
  input          io_commonIn_enq_bits_payload_vpu_isExt,
  input          io_commonIn_enq_bits_payload_vpu_isNarrow,
  input          io_commonIn_enq_bits_payload_vpu_isDstMask,
  input          io_commonIn_enq_bits_payload_vpu_isOpMask,
  input          io_commonIn_enq_bits_payload_vpu_isMove,
  input          io_commonIn_enq_bits_payload_vpu_isDependOldVd,
  input          io_commonIn_enq_bits_payload_vpu_isWritePartVd,
  input          io_commonIn_enq_bits_payload_vpu_isVleff,
  input          io_commonIn_enq_bits_payload_vlsInstr,
  input          io_commonIn_enq_bits_payload_wfflags,
  input          io_commonIn_enq_bits_payload_isMove,
  input          io_commonIn_enq_bits_payload_isDropAmocasSta,
  input  [6:0]   io_commonIn_enq_bits_payload_uopIdx,
  input          io_commonIn_enq_bits_payload_isVset,
  input          io_commonIn_enq_bits_payload_firstUop,
  input          io_commonIn_enq_bits_payload_lastUop,
  input  [6:0]   io_commonIn_enq_bits_payload_numUops,
  input  [6:0]   io_commonIn_enq_bits_payload_numWB,
  input  [2:0]   io_commonIn_enq_bits_payload_commitType,
  input          io_commonIn_enq_bits_payload_srcState_0,
  input          io_commonIn_enq_bits_payload_srcState_1,
  input          io_commonIn_enq_bits_payload_srcState_2,
  input          io_commonIn_enq_bits_payload_srcState_3,
  input          io_commonIn_enq_bits_payload_srcState_4,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_0_0,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_0_1,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_0_2,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_1_0,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_1_1,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_1_2,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_2_0,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_2_1,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_2_2,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_3_0,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_3_1,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_3_2,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_4_0,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_4_1,
  input  [1:0]   io_commonIn_enq_bits_payload_srcLoadDependency_4_2,
  input  [7:0]   io_commonIn_enq_bits_payload_psrc_0,
  input  [7:0]   io_commonIn_enq_bits_payload_psrc_1,
  input  [7:0]   io_commonIn_enq_bits_payload_psrc_2,
  input  [7:0]   io_commonIn_enq_bits_payload_psrc_3,
  input  [7:0]   io_commonIn_enq_bits_payload_psrc_4,
  input  [7:0]   io_commonIn_enq_bits_payload_pdest,
  input          io_commonIn_enq_bits_payload_useRegCache_0,
  input          io_commonIn_enq_bits_payload_useRegCache_1,
  input  [4:0]   io_commonIn_enq_bits_payload_regCacheIdx_0,
  input  [4:0]   io_commonIn_enq_bits_payload_regCacheIdx_1,
  input          io_commonIn_enq_bits_payload_robIdx_flag,
  input  [7:0]   io_commonIn_enq_bits_payload_robIdx_value,
  input  [2:0]   io_commonIn_enq_bits_payload_instrSize,
  input          io_commonIn_enq_bits_payload_dirtyFs,
  input          io_commonIn_enq_bits_payload_dirtyVs,
  input  [3:0]   io_commonIn_enq_bits_payload_traceBlockInPipe_itype,
  input  [3:0]   io_commonIn_enq_bits_payload_traceBlockInPipe_iretire,
  input          io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize,
  input          io_commonIn_enq_bits_payload_eliminatedMove,
  input          io_commonIn_enq_bits_payload_snapshot,
  input          io_commonIn_enq_bits_payload_debugInfo_eliminatedMove,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_renameTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_dispatchTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_enqRsTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_selectTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_issueTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_writebackTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_commonIn_enq_bits_payload_debugInfo_tlbRespTime,
  input  [55:0]  io_commonIn_enq_bits_payload_debug_seqNum_seqNum,
  input  [7:0]   io_commonIn_enq_bits_payload_debug_seqNum_uopIdx,
  input          io_commonIn_enq_bits_payload_storeSetHit,
  input          io_commonIn_enq_bits_payload_waitForRobIdx_flag,
  input  [7:0]   io_commonIn_enq_bits_payload_waitForRobIdx_value,
  input          io_commonIn_enq_bits_payload_loadWaitBit,
  input          io_commonIn_enq_bits_payload_loadWaitStrict,
  input  [4:0]   io_commonIn_enq_bits_payload_ssid,
  input          io_commonIn_enq_bits_payload_lqIdx_flag,
  input  [6:0]   io_commonIn_enq_bits_payload_lqIdx_value,
  input          io_commonIn_enq_bits_payload_sqIdx_flag,
  input  [5:0]   io_commonIn_enq_bits_payload_sqIdx_value,
  input          io_commonIn_enq_bits_payload_singleStep,
  input          io_commonIn_enq_bits_payload_replayInst,
  input  [34:0]  io_commonIn_enq_bits_payload_debug_fuType,
  input          io_commonIn_enq_bits_payload_debug_sim_trig,
  input  [4:0]   io_commonIn_enq_bits_payload_numLsElem,
  input          io_commonIn_wakeUpFromWB_15_valid,
  input          io_commonIn_wakeUpFromWB_15_bits_vlWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_15_bits_pdest,
  input          io_commonIn_wakeUpFromWB_14_valid,
  input          io_commonIn_wakeUpFromWB_14_bits_vlWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_14_bits_pdest,
  input          io_commonIn_wakeUpFromWB_13_valid,
  input          io_commonIn_wakeUpFromWB_13_bits_vlWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_13_bits_pdest,
  input          io_commonIn_wakeUpFromWB_12_valid,
  input          io_commonIn_wakeUpFromWB_12_bits_vlWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_12_bits_pdest,
  input          io_commonIn_wakeUpFromWB_11_valid,
  input          io_commonIn_wakeUpFromWB_11_bits_v0Wen,
  input  [7:0]   io_commonIn_wakeUpFromWB_11_bits_pdest,
  input          io_commonIn_wakeUpFromWB_10_valid,
  input          io_commonIn_wakeUpFromWB_10_bits_v0Wen,
  input  [7:0]   io_commonIn_wakeUpFromWB_10_bits_pdest,
  input          io_commonIn_wakeUpFromWB_9_valid,
  input          io_commonIn_wakeUpFromWB_9_bits_v0Wen,
  input  [7:0]   io_commonIn_wakeUpFromWB_9_bits_pdest,
  input          io_commonIn_wakeUpFromWB_8_valid,
  input          io_commonIn_wakeUpFromWB_8_bits_v0Wen,
  input  [7:0]   io_commonIn_wakeUpFromWB_8_bits_pdest,
  input          io_commonIn_wakeUpFromWB_7_valid,
  input          io_commonIn_wakeUpFromWB_7_bits_v0Wen,
  input  [7:0]   io_commonIn_wakeUpFromWB_7_bits_pdest,
  input          io_commonIn_wakeUpFromWB_6_valid,
  input          io_commonIn_wakeUpFromWB_6_bits_v0Wen,
  input  [7:0]   io_commonIn_wakeUpFromWB_6_bits_pdest,
  input          io_commonIn_wakeUpFromWB_5_valid,
  input          io_commonIn_wakeUpFromWB_5_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_5_bits_pdest,
  input          io_commonIn_wakeUpFromWB_4_valid,
  input          io_commonIn_wakeUpFromWB_4_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_4_bits_pdest,
  input          io_commonIn_wakeUpFromWB_3_valid,
  input          io_commonIn_wakeUpFromWB_3_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_3_bits_pdest,
  input          io_commonIn_wakeUpFromWB_2_valid,
  input          io_commonIn_wakeUpFromWB_2_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_2_bits_pdest,
  input          io_commonIn_wakeUpFromWB_1_valid,
  input          io_commonIn_wakeUpFromWB_1_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_1_bits_pdest,
  input          io_commonIn_wakeUpFromWB_0_valid,
  input          io_commonIn_wakeUpFromWB_0_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_0_bits_pdest,
  input          io_commonIn_vlFromIntIsZero,
  input          io_commonIn_vlFromIntIsVlmax,
  input          io_commonIn_vlFromVfIsZero,
  input          io_commonIn_vlFromVfIsVlmax,
  input          io_commonIn_deqSel,
  input          io_commonIn_deqPortIdxWrite,
  input          io_commonIn_issueResp_valid,
  input  [1:0]   io_commonIn_issueResp_bits_resp,
  input          io_commonIn_transSel,
  output         io_commonOut_valid,
  output         io_commonOut_issued,
  output         io_commonOut_canIssue,
  output [34:0]  io_commonOut_fuType,
  output [3:0]   io_commonOut_dataSources_0_value,
  output [3:0]   io_commonOut_dataSources_1_value,
  output [3:0]   io_commonOut_dataSources_2_value,
  output [3:0]   io_commonOut_dataSources_3_value,
  output [3:0]   io_commonOut_dataSources_4_value,
  output         io_commonOut_isFirstIssue,
  output         io_commonOut_entry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_entry_bits_status_robIdx_value,
  output         io_commonOut_entry_bits_status_fuType_19,
  output         io_commonOut_entry_bits_status_fuType_24,
  output         io_commonOut_entry_bits_status_fuType_25,
  output [6:0]   io_commonOut_entry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_0_srcType,
  output [6:0]   io_commonOut_entry_bits_status_srcStatus_1_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_1_srcType,
  output [6:0]   io_commonOut_entry_bits_status_srcStatus_2_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_2_srcType,
  output [6:0]   io_commonOut_entry_bits_status_srcStatus_3_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_3_srcType,
  output [6:0]   io_commonOut_entry_bits_status_srcStatus_4_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_4_srcType,
  output [8:0]   io_commonOut_entry_bits_payload_fuOpType,
  output         io_commonOut_entry_bits_payload_fpWen,
  output         io_commonOut_entry_bits_payload_vecWen,
  output         io_commonOut_entry_bits_payload_v0Wen,
  output [3:0]   io_commonOut_entry_bits_payload_selImm,
  output [1:0]   io_commonOut_entry_bits_payload_fpu_typeTagOut,
  output         io_commonOut_entry_bits_payload_fpu_wflags,
  output [1:0]   io_commonOut_entry_bits_payload_fpu_typ,
  output [1:0]   io_commonOut_entry_bits_payload_fpu_fmt,
  output [2:0]   io_commonOut_entry_bits_payload_fpu_rm,
  output         io_commonOut_entry_bits_payload_vpu_vill,
  output         io_commonOut_entry_bits_payload_vpu_vma,
  output         io_commonOut_entry_bits_payload_vpu_vta,
  output [1:0]   io_commonOut_entry_bits_payload_vpu_vsew,
  output [2:0]   io_commonOut_entry_bits_payload_vpu_vlmul,
  output         io_commonOut_entry_bits_payload_vpu_specVill,
  output         io_commonOut_entry_bits_payload_vpu_specVma,
  output         io_commonOut_entry_bits_payload_vpu_specVta,
  output [1:0]   io_commonOut_entry_bits_payload_vpu_specVsew,
  output [2:0]   io_commonOut_entry_bits_payload_vpu_specVlmul,
  output         io_commonOut_entry_bits_payload_vpu_vm,
  output [7:0]   io_commonOut_entry_bits_payload_vpu_vstart,
  output [2:0]   io_commonOut_entry_bits_payload_vpu_frm,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isReduction,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4,
  output         io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_commonOut_entry_bits_payload_vpu_vxrm,
  output [127:0] io_commonOut_entry_bits_payload_vpu_vmask,
  output [7:0]   io_commonOut_entry_bits_payload_vpu_vl,
  output [2:0]   io_commonOut_entry_bits_payload_vpu_nf,
  output [1:0]   io_commonOut_entry_bits_payload_vpu_veew,
  output         io_commonOut_entry_bits_payload_vpu_isReverse,
  output         io_commonOut_entry_bits_payload_vpu_isExt,
  output         io_commonOut_entry_bits_payload_vpu_isNarrow,
  output         io_commonOut_entry_bits_payload_vpu_isDstMask,
  output         io_commonOut_entry_bits_payload_vpu_isOpMask,
  output         io_commonOut_entry_bits_payload_vpu_isMove,
  output         io_commonOut_entry_bits_payload_vpu_isDependOldVd,
  output         io_commonOut_entry_bits_payload_vpu_isWritePartVd,
  output         io_commonOut_entry_bits_payload_vpu_isVleff,
  output [6:0]   io_commonOut_entry_bits_payload_uopIdx,
  output         io_commonOut_entry_bits_payload_lastUop,
  output [7:0]   io_commonOut_entry_bits_payload_pdest,
  output         io_commonOut_entry_bits_payload_debugInfo_eliminatedMove,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_renameTime,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_dispatchTime,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_enqRsTime,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_writebackTime,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime,
  output [63:0]  io_commonOut_entry_bits_payload_debugInfo_tlbRespTime,
  output [55:0]  io_commonOut_entry_bits_payload_debug_seqNum_seqNum,
  output [7:0]   io_commonOut_entry_bits_payload_debug_seqNum_uopIdx,
  output         io_commonOut_deqPortIdxRead,
  output [1:0]   io_commonOut_issueTimerRead,
  output         io_commonOut_enqReady,
  output         io_commonOut_transEntry_valid,
  output         io_commonOut_transEntry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_transEntry_bits_status_robIdx_value,
  output         io_commonOut_transEntry_bits_status_fuType_19,
  output         io_commonOut_transEntry_bits_status_fuType_24,
  output         io_commonOut_transEntry_bits_status_fuType_25,
  output [6:0]   io_commonOut_transEntry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_0_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2,
  output [6:0]   io_commonOut_transEntry_bits_status_srcStatus_1_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_1_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2,
  output [6:0]   io_commonOut_transEntry_bits_status_srcStatus_2_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_2_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2,
  output [6:0]   io_commonOut_transEntry_bits_status_srcStatus_3_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_3_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_3_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2,
  output [6:0]   io_commonOut_transEntry_bits_status_srcStatus_4_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_4_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_4_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2,
  output         io_commonOut_transEntry_bits_status_issued,
  output         io_commonOut_transEntry_bits_status_firstIssue,
  output [1:0]   io_commonOut_transEntry_bits_status_issueTimer,
  output         io_commonOut_transEntry_bits_status_deqPortIdx,
  output [31:0]  io_commonOut_transEntry_bits_payload_instr,
  output [49:0]  io_commonOut_transEntry_bits_payload_pc,
  output [9:0]   io_commonOut_transEntry_bits_payload_foldpc,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_0,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_1,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_2,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_3,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_4,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_5,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_6,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_7,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_8,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_9,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_10,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_11,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_12,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_13,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_14,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_15,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_16,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_17,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_18,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_19,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_20,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_21,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_22,
  output         io_commonOut_transEntry_bits_payload_exceptionVec_23,
  output         io_commonOut_transEntry_bits_payload_isFetchMalAddr,
  output         io_commonOut_transEntry_bits_payload_hasException,
  output [3:0]   io_commonOut_transEntry_bits_payload_trigger,
  output         io_commonOut_transEntry_bits_payload_preDecodeInfo_valid,
  output         io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC,
  output [1:0]   io_commonOut_transEntry_bits_payload_preDecodeInfo_brType,
  output         io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall,
  output         io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet,
  output         io_commonOut_transEntry_bits_payload_pred_taken,
  output         io_commonOut_transEntry_bits_payload_crossPageIPFFix,
  output         io_commonOut_transEntry_bits_payload_ftqPtr_flag,
  output [5:0]   io_commonOut_transEntry_bits_payload_ftqPtr_value,
  output [3:0]   io_commonOut_transEntry_bits_payload_ftqOffset,
  output         io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault,
  output [3:0]   io_commonOut_transEntry_bits_payload_srcType_0,
  output [3:0]   io_commonOut_transEntry_bits_payload_srcType_1,
  output [3:0]   io_commonOut_transEntry_bits_payload_srcType_2,
  output [3:0]   io_commonOut_transEntry_bits_payload_srcType_3,
  output [3:0]   io_commonOut_transEntry_bits_payload_srcType_4,
  output [5:0]   io_commonOut_transEntry_bits_payload_ldest,
  output [34:0]  io_commonOut_transEntry_bits_payload_fuType,
  output [8:0]   io_commonOut_transEntry_bits_payload_fuOpType,
  output         io_commonOut_transEntry_bits_payload_rfWen,
  output         io_commonOut_transEntry_bits_payload_fpWen,
  output         io_commonOut_transEntry_bits_payload_vecWen,
  output         io_commonOut_transEntry_bits_payload_v0Wen,
  output         io_commonOut_transEntry_bits_payload_vlWen,
  output         io_commonOut_transEntry_bits_payload_isXSTrap,
  output         io_commonOut_transEntry_bits_payload_waitForward,
  output         io_commonOut_transEntry_bits_payload_blockBackward,
  output         io_commonOut_transEntry_bits_payload_flushPipe,
  output         io_commonOut_transEntry_bits_payload_canRobCompress,
  output [3:0]   io_commonOut_transEntry_bits_payload_selImm,
  output [31:0]  io_commonOut_transEntry_bits_payload_imm,
  output [1:0]   io_commonOut_transEntry_bits_payload_fpu_typeTagOut,
  output         io_commonOut_transEntry_bits_payload_fpu_wflags,
  output [1:0]   io_commonOut_transEntry_bits_payload_fpu_typ,
  output [1:0]   io_commonOut_transEntry_bits_payload_fpu_fmt,
  output [2:0]   io_commonOut_transEntry_bits_payload_fpu_rm,
  output         io_commonOut_transEntry_bits_payload_vpu_vill,
  output         io_commonOut_transEntry_bits_payload_vpu_vma,
  output         io_commonOut_transEntry_bits_payload_vpu_vta,
  output [1:0]   io_commonOut_transEntry_bits_payload_vpu_vsew,
  output [2:0]   io_commonOut_transEntry_bits_payload_vpu_vlmul,
  output         io_commonOut_transEntry_bits_payload_vpu_specVill,
  output         io_commonOut_transEntry_bits_payload_vpu_specVma,
  output         io_commonOut_transEntry_bits_payload_vpu_specVta,
  output [1:0]   io_commonOut_transEntry_bits_payload_vpu_specVsew,
  output [2:0]   io_commonOut_transEntry_bits_payload_vpu_specVlmul,
  output         io_commonOut_transEntry_bits_payload_vpu_vm,
  output [7:0]   io_commonOut_transEntry_bits_payload_vpu_vstart,
  output [2:0]   io_commonOut_transEntry_bits_payload_vpu_frm,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4,
  output         io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_commonOut_transEntry_bits_payload_vpu_vxrm,
  output [6:0]   io_commonOut_transEntry_bits_payload_vpu_vuopIdx,
  output         io_commonOut_transEntry_bits_payload_vpu_lastUop,
  output [127:0] io_commonOut_transEntry_bits_payload_vpu_vmask,
  output [7:0]   io_commonOut_transEntry_bits_payload_vpu_vl,
  output [2:0]   io_commonOut_transEntry_bits_payload_vpu_nf,
  output [1:0]   io_commonOut_transEntry_bits_payload_vpu_veew,
  output         io_commonOut_transEntry_bits_payload_vpu_isReverse,
  output         io_commonOut_transEntry_bits_payload_vpu_isExt,
  output         io_commonOut_transEntry_bits_payload_vpu_isNarrow,
  output         io_commonOut_transEntry_bits_payload_vpu_isDstMask,
  output         io_commonOut_transEntry_bits_payload_vpu_isOpMask,
  output         io_commonOut_transEntry_bits_payload_vpu_isMove,
  output         io_commonOut_transEntry_bits_payload_vpu_isDependOldVd,
  output         io_commonOut_transEntry_bits_payload_vpu_isWritePartVd,
  output         io_commonOut_transEntry_bits_payload_vpu_isVleff,
  output         io_commonOut_transEntry_bits_payload_vlsInstr,
  output         io_commonOut_transEntry_bits_payload_wfflags,
  output         io_commonOut_transEntry_bits_payload_isMove,
  output         io_commonOut_transEntry_bits_payload_isDropAmocasSta,
  output [6:0]   io_commonOut_transEntry_bits_payload_uopIdx,
  output         io_commonOut_transEntry_bits_payload_isVset,
  output         io_commonOut_transEntry_bits_payload_firstUop,
  output         io_commonOut_transEntry_bits_payload_lastUop,
  output [6:0]   io_commonOut_transEntry_bits_payload_numUops,
  output [6:0]   io_commonOut_transEntry_bits_payload_numWB,
  output [2:0]   io_commonOut_transEntry_bits_payload_commitType,
  output         io_commonOut_transEntry_bits_payload_srcState_0,
  output         io_commonOut_transEntry_bits_payload_srcState_1,
  output         io_commonOut_transEntry_bits_payload_srcState_2,
  output         io_commonOut_transEntry_bits_payload_srcState_3,
  output         io_commonOut_transEntry_bits_payload_srcState_4,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1,
  output [1:0]   io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2,
  output [7:0]   io_commonOut_transEntry_bits_payload_psrc_0,
  output [7:0]   io_commonOut_transEntry_bits_payload_psrc_1,
  output [7:0]   io_commonOut_transEntry_bits_payload_psrc_2,
  output [7:0]   io_commonOut_transEntry_bits_payload_psrc_3,
  output [7:0]   io_commonOut_transEntry_bits_payload_psrc_4,
  output [7:0]   io_commonOut_transEntry_bits_payload_pdest,
  output         io_commonOut_transEntry_bits_payload_useRegCache_0,
  output         io_commonOut_transEntry_bits_payload_useRegCache_1,
  output [4:0]   io_commonOut_transEntry_bits_payload_regCacheIdx_0,
  output [4:0]   io_commonOut_transEntry_bits_payload_regCacheIdx_1,
  output         io_commonOut_transEntry_bits_payload_robIdx_flag,
  output [7:0]   io_commonOut_transEntry_bits_payload_robIdx_value,
  output [2:0]   io_commonOut_transEntry_bits_payload_instrSize,
  output         io_commonOut_transEntry_bits_payload_dirtyFs,
  output         io_commonOut_transEntry_bits_payload_dirtyVs,
  output [3:0]   io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype,
  output [3:0]   io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire,
  output         io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize,
  output         io_commonOut_transEntry_bits_payload_eliminatedMove,
  output         io_commonOut_transEntry_bits_payload_snapshot,
  output         io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_renameTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_selectTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_issueTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_writebackTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime,
  output [63:0]  io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime,
  output [55:0]  io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum,
  output [7:0]   io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx,
  output         io_commonOut_transEntry_bits_payload_storeSetHit,
  output         io_commonOut_transEntry_bits_payload_waitForRobIdx_flag,
  output [7:0]   io_commonOut_transEntry_bits_payload_waitForRobIdx_value,
  output         io_commonOut_transEntry_bits_payload_loadWaitBit,
  output         io_commonOut_transEntry_bits_payload_loadWaitStrict,
  output [4:0]   io_commonOut_transEntry_bits_payload_ssid,
  output         io_commonOut_transEntry_bits_payload_lqIdx_flag,
  output [6:0]   io_commonOut_transEntry_bits_payload_lqIdx_value,
  output         io_commonOut_transEntry_bits_payload_sqIdx_flag,
  output [5:0]   io_commonOut_transEntry_bits_payload_sqIdx_value,
  output         io_commonOut_transEntry_bits_payload_singleStep,
  output         io_commonOut_transEntry_bits_payload_replayInst,
  output [34:0]  io_commonOut_transEntry_bits_payload_debug_fuType,
  output         io_commonOut_transEntry_bits_payload_debug_sim_trig,
  output [4:0]   io_commonOut_transEntry_bits_payload_numLsElem,
  output         io_commonOut_entryInValid,
  output         io_commonOut_entryOutDeqValid,
  output         io_commonOut_entryOutTransValid,
  output         io_commonOut_perfWakeupByWB_0,
  output         io_commonOut_perfWakeupByWB_1,
  output         io_commonOut_perfWakeupByWB_2,
  output         io_commonOut_perfWakeupByWB_3,
  output         io_commonOut_perfWakeupByWB_4
);

  // BEGIN GENERATED(core-inst)
  // 入队负载按 Variant 的偏移表拼成一根 1330 位向量（transEntry 整包）
  logic [1329:0] enq_payload;
  assign enq_payload = {io_commonIn_enq_bits_payload_numLsElem, io_commonIn_enq_bits_payload_debug_sim_trig, io_commonIn_enq_bits_payload_debug_fuType, io_commonIn_enq_bits_payload_replayInst, io_commonIn_enq_bits_payload_singleStep, io_commonIn_enq_bits_payload_sqIdx_value, io_commonIn_enq_bits_payload_sqIdx_flag, io_commonIn_enq_bits_payload_lqIdx_value, io_commonIn_enq_bits_payload_lqIdx_flag, io_commonIn_enq_bits_payload_ssid, io_commonIn_enq_bits_payload_loadWaitStrict, io_commonIn_enq_bits_payload_loadWaitBit, io_commonIn_enq_bits_payload_waitForRobIdx_value, io_commonIn_enq_bits_payload_waitForRobIdx_flag, io_commonIn_enq_bits_payload_storeSetHit, io_commonIn_enq_bits_payload_debugInfo_issueTime, io_commonIn_enq_bits_payload_debugInfo_selectTime, io_commonIn_enq_bits_payload_snapshot, io_commonIn_enq_bits_payload_eliminatedMove, io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize, io_commonIn_enq_bits_payload_traceBlockInPipe_iretire, io_commonIn_enq_bits_payload_traceBlockInPipe_itype, io_commonIn_enq_bits_payload_dirtyVs, io_commonIn_enq_bits_payload_dirtyFs, io_commonIn_enq_bits_payload_instrSize, io_commonIn_enq_bits_payload_robIdx_value, io_commonIn_enq_bits_payload_robIdx_flag, io_commonIn_enq_bits_payload_regCacheIdx_1, io_commonIn_enq_bits_payload_regCacheIdx_0, io_commonIn_enq_bits_payload_useRegCache_1, io_commonIn_enq_bits_payload_useRegCache_0, io_commonIn_enq_bits_payload_psrc_4, io_commonIn_enq_bits_payload_psrc_3, io_commonIn_enq_bits_payload_psrc_2, io_commonIn_enq_bits_payload_psrc_1, io_commonIn_enq_bits_payload_psrc_0, io_commonIn_enq_bits_payload_srcLoadDependency_4_2, io_commonIn_enq_bits_payload_srcLoadDependency_4_1, io_commonIn_enq_bits_payload_srcLoadDependency_4_0, io_commonIn_enq_bits_payload_srcLoadDependency_3_2, io_commonIn_enq_bits_payload_srcLoadDependency_3_1, io_commonIn_enq_bits_payload_srcLoadDependency_3_0, io_commonIn_enq_bits_payload_srcLoadDependency_2_2, io_commonIn_enq_bits_payload_srcLoadDependency_2_1, io_commonIn_enq_bits_payload_srcLoadDependency_2_0, io_commonIn_enq_bits_payload_srcLoadDependency_1_2, io_commonIn_enq_bits_payload_srcLoadDependency_1_1, io_commonIn_enq_bits_payload_srcLoadDependency_1_0, io_commonIn_enq_bits_payload_srcLoadDependency_0_2, io_commonIn_enq_bits_payload_srcLoadDependency_0_1, io_commonIn_enq_bits_payload_srcLoadDependency_0_0, io_commonIn_enq_bits_payload_srcState_4, io_commonIn_enq_bits_payload_srcState_3, io_commonIn_enq_bits_payload_srcState_2, io_commonIn_enq_bits_payload_srcState_1, io_commonIn_enq_bits_payload_srcState_0, io_commonIn_enq_bits_payload_commitType, io_commonIn_enq_bits_payload_numWB, io_commonIn_enq_bits_payload_numUops, io_commonIn_enq_bits_payload_firstUop, io_commonIn_enq_bits_payload_isVset, io_commonIn_enq_bits_payload_isDropAmocasSta, io_commonIn_enq_bits_payload_isMove, io_commonIn_enq_bits_payload_wfflags, io_commonIn_enq_bits_payload_vlsInstr, io_commonIn_enq_bits_payload_vpu_lastUop, io_commonIn_enq_bits_payload_vpu_vuopIdx, io_commonIn_enq_bits_payload_imm, io_commonIn_enq_bits_payload_canRobCompress, io_commonIn_enq_bits_payload_flushPipe, io_commonIn_enq_bits_payload_blockBackward, io_commonIn_enq_bits_payload_waitForward, io_commonIn_enq_bits_payload_isXSTrap, io_commonIn_enq_bits_payload_vlWen, io_commonIn_enq_bits_payload_rfWen, io_commonIn_enq_bits_payload_fuType, io_commonIn_enq_bits_payload_ldest, io_commonIn_enq_bits_payload_srcType_4, io_commonIn_enq_bits_payload_srcType_3, io_commonIn_enq_bits_payload_srcType_2, io_commonIn_enq_bits_payload_srcType_1, io_commonIn_enq_bits_payload_srcType_0, io_commonIn_enq_bits_payload_satpFlushFirstFetchFault, io_commonIn_enq_bits_payload_ftqOffset, io_commonIn_enq_bits_payload_ftqPtr_value, io_commonIn_enq_bits_payload_ftqPtr_flag, io_commonIn_enq_bits_payload_crossPageIPFFix, io_commonIn_enq_bits_payload_pred_taken, io_commonIn_enq_bits_payload_preDecodeInfo_isRet, io_commonIn_enq_bits_payload_preDecodeInfo_isCall, io_commonIn_enq_bits_payload_preDecodeInfo_brType, io_commonIn_enq_bits_payload_preDecodeInfo_isRVC, io_commonIn_enq_bits_payload_preDecodeInfo_valid, io_commonIn_enq_bits_payload_trigger, io_commonIn_enq_bits_payload_hasException, io_commonIn_enq_bits_payload_isFetchMalAddr, io_commonIn_enq_bits_payload_exceptionVec_23, io_commonIn_enq_bits_payload_exceptionVec_22, io_commonIn_enq_bits_payload_exceptionVec_21, io_commonIn_enq_bits_payload_exceptionVec_20, io_commonIn_enq_bits_payload_exceptionVec_19, io_commonIn_enq_bits_payload_exceptionVec_18, io_commonIn_enq_bits_payload_exceptionVec_17, io_commonIn_enq_bits_payload_exceptionVec_16, io_commonIn_enq_bits_payload_exceptionVec_15, io_commonIn_enq_bits_payload_exceptionVec_14, io_commonIn_enq_bits_payload_exceptionVec_13, io_commonIn_enq_bits_payload_exceptionVec_12, io_commonIn_enq_bits_payload_exceptionVec_11, io_commonIn_enq_bits_payload_exceptionVec_10, io_commonIn_enq_bits_payload_exceptionVec_9, io_commonIn_enq_bits_payload_exceptionVec_8, io_commonIn_enq_bits_payload_exceptionVec_7, io_commonIn_enq_bits_payload_exceptionVec_6, io_commonIn_enq_bits_payload_exceptionVec_5, io_commonIn_enq_bits_payload_exceptionVec_4, io_commonIn_enq_bits_payload_exceptionVec_3, io_commonIn_enq_bits_payload_exceptionVec_2, io_commonIn_enq_bits_payload_exceptionVec_1, io_commonIn_enq_bits_payload_exceptionVec_0, io_commonIn_enq_bits_payload_foldpc, io_commonIn_enq_bits_payload_pc, io_commonIn_enq_bits_payload_instr, io_commonIn_enq_bits_payload_debug_seqNum_uopIdx, io_commonIn_enq_bits_payload_debug_seqNum_seqNum, io_commonIn_enq_bits_payload_debugInfo_tlbRespTime, io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime, io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id, io_commonIn_enq_bits_payload_debugInfo_writebackTime, io_commonIn_enq_bits_payload_debugInfo_enqRsTime, io_commonIn_enq_bits_payload_debugInfo_dispatchTime, io_commonIn_enq_bits_payload_debugInfo_renameTime, io_commonIn_enq_bits_payload_debugInfo_eliminatedMove, io_commonIn_enq_bits_payload_pdest, io_commonIn_enq_bits_payload_lastUop, io_commonIn_enq_bits_payload_uopIdx, io_commonIn_enq_bits_payload_vpu_isVleff, io_commonIn_enq_bits_payload_vpu_isWritePartVd, io_commonIn_enq_bits_payload_vpu_isDependOldVd, io_commonIn_enq_bits_payload_vpu_isMove, io_commonIn_enq_bits_payload_vpu_isOpMask, io_commonIn_enq_bits_payload_vpu_isDstMask, io_commonIn_enq_bits_payload_vpu_isNarrow, io_commonIn_enq_bits_payload_vpu_isExt, io_commonIn_enq_bits_payload_vpu_isReverse, io_commonIn_enq_bits_payload_vpu_veew, io_commonIn_enq_bits_payload_vpu_nf, io_commonIn_enq_bits_payload_vpu_vl, io_commonIn_enq_bits_payload_vpu_vmask, io_commonIn_enq_bits_payload_vpu_vxrm, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2, io_commonIn_enq_bits_payload_vpu_fpu_isReduction, io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr, io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr, io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst, io_commonIn_enq_bits_payload_vpu_frm, io_commonIn_enq_bits_payload_vpu_vstart, io_commonIn_enq_bits_payload_vpu_vm, io_commonIn_enq_bits_payload_vpu_specVlmul, io_commonIn_enq_bits_payload_vpu_specVsew, io_commonIn_enq_bits_payload_vpu_specVta, io_commonIn_enq_bits_payload_vpu_specVma, io_commonIn_enq_bits_payload_vpu_specVill, io_commonIn_enq_bits_payload_vpu_vlmul, io_commonIn_enq_bits_payload_vpu_vsew, io_commonIn_enq_bits_payload_vpu_vta, io_commonIn_enq_bits_payload_vpu_vma, io_commonIn_enq_bits_payload_vpu_vill, io_commonIn_enq_bits_payload_fpu_rm, io_commonIn_enq_bits_payload_fpu_fmt, io_commonIn_enq_bits_payload_fpu_typ, io_commonIn_enq_bits_payload_fpu_wflags, io_commonIn_enq_bits_payload_fpu_typeTagOut, io_commonIn_enq_bits_payload_selImm, io_commonIn_enq_bits_payload_v0Wen, io_commonIn_enq_bits_payload_vecWen, io_commonIn_enq_bits_payload_fpWen, io_commonIn_enq_bits_payload_fuOpType};

  logic [2:0] fu_type_narrow;
  logic [4:0][3:0] data_src;
  logic [4:0][0:0] exu_src;
  logic [741:0] ety_payload;
  logic [4:0][6:0] ety_psrc;
  logic [4:0][3:0] ety_src_type;
  logic [4:0][2:0][1:0] ety_ld_dep;
  logic [4:0][0:0] ety_rc_idx;
  logic [1329:0] trans_payload;
  logic [4:0][6:0] trans_psrc;
  logic [4:0][3:0] trans_src_type, trans_data_src;
  logic [4:0] trans_src_state, trans_use_rc;
  logic [4:0][2:0][1:0] trans_ld_dep;
  logic [4:0][0:0] trans_exu_src;
  logic [4:0][0:0] trans_rc_idx;
  logic [2:0] trans_fu_type;
  logic unused_cancel_bypass;
  logic [4:0] unused_dbg_ld_cancel;
  logic [4:0] unused_dbg_og0_cancel;
  logic [4:0][0:0] unused_dbg_wakeup_by_iq;

  xs_iq_entry #(
    .IS_ENQ(0), .IS_TRANS(1), .IS_COMP(0),
    .NUM_DEQ_PORTS(2),
    .NUM_REGSRC(5), .NUM_WK_WB(16), .NUM_FU_BIT(3),
    .ROB_W(8), .PSRC_W(7), .PDEST_W(8),
    .PL_DEQ_W(742), .PL_TRANS_W(1330),
    .HAS_LD_DEP(1), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(0), .EXU_W(1),
    .SRC_WB_MASK({16'b1111000000000000, 16'b0000111111000000, 16'b0000000000111111, 16'b0000000000111111, 16'b0000000000111111}),
    .SRC_TYPE_BIT({3'd2, 3'd3, 3'd2, 3'd2, 3'd2}),
    .HAS_IGNORE_OLD_VD(1),
    .VD_SRC(2), .VL_SRC(4), .WB_VL_INT(12), .WB_VL_VF(13),
    .PLB_VM(42),
    .PLB_VMA(27),
    .PLB_VTA(28),
    .PLB_IS_DEPEND_OLDVD(210),
    .PLB_IS_WRITE_PARTVD(211),
    // ★ 条目单独成模块时 golden 有这 7 组 debug/perf 输出，故打开
    .HAS_DBG_OUT(1)
  ) u_entry (
    .clock(clock), .reset(reset),
    .flush_valid(io_commonIn_flush_valid),
    .flush_rob_flag(io_commonIn_flush_bits_robIdx_flag),
    .flush_rob_value(io_commonIn_flush_bits_robIdx_value),
    .flush_level(io_commonIn_flush_bits_level),
    .enq_valid(io_commonIn_enq_valid),
    .enq_rob_flag(io_commonIn_enq_bits_status_robIdx_flag),
    .enq_rob_value(io_commonIn_enq_bits_status_robIdx_value),
    .enq_fu_type({io_commonIn_enq_bits_status_fuType_25, io_commonIn_enq_bits_status_fuType_24, io_commonIn_enq_bits_status_fuType_19}),
    .enq_psrc({io_commonIn_enq_bits_status_srcStatus_4_psrc, io_commonIn_enq_bits_status_srcStatus_3_psrc, io_commonIn_enq_bits_status_srcStatus_2_psrc, io_commonIn_enq_bits_status_srcStatus_1_psrc, io_commonIn_enq_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_commonIn_enq_bits_status_srcStatus_4_srcType, io_commonIn_enq_bits_status_srcStatus_3_srcType, io_commonIn_enq_bits_status_srcStatus_2_srcType, io_commonIn_enq_bits_status_srcStatus_1_srcType, io_commonIn_enq_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_commonIn_enq_bits_status_srcStatus_4_srcState, io_commonIn_enq_bits_status_srcStatus_3_srcState, io_commonIn_enq_bits_status_srcStatus_2_srcState, io_commonIn_enq_bits_status_srcStatus_1_srcState, io_commonIn_enq_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_commonIn_enq_bits_status_srcStatus_4_dataSources_value, io_commonIn_enq_bits_status_srcStatus_3_dataSources_value, io_commonIn_enq_bits_status_srcStatus_2_dataSources_value, io_commonIn_enq_bits_status_srcStatus_1_dataSources_value, io_commonIn_enq_bits_status_srcStatus_0_dataSources_value}),
    .enq_blocked(io_commonIn_enq_bits_status_blocked),
    .enq_issued(io_commonIn_enq_bits_status_issued),
    .enq_first_issue(io_commonIn_enq_bits_status_firstIssue),
    .enq_issue_timer(io_commonIn_enq_bits_status_issueTimer),
    .enq_deq_port_idx(io_commonIn_enq_bits_status_deqPortIdx),
    .enq_payload(enq_payload),
    .enq_ld_dep({io_commonIn_enq_bits_status_srcStatus_4_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_4_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_4_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_3_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_3_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_3_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0}),
    .enq_exu_src('0),
    .enq_use_rc('0),
    .enq_rc_idx('0),
    .wk_valid({io_commonIn_wakeUpFromWB_15_valid, io_commonIn_wakeUpFromWB_14_valid, io_commonIn_wakeUpFromWB_13_valid, io_commonIn_wakeUpFromWB_12_valid, io_commonIn_wakeUpFromWB_11_valid, io_commonIn_wakeUpFromWB_10_valid, io_commonIn_wakeUpFromWB_9_valid, io_commonIn_wakeUpFromWB_8_valid, io_commonIn_wakeUpFromWB_7_valid, io_commonIn_wakeUpFromWB_6_valid, io_commonIn_wakeUpFromWB_5_valid, io_commonIn_wakeUpFromWB_4_valid, io_commonIn_wakeUpFromWB_3_valid, io_commonIn_wakeUpFromWB_2_valid, io_commonIn_wakeUpFromWB_1_valid, io_commonIn_wakeUpFromWB_0_valid}),
    .wk_wen({io_commonIn_wakeUpFromWB_15_bits_vlWen, io_commonIn_wakeUpFromWB_14_bits_vlWen, io_commonIn_wakeUpFromWB_13_bits_vlWen, io_commonIn_wakeUpFromWB_12_bits_vlWen, io_commonIn_wakeUpFromWB_11_bits_v0Wen, io_commonIn_wakeUpFromWB_10_bits_v0Wen, io_commonIn_wakeUpFromWB_9_bits_v0Wen, io_commonIn_wakeUpFromWB_8_bits_v0Wen, io_commonIn_wakeUpFromWB_7_bits_v0Wen, io_commonIn_wakeUpFromWB_6_bits_v0Wen, io_commonIn_wakeUpFromWB_5_bits_vecWen, io_commonIn_wakeUpFromWB_4_bits_vecWen, io_commonIn_wakeUpFromWB_3_bits_vecWen, io_commonIn_wakeUpFromWB_2_bits_vecWen, io_commonIn_wakeUpFromWB_1_bits_vecWen, io_commonIn_wakeUpFromWB_0_bits_vecWen}),
    .wk_pdest({io_commonIn_wakeUpFromWB_15_bits_pdest, io_commonIn_wakeUpFromWB_14_bits_pdest, io_commonIn_wakeUpFromWB_13_bits_pdest, io_commonIn_wakeUpFromWB_12_bits_pdest, io_commonIn_wakeUpFromWB_11_bits_pdest, io_commonIn_wakeUpFromWB_10_bits_pdest, io_commonIn_wakeUpFromWB_9_bits_pdest, io_commonIn_wakeUpFromWB_8_bits_pdest, io_commonIn_wakeUpFromWB_7_bits_pdest, io_commonIn_wakeUpFromWB_6_bits_pdest, io_commonIn_wakeUpFromWB_5_bits_pdest, io_commonIn_wakeUpFromWB_4_bits_pdest, io_commonIn_wakeUpFromWB_3_bits_pdest, io_commonIn_wakeUpFromWB_2_bits_pdest, io_commonIn_wakeUpFromWB_1_bits_pdest, io_commonIn_wakeUpFromWB_0_bits_pdest}),
    // ★ 入队延迟窗口只有 EnqEntry 有（IS_ENQ=1）；OthersEntry 的 golden
    //   根本没有 wakeUpFromWBDelayed / enqDelay 这组端口，故整组钉 0
    .wkd_valid('0), .wkd_wen('0), .wkd_pdest('0),
    .iq_wen('0), .iq_pdest('0), .iq_ld_dep('0), .iq_rc_dest('0),
    .iq_cancel('0),
    .iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0),
    .iqd_cancel('0),
    .ld1_cancel('0),
    .ld2_cancel('0),
    .ld1d_cancel('0), .ld2d_cancel('0), .enqd_self_ld_dep('0),
    .vl_int_is_zero(io_commonIn_vlFromIntIsZero),
    .vl_int_is_vlmax(io_commonIn_vlFromIntIsVlmax),
    .vl_vf_is_zero(io_commonIn_vlFromVfIsZero),
    .vl_vf_is_vlmax(io_commonIn_vlFromVfIsVlmax),
    .deq_sel(io_commonIn_deqSel),
    .deq_port_idx_write(io_commonIn_deqPortIdxWrite),
    .resp_valid(io_commonIn_issueResp_valid),
    .resp_bits(io_commonIn_issueResp_bits_resp),
    .trans_sel(io_commonIn_transSel),
    .o_valid(io_commonOut_valid), .o_issued(io_commonOut_issued),
    .o_can_issue(io_commonOut_canIssue),
    .o_cancel_bypass(unused_cancel_bypass),
    .o_is_first_issue(io_commonOut_isFirstIssue),
    .o_fu_type(fu_type_narrow), .o_data_src(data_src),
    .o_issue_timer(io_commonOut_issueTimerRead),
    .o_deq_port_idx(io_commonOut_deqPortIdxRead),
    .o_enq_ready(io_commonOut_enqReady),
    .o_ety_rob_flag(io_commonOut_entry_bits_status_robIdx_flag),
    .o_ety_rob_value(io_commonOut_entry_bits_status_robIdx_value),
    .o_ety_psrc(ety_psrc), .o_ety_src_type(ety_src_type),
    .o_ety_payload(ety_payload), .o_ety_ld_dep(ety_ld_dep),
    .o_ety_rc_idx(ety_rc_idx), .o_exu_src(exu_src),
    .o_trans_valid(io_commonOut_transEntry_valid),
    .o_trans_rob_flag(io_commonOut_transEntry_bits_status_robIdx_flag),
    .o_trans_rob_value(io_commonOut_transEntry_bits_status_robIdx_value),
    .o_trans_fu_type(trans_fu_type),
    .o_trans_psrc(trans_psrc),
    .o_trans_src_type(trans_src_type),
    .o_trans_src_state(trans_src_state),
    .o_trans_data_src(trans_data_src),
    .o_trans_payload(trans_payload),
    .o_trans_ld_dep(trans_ld_dep),
    .o_trans_exu_src(trans_exu_src),
    .o_trans_use_rc(trans_use_rc),
    .o_trans_rc_idx(trans_rc_idx),
    .o_trans_blocked(unused_trans_blocked),
    .o_trans_issued(io_commonOut_transEntry_bits_status_issued),
    .o_trans_first_issue(io_commonOut_transEntry_bits_status_firstIssue),
    .o_trans_issue_timer(io_commonOut_transEntry_bits_status_issueTimer),
    .o_trans_deq_port_idx(io_commonOut_transEntry_bits_status_deqPortIdx),
    // golden 的 7 组 debug/perf 输出（EntryBundles.scala:476-483）
    .o_dbg_entry_in_valid(io_commonOut_entryInValid),
    .o_dbg_entry_out_deq_valid(io_commonOut_entryOutDeqValid),
    .o_dbg_entry_out_trans_valid(io_commonOut_entryOutTransValid),
    .o_dbg_perf_ld_cancel(unused_dbg_ld_cancel),
    .o_dbg_perf_og0_cancel(unused_dbg_og0_cancel),
    .o_dbg_perf_wakeup_by_wb({io_commonOut_perfWakeupByWB_4, io_commonOut_perfWakeupByWB_3, io_commonOut_perfWakeupByWB_2, io_commonOut_perfWakeupByWB_1, io_commonOut_perfWakeupByWB_0}),
    .o_dbg_perf_wakeup_by_iq(unused_dbg_wakeup_by_iq)
  );

  // fuType 出口：核只存本变体保留的 3 位，这里放回 35 位 one-hot 的原位置
  assign io_commonOut_fuType = {9'h0, fu_type_narrow[2], fu_type_narrow[1], 4'h0, fu_type_narrow[0], 19'h0};

  assign io_commonOut_dataSources_0_value = data_src[0];
  assign io_commonOut_dataSources_1_value = data_src[1];
  assign io_commonOut_dataSources_2_value = data_src[2];
  assign io_commonOut_dataSources_3_value = data_src[3];
  assign io_commonOut_dataSources_4_value = data_src[4];

  // commonOut.entry.bits.status —— fuType 与 commonOut.fuType 同一组寄存器
  assign io_commonOut_entry_bits_status_fuType_19 = fu_type_narrow[0];
  assign io_commonOut_entry_bits_status_fuType_24 = fu_type_narrow[1];
  assign io_commonOut_entry_bits_status_fuType_25 = fu_type_narrow[2];
  assign io_commonOut_entry_bits_status_srcStatus_0_psrc = ety_psrc[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcType = ety_src_type[0];
  assign io_commonOut_entry_bits_status_srcStatus_1_psrc = ety_psrc[1];
  assign io_commonOut_entry_bits_status_srcStatus_1_srcType = ety_src_type[1];
  assign io_commonOut_entry_bits_status_srcStatus_2_psrc = ety_psrc[2];
  assign io_commonOut_entry_bits_status_srcStatus_2_srcType = ety_src_type[2];
  assign io_commonOut_entry_bits_status_srcStatus_3_psrc = ety_psrc[3];
  assign io_commonOut_entry_bits_status_srcStatus_3_srcType = ety_src_type[3];
  assign io_commonOut_entry_bits_status_srcStatus_4_psrc = ety_psrc[4];
  assign io_commonOut_entry_bits_status_srcStatus_4_srcType = ety_src_type[4];
  assign io_commonOut_entry_bits_payload_fuOpType = ety_payload[8:0];
  assign io_commonOut_entry_bits_payload_fpWen = ety_payload[9];
  assign io_commonOut_entry_bits_payload_vecWen = ety_payload[10];
  assign io_commonOut_entry_bits_payload_v0Wen = ety_payload[11];
  assign io_commonOut_entry_bits_payload_selImm = ety_payload[15:12];
  assign io_commonOut_entry_bits_payload_fpu_typeTagOut = ety_payload[17:16];
  assign io_commonOut_entry_bits_payload_fpu_wflags = ety_payload[18];
  assign io_commonOut_entry_bits_payload_fpu_typ = ety_payload[20:19];
  assign io_commonOut_entry_bits_payload_fpu_fmt = ety_payload[22:21];
  assign io_commonOut_entry_bits_payload_fpu_rm = ety_payload[25:23];
  assign io_commonOut_entry_bits_payload_vpu_vill = ety_payload[26];
  assign io_commonOut_entry_bits_payload_vpu_vma = ety_payload[27];
  assign io_commonOut_entry_bits_payload_vpu_vta = ety_payload[28];
  assign io_commonOut_entry_bits_payload_vpu_vsew = ety_payload[30:29];
  assign io_commonOut_entry_bits_payload_vpu_vlmul = ety_payload[33:31];
  assign io_commonOut_entry_bits_payload_vpu_specVill = ety_payload[34];
  assign io_commonOut_entry_bits_payload_vpu_specVma = ety_payload[35];
  assign io_commonOut_entry_bits_payload_vpu_specVta = ety_payload[36];
  assign io_commonOut_entry_bits_payload_vpu_specVsew = ety_payload[38:37];
  assign io_commonOut_entry_bits_payload_vpu_specVlmul = ety_payload[41:39];
  assign io_commonOut_entry_bits_payload_vpu_vm = ety_payload[42];
  assign io_commonOut_entry_bits_payload_vpu_vstart = ety_payload[50:43];
  assign io_commonOut_entry_bits_payload_vpu_frm = ety_payload[53:51];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isFpToVecInst = ety_payload[54];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isFP32Instr = ety_payload[55];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isFP64Instr = ety_payload[56];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isReduction = ety_payload[57];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_2 = ety_payload[58];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_4 = ety_payload[59];
  assign io_commonOut_entry_bits_payload_vpu_fpu_isFoldTo1_8 = ety_payload[60];
  assign io_commonOut_entry_bits_payload_vpu_vxrm = ety_payload[62:61];
  assign io_commonOut_entry_bits_payload_vpu_vmask = ety_payload[190:63];
  assign io_commonOut_entry_bits_payload_vpu_vl = ety_payload[198:191];
  assign io_commonOut_entry_bits_payload_vpu_nf = ety_payload[201:199];
  assign io_commonOut_entry_bits_payload_vpu_veew = ety_payload[203:202];
  assign io_commonOut_entry_bits_payload_vpu_isReverse = ety_payload[204];
  assign io_commonOut_entry_bits_payload_vpu_isExt = ety_payload[205];
  assign io_commonOut_entry_bits_payload_vpu_isNarrow = ety_payload[206];
  assign io_commonOut_entry_bits_payload_vpu_isDstMask = ety_payload[207];
  assign io_commonOut_entry_bits_payload_vpu_isOpMask = ety_payload[208];
  assign io_commonOut_entry_bits_payload_vpu_isMove = ety_payload[209];
  assign io_commonOut_entry_bits_payload_vpu_isDependOldVd = ety_payload[210];
  assign io_commonOut_entry_bits_payload_vpu_isWritePartVd = ety_payload[211];
  assign io_commonOut_entry_bits_payload_vpu_isVleff = ety_payload[212];
  assign io_commonOut_entry_bits_payload_uopIdx = ety_payload[219:213];
  assign io_commonOut_entry_bits_payload_lastUop = ety_payload[220];
  assign io_commonOut_entry_bits_payload_pdest = ety_payload[228:221];
  assign io_commonOut_entry_bits_payload_debugInfo_eliminatedMove = ety_payload[229];
  assign io_commonOut_entry_bits_payload_debugInfo_renameTime = ety_payload[293:230];
  assign io_commonOut_entry_bits_payload_debugInfo_dispatchTime = ety_payload[357:294];
  assign io_commonOut_entry_bits_payload_debugInfo_enqRsTime = ety_payload[421:358];
  assign io_commonOut_entry_bits_payload_debugInfo_writebackTime = ety_payload[485:422];
  assign io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id = ety_payload[549:486];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime = ety_payload[613:550];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbRespTime = ety_payload[677:614];
  assign io_commonOut_entry_bits_payload_debug_seqNum_seqNum = ety_payload[733:678];
  assign io_commonOut_entry_bits_payload_debug_seqNum_uopIdx = ety_payload[741:734];

  // commonOut.transEntry —— 交给下一级的整包（= entryUpdate）
  assign io_commonOut_transEntry_bits_status_fuType_19 = trans_fu_type[0];
  assign io_commonOut_transEntry_bits_status_fuType_24 = trans_fu_type[1];
  assign io_commonOut_transEntry_bits_status_fuType_25 = trans_fu_type[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_psrc = trans_psrc[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcType = trans_src_type[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcState = trans_src_state[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value = trans_data_src[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0 = trans_ld_dep[0][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1 = trans_ld_dep[0][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2 = trans_ld_dep[0][2];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_psrc = trans_psrc[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcType = trans_src_type[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcState = trans_src_state[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value = trans_data_src[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0 = trans_ld_dep[1][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1 = trans_ld_dep[1][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2 = trans_ld_dep[1][2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_psrc = trans_psrc[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcType = trans_src_type[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcState = trans_src_state[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value = trans_data_src[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0 = trans_ld_dep[2][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1 = trans_ld_dep[2][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2 = trans_ld_dep[2][2];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_psrc = trans_psrc[3];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_srcType = trans_src_type[3];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_srcState = trans_src_state[3];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_dataSources_value = trans_data_src[3];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_0 = trans_ld_dep[3][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_1 = trans_ld_dep[3][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_3_srcLoadDependency_2 = trans_ld_dep[3][2];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_psrc = trans_psrc[4];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_srcType = trans_src_type[4];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_srcState = trans_src_state[4];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_dataSources_value = trans_data_src[4];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_0 = trans_ld_dep[4][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_1 = trans_ld_dep[4][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_4_srcLoadDependency_2 = trans_ld_dep[4][2];
  assign io_commonOut_transEntry_bits_payload_fuOpType = trans_payload[8:0];
  assign io_commonOut_transEntry_bits_payload_fpWen = trans_payload[9];
  assign io_commonOut_transEntry_bits_payload_vecWen = trans_payload[10];
  assign io_commonOut_transEntry_bits_payload_v0Wen = trans_payload[11];
  assign io_commonOut_transEntry_bits_payload_selImm = trans_payload[15:12];
  assign io_commonOut_transEntry_bits_payload_fpu_typeTagOut = trans_payload[17:16];
  assign io_commonOut_transEntry_bits_payload_fpu_wflags = trans_payload[18];
  assign io_commonOut_transEntry_bits_payload_fpu_typ = trans_payload[20:19];
  assign io_commonOut_transEntry_bits_payload_fpu_fmt = trans_payload[22:21];
  assign io_commonOut_transEntry_bits_payload_fpu_rm = trans_payload[25:23];
  assign io_commonOut_transEntry_bits_payload_vpu_vill = trans_payload[26];
  assign io_commonOut_transEntry_bits_payload_vpu_vma = trans_payload[27];
  assign io_commonOut_transEntry_bits_payload_vpu_vta = trans_payload[28];
  assign io_commonOut_transEntry_bits_payload_vpu_vsew = trans_payload[30:29];
  assign io_commonOut_transEntry_bits_payload_vpu_vlmul = trans_payload[33:31];
  assign io_commonOut_transEntry_bits_payload_vpu_specVill = trans_payload[34];
  assign io_commonOut_transEntry_bits_payload_vpu_specVma = trans_payload[35];
  assign io_commonOut_transEntry_bits_payload_vpu_specVta = trans_payload[36];
  assign io_commonOut_transEntry_bits_payload_vpu_specVsew = trans_payload[38:37];
  assign io_commonOut_transEntry_bits_payload_vpu_specVlmul = trans_payload[41:39];
  assign io_commonOut_transEntry_bits_payload_vpu_vm = trans_payload[42];
  assign io_commonOut_transEntry_bits_payload_vpu_vstart = trans_payload[50:43];
  assign io_commonOut_transEntry_bits_payload_vpu_frm = trans_payload[53:51];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst = trans_payload[54];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr = trans_payload[55];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr = trans_payload[56];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction = trans_payload[57];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2 = trans_payload[58];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4 = trans_payload[59];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8 = trans_payload[60];
  assign io_commonOut_transEntry_bits_payload_vpu_vxrm = trans_payload[62:61];
  assign io_commonOut_transEntry_bits_payload_vpu_vmask = trans_payload[190:63];
  assign io_commonOut_transEntry_bits_payload_vpu_vl = trans_payload[198:191];
  assign io_commonOut_transEntry_bits_payload_vpu_nf = trans_payload[201:199];
  assign io_commonOut_transEntry_bits_payload_vpu_veew = trans_payload[203:202];
  assign io_commonOut_transEntry_bits_payload_vpu_isReverse = trans_payload[204];
  assign io_commonOut_transEntry_bits_payload_vpu_isExt = trans_payload[205];
  assign io_commonOut_transEntry_bits_payload_vpu_isNarrow = trans_payload[206];
  assign io_commonOut_transEntry_bits_payload_vpu_isDstMask = trans_payload[207];
  assign io_commonOut_transEntry_bits_payload_vpu_isOpMask = trans_payload[208];
  assign io_commonOut_transEntry_bits_payload_vpu_isMove = trans_payload[209];
  assign io_commonOut_transEntry_bits_payload_vpu_isDependOldVd = trans_payload[210];
  assign io_commonOut_transEntry_bits_payload_vpu_isWritePartVd = trans_payload[211];
  assign io_commonOut_transEntry_bits_payload_vpu_isVleff = trans_payload[212];
  assign io_commonOut_transEntry_bits_payload_uopIdx = trans_payload[219:213];
  assign io_commonOut_transEntry_bits_payload_lastUop = trans_payload[220];
  assign io_commonOut_transEntry_bits_payload_pdest = trans_payload[228:221];
  assign io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove = trans_payload[229];
  assign io_commonOut_transEntry_bits_payload_debugInfo_renameTime = trans_payload[293:230];
  assign io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime = trans_payload[357:294];
  assign io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime = trans_payload[421:358];
  assign io_commonOut_transEntry_bits_payload_debugInfo_writebackTime = trans_payload[485:422];
  assign io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id = trans_payload[549:486];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime = trans_payload[613:550];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime = trans_payload[677:614];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum = trans_payload[733:678];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx = trans_payload[741:734];
  assign io_commonOut_transEntry_bits_payload_instr = trans_payload[773:742];
  assign io_commonOut_transEntry_bits_payload_pc = trans_payload[823:774];
  assign io_commonOut_transEntry_bits_payload_foldpc = trans_payload[833:824];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_0 = trans_payload[834];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_1 = trans_payload[835];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_2 = trans_payload[836];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_3 = trans_payload[837];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_4 = trans_payload[838];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_5 = trans_payload[839];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_6 = trans_payload[840];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_7 = trans_payload[841];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_8 = trans_payload[842];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_9 = trans_payload[843];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_10 = trans_payload[844];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_11 = trans_payload[845];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_12 = trans_payload[846];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_13 = trans_payload[847];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_14 = trans_payload[848];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_15 = trans_payload[849];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_16 = trans_payload[850];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_17 = trans_payload[851];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_18 = trans_payload[852];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_19 = trans_payload[853];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_20 = trans_payload[854];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_21 = trans_payload[855];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_22 = trans_payload[856];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_23 = trans_payload[857];
  assign io_commonOut_transEntry_bits_payload_isFetchMalAddr = trans_payload[858];
  assign io_commonOut_transEntry_bits_payload_hasException = trans_payload[859];
  assign io_commonOut_transEntry_bits_payload_trigger = trans_payload[863:860];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_valid = trans_payload[864];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC = trans_payload[865];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_brType = trans_payload[867:866];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall = trans_payload[868];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet = trans_payload[869];
  assign io_commonOut_transEntry_bits_payload_pred_taken = trans_payload[870];
  assign io_commonOut_transEntry_bits_payload_crossPageIPFFix = trans_payload[871];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_flag = trans_payload[872];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_value = trans_payload[878:873];
  assign io_commonOut_transEntry_bits_payload_ftqOffset = trans_payload[882:879];
  assign io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault = trans_payload[883];
  assign io_commonOut_transEntry_bits_payload_srcType_0 = trans_payload[887:884];
  assign io_commonOut_transEntry_bits_payload_srcType_1 = trans_payload[891:888];
  assign io_commonOut_transEntry_bits_payload_srcType_2 = trans_payload[895:892];
  assign io_commonOut_transEntry_bits_payload_srcType_3 = trans_payload[899:896];
  assign io_commonOut_transEntry_bits_payload_srcType_4 = trans_payload[903:900];
  assign io_commonOut_transEntry_bits_payload_ldest = trans_payload[909:904];
  assign io_commonOut_transEntry_bits_payload_fuType = trans_payload[944:910];
  assign io_commonOut_transEntry_bits_payload_rfWen = trans_payload[945];
  assign io_commonOut_transEntry_bits_payload_vlWen = trans_payload[946];
  assign io_commonOut_transEntry_bits_payload_isXSTrap = trans_payload[947];
  assign io_commonOut_transEntry_bits_payload_waitForward = trans_payload[948];
  assign io_commonOut_transEntry_bits_payload_blockBackward = trans_payload[949];
  assign io_commonOut_transEntry_bits_payload_flushPipe = trans_payload[950];
  assign io_commonOut_transEntry_bits_payload_canRobCompress = trans_payload[951];
  assign io_commonOut_transEntry_bits_payload_imm = trans_payload[983:952];
  assign io_commonOut_transEntry_bits_payload_vpu_vuopIdx = trans_payload[990:984];
  assign io_commonOut_transEntry_bits_payload_vpu_lastUop = trans_payload[991];
  assign io_commonOut_transEntry_bits_payload_vlsInstr = trans_payload[992];
  assign io_commonOut_transEntry_bits_payload_wfflags = trans_payload[993];
  assign io_commonOut_transEntry_bits_payload_isMove = trans_payload[994];
  assign io_commonOut_transEntry_bits_payload_isDropAmocasSta = trans_payload[995];
  assign io_commonOut_transEntry_bits_payload_isVset = trans_payload[996];
  assign io_commonOut_transEntry_bits_payload_firstUop = trans_payload[997];
  assign io_commonOut_transEntry_bits_payload_numUops = trans_payload[1004:998];
  assign io_commonOut_transEntry_bits_payload_numWB = trans_payload[1011:1005];
  assign io_commonOut_transEntry_bits_payload_commitType = trans_payload[1014:1012];
  assign io_commonOut_transEntry_bits_payload_srcState_0 = trans_payload[1015];
  assign io_commonOut_transEntry_bits_payload_srcState_1 = trans_payload[1016];
  assign io_commonOut_transEntry_bits_payload_srcState_2 = trans_payload[1017];
  assign io_commonOut_transEntry_bits_payload_srcState_3 = trans_payload[1018];
  assign io_commonOut_transEntry_bits_payload_srcState_4 = trans_payload[1019];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0 = trans_payload[1021:1020];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1 = trans_payload[1023:1022];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2 = trans_payload[1025:1024];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0 = trans_payload[1027:1026];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1 = trans_payload[1029:1028];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2 = trans_payload[1031:1030];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0 = trans_payload[1033:1032];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1 = trans_payload[1035:1034];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2 = trans_payload[1037:1036];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0 = trans_payload[1039:1038];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1 = trans_payload[1041:1040];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2 = trans_payload[1043:1042];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0 = trans_payload[1045:1044];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1 = trans_payload[1047:1046];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2 = trans_payload[1049:1048];
  assign io_commonOut_transEntry_bits_payload_psrc_0 = trans_payload[1057:1050];
  assign io_commonOut_transEntry_bits_payload_psrc_1 = trans_payload[1065:1058];
  assign io_commonOut_transEntry_bits_payload_psrc_2 = trans_payload[1073:1066];
  assign io_commonOut_transEntry_bits_payload_psrc_3 = trans_payload[1081:1074];
  assign io_commonOut_transEntry_bits_payload_psrc_4 = trans_payload[1089:1082];
  assign io_commonOut_transEntry_bits_payload_useRegCache_0 = trans_payload[1090];
  assign io_commonOut_transEntry_bits_payload_useRegCache_1 = trans_payload[1091];
  assign io_commonOut_transEntry_bits_payload_regCacheIdx_0 = trans_payload[1096:1092];
  assign io_commonOut_transEntry_bits_payload_regCacheIdx_1 = trans_payload[1101:1097];
  assign io_commonOut_transEntry_bits_payload_robIdx_flag = trans_payload[1102];
  assign io_commonOut_transEntry_bits_payload_robIdx_value = trans_payload[1110:1103];
  assign io_commonOut_transEntry_bits_payload_instrSize = trans_payload[1113:1111];
  assign io_commonOut_transEntry_bits_payload_dirtyFs = trans_payload[1114];
  assign io_commonOut_transEntry_bits_payload_dirtyVs = trans_payload[1115];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype = trans_payload[1119:1116];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire = trans_payload[1123:1120];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize = trans_payload[1124];
  assign io_commonOut_transEntry_bits_payload_eliminatedMove = trans_payload[1125];
  assign io_commonOut_transEntry_bits_payload_snapshot = trans_payload[1126];
  assign io_commonOut_transEntry_bits_payload_debugInfo_selectTime = trans_payload[1190:1127];
  assign io_commonOut_transEntry_bits_payload_debugInfo_issueTime = trans_payload[1254:1191];
  assign io_commonOut_transEntry_bits_payload_storeSetHit = trans_payload[1255];
  assign io_commonOut_transEntry_bits_payload_waitForRobIdx_flag = trans_payload[1256];
  assign io_commonOut_transEntry_bits_payload_waitForRobIdx_value = trans_payload[1264:1257];
  assign io_commonOut_transEntry_bits_payload_loadWaitBit = trans_payload[1265];
  assign io_commonOut_transEntry_bits_payload_loadWaitStrict = trans_payload[1266];
  assign io_commonOut_transEntry_bits_payload_ssid = trans_payload[1271:1267];
  assign io_commonOut_transEntry_bits_payload_lqIdx_flag = trans_payload[1272];
  assign io_commonOut_transEntry_bits_payload_lqIdx_value = trans_payload[1279:1273];
  assign io_commonOut_transEntry_bits_payload_sqIdx_flag = trans_payload[1280];
  assign io_commonOut_transEntry_bits_payload_sqIdx_value = trans_payload[1286:1281];
  assign io_commonOut_transEntry_bits_payload_singleStep = trans_payload[1287];
  assign io_commonOut_transEntry_bits_payload_replayInst = trans_payload[1288];
  assign io_commonOut_transEntry_bits_payload_debug_fuType = trans_payload[1323:1289];
  assign io_commonOut_transEntry_bits_payload_debug_sim_trig = trans_payload[1324];
  assign io_commonOut_transEntry_bits_payload_numLsElem = trans_payload[1329:1325];
  // END GENERATED(core-inst)

endmodule
