// OthersEntry_88.sv —— 发射队列单条目（FaluFcvtF2vFmacFdiv 变体的 simp）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*
// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。
//
// 在流水线里的位置：一条等待发射的 uop 占一个条目。条目每拍监听写回(WB)与
// IQ 即时唤醒总线，把命中的源置就绪；「全源就绪 && 未发射 && 未阻塞 && 未冲刷」
// 即 canIssue，上层 Entries 在 canIssue 的条目里按年龄选最老的发射。
// 本条目角色：简单条目 simp（可被提级，产出 transEntry）
//   golden 里由 EntriesFaluFcvtF2vFmacFdiv 例化 2 份（实例名 othersEntriesSimp_*）。
//
// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的
//   Variant("EntriesFaluFcvtF2vFmacFdiv")，那份代码已断言 enq/simp/comp 三个 golden 模块
//   共用同一套唤醒路由与 og0 取消映射；逐模块才会不同的几样在本文件里另量）：
//   源寄存器 3 个，发射口 2 个（deqPortIdxRead 有）
//   WB 唤醒 6 路（fpWen）+ IQ 即时唤醒 3 路
//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：
//     IQ0: og0Cancel[8], is0Lat=real
//     IQ1: 无取消, is0Lat=const0
//     IQ2: 无取消, is0Lat=const0
//   保留的 FuType one-hot 位：FuType[4], FuType[11], FuType[12], FuType[13], FuType[14]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位
//   负载：发射口可见 22 个字段 / 548 位；转移包另带 158 个字段，共 1330 位
//
// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出
//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool
//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。
//
// 自动生成：verif/ut/OthersEntry_88/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
// =============================================================================
module OthersEntry_88 (
  input          clock,
  input          reset,
  input          io_commonIn_flush_valid,
  input          io_commonIn_flush_bits_robIdx_flag,
  input  [7:0]   io_commonIn_flush_bits_robIdx_value,
  input          io_commonIn_flush_bits_level,
  input          io_commonIn_enq_valid,
  input          io_commonIn_enq_bits_status_robIdx_flag,
  input  [7:0]   io_commonIn_enq_bits_status_robIdx_value,
  input          io_commonIn_enq_bits_status_fuType_4,
  input          io_commonIn_enq_bits_status_fuType_11,
  input          io_commonIn_enq_bits_status_fuType_12,
  input          io_commonIn_enq_bits_status_fuType_13,
  input          io_commonIn_enq_bits_status_fuType_14,
  input  [7:0]   io_commonIn_enq_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_exuSources_value,
  input  [7:0]   io_commonIn_enq_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_1_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_1_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_exuSources_value,
  input  [7:0]   io_commonIn_enq_bits_status_srcStatus_2_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_2_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_2_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_2_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_2,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_2_exuSources_value,
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
  input          io_commonIn_wakeUpFromWB_5_valid,
  input          io_commonIn_wakeUpFromWB_5_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_5_bits_pdest,
  input          io_commonIn_wakeUpFromWB_4_valid,
  input          io_commonIn_wakeUpFromWB_4_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_4_bits_pdest,
  input          io_commonIn_wakeUpFromWB_3_valid,
  input          io_commonIn_wakeUpFromWB_3_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_3_bits_pdest,
  input          io_commonIn_wakeUpFromWB_2_valid,
  input          io_commonIn_wakeUpFromWB_2_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_2_bits_pdest,
  input          io_commonIn_wakeUpFromWB_1_valid,
  input          io_commonIn_wakeUpFromWB_1_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_1_bits_pdest,
  input          io_commonIn_wakeUpFromWB_0_valid,
  input          io_commonIn_wakeUpFromWB_0_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_0_bits_pdest,
  input          io_commonIn_wakeUpFromIQ_2_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_2_bits_pdest,
  input          io_commonIn_wakeUpFromIQ_1_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_1_bits_pdest,
  input          io_commonIn_wakeUpFromIQ_0_bits_fpWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_0_bits_pdest,
  input          io_commonIn_wakeUpFromIQ_0_bits_is0Lat,
  input          io_commonIn_og0Cancel_8,
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
  output [1:0]   io_commonOut_exuSources_0_value,
  output [1:0]   io_commonOut_exuSources_1_value,
  output [1:0]   io_commonOut_exuSources_2_value,
  output         io_commonOut_isFirstIssue,
  output         io_commonOut_entry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_entry_bits_status_robIdx_value,
  output         io_commonOut_entry_bits_status_fuType_4,
  output         io_commonOut_entry_bits_status_fuType_11,
  output         io_commonOut_entry_bits_status_fuType_12,
  output         io_commonOut_entry_bits_status_fuType_13,
  output         io_commonOut_entry_bits_status_fuType_14,
  output [7:0]   io_commonOut_entry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_0_srcType,
  output [7:0]   io_commonOut_entry_bits_status_srcStatus_1_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_1_srcType,
  output [7:0]   io_commonOut_entry_bits_status_srcStatus_2_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_2_srcType,
  output [8:0]   io_commonOut_entry_bits_payload_fuOpType,
  output         io_commonOut_entry_bits_payload_rfWen,
  output         io_commonOut_entry_bits_payload_fpWen,
  output         io_commonOut_entry_bits_payload_vecWen,
  output         io_commonOut_entry_bits_payload_v0Wen,
  output [3:0]   io_commonOut_entry_bits_payload_selImm,
  output [1:0]   io_commonOut_entry_bits_payload_fpu_typeTagOut,
  output         io_commonOut_entry_bits_payload_fpu_wflags,
  output [1:0]   io_commonOut_entry_bits_payload_fpu_typ,
  output [1:0]   io_commonOut_entry_bits_payload_fpu_fmt,
  output [2:0]   io_commonOut_entry_bits_payload_fpu_rm,
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
  output         io_commonOut_transEntry_bits_status_fuType_4,
  output         io_commonOut_transEntry_bits_status_fuType_11,
  output         io_commonOut_transEntry_bits_status_fuType_12,
  output         io_commonOut_transEntry_bits_status_fuType_13,
  output         io_commonOut_transEntry_bits_status_fuType_14,
  output [7:0]   io_commonOut_transEntry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_0_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value,
  output [7:0]   io_commonOut_transEntry_bits_status_srcStatus_1_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_1_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_exuSources_value,
  output [7:0]   io_commonOut_transEntry_bits_status_srcStatus_2_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_2_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_2_exuSources_value,
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
  output         io_commonOut_perfOg0Cancel_0,
  output         io_commonOut_perfOg0Cancel_1,
  output         io_commonOut_perfOg0Cancel_2,
  output         io_commonOut_perfWakeupByWB_0,
  output         io_commonOut_perfWakeupByWB_1,
  output         io_commonOut_perfWakeupByWB_2,
  output         io_commonOut_perfWakeupByIQ_0_0,
  output         io_commonOut_perfWakeupByIQ_0_1,
  output         io_commonOut_perfWakeupByIQ_0_2,
  output         io_commonOut_perfWakeupByIQ_1_0,
  output         io_commonOut_perfWakeupByIQ_1_1,
  output         io_commonOut_perfWakeupByIQ_1_2,
  output         io_commonOut_perfWakeupByIQ_2_0,
  output         io_commonOut_perfWakeupByIQ_2_1,
  output         io_commonOut_perfWakeupByIQ_2_2
);

  // BEGIN GENERATED(core-inst)
  // 入队负载按 Variant 的偏移表拼成一根 1330 位向量（transEntry 整包）
  logic [1329:0] enq_payload;
  assign enq_payload = {io_commonIn_enq_bits_payload_numLsElem, io_commonIn_enq_bits_payload_debug_sim_trig, io_commonIn_enq_bits_payload_debug_fuType, io_commonIn_enq_bits_payload_replayInst, io_commonIn_enq_bits_payload_singleStep, io_commonIn_enq_bits_payload_sqIdx_value, io_commonIn_enq_bits_payload_sqIdx_flag, io_commonIn_enq_bits_payload_lqIdx_value, io_commonIn_enq_bits_payload_lqIdx_flag, io_commonIn_enq_bits_payload_ssid, io_commonIn_enq_bits_payload_loadWaitStrict, io_commonIn_enq_bits_payload_loadWaitBit, io_commonIn_enq_bits_payload_waitForRobIdx_value, io_commonIn_enq_bits_payload_waitForRobIdx_flag, io_commonIn_enq_bits_payload_storeSetHit, io_commonIn_enq_bits_payload_debugInfo_issueTime, io_commonIn_enq_bits_payload_debugInfo_selectTime, io_commonIn_enq_bits_payload_snapshot, io_commonIn_enq_bits_payload_eliminatedMove, io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize, io_commonIn_enq_bits_payload_traceBlockInPipe_iretire, io_commonIn_enq_bits_payload_traceBlockInPipe_itype, io_commonIn_enq_bits_payload_dirtyVs, io_commonIn_enq_bits_payload_dirtyFs, io_commonIn_enq_bits_payload_instrSize, io_commonIn_enq_bits_payload_robIdx_value, io_commonIn_enq_bits_payload_robIdx_flag, io_commonIn_enq_bits_payload_regCacheIdx_1, io_commonIn_enq_bits_payload_regCacheIdx_0, io_commonIn_enq_bits_payload_useRegCache_1, io_commonIn_enq_bits_payload_useRegCache_0, io_commonIn_enq_bits_payload_psrc_4, io_commonIn_enq_bits_payload_psrc_3, io_commonIn_enq_bits_payload_psrc_2, io_commonIn_enq_bits_payload_psrc_1, io_commonIn_enq_bits_payload_psrc_0, io_commonIn_enq_bits_payload_srcLoadDependency_4_2, io_commonIn_enq_bits_payload_srcLoadDependency_4_1, io_commonIn_enq_bits_payload_srcLoadDependency_4_0, io_commonIn_enq_bits_payload_srcLoadDependency_3_2, io_commonIn_enq_bits_payload_srcLoadDependency_3_1, io_commonIn_enq_bits_payload_srcLoadDependency_3_0, io_commonIn_enq_bits_payload_srcLoadDependency_2_2, io_commonIn_enq_bits_payload_srcLoadDependency_2_1, io_commonIn_enq_bits_payload_srcLoadDependency_2_0, io_commonIn_enq_bits_payload_srcLoadDependency_1_2, io_commonIn_enq_bits_payload_srcLoadDependency_1_1, io_commonIn_enq_bits_payload_srcLoadDependency_1_0, io_commonIn_enq_bits_payload_srcLoadDependency_0_2, io_commonIn_enq_bits_payload_srcLoadDependency_0_1, io_commonIn_enq_bits_payload_srcLoadDependency_0_0, io_commonIn_enq_bits_payload_srcState_4, io_commonIn_enq_bits_payload_srcState_3, io_commonIn_enq_bits_payload_srcState_2, io_commonIn_enq_bits_payload_srcState_1, io_commonIn_enq_bits_payload_srcState_0, io_commonIn_enq_bits_payload_commitType, io_commonIn_enq_bits_payload_numWB, io_commonIn_enq_bits_payload_numUops, io_commonIn_enq_bits_payload_lastUop, io_commonIn_enq_bits_payload_firstUop, io_commonIn_enq_bits_payload_isVset, io_commonIn_enq_bits_payload_uopIdx, io_commonIn_enq_bits_payload_isDropAmocasSta, io_commonIn_enq_bits_payload_isMove, io_commonIn_enq_bits_payload_wfflags, io_commonIn_enq_bits_payload_vlsInstr, io_commonIn_enq_bits_payload_vpu_isVleff, io_commonIn_enq_bits_payload_vpu_isWritePartVd, io_commonIn_enq_bits_payload_vpu_isDependOldVd, io_commonIn_enq_bits_payload_vpu_isMove, io_commonIn_enq_bits_payload_vpu_isOpMask, io_commonIn_enq_bits_payload_vpu_isDstMask, io_commonIn_enq_bits_payload_vpu_isNarrow, io_commonIn_enq_bits_payload_vpu_isExt, io_commonIn_enq_bits_payload_vpu_isReverse, io_commonIn_enq_bits_payload_vpu_veew, io_commonIn_enq_bits_payload_vpu_nf, io_commonIn_enq_bits_payload_vpu_vl, io_commonIn_enq_bits_payload_vpu_vmask, io_commonIn_enq_bits_payload_vpu_lastUop, io_commonIn_enq_bits_payload_vpu_vuopIdx, io_commonIn_enq_bits_payload_vpu_vxrm, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2, io_commonIn_enq_bits_payload_vpu_fpu_isReduction, io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr, io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr, io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst, io_commonIn_enq_bits_payload_vpu_frm, io_commonIn_enq_bits_payload_vpu_vstart, io_commonIn_enq_bits_payload_vpu_vm, io_commonIn_enq_bits_payload_vpu_specVlmul, io_commonIn_enq_bits_payload_vpu_specVsew, io_commonIn_enq_bits_payload_vpu_specVta, io_commonIn_enq_bits_payload_vpu_specVma, io_commonIn_enq_bits_payload_vpu_specVill, io_commonIn_enq_bits_payload_vpu_vlmul, io_commonIn_enq_bits_payload_vpu_vsew, io_commonIn_enq_bits_payload_vpu_vta, io_commonIn_enq_bits_payload_vpu_vma, io_commonIn_enq_bits_payload_vpu_vill, io_commonIn_enq_bits_payload_imm, io_commonIn_enq_bits_payload_canRobCompress, io_commonIn_enq_bits_payload_flushPipe, io_commonIn_enq_bits_payload_blockBackward, io_commonIn_enq_bits_payload_waitForward, io_commonIn_enq_bits_payload_isXSTrap, io_commonIn_enq_bits_payload_vlWen, io_commonIn_enq_bits_payload_fuType, io_commonIn_enq_bits_payload_ldest, io_commonIn_enq_bits_payload_srcType_4, io_commonIn_enq_bits_payload_srcType_3, io_commonIn_enq_bits_payload_srcType_2, io_commonIn_enq_bits_payload_srcType_1, io_commonIn_enq_bits_payload_srcType_0, io_commonIn_enq_bits_payload_satpFlushFirstFetchFault, io_commonIn_enq_bits_payload_ftqOffset, io_commonIn_enq_bits_payload_ftqPtr_value, io_commonIn_enq_bits_payload_ftqPtr_flag, io_commonIn_enq_bits_payload_crossPageIPFFix, io_commonIn_enq_bits_payload_pred_taken, io_commonIn_enq_bits_payload_preDecodeInfo_isRet, io_commonIn_enq_bits_payload_preDecodeInfo_isCall, io_commonIn_enq_bits_payload_preDecodeInfo_brType, io_commonIn_enq_bits_payload_preDecodeInfo_isRVC, io_commonIn_enq_bits_payload_preDecodeInfo_valid, io_commonIn_enq_bits_payload_trigger, io_commonIn_enq_bits_payload_hasException, io_commonIn_enq_bits_payload_isFetchMalAddr, io_commonIn_enq_bits_payload_exceptionVec_23, io_commonIn_enq_bits_payload_exceptionVec_22, io_commonIn_enq_bits_payload_exceptionVec_21, io_commonIn_enq_bits_payload_exceptionVec_20, io_commonIn_enq_bits_payload_exceptionVec_19, io_commonIn_enq_bits_payload_exceptionVec_18, io_commonIn_enq_bits_payload_exceptionVec_17, io_commonIn_enq_bits_payload_exceptionVec_16, io_commonIn_enq_bits_payload_exceptionVec_15, io_commonIn_enq_bits_payload_exceptionVec_14, io_commonIn_enq_bits_payload_exceptionVec_13, io_commonIn_enq_bits_payload_exceptionVec_12, io_commonIn_enq_bits_payload_exceptionVec_11, io_commonIn_enq_bits_payload_exceptionVec_10, io_commonIn_enq_bits_payload_exceptionVec_9, io_commonIn_enq_bits_payload_exceptionVec_8, io_commonIn_enq_bits_payload_exceptionVec_7, io_commonIn_enq_bits_payload_exceptionVec_6, io_commonIn_enq_bits_payload_exceptionVec_5, io_commonIn_enq_bits_payload_exceptionVec_4, io_commonIn_enq_bits_payload_exceptionVec_3, io_commonIn_enq_bits_payload_exceptionVec_2, io_commonIn_enq_bits_payload_exceptionVec_1, io_commonIn_enq_bits_payload_exceptionVec_0, io_commonIn_enq_bits_payload_foldpc, io_commonIn_enq_bits_payload_pc, io_commonIn_enq_bits_payload_instr, io_commonIn_enq_bits_payload_debug_seqNum_uopIdx, io_commonIn_enq_bits_payload_debug_seqNum_seqNum, io_commonIn_enq_bits_payload_debugInfo_tlbRespTime, io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime, io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id, io_commonIn_enq_bits_payload_debugInfo_writebackTime, io_commonIn_enq_bits_payload_debugInfo_enqRsTime, io_commonIn_enq_bits_payload_debugInfo_dispatchTime, io_commonIn_enq_bits_payload_debugInfo_renameTime, io_commonIn_enq_bits_payload_debugInfo_eliminatedMove, io_commonIn_enq_bits_payload_pdest, io_commonIn_enq_bits_payload_fpu_rm, io_commonIn_enq_bits_payload_fpu_fmt, io_commonIn_enq_bits_payload_fpu_typ, io_commonIn_enq_bits_payload_fpu_wflags, io_commonIn_enq_bits_payload_fpu_typeTagOut, io_commonIn_enq_bits_payload_selImm, io_commonIn_enq_bits_payload_v0Wen, io_commonIn_enq_bits_payload_vecWen, io_commonIn_enq_bits_payload_fpWen, io_commonIn_enq_bits_payload_rfWen, io_commonIn_enq_bits_payload_fuOpType};

  logic [4:0] fu_type_narrow;
  logic [2:0][3:0] data_src;
  logic [2:0][1:0] exu_src;
  logic [547:0] ety_payload;
  logic [2:0][7:0] ety_psrc;
  logic [2:0][3:0] ety_src_type;
  logic [2:0][2:0][1:0] ety_ld_dep;
  logic [2:0][0:0] ety_rc_idx;
  logic [1329:0] trans_payload;
  logic [2:0][7:0] trans_psrc;
  logic [2:0][3:0] trans_src_type, trans_data_src;
  logic [2:0] trans_src_state, trans_use_rc;
  logic [2:0][2:0][1:0] trans_ld_dep;
  logic [2:0][1:0] trans_exu_src;
  logic [2:0][0:0] trans_rc_idx;
  logic [4:0] trans_fu_type;
  logic unused_cancel_bypass;
  logic [2:0] unused_dbg_ld_cancel;

  xs_iq_entry #(
    .IS_ENQ(0), .IS_TRANS(1), .IS_COMP(0),
    .NUM_DEQ_PORTS(2),
    .NUM_REGSRC(3), .NUM_WK_WB(6), .NUM_FU_BIT(5),
    .ROB_W(8), .PSRC_W(8), .PDEST_W(8),
    .PL_DEQ_W(548), .PL_TRANS_W(1330),
    .HAS_LD_DEP(1), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(3), .EXU_W(2),
    .IQ_SRC_MASK({3'b111, 3'b111, 3'b111}),
    .IQ_WEN_PRESENT(5'b00010),
    .IQD_WEN_PRESENT(5'b00000),
    .IQ_IS_LD_PIPE({3'b000, 3'b000, 3'b000}),
    .HAS_REG_CACHE(0), .RC_IDX_W(1),
    .IQ_WRITE_RC(3'b000), .RC_TYPE_BIT(0),
    .SRC_WB_MASK({6'b111111, 6'b111111, 6'b111111}),
    .SRC_MATCH_KIND({2'd0, 2'd0, 2'd0}),
    .WB_WEN_PRESENT(5'b00010),
    .WBD_WEN_PRESENT(5'b00000),
    .HAS_IGNORE_OLD_VD(0),
    .VD_SRC(0), .VL_SRC(0), .WB_VL_INT(0), .WB_VL_VF(0),
    .PLB_VM(805),
    .PLB_VMA(790),
    .PLB_VTA(791),
    .PLB_IS_DEPEND_OLDVD(981),
    .PLB_IS_WRITE_PARTVD(982),
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
    .enq_fu_type({io_commonIn_enq_bits_status_fuType_14, io_commonIn_enq_bits_status_fuType_13, io_commonIn_enq_bits_status_fuType_12, io_commonIn_enq_bits_status_fuType_11, io_commonIn_enq_bits_status_fuType_4}),
    .enq_psrc({io_commonIn_enq_bits_status_srcStatus_2_psrc, io_commonIn_enq_bits_status_srcStatus_1_psrc, io_commonIn_enq_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_commonIn_enq_bits_status_srcStatus_2_srcType, io_commonIn_enq_bits_status_srcStatus_1_srcType, io_commonIn_enq_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_commonIn_enq_bits_status_srcStatus_2_srcState, io_commonIn_enq_bits_status_srcStatus_1_srcState, io_commonIn_enq_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_commonIn_enq_bits_status_srcStatus_2_dataSources_value, io_commonIn_enq_bits_status_srcStatus_1_dataSources_value, io_commonIn_enq_bits_status_srcStatus_0_dataSources_value}),
    .enq_blocked(io_commonIn_enq_bits_status_blocked),
    .enq_issued(io_commonIn_enq_bits_status_issued),
    .enq_first_issue(io_commonIn_enq_bits_status_firstIssue),
    .enq_issue_timer(io_commonIn_enq_bits_status_issueTimer),
    .enq_deq_port_idx(io_commonIn_enq_bits_status_deqPortIdx),
    .enq_payload(enq_payload),
    .enq_ld_dep({io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_2_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0}),
    .enq_exu_src({io_commonIn_enq_bits_status_srcStatus_2_exuSources_value, io_commonIn_enq_bits_status_srcStatus_1_exuSources_value, io_commonIn_enq_bits_status_srcStatus_0_exuSources_value}),
    .enq_use_rc('0),
    .enq_rc_idx('0),
    .wk_valid({io_commonIn_wakeUpFromWB_5_valid, io_commonIn_wakeUpFromWB_4_valid, io_commonIn_wakeUpFromWB_3_valid, io_commonIn_wakeUpFromWB_2_valid, io_commonIn_wakeUpFromWB_1_valid, io_commonIn_wakeUpFromWB_0_valid}),
    .wk_wen({{1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_5_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_4_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_3_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_2_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_1_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_0_bits_fpWen, 1'b0}}),
    .wk_pdest({io_commonIn_wakeUpFromWB_5_bits_pdest, io_commonIn_wakeUpFromWB_4_bits_pdest, io_commonIn_wakeUpFromWB_3_bits_pdest, io_commonIn_wakeUpFromWB_2_bits_pdest, io_commonIn_wakeUpFromWB_1_bits_pdest, io_commonIn_wakeUpFromWB_0_bits_pdest}),
    // ★ 入队延迟窗口只有 EnqEntry 有（IS_ENQ=1）；OthersEntry 的 golden
    //   根本没有 wakeUpFromWBDelayed / enqDelay 这组端口，故整组钉 0
    .wkd_valid('0), .wkd_wen('0), .wkd_pdest('0),
    .iq_wen({{1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_2_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_1_bits_fpWen, 1'b0}, {1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_0_bits_fpWen, 1'b0}}),
    .iq_pdest({io_commonIn_wakeUpFromIQ_2_bits_pdest, io_commonIn_wakeUpFromIQ_1_bits_pdest, io_commonIn_wakeUpFromIQ_0_bits_pdest}),
    .iq_ld_dep('0),
    .iq_rc_dest('0),
    // iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]；
    // og0Cancel 的下标是稀疏的，is0Lat 有的路被 firtool 折成常量。
    .iq_cancel({1'b0, 1'b0, (io_commonIn_og0Cancel_8 & io_commonIn_wakeUpFromIQ_0_bits_is0Lat)}),
    .iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0),
    .iqd_cancel('0),
    .ld1_cancel('0),
    .ld2_cancel('0),
    .ld1d_cancel('0), .ld2d_cancel('0), .enqd_self_ld_dep('0),
    .vl_int_is_zero(1'b0),
    .vl_int_is_vlmax(1'b0),
    .vl_vf_is_zero(1'b0),
    .vl_vf_is_vlmax(1'b0),
    .deq_sel(io_commonIn_deqSel),
    .deq_port_idx_write(io_commonIn_deqPortIdxWrite),
    .resp_valid(io_commonIn_issueResp_valid),
    .resp_bits(io_commonIn_issueResp_bits_resp),
    .enq_vm('0), .enq_vpr('0), .enq_vr_mask('0), .enq_vr_mbidx('0),
    .lq_deq_ptr('0), .resp_vpr('0), .resp_vr_mask('0), .resp_vr_mbidx('0),
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
    .o_dbg_perf_og0_cancel({io_commonOut_perfOg0Cancel_2, io_commonOut_perfOg0Cancel_1, io_commonOut_perfOg0Cancel_0}),
    .o_dbg_perf_wakeup_by_wb({io_commonOut_perfWakeupByWB_2, io_commonOut_perfWakeupByWB_1, io_commonOut_perfWakeupByWB_0}),
    .o_dbg_perf_wakeup_by_iq({io_commonOut_perfWakeupByIQ_2_2, io_commonOut_perfWakeupByIQ_2_1, io_commonOut_perfWakeupByIQ_2_0, io_commonOut_perfWakeupByIQ_1_2, io_commonOut_perfWakeupByIQ_1_1, io_commonOut_perfWakeupByIQ_1_0, io_commonOut_perfWakeupByIQ_0_2, io_commonOut_perfWakeupByIQ_0_1, io_commonOut_perfWakeupByIQ_0_0})
  );

  // fuType 出口：核只存本变体保留的 5 位，这里放回 35 位 one-hot 的原位置
  assign io_commonOut_fuType = {20'h0, fu_type_narrow[4], fu_type_narrow[3], fu_type_narrow[2], fu_type_narrow[1], 6'h0, fu_type_narrow[0], 4'h0};

  assign io_commonOut_dataSources_0_value = data_src[0];
  assign io_commonOut_exuSources_0_value = exu_src[0];
  assign io_commonOut_dataSources_1_value = data_src[1];
  assign io_commonOut_exuSources_1_value = exu_src[1];
  assign io_commonOut_dataSources_2_value = data_src[2];
  assign io_commonOut_exuSources_2_value = exu_src[2];

  // commonOut.entry.bits.status —— fuType 与 commonOut.fuType 同一组寄存器
  assign io_commonOut_entry_bits_status_fuType_4 = fu_type_narrow[0];
  assign io_commonOut_entry_bits_status_fuType_11 = fu_type_narrow[1];
  assign io_commonOut_entry_bits_status_fuType_12 = fu_type_narrow[2];
  assign io_commonOut_entry_bits_status_fuType_13 = fu_type_narrow[3];
  assign io_commonOut_entry_bits_status_fuType_14 = fu_type_narrow[4];
  assign io_commonOut_entry_bits_status_srcStatus_0_psrc = ety_psrc[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcType = ety_src_type[0];
  assign io_commonOut_entry_bits_status_srcStatus_1_psrc = ety_psrc[1];
  assign io_commonOut_entry_bits_status_srcStatus_1_srcType = ety_src_type[1];
  assign io_commonOut_entry_bits_status_srcStatus_2_psrc = ety_psrc[2];
  assign io_commonOut_entry_bits_status_srcStatus_2_srcType = ety_src_type[2];
  assign io_commonOut_entry_bits_payload_fuOpType = ety_payload[8:0];
  assign io_commonOut_entry_bits_payload_rfWen = ety_payload[9];
  assign io_commonOut_entry_bits_payload_fpWen = ety_payload[10];
  assign io_commonOut_entry_bits_payload_vecWen = ety_payload[11];
  assign io_commonOut_entry_bits_payload_v0Wen = ety_payload[12];
  assign io_commonOut_entry_bits_payload_selImm = ety_payload[16:13];
  assign io_commonOut_entry_bits_payload_fpu_typeTagOut = ety_payload[18:17];
  assign io_commonOut_entry_bits_payload_fpu_wflags = ety_payload[19];
  assign io_commonOut_entry_bits_payload_fpu_typ = ety_payload[21:20];
  assign io_commonOut_entry_bits_payload_fpu_fmt = ety_payload[23:22];
  assign io_commonOut_entry_bits_payload_fpu_rm = ety_payload[26:24];
  assign io_commonOut_entry_bits_payload_pdest = ety_payload[34:27];
  assign io_commonOut_entry_bits_payload_debugInfo_eliminatedMove = ety_payload[35];
  assign io_commonOut_entry_bits_payload_debugInfo_renameTime = ety_payload[99:36];
  assign io_commonOut_entry_bits_payload_debugInfo_dispatchTime = ety_payload[163:100];
  assign io_commonOut_entry_bits_payload_debugInfo_enqRsTime = ety_payload[227:164];
  assign io_commonOut_entry_bits_payload_debugInfo_writebackTime = ety_payload[291:228];
  assign io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id = ety_payload[355:292];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime = ety_payload[419:356];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbRespTime = ety_payload[483:420];
  assign io_commonOut_entry_bits_payload_debug_seqNum_seqNum = ety_payload[539:484];
  assign io_commonOut_entry_bits_payload_debug_seqNum_uopIdx = ety_payload[547:540];

  // commonOut.transEntry —— 交给下一级的整包（= entryUpdate）
  assign io_commonOut_transEntry_bits_status_fuType_4 = trans_fu_type[0];
  assign io_commonOut_transEntry_bits_status_fuType_11 = trans_fu_type[1];
  assign io_commonOut_transEntry_bits_status_fuType_12 = trans_fu_type[2];
  assign io_commonOut_transEntry_bits_status_fuType_13 = trans_fu_type[3];
  assign io_commonOut_transEntry_bits_status_fuType_14 = trans_fu_type[4];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_psrc = trans_psrc[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcType = trans_src_type[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcState = trans_src_state[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value = trans_data_src[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value = trans_exu_src[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0 = trans_ld_dep[0][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1 = trans_ld_dep[0][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2 = trans_ld_dep[0][2];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_psrc = trans_psrc[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcType = trans_src_type[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcState = trans_src_state[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value = trans_data_src[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_exuSources_value = trans_exu_src[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0 = trans_ld_dep[1][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1 = trans_ld_dep[1][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2 = trans_ld_dep[1][2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_psrc = trans_psrc[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcType = trans_src_type[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcState = trans_src_state[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_dataSources_value = trans_data_src[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_exuSources_value = trans_exu_src[2];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_0 = trans_ld_dep[2][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_1 = trans_ld_dep[2][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_2_srcLoadDependency_2 = trans_ld_dep[2][2];
  assign io_commonOut_transEntry_bits_payload_fuOpType = trans_payload[8:0];
  assign io_commonOut_transEntry_bits_payload_rfWen = trans_payload[9];
  assign io_commonOut_transEntry_bits_payload_fpWen = trans_payload[10];
  assign io_commonOut_transEntry_bits_payload_vecWen = trans_payload[11];
  assign io_commonOut_transEntry_bits_payload_v0Wen = trans_payload[12];
  assign io_commonOut_transEntry_bits_payload_selImm = trans_payload[16:13];
  assign io_commonOut_transEntry_bits_payload_fpu_typeTagOut = trans_payload[18:17];
  assign io_commonOut_transEntry_bits_payload_fpu_wflags = trans_payload[19];
  assign io_commonOut_transEntry_bits_payload_fpu_typ = trans_payload[21:20];
  assign io_commonOut_transEntry_bits_payload_fpu_fmt = trans_payload[23:22];
  assign io_commonOut_transEntry_bits_payload_fpu_rm = trans_payload[26:24];
  assign io_commonOut_transEntry_bits_payload_pdest = trans_payload[34:27];
  assign io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove = trans_payload[35];
  assign io_commonOut_transEntry_bits_payload_debugInfo_renameTime = trans_payload[99:36];
  assign io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime = trans_payload[163:100];
  assign io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime = trans_payload[227:164];
  assign io_commonOut_transEntry_bits_payload_debugInfo_writebackTime = trans_payload[291:228];
  assign io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id = trans_payload[355:292];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime = trans_payload[419:356];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime = trans_payload[483:420];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum = trans_payload[539:484];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx = trans_payload[547:540];
  assign io_commonOut_transEntry_bits_payload_instr = trans_payload[579:548];
  assign io_commonOut_transEntry_bits_payload_pc = trans_payload[629:580];
  assign io_commonOut_transEntry_bits_payload_foldpc = trans_payload[639:630];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_0 = trans_payload[640];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_1 = trans_payload[641];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_2 = trans_payload[642];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_3 = trans_payload[643];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_4 = trans_payload[644];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_5 = trans_payload[645];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_6 = trans_payload[646];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_7 = trans_payload[647];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_8 = trans_payload[648];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_9 = trans_payload[649];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_10 = trans_payload[650];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_11 = trans_payload[651];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_12 = trans_payload[652];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_13 = trans_payload[653];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_14 = trans_payload[654];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_15 = trans_payload[655];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_16 = trans_payload[656];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_17 = trans_payload[657];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_18 = trans_payload[658];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_19 = trans_payload[659];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_20 = trans_payload[660];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_21 = trans_payload[661];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_22 = trans_payload[662];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_23 = trans_payload[663];
  assign io_commonOut_transEntry_bits_payload_isFetchMalAddr = trans_payload[664];
  assign io_commonOut_transEntry_bits_payload_hasException = trans_payload[665];
  assign io_commonOut_transEntry_bits_payload_trigger = trans_payload[669:666];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_valid = trans_payload[670];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC = trans_payload[671];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_brType = trans_payload[673:672];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall = trans_payload[674];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet = trans_payload[675];
  assign io_commonOut_transEntry_bits_payload_pred_taken = trans_payload[676];
  assign io_commonOut_transEntry_bits_payload_crossPageIPFFix = trans_payload[677];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_flag = trans_payload[678];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_value = trans_payload[684:679];
  assign io_commonOut_transEntry_bits_payload_ftqOffset = trans_payload[688:685];
  assign io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault = trans_payload[689];
  assign io_commonOut_transEntry_bits_payload_srcType_0 = trans_payload[693:690];
  assign io_commonOut_transEntry_bits_payload_srcType_1 = trans_payload[697:694];
  assign io_commonOut_transEntry_bits_payload_srcType_2 = trans_payload[701:698];
  assign io_commonOut_transEntry_bits_payload_srcType_3 = trans_payload[705:702];
  assign io_commonOut_transEntry_bits_payload_srcType_4 = trans_payload[709:706];
  assign io_commonOut_transEntry_bits_payload_ldest = trans_payload[715:710];
  assign io_commonOut_transEntry_bits_payload_fuType = trans_payload[750:716];
  assign io_commonOut_transEntry_bits_payload_vlWen = trans_payload[751];
  assign io_commonOut_transEntry_bits_payload_isXSTrap = trans_payload[752];
  assign io_commonOut_transEntry_bits_payload_waitForward = trans_payload[753];
  assign io_commonOut_transEntry_bits_payload_blockBackward = trans_payload[754];
  assign io_commonOut_transEntry_bits_payload_flushPipe = trans_payload[755];
  assign io_commonOut_transEntry_bits_payload_canRobCompress = trans_payload[756];
  assign io_commonOut_transEntry_bits_payload_imm = trans_payload[788:757];
  assign io_commonOut_transEntry_bits_payload_vpu_vill = trans_payload[789];
  assign io_commonOut_transEntry_bits_payload_vpu_vma = trans_payload[790];
  assign io_commonOut_transEntry_bits_payload_vpu_vta = trans_payload[791];
  assign io_commonOut_transEntry_bits_payload_vpu_vsew = trans_payload[793:792];
  assign io_commonOut_transEntry_bits_payload_vpu_vlmul = trans_payload[796:794];
  assign io_commonOut_transEntry_bits_payload_vpu_specVill = trans_payload[797];
  assign io_commonOut_transEntry_bits_payload_vpu_specVma = trans_payload[798];
  assign io_commonOut_transEntry_bits_payload_vpu_specVta = trans_payload[799];
  assign io_commonOut_transEntry_bits_payload_vpu_specVsew = trans_payload[801:800];
  assign io_commonOut_transEntry_bits_payload_vpu_specVlmul = trans_payload[804:802];
  assign io_commonOut_transEntry_bits_payload_vpu_vm = trans_payload[805];
  assign io_commonOut_transEntry_bits_payload_vpu_vstart = trans_payload[813:806];
  assign io_commonOut_transEntry_bits_payload_vpu_frm = trans_payload[816:814];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst = trans_payload[817];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr = trans_payload[818];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr = trans_payload[819];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction = trans_payload[820];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2 = trans_payload[821];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4 = trans_payload[822];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8 = trans_payload[823];
  assign io_commonOut_transEntry_bits_payload_vpu_vxrm = trans_payload[825:824];
  assign io_commonOut_transEntry_bits_payload_vpu_vuopIdx = trans_payload[832:826];
  assign io_commonOut_transEntry_bits_payload_vpu_lastUop = trans_payload[833];
  assign io_commonOut_transEntry_bits_payload_vpu_vmask = trans_payload[961:834];
  assign io_commonOut_transEntry_bits_payload_vpu_vl = trans_payload[969:962];
  assign io_commonOut_transEntry_bits_payload_vpu_nf = trans_payload[972:970];
  assign io_commonOut_transEntry_bits_payload_vpu_veew = trans_payload[974:973];
  assign io_commonOut_transEntry_bits_payload_vpu_isReverse = trans_payload[975];
  assign io_commonOut_transEntry_bits_payload_vpu_isExt = trans_payload[976];
  assign io_commonOut_transEntry_bits_payload_vpu_isNarrow = trans_payload[977];
  assign io_commonOut_transEntry_bits_payload_vpu_isDstMask = trans_payload[978];
  assign io_commonOut_transEntry_bits_payload_vpu_isOpMask = trans_payload[979];
  assign io_commonOut_transEntry_bits_payload_vpu_isMove = trans_payload[980];
  assign io_commonOut_transEntry_bits_payload_vpu_isDependOldVd = trans_payload[981];
  assign io_commonOut_transEntry_bits_payload_vpu_isWritePartVd = trans_payload[982];
  assign io_commonOut_transEntry_bits_payload_vpu_isVleff = trans_payload[983];
  assign io_commonOut_transEntry_bits_payload_vlsInstr = trans_payload[984];
  assign io_commonOut_transEntry_bits_payload_wfflags = trans_payload[985];
  assign io_commonOut_transEntry_bits_payload_isMove = trans_payload[986];
  assign io_commonOut_transEntry_bits_payload_isDropAmocasSta = trans_payload[987];
  assign io_commonOut_transEntry_bits_payload_uopIdx = trans_payload[994:988];
  assign io_commonOut_transEntry_bits_payload_isVset = trans_payload[995];
  assign io_commonOut_transEntry_bits_payload_firstUop = trans_payload[996];
  assign io_commonOut_transEntry_bits_payload_lastUop = trans_payload[997];
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
