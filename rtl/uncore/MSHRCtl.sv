// 自动生成 scripts/gen_mshrctl.py —— 勿手改
// xs_MSHRCtl_core: L2 MSHR 控制阵列可读重写核(16 个 MSHR 黑盒 + 手写 glue/仲裁互联)
`timescale 1ns/1ps
module xs_MSHRCtl_core(
  input clock,
  input reset,
  output io_toReqArb_blockA_s1,
  output io_toReqArb_blockB_s1,
  input io_fromMainPipe_mshr_alloc_s3_valid,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit,
  input [30:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag,
  input [8:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set,
  input [2:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty,
  input [1:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients,
  input [1:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch,
  input [2:0] io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr,
  input io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_release,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack,
  input io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct,
  input [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_channel,
  input [8:0] io_fromMainPipe_mshr_alloc_s3_bits_task_set,
  input [30:0] io_fromMainPipe_mshr_alloc_s3_bits_task_tag,
  input [5:0] io_fromMainPipe_mshr_alloc_s3_bits_task_off,
  input [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_alias,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword,
  input [3:0] io_fromMainPipe_mshr_alloc_s3_bits_task_opcode,
  input [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_param,
  input [6:0] io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft,
  input [4:0] io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData,
  input [7:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty,
  input [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients,
  input [1:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch,
  input [2:0] io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr,
  input [10:0] io_fromMainPipe_mshr_alloc_s3_bits_task_srcID,
  input [11:0] io_fromMainPipe_mshr_alloc_s3_bits_task_txnID,
  input [10:0] io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID,
  input [11:0] io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID,
  input [6:0] io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc,
  input io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag,
  output [7:0] io_toMainPipe_mshr_alloc_ptr,
  input io_mshrTask_ready,
  output io_mshrTask_valid,
  output [2:0] io_mshrTask_bits_channel,
  output [2:0] io_mshrTask_bits_txChannel,
  output [8:0] io_mshrTask_bits_set,
  output [30:0] io_mshrTask_bits_tag,
  output [5:0] io_mshrTask_bits_off,
  output [1:0] io_mshrTask_bits_alias,
  output io_mshrTask_bits_isKeyword,
  output [3:0] io_mshrTask_bits_opcode,
  output [2:0] io_mshrTask_bits_param,
  output [2:0] io_mshrTask_bits_size,
  output [6:0] io_mshrTask_bits_sourceId,
  output io_mshrTask_bits_denied,
  output io_mshrTask_bits_corrupt,
  output io_mshrTask_bits_mshrTask,
  output [7:0] io_mshrTask_bits_mshrId,
  output io_mshrTask_bits_aliasTask,
  output io_mshrTask_bits_useProbeData,
  output io_mshrTask_bits_mshrRetry,
  output io_mshrTask_bits_readProbeDataDown,
  output io_mshrTask_bits_fromL2pft,
  output io_mshrTask_bits_dirty,
  output [2:0] io_mshrTask_bits_way,
  output io_mshrTask_bits_meta_dirty,
  output [1:0] io_mshrTask_bits_meta_state,
  output io_mshrTask_bits_meta_clients,
  output [1:0] io_mshrTask_bits_meta_alias,
  output io_mshrTask_bits_meta_prefetch,
  output [2:0] io_mshrTask_bits_meta_prefetchSrc,
  output io_mshrTask_bits_meta_accessed,
  output io_mshrTask_bits_meta_tagErr,
  output io_mshrTask_bits_meta_dataErr,
  output io_mshrTask_bits_metaWen,
  output io_mshrTask_bits_tagWen,
  output io_mshrTask_bits_dsWen,
  output io_mshrTask_bits_replTask,
  output io_mshrTask_bits_cmoTask,
  output [4:0] io_mshrTask_bits_reqSource,
  output io_mshrTask_bits_mergeA,
  output [5:0] io_mshrTask_bits_aMergeTask_off,
  output [1:0] io_mshrTask_bits_aMergeTask_alias,
  output [43:0] io_mshrTask_bits_aMergeTask_vaddr,
  output io_mshrTask_bits_aMergeTask_isKeyword,
  output [2:0] io_mshrTask_bits_aMergeTask_opcode,
  output [2:0] io_mshrTask_bits_aMergeTask_param,
  output [6:0] io_mshrTask_bits_aMergeTask_sourceId,
  output io_mshrTask_bits_aMergeTask_meta_dirty,
  output [1:0] io_mshrTask_bits_aMergeTask_meta_state,
  output io_mshrTask_bits_aMergeTask_meta_clients,
  output [1:0] io_mshrTask_bits_aMergeTask_meta_alias,
  output io_mshrTask_bits_aMergeTask_meta_accessed,
  output io_mshrTask_bits_snpHitRelease,
  output io_mshrTask_bits_snpHitReleaseToInval,
  output io_mshrTask_bits_snpHitReleaseToClean,
  output io_mshrTask_bits_snpHitReleaseWithData,
  output [7:0] io_mshrTask_bits_snpHitReleaseIdx,
  output io_mshrTask_bits_snpHitReleaseMeta_dirty,
  output [1:0] io_mshrTask_bits_snpHitReleaseMeta_state,
  output io_mshrTask_bits_snpHitReleaseMeta_clients,
  output [1:0] io_mshrTask_bits_snpHitReleaseMeta_alias,
  output io_mshrTask_bits_snpHitReleaseMeta_prefetch,
  output [2:0] io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc,
  output io_mshrTask_bits_snpHitReleaseMeta_accessed,
  output io_mshrTask_bits_snpHitReleaseMeta_tagErr,
  output io_mshrTask_bits_snpHitReleaseMeta_dataErr,
  output [10:0] io_mshrTask_bits_tgtID,
  output [11:0] io_mshrTask_bits_txnID,
  output [10:0] io_mshrTask_bits_homeNID,
  output [11:0] io_mshrTask_bits_dbID,
  output [6:0] io_mshrTask_bits_chiOpcode,
  output [2:0] io_mshrTask_bits_resp,
  output [2:0] io_mshrTask_bits_fwdState,
  output io_mshrTask_bits_retToSrc,
  output io_mshrTask_bits_likelyshared,
  output io_mshrTask_bits_expCompAck,
  output io_mshrTask_bits_allowRetry,
  output io_mshrTask_bits_memAttr_allocate,
  output io_mshrTask_bits_memAttr_cacheable,
  output io_mshrTask_bits_memAttr_ewa,
  output io_mshrTask_bits_traceTag,
  output io_mshrTask_bits_dataCheckErr,
  input io_pipeStatusVec_0_valid,
  input io_pipeStatusVec_1_valid,
  input io_toTXREQ_ready,
  output io_toTXREQ_valid,
  output [3:0] io_toTXREQ_bits_qos,
  output [10:0] io_toTXREQ_bits_tgtID,
  output [11:0] io_toTXREQ_bits_txnID,
  output [6:0] io_toTXREQ_bits_opcode,
  output [2:0] io_toTXREQ_bits_size,
  output [47:0] io_toTXREQ_bits_addr,
  output io_toTXREQ_bits_likelyshared,
  output io_toTXREQ_bits_allowRetry,
  output [3:0] io_toTXREQ_bits_pCrdType,
  output io_toTXREQ_bits_memAttr_allocate,
  output io_toTXREQ_bits_memAttr_cacheable,
  output io_toTXREQ_bits_memAttr_ewa,
  output io_toTXREQ_bits_snpAttr,
  output io_toTXREQ_bits_expCompAck,
  input io_toTXRSP_ready,
  output io_toTXRSP_valid,
  output [10:0] io_toTXRSP_bits_tgtID,
  output [11:0] io_toTXRSP_bits_txnID,
  output [4:0] io_toTXRSP_bits_opcode,
  output io_toTXRSP_bits_traceTag,
  input io_toSourceB_ready,
  output io_toSourceB_valid,
  output [2:0] io_toSourceB_bits_opcode,
  output [1:0] io_toSourceB_bits_param,
  output [47:0] io_toSourceB_bits_address,
  output [255:0] io_toSourceB_bits_data,
  input io_grantStatus_0_valid,
  input [8:0] io_grantStatus_0_set,
  input [30:0] io_grantStatus_0_tag,
  input io_grantStatus_1_valid,
  input [8:0] io_grantStatus_1_set,
  input [30:0] io_grantStatus_1_tag,
  input io_grantStatus_2_valid,
  input [8:0] io_grantStatus_2_set,
  input [30:0] io_grantStatus_2_tag,
  input io_grantStatus_3_valid,
  input [8:0] io_grantStatus_3_set,
  input [30:0] io_grantStatus_3_tag,
  input io_grantStatus_4_valid,
  input [8:0] io_grantStatus_4_set,
  input [30:0] io_grantStatus_4_tag,
  input io_grantStatus_5_valid,
  input [8:0] io_grantStatus_5_set,
  input [30:0] io_grantStatus_5_tag,
  input io_grantStatus_6_valid,
  input [8:0] io_grantStatus_6_set,
  input [30:0] io_grantStatus_6_tag,
  input io_grantStatus_7_valid,
  input [8:0] io_grantStatus_7_set,
  input [30:0] io_grantStatus_7_tag,
  input io_grantStatus_8_valid,
  input [8:0] io_grantStatus_8_set,
  input [30:0] io_grantStatus_8_tag,
  input io_grantStatus_9_valid,
  input [8:0] io_grantStatus_9_set,
  input [30:0] io_grantStatus_9_tag,
  input io_grantStatus_10_valid,
  input [8:0] io_grantStatus_10_set,
  input [30:0] io_grantStatus_10_tag,
  input io_grantStatus_11_valid,
  input [8:0] io_grantStatus_11_set,
  input [30:0] io_grantStatus_11_tag,
  input io_grantStatus_12_valid,
  input [8:0] io_grantStatus_12_set,
  input [30:0] io_grantStatus_12_tag,
  input io_grantStatus_13_valid,
  input [8:0] io_grantStatus_13_set,
  input [30:0] io_grantStatus_13_tag,
  input io_grantStatus_14_valid,
  input [8:0] io_grantStatus_14_set,
  input [30:0] io_grantStatus_14_tag,
  input io_grantStatus_15_valid,
  input [8:0] io_grantStatus_15_set,
  input [30:0] io_grantStatus_15_tag,
  input io_resps_sinkC_valid,
  input [8:0] io_resps_sinkC_set,
  input [30:0] io_resps_sinkC_tag,
  input [2:0] io_resps_sinkC_respInfo_opcode,
  input [2:0] io_resps_sinkC_respInfo_param,
  input io_resps_sinkC_respInfo_last,
  input io_resps_sinkC_respInfo_denied,
  input io_resps_sinkC_respInfo_corrupt,
  input io_resps_rxrsp_valid,
  input [7:0] io_resps_rxrsp_mshrId,
  input [6:0] io_resps_rxrsp_respInfo_chiOpcode,
  input [10:0] io_resps_rxrsp_respInfo_srcID,
  input [11:0] io_resps_rxrsp_respInfo_dbID,
  input [2:0] io_resps_rxrsp_respInfo_resp,
  input [3:0] io_resps_rxrsp_respInfo_pCrdType,
  input [1:0] io_resps_rxrsp_respInfo_respErr,
  input io_resps_rxrsp_respInfo_traceTag,
  input io_resps_rxdat_valid,
  input [7:0] io_resps_rxdat_mshrId,
  input io_resps_rxdat_respInfo_last,
  input io_resps_rxdat_respInfo_corrupt,
  input [6:0] io_resps_rxdat_respInfo_chiOpcode,
  input [10:0] io_resps_rxdat_respInfo_homeNID,
  input [11:0] io_resps_rxdat_respInfo_dbID,
  input [2:0] io_resps_rxdat_respInfo_resp,
  input [1:0] io_resps_rxdat_respInfo_respErr,
  input io_resps_rxdat_respInfo_traceTag,
  input io_resps_rxdat_respInfo_dataCheckErr,
  output [7:0] io_releaseBufWriteId,
  input [8:0] io_nestedwb_set,
  input [30:0] io_nestedwb_tag,
  input io_nestedwb_c_set_dirty,
  input io_nestedwb_c_set_tip,
  input io_nestedwb_b_inv_dirty,
  input io_nestedwb_b_toB,
  input io_nestedwb_b_toN,
  input io_nestedwb_b_toClean,
  output io_nestedwbDataId_valid,
  output [7:0] io_nestedwbDataId_bits,
  output io_msInfo_0_valid,
  output [2:0] io_msInfo_0_bits_channel,
  output [8:0] io_msInfo_0_bits_set,
  output [2:0] io_msInfo_0_bits_way,
  output [30:0] io_msInfo_0_bits_reqTag,
  output io_msInfo_0_bits_willFree,
  output io_msInfo_0_bits_aliasTask,
  output io_msInfo_0_bits_needRelease,
  output io_msInfo_0_bits_blockRefill,
  output io_msInfo_0_bits_meta_dirty,
  output [1:0] io_msInfo_0_bits_meta_state,
  output io_msInfo_0_bits_meta_clients,
  output [1:0] io_msInfo_0_bits_meta_alias,
  output io_msInfo_0_bits_meta_prefetch,
  output [2:0] io_msInfo_0_bits_meta_prefetchSrc,
  output io_msInfo_0_bits_meta_accessed,
  output io_msInfo_0_bits_meta_tagErr,
  output io_msInfo_0_bits_meta_dataErr,
  output [30:0] io_msInfo_0_bits_metaTag,
  output io_msInfo_0_bits_dirHit,
  output io_msInfo_0_bits_isAcqOrPrefetch,
  output io_msInfo_0_bits_isPrefetch,
  output [2:0] io_msInfo_0_bits_param,
  output io_msInfo_0_bits_mergeA,
  output io_msInfo_0_bits_w_grantfirst,
  output io_msInfo_0_bits_s_release,
  output io_msInfo_0_bits_s_refill,
  output io_msInfo_0_bits_s_cmoresp,
  output io_msInfo_0_bits_s_cmometaw,
  output io_msInfo_0_bits_w_releaseack,
  output io_msInfo_0_bits_w_replResp,
  output io_msInfo_0_bits_w_rprobeacklast,
  output io_msInfo_0_bits_replaceData,
  output io_msInfo_0_bits_releaseToClean,
  output io_msInfo_1_valid,
  output [2:0] io_msInfo_1_bits_channel,
  output [8:0] io_msInfo_1_bits_set,
  output [2:0] io_msInfo_1_bits_way,
  output [30:0] io_msInfo_1_bits_reqTag,
  output io_msInfo_1_bits_willFree,
  output io_msInfo_1_bits_aliasTask,
  output io_msInfo_1_bits_needRelease,
  output io_msInfo_1_bits_blockRefill,
  output io_msInfo_1_bits_meta_dirty,
  output [1:0] io_msInfo_1_bits_meta_state,
  output io_msInfo_1_bits_meta_clients,
  output [1:0] io_msInfo_1_bits_meta_alias,
  output io_msInfo_1_bits_meta_prefetch,
  output [2:0] io_msInfo_1_bits_meta_prefetchSrc,
  output io_msInfo_1_bits_meta_accessed,
  output io_msInfo_1_bits_meta_tagErr,
  output io_msInfo_1_bits_meta_dataErr,
  output [30:0] io_msInfo_1_bits_metaTag,
  output io_msInfo_1_bits_dirHit,
  output io_msInfo_1_bits_isAcqOrPrefetch,
  output io_msInfo_1_bits_isPrefetch,
  output [2:0] io_msInfo_1_bits_param,
  output io_msInfo_1_bits_mergeA,
  output io_msInfo_1_bits_w_grantfirst,
  output io_msInfo_1_bits_s_release,
  output io_msInfo_1_bits_s_refill,
  output io_msInfo_1_bits_s_cmoresp,
  output io_msInfo_1_bits_s_cmometaw,
  output io_msInfo_1_bits_w_releaseack,
  output io_msInfo_1_bits_w_replResp,
  output io_msInfo_1_bits_w_rprobeacklast,
  output io_msInfo_1_bits_replaceData,
  output io_msInfo_1_bits_releaseToClean,
  output io_msInfo_2_valid,
  output [2:0] io_msInfo_2_bits_channel,
  output [8:0] io_msInfo_2_bits_set,
  output [2:0] io_msInfo_2_bits_way,
  output [30:0] io_msInfo_2_bits_reqTag,
  output io_msInfo_2_bits_willFree,
  output io_msInfo_2_bits_aliasTask,
  output io_msInfo_2_bits_needRelease,
  output io_msInfo_2_bits_blockRefill,
  output io_msInfo_2_bits_meta_dirty,
  output [1:0] io_msInfo_2_bits_meta_state,
  output io_msInfo_2_bits_meta_clients,
  output [1:0] io_msInfo_2_bits_meta_alias,
  output io_msInfo_2_bits_meta_prefetch,
  output [2:0] io_msInfo_2_bits_meta_prefetchSrc,
  output io_msInfo_2_bits_meta_accessed,
  output io_msInfo_2_bits_meta_tagErr,
  output io_msInfo_2_bits_meta_dataErr,
  output [30:0] io_msInfo_2_bits_metaTag,
  output io_msInfo_2_bits_dirHit,
  output io_msInfo_2_bits_isAcqOrPrefetch,
  output io_msInfo_2_bits_isPrefetch,
  output [2:0] io_msInfo_2_bits_param,
  output io_msInfo_2_bits_mergeA,
  output io_msInfo_2_bits_w_grantfirst,
  output io_msInfo_2_bits_s_release,
  output io_msInfo_2_bits_s_refill,
  output io_msInfo_2_bits_s_cmoresp,
  output io_msInfo_2_bits_s_cmometaw,
  output io_msInfo_2_bits_w_releaseack,
  output io_msInfo_2_bits_w_replResp,
  output io_msInfo_2_bits_w_rprobeacklast,
  output io_msInfo_2_bits_replaceData,
  output io_msInfo_2_bits_releaseToClean,
  output io_msInfo_3_valid,
  output [2:0] io_msInfo_3_bits_channel,
  output [8:0] io_msInfo_3_bits_set,
  output [2:0] io_msInfo_3_bits_way,
  output [30:0] io_msInfo_3_bits_reqTag,
  output io_msInfo_3_bits_willFree,
  output io_msInfo_3_bits_aliasTask,
  output io_msInfo_3_bits_needRelease,
  output io_msInfo_3_bits_blockRefill,
  output io_msInfo_3_bits_meta_dirty,
  output [1:0] io_msInfo_3_bits_meta_state,
  output io_msInfo_3_bits_meta_clients,
  output [1:0] io_msInfo_3_bits_meta_alias,
  output io_msInfo_3_bits_meta_prefetch,
  output [2:0] io_msInfo_3_bits_meta_prefetchSrc,
  output io_msInfo_3_bits_meta_accessed,
  output io_msInfo_3_bits_meta_tagErr,
  output io_msInfo_3_bits_meta_dataErr,
  output [30:0] io_msInfo_3_bits_metaTag,
  output io_msInfo_3_bits_dirHit,
  output io_msInfo_3_bits_isAcqOrPrefetch,
  output io_msInfo_3_bits_isPrefetch,
  output [2:0] io_msInfo_3_bits_param,
  output io_msInfo_3_bits_mergeA,
  output io_msInfo_3_bits_w_grantfirst,
  output io_msInfo_3_bits_s_release,
  output io_msInfo_3_bits_s_refill,
  output io_msInfo_3_bits_s_cmoresp,
  output io_msInfo_3_bits_s_cmometaw,
  output io_msInfo_3_bits_w_releaseack,
  output io_msInfo_3_bits_w_replResp,
  output io_msInfo_3_bits_w_rprobeacklast,
  output io_msInfo_3_bits_replaceData,
  output io_msInfo_3_bits_releaseToClean,
  output io_msInfo_4_valid,
  output [2:0] io_msInfo_4_bits_channel,
  output [8:0] io_msInfo_4_bits_set,
  output [2:0] io_msInfo_4_bits_way,
  output [30:0] io_msInfo_4_bits_reqTag,
  output io_msInfo_4_bits_willFree,
  output io_msInfo_4_bits_aliasTask,
  output io_msInfo_4_bits_needRelease,
  output io_msInfo_4_bits_blockRefill,
  output io_msInfo_4_bits_meta_dirty,
  output [1:0] io_msInfo_4_bits_meta_state,
  output io_msInfo_4_bits_meta_clients,
  output [1:0] io_msInfo_4_bits_meta_alias,
  output io_msInfo_4_bits_meta_prefetch,
  output [2:0] io_msInfo_4_bits_meta_prefetchSrc,
  output io_msInfo_4_bits_meta_accessed,
  output io_msInfo_4_bits_meta_tagErr,
  output io_msInfo_4_bits_meta_dataErr,
  output [30:0] io_msInfo_4_bits_metaTag,
  output io_msInfo_4_bits_dirHit,
  output io_msInfo_4_bits_isAcqOrPrefetch,
  output io_msInfo_4_bits_isPrefetch,
  output [2:0] io_msInfo_4_bits_param,
  output io_msInfo_4_bits_mergeA,
  output io_msInfo_4_bits_w_grantfirst,
  output io_msInfo_4_bits_s_release,
  output io_msInfo_4_bits_s_refill,
  output io_msInfo_4_bits_s_cmoresp,
  output io_msInfo_4_bits_s_cmometaw,
  output io_msInfo_4_bits_w_releaseack,
  output io_msInfo_4_bits_w_replResp,
  output io_msInfo_4_bits_w_rprobeacklast,
  output io_msInfo_4_bits_replaceData,
  output io_msInfo_4_bits_releaseToClean,
  output io_msInfo_5_valid,
  output [2:0] io_msInfo_5_bits_channel,
  output [8:0] io_msInfo_5_bits_set,
  output [2:0] io_msInfo_5_bits_way,
  output [30:0] io_msInfo_5_bits_reqTag,
  output io_msInfo_5_bits_willFree,
  output io_msInfo_5_bits_aliasTask,
  output io_msInfo_5_bits_needRelease,
  output io_msInfo_5_bits_blockRefill,
  output io_msInfo_5_bits_meta_dirty,
  output [1:0] io_msInfo_5_bits_meta_state,
  output io_msInfo_5_bits_meta_clients,
  output [1:0] io_msInfo_5_bits_meta_alias,
  output io_msInfo_5_bits_meta_prefetch,
  output [2:0] io_msInfo_5_bits_meta_prefetchSrc,
  output io_msInfo_5_bits_meta_accessed,
  output io_msInfo_5_bits_meta_tagErr,
  output io_msInfo_5_bits_meta_dataErr,
  output [30:0] io_msInfo_5_bits_metaTag,
  output io_msInfo_5_bits_dirHit,
  output io_msInfo_5_bits_isAcqOrPrefetch,
  output io_msInfo_5_bits_isPrefetch,
  output [2:0] io_msInfo_5_bits_param,
  output io_msInfo_5_bits_mergeA,
  output io_msInfo_5_bits_w_grantfirst,
  output io_msInfo_5_bits_s_release,
  output io_msInfo_5_bits_s_refill,
  output io_msInfo_5_bits_s_cmoresp,
  output io_msInfo_5_bits_s_cmometaw,
  output io_msInfo_5_bits_w_releaseack,
  output io_msInfo_5_bits_w_replResp,
  output io_msInfo_5_bits_w_rprobeacklast,
  output io_msInfo_5_bits_replaceData,
  output io_msInfo_5_bits_releaseToClean,
  output io_msInfo_6_valid,
  output [2:0] io_msInfo_6_bits_channel,
  output [8:0] io_msInfo_6_bits_set,
  output [2:0] io_msInfo_6_bits_way,
  output [30:0] io_msInfo_6_bits_reqTag,
  output io_msInfo_6_bits_willFree,
  output io_msInfo_6_bits_aliasTask,
  output io_msInfo_6_bits_needRelease,
  output io_msInfo_6_bits_blockRefill,
  output io_msInfo_6_bits_meta_dirty,
  output [1:0] io_msInfo_6_bits_meta_state,
  output io_msInfo_6_bits_meta_clients,
  output [1:0] io_msInfo_6_bits_meta_alias,
  output io_msInfo_6_bits_meta_prefetch,
  output [2:0] io_msInfo_6_bits_meta_prefetchSrc,
  output io_msInfo_6_bits_meta_accessed,
  output io_msInfo_6_bits_meta_tagErr,
  output io_msInfo_6_bits_meta_dataErr,
  output [30:0] io_msInfo_6_bits_metaTag,
  output io_msInfo_6_bits_dirHit,
  output io_msInfo_6_bits_isAcqOrPrefetch,
  output io_msInfo_6_bits_isPrefetch,
  output [2:0] io_msInfo_6_bits_param,
  output io_msInfo_6_bits_mergeA,
  output io_msInfo_6_bits_w_grantfirst,
  output io_msInfo_6_bits_s_release,
  output io_msInfo_6_bits_s_refill,
  output io_msInfo_6_bits_s_cmoresp,
  output io_msInfo_6_bits_s_cmometaw,
  output io_msInfo_6_bits_w_releaseack,
  output io_msInfo_6_bits_w_replResp,
  output io_msInfo_6_bits_w_rprobeacklast,
  output io_msInfo_6_bits_replaceData,
  output io_msInfo_6_bits_releaseToClean,
  output io_msInfo_7_valid,
  output [2:0] io_msInfo_7_bits_channel,
  output [8:0] io_msInfo_7_bits_set,
  output [2:0] io_msInfo_7_bits_way,
  output [30:0] io_msInfo_7_bits_reqTag,
  output io_msInfo_7_bits_willFree,
  output io_msInfo_7_bits_aliasTask,
  output io_msInfo_7_bits_needRelease,
  output io_msInfo_7_bits_blockRefill,
  output io_msInfo_7_bits_meta_dirty,
  output [1:0] io_msInfo_7_bits_meta_state,
  output io_msInfo_7_bits_meta_clients,
  output [1:0] io_msInfo_7_bits_meta_alias,
  output io_msInfo_7_bits_meta_prefetch,
  output [2:0] io_msInfo_7_bits_meta_prefetchSrc,
  output io_msInfo_7_bits_meta_accessed,
  output io_msInfo_7_bits_meta_tagErr,
  output io_msInfo_7_bits_meta_dataErr,
  output [30:0] io_msInfo_7_bits_metaTag,
  output io_msInfo_7_bits_dirHit,
  output io_msInfo_7_bits_isAcqOrPrefetch,
  output io_msInfo_7_bits_isPrefetch,
  output [2:0] io_msInfo_7_bits_param,
  output io_msInfo_7_bits_mergeA,
  output io_msInfo_7_bits_w_grantfirst,
  output io_msInfo_7_bits_s_release,
  output io_msInfo_7_bits_s_refill,
  output io_msInfo_7_bits_s_cmoresp,
  output io_msInfo_7_bits_s_cmometaw,
  output io_msInfo_7_bits_w_releaseack,
  output io_msInfo_7_bits_w_replResp,
  output io_msInfo_7_bits_w_rprobeacklast,
  output io_msInfo_7_bits_replaceData,
  output io_msInfo_7_bits_releaseToClean,
  output io_msInfo_8_valid,
  output [2:0] io_msInfo_8_bits_channel,
  output [8:0] io_msInfo_8_bits_set,
  output [2:0] io_msInfo_8_bits_way,
  output [30:0] io_msInfo_8_bits_reqTag,
  output io_msInfo_8_bits_willFree,
  output io_msInfo_8_bits_aliasTask,
  output io_msInfo_8_bits_needRelease,
  output io_msInfo_8_bits_blockRefill,
  output io_msInfo_8_bits_meta_dirty,
  output [1:0] io_msInfo_8_bits_meta_state,
  output io_msInfo_8_bits_meta_clients,
  output [1:0] io_msInfo_8_bits_meta_alias,
  output io_msInfo_8_bits_meta_prefetch,
  output [2:0] io_msInfo_8_bits_meta_prefetchSrc,
  output io_msInfo_8_bits_meta_accessed,
  output io_msInfo_8_bits_meta_tagErr,
  output io_msInfo_8_bits_meta_dataErr,
  output [30:0] io_msInfo_8_bits_metaTag,
  output io_msInfo_8_bits_dirHit,
  output io_msInfo_8_bits_isAcqOrPrefetch,
  output io_msInfo_8_bits_isPrefetch,
  output [2:0] io_msInfo_8_bits_param,
  output io_msInfo_8_bits_mergeA,
  output io_msInfo_8_bits_w_grantfirst,
  output io_msInfo_8_bits_s_release,
  output io_msInfo_8_bits_s_refill,
  output io_msInfo_8_bits_s_cmoresp,
  output io_msInfo_8_bits_s_cmometaw,
  output io_msInfo_8_bits_w_releaseack,
  output io_msInfo_8_bits_w_replResp,
  output io_msInfo_8_bits_w_rprobeacklast,
  output io_msInfo_8_bits_replaceData,
  output io_msInfo_8_bits_releaseToClean,
  output io_msInfo_9_valid,
  output [2:0] io_msInfo_9_bits_channel,
  output [8:0] io_msInfo_9_bits_set,
  output [2:0] io_msInfo_9_bits_way,
  output [30:0] io_msInfo_9_bits_reqTag,
  output io_msInfo_9_bits_willFree,
  output io_msInfo_9_bits_aliasTask,
  output io_msInfo_9_bits_needRelease,
  output io_msInfo_9_bits_blockRefill,
  output io_msInfo_9_bits_meta_dirty,
  output [1:0] io_msInfo_9_bits_meta_state,
  output io_msInfo_9_bits_meta_clients,
  output [1:0] io_msInfo_9_bits_meta_alias,
  output io_msInfo_9_bits_meta_prefetch,
  output [2:0] io_msInfo_9_bits_meta_prefetchSrc,
  output io_msInfo_9_bits_meta_accessed,
  output io_msInfo_9_bits_meta_tagErr,
  output io_msInfo_9_bits_meta_dataErr,
  output [30:0] io_msInfo_9_bits_metaTag,
  output io_msInfo_9_bits_dirHit,
  output io_msInfo_9_bits_isAcqOrPrefetch,
  output io_msInfo_9_bits_isPrefetch,
  output [2:0] io_msInfo_9_bits_param,
  output io_msInfo_9_bits_mergeA,
  output io_msInfo_9_bits_w_grantfirst,
  output io_msInfo_9_bits_s_release,
  output io_msInfo_9_bits_s_refill,
  output io_msInfo_9_bits_s_cmoresp,
  output io_msInfo_9_bits_s_cmometaw,
  output io_msInfo_9_bits_w_releaseack,
  output io_msInfo_9_bits_w_replResp,
  output io_msInfo_9_bits_w_rprobeacklast,
  output io_msInfo_9_bits_replaceData,
  output io_msInfo_9_bits_releaseToClean,
  output io_msInfo_10_valid,
  output [2:0] io_msInfo_10_bits_channel,
  output [8:0] io_msInfo_10_bits_set,
  output [2:0] io_msInfo_10_bits_way,
  output [30:0] io_msInfo_10_bits_reqTag,
  output io_msInfo_10_bits_willFree,
  output io_msInfo_10_bits_aliasTask,
  output io_msInfo_10_bits_needRelease,
  output io_msInfo_10_bits_blockRefill,
  output io_msInfo_10_bits_meta_dirty,
  output [1:0] io_msInfo_10_bits_meta_state,
  output io_msInfo_10_bits_meta_clients,
  output [1:0] io_msInfo_10_bits_meta_alias,
  output io_msInfo_10_bits_meta_prefetch,
  output [2:0] io_msInfo_10_bits_meta_prefetchSrc,
  output io_msInfo_10_bits_meta_accessed,
  output io_msInfo_10_bits_meta_tagErr,
  output io_msInfo_10_bits_meta_dataErr,
  output [30:0] io_msInfo_10_bits_metaTag,
  output io_msInfo_10_bits_dirHit,
  output io_msInfo_10_bits_isAcqOrPrefetch,
  output io_msInfo_10_bits_isPrefetch,
  output [2:0] io_msInfo_10_bits_param,
  output io_msInfo_10_bits_mergeA,
  output io_msInfo_10_bits_w_grantfirst,
  output io_msInfo_10_bits_s_release,
  output io_msInfo_10_bits_s_refill,
  output io_msInfo_10_bits_s_cmoresp,
  output io_msInfo_10_bits_s_cmometaw,
  output io_msInfo_10_bits_w_releaseack,
  output io_msInfo_10_bits_w_replResp,
  output io_msInfo_10_bits_w_rprobeacklast,
  output io_msInfo_10_bits_replaceData,
  output io_msInfo_10_bits_releaseToClean,
  output io_msInfo_11_valid,
  output [2:0] io_msInfo_11_bits_channel,
  output [8:0] io_msInfo_11_bits_set,
  output [2:0] io_msInfo_11_bits_way,
  output [30:0] io_msInfo_11_bits_reqTag,
  output io_msInfo_11_bits_willFree,
  output io_msInfo_11_bits_aliasTask,
  output io_msInfo_11_bits_needRelease,
  output io_msInfo_11_bits_blockRefill,
  output io_msInfo_11_bits_meta_dirty,
  output [1:0] io_msInfo_11_bits_meta_state,
  output io_msInfo_11_bits_meta_clients,
  output [1:0] io_msInfo_11_bits_meta_alias,
  output io_msInfo_11_bits_meta_prefetch,
  output [2:0] io_msInfo_11_bits_meta_prefetchSrc,
  output io_msInfo_11_bits_meta_accessed,
  output io_msInfo_11_bits_meta_tagErr,
  output io_msInfo_11_bits_meta_dataErr,
  output [30:0] io_msInfo_11_bits_metaTag,
  output io_msInfo_11_bits_dirHit,
  output io_msInfo_11_bits_isAcqOrPrefetch,
  output io_msInfo_11_bits_isPrefetch,
  output [2:0] io_msInfo_11_bits_param,
  output io_msInfo_11_bits_mergeA,
  output io_msInfo_11_bits_w_grantfirst,
  output io_msInfo_11_bits_s_release,
  output io_msInfo_11_bits_s_refill,
  output io_msInfo_11_bits_s_cmoresp,
  output io_msInfo_11_bits_s_cmometaw,
  output io_msInfo_11_bits_w_releaseack,
  output io_msInfo_11_bits_w_replResp,
  output io_msInfo_11_bits_w_rprobeacklast,
  output io_msInfo_11_bits_replaceData,
  output io_msInfo_11_bits_releaseToClean,
  output io_msInfo_12_valid,
  output [2:0] io_msInfo_12_bits_channel,
  output [8:0] io_msInfo_12_bits_set,
  output [2:0] io_msInfo_12_bits_way,
  output [30:0] io_msInfo_12_bits_reqTag,
  output io_msInfo_12_bits_willFree,
  output io_msInfo_12_bits_aliasTask,
  output io_msInfo_12_bits_needRelease,
  output io_msInfo_12_bits_blockRefill,
  output io_msInfo_12_bits_meta_dirty,
  output [1:0] io_msInfo_12_bits_meta_state,
  output io_msInfo_12_bits_meta_clients,
  output [1:0] io_msInfo_12_bits_meta_alias,
  output io_msInfo_12_bits_meta_prefetch,
  output [2:0] io_msInfo_12_bits_meta_prefetchSrc,
  output io_msInfo_12_bits_meta_accessed,
  output io_msInfo_12_bits_meta_tagErr,
  output io_msInfo_12_bits_meta_dataErr,
  output [30:0] io_msInfo_12_bits_metaTag,
  output io_msInfo_12_bits_dirHit,
  output io_msInfo_12_bits_isAcqOrPrefetch,
  output io_msInfo_12_bits_isPrefetch,
  output [2:0] io_msInfo_12_bits_param,
  output io_msInfo_12_bits_mergeA,
  output io_msInfo_12_bits_w_grantfirst,
  output io_msInfo_12_bits_s_release,
  output io_msInfo_12_bits_s_refill,
  output io_msInfo_12_bits_s_cmoresp,
  output io_msInfo_12_bits_s_cmometaw,
  output io_msInfo_12_bits_w_releaseack,
  output io_msInfo_12_bits_w_replResp,
  output io_msInfo_12_bits_w_rprobeacklast,
  output io_msInfo_12_bits_replaceData,
  output io_msInfo_12_bits_releaseToClean,
  output io_msInfo_13_valid,
  output [2:0] io_msInfo_13_bits_channel,
  output [8:0] io_msInfo_13_bits_set,
  output [2:0] io_msInfo_13_bits_way,
  output [30:0] io_msInfo_13_bits_reqTag,
  output io_msInfo_13_bits_willFree,
  output io_msInfo_13_bits_aliasTask,
  output io_msInfo_13_bits_needRelease,
  output io_msInfo_13_bits_blockRefill,
  output io_msInfo_13_bits_meta_dirty,
  output [1:0] io_msInfo_13_bits_meta_state,
  output io_msInfo_13_bits_meta_clients,
  output [1:0] io_msInfo_13_bits_meta_alias,
  output io_msInfo_13_bits_meta_prefetch,
  output [2:0] io_msInfo_13_bits_meta_prefetchSrc,
  output io_msInfo_13_bits_meta_accessed,
  output io_msInfo_13_bits_meta_tagErr,
  output io_msInfo_13_bits_meta_dataErr,
  output [30:0] io_msInfo_13_bits_metaTag,
  output io_msInfo_13_bits_dirHit,
  output io_msInfo_13_bits_isAcqOrPrefetch,
  output io_msInfo_13_bits_isPrefetch,
  output [2:0] io_msInfo_13_bits_param,
  output io_msInfo_13_bits_mergeA,
  output io_msInfo_13_bits_w_grantfirst,
  output io_msInfo_13_bits_s_release,
  output io_msInfo_13_bits_s_refill,
  output io_msInfo_13_bits_s_cmoresp,
  output io_msInfo_13_bits_s_cmometaw,
  output io_msInfo_13_bits_w_releaseack,
  output io_msInfo_13_bits_w_replResp,
  output io_msInfo_13_bits_w_rprobeacklast,
  output io_msInfo_13_bits_replaceData,
  output io_msInfo_13_bits_releaseToClean,
  output io_msInfo_14_valid,
  output [2:0] io_msInfo_14_bits_channel,
  output [8:0] io_msInfo_14_bits_set,
  output [2:0] io_msInfo_14_bits_way,
  output [30:0] io_msInfo_14_bits_reqTag,
  output io_msInfo_14_bits_willFree,
  output io_msInfo_14_bits_aliasTask,
  output io_msInfo_14_bits_needRelease,
  output io_msInfo_14_bits_blockRefill,
  output io_msInfo_14_bits_meta_dirty,
  output [1:0] io_msInfo_14_bits_meta_state,
  output io_msInfo_14_bits_meta_clients,
  output [1:0] io_msInfo_14_bits_meta_alias,
  output io_msInfo_14_bits_meta_prefetch,
  output [2:0] io_msInfo_14_bits_meta_prefetchSrc,
  output io_msInfo_14_bits_meta_accessed,
  output io_msInfo_14_bits_meta_tagErr,
  output io_msInfo_14_bits_meta_dataErr,
  output [30:0] io_msInfo_14_bits_metaTag,
  output io_msInfo_14_bits_dirHit,
  output io_msInfo_14_bits_isAcqOrPrefetch,
  output io_msInfo_14_bits_isPrefetch,
  output [2:0] io_msInfo_14_bits_param,
  output io_msInfo_14_bits_mergeA,
  output io_msInfo_14_bits_w_grantfirst,
  output io_msInfo_14_bits_s_release,
  output io_msInfo_14_bits_s_refill,
  output io_msInfo_14_bits_s_cmoresp,
  output io_msInfo_14_bits_s_cmometaw,
  output io_msInfo_14_bits_w_releaseack,
  output io_msInfo_14_bits_w_replResp,
  output io_msInfo_14_bits_w_rprobeacklast,
  output io_msInfo_14_bits_replaceData,
  output io_msInfo_14_bits_releaseToClean,
  output io_msInfo_15_valid,
  output [2:0] io_msInfo_15_bits_channel,
  output [8:0] io_msInfo_15_bits_set,
  output [2:0] io_msInfo_15_bits_way,
  output [30:0] io_msInfo_15_bits_reqTag,
  output io_msInfo_15_bits_willFree,
  output io_msInfo_15_bits_aliasTask,
  output io_msInfo_15_bits_needRelease,
  output io_msInfo_15_bits_blockRefill,
  output io_msInfo_15_bits_meta_dirty,
  output [1:0] io_msInfo_15_bits_meta_state,
  output io_msInfo_15_bits_meta_clients,
  output [1:0] io_msInfo_15_bits_meta_alias,
  output io_msInfo_15_bits_meta_prefetch,
  output [2:0] io_msInfo_15_bits_meta_prefetchSrc,
  output io_msInfo_15_bits_meta_accessed,
  output io_msInfo_15_bits_meta_tagErr,
  output io_msInfo_15_bits_meta_dataErr,
  output [30:0] io_msInfo_15_bits_metaTag,
  output io_msInfo_15_bits_dirHit,
  output io_msInfo_15_bits_isAcqOrPrefetch,
  output io_msInfo_15_bits_isPrefetch,
  output [2:0] io_msInfo_15_bits_param,
  output io_msInfo_15_bits_mergeA,
  output io_msInfo_15_bits_w_grantfirst,
  output io_msInfo_15_bits_s_release,
  output io_msInfo_15_bits_s_refill,
  output io_msInfo_15_bits_s_cmoresp,
  output io_msInfo_15_bits_s_cmometaw,
  output io_msInfo_15_bits_w_releaseack,
  output io_msInfo_15_bits_w_replResp,
  output io_msInfo_15_bits_w_rprobeacklast,
  output io_msInfo_15_bits_replaceData,
  output io_msInfo_15_bits_releaseToClean,
  input io_aMergeTask_valid,
  input [7:0] io_aMergeTask_bits_id,
  input [5:0] io_aMergeTask_bits_task_off,
  input [1:0] io_aMergeTask_bits_task_alias,
  input [43:0] io_aMergeTask_bits_task_vaddr,
  input io_aMergeTask_bits_task_isKeyword,
  input [3:0] io_aMergeTask_bits_task_opcode,
  input [2:0] io_aMergeTask_bits_task_param,
  input [6:0] io_aMergeTask_bits_task_sourceId,
  input io_replResp_valid,
  input [30:0] io_replResp_bits_tag,
  input [2:0] io_replResp_bits_way,
  input io_replResp_bits_meta_dirty,
  input [1:0] io_replResp_bits_meta_state,
  input io_replResp_bits_meta_clients,
  input [1:0] io_replResp_bits_meta_alias,
  input io_replResp_bits_meta_prefetch,
  input [2:0] io_replResp_bits_meta_prefetchSrc,
  input io_replResp_bits_meta_accessed,
  input io_replResp_bits_meta_tagErr,
  input io_replResp_bits_meta_dataErr,
  input [7:0] io_replResp_bits_mshrId,
  input io_replResp_bits_retry,
  output io_msStatus_0_valid,
  output [2:0] io_msStatus_0_bits_channel,
  output [8:0] io_msStatus_0_bits_set,
  output [30:0] io_msStatus_0_bits_reqTag,
  output io_msStatus_0_bits_is_miss,
  output io_msStatus_0_bits_is_prefetch,
  output io_msStatus_1_valid,
  output [2:0] io_msStatus_1_bits_channel,
  output [8:0] io_msStatus_1_bits_set,
  output [30:0] io_msStatus_1_bits_reqTag,
  output io_msStatus_1_bits_is_miss,
  output io_msStatus_1_bits_is_prefetch,
  output io_msStatus_2_valid,
  output [2:0] io_msStatus_2_bits_channel,
  output [8:0] io_msStatus_2_bits_set,
  output [30:0] io_msStatus_2_bits_reqTag,
  output io_msStatus_2_bits_is_miss,
  output io_msStatus_2_bits_is_prefetch,
  output io_msStatus_3_valid,
  output [2:0] io_msStatus_3_bits_channel,
  output [8:0] io_msStatus_3_bits_set,
  output [30:0] io_msStatus_3_bits_reqTag,
  output io_msStatus_3_bits_is_miss,
  output io_msStatus_3_bits_is_prefetch,
  output io_msStatus_4_valid,
  output [2:0] io_msStatus_4_bits_channel,
  output [8:0] io_msStatus_4_bits_set,
  output [30:0] io_msStatus_4_bits_reqTag,
  output io_msStatus_4_bits_is_miss,
  output io_msStatus_4_bits_is_prefetch,
  output io_msStatus_5_valid,
  output [2:0] io_msStatus_5_bits_channel,
  output [8:0] io_msStatus_5_bits_set,
  output [30:0] io_msStatus_5_bits_reqTag,
  output io_msStatus_5_bits_is_miss,
  output io_msStatus_5_bits_is_prefetch,
  output io_msStatus_6_valid,
  output [2:0] io_msStatus_6_bits_channel,
  output [8:0] io_msStatus_6_bits_set,
  output [30:0] io_msStatus_6_bits_reqTag,
  output io_msStatus_6_bits_is_miss,
  output io_msStatus_6_bits_is_prefetch,
  output io_msStatus_7_valid,
  output [2:0] io_msStatus_7_bits_channel,
  output [8:0] io_msStatus_7_bits_set,
  output [30:0] io_msStatus_7_bits_reqTag,
  output io_msStatus_7_bits_is_miss,
  output io_msStatus_7_bits_is_prefetch,
  output io_msStatus_8_valid,
  output [2:0] io_msStatus_8_bits_channel,
  output [8:0] io_msStatus_8_bits_set,
  output [30:0] io_msStatus_8_bits_reqTag,
  output io_msStatus_8_bits_is_miss,
  output io_msStatus_8_bits_is_prefetch,
  output io_msStatus_9_valid,
  output [2:0] io_msStatus_9_bits_channel,
  output [8:0] io_msStatus_9_bits_set,
  output [30:0] io_msStatus_9_bits_reqTag,
  output io_msStatus_9_bits_is_miss,
  output io_msStatus_9_bits_is_prefetch,
  output io_msStatus_10_valid,
  output [2:0] io_msStatus_10_bits_channel,
  output [8:0] io_msStatus_10_bits_set,
  output [30:0] io_msStatus_10_bits_reqTag,
  output io_msStatus_10_bits_is_miss,
  output io_msStatus_10_bits_is_prefetch,
  output io_msStatus_11_valid,
  output [2:0] io_msStatus_11_bits_channel,
  output [8:0] io_msStatus_11_bits_set,
  output [30:0] io_msStatus_11_bits_reqTag,
  output io_msStatus_11_bits_is_miss,
  output io_msStatus_11_bits_is_prefetch,
  output io_msStatus_12_valid,
  output [2:0] io_msStatus_12_bits_channel,
  output [8:0] io_msStatus_12_bits_set,
  output [30:0] io_msStatus_12_bits_reqTag,
  output io_msStatus_12_bits_is_miss,
  output io_msStatus_12_bits_is_prefetch,
  output io_msStatus_13_valid,
  output [2:0] io_msStatus_13_bits_channel,
  output [8:0] io_msStatus_13_bits_set,
  output [30:0] io_msStatus_13_bits_reqTag,
  output io_msStatus_13_bits_is_miss,
  output io_msStatus_13_bits_is_prefetch,
  output io_msStatus_14_valid,
  output [2:0] io_msStatus_14_bits_channel,
  output [8:0] io_msStatus_14_bits_set,
  output [30:0] io_msStatus_14_bits_reqTag,
  output io_msStatus_14_bits_is_miss,
  output io_msStatus_14_bits_is_prefetch,
  output io_msStatus_15_valid,
  output [2:0] io_msStatus_15_bits_channel,
  output [8:0] io_msStatus_15_bits_set,
  output [30:0] io_msStatus_15_bits_reqTag,
  output io_msStatus_15_bits_is_miss,
  output io_msStatus_15_bits_is_prefetch,
  output io_pCrd_0_query_valid,
  output [3:0] io_pCrd_0_query_bits_pCrdType,
  output [10:0] io_pCrd_0_query_bits_srcID,
  input io_pCrd_0_grant,
  output io_pCrd_1_query_valid,
  output [3:0] io_pCrd_1_query_bits_pCrdType,
  output [10:0] io_pCrd_1_query_bits_srcID,
  input io_pCrd_1_grant,
  output io_pCrd_2_query_valid,
  output [3:0] io_pCrd_2_query_bits_pCrdType,
  output [10:0] io_pCrd_2_query_bits_srcID,
  input io_pCrd_2_grant,
  output io_pCrd_3_query_valid,
  output [3:0] io_pCrd_3_query_bits_pCrdType,
  output [10:0] io_pCrd_3_query_bits_srcID,
  input io_pCrd_3_grant,
  output io_pCrd_4_query_valid,
  output [3:0] io_pCrd_4_query_bits_pCrdType,
  output [10:0] io_pCrd_4_query_bits_srcID,
  input io_pCrd_4_grant,
  output io_pCrd_5_query_valid,
  output [3:0] io_pCrd_5_query_bits_pCrdType,
  output [10:0] io_pCrd_5_query_bits_srcID,
  input io_pCrd_5_grant,
  output io_pCrd_6_query_valid,
  output [3:0] io_pCrd_6_query_bits_pCrdType,
  output [10:0] io_pCrd_6_query_bits_srcID,
  input io_pCrd_6_grant,
  output io_pCrd_7_query_valid,
  output [3:0] io_pCrd_7_query_bits_pCrdType,
  output [10:0] io_pCrd_7_query_bits_srcID,
  input io_pCrd_7_grant,
  output io_pCrd_8_query_valid,
  output [3:0] io_pCrd_8_query_bits_pCrdType,
  output [10:0] io_pCrd_8_query_bits_srcID,
  input io_pCrd_8_grant,
  output io_pCrd_9_query_valid,
  output [3:0] io_pCrd_9_query_bits_pCrdType,
  output [10:0] io_pCrd_9_query_bits_srcID,
  input io_pCrd_9_grant,
  output io_pCrd_10_query_valid,
  output [3:0] io_pCrd_10_query_bits_pCrdType,
  output [10:0] io_pCrd_10_query_bits_srcID,
  input io_pCrd_10_grant,
  output io_pCrd_11_query_valid,
  output [3:0] io_pCrd_11_query_bits_pCrdType,
  output [10:0] io_pCrd_11_query_bits_srcID,
  input io_pCrd_11_grant,
  output io_pCrd_12_query_valid,
  output [3:0] io_pCrd_12_query_bits_pCrdType,
  output [10:0] io_pCrd_12_query_bits_srcID,
  input io_pCrd_12_grant,
  output io_pCrd_13_query_valid,
  output [3:0] io_pCrd_13_query_bits_pCrdType,
  output [10:0] io_pCrd_13_query_bits_srcID,
  input io_pCrd_13_grant,
  output io_pCrd_14_query_valid,
  output [3:0] io_pCrd_14_query_bits_pCrdType,
  output [10:0] io_pCrd_14_query_bits_srcID,
  input io_pCrd_14_grant,
  output io_pCrd_15_query_valid,
  output [3:0] io_pCrd_15_query_bits_pCrdType,
  output [10:0] io_pCrd_15_query_bits_srcID,
  input io_pCrd_15_grant,
  output io_l2Miss,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_3_value
);

  localparam int MSHRS = 16;

  // ===== 16 个 MSHR 的输出(数组), 经展平/glue 使用 =====
  wire m_io_status_valid [MSHRS];
  wire [2:0] m_io_status_bits_channel [MSHRS];
  wire [8:0] m_io_status_bits_set [MSHRS];
  wire [30:0] m_io_status_bits_reqTag [MSHRS];
  wire [30:0] m_io_status_bits_metaTag [MSHRS];
  wire m_io_status_bits_needsRepl [MSHRS];
  wire m_io_status_bits_w_c_resp [MSHRS];
  wire m_io_status_bits_will_free [MSHRS];
  wire [4:0] m_io_status_bits_reqSource [MSHRS];
  wire m_io_status_bits_is_miss [MSHRS];
  wire m_io_status_bits_is_prefetch [MSHRS];
  wire m_io_msInfo_valid [MSHRS];
  wire [2:0] m_io_msInfo_bits_channel [MSHRS];
  wire [8:0] m_io_msInfo_bits_set [MSHRS];
  wire [2:0] m_io_msInfo_bits_way [MSHRS];
  wire [30:0] m_io_msInfo_bits_reqTag [MSHRS];
  wire m_io_msInfo_bits_willFree [MSHRS];
  wire m_io_msInfo_bits_aliasTask [MSHRS];
  wire m_io_msInfo_bits_needRelease [MSHRS];
  wire m_io_msInfo_bits_blockRefill [MSHRS];
  wire m_io_msInfo_bits_meta_dirty [MSHRS];
  wire [1:0] m_io_msInfo_bits_meta_state [MSHRS];
  wire m_io_msInfo_bits_meta_clients [MSHRS];
  wire [1:0] m_io_msInfo_bits_meta_alias [MSHRS];
  wire m_io_msInfo_bits_meta_prefetch [MSHRS];
  wire [2:0] m_io_msInfo_bits_meta_prefetchSrc [MSHRS];
  wire m_io_msInfo_bits_meta_accessed [MSHRS];
  wire m_io_msInfo_bits_meta_tagErr [MSHRS];
  wire m_io_msInfo_bits_meta_dataErr [MSHRS];
  wire [30:0] m_io_msInfo_bits_metaTag [MSHRS];
  wire m_io_msInfo_bits_dirHit [MSHRS];
  wire m_io_msInfo_bits_isAcqOrPrefetch [MSHRS];
  wire m_io_msInfo_bits_isPrefetch [MSHRS];
  wire [2:0] m_io_msInfo_bits_param [MSHRS];
  wire m_io_msInfo_bits_mergeA [MSHRS];
  wire m_io_msInfo_bits_w_grantfirst [MSHRS];
  wire m_io_msInfo_bits_s_release [MSHRS];
  wire m_io_msInfo_bits_s_refill [MSHRS];
  wire m_io_msInfo_bits_s_cmoresp [MSHRS];
  wire m_io_msInfo_bits_s_cmometaw [MSHRS];
  wire m_io_msInfo_bits_w_releaseack [MSHRS];
  wire m_io_msInfo_bits_w_replResp [MSHRS];
  wire m_io_msInfo_bits_w_rprobeacklast [MSHRS];
  wire m_io_msInfo_bits_replaceData [MSHRS];
  wire m_io_msInfo_bits_releaseToClean [MSHRS];
  wire m_io_tasks_txreq_valid [MSHRS];
  wire [10:0] m_io_tasks_txreq_bits_tgtID [MSHRS];
  wire [11:0] m_io_tasks_txreq_bits_txnID [MSHRS];
  wire [6:0] m_io_tasks_txreq_bits_opcode [MSHRS];
  wire [47:0] m_io_tasks_txreq_bits_addr [MSHRS];
  wire m_io_tasks_txreq_bits_likelyshared [MSHRS];
  wire m_io_tasks_txreq_bits_allowRetry [MSHRS];
  wire [3:0] m_io_tasks_txreq_bits_pCrdType [MSHRS];
  wire m_io_tasks_txreq_bits_memAttr_allocate [MSHRS];
  wire m_io_tasks_txreq_bits_memAttr_ewa [MSHRS];
  wire m_io_tasks_txreq_bits_expCompAck [MSHRS];
  wire m_io_tasks_txrsp_valid [MSHRS];
  wire [10:0] m_io_tasks_txrsp_bits_tgtID [MSHRS];
  wire [11:0] m_io_tasks_txrsp_bits_txnID [MSHRS];
  wire m_io_tasks_txrsp_bits_traceTag [MSHRS];
  wire m_io_tasks_source_b_valid [MSHRS];
  wire [30:0] m_io_tasks_source_b_bits_tag [MSHRS];
  wire [8:0] m_io_tasks_source_b_bits_set [MSHRS];
  wire [1:0] m_io_tasks_source_b_bits_param [MSHRS];
  wire [1:0] m_io_tasks_source_b_bits_alias [MSHRS];
  wire m_io_tasks_mainpipe_valid [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_channel [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_txChannel [MSHRS];
  wire [8:0] m_io_tasks_mainpipe_bits_set [MSHRS];
  wire [30:0] m_io_tasks_mainpipe_bits_tag [MSHRS];
  wire [5:0] m_io_tasks_mainpipe_bits_off [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_alias [MSHRS];
  wire m_io_tasks_mainpipe_bits_isKeyword [MSHRS];
  wire [3:0] m_io_tasks_mainpipe_bits_opcode [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_param [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_size [MSHRS];
  wire [6:0] m_io_tasks_mainpipe_bits_sourceId [MSHRS];
  wire m_io_tasks_mainpipe_bits_denied [MSHRS];
  wire m_io_tasks_mainpipe_bits_corrupt [MSHRS];
  wire [7:0] m_io_tasks_mainpipe_bits_mshrId [MSHRS];
  wire m_io_tasks_mainpipe_bits_aliasTask [MSHRS];
  wire m_io_tasks_mainpipe_bits_useProbeData [MSHRS];
  wire m_io_tasks_mainpipe_bits_mshrRetry [MSHRS];
  wire m_io_tasks_mainpipe_bits_readProbeDataDown [MSHRS];
  wire m_io_tasks_mainpipe_bits_fromL2pft [MSHRS];
  wire m_io_tasks_mainpipe_bits_dirty [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_way [MSHRS];
  wire m_io_tasks_mainpipe_bits_meta_dirty [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_meta_state [MSHRS];
  wire m_io_tasks_mainpipe_bits_meta_clients [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_meta_alias [MSHRS];
  wire m_io_tasks_mainpipe_bits_meta_prefetch [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_meta_prefetchSrc [MSHRS];
  wire m_io_tasks_mainpipe_bits_meta_accessed [MSHRS];
  wire m_io_tasks_mainpipe_bits_meta_tagErr [MSHRS];
  wire m_io_tasks_mainpipe_bits_meta_dataErr [MSHRS];
  wire m_io_tasks_mainpipe_bits_metaWen [MSHRS];
  wire m_io_tasks_mainpipe_bits_tagWen [MSHRS];
  wire m_io_tasks_mainpipe_bits_dsWen [MSHRS];
  wire m_io_tasks_mainpipe_bits_replTask [MSHRS];
  wire m_io_tasks_mainpipe_bits_cmoTask [MSHRS];
  wire [4:0] m_io_tasks_mainpipe_bits_reqSource [MSHRS];
  wire m_io_tasks_mainpipe_bits_mergeA [MSHRS];
  wire [5:0] m_io_tasks_mainpipe_bits_aMergeTask_off [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_aMergeTask_alias [MSHRS];
  wire [43:0] m_io_tasks_mainpipe_bits_aMergeTask_vaddr [MSHRS];
  wire m_io_tasks_mainpipe_bits_aMergeTask_isKeyword [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_aMergeTask_opcode [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_aMergeTask_param [MSHRS];
  wire [6:0] m_io_tasks_mainpipe_bits_aMergeTask_sourceId [MSHRS];
  wire m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_aMergeTask_meta_state [MSHRS];
  wire m_io_tasks_mainpipe_bits_aMergeTask_meta_clients [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_aMergeTask_meta_alias [MSHRS];
  wire m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitRelease [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseToInval [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseToClean [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseWithData [MSHRS];
  wire [7:0] m_io_tasks_mainpipe_bits_snpHitReleaseIdx [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients [MSHRS];
  wire [1:0] m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr [MSHRS];
  wire m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr [MSHRS];
  wire [10:0] m_io_tasks_mainpipe_bits_tgtID [MSHRS];
  wire [11:0] m_io_tasks_mainpipe_bits_txnID [MSHRS];
  wire [10:0] m_io_tasks_mainpipe_bits_homeNID [MSHRS];
  wire [11:0] m_io_tasks_mainpipe_bits_dbID [MSHRS];
  wire [6:0] m_io_tasks_mainpipe_bits_chiOpcode [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_resp [MSHRS];
  wire [2:0] m_io_tasks_mainpipe_bits_fwdState [MSHRS];
  wire m_io_tasks_mainpipe_bits_retToSrc [MSHRS];
  wire m_io_tasks_mainpipe_bits_likelyshared [MSHRS];
  wire m_io_tasks_mainpipe_bits_expCompAck [MSHRS];
  wire m_io_tasks_mainpipe_bits_allowRetry [MSHRS];
  wire m_io_tasks_mainpipe_bits_memAttr_allocate [MSHRS];
  wire m_io_tasks_mainpipe_bits_memAttr_cacheable [MSHRS];
  wire m_io_tasks_mainpipe_bits_memAttr_ewa [MSHRS];
  wire m_io_tasks_mainpipe_bits_traceTag [MSHRS];
  wire m_io_tasks_mainpipe_bits_dataCheckErr [MSHRS];
  wire m_io_nestedwbData [MSHRS];
  wire m_io_pCrd_query_valid [MSHRS];
  wire [3:0] m_io_pCrd_query_bits_pCrdType [MSHRS];
  wire [10:0] m_io_pCrd_query_bits_srcID [MSHRS];
  wire m_acquire_period_valid [MSHRS];
  wire [63:0] m_acquire_period_bits [MSHRS];
  wire m_release_period_valid [MSHRS];
  wire [63:0] m_release_period_bits [MSHRS];

  // pCrd 授权输入去扁平 / 仲裁器回灌 ready / 选择器·SourceB 互联线
  logic io_pCrd_grant_arr [MSHRS];
  wire  txreq_arb_in_ready    [MSHRS];
  wire  txrsp_arb_in_ready    [MSHRS];
  wire  source_b_arb_in_ready [MSHRS];
  wire  mshr_task_arb_in_ready[MSHRS];
  wire [15:0] mshrSelector_out_bits;
  wire        _source_b_arb_io_out_valid;
  wire [30:0] _source_b_arb_io_out_bits_tag;
  wire [8:0]  _source_b_arb_io_out_bits_set;
  wire [2:0]  _source_b_arb_io_out_bits_opcode;
  wire [1:0]  _source_b_arb_io_out_bits_param;
  wire [1:0]  _source_b_arb_io_out_bits_alias;
  wire        _sourceB_io_task_ready;

  // 16 路 one-hot → 4bit 下标(OHToUInt)
  function automatic [3:0] f_oh16_to_uint(input [15:0] oh);
    f_oh16_to_uint[0] = oh[1]|oh[3]|oh[5]|oh[7]|oh[9]|oh[11]|oh[13]|oh[15];
    f_oh16_to_uint[1] = oh[2]|oh[3]|oh[6]|oh[7]|oh[10]|oh[11]|oh[14]|oh[15];
    f_oh16_to_uint[2] = oh[4]|oh[5]|oh[6]|oh[7]|oh[12]|oh[13]|oh[14]|oh[15];
    f_oh16_to_uint[3] = oh[8]|oh[9]|oh[10]|oh[11]|oh[12]|oh[13]|oh[14]|oh[15];
  endfunction
  // 16 路向量优先选择(最低置位下标; 全 0 → 15, 与 ParallelPriorityMux 末项一致)
  function automatic [3:0] f_pri16(input [15:0] sel);
    f_pri16 = 4'd15;
    for (int k = 15; k >= 0; k = k - 1) if (sel[k]) f_pri16 = k[3:0];
  endfunction

  // ===== 分配: 空闲槽 one-hot & 有效 alloc 请求 =====
  wire [15:0] mshrAllocOH =
    mshrSelector_out_bits & {16{io_fromMainPipe_mshr_alloc_s3_valid}};

  // ===== SinkC(release) 按 PA 搜索 MSHR: set 相等 & tag 相等(needsRepl 选 metaTag) =====
  logic [15:0] resp_sinkC_match_vec;
  always_comb
    for (int k = 0; k < MSHRS; k++)
      resp_sinkC_match_vec[k] =
        m_io_status_valid[k] & m_io_status_bits_w_c_resp[k]
        & (io_resps_sinkC_set == m_io_status_bits_set[k])
        & (io_resps_sinkC_tag == (m_io_status_bits_needsRepl[k]
                                   ? m_io_status_bits_metaTag[k]
                                   : m_io_status_bits_reqTag[k]));

  // ===== 16 个 MSHR 例化(黑盒): 广播输入直连, 每实例输入按 mshrId/PA 路由, 输出入数组 =====
  genvar i;
  generate for (i = 0; i < MSHRS; i = i + 1) begin : g_mshr
    MSHR mshrs (
      .clock(clock),
      .reset(reset),
      .io_id(8'(i)),
      .io_status_valid(m_io_status_valid[i]),
      .io_status_bits_channel(m_io_status_bits_channel[i]),
      .io_status_bits_set(m_io_status_bits_set[i]),
      .io_status_bits_reqTag(m_io_status_bits_reqTag[i]),
      .io_status_bits_metaTag(m_io_status_bits_metaTag[i]),
      .io_status_bits_needsRepl(m_io_status_bits_needsRepl[i]),
      .io_status_bits_w_c_resp(m_io_status_bits_w_c_resp[i]),
      .io_status_bits_will_free(m_io_status_bits_will_free[i]),
      .io_status_bits_reqSource(m_io_status_bits_reqSource[i]),
      .io_status_bits_is_miss(m_io_status_bits_is_miss[i]),
      .io_status_bits_is_prefetch(m_io_status_bits_is_prefetch[i]),
      .io_msInfo_valid(m_io_msInfo_valid[i]),
      .io_msInfo_bits_channel(m_io_msInfo_bits_channel[i]),
      .io_msInfo_bits_set(m_io_msInfo_bits_set[i]),
      .io_msInfo_bits_way(m_io_msInfo_bits_way[i]),
      .io_msInfo_bits_reqTag(m_io_msInfo_bits_reqTag[i]),
      .io_msInfo_bits_willFree(m_io_msInfo_bits_willFree[i]),
      .io_msInfo_bits_aliasTask(m_io_msInfo_bits_aliasTask[i]),
      .io_msInfo_bits_needRelease(m_io_msInfo_bits_needRelease[i]),
      .io_msInfo_bits_blockRefill(m_io_msInfo_bits_blockRefill[i]),
      .io_msInfo_bits_meta_dirty(m_io_msInfo_bits_meta_dirty[i]),
      .io_msInfo_bits_meta_state(m_io_msInfo_bits_meta_state[i]),
      .io_msInfo_bits_meta_clients(m_io_msInfo_bits_meta_clients[i]),
      .io_msInfo_bits_meta_alias(m_io_msInfo_bits_meta_alias[i]),
      .io_msInfo_bits_meta_prefetch(m_io_msInfo_bits_meta_prefetch[i]),
      .io_msInfo_bits_meta_prefetchSrc(m_io_msInfo_bits_meta_prefetchSrc[i]),
      .io_msInfo_bits_meta_accessed(m_io_msInfo_bits_meta_accessed[i]),
      .io_msInfo_bits_meta_tagErr(m_io_msInfo_bits_meta_tagErr[i]),
      .io_msInfo_bits_meta_dataErr(m_io_msInfo_bits_meta_dataErr[i]),
      .io_msInfo_bits_metaTag(m_io_msInfo_bits_metaTag[i]),
      .io_msInfo_bits_dirHit(m_io_msInfo_bits_dirHit[i]),
      .io_msInfo_bits_isAcqOrPrefetch(m_io_msInfo_bits_isAcqOrPrefetch[i]),
      .io_msInfo_bits_isPrefetch(m_io_msInfo_bits_isPrefetch[i]),
      .io_msInfo_bits_param(m_io_msInfo_bits_param[i]),
      .io_msInfo_bits_mergeA(m_io_msInfo_bits_mergeA[i]),
      .io_msInfo_bits_w_grantfirst(m_io_msInfo_bits_w_grantfirst[i]),
      .io_msInfo_bits_s_release(m_io_msInfo_bits_s_release[i]),
      .io_msInfo_bits_s_refill(m_io_msInfo_bits_s_refill[i]),
      .io_msInfo_bits_s_cmoresp(m_io_msInfo_bits_s_cmoresp[i]),
      .io_msInfo_bits_s_cmometaw(m_io_msInfo_bits_s_cmometaw[i]),
      .io_msInfo_bits_w_releaseack(m_io_msInfo_bits_w_releaseack[i]),
      .io_msInfo_bits_w_replResp(m_io_msInfo_bits_w_replResp[i]),
      .io_msInfo_bits_w_rprobeacklast(m_io_msInfo_bits_w_rprobeacklast[i]),
      .io_msInfo_bits_replaceData(m_io_msInfo_bits_replaceData[i]),
      .io_msInfo_bits_releaseToClean(m_io_msInfo_bits_releaseToClean[i]),
      .io_alloc_valid(mshrAllocOH[i]),
      .io_alloc_bits_dirResult_hit(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_hit),
      .io_alloc_bits_dirResult_tag(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_tag),
      .io_alloc_bits_dirResult_set(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_set),
      .io_alloc_bits_dirResult_way(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_way),
      .io_alloc_bits_dirResult_meta_dirty(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dirty),
      .io_alloc_bits_dirResult_meta_state(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_state),
      .io_alloc_bits_dirResult_meta_clients(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_clients),
      .io_alloc_bits_dirResult_meta_alias(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_alias),
      .io_alloc_bits_dirResult_meta_prefetch(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetch),
      .io_alloc_bits_dirResult_meta_prefetchSrc(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_prefetchSrc),
      .io_alloc_bits_dirResult_meta_accessed(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_accessed),
      .io_alloc_bits_dirResult_meta_tagErr(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_tagErr),
      .io_alloc_bits_dirResult_meta_dataErr(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_meta_dataErr),
      .io_alloc_bits_dirResult_error(io_fromMainPipe_mshr_alloc_s3_bits_dirResult_error),
      .io_alloc_bits_state_s_acquire(io_fromMainPipe_mshr_alloc_s3_bits_state_s_acquire),
      .io_alloc_bits_state_s_rprobe(io_fromMainPipe_mshr_alloc_s3_bits_state_s_rprobe),
      .io_alloc_bits_state_s_pprobe(io_fromMainPipe_mshr_alloc_s3_bits_state_s_pprobe),
      .io_alloc_bits_state_s_release(io_fromMainPipe_mshr_alloc_s3_bits_state_s_release),
      .io_alloc_bits_state_s_probeack(io_fromMainPipe_mshr_alloc_s3_bits_state_s_probeack),
      .io_alloc_bits_state_s_refill(io_fromMainPipe_mshr_alloc_s3_bits_state_s_refill),
      .io_alloc_bits_state_s_cmoresp(io_fromMainPipe_mshr_alloc_s3_bits_state_s_cmoresp),
      .io_alloc_bits_state_w_rprobeackfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeackfirst),
      .io_alloc_bits_state_w_rprobeacklast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_rprobeacklast),
      .io_alloc_bits_state_w_pprobeackfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeackfirst),
      .io_alloc_bits_state_w_pprobeacklast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_pprobeacklast),
      .io_alloc_bits_state_w_grantfirst(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantfirst),
      .io_alloc_bits_state_w_grantlast(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grantlast),
      .io_alloc_bits_state_w_grant(io_fromMainPipe_mshr_alloc_s3_bits_state_w_grant),
      .io_alloc_bits_state_w_releaseack(io_fromMainPipe_mshr_alloc_s3_bits_state_w_releaseack),
      .io_alloc_bits_state_w_replResp(io_fromMainPipe_mshr_alloc_s3_bits_state_w_replResp),
      .io_alloc_bits_state_s_rcompack(io_fromMainPipe_mshr_alloc_s3_bits_state_s_rcompack),
      .io_alloc_bits_state_s_dct(io_fromMainPipe_mshr_alloc_s3_bits_state_s_dct),
      .io_alloc_bits_task_channel(io_fromMainPipe_mshr_alloc_s3_bits_task_channel),
      .io_alloc_bits_task_set(io_fromMainPipe_mshr_alloc_s3_bits_task_set),
      .io_alloc_bits_task_tag(io_fromMainPipe_mshr_alloc_s3_bits_task_tag),
      .io_alloc_bits_task_off(io_fromMainPipe_mshr_alloc_s3_bits_task_off),
      .io_alloc_bits_task_alias(io_fromMainPipe_mshr_alloc_s3_bits_task_alias),
      .io_alloc_bits_task_isKeyword(io_fromMainPipe_mshr_alloc_s3_bits_task_isKeyword),
      .io_alloc_bits_task_opcode(io_fromMainPipe_mshr_alloc_s3_bits_task_opcode),
      .io_alloc_bits_task_param(io_fromMainPipe_mshr_alloc_s3_bits_task_param),
      .io_alloc_bits_task_sourceId(io_fromMainPipe_mshr_alloc_s3_bits_task_sourceId),
      .io_alloc_bits_task_aliasTask(io_fromMainPipe_mshr_alloc_s3_bits_task_aliasTask),
      .io_alloc_bits_task_fromL2pft(io_fromMainPipe_mshr_alloc_s3_bits_task_fromL2pft),
      .io_alloc_bits_task_reqSource(io_fromMainPipe_mshr_alloc_s3_bits_task_reqSource),
      .io_alloc_bits_task_snpHitRelease(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitRelease),
      .io_alloc_bits_task_snpHitReleaseToInval(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToInval),
      .io_alloc_bits_task_snpHitReleaseToClean(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseToClean),
      .io_alloc_bits_task_snpHitReleaseWithData(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseWithData),
      .io_alloc_bits_task_snpHitReleaseIdx(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseIdx),
      .io_alloc_bits_task_snpHitReleaseMeta_dirty(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dirty),
      .io_alloc_bits_task_snpHitReleaseMeta_state(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_state),
      .io_alloc_bits_task_snpHitReleaseMeta_clients(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_clients),
      .io_alloc_bits_task_snpHitReleaseMeta_alias(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_alias),
      .io_alloc_bits_task_snpHitReleaseMeta_prefetch(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetch),
      .io_alloc_bits_task_snpHitReleaseMeta_prefetchSrc(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_prefetchSrc),
      .io_alloc_bits_task_snpHitReleaseMeta_accessed(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_accessed),
      .io_alloc_bits_task_snpHitReleaseMeta_tagErr(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_tagErr),
      .io_alloc_bits_task_snpHitReleaseMeta_dataErr(io_fromMainPipe_mshr_alloc_s3_bits_task_snpHitReleaseMeta_dataErr),
      .io_alloc_bits_task_srcID(io_fromMainPipe_mshr_alloc_s3_bits_task_srcID),
      .io_alloc_bits_task_txnID(io_fromMainPipe_mshr_alloc_s3_bits_task_txnID),
      .io_alloc_bits_task_fwdNID(io_fromMainPipe_mshr_alloc_s3_bits_task_fwdNID),
      .io_alloc_bits_task_fwdTxnID(io_fromMainPipe_mshr_alloc_s3_bits_task_fwdTxnID),
      .io_alloc_bits_task_chiOpcode(io_fromMainPipe_mshr_alloc_s3_bits_task_chiOpcode),
      .io_alloc_bits_task_retToSrc(io_fromMainPipe_mshr_alloc_s3_bits_task_retToSrc),
      .io_alloc_bits_task_traceTag(io_fromMainPipe_mshr_alloc_s3_bits_task_traceTag),
      .io_tasks_txreq_ready(txreq_arb_in_ready[i]),
      .io_tasks_txreq_valid(m_io_tasks_txreq_valid[i]),
      .io_tasks_txreq_bits_tgtID(m_io_tasks_txreq_bits_tgtID[i]),
      .io_tasks_txreq_bits_txnID(m_io_tasks_txreq_bits_txnID[i]),
      .io_tasks_txreq_bits_opcode(m_io_tasks_txreq_bits_opcode[i]),
      .io_tasks_txreq_bits_addr(m_io_tasks_txreq_bits_addr[i]),
      .io_tasks_txreq_bits_likelyshared(m_io_tasks_txreq_bits_likelyshared[i]),
      .io_tasks_txreq_bits_allowRetry(m_io_tasks_txreq_bits_allowRetry[i]),
      .io_tasks_txreq_bits_pCrdType(m_io_tasks_txreq_bits_pCrdType[i]),
      .io_tasks_txreq_bits_memAttr_allocate(m_io_tasks_txreq_bits_memAttr_allocate[i]),
      .io_tasks_txreq_bits_memAttr_ewa(m_io_tasks_txreq_bits_memAttr_ewa[i]),
      .io_tasks_txreq_bits_expCompAck(m_io_tasks_txreq_bits_expCompAck[i]),
      .io_tasks_txrsp_ready(txrsp_arb_in_ready[i]),
      .io_tasks_txrsp_valid(m_io_tasks_txrsp_valid[i]),
      .io_tasks_txrsp_bits_tgtID(m_io_tasks_txrsp_bits_tgtID[i]),
      .io_tasks_txrsp_bits_txnID(m_io_tasks_txrsp_bits_txnID[i]),
      .io_tasks_txrsp_bits_traceTag(m_io_tasks_txrsp_bits_traceTag[i]),
      .io_tasks_source_b_ready(source_b_arb_in_ready[i]),
      .io_tasks_source_b_valid(m_io_tasks_source_b_valid[i]),
      .io_tasks_source_b_bits_tag(m_io_tasks_source_b_bits_tag[i]),
      .io_tasks_source_b_bits_set(m_io_tasks_source_b_bits_set[i]),
      .io_tasks_source_b_bits_param(m_io_tasks_source_b_bits_param[i]),
      .io_tasks_source_b_bits_alias(m_io_tasks_source_b_bits_alias[i]),
      .io_tasks_mainpipe_ready(mshr_task_arb_in_ready[i]),
      .io_tasks_mainpipe_valid(m_io_tasks_mainpipe_valid[i]),
      .io_tasks_mainpipe_bits_channel(m_io_tasks_mainpipe_bits_channel[i]),
      .io_tasks_mainpipe_bits_txChannel(m_io_tasks_mainpipe_bits_txChannel[i]),
      .io_tasks_mainpipe_bits_set(m_io_tasks_mainpipe_bits_set[i]),
      .io_tasks_mainpipe_bits_tag(m_io_tasks_mainpipe_bits_tag[i]),
      .io_tasks_mainpipe_bits_off(m_io_tasks_mainpipe_bits_off[i]),
      .io_tasks_mainpipe_bits_alias(m_io_tasks_mainpipe_bits_alias[i]),
      .io_tasks_mainpipe_bits_isKeyword(m_io_tasks_mainpipe_bits_isKeyword[i]),
      .io_tasks_mainpipe_bits_opcode(m_io_tasks_mainpipe_bits_opcode[i]),
      .io_tasks_mainpipe_bits_param(m_io_tasks_mainpipe_bits_param[i]),
      .io_tasks_mainpipe_bits_size(m_io_tasks_mainpipe_bits_size[i]),
      .io_tasks_mainpipe_bits_sourceId(m_io_tasks_mainpipe_bits_sourceId[i]),
      .io_tasks_mainpipe_bits_denied(m_io_tasks_mainpipe_bits_denied[i]),
      .io_tasks_mainpipe_bits_corrupt(m_io_tasks_mainpipe_bits_corrupt[i]),
      .io_tasks_mainpipe_bits_mshrId(m_io_tasks_mainpipe_bits_mshrId[i]),
      .io_tasks_mainpipe_bits_aliasTask(m_io_tasks_mainpipe_bits_aliasTask[i]),
      .io_tasks_mainpipe_bits_useProbeData(m_io_tasks_mainpipe_bits_useProbeData[i]),
      .io_tasks_mainpipe_bits_mshrRetry(m_io_tasks_mainpipe_bits_mshrRetry[i]),
      .io_tasks_mainpipe_bits_readProbeDataDown(m_io_tasks_mainpipe_bits_readProbeDataDown[i]),
      .io_tasks_mainpipe_bits_fromL2pft(m_io_tasks_mainpipe_bits_fromL2pft[i]),
      .io_tasks_mainpipe_bits_dirty(m_io_tasks_mainpipe_bits_dirty[i]),
      .io_tasks_mainpipe_bits_way(m_io_tasks_mainpipe_bits_way[i]),
      .io_tasks_mainpipe_bits_meta_dirty(m_io_tasks_mainpipe_bits_meta_dirty[i]),
      .io_tasks_mainpipe_bits_meta_state(m_io_tasks_mainpipe_bits_meta_state[i]),
      .io_tasks_mainpipe_bits_meta_clients(m_io_tasks_mainpipe_bits_meta_clients[i]),
      .io_tasks_mainpipe_bits_meta_alias(m_io_tasks_mainpipe_bits_meta_alias[i]),
      .io_tasks_mainpipe_bits_meta_prefetch(m_io_tasks_mainpipe_bits_meta_prefetch[i]),
      .io_tasks_mainpipe_bits_meta_prefetchSrc(m_io_tasks_mainpipe_bits_meta_prefetchSrc[i]),
      .io_tasks_mainpipe_bits_meta_accessed(m_io_tasks_mainpipe_bits_meta_accessed[i]),
      .io_tasks_mainpipe_bits_meta_tagErr(m_io_tasks_mainpipe_bits_meta_tagErr[i]),
      .io_tasks_mainpipe_bits_meta_dataErr(m_io_tasks_mainpipe_bits_meta_dataErr[i]),
      .io_tasks_mainpipe_bits_metaWen(m_io_tasks_mainpipe_bits_metaWen[i]),
      .io_tasks_mainpipe_bits_tagWen(m_io_tasks_mainpipe_bits_tagWen[i]),
      .io_tasks_mainpipe_bits_dsWen(m_io_tasks_mainpipe_bits_dsWen[i]),
      .io_tasks_mainpipe_bits_replTask(m_io_tasks_mainpipe_bits_replTask[i]),
      .io_tasks_mainpipe_bits_cmoTask(m_io_tasks_mainpipe_bits_cmoTask[i]),
      .io_tasks_mainpipe_bits_reqSource(m_io_tasks_mainpipe_bits_reqSource[i]),
      .io_tasks_mainpipe_bits_mergeA(m_io_tasks_mainpipe_bits_mergeA[i]),
      .io_tasks_mainpipe_bits_aMergeTask_off(m_io_tasks_mainpipe_bits_aMergeTask_off[i]),
      .io_tasks_mainpipe_bits_aMergeTask_alias(m_io_tasks_mainpipe_bits_aMergeTask_alias[i]),
      .io_tasks_mainpipe_bits_aMergeTask_vaddr(m_io_tasks_mainpipe_bits_aMergeTask_vaddr[i]),
      .io_tasks_mainpipe_bits_aMergeTask_isKeyword(m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[i]),
      .io_tasks_mainpipe_bits_aMergeTask_opcode(m_io_tasks_mainpipe_bits_aMergeTask_opcode[i]),
      .io_tasks_mainpipe_bits_aMergeTask_param(m_io_tasks_mainpipe_bits_aMergeTask_param[i]),
      .io_tasks_mainpipe_bits_aMergeTask_sourceId(m_io_tasks_mainpipe_bits_aMergeTask_sourceId[i]),
      .io_tasks_mainpipe_bits_aMergeTask_meta_dirty(m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[i]),
      .io_tasks_mainpipe_bits_aMergeTask_meta_state(m_io_tasks_mainpipe_bits_aMergeTask_meta_state[i]),
      .io_tasks_mainpipe_bits_aMergeTask_meta_clients(m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[i]),
      .io_tasks_mainpipe_bits_aMergeTask_meta_alias(m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[i]),
      .io_tasks_mainpipe_bits_aMergeTask_meta_accessed(m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[i]),
      .io_tasks_mainpipe_bits_snpHitRelease(m_io_tasks_mainpipe_bits_snpHitRelease[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseToInval(m_io_tasks_mainpipe_bits_snpHitReleaseToInval[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseToClean(m_io_tasks_mainpipe_bits_snpHitReleaseToClean[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseWithData(m_io_tasks_mainpipe_bits_snpHitReleaseWithData[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseIdx(m_io_tasks_mainpipe_bits_snpHitReleaseIdx[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_state(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_clients(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_alias(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[i]),
      .io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr(m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[i]),
      .io_tasks_mainpipe_bits_tgtID(m_io_tasks_mainpipe_bits_tgtID[i]),
      .io_tasks_mainpipe_bits_txnID(m_io_tasks_mainpipe_bits_txnID[i]),
      .io_tasks_mainpipe_bits_homeNID(m_io_tasks_mainpipe_bits_homeNID[i]),
      .io_tasks_mainpipe_bits_dbID(m_io_tasks_mainpipe_bits_dbID[i]),
      .io_tasks_mainpipe_bits_chiOpcode(m_io_tasks_mainpipe_bits_chiOpcode[i]),
      .io_tasks_mainpipe_bits_resp(m_io_tasks_mainpipe_bits_resp[i]),
      .io_tasks_mainpipe_bits_fwdState(m_io_tasks_mainpipe_bits_fwdState[i]),
      .io_tasks_mainpipe_bits_retToSrc(m_io_tasks_mainpipe_bits_retToSrc[i]),
      .io_tasks_mainpipe_bits_likelyshared(m_io_tasks_mainpipe_bits_likelyshared[i]),
      .io_tasks_mainpipe_bits_expCompAck(m_io_tasks_mainpipe_bits_expCompAck[i]),
      .io_tasks_mainpipe_bits_allowRetry(m_io_tasks_mainpipe_bits_allowRetry[i]),
      .io_tasks_mainpipe_bits_memAttr_allocate(m_io_tasks_mainpipe_bits_memAttr_allocate[i]),
      .io_tasks_mainpipe_bits_memAttr_cacheable(m_io_tasks_mainpipe_bits_memAttr_cacheable[i]),
      .io_tasks_mainpipe_bits_memAttr_ewa(m_io_tasks_mainpipe_bits_memAttr_ewa[i]),
      .io_tasks_mainpipe_bits_traceTag(m_io_tasks_mainpipe_bits_traceTag[i]),
      .io_tasks_mainpipe_bits_dataCheckErr(m_io_tasks_mainpipe_bits_dataCheckErr[i]),
      .io_resps_sinkC_valid((io_resps_sinkC_valid & resp_sinkC_match_vec[i])),
      .io_resps_sinkC_bits_opcode(io_resps_sinkC_respInfo_opcode),
      .io_resps_sinkC_bits_param(io_resps_sinkC_respInfo_param),
      .io_resps_sinkC_bits_last(io_resps_sinkC_respInfo_last),
      .io_resps_sinkC_bits_denied(io_resps_sinkC_respInfo_denied),
      .io_resps_sinkC_bits_corrupt(io_resps_sinkC_respInfo_corrupt),
      .io_resps_rxrsp_valid((m_io_status_valid[i] & io_resps_rxrsp_valid & (io_resps_rxrsp_mshrId == 8'(i)))),
      .io_resps_rxrsp_bits_chiOpcode(io_resps_rxrsp_respInfo_chiOpcode),
      .io_resps_rxrsp_bits_srcID(io_resps_rxrsp_respInfo_srcID),
      .io_resps_rxrsp_bits_dbID(io_resps_rxrsp_respInfo_dbID),
      .io_resps_rxrsp_bits_resp(io_resps_rxrsp_respInfo_resp),
      .io_resps_rxrsp_bits_pCrdType(io_resps_rxrsp_respInfo_pCrdType),
      .io_resps_rxrsp_bits_respErr(io_resps_rxrsp_respInfo_respErr),
      .io_resps_rxrsp_bits_traceTag(io_resps_rxrsp_respInfo_traceTag),
      .io_resps_rxdat_valid((m_io_status_valid[i] & io_resps_rxdat_valid & (io_resps_rxdat_mshrId == 8'(i)))),
      .io_resps_rxdat_bits_corrupt(io_resps_rxdat_respInfo_corrupt),
      .io_resps_rxdat_bits_chiOpcode(io_resps_rxdat_respInfo_chiOpcode),
      .io_resps_rxdat_bits_homeNID(io_resps_rxdat_respInfo_homeNID),
      .io_resps_rxdat_bits_dbID(io_resps_rxdat_respInfo_dbID),
      .io_resps_rxdat_bits_resp(io_resps_rxdat_respInfo_resp),
      .io_resps_rxdat_bits_respErr(io_resps_rxdat_respInfo_respErr),
      .io_resps_rxdat_bits_traceTag(io_resps_rxdat_respInfo_traceTag),
      .io_resps_rxdat_bits_dataCheckErr(io_resps_rxdat_respInfo_dataCheckErr),
      .io_nestedwb_set(io_nestedwb_set),
      .io_nestedwb_tag(io_nestedwb_tag),
      .io_nestedwb_c_set_dirty(io_nestedwb_c_set_dirty),
      .io_nestedwb_c_set_tip(io_nestedwb_c_set_tip),
      .io_nestedwb_b_inv_dirty(io_nestedwb_b_inv_dirty),
      .io_nestedwb_b_toB(io_nestedwb_b_toB),
      .io_nestedwb_b_toN(io_nestedwb_b_toN),
      .io_nestedwb_b_toClean(io_nestedwb_b_toClean),
      .io_nestedwbData(m_io_nestedwbData[i]),
      .io_aMergeTask_valid((io_aMergeTask_valid & (io_aMergeTask_bits_id == 8'(i)))),
      .io_aMergeTask_bits_off(io_aMergeTask_bits_task_off),
      .io_aMergeTask_bits_alias(io_aMergeTask_bits_task_alias),
      .io_aMergeTask_bits_vaddr(io_aMergeTask_bits_task_vaddr),
      .io_aMergeTask_bits_isKeyword(io_aMergeTask_bits_task_isKeyword),
      .io_aMergeTask_bits_opcode(io_aMergeTask_bits_task_opcode),
      .io_aMergeTask_bits_param(io_aMergeTask_bits_task_param),
      .io_aMergeTask_bits_sourceId(io_aMergeTask_bits_task_sourceId),
      .io_replResp_valid((io_replResp_valid & (io_replResp_bits_mshrId == 8'(i)))),
      .io_replResp_bits_tag(io_replResp_bits_tag),
      .io_replResp_bits_way(io_replResp_bits_way),
      .io_replResp_bits_meta_dirty(io_replResp_bits_meta_dirty),
      .io_replResp_bits_meta_state(io_replResp_bits_meta_state),
      .io_replResp_bits_meta_clients(io_replResp_bits_meta_clients),
      .io_replResp_bits_meta_alias(io_replResp_bits_meta_alias),
      .io_replResp_bits_meta_prefetch(io_replResp_bits_meta_prefetch),
      .io_replResp_bits_meta_prefetchSrc(io_replResp_bits_meta_prefetchSrc),
      .io_replResp_bits_meta_accessed(io_replResp_bits_meta_accessed),
      .io_replResp_bits_meta_tagErr(io_replResp_bits_meta_tagErr),
      .io_replResp_bits_meta_dataErr(io_replResp_bits_meta_dataErr),
      .io_replResp_bits_retry(io_replResp_bits_retry),
      .io_pCrd_query_valid(m_io_pCrd_query_valid[i]),
      .io_pCrd_query_bits_pCrdType(m_io_pCrd_query_bits_pCrdType[i]),
      .io_pCrd_query_bits_srcID(m_io_pCrd_query_bits_srcID[i]),
      .io_pCrd_grant(io_pCrd_grant_arr[i]),
      .acquire_period_valid(m_acquire_period_valid[i]),
      .acquire_period_bits(m_acquire_period_bits[i]),
      .release_period_valid(m_release_period_valid[i]),
      .release_period_bits(m_release_period_bits[i])
    );
  end endgenerate

  // pCrd 授权输入: 扁平端口 → 数组
  assign io_pCrd_grant_arr[0] = io_pCrd_0_grant;
  assign io_pCrd_grant_arr[1] = io_pCrd_1_grant;
  assign io_pCrd_grant_arr[2] = io_pCrd_2_grant;
  assign io_pCrd_grant_arr[3] = io_pCrd_3_grant;
  assign io_pCrd_grant_arr[4] = io_pCrd_4_grant;
  assign io_pCrd_grant_arr[5] = io_pCrd_5_grant;
  assign io_pCrd_grant_arr[6] = io_pCrd_6_grant;
  assign io_pCrd_grant_arr[7] = io_pCrd_7_grant;
  assign io_pCrd_grant_arr[8] = io_pCrd_8_grant;
  assign io_pCrd_grant_arr[9] = io_pCrd_9_grant;
  assign io_pCrd_grant_arr[10] = io_pCrd_10_grant;
  assign io_pCrd_grant_arr[11] = io_pCrd_11_grant;
  assign io_pCrd_grant_arr[12] = io_pCrd_12_grant;
  assign io_pCrd_grant_arr[13] = io_pCrd_13_grant;
  assign io_pCrd_grant_arr[14] = io_pCrd_14_grant;
  assign io_pCrd_grant_arr[15] = io_pCrd_15_grant;

  // ===== 选择器 / 仲裁器 / SourceB 例化(黑盒, 连线从 golden 派生) =====
  MSHRSelector mshrSelector (
    .io_idle_0   (~m_io_status_valid[0]),
    .io_idle_1   (~m_io_status_valid[1]),
    .io_idle_2   (~m_io_status_valid[2]),
    .io_idle_3   (~m_io_status_valid[3]),
    .io_idle_4   (~m_io_status_valid[4]),
    .io_idle_5   (~m_io_status_valid[5]),
    .io_idle_6   (~m_io_status_valid[6]),
    .io_idle_7   (~m_io_status_valid[7]),
    .io_idle_8   (~m_io_status_valid[8]),
    .io_idle_9   (~m_io_status_valid[9]),
    .io_idle_10  (~m_io_status_valid[10]),
    .io_idle_11  (~m_io_status_valid[11]),
    .io_idle_12  (~m_io_status_valid[12]),
    .io_idle_13  (~m_io_status_valid[13]),
    .io_idle_14  (~m_io_status_valid[14]),
    .io_out_bits (mshrSelector_out_bits)
  );

  FastArbiter_4 txreq_arb (
    .clock                          (clock),
    .reset                          (reset),
    .io_in_0_ready                  (txreq_arb_in_ready[0]),
    .io_in_0_valid                  (m_io_tasks_txreq_valid[0]),
    .io_in_0_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[0]),
    .io_in_0_bits_txnID             (m_io_tasks_txreq_bits_txnID[0]),
    .io_in_0_bits_opcode            (m_io_tasks_txreq_bits_opcode[0]),
    .io_in_0_bits_addr              (m_io_tasks_txreq_bits_addr[0]),
    .io_in_0_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[0]),
    .io_in_0_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[0]),
    .io_in_0_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[0]),
    .io_in_0_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[0]),
    .io_in_0_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[0]),
    .io_in_0_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[0]),
    .io_in_1_ready                  (txreq_arb_in_ready[1]),
    .io_in_1_valid                  (m_io_tasks_txreq_valid[1]),
    .io_in_1_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[1]),
    .io_in_1_bits_txnID             (m_io_tasks_txreq_bits_txnID[1]),
    .io_in_1_bits_opcode            (m_io_tasks_txreq_bits_opcode[1]),
    .io_in_1_bits_addr              (m_io_tasks_txreq_bits_addr[1]),
    .io_in_1_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[1]),
    .io_in_1_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[1]),
    .io_in_1_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[1]),
    .io_in_1_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[1]),
    .io_in_1_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[1]),
    .io_in_1_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[1]),
    .io_in_2_ready                  (txreq_arb_in_ready[2]),
    .io_in_2_valid                  (m_io_tasks_txreq_valid[2]),
    .io_in_2_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[2]),
    .io_in_2_bits_txnID             (m_io_tasks_txreq_bits_txnID[2]),
    .io_in_2_bits_opcode            (m_io_tasks_txreq_bits_opcode[2]),
    .io_in_2_bits_addr              (m_io_tasks_txreq_bits_addr[2]),
    .io_in_2_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[2]),
    .io_in_2_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[2]),
    .io_in_2_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[2]),
    .io_in_2_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[2]),
    .io_in_2_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[2]),
    .io_in_2_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[2]),
    .io_in_3_ready                  (txreq_arb_in_ready[3]),
    .io_in_3_valid                  (m_io_tasks_txreq_valid[3]),
    .io_in_3_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[3]),
    .io_in_3_bits_txnID             (m_io_tasks_txreq_bits_txnID[3]),
    .io_in_3_bits_opcode            (m_io_tasks_txreq_bits_opcode[3]),
    .io_in_3_bits_addr              (m_io_tasks_txreq_bits_addr[3]),
    .io_in_3_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[3]),
    .io_in_3_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[3]),
    .io_in_3_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[3]),
    .io_in_3_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[3]),
    .io_in_3_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[3]),
    .io_in_3_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[3]),
    .io_in_4_ready                  (txreq_arb_in_ready[4]),
    .io_in_4_valid                  (m_io_tasks_txreq_valid[4]),
    .io_in_4_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[4]),
    .io_in_4_bits_txnID             (m_io_tasks_txreq_bits_txnID[4]),
    .io_in_4_bits_opcode            (m_io_tasks_txreq_bits_opcode[4]),
    .io_in_4_bits_addr              (m_io_tasks_txreq_bits_addr[4]),
    .io_in_4_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[4]),
    .io_in_4_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[4]),
    .io_in_4_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[4]),
    .io_in_4_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[4]),
    .io_in_4_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[4]),
    .io_in_4_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[4]),
    .io_in_5_ready                  (txreq_arb_in_ready[5]),
    .io_in_5_valid                  (m_io_tasks_txreq_valid[5]),
    .io_in_5_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[5]),
    .io_in_5_bits_txnID             (m_io_tasks_txreq_bits_txnID[5]),
    .io_in_5_bits_opcode            (m_io_tasks_txreq_bits_opcode[5]),
    .io_in_5_bits_addr              (m_io_tasks_txreq_bits_addr[5]),
    .io_in_5_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[5]),
    .io_in_5_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[5]),
    .io_in_5_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[5]),
    .io_in_5_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[5]),
    .io_in_5_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[5]),
    .io_in_5_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[5]),
    .io_in_6_ready                  (txreq_arb_in_ready[6]),
    .io_in_6_valid                  (m_io_tasks_txreq_valid[6]),
    .io_in_6_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[6]),
    .io_in_6_bits_txnID             (m_io_tasks_txreq_bits_txnID[6]),
    .io_in_6_bits_opcode            (m_io_tasks_txreq_bits_opcode[6]),
    .io_in_6_bits_addr              (m_io_tasks_txreq_bits_addr[6]),
    .io_in_6_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[6]),
    .io_in_6_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[6]),
    .io_in_6_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[6]),
    .io_in_6_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[6]),
    .io_in_6_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[6]),
    .io_in_6_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[6]),
    .io_in_7_ready                  (txreq_arb_in_ready[7]),
    .io_in_7_valid                  (m_io_tasks_txreq_valid[7]),
    .io_in_7_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[7]),
    .io_in_7_bits_txnID             (m_io_tasks_txreq_bits_txnID[7]),
    .io_in_7_bits_opcode            (m_io_tasks_txreq_bits_opcode[7]),
    .io_in_7_bits_addr              (m_io_tasks_txreq_bits_addr[7]),
    .io_in_7_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[7]),
    .io_in_7_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[7]),
    .io_in_7_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[7]),
    .io_in_7_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[7]),
    .io_in_7_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[7]),
    .io_in_7_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[7]),
    .io_in_8_ready                  (txreq_arb_in_ready[8]),
    .io_in_8_valid                  (m_io_tasks_txreq_valid[8]),
    .io_in_8_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[8]),
    .io_in_8_bits_txnID             (m_io_tasks_txreq_bits_txnID[8]),
    .io_in_8_bits_opcode            (m_io_tasks_txreq_bits_opcode[8]),
    .io_in_8_bits_addr              (m_io_tasks_txreq_bits_addr[8]),
    .io_in_8_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[8]),
    .io_in_8_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[8]),
    .io_in_8_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[8]),
    .io_in_8_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[8]),
    .io_in_8_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[8]),
    .io_in_8_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[8]),
    .io_in_9_ready                  (txreq_arb_in_ready[9]),
    .io_in_9_valid                  (m_io_tasks_txreq_valid[9]),
    .io_in_9_bits_tgtID             (m_io_tasks_txreq_bits_tgtID[9]),
    .io_in_9_bits_txnID             (m_io_tasks_txreq_bits_txnID[9]),
    .io_in_9_bits_opcode            (m_io_tasks_txreq_bits_opcode[9]),
    .io_in_9_bits_addr              (m_io_tasks_txreq_bits_addr[9]),
    .io_in_9_bits_likelyshared      (m_io_tasks_txreq_bits_likelyshared[9]),
    .io_in_9_bits_allowRetry        (m_io_tasks_txreq_bits_allowRetry[9]),
    .io_in_9_bits_pCrdType          (m_io_tasks_txreq_bits_pCrdType[9]),
    .io_in_9_bits_memAttr_allocate  (m_io_tasks_txreq_bits_memAttr_allocate[9]),
    .io_in_9_bits_memAttr_ewa       (m_io_tasks_txreq_bits_memAttr_ewa[9]),
    .io_in_9_bits_expCompAck        (m_io_tasks_txreq_bits_expCompAck[9]),
    .io_in_10_ready                 (txreq_arb_in_ready[10]),
    .io_in_10_valid                 (m_io_tasks_txreq_valid[10]),
    .io_in_10_bits_tgtID            (m_io_tasks_txreq_bits_tgtID[10]),
    .io_in_10_bits_txnID            (m_io_tasks_txreq_bits_txnID[10]),
    .io_in_10_bits_opcode           (m_io_tasks_txreq_bits_opcode[10]),
    .io_in_10_bits_addr             (m_io_tasks_txreq_bits_addr[10]),
    .io_in_10_bits_likelyshared     (m_io_tasks_txreq_bits_likelyshared[10]),
    .io_in_10_bits_allowRetry       (m_io_tasks_txreq_bits_allowRetry[10]),
    .io_in_10_bits_pCrdType         (m_io_tasks_txreq_bits_pCrdType[10]),
    .io_in_10_bits_memAttr_allocate (m_io_tasks_txreq_bits_memAttr_allocate[10]),
    .io_in_10_bits_memAttr_ewa      (m_io_tasks_txreq_bits_memAttr_ewa[10]),
    .io_in_10_bits_expCompAck       (m_io_tasks_txreq_bits_expCompAck[10]),
    .io_in_11_ready                 (txreq_arb_in_ready[11]),
    .io_in_11_valid                 (m_io_tasks_txreq_valid[11]),
    .io_in_11_bits_tgtID            (m_io_tasks_txreq_bits_tgtID[11]),
    .io_in_11_bits_txnID            (m_io_tasks_txreq_bits_txnID[11]),
    .io_in_11_bits_opcode           (m_io_tasks_txreq_bits_opcode[11]),
    .io_in_11_bits_addr             (m_io_tasks_txreq_bits_addr[11]),
    .io_in_11_bits_likelyshared     (m_io_tasks_txreq_bits_likelyshared[11]),
    .io_in_11_bits_allowRetry       (m_io_tasks_txreq_bits_allowRetry[11]),
    .io_in_11_bits_pCrdType         (m_io_tasks_txreq_bits_pCrdType[11]),
    .io_in_11_bits_memAttr_allocate (m_io_tasks_txreq_bits_memAttr_allocate[11]),
    .io_in_11_bits_memAttr_ewa      (m_io_tasks_txreq_bits_memAttr_ewa[11]),
    .io_in_11_bits_expCompAck       (m_io_tasks_txreq_bits_expCompAck[11]),
    .io_in_12_ready                 (txreq_arb_in_ready[12]),
    .io_in_12_valid                 (m_io_tasks_txreq_valid[12]),
    .io_in_12_bits_tgtID            (m_io_tasks_txreq_bits_tgtID[12]),
    .io_in_12_bits_txnID            (m_io_tasks_txreq_bits_txnID[12]),
    .io_in_12_bits_opcode           (m_io_tasks_txreq_bits_opcode[12]),
    .io_in_12_bits_addr             (m_io_tasks_txreq_bits_addr[12]),
    .io_in_12_bits_likelyshared     (m_io_tasks_txreq_bits_likelyshared[12]),
    .io_in_12_bits_allowRetry       (m_io_tasks_txreq_bits_allowRetry[12]),
    .io_in_12_bits_pCrdType         (m_io_tasks_txreq_bits_pCrdType[12]),
    .io_in_12_bits_memAttr_allocate (m_io_tasks_txreq_bits_memAttr_allocate[12]),
    .io_in_12_bits_memAttr_ewa      (m_io_tasks_txreq_bits_memAttr_ewa[12]),
    .io_in_12_bits_expCompAck       (m_io_tasks_txreq_bits_expCompAck[12]),
    .io_in_13_ready                 (txreq_arb_in_ready[13]),
    .io_in_13_valid                 (m_io_tasks_txreq_valid[13]),
    .io_in_13_bits_tgtID            (m_io_tasks_txreq_bits_tgtID[13]),
    .io_in_13_bits_txnID            (m_io_tasks_txreq_bits_txnID[13]),
    .io_in_13_bits_opcode           (m_io_tasks_txreq_bits_opcode[13]),
    .io_in_13_bits_addr             (m_io_tasks_txreq_bits_addr[13]),
    .io_in_13_bits_likelyshared     (m_io_tasks_txreq_bits_likelyshared[13]),
    .io_in_13_bits_allowRetry       (m_io_tasks_txreq_bits_allowRetry[13]),
    .io_in_13_bits_pCrdType         (m_io_tasks_txreq_bits_pCrdType[13]),
    .io_in_13_bits_memAttr_allocate (m_io_tasks_txreq_bits_memAttr_allocate[13]),
    .io_in_13_bits_memAttr_ewa      (m_io_tasks_txreq_bits_memAttr_ewa[13]),
    .io_in_13_bits_expCompAck       (m_io_tasks_txreq_bits_expCompAck[13]),
    .io_in_14_ready                 (txreq_arb_in_ready[14]),
    .io_in_14_valid                 (m_io_tasks_txreq_valid[14]),
    .io_in_14_bits_tgtID            (m_io_tasks_txreq_bits_tgtID[14]),
    .io_in_14_bits_txnID            (m_io_tasks_txreq_bits_txnID[14]),
    .io_in_14_bits_opcode           (m_io_tasks_txreq_bits_opcode[14]),
    .io_in_14_bits_addr             (m_io_tasks_txreq_bits_addr[14]),
    .io_in_14_bits_likelyshared     (m_io_tasks_txreq_bits_likelyshared[14]),
    .io_in_14_bits_allowRetry       (m_io_tasks_txreq_bits_allowRetry[14]),
    .io_in_14_bits_pCrdType         (m_io_tasks_txreq_bits_pCrdType[14]),
    .io_in_14_bits_memAttr_allocate (m_io_tasks_txreq_bits_memAttr_allocate[14]),
    .io_in_14_bits_memAttr_ewa      (m_io_tasks_txreq_bits_memAttr_ewa[14]),
    .io_in_14_bits_expCompAck       (m_io_tasks_txreq_bits_expCompAck[14]),
    .io_in_15_ready                 (txreq_arb_in_ready[15]),
    .io_in_15_valid                 (m_io_tasks_txreq_valid[15]),
    .io_in_15_bits_tgtID            (m_io_tasks_txreq_bits_tgtID[15]),
    .io_in_15_bits_txnID            (m_io_tasks_txreq_bits_txnID[15]),
    .io_in_15_bits_opcode           (m_io_tasks_txreq_bits_opcode[15]),
    .io_in_15_bits_addr             (m_io_tasks_txreq_bits_addr[15]),
    .io_in_15_bits_likelyshared     (m_io_tasks_txreq_bits_likelyshared[15]),
    .io_in_15_bits_allowRetry       (m_io_tasks_txreq_bits_allowRetry[15]),
    .io_in_15_bits_pCrdType         (m_io_tasks_txreq_bits_pCrdType[15]),
    .io_in_15_bits_memAttr_allocate (m_io_tasks_txreq_bits_memAttr_allocate[15]),
    .io_in_15_bits_memAttr_ewa      (m_io_tasks_txreq_bits_memAttr_ewa[15]),
    .io_in_15_bits_expCompAck       (m_io_tasks_txreq_bits_expCompAck[15]),
    .io_out_ready                   (io_toTXREQ_ready),
    .io_out_valid                   (io_toTXREQ_valid),
    .io_out_bits_qos                (io_toTXREQ_bits_qos),
    .io_out_bits_tgtID              (io_toTXREQ_bits_tgtID),
    .io_out_bits_txnID              (io_toTXREQ_bits_txnID),
    .io_out_bits_opcode             (io_toTXREQ_bits_opcode),
    .io_out_bits_size               (io_toTXREQ_bits_size),
    .io_out_bits_addr               (io_toTXREQ_bits_addr),
    .io_out_bits_likelyshared       (io_toTXREQ_bits_likelyshared),
    .io_out_bits_allowRetry         (io_toTXREQ_bits_allowRetry),
    .io_out_bits_pCrdType           (io_toTXREQ_bits_pCrdType),
    .io_out_bits_memAttr_allocate   (io_toTXREQ_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable  (io_toTXREQ_bits_memAttr_cacheable),
    .io_out_bits_memAttr_ewa        (io_toTXREQ_bits_memAttr_ewa),
    .io_out_bits_snpAttr            (io_toTXREQ_bits_snpAttr),
    .io_out_bits_expCompAck         (io_toTXREQ_bits_expCompAck)
  );

  FastArbiter_5 txrsp_arb (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_0_ready          (txrsp_arb_in_ready[0]),
    .io_in_0_valid          (m_io_tasks_txrsp_valid[0]),
    .io_in_0_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[0]),
    .io_in_0_bits_txnID     (m_io_tasks_txrsp_bits_txnID[0]),
    .io_in_0_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[0]),
    .io_in_1_ready          (txrsp_arb_in_ready[1]),
    .io_in_1_valid          (m_io_tasks_txrsp_valid[1]),
    .io_in_1_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[1]),
    .io_in_1_bits_txnID     (m_io_tasks_txrsp_bits_txnID[1]),
    .io_in_1_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[1]),
    .io_in_2_ready          (txrsp_arb_in_ready[2]),
    .io_in_2_valid          (m_io_tasks_txrsp_valid[2]),
    .io_in_2_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[2]),
    .io_in_2_bits_txnID     (m_io_tasks_txrsp_bits_txnID[2]),
    .io_in_2_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[2]),
    .io_in_3_ready          (txrsp_arb_in_ready[3]),
    .io_in_3_valid          (m_io_tasks_txrsp_valid[3]),
    .io_in_3_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[3]),
    .io_in_3_bits_txnID     (m_io_tasks_txrsp_bits_txnID[3]),
    .io_in_3_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[3]),
    .io_in_4_ready          (txrsp_arb_in_ready[4]),
    .io_in_4_valid          (m_io_tasks_txrsp_valid[4]),
    .io_in_4_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[4]),
    .io_in_4_bits_txnID     (m_io_tasks_txrsp_bits_txnID[4]),
    .io_in_4_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[4]),
    .io_in_5_ready          (txrsp_arb_in_ready[5]),
    .io_in_5_valid          (m_io_tasks_txrsp_valid[5]),
    .io_in_5_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[5]),
    .io_in_5_bits_txnID     (m_io_tasks_txrsp_bits_txnID[5]),
    .io_in_5_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[5]),
    .io_in_6_ready          (txrsp_arb_in_ready[6]),
    .io_in_6_valid          (m_io_tasks_txrsp_valid[6]),
    .io_in_6_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[6]),
    .io_in_6_bits_txnID     (m_io_tasks_txrsp_bits_txnID[6]),
    .io_in_6_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[6]),
    .io_in_7_ready          (txrsp_arb_in_ready[7]),
    .io_in_7_valid          (m_io_tasks_txrsp_valid[7]),
    .io_in_7_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[7]),
    .io_in_7_bits_txnID     (m_io_tasks_txrsp_bits_txnID[7]),
    .io_in_7_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[7]),
    .io_in_8_ready          (txrsp_arb_in_ready[8]),
    .io_in_8_valid          (m_io_tasks_txrsp_valid[8]),
    .io_in_8_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[8]),
    .io_in_8_bits_txnID     (m_io_tasks_txrsp_bits_txnID[8]),
    .io_in_8_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[8]),
    .io_in_9_ready          (txrsp_arb_in_ready[9]),
    .io_in_9_valid          (m_io_tasks_txrsp_valid[9]),
    .io_in_9_bits_tgtID     (m_io_tasks_txrsp_bits_tgtID[9]),
    .io_in_9_bits_txnID     (m_io_tasks_txrsp_bits_txnID[9]),
    .io_in_9_bits_traceTag  (m_io_tasks_txrsp_bits_traceTag[9]),
    .io_in_10_ready         (txrsp_arb_in_ready[10]),
    .io_in_10_valid         (m_io_tasks_txrsp_valid[10]),
    .io_in_10_bits_tgtID    (m_io_tasks_txrsp_bits_tgtID[10]),
    .io_in_10_bits_txnID    (m_io_tasks_txrsp_bits_txnID[10]),
    .io_in_10_bits_traceTag (m_io_tasks_txrsp_bits_traceTag[10]),
    .io_in_11_ready         (txrsp_arb_in_ready[11]),
    .io_in_11_valid         (m_io_tasks_txrsp_valid[11]),
    .io_in_11_bits_tgtID    (m_io_tasks_txrsp_bits_tgtID[11]),
    .io_in_11_bits_txnID    (m_io_tasks_txrsp_bits_txnID[11]),
    .io_in_11_bits_traceTag (m_io_tasks_txrsp_bits_traceTag[11]),
    .io_in_12_ready         (txrsp_arb_in_ready[12]),
    .io_in_12_valid         (m_io_tasks_txrsp_valid[12]),
    .io_in_12_bits_tgtID    (m_io_tasks_txrsp_bits_tgtID[12]),
    .io_in_12_bits_txnID    (m_io_tasks_txrsp_bits_txnID[12]),
    .io_in_12_bits_traceTag (m_io_tasks_txrsp_bits_traceTag[12]),
    .io_in_13_ready         (txrsp_arb_in_ready[13]),
    .io_in_13_valid         (m_io_tasks_txrsp_valid[13]),
    .io_in_13_bits_tgtID    (m_io_tasks_txrsp_bits_tgtID[13]),
    .io_in_13_bits_txnID    (m_io_tasks_txrsp_bits_txnID[13]),
    .io_in_13_bits_traceTag (m_io_tasks_txrsp_bits_traceTag[13]),
    .io_in_14_ready         (txrsp_arb_in_ready[14]),
    .io_in_14_valid         (m_io_tasks_txrsp_valid[14]),
    .io_in_14_bits_tgtID    (m_io_tasks_txrsp_bits_tgtID[14]),
    .io_in_14_bits_txnID    (m_io_tasks_txrsp_bits_txnID[14]),
    .io_in_14_bits_traceTag (m_io_tasks_txrsp_bits_traceTag[14]),
    .io_in_15_ready         (txrsp_arb_in_ready[15]),
    .io_in_15_valid         (m_io_tasks_txrsp_valid[15]),
    .io_in_15_bits_tgtID    (m_io_tasks_txrsp_bits_tgtID[15]),
    .io_in_15_bits_txnID    (m_io_tasks_txrsp_bits_txnID[15]),
    .io_in_15_bits_traceTag (m_io_tasks_txrsp_bits_traceTag[15]),
    .io_out_ready           (io_toTXRSP_ready),
    .io_out_valid           (io_toTXRSP_valid),
    .io_out_bits_tgtID      (io_toTXRSP_bits_tgtID),
    .io_out_bits_txnID      (io_toTXRSP_bits_txnID),
    .io_out_bits_opcode     (io_toTXRSP_bits_opcode),
    .io_out_bits_traceTag   (io_toTXRSP_bits_traceTag)
  );

  SourceB sourceB (
    .clock                   (clock),
    .reset                   (reset),
    .io_sourceB_ready        (io_toSourceB_ready),
    .io_sourceB_valid        (io_toSourceB_valid),
    .io_sourceB_bits_opcode  (io_toSourceB_bits_opcode),
    .io_sourceB_bits_param   (io_toSourceB_bits_param),
    .io_sourceB_bits_address (io_toSourceB_bits_address),
    .io_sourceB_bits_data    (io_toSourceB_bits_data),
    .io_task_ready           (_sourceB_io_task_ready),
    .io_task_valid           (_source_b_arb_io_out_valid),
    .io_task_bits_tag        (_source_b_arb_io_out_bits_tag),
    .io_task_bits_set        (_source_b_arb_io_out_bits_set),
    .io_task_bits_opcode     (_source_b_arb_io_out_bits_opcode),
    .io_task_bits_param      (_source_b_arb_io_out_bits_param),
    .io_task_bits_alias      (_source_b_arb_io_out_bits_alias),
    .io_grantStatus_0_valid  (io_grantStatus_0_valid),
    .io_grantStatus_0_set    (io_grantStatus_0_set),
    .io_grantStatus_0_tag    (io_grantStatus_0_tag),
    .io_grantStatus_1_valid  (io_grantStatus_1_valid),
    .io_grantStatus_1_set    (io_grantStatus_1_set),
    .io_grantStatus_1_tag    (io_grantStatus_1_tag),
    .io_grantStatus_2_valid  (io_grantStatus_2_valid),
    .io_grantStatus_2_set    (io_grantStatus_2_set),
    .io_grantStatus_2_tag    (io_grantStatus_2_tag),
    .io_grantStatus_3_valid  (io_grantStatus_3_valid),
    .io_grantStatus_3_set    (io_grantStatus_3_set),
    .io_grantStatus_3_tag    (io_grantStatus_3_tag),
    .io_grantStatus_4_valid  (io_grantStatus_4_valid),
    .io_grantStatus_4_set    (io_grantStatus_4_set),
    .io_grantStatus_4_tag    (io_grantStatus_4_tag),
    .io_grantStatus_5_valid  (io_grantStatus_5_valid),
    .io_grantStatus_5_set    (io_grantStatus_5_set),
    .io_grantStatus_5_tag    (io_grantStatus_5_tag),
    .io_grantStatus_6_valid  (io_grantStatus_6_valid),
    .io_grantStatus_6_set    (io_grantStatus_6_set),
    .io_grantStatus_6_tag    (io_grantStatus_6_tag),
    .io_grantStatus_7_valid  (io_grantStatus_7_valid),
    .io_grantStatus_7_set    (io_grantStatus_7_set),
    .io_grantStatus_7_tag    (io_grantStatus_7_tag),
    .io_grantStatus_8_valid  (io_grantStatus_8_valid),
    .io_grantStatus_8_set    (io_grantStatus_8_set),
    .io_grantStatus_8_tag    (io_grantStatus_8_tag),
    .io_grantStatus_9_valid  (io_grantStatus_9_valid),
    .io_grantStatus_9_set    (io_grantStatus_9_set),
    .io_grantStatus_9_tag    (io_grantStatus_9_tag),
    .io_grantStatus_10_valid (io_grantStatus_10_valid),
    .io_grantStatus_10_set   (io_grantStatus_10_set),
    .io_grantStatus_10_tag   (io_grantStatus_10_tag),
    .io_grantStatus_11_valid (io_grantStatus_11_valid),
    .io_grantStatus_11_set   (io_grantStatus_11_set),
    .io_grantStatus_11_tag   (io_grantStatus_11_tag),
    .io_grantStatus_12_valid (io_grantStatus_12_valid),
    .io_grantStatus_12_set   (io_grantStatus_12_set),
    .io_grantStatus_12_tag   (io_grantStatus_12_tag),
    .io_grantStatus_13_valid (io_grantStatus_13_valid),
    .io_grantStatus_13_set   (io_grantStatus_13_set),
    .io_grantStatus_13_tag   (io_grantStatus_13_tag),
    .io_grantStatus_14_valid (io_grantStatus_14_valid),
    .io_grantStatus_14_set   (io_grantStatus_14_set),
    .io_grantStatus_14_tag   (io_grantStatus_14_tag),
    .io_grantStatus_15_valid (io_grantStatus_15_valid),
    .io_grantStatus_15_set   (io_grantStatus_15_set),
    .io_grantStatus_15_tag   (io_grantStatus_15_tag)
  );

  FastArbiter_7 source_b_arb (
    .clock               (clock),
    .reset               (reset),
    .io_in_0_ready       (source_b_arb_in_ready[0]),
    .io_in_0_valid       (m_io_tasks_source_b_valid[0]),
    .io_in_0_bits_tag    (m_io_tasks_source_b_bits_tag[0]),
    .io_in_0_bits_set    (m_io_tasks_source_b_bits_set[0]),
    .io_in_0_bits_param  (m_io_tasks_source_b_bits_param[0]),
    .io_in_0_bits_alias  (m_io_tasks_source_b_bits_alias[0]),
    .io_in_1_ready       (source_b_arb_in_ready[1]),
    .io_in_1_valid       (m_io_tasks_source_b_valid[1]),
    .io_in_1_bits_tag    (m_io_tasks_source_b_bits_tag[1]),
    .io_in_1_bits_set    (m_io_tasks_source_b_bits_set[1]),
    .io_in_1_bits_param  (m_io_tasks_source_b_bits_param[1]),
    .io_in_1_bits_alias  (m_io_tasks_source_b_bits_alias[1]),
    .io_in_2_ready       (source_b_arb_in_ready[2]),
    .io_in_2_valid       (m_io_tasks_source_b_valid[2]),
    .io_in_2_bits_tag    (m_io_tasks_source_b_bits_tag[2]),
    .io_in_2_bits_set    (m_io_tasks_source_b_bits_set[2]),
    .io_in_2_bits_param  (m_io_tasks_source_b_bits_param[2]),
    .io_in_2_bits_alias  (m_io_tasks_source_b_bits_alias[2]),
    .io_in_3_ready       (source_b_arb_in_ready[3]),
    .io_in_3_valid       (m_io_tasks_source_b_valid[3]),
    .io_in_3_bits_tag    (m_io_tasks_source_b_bits_tag[3]),
    .io_in_3_bits_set    (m_io_tasks_source_b_bits_set[3]),
    .io_in_3_bits_param  (m_io_tasks_source_b_bits_param[3]),
    .io_in_3_bits_alias  (m_io_tasks_source_b_bits_alias[3]),
    .io_in_4_ready       (source_b_arb_in_ready[4]),
    .io_in_4_valid       (m_io_tasks_source_b_valid[4]),
    .io_in_4_bits_tag    (m_io_tasks_source_b_bits_tag[4]),
    .io_in_4_bits_set    (m_io_tasks_source_b_bits_set[4]),
    .io_in_4_bits_param  (m_io_tasks_source_b_bits_param[4]),
    .io_in_4_bits_alias  (m_io_tasks_source_b_bits_alias[4]),
    .io_in_5_ready       (source_b_arb_in_ready[5]),
    .io_in_5_valid       (m_io_tasks_source_b_valid[5]),
    .io_in_5_bits_tag    (m_io_tasks_source_b_bits_tag[5]),
    .io_in_5_bits_set    (m_io_tasks_source_b_bits_set[5]),
    .io_in_5_bits_param  (m_io_tasks_source_b_bits_param[5]),
    .io_in_5_bits_alias  (m_io_tasks_source_b_bits_alias[5]),
    .io_in_6_ready       (source_b_arb_in_ready[6]),
    .io_in_6_valid       (m_io_tasks_source_b_valid[6]),
    .io_in_6_bits_tag    (m_io_tasks_source_b_bits_tag[6]),
    .io_in_6_bits_set    (m_io_tasks_source_b_bits_set[6]),
    .io_in_6_bits_param  (m_io_tasks_source_b_bits_param[6]),
    .io_in_6_bits_alias  (m_io_tasks_source_b_bits_alias[6]),
    .io_in_7_ready       (source_b_arb_in_ready[7]),
    .io_in_7_valid       (m_io_tasks_source_b_valid[7]),
    .io_in_7_bits_tag    (m_io_tasks_source_b_bits_tag[7]),
    .io_in_7_bits_set    (m_io_tasks_source_b_bits_set[7]),
    .io_in_7_bits_param  (m_io_tasks_source_b_bits_param[7]),
    .io_in_7_bits_alias  (m_io_tasks_source_b_bits_alias[7]),
    .io_in_8_ready       (source_b_arb_in_ready[8]),
    .io_in_8_valid       (m_io_tasks_source_b_valid[8]),
    .io_in_8_bits_tag    (m_io_tasks_source_b_bits_tag[8]),
    .io_in_8_bits_set    (m_io_tasks_source_b_bits_set[8]),
    .io_in_8_bits_param  (m_io_tasks_source_b_bits_param[8]),
    .io_in_8_bits_alias  (m_io_tasks_source_b_bits_alias[8]),
    .io_in_9_ready       (source_b_arb_in_ready[9]),
    .io_in_9_valid       (m_io_tasks_source_b_valid[9]),
    .io_in_9_bits_tag    (m_io_tasks_source_b_bits_tag[9]),
    .io_in_9_bits_set    (m_io_tasks_source_b_bits_set[9]),
    .io_in_9_bits_param  (m_io_tasks_source_b_bits_param[9]),
    .io_in_9_bits_alias  (m_io_tasks_source_b_bits_alias[9]),
    .io_in_10_ready      (source_b_arb_in_ready[10]),
    .io_in_10_valid      (m_io_tasks_source_b_valid[10]),
    .io_in_10_bits_tag   (m_io_tasks_source_b_bits_tag[10]),
    .io_in_10_bits_set   (m_io_tasks_source_b_bits_set[10]),
    .io_in_10_bits_param (m_io_tasks_source_b_bits_param[10]),
    .io_in_10_bits_alias (m_io_tasks_source_b_bits_alias[10]),
    .io_in_11_ready      (source_b_arb_in_ready[11]),
    .io_in_11_valid      (m_io_tasks_source_b_valid[11]),
    .io_in_11_bits_tag   (m_io_tasks_source_b_bits_tag[11]),
    .io_in_11_bits_set   (m_io_tasks_source_b_bits_set[11]),
    .io_in_11_bits_param (m_io_tasks_source_b_bits_param[11]),
    .io_in_11_bits_alias (m_io_tasks_source_b_bits_alias[11]),
    .io_in_12_ready      (source_b_arb_in_ready[12]),
    .io_in_12_valid      (m_io_tasks_source_b_valid[12]),
    .io_in_12_bits_tag   (m_io_tasks_source_b_bits_tag[12]),
    .io_in_12_bits_set   (m_io_tasks_source_b_bits_set[12]),
    .io_in_12_bits_param (m_io_tasks_source_b_bits_param[12]),
    .io_in_12_bits_alias (m_io_tasks_source_b_bits_alias[12]),
    .io_in_13_ready      (source_b_arb_in_ready[13]),
    .io_in_13_valid      (m_io_tasks_source_b_valid[13]),
    .io_in_13_bits_tag   (m_io_tasks_source_b_bits_tag[13]),
    .io_in_13_bits_set   (m_io_tasks_source_b_bits_set[13]),
    .io_in_13_bits_param (m_io_tasks_source_b_bits_param[13]),
    .io_in_13_bits_alias (m_io_tasks_source_b_bits_alias[13]),
    .io_in_14_ready      (source_b_arb_in_ready[14]),
    .io_in_14_valid      (m_io_tasks_source_b_valid[14]),
    .io_in_14_bits_tag   (m_io_tasks_source_b_bits_tag[14]),
    .io_in_14_bits_set   (m_io_tasks_source_b_bits_set[14]),
    .io_in_14_bits_param (m_io_tasks_source_b_bits_param[14]),
    .io_in_14_bits_alias (m_io_tasks_source_b_bits_alias[14]),
    .io_in_15_ready      (source_b_arb_in_ready[15]),
    .io_in_15_valid      (m_io_tasks_source_b_valid[15]),
    .io_in_15_bits_tag   (m_io_tasks_source_b_bits_tag[15]),
    .io_in_15_bits_set   (m_io_tasks_source_b_bits_set[15]),
    .io_in_15_bits_param (m_io_tasks_source_b_bits_param[15]),
    .io_in_15_bits_alias (m_io_tasks_source_b_bits_alias[15]),
    .io_out_ready        (_sourceB_io_task_ready),
    .io_out_valid        (_source_b_arb_io_out_valid),
    .io_out_bits_tag     (_source_b_arb_io_out_bits_tag),
    .io_out_bits_set     (_source_b_arb_io_out_bits_set),
    .io_out_bits_opcode  (_source_b_arb_io_out_bits_opcode),
    .io_out_bits_param   (_source_b_arb_io_out_bits_param),
    .io_out_bits_alias   (_source_b_arb_io_out_bits_alias)
  );

  FastArbiter_8 mshr_task_arb (
    .clock                                       (clock),
    .reset                                       (reset),
    .io_in_0_ready                               (mshr_task_arb_in_ready[0]),
    .io_in_0_valid                               (m_io_tasks_mainpipe_valid[0]),
    .io_in_0_bits_channel
      (m_io_tasks_mainpipe_bits_channel[0]),
    .io_in_0_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[0]),
    .io_in_0_bits_set                            (m_io_tasks_mainpipe_bits_set[0]),
    .io_in_0_bits_tag                            (m_io_tasks_mainpipe_bits_tag[0]),
    .io_in_0_bits_off                            (m_io_tasks_mainpipe_bits_off[0]),
    .io_in_0_bits_alias                          (m_io_tasks_mainpipe_bits_alias[0]),
    .io_in_0_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[0]),
    .io_in_0_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[0]),
    .io_in_0_bits_param                          (m_io_tasks_mainpipe_bits_param[0]),
    .io_in_0_bits_size                           (m_io_tasks_mainpipe_bits_size[0]),
    .io_in_0_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[0]),
    .io_in_0_bits_denied                         (m_io_tasks_mainpipe_bits_denied[0]),
    .io_in_0_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[0]),
    .io_in_0_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[0]),
    .io_in_0_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[0]),
    .io_in_0_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[0]),
    .io_in_0_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[0]),
    .io_in_0_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[0]),
    .io_in_0_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[0]),
    .io_in_0_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[0]),
    .io_in_0_bits_way                            (m_io_tasks_mainpipe_bits_way[0]),
    .io_in_0_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[0]),
    .io_in_0_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[0]),
    .io_in_0_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[0]),
    .io_in_0_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[0]),
    .io_in_0_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[0]),
    .io_in_0_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[0]),
    .io_in_0_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[0]),
    .io_in_0_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[0]),
    .io_in_0_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[0]),
    .io_in_0_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[0]),
    .io_in_0_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[0]),
    .io_in_0_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[0]),
    .io_in_0_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[0]),
    .io_in_0_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[0]),
    .io_in_0_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[0]),
    .io_in_0_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[0]),
    .io_in_0_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[0]),
    .io_in_0_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[0]),
    .io_in_0_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[0]),
    .io_in_0_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[0]),
    .io_in_0_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[0]),
    .io_in_0_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[0]),
    .io_in_0_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[0]),
    .io_in_0_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[0]),
    .io_in_0_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[0]),
    .io_in_0_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[0]),
    .io_in_0_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[0]),
    .io_in_0_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[0]),
    .io_in_0_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[0]),
    .io_in_0_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[0]),
    .io_in_0_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[0]),
    .io_in_0_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[0]),
    .io_in_0_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[0]),
    .io_in_0_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[0]),
    .io_in_0_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[0]),
    .io_in_0_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[0]),
    .io_in_0_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[0]),
    .io_in_0_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[0]),
    .io_in_0_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[0]),
    .io_in_0_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[0]),
    .io_in_0_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[0]),
    .io_in_0_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[0]),
    .io_in_0_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[0]),
    .io_in_0_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[0]),
    .io_in_0_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[0]),
    .io_in_0_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[0]),
    .io_in_0_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[0]),
    .io_in_0_bits_resp                           (m_io_tasks_mainpipe_bits_resp[0]),
    .io_in_0_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[0]),
    .io_in_0_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[0]),
    .io_in_0_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[0]),
    .io_in_0_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[0]),
    .io_in_0_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[0]),
    .io_in_0_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[0]),
    .io_in_0_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[0]),
    .io_in_0_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[0]),
    .io_in_0_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[0]),
    .io_in_0_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[0]),
    .io_in_1_ready                               (mshr_task_arb_in_ready[1]),
    .io_in_1_valid                               (m_io_tasks_mainpipe_valid[1]),
    .io_in_1_bits_channel
      (m_io_tasks_mainpipe_bits_channel[1]),
    .io_in_1_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[1]),
    .io_in_1_bits_set                            (m_io_tasks_mainpipe_bits_set[1]),
    .io_in_1_bits_tag                            (m_io_tasks_mainpipe_bits_tag[1]),
    .io_in_1_bits_off                            (m_io_tasks_mainpipe_bits_off[1]),
    .io_in_1_bits_alias                          (m_io_tasks_mainpipe_bits_alias[1]),
    .io_in_1_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[1]),
    .io_in_1_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[1]),
    .io_in_1_bits_param                          (m_io_tasks_mainpipe_bits_param[1]),
    .io_in_1_bits_size                           (m_io_tasks_mainpipe_bits_size[1]),
    .io_in_1_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[1]),
    .io_in_1_bits_denied                         (m_io_tasks_mainpipe_bits_denied[1]),
    .io_in_1_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[1]),
    .io_in_1_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[1]),
    .io_in_1_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[1]),
    .io_in_1_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[1]),
    .io_in_1_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[1]),
    .io_in_1_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[1]),
    .io_in_1_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[1]),
    .io_in_1_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[1]),
    .io_in_1_bits_way                            (m_io_tasks_mainpipe_bits_way[1]),
    .io_in_1_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[1]),
    .io_in_1_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[1]),
    .io_in_1_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[1]),
    .io_in_1_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[1]),
    .io_in_1_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[1]),
    .io_in_1_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[1]),
    .io_in_1_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[1]),
    .io_in_1_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[1]),
    .io_in_1_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[1]),
    .io_in_1_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[1]),
    .io_in_1_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[1]),
    .io_in_1_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[1]),
    .io_in_1_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[1]),
    .io_in_1_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[1]),
    .io_in_1_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[1]),
    .io_in_1_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[1]),
    .io_in_1_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[1]),
    .io_in_1_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[1]),
    .io_in_1_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[1]),
    .io_in_1_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[1]),
    .io_in_1_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[1]),
    .io_in_1_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[1]),
    .io_in_1_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[1]),
    .io_in_1_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[1]),
    .io_in_1_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[1]),
    .io_in_1_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[1]),
    .io_in_1_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[1]),
    .io_in_1_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[1]),
    .io_in_1_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[1]),
    .io_in_1_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[1]),
    .io_in_1_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[1]),
    .io_in_1_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[1]),
    .io_in_1_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[1]),
    .io_in_1_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[1]),
    .io_in_1_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[1]),
    .io_in_1_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[1]),
    .io_in_1_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[1]),
    .io_in_1_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[1]),
    .io_in_1_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[1]),
    .io_in_1_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[1]),
    .io_in_1_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[1]),
    .io_in_1_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[1]),
    .io_in_1_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[1]),
    .io_in_1_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[1]),
    .io_in_1_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[1]),
    .io_in_1_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[1]),
    .io_in_1_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[1]),
    .io_in_1_bits_resp                           (m_io_tasks_mainpipe_bits_resp[1]),
    .io_in_1_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[1]),
    .io_in_1_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[1]),
    .io_in_1_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[1]),
    .io_in_1_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[1]),
    .io_in_1_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[1]),
    .io_in_1_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[1]),
    .io_in_1_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[1]),
    .io_in_1_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[1]),
    .io_in_1_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[1]),
    .io_in_1_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[1]),
    .io_in_2_ready                               (mshr_task_arb_in_ready[2]),
    .io_in_2_valid                               (m_io_tasks_mainpipe_valid[2]),
    .io_in_2_bits_channel
      (m_io_tasks_mainpipe_bits_channel[2]),
    .io_in_2_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[2]),
    .io_in_2_bits_set                            (m_io_tasks_mainpipe_bits_set[2]),
    .io_in_2_bits_tag                            (m_io_tasks_mainpipe_bits_tag[2]),
    .io_in_2_bits_off                            (m_io_tasks_mainpipe_bits_off[2]),
    .io_in_2_bits_alias                          (m_io_tasks_mainpipe_bits_alias[2]),
    .io_in_2_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[2]),
    .io_in_2_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[2]),
    .io_in_2_bits_param                          (m_io_tasks_mainpipe_bits_param[2]),
    .io_in_2_bits_size                           (m_io_tasks_mainpipe_bits_size[2]),
    .io_in_2_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[2]),
    .io_in_2_bits_denied                         (m_io_tasks_mainpipe_bits_denied[2]),
    .io_in_2_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[2]),
    .io_in_2_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[2]),
    .io_in_2_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[2]),
    .io_in_2_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[2]),
    .io_in_2_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[2]),
    .io_in_2_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[2]),
    .io_in_2_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[2]),
    .io_in_2_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[2]),
    .io_in_2_bits_way                            (m_io_tasks_mainpipe_bits_way[2]),
    .io_in_2_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[2]),
    .io_in_2_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[2]),
    .io_in_2_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[2]),
    .io_in_2_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[2]),
    .io_in_2_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[2]),
    .io_in_2_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[2]),
    .io_in_2_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[2]),
    .io_in_2_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[2]),
    .io_in_2_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[2]),
    .io_in_2_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[2]),
    .io_in_2_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[2]),
    .io_in_2_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[2]),
    .io_in_2_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[2]),
    .io_in_2_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[2]),
    .io_in_2_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[2]),
    .io_in_2_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[2]),
    .io_in_2_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[2]),
    .io_in_2_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[2]),
    .io_in_2_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[2]),
    .io_in_2_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[2]),
    .io_in_2_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[2]),
    .io_in_2_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[2]),
    .io_in_2_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[2]),
    .io_in_2_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[2]),
    .io_in_2_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[2]),
    .io_in_2_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[2]),
    .io_in_2_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[2]),
    .io_in_2_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[2]),
    .io_in_2_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[2]),
    .io_in_2_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[2]),
    .io_in_2_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[2]),
    .io_in_2_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[2]),
    .io_in_2_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[2]),
    .io_in_2_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[2]),
    .io_in_2_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[2]),
    .io_in_2_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[2]),
    .io_in_2_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[2]),
    .io_in_2_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[2]),
    .io_in_2_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[2]),
    .io_in_2_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[2]),
    .io_in_2_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[2]),
    .io_in_2_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[2]),
    .io_in_2_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[2]),
    .io_in_2_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[2]),
    .io_in_2_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[2]),
    .io_in_2_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[2]),
    .io_in_2_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[2]),
    .io_in_2_bits_resp                           (m_io_tasks_mainpipe_bits_resp[2]),
    .io_in_2_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[2]),
    .io_in_2_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[2]),
    .io_in_2_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[2]),
    .io_in_2_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[2]),
    .io_in_2_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[2]),
    .io_in_2_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[2]),
    .io_in_2_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[2]),
    .io_in_2_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[2]),
    .io_in_2_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[2]),
    .io_in_2_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[2]),
    .io_in_3_ready                               (mshr_task_arb_in_ready[3]),
    .io_in_3_valid                               (m_io_tasks_mainpipe_valid[3]),
    .io_in_3_bits_channel
      (m_io_tasks_mainpipe_bits_channel[3]),
    .io_in_3_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[3]),
    .io_in_3_bits_set                            (m_io_tasks_mainpipe_bits_set[3]),
    .io_in_3_bits_tag                            (m_io_tasks_mainpipe_bits_tag[3]),
    .io_in_3_bits_off                            (m_io_tasks_mainpipe_bits_off[3]),
    .io_in_3_bits_alias                          (m_io_tasks_mainpipe_bits_alias[3]),
    .io_in_3_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[3]),
    .io_in_3_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[3]),
    .io_in_3_bits_param                          (m_io_tasks_mainpipe_bits_param[3]),
    .io_in_3_bits_size                           (m_io_tasks_mainpipe_bits_size[3]),
    .io_in_3_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[3]),
    .io_in_3_bits_denied                         (m_io_tasks_mainpipe_bits_denied[3]),
    .io_in_3_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[3]),
    .io_in_3_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[3]),
    .io_in_3_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[3]),
    .io_in_3_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[3]),
    .io_in_3_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[3]),
    .io_in_3_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[3]),
    .io_in_3_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[3]),
    .io_in_3_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[3]),
    .io_in_3_bits_way                            (m_io_tasks_mainpipe_bits_way[3]),
    .io_in_3_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[3]),
    .io_in_3_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[3]),
    .io_in_3_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[3]),
    .io_in_3_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[3]),
    .io_in_3_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[3]),
    .io_in_3_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[3]),
    .io_in_3_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[3]),
    .io_in_3_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[3]),
    .io_in_3_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[3]),
    .io_in_3_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[3]),
    .io_in_3_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[3]),
    .io_in_3_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[3]),
    .io_in_3_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[3]),
    .io_in_3_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[3]),
    .io_in_3_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[3]),
    .io_in_3_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[3]),
    .io_in_3_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[3]),
    .io_in_3_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[3]),
    .io_in_3_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[3]),
    .io_in_3_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[3]),
    .io_in_3_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[3]),
    .io_in_3_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[3]),
    .io_in_3_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[3]),
    .io_in_3_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[3]),
    .io_in_3_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[3]),
    .io_in_3_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[3]),
    .io_in_3_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[3]),
    .io_in_3_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[3]),
    .io_in_3_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[3]),
    .io_in_3_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[3]),
    .io_in_3_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[3]),
    .io_in_3_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[3]),
    .io_in_3_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[3]),
    .io_in_3_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[3]),
    .io_in_3_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[3]),
    .io_in_3_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[3]),
    .io_in_3_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[3]),
    .io_in_3_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[3]),
    .io_in_3_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[3]),
    .io_in_3_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[3]),
    .io_in_3_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[3]),
    .io_in_3_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[3]),
    .io_in_3_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[3]),
    .io_in_3_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[3]),
    .io_in_3_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[3]),
    .io_in_3_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[3]),
    .io_in_3_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[3]),
    .io_in_3_bits_resp                           (m_io_tasks_mainpipe_bits_resp[3]),
    .io_in_3_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[3]),
    .io_in_3_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[3]),
    .io_in_3_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[3]),
    .io_in_3_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[3]),
    .io_in_3_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[3]),
    .io_in_3_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[3]),
    .io_in_3_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[3]),
    .io_in_3_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[3]),
    .io_in_3_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[3]),
    .io_in_3_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[3]),
    .io_in_4_ready                               (mshr_task_arb_in_ready[4]),
    .io_in_4_valid                               (m_io_tasks_mainpipe_valid[4]),
    .io_in_4_bits_channel
      (m_io_tasks_mainpipe_bits_channel[4]),
    .io_in_4_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[4]),
    .io_in_4_bits_set                            (m_io_tasks_mainpipe_bits_set[4]),
    .io_in_4_bits_tag                            (m_io_tasks_mainpipe_bits_tag[4]),
    .io_in_4_bits_off                            (m_io_tasks_mainpipe_bits_off[4]),
    .io_in_4_bits_alias                          (m_io_tasks_mainpipe_bits_alias[4]),
    .io_in_4_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[4]),
    .io_in_4_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[4]),
    .io_in_4_bits_param                          (m_io_tasks_mainpipe_bits_param[4]),
    .io_in_4_bits_size                           (m_io_tasks_mainpipe_bits_size[4]),
    .io_in_4_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[4]),
    .io_in_4_bits_denied                         (m_io_tasks_mainpipe_bits_denied[4]),
    .io_in_4_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[4]),
    .io_in_4_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[4]),
    .io_in_4_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[4]),
    .io_in_4_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[4]),
    .io_in_4_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[4]),
    .io_in_4_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[4]),
    .io_in_4_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[4]),
    .io_in_4_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[4]),
    .io_in_4_bits_way                            (m_io_tasks_mainpipe_bits_way[4]),
    .io_in_4_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[4]),
    .io_in_4_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[4]),
    .io_in_4_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[4]),
    .io_in_4_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[4]),
    .io_in_4_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[4]),
    .io_in_4_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[4]),
    .io_in_4_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[4]),
    .io_in_4_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[4]),
    .io_in_4_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[4]),
    .io_in_4_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[4]),
    .io_in_4_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[4]),
    .io_in_4_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[4]),
    .io_in_4_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[4]),
    .io_in_4_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[4]),
    .io_in_4_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[4]),
    .io_in_4_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[4]),
    .io_in_4_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[4]),
    .io_in_4_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[4]),
    .io_in_4_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[4]),
    .io_in_4_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[4]),
    .io_in_4_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[4]),
    .io_in_4_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[4]),
    .io_in_4_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[4]),
    .io_in_4_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[4]),
    .io_in_4_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[4]),
    .io_in_4_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[4]),
    .io_in_4_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[4]),
    .io_in_4_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[4]),
    .io_in_4_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[4]),
    .io_in_4_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[4]),
    .io_in_4_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[4]),
    .io_in_4_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[4]),
    .io_in_4_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[4]),
    .io_in_4_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[4]),
    .io_in_4_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[4]),
    .io_in_4_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[4]),
    .io_in_4_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[4]),
    .io_in_4_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[4]),
    .io_in_4_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[4]),
    .io_in_4_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[4]),
    .io_in_4_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[4]),
    .io_in_4_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[4]),
    .io_in_4_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[4]),
    .io_in_4_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[4]),
    .io_in_4_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[4]),
    .io_in_4_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[4]),
    .io_in_4_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[4]),
    .io_in_4_bits_resp                           (m_io_tasks_mainpipe_bits_resp[4]),
    .io_in_4_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[4]),
    .io_in_4_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[4]),
    .io_in_4_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[4]),
    .io_in_4_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[4]),
    .io_in_4_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[4]),
    .io_in_4_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[4]),
    .io_in_4_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[4]),
    .io_in_4_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[4]),
    .io_in_4_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[4]),
    .io_in_4_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[4]),
    .io_in_5_ready                               (mshr_task_arb_in_ready[5]),
    .io_in_5_valid                               (m_io_tasks_mainpipe_valid[5]),
    .io_in_5_bits_channel
      (m_io_tasks_mainpipe_bits_channel[5]),
    .io_in_5_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[5]),
    .io_in_5_bits_set                            (m_io_tasks_mainpipe_bits_set[5]),
    .io_in_5_bits_tag                            (m_io_tasks_mainpipe_bits_tag[5]),
    .io_in_5_bits_off                            (m_io_tasks_mainpipe_bits_off[5]),
    .io_in_5_bits_alias                          (m_io_tasks_mainpipe_bits_alias[5]),
    .io_in_5_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[5]),
    .io_in_5_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[5]),
    .io_in_5_bits_param                          (m_io_tasks_mainpipe_bits_param[5]),
    .io_in_5_bits_size                           (m_io_tasks_mainpipe_bits_size[5]),
    .io_in_5_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[5]),
    .io_in_5_bits_denied                         (m_io_tasks_mainpipe_bits_denied[5]),
    .io_in_5_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[5]),
    .io_in_5_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[5]),
    .io_in_5_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[5]),
    .io_in_5_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[5]),
    .io_in_5_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[5]),
    .io_in_5_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[5]),
    .io_in_5_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[5]),
    .io_in_5_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[5]),
    .io_in_5_bits_way                            (m_io_tasks_mainpipe_bits_way[5]),
    .io_in_5_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[5]),
    .io_in_5_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[5]),
    .io_in_5_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[5]),
    .io_in_5_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[5]),
    .io_in_5_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[5]),
    .io_in_5_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[5]),
    .io_in_5_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[5]),
    .io_in_5_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[5]),
    .io_in_5_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[5]),
    .io_in_5_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[5]),
    .io_in_5_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[5]),
    .io_in_5_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[5]),
    .io_in_5_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[5]),
    .io_in_5_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[5]),
    .io_in_5_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[5]),
    .io_in_5_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[5]),
    .io_in_5_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[5]),
    .io_in_5_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[5]),
    .io_in_5_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[5]),
    .io_in_5_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[5]),
    .io_in_5_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[5]),
    .io_in_5_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[5]),
    .io_in_5_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[5]),
    .io_in_5_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[5]),
    .io_in_5_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[5]),
    .io_in_5_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[5]),
    .io_in_5_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[5]),
    .io_in_5_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[5]),
    .io_in_5_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[5]),
    .io_in_5_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[5]),
    .io_in_5_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[5]),
    .io_in_5_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[5]),
    .io_in_5_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[5]),
    .io_in_5_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[5]),
    .io_in_5_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[5]),
    .io_in_5_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[5]),
    .io_in_5_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[5]),
    .io_in_5_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[5]),
    .io_in_5_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[5]),
    .io_in_5_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[5]),
    .io_in_5_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[5]),
    .io_in_5_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[5]),
    .io_in_5_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[5]),
    .io_in_5_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[5]),
    .io_in_5_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[5]),
    .io_in_5_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[5]),
    .io_in_5_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[5]),
    .io_in_5_bits_resp                           (m_io_tasks_mainpipe_bits_resp[5]),
    .io_in_5_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[5]),
    .io_in_5_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[5]),
    .io_in_5_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[5]),
    .io_in_5_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[5]),
    .io_in_5_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[5]),
    .io_in_5_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[5]),
    .io_in_5_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[5]),
    .io_in_5_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[5]),
    .io_in_5_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[5]),
    .io_in_5_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[5]),
    .io_in_6_ready                               (mshr_task_arb_in_ready[6]),
    .io_in_6_valid                               (m_io_tasks_mainpipe_valid[6]),
    .io_in_6_bits_channel
      (m_io_tasks_mainpipe_bits_channel[6]),
    .io_in_6_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[6]),
    .io_in_6_bits_set                            (m_io_tasks_mainpipe_bits_set[6]),
    .io_in_6_bits_tag                            (m_io_tasks_mainpipe_bits_tag[6]),
    .io_in_6_bits_off                            (m_io_tasks_mainpipe_bits_off[6]),
    .io_in_6_bits_alias                          (m_io_tasks_mainpipe_bits_alias[6]),
    .io_in_6_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[6]),
    .io_in_6_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[6]),
    .io_in_6_bits_param                          (m_io_tasks_mainpipe_bits_param[6]),
    .io_in_6_bits_size                           (m_io_tasks_mainpipe_bits_size[6]),
    .io_in_6_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[6]),
    .io_in_6_bits_denied                         (m_io_tasks_mainpipe_bits_denied[6]),
    .io_in_6_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[6]),
    .io_in_6_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[6]),
    .io_in_6_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[6]),
    .io_in_6_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[6]),
    .io_in_6_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[6]),
    .io_in_6_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[6]),
    .io_in_6_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[6]),
    .io_in_6_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[6]),
    .io_in_6_bits_way                            (m_io_tasks_mainpipe_bits_way[6]),
    .io_in_6_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[6]),
    .io_in_6_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[6]),
    .io_in_6_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[6]),
    .io_in_6_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[6]),
    .io_in_6_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[6]),
    .io_in_6_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[6]),
    .io_in_6_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[6]),
    .io_in_6_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[6]),
    .io_in_6_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[6]),
    .io_in_6_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[6]),
    .io_in_6_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[6]),
    .io_in_6_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[6]),
    .io_in_6_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[6]),
    .io_in_6_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[6]),
    .io_in_6_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[6]),
    .io_in_6_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[6]),
    .io_in_6_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[6]),
    .io_in_6_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[6]),
    .io_in_6_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[6]),
    .io_in_6_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[6]),
    .io_in_6_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[6]),
    .io_in_6_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[6]),
    .io_in_6_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[6]),
    .io_in_6_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[6]),
    .io_in_6_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[6]),
    .io_in_6_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[6]),
    .io_in_6_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[6]),
    .io_in_6_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[6]),
    .io_in_6_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[6]),
    .io_in_6_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[6]),
    .io_in_6_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[6]),
    .io_in_6_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[6]),
    .io_in_6_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[6]),
    .io_in_6_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[6]),
    .io_in_6_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[6]),
    .io_in_6_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[6]),
    .io_in_6_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[6]),
    .io_in_6_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[6]),
    .io_in_6_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[6]),
    .io_in_6_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[6]),
    .io_in_6_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[6]),
    .io_in_6_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[6]),
    .io_in_6_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[6]),
    .io_in_6_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[6]),
    .io_in_6_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[6]),
    .io_in_6_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[6]),
    .io_in_6_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[6]),
    .io_in_6_bits_resp                           (m_io_tasks_mainpipe_bits_resp[6]),
    .io_in_6_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[6]),
    .io_in_6_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[6]),
    .io_in_6_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[6]),
    .io_in_6_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[6]),
    .io_in_6_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[6]),
    .io_in_6_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[6]),
    .io_in_6_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[6]),
    .io_in_6_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[6]),
    .io_in_6_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[6]),
    .io_in_6_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[6]),
    .io_in_7_ready                               (mshr_task_arb_in_ready[7]),
    .io_in_7_valid                               (m_io_tasks_mainpipe_valid[7]),
    .io_in_7_bits_channel
      (m_io_tasks_mainpipe_bits_channel[7]),
    .io_in_7_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[7]),
    .io_in_7_bits_set                            (m_io_tasks_mainpipe_bits_set[7]),
    .io_in_7_bits_tag                            (m_io_tasks_mainpipe_bits_tag[7]),
    .io_in_7_bits_off                            (m_io_tasks_mainpipe_bits_off[7]),
    .io_in_7_bits_alias                          (m_io_tasks_mainpipe_bits_alias[7]),
    .io_in_7_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[7]),
    .io_in_7_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[7]),
    .io_in_7_bits_param                          (m_io_tasks_mainpipe_bits_param[7]),
    .io_in_7_bits_size                           (m_io_tasks_mainpipe_bits_size[7]),
    .io_in_7_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[7]),
    .io_in_7_bits_denied                         (m_io_tasks_mainpipe_bits_denied[7]),
    .io_in_7_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[7]),
    .io_in_7_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[7]),
    .io_in_7_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[7]),
    .io_in_7_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[7]),
    .io_in_7_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[7]),
    .io_in_7_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[7]),
    .io_in_7_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[7]),
    .io_in_7_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[7]),
    .io_in_7_bits_way                            (m_io_tasks_mainpipe_bits_way[7]),
    .io_in_7_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[7]),
    .io_in_7_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[7]),
    .io_in_7_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[7]),
    .io_in_7_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[7]),
    .io_in_7_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[7]),
    .io_in_7_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[7]),
    .io_in_7_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[7]),
    .io_in_7_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[7]),
    .io_in_7_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[7]),
    .io_in_7_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[7]),
    .io_in_7_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[7]),
    .io_in_7_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[7]),
    .io_in_7_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[7]),
    .io_in_7_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[7]),
    .io_in_7_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[7]),
    .io_in_7_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[7]),
    .io_in_7_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[7]),
    .io_in_7_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[7]),
    .io_in_7_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[7]),
    .io_in_7_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[7]),
    .io_in_7_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[7]),
    .io_in_7_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[7]),
    .io_in_7_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[7]),
    .io_in_7_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[7]),
    .io_in_7_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[7]),
    .io_in_7_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[7]),
    .io_in_7_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[7]),
    .io_in_7_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[7]),
    .io_in_7_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[7]),
    .io_in_7_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[7]),
    .io_in_7_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[7]),
    .io_in_7_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[7]),
    .io_in_7_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[7]),
    .io_in_7_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[7]),
    .io_in_7_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[7]),
    .io_in_7_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[7]),
    .io_in_7_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[7]),
    .io_in_7_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[7]),
    .io_in_7_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[7]),
    .io_in_7_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[7]),
    .io_in_7_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[7]),
    .io_in_7_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[7]),
    .io_in_7_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[7]),
    .io_in_7_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[7]),
    .io_in_7_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[7]),
    .io_in_7_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[7]),
    .io_in_7_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[7]),
    .io_in_7_bits_resp                           (m_io_tasks_mainpipe_bits_resp[7]),
    .io_in_7_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[7]),
    .io_in_7_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[7]),
    .io_in_7_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[7]),
    .io_in_7_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[7]),
    .io_in_7_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[7]),
    .io_in_7_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[7]),
    .io_in_7_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[7]),
    .io_in_7_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[7]),
    .io_in_7_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[7]),
    .io_in_7_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[7]),
    .io_in_8_ready                               (mshr_task_arb_in_ready[8]),
    .io_in_8_valid                               (m_io_tasks_mainpipe_valid[8]),
    .io_in_8_bits_channel
      (m_io_tasks_mainpipe_bits_channel[8]),
    .io_in_8_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[8]),
    .io_in_8_bits_set                            (m_io_tasks_mainpipe_bits_set[8]),
    .io_in_8_bits_tag                            (m_io_tasks_mainpipe_bits_tag[8]),
    .io_in_8_bits_off                            (m_io_tasks_mainpipe_bits_off[8]),
    .io_in_8_bits_alias                          (m_io_tasks_mainpipe_bits_alias[8]),
    .io_in_8_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[8]),
    .io_in_8_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[8]),
    .io_in_8_bits_param                          (m_io_tasks_mainpipe_bits_param[8]),
    .io_in_8_bits_size                           (m_io_tasks_mainpipe_bits_size[8]),
    .io_in_8_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[8]),
    .io_in_8_bits_denied                         (m_io_tasks_mainpipe_bits_denied[8]),
    .io_in_8_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[8]),
    .io_in_8_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[8]),
    .io_in_8_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[8]),
    .io_in_8_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[8]),
    .io_in_8_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[8]),
    .io_in_8_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[8]),
    .io_in_8_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[8]),
    .io_in_8_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[8]),
    .io_in_8_bits_way                            (m_io_tasks_mainpipe_bits_way[8]),
    .io_in_8_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[8]),
    .io_in_8_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[8]),
    .io_in_8_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[8]),
    .io_in_8_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[8]),
    .io_in_8_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[8]),
    .io_in_8_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[8]),
    .io_in_8_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[8]),
    .io_in_8_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[8]),
    .io_in_8_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[8]),
    .io_in_8_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[8]),
    .io_in_8_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[8]),
    .io_in_8_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[8]),
    .io_in_8_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[8]),
    .io_in_8_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[8]),
    .io_in_8_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[8]),
    .io_in_8_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[8]),
    .io_in_8_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[8]),
    .io_in_8_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[8]),
    .io_in_8_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[8]),
    .io_in_8_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[8]),
    .io_in_8_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[8]),
    .io_in_8_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[8]),
    .io_in_8_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[8]),
    .io_in_8_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[8]),
    .io_in_8_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[8]),
    .io_in_8_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[8]),
    .io_in_8_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[8]),
    .io_in_8_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[8]),
    .io_in_8_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[8]),
    .io_in_8_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[8]),
    .io_in_8_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[8]),
    .io_in_8_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[8]),
    .io_in_8_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[8]),
    .io_in_8_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[8]),
    .io_in_8_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[8]),
    .io_in_8_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[8]),
    .io_in_8_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[8]),
    .io_in_8_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[8]),
    .io_in_8_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[8]),
    .io_in_8_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[8]),
    .io_in_8_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[8]),
    .io_in_8_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[8]),
    .io_in_8_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[8]),
    .io_in_8_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[8]),
    .io_in_8_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[8]),
    .io_in_8_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[8]),
    .io_in_8_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[8]),
    .io_in_8_bits_resp                           (m_io_tasks_mainpipe_bits_resp[8]),
    .io_in_8_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[8]),
    .io_in_8_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[8]),
    .io_in_8_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[8]),
    .io_in_8_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[8]),
    .io_in_8_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[8]),
    .io_in_8_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[8]),
    .io_in_8_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[8]),
    .io_in_8_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[8]),
    .io_in_8_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[8]),
    .io_in_8_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[8]),
    .io_in_9_ready                               (mshr_task_arb_in_ready[9]),
    .io_in_9_valid                               (m_io_tasks_mainpipe_valid[9]),
    .io_in_9_bits_channel
      (m_io_tasks_mainpipe_bits_channel[9]),
    .io_in_9_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[9]),
    .io_in_9_bits_set                            (m_io_tasks_mainpipe_bits_set[9]),
    .io_in_9_bits_tag                            (m_io_tasks_mainpipe_bits_tag[9]),
    .io_in_9_bits_off                            (m_io_tasks_mainpipe_bits_off[9]),
    .io_in_9_bits_alias                          (m_io_tasks_mainpipe_bits_alias[9]),
    .io_in_9_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[9]),
    .io_in_9_bits_opcode                         (m_io_tasks_mainpipe_bits_opcode[9]),
    .io_in_9_bits_param                          (m_io_tasks_mainpipe_bits_param[9]),
    .io_in_9_bits_size                           (m_io_tasks_mainpipe_bits_size[9]),
    .io_in_9_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[9]),
    .io_in_9_bits_denied                         (m_io_tasks_mainpipe_bits_denied[9]),
    .io_in_9_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[9]),
    .io_in_9_bits_mshrId                         (m_io_tasks_mainpipe_bits_mshrId[9]),
    .io_in_9_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[9]),
    .io_in_9_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[9]),
    .io_in_9_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[9]),
    .io_in_9_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[9]),
    .io_in_9_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[9]),
    .io_in_9_bits_dirty                          (m_io_tasks_mainpipe_bits_dirty[9]),
    .io_in_9_bits_way                            (m_io_tasks_mainpipe_bits_way[9]),
    .io_in_9_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[9]),
    .io_in_9_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[9]),
    .io_in_9_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[9]),
    .io_in_9_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[9]),
    .io_in_9_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[9]),
    .io_in_9_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[9]),
    .io_in_9_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[9]),
    .io_in_9_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[9]),
    .io_in_9_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[9]),
    .io_in_9_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[9]),
    .io_in_9_bits_tagWen                         (m_io_tasks_mainpipe_bits_tagWen[9]),
    .io_in_9_bits_dsWen                          (m_io_tasks_mainpipe_bits_dsWen[9]),
    .io_in_9_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[9]),
    .io_in_9_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[9]),
    .io_in_9_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[9]),
    .io_in_9_bits_mergeA                         (m_io_tasks_mainpipe_bits_mergeA[9]),
    .io_in_9_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[9]),
    .io_in_9_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[9]),
    .io_in_9_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[9]),
    .io_in_9_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[9]),
    .io_in_9_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[9]),
    .io_in_9_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[9]),
    .io_in_9_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[9]),
    .io_in_9_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[9]),
    .io_in_9_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[9]),
    .io_in_9_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[9]),
    .io_in_9_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[9]),
    .io_in_9_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[9]),
    .io_in_9_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[9]),
    .io_in_9_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[9]),
    .io_in_9_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[9]),
    .io_in_9_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[9]),
    .io_in_9_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[9]),
    .io_in_9_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[9]),
    .io_in_9_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[9]),
    .io_in_9_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[9]),
    .io_in_9_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[9]),
    .io_in_9_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[9]),
    .io_in_9_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[9]),
    .io_in_9_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[9]),
    .io_in_9_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[9]),
    .io_in_9_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[9]),
    .io_in_9_bits_tgtID                          (m_io_tasks_mainpipe_bits_tgtID[9]),
    .io_in_9_bits_txnID                          (m_io_tasks_mainpipe_bits_txnID[9]),
    .io_in_9_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[9]),
    .io_in_9_bits_dbID                           (m_io_tasks_mainpipe_bits_dbID[9]),
    .io_in_9_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[9]),
    .io_in_9_bits_resp                           (m_io_tasks_mainpipe_bits_resp[9]),
    .io_in_9_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[9]),
    .io_in_9_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[9]),
    .io_in_9_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[9]),
    .io_in_9_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[9]),
    .io_in_9_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[9]),
    .io_in_9_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[9]),
    .io_in_9_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[9]),
    .io_in_9_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[9]),
    .io_in_9_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[9]),
    .io_in_9_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[9]),
    .io_in_10_ready                              (mshr_task_arb_in_ready[10]),
    .io_in_10_valid                              (m_io_tasks_mainpipe_valid[10]),
    .io_in_10_bits_channel
      (m_io_tasks_mainpipe_bits_channel[10]),
    .io_in_10_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[10]),
    .io_in_10_bits_set                           (m_io_tasks_mainpipe_bits_set[10]),
    .io_in_10_bits_tag                           (m_io_tasks_mainpipe_bits_tag[10]),
    .io_in_10_bits_off                           (m_io_tasks_mainpipe_bits_off[10]),
    .io_in_10_bits_alias                         (m_io_tasks_mainpipe_bits_alias[10]),
    .io_in_10_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[10]),
    .io_in_10_bits_opcode
      (m_io_tasks_mainpipe_bits_opcode[10]),
    .io_in_10_bits_param                         (m_io_tasks_mainpipe_bits_param[10]),
    .io_in_10_bits_size                          (m_io_tasks_mainpipe_bits_size[10]),
    .io_in_10_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[10]),
    .io_in_10_bits_denied
      (m_io_tasks_mainpipe_bits_denied[10]),
    .io_in_10_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[10]),
    .io_in_10_bits_mshrId
      (m_io_tasks_mainpipe_bits_mshrId[10]),
    .io_in_10_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[10]),
    .io_in_10_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[10]),
    .io_in_10_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[10]),
    .io_in_10_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[10]),
    .io_in_10_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[10]),
    .io_in_10_bits_dirty                         (m_io_tasks_mainpipe_bits_dirty[10]),
    .io_in_10_bits_way                           (m_io_tasks_mainpipe_bits_way[10]),
    .io_in_10_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[10]),
    .io_in_10_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[10]),
    .io_in_10_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[10]),
    .io_in_10_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[10]),
    .io_in_10_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[10]),
    .io_in_10_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[10]),
    .io_in_10_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[10]),
    .io_in_10_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[10]),
    .io_in_10_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[10]),
    .io_in_10_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[10]),
    .io_in_10_bits_tagWen
      (m_io_tasks_mainpipe_bits_tagWen[10]),
    .io_in_10_bits_dsWen                         (m_io_tasks_mainpipe_bits_dsWen[10]),
    .io_in_10_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[10]),
    .io_in_10_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[10]),
    .io_in_10_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[10]),
    .io_in_10_bits_mergeA
      (m_io_tasks_mainpipe_bits_mergeA[10]),
    .io_in_10_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[10]),
    .io_in_10_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[10]),
    .io_in_10_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[10]),
    .io_in_10_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[10]),
    .io_in_10_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[10]),
    .io_in_10_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[10]),
    .io_in_10_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[10]),
    .io_in_10_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[10]),
    .io_in_10_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[10]),
    .io_in_10_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[10]),
    .io_in_10_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[10]),
    .io_in_10_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[10]),
    .io_in_10_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[10]),
    .io_in_10_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[10]),
    .io_in_10_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[10]),
    .io_in_10_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[10]),
    .io_in_10_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[10]),
    .io_in_10_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[10]),
    .io_in_10_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[10]),
    .io_in_10_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[10]),
    .io_in_10_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[10]),
    .io_in_10_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[10]),
    .io_in_10_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[10]),
    .io_in_10_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[10]),
    .io_in_10_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[10]),
    .io_in_10_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[10]),
    .io_in_10_bits_tgtID                         (m_io_tasks_mainpipe_bits_tgtID[10]),
    .io_in_10_bits_txnID                         (m_io_tasks_mainpipe_bits_txnID[10]),
    .io_in_10_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[10]),
    .io_in_10_bits_dbID                          (m_io_tasks_mainpipe_bits_dbID[10]),
    .io_in_10_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[10]),
    .io_in_10_bits_resp                          (m_io_tasks_mainpipe_bits_resp[10]),
    .io_in_10_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[10]),
    .io_in_10_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[10]),
    .io_in_10_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[10]),
    .io_in_10_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[10]),
    .io_in_10_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[10]),
    .io_in_10_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[10]),
    .io_in_10_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[10]),
    .io_in_10_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[10]),
    .io_in_10_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[10]),
    .io_in_10_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[10]),
    .io_in_11_ready                              (mshr_task_arb_in_ready[11]),
    .io_in_11_valid                              (m_io_tasks_mainpipe_valid[11]),
    .io_in_11_bits_channel
      (m_io_tasks_mainpipe_bits_channel[11]),
    .io_in_11_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[11]),
    .io_in_11_bits_set                           (m_io_tasks_mainpipe_bits_set[11]),
    .io_in_11_bits_tag                           (m_io_tasks_mainpipe_bits_tag[11]),
    .io_in_11_bits_off                           (m_io_tasks_mainpipe_bits_off[11]),
    .io_in_11_bits_alias                         (m_io_tasks_mainpipe_bits_alias[11]),
    .io_in_11_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[11]),
    .io_in_11_bits_opcode
      (m_io_tasks_mainpipe_bits_opcode[11]),
    .io_in_11_bits_param                         (m_io_tasks_mainpipe_bits_param[11]),
    .io_in_11_bits_size                          (m_io_tasks_mainpipe_bits_size[11]),
    .io_in_11_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[11]),
    .io_in_11_bits_denied
      (m_io_tasks_mainpipe_bits_denied[11]),
    .io_in_11_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[11]),
    .io_in_11_bits_mshrId
      (m_io_tasks_mainpipe_bits_mshrId[11]),
    .io_in_11_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[11]),
    .io_in_11_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[11]),
    .io_in_11_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[11]),
    .io_in_11_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[11]),
    .io_in_11_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[11]),
    .io_in_11_bits_dirty                         (m_io_tasks_mainpipe_bits_dirty[11]),
    .io_in_11_bits_way                           (m_io_tasks_mainpipe_bits_way[11]),
    .io_in_11_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[11]),
    .io_in_11_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[11]),
    .io_in_11_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[11]),
    .io_in_11_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[11]),
    .io_in_11_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[11]),
    .io_in_11_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[11]),
    .io_in_11_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[11]),
    .io_in_11_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[11]),
    .io_in_11_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[11]),
    .io_in_11_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[11]),
    .io_in_11_bits_tagWen
      (m_io_tasks_mainpipe_bits_tagWen[11]),
    .io_in_11_bits_dsWen                         (m_io_tasks_mainpipe_bits_dsWen[11]),
    .io_in_11_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[11]),
    .io_in_11_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[11]),
    .io_in_11_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[11]),
    .io_in_11_bits_mergeA
      (m_io_tasks_mainpipe_bits_mergeA[11]),
    .io_in_11_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[11]),
    .io_in_11_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[11]),
    .io_in_11_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[11]),
    .io_in_11_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[11]),
    .io_in_11_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[11]),
    .io_in_11_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[11]),
    .io_in_11_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[11]),
    .io_in_11_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[11]),
    .io_in_11_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[11]),
    .io_in_11_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[11]),
    .io_in_11_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[11]),
    .io_in_11_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[11]),
    .io_in_11_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[11]),
    .io_in_11_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[11]),
    .io_in_11_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[11]),
    .io_in_11_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[11]),
    .io_in_11_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[11]),
    .io_in_11_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[11]),
    .io_in_11_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[11]),
    .io_in_11_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[11]),
    .io_in_11_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[11]),
    .io_in_11_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[11]),
    .io_in_11_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[11]),
    .io_in_11_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[11]),
    .io_in_11_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[11]),
    .io_in_11_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[11]),
    .io_in_11_bits_tgtID                         (m_io_tasks_mainpipe_bits_tgtID[11]),
    .io_in_11_bits_txnID                         (m_io_tasks_mainpipe_bits_txnID[11]),
    .io_in_11_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[11]),
    .io_in_11_bits_dbID                          (m_io_tasks_mainpipe_bits_dbID[11]),
    .io_in_11_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[11]),
    .io_in_11_bits_resp                          (m_io_tasks_mainpipe_bits_resp[11]),
    .io_in_11_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[11]),
    .io_in_11_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[11]),
    .io_in_11_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[11]),
    .io_in_11_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[11]),
    .io_in_11_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[11]),
    .io_in_11_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[11]),
    .io_in_11_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[11]),
    .io_in_11_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[11]),
    .io_in_11_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[11]),
    .io_in_11_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[11]),
    .io_in_12_ready                              (mshr_task_arb_in_ready[12]),
    .io_in_12_valid                              (m_io_tasks_mainpipe_valid[12]),
    .io_in_12_bits_channel
      (m_io_tasks_mainpipe_bits_channel[12]),
    .io_in_12_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[12]),
    .io_in_12_bits_set                           (m_io_tasks_mainpipe_bits_set[12]),
    .io_in_12_bits_tag                           (m_io_tasks_mainpipe_bits_tag[12]),
    .io_in_12_bits_off                           (m_io_tasks_mainpipe_bits_off[12]),
    .io_in_12_bits_alias                         (m_io_tasks_mainpipe_bits_alias[12]),
    .io_in_12_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[12]),
    .io_in_12_bits_opcode
      (m_io_tasks_mainpipe_bits_opcode[12]),
    .io_in_12_bits_param                         (m_io_tasks_mainpipe_bits_param[12]),
    .io_in_12_bits_size                          (m_io_tasks_mainpipe_bits_size[12]),
    .io_in_12_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[12]),
    .io_in_12_bits_denied
      (m_io_tasks_mainpipe_bits_denied[12]),
    .io_in_12_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[12]),
    .io_in_12_bits_mshrId
      (m_io_tasks_mainpipe_bits_mshrId[12]),
    .io_in_12_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[12]),
    .io_in_12_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[12]),
    .io_in_12_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[12]),
    .io_in_12_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[12]),
    .io_in_12_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[12]),
    .io_in_12_bits_dirty                         (m_io_tasks_mainpipe_bits_dirty[12]),
    .io_in_12_bits_way                           (m_io_tasks_mainpipe_bits_way[12]),
    .io_in_12_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[12]),
    .io_in_12_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[12]),
    .io_in_12_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[12]),
    .io_in_12_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[12]),
    .io_in_12_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[12]),
    .io_in_12_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[12]),
    .io_in_12_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[12]),
    .io_in_12_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[12]),
    .io_in_12_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[12]),
    .io_in_12_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[12]),
    .io_in_12_bits_tagWen
      (m_io_tasks_mainpipe_bits_tagWen[12]),
    .io_in_12_bits_dsWen                         (m_io_tasks_mainpipe_bits_dsWen[12]),
    .io_in_12_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[12]),
    .io_in_12_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[12]),
    .io_in_12_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[12]),
    .io_in_12_bits_mergeA
      (m_io_tasks_mainpipe_bits_mergeA[12]),
    .io_in_12_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[12]),
    .io_in_12_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[12]),
    .io_in_12_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[12]),
    .io_in_12_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[12]),
    .io_in_12_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[12]),
    .io_in_12_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[12]),
    .io_in_12_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[12]),
    .io_in_12_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[12]),
    .io_in_12_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[12]),
    .io_in_12_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[12]),
    .io_in_12_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[12]),
    .io_in_12_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[12]),
    .io_in_12_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[12]),
    .io_in_12_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[12]),
    .io_in_12_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[12]),
    .io_in_12_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[12]),
    .io_in_12_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[12]),
    .io_in_12_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[12]),
    .io_in_12_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[12]),
    .io_in_12_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[12]),
    .io_in_12_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[12]),
    .io_in_12_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[12]),
    .io_in_12_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[12]),
    .io_in_12_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[12]),
    .io_in_12_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[12]),
    .io_in_12_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[12]),
    .io_in_12_bits_tgtID                         (m_io_tasks_mainpipe_bits_tgtID[12]),
    .io_in_12_bits_txnID                         (m_io_tasks_mainpipe_bits_txnID[12]),
    .io_in_12_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[12]),
    .io_in_12_bits_dbID                          (m_io_tasks_mainpipe_bits_dbID[12]),
    .io_in_12_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[12]),
    .io_in_12_bits_resp                          (m_io_tasks_mainpipe_bits_resp[12]),
    .io_in_12_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[12]),
    .io_in_12_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[12]),
    .io_in_12_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[12]),
    .io_in_12_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[12]),
    .io_in_12_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[12]),
    .io_in_12_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[12]),
    .io_in_12_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[12]),
    .io_in_12_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[12]),
    .io_in_12_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[12]),
    .io_in_12_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[12]),
    .io_in_13_ready                              (mshr_task_arb_in_ready[13]),
    .io_in_13_valid                              (m_io_tasks_mainpipe_valid[13]),
    .io_in_13_bits_channel
      (m_io_tasks_mainpipe_bits_channel[13]),
    .io_in_13_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[13]),
    .io_in_13_bits_set                           (m_io_tasks_mainpipe_bits_set[13]),
    .io_in_13_bits_tag                           (m_io_tasks_mainpipe_bits_tag[13]),
    .io_in_13_bits_off                           (m_io_tasks_mainpipe_bits_off[13]),
    .io_in_13_bits_alias                         (m_io_tasks_mainpipe_bits_alias[13]),
    .io_in_13_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[13]),
    .io_in_13_bits_opcode
      (m_io_tasks_mainpipe_bits_opcode[13]),
    .io_in_13_bits_param                         (m_io_tasks_mainpipe_bits_param[13]),
    .io_in_13_bits_size                          (m_io_tasks_mainpipe_bits_size[13]),
    .io_in_13_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[13]),
    .io_in_13_bits_denied
      (m_io_tasks_mainpipe_bits_denied[13]),
    .io_in_13_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[13]),
    .io_in_13_bits_mshrId
      (m_io_tasks_mainpipe_bits_mshrId[13]),
    .io_in_13_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[13]),
    .io_in_13_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[13]),
    .io_in_13_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[13]),
    .io_in_13_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[13]),
    .io_in_13_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[13]),
    .io_in_13_bits_dirty                         (m_io_tasks_mainpipe_bits_dirty[13]),
    .io_in_13_bits_way                           (m_io_tasks_mainpipe_bits_way[13]),
    .io_in_13_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[13]),
    .io_in_13_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[13]),
    .io_in_13_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[13]),
    .io_in_13_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[13]),
    .io_in_13_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[13]),
    .io_in_13_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[13]),
    .io_in_13_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[13]),
    .io_in_13_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[13]),
    .io_in_13_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[13]),
    .io_in_13_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[13]),
    .io_in_13_bits_tagWen
      (m_io_tasks_mainpipe_bits_tagWen[13]),
    .io_in_13_bits_dsWen                         (m_io_tasks_mainpipe_bits_dsWen[13]),
    .io_in_13_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[13]),
    .io_in_13_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[13]),
    .io_in_13_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[13]),
    .io_in_13_bits_mergeA
      (m_io_tasks_mainpipe_bits_mergeA[13]),
    .io_in_13_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[13]),
    .io_in_13_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[13]),
    .io_in_13_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[13]),
    .io_in_13_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[13]),
    .io_in_13_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[13]),
    .io_in_13_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[13]),
    .io_in_13_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[13]),
    .io_in_13_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[13]),
    .io_in_13_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[13]),
    .io_in_13_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[13]),
    .io_in_13_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[13]),
    .io_in_13_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[13]),
    .io_in_13_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[13]),
    .io_in_13_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[13]),
    .io_in_13_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[13]),
    .io_in_13_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[13]),
    .io_in_13_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[13]),
    .io_in_13_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[13]),
    .io_in_13_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[13]),
    .io_in_13_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[13]),
    .io_in_13_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[13]),
    .io_in_13_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[13]),
    .io_in_13_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[13]),
    .io_in_13_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[13]),
    .io_in_13_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[13]),
    .io_in_13_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[13]),
    .io_in_13_bits_tgtID                         (m_io_tasks_mainpipe_bits_tgtID[13]),
    .io_in_13_bits_txnID                         (m_io_tasks_mainpipe_bits_txnID[13]),
    .io_in_13_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[13]),
    .io_in_13_bits_dbID                          (m_io_tasks_mainpipe_bits_dbID[13]),
    .io_in_13_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[13]),
    .io_in_13_bits_resp                          (m_io_tasks_mainpipe_bits_resp[13]),
    .io_in_13_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[13]),
    .io_in_13_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[13]),
    .io_in_13_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[13]),
    .io_in_13_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[13]),
    .io_in_13_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[13]),
    .io_in_13_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[13]),
    .io_in_13_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[13]),
    .io_in_13_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[13]),
    .io_in_13_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[13]),
    .io_in_13_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[13]),
    .io_in_14_ready                              (mshr_task_arb_in_ready[14]),
    .io_in_14_valid                              (m_io_tasks_mainpipe_valid[14]),
    .io_in_14_bits_channel
      (m_io_tasks_mainpipe_bits_channel[14]),
    .io_in_14_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[14]),
    .io_in_14_bits_set                           (m_io_tasks_mainpipe_bits_set[14]),
    .io_in_14_bits_tag                           (m_io_tasks_mainpipe_bits_tag[14]),
    .io_in_14_bits_off                           (m_io_tasks_mainpipe_bits_off[14]),
    .io_in_14_bits_alias                         (m_io_tasks_mainpipe_bits_alias[14]),
    .io_in_14_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[14]),
    .io_in_14_bits_opcode
      (m_io_tasks_mainpipe_bits_opcode[14]),
    .io_in_14_bits_param                         (m_io_tasks_mainpipe_bits_param[14]),
    .io_in_14_bits_size                          (m_io_tasks_mainpipe_bits_size[14]),
    .io_in_14_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[14]),
    .io_in_14_bits_denied
      (m_io_tasks_mainpipe_bits_denied[14]),
    .io_in_14_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[14]),
    .io_in_14_bits_mshrId
      (m_io_tasks_mainpipe_bits_mshrId[14]),
    .io_in_14_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[14]),
    .io_in_14_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[14]),
    .io_in_14_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[14]),
    .io_in_14_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[14]),
    .io_in_14_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[14]),
    .io_in_14_bits_dirty                         (m_io_tasks_mainpipe_bits_dirty[14]),
    .io_in_14_bits_way                           (m_io_tasks_mainpipe_bits_way[14]),
    .io_in_14_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[14]),
    .io_in_14_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[14]),
    .io_in_14_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[14]),
    .io_in_14_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[14]),
    .io_in_14_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[14]),
    .io_in_14_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[14]),
    .io_in_14_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[14]),
    .io_in_14_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[14]),
    .io_in_14_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[14]),
    .io_in_14_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[14]),
    .io_in_14_bits_tagWen
      (m_io_tasks_mainpipe_bits_tagWen[14]),
    .io_in_14_bits_dsWen                         (m_io_tasks_mainpipe_bits_dsWen[14]),
    .io_in_14_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[14]),
    .io_in_14_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[14]),
    .io_in_14_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[14]),
    .io_in_14_bits_mergeA
      (m_io_tasks_mainpipe_bits_mergeA[14]),
    .io_in_14_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[14]),
    .io_in_14_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[14]),
    .io_in_14_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[14]),
    .io_in_14_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[14]),
    .io_in_14_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[14]),
    .io_in_14_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[14]),
    .io_in_14_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[14]),
    .io_in_14_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[14]),
    .io_in_14_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[14]),
    .io_in_14_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[14]),
    .io_in_14_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[14]),
    .io_in_14_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[14]),
    .io_in_14_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[14]),
    .io_in_14_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[14]),
    .io_in_14_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[14]),
    .io_in_14_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[14]),
    .io_in_14_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[14]),
    .io_in_14_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[14]),
    .io_in_14_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[14]),
    .io_in_14_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[14]),
    .io_in_14_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[14]),
    .io_in_14_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[14]),
    .io_in_14_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[14]),
    .io_in_14_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[14]),
    .io_in_14_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[14]),
    .io_in_14_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[14]),
    .io_in_14_bits_tgtID                         (m_io_tasks_mainpipe_bits_tgtID[14]),
    .io_in_14_bits_txnID                         (m_io_tasks_mainpipe_bits_txnID[14]),
    .io_in_14_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[14]),
    .io_in_14_bits_dbID                          (m_io_tasks_mainpipe_bits_dbID[14]),
    .io_in_14_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[14]),
    .io_in_14_bits_resp                          (m_io_tasks_mainpipe_bits_resp[14]),
    .io_in_14_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[14]),
    .io_in_14_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[14]),
    .io_in_14_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[14]),
    .io_in_14_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[14]),
    .io_in_14_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[14]),
    .io_in_14_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[14]),
    .io_in_14_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[14]),
    .io_in_14_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[14]),
    .io_in_14_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[14]),
    .io_in_14_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[14]),
    .io_in_15_ready                              (mshr_task_arb_in_ready[15]),
    .io_in_15_valid                              (m_io_tasks_mainpipe_valid[15]),
    .io_in_15_bits_channel
      (m_io_tasks_mainpipe_bits_channel[15]),
    .io_in_15_bits_txChannel
      (m_io_tasks_mainpipe_bits_txChannel[15]),
    .io_in_15_bits_set                           (m_io_tasks_mainpipe_bits_set[15]),
    .io_in_15_bits_tag                           (m_io_tasks_mainpipe_bits_tag[15]),
    .io_in_15_bits_off                           (m_io_tasks_mainpipe_bits_off[15]),
    .io_in_15_bits_alias                         (m_io_tasks_mainpipe_bits_alias[15]),
    .io_in_15_bits_isKeyword
      (m_io_tasks_mainpipe_bits_isKeyword[15]),
    .io_in_15_bits_opcode
      (m_io_tasks_mainpipe_bits_opcode[15]),
    .io_in_15_bits_param                         (m_io_tasks_mainpipe_bits_param[15]),
    .io_in_15_bits_size                          (m_io_tasks_mainpipe_bits_size[15]),
    .io_in_15_bits_sourceId
      (m_io_tasks_mainpipe_bits_sourceId[15]),
    .io_in_15_bits_denied
      (m_io_tasks_mainpipe_bits_denied[15]),
    .io_in_15_bits_corrupt
      (m_io_tasks_mainpipe_bits_corrupt[15]),
    .io_in_15_bits_mshrId
      (m_io_tasks_mainpipe_bits_mshrId[15]),
    .io_in_15_bits_aliasTask
      (m_io_tasks_mainpipe_bits_aliasTask[15]),
    .io_in_15_bits_useProbeData
      (m_io_tasks_mainpipe_bits_useProbeData[15]),
    .io_in_15_bits_mshrRetry
      (m_io_tasks_mainpipe_bits_mshrRetry[15]),
    .io_in_15_bits_readProbeDataDown
      (m_io_tasks_mainpipe_bits_readProbeDataDown[15]),
    .io_in_15_bits_fromL2pft
      (m_io_tasks_mainpipe_bits_fromL2pft[15]),
    .io_in_15_bits_dirty                         (m_io_tasks_mainpipe_bits_dirty[15]),
    .io_in_15_bits_way                           (m_io_tasks_mainpipe_bits_way[15]),
    .io_in_15_bits_meta_dirty
      (m_io_tasks_mainpipe_bits_meta_dirty[15]),
    .io_in_15_bits_meta_state
      (m_io_tasks_mainpipe_bits_meta_state[15]),
    .io_in_15_bits_meta_clients
      (m_io_tasks_mainpipe_bits_meta_clients[15]),
    .io_in_15_bits_meta_alias
      (m_io_tasks_mainpipe_bits_meta_alias[15]),
    .io_in_15_bits_meta_prefetch
      (m_io_tasks_mainpipe_bits_meta_prefetch[15]),
    .io_in_15_bits_meta_prefetchSrc
      (m_io_tasks_mainpipe_bits_meta_prefetchSrc[15]),
    .io_in_15_bits_meta_accessed
      (m_io_tasks_mainpipe_bits_meta_accessed[15]),
    .io_in_15_bits_meta_tagErr
      (m_io_tasks_mainpipe_bits_meta_tagErr[15]),
    .io_in_15_bits_meta_dataErr
      (m_io_tasks_mainpipe_bits_meta_dataErr[15]),
    .io_in_15_bits_metaWen
      (m_io_tasks_mainpipe_bits_metaWen[15]),
    .io_in_15_bits_tagWen
      (m_io_tasks_mainpipe_bits_tagWen[15]),
    .io_in_15_bits_dsWen                         (m_io_tasks_mainpipe_bits_dsWen[15]),
    .io_in_15_bits_replTask
      (m_io_tasks_mainpipe_bits_replTask[15]),
    .io_in_15_bits_cmoTask
      (m_io_tasks_mainpipe_bits_cmoTask[15]),
    .io_in_15_bits_reqSource
      (m_io_tasks_mainpipe_bits_reqSource[15]),
    .io_in_15_bits_mergeA
      (m_io_tasks_mainpipe_bits_mergeA[15]),
    .io_in_15_bits_aMergeTask_off
      (m_io_tasks_mainpipe_bits_aMergeTask_off[15]),
    .io_in_15_bits_aMergeTask_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_alias[15]),
    .io_in_15_bits_aMergeTask_vaddr
      (m_io_tasks_mainpipe_bits_aMergeTask_vaddr[15]),
    .io_in_15_bits_aMergeTask_isKeyword
      (m_io_tasks_mainpipe_bits_aMergeTask_isKeyword[15]),
    .io_in_15_bits_aMergeTask_opcode
      (m_io_tasks_mainpipe_bits_aMergeTask_opcode[15]),
    .io_in_15_bits_aMergeTask_param
      (m_io_tasks_mainpipe_bits_aMergeTask_param[15]),
    .io_in_15_bits_aMergeTask_sourceId
      (m_io_tasks_mainpipe_bits_aMergeTask_sourceId[15]),
    .io_in_15_bits_aMergeTask_meta_dirty
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_dirty[15]),
    .io_in_15_bits_aMergeTask_meta_state
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_state[15]),
    .io_in_15_bits_aMergeTask_meta_clients
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_clients[15]),
    .io_in_15_bits_aMergeTask_meta_alias
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_alias[15]),
    .io_in_15_bits_aMergeTask_meta_accessed
      (m_io_tasks_mainpipe_bits_aMergeTask_meta_accessed[15]),
    .io_in_15_bits_snpHitRelease
      (m_io_tasks_mainpipe_bits_snpHitRelease[15]),
    .io_in_15_bits_snpHitReleaseToInval
      (m_io_tasks_mainpipe_bits_snpHitReleaseToInval[15]),
    .io_in_15_bits_snpHitReleaseToClean
      (m_io_tasks_mainpipe_bits_snpHitReleaseToClean[15]),
    .io_in_15_bits_snpHitReleaseWithData
      (m_io_tasks_mainpipe_bits_snpHitReleaseWithData[15]),
    .io_in_15_bits_snpHitReleaseIdx
      (m_io_tasks_mainpipe_bits_snpHitReleaseIdx[15]),
    .io_in_15_bits_snpHitReleaseMeta_dirty
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dirty[15]),
    .io_in_15_bits_snpHitReleaseMeta_state
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_state[15]),
    .io_in_15_bits_snpHitReleaseMeta_clients
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_clients[15]),
    .io_in_15_bits_snpHitReleaseMeta_alias
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_alias[15]),
    .io_in_15_bits_snpHitReleaseMeta_prefetch
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetch[15]),
    .io_in_15_bits_snpHitReleaseMeta_prefetchSrc
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_prefetchSrc[15]),
    .io_in_15_bits_snpHitReleaseMeta_accessed
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_accessed[15]),
    .io_in_15_bits_snpHitReleaseMeta_tagErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_tagErr[15]),
    .io_in_15_bits_snpHitReleaseMeta_dataErr
      (m_io_tasks_mainpipe_bits_snpHitReleaseMeta_dataErr[15]),
    .io_in_15_bits_tgtID                         (m_io_tasks_mainpipe_bits_tgtID[15]),
    .io_in_15_bits_txnID                         (m_io_tasks_mainpipe_bits_txnID[15]),
    .io_in_15_bits_homeNID
      (m_io_tasks_mainpipe_bits_homeNID[15]),
    .io_in_15_bits_dbID                          (m_io_tasks_mainpipe_bits_dbID[15]),
    .io_in_15_bits_chiOpcode
      (m_io_tasks_mainpipe_bits_chiOpcode[15]),
    .io_in_15_bits_resp                          (m_io_tasks_mainpipe_bits_resp[15]),
    .io_in_15_bits_fwdState
      (m_io_tasks_mainpipe_bits_fwdState[15]),
    .io_in_15_bits_retToSrc
      (m_io_tasks_mainpipe_bits_retToSrc[15]),
    .io_in_15_bits_likelyshared
      (m_io_tasks_mainpipe_bits_likelyshared[15]),
    .io_in_15_bits_expCompAck
      (m_io_tasks_mainpipe_bits_expCompAck[15]),
    .io_in_15_bits_allowRetry
      (m_io_tasks_mainpipe_bits_allowRetry[15]),
    .io_in_15_bits_memAttr_allocate
      (m_io_tasks_mainpipe_bits_memAttr_allocate[15]),
    .io_in_15_bits_memAttr_cacheable
      (m_io_tasks_mainpipe_bits_memAttr_cacheable[15]),
    .io_in_15_bits_memAttr_ewa
      (m_io_tasks_mainpipe_bits_memAttr_ewa[15]),
    .io_in_15_bits_traceTag
      (m_io_tasks_mainpipe_bits_traceTag[15]),
    .io_in_15_bits_dataCheckErr
      (m_io_tasks_mainpipe_bits_dataCheckErr[15]),
    .io_out_ready                                (io_mshrTask_ready),
    .io_out_valid                                (io_mshrTask_valid),
    .io_out_bits_channel                         (io_mshrTask_bits_channel),
    .io_out_bits_txChannel                       (io_mshrTask_bits_txChannel),
    .io_out_bits_set                             (io_mshrTask_bits_set),
    .io_out_bits_tag                             (io_mshrTask_bits_tag),
    .io_out_bits_off                             (io_mshrTask_bits_off),
    .io_out_bits_alias                           (io_mshrTask_bits_alias),
    .io_out_bits_isKeyword                       (io_mshrTask_bits_isKeyword),
    .io_out_bits_opcode                          (io_mshrTask_bits_opcode),
    .io_out_bits_param                           (io_mshrTask_bits_param),
    .io_out_bits_size                            (io_mshrTask_bits_size),
    .io_out_bits_sourceId                        (io_mshrTask_bits_sourceId),
    .io_out_bits_denied                          (io_mshrTask_bits_denied),
    .io_out_bits_corrupt                         (io_mshrTask_bits_corrupt),
    .io_out_bits_mshrTask                        (io_mshrTask_bits_mshrTask),
    .io_out_bits_mshrId                          (io_mshrTask_bits_mshrId),
    .io_out_bits_aliasTask                       (io_mshrTask_bits_aliasTask),
    .io_out_bits_useProbeData                    (io_mshrTask_bits_useProbeData),
    .io_out_bits_mshrRetry                       (io_mshrTask_bits_mshrRetry),
    .io_out_bits_readProbeDataDown               (io_mshrTask_bits_readProbeDataDown),
    .io_out_bits_fromL2pft                       (io_mshrTask_bits_fromL2pft),
    .io_out_bits_dirty                           (io_mshrTask_bits_dirty),
    .io_out_bits_way                             (io_mshrTask_bits_way),
    .io_out_bits_meta_dirty                      (io_mshrTask_bits_meta_dirty),
    .io_out_bits_meta_state                      (io_mshrTask_bits_meta_state),
    .io_out_bits_meta_clients                    (io_mshrTask_bits_meta_clients),
    .io_out_bits_meta_alias                      (io_mshrTask_bits_meta_alias),
    .io_out_bits_meta_prefetch                   (io_mshrTask_bits_meta_prefetch),
    .io_out_bits_meta_prefetchSrc                (io_mshrTask_bits_meta_prefetchSrc),
    .io_out_bits_meta_accessed                   (io_mshrTask_bits_meta_accessed),
    .io_out_bits_meta_tagErr                     (io_mshrTask_bits_meta_tagErr),
    .io_out_bits_meta_dataErr                    (io_mshrTask_bits_meta_dataErr),
    .io_out_bits_metaWen                         (io_mshrTask_bits_metaWen),
    .io_out_bits_tagWen                          (io_mshrTask_bits_tagWen),
    .io_out_bits_dsWen                           (io_mshrTask_bits_dsWen),
    .io_out_bits_replTask                        (io_mshrTask_bits_replTask),
    .io_out_bits_cmoTask                         (io_mshrTask_bits_cmoTask),
    .io_out_bits_reqSource                       (io_mshrTask_bits_reqSource),
    .io_out_bits_mergeA                          (io_mshrTask_bits_mergeA),
    .io_out_bits_aMergeTask_off                  (io_mshrTask_bits_aMergeTask_off),
    .io_out_bits_aMergeTask_alias                (io_mshrTask_bits_aMergeTask_alias),
    .io_out_bits_aMergeTask_vaddr                (io_mshrTask_bits_aMergeTask_vaddr),
    .io_out_bits_aMergeTask_isKeyword            (io_mshrTask_bits_aMergeTask_isKeyword),
    .io_out_bits_aMergeTask_opcode               (io_mshrTask_bits_aMergeTask_opcode),
    .io_out_bits_aMergeTask_param                (io_mshrTask_bits_aMergeTask_param),
    .io_out_bits_aMergeTask_sourceId             (io_mshrTask_bits_aMergeTask_sourceId),
    .io_out_bits_aMergeTask_meta_dirty           (io_mshrTask_bits_aMergeTask_meta_dirty),
    .io_out_bits_aMergeTask_meta_state           (io_mshrTask_bits_aMergeTask_meta_state),
    .io_out_bits_aMergeTask_meta_clients
      (io_mshrTask_bits_aMergeTask_meta_clients),
    .io_out_bits_aMergeTask_meta_alias           (io_mshrTask_bits_aMergeTask_meta_alias),
    .io_out_bits_aMergeTask_meta_accessed
      (io_mshrTask_bits_aMergeTask_meta_accessed),
    .io_out_bits_snpHitRelease                   (io_mshrTask_bits_snpHitRelease),
    .io_out_bits_snpHitReleaseToInval            (io_mshrTask_bits_snpHitReleaseToInval),
    .io_out_bits_snpHitReleaseToClean            (io_mshrTask_bits_snpHitReleaseToClean),
    .io_out_bits_snpHitReleaseWithData           (io_mshrTask_bits_snpHitReleaseWithData),
    .io_out_bits_snpHitReleaseIdx                (io_mshrTask_bits_snpHitReleaseIdx),
    .io_out_bits_snpHitReleaseMeta_dirty
      (io_mshrTask_bits_snpHitReleaseMeta_dirty),
    .io_out_bits_snpHitReleaseMeta_state
      (io_mshrTask_bits_snpHitReleaseMeta_state),
    .io_out_bits_snpHitReleaseMeta_clients
      (io_mshrTask_bits_snpHitReleaseMeta_clients),
    .io_out_bits_snpHitReleaseMeta_alias
      (io_mshrTask_bits_snpHitReleaseMeta_alias),
    .io_out_bits_snpHitReleaseMeta_prefetch
      (io_mshrTask_bits_snpHitReleaseMeta_prefetch),
    .io_out_bits_snpHitReleaseMeta_prefetchSrc
      (io_mshrTask_bits_snpHitReleaseMeta_prefetchSrc),
    .io_out_bits_snpHitReleaseMeta_accessed
      (io_mshrTask_bits_snpHitReleaseMeta_accessed),
    .io_out_bits_snpHitReleaseMeta_tagErr
      (io_mshrTask_bits_snpHitReleaseMeta_tagErr),
    .io_out_bits_snpHitReleaseMeta_dataErr
      (io_mshrTask_bits_snpHitReleaseMeta_dataErr),
    .io_out_bits_tgtID                           (io_mshrTask_bits_tgtID),
    .io_out_bits_txnID                           (io_mshrTask_bits_txnID),
    .io_out_bits_homeNID                         (io_mshrTask_bits_homeNID),
    .io_out_bits_dbID                            (io_mshrTask_bits_dbID),
    .io_out_bits_chiOpcode                       (io_mshrTask_bits_chiOpcode),
    .io_out_bits_resp                            (io_mshrTask_bits_resp),
    .io_out_bits_fwdState                        (io_mshrTask_bits_fwdState),
    .io_out_bits_retToSrc                        (io_mshrTask_bits_retToSrc),
    .io_out_bits_likelyshared                    (io_mshrTask_bits_likelyshared),
    .io_out_bits_expCompAck                      (io_mshrTask_bits_expCompAck),
    .io_out_bits_allowRetry                      (io_mshrTask_bits_allowRetry),
    .io_out_bits_memAttr_allocate                (io_mshrTask_bits_memAttr_allocate),
    .io_out_bits_memAttr_cacheable               (io_mshrTask_bits_memAttr_cacheable),
    .io_out_bits_memAttr_ewa                     (io_mshrTask_bits_memAttr_ewa),
    .io_out_bits_traceTag                        (io_mshrTask_bits_traceTag),
    .io_out_bits_dataCheckErr                    (io_mshrTask_bits_dataCheckErr)
  );

  // ===== 容量计数: 在途流水请求(s2/s3) + 已占用 MSHR 数 =====
  logic [4:0] occTotal;
  always_comb begin
    occTotal = 5'd0;
    occTotal += 5'(io_pipeStatusVec_0_valid);
    occTotal += 5'(io_pipeStatusVec_1_valid);
    for (int k = 0; k < MSHRS; k++) occTotal += 5'(m_io_status_valid[k]);
  end
  wire mshrFull   = occTotal[4];        // >= 16: 阻塞 SinkB
  wire a_mshrFull = occTotal > 5'hE;    // >= 15: 留 1 槽给 SinkB, 阻塞 SinkA
  assign io_toReqArb_blockA_s1 = a_mshrFull;
  assign io_toReqArb_blockB_s1 = mshrFull;

  // ===== 分配指针 → MainPipe(one-hot 转下标, 高位补 0 至 8bit) =====
  assign io_toMainPipe_mshr_alloc_ptr = {4'h0, f_oh16_to_uint(mshrSelector_out_bits)};

  // ===== releaseBuf 写入 MSHR id(SinkC 命中槽优先选择) =====
  assign io_releaseBufWriteId = {4'h0, f_pri16(resp_sinkC_match_vec)};

  // ===== 嵌套回写数据 id: 各 MSHR nestedwbData 优先选择 =====
  wire [15:0] nestedwb_vec = {
    m_io_nestedwbData[15], m_io_nestedwbData[14], m_io_nestedwbData[13], m_io_nestedwbData[12], m_io_nestedwbData[11], m_io_nestedwbData[10], m_io_nestedwbData[9], m_io_nestedwbData[8], m_io_nestedwbData[7], m_io_nestedwbData[6], m_io_nestedwbData[5], m_io_nestedwbData[4], m_io_nestedwbData[3], m_io_nestedwbData[2], m_io_nestedwbData[1], m_io_nestedwbData[0]};
  assign io_nestedwbDataId_valid = |nestedwb_vec;
  assign io_nestedwbDataId_bits  = {4'h0, f_pri16(nestedwb_vec)};

  // ===== l2Miss(TopDown): 任一 MSHR 处理 channel A 的 CPU load/store miss =====
  logic l2miss_r;
  always_comb begin
    l2miss_r = 1'b0;
    for (int k = 0; k < MSHRS; k++)
      l2miss_r |= m_io_status_valid[k] & m_io_status_bits_channel[k][0]
                  & (m_io_status_bits_reqSource[k] == 5'h2
                     | m_io_status_bits_reqSource[k] == 5'h3);
  end
  assign io_l2Miss = l2miss_r;

  // ===== 性能计数: hpm_timers(每槽自占用起计时) + lmiss(>200 拍长 miss) =====
  reg [9:0] hpm_timers [MSHRS];
  always @(posedge clock or posedge reset)
    if (reset)
      for (int k = 0; k < MSHRS; k++) hpm_timers[k] <= 10'h0;
    else
      for (int k = 0; k < MSHRS; k++)
        hpm_timers[k] <= mshrAllocOH[k] ? 10'h1 : 10'(hpm_timers[k] + 10'h1);
  logic [3:0] lmiss_sum;
  always_comb begin
    lmiss_sum = 4'd0;
    for (int k = 0; k < MSHRS; k++)
      lmiss_sum += 4'(m_io_status_valid[k] & m_io_status_bits_will_free[k]
                      & (hpm_timers[k] > 10'hC8));
  end
  wire perf_refill = io_resps_rxdat_valid & io_resps_rxdat_respInfo_last;
  reg       perf01_s1, perf01_s2;
  reg [3:0] perf3_s1, perf3_s2;
  always @(posedge clock) begin
    perf01_s1 <= perf_refill; perf01_s2 <= perf01_s1;
    perf3_s1  <= lmiss_sum;   perf3_s2  <= perf3_s1;
  end
  assign io_perf_0_value = {5'h0, perf01_s2};  // l2_cache_refill
  assign io_perf_1_value = {5'h0, perf01_s2};  // l2_cache_rd_refill
  assign io_perf_3_value = {2'h0, perf3_s2};   // l2_cache_long_miss

  // ===== golden 死观测锥(BoringUtils probe 观测线, 综合下无扇出)镜像 =====
  // 目的: 让 MSHR 黑盒的 acquire_period_*/release_period_* 输出被消费,
  //       否则 impl 侧这些黑盒输出悬空 → FM 判为黑盒输入方向 → 与 golden(输出)失配。
  // 与 golden MSHRCtl.sv 逐字对齐: 消费黑盒周期输出汇入死 probe 线;
  //       另镜像 golden 的 64 位 timers_* 死寄存器 + REG 断言寄存器。
  // 均为 golden-only cone-dead 的对称复刻(bug-for-bug), 无功能扇出。
  wire [63:0] acquire_period_probe =
      (m_acquire_period_valid[0]  ? m_acquire_period_bits[0]  : 64'h0)
    | (m_acquire_period_valid[1]  ? m_acquire_period_bits[1]  : 64'h0)
    | (m_acquire_period_valid[2]  ? m_acquire_period_bits[2]  : 64'h0)
    | (m_acquire_period_valid[3]  ? m_acquire_period_bits[3]  : 64'h0)
    | (m_acquire_period_valid[4]  ? m_acquire_period_bits[4]  : 64'h0)
    | (m_acquire_period_valid[5]  ? m_acquire_period_bits[5]  : 64'h0)
    | (m_acquire_period_valid[6]  ? m_acquire_period_bits[6]  : 64'h0)
    | (m_acquire_period_valid[7]  ? m_acquire_period_bits[7]  : 64'h0)
    | (m_acquire_period_valid[8]  ? m_acquire_period_bits[8]  : 64'h0)
    | (m_acquire_period_valid[9]  ? m_acquire_period_bits[9]  : 64'h0)
    | (m_acquire_period_valid[10] ? m_acquire_period_bits[10] : 64'h0)
    | (m_acquire_period_valid[11] ? m_acquire_period_bits[11] : 64'h0)
    | (m_acquire_period_valid[12] ? m_acquire_period_bits[12] : 64'h0)
    | (m_acquire_period_valid[13] ? m_acquire_period_bits[13] : 64'h0)
    | (m_acquire_period_valid[14] ? m_acquire_period_bits[14] : 64'h0)
    | (m_acquire_period_valid[15] ? m_acquire_period_bits[15] : 64'h0);
  wire [63:0] release_period_probe =
      (m_release_period_valid[0]  ? m_release_period_bits[0]  : 64'h0)
    | (m_release_period_valid[1]  ? m_release_period_bits[1]  : 64'h0)
    | (m_release_period_valid[2]  ? m_release_period_bits[2]  : 64'h0)
    | (m_release_period_valid[3]  ? m_release_period_bits[3]  : 64'h0)
    | (m_release_period_valid[4]  ? m_release_period_bits[4]  : 64'h0)
    | (m_release_period_valid[5]  ? m_release_period_bits[5]  : 64'h0)
    | (m_release_period_valid[6]  ? m_release_period_bits[6]  : 64'h0)
    | (m_release_period_valid[7]  ? m_release_period_bits[7]  : 64'h0)
    | (m_release_period_valid[8]  ? m_release_period_bits[8]  : 64'h0)
    | (m_release_period_valid[9]  ? m_release_period_bits[9]  : 64'h0)
    | (m_release_period_valid[10] ? m_release_period_bits[10] : 64'h0)
    | (m_release_period_valid[11] ? m_release_period_bits[11] : 64'h0)
    | (m_release_period_valid[12] ? m_release_period_bits[12] : 64'h0)
    | (m_release_period_valid[13] ? m_release_period_bits[13] : 64'h0)
    | (m_release_period_valid[14] ? m_release_period_bits[14] : 64'h0)
    | (m_release_period_valid[15] ? m_release_period_bits[15] : 64'h0);
  wire acquire_period_en_probe =
      m_acquire_period_valid[0]  | m_acquire_period_valid[1]
    | m_acquire_period_valid[2]  | m_acquire_period_valid[3]
    | m_acquire_period_valid[4]  | m_acquire_period_valid[5]
    | m_acquire_period_valid[6]  | m_acquire_period_valid[7]
    | m_acquire_period_valid[8]  | m_acquire_period_valid[9]
    | m_acquire_period_valid[10] | m_acquire_period_valid[11]
    | m_acquire_period_valid[12] | m_acquire_period_valid[13]
    | m_acquire_period_valid[14] | m_acquire_period_valid[15];
  wire release_period_en_probe =
      m_release_period_valid[0]  | m_release_period_valid[1]
    | m_release_period_valid[2]  | m_release_period_valid[3]
    | m_release_period_valid[4]  | m_release_period_valid[5]
    | m_release_period_valid[6]  | m_release_period_valid[7]
    | m_release_period_valid[8]  | m_release_period_valid[9]
    | m_release_period_valid[10] | m_release_period_valid[11]
    | m_release_period_valid[12] | m_release_period_valid[13]
    | m_release_period_valid[14] | m_release_period_valid[15];

  // ===== 输出展平: 内部数组 → golden 扁平端口 =====
  assign io_msStatus_0_bits_is_miss = m_io_status_bits_is_miss[0];
  assign io_msStatus_1_bits_is_miss = m_io_status_bits_is_miss[1];
  assign io_msStatus_2_bits_is_miss = m_io_status_bits_is_miss[2];
  assign io_msStatus_3_bits_is_miss = m_io_status_bits_is_miss[3];
  assign io_msStatus_4_bits_is_miss = m_io_status_bits_is_miss[4];
  assign io_msStatus_5_bits_is_miss = m_io_status_bits_is_miss[5];
  assign io_msStatus_6_bits_is_miss = m_io_status_bits_is_miss[6];
  assign io_msStatus_7_bits_is_miss = m_io_status_bits_is_miss[7];
  assign io_msStatus_8_bits_is_miss = m_io_status_bits_is_miss[8];
  assign io_msStatus_9_bits_is_miss = m_io_status_bits_is_miss[9];
  assign io_msStatus_10_bits_is_miss = m_io_status_bits_is_miss[10];
  assign io_msStatus_11_bits_is_miss = m_io_status_bits_is_miss[11];
  assign io_msStatus_12_bits_is_miss = m_io_status_bits_is_miss[12];
  assign io_msStatus_13_bits_is_miss = m_io_status_bits_is_miss[13];
  assign io_msStatus_14_bits_is_miss = m_io_status_bits_is_miss[14];
  assign io_msStatus_15_bits_is_miss = m_io_status_bits_is_miss[15];
  assign io_msStatus_0_bits_is_prefetch = m_io_status_bits_is_prefetch[0];
  assign io_msStatus_1_bits_is_prefetch = m_io_status_bits_is_prefetch[1];
  assign io_msStatus_2_bits_is_prefetch = m_io_status_bits_is_prefetch[2];
  assign io_msStatus_3_bits_is_prefetch = m_io_status_bits_is_prefetch[3];
  assign io_msStatus_4_bits_is_prefetch = m_io_status_bits_is_prefetch[4];
  assign io_msStatus_5_bits_is_prefetch = m_io_status_bits_is_prefetch[5];
  assign io_msStatus_6_bits_is_prefetch = m_io_status_bits_is_prefetch[6];
  assign io_msStatus_7_bits_is_prefetch = m_io_status_bits_is_prefetch[7];
  assign io_msStatus_8_bits_is_prefetch = m_io_status_bits_is_prefetch[8];
  assign io_msStatus_9_bits_is_prefetch = m_io_status_bits_is_prefetch[9];
  assign io_msStatus_10_bits_is_prefetch = m_io_status_bits_is_prefetch[10];
  assign io_msStatus_11_bits_is_prefetch = m_io_status_bits_is_prefetch[11];
  assign io_msStatus_12_bits_is_prefetch = m_io_status_bits_is_prefetch[12];
  assign io_msStatus_13_bits_is_prefetch = m_io_status_bits_is_prefetch[13];
  assign io_msStatus_14_bits_is_prefetch = m_io_status_bits_is_prefetch[14];
  assign io_msStatus_15_bits_is_prefetch = m_io_status_bits_is_prefetch[15];
  assign io_msInfo_0_valid = m_io_msInfo_valid[0];
  assign io_msInfo_1_valid = m_io_msInfo_valid[1];
  assign io_msInfo_2_valid = m_io_msInfo_valid[2];
  assign io_msInfo_3_valid = m_io_msInfo_valid[3];
  assign io_msInfo_4_valid = m_io_msInfo_valid[4];
  assign io_msInfo_5_valid = m_io_msInfo_valid[5];
  assign io_msInfo_6_valid = m_io_msInfo_valid[6];
  assign io_msInfo_7_valid = m_io_msInfo_valid[7];
  assign io_msInfo_8_valid = m_io_msInfo_valid[8];
  assign io_msInfo_9_valid = m_io_msInfo_valid[9];
  assign io_msInfo_10_valid = m_io_msInfo_valid[10];
  assign io_msInfo_11_valid = m_io_msInfo_valid[11];
  assign io_msInfo_12_valid = m_io_msInfo_valid[12];
  assign io_msInfo_13_valid = m_io_msInfo_valid[13];
  assign io_msInfo_14_valid = m_io_msInfo_valid[14];
  assign io_msInfo_15_valid = m_io_msInfo_valid[15];
  assign io_msInfo_0_bits_channel = m_io_msInfo_bits_channel[0];
  assign io_msInfo_1_bits_channel = m_io_msInfo_bits_channel[1];
  assign io_msInfo_2_bits_channel = m_io_msInfo_bits_channel[2];
  assign io_msInfo_3_bits_channel = m_io_msInfo_bits_channel[3];
  assign io_msInfo_4_bits_channel = m_io_msInfo_bits_channel[4];
  assign io_msInfo_5_bits_channel = m_io_msInfo_bits_channel[5];
  assign io_msInfo_6_bits_channel = m_io_msInfo_bits_channel[6];
  assign io_msInfo_7_bits_channel = m_io_msInfo_bits_channel[7];
  assign io_msInfo_8_bits_channel = m_io_msInfo_bits_channel[8];
  assign io_msInfo_9_bits_channel = m_io_msInfo_bits_channel[9];
  assign io_msInfo_10_bits_channel = m_io_msInfo_bits_channel[10];
  assign io_msInfo_11_bits_channel = m_io_msInfo_bits_channel[11];
  assign io_msInfo_12_bits_channel = m_io_msInfo_bits_channel[12];
  assign io_msInfo_13_bits_channel = m_io_msInfo_bits_channel[13];
  assign io_msInfo_14_bits_channel = m_io_msInfo_bits_channel[14];
  assign io_msInfo_15_bits_channel = m_io_msInfo_bits_channel[15];
  assign io_msInfo_0_bits_set = m_io_msInfo_bits_set[0];
  assign io_msInfo_1_bits_set = m_io_msInfo_bits_set[1];
  assign io_msInfo_2_bits_set = m_io_msInfo_bits_set[2];
  assign io_msInfo_3_bits_set = m_io_msInfo_bits_set[3];
  assign io_msInfo_4_bits_set = m_io_msInfo_bits_set[4];
  assign io_msInfo_5_bits_set = m_io_msInfo_bits_set[5];
  assign io_msInfo_6_bits_set = m_io_msInfo_bits_set[6];
  assign io_msInfo_7_bits_set = m_io_msInfo_bits_set[7];
  assign io_msInfo_8_bits_set = m_io_msInfo_bits_set[8];
  assign io_msInfo_9_bits_set = m_io_msInfo_bits_set[9];
  assign io_msInfo_10_bits_set = m_io_msInfo_bits_set[10];
  assign io_msInfo_11_bits_set = m_io_msInfo_bits_set[11];
  assign io_msInfo_12_bits_set = m_io_msInfo_bits_set[12];
  assign io_msInfo_13_bits_set = m_io_msInfo_bits_set[13];
  assign io_msInfo_14_bits_set = m_io_msInfo_bits_set[14];
  assign io_msInfo_15_bits_set = m_io_msInfo_bits_set[15];
  assign io_msInfo_0_bits_way = m_io_msInfo_bits_way[0];
  assign io_msInfo_1_bits_way = m_io_msInfo_bits_way[1];
  assign io_msInfo_2_bits_way = m_io_msInfo_bits_way[2];
  assign io_msInfo_3_bits_way = m_io_msInfo_bits_way[3];
  assign io_msInfo_4_bits_way = m_io_msInfo_bits_way[4];
  assign io_msInfo_5_bits_way = m_io_msInfo_bits_way[5];
  assign io_msInfo_6_bits_way = m_io_msInfo_bits_way[6];
  assign io_msInfo_7_bits_way = m_io_msInfo_bits_way[7];
  assign io_msInfo_8_bits_way = m_io_msInfo_bits_way[8];
  assign io_msInfo_9_bits_way = m_io_msInfo_bits_way[9];
  assign io_msInfo_10_bits_way = m_io_msInfo_bits_way[10];
  assign io_msInfo_11_bits_way = m_io_msInfo_bits_way[11];
  assign io_msInfo_12_bits_way = m_io_msInfo_bits_way[12];
  assign io_msInfo_13_bits_way = m_io_msInfo_bits_way[13];
  assign io_msInfo_14_bits_way = m_io_msInfo_bits_way[14];
  assign io_msInfo_15_bits_way = m_io_msInfo_bits_way[15];
  assign io_msInfo_0_bits_reqTag = m_io_msInfo_bits_reqTag[0];
  assign io_msInfo_1_bits_reqTag = m_io_msInfo_bits_reqTag[1];
  assign io_msInfo_2_bits_reqTag = m_io_msInfo_bits_reqTag[2];
  assign io_msInfo_3_bits_reqTag = m_io_msInfo_bits_reqTag[3];
  assign io_msInfo_4_bits_reqTag = m_io_msInfo_bits_reqTag[4];
  assign io_msInfo_5_bits_reqTag = m_io_msInfo_bits_reqTag[5];
  assign io_msInfo_6_bits_reqTag = m_io_msInfo_bits_reqTag[6];
  assign io_msInfo_7_bits_reqTag = m_io_msInfo_bits_reqTag[7];
  assign io_msInfo_8_bits_reqTag = m_io_msInfo_bits_reqTag[8];
  assign io_msInfo_9_bits_reqTag = m_io_msInfo_bits_reqTag[9];
  assign io_msInfo_10_bits_reqTag = m_io_msInfo_bits_reqTag[10];
  assign io_msInfo_11_bits_reqTag = m_io_msInfo_bits_reqTag[11];
  assign io_msInfo_12_bits_reqTag = m_io_msInfo_bits_reqTag[12];
  assign io_msInfo_13_bits_reqTag = m_io_msInfo_bits_reqTag[13];
  assign io_msInfo_14_bits_reqTag = m_io_msInfo_bits_reqTag[14];
  assign io_msInfo_15_bits_reqTag = m_io_msInfo_bits_reqTag[15];
  assign io_msInfo_0_bits_willFree = m_io_msInfo_bits_willFree[0];
  assign io_msInfo_1_bits_willFree = m_io_msInfo_bits_willFree[1];
  assign io_msInfo_2_bits_willFree = m_io_msInfo_bits_willFree[2];
  assign io_msInfo_3_bits_willFree = m_io_msInfo_bits_willFree[3];
  assign io_msInfo_4_bits_willFree = m_io_msInfo_bits_willFree[4];
  assign io_msInfo_5_bits_willFree = m_io_msInfo_bits_willFree[5];
  assign io_msInfo_6_bits_willFree = m_io_msInfo_bits_willFree[6];
  assign io_msInfo_7_bits_willFree = m_io_msInfo_bits_willFree[7];
  assign io_msInfo_8_bits_willFree = m_io_msInfo_bits_willFree[8];
  assign io_msInfo_9_bits_willFree = m_io_msInfo_bits_willFree[9];
  assign io_msInfo_10_bits_willFree = m_io_msInfo_bits_willFree[10];
  assign io_msInfo_11_bits_willFree = m_io_msInfo_bits_willFree[11];
  assign io_msInfo_12_bits_willFree = m_io_msInfo_bits_willFree[12];
  assign io_msInfo_13_bits_willFree = m_io_msInfo_bits_willFree[13];
  assign io_msInfo_14_bits_willFree = m_io_msInfo_bits_willFree[14];
  assign io_msInfo_15_bits_willFree = m_io_msInfo_bits_willFree[15];
  assign io_msInfo_0_bits_aliasTask = m_io_msInfo_bits_aliasTask[0];
  assign io_msInfo_1_bits_aliasTask = m_io_msInfo_bits_aliasTask[1];
  assign io_msInfo_2_bits_aliasTask = m_io_msInfo_bits_aliasTask[2];
  assign io_msInfo_3_bits_aliasTask = m_io_msInfo_bits_aliasTask[3];
  assign io_msInfo_4_bits_aliasTask = m_io_msInfo_bits_aliasTask[4];
  assign io_msInfo_5_bits_aliasTask = m_io_msInfo_bits_aliasTask[5];
  assign io_msInfo_6_bits_aliasTask = m_io_msInfo_bits_aliasTask[6];
  assign io_msInfo_7_bits_aliasTask = m_io_msInfo_bits_aliasTask[7];
  assign io_msInfo_8_bits_aliasTask = m_io_msInfo_bits_aliasTask[8];
  assign io_msInfo_9_bits_aliasTask = m_io_msInfo_bits_aliasTask[9];
  assign io_msInfo_10_bits_aliasTask = m_io_msInfo_bits_aliasTask[10];
  assign io_msInfo_11_bits_aliasTask = m_io_msInfo_bits_aliasTask[11];
  assign io_msInfo_12_bits_aliasTask = m_io_msInfo_bits_aliasTask[12];
  assign io_msInfo_13_bits_aliasTask = m_io_msInfo_bits_aliasTask[13];
  assign io_msInfo_14_bits_aliasTask = m_io_msInfo_bits_aliasTask[14];
  assign io_msInfo_15_bits_aliasTask = m_io_msInfo_bits_aliasTask[15];
  assign io_msInfo_0_bits_needRelease = m_io_msInfo_bits_needRelease[0];
  assign io_msInfo_1_bits_needRelease = m_io_msInfo_bits_needRelease[1];
  assign io_msInfo_2_bits_needRelease = m_io_msInfo_bits_needRelease[2];
  assign io_msInfo_3_bits_needRelease = m_io_msInfo_bits_needRelease[3];
  assign io_msInfo_4_bits_needRelease = m_io_msInfo_bits_needRelease[4];
  assign io_msInfo_5_bits_needRelease = m_io_msInfo_bits_needRelease[5];
  assign io_msInfo_6_bits_needRelease = m_io_msInfo_bits_needRelease[6];
  assign io_msInfo_7_bits_needRelease = m_io_msInfo_bits_needRelease[7];
  assign io_msInfo_8_bits_needRelease = m_io_msInfo_bits_needRelease[8];
  assign io_msInfo_9_bits_needRelease = m_io_msInfo_bits_needRelease[9];
  assign io_msInfo_10_bits_needRelease = m_io_msInfo_bits_needRelease[10];
  assign io_msInfo_11_bits_needRelease = m_io_msInfo_bits_needRelease[11];
  assign io_msInfo_12_bits_needRelease = m_io_msInfo_bits_needRelease[12];
  assign io_msInfo_13_bits_needRelease = m_io_msInfo_bits_needRelease[13];
  assign io_msInfo_14_bits_needRelease = m_io_msInfo_bits_needRelease[14];
  assign io_msInfo_15_bits_needRelease = m_io_msInfo_bits_needRelease[15];
  assign io_msInfo_0_bits_blockRefill = m_io_msInfo_bits_blockRefill[0];
  assign io_msInfo_1_bits_blockRefill = m_io_msInfo_bits_blockRefill[1];
  assign io_msInfo_2_bits_blockRefill = m_io_msInfo_bits_blockRefill[2];
  assign io_msInfo_3_bits_blockRefill = m_io_msInfo_bits_blockRefill[3];
  assign io_msInfo_4_bits_blockRefill = m_io_msInfo_bits_blockRefill[4];
  assign io_msInfo_5_bits_blockRefill = m_io_msInfo_bits_blockRefill[5];
  assign io_msInfo_6_bits_blockRefill = m_io_msInfo_bits_blockRefill[6];
  assign io_msInfo_7_bits_blockRefill = m_io_msInfo_bits_blockRefill[7];
  assign io_msInfo_8_bits_blockRefill = m_io_msInfo_bits_blockRefill[8];
  assign io_msInfo_9_bits_blockRefill = m_io_msInfo_bits_blockRefill[9];
  assign io_msInfo_10_bits_blockRefill = m_io_msInfo_bits_blockRefill[10];
  assign io_msInfo_11_bits_blockRefill = m_io_msInfo_bits_blockRefill[11];
  assign io_msInfo_12_bits_blockRefill = m_io_msInfo_bits_blockRefill[12];
  assign io_msInfo_13_bits_blockRefill = m_io_msInfo_bits_blockRefill[13];
  assign io_msInfo_14_bits_blockRefill = m_io_msInfo_bits_blockRefill[14];
  assign io_msInfo_15_bits_blockRefill = m_io_msInfo_bits_blockRefill[15];
  assign io_msInfo_0_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[0];
  assign io_msInfo_1_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[1];
  assign io_msInfo_2_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[2];
  assign io_msInfo_3_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[3];
  assign io_msInfo_4_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[4];
  assign io_msInfo_5_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[5];
  assign io_msInfo_6_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[6];
  assign io_msInfo_7_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[7];
  assign io_msInfo_8_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[8];
  assign io_msInfo_9_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[9];
  assign io_msInfo_10_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[10];
  assign io_msInfo_11_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[11];
  assign io_msInfo_12_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[12];
  assign io_msInfo_13_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[13];
  assign io_msInfo_14_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[14];
  assign io_msInfo_15_bits_meta_dirty = m_io_msInfo_bits_meta_dirty[15];
  assign io_msInfo_0_bits_meta_state = m_io_msInfo_bits_meta_state[0];
  assign io_msInfo_1_bits_meta_state = m_io_msInfo_bits_meta_state[1];
  assign io_msInfo_2_bits_meta_state = m_io_msInfo_bits_meta_state[2];
  assign io_msInfo_3_bits_meta_state = m_io_msInfo_bits_meta_state[3];
  assign io_msInfo_4_bits_meta_state = m_io_msInfo_bits_meta_state[4];
  assign io_msInfo_5_bits_meta_state = m_io_msInfo_bits_meta_state[5];
  assign io_msInfo_6_bits_meta_state = m_io_msInfo_bits_meta_state[6];
  assign io_msInfo_7_bits_meta_state = m_io_msInfo_bits_meta_state[7];
  assign io_msInfo_8_bits_meta_state = m_io_msInfo_bits_meta_state[8];
  assign io_msInfo_9_bits_meta_state = m_io_msInfo_bits_meta_state[9];
  assign io_msInfo_10_bits_meta_state = m_io_msInfo_bits_meta_state[10];
  assign io_msInfo_11_bits_meta_state = m_io_msInfo_bits_meta_state[11];
  assign io_msInfo_12_bits_meta_state = m_io_msInfo_bits_meta_state[12];
  assign io_msInfo_13_bits_meta_state = m_io_msInfo_bits_meta_state[13];
  assign io_msInfo_14_bits_meta_state = m_io_msInfo_bits_meta_state[14];
  assign io_msInfo_15_bits_meta_state = m_io_msInfo_bits_meta_state[15];
  assign io_msInfo_0_bits_meta_clients = m_io_msInfo_bits_meta_clients[0];
  assign io_msInfo_1_bits_meta_clients = m_io_msInfo_bits_meta_clients[1];
  assign io_msInfo_2_bits_meta_clients = m_io_msInfo_bits_meta_clients[2];
  assign io_msInfo_3_bits_meta_clients = m_io_msInfo_bits_meta_clients[3];
  assign io_msInfo_4_bits_meta_clients = m_io_msInfo_bits_meta_clients[4];
  assign io_msInfo_5_bits_meta_clients = m_io_msInfo_bits_meta_clients[5];
  assign io_msInfo_6_bits_meta_clients = m_io_msInfo_bits_meta_clients[6];
  assign io_msInfo_7_bits_meta_clients = m_io_msInfo_bits_meta_clients[7];
  assign io_msInfo_8_bits_meta_clients = m_io_msInfo_bits_meta_clients[8];
  assign io_msInfo_9_bits_meta_clients = m_io_msInfo_bits_meta_clients[9];
  assign io_msInfo_10_bits_meta_clients = m_io_msInfo_bits_meta_clients[10];
  assign io_msInfo_11_bits_meta_clients = m_io_msInfo_bits_meta_clients[11];
  assign io_msInfo_12_bits_meta_clients = m_io_msInfo_bits_meta_clients[12];
  assign io_msInfo_13_bits_meta_clients = m_io_msInfo_bits_meta_clients[13];
  assign io_msInfo_14_bits_meta_clients = m_io_msInfo_bits_meta_clients[14];
  assign io_msInfo_15_bits_meta_clients = m_io_msInfo_bits_meta_clients[15];
  assign io_msInfo_0_bits_meta_alias = m_io_msInfo_bits_meta_alias[0];
  assign io_msInfo_1_bits_meta_alias = m_io_msInfo_bits_meta_alias[1];
  assign io_msInfo_2_bits_meta_alias = m_io_msInfo_bits_meta_alias[2];
  assign io_msInfo_3_bits_meta_alias = m_io_msInfo_bits_meta_alias[3];
  assign io_msInfo_4_bits_meta_alias = m_io_msInfo_bits_meta_alias[4];
  assign io_msInfo_5_bits_meta_alias = m_io_msInfo_bits_meta_alias[5];
  assign io_msInfo_6_bits_meta_alias = m_io_msInfo_bits_meta_alias[6];
  assign io_msInfo_7_bits_meta_alias = m_io_msInfo_bits_meta_alias[7];
  assign io_msInfo_8_bits_meta_alias = m_io_msInfo_bits_meta_alias[8];
  assign io_msInfo_9_bits_meta_alias = m_io_msInfo_bits_meta_alias[9];
  assign io_msInfo_10_bits_meta_alias = m_io_msInfo_bits_meta_alias[10];
  assign io_msInfo_11_bits_meta_alias = m_io_msInfo_bits_meta_alias[11];
  assign io_msInfo_12_bits_meta_alias = m_io_msInfo_bits_meta_alias[12];
  assign io_msInfo_13_bits_meta_alias = m_io_msInfo_bits_meta_alias[13];
  assign io_msInfo_14_bits_meta_alias = m_io_msInfo_bits_meta_alias[14];
  assign io_msInfo_15_bits_meta_alias = m_io_msInfo_bits_meta_alias[15];
  assign io_msInfo_0_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[0];
  assign io_msInfo_1_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[1];
  assign io_msInfo_2_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[2];
  assign io_msInfo_3_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[3];
  assign io_msInfo_4_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[4];
  assign io_msInfo_5_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[5];
  assign io_msInfo_6_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[6];
  assign io_msInfo_7_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[7];
  assign io_msInfo_8_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[8];
  assign io_msInfo_9_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[9];
  assign io_msInfo_10_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[10];
  assign io_msInfo_11_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[11];
  assign io_msInfo_12_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[12];
  assign io_msInfo_13_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[13];
  assign io_msInfo_14_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[14];
  assign io_msInfo_15_bits_meta_prefetch = m_io_msInfo_bits_meta_prefetch[15];
  assign io_msInfo_0_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[0];
  assign io_msInfo_1_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[1];
  assign io_msInfo_2_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[2];
  assign io_msInfo_3_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[3];
  assign io_msInfo_4_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[4];
  assign io_msInfo_5_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[5];
  assign io_msInfo_6_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[6];
  assign io_msInfo_7_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[7];
  assign io_msInfo_8_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[8];
  assign io_msInfo_9_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[9];
  assign io_msInfo_10_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[10];
  assign io_msInfo_11_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[11];
  assign io_msInfo_12_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[12];
  assign io_msInfo_13_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[13];
  assign io_msInfo_14_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[14];
  assign io_msInfo_15_bits_meta_prefetchSrc = m_io_msInfo_bits_meta_prefetchSrc[15];
  assign io_msInfo_0_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[0];
  assign io_msInfo_1_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[1];
  assign io_msInfo_2_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[2];
  assign io_msInfo_3_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[3];
  assign io_msInfo_4_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[4];
  assign io_msInfo_5_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[5];
  assign io_msInfo_6_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[6];
  assign io_msInfo_7_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[7];
  assign io_msInfo_8_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[8];
  assign io_msInfo_9_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[9];
  assign io_msInfo_10_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[10];
  assign io_msInfo_11_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[11];
  assign io_msInfo_12_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[12];
  assign io_msInfo_13_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[13];
  assign io_msInfo_14_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[14];
  assign io_msInfo_15_bits_meta_accessed = m_io_msInfo_bits_meta_accessed[15];
  assign io_msInfo_0_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[0];
  assign io_msInfo_1_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[1];
  assign io_msInfo_2_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[2];
  assign io_msInfo_3_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[3];
  assign io_msInfo_4_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[4];
  assign io_msInfo_5_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[5];
  assign io_msInfo_6_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[6];
  assign io_msInfo_7_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[7];
  assign io_msInfo_8_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[8];
  assign io_msInfo_9_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[9];
  assign io_msInfo_10_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[10];
  assign io_msInfo_11_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[11];
  assign io_msInfo_12_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[12];
  assign io_msInfo_13_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[13];
  assign io_msInfo_14_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[14];
  assign io_msInfo_15_bits_meta_tagErr = m_io_msInfo_bits_meta_tagErr[15];
  assign io_msInfo_0_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[0];
  assign io_msInfo_1_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[1];
  assign io_msInfo_2_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[2];
  assign io_msInfo_3_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[3];
  assign io_msInfo_4_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[4];
  assign io_msInfo_5_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[5];
  assign io_msInfo_6_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[6];
  assign io_msInfo_7_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[7];
  assign io_msInfo_8_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[8];
  assign io_msInfo_9_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[9];
  assign io_msInfo_10_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[10];
  assign io_msInfo_11_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[11];
  assign io_msInfo_12_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[12];
  assign io_msInfo_13_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[13];
  assign io_msInfo_14_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[14];
  assign io_msInfo_15_bits_meta_dataErr = m_io_msInfo_bits_meta_dataErr[15];
  assign io_msInfo_0_bits_metaTag = m_io_msInfo_bits_metaTag[0];
  assign io_msInfo_1_bits_metaTag = m_io_msInfo_bits_metaTag[1];
  assign io_msInfo_2_bits_metaTag = m_io_msInfo_bits_metaTag[2];
  assign io_msInfo_3_bits_metaTag = m_io_msInfo_bits_metaTag[3];
  assign io_msInfo_4_bits_metaTag = m_io_msInfo_bits_metaTag[4];
  assign io_msInfo_5_bits_metaTag = m_io_msInfo_bits_metaTag[5];
  assign io_msInfo_6_bits_metaTag = m_io_msInfo_bits_metaTag[6];
  assign io_msInfo_7_bits_metaTag = m_io_msInfo_bits_metaTag[7];
  assign io_msInfo_8_bits_metaTag = m_io_msInfo_bits_metaTag[8];
  assign io_msInfo_9_bits_metaTag = m_io_msInfo_bits_metaTag[9];
  assign io_msInfo_10_bits_metaTag = m_io_msInfo_bits_metaTag[10];
  assign io_msInfo_11_bits_metaTag = m_io_msInfo_bits_metaTag[11];
  assign io_msInfo_12_bits_metaTag = m_io_msInfo_bits_metaTag[12];
  assign io_msInfo_13_bits_metaTag = m_io_msInfo_bits_metaTag[13];
  assign io_msInfo_14_bits_metaTag = m_io_msInfo_bits_metaTag[14];
  assign io_msInfo_15_bits_metaTag = m_io_msInfo_bits_metaTag[15];
  assign io_msInfo_0_bits_dirHit = m_io_msInfo_bits_dirHit[0];
  assign io_msInfo_1_bits_dirHit = m_io_msInfo_bits_dirHit[1];
  assign io_msInfo_2_bits_dirHit = m_io_msInfo_bits_dirHit[2];
  assign io_msInfo_3_bits_dirHit = m_io_msInfo_bits_dirHit[3];
  assign io_msInfo_4_bits_dirHit = m_io_msInfo_bits_dirHit[4];
  assign io_msInfo_5_bits_dirHit = m_io_msInfo_bits_dirHit[5];
  assign io_msInfo_6_bits_dirHit = m_io_msInfo_bits_dirHit[6];
  assign io_msInfo_7_bits_dirHit = m_io_msInfo_bits_dirHit[7];
  assign io_msInfo_8_bits_dirHit = m_io_msInfo_bits_dirHit[8];
  assign io_msInfo_9_bits_dirHit = m_io_msInfo_bits_dirHit[9];
  assign io_msInfo_10_bits_dirHit = m_io_msInfo_bits_dirHit[10];
  assign io_msInfo_11_bits_dirHit = m_io_msInfo_bits_dirHit[11];
  assign io_msInfo_12_bits_dirHit = m_io_msInfo_bits_dirHit[12];
  assign io_msInfo_13_bits_dirHit = m_io_msInfo_bits_dirHit[13];
  assign io_msInfo_14_bits_dirHit = m_io_msInfo_bits_dirHit[14];
  assign io_msInfo_15_bits_dirHit = m_io_msInfo_bits_dirHit[15];
  assign io_msInfo_0_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[0];
  assign io_msInfo_1_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[1];
  assign io_msInfo_2_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[2];
  assign io_msInfo_3_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[3];
  assign io_msInfo_4_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[4];
  assign io_msInfo_5_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[5];
  assign io_msInfo_6_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[6];
  assign io_msInfo_7_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[7];
  assign io_msInfo_8_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[8];
  assign io_msInfo_9_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[9];
  assign io_msInfo_10_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[10];
  assign io_msInfo_11_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[11];
  assign io_msInfo_12_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[12];
  assign io_msInfo_13_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[13];
  assign io_msInfo_14_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[14];
  assign io_msInfo_15_bits_isAcqOrPrefetch = m_io_msInfo_bits_isAcqOrPrefetch[15];
  assign io_msInfo_0_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[0];
  assign io_msInfo_1_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[1];
  assign io_msInfo_2_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[2];
  assign io_msInfo_3_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[3];
  assign io_msInfo_4_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[4];
  assign io_msInfo_5_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[5];
  assign io_msInfo_6_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[6];
  assign io_msInfo_7_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[7];
  assign io_msInfo_8_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[8];
  assign io_msInfo_9_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[9];
  assign io_msInfo_10_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[10];
  assign io_msInfo_11_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[11];
  assign io_msInfo_12_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[12];
  assign io_msInfo_13_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[13];
  assign io_msInfo_14_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[14];
  assign io_msInfo_15_bits_isPrefetch = m_io_msInfo_bits_isPrefetch[15];
  assign io_msInfo_0_bits_param = m_io_msInfo_bits_param[0];
  assign io_msInfo_1_bits_param = m_io_msInfo_bits_param[1];
  assign io_msInfo_2_bits_param = m_io_msInfo_bits_param[2];
  assign io_msInfo_3_bits_param = m_io_msInfo_bits_param[3];
  assign io_msInfo_4_bits_param = m_io_msInfo_bits_param[4];
  assign io_msInfo_5_bits_param = m_io_msInfo_bits_param[5];
  assign io_msInfo_6_bits_param = m_io_msInfo_bits_param[6];
  assign io_msInfo_7_bits_param = m_io_msInfo_bits_param[7];
  assign io_msInfo_8_bits_param = m_io_msInfo_bits_param[8];
  assign io_msInfo_9_bits_param = m_io_msInfo_bits_param[9];
  assign io_msInfo_10_bits_param = m_io_msInfo_bits_param[10];
  assign io_msInfo_11_bits_param = m_io_msInfo_bits_param[11];
  assign io_msInfo_12_bits_param = m_io_msInfo_bits_param[12];
  assign io_msInfo_13_bits_param = m_io_msInfo_bits_param[13];
  assign io_msInfo_14_bits_param = m_io_msInfo_bits_param[14];
  assign io_msInfo_15_bits_param = m_io_msInfo_bits_param[15];
  assign io_msInfo_0_bits_mergeA = m_io_msInfo_bits_mergeA[0];
  assign io_msInfo_1_bits_mergeA = m_io_msInfo_bits_mergeA[1];
  assign io_msInfo_2_bits_mergeA = m_io_msInfo_bits_mergeA[2];
  assign io_msInfo_3_bits_mergeA = m_io_msInfo_bits_mergeA[3];
  assign io_msInfo_4_bits_mergeA = m_io_msInfo_bits_mergeA[4];
  assign io_msInfo_5_bits_mergeA = m_io_msInfo_bits_mergeA[5];
  assign io_msInfo_6_bits_mergeA = m_io_msInfo_bits_mergeA[6];
  assign io_msInfo_7_bits_mergeA = m_io_msInfo_bits_mergeA[7];
  assign io_msInfo_8_bits_mergeA = m_io_msInfo_bits_mergeA[8];
  assign io_msInfo_9_bits_mergeA = m_io_msInfo_bits_mergeA[9];
  assign io_msInfo_10_bits_mergeA = m_io_msInfo_bits_mergeA[10];
  assign io_msInfo_11_bits_mergeA = m_io_msInfo_bits_mergeA[11];
  assign io_msInfo_12_bits_mergeA = m_io_msInfo_bits_mergeA[12];
  assign io_msInfo_13_bits_mergeA = m_io_msInfo_bits_mergeA[13];
  assign io_msInfo_14_bits_mergeA = m_io_msInfo_bits_mergeA[14];
  assign io_msInfo_15_bits_mergeA = m_io_msInfo_bits_mergeA[15];
  assign io_msInfo_0_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[0];
  assign io_msInfo_1_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[1];
  assign io_msInfo_2_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[2];
  assign io_msInfo_3_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[3];
  assign io_msInfo_4_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[4];
  assign io_msInfo_5_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[5];
  assign io_msInfo_6_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[6];
  assign io_msInfo_7_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[7];
  assign io_msInfo_8_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[8];
  assign io_msInfo_9_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[9];
  assign io_msInfo_10_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[10];
  assign io_msInfo_11_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[11];
  assign io_msInfo_12_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[12];
  assign io_msInfo_13_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[13];
  assign io_msInfo_14_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[14];
  assign io_msInfo_15_bits_w_grantfirst = m_io_msInfo_bits_w_grantfirst[15];
  assign io_msInfo_0_bits_s_release = m_io_msInfo_bits_s_release[0];
  assign io_msInfo_1_bits_s_release = m_io_msInfo_bits_s_release[1];
  assign io_msInfo_2_bits_s_release = m_io_msInfo_bits_s_release[2];
  assign io_msInfo_3_bits_s_release = m_io_msInfo_bits_s_release[3];
  assign io_msInfo_4_bits_s_release = m_io_msInfo_bits_s_release[4];
  assign io_msInfo_5_bits_s_release = m_io_msInfo_bits_s_release[5];
  assign io_msInfo_6_bits_s_release = m_io_msInfo_bits_s_release[6];
  assign io_msInfo_7_bits_s_release = m_io_msInfo_bits_s_release[7];
  assign io_msInfo_8_bits_s_release = m_io_msInfo_bits_s_release[8];
  assign io_msInfo_9_bits_s_release = m_io_msInfo_bits_s_release[9];
  assign io_msInfo_10_bits_s_release = m_io_msInfo_bits_s_release[10];
  assign io_msInfo_11_bits_s_release = m_io_msInfo_bits_s_release[11];
  assign io_msInfo_12_bits_s_release = m_io_msInfo_bits_s_release[12];
  assign io_msInfo_13_bits_s_release = m_io_msInfo_bits_s_release[13];
  assign io_msInfo_14_bits_s_release = m_io_msInfo_bits_s_release[14];
  assign io_msInfo_15_bits_s_release = m_io_msInfo_bits_s_release[15];
  assign io_msInfo_0_bits_s_refill = m_io_msInfo_bits_s_refill[0];
  assign io_msInfo_1_bits_s_refill = m_io_msInfo_bits_s_refill[1];
  assign io_msInfo_2_bits_s_refill = m_io_msInfo_bits_s_refill[2];
  assign io_msInfo_3_bits_s_refill = m_io_msInfo_bits_s_refill[3];
  assign io_msInfo_4_bits_s_refill = m_io_msInfo_bits_s_refill[4];
  assign io_msInfo_5_bits_s_refill = m_io_msInfo_bits_s_refill[5];
  assign io_msInfo_6_bits_s_refill = m_io_msInfo_bits_s_refill[6];
  assign io_msInfo_7_bits_s_refill = m_io_msInfo_bits_s_refill[7];
  assign io_msInfo_8_bits_s_refill = m_io_msInfo_bits_s_refill[8];
  assign io_msInfo_9_bits_s_refill = m_io_msInfo_bits_s_refill[9];
  assign io_msInfo_10_bits_s_refill = m_io_msInfo_bits_s_refill[10];
  assign io_msInfo_11_bits_s_refill = m_io_msInfo_bits_s_refill[11];
  assign io_msInfo_12_bits_s_refill = m_io_msInfo_bits_s_refill[12];
  assign io_msInfo_13_bits_s_refill = m_io_msInfo_bits_s_refill[13];
  assign io_msInfo_14_bits_s_refill = m_io_msInfo_bits_s_refill[14];
  assign io_msInfo_15_bits_s_refill = m_io_msInfo_bits_s_refill[15];
  assign io_msInfo_0_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[0];
  assign io_msInfo_1_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[1];
  assign io_msInfo_2_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[2];
  assign io_msInfo_3_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[3];
  assign io_msInfo_4_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[4];
  assign io_msInfo_5_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[5];
  assign io_msInfo_6_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[6];
  assign io_msInfo_7_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[7];
  assign io_msInfo_8_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[8];
  assign io_msInfo_9_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[9];
  assign io_msInfo_10_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[10];
  assign io_msInfo_11_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[11];
  assign io_msInfo_12_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[12];
  assign io_msInfo_13_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[13];
  assign io_msInfo_14_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[14];
  assign io_msInfo_15_bits_s_cmoresp = m_io_msInfo_bits_s_cmoresp[15];
  assign io_msInfo_0_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[0];
  assign io_msInfo_1_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[1];
  assign io_msInfo_2_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[2];
  assign io_msInfo_3_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[3];
  assign io_msInfo_4_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[4];
  assign io_msInfo_5_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[5];
  assign io_msInfo_6_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[6];
  assign io_msInfo_7_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[7];
  assign io_msInfo_8_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[8];
  assign io_msInfo_9_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[9];
  assign io_msInfo_10_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[10];
  assign io_msInfo_11_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[11];
  assign io_msInfo_12_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[12];
  assign io_msInfo_13_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[13];
  assign io_msInfo_14_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[14];
  assign io_msInfo_15_bits_s_cmometaw = m_io_msInfo_bits_s_cmometaw[15];
  assign io_msInfo_0_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[0];
  assign io_msInfo_1_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[1];
  assign io_msInfo_2_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[2];
  assign io_msInfo_3_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[3];
  assign io_msInfo_4_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[4];
  assign io_msInfo_5_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[5];
  assign io_msInfo_6_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[6];
  assign io_msInfo_7_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[7];
  assign io_msInfo_8_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[8];
  assign io_msInfo_9_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[9];
  assign io_msInfo_10_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[10];
  assign io_msInfo_11_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[11];
  assign io_msInfo_12_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[12];
  assign io_msInfo_13_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[13];
  assign io_msInfo_14_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[14];
  assign io_msInfo_15_bits_w_releaseack = m_io_msInfo_bits_w_releaseack[15];
  assign io_msInfo_0_bits_w_replResp = m_io_msInfo_bits_w_replResp[0];
  assign io_msInfo_1_bits_w_replResp = m_io_msInfo_bits_w_replResp[1];
  assign io_msInfo_2_bits_w_replResp = m_io_msInfo_bits_w_replResp[2];
  assign io_msInfo_3_bits_w_replResp = m_io_msInfo_bits_w_replResp[3];
  assign io_msInfo_4_bits_w_replResp = m_io_msInfo_bits_w_replResp[4];
  assign io_msInfo_5_bits_w_replResp = m_io_msInfo_bits_w_replResp[5];
  assign io_msInfo_6_bits_w_replResp = m_io_msInfo_bits_w_replResp[6];
  assign io_msInfo_7_bits_w_replResp = m_io_msInfo_bits_w_replResp[7];
  assign io_msInfo_8_bits_w_replResp = m_io_msInfo_bits_w_replResp[8];
  assign io_msInfo_9_bits_w_replResp = m_io_msInfo_bits_w_replResp[9];
  assign io_msInfo_10_bits_w_replResp = m_io_msInfo_bits_w_replResp[10];
  assign io_msInfo_11_bits_w_replResp = m_io_msInfo_bits_w_replResp[11];
  assign io_msInfo_12_bits_w_replResp = m_io_msInfo_bits_w_replResp[12];
  assign io_msInfo_13_bits_w_replResp = m_io_msInfo_bits_w_replResp[13];
  assign io_msInfo_14_bits_w_replResp = m_io_msInfo_bits_w_replResp[14];
  assign io_msInfo_15_bits_w_replResp = m_io_msInfo_bits_w_replResp[15];
  assign io_msInfo_0_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[0];
  assign io_msInfo_1_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[1];
  assign io_msInfo_2_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[2];
  assign io_msInfo_3_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[3];
  assign io_msInfo_4_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[4];
  assign io_msInfo_5_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[5];
  assign io_msInfo_6_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[6];
  assign io_msInfo_7_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[7];
  assign io_msInfo_8_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[8];
  assign io_msInfo_9_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[9];
  assign io_msInfo_10_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[10];
  assign io_msInfo_11_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[11];
  assign io_msInfo_12_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[12];
  assign io_msInfo_13_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[13];
  assign io_msInfo_14_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[14];
  assign io_msInfo_15_bits_w_rprobeacklast = m_io_msInfo_bits_w_rprobeacklast[15];
  assign io_msInfo_0_bits_replaceData = m_io_msInfo_bits_replaceData[0];
  assign io_msInfo_1_bits_replaceData = m_io_msInfo_bits_replaceData[1];
  assign io_msInfo_2_bits_replaceData = m_io_msInfo_bits_replaceData[2];
  assign io_msInfo_3_bits_replaceData = m_io_msInfo_bits_replaceData[3];
  assign io_msInfo_4_bits_replaceData = m_io_msInfo_bits_replaceData[4];
  assign io_msInfo_5_bits_replaceData = m_io_msInfo_bits_replaceData[5];
  assign io_msInfo_6_bits_replaceData = m_io_msInfo_bits_replaceData[6];
  assign io_msInfo_7_bits_replaceData = m_io_msInfo_bits_replaceData[7];
  assign io_msInfo_8_bits_replaceData = m_io_msInfo_bits_replaceData[8];
  assign io_msInfo_9_bits_replaceData = m_io_msInfo_bits_replaceData[9];
  assign io_msInfo_10_bits_replaceData = m_io_msInfo_bits_replaceData[10];
  assign io_msInfo_11_bits_replaceData = m_io_msInfo_bits_replaceData[11];
  assign io_msInfo_12_bits_replaceData = m_io_msInfo_bits_replaceData[12];
  assign io_msInfo_13_bits_replaceData = m_io_msInfo_bits_replaceData[13];
  assign io_msInfo_14_bits_replaceData = m_io_msInfo_bits_replaceData[14];
  assign io_msInfo_15_bits_replaceData = m_io_msInfo_bits_replaceData[15];
  assign io_msInfo_0_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[0];
  assign io_msInfo_1_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[1];
  assign io_msInfo_2_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[2];
  assign io_msInfo_3_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[3];
  assign io_msInfo_4_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[4];
  assign io_msInfo_5_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[5];
  assign io_msInfo_6_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[6];
  assign io_msInfo_7_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[7];
  assign io_msInfo_8_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[8];
  assign io_msInfo_9_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[9];
  assign io_msInfo_10_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[10];
  assign io_msInfo_11_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[11];
  assign io_msInfo_12_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[12];
  assign io_msInfo_13_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[13];
  assign io_msInfo_14_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[14];
  assign io_msInfo_15_bits_releaseToClean = m_io_msInfo_bits_releaseToClean[15];
  assign io_pCrd_0_query_valid = m_io_pCrd_query_valid[0];
  assign io_pCrd_1_query_valid = m_io_pCrd_query_valid[1];
  assign io_pCrd_2_query_valid = m_io_pCrd_query_valid[2];
  assign io_pCrd_3_query_valid = m_io_pCrd_query_valid[3];
  assign io_pCrd_4_query_valid = m_io_pCrd_query_valid[4];
  assign io_pCrd_5_query_valid = m_io_pCrd_query_valid[5];
  assign io_pCrd_6_query_valid = m_io_pCrd_query_valid[6];
  assign io_pCrd_7_query_valid = m_io_pCrd_query_valid[7];
  assign io_pCrd_8_query_valid = m_io_pCrd_query_valid[8];
  assign io_pCrd_9_query_valid = m_io_pCrd_query_valid[9];
  assign io_pCrd_10_query_valid = m_io_pCrd_query_valid[10];
  assign io_pCrd_11_query_valid = m_io_pCrd_query_valid[11];
  assign io_pCrd_12_query_valid = m_io_pCrd_query_valid[12];
  assign io_pCrd_13_query_valid = m_io_pCrd_query_valid[13];
  assign io_pCrd_14_query_valid = m_io_pCrd_query_valid[14];
  assign io_pCrd_15_query_valid = m_io_pCrd_query_valid[15];
  assign io_pCrd_0_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[0];
  assign io_pCrd_1_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[1];
  assign io_pCrd_2_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[2];
  assign io_pCrd_3_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[3];
  assign io_pCrd_4_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[4];
  assign io_pCrd_5_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[5];
  assign io_pCrd_6_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[6];
  assign io_pCrd_7_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[7];
  assign io_pCrd_8_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[8];
  assign io_pCrd_9_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[9];
  assign io_pCrd_10_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[10];
  assign io_pCrd_11_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[11];
  assign io_pCrd_12_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[12];
  assign io_pCrd_13_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[13];
  assign io_pCrd_14_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[14];
  assign io_pCrd_15_query_bits_pCrdType = m_io_pCrd_query_bits_pCrdType[15];
  assign io_pCrd_0_query_bits_srcID = m_io_pCrd_query_bits_srcID[0];
  assign io_pCrd_1_query_bits_srcID = m_io_pCrd_query_bits_srcID[1];
  assign io_pCrd_2_query_bits_srcID = m_io_pCrd_query_bits_srcID[2];
  assign io_pCrd_3_query_bits_srcID = m_io_pCrd_query_bits_srcID[3];
  assign io_pCrd_4_query_bits_srcID = m_io_pCrd_query_bits_srcID[4];
  assign io_pCrd_5_query_bits_srcID = m_io_pCrd_query_bits_srcID[5];
  assign io_pCrd_6_query_bits_srcID = m_io_pCrd_query_bits_srcID[6];
  assign io_pCrd_7_query_bits_srcID = m_io_pCrd_query_bits_srcID[7];
  assign io_pCrd_8_query_bits_srcID = m_io_pCrd_query_bits_srcID[8];
  assign io_pCrd_9_query_bits_srcID = m_io_pCrd_query_bits_srcID[9];
  assign io_pCrd_10_query_bits_srcID = m_io_pCrd_query_bits_srcID[10];
  assign io_pCrd_11_query_bits_srcID = m_io_pCrd_query_bits_srcID[11];
  assign io_pCrd_12_query_bits_srcID = m_io_pCrd_query_bits_srcID[12];
  assign io_pCrd_13_query_bits_srcID = m_io_pCrd_query_bits_srcID[13];
  assign io_pCrd_14_query_bits_srcID = m_io_pCrd_query_bits_srcID[14];
  assign io_pCrd_15_query_bits_srcID = m_io_pCrd_query_bits_srcID[15];
  // msStatus 的 valid/channel/set/reqTag 取自各 MSHR status 输出
  assign io_msStatus_0_valid       = m_io_status_valid[0];
  assign io_msStatus_0_bits_channel = m_io_status_bits_channel[0];
  assign io_msStatus_0_bits_set     = m_io_status_bits_set[0];
  assign io_msStatus_0_bits_reqTag  = m_io_status_bits_reqTag[0];
  assign io_msStatus_1_valid       = m_io_status_valid[1];
  assign io_msStatus_1_bits_channel = m_io_status_bits_channel[1];
  assign io_msStatus_1_bits_set     = m_io_status_bits_set[1];
  assign io_msStatus_1_bits_reqTag  = m_io_status_bits_reqTag[1];
  assign io_msStatus_2_valid       = m_io_status_valid[2];
  assign io_msStatus_2_bits_channel = m_io_status_bits_channel[2];
  assign io_msStatus_2_bits_set     = m_io_status_bits_set[2];
  assign io_msStatus_2_bits_reqTag  = m_io_status_bits_reqTag[2];
  assign io_msStatus_3_valid       = m_io_status_valid[3];
  assign io_msStatus_3_bits_channel = m_io_status_bits_channel[3];
  assign io_msStatus_3_bits_set     = m_io_status_bits_set[3];
  assign io_msStatus_3_bits_reqTag  = m_io_status_bits_reqTag[3];
  assign io_msStatus_4_valid       = m_io_status_valid[4];
  assign io_msStatus_4_bits_channel = m_io_status_bits_channel[4];
  assign io_msStatus_4_bits_set     = m_io_status_bits_set[4];
  assign io_msStatus_4_bits_reqTag  = m_io_status_bits_reqTag[4];
  assign io_msStatus_5_valid       = m_io_status_valid[5];
  assign io_msStatus_5_bits_channel = m_io_status_bits_channel[5];
  assign io_msStatus_5_bits_set     = m_io_status_bits_set[5];
  assign io_msStatus_5_bits_reqTag  = m_io_status_bits_reqTag[5];
  assign io_msStatus_6_valid       = m_io_status_valid[6];
  assign io_msStatus_6_bits_channel = m_io_status_bits_channel[6];
  assign io_msStatus_6_bits_set     = m_io_status_bits_set[6];
  assign io_msStatus_6_bits_reqTag  = m_io_status_bits_reqTag[6];
  assign io_msStatus_7_valid       = m_io_status_valid[7];
  assign io_msStatus_7_bits_channel = m_io_status_bits_channel[7];
  assign io_msStatus_7_bits_set     = m_io_status_bits_set[7];
  assign io_msStatus_7_bits_reqTag  = m_io_status_bits_reqTag[7];
  assign io_msStatus_8_valid       = m_io_status_valid[8];
  assign io_msStatus_8_bits_channel = m_io_status_bits_channel[8];
  assign io_msStatus_8_bits_set     = m_io_status_bits_set[8];
  assign io_msStatus_8_bits_reqTag  = m_io_status_bits_reqTag[8];
  assign io_msStatus_9_valid       = m_io_status_valid[9];
  assign io_msStatus_9_bits_channel = m_io_status_bits_channel[9];
  assign io_msStatus_9_bits_set     = m_io_status_bits_set[9];
  assign io_msStatus_9_bits_reqTag  = m_io_status_bits_reqTag[9];
  assign io_msStatus_10_valid       = m_io_status_valid[10];
  assign io_msStatus_10_bits_channel = m_io_status_bits_channel[10];
  assign io_msStatus_10_bits_set     = m_io_status_bits_set[10];
  assign io_msStatus_10_bits_reqTag  = m_io_status_bits_reqTag[10];
  assign io_msStatus_11_valid       = m_io_status_valid[11];
  assign io_msStatus_11_bits_channel = m_io_status_bits_channel[11];
  assign io_msStatus_11_bits_set     = m_io_status_bits_set[11];
  assign io_msStatus_11_bits_reqTag  = m_io_status_bits_reqTag[11];
  assign io_msStatus_12_valid       = m_io_status_valid[12];
  assign io_msStatus_12_bits_channel = m_io_status_bits_channel[12];
  assign io_msStatus_12_bits_set     = m_io_status_bits_set[12];
  assign io_msStatus_12_bits_reqTag  = m_io_status_bits_reqTag[12];
  assign io_msStatus_13_valid       = m_io_status_valid[13];
  assign io_msStatus_13_bits_channel = m_io_status_bits_channel[13];
  assign io_msStatus_13_bits_set     = m_io_status_bits_set[13];
  assign io_msStatus_13_bits_reqTag  = m_io_status_bits_reqTag[13];
  assign io_msStatus_14_valid       = m_io_status_valid[14];
  assign io_msStatus_14_bits_channel = m_io_status_bits_channel[14];
  assign io_msStatus_14_bits_set     = m_io_status_bits_set[14];
  assign io_msStatus_14_bits_reqTag  = m_io_status_bits_reqTag[14];
  assign io_msStatus_15_valid       = m_io_status_valid[15];
  assign io_msStatus_15_bits_channel = m_io_status_bits_channel[15];
  assign io_msStatus_15_bits_set     = m_io_status_bits_set[15];
  assign io_msStatus_15_bits_reqTag  = m_io_status_bits_reqTag[15];

endmodule
