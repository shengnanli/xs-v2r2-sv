// EnqEntry_4.sv —— 发射队列**入队条目**（AluBrhJmpI2fVsetriwiVsetriwvfI2v 变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*
// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。
//
// 在流水线里的位置：派遣(dispatch)来的新 uop 落在**入队条目**上。它与其它条目
// 的三处差别（核里由 IS_ENQ=1 表达）：
//   1) 装载条件带 enqReady（= 本条目空 或 本拍正被搬走）；
//   2) 装载时 issued=0 / firstIssue=0 / issueTimer=3 强制写入，而不是从上一级
//      的 transEntry 继承 —— 所以 golden 这个模块没有 enq.status.issued 等端口；
//   3) 多一拍「入队延迟唤醒」窗口：入队后的**下一拍**再用 io_enqDelayIn1_* 这组
//      延迟总线补一次唤醒匹配（派遣与唤醒总线之间差一拍，不补就会漏唤醒）。
//   golden 里由 EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v 例化 2 份（实例名 enqEntries_*）。
//
// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的
//   Variant("EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v") —— 那张表本来就是从本模块量出来的）：
//   源寄存器 2 个，发射口 2 个（deqPortIdxRead 有）
//   WB 唤醒 4 路（rfWen）+ IQ 即时唤醒 7 路；延迟窗口同宽（WB 4 / IQ 7）
//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：
//     IQ0: og0Cancel[0], is0Lat=real
//     IQ1: og0Cancel[2], is0Lat=real
//     IQ2: og0Cancel[4], is0Lat=const1
//     IQ3: og0Cancel[6], is0Lat=const1
//     IQ4: 无取消, is0Lat=const0, 自身是 load 流水 0
//     IQ5: 无取消, is0Lat=const0, 自身是 load 流水 1
//     IQ6: 无取消, is0Lat=const0, 自身是 load 流水 2
//   保留的 FuType one-hot 位：FuType[0], FuType[1], FuType[2], FuType[3], FuType[6], FuType[28], FuType[29]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位
//   负载：发射口可见 33 个字段 / 599 位；转移包另带 148 个字段，共 1362 位
//
// ★ 没有 commonOut.enqReady 端口 ★：核里照样算 enq_ready（装载条件要用），
//   但 golden 的 EnqEntry 不把它露出来（实测 14/14 变体都没有），故接悬空线。
//
// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出
//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool
//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。
//
// 自动生成：verif/ut/EnqEntry_4/gen.py（共享库 verif/ut/EnqEntry_common/enqentry_gen.py）—— 勿手改
// =============================================================================
module EnqEntry_4 (
  input          clock,
  input          reset,
  input          io_commonIn_flush_valid,
  input          io_commonIn_flush_bits_robIdx_flag,
  input  [7:0]   io_commonIn_flush_bits_robIdx_value,
  input          io_commonIn_flush_bits_level,
  input          io_commonIn_enq_valid,
  input          io_commonIn_enq_bits_status_robIdx_flag,
  input  [7:0]   io_commonIn_enq_bits_status_robIdx_value,
  input          io_commonIn_enq_bits_status_fuType_0,
  input          io_commonIn_enq_bits_status_fuType_1,
  input          io_commonIn_enq_bits_status_fuType_2,
  input          io_commonIn_enq_bits_status_fuType_3,
  input          io_commonIn_enq_bits_status_fuType_6,
  input          io_commonIn_enq_bits_status_fuType_28,
  input          io_commonIn_enq_bits_status_fuType_29,
  input  [7:0]   io_commonIn_enq_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2,
  input          io_commonIn_enq_bits_status_srcStatus_0_useRegCache,
  input  [4:0]   io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx,
  input  [7:0]   io_commonIn_enq_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_1_srcType,
  input          io_commonIn_enq_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_commonIn_enq_bits_status_srcStatus_1_dataSources_value,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0]   io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2,
  input          io_commonIn_enq_bits_status_srcStatus_1_useRegCache,
  input  [4:0]   io_commonIn_enq_bits_status_srcStatus_1_regCacheIdx,
  input  [31:0]  io_commonIn_enq_bits_imm,
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
  input          io_commonIn_wakeUpFromWB_3_valid,
  input          io_commonIn_wakeUpFromWB_3_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_3_bits_pdest,
  input          io_commonIn_wakeUpFromWB_2_valid,
  input          io_commonIn_wakeUpFromWB_2_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_2_bits_pdest,
  input          io_commonIn_wakeUpFromWB_1_valid,
  input          io_commonIn_wakeUpFromWB_1_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_1_bits_pdest,
  input          io_commonIn_wakeUpFromWB_0_valid,
  input          io_commonIn_wakeUpFromWB_0_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromWB_0_bits_pdest,
  input          io_commonIn_wakeUpFromIQ_6_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_6_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2,
  input  [4:0]   io_commonIn_wakeUpFromIQ_6_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_5_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_5_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2,
  input  [4:0]   io_commonIn_wakeUpFromIQ_5_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_4_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_4_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2,
  input  [4:0]   io_commonIn_wakeUpFromIQ_4_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_3_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_3_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2,
  input  [4:0]   io_commonIn_wakeUpFromIQ_3_bits_rcDest,
  input          io_commonIn_wakeUpFromIQ_2_bits_rfWen,
  input  [7:0]   io_commonIn_wakeUpFromIQ_2_bits_pdest,
  input  [1:0]   io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0,
  input  [1:0]   io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1,
  input  [1:0]   io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2,
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
  input          io_commonIn_ldCancel_0_ld2Cancel,
  input          io_commonIn_ldCancel_1_ld2Cancel,
  input          io_commonIn_ldCancel_2_ld2Cancel,
  input          io_commonIn_deqSel,
  input          io_commonIn_deqPortIdxWrite,
  input          io_commonIn_issueResp_valid,
  input  [1:0]   io_commonIn_issueResp_bits_resp,
  input          io_commonIn_transSel,
  input          io_enqDelayIn1_wakeUpFromWB_3_valid,
  input          io_enqDelayIn1_wakeUpFromWB_3_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromWB_3_bits_pdest,
  input          io_enqDelayIn1_wakeUpFromWB_2_valid,
  input          io_enqDelayIn1_wakeUpFromWB_2_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromWB_2_bits_pdest,
  input          io_enqDelayIn1_wakeUpFromWB_1_valid,
  input          io_enqDelayIn1_wakeUpFromWB_1_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromWB_1_bits_pdest,
  input          io_enqDelayIn1_wakeUpFromWB_0_valid,
  input          io_enqDelayIn1_wakeUpFromWB_0_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromWB_0_bits_pdest,
  input          io_enqDelayIn1_wakeUpFromIQ_6_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_6_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_6_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_6_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_6_bits_loadDependency_2,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_6_bits_rcDest,
  input          io_enqDelayIn1_wakeUpFromIQ_5_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_5_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_5_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_5_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_5_bits_loadDependency_2,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_5_bits_rcDest,
  input          io_enqDelayIn1_wakeUpFromIQ_4_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_4_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_4_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_4_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_4_bits_loadDependency_2,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_4_bits_rcDest,
  input          io_enqDelayIn1_wakeUpFromIQ_3_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_3_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_3_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_3_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_3_bits_loadDependency_2,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_3_bits_rcDest,
  input          io_enqDelayIn1_wakeUpFromIQ_2_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_2_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_2_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_2_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_2_bits_loadDependency_2,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_2_bits_rcDest,
  input          io_enqDelayIn1_wakeUpFromIQ_1_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_1_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_1_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_1_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_1_bits_loadDependency_2,
  input          io_enqDelayIn1_wakeUpFromIQ_1_bits_is0Lat,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_1_bits_rcDest,
  input          io_enqDelayIn1_wakeUpFromIQ_0_bits_rfWen,
  input  [7:0]   io_enqDelayIn1_wakeUpFromIQ_0_bits_pdest,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_0,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_1,
  input  [1:0]   io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_2,
  input          io_enqDelayIn1_wakeUpFromIQ_0_bits_is0Lat,
  input  [4:0]   io_enqDelayIn1_wakeUpFromIQ_0_bits_rcDest,
  input  [1:0]   io_enqDelayIn1_srcLoadDependency_0_0,
  input  [1:0]   io_enqDelayIn1_srcLoadDependency_0_1,
  input  [1:0]   io_enqDelayIn1_srcLoadDependency_0_2,
  input  [1:0]   io_enqDelayIn1_srcLoadDependency_1_0,
  input  [1:0]   io_enqDelayIn1_srcLoadDependency_1_1,
  input  [1:0]   io_enqDelayIn1_srcLoadDependency_1_2,
  input          io_enqDelayIn1_og0Cancel_0,
  input          io_enqDelayIn1_og0Cancel_2,
  input          io_enqDelayIn1_og0Cancel_4,
  input          io_enqDelayIn1_og0Cancel_6,
  input          io_enqDelayIn1_ldCancel_0_ld2Cancel,
  input          io_enqDelayIn1_ldCancel_1_ld2Cancel,
  input          io_enqDelayIn1_ldCancel_2_ld2Cancel,
  output         io_commonOut_valid,
  output         io_commonOut_issued,
  output         io_commonOut_canIssue,
  output [34:0]  io_commonOut_fuType,
  output [3:0]   io_commonOut_dataSources_0_value,
  output [3:0]   io_commonOut_dataSources_1_value,
  output [2:0]   io_commonOut_exuSources_0_value,
  output [2:0]   io_commonOut_exuSources_1_value,
  output         io_commonOut_isFirstIssue,
  output         io_commonOut_entry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_entry_bits_status_robIdx_value,
  output         io_commonOut_entry_bits_status_fuType_0,
  output         io_commonOut_entry_bits_status_fuType_1,
  output         io_commonOut_entry_bits_status_fuType_2,
  output         io_commonOut_entry_bits_status_fuType_3,
  output         io_commonOut_entry_bits_status_fuType_6,
  output         io_commonOut_entry_bits_status_fuType_28,
  output         io_commonOut_entry_bits_status_fuType_29,
  output [7:0]   io_commonOut_entry_bits_status_srcStatus_0_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_0_srcType,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2,
  output [4:0]   io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx,
  output [7:0]   io_commonOut_entry_bits_status_srcStatus_1_psrc,
  output [3:0]   io_commonOut_entry_bits_status_srcStatus_1_srcType,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_0,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_1,
  output [1:0]   io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_2,
  output [4:0]   io_commonOut_entry_bits_status_srcStatus_1_regCacheIdx,
  output [31:0]  io_commonOut_entry_bits_imm,
  output         io_commonOut_entry_bits_payload_preDecodeInfo_valid,
  output         io_commonOut_entry_bits_payload_preDecodeInfo_isRVC,
  output [1:0]   io_commonOut_entry_bits_payload_preDecodeInfo_brType,
  output         io_commonOut_entry_bits_payload_preDecodeInfo_isCall,
  output         io_commonOut_entry_bits_payload_preDecodeInfo_isRet,
  output         io_commonOut_entry_bits_payload_pred_taken,
  output         io_commonOut_entry_bits_payload_ftqPtr_flag,
  output [5:0]   io_commonOut_entry_bits_payload_ftqPtr_value,
  output [3:0]   io_commonOut_entry_bits_payload_ftqOffset,
  output [8:0]   io_commonOut_entry_bits_payload_fuOpType,
  output         io_commonOut_entry_bits_payload_rfWen,
  output         io_commonOut_entry_bits_payload_fpWen,
  output         io_commonOut_entry_bits_payload_vecWen,
  output         io_commonOut_entry_bits_payload_v0Wen,
  output         io_commonOut_entry_bits_payload_vlWen,
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
  output         io_commonOut_cancelBypass,
  output         io_commonOut_deqPortIdxRead,
  output [1:0]   io_commonOut_issueTimerRead,
  output         io_commonOut_transEntry_valid,
  output         io_commonOut_transEntry_bits_status_robIdx_flag,
  output [7:0]   io_commonOut_transEntry_bits_status_robIdx_value,
  output         io_commonOut_transEntry_bits_status_fuType_0,
  output         io_commonOut_transEntry_bits_status_fuType_1,
  output         io_commonOut_transEntry_bits_status_fuType_2,
  output         io_commonOut_transEntry_bits_status_fuType_3,
  output         io_commonOut_transEntry_bits_status_fuType_6,
  output         io_commonOut_transEntry_bits_status_fuType_28,
  output         io_commonOut_transEntry_bits_status_fuType_29,
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
  output [7:0]   io_commonOut_transEntry_bits_status_srcStatus_1_psrc,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcType,
  output         io_commonOut_transEntry_bits_status_srcStatus_1_srcState,
  output [3:0]   io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1,
  output [1:0]   io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2,
  output [2:0]   io_commonOut_transEntry_bits_status_srcStatus_1_exuSources_value,
  output         io_commonOut_transEntry_bits_status_srcStatus_1_useRegCache,
  output [4:0]   io_commonOut_transEntry_bits_status_srcStatus_1_regCacheIdx,
  output         io_commonOut_transEntry_bits_status_issued,
  output         io_commonOut_transEntry_bits_status_firstIssue,
  output [1:0]   io_commonOut_transEntry_bits_status_issueTimer,
  output         io_commonOut_transEntry_bits_status_deqPortIdx,
  output [31:0]  io_commonOut_transEntry_bits_imm,
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
  output         io_commonOut_perfLdCancel_1,
  output         io_commonOut_perfOg0Cancel_0,
  output         io_commonOut_perfOg0Cancel_1,
  output         io_commonOut_perfWakeupByWB_0,
  output         io_commonOut_perfWakeupByWB_1,
  output         io_commonOut_perfWakeupByIQ_0_0,
  output         io_commonOut_perfWakeupByIQ_0_1,
  output         io_commonOut_perfWakeupByIQ_0_2,
  output         io_commonOut_perfWakeupByIQ_0_3,
  output         io_commonOut_perfWakeupByIQ_0_4,
  output         io_commonOut_perfWakeupByIQ_0_5,
  output         io_commonOut_perfWakeupByIQ_0_6,
  output         io_commonOut_perfWakeupByIQ_1_0,
  output         io_commonOut_perfWakeupByIQ_1_1,
  output         io_commonOut_perfWakeupByIQ_1_2,
  output         io_commonOut_perfWakeupByIQ_1_3,
  output         io_commonOut_perfWakeupByIQ_1_4,
  output         io_commonOut_perfWakeupByIQ_1_5,
  output         io_commonOut_perfWakeupByIQ_1_6
);

  // BEGIN GENERATED(core-inst)
  // 入队负载按 Variant 的偏移表拼成一根 1362 位向量（transEntry 整包：
  // KEEP_WIDE = IS_ENQ | IS_TRANS，enq 条目要把整包交给下一级）
  logic [1361:0] enq_payload;
  // 一字段一行 + 比特区间 —— 这张表就是「负载字段 -> 比特位置」的地图，
  // fm_pins_pre.tcl 的钉点用的是同一张 Variant.pl_off，两边不会各算各的。
  assign enq_payload = {
    io_commonIn_enq_bits_payload_numLsElem,                       // [1361:1357] numLsElem
    io_commonIn_enq_bits_payload_debug_sim_trig,                  // [1356] debug_sim_trig
    io_commonIn_enq_bits_payload_debug_fuType,                    // [1355:1321] debug_fuType
    io_commonIn_enq_bits_payload_replayInst,                      // [1320] replayInst
    io_commonIn_enq_bits_payload_singleStep,                      // [1319] singleStep
    io_commonIn_enq_bits_payload_sqIdx_value,                     // [1318:1313] sqIdx_value
    io_commonIn_enq_bits_payload_sqIdx_flag,                      // [1312] sqIdx_flag
    io_commonIn_enq_bits_payload_lqIdx_value,                     // [1311:1305] lqIdx_value
    io_commonIn_enq_bits_payload_lqIdx_flag,                      // [1304] lqIdx_flag
    io_commonIn_enq_bits_payload_ssid,                            // [1303:1299] ssid
    io_commonIn_enq_bits_payload_loadWaitStrict,                  // [1298] loadWaitStrict
    io_commonIn_enq_bits_payload_loadWaitBit,                     // [1297] loadWaitBit
    io_commonIn_enq_bits_payload_waitForRobIdx_value,             // [1296:1289] waitForRobIdx_value
    io_commonIn_enq_bits_payload_waitForRobIdx_flag,              // [1288] waitForRobIdx_flag
    io_commonIn_enq_bits_payload_storeSetHit,                     // [1287] storeSetHit
    io_commonIn_enq_bits_payload_debugInfo_issueTime,             // [1286:1223] debugInfo_issueTime
    io_commonIn_enq_bits_payload_debugInfo_selectTime,            // [1222:1159] debugInfo_selectTime
    io_commonIn_enq_bits_payload_snapshot,                        // [1158] snapshot
    io_commonIn_enq_bits_payload_eliminatedMove,                  // [1157] eliminatedMove
    io_commonIn_enq_bits_payload_traceBlockInPipe_ilastsize,      // [1156] traceBlockInPipe_ilastsize
    io_commonIn_enq_bits_payload_traceBlockInPipe_iretire,        // [1155:1152] traceBlockInPipe_iretire
    io_commonIn_enq_bits_payload_traceBlockInPipe_itype,          // [1151:1148] traceBlockInPipe_itype
    io_commonIn_enq_bits_payload_dirtyVs,                         // [1147] dirtyVs
    io_commonIn_enq_bits_payload_dirtyFs,                         // [1146] dirtyFs
    io_commonIn_enq_bits_payload_instrSize,                       // [1145:1143] instrSize
    io_commonIn_enq_bits_payload_robIdx_value,                    // [1142:1135] robIdx_value
    io_commonIn_enq_bits_payload_robIdx_flag,                     // [1134] robIdx_flag
    io_commonIn_enq_bits_payload_regCacheIdx_1,                   // [1133:1129] regCacheIdx_1
    io_commonIn_enq_bits_payload_regCacheIdx_0,                   // [1128:1124] regCacheIdx_0
    io_commonIn_enq_bits_payload_useRegCache_1,                   // [1123] useRegCache_1
    io_commonIn_enq_bits_payload_useRegCache_0,                   // [1122] useRegCache_0
    io_commonIn_enq_bits_payload_psrc_4,                          // [1121:1114] psrc_4
    io_commonIn_enq_bits_payload_psrc_3,                          // [1113:1106] psrc_3
    io_commonIn_enq_bits_payload_psrc_2,                          // [1105:1098] psrc_2
    io_commonIn_enq_bits_payload_psrc_1,                          // [1097:1090] psrc_1
    io_commonIn_enq_bits_payload_psrc_0,                          // [1089:1082] psrc_0
    io_commonIn_enq_bits_payload_srcLoadDependency_4_2,           // [1081:1080] srcLoadDependency_4_2
    io_commonIn_enq_bits_payload_srcLoadDependency_4_1,           // [1079:1078] srcLoadDependency_4_1
    io_commonIn_enq_bits_payload_srcLoadDependency_4_0,           // [1077:1076] srcLoadDependency_4_0
    io_commonIn_enq_bits_payload_srcLoadDependency_3_2,           // [1075:1074] srcLoadDependency_3_2
    io_commonIn_enq_bits_payload_srcLoadDependency_3_1,           // [1073:1072] srcLoadDependency_3_1
    io_commonIn_enq_bits_payload_srcLoadDependency_3_0,           // [1071:1070] srcLoadDependency_3_0
    io_commonIn_enq_bits_payload_srcLoadDependency_2_2,           // [1069:1068] srcLoadDependency_2_2
    io_commonIn_enq_bits_payload_srcLoadDependency_2_1,           // [1067:1066] srcLoadDependency_2_1
    io_commonIn_enq_bits_payload_srcLoadDependency_2_0,           // [1065:1064] srcLoadDependency_2_0
    io_commonIn_enq_bits_payload_srcLoadDependency_1_2,           // [1063:1062] srcLoadDependency_1_2
    io_commonIn_enq_bits_payload_srcLoadDependency_1_1,           // [1061:1060] srcLoadDependency_1_1
    io_commonIn_enq_bits_payload_srcLoadDependency_1_0,           // [1059:1058] srcLoadDependency_1_0
    io_commonIn_enq_bits_payload_srcLoadDependency_0_2,           // [1057:1056] srcLoadDependency_0_2
    io_commonIn_enq_bits_payload_srcLoadDependency_0_1,           // [1055:1054] srcLoadDependency_0_1
    io_commonIn_enq_bits_payload_srcLoadDependency_0_0,           // [1053:1052] srcLoadDependency_0_0
    io_commonIn_enq_bits_payload_srcState_4,                      // [1051] srcState_4
    io_commonIn_enq_bits_payload_srcState_3,                      // [1050] srcState_3
    io_commonIn_enq_bits_payload_srcState_2,                      // [1049] srcState_2
    io_commonIn_enq_bits_payload_srcState_1,                      // [1048] srcState_1
    io_commonIn_enq_bits_payload_srcState_0,                      // [1047] srcState_0
    io_commonIn_enq_bits_payload_commitType,                      // [1046:1044] commitType
    io_commonIn_enq_bits_payload_numWB,                           // [1043:1037] numWB
    io_commonIn_enq_bits_payload_numUops,                         // [1036:1030] numUops
    io_commonIn_enq_bits_payload_lastUop,                         // [1029] lastUop
    io_commonIn_enq_bits_payload_firstUop,                        // [1028] firstUop
    io_commonIn_enq_bits_payload_isVset,                          // [1027] isVset
    io_commonIn_enq_bits_payload_uopIdx,                          // [1026:1020] uopIdx
    io_commonIn_enq_bits_payload_isDropAmocasSta,                 // [1019] isDropAmocasSta
    io_commonIn_enq_bits_payload_isMove,                          // [1018] isMove
    io_commonIn_enq_bits_payload_wfflags,                         // [1017] wfflags
    io_commonIn_enq_bits_payload_vlsInstr,                        // [1016] vlsInstr
    io_commonIn_enq_bits_payload_vpu_isVleff,                     // [1015] vpu_isVleff
    io_commonIn_enq_bits_payload_vpu_isWritePartVd,               // [1014] vpu_isWritePartVd
    io_commonIn_enq_bits_payload_vpu_isDependOldVd,               // [1013] vpu_isDependOldVd
    io_commonIn_enq_bits_payload_vpu_isMove,                      // [1012] vpu_isMove
    io_commonIn_enq_bits_payload_vpu_isOpMask,                    // [1011] vpu_isOpMask
    io_commonIn_enq_bits_payload_vpu_isDstMask,                   // [1010] vpu_isDstMask
    io_commonIn_enq_bits_payload_vpu_isNarrow,                    // [1009] vpu_isNarrow
    io_commonIn_enq_bits_payload_vpu_isExt,                       // [1008] vpu_isExt
    io_commonIn_enq_bits_payload_vpu_isReverse,                   // [1007] vpu_isReverse
    io_commonIn_enq_bits_payload_vpu_veew,                        // [1006:1005] vpu_veew
    io_commonIn_enq_bits_payload_vpu_nf,                          // [1004:1002] vpu_nf
    io_commonIn_enq_bits_payload_vpu_vl,                          // [1001:994] vpu_vl
    io_commonIn_enq_bits_payload_vpu_vmask,                       // [993:866] vpu_vmask
    io_commonIn_enq_bits_payload_vpu_lastUop,                     // [865] vpu_lastUop
    io_commonIn_enq_bits_payload_vpu_vuopIdx,                     // [864:858] vpu_vuopIdx
    io_commonIn_enq_bits_payload_vpu_vxrm,                        // [857:856] vpu_vxrm
    io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_8,             // [855] vpu_fpu_isFoldTo1_8
    io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_4,             // [854] vpu_fpu_isFoldTo1_4
    io_commonIn_enq_bits_payload_vpu_fpu_isFoldTo1_2,             // [853] vpu_fpu_isFoldTo1_2
    io_commonIn_enq_bits_payload_vpu_fpu_isReduction,             // [852] vpu_fpu_isReduction
    io_commonIn_enq_bits_payload_vpu_fpu_isFP64Instr,             // [851] vpu_fpu_isFP64Instr
    io_commonIn_enq_bits_payload_vpu_fpu_isFP32Instr,             // [850] vpu_fpu_isFP32Instr
    io_commonIn_enq_bits_payload_vpu_fpu_isFpToVecInst,           // [849] vpu_fpu_isFpToVecInst
    io_commonIn_enq_bits_payload_vpu_frm,                         // [848:846] vpu_frm
    io_commonIn_enq_bits_payload_vpu_vstart,                      // [845:838] vpu_vstart
    io_commonIn_enq_bits_payload_vpu_vm,                          // [837] vpu_vm
    io_commonIn_enq_bits_payload_vpu_specVlmul,                   // [836:834] vpu_specVlmul
    io_commonIn_enq_bits_payload_vpu_specVsew,                    // [833:832] vpu_specVsew
    io_commonIn_enq_bits_payload_vpu_specVta,                     // [831] vpu_specVta
    io_commonIn_enq_bits_payload_vpu_specVma,                     // [830] vpu_specVma
    io_commonIn_enq_bits_payload_vpu_specVill,                    // [829] vpu_specVill
    io_commonIn_enq_bits_payload_vpu_vlmul,                       // [828:826] vpu_vlmul
    io_commonIn_enq_bits_payload_vpu_vsew,                        // [825:824] vpu_vsew
    io_commonIn_enq_bits_payload_vpu_vta,                         // [823] vpu_vta
    io_commonIn_enq_bits_payload_vpu_vma,                         // [822] vpu_vma
    io_commonIn_enq_bits_payload_vpu_vill,                        // [821] vpu_vill
    io_commonIn_enq_bits_payload_imm,                             // [820:789] imm
    io_commonIn_enq_bits_payload_canRobCompress,                  // [788] canRobCompress
    io_commonIn_enq_bits_payload_flushPipe,                       // [787] flushPipe
    io_commonIn_enq_bits_payload_blockBackward,                   // [786] blockBackward
    io_commonIn_enq_bits_payload_waitForward,                     // [785] waitForward
    io_commonIn_enq_bits_payload_isXSTrap,                        // [784] isXSTrap
    io_commonIn_enq_bits_payload_fuType,                          // [783:749] fuType
    io_commonIn_enq_bits_payload_ldest,                           // [748:743] ldest
    io_commonIn_enq_bits_payload_srcType_4,                       // [742:739] srcType_4
    io_commonIn_enq_bits_payload_srcType_3,                       // [738:735] srcType_3
    io_commonIn_enq_bits_payload_srcType_2,                       // [734:731] srcType_2
    io_commonIn_enq_bits_payload_srcType_1,                       // [730:727] srcType_1
    io_commonIn_enq_bits_payload_srcType_0,                       // [726:723] srcType_0
    io_commonIn_enq_bits_payload_satpFlushFirstFetchFault,        // [722] satpFlushFirstFetchFault
    io_commonIn_enq_bits_payload_crossPageIPFFix,                 // [721] crossPageIPFFix
    io_commonIn_enq_bits_payload_trigger,                         // [720:717] trigger
    io_commonIn_enq_bits_payload_hasException,                    // [716] hasException
    io_commonIn_enq_bits_payload_isFetchMalAddr,                  // [715] isFetchMalAddr
    io_commonIn_enq_bits_payload_exceptionVec_23,                 // [714] exceptionVec_23
    io_commonIn_enq_bits_payload_exceptionVec_22,                 // [713] exceptionVec_22
    io_commonIn_enq_bits_payload_exceptionVec_21,                 // [712] exceptionVec_21
    io_commonIn_enq_bits_payload_exceptionVec_20,                 // [711] exceptionVec_20
    io_commonIn_enq_bits_payload_exceptionVec_19,                 // [710] exceptionVec_19
    io_commonIn_enq_bits_payload_exceptionVec_18,                 // [709] exceptionVec_18
    io_commonIn_enq_bits_payload_exceptionVec_17,                 // [708] exceptionVec_17
    io_commonIn_enq_bits_payload_exceptionVec_16,                 // [707] exceptionVec_16
    io_commonIn_enq_bits_payload_exceptionVec_15,                 // [706] exceptionVec_15
    io_commonIn_enq_bits_payload_exceptionVec_14,                 // [705] exceptionVec_14
    io_commonIn_enq_bits_payload_exceptionVec_13,                 // [704] exceptionVec_13
    io_commonIn_enq_bits_payload_exceptionVec_12,                 // [703] exceptionVec_12
    io_commonIn_enq_bits_payload_exceptionVec_11,                 // [702] exceptionVec_11
    io_commonIn_enq_bits_payload_exceptionVec_10,                 // [701] exceptionVec_10
    io_commonIn_enq_bits_payload_exceptionVec_9,                  // [700] exceptionVec_9
    io_commonIn_enq_bits_payload_exceptionVec_8,                  // [699] exceptionVec_8
    io_commonIn_enq_bits_payload_exceptionVec_7,                  // [698] exceptionVec_7
    io_commonIn_enq_bits_payload_exceptionVec_6,                  // [697] exceptionVec_6
    io_commonIn_enq_bits_payload_exceptionVec_5,                  // [696] exceptionVec_5
    io_commonIn_enq_bits_payload_exceptionVec_4,                  // [695] exceptionVec_4
    io_commonIn_enq_bits_payload_exceptionVec_3,                  // [694] exceptionVec_3
    io_commonIn_enq_bits_payload_exceptionVec_2,                  // [693] exceptionVec_2
    io_commonIn_enq_bits_payload_exceptionVec_1,                  // [692] exceptionVec_1
    io_commonIn_enq_bits_payload_exceptionVec_0,                  // [691] exceptionVec_0
    io_commonIn_enq_bits_payload_foldpc,                          // [690:681] foldpc
    io_commonIn_enq_bits_payload_pc,                              // [680:631] pc
    io_commonIn_enq_bits_payload_instr,                           // [630:599] instr
    io_commonIn_enq_bits_payload_debug_seqNum_uopIdx,             // [598:591] debug_seqNum_uopIdx
    io_commonIn_enq_bits_payload_debug_seqNum_seqNum,             // [590:535] debug_seqNum_seqNum
    io_commonIn_enq_bits_payload_debugInfo_tlbRespTime,           // [534:471] debugInfo_tlbRespTime
    io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime,       // [470:407] debugInfo_tlbFirstReqTime
    io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id,// [406:343] debugInfo_runahead_checkpoint_id
    io_commonIn_enq_bits_payload_debugInfo_writebackTime,         // [342:279] debugInfo_writebackTime
    io_commonIn_enq_bits_payload_debugInfo_enqRsTime,             // [278:215] debugInfo_enqRsTime
    io_commonIn_enq_bits_payload_debugInfo_dispatchTime,          // [214:151] debugInfo_dispatchTime
    io_commonIn_enq_bits_payload_debugInfo_renameTime,            // [150:87] debugInfo_renameTime
    io_commonIn_enq_bits_payload_debugInfo_eliminatedMove,        // [86] debugInfo_eliminatedMove
    io_commonIn_enq_bits_payload_pdest,                           // [85:78] pdest
    io_commonIn_enq_bits_payload_fpu_rm,                          // [77:75] fpu_rm
    io_commonIn_enq_bits_payload_fpu_fmt,                         // [74:73] fpu_fmt
    io_commonIn_enq_bits_payload_fpu_typ,                         // [72:71] fpu_typ
    io_commonIn_enq_bits_payload_fpu_wflags,                      // [70] fpu_wflags
    io_commonIn_enq_bits_payload_fpu_typeTagOut,                  // [69:68] fpu_typeTagOut
    io_commonIn_enq_bits_payload_selImm,                          // [67:64] selImm
    io_commonIn_enq_bits_payload_vlWen,                           // [63] vlWen
    io_commonIn_enq_bits_payload_v0Wen,                           // [62] v0Wen
    io_commonIn_enq_bits_payload_vecWen,                          // [61] vecWen
    io_commonIn_enq_bits_payload_fpWen,                           // [60] fpWen
    io_commonIn_enq_bits_payload_rfWen,                           // [59] rfWen
    io_commonIn_enq_bits_payload_fuOpType,                        // [58:50] fuOpType
    io_commonIn_enq_bits_payload_ftqOffset,                       // [49:46] ftqOffset
    io_commonIn_enq_bits_payload_ftqPtr_value,                    // [45:40] ftqPtr_value
    io_commonIn_enq_bits_payload_ftqPtr_flag,                     // [39] ftqPtr_flag
    io_commonIn_enq_bits_payload_pred_taken,                      // [38] pred_taken
    io_commonIn_enq_bits_payload_preDecodeInfo_isRet,             // [37] preDecodeInfo_isRet
    io_commonIn_enq_bits_payload_preDecodeInfo_isCall,            // [36] preDecodeInfo_isCall
    io_commonIn_enq_bits_payload_preDecodeInfo_brType,            // [35:34] preDecodeInfo_brType
    io_commonIn_enq_bits_payload_preDecodeInfo_isRVC,             // [33] preDecodeInfo_isRVC
    io_commonIn_enq_bits_payload_preDecodeInfo_valid,             // [32] preDecodeInfo_valid
    io_commonIn_enq_bits_imm                                      // [31:0] #imm
  };

  logic [6:0] fu_type_narrow;
  logic [1:0][3:0] data_src;
  logic [1:0][2:0] exu_src;
  logic [598:0] ety_payload;
  logic [1:0][7:0] ety_psrc;
  logic [1:0][3:0] ety_src_type;
  logic [1:0][2:0][1:0] ety_ld_dep;
  logic [1:0][4:0] ety_rc_idx;
  logic [1361:0] trans_payload;
  logic [1:0][7:0] trans_psrc;
  logic [1:0][3:0] trans_src_type, trans_data_src;
  logic [1:0] trans_src_state, trans_use_rc;
  logic [1:0][2:0][1:0] trans_ld_dep;
  logic [1:0][2:0] trans_exu_src;
  logic [1:0][4:0] trans_rc_idx;
  logic [6:0] trans_fu_type;
  // golden 的 EnqEntry 不露 enqReady（核内部自用）
  logic unused_enq_ready;
  // enq 条目没有 blocked 寄存器（核 §2.6a：IS_ENQ 时次态恒 0）
  logic unused_trans_blocked;

  xs_iq_entry #(
    // ★ IS_ENQ=1：装载带 enqReady、强制 issued/firstIssue/issueTimer、
    //   无 blocked 寄存器、多一拍入队延迟唤醒窗口（核 §2.4/§2.6/§2.6a/§2.6b）
    .IS_ENQ(1), .IS_TRANS(0), .IS_COMP(1),
    .NUM_DEQ_PORTS(2),
    .NUM_REGSRC(2), .NUM_WK_WB(4), .NUM_FU_BIT(7),
    .ROB_W(8), .PSRC_W(8), .PDEST_W(8),
    .PL_DEQ_W(599), .PL_TRANS_W(1362),
    .HAS_LD_DEP(1), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(7), .EXU_W(3),
    .IQ_SRC_MASK({7'b1111111, 7'b1111111}),
    .IQ_WEN_PRESENT(5'b00001),
    .IQD_WEN_PRESENT(5'b00001),
    .IQ_IS_LD_PIPE({3'b100, 3'b010, 3'b001, 3'b000, 3'b000, 3'b000, 3'b000}),
    .HAS_REG_CACHE(1), .RC_IDX_W(5),
    .IQ_WRITE_RC(7'b1111111), .RC_TYPE_BIT(0),
    .SRC_WB_MASK({4'b1111, 4'b1111}),
    .SRC_MATCH_KIND({2'd0, 2'd0}),
    .WB_WEN_PRESENT(5'b00001),
    .WBD_WEN_PRESENT(5'b00001),
    .HAS_IGNORE_OLD_VD(0),
    .VD_SRC(0), .VL_SRC(0), .WB_VL_INT(0), .WB_VL_VF(0),
    .PLB_VM(837),
    .PLB_VMA(822),
    .PLB_VTA(823),
    .PLB_IS_DEPEND_OLDVD(1013),
    .PLB_IS_WRITE_PARTVD(1014),
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
    .enq_fu_type({io_commonIn_enq_bits_status_fuType_29, io_commonIn_enq_bits_status_fuType_28,
        io_commonIn_enq_bits_status_fuType_6, io_commonIn_enq_bits_status_fuType_3,
        io_commonIn_enq_bits_status_fuType_2, io_commonIn_enq_bits_status_fuType_1,
        io_commonIn_enq_bits_status_fuType_0}),
    .enq_psrc({io_commonIn_enq_bits_status_srcStatus_1_psrc,
        io_commonIn_enq_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_commonIn_enq_bits_status_srcStatus_1_srcType,
        io_commonIn_enq_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_commonIn_enq_bits_status_srcStatus_1_srcState,
        io_commonIn_enq_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_commonIn_enq_bits_status_srcStatus_1_dataSources_value,
        io_commonIn_enq_bits_status_srcStatus_0_dataSources_value}),
    // ★ IS_ENQ 装载时这五个由核强制（issued=0/firstIssue=0/issueTimer=3，
    //   blocked 无寄存器、deqPortIdx 清 0），golden 也正因此没有这几个输入
    .enq_blocked('0), .enq_issued('0), .enq_first_issue('0),
    .enq_issue_timer('0), .enq_deq_port_idx('0),
    .enq_payload(enq_payload),
    .enq_ld_dep({io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2,
        io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1,
        io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0,
        io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2,
        io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1,
        io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0}),
    // exuSources 入队值：enq 条目是 uop 的第一站，还没被任何 IQ 唤醒过
    //   （golden 也没有 enq.status.srcStatus.exuSources 输入端口）
    .enq_exu_src('0),
    .enq_use_rc({io_commonIn_enq_bits_status_srcStatus_1_useRegCache,
        io_commonIn_enq_bits_status_srcStatus_0_useRegCache}),
    .enq_rc_idx({io_commonIn_enq_bits_status_srcStatus_1_regCacheIdx,
        io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx}),
    .wk_valid({io_commonIn_wakeUpFromWB_3_valid, io_commonIn_wakeUpFromWB_2_valid,
        io_commonIn_wakeUpFromWB_1_valid, io_commonIn_wakeUpFromWB_0_valid}),
    .wk_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_3_bits_rfWen}, {1'b0, 1'b0, 1'b0,
        1'b0, io_commonIn_wakeUpFromWB_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromWB_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromWB_0_bits_rfWen}}),
    .wk_pdest({io_commonIn_wakeUpFromWB_3_bits_pdest, io_commonIn_wakeUpFromWB_2_bits_pdest,
        io_commonIn_wakeUpFromWB_1_bits_pdest, io_commonIn_wakeUpFromWB_0_bits_pdest}),
    // ★ 入队延迟窗口（IS_ENQ 专属）：派遣与唤醒总线差一拍，入队后的下一拍
    //   用这组延迟总线再匹配一次，否则那一拍的唤醒会被整个漏掉。
    .wkd_valid({io_enqDelayIn1_wakeUpFromWB_3_valid, io_enqDelayIn1_wakeUpFromWB_2_valid,
        io_enqDelayIn1_wakeUpFromWB_1_valid, io_enqDelayIn1_wakeUpFromWB_0_valid}),
    .wkd_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_enqDelayIn1_wakeUpFromWB_3_bits_rfWen}, {1'b0, 1'b0,
        1'b0, 1'b0, io_enqDelayIn1_wakeUpFromWB_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromWB_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromWB_0_bits_rfWen}}),
    .wkd_pdest({io_enqDelayIn1_wakeUpFromWB_3_bits_pdest,
        io_enqDelayIn1_wakeUpFromWB_2_bits_pdest, io_enqDelayIn1_wakeUpFromWB_1_bits_pdest,
        io_enqDelayIn1_wakeUpFromWB_0_bits_pdest}),
    // iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]；
    // og0Cancel 的下标是稀疏的，is0Lat 有的路被 firtool 折成常量。
    .iq_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_6_bits_rfWen}, {1'b0, 1'b0, 1'b0,
        1'b0, io_commonIn_wakeUpFromIQ_5_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromIQ_4_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromIQ_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromIQ_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromIQ_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_commonIn_wakeUpFromIQ_0_bits_rfWen}}),
    .iq_pdest({io_commonIn_wakeUpFromIQ_6_bits_pdest, io_commonIn_wakeUpFromIQ_5_bits_pdest,
        io_commonIn_wakeUpFromIQ_4_bits_pdest, io_commonIn_wakeUpFromIQ_3_bits_pdest,
        io_commonIn_wakeUpFromIQ_2_bits_pdest, io_commonIn_wakeUpFromIQ_1_bits_pdest,
        io_commonIn_wakeUpFromIQ_0_bits_pdest}),
    .iq_ld_dep({io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0,
        io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0,
        io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0,
        io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0,
        io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0,
        io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0,
        io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2,
        io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1,
        io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0}),
    .iq_rc_dest({io_commonIn_wakeUpFromIQ_6_bits_rcDest, io_commonIn_wakeUpFromIQ_5_bits_rcDest,
        io_commonIn_wakeUpFromIQ_4_bits_rcDest, io_commonIn_wakeUpFromIQ_3_bits_rcDest,
        io_commonIn_wakeUpFromIQ_2_bits_rcDest, io_commonIn_wakeUpFromIQ_1_bits_rcDest,
        io_commonIn_wakeUpFromIQ_0_bits_rcDest}),
    .iq_cancel({1'b0, 1'b0, 1'b0, io_commonIn_og0Cancel_6, io_commonIn_og0Cancel_4,
        (io_commonIn_og0Cancel_2 & io_commonIn_wakeUpFromIQ_1_bits_is0Lat),
        (io_commonIn_og0Cancel_0 & io_commonIn_wakeUpFromIQ_0_bits_is0Lat)}),
    // 延迟窗口的 IQ 总线：路数/下标映射与当拍侧同（构造时已断言）
    .iqd_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_enqDelayIn1_wakeUpFromIQ_6_bits_rfWen}, {1'b0, 1'b0,
        1'b0, 1'b0, io_enqDelayIn1_wakeUpFromIQ_5_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromIQ_4_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromIQ_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromIQ_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromIQ_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0,
        io_enqDelayIn1_wakeUpFromIQ_0_bits_rfWen}}),
    .iqd_pdest({io_enqDelayIn1_wakeUpFromIQ_6_bits_pdest,
        io_enqDelayIn1_wakeUpFromIQ_5_bits_pdest, io_enqDelayIn1_wakeUpFromIQ_4_bits_pdest,
        io_enqDelayIn1_wakeUpFromIQ_3_bits_pdest, io_enqDelayIn1_wakeUpFromIQ_2_bits_pdest,
        io_enqDelayIn1_wakeUpFromIQ_1_bits_pdest, io_enqDelayIn1_wakeUpFromIQ_0_bits_pdest}),
    .iqd_ld_dep({io_enqDelayIn1_wakeUpFromIQ_6_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_6_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_6_bits_loadDependency_0,
        io_enqDelayIn1_wakeUpFromIQ_5_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_5_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_5_bits_loadDependency_0,
        io_enqDelayIn1_wakeUpFromIQ_4_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_4_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_4_bits_loadDependency_0,
        io_enqDelayIn1_wakeUpFromIQ_3_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_3_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_3_bits_loadDependency_0,
        io_enqDelayIn1_wakeUpFromIQ_2_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_2_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_2_bits_loadDependency_0,
        io_enqDelayIn1_wakeUpFromIQ_1_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_1_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_1_bits_loadDependency_0,
        io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_2,
        io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_1,
        io_enqDelayIn1_wakeUpFromIQ_0_bits_loadDependency_0}),
    .iqd_rc_dest({io_enqDelayIn1_wakeUpFromIQ_6_bits_rcDest,
        io_enqDelayIn1_wakeUpFromIQ_5_bits_rcDest, io_enqDelayIn1_wakeUpFromIQ_4_bits_rcDest,
        io_enqDelayIn1_wakeUpFromIQ_3_bits_rcDest, io_enqDelayIn1_wakeUpFromIQ_2_bits_rcDest,
        io_enqDelayIn1_wakeUpFromIQ_1_bits_rcDest, io_enqDelayIn1_wakeUpFromIQ_0_bits_rcDest}),
    .iqd_cancel({1'b0, 1'b0, 1'b0, io_enqDelayIn1_og0Cancel_6, io_enqDelayIn1_og0Cancel_4,
        (io_enqDelayIn1_og0Cancel_2 & io_enqDelayIn1_wakeUpFromIQ_1_bits_is0Lat),
        (io_enqDelayIn1_og0Cancel_0 & io_enqDelayIn1_wakeUpFromIQ_0_bits_is0Lat)}),
    .ld1_cancel('0),
    .ld2_cancel({io_commonIn_ldCancel_2_ld2Cancel, io_commonIn_ldCancel_1_ld2Cancel,
        io_commonIn_ldCancel_0_ld2Cancel}),
    .ld1d_cancel('0),
    .ld2d_cancel({io_enqDelayIn1_ldCancel_2_ld2Cancel, io_enqDelayIn1_ldCancel_1_ld2Cancel,
        io_enqDelayIn1_ldCancel_0_ld2Cancel}),
    // ★ 延迟窗口判「本源影子该不该撤」用的是 Entries 在入队瞬间存下的那份
    //   （golden Entries.scala:140 的 RegEnable），条目这一层是输入端口。
    .enqd_self_ld_dep({io_enqDelayIn1_srcLoadDependency_1_2,
        io_enqDelayIn1_srcLoadDependency_1_1, io_enqDelayIn1_srcLoadDependency_1_0,
        io_enqDelayIn1_srcLoadDependency_0_2, io_enqDelayIn1_srcLoadDependency_0_1,
        io_enqDelayIn1_srcLoadDependency_0_0}),
    .vl_int_is_zero(1'b0),
    .vl_int_is_vlmax(1'b0),
    .vl_vf_is_zero(1'b0),
    .vl_vf_is_vlmax(1'b0),
    .deq_sel(io_commonIn_deqSel),
    .deq_port_idx_write(io_commonIn_deqPortIdxWrite),
    .resp_valid(io_commonIn_issueResp_valid),
    .resp_bits(io_commonIn_issueResp_bits_resp),
    // enq 条目的 transSel = 「本拍被搬到 simp/comp 去了」-> enqReady/clear
    .trans_sel(io_commonIn_transSel),
    .o_valid(io_commonOut_valid), .o_issued(io_commonOut_issued),
    .o_can_issue(io_commonOut_canIssue),
    .o_cancel_bypass(io_commonOut_cancelBypass),
    .o_is_first_issue(io_commonOut_isFirstIssue),
    .o_fu_type(fu_type_narrow), .o_data_src(data_src),
    .o_issue_timer(io_commonOut_issueTimerRead),
    .o_deq_port_idx(io_commonOut_deqPortIdxRead),
    .o_enq_ready(unused_enq_ready),
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
    .o_dbg_perf_ld_cancel({io_commonOut_perfLdCancel_1, io_commonOut_perfLdCancel_0}),
    .o_dbg_perf_og0_cancel({io_commonOut_perfOg0Cancel_1, io_commonOut_perfOg0Cancel_0}),
    .o_dbg_perf_wakeup_by_wb({io_commonOut_perfWakeupByWB_1, io_commonOut_perfWakeupByWB_0}),
    .o_dbg_perf_wakeup_by_iq({io_commonOut_perfWakeupByIQ_1_6, io_commonOut_perfWakeupByIQ_1_5,
        io_commonOut_perfWakeupByIQ_1_4, io_commonOut_perfWakeupByIQ_1_3,
        io_commonOut_perfWakeupByIQ_1_2, io_commonOut_perfWakeupByIQ_1_1,
        io_commonOut_perfWakeupByIQ_1_0, io_commonOut_perfWakeupByIQ_0_6,
        io_commonOut_perfWakeupByIQ_0_5, io_commonOut_perfWakeupByIQ_0_4,
        io_commonOut_perfWakeupByIQ_0_3, io_commonOut_perfWakeupByIQ_0_2,
        io_commonOut_perfWakeupByIQ_0_1, io_commonOut_perfWakeupByIQ_0_0})
  );

  // fuType 出口：核只存本变体保留的 7 位，这里放回 35 位 one-hot 的原位置
  assign io_commonOut_fuType = {5'h0, fu_type_narrow[6], fu_type_narrow[5], 21'h0,
      fu_type_narrow[4], 2'h0, fu_type_narrow[3], fu_type_narrow[2], fu_type_narrow[1],
      fu_type_narrow[0]};

  assign io_commonOut_dataSources_0_value = data_src[0];
  assign io_commonOut_exuSources_0_value = exu_src[0];
  assign io_commonOut_dataSources_1_value = data_src[1];
  assign io_commonOut_exuSources_1_value = exu_src[1];

  // commonOut.entry.bits.status —— fuType 与 commonOut.fuType 同一组寄存器
  assign io_commonOut_entry_bits_status_fuType_0 = fu_type_narrow[0];
  assign io_commonOut_entry_bits_status_fuType_1 = fu_type_narrow[1];
  assign io_commonOut_entry_bits_status_fuType_2 = fu_type_narrow[2];
  assign io_commonOut_entry_bits_status_fuType_3 = fu_type_narrow[3];
  assign io_commonOut_entry_bits_status_fuType_6 = fu_type_narrow[4];
  assign io_commonOut_entry_bits_status_fuType_28 = fu_type_narrow[5];
  assign io_commonOut_entry_bits_status_fuType_29 = fu_type_narrow[6];
  assign io_commonOut_entry_bits_status_srcStatus_0_psrc = ety_psrc[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcType = ety_src_type[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx = ety_rc_idx[0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0 = ety_ld_dep[0][0];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1 = ety_ld_dep[0][1];
  assign io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2 = ety_ld_dep[0][2];
  assign io_commonOut_entry_bits_status_srcStatus_1_psrc = ety_psrc[1];
  assign io_commonOut_entry_bits_status_srcStatus_1_srcType = ety_src_type[1];
  assign io_commonOut_entry_bits_status_srcStatus_1_regCacheIdx = ety_rc_idx[1];
  assign io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_0 = ety_ld_dep[1][0];
  assign io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_1 = ety_ld_dep[1][1];
  assign io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_2 = ety_ld_dep[1][2];
  assign io_commonOut_entry_bits_imm = ety_payload[31:0];
  assign io_commonOut_entry_bits_payload_preDecodeInfo_valid = ety_payload[32];
  assign io_commonOut_entry_bits_payload_preDecodeInfo_isRVC = ety_payload[33];
  assign io_commonOut_entry_bits_payload_preDecodeInfo_brType = ety_payload[35:34];
  assign io_commonOut_entry_bits_payload_preDecodeInfo_isCall = ety_payload[36];
  assign io_commonOut_entry_bits_payload_preDecodeInfo_isRet = ety_payload[37];
  assign io_commonOut_entry_bits_payload_pred_taken = ety_payload[38];
  assign io_commonOut_entry_bits_payload_ftqPtr_flag = ety_payload[39];
  assign io_commonOut_entry_bits_payload_ftqPtr_value = ety_payload[45:40];
  assign io_commonOut_entry_bits_payload_ftqOffset = ety_payload[49:46];
  assign io_commonOut_entry_bits_payload_fuOpType = ety_payload[58:50];
  assign io_commonOut_entry_bits_payload_rfWen = ety_payload[59];
  assign io_commonOut_entry_bits_payload_fpWen = ety_payload[60];
  assign io_commonOut_entry_bits_payload_vecWen = ety_payload[61];
  assign io_commonOut_entry_bits_payload_v0Wen = ety_payload[62];
  assign io_commonOut_entry_bits_payload_vlWen = ety_payload[63];
  assign io_commonOut_entry_bits_payload_selImm = ety_payload[67:64];
  assign io_commonOut_entry_bits_payload_fpu_typeTagOut = ety_payload[69:68];
  assign io_commonOut_entry_bits_payload_fpu_wflags = ety_payload[70];
  assign io_commonOut_entry_bits_payload_fpu_typ = ety_payload[72:71];
  assign io_commonOut_entry_bits_payload_fpu_fmt = ety_payload[74:73];
  assign io_commonOut_entry_bits_payload_fpu_rm = ety_payload[77:75];
  assign io_commonOut_entry_bits_payload_pdest = ety_payload[85:78];
  assign io_commonOut_entry_bits_payload_debugInfo_eliminatedMove = ety_payload[86];
  assign io_commonOut_entry_bits_payload_debugInfo_renameTime = ety_payload[150:87];
  assign io_commonOut_entry_bits_payload_debugInfo_dispatchTime = ety_payload[214:151];
  assign io_commonOut_entry_bits_payload_debugInfo_enqRsTime = ety_payload[278:215];
  assign io_commonOut_entry_bits_payload_debugInfo_writebackTime = ety_payload[342:279];
  assign io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id = ety_payload[406:343];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime = ety_payload[470:407];
  assign io_commonOut_entry_bits_payload_debugInfo_tlbRespTime = ety_payload[534:471];
  assign io_commonOut_entry_bits_payload_debug_seqNum_seqNum = ety_payload[590:535];
  assign io_commonOut_entry_bits_payload_debug_seqNum_uopIdx = ety_payload[598:591];

  // commonOut.transEntry —— 交给下一级（simp/comp）的整包（= entryUpdate）
  assign io_commonOut_transEntry_bits_status_fuType_0 = trans_fu_type[0];
  assign io_commonOut_transEntry_bits_status_fuType_1 = trans_fu_type[1];
  assign io_commonOut_transEntry_bits_status_fuType_2 = trans_fu_type[2];
  assign io_commonOut_transEntry_bits_status_fuType_3 = trans_fu_type[3];
  assign io_commonOut_transEntry_bits_status_fuType_6 = trans_fu_type[4];
  assign io_commonOut_transEntry_bits_status_fuType_28 = trans_fu_type[5];
  assign io_commonOut_transEntry_bits_status_fuType_29 = trans_fu_type[6];
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
  assign io_commonOut_transEntry_bits_status_srcStatus_1_psrc = trans_psrc[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcType = trans_src_type[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcState = trans_src_state[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_dataSources_value = trans_data_src[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_exuSources_value = trans_exu_src[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_useRegCache = trans_use_rc[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_regCacheIdx = trans_rc_idx[1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_0 = trans_ld_dep[1][0];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_1 = trans_ld_dep[1][1];
  assign io_commonOut_transEntry_bits_status_srcStatus_1_srcLoadDependency_2 = trans_ld_dep[1][2];
  assign io_commonOut_transEntry_bits_imm = trans_payload[31:0];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_valid = trans_payload[32];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRVC = trans_payload[33];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_brType = trans_payload[35:34];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isCall = trans_payload[36];
  assign io_commonOut_transEntry_bits_payload_preDecodeInfo_isRet = trans_payload[37];
  assign io_commonOut_transEntry_bits_payload_pred_taken = trans_payload[38];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_flag = trans_payload[39];
  assign io_commonOut_transEntry_bits_payload_ftqPtr_value = trans_payload[45:40];
  assign io_commonOut_transEntry_bits_payload_ftqOffset = trans_payload[49:46];
  assign io_commonOut_transEntry_bits_payload_fuOpType = trans_payload[58:50];
  assign io_commonOut_transEntry_bits_payload_rfWen = trans_payload[59];
  assign io_commonOut_transEntry_bits_payload_fpWen = trans_payload[60];
  assign io_commonOut_transEntry_bits_payload_vecWen = trans_payload[61];
  assign io_commonOut_transEntry_bits_payload_v0Wen = trans_payload[62];
  assign io_commonOut_transEntry_bits_payload_vlWen = trans_payload[63];
  assign io_commonOut_transEntry_bits_payload_selImm = trans_payload[67:64];
  assign io_commonOut_transEntry_bits_payload_fpu_typeTagOut = trans_payload[69:68];
  assign io_commonOut_transEntry_bits_payload_fpu_wflags = trans_payload[70];
  assign io_commonOut_transEntry_bits_payload_fpu_typ = trans_payload[72:71];
  assign io_commonOut_transEntry_bits_payload_fpu_fmt = trans_payload[74:73];
  assign io_commonOut_transEntry_bits_payload_fpu_rm = trans_payload[77:75];
  assign io_commonOut_transEntry_bits_payload_pdest = trans_payload[85:78];
  assign io_commonOut_transEntry_bits_payload_debugInfo_eliminatedMove = trans_payload[86];
  assign io_commonOut_transEntry_bits_payload_debugInfo_renameTime = trans_payload[150:87];
  assign io_commonOut_transEntry_bits_payload_debugInfo_dispatchTime = trans_payload[214:151];
  assign io_commonOut_transEntry_bits_payload_debugInfo_enqRsTime = trans_payload[278:215];
  assign io_commonOut_transEntry_bits_payload_debugInfo_writebackTime = trans_payload[342:279];
  assign io_commonOut_transEntry_bits_payload_debugInfo_runahead_checkpoint_id = trans_payload[406:343];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbFirstReqTime = trans_payload[470:407];
  assign io_commonOut_transEntry_bits_payload_debugInfo_tlbRespTime = trans_payload[534:471];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_seqNum = trans_payload[590:535];
  assign io_commonOut_transEntry_bits_payload_debug_seqNum_uopIdx = trans_payload[598:591];
  assign io_commonOut_transEntry_bits_payload_instr = trans_payload[630:599];
  assign io_commonOut_transEntry_bits_payload_pc = trans_payload[680:631];
  assign io_commonOut_transEntry_bits_payload_foldpc = trans_payload[690:681];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_0 = trans_payload[691];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_1 = trans_payload[692];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_2 = trans_payload[693];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_3 = trans_payload[694];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_4 = trans_payload[695];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_5 = trans_payload[696];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_6 = trans_payload[697];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_7 = trans_payload[698];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_8 = trans_payload[699];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_9 = trans_payload[700];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_10 = trans_payload[701];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_11 = trans_payload[702];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_12 = trans_payload[703];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_13 = trans_payload[704];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_14 = trans_payload[705];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_15 = trans_payload[706];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_16 = trans_payload[707];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_17 = trans_payload[708];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_18 = trans_payload[709];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_19 = trans_payload[710];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_20 = trans_payload[711];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_21 = trans_payload[712];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_22 = trans_payload[713];
  assign io_commonOut_transEntry_bits_payload_exceptionVec_23 = trans_payload[714];
  assign io_commonOut_transEntry_bits_payload_isFetchMalAddr = trans_payload[715];
  assign io_commonOut_transEntry_bits_payload_hasException = trans_payload[716];
  assign io_commonOut_transEntry_bits_payload_trigger = trans_payload[720:717];
  assign io_commonOut_transEntry_bits_payload_crossPageIPFFix = trans_payload[721];
  assign io_commonOut_transEntry_bits_payload_satpFlushFirstFetchFault = trans_payload[722];
  assign io_commonOut_transEntry_bits_payload_srcType_0 = trans_payload[726:723];
  assign io_commonOut_transEntry_bits_payload_srcType_1 = trans_payload[730:727];
  assign io_commonOut_transEntry_bits_payload_srcType_2 = trans_payload[734:731];
  assign io_commonOut_transEntry_bits_payload_srcType_3 = trans_payload[738:735];
  assign io_commonOut_transEntry_bits_payload_srcType_4 = trans_payload[742:739];
  assign io_commonOut_transEntry_bits_payload_ldest = trans_payload[748:743];
  assign io_commonOut_transEntry_bits_payload_fuType = trans_payload[783:749];
  assign io_commonOut_transEntry_bits_payload_isXSTrap = trans_payload[784];
  assign io_commonOut_transEntry_bits_payload_waitForward = trans_payload[785];
  assign io_commonOut_transEntry_bits_payload_blockBackward = trans_payload[786];
  assign io_commonOut_transEntry_bits_payload_flushPipe = trans_payload[787];
  assign io_commonOut_transEntry_bits_payload_canRobCompress = trans_payload[788];
  assign io_commonOut_transEntry_bits_payload_imm = trans_payload[820:789];
  assign io_commonOut_transEntry_bits_payload_vpu_vill = trans_payload[821];
  assign io_commonOut_transEntry_bits_payload_vpu_vma = trans_payload[822];
  assign io_commonOut_transEntry_bits_payload_vpu_vta = trans_payload[823];
  assign io_commonOut_transEntry_bits_payload_vpu_vsew = trans_payload[825:824];
  assign io_commonOut_transEntry_bits_payload_vpu_vlmul = trans_payload[828:826];
  assign io_commonOut_transEntry_bits_payload_vpu_specVill = trans_payload[829];
  assign io_commonOut_transEntry_bits_payload_vpu_specVma = trans_payload[830];
  assign io_commonOut_transEntry_bits_payload_vpu_specVta = trans_payload[831];
  assign io_commonOut_transEntry_bits_payload_vpu_specVsew = trans_payload[833:832];
  assign io_commonOut_transEntry_bits_payload_vpu_specVlmul = trans_payload[836:834];
  assign io_commonOut_transEntry_bits_payload_vpu_vm = trans_payload[837];
  assign io_commonOut_transEntry_bits_payload_vpu_vstart = trans_payload[845:838];
  assign io_commonOut_transEntry_bits_payload_vpu_frm = trans_payload[848:846];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFpToVecInst = trans_payload[849];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP32Instr = trans_payload[850];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFP64Instr = trans_payload[851];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isReduction = trans_payload[852];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_2 = trans_payload[853];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_4 = trans_payload[854];
  assign io_commonOut_transEntry_bits_payload_vpu_fpu_isFoldTo1_8 = trans_payload[855];
  assign io_commonOut_transEntry_bits_payload_vpu_vxrm = trans_payload[857:856];
  assign io_commonOut_transEntry_bits_payload_vpu_vuopIdx = trans_payload[864:858];
  assign io_commonOut_transEntry_bits_payload_vpu_lastUop = trans_payload[865];
  assign io_commonOut_transEntry_bits_payload_vpu_vmask = trans_payload[993:866];
  assign io_commonOut_transEntry_bits_payload_vpu_vl = trans_payload[1001:994];
  assign io_commonOut_transEntry_bits_payload_vpu_nf = trans_payload[1004:1002];
  assign io_commonOut_transEntry_bits_payload_vpu_veew = trans_payload[1006:1005];
  assign io_commonOut_transEntry_bits_payload_vpu_isReverse = trans_payload[1007];
  assign io_commonOut_transEntry_bits_payload_vpu_isExt = trans_payload[1008];
  assign io_commonOut_transEntry_bits_payload_vpu_isNarrow = trans_payload[1009];
  assign io_commonOut_transEntry_bits_payload_vpu_isDstMask = trans_payload[1010];
  assign io_commonOut_transEntry_bits_payload_vpu_isOpMask = trans_payload[1011];
  assign io_commonOut_transEntry_bits_payload_vpu_isMove = trans_payload[1012];
  assign io_commonOut_transEntry_bits_payload_vpu_isDependOldVd = trans_payload[1013];
  assign io_commonOut_transEntry_bits_payload_vpu_isWritePartVd = trans_payload[1014];
  assign io_commonOut_transEntry_bits_payload_vpu_isVleff = trans_payload[1015];
  assign io_commonOut_transEntry_bits_payload_vlsInstr = trans_payload[1016];
  assign io_commonOut_transEntry_bits_payload_wfflags = trans_payload[1017];
  assign io_commonOut_transEntry_bits_payload_isMove = trans_payload[1018];
  assign io_commonOut_transEntry_bits_payload_isDropAmocasSta = trans_payload[1019];
  assign io_commonOut_transEntry_bits_payload_uopIdx = trans_payload[1026:1020];
  assign io_commonOut_transEntry_bits_payload_isVset = trans_payload[1027];
  assign io_commonOut_transEntry_bits_payload_firstUop = trans_payload[1028];
  assign io_commonOut_transEntry_bits_payload_lastUop = trans_payload[1029];
  assign io_commonOut_transEntry_bits_payload_numUops = trans_payload[1036:1030];
  assign io_commonOut_transEntry_bits_payload_numWB = trans_payload[1043:1037];
  assign io_commonOut_transEntry_bits_payload_commitType = trans_payload[1046:1044];
  assign io_commonOut_transEntry_bits_payload_srcState_0 = trans_payload[1047];
  assign io_commonOut_transEntry_bits_payload_srcState_1 = trans_payload[1048];
  assign io_commonOut_transEntry_bits_payload_srcState_2 = trans_payload[1049];
  assign io_commonOut_transEntry_bits_payload_srcState_3 = trans_payload[1050];
  assign io_commonOut_transEntry_bits_payload_srcState_4 = trans_payload[1051];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_0 = trans_payload[1053:1052];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_1 = trans_payload[1055:1054];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_0_2 = trans_payload[1057:1056];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_0 = trans_payload[1059:1058];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_1 = trans_payload[1061:1060];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_1_2 = trans_payload[1063:1062];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_0 = trans_payload[1065:1064];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_1 = trans_payload[1067:1066];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_2_2 = trans_payload[1069:1068];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_0 = trans_payload[1071:1070];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_1 = trans_payload[1073:1072];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_3_2 = trans_payload[1075:1074];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_0 = trans_payload[1077:1076];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_1 = trans_payload[1079:1078];
  assign io_commonOut_transEntry_bits_payload_srcLoadDependency_4_2 = trans_payload[1081:1080];
  assign io_commonOut_transEntry_bits_payload_psrc_0 = trans_payload[1089:1082];
  assign io_commonOut_transEntry_bits_payload_psrc_1 = trans_payload[1097:1090];
  assign io_commonOut_transEntry_bits_payload_psrc_2 = trans_payload[1105:1098];
  assign io_commonOut_transEntry_bits_payload_psrc_3 = trans_payload[1113:1106];
  assign io_commonOut_transEntry_bits_payload_psrc_4 = trans_payload[1121:1114];
  assign io_commonOut_transEntry_bits_payload_useRegCache_0 = trans_payload[1122];
  assign io_commonOut_transEntry_bits_payload_useRegCache_1 = trans_payload[1123];
  assign io_commonOut_transEntry_bits_payload_regCacheIdx_0 = trans_payload[1128:1124];
  assign io_commonOut_transEntry_bits_payload_regCacheIdx_1 = trans_payload[1133:1129];
  assign io_commonOut_transEntry_bits_payload_robIdx_flag = trans_payload[1134];
  assign io_commonOut_transEntry_bits_payload_robIdx_value = trans_payload[1142:1135];
  assign io_commonOut_transEntry_bits_payload_instrSize = trans_payload[1145:1143];
  assign io_commonOut_transEntry_bits_payload_dirtyFs = trans_payload[1146];
  assign io_commonOut_transEntry_bits_payload_dirtyVs = trans_payload[1147];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_itype = trans_payload[1151:1148];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_iretire = trans_payload[1155:1152];
  assign io_commonOut_transEntry_bits_payload_traceBlockInPipe_ilastsize = trans_payload[1156];
  assign io_commonOut_transEntry_bits_payload_eliminatedMove = trans_payload[1157];
  assign io_commonOut_transEntry_bits_payload_snapshot = trans_payload[1158];
  assign io_commonOut_transEntry_bits_payload_debugInfo_selectTime = trans_payload[1222:1159];
  assign io_commonOut_transEntry_bits_payload_debugInfo_issueTime = trans_payload[1286:1223];
  assign io_commonOut_transEntry_bits_payload_storeSetHit = trans_payload[1287];
  assign io_commonOut_transEntry_bits_payload_waitForRobIdx_flag = trans_payload[1288];
  assign io_commonOut_transEntry_bits_payload_waitForRobIdx_value = trans_payload[1296:1289];
  assign io_commonOut_transEntry_bits_payload_loadWaitBit = trans_payload[1297];
  assign io_commonOut_transEntry_bits_payload_loadWaitStrict = trans_payload[1298];
  assign io_commonOut_transEntry_bits_payload_ssid = trans_payload[1303:1299];
  assign io_commonOut_transEntry_bits_payload_lqIdx_flag = trans_payload[1304];
  assign io_commonOut_transEntry_bits_payload_lqIdx_value = trans_payload[1311:1305];
  assign io_commonOut_transEntry_bits_payload_sqIdx_flag = trans_payload[1312];
  assign io_commonOut_transEntry_bits_payload_sqIdx_value = trans_payload[1318:1313];
  assign io_commonOut_transEntry_bits_payload_singleStep = trans_payload[1319];
  assign io_commonOut_transEntry_bits_payload_replayInst = trans_payload[1320];
  assign io_commonOut_transEntry_bits_payload_debug_fuType = trans_payload[1355:1321];
  assign io_commonOut_transEntry_bits_payload_debug_sim_trig = trans_payload[1356];
  assign io_commonOut_transEntry_bits_payload_numLsElem = trans_payload[1361:1357];
  // END GENERATED(core-inst)

endmodule
