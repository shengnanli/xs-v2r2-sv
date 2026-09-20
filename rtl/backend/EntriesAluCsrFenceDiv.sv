// EntriesAluCsrFenceDiv.sv —— 发射队列条目阵列（AluCsrFenceDiv 变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv（Entries* 家族共享参数化核，本文件不含逻辑分支，
// 只把 golden 的扁平端口打包成核的数组/位向量接口，并给出本变体的参数）。
//
// 本变体规模（全部从 G1 golden EntriesAluCsrFenceDiv.sv 机械量得）：
//   条目 24 = enq 2 + simp 6 + comp 16，发射口 2，源寄存器 2 个
//   WB 唤醒 4 路 + IQ 即时唤醒 7 路（带 og0Cancel / ldCancel×3 取消网络）
//   og0Cancel 的全局 exu 下标（稀疏！）与 is0Lat 是真信号还是常量：
//     IQ0: og0Cancel[0], is0Lat=real
//     IQ1: og0Cancel[2], is0Lat=real
//     IQ2: og0Cancel[4], is0Lat=const1
//     IQ3: og0Cancel[6], is0Lat=const1
//     IQ4: 无取消, is0Lat=const0, 自身是 load 流水 0
//     IQ5: 无取消, is0Lat=const0, 自身是 load 流水 1
//     IQ6: 无取消, is0Lat=const0, 自身是 load 流水 2
//   保留的 FuType one-hot 位：FuType[5], FuType[6], FuType[8], FuType[9]
//   srcLoadDependency 影子：每源 3 条 load 流水 × 2 位（comp 段也存）
//   寄存器缓存：regCacheIdx 5 位，写 RC 的 IQ 路 [0, 1, 2, 3, 4, 5, 6]
//   issueResp 4 档（按 issueTimer）：timer0=常量 2'h0, timer1=真 resp, timer2=常量 2'h0, timer3=常量 2'h0
//   负载：发射口可见 25 个字段 / 586 位；转移包另带 156 个字段，共 1362 位
//   golden 层次：EnqEntry_6 ×2 + OthersEntry_66 ×6 + OthersEntry_72 ×16 + EnqPolicy ×2，本文件把它们一并扁平化。
//
// 唤醒路由（从 golden currentStatus_srcStatus_<s>_srcState 表达式机械提取）：
//   src0: WB[0..3]（rfWen），门控 srcType[0]
//   src1: WB[0..3]（rfWen），门控 srcType[0]
//
// 自动生成：verif/ut/EntriesAluCsrFenceDiv/gen.py（共享库 verif/ut/Entries_common/entries_gen.py）—— 勿手改
// =============================================================================
module EntriesAluCsrFenceDiv (
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  input          io_enq_0_valid,
  input          io_enq_0_bits_status_robIdx_flag,
  input  [7:0]   io_enq_0_bits_status_robIdx_value,
  input          io_enq_0_bits_status_fuType_5,
  input          io_enq_0_bits_status_fuType_6,
  input          io_enq_0_bits_status_fuType_8,
  input          io_enq_0_bits_status_fuType_9,
  input  [7:0]   io_enq_0_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_0_srcType,
  input          io_enq_0_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]   io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]   io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]   io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2,
  input          io_enq_0_bits_status_srcStatus_0_useRegCache,
  input  [4:0]   io_enq_0_bits_status_srcStatus_0_regCacheIdx,
  input  [7:0]   io_enq_0_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_enq_0_bits_status_srcStatus_1_srcType,
  input          io_enq_0_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_enq_0_bits_status_srcStatus_1_dataSources_value,
  input  [1:0]   io_enq_0_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0]   io_enq_0_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0]   io_enq_0_bits_status_srcStatus_1_srcLoadDependency_2,
  input          io_enq_0_bits_status_srcStatus_1_useRegCache,
  input  [4:0]   io_enq_0_bits_status_srcStatus_1_regCacheIdx,
  input  [31:0]  io_enq_0_bits_imm,
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
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_0_0,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_0_1,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_0_2,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_1_0,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_1_1,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_1_2,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_2_0,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_2_1,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_2_2,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_3_0,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_3_1,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_3_2,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_4_0,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_4_1,
  input  [1:0]   io_enq_0_bits_payload_srcLoadDependency_4_2,
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
  input          io_enq_1_bits_status_fuType_5,
  input          io_enq_1_bits_status_fuType_6,
  input          io_enq_1_bits_status_fuType_8,
  input          io_enq_1_bits_status_fuType_9,
  input  [7:0]   io_enq_1_bits_status_srcStatus_0_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_0_srcType,
  input          io_enq_1_bits_status_srcStatus_0_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]   io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]   io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]   io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2,
  input          io_enq_1_bits_status_srcStatus_0_useRegCache,
  input  [4:0]   io_enq_1_bits_status_srcStatus_0_regCacheIdx,
  input  [7:0]   io_enq_1_bits_status_srcStatus_1_psrc,
  input  [3:0]   io_enq_1_bits_status_srcStatus_1_srcType,
  input          io_enq_1_bits_status_srcStatus_1_srcState,
  input  [3:0]   io_enq_1_bits_status_srcStatus_1_dataSources_value,
  input  [1:0]   io_enq_1_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0]   io_enq_1_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0]   io_enq_1_bits_status_srcStatus_1_srcLoadDependency_2,
  input          io_enq_1_bits_status_srcStatus_1_useRegCache,
  input  [4:0]   io_enq_1_bits_status_srcStatus_1_regCacheIdx,
  input  [31:0]  io_enq_1_bits_imm,
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
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_0_0,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_0_1,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_0_2,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_1_0,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_1_1,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_1_2,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_2_0,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_2_1,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_2_2,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_3_0,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_3_1,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_3_2,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_4_0,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_4_1,
  input  [1:0]   io_enq_1_bits_payload_srcLoadDependency_4_2,
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
  input  [23:0]  io_deqSelOH_0_bits,
  input          io_deqSelOH_1_valid,
  input  [23:0]  io_deqSelOH_1_bits,
  input  [1:0]   io_enqEntryOldestSel_0_bits,
  input  [1:0]   io_enqEntryOldestSel_1_bits,
  input          io_simpEntryOldestSel_0_valid,
  input  [5:0]   io_simpEntryOldestSel_0_bits,
  input          io_simpEntryOldestSel_1_valid,
  input  [5:0]   io_simpEntryOldestSel_1_bits,
  input          io_compEntryOldestSel_0_valid,
  input  [15:0]  io_compEntryOldestSel_0_bits,
  input          io_compEntryOldestSel_1_valid,
  input  [15:0]  io_compEntryOldestSel_1_bits,
  input          io_wakeUpFromWB_3_valid,
  input          io_wakeUpFromWB_3_bits_rfWen,
  input  [7:0]   io_wakeUpFromWB_3_bits_pdest,
  input          io_wakeUpFromWB_2_valid,
  input          io_wakeUpFromWB_2_bits_rfWen,
  input  [7:0]   io_wakeUpFromWB_2_bits_pdest,
  input          io_wakeUpFromWB_1_valid,
  input          io_wakeUpFromWB_1_bits_rfWen,
  input  [7:0]   io_wakeUpFromWB_1_bits_pdest,
  input          io_wakeUpFromWB_0_valid,
  input          io_wakeUpFromWB_0_bits_rfWen,
  input  [7:0]   io_wakeUpFromWB_0_bits_pdest,
  input          io_wakeUpFromIQ_6_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_6_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_6_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_6_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_6_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQ_6_bits_rcDest,
  input          io_wakeUpFromIQ_5_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_5_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_5_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_5_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_5_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQ_5_bits_rcDest,
  input          io_wakeUpFromIQ_4_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_4_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_4_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_4_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_4_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQ_4_bits_rcDest,
  input          io_wakeUpFromIQ_3_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_3_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_3_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_3_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_3_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQ_3_bits_rcDest,
  input          io_wakeUpFromIQ_2_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_2_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_2_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_2_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_2_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQ_2_bits_rcDest,
  input          io_wakeUpFromIQ_1_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_1_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_1_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_1_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_1_bits_loadDependency_2,
  input          io_wakeUpFromIQ_1_bits_is0Lat,
  input  [4:0]   io_wakeUpFromIQ_1_bits_rcDest,
  input          io_wakeUpFromIQ_0_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQ_0_bits_pdest,
  input  [1:0]   io_wakeUpFromIQ_0_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQ_0_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQ_0_bits_loadDependency_2,
  input          io_wakeUpFromIQ_0_bits_is0Lat,
  input  [4:0]   io_wakeUpFromIQ_0_bits_rcDest,
  input          io_wakeUpFromWBDelayed_3_valid,
  input          io_wakeUpFromWBDelayed_3_bits_rfWen,
  input  [7:0]   io_wakeUpFromWBDelayed_3_bits_pdest,
  input          io_wakeUpFromWBDelayed_2_valid,
  input          io_wakeUpFromWBDelayed_2_bits_rfWen,
  input  [7:0]   io_wakeUpFromWBDelayed_2_bits_pdest,
  input          io_wakeUpFromWBDelayed_1_valid,
  input          io_wakeUpFromWBDelayed_1_bits_rfWen,
  input  [7:0]   io_wakeUpFromWBDelayed_1_bits_pdest,
  input          io_wakeUpFromWBDelayed_0_valid,
  input          io_wakeUpFromWBDelayed_0_bits_rfWen,
  input  [7:0]   io_wakeUpFromWBDelayed_0_bits_pdest,
  input          io_wakeUpFromIQDelayed_6_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_6_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_6_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_6_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_6_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQDelayed_6_bits_rcDest,
  input          io_wakeUpFromIQDelayed_5_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_5_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_5_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_5_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_5_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQDelayed_5_bits_rcDest,
  input          io_wakeUpFromIQDelayed_4_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_4_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_4_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_4_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_4_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQDelayed_4_bits_rcDest,
  input          io_wakeUpFromIQDelayed_3_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_3_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_3_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_3_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_3_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQDelayed_3_bits_rcDest,
  input          io_wakeUpFromIQDelayed_2_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_2_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_2_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_2_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_2_bits_loadDependency_2,
  input  [4:0]   io_wakeUpFromIQDelayed_2_bits_rcDest,
  input          io_wakeUpFromIQDelayed_1_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_1_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_1_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_1_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_1_bits_loadDependency_2,
  input          io_wakeUpFromIQDelayed_1_bits_is0Lat,
  input  [4:0]   io_wakeUpFromIQDelayed_1_bits_rcDest,
  input          io_wakeUpFromIQDelayed_0_bits_rfWen,
  input  [7:0]   io_wakeUpFromIQDelayed_0_bits_pdest,
  input  [1:0]   io_wakeUpFromIQDelayed_0_bits_loadDependency_0,
  input  [1:0]   io_wakeUpFromIQDelayed_0_bits_loadDependency_1,
  input  [1:0]   io_wakeUpFromIQDelayed_0_bits_loadDependency_2,
  input          io_wakeUpFromIQDelayed_0_bits_is0Lat,
  input  [4:0]   io_wakeUpFromIQDelayed_0_bits_rcDest,
  input          io_og0Cancel_0,
  input          io_og0Cancel_2,
  input          io_og0Cancel_4,
  input          io_og0Cancel_6,
  input          io_ldCancel_0_ld2Cancel,
  input          io_ldCancel_1_ld2Cancel,
  input          io_ldCancel_2_ld2Cancel,
  output [23:0]  io_valid,
  output [23:0]  io_issued,
  output [23:0]  io_canIssue,
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
  output [34:0]  io_fuType_18,
  output [34:0]  io_fuType_19,
  output [34:0]  io_fuType_20,
  output [34:0]  io_fuType_21,
  output [34:0]  io_fuType_22,
  output [34:0]  io_fuType_23,
  output [3:0]   io_dataSources_0_0_value,
  output [3:0]   io_dataSources_0_1_value,
  output [3:0]   io_dataSources_1_0_value,
  output [3:0]   io_dataSources_1_1_value,
  output [3:0]   io_dataSources_2_0_value,
  output [3:0]   io_dataSources_2_1_value,
  output [3:0]   io_dataSources_3_0_value,
  output [3:0]   io_dataSources_3_1_value,
  output [3:0]   io_dataSources_4_0_value,
  output [3:0]   io_dataSources_4_1_value,
  output [3:0]   io_dataSources_5_0_value,
  output [3:0]   io_dataSources_5_1_value,
  output [3:0]   io_dataSources_6_0_value,
  output [3:0]   io_dataSources_6_1_value,
  output [3:0]   io_dataSources_7_0_value,
  output [3:0]   io_dataSources_7_1_value,
  output [3:0]   io_dataSources_8_0_value,
  output [3:0]   io_dataSources_8_1_value,
  output [3:0]   io_dataSources_9_0_value,
  output [3:0]   io_dataSources_9_1_value,
  output [3:0]   io_dataSources_10_0_value,
  output [3:0]   io_dataSources_10_1_value,
  output [3:0]   io_dataSources_11_0_value,
  output [3:0]   io_dataSources_11_1_value,
  output [3:0]   io_dataSources_12_0_value,
  output [3:0]   io_dataSources_12_1_value,
  output [3:0]   io_dataSources_13_0_value,
  output [3:0]   io_dataSources_13_1_value,
  output [3:0]   io_dataSources_14_0_value,
  output [3:0]   io_dataSources_14_1_value,
  output [3:0]   io_dataSources_15_0_value,
  output [3:0]   io_dataSources_15_1_value,
  output [3:0]   io_dataSources_16_0_value,
  output [3:0]   io_dataSources_16_1_value,
  output [3:0]   io_dataSources_17_0_value,
  output [3:0]   io_dataSources_17_1_value,
  output [3:0]   io_dataSources_18_0_value,
  output [3:0]   io_dataSources_18_1_value,
  output [3:0]   io_dataSources_19_0_value,
  output [3:0]   io_dataSources_19_1_value,
  output [3:0]   io_dataSources_20_0_value,
  output [3:0]   io_dataSources_20_1_value,
  output [3:0]   io_dataSources_21_0_value,
  output [3:0]   io_dataSources_21_1_value,
  output [3:0]   io_dataSources_22_0_value,
  output [3:0]   io_dataSources_22_1_value,
  output [3:0]   io_dataSources_23_0_value,
  output [3:0]   io_dataSources_23_1_value,
  output [1:0]   io_loadDependency_0_0,
  output [1:0]   io_loadDependency_0_1,
  output [1:0]   io_loadDependency_0_2,
  output [1:0]   io_loadDependency_1_0,
  output [1:0]   io_loadDependency_1_1,
  output [1:0]   io_loadDependency_1_2,
  output [1:0]   io_loadDependency_2_0,
  output [1:0]   io_loadDependency_2_1,
  output [1:0]   io_loadDependency_2_2,
  output [1:0]   io_loadDependency_3_0,
  output [1:0]   io_loadDependency_3_1,
  output [1:0]   io_loadDependency_3_2,
  output [1:0]   io_loadDependency_4_0,
  output [1:0]   io_loadDependency_4_1,
  output [1:0]   io_loadDependency_4_2,
  output [1:0]   io_loadDependency_5_0,
  output [1:0]   io_loadDependency_5_1,
  output [1:0]   io_loadDependency_5_2,
  output [1:0]   io_loadDependency_6_0,
  output [1:0]   io_loadDependency_6_1,
  output [1:0]   io_loadDependency_6_2,
  output [1:0]   io_loadDependency_7_0,
  output [1:0]   io_loadDependency_7_1,
  output [1:0]   io_loadDependency_7_2,
  output [1:0]   io_loadDependency_8_0,
  output [1:0]   io_loadDependency_8_1,
  output [1:0]   io_loadDependency_8_2,
  output [1:0]   io_loadDependency_9_0,
  output [1:0]   io_loadDependency_9_1,
  output [1:0]   io_loadDependency_9_2,
  output [1:0]   io_loadDependency_10_0,
  output [1:0]   io_loadDependency_10_1,
  output [1:0]   io_loadDependency_10_2,
  output [1:0]   io_loadDependency_11_0,
  output [1:0]   io_loadDependency_11_1,
  output [1:0]   io_loadDependency_11_2,
  output [1:0]   io_loadDependency_12_0,
  output [1:0]   io_loadDependency_12_1,
  output [1:0]   io_loadDependency_12_2,
  output [1:0]   io_loadDependency_13_0,
  output [1:0]   io_loadDependency_13_1,
  output [1:0]   io_loadDependency_13_2,
  output [1:0]   io_loadDependency_14_0,
  output [1:0]   io_loadDependency_14_1,
  output [1:0]   io_loadDependency_14_2,
  output [1:0]   io_loadDependency_15_0,
  output [1:0]   io_loadDependency_15_1,
  output [1:0]   io_loadDependency_15_2,
  output [1:0]   io_loadDependency_16_0,
  output [1:0]   io_loadDependency_16_1,
  output [1:0]   io_loadDependency_16_2,
  output [1:0]   io_loadDependency_17_0,
  output [1:0]   io_loadDependency_17_1,
  output [1:0]   io_loadDependency_17_2,
  output [1:0]   io_loadDependency_18_0,
  output [1:0]   io_loadDependency_18_1,
  output [1:0]   io_loadDependency_18_2,
  output [1:0]   io_loadDependency_19_0,
  output [1:0]   io_loadDependency_19_1,
  output [1:0]   io_loadDependency_19_2,
  output [1:0]   io_loadDependency_20_0,
  output [1:0]   io_loadDependency_20_1,
  output [1:0]   io_loadDependency_20_2,
  output [1:0]   io_loadDependency_21_0,
  output [1:0]   io_loadDependency_21_1,
  output [1:0]   io_loadDependency_21_2,
  output [1:0]   io_loadDependency_22_0,
  output [1:0]   io_loadDependency_22_1,
  output [1:0]   io_loadDependency_22_2,
  output [1:0]   io_loadDependency_23_0,
  output [1:0]   io_loadDependency_23_1,
  output [1:0]   io_loadDependency_23_2,
  output [2:0]   io_exuSources_0_0_value,
  output [2:0]   io_exuSources_0_1_value,
  output [2:0]   io_exuSources_1_0_value,
  output [2:0]   io_exuSources_1_1_value,
  output [2:0]   io_exuSources_2_0_value,
  output [2:0]   io_exuSources_2_1_value,
  output [2:0]   io_exuSources_3_0_value,
  output [2:0]   io_exuSources_3_1_value,
  output [2:0]   io_exuSources_4_0_value,
  output [2:0]   io_exuSources_4_1_value,
  output [2:0]   io_exuSources_5_0_value,
  output [2:0]   io_exuSources_5_1_value,
  output [2:0]   io_exuSources_6_0_value,
  output [2:0]   io_exuSources_6_1_value,
  output [2:0]   io_exuSources_7_0_value,
  output [2:0]   io_exuSources_7_1_value,
  output [2:0]   io_exuSources_8_0_value,
  output [2:0]   io_exuSources_8_1_value,
  output [2:0]   io_exuSources_9_0_value,
  output [2:0]   io_exuSources_9_1_value,
  output [2:0]   io_exuSources_10_0_value,
  output [2:0]   io_exuSources_10_1_value,
  output [2:0]   io_exuSources_11_0_value,
  output [2:0]   io_exuSources_11_1_value,
  output [2:0]   io_exuSources_12_0_value,
  output [2:0]   io_exuSources_12_1_value,
  output [2:0]   io_exuSources_13_0_value,
  output [2:0]   io_exuSources_13_1_value,
  output [2:0]   io_exuSources_14_0_value,
  output [2:0]   io_exuSources_14_1_value,
  output [2:0]   io_exuSources_15_0_value,
  output [2:0]   io_exuSources_15_1_value,
  output [2:0]   io_exuSources_16_0_value,
  output [2:0]   io_exuSources_16_1_value,
  output [2:0]   io_exuSources_17_0_value,
  output [2:0]   io_exuSources_17_1_value,
  output [2:0]   io_exuSources_18_0_value,
  output [2:0]   io_exuSources_18_1_value,
  output [2:0]   io_exuSources_19_0_value,
  output [2:0]   io_exuSources_19_1_value,
  output [2:0]   io_exuSources_20_0_value,
  output [2:0]   io_exuSources_20_1_value,
  output [2:0]   io_exuSources_21_0_value,
  output [2:0]   io_exuSources_21_1_value,
  output [2:0]   io_exuSources_22_0_value,
  output [2:0]   io_exuSources_22_1_value,
  output [2:0]   io_exuSources_23_0_value,
  output [2:0]   io_exuSources_23_1_value,
  output         io_isFirstIssue_0,
  output         io_isFirstIssue_1,
  output         io_deqEntry_0_bits_status_robIdx_flag,
  output [7:0]   io_deqEntry_0_bits_status_robIdx_value,
  output         io_deqEntry_0_bits_status_fuType_5,
  output         io_deqEntry_0_bits_status_fuType_6,
  output         io_deqEntry_0_bits_status_fuType_8,
  output         io_deqEntry_0_bits_status_fuType_9,
  output [7:0]   io_deqEntry_0_bits_status_srcStatus_0_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_0_srcType,
  output [4:0]   io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx,
  output [7:0]   io_deqEntry_0_bits_status_srcStatus_1_psrc,
  output [3:0]   io_deqEntry_0_bits_status_srcStatus_1_srcType,
  output [4:0]   io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx,
  output [31:0]  io_deqEntry_0_bits_imm,
  output [8:0]   io_deqEntry_0_bits_payload_fuOpType,
  output         io_deqEntry_0_bits_payload_rfWen,
  output [3:0]   io_deqEntry_0_bits_payload_selImm,
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
  output         io_deqEntry_1_bits_status_fuType_5,
  output         io_deqEntry_1_bits_status_fuType_6,
  output         io_deqEntry_1_bits_status_fuType_8,
  output         io_deqEntry_1_bits_status_fuType_9,
  output [7:0]   io_deqEntry_1_bits_status_srcStatus_0_psrc,
  output [3:0]   io_deqEntry_1_bits_status_srcStatus_0_srcType,
  output [4:0]   io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx,
  output [7:0]   io_deqEntry_1_bits_status_srcStatus_1_psrc,
  output [3:0]   io_deqEntry_1_bits_status_srcStatus_1_srcType,
  output [4:0]   io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx,
  output [31:0]  io_deqEntry_1_bits_imm,
  output         io_deqEntry_1_bits_payload_preDecodeInfo_valid,
  output         io_deqEntry_1_bits_payload_preDecodeInfo_isRVC,
  output [1:0]   io_deqEntry_1_bits_payload_preDecodeInfo_brType,
  output         io_deqEntry_1_bits_payload_preDecodeInfo_isCall,
  output         io_deqEntry_1_bits_payload_preDecodeInfo_isRet,
  output         io_deqEntry_1_bits_payload_pred_taken,
  output         io_deqEntry_1_bits_payload_ftqPtr_flag,
  output [5:0]   io_deqEntry_1_bits_payload_ftqPtr_value,
  output [3:0]   io_deqEntry_1_bits_payload_ftqOffset,
  output [8:0]   io_deqEntry_1_bits_payload_fuOpType,
  output         io_deqEntry_1_bits_payload_rfWen,
  output         io_deqEntry_1_bits_payload_flushPipe,
  output [3:0]   io_deqEntry_1_bits_payload_selImm,
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
  output         io_cancelDeqVec_0,
  output         io_cancelDeqVec_1,
  input  [5:0]   io_simpEntryDeqSelVec_0,
  input  [5:0]   io_simpEntryDeqSelVec_1,
  output [5:0]   io_simpEntryEnqSelVec_0,
  output [5:0]   io_simpEntryEnqSelVec_1,
  output [15:0]  io_compEntryEnqSelVec_0,
  output [15:0]  io_compEntryEnqSelVec_1
);

  // BEGIN GENERATED(core-inst)
  logic [1:0][1361:0] enq_payload;
  assign enq_payload[0] = {io_enq_0_bits_payload_numLsElem, io_enq_0_bits_payload_debug_sim_trig, io_enq_0_bits_payload_debug_fuType, io_enq_0_bits_payload_replayInst, io_enq_0_bits_payload_singleStep, io_enq_0_bits_payload_sqIdx_value, io_enq_0_bits_payload_sqIdx_flag, io_enq_0_bits_payload_lqIdx_value, io_enq_0_bits_payload_lqIdx_flag, io_enq_0_bits_payload_ssid, io_enq_0_bits_payload_loadWaitStrict, io_enq_0_bits_payload_loadWaitBit, io_enq_0_bits_payload_waitForRobIdx_value, io_enq_0_bits_payload_waitForRobIdx_flag, io_enq_0_bits_payload_storeSetHit, io_enq_0_bits_payload_debugInfo_issueTime, io_enq_0_bits_payload_debugInfo_selectTime, io_enq_0_bits_payload_snapshot, io_enq_0_bits_payload_eliminatedMove, io_enq_0_bits_payload_traceBlockInPipe_ilastsize, io_enq_0_bits_payload_traceBlockInPipe_iretire, io_enq_0_bits_payload_traceBlockInPipe_itype, io_enq_0_bits_payload_dirtyVs, io_enq_0_bits_payload_dirtyFs, io_enq_0_bits_payload_instrSize, io_enq_0_bits_payload_robIdx_value, io_enq_0_bits_payload_robIdx_flag, io_enq_0_bits_payload_regCacheIdx_1, io_enq_0_bits_payload_regCacheIdx_0, io_enq_0_bits_payload_useRegCache_1, io_enq_0_bits_payload_useRegCache_0, io_enq_0_bits_payload_psrc_4, io_enq_0_bits_payload_psrc_3, io_enq_0_bits_payload_psrc_2, io_enq_0_bits_payload_psrc_1, io_enq_0_bits_payload_psrc_0, io_enq_0_bits_payload_srcLoadDependency_4_2, io_enq_0_bits_payload_srcLoadDependency_4_1, io_enq_0_bits_payload_srcLoadDependency_4_0, io_enq_0_bits_payload_srcLoadDependency_3_2, io_enq_0_bits_payload_srcLoadDependency_3_1, io_enq_0_bits_payload_srcLoadDependency_3_0, io_enq_0_bits_payload_srcLoadDependency_2_2, io_enq_0_bits_payload_srcLoadDependency_2_1, io_enq_0_bits_payload_srcLoadDependency_2_0, io_enq_0_bits_payload_srcLoadDependency_1_2, io_enq_0_bits_payload_srcLoadDependency_1_1, io_enq_0_bits_payload_srcLoadDependency_1_0, io_enq_0_bits_payload_srcLoadDependency_0_2, io_enq_0_bits_payload_srcLoadDependency_0_1, io_enq_0_bits_payload_srcLoadDependency_0_0, io_enq_0_bits_payload_srcState_4, io_enq_0_bits_payload_srcState_3, io_enq_0_bits_payload_srcState_2, io_enq_0_bits_payload_srcState_1, io_enq_0_bits_payload_srcState_0, io_enq_0_bits_payload_commitType, io_enq_0_bits_payload_numWB, io_enq_0_bits_payload_numUops, io_enq_0_bits_payload_lastUop, io_enq_0_bits_payload_firstUop, io_enq_0_bits_payload_isVset, io_enq_0_bits_payload_uopIdx, io_enq_0_bits_payload_isDropAmocasSta, io_enq_0_bits_payload_isMove, io_enq_0_bits_payload_wfflags, io_enq_0_bits_payload_vlsInstr, io_enq_0_bits_payload_vpu_isVleff, io_enq_0_bits_payload_vpu_isWritePartVd, io_enq_0_bits_payload_vpu_isDependOldVd, io_enq_0_bits_payload_vpu_isMove, io_enq_0_bits_payload_vpu_isOpMask, io_enq_0_bits_payload_vpu_isDstMask, io_enq_0_bits_payload_vpu_isNarrow, io_enq_0_bits_payload_vpu_isExt, io_enq_0_bits_payload_vpu_isReverse, io_enq_0_bits_payload_vpu_veew, io_enq_0_bits_payload_vpu_nf, io_enq_0_bits_payload_vpu_vl, io_enq_0_bits_payload_vpu_vmask, io_enq_0_bits_payload_vpu_lastUop, io_enq_0_bits_payload_vpu_vuopIdx, io_enq_0_bits_payload_vpu_vxrm, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_0_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_0_bits_payload_vpu_fpu_isReduction, io_enq_0_bits_payload_vpu_fpu_isFP64Instr, io_enq_0_bits_payload_vpu_fpu_isFP32Instr, io_enq_0_bits_payload_vpu_fpu_isFpToVecInst, io_enq_0_bits_payload_vpu_frm, io_enq_0_bits_payload_vpu_vstart, io_enq_0_bits_payload_vpu_vm, io_enq_0_bits_payload_vpu_specVlmul, io_enq_0_bits_payload_vpu_specVsew, io_enq_0_bits_payload_vpu_specVta, io_enq_0_bits_payload_vpu_specVma, io_enq_0_bits_payload_vpu_specVill, io_enq_0_bits_payload_vpu_vlmul, io_enq_0_bits_payload_vpu_vsew, io_enq_0_bits_payload_vpu_vta, io_enq_0_bits_payload_vpu_vma, io_enq_0_bits_payload_vpu_vill, io_enq_0_bits_payload_fpu_rm, io_enq_0_bits_payload_fpu_fmt, io_enq_0_bits_payload_fpu_typ, io_enq_0_bits_payload_fpu_wflags, io_enq_0_bits_payload_fpu_typeTagOut, io_enq_0_bits_payload_imm, io_enq_0_bits_payload_canRobCompress, io_enq_0_bits_payload_blockBackward, io_enq_0_bits_payload_waitForward, io_enq_0_bits_payload_isXSTrap, io_enq_0_bits_payload_vlWen, io_enq_0_bits_payload_v0Wen, io_enq_0_bits_payload_vecWen, io_enq_0_bits_payload_fpWen, io_enq_0_bits_payload_fuType, io_enq_0_bits_payload_ldest, io_enq_0_bits_payload_srcType_4, io_enq_0_bits_payload_srcType_3, io_enq_0_bits_payload_srcType_2, io_enq_0_bits_payload_srcType_1, io_enq_0_bits_payload_srcType_0, io_enq_0_bits_payload_satpFlushFirstFetchFault, io_enq_0_bits_payload_crossPageIPFFix, io_enq_0_bits_payload_trigger, io_enq_0_bits_payload_hasException, io_enq_0_bits_payload_isFetchMalAddr, io_enq_0_bits_payload_exceptionVec_23, io_enq_0_bits_payload_exceptionVec_22, io_enq_0_bits_payload_exceptionVec_21, io_enq_0_bits_payload_exceptionVec_20, io_enq_0_bits_payload_exceptionVec_19, io_enq_0_bits_payload_exceptionVec_18, io_enq_0_bits_payload_exceptionVec_17, io_enq_0_bits_payload_exceptionVec_16, io_enq_0_bits_payload_exceptionVec_15, io_enq_0_bits_payload_exceptionVec_14, io_enq_0_bits_payload_exceptionVec_13, io_enq_0_bits_payload_exceptionVec_12, io_enq_0_bits_payload_exceptionVec_11, io_enq_0_bits_payload_exceptionVec_10, io_enq_0_bits_payload_exceptionVec_9, io_enq_0_bits_payload_exceptionVec_8, io_enq_0_bits_payload_exceptionVec_7, io_enq_0_bits_payload_exceptionVec_6, io_enq_0_bits_payload_exceptionVec_5, io_enq_0_bits_payload_exceptionVec_4, io_enq_0_bits_payload_exceptionVec_3, io_enq_0_bits_payload_exceptionVec_2, io_enq_0_bits_payload_exceptionVec_1, io_enq_0_bits_payload_exceptionVec_0, io_enq_0_bits_payload_foldpc, io_enq_0_bits_payload_pc, io_enq_0_bits_payload_instr, io_enq_0_bits_payload_debug_seqNum_uopIdx, io_enq_0_bits_payload_debug_seqNum_seqNum, io_enq_0_bits_payload_debugInfo_tlbRespTime, io_enq_0_bits_payload_debugInfo_tlbFirstReqTime, io_enq_0_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_0_bits_payload_debugInfo_writebackTime, io_enq_0_bits_payload_debugInfo_enqRsTime, io_enq_0_bits_payload_debugInfo_dispatchTime, io_enq_0_bits_payload_debugInfo_renameTime, io_enq_0_bits_payload_debugInfo_eliminatedMove, io_enq_0_bits_payload_pdest, io_enq_0_bits_payload_selImm, io_enq_0_bits_payload_flushPipe, io_enq_0_bits_payload_rfWen, io_enq_0_bits_payload_fuOpType, io_enq_0_bits_payload_ftqOffset, io_enq_0_bits_payload_ftqPtr_value, io_enq_0_bits_payload_ftqPtr_flag, io_enq_0_bits_payload_pred_taken, io_enq_0_bits_payload_preDecodeInfo_isRet, io_enq_0_bits_payload_preDecodeInfo_isCall, io_enq_0_bits_payload_preDecodeInfo_brType, io_enq_0_bits_payload_preDecodeInfo_isRVC, io_enq_0_bits_payload_preDecodeInfo_valid, io_enq_0_bits_imm};
  assign enq_payload[1] = {io_enq_1_bits_payload_numLsElem, io_enq_1_bits_payload_debug_sim_trig, io_enq_1_bits_payload_debug_fuType, io_enq_1_bits_payload_replayInst, io_enq_1_bits_payload_singleStep, io_enq_1_bits_payload_sqIdx_value, io_enq_1_bits_payload_sqIdx_flag, io_enq_1_bits_payload_lqIdx_value, io_enq_1_bits_payload_lqIdx_flag, io_enq_1_bits_payload_ssid, io_enq_1_bits_payload_loadWaitStrict, io_enq_1_bits_payload_loadWaitBit, io_enq_1_bits_payload_waitForRobIdx_value, io_enq_1_bits_payload_waitForRobIdx_flag, io_enq_1_bits_payload_storeSetHit, io_enq_1_bits_payload_debugInfo_issueTime, io_enq_1_bits_payload_debugInfo_selectTime, io_enq_1_bits_payload_snapshot, io_enq_1_bits_payload_eliminatedMove, io_enq_1_bits_payload_traceBlockInPipe_ilastsize, io_enq_1_bits_payload_traceBlockInPipe_iretire, io_enq_1_bits_payload_traceBlockInPipe_itype, io_enq_1_bits_payload_dirtyVs, io_enq_1_bits_payload_dirtyFs, io_enq_1_bits_payload_instrSize, io_enq_1_bits_payload_robIdx_value, io_enq_1_bits_payload_robIdx_flag, io_enq_1_bits_payload_regCacheIdx_1, io_enq_1_bits_payload_regCacheIdx_0, io_enq_1_bits_payload_useRegCache_1, io_enq_1_bits_payload_useRegCache_0, io_enq_1_bits_payload_psrc_4, io_enq_1_bits_payload_psrc_3, io_enq_1_bits_payload_psrc_2, io_enq_1_bits_payload_psrc_1, io_enq_1_bits_payload_psrc_0, io_enq_1_bits_payload_srcLoadDependency_4_2, io_enq_1_bits_payload_srcLoadDependency_4_1, io_enq_1_bits_payload_srcLoadDependency_4_0, io_enq_1_bits_payload_srcLoadDependency_3_2, io_enq_1_bits_payload_srcLoadDependency_3_1, io_enq_1_bits_payload_srcLoadDependency_3_0, io_enq_1_bits_payload_srcLoadDependency_2_2, io_enq_1_bits_payload_srcLoadDependency_2_1, io_enq_1_bits_payload_srcLoadDependency_2_0, io_enq_1_bits_payload_srcLoadDependency_1_2, io_enq_1_bits_payload_srcLoadDependency_1_1, io_enq_1_bits_payload_srcLoadDependency_1_0, io_enq_1_bits_payload_srcLoadDependency_0_2, io_enq_1_bits_payload_srcLoadDependency_0_1, io_enq_1_bits_payload_srcLoadDependency_0_0, io_enq_1_bits_payload_srcState_4, io_enq_1_bits_payload_srcState_3, io_enq_1_bits_payload_srcState_2, io_enq_1_bits_payload_srcState_1, io_enq_1_bits_payload_srcState_0, io_enq_1_bits_payload_commitType, io_enq_1_bits_payload_numWB, io_enq_1_bits_payload_numUops, io_enq_1_bits_payload_lastUop, io_enq_1_bits_payload_firstUop, io_enq_1_bits_payload_isVset, io_enq_1_bits_payload_uopIdx, io_enq_1_bits_payload_isDropAmocasSta, io_enq_1_bits_payload_isMove, io_enq_1_bits_payload_wfflags, io_enq_1_bits_payload_vlsInstr, io_enq_1_bits_payload_vpu_isVleff, io_enq_1_bits_payload_vpu_isWritePartVd, io_enq_1_bits_payload_vpu_isDependOldVd, io_enq_1_bits_payload_vpu_isMove, io_enq_1_bits_payload_vpu_isOpMask, io_enq_1_bits_payload_vpu_isDstMask, io_enq_1_bits_payload_vpu_isNarrow, io_enq_1_bits_payload_vpu_isExt, io_enq_1_bits_payload_vpu_isReverse, io_enq_1_bits_payload_vpu_veew, io_enq_1_bits_payload_vpu_nf, io_enq_1_bits_payload_vpu_vl, io_enq_1_bits_payload_vpu_vmask, io_enq_1_bits_payload_vpu_lastUop, io_enq_1_bits_payload_vpu_vuopIdx, io_enq_1_bits_payload_vpu_vxrm, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_8, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_4, io_enq_1_bits_payload_vpu_fpu_isFoldTo1_2, io_enq_1_bits_payload_vpu_fpu_isReduction, io_enq_1_bits_payload_vpu_fpu_isFP64Instr, io_enq_1_bits_payload_vpu_fpu_isFP32Instr, io_enq_1_bits_payload_vpu_fpu_isFpToVecInst, io_enq_1_bits_payload_vpu_frm, io_enq_1_bits_payload_vpu_vstart, io_enq_1_bits_payload_vpu_vm, io_enq_1_bits_payload_vpu_specVlmul, io_enq_1_bits_payload_vpu_specVsew, io_enq_1_bits_payload_vpu_specVta, io_enq_1_bits_payload_vpu_specVma, io_enq_1_bits_payload_vpu_specVill, io_enq_1_bits_payload_vpu_vlmul, io_enq_1_bits_payload_vpu_vsew, io_enq_1_bits_payload_vpu_vta, io_enq_1_bits_payload_vpu_vma, io_enq_1_bits_payload_vpu_vill, io_enq_1_bits_payload_fpu_rm, io_enq_1_bits_payload_fpu_fmt, io_enq_1_bits_payload_fpu_typ, io_enq_1_bits_payload_fpu_wflags, io_enq_1_bits_payload_fpu_typeTagOut, io_enq_1_bits_payload_imm, io_enq_1_bits_payload_canRobCompress, io_enq_1_bits_payload_blockBackward, io_enq_1_bits_payload_waitForward, io_enq_1_bits_payload_isXSTrap, io_enq_1_bits_payload_vlWen, io_enq_1_bits_payload_v0Wen, io_enq_1_bits_payload_vecWen, io_enq_1_bits_payload_fpWen, io_enq_1_bits_payload_fuType, io_enq_1_bits_payload_ldest, io_enq_1_bits_payload_srcType_4, io_enq_1_bits_payload_srcType_3, io_enq_1_bits_payload_srcType_2, io_enq_1_bits_payload_srcType_1, io_enq_1_bits_payload_srcType_0, io_enq_1_bits_payload_satpFlushFirstFetchFault, io_enq_1_bits_payload_crossPageIPFFix, io_enq_1_bits_payload_trigger, io_enq_1_bits_payload_hasException, io_enq_1_bits_payload_isFetchMalAddr, io_enq_1_bits_payload_exceptionVec_23, io_enq_1_bits_payload_exceptionVec_22, io_enq_1_bits_payload_exceptionVec_21, io_enq_1_bits_payload_exceptionVec_20, io_enq_1_bits_payload_exceptionVec_19, io_enq_1_bits_payload_exceptionVec_18, io_enq_1_bits_payload_exceptionVec_17, io_enq_1_bits_payload_exceptionVec_16, io_enq_1_bits_payload_exceptionVec_15, io_enq_1_bits_payload_exceptionVec_14, io_enq_1_bits_payload_exceptionVec_13, io_enq_1_bits_payload_exceptionVec_12, io_enq_1_bits_payload_exceptionVec_11, io_enq_1_bits_payload_exceptionVec_10, io_enq_1_bits_payload_exceptionVec_9, io_enq_1_bits_payload_exceptionVec_8, io_enq_1_bits_payload_exceptionVec_7, io_enq_1_bits_payload_exceptionVec_6, io_enq_1_bits_payload_exceptionVec_5, io_enq_1_bits_payload_exceptionVec_4, io_enq_1_bits_payload_exceptionVec_3, io_enq_1_bits_payload_exceptionVec_2, io_enq_1_bits_payload_exceptionVec_1, io_enq_1_bits_payload_exceptionVec_0, io_enq_1_bits_payload_foldpc, io_enq_1_bits_payload_pc, io_enq_1_bits_payload_instr, io_enq_1_bits_payload_debug_seqNum_uopIdx, io_enq_1_bits_payload_debug_seqNum_seqNum, io_enq_1_bits_payload_debugInfo_tlbRespTime, io_enq_1_bits_payload_debugInfo_tlbFirstReqTime, io_enq_1_bits_payload_debugInfo_runahead_checkpoint_id, io_enq_1_bits_payload_debugInfo_writebackTime, io_enq_1_bits_payload_debugInfo_enqRsTime, io_enq_1_bits_payload_debugInfo_dispatchTime, io_enq_1_bits_payload_debugInfo_renameTime, io_enq_1_bits_payload_debugInfo_eliminatedMove, io_enq_1_bits_payload_pdest, io_enq_1_bits_payload_selImm, io_enq_1_bits_payload_flushPipe, io_enq_1_bits_payload_rfWen, io_enq_1_bits_payload_fuOpType, io_enq_1_bits_payload_ftqOffset, io_enq_1_bits_payload_ftqPtr_value, io_enq_1_bits_payload_ftqPtr_flag, io_enq_1_bits_payload_pred_taken, io_enq_1_bits_payload_preDecodeInfo_isRet, io_enq_1_bits_payload_preDecodeInfo_isCall, io_enq_1_bits_payload_preDecodeInfo_brType, io_enq_1_bits_payload_preDecodeInfo_isRVC, io_enq_1_bits_payload_preDecodeInfo_valid, io_enq_1_bits_imm};

  logic [1:0][585:0] deq_payload;
  logic [23:0][3:0] fu_type_narrow;
  logic [1:0][3:0] deq_fu_type;
  logic [1:0][1:0][7:0] deq_psrc;
  logic [1:0][1:0][3:0] deq_src_type;
  logic [1:0] deq_rob_flag;
  logic [1:0][7:0] deq_rob_value;
  logic [23:0][1:0][3:0] data_src;
  // 核的这几个出口：顶层有对应端口的接有名线（后面展开），没有的接悬空线
  logic [23:0][1:0][2:0] exu_src;
  logic [23:0][2:0][1:0] ld_dep_out;
  logic [1:0][1:0][2:0][1:0] unused_deq_ld_dep;
  logic [1:0][1:0][4:0] deq_rc_idx;

  xs_iq_entries_core #(
    .NUM_ENQ(2), .NUM_SIMP(6), .NUM_COMP(16), .NUM_DEQ(2),
    .NUM_REGSRC(2), .NUM_WK_WB(4), .NUM_FU_BIT(4),
    .ROB_W(8), .PSRC_W(8), .PDEST_W(8),
    .PL_DEQ_W(586), .PL_TRANS_W(1362),
    .HAS_LD_DEP(1), .COMP_HAS_LD_DEP(1),
    .HAS_LD_CANCEL(1), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(7), .EXU_W(3),
    .IQ_SRC_MASK({7'b1111111, 7'b1111111}),
    .IQ_WEN_PRESENT(5'b00001),
    .IQD_WEN_PRESENT(5'b00001),
    .IQ_IS_LD_PIPE({3'b100, 3'b010, 3'b001, 3'b000, 3'b000, 3'b000, 3'b000}),
    .OG0_HAS_SRC(7'b0001111),
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
    .OG_HAS_BITS(4'b0010),
    .OG_CONST_RESP({2'h0, 2'h0, 2'h0, 2'h0})
  ) u_core (
    .clock(clock), .reset(reset),
    .flush_valid(io_flush_valid), .flush_rob_flag(io_flush_bits_robIdx_flag),
    .flush_rob_value(io_flush_bits_robIdx_value), .flush_level(io_flush_bits_level),
    .enq_valid({io_enq_1_valid, io_enq_0_valid}),
    .enq_rob_flag({io_enq_1_bits_status_robIdx_flag, io_enq_0_bits_status_robIdx_flag}),
    .enq_rob_value({io_enq_1_bits_status_robIdx_value, io_enq_0_bits_status_robIdx_value}),
    .enq_fu_type({io_enq_1_bits_status_fuType_9, io_enq_1_bits_status_fuType_8, io_enq_1_bits_status_fuType_6, io_enq_1_bits_status_fuType_5, io_enq_0_bits_status_fuType_9, io_enq_0_bits_status_fuType_8, io_enq_0_bits_status_fuType_6, io_enq_0_bits_status_fuType_5}),
    .enq_psrc({io_enq_1_bits_status_srcStatus_1_psrc, io_enq_1_bits_status_srcStatus_0_psrc, io_enq_0_bits_status_srcStatus_1_psrc, io_enq_0_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_enq_1_bits_status_srcStatus_1_srcType, io_enq_1_bits_status_srcStatus_0_srcType, io_enq_0_bits_status_srcStatus_1_srcType, io_enq_0_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_enq_1_bits_status_srcStatus_1_srcState, io_enq_1_bits_status_srcStatus_0_srcState, io_enq_0_bits_status_srcStatus_1_srcState, io_enq_0_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_enq_1_bits_status_srcStatus_1_dataSources_value, io_enq_1_bits_status_srcStatus_0_dataSources_value, io_enq_0_bits_status_srcStatus_1_dataSources_value, io_enq_0_bits_status_srcStatus_0_dataSources_value}),
    .enq_payload(enq_payload),
    .enq_ld_dep({io_enq_1_bits_status_srcStatus_1_srcLoadDependency_2, io_enq_1_bits_status_srcStatus_1_srcLoadDependency_1, io_enq_1_bits_status_srcStatus_1_srcLoadDependency_0, io_enq_1_bits_status_srcStatus_0_srcLoadDependency_2, io_enq_1_bits_status_srcStatus_0_srcLoadDependency_1, io_enq_1_bits_status_srcStatus_0_srcLoadDependency_0, io_enq_0_bits_status_srcStatus_1_srcLoadDependency_2, io_enq_0_bits_status_srcStatus_1_srcLoadDependency_1, io_enq_0_bits_status_srcStatus_1_srcLoadDependency_0, io_enq_0_bits_status_srcStatus_0_srcLoadDependency_2, io_enq_0_bits_status_srcStatus_0_srcLoadDependency_1, io_enq_0_bits_status_srcStatus_0_srcLoadDependency_0}),
    .enq_pl_ld_dep({io_enq_1_bits_payload_srcLoadDependency_1_2, io_enq_1_bits_payload_srcLoadDependency_1_1, io_enq_1_bits_payload_srcLoadDependency_1_0, io_enq_1_bits_payload_srcLoadDependency_0_2, io_enq_1_bits_payload_srcLoadDependency_0_1, io_enq_1_bits_payload_srcLoadDependency_0_0, io_enq_0_bits_payload_srcLoadDependency_1_2, io_enq_0_bits_payload_srcLoadDependency_1_1, io_enq_0_bits_payload_srcLoadDependency_1_0, io_enq_0_bits_payload_srcLoadDependency_0_2, io_enq_0_bits_payload_srcLoadDependency_0_1, io_enq_0_bits_payload_srcLoadDependency_0_0}),
    .enq_use_rc({io_enq_1_bits_status_srcStatus_1_useRegCache, io_enq_1_bits_status_srcStatus_0_useRegCache, io_enq_0_bits_status_srcStatus_1_useRegCache, io_enq_0_bits_status_srcStatus_0_useRegCache}),
    .enq_rc_idx({io_enq_1_bits_status_srcStatus_1_regCacheIdx, io_enq_1_bits_status_srcStatus_0_regCacheIdx, io_enq_0_bits_status_srcStatus_1_regCacheIdx, io_enq_0_bits_status_srcStatus_0_regCacheIdx}),
    .iq_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_6_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_5_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_4_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQ_0_bits_rfWen}}),
    .iq_pdest({io_wakeUpFromIQ_6_bits_pdest, io_wakeUpFromIQ_5_bits_pdest, io_wakeUpFromIQ_4_bits_pdest, io_wakeUpFromIQ_3_bits_pdest, io_wakeUpFromIQ_2_bits_pdest, io_wakeUpFromIQ_1_bits_pdest, io_wakeUpFromIQ_0_bits_pdest}),
    .iq_ld_dep({io_wakeUpFromIQ_6_bits_loadDependency_2, io_wakeUpFromIQ_6_bits_loadDependency_1, io_wakeUpFromIQ_6_bits_loadDependency_0, io_wakeUpFromIQ_5_bits_loadDependency_2, io_wakeUpFromIQ_5_bits_loadDependency_1, io_wakeUpFromIQ_5_bits_loadDependency_0, io_wakeUpFromIQ_4_bits_loadDependency_2, io_wakeUpFromIQ_4_bits_loadDependency_1, io_wakeUpFromIQ_4_bits_loadDependency_0, io_wakeUpFromIQ_3_bits_loadDependency_2, io_wakeUpFromIQ_3_bits_loadDependency_1, io_wakeUpFromIQ_3_bits_loadDependency_0, io_wakeUpFromIQ_2_bits_loadDependency_2, io_wakeUpFromIQ_2_bits_loadDependency_1, io_wakeUpFromIQ_2_bits_loadDependency_0, io_wakeUpFromIQ_1_bits_loadDependency_2, io_wakeUpFromIQ_1_bits_loadDependency_1, io_wakeUpFromIQ_1_bits_loadDependency_0, io_wakeUpFromIQ_0_bits_loadDependency_2, io_wakeUpFromIQ_0_bits_loadDependency_1, io_wakeUpFromIQ_0_bits_loadDependency_0}),
    .iq_rc_dest({io_wakeUpFromIQ_6_bits_rcDest, io_wakeUpFromIQ_5_bits_rcDest, io_wakeUpFromIQ_4_bits_rcDest, io_wakeUpFromIQ_3_bits_rcDest, io_wakeUpFromIQ_2_bits_rcDest, io_wakeUpFromIQ_1_bits_rcDest, io_wakeUpFromIQ_0_bits_rcDest}),
    .iqd_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_6_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_5_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_4_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromIQDelayed_0_bits_rfWen}}),
    .iqd_pdest({io_wakeUpFromIQDelayed_6_bits_pdest, io_wakeUpFromIQDelayed_5_bits_pdest, io_wakeUpFromIQDelayed_4_bits_pdest, io_wakeUpFromIQDelayed_3_bits_pdest, io_wakeUpFromIQDelayed_2_bits_pdest, io_wakeUpFromIQDelayed_1_bits_pdest, io_wakeUpFromIQDelayed_0_bits_pdest}),
    .iqd_ld_dep({io_wakeUpFromIQDelayed_6_bits_loadDependency_2, io_wakeUpFromIQDelayed_6_bits_loadDependency_1, io_wakeUpFromIQDelayed_6_bits_loadDependency_0, io_wakeUpFromIQDelayed_5_bits_loadDependency_2, io_wakeUpFromIQDelayed_5_bits_loadDependency_1, io_wakeUpFromIQDelayed_5_bits_loadDependency_0, io_wakeUpFromIQDelayed_4_bits_loadDependency_2, io_wakeUpFromIQDelayed_4_bits_loadDependency_1, io_wakeUpFromIQDelayed_4_bits_loadDependency_0, io_wakeUpFromIQDelayed_3_bits_loadDependency_2, io_wakeUpFromIQDelayed_3_bits_loadDependency_1, io_wakeUpFromIQDelayed_3_bits_loadDependency_0, io_wakeUpFromIQDelayed_2_bits_loadDependency_2, io_wakeUpFromIQDelayed_2_bits_loadDependency_1, io_wakeUpFromIQDelayed_2_bits_loadDependency_0, io_wakeUpFromIQDelayed_1_bits_loadDependency_2, io_wakeUpFromIQDelayed_1_bits_loadDependency_1, io_wakeUpFromIQDelayed_1_bits_loadDependency_0, io_wakeUpFromIQDelayed_0_bits_loadDependency_2, io_wakeUpFromIQDelayed_0_bits_loadDependency_1, io_wakeUpFromIQDelayed_0_bits_loadDependency_0}),
    .iqd_rc_dest({io_wakeUpFromIQDelayed_6_bits_rcDest, io_wakeUpFromIQDelayed_5_bits_rcDest, io_wakeUpFromIQDelayed_4_bits_rcDest, io_wakeUpFromIQDelayed_3_bits_rcDest, io_wakeUpFromIQDelayed_2_bits_rcDest, io_wakeUpFromIQDelayed_1_bits_rcDest, io_wakeUpFromIQDelayed_0_bits_rcDest}),
    .og0_cancel_sel({1'b0, 1'b0, 1'b0, io_og0Cancel_6, io_og0Cancel_4, io_og0Cancel_2, io_og0Cancel_0}),
    .iq_is0lat({1'b0, 1'b0, 1'b0, 1'b1, 1'b1, io_wakeUpFromIQ_1_bits_is0Lat, io_wakeUpFromIQ_0_bits_is0Lat}),
    .iqd_is0lat({1'b0, 1'b0, 1'b0, 1'b1, 1'b1, io_wakeUpFromIQDelayed_1_bits_is0Lat, io_wakeUpFromIQDelayed_0_bits_is0Lat}),
    .ld1_cancel('0),
    .ld2_cancel({io_ldCancel_2_ld2Cancel, io_ldCancel_1_ld2Cancel, io_ldCancel_0_ld2Cancel}),
    .wk_valid({io_wakeUpFromWB_3_valid, io_wakeUpFromWB_2_valid, io_wakeUpFromWB_1_valid, io_wakeUpFromWB_0_valid}),
    .wk_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWB_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWB_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWB_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWB_0_bits_rfWen}}),
    .wk_pdest({io_wakeUpFromWB_3_bits_pdest, io_wakeUpFromWB_2_bits_pdest, io_wakeUpFromWB_1_bits_pdest, io_wakeUpFromWB_0_bits_pdest}),
    .wkd_valid({io_wakeUpFromWBDelayed_3_valid, io_wakeUpFromWBDelayed_2_valid, io_wakeUpFromWBDelayed_1_valid, io_wakeUpFromWBDelayed_0_valid}),
    .wkd_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_wakeUpFromWBDelayed_0_bits_rfWen}}),
    .wkd_pdest({io_wakeUpFromWBDelayed_3_bits_pdest, io_wakeUpFromWBDelayed_2_bits_pdest, io_wakeUpFromWBDelayed_1_bits_pdest, io_wakeUpFromWBDelayed_0_bits_pdest}),
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
    .o_exu_src(exu_src), .o_ld_dep(ld_dep_out),
    .o_deq_ld_dep(unused_deq_ld_dep), .o_deq_rc_idx(deq_rc_idx),
    .o_cancel_deq({io_cancelDeqVec_1, io_cancelDeqVec_0}),
    .o_fu_type(fu_type_narrow), .o_data_src(data_src),
    .o_is_first_issue({io_isFirstIssue_1, io_isFirstIssue_0}),
    .o_deq_rob_flag(deq_rob_flag), .o_deq_rob_value(deq_rob_value),
    .o_deq_fu_type(deq_fu_type), .o_deq_psrc(deq_psrc),
    .o_deq_src_type(deq_src_type), .o_deq_payload(deq_payload),
    .o_simp_enq_sel_vec({io_simpEntryEnqSelVec_1, io_simpEntryEnqSelVec_0}),
    .o_comp_enq_sel_vec({io_compEntryEnqSelVec_1, io_compEntryEnqSelVec_0})
  );

  // fuType 输出：核只存本变体保留的 4 位，这里放回 35 位 one-hot 的原位置
  assign io_fuType_0 = {25'h0, fu_type_narrow[0][3], fu_type_narrow[0][2], 1'h0, fu_type_narrow[0][1], fu_type_narrow[0][0], 5'h0};
  assign io_fuType_1 = {25'h0, fu_type_narrow[1][3], fu_type_narrow[1][2], 1'h0, fu_type_narrow[1][1], fu_type_narrow[1][0], 5'h0};
  assign io_fuType_2 = {25'h0, fu_type_narrow[2][3], fu_type_narrow[2][2], 1'h0, fu_type_narrow[2][1], fu_type_narrow[2][0], 5'h0};
  assign io_fuType_3 = {25'h0, fu_type_narrow[3][3], fu_type_narrow[3][2], 1'h0, fu_type_narrow[3][1], fu_type_narrow[3][0], 5'h0};
  assign io_fuType_4 = {25'h0, fu_type_narrow[4][3], fu_type_narrow[4][2], 1'h0, fu_type_narrow[4][1], fu_type_narrow[4][0], 5'h0};
  assign io_fuType_5 = {25'h0, fu_type_narrow[5][3], fu_type_narrow[5][2], 1'h0, fu_type_narrow[5][1], fu_type_narrow[5][0], 5'h0};
  assign io_fuType_6 = {25'h0, fu_type_narrow[6][3], fu_type_narrow[6][2], 1'h0, fu_type_narrow[6][1], fu_type_narrow[6][0], 5'h0};
  assign io_fuType_7 = {25'h0, fu_type_narrow[7][3], fu_type_narrow[7][2], 1'h0, fu_type_narrow[7][1], fu_type_narrow[7][0], 5'h0};
  assign io_fuType_8 = {25'h0, fu_type_narrow[8][3], fu_type_narrow[8][2], 1'h0, fu_type_narrow[8][1], fu_type_narrow[8][0], 5'h0};
  assign io_fuType_9 = {25'h0, fu_type_narrow[9][3], fu_type_narrow[9][2], 1'h0, fu_type_narrow[9][1], fu_type_narrow[9][0], 5'h0};
  assign io_fuType_10 = {25'h0, fu_type_narrow[10][3], fu_type_narrow[10][2], 1'h0, fu_type_narrow[10][1], fu_type_narrow[10][0], 5'h0};
  assign io_fuType_11 = {25'h0, fu_type_narrow[11][3], fu_type_narrow[11][2], 1'h0, fu_type_narrow[11][1], fu_type_narrow[11][0], 5'h0};
  assign io_fuType_12 = {25'h0, fu_type_narrow[12][3], fu_type_narrow[12][2], 1'h0, fu_type_narrow[12][1], fu_type_narrow[12][0], 5'h0};
  assign io_fuType_13 = {25'h0, fu_type_narrow[13][3], fu_type_narrow[13][2], 1'h0, fu_type_narrow[13][1], fu_type_narrow[13][0], 5'h0};
  assign io_fuType_14 = {25'h0, fu_type_narrow[14][3], fu_type_narrow[14][2], 1'h0, fu_type_narrow[14][1], fu_type_narrow[14][0], 5'h0};
  assign io_fuType_15 = {25'h0, fu_type_narrow[15][3], fu_type_narrow[15][2], 1'h0, fu_type_narrow[15][1], fu_type_narrow[15][0], 5'h0};
  assign io_fuType_16 = {25'h0, fu_type_narrow[16][3], fu_type_narrow[16][2], 1'h0, fu_type_narrow[16][1], fu_type_narrow[16][0], 5'h0};
  assign io_fuType_17 = {25'h0, fu_type_narrow[17][3], fu_type_narrow[17][2], 1'h0, fu_type_narrow[17][1], fu_type_narrow[17][0], 5'h0};
  assign io_fuType_18 = {25'h0, fu_type_narrow[18][3], fu_type_narrow[18][2], 1'h0, fu_type_narrow[18][1], fu_type_narrow[18][0], 5'h0};
  assign io_fuType_19 = {25'h0, fu_type_narrow[19][3], fu_type_narrow[19][2], 1'h0, fu_type_narrow[19][1], fu_type_narrow[19][0], 5'h0};
  assign io_fuType_20 = {25'h0, fu_type_narrow[20][3], fu_type_narrow[20][2], 1'h0, fu_type_narrow[20][1], fu_type_narrow[20][0], 5'h0};
  assign io_fuType_21 = {25'h0, fu_type_narrow[21][3], fu_type_narrow[21][2], 1'h0, fu_type_narrow[21][1], fu_type_narrow[21][0], 5'h0};
  assign io_fuType_22 = {25'h0, fu_type_narrow[22][3], fu_type_narrow[22][2], 1'h0, fu_type_narrow[22][1], fu_type_narrow[22][0], 5'h0};
  assign io_fuType_23 = {25'h0, fu_type_narrow[23][3], fu_type_narrow[23][2], 1'h0, fu_type_narrow[23][1], fu_type_narrow[23][0], 5'h0};

  assign io_dataSources_0_0_value = data_src[0][0];
  assign io_dataSources_0_1_value = data_src[0][1];
  assign io_dataSources_1_0_value = data_src[1][0];
  assign io_dataSources_1_1_value = data_src[1][1];
  assign io_dataSources_2_0_value = data_src[2][0];
  assign io_dataSources_2_1_value = data_src[2][1];
  assign io_dataSources_3_0_value = data_src[3][0];
  assign io_dataSources_3_1_value = data_src[3][1];
  assign io_dataSources_4_0_value = data_src[4][0];
  assign io_dataSources_4_1_value = data_src[4][1];
  assign io_dataSources_5_0_value = data_src[5][0];
  assign io_dataSources_5_1_value = data_src[5][1];
  assign io_dataSources_6_0_value = data_src[6][0];
  assign io_dataSources_6_1_value = data_src[6][1];
  assign io_dataSources_7_0_value = data_src[7][0];
  assign io_dataSources_7_1_value = data_src[7][1];
  assign io_dataSources_8_0_value = data_src[8][0];
  assign io_dataSources_8_1_value = data_src[8][1];
  assign io_dataSources_9_0_value = data_src[9][0];
  assign io_dataSources_9_1_value = data_src[9][1];
  assign io_dataSources_10_0_value = data_src[10][0];
  assign io_dataSources_10_1_value = data_src[10][1];
  assign io_dataSources_11_0_value = data_src[11][0];
  assign io_dataSources_11_1_value = data_src[11][1];
  assign io_dataSources_12_0_value = data_src[12][0];
  assign io_dataSources_12_1_value = data_src[12][1];
  assign io_dataSources_13_0_value = data_src[13][0];
  assign io_dataSources_13_1_value = data_src[13][1];
  assign io_dataSources_14_0_value = data_src[14][0];
  assign io_dataSources_14_1_value = data_src[14][1];
  assign io_dataSources_15_0_value = data_src[15][0];
  assign io_dataSources_15_1_value = data_src[15][1];
  assign io_dataSources_16_0_value = data_src[16][0];
  assign io_dataSources_16_1_value = data_src[16][1];
  assign io_dataSources_17_0_value = data_src[17][0];
  assign io_dataSources_17_1_value = data_src[17][1];
  assign io_dataSources_18_0_value = data_src[18][0];
  assign io_dataSources_18_1_value = data_src[18][1];
  assign io_dataSources_19_0_value = data_src[19][0];
  assign io_dataSources_19_1_value = data_src[19][1];
  assign io_dataSources_20_0_value = data_src[20][0];
  assign io_dataSources_20_1_value = data_src[20][1];
  assign io_dataSources_21_0_value = data_src[21][0];
  assign io_dataSources_21_1_value = data_src[21][1];
  assign io_dataSources_22_0_value = data_src[22][0];
  assign io_dataSources_22_1_value = data_src[22][1];
  assign io_dataSources_23_0_value = data_src[23][0];
  assign io_dataSources_23_1_value = data_src[23][1];

  assign io_exuSources_0_0_value = exu_src[0][0];
  assign io_exuSources_0_1_value = exu_src[0][1];
  assign io_exuSources_1_0_value = exu_src[1][0];
  assign io_exuSources_1_1_value = exu_src[1][1];
  assign io_exuSources_2_0_value = exu_src[2][0];
  assign io_exuSources_2_1_value = exu_src[2][1];
  assign io_exuSources_3_0_value = exu_src[3][0];
  assign io_exuSources_3_1_value = exu_src[3][1];
  assign io_exuSources_4_0_value = exu_src[4][0];
  assign io_exuSources_4_1_value = exu_src[4][1];
  assign io_exuSources_5_0_value = exu_src[5][0];
  assign io_exuSources_5_1_value = exu_src[5][1];
  assign io_exuSources_6_0_value = exu_src[6][0];
  assign io_exuSources_6_1_value = exu_src[6][1];
  assign io_exuSources_7_0_value = exu_src[7][0];
  assign io_exuSources_7_1_value = exu_src[7][1];
  assign io_exuSources_8_0_value = exu_src[8][0];
  assign io_exuSources_8_1_value = exu_src[8][1];
  assign io_exuSources_9_0_value = exu_src[9][0];
  assign io_exuSources_9_1_value = exu_src[9][1];
  assign io_exuSources_10_0_value = exu_src[10][0];
  assign io_exuSources_10_1_value = exu_src[10][1];
  assign io_exuSources_11_0_value = exu_src[11][0];
  assign io_exuSources_11_1_value = exu_src[11][1];
  assign io_exuSources_12_0_value = exu_src[12][0];
  assign io_exuSources_12_1_value = exu_src[12][1];
  assign io_exuSources_13_0_value = exu_src[13][0];
  assign io_exuSources_13_1_value = exu_src[13][1];
  assign io_exuSources_14_0_value = exu_src[14][0];
  assign io_exuSources_14_1_value = exu_src[14][1];
  assign io_exuSources_15_0_value = exu_src[15][0];
  assign io_exuSources_15_1_value = exu_src[15][1];
  assign io_exuSources_16_0_value = exu_src[16][0];
  assign io_exuSources_16_1_value = exu_src[16][1];
  assign io_exuSources_17_0_value = exu_src[17][0];
  assign io_exuSources_17_1_value = exu_src[17][1];
  assign io_exuSources_18_0_value = exu_src[18][0];
  assign io_exuSources_18_1_value = exu_src[18][1];
  assign io_exuSources_19_0_value = exu_src[19][0];
  assign io_exuSources_19_1_value = exu_src[19][1];
  assign io_exuSources_20_0_value = exu_src[20][0];
  assign io_exuSources_20_1_value = exu_src[20][1];
  assign io_exuSources_21_0_value = exu_src[21][0];
  assign io_exuSources_21_1_value = exu_src[21][1];
  assign io_exuSources_22_0_value = exu_src[22][0];
  assign io_exuSources_22_1_value = exu_src[22][1];
  assign io_exuSources_23_0_value = exu_src[23][0];
  assign io_exuSources_23_1_value = exu_src[23][1];

  // io.loadDependency 是**按条目**的 mergedLoadDependency（各源按位或）
  assign io_loadDependency_0_0 = ld_dep_out[0][0];
  assign io_loadDependency_0_1 = ld_dep_out[0][1];
  assign io_loadDependency_0_2 = ld_dep_out[0][2];
  assign io_loadDependency_1_0 = ld_dep_out[1][0];
  assign io_loadDependency_1_1 = ld_dep_out[1][1];
  assign io_loadDependency_1_2 = ld_dep_out[1][2];
  assign io_loadDependency_2_0 = ld_dep_out[2][0];
  assign io_loadDependency_2_1 = ld_dep_out[2][1];
  assign io_loadDependency_2_2 = ld_dep_out[2][2];
  assign io_loadDependency_3_0 = ld_dep_out[3][0];
  assign io_loadDependency_3_1 = ld_dep_out[3][1];
  assign io_loadDependency_3_2 = ld_dep_out[3][2];
  assign io_loadDependency_4_0 = ld_dep_out[4][0];
  assign io_loadDependency_4_1 = ld_dep_out[4][1];
  assign io_loadDependency_4_2 = ld_dep_out[4][2];
  assign io_loadDependency_5_0 = ld_dep_out[5][0];
  assign io_loadDependency_5_1 = ld_dep_out[5][1];
  assign io_loadDependency_5_2 = ld_dep_out[5][2];
  assign io_loadDependency_6_0 = ld_dep_out[6][0];
  assign io_loadDependency_6_1 = ld_dep_out[6][1];
  assign io_loadDependency_6_2 = ld_dep_out[6][2];
  assign io_loadDependency_7_0 = ld_dep_out[7][0];
  assign io_loadDependency_7_1 = ld_dep_out[7][1];
  assign io_loadDependency_7_2 = ld_dep_out[7][2];
  assign io_loadDependency_8_0 = ld_dep_out[8][0];
  assign io_loadDependency_8_1 = ld_dep_out[8][1];
  assign io_loadDependency_8_2 = ld_dep_out[8][2];
  assign io_loadDependency_9_0 = ld_dep_out[9][0];
  assign io_loadDependency_9_1 = ld_dep_out[9][1];
  assign io_loadDependency_9_2 = ld_dep_out[9][2];
  assign io_loadDependency_10_0 = ld_dep_out[10][0];
  assign io_loadDependency_10_1 = ld_dep_out[10][1];
  assign io_loadDependency_10_2 = ld_dep_out[10][2];
  assign io_loadDependency_11_0 = ld_dep_out[11][0];
  assign io_loadDependency_11_1 = ld_dep_out[11][1];
  assign io_loadDependency_11_2 = ld_dep_out[11][2];
  assign io_loadDependency_12_0 = ld_dep_out[12][0];
  assign io_loadDependency_12_1 = ld_dep_out[12][1];
  assign io_loadDependency_12_2 = ld_dep_out[12][2];
  assign io_loadDependency_13_0 = ld_dep_out[13][0];
  assign io_loadDependency_13_1 = ld_dep_out[13][1];
  assign io_loadDependency_13_2 = ld_dep_out[13][2];
  assign io_loadDependency_14_0 = ld_dep_out[14][0];
  assign io_loadDependency_14_1 = ld_dep_out[14][1];
  assign io_loadDependency_14_2 = ld_dep_out[14][2];
  assign io_loadDependency_15_0 = ld_dep_out[15][0];
  assign io_loadDependency_15_1 = ld_dep_out[15][1];
  assign io_loadDependency_15_2 = ld_dep_out[15][2];
  assign io_loadDependency_16_0 = ld_dep_out[16][0];
  assign io_loadDependency_16_1 = ld_dep_out[16][1];
  assign io_loadDependency_16_2 = ld_dep_out[16][2];
  assign io_loadDependency_17_0 = ld_dep_out[17][0];
  assign io_loadDependency_17_1 = ld_dep_out[17][1];
  assign io_loadDependency_17_2 = ld_dep_out[17][2];
  assign io_loadDependency_18_0 = ld_dep_out[18][0];
  assign io_loadDependency_18_1 = ld_dep_out[18][1];
  assign io_loadDependency_18_2 = ld_dep_out[18][2];
  assign io_loadDependency_19_0 = ld_dep_out[19][0];
  assign io_loadDependency_19_1 = ld_dep_out[19][1];
  assign io_loadDependency_19_2 = ld_dep_out[19][2];
  assign io_loadDependency_20_0 = ld_dep_out[20][0];
  assign io_loadDependency_20_1 = ld_dep_out[20][1];
  assign io_loadDependency_20_2 = ld_dep_out[20][2];
  assign io_loadDependency_21_0 = ld_dep_out[21][0];
  assign io_loadDependency_21_1 = ld_dep_out[21][1];
  assign io_loadDependency_21_2 = ld_dep_out[21][2];
  assign io_loadDependency_22_0 = ld_dep_out[22][0];
  assign io_loadDependency_22_1 = ld_dep_out[22][1];
  assign io_loadDependency_22_2 = ld_dep_out[22][2];
  assign io_loadDependency_23_0 = ld_dep_out[23][0];
  assign io_loadDependency_23_1 = ld_dep_out[23][1];
  assign io_loadDependency_23_2 = ld_dep_out[23][2];

  assign io_deqEntry_0_bits_status_robIdx_flag  = deq_rob_flag[0];
  assign io_deqEntry_0_bits_status_robIdx_value = deq_rob_value[0];
  assign io_deqEntry_0_bits_status_fuType_5 = deq_fu_type[0][0];
  assign io_deqEntry_0_bits_status_fuType_6 = deq_fu_type[0][1];
  assign io_deqEntry_0_bits_status_fuType_8 = deq_fu_type[0][2];
  assign io_deqEntry_0_bits_status_fuType_9 = deq_fu_type[0][3];
  assign io_deqEntry_0_bits_status_srcStatus_0_psrc    = deq_psrc[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_0_srcType = deq_src_type[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_0_regCacheIdx = deq_rc_idx[0][0];
  assign io_deqEntry_0_bits_status_srcStatus_1_psrc    = deq_psrc[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_1_srcType = deq_src_type[0][1];
  assign io_deqEntry_0_bits_status_srcStatus_1_regCacheIdx = deq_rc_idx[0][1];
  assign io_deqEntry_0_bits_imm = deq_payload[0][31:0];
  assign io_deqEntry_0_bits_payload_fuOpType = deq_payload[0][58:50];
  assign io_deqEntry_0_bits_payload_rfWen = deq_payload[0][59];
  assign io_deqEntry_0_bits_payload_selImm = deq_payload[0][64:61];
  assign io_deqEntry_0_bits_payload_pdest = deq_payload[0][72:65];
  assign io_deqEntry_0_bits_payload_debugInfo_eliminatedMove = deq_payload[0][73];
  assign io_deqEntry_0_bits_payload_debugInfo_renameTime = deq_payload[0][137:74];
  assign io_deqEntry_0_bits_payload_debugInfo_dispatchTime = deq_payload[0][201:138];
  assign io_deqEntry_0_bits_payload_debugInfo_enqRsTime = deq_payload[0][265:202];
  assign io_deqEntry_0_bits_payload_debugInfo_writebackTime = deq_payload[0][329:266];
  assign io_deqEntry_0_bits_payload_debugInfo_runahead_checkpoint_id = deq_payload[0][393:330];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbFirstReqTime = deq_payload[0][457:394];
  assign io_deqEntry_0_bits_payload_debugInfo_tlbRespTime = deq_payload[0][521:458];
  assign io_deqEntry_0_bits_payload_debug_seqNum_seqNum = deq_payload[0][577:522];
  assign io_deqEntry_0_bits_payload_debug_seqNum_uopIdx = deq_payload[0][585:578];
  assign io_deqEntry_1_bits_status_robIdx_flag  = deq_rob_flag[1];
  assign io_deqEntry_1_bits_status_robIdx_value = deq_rob_value[1];
  assign io_deqEntry_1_bits_status_fuType_5 = deq_fu_type[1][0];
  assign io_deqEntry_1_bits_status_fuType_6 = deq_fu_type[1][1];
  assign io_deqEntry_1_bits_status_fuType_8 = deq_fu_type[1][2];
  assign io_deqEntry_1_bits_status_fuType_9 = deq_fu_type[1][3];
  assign io_deqEntry_1_bits_status_srcStatus_0_psrc    = deq_psrc[1][0];
  assign io_deqEntry_1_bits_status_srcStatus_0_srcType = deq_src_type[1][0];
  assign io_deqEntry_1_bits_status_srcStatus_0_regCacheIdx = deq_rc_idx[1][0];
  assign io_deqEntry_1_bits_status_srcStatus_1_psrc    = deq_psrc[1][1];
  assign io_deqEntry_1_bits_status_srcStatus_1_srcType = deq_src_type[1][1];
  assign io_deqEntry_1_bits_status_srcStatus_1_regCacheIdx = deq_rc_idx[1][1];
  assign io_deqEntry_1_bits_imm = deq_payload[1][31:0];
  assign io_deqEntry_1_bits_payload_preDecodeInfo_valid = deq_payload[1][32];
  assign io_deqEntry_1_bits_payload_preDecodeInfo_isRVC = deq_payload[1][33];
  assign io_deqEntry_1_bits_payload_preDecodeInfo_brType = deq_payload[1][35:34];
  assign io_deqEntry_1_bits_payload_preDecodeInfo_isCall = deq_payload[1][36];
  assign io_deqEntry_1_bits_payload_preDecodeInfo_isRet = deq_payload[1][37];
  assign io_deqEntry_1_bits_payload_pred_taken = deq_payload[1][38];
  assign io_deqEntry_1_bits_payload_ftqPtr_flag = deq_payload[1][39];
  assign io_deqEntry_1_bits_payload_ftqPtr_value = deq_payload[1][45:40];
  assign io_deqEntry_1_bits_payload_ftqOffset = deq_payload[1][49:46];
  assign io_deqEntry_1_bits_payload_fuOpType = deq_payload[1][58:50];
  assign io_deqEntry_1_bits_payload_rfWen = deq_payload[1][59];
  assign io_deqEntry_1_bits_payload_flushPipe = deq_payload[1][60];
  assign io_deqEntry_1_bits_payload_selImm = deq_payload[1][64:61];
  assign io_deqEntry_1_bits_payload_pdest = deq_payload[1][72:65];
  assign io_deqEntry_1_bits_payload_debugInfo_eliminatedMove = deq_payload[1][73];
  assign io_deqEntry_1_bits_payload_debugInfo_renameTime = deq_payload[1][137:74];
  assign io_deqEntry_1_bits_payload_debugInfo_dispatchTime = deq_payload[1][201:138];
  assign io_deqEntry_1_bits_payload_debugInfo_enqRsTime = deq_payload[1][265:202];
  assign io_deqEntry_1_bits_payload_debugInfo_writebackTime = deq_payload[1][329:266];
  assign io_deqEntry_1_bits_payload_debugInfo_runahead_checkpoint_id = deq_payload[1][393:330];
  assign io_deqEntry_1_bits_payload_debugInfo_tlbFirstReqTime = deq_payload[1][457:394];
  assign io_deqEntry_1_bits_payload_debugInfo_tlbRespTime = deq_payload[1][521:458];
  assign io_deqEntry_1_bits_payload_debug_seqNum_seqNum = deq_payload[1][577:522];
  assign io_deqEntry_1_bits_payload_debug_seqNum_uopIdx = deq_payload[1][585:578];
  // END GENERATED(core-inst)

endmodule
