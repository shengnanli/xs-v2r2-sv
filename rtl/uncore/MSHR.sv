// =============================================================================
//  MSHR —— coupledL2 (tl2chi) L2 缓存 Miss Status Handling Register 可读重写核
//          (xs_MSHR_core)  ★ L2 一致性协议的心脏 ★
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/tl2chi/MSHR.scala
//  这是单个 MSHR 槽的有限状态机: 处理一次 L2 miss / snoop / CMO 事务的完整生命
//  周期, 在 CHI 互联上发 ReadUnique/MakeUnique/WriteBackFull/Evict 等请求, 向上层
//  core 发 Probe, 收 ProbeAck/CompData/Comp/CompDBIDResp, 最终把 refill/probeack/
//  release 任务投到 MainPipe。
//
//  ===== 一致性状态机的两类标志位 (FSMState) =====
//   s_* (schedule): "还需要发出的任务", 复位/分配后由 alloc 给出初值, 发出后置 1。
//   w_* (wait):     "还需要等待的响应", 收齐后置 1。
//   全 1 (no_schedule && no_wait) => will_free, MSHR 退休。
//
//   s_acquire   : 还需向 CHI 发 Read/Make/CMO 请求
//   s_rprobe    : 还需发 replacement-probe (替换被占 way 前先探上层)
//   s_pprobe    : 还需发 snoop-probe (被 snoop 命中需先探上层)
//   s_release   : 还需向下 release (WriteBack/Evict)
//   s_probeack  : 还需回 snoop 的 ProbeAck/SnpResp
//   s_refill    : 还需把数据 refill 给上层 (Grant)
//   s_rcompack  : 还需对读事务回 CompAck
//   s_wcompack  : 还需对写事务回 CompAck (WriteEvictOrEvict)
//   s_cbwrdata  : 还需发 CopyBackWrData (回写脏数据)
//   s_reissue   : 还需重发(协议 RetryAck 后, 等 PCrdGrant)
//   s_dct       : 还需做 Direct Cache Transfer (snoop forward)
//   s_cmoresp/s_cmometaw : CMO 完成响应 / 元数据补写
//   w_grant{first,last}/w_grant : 等 CompData/Comp
//   w_rprobeack{first,last}/w_pprobeack{first,last} : 等 ProbeAck
//   w_releaseack : 等 release 的 CompDBIDResp/Comp
//   w_replResp   : 等 replacer 回 way (miss 替换选路)
//
//  ===== 单态化参数 (firtool MSHR.sv) =====
//   beatSize=2 (beatCnt 1bit; CompData 一拍收完两 beat -> w_grantlast:=w_grantfirst)
//   afterIssueC=true, afterIssueEb=true (有 DataSepResp/RespSepData/WriteEvictOrEvict)
//   enableNS=false。
//
//  ===== X 铁律 =====
//   分配前 req_valid=0, 所有输出由 req_valid/state 门控; 数组无越界索引; 优先 mux 顺序
//   严格对齐 Scala 的 ParallelPriorityMux / last-connect-wins。
// =============================================================================
module xs_MSHR_core
  import mshr_pkg::*;
(
  input  logic         clock,
  input  logic         reset,
  input  logic [7:0]   io_id,

  // ---- status (给 MSHRCtl 用于 block/nest 判定) ----
  output logic         io_status_valid,
  output logic [2:0]   io_status_bits_channel,
  output logic [8:0]   io_status_bits_set,
  output logic [30:0]  io_status_bits_reqTag,
  output logic [30:0]  io_status_bits_metaTag,
  output logic         io_status_bits_needsRepl,
  output logic         io_status_bits_w_c_resp,
  output logic         io_status_bits_will_free,
  output logic [4:0]   io_status_bits_reqSource,
  output logic         io_status_bits_is_miss,
  output logic         io_status_bits_is_prefetch,

  // ---- msInfo (给 MSHRCtl 嵌套/合并/替换决策) ----
  output logic         io_msInfo_valid,
  output logic [2:0]   io_msInfo_bits_channel,
  output logic [8:0]   io_msInfo_bits_set,
  output logic [2:0]   io_msInfo_bits_way,
  output logic [30:0]  io_msInfo_bits_reqTag,
  output logic         io_msInfo_bits_willFree,
  output logic         io_msInfo_bits_aliasTask,
  output logic         io_msInfo_bits_needRelease,
  output logic         io_msInfo_bits_blockRefill,
  output logic         io_msInfo_bits_meta_dirty,
  output logic [1:0]   io_msInfo_bits_meta_state,
  output logic         io_msInfo_bits_meta_clients,
  output logic [1:0]   io_msInfo_bits_meta_alias,
  output logic         io_msInfo_bits_meta_prefetch,
  output logic [2:0]   io_msInfo_bits_meta_prefetchSrc,
  output logic         io_msInfo_bits_meta_accessed,
  output logic         io_msInfo_bits_meta_tagErr,
  output logic         io_msInfo_bits_meta_dataErr,
  output logic [30:0]  io_msInfo_bits_metaTag,
  output logic         io_msInfo_bits_dirHit,
  output logic         io_msInfo_bits_isAcqOrPrefetch,
  output logic         io_msInfo_bits_isPrefetch,
  output logic [2:0]   io_msInfo_bits_param,
  output logic         io_msInfo_bits_mergeA,
  output logic         io_msInfo_bits_w_grantfirst,
  output logic         io_msInfo_bits_s_release,
  output logic         io_msInfo_bits_s_refill,
  output logic         io_msInfo_bits_s_cmoresp,
  output logic         io_msInfo_bits_s_cmometaw,
  output logic         io_msInfo_bits_w_releaseack,
  output logic         io_msInfo_bits_w_replResp,
  output logic         io_msInfo_bits_w_rprobeacklast,
  output logic         io_msInfo_bits_replaceData,
  output logic         io_msInfo_bits_releaseToClean,

  // ---- alloc (MSHRCtl 分配一个新事务) ----
  input  logic         io_alloc_valid,
  input  logic         io_alloc_bits_dirResult_hit,
  input  logic [30:0]  io_alloc_bits_dirResult_tag,
  input  logic [8:0]   io_alloc_bits_dirResult_set,
  input  logic [2:0]   io_alloc_bits_dirResult_way,
  input  logic         io_alloc_bits_dirResult_meta_dirty,
  input  logic [1:0]   io_alloc_bits_dirResult_meta_state,
  input  logic         io_alloc_bits_dirResult_meta_clients,
  input  logic [1:0]   io_alloc_bits_dirResult_meta_alias,
  input  logic         io_alloc_bits_dirResult_meta_prefetch,
  input  logic [2:0]   io_alloc_bits_dirResult_meta_prefetchSrc,
  input  logic         io_alloc_bits_dirResult_meta_accessed,
  input  logic         io_alloc_bits_dirResult_meta_tagErr,
  input  logic         io_alloc_bits_dirResult_meta_dataErr,
  input  logic         io_alloc_bits_dirResult_error,
  input  logic         io_alloc_bits_state_s_acquire,
  input  logic         io_alloc_bits_state_s_rprobe,
  input  logic         io_alloc_bits_state_s_pprobe,
  input  logic         io_alloc_bits_state_s_release,
  input  logic         io_alloc_bits_state_s_probeack,
  input  logic         io_alloc_bits_state_s_refill,
  input  logic         io_alloc_bits_state_s_cmoresp,
  input  logic         io_alloc_bits_state_w_rprobeackfirst,
  input  logic         io_alloc_bits_state_w_rprobeacklast,
  input  logic         io_alloc_bits_state_w_pprobeackfirst,
  input  logic         io_alloc_bits_state_w_pprobeacklast,
  input  logic         io_alloc_bits_state_w_grantfirst,
  input  logic         io_alloc_bits_state_w_grantlast,
  input  logic         io_alloc_bits_state_w_grant,
  input  logic         io_alloc_bits_state_w_releaseack,
  input  logic         io_alloc_bits_state_w_replResp,
  input  logic         io_alloc_bits_state_s_rcompack,
  input  logic         io_alloc_bits_state_s_dct,
  input  logic [2:0]   io_alloc_bits_task_channel,
  input  logic [8:0]   io_alloc_bits_task_set,
  input  logic [30:0]  io_alloc_bits_task_tag,
  input  logic [5:0]   io_alloc_bits_task_off,
  input  logic [1:0]   io_alloc_bits_task_alias,
  input  logic         io_alloc_bits_task_isKeyword,
  input  logic [3:0]   io_alloc_bits_task_opcode,
  input  logic [2:0]   io_alloc_bits_task_param,
  input  logic [6:0]   io_alloc_bits_task_sourceId,
  input  logic         io_alloc_bits_task_aliasTask,
  input  logic         io_alloc_bits_task_fromL2pft,
  input  logic [4:0]   io_alloc_bits_task_reqSource,
  input  logic         io_alloc_bits_task_snpHitRelease,
  input  logic         io_alloc_bits_task_snpHitReleaseToInval,
  input  logic         io_alloc_bits_task_snpHitReleaseToClean,
  input  logic         io_alloc_bits_task_snpHitReleaseWithData,
  input  logic [7:0]   io_alloc_bits_task_snpHitReleaseIdx,
  input  logic         io_alloc_bits_task_snpHitReleaseMeta_dirty,
  input  logic [1:0]   io_alloc_bits_task_snpHitReleaseMeta_state,
  input  logic         io_alloc_bits_task_snpHitReleaseMeta_clients,
  input  logic [1:0]   io_alloc_bits_task_snpHitReleaseMeta_alias,
  input  logic         io_alloc_bits_task_snpHitReleaseMeta_prefetch,
  input  logic [2:0]   io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc,
  input  logic         io_alloc_bits_task_snpHitReleaseMeta_accessed,
  input  logic         io_alloc_bits_task_snpHitReleaseMeta_tagErr,
  input  logic         io_alloc_bits_task_snpHitReleaseMeta_dataErr,
  input  logic [10:0]  io_alloc_bits_task_srcID,
  input  logic [11:0]  io_alloc_bits_task_txnID,
  input  logic [10:0]  io_alloc_bits_task_fwdNID,
  input  logic [11:0]  io_alloc_bits_task_fwdTxnID,
  input  logic [6:0]   io_alloc_bits_task_chiOpcode,
  input  logic         io_alloc_bits_task_retToSrc,
  input  logic         io_alloc_bits_task_traceTag,

  // ---- tasks.txreq (CHI REQ 通道) ----
  input  logic         io_tasks_txreq_ready,
  output logic         io_tasks_txreq_valid,
  output logic [10:0]  io_tasks_txreq_bits_tgtID,
  output logic [11:0]  io_tasks_txreq_bits_txnID,
  output logic [6:0]   io_tasks_txreq_bits_opcode,
  output logic [47:0]  io_tasks_txreq_bits_addr,
  output logic         io_tasks_txreq_bits_likelyshared,
  output logic         io_tasks_txreq_bits_allowRetry,
  output logic [3:0]   io_tasks_txreq_bits_pCrdType,
  output logic         io_tasks_txreq_bits_memAttr_allocate,
  output logic         io_tasks_txreq_bits_memAttr_ewa,
  output logic         io_tasks_txreq_bits_expCompAck,

  // ---- tasks.txrsp (CHI RSP 通道, CompAck) ----
  input  logic         io_tasks_txrsp_ready,
  output logic         io_tasks_txrsp_valid,
  output logic [10:0]  io_tasks_txrsp_bits_tgtID,
  output logic [11:0]  io_tasks_txrsp_bits_txnID,
  output logic         io_tasks_txrsp_bits_traceTag,

  // ---- tasks.source_b (向上层 core 发 Probe) ----
  input  logic         io_tasks_source_b_ready,
  output logic         io_tasks_source_b_valid,
  output logic [30:0]  io_tasks_source_b_bits_tag,
  output logic [8:0]   io_tasks_source_b_bits_set,
  output logic [1:0]   io_tasks_source_b_bits_param,
  output logic [1:0]   io_tasks_source_b_bits_alias,

  // ---- tasks.mainpipe (refill/probeack/release/cbwrdata/dct/cmometaw 任务) ----
  input  logic         io_tasks_mainpipe_ready,
  output logic         io_tasks_mainpipe_valid,
  output logic [2:0]   io_tasks_mainpipe_bits_channel,
  output logic [2:0]   io_tasks_mainpipe_bits_txChannel,
  output logic [8:0]   io_tasks_mainpipe_bits_set,
  output logic [30:0]  io_tasks_mainpipe_bits_tag,
  output logic [5:0]   io_tasks_mainpipe_bits_off,
  output logic [1:0]   io_tasks_mainpipe_bits_alias,
  output logic         io_tasks_mainpipe_bits_isKeyword,
  output logic [3:0]   io_tasks_mainpipe_bits_opcode,
  output logic [2:0]   io_tasks_mainpipe_bits_param,
  output logic [2:0]   io_tasks_mainpipe_bits_size,
  output logic [6:0]   io_tasks_mainpipe_bits_sourceId,
  output logic         io_tasks_mainpipe_bits_denied,
  output logic         io_tasks_mainpipe_bits_corrupt,
  output logic [7:0]   io_tasks_mainpipe_bits_mshrId,
  output logic         io_tasks_mainpipe_bits_aliasTask,
  output logic         io_tasks_mainpipe_bits_useProbeData,
  output logic         io_tasks_mainpipe_bits_mshrRetry,
  output logic         io_tasks_mainpipe_bits_readProbeDataDown,
  output logic         io_tasks_mainpipe_bits_fromL2pft,
  output logic         io_tasks_mainpipe_bits_dirty,
  output logic [2:0]   io_tasks_mainpipe_bits_way,
  output logic         io_tasks_mainpipe_bits_meta_dirty,
  output logic [1:0]   io_tasks_mainpipe_bits_meta_state,
  output logic         io_tasks_mainpipe_bits_meta_clients,
  output logic [1:0]   io_tasks_mainpipe_bits_meta_alias,
  output logic         io_tasks_mainpipe_bits_meta_prefetch,
  output logic [2:0]   io_tasks_mainpipe_bits_meta_prefetchSrc,
  output logic         io_tasks_mainpipe_bits_meta_accessed,
  output logic         io_tasks_mainpipe_bits_meta_tagErr,
  output logic         io_tasks_mainpipe_bits_meta_dataErr,
  output logic         io_tasks_mainpipe_bits_metaWen,
  output logic         io_tasks_mainpipe_bits_tagWen,
  output logic         io_tasks_mainpipe_bits_dsWen,
  output logic         io_tasks_mainpipe_bits_replTask,
  output logic         io_tasks_mainpipe_bits_cmoTask,
  output logic [4:0]   io_tasks_mainpipe_bits_reqSource,
  output logic         io_tasks_mainpipe_bits_mergeA,
  output logic [5:0]   io_tasks_mainpipe_bits_aMergeTask_off,
  output logic [1:0]   io_tasks_mainpipe_bits_aMergeTask_alias,
  output logic [43:0]  io_tasks_mainpipe_bits_aMergeTask_vaddr,
  output logic         io_tasks_mainpipe_bits_aMergeTask_isKeyword,
  output logic [2:0]   io_tasks_mainpipe_bits_aMergeTask_opcode,
  output logic [2:0]   io_tasks_mainpipe_bits_aMergeTask_param,
  output logic [6:0]   io_tasks_mainpipe_bits_aMergeTask_sourceId,
  output logic         io_tasks_mainpipe_bits_aMergeTask_meta_dirty,
  output logic [1:0]   io_tasks_mainpipe_bits_aMergeTask_meta_state,
  output logic         io_tasks_mainpipe_bits_aMergeTask_meta_clients,
  output logic [1:0]   io_tasks_mainpipe_bits_aMergeTask_meta_alias,
  output logic         io_tasks_mainpipe_bits_aMergeTask_meta_accessed,
  output logic         io_tasks_mainpipe_bits_snpHitRelease,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseToInval,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseToClean,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseWithData,
  output logic [7:0]   io_tasks_mainpipe_bits_snpHitReleaseIdx,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty,
  output logic [1:0]   io_tasks_mainpipe_bits_snpHitReleaseMeta_state,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseMeta_clients,
  output logic [1:0]   io_tasks_mainpipe_bits_snpHitReleaseMeta_alias,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch,
  output logic [2:0]   io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr,
  output logic         io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr,
  output logic [10:0]  io_tasks_mainpipe_bits_tgtID,
  output logic [11:0]  io_tasks_mainpipe_bits_txnID,
  output logic [10:0]  io_tasks_mainpipe_bits_homeNID,
  output logic [11:0]  io_tasks_mainpipe_bits_dbID,
  output logic [6:0]   io_tasks_mainpipe_bits_chiOpcode,
  output logic [2:0]   io_tasks_mainpipe_bits_resp,
  output logic [2:0]   io_tasks_mainpipe_bits_fwdState,
  output logic         io_tasks_mainpipe_bits_retToSrc,
  output logic         io_tasks_mainpipe_bits_likelyshared,
  output logic         io_tasks_mainpipe_bits_expCompAck,
  output logic         io_tasks_mainpipe_bits_allowRetry,
  output logic         io_tasks_mainpipe_bits_memAttr_allocate,
  output logic         io_tasks_mainpipe_bits_memAttr_cacheable,
  output logic         io_tasks_mainpipe_bits_memAttr_ewa,
  output logic         io_tasks_mainpipe_bits_traceTag,
  output logic         io_tasks_mainpipe_bits_dataCheckErr,

  // ---- resps (来自 SinkC / RXRSP / RXDAT 的响应) ----
  input  logic         io_resps_sinkC_valid,
  input  logic [2:0]   io_resps_sinkC_bits_opcode,
  input  logic [2:0]   io_resps_sinkC_bits_param,
  input  logic         io_resps_sinkC_bits_last,
  input  logic         io_resps_sinkC_bits_denied,
  input  logic         io_resps_sinkC_bits_corrupt,
  input  logic         io_resps_rxrsp_valid,
  input  logic [6:0]   io_resps_rxrsp_bits_chiOpcode,
  input  logic [10:0]  io_resps_rxrsp_bits_srcID,
  input  logic [11:0]  io_resps_rxrsp_bits_dbID,
  input  logic [2:0]   io_resps_rxrsp_bits_resp,
  input  logic [3:0]   io_resps_rxrsp_bits_pCrdType,
  input  logic [1:0]   io_resps_rxrsp_bits_respErr,
  input  logic         io_resps_rxrsp_bits_traceTag,
  input  logic         io_resps_rxdat_valid,
  input  logic         io_resps_rxdat_bits_corrupt,
  input  logic [6:0]   io_resps_rxdat_bits_chiOpcode,
  input  logic [10:0]  io_resps_rxdat_bits_homeNID,
  input  logic [11:0]  io_resps_rxdat_bits_dbID,
  input  logic [2:0]   io_resps_rxdat_bits_resp,
  input  logic [1:0]   io_resps_rxdat_bits_respErr,
  input  logic         io_resps_rxdat_bits_traceTag,
  input  logic         io_resps_rxdat_bits_dataCheckErr,

  // ---- nestedwb (嵌套回写: 别的 MSHR 在同 set/tag 上的 release/snoop 改了 meta) ----
  input  logic [8:0]   io_nestedwb_set,
  input  logic [30:0]  io_nestedwb_tag,
  input  logic         io_nestedwb_c_set_dirty,
  input  logic         io_nestedwb_c_set_tip,
  input  logic         io_nestedwb_b_inv_dirty,
  input  logic         io_nestedwb_b_toB,
  input  logic         io_nestedwb_b_toN,
  input  logic         io_nestedwb_b_toClean,
  output logic         io_nestedwbData,

  // ---- aMergeTask (晚到的 Acquire/Prefetch 合并进本 MSHR 的 grant) ----
  input  logic         io_aMergeTask_valid,
  input  logic [5:0]   io_aMergeTask_bits_off,
  input  logic [1:0]   io_aMergeTask_bits_alias,
  input  logic [43:0]  io_aMergeTask_bits_vaddr,
  input  logic         io_aMergeTask_bits_isKeyword,
  input  logic [3:0]   io_aMergeTask_bits_opcode,
  input  logic [2:0]   io_aMergeTask_bits_param,
  input  logic [6:0]   io_aMergeTask_bits_sourceId,

  // ---- replResp (replacer 选 way 的回包) ----
  input  logic         io_replResp_valid,
  input  logic [30:0]  io_replResp_bits_tag,
  input  logic [2:0]   io_replResp_bits_way,
  input  logic         io_replResp_bits_meta_dirty,
  input  logic [1:0]   io_replResp_bits_meta_state,
  input  logic         io_replResp_bits_meta_clients,
  input  logic [1:0]   io_replResp_bits_meta_alias,
  input  logic         io_replResp_bits_meta_prefetch,
  input  logic [2:0]   io_replResp_bits_meta_prefetchSrc,
  input  logic         io_replResp_bits_meta_accessed,
  input  logic         io_replResp_bits_meta_tagErr,
  input  logic         io_replResp_bits_meta_dataErr,
  input  logic         io_replResp_bits_retry,

  // ---- pCrd (CHI 协议重试的 credit 查询/授予) ----
  output logic         io_pCrd_query_valid,
  output logic [3:0]   io_pCrd_query_bits_pCrdType,
  output logic [10:0]  io_pCrd_query_bits_srcID,
  input  logic         io_pCrd_grant,

  // ---- 性能计数 (acquire/release 时延) ----
  output logic         acquire_period_valid,
  output logic [63:0]  acquire_period_bits,
  output logic         release_period_valid,
  output logic [63:0]  release_period_bits
);

`include "mshr_core.svh"

endmodule
