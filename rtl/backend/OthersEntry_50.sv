// OthersEntry_50.sv —— 发射队列单条目（AluBrhJmpI2fVsetriwiVsetriwvfI2v 变体的 comp）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_iq_entries_core.sv 的 `xs_iq_entry`（Entries*/OthersEntry*/EnqEntry*
// 三族共享的参数化单条目核）。本文件不含逻辑分支，只做端口摊平 + 设参数。
//
// 在流水线里的位置：一条等待发射的 uop 占一个条目。条目每拍监听写回(WB)与
// IQ 即时唤醒总线，把命中的源置就绪；「全源就绪 && 未发射 && 未阻塞 && 未冲刷」
// 即 canIssue，上层 Entries 在 canIssue 的条目里按年龄选最老的发射。
// 本条目角色：复杂条目 comp（终端，发射从这里走）
//   golden 里由 EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v 例化 16 份（实例名 othersEntriesComp_*）。
//
// 本变体规模（家族参数取自 verif/ut/Entries_common/entries_gen.py 的
//   Variant("EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v")，那份代码已断言 enq/simp/comp 三个 golden 模块
//   共用同一套唤醒路由与 og0 取消映射；逐模块才会不同的几样在本文件里另量）：
//   源寄存器 2 个，发射口 2 个（deqPortIdxRead 有）
//   WB 唤醒 4 路（rfWen）+ IQ 即时唤醒 7 路
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
//   负载：发射口可见 33 个字段 / 599 位（comp 不产出 transEntry，只存这一份）
//
// ★ HAS_DBG_OUT=1 ★：golden 的 CommonOutBundle 有 7 组 debug/perf 输出
//   （EntryBundles.scala:155-161 / :476-483）。它们在 Entries 那一层被 firtool
//   消掉，所以共享核默认不产出；条目单独成模块时它们是真端口，故这里打开。
//
// 自动生成：verif/ut/OthersEntry_50/gen.py（共享库 verif/ut/OthersEntry_common/othersentry_gen.py）—— 勿手改
// =============================================================================
module OthersEntry_50 (
  input         clock,
  input         reset,
  input         io_commonIn_flush_valid,
  input         io_commonIn_flush_bits_robIdx_flag,
  input  [7:0]  io_commonIn_flush_bits_robIdx_value,
  input         io_commonIn_flush_bits_level,
  input         io_commonIn_enq_valid,
  input         io_commonIn_enq_bits_status_robIdx_flag,
  input  [7:0]  io_commonIn_enq_bits_status_robIdx_value,
  input         io_commonIn_enq_bits_status_fuType_0,
  input         io_commonIn_enq_bits_status_fuType_1,
  input         io_commonIn_enq_bits_status_fuType_2,
  input         io_commonIn_enq_bits_status_fuType_3,
  input         io_commonIn_enq_bits_status_fuType_6,
  input         io_commonIn_enq_bits_status_fuType_28,
  input         io_commonIn_enq_bits_status_fuType_29,
  input  [7:0]  io_commonIn_enq_bits_status_srcStatus_0_psrc,
  input  [3:0]  io_commonIn_enq_bits_status_srcStatus_0_srcType,
  input         io_commonIn_enq_bits_status_srcStatus_0_srcState,
  input  [3:0]  io_commonIn_enq_bits_status_srcStatus_0_dataSources_value,
  input  [1:0]  io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0,
  input  [1:0]  io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1,
  input  [1:0]  io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2,
  input  [2:0]  io_commonIn_enq_bits_status_srcStatus_0_exuSources_value,
  input         io_commonIn_enq_bits_status_srcStatus_0_useRegCache,
  input  [4:0]  io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx,
  input  [7:0]  io_commonIn_enq_bits_status_srcStatus_1_psrc,
  input  [3:0]  io_commonIn_enq_bits_status_srcStatus_1_srcType,
  input         io_commonIn_enq_bits_status_srcStatus_1_srcState,
  input  [3:0]  io_commonIn_enq_bits_status_srcStatus_1_dataSources_value,
  input  [1:0]  io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0,
  input  [1:0]  io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1,
  input  [1:0]  io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2,
  input  [2:0]  io_commonIn_enq_bits_status_srcStatus_1_exuSources_value,
  input         io_commonIn_enq_bits_status_srcStatus_1_useRegCache,
  input  [4:0]  io_commonIn_enq_bits_status_srcStatus_1_regCacheIdx,
  input         io_commonIn_enq_bits_status_blocked,
  input         io_commonIn_enq_bits_status_issued,
  input         io_commonIn_enq_bits_status_firstIssue,
  input  [1:0]  io_commonIn_enq_bits_status_issueTimer,
  input         io_commonIn_enq_bits_status_deqPortIdx,
  input  [31:0] io_commonIn_enq_bits_imm,
  input         io_commonIn_enq_bits_payload_preDecodeInfo_valid,
  input         io_commonIn_enq_bits_payload_preDecodeInfo_isRVC,
  input  [1:0]  io_commonIn_enq_bits_payload_preDecodeInfo_brType,
  input         io_commonIn_enq_bits_payload_preDecodeInfo_isCall,
  input         io_commonIn_enq_bits_payload_preDecodeInfo_isRet,
  input         io_commonIn_enq_bits_payload_pred_taken,
  input         io_commonIn_enq_bits_payload_ftqPtr_flag,
  input  [5:0]  io_commonIn_enq_bits_payload_ftqPtr_value,
  input  [3:0]  io_commonIn_enq_bits_payload_ftqOffset,
  input  [8:0]  io_commonIn_enq_bits_payload_fuOpType,
  input         io_commonIn_enq_bits_payload_rfWen,
  input         io_commonIn_enq_bits_payload_fpWen,
  input         io_commonIn_enq_bits_payload_vecWen,
  input         io_commonIn_enq_bits_payload_v0Wen,
  input         io_commonIn_enq_bits_payload_vlWen,
  input  [3:0]  io_commonIn_enq_bits_payload_selImm,
  input  [1:0]  io_commonIn_enq_bits_payload_fpu_typeTagOut,
  input         io_commonIn_enq_bits_payload_fpu_wflags,
  input  [1:0]  io_commonIn_enq_bits_payload_fpu_typ,
  input  [1:0]  io_commonIn_enq_bits_payload_fpu_fmt,
  input  [2:0]  io_commonIn_enq_bits_payload_fpu_rm,
  input  [7:0]  io_commonIn_enq_bits_payload_pdest,
  input         io_commonIn_enq_bits_payload_debugInfo_eliminatedMove,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_renameTime,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_dispatchTime,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_enqRsTime,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_writebackTime,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime,
  input  [63:0] io_commonIn_enq_bits_payload_debugInfo_tlbRespTime,
  input  [55:0] io_commonIn_enq_bits_payload_debug_seqNum_seqNum,
  input  [7:0]  io_commonIn_enq_bits_payload_debug_seqNum_uopIdx,
  input         io_commonIn_wakeUpFromWB_3_valid,
  input         io_commonIn_wakeUpFromWB_3_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromWB_3_bits_pdest,
  input         io_commonIn_wakeUpFromWB_2_valid,
  input         io_commonIn_wakeUpFromWB_2_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromWB_2_bits_pdest,
  input         io_commonIn_wakeUpFromWB_1_valid,
  input         io_commonIn_wakeUpFromWB_1_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromWB_1_bits_pdest,
  input         io_commonIn_wakeUpFromWB_0_valid,
  input         io_commonIn_wakeUpFromWB_0_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromWB_0_bits_pdest,
  input         io_commonIn_wakeUpFromIQ_6_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_6_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2,
  input  [4:0]  io_commonIn_wakeUpFromIQ_6_bits_rcDest,
  input         io_commonIn_wakeUpFromIQ_5_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_5_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2,
  input  [4:0]  io_commonIn_wakeUpFromIQ_5_bits_rcDest,
  input         io_commonIn_wakeUpFromIQ_4_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_4_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2,
  input  [4:0]  io_commonIn_wakeUpFromIQ_4_bits_rcDest,
  input         io_commonIn_wakeUpFromIQ_3_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_3_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2,
  input  [4:0]  io_commonIn_wakeUpFromIQ_3_bits_rcDest,
  input         io_commonIn_wakeUpFromIQ_2_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_2_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2,
  input  [4:0]  io_commonIn_wakeUpFromIQ_2_bits_rcDest,
  input         io_commonIn_wakeUpFromIQ_1_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_1_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2,
  input         io_commonIn_wakeUpFromIQ_1_bits_is0Lat,
  input  [4:0]  io_commonIn_wakeUpFromIQ_1_bits_rcDest,
  input         io_commonIn_wakeUpFromIQ_0_bits_rfWen,
  input  [7:0]  io_commonIn_wakeUpFromIQ_0_bits_pdest,
  input  [1:0]  io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0,
  input  [1:0]  io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1,
  input  [1:0]  io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2,
  input         io_commonIn_wakeUpFromIQ_0_bits_is0Lat,
  input  [4:0]  io_commonIn_wakeUpFromIQ_0_bits_rcDest,
  input         io_commonIn_og0Cancel_0,
  input         io_commonIn_og0Cancel_2,
  input         io_commonIn_og0Cancel_4,
  input         io_commonIn_og0Cancel_6,
  input         io_commonIn_ldCancel_0_ld2Cancel,
  input         io_commonIn_ldCancel_1_ld2Cancel,
  input         io_commonIn_ldCancel_2_ld2Cancel,
  input         io_commonIn_deqSel,
  input         io_commonIn_deqPortIdxWrite,
  input         io_commonIn_issueResp_valid,
  input  [1:0]  io_commonIn_issueResp_bits_resp,
  output        io_commonOut_valid,
  output        io_commonOut_issued,
  output        io_commonOut_canIssue,
  output [34:0] io_commonOut_fuType,
  output [3:0]  io_commonOut_dataSources_0_value,
  output [3:0]  io_commonOut_dataSources_1_value,
  output [2:0]  io_commonOut_exuSources_0_value,
  output [2:0]  io_commonOut_exuSources_1_value,
  output        io_commonOut_isFirstIssue,
  output        io_commonOut_entry_bits_status_robIdx_flag,
  output [7:0]  io_commonOut_entry_bits_status_robIdx_value,
  output        io_commonOut_entry_bits_status_fuType_0,
  output        io_commonOut_entry_bits_status_fuType_1,
  output        io_commonOut_entry_bits_status_fuType_2,
  output        io_commonOut_entry_bits_status_fuType_3,
  output        io_commonOut_entry_bits_status_fuType_6,
  output        io_commonOut_entry_bits_status_fuType_28,
  output        io_commonOut_entry_bits_status_fuType_29,
  output [7:0]  io_commonOut_entry_bits_status_srcStatus_0_psrc,
  output [3:0]  io_commonOut_entry_bits_status_srcStatus_0_srcType,
  output [1:0]  io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_0,
  output [1:0]  io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_1,
  output [1:0]  io_commonOut_entry_bits_status_srcStatus_0_srcLoadDependency_2,
  output [4:0]  io_commonOut_entry_bits_status_srcStatus_0_regCacheIdx,
  output [7:0]  io_commonOut_entry_bits_status_srcStatus_1_psrc,
  output [3:0]  io_commonOut_entry_bits_status_srcStatus_1_srcType,
  output [1:0]  io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_0,
  output [1:0]  io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_1,
  output [1:0]  io_commonOut_entry_bits_status_srcStatus_1_srcLoadDependency_2,
  output [4:0]  io_commonOut_entry_bits_status_srcStatus_1_regCacheIdx,
  output [31:0] io_commonOut_entry_bits_imm,
  output        io_commonOut_entry_bits_payload_preDecodeInfo_valid,
  output        io_commonOut_entry_bits_payload_preDecodeInfo_isRVC,
  output [1:0]  io_commonOut_entry_bits_payload_preDecodeInfo_brType,
  output        io_commonOut_entry_bits_payload_preDecodeInfo_isCall,
  output        io_commonOut_entry_bits_payload_preDecodeInfo_isRet,
  output        io_commonOut_entry_bits_payload_pred_taken,
  output        io_commonOut_entry_bits_payload_ftqPtr_flag,
  output [5:0]  io_commonOut_entry_bits_payload_ftqPtr_value,
  output [3:0]  io_commonOut_entry_bits_payload_ftqOffset,
  output [8:0]  io_commonOut_entry_bits_payload_fuOpType,
  output        io_commonOut_entry_bits_payload_rfWen,
  output        io_commonOut_entry_bits_payload_fpWen,
  output        io_commonOut_entry_bits_payload_vecWen,
  output        io_commonOut_entry_bits_payload_v0Wen,
  output        io_commonOut_entry_bits_payload_vlWen,
  output [3:0]  io_commonOut_entry_bits_payload_selImm,
  output [1:0]  io_commonOut_entry_bits_payload_fpu_typeTagOut,
  output        io_commonOut_entry_bits_payload_fpu_wflags,
  output [1:0]  io_commonOut_entry_bits_payload_fpu_typ,
  output [1:0]  io_commonOut_entry_bits_payload_fpu_fmt,
  output [2:0]  io_commonOut_entry_bits_payload_fpu_rm,
  output [7:0]  io_commonOut_entry_bits_payload_pdest,
  output        io_commonOut_entry_bits_payload_debugInfo_eliminatedMove,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_renameTime,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_dispatchTime,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_enqRsTime,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_writebackTime,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_runahead_checkpoint_id,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_tlbFirstReqTime,
  output [63:0] io_commonOut_entry_bits_payload_debugInfo_tlbRespTime,
  output [55:0] io_commonOut_entry_bits_payload_debug_seqNum_seqNum,
  output [7:0]  io_commonOut_entry_bits_payload_debug_seqNum_uopIdx,
  output        io_commonOut_cancelBypass,
  output        io_commonOut_deqPortIdxRead,
  output [1:0]  io_commonOut_issueTimerRead,
  output        io_commonOut_entryInValid,
  output        io_commonOut_entryOutDeqValid,
  output        io_commonOut_perfLdCancel_0,
  output        io_commonOut_perfLdCancel_1,
  output        io_commonOut_perfOg0Cancel_0,
  output        io_commonOut_perfOg0Cancel_1,
  output        io_commonOut_perfWakeupByWB_0,
  output        io_commonOut_perfWakeupByWB_1,
  output        io_commonOut_perfWakeupByIQ_0_0,
  output        io_commonOut_perfWakeupByIQ_0_1,
  output        io_commonOut_perfWakeupByIQ_0_2,
  output        io_commonOut_perfWakeupByIQ_0_3,
  output        io_commonOut_perfWakeupByIQ_0_4,
  output        io_commonOut_perfWakeupByIQ_0_5,
  output        io_commonOut_perfWakeupByIQ_0_6,
  output        io_commonOut_perfWakeupByIQ_1_0,
  output        io_commonOut_perfWakeupByIQ_1_1,
  output        io_commonOut_perfWakeupByIQ_1_2,
  output        io_commonOut_perfWakeupByIQ_1_3,
  output        io_commonOut_perfWakeupByIQ_1_4,
  output        io_commonOut_perfWakeupByIQ_1_5,
  output        io_commonOut_perfWakeupByIQ_1_6
);

  // BEGIN GENERATED(core-inst)
  // 入队负载按 Variant 的偏移表拼成一根 599 位向量（只存发射口可见那份）
  logic [1361:0] enq_payload;
  assign enq_payload = {5'h0, 1'h0, 35'h0, 1'h0, 1'h0, 6'h0, 1'h0, 7'h0, 1'h0, 5'h0, 1'h0, 1'h0, 8'h0, 1'h0, 1'h0, 64'h0, 64'h0, 1'h0, 1'h0, 1'h0, 4'h0, 4'h0, 1'h0, 1'h0, 3'h0, 8'h0, 1'h0, 5'h0, 5'h0, 1'h0, 1'h0, 8'h0, 8'h0, 8'h0, 8'h0, 8'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 2'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 3'h0, 7'h0, 7'h0, 1'h0, 1'h0, 1'h0, 7'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 2'h0, 3'h0, 8'h0, 128'h0, 1'h0, 7'h0, 2'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 3'h0, 8'h0, 1'h0, 3'h0, 2'h0, 1'h0, 1'h0, 1'h0, 3'h0, 2'h0, 1'h0, 1'h0, 1'h0, 32'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 35'h0, 6'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 1'h0, 1'h0, 4'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 1'h0, 10'h0, 50'h0, 32'h0, io_commonIn_enq_bits_payload_debug_seqNum_uopIdx, io_commonIn_enq_bits_payload_debug_seqNum_seqNum, io_commonIn_enq_bits_payload_debugInfo_tlbRespTime, io_commonIn_enq_bits_payload_debugInfo_tlbFirstReqTime, io_commonIn_enq_bits_payload_debugInfo_runahead_checkpoint_id, io_commonIn_enq_bits_payload_debugInfo_writebackTime, io_commonIn_enq_bits_payload_debugInfo_enqRsTime, io_commonIn_enq_bits_payload_debugInfo_dispatchTime, io_commonIn_enq_bits_payload_debugInfo_renameTime, io_commonIn_enq_bits_payload_debugInfo_eliminatedMove, io_commonIn_enq_bits_payload_pdest, io_commonIn_enq_bits_payload_fpu_rm, io_commonIn_enq_bits_payload_fpu_fmt, io_commonIn_enq_bits_payload_fpu_typ, io_commonIn_enq_bits_payload_fpu_wflags, io_commonIn_enq_bits_payload_fpu_typeTagOut, io_commonIn_enq_bits_payload_selImm, io_commonIn_enq_bits_payload_vlWen, io_commonIn_enq_bits_payload_v0Wen, io_commonIn_enq_bits_payload_vecWen, io_commonIn_enq_bits_payload_fpWen, io_commonIn_enq_bits_payload_rfWen, io_commonIn_enq_bits_payload_fuOpType, io_commonIn_enq_bits_payload_ftqOffset, io_commonIn_enq_bits_payload_ftqPtr_value, io_commonIn_enq_bits_payload_ftqPtr_flag, io_commonIn_enq_bits_payload_pred_taken, io_commonIn_enq_bits_payload_preDecodeInfo_isRet, io_commonIn_enq_bits_payload_preDecodeInfo_isCall, io_commonIn_enq_bits_payload_preDecodeInfo_brType, io_commonIn_enq_bits_payload_preDecodeInfo_isRVC, io_commonIn_enq_bits_payload_preDecodeInfo_valid, io_commonIn_enq_bits_imm};

  logic [6:0] fu_type_narrow;
  logic [1:0][3:0] data_src;
  logic [1:0][2:0] exu_src;
  logic [598:0] ety_payload;
  logic [1:0][7:0] ety_psrc;
  logic [1:0][3:0] ety_src_type;
  logic [1:0][2:0][1:0] ety_ld_dep;
  logic [1:0][4:0] ety_rc_idx;
  // comp 不产出 transEntry：核的这组出口接悬空线（golden 同样没有这些端口）
  logic [1361:0] unused_trans_payload;
  logic [1:0][7:0] unused_trans_psrc;
  logic [1:0][3:0] unused_trans_src_type, unused_trans_data_src;
  logic [1:0] unused_trans_src_state, unused_trans_use_rc;
  logic [1:0][2:0][1:0] unused_trans_ld_dep;
  logic [1:0][2:0] unused_trans_exu_src;
  logic [1:0][4:0] unused_trans_rc_idx;
  logic [6:0] unused_trans_fu_type;
  logic unused_trans_valid, unused_trans_rob_flag, unused_trans_blocked;
  logic unused_trans_issued, unused_trans_first_issue, unused_trans_deq_port;
  logic [7:0] unused_trans_rob_value;
  logic [1:0] unused_trans_issue_timer;
  logic unused_enq_ready, unused_trans_out_valid;
  logic unused_dbg_trans_valid;

  xs_iq_entry #(
    .IS_ENQ(0), .IS_TRANS(0), .IS_COMP(1),
    .NUM_DEQ_PORTS(2),
    .NUM_REGSRC(2), .NUM_WK_WB(4), .NUM_FU_BIT(7),
    .ROB_W(8), .PSRC_W(8), .PDEST_W(8),
    .PL_DEQ_W(599), .PL_TRANS_W(1362),
    .HAS_LD_DEP(1), .HAS_LD1_CANCEL(0),
    .LD_PIPES(3), .LD_DEP_W(2),
    .NUM_WK_IQ(7), .EXU_W(3),
    .IQ_SRC_MASK({7'b1111111, 7'b1111111}),
    .IQ_WEN_PRESENT(5'b00001),
    .IQD_WEN_PRESENT(5'b00000),
    .IQ_IS_LD_PIPE({3'b100, 3'b010, 3'b001, 3'b000, 3'b000, 3'b000, 3'b000}),
    .HAS_REG_CACHE(1), .RC_IDX_W(5),
    .IQ_WRITE_RC(7'b1111111), .RC_TYPE_BIT(0),
    .SRC_WB_MASK({4'b1111, 4'b1111}),
    .SRC_MATCH_KIND({2'd0, 2'd0}),
    .WB_WEN_PRESENT(5'b00001),
    .WBD_WEN_PRESENT(5'b00000),
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
    .enq_fu_type({io_commonIn_enq_bits_status_fuType_29, io_commonIn_enq_bits_status_fuType_28, io_commonIn_enq_bits_status_fuType_6, io_commonIn_enq_bits_status_fuType_3, io_commonIn_enq_bits_status_fuType_2, io_commonIn_enq_bits_status_fuType_1, io_commonIn_enq_bits_status_fuType_0}),
    .enq_psrc({io_commonIn_enq_bits_status_srcStatus_1_psrc, io_commonIn_enq_bits_status_srcStatus_0_psrc}),
    .enq_src_type({io_commonIn_enq_bits_status_srcStatus_1_srcType, io_commonIn_enq_bits_status_srcStatus_0_srcType}),
    .enq_src_state({io_commonIn_enq_bits_status_srcStatus_1_srcState, io_commonIn_enq_bits_status_srcStatus_0_srcState}),
    .enq_data_src({io_commonIn_enq_bits_status_srcStatus_1_dataSources_value, io_commonIn_enq_bits_status_srcStatus_0_dataSources_value}),
    .enq_blocked(io_commonIn_enq_bits_status_blocked),
    .enq_issued(io_commonIn_enq_bits_status_issued),
    .enq_first_issue(io_commonIn_enq_bits_status_firstIssue),
    .enq_issue_timer(io_commonIn_enq_bits_status_issueTimer),
    .enq_deq_port_idx(io_commonIn_enq_bits_status_deqPortIdx),
    .enq_payload(enq_payload),
    .enq_ld_dep({io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_1_srcLoadDependency_0, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_2, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_1, io_commonIn_enq_bits_status_srcStatus_0_srcLoadDependency_0}),
    .enq_exu_src({io_commonIn_enq_bits_status_srcStatus_1_exuSources_value, io_commonIn_enq_bits_status_srcStatus_0_exuSources_value}),
    .enq_use_rc({io_commonIn_enq_bits_status_srcStatus_1_useRegCache, io_commonIn_enq_bits_status_srcStatus_0_useRegCache}),
    .enq_rc_idx({io_commonIn_enq_bits_status_srcStatus_1_regCacheIdx, io_commonIn_enq_bits_status_srcStatus_0_regCacheIdx}),
    .wk_valid({io_commonIn_wakeUpFromWB_3_valid, io_commonIn_wakeUpFromWB_2_valid, io_commonIn_wakeUpFromWB_1_valid, io_commonIn_wakeUpFromWB_0_valid}),
    .wk_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromWB_0_bits_rfWen}}),
    .wk_pdest({io_commonIn_wakeUpFromWB_3_bits_pdest, io_commonIn_wakeUpFromWB_2_bits_pdest, io_commonIn_wakeUpFromWB_1_bits_pdest, io_commonIn_wakeUpFromWB_0_bits_pdest}),
    // ★ 入队延迟窗口只有 EnqEntry 有（IS_ENQ=1）；OthersEntry 的 golden
    //   根本没有 wakeUpFromWBDelayed / enqDelay 这组端口，故整组钉 0
    .wkd_valid('0), .wkd_wen('0), .wkd_pdest('0),
    .iq_wen({{1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_6_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_5_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_4_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_3_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_2_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_1_bits_rfWen}, {1'b0, 1'b0, 1'b0, 1'b0, io_commonIn_wakeUpFromIQ_0_bits_rfWen}}),
    .iq_pdest({io_commonIn_wakeUpFromIQ_6_bits_pdest, io_commonIn_wakeUpFromIQ_5_bits_pdest, io_commonIn_wakeUpFromIQ_4_bits_pdest, io_commonIn_wakeUpFromIQ_3_bits_pdest, io_commonIn_wakeUpFromIQ_2_bits_pdest, io_commonIn_wakeUpFromIQ_1_bits_pdest, io_commonIn_wakeUpFromIQ_0_bits_pdest}),
    .iq_ld_dep({io_commonIn_wakeUpFromIQ_6_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_6_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_6_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_5_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_5_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_5_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_4_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_4_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_4_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_3_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_3_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_3_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_2_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_2_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_2_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_1_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_1_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_1_bits_loadDependency_0, io_commonIn_wakeUpFromIQ_0_bits_loadDependency_2, io_commonIn_wakeUpFromIQ_0_bits_loadDependency_1, io_commonIn_wakeUpFromIQ_0_bits_loadDependency_0}),
    .iq_rc_dest({io_commonIn_wakeUpFromIQ_6_bits_rcDest, io_commonIn_wakeUpFromIQ_5_bits_rcDest, io_commonIn_wakeUpFromIQ_4_bits_rcDest, io_commonIn_wakeUpFromIQ_3_bits_rcDest, io_commonIn_wakeUpFromIQ_2_bits_rcDest, io_commonIn_wakeUpFromIQ_1_bits_rcDest, io_commonIn_wakeUpFromIQ_0_bits_rcDest}),
    // iq_cancel[w] = og0Cancel[第 w 路的全局 exu 下标] & is0Lat[w]；
    // og0Cancel 的下标是稀疏的，is0Lat 有的路被 firtool 折成常量。
    .iq_cancel({1'b0, 1'b0, 1'b0, io_commonIn_og0Cancel_6, io_commonIn_og0Cancel_4, (io_commonIn_og0Cancel_2 & io_commonIn_wakeUpFromIQ_1_bits_is0Lat), (io_commonIn_og0Cancel_0 & io_commonIn_wakeUpFromIQ_0_bits_is0Lat)}),
    .iqd_wen('0), .iqd_pdest('0), .iqd_ld_dep('0), .iqd_rc_dest('0),
    .iqd_cancel('0),
    .ld1_cancel('0),
    .ld2_cancel({io_commonIn_ldCancel_2_ld2Cancel, io_commonIn_ldCancel_1_ld2Cancel, io_commonIn_ldCancel_0_ld2Cancel}),
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
    .trans_sel(1'b0),
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
    .o_trans_valid(unused_trans_out_valid),
    .o_trans_rob_flag(unused_trans_rob_flag),
    .o_trans_rob_value(unused_trans_rob_value),
    .o_trans_fu_type(unused_trans_fu_type),
    .o_trans_psrc(unused_trans_psrc),
    .o_trans_src_type(unused_trans_src_type),
    .o_trans_src_state(unused_trans_src_state),
    .o_trans_data_src(unused_trans_data_src),
    .o_trans_payload(unused_trans_payload),
    .o_trans_ld_dep(unused_trans_ld_dep),
    .o_trans_exu_src(unused_trans_exu_src),
    .o_trans_use_rc(unused_trans_use_rc),
    .o_trans_rc_idx(unused_trans_rc_idx),
    .o_trans_blocked(unused_trans_blocked),
    .o_trans_issued(unused_trans_issued),
    .o_trans_first_issue(unused_trans_first_issue),
    .o_trans_issue_timer(unused_trans_issue_timer),
    .o_trans_deq_port_idx(unused_trans_deq_port),
    // golden 的 7 组 debug/perf 输出（EntryBundles.scala:476-483）
    .o_dbg_entry_in_valid(io_commonOut_entryInValid),
    .o_dbg_entry_out_deq_valid(io_commonOut_entryOutDeqValid),
    .o_dbg_entry_out_trans_valid(unused_dbg_trans_valid),
    .o_dbg_perf_ld_cancel({io_commonOut_perfLdCancel_1, io_commonOut_perfLdCancel_0}),
    .o_dbg_perf_og0_cancel({io_commonOut_perfOg0Cancel_1, io_commonOut_perfOg0Cancel_0}),
    .o_dbg_perf_wakeup_by_wb({io_commonOut_perfWakeupByWB_1, io_commonOut_perfWakeupByWB_0}),
    .o_dbg_perf_wakeup_by_iq({io_commonOut_perfWakeupByIQ_1_6, io_commonOut_perfWakeupByIQ_1_5, io_commonOut_perfWakeupByIQ_1_4, io_commonOut_perfWakeupByIQ_1_3, io_commonOut_perfWakeupByIQ_1_2, io_commonOut_perfWakeupByIQ_1_1, io_commonOut_perfWakeupByIQ_1_0, io_commonOut_perfWakeupByIQ_0_6, io_commonOut_perfWakeupByIQ_0_5, io_commonOut_perfWakeupByIQ_0_4, io_commonOut_perfWakeupByIQ_0_3, io_commonOut_perfWakeupByIQ_0_2, io_commonOut_perfWakeupByIQ_0_1, io_commonOut_perfWakeupByIQ_0_0})
  );

  // fuType 出口：核只存本变体保留的 7 位，这里放回 35 位 one-hot 的原位置
  assign io_commonOut_fuType = {5'h0, fu_type_narrow[6], fu_type_narrow[5], 21'h0, fu_type_narrow[4], 2'h0, fu_type_narrow[3], fu_type_narrow[2], fu_type_narrow[1], fu_type_narrow[0]};

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
  // END GENERATED(core-inst)

endmodule
