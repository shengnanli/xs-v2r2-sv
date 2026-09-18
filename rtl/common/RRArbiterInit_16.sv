// =============================================================================
// RRArbiterInit_16.sv —— 轮转仲裁器家族薄 wrapper：L2 SinkC 4 路 TaskBundle（94 字段）仲裁，payload 家族最宽
//
// 本变体规模：仲裁宽度 N=4，payload 打平 W=383 位（94 个字段），chosen/lastGrant 2 位。
//   端口面：in_ready 输出有、out_ready 输入有、io_chosen 输出无。
//   例化者：SinkC.sv。
//
// 本文件只做参数与端口对位；仲裁逻辑核在 rtl/common/RRArbiterInit.sv
// （模块 xs_RRArbiterInit_core），核体全家族共一份。本文件由
// verif/ut/RRArbiterInitVariants/gen.py 生成，勿手改。
//
// 设计源：rocket-chip util/Arbiters.scala (class LockingRRArbiter)
// golden 对照：G1-canonical/golden-rtl/RRArbiterInit_16.sv
// =============================================================================
package rrarbiterinit_16_pkg;
  // payload 字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  // 打平成 383 位送进仲裁核，核只按 chosen 选一路，不看字段结构。
  // 注：bits_alias 去掉 bits_ 前缀后撞上 SV 保留字，加 _f 后缀。
  typedef struct packed {
    logic [2:0]  channel;
    logic [2:0]  txChannel;
    logic [8:0]  set;
    logic [30:0] tag;
    logic [5:0]  off;
    logic [1:0]  alias_f;
    logic [43:0] vaddr;
    logic        isKeyword;
    logic [3:0]  opcode;
    logic [2:0]  param;
    logic [2:0]  size;
    logic [6:0]  sourceId;
    logic [1:0]  bufIdx;
    logic        needProbeAckData;
    logic        denied;
    logic        corrupt;
    logic        mshrTask;
    logic [7:0]  mshrId;
    logic        aliasTask;
    logic        useProbeData;
    logic        mshrRetry;
    logic        readProbeDataDown;
    logic        fromL2pft;
    logic        needHint;
    logic        dirty;
    logic [2:0]  way;
    logic        meta_dirty;
    logic [1:0]  meta_state;
    logic        meta_clients;
    logic [1:0]  meta_alias;
    logic        meta_prefetch;
    logic [2:0]  meta_prefetchSrc;
    logic        meta_accessed;
    logic        meta_tagErr;
    logic        meta_dataErr;
    logic        metaWen;
    logic        tagWen;
    logic        dsWen;
    logic [7:0]  wayMask;
    logic        replTask;
    logic        cmoTask;
    logic        cmoAll;
    logic [4:0]  reqSource;
    logic        mergeA;
    logic [5:0]  aMergeTask_off;
    logic [1:0]  aMergeTask_alias;
    logic [43:0] aMergeTask_vaddr;
    logic        aMergeTask_isKeyword;
    logic [2:0]  aMergeTask_opcode;
    logic [2:0]  aMergeTask_param;
    logic [6:0]  aMergeTask_sourceId;
    logic        aMergeTask_meta_dirty;
    logic [1:0]  aMergeTask_meta_state;
    logic        aMergeTask_meta_clients;
    logic [1:0]  aMergeTask_meta_alias;
    logic        aMergeTask_meta_prefetch;
    logic [2:0]  aMergeTask_meta_prefetchSrc;
    logic        aMergeTask_meta_accessed;
    logic        aMergeTask_meta_tagErr;
    logic        aMergeTask_meta_dataErr;
    logic        snpHitRelease;
    logic        snpHitReleaseToInval;
    logic        snpHitReleaseToClean;
    logic        snpHitReleaseWithData;
    logic [7:0]  snpHitReleaseIdx;
    logic        snpHitReleaseMeta_dirty;
    logic [1:0]  snpHitReleaseMeta_state;
    logic        snpHitReleaseMeta_clients;
    logic [1:0]  snpHitReleaseMeta_alias;
    logic        snpHitReleaseMeta_prefetch;
    logic [2:0]  snpHitReleaseMeta_prefetchSrc;
    logic        snpHitReleaseMeta_accessed;
    logic        snpHitReleaseMeta_tagErr;
    logic        snpHitReleaseMeta_dataErr;
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [10:0] homeNID;
    logic [11:0] dbID;
    logic [10:0] fwdNID;
    logic [11:0] fwdTxnID;
    logic [6:0]  chiOpcode;
    logic [2:0]  resp;
    logic [2:0]  fwdState;
    logic [3:0]  pCrdType;
    logic        retToSrc;
    logic        likelyshared;
    logic        expCompAck;
    logic        allowRetry;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        traceTag;
  } payload_t;
endpackage

module RRArbiterInit_16 import rrarbiterinit_16_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [2:0]  io_in_0_bits_channel,
  input  [2:0]  io_in_0_bits_txChannel,
  input  [8:0]  io_in_0_bits_set,
  input  [30:0] io_in_0_bits_tag,
  input  [5:0]  io_in_0_bits_off,
  input  [1:0]  io_in_0_bits_alias,
  input  [43:0] io_in_0_bits_vaddr,
  input         io_in_0_bits_isKeyword,
  input  [3:0]  io_in_0_bits_opcode,
  input  [2:0]  io_in_0_bits_param,
  input  [2:0]  io_in_0_bits_size,
  input  [6:0]  io_in_0_bits_sourceId,
  input  [1:0]  io_in_0_bits_bufIdx,
  input         io_in_0_bits_needProbeAckData,
  input         io_in_0_bits_denied,
  input         io_in_0_bits_corrupt,
  input         io_in_0_bits_mshrTask,
  input  [7:0]  io_in_0_bits_mshrId,
  input         io_in_0_bits_aliasTask,
  input         io_in_0_bits_useProbeData,
  input         io_in_0_bits_mshrRetry,
  input         io_in_0_bits_readProbeDataDown,
  input         io_in_0_bits_fromL2pft,
  input         io_in_0_bits_needHint,
  input         io_in_0_bits_dirty,
  input  [2:0]  io_in_0_bits_way,
  input         io_in_0_bits_meta_dirty,
  input  [1:0]  io_in_0_bits_meta_state,
  input         io_in_0_bits_meta_clients,
  input  [1:0]  io_in_0_bits_meta_alias,
  input         io_in_0_bits_meta_prefetch,
  input  [2:0]  io_in_0_bits_meta_prefetchSrc,
  input         io_in_0_bits_meta_accessed,
  input         io_in_0_bits_meta_tagErr,
  input         io_in_0_bits_meta_dataErr,
  input         io_in_0_bits_metaWen,
  input         io_in_0_bits_tagWen,
  input         io_in_0_bits_dsWen,
  input  [7:0]  io_in_0_bits_wayMask,
  input         io_in_0_bits_replTask,
  input         io_in_0_bits_cmoTask,
  input         io_in_0_bits_cmoAll,
  input  [4:0]  io_in_0_bits_reqSource,
  input         io_in_0_bits_mergeA,
  input  [5:0]  io_in_0_bits_aMergeTask_off,
  input  [1:0]  io_in_0_bits_aMergeTask_alias,
  input  [43:0] io_in_0_bits_aMergeTask_vaddr,
  input         io_in_0_bits_aMergeTask_isKeyword,
  input  [2:0]  io_in_0_bits_aMergeTask_opcode,
  input  [2:0]  io_in_0_bits_aMergeTask_param,
  input  [6:0]  io_in_0_bits_aMergeTask_sourceId,
  input         io_in_0_bits_aMergeTask_meta_dirty,
  input  [1:0]  io_in_0_bits_aMergeTask_meta_state,
  input         io_in_0_bits_aMergeTask_meta_clients,
  input  [1:0]  io_in_0_bits_aMergeTask_meta_alias,
  input         io_in_0_bits_aMergeTask_meta_prefetch,
  input  [2:0]  io_in_0_bits_aMergeTask_meta_prefetchSrc,
  input         io_in_0_bits_aMergeTask_meta_accessed,
  input         io_in_0_bits_aMergeTask_meta_tagErr,
  input         io_in_0_bits_aMergeTask_meta_dataErr,
  input         io_in_0_bits_snpHitRelease,
  input         io_in_0_bits_snpHitReleaseToInval,
  input         io_in_0_bits_snpHitReleaseToClean,
  input         io_in_0_bits_snpHitReleaseWithData,
  input  [7:0]  io_in_0_bits_snpHitReleaseIdx,
  input         io_in_0_bits_snpHitReleaseMeta_dirty,
  input  [1:0]  io_in_0_bits_snpHitReleaseMeta_state,
  input         io_in_0_bits_snpHitReleaseMeta_clients,
  input  [1:0]  io_in_0_bits_snpHitReleaseMeta_alias,
  input         io_in_0_bits_snpHitReleaseMeta_prefetch,
  input  [2:0]  io_in_0_bits_snpHitReleaseMeta_prefetchSrc,
  input         io_in_0_bits_snpHitReleaseMeta_accessed,
  input         io_in_0_bits_snpHitReleaseMeta_tagErr,
  input         io_in_0_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_in_0_bits_tgtID,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_homeNID,
  input  [11:0] io_in_0_bits_dbID,
  input  [10:0] io_in_0_bits_fwdNID,
  input  [11:0] io_in_0_bits_fwdTxnID,
  input  [6:0]  io_in_0_bits_chiOpcode,
  input  [2:0]  io_in_0_bits_resp,
  input  [2:0]  io_in_0_bits_fwdState,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_retToSrc,
  input         io_in_0_bits_likelyshared,
  input         io_in_0_bits_expCompAck,
  input         io_in_0_bits_allowRetry,
  input         io_in_0_bits_memAttr_allocate,
  input         io_in_0_bits_memAttr_cacheable,
  input         io_in_0_bits_memAttr_device,
  input         io_in_0_bits_memAttr_ewa,
  input         io_in_0_bits_traceTag,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [2:0]  io_in_1_bits_channel,
  input  [2:0]  io_in_1_bits_txChannel,
  input  [8:0]  io_in_1_bits_set,
  input  [30:0] io_in_1_bits_tag,
  input  [5:0]  io_in_1_bits_off,
  input  [1:0]  io_in_1_bits_alias,
  input  [43:0] io_in_1_bits_vaddr,
  input         io_in_1_bits_isKeyword,
  input  [3:0]  io_in_1_bits_opcode,
  input  [2:0]  io_in_1_bits_param,
  input  [2:0]  io_in_1_bits_size,
  input  [6:0]  io_in_1_bits_sourceId,
  input  [1:0]  io_in_1_bits_bufIdx,
  input         io_in_1_bits_needProbeAckData,
  input         io_in_1_bits_denied,
  input         io_in_1_bits_corrupt,
  input         io_in_1_bits_mshrTask,
  input  [7:0]  io_in_1_bits_mshrId,
  input         io_in_1_bits_aliasTask,
  input         io_in_1_bits_useProbeData,
  input         io_in_1_bits_mshrRetry,
  input         io_in_1_bits_readProbeDataDown,
  input         io_in_1_bits_fromL2pft,
  input         io_in_1_bits_needHint,
  input         io_in_1_bits_dirty,
  input  [2:0]  io_in_1_bits_way,
  input         io_in_1_bits_meta_dirty,
  input  [1:0]  io_in_1_bits_meta_state,
  input         io_in_1_bits_meta_clients,
  input  [1:0]  io_in_1_bits_meta_alias,
  input         io_in_1_bits_meta_prefetch,
  input  [2:0]  io_in_1_bits_meta_prefetchSrc,
  input         io_in_1_bits_meta_accessed,
  input         io_in_1_bits_meta_tagErr,
  input         io_in_1_bits_meta_dataErr,
  input         io_in_1_bits_metaWen,
  input         io_in_1_bits_tagWen,
  input         io_in_1_bits_dsWen,
  input  [7:0]  io_in_1_bits_wayMask,
  input         io_in_1_bits_replTask,
  input         io_in_1_bits_cmoTask,
  input         io_in_1_bits_cmoAll,
  input  [4:0]  io_in_1_bits_reqSource,
  input         io_in_1_bits_mergeA,
  input  [5:0]  io_in_1_bits_aMergeTask_off,
  input  [1:0]  io_in_1_bits_aMergeTask_alias,
  input  [43:0] io_in_1_bits_aMergeTask_vaddr,
  input         io_in_1_bits_aMergeTask_isKeyword,
  input  [2:0]  io_in_1_bits_aMergeTask_opcode,
  input  [2:0]  io_in_1_bits_aMergeTask_param,
  input  [6:0]  io_in_1_bits_aMergeTask_sourceId,
  input         io_in_1_bits_aMergeTask_meta_dirty,
  input  [1:0]  io_in_1_bits_aMergeTask_meta_state,
  input         io_in_1_bits_aMergeTask_meta_clients,
  input  [1:0]  io_in_1_bits_aMergeTask_meta_alias,
  input         io_in_1_bits_aMergeTask_meta_prefetch,
  input  [2:0]  io_in_1_bits_aMergeTask_meta_prefetchSrc,
  input         io_in_1_bits_aMergeTask_meta_accessed,
  input         io_in_1_bits_aMergeTask_meta_tagErr,
  input         io_in_1_bits_aMergeTask_meta_dataErr,
  input         io_in_1_bits_snpHitRelease,
  input         io_in_1_bits_snpHitReleaseToInval,
  input         io_in_1_bits_snpHitReleaseToClean,
  input         io_in_1_bits_snpHitReleaseWithData,
  input  [7:0]  io_in_1_bits_snpHitReleaseIdx,
  input         io_in_1_bits_snpHitReleaseMeta_dirty,
  input  [1:0]  io_in_1_bits_snpHitReleaseMeta_state,
  input         io_in_1_bits_snpHitReleaseMeta_clients,
  input  [1:0]  io_in_1_bits_snpHitReleaseMeta_alias,
  input         io_in_1_bits_snpHitReleaseMeta_prefetch,
  input  [2:0]  io_in_1_bits_snpHitReleaseMeta_prefetchSrc,
  input         io_in_1_bits_snpHitReleaseMeta_accessed,
  input         io_in_1_bits_snpHitReleaseMeta_tagErr,
  input         io_in_1_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_in_1_bits_tgtID,
  input  [10:0] io_in_1_bits_srcID,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_homeNID,
  input  [11:0] io_in_1_bits_dbID,
  input  [10:0] io_in_1_bits_fwdNID,
  input  [11:0] io_in_1_bits_fwdTxnID,
  input  [6:0]  io_in_1_bits_chiOpcode,
  input  [2:0]  io_in_1_bits_resp,
  input  [2:0]  io_in_1_bits_fwdState,
  input  [3:0]  io_in_1_bits_pCrdType,
  input         io_in_1_bits_retToSrc,
  input         io_in_1_bits_likelyshared,
  input         io_in_1_bits_expCompAck,
  input         io_in_1_bits_allowRetry,
  input         io_in_1_bits_memAttr_allocate,
  input         io_in_1_bits_memAttr_cacheable,
  input         io_in_1_bits_memAttr_device,
  input         io_in_1_bits_memAttr_ewa,
  input         io_in_1_bits_traceTag,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [2:0]  io_in_2_bits_channel,
  input  [2:0]  io_in_2_bits_txChannel,
  input  [8:0]  io_in_2_bits_set,
  input  [30:0] io_in_2_bits_tag,
  input  [5:0]  io_in_2_bits_off,
  input  [1:0]  io_in_2_bits_alias,
  input  [43:0] io_in_2_bits_vaddr,
  input         io_in_2_bits_isKeyword,
  input  [3:0]  io_in_2_bits_opcode,
  input  [2:0]  io_in_2_bits_param,
  input  [2:0]  io_in_2_bits_size,
  input  [6:0]  io_in_2_bits_sourceId,
  input  [1:0]  io_in_2_bits_bufIdx,
  input         io_in_2_bits_needProbeAckData,
  input         io_in_2_bits_denied,
  input         io_in_2_bits_corrupt,
  input         io_in_2_bits_mshrTask,
  input  [7:0]  io_in_2_bits_mshrId,
  input         io_in_2_bits_aliasTask,
  input         io_in_2_bits_useProbeData,
  input         io_in_2_bits_mshrRetry,
  input         io_in_2_bits_readProbeDataDown,
  input         io_in_2_bits_fromL2pft,
  input         io_in_2_bits_needHint,
  input         io_in_2_bits_dirty,
  input  [2:0]  io_in_2_bits_way,
  input         io_in_2_bits_meta_dirty,
  input  [1:0]  io_in_2_bits_meta_state,
  input         io_in_2_bits_meta_clients,
  input  [1:0]  io_in_2_bits_meta_alias,
  input         io_in_2_bits_meta_prefetch,
  input  [2:0]  io_in_2_bits_meta_prefetchSrc,
  input         io_in_2_bits_meta_accessed,
  input         io_in_2_bits_meta_tagErr,
  input         io_in_2_bits_meta_dataErr,
  input         io_in_2_bits_metaWen,
  input         io_in_2_bits_tagWen,
  input         io_in_2_bits_dsWen,
  input  [7:0]  io_in_2_bits_wayMask,
  input         io_in_2_bits_replTask,
  input         io_in_2_bits_cmoTask,
  input         io_in_2_bits_cmoAll,
  input  [4:0]  io_in_2_bits_reqSource,
  input         io_in_2_bits_mergeA,
  input  [5:0]  io_in_2_bits_aMergeTask_off,
  input  [1:0]  io_in_2_bits_aMergeTask_alias,
  input  [43:0] io_in_2_bits_aMergeTask_vaddr,
  input         io_in_2_bits_aMergeTask_isKeyword,
  input  [2:0]  io_in_2_bits_aMergeTask_opcode,
  input  [2:0]  io_in_2_bits_aMergeTask_param,
  input  [6:0]  io_in_2_bits_aMergeTask_sourceId,
  input         io_in_2_bits_aMergeTask_meta_dirty,
  input  [1:0]  io_in_2_bits_aMergeTask_meta_state,
  input         io_in_2_bits_aMergeTask_meta_clients,
  input  [1:0]  io_in_2_bits_aMergeTask_meta_alias,
  input         io_in_2_bits_aMergeTask_meta_prefetch,
  input  [2:0]  io_in_2_bits_aMergeTask_meta_prefetchSrc,
  input         io_in_2_bits_aMergeTask_meta_accessed,
  input         io_in_2_bits_aMergeTask_meta_tagErr,
  input         io_in_2_bits_aMergeTask_meta_dataErr,
  input         io_in_2_bits_snpHitRelease,
  input         io_in_2_bits_snpHitReleaseToInval,
  input         io_in_2_bits_snpHitReleaseToClean,
  input         io_in_2_bits_snpHitReleaseWithData,
  input  [7:0]  io_in_2_bits_snpHitReleaseIdx,
  input         io_in_2_bits_snpHitReleaseMeta_dirty,
  input  [1:0]  io_in_2_bits_snpHitReleaseMeta_state,
  input         io_in_2_bits_snpHitReleaseMeta_clients,
  input  [1:0]  io_in_2_bits_snpHitReleaseMeta_alias,
  input         io_in_2_bits_snpHitReleaseMeta_prefetch,
  input  [2:0]  io_in_2_bits_snpHitReleaseMeta_prefetchSrc,
  input         io_in_2_bits_snpHitReleaseMeta_accessed,
  input         io_in_2_bits_snpHitReleaseMeta_tagErr,
  input         io_in_2_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_in_2_bits_tgtID,
  input  [10:0] io_in_2_bits_srcID,
  input  [11:0] io_in_2_bits_txnID,
  input  [10:0] io_in_2_bits_homeNID,
  input  [11:0] io_in_2_bits_dbID,
  input  [10:0] io_in_2_bits_fwdNID,
  input  [11:0] io_in_2_bits_fwdTxnID,
  input  [6:0]  io_in_2_bits_chiOpcode,
  input  [2:0]  io_in_2_bits_resp,
  input  [2:0]  io_in_2_bits_fwdState,
  input  [3:0]  io_in_2_bits_pCrdType,
  input         io_in_2_bits_retToSrc,
  input         io_in_2_bits_likelyshared,
  input         io_in_2_bits_expCompAck,
  input         io_in_2_bits_allowRetry,
  input         io_in_2_bits_memAttr_allocate,
  input         io_in_2_bits_memAttr_cacheable,
  input         io_in_2_bits_memAttr_device,
  input         io_in_2_bits_memAttr_ewa,
  input         io_in_2_bits_traceTag,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [2:0]  io_in_3_bits_channel,
  input  [2:0]  io_in_3_bits_txChannel,
  input  [8:0]  io_in_3_bits_set,
  input  [30:0] io_in_3_bits_tag,
  input  [5:0]  io_in_3_bits_off,
  input  [1:0]  io_in_3_bits_alias,
  input  [43:0] io_in_3_bits_vaddr,
  input         io_in_3_bits_isKeyword,
  input  [3:0]  io_in_3_bits_opcode,
  input  [2:0]  io_in_3_bits_param,
  input  [2:0]  io_in_3_bits_size,
  input  [6:0]  io_in_3_bits_sourceId,
  input  [1:0]  io_in_3_bits_bufIdx,
  input         io_in_3_bits_needProbeAckData,
  input         io_in_3_bits_denied,
  input         io_in_3_bits_corrupt,
  input         io_in_3_bits_mshrTask,
  input  [7:0]  io_in_3_bits_mshrId,
  input         io_in_3_bits_aliasTask,
  input         io_in_3_bits_useProbeData,
  input         io_in_3_bits_mshrRetry,
  input         io_in_3_bits_readProbeDataDown,
  input         io_in_3_bits_fromL2pft,
  input         io_in_3_bits_needHint,
  input         io_in_3_bits_dirty,
  input  [2:0]  io_in_3_bits_way,
  input         io_in_3_bits_meta_dirty,
  input  [1:0]  io_in_3_bits_meta_state,
  input         io_in_3_bits_meta_clients,
  input  [1:0]  io_in_3_bits_meta_alias,
  input         io_in_3_bits_meta_prefetch,
  input  [2:0]  io_in_3_bits_meta_prefetchSrc,
  input         io_in_3_bits_meta_accessed,
  input         io_in_3_bits_meta_tagErr,
  input         io_in_3_bits_meta_dataErr,
  input         io_in_3_bits_metaWen,
  input         io_in_3_bits_tagWen,
  input         io_in_3_bits_dsWen,
  input  [7:0]  io_in_3_bits_wayMask,
  input         io_in_3_bits_replTask,
  input         io_in_3_bits_cmoTask,
  input         io_in_3_bits_cmoAll,
  input  [4:0]  io_in_3_bits_reqSource,
  input         io_in_3_bits_mergeA,
  input  [5:0]  io_in_3_bits_aMergeTask_off,
  input  [1:0]  io_in_3_bits_aMergeTask_alias,
  input  [43:0] io_in_3_bits_aMergeTask_vaddr,
  input         io_in_3_bits_aMergeTask_isKeyword,
  input  [2:0]  io_in_3_bits_aMergeTask_opcode,
  input  [2:0]  io_in_3_bits_aMergeTask_param,
  input  [6:0]  io_in_3_bits_aMergeTask_sourceId,
  input         io_in_3_bits_aMergeTask_meta_dirty,
  input  [1:0]  io_in_3_bits_aMergeTask_meta_state,
  input         io_in_3_bits_aMergeTask_meta_clients,
  input  [1:0]  io_in_3_bits_aMergeTask_meta_alias,
  input         io_in_3_bits_aMergeTask_meta_prefetch,
  input  [2:0]  io_in_3_bits_aMergeTask_meta_prefetchSrc,
  input         io_in_3_bits_aMergeTask_meta_accessed,
  input         io_in_3_bits_aMergeTask_meta_tagErr,
  input         io_in_3_bits_aMergeTask_meta_dataErr,
  input         io_in_3_bits_snpHitRelease,
  input         io_in_3_bits_snpHitReleaseToInval,
  input         io_in_3_bits_snpHitReleaseToClean,
  input         io_in_3_bits_snpHitReleaseWithData,
  input  [7:0]  io_in_3_bits_snpHitReleaseIdx,
  input         io_in_3_bits_snpHitReleaseMeta_dirty,
  input  [1:0]  io_in_3_bits_snpHitReleaseMeta_state,
  input         io_in_3_bits_snpHitReleaseMeta_clients,
  input  [1:0]  io_in_3_bits_snpHitReleaseMeta_alias,
  input         io_in_3_bits_snpHitReleaseMeta_prefetch,
  input  [2:0]  io_in_3_bits_snpHitReleaseMeta_prefetchSrc,
  input         io_in_3_bits_snpHitReleaseMeta_accessed,
  input         io_in_3_bits_snpHitReleaseMeta_tagErr,
  input         io_in_3_bits_snpHitReleaseMeta_dataErr,
  input  [10:0] io_in_3_bits_tgtID,
  input  [10:0] io_in_3_bits_srcID,
  input  [11:0] io_in_3_bits_txnID,
  input  [10:0] io_in_3_bits_homeNID,
  input  [11:0] io_in_3_bits_dbID,
  input  [10:0] io_in_3_bits_fwdNID,
  input  [11:0] io_in_3_bits_fwdTxnID,
  input  [6:0]  io_in_3_bits_chiOpcode,
  input  [2:0]  io_in_3_bits_resp,
  input  [2:0]  io_in_3_bits_fwdState,
  input  [3:0]  io_in_3_bits_pCrdType,
  input         io_in_3_bits_retToSrc,
  input         io_in_3_bits_likelyshared,
  input         io_in_3_bits_expCompAck,
  input         io_in_3_bits_allowRetry,
  input         io_in_3_bits_memAttr_allocate,
  input         io_in_3_bits_memAttr_cacheable,
  input         io_in_3_bits_memAttr_device,
  input         io_in_3_bits_memAttr_ewa,
  input         io_in_3_bits_traceTag,
  input         io_out_ready,
  output        io_out_valid,
  output [2:0]  io_out_bits_channel,
  output [2:0]  io_out_bits_txChannel,
  output [8:0]  io_out_bits_set,
  output [30:0] io_out_bits_tag,
  output [5:0]  io_out_bits_off,
  output [1:0]  io_out_bits_alias,
  output [43:0] io_out_bits_vaddr,
  output        io_out_bits_isKeyword,
  output [3:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_param,
  output [2:0]  io_out_bits_size,
  output [6:0]  io_out_bits_sourceId,
  output [1:0]  io_out_bits_bufIdx,
  output        io_out_bits_needProbeAckData,
  output        io_out_bits_denied,
  output        io_out_bits_corrupt,
  output        io_out_bits_mshrTask,
  output [7:0]  io_out_bits_mshrId,
  output        io_out_bits_aliasTask,
  output        io_out_bits_useProbeData,
  output        io_out_bits_mshrRetry,
  output        io_out_bits_readProbeDataDown,
  output        io_out_bits_fromL2pft,
  output        io_out_bits_needHint,
  output        io_out_bits_dirty,
  output [2:0]  io_out_bits_way,
  output        io_out_bits_meta_dirty,
  output [1:0]  io_out_bits_meta_state,
  output        io_out_bits_meta_clients,
  output [1:0]  io_out_bits_meta_alias,
  output        io_out_bits_meta_prefetch,
  output [2:0]  io_out_bits_meta_prefetchSrc,
  output        io_out_bits_meta_accessed,
  output        io_out_bits_meta_tagErr,
  output        io_out_bits_meta_dataErr,
  output        io_out_bits_metaWen,
  output        io_out_bits_tagWen,
  output        io_out_bits_dsWen,
  output [7:0]  io_out_bits_wayMask,
  output        io_out_bits_replTask,
  output        io_out_bits_cmoTask,
  output        io_out_bits_cmoAll,
  output [4:0]  io_out_bits_reqSource,
  output        io_out_bits_mergeA,
  output [5:0]  io_out_bits_aMergeTask_off,
  output [1:0]  io_out_bits_aMergeTask_alias,
  output [43:0] io_out_bits_aMergeTask_vaddr,
  output        io_out_bits_aMergeTask_isKeyword,
  output [2:0]  io_out_bits_aMergeTask_opcode,
  output [2:0]  io_out_bits_aMergeTask_param,
  output [6:0]  io_out_bits_aMergeTask_sourceId,
  output        io_out_bits_aMergeTask_meta_dirty,
  output [1:0]  io_out_bits_aMergeTask_meta_state,
  output        io_out_bits_aMergeTask_meta_clients,
  output [1:0]  io_out_bits_aMergeTask_meta_alias,
  output        io_out_bits_aMergeTask_meta_prefetch,
  output [2:0]  io_out_bits_aMergeTask_meta_prefetchSrc,
  output        io_out_bits_aMergeTask_meta_accessed,
  output        io_out_bits_aMergeTask_meta_tagErr,
  output        io_out_bits_aMergeTask_meta_dataErr,
  output        io_out_bits_snpHitRelease,
  output        io_out_bits_snpHitReleaseToInval,
  output        io_out_bits_snpHitReleaseToClean,
  output        io_out_bits_snpHitReleaseWithData,
  output [7:0]  io_out_bits_snpHitReleaseIdx,
  output        io_out_bits_snpHitReleaseMeta_dirty,
  output [1:0]  io_out_bits_snpHitReleaseMeta_state,
  output        io_out_bits_snpHitReleaseMeta_clients,
  output [1:0]  io_out_bits_snpHitReleaseMeta_alias,
  output        io_out_bits_snpHitReleaseMeta_prefetch,
  output [2:0]  io_out_bits_snpHitReleaseMeta_prefetchSrc,
  output        io_out_bits_snpHitReleaseMeta_accessed,
  output        io_out_bits_snpHitReleaseMeta_tagErr,
  output        io_out_bits_snpHitReleaseMeta_dataErr,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [10:0] io_out_bits_homeNID,
  output [11:0] io_out_bits_dbID,
  output [10:0] io_out_bits_fwdNID,
  output [11:0] io_out_bits_fwdTxnID,
  output [6:0]  io_out_bits_chiOpcode,
  output [2:0]  io_out_bits_resp,
  output [2:0]  io_out_bits_fwdState,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_retToSrc,
  output        io_out_bits_likelyshared,
  output        io_out_bits_expCompAck,
  output        io_out_bits_allowRetry,
  output        io_out_bits_memAttr_allocate,
  output        io_out_bits_memAttr_cacheable,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa,
  output        io_out_bits_traceTag
);
  localparam int N = 4;
  localparam int W = $bits(payload_t);

  // 打包：每一路按字段表顺序拼成 W 位（下面的拆包用同一张表，反过来一次）。
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = {
    io_in_0_bits_channel,
    io_in_0_bits_txChannel,
    io_in_0_bits_set,
    io_in_0_bits_tag,
    io_in_0_bits_off,
    io_in_0_bits_alias,
    io_in_0_bits_vaddr,
    io_in_0_bits_isKeyword,
    io_in_0_bits_opcode,
    io_in_0_bits_param,
    io_in_0_bits_size,
    io_in_0_bits_sourceId,
    io_in_0_bits_bufIdx,
    io_in_0_bits_needProbeAckData,
    io_in_0_bits_denied,
    io_in_0_bits_corrupt,
    io_in_0_bits_mshrTask,
    io_in_0_bits_mshrId,
    io_in_0_bits_aliasTask,
    io_in_0_bits_useProbeData,
    io_in_0_bits_mshrRetry,
    io_in_0_bits_readProbeDataDown,
    io_in_0_bits_fromL2pft,
    io_in_0_bits_needHint,
    io_in_0_bits_dirty,
    io_in_0_bits_way,
    io_in_0_bits_meta_dirty,
    io_in_0_bits_meta_state,
    io_in_0_bits_meta_clients,
    io_in_0_bits_meta_alias,
    io_in_0_bits_meta_prefetch,
    io_in_0_bits_meta_prefetchSrc,
    io_in_0_bits_meta_accessed,
    io_in_0_bits_meta_tagErr,
    io_in_0_bits_meta_dataErr,
    io_in_0_bits_metaWen,
    io_in_0_bits_tagWen,
    io_in_0_bits_dsWen,
    io_in_0_bits_wayMask,
    io_in_0_bits_replTask,
    io_in_0_bits_cmoTask,
    io_in_0_bits_cmoAll,
    io_in_0_bits_reqSource,
    io_in_0_bits_mergeA,
    io_in_0_bits_aMergeTask_off,
    io_in_0_bits_aMergeTask_alias,
    io_in_0_bits_aMergeTask_vaddr,
    io_in_0_bits_aMergeTask_isKeyword,
    io_in_0_bits_aMergeTask_opcode,
    io_in_0_bits_aMergeTask_param,
    io_in_0_bits_aMergeTask_sourceId,
    io_in_0_bits_aMergeTask_meta_dirty,
    io_in_0_bits_aMergeTask_meta_state,
    io_in_0_bits_aMergeTask_meta_clients,
    io_in_0_bits_aMergeTask_meta_alias,
    io_in_0_bits_aMergeTask_meta_prefetch,
    io_in_0_bits_aMergeTask_meta_prefetchSrc,
    io_in_0_bits_aMergeTask_meta_accessed,
    io_in_0_bits_aMergeTask_meta_tagErr,
    io_in_0_bits_aMergeTask_meta_dataErr,
    io_in_0_bits_snpHitRelease,
    io_in_0_bits_snpHitReleaseToInval,
    io_in_0_bits_snpHitReleaseToClean,
    io_in_0_bits_snpHitReleaseWithData,
    io_in_0_bits_snpHitReleaseIdx,
    io_in_0_bits_snpHitReleaseMeta_dirty,
    io_in_0_bits_snpHitReleaseMeta_state,
    io_in_0_bits_snpHitReleaseMeta_clients,
    io_in_0_bits_snpHitReleaseMeta_alias,
    io_in_0_bits_snpHitReleaseMeta_prefetch,
    io_in_0_bits_snpHitReleaseMeta_prefetchSrc,
    io_in_0_bits_snpHitReleaseMeta_accessed,
    io_in_0_bits_snpHitReleaseMeta_tagErr,
    io_in_0_bits_snpHitReleaseMeta_dataErr,
    io_in_0_bits_tgtID,
    io_in_0_bits_srcID,
    io_in_0_bits_txnID,
    io_in_0_bits_homeNID,
    io_in_0_bits_dbID,
    io_in_0_bits_fwdNID,
    io_in_0_bits_fwdTxnID,
    io_in_0_bits_chiOpcode,
    io_in_0_bits_resp,
    io_in_0_bits_fwdState,
    io_in_0_bits_pCrdType,
    io_in_0_bits_retToSrc,
    io_in_0_bits_likelyshared,
    io_in_0_bits_expCompAck,
    io_in_0_bits_allowRetry,
    io_in_0_bits_memAttr_allocate,
    io_in_0_bits_memAttr_cacheable,
    io_in_0_bits_memAttr_device,
    io_in_0_bits_memAttr_ewa,
    io_in_0_bits_traceTag};
  assign in_payload[1] = {
    io_in_1_bits_channel,
    io_in_1_bits_txChannel,
    io_in_1_bits_set,
    io_in_1_bits_tag,
    io_in_1_bits_off,
    io_in_1_bits_alias,
    io_in_1_bits_vaddr,
    io_in_1_bits_isKeyword,
    io_in_1_bits_opcode,
    io_in_1_bits_param,
    io_in_1_bits_size,
    io_in_1_bits_sourceId,
    io_in_1_bits_bufIdx,
    io_in_1_bits_needProbeAckData,
    io_in_1_bits_denied,
    io_in_1_bits_corrupt,
    io_in_1_bits_mshrTask,
    io_in_1_bits_mshrId,
    io_in_1_bits_aliasTask,
    io_in_1_bits_useProbeData,
    io_in_1_bits_mshrRetry,
    io_in_1_bits_readProbeDataDown,
    io_in_1_bits_fromL2pft,
    io_in_1_bits_needHint,
    io_in_1_bits_dirty,
    io_in_1_bits_way,
    io_in_1_bits_meta_dirty,
    io_in_1_bits_meta_state,
    io_in_1_bits_meta_clients,
    io_in_1_bits_meta_alias,
    io_in_1_bits_meta_prefetch,
    io_in_1_bits_meta_prefetchSrc,
    io_in_1_bits_meta_accessed,
    io_in_1_bits_meta_tagErr,
    io_in_1_bits_meta_dataErr,
    io_in_1_bits_metaWen,
    io_in_1_bits_tagWen,
    io_in_1_bits_dsWen,
    io_in_1_bits_wayMask,
    io_in_1_bits_replTask,
    io_in_1_bits_cmoTask,
    io_in_1_bits_cmoAll,
    io_in_1_bits_reqSource,
    io_in_1_bits_mergeA,
    io_in_1_bits_aMergeTask_off,
    io_in_1_bits_aMergeTask_alias,
    io_in_1_bits_aMergeTask_vaddr,
    io_in_1_bits_aMergeTask_isKeyword,
    io_in_1_bits_aMergeTask_opcode,
    io_in_1_bits_aMergeTask_param,
    io_in_1_bits_aMergeTask_sourceId,
    io_in_1_bits_aMergeTask_meta_dirty,
    io_in_1_bits_aMergeTask_meta_state,
    io_in_1_bits_aMergeTask_meta_clients,
    io_in_1_bits_aMergeTask_meta_alias,
    io_in_1_bits_aMergeTask_meta_prefetch,
    io_in_1_bits_aMergeTask_meta_prefetchSrc,
    io_in_1_bits_aMergeTask_meta_accessed,
    io_in_1_bits_aMergeTask_meta_tagErr,
    io_in_1_bits_aMergeTask_meta_dataErr,
    io_in_1_bits_snpHitRelease,
    io_in_1_bits_snpHitReleaseToInval,
    io_in_1_bits_snpHitReleaseToClean,
    io_in_1_bits_snpHitReleaseWithData,
    io_in_1_bits_snpHitReleaseIdx,
    io_in_1_bits_snpHitReleaseMeta_dirty,
    io_in_1_bits_snpHitReleaseMeta_state,
    io_in_1_bits_snpHitReleaseMeta_clients,
    io_in_1_bits_snpHitReleaseMeta_alias,
    io_in_1_bits_snpHitReleaseMeta_prefetch,
    io_in_1_bits_snpHitReleaseMeta_prefetchSrc,
    io_in_1_bits_snpHitReleaseMeta_accessed,
    io_in_1_bits_snpHitReleaseMeta_tagErr,
    io_in_1_bits_snpHitReleaseMeta_dataErr,
    io_in_1_bits_tgtID,
    io_in_1_bits_srcID,
    io_in_1_bits_txnID,
    io_in_1_bits_homeNID,
    io_in_1_bits_dbID,
    io_in_1_bits_fwdNID,
    io_in_1_bits_fwdTxnID,
    io_in_1_bits_chiOpcode,
    io_in_1_bits_resp,
    io_in_1_bits_fwdState,
    io_in_1_bits_pCrdType,
    io_in_1_bits_retToSrc,
    io_in_1_bits_likelyshared,
    io_in_1_bits_expCompAck,
    io_in_1_bits_allowRetry,
    io_in_1_bits_memAttr_allocate,
    io_in_1_bits_memAttr_cacheable,
    io_in_1_bits_memAttr_device,
    io_in_1_bits_memAttr_ewa,
    io_in_1_bits_traceTag};
  assign in_payload[2] = {
    io_in_2_bits_channel,
    io_in_2_bits_txChannel,
    io_in_2_bits_set,
    io_in_2_bits_tag,
    io_in_2_bits_off,
    io_in_2_bits_alias,
    io_in_2_bits_vaddr,
    io_in_2_bits_isKeyword,
    io_in_2_bits_opcode,
    io_in_2_bits_param,
    io_in_2_bits_size,
    io_in_2_bits_sourceId,
    io_in_2_bits_bufIdx,
    io_in_2_bits_needProbeAckData,
    io_in_2_bits_denied,
    io_in_2_bits_corrupt,
    io_in_2_bits_mshrTask,
    io_in_2_bits_mshrId,
    io_in_2_bits_aliasTask,
    io_in_2_bits_useProbeData,
    io_in_2_bits_mshrRetry,
    io_in_2_bits_readProbeDataDown,
    io_in_2_bits_fromL2pft,
    io_in_2_bits_needHint,
    io_in_2_bits_dirty,
    io_in_2_bits_way,
    io_in_2_bits_meta_dirty,
    io_in_2_bits_meta_state,
    io_in_2_bits_meta_clients,
    io_in_2_bits_meta_alias,
    io_in_2_bits_meta_prefetch,
    io_in_2_bits_meta_prefetchSrc,
    io_in_2_bits_meta_accessed,
    io_in_2_bits_meta_tagErr,
    io_in_2_bits_meta_dataErr,
    io_in_2_bits_metaWen,
    io_in_2_bits_tagWen,
    io_in_2_bits_dsWen,
    io_in_2_bits_wayMask,
    io_in_2_bits_replTask,
    io_in_2_bits_cmoTask,
    io_in_2_bits_cmoAll,
    io_in_2_bits_reqSource,
    io_in_2_bits_mergeA,
    io_in_2_bits_aMergeTask_off,
    io_in_2_bits_aMergeTask_alias,
    io_in_2_bits_aMergeTask_vaddr,
    io_in_2_bits_aMergeTask_isKeyword,
    io_in_2_bits_aMergeTask_opcode,
    io_in_2_bits_aMergeTask_param,
    io_in_2_bits_aMergeTask_sourceId,
    io_in_2_bits_aMergeTask_meta_dirty,
    io_in_2_bits_aMergeTask_meta_state,
    io_in_2_bits_aMergeTask_meta_clients,
    io_in_2_bits_aMergeTask_meta_alias,
    io_in_2_bits_aMergeTask_meta_prefetch,
    io_in_2_bits_aMergeTask_meta_prefetchSrc,
    io_in_2_bits_aMergeTask_meta_accessed,
    io_in_2_bits_aMergeTask_meta_tagErr,
    io_in_2_bits_aMergeTask_meta_dataErr,
    io_in_2_bits_snpHitRelease,
    io_in_2_bits_snpHitReleaseToInval,
    io_in_2_bits_snpHitReleaseToClean,
    io_in_2_bits_snpHitReleaseWithData,
    io_in_2_bits_snpHitReleaseIdx,
    io_in_2_bits_snpHitReleaseMeta_dirty,
    io_in_2_bits_snpHitReleaseMeta_state,
    io_in_2_bits_snpHitReleaseMeta_clients,
    io_in_2_bits_snpHitReleaseMeta_alias,
    io_in_2_bits_snpHitReleaseMeta_prefetch,
    io_in_2_bits_snpHitReleaseMeta_prefetchSrc,
    io_in_2_bits_snpHitReleaseMeta_accessed,
    io_in_2_bits_snpHitReleaseMeta_tagErr,
    io_in_2_bits_snpHitReleaseMeta_dataErr,
    io_in_2_bits_tgtID,
    io_in_2_bits_srcID,
    io_in_2_bits_txnID,
    io_in_2_bits_homeNID,
    io_in_2_bits_dbID,
    io_in_2_bits_fwdNID,
    io_in_2_bits_fwdTxnID,
    io_in_2_bits_chiOpcode,
    io_in_2_bits_resp,
    io_in_2_bits_fwdState,
    io_in_2_bits_pCrdType,
    io_in_2_bits_retToSrc,
    io_in_2_bits_likelyshared,
    io_in_2_bits_expCompAck,
    io_in_2_bits_allowRetry,
    io_in_2_bits_memAttr_allocate,
    io_in_2_bits_memAttr_cacheable,
    io_in_2_bits_memAttr_device,
    io_in_2_bits_memAttr_ewa,
    io_in_2_bits_traceTag};
  assign in_payload[3] = {
    io_in_3_bits_channel,
    io_in_3_bits_txChannel,
    io_in_3_bits_set,
    io_in_3_bits_tag,
    io_in_3_bits_off,
    io_in_3_bits_alias,
    io_in_3_bits_vaddr,
    io_in_3_bits_isKeyword,
    io_in_3_bits_opcode,
    io_in_3_bits_param,
    io_in_3_bits_size,
    io_in_3_bits_sourceId,
    io_in_3_bits_bufIdx,
    io_in_3_bits_needProbeAckData,
    io_in_3_bits_denied,
    io_in_3_bits_corrupt,
    io_in_3_bits_mshrTask,
    io_in_3_bits_mshrId,
    io_in_3_bits_aliasTask,
    io_in_3_bits_useProbeData,
    io_in_3_bits_mshrRetry,
    io_in_3_bits_readProbeDataDown,
    io_in_3_bits_fromL2pft,
    io_in_3_bits_needHint,
    io_in_3_bits_dirty,
    io_in_3_bits_way,
    io_in_3_bits_meta_dirty,
    io_in_3_bits_meta_state,
    io_in_3_bits_meta_clients,
    io_in_3_bits_meta_alias,
    io_in_3_bits_meta_prefetch,
    io_in_3_bits_meta_prefetchSrc,
    io_in_3_bits_meta_accessed,
    io_in_3_bits_meta_tagErr,
    io_in_3_bits_meta_dataErr,
    io_in_3_bits_metaWen,
    io_in_3_bits_tagWen,
    io_in_3_bits_dsWen,
    io_in_3_bits_wayMask,
    io_in_3_bits_replTask,
    io_in_3_bits_cmoTask,
    io_in_3_bits_cmoAll,
    io_in_3_bits_reqSource,
    io_in_3_bits_mergeA,
    io_in_3_bits_aMergeTask_off,
    io_in_3_bits_aMergeTask_alias,
    io_in_3_bits_aMergeTask_vaddr,
    io_in_3_bits_aMergeTask_isKeyword,
    io_in_3_bits_aMergeTask_opcode,
    io_in_3_bits_aMergeTask_param,
    io_in_3_bits_aMergeTask_sourceId,
    io_in_3_bits_aMergeTask_meta_dirty,
    io_in_3_bits_aMergeTask_meta_state,
    io_in_3_bits_aMergeTask_meta_clients,
    io_in_3_bits_aMergeTask_meta_alias,
    io_in_3_bits_aMergeTask_meta_prefetch,
    io_in_3_bits_aMergeTask_meta_prefetchSrc,
    io_in_3_bits_aMergeTask_meta_accessed,
    io_in_3_bits_aMergeTask_meta_tagErr,
    io_in_3_bits_aMergeTask_meta_dataErr,
    io_in_3_bits_snpHitRelease,
    io_in_3_bits_snpHitReleaseToInval,
    io_in_3_bits_snpHitReleaseToClean,
    io_in_3_bits_snpHitReleaseWithData,
    io_in_3_bits_snpHitReleaseIdx,
    io_in_3_bits_snpHitReleaseMeta_dirty,
    io_in_3_bits_snpHitReleaseMeta_state,
    io_in_3_bits_snpHitReleaseMeta_clients,
    io_in_3_bits_snpHitReleaseMeta_alias,
    io_in_3_bits_snpHitReleaseMeta_prefetch,
    io_in_3_bits_snpHitReleaseMeta_prefetchSrc,
    io_in_3_bits_snpHitReleaseMeta_accessed,
    io_in_3_bits_snpHitReleaseMeta_tagErr,
    io_in_3_bits_snpHitReleaseMeta_dataErr,
    io_in_3_bits_tgtID,
    io_in_3_bits_srcID,
    io_in_3_bits_txnID,
    io_in_3_bits_homeNID,
    io_in_3_bits_dbID,
    io_in_3_bits_fwdNID,
    io_in_3_bits_fwdTxnID,
    io_in_3_bits_chiOpcode,
    io_in_3_bits_resp,
    io_in_3_bits_fwdState,
    io_in_3_bits_pCrdType,
    io_in_3_bits_retToSrc,
    io_in_3_bits_likelyshared,
    io_in_3_bits_expCompAck,
    io_in_3_bits_allowRetry,
    io_in_3_bits_memAttr_allocate,
    io_in_3_bits_memAttr_cacheable,
    io_in_3_bits_memAttr_device,
    io_in_3_bits_memAttr_ewa,
    io_in_3_bits_traceTag};

  payload_t out_payload;
  xs_RRArbiterInit_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload),
    .chosen    ()                  // 本变体 golden 无 io_chosen 输出端口
  );

  // 拆包：与上面的打包共用同一张字段表。
  assign io_out_bits_channel = out_payload.channel;
  assign io_out_bits_txChannel = out_payload.txChannel;
  assign io_out_bits_set = out_payload.set;
  assign io_out_bits_tag = out_payload.tag;
  assign io_out_bits_off = out_payload.off;
  assign io_out_bits_alias = out_payload.alias_f;
  assign io_out_bits_vaddr = out_payload.vaddr;
  assign io_out_bits_isKeyword = out_payload.isKeyword;
  assign io_out_bits_opcode = out_payload.opcode;
  assign io_out_bits_param = out_payload.param;
  assign io_out_bits_size = out_payload.size;
  assign io_out_bits_sourceId = out_payload.sourceId;
  assign io_out_bits_bufIdx = out_payload.bufIdx;
  assign io_out_bits_needProbeAckData = out_payload.needProbeAckData;
  assign io_out_bits_denied = out_payload.denied;
  assign io_out_bits_corrupt = out_payload.corrupt;
  assign io_out_bits_mshrTask = out_payload.mshrTask;
  assign io_out_bits_mshrId = out_payload.mshrId;
  assign io_out_bits_aliasTask = out_payload.aliasTask;
  assign io_out_bits_useProbeData = out_payload.useProbeData;
  assign io_out_bits_mshrRetry = out_payload.mshrRetry;
  assign io_out_bits_readProbeDataDown = out_payload.readProbeDataDown;
  assign io_out_bits_fromL2pft = out_payload.fromL2pft;
  assign io_out_bits_needHint = out_payload.needHint;
  assign io_out_bits_dirty = out_payload.dirty;
  assign io_out_bits_way = out_payload.way;
  assign io_out_bits_meta_dirty = out_payload.meta_dirty;
  assign io_out_bits_meta_state = out_payload.meta_state;
  assign io_out_bits_meta_clients = out_payload.meta_clients;
  assign io_out_bits_meta_alias = out_payload.meta_alias;
  assign io_out_bits_meta_prefetch = out_payload.meta_prefetch;
  assign io_out_bits_meta_prefetchSrc = out_payload.meta_prefetchSrc;
  assign io_out_bits_meta_accessed = out_payload.meta_accessed;
  assign io_out_bits_meta_tagErr = out_payload.meta_tagErr;
  assign io_out_bits_meta_dataErr = out_payload.meta_dataErr;
  assign io_out_bits_metaWen = out_payload.metaWen;
  assign io_out_bits_tagWen = out_payload.tagWen;
  assign io_out_bits_dsWen = out_payload.dsWen;
  assign io_out_bits_wayMask = out_payload.wayMask;
  assign io_out_bits_replTask = out_payload.replTask;
  assign io_out_bits_cmoTask = out_payload.cmoTask;
  assign io_out_bits_cmoAll = out_payload.cmoAll;
  assign io_out_bits_reqSource = out_payload.reqSource;
  assign io_out_bits_mergeA = out_payload.mergeA;
  assign io_out_bits_aMergeTask_off = out_payload.aMergeTask_off;
  assign io_out_bits_aMergeTask_alias = out_payload.aMergeTask_alias;
  assign io_out_bits_aMergeTask_vaddr = out_payload.aMergeTask_vaddr;
  assign io_out_bits_aMergeTask_isKeyword = out_payload.aMergeTask_isKeyword;
  assign io_out_bits_aMergeTask_opcode = out_payload.aMergeTask_opcode;
  assign io_out_bits_aMergeTask_param = out_payload.aMergeTask_param;
  assign io_out_bits_aMergeTask_sourceId = out_payload.aMergeTask_sourceId;
  assign io_out_bits_aMergeTask_meta_dirty = out_payload.aMergeTask_meta_dirty;
  assign io_out_bits_aMergeTask_meta_state = out_payload.aMergeTask_meta_state;
  assign io_out_bits_aMergeTask_meta_clients = out_payload.aMergeTask_meta_clients;
  assign io_out_bits_aMergeTask_meta_alias = out_payload.aMergeTask_meta_alias;
  assign io_out_bits_aMergeTask_meta_prefetch = out_payload.aMergeTask_meta_prefetch;
  assign io_out_bits_aMergeTask_meta_prefetchSrc = out_payload.aMergeTask_meta_prefetchSrc;
  assign io_out_bits_aMergeTask_meta_accessed = out_payload.aMergeTask_meta_accessed;
  assign io_out_bits_aMergeTask_meta_tagErr = out_payload.aMergeTask_meta_tagErr;
  assign io_out_bits_aMergeTask_meta_dataErr = out_payload.aMergeTask_meta_dataErr;
  assign io_out_bits_snpHitRelease = out_payload.snpHitRelease;
  assign io_out_bits_snpHitReleaseToInval = out_payload.snpHitReleaseToInval;
  assign io_out_bits_snpHitReleaseToClean = out_payload.snpHitReleaseToClean;
  assign io_out_bits_snpHitReleaseWithData = out_payload.snpHitReleaseWithData;
  assign io_out_bits_snpHitReleaseIdx = out_payload.snpHitReleaseIdx;
  assign io_out_bits_snpHitReleaseMeta_dirty = out_payload.snpHitReleaseMeta_dirty;
  assign io_out_bits_snpHitReleaseMeta_state = out_payload.snpHitReleaseMeta_state;
  assign io_out_bits_snpHitReleaseMeta_clients = out_payload.snpHitReleaseMeta_clients;
  assign io_out_bits_snpHitReleaseMeta_alias = out_payload.snpHitReleaseMeta_alias;
  assign io_out_bits_snpHitReleaseMeta_prefetch = out_payload.snpHitReleaseMeta_prefetch;
  assign io_out_bits_snpHitReleaseMeta_prefetchSrc = out_payload.snpHitReleaseMeta_prefetchSrc;
  assign io_out_bits_snpHitReleaseMeta_accessed = out_payload.snpHitReleaseMeta_accessed;
  assign io_out_bits_snpHitReleaseMeta_tagErr = out_payload.snpHitReleaseMeta_tagErr;
  assign io_out_bits_snpHitReleaseMeta_dataErr = out_payload.snpHitReleaseMeta_dataErr;
  assign io_out_bits_tgtID = out_payload.tgtID;
  assign io_out_bits_srcID = out_payload.srcID;
  assign io_out_bits_txnID = out_payload.txnID;
  assign io_out_bits_homeNID = out_payload.homeNID;
  assign io_out_bits_dbID = out_payload.dbID;
  assign io_out_bits_fwdNID = out_payload.fwdNID;
  assign io_out_bits_fwdTxnID = out_payload.fwdTxnID;
  assign io_out_bits_chiOpcode = out_payload.chiOpcode;
  assign io_out_bits_resp = out_payload.resp;
  assign io_out_bits_fwdState = out_payload.fwdState;
  assign io_out_bits_pCrdType = out_payload.pCrdType;
  assign io_out_bits_retToSrc = out_payload.retToSrc;
  assign io_out_bits_likelyshared = out_payload.likelyshared;
  assign io_out_bits_expCompAck = out_payload.expCompAck;
  assign io_out_bits_allowRetry = out_payload.allowRetry;
  assign io_out_bits_memAttr_allocate = out_payload.memAttr_allocate;
  assign io_out_bits_memAttr_cacheable = out_payload.memAttr_cacheable;
  assign io_out_bits_memAttr_device = out_payload.memAttr_device;
  assign io_out_bits_memAttr_ewa = out_payload.memAttr_ewa;
  assign io_out_bits_traceTag = out_payload.traceTag;
endmodule
