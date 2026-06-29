// 自动生成 scripts/gen_l2mainpipe.py / gen_l2mainpipe_core.py —— 勿手改
// =============================================================================
//  MainPipe —— coupledL2 (tl2chi) L2 slice s2/s3/s4/s5 主流水 可读重写核
//          (xs_MainPipe_core, golden=MainPipe_1)
// -----------------------------------------------------------------------------
//  对照 Scala coupledL2/src/main/scala/coupledL2/tl2chi/MainPipe.scala。
//  s2: 组合收 RequestArb 的 task; s3: 主计算(读 Directory→判命中/一致性→派发);
//  s4: 锁存 sinkB 响应; s5: 收 DS 数据/发 releaseBuf/出 error。
//  4 个优先 Arbiter(in0=s5>s4>s3) 内联; CustomL1Hint 黑盒(核出 hint_s3_*)。
//  ===== X 铁律 =====
//    主流水寄存器异步复位置 0(resetIdx 起 511); data_s4/data_s5/io_perf_*_REG
//    为无复位 RegNext(+vcs+initreg+0 起 0)。寄存器全用 golden 扁平命名(FM/探针配对)。
// =============================================================================
module xs_MainPipe_core
  import l2_task_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  input  logic         io_taskFromArb_s2_valid,
  input  logic [2:0]   io_taskFromArb_s2_bits_channel,
  input  logic [2:0]   io_taskFromArb_s2_bits_txChannel,
  input  logic [8:0]   io_taskFromArb_s2_bits_set,
  input  logic [30:0]  io_taskFromArb_s2_bits_tag,
  input  logic [5:0]   io_taskFromArb_s2_bits_off,
  input  logic [1:0]   io_taskFromArb_s2_bits_alias,
  input  logic [43:0]  io_taskFromArb_s2_bits_vaddr,
  input  logic         io_taskFromArb_s2_bits_isKeyword,
  input  logic [3:0]   io_taskFromArb_s2_bits_opcode,
  input  logic [2:0]   io_taskFromArb_s2_bits_param,
  input  logic [2:0]   io_taskFromArb_s2_bits_size,
  input  logic [6:0]   io_taskFromArb_s2_bits_sourceId,
  input  logic [1:0]   io_taskFromArb_s2_bits_bufIdx,
  input  logic         io_taskFromArb_s2_bits_needProbeAckData,
  input  logic         io_taskFromArb_s2_bits_denied,
  input  logic         io_taskFromArb_s2_bits_corrupt,
  input  logic         io_taskFromArb_s2_bits_mshrTask,
  input  logic [7:0]   io_taskFromArb_s2_bits_mshrId,
  input  logic         io_taskFromArb_s2_bits_aliasTask,
  input  logic         io_taskFromArb_s2_bits_useProbeData,
  input  logic         io_taskFromArb_s2_bits_mshrRetry,
  input  logic         io_taskFromArb_s2_bits_readProbeDataDown,
  input  logic         io_taskFromArb_s2_bits_fromL2pft,
  input  logic         io_taskFromArb_s2_bits_needHint,
  input  logic         io_taskFromArb_s2_bits_dirty,
  input  logic [2:0]   io_taskFromArb_s2_bits_way,
  input  logic         io_taskFromArb_s2_bits_meta_dirty,
  input  logic [1:0]   io_taskFromArb_s2_bits_meta_state,
  input  logic         io_taskFromArb_s2_bits_meta_clients,
  input  logic [1:0]   io_taskFromArb_s2_bits_meta_alias,
  input  logic         io_taskFromArb_s2_bits_meta_prefetch,
  input  logic [2:0]   io_taskFromArb_s2_bits_meta_prefetchSrc,
  input  logic         io_taskFromArb_s2_bits_meta_accessed,
  input  logic         io_taskFromArb_s2_bits_meta_tagErr,
  input  logic         io_taskFromArb_s2_bits_meta_dataErr,
  input  logic         io_taskFromArb_s2_bits_metaWen,
  input  logic         io_taskFromArb_s2_bits_tagWen,
  input  logic         io_taskFromArb_s2_bits_dsWen,
  input  logic [7:0]   io_taskFromArb_s2_bits_wayMask,
  input  logic         io_taskFromArb_s2_bits_replTask,
  input  logic         io_taskFromArb_s2_bits_cmoTask,
  input  logic         io_taskFromArb_s2_bits_cmoAll,
  input  logic [4:0]   io_taskFromArb_s2_bits_reqSource,
  input  logic         io_taskFromArb_s2_bits_mergeA,
  input  logic [5:0]   io_taskFromArb_s2_bits_aMergeTask_off,
  input  logic [1:0]   io_taskFromArb_s2_bits_aMergeTask_alias,
  input  logic [43:0]  io_taskFromArb_s2_bits_aMergeTask_vaddr,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_isKeyword,
  input  logic [2:0]   io_taskFromArb_s2_bits_aMergeTask_opcode,
  input  logic [2:0]   io_taskFromArb_s2_bits_aMergeTask_param,
  input  logic [6:0]   io_taskFromArb_s2_bits_aMergeTask_sourceId,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_meta_dirty,
  input  logic [1:0]   io_taskFromArb_s2_bits_aMergeTask_meta_state,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_meta_clients,
  input  logic [1:0]   io_taskFromArb_s2_bits_aMergeTask_meta_alias,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_meta_prefetch,
  input  logic [2:0]   io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_meta_accessed,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_meta_tagErr,
  input  logic         io_taskFromArb_s2_bits_aMergeTask_meta_dataErr,
  input  logic         io_taskFromArb_s2_bits_snpHitRelease,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseToInval,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseToClean,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseWithData,
  input  logic [7:0]   io_taskFromArb_s2_bits_snpHitReleaseIdx,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty,
  input  logic [1:0]   io_taskFromArb_s2_bits_snpHitReleaseMeta_state,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseMeta_clients,
  input  logic [1:0]   io_taskFromArb_s2_bits_snpHitReleaseMeta_alias,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch,
  input  logic [2:0]   io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr,
  input  logic         io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr,
  input  logic [10:0]  io_taskFromArb_s2_bits_tgtID,
  input  logic [10:0]  io_taskFromArb_s2_bits_srcID,
  input  logic [11:0]  io_taskFromArb_s2_bits_txnID,
  input  logic [10:0]  io_taskFromArb_s2_bits_homeNID,
  input  logic [11:0]  io_taskFromArb_s2_bits_dbID,
  input  logic [10:0]  io_taskFromArb_s2_bits_fwdNID,
  input  logic [11:0]  io_taskFromArb_s2_bits_fwdTxnID,
  input  logic [6:0]   io_taskFromArb_s2_bits_chiOpcode,
  input  logic [2:0]   io_taskFromArb_s2_bits_resp,
  input  logic [2:0]   io_taskFromArb_s2_bits_fwdState,
  input  logic [3:0]   io_taskFromArb_s2_bits_pCrdType,
  input  logic         io_taskFromArb_s2_bits_retToSrc,
  input  logic         io_taskFromArb_s2_bits_likelyshared,
  input  logic         io_taskFromArb_s2_bits_expCompAck,
  input  logic         io_taskFromArb_s2_bits_allowRetry,
  input  logic         io_taskFromArb_s2_bits_memAttr_allocate,
  input  logic         io_taskFromArb_s2_bits_memAttr_cacheable,
  input  logic         io_taskFromArb_s2_bits_memAttr_device,
  input  logic         io_taskFromArb_s2_bits_memAttr_ewa,
  input  logic         io_taskFromArb_s2_bits_traceTag,
  input  logic         io_taskFromArb_s2_bits_dataCheckErr,
  input  logic [30:0]  io_fromReqArb_status_s1_tags_1,
  input  logic [8:0]   io_fromReqArb_status_s1_sets_0,
  input  logic [8:0]   io_fromReqArb_status_s1_sets_1,
  input  logic [8:0]   io_fromReqArb_status_s1_sets_2,
  input  logic [8:0]   io_fromReqArb_status_s1_sets_3,
  output logic         io_toReqArb_blockG_s1,
  output logic         io_toReqArb_blockB_s1,
  output logic         io_toReqArb_blockC_s1,
  output logic         io_toReqBuf_0,
  output logic         io_toReqBuf_1,
  output logic         io_status_vec_toD_0_valid,
  output logic [2:0]   io_status_vec_toD_0_bits_channel,
  output logic         io_status_vec_toD_1_valid,
  output logic [2:0]   io_status_vec_toD_1_bits_channel,
  output logic         io_status_vec_toD_2_valid,
  output logic [2:0]   io_status_vec_toD_2_bits_channel,
  output logic         io_status_vec_toTX_0_valid,
  output logic [2:0]   io_status_vec_toTX_0_bits_channel,
  output logic [2:0]   io_status_vec_toTX_0_bits_txChannel,
  output logic         io_status_vec_toTX_0_bits_mshrTask,
  output logic         io_status_vec_toTX_1_valid,
  output logic [2:0]   io_status_vec_toTX_1_bits_channel,
  output logic [2:0]   io_status_vec_toTX_1_bits_txChannel,
  output logic         io_status_vec_toTX_1_bits_mshrTask,
  output logic         io_status_vec_toTX_2_valid,
  output logic [2:0]   io_status_vec_toTX_2_bits_channel,
  output logic [2:0]   io_status_vec_toTX_2_bits_txChannel,
  output logic         io_status_vec_toTX_2_bits_mshrTask,
  input  logic         io_dirResp_s3_hit,
  input  logic [30:0]  io_dirResp_s3_tag,
  input  logic [8:0]   io_dirResp_s3_set,
  input  logic [2:0]   io_dirResp_s3_way,
  input  logic         io_dirResp_s3_meta_dirty,
  input  logic [1:0]   io_dirResp_s3_meta_state,
  input  logic         io_dirResp_s3_meta_clients,
  input  logic [1:0]   io_dirResp_s3_meta_alias,
  input  logic         io_dirResp_s3_meta_prefetch,
  input  logic [2:0]   io_dirResp_s3_meta_prefetchSrc,
  input  logic         io_dirResp_s3_meta_accessed,
  input  logic         io_dirResp_s3_meta_tagErr,
  input  logic         io_dirResp_s3_meta_dataErr,
  input  logic         io_dirResp_s3_error,
  input  logic         io_replResp_valid,
  input  logic [2:0]   io_replResp_bits_way,
  input  logic [1:0]   io_replResp_bits_meta_state,
  input  logic         io_replResp_bits_retry,
  output logic         io_toMSHRCtl_mshr_alloc_s3_valid,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit,
  output logic [30:0]  io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag,
  output logic [8:0]   io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set,
  output logic [2:0]   io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty,
  output logic [1:0]   io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients,
  output logic [1:0]   io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch,
  output logic [2:0]   io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct,
  output logic [2:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_channel,
  output logic [8:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_set,
  output logic [30:0]  io_toMSHRCtl_mshr_alloc_s3_bits_task_tag,
  output logic [5:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_off,
  output logic [1:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_alias,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword,
  output logic [3:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode,
  output logic [2:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_param,
  output logic [6:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft,
  output logic [4:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData,
  output logic [7:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0]  io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID,
  output logic [11:0]  io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID,
  output logic [10:0]  io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID,
  output logic [11:0]  io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID,
  output logic [6:0]   io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc,
  output logic         io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag,
  input  logic [7:0]   io_fromMSHRCtl_mshr_alloc_ptr,
  input  logic [255:0] io_bufResp_data_0,
  input  logic [255:0] io_bufResp_data_1,
  input  logic [511:0] io_refillBufResp_s3_bits_data,
  input  logic         io_releaseBufResp_s3_valid,
  input  logic [511:0] io_releaseBufResp_s3_bits_data,
  output logic         io_toDS_en_s3,
  output logic         io_toDS_req_s3_valid,
  output logic [2:0]   io_toDS_req_s3_bits_way,
  output logic [8:0]   io_toDS_req_s3_bits_set,
  output logic         io_toDS_req_s3_bits_wen,
  input  logic [511:0] io_toDS_rdata_s5_data,
  output logic [511:0] io_toDS_wdata_s3_data,
  input  logic         io_toDS_error_s5,
  output logic         io_toSourceD_valid,
  output logic [2:0]   io_toSourceD_bits_task_channel,
  output logic [2:0]   io_toSourceD_bits_task_txChannel,
  output logic [8:0]   io_toSourceD_bits_task_set,
  output logic [30:0]  io_toSourceD_bits_task_tag,
  output logic [5:0]   io_toSourceD_bits_task_off,
  output logic [1:0]   io_toSourceD_bits_task_alias,
  output logic [43:0]  io_toSourceD_bits_task_vaddr,
  output logic         io_toSourceD_bits_task_isKeyword,
  output logic [3:0]   io_toSourceD_bits_task_opcode,
  output logic [2:0]   io_toSourceD_bits_task_param,
  output logic [2:0]   io_toSourceD_bits_task_size,
  output logic [6:0]   io_toSourceD_bits_task_sourceId,
  output logic [1:0]   io_toSourceD_bits_task_bufIdx,
  output logic         io_toSourceD_bits_task_needProbeAckData,
  output logic         io_toSourceD_bits_task_denied,
  output logic         io_toSourceD_bits_task_corrupt,
  output logic         io_toSourceD_bits_task_mshrTask,
  output logic [7:0]   io_toSourceD_bits_task_mshrId,
  output logic         io_toSourceD_bits_task_aliasTask,
  output logic         io_toSourceD_bits_task_useProbeData,
  output logic         io_toSourceD_bits_task_mshrRetry,
  output logic         io_toSourceD_bits_task_readProbeDataDown,
  output logic         io_toSourceD_bits_task_fromL2pft,
  output logic         io_toSourceD_bits_task_needHint,
  output logic         io_toSourceD_bits_task_dirty,
  output logic [2:0]   io_toSourceD_bits_task_way,
  output logic         io_toSourceD_bits_task_meta_dirty,
  output logic [1:0]   io_toSourceD_bits_task_meta_state,
  output logic         io_toSourceD_bits_task_meta_clients,
  output logic [1:0]   io_toSourceD_bits_task_meta_alias,
  output logic         io_toSourceD_bits_task_meta_prefetch,
  output logic [2:0]   io_toSourceD_bits_task_meta_prefetchSrc,
  output logic         io_toSourceD_bits_task_meta_accessed,
  output logic         io_toSourceD_bits_task_meta_tagErr,
  output logic         io_toSourceD_bits_task_meta_dataErr,
  output logic         io_toSourceD_bits_task_metaWen,
  output logic         io_toSourceD_bits_task_tagWen,
  output logic         io_toSourceD_bits_task_dsWen,
  output logic [7:0]   io_toSourceD_bits_task_wayMask,
  output logic         io_toSourceD_bits_task_replTask,
  output logic         io_toSourceD_bits_task_cmoTask,
  output logic         io_toSourceD_bits_task_cmoAll,
  output logic [4:0]   io_toSourceD_bits_task_reqSource,
  output logic         io_toSourceD_bits_task_mergeA,
  output logic [5:0]   io_toSourceD_bits_task_aMergeTask_off,
  output logic [1:0]   io_toSourceD_bits_task_aMergeTask_alias,
  output logic [43:0]  io_toSourceD_bits_task_aMergeTask_vaddr,
  output logic         io_toSourceD_bits_task_aMergeTask_isKeyword,
  output logic [2:0]   io_toSourceD_bits_task_aMergeTask_opcode,
  output logic [2:0]   io_toSourceD_bits_task_aMergeTask_param,
  output logic [6:0]   io_toSourceD_bits_task_aMergeTask_sourceId,
  output logic         io_toSourceD_bits_task_aMergeTask_meta_dirty,
  output logic [1:0]   io_toSourceD_bits_task_aMergeTask_meta_state,
  output logic         io_toSourceD_bits_task_aMergeTask_meta_clients,
  output logic [1:0]   io_toSourceD_bits_task_aMergeTask_meta_alias,
  output logic         io_toSourceD_bits_task_aMergeTask_meta_prefetch,
  output logic [2:0]   io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc,
  output logic         io_toSourceD_bits_task_aMergeTask_meta_accessed,
  output logic         io_toSourceD_bits_task_aMergeTask_meta_tagErr,
  output logic         io_toSourceD_bits_task_aMergeTask_meta_dataErr,
  output logic         io_toSourceD_bits_task_snpHitRelease,
  output logic         io_toSourceD_bits_task_snpHitReleaseToInval,
  output logic         io_toSourceD_bits_task_snpHitReleaseToClean,
  output logic         io_toSourceD_bits_task_snpHitReleaseWithData,
  output logic [7:0]   io_toSourceD_bits_task_snpHitReleaseIdx,
  output logic         io_toSourceD_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0]   io_toSourceD_bits_task_snpHitReleaseMeta_state,
  output logic         io_toSourceD_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0]   io_toSourceD_bits_task_snpHitReleaseMeta_alias,
  output logic         io_toSourceD_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0]   io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic         io_toSourceD_bits_task_snpHitReleaseMeta_accessed,
  output logic         io_toSourceD_bits_task_snpHitReleaseMeta_tagErr,
  output logic         io_toSourceD_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0]  io_toSourceD_bits_task_tgtID,
  output logic [10:0]  io_toSourceD_bits_task_srcID,
  output logic [11:0]  io_toSourceD_bits_task_txnID,
  output logic [10:0]  io_toSourceD_bits_task_homeNID,
  output logic [11:0]  io_toSourceD_bits_task_dbID,
  output logic [10:0]  io_toSourceD_bits_task_fwdNID,
  output logic [11:0]  io_toSourceD_bits_task_fwdTxnID,
  output logic [6:0]   io_toSourceD_bits_task_chiOpcode,
  output logic [2:0]   io_toSourceD_bits_task_resp,
  output logic [2:0]   io_toSourceD_bits_task_fwdState,
  output logic [3:0]   io_toSourceD_bits_task_pCrdType,
  output logic         io_toSourceD_bits_task_retToSrc,
  output logic         io_toSourceD_bits_task_likelyshared,
  output logic         io_toSourceD_bits_task_expCompAck,
  output logic         io_toSourceD_bits_task_allowRetry,
  output logic         io_toSourceD_bits_task_memAttr_allocate,
  output logic         io_toSourceD_bits_task_memAttr_cacheable,
  output logic         io_toSourceD_bits_task_memAttr_device,
  output logic         io_toSourceD_bits_task_memAttr_ewa,
  output logic         io_toSourceD_bits_task_traceTag,
  output logic         io_toSourceD_bits_task_dataCheckErr,
  output logic [511:0] io_toSourceD_bits_data_data,
  output logic         io_toTXREQ_valid,
  output logic [10:0]  io_toTXREQ_bits_tgtID,
  output logic [10:0]  io_toTXREQ_bits_srcID,
  output logic [11:0]  io_toTXREQ_bits_txnID,
  output logic [6:0]   io_toTXREQ_bits_opcode,
  output logic [47:0]  io_toTXREQ_bits_addr,
  output logic         io_toTXREQ_bits_likelyshared,
  output logic         io_toTXREQ_bits_allowRetry,
  output logic [3:0]   io_toTXREQ_bits_pCrdType,
  output logic         io_toTXREQ_bits_memAttr_allocate,
  output logic         io_toTXREQ_bits_memAttr_cacheable,
  output logic         io_toTXREQ_bits_memAttr_device,
  output logic         io_toTXREQ_bits_memAttr_ewa,
  output logic         io_toTXREQ_bits_expCompAck,
  output logic         io_toTXRSP_valid,
  output logic [2:0]   io_toTXRSP_bits_txChannel,
  output logic         io_toTXRSP_bits_denied,
  output logic [10:0]  io_toTXRSP_bits_tgtID,
  output logic [10:0]  io_toTXRSP_bits_srcID,
  output logic [11:0]  io_toTXRSP_bits_txnID,
  output logic [11:0]  io_toTXRSP_bits_dbID,
  output logic [6:0]   io_toTXRSP_bits_chiOpcode,
  output logic [2:0]   io_toTXRSP_bits_resp,
  output logic [2:0]   io_toTXRSP_bits_fwdState,
  output logic [3:0]   io_toTXRSP_bits_pCrdType,
  output logic         io_toTXRSP_bits_traceTag,
  input  logic         io_toTXDAT_ready,
  output logic         io_toTXDAT_valid,
  output logic [2:0]   io_toTXDAT_bits_task_channel,
  output logic [2:0]   io_toTXDAT_bits_task_txChannel,
  output logic [8:0]   io_toTXDAT_bits_task_set,
  output logic [30:0]  io_toTXDAT_bits_task_tag,
  output logic [5:0]   io_toTXDAT_bits_task_off,
  output logic [1:0]   io_toTXDAT_bits_task_alias,
  output logic [43:0]  io_toTXDAT_bits_task_vaddr,
  output logic         io_toTXDAT_bits_task_isKeyword,
  output logic [3:0]   io_toTXDAT_bits_task_opcode,
  output logic [2:0]   io_toTXDAT_bits_task_param,
  output logic [2:0]   io_toTXDAT_bits_task_size,
  output logic [6:0]   io_toTXDAT_bits_task_sourceId,
  output logic [1:0]   io_toTXDAT_bits_task_bufIdx,
  output logic         io_toTXDAT_bits_task_needProbeAckData,
  output logic         io_toTXDAT_bits_task_denied,
  output logic         io_toTXDAT_bits_task_corrupt,
  output logic         io_toTXDAT_bits_task_mshrTask,
  output logic [7:0]   io_toTXDAT_bits_task_mshrId,
  output logic         io_toTXDAT_bits_task_aliasTask,
  output logic         io_toTXDAT_bits_task_useProbeData,
  output logic         io_toTXDAT_bits_task_mshrRetry,
  output logic         io_toTXDAT_bits_task_readProbeDataDown,
  output logic         io_toTXDAT_bits_task_fromL2pft,
  output logic         io_toTXDAT_bits_task_needHint,
  output logic         io_toTXDAT_bits_task_dirty,
  output logic [2:0]   io_toTXDAT_bits_task_way,
  output logic         io_toTXDAT_bits_task_meta_dirty,
  output logic [1:0]   io_toTXDAT_bits_task_meta_state,
  output logic         io_toTXDAT_bits_task_meta_clients,
  output logic [1:0]   io_toTXDAT_bits_task_meta_alias,
  output logic         io_toTXDAT_bits_task_meta_prefetch,
  output logic [2:0]   io_toTXDAT_bits_task_meta_prefetchSrc,
  output logic         io_toTXDAT_bits_task_meta_accessed,
  output logic         io_toTXDAT_bits_task_meta_tagErr,
  output logic         io_toTXDAT_bits_task_meta_dataErr,
  output logic         io_toTXDAT_bits_task_metaWen,
  output logic         io_toTXDAT_bits_task_tagWen,
  output logic         io_toTXDAT_bits_task_dsWen,
  output logic [7:0]   io_toTXDAT_bits_task_wayMask,
  output logic         io_toTXDAT_bits_task_replTask,
  output logic         io_toTXDAT_bits_task_cmoTask,
  output logic         io_toTXDAT_bits_task_cmoAll,
  output logic [4:0]   io_toTXDAT_bits_task_reqSource,
  output logic         io_toTXDAT_bits_task_mergeA,
  output logic [5:0]   io_toTXDAT_bits_task_aMergeTask_off,
  output logic [1:0]   io_toTXDAT_bits_task_aMergeTask_alias,
  output logic [43:0]  io_toTXDAT_bits_task_aMergeTask_vaddr,
  output logic         io_toTXDAT_bits_task_aMergeTask_isKeyword,
  output logic [2:0]   io_toTXDAT_bits_task_aMergeTask_opcode,
  output logic [2:0]   io_toTXDAT_bits_task_aMergeTask_param,
  output logic [6:0]   io_toTXDAT_bits_task_aMergeTask_sourceId,
  output logic         io_toTXDAT_bits_task_aMergeTask_meta_dirty,
  output logic [1:0]   io_toTXDAT_bits_task_aMergeTask_meta_state,
  output logic         io_toTXDAT_bits_task_aMergeTask_meta_clients,
  output logic [1:0]   io_toTXDAT_bits_task_aMergeTask_meta_alias,
  output logic         io_toTXDAT_bits_task_aMergeTask_meta_prefetch,
  output logic [2:0]   io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc,
  output logic         io_toTXDAT_bits_task_aMergeTask_meta_accessed,
  output logic         io_toTXDAT_bits_task_aMergeTask_meta_tagErr,
  output logic         io_toTXDAT_bits_task_aMergeTask_meta_dataErr,
  output logic         io_toTXDAT_bits_task_snpHitRelease,
  output logic         io_toTXDAT_bits_task_snpHitReleaseToInval,
  output logic         io_toTXDAT_bits_task_snpHitReleaseToClean,
  output logic         io_toTXDAT_bits_task_snpHitReleaseWithData,
  output logic [7:0]   io_toTXDAT_bits_task_snpHitReleaseIdx,
  output logic         io_toTXDAT_bits_task_snpHitReleaseMeta_dirty,
  output logic [1:0]   io_toTXDAT_bits_task_snpHitReleaseMeta_state,
  output logic         io_toTXDAT_bits_task_snpHitReleaseMeta_clients,
  output logic [1:0]   io_toTXDAT_bits_task_snpHitReleaseMeta_alias,
  output logic         io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch,
  output logic [2:0]   io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc,
  output logic         io_toTXDAT_bits_task_snpHitReleaseMeta_accessed,
  output logic         io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr,
  output logic         io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr,
  output logic [10:0]  io_toTXDAT_bits_task_tgtID,
  output logic [10:0]  io_toTXDAT_bits_task_srcID,
  output logic [11:0]  io_toTXDAT_bits_task_txnID,
  output logic [10:0]  io_toTXDAT_bits_task_homeNID,
  output logic [11:0]  io_toTXDAT_bits_task_dbID,
  output logic [10:0]  io_toTXDAT_bits_task_fwdNID,
  output logic [11:0]  io_toTXDAT_bits_task_fwdTxnID,
  output logic [6:0]   io_toTXDAT_bits_task_chiOpcode,
  output logic [2:0]   io_toTXDAT_bits_task_resp,
  output logic [2:0]   io_toTXDAT_bits_task_fwdState,
  output logic [3:0]   io_toTXDAT_bits_task_pCrdType,
  output logic         io_toTXDAT_bits_task_retToSrc,
  output logic         io_toTXDAT_bits_task_likelyshared,
  output logic         io_toTXDAT_bits_task_expCompAck,
  output logic         io_toTXDAT_bits_task_allowRetry,
  output logic         io_toTXDAT_bits_task_memAttr_allocate,
  output logic         io_toTXDAT_bits_task_memAttr_cacheable,
  output logic         io_toTXDAT_bits_task_memAttr_device,
  output logic         io_toTXDAT_bits_task_memAttr_ewa,
  output logic         io_toTXDAT_bits_task_traceTag,
  output logic         io_toTXDAT_bits_task_dataCheckErr,
  output logic [511:0] io_toTXDAT_bits_data_data,
  output logic         io_metaWReq_valid,
  output logic [8:0]   io_metaWReq_bits_set,
  output logic [7:0]   io_metaWReq_bits_wayOH,
  output logic         io_metaWReq_bits_wmeta_dirty,
  output logic [1:0]   io_metaWReq_bits_wmeta_state,
  output logic         io_metaWReq_bits_wmeta_clients,
  output logic [1:0]   io_metaWReq_bits_wmeta_alias,
  output logic         io_metaWReq_bits_wmeta_prefetch,
  output logic [2:0]   io_metaWReq_bits_wmeta_prefetchSrc,
  output logic         io_metaWReq_bits_wmeta_accessed,
  output logic         io_metaWReq_bits_wmeta_tagErr,
  output logic         io_metaWReq_bits_wmeta_dataErr,
  output logic         io_tagWReq_valid,
  output logic [8:0]   io_tagWReq_bits_set,
  output logic [2:0]   io_tagWReq_bits_way,
  output logic [30:0]  io_tagWReq_bits_wtag,
  output logic         io_releaseBufWrite_valid,
  output logic [7:0]   io_releaseBufWrite_bits_id,
  output logic [511:0] io_releaseBufWrite_bits_data_data,
  output logic [8:0]   io_nestedwb_set,
  output logic [30:0]  io_nestedwb_tag,
  output logic         io_nestedwb_c_set_dirty,
  output logic         io_nestedwb_c_set_tip,
  output logic         io_nestedwb_b_inv_dirty,
  output logic         io_nestedwb_b_toB,
  output logic         io_nestedwb_b_toN,
  output logic         io_nestedwb_b_toClean,
  output logic [511:0] io_nestedwbData_data,
  input  logic         io_prefetchTrain_ready,
  output logic         io_prefetchTrain_valid,
  output logic [32:0]  io_prefetchTrain_bits_tag,
  output logic [8:0]   io_prefetchTrain_bits_set,
  output logic         io_prefetchTrain_bits_needT,
  output logic [6:0]   io_prefetchTrain_bits_source,
  output logic [43:0]  io_prefetchTrain_bits_vaddr,
  output logic         io_prefetchTrain_bits_hit,
  output logic         io_prefetchTrain_bits_prefetched,
  output logic [2:0]   io_prefetchTrain_bits_pfsource,
  output logic [4:0]   io_prefetchTrain_bits_reqsource,
  output logic         io_error_valid,
  output logic         io_error_bits_valid,
  output logic [45:0]  io_error_bits_address,
  output logic [5:0]   io_perf_0_value,
  output logic [5:0]   io_perf_1_value,
  output logic [5:0]   io_perf_2_value,
  output logic [5:0]   io_perf_3_value,
  output logic [5:0]   io_perf_4_value,
  output logic [5:0]   io_perf_5_value,
  output logic [5:0]   io_perf_6_value,
  output logic [5:0]   io_perf_7_value,
  // ---- 喂 CustomL1Hint 的 s3 信号 ----
  output logic        hint_s3_task_valid,
  output logic [2:0]  hint_s3_task_bits_channel,
  output logic        hint_s3_task_bits_isKeyword,
  output logic [3:0]  hint_s3_task_bits_opcode,
  output logic [6:0]  hint_s3_task_bits_sourceId,
  output logic        hint_s3_task_bits_mshrTask,
  output logic        hint_s3_need_mshr
);

  // ===== 一致性状态/opcode 常量(单态化) =====
  localparam logic [1:0] INVALID = 2'd0, BRANCH = 2'd1, TRUNK = 2'd2, TIP = 2'd3;
  // CHI Resp 编码: I=0 SC=1 UC=UD=2 SD=3; PassDirty=4
  localparam logic [2:0] CHI_I = 3'd0, CHI_SC = 3'd1, CHI_UC = 3'd2, CHI_SD = 3'd3;
  localparam logic [2:0] CHI_PD = 3'd4;

  // ===== 权限/snoop 判定函数(只读入参) =====
  function automatic logic f_needT(input logic [3:0] op, input logic [2:0] pm);
    f_needT = (~op[2]) | (op == 4'd5 & pm == 3'd1) | ((op == 4'd6 | op == 4'd7) & pm != 3'd0);
  endfunction
  function automatic logic f_isToN(input logic [2:0] pm);   f_isToN = (pm==3'd1)|(pm==3'd2)|(pm==3'd5); endfunction
  function automatic logic f_isParamFromT(input logic [2:0] pm); f_isParamFromT = (pm==3'd0)|(pm==3'd1)|(pm==3'd3); endfunction
  function automatic logic f_isT(input logic [1:0] st); f_isT = st[1]; endfunction
  // CHI snoop opcode (7-bit) 判定
  function automatic logic f_isSnpXFwd(input logic [6:0] o);
    f_isSnpXFwd = (o==7'h11)|(o==7'h12)|(o==7'h13)|(o==7'h14)|(o==7'h17); endfunction
  function automatic logic f_isSnpStashX(input logic [6:0] o); f_isSnpStashX = (o==7'h0B)|(o==7'h0C); endfunction
  function automatic logic f_isSnpQuery(input logic [6:0] o);  f_isSnpQuery = (o==7'h10); endfunction
  function automatic logic f_isSnpOnceX(input logic [6:0] o);  f_isSnpOnceX = (o==7'h03)|(o==7'h13); endfunction
  function automatic logic f_isSnpUniqueX(input logic [6:0] o);
    f_isSnpUniqueX = (o==7'h07)|(o==7'h17)|(o==7'h05); endfunction
  function automatic logic f_isSnpMakeInvalidX(input logic [6:0] o); f_isSnpMakeInvalidX = (o==7'h0A)|(o==7'h06); endfunction
  function automatic logic f_isSnpToB(input logic [6:0] o);
    f_isSnpToB = (o==7'h01)|(o==7'h02)|(o==7'h04)|(o==7'h11)|(o==7'h12)|(o==7'h14); endfunction
  function automatic logic f_isSnpToBFwd(input logic [6:0] o); f_isSnpToBFwd = (o==7'h11)|(o==7'h12)|(o==7'h14); endfunction
  function automatic logic f_isSnpToBNonFwd(input logic [6:0] o); f_isSnpToBNonFwd = (o==7'h01)|(o==7'h02)|(o==7'h04); endfunction
  function automatic logic f_isSnpToN(input logic [6:0] o);
    f_isSnpToN = f_isSnpUniqueX(o) | (o==7'h09) | f_isSnpMakeInvalidX(o); endfunction

  // ===== 复位: resetIdx 倒数 512 拍, 期间逐 set 清 Directory =====
  logic        resetFinish;
  logic [8:0]  resetIdx;

  // ===== 流水寄存器(扁平 golden 命名, 异步复位置 0 除 data_s4/s5) =====
  logic        task_s3_valid;
  logic [2:0]   task_s3_bits_channel;
  logic [2:0]   task_s3_bits_txChannel;
  logic [8:0]   task_s3_bits_set;
  logic [30:0]  task_s3_bits_tag;
  logic [5:0]   task_s3_bits_off;
  logic [1:0]   task_s3_bits_alias;
  logic [43:0]  task_s3_bits_vaddr;
  logic         task_s3_bits_isKeyword;
  logic [3:0]   task_s3_bits_opcode;
  logic [2:0]   task_s3_bits_param;
  logic [2:0]   task_s3_bits_size;
  logic [6:0]   task_s3_bits_sourceId;
  logic [1:0]   task_s3_bits_bufIdx;
  logic         task_s3_bits_needProbeAckData;
  logic         task_s3_bits_denied;
  logic         task_s3_bits_corrupt;
  logic         task_s3_bits_mshrTask;
  logic [7:0]   task_s3_bits_mshrId;
  logic         task_s3_bits_aliasTask;
  logic         task_s3_bits_useProbeData;
  logic         task_s3_bits_mshrRetry;
  logic         task_s3_bits_readProbeDataDown;
  logic         task_s3_bits_fromL2pft;
  logic         task_s3_bits_needHint;
  logic         task_s3_bits_dirty;
  logic [2:0]   task_s3_bits_way;
  logic         task_s3_bits_meta_dirty;
  logic [1:0]   task_s3_bits_meta_state;
  logic         task_s3_bits_meta_clients;
  logic [1:0]   task_s3_bits_meta_alias;
  logic         task_s3_bits_meta_prefetch;
  logic [2:0]   task_s3_bits_meta_prefetchSrc;
  logic         task_s3_bits_meta_accessed;
  logic         task_s3_bits_meta_tagErr;
  logic         task_s3_bits_meta_dataErr;
  logic         task_s3_bits_metaWen;
  logic         task_s3_bits_tagWen;
  logic         task_s3_bits_dsWen;
  logic [7:0]   task_s3_bits_wayMask;
  logic         task_s3_bits_replTask;
  logic         task_s3_bits_cmoTask;
  logic         task_s3_bits_cmoAll;
  logic [4:0]   task_s3_bits_reqSource;
  logic         task_s3_bits_mergeA;
  logic [5:0]   task_s3_bits_aMergeTask_off;
  logic [1:0]   task_s3_bits_aMergeTask_alias;
  logic [43:0]  task_s3_bits_aMergeTask_vaddr;
  logic         task_s3_bits_aMergeTask_isKeyword;
  logic [2:0]   task_s3_bits_aMergeTask_opcode;
  logic [2:0]   task_s3_bits_aMergeTask_param;
  logic [6:0]   task_s3_bits_aMergeTask_sourceId;
  logic         task_s3_bits_aMergeTask_meta_dirty;
  logic [1:0]   task_s3_bits_aMergeTask_meta_state;
  logic         task_s3_bits_aMergeTask_meta_clients;
  logic [1:0]   task_s3_bits_aMergeTask_meta_alias;
  logic         task_s3_bits_aMergeTask_meta_prefetch;
  logic [2:0]   task_s3_bits_aMergeTask_meta_prefetchSrc;
  logic         task_s3_bits_aMergeTask_meta_accessed;
  logic         task_s3_bits_aMergeTask_meta_tagErr;
  logic         task_s3_bits_aMergeTask_meta_dataErr;
  logic         task_s3_bits_snpHitRelease;
  logic         task_s3_bits_snpHitReleaseToInval;
  logic         task_s3_bits_snpHitReleaseToClean;
  logic         task_s3_bits_snpHitReleaseWithData;
  logic [7:0]   task_s3_bits_snpHitReleaseIdx;
  logic         task_s3_bits_snpHitReleaseMeta_dirty;
  logic [1:0]   task_s3_bits_snpHitReleaseMeta_state;
  logic         task_s3_bits_snpHitReleaseMeta_clients;
  logic [1:0]   task_s3_bits_snpHitReleaseMeta_alias;
  logic         task_s3_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]   task_s3_bits_snpHitReleaseMeta_prefetchSrc;
  logic         task_s3_bits_snpHitReleaseMeta_accessed;
  logic         task_s3_bits_snpHitReleaseMeta_tagErr;
  logic         task_s3_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]  task_s3_bits_tgtID;
  logic [10:0]  task_s3_bits_srcID;
  logic [11:0]  task_s3_bits_txnID;
  logic [10:0]  task_s3_bits_homeNID;
  logic [11:0]  task_s3_bits_dbID;
  logic [10:0]  task_s3_bits_fwdNID;
  logic [11:0]  task_s3_bits_fwdTxnID;
  logic [6:0]   task_s3_bits_chiOpcode;
  logic [2:0]   task_s3_bits_resp;
  logic [2:0]   task_s3_bits_fwdState;
  logic [3:0]   task_s3_bits_pCrdType;
  logic         task_s3_bits_retToSrc;
  logic         task_s3_bits_likelyshared;
  logic         task_s3_bits_expCompAck;
  logic         task_s3_bits_allowRetry;
  logic         task_s3_bits_memAttr_allocate;
  logic         task_s3_bits_memAttr_cacheable;
  logic         task_s3_bits_memAttr_device;
  logic         task_s3_bits_memAttr_ewa;
  logic         task_s3_bits_traceTag;
  logic         task_s3_bits_dataCheckErr;
  logic        task_s4_valid;
  logic [2:0]   task_s4_bits_channel;
  logic [2:0]   task_s4_bits_txChannel;
  logic [8:0]   task_s4_bits_set;
  logic [30:0]  task_s4_bits_tag;
  logic [5:0]   task_s4_bits_off;
  logic [1:0]   task_s4_bits_alias;
  logic [43:0]  task_s4_bits_vaddr;
  logic         task_s4_bits_isKeyword;
  logic [3:0]   task_s4_bits_opcode;
  logic [2:0]   task_s4_bits_param;
  logic [2:0]   task_s4_bits_size;
  logic [6:0]   task_s4_bits_sourceId;
  logic [1:0]   task_s4_bits_bufIdx;
  logic         task_s4_bits_needProbeAckData;
  logic         task_s4_bits_denied;
  logic         task_s4_bits_corrupt;
  logic         task_s4_bits_mshrTask;
  logic [7:0]   task_s4_bits_mshrId;
  logic         task_s4_bits_aliasTask;
  logic         task_s4_bits_useProbeData;
  logic         task_s4_bits_mshrRetry;
  logic         task_s4_bits_readProbeDataDown;
  logic         task_s4_bits_fromL2pft;
  logic         task_s4_bits_needHint;
  logic         task_s4_bits_dirty;
  logic [2:0]   task_s4_bits_way;
  logic         task_s4_bits_meta_dirty;
  logic [1:0]   task_s4_bits_meta_state;
  logic         task_s4_bits_meta_clients;
  logic [1:0]   task_s4_bits_meta_alias;
  logic         task_s4_bits_meta_prefetch;
  logic [2:0]   task_s4_bits_meta_prefetchSrc;
  logic         task_s4_bits_meta_accessed;
  logic         task_s4_bits_meta_tagErr;
  logic         task_s4_bits_meta_dataErr;
  logic         task_s4_bits_metaWen;
  logic         task_s4_bits_tagWen;
  logic         task_s4_bits_dsWen;
  logic [7:0]   task_s4_bits_wayMask;
  logic         task_s4_bits_replTask;
  logic         task_s4_bits_cmoTask;
  logic         task_s4_bits_cmoAll;
  logic [4:0]   task_s4_bits_reqSource;
  logic         task_s4_bits_mergeA;
  logic [5:0]   task_s4_bits_aMergeTask_off;
  logic [1:0]   task_s4_bits_aMergeTask_alias;
  logic [43:0]  task_s4_bits_aMergeTask_vaddr;
  logic         task_s4_bits_aMergeTask_isKeyword;
  logic [2:0]   task_s4_bits_aMergeTask_opcode;
  logic [2:0]   task_s4_bits_aMergeTask_param;
  logic [6:0]   task_s4_bits_aMergeTask_sourceId;
  logic         task_s4_bits_aMergeTask_meta_dirty;
  logic [1:0]   task_s4_bits_aMergeTask_meta_state;
  logic         task_s4_bits_aMergeTask_meta_clients;
  logic [1:0]   task_s4_bits_aMergeTask_meta_alias;
  logic         task_s4_bits_aMergeTask_meta_prefetch;
  logic [2:0]   task_s4_bits_aMergeTask_meta_prefetchSrc;
  logic         task_s4_bits_aMergeTask_meta_accessed;
  logic         task_s4_bits_aMergeTask_meta_tagErr;
  logic         task_s4_bits_aMergeTask_meta_dataErr;
  logic         task_s4_bits_snpHitRelease;
  logic         task_s4_bits_snpHitReleaseToInval;
  logic         task_s4_bits_snpHitReleaseToClean;
  logic         task_s4_bits_snpHitReleaseWithData;
  logic [7:0]   task_s4_bits_snpHitReleaseIdx;
  logic         task_s4_bits_snpHitReleaseMeta_dirty;
  logic [1:0]   task_s4_bits_snpHitReleaseMeta_state;
  logic         task_s4_bits_snpHitReleaseMeta_clients;
  logic [1:0]   task_s4_bits_snpHitReleaseMeta_alias;
  logic         task_s4_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]   task_s4_bits_snpHitReleaseMeta_prefetchSrc;
  logic         task_s4_bits_snpHitReleaseMeta_accessed;
  logic         task_s4_bits_snpHitReleaseMeta_tagErr;
  logic         task_s4_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]  task_s4_bits_tgtID;
  logic [10:0]  task_s4_bits_srcID;
  logic [11:0]  task_s4_bits_txnID;
  logic [10:0]  task_s4_bits_homeNID;
  logic [11:0]  task_s4_bits_dbID;
  logic [10:0]  task_s4_bits_fwdNID;
  logic [11:0]  task_s4_bits_fwdTxnID;
  logic [6:0]   task_s4_bits_chiOpcode;
  logic [2:0]   task_s4_bits_resp;
  logic [2:0]   task_s4_bits_fwdState;
  logic [3:0]   task_s4_bits_pCrdType;
  logic         task_s4_bits_retToSrc;
  logic         task_s4_bits_likelyshared;
  logic         task_s4_bits_expCompAck;
  logic         task_s4_bits_allowRetry;
  logic         task_s4_bits_memAttr_allocate;
  logic         task_s4_bits_memAttr_cacheable;
  logic         task_s4_bits_memAttr_device;
  logic         task_s4_bits_memAttr_ewa;
  logic         task_s4_bits_traceTag;
  logic         task_s4_bits_dataCheckErr;
  logic        task_s5_valid;
  logic [2:0]   task_s5_bits_channel;
  logic [2:0]   task_s5_bits_txChannel;
  logic [8:0]   task_s5_bits_set;
  logic [30:0]  task_s5_bits_tag;
  logic [5:0]   task_s5_bits_off;
  logic [1:0]   task_s5_bits_alias;
  logic [43:0]  task_s5_bits_vaddr;
  logic         task_s5_bits_isKeyword;
  logic [3:0]   task_s5_bits_opcode;
  logic [2:0]   task_s5_bits_param;
  logic [2:0]   task_s5_bits_size;
  logic [6:0]   task_s5_bits_sourceId;
  logic [1:0]   task_s5_bits_bufIdx;
  logic         task_s5_bits_needProbeAckData;
  logic         task_s5_bits_denied;
  logic         task_s5_bits_corrupt;
  logic         task_s5_bits_mshrTask;
  logic [7:0]   task_s5_bits_mshrId;
  logic         task_s5_bits_aliasTask;
  logic         task_s5_bits_useProbeData;
  logic         task_s5_bits_mshrRetry;
  logic         task_s5_bits_readProbeDataDown;
  logic         task_s5_bits_fromL2pft;
  logic         task_s5_bits_needHint;
  logic         task_s5_bits_dirty;
  logic [2:0]   task_s5_bits_way;
  logic         task_s5_bits_meta_dirty;
  logic [1:0]   task_s5_bits_meta_state;
  logic         task_s5_bits_meta_clients;
  logic [1:0]   task_s5_bits_meta_alias;
  logic         task_s5_bits_meta_prefetch;
  logic [2:0]   task_s5_bits_meta_prefetchSrc;
  logic         task_s5_bits_meta_accessed;
  logic         task_s5_bits_meta_tagErr;
  logic         task_s5_bits_meta_dataErr;
  logic         task_s5_bits_metaWen;
  logic         task_s5_bits_tagWen;
  logic         task_s5_bits_dsWen;
  logic [7:0]   task_s5_bits_wayMask;
  logic         task_s5_bits_replTask;
  logic         task_s5_bits_cmoTask;
  logic         task_s5_bits_cmoAll;
  logic [4:0]   task_s5_bits_reqSource;
  logic         task_s5_bits_mergeA;
  logic [5:0]   task_s5_bits_aMergeTask_off;
  logic [1:0]   task_s5_bits_aMergeTask_alias;
  logic [43:0]  task_s5_bits_aMergeTask_vaddr;
  logic         task_s5_bits_aMergeTask_isKeyword;
  logic [2:0]   task_s5_bits_aMergeTask_opcode;
  logic [2:0]   task_s5_bits_aMergeTask_param;
  logic [6:0]   task_s5_bits_aMergeTask_sourceId;
  logic         task_s5_bits_aMergeTask_meta_dirty;
  logic [1:0]   task_s5_bits_aMergeTask_meta_state;
  logic         task_s5_bits_aMergeTask_meta_clients;
  logic [1:0]   task_s5_bits_aMergeTask_meta_alias;
  logic         task_s5_bits_aMergeTask_meta_prefetch;
  logic [2:0]   task_s5_bits_aMergeTask_meta_prefetchSrc;
  logic         task_s5_bits_aMergeTask_meta_accessed;
  logic         task_s5_bits_aMergeTask_meta_tagErr;
  logic         task_s5_bits_aMergeTask_meta_dataErr;
  logic         task_s5_bits_snpHitRelease;
  logic         task_s5_bits_snpHitReleaseToInval;
  logic         task_s5_bits_snpHitReleaseToClean;
  logic         task_s5_bits_snpHitReleaseWithData;
  logic [7:0]   task_s5_bits_snpHitReleaseIdx;
  logic         task_s5_bits_snpHitReleaseMeta_dirty;
  logic [1:0]   task_s5_bits_snpHitReleaseMeta_state;
  logic         task_s5_bits_snpHitReleaseMeta_clients;
  logic [1:0]   task_s5_bits_snpHitReleaseMeta_alias;
  logic         task_s5_bits_snpHitReleaseMeta_prefetch;
  logic [2:0]   task_s5_bits_snpHitReleaseMeta_prefetchSrc;
  logic         task_s5_bits_snpHitReleaseMeta_accessed;
  logic         task_s5_bits_snpHitReleaseMeta_tagErr;
  logic         task_s5_bits_snpHitReleaseMeta_dataErr;
  logic [10:0]  task_s5_bits_tgtID;
  logic [10:0]  task_s5_bits_srcID;
  logic [11:0]  task_s5_bits_txnID;
  logic [10:0]  task_s5_bits_homeNID;
  logic [11:0]  task_s5_bits_dbID;
  logic [10:0]  task_s5_bits_fwdNID;
  logic [11:0]  task_s5_bits_fwdTxnID;
  logic [6:0]   task_s5_bits_chiOpcode;
  logic [2:0]   task_s5_bits_resp;
  logic [2:0]   task_s5_bits_fwdState;
  logic [3:0]   task_s5_bits_pCrdType;
  logic         task_s5_bits_retToSrc;
  logic         task_s5_bits_likelyshared;
  logic         task_s5_bits_expCompAck;
  logic         task_s5_bits_allowRetry;
  logic         task_s5_bits_memAttr_allocate;
  logic         task_s5_bits_memAttr_cacheable;
  logic         task_s5_bits_memAttr_device;
  logic         task_s5_bits_memAttr_ewa;
  logic         task_s5_bits_traceTag;
  logic         task_s5_bits_dataCheckErr;
  logic        replResp_valid_s4;
  logic [1:0]  task_s3_valid_hold2;
  logic [511:0] data_s4;          // 无复位 RegNext
  logic        need_write_releaseBuf_s4, isD_s4, isTXREQ_s4, isTXRSP_s4, isTXDAT_s4;
  logic        tagError_s4, dataError_s4, l2Error_s4;
  logic        chnl_valid_s4_REG;
  logic [511:0] data_s5;          // 无复位 RegNext
  logic        need_write_releaseBuf_s5, isD_s5, isTXREQ_s5, isTXRSP_s5, isTXDAT_s5;
  logic        tagError_s5, dataMetaError_s5, l2TagError_s5;
  logic        chnl_valid_s5_REG, chnl_fire_s3_d1, chnl_fire_s3_d2;
  logic        io_perf_0_value_REG, io_perf_0_value_dly2;
  logic        io_perf_1_value_REG, io_perf_1_value_dly2;
  logic        io_perf_2_value_REG, io_perf_2_value_dly2;
  logic        io_perf_3_value_REG, io_perf_3_value_dly2;
  logic        io_perf_4_value_REG, io_perf_4_value_dly2;
  logic        io_perf_5_value_REG, io_perf_5_value_dly2;
  logic        io_perf_6_value_REG, io_perf_6_value_dly2;
  logic        io_perf_7_value_REG, io_perf_7_value_dly2;

  // ===== 结构体视图(便于逐字段派生) =====
  task_bundle_t req_s3;
  always_comb begin
    req_s3.channel                = task_s3_bits_channel;
    req_s3.txChannel              = task_s3_bits_txChannel;
    req_s3.set                    = task_s3_bits_set;
    req_s3.tag                    = task_s3_bits_tag;
    req_s3.off                    = task_s3_bits_off;
    req_s3.alias_                 = task_s3_bits_alias;
    req_s3.vaddr                  = task_s3_bits_vaddr;
    req_s3.isKeyword              = task_s3_bits_isKeyword;
    req_s3.opcode                 = task_s3_bits_opcode;
    req_s3.param                  = task_s3_bits_param;
    req_s3.size                   = task_s3_bits_size;
    req_s3.sourceId               = task_s3_bits_sourceId;
    req_s3.bufIdx                 = task_s3_bits_bufIdx;
    req_s3.needProbeAckData       = task_s3_bits_needProbeAckData;
    req_s3.denied                 = task_s3_bits_denied;
    req_s3.corrupt                = task_s3_bits_corrupt;
    req_s3.mshrTask               = task_s3_bits_mshrTask;
    req_s3.mshrId                 = task_s3_bits_mshrId;
    req_s3.aliasTask              = task_s3_bits_aliasTask;
    req_s3.useProbeData           = task_s3_bits_useProbeData;
    req_s3.mshrRetry              = task_s3_bits_mshrRetry;
    req_s3.readProbeDataDown      = task_s3_bits_readProbeDataDown;
    req_s3.fromL2pft              = task_s3_bits_fromL2pft;
    req_s3.needHint               = task_s3_bits_needHint;
    req_s3.dirty                  = task_s3_bits_dirty;
    req_s3.way                    = task_s3_bits_way;
    req_s3.meta_dirty             = task_s3_bits_meta_dirty;
    req_s3.meta_state             = task_s3_bits_meta_state;
    req_s3.meta_clients           = task_s3_bits_meta_clients;
    req_s3.meta_alias             = task_s3_bits_meta_alias;
    req_s3.meta_prefetch          = task_s3_bits_meta_prefetch;
    req_s3.meta_prefetchSrc       = task_s3_bits_meta_prefetchSrc;
    req_s3.meta_accessed          = task_s3_bits_meta_accessed;
    req_s3.meta_tagErr            = task_s3_bits_meta_tagErr;
    req_s3.meta_dataErr           = task_s3_bits_meta_dataErr;
    req_s3.metaWen                = task_s3_bits_metaWen;
    req_s3.tagWen                 = task_s3_bits_tagWen;
    req_s3.dsWen                  = task_s3_bits_dsWen;
    req_s3.wayMask                = task_s3_bits_wayMask;
    req_s3.replTask               = task_s3_bits_replTask;
    req_s3.cmoTask                = task_s3_bits_cmoTask;
    req_s3.cmoAll                 = task_s3_bits_cmoAll;
    req_s3.reqSource              = task_s3_bits_reqSource;
    req_s3.mergeA                 = task_s3_bits_mergeA;
    req_s3.aMergeTask_off         = task_s3_bits_aMergeTask_off;
    req_s3.aMergeTask_alias       = task_s3_bits_aMergeTask_alias;
    req_s3.aMergeTask_vaddr       = task_s3_bits_aMergeTask_vaddr;
    req_s3.aMergeTask_isKeyword   = task_s3_bits_aMergeTask_isKeyword;
    req_s3.aMergeTask_opcode      = task_s3_bits_aMergeTask_opcode;
    req_s3.aMergeTask_param       = task_s3_bits_aMergeTask_param;
    req_s3.aMergeTask_sourceId    = task_s3_bits_aMergeTask_sourceId;
    req_s3.aMergeTask_meta_dirty  = task_s3_bits_aMergeTask_meta_dirty;
    req_s3.aMergeTask_meta_state  = task_s3_bits_aMergeTask_meta_state;
    req_s3.aMergeTask_meta_clients = task_s3_bits_aMergeTask_meta_clients;
    req_s3.aMergeTask_meta_alias  = task_s3_bits_aMergeTask_meta_alias;
    req_s3.aMergeTask_meta_prefetch = task_s3_bits_aMergeTask_meta_prefetch;
    req_s3.aMergeTask_meta_prefetchSrc = task_s3_bits_aMergeTask_meta_prefetchSrc;
    req_s3.aMergeTask_meta_accessed = task_s3_bits_aMergeTask_meta_accessed;
    req_s3.aMergeTask_meta_tagErr = task_s3_bits_aMergeTask_meta_tagErr;
    req_s3.aMergeTask_meta_dataErr = task_s3_bits_aMergeTask_meta_dataErr;
    req_s3.snpHitRelease          = task_s3_bits_snpHitRelease;
    req_s3.snpHitReleaseToInval   = task_s3_bits_snpHitReleaseToInval;
    req_s3.snpHitReleaseToClean   = task_s3_bits_snpHitReleaseToClean;
    req_s3.snpHitReleaseWithData  = task_s3_bits_snpHitReleaseWithData;
    req_s3.snpHitReleaseIdx       = task_s3_bits_snpHitReleaseIdx;
    req_s3.snpHitReleaseMeta_dirty = task_s3_bits_snpHitReleaseMeta_dirty;
    req_s3.snpHitReleaseMeta_state = task_s3_bits_snpHitReleaseMeta_state;
    req_s3.snpHitReleaseMeta_clients = task_s3_bits_snpHitReleaseMeta_clients;
    req_s3.snpHitReleaseMeta_alias = task_s3_bits_snpHitReleaseMeta_alias;
    req_s3.snpHitReleaseMeta_prefetch = task_s3_bits_snpHitReleaseMeta_prefetch;
    req_s3.snpHitReleaseMeta_prefetchSrc = task_s3_bits_snpHitReleaseMeta_prefetchSrc;
    req_s3.snpHitReleaseMeta_accessed = task_s3_bits_snpHitReleaseMeta_accessed;
    req_s3.snpHitReleaseMeta_tagErr = task_s3_bits_snpHitReleaseMeta_tagErr;
    req_s3.snpHitReleaseMeta_dataErr = task_s3_bits_snpHitReleaseMeta_dataErr;
    req_s3.tgtID                  = task_s3_bits_tgtID;
    req_s3.srcID                  = task_s3_bits_srcID;
    req_s3.txnID                  = task_s3_bits_txnID;
    req_s3.homeNID                = task_s3_bits_homeNID;
    req_s3.dbID                   = task_s3_bits_dbID;
    req_s3.fwdNID                 = task_s3_bits_fwdNID;
    req_s3.fwdTxnID               = task_s3_bits_fwdTxnID;
    req_s3.chiOpcode              = task_s3_bits_chiOpcode;
    req_s3.resp                   = task_s3_bits_resp;
    req_s3.fwdState               = task_s3_bits_fwdState;
    req_s3.pCrdType               = task_s3_bits_pCrdType;
    req_s3.retToSrc               = task_s3_bits_retToSrc;
    req_s3.likelyshared           = task_s3_bits_likelyshared;
    req_s3.expCompAck             = task_s3_bits_expCompAck;
    req_s3.allowRetry             = task_s3_bits_allowRetry;
    req_s3.memAttr_allocate       = task_s3_bits_memAttr_allocate;
    req_s3.memAttr_cacheable      = task_s3_bits_memAttr_cacheable;
    req_s3.memAttr_device         = task_s3_bits_memAttr_device;
    req_s3.memAttr_ewa            = task_s3_bits_memAttr_ewa;
    req_s3.traceTag               = task_s3_bits_traceTag;
    req_s3.dataCheckErr           = task_s3_bits_dataCheckErr;
  end
  task_bundle_t task_s4_v;
  always_comb begin
    task_s4_v.channel                = task_s4_bits_channel;
    task_s4_v.txChannel              = task_s4_bits_txChannel;
    task_s4_v.set                    = task_s4_bits_set;
    task_s4_v.tag                    = task_s4_bits_tag;
    task_s4_v.off                    = task_s4_bits_off;
    task_s4_v.alias_                 = task_s4_bits_alias;
    task_s4_v.vaddr                  = task_s4_bits_vaddr;
    task_s4_v.isKeyword              = task_s4_bits_isKeyword;
    task_s4_v.opcode                 = task_s4_bits_opcode;
    task_s4_v.param                  = task_s4_bits_param;
    task_s4_v.size                   = task_s4_bits_size;
    task_s4_v.sourceId               = task_s4_bits_sourceId;
    task_s4_v.bufIdx                 = task_s4_bits_bufIdx;
    task_s4_v.needProbeAckData       = task_s4_bits_needProbeAckData;
    task_s4_v.denied                 = task_s4_bits_denied;
    task_s4_v.corrupt                = task_s4_bits_corrupt;
    task_s4_v.mshrTask               = task_s4_bits_mshrTask;
    task_s4_v.mshrId                 = task_s4_bits_mshrId;
    task_s4_v.aliasTask              = task_s4_bits_aliasTask;
    task_s4_v.useProbeData           = task_s4_bits_useProbeData;
    task_s4_v.mshrRetry              = task_s4_bits_mshrRetry;
    task_s4_v.readProbeDataDown      = task_s4_bits_readProbeDataDown;
    task_s4_v.fromL2pft              = task_s4_bits_fromL2pft;
    task_s4_v.needHint               = task_s4_bits_needHint;
    task_s4_v.dirty                  = task_s4_bits_dirty;
    task_s4_v.way                    = task_s4_bits_way;
    task_s4_v.meta_dirty             = task_s4_bits_meta_dirty;
    task_s4_v.meta_state             = task_s4_bits_meta_state;
    task_s4_v.meta_clients           = task_s4_bits_meta_clients;
    task_s4_v.meta_alias             = task_s4_bits_meta_alias;
    task_s4_v.meta_prefetch          = task_s4_bits_meta_prefetch;
    task_s4_v.meta_prefetchSrc       = task_s4_bits_meta_prefetchSrc;
    task_s4_v.meta_accessed          = task_s4_bits_meta_accessed;
    task_s4_v.meta_tagErr            = task_s4_bits_meta_tagErr;
    task_s4_v.meta_dataErr           = task_s4_bits_meta_dataErr;
    task_s4_v.metaWen                = task_s4_bits_metaWen;
    task_s4_v.tagWen                 = task_s4_bits_tagWen;
    task_s4_v.dsWen                  = task_s4_bits_dsWen;
    task_s4_v.wayMask                = task_s4_bits_wayMask;
    task_s4_v.replTask               = task_s4_bits_replTask;
    task_s4_v.cmoTask                = task_s4_bits_cmoTask;
    task_s4_v.cmoAll                 = task_s4_bits_cmoAll;
    task_s4_v.reqSource              = task_s4_bits_reqSource;
    task_s4_v.mergeA                 = task_s4_bits_mergeA;
    task_s4_v.aMergeTask_off         = task_s4_bits_aMergeTask_off;
    task_s4_v.aMergeTask_alias       = task_s4_bits_aMergeTask_alias;
    task_s4_v.aMergeTask_vaddr       = task_s4_bits_aMergeTask_vaddr;
    task_s4_v.aMergeTask_isKeyword   = task_s4_bits_aMergeTask_isKeyword;
    task_s4_v.aMergeTask_opcode      = task_s4_bits_aMergeTask_opcode;
    task_s4_v.aMergeTask_param       = task_s4_bits_aMergeTask_param;
    task_s4_v.aMergeTask_sourceId    = task_s4_bits_aMergeTask_sourceId;
    task_s4_v.aMergeTask_meta_dirty  = task_s4_bits_aMergeTask_meta_dirty;
    task_s4_v.aMergeTask_meta_state  = task_s4_bits_aMergeTask_meta_state;
    task_s4_v.aMergeTask_meta_clients = task_s4_bits_aMergeTask_meta_clients;
    task_s4_v.aMergeTask_meta_alias  = task_s4_bits_aMergeTask_meta_alias;
    task_s4_v.aMergeTask_meta_prefetch = task_s4_bits_aMergeTask_meta_prefetch;
    task_s4_v.aMergeTask_meta_prefetchSrc = task_s4_bits_aMergeTask_meta_prefetchSrc;
    task_s4_v.aMergeTask_meta_accessed = task_s4_bits_aMergeTask_meta_accessed;
    task_s4_v.aMergeTask_meta_tagErr = task_s4_bits_aMergeTask_meta_tagErr;
    task_s4_v.aMergeTask_meta_dataErr = task_s4_bits_aMergeTask_meta_dataErr;
    task_s4_v.snpHitRelease          = task_s4_bits_snpHitRelease;
    task_s4_v.snpHitReleaseToInval   = task_s4_bits_snpHitReleaseToInval;
    task_s4_v.snpHitReleaseToClean   = task_s4_bits_snpHitReleaseToClean;
    task_s4_v.snpHitReleaseWithData  = task_s4_bits_snpHitReleaseWithData;
    task_s4_v.snpHitReleaseIdx       = task_s4_bits_snpHitReleaseIdx;
    task_s4_v.snpHitReleaseMeta_dirty = task_s4_bits_snpHitReleaseMeta_dirty;
    task_s4_v.snpHitReleaseMeta_state = task_s4_bits_snpHitReleaseMeta_state;
    task_s4_v.snpHitReleaseMeta_clients = task_s4_bits_snpHitReleaseMeta_clients;
    task_s4_v.snpHitReleaseMeta_alias = task_s4_bits_snpHitReleaseMeta_alias;
    task_s4_v.snpHitReleaseMeta_prefetch = task_s4_bits_snpHitReleaseMeta_prefetch;
    task_s4_v.snpHitReleaseMeta_prefetchSrc = task_s4_bits_snpHitReleaseMeta_prefetchSrc;
    task_s4_v.snpHitReleaseMeta_accessed = task_s4_bits_snpHitReleaseMeta_accessed;
    task_s4_v.snpHitReleaseMeta_tagErr = task_s4_bits_snpHitReleaseMeta_tagErr;
    task_s4_v.snpHitReleaseMeta_dataErr = task_s4_bits_snpHitReleaseMeta_dataErr;
    task_s4_v.tgtID                  = task_s4_bits_tgtID;
    task_s4_v.srcID                  = task_s4_bits_srcID;
    task_s4_v.txnID                  = task_s4_bits_txnID;
    task_s4_v.homeNID                = task_s4_bits_homeNID;
    task_s4_v.dbID                   = task_s4_bits_dbID;
    task_s4_v.fwdNID                 = task_s4_bits_fwdNID;
    task_s4_v.fwdTxnID               = task_s4_bits_fwdTxnID;
    task_s4_v.chiOpcode              = task_s4_bits_chiOpcode;
    task_s4_v.resp                   = task_s4_bits_resp;
    task_s4_v.fwdState               = task_s4_bits_fwdState;
    task_s4_v.pCrdType               = task_s4_bits_pCrdType;
    task_s4_v.retToSrc               = task_s4_bits_retToSrc;
    task_s4_v.likelyshared           = task_s4_bits_likelyshared;
    task_s4_v.expCompAck             = task_s4_bits_expCompAck;
    task_s4_v.allowRetry             = task_s4_bits_allowRetry;
    task_s4_v.memAttr_allocate       = task_s4_bits_memAttr_allocate;
    task_s4_v.memAttr_cacheable      = task_s4_bits_memAttr_cacheable;
    task_s4_v.memAttr_device         = task_s4_bits_memAttr_device;
    task_s4_v.memAttr_ewa            = task_s4_bits_memAttr_ewa;
    task_s4_v.traceTag               = task_s4_bits_traceTag;
    task_s4_v.dataCheckErr           = task_s4_bits_dataCheckErr;
  end
  task_bundle_t task_s5_v;
  always_comb begin
    task_s5_v.channel                = task_s5_bits_channel;
    task_s5_v.txChannel              = task_s5_bits_txChannel;
    task_s5_v.set                    = task_s5_bits_set;
    task_s5_v.tag                    = task_s5_bits_tag;
    task_s5_v.off                    = task_s5_bits_off;
    task_s5_v.alias_                 = task_s5_bits_alias;
    task_s5_v.vaddr                  = task_s5_bits_vaddr;
    task_s5_v.isKeyword              = task_s5_bits_isKeyword;
    task_s5_v.opcode                 = task_s5_bits_opcode;
    task_s5_v.param                  = task_s5_bits_param;
    task_s5_v.size                   = task_s5_bits_size;
    task_s5_v.sourceId               = task_s5_bits_sourceId;
    task_s5_v.bufIdx                 = task_s5_bits_bufIdx;
    task_s5_v.needProbeAckData       = task_s5_bits_needProbeAckData;
    task_s5_v.denied                 = task_s5_bits_denied;
    task_s5_v.corrupt                = task_s5_bits_corrupt;
    task_s5_v.mshrTask               = task_s5_bits_mshrTask;
    task_s5_v.mshrId                 = task_s5_bits_mshrId;
    task_s5_v.aliasTask              = task_s5_bits_aliasTask;
    task_s5_v.useProbeData           = task_s5_bits_useProbeData;
    task_s5_v.mshrRetry              = task_s5_bits_mshrRetry;
    task_s5_v.readProbeDataDown      = task_s5_bits_readProbeDataDown;
    task_s5_v.fromL2pft              = task_s5_bits_fromL2pft;
    task_s5_v.needHint               = task_s5_bits_needHint;
    task_s5_v.dirty                  = task_s5_bits_dirty;
    task_s5_v.way                    = task_s5_bits_way;
    task_s5_v.meta_dirty             = task_s5_bits_meta_dirty;
    task_s5_v.meta_state             = task_s5_bits_meta_state;
    task_s5_v.meta_clients           = task_s5_bits_meta_clients;
    task_s5_v.meta_alias             = task_s5_bits_meta_alias;
    task_s5_v.meta_prefetch          = task_s5_bits_meta_prefetch;
    task_s5_v.meta_prefetchSrc       = task_s5_bits_meta_prefetchSrc;
    task_s5_v.meta_accessed          = task_s5_bits_meta_accessed;
    task_s5_v.meta_tagErr            = task_s5_bits_meta_tagErr;
    task_s5_v.meta_dataErr           = task_s5_bits_meta_dataErr;
    task_s5_v.metaWen                = task_s5_bits_metaWen;
    task_s5_v.tagWen                 = task_s5_bits_tagWen;
    task_s5_v.dsWen                  = task_s5_bits_dsWen;
    task_s5_v.wayMask                = task_s5_bits_wayMask;
    task_s5_v.replTask               = task_s5_bits_replTask;
    task_s5_v.cmoTask                = task_s5_bits_cmoTask;
    task_s5_v.cmoAll                 = task_s5_bits_cmoAll;
    task_s5_v.reqSource              = task_s5_bits_reqSource;
    task_s5_v.mergeA                 = task_s5_bits_mergeA;
    task_s5_v.aMergeTask_off         = task_s5_bits_aMergeTask_off;
    task_s5_v.aMergeTask_alias       = task_s5_bits_aMergeTask_alias;
    task_s5_v.aMergeTask_vaddr       = task_s5_bits_aMergeTask_vaddr;
    task_s5_v.aMergeTask_isKeyword   = task_s5_bits_aMergeTask_isKeyword;
    task_s5_v.aMergeTask_opcode      = task_s5_bits_aMergeTask_opcode;
    task_s5_v.aMergeTask_param       = task_s5_bits_aMergeTask_param;
    task_s5_v.aMergeTask_sourceId    = task_s5_bits_aMergeTask_sourceId;
    task_s5_v.aMergeTask_meta_dirty  = task_s5_bits_aMergeTask_meta_dirty;
    task_s5_v.aMergeTask_meta_state  = task_s5_bits_aMergeTask_meta_state;
    task_s5_v.aMergeTask_meta_clients = task_s5_bits_aMergeTask_meta_clients;
    task_s5_v.aMergeTask_meta_alias  = task_s5_bits_aMergeTask_meta_alias;
    task_s5_v.aMergeTask_meta_prefetch = task_s5_bits_aMergeTask_meta_prefetch;
    task_s5_v.aMergeTask_meta_prefetchSrc = task_s5_bits_aMergeTask_meta_prefetchSrc;
    task_s5_v.aMergeTask_meta_accessed = task_s5_bits_aMergeTask_meta_accessed;
    task_s5_v.aMergeTask_meta_tagErr = task_s5_bits_aMergeTask_meta_tagErr;
    task_s5_v.aMergeTask_meta_dataErr = task_s5_bits_aMergeTask_meta_dataErr;
    task_s5_v.snpHitRelease          = task_s5_bits_snpHitRelease;
    task_s5_v.snpHitReleaseToInval   = task_s5_bits_snpHitReleaseToInval;
    task_s5_v.snpHitReleaseToClean   = task_s5_bits_snpHitReleaseToClean;
    task_s5_v.snpHitReleaseWithData  = task_s5_bits_snpHitReleaseWithData;
    task_s5_v.snpHitReleaseIdx       = task_s5_bits_snpHitReleaseIdx;
    task_s5_v.snpHitReleaseMeta_dirty = task_s5_bits_snpHitReleaseMeta_dirty;
    task_s5_v.snpHitReleaseMeta_state = task_s5_bits_snpHitReleaseMeta_state;
    task_s5_v.snpHitReleaseMeta_clients = task_s5_bits_snpHitReleaseMeta_clients;
    task_s5_v.snpHitReleaseMeta_alias = task_s5_bits_snpHitReleaseMeta_alias;
    task_s5_v.snpHitReleaseMeta_prefetch = task_s5_bits_snpHitReleaseMeta_prefetch;
    task_s5_v.snpHitReleaseMeta_prefetchSrc = task_s5_bits_snpHitReleaseMeta_prefetchSrc;
    task_s5_v.snpHitReleaseMeta_accessed = task_s5_bits_snpHitReleaseMeta_accessed;
    task_s5_v.snpHitReleaseMeta_tagErr = task_s5_bits_snpHitReleaseMeta_tagErr;
    task_s5_v.snpHitReleaseMeta_dataErr = task_s5_bits_snpHitReleaseMeta_dataErr;
    task_s5_v.tgtID                  = task_s5_bits_tgtID;
    task_s5_v.srcID                  = task_s5_bits_srcID;
    task_s5_v.txnID                  = task_s5_bits_txnID;
    task_s5_v.homeNID                = task_s5_bits_homeNID;
    task_s5_v.dbID                   = task_s5_bits_dbID;
    task_s5_v.fwdNID                 = task_s5_bits_fwdNID;
    task_s5_v.fwdTxnID               = task_s5_bits_fwdTxnID;
    task_s5_v.chiOpcode              = task_s5_bits_chiOpcode;
    task_s5_v.resp                   = task_s5_bits_resp;
    task_s5_v.fwdState               = task_s5_bits_fwdState;
    task_s5_v.pCrdType               = task_s5_bits_pCrdType;
    task_s5_v.retToSrc               = task_s5_bits_retToSrc;
    task_s5_v.likelyshared           = task_s5_bits_likelyshared;
    task_s5_v.expCompAck             = task_s5_bits_expCompAck;
    task_s5_v.allowRetry             = task_s5_bits_allowRetry;
    task_s5_v.memAttr_allocate       = task_s5_bits_memAttr_allocate;
    task_s5_v.memAttr_cacheable      = task_s5_bits_memAttr_cacheable;
    task_s5_v.memAttr_device         = task_s5_bits_memAttr_device;
    task_s5_v.memAttr_ewa            = task_s5_bits_memAttr_ewa;
    task_s5_v.traceTag               = task_s5_bits_traceTag;
    task_s5_v.dataCheckErr           = task_s5_bits_dataCheckErr;
  end

  // ===== s3: 通道 one-hot / mshr / TL-opcode 译码 =====
  wire mshr_req_s3  = task_s3_bits_mshrTask;
  wire fromA_s3 = task_s3_bits_channel[0];
  wire fromB_s3 = task_s3_bits_channel[1];
  wire fromC_s3 = task_s3_bits_channel[2];
  wire toTXREQ_s3 = task_s3_bits_txChannel[0];
  wire toTXRSP_s3 = task_s3_bits_txChannel[1];
  wire toTXDAT_s3 = task_s3_bits_txChannel[2];
  wire sinkA_req_s3 = ~mshr_req_s3 & fromA_s3;
  wire sinkB_req_s3 = ~mshr_req_s3 & fromB_s3;
  wire sinkC_req_s3 = ~mshr_req_s3 & fromC_s3;
  // sinkA TL opcode: Get=4 Hint=5 AcquireBlock=6 AcquirePerm=7 CBOClean=12 CBOFlush=13 CBOInval=14
  wire req_acquire_s3      = sinkA_req_s3 & (task_s3_bits_opcode==4'd6 | task_s3_bits_opcode==4'd7);
  wire req_acquireBlock_s3 = sinkA_req_s3 & task_s3_bits_opcode==4'd6;
  wire req_prefetch_s3     = sinkA_req_s3 & task_s3_bits_opcode==4'd5;
  wire req_get_s3          = sinkA_req_s3 & task_s3_bits_opcode==4'd4;
  wire req_cbo_clean_s3    = sinkA_req_s3 & task_s3_bits_opcode==4'd12;
  wire req_cbo_flush_s3    = sinkA_req_s3 & task_s3_bits_opcode==4'd13;   // enableL2Flush=false → cmoHitInvalid=0
  wire req_cbo_inval_s3    = sinkA_req_s3 & task_s3_bits_opcode==4'd14;
  wire cmo_cbo_s3          = req_cbo_clean_s3 | req_cbo_flush_s3 | req_cbo_inval_s3;
  // mshr 任务 TL-D 类: Grant=4 GrantData=5 AccessAckData=1 HintAck=2 CBOAck=8
  wire mshr_grant_s3        = mshr_req_s3 & fromA_s3 & (task_s3_bits_opcode==4'd4 | task_s3_bits_opcode==4'd5);
  wire mshr_grantdata_s3    = mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd5;
  wire mshr_accessackdata_s3= mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd1;
  wire mshr_hintack_s3      = mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd2;
  wire mshr_cmoresp_s3      = mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd8;
  wire mshr_refill_s3       = mshr_accessackdata_s3 | mshr_hintack_s3 | mshr_grant_s3;
  // mshr 任务 CHI 类(按 txChannel + chiOpcode)
  wire mshr_snpResp_s3        = mshr_req_s3 & toTXRSP_s3 & task_s3_bits_chiOpcode==7'h01;
  wire mshr_snpRespFwded_s3   = mshr_req_s3 & toTXRSP_s3 & task_s3_bits_chiOpcode==7'h09;
  wire mshr_snpRespData_s3    = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h01;
  wire mshr_snpRespDataPtl_s3 = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h05;
  wire mshr_snpRespDataFwded_s3 = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h06;
  wire mshr_snpRespX_s3     = mshr_snpResp_s3 | mshr_snpRespFwded_s3;
  wire mshr_snpRespDataX_s3 = mshr_snpRespData_s3 | mshr_snpRespDataPtl_s3 | mshr_snpRespDataFwded_s3;
  wire mshr_dct_s3          = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h04;  // CompData
  wire mshr_writeCleanFull_s3 = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h17;
  wire mshr_writeBackFull_s3  = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h1B;
  wire mshr_writeEvictFull_s3 = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h15;
  wire mshr_writeEvictOrEvict_s3 = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h42;  // Issue>=Eb
  wire mshr_evict_s3          = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h0D;
  wire mshr_cbWrData_s3       = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h02;  // CopyBackWrData

  // ===== Directory 结果 + nestable(snoop 嵌套 Release 时以 MSHR meta 替代目录) =====
  wire        dh = io_dirResp_s3_hit;
  wire [1:0]  meta_state = io_dirResp_s3_meta_state;
  wire        meta_has_clients_s3 = io_dirResp_s3_meta_clients;
  wire        req_needT_s3 = f_needT(task_s3_bits_opcode, task_s3_bits_param);
  wire        cache_alias = req_acquire_s3 & dh & io_dirResp_s3_meta_clients &
                            (io_dirResp_s3_meta_alias != task_s3_bits_alias);
  wire        snpHitRel = task_s3_bits_snpHitRelease;
  wire        nest_hit       = snpHitRel ? (task_s3_bits_snpHitReleaseMeta_state != INVALID) : dh;
  wire [1:0]  nest_state     = snpHitRel ? task_s3_bits_snpHitReleaseMeta_state    : meta_state;
  wire        nest_dirty     = snpHitRel ? task_s3_bits_snpHitReleaseMeta_dirty    : io_dirResp_s3_meta_dirty;
  wire        nest_clients   = snpHitRel ? task_s3_bits_snpHitReleaseMeta_clients  : io_dirResp_s3_meta_clients;
  wire        nest_tagErr    = snpHitRel ? task_s3_bits_snpHitReleaseMeta_tagErr   : io_dirResp_s3_meta_tagErr;
  wire        nest_error     = io_dirResp_s3_error;
  // 错误标志
  wire        tagError_s3  = io_dirResp_s3_error | io_dirResp_s3_meta_tagErr;
  wire        dataError_s3 = io_dirResp_s3_meta_dataErr;
  wire        l2TagError_s3 = io_dirResp_s3_error;
  wire        l2Error_s3   = io_dirResp_s3_error | (mshr_req_s3 & task_s3_bits_dataCheckErr);

  // ===== replacer 响应(替换路是否需先回写) =====
  wire replResp_valid_s3   = io_replResp_valid;
  wire replResp_valid_hold = replResp_valid_s3 | replResp_valid_s4;
  wire retry     = replResp_valid_hold & io_replResp_bits_retry;
  wire need_repl = replResp_valid_hold & (io_replResp_bits_meta_state != INVALID) & task_s3_bits_replTask;

  // ===== A 通道是否需 Acquire/Probe/Release(向下获权/探测/回写) =====
  wire acquire_on_miss_s3 = req_acquire_s3 | req_prefetch_s3 | req_get_s3;
  wire acquire_on_hit_s3  = (meta_state==BRANCH) & req_needT_s3 & ~req_prefetch_s3;
  wire need_acquire_s3_a  = fromA_s3 & ((dh ? acquire_on_hit_s3 : acquire_on_miss_s3) | cmo_cbo_s3);
  wire need_probe_s3_a    = dh & meta_has_clients_s3 & (
       (req_get_s3 & meta_state==TRUNK) | (req_cbo_clean_s3 & meta_state==TRUNK) |
       req_cbo_flush_s3 | req_cbo_inval_s3);
  wire need_release_s3_a  = dh & (
       (req_cbo_clean_s3 & ~need_probe_s3_a & io_dirResp_s3_meta_dirty) |
       (req_cbo_flush_s3 & (|meta_state)) | (req_cbo_inval_s3 & (|meta_state)));
  wire need_cmoresp_s3_a  = cmo_cbo_s3;
  wire need_compack_s3_a  = ~cmo_cbo_s3;
  wire need_mshr_s3_a     = need_acquire_s3_a | need_probe_s3_a | cache_alias;

  // ===== B 通道(RXSNP snoop): 是否需 pProbe / DCT 前递 =====
  wire [6:0] chi = task_s3_bits_chiOpcode;
  wire expectFwd = f_isSnpXFwd(chi);
  wire canFwd    = nest_hit & ~(nest_tagErr | nest_error);
  wire doFwd     = expectFwd & canFwd;
  wire need_pprobe_s3_b_snpStable = fromB_s3 & (f_isSnpOnceX(chi) | f_isSnpQuery(chi) | f_isSnpStashX(chi))
                                    & dh & meta_state==TRUNK & meta_has_clients_s3;
  wire need_pprobe_s3_b_snpToB    = fromB_s3 & (f_isSnpToB(chi) | chi==7'h08)
                                    & dh & meta_state==TRUNK & meta_has_clients_s3;
  wire need_pprobe_s3_b_snpToN    = fromB_s3 & (f_isSnpUniqueX(chi) | chi==7'h09 | f_isSnpMakeInvalidX(chi))
                                    & dh & meta_has_clients_s3;
  wire need_pprobe_s3_b_snpNDERR  = fromB_s3 & tagError_s3 & dh;
  wire need_pprobe_s3_b = need_pprobe_s3_b_snpStable | need_pprobe_s3_b_snpToB |
                         need_pprobe_s3_b_snpToN | need_pprobe_s3_b_snpNDERR;
  wire need_dct_s3_b    = doFwd;
  wire need_mshr_s3_b   = need_pprobe_s3_b | need_dct_s3_b;
  wire need_mshr_s3     = need_mshr_s3_a | need_mshr_s3_b;

  // ===== snoop 响应: 是否回数据 / PassDirty / 响应后一致性态 =====
  wire retToSrc = task_s3_bits_retToSrc;
  wire neverRespData = f_isSnpMakeInvalidX(chi) | f_isSnpStashX(chi) | f_isSnpQuery(chi) |
                       chi==7'h13 | chi==7'h17;  // SnpOnceFwd / SnpUniqueFwd
  wire shouldRespData_dirty = nest_hit & (nest_state==TIP | nest_state==TRUNK) & nest_dirty;
  wire shouldRespData_once  = nest_hit & nest_state==TIP & ~nest_dirty & chi==7'h03;  // SnpOnce
  wire shouldRespData_retToSrc_fwd    = nest_hit & retToSrc & f_isSnpXFwd(chi);
  wire shouldRespData_retToSrc_nonFwd = nest_hit & retToSrc & nest_state==BRANCH &
       (chi==7'h03 | chi==7'h07 | f_isSnpToBNonFwd(chi));  // SnpOnce / SnpUnique / SnpToB-nonFwd
  wire shouldRespData = shouldRespData_dirty | shouldRespData_once |
                        shouldRespData_retToSrc_fwd | shouldRespData_retToSrc_nonFwd;
  wire doRespData = shouldRespData & ~neverRespData;
  wire respPassDirty = doRespData & nest_hit & f_isT(nest_state) & nest_dirty &
       (chi != 7'h03 | snpHitRel) & ~(f_isSnpStashX(chi) | f_isSnpQuery(chi));

  // respCacheState: snoop 命中且无 tagErr 时, 按 snoop 类型降级(顺序 when, 后者覆盖前者)
  logic [2:0] respCacheState;
  always_comb begin
    respCacheState = CHI_I;
    if (nest_hit & ~tagError_s3) begin
      if (f_isSnpToB(chi))
        respCacheState = task_s3_bits_snpHitReleaseToInval ? CHI_I : CHI_SC;
      if (f_isSnpOnceX(chi) | f_isSnpStashX(chi) | f_isSnpQuery(chi))
        respCacheState = (nest_state==BRANCH) ? CHI_SC : (nest_dirty ? CHI_UC : CHI_UC); // UD==UC==2
      if (f_isSnpOnceX(chi)) begin
        if (task_s3_bits_snpHitReleaseToClean & nest_dirty) respCacheState = CHI_SC;
        if (task_s3_bits_snpHitReleaseToInval)              respCacheState = CHI_I;
      end
      if (chi==7'h08)  // SnpCleanShared
        respCacheState = f_isT(nest_state) ? CHI_UC : CHI_SC;
    end
  end
  wire [2:0] snpResp_resp = respCacheState | ((respPassDirty & doRespData) ? CHI_PD : 3'h0);

  // fwdState: DCT 前递时给请求方的一致性态
  logic [2:0] fwdCacheState; logic fwdPassDirty;
  always_comb begin
    fwdCacheState = CHI_I; fwdPassDirty = 1'b0;
    if (nest_hit) begin
      if (f_isSnpToBFwd(chi))
        fwdCacheState = task_s3_bits_snpHitReleaseToInval ? CHI_I : CHI_SC;
      if (chi==7'h17) begin  // SnpUniqueFwd
        if (nest_state==TIP & nest_dirty) begin fwdCacheState = CHI_UC; fwdPassDirty = 1'b1; end // UD==UC==2
        else                                    fwdCacheState = CHI_UC;
      end
    end
  end
  wire [2:0] snpResp_fwdState = fwdCacheState | (fwdPassDirty ? CHI_PD : 3'h0);

  // snoop 响应 CHI opcode: {doFwd,doRespData} → SnpResp/SnpRespFwded/SnpRespData/SnpRespDataFwded
  logic [6:0] snpResp_chiOpcode;
  always_comb begin
    case ({doFwd, doRespData})
      2'b00: snpResp_chiOpcode = 7'h01;  // SnpResp
      2'b10: snpResp_chiOpcode = 7'h09;  // SnpRespFwded
      2'b01: snpResp_chiOpcode = 7'h01;  // SnpRespData (DAT 通道, 同值 1)
      2'b11: snpResp_chiOpcode = 7'h06;  // SnpRespDataFwded
    endcase
  end

  // metaW_s3_b: B-snoop 命中写回的目录 meta(isSnpToN 全清, 否则降 BRANCH/保持)
  wire isSnpToN_b = f_isSnpToN(chi);
  wire [1:0] metaW_s3_b_state   = isSnpToN_b ? INVALID : (chi==7'h08 ? meta_state : BRANCH);
  wire       metaW_s3_b_clients = ~isSnpToN_b & io_dirResp_s3_meta_clients;
  wire [1:0] metaW_s3_b_alias   = isSnpToN_b ? 2'h0 : io_dirResp_s3_meta_alias;
  wire       metaW_s3_b_accessed= ~isSnpToN_b & io_dirResp_s3_meta_accessed;
  wire       metaW_s3_b_tagErr  = ~isSnpToN_b & io_dirResp_s3_meta_tagErr;
  wire       metaW_s3_b_dataErr = ~isSnpToN_b & io_dirResp_s3_meta_dataErr;

  // ===== 写 Directory 的各路有效(a>b>c>mshr>cmo 优先, 提前定义供 source_req 使用) =====
  wire metaW_valid_s3_a = sinkA_req_s3 & ~need_mshr_s3_a & ~req_get_s3 & ~req_prefetch_s3 & ~cmo_cbo_s3;
  wire metaW_valid_s3_b = sinkB_req_s3 & ~need_mshr_s3_b & dh &
       (chi != 7'h03 | (task_s3_bits_snpHitReleaseToClean & task_s3_bits_snpHitReleaseMeta_dirty)) &
       ~f_isSnpStashX(chi) & ~f_isSnpQuery(chi) &
       (meta_state==TIP | (meta_state==BRANCH & f_isSnpToN(chi)));
  wire metaW_valid_s3_c    = sinkC_req_s3 & dh;
  wire metaW_valid_s3_mshr = mshr_req_s3 & task_s3_bits_metaWen & ~(mshr_refill_s3 & retry);
  wire metaW_valid_s3_cmo  = req_cbo_inval_s3 & dh;
  wire mw_ab  = metaW_valid_s3_a | metaW_valid_s3_b;
  wire mw_abc = mw_ab | metaW_valid_s3_c;

  // ===== sink 直接响应(无需 MSHR 的 A/B/C 请求) =====
  wire sink_resp_s3_valid = task_s3_valid & ~mshr_req_s3 & ~need_mshr_s3;
  wire sink_resp_s3_a_promoteT = dh & f_isT(meta_state);
  // odOpGen: A 请求 → TL-D opcode 查表(Get→AccessAckData, AcqBlock→GrantData, AcqPerm→Grant, Hint→HintAck, CBO→CBOAck)
  wire [15:0][3:0] odOp_lut = '{4'h0,4'h8,4'h8,4'h8,4'h0,4'h0,4'h0,4'h0,
                                4'h4,4'h5,4'h2,4'h1,4'h1,4'h1,4'h0,4'h0};
  wire [3:0] sink_resp_s3_bits_opcode =
       fromA_s3 ? odOp_lut[task_s3_bits_opcode] : (fromB_s3 ? 4'h0 : 4'h6);  // C→ReleaseAck=6
  wire [2:0] sink_resp_s3_bits_param =
       fromA_s3 ? {2'h0, req_acquire_s3 & ~(|task_s3_bits_param) & ~sink_resp_s3_a_promoteT} : 3'h0;

  // ===== source_req_s3 = req_s3 + (sink_resp 时覆盖 opcode/param/mshrId; B-snoop 时覆盖响应字段) =====
  wire b_resp_ovr = sink_resp_s3_valid & ~fromA_s3 & fromB_s3;  // golden _GEN_3 取反
  task_bundle_t source_req_s3;
  always_comb begin
    source_req_s3 = req_s3;
    source_req_s3.txChannel    = b_resp_ovr ? {doRespData, ~doRespData, 1'b0} : task_s3_bits_txChannel;
    source_req_s3.opcode       = sink_resp_s3_valid ? sink_resp_s3_bits_opcode : task_s3_bits_opcode;
    source_req_s3.param        = sink_resp_s3_valid ? sink_resp_s3_bits_param : task_s3_bits_param;
    source_req_s3.size         = b_resp_ovr ? 3'h6 : task_s3_bits_size;
    source_req_s3.mshrId       = sink_resp_s3_valid ? (task_s3_bits_sourceId + 8'h80) : task_s3_bits_mshrId;
    source_req_s3.meta_dirty   = b_resp_ovr ? 1'b0 : task_s3_bits_meta_dirty;
    source_req_s3.meta_state   = b_resp_ovr ? metaW_s3_b_state : task_s3_bits_meta_state;
    source_req_s3.meta_clients = b_resp_ovr ? metaW_s3_b_clients : task_s3_bits_meta_clients;
    source_req_s3.meta_alias   = b_resp_ovr ? metaW_s3_b_alias : task_s3_bits_meta_alias;
    source_req_s3.meta_prefetch = b_resp_ovr ? 1'b0 : task_s3_bits_meta_prefetch;
    source_req_s3.meta_prefetchSrc = b_resp_ovr ? 3'h0 : task_s3_bits_meta_prefetchSrc;
    source_req_s3.meta_accessed = b_resp_ovr ? metaW_s3_b_accessed : task_s3_bits_meta_accessed;
    source_req_s3.meta_tagErr  = b_resp_ovr ? metaW_s3_b_tagErr : task_s3_bits_meta_tagErr;
    source_req_s3.meta_dataErr = b_resp_ovr ? metaW_s3_b_dataErr : task_s3_bits_meta_dataErr;
    source_req_s3.metaWen      = b_resp_ovr ? metaW_valid_s3_b : task_s3_bits_metaWen;
    source_req_s3.tgtID        = b_resp_ovr ? task_s3_bits_srcID : task_s3_bits_tgtID;
    source_req_s3.srcID        = b_resp_ovr ? task_s3_bits_tgtID : task_s3_bits_srcID;
    source_req_s3.dbID         = b_resp_ovr ? 12'h0 : task_s3_bits_dbID;
    source_req_s3.chiOpcode    = b_resp_ovr ? snpResp_chiOpcode : task_s3_bits_chiOpcode;
    source_req_s3.resp         = b_resp_ovr ? snpResp_resp : task_s3_bits_resp;
    source_req_s3.fwdState     = b_resp_ovr ? snpResp_fwdState : task_s3_bits_fwdState;
    source_req_s3.pCrdType     = b_resp_ovr ? 4'h0 : task_s3_bits_pCrdType;
  end

  // ===== DataStorage 读/写决策 =====
  wire [511:0] data_s3 = io_releaseBufResp_s3_valid ? io_releaseBufResp_s3_bits_data
                                                    : io_refillBufResp_s3_bits_data;
  wire [511:0] c_releaseData_s3 = {io_bufResp_data_1, io_bufResp_data_0};
  wire hasData_s3_tl  = source_req_s3.opcode[0];
  wire hasData_s3_chi = source_req_s3.txChannel[2];
  wire hasData_s3     = hasData_s3_tl | hasData_s3_chi;
  wire data_unready_s3    = hasData_s3   & ~mshr_req_s3;
  wire data_unready_s3_tl = hasData_s3_tl & ~mshr_req_s3;
  wire need_data_a = dh & (req_get_s3 | req_acquireBlock_s3);
  wire need_data_b = sinkB_req_s3 & (doRespData | doFwd | (nest_hit & nest_state==TRUNK));
  wire need_data_mshr_repl = mshr_refill_s3 & need_repl & ~retry;
  wire need_data_cmo = cmo_cbo_s3 & nest_hit & nest_dirty;
  wire ren = need_data_a | need_data_b | need_data_mshr_repl | need_data_cmo;
  // 写 DS: C 释放带数据 / mshr 各类回写填充
  wire wen_c = sinkC_req_s3 & f_isParamFromT(task_s3_bits_param) & task_s3_bits_opcode[0] & dh;
  wire wen_mshr = task_s3_bits_dsWen & (mshr_snpRespX_s3 | mshr_snpRespDataX_s3 |
       mshr_writeCleanFull_s3 | mshr_writeBackFull_s3 | mshr_writeEvictFull_s3 |
       mshr_writeEvictOrEvict_s3 | mshr_evict_s3 | (mshr_refill_s3 & ~need_repl & ~retry));
  wire wen = wen_c | wen_mshr;
  wire need_write_releaseBuf = need_probe_s3_a | cache_alias | (need_data_b & need_mshr_s3_b) |
                               need_data_mshr_repl | need_data_cmo;

  wire [2:0] metaW_way = (mshr_refill_s3 & task_s3_bits_replTask) ? io_replResp_bits_way :
                         (mshr_req_s3 ? task_s3_bits_way : io_dirResp_s3_way);
  assign io_toDS_en_s3 = task_s3_valid & (ren | wen);
  assign io_toDS_req_s3_valid = task_s3_valid_hold2[0] & (ren | wen);
  assign io_toDS_req_s3_bits_way = metaW_way;
  assign io_toDS_req_s3_bits_set = mshr_req_s3 ? task_s3_bits_set : io_dirResp_s3_set;
  assign io_toDS_req_s3_bits_wen = wen;
  assign io_toDS_wdata_s3_data = ~mshr_req_s3 ? c_releaseData_s3 :
       (task_s3_bits_useProbeData ? io_releaseBufResp_s3_bits_data : io_refillBufResp_s3_bits_data);

  // ===== 写 Directory: metaWReq(含复位逐 set 清零) + tagWReq =====
  // mshr 写 meta 取 mergeA 的 aMergeTask.meta 或 req.meta
  wire       mshrMeta_dirty   = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_dirty    : task_s3_bits_meta_dirty;
  wire [1:0] mshrMeta_state   = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_state    : task_s3_bits_meta_state;
  wire       mshrMeta_clients = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_clients  : task_s3_bits_meta_clients;
  wire [1:0] mshrMeta_alias   = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_alias    : task_s3_bits_meta_alias;
  wire       mshrMeta_prefetch= task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_prefetch : task_s3_bits_meta_prefetch;
  wire [2:0] mshrMeta_prefetchSrc = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_prefetchSrc : task_s3_bits_meta_prefetchSrc;
  wire       mshrMeta_accessed= task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_accessed : task_s3_bits_meta_accessed;
  // wmeta 优先级 a>b>c>mshr>(cmo=全0)
  assign io_metaWReq_valid = ~resetFinish | (task_s3_valid &
       (metaW_valid_s3_a | metaW_valid_s3_b | metaW_valid_s3_c | metaW_valid_s3_mshr | metaW_valid_s3_cmo));
  assign io_metaWReq_bits_set   = resetFinish ? task_s3_bits_set : resetIdx;
  assign io_metaWReq_bits_wayOH = resetFinish ? (8'h1 << metaW_way) : 8'hFF;
  assign io_metaWReq_bits_wmeta_dirty = resetFinish & (
       metaW_valid_s3_a ? io_dirResp_s3_meta_dirty :
       metaW_valid_s3_b ? 1'b0 :
       metaW_valid_s3_c ? (io_dirResp_s3_meta_dirty | wen_c) :
       metaW_valid_s3_mshr ? mshrMeta_dirty : 1'b0);
  assign io_metaWReq_bits_wmeta_state = ~resetFinish ? 2'h0 : (
       metaW_valid_s3_a ? ((req_needT_s3 | sink_resp_s3_a_promoteT) ? TRUNK : meta_state) :
       metaW_valid_s3_b ? metaW_s3_b_state :
       metaW_valid_s3_c ? (f_isParamFromT(task_s3_bits_param) ? TIP : meta_state) :
       metaW_valid_s3_mshr ? mshrMeta_state : 2'h0);
  assign io_metaWReq_bits_wmeta_clients = resetFinish & (
       metaW_valid_s3_a ? ~io_dirResp_s3_error :
       metaW_valid_s3_b ? metaW_s3_b_clients :
       metaW_valid_s3_c ? ~f_isToN(task_s3_bits_param) :
       metaW_valid_s3_mshr ? mshrMeta_clients : 1'b0);
  assign io_metaWReq_bits_wmeta_alias = ~resetFinish ? 2'h0 : (
       metaW_valid_s3_a ? ((req_get_s3 | req_prefetch_s3) ? io_dirResp_s3_meta_alias : task_s3_bits_alias) :
       metaW_valid_s3_b ? metaW_s3_b_alias :
       metaW_valid_s3_c ? io_dirResp_s3_meta_alias :
       metaW_valid_s3_mshr ? mshrMeta_alias : 2'h0);
  assign io_metaWReq_bits_wmeta_prefetch    = resetFinish & ~mw_abc & metaW_valid_s3_mshr & mshrMeta_prefetch;
  assign io_metaWReq_bits_wmeta_prefetchSrc = (~resetFinish | mw_abc | ~metaW_valid_s3_mshr) ? 3'h0 : mshrMeta_prefetchSrc;
  assign io_metaWReq_bits_wmeta_accessed = resetFinish & (
       metaW_valid_s3_a ? 1'b1 :
       metaW_valid_s3_b ? metaW_s3_b_accessed :
       metaW_valid_s3_c ? io_dirResp_s3_meta_accessed :
       metaW_valid_s3_mshr ? mshrMeta_accessed : 1'b0);
  assign io_metaWReq_bits_wmeta_tagErr = resetFinish & (
       metaW_valid_s3_a ? io_dirResp_s3_meta_tagErr :
       metaW_valid_s3_b ? metaW_s3_b_tagErr :
       metaW_valid_s3_c ? (wen_c ? task_s3_bits_denied : io_dirResp_s3_meta_tagErr) :
       metaW_valid_s3_mshr ? task_s3_bits_denied : 1'b0);
  assign io_metaWReq_bits_wmeta_dataErr = resetFinish & (
       metaW_valid_s3_a ? io_dirResp_s3_meta_dataErr :
       metaW_valid_s3_b ? metaW_s3_b_dataErr :
       metaW_valid_s3_c ? (wen_c ? task_s3_bits_corrupt : io_dirResp_s3_meta_dataErr) :
       metaW_valid_s3_mshr ? task_s3_bits_corrupt : 1'b0);
  assign io_tagWReq_valid = task_s3_valid & task_s3_bits_tagWen & mshr_refill_s3 & ~retry;
  assign io_tagWReq_bits_set = task_s3_bits_set;
  assign io_tagWReq_bits_way = (mshr_refill_s3 & task_s3_bits_replTask) ? io_replResp_bits_way : task_s3_bits_way;
  assign io_tagWReq_bits_wtag = task_s3_bits_tag;

  // ===== 嵌套写回 nestedwb(C 释放置脏/置 tip; B snoop 失效/降级) =====
  assign io_nestedwb_set = task_s3_bits_set;
  assign io_nestedwb_tag = task_s3_bits_tag;
  assign io_nestedwb_c_set_dirty = task_s3_valid & fromC_s3 & task_s3_bits_opcode==4'd7 & task_s3_bits_param==3'd1;  // ReleaseData & TtoN
  assign io_nestedwb_c_set_tip   = task_s3_valid & fromC_s3 & task_s3_bits_opcode==4'd6 & task_s3_bits_param==3'd1;  // Release & TtoN
  assign io_nestedwb_b_inv_dirty = task_s3_valid & fromB_s3 & task_s3_bits_snpHitReleaseToInval &
                                   ~(f_isSnpStashX(chi) | f_isSnpQuery(chi));
  assign io_nestedwb_b_toB     = task_s3_valid & fromB_s3 & source_req_s3.metaWen & source_req_s3.meta_state==BRANCH;
  assign io_nestedwb_b_toN     = task_s3_valid & fromB_s3 & source_req_s3.metaWen & source_req_s3.meta_state==INVALID;
  assign io_nestedwb_b_toClean = task_s3_valid & fromB_s3 & source_req_s3.metaWen & ~source_req_s3.meta_dirty;
  assign io_nestedwbData_data  = c_releaseData_s3;

  // ===== MSHR 分配(s3 判定需 MSHR 时, 把 dirResult/初态/任务 发往 MSHRCtl) =====
  assign io_toMSHRCtl_mshr_alloc_s3_valid = task_s3_valid & ~mshr_req_s3 & need_mshr_s3;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_hit = nest_hit;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_tag = (snpHitRel ? task_s3_bits_tag : io_dirResp_s3_tag);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_set = (snpHitRel ? task_s3_bits_set : io_dirResp_s3_set);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_way = io_dirResp_s3_way;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dirty = nest_dirty;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_state = nest_state;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_clients = nest_clients;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_alias = (snpHitRel ? task_s3_bits_snpHitReleaseMeta_alias : io_dirResp_s3_meta_alias);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetch = (snpHitRel ? task_s3_bits_snpHitReleaseMeta_prefetch : io_dirResp_s3_meta_prefetch);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc = (snpHitRel ? task_s3_bits_snpHitReleaseMeta_prefetchSrc : io_dirResp_s3_meta_prefetchSrc);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_accessed = (snpHitRel ? task_s3_bits_snpHitReleaseMeta_accessed : io_dirResp_s3_meta_accessed);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_tagErr = nest_tagErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_meta_dataErr = (snpHitRel ? task_s3_bits_snpHitReleaseMeta_dataErr : io_dirResp_s3_meta_dataErr);
  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_error = nest_error;
  // FSMState 初态: 全 1(s_/w_ 取假为有效), 按通道与需求清相应位
  logic [17:0] alloc_state;  // 顺序见 FSM 端口
  always_comb begin
    alloc_state = '1;
    if (fromA_s3) begin
      alloc_state[5]  = cmo_cbo_s3;            // s_refill
      alloc_state[15] = cmo_cbo_s3 | dh;       // w_replResp
      if (need_acquire_s3_a) begin
        alloc_state[0]  = 1'b0;                // s_acquire
        alloc_state[16] = ~need_compack_s3_a;  // s_rcompack
        alloc_state[11] = 1'b0;                // w_grantfirst
        alloc_state[12] = 1'b0;                // w_grantlast
        alloc_state[13] = 1'b0;                // w_grant
      end
      if (cache_alias | need_probe_s3_a) begin
        alloc_state[1] = 1'b0;                 // s_rprobe
        alloc_state[7] = 1'b0;                 // w_rprobeackfirst
        alloc_state[8] = 1'b0;                 // w_rprobeacklast
      end
      if (need_release_s3_a) begin
        alloc_state[3]  = 1'b0;                // s_release
        alloc_state[14] = 1'b0;                // w_releaseack
      end
      if (need_cmoresp_s3_a) alloc_state[6] = 1'b0;  // s_cmoresp
    end
    if (fromB_s3) begin
      alloc_state[4] = 1'b0;                   // s_probeack
      if (need_pprobe_s3_b) begin
        alloc_state[2] = 1'b0;                 // s_pprobe
        alloc_state[9]  = 1'b0;                // w_pprobeackfirst
        alloc_state[10] = 1'b0;                // w_pprobeacklast
      end
      if (need_dct_s3_b) alloc_state[17] = 1'b0;  // s_dct
    end
  end
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_acquire = alloc_state[0];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rprobe = alloc_state[1];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_pprobe = alloc_state[2];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_release = alloc_state[3];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_probeack = alloc_state[4];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_refill = alloc_state[5];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_cmoresp = alloc_state[6];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeackfirst = alloc_state[7];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_rprobeacklast = alloc_state[8];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeackfirst = alloc_state[9];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_pprobeacklast = alloc_state[10];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantfirst = alloc_state[11];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grantlast = alloc_state[12];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_grant = alloc_state[13];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_releaseack = alloc_state[14];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_w_replResp = alloc_state[15];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_rcompack = alloc_state[16];
  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_s_dct = alloc_state[17];
  // task = req_s3, 仅 aliasTask 取 cache_alias
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_channel = task_s3_bits_channel;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_set = task_s3_bits_set;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_tag = task_s3_bits_tag;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_off = task_s3_bits_off;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_alias = task_s3_bits_alias;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_isKeyword = task_s3_bits_isKeyword;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_opcode = task_s3_bits_opcode;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_param = task_s3_bits_param;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_sourceId = task_s3_bits_sourceId;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_aliasTask = cache_alias;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fromL2pft = task_s3_bits_fromL2pft;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_reqSource = task_s3_bits_reqSource;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitRelease = task_s3_bits_snpHitRelease;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToInval = task_s3_bits_snpHitReleaseToInval;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseToClean = task_s3_bits_snpHitReleaseToClean;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseWithData = task_s3_bits_snpHitReleaseWithData;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseIdx = task_s3_bits_snpHitReleaseIdx;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty = task_s3_bits_snpHitReleaseMeta_dirty;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state = task_s3_bits_snpHitReleaseMeta_state;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients = task_s3_bits_snpHitReleaseMeta_clients;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias = task_s3_bits_snpHitReleaseMeta_alias;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch = task_s3_bits_snpHitReleaseMeta_prefetch;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc = task_s3_bits_snpHitReleaseMeta_prefetchSrc;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed = task_s3_bits_snpHitReleaseMeta_accessed;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr = task_s3_bits_snpHitReleaseMeta_tagErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr = task_s3_bits_snpHitReleaseMeta_dataErr;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_srcID = task_s3_bits_srcID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_txnID = task_s3_bits_txnID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdNID = task_s3_bits_fwdNID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_fwdTxnID = task_s3_bits_fwdTxnID;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_chiOpcode = task_s3_bits_chiOpcode;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_retToSrc = task_s3_bits_retToSrc;
  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_traceTag = task_s3_bits_traceTag;

  // ===== 预取训练(命中预取块/带 needHint 的缺失/aMerge 触发) =====
  assign io_prefetchTrain_valid = task_s3_valid & (
       ((req_acquire_s3 | req_get_s3) & task_s3_bits_needHint & (~dh | io_dirResp_s3_meta_prefetch)) |
       task_s3_bits_mergeA);
  assign io_prefetchTrain_bits_tag = {2'h0, task_s3_bits_tag};
  assign io_prefetchTrain_bits_set = task_s3_bits_set;
  assign io_prefetchTrain_bits_needT = task_s3_bits_mergeA ?
       f_needT({1'b0, task_s3_bits_aMergeTask_opcode}, task_s3_bits_aMergeTask_param) : req_needT_s3;
  assign io_prefetchTrain_bits_source = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_sourceId : task_s3_bits_sourceId;
  assign io_prefetchTrain_bits_vaddr  = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_vaddr : task_s3_bits_vaddr;
  assign io_prefetchTrain_bits_hit        = task_s3_bits_mergeA ? 1'b1 : dh;
  assign io_prefetchTrain_bits_prefetched = task_s3_bits_mergeA ? 1'b1 : io_dirResp_s3_meta_prefetch;
  assign io_prefetchTrain_bits_pfsource   = io_dirResp_s3_meta_prefetchSrc;
  assign io_prefetchTrain_bits_reqsource  = task_s3_bits_reqSource;

  // ===== 喂 CustomL1Hint 的 s3 信号 =====
  assign hint_s3_task_valid        = task_s3_valid;
  assign hint_s3_task_bits_channel = task_s3_bits_channel;
  assign hint_s3_task_bits_isKeyword = task_s3_bits_isKeyword;
  assign hint_s3_task_bits_opcode  = sink_resp_s3_valid ? sink_resp_s3_bits_opcode : task_s3_bits_opcode;
  assign hint_s3_task_bits_sourceId = task_s3_bits_sourceId;
  assign hint_s3_task_bits_mshrTask = task_s3_bits_mshrTask;
  assign hint_s3_need_mshr         = need_mshr_s3;

  // ===== Stage 5: 收 DS 读数据, 发 releaseBufWrite, 出 error =====
  wire [511:0] rdata_s5 = io_toDS_rdata_s5_data;
  wire dataError_s5 = io_toDS_error_s5 | dataMetaError_s5;
  wire l2Error_s5   = l2TagError_s5 | io_toDS_error_s5;
  wire [511:0] out_data_s5 = (task_s5_bits_mshrTask | task_s5_bits_snpHitReleaseWithData) ? data_s5 : rdata_s5;
  wire chnl_valid_s5 = task_s5_valid & ~chnl_valid_s5_REG & ~chnl_fire_s3_d2;
  assign io_releaseBufWrite_valid = task_s5_valid & need_write_releaseBuf_s5;
  assign io_releaseBufWrite_bits_id = task_s5_bits_mshrId;
  assign io_releaseBufWrite_bits_data_data = rdata_s5;

  // s4/s5 通道有效门控(RegNext(chnl_fire) 防同任务多次发)
  wire chnl_valid_s4 = task_s4_valid & ~chnl_valid_s4_REG;
  // ===== 各通道 s3 派发判定(D=SourceD, TXREQ/RSP/DAT=CHI) =====
  // d_s3_latch/txdat_s3_latch=true: 非 mshr 的 A-D / B-DAT 响应推后一拍到 s4
  wire isD_s3 = mshr_req_s3 ? (mshr_cmoresp_s3 | (mshr_refill_s3 & ~retry)) :
       (fromC_s3 | (fromA_s3 & ~need_mshr_s3_a & ~data_unready_s3_tl & task_s3_bits_opcode!=4'd5));
  wire isD_s3_ready = mshr_req_s3 ? (mshr_cmoresp_s3 | (mshr_refill_s3 & ~retry)) : fromC_s3;
  wire isTXREQ_s3 = mshr_req_s3 & (mshr_writeBackFull_s3 | mshr_writeCleanFull_s3 |
                    mshr_writeEvictFull_s3 | mshr_writeEvictOrEvict_s3 | mshr_evict_s3);
  wire isTXRSP_s3 = mshr_req_s3 ? mshr_snpRespX_s3 : (fromB_s3 & ~need_mshr_s3 & ~hasData_s3);
  wire isTXDAT_s3 = mshr_req_s3 ? (mshr_snpRespDataX_s3 | mshr_cbWrData_s3 | mshr_dct_s3) :
       (fromB_s3 & ~need_mshr_s3 & doRespData &
        (~data_unready_s3 | (snpHitRel & task_s3_bits_snpHitReleaseWithData)));
  wire isTXDAT_s3_ready = mshr_req_s3 ? (mshr_snpRespDataX_s3 | mshr_cbWrData_s3 | mshr_dct_s3) : 1'b0;

  // 各级各通道 valid
  wire d_s3_valid     = task_s3_valid & isD_s3_ready;
  wire txreq_s3_valid = task_s3_valid & isTXREQ_s3;
  wire txrsp_s3_valid = task_s3_valid & isTXRSP_s3;
  wire txdat_s3_valid = task_s3_valid & isTXDAT_s3_ready;
  wire d_s4_valid     = chnl_valid_s4 & isD_s4;
  wire txreq_s4_valid = chnl_valid_s4 & isTXREQ_s4;
  wire txrsp_s4_valid = chnl_valid_s4 & isTXRSP_s4;
  wire txdat_s4_valid = chnl_valid_s4 & isTXDAT_s4;
  wire d_s5_valid     = chnl_valid_s5 & isD_s5;
  wire txreq_s5_valid = chnl_valid_s5 & isTXREQ_s5;
  wire txrsp_s5_valid = chnl_valid_s5 & isTXRSP_s5;
  wire txdat_s5_valid = chnl_valid_s5 & isTXDAT_s5;

  // 优先 Arbiter: in0=s5 最高 > s4 > s3。D/REQ/RSP 下游恒 ready=1; DAT=io_toTXDAT_ready
  wire d_s5_fire = d_s5_valid;
  wire d_s4_fire = d_s4_valid & ~d_s5_valid;
  wire d_s3_fire = d_s3_valid & ~d_s5_valid & ~d_s4_valid;
  wire txreq_s5_fire = txreq_s5_valid;
  wire txreq_s4_fire = txreq_s4_valid & ~txreq_s5_valid;
  wire txreq_s3_fire = txreq_s3_valid & ~txreq_s5_valid & ~txreq_s4_valid;
  wire txrsp_s5_fire = txrsp_s5_valid;
  wire txrsp_s4_fire = txrsp_s4_valid & ~txrsp_s5_valid;
  wire txrsp_s3_fire = txrsp_s3_valid & ~txrsp_s5_valid & ~txrsp_s4_valid;
  wire txdat_s5_fire = txdat_s5_valid & io_toTXDAT_ready;
  wire txdat_s4_fire = txdat_s4_valid & io_toTXDAT_ready & ~txdat_s5_valid;
  wire txdat_s3_fire = txdat_s3_valid & io_toTXDAT_ready & ~txdat_s5_valid & ~txdat_s4_valid;
  wire chnl_fire_s3 = d_s3_fire | txreq_s3_fire | txrsp_s3_fire | txdat_s3_fire;
  wire chnl_fire_s4 = d_s4_fire | txreq_s4_fire | txrsp_s4_fire | txdat_s4_fire;

  // Arbiter 输出 valid
  assign io_toSourceD_valid = d_s5_valid | d_s4_valid | d_s3_valid;
  assign io_toTXREQ_valid   = txreq_s5_valid | txreq_s4_valid | txreq_s3_valid;
  assign io_toTXRSP_valid   = txrsp_s5_valid | txrsp_s4_valid | txrsp_s3_valid;
  assign io_toTXDAT_valid   = txdat_s5_valid | txdat_s4_valid | txdat_s3_valid;

  // s5 task 视图的 denied/corrupt 覆盖(SourceD 与 TXDAT 略不同)
  task_bundle_t s5_sd, s5_txdat;
  always_comb begin
    s5_sd = task_s5_v;
    s5_sd.denied  = (task_s5_bits_mshrTask | task_s5_bits_snpHitReleaseWithData) ? task_s5_bits_denied  : tagError_s5;
    s5_sd.corrupt = (task_s5_bits_mshrTask | task_s5_bits_snpHitReleaseWithData) ? task_s5_bits_corrupt : dataError_s5;
    s5_txdat = task_s5_v;
    s5_txdat.denied  = tagError_s5;
    s5_txdat.corrupt = task_s5_bits_corrupt | dataError_s5;
  end

  // ----- SourceD (TaskWithData): 优先选 s5>s4>s3, 全字段 -----
  assign io_toSourceD_bits_task_channel = d_s5_valid ? s5_sd.channel : d_s4_valid ? task_s4_v.channel : source_req_s3.channel;
  assign io_toSourceD_bits_task_txChannel = d_s5_valid ? s5_sd.txChannel : d_s4_valid ? task_s4_v.txChannel : source_req_s3.txChannel;
  assign io_toSourceD_bits_task_set = d_s5_valid ? s5_sd.set : d_s4_valid ? task_s4_v.set : source_req_s3.set;
  assign io_toSourceD_bits_task_tag = d_s5_valid ? s5_sd.tag : d_s4_valid ? task_s4_v.tag : source_req_s3.tag;
  assign io_toSourceD_bits_task_off = d_s5_valid ? s5_sd.off : d_s4_valid ? task_s4_v.off : source_req_s3.off;
  assign io_toSourceD_bits_task_alias = d_s5_valid ? s5_sd.alias_ : d_s4_valid ? task_s4_v.alias_ : source_req_s3.alias_;
  assign io_toSourceD_bits_task_vaddr = d_s5_valid ? s5_sd.vaddr : d_s4_valid ? task_s4_v.vaddr : source_req_s3.vaddr;
  assign io_toSourceD_bits_task_isKeyword = d_s5_valid ? s5_sd.isKeyword : d_s4_valid ? task_s4_v.isKeyword : source_req_s3.isKeyword;
  assign io_toSourceD_bits_task_opcode = d_s5_valid ? s5_sd.opcode : d_s4_valid ? task_s4_v.opcode : source_req_s3.opcode;
  assign io_toSourceD_bits_task_param = d_s5_valid ? s5_sd.param : d_s4_valid ? task_s4_v.param : source_req_s3.param;
  assign io_toSourceD_bits_task_size = d_s5_valid ? s5_sd.size : d_s4_valid ? task_s4_v.size : source_req_s3.size;
  assign io_toSourceD_bits_task_sourceId = d_s5_valid ? s5_sd.sourceId : d_s4_valid ? task_s4_v.sourceId : source_req_s3.sourceId;
  assign io_toSourceD_bits_task_bufIdx = d_s5_valid ? s5_sd.bufIdx : d_s4_valid ? task_s4_v.bufIdx : source_req_s3.bufIdx;
  assign io_toSourceD_bits_task_needProbeAckData = d_s5_valid ? s5_sd.needProbeAckData : d_s4_valid ? task_s4_v.needProbeAckData : source_req_s3.needProbeAckData;
  assign io_toSourceD_bits_task_denied = d_s5_valid ? s5_sd.denied : d_s4_valid ? task_s4_v.denied : source_req_s3.denied;
  assign io_toSourceD_bits_task_corrupt = d_s5_valid ? s5_sd.corrupt : d_s4_valid ? task_s4_v.corrupt : source_req_s3.corrupt;
  assign io_toSourceD_bits_task_mshrTask = d_s5_valid ? s5_sd.mshrTask : d_s4_valid ? task_s4_v.mshrTask : source_req_s3.mshrTask;
  assign io_toSourceD_bits_task_mshrId = d_s5_valid ? s5_sd.mshrId : d_s4_valid ? task_s4_v.mshrId : source_req_s3.mshrId;
  assign io_toSourceD_bits_task_aliasTask = d_s5_valid ? s5_sd.aliasTask : d_s4_valid ? task_s4_v.aliasTask : source_req_s3.aliasTask;
  assign io_toSourceD_bits_task_useProbeData = d_s5_valid ? s5_sd.useProbeData : d_s4_valid ? task_s4_v.useProbeData : source_req_s3.useProbeData;
  assign io_toSourceD_bits_task_mshrRetry = d_s5_valid ? s5_sd.mshrRetry : d_s4_valid ? task_s4_v.mshrRetry : source_req_s3.mshrRetry;
  assign io_toSourceD_bits_task_readProbeDataDown = d_s5_valid ? s5_sd.readProbeDataDown : d_s4_valid ? task_s4_v.readProbeDataDown : source_req_s3.readProbeDataDown;
  assign io_toSourceD_bits_task_fromL2pft = d_s5_valid ? s5_sd.fromL2pft : d_s4_valid ? task_s4_v.fromL2pft : source_req_s3.fromL2pft;
  assign io_toSourceD_bits_task_needHint = d_s5_valid ? s5_sd.needHint : d_s4_valid ? task_s4_v.needHint : source_req_s3.needHint;
  assign io_toSourceD_bits_task_dirty = d_s5_valid ? s5_sd.dirty : d_s4_valid ? task_s4_v.dirty : source_req_s3.dirty;
  assign io_toSourceD_bits_task_way = d_s5_valid ? s5_sd.way : d_s4_valid ? task_s4_v.way : source_req_s3.way;
  assign io_toSourceD_bits_task_meta_dirty = d_s5_valid ? s5_sd.meta_dirty : d_s4_valid ? task_s4_v.meta_dirty : source_req_s3.meta_dirty;
  assign io_toSourceD_bits_task_meta_state = d_s5_valid ? s5_sd.meta_state : d_s4_valid ? task_s4_v.meta_state : source_req_s3.meta_state;
  assign io_toSourceD_bits_task_meta_clients = d_s5_valid ? s5_sd.meta_clients : d_s4_valid ? task_s4_v.meta_clients : source_req_s3.meta_clients;
  assign io_toSourceD_bits_task_meta_alias = d_s5_valid ? s5_sd.meta_alias : d_s4_valid ? task_s4_v.meta_alias : source_req_s3.meta_alias;
  assign io_toSourceD_bits_task_meta_prefetch = d_s5_valid ? s5_sd.meta_prefetch : d_s4_valid ? task_s4_v.meta_prefetch : source_req_s3.meta_prefetch;
  assign io_toSourceD_bits_task_meta_prefetchSrc = d_s5_valid ? s5_sd.meta_prefetchSrc : d_s4_valid ? task_s4_v.meta_prefetchSrc : source_req_s3.meta_prefetchSrc;
  assign io_toSourceD_bits_task_meta_accessed = d_s5_valid ? s5_sd.meta_accessed : d_s4_valid ? task_s4_v.meta_accessed : source_req_s3.meta_accessed;
  assign io_toSourceD_bits_task_meta_tagErr = d_s5_valid ? s5_sd.meta_tagErr : d_s4_valid ? task_s4_v.meta_tagErr : source_req_s3.meta_tagErr;
  assign io_toSourceD_bits_task_meta_dataErr = d_s5_valid ? s5_sd.meta_dataErr : d_s4_valid ? task_s4_v.meta_dataErr : source_req_s3.meta_dataErr;
  assign io_toSourceD_bits_task_metaWen = d_s5_valid ? s5_sd.metaWen : d_s4_valid ? task_s4_v.metaWen : source_req_s3.metaWen;
  assign io_toSourceD_bits_task_tagWen = d_s5_valid ? s5_sd.tagWen : d_s4_valid ? task_s4_v.tagWen : source_req_s3.tagWen;
  assign io_toSourceD_bits_task_dsWen = d_s5_valid ? s5_sd.dsWen : d_s4_valid ? task_s4_v.dsWen : source_req_s3.dsWen;
  assign io_toSourceD_bits_task_wayMask = d_s5_valid ? s5_sd.wayMask : d_s4_valid ? task_s4_v.wayMask : source_req_s3.wayMask;
  assign io_toSourceD_bits_task_replTask = d_s5_valid ? s5_sd.replTask : d_s4_valid ? task_s4_v.replTask : source_req_s3.replTask;
  assign io_toSourceD_bits_task_cmoTask = d_s5_valid ? s5_sd.cmoTask : d_s4_valid ? task_s4_v.cmoTask : source_req_s3.cmoTask;
  assign io_toSourceD_bits_task_cmoAll = d_s5_valid ? s5_sd.cmoAll : d_s4_valid ? task_s4_v.cmoAll : source_req_s3.cmoAll;
  assign io_toSourceD_bits_task_reqSource = d_s5_valid ? s5_sd.reqSource : d_s4_valid ? task_s4_v.reqSource : source_req_s3.reqSource;
  assign io_toSourceD_bits_task_mergeA = d_s5_valid ? s5_sd.mergeA : d_s4_valid ? task_s4_v.mergeA : source_req_s3.mergeA;
  assign io_toSourceD_bits_task_aMergeTask_off = d_s5_valid ? s5_sd.aMergeTask_off : d_s4_valid ? task_s4_v.aMergeTask_off : source_req_s3.aMergeTask_off;
  assign io_toSourceD_bits_task_aMergeTask_alias = d_s5_valid ? s5_sd.aMergeTask_alias : d_s4_valid ? task_s4_v.aMergeTask_alias : source_req_s3.aMergeTask_alias;
  assign io_toSourceD_bits_task_aMergeTask_vaddr = d_s5_valid ? s5_sd.aMergeTask_vaddr : d_s4_valid ? task_s4_v.aMergeTask_vaddr : source_req_s3.aMergeTask_vaddr;
  assign io_toSourceD_bits_task_aMergeTask_isKeyword = d_s5_valid ? s5_sd.aMergeTask_isKeyword : d_s4_valid ? task_s4_v.aMergeTask_isKeyword : source_req_s3.aMergeTask_isKeyword;
  assign io_toSourceD_bits_task_aMergeTask_opcode = d_s5_valid ? s5_sd.aMergeTask_opcode : d_s4_valid ? task_s4_v.aMergeTask_opcode : source_req_s3.aMergeTask_opcode;
  assign io_toSourceD_bits_task_aMergeTask_param = d_s5_valid ? s5_sd.aMergeTask_param : d_s4_valid ? task_s4_v.aMergeTask_param : source_req_s3.aMergeTask_param;
  assign io_toSourceD_bits_task_aMergeTask_sourceId = d_s5_valid ? s5_sd.aMergeTask_sourceId : d_s4_valid ? task_s4_v.aMergeTask_sourceId : source_req_s3.aMergeTask_sourceId;
  assign io_toSourceD_bits_task_aMergeTask_meta_dirty = d_s5_valid ? s5_sd.aMergeTask_meta_dirty : d_s4_valid ? task_s4_v.aMergeTask_meta_dirty : source_req_s3.aMergeTask_meta_dirty;
  assign io_toSourceD_bits_task_aMergeTask_meta_state = d_s5_valid ? s5_sd.aMergeTask_meta_state : d_s4_valid ? task_s4_v.aMergeTask_meta_state : source_req_s3.aMergeTask_meta_state;
  assign io_toSourceD_bits_task_aMergeTask_meta_clients = d_s5_valid ? s5_sd.aMergeTask_meta_clients : d_s4_valid ? task_s4_v.aMergeTask_meta_clients : source_req_s3.aMergeTask_meta_clients;
  assign io_toSourceD_bits_task_aMergeTask_meta_alias = d_s5_valid ? s5_sd.aMergeTask_meta_alias : d_s4_valid ? task_s4_v.aMergeTask_meta_alias : source_req_s3.aMergeTask_meta_alias;
  assign io_toSourceD_bits_task_aMergeTask_meta_prefetch = d_s5_valid ? s5_sd.aMergeTask_meta_prefetch : d_s4_valid ? task_s4_v.aMergeTask_meta_prefetch : source_req_s3.aMergeTask_meta_prefetch;
  assign io_toSourceD_bits_task_aMergeTask_meta_prefetchSrc = d_s5_valid ? s5_sd.aMergeTask_meta_prefetchSrc : d_s4_valid ? task_s4_v.aMergeTask_meta_prefetchSrc : source_req_s3.aMergeTask_meta_prefetchSrc;
  assign io_toSourceD_bits_task_aMergeTask_meta_accessed = d_s5_valid ? s5_sd.aMergeTask_meta_accessed : d_s4_valid ? task_s4_v.aMergeTask_meta_accessed : source_req_s3.aMergeTask_meta_accessed;
  assign io_toSourceD_bits_task_aMergeTask_meta_tagErr = d_s5_valid ? s5_sd.aMergeTask_meta_tagErr : d_s4_valid ? task_s4_v.aMergeTask_meta_tagErr : source_req_s3.aMergeTask_meta_tagErr;
  assign io_toSourceD_bits_task_aMergeTask_meta_dataErr = d_s5_valid ? s5_sd.aMergeTask_meta_dataErr : d_s4_valid ? task_s4_v.aMergeTask_meta_dataErr : source_req_s3.aMergeTask_meta_dataErr;
  assign io_toSourceD_bits_task_snpHitRelease = d_s5_valid ? s5_sd.snpHitRelease : d_s4_valid ? task_s4_v.snpHitRelease : source_req_s3.snpHitRelease;
  assign io_toSourceD_bits_task_snpHitReleaseToInval = d_s5_valid ? s5_sd.snpHitReleaseToInval : d_s4_valid ? task_s4_v.snpHitReleaseToInval : source_req_s3.snpHitReleaseToInval;
  assign io_toSourceD_bits_task_snpHitReleaseToClean = d_s5_valid ? s5_sd.snpHitReleaseToClean : d_s4_valid ? task_s4_v.snpHitReleaseToClean : source_req_s3.snpHitReleaseToClean;
  assign io_toSourceD_bits_task_snpHitReleaseWithData = d_s5_valid ? s5_sd.snpHitReleaseWithData : d_s4_valid ? task_s4_v.snpHitReleaseWithData : source_req_s3.snpHitReleaseWithData;
  assign io_toSourceD_bits_task_snpHitReleaseIdx = d_s5_valid ? s5_sd.snpHitReleaseIdx : d_s4_valid ? task_s4_v.snpHitReleaseIdx : source_req_s3.snpHitReleaseIdx;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_dirty = d_s5_valid ? s5_sd.snpHitReleaseMeta_dirty : d_s4_valid ? task_s4_v.snpHitReleaseMeta_dirty : source_req_s3.snpHitReleaseMeta_dirty;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_state = d_s5_valid ? s5_sd.snpHitReleaseMeta_state : d_s4_valid ? task_s4_v.snpHitReleaseMeta_state : source_req_s3.snpHitReleaseMeta_state;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_clients = d_s5_valid ? s5_sd.snpHitReleaseMeta_clients : d_s4_valid ? task_s4_v.snpHitReleaseMeta_clients : source_req_s3.snpHitReleaseMeta_clients;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_alias = d_s5_valid ? s5_sd.snpHitReleaseMeta_alias : d_s4_valid ? task_s4_v.snpHitReleaseMeta_alias : source_req_s3.snpHitReleaseMeta_alias;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_prefetch = d_s5_valid ? s5_sd.snpHitReleaseMeta_prefetch : d_s4_valid ? task_s4_v.snpHitReleaseMeta_prefetch : source_req_s3.snpHitReleaseMeta_prefetch;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_prefetchSrc = d_s5_valid ? s5_sd.snpHitReleaseMeta_prefetchSrc : d_s4_valid ? task_s4_v.snpHitReleaseMeta_prefetchSrc : source_req_s3.snpHitReleaseMeta_prefetchSrc;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_accessed = d_s5_valid ? s5_sd.snpHitReleaseMeta_accessed : d_s4_valid ? task_s4_v.snpHitReleaseMeta_accessed : source_req_s3.snpHitReleaseMeta_accessed;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_tagErr = d_s5_valid ? s5_sd.snpHitReleaseMeta_tagErr : d_s4_valid ? task_s4_v.snpHitReleaseMeta_tagErr : source_req_s3.snpHitReleaseMeta_tagErr;
  assign io_toSourceD_bits_task_snpHitReleaseMeta_dataErr = d_s5_valid ? s5_sd.snpHitReleaseMeta_dataErr : d_s4_valid ? task_s4_v.snpHitReleaseMeta_dataErr : source_req_s3.snpHitReleaseMeta_dataErr;
  assign io_toSourceD_bits_task_tgtID = d_s5_valid ? s5_sd.tgtID : d_s4_valid ? task_s4_v.tgtID : source_req_s3.tgtID;
  assign io_toSourceD_bits_task_srcID = d_s5_valid ? s5_sd.srcID : d_s4_valid ? task_s4_v.srcID : source_req_s3.srcID;
  assign io_toSourceD_bits_task_txnID = d_s5_valid ? s5_sd.txnID : d_s4_valid ? task_s4_v.txnID : source_req_s3.txnID;
  assign io_toSourceD_bits_task_homeNID = d_s5_valid ? s5_sd.homeNID : d_s4_valid ? task_s4_v.homeNID : source_req_s3.homeNID;
  assign io_toSourceD_bits_task_dbID = d_s5_valid ? s5_sd.dbID : d_s4_valid ? task_s4_v.dbID : source_req_s3.dbID;
  assign io_toSourceD_bits_task_fwdNID = d_s5_valid ? s5_sd.fwdNID : d_s4_valid ? task_s4_v.fwdNID : source_req_s3.fwdNID;
  assign io_toSourceD_bits_task_fwdTxnID = d_s5_valid ? s5_sd.fwdTxnID : d_s4_valid ? task_s4_v.fwdTxnID : source_req_s3.fwdTxnID;
  assign io_toSourceD_bits_task_chiOpcode = d_s5_valid ? s5_sd.chiOpcode : d_s4_valid ? task_s4_v.chiOpcode : source_req_s3.chiOpcode;
  assign io_toSourceD_bits_task_resp = d_s5_valid ? s5_sd.resp : d_s4_valid ? task_s4_v.resp : source_req_s3.resp;
  assign io_toSourceD_bits_task_fwdState = d_s5_valid ? s5_sd.fwdState : d_s4_valid ? task_s4_v.fwdState : source_req_s3.fwdState;
  assign io_toSourceD_bits_task_pCrdType = d_s5_valid ? s5_sd.pCrdType : d_s4_valid ? task_s4_v.pCrdType : source_req_s3.pCrdType;
  assign io_toSourceD_bits_task_retToSrc = d_s5_valid ? s5_sd.retToSrc : d_s4_valid ? task_s4_v.retToSrc : source_req_s3.retToSrc;
  assign io_toSourceD_bits_task_likelyshared = d_s5_valid ? s5_sd.likelyshared : d_s4_valid ? task_s4_v.likelyshared : source_req_s3.likelyshared;
  assign io_toSourceD_bits_task_expCompAck = d_s5_valid ? s5_sd.expCompAck : d_s4_valid ? task_s4_v.expCompAck : source_req_s3.expCompAck;
  assign io_toSourceD_bits_task_allowRetry = d_s5_valid ? s5_sd.allowRetry : d_s4_valid ? task_s4_v.allowRetry : source_req_s3.allowRetry;
  assign io_toSourceD_bits_task_memAttr_allocate = d_s5_valid ? s5_sd.memAttr_allocate : d_s4_valid ? task_s4_v.memAttr_allocate : source_req_s3.memAttr_allocate;
  assign io_toSourceD_bits_task_memAttr_cacheable = d_s5_valid ? s5_sd.memAttr_cacheable : d_s4_valid ? task_s4_v.memAttr_cacheable : source_req_s3.memAttr_cacheable;
  assign io_toSourceD_bits_task_memAttr_device = d_s5_valid ? s5_sd.memAttr_device : d_s4_valid ? task_s4_v.memAttr_device : source_req_s3.memAttr_device;
  assign io_toSourceD_bits_task_memAttr_ewa = d_s5_valid ? s5_sd.memAttr_ewa : d_s4_valid ? task_s4_v.memAttr_ewa : source_req_s3.memAttr_ewa;
  assign io_toSourceD_bits_task_traceTag = d_s5_valid ? s5_sd.traceTag : d_s4_valid ? task_s4_v.traceTag : source_req_s3.traceTag;
  assign io_toSourceD_bits_task_dataCheckErr = d_s5_valid ? s5_sd.dataCheckErr : d_s4_valid ? task_s4_v.dataCheckErr : source_req_s3.dataCheckErr;
  assign io_toSourceD_bits_data_data = d_s5_valid ? out_data_s5 : d_s4_valid ? data_s4 : data_s3;

  // ----- TXDAT (TaskWithData) -----
  assign io_toTXDAT_bits_task_channel = txdat_s5_valid ? s5_txdat.channel : txdat_s4_valid ? task_s4_v.channel : source_req_s3.channel;
  assign io_toTXDAT_bits_task_txChannel = txdat_s5_valid ? s5_txdat.txChannel : txdat_s4_valid ? task_s4_v.txChannel : source_req_s3.txChannel;
  assign io_toTXDAT_bits_task_set = txdat_s5_valid ? s5_txdat.set : txdat_s4_valid ? task_s4_v.set : source_req_s3.set;
  assign io_toTXDAT_bits_task_tag = txdat_s5_valid ? s5_txdat.tag : txdat_s4_valid ? task_s4_v.tag : source_req_s3.tag;
  assign io_toTXDAT_bits_task_off = txdat_s5_valid ? s5_txdat.off : txdat_s4_valid ? task_s4_v.off : source_req_s3.off;
  assign io_toTXDAT_bits_task_alias = txdat_s5_valid ? s5_txdat.alias_ : txdat_s4_valid ? task_s4_v.alias_ : source_req_s3.alias_;
  assign io_toTXDAT_bits_task_vaddr = txdat_s5_valid ? s5_txdat.vaddr : txdat_s4_valid ? task_s4_v.vaddr : source_req_s3.vaddr;
  assign io_toTXDAT_bits_task_isKeyword = txdat_s5_valid ? s5_txdat.isKeyword : txdat_s4_valid ? task_s4_v.isKeyword : source_req_s3.isKeyword;
  assign io_toTXDAT_bits_task_opcode = txdat_s5_valid ? s5_txdat.opcode : txdat_s4_valid ? task_s4_v.opcode : source_req_s3.opcode;
  assign io_toTXDAT_bits_task_param = txdat_s5_valid ? s5_txdat.param : txdat_s4_valid ? task_s4_v.param : source_req_s3.param;
  assign io_toTXDAT_bits_task_size = txdat_s5_valid ? s5_txdat.size : txdat_s4_valid ? task_s4_v.size : source_req_s3.size;
  assign io_toTXDAT_bits_task_sourceId = txdat_s5_valid ? s5_txdat.sourceId : txdat_s4_valid ? task_s4_v.sourceId : source_req_s3.sourceId;
  assign io_toTXDAT_bits_task_bufIdx = txdat_s5_valid ? s5_txdat.bufIdx : txdat_s4_valid ? task_s4_v.bufIdx : source_req_s3.bufIdx;
  assign io_toTXDAT_bits_task_needProbeAckData = txdat_s5_valid ? s5_txdat.needProbeAckData : txdat_s4_valid ? task_s4_v.needProbeAckData : source_req_s3.needProbeAckData;
  assign io_toTXDAT_bits_task_denied = txdat_s5_valid ? s5_txdat.denied : txdat_s4_valid ? task_s4_v.denied : source_req_s3.denied;
  assign io_toTXDAT_bits_task_corrupt = txdat_s5_valid ? s5_txdat.corrupt : txdat_s4_valid ? task_s4_v.corrupt : source_req_s3.corrupt;
  assign io_toTXDAT_bits_task_mshrTask = txdat_s5_valid ? s5_txdat.mshrTask : txdat_s4_valid ? task_s4_v.mshrTask : source_req_s3.mshrTask;
  assign io_toTXDAT_bits_task_mshrId = txdat_s5_valid ? s5_txdat.mshrId : txdat_s4_valid ? task_s4_v.mshrId : source_req_s3.mshrId;
  assign io_toTXDAT_bits_task_aliasTask = txdat_s5_valid ? s5_txdat.aliasTask : txdat_s4_valid ? task_s4_v.aliasTask : source_req_s3.aliasTask;
  assign io_toTXDAT_bits_task_useProbeData = txdat_s5_valid ? s5_txdat.useProbeData : txdat_s4_valid ? task_s4_v.useProbeData : source_req_s3.useProbeData;
  assign io_toTXDAT_bits_task_mshrRetry = txdat_s5_valid ? s5_txdat.mshrRetry : txdat_s4_valid ? task_s4_v.mshrRetry : source_req_s3.mshrRetry;
  assign io_toTXDAT_bits_task_readProbeDataDown = txdat_s5_valid ? s5_txdat.readProbeDataDown : txdat_s4_valid ? task_s4_v.readProbeDataDown : source_req_s3.readProbeDataDown;
  assign io_toTXDAT_bits_task_fromL2pft = txdat_s5_valid ? s5_txdat.fromL2pft : txdat_s4_valid ? task_s4_v.fromL2pft : source_req_s3.fromL2pft;
  assign io_toTXDAT_bits_task_needHint = txdat_s5_valid ? s5_txdat.needHint : txdat_s4_valid ? task_s4_v.needHint : source_req_s3.needHint;
  assign io_toTXDAT_bits_task_dirty = txdat_s5_valid ? s5_txdat.dirty : txdat_s4_valid ? task_s4_v.dirty : source_req_s3.dirty;
  assign io_toTXDAT_bits_task_way = txdat_s5_valid ? s5_txdat.way : txdat_s4_valid ? task_s4_v.way : source_req_s3.way;
  assign io_toTXDAT_bits_task_meta_dirty = txdat_s5_valid ? s5_txdat.meta_dirty : txdat_s4_valid ? task_s4_v.meta_dirty : source_req_s3.meta_dirty;
  assign io_toTXDAT_bits_task_meta_state = txdat_s5_valid ? s5_txdat.meta_state : txdat_s4_valid ? task_s4_v.meta_state : source_req_s3.meta_state;
  assign io_toTXDAT_bits_task_meta_clients = txdat_s5_valid ? s5_txdat.meta_clients : txdat_s4_valid ? task_s4_v.meta_clients : source_req_s3.meta_clients;
  assign io_toTXDAT_bits_task_meta_alias = txdat_s5_valid ? s5_txdat.meta_alias : txdat_s4_valid ? task_s4_v.meta_alias : source_req_s3.meta_alias;
  assign io_toTXDAT_bits_task_meta_prefetch = txdat_s5_valid ? s5_txdat.meta_prefetch : txdat_s4_valid ? task_s4_v.meta_prefetch : source_req_s3.meta_prefetch;
  assign io_toTXDAT_bits_task_meta_prefetchSrc = txdat_s5_valid ? s5_txdat.meta_prefetchSrc : txdat_s4_valid ? task_s4_v.meta_prefetchSrc : source_req_s3.meta_prefetchSrc;
  assign io_toTXDAT_bits_task_meta_accessed = txdat_s5_valid ? s5_txdat.meta_accessed : txdat_s4_valid ? task_s4_v.meta_accessed : source_req_s3.meta_accessed;
  assign io_toTXDAT_bits_task_meta_tagErr = txdat_s5_valid ? s5_txdat.meta_tagErr : txdat_s4_valid ? task_s4_v.meta_tagErr : source_req_s3.meta_tagErr;
  assign io_toTXDAT_bits_task_meta_dataErr = txdat_s5_valid ? s5_txdat.meta_dataErr : txdat_s4_valid ? task_s4_v.meta_dataErr : source_req_s3.meta_dataErr;
  assign io_toTXDAT_bits_task_metaWen = txdat_s5_valid ? s5_txdat.metaWen : txdat_s4_valid ? task_s4_v.metaWen : source_req_s3.metaWen;
  assign io_toTXDAT_bits_task_tagWen = txdat_s5_valid ? s5_txdat.tagWen : txdat_s4_valid ? task_s4_v.tagWen : source_req_s3.tagWen;
  assign io_toTXDAT_bits_task_dsWen = txdat_s5_valid ? s5_txdat.dsWen : txdat_s4_valid ? task_s4_v.dsWen : source_req_s3.dsWen;
  assign io_toTXDAT_bits_task_wayMask = txdat_s5_valid ? s5_txdat.wayMask : txdat_s4_valid ? task_s4_v.wayMask : source_req_s3.wayMask;
  assign io_toTXDAT_bits_task_replTask = txdat_s5_valid ? s5_txdat.replTask : txdat_s4_valid ? task_s4_v.replTask : source_req_s3.replTask;
  assign io_toTXDAT_bits_task_cmoTask = txdat_s5_valid ? s5_txdat.cmoTask : txdat_s4_valid ? task_s4_v.cmoTask : source_req_s3.cmoTask;
  assign io_toTXDAT_bits_task_cmoAll = txdat_s5_valid ? s5_txdat.cmoAll : txdat_s4_valid ? task_s4_v.cmoAll : source_req_s3.cmoAll;
  assign io_toTXDAT_bits_task_reqSource = txdat_s5_valid ? s5_txdat.reqSource : txdat_s4_valid ? task_s4_v.reqSource : source_req_s3.reqSource;
  assign io_toTXDAT_bits_task_mergeA = txdat_s5_valid ? s5_txdat.mergeA : txdat_s4_valid ? task_s4_v.mergeA : source_req_s3.mergeA;
  assign io_toTXDAT_bits_task_aMergeTask_off = txdat_s5_valid ? s5_txdat.aMergeTask_off : txdat_s4_valid ? task_s4_v.aMergeTask_off : source_req_s3.aMergeTask_off;
  assign io_toTXDAT_bits_task_aMergeTask_alias = txdat_s5_valid ? s5_txdat.aMergeTask_alias : txdat_s4_valid ? task_s4_v.aMergeTask_alias : source_req_s3.aMergeTask_alias;
  assign io_toTXDAT_bits_task_aMergeTask_vaddr = txdat_s5_valid ? s5_txdat.aMergeTask_vaddr : txdat_s4_valid ? task_s4_v.aMergeTask_vaddr : source_req_s3.aMergeTask_vaddr;
  assign io_toTXDAT_bits_task_aMergeTask_isKeyword = txdat_s5_valid ? s5_txdat.aMergeTask_isKeyword : txdat_s4_valid ? task_s4_v.aMergeTask_isKeyword : source_req_s3.aMergeTask_isKeyword;
  assign io_toTXDAT_bits_task_aMergeTask_opcode = txdat_s5_valid ? s5_txdat.aMergeTask_opcode : txdat_s4_valid ? task_s4_v.aMergeTask_opcode : source_req_s3.aMergeTask_opcode;
  assign io_toTXDAT_bits_task_aMergeTask_param = txdat_s5_valid ? s5_txdat.aMergeTask_param : txdat_s4_valid ? task_s4_v.aMergeTask_param : source_req_s3.aMergeTask_param;
  assign io_toTXDAT_bits_task_aMergeTask_sourceId = txdat_s5_valid ? s5_txdat.aMergeTask_sourceId : txdat_s4_valid ? task_s4_v.aMergeTask_sourceId : source_req_s3.aMergeTask_sourceId;
  assign io_toTXDAT_bits_task_aMergeTask_meta_dirty = txdat_s5_valid ? s5_txdat.aMergeTask_meta_dirty : txdat_s4_valid ? task_s4_v.aMergeTask_meta_dirty : source_req_s3.aMergeTask_meta_dirty;
  assign io_toTXDAT_bits_task_aMergeTask_meta_state = txdat_s5_valid ? s5_txdat.aMergeTask_meta_state : txdat_s4_valid ? task_s4_v.aMergeTask_meta_state : source_req_s3.aMergeTask_meta_state;
  assign io_toTXDAT_bits_task_aMergeTask_meta_clients = txdat_s5_valid ? s5_txdat.aMergeTask_meta_clients : txdat_s4_valid ? task_s4_v.aMergeTask_meta_clients : source_req_s3.aMergeTask_meta_clients;
  assign io_toTXDAT_bits_task_aMergeTask_meta_alias = txdat_s5_valid ? s5_txdat.aMergeTask_meta_alias : txdat_s4_valid ? task_s4_v.aMergeTask_meta_alias : source_req_s3.aMergeTask_meta_alias;
  assign io_toTXDAT_bits_task_aMergeTask_meta_prefetch = txdat_s5_valid ? s5_txdat.aMergeTask_meta_prefetch : txdat_s4_valid ? task_s4_v.aMergeTask_meta_prefetch : source_req_s3.aMergeTask_meta_prefetch;
  assign io_toTXDAT_bits_task_aMergeTask_meta_prefetchSrc = txdat_s5_valid ? s5_txdat.aMergeTask_meta_prefetchSrc : txdat_s4_valid ? task_s4_v.aMergeTask_meta_prefetchSrc : source_req_s3.aMergeTask_meta_prefetchSrc;
  assign io_toTXDAT_bits_task_aMergeTask_meta_accessed = txdat_s5_valid ? s5_txdat.aMergeTask_meta_accessed : txdat_s4_valid ? task_s4_v.aMergeTask_meta_accessed : source_req_s3.aMergeTask_meta_accessed;
  assign io_toTXDAT_bits_task_aMergeTask_meta_tagErr = txdat_s5_valid ? s5_txdat.aMergeTask_meta_tagErr : txdat_s4_valid ? task_s4_v.aMergeTask_meta_tagErr : source_req_s3.aMergeTask_meta_tagErr;
  assign io_toTXDAT_bits_task_aMergeTask_meta_dataErr = txdat_s5_valid ? s5_txdat.aMergeTask_meta_dataErr : txdat_s4_valid ? task_s4_v.aMergeTask_meta_dataErr : source_req_s3.aMergeTask_meta_dataErr;
  assign io_toTXDAT_bits_task_snpHitRelease = txdat_s5_valid ? s5_txdat.snpHitRelease : txdat_s4_valid ? task_s4_v.snpHitRelease : source_req_s3.snpHitRelease;
  assign io_toTXDAT_bits_task_snpHitReleaseToInval = txdat_s5_valid ? s5_txdat.snpHitReleaseToInval : txdat_s4_valid ? task_s4_v.snpHitReleaseToInval : source_req_s3.snpHitReleaseToInval;
  assign io_toTXDAT_bits_task_snpHitReleaseToClean = txdat_s5_valid ? s5_txdat.snpHitReleaseToClean : txdat_s4_valid ? task_s4_v.snpHitReleaseToClean : source_req_s3.snpHitReleaseToClean;
  assign io_toTXDAT_bits_task_snpHitReleaseWithData = txdat_s5_valid ? s5_txdat.snpHitReleaseWithData : txdat_s4_valid ? task_s4_v.snpHitReleaseWithData : source_req_s3.snpHitReleaseWithData;
  assign io_toTXDAT_bits_task_snpHitReleaseIdx = txdat_s5_valid ? s5_txdat.snpHitReleaseIdx : txdat_s4_valid ? task_s4_v.snpHitReleaseIdx : source_req_s3.snpHitReleaseIdx;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_dirty = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_dirty : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_dirty : source_req_s3.snpHitReleaseMeta_dirty;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_state = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_state : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_state : source_req_s3.snpHitReleaseMeta_state;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_clients = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_clients : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_clients : source_req_s3.snpHitReleaseMeta_clients;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_alias = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_alias : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_alias : source_req_s3.snpHitReleaseMeta_alias;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_prefetch = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_prefetch : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_prefetch : source_req_s3.snpHitReleaseMeta_prefetch;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_prefetchSrc = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_prefetchSrc : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_prefetchSrc : source_req_s3.snpHitReleaseMeta_prefetchSrc;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_accessed = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_accessed : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_accessed : source_req_s3.snpHitReleaseMeta_accessed;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_tagErr = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_tagErr : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_tagErr : source_req_s3.snpHitReleaseMeta_tagErr;
  assign io_toTXDAT_bits_task_snpHitReleaseMeta_dataErr = txdat_s5_valid ? s5_txdat.snpHitReleaseMeta_dataErr : txdat_s4_valid ? task_s4_v.snpHitReleaseMeta_dataErr : source_req_s3.snpHitReleaseMeta_dataErr;
  assign io_toTXDAT_bits_task_tgtID = txdat_s5_valid ? s5_txdat.tgtID : txdat_s4_valid ? task_s4_v.tgtID : source_req_s3.tgtID;
  assign io_toTXDAT_bits_task_srcID = txdat_s5_valid ? s5_txdat.srcID : txdat_s4_valid ? task_s4_v.srcID : source_req_s3.srcID;
  assign io_toTXDAT_bits_task_txnID = txdat_s5_valid ? s5_txdat.txnID : txdat_s4_valid ? task_s4_v.txnID : source_req_s3.txnID;
  assign io_toTXDAT_bits_task_homeNID = txdat_s5_valid ? s5_txdat.homeNID : txdat_s4_valid ? task_s4_v.homeNID : source_req_s3.homeNID;
  assign io_toTXDAT_bits_task_dbID = txdat_s5_valid ? s5_txdat.dbID : txdat_s4_valid ? task_s4_v.dbID : source_req_s3.dbID;
  assign io_toTXDAT_bits_task_fwdNID = txdat_s5_valid ? s5_txdat.fwdNID : txdat_s4_valid ? task_s4_v.fwdNID : source_req_s3.fwdNID;
  assign io_toTXDAT_bits_task_fwdTxnID = txdat_s5_valid ? s5_txdat.fwdTxnID : txdat_s4_valid ? task_s4_v.fwdTxnID : source_req_s3.fwdTxnID;
  assign io_toTXDAT_bits_task_chiOpcode = txdat_s5_valid ? s5_txdat.chiOpcode : txdat_s4_valid ? task_s4_v.chiOpcode : source_req_s3.chiOpcode;
  assign io_toTXDAT_bits_task_resp = txdat_s5_valid ? s5_txdat.resp : txdat_s4_valid ? task_s4_v.resp : source_req_s3.resp;
  assign io_toTXDAT_bits_task_fwdState = txdat_s5_valid ? s5_txdat.fwdState : txdat_s4_valid ? task_s4_v.fwdState : source_req_s3.fwdState;
  assign io_toTXDAT_bits_task_pCrdType = txdat_s5_valid ? s5_txdat.pCrdType : txdat_s4_valid ? task_s4_v.pCrdType : source_req_s3.pCrdType;
  assign io_toTXDAT_bits_task_retToSrc = txdat_s5_valid ? s5_txdat.retToSrc : txdat_s4_valid ? task_s4_v.retToSrc : source_req_s3.retToSrc;
  assign io_toTXDAT_bits_task_likelyshared = txdat_s5_valid ? s5_txdat.likelyshared : txdat_s4_valid ? task_s4_v.likelyshared : source_req_s3.likelyshared;
  assign io_toTXDAT_bits_task_expCompAck = txdat_s5_valid ? s5_txdat.expCompAck : txdat_s4_valid ? task_s4_v.expCompAck : source_req_s3.expCompAck;
  assign io_toTXDAT_bits_task_allowRetry = txdat_s5_valid ? s5_txdat.allowRetry : txdat_s4_valid ? task_s4_v.allowRetry : source_req_s3.allowRetry;
  assign io_toTXDAT_bits_task_memAttr_allocate = txdat_s5_valid ? s5_txdat.memAttr_allocate : txdat_s4_valid ? task_s4_v.memAttr_allocate : source_req_s3.memAttr_allocate;
  assign io_toTXDAT_bits_task_memAttr_cacheable = txdat_s5_valid ? s5_txdat.memAttr_cacheable : txdat_s4_valid ? task_s4_v.memAttr_cacheable : source_req_s3.memAttr_cacheable;
  assign io_toTXDAT_bits_task_memAttr_device = txdat_s5_valid ? s5_txdat.memAttr_device : txdat_s4_valid ? task_s4_v.memAttr_device : source_req_s3.memAttr_device;
  assign io_toTXDAT_bits_task_memAttr_ewa = txdat_s5_valid ? s5_txdat.memAttr_ewa : txdat_s4_valid ? task_s4_v.memAttr_ewa : source_req_s3.memAttr_ewa;
  assign io_toTXDAT_bits_task_traceTag = txdat_s5_valid ? s5_txdat.traceTag : txdat_s4_valid ? task_s4_v.traceTag : source_req_s3.traceTag;
  assign io_toTXDAT_bits_task_dataCheckErr = txdat_s5_valid ? s5_txdat.dataCheckErr : txdat_s4_valid ? task_s4_v.dataCheckErr : source_req_s3.dataCheckErr;
  assign io_toTXDAT_bits_data_data = txdat_s5_valid ? out_data_s5 : txdat_s4_valid ? data_s4 : data_s3;

  // ----- TXREQ (CHIREQ via toCHIREQBundle): addr={2'h0,tag,set,6'h0} -----
  assign io_toTXREQ_bits_tgtID = txreq_s5_valid ? task_s5_bits_tgtID : txreq_s4_valid ? task_s4_bits_tgtID : source_req_s3.tgtID;
  assign io_toTXREQ_bits_srcID = txreq_s5_valid ? task_s5_bits_srcID : txreq_s4_valid ? task_s4_bits_srcID : source_req_s3.srcID;
  assign io_toTXREQ_bits_txnID = txreq_s5_valid ? task_s5_bits_txnID : txreq_s4_valid ? task_s4_bits_txnID : source_req_s3.txnID;
  assign io_toTXREQ_bits_opcode = txreq_s5_valid ? task_s5_bits_chiOpcode : txreq_s4_valid ? task_s4_bits_chiOpcode : source_req_s3.chiOpcode;
  assign io_toTXREQ_bits_addr = txreq_s5_valid ? {2'h0, task_s5_bits_tag, task_s5_bits_set, 6'h0} : txreq_s4_valid ? {2'h0, task_s4_bits_tag, task_s4_bits_set, 6'h0} : {2'h0, source_req_s3.tag, source_req_s3.set, 6'h0};
  assign io_toTXREQ_bits_likelyshared = txreq_s5_valid ? task_s5_bits_likelyshared : txreq_s4_valid ? task_s4_bits_likelyshared : source_req_s3.likelyshared;
  assign io_toTXREQ_bits_allowRetry = txreq_s5_valid ? task_s5_bits_allowRetry : txreq_s4_valid ? task_s4_bits_allowRetry : source_req_s3.allowRetry;
  assign io_toTXREQ_bits_pCrdType = txreq_s5_valid ? task_s5_bits_pCrdType : txreq_s4_valid ? task_s4_bits_pCrdType : source_req_s3.pCrdType;
  assign io_toTXREQ_bits_memAttr_allocate = txreq_s5_valid ? task_s5_bits_memAttr_allocate : txreq_s4_valid ? task_s4_bits_memAttr_allocate : source_req_s3.memAttr_allocate;
  assign io_toTXREQ_bits_memAttr_cacheable = txreq_s5_valid ? task_s5_bits_memAttr_cacheable : txreq_s4_valid ? task_s4_bits_memAttr_cacheable : source_req_s3.memAttr_cacheable;
  assign io_toTXREQ_bits_memAttr_device = txreq_s5_valid ? task_s5_bits_memAttr_device : txreq_s4_valid ? task_s4_bits_memAttr_device : source_req_s3.memAttr_device;
  assign io_toTXREQ_bits_memAttr_ewa = txreq_s5_valid ? task_s5_bits_memAttr_ewa : txreq_s4_valid ? task_s4_bits_memAttr_ewa : source_req_s3.memAttr_ewa;
  assign io_toTXREQ_bits_expCompAck = txreq_s5_valid ? task_s5_bits_expCompAck : txreq_s4_valid ? task_s4_bits_expCompAck : source_req_s3.expCompAck;

  // ----- TXRSP (TaskBundle subset): s5 denied=tagError_s5 -----
  assign io_toTXRSP_bits_txChannel = txrsp_s5_valid ? task_s5_bits_txChannel : txrsp_s4_valid ? task_s4_bits_txChannel : source_req_s3.txChannel;
  assign io_toTXRSP_bits_denied = txrsp_s5_valid ? tagError_s5 : txrsp_s4_valid ? task_s4_bits_denied : source_req_s3.denied;
  assign io_toTXRSP_bits_tgtID = txrsp_s5_valid ? task_s5_bits_tgtID : txrsp_s4_valid ? task_s4_bits_tgtID : source_req_s3.tgtID;
  assign io_toTXRSP_bits_srcID = txrsp_s5_valid ? task_s5_bits_srcID : txrsp_s4_valid ? task_s4_bits_srcID : source_req_s3.srcID;
  assign io_toTXRSP_bits_txnID = txrsp_s5_valid ? task_s5_bits_txnID : txrsp_s4_valid ? task_s4_bits_txnID : source_req_s3.txnID;
  assign io_toTXRSP_bits_dbID = txrsp_s5_valid ? task_s5_bits_dbID : txrsp_s4_valid ? task_s4_bits_dbID : source_req_s3.dbID;
  assign io_toTXRSP_bits_chiOpcode = txrsp_s5_valid ? task_s5_bits_chiOpcode : txrsp_s4_valid ? task_s4_bits_chiOpcode : source_req_s3.chiOpcode;
  assign io_toTXRSP_bits_resp = txrsp_s5_valid ? task_s5_bits_resp : txrsp_s4_valid ? task_s4_bits_resp : source_req_s3.resp;
  assign io_toTXRSP_bits_fwdState = txrsp_s5_valid ? task_s5_bits_fwdState : txrsp_s4_valid ? task_s4_bits_fwdState : source_req_s3.fwdState;
  assign io_toTXRSP_bits_pCrdType = txrsp_s5_valid ? task_s5_bits_pCrdType : txrsp_s4_valid ? task_s4_bits_pCrdType : source_req_s3.pCrdType;
  assign io_toTXRSP_bits_traceTag = txrsp_s5_valid ? task_s5_bits_traceTag : txrsp_s4_valid ? task_s4_bits_traceTag : source_req_s3.traceTag;

  // ===== Stage 4: 锁存 sinkB 响应/数据(时序), 处理 drop =====
  wire pendingTXDAT_s4 = task_s4_bits_channel[1] & ~task_s4_bits_mshrTask & task_s4_bits_txChannel[2];
  wire pendingD_s4 = task_s4_bits_channel[0] & ~task_s4_bits_mshrTask &
                     (task_s4_bits_opcode==4'd5 | task_s4_bits_opcode==4'd1);  // GrantData / AccessAckData
  wire req_drop_s3 = (~need_write_releaseBuf & ((~mshr_req_s3 & need_mshr_s3) | chnl_fire_s3)) |
                     (mshr_refill_s3 & retry);
  wire req_drop_s4 = ~need_write_releaseBuf_s4 & chnl_fire_s4;

  // ===== BlockInfo: 若 s2/s3 可能写 Dir 则反压 s1 同 set 入口 =====
  wire [8:0] s1_c_set = io_fromReqArb_status_s1_sets_0;
  wire [8:0] s1_b_set = io_fromReqArb_status_s1_sets_1;
  wire [8:0] s1_a_set = io_fromReqArb_status_s1_sets_2;
  wire [8:0] s1_g_set = io_fromReqArb_status_s1_sets_3;
  wire [30:0] s1_b_tag = io_fromReqArb_status_s1_tags_1;
  wire s2_valid = io_taskFromArb_s2_valid;
  // s23Block: set 相等 且 非(保证不写 meta 的 mshrTask)
  wire s2_writesMeta = ~(io_taskFromArb_s2_bits_mshrTask & ~io_taskFromArb_s2_bits_metaWen);
  wire s3_writesMeta = ~(task_s3_bits_mshrTask & ~task_s3_bits_metaWen);
  assign io_toReqBuf_0 = s2_valid & (io_taskFromArb_s2_bits_set==s1_a_set) & s2_writesMeta;
  assign io_toReqBuf_1 = task_s3_valid & (task_s3_bits_set==s1_a_set) & s3_writesMeta;
  assign io_toReqArb_blockC_s1 = s2_valid & (io_taskFromArb_s2_bits_set==s1_c_set) & s2_writesMeta;
  assign io_toReqArb_blockG_s1 = s2_valid & (io_taskFromArb_s2_bits_set==s1_g_set) & s2_writesMeta;
  assign io_toReqArb_blockB_s1 =
       (s2_valid & (io_taskFromArb_s2_bits_set==s1_b_set)) |
       (task_s3_valid & (task_s3_bits_set==s1_b_set)) |
       (task_s4_valid & (task_s4_bits_set==s1_b_set) & (task_s4_bits_tag==s1_b_tag)) |
       (task_s5_valid & (task_s5_bits_set==s1_b_set) & (task_s5_bits_tag==s1_b_tag));

  // ===== Pipeline Status(给 GrantBuffer/TX 容量冲突判定) =====
  assign io_status_vec_toD_0_valid = task_s3_valid & (mshr_req_s3 ? (mshr_refill_s3 & ~retry) : 1'b1);
  assign io_status_vec_toD_0_bits_channel = task_s3_bits_channel;
  assign io_status_vec_toD_1_valid = task_s4_valid & (isD_s4 | pendingD_s4);
  assign io_status_vec_toD_1_bits_channel = task_s4_bits_channel;
  assign io_status_vec_toD_2_valid = d_s5_valid;
  assign io_status_vec_toD_2_bits_channel = task_s5_bits_channel;
  assign io_status_vec_toTX_0_valid = task_s3_valid;
  assign io_status_vec_toTX_0_bits_channel   = task_s3_bits_channel;
  assign io_status_vec_toTX_0_bits_txChannel = source_req_s3.txChannel;
  assign io_status_vec_toTX_0_bits_mshrTask  = task_s3_bits_mshrTask;
  assign io_status_vec_toTX_1_valid = task_s4_valid;
  assign io_status_vec_toTX_1_bits_channel   = task_s4_bits_channel;
  assign io_status_vec_toTX_1_bits_txChannel = task_s4_bits_txChannel;
  assign io_status_vec_toTX_1_bits_mshrTask  = task_s4_bits_mshrTask;
  assign io_status_vec_toTX_2_valid = task_s5_valid;
  assign io_status_vec_toTX_2_bits_channel   = task_s5_bits_channel;
  assign io_status_vec_toTX_2_bits_txChannel = task_s5_bits_txChannel;
  assign io_status_vec_toTX_2_bits_mshrTask  = task_s5_bits_mshrTask;

  // ===== ECC error =====
  assign io_error_valid = task_s5_valid;
  assign io_error_bits_valid = l2Error_s5;
  assign io_error_bits_address = {task_s5_bits_tag, task_s5_bits_set, task_s5_bits_off};

  // ===== 性能事件(8 个, 2 级 RegNext 延迟后零扩展成 6-bit) =====
  wire perf0 = task_s3_valid & ((sinkA_req_s3 & ~req_prefetch_s3) | sinkC_req_s3);
  wire perf1 = task_s3_valid & (mshr_cbWrData_s3 | mshr_snpRespDataX_s3);
  wire perf2 = task_s3_valid & sinkC_req_s3 & task_s3_bits_opcode==4'd7;  // ReleaseData
  wire perf3 = task_s3_valid & mshr_cbWrData_s3;
  wire perf4 = task_s3_valid & mshr_snpRespDataX_s3;
  wire perf5 = task_s3_valid & sinkA_req_s3 & ~req_prefetch_s3;
  wire perf6 = task_s3_valid & sinkC_req_s3;
  wire perf7 = task_s3_valid & sinkB_req_s3 & task_s3_bits_param==3'd2;  // toN
  assign io_perf_0_value = {5'h0, io_perf_0_value_dly2};
  assign io_perf_1_value = {5'h0, io_perf_1_value_dly2};
  assign io_perf_2_value = {5'h0, io_perf_2_value_dly2};
  assign io_perf_3_value = {5'h0, io_perf_3_value_dly2};
  assign io_perf_4_value = {5'h0, io_perf_4_value_dly2};
  assign io_perf_5_value = {5'h0, io_perf_5_value_dly2};
  assign io_perf_6_value = {5'h0, io_perf_6_value_dly2};
  assign io_perf_7_value = {5'h0, io_perf_7_value_dly2};

  // ===== 时序 1: 异步复位主流水寄存器 =====
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish <= 1'b0;
      resetIdx    <= 9'd511;
      task_s3_valid <= 1'b0; task_s4_valid <= 1'b0; task_s5_valid <= 1'b0;
      replResp_valid_s4 <= 1'b0; task_s3_valid_hold2 <= 2'b0;
      need_write_releaseBuf_s4 <= 1'b0; isD_s4 <= 1'b0; isTXREQ_s4 <= 1'b0;
      isTXRSP_s4 <= 1'b0; isTXDAT_s4 <= 1'b0; tagError_s4 <= 1'b0;
      dataError_s4 <= 1'b0; l2Error_s4 <= 1'b0; chnl_valid_s4_REG <= 1'b0;
      need_write_releaseBuf_s5 <= 1'b0; isD_s5 <= 1'b0; isTXREQ_s5 <= 1'b0;
      isTXRSP_s5 <= 1'b0; isTXDAT_s5 <= 1'b0; tagError_s5 <= 1'b0;
      dataMetaError_s5 <= 1'b0; l2TagError_s5 <= 1'b0;
      chnl_valid_s5_REG <= 1'b0; chnl_fire_s3_d1 <= 1'b0; chnl_fire_s3_d2 <= 1'b0;
      task_s3_bits_channel <= '0; task_s4_bits_channel <= '0; task_s5_bits_channel <= '0;
      task_s3_bits_txChannel <= '0; task_s4_bits_txChannel <= '0; task_s5_bits_txChannel <= '0;
      task_s3_bits_set <= '0; task_s4_bits_set <= '0; task_s5_bits_set <= '0;
      task_s3_bits_tag <= '0; task_s4_bits_tag <= '0; task_s5_bits_tag <= '0;
      task_s3_bits_off <= '0; task_s4_bits_off <= '0; task_s5_bits_off <= '0;
      task_s3_bits_alias <= '0; task_s4_bits_alias <= '0; task_s5_bits_alias <= '0;
      task_s3_bits_vaddr <= '0; task_s4_bits_vaddr <= '0; task_s5_bits_vaddr <= '0;
      task_s3_bits_isKeyword <= '0; task_s4_bits_isKeyword <= '0; task_s5_bits_isKeyword <= '0;
      task_s3_bits_opcode <= '0; task_s4_bits_opcode <= '0; task_s5_bits_opcode <= '0;
      task_s3_bits_param <= '0; task_s4_bits_param <= '0; task_s5_bits_param <= '0;
      task_s3_bits_size <= '0; task_s4_bits_size <= '0; task_s5_bits_size <= '0;
      task_s3_bits_sourceId <= '0; task_s4_bits_sourceId <= '0; task_s5_bits_sourceId <= '0;
      task_s3_bits_bufIdx <= '0; task_s4_bits_bufIdx <= '0; task_s5_bits_bufIdx <= '0;
      task_s3_bits_needProbeAckData <= '0; task_s4_bits_needProbeAckData <= '0; task_s5_bits_needProbeAckData <= '0;
      task_s3_bits_denied <= '0; task_s4_bits_denied <= '0; task_s5_bits_denied <= '0;
      task_s3_bits_corrupt <= '0; task_s4_bits_corrupt <= '0; task_s5_bits_corrupt <= '0;
      task_s3_bits_mshrTask <= '0; task_s4_bits_mshrTask <= '0; task_s5_bits_mshrTask <= '0;
      task_s3_bits_mshrId <= '0; task_s4_bits_mshrId <= '0; task_s5_bits_mshrId <= '0;
      task_s3_bits_aliasTask <= '0; task_s4_bits_aliasTask <= '0; task_s5_bits_aliasTask <= '0;
      task_s3_bits_useProbeData <= '0; task_s4_bits_useProbeData <= '0; task_s5_bits_useProbeData <= '0;
      task_s3_bits_mshrRetry <= '0; task_s4_bits_mshrRetry <= '0; task_s5_bits_mshrRetry <= '0;
      task_s3_bits_readProbeDataDown <= '0; task_s4_bits_readProbeDataDown <= '0; task_s5_bits_readProbeDataDown <= '0;
      task_s3_bits_fromL2pft <= '0; task_s4_bits_fromL2pft <= '0; task_s5_bits_fromL2pft <= '0;
      task_s3_bits_needHint <= '0; task_s4_bits_needHint <= '0; task_s5_bits_needHint <= '0;
      task_s3_bits_dirty <= '0; task_s4_bits_dirty <= '0; task_s5_bits_dirty <= '0;
      task_s3_bits_way <= '0; task_s4_bits_way <= '0; task_s5_bits_way <= '0;
      task_s3_bits_meta_dirty <= '0; task_s4_bits_meta_dirty <= '0; task_s5_bits_meta_dirty <= '0;
      task_s3_bits_meta_state <= '0; task_s4_bits_meta_state <= '0; task_s5_bits_meta_state <= '0;
      task_s3_bits_meta_clients <= '0; task_s4_bits_meta_clients <= '0; task_s5_bits_meta_clients <= '0;
      task_s3_bits_meta_alias <= '0; task_s4_bits_meta_alias <= '0; task_s5_bits_meta_alias <= '0;
      task_s3_bits_meta_prefetch <= '0; task_s4_bits_meta_prefetch <= '0; task_s5_bits_meta_prefetch <= '0;
      task_s3_bits_meta_prefetchSrc <= '0; task_s4_bits_meta_prefetchSrc <= '0; task_s5_bits_meta_prefetchSrc <= '0;
      task_s3_bits_meta_accessed <= '0; task_s4_bits_meta_accessed <= '0; task_s5_bits_meta_accessed <= '0;
      task_s3_bits_meta_tagErr <= '0; task_s4_bits_meta_tagErr <= '0; task_s5_bits_meta_tagErr <= '0;
      task_s3_bits_meta_dataErr <= '0; task_s4_bits_meta_dataErr <= '0; task_s5_bits_meta_dataErr <= '0;
      task_s3_bits_metaWen <= '0; task_s4_bits_metaWen <= '0; task_s5_bits_metaWen <= '0;
      task_s3_bits_tagWen <= '0; task_s4_bits_tagWen <= '0; task_s5_bits_tagWen <= '0;
      task_s3_bits_dsWen <= '0; task_s4_bits_dsWen <= '0; task_s5_bits_dsWen <= '0;
      task_s3_bits_wayMask <= '0; task_s4_bits_wayMask <= '0; task_s5_bits_wayMask <= '0;
      task_s3_bits_replTask <= '0; task_s4_bits_replTask <= '0; task_s5_bits_replTask <= '0;
      task_s3_bits_cmoTask <= '0; task_s4_bits_cmoTask <= '0; task_s5_bits_cmoTask <= '0;
      task_s3_bits_cmoAll <= '0; task_s4_bits_cmoAll <= '0; task_s5_bits_cmoAll <= '0;
      task_s3_bits_reqSource <= '0; task_s4_bits_reqSource <= '0; task_s5_bits_reqSource <= '0;
      task_s3_bits_mergeA <= '0; task_s4_bits_mergeA <= '0; task_s5_bits_mergeA <= '0;
      task_s3_bits_aMergeTask_off <= '0; task_s4_bits_aMergeTask_off <= '0; task_s5_bits_aMergeTask_off <= '0;
      task_s3_bits_aMergeTask_alias <= '0; task_s4_bits_aMergeTask_alias <= '0; task_s5_bits_aMergeTask_alias <= '0;
      task_s3_bits_aMergeTask_vaddr <= '0; task_s4_bits_aMergeTask_vaddr <= '0; task_s5_bits_aMergeTask_vaddr <= '0;
      task_s3_bits_aMergeTask_isKeyword <= '0; task_s4_bits_aMergeTask_isKeyword <= '0; task_s5_bits_aMergeTask_isKeyword <= '0;
      task_s3_bits_aMergeTask_opcode <= '0; task_s4_bits_aMergeTask_opcode <= '0; task_s5_bits_aMergeTask_opcode <= '0;
      task_s3_bits_aMergeTask_param <= '0; task_s4_bits_aMergeTask_param <= '0; task_s5_bits_aMergeTask_param <= '0;
      task_s3_bits_aMergeTask_sourceId <= '0; task_s4_bits_aMergeTask_sourceId <= '0; task_s5_bits_aMergeTask_sourceId <= '0;
      task_s3_bits_aMergeTask_meta_dirty <= '0; task_s4_bits_aMergeTask_meta_dirty <= '0; task_s5_bits_aMergeTask_meta_dirty <= '0;
      task_s3_bits_aMergeTask_meta_state <= '0; task_s4_bits_aMergeTask_meta_state <= '0; task_s5_bits_aMergeTask_meta_state <= '0;
      task_s3_bits_aMergeTask_meta_clients <= '0; task_s4_bits_aMergeTask_meta_clients <= '0; task_s5_bits_aMergeTask_meta_clients <= '0;
      task_s3_bits_aMergeTask_meta_alias <= '0; task_s4_bits_aMergeTask_meta_alias <= '0; task_s5_bits_aMergeTask_meta_alias <= '0;
      task_s3_bits_aMergeTask_meta_prefetch <= '0; task_s4_bits_aMergeTask_meta_prefetch <= '0; task_s5_bits_aMergeTask_meta_prefetch <= '0;
      task_s3_bits_aMergeTask_meta_prefetchSrc <= '0; task_s4_bits_aMergeTask_meta_prefetchSrc <= '0; task_s5_bits_aMergeTask_meta_prefetchSrc <= '0;
      task_s3_bits_aMergeTask_meta_accessed <= '0; task_s4_bits_aMergeTask_meta_accessed <= '0; task_s5_bits_aMergeTask_meta_accessed <= '0;
      task_s3_bits_aMergeTask_meta_tagErr <= '0; task_s4_bits_aMergeTask_meta_tagErr <= '0; task_s5_bits_aMergeTask_meta_tagErr <= '0;
      task_s3_bits_aMergeTask_meta_dataErr <= '0; task_s4_bits_aMergeTask_meta_dataErr <= '0; task_s5_bits_aMergeTask_meta_dataErr <= '0;
      task_s3_bits_snpHitRelease <= '0; task_s4_bits_snpHitRelease <= '0; task_s5_bits_snpHitRelease <= '0;
      task_s3_bits_snpHitReleaseToInval <= '0; task_s4_bits_snpHitReleaseToInval <= '0; task_s5_bits_snpHitReleaseToInval <= '0;
      task_s3_bits_snpHitReleaseToClean <= '0; task_s4_bits_snpHitReleaseToClean <= '0; task_s5_bits_snpHitReleaseToClean <= '0;
      task_s3_bits_snpHitReleaseWithData <= '0; task_s4_bits_snpHitReleaseWithData <= '0; task_s5_bits_snpHitReleaseWithData <= '0;
      task_s3_bits_snpHitReleaseIdx <= '0; task_s4_bits_snpHitReleaseIdx <= '0; task_s5_bits_snpHitReleaseIdx <= '0;
      task_s3_bits_snpHitReleaseMeta_dirty <= '0; task_s4_bits_snpHitReleaseMeta_dirty <= '0; task_s5_bits_snpHitReleaseMeta_dirty <= '0;
      task_s3_bits_snpHitReleaseMeta_state <= '0; task_s4_bits_snpHitReleaseMeta_state <= '0; task_s5_bits_snpHitReleaseMeta_state <= '0;
      task_s3_bits_snpHitReleaseMeta_clients <= '0; task_s4_bits_snpHitReleaseMeta_clients <= '0; task_s5_bits_snpHitReleaseMeta_clients <= '0;
      task_s3_bits_snpHitReleaseMeta_alias <= '0; task_s4_bits_snpHitReleaseMeta_alias <= '0; task_s5_bits_snpHitReleaseMeta_alias <= '0;
      task_s3_bits_snpHitReleaseMeta_prefetch <= '0; task_s4_bits_snpHitReleaseMeta_prefetch <= '0; task_s5_bits_snpHitReleaseMeta_prefetch <= '0;
      task_s3_bits_snpHitReleaseMeta_prefetchSrc <= '0; task_s4_bits_snpHitReleaseMeta_prefetchSrc <= '0; task_s5_bits_snpHitReleaseMeta_prefetchSrc <= '0;
      task_s3_bits_snpHitReleaseMeta_accessed <= '0; task_s4_bits_snpHitReleaseMeta_accessed <= '0; task_s5_bits_snpHitReleaseMeta_accessed <= '0;
      task_s3_bits_snpHitReleaseMeta_tagErr <= '0; task_s4_bits_snpHitReleaseMeta_tagErr <= '0; task_s5_bits_snpHitReleaseMeta_tagErr <= '0;
      task_s3_bits_snpHitReleaseMeta_dataErr <= '0; task_s4_bits_snpHitReleaseMeta_dataErr <= '0; task_s5_bits_snpHitReleaseMeta_dataErr <= '0;
      task_s3_bits_tgtID <= '0; task_s4_bits_tgtID <= '0; task_s5_bits_tgtID <= '0;
      task_s3_bits_srcID <= '0; task_s4_bits_srcID <= '0; task_s5_bits_srcID <= '0;
      task_s3_bits_txnID <= '0; task_s4_bits_txnID <= '0; task_s5_bits_txnID <= '0;
      task_s3_bits_homeNID <= '0; task_s4_bits_homeNID <= '0; task_s5_bits_homeNID <= '0;
      task_s3_bits_dbID <= '0; task_s4_bits_dbID <= '0; task_s5_bits_dbID <= '0;
      task_s3_bits_fwdNID <= '0; task_s4_bits_fwdNID <= '0; task_s5_bits_fwdNID <= '0;
      task_s3_bits_fwdTxnID <= '0; task_s4_bits_fwdTxnID <= '0; task_s5_bits_fwdTxnID <= '0;
      task_s3_bits_chiOpcode <= '0; task_s4_bits_chiOpcode <= '0; task_s5_bits_chiOpcode <= '0;
      task_s3_bits_resp <= '0; task_s4_bits_resp <= '0; task_s5_bits_resp <= '0;
      task_s3_bits_fwdState <= '0; task_s4_bits_fwdState <= '0; task_s5_bits_fwdState <= '0;
      task_s3_bits_pCrdType <= '0; task_s4_bits_pCrdType <= '0; task_s5_bits_pCrdType <= '0;
      task_s3_bits_retToSrc <= '0; task_s4_bits_retToSrc <= '0; task_s5_bits_retToSrc <= '0;
      task_s3_bits_likelyshared <= '0; task_s4_bits_likelyshared <= '0; task_s5_bits_likelyshared <= '0;
      task_s3_bits_expCompAck <= '0; task_s4_bits_expCompAck <= '0; task_s5_bits_expCompAck <= '0;
      task_s3_bits_allowRetry <= '0; task_s4_bits_allowRetry <= '0; task_s5_bits_allowRetry <= '0;
      task_s3_bits_memAttr_allocate <= '0; task_s4_bits_memAttr_allocate <= '0; task_s5_bits_memAttr_allocate <= '0;
      task_s3_bits_memAttr_cacheable <= '0; task_s4_bits_memAttr_cacheable <= '0; task_s5_bits_memAttr_cacheable <= '0;
      task_s3_bits_memAttr_device <= '0; task_s4_bits_memAttr_device <= '0; task_s5_bits_memAttr_device <= '0;
      task_s3_bits_memAttr_ewa <= '0; task_s4_bits_memAttr_ewa <= '0; task_s5_bits_memAttr_ewa <= '0;
      task_s3_bits_traceTag <= '0; task_s4_bits_traceTag <= '0; task_s5_bits_traceTag <= '0;
      task_s3_bits_dataCheckErr <= '0; task_s4_bits_dataCheckErr <= '0; task_s5_bits_dataCheckErr <= '0;
    end else begin
      resetFinish <= (resetIdx == 9'd0) | resetFinish;
      if (~resetFinish) resetIdx <= resetIdx - 9'd1;
      replResp_valid_s4 <= io_replResp_valid;
      // task_s3_valid_hold2: s2 有效起 2 拍 (给 DS req valid 拉宽)
      task_s3_valid_hold2 <= io_taskFromArb_s2_valid ? 2'b11 : (task_s3_valid_hold2 >> 1);
      // s2 → s3
      task_s3_valid <= io_taskFromArb_s2_valid;
      if (io_taskFromArb_s2_valid) begin
        task_s3_bits_channel <= io_taskFromArb_s2_bits_channel;
        task_s3_bits_txChannel <= io_taskFromArb_s2_bits_txChannel;
        task_s3_bits_set <= io_taskFromArb_s2_bits_set;
        task_s3_bits_tag <= io_taskFromArb_s2_bits_tag;
        task_s3_bits_off <= io_taskFromArb_s2_bits_off;
        task_s3_bits_alias <= io_taskFromArb_s2_bits_alias;
        task_s3_bits_vaddr <= io_taskFromArb_s2_bits_vaddr;
        task_s3_bits_isKeyword <= io_taskFromArb_s2_bits_isKeyword;
        task_s3_bits_opcode <= io_taskFromArb_s2_bits_opcode;
        task_s3_bits_param <= io_taskFromArb_s2_bits_param;
        task_s3_bits_size <= io_taskFromArb_s2_bits_size;
        task_s3_bits_sourceId <= io_taskFromArb_s2_bits_sourceId;
        task_s3_bits_bufIdx <= io_taskFromArb_s2_bits_bufIdx;
        task_s3_bits_needProbeAckData <= io_taskFromArb_s2_bits_needProbeAckData;
        task_s3_bits_denied <= io_taskFromArb_s2_bits_denied;
        task_s3_bits_corrupt <= io_taskFromArb_s2_bits_corrupt;
        task_s3_bits_mshrTask <= io_taskFromArb_s2_bits_mshrTask;
        task_s3_bits_mshrId <= io_taskFromArb_s2_bits_mshrId;
        task_s3_bits_aliasTask <= io_taskFromArb_s2_bits_aliasTask;
        task_s3_bits_useProbeData <= io_taskFromArb_s2_bits_useProbeData;
        task_s3_bits_mshrRetry <= io_taskFromArb_s2_bits_mshrRetry;
        task_s3_bits_readProbeDataDown <= io_taskFromArb_s2_bits_readProbeDataDown;
        task_s3_bits_fromL2pft <= io_taskFromArb_s2_bits_fromL2pft;
        task_s3_bits_needHint <= io_taskFromArb_s2_bits_needHint;
        task_s3_bits_dirty <= io_taskFromArb_s2_bits_dirty;
        task_s3_bits_way <= io_taskFromArb_s2_bits_way;
        task_s3_bits_meta_dirty <= io_taskFromArb_s2_bits_meta_dirty;
        task_s3_bits_meta_state <= io_taskFromArb_s2_bits_meta_state;
        task_s3_bits_meta_clients <= io_taskFromArb_s2_bits_meta_clients;
        task_s3_bits_meta_alias <= io_taskFromArb_s2_bits_meta_alias;
        task_s3_bits_meta_prefetch <= io_taskFromArb_s2_bits_meta_prefetch;
        task_s3_bits_meta_prefetchSrc <= io_taskFromArb_s2_bits_meta_prefetchSrc;
        task_s3_bits_meta_accessed <= io_taskFromArb_s2_bits_meta_accessed;
        task_s3_bits_meta_tagErr <= io_taskFromArb_s2_bits_meta_tagErr;
        task_s3_bits_meta_dataErr <= io_taskFromArb_s2_bits_meta_dataErr;
        task_s3_bits_metaWen <= io_taskFromArb_s2_bits_metaWen;
        task_s3_bits_tagWen <= io_taskFromArb_s2_bits_tagWen;
        task_s3_bits_dsWen <= io_taskFromArb_s2_bits_dsWen;
        task_s3_bits_wayMask <= io_taskFromArb_s2_bits_wayMask;
        task_s3_bits_replTask <= io_taskFromArb_s2_bits_replTask;
        task_s3_bits_cmoTask <= io_taskFromArb_s2_bits_cmoTask;
        task_s3_bits_cmoAll <= io_taskFromArb_s2_bits_cmoAll;
        task_s3_bits_reqSource <= io_taskFromArb_s2_bits_reqSource;
        task_s3_bits_mergeA <= io_taskFromArb_s2_bits_mergeA;
        task_s3_bits_aMergeTask_off <= io_taskFromArb_s2_bits_aMergeTask_off;
        task_s3_bits_aMergeTask_alias <= io_taskFromArb_s2_bits_aMergeTask_alias;
        task_s3_bits_aMergeTask_vaddr <= io_taskFromArb_s2_bits_aMergeTask_vaddr;
        task_s3_bits_aMergeTask_isKeyword <= io_taskFromArb_s2_bits_aMergeTask_isKeyword;
        task_s3_bits_aMergeTask_opcode <= io_taskFromArb_s2_bits_aMergeTask_opcode;
        task_s3_bits_aMergeTask_param <= io_taskFromArb_s2_bits_aMergeTask_param;
        task_s3_bits_aMergeTask_sourceId <= io_taskFromArb_s2_bits_aMergeTask_sourceId;
        task_s3_bits_aMergeTask_meta_dirty <= io_taskFromArb_s2_bits_aMergeTask_meta_dirty;
        task_s3_bits_aMergeTask_meta_state <= io_taskFromArb_s2_bits_aMergeTask_meta_state;
        task_s3_bits_aMergeTask_meta_clients <= io_taskFromArb_s2_bits_aMergeTask_meta_clients;
        task_s3_bits_aMergeTask_meta_alias <= io_taskFromArb_s2_bits_aMergeTask_meta_alias;
        task_s3_bits_aMergeTask_meta_prefetch <= io_taskFromArb_s2_bits_aMergeTask_meta_prefetch;
        task_s3_bits_aMergeTask_meta_prefetchSrc <= io_taskFromArb_s2_bits_aMergeTask_meta_prefetchSrc;
        task_s3_bits_aMergeTask_meta_accessed <= io_taskFromArb_s2_bits_aMergeTask_meta_accessed;
        task_s3_bits_aMergeTask_meta_tagErr <= io_taskFromArb_s2_bits_aMergeTask_meta_tagErr;
        task_s3_bits_aMergeTask_meta_dataErr <= io_taskFromArb_s2_bits_aMergeTask_meta_dataErr;
        task_s3_bits_snpHitRelease <= io_taskFromArb_s2_bits_snpHitRelease;
        task_s3_bits_snpHitReleaseToInval <= io_taskFromArb_s2_bits_snpHitReleaseToInval;
        task_s3_bits_snpHitReleaseToClean <= io_taskFromArb_s2_bits_snpHitReleaseToClean;
        task_s3_bits_snpHitReleaseWithData <= io_taskFromArb_s2_bits_snpHitReleaseWithData;
        task_s3_bits_snpHitReleaseIdx <= io_taskFromArb_s2_bits_snpHitReleaseIdx;
        task_s3_bits_snpHitReleaseMeta_dirty <= io_taskFromArb_s2_bits_snpHitReleaseMeta_dirty;
        task_s3_bits_snpHitReleaseMeta_state <= io_taskFromArb_s2_bits_snpHitReleaseMeta_state;
        task_s3_bits_snpHitReleaseMeta_clients <= io_taskFromArb_s2_bits_snpHitReleaseMeta_clients;
        task_s3_bits_snpHitReleaseMeta_alias <= io_taskFromArb_s2_bits_snpHitReleaseMeta_alias;
        task_s3_bits_snpHitReleaseMeta_prefetch <= io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetch;
        task_s3_bits_snpHitReleaseMeta_prefetchSrc <= io_taskFromArb_s2_bits_snpHitReleaseMeta_prefetchSrc;
        task_s3_bits_snpHitReleaseMeta_accessed <= io_taskFromArb_s2_bits_snpHitReleaseMeta_accessed;
        task_s3_bits_snpHitReleaseMeta_tagErr <= io_taskFromArb_s2_bits_snpHitReleaseMeta_tagErr;
        task_s3_bits_snpHitReleaseMeta_dataErr <= io_taskFromArb_s2_bits_snpHitReleaseMeta_dataErr;
        task_s3_bits_tgtID <= io_taskFromArb_s2_bits_tgtID;
        task_s3_bits_srcID <= io_taskFromArb_s2_bits_srcID;
        task_s3_bits_txnID <= io_taskFromArb_s2_bits_txnID;
        task_s3_bits_homeNID <= io_taskFromArb_s2_bits_homeNID;
        task_s3_bits_dbID <= io_taskFromArb_s2_bits_dbID;
        task_s3_bits_fwdNID <= io_taskFromArb_s2_bits_fwdNID;
        task_s3_bits_fwdTxnID <= io_taskFromArb_s2_bits_fwdTxnID;
        task_s3_bits_chiOpcode <= io_taskFromArb_s2_bits_chiOpcode;
        task_s3_bits_resp <= io_taskFromArb_s2_bits_resp;
        task_s3_bits_fwdState <= io_taskFromArb_s2_bits_fwdState;
        task_s3_bits_pCrdType <= io_taskFromArb_s2_bits_pCrdType;
        task_s3_bits_retToSrc <= io_taskFromArb_s2_bits_retToSrc;
        task_s3_bits_likelyshared <= io_taskFromArb_s2_bits_likelyshared;
        task_s3_bits_expCompAck <= io_taskFromArb_s2_bits_expCompAck;
        task_s3_bits_allowRetry <= io_taskFromArb_s2_bits_allowRetry;
        task_s3_bits_memAttr_allocate <= io_taskFromArb_s2_bits_memAttr_allocate;
        task_s3_bits_memAttr_cacheable <= io_taskFromArb_s2_bits_memAttr_cacheable;
        task_s3_bits_memAttr_device <= io_taskFromArb_s2_bits_memAttr_device;
        task_s3_bits_memAttr_ewa <= io_taskFromArb_s2_bits_memAttr_ewa;
        task_s3_bits_traceTag <= io_taskFromArb_s2_bits_traceTag;
        task_s3_bits_dataCheckErr <= io_taskFromArb_s2_bits_dataCheckErr;
      end
      // s3 → s4 (锁存 source_req_s3; need_mshr 时 mshrId 取 alloc_ptr)
      task_s4_valid <= task_s3_valid & ~req_drop_s3;
      if (task_s3_valid & ~req_drop_s3) begin
        task_s4_bits_channel <= source_req_s3.channel;
        task_s4_bits_txChannel <= source_req_s3.txChannel;
        task_s4_bits_set <= source_req_s3.set;
        task_s4_bits_tag <= source_req_s3.tag;
        task_s4_bits_off <= source_req_s3.off;
        task_s4_bits_alias <= source_req_s3.alias_;
        task_s4_bits_vaddr <= source_req_s3.vaddr;
        task_s4_bits_isKeyword <= source_req_s3.isKeyword;
        task_s4_bits_opcode <= source_req_s3.opcode;
        task_s4_bits_param <= source_req_s3.param;
        task_s4_bits_size <= source_req_s3.size;
        task_s4_bits_sourceId <= source_req_s3.sourceId;
        task_s4_bits_bufIdx <= source_req_s3.bufIdx;
        task_s4_bits_needProbeAckData <= source_req_s3.needProbeAckData;
        task_s4_bits_denied <= source_req_s3.denied;
        task_s4_bits_corrupt <= source_req_s3.corrupt;
        task_s4_bits_mshrTask <= source_req_s3.mshrTask;
        task_s4_bits_mshrId <= (~mshr_req_s3 & need_mshr_s3) ? io_fromMSHRCtl_mshr_alloc_ptr : source_req_s3.mshrId;
        task_s4_bits_aliasTask <= source_req_s3.aliasTask;
        task_s4_bits_useProbeData <= source_req_s3.useProbeData;
        task_s4_bits_mshrRetry <= source_req_s3.mshrRetry;
        task_s4_bits_readProbeDataDown <= source_req_s3.readProbeDataDown;
        task_s4_bits_fromL2pft <= source_req_s3.fromL2pft;
        task_s4_bits_needHint <= source_req_s3.needHint;
        task_s4_bits_dirty <= source_req_s3.dirty;
        task_s4_bits_way <= source_req_s3.way;
        task_s4_bits_meta_dirty <= source_req_s3.meta_dirty;
        task_s4_bits_meta_state <= source_req_s3.meta_state;
        task_s4_bits_meta_clients <= source_req_s3.meta_clients;
        task_s4_bits_meta_alias <= source_req_s3.meta_alias;
        task_s4_bits_meta_prefetch <= source_req_s3.meta_prefetch;
        task_s4_bits_meta_prefetchSrc <= source_req_s3.meta_prefetchSrc;
        task_s4_bits_meta_accessed <= source_req_s3.meta_accessed;
        task_s4_bits_meta_tagErr <= source_req_s3.meta_tagErr;
        task_s4_bits_meta_dataErr <= source_req_s3.meta_dataErr;
        task_s4_bits_metaWen <= source_req_s3.metaWen;
        task_s4_bits_tagWen <= source_req_s3.tagWen;
        task_s4_bits_dsWen <= source_req_s3.dsWen;
        task_s4_bits_wayMask <= source_req_s3.wayMask;
        task_s4_bits_replTask <= source_req_s3.replTask;
        task_s4_bits_cmoTask <= source_req_s3.cmoTask;
        task_s4_bits_cmoAll <= source_req_s3.cmoAll;
        task_s4_bits_reqSource <= source_req_s3.reqSource;
        task_s4_bits_mergeA <= source_req_s3.mergeA;
        task_s4_bits_aMergeTask_off <= source_req_s3.aMergeTask_off;
        task_s4_bits_aMergeTask_alias <= source_req_s3.aMergeTask_alias;
        task_s4_bits_aMergeTask_vaddr <= source_req_s3.aMergeTask_vaddr;
        task_s4_bits_aMergeTask_isKeyword <= source_req_s3.aMergeTask_isKeyword;
        task_s4_bits_aMergeTask_opcode <= source_req_s3.aMergeTask_opcode;
        task_s4_bits_aMergeTask_param <= source_req_s3.aMergeTask_param;
        task_s4_bits_aMergeTask_sourceId <= source_req_s3.aMergeTask_sourceId;
        task_s4_bits_aMergeTask_meta_dirty <= source_req_s3.aMergeTask_meta_dirty;
        task_s4_bits_aMergeTask_meta_state <= source_req_s3.aMergeTask_meta_state;
        task_s4_bits_aMergeTask_meta_clients <= source_req_s3.aMergeTask_meta_clients;
        task_s4_bits_aMergeTask_meta_alias <= source_req_s3.aMergeTask_meta_alias;
        task_s4_bits_aMergeTask_meta_prefetch <= source_req_s3.aMergeTask_meta_prefetch;
        task_s4_bits_aMergeTask_meta_prefetchSrc <= source_req_s3.aMergeTask_meta_prefetchSrc;
        task_s4_bits_aMergeTask_meta_accessed <= source_req_s3.aMergeTask_meta_accessed;
        task_s4_bits_aMergeTask_meta_tagErr <= source_req_s3.aMergeTask_meta_tagErr;
        task_s4_bits_aMergeTask_meta_dataErr <= source_req_s3.aMergeTask_meta_dataErr;
        task_s4_bits_snpHitRelease <= source_req_s3.snpHitRelease;
        task_s4_bits_snpHitReleaseToInval <= source_req_s3.snpHitReleaseToInval;
        task_s4_bits_snpHitReleaseToClean <= source_req_s3.snpHitReleaseToClean;
        task_s4_bits_snpHitReleaseWithData <= source_req_s3.snpHitReleaseWithData;
        task_s4_bits_snpHitReleaseIdx <= source_req_s3.snpHitReleaseIdx;
        task_s4_bits_snpHitReleaseMeta_dirty <= source_req_s3.snpHitReleaseMeta_dirty;
        task_s4_bits_snpHitReleaseMeta_state <= source_req_s3.snpHitReleaseMeta_state;
        task_s4_bits_snpHitReleaseMeta_clients <= source_req_s3.snpHitReleaseMeta_clients;
        task_s4_bits_snpHitReleaseMeta_alias <= source_req_s3.snpHitReleaseMeta_alias;
        task_s4_bits_snpHitReleaseMeta_prefetch <= source_req_s3.snpHitReleaseMeta_prefetch;
        task_s4_bits_snpHitReleaseMeta_prefetchSrc <= source_req_s3.snpHitReleaseMeta_prefetchSrc;
        task_s4_bits_snpHitReleaseMeta_accessed <= source_req_s3.snpHitReleaseMeta_accessed;
        task_s4_bits_snpHitReleaseMeta_tagErr <= source_req_s3.snpHitReleaseMeta_tagErr;
        task_s4_bits_snpHitReleaseMeta_dataErr <= source_req_s3.snpHitReleaseMeta_dataErr;
        task_s4_bits_tgtID <= source_req_s3.tgtID;
        task_s4_bits_srcID <= source_req_s3.srcID;
        task_s4_bits_txnID <= source_req_s3.txnID;
        task_s4_bits_homeNID <= source_req_s3.homeNID;
        task_s4_bits_dbID <= source_req_s3.dbID;
        task_s4_bits_fwdNID <= source_req_s3.fwdNID;
        task_s4_bits_fwdTxnID <= source_req_s3.fwdTxnID;
        task_s4_bits_chiOpcode <= source_req_s3.chiOpcode;
        task_s4_bits_resp <= source_req_s3.resp;
        task_s4_bits_fwdState <= source_req_s3.fwdState;
        task_s4_bits_pCrdType <= source_req_s3.pCrdType;
        task_s4_bits_retToSrc <= source_req_s3.retToSrc;
        task_s4_bits_likelyshared <= source_req_s3.likelyshared;
        task_s4_bits_expCompAck <= source_req_s3.expCompAck;
        task_s4_bits_allowRetry <= source_req_s3.allowRetry;
        task_s4_bits_memAttr_allocate <= source_req_s3.memAttr_allocate;
        task_s4_bits_memAttr_cacheable <= source_req_s3.memAttr_cacheable;
        task_s4_bits_memAttr_device <= source_req_s3.memAttr_device;
        task_s4_bits_memAttr_ewa <= source_req_s3.memAttr_ewa;
        task_s4_bits_traceTag <= source_req_s3.traceTag;
        task_s4_bits_dataCheckErr <= source_req_s3.dataCheckErr;
        need_write_releaseBuf_s4 <= need_write_releaseBuf;
        isD_s4 <= isD_s3; isTXREQ_s4 <= isTXREQ_s3; isTXRSP_s4 <= isTXRSP_s3; isTXDAT_s4 <= isTXDAT_s3;
        tagError_s4 <= tagError_s3; dataError_s4 <= dataError_s3; l2Error_s4 <= l2Error_s3;
      end
      chnl_valid_s4_REG <= chnl_fire_s3;
      // s4 → s5
      task_s5_valid <= task_s4_valid & ~req_drop_s4;
      if (task_s4_valid & ~req_drop_s4) begin
        task_s5_bits_channel <= task_s4_bits_channel;
        task_s5_bits_txChannel <= task_s4_bits_txChannel;
        task_s5_bits_set <= task_s4_bits_set;
        task_s5_bits_tag <= task_s4_bits_tag;
        task_s5_bits_off <= task_s4_bits_off;
        task_s5_bits_alias <= task_s4_bits_alias;
        task_s5_bits_vaddr <= task_s4_bits_vaddr;
        task_s5_bits_isKeyword <= task_s4_bits_isKeyword;
        task_s5_bits_opcode <= task_s4_bits_opcode;
        task_s5_bits_param <= task_s4_bits_param;
        task_s5_bits_size <= task_s4_bits_size;
        task_s5_bits_sourceId <= task_s4_bits_sourceId;
        task_s5_bits_bufIdx <= task_s4_bits_bufIdx;
        task_s5_bits_needProbeAckData <= task_s4_bits_needProbeAckData;
        task_s5_bits_denied <= task_s4_bits_denied;
        task_s5_bits_corrupt <= task_s4_bits_corrupt;
        task_s5_bits_mshrTask <= task_s4_bits_mshrTask;
        task_s5_bits_mshrId <= task_s4_bits_mshrId;
        task_s5_bits_aliasTask <= task_s4_bits_aliasTask;
        task_s5_bits_useProbeData <= task_s4_bits_useProbeData;
        task_s5_bits_mshrRetry <= task_s4_bits_mshrRetry;
        task_s5_bits_readProbeDataDown <= task_s4_bits_readProbeDataDown;
        task_s5_bits_fromL2pft <= task_s4_bits_fromL2pft;
        task_s5_bits_needHint <= task_s4_bits_needHint;
        task_s5_bits_dirty <= task_s4_bits_dirty;
        task_s5_bits_way <= task_s4_bits_way;
        task_s5_bits_meta_dirty <= task_s4_bits_meta_dirty;
        task_s5_bits_meta_state <= task_s4_bits_meta_state;
        task_s5_bits_meta_clients <= task_s4_bits_meta_clients;
        task_s5_bits_meta_alias <= task_s4_bits_meta_alias;
        task_s5_bits_meta_prefetch <= task_s4_bits_meta_prefetch;
        task_s5_bits_meta_prefetchSrc <= task_s4_bits_meta_prefetchSrc;
        task_s5_bits_meta_accessed <= task_s4_bits_meta_accessed;
        task_s5_bits_meta_tagErr <= task_s4_bits_meta_tagErr;
        task_s5_bits_meta_dataErr <= task_s4_bits_meta_dataErr;
        task_s5_bits_metaWen <= task_s4_bits_metaWen;
        task_s5_bits_tagWen <= task_s4_bits_tagWen;
        task_s5_bits_dsWen <= task_s4_bits_dsWen;
        task_s5_bits_wayMask <= task_s4_bits_wayMask;
        task_s5_bits_replTask <= task_s4_bits_replTask;
        task_s5_bits_cmoTask <= task_s4_bits_cmoTask;
        task_s5_bits_cmoAll <= task_s4_bits_cmoAll;
        task_s5_bits_reqSource <= task_s4_bits_reqSource;
        task_s5_bits_mergeA <= task_s4_bits_mergeA;
        task_s5_bits_aMergeTask_off <= task_s4_bits_aMergeTask_off;
        task_s5_bits_aMergeTask_alias <= task_s4_bits_aMergeTask_alias;
        task_s5_bits_aMergeTask_vaddr <= task_s4_bits_aMergeTask_vaddr;
        task_s5_bits_aMergeTask_isKeyword <= task_s4_bits_aMergeTask_isKeyword;
        task_s5_bits_aMergeTask_opcode <= task_s4_bits_aMergeTask_opcode;
        task_s5_bits_aMergeTask_param <= task_s4_bits_aMergeTask_param;
        task_s5_bits_aMergeTask_sourceId <= task_s4_bits_aMergeTask_sourceId;
        task_s5_bits_aMergeTask_meta_dirty <= task_s4_bits_aMergeTask_meta_dirty;
        task_s5_bits_aMergeTask_meta_state <= task_s4_bits_aMergeTask_meta_state;
        task_s5_bits_aMergeTask_meta_clients <= task_s4_bits_aMergeTask_meta_clients;
        task_s5_bits_aMergeTask_meta_alias <= task_s4_bits_aMergeTask_meta_alias;
        task_s5_bits_aMergeTask_meta_prefetch <= task_s4_bits_aMergeTask_meta_prefetch;
        task_s5_bits_aMergeTask_meta_prefetchSrc <= task_s4_bits_aMergeTask_meta_prefetchSrc;
        task_s5_bits_aMergeTask_meta_accessed <= task_s4_bits_aMergeTask_meta_accessed;
        task_s5_bits_aMergeTask_meta_tagErr <= task_s4_bits_aMergeTask_meta_tagErr;
        task_s5_bits_aMergeTask_meta_dataErr <= task_s4_bits_aMergeTask_meta_dataErr;
        task_s5_bits_snpHitRelease <= task_s4_bits_snpHitRelease;
        task_s5_bits_snpHitReleaseToInval <= task_s4_bits_snpHitReleaseToInval;
        task_s5_bits_snpHitReleaseToClean <= task_s4_bits_snpHitReleaseToClean;
        task_s5_bits_snpHitReleaseWithData <= task_s4_bits_snpHitReleaseWithData;
        task_s5_bits_snpHitReleaseIdx <= task_s4_bits_snpHitReleaseIdx;
        task_s5_bits_snpHitReleaseMeta_dirty <= task_s4_bits_snpHitReleaseMeta_dirty;
        task_s5_bits_snpHitReleaseMeta_state <= task_s4_bits_snpHitReleaseMeta_state;
        task_s5_bits_snpHitReleaseMeta_clients <= task_s4_bits_snpHitReleaseMeta_clients;
        task_s5_bits_snpHitReleaseMeta_alias <= task_s4_bits_snpHitReleaseMeta_alias;
        task_s5_bits_snpHitReleaseMeta_prefetch <= task_s4_bits_snpHitReleaseMeta_prefetch;
        task_s5_bits_snpHitReleaseMeta_prefetchSrc <= task_s4_bits_snpHitReleaseMeta_prefetchSrc;
        task_s5_bits_snpHitReleaseMeta_accessed <= task_s4_bits_snpHitReleaseMeta_accessed;
        task_s5_bits_snpHitReleaseMeta_tagErr <= task_s4_bits_snpHitReleaseMeta_tagErr;
        task_s5_bits_snpHitReleaseMeta_dataErr <= task_s4_bits_snpHitReleaseMeta_dataErr;
        task_s5_bits_tgtID <= task_s4_bits_tgtID;
        task_s5_bits_srcID <= task_s4_bits_srcID;
        task_s5_bits_txnID <= task_s4_bits_txnID;
        task_s5_bits_homeNID <= task_s4_bits_homeNID;
        task_s5_bits_dbID <= task_s4_bits_dbID;
        task_s5_bits_fwdNID <= task_s4_bits_fwdNID;
        task_s5_bits_fwdTxnID <= task_s4_bits_fwdTxnID;
        task_s5_bits_chiOpcode <= task_s4_bits_chiOpcode;
        task_s5_bits_resp <= task_s4_bits_resp;
        task_s5_bits_fwdState <= task_s4_bits_fwdState;
        task_s5_bits_pCrdType <= task_s4_bits_pCrdType;
        task_s5_bits_retToSrc <= task_s4_bits_retToSrc;
        task_s5_bits_likelyshared <= task_s4_bits_likelyshared;
        task_s5_bits_expCompAck <= task_s4_bits_expCompAck;
        task_s5_bits_allowRetry <= task_s4_bits_allowRetry;
        task_s5_bits_memAttr_allocate <= task_s4_bits_memAttr_allocate;
        task_s5_bits_memAttr_cacheable <= task_s4_bits_memAttr_cacheable;
        task_s5_bits_memAttr_device <= task_s4_bits_memAttr_device;
        task_s5_bits_memAttr_ewa <= task_s4_bits_memAttr_ewa;
        task_s5_bits_traceTag <= task_s4_bits_traceTag;
        task_s5_bits_dataCheckErr <= task_s4_bits_dataCheckErr;
        need_write_releaseBuf_s5 <= need_write_releaseBuf_s4;
        isD_s5 <= isD_s4 | pendingD_s4; isTXREQ_s5 <= isTXREQ_s4; isTXRSP_s5 <= isTXRSP_s4;
        isTXDAT_s5 <= isTXDAT_s4 | pendingTXDAT_s4;
        tagError_s5 <= tagError_s4; dataMetaError_s5 <= dataError_s4; l2TagError_s5 <= l2Error_s4;
      end
      chnl_valid_s5_REG   <= chnl_fire_s4;
      chnl_fire_s3_d1 <= chnl_fire_s3;
      chnl_fire_s3_d2 <= chnl_fire_s3_d1;
    end
  end

  // ===== 时序 2: 无复位 RegNext (data_s4/s5 数据通路 + perf 计数, initreg+0 起 0) =====
  always_ff @(posedge clock) begin
    if (task_s3_valid & ~req_drop_s3) data_s4 <= data_s3;
    if (task_s4_valid & ~req_drop_s4) data_s5 <= data_s4;
    io_perf_0_value_REG <= perf0;
    io_perf_0_value_dly2 <= io_perf_0_value_REG;
    io_perf_1_value_REG <= perf1;
    io_perf_1_value_dly2 <= io_perf_1_value_REG;
    io_perf_2_value_REG <= perf2;
    io_perf_2_value_dly2 <= io_perf_2_value_REG;
    io_perf_3_value_REG <= perf3;
    io_perf_3_value_dly2 <= io_perf_3_value_REG;
    io_perf_4_value_REG <= perf4;
    io_perf_4_value_dly2 <= io_perf_4_value_REG;
    io_perf_5_value_REG <= perf5;
    io_perf_5_value_dly2 <= io_perf_5_value_REG;
    io_perf_6_value_REG <= perf6;
    io_perf_6_value_dly2 <= io_perf_6_value_REG;
    io_perf_7_value_REG <= perf7;
    io_perf_7_value_dly2 <= io_perf_7_value_REG;
  end

endmodule
