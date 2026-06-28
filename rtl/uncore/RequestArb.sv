// 自动生成 scripts/gen_requestarb.py —— 勿手改
// =============================================================================
//  RequestArb —— coupledL2 (tl2chi) L2 slice s0/s1/s2 请求仲裁流水 可读重写核
//          (xs_RequestArb_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/RequestArb.scala
//  无子模块, 纯流水仲裁。通道选择/逐级流水用 TaskBundle 结构体收敛逐字段 Mux。
//  ===== X 铁律 =====
//    resetFinish/resetIdx/mshr_task_s1_valid/task_s2_valid 异步复位; resetIdx=511
//    倒数 512 拍门控通道入口; ds_mcp2_stall 为无复位 RegNext(initreg+0 起 0)。
// =============================================================================
module xs_RequestArb_core
  import l2_task_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  // ---- io.sinkA (Flipped Decoupled TaskBundle) ----
  output logic        io_sinkA_ready,
  input  logic        io_sinkA_valid,
  input  logic [2:0]  io_sinkA_bits_channel,
  input  logic [2:0]  io_sinkA_bits_txChannel,
  input  logic [8:0]  io_sinkA_bits_set,
  input  logic [30:0] io_sinkA_bits_tag,
  input  logic [5:0]  io_sinkA_bits_off,
  input  logic [1:0]  io_sinkA_bits_alias,
  input  logic [43:0] io_sinkA_bits_vaddr,
  input  logic        io_sinkA_bits_isKeyword,
  input  logic [3:0]  io_sinkA_bits_opcode,
  input  logic [2:0]  io_sinkA_bits_param,
  input  logic [2:0]  io_sinkA_bits_size,
  input  logic [6:0]  io_sinkA_bits_sourceId,
  input  logic [1:0]  io_sinkA_bits_bufIdx,
  input  logic        io_sinkA_bits_needProbeAckData,
  input  logic        io_sinkA_bits_denied,
  input  logic        io_sinkA_bits_corrupt,
  input  logic        io_sinkA_bits_mshrTask,
  input  logic [7:0]  io_sinkA_bits_mshrId,
  input  logic        io_sinkA_bits_aliasTask,
  input  logic        io_sinkA_bits_useProbeData,
  input  logic        io_sinkA_bits_mshrRetry,
  input  logic        io_sinkA_bits_readProbeDataDown,
  input  logic        io_sinkA_bits_fromL2pft,
  input  logic        io_sinkA_bits_needHint,
  input  logic        io_sinkA_bits_dirty,
  input  logic [2:0]  io_sinkA_bits_way,
  input  logic        io_sinkA_bits_meta_dirty,
  input  logic [1:0]  io_sinkA_bits_meta_state,
  input  logic        io_sinkA_bits_meta_clients,
  input  logic [1:0]  io_sinkA_bits_meta_alias,
  input  logic        io_sinkA_bits_meta_prefetch,
  input  logic [2:0]  io_sinkA_bits_meta_prefetchSrc,
  input  logic        io_sinkA_bits_meta_accessed,
  input  logic        io_sinkA_bits_meta_tagErr,
  input  logic        io_sinkA_bits_meta_dataErr,
  input  logic        io_sinkA_bits_metaWen,
  input  logic        io_sinkA_bits_tagWen,
  input  logic        io_sinkA_bits_dsWen,
  input  logic [7:0]  io_sinkA_bits_wayMask,
  input  logic        io_sinkA_bits_replTask,
  input  logic        io_sinkA_bits_cmoTask,
  input  logic        io_sinkA_bits_cmoAll,
  input  logic [4:0]  io_sinkA_bits_reqSource,
  input  logic        io_sinkA_bits_mergeA,
  input  logic [5:0]  io_sinkA_bits_aMergeTask_off,
  input  logic [1:0]  io_sinkA_bits_aMergeTask_alias,
  input  logic [43:0] io_sinkA_bits_aMergeTask_vaddr,
  input  logic        io_sinkA_bits_aMergeTask_isKeyword,
  input  logic [2:0]  io_sinkA_bits_aMergeTask_opcode,
  input  logic [2:0]  io_sinkA_bits_aMergeTask_param,
  input  logic [6:0]  io_sinkA_bits_aMergeTask_sourceId,
  input  logic        io_sinkA_bits_aMergeTask_meta_dirty,
  input  logic [1:0]  io_sinkA_bits_aMergeTask_meta_state,
  input  logic        io_sinkA_bits_aMergeTask_meta_clients,
  input  logic [1:0]  io_sinkA_bits_aMergeTask_meta_alias,
  input  logic        io_sinkA_bits_aMergeTask_meta_prefetch,
  input  logic [2:0]  io_sinkA_bits_aMergeTask_meta_prefetchSrc,
  input  logic        io_sinkA_bits_aMergeTask_meta_accessed,
  input  logic        io_sinkA_bits_aMergeTask_meta_tagErr,
  input  logic        io_sinkA_bits_aMergeTask_meta_dataErr,
  input  logic        io_sinkA_bits_snpHitRelease,
  input  logic        io_sinkA_bits_snpHitReleaseToInval,
  input  logic        io_sinkA_bits_snpHitReleaseToClean,
  input  logic        io_sinkA_bits_snpHitReleaseWithData,
  input  logic [7:0]  io_sinkA_bits_snpHitReleaseIdx,
  input  logic        io_sinkA_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0]  io_sinkA_bits_snpHitReleaseMeta_state,
  input  logic        io_sinkA_bits_snpHitReleaseMeta_clients,
  input  logic [1:0]  io_sinkA_bits_snpHitReleaseMeta_alias,
  input  logic        io_sinkA_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0]  io_sinkA_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic        io_sinkA_bits_snpHitReleaseMeta_accessed,
  input  logic        io_sinkA_bits_snpHitReleaseMeta_tagErr,
  input  logic        io_sinkA_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_sinkA_bits_tgtID,
  input  logic [10:0] io_sinkA_bits_srcID,
  input  logic [11:0] io_sinkA_bits_txnID,
  input  logic [10:0] io_sinkA_bits_homeNID,
  input  logic [11:0] io_sinkA_bits_dbID,
  input  logic [10:0] io_sinkA_bits_fwdNID,
  input  logic [11:0] io_sinkA_bits_fwdTxnID,
  input  logic [6:0]  io_sinkA_bits_chiOpcode,
  input  logic [2:0]  io_sinkA_bits_resp,
  input  logic [2:0]  io_sinkA_bits_fwdState,
  input  logic [3:0]  io_sinkA_bits_pCrdType,
  input  logic        io_sinkA_bits_retToSrc,
  input  logic        io_sinkA_bits_likelyshared,
  input  logic        io_sinkA_bits_expCompAck,
  input  logic        io_sinkA_bits_allowRetry,
  input  logic        io_sinkA_bits_memAttr_allocate,
  input  logic        io_sinkA_bits_memAttr_cacheable,
  input  logic        io_sinkA_bits_memAttr_device,
  input  logic        io_sinkA_bits_memAttr_ewa,
  input  logic        io_sinkA_bits_traceTag,
  input  logic        io_sinkA_bits_dataCheckErr,
  // ---- io.sinkB (Flipped Decoupled TaskBundle) ----
  output logic        io_sinkB_ready,
  input  logic        io_sinkB_valid,
  input  logic [2:0]  io_sinkB_bits_channel,
  input  logic [2:0]  io_sinkB_bits_txChannel,
  input  logic [8:0]  io_sinkB_bits_set,
  input  logic [30:0] io_sinkB_bits_tag,
  input  logic [5:0]  io_sinkB_bits_off,
  input  logic [1:0]  io_sinkB_bits_alias,
  input  logic [43:0] io_sinkB_bits_vaddr,
  input  logic        io_sinkB_bits_isKeyword,
  input  logic [3:0]  io_sinkB_bits_opcode,
  input  logic [2:0]  io_sinkB_bits_param,
  input  logic [2:0]  io_sinkB_bits_size,
  input  logic [6:0]  io_sinkB_bits_sourceId,
  input  logic [1:0]  io_sinkB_bits_bufIdx,
  input  logic        io_sinkB_bits_needProbeAckData,
  input  logic        io_sinkB_bits_denied,
  input  logic        io_sinkB_bits_corrupt,
  input  logic        io_sinkB_bits_mshrTask,
  input  logic [7:0]  io_sinkB_bits_mshrId,
  input  logic        io_sinkB_bits_aliasTask,
  input  logic        io_sinkB_bits_useProbeData,
  input  logic        io_sinkB_bits_mshrRetry,
  input  logic        io_sinkB_bits_readProbeDataDown,
  input  logic        io_sinkB_bits_fromL2pft,
  input  logic        io_sinkB_bits_needHint,
  input  logic        io_sinkB_bits_dirty,
  input  logic [2:0]  io_sinkB_bits_way,
  input  logic        io_sinkB_bits_meta_dirty,
  input  logic [1:0]  io_sinkB_bits_meta_state,
  input  logic        io_sinkB_bits_meta_clients,
  input  logic [1:0]  io_sinkB_bits_meta_alias,
  input  logic        io_sinkB_bits_meta_prefetch,
  input  logic [2:0]  io_sinkB_bits_meta_prefetchSrc,
  input  logic        io_sinkB_bits_meta_accessed,
  input  logic        io_sinkB_bits_meta_tagErr,
  input  logic        io_sinkB_bits_meta_dataErr,
  input  logic        io_sinkB_bits_metaWen,
  input  logic        io_sinkB_bits_tagWen,
  input  logic        io_sinkB_bits_dsWen,
  input  logic [7:0]  io_sinkB_bits_wayMask,
  input  logic        io_sinkB_bits_replTask,
  input  logic        io_sinkB_bits_cmoTask,
  input  logic        io_sinkB_bits_cmoAll,
  input  logic [4:0]  io_sinkB_bits_reqSource,
  input  logic        io_sinkB_bits_mergeA,
  input  logic [5:0]  io_sinkB_bits_aMergeTask_off,
  input  logic [1:0]  io_sinkB_bits_aMergeTask_alias,
  input  logic [43:0] io_sinkB_bits_aMergeTask_vaddr,
  input  logic        io_sinkB_bits_aMergeTask_isKeyword,
  input  logic [2:0]  io_sinkB_bits_aMergeTask_opcode,
  input  logic [2:0]  io_sinkB_bits_aMergeTask_param,
  input  logic [6:0]  io_sinkB_bits_aMergeTask_sourceId,
  input  logic        io_sinkB_bits_aMergeTask_meta_dirty,
  input  logic [1:0]  io_sinkB_bits_aMergeTask_meta_state,
  input  logic        io_sinkB_bits_aMergeTask_meta_clients,
  input  logic [1:0]  io_sinkB_bits_aMergeTask_meta_alias,
  input  logic        io_sinkB_bits_aMergeTask_meta_prefetch,
  input  logic [2:0]  io_sinkB_bits_aMergeTask_meta_prefetchSrc,
  input  logic        io_sinkB_bits_aMergeTask_meta_accessed,
  input  logic        io_sinkB_bits_aMergeTask_meta_tagErr,
  input  logic        io_sinkB_bits_aMergeTask_meta_dataErr,
  input  logic        io_sinkB_bits_snpHitRelease,
  input  logic        io_sinkB_bits_snpHitReleaseToInval,
  input  logic        io_sinkB_bits_snpHitReleaseToClean,
  input  logic        io_sinkB_bits_snpHitReleaseWithData,
  input  logic [7:0]  io_sinkB_bits_snpHitReleaseIdx,
  input  logic        io_sinkB_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0]  io_sinkB_bits_snpHitReleaseMeta_state,
  input  logic        io_sinkB_bits_snpHitReleaseMeta_clients,
  input  logic [1:0]  io_sinkB_bits_snpHitReleaseMeta_alias,
  input  logic        io_sinkB_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0]  io_sinkB_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic        io_sinkB_bits_snpHitReleaseMeta_accessed,
  input  logic        io_sinkB_bits_snpHitReleaseMeta_tagErr,
  input  logic        io_sinkB_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_sinkB_bits_tgtID,
  input  logic [10:0] io_sinkB_bits_srcID,
  input  logic [11:0] io_sinkB_bits_txnID,
  input  logic [10:0] io_sinkB_bits_homeNID,
  input  logic [11:0] io_sinkB_bits_dbID,
  input  logic [10:0] io_sinkB_bits_fwdNID,
  input  logic [11:0] io_sinkB_bits_fwdTxnID,
  input  logic [6:0]  io_sinkB_bits_chiOpcode,
  input  logic [2:0]  io_sinkB_bits_resp,
  input  logic [2:0]  io_sinkB_bits_fwdState,
  input  logic [3:0]  io_sinkB_bits_pCrdType,
  input  logic        io_sinkB_bits_retToSrc,
  input  logic        io_sinkB_bits_likelyshared,
  input  logic        io_sinkB_bits_expCompAck,
  input  logic        io_sinkB_bits_allowRetry,
  input  logic        io_sinkB_bits_memAttr_allocate,
  input  logic        io_sinkB_bits_memAttr_cacheable,
  input  logic        io_sinkB_bits_memAttr_device,
  input  logic        io_sinkB_bits_memAttr_ewa,
  input  logic        io_sinkB_bits_traceTag,
  input  logic        io_sinkB_bits_dataCheckErr,
  // ---- io.sinkC (Flipped Decoupled TaskBundle) ----
  output logic        io_sinkC_ready,
  input  logic        io_sinkC_valid,
  input  logic [2:0]  io_sinkC_bits_channel,
  input  logic [2:0]  io_sinkC_bits_txChannel,
  input  logic [8:0]  io_sinkC_bits_set,
  input  logic [30:0] io_sinkC_bits_tag,
  input  logic [5:0]  io_sinkC_bits_off,
  input  logic [1:0]  io_sinkC_bits_alias,
  input  logic [43:0] io_sinkC_bits_vaddr,
  input  logic        io_sinkC_bits_isKeyword,
  input  logic [3:0]  io_sinkC_bits_opcode,
  input  logic [2:0]  io_sinkC_bits_param,
  input  logic [2:0]  io_sinkC_bits_size,
  input  logic [6:0]  io_sinkC_bits_sourceId,
  input  logic [1:0]  io_sinkC_bits_bufIdx,
  input  logic        io_sinkC_bits_needProbeAckData,
  input  logic        io_sinkC_bits_denied,
  input  logic        io_sinkC_bits_corrupt,
  input  logic        io_sinkC_bits_mshrTask,
  input  logic [7:0]  io_sinkC_bits_mshrId,
  input  logic        io_sinkC_bits_aliasTask,
  input  logic        io_sinkC_bits_useProbeData,
  input  logic        io_sinkC_bits_mshrRetry,
  input  logic        io_sinkC_bits_readProbeDataDown,
  input  logic        io_sinkC_bits_fromL2pft,
  input  logic        io_sinkC_bits_needHint,
  input  logic        io_sinkC_bits_dirty,
  input  logic [2:0]  io_sinkC_bits_way,
  input  logic        io_sinkC_bits_meta_dirty,
  input  logic [1:0]  io_sinkC_bits_meta_state,
  input  logic        io_sinkC_bits_meta_clients,
  input  logic [1:0]  io_sinkC_bits_meta_alias,
  input  logic        io_sinkC_bits_meta_prefetch,
  input  logic [2:0]  io_sinkC_bits_meta_prefetchSrc,
  input  logic        io_sinkC_bits_meta_accessed,
  input  logic        io_sinkC_bits_meta_tagErr,
  input  logic        io_sinkC_bits_meta_dataErr,
  input  logic        io_sinkC_bits_metaWen,
  input  logic        io_sinkC_bits_tagWen,
  input  logic        io_sinkC_bits_dsWen,
  input  logic [7:0]  io_sinkC_bits_wayMask,
  input  logic        io_sinkC_bits_replTask,
  input  logic        io_sinkC_bits_cmoTask,
  input  logic        io_sinkC_bits_cmoAll,
  input  logic [4:0]  io_sinkC_bits_reqSource,
  input  logic        io_sinkC_bits_mergeA,
  input  logic [5:0]  io_sinkC_bits_aMergeTask_off,
  input  logic [1:0]  io_sinkC_bits_aMergeTask_alias,
  input  logic [43:0] io_sinkC_bits_aMergeTask_vaddr,
  input  logic        io_sinkC_bits_aMergeTask_isKeyword,
  input  logic [2:0]  io_sinkC_bits_aMergeTask_opcode,
  input  logic [2:0]  io_sinkC_bits_aMergeTask_param,
  input  logic [6:0]  io_sinkC_bits_aMergeTask_sourceId,
  input  logic        io_sinkC_bits_aMergeTask_meta_dirty,
  input  logic [1:0]  io_sinkC_bits_aMergeTask_meta_state,
  input  logic        io_sinkC_bits_aMergeTask_meta_clients,
  input  logic [1:0]  io_sinkC_bits_aMergeTask_meta_alias,
  input  logic        io_sinkC_bits_aMergeTask_meta_prefetch,
  input  logic [2:0]  io_sinkC_bits_aMergeTask_meta_prefetchSrc,
  input  logic        io_sinkC_bits_aMergeTask_meta_accessed,
  input  logic        io_sinkC_bits_aMergeTask_meta_tagErr,
  input  logic        io_sinkC_bits_aMergeTask_meta_dataErr,
  input  logic        io_sinkC_bits_snpHitRelease,
  input  logic        io_sinkC_bits_snpHitReleaseToInval,
  input  logic        io_sinkC_bits_snpHitReleaseToClean,
  input  logic        io_sinkC_bits_snpHitReleaseWithData,
  input  logic [7:0]  io_sinkC_bits_snpHitReleaseIdx,
  input  logic        io_sinkC_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0]  io_sinkC_bits_snpHitReleaseMeta_state,
  input  logic        io_sinkC_bits_snpHitReleaseMeta_clients,
  input  logic [1:0]  io_sinkC_bits_snpHitReleaseMeta_alias,
  input  logic        io_sinkC_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0]  io_sinkC_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic        io_sinkC_bits_snpHitReleaseMeta_accessed,
  input  logic        io_sinkC_bits_snpHitReleaseMeta_tagErr,
  input  logic        io_sinkC_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_sinkC_bits_tgtID,
  input  logic [10:0] io_sinkC_bits_srcID,
  input  logic [11:0] io_sinkC_bits_txnID,
  input  logic [10:0] io_sinkC_bits_homeNID,
  input  logic [11:0] io_sinkC_bits_dbID,
  input  logic [10:0] io_sinkC_bits_fwdNID,
  input  logic [11:0] io_sinkC_bits_fwdTxnID,
  input  logic [6:0]  io_sinkC_bits_chiOpcode,
  input  logic [2:0]  io_sinkC_bits_resp,
  input  logic [2:0]  io_sinkC_bits_fwdState,
  input  logic [3:0]  io_sinkC_bits_pCrdType,
  input  logic        io_sinkC_bits_retToSrc,
  input  logic        io_sinkC_bits_likelyshared,
  input  logic        io_sinkC_bits_expCompAck,
  input  logic        io_sinkC_bits_allowRetry,
  input  logic        io_sinkC_bits_memAttr_allocate,
  input  logic        io_sinkC_bits_memAttr_cacheable,
  input  logic        io_sinkC_bits_memAttr_device,
  input  logic        io_sinkC_bits_memAttr_ewa,
  input  logic        io_sinkC_bits_traceTag,
  input  logic        io_sinkC_bits_dataCheckErr,
  // ---- io.mshrTask (Flipped Decoupled TaskBundle) ----
  output logic        io_mshrTask_ready,  // (在输出段集中赋值, 此处占位声明顺序)
  input  logic        io_mshrTask_valid,
  input  logic [2:0]  io_mshrTask_bits_channel,
  input  logic [2:0]  io_mshrTask_bits_txChannel,
  input  logic [8:0]  io_mshrTask_bits_set,
  input  logic [30:0] io_mshrTask_bits_tag,
  input  logic [5:0]  io_mshrTask_bits_off,
  input  logic [1:0]  io_mshrTask_bits_alias,
  input  logic [43:0] io_mshrTask_bits_vaddr,
  input  logic        io_mshrTask_bits_isKeyword,
  input  logic [3:0]  io_mshrTask_bits_opcode,
  input  logic [2:0]  io_mshrTask_bits_param,
  input  logic [2:0]  io_mshrTask_bits_size,
  input  logic [6:0]  io_mshrTask_bits_sourceId,
  input  logic [1:0]  io_mshrTask_bits_bufIdx,
  input  logic        io_mshrTask_bits_needProbeAckData,
  input  logic        io_mshrTask_bits_denied,
  input  logic        io_mshrTask_bits_corrupt,
  input  logic        io_mshrTask_bits_mshrTask,
  input  logic [7:0]  io_mshrTask_bits_mshrId,
  input  logic        io_mshrTask_bits_aliasTask,
  input  logic        io_mshrTask_bits_useProbeData,
  input  logic        io_mshrTask_bits_mshrRetry,
  input  logic        io_mshrTask_bits_readProbeDataDown,
  input  logic        io_mshrTask_bits_fromL2pft,
  input  logic        io_mshrTask_bits_needHint,
  input  logic        io_mshrTask_bits_dirty,
  input  logic [2:0]  io_mshrTask_bits_way,
  input  logic        io_mshrTask_bits_meta_dirty,
  input  logic [1:0]  io_mshrTask_bits_meta_state,
  input  logic        io_mshrTask_bits_meta_clients,
  input  logic [1:0]  io_mshrTask_bits_meta_alias,
  input  logic        io_mshrTask_bits_meta_prefetch,
  input  logic [2:0]  io_mshrTask_bits_meta_prefetchSrc,
  input  logic        io_mshrTask_bits_meta_accessed,
  input  logic        io_mshrTask_bits_meta_tagErr,
  input  logic        io_mshrTask_bits_meta_dataErr,
  input  logic        io_mshrTask_bits_metaWen,
  input  logic        io_mshrTask_bits_tagWen,
  input  logic        io_mshrTask_bits_dsWen,
  input  logic [7:0]  io_mshrTask_bits_wayMask,
  input  logic        io_mshrTask_bits_replTask,
  input  logic        io_mshrTask_bits_cmoTask,
  input  logic        io_mshrTask_bits_cmoAll,
  input  logic [4:0]  io_mshrTask_bits_reqSource,
  input  logic        io_mshrTask_bits_mergeA,
  input  logic [5:0]  io_mshrTask_bits_aMergeTask_off,
  input  logic [1:0]  io_mshrTask_bits_aMergeTask_alias,
  input  logic [43:0] io_mshrTask_bits_aMergeTask_vaddr,
  input  logic        io_mshrTask_bits_aMergeTask_isKeyword,
  input  logic [2:0]  io_mshrTask_bits_aMergeTask_opcode,
  input  logic [2:0]  io_mshrTask_bits_aMergeTask_param,
  input  logic [6:0]  io_mshrTask_bits_aMergeTask_sourceId,
  input  logic        io_mshrTask_bits_aMergeTask_meta_dirty,
  input  logic [1:0]  io_mshrTask_bits_aMergeTask_meta_state,
  input  logic        io_mshrTask_bits_aMergeTask_meta_clients,
  input  logic [1:0]  io_mshrTask_bits_aMergeTask_meta_alias,
  input  logic        io_mshrTask_bits_aMergeTask_meta_prefetch,
  input  logic [2:0]  io_mshrTask_bits_aMergeTask_meta_prefetchSrc,
  input  logic        io_mshrTask_bits_aMergeTask_meta_accessed,
  input  logic        io_mshrTask_bits_aMergeTask_meta_tagErr,
  input  logic        io_mshrTask_bits_aMergeTask_meta_dataErr,
  input  logic        io_mshrTask_bits_snpHitRelease,
  input  logic        io_mshrTask_bits_snpHitReleaseToInval,
  input  logic        io_mshrTask_bits_snpHitReleaseToClean,
  input  logic        io_mshrTask_bits_snpHitReleaseWithData,
  input  logic [7:0]  io_mshrTask_bits_snpHitReleaseIdx,
  input  logic        io_mshrTask_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0]  io_mshrTask_bits_snpHitReleaseMeta_state,
  input  logic        io_mshrTask_bits_snpHitReleaseMeta_clients,
  input  logic [1:0]  io_mshrTask_bits_snpHitReleaseMeta_alias,
  input  logic        io_mshrTask_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0]  io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic        io_mshrTask_bits_snpHitReleaseMeta_accessed,
  input  logic        io_mshrTask_bits_snpHitReleaseMeta_tagErr,
  input  logic        io_mshrTask_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0] io_mshrTask_bits_tgtID,
  input  logic [10:0] io_mshrTask_bits_srcID,
  input  logic [11:0] io_mshrTask_bits_txnID,
  input  logic [10:0] io_mshrTask_bits_homeNID,
  input  logic [11:0] io_mshrTask_bits_dbID,
  input  logic [10:0] io_mshrTask_bits_fwdNID,
  input  logic [11:0] io_mshrTask_bits_fwdTxnID,
  input  logic [6:0]  io_mshrTask_bits_chiOpcode,
  input  logic [2:0]  io_mshrTask_bits_resp,
  input  logic [2:0]  io_mshrTask_bits_fwdState,
  input  logic [3:0]  io_mshrTask_bits_pCrdType,
  input  logic        io_mshrTask_bits_retToSrc,
  input  logic        io_mshrTask_bits_likelyshared,
  input  logic        io_mshrTask_bits_expCompAck,
  input  logic        io_mshrTask_bits_allowRetry,
  input  logic        io_mshrTask_bits_memAttr_allocate,
  input  logic        io_mshrTask_bits_memAttr_cacheable,
  input  logic        io_mshrTask_bits_memAttr_device,
  input  logic        io_mshrTask_bits_memAttr_ewa,
  input  logic        io_mshrTask_bits_traceTag,
  input  logic        io_mshrTask_bits_dataCheckErr,
  // ---- 其余控制输入 ----
  input  logic [30:0] io_ATag,
  input  logic [8:0]  io_ASet,
  input  logic        io_dirRead_s1_ready,
  input  logic        io_fromMSHRCtl_blockG_s1,
  input  logic        io_fromMSHRCtl_blockA_s1,
  input  logic        io_fromMSHRCtl_blockB_s1,
  input  logic        io_fromMSHRCtl_blockC_s1,
  input  logic        io_fromMainPipe_blockG_s1,
  input  logic        io_fromMainPipe_blockA_s1,
  input  logic        io_fromMainPipe_blockB_s1,
  input  logic        io_fromMainPipe_blockC_s1,
  input  logic        io_fromGrantBuffer_blockSinkReqEntrance_blockG_s1,
  input  logic        io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1,
  input  logic        io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1,
  input  logic        io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1,
  input  logic        io_fromGrantBuffer_blockMSHRReqEntrance,
  input  logic        io_fromTXDAT_blockMSHRReqEntrance,
  input  logic        io_fromTXDAT_blockSinkBReqEntrance,
  input  logic        io_fromTXRSP_blockMSHRReqEntrance,
  input  logic        io_fromTXRSP_blockSinkBReqEntrance,
  input  logic        io_fromTXREQ_blockMSHRReqEntrance,
  // ---- 输出 ----
  output logic        io_s1Entrance_valid,
  output logic [8:0]  io_s1Entrance_bits_set,
  output logic        io_dirRead_s1_valid,
  output logic [30:0] io_dirRead_s1_bits_tag,
  output logic [8:0]  io_dirRead_s1_bits_set,
  output logic [7:0]  io_dirRead_s1_bits_wayMask,
  output logic [2:0]  io_dirRead_s1_bits_replacerInfo_channel,
  output logic [2:0]  io_dirRead_s1_bits_replacerInfo_opcode,
  output logic [4:0]  io_dirRead_s1_bits_replacerInfo_reqSource,
  output logic        io_dirRead_s1_bits_replacerInfo_refill_prefetch,
  output logic        io_dirRead_s1_bits_refill,
  output logic [7:0]  io_dirRead_s1_bits_mshrId,
  output logic        io_dirRead_s1_bits_cmoAll,
  output logic [2:0]  io_dirRead_s1_bits_cmoWay,
  output logic        io_refillBufRead_s2_valid,
  output logic [7:0]  io_refillBufRead_s2_bits_id,
  output logic        io_releaseBufRead_s2_valid,
  output logic [7:0]  io_releaseBufRead_s2_bits_id,
  output logic [30:0] io_status_s1_tags_0,
  output logic [30:0] io_status_s1_tags_1,
  output logic [30:0] io_status_s1_tags_2,
  output logic [30:0] io_status_s1_tags_3,
  output logic [8:0]  io_status_s1_sets_0,
  output logic [8:0]  io_status_s1_sets_1,
  output logic [8:0]  io_status_s1_sets_2,
  output logic [8:0]  io_status_s1_sets_3,
  output logic        io_status_vec_0_valid,
  output logic [2:0]  io_status_vec_0_bits_channel,
  output logic        io_status_vec_1_valid,
  output logic [2:0]  io_status_vec_1_bits_channel,
  output logic        io_status_vec_toTX_0_valid,
  output logic [2:0]  io_status_vec_toTX_0_bits_channel,
  output logic [2:0]  io_status_vec_toTX_0_bits_txChannel,
  output logic        io_status_vec_toTX_0_bits_mshrTask,
  output logic        io_status_vec_toTX_1_valid,
  output logic [2:0]  io_status_vec_toTX_1_bits_channel,
  output logic [2:0]  io_status_vec_toTX_1_bits_txChannel,
  output logic        io_status_vec_toTX_1_bits_mshrTask,
  // taskToPipe_s2 (= task_s2 全字段)
  output logic        io_taskToPipe_s2_valid,
  output logic [2:0]  io_taskToPipe_s2_bits_channel,
  output logic [2:0]  io_taskToPipe_s2_bits_txChannel,
  output logic [8:0]  io_taskToPipe_s2_bits_set,
  output logic [30:0] io_taskToPipe_s2_bits_tag,
  output logic [5:0]  io_taskToPipe_s2_bits_off,
  output logic [1:0]  io_taskToPipe_s2_bits_alias,
  output logic [43:0] io_taskToPipe_s2_bits_vaddr,
  output logic        io_taskToPipe_s2_bits_isKeyword,
  output logic [3:0]  io_taskToPipe_s2_bits_opcode,
  output logic [2:0]  io_taskToPipe_s2_bits_param,
  output logic [2:0]  io_taskToPipe_s2_bits_size,
  output logic [6:0]  io_taskToPipe_s2_bits_sourceId,
  output logic [1:0]  io_taskToPipe_s2_bits_bufIdx,
  output logic        io_taskToPipe_s2_bits_needProbeAckData,
  output logic        io_taskToPipe_s2_bits_denied,
  output logic        io_taskToPipe_s2_bits_corrupt,
  output logic        io_taskToPipe_s2_bits_mshrTask,
  output logic [7:0]  io_taskToPipe_s2_bits_mshrId,
  output logic        io_taskToPipe_s2_bits_aliasTask,
  output logic        io_taskToPipe_s2_bits_useProbeData,
  output logic        io_taskToPipe_s2_bits_mshrRetry,
  output logic        io_taskToPipe_s2_bits_readProbeDataDown,
  output logic        io_taskToPipe_s2_bits_fromL2pft,
  output logic        io_taskToPipe_s2_bits_needHint,
  output logic        io_taskToPipe_s2_bits_dirty,
  output logic [2:0]  io_taskToPipe_s2_bits_way,
  output logic        io_taskToPipe_s2_bits_meta_dirty,
  output logic [1:0]  io_taskToPipe_s2_bits_meta_state,
  output logic        io_taskToPipe_s2_bits_meta_clients,
  output logic [1:0]  io_taskToPipe_s2_bits_meta_alias,
  output logic        io_taskToPipe_s2_bits_meta_prefetch,
  output logic [2:0]  io_taskToPipe_s2_bits_meta_prefetchSrc,
  output logic        io_taskToPipe_s2_bits_meta_accessed,
  output logic        io_taskToPipe_s2_bits_meta_tagErr,
  output logic        io_taskToPipe_s2_bits_meta_dataErr,
  output logic        io_taskToPipe_s2_bits_metaWen,
  output logic        io_taskToPipe_s2_bits_tagWen,
  output logic        io_taskToPipe_s2_bits_dsWen,
  output logic [7:0]  io_taskToPipe_s2_bits_wayMask,
  output logic        io_taskToPipe_s2_bits_replTask,
  output logic        io_taskToPipe_s2_bits_cmoTask,
  output logic        io_taskToPipe_s2_bits_cmoAll,
  output logic [4:0]  io_taskToPipe_s2_bits_reqSource,
  output logic        io_taskToPipe_s2_bits_mergeA,
  output logic [5:0]  io_taskToPipe_s2_bits_aMergeTask_off,
  output logic [1:0]  io_taskToPipe_s2_bits_aMergeTask_alias,
  output logic [43:0] io_taskToPipe_s2_bits_aMergeTask_vaddr,
  output logic        io_taskToPipe_s2_bits_aMergeTask_isKeyword,
  output logic [2:0]  io_taskToPipe_s2_bits_aMergeTask_opcode,
  output logic [2:0]  io_taskToPipe_s2_bits_aMergeTask_param,
  output logic [6:0]  io_taskToPipe_s2_bits_aMergeTask_sourceId,
  output logic        io_taskToPipe_s2_bits_aMergeTask_meta_dirty,
  output logic [1:0]  io_taskToPipe_s2_bits_aMergeTask_meta_state,
  output logic        io_taskToPipe_s2_bits_aMergeTask_meta_clients,
  output logic [1:0]  io_taskToPipe_s2_bits_aMergeTask_meta_alias,
  output logic        io_taskToPipe_s2_bits_aMergeTask_meta_prefetch,
  output logic [2:0]  io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc,
  output logic        io_taskToPipe_s2_bits_aMergeTask_meta_accessed,
  output logic        io_taskToPipe_s2_bits_aMergeTask_meta_tagErr,
  output logic        io_taskToPipe_s2_bits_aMergeTask_meta_dataErr,
  output logic        io_taskToPipe_s2_bits_snpHitRelease,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseToInval,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseToClean,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseWithData,
  output logic [7:0]  io_taskToPipe_s2_bits_snpHitReleaseIdx,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty,
  output logic [1:0]  io_taskToPipe_s2_bits_snpHitReleaseMeta_state,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseMeta_clients,
  output logic [1:0]  io_taskToPipe_s2_bits_snpHitReleaseMeta_alias,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0]  io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr,
  output logic        io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_taskToPipe_s2_bits_tgtID,
  output logic [10:0] io_taskToPipe_s2_bits_srcID,
  output logic [11:0] io_taskToPipe_s2_bits_txnID,
  output logic [10:0] io_taskToPipe_s2_bits_homeNID,
  output logic [11:0] io_taskToPipe_s2_bits_dbID,
  output logic [10:0] io_taskToPipe_s2_bits_fwdNID,
  output logic [11:0] io_taskToPipe_s2_bits_fwdTxnID,
  output logic [6:0]  io_taskToPipe_s2_bits_chiOpcode,
  output logic [2:0]  io_taskToPipe_s2_bits_resp,
  output logic [2:0]  io_taskToPipe_s2_bits_fwdState,
  output logic [3:0]  io_taskToPipe_s2_bits_pCrdType,
  output logic        io_taskToPipe_s2_bits_retToSrc,
  output logic        io_taskToPipe_s2_bits_likelyshared,
  output logic        io_taskToPipe_s2_bits_expCompAck,
  output logic        io_taskToPipe_s2_bits_allowRetry,
  output logic        io_taskToPipe_s2_bits_memAttr_allocate,
  output logic        io_taskToPipe_s2_bits_memAttr_cacheable,
  output logic        io_taskToPipe_s2_bits_memAttr_device,
  output logic        io_taskToPipe_s2_bits_memAttr_ewa,
  output logic        io_taskToPipe_s2_bits_traceTag,
  output logic        io_taskToPipe_s2_bits_dataCheckErr,
  // taskInfo_s1 (= task_s1 全字段)
  output logic        io_taskInfo_s1_valid,
  output logic [2:0]  io_taskInfo_s1_bits_channel,
  output logic [2:0]  io_taskInfo_s1_bits_txChannel,
  output logic [8:0]  io_taskInfo_s1_bits_set,
  output logic [30:0] io_taskInfo_s1_bits_tag,
  output logic [5:0]  io_taskInfo_s1_bits_off,
  output logic [1:0]  io_taskInfo_s1_bits_alias,
  output logic [43:0] io_taskInfo_s1_bits_vaddr,
  output logic        io_taskInfo_s1_bits_isKeyword,
  output logic [3:0]  io_taskInfo_s1_bits_opcode,
  output logic [2:0]  io_taskInfo_s1_bits_param,
  output logic [2:0]  io_taskInfo_s1_bits_size,
  output logic [6:0]  io_taskInfo_s1_bits_sourceId,
  output logic [1:0]  io_taskInfo_s1_bits_bufIdx,
  output logic        io_taskInfo_s1_bits_needProbeAckData,
  output logic        io_taskInfo_s1_bits_denied,
  output logic        io_taskInfo_s1_bits_corrupt,
  output logic        io_taskInfo_s1_bits_mshrTask,
  output logic [7:0]  io_taskInfo_s1_bits_mshrId,
  output logic        io_taskInfo_s1_bits_aliasTask,
  output logic        io_taskInfo_s1_bits_useProbeData,
  output logic        io_taskInfo_s1_bits_mshrRetry,
  output logic        io_taskInfo_s1_bits_readProbeDataDown,
  output logic        io_taskInfo_s1_bits_fromL2pft,
  output logic        io_taskInfo_s1_bits_needHint,
  output logic        io_taskInfo_s1_bits_dirty,
  output logic [2:0]  io_taskInfo_s1_bits_way,
  output logic        io_taskInfo_s1_bits_meta_dirty,
  output logic [1:0]  io_taskInfo_s1_bits_meta_state,
  output logic        io_taskInfo_s1_bits_meta_clients,
  output logic [1:0]  io_taskInfo_s1_bits_meta_alias,
  output logic        io_taskInfo_s1_bits_meta_prefetch,
  output logic [2:0]  io_taskInfo_s1_bits_meta_prefetchSrc,
  output logic        io_taskInfo_s1_bits_meta_accessed,
  output logic        io_taskInfo_s1_bits_meta_tagErr,
  output logic        io_taskInfo_s1_bits_meta_dataErr,
  output logic        io_taskInfo_s1_bits_metaWen,
  output logic        io_taskInfo_s1_bits_tagWen,
  output logic        io_taskInfo_s1_bits_dsWen,
  output logic [7:0]  io_taskInfo_s1_bits_wayMask,
  output logic        io_taskInfo_s1_bits_replTask,
  output logic        io_taskInfo_s1_bits_cmoTask,
  output logic        io_taskInfo_s1_bits_cmoAll,
  output logic [4:0]  io_taskInfo_s1_bits_reqSource,
  output logic        io_taskInfo_s1_bits_mergeA,
  output logic [5:0]  io_taskInfo_s1_bits_aMergeTask_off,
  output logic [1:0]  io_taskInfo_s1_bits_aMergeTask_alias,
  output logic [43:0] io_taskInfo_s1_bits_aMergeTask_vaddr,
  output logic        io_taskInfo_s1_bits_aMergeTask_isKeyword,
  output logic [2:0]  io_taskInfo_s1_bits_aMergeTask_opcode,
  output logic [2:0]  io_taskInfo_s1_bits_aMergeTask_param,
  output logic [6:0]  io_taskInfo_s1_bits_aMergeTask_sourceId,
  output logic        io_taskInfo_s1_bits_aMergeTask_meta_dirty,
  output logic [1:0]  io_taskInfo_s1_bits_aMergeTask_meta_state,
  output logic        io_taskInfo_s1_bits_aMergeTask_meta_clients,
  output logic [1:0]  io_taskInfo_s1_bits_aMergeTask_meta_alias,
  output logic        io_taskInfo_s1_bits_aMergeTask_meta_prefetch,
  output logic [2:0]  io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc,
  output logic        io_taskInfo_s1_bits_aMergeTask_meta_accessed,
  output logic        io_taskInfo_s1_bits_aMergeTask_meta_tagErr,
  output logic        io_taskInfo_s1_bits_aMergeTask_meta_dataErr,
  output logic        io_taskInfo_s1_bits_snpHitRelease,
  output logic        io_taskInfo_s1_bits_snpHitReleaseToInval,
  output logic        io_taskInfo_s1_bits_snpHitReleaseToClean,
  output logic        io_taskInfo_s1_bits_snpHitReleaseWithData,
  output logic [7:0]  io_taskInfo_s1_bits_snpHitReleaseIdx,
  output logic        io_taskInfo_s1_bits_snpHitReleaseMeta_dirty,
  output logic [1:0]  io_taskInfo_s1_bits_snpHitReleaseMeta_state,
  output logic        io_taskInfo_s1_bits_snpHitReleaseMeta_clients,
  output logic [1:0]  io_taskInfo_s1_bits_snpHitReleaseMeta_alias,
  output logic        io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0]  io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc,
  output logic        io_taskInfo_s1_bits_snpHitReleaseMeta_accessed,
  output logic        io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr,
  output logic        io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0] io_taskInfo_s1_bits_tgtID,
  output logic [10:0] io_taskInfo_s1_bits_srcID,
  output logic [11:0] io_taskInfo_s1_bits_txnID,
  output logic [10:0] io_taskInfo_s1_bits_homeNID,
  output logic [11:0] io_taskInfo_s1_bits_dbID,
  output logic [10:0] io_taskInfo_s1_bits_fwdNID,
  output logic [11:0] io_taskInfo_s1_bits_fwdTxnID,
  output logic [6:0]  io_taskInfo_s1_bits_chiOpcode,
  output logic [2:0]  io_taskInfo_s1_bits_resp,
  output logic [2:0]  io_taskInfo_s1_bits_fwdState,
  output logic [3:0]  io_taskInfo_s1_bits_pCrdType,
  output logic        io_taskInfo_s1_bits_retToSrc,
  output logic        io_taskInfo_s1_bits_likelyshared,
  output logic        io_taskInfo_s1_bits_expCompAck,
  output logic        io_taskInfo_s1_bits_allowRetry,
  output logic        io_taskInfo_s1_bits_memAttr_allocate,
  output logic        io_taskInfo_s1_bits_memAttr_cacheable,
  output logic        io_taskInfo_s1_bits_memAttr_device,
  output logic        io_taskInfo_s1_bits_memAttr_ewa,
  output logic        io_taskInfo_s1_bits_traceTag,
  output logic        io_taskInfo_s1_bits_dataCheckErr
);

  // ===== 打包扁平通道/MSHR 输入为 TaskBundle 结构体 =====
  task_bundle_t A_task;
  always_comb begin
    A_task.channel                = io_sinkA_bits_channel;
    A_task.txChannel              = io_sinkA_bits_txChannel;
    A_task.set                    = io_sinkA_bits_set;
    A_task.tag                    = io_sinkA_bits_tag;
    A_task.off                    = io_sinkA_bits_off;
    A_task.alias_                 = io_sinkA_bits_alias;
    A_task.vaddr                  = io_sinkA_bits_vaddr;
    A_task.isKeyword              = io_sinkA_bits_isKeyword;
    A_task.opcode                 = io_sinkA_bits_opcode;
    A_task.param                  = io_sinkA_bits_param;
    A_task.size                   = io_sinkA_bits_size;
    A_task.sourceId               = io_sinkA_bits_sourceId;
    A_task.bufIdx                 = io_sinkA_bits_bufIdx;
    A_task.needProbeAckData       = io_sinkA_bits_needProbeAckData;
    A_task.denied                 = io_sinkA_bits_denied;
    A_task.corrupt                = io_sinkA_bits_corrupt;
    A_task.mshrTask               = io_sinkA_bits_mshrTask;
    A_task.mshrId                 = io_sinkA_bits_mshrId;
    A_task.aliasTask              = io_sinkA_bits_aliasTask;
    A_task.useProbeData           = io_sinkA_bits_useProbeData;
    A_task.mshrRetry              = io_sinkA_bits_mshrRetry;
    A_task.readProbeDataDown      = io_sinkA_bits_readProbeDataDown;
    A_task.fromL2pft              = io_sinkA_bits_fromL2pft;
    A_task.needHint               = io_sinkA_bits_needHint;
    A_task.dirty                  = io_sinkA_bits_dirty;
    A_task.way                    = io_sinkA_bits_way;
    A_task.meta_dirty             = io_sinkA_bits_meta_dirty;
    A_task.meta_state             = io_sinkA_bits_meta_state;
    A_task.meta_clients           = io_sinkA_bits_meta_clients;
    A_task.meta_alias             = io_sinkA_bits_meta_alias;
    A_task.meta_prefetch          = io_sinkA_bits_meta_prefetch;
    A_task.meta_prefetchSrc       = io_sinkA_bits_meta_prefetchSrc;
    A_task.meta_accessed          = io_sinkA_bits_meta_accessed;
    A_task.meta_tagErr            = io_sinkA_bits_meta_tagErr;
    A_task.meta_dataErr           = io_sinkA_bits_meta_dataErr;
    A_task.metaWen                = io_sinkA_bits_metaWen;
    A_task.tagWen                 = io_sinkA_bits_tagWen;
    A_task.dsWen                  = io_sinkA_bits_dsWen;
    A_task.wayMask                = io_sinkA_bits_wayMask;
    A_task.replTask               = io_sinkA_bits_replTask;
    A_task.cmoTask                = io_sinkA_bits_cmoTask;
    A_task.cmoAll                 = io_sinkA_bits_cmoAll;
    A_task.reqSource              = io_sinkA_bits_reqSource;
    A_task.mergeA                 = io_sinkA_bits_mergeA;
    A_task.aMergeTask_off         = io_sinkA_bits_aMergeTask_off;
    A_task.aMergeTask_alias       = io_sinkA_bits_aMergeTask_alias;
    A_task.aMergeTask_vaddr       = io_sinkA_bits_aMergeTask_vaddr;
    A_task.aMergeTask_isKeyword   = io_sinkA_bits_aMergeTask_isKeyword;
    A_task.aMergeTask_opcode      = io_sinkA_bits_aMergeTask_opcode;
    A_task.aMergeTask_param       = io_sinkA_bits_aMergeTask_param;
    A_task.aMergeTask_sourceId    = io_sinkA_bits_aMergeTask_sourceId;
    A_task.aMergeTask_meta_dirty  = io_sinkA_bits_aMergeTask_meta_dirty;
    A_task.aMergeTask_meta_state  = io_sinkA_bits_aMergeTask_meta_state;
    A_task.aMergeTask_meta_clients = io_sinkA_bits_aMergeTask_meta_clients;
    A_task.aMergeTask_meta_alias  = io_sinkA_bits_aMergeTask_meta_alias;
    A_task.aMergeTask_meta_prefetch = io_sinkA_bits_aMergeTask_meta_prefetch;
    A_task.aMergeTask_meta_prefetchSrc = io_sinkA_bits_aMergeTask_meta_prefetchSrc;
    A_task.aMergeTask_meta_accessed = io_sinkA_bits_aMergeTask_meta_accessed;
    A_task.aMergeTask_meta_tagErr = io_sinkA_bits_aMergeTask_meta_tagErr;
    A_task.aMergeTask_meta_dataErr = io_sinkA_bits_aMergeTask_meta_dataErr;
    A_task.snpHitRelease          = io_sinkA_bits_snpHitRelease;
    A_task.snpHitReleaseToInval   = io_sinkA_bits_snpHitReleaseToInval;
    A_task.snpHitReleaseToClean   = io_sinkA_bits_snpHitReleaseToClean;
    A_task.snpHitReleaseWithData  = io_sinkA_bits_snpHitReleaseWithData;
    A_task.snpHitReleaseIdx       = io_sinkA_bits_snpHitReleaseIdx;
    A_task.snpHitReleaseMeta_dirty = io_sinkA_bits_snpHitReleaseMeta_dirty;
    A_task.snpHitReleaseMeta_state = io_sinkA_bits_snpHitReleaseMeta_state;
    A_task.snpHitReleaseMeta_clients = io_sinkA_bits_snpHitReleaseMeta_clients;
    A_task.snpHitReleaseMeta_alias = io_sinkA_bits_snpHitReleaseMeta_alias;
    A_task.snpHitReleaseMeta_prefetch = io_sinkA_bits_snpHitReleaseMeta_prefetch;
    A_task.snpHitReleaseMeta_prefetchSrc = io_sinkA_bits_snpHitReleaseMeta_prefetchSrc;
    A_task.snpHitReleaseMeta_accessed = io_sinkA_bits_snpHitReleaseMeta_accessed;
    A_task.snpHitReleaseMeta_tagErr = io_sinkA_bits_snpHitReleaseMeta_tagErr;
    A_task.snpHitReleaseMeta_dataErr = io_sinkA_bits_snpHitReleaseMeta_dataErr;
    A_task.tgtID                  = io_sinkA_bits_tgtID;
    A_task.srcID                  = io_sinkA_bits_srcID;
    A_task.txnID                  = io_sinkA_bits_txnID;
    A_task.homeNID                = io_sinkA_bits_homeNID;
    A_task.dbID                   = io_sinkA_bits_dbID;
    A_task.fwdNID                 = io_sinkA_bits_fwdNID;
    A_task.fwdTxnID               = io_sinkA_bits_fwdTxnID;
    A_task.chiOpcode              = io_sinkA_bits_chiOpcode;
    A_task.resp                   = io_sinkA_bits_resp;
    A_task.fwdState               = io_sinkA_bits_fwdState;
    A_task.pCrdType               = io_sinkA_bits_pCrdType;
    A_task.retToSrc               = io_sinkA_bits_retToSrc;
    A_task.likelyshared           = io_sinkA_bits_likelyshared;
    A_task.expCompAck             = io_sinkA_bits_expCompAck;
    A_task.allowRetry             = io_sinkA_bits_allowRetry;
    A_task.memAttr_allocate       = io_sinkA_bits_memAttr_allocate;
    A_task.memAttr_cacheable      = io_sinkA_bits_memAttr_cacheable;
    A_task.memAttr_device         = io_sinkA_bits_memAttr_device;
    A_task.memAttr_ewa            = io_sinkA_bits_memAttr_ewa;
    A_task.traceTag               = io_sinkA_bits_traceTag;
    A_task.dataCheckErr           = io_sinkA_bits_dataCheckErr;
  end
  task_bundle_t B_task;
  always_comb begin
    B_task.channel                = io_sinkB_bits_channel;
    B_task.txChannel              = io_sinkB_bits_txChannel;
    B_task.set                    = io_sinkB_bits_set;
    B_task.tag                    = io_sinkB_bits_tag;
    B_task.off                    = io_sinkB_bits_off;
    B_task.alias_                 = io_sinkB_bits_alias;
    B_task.vaddr                  = io_sinkB_bits_vaddr;
    B_task.isKeyword              = io_sinkB_bits_isKeyword;
    B_task.opcode                 = io_sinkB_bits_opcode;
    B_task.param                  = io_sinkB_bits_param;
    B_task.size                   = io_sinkB_bits_size;
    B_task.sourceId               = io_sinkB_bits_sourceId;
    B_task.bufIdx                 = io_sinkB_bits_bufIdx;
    B_task.needProbeAckData       = io_sinkB_bits_needProbeAckData;
    B_task.denied                 = io_sinkB_bits_denied;
    B_task.corrupt                = io_sinkB_bits_corrupt;
    B_task.mshrTask               = io_sinkB_bits_mshrTask;
    B_task.mshrId                 = io_sinkB_bits_mshrId;
    B_task.aliasTask              = io_sinkB_bits_aliasTask;
    B_task.useProbeData           = io_sinkB_bits_useProbeData;
    B_task.mshrRetry              = io_sinkB_bits_mshrRetry;
    B_task.readProbeDataDown      = io_sinkB_bits_readProbeDataDown;
    B_task.fromL2pft              = io_sinkB_bits_fromL2pft;
    B_task.needHint               = io_sinkB_bits_needHint;
    B_task.dirty                  = io_sinkB_bits_dirty;
    B_task.way                    = io_sinkB_bits_way;
    B_task.meta_dirty             = io_sinkB_bits_meta_dirty;
    B_task.meta_state             = io_sinkB_bits_meta_state;
    B_task.meta_clients           = io_sinkB_bits_meta_clients;
    B_task.meta_alias             = io_sinkB_bits_meta_alias;
    B_task.meta_prefetch          = io_sinkB_bits_meta_prefetch;
    B_task.meta_prefetchSrc       = io_sinkB_bits_meta_prefetchSrc;
    B_task.meta_accessed          = io_sinkB_bits_meta_accessed;
    B_task.meta_tagErr            = io_sinkB_bits_meta_tagErr;
    B_task.meta_dataErr           = io_sinkB_bits_meta_dataErr;
    B_task.metaWen                = io_sinkB_bits_metaWen;
    B_task.tagWen                 = io_sinkB_bits_tagWen;
    B_task.dsWen                  = io_sinkB_bits_dsWen;
    B_task.wayMask                = io_sinkB_bits_wayMask;
    B_task.replTask               = io_sinkB_bits_replTask;
    B_task.cmoTask                = io_sinkB_bits_cmoTask;
    B_task.cmoAll                 = io_sinkB_bits_cmoAll;
    B_task.reqSource              = io_sinkB_bits_reqSource;
    B_task.mergeA                 = io_sinkB_bits_mergeA;
    B_task.aMergeTask_off         = io_sinkB_bits_aMergeTask_off;
    B_task.aMergeTask_alias       = io_sinkB_bits_aMergeTask_alias;
    B_task.aMergeTask_vaddr       = io_sinkB_bits_aMergeTask_vaddr;
    B_task.aMergeTask_isKeyword   = io_sinkB_bits_aMergeTask_isKeyword;
    B_task.aMergeTask_opcode      = io_sinkB_bits_aMergeTask_opcode;
    B_task.aMergeTask_param       = io_sinkB_bits_aMergeTask_param;
    B_task.aMergeTask_sourceId    = io_sinkB_bits_aMergeTask_sourceId;
    B_task.aMergeTask_meta_dirty  = io_sinkB_bits_aMergeTask_meta_dirty;
    B_task.aMergeTask_meta_state  = io_sinkB_bits_aMergeTask_meta_state;
    B_task.aMergeTask_meta_clients = io_sinkB_bits_aMergeTask_meta_clients;
    B_task.aMergeTask_meta_alias  = io_sinkB_bits_aMergeTask_meta_alias;
    B_task.aMergeTask_meta_prefetch = io_sinkB_bits_aMergeTask_meta_prefetch;
    B_task.aMergeTask_meta_prefetchSrc = io_sinkB_bits_aMergeTask_meta_prefetchSrc;
    B_task.aMergeTask_meta_accessed = io_sinkB_bits_aMergeTask_meta_accessed;
    B_task.aMergeTask_meta_tagErr = io_sinkB_bits_aMergeTask_meta_tagErr;
    B_task.aMergeTask_meta_dataErr = io_sinkB_bits_aMergeTask_meta_dataErr;
    B_task.snpHitRelease          = io_sinkB_bits_snpHitRelease;
    B_task.snpHitReleaseToInval   = io_sinkB_bits_snpHitReleaseToInval;
    B_task.snpHitReleaseToClean   = io_sinkB_bits_snpHitReleaseToClean;
    B_task.snpHitReleaseWithData  = io_sinkB_bits_snpHitReleaseWithData;
    B_task.snpHitReleaseIdx       = io_sinkB_bits_snpHitReleaseIdx;
    B_task.snpHitReleaseMeta_dirty = io_sinkB_bits_snpHitReleaseMeta_dirty;
    B_task.snpHitReleaseMeta_state = io_sinkB_bits_snpHitReleaseMeta_state;
    B_task.snpHitReleaseMeta_clients = io_sinkB_bits_snpHitReleaseMeta_clients;
    B_task.snpHitReleaseMeta_alias = io_sinkB_bits_snpHitReleaseMeta_alias;
    B_task.snpHitReleaseMeta_prefetch = io_sinkB_bits_snpHitReleaseMeta_prefetch;
    B_task.snpHitReleaseMeta_prefetchSrc = io_sinkB_bits_snpHitReleaseMeta_prefetchSrc;
    B_task.snpHitReleaseMeta_accessed = io_sinkB_bits_snpHitReleaseMeta_accessed;
    B_task.snpHitReleaseMeta_tagErr = io_sinkB_bits_snpHitReleaseMeta_tagErr;
    B_task.snpHitReleaseMeta_dataErr = io_sinkB_bits_snpHitReleaseMeta_dataErr;
    B_task.tgtID                  = io_sinkB_bits_tgtID;
    B_task.srcID                  = io_sinkB_bits_srcID;
    B_task.txnID                  = io_sinkB_bits_txnID;
    B_task.homeNID                = io_sinkB_bits_homeNID;
    B_task.dbID                   = io_sinkB_bits_dbID;
    B_task.fwdNID                 = io_sinkB_bits_fwdNID;
    B_task.fwdTxnID               = io_sinkB_bits_fwdTxnID;
    B_task.chiOpcode              = io_sinkB_bits_chiOpcode;
    B_task.resp                   = io_sinkB_bits_resp;
    B_task.fwdState               = io_sinkB_bits_fwdState;
    B_task.pCrdType               = io_sinkB_bits_pCrdType;
    B_task.retToSrc               = io_sinkB_bits_retToSrc;
    B_task.likelyshared           = io_sinkB_bits_likelyshared;
    B_task.expCompAck             = io_sinkB_bits_expCompAck;
    B_task.allowRetry             = io_sinkB_bits_allowRetry;
    B_task.memAttr_allocate       = io_sinkB_bits_memAttr_allocate;
    B_task.memAttr_cacheable      = io_sinkB_bits_memAttr_cacheable;
    B_task.memAttr_device         = io_sinkB_bits_memAttr_device;
    B_task.memAttr_ewa            = io_sinkB_bits_memAttr_ewa;
    B_task.traceTag               = io_sinkB_bits_traceTag;
    B_task.dataCheckErr           = io_sinkB_bits_dataCheckErr;
  end
  task_bundle_t C_task;
  always_comb begin
    C_task.channel                = io_sinkC_bits_channel;
    C_task.txChannel              = io_sinkC_bits_txChannel;
    C_task.set                    = io_sinkC_bits_set;
    C_task.tag                    = io_sinkC_bits_tag;
    C_task.off                    = io_sinkC_bits_off;
    C_task.alias_                 = io_sinkC_bits_alias;
    C_task.vaddr                  = io_sinkC_bits_vaddr;
    C_task.isKeyword              = io_sinkC_bits_isKeyword;
    C_task.opcode                 = io_sinkC_bits_opcode;
    C_task.param                  = io_sinkC_bits_param;
    C_task.size                   = io_sinkC_bits_size;
    C_task.sourceId               = io_sinkC_bits_sourceId;
    C_task.bufIdx                 = io_sinkC_bits_bufIdx;
    C_task.needProbeAckData       = io_sinkC_bits_needProbeAckData;
    C_task.denied                 = io_sinkC_bits_denied;
    C_task.corrupt                = io_sinkC_bits_corrupt;
    C_task.mshrTask               = io_sinkC_bits_mshrTask;
    C_task.mshrId                 = io_sinkC_bits_mshrId;
    C_task.aliasTask              = io_sinkC_bits_aliasTask;
    C_task.useProbeData           = io_sinkC_bits_useProbeData;
    C_task.mshrRetry              = io_sinkC_bits_mshrRetry;
    C_task.readProbeDataDown      = io_sinkC_bits_readProbeDataDown;
    C_task.fromL2pft              = io_sinkC_bits_fromL2pft;
    C_task.needHint               = io_sinkC_bits_needHint;
    C_task.dirty                  = io_sinkC_bits_dirty;
    C_task.way                    = io_sinkC_bits_way;
    C_task.meta_dirty             = io_sinkC_bits_meta_dirty;
    C_task.meta_state             = io_sinkC_bits_meta_state;
    C_task.meta_clients           = io_sinkC_bits_meta_clients;
    C_task.meta_alias             = io_sinkC_bits_meta_alias;
    C_task.meta_prefetch          = io_sinkC_bits_meta_prefetch;
    C_task.meta_prefetchSrc       = io_sinkC_bits_meta_prefetchSrc;
    C_task.meta_accessed          = io_sinkC_bits_meta_accessed;
    C_task.meta_tagErr            = io_sinkC_bits_meta_tagErr;
    C_task.meta_dataErr           = io_sinkC_bits_meta_dataErr;
    C_task.metaWen                = io_sinkC_bits_metaWen;
    C_task.tagWen                 = io_sinkC_bits_tagWen;
    C_task.dsWen                  = io_sinkC_bits_dsWen;
    C_task.wayMask                = io_sinkC_bits_wayMask;
    C_task.replTask               = io_sinkC_bits_replTask;
    C_task.cmoTask                = io_sinkC_bits_cmoTask;
    C_task.cmoAll                 = io_sinkC_bits_cmoAll;
    C_task.reqSource              = io_sinkC_bits_reqSource;
    C_task.mergeA                 = io_sinkC_bits_mergeA;
    C_task.aMergeTask_off         = io_sinkC_bits_aMergeTask_off;
    C_task.aMergeTask_alias       = io_sinkC_bits_aMergeTask_alias;
    C_task.aMergeTask_vaddr       = io_sinkC_bits_aMergeTask_vaddr;
    C_task.aMergeTask_isKeyword   = io_sinkC_bits_aMergeTask_isKeyword;
    C_task.aMergeTask_opcode      = io_sinkC_bits_aMergeTask_opcode;
    C_task.aMergeTask_param       = io_sinkC_bits_aMergeTask_param;
    C_task.aMergeTask_sourceId    = io_sinkC_bits_aMergeTask_sourceId;
    C_task.aMergeTask_meta_dirty  = io_sinkC_bits_aMergeTask_meta_dirty;
    C_task.aMergeTask_meta_state  = io_sinkC_bits_aMergeTask_meta_state;
    C_task.aMergeTask_meta_clients = io_sinkC_bits_aMergeTask_meta_clients;
    C_task.aMergeTask_meta_alias  = io_sinkC_bits_aMergeTask_meta_alias;
    C_task.aMergeTask_meta_prefetch = io_sinkC_bits_aMergeTask_meta_prefetch;
    C_task.aMergeTask_meta_prefetchSrc = io_sinkC_bits_aMergeTask_meta_prefetchSrc;
    C_task.aMergeTask_meta_accessed = io_sinkC_bits_aMergeTask_meta_accessed;
    C_task.aMergeTask_meta_tagErr = io_sinkC_bits_aMergeTask_meta_tagErr;
    C_task.aMergeTask_meta_dataErr = io_sinkC_bits_aMergeTask_meta_dataErr;
    C_task.snpHitRelease          = io_sinkC_bits_snpHitRelease;
    C_task.snpHitReleaseToInval   = io_sinkC_bits_snpHitReleaseToInval;
    C_task.snpHitReleaseToClean   = io_sinkC_bits_snpHitReleaseToClean;
    C_task.snpHitReleaseWithData  = io_sinkC_bits_snpHitReleaseWithData;
    C_task.snpHitReleaseIdx       = io_sinkC_bits_snpHitReleaseIdx;
    C_task.snpHitReleaseMeta_dirty = io_sinkC_bits_snpHitReleaseMeta_dirty;
    C_task.snpHitReleaseMeta_state = io_sinkC_bits_snpHitReleaseMeta_state;
    C_task.snpHitReleaseMeta_clients = io_sinkC_bits_snpHitReleaseMeta_clients;
    C_task.snpHitReleaseMeta_alias = io_sinkC_bits_snpHitReleaseMeta_alias;
    C_task.snpHitReleaseMeta_prefetch = io_sinkC_bits_snpHitReleaseMeta_prefetch;
    C_task.snpHitReleaseMeta_prefetchSrc = io_sinkC_bits_snpHitReleaseMeta_prefetchSrc;
    C_task.snpHitReleaseMeta_accessed = io_sinkC_bits_snpHitReleaseMeta_accessed;
    C_task.snpHitReleaseMeta_tagErr = io_sinkC_bits_snpHitReleaseMeta_tagErr;
    C_task.snpHitReleaseMeta_dataErr = io_sinkC_bits_snpHitReleaseMeta_dataErr;
    C_task.tgtID                  = io_sinkC_bits_tgtID;
    C_task.srcID                  = io_sinkC_bits_srcID;
    C_task.txnID                  = io_sinkC_bits_txnID;
    C_task.homeNID                = io_sinkC_bits_homeNID;
    C_task.dbID                   = io_sinkC_bits_dbID;
    C_task.fwdNID                 = io_sinkC_bits_fwdNID;
    C_task.fwdTxnID               = io_sinkC_bits_fwdTxnID;
    C_task.chiOpcode              = io_sinkC_bits_chiOpcode;
    C_task.resp                   = io_sinkC_bits_resp;
    C_task.fwdState               = io_sinkC_bits_fwdState;
    C_task.pCrdType               = io_sinkC_bits_pCrdType;
    C_task.retToSrc               = io_sinkC_bits_retToSrc;
    C_task.likelyshared           = io_sinkC_bits_likelyshared;
    C_task.expCompAck             = io_sinkC_bits_expCompAck;
    C_task.allowRetry             = io_sinkC_bits_allowRetry;
    C_task.memAttr_allocate       = io_sinkC_bits_memAttr_allocate;
    C_task.memAttr_cacheable      = io_sinkC_bits_memAttr_cacheable;
    C_task.memAttr_device         = io_sinkC_bits_memAttr_device;
    C_task.memAttr_ewa            = io_sinkC_bits_memAttr_ewa;
    C_task.traceTag               = io_sinkC_bits_traceTag;
    C_task.dataCheckErr           = io_sinkC_bits_dataCheckErr;
  end
  task_bundle_t mshrTask_in;
  always_comb begin
    mshrTask_in.channel                = io_mshrTask_bits_channel;
    mshrTask_in.txChannel              = io_mshrTask_bits_txChannel;
    mshrTask_in.set                    = io_mshrTask_bits_set;
    mshrTask_in.tag                    = io_mshrTask_bits_tag;
    mshrTask_in.off                    = io_mshrTask_bits_off;
    mshrTask_in.alias_                 = io_mshrTask_bits_alias;
    mshrTask_in.vaddr                  = io_mshrTask_bits_vaddr;
    mshrTask_in.isKeyword              = io_mshrTask_bits_isKeyword;
    mshrTask_in.opcode                 = io_mshrTask_bits_opcode;
    mshrTask_in.param                  = io_mshrTask_bits_param;
    mshrTask_in.size                   = io_mshrTask_bits_size;
    mshrTask_in.sourceId               = io_mshrTask_bits_sourceId;
    mshrTask_in.bufIdx                 = io_mshrTask_bits_bufIdx;
    mshrTask_in.needProbeAckData       = io_mshrTask_bits_needProbeAckData;
    mshrTask_in.denied                 = io_mshrTask_bits_denied;
    mshrTask_in.corrupt                = io_mshrTask_bits_corrupt;
    mshrTask_in.mshrTask               = io_mshrTask_bits_mshrTask;
    mshrTask_in.mshrId                 = io_mshrTask_bits_mshrId;
    mshrTask_in.aliasTask              = io_mshrTask_bits_aliasTask;
    mshrTask_in.useProbeData           = io_mshrTask_bits_useProbeData;
    mshrTask_in.mshrRetry              = io_mshrTask_bits_mshrRetry;
    mshrTask_in.readProbeDataDown      = io_mshrTask_bits_readProbeDataDown;
    mshrTask_in.fromL2pft              = io_mshrTask_bits_fromL2pft;
    mshrTask_in.needHint               = io_mshrTask_bits_needHint;
    mshrTask_in.dirty                  = io_mshrTask_bits_dirty;
    mshrTask_in.way                    = io_mshrTask_bits_way;
    mshrTask_in.meta_dirty             = io_mshrTask_bits_meta_dirty;
    mshrTask_in.meta_state             = io_mshrTask_bits_meta_state;
    mshrTask_in.meta_clients           = io_mshrTask_bits_meta_clients;
    mshrTask_in.meta_alias             = io_mshrTask_bits_meta_alias;
    mshrTask_in.meta_prefetch          = io_mshrTask_bits_meta_prefetch;
    mshrTask_in.meta_prefetchSrc       = io_mshrTask_bits_meta_prefetchSrc;
    mshrTask_in.meta_accessed          = io_mshrTask_bits_meta_accessed;
    mshrTask_in.meta_tagErr            = io_mshrTask_bits_meta_tagErr;
    mshrTask_in.meta_dataErr           = io_mshrTask_bits_meta_dataErr;
    mshrTask_in.metaWen                = io_mshrTask_bits_metaWen;
    mshrTask_in.tagWen                 = io_mshrTask_bits_tagWen;
    mshrTask_in.dsWen                  = io_mshrTask_bits_dsWen;
    mshrTask_in.wayMask                = io_mshrTask_bits_wayMask;
    mshrTask_in.replTask               = io_mshrTask_bits_replTask;
    mshrTask_in.cmoTask                = io_mshrTask_bits_cmoTask;
    mshrTask_in.cmoAll                 = io_mshrTask_bits_cmoAll;
    mshrTask_in.reqSource              = io_mshrTask_bits_reqSource;
    mshrTask_in.mergeA                 = io_mshrTask_bits_mergeA;
    mshrTask_in.aMergeTask_off         = io_mshrTask_bits_aMergeTask_off;
    mshrTask_in.aMergeTask_alias       = io_mshrTask_bits_aMergeTask_alias;
    mshrTask_in.aMergeTask_vaddr       = io_mshrTask_bits_aMergeTask_vaddr;
    mshrTask_in.aMergeTask_isKeyword   = io_mshrTask_bits_aMergeTask_isKeyword;
    mshrTask_in.aMergeTask_opcode      = io_mshrTask_bits_aMergeTask_opcode;
    mshrTask_in.aMergeTask_param       = io_mshrTask_bits_aMergeTask_param;
    mshrTask_in.aMergeTask_sourceId    = io_mshrTask_bits_aMergeTask_sourceId;
    mshrTask_in.aMergeTask_meta_dirty  = io_mshrTask_bits_aMergeTask_meta_dirty;
    mshrTask_in.aMergeTask_meta_state  = io_mshrTask_bits_aMergeTask_meta_state;
    mshrTask_in.aMergeTask_meta_clients = io_mshrTask_bits_aMergeTask_meta_clients;
    mshrTask_in.aMergeTask_meta_alias  = io_mshrTask_bits_aMergeTask_meta_alias;
    mshrTask_in.aMergeTask_meta_prefetch = io_mshrTask_bits_aMergeTask_meta_prefetch;
    mshrTask_in.aMergeTask_meta_prefetchSrc = io_mshrTask_bits_aMergeTask_meta_prefetchSrc;
    mshrTask_in.aMergeTask_meta_accessed = io_mshrTask_bits_aMergeTask_meta_accessed;
    mshrTask_in.aMergeTask_meta_tagErr = io_mshrTask_bits_aMergeTask_meta_tagErr;
    mshrTask_in.aMergeTask_meta_dataErr = io_mshrTask_bits_aMergeTask_meta_dataErr;
    mshrTask_in.snpHitRelease          = io_mshrTask_bits_snpHitRelease;
    mshrTask_in.snpHitReleaseToInval   = io_mshrTask_bits_snpHitReleaseToInval;
    mshrTask_in.snpHitReleaseToClean   = io_mshrTask_bits_snpHitReleaseToClean;
    mshrTask_in.snpHitReleaseWithData  = io_mshrTask_bits_snpHitReleaseWithData;
    mshrTask_in.snpHitReleaseIdx       = io_mshrTask_bits_snpHitReleaseIdx;
    mshrTask_in.snpHitReleaseMeta_dirty = io_mshrTask_bits_snpHitReleaseMeta_dirty;
    mshrTask_in.snpHitReleaseMeta_state = io_mshrTask_bits_snpHitReleaseMeta_state;
    mshrTask_in.snpHitReleaseMeta_clients = io_mshrTask_bits_snpHitReleaseMeta_clients;
    mshrTask_in.snpHitReleaseMeta_alias = io_mshrTask_bits_snpHitReleaseMeta_alias;
    mshrTask_in.snpHitReleaseMeta_prefetch = io_mshrTask_bits_snpHitReleaseMeta_prefetch;
    mshrTask_in.snpHitReleaseMeta_prefetchSrc = io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
    mshrTask_in.snpHitReleaseMeta_accessed = io_mshrTask_bits_snpHitReleaseMeta_accessed;
    mshrTask_in.snpHitReleaseMeta_tagErr = io_mshrTask_bits_snpHitReleaseMeta_tagErr;
    mshrTask_in.snpHitReleaseMeta_dataErr = io_mshrTask_bits_snpHitReleaseMeta_dataErr;
    mshrTask_in.tgtID                  = io_mshrTask_bits_tgtID;
    mshrTask_in.srcID                  = io_mshrTask_bits_srcID;
    mshrTask_in.txnID                  = io_mshrTask_bits_txnID;
    mshrTask_in.homeNID                = io_mshrTask_bits_homeNID;
    mshrTask_in.dbID                   = io_mshrTask_bits_dbID;
    mshrTask_in.fwdNID                 = io_mshrTask_bits_fwdNID;
    mshrTask_in.fwdTxnID               = io_mshrTask_bits_fwdTxnID;
    mshrTask_in.chiOpcode              = io_mshrTask_bits_chiOpcode;
    mshrTask_in.resp                   = io_mshrTask_bits_resp;
    mshrTask_in.fwdState               = io_mshrTask_bits_fwdState;
    mshrTask_in.pCrdType               = io_mshrTask_bits_pCrdType;
    mshrTask_in.retToSrc               = io_mshrTask_bits_retToSrc;
    mshrTask_in.likelyshared           = io_mshrTask_bits_likelyshared;
    mshrTask_in.expCompAck             = io_mshrTask_bits_expCompAck;
    mshrTask_in.allowRetry             = io_mshrTask_bits_allowRetry;
    mshrTask_in.memAttr_allocate       = io_mshrTask_bits_memAttr_allocate;
    mshrTask_in.memAttr_cacheable      = io_mshrTask_bits_memAttr_cacheable;
    mshrTask_in.memAttr_device         = io_mshrTask_bits_memAttr_device;
    mshrTask_in.memAttr_ewa            = io_mshrTask_bits_memAttr_ewa;
    mshrTask_in.traceTag               = io_mshrTask_bits_traceTag;
    mshrTask_in.dataCheckErr           = io_mshrTask_bits_dataCheckErr;
  end

  // ===== 流水寄存器(扁平 golden 命名, FM 逐 DFF 配对) =====
  logic        resetFinish;
  logic [8:0]  resetIdx;
  logic        ds_mcp2_stall;   // 无复位 RegNext: 上一拍非 AHint 的 s1_fire(防连续 DS 访问)
  logic        mshr_task_s1_valid;
  logic [2:0]  mshr_task_s1_bits_channel;
  logic [2:0]  mshr_task_s1_bits_txChannel;
  logic [8:0]  mshr_task_s1_bits_set;
  logic [30:0] mshr_task_s1_bits_tag;
  logic [5:0]  mshr_task_s1_bits_off;
  logic [1:0]  mshr_task_s1_bits_alias;
  logic [43:0] mshr_task_s1_bits_vaddr;
  logic        mshr_task_s1_bits_isKeyword;
  logic [3:0]  mshr_task_s1_bits_opcode;
  logic [2:0]  mshr_task_s1_bits_param;
  logic [2:0]  mshr_task_s1_bits_size;
  logic [6:0]  mshr_task_s1_bits_sourceId;
  logic [1:0]  mshr_task_s1_bits_bufIdx;
  logic        mshr_task_s1_bits_needProbeAckData;
  logic        mshr_task_s1_bits_denied;
  logic        mshr_task_s1_bits_corrupt;
  logic        mshr_task_s1_bits_mshrTask;
  logic [7:0]  mshr_task_s1_bits_mshrId;
  logic        mshr_task_s1_bits_aliasTask;
  logic        mshr_task_s1_bits_useProbeData;
  logic        mshr_task_s1_bits_mshrRetry;
  logic        mshr_task_s1_bits_readProbeDataDown;
  logic        mshr_task_s1_bits_fromL2pft;
  logic        mshr_task_s1_bits_needHint;
  logic        mshr_task_s1_bits_dirty;
  logic [2:0]  mshr_task_s1_bits_way;
  logic        mshr_task_s1_bits_meta_dirty;
  logic [1:0]  mshr_task_s1_bits_meta_state;
  logic        mshr_task_s1_bits_meta_clients;
  logic [1:0]  mshr_task_s1_bits_meta_alias;
  logic        mshr_task_s1_bits_meta_prefetch;
  logic [2:0]  mshr_task_s1_bits_meta_prefetchSrc;
  logic        mshr_task_s1_bits_meta_accessed;
  logic        mshr_task_s1_bits_meta_tagErr;
  logic        mshr_task_s1_bits_meta_dataErr;
  logic        mshr_task_s1_bits_metaWen;
  logic        mshr_task_s1_bits_tagWen;
  logic        mshr_task_s1_bits_dsWen;
  logic [7:0]  mshr_task_s1_bits_wayMask;
  logic        mshr_task_s1_bits_replTask;
  logic        mshr_task_s1_bits_cmoTask;
  logic        mshr_task_s1_bits_cmoAll;
  logic [4:0]  mshr_task_s1_bits_reqSource;
  logic        mshr_task_s1_bits_mergeA;
  logic [5:0]  mshr_task_s1_bits_aMergeTask_off;
  logic [1:0]  mshr_task_s1_bits_aMergeTask_alias;
  logic [43:0] mshr_task_s1_bits_aMergeTask_vaddr;
  logic        mshr_task_s1_bits_aMergeTask_isKeyword;
  logic [2:0]  mshr_task_s1_bits_aMergeTask_opcode;
  logic [2:0]  mshr_task_s1_bits_aMergeTask_param;
  logic [6:0]  mshr_task_s1_bits_aMergeTask_sourceId;
  logic        mshr_task_s1_bits_aMergeTask_meta_dirty;
  logic [1:0]  mshr_task_s1_bits_aMergeTask_meta_state;
  logic        mshr_task_s1_bits_aMergeTask_meta_clients;
  logic [1:0]  mshr_task_s1_bits_aMergeTask_meta_alias;
  logic        mshr_task_s1_bits_aMergeTask_meta_prefetch;
  logic [2:0]  mshr_task_s1_bits_aMergeTask_meta_prefetchSrc;
  logic        mshr_task_s1_bits_aMergeTask_meta_accessed;
  logic        mshr_task_s1_bits_aMergeTask_meta_tagErr;
  logic        mshr_task_s1_bits_aMergeTask_meta_dataErr;
  logic        mshr_task_s1_bits_snpHitRelease;
  logic        mshr_task_s1_bits_snpHitReleaseToInval;
  logic        mshr_task_s1_bits_snpHitReleaseToClean;
  logic        mshr_task_s1_bits_snpHitReleaseWithData;
  logic [7:0]  mshr_task_s1_bits_snpHitReleaseIdx;
  logic        mshr_task_s1_bits_snpHitReleaseMeta_dirty;
  logic [1:0]  mshr_task_s1_bits_snpHitReleaseMeta_state;
  logic        mshr_task_s1_bits_snpHitReleaseMeta_clients;
  logic [1:0]  mshr_task_s1_bits_snpHitReleaseMeta_alias;
  logic        mshr_task_s1_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]  mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc;
  logic        mshr_task_s1_bits_snpHitReleaseMeta_accessed;
  logic        mshr_task_s1_bits_snpHitReleaseMeta_tagErr;
  logic        mshr_task_s1_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] mshr_task_s1_bits_tgtID;
  logic [10:0] mshr_task_s1_bits_srcID;
  logic [11:0] mshr_task_s1_bits_txnID;
  logic [10:0] mshr_task_s1_bits_homeNID;
  logic [11:0] mshr_task_s1_bits_dbID;
  logic [10:0] mshr_task_s1_bits_fwdNID;
  logic [11:0] mshr_task_s1_bits_fwdTxnID;
  logic [6:0]  mshr_task_s1_bits_chiOpcode;
  logic [2:0]  mshr_task_s1_bits_resp;
  logic [2:0]  mshr_task_s1_bits_fwdState;
  logic [3:0]  mshr_task_s1_bits_pCrdType;
  logic        mshr_task_s1_bits_retToSrc;
  logic        mshr_task_s1_bits_likelyshared;
  logic        mshr_task_s1_bits_expCompAck;
  logic        mshr_task_s1_bits_allowRetry;
  logic        mshr_task_s1_bits_memAttr_allocate;
  logic        mshr_task_s1_bits_memAttr_cacheable;
  logic        mshr_task_s1_bits_memAttr_device;
  logic        mshr_task_s1_bits_memAttr_ewa;
  logic        mshr_task_s1_bits_traceTag;
  logic        mshr_task_s1_bits_dataCheckErr;
  logic        task_s2_valid;
  logic [2:0]  task_s2_bits_channel;
  logic [2:0]  task_s2_bits_txChannel;
  logic [8:0]  task_s2_bits_set;
  logic [30:0] task_s2_bits_tag;
  logic [5:0]  task_s2_bits_off;
  logic [1:0]  task_s2_bits_alias;
  logic [43:0] task_s2_bits_vaddr;
  logic        task_s2_bits_isKeyword;
  logic [3:0]  task_s2_bits_opcode;
  logic [2:0]  task_s2_bits_param;
  logic [2:0]  task_s2_bits_size;
  logic [6:0]  task_s2_bits_sourceId;
  logic [1:0]  task_s2_bits_bufIdx;
  logic        task_s2_bits_needProbeAckData;
  logic        task_s2_bits_denied;
  logic        task_s2_bits_corrupt;
  logic        task_s2_bits_mshrTask;
  logic [7:0]  task_s2_bits_mshrId;
  logic        task_s2_bits_aliasTask;
  logic        task_s2_bits_useProbeData;
  logic        task_s2_bits_mshrRetry;
  logic        task_s2_bits_readProbeDataDown;
  logic        task_s2_bits_fromL2pft;
  logic        task_s2_bits_needHint;
  logic        task_s2_bits_dirty;
  logic [2:0]  task_s2_bits_way;
  logic        task_s2_bits_meta_dirty;
  logic [1:0]  task_s2_bits_meta_state;
  logic        task_s2_bits_meta_clients;
  logic [1:0]  task_s2_bits_meta_alias;
  logic        task_s2_bits_meta_prefetch;
  logic [2:0]  task_s2_bits_meta_prefetchSrc;
  logic        task_s2_bits_meta_accessed;
  logic        task_s2_bits_meta_tagErr;
  logic        task_s2_bits_meta_dataErr;
  logic        task_s2_bits_metaWen;
  logic        task_s2_bits_tagWen;
  logic        task_s2_bits_dsWen;
  logic [7:0]  task_s2_bits_wayMask;
  logic        task_s2_bits_replTask;
  logic        task_s2_bits_cmoTask;
  logic        task_s2_bits_cmoAll;
  logic [4:0]  task_s2_bits_reqSource;
  logic        task_s2_bits_mergeA;
  logic [5:0]  task_s2_bits_aMergeTask_off;
  logic [1:0]  task_s2_bits_aMergeTask_alias;
  logic [43:0] task_s2_bits_aMergeTask_vaddr;
  logic        task_s2_bits_aMergeTask_isKeyword;
  logic [2:0]  task_s2_bits_aMergeTask_opcode;
  logic [2:0]  task_s2_bits_aMergeTask_param;
  logic [6:0]  task_s2_bits_aMergeTask_sourceId;
  logic        task_s2_bits_aMergeTask_meta_dirty;
  logic [1:0]  task_s2_bits_aMergeTask_meta_state;
  logic        task_s2_bits_aMergeTask_meta_clients;
  logic [1:0]  task_s2_bits_aMergeTask_meta_alias;
  logic        task_s2_bits_aMergeTask_meta_prefetch;
  logic [2:0]  task_s2_bits_aMergeTask_meta_prefetchSrc;
  logic        task_s2_bits_aMergeTask_meta_accessed;
  logic        task_s2_bits_aMergeTask_meta_tagErr;
  logic        task_s2_bits_aMergeTask_meta_dataErr;
  logic        task_s2_bits_snpHitRelease;
  logic        task_s2_bits_snpHitReleaseToInval;
  logic        task_s2_bits_snpHitReleaseToClean;
  logic        task_s2_bits_snpHitReleaseWithData;
  logic [7:0]  task_s2_bits_snpHitReleaseIdx;
  logic        task_s2_bits_snpHitReleaseMeta_dirty;
  logic [1:0]  task_s2_bits_snpHitReleaseMeta_state;
  logic        task_s2_bits_snpHitReleaseMeta_clients;
  logic [1:0]  task_s2_bits_snpHitReleaseMeta_alias;
  logic        task_s2_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]  task_s2_bits_snpHitReleaseMeta_prefetchSrc;
  logic        task_s2_bits_snpHitReleaseMeta_accessed;
  logic        task_s2_bits_snpHitReleaseMeta_tagErr;
  logic        task_s2_bits_snpHitReleaseMeta_dataErr;
  logic [10:0] task_s2_bits_tgtID;
  logic [10:0] task_s2_bits_srcID;
  logic [11:0] task_s2_bits_txnID;
  logic [10:0] task_s2_bits_homeNID;
  logic [11:0] task_s2_bits_dbID;
  logic [10:0] task_s2_bits_fwdNID;
  logic [11:0] task_s2_bits_fwdTxnID;
  logic [6:0]  task_s2_bits_chiOpcode;
  logic [2:0]  task_s2_bits_resp;
  logic [2:0]  task_s2_bits_fwdState;
  logic [3:0]  task_s2_bits_pCrdType;
  logic        task_s2_bits_retToSrc;
  logic        task_s2_bits_likelyshared;
  logic        task_s2_bits_expCompAck;
  logic        task_s2_bits_allowRetry;
  logic        task_s2_bits_memAttr_allocate;
  logic        task_s2_bits_memAttr_cacheable;
  logic        task_s2_bits_memAttr_device;
  logic        task_s2_bits_memAttr_ewa;
  logic        task_s2_bits_traceTag;
  logic        task_s2_bits_dataCheckErr;

  // mshr_task_s1 扁平寄存器的结构体视图(供 task_s1 选择)
  task_bundle_t mshr_task_s1;
  always_comb begin
    mshr_task_s1.channel                = mshr_task_s1_bits_channel;
    mshr_task_s1.txChannel              = mshr_task_s1_bits_txChannel;
    mshr_task_s1.set                    = mshr_task_s1_bits_set;
    mshr_task_s1.tag                    = mshr_task_s1_bits_tag;
    mshr_task_s1.off                    = mshr_task_s1_bits_off;
    mshr_task_s1.alias_                 = mshr_task_s1_bits_alias;
    mshr_task_s1.vaddr                  = mshr_task_s1_bits_vaddr;
    mshr_task_s1.isKeyword              = mshr_task_s1_bits_isKeyword;
    mshr_task_s1.opcode                 = mshr_task_s1_bits_opcode;
    mshr_task_s1.param                  = mshr_task_s1_bits_param;
    mshr_task_s1.size                   = mshr_task_s1_bits_size;
    mshr_task_s1.sourceId               = mshr_task_s1_bits_sourceId;
    mshr_task_s1.bufIdx                 = mshr_task_s1_bits_bufIdx;
    mshr_task_s1.needProbeAckData       = mshr_task_s1_bits_needProbeAckData;
    mshr_task_s1.denied                 = mshr_task_s1_bits_denied;
    mshr_task_s1.corrupt                = mshr_task_s1_bits_corrupt;
    mshr_task_s1.mshrTask               = mshr_task_s1_bits_mshrTask;
    mshr_task_s1.mshrId                 = mshr_task_s1_bits_mshrId;
    mshr_task_s1.aliasTask              = mshr_task_s1_bits_aliasTask;
    mshr_task_s1.useProbeData           = mshr_task_s1_bits_useProbeData;
    mshr_task_s1.mshrRetry              = mshr_task_s1_bits_mshrRetry;
    mshr_task_s1.readProbeDataDown      = mshr_task_s1_bits_readProbeDataDown;
    mshr_task_s1.fromL2pft              = mshr_task_s1_bits_fromL2pft;
    mshr_task_s1.needHint               = mshr_task_s1_bits_needHint;
    mshr_task_s1.dirty                  = mshr_task_s1_bits_dirty;
    mshr_task_s1.way                    = mshr_task_s1_bits_way;
    mshr_task_s1.meta_dirty             = mshr_task_s1_bits_meta_dirty;
    mshr_task_s1.meta_state             = mshr_task_s1_bits_meta_state;
    mshr_task_s1.meta_clients           = mshr_task_s1_bits_meta_clients;
    mshr_task_s1.meta_alias             = mshr_task_s1_bits_meta_alias;
    mshr_task_s1.meta_prefetch          = mshr_task_s1_bits_meta_prefetch;
    mshr_task_s1.meta_prefetchSrc       = mshr_task_s1_bits_meta_prefetchSrc;
    mshr_task_s1.meta_accessed          = mshr_task_s1_bits_meta_accessed;
    mshr_task_s1.meta_tagErr            = mshr_task_s1_bits_meta_tagErr;
    mshr_task_s1.meta_dataErr           = mshr_task_s1_bits_meta_dataErr;
    mshr_task_s1.metaWen                = mshr_task_s1_bits_metaWen;
    mshr_task_s1.tagWen                 = mshr_task_s1_bits_tagWen;
    mshr_task_s1.dsWen                  = mshr_task_s1_bits_dsWen;
    mshr_task_s1.wayMask                = mshr_task_s1_bits_wayMask;
    mshr_task_s1.replTask               = mshr_task_s1_bits_replTask;
    mshr_task_s1.cmoTask                = mshr_task_s1_bits_cmoTask;
    mshr_task_s1.cmoAll                 = mshr_task_s1_bits_cmoAll;
    mshr_task_s1.reqSource              = mshr_task_s1_bits_reqSource;
    mshr_task_s1.mergeA                 = mshr_task_s1_bits_mergeA;
    mshr_task_s1.aMergeTask_off         = mshr_task_s1_bits_aMergeTask_off;
    mshr_task_s1.aMergeTask_alias       = mshr_task_s1_bits_aMergeTask_alias;
    mshr_task_s1.aMergeTask_vaddr       = mshr_task_s1_bits_aMergeTask_vaddr;
    mshr_task_s1.aMergeTask_isKeyword   = mshr_task_s1_bits_aMergeTask_isKeyword;
    mshr_task_s1.aMergeTask_opcode      = mshr_task_s1_bits_aMergeTask_opcode;
    mshr_task_s1.aMergeTask_param       = mshr_task_s1_bits_aMergeTask_param;
    mshr_task_s1.aMergeTask_sourceId    = mshr_task_s1_bits_aMergeTask_sourceId;
    mshr_task_s1.aMergeTask_meta_dirty  = mshr_task_s1_bits_aMergeTask_meta_dirty;
    mshr_task_s1.aMergeTask_meta_state  = mshr_task_s1_bits_aMergeTask_meta_state;
    mshr_task_s1.aMergeTask_meta_clients = mshr_task_s1_bits_aMergeTask_meta_clients;
    mshr_task_s1.aMergeTask_meta_alias  = mshr_task_s1_bits_aMergeTask_meta_alias;
    mshr_task_s1.aMergeTask_meta_prefetch = mshr_task_s1_bits_aMergeTask_meta_prefetch;
    mshr_task_s1.aMergeTask_meta_prefetchSrc = mshr_task_s1_bits_aMergeTask_meta_prefetchSrc;
    mshr_task_s1.aMergeTask_meta_accessed = mshr_task_s1_bits_aMergeTask_meta_accessed;
    mshr_task_s1.aMergeTask_meta_tagErr = mshr_task_s1_bits_aMergeTask_meta_tagErr;
    mshr_task_s1.aMergeTask_meta_dataErr = mshr_task_s1_bits_aMergeTask_meta_dataErr;
    mshr_task_s1.snpHitRelease          = mshr_task_s1_bits_snpHitRelease;
    mshr_task_s1.snpHitReleaseToInval   = mshr_task_s1_bits_snpHitReleaseToInval;
    mshr_task_s1.snpHitReleaseToClean   = mshr_task_s1_bits_snpHitReleaseToClean;
    mshr_task_s1.snpHitReleaseWithData  = mshr_task_s1_bits_snpHitReleaseWithData;
    mshr_task_s1.snpHitReleaseIdx       = mshr_task_s1_bits_snpHitReleaseIdx;
    mshr_task_s1.snpHitReleaseMeta_dirty = mshr_task_s1_bits_snpHitReleaseMeta_dirty;
    mshr_task_s1.snpHitReleaseMeta_state = mshr_task_s1_bits_snpHitReleaseMeta_state;
    mshr_task_s1.snpHitReleaseMeta_clients = mshr_task_s1_bits_snpHitReleaseMeta_clients;
    mshr_task_s1.snpHitReleaseMeta_alias = mshr_task_s1_bits_snpHitReleaseMeta_alias;
    mshr_task_s1.snpHitReleaseMeta_prefetch = mshr_task_s1_bits_snpHitReleaseMeta_prefetch;
    mshr_task_s1.snpHitReleaseMeta_prefetchSrc = mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc;
    mshr_task_s1.snpHitReleaseMeta_accessed = mshr_task_s1_bits_snpHitReleaseMeta_accessed;
    mshr_task_s1.snpHitReleaseMeta_tagErr = mshr_task_s1_bits_snpHitReleaseMeta_tagErr;
    mshr_task_s1.snpHitReleaseMeta_dataErr = mshr_task_s1_bits_snpHitReleaseMeta_dataErr;
    mshr_task_s1.tgtID                  = mshr_task_s1_bits_tgtID;
    mshr_task_s1.srcID                  = mshr_task_s1_bits_srcID;
    mshr_task_s1.txnID                  = mshr_task_s1_bits_txnID;
    mshr_task_s1.homeNID                = mshr_task_s1_bits_homeNID;
    mshr_task_s1.dbID                   = mshr_task_s1_bits_dbID;
    mshr_task_s1.fwdNID                 = mshr_task_s1_bits_fwdNID;
    mshr_task_s1.fwdTxnID               = mshr_task_s1_bits_fwdTxnID;
    mshr_task_s1.chiOpcode              = mshr_task_s1_bits_chiOpcode;
    mshr_task_s1.resp                   = mshr_task_s1_bits_resp;
    mshr_task_s1.fwdState               = mshr_task_s1_bits_fwdState;
    mshr_task_s1.pCrdType               = mshr_task_s1_bits_pCrdType;
    mshr_task_s1.retToSrc               = mshr_task_s1_bits_retToSrc;
    mshr_task_s1.likelyshared           = mshr_task_s1_bits_likelyshared;
    mshr_task_s1.expCompAck             = mshr_task_s1_bits_expCompAck;
    mshr_task_s1.allowRetry             = mshr_task_s1_bits_allowRetry;
    mshr_task_s1.memAttr_allocate       = mshr_task_s1_bits_memAttr_allocate;
    mshr_task_s1.memAttr_cacheable      = mshr_task_s1_bits_memAttr_cacheable;
    mshr_task_s1.memAttr_device         = mshr_task_s1_bits_memAttr_device;
    mshr_task_s1.memAttr_ewa            = mshr_task_s1_bits_memAttr_ewa;
    mshr_task_s1.traceTag               = mshr_task_s1_bits_traceTag;
    mshr_task_s1.dataCheckErr           = mshr_task_s1_bits_dataCheckErr;
  end

  // ===== s1: 是否为需读替换路的 MSHR refill 任务(Grant/GrantData/AccessAckData/HintAck) =====
  wire opcode_is_hintAck = mshr_task_s1_bits_opcode == 4'h2;
  wire s1_needs_replRead =
    mshr_task_s1_valid & mshr_task_s1.channel[0] & mshr_task_s1_bits_replTask &
    (mshr_task_s1_bits_opcode == 4'h4 | mshr_task_s1_bits_opcode == 4'h5 |
     mshr_task_s1_bits_opcode == 4'h1 | opcode_is_hintAck);
  // replRead 需等 dirRead.ready 且 MainPipe 不阻塞 G, 期间 stall
  wire mshr_replRead_stall =
    mshr_task_s1_valid & s1_needs_replRead &
    (~io_dirRead_s1_ready | io_fromMainPipe_blockG_s1);

  // ===== s0: mshrTask 入口 ready / fire =====
  wire io_mshrTask_ready_0 =
    ~io_fromGrantBuffer_blockMSHRReqEntrance & ~s1_needs_replRead &
    ~(mshr_task_s1_valid & ds_mcp2_stall) & ~io_fromTXDAT_blockMSHRReqEntrance &
    ~io_fromTXRSP_blockMSHRReqEntrance & ~io_fromTXREQ_blockMSHRReqEntrance;
  wire s0_fire = io_mshrTask_valid & io_mshrTask_ready_0;

  // ===== s1: 通道阻塞 + 优先级(C>B>A) =====
  wire block_A = io_fromMSHRCtl_blockA_s1 | io_fromMainPipe_blockA_s1 |
                 io_fromGrantBuffer_blockSinkReqEntrance_blockA_s1;
  wire block_B = io_fromMSHRCtl_blockB_s1 | io_fromMainPipe_blockB_s1 |
                 io_fromGrantBuffer_blockSinkReqEntrance_blockB_s1 |
                 io_fromTXDAT_blockSinkBReqEntrance | io_fromTXRSP_blockSinkBReqEntrance;
  wire block_C = io_fromMSHRCtl_blockC_s1 | io_fromMainPipe_blockC_s1 |
                 io_fromGrantBuffer_blockSinkReqEntrance_blockC_s1;
  wire selC = io_sinkC_valid & ~block_C;   // C 最高
  wire selB = io_sinkB_valid & ~block_B;
  wire selA = io_sinkA_valid & ~block_A;
  // 基本就绪: dir 可读 & 复位完成 & 无在途 mshr_s1 & 无 DS 连访 stall
  wire sink_ready_basic =
    io_dirRead_s1_ready & resetFinish & ~mshr_task_s1_valid & ~ds_mcp2_stall;
  wire io_sinkA_ready_0 = sink_ready_basic & ~block_A & ~selB & ~selC;
  wire io_sinkB_ready_0 = sink_ready_basic & ~block_B & ~selC;
  wire io_sinkC_ready_0 = sink_ready_basic & ~block_C;
  wire chnl_task_s1_valid = io_dirRead_s1_ready & (selA | selB | selC) & resetFinish;

  // ===== 通道优先选择 + mshr 优先 → task_s1 (结构体 Mux 收敛逐字段) =====
  task_bundle_t chnl_task_s1, task_s1;
  assign chnl_task_s1 = selC ? C_task : (selB ? B_task : A_task);
  assign task_s1      = mshr_task_s1_valid ? mshr_task_s1 : chnl_task_s1;
  wire task_s1_valid  = mshr_task_s1_valid ? 1'b1 : chnl_task_s1_valid;

  // ===== s1_fire / s2_ready =====
  wire s1_fire = task_s1_valid & ~mshr_replRead_stall & ~ds_mcp2_stall;
  // sinkA Hint(opcode==5) fire 不引发 DS 连访 stall
  wire sinkA_fire = io_sinkA_ready_0 & io_sinkA_valid;
  wire sinkB_fire = io_sinkB_ready_0 & io_sinkB_valid;
  wire sinkC_fire = io_sinkC_ready_0 & io_sinkC_valid;

  // ===== 时序: 复位计数 / mshr_task_s1 锁存 / task_s2 锁存 =====
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish        <= 1'b0;
      resetIdx           <= 9'h1FF;
      mshr_task_s1_valid <= 1'b0;
      mshr_task_s1_bits_channel <= '0;
      mshr_task_s1_bits_txChannel <= '0;
      mshr_task_s1_bits_set <= '0;
      mshr_task_s1_bits_tag <= '0;
      mshr_task_s1_bits_off <= '0;
      mshr_task_s1_bits_alias <= '0;
      mshr_task_s1_bits_vaddr <= '0;
      mshr_task_s1_bits_isKeyword <= '0;
      mshr_task_s1_bits_opcode <= '0;
      mshr_task_s1_bits_param <= '0;
      mshr_task_s1_bits_size <= '0;
      mshr_task_s1_bits_sourceId <= '0;
      mshr_task_s1_bits_bufIdx <= '0;
      mshr_task_s1_bits_needProbeAckData <= '0;
      mshr_task_s1_bits_denied <= '0;
      mshr_task_s1_bits_corrupt <= '0;
      mshr_task_s1_bits_mshrTask <= '0;
      mshr_task_s1_bits_mshrId <= '0;
      mshr_task_s1_bits_aliasTask <= '0;
      mshr_task_s1_bits_useProbeData <= '0;
      mshr_task_s1_bits_mshrRetry <= '0;
      mshr_task_s1_bits_readProbeDataDown <= '0;
      mshr_task_s1_bits_fromL2pft <= '0;
      mshr_task_s1_bits_needHint <= '0;
      mshr_task_s1_bits_dirty <= '0;
      mshr_task_s1_bits_way <= '0;
      mshr_task_s1_bits_meta_dirty <= '0;
      mshr_task_s1_bits_meta_state <= '0;
      mshr_task_s1_bits_meta_clients <= '0;
      mshr_task_s1_bits_meta_alias <= '0;
      mshr_task_s1_bits_meta_prefetch <= '0;
      mshr_task_s1_bits_meta_prefetchSrc <= '0;
      mshr_task_s1_bits_meta_accessed <= '0;
      mshr_task_s1_bits_meta_tagErr <= '0;
      mshr_task_s1_bits_meta_dataErr <= '0;
      mshr_task_s1_bits_metaWen <= '0;
      mshr_task_s1_bits_tagWen <= '0;
      mshr_task_s1_bits_dsWen <= '0;
      mshr_task_s1_bits_wayMask <= '0;
      mshr_task_s1_bits_replTask <= '0;
      mshr_task_s1_bits_cmoTask <= '0;
      mshr_task_s1_bits_cmoAll <= '0;
      mshr_task_s1_bits_reqSource <= '0;
      mshr_task_s1_bits_mergeA <= '0;
      mshr_task_s1_bits_aMergeTask_off <= '0;
      mshr_task_s1_bits_aMergeTask_alias <= '0;
      mshr_task_s1_bits_aMergeTask_vaddr <= '0;
      mshr_task_s1_bits_aMergeTask_isKeyword <= '0;
      mshr_task_s1_bits_aMergeTask_opcode <= '0;
      mshr_task_s1_bits_aMergeTask_param <= '0;
      mshr_task_s1_bits_aMergeTask_sourceId <= '0;
      mshr_task_s1_bits_aMergeTask_meta_dirty <= '0;
      mshr_task_s1_bits_aMergeTask_meta_state <= '0;
      mshr_task_s1_bits_aMergeTask_meta_clients <= '0;
      mshr_task_s1_bits_aMergeTask_meta_alias <= '0;
      mshr_task_s1_bits_aMergeTask_meta_prefetch <= '0;
      mshr_task_s1_bits_aMergeTask_meta_prefetchSrc <= '0;
      mshr_task_s1_bits_aMergeTask_meta_accessed <= '0;
      mshr_task_s1_bits_aMergeTask_meta_tagErr <= '0;
      mshr_task_s1_bits_aMergeTask_meta_dataErr <= '0;
      mshr_task_s1_bits_snpHitRelease <= '0;
      mshr_task_s1_bits_snpHitReleaseToInval <= '0;
      mshr_task_s1_bits_snpHitReleaseToClean <= '0;
      mshr_task_s1_bits_snpHitReleaseWithData <= '0;
      mshr_task_s1_bits_snpHitReleaseIdx <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_dirty <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_state <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_clients <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_alias <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_prefetch <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_accessed <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_tagErr <= '0;
      mshr_task_s1_bits_snpHitReleaseMeta_dataErr <= '0;
      mshr_task_s1_bits_tgtID <= '0;
      mshr_task_s1_bits_srcID <= '0;
      mshr_task_s1_bits_txnID <= '0;
      mshr_task_s1_bits_homeNID <= '0;
      mshr_task_s1_bits_dbID <= '0;
      mshr_task_s1_bits_fwdNID <= '0;
      mshr_task_s1_bits_fwdTxnID <= '0;
      mshr_task_s1_bits_chiOpcode <= '0;
      mshr_task_s1_bits_resp <= '0;
      mshr_task_s1_bits_fwdState <= '0;
      mshr_task_s1_bits_pCrdType <= '0;
      mshr_task_s1_bits_retToSrc <= '0;
      mshr_task_s1_bits_likelyshared <= '0;
      mshr_task_s1_bits_expCompAck <= '0;
      mshr_task_s1_bits_allowRetry <= '0;
      mshr_task_s1_bits_memAttr_allocate <= '0;
      mshr_task_s1_bits_memAttr_cacheable <= '0;
      mshr_task_s1_bits_memAttr_device <= '0;
      mshr_task_s1_bits_memAttr_ewa <= '0;
      mshr_task_s1_bits_traceTag <= '0;
      mshr_task_s1_bits_dataCheckErr <= '0;
      task_s2_valid      <= 1'b0;
      task_s2_bits_channel <= '0;
      task_s2_bits_txChannel <= '0;
      task_s2_bits_set <= '0;
      task_s2_bits_tag <= '0;
      task_s2_bits_off <= '0;
      task_s2_bits_alias <= '0;
      task_s2_bits_vaddr <= '0;
      task_s2_bits_isKeyword <= '0;
      task_s2_bits_opcode <= '0;
      task_s2_bits_param <= '0;
      task_s2_bits_size <= '0;
      task_s2_bits_sourceId <= '0;
      task_s2_bits_bufIdx <= '0;
      task_s2_bits_needProbeAckData <= '0;
      task_s2_bits_denied <= '0;
      task_s2_bits_corrupt <= '0;
      task_s2_bits_mshrTask <= '0;
      task_s2_bits_mshrId <= '0;
      task_s2_bits_aliasTask <= '0;
      task_s2_bits_useProbeData <= '0;
      task_s2_bits_mshrRetry <= '0;
      task_s2_bits_readProbeDataDown <= '0;
      task_s2_bits_fromL2pft <= '0;
      task_s2_bits_needHint <= '0;
      task_s2_bits_dirty <= '0;
      task_s2_bits_way <= '0;
      task_s2_bits_meta_dirty <= '0;
      task_s2_bits_meta_state <= '0;
      task_s2_bits_meta_clients <= '0;
      task_s2_bits_meta_alias <= '0;
      task_s2_bits_meta_prefetch <= '0;
      task_s2_bits_meta_prefetchSrc <= '0;
      task_s2_bits_meta_accessed <= '0;
      task_s2_bits_meta_tagErr <= '0;
      task_s2_bits_meta_dataErr <= '0;
      task_s2_bits_metaWen <= '0;
      task_s2_bits_tagWen <= '0;
      task_s2_bits_dsWen <= '0;
      task_s2_bits_wayMask <= '0;
      task_s2_bits_replTask <= '0;
      task_s2_bits_cmoTask <= '0;
      task_s2_bits_cmoAll <= '0;
      task_s2_bits_reqSource <= '0;
      task_s2_bits_mergeA <= '0;
      task_s2_bits_aMergeTask_off <= '0;
      task_s2_bits_aMergeTask_alias <= '0;
      task_s2_bits_aMergeTask_vaddr <= '0;
      task_s2_bits_aMergeTask_isKeyword <= '0;
      task_s2_bits_aMergeTask_opcode <= '0;
      task_s2_bits_aMergeTask_param <= '0;
      task_s2_bits_aMergeTask_sourceId <= '0;
      task_s2_bits_aMergeTask_meta_dirty <= '0;
      task_s2_bits_aMergeTask_meta_state <= '0;
      task_s2_bits_aMergeTask_meta_clients <= '0;
      task_s2_bits_aMergeTask_meta_alias <= '0;
      task_s2_bits_aMergeTask_meta_prefetch <= '0;
      task_s2_bits_aMergeTask_meta_prefetchSrc <= '0;
      task_s2_bits_aMergeTask_meta_accessed <= '0;
      task_s2_bits_aMergeTask_meta_tagErr <= '0;
      task_s2_bits_aMergeTask_meta_dataErr <= '0;
      task_s2_bits_snpHitRelease <= '0;
      task_s2_bits_snpHitReleaseToInval <= '0;
      task_s2_bits_snpHitReleaseToClean <= '0;
      task_s2_bits_snpHitReleaseWithData <= '0;
      task_s2_bits_snpHitReleaseIdx <= '0;
      task_s2_bits_snpHitReleaseMeta_dirty <= '0;
      task_s2_bits_snpHitReleaseMeta_state <= '0;
      task_s2_bits_snpHitReleaseMeta_clients <= '0;
      task_s2_bits_snpHitReleaseMeta_alias <= '0;
      task_s2_bits_snpHitReleaseMeta_prefetch <= '0;
      task_s2_bits_snpHitReleaseMeta_prefetchSrc <= '0;
      task_s2_bits_snpHitReleaseMeta_accessed <= '0;
      task_s2_bits_snpHitReleaseMeta_tagErr <= '0;
      task_s2_bits_snpHitReleaseMeta_dataErr <= '0;
      task_s2_bits_tgtID <= '0;
      task_s2_bits_srcID <= '0;
      task_s2_bits_txnID <= '0;
      task_s2_bits_homeNID <= '0;
      task_s2_bits_dbID <= '0;
      task_s2_bits_fwdNID <= '0;
      task_s2_bits_fwdTxnID <= '0;
      task_s2_bits_chiOpcode <= '0;
      task_s2_bits_resp <= '0;
      task_s2_bits_fwdState <= '0;
      task_s2_bits_pCrdType <= '0;
      task_s2_bits_retToSrc <= '0;
      task_s2_bits_likelyshared <= '0;
      task_s2_bits_expCompAck <= '0;
      task_s2_bits_allowRetry <= '0;
      task_s2_bits_memAttr_allocate <= '0;
      task_s2_bits_memAttr_cacheable <= '0;
      task_s2_bits_memAttr_device <= '0;
      task_s2_bits_memAttr_ewa <= '0;
      task_s2_bits_traceTag <= '0;
      task_s2_bits_dataCheckErr <= '0;
    end else begin
      resetFinish <= (resetIdx == 9'h0) | resetFinish;
      if (~resetFinish) resetIdx <= resetIdx - 9'h1;
      // mshr_task_s1: s1_fire 清(除非同拍 s0 再入), s0_fire 装载
      mshr_task_s1_valid <= (mshr_task_s1_valid & ~s1_fire) | s0_fire;
      if (s0_fire) begin
        mshr_task_s1_bits_channel <= io_mshrTask_bits_channel;
        mshr_task_s1_bits_txChannel <= io_mshrTask_bits_txChannel;
        mshr_task_s1_bits_set <= io_mshrTask_bits_set;
        mshr_task_s1_bits_tag <= io_mshrTask_bits_tag;
        mshr_task_s1_bits_off <= io_mshrTask_bits_off;
        mshr_task_s1_bits_alias <= io_mshrTask_bits_alias;
        mshr_task_s1_bits_vaddr <= io_mshrTask_bits_vaddr;
        mshr_task_s1_bits_isKeyword <= io_mshrTask_bits_isKeyword;
        mshr_task_s1_bits_opcode <= io_mshrTask_bits_opcode;
        mshr_task_s1_bits_param <= io_mshrTask_bits_param;
        mshr_task_s1_bits_size <= io_mshrTask_bits_size;
        mshr_task_s1_bits_sourceId <= io_mshrTask_bits_sourceId;
        mshr_task_s1_bits_bufIdx <= io_mshrTask_bits_bufIdx;
        mshr_task_s1_bits_needProbeAckData <= io_mshrTask_bits_needProbeAckData;
        mshr_task_s1_bits_denied <= io_mshrTask_bits_denied;
        mshr_task_s1_bits_corrupt <= io_mshrTask_bits_corrupt;
        mshr_task_s1_bits_mshrTask <= io_mshrTask_bits_mshrTask;
        mshr_task_s1_bits_mshrId <= io_mshrTask_bits_mshrId;
        mshr_task_s1_bits_aliasTask <= io_mshrTask_bits_aliasTask;
        mshr_task_s1_bits_useProbeData <= io_mshrTask_bits_useProbeData;
        mshr_task_s1_bits_mshrRetry <= io_mshrTask_bits_mshrRetry;
        mshr_task_s1_bits_readProbeDataDown <= io_mshrTask_bits_readProbeDataDown;
        mshr_task_s1_bits_fromL2pft <= io_mshrTask_bits_fromL2pft;
        mshr_task_s1_bits_needHint <= io_mshrTask_bits_needHint;
        mshr_task_s1_bits_dirty <= io_mshrTask_bits_dirty;
        mshr_task_s1_bits_way <= io_mshrTask_bits_way;
        mshr_task_s1_bits_meta_dirty <= io_mshrTask_bits_meta_dirty;
        mshr_task_s1_bits_meta_state <= io_mshrTask_bits_meta_state;
        mshr_task_s1_bits_meta_clients <= io_mshrTask_bits_meta_clients;
        mshr_task_s1_bits_meta_alias <= io_mshrTask_bits_meta_alias;
        mshr_task_s1_bits_meta_prefetch <= io_mshrTask_bits_meta_prefetch;
        mshr_task_s1_bits_meta_prefetchSrc <= io_mshrTask_bits_meta_prefetchSrc;
        mshr_task_s1_bits_meta_accessed <= io_mshrTask_bits_meta_accessed;
        mshr_task_s1_bits_meta_tagErr <= io_mshrTask_bits_meta_tagErr;
        mshr_task_s1_bits_meta_dataErr <= io_mshrTask_bits_meta_dataErr;
        mshr_task_s1_bits_metaWen <= io_mshrTask_bits_metaWen;
        mshr_task_s1_bits_tagWen <= io_mshrTask_bits_tagWen;
        mshr_task_s1_bits_dsWen <= io_mshrTask_bits_dsWen;
        mshr_task_s1_bits_wayMask <= io_mshrTask_bits_wayMask;
        mshr_task_s1_bits_replTask <= io_mshrTask_bits_replTask;
        mshr_task_s1_bits_cmoTask <= io_mshrTask_bits_cmoTask;
        mshr_task_s1_bits_cmoAll <= io_mshrTask_bits_cmoAll;
        mshr_task_s1_bits_reqSource <= io_mshrTask_bits_reqSource;
        mshr_task_s1_bits_mergeA <= io_mshrTask_bits_mergeA;
        mshr_task_s1_bits_aMergeTask_off <= io_mshrTask_bits_aMergeTask_off;
        mshr_task_s1_bits_aMergeTask_alias <= io_mshrTask_bits_aMergeTask_alias;
        mshr_task_s1_bits_aMergeTask_vaddr <= io_mshrTask_bits_aMergeTask_vaddr;
        mshr_task_s1_bits_aMergeTask_isKeyword <= io_mshrTask_bits_aMergeTask_isKeyword;
        mshr_task_s1_bits_aMergeTask_opcode <= io_mshrTask_bits_aMergeTask_opcode;
        mshr_task_s1_bits_aMergeTask_param <= io_mshrTask_bits_aMergeTask_param;
        mshr_task_s1_bits_aMergeTask_sourceId <= io_mshrTask_bits_aMergeTask_sourceId;
        mshr_task_s1_bits_aMergeTask_meta_dirty <= io_mshrTask_bits_aMergeTask_meta_dirty;
        mshr_task_s1_bits_aMergeTask_meta_state <= io_mshrTask_bits_aMergeTask_meta_state;
        mshr_task_s1_bits_aMergeTask_meta_clients <= io_mshrTask_bits_aMergeTask_meta_clients;
        mshr_task_s1_bits_aMergeTask_meta_alias <= io_mshrTask_bits_aMergeTask_meta_alias;
        mshr_task_s1_bits_aMergeTask_meta_prefetch <= io_mshrTask_bits_aMergeTask_meta_prefetch;
        mshr_task_s1_bits_aMergeTask_meta_prefetchSrc <= io_mshrTask_bits_aMergeTask_meta_prefetchSrc;
        mshr_task_s1_bits_aMergeTask_meta_accessed <= io_mshrTask_bits_aMergeTask_meta_accessed;
        mshr_task_s1_bits_aMergeTask_meta_tagErr <= io_mshrTask_bits_aMergeTask_meta_tagErr;
        mshr_task_s1_bits_aMergeTask_meta_dataErr <= io_mshrTask_bits_aMergeTask_meta_dataErr;
        mshr_task_s1_bits_snpHitRelease <= io_mshrTask_bits_snpHitRelease;
        mshr_task_s1_bits_snpHitReleaseToInval <= io_mshrTask_bits_snpHitReleaseToInval;
        mshr_task_s1_bits_snpHitReleaseToClean <= io_mshrTask_bits_snpHitReleaseToClean;
        mshr_task_s1_bits_snpHitReleaseWithData <= io_mshrTask_bits_snpHitReleaseWithData;
        mshr_task_s1_bits_snpHitReleaseIdx <= io_mshrTask_bits_snpHitReleaseIdx;
        mshr_task_s1_bits_snpHitReleaseMeta_dirty <= io_mshrTask_bits_snpHitReleaseMeta_dirty;
        mshr_task_s1_bits_snpHitReleaseMeta_state <= io_mshrTask_bits_snpHitReleaseMeta_state;
        mshr_task_s1_bits_snpHitReleaseMeta_clients <= io_mshrTask_bits_snpHitReleaseMeta_clients;
        mshr_task_s1_bits_snpHitReleaseMeta_alias <= io_mshrTask_bits_snpHitReleaseMeta_alias;
        mshr_task_s1_bits_snpHitReleaseMeta_prefetch <= io_mshrTask_bits_snpHitReleaseMeta_prefetch;
        mshr_task_s1_bits_snpHitReleaseMeta_prefetchSrc <= io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc;
        mshr_task_s1_bits_snpHitReleaseMeta_accessed <= io_mshrTask_bits_snpHitReleaseMeta_accessed;
        mshr_task_s1_bits_snpHitReleaseMeta_tagErr <= io_mshrTask_bits_snpHitReleaseMeta_tagErr;
        mshr_task_s1_bits_snpHitReleaseMeta_dataErr <= io_mshrTask_bits_snpHitReleaseMeta_dataErr;
        mshr_task_s1_bits_tgtID <= io_mshrTask_bits_tgtID;
        mshr_task_s1_bits_srcID <= io_mshrTask_bits_srcID;
        mshr_task_s1_bits_txnID <= io_mshrTask_bits_txnID;
        mshr_task_s1_bits_homeNID <= io_mshrTask_bits_homeNID;
        mshr_task_s1_bits_dbID <= io_mshrTask_bits_dbID;
        mshr_task_s1_bits_fwdNID <= io_mshrTask_bits_fwdNID;
        mshr_task_s1_bits_fwdTxnID <= io_mshrTask_bits_fwdTxnID;
        mshr_task_s1_bits_chiOpcode <= io_mshrTask_bits_chiOpcode;
        mshr_task_s1_bits_resp <= io_mshrTask_bits_resp;
        mshr_task_s1_bits_fwdState <= io_mshrTask_bits_fwdState;
        mshr_task_s1_bits_pCrdType <= io_mshrTask_bits_pCrdType;
        mshr_task_s1_bits_retToSrc <= io_mshrTask_bits_retToSrc;
        mshr_task_s1_bits_likelyshared <= io_mshrTask_bits_likelyshared;
        mshr_task_s1_bits_expCompAck <= io_mshrTask_bits_expCompAck;
        mshr_task_s1_bits_allowRetry <= io_mshrTask_bits_allowRetry;
        mshr_task_s1_bits_memAttr_allocate <= io_mshrTask_bits_memAttr_allocate;
        mshr_task_s1_bits_memAttr_cacheable <= io_mshrTask_bits_memAttr_cacheable;
        mshr_task_s1_bits_memAttr_device <= io_mshrTask_bits_memAttr_device;
        mshr_task_s1_bits_memAttr_ewa <= io_mshrTask_bits_memAttr_ewa;
        mshr_task_s1_bits_traceTag <= io_mshrTask_bits_traceTag;
        mshr_task_s1_bits_dataCheckErr <= io_mshrTask_bits_dataCheckErr;
      end
      // task_s2: s1_fire 时锁存 task_s1
      task_s2_valid <= s1_fire;
      if (s1_fire) begin
        task_s2_bits_channel <= task_s1.channel;
        task_s2_bits_txChannel <= task_s1.txChannel;
        task_s2_bits_set <= task_s1.set;
        task_s2_bits_tag <= task_s1.tag;
        task_s2_bits_off <= task_s1.off;
        task_s2_bits_alias <= task_s1.alias_;
        task_s2_bits_vaddr <= task_s1.vaddr;
        task_s2_bits_isKeyword <= task_s1.isKeyword;
        task_s2_bits_opcode <= task_s1.opcode;
        task_s2_bits_param <= task_s1.param;
        task_s2_bits_size <= task_s1.size;
        task_s2_bits_sourceId <= task_s1.sourceId;
        task_s2_bits_bufIdx <= task_s1.bufIdx;
        task_s2_bits_needProbeAckData <= task_s1.needProbeAckData;
        task_s2_bits_denied <= task_s1.denied;
        task_s2_bits_corrupt <= task_s1.corrupt;
        task_s2_bits_mshrTask <= task_s1.mshrTask;
        task_s2_bits_mshrId <= task_s1.mshrId;
        task_s2_bits_aliasTask <= task_s1.aliasTask;
        task_s2_bits_useProbeData <= task_s1.useProbeData;
        task_s2_bits_mshrRetry <= task_s1.mshrRetry;
        task_s2_bits_readProbeDataDown <= task_s1.readProbeDataDown;
        task_s2_bits_fromL2pft <= task_s1.fromL2pft;
        task_s2_bits_needHint <= task_s1.needHint;
        task_s2_bits_dirty <= task_s1.dirty;
        task_s2_bits_way <= task_s1.way;
        task_s2_bits_meta_dirty <= task_s1.meta_dirty;
        task_s2_bits_meta_state <= task_s1.meta_state;
        task_s2_bits_meta_clients <= task_s1.meta_clients;
        task_s2_bits_meta_alias <= task_s1.meta_alias;
        task_s2_bits_meta_prefetch <= task_s1.meta_prefetch;
        task_s2_bits_meta_prefetchSrc <= task_s1.meta_prefetchSrc;
        task_s2_bits_meta_accessed <= task_s1.meta_accessed;
        task_s2_bits_meta_tagErr <= task_s1.meta_tagErr;
        task_s2_bits_meta_dataErr <= task_s1.meta_dataErr;
        task_s2_bits_metaWen <= task_s1.metaWen;
        task_s2_bits_tagWen <= task_s1.tagWen;
        task_s2_bits_dsWen <= task_s1.dsWen;
        task_s2_bits_wayMask <= task_s1.wayMask;
        task_s2_bits_replTask <= task_s1.replTask;
        task_s2_bits_cmoTask <= task_s1.cmoTask;
        task_s2_bits_cmoAll <= task_s1.cmoAll;
        task_s2_bits_reqSource <= task_s1.reqSource;
        task_s2_bits_mergeA <= task_s1.mergeA;
        task_s2_bits_aMergeTask_off <= task_s1.aMergeTask_off;
        task_s2_bits_aMergeTask_alias <= task_s1.aMergeTask_alias;
        task_s2_bits_aMergeTask_vaddr <= task_s1.aMergeTask_vaddr;
        task_s2_bits_aMergeTask_isKeyword <= task_s1.aMergeTask_isKeyword;
        task_s2_bits_aMergeTask_opcode <= task_s1.aMergeTask_opcode;
        task_s2_bits_aMergeTask_param <= task_s1.aMergeTask_param;
        task_s2_bits_aMergeTask_sourceId <= task_s1.aMergeTask_sourceId;
        task_s2_bits_aMergeTask_meta_dirty <= task_s1.aMergeTask_meta_dirty;
        task_s2_bits_aMergeTask_meta_state <= task_s1.aMergeTask_meta_state;
        task_s2_bits_aMergeTask_meta_clients <= task_s1.aMergeTask_meta_clients;
        task_s2_bits_aMergeTask_meta_alias <= task_s1.aMergeTask_meta_alias;
        task_s2_bits_aMergeTask_meta_prefetch <= task_s1.aMergeTask_meta_prefetch;
        task_s2_bits_aMergeTask_meta_prefetchSrc <= task_s1.aMergeTask_meta_prefetchSrc;
        task_s2_bits_aMergeTask_meta_accessed <= task_s1.aMergeTask_meta_accessed;
        task_s2_bits_aMergeTask_meta_tagErr <= task_s1.aMergeTask_meta_tagErr;
        task_s2_bits_aMergeTask_meta_dataErr <= task_s1.aMergeTask_meta_dataErr;
        task_s2_bits_snpHitRelease <= task_s1.snpHitRelease;
        task_s2_bits_snpHitReleaseToInval <= task_s1.snpHitReleaseToInval;
        task_s2_bits_snpHitReleaseToClean <= task_s1.snpHitReleaseToClean;
        task_s2_bits_snpHitReleaseWithData <= task_s1.snpHitReleaseWithData;
        task_s2_bits_snpHitReleaseIdx <= task_s1.snpHitReleaseIdx;
        task_s2_bits_snpHitReleaseMeta_dirty <= task_s1.snpHitReleaseMeta_dirty;
        task_s2_bits_snpHitReleaseMeta_state <= task_s1.snpHitReleaseMeta_state;
        task_s2_bits_snpHitReleaseMeta_clients <= task_s1.snpHitReleaseMeta_clients;
        task_s2_bits_snpHitReleaseMeta_alias <= task_s1.snpHitReleaseMeta_alias;
        task_s2_bits_snpHitReleaseMeta_prefetch <= task_s1.snpHitReleaseMeta_prefetch;
        task_s2_bits_snpHitReleaseMeta_prefetchSrc <= task_s1.snpHitReleaseMeta_prefetchSrc;
        task_s2_bits_snpHitReleaseMeta_accessed <= task_s1.snpHitReleaseMeta_accessed;
        task_s2_bits_snpHitReleaseMeta_tagErr <= task_s1.snpHitReleaseMeta_tagErr;
        task_s2_bits_snpHitReleaseMeta_dataErr <= task_s1.snpHitReleaseMeta_dataErr;
        task_s2_bits_tgtID <= task_s1.tgtID;
        task_s2_bits_srcID <= task_s1.srcID;
        task_s2_bits_txnID <= task_s1.txnID;
        task_s2_bits_homeNID <= task_s1.homeNID;
        task_s2_bits_dbID <= task_s1.dbID;
        task_s2_bits_fwdNID <= task_s1.fwdNID;
        task_s2_bits_fwdTxnID <= task_s1.fwdTxnID;
        task_s2_bits_chiOpcode <= task_s1.chiOpcode;
        task_s2_bits_resp <= task_s1.resp;
        task_s2_bits_fwdState <= task_s1.fwdState;
        task_s2_bits_pCrdType <= task_s1.pCrdType;
        task_s2_bits_retToSrc <= task_s1.retToSrc;
        task_s2_bits_likelyshared <= task_s1.likelyshared;
        task_s2_bits_expCompAck <= task_s1.expCompAck;
        task_s2_bits_allowRetry <= task_s1.allowRetry;
        task_s2_bits_memAttr_allocate <= task_s1.memAttr_allocate;
        task_s2_bits_memAttr_cacheable <= task_s1.memAttr_cacheable;
        task_s2_bits_memAttr_device <= task_s1.memAttr_device;
        task_s2_bits_memAttr_ewa <= task_s1.memAttr_ewa;
        task_s2_bits_traceTag <= task_s1.traceTag;
        task_s2_bits_dataCheckErr <= task_s1.dataCheckErr;
      end
    end
  end
  // ds_mcp2_stall 为无复位 RegNext (Chisel RegNext 无初值)
  always_ff @(posedge clock)
    ds_mcp2_stall <= s1_fire & ~(sinkA_fire & io_sinkA_bits_opcode == 4'h5);

  // ===== s2 类型译码: 是否读 refillBuf/releaseBuf =====
  wire mshrTask_s2 = task_s2_valid & task_s2_bits_mshrTask;
  // a_upwards: 上行 A 响应(GrantData / Grant&dsWen / AccessAckData / HintAck&dsWen)
  wire mshrTask_s2_a_upwards =
    task_s2_bits_channel[0] &
    (task_s2_bits_opcode == 4'h5 | (task_s2_bits_opcode == 4'h4 & task_s2_bits_dsWen) |
     task_s2_bits_opcode == 4'h1 | (task_s2_bits_opcode == 4'h2 & task_s2_bits_dsWen));

  // ===== 输出: 握手 ready =====
  assign io_sinkA_ready   = io_sinkA_ready_0;
  assign io_sinkB_ready   = io_sinkB_ready_0;
  assign io_sinkC_ready   = io_sinkC_ready_0;
  assign io_mshrTask_ready = io_mshrTask_ready_0;

  // ===== 输出: s1Entrance(阻塞同 set 的后续 A) =====
  assign io_s1Entrance_valid =
    (mshr_task_s1_valid & ~ds_mcp2_stall & mshr_task_s1_bits_metaWen) |
    sinkC_fire | sinkB_fire;
  assign io_s1Entrance_bits_set =
    (mshr_task_s1_valid & mshr_task_s1_bits_metaWen) ? mshr_task_s1_bits_set :
    (sinkC_fire ? io_sinkC_bits_set : io_sinkB_bits_set);

  // ===== 输出: Directory 读请求 dirRead_s1 =====
  assign io_dirRead_s1_valid =
    ~ds_mcp2_stall & ((chnl_task_s1_valid & ~mshr_task_s1_valid) |
                      (s1_needs_replRead & ~io_fromMainPipe_blockG_s1));
  assign io_dirRead_s1_bits_tag = task_s1.tag;
  assign io_dirRead_s1_bits_set = task_s1.set;
  // wayMask: mshrRetry 时屏蔽冲突 way (~(1<<way)), 否则全 1
  wire [14:0] wayMask_oh = 15'h1 << mshr_task_s1_bits_way;
  assign io_dirRead_s1_bits_wayMask =
    ~({8{mshr_task_s1_valid & mshr_task_s1_bits_mshrRetry}} & wayMask_oh[7:0]);
  assign io_dirRead_s1_bits_replacerInfo_channel  = task_s1.channel;
  assign io_dirRead_s1_bits_replacerInfo_opcode   = task_s1.opcode[2:0];
  assign io_dirRead_s1_bits_replacerInfo_reqSource = task_s1.reqSource;
  assign io_dirRead_s1_bits_replacerInfo_refill_prefetch =
    s1_needs_replRead & opcode_is_hintAck & mshr_task_s1_bits_dsWen;
  assign io_dirRead_s1_bits_refill = s1_needs_replRead;
  assign io_dirRead_s1_bits_mshrId = task_s1.mshrId;
  assign io_dirRead_s1_bits_cmoAll = task_s1.cmoAll;
  assign io_dirRead_s1_bits_cmoWay = task_s1.way;

  // ===== 输出: taskToPipe_s2 (= task_s2 全字段) =====
  assign io_taskToPipe_s2_valid = task_s2_valid;
  assign io_taskToPipe_s2_bits_channel = task_s2_bits_channel;
  assign io_taskToPipe_s2_bits_txChannel = task_s2_bits_txChannel;
  assign io_taskToPipe_s2_bits_set = task_s2_bits_set;
  assign io_taskToPipe_s2_bits_tag = task_s2_bits_tag;
  assign io_taskToPipe_s2_bits_off = task_s2_bits_off;
  assign io_taskToPipe_s2_bits_alias = task_s2_bits_alias;
  assign io_taskToPipe_s2_bits_vaddr = task_s2_bits_vaddr;
  assign io_taskToPipe_s2_bits_isKeyword = task_s2_bits_isKeyword;
  assign io_taskToPipe_s2_bits_opcode = task_s2_bits_opcode;
  assign io_taskToPipe_s2_bits_param = task_s2_bits_param;
  assign io_taskToPipe_s2_bits_size = task_s2_bits_size;
  assign io_taskToPipe_s2_bits_sourceId = task_s2_bits_sourceId;
  assign io_taskToPipe_s2_bits_bufIdx = task_s2_bits_bufIdx;
  assign io_taskToPipe_s2_bits_needProbeAckData = task_s2_bits_needProbeAckData;
  assign io_taskToPipe_s2_bits_denied = task_s2_bits_denied;
  assign io_taskToPipe_s2_bits_corrupt = task_s2_bits_corrupt;
  assign io_taskToPipe_s2_bits_mshrTask = task_s2_bits_mshrTask;
  assign io_taskToPipe_s2_bits_mshrId = task_s2_bits_mshrId;
  assign io_taskToPipe_s2_bits_aliasTask = task_s2_bits_aliasTask;
  assign io_taskToPipe_s2_bits_useProbeData = task_s2_bits_useProbeData;
  assign io_taskToPipe_s2_bits_mshrRetry = task_s2_bits_mshrRetry;
  assign io_taskToPipe_s2_bits_readProbeDataDown = task_s2_bits_readProbeDataDown;
  assign io_taskToPipe_s2_bits_fromL2pft = task_s2_bits_fromL2pft;
  assign io_taskToPipe_s2_bits_needHint = task_s2_bits_needHint;
  assign io_taskToPipe_s2_bits_dirty = task_s2_bits_dirty;
  assign io_taskToPipe_s2_bits_way = task_s2_bits_way;
  assign io_taskToPipe_s2_bits_meta_dirty = task_s2_bits_meta_dirty;
  assign io_taskToPipe_s2_bits_meta_state = task_s2_bits_meta_state;
  assign io_taskToPipe_s2_bits_meta_clients = task_s2_bits_meta_clients;
  assign io_taskToPipe_s2_bits_meta_alias = task_s2_bits_meta_alias;
  assign io_taskToPipe_s2_bits_meta_prefetch = task_s2_bits_meta_prefetch;
  assign io_taskToPipe_s2_bits_meta_prefetchSrc = task_s2_bits_meta_prefetchSrc;
  assign io_taskToPipe_s2_bits_meta_accessed = task_s2_bits_meta_accessed;
  assign io_taskToPipe_s2_bits_meta_tagErr = task_s2_bits_meta_tagErr;
  assign io_taskToPipe_s2_bits_meta_dataErr = task_s2_bits_meta_dataErr;
  assign io_taskToPipe_s2_bits_metaWen = task_s2_bits_metaWen;
  assign io_taskToPipe_s2_bits_tagWen = task_s2_bits_tagWen;
  assign io_taskToPipe_s2_bits_dsWen = task_s2_bits_dsWen;
  assign io_taskToPipe_s2_bits_wayMask = task_s2_bits_wayMask;
  assign io_taskToPipe_s2_bits_replTask = task_s2_bits_replTask;
  assign io_taskToPipe_s2_bits_cmoTask = task_s2_bits_cmoTask;
  assign io_taskToPipe_s2_bits_cmoAll = task_s2_bits_cmoAll;
  assign io_taskToPipe_s2_bits_reqSource = task_s2_bits_reqSource;
  assign io_taskToPipe_s2_bits_mergeA = task_s2_bits_mergeA;
  assign io_taskToPipe_s2_bits_aMergeTask_off = task_s2_bits_aMergeTask_off;
  assign io_taskToPipe_s2_bits_aMergeTask_alias = task_s2_bits_aMergeTask_alias;
  assign io_taskToPipe_s2_bits_aMergeTask_vaddr = task_s2_bits_aMergeTask_vaddr;
  assign io_taskToPipe_s2_bits_aMergeTask_isKeyword = task_s2_bits_aMergeTask_isKeyword;
  assign io_taskToPipe_s2_bits_aMergeTask_opcode = task_s2_bits_aMergeTask_opcode;
  assign io_taskToPipe_s2_bits_aMergeTask_param = task_s2_bits_aMergeTask_param;
  assign io_taskToPipe_s2_bits_aMergeTask_sourceId = task_s2_bits_aMergeTask_sourceId;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_dirty = task_s2_bits_aMergeTask_meta_dirty;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_state = task_s2_bits_aMergeTask_meta_state;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_clients = task_s2_bits_aMergeTask_meta_clients;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_alias = task_s2_bits_aMergeTask_meta_alias;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_prefetch = task_s2_bits_aMergeTask_meta_prefetch;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_prefetchSrc = task_s2_bits_aMergeTask_meta_prefetchSrc;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_accessed = task_s2_bits_aMergeTask_meta_accessed;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_tagErr = task_s2_bits_aMergeTask_meta_tagErr;
  assign io_taskToPipe_s2_bits_aMergeTask_meta_dataErr = task_s2_bits_aMergeTask_meta_dataErr;
  assign io_taskToPipe_s2_bits_snpHitRelease = task_s2_bits_snpHitRelease;
  assign io_taskToPipe_s2_bits_snpHitReleaseToInval = task_s2_bits_snpHitReleaseToInval;
  assign io_taskToPipe_s2_bits_snpHitReleaseToClean = task_s2_bits_snpHitReleaseToClean;
  assign io_taskToPipe_s2_bits_snpHitReleaseWithData = task_s2_bits_snpHitReleaseWithData;
  assign io_taskToPipe_s2_bits_snpHitReleaseIdx = task_s2_bits_snpHitReleaseIdx;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_dirty = task_s2_bits_snpHitReleaseMeta_dirty;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_state = task_s2_bits_snpHitReleaseMeta_state;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_clients = task_s2_bits_snpHitReleaseMeta_clients;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_alias = task_s2_bits_snpHitReleaseMeta_alias;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetch = task_s2_bits_snpHitReleaseMeta_prefetch;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_prefetchSrc = task_s2_bits_snpHitReleaseMeta_prefetchSrc;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_accessed = task_s2_bits_snpHitReleaseMeta_accessed;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_tagErr = task_s2_bits_snpHitReleaseMeta_tagErr;
  assign io_taskToPipe_s2_bits_snpHitReleaseMeta_dataErr = task_s2_bits_snpHitReleaseMeta_dataErr;
  assign io_taskToPipe_s2_bits_tgtID = task_s2_bits_tgtID;
  assign io_taskToPipe_s2_bits_srcID = task_s2_bits_srcID;
  assign io_taskToPipe_s2_bits_txnID = task_s2_bits_txnID;
  assign io_taskToPipe_s2_bits_homeNID = task_s2_bits_homeNID;
  assign io_taskToPipe_s2_bits_dbID = task_s2_bits_dbID;
  assign io_taskToPipe_s2_bits_fwdNID = task_s2_bits_fwdNID;
  assign io_taskToPipe_s2_bits_fwdTxnID = task_s2_bits_fwdTxnID;
  assign io_taskToPipe_s2_bits_chiOpcode = task_s2_bits_chiOpcode;
  assign io_taskToPipe_s2_bits_resp = task_s2_bits_resp;
  assign io_taskToPipe_s2_bits_fwdState = task_s2_bits_fwdState;
  assign io_taskToPipe_s2_bits_pCrdType = task_s2_bits_pCrdType;
  assign io_taskToPipe_s2_bits_retToSrc = task_s2_bits_retToSrc;
  assign io_taskToPipe_s2_bits_likelyshared = task_s2_bits_likelyshared;
  assign io_taskToPipe_s2_bits_expCompAck = task_s2_bits_expCompAck;
  assign io_taskToPipe_s2_bits_allowRetry = task_s2_bits_allowRetry;
  assign io_taskToPipe_s2_bits_memAttr_allocate = task_s2_bits_memAttr_allocate;
  assign io_taskToPipe_s2_bits_memAttr_cacheable = task_s2_bits_memAttr_cacheable;
  assign io_taskToPipe_s2_bits_memAttr_device = task_s2_bits_memAttr_device;
  assign io_taskToPipe_s2_bits_memAttr_ewa = task_s2_bits_memAttr_ewa;
  assign io_taskToPipe_s2_bits_traceTag = task_s2_bits_traceTag;
  assign io_taskToPipe_s2_bits_dataCheckErr = task_s2_bits_dataCheckErr;

  // ===== 输出: taskInfo_s1 (= task_s1 全字段, 给 MainPipe 提前 hint) =====
  assign io_taskInfo_s1_valid = s1_fire;
  assign io_taskInfo_s1_bits_channel = task_s1.channel;
  assign io_taskInfo_s1_bits_txChannel = task_s1.txChannel;
  assign io_taskInfo_s1_bits_set = task_s1.set;
  assign io_taskInfo_s1_bits_tag = task_s1.tag;
  assign io_taskInfo_s1_bits_off = task_s1.off;
  assign io_taskInfo_s1_bits_alias = task_s1.alias_;
  assign io_taskInfo_s1_bits_vaddr = task_s1.vaddr;
  assign io_taskInfo_s1_bits_isKeyword = task_s1.isKeyword;
  assign io_taskInfo_s1_bits_opcode = task_s1.opcode;
  assign io_taskInfo_s1_bits_param = task_s1.param;
  assign io_taskInfo_s1_bits_size = task_s1.size;
  assign io_taskInfo_s1_bits_sourceId = task_s1.sourceId;
  assign io_taskInfo_s1_bits_bufIdx = task_s1.bufIdx;
  assign io_taskInfo_s1_bits_needProbeAckData = task_s1.needProbeAckData;
  assign io_taskInfo_s1_bits_denied = task_s1.denied;
  assign io_taskInfo_s1_bits_corrupt = task_s1.corrupt;
  assign io_taskInfo_s1_bits_mshrTask = task_s1.mshrTask;
  assign io_taskInfo_s1_bits_mshrId = task_s1.mshrId;
  assign io_taskInfo_s1_bits_aliasTask = task_s1.aliasTask;
  assign io_taskInfo_s1_bits_useProbeData = task_s1.useProbeData;
  assign io_taskInfo_s1_bits_mshrRetry = task_s1.mshrRetry;
  assign io_taskInfo_s1_bits_readProbeDataDown = task_s1.readProbeDataDown;
  assign io_taskInfo_s1_bits_fromL2pft = task_s1.fromL2pft;
  assign io_taskInfo_s1_bits_needHint = task_s1.needHint;
  assign io_taskInfo_s1_bits_dirty = task_s1.dirty;
  assign io_taskInfo_s1_bits_way = task_s1.way;
  assign io_taskInfo_s1_bits_meta_dirty = task_s1.meta_dirty;
  assign io_taskInfo_s1_bits_meta_state = task_s1.meta_state;
  assign io_taskInfo_s1_bits_meta_clients = task_s1.meta_clients;
  assign io_taskInfo_s1_bits_meta_alias = task_s1.meta_alias;
  assign io_taskInfo_s1_bits_meta_prefetch = task_s1.meta_prefetch;
  assign io_taskInfo_s1_bits_meta_prefetchSrc = task_s1.meta_prefetchSrc;
  assign io_taskInfo_s1_bits_meta_accessed = task_s1.meta_accessed;
  assign io_taskInfo_s1_bits_meta_tagErr = task_s1.meta_tagErr;
  assign io_taskInfo_s1_bits_meta_dataErr = task_s1.meta_dataErr;
  assign io_taskInfo_s1_bits_metaWen = task_s1.metaWen;
  assign io_taskInfo_s1_bits_tagWen = task_s1.tagWen;
  assign io_taskInfo_s1_bits_dsWen = task_s1.dsWen;
  assign io_taskInfo_s1_bits_wayMask = task_s1.wayMask;
  assign io_taskInfo_s1_bits_replTask = task_s1.replTask;
  assign io_taskInfo_s1_bits_cmoTask = task_s1.cmoTask;
  assign io_taskInfo_s1_bits_cmoAll = task_s1.cmoAll;
  assign io_taskInfo_s1_bits_reqSource = task_s1.reqSource;
  assign io_taskInfo_s1_bits_mergeA = task_s1.mergeA;
  assign io_taskInfo_s1_bits_aMergeTask_off = task_s1.aMergeTask_off;
  assign io_taskInfo_s1_bits_aMergeTask_alias = task_s1.aMergeTask_alias;
  assign io_taskInfo_s1_bits_aMergeTask_vaddr = task_s1.aMergeTask_vaddr;
  assign io_taskInfo_s1_bits_aMergeTask_isKeyword = task_s1.aMergeTask_isKeyword;
  assign io_taskInfo_s1_bits_aMergeTask_opcode = task_s1.aMergeTask_opcode;
  assign io_taskInfo_s1_bits_aMergeTask_param = task_s1.aMergeTask_param;
  assign io_taskInfo_s1_bits_aMergeTask_sourceId = task_s1.aMergeTask_sourceId;
  assign io_taskInfo_s1_bits_aMergeTask_meta_dirty = task_s1.aMergeTask_meta_dirty;
  assign io_taskInfo_s1_bits_aMergeTask_meta_state = task_s1.aMergeTask_meta_state;
  assign io_taskInfo_s1_bits_aMergeTask_meta_clients = task_s1.aMergeTask_meta_clients;
  assign io_taskInfo_s1_bits_aMergeTask_meta_alias = task_s1.aMergeTask_meta_alias;
  assign io_taskInfo_s1_bits_aMergeTask_meta_prefetch = task_s1.aMergeTask_meta_prefetch;
  assign io_taskInfo_s1_bits_aMergeTask_meta_prefetchSrc = task_s1.aMergeTask_meta_prefetchSrc;
  assign io_taskInfo_s1_bits_aMergeTask_meta_accessed = task_s1.aMergeTask_meta_accessed;
  assign io_taskInfo_s1_bits_aMergeTask_meta_tagErr = task_s1.aMergeTask_meta_tagErr;
  assign io_taskInfo_s1_bits_aMergeTask_meta_dataErr = task_s1.aMergeTask_meta_dataErr;
  assign io_taskInfo_s1_bits_snpHitRelease = task_s1.snpHitRelease;
  assign io_taskInfo_s1_bits_snpHitReleaseToInval = task_s1.snpHitReleaseToInval;
  assign io_taskInfo_s1_bits_snpHitReleaseToClean = task_s1.snpHitReleaseToClean;
  assign io_taskInfo_s1_bits_snpHitReleaseWithData = task_s1.snpHitReleaseWithData;
  assign io_taskInfo_s1_bits_snpHitReleaseIdx = task_s1.snpHitReleaseIdx;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_dirty = task_s1.snpHitReleaseMeta_dirty;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_state = task_s1.snpHitReleaseMeta_state;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_clients = task_s1.snpHitReleaseMeta_clients;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_alias = task_s1.snpHitReleaseMeta_alias;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_prefetch = task_s1.snpHitReleaseMeta_prefetch;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_prefetchSrc = task_s1.snpHitReleaseMeta_prefetchSrc;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_accessed = task_s1.snpHitReleaseMeta_accessed;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_tagErr = task_s1.snpHitReleaseMeta_tagErr;
  assign io_taskInfo_s1_bits_snpHitReleaseMeta_dataErr = task_s1.snpHitReleaseMeta_dataErr;
  assign io_taskInfo_s1_bits_tgtID = task_s1.tgtID;
  assign io_taskInfo_s1_bits_srcID = task_s1.srcID;
  assign io_taskInfo_s1_bits_txnID = task_s1.txnID;
  assign io_taskInfo_s1_bits_homeNID = task_s1.homeNID;
  assign io_taskInfo_s1_bits_dbID = task_s1.dbID;
  assign io_taskInfo_s1_bits_fwdNID = task_s1.fwdNID;
  assign io_taskInfo_s1_bits_fwdTxnID = task_s1.fwdTxnID;
  assign io_taskInfo_s1_bits_chiOpcode = task_s1.chiOpcode;
  assign io_taskInfo_s1_bits_resp = task_s1.resp;
  assign io_taskInfo_s1_bits_fwdState = task_s1.fwdState;
  assign io_taskInfo_s1_bits_pCrdType = task_s1.pCrdType;
  assign io_taskInfo_s1_bits_retToSrc = task_s1.retToSrc;
  assign io_taskInfo_s1_bits_likelyshared = task_s1.likelyshared;
  assign io_taskInfo_s1_bits_expCompAck = task_s1.expCompAck;
  assign io_taskInfo_s1_bits_allowRetry = task_s1.allowRetry;
  assign io_taskInfo_s1_bits_memAttr_allocate = task_s1.memAttr_allocate;
  assign io_taskInfo_s1_bits_memAttr_cacheable = task_s1.memAttr_cacheable;
  assign io_taskInfo_s1_bits_memAttr_device = task_s1.memAttr_device;
  assign io_taskInfo_s1_bits_memAttr_ewa = task_s1.memAttr_ewa;
  assign io_taskInfo_s1_bits_traceTag = task_s1.traceTag;
  assign io_taskInfo_s1_bits_dataCheckErr = task_s1.dataCheckErr;

  // ===== 输出: refillBuf / releaseBuf 读 =====
  // refillBuf: replTask 回 TX(txChannel[0]) 的写回族(WriteBackFull/WriteEvict*/Evict)
  //            或上行 A 响应且非用 ProbeData
  assign io_refillBufRead_s2_valid =
    mshrTask_s2 &
    ((task_s2_bits_replTask & task_s2_bits_txChannel[0] &
      (task_s2_bits_chiOpcode == 7'h1B | task_s2_bits_chiOpcode == 7'h15 |
       task_s2_bits_chiOpcode == 7'h42 | task_s2_bits_chiOpcode == 7'hD)) |
     (mshrTask_s2_a_upwards & ~task_s2_bits_useProbeData));
  assign io_refillBufRead_s2_bits_id = task_s2_bits_mshrId;
  // releaseBuf: mshr 任务读 ProbeData 下行/上行用 ProbeData; 或非 mshr 的 B 探测命中带数据释放
  assign io_releaseBufRead_s2_valid =
    task_s2_valid &
    (mshrTask_s2 ? (task_s2_bits_readProbeDataDown |
                    (mshrTask_s2_a_upwards & task_s2_bits_useProbeData)) :
                   (~mshrTask_s2 & task_s2_bits_channel[1] &
                    task_s2_bits_snpHitReleaseWithData));
  assign io_releaseBufRead_s2_bits_id =
    task_s2_bits_snpHitRelease ? task_s2_bits_snpHitReleaseIdx : task_s2_bits_mshrId;

  // ===== 输出: 各级 set/tag 状态(给 MSHR/TX 同址阻塞) =====
  assign io_status_s1_tags_0 = io_sinkC_bits_tag;
  assign io_status_s1_tags_1 = io_sinkB_bits_tag;
  assign io_status_s1_tags_2 = io_ATag;
  assign io_status_s1_tags_3 = mshr_task_s1_bits_tag;
  assign io_status_s1_sets_0 = io_sinkC_bits_set;
  assign io_status_s1_sets_1 = io_sinkB_bits_set;
  assign io_status_s1_sets_2 = io_ASet;
  assign io_status_s1_sets_3 = mshr_task_s1_bits_set;
  assign io_status_vec_0_valid        = task_s1_valid;
  assign io_status_vec_0_bits_channel = task_s1.channel;
  assign io_status_vec_1_valid        = task_s2_valid;
  assign io_status_vec_1_bits_channel = task_s2_bits_channel;
  assign io_status_vec_toTX_0_valid         = task_s1_valid;
  assign io_status_vec_toTX_0_bits_channel  = task_s1.channel;
  assign io_status_vec_toTX_0_bits_txChannel = task_s1.txChannel;
  assign io_status_vec_toTX_0_bits_mshrTask  = task_s1.mshrTask;
  assign io_status_vec_toTX_1_valid         = task_s2_valid;
  assign io_status_vec_toTX_1_bits_channel  = task_s2_bits_channel;
  assign io_status_vec_toTX_1_bits_txChannel = task_s2_bits_txChannel;
  assign io_status_vec_toTX_1_bits_mshrTask  = task_s2_bits_mshrTask;

endmodule
