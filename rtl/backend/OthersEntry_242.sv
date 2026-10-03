// OthersEntry_242.sv —— 发射队列单条目（StdMoud 变体的 simp）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*
// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。
//
// 在流水线里的位置：一条等待发射的 uop 占一个条目。条目每拍监听写回(WB)与
// IQ 即时唤醒总线，把命中的源置就绪；「全源就绪 && 未发射 && 未阻塞 && 未冲刷」
// 即 canIssue，上层 Entries 在 canIssue 的条目里按年龄选最老的发射。
// 本条目角色：简单条目 simp（可被提级，产出 transEntry）
//   golden 里由 EntriesStdMoud 例化 2 份（实例名 othersEntriesSimp_*）。
//
// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的
//   Variant("EntriesStdMoud")，那份代码已断言 enq/simp/comp 三个 golden 模块
//   共用同一套唤醒路由与 og0 取消映射；逐模块才会不同的几样在本文件里另量）：
//   源寄存器 1 个，发射口 1 个（deqPortIdxRead 无）
//   WB 唤醒 10 路（fpWen）+ IQ 即时唤醒 7 路
//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：
//     IQ0: og0Cancel[0], is0Lat=real
//     IQ1: og0Cancel[2], is0Lat=real
//     IQ2: og0Cancel[4], is0Lat=real
//     IQ3: og0Cancel[6], is0Lat=real
//     IQ4: og0Cancel[20], is0Lat=real, 自身是 load 流水 0
//     IQ5: og0Cancel[21], is0Lat=real, 自身是 load 流水 1
//     IQ6: og0Cancel[22], is0Lat=real, 自身是 load 流水 2
//   保留的 FuType one-hot 位：FuType[16], FuType[17]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位
//   负载：发射口可见 15 个字段 / 541 位；转移包另带 165 个字段，共 1330 位
//
// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出
//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool
//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。
//
// 自动生成：verif/ut/OthersEntry_242/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
// =============================================================================
module OthersEntry_242 (
  input          clock,
  input          reset,
  input          io_commonIn_flush_valid,
  input          io_commonIn_flush_bits_robIdx_flag,
  input  [7:0]   io_commonIn_flush_bits_robIdx_value,
  input          io_commonIn_flush_bits_level,
  input          io_commonIn_enq_valid,
  input          io_commonIn_enq_bits_status_robIdx_flag,
  input  [7:0]   io_commonIn_enq_bits_status_robIdx_value,
  input          io_commonIn_enq_bits_status_fuType_16,
  input          io_commonIn_enq_bits_status_fuType_17,
  input  [7:0]   io_commonIn_enq_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2,
  input  [2:0]   io_commonIn_enq_bits_status_srcStatus_0_exuSources_value,
  input          io_commonIn_enq_bits_status_srcStatus_0_useRegCache,
  input  [4:0]   io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx,
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
  input          io_commonIn_wakeUpFromWB_9_valid,
  input          io_commonIn_wakeUpFromWB_9_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_9_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_9_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_9_bits_pdest,
  input          io_commonIn_wakeUpFromWB_8_valid,
  input          io_commonIn_wakeUpFromWB_8_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_8_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_8_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_8_bits_pdest,
  input          io_commonIn_wakeUpFromWB_7_valid,
  input          io_commonIn_wakeUpFromWB_7_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_7_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_7_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_7_bits_pdest,
  input          io_commonIn_wakeUpFromWB_6_valid,
  input          io_commonIn_wakeUpFromWB_6_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_6_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_6_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_6_bits_pdest,
  input          io_commonIn_wakeUpFromWB_5_valid,
  input          io_commonIn_wakeUpFromWB_5_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_5_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_5_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_5_bits_pdest,
  input          io_commonIn_wakeUpFromWB_4_valid,
  input          io_commonIn_wakeUpFromWB_4_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_4_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_4_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_4_bits_pdest,
  input          io_commonIn_wakeUpFromWB_3_valid,
  input          io_commonIn_wakeUpFromWB_3_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_3_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_3_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_3_bits_pdest,
  input          io_commonIn_wakeUpFromWB_2_valid,
  input          io_commonIn_wakeUpFromWB_2_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_2_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_2_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_2_bits_pdest,
  input          io_commonIn_wakeUpFromWB_1_valid,
  input          io_commonIn_wakeUpFromWB_1_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_1_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_1_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_1_bits_pdest,
  input          io_commonIn_wakeUpFromWB_0_valid,
  input          io_commonIn_wakeUpFromWB_0_bits_rfWen,
  input          io_commonIn_wakeUpFromWB_0_bits_fpWen,
  input          io_commonIn_wakeUpFromWB_0_bits_vecWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_0_bits_pdest,
  input          io_commonIn_wakeUpFromIQ_6_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_6_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_6_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_6_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_5_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_5_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_5_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_5_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_4_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_4_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_4_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_4_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_3_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_3_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_3_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_3_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_2_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_2_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_2_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_2_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_1_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_1_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_1_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_1_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_0_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_0_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2,
  input          io_commonIn_wakeUpFromIQ_0_bits_is0Lat,
  input  [4:0]   io_commonIn_wakeUpFromIQ_0_bits_rcDest,
  input          io_commonIn_og0Cancel_0,
  input          io_commonIn_og0Cancel_2,
  input          io_commonIn_og0Cancel_4,
  input          io_commonIn_og0Cancel_6,
  input          io_commonIn_og0Cancel_20,
  input          io_commonIn_og0Cancel_21,
  input          io_commonIn_og0Cancel_22,
  input          io_commonIn_ldCancel_0_ld1Cancel,
  input          io_commonIn_ldCancel_0_ld2Cancel,
  input          io_commonIn_ldCancel_1_ld1Cancel,
  input          io_commonIn_ldCancel_1_ld2Cancel,
  input          io_commonIn_ldCancel_2_ld1Cancel,
  input          io_commonIn_ldCancel_2_ld2Cancel,
  input          io_commonIn_deqSel,
  input          io_commonIn_issueResp_valid,
  input  [1:0]   io_commonIn_issueResp_bits_resp,
  input          io_commonIn_transSel,
  output         io_commonOut_valid,
  output         io_commonOut_issued,
  output         io_commonOut_canIssue,
  output [34:0]  io_commonOut_fuType,
  output [3:0]   io_commonOut_dataSources_0_value,
  output [2:0]   io_commonOut_exuSources_0_value,
  output         io_commonOut_isFirstIssue,
  output         io_commonOut_entry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_entry_bits_status_robIdx_value,
  output         io_commonOut_entry_bits_status_fuType_16,
  output         io_commonOut_entry_bits_status_fuType_17,
  output [7:0]   io_commonOut_entry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_0_srcType,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2,
  output [4:0]   io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx,
  output [8:0]   io_commonOut_entry_bits_payload_fuOpType,
  output [3:0]   io_commonOut_entry_bits_payload_selImm,
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
  output         io_commonOut_entry_bits_payload_sqIdx_flag,
  output [5:0]   io_commonOut_entry_bits_payload_sqIdx_value,
  output         io_commonOut_cancelBypass,
  output [1:0]   io_commonOut_issueTimerRead,
  output         io_commonOut_enqReady,
  output         io_commonOut_transEntry_valid,
  output         io_commonOut_transEntry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_transEntry_bits_status_robIdx_value,
  output         io_commonOut_transEntry_bits_status_fuType_16,
  output         io_commonOut_transEntry_bits_status_fuType_17,
  output [7:0]   io_commonOut_transEntry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_0_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2,
  output [2:0]   io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value,
  output         io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache,
  output [4:0]   io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx,
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
  output         io_commonOut_perfLdCancel_0,
  output         io_commonOut_perfOg0Cancel_0,
  output         io_commonOut_perfWakeupByWB_0,
  output         io_commonOut_perfWakeupByIQ_0_0,
  output         io_commonOut_perfWakeupByIQ_0_1,
  output         io_commonOut_perfWakeupByIQ_0_2,
  output         io_commonOut_perfWakeupByIQ_0_3,
  output         io_commonOut_perfWakeupByIQ_0_4,
  output         io_commonOut_perfWakeupByIQ_0_5,
  output         io_commonOut_perfWakeupByIQ_0_6
);

  // BEGIN GENERATED(core-inst)
  // 入队负载按 Variant 的偏移表拼成一根 1330 位向量（transEntry 整包）
  logic [1329:0] enq_payload;
  assign enq_payload = {io_commonIn_enq_bits_payload_numLsElem, io_commonIn_enq_bits_payload_debug_sim_trig, io_commonIn_enq_bits_payload_debug_fuType, io_commonIn_enq_bits_payload_replayInst, io_commonIn_enq_bits_payload_singleStep, io_commonIn_enq_bits_payload_lqIdx_value, io_commonIn_enq_bits_payload_lqIdx_flag, io_commonIn_enq_bits_payload_ssid, io_commonIn_enq_bits_payload_loadWaitStrict, io_commonIn_enq_bits_payload_loadWaitBit, io_commonIn_enq_bits_payload_waitForRobIdx_value, io_commonIn_enq_bits_payload_waitForRobIdx_flag, io_commonIn_enq_bits_payload_storeSetHit, io_commonIn_enq_bits_payload_debugInfo_issueTime, io_commonIn_enq_bits_payload_debugInfo_selectTime, io_commonIn_enq_bits_payload_snapshot, io_commonIn_enq_bits_payload_eliminatedMove, io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize, io_commonIn_enq_bits_payload_traceBlockInPipe_iretire, io_commonIn_enq_bits_payload_traceBlockInPipe_itype, io_commonIn_enq_bits_payload_dirtyVs, io_commonIn_enq_bits_payload_dirtyFs, io_commonIn_enq_bits_payload_instrSize, io_commonIn_enq_bits_payload_robIdx_value, io_commonIn_enq_bits_payload_robIdx_flag, io_commonIn_enq_bits_payload_regCacheIdx_1, io_commonIn_enq_bits_payload_regCacheIdx_0, io_commonIn_enq_bits_payload_useRegCache_1, io_commonIn_enq_bits_payload_useRegCache_0, io_commonIn_enq_bits_payload_psrc_4, io_commonIn_enq_bits_payload_psrc_3, io_commonIn_enq_bits_payload_psrc_2, io_commonIn_enq_bits_payload_psrc_1, io_commonIn_enq_bits_payload_psrc_0, io_commonIn_enq_bits_payload_srcLoadDependency_4_2, io_commonIn_enq_bits_payload_srcLoadDependency_4_1, io_commonIn_enq_bits_payload_srcLoadDependency_4_0, io_commonIn_enq_bits_payload_srcLoadDependency_3_2, io_commonIn_enq_bits_payload_srcLoadDependency_3_1, io_commonIn_enq_bits_payload_srcLoadDependency_3_0, io_commonIn_enq_bits_payload_srcLoadDependency_2_2, io_commonIn_enq_bits_payload_srcLoadDependency_2_1, io_commonIn_enq_bits_payload_srcLoadDependency_2_0, io_commonIn_enq_bits_payload_srcLoadDependency_1_2, io_commonIn_enq_bits_payload_srcLoadDependency_1_1, io_commonIn_enq_bits_payload_srcLoadDependency_1_0, io_commonIn_enq_bits_payload_srcLoadDependency_0_2, io_commonIn_enq_bits_payload_srcLoadDependency_0_1, io_commonIn_enq_bits_payload_srcLoadDependency_0_0, io_commonIn_enq_bits_payload_srcState_4, io_commonIn_enq_bits_payload_srcState_3, io_commonIn_enq_bits_payload_srcState_2, io_commonIn_enq_bits_payload_srcState_1, io_commonIn_enq_bits_payload_srcState_0, io_commonIn_enq_bits_payload_commitType, io_commonIn_enq_bits_payload_numWB, io_commonIn_enq_bits_payload_numUops, io_commonIn_enq_bits_payload_lastUop, io_commonIn_enq_bits_payload_firstUop, io_commonIn_enq_bits_payload_isVset, io_commonIn_enq_bits_payload_uopIdx, io_commonIn_enq_bits_payload_isDropAmocasSta, io_commonIn_enq_bits_payload_isMove, io_commonIn_enq_bits_payload_wfflags, io_commonIn_enq_bits_payload_vlsInstr, io_commonIn_enq_bits_payload_vpu_isVleff, io_commonIn_enq_bits_payload_vpu_isWritePartVd, io_commonIn_enq_bits_payload_vpu_isDependOldVd, io_commonIn_enq_bits_payload_vpu_isMove, io_commonIn_enq_bits_payload_vpu_isOpMask, io_commonIn_enq_bits_payload_vpu_isDstMask, io_commonIn_enq_bits_payload_vpu_isNarrow, io_commonIn_enq_bits_payload_vpu_isExt, io_commonIn_enq_bits_payload_vpu_isReverse, io_commonIn_enq_bits_payload_vpu_veew, io_commonIn_enq_bits_payload_vpu_nf, io_commonIn_enq_bits_payload_vpu_vl, io_commonIn_enq_bits_payload_vpu_vmask, io_commonIn_enq_bits_payload_vpu_lastUop, io_commonIn_enq_bits_payload_vpu_vuopIdx, io_commonIn_enq_bits_payload_vpu_vxrm, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4, io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2, io_commonIn_enq_bits_payload_vpu_fpu_isReduction, io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr, io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr, io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst, io_commonIn_enq_bits_payload_vpu_frm, io_commonIn_enq_bits_payload_vpu_vstart, io_commonIn_enq_bits_payload_vpu_vm, io_commonIn_enq_bits_payload_vpu_specVlmul, io_commonIn_enq_bits_payload_vpu_specVsew, io_commonIn_enq_bits_payload_vpu_specVta, io_commonIn_enq_bits_payload_vpu_specVma, io_commonIn_enq_bits_payload_vpu_specVill, io_commonIn_enq_bits_payload_vpu_vlmul, io_commonIn_enq_bits_payload_vpu_vsew, io_commonIn_enq_bits_payload_vpu_vta, io_commonIn_enq_bits_payload_vpu_vma, io_commonIn_enq_bits_payload_vpu_vill, io_commonIn_enq_bits_payload_fpu_rm, io_commonIn_enq_bits_payload_fpu_fmt, io_commonIn_enq_bits_payload_fpu_typ, io_commonIn_enq_bits_payload_fpu_wflags, io_commonIn_enq_bits_payload_fpu_typeTagOut, io_commonIn_enq_bits_payload_imm, io_commonIn_enq_bits_payload_canRobCompress, io_commonIn_enq_bits_payload_flushPipe, io_commonIn_enq_bits_payload_blockBackward, io_commonIn_enq_bits_payload_waitForward, io_commonIn_enq_bits_payload_isXSTrap, io_commonIn_enq_bits_payload_vlWen, io_commonIn_enq_bits_payload_v0Wen, io_commonIn_enq_bits_payload_vecWen, io_commonIn_enq_bits_payload_fpWen, io_commonIn_enq_bits_payload_rfWen, io_commonIn_enq_bits_payload_fuType, io_commonIn_enq_bits_payload_ldest, io_commonIn_enq_bits_payload_srcType_4, io_commonIn_enq_bits_payload_srcType_3, io_commonIn_enq_bits_payload_srcType_2, io_commonIn_enq_bits_payload_srcType_1, io_commonIn_enq_bits_payload_srcType_0, io_commonIn_enq_bits_payload_satpFlushFirstFetchFault, io_commonIn_enq_bits_payload_ftqOffset, io_commonIn_enq_bits_payload_ftqPtr_value, io_commonIn_enq_bits_payload_ftqPtr_flag, io_commonIn_enq_bits_payload_crossPageIPFFix, io_commonIn_enq_bits_payload_pred_taken, io_commonIn_enq_bits_payload_preDecodeInfo_isRet, io_commonIn_enq_bits_payload_preDecodeInfo_isCall, io_commonIn_enq_bits_payload_preDecodeInfo_brType, io_commonIn_enq_bits_payload_preDecodeInfo_isRVC, io_commonIn_enq_bits_payload_preDecodeInfo_valid, io_commonIn_enq_bits_payload_trigger, io_commonIn_enq_bits_payload_hasException, io_commonIn_enq_bits_payload_isFetchMalAddr, io_commonIn_enq_bits_payload_exceptionVec_23, io_commonIn_enq_bits_payload_exceptionVec_22, io_commonIn_enq_bits_payload_exceptionVec_21, io_commonIn_enq_bits_payload_exceptionVec_20, io_commonIn_enq_bits_payload_exceptionVec_19, io_commonIn_enq_bits_payload_exceptionVec_18, io_commonIn_enq_bits_payload_exceptionVec_17, io_commonIn_enq_bits_payload_exceptionVec_16, io_commonIn_enq_bits_payload_exceptionVec_15, io_commonIn_enq_bits_payload_exceptionVec_14, io_commonIn_enq_bits_payload_exceptionVec_13, io_commonIn_enq_bits_payload_exceptionVec_12, io_commonIn_enq_bits_payload_exceptionVec_11, io_commonIn_enq_bits_payload_exceptionVec_10, io_commonIn_enq_bits_payload_exceptionVec_9, io_commonIn_enq_bits_payload_exceptionVec_8, io_commonIn_enq_bits_payload_exceptionVec_7, io_commonIn_enq_bits_payload_exceptionVec_6, io_commonIn_enq_bits_payload_exceptionVec_5, io_commonIn_enq_bits_payload_exceptionVec_4, io_commonIn_enq_bits_payload_exceptionVec_3, io_commonIn_enq_bits_payload_exceptionVec_2, io_commonIn_enq_bits_payload_exceptionVec_1, io_commonIn_enq_bits_payload_exceptionVec_0, io_commonIn_enq_bits_payload_foldpc, io_commonIn_enq_bits_payload_pc, io_commonIn_enq_bits_payload_instr, io_commonIn_enq_bits_payload_sqIdx_value, io_commonIn_enq_bits_payload_sqIdx_flag, io_commonIn_enq_bits_payload_debug_seqNum_uopIdx, io_commonIn_enq_bits_payload_debug_seqNum_seqNum, io_commonIn_enq_bits_payload_debugInfo_tlbRespTime, io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime, io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id, io_commonIn_enq_bits_payload_debugInfo_writebackTime, io_commonIn_enq_bits_payload_debugInfo_enqRsTime, io_commonIn_enq_bits_payload_debugInfo_dispatchTime, io_commonIn_enq_bits_payload_debugInfo_renameTime, io_commonIn_enq_bits_payload_debugInfo_eliminatedMove, io_commonIn_enq_bits_payload_pdest, io_commonIn_enq_bits_payload_selImm, io_commonIn_enq_bits_payload_fuOpType};

  logic [1:0] fu_type_narrow;
  logic [0:0][3:0] data_src;
  logic [0:0][2:0] exu_src;
  logic [540:0] ety_payload;
  logic [0:0][7:0] ety_psrc;
  logic [0:0][3:0] ety_src_type;
  logic [0:0][2:0][1:0] ety_ld_dep;
  logic [0:0][4:0] ety_rc_idx;
  logic [1329:0] trans_payload;
  logic [0:0][7:0] trans_psrc;
  logic [0:0][3:0] trans_src_type, trans_data_src;
  logic [0:0] trans_src_state, trans_use_rc;
  logic [0:0][2:0][1:0] trans_ld_dep;
  logic [0:0][2:0] trans_exu_src;
  logic [0:0][4:0] trans_rc_idx;
  logic [1:0] trans_fu_type;
  logic unused_deq_port_idx;

  xs_iq_entry #(
    .IS_ENQ(0), .IS_TRANS(1), .IS_COMP(0),
    .NUM_DEQ_PORTS(1),
    .NUM_REGSRC(1), .NUM_WK_WB(10), .NUM_FU_BIT(2),
    .ROB_W(8), .PSRC_W(8), .PDEST_W(8),
    .PL_DEQ_W(541), .PL_TRANS_W(1330),
    .HAS_LD_DEP(1), .HAS_LD1_CANCEL(1),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(7), .EXU_W(3),
    .IQ_SRC_MASK({7'b1111111}),
    .IQ_WEN_PRESENT(5'b00001),
    .IQD_WEN_PRESENT(5'b00000),
    .IQ_IS_LD_PIPE({3'b100, 3'b010, 3'b001, 3'b000, 3'b000, 3'b000, 3'b000}),
    .HAS_REG_CACHE(1), .RC_IDX_W(5),
    .IQ_WRITE_RC(7'b1111111), .RC_TYPE_BIT(0),
    .SRC_WB_MASK({10'b1111111111}),
    .SRC_MATCH_KIND({2'd0}),
    .WB_WEN_PRESENT(5'b00111),
    .WBD_WEN_PRESENT(5'b00000),
    .HAS_IGNORE_OLD_VD(0),
    .VD_SRC(0), .VL_SRC(0), .WB_VL_INT(0), .WB_VL_VF(0),
    .PLB_VM(812),
    .PLB_VMA(797),
    .PLB_VTA(798),
    .PLB_IS_DEPEND_OLDVD(988),
    .PLB_IS_WRITE_PARTVD(989),
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
    .enq_fu_type({io_commonIn_enq_bits_status_fuType_17, io_commonIn_enq_bits_status_fuType_16}),
    .enq_psrc({io_commonIn_enq_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_commonIn_enq_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_commonIn_enq_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_commonIn_enq_bits_status_srcStatus_0_dataSources_value}),
    .enq_blocked(io_commonIn_enq_bits_status_blocked),
    .enq_issued(io_commonIn_enq_bits_status_issued),
    .enq_first_issue(io_commonIn_enq_bits_status_firstIssue),
    .enq_issue_timer(io_commonIn_enq_bits_status_issueTimer),
    .enq_deq_port_idx(io_commonIn_enq_bits_status_deqPortIdx),
    .enq_payload(enq_payload),
    .enq_ld_dep({io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0}),
    .enq_exu_src({io_commonIn_enq_bits_status_srcStatus_0_exuSources_value}),
    .enq_use_rc({io_commonIn_enq_bits_status_srcStatus_0_useRegCache}),
    .enq_rc_idx({io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx}),
    .wk_valid({io_commonIn_wakeUpFromWB_9_valid, io_commonIn_wakeUpFromWB_8_valid, io_commonIn_wakeUpFromWB_7_valid, io_commonIn_wakeUpFromWB_6_valid, io_commonIn_wakeUpFromWB_5_valid, io_commonIn_wakeUpFromWB_4_valid, io_commonIn_wakeUpFromWB_3_valid, io_commonIn_wakeUpFromWB_2_valid, io_commonIn_wakeUpFromWB_1_valid, io_commonIn_wakeUpFromWB_0_valid}),
    .wk_wen({{1'b0, 1'b0, io_commonIn_wakeUpFromWB_9_bits_vecWen, io_commonIn_wakeUpFromWB_9_bits_fpWen, io_commonIn_wakeUpFromWB_9_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_8_bits_vecWen, io_commonIn_wakeUpFromWB_8_bits_fpWen, io_commonIn_wakeUpFromWB_8_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_7_bits_vecWen, io_commonIn_wakeUpFromWB_7_bits_fpWen, io_commonIn_wakeUpFromWB_7_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_6_bits_vecWen, io_commonIn_wakeUpFromWB_6_bits_fpWen, io_commonIn_wakeUpFromWB_6_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_5_bits_vecWen, io_commonIn_wakeUpFromWB_5_bits_fpWen, io_commonIn_wakeUpFromWB_5_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_4_bits_vecWen, io_commonIn_wakeUpFromWB_4_bits_fpWen, io_commonIn_wakeUpFromWB_4_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_3_bits_vecWen, io_commonIn_wakeUpFromWB_3_bits_fpWen, io_commonIn_wakeUpFromWB_3_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_2_bits_vecWen, io_commonIn_wakeUpFromWB_2_bits_fpWen, io_commonIn_wakeUpFromWB_2_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_1_bits_vecWen, io_commonIn_wakeUpFromWB_1_bits_fpWen, io_commonIn_wakeUpFromWB_1_bits_rfWen}, {1'b0, 1'b0, io_commonIn_wakeUpFromWB_0_bits_vecWen, io_commonIn_wakeUpFromWB_0_bits_fpWen, io_commonIn_wakeUpFromWB_0_bits_rfWen}}),
    .wk_pdest({io_commonIn_wakeUpFromWB_9_bits_pdest, io_commonIn_wakeUpFromWB_8_bits_pdest, io_commonIn_wakeUpFromWB_7_bits_pdest, io_commonIn_wakeUpFromWB_6_bits_pdest, io_commonIn_wakeUpFromWB_5_bits_pdest, io_commonIn_wakeUpFromWB_4_bits_pdest, io_commonIn_wakeUpFromWB_3_bits_pdest, io_commonIn_wakeUpFromWB_2_bits_pdest, io_commonIn_wakeUpFromWB_1_bits_pdest, io_commonIn_wakeUpFromWB_0_bits_pdest}),
    // ★ 入队延迟窗口只有 EnqEntry 有（IS_ENQ=1）；OthersEntry 的 golden
    //   根本没有 wakeUpFromWBDelayed / enqDelay 这组端口，故整组钉 0
    .wkd_valid('0), .wkd_wen('0), .wkd_pdest('0),
    .iq_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_6_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_5_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_4_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_0_bits_rfWen}}),
    .iq_pdest({io_commonIn_wakeUpFromIQ_6_bits_pdest, io_commonIn_wakeUpFromIQ_5_bits_pdest, io_commonIn_wakeUpFromIQ_4_bits_pdest, io_commonIn_wakeUpFromIQ_3_bits_pdest, io_commonIn_wakeUpFromIQ_2_bits_pdest, io_commonIn_wakeUpFromIQ_1_bits_pdest, io_commonIn_wakeUpFromIQ_0_bits_pdest}),
    .iq_ld_dep({io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0}),
    .iq_rc_dest({io_commonIn_wakeUpFromIQ_6_bits_rcDest, io_commonIn_wakeUpFromIQ_5_bits_rcDest, io_commonIn_wakeUpFromIQ_4_bits_rcDest, io_commonIn_wakeUpFromIQ_3_bits_rcDest, io_commonIn_wakeUpFromIQ_2_bits_rcDest, io_commonIn_wakeUpFromIQ_1_bits_rcDest, io_commonIn_wakeUpFromIQ_0_bits_rcDest}),
    // iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]；
    // og0Cancel 的下标是稀疏的，is0Lat 有的路被 firtool 折成常量。
    .iq_cancel({(io_commonIn_og0Cancel_22 & io_commonIn_wakeUpFromIQ_6_bits_is0Lat), (io_commonIn_og0Cancel_21 & io_commonIn_wakeUpFromIQ_5_bits_is0Lat), (io_commonIn_og0Cancel_20 & io_commonIn_wakeUpFromIQ_4_bits_is0Lat), (io_commonIn_og0Cancel_6 & io_commonIn_wakeUpFromIQ_3_bits_is0Lat), (io_commonIn_og0Cancel_4 & io_commonIn_wakeUpFromIQ_2_bits_is0Lat), (io_commonIn_og0Cancel_2 & io_commonIn_wakeUpFromIQ_1_bits_is0Lat), (io_commonIn_og0Cancel_0 & io_commonIn_wakeUpFromIQ_0_bits_is0Lat)}),
    .iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0),
    .iqd_cancel('0),
    .ld1_cancel({io_commonIn_ldCancel_2_ld1Cancel, io_commonIn_ldCancel_1_ld1Cancel, io_commonIn_ldCancel_0_ld1Cancel}),
    .ld2_cancel({io_commonIn_ldCancel_2_ld2Cancel, io_commonIn_ldCancel_1_ld2Cancel, io_commonIn_ldCancel_0_ld2Cancel}),
    .ld1d_cancel('0), .ld2d_cancel('0), .enqd_self_ld_dep('0),
    .vl_int_is_zero(1'b0),
    .vl_int_is_vlmax(1'b0),
    .vl_vf_is_zero(1'b0),
    .vl_vf_is_vlmax(1'b0),
    .deq_sel(io_commonIn_deqSel),
    .deq_port_idx_write(1'b0),
    .resp_valid(io_commonIn_issueResp_valid),
    .resp_bits(io_commonIn_issueResp_bits_resp),
    .enq_vm('0), .enq_vpr('0), .enq_vr_mask('0), .enq_vr_mbidx('0),
    .lq_deq_ptr('0), .resp_vpr('0), .resp_vr_mask('0), .resp_vr_mbidx('0),
    .trans_sel(io_commonIn_transSel),
    .o_valid(io_commonOut_valid), .o_issued(io_commonOut_issued),
    .o_can_issue(io_commonOut_canIssue),
    .o_cancel_bypass(io_commonOut_cancelBypass),
    .o_is_first_issue(io_commonOut_isFirstIssue),
    .o_fu_type(fu_type_narrow), .o_data_src(data_src),
    .o_issue_timer(io_commonOut_issueTimerRead),
    .o_deq_port_idx(unused_deq_port_idx),
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
    .o_dbg_perf_ld_cancel({io_commonOut_perfLdCancel_0}),
    .o_dbg_perf_og0_cancel({io_commonOut_perfOg0Cancel_0}),
    .o_dbg_perf_wakeup_by_wb({io_commonOut_perfWakeupByWB_0}),
    .o_dbg_perf_wakeup_by_iq({io_commonOut_perfWakeupByIQ_0_6, io_commonOut_perfWakeupByIQ_0_5, io_commonOut_perfWakeupByIQ_0_4, io_commonOut_perfWakeupByIQ_0_3, io_commonOut_perfWakeupByIQ_0_2, io_commonOut_perfWakeupByIQ_0_1, io_commonOut_perfWakeupByIQ_0_0})
  );

  // fuType 出口：核只存本变体保留的 2 位，这里放回 35 位 one-hot 的原位置
  assign io_commonOut_fuType = {17'h0, fu_type_narrow[1], fu_type_narrow[0], 16'h0};

  assign io_commonOut_dataSources_0_value = data_src[0];
  assign io_commonOut_exuSources_0_value = exu_src[0];

  // commonOut.entry.bits.status —— fuType 与 commonOut.fuType 同一组寄存器
  assign io_commonOut_entry_bits_status_fuType_16 = fu_type_narrow[0];
  assign io_commonOut_entry_bits_status_fuType_17 = fu_type_narrow[1];
  assign io_commonOut_entry_bits_status_srcStatus_0_psrc = ety_psrc[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcType = ety_src_type[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx = ety_rc_idx[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0 = ety_ld_dep[0][0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1 = ety_ld_dep[0][1];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2 = ety_ld_dep[0][2];
  assign io_commonOut_entry_bits_payload_fuOpType = ety_payload[8:0];
  assign io_commonOut_entry_bits_payload_selImm = ety_payload[12:9];
  assign io_commonOut_entry_bits_payload_pdest = ety_payload[20:13];
  assign io_commonOut_entry_bits_payload_debugInfo_eliminatedMove = ety_payload[21];
  assign io_commonOut_entry_bits_payload_debugInfo_renameTime = ety_payload[85:22];
  assign io_commonOut_entry_bits_payload_debugInfo_dispatchTime = ety_payload[149:86];
  assign io_commonOut_entry_bits_payload_debugInfo_enqRsTime = ety_payload[213:150];
  assign io_commonOut_entry_bits_payload_debugInfo_writebackTime = ety_payload[277:214];
  assign io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id = ety_payload[341:278];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime = ety_payload[405:342];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbRespTime = ety_payload[469:406];
  assign io_commonOut_entry_bits_payload_debug_seqNum_seqNum = ety_payload[525:470];
  assign io_commonOut_entry_bits_payload_debug_seqNum_uopIdx = ety_payload[533:526];
  assign io_commonOut_entry_bits_payload_sqIdx_flag = ety_payload[534];
  assign io_commonOut_entry_bits_payload_sqIdx_value = ety_payload[540:535];

  // commonOut.transEntry —— 交给下一级的整包（= entryUpdate）
  assign io_commonOut_transEntry_bits_status_fuType_16 = trans_fu_type[0];
  assign io_commonOut_transEntry_bits_status_fuType_17 = trans_fu_type[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_psrc = trans_psrc[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcType = trans_src_type[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcState = trans_src_state[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_dataSources_value = trans_data_src[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_exuSources_value = trans_exu_src[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_useRegCache = trans_use_rc[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_regCacheIdx = trans_rc_idx[0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_0 = trans_ld_dep[0][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_1 = trans_ld_dep[0][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_0_srcLoadDependency_2 = trans_ld_dep[0][2];
  assign io_commonOut_transEntry_bits_payload_fuOpType = trans_payload[8:0];
  assign io_commonOut_transEntry_bits_payload_selImm = trans_payload[12:9];
  assign io_commonOut_transEntry_bits_payload_pdest = trans_payload[20:13];
  assign io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove = trans_payload[21];
  assign io_commonOut_transEntry_bits_payload_debugInfo_renameTime = trans_payload[85:22];
  assign io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime = trans_payload[149:86];
  assign io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime = trans_payload[213:150];
  assign io_commonOut_transEntry_bits_payload_debugInfo_writebackTime = trans_payload[277:214];
  assign io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id = trans_payload[341:278];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime = trans_payload[405:342];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime = trans_payload[469:406];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum = trans_payload[525:470];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx = trans_payload[533:526];
  assign io_commonOut_transEntry_bits_payload_sqIdx_flag = trans_payload[534];
  assign io_commonOut_transEntry_bits_payload_sqIdx_value = trans_payload[540:535];
  assign io_commonOut_transEntry_bits_payload_instr = trans_payload[572:541];
  assign io_commonOut_transEntry_bits_payload_pc = trans_payload[622:573];
  assign io_commonOut_transEntry_bits_payload_foldpc = trans_payload[632:623];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_0 = trans_payload[633];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_1 = trans_payload[634];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_2 = trans_payload[635];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_3 = trans_payload[636];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_4 = trans_payload[637];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_5 = trans_payload[638];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_6 = trans_payload[639];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_7 = trans_payload[640];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_8 = trans_payload[641];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_9 = trans_payload[642];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_10 = trans_payload[643];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_11 = trans_payload[644];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_12 = trans_payload[645];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_13 = trans_payload[646];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_14 = trans_payload[647];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_15 = trans_payload[648];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_16 = trans_payload[649];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_17 = trans_payload[650];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_18 = trans_payload[651];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_19 = trans_payload[652];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_20 = trans_payload[653];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_21 = trans_payload[654];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_22 = trans_payload[655];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_23 = trans_payload[656];
  assign io_commonOut_transEntry_bits_payload_isFetchMalAddr = trans_payload[657];
  assign io_commonOut_transEntry_bits_payload_hasException = trans_payload[658];
  assign io_commonOut_transEntry_bits_payload_trigger = trans_payload[662:659];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_valid = trans_payload[663];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC = trans_payload[664];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_brType = trans_payload[666:665];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall = trans_payload[667];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet = trans_payload[668];
  assign io_commonOut_transEntry_bits_payload_pred_taken = trans_payload[669];
  assign io_commonOut_transEntry_bits_payload_crossPageIPFFix = trans_payload[670];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_flag = trans_payload[671];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_value = trans_payload[677:672];
  assign io_commonOut_transEntry_bits_payload_ftqOffset = trans_payload[681:678];
  assign io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault = trans_payload[682];
  assign io_commonOut_transEntry_bits_payload_srcType_0 = trans_payload[686:683];
  assign io_commonOut_transEntry_bits_payload_srcType_1 = trans_payload[690:687];
  assign io_commonOut_transEntry_bits_payload_srcType_2 = trans_payload[694:691];
  assign io_commonOut_transEntry_bits_payload_srcType_3 = trans_payload[698:695];
  assign io_commonOut_transEntry_bits_payload_srcType_4 = trans_payload[702:699];
  assign io_commonOut_transEntry_bits_payload_ldest = trans_payload[708:703];
  assign io_commonOut_transEntry_bits_payload_fuType = trans_payload[743:709];
  assign io_commonOut_transEntry_bits_payload_rfWen = trans_payload[744];
  assign io_commonOut_transEntry_bits_payload_fpWen = trans_payload[745];
  assign io_commonOut_transEntry_bits_payload_vecWen = trans_payload[746];
  assign io_commonOut_transEntry_bits_payload_v0Wen = trans_payload[747];
  assign io_commonOut_transEntry_bits_payload_vlWen = trans_payload[748];
  assign io_commonOut_transEntry_bits_payload_isXSTrap = trans_payload[749];
  assign io_commonOut_transEntry_bits_payload_waitForward = trans_payload[750];
  assign io_commonOut_transEntry_bits_payload_blockBackward = trans_payload[751];
  assign io_commonOut_transEntry_bits_payload_flushPipe = trans_payload[752];
  assign io_commonOut_transEntry_bits_payload_canRobCompress = trans_payload[753];
  assign io_commonOut_transEntry_bits_payload_imm = trans_payload[785:754];
  assign io_commonOut_transEntry_bits_payload_fpu_typeTagOut = trans_payload[787:786];
  assign io_commonOut_transEntry_bits_payload_fpu_wflags = trans_payload[788];
  assign io_commonOut_transEntry_bits_payload_fpu_typ = trans_payload[790:789];
  assign io_commonOut_transEntry_bits_payload_fpu_fmt = trans_payload[792:791];
  assign io_commonOut_transEntry_bits_payload_fpu_rm = trans_payload[795:793];
  assign io_commonOut_transEntry_bits_payload_vpu_vill = trans_payload[796];
  assign io_commonOut_transEntry_bits_payload_vpu_vma = trans_payload[797];
  assign io_commonOut_transEntry_bits_payload_vpu_vta = trans_payload[798];
  assign io_commonOut_transEntry_bits_payload_vpu_vsew = trans_payload[800:799];
  assign io_commonOut_transEntry_bits_payload_vpu_vlmul = trans_payload[803:801];
  assign io_commonOut_transEntry_bits_payload_vpu_specVill = trans_payload[804];
  assign io_commonOut_transEntry_bits_payload_vpu_specVma = trans_payload[805];
  assign io_commonOut_transEntry_bits_payload_vpu_specVta = trans_payload[806];
  assign io_commonOut_transEntry_bits_payload_vpu_specVsew = trans_payload[808:807];
  assign io_commonOut_transEntry_bits_payload_vpu_specVlmul = trans_payload[811:809];
  assign io_commonOut_transEntry_bits_payload_vpu_vm = trans_payload[812];
  assign io_commonOut_transEntry_bits_payload_vpu_vstart = trans_payload[820:813];
  assign io_commonOut_transEntry_bits_payload_vpu_frm = trans_payload[823:821];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst = trans_payload[824];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr = trans_payload[825];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr = trans_payload[826];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction = trans_payload[827];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2 = trans_payload[828];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4 = trans_payload[829];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8 = trans_payload[830];
  assign io_commonOut_transEntry_bits_payload_vpu_vxrm = trans_payload[832:831];
  assign io_commonOut_transEntry_bits_payload_vpu_vuopIdx = trans_payload[839:833];
  assign io_commonOut_transEntry_bits_payload_vpu_lastUop = trans_payload[840];
  assign io_commonOut_transEntry_bits_payload_vpu_vmask = trans_payload[968:841];
  assign io_commonOut_transEntry_bits_payload_vpu_vl = trans_payload[976:969];
  assign io_commonOut_transEntry_bits_payload_vpu_nf = trans_payload[979:977];
  assign io_commonOut_transEntry_bits_payload_vpu_veew = trans_payload[981:980];
  assign io_commonOut_transEntry_bits_payload_vpu_isReverse = trans_payload[982];
  assign io_commonOut_transEntry_bits_payload_vpu_isExt = trans_payload[983];
  assign io_commonOut_transEntry_bits_payload_vpu_isNarrow = trans_payload[984];
  assign io_commonOut_transEntry_bits_payload_vpu_isDstMask = trans_payload[985];
  assign io_commonOut_transEntry_bits_payload_vpu_isOpMask = trans_payload[986];
  assign io_commonOut_transEntry_bits_payload_vpu_isMove = trans_payload[987];
  assign io_commonOut_transEntry_bits_payload_vpu_isDependOldVd = trans_payload[988];
  assign io_commonOut_transEntry_bits_payload_vpu_isWritePartVd = trans_payload[989];
  assign io_commonOut_transEntry_bits_payload_vpu_isVleff = trans_payload[990];
  assign io_commonOut_transEntry_bits_payload_vlsInstr = trans_payload[991];
  assign io_commonOut_transEntry_bits_payload_wfflags = trans_payload[992];
  assign io_commonOut_transEntry_bits_payload_isMove = trans_payload[993];
  assign io_commonOut_transEntry_bits_payload_isDropAmocasSta = trans_payload[994];
  assign io_commonOut_transEntry_bits_payload_uopIdx = trans_payload[1001:995];
  assign io_commonOut_transEntry_bits_payload_isVset = trans_payload[1002];
  assign io_commonOut_transEntry_bits_payload_firstUop = trans_payload[1003];
  assign io_commonOut_transEntry_bits_payload_lastUop = trans_payload[1004];
  assign io_commonOut_transEntry_bits_payload_numUops = trans_payload[1011:1005];
  assign io_commonOut_transEntry_bits_payload_numWB = trans_payload[1018:1012];
  assign io_commonOut_transEntry_bits_payload_commitType = trans_payload[1021:1019];
  assign io_commonOut_transEntry_bits_payload_srcState_0 = trans_payload[1022];
  assign io_commonOut_transEntry_bits_payload_srcState_1 = trans_payload[1023];
  assign io_commonOut_transEntry_bits_payload_srcState_2 = trans_payload[1024];
  assign io_commonOut_transEntry_bits_payload_srcState_3 = trans_payload[1025];
  assign io_commonOut_transEntry_bits_payload_srcState_4 = trans_payload[1026];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0 = trans_payload[1028:1027];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1 = trans_payload[1030:1029];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2 = trans_payload[1032:1031];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0 = trans_payload[1034:1033];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1 = trans_payload[1036:1035];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2 = trans_payload[1038:1037];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0 = trans_payload[1040:1039];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1 = trans_payload[1042:1041];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2 = trans_payload[1044:1043];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0 = trans_payload[1046:1045];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1 = trans_payload[1048:1047];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2 = trans_payload[1050:1049];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0 = trans_payload[1052:1051];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1 = trans_payload[1054:1053];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2 = trans_payload[1056:1055];
  assign io_commonOut_transEntry_bits_payload_psrc_0 = trans_payload[1064:1057];
  assign io_commonOut_transEntry_bits_payload_psrc_1 = trans_payload[1072:1065];
  assign io_commonOut_transEntry_bits_payload_psrc_2 = trans_payload[1080:1073];
  assign io_commonOut_transEntry_bits_payload_psrc_3 = trans_payload[1088:1081];
  assign io_commonOut_transEntry_bits_payload_psrc_4 = trans_payload[1096:1089];
  assign io_commonOut_transEntry_bits_payload_useRegCache_0 = trans_payload[1097];
  assign io_commonOut_transEntry_bits_payload_useRegCache_1 = trans_payload[1098];
  assign io_commonOut_transEntry_bits_payload_regCacheIdx_0 = trans_payload[1103:1099];
  assign io_commonOut_transEntry_bits_payload_regCacheIdx_1 = trans_payload[1108:1104];
  assign io_commonOut_transEntry_bits_payload_robIdx_flag = trans_payload[1109];
  assign io_commonOut_transEntry_bits_payload_robIdx_value = trans_payload[1117:1110];
  assign io_commonOut_transEntry_bits_payload_instrSize = trans_payload[1120:1118];
  assign io_commonOut_transEntry_bits_payload_dirtyFs = trans_payload[1121];
  assign io_commonOut_transEntry_bits_payload_dirtyVs = trans_payload[1122];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype = trans_payload[1126:1123];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire = trans_payload[1130:1127];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize = trans_payload[1131];
  assign io_commonOut_transEntry_bits_payload_eliminatedMove = trans_payload[1132];
  assign io_commonOut_transEntry_bits_payload_snapshot = trans_payload[1133];
  assign io_commonOut_transEntry_bits_payload_debugInfo_selectTime = trans_payload[1197:1134];
  assign io_commonOut_transEntry_bits_payload_debugInfo_issueTime = trans_payload[1261:1198];
  assign io_commonOut_transEntry_bits_payload_storeSetHit = trans_payload[1262];
  assign io_commonOut_transEntry_bits_payload_waitForRobIdx_flag = trans_payload[1263];
  assign io_commonOut_transEntry_bits_payload_waitForRobIdx_value = trans_payload[1271:1264];
  assign io_commonOut_transEntry_bits_payload_loadWaitBit = trans_payload[1272];
  assign io_commonOut_transEntry_bits_payload_loadWaitStrict = trans_payload[1273];
  assign io_commonOut_transEntry_bits_payload_ssid = trans_payload[1278:1274];
  assign io_commonOut_transEntry_bits_payload_lqIdx_flag = trans_payload[1279];
  assign io_commonOut_transEntry_bits_payload_lqIdx_value = trans_payload[1286:1280];
  assign io_commonOut_transEntry_bits_payload_singleStep = trans_payload[1287];
  assign io_commonOut_transEntry_bits_payload_replayInst = trans_payload[1288];
  assign io_commonOut_transEntry_bits_payload_debug_fuType = trans_payload[1323:1289];
  assign io_commonOut_transEntry_bits_payload_debug_sim_trig = trans_payload[1324];
  assign io_commonOut_transEntry_bits_payload_numLsElem = trans_payload[1329:1325];
  // END GENERATED(core-inst)

endmodule
